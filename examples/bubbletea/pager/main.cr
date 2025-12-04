require "../../../src/term2"

include Term2::Prelude

TITLE_BORDER = Term2::Border.rounded.dup
TITLE_BORDER.right = "├"
INFO_BORDER = Term2::Border.rounded.dup
INFO_BORDER.left = "┤"

PAGER_TITLE_STYLE = Term2::Style.new.border(TITLE_BORDER).padding(0, 1)
INFO_STYLE = Term2::Style.new.border(INFO_BORDER).padding(0, 1)

class PagerModel
  include Term2::Model

  getter content : String
  getter? ready : Bool
  getter viewport : TC::Viewport

  def initialize(@content = File.read(File.join(__DIR__, "artichoke.md")))
    @ready = false
    @viewport = TC::Viewport.new(0, 0)
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q", "esc"
        return {self, Term2::Cmds.quit}
      end
    when Term2::WindowSizeMsg
      header_height = Term2::Text.height(header_view)
      footer_height = Term2::Text.height(footer_view)
      vertical_margin = header_height + footer_height

      if !@ready
        @viewport = TC::Viewport.new(msg.width, msg.height - vertical_margin)
        @viewport.y_position = header_height
        @viewport.content = @content
        @ready = true
      else
        @viewport.width = msg.width
        @viewport.height = msg.height - vertical_margin
      end
    end

    @viewport, cmd = @viewport.update(msg)
    {self, cmd}
  end

  def view : String
    return "\n  Initializing..." unless @ready
    "#{header_view}\n#{@viewport.view}\n#{footer_view}"
  end

  def header_view : String
    title = PAGER_TITLE_STYLE.render("Mr. Pager")
    line = "─" * Math.max(0, @viewport.width - Term2::Text.width(title))
    Term2.join_horizontal(Term2::Position::Center, title, line)
  end

  def footer_view : String
    info = INFO_STYLE.render("%3.f%%" % (@viewport.scroll_percent * 100))
    line = "─" * Math.max(0, @viewport.width - Term2::Text.width(info))
    Term2.join_horizontal(Term2::Position::Center, line, info)
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(PagerModel.new, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new, Term2::WithMouseCellMotion.new))
end
