require "../style"

module Term2
  module Components
    # Styles used by the List component (parity with bubbles/list).
    struct ListStyles
      property title_bar : Style
      property title : Style
      property spinner : Style
      property filter_prompt : Style
      property filter_cursor : Style
      property default_filter_character_match : Style
      property status_bar : Style
      property status_empty : Style
      property status_bar_active_filter : Style
      property status_bar_filter_count : Style
      property no_items : Style
      property pagination_style : Style
      property help_style : Style
      property active_pagination_dot : Style
      property inactive_pagination_dot : Style
      property arabic_pagination : Style
      property divider_dot : Style

      def initialize(
        @title_bar : Style = Style.new,
        @title : Style = Style.new,
        @spinner : Style = Style.new,
        @filter_prompt : Style = Style.new,
        @filter_cursor : Style = Style.new,
        @default_filter_character_match : Style = Style.new,
        @status_bar : Style = Style.new,
        @status_empty : Style = Style.new,
        @status_bar_active_filter : Style = Style.new,
        @status_bar_filter_count : Style = Style.new,
        @no_items : Style = Style.new,
        @pagination_style : Style = Style.new,
        @help_style : Style = Style.new,
        @active_pagination_dot : Style = Style.new,
        @inactive_pagination_dot : Style = Style.new,
        @arabic_pagination : Style = Style.new,
        @divider_dot : Style = Style.new,
      )
      end

      def self.default : ListStyles
        very_subdued = Style.new.fg_hex("#DDDADA").background(Color.from_hex("#3C3C3C"))
        subdued = Style.new.foreground(Color.from_hex("#9B9B9B"))

        ListStyles.new(
          Style.new.padding(0, 0, 1, 2),
          Style.new.background(Color.from_hex("62")).foreground(Color.from_hex("230")).padding(0, 1),
          Style.new.foreground(Color.from_hex("8E8E8E")),
          Style.new.foreground(Color.from_hex("04B575")),
          Style.new.foreground(Color.from_hex("EE6FF8")),
          Style.new.underline(true),
          Style.new.foreground(Color.from_hex("A49FA5")).padding(0, 0, 1, 2),
          subdued,
          Style.new.foreground(Color.from_hex("1a1a1a")),
          Style.new.foreground(very_subdued.foreground_color || Color::WHITE),
          Style.new.foreground(Color.from_hex("909090")),
          Style.new.padding_left(2),
          Style.new.padding(1, 0, 0, 2),
          Style.new.foreground(Color.from_hex("847A85")).set_string("•"),
          Style.new.foreground(Color.from_hex("DDDADA")).set_string("•"),
          subdued,
          Style.new.foreground(Color.from_hex("DDDADA")).set_string(" • "),
        )
      end
    end
  end
end
