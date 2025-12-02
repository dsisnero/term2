module BubblezoneFullLipgloss
  SUBTLE    = Term2::Color.from_hex("#D9DCCF")
  HIGHLIGHT = Term2::Color.from_hex("#874BFD")
  SPECIAL   = Term2::Color.from_hex("#43BF6D")

  TAB_BORDER        = Term2::Border.new("─", "─", "│", "│", "╭", "╮", "┴", "┴", "", "", "", "", "")
  ACTIVE_TAB_BORDER = Term2::Border.new("─", " ", "│", "│", "╭", "╮", "┘", "└", "", "", "", "", "")

  def self.tab_block(zone_id : String, label : String, active : Bool) : String
    style = active ? active_tab_style : tab_style
    Term2::Zone.mark(zone_id, style.render(label))
  end

  def self.list_style(width : Int32) : Term2::Style
    Term2::Style.new
      .border(Term2::Border.normal)
      .border_foreground(SUBTLE)
      .padding(0, 1)
      .margin_right(1)
      .margin_bottom(1)
      .width([width, 0].max)
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
      "#{check_mark}#{Term2::Style.new
                        .strikethrough(true)
                        .foreground(Term2::Color.from_hex("#969B86"))
                        .render(text)}"
    else
      Term2::Style.new.padding_left(2).render(text)
    end
  end

  def self.dialog_box(content : String, width : Int32) : String
    Term2::Style.new
      .border(Term2::Border.rounded)
      .border_foreground(HIGHLIGHT)
      .padding(1, 0)
      .width([width, 0].max)
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
      .width(normalized_width)
      .height(normalized_height)
      .padding(1, 2)
      .align(Term2::Position::Center)
      .max_height(normalized_height)
      .background(active ? HIGHLIGHT : SUBTLE)
      .foreground(Term2::Color::WHITE)
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
    Term2::Style.new
      .border(ACTIVE_TAB_BORDER, true)
      .border_foreground(HIGHLIGHT)
      .padding(0, 1)
  end

  private def self.button_style : Term2::Style
    Term2::Style.new
      .foreground(Term2::Color.from_hex("#FFF7DB"))
      .background(Term2::Color.from_hex("#888B7E"))
      .padding(0, 3)
      .margin_top(1)
      .margin_right(2)
  end

  private def self.active_button : Term2::Style
    Term2::Style.new
      .foreground(Term2::Color.from_hex("#FFF7DB"))
      .background(Term2::Color.from_hex("#F25D94"))
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