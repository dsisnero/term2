ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/prevent-quit/main"

describe "Example: prevent-quit", tags: "interactive" do
  it "blocks quit when changes unsaved" do
    model = PreventQuitModel.new
    options = Term2::ProgramOptions.new(Term2::WithFilter.new(->(msg : Term2::Msg) { prevent_filter(model, msg) }))
    program = Term2::Program(PreventQuitModel).new(model, input: IO::Memory.new, output: IO::Memory.new, options: options)

    result_ch = Channel(PreventQuitModel).new(1)
    spawn do
      final = program.run
      result_ch.send(final)
    end

    program.send(Term2::TestHelpers.uv_key('a'))
    program.send(Term2::TestHelpers.uv_key("esc"))
    sleep 50.milliseconds # allow quit filter to trigger
    program.send(Term2::TestHelpers.uv_key("y"))

    final_model = result_ch.receive
    final_model.has_changes?.should be_false
  end
end
