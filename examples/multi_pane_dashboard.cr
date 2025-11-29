# Multi-Pane Dashboard Example
#
# This example demonstrates:
# - Multiple concurrent panes with different components
# - Component embedding and concurrent updates
# - Layout DSL for complex grid layouts
# - Styling with borders and colors
#
# Run with: crystal run examples/multi_pane_dashboard.cr
require "../src/term2"
require "../src/components/spinner"
require "../src/components/timer"
require "../src/components/text_input"

include Term2::Prelude

# --- Component Definitions ---

# Counter Component
class CounterModel
  getter count : Int32

  def initialize(@count = 0); end
end

module Counter
  def self.update(msg : Message, model : CounterModel) : {CounterModel, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "k", "up"   then {CounterModel.new(model.count + 1), Cmd.none}
      when "j", "down" then {CounterModel.new(model.count - 1), Cmd.none}
      else                  {model, Cmd.none}
      end
    else
      {model, Cmd.none}
    end
  end

  def self.render(model : CounterModel) : Layout::Node
    Layout::VStack.new.tap do |stack|
      stack.add(Layout::Text.new("Counter".bold.underline))
      stack.add(Layout::Text.new("#{model.count}".bold.cyan))
      stack.add(Layout::Text.new("[↑/k] increment".gray))
      stack.add(Layout::Text.new("[↓/j] decrement".gray))
    end
  end

  def self.view(model : CounterModel) : String
    Layout.render(25, 8) do
      border("Counter", color: :blue) do
        add Counter.render(model)
      end
    end
  end
end

# Spinner Component
class SpinnerModel
  property spinner : Term2::Components::Spinner
  property? running : Bool = false

  def initialize
    @spinner = Term2::Components::Spinner.new(Term2::Components::Spinner::DOT)
    @spinner.style = Style.magenta
  end
end

module Spinner
  def self.update(msg : Message, model : SpinnerModel) : {SpinnerModel, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "s"
        model.running = !model.running?
        return {model, model.running? ? model.spinner.tick : Cmd.none}
      end
    end

    if model.running?
      new_spinner, cmd = model.spinner.update(msg)
      model.spinner = new_spinner
      {model, cmd}
    else
      {model, Cmd.none}
    end
  end

  def self.render(model : SpinnerModel) : Layout::Node
    Layout::VStack.new.tap do |stack|
      stack.add(Layout::Text.new("Spinner".bold.underline))
      stack.add(Layout::Text.new(model.spinner.view))
      status = model.running? ? "running".green : "stopped".red
      stack.add(Layout::Text.new("Status: #{status}"))
      stack.add(Layout::Text.new("[s] toggle".gray))
    end
  end

  def self.view(model : SpinnerModel) : String
    Layout.render(25, 8) do
      border("Spinner", color: :magenta) do
        add Spinner.render(model)
      end
    end
  end
end

# Timer Component
class TimerModel
  property timer : Term2::Components::Timer
  property? running : Bool = false

  def initialize
    @timer = Term2::Components::Timer.new(10.seconds)
  end
end

module Timer
  def self.update(msg : Message, model : TimerModel) : {TimerModel, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "t"
        model.running = !model.running?
        return {model, model.running? ? model.timer.start : model.timer.stop}
      when "r"
        model.timer = Term2::Components::Timer.new(10.seconds)
        model.running = false
        return {model, Cmd.none}
      end
    end

    new_timer, cmd = model.timer.update(msg)
    model.timer = new_timer
    {model, cmd}
  end

  def self.render(model : TimerModel) : Layout::Node
    Layout::VStack.new.tap do |stack|
      stack.add(Layout::Text.new("Timer".bold.underline))
      stack.add(Layout::Text.new(model.timer.view.bold.yellow))
      status = model.running? ? "running".green : "stopped".red
      stack.add(Layout::Text.new("Status: #{status}"))
      stack.add(Layout::Text.new("[t] start/stop".gray))
      stack.add(Layout::Text.new("[r] reset".gray))
    end
  end

  def self.view(model : TimerModel) : String
    Layout.render(25, 8) do
      border("Timer", color: :yellow) do
        add Timer.render(model)
      end
    end
  end
end

# Text Input Component
class InputModel
  property text_input : Term2::Components::TextInput

  def initialize
    @text_input = Term2::Components::TextInput.new
    @text_input.placeholder = "Type something..."
    @text_input.focus
  end
end

module Input
  def self.update(msg : Message, model : InputModel) : {InputModel, Cmd}
    new_ti, cmd = model.text_input.update(msg)
    model.text_input = new_ti
    {model, cmd}
  end

  def self.render(model : InputModel) : Layout::Node
    Layout::VStack.new.tap do |stack|
      stack.add(Layout::Text.new("Text Input".bold.underline))
      stack.add(Layout::Text.new(model.text_input.view))
      stack.add(Layout::Text.new("Type to enter text".gray))
    end
  end

  def self.view(model : InputModel) : String
    Layout.render(25, 8) do
      border("Text Input", color: :cyan) do
        add Input.render(model)
      end
    end
  end
end

# --- Main Application ---

class DashboardModel < Model
  getter counter : CounterModel
  getter spinner : SpinnerModel
  getter timer : TimerModel
  getter input : InputModel
  getter width : Int32
  getter height : Int32

  def initialize(
    @counter = CounterModel.new,
    @spinner = SpinnerModel.new,
    @timer = TimerModel.new,
    @input = InputModel.new,
    @width = 80,
    @height = 24,
  )
  end

  def init : Cmd
    # Start with spinner running
    Cmd.batch(
      @spinner.spinner.tick,
      @input.text_input.focus
    )
  end

  def update(msg : Message) : {Model, Cmd}
    # Global keys
    case msg
    when WindowSizeMsg
      return {DashboardModel.new(@counter, @spinner, @timer, @input, msg.width, msg.height), Cmd.none}
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2.quit}
      end
    end

    # Update all components concurrently
    new_counter, counter_cmd = Counter.update(msg, @counter)
    new_spinner, spinner_cmd = Spinner.update(msg, @spinner)
    new_timer, timer_cmd = Timer.update(msg, @timer)
    new_input, input_cmd = Input.update(msg, @input)

    new_model = DashboardModel.new(
      new_counter,
      new_spinner,
      new_timer,
      new_input,
      @width,
      @height
    )

    {new_model, Cmd.batch(counter_cmd, spinner_cmd, timer_cmd, input_cmd)}
  end

  def view : String
    Layout.render(@width, @height) do
      padding(1, flex: 1) do
        text "Multi-Pane Dashboard".bold.center(@width)
        text "Four concurrent components running independently".gray.center(@width)

        # 2x2 grid layout
        v_stack(flex: 1) do
          # Row 1: Counter and Spinner
          h_stack(gap: 2, flex: 1) do
            # Counter Pane
            v_stack(flex: 1) do
              add Counter.render(@counter)
            end

            # Spinner Pane
            v_stack(flex: 1) do
              add Spinner.render(@spinner)
            end
          end

          # Row 2: Timer and Text Input
          h_stack(gap: 2, flex: 1) do
            # Timer Pane
            v_stack(flex: 1) do
              add Timer.render(@timer)
            end

            # Text Input Pane
            v_stack(flex: 1) do
              add Input.render(@input)
            end
          end
        end

        text "Press [q] or [Ctrl+C] to quit".on_black.center(@width)
      end
    end
  end
end

Term2.run(DashboardModel.new, options: Term2::ProgramOptions.new(WithAltScreen.new))
