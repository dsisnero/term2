module BubblezoneFullLipgloss
  # Ported from bubblezone/examples/full-lipgloss/main.go
  SUBTLE = Term2::AdaptiveColor.new(
    light: Term2::Color.hex("#D9DCCF"),
    dark: Term2::Color.hex("#383838"),
  )
  HIGHLIGHT = Term2::AdaptiveColor.new(
    light: Term2::Color.hex("#874BFD"),
    dark: Term2::Color.hex("#7D56F4"),
  )
  SPECIAL = Term2::AdaptiveColor.new(
    light: Term2::Color.hex("#43BF6D"),
    dark: Term2::Color.hex("#73F59F"),
  )

  TAB_BORDER        = Term2::Border.new("─", "─", "│", "│", "╭", "╮", "┴", "┴", "", "", "", "", "")
  ACTIVE_TAB_BORDER = Term2::Border.new("─", " ", "│", "│", "╭", "╮", "┘", "└", "", "", "", "", "")

  def self.tab_block(zone_id : String, label : String, active : Bool) : String
    style = active ? active_tab_style : tab_style
    Term2::Zone.mark(zone_id, style.render(label))
  end

  def self.list_style(width : Int32) : Term2::Style
    # listStyle in Go uses only a right border and right margin.
    Term2::Style.new
      .border(Term2::Border.normal, false, true, false, false)
      .border_foreground(SUBTLE)
      .margin_right(2)
  end

  def self.list_header(text : String) : String
    Term2::Style.new
      .border_style(Term2::Border.normal)
      .border_bottom(true)
      .border_foreground(SUBTLE)
      .margin_right(2)
      .render(text)
  end

  def self.list_text(text : String, done : Bool) : String
    if done
      done_color = Term2::AdaptiveColor.new(
        light: Term2::Color.hex("#969B86"),
        dark: Term2::Color.hex("#696969"),
      )

      "#{check_mark}#{Term2::Style.new
                        .strikethrough(true)
                        .foreground(done_color)
                        .render(text)}"
    else
      Term2::Style.new.padding_left(2).render(text)
    end
  end

  def self.dialog_box(content : String, width : Int32) : String
    Term2::Style.new
      .border(Term2::Border.rounded)
      .border_foreground(Term2::Color.hex("#874BFD"))
      .padding(1, 0)
      .render(content)
  end

  def self.dialog_question(text : String) : String
    Term2::Style.new
      .width(27)
      .align(Term2::Position::Center)
      .render(text)
  end

  def self.dialog_button(zone_id : String, label : String, active : Bool) : String
    style = active ? active_button : button_style
    Term2::Zone.mark(zone_id, style.render(label))
  end

  def self.history_entry(zone_id : String, text : String, width : Int32, height : Int32, active : Bool) : String
    normalized_width = [width, 0].max
    normalized_height = [height, 0].max

    style = Term2::Style.new
      .align(Term2::Position::Left)
      .foreground(Term2::Color.hex("#FAFAFA"))
      .background(active ? HIGHLIGHT : SUBTLE)
      .margin(1)
      .padding(1, 2)
      .width(normalized_width)
      .height([normalized_height - 2, 1].max)
      .max_height(normalized_height)

    Term2::Zone.mark(zone_id, style.render(text))
  end

  def self.list_description(text : String) : String
    Term2::Style.new.faint(true).render(text)
  end

  private def self.tab_style : Term2::Style
    Term2::Style.new
      .border(TAB_BORDER, true)
      .border_foreground(HIGHLIGHT)
      .padding(0, 1)
  end

  private def self.active_tab_style : Term2::Style
    tab_style.copy.border(ACTIVE_TAB_BORDER, true)
  end

  private def self.button_style : Term2::Style
    Term2::Style.new
      .foreground(Term2::Color.hex("#FFF7DB"))
      .background(Term2::Color.hex("#888B7E"))
      .padding(0, 3)
      .margin_top(1)
      .margin_right(2)
  end

  private def self.active_button : Term2::Style
    Term2::Style.new
      .foreground(Term2::Color.hex("#FFF7DB"))
      .background(Term2::Color.hex("#F25D94"))
      .margin_right(2)
      .underline(true)
  end

  private def self.check_mark : String
    Term2::Style.new
      .foreground(SPECIAL)
      .padding_right(1)
      .render("✓")
  end
end
