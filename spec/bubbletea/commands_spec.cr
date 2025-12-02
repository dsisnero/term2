require "../spec_helper"

private class CmdTestMsg < Term2::Message
  getter value : String

  def initialize(@value : String); end
end

describe "BubbleTea parity: commands" do
  it "Every returns message" do
    msg = Term2::Cmds.every(1.millisecond) { |_| CmdTestMsg.new("every ms") }.not_nil!.call
    msg.as(CmdTestMsg).value.should eq("every ms")
  end

  it "Tick returns message" do
    msg = Term2::Cmds.tick(1.millisecond) { |_| CmdTestMsg.new("tick") }.not_nil!.call
    msg.as(CmdTestMsg).value.should eq("tick")
  end

  it "Sequentially returns first non-nil message" do
    err_msg = CmdTestMsg.new("some err")
    str_msg = CmdTestMsg.new("some msg")
    nil_cmd = -> : Term2::Msg? { nil }

    tests = [
      {name: "all nil", cmds: [nil_cmd, nil_cmd], expected: nil},
      {name: "null cmds", cmds: [nil, nil], expected: nil},
      {name: "one error", cmds: [nil_cmd, -> { err_msg.as(Term2::Msg) }, nil_cmd], expected: err_msg},
      {name: "some msg", cmds: [nil_cmd, -> { str_msg.as(Term2::Msg) }, nil_cmd], expected: str_msg},
    ]

    tests.each do |test|
      cmds = test[:cmds].compact_map { |c| c.as(Term2::Cmd) }
      cmd = Term2::Cmds.sequentially(cmds)
      msg = cmd ? cmd.call : nil
      msg.should eq(test[:expected])
    end
  end

  it "Batch handles nil/empty/single/mixed" do
    Term2::Cmds.batch(nil).should be_nil
    Term2::Cmds.batch.should be_nil
    single = Term2::Cmds.batch(Term2::Cmds.quit)
    single.not_nil!.call.should be_a(Term2::QuitMsg)

    mixed = Term2::Cmds.batch(nil, Term2::Cmds.quit, nil, Term2::Cmds.quit, nil)
    msgs = mixed.not_nil!.call.as(Term2::BatchMsg)
    msgs.cmds.size.should eq(2)
  end

  it "Sequence handles nil/empty/single/mixed" do
    Term2::Cmds.sequence(nil).should be_nil
    Term2::Cmds.sequence.should be_nil
    single = Term2::Cmds.sequence(Term2::Cmds.quit)
    single.not_nil!.call.should be_a(Term2::QuitMsg)

    mixed = Term2::Cmds.sequence(nil, Term2::Cmds.quit, nil, Term2::Cmds.quit, nil)
    seq_msg = mixed.not_nil!.call.as(Term2::SequenceMsg)
    seq_msg.cmds.size.should eq(2)
  end
end