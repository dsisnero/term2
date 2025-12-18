require "../../../src/term2"
require "../../../src/components/list"

# Define global styles to match Go example
TITLE_STYLE         = Term2::Style.new.margin_left(2)
ITEM_STYLE          = Term2::Style.new.padding_left(4)
SELECTED_ITEM_STYLE = Term2::Style.new.padding_left(2).foreground(Term2::Color.indexed(170))
PAGINATION_STYLE    = Term2::Components::List::Styles.new.pagination_style.padding_left(4)
HELP_STYLE          = Term2::Components::List::Styles.new.help_style.padding_left(4).padding_bottom(1)
QUIT_TEXT_STYLE     = Term2::Style.new.margin(1, 0, 2, 4)

# 1. Define the concrete Item struct
struct MenuItem
  include Term2::Components::List::Item
  getter title : String

  def initialize(@title : String)
  end

  def filter_value : String
    "" # Not used in this example as filtering is disabled
  end

  def to_s
    @title
  end
end

# 2. Define the Delegate
class SimpleDelegate
  include Term2::Components::List::ItemDelegate

  def height : Int32
    1
  end

  def spacing : Int32
    0
  end

  def update(msg : Term2::Msg, model : Term2::Components::List) : Term2::Cmd
    nil
  end

  # Fix: Signature must match abstract def exactly
  def render(io : IO, model : Term2::Components::List, index : Int32, item : Term2::Components::List::Item)
    # Cast to concrete type
    if i = item.as?(MenuItem)
      str = "#{index + 1}. #{i.title}"

      if index == model.index
        # Selected
        io << SELECTED_ITEM_STYLE.render("> " + str)
      else
        # Normal
        io << ITEM_STYLE.render(str)
      end
    end
  end
end

# 3. Define the Application Model
class ListSimpleModel
  include Term2::Model

  @list : Term2::Components::List
  getter choice : String = ""
  @quitting : Bool = false

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
    ].map { |t| MenuItem.new(t).as(Term2::Components::List::Item) }

    @list = Term2::Components::List.new(items, 20, 14)
    @list.delegate = SimpleDelegate.new
    @list.title = "What do you want for dinner?"
    @list.show_status_bar = false
    @list.filtering_enabled = false

    # Apply styles
    @list.styles.title = TITLE_STYLE
    @list.styles.pagination_style = PAGINATION_STYLE
    @list.styles.help_style = HELP_STYLE
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @list.width = msg.width
      return {self, nil}
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        @quitting = true
        return {self, Term2::Cmds.quit}
      when "enter"
        if selected = @list.selected_item
          if i = selected.as?(MenuItem)
            @choice = i.title
          end
        end
        return {self, Term2::Cmds.quit}
      end
    end

    # Forward other messages to the list
    new_list, cmd = @list.update(msg)
    @list = new_list.as(Term2::Components::List)

    {self, cmd}
  end

  def view : String
    if !@choice.empty?
      return QUIT_TEXT_STYLE.render("#{@choice}? Sounds good to me.")
    end
    if @quitting
      return QUIT_TEXT_STYLE.render("Not hungry? That’s cool.")
    end

    "\n" + @list.view
  end
end

# 4. Run
unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ListSimpleModel.new)
end
