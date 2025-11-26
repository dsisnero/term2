# Comprehensive Example
#
# Demonstrates:
# - View DSL for complex layouts
# - Component embedding (updating panes separately)
# - Generic Application(M) to avoid casting
# - Styling DSL
#
# Run with: crystal run examples/comprehensive_demo.cr
require "../src/term2"
include Term2::Prelude

# --- Components ---

# 1. Counter Component
class CounterModel < Model
  getter count : Int32

  def initialize(@count = 0); end
end

module Counter
  def self.update(msg : Message, model : CounterModel) : {CounterModel, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "+" then {CounterModel.new(model.count + 1), Cmd.none}
      when "-" then {CounterModel.new(model.count - 1), Cmd.none}
      else          {model, Cmd.none}
      end
    else
      {model, Cmd.none}
    end
  end

  def self.render(model : CounterModel) : Layout::Node
    # Return a Node directly for embedding
    Layout::VStack.new.tap do |stack|
      stack.add(Layout::Text.new("Counter".bold.underline))
      stack.add(Layout::Text.new("#{model.count}".cyan.bold))
      stack.add(Layout::Text.new("[+/-]".gray))
    end
  end

  def self.view(model : CounterModel) : String
    Layout.render(20, 5) do
      add Counter.render(model)
    end
  end
end

# 2. List Component
class ListModel < Model
  getter items : Array(String)
  getter selected : Int32

  def initialize(@items = ["Item 1", "Item 2", "Item 3"], @selected = 0); end
end

module List
  def self.update(msg : Message, model : ListModel) : {ListModel, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "j", "down"
        new_sel = (model.selected + 1) % model.items.size
        {ListModel.new(model.items, new_sel), Cmd.none}
      when "k", "up"
        new_sel = (model.selected - 1)
        new_sel = model.items.size - 1 if new_sel < 0
        {ListModel.new(model.items, new_sel), Cmd.none}
      else {model, Cmd.none}
      end
    else
      {model, Cmd.none}
    end
  end

  def self.render(model : ListModel) : Layout::Node
    Layout::VStack.new.tap do |stack|
      # stack.add(Layout::Text.new("List (j/k)".bold.underline))
      model.items.each_with_index do |item, i|
        if i == model.selected
          stack.add(Layout::Text.new("> #{item}".green.bold))
        else
          stack.add(Layout::Text.new("  #{item}"))
        end
      end
    end
  end

  def self.view(model : ListModel) : String
    Layout.render(30, 10) do
      add List.render(model)
    end
  end
end

# --- Main Application ---

class AppModel < Model
  getter counter : CounterModel
  getter list : ListModel
  getter active_pane : Int32 # 0 = Counter, 1 = List
  getter width : Int32
  getter height : Int32

  def initialize(
    @counter = CounterModel.new,
    @list = ListModel.new,
    @active_pane = 0,
    @width = 80,
    @height = 24,
  )
  end
end

class ComprehensiveApp < Application(AppModel)
  def init : AppModel
    AppModel.new
  end

  def options : Array(Term2::ProgramOption)
    [WithAltScreen.new] of Term2::ProgramOption
  end

  def update(msg : Message, model : AppModel)
    # Global keys
    case msg
    when WindowSizeMsg
      return {AppModel.new(model.counter, model.list, model.active_pane, msg.width, msg.height), Cmd.none}
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {model, Cmd.quit}
      when "tab"
        new_pane = (model.active_pane + 1) % 2
        return {AppModel.new(model.counter, model.list, new_pane, model.width, model.height), Cmd.none}
      end
    end

    # Route messages to active pane
    case model.active_pane
    when 0 # Counter
      new_counter, cmd = Counter.update(msg, model.counter)
      {AppModel.new(new_counter, model.list, model.active_pane, model.width, model.height), cmd}
    when 1 # List
      new_list, cmd = List.update(msg, model.list)
      {AppModel.new(model.counter, new_list, model.active_pane, model.width, model.height), cmd}
    else
      {model, Cmd.none}
    end
  end

  def view(model : AppModel) : String
    Layout.render(model.width, model.height) do
      padding(1, flex: 1) do
        text "Comprehensive Demo".bold.center(model.width)
        text "Press [Tab] to switch panes, [q] to quit".gray.center(model.width)

        h_stack(gap: 2, flex: 1) do
          # Counter Pane
          border("Counter", active: model.active_pane == 0, flex: 1) do
            add Counter.render(model.counter)
          end

          # List Pane
          border("List", active: model.active_pane == 1, flex: 1) do
            add List.render(model.list)
          end
        end

        text "Status: Pane #{model.active_pane} Active".on_blue
      end
    end
  end
end

ComprehensiveApp.new.run
