require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LibglossTableModel
  include Model

  getter data : Array(Array(String))

  def initialize
    @data = [
      ["Region", "Servers", "Latency"],
      ["east-1", "24", "48ms"],
      ["west-2", "18", "62ms"],
      ["eu-central", "12", "55ms"],
      ["ap-south", "10", "71ms"],
    ]
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    {self, Cmds.none}
  end

  def view : String
    widths = [16, 10, 10]
    rows = @data.each_with_index.map do |row, idx|
      LibglossStyles.table_row(row, widths, idx == 0)
    end

    doc = [
      "Region Snapshot",
      "",
      rows.join("\n"),
      "",
      "Columns show region, active servers, and average latency.",
    ].join("\n")

    LibglossStyles::DOC_STYLE.render(doc)
  end
end

Term2.run(LibglossTableModel.new)
