# spec/bubblezone/support/bubblezone_helpers_spec.cr
# Base helper file for bubblezone specs

module BubbleZoneHelpers
  # Shared setup and teardown methods

  def self.create_test_zone(id = "test", x = 0, y = 0, width = 10, height = 5)
    Term2::Zone.register(id, x, y, width, height)
  end

  def self.create_test_zones(count = 3)
    count.times do |i|
      Term2::Zone.register("zone_#{i}", i * 15, i * 10, 10, 5)
    end
  end

  def self.create_mouse_event(x = 0, y = 0, button = :left, action = :press)
    uv_button = case button
                when Symbol
                  case button
                  when :left      then UV::MouseButton::Left
                  when :right     then UV::MouseButton::Right
                  when :middle    then UV::MouseButton::Middle
                  when :wheel_up  then UV::MouseButton::WheelUp
                  when :wheel_down then UV::MouseButton::WheelDown
                  when :wheel_left then UV::MouseButton::WheelLeft
                  when :wheel_right then UV::MouseButton::WheelRight
                  else
                    UV::MouseButton::None
                  end
                when UV::MouseButton
                  button
                else
                  UV::MouseButton::None
                end

    Term2::TestHelpers.mouse_event(x: x, y: y, button: uv_button, action: action)
  end

  # Helper to wait for async zone processing
  def self.wait_for_zones(delay_ms = 20)
    sleep delay_ms.milliseconds
  end

  # Helper methods for zone assertions

  def self.assert_zone_exists(zone)
    !zone.zero?
  end

  def self.assert_zone_at(zone, x, y)
    !zone.zero?
  end

  def self.assert_contains_point(zone, x, y)
    zone.in_bounds?(x, y)
  end

  # Helper methods for common test patterns

  def self.with_zone_reset(&block)
    Term2::Zone.reset
    block.call
  ensure
    Term2::Zone.reset
  end

  def self.scan_and_wait(text : String, delay_ms = 20)
    result = Term2::Zone.scan(text)
    wait_for_zones(delay_ms)
    result
  end

  def self.mark_and_wait(id : String, content : String, delay_ms = 20)
    result = Term2::Zone.mark(id, content)
    wait_for_zones(delay_ms)
    result
  end
end

# Include helpers in spec context
Spec.before_each do
  Term2::Zone.reset
end

Spec.after_each do
  Term2::Zone.reset
end

# Helper method shortcuts
def zone_exists?(zone)
  !zone.zero?
end

def point_in_zone?(zone, x, y)
  zone.in_bounds?(x, y)
end
