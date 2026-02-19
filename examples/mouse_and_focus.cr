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
TITLE_STYLE = Lipgloss::Style.new
  .bold(true)
  .foreground(Lipgloss::Color::CYAN)

LABEL_STYLE   = Lipgloss::Style.new.bold(true)
HEADER_STYLE  = Lipgloss::Style.new.bold(true).foreground(Lipgloss::Color::YELLOW)
FOCUSED_STYLE = Lipgloss::Style.new.foreground(Lipgloss::Color::GREEN)
BLURRED_STYLE = Lipgloss::Style.new.foreground(Lipgloss::Color::RED)
DIM_STYLE     = Lipgloss::Style.new.foreground(Lipgloss::Color::BRIGHT_BLACK) # gray

class AppModel
  include Term2::Model
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

  def init : Term2::Cmd
    # Start with initial model
    @events = ["Started! Move your mouse or click."]
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.string
      when "q", "ctrl+c"
        {self, Term2::Cmds.quit}
      else
        new_events = add_event(@events, "Key: #{msg.key.inspect}")
        {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, @focused, new_events), Term2::Cmds.none}
      end
    when Term2::MouseClickMsg
      # Handle mouse click
      new_events = add_event(@events, "Mouse: click #{msg.button} at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: msg.button.to_s,
        mouse_action: "click",
        focused: @focused,
        events: new_events
      )
      {new_model, Term2::Cmds.none}
    when Term2::MouseMotionMsg
      # Handle mouse motion
      new_events = add_event(@events, "Mouse: motion at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: "none",
        mouse_action: "motion",
        focused: @focused,
        events: new_events
      )
      {new_model, Term2::Cmds.none}
    when Term2::MouseReleaseMsg
      # Handle mouse release
      new_events = add_event(@events, "Mouse: release #{msg.button} at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: msg.button.to_s,
        mouse_action: "release",
        focused: @focused,
        events: new_events
      )
      {new_model, Term2::Cmds.none}
    when Term2::MouseWheelMsg
      # Handle mouse wheel
      new_events = add_event(@events, "Mouse: wheel #{msg.button} at (#{msg.x}, #{msg.y})")
      new_model = AppModel.new(
        mouse_x: msg.x,
        mouse_y: msg.y,
        mouse_button: msg.button.to_s,
        mouse_action: "wheel",
        focused: @focused,
        events: new_events
      )
      {new_model, Term2::Cmds.none}
    when Term2::FocusMsg
      # Terminal gained focus
      new_events = add_event(@events, "Window FOCUSED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, true, new_events), Term2::Cmds.none}
    when Term2::BlurMsg
      # Terminal lost focus
      new_events = add_event(@events, "Window BLURRED")
      {AppModel.new(@mouse_x, @mouse_y, @mouse_button, @mouse_action, false, new_events), Term2::Cmds.none}
    else
      {self, Term2::Cmds.none}
    end
  end

  # Keep only last 10 events
  private def add_event(events : Array(String), event : String) : Array(String)
    new_events = events.dup
    new_events << event
    new_events.shift if new_events.size > 10
    new_events
  end

  def view : Term2::View
    focus_indicator = @focused ? "●" : "○"
    focus_status = if @focused
                     FOCUSED_STYLE.render("#{focus_indicator} FOCUSED")
                   else
                     BLURRED_STYLE.render("#{focus_indicator} BLURRED")
                   end

    content = String.build do |str|
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

    Term2::View.new(
      content: content,
      window_title: "Mouse & Focus Demo",
      alt_screen: true,
      mouse_mode: Term2::MouseMode::AllMotion,
      report_focus: true
    )
  end
end

Term2.run(AppModel.new)
