require "../src/term2"

# A Crystal port of the Bubble Tea tabs example
# https://github.com/charmbracelet/bubbletea/blob/master/examples/tabs/main.go

class TabsModel
  include Term2::Model
  property tabs : Array(String)
  property tab_content : Array(String)
  property active_tab : Int32

  def initialize(@tabs, @tab_content, @active_tab = 0)
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        {self, Term2.quit}
      when "right", "l", "n", "tab"
        @active_tab = [(@active_tab + 1), @tabs.size - 1].min
        {self, Term2::Cmds.none}
      when "left", "h", "p", "shift+tab"
        @active_tab = [(@active_tab - 1), 0].max
        {self, Term2::Cmds.none}
      else
        {self, Term2::Cmds.none}
      end
    else
      {self, Term2::Cmds.none}
    end
  end

  def tab_border_with_bottom(left : String, middle : String, right : String) : Term2::Border
    border = Term2::Border.rounded
    border.bottom_left = left
    border.bottom = middle
    border.bottom_right = right
    border
  end

  def view : String
    inactive_tab_border = tab_border_with_bottom("┴", "─", "┴")
    active_tab_border = tab_border_with_bottom("┘", " ", "└")

    doc_style = Term2::Style.new.padding(1, 2, 1, 2)
    highlight_color = Term2::AdaptiveColor.new(
      light: Term2::Color.rgb(135, 75, 253), # #874BFD
      dark: Term2::Color.rgb(125, 86, 244)   # #7D56F4
    )

    inactive_tab_style = Term2::Style.new
      .border(inactive_tab_border, true)
      .border_foreground(highlight_color)
      .padding(0, 1)

    active_tab_style = inactive_tab_style.copy
      .border(active_tab_border, true)

    window_style = Term2::Style.new
      .border_foreground(highlight_color)
      .padding(2, 0)
      .align(Term2::Position::Center)
      .border(Term2::Border.normal, true)
      .border_top(false)

    rendered_tabs = [] of String

    @tabs.each_with_index do |t, i|
      style = (i == @active_tab) ? active_tab_style.copy : inactive_tab_style.copy

      is_first = (i == 0)
      is_last = (i == @tabs.size - 1)
      is_active = (i == @active_tab)

      # We need to modify the border of the style.
      # Since Style holds a reference to Border (which is a struct),
      # we need to get the border, modify it (it's a struct, so copy), and set it back.

      border = style.get_border_style
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

      style.border(new_border, true)

      rendered_tabs << style.render(t)
    end

    row = rendered_tabs.reduce("") do |acc, tab|
      if acc.empty?
        tab
      else
        Term2.join_horizontal(Term2::Position::Top, acc, tab)
      end
    end

    content = window_style
      .width(Term2.width(row) - window_style.get_horizontal_frame_size)
      .render(@tab_content[@active_tab])

    doc_style.render("#{row}\n#{content}")
  end
end

tabs = ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"]
tab_content = ["Lip Gloss Tab", "Blush Tab", "Eye Shadow Tab", "Mascara Tab", "Foundation Tab"]

program = Term2::Program.new(TabsModel.new(tabs, tab_content))
program.run
