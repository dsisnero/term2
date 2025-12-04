# Port of lipgloss table/simple example to term2
# This example demonstrates basic table rendering using term2's Table component

require "../../../src/term2"

module Term2
  module Components
    # Simple table example using term2's Table component
    class SimpleTableExample
      include Model

      @table : Table

      def initialize
        # Define columns
        columns = [
          Table::Column.new("Name", 15),
          Table::Column.new("Age", 10),
          Table::Column.new("City", 20),
          Table::Column.new("Score", 10),
        ]

        # Define rows
        rows = [
          ["Alice Johnson", "28", "New York", "95"],
          ["Bob Smith", "35", "Los Angeles", "88"],
          ["Charlie Brown", "42", "Chicago", "92"],
          ["Diana Prince", "31", "Seattle", "96"],
          ["Edward Norton", "29", "Boston", "85"],
          ["Fiona Apple", "38", "Austin", "90"],
          ["George Lucas", "45", "San Francisco", "87"],
          ["Helen Mirren", "39", "Miami", "94"],
        ]

        @table = Table.new(columns, rows, width: 60, height: 12)

        # Custom style function
        @table.style_func = ->(row : Int32, _col : Int32) do
          case row
          when -1
            Style.new.bold(true).foreground(Color::CYAN)
          when .even?
            Style.new.background(Color.new(Color::Type::Indexed, 236)) # Dark gray
          else
            Style.new
          end
        end
      end

      def view : String
        # Create a simple view with the table
        String.build do |io|
          io << "Simple Table Example\n"
          io << "=" * 60 << "\n\n"
          io << @table.view
        end
      end

      def update(msg : Msg) : {Model, Cmd}
        # For this simple example, we don't handle any messages
        {self, Cmds.none}
      end
    end
  end
end

# Run the example
example = Term2::Components::SimpleTableExample.new
puts example.view
