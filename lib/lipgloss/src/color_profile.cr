module Lipgloss
  # ColorProfile specifies the terminal's color capabilities.
  enum ColorProfile
    ASCII     # No colors
    ANSI      # 16 colors
    ANSI256   # 256 colors
    TrueColor # 16 million colors
  end

  # StyleRenderer provides lipgloss-compatible color profile management.
  class StyleRenderer
    @@default : StyleRenderer = StyleRenderer.new

    property color_profile : ColorProfile = ColorProfile::TrueColor
    property? has_dark_background : Bool = true

    def self.default : StyleRenderer
      @@default
    end

    def self.default=(renderer : StyleRenderer)
      @@default = renderer
    end

    def has_dark_background? : Bool
      @has_dark_background
    end
  end
end
