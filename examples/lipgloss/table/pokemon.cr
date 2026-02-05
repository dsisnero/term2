# Port of lipgloss table/pokemon example to term2
# This example demonstrates a Pokemon table with type-based coloring

require "../../../src/term2"

module Term2
  module Components
    # Pokemon table example using term2's Table component
    class PokemonTableExample
      include Model

      @table : Table

      def initialize
        # Define columns
        columns = [
          Table::Column.new("#", 5),
          Table::Column.new("Name", 15),
          Table::Column.new("Type 1", 10),
          Table::Column.new("Type 2", 10),
          Table::Column.new("Japanese", 15),
          Table::Column.new("Official Rom.", 15),
        ]

        # Define rows (first 30 Pokemon)
        rows = [
          ["1", "Bulbasaur", "Grass", "Poison", "フシギダネ", "Fushigidane"],
          ["2", "Ivysaur", "Grass", "Poison", "フシギソウ", "Fushigisou"],
          ["3", "Venusaur", "Grass", "Poison", "フシギバナ", "Fushigibana"],
          ["4", "Charmander", "Fire", "", "ヒトカゲ", "Hitokage"],
          ["5", "Charmeleon", "Fire", "", "リザード", "Lizardo"],
          ["6", "Charizard", "Fire", "Flying", "リザードン", "Lizardon"],
          ["7", "Squirtle", "Water", "", "ゼニガメ", "Zenigame"],
          ["8", "Wartortle", "Water", "", "カメール", "Kameil"],
          ["9", "Blastoise", "Water", "", "カメックス", "Kamex"],
          ["10", "Caterpie", "Bug", "", "キャタピー", "Caterpie"],
          ["11", "Metapod", "Bug", "", "トランセル", "Trancell"],
          ["12", "Butterfree", "Bug", "Flying", "バタフリー", "Butterfree"],
          ["13", "Weedle", "Bug", "Poison", "ビードル", "Beedle"],
          ["14", "Kakuna", "Bug", "Poison", "コクーン", "Cocoon"],
          ["15", "Beedrill", "Bug", "Poison", "スピアー", "Spear"],
          ["16", "Pidgey", "Normal", "Flying", "ポッポ", "Poppo"],
          ["17", "Pidgeotto", "Normal", "Flying", "ピジョン", "Pigeon"],
          ["18", "Pidgeot", "Normal", "Flying", "ピジョット", "Pigeot"],
          ["19", "Rattata", "Normal", "", "コラッタ", "Koratta"],
          ["20", "Raticate", "Normal", "", "ラッタ", "Ratta"],
          ["21", "Spearow", "Normal", "Flying", "オニスズメ", "Onisuzume"],
          ["22", "Fearow", "Normal", "Flying", "オニドリル", "Onidrill"],
          ["23", "Ekans", "Poison", "", "アーボ", "Arbo"],
          ["24", "Arbok", "Poison", "", "アーボック", "Arbok"],
          ["25", "Pikachu", "Electric", "", "ピカチュウ", "Pikachu"],
          ["26", "Raichu", "Electric", "", "ライチュウ", "Raichu"],
          ["27", "Sandshrew", "Ground", "", "サンド", "Sand"],
          ["28", "Sandslash", "Ground", "", "サンドパン", "Sandpan"],
        ]

        @table = Table.new(columns, rows, width: 80, height: 20)

        # Type colors (similar to original lipgloss example)
        type_colors = {
          "Bug"      => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xD7FF87),
          "Electric" => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xFDFF90),
          "Fire"     => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xFF7698),
          "Flying"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xFF87D7),
          "Grass"    => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x75FBAB),
          "Ground"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xFF875F),
          "Normal"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x929292),
          "Poison"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x7D5AFC),
          "Water"    => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x00E2C7),
        }

        # Dim type colors for even rows
        dim_type_colors = {
          "Bug"      => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x97AD64),
          "Electric" => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xFCFF5F),
          "Fire"     => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xBA5F75),
          "Flying"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xC97AB2),
          "Grass"    => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x59B980),
          "Ground"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0xC77252),
          "Normal"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x727272),
          "Poison"   => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x634BD0),
          "Water"    => Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x439F8E),
        }

        # Custom style function
        @table.style_func = ->(row : Int32, col : Int32) do
          case row
          when -1
            # Header style
            Lipgloss::Style.new.bold(true).foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Indexed, 252))
          else
            # Data rows
            even_row = row.even?

            # Special style for Pikachu (selected row)
            if rows[row][1] == "Pikachu"
              return Lipgloss::Style.new
                .foreground(Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x01BE85))
                .background(Lipgloss::Color.new(Lipgloss::Color::Type::RGB, 0x00432F))
            end

            # Type columns (2 and 3)
            if col == 2 || col == 3
              type_name = rows[row][col]
              if !type_name.empty? && type_colors.has_key?(type_name)
                color_map = even_row ? dim_type_colors : type_colors
                return Lipgloss::Style.new.foreground(color_map[type_name])
              end
            end

            # Default row colors
            if even_row
              Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Indexed, 245))
            else
              Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Indexed, 252))
            end
          end
        end

        # Set border style
        @table.border = Lipgloss::Border.new
        @table.border_style = Lipgloss::Style.new.foreground(Lipgloss::Color.new(Lipgloss::Color::Type::Indexed, 238))
      end

      def view : String
        # Create a view with the table
        String.build do |io|
          io << "Pokemon Table Example\n"
          io << "=" * 80 << "\n\n"
          io << @table.view
        end
      end

      def update(msg : Msg) : {Model, Cmd}
        # For this example, we don't handle any messages
        {self, Cmds.none}
      end
    end
  end
end

# Run the example
example = Term2::Components::PokemonTableExample.new
puts example.view
