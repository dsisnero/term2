require "../spec_helper"
require "../../src/components/spinner"

describe Term2::Components::Spinner do
  it "defaults to LINE spinner" do
    spinner = Term2::Components::Spinner.new
    spinner.type.should eq Term2::Components::Spinner::LINE
  end

  it "accepts custom spinner type" do
    custom = Term2::Components::Spinner::Type.new(%w(a b c d), 160.milliseconds)
    spinner = Term2::Components::Spinner.new(custom)
    spinner.type.should eq custom
  end

  it "exposes predefined spinners" do
    tests = {
      "LINE"     => Term2::Components::Spinner::LINE,
      "DOT"      => Term2::Components::Spinner::DOT,
      "MINI_DOT" => Term2::Components::Spinner::MINI_DOT,
      "JUMP"     => Term2::Components::Spinner::JUMP,
      "PULSE"    => Term2::Components::Spinner::PULSE,
      "POINTS"   => Term2::Components::Spinner::POINTS,
      "GLOBE"    => Term2::Components::Spinner::GLOBE,
      "MOON"     => Term2::Components::Spinner::MOON,
      "MONKEY"   => Term2::Components::Spinner::MONKEY,
    }

    tests.each do |_, spin_type|
      spinner = Term2::Components::Spinner.new(spin_type)
      spinner.type.should eq spin_type
      spinner.type.frames.size.should eq spin_type.frames.size
      spinner.type.fps.should eq spin_type.fps
    end
  end
end
