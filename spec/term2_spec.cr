require "./spec_helper"
include Term2::Prelude

private class SpecTextMessage < Term2::Message
  getter value : String

  def initialize(@value : String)
  end
end

private class SpecTick < Term2::Message
end

private class SpecCounterModel < Term2::Model
  getter count : Int32

  def initialize(@count : Int32 = 0)
  end
end

private class SpecCounterApp < Term2::Application(SpecCounterModel)
  def init : {SpecCounterModel, Term2::Cmd}
    {SpecCounterModel.new, Term2::Cmd.tick(100.milliseconds) { |_| SpecTick.new }}
  end

  def update(msg : Term2::Message, model : SpecCounterModel)
    counter = model

    case msg
    when SpecTick
      {SpecCounterModel.new(counter.count + 1), Term2::Cmd.quit}
    else
      {model, Term2::Cmd.none}
    end
  end

  def view(model : SpecCounterModel) : String
    counter = model
    "Counter: #{counter.count}\n"
  end
end

describe Term2 do
  describe Term2::Cmd do
    it "dispatches batched messages" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      seen = [] of Term2::Message
      done = Channel(Nil).new

      spawn do
        2.times { seen << CML.sync(mailbox.recv_evt) }
        done.send(nil)
      end

      cmd = Term2::Cmd.batch(
        Term2::Cmd.message(SpecTextMessage.new("one")),
        Term2::Cmd.message(SpecTextMessage.new("two"))
      )

      cmd.run(dispatcher)
      done.receive
      seen.map(&.as(SpecTextMessage).value).should eq(["one", "two"])
    end

    it "dispatches messages from events" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      ch = CML::Chan(String).new
      cmd = Term2::Cmd.from_event(CML.wrap(ch.recv_evt) { |msg| SpecTextMessage.new(msg) })

      cmd.run(dispatcher)
      spawn { CML.sync(ch.send_evt("event-msg")) }

      CML.sync(mailbox.recv_evt).as(SpecTextMessage).value.should eq("event-msg")
    end

    it "dispatches delayed messages" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      cmd = Term2::Cmd.after(5.milliseconds, SpecTextMessage.new("delayed"))

      cmd.run(dispatcher)
      result = CML.sync(
        CML.choose(
          mailbox.recv_evt,
          CML.wrap(CML.timeout(200.milliseconds)) { :timeout }
        )
      )

      result.should_not eq(:timeout)
      result.as(SpecTextMessage).value.should eq("delayed")
    end

    it "provides time to tick blocks" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      tick_time : Time? = nil
      cmd = Term2::Cmd.tick(5.milliseconds) do |time|
        tick_time = time
        SpecTextMessage.new("tick")
      end

      cmd.run(dispatcher)
      result = CML.sync(
        CML.choose(
          mailbox.recv_evt,
          CML.wrap(CML.timeout(200.milliseconds)) { :timeout }
        )
      )

      result.should_not eq(:timeout)
      result.as(SpecTextMessage).value.should eq("tick")
      tick_time.should be_a(Time)
    end

    it "dispatches timeout results from work or timer" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)

      fast = Term2::Cmd.timeout(50.milliseconds, SpecTextMessage.new("timeout")) do
        SpecTextMessage.new("fast")
      end

      slow = Term2::Cmd.timeout(5.milliseconds, SpecTextMessage.new("timeout")) do
        CML.sync(CML.timeout(50.milliseconds))
        SpecTextMessage.new("slow")
      end

      fast.run(dispatcher)
      CML.sync(mailbox.recv_evt).as(SpecTextMessage).value.should eq("fast")

      slow.run(dispatcher)
      CML.sync(mailbox.recv_evt).as(SpecTextMessage).value.should eq("timeout")
    end

    it "dispatches messages at deadlines" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      past = Term2::Cmd.deadline(Time.utc - 1.second, SpecTextMessage.new("due"))
      future = Term2::Cmd.deadline(Time.utc + 5.milliseconds) { SpecTextMessage.new("future") }

      past.run(dispatcher)
      future.run(dispatcher)

      first = CML.sync(mailbox.recv_evt).as(SpecTextMessage).value
      second = CML.sync(mailbox.recv_evt).as(SpecTextMessage).value
      first.should eq("due")
      second.should eq("future")
    end

    it "dispatches periodic messages until dispatcher stops" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      cmd = Term2::Cmd.every(5.milliseconds) { SpecTick.new }
      cmd.run(dispatcher)

      2.times do
        result = CML.sync(
          CML.choose(
            mailbox.recv_evt,
            CML.wrap(CML.timeout(200.milliseconds)) { :timeout }
          )
        )
        result.should_not eq(:timeout)
        result.should be_a(SpecTick)
      end

      dispatcher.stop
      while mailbox.poll
      end

      CML.sync(
        CML.choose(
          mailbox.recv_evt,
          CML.wrap(CML.timeout(50.milliseconds)) { :timeout }
        )
      ).should eq(:timeout)
    end

    it "runs commands sequentially" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      order = [] of String

      cmd = Term2::Cmd.sequence(
        Term2::Cmd.message(SpecTextMessage.new("first")),
        Term2::Cmd.message(SpecTextMessage.new("second"))
      )

      cmd.run(dispatcher)
      2.times do
        msg = CML.sync(mailbox.recv_evt).as(SpecTextMessage)
        order << msg.value
      end

      order.should eq(["first", "second"])
    end

    it "maps messages emitted by a command" do
      mailbox = CML::Mailbox(Term2::Message).new
      dispatcher = Term2::Dispatcher.new(mailbox)
      original = Term2::Cmd.message(SpecTextMessage.new("original"))
      cmd = Term2::Cmd.map(original) do |msg|
        text = msg.as(SpecTextMessage).value.upcase
        SpecTextMessage.new(text)
      end

      cmd.run(dispatcher)
      CML.sync(mailbox.recv_evt).as(SpecTextMessage).value.should eq("ORIGINAL")
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
      app = SpecCounterApp.new
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
      program = Term2::Program.new(SpecCounterApp.new, input: nil, output: output, options: options)
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
