ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"

private class TimeoutIO < IO
  property read_timeout : Time::Span? = nil

  def initialize(@chunks : Array(String))
    @current = ""
    @pos = 0
  end

  def read(slice : Bytes) : Int32
    raise IO::Error.new("not implemented")
  end

  def write(slice : Bytes) : Nil
    raise IO::Error.new("not implemented")
  end

  def read_char : Char?
    loop do
      if @pos < @current.size
        ch = @current[@pos]
        @pos += 1
        return ch
      end

      if next_chunk = @chunks.shift?
        @current = next_chunk
        @pos = 0
        next
      end

      raise IO::TimeoutError.new if @read_timeout
      raise IO::EOFError.new
    end
  end
end

describe Term2::KeyReader do
  it "parses chunked SGR mouse sequences under timeouts" do
    io = TimeoutIO.new([
      "\e",    # ESC arrives first (common in real terminals)
      "[<0;4", # then part of CSI payload
      "5;3M",  # completes press
    ])

    reader = Term2::KeyReader.new

    # Read until we get the synthetic Null key that indicates a mouse event.
    key = nil.as(Term2::Key?)
    20.times do
      key = reader.read_key(io)
      break if key
    end

    key.should_not be_nil
    key.not_nil!.type.should eq(Term2::KeyType::Null)

    mouse = reader.last_mouse_event
    mouse.should_not be_nil
    mouse.not_nil!.x.should eq(44) # SGR uses 1-based; we normalize to 0-based
    mouse.not_nil!.y.should eq(2)
    mouse.not_nil!.action.should eq(Term2::MouseEvent::Action::Press)
    mouse.not_nil!.button.should eq(Term2::MouseEvent::Button::Left)
  end
end
