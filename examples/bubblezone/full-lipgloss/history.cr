require "./styles"

class HistoryComponent
  getter id : String
  getter items : Array(String)
  property active : String

  def initialize(@items : Array(String))
    @id = Term2::Zone.new_prefix + "history_"
    @active = @items.first
  end

  def handle_zone_click(msg : Term2::ZoneClickMsg) : Bool
    return false unless msg.id.starts_with?(@id)
    clicked = msg.id[@id.size..-1]
    if @items.includes?(clicked)
      @active = clicked
      true
    else
      false
    end
  end

  def view(width : Int32, height : Int32) : String
    return "" if width <= 0 || height <= 0
    zone_height = [height - 2, 1].max
    column_width = [[width // @items.size, 1].max, width].min
    entries = @items.map do |item|
      zone_id = "#{@id}#{item}"
      BubblezoneFullLipgloss.history_entry(zone_id, item, column_width, zone_height, item == @active)
    end
    entries.join
  end
end
