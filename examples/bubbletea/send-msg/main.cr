require "../../../src/term2"
require "random"

include Term2::Prelude

SEND_MSG_SPINNER_STYLE = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 63))
SEND_MSG_HELP_STYLE    = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 241)).margin(1, 0)
SEND_MSG_DOT_STYLE     = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 241))
DURATION_STYLE         = SEND_MSG_DOT_STYLE
SEND_MSG_APP_STYLE     = Term2::Style.new.margin(1, 2, 0, 2)

class ResultMsg < Term2::Message
  getter duration : Time::Span
  getter food : String

  def initialize(@food : String, @duration : Time::Span)
  end

  def to_s : String
    if @duration == Time::Span.zero
      SEND_MSG_DOT_STYLE.render("." * 30)
    else
      "🍔 Ate #{@food} " + DURATION_STYLE.render(@duration.to_s)
    end
  end
end

class SendMsgModel
  include Term2::Model

  getter spinner : TC::Spinner
  getter results : Array(ResultMsg)
  getter? quitting : Bool

  def initialize
    @spinner = TC::Spinner.new
    @spinner.style = SEND_MSG_SPINNER_STYLE
    @results = Array(ResultMsg).new(5, ResultMsg.new("", Time::Span.zero))
    @quitting = false
  end

  def init : Term2::Cmd
    @spinner.tick
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      @quitting = true
      return {self, Term2::Cmds.quit}
    when ResultMsg
      @results.shift
      @results << msg
      return {self, nil}
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    s = ""

    if @quitting
      s += "That’s all for today!"
    else
      s += @spinner.view + " Eating food..."
    end

    s += "\n\n"
    @results.each { |res| s += res.to_s + "\n" }

    unless @quitting
      s += SEND_MSG_HELP_STYLE.render("Press any key to exit")
    end

    s += "\n" if @quitting

    SEND_MSG_APP_STYLE.render(s)
  end
end

def random_food : String
  foods = [
    "an apple", "a pear", "a gherkin", "a party gherkin",
    "a kohlrabi", "some spaghetti", "tacos", "a currywurst", "some curry",
    "a sandwich", "some peanut butter", "some cashews", "some ramen",
  ]
  foods.sample
end

def simulate(program : Term2::Program(SendMsgModel))
  spawn do
    loop do
      pause = Random.rand(100..999).milliseconds
      sleep pause
      program.dispatch(ResultMsg.new(random_food, pause))
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  program = Term2::Program(SendMsgModel).new(SendMsgModel.new)
  simulate(program)
  program.run
end
