require "./styles"

module BubblezoneFullLipgloss
  class HistoryComponent
    getter id : String
    getter items : Array(String)
    property active : String

    @cache_height : Int32 = -1
    @cache_column_width : Int32 = -1
    @cache_active = Hash(String, String).new
    @cache_inactive = Hash(String, String).new

    # `id` is a unique prefix for this component's zones (Go: `zone.NewPrefix()`).
    def initialize(@id : String, @items : Array(String))
      @active = @items.first
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

    def view(width : Int32, height : Int32) : String
      return "" if width <= 0 || height <= 0
      column_width = [((width // @items.size) - 2), 1].max
      ensure_cache(column_width, height)

      entries = @items.map do |item|
        item == @active ? @cache_active[item] : @cache_inactive[item]
      end
      Term2.join_horizontal(Term2::Position::Top, entries)
    end

    private def ensure_cache(column_width : Int32, height : Int32) : Nil
      return if column_width == @cache_column_width && height == @cache_height && !@cache_active.empty? && !@cache_inactive.empty?

      @cache_column_width = column_width
      @cache_height = height
      @cache_active.clear
      @cache_inactive.clear

      @items.each do |item|
        zone_id = "#{@id}#{item}"
        @cache_active[item] = BubblezoneFullLipgloss.history_entry(zone_id, item, column_width, height, true)
        @cache_inactive[item] = BubblezoneFullLipgloss.history_entry(zone_id, item, column_width, height, false)
      end
    end
  end
end
