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
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Enter)))

    model.messages.join(" ").should contain("hello there")
  end
end
