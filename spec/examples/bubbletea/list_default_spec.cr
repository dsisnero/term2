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

    tm.send(Term2::TestHelpers.uv_key("ctrl+c"))

    output = tm.final_output
    output.should contain("My Fave Things")
  end

  it "filters with fuzzy match and shows scores in debug mode" do
    previous = ENV["TERM2_DEBUG"]?
    orig_stderr = STDERR.dup
    stderr_read, stderr_write = IO.pipe
    drain = spawn do
      begin
        stderr_read.each_line { }
      rescue
      end
    end
    STDERR.reopen(stderr_write)
    STDERR.sync = true
    ENV["TERM2_DEBUG"] = "1"

    begin
      tm = Term2::Teatest::TestModel(ListDefaultModel).new(
        ListDefaultModel.new,
        Term2::Teatest.with_initial_term_size(80, 20),
      )
      tm.send(Term2::WindowSizeMsg.new(80, 20))
      tm.send(Term2::TestHelpers.uv_key("/"))
      tm.type("pi")
      tm.send(Term2::TestHelpers.uv_key("enter"))
      tm.send(Term2::TestHelpers.uv_key("ctrl+c"))

      output = Lipgloss::Text.strip_ansi(tm.final_output)
      output.should contain("Raspberry Pi")
      output.should contain("score=")
    ensure
      STDERR.reopen(orig_stderr)
      stderr_write.close rescue nil
      stderr_read.close rescue nil
      if previous
        ENV["TERM2_DEBUG"] = previous
      else
        ENV.delete("TERM2_DEBUG")
      end
    end
  end
end
