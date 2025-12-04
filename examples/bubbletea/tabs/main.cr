require "../../../src/term2"

include Term2::Prelude

class TabsModel
  include Term2::Model

  private def self.tab_border_with_bottom(left : String, middle : String, right : String) : Term2::Border
    border = Term2::Border.rounded
    border.bottom_left = left
    border.bottom = middle
    border.bottom_right = right
    border
  end

  INACTIVE_TAB_BORDER = tab_border_with_bottom("┴", "─", "┴")
  ACTIVE_TAB_BORDER   = tab_border_with_bottom("┘", " ", "└")
  DOC_STYLE           = Term2::Style.new.padding(1, 2, 1, 2)
HIGHLIGHT_COLOR     = Term2::AdaptiveColor.new(light: Term2::Color.hex("#874BFD"), dark: Term2::Color.hex("#7D56F4"))
  INACTIVE_TAB_STYLE  = Term2::Style.new.border(INACTIVE_TAB_BORDER, true).border_foreground(HIGHLIGHT_COLOR).padding(0, 1)
  ACTIVE_TAB_STYLE    = Term2::Style.new.border(ACTIVE_TAB_BORDER, true).border_foreground(HIGHLIGHT_COLOR).padding(0, 1)
  WINDOW_STYLE        = Term2::Style.new.border_foreground(HIGHLIGHT_COLOR).padding(2, 0).align(:center).border(Term2::Border.normal).unset_border_top

  getter tabs : Array(String)
  getter tab_content : Array(String)
  getter active_tab : Int32

  def initialize
    @tabs = ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"]
    @tab_content = ["Lip Gloss Tab", "Blush Tab", "Eye Shadow Tab", "Mascara Tab", "Foundation Tab"]
    @active_tab = 0
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        return {self, Term2::Cmds.quit}
      when "right", "l", "n", "tab"
        @active_tab = Math.min(@active_tab + 1, @tabs.size - 1)
      when "left", "h", "p", "shift+tab"
        @active_tab = Math.max(@active_tab - 1, 0)
      end
    end
    {self, nil}
  end

  def view : String
    rendered_tabs = @tabs.map_with_index do |tab, i|
      is_first = i == 0
      is_last = i == @tabs.size - 1
      is_active = i == @active_tab

      style = is_active ? ACTIVE_TAB_STYLE : INACTIVE_TAB_STYLE
      border, _, _, _, _ = style.get_border
      if is_first && is_active
        border.bottom_left = "│"
      elsif is_first && !is_active
        border.bottom_left = "├"
      elsif is_last && is_active
        border.bottom_right = "│"
      elsif is_last && !is_active
        border.bottom_right = "┤"
      end
      style = style.border(border)
      style.render(tab)
    end

    row = Term2.join_horizontal(Term2::Position::Top, rendered_tabs)
    window = WINDOW_STYLE.width(Term2::Text.width(row) - WINDOW_STYLE.get_horizontal_frame_size).render(@tab_content[@active_tab])

    DOC_STYLE.render("#{row}\n#{window}")
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TabsModel.new)
end
