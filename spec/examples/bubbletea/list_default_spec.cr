ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../../spec_helper"
require "../../../examples/bubbletea/list-default/main"

describe "Example: list-default", tags: "interactive" do
  it "renders list title and quits" do
    tm = Term2::Teatest::TestModel(ListDefaultModel).new(
      ListDefaultModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    tm.send(Term2::KeyMsg.new(Term2::Key.new("ctrl+c")))

    output = tm.final_output
    output.should contain("My Fave Things")
  end

  it "filters with fuzzy match and shows scores in debug mode" do
    previous = ENV["TERM2_DEBUG"]?
    ENV["TERM2_DEBUG"] = "1"

    begin
      tm = Term2::Teatest::TestModel(ListDefaultModel).new(
        ListDefaultModel.new,
        Term2::Teatest.with_initial_term_size(80, 20),
      )
      tm.send(Term2::WindowSizeMsg.new(80, 20))
      tm.send(Term2::KeyMsg.new(Term2::Key.new("/")))
      tm.type("pi")
      tm.send(Term2::KeyMsg.new(Term2::Key.new("enter")))
      tm.send(Term2::KeyMsg.new(Term2::Key.new("ctrl+c")))

      output = Term2::Text.strip_ansi(tm.final_output)
      output.should contain("Raspberry Pi")
      output.should contain("score=")
    ensure
      if previous
        ENV["TERM2_DEBUG"] = previous
      else
        ENV.delete("TERM2_DEBUG")
      end
    end
  end
end
