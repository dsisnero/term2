require "./styles"

class TabsComponent
  getter id : String
  getter items : Array(String)
  property active : String

  def initialize(items : Array(String), @active : String)
    @id = Term2::Zone.new_prefix + "tabs__"
    @items = items
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

  def view(width : Int32) : String
    blocks = @items.map do |item|
      zone_id = "#{@id}#{item}"
      BubblezoneFullLipgloss.tab_block(zone_id, item, item == @active)
    end
    row = blocks.join
    gap_width = [width - Term2::Text.width(row) - 2, 0].max
    row + (" " * gap_width)
  end
end