require "../../../src/term2"

include Term2::Prelude

class SpinnersModel
  include Term2::Model

  SPINNERS = [
    TC::Spinner::LINE,
    TC::Spinner::DOT,
    TC::Spinner::MINI_DOT,
    TC::Spinner::JUMP,
    TC::Spinner::PULSE,
    TC::Spinner::POINTS,
    TC::Spinner::GLOBE,
    TC::Spinner::MOON,
    TC::Spinner::MONKEY,
  ]

  TEXT_STYLE    = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 252))
  SPINNER_STYLE = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 69))
  HELP_STYLE    = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 241))

  getter index : Int32
  getter spinner : TC::Spinner

  def initialize
    @index = 0
    @spinner = TC::Spinner.new(SPINNERS[@index])
    @spinner.style = SPINNER_STYLE
  end

  def init : Term2::Cmd
    @spinner.tick
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q", "esc"
        return {self, Term2::Cmds.quit}
      when "h", "left"
        @index -= 1
        @index = SPINNERS.size - 1 if @index < 0
        reset_spinner
        return {self, @spinner.tick}
      when "l", "right"
        @index += 1
        @index = 0 if @index >= SPINNERS.size
        reset_spinner
        return {self, @spinner.tick}
      end
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    gap = @index == 1 ? "" : " "
    s = "\n #{@spinner.view}#{gap}#{TEXT_STYLE.render("Spinning...")}\n\n"
    s += HELP_STYLE.render("h/l, ←/→: change spinner • q: exit\n")
    s
  end

  private def reset_spinner
    @spinner = TC::Spinner.new(SPINNERS[@index])
    @spinner.style = SPINNER_STYLE
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SpinnersModel.new)
end
