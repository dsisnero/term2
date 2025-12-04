require "../../../src/term2"

include Term2::Prelude

LIST_HEIGHT                = 14
ITEM_STYLE                 = Term2::Style.new.padding(0, 0, 0, 4)
LIST_SIMPLE_SELECTED_STYLE = Term2::Style.new.padding(0, 0, 0, 2).foreground(Term2::Color.new(Term2::Color::Type::Indexed, 170))
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
    ""
  end
end

class SimpleDelegate
  include TC::List::ItemDelegate

  def height : Int32
    1
  end

  def spacing : Int32
    0
  end

  def render(io : IO, item : TC::List::Item, index : Int32, selected : Bool, enumerator : String)
    menu_item = item.as(MenuItem)
    str = "#{index + 1}. #{menu_item.title}"
    if selected
      io << LIST_SIMPLE_SELECTED_STYLE.render("> #{str}")
    else
      io << ITEM_STYLE.render(str)
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
    @list.filtering_enabled = false
    @list.show_help = true
    @list.show_pagination = true
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
