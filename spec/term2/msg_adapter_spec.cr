require "../spec_helper"

describe Term2::MsgAdapter do
  it "wraps a single event" do
    key = Term2::UV::Key.new("a")
    messages = Term2::MsgAdapter.to_messages(key)
    messages.size.should eq(1)
    messages.first.should eq(key)
  end

  it "flattens arrays of events" do
    key = Term2::UV::Key.new("a")
    win = Term2::UV::WindowSizeEvent.new(80, 24)
    event = [key, win] of Term2::UV::EventSingle

    messages = Term2::MsgAdapter.to_messages(event)
    messages.size.should eq(2)
    messages[0].should eq(key)
    messages[1].should eq(win)
  end

  it "does not flatten array payload events" do
    payload = [1, 2, 3] of Int32

    messages = Term2::MsgAdapter.to_messages(payload)
    messages.size.should eq(1)
    messages.first.should eq(payload)
  end
end
