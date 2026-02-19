require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LibglossTreeModel
  include Term2::Model

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, Term2::Cmds.none}
  end

  def view : String
    nodes = [
      "root",
      "├─ src",
      "│  ├─ components",
      "│  │  ├─ button.cr",
      "│  │  └─ list.cr",
      "│  └─ layout.cr",
      "├─ examples",
      "│  ├─ libgloss",
      "│  └─ bubblezone",
      "└─ specs",
    ]

    doc = ["Tree View", "", nodes.join("\n"), "", "Visualizes a basic project tree."]
    LibglossStyles::DOC_STYLE.render(doc.join("\n"))
  end
end

Term2.run(LibglossTreeModel.new)
