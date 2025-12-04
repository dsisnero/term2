require "../../../src/term2"

include Term2::Prelude

LIST_HEIGHT                = 14
ITEM_STYLE                 = Term2::Style.new.padding(0, 0, 0, 4)
LIST_SIMPLE_SELECTED_STYLE = Term2::Style.new.padding(0, 0, 0, 2).fg_indexed(170)
PAGINATION_STYLE           = Term2::Style.new.padding(0, 0, 0, 4)
QUIT_STYLE                 = Term2::Style.new.margin(1, 0, 2, 4)

struct MenuItem
  include TC::List::Item
  getter title : String

  def initialize(@title : String)
  end

  def description : String
    ""
  end

  def filter_value : String
    @title
  end
end

class SimpleDelegate
  include TC::List::ItemDelegate

  def initialize(@match_style = Term2::Style.new.underline(true))
  end

  def height : Int32
    1
  end

  def spacing : Int32
    0
  end

  def render_with_matches(io : IO, item : TC::List::Item, index : Int32, selected : Bool, enumerator : String, matches : Array(Int32))
    menu_item = item.as(MenuItem)
    str = highlight("#{index + 1}. #{menu_item.title}", matches)
    line = selected ? LIST_SIMPLE_SELECTED_STYLE.render("> #{str}") : ITEM_STYLE.render(str)
    io << line
  end

  def render(io : IO, item : TC::List::Item, index : Int32, selected : Bool, enumerator : String)
    render_with_matches(io, item, index, selected, enumerator, [] of Int32)
  end

  private def highlight(text : String, matches : Array(Int32)) : String
    return text if matches.empty?
    String.build do |s|
      text.chars.each_with_index do |ch, i|
        if matches.includes?(i)
          s << @match_style.render(ch.to_s)
        else
          s << ch
        end
      end
    end
  end
end

class ListSimpleModel
  include Term2::Model

  getter list : TC::List
  getter choice : String
  getter? quitting : Bool

  def initialize
    items = [
      "Ramen",
      "Tomato Soup",
      "Hamburgers",
      "Cheeseburgers",
      "Currywurst",
      "Okonomiyaki",
      "Pasta",
      "Fillet Mignon",
      "Caviar",
      "Just Wine",
    ].map { |i| MenuItem.new(i).as(TC::List::Item) }

    delegate = SimpleDelegate.new
    @list = TC::List.new(items, 20, LIST_HEIGHT)
    @list.delegate = delegate
    @list.title = "What do you want for dinner?"
    @list.show_status_bar = false
    @list.filtering_enabled = true
    @list.show_filter = true
    @list.show_help = true
    @list.show_pagination = true
    @list.styles = @list.styles.tap { |s| s.default_filter_character_match = Term2::Style.new.underline(true) }
    @list.enumerator = TC::List::Enumerators::None
    @choice = ""
    @quitting = false
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @list.width = msg.width
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        @quitting = true
        return {self, Term2::Cmds.quit}
      when "enter"
        if selected = @list.selected_item
          @choice = selected.as(MenuItem).title
        end
        return {self, Term2::Cmds.quit}
      end
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : String
    if !@choice.empty?
      return QUIT_STYLE.render("#{@choice}? Sounds good to me.")
    end
    if @quitting
      return QUIT_STYLE.render("Not hungry? That’s cool.")
    end

    "\n" + @list.view
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ListSimpleModel.new)
end
