require "./spec_helper"

module Term2
  describe MouseEvent do
    it "creates a mouse event with all properties" do
      event = MouseEvent.new(10, 20, MouseEvent::Button::Left, MouseEvent::Action::Press, alt: true, ctrl: false, shift: true)
      event.x.should eq(10)
      event.y.should eq(20)
      event.button.should eq(MouseEvent::Button::Left)
      event.action.should eq(MouseEvent::Action::Press)
      event.alt?.should be_true
      event.ctrl?.should be_false
      event.shift?.should be_true
    end

    it "creates a mouse event with default modifiers" do
      event = MouseEvent.new(5, 5, MouseEvent::Button::Right, MouseEvent::Action::Release)
      event.alt?.should be_false
      event.ctrl?.should be_false
      event.shift?.should be_false
    end

    it "converts to string representation" do
      event = MouseEvent.new(10, 20, MouseEvent::Button::Left, MouseEvent::Action::Press)
      event.to_s.should eq("left+press")
    end

    it "includes modifiers in string representation" do
      event = MouseEvent.new(10, 20, MouseEvent::Button::Left, MouseEvent::Action::Press, alt: true, ctrl: true)
      str = event.to_s
      str.should contain("alt")
      str.should contain("ctrl")
      str.should contain("left")
    end

    it "matches Bubble Tea string expectations" do
      specs = {
        MouseEvent.new(0, 0, MouseEvent::Button::None, MouseEvent::Action::Press)                                     => "unknown",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press)                                     => "left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Right, MouseEvent::Action::Press)                                    => "right+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Middle, MouseEvent::Action::Press)                                   => "middle+press",
        MouseEvent.new(0, 0, MouseEvent::Button::None, MouseEvent::Action::Release)                                   => "release",
        MouseEvent.new(0, 0, MouseEvent::Button::WheelUp, MouseEvent::Action::Press)                                  => "wheel up",
        MouseEvent.new(0, 0, MouseEvent::Button::WheelDown, MouseEvent::Action::Press)                                => "wheel down",
        MouseEvent.new(0, 0, MouseEvent::Button::WheelLeft, MouseEvent::Action::Press)                                => "wheel left",
        MouseEvent.new(0, 0, MouseEvent::Button::WheelRight, MouseEvent::Action::Press)                               => "wheel right",
        MouseEvent.new(0, 0, MouseEvent::Button::None, MouseEvent::Action::Move)                                      => "motion",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Release, shift: true)                      => "shift+left+release",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, shift: true)                        => "shift+left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, shift: true, ctrl: true)            => "ctrl+shift+left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, alt: true)                          => "alt+left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, ctrl: true)                         => "ctrl+left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, ctrl: true, alt: true)              => "ctrl+alt+left+press",
        MouseEvent.new(0, 0, MouseEvent::Button::Left, MouseEvent::Action::Press, ctrl: true, alt: true, shift: true) => "ctrl+alt+shift+left+press",
      }

      specs.each do |event, expected|
        event.to_s.should eq(expected)
      end
    end
  end

  describe MouseEvent::Button do
    it "has all expected button types" do
      MouseEvent::Button::Left.should be_a(MouseEvent::Button)
      MouseEvent::Button::Right.should be_a(MouseEvent::Button)
      MouseEvent::Button::Middle.should be_a(MouseEvent::Button)
      MouseEvent::Button::WheelUp.should be_a(MouseEvent::Button)
      MouseEvent::Button::WheelDown.should be_a(MouseEvent::Button)
      MouseEvent::Button::WheelLeft.should be_a(MouseEvent::Button)
      MouseEvent::Button::WheelRight.should be_a(MouseEvent::Button)
      MouseEvent::Button::Release.should be_a(MouseEvent::Button)
      MouseEvent::Button::None.should be_a(MouseEvent::Button)
    end
  end

  describe MouseEvent::Action do
    it "has all expected action types" do
      MouseEvent::Action::Press.should be_a(MouseEvent::Action)
      MouseEvent::Action::Release.should be_a(MouseEvent::Action)
      MouseEvent::Action::Drag.should be_a(MouseEvent::Action)
      MouseEvent::Action::Move.should be_a(MouseEvent::Action)
    end
  end

  describe MouseReader do
    describe "#check_mouse_event" do
      it "parses SGR mouse press event" do
        reader = MouseReader.new
        # SGR mouse format: \e[<button;x;y{M|m}
        # Button 0 = left, M = press
        event = reader.check_mouse_event("\e[<0;10;20M")
        event.should_not be_nil
        if event
          event.x.should eq(9)
          event.y.should eq(19)
          event.button.should eq(MouseEvent::Button::Left)
          event.action.should eq(MouseEvent::Action::Press)
        end
      end

      it "parses SGR mouse release event" do
        reader = MouseReader.new
        # Button 0 = left, m = release
        event = reader.check_mouse_event("\e[<0;15;25m")
        event.should_not be_nil
        if event
          event.x.should eq(14)
          event.y.should eq(24)
          event.action.should eq(MouseEvent::Action::Release)
        end
      end

      it "parses SGR right click event" do
        reader = MouseReader.new
        # Button 2 = right
        event = reader.check_mouse_event("\e[<2;5;10M")
        event.should_not be_nil
        if event
          event.button.should eq(MouseEvent::Button::Right)
        end
      end

      it "parses SGR middle click event" do
        reader = MouseReader.new
        # Button 1 = middle
        event = reader.check_mouse_event("\e[<1;5;10M")
        event.should_not be_nil
        if event
          event.button.should eq(MouseEvent::Button::Middle)
        end
      end

      it "parses SGR wheel up event" do
        reader = MouseReader.new
        # Button 64 = wheel up
        event = reader.check_mouse_event("\e[<64;10;10M")
        event.should_not be_nil
        if event
          event.button.should eq(MouseEvent::Button::WheelUp)
        end
      end

      it "parses SGR wheel down event" do
        reader = MouseReader.new
        # Button 65 = wheel down
        event = reader.check_mouse_event("\e[<65;10;10M")
        event.should_not be_nil
        if event
          event.button.should eq(MouseEvent::Button::WheelDown)
        end
      end

      it "parses legacy mouse press event" do
        reader = MouseReader.new
        # Legacy format: \e[M<button+32><x+32><y+32>
        # Button 0 (left) + 32 = 32, x=10+32=42, y=20+32=52
        event = reader.check_mouse_event("\e[M #{42.chr}#{52.chr}")
        event.should_not be_nil
        if event
          event.x.should eq(9)
          event.y.should eq(19)
          event.button.should eq(MouseEvent::Button::Left)
        end
      end

      it "returns nil for non-mouse sequences" do
        reader = MouseReader.new
        event = reader.check_mouse_event("\e[A") # Up arrow
        event.should be_nil
      end

      it "returns nil for incomplete sequences" do
        reader = MouseReader.new
        event = reader.check_mouse_event("\e[<0;10")
        event.should be_nil
      end
    end
  end

  describe Mouse do
    it "has enable_tracking method" do
      # Just verify the method exists
      Mouse.responds_to?(:enable_tracking).should be_true
    end

    it "has disable_tracking method" do
      Mouse.responds_to?(:disable_tracking).should be_true
    end

    it "has enable_click_reporting method" do
      Mouse.responds_to?(:enable_click_reporting).should be_true
    end

    it "has disable_click_reporting method" do
      Mouse.responds_to?(:disable_click_reporting).should be_true
    end

    it "has enable_drag_reporting method" do
      Mouse.responds_to?(:enable_drag_reporting).should be_true
    end

    it "has disable_drag_reporting method" do
      Mouse.responds_to?(:disable_drag_reporting).should be_true
    end

    it "has enable_move_reporting method" do
      Mouse.responds_to?(:enable_move_reporting).should be_true
    end

    it "has disable_move_reporting method" do
      Mouse.responds_to?(:disable_move_reporting).should be_true
    end
  end
end
