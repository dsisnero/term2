require "../spec_helper"

module Term2
  describe Environ do
    describe ".terminal_type" do
      it "returns TERM environment variable" do
        original = ENV["TERM"]?
        begin
          ENV["TERM"] = "xterm-256color"
          Environ.terminal_type.should eq "xterm-256color"
        ensure
          ENV["TERM"] = original
        end
      end

      it "returns 'dumb' when TERM is not set" do
        original = ENV["TERM"]?
        begin
          ENV.delete("TERM")
          Environ.terminal_type.should eq "dumb"
        ensure
          ENV["TERM"] = original
        end
      end
    end

    describe ".color_profile" do
      it "detects truecolor from COLORTERM=truecolor" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV["TERM"] = "xterm"
          ENV["COLORTERM"] = "truecolor"
          Environ.color_profile.should eq Lipgloss::ColorProfile::TrueColor
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end

      it "detects truecolor from COLORTERM=24bit" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV["TERM"] = "xterm"
          ENV["COLORTERM"] = "24bit"
          Environ.color_profile.should eq Lipgloss::ColorProfile::TrueColor
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end

      it "detects ANSI256 from TERM containing 256color" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV.delete("COLORTERM")
          ENV["TERM"] = "xterm-256color"
          Environ.color_profile.should eq Lipgloss::ColorProfile::ANSI256
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end

      it "detects ANSI from TERM containing color" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV.delete("COLORTERM")
          ENV["TERM"] = "xterm-color"
          Environ.color_profile.should eq Lipgloss::ColorProfile::ANSI
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end

      it "detects ANSI from TERM containing ansi" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV.delete("COLORTERM")
          ENV["TERM"] = "ansi"
          Environ.color_profile.should eq Lipgloss::ColorProfile::ANSI
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end

      it "defaults to ANSI when no color hints" do
        original_term = ENV["TERM"]?
        original_colorterm = ENV["COLORTERM"]?
        begin
          ENV.delete("COLORTERM")
          ENV["TERM"] = "vt100"
          Environ.color_profile.should eq Lipgloss::ColorProfile::ANSI
        ensure
          ENV["TERM"] = original_term
          ENV["COLORTERM"] = original_colorterm
        end
      end
    end

    describe ".platform" do
      it "returns a symbol" do
        Environ.platform.should be_a Symbol
      end

      # Platform detection is compile-time, so we can't test dynamically.
      # But we can at least ensure it returns one of the expected values.
      it "returns one of :darwin, :linux, :windows, :wsl, :unknown" do
        allowed = {:darwin, :linux, :windows, :wsl, :unknown}
        allowed.should contain(Environ.platform)
      end
    end

    describe ".keyboard_enhancements?" do
      it "returns true for known enhanced terminals" do
        original = ENV["TERM"]?
        begin
          %w[kitty wezterm iterm2 foot contour mintty].each do |term|
            ENV["TERM"] = term
            Environ.keyboard_enhancements?.should be_true
          end
        ensure
          ENV["TERM"] = original
        end
      end

      it "returns false for dumb terminals" do
        original = ENV["TERM"]?
        begin
          ENV["TERM"] = "dumb"
          Environ.keyboard_enhancements?.should be_false
        ensure
          ENV["TERM"] = original
        end
      end

      it "returns false for xterm" do
        original = ENV["TERM"]?
        begin
          ENV["TERM"] = "xterm"
          Environ.keyboard_enhancements?.should be_false
        ensure
          ENV["TERM"] = original
        end
      end
    end

    describe ".dumb?" do
      it "returns true when TERM=dumb" do
        original = ENV["TERM"]?
        begin
          ENV["TERM"] = "dumb"
          Environ.dumb?.should be_true
        ensure
          ENV["TERM"] = original
        end
      end

      it "returns false when TERM is not dumb" do
        original = ENV["TERM"]?
        begin
          ENV["TERM"] = "xterm"
          Environ.dumb?.should be_false
        ensure
          ENV["TERM"] = original
        end
      end
    end

    describe ".capabilities" do
      it "returns a hash with expected keys" do
        caps = Environ.capabilities
        caps.should be_a Hash(String, Bool | String | Symbol)
        %w[terminal_type color_profile platform truecolor ansi256 ansi dumb keyboard_enhancements mouse].each do |key|
          caps.has_key?(key).should be_true
        end
      end
    end
  end
end
