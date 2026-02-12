require "../../../src/term2"

module DoomFireExample
  include Term2::Prelude

  FIRE_PALETTE = [0, 233, 234, 52, 53, 88, 89, 94, 95, 96, 130, 131, 132, 133, 172, 214, 215, 220, 220, 221, 3, 226, 227, 230, 231, 7]
  RAMP         = [' ', '.', ':', '-', '=', '+', '*', '#', '%', '@']

  class TickMsg < Term2::Message; end

  class Model
    include Term2::Model

    property screen_buf : Array(Int32) = [] of Int32
    property width : Int32 = 0
    property height : Int32 = 0
    property fire_palette : Array(Int32) = FIRE_PALETTE
    property start_time : Time = Time.utc
    property frame_no : Int32 = 0

    def initialize
      width, height = Term2::Terminal.size
      width = 80 if width <= 0
      height = 24 if height <= 0
      setup_screen(width, height)
    end

    def init : Term2::Cmd
      tick
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        if msg.string == "q" || msg.string == "ctrl+c"
          return {self, Term2.quit}
        end
      when TickMsg
        spread_fire
        @frame_no += 1
        return {self, tick}
      when Term2::WindowSizeMsg
        # Some terminals can briefly report zero size during startup; keep
        # the initialized fallback dimensions until we get a usable size.
        if msg.width > 0 && msg.height > 0
          setup_screen(msg.width, msg.height)
        end
      end

      {self, nil}
    end

    def view : Term2::View
      return Term2::View.new(content: "Initializing...") if @width == 0

      content = String.build do |io|
        y = 0
        while y < @height - 2
          @width.times do |x|
            pixel_hi = @screen_buf[y * @width + x]
            pixel_lo = @screen_buf[(y + 1) * @width + x]

            avg = (pixel_hi + pixel_lo) // 2
            ramp_idx = (avg * (RAMP.size - 1)) // (@fire_palette.size - 1)
            io << RAMP[ramp_idx]
          end
          io << '\n' if y < @height - 2
          y += 2
        end

        elapsed = Time.utc - @start_time
        io << "Press q or ctrl+c to quit. Elapsed: #{elapsed.total_seconds.round.to_i}s"
      end

      Term2::View.new(content: content, alt_screen: true)
    end

    private def spread_fire : Nil
      @width.times do |x|
        @height.times do |y|
          spread_pixel(y * @width + x)
        end
      end
    end

    private def spread_pixel(idx : Int32) : Nil
      return if idx < @width

      pixel = @screen_buf[idx]
      if pixel == 0
        @screen_buf[idx - @width] = 0
        return
      end

      rnd = pseudo_rand3(idx)
      dst = idx - rnd + 1
      if dst - @width >= 0 && dst - @width < @screen_buf.size
        decay = rnd & 1
        new_value = pixel - decay
        new_value = 0 if new_value < 0
        @screen_buf[dst - @width] = new_value
      end
    end

    private def setup_screen(width : Int32, height : Int32) : Nil
      @width = width
      @height = height * 2
      @screen_buf = Array.new(@width * @height, 0)
      @width.times do |i|
        @screen_buf[(@height - 1) * @width + i] = @fire_palette.size - 1
      end
    end

    private def tick : Term2::Cmd
      Term2::Cmds.tick(50.milliseconds) { TickMsg.new }
    end

    private def pseudo_rand3(idx : Int32) : Int32
      seed = idx.to_i64 * 1_103_515_245_i64 + @frame_no.to_i64 * 12_345_i64 + 9_876_543_i64
      ((seed & 0x7FFF_FFFF_i64) % 3_i64).to_i
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(DoomFireExample::Model.new)
end
