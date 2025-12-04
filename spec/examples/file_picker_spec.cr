ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/file-picker/main"

describe "Example: file-picker" do
  it "selects a file and handles invalid selection" do
    tm = Term2::Teatest::TestModel(FilePickerModel).new(FilePickerModel.new, Term2::Teatest.with_initial_term_size(80, 24))
    tm.send(Term2::WindowSizeMsg.new(80, 24))
    tm.quit
    tm.final_output.should contain("Pick a file")
  end
end
