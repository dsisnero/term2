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
end

class MouseFocusApp < Application
  def init
    # Start with initial model
    AppModel.new(events: ["Started! Move your mouse or click."])
  end

  # Configure program options for mouse and focus
  def options : Array(Term2::ProgramOption)
    [
      WithAltScreen.new,      # Use alternate screen
      WithMouseAllMotion.new, # Track all mouse motion (including hover)
      WithReportFocus.new,    # Report focus in/out events
    ]
  end

  def update(msg : Message, model : Model)
    app = model.as(AppModel)

    case msg
    when KeyPress
      case msg.key
      when "q", "\u0003" # q or Ctrl+C
        {app, Cmd.quit}
      else
        new_events = add_event(app.events, "Key: #{msg.key.inspect}")
        {AppModel.new(app.mouse_x, app.mouse_y, app.mouse_button, app.mouse_action, app.focused?, new_events), Cmd.none}
      end
    when MouseEvent
      # Handle mouse events
      new_events = add_event(app.events, "Mouse: #{msg.action} #{msg.button} at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: msg.button.to_s,
        mouse_action: msg.action.to_s,
        focused: app.focused?,
        events: new_events
      )
      {new_model, Cmd.none}
    when FocusMsg
      # Terminal gained focus
      new_events = add_event(app.events, "Window FOCUSED")
      {AppModel.new(app.mouse_x, app.mouse_y, app.mouse_button, app.mouse_action, true, new_events), Cmd.none}
    when BlurMsg
      # Terminal lost focus
      new_events = add_event(app.events, "Window BLURRED")
      {AppModel.new(app.mouse_x, app.mouse_y, app.mouse_button, app.mouse_action, false, new_events), Cmd.none}
    else
      {app, Cmd.none}
    end
  end

  # Keep only last 10 events
  private def add_event(events : Array(String), event : String) : Array(String)
    new_events = events.dup
    new_events << event
    new_events.shift if new_events.size > 10
    new_events
  end

  def view(model : Model) : String
    app = model.as(AppModel)
    focus_indicator = app.focused? ? "●" : "○"
    focus_status = if app.focused?
                     S.green | "#{focus_indicator} FOCUSED"
                   else
                     S.red | "#{focus_indicator} BLURRED"
                   end

    String.build do |s|
      s << (S.bold.cyan | "╔══════════════════════════════════════════════════════╗") << "\n"
      s << (S.bold.cyan | "║           Mouse & Focus Demo                         ║") << "\n"
      s << (S.bold.cyan | "╚══════════════════════════════════════════════════════╝") << "\n"
      s << "\n"
      s << "Mouse Position:".bold << " (#{app.mouse_x}, #{app.mouse_y})\n"
      s << "Button:".bold << " #{app.mouse_button}\n"
      s << "Action:".bold << " #{app.mouse_action}\n"
      s << "\n"
      s << "Window Status:".bold << " #{focus_status}\n"
      s << "\n"
      s << (S.bold.yellow | "Recent Events:") << "\n"
      app.events.each do |event|
        s << "  • #{event}\n"
      end
      s << "\n"
      s << "──────────────────────────────────────────────────────".gray << "\n"
      s << "Press 'q' or Ctrl+C to quit".gray << "\n"
    end
  end
end

MouseFocusApp.new.run
