ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"

private class RenderOnceModel
  include Term2::Model

  getter count : Int32 = 0

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      @count += 1
      {self, Term2::Cmds.none}
    when Term2::QuitMsg
      {self, Term2::Cmds.none}
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
    "count=#{@count}"
  end
end

describe "Program rendering" do
  it "renders after a single input event without waiting for another" do
    tm = Term2::Teatest::TestModel(RenderOnceModel).new(
      RenderOnceModel.new,
      Term2::Teatest.with_initial_term_size(20, 5),
    )

    tm.send(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key('a')))

    Term2::Teatest.wait_for(tm.output_reader, Term2::Teatest.with_duration(500.milliseconds)) do |text|
      text.includes?("count=1")
    end

    tm.quit
  end
end
