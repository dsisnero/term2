require "lipgloss"

module Term2
  module Components
    struct TableStyles
      property header : Lipgloss::Style
      property cell : Lipgloss::Style
      property selected : Lipgloss::Style

      def initialize(@header : Lipgloss::Style = Lipgloss::Style.new, @cell : Lipgloss::Style = Lipgloss::Style.new, @selected : Lipgloss::Style = Lipgloss::Style.new)
      end

      def self.default : TableStyles
        TableStyles.new(
          Lipgloss::Style.new.padding(0, 1),
          Lipgloss::Style.new.padding(0, 1),
          Lipgloss::Style.new,
        )
      end
    end
  end
end
