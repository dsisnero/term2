ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/chat/main"

describe "Example: chat" do
  it "keeps welcome text after resize" do
    model = ChatModel.new
    model.update(Term2::WindowSizeMsg.new(40, 16))

    view = model.view
    view.should contain("Welcome to the chat room!")
  end

  it "submits messages on enter like the Go example" do
    model = ChatModel.new
    model.update(Term2::WindowSizeMsg.new(40, 16))

    "hello".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }
    model.update(Term2::TestHelpers.uv_key("enter"))

    model.messages.size.should eq(1)
    model.messages.first.should contain("You: ")
    model.messages.first.should contain("hello")
  end
end
