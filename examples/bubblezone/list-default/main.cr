# List default example ported from Bubblezone
# Original Go code: https://github.com/charmbracelet/bubblezone/tree/main/examples/list-default
#
# Demonstrates:
# - Clickable list entries via `Zone.mark`
# - Mouse wheel scrolling
# - Selecting items via keyboard or mouse
# - Zone click handling without manual coordinate math

require "../../../src/term2"
include Term2::Prelude
alias Zone = Term2::Zone
alias ZoneClickMsg = Term2::ZoneClickMsg

DOC_STYLE = Term2::Style.new
  .margin(1, 2, 1, 2)
  .padding(1)

TITLE_STYLE    = Term2::Style.new.padding_left(2)
SELECTED_STYLE = Term2::Style.new
  .padding_left(2)
  .bold(true)
  .foreground(Term2::Color::CYAN)
DESC_STYLE = Term2::Style.new.faint(true)

class ListItem
  getter id : String
  getter title : String
  getter desc : String
  property done : Bool = false

  def initialize(@id : String, @title : String, @desc : String, @done : Bool = false)
  end

  def toggle!
    @done = !@done
  end
end

class ListModel
  include Model

  ITEM_DATA = [
    {"item_1", "Raspberry Pi's", "I have 'em all over my house"},
    {"item_2", "Nutella", "It's good on toast"},
    {"item_3", "Bitter melon", "It cools you down"},
    {"item_4", "Nice socks", "And by that I mean socks without holes"},
    {"item_5", "Eight hours of sleep", "I had this once"},
    {"item_6", "Cats", "Usually"},
    {"item_7", "Plantasia, the album", "My plants love it too"},
    {"item_8", "Pour over coffee", "It takes forever to make though"},
    {"item_9", "VR", "Virtual reality...what is there to say?"},
    {"item_10", "Noguchi Lamps", "Such pleasing organic forms"},
    {"item_11", "Linux", "Pretty much the best OS"},
    {"item_12", "Business school", "Just kidding"},
    {"item_13", "Pottery", "Wet clay is a great feeling"},
    {"item_14", "Shampoo", "Nothing like clean hair"},
    {"item_15", "Table tennis", "It's surprisingly exhausting"},
    {"item_16", "Milk crates", "Great for packing in your extra stuff"},
    {"item_17", "Afternoon tea", "Especially the tea sandwich part"},
    {"item_18", "Stickers", "The thicker the vinyl the better"},
    {"item_19", "20 deg Weather", "Celsius not Fahrenheit"},
    {"item_20", "Warm light", "Like around 2700 Kelvin"},
    {"item_21", "The vernal equinox", "The autumnal equinox is pretty good too"},
    {"item_22", "Gaffer's tape", "Basically sticky fabric"},
    {"item_23", "Terrycloth", "In other words, towel fabric"},
  ]

  property items : Array(ListItem) = [] of ListItem
  property selected_index : Int32 = 0
  property visible_start : Int32 = 0
  property visible_count : Int32 = 10
  property width : Int32 = 0
  property height : Int32 = 0

  def initialize(@items = build_items)
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      handle_key(msg.key.to_s)
    when MouseEvent
      handle_mouse(msg)
    when ZoneClickMsg
      handle_zone_click(msg)
    when WindowSizeMsg
      handle_resize(msg.width, msg.height)
    else
      {self, Cmds.none}
    end
  end

  def view : String
    lines = [] of String
    lines << "Left click on an item's title to select it"
    lines << ""

    visible_items.each_with_index do |item, offset|
      idx = @visible_start + offset
      prefix = idx == @selected_index ? "> " : "  "
      style = idx == @selected_index ? SELECTED_STYLE : TITLE_STYLE
      content = "#{prefix}#{style.render(item.title)} - #{DESC_STYLE.render(item.desc)}"
      mark = Zone.mark(item.id, content)
      lines << mark
    end

    if @visible_start > 0 || @visible_start + @visible_count < @items.size
      lines << ""
      if @visible_start > 0
        lines << "↑ More items above"
      end
      if @visible_start + @visible_count < @items.size
        lines << "↓ More items below"
      end
    end

    lines << ""
    lines << "Press q or ctrl+c to quit"

    DOC_STYLE.render(lines.join("\n"))
  end

  private def build_items : Array(ListItem)
    ITEM_DATA.map do |id, title, desc|
      ListItem.new(id, title, desc)
    end
  end

  private def visible_items : Array(ListItem)
    return [] of ListItem if @items.empty?
    count = [@visible_count, @items.size - @visible_start].min
    @items[@visible_start, count]
  end

  private def handle_key(key : String) : {Model, Cmd}
    case key
    when "q", "ctrl+c"
      {self, Term2.quit}
    when "up", "k"
      move_selection(-1)
    when "down", "j"
      move_selection(1)
    else
      {self, Cmds.none}
    end
  end

  private def handle_mouse(event : MouseEvent) : {Model, Cmd}
    case event.button
    when MouseEvent::Button::WheelUp
      @visible_start = [@visible_start - 1, 0].max
    when MouseEvent::Button::WheelDown
      max_start = [@items.size - @visible_count, 0].max
      @visible_start = [@visible_start + 1, max_start].min
    else
      return {self, Cmds.none}
    end
    ensure_visibility
    {self, Cmds.none}
  end

  private def handle_zone_click(msg : ZoneClickMsg) : {Model, Cmd}
    return {self, Cmds.none} unless idx = @items.index { |item| item.id == msg.id }
    @selected_index = idx
    ensure_visibility
    {self, Cmds.none}
  end

  private def handle_resize(width : Int32, height : Int32) : {Model, Cmd}
    @width = width
    @height = height
    @visible_count = [height - 4, 1].max
    ensure_visibility
    {self, Cmds.none}
  end

  private def move_selection(delta : Int32) : {Model, Cmd}
    new_index = @selected_index + delta
    if new_index < 0
      new_index = @items.size - 1
    elsif new_index >= @items.size
      new_index = 0
    end
    @selected_index = new_index
    ensure_visibility
    {self, Cmds.none}
  end

  private def ensure_visibility
    max_start = [@items.size - @visible_count, 0].max
    @visible_start = [[@visible_start, max_start].min, 0].max
    if @selected_index < @visible_start
      @visible_start = @selected_index
    elsif @selected_index >= @visible_start + @visible_count
      @visible_start = @selected_index - @visible_count + 1
    end
  end
end

model = ListModel.new
Term2.run(model, options: Term2::ProgramOptions.new(
  Term2::WithMouseAllMotion.new
))