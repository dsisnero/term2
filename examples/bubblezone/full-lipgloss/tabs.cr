require "./styles"

module BubblezoneFullLipgloss
  class TabsComponent
    getter id : String
    getter items : Array(String)
    property active : String

    # `id` is a unique prefix for this component's zones (Go: `zone.NewPrefix()`).
    def initialize(@id : String, items : Array(String), @active : String)
      @items = items
    end

    def handle_zone_click(msg : Term2::ZoneClickMsg) : Bool
      return false unless msg.action == Term2::ZoneMouseAction::Release
      return false unless msg.button == Term2::ZoneMouseButton::Left
      return false unless msg.id.starts_with?(@id)
      clicked = msg.id[@id.size..-1]
      if @items.includes?(clicked)
        @active = clicked
        true
      else
        false
      end
    end

    def view(width : Int32) : String
      blocks = @items.map do |item|
        zone_id = "#{@id}#{item}"
        BubblezoneFullLipgloss.tab_block(zone_id, item, item == @active)
      end

      tab = Lipgloss::Style.new
        .border(Lipgloss::Border.new("─", "─", "│", "│", "╭", "╮", "┴", "┴", "", "", "", "", ""), true)
        .border_foreground(BubblezoneFullLipgloss::HIGHLIGHT)
        .padding(0, 1)

      tab_gap = tab.copy
        .border_top(false)
        .border_left(false)
        .border_right(false)

      row = Lipgloss.join_horizontal(Lipgloss::Position::Top, blocks)
      gap_width = [width - Lipgloss::Text.width(row) - 2, 0].max
      gap = tab_gap.render(" " * gap_width)

      Lipgloss.join_horizontal(Lipgloss::Position::Bottom, row, gap)
    end
  end
end
