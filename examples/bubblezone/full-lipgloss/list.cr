require "./styles"

module BubblezoneFullLipgloss
  class ListItem
    getter name : String
    property done : Bool

    def initialize(@name : String, @done : Bool = false)
    end

    def toggle!
      @done = !@done
    end
  end

  class ListComponent
    getter id : String
    getter title : String
    getter items : Array(ListItem)

    # `id` is a unique prefix for this component's zones (Go: `zone.NewPrefix()`).
    def initialize(@id : String, @title : String, @items : Array(ListItem))
    end

    def handle_zone_click(msg : Term2::ZoneClickMsg) : Bool
      return false unless msg.action == Term2::ZoneMouseAction::Release
      return false unless msg.button == Term2::ZoneMouseButton::Left
      return false unless msg.id.starts_with?(@id)
      clicked = msg.id[@id.size..-1]
      if item = @items.find { |it| it.name == clicked }
        item.toggle!
        true
      else
        false
      end
    end

    def view(width : Int32, _height : Int32) : String
      lines = [BubblezoneFullLipgloss.list_header(@title)]
      @items.each do |item|
        zone_id = "#{@id}#{item.name}"
        lines << Term2::Zone.mark(zone_id, BubblezoneFullLipgloss.list_text(item.name, item.done))
      end
      BubblezoneFullLipgloss.list_style(width).render(lines.join("\n"))
    end
  end
end
