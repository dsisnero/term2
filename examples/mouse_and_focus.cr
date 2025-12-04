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

# Define styles
TITLE_STYLE = Term2::Style.new
  .bold(true)
  .cyan

LABEL_STYLE   = Term2::Style.new.bold(true)
HEADER_STYLE  = Term2::Style.new.bold(true).yellow
FOCUSED_STYLE = Term2::Style.new.green
BLURRED_STYLE = Term2::Style.new.red
DIM_STYLE     = Term2::Style.new.dark_gray # gray

class AppModel
  include Model
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
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      else
        new_events = add_event(@events, "Key: #{msg.key.inspect}")
        {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, @focused, new_events), Cmds.none}
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
      {new_model, Cmds.none}
    when FocusMsg
      # Terminal gained focus
      new_events = add_event(@events, "Window FOCUSED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, true, new_events), Cmds.none}
    when BlurMsg
      # Terminal lost focus
      new_events = add_event(@events, "Window BLURRED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, false, new_events), Cmds.none}
    else
      {self, Cmds.none}
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
                     FOCUSED_STYLE.render("#{focus_indicator} FOCUSED")
                   else
                     BLURRED_STYLE.render("#{focus_indicator} BLURRED")
                   end

    String.build do |str|
      str << TITLE_STYLE.render("╔══════════════════════════════════════════════════════╗") << "\n"
      str << TITLE_STYLE.render("║           Mouse & Focus Demo                         ║") << "\n"
      str << TITLE_STYLE.render("╚══════════════════════════════════════════════════════╝") << "\n"
      str << "\n"
      str << LABEL_STYLE.render("Mouse Position:") << " (#{@mouse_x}, #{@mouse_y})\n"
      str << LABEL_STYLE.render("Button:") << " #{@mouse_button}\n"
      str << LABEL_STYLE.render("Action:") << " #{@mouse_action}\n"
      str << "\n"
      str << LABEL_STYLE.render("Window Status:") << " #{focus_status}\n"
      str << "\n"
      str << HEADER_STYLE.render("Recent Events:") << "\n"
      @events.each do |event|
        str << "  • #{event}\n"
      end
      str << "\n"
      str << DIM_STYLE.render("──────────────────────────────────────────────────────") << "\n"
      str << DIM_STYLE.render("Press 'q' or Ctrl+C to quit") << "\n"
    end
  end
end

Term2.run(AppModel.new, options: Term2::ProgramOptions.new(
  WithAltScreen.new,      # Use alternate screen
  WithMouseAllMotion.new, # Track all mouse motion (including hover)
  WithReportFocus.new,    # Report focus in/out events
))
