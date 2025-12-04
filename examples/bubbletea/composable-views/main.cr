require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

enum SessionState
  TimerView
  SpinnerView
end

class ComposableModel
  include Term2::Model

  DEFAULT_TIME = 60.seconds

  MODEL_STYLE = Term2::Style.new.width(15).height(5).align(:center).border(Term2::Border.hidden)
  FOCUSED_MODEL_STYLE = Term2::Style.new.width(15).height(5).align(:center).border(Term2::Border.normal).border_foreground(Term2::Color.rgb(69, 69, 69))
  SPINNER_STYLE = Term2::Style.new.foreground(Term2::Color.rgb(69, 69, 69))
  HELP_STYLE = Term2::Style.new.foreground(Term2::Color.rgb(241, 241, 241))

  getter state : SessionState
  getter timer : TC::Timer
  getter spinner : TC::Spinner
  getter index : Int32

  def initialize(timeout : Time::Span = DEFAULT_TIME)
    @state = SessionState::TimerView
    @timer = TC::Timer.new(timeout: timeout, interval: 1.second)
    @spinner = TC::Spinner.new
    @index = 0
    reset_spinner
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(@timer.tick_cmd, @spinner.tick)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    cmds = [] of Term2::Cmd
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        return {self, Term2::Cmds.quit}
      when "tab"
        @state = @state == SessionState::TimerView ? SessionState::SpinnerView : SessionState::TimerView
      when "n"
        if @state == SessionState::TimerView
          @timer = TC::Timer.new(timeout: DEFAULT_TIME, interval: 1.second)
          cmds << @timer.tick_cmd
        else
          next_spinner
          reset_spinner
          cmds << @spinner.tick
        end
      end

      case @state
      when SessionState::SpinnerView
        @spinner, cmd = @spinner.update(msg)
        cmds << cmd if cmd
      else
        @timer, cmd = @timer.update(msg)
        cmds << cmd if cmd
      end
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      cmds << cmd if cmd
    when TC::Timer::TickMsg
      @timer, cmd = @timer.update(msg)
      cmds << cmd if cmd
    end

    {self, Term2::Cmds.batch(cmds.compact)}
  end

  def view : String
    focused_timer = @state == SessionState::TimerView
    left = (focused_timer ? FOCUSED_MODEL_STYLE : MODEL_STYLE).render(@timer.view.rjust(4))
    right = (focused_timer ? MODEL_STYLE : FOCUSED_MODEL_STYLE).render(@spinner.view)
    model_name = focused_timer ? "timer" : "spinner"
    String.build do |str|
      str << Term2.join_horizontal(Term2::Position::Top, left, right)
      str << HELP_STYLE.render("\ntab: focus next • n: new #{model_name} • q: exit\n")
    end
  end

  def current_focused_model : String
    @state == SessionState::TimerView ? "timer" : "spinner"
  end

  def next_spinner
    @index = (@index + 1) % TC::Spinner::SPINNERS.size
  end

  def reset_spinner
    @spinner = TC::Spinner.new(TC::Spinner::SPINNERS[@index])
    @spinner.style = SPINNER_STYLE
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ComposableModel.new)
end
