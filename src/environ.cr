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
  end
end
