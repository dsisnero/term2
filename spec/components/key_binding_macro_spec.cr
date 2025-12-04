require "../spec_helper"
require "../../src/components/key"

class MacroKeymap
  Term2::Components::Key.key_bindings(
    start: {["s"], "s", "start"},
    stop:  {["t"], "t", "stop"},
  )
end

describe Term2::Components::Key do
  it "builds bindings and getters via key_bindings macro" do
    km = MacroKeymap.new
    km.start.help_desc.should eq "start"
    km.stop.help_key.should eq "t"
    km.bindings.size.should eq 2
    km.start.matches?(Term2::KeyMsg.new(Term2::Key.new("s"))).should be_true
  end
end
