require "../src/term2"
require "../src/components/table"

class TableModel < Term2::Model
  property table : Term2::Components::Table

  def initialize
    @table = Term2::Components::Table.new(
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
    Term2::Cmd.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
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
