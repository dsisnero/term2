require "./spec_helper"

# Integration tests for Term2 - end-to-end testing of the framework

# Test app that counts messages received
private class MessageCounterModel < Term2::Model
  getter messages : Array(String) = [] of String
  getter? quit_requested : Bool = false

  def initialize(@messages = [] of String, @quit_requested = false)
  end

  def init : Term2::Cmd
    Term2::Cmd.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      key_str = msg.key.to_s
      if key_str == "q" || msg.key.type == Term2::KeyType::CtrlC
        {MessageCounterModel.new(messages + [key_str], quit_requested: true), Term2::Cmd.quit}
      else
        {MessageCounterModel.new(messages + [key_str]), Term2::Cmd.none}
      end
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    "Messages: #{messages.size}\n"
  end
end

# Test app for window resize
private class ResizeModel < Term2::Model
  getter width : Int32 = 0
  getter height : Int32 = 0

  def initialize(@width = 0, @height = 0)
  end

  def init : Term2::Cmd
    Term2::Cmd.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      {ResizeModel.new(msg.width, msg.height), Term2::Cmd.quit}
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    "Size: #{width}x#{height}\n"
  end
end

# Test app for commands
private class CommandTickMsg < Term2::Message
end

private class CommandModel < Term2::Model
  getter tick_count : Int32 = 0

  def initialize(@tick_count = 0)
  end

  def init : Term2::Cmd
    Term2::Cmd.tick(10.milliseconds) { CommandTickMsg.new }
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when CommandTickMsg
      new_count = tick_count + 1
      if new_count >= 3
        {CommandModel.new(new_count), Term2::Cmd.quit}
      else
        {CommandModel.new(new_count), Term2::Cmd.tick(10.milliseconds) { CommandTickMsg.new }}
      end
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    "Ticks: #{tick_count}\n"
  end
end

# Test app for batched commands
private class BatchMsgA < Term2::Message
end

private class BatchMsgB < Term2::Message
end

private class BatchCommandModel < Term2::Model
  getter received : Array(String) = [] of String

  def initialize(@received = [] of String)
  end

  def init : Term2::Cmd
    Term2::Cmd.batch(
      Term2::Cmd.message(BatchMsgA.new),
      Term2::Cmd.message(BatchMsgB.new)
    )
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when BatchMsgA
      new_received = received + ["A"]
      if new_received.size >= 2
        {BatchCommandModel.new(new_received), Term2::Cmd.quit}
      else
        {BatchCommandModel.new(new_received), Term2::Cmd.none}
      end
    when BatchMsgB
      new_received = received + ["B"]
      if new_received.size >= 2
        {BatchCommandModel.new(new_received), Term2::Cmd.quit}
      else
        {BatchCommandModel.new(new_received), Term2::Cmd.none}
      end
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    "Received: #{received.join(", ")}\n"
  end
end

# Test app for message filtering
private class FilteredMsg < Term2::Message
  getter value : String

  def initialize(@value)
  end
end

private class FilterModel < Term2::Model
  getter values : Array(String) = [] of String

  def initialize(@values = [] of String)
  end

  def init : Term2::Cmd
    Term2::Cmd.message(FilteredMsg.new("original"))
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when FilteredMsg
      new_values = values + [msg.value]
      if new_values.size >= 1
        {FilterModel.new(new_values), Term2::Cmd.quit}
      else
        {FilterModel.new(new_values), Term2::Cmd.none}
      end
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    "Values: #{values.join(", ")}\n"
  end
end

describe "Integration Tests" do
  describe "Key Input Processing" do
    it "processes multiple key presses" do
      input = IO::Memory.new
      output = IO::Memory.new

      # Send keys: a, b, c, q (to quit)
      input.print "abcq"
      input.rewind

      app = MessageCounterModel.new
      program = Term2::Program.new(app, input: input, output: output)

      final_model = program.run.as(MessageCounterModel)

      final_model.messages.should eq(["a", "b", "c", "q"])
      final_model.quit_requested?.should be_true
    end

    it "handles control characters" do
      input = IO::Memory.new
      output = IO::Memory.new

      # Send Ctrl+C (0x03)
      input.write Bytes[0x03]
      input.rewind

      app = MessageCounterModel.new
      program = Term2::Program.new(app, input: input, output: output)

      final_model = program.run.as(MessageCounterModel)

      final_model.quit_requested?.should be_true
    end
  end

  describe "Command System" do
    it "executes tick commands" do
      input = IO::Memory.new
      output = IO::Memory.new

      app = CommandModel.new
      program = Term2::Program.new(app, input: input, output: output)

      final_model = program.run.as(CommandModel)

      final_model.tick_count.should eq(3)
    end

    it "executes batched commands" do
      input = IO::Memory.new
      output = IO::Memory.new

      app = BatchCommandModel.new
      program = Term2::Program.new(app, input: input, output: output)

      final_model = program.run.as(BatchCommandModel)

      final_model.received.sort.should eq(["A", "B"])
    end
  end

  describe "Program Options" do
    it "applies alt screen option" do
      input = IO::Memory.new
      output = IO::Memory.new

      # Quick quit
      input.print "q"
      input.rewind

      app = MessageCounterModel.new
      options = Term2::ProgramOptions.new
      options.add(Term2::WithAltScreen.new)
      program = Term2::Program.new(app, input: input, output: output, options: options)

      program.run

      # Check that alt screen escape codes were written
      output.rewind
      output_str = output.gets_to_end
      output_str.should contain("\e[?1049h") # Enter alt screen
    end

    it "disables renderer when requested" do
      input = IO::Memory.new
      output = IO::Memory.new

      input.print "q"
      input.rewind

      app = MessageCounterModel.new
      options = Term2::ProgramOptions.new
      options.add(Term2::WithoutRenderer.new)
      program = Term2::Program.new(app, input: input, output: output, options: options)

      program.run

      # With renderer disabled, output should still work but without rate limiting
      output.rewind
      output_str = output.gets_to_end
      # Should contain view output
      output_str.should contain("Messages:")
    end
  end

  describe "Focus Events" do
    it "handles focus in and out" do
      input = IO::Memory.new
      output = IO::Memory.new

      # FocusIn then FocusOut
      input.print "\e[I\e[O"
      input.rewind

      app = FocusTestModel.new
      program = Term2::Program.new(app, input: input, output: output)
      program.enable_focus_reporting

      final_model = program.run.as(FocusTestModel)

      final_model.focused?.should be_true
      final_model.blurred?.should be_true
    end
  end
end

# Reuse FocusTestApp from focus_spec.cr
private class FocusTestModel < Term2::Model
  getter? focused : Bool = false
  getter? blurred : Bool = false

  def initialize(@focused : Bool = false, @blurred : Bool = false)
  end

  def init : Term2::Cmd
    Term2::Cmd.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::FocusMsg
      {FocusTestModel.new(focused: true, blurred: blurred?), Term2::Cmd.none}
    when Term2::BlurMsg
      {FocusTestModel.new(focused: focused?, blurred: true), Term2::Cmd.quit}
    else
      {self, Term2::Cmd.none}
    end
  end

  def view : String
    ""
  end
end
