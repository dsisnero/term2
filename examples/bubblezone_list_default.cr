# BubbleZone List Example (Term2 version)
#
# This is a Term2 conversion of the BubbleZone list-default example.
# It demonstrates how to use BubbleZone with a list component to handle
# mouse clicks on list items.
#
# Original Go example: https://github.com/lrstanley/bubblezone/tree/master/examples/list-default

require "../src/term2"
require "../src/components/list"
require "../src/bubblezone"

include Term2::Prelude

class ListItem
  getter id : String
  getter title : String
  getter description : String

  def initialize(@id : String, @title : String, @description : String)
  end

  def to_s : String
    "#{@title} - #{@description}"
  end
end

class ListModel < Term2::Model
  property list : TC::List
  property items : Array(ListItem)
  property selected_item : ListItem?
  property zone_manager : BubbleZone::ZoneManager

  def initialize
    @items = [
      ListItem.new("item_1", "Raspberry Pi's", "I have 'em all over my house"),
      ListItem.new("item_2", "Nutella", "It's good on toast"),
      ListItem.new("item_3", "Bitter melon", "It cools you down"),
      ListItem.new("item_4", "Nice socks", "And by that I mean socks without holes"),
      ListItem.new("item_5", "Eight hours of sleep", "I had this once"),
      ListItem.new("item_6", "Cats", "Usually"),
      ListItem.new("item_7", "Plantasia, the album", "My plants love it too"),
      ListItem.new("item_8", "Pour over coffee", "It takes forever to make though"),
      ListItem.new("item_9", "VR", "Virtual reality...what is there to say?"),
      ListItem.new("item_10", "Noguchi Lamps", "Such pleasing organic forms"),
      ListItem.new("item_11", "Linux", "Pretty much the best OS"),
      ListItem.new("item_12", "Business school", "Just kidding"),
      ListItem.new("item_13", "Pottery", "Wet clay is a great feeling"),
      ListItem.new("item_14", "Shampoo", "Nothing like clean hair"),
      ListItem.new("item_15", "Table tennis", "It's surprisingly exhausting"),
      ListItem.new("item_16", "Milk crates", "Great for packing in your extra stuff"),
      ListItem.new("item_17", "Afternoon tea", "Especially the tea sandwich part"),
      ListItem.new("item_18", "Stickers", "The thicker the vinyl the better"),
      ListItem.new("item_19", "20° Weather", "Celsius, not Fahrenheit"),
      ListItem.new("item_20", "Warm light", "Like around 2700 Kelvin"),
      ListItem.new("item_21", "The vernal equinox", "The autumnal equinox is pretty good too"),
      ListItem.new("item_22", "Gaffer's tape", "Basically sticky fabric"),
      ListItem.new("item_23", "Terrycloth", "In other words, towel fabric"),
    ]

    # Create list items for the component
    list_items = @items.map { |item| {item.title, item.description} }

    @list = TC::List.new(
      items: list_items,
      width: 40,
      height: 15
    )

    @zone_manager = BubbleZone::ZoneManager.new
    @selected_item = nil
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2.quit}
      when "up"
        @list.cursor_up
      when "down"
        @list.cursor_down
      end
    when MouseEvent
      # Handle mouse clicks on list items
      if msg.action == "press" && msg.button == "left"
        # Check if click is within any item zone
        @items.each_with_index do |item, index|
          zone = @zone_manager.find_at(msg.x, msg.y)
          if zone && zone.id == item.id
            @list.index = index
            @selected_item = item
            break
          end
        end
      end
    end

    # Update the list component
    new_list, cmd = @list.update(msg)
    @list = new_list

    {self, cmd}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate list position (centered)
    term_width = 80 # Default terminal width

    list_width = 40

    start_x = (term_width - list_width) // 2
    start_y = 3 # Start below title

    # Create zones for each visible list item
    # Calculate visible range based on pagination
    per_page = @list.paginator.per_page
    start_index = @list.paginator.page * per_page
    end_index = [start_index + per_page - 1, @items.size - 1].min

    (start_index..end_index).each_with_index do |item_index, visible_index|
      item_y = start_y + visible_index + 1 # +1 for list border
      item_id = @items[item_index].id

      # Create a zone for this list item
      @zone_manager.add(BubbleZone::ZoneInfo.new(
        item_id,
        1,           # priority
        start_x + 1, # inside list border
        item_y,
        start_x + list_width - 2, # inside list border
        item_y
      ))
    end

    # Build the view
    String.build do |str|
      str << "╔══════════════════════════════════════════════════════════════════════╗\n"
      str << "║                    BubbleZone List Example                          ║\n"
      str << "╚══════════════════════════════════════════════════════════════════════╝\n"
      str << "\n"
      str << "Left click on an item's title to select it\n"
      str << "\n"

      # Render the list
      str << @list.view

      str << "\n"

      # Show selected item
      if selected = @selected_item
        str << "Selected: ".bold << selected.title << " - " << selected.description << "\n"
      else
        str << "No item selected\n"
      end

      str << "\n"
      str << "──────────────────────────────────────────────────────────────────────\n"
      str << "Use arrow keys or mouse to navigate • Press 'q' or Ctrl+C to quit\n"
    end
  end
end

# Run the application
Term2.run(ListModel.new, options: Term2::ProgramOptions.new(
  WithAltScreen.new,
  WithMouseAllMotion.new
))
