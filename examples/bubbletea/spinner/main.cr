require "../../../src/term2"

include Term2::Prelude

class SpinnerModel
  include Term2::Model

  getter spinner : TC::Spinner
  getter? quitting : Bool
  getter err : Exception?

  def initialize
    s = TC::Spinner.new(TC::Spinner::DOT)
    s.style = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 205))
    @spinner = s
    @quitting = false
    @err = nil
  end

  def init : Term2::Cmd
    @spinner.tick
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "esc", "ctrl+c"
        @quitting = true
        return {self, Term2::Cmds.quit}
      end
    else
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    if err = @err
      return err.message || err.to_s
    end
    str = "\n\n   #{@spinner.view} Loading forever...press q to quit\n\n"
    @quitting ? str + "\n" : str
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SpinnerModel.new)
end
