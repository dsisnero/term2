require "../spec_helper"

# A dummy message for testing equality
class DummyMsg < Term2::Message
  getter value : String

  def initialize(@value : String)
  end

  def ==(other)
    other.is_a?(DummyMsg) && other.value == value
  end

  def to_s(io)
    io << "DummyMsg(#{@value})"
  end
end

describe "Term2::Cmds" do
  describe "Timer commands" do
    it "every returns expected message after delay" do
      expected = DummyMsg.new("every ms")

      # 'every' blocks using CML.sync, so we must run it in a fiber
      # to prevent blocking the test runner
      result_ch = Channel(Term2::Msg?).new

      cmd = Term2::Cmds.every(1.millisecond) { |_| expected }

      spawn do
        if c = cmd
          result_ch.send(c.call)
        end
      end

      select
      when msg = result_ch.receive
        msg.should_not be_nil
        msg.not_nil!.should eq(expected)
      when timeout(100.milliseconds)
        fail "Timed out waiting for 'every' command"
      end
    end

    it "tick returns expected message after delay" do
      expected = DummyMsg.new("tick")
      result_ch = Channel(Term2::Msg?).new

      cmd = Term2::Cmds.tick(1.millisecond) { |_| expected }

      spawn do
        if c = cmd
          result_ch.send(c.call)
        end
      end

      select
      when msg = result_ch.receive
        msg.should_not be_nil
        msg.not_nil!.should eq(expected)
      when timeout(100.milliseconds)
        fail "Timed out waiting for 'tick' command"
      end
    end
  end

  describe "Batch" do
    it "returns nil for empty or nil inputs" do
      Term2::Cmds.batch(nil).should be_nil
      Term2::Cmds.batch([] of Term2::Cmd).should be_nil
    end

    it "optimizes single command by returning it directly" do
      # If batch receives only 1 valid command, it should return that command
      # instead of wrapping it in a BatchMsg
      cmd = Term2.quit
      batch_cmd = Term2::Cmds.batch(cmd)

      # The resulting command should produce QuitMsg directly, not BatchMsg
      msg = batch_cmd.not_nil!.call
      msg.should_not be_nil
      msg.not_nil!.should be_a(Term2::QuitMsg)
    end

    it "wraps multiple commands in a BatchMsg" do
      cmd1 = Term2.quit
      cmd2 = Term2::Cmds.message(DummyMsg.new("hello"))

      # Mixed with nils
      cmds = [nil, cmd1, nil, cmd2, nil].map(&.as(Term2::Cmd))

      batch_cmd = Term2::Cmds.batch(cmds)
      batch_cmd.should_not be_nil

      msg = batch_cmd.not_nil!.call
      msg.should_not be_nil
      msg.not_nil!.should be_a(Term2::BatchMsg)

      batch_msg = msg.not_nil!.as(Term2::BatchMsg)
      batch_msg.cmds.size.should eq(2)
    end
  end

  describe "Sequence" do
    it "returns nil for empty or nil inputs" do
      Term2::Cmds.sequence(nil).should be_nil
      Term2::Cmds.sequence([] of Term2::Cmd).should be_nil
    end

    it "optimizes single command by returning it directly" do
      cmd = Term2.quit
      seq_cmd = Term2::Cmds.sequence(cmd)

      msg = seq_cmd.not_nil!.call
      msg.should_not be_nil
      msg.not_nil!.should be_a(Term2::QuitMsg)
    end

    it "wraps multiple commands in a SequenceMsg" do
      # Setup commands
      msg1 = DummyMsg.new("1")
      msg2 = DummyMsg.new("2")

      cmd1 = Term2::Cmds.message(msg1)
      cmd2 = Term2::Cmds.message(msg2)

      # Pass them to sequence
      seq_cmd = Term2::Cmds.sequence([cmd1, cmd2].map(&.as(Term2::Cmd)))
      seq_cmd.should_not be_nil

      # Execute the command wrapper to get the Message
      result_msg = seq_cmd.not_nil!.call

      # It should be a SequenceMsg
      result_msg.should be_a(Term2::SequenceMsg)

      # It should contain the commands to produce the messages
      seq_msg = result_msg.as(Term2::SequenceMsg)
      seq_msg.cmds.size.should eq(2)

      # Verify the internal commands produce the expected messages
      seq_msg.cmds[0].call.should eq(msg1)
      seq_msg.cmds[1].call.should eq(msg2)
    end
  end
end
