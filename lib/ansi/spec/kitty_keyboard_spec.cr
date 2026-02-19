require "./spec_helper"

describe "Ansi kitty keyboard protocol" do
  describe "constants" do
    it "defines flags" do
      Ansi::KittyDisambiguateEscapeCodes.should eq 1
      Ansi::KittyReportEventTypes.should eq 2
      Ansi::KittyReportAlternateKeys.should eq 4
      Ansi::KittyReportAllKeysAsEscapeCodes.should eq 8
      Ansi::KittyReportAssociatedKeys.should eq 16
      Ansi::KittyAllFlags.should eq 31
    end

    it "defines request and disable sequences" do
      Ansi::RequestKittyKeyboard.should eq "\e[?u"
      Ansi::DisableKittyKeyboard.should eq "\e[>u"
    end
  end

  describe ".kitty_keyboard" do
    it "builds the request sequence" do
      Ansi.kitty_keyboard(3, 2).should eq "\e[=3;2u"
    end
  end

  describe ".push_kitty_keyboard" do
    it "omits zero flags" do
      Ansi.push_kitty_keyboard(0).should eq "\e[>u"
    end

    it "includes flags when provided" do
      Ansi.push_kitty_keyboard(5).should eq "\e[>5u"
    end
  end

  describe ".pop_kitty_keyboard" do
    it "omits zero" do
      Ansi.pop_kitty_keyboard(0).should eq "\e[<u"
    end

    it "includes count when provided" do
      Ansi.pop_kitty_keyboard(2).should eq "\e[<2u"
    end
  end
end
