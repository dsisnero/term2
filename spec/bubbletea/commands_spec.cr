require "../spec_helper"

class DummyMsg < Term2::Message
  getter value : String

  def initialize(@value : String)
  end

  def ==(other)
    other.is_a?(DummyMsg) && other.value == value
  end
end

describe "Bubbletea parity: commands_test.go" do
  it "every returns expected message" do
    expected = DummyMsg.new("every ms")
    msg = Term2::Cmds.every(1.millisecond) { expected }.not_nil!.call
    msg.should eq(expected)
  end

  it "tick returns expected message" do
    expected = DummyMsg.new("tick")
    msg = Term2::Cmds.tick(1.millisecond) { expected }.not_nil!.call
    msg.should eq(expected)
  end

  it "sequentially returns first non-nil message" do
    err_msg = DummyMsg.new("err")
    str_msg = DummyMsg.new("some msg")
    nil_cmd = Proc(Term2::Msg?).new { nil }
    err_cmd = Proc(Term2::Msg?).new { err_msg }
    str_cmd = Proc(Term2::Msg?).new { str_msg }

    tests = [
      {name: "all nil", cmds: [nil_cmd, nil_cmd], expected: nil},
      {name: "null cmds", cmds: [nil, nil], expected: nil},
      {name: "one error", cmds: [nil_cmd, err_cmd, nil_cmd], expected: err_msg},
      {name: "some msg", cmds: [nil_cmd, str_cmd, nil_cmd], expected: str_msg},
    ]

    tests.each do |t|
      arr = t[:cmds].map(&.as(Term2::Cmd?))
      msg = Term2::Cmds.sequentially(arr).try(&.call)
      msg.should eq(t[:expected])
    end
  end

  it "batch handles nil and multiple commands" do
    Term2::Cmds.batch(nil).should be_nil
    Term2::Cmds.batch.should be_nil

    b = Term2::Cmds.batch(Term2.quit)
    b.should be_a(Term2::Cmd)
    b.try(&.call).should be_a(Term2::QuitMsg)

    cmds = [nil, Term2.quit, nil, Term2.quit, nil, nil].map(&.as(Term2::Cmd?))
    msg = Term2::Cmds.batch(cmds).try(&.call)
    msg.should be_a(Term2::BatchMsg)
    msg.as(Term2::BatchMsg).cmds.size.should eq(2)
  end

  it "sequence handles nil and multiple commands" do
    Term2::Cmds.sequence(nil).should be_nil
    Term2::Cmds.sequence.should be_nil

    b = Term2::Cmds.sequence(Term2.quit)
    b.should be_a(Term2::Cmd)
    b.try(&.call).should be_a(Term2::QuitMsg)

    cmds = [Term2.quit, Term2.quit]
    msg = Term2::Cmds.sequence(cmds).try(&.call)
    msg.should be_a(Term2::SequenceMsg)
    msg.as(Term2::SequenceMsg).cmds.size.should eq(2)
  end
end
