require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LibglossListModel
  include Term2::Model

  getter items : Array(String)
  getter cursor : Int32

  def initialize
    @items = [
      "Grapefruit",
      "Yuzu",
      "Citron",
      "Kumquat",
      "Pomelo",
      "Clementine",
      "Blood orange",
      "Meyer lemon",
    ]
    @cursor = 0
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.string
      when "q", "ctrl+c"
        {self, Term2::Cmds.quit}
      when "down", "j"
        @cursor = (@cursor + 1) % @items.size
        {self, Term2::Cmds.none}
      when "up", "k"
        @cursor = (@cursor - 1 + @items.size) % @items.size
        {self, Term2::Cmds.none}
      else
        {self, Term2::Cmds.none}
      end
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
    lines = @items.each_with_index.map do |item, idx|
      prefix = idx == @cursor ? "→" : " "
      LibglossStyles.list_item("#{prefix} #{item}", idx == @cursor)
    end

    header = LibglossStyles.panel(40, "Favorite Citrus", lines.join("\n"))
    footer = "Use ↑/↓ to move, q to exit."
    LibglossStyles::DOC_STYLE.render(["Libgloss List Example", "", header, "", footer].join("\n"))
  end
end

Term2.run(LibglossListModel.new)
