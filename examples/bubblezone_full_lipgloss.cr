# BubbleZone Full Lipgloss Example (Term2 version with proper Lipgloss)
#
# This is a Term2 conversion of the BubbleZone full-lipgloss example.
# It demonstrates a complex UI with multiple interactive components:
# - Tabs with clickable navigation
# - Interactive lists with checkboxes
# - Dialog with buttons
# - History panel with clickable items
#
# Original Go example: https://github.com/lrstanley/bubblezone/tree/master/examples/full-lipgloss

require "../src/term2"
require "../src/bubblezone"
require "../src/lipgloss"

include Term2::Prelude

# Colors
SUBTLE    = Term2::Color.rgb(56, 56, 56)    # #383838
HIGHLIGHT = Term2::Color.rgb(125, 86, 244)  # #7D56F4
SPECIAL   = Term2::Color.rgb(115, 245, 159) # #73F59F

# Styles using Lipgloss
class Styles
  # Tab styles
  def self.tab_style
    Term2::LipGloss::Style.new
      .border(Term2::LipGloss::Border.normal)
      .border_foreground(HIGHLIGHT)
      .padding(0, 1)
  end

  def self.active_tab_style
    Term2::LipGloss::Style.new
      .border(Term2::LipGloss::Border.normal)
      .border_foreground(HIGHLIGHT)
      .padding(0, 1)
      .bold
  end

  # List styles
  def self.list_style
    Term2::LipGloss::Style.new
      .border_right(true)
      .border_foreground(SUBTLE)
      .margin(0, 2, 0, 0)
  end

  def self.list_header_style
    Term2::LipGloss::Style.new
      .border_bottom(true)
      .border_foreground(SUBTLE)
      .margin(0, 2, 0, 0)
  end

  def self.list_item_style
    Term2::LipGloss::Style.new
      .padding(0, 0, 0, 2)
  end

  def self.list_done_style(text)
    Term2::LipGloss::Style.new
      .foreground(SUBTLE)
      .strikethrough
      .render(text)
  end

  # Dialog styles
  def self.dialog_box_style
    Term2::LipGloss::Style.new
      .border(Term2::LipGloss::Border.rounded)
      .border_foreground(Term2::Color.rgb(135, 75, 253))  # #874BFD
      .padding(1, 0)
  end

  def self.button_style
    Term2::LipGloss::Style.new
      .foreground(Term2::Color.rgb(255, 247, 219))  # #FFF7DB
      .background(Term2::Color.rgb(136, 139, 126))  # #888B7E
      .padding(0, 3)
      .margin(1, 2, 0, 0)
  end

  def self.active_button_style
    Term2::LipGloss::Style.new
      .foreground(Term2::Color.rgb(255, 247, 219))  # #FFF7DB
      .background(Term2::Color.rgb(242, 93, 148))   # #F25D94
      .margin(0, 2, 0, 0)
      .underline
  end

  # History styles
  def self.history_style(width, height)
    Term2::LipGloss::Style.new
      .align(Term2::LipGloss::Position::Left)
      .foreground(Term2::Color.rgb(250, 250, 250))  # #FAFAFA
      .background(SUBTLE)
      .margin(1)
      .padding(1, 2)
      .width(width)
      .height(height)
  end
end

# Tab component
class TabsModel < Term2::Model
  property id : String
  property height : Int32
  property width : Int32
  property active : String
  property tabs : Array(String)
  property zone_manager : BubbleZone::ZoneManager

  def initialize(@id : String, @height : Int32, @active : String, @tabs : Array(String))
    @width = 0
    @zone_manager = BubbleZone::ZoneManager.new
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when WindowSizeMsg
      @width = msg.width
    when MouseEvent
      if msg.action == "press" && msg.button == "left"
        @tabs.each do |tab|
          zone = @zone_manager.find_at(msg.x, msg.y)
          if zone && zone.id == @id + tab
            @active = tab
            break
          end
        end
      end
    end
    {self, Cmd.none}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate tab positions
    tab_width = (@width // @tabs.size) - 2
    start_x = 0

    # Create zones for each tab
    @tabs.each_with_index do |tab, index|
      tab_x = start_x + (index * tab_width)
      @zone_manager.add(BubbleZone::ZoneInfo.new(
        @id + tab,
        1,
        tab_x,
        0,
        tab_x + tab_width - 1,
        0
      ))
    end

    # Render tabs using Lipgloss
    @tabs.map_with_index do |tab, index|
      style = tab == @active ? Styles.active_tab_style : Styles.tab_style
      style.render(tab)
    end.join(" ")
  end
end

# List component
class ListModel < Term2::Model
  class Item
    property name : String
    property? done : Bool = false

    def initialize(@name : String, @done = false)
    end

  end

  property id : String
  property height : Int32
  property width : Int32
  property title : String
  property items : Array(Item)
  property zone_manager : BubbleZone::ZoneManager

  def initialize(@id : String, @height : Int32, @title : String, @items : Array(Item))
    @width = 0
    @zone_manager = BubbleZone::ZoneManager.new
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when WindowSizeMsg
      @width = msg.width
    when MouseEvent
      if msg.action == "press" && msg.button == "left"
        @items.each_with_index do |item, index|
          zone = @zone_manager.find_at(msg.x, msg.y)
          if zone && zone.id == @id + item.name
            @items[index].done = !@items[index].done?
            break
          end
        end
      end
    end
    {self, Cmd.none}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate list position
    list_width = 25
    start_x = 0
    start_y = 0

    # Create zones for each list item
    @items.each_with_index do |item, index|
      item_y = start_y + index + 1
      @zone_manager.add(BubbleZone::ZoneInfo.new(
        @id + item.name,
        1,
        start_x,
        item_y,
        start_x + list_width - 1,
        item_y
      ))
    end

    # Render list using Lipgloss
    output = [Styles.list_header_style.render(@title)]

    @items.each do |item|
      item_text = if item.done?
                    "✓ #{item.name}"
                  else
                    "  #{item.name}"
                  end

      styled_text = Styles.list_item_style.render(item_text)
      if item.done?
        styled_text = Styles.list_done_style(styled_text)
      end

      output << styled_text
    end

    Styles.list_style.render(output.join("\n"))
  end
end

# Dialog component
class DialogModel < Term2::Model
  property id : String
  property height : Int32
  property width : Int32
  property active : String
  property question : String
  property zone_manager : BubbleZone::ZoneManager

  def initialize(@id : String, @height : Int32, @active : String, @question : String)
    @width = 0
    @zone_manager = BubbleZone::ZoneManager.new
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when WindowSizeMsg
      @width = msg.width
    when MouseEvent
      if msg.action == "press" && msg.button == "left"
        if zone = @zone_manager.find_at(msg.x, msg.y)
          if zone.id == @id + "confirm"
            @active = "confirm"
          elsif zone.id == @id + "cancel"
            @active = "cancel"
          end
        end
      end
    end
    {self, Cmd.none}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate dialog position
    start_x = 0
    start_y = 0

    # Create zones for buttons
    @zone_manager.add(BubbleZone::ZoneInfo.new(
      @id + "confirm",
      1,
      start_x + 5,
      start_y + 3,
      start_x + 10,
      start_y + 3
    ))

    @zone_manager.add(BubbleZone::ZoneInfo.new(
      @id + "cancel",
      1,
      start_x + 15,
      start_y + 3,
      start_x + 20,
      start_y + 3
    ))

    # Render dialog using Lipgloss
    dialog_content = String.build do |str|
      str << "#{@question}\n"
      str << "\n"

      if @active == "confirm"
        str << Styles.active_button_style.render("Yes") + " " + Styles.button_style.render("Maybe")
      else
        str << Styles.button_style.render("Yes") + " " + Styles.active_button_style.render("Maybe")
      end
    end

    Styles.dialog_box_style.render(dialog_content)
  end
end

# History component
class HistoryModel < Term2::Model
  property id : String
  property height : Int32
  property width : Int32
  property active : String
  property items : Array(String)
  property zone_manager : BubbleZone::ZoneManager

  def initialize(@id : String, @items : Array(String))
    @height = 0
    @width = 0
    @active = ""
    @zone_manager = BubbleZone::ZoneManager.new
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when WindowSizeMsg
      @height = msg.height
      @width = msg.width
    when MouseEvent
      if msg.action == "press" && msg.button == "left"
        @items.each do |item|
          zone = @zone_manager.find_at(msg.x, msg.y)
          if zone && zone.id == @id + item
            @active = item
            break
          end
        end
      end
    end
    {self, Cmd.none}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate history item positions
    item_width = (@width // @items.size) - 2
    start_x = 0

    # Create zones for each history item
    @items.each_with_index do |item, index|
      item_x = start_x + (index * item_width)
      @zone_manager.add(BubbleZone::ZoneInfo.new(
        @id + item,
        1,
        item_x,
        0,
        item_x + item_width - 1,
        @height - 2
      ))
    end

    # Render history items using Lipgloss
    history_content = @items.map do |item|
      if item == @active
        "[#{item[0..30]}...]"
      else
        " #{item[0..30]}... "
      end
    end.join(" | ")

    Styles.history_style(@width, @height).render(history_content)
  end
end

# Main application model
class FullLipglossModel < Term2::Model
  property height : Int32
  property width : Int32
  property tabs : TabsModel
  property dialog : DialogModel
  property list1 : ListModel
  property list2 : ListModel
  property history : HistoryModel
  property zone_manager : BubbleZone::ZoneManager

  def initialize
    @height = 0
    @width = 0

    @tabs = TabsModel.new(
      "tabs_",
      3,
      "Tab 1",
      ["Tab 1", "Tab 2", "Tab 3"]
    )

    @dialog = DialogModel.new(
      "dialog_",
      5,
      "confirm",
      "Are you sure you want to continue?"
    )

    @list1 = ListModel.new(
      "list1_",
      10,
      "To Do",
      [
        ListModel::Item.new("Buy groceries"),
        ListModel::Item.new("Walk the dog"),
        ListModel::Item.new("Finish project", true),
        ListModel::Item.new("Call mom"),
        ListModel::Item.new("Read book")
      ]
    )

    @list2 = ListModel.new(
      "list2_",
      10,
      "Completed",
      [
        ListModel::Item.new("Clean room", true),
        ListModel::Item.new("Pay bills", true),
        ListModel::Item.new("Exercise", true)
      ]
    )

    @history = HistoryModel.new(
      "history_",
      [
        "User clicked on Tab 1",
        "User toggled 'Buy groceries'",
        "Dialog confirmed",
        "User switched to Tab 2"
      ]
    )

    @zone_manager = BubbleZone::ZoneManager.new
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when WindowSizeMsg
      @height = msg.height
      @width = msg.width
    when MouseEvent
      # Delegate mouse events to child components
      @tabs.update(msg)
      @dialog.update(msg)
      @list1.update(msg)
      @list2.update(msg)
      @history.update(msg)
    end
    {self, Cmd.none}
  end

  def view : String
    # Clear previous zones
    @zone_manager.clear

    # Calculate layout
    content_height = @height - 6
    list_height = content_height // 2
    dialog_height = 5

    # Update child component dimensions
    @tabs.height = 1
    @tabs.width = @width

    @dialog.height = dialog_height
    @dialog.width = @width

    @list1.height = list_height
    @list1.width = @width // 2

    @list2.height = list_height
    @list2.width = @width // 2

    @history.height = 3
    @history.width = @width

    # Render using Lipgloss layout utilities
    tabs_view = @tabs.view
    dialog_view = @dialog.view
    list1_view = @list1.view
    list2_view = @list2.view
    history_view = @history.view

    # Combine views using Lipgloss layout
    lists_combined = Term2::LipGloss.join_horizontal(Term2::LipGloss::Position::Top, list1_view, list2_view)

    main_content = Term2::LipGloss.join_vertical(Term2::LipGloss::Position::Top,
      tabs_view,
      lists_combined,
      dialog_view,
      history_view
    )

    main_content
  end
end

# Run the application
if PROGRAM_NAME.includes?(__FILE__)
  model = FullLipglossModel.new
  Term2.run(model)
end
