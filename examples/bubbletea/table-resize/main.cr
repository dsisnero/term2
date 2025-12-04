require "../../../src/term2"

include Term2::Prelude

TABLE_RESIZE_BASE_STYLE     = Term2::Style.new.padding(0, 1)
HEADER_STYLE                = TABLE_RESIZE_BASE_STYLE.fg_indexed(252).bold(true)
TABLE_RESIZE_SELECTED_STYLE = TABLE_RESIZE_BASE_STYLE.fg_hex("#01BE85").bg_hex("#00432F")
TYPE_COLORS                 = {
  "Bug"      => Term2::Color.hex("#D7FF87"),
  "Electric" => Term2::Color.hex("#FDFF90"),
  "Fire"     => Term2::Color.hex("#FF7698"),
  "Flying"   => Term2::Color.hex("#FF87D7"),
  "Grass"    => Term2::Color.hex("#75FBAB"),
  "Ground"   => Term2::Color.hex("#FF875F"),
  "Normal"   => Term2::Color.hex("#929292"),
  "Poison"   => Term2::Color.hex("#7D5AFC"),
  "Water"    => Term2::Color.hex("#00E2C7"),
}
DIM_TYPE_COLORS = {
  "Bug"      => Term2::Color.hex("#97AD64"),
  "Electric" => Term2::Color.hex("#FCFF5F"),
  "Fire"     => Term2::Color.hex("#BA5F75"),
  "Flying"   => Term2::Color.hex("#C97AB2"),
  "Grass"    => Term2::Color.hex("#59B980"),
  "Ground"   => Term2::Color.hex("#C77252"),
  "Normal"   => Term2::Color.hex("#727272"),
  "Poison"   => Term2::Color.hex("#634BD0"),
  "Water"    => Term2::Color.hex("#439F8E"),
}

HEADERS = ["#", "NAME", "TYPE 1", "TYPE 2", "JAPANESE", "OFFICIAL ROM."]
ROWS    = [
  {"1", "Bulbasaur", "Grass", "Poison", "フシギダネ", "Bulbasaur"},
  {"2", "Ivysaur", "Grass", "Poison", "フシギソウ", "Ivysaur"},
  {"3", "Venusaur", "Grass", "Poison", "フシギバナ", "Venusaur"},
  {"4", "Charmander", "Fire", "", "ヒトカゲ", "Hitokage"},
  {"5", "Charmeleon", "Fire", "", "リザード", "Lizardo"},
  {"6", "Charizard", "Fire", "Flying", "リザードン", "Lizardon"},
  {"7", "Squirtle", "Water", "", "ゼニガメ", "Zenigame"},
  {"8", "Wartortle", "Water", "", "カメール", "Kameil"},
  {"9", "Blastoise", "Water", "", "カメックス", "Kamex"},
  {"10", "Caterpie", "Bug", "", "キャタピー", "Caterpie"},
  {"11", "Metapod", "Bug", "", "トランセル", "Trancell"},
  {"12", "Butterfree", "Bug", "Flying", "バタフリー", "Butterfree"},
  {"13", "Weedle", "Bug", "Poison", "ビードル", "Beedle"},
  {"14", "Kakuna", "Bug", "Poison", "コクーン", "Cocoon"},
  {"15", "Beedrill", "Bug", "Poison", "スピアー", "Spear"},
  {"16", "Pidgey", "Normal", "Flying", "ポッポ", "Poppo"},
  {"17", "Pidgeotto", "Normal", "Flying", "ピジョン", "Pigeon"},
  {"18", "Pidgeot", "Normal", "Flying", "ピジョット", "Pigeot"},
  {"19", "Rattata", "Normal", "", "コラッタ", "Koratta"},
  {"20", "Raticate", "Normal", "", "ラッタ", "Ratta"},
  {"21", "Spearow", "Normal", "Flying", "オニスズメ", "Onisuzume"},
  {"22", "Fearow", "Normal", "Flying", "オニドリル", "Onidrill"},
  {"23", "Ekans", "Poison", "", "アーボ", "Arbo"},
  {"24", "Arbok", "Poison", "", "アーボック", "Arbok"},
  {"25", "Pikachu", "Electric", "", "ピカチュウ", "Pikachu"},
  {"26", "Raichu", "Electric", "", "ライチュウ", "Raichu"},
  {"27", "Sandshrew", "Ground", "", "サンド", "Sand"},
  {"28", "Sandslash", "Ground", "", "サンドパン", "Sandpan"},
]

class TableResizeModel
  include Term2::Model

  getter table : TC::Table

  def initialize
    cols = HEADERS.map { |h| TC::Table::Column.new(h, 12) }
    table_rows = ROWS.map(&.to_a)
    t = TC::Table.new(columns: cols, rows: table_rows, height: ROWS.size + 2)
    t.border = Term2::Border.thick
    t.border_style = Term2::Style.new.fg_indexed(238)
    t.style_func = ->(row : Int32, col : Int32) do
      # header row
      return HEADER_STYLE if row == -1
      row_index = row
      return TABLE_RESIZE_BASE_STYLE unless row_index >= 0 && row_index < ROWS.size
      return TABLE_RESIZE_SELECTED_STYLE if ROWS[row_index][1] == "Pikachu"
      even = row % 2 == 0
      if col == 2 || col == 3
        colors = even ? DIM_TYPE_COLORS : TYPE_COLORS
        if val = ROWS[row_index][col]?
          if c = colors[val]?
            return TABLE_RESIZE_BASE_STYLE.foreground(c)
          end
        end
      end
      if even
        TABLE_RESIZE_BASE_STYLE.fg_indexed(245)
      else
        TABLE_RESIZE_BASE_STYLE.fg_indexed(253)
      end
    end
    @table = t
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @table.width = msg.width
      new_height = msg.height - 2
      @table.height = new_height if new_height > 0
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2::Cmds.quit}
      end
    end
    {self, nil}
  end

  def view : String
    "\n" + @table.view + "\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TableResizeModel.new, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new))
end
