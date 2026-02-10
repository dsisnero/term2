ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/chat/main"

# Basic interaction coverage for the chat example using teatest.
describe "Bubbletea example: chat" do
  it "accepts input and appends message (direct model update to verify spaces)" do
    model = ChatModel.new
    # Simulate init commands
    model.init

    "hello there".each_char do |ch|
      model, _ = model.update(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key(ch)))
    end
    model, _ = model.update(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key("enter")))

    model.messages.join(" ").should contain("hello there")
  end
end
