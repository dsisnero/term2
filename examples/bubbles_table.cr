require "../src/term2"
require "../src/components/table"
include Term2::Prelude

class TableModel
  include Term2::Model
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

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.string == "q" || msg.string == "ctrl+c"
        return {self, Term2::Cmds.quit}
      end
    end

    new_table, cmd = @table.update(msg)
    @table = new_table

    {self, cmd}
  end

  def view : String
    "Employee Directory:\n\n" +
      @table.view.content +
      "\n(q to quit)"
  end
end

Term2.run(TableModel.new)
