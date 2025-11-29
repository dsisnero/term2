require "../src/term2"

# A Crystal port of the Bubble Tea tabs example
# https://github.com/charmbracelet/bubbletea/blob/master/examples/tabs/main.go

class TabsModel < Term2::Model
  property tabs : Array(String)
  property tab_content : Array(String)
  property active_tab : Int32

  def initialize(@tabs, @tab_content, @active_tab = 0)
  end

  def init : Term2::Cmd
    Term2::Cmd.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        {self, Term2::Cmd.quit}
      when "right", "l", "n", "tab"
        @active_tab = [(@active_tab + 1), @tabs.size - 1].min
        {self, Term2::Cmd.none}
      when "left", "h", "p", "shift+tab"
        @active_tab = [(@active_tab - 1), 0].max
        {self, Term2::Cmd.none}
      else
        {self, Term2::Cmd.none}
      end
    else
      {self, Term2::Cmd.none}
    end
  end

  def tab_border_with_bottom(left : String, middle : String, right : String) : Term2::LipGloss::Border
    border = Term2::LipGloss::Border.rounded
    border.bottom_left = left
    border.bottom = middle
    border.bottom_right = right
    border
  end

  def view : String
    inactive_tab_border = tab_border_with_bottom("┴", "─", "┴")
    active_tab_border = tab_border_with_bottom("┘", " ", "└")

    doc_style = Term2::LipGloss::Style.new.padding(1, 2, 1, 2)
    highlight_color = Term2::LipGloss::AdaptiveColor.new(
      light: Term2::Color.rgb(135, 75, 253), # #874BFD
      dark: Term2::Color.rgb(125, 86, 244)   # #7D56F4
    )

    inactive_tab_style = Term2::LipGloss::Style.new
      .border(inactive_tab_border)
      .border_foreground(highlight_color)
      .padding(0, 1)

    active_tab_style = inactive_tab_style.copy
      .border(active_tab_border)

    window_style = Term2::LipGloss::Style.new
      .border_foreground(highlight_color)
      .padding(2, 0)
      .align(Term2::LipGloss::Position::Center)
      .border(Term2::LipGloss::Border.normal)
      .border_top(false)

    rendered_tabs = render_tabs(inactive_tab_style, active_tab_style)

    row = Term2::LipGloss.join_horizontal(Term2::LipGloss::Position::Top, rendered_tabs)

    content = window_style
      .width(Term2::LipGloss.width(row) - window_style.horizontal_frame_size)
      .render(@tab_content[@active_tab])

    doc_style.render("#{row}\n#{content}")
  end

  private def render_tabs(inactive_tab_style : Term2::LipGloss::Style, active_tab_style : Term2::LipGloss::Style) : Array(String)
    rendered_tabs = [] of String

    @tabs.each_with_index do |tab, i|
      style = (i == @active_tab) ? active_tab_style.copy : inactive_tab_style.copy
      style = modify_tab_border(style, i)
      rendered_tabs << style.render(tab)
    end

    rendered_tabs
  end

  private def modify_tab_border(style : Term2::LipGloss::Style, index : Int32) : Term2::LipGloss::Style
    is_first = (index == 0)
    is_last = (index == @tabs.size - 1)
    is_active = (index == @active_tab)

    if border = style.border_style
      new_border = border # Copy struct

      if is_first && is_active
        new_border.bottom_left = "│"
      elsif is_first && !is_active
        new_border.bottom_left = "├"
      elsif is_last && is_active
        new_border.bottom_right = "│"
      elsif is_last && !is_active
        new_border.bottom_right = "┤"
      end

      style.border(new_border)
    end

    style
  end
end

tabs = ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"]
tab_content = ["Lip Gloss Tab", "Blush Tab", "Eye Shadow Tab", "Mascara Tab", "Foundation Tab"]

program = Term2::Program.new(TabsModel.new(tabs, tab_content))
program.run
