require "./spec_helper"

describe "Cross-Platform Compatibility" do
  describe "Terminal escape sequences" do
    it "generates valid ANSI escape sequences for cursor control" do
      output = IO::Memory.new
      Term2::Terminal.hide_cursor(output)
      output.rewind
      output.gets_to_end.should eq("\e[?25l")

      output = IO::Memory.new
      Term2::Terminal.show_cursor(output)
      output.rewind
      output.gets_to_end.should eq("\e[?25h")
    end

    it "generates valid alternate screen sequences" do
      output = IO::Memory.new
      Term2::Terminal.enter_alt_screen(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1049h")

      output = IO::Memory.new
      Term2::Terminal.exit_alt_screen(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1049l")
    end

    it "generates valid clear screen sequence" do
      output = IO::Memory.new
      Term2::Terminal.clear(output)
      output.rewind
      output.gets_to_end.should eq("\e[2J\e[H")
    end

    it "generates valid bracketed paste sequences" do
      output = IO::Memory.new
      Term2::Terminal.enable_bracketed_paste(output)
      output.rewind
      output.gets_to_end.should eq("\e[?2004h")

      output = IO::Memory.new
      Term2::Terminal.disable_bracketed_paste(output)
      output.rewind
      output.gets_to_end.should eq("\e[?2004l")
    end

    it "generates valid focus reporting sequences" do
      output = IO::Memory.new
      Term2::Terminal.enable_focus_reporting(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1004h")

      output = IO::Memory.new
      Term2::Terminal.disable_focus_reporting(output)
      output.rewind
      output.gets_to_end.should eq("\e[?1004l")
    end

    it "generates valid state save/restore sequences" do
      output = IO::Memory.new
      Term2::Terminal.save_state(output)
      output.rewind
      output.gets_to_end.should eq("\e7")

      output = IO::Memory.new
      Term2::Terminal.restore_state(output)
      output.rewind
      output.gets_to_end.should eq("\e8")
    end
  end

  describe "Terminal size detection" do
    it "returns valid size values" do
      width, height = Term2::Terminal.size
      width.should be > 0
      height.should be > 0
      # Size should be reasonable (between 10 and 500)
      width.should be >= 10
      width.should be <= 500
      height.should be >= 5
      height.should be <= 200
    end
  end

  describe "Key sequence compatibility" do
    # Test that key sequences work across different terminal types
    describe "xterm sequences" do
      it "parses xterm arrow keys" do
        Term2::KeySequences.find("\e[A").should eq(Term2::Key.new(Term2::KeyType::Up))
        Term2::KeySequences.find("\e[B").should eq(Term2::Key.new(Term2::KeyType::Down))
        Term2::KeySequences.find("\e[C").should eq(Term2::Key.new(Term2::KeyType::Right))
        Term2::KeySequences.find("\e[D").should eq(Term2::Key.new(Term2::KeyType::Left))
      end

      it "parses xterm function keys" do
        Term2::KeySequences.find("\eOP").should eq(Term2::Key.new(Term2::KeyType::F1))
        Term2::KeySequences.find("\eOQ").should eq(Term2::Key.new(Term2::KeyType::F2))
        Term2::KeySequences.find("\eOR").should eq(Term2::Key.new(Term2::KeyType::F3))
        Term2::KeySequences.find("\eOS").should eq(Term2::Key.new(Term2::KeyType::F4))
      end

      it "parses xterm modified arrows" do
        Term2::KeySequences.find("\e[1;5A").should eq(Term2::Key.new(Term2::KeyType::CtrlUp))
        Term2::KeySequences.find("\e[1;5B").should eq(Term2::Key.new(Term2::KeyType::CtrlDown))
        Term2::KeySequences.find("\e[1;2A").should eq(Term2::Key.new(Term2::KeyType::ShiftUp))
        Term2::KeySequences.find("\e[1;2B").should eq(Term2::Key.new(Term2::KeyType::ShiftDown))
      end
    end

    describe "linux console sequences" do
      it "parses linux console function keys" do
        Term2::KeySequences.find("\e[[A").should eq(Term2::Key.new(Term2::KeyType::F1))
        Term2::KeySequences.find("\e[[B").should eq(Term2::Key.new(Term2::KeyType::F2))
        Term2::KeySequences.find("\e[[C").should eq(Term2::Key.new(Term2::KeyType::F3))
        Term2::KeySequences.find("\e[[D").should eq(Term2::Key.new(Term2::KeyType::F4))
        Term2::KeySequences.find("\e[[E").should eq(Term2::Key.new(Term2::KeyType::F5))
      end
    end

    describe "VT100/VT220 sequences" do
      it "parses VT100 function keys" do
        Term2::KeySequences.find("\e[11~").should eq(Term2::Key.new(Term2::KeyType::F1))
        Term2::KeySequences.find("\e[12~").should eq(Term2::Key.new(Term2::KeyType::F2))
        Term2::KeySequences.find("\e[13~").should eq(Term2::Key.new(Term2::KeyType::F3))
        Term2::KeySequences.find("\e[14~").should eq(Term2::Key.new(Term2::KeyType::F4))
      end

      it "parses VT220 function keys" do
        Term2::KeySequences.find("\e[15~").should eq(Term2::Key.new(Term2::KeyType::F5))
        Term2::KeySequences.find("\e[17~").should eq(Term2::Key.new(Term2::KeyType::F6))
        Term2::KeySequences.find("\e[18~").should eq(Term2::Key.new(Term2::KeyType::F7))
        Term2::KeySequences.find("\e[19~").should eq(Term2::Key.new(Term2::KeyType::F8))
      end
    end

    describe "rxvt sequences" do
      it "parses rxvt shift arrow keys" do
        # rxvt uses \e[a, \e[b, \e[c, \e[d for shift arrows
        Term2::KeySequences.find("\e[a").should eq(Term2::Key.new(Term2::KeyType::ShiftUp))
        Term2::KeySequences.find("\e[b").should eq(Term2::Key.new(Term2::KeyType::ShiftDown))
        Term2::KeySequences.find("\e[c").should eq(Term2::Key.new(Term2::KeyType::ShiftRight))
        Term2::KeySequences.find("\e[d").should eq(Term2::Key.new(Term2::KeyType::ShiftLeft))
      end
    end
  end

  describe "Mouse protocol compatibility" do
    describe "SGR mouse protocol" do
      it "parses SGR mouse press events" do
        reader = Term2::MouseReader.new
        event = reader.check_mouse_event("\e[<0;10;20M")
        event.should_not be_nil
        if event
          event.x.should eq(10)
          event.y.should eq(20)
          event.button.should eq(Term2::MouseEvent::Button::Left)
          event.action.should eq(Term2::MouseEvent::Action::Press)
        end
      end

      it "parses SGR mouse release events" do
        reader = Term2::MouseReader.new
        event = reader.check_mouse_event("\e[<0;10;20m")
        event.should_not be_nil
        if event
          event.action.should eq(Term2::MouseEvent::Action::Release)
        end
      end

      it "parses SGR mouse with modifiers" do
        reader = Term2::MouseReader.new
        # Code 8 = Alt modifier (bit 3)
        event = reader.check_mouse_event("\e[<8;10;20M")
        event.should_not be_nil
        if event
          event.alt?.should be_true
        end

        # Code 16 = Ctrl modifier (bit 4)
        event = reader.check_mouse_event("\e[<16;10;20M")
        event.should_not be_nil
        if event
          event.ctrl?.should be_true
        end

        # Code 4 = Shift modifier (bit 2)
        event = reader.check_mouse_event("\e[<4;10;20M")
        event.should_not be_nil
        if event
          event.shift?.should be_true
        end
      end

      it "parses wheel events" do
        reader = Term2::MouseReader.new
        # Code 64 = wheel up
        event = reader.check_mouse_event("\e[<64;10;20M")
        event.should_not be_nil
        if event
          event.button.should eq(Term2::MouseEvent::Button::WheelUp)
        end

        # Code 65 = wheel down
        event = reader.check_mouse_event("\e[<65;10;20M")
        event.should_not be_nil
        if event
          event.button.should eq(Term2::MouseEvent::Button::WheelDown)
        end
      end
    end

    describe "Legacy X10 mouse protocol" do
      it "parses legacy mouse events" do
        reader = Term2::MouseReader.new
        # Legacy format: \e[M<button+32><x+32><y+32>
        # Button 0 (left) at position (10, 20)
        event = reader.check_mouse_event("\e[M #{42.chr}#{52.chr}")
        event.should_not be_nil
        if event
          event.x.should eq(10)
          event.y.should eq(20)
          event.button.should eq(Term2::MouseEvent::Button::Left)
        end
      end
    end
  end

  describe "Focus event compatibility" do
    it "recognizes focus in sequence" do
      key = Term2::KeySequences.find("\e[I")
      key.should_not be_nil
      if key
        key.type.should eq(Term2::KeyType::FocusIn)
      end
    end

    it "recognizes focus out sequence" do
      key = Term2::KeySequences.find("\e[O")
      key.should_not be_nil
      if key
        key.type.should eq(Term2::KeyType::FocusOut)
      end
    end
  end

  describe "Control character handling" do
    it "handles all standard control characters" do
      (0..31).each do |code|
        # Skip special cases that have their own handling
        next if code == 9 || code == 10 || code == 13 || code == 27

        char = code.chr
        # Control characters should be recognized
        key = Term2::Key.new(char)
        key.type.should eq(Term2::KeyType::Runes)
        key.runes.should eq([char])
      end
    end

    it "handles escape character via KeyType" do
      # Single escape is handled by KeyType, not KeySequences
      key = Term2::Key.new(Term2::KeyType::Esc)
      key.type.should eq(Term2::KeyType::Esc)
      key.to_s.should eq("esc")
    end

    it "handles tab character via KeyType" do
      key = Term2::Key.new(Term2::KeyType::Tab)
      key.type.should eq(Term2::KeyType::Tab)
      key.to_s.should eq("tab")
    end

    it "handles enter/carriage return via KeyType" do
      key = Term2::Key.new(Term2::KeyType::Enter)
      key.type.should eq(Term2::KeyType::Enter)
      key.to_s.should eq("enter")
    end

    it "handles backspace/delete via KeyType" do
      key = Term2::Key.new(Term2::KeyType::Backspace)
      key.type.should eq(Term2::KeyType::Backspace)
      key.to_s.should eq("backspace")
    end
  end

  describe "UTF-8 handling" do
    it "handles single-byte ASCII characters" do
      key = Term2::Key.new('a')
      key.type.should eq(Term2::KeyType::Runes)
      key.runes.should eq(['a'])
      key.to_s.should eq("a")
    end

    it "handles multi-byte UTF-8 characters" do
      key = Term2::Key.new('日')
      key.type.should eq(Term2::KeyType::Runes)
      key.runes.should eq(['日'])
      key.to_s.should eq("日")
    end

    it "handles emoji characters" do
      key = Term2::Key.new('🎉')
      key.type.should eq(Term2::KeyType::Runes)
      key.runes.should eq(['🎉'])
      key.to_s.should eq("🎉")
    end

    it "handles multi-character strings" do
      key = Term2::Key.new("hello")
      key.type.should eq(Term2::KeyType::Runes)
      key.runes.should eq(['h', 'e', 'l', 'l', 'o'])
      key.to_s.should eq("hello")
    end
  end
end
