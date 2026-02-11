ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/isbn-form/main"

describe "Example: isbn-form" do
  it "enables find action when valid isbn and title are entered" do
    model = IsbnFormExample::Model.new

    "9783548372570".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }
    model.update(Term2::TestHelpers.uv_key("down"))
    "A Crystal Book".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }

    model.can_find_book?.should be_true
    model.view.content.should contain("Find ->")
  end

  it "rejects invalid isbn check digit" do
    model = IsbnFormExample::Model.new
    "9783548372571".each_char { |ch| model.update(Term2::TestHelpers.uv_key(ch)) }
    model.isbn_input.err.should_not be_nil
  end
end
