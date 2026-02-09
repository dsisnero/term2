require "./base_types"
require "lipgloss"

module Term2
  # Environ provides terminal environment detection capabilities.
  #
  # This module detects terminal type, color profile, platform, and feature
  # capabilities based on environment variables, terminal queries, and platform
  # inspection.
  module Environ
    extend self

    private class_property color_profile_override : Lipgloss::ColorProfile? = nil

    # Returns the terminal type string (e.g., "xterm-256color", "kitty", "wezterm").
    # Primarily derived from the `TERM` environment variable.
    def terminal_type : String
      ENV["TERM"]? || "dumb"
    end

    # Returns the color profile based on environment detection.
    # Detection order:
    # 1. `COLORTERM` environment variable (truecolor, 24bit)
    # 2. `TERM` substring matching (256color, ansi, color)
    # 3. Fallback to ANSI
    def color_profile : Lipgloss::ColorProfile
      # Check for capability-based override first
      if override = color_profile_override
        return override
      end

      # Check for truecolor/24bit support
      colorterm = ENV["COLORTERM"]?.to_s.downcase
      if colorterm.includes?("truecolor") || colorterm.includes?("24bit")
        return Lipgloss::ColorProfile::TrueColor
      end

      # Check for 256-color support
      term = terminal_type.downcase
      if term.includes?("256color")
        return Lipgloss::ColorProfile::ANSI256
      end

      # Check for basic color support
      if term.includes?("ansi") || term.includes?("color")
        return Lipgloss::ColorProfile::ANSI
      end

      # Default to ANSI for safety (most terminals support at least 16 colors)
      Lipgloss::ColorProfile::ANSI
    end

    # Decode hex string to ASCII string
    private def self.hex_to_string(hex : String) : String
      return "" if hex.size % 2 != 0
      String.build do |str|
        i = 0
        while i < hex.size
          byte = hex[i, 2].to_i(16)
          str << byte.unsafe_chr
          i += 2
        end
      end
    end

    # Process a capability response and upgrade color profile if applicable.
    # Returns true if color profile was upgraded.
    def self.process_capability(content : String) : Bool
      # Decode hex content
      decoded = hex_to_string(content)
      # Check for RGB or Tc capability
      if decoded.includes?("RGB")
        # RGB capability indicates true color support
        self.color_profile_override = Lipgloss::ColorProfile::TrueColor
        return true
      elsif decoded.includes?("Tc")
        # Tc capability indicates true color support
        self.color_profile_override = Lipgloss::ColorProfile::TrueColor
        return true
      end
      false
    end

    # Returns the platform identifier as a Symbol.
    # Possible values: `:darwin`, `:linux`, `:windows`, `:wsl`
    def platform : Symbol
      {% if flag?(:darwin) %}
        :darwin
      {% elsif flag?(:win32) || flag?(:windows) %}
        :windows
      {% elsif flag?(:linux) %}
        # Check for WSL (Windows Subsystem for Linux)
        if File.read("/proc/version").to_s.downcase.includes?("microsoft")
          :wsl
        else
          :linux
        end
      {% else %}
        :unknown
      {% end %}
    end

    # Returns whether the terminal supports truecolor (24-bit) colors.
    def truecolor? : Bool
      color_profile == Lipgloss::ColorProfile::TrueColor
    end

    # Returns whether the terminal supports 256 colors.
    def ansi256? : Bool
      color_profile == Lipgloss::ColorProfile::ANSI256
    end

    # Returns whether the terminal supports basic ANSI colors (16 colors).
    def ansi? : Bool
      color_profile == Lipgloss::ColorProfile::ANSI
    end

    # Returns whether the terminal is considered "dumb" (no color, limited capabilities).
    def dumb? : Bool
      terminal_type == "dumb"
    end

    # Returns whether the terminal is known to support keyboard enhancement protocol.
    # This includes terminals like Kitty, WezTerm, iTerm2, etc.
    def keyboard_enhancements? : Bool
      term = terminal_type.downcase
      term.includes?("kitty") || term.includes?("wezterm") || term.includes?("iterm") ||
        term.includes?("foot") || term.includes?("contour") || term.includes?("mintty")
    end

    # Returns whether the terminal is known to support mouse protocols.
    # Most modern terminals support xterm mouse protocol.
    def mouse? : Bool
      !dumb?
    end

    # Returns a hash of detected capabilities for debugging.
    def capabilities : Hash(String, Bool | String | Symbol)
      {
        "terminal_type"         => terminal_type,
        "color_profile"         => color_profile.to_s,
        "platform"              => platform,
        "truecolor"             => truecolor?,
        "ansi256"               => ansi256?,
        "ansi"                  => ansi?,
        "dumb"                  => dumb?,
        "keyboard_enhancements" => keyboard_enhancements?,
        "mouse"                 => mouse?,
      }
    end

    # Calculate relative luminance (0.0 to 1.0) of a color using the WCAG formula.
    # Uses sRGB gamma-compressed values (0-255) for simplicity.
    def color_luminance(color : Lipgloss::Color) : Float64
      r, g, b = color.to_rgb
      # Normalize to 0-1 range
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0
      # Relative luminance coefficients (without linearization, good enough for dark/light detection)
      0.2126 * r_norm + 0.7152 * g_norm + 0.0722 * b_norm
    end

    # Determine if a color is dark based on luminance threshold.
    # Returns true if luminance < 0.5 (midpoint).
    def has_dark_background?(color : Lipgloss::Color) : Bool
      color_luminance(color) < 0.5
    end

    # Update global dark/light mode setting based on background color.
    # This should be called when a BackgroundColorMsg is received.
    def update_dark_mode_from_background(color : Lipgloss::Color) : Nil
      dark = has_dark_background?(color)
      Lipgloss.has_dark_background = dark
      Lipgloss::StyleRenderer.default.has_dark_background = dark
    end
  end
end
