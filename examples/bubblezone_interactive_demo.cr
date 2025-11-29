# BubbleZone Interactive Demo (Term2 version)
#
# This example demonstrates the core BubbleZone functionality integrated with Term2,
# showing how to create interactive zones and handle mouse events.

require "../src/term2"
require "../src/bubblezone"

include Term2::Prelude

class InteractiveDemoModel < Term2::Model
  property zones : Array(BubbleZone::ZoneInfo)
  property zone_manager : BubbleZone::ZoneManager
  property last_click : {Int32, Int32}?
  property hover_position : {Int32, Int32}?
  property active_zone : String?

  def initialize
    @zones = [] of BubbleZone::ZoneInfo
    @zone_manager = BubbleZone::ZoneManager.new
    @last_click = nil
    @hover_position = nil
    @active_zone = nil

    # Create some initial zones
    create_initial_zones
  end

  private def create_initial_zones
    @zones = [
      BubbleZone::ZoneInfo.new("header", 1, 2, 2, 40, 4),
      BubbleZone::ZoneInfo.new("button1", 1, 5, 6, 15, 8),
      BubbleZone::ZoneInfo.new("button2", 1, 20, 6, 30, 8),
      BubbleZone::ZoneInfo.new("content", 1, 2, 10, 40, 18),
      BubbleZone::ZoneInfo.new("footer", 1, 2, 20, 40, 22),
    ]

    # Add zones to manager
    @zones.each do |zone|
      @zone_manager.add(zone)
    end
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2.quit}
      when "r"
        # Reset zones
        @zone_manager.clear
        create_initial_zones
        @last_click = nil
        @active_zone = nil
      when "a"
        # Add a random zone
        add_random_zone
      end
    when MouseEvent
      @hover_position = {msg.x, msg.y}

      if msg.action == "press" && msg.button == "left"
        @last_click = {msg.x, msg.y}

        # Find which zone was clicked
        zone = @zone_manager.find_at(msg.x, msg.y)
        @active_zone = zone ? zone.id : nil

        # Handle zone-specific actions
        handle_zone_click(zone) if zone
      end
    end

    {self, Cmd.none}
  end

  private def handle_zone_click(zone : BubbleZone::ZoneInfo?)
    return unless zone

    case zone.id
    when "button1"
      puts "Button 1 clicked!"
    when "button2"
      puts "Button 2 clicked!"
    when "header"
      puts "Header clicked!"
    when "footer"
      puts "Footer clicked!"
    when "content"
      puts "Content area clicked!"
    else
      puts "Unknown zone clicked: #{zone.id}"
    end
  end

  private def add_random_zone
    x = rand(5..35)
    y = rand(5..20)
    width = rand(5..15)
    height = rand(2..6)

    zone_id = "zone_#{@zones.size + 1}"
    zone = BubbleZone::ZoneInfo.new(zone_id, 1, x, y, x + width, y + height)

    @zones << zone
    @zone_manager.add(zone)
  end

  def view : String
    String.build do |str|
      str << "╔══════════════════════════════════════════════════════════════╗\n"
      str << "║               BubbleZone Interactive Demo                    ║\n"
      str << "╚══════════════════════════════════════════════════════════════╝\n"
      str << "\n"

      # Draw zones
      (0..24).each do |y|
        (0..50).each do |x|
          zone = @zone_manager.find_at(x, y)

          if zone
            # Draw zone borders and content
            draw_zone_cell(str, x, y, zone)
          else
            str << " "
          end
        end
        str << "\n"
      end

      str << "\n"

      # Status information
      if last_click = @last_click
        str << "Last click: ".bold << "(#{last_click[0]}, #{last_click[1]})\n"
      else
        str << "Last click: ".bold << "None\n"
      end

      if hover_pos = @hover_position
        str << "Mouse position: ".bold << "(#{hover_pos[0]}, #{hover_pos[1]})\n"
      end

      if @active_zone
        str << "Active zone: ".bold << @active_zone << "\n"
      else
        str << "Active zone: ".bold << "None\n"
      end

      str << "\n"
      str << "Zones: ".bold << @zones.size.to_s << "\n"

      str << "\n"
      str << "Controls:\n"
      str << "  • Click on any colored area to interact\n"
      str << "  • 'r' - Reset zones\n"
      str << "  • 'a' - Add random zone\n"
      str << "  • 'q' - Quit\n"

      str << "\n"
      str << "Zone Legend:\n"
      str << "  █ Header    █ Button 1  █ Button 2  █ Content   █ Footer\n"
    end
  end

  private def draw_zone_cell(str, x, y, zone)
    is_border = x == zone.start_x || x == zone.end_x || y == zone.start_y || y == zone.end_y

    zone_chars = {
      "header"  => {border: "█", fill: "▒"},
      "button1" => {border: "█", fill: "▓"},
      "button2" => {border: "█", fill: "▓"},
      "content" => {border: "█", fill: "░"},
      "footer"  => {border: "█", fill: "▒"},
    }

    if chars = zone_chars[zone.id]?
      str << (is_border ? chars[:border] : chars[:fill])
    else
      # Random zones
      str << (is_border ? "█" : "·")
    end
  end
end

# Run the application
Term2.run(InteractiveDemoModel.new, options: Term2::ProgramOptions.new(
  WithAltScreen.new,
  WithMouseAllMotion.new
))
