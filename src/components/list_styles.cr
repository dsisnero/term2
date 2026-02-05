require "lipgloss"

module Term2
  module Components
    # Styles used by the List component (parity with bubbles/list).
    struct ListStyles
      property title_bar : Lipgloss::Style
      property title : Lipgloss::Style
      property spinner : Lipgloss::Style
      property filter_prompt : Lipgloss::Style
      property filter_cursor : Lipgloss::Style
      property default_filter_character_match : Lipgloss::Style
      property status_bar : Lipgloss::Style
      property status_empty : Lipgloss::Style
      property status_bar_active_filter : Lipgloss::Style
      property status_bar_filter_count : Lipgloss::Style
      property no_items : Lipgloss::Style
      property pagination_style : Lipgloss::Style
      property help_style : Lipgloss::Style
      property active_pagination_dot : Lipgloss::Style
      property inactive_pagination_dot : Lipgloss::Style
      property arabic_pagination : Lipgloss::Style
      property divider_dot : Lipgloss::Style

      def initialize(
        @title_bar : Lipgloss::Style = Lipgloss::Style.new,
        @title : Lipgloss::Style = Lipgloss::Style.new,
        @spinner : Lipgloss::Style = Lipgloss::Style.new,
        @filter_prompt : Lipgloss::Style = Lipgloss::Style.new,
        @filter_cursor : Lipgloss::Style = Lipgloss::Style.new,
        @default_filter_character_match : Lipgloss::Style = Lipgloss::Style.new,
        @status_bar : Lipgloss::Style = Lipgloss::Style.new,
        @status_empty : Lipgloss::Style = Lipgloss::Style.new,
        @status_bar_active_filter : Lipgloss::Style = Lipgloss::Style.new,
        @status_bar_filter_count : Lipgloss::Style = Lipgloss::Style.new,
        @no_items : Lipgloss::Style = Lipgloss::Style.new,
        @pagination_style : Lipgloss::Style = Lipgloss::Style.new,
        @help_style : Lipgloss::Style = Lipgloss::Style.new,
        @active_pagination_dot : Lipgloss::Style = Lipgloss::Style.new,
        @inactive_pagination_dot : Lipgloss::Style = Lipgloss::Style.new,
        @arabic_pagination : Lipgloss::Style = Lipgloss::Style.new,
        @divider_dot : Lipgloss::Style = Lipgloss::Style.new,
      )
      end

      def self.default : ListStyles
        very_subdued = Lipgloss::Style.new.fg_hex("#DDDADA").background(Lipgloss::Color.from_hex("#3C3C3C"))
        subdued = Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#9B9B9B"))

        ListStyles.new(
          Lipgloss::Style.new.padding(0, 0, 1, 2),
          Lipgloss::Style.new.background(Lipgloss::Color.from_hex("62")).foreground(Lipgloss::Color.from_hex("230")).padding(0, 1),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("8E8E8E")),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("04B575")),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("EE6FF8")),
          Lipgloss::Style.new.underline(true),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("A49FA5")).padding(0, 0, 1, 2),
          subdued,
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("1a1a1a")),
          Lipgloss::Style.new.foreground(very_subdued.foreground_color || Lipgloss::Color::WHITE),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("909090")),
          Lipgloss::Style.new.padding_left(2),
          Lipgloss::Style.new.padding(1, 0, 0, 2),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("847A85")).set_string("•"),
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("DDDADA")).set_string("•"),
          subdued,
          Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("DDDADA")).set_string(" • "),
        )
      end
    end
  end
end
