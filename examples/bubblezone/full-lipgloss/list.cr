require "./styles"

class ListItem
  getter id : String
  getter name : String
  property done : Bool

  def initialize(@id : String, @name : String, @done : Bool = false)
  end

  def toggle!
    @done = !@done
  end
end

class ListComponent
  getter id : String
  getter title : String
  getter items : Array(ListItem)

  def initialize(@title : String, @items : Array(ListItem), suffix : String)
    @id = Term2::Zone.new_prefix + suffix
  end

  def handle_zone_click(msg : Term2::ZoneClickMsg) : Bool
    return false unless msg.id.starts_with?(@id)
    clicked = msg.id[@id.size..-1]
    if item = @items.find { |it| it.id == clicked }
      item.toggle!
      true
    else
      false
    end
  end

  def view(width : Int32, _height : Int32) : String
    lines = [BubblezoneFullLipgloss.list_header(@title)]
    @items.each do |item|
      zone_id = "#{@id}#{item.id}"
      lines << Term2::Zone.mark(zone_id, BubblezoneFullLipgloss.list_text(item.name, item.done))
    end
    BubblezoneFullLipgloss.list_style(width).render(lines.join("\n"))
  end
end
