require "./base_types"

# Zone provides focus and mouse click management for Term2.
# Mirrors BubbleZone semantics using CML-style asynchronous worker messaging.
module Term2
  # Zone info for tracking interactive regions
  struct ZoneInfo
    getter id : String
    getter start_x : Int32
    getter start_y : Int32
    getter end_x : Int32
    getter end_y : Int32
    getter z_index : Int32
    getter iteration : Int32

    def initialize(@id : String = "", @start_x : Int32 = 0, @start_y : Int32 = 0, @end_x : Int32 = 0, @end_y : Int32 = 0, @z_index : Int32 = 0, @iteration : Int32 = 0)
    end

    def is_zero? : Bool
      @id.empty?
    end

    def in_bounds?(x : Int32, y : Int32) : Bool
      return false if is_zero?
      return false if @start_x > @end_x || @start_y > @end_y
      x >= @start_x && x <= @end_x && y >= @start_y && y <= @end_y
    end

    def pos(x : Int32, y : Int32) : Tuple(Int32, Int32)
      return {-1, -1} if is_zero? || !in_bounds?(x, y)
      {x - @start_x, y - @start_y}
    end

    def width : Int32
      @end_x - @start_x + 1
    end

    def height : Int32
      @end_y - @start_y + 1
    end
  end

  class ZoneClickMsg < Message
    getter id : String
    getter x : Int32 # relative to zone
    getter y : Int32 # relative to zone
    getter button : ZoneMouseButton
    getter action : ZoneMouseAction

    def initialize(@id : String, @x : Int32, @y : Int32, @button : ZoneMouseButton, @action : ZoneMouseAction)
    end
  end

  # Message sent when a mouse event is in bounds of a zone.
  class ZoneInBoundsMsg < Message
    getter zone : ZoneInfo
    getter event : MouseEvent

    def initialize(@zone : ZoneInfo, @event : MouseEvent)
    end
  end

  enum ZoneMouseButton
    Left
    Right
    Middle
    None
  end

  enum ZoneMouseAction
    Press
    Release
    Motion
  end

  record ZoneMouseEvent,
    x : Int32,
    y : Int32,
    button : ZoneMouseButton,
    action : ZoneMouseAction

  module Zone
    IDENT_START   = '\u001B'
    IDENT_BRACKET = '['
    IDENT_END     = 'z'

    @@enabled = Atomic(Bool).new(true)
    @@closed = Atomic(Bool).new(false)
    @@worker_running = Atomic(Bool).new(false)
    @@worker_mailbox : CML::Mailbox(WorkerMsg)? = nil
    @@worker_mutex = Mutex.new
    @@prefix_counter = Atomic(Int64).new(0_i64)

    private enum WorkerSignal
      Stop
    end

    private struct ClearIteration
      getter iteration : Int32

      def initialize(@iteration : Int32); end
    end

    private struct ClearId
      getter id : String

      def initialize(@id : String); end
    end

    private struct ClearAll
    end

    private struct MarkerRequest
      getter id : String
      getter reply : CML::Chan(String)

      def initialize(@id : String, @reply : CML::Chan(String)); end
    end

    private struct GetRequest
      getter id : String
      getter reply : CML::Chan(ZoneInfo)

      def initialize(@id : String, @reply : CML::Chan(ZoneInfo)); end
    end

    private struct GetAllRequest
      getter reply : CML::Chan(Hash(String, ZoneInfo))

      def initialize(@reply : CML::Chan(Hash(String, ZoneInfo))); end
    end

    private struct FocusRequest
      getter id : String

      def initialize(@id : String); end
    end

    private struct BlurRequest
      getter id : String

      def initialize(@id : String); end
    end

    private struct FocusNextRequest
      getter reply : CML::Chan(String?)

      def initialize(@reply : CML::Chan(String?)); end
    end

    private struct FocusPrevRequest
      getter reply : CML::Chan(String?)

      def initialize(@reply : CML::Chan(String?)); end
    end

    private struct FindAtRequest
      getter x : Int32
      getter y : Int32
      getter reply : CML::Chan(ZoneInfo?)

      def initialize(@x : Int32, @y : Int32, @reply : CML::Chan(ZoneInfo?)); end
    end

    private struct FindAllAtRequest
      getter x : Int32
      getter y : Int32
      getter reply : CML::Chan(Array(ZoneInfo))

      def initialize(@x : Int32, @y : Int32, @reply : CML::Chan(Array(ZoneInfo))); end
    end

    private struct AnyInBoundsRequest
      getter mouse : MouseEvent
      getter reply : CML::Chan(Array(ZoneInfo))

      def initialize(@mouse : MouseEvent, @reply : CML::Chan(Array(ZoneInfo))); end
    end

    private struct FocusedIdRequest
      getter reply : CML::Chan(String?)

      def initialize(@reply : CML::Chan(String?)); end
    end

    private struct MarkerCounterRequest
      getter reply : CML::Chan(UInt64)

      def initialize(@reply : CML::Chan(UInt64)); end
    end

    private struct RidsRequest
      getter reply : CML::Chan(Hash(String, String))

      def initialize(@reply : CML::Chan(Hash(String, String))); end
    end

    private struct ResetRequest
    end

    private alias WorkerMsg = ZoneInfo | ClearIteration | ClearId | ClearAll | WorkerSignal | MarkerRequest | GetRequest | GetAllRequest | FocusRequest | BlurRequest | FocusNextRequest | FocusPrevRequest | FocusedIdRequest | FindAtRequest | FindAllAtRequest | AnyInBoundsRequest | MarkerCounterRequest | RidsRequest | ResetRequest

    # Enable/disable zone tracking
    def self.enabled? : Bool
      @@enabled.get
    end

    def self.enabled=(value : Bool)
      ensure_worker
      @@enabled.set(value)
      if !value && !@@closed.get
        iteration = Time.local.nanosecond
        send_zone_update(ClearIteration.new(iteration))
      end
    end

    def self.clear
      return if @@closed.get
      ensure_worker
      send_zone_update(ClearAll.new)
    end

    def self.clear(id : String)
      return if @@closed.get
      ensure_worker
      send_zone_update(ClearId.new(id))
    end

    def self.clear_all
      clear
    end

    def self.reset
      @@closed.set(false)
      @@enabled.set(true)
      ensure_worker
      send_zone_update(ResetRequest.new)
    end

    def self.close
      return if @@closed.get
      @@closed.set(true)
      @@enabled.set(false)
      if mailbox = @@worker_mailbox
        mailbox.send(WorkerSignal::Stop)
      end
      @@worker_running.set(false)
    end

    def self.get(id : String) : ZoneInfo
      return ZoneInfo.new if @@closed.get
      ensure_worker
      reply = CML::Chan(ZoneInfo).new
      send_zone_update(GetRequest.new(id, reply))
      CML.sync(reply.recv_evt)
    end

    def self.zones : Hash(String, ZoneInfo)
      return Hash(String, ZoneInfo).new if @@closed.get
      ensure_worker
      reply = CML::Chan(Hash(String, ZoneInfo)).new
      send_zone_update(GetAllRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    def self.focused?(id : String) : Bool
      focused_id == id
    end

    def self.focused_id : String?
      return nil if @@closed.get
      ensure_worker
      reply = CML::Chan(String?).new
      send_zone_update(FocusedIdRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    def self.focused_id=(id : String?)
      return if @@closed.get
      ensure_worker
      id ? focus(id) : blur("")
    end

    def self.focus(id : String)
      return if @@closed.get
      ensure_worker
      send_zone_update(FocusRequest.new(id))
    end

    def self.blur(id : String)
      return if @@closed.get
      ensure_worker
      send_zone_update(BlurRequest.new(id))
    end

    def self.register(id : String, x : Int32, y : Int32, width : Int32, height : Int32, z_index : Int32 = 0)
      end_x = x + width - 1
      end_y = y + height - 1
      register(id, x, y, end_x, end_y, z_index)
    end

    def self.register(id : String, start_x : Int32, start_y : Int32, end_x : Int32, end_y : Int32, z_index : Int32 = 0)
      return if @@closed.get
      ensure_worker
      iteration = Time.local.nanosecond
      send_zone_update(ZoneInfo.new(id, start_x, start_y, end_x, end_y, z_index, iteration))
    end

    def self.mark(id : String, content : String) : String
      return content unless enabled?
      return content if id.empty? || content.empty? || @@closed.get
      ensure_worker
      reply = CML::Chan(String).new
      send_zone_update(MarkerRequest.new(id, reply))
      marker = CML.sync(reply.recv_evt)
      marker + content + marker
    end

    def self.scan(output : String) : String
      return output if @@closed.get
      ensure_worker

      rids = request_rids
      iteration = Time.local.nanosecond
      enabled = enabled?
      scanner = Scanner.new(output, iteration, enabled, rids)
      stripped, zones = scanner.run

      zones.each { |zone| send_zone_update(zone) } if enabled
      send_zone_update(ClearIteration.new(iteration))

      stripped
    end

    def self.find_at(x : Int32, y : Int32) : ZoneInfo?
      return nil if @@closed.get
      ensure_worker
      reply = CML::Chan(ZoneInfo?).new
      send_zone_update(FindAtRequest.new(x, y, reply))
      CML.sync(reply.recv_evt)
    end

    def self.handle_mouse(event : MouseEvent) : ZoneClickMsg?
      return nil unless enabled?
      return nil if @@closed.get

      if zone = find_at(event.x, event.y)
        rel_x = event.x - zone.start_x
        rel_y = event.y - zone.start_y

        button = case event.button
                 when MouseEvent::Button::Left   then ZoneMouseButton::Left
                 when MouseEvent::Button::Right  then ZoneMouseButton::Right
                 when MouseEvent::Button::Middle then ZoneMouseButton::Middle
                 else                                 ZoneMouseButton::None
                 end

        action = case event.action
                 when MouseEvent::Action::Press                          then ZoneMouseAction::Press
                 when MouseEvent::Action::Release                        then ZoneMouseAction::Release
                 when MouseEvent::Action::Drag, MouseEvent::Action::Move then ZoneMouseAction::Motion
                 else                                                         ZoneMouseAction::Press
                 end

        ZoneClickMsg.new(zone.id, rel_x, rel_y, button, action)
      end
    end

    def self.focus_next : String?
      return nil if @@closed.get
      ensure_worker
      reply = CML::Chan(String?).new
      send_zone_update(FocusNextRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    def self.focus_prev : String?
      return nil if @@closed.get
      ensure_worker
      reply = CML::Chan(String?).new
      send_zone_update(FocusPrevRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    def self.new_prefix : String
      "zone_#{@@prefix_counter.add(1)}__"
    end

    def self.marker_counter : UInt64
      return 0_u64 if @@closed.get
      ensure_worker
      reply = CML::Chan(UInt64).new
      send_zone_update(MarkerCounterRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    def self.any_in_bounds?(x : Int32, y : Int32) : Bool
      !find_all_at(x, y).empty?
    end

    def self.find_all_at(x : Int32, y : Int32) : Array(ZoneInfo)
      return [] of ZoneInfo if @@closed.get
      ensure_worker
      reply = CML::Chan(Array(ZoneInfo)).new
      send_zone_update(FindAllAtRequest.new(x, y, reply))
      CML.sync(reply.recv_evt)
    end

    def self.find_smallest_at(x : Int32, y : Int32) : ZoneInfo?
      zones = find_all_at(x, y)
      return nil if zones.empty?
      zones.min_by do |zone|
        area = zone.width * zone.height
        {-zone.z_index, area}
      end
    end

    def self.any_in_bounds(model : Model, mouse : MouseEvent)
      zones = find_in_bounds(mouse)
      zones.each do |zone|
        model.update(ZoneInBoundsMsg.new(zone, mouse))
      end
    end

    def self.any_in_bounds_and_update(model : Model, mouse : MouseEvent) : {Model, Cmd}
      zones = find_in_bounds(mouse)
      cmds = [] of Cmd
      zones.each do |zone|
        model, cmd = model.update(ZoneInBoundsMsg.new(zone, mouse))
        cmds << cmd if cmd
      end
      normalized = cmds.compact_map { |c| c.as(-> Msg?) }
      cmd = case normalized.size
            when 0 then nil
            when 1 then normalized.first
            else
              -> : Msg? { Term2::BatchMsg.new(normalized).as(Msg) }
            end
      {model, cmd}
    end

    private def self.find_in_bounds(mouse : MouseEvent) : Array(ZoneInfo)
      return [] of ZoneInfo if @@closed.get
      ensure_worker
      reply = CML::Chan(Array(ZoneInfo)).new
      send_zone_update(AnyInBoundsRequest.new(mouse, reply))
      CML.sync(reply.recv_evt)
    end

    private def self.ensure_worker
      return if @@closed.get
      return if @@worker_running.get
      @@worker_mutex.synchronize do
        return if @@closed.get
        return if @@worker_running.get
        mailbox = CML::Mailbox(WorkerMsg).new
        @@worker_mailbox = mailbox
        @@worker_running.set(true)
        spawn do
          worker_loop(mailbox)
        end
      end
    end

    private def self.send_zone_update(msg : WorkerMsg)
      return if @@closed.get
      if mailbox = @@worker_mailbox
        mailbox.send(msg)
      end
    end

    private def self.request_rids : Hash(String, String)
      reply = CML::Chan(Hash(String, String)).new
      send_zone_update(RidsRequest.new(reply))
      CML.sync(reply.recv_evt)
    end

    private def self.worker_loop(mailbox : CML::Mailbox(WorkerMsg))
      zones = Hash(String, ZoneInfo).new
      ids = Hash(String, String).new
      rids = Hash(String, String).new
      focused_id : String? = nil
      marker_counter = 1000_u64

      loop do
        msg = CML.sync(mailbox.recv_evt)
        case msg
        when WorkerSignal
          break
        when ZoneInfo
          zones[msg.id] = msg
        when ClearIteration
          zones.reject! { |_, info| info.iteration != msg.iteration }
        when ClearId
          zones.delete(msg.id)
        when ClearAll
          zones.clear
        when ResetRequest
          zones.clear
          ids.clear
          rids.clear
          focused_id = nil
          marker_counter = 1000_u64
        when MarkerRequest
          marker = ids[msg.id]? || begin
            marker_counter += 1
            generated = "#{IDENT_START}#{IDENT_BRACKET}#{marker_counter}#{IDENT_END}"
            ids[msg.id] = generated
            rids[generated] = msg.id
            generated
          end
          CML.sync(msg.reply.send_evt(marker))
        when RidsRequest
          CML.sync(msg.reply.send_evt(rids.dup))
        when GetRequest
          CML.sync(msg.reply.send_evt(zones[msg.id]? || ZoneInfo.new))
        when GetAllRequest
          CML.sync(msg.reply.send_evt(zones.dup))
        when FocusRequest
          focused_id = msg.id if zones.has_key?(msg.id)
        when BlurRequest
          if msg.id.empty?
            focused_id = nil
          else
            focused_id = nil if focused_id == msg.id
          end
        when FocusNextRequest
          ids_sorted = zones.keys.sort!
          next_id = if ids_sorted.empty?
                      nil
                    else
                      idx = focused_id ? ids_sorted.index(focused_id) : nil
                      ids_sorted[idx ? (idx + 1) % ids_sorted.size : 0]
                    end
          focused_id = next_id if next_id
          CML.sync(msg.reply.send_evt(focused_id))
        when FocusPrevRequest
          ids_sorted = zones.keys.sort!
          prev_id = if ids_sorted.empty?
                      nil
                    else
                      idx = focused_id ? ids_sorted.index(focused_id) : nil
                      ids_sorted[idx ? (idx - 1 + ids_sorted.size) % ids_sorted.size : ids_sorted.size - 1]
                    end
          focused_id = prev_id if prev_id
          CML.sync(msg.reply.send_evt(focused_id))
        when FocusedIdRequest
          CML.sync(msg.reply.send_evt(focused_id))
        when FindAtRequest
          CML.sync(msg.reply.send_evt(find_smallest_at(zones, msg.x, msg.y)))
        when FindAllAtRequest
          CML.sync(msg.reply.send_evt(find_all_at(zones, msg.x, msg.y)))
        when AnyInBoundsRequest
          CML.sync(msg.reply.send_evt(find_in_bounds(zones, msg.mouse)))
        when MarkerCounterRequest
          CML.sync(msg.reply.send_evt(marker_counter))
        end
      end
    ensure
      @@worker_running.set(false)
    end

    private def self.find_smallest_at(zones : Hash(String, ZoneInfo), x : Int32, y : Int32) : ZoneInfo?
      matches = find_all_at(zones, x, y)
      return nil if matches.empty?
      matches.min_by do |zone|
        area = zone.width * zone.height
        {-zone.z_index, area}
      end
    end

    private def self.find_all_at(zones : Hash(String, ZoneInfo), x : Int32, y : Int32) : Array(ZoneInfo)
      zones.values.select(&.in_bounds?(x, y))
    end

    private def self.find_in_bounds(zones : Hash(String, ZoneInfo), mouse : MouseEvent) : Array(ZoneInfo)
      zones.keys.sort!.compact_map do |id|
        zone = zones[id]
        zone if zone.in_bounds?(mouse.x, mouse.y)
      end
    end

    # Scanner that strips markers and records zone positions.
    private class Scanner
      def initialize(@input : String, @iteration : Int32, @enabled : Bool, @rids : Hash(String, String))
      end

      def run : {String, Array(ZoneInfo)}
        completed = [] of ZoneInfo
        open_zones = Hash(String, Tuple(Int32, Int32)).new

        stripped = String.build do |str|
          x = 0
          y = 0
          i = 0

          while i < @input.size
            if marker_start?(i)
              marker_end = scan_marker(i + 2)
              if marker_end && @input[marker_end] == IDENT_END
                marker = @input[i..marker_end]
                if id = @rids[marker]?
                  if coords = open_zones.delete(id)
                    start_x, start_y = coords
                    completed << ZoneInfo.new(id, start_x, start_y, x - 1, y, 0, @iteration) if @enabled
                  else
                    open_zones[id] = {x, y}
                  end
                  i = marker_end + 1
                  next
                end
              end
            end

            case @input[i]
            when '\n'
              x = 0
              y += 1
            when '\r'
              x = 0
            when '\e'
              skipped = skip_ansi(i + 1)
              if skipped > i
                str << @input[i...skipped]
                i = skipped
                next
              end
              x += 1
            else
              x += 1
            end

            str << @input[i]
            i += 1
          end
        end

        {stripped, completed}
      end

      private def marker_start?(index : Int32) : Bool
        @input[index]? == IDENT_START && @input[index + 1]? == IDENT_BRACKET
      end

      private def scan_marker(pos : Int32) : Int32?
        i = pos
        while i < @input.size && @input[i].ascii_number?
          i += 1
        end
        i
      end

      private def skip_ansi(pos : Int32) : Int32
        i = pos
        return i unless @input[i]? == '['
        i += 1
        while i < @input.size
          char = @input[i]
          i += 1
          break if char.ascii_letter?
        end
        i
      end
    end
  end
end
