require "./spec_helper"

describe Term2::Components::Progress do
  it "initializes with zero progress" do
    bar = Term2::Components::Progress.new(width: 10)
    bar.full_char = '#'
    bar.empty_char = '.'

    # Width 10 includes percentage " 0%" (3 chars)
    # So bar width is 7.
    bar.view.should contain(".......")
    bar.view.should contain("0%")
  end

  it "clamps progress and renders percentage" do
    bar = Term2::Components::Progress.new(width: 10)
    bar.full_char = '#'
    bar.empty_char = '.'

    msg = Term2::Components::Progress::SetPercentMsg.new(0.55)
    bar.update(msg)

    # Width 10 includes " 55%" (4 chars)
    # Bar width is 6.
    # 55% of 6 is 3.3 -> 3.
    # So 3 filled, 3 empty.

    bar.view.should contain("###")
    bar.view.should contain("...")
    bar.view.should contain("55%")

    msg_inc = Term2::Components::Progress::IncrementMsg.new(1.0)
    bar.update(msg_inc)

    # Width 10 includes " 100%" (5 chars)
    # Bar width is 5.
    # 100% of 5 is 5.

    bar.view.should contain("#####")
    bar.view.should contain("100%")
  end
end
