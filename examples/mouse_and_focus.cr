# Mouse and Focus Example
#
# This example demonstrates mouse tracking and focus reporting features.
# It shows how to:
# - Enable mouse tracking (all motion including hover)
# - Enable focus reporting
# - Handle MouseEvent messages
# - Handle FocusIn/FocusOut events
#
# Run with: crystal run examples/mouse_and_focus.cr
require "../src/term2"
include Term2::Prelude

class AppModel < Model
  getter mouse_x : Int32
  getter mouse_y : Int32
  getter mouse_button : String
  getter mouse_action : String
  getter? focused : Bool
  getter events : Array(String)

  def initialize(
    @mouse_x : Int32 = 0,
    @mouse_y : Int32 = 0,
    @mouse_button : String = "none",
    @mouse_action : String = "none",
    @focused : Bool = true,
    @events : Array(String) = [] of String,
  )
  end

  def init : Cmd
    # Start with initial model
    @events = ["Started! Move your mouse or click."]
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      else
        new_events = add_event(@events, "Key: #{msg.key.inspect}")
        {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, @focused, new_events), Cmd.none}
      end
    when MouseEvent
      # Handle mouse events
      new_events = add_event(@events, "Mouse: #{msg.action} #{msg.button} at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: msg.button.to_s,
        mouse_action: msg.action.to_s,
        focused: @focused,
        events: new_events
      )
      {new_model, Cmd.none}
    when FocusMsg
      # Terminal gained focus
      new_events = add_event(@events, "Window FOCUSED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, true, new_events), Cmd.none}
    when BlurMsg
      # Terminal lost focus
      new_events = add_event(@events, "Window BLURRED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, false, new_events), Cmd.none}
    else
      {self, Cmd.none}
    end
  end

  # Keep only last 10 events
  private def add_event(events : Array(String), event : String) : Array(String)
    new_events = events.dup
    new_events << event
    new_events.shift if new_events.size > 10
    new_events
  end

  def view : String
    focus_indicator = @focused ? "●" : "○"
    focus_status = if @focused
                     "#{focus_indicator} FOCUSED".green
                   else
                     "#{focus_indicator} BLURRED".red
                   end

    String.build do |str|
      str << "╔══════════════════════════════════════════════════════╗".bold.cyan << "\n"
      str << "║           Mouse & Focus Demo                         ║".bold.cyan << "\n"
      str << "╚══════════════════════════════════════════════════════╝".bold.cyan << "\n"
      str << "\n"
      str << "Mouse Position:".bold << " (#{@mouse_x}, #{@mouse_y})\n"
      str << "Button:".bold << " #{@mouse_button}\n"
      str << "Action:".bold << " #{@mouse_action}\n"
      str << "\n"
      str << "Window Status:".bold << " #{focus_status}\n"
      str << "\n"
      str << "Recent Events:".bold.yellow << "\n"
      @events.each do |event|
        str << "  • #{event}\n"
      end
      str << "\n"
      str << "──────────────────────────────────────────────────────".gray << "\n"
      str << "Press 'q' or Ctrl+C to quit".gray << "\n"
    end
  end
end

Term2.run(AppModel.new, options: Term2::ProgramOptions.new(
  WithAltScreen.new,      # Use alternate screen
  WithMouseAllMotion.new, # Track all mouse motion (including hover)
  WithReportFocus.new,    # Report focus in/out events
))
