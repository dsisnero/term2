require "../spec_helper"

describe "BubbleTea parity: MouseEvent#to_s" do
  it "matches Bubble Tea string outputs" do
    cases = {
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Press)                                     => "unknown",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)                                     => "left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Right, Term2::MouseEvent::Action::Press)                                    => "right+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Middle, Term2::MouseEvent::Action::Press)                                   => "middle+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Release)                                   => "release",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelUp, Term2::MouseEvent::Action::Press)                                  => "wheel up",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelDown, Term2::MouseEvent::Action::Press)                                => "wheel down",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelLeft, Term2::MouseEvent::Action::Press)                                => "wheel left",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::WheelRight, Term2::MouseEvent::Action::Press)                               => "wheel right",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Move)                                      => "motion",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Release, shift: true)                      => "shift+left+release",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true)                        => "shift+left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, shift: true, ctrl: true)            => "ctrl+shift+left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, alt: true)                          => "alt+left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, ctrl: true)                         => "ctrl+left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, ctrl: true, alt: true)              => "ctrl+alt+left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press, ctrl: true, alt: true, shift: true) => "ctrl+alt+shift+left+press",
      Term2::MouseEvent.new(100, 200, Term2::MouseEvent::Button::Left, Term2::MouseEvent::Action::Press)                                 => "left+press",
      Term2::MouseEvent.new(0, 0, Term2::MouseEvent::Button::None, Term2::MouseEvent::Action::Press, type: "broken")                     => "unknown",
    }

    cases.each do |event, expected|
      event.to_s.should eq(expected)
    end
  end
end