require "./spec_helper"

describe "Teatest app" do
  it "runs a program and captures output" do
    model = CountdownModel.new(10)
    tm = Teatest.new_test_model(model, [Teatest.with_initial_term_size(70, 30)])
    begin
      sleep 1.2
      tm.type("I'm typing things, but it'll be ignored by my program")
      tm.type("ignored msg")
      tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Enter)))

      tm.quit

      output = read_bytes(tm.final_output([Teatest.with_final_timeout(1.second)]))
      output_str = String.new(output)
      output_str.should match(/This program will exit in \d+ seconds/)
      Teatest.require_equal_output("TestApp", output)

      tm.final_model.as(CountdownModel).value.should eq 9
    ensure
      tm.quit
    end
  end

  it "supports interactive output inspection" do
    model = CountdownModel.new(10)
    tm = Teatest.new_test_model(model, [Teatest.with_initial_term_size(70, 30)])
    begin
      sleep 1.2
      tm.type("ignored msg")

      output = read_bytes(tm.output)
      String.new(output).should contain("9 seconds")

      Teatest.wait_for(tm.output, ->(buffer : Bytes) { buffer.includes?('7'.ord.to_u8) }, [
        Teatest.with_duration(5.seconds),
        Teatest.with_check_interval(10.milliseconds),
      ])

      tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Enter)))
      tm.quit

      tm.final_model.as(CountdownModel).value.should eq 7
    ensure
      tm.quit
    end
  end
end

struct CountdownModel
  include Term2::Model
  getter value : Int32

  def initialize(@value : Int32)
  end

  def init : Term2::Cmd
    -> {
      sleep 1.second
      TickMsg.new.as(Term2::Msg)
    }
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      {self, Term2.quit}
    when TickMsg
      @value -= 1
      if @value <= 0
        {self, Term2.quit}
      else
        {self, init}
      end
    else
      {self, nil}
    end
  end

  def view : String
    "Hi. This program will exit in #{@value} seconds. To quit sooner press any key.\n"
  end
end

class TickMsg < Term2::Message
end
