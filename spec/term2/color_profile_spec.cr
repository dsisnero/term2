require "../spec_helper"

module Term2
  describe ColorProfile do
    describe ".detect_background_color_from_env" do
      it "returns nil when COLORFGBG is not set" do
        original = ENV["COLORFGBG"]?
        begin
          ENV.delete("COLORFGBG")
          ColorProfile.detect_background_color_from_env.should be_nil
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end

      it "returns indexed color when COLORFGBG contains background index" do
        original = ENV["COLORFGBG"]?
        begin
          ENV["COLORFGBG"] = "15;0"
          color = ColorProfile.detect_background_color_from_env.not_nil!
          color.should be_a(Lipgloss::Color)
          # Background is second value "0" which is black (indexed color)
          color.type.should eq(Lipgloss::Color::Type::Indexed)
          color.value.should eq(0)
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end

      it "handles COLORFGBG with extra semicolons" do
        original = ENV["COLORFGBG"]?
        begin
          ENV["COLORFGBG"] = "15;0;something"
          color = ColorProfile.detect_background_color_from_env.not_nil!
          color.should be_a(Lipgloss::Color)
          color.type.should eq(Lipgloss::Color::Type::Indexed)
          color.value.should eq(0)
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end

      it "returns nil when background is not a number" do
        original = ENV["COLORFGBG"]?
        begin
          ENV["COLORFGBG"] = "15;invalid"
          ColorProfile.detect_background_color_from_env.should be_nil
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end
    end

    describe ".dark_background_from_env?" do
      it "returns nil when COLORFGBG not set" do
        original = ENV["COLORFGBG"]?
        begin
          ENV.delete("COLORFGBG")
          ColorProfile.dark_background_from_env?.should be_nil
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end

      it "returns true for dark background colors" do
        original = ENV["COLORFGBG"]?
        begin
          # Black background (index 0) is dark
          ENV["COLORFGBG"] = "15;0"
          ColorProfile.dark_background_from_env?.should be_true
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end

      it "returns false for light background colors" do
        original = ENV["COLORFGBG"]?
        begin
          # White background (index 15) is light
          ENV["COLORFGBG"] = "0;15"
          ColorProfile.dark_background_from_env?.should be_false
        ensure
          ENV["COLORFGBG"] = original if original
        end
      end
    end

    describe ".rgb_to_hsl" do
      it "converts black to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(0, 0, 0)
        h.should eq(0.0)
        s.should eq(0.0)
        l.should eq(0.0)
      end

      it "converts white to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(255, 255, 255)
        h.should eq(0.0)
        s.should eq(0.0)
        l.should eq(1.0)
      end

      it "converts red to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(255, 0, 0)
        h.should eq(0.0)
        s.should eq(1.0)
        l.should eq(0.5)
      end

      it "converts green to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(0, 255, 0)
        h.should eq(120.0)
        s.should eq(1.0)
        l.should eq(0.5)
      end

      it "converts blue to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(0, 0, 255)
        h.should eq(240.0)
        s.should eq(1.0)
        l.should eq(0.5)
      end

      it "converts gray to HSL" do
        h, s, l = ColorProfile.rgb_to_hsl(128, 128, 128)
        h.should eq(0.0)
        s.should eq(0.0)
        l.should be_close(0.5, 0.01)
      end
    end

    describe ".hsl_to_rgb" do
      it "converts HSL black to RGB" do
        r, g, b = ColorProfile.hsl_to_rgb(0.0, 0.0, 0.0)
        r.should eq(0)
        g.should eq(0)
        b.should eq(0)
      end

      it "converts HSL white to RGB" do
        r, g, b = ColorProfile.hsl_to_rgb(0.0, 0.0, 1.0)
        r.should eq(255)
        g.should eq(255)
        b.should eq(255)
      end

      it "converts HSL red to RGB" do
        r, g, b = ColorProfile.hsl_to_rgb(0.0, 1.0, 0.5)
        r.should eq(255)
        g.should eq(0)
        b.should eq(0)
      end

      it "converts HSL green to RGB" do
        r, g, b = ColorProfile.hsl_to_rgb(120.0, 1.0, 0.5)
        r.should eq(0)
        g.should eq(255)
        b.should eq(0)
      end

      it "converts HSL blue to RGB" do
        r, g, b = ColorProfile.hsl_to_rgb(240.0, 1.0, 0.5)
        r.should eq(0)
        g.should eq(0)
        b.should eq(255)
      end

      it "round-trip conversion" do
        original_r, original_g, original_b = 123, 45, 67
        h, s, l = ColorProfile.rgb_to_hsl(original_r, original_g, original_b)
        r, g, b = ColorProfile.hsl_to_rgb(h, s, l)
        r.should eq(original_r)
        g.should eq(original_g)
        b.should eq(original_b)
      end
    end

    describe ".rgb_to_hsv" do
      it "converts black to HSV" do
        h, s, v = ColorProfile.rgb_to_hsv(0, 0, 0)
        h.should eq(0.0)
        s.should eq(0.0)
        v.should eq(0.0)
      end

      it "converts white to HSV" do
        h, s, v = ColorProfile.rgb_to_hsv(255, 255, 255)
        h.should eq(0.0)
        s.should eq(0.0)
        v.should eq(1.0)
      end

      it "converts red to HSV" do
        h, s, v = ColorProfile.rgb_to_hsv(255, 0, 0)
        h.should eq(0.0)
        s.should eq(1.0)
        v.should eq(1.0)
      end

      it "converts green to HSV" do
        h, s, v = ColorProfile.rgb_to_hsv(0, 255, 0)
        h.should eq(120.0)
        s.should eq(1.0)
        v.should eq(1.0)
      end

      it "converts blue to HSV" do
        h, s, v = ColorProfile.rgb_to_hsv(0, 0, 255)
        h.should eq(240.0)
        s.should eq(1.0)
        v.should eq(1.0)
      end
    end

    describe ".hsv_to_rgb" do
      it "converts HSV black to RGB" do
        r, g, b = ColorProfile.hsv_to_rgb(0.0, 0.0, 0.0)
        r.should eq(0)
        g.should eq(0)
        b.should eq(0)
      end

      it "converts HSV white to RGB" do
        r, g, b = ColorProfile.hsv_to_rgb(0.0, 0.0, 1.0)
        r.should eq(255)
        g.should eq(255)
        b.should eq(255)
      end

      it "round-trip conversion" do
        original_r, original_g, original_b = 200, 100, 50
        h, s, v = ColorProfile.rgb_to_hsv(original_r, original_g, original_b)
        r, g, b = ColorProfile.hsv_to_rgb(h, s, v)
        r.should eq(original_r)
        g.should eq(original_g)
        b.should eq(original_b)
      end
    end

    describe ".rgb_to_cmyk" do
      it "converts black to CMYK" do
        c, m, y, k = ColorProfile.rgb_to_cmyk(0, 0, 0)
        c.should eq(0.0)
        m.should eq(0.0)
        y.should eq(0.0)
        k.should eq(1.0)
      end

      it "converts white to CMYK" do
        c, m, y, k = ColorProfile.rgb_to_cmyk(255, 255, 255)
        c.should eq(0.0)
        m.should eq(0.0)
        y.should eq(0.0)
        k.should eq(0.0)
      end

      it "converts red to CMYK" do
        c, m, y, k = ColorProfile.rgb_to_cmyk(255, 0, 0)
        c.should eq(0.0)
        m.should eq(1.0)
        y.should eq(1.0)
        k.should eq(0.0)
      end

      it "converts green to CMYK" do
        c, m, y, k = ColorProfile.rgb_to_cmyk(0, 255, 0)
        c.should eq(1.0)
        m.should eq(0.0)
        y.should eq(1.0)
        k.should eq(0.0)
      end

      it "converts blue to CMYK" do
        c, m, y, k = ColorProfile.rgb_to_cmyk(0, 0, 255)
        c.should eq(1.0)
        m.should eq(1.0)
        y.should eq(0.0)
        k.should eq(0.0)
      end
    end

    describe ".cmyk_to_rgb" do
      it "converts CMYK black to RGB" do
        r, g, b = ColorProfile.cmyk_to_rgb(0.0, 0.0, 0.0, 1.0)
        r.should eq(0)
        g.should eq(0)
        b.should eq(0)
      end

      it "converts CMYK white to RGB" do
        r, g, b = ColorProfile.cmyk_to_rgb(0.0, 0.0, 0.0, 0.0)
        r.should eq(255)
        g.should eq(255)
        b.should eq(255)
      end

      it "round-trip conversion from RGB to CMYK to RGB" do
        original_r, original_g, original_b = 123, 45, 67
        c, m, y, k = ColorProfile.rgb_to_cmyk(original_r, original_g, original_b)
        r, g, b = ColorProfile.cmyk_to_rgb(c, m, y, k)
        # Allow small differences due to floating point rounding
        r.should be_close(original_r, 1)
        g.should be_close(original_g, 1)
        b.should be_close(original_b, 1)
      end
    end
  end
end
