require "../../../src/term2"

include Term2::Prelude

class ResponseMsg < Term2::Message
end

def listen_for_activity(ch : Channel(Nil)) : Term2::Cmd
  -> : Term2::Message? {
    loop do
      sleep Random.rand(100..1000).milliseconds
      ch.send(nil)
    end
  }
end

def wait_for_activity(ch : Channel(Nil)) : Term2::Cmd
  -> : Term2::Message? {
    ch.receive?
    ResponseMsg.new
  }
end

class RealtimeModel
  include Term2::Model

  getter sub : Channel(Nil)
  getter responses : Int32
  getter spinner : TC::Spinner
  getter? quitting : Bool

  def initialize
    @sub = Channel(Nil).new(1)
    @responses = 0
    @spinner = TC::Spinner.new
    @quitting = false
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(
      @spinner.tick,
      listen_for_activity(@sub),
      wait_for_activity(@sub),
    )
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      @quitting = true
      return {self, Term2::Cmds.quit}
    when ResponseMsg
      @responses += 1
      return {self, wait_for_activity(@sub)}
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    s = "\n #{@spinner.view} Events received: #{@responses}\n\n Press any key to exit\n"
    s += "\n" if @quitting
    s
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(RealtimeModel.new)
end
