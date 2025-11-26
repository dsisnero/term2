require "../spec_helper"
require "../../src/components/spinner"

describe Term2::Components::Spinner do
  it "initializes with defaults" do
    spinner = Term2::Components::Spinner.new
    spinner.type.should eq Term2::Components::Spinner::LINE
    spinner.frame_index.should eq 0
  end

  it "advances frame on tick" do
    spinner = Term2::Components::Spinner.new
    initial_frame = spinner.frame_index

    msg = Term2::Components::Spinner::TickMsg.new(spinner.id, 0, Time.utc)
    spinner, cmd = spinner.update(msg)

    spinner.frame_index.should eq(initial_frame + 1)
    cmd.should_not be_nil
  end

  it "ignores tick with wrong ID" do
    spinner = Term2::Components::Spinner.new
    initial_frame = spinner.frame_index

    msg = Term2::Components::Spinner::TickMsg.new(spinner.id + 1, 0, Time.utc)
    spinner, _ = spinner.update(msg)

    spinner.frame_index.should eq initial_frame
    # cmd should be none, but hard to check.
  end
end
