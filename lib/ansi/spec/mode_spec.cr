require "./spec_helper"

describe "Ansi modes" do
  describe Ansi::ModeSetting do
    it "reports correct mode setting properties" do
      cases = [
        {Ansi::ModeNotRecognized, true, false, false, false, false},
        {Ansi::ModeSet, false, true, false, false, false},
        {Ansi::ModeReset, false, false, true, false, false},
        {Ansi::ModePermanentlySet, false, true, false, true, false},
        {Ansi::ModePermanentlyReset, false, false, true, false, true},
      ]

      cases.each do |mode, not_recog, is_set, is_reset, perm_set, perm_reset|
        mode.is_not_recognized.should eq not_recog
        mode.is_set.should eq is_set
        mode.is_reset.should eq is_reset
        mode.is_permanently_set.should eq perm_set
        mode.is_permanently_reset.should eq perm_reset
      end
    end
  end

  describe ".set_mode" do
    it "builds mode sequences" do
      Ansi.set_mode.should eq ""
      Ansi.set_mode(Ansi::ModeKeyboardAction).should eq "\e[2h"
      Ansi.set_mode(Ansi::ModeCursorKeys).should eq "\e[?1h"
      Ansi.set_mode(Ansi::ModeKeyboardAction, Ansi::ModeInsertReplace).should eq "\e[2;4h"
      Ansi.set_mode(Ansi::ModeCursorKeys, Ansi::ModeAutoWrap).should eq "\e[?1;7h"
      Ansi.set_mode(Ansi::ModeKeyboardAction, Ansi::ModeCursorKeys).should eq "\e[2h\e[?1h"
      Ansi.set_mode(Ansi::ModeKeyboardAction, Ansi::ModeInsertReplace, Ansi::ModeCursorKeys, Ansi::ModeAutoWrap).should eq "\e[2;4h\e[?1;7h"
    end
  end

  describe ".reset_mode" do
    it "builds mode reset sequences" do
      Ansi.reset_mode.should eq ""
      Ansi.reset_mode(Ansi::ModeKeyboardAction).should eq "\e[2l"
      Ansi.reset_mode(Ansi::ModeCursorKeys).should eq "\e[?1l"
      Ansi.reset_mode(Ansi::ModeKeyboardAction, Ansi::ModeInsertReplace).should eq "\e[2;4l"
      Ansi.reset_mode(Ansi::ModeCursorKeys, Ansi::ModeAutoWrap).should eq "\e[?1;7l"
      Ansi.reset_mode(Ansi::ModeKeyboardAction, Ansi::ModeCursorKeys).should eq "\e[2l\e[?1l"
      Ansi.reset_mode(Ansi::ModeKeyboardAction, Ansi::ModeInsertReplace, Ansi::ModeCursorKeys, Ansi::ModeAutoWrap).should eq "\e[2;4l\e[?1;7l"
    end
  end

  describe ".request_mode" do
    it "builds mode request sequences" do
      Ansi.request_mode(Ansi::ModeKeyboardAction).should eq "\e[2$p"
      Ansi.request_mode(Ansi::ModeCursorKeys).should eq "\e[?1$p"
    end
  end

  describe ".report_mode" do
    it "builds mode report sequences" do
      Ansi.report_mode(Ansi::ModeKeyboardAction, Ansi::ModeNotRecognized).should eq "\e[2;0$y"
      Ansi.report_mode(Ansi::ModeCursorKeys, Ansi::ModeSet).should eq "\e[?1;1$y"
      Ansi.report_mode(Ansi::ModeInsertReplace, Ansi::ModeReset).should eq "\e[4;2$y"
      Ansi.report_mode(Ansi::ModeAutoWrap, Ansi::ModePermanentlySet).should eq "\e[?7;3$y"
      Ansi.report_mode(Ansi::ModeSendReceive, Ansi::ModePermanentlyReset).should eq "\e[12;4$y"
      Ansi.report_mode(Ansi::ModeKeyboardAction, 5).should eq "\e[2;0$y"
    end
  end

  describe "mode implementations" do
    it "returns mode values" do
      Ansi::ANSIMode.new(42).mode.should eq 42
      Ansi::DECMode.new(99).mode.should eq 99
    end
  end
end
