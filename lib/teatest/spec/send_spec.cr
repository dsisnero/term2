require "./spec_helper"

describe "Teatest send" do
  it "sends messages between programs" do
    m1 = ConnectedModel.new("m1")
    m2 = ConnectedModel.new("m2")

    tm1 = Teatest.new_test_model(m1, [Teatest.with_initial_term_size(70, 30)])
    tm2 = Teatest.new_test_model(m2, [Teatest.with_initial_term_size(70, 30)])
    begin
      m1.programs << tm2
      m2.programs << tm1

      tm1.type("pp")
      tm2.type("pppp")

      tm1.type("q")
      tm2.type("q")

      out1 = read_bytes(tm1.final_output([Teatest.with_final_timeout(1.second)]))
      out2 = read_bytes(tm2.final_output([Teatest.with_final_timeout(1.second)]))

      out1.should eq out2
      Teatest.require_equal_output("TestAppSendToOtherProgram", out1)
    ensure
      tm1.quit
      tm2.quit
    end
  end
end

struct ConnectedModel
  include Term2::Model
  property programs : Array(Teatest::Program)
  @msgs : Array(String)

  def initialize(@name : String)
    @programs = [] of Teatest::Program
    @msgs = [] of String
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "p"
        send = Ping.new("from #{@name}")
        @msgs << send.value
        @programs.each { |p| p.send(send) }
        puts %(sent ping "#{send.value}" to others)
      when "q"
        return {self, Term2.quit}
      end
    when Ping
      puts %(rcvd ping "#{msg.value}" on #{@name})
      @msgs << msg.value
    end
    {self, nil}
  end

  def view : String
    "All pings:\n" + @msgs.join("\n")
  end
end

class Ping < Term2::Message
  getter value : String

  def initialize(@value : String)
  end
end
