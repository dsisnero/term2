require "../src/term2"
require "../src/bubbles/table"

class TableModel < Term2::Model
  property table : Term2::Bubbles::Table

  def initialize
    @table = Term2::Bubbles::Table.new(
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
end

class TableDemo < Term2::Application(TableModel)
  def init : {TableModel, Term2::Cmd}
    {TableModel.new, Term2::Cmd.none}
  end

  def update(msg : Term2::Message, model : TableModel) : {TableModel, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {model, Term2::Cmd.quit}
      end
    end

    new_table, cmd = model.table.update(msg)
    model.table = new_table

    {model, cmd}
  end

  def view(model : TableModel) : String
    "Employee Directory:\n\n" +
      model.table.view +
      "\n(q to quit)"
  end
end

TableDemo.new.run
