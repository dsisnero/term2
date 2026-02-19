require "spec"
require "../src/**"

# Helper methods for testing
module SpecHelper
  # Convert bytes to hex string for comparison
  def hex_string(bytes : Bytes) : String
    bytes.hexstring
  end

  # Create a simple test image
  def create_test_image(width : Int32, height : Int32, color : Ansi::Color? = nil) : Ansi::Image
    color = color || Ansi::Color.new(255_u8, 0_u8, 0_u8, 255_u8)
    image = Ansi::RGBAImage.new(width, height)
    height.times do |y|
      width.times do |x|
        image.set(x, y, color)
      end
    end
    image
  end
end

Spec.before_each do
  # Setup before each spec
end

Spec.after_each do
  # Cleanup after each spec
end
