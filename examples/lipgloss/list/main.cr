require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LibglossListModel
  include Model

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

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "down", "j"
        @cursor = (@cursor + 1) % @items.size
        {self, Cmds.none}
      when "up", "k"
        @cursor = (@cursor - 1 + @items.size) % @items.size
        {self, Cmds.none}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
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