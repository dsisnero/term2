require "./spec_helper"

describe Term2::Components::ProgressBar do
  it "initializes with zero progress" do
    bar = Term2::Components::ProgressBar.new(width: 10, complete_char: '#', incomplete_char: '.')
    model, _cmd = bar.init
    bar.view(model).should eq("[..........] 0.0%")
  end

  it "clamps progress and renders percentage" do
    bar = Term2::Components::ProgressBar.new(width: 10, complete_char: '#', incomplete_char: '.')
    model, _ = bar.init
    update_model, _ = bar.update(Term2::Components::ProgressBar::SetPercent.new(0.55), model)
    bar.view(update_model).should eq("[######....] 55.0%")

    full_model, _ = bar.update(Term2::Components::ProgressBar::Increment.new(1.0), update_model)
    bar.view(full_model).should eq("[##########] 100.0%")
  end
end
