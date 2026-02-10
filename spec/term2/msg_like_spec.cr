require "../spec_helper"

def accepts_msg(msg : Term2::Msg) : Term2::Msg
  msg
end

struct CustomMsg
  include Term2::MsgLike

  getter value : Int32

  def initialize(@value : Int32)
  end
end

describe Term2::MsgLike do
  it "accepts custom structs that include MsgLike" do
    msg = CustomMsg.new(1)
    accepts_msg(msg).should be_a(CustomMsg)
  end
end
