require "./spec_helper"

describe Charmtone do
  describe ".keys" do
    it "returns canonical palette keys" do
      keys = Charmtone.keys
      keys.first.should eq(Charmtone::Key::Cumin)
      keys.last.should eq(Charmtone::Key::Butter)
      keys.should_not contain(Charmtone::Key::Pickle)
      keys.should_not contain(Charmtone::Key::Pom)
      keys.should_not contain(Charmtone::Key::NeueGuac)
    end
  end

  it "emits valid hex values for all canonical keys" do
    Charmtone.keys.each do |key|
      hex = key.hex.lchop('#')
      (hex.size == 6 || hex.size == 3).should be_true
      hex.to_i64(16).should be >= 0_i64
    end
  end

  it "supports palette classification helpers" do
    Charmtone::Key::Charple.is_primary?.should be_true
    Charmtone::Key::Blush.is_secondary?.should be_true
    Charmtone::Key::Malibu.is_tertiary?.should be_true
    Charmtone::Key::Pepper.is_primary?.should be_false
  end

  it "returns custom names including aliases" do
    Charmtone::Key::Mochi.to_s.should eq("Crystal")
    Charmtone::Key::NeueGuac.to_s.should eq("Neue Guac")
  end

  it "returns 16-bit RGBA values" do
    r, g, b, a = Charmtone::Key::Charple.rgba
    r.should eq(0x6B6B_u32)
    g.should eq(0x5050_u32)
    b.should eq(0xFFFF_u32)
    a.should eq(0xFFFF_u32)
  end
end
