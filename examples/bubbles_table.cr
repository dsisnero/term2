require "../src/term2"
require "../src/components/table"
include Term2::Prelude

class TableModel
  include Model
  property table : TC::Table

  def initialize
    @table = TC::Table.new(
      columns: [
        {"ID", 5},
        {"Name", 20},
        {"Role", 15},
      ],
      rows: [
        ["1", "Alice Smith", "Engineer"],
        ["2", "Bob Jones", "Designer"],
        ["3", "Charlie Brown", "Manager"],
        ["4", "David Wilson", "Developer"],
        ["5", "Eve Davis", "Product Owner"],
      ],
      width: 50,
      height: 5
    )
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_table, cmd = @table.update(msg)
    @table = new_table

    {self, cmd}
  end

  def view : String
    "Employee Directory:\n\n" +
      @table.view +
      "\n(q to quit)"
  end
end

Term2.run(TableModel.new)
