ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/package-manager/main"

describe "Example: package-manager" do
  it "installs all packages" do
    tm = Term2::Teatest::TestModel(PackageManagerModel).new(
      PackageManagerModel.new,
      Term2::Teatest.with_initial_term_size(80, 20),
    )
    tm.send(Term2::WindowSizeMsg.new(80, 20))

    model = tm.final_model(
      Term2::Teatest.with_final_timeout(3.seconds),
      Term2::Teatest.with_timeout_fn { tm.quit },
    )
    model.done?.should be_true
    model.index.should eq(model.packages.size - 1)
  end
end
