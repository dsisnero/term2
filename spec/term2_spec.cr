require "./spec_helper"
include Term2::Prelude

private class SpecTextMessage < Term2::Msg
  getter value : String

  def initialize(@value : String)
  end
end

private class SpecTick < Term2::Msg
end

private class SpecCounterModel
  include Term2::Model

  getter count : Int32

  def initialize(@count : Int32 = 0)
  end

  def init : Term2::Cmd
    Term2::Cmds.tick(100.milliseconds) { |_| SpecTick.new }
  end

  def update(msg : Term2::Msg) : {self, Term2::Cmd}
    case msg
    when SpecTick
      {SpecCounterModel.new(count + 1), Term2::Cmds.quit}
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
    "Counter: #{count}\n"
  end
end

describe Term2 do
  describe Term2::Cmds do
    it "creates batch commands" do
      cmd = Term2::Cmds.batch(
        Term2::Cmds.message(SpecTextMessage.new("one")),
        Term2::Cmds.message(SpecTextMessage.new("two"))
      )
      cmd.should_not be_nil
    end

    it "creates message commands" do
      cmd = Term2::Cmds.message(SpecTextMessage.new("test"))
      cmd.should_not be_nil
      msg = cmd.not_nil!.call
      msg.should be_a(SpecTextMessage)
      msg.as(SpecTextMessage).value.should eq("test")
    end

    it "creates none command" do
      cmd = Term2::Cmds.none
      cmd.should be_nil
    end

    it "dispatches delayed messages" do
      cmd = Term2::Cmds.after(5.milliseconds, SpecTextMessage.new("delayed"))
      cmd.should_not be_nil
      # The command should return the message after the delay
      msg = cmd.not_nil!.call
      msg.should be_a(SpecTextMessage)
      msg.as(SpecTextMessage).value.should eq("delayed")
    end

    it "provides time to tick blocks" do
      tick_time : Time? = nil
      cmd = Term2::Cmds.tick(5.milliseconds) do |time|
        tick_time = time
        SpecTextMessage.new("tick")
      end

      msg = cmd.not_nil!.call
      msg.should be_a(SpecTextMessage)
      msg.as(SpecTextMessage).value.should eq("tick")
      tick_time.should be_a(Time)
    end

    it "dispatches timeout results" do
      fast = Term2::Cmds.timeout(50.milliseconds, SpecTextMessage.new("timeout")) do
        SpecTextMessage.new("fast")
      end
      fast.not_nil!.call.as(SpecTextMessage).value.should eq("fast")

      slow = Term2::Cmds.timeout(5.milliseconds, SpecTextMessage.new("timeout")) do
        sleep 50.milliseconds
        SpecTextMessage.new("slow")
      end
      slow.not_nil!.call.as(SpecTextMessage).value.should eq("timeout")
    end

    it "runs commands sequentially" do
      cmd = Term2::Cmds.sequence(
        Term2::Cmds.message(SpecTextMessage.new("first")),
        Term2::Cmds.message(SpecTextMessage.new("second"))
      )

      msg = cmd.not_nil!.call
      msg.should be_a(Term2::SequenceMsg)
      msg.as(Term2::SequenceMsg).cmds.size.should eq(2)
    end

    it "maps messages emitted by a command" do
      original = Term2::Cmds.message(SpecTextMessage.new("original"))
      cmd = Term2::Cmds.map(original) do |msg|
        text = msg.as(SpecTextMessage).value.upcase
        SpecTextMessage.new(text)
      end

      msg = cmd.not_nil!.call
      msg.as(SpecTextMessage).value.should eq("ORIGINAL")
    end
  end

  describe "KeyPress" do
    it "initializes with a key" do
      key_press = Term2::KeyPress.new("a")
      key_press.key.should eq("a")
    end
  end

  describe "MouseEvent" do
    it "initializes with coordinates and button" do
      mouse_event = Term2::MouseEvent.new(10, 20, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)
      mouse_event.x.should eq(10)
      mouse_event.y.should eq(20)
      mouse_event.button.should eq(Term2::MouseEvent::Button::Left)
    end
  end

  describe "Terminal" do
    it "provides terminal utilities" do
      # These methods should exist and not raise
      io = IO::Memory.new
      Terminal.clear(io)
      Terminal.hide_cursor(io)
      Terminal.show_cursor(io)

      size = Terminal.size
      size.should be_a(Tuple(Int32, Int32))
    end
  end

  describe Term2::Prelude do
    it "exposes shorter aliases" do
      Cmd.should eq(Term2::Cmd)
      Terminal.should eq(Term2::Terminal)
      Program.should eq(Term2::Program)
    end
  end

  describe Term2::KeyBinding do
    it "matches keys" do
      binding = Term2::KeyBinding.new(:action, ["a", "b"])
      binding.matches?("a").should be_true
      binding.matches?("c").should be_false
    end
  end

  describe Term2::KeyReader do
    it "reads a single character" do
      input = IO::Memory.new("a")
      reader = Term2::KeyReader.new
      key = reader.read_key(input)
      key.should_not be_nil
      key.try(&.to_s).should eq("a")
    end

    it "detects bracketed paste" do
      # Simulates: paste start + "hello" + paste end
      paste_sequence = "\e[200~hello\e[201~"
      input = IO::Memory.new(paste_sequence)
      reader = Term2::KeyReader.new

      # Need to read multiple times to collect all characters
      key : Term2::Key? = nil
      paste_sequence.size.times do
        result = reader.read_key(input)
        key = result if result
      end

      key.should_not be_nil
      if k = key
        k.paste?.should be_true
        k.runes.join.should eq("hello")
      end
    end

    it "does not set paste flag for normal input" do
      input = IO::Memory.new("hello")
      reader = Term2::KeyReader.new

      key = reader.read_key(input)
      key.should_not be_nil
      if k = key
        k.paste?.should be_false
      end
    end
  end

  describe Term2::ProgramOptions do
    it "applies message filter" do
      # Create a filter that transforms messages
      filter_called = false
      filter = ->(msg : Term2::Message) {
        filter_called = true
        msg
      }

      options = Term2::ProgramOptions.new
      options.add(Term2::WithFilter.new(filter))

      output = IO::Memory.new
      app = SpecCounterModel.new
      program = Term2::Program.new(app, input: nil, output: output, options: options)

      # Run program briefly
      evt = CML.choose([
        CML.wrap(CML.spawn_evt { program.run }) { |model| {model.as(Term2::Model?), :ok} },
        CML.wrap(CML.timeout(2.seconds)) { |_| {nil.as(Term2::Model?), :timeout} },
      ])
      CML.sync(evt)

      # The filter should have been called for at least one message
      filter_called.should be_true
    end
  end

  describe Program do
    it "runs until receiving a quit message" do
      output = IO::Memory.new
      options = Term2::ProgramOptions.new
      options.add(Term2::WithFPS.new(1000.0))
      program = Term2::Program.new(SpecCounterModel.new, input: nil, output: output, options: options)
      # Race the run loop against a timeout so specs don't hang.
      evt = CML.choose([
        CML.wrap(CML.spawn_evt { program.run }) { |model| {model.as(Term2::Model?), :ok} },
        CML.wrap(CML.timeout(2.seconds)) { |_| {nil.as(Term2::Model?), :timeout} },
      ])
      result = CML.sync(evt)

      result.should_not eq({nil, :timeout})
      model = result[0].as(Term2::Model)

      counter = model.as(SpecCounterModel)
      counter.count.should eq(1)
      output.to_s.should contain("Counter: 1")
    end
  end
end
