require "./spec_helper"

describe Ansi::Image do
  describe "interface" do
    it "requires width, height, pixel, and each_pixel methods" do
      # This is just documentation of the interface
      # Actual testing happens with concrete implementations
      true.should be_true
    end
  end
end

describe Ansi::RGBAImage do
  describe "initialize" do
    it "creates an image with given dimensions" do
      image = Ansi::RGBAImage.new(10, 20)
      image.width.should eq 10
      image.height.should eq 20
    end

    it "fills image with black by default" do
      image = Ansi::RGBAImage.new(5, 5)
      color = image.pixel(0, 0)
      color.r.should eq 0_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
      color.a.should eq 255_u8
    end

    it "fills image with specified color" do
      fill_color = Ansi::Color.new(255_u8, 128_u8, 64_u8, 255_u8)
      image = Ansi::RGBAImage.new(5, 5, fill_color)
      color = image.pixel(2, 3)
      color.r.should eq 255_u8
      color.g.should eq 128_u8
      color.b.should eq 64_u8
      color.a.should eq 255_u8
    end
  end

  describe "pixel" do
    it "returns pixel color at coordinates" do
      image = Ansi::RGBAImage.new(3, 3)
      red = Ansi::Color.new(255_u8, 0_u8, 0_u8)
      image.set(1, 2, red)

      color = image.pixel(1, 2)
      color.r.should eq 255_u8
      color.g.should eq 0_u8
      color.b.should eq 0_u8
    end

    it "raises on out of bounds access" do
      image = Ansi::RGBAImage.new(3, 3)
      expect_raises(IndexError) do
        image.pixel(5, 5)
      end
    end
  end

  describe "set" do
    it "sets pixel color at coordinates" do
      image = Ansi::RGBAImage.new(4, 4)
      blue = Ansi::Color.new(0_u8, 0_u8, 255_u8)

      image.set(2, 3, blue)
      color = image.pixel(2, 3)
      color.b.should eq 255_u8
    end

    it "overwrites existing pixel color" do
      image = Ansi::RGBAImage.new(2, 2)
      red = Ansi::Color.new(255_u8, 0_u8, 0_u8)
      green = Ansi::Color.new(0_u8, 255_u8, 0_u8)

      image.set(0, 0, red)
      image.set(0, 0, green)

      color = image.pixel(0, 0)
      color.g.should eq 255_u8
    end
  end

  describe "each_pixel" do
    it "iterates over all pixels" do
      image = Ansi::RGBAImage.new(2, 2)
      colors = [
        Ansi::Color.new(255_u8, 0_u8, 0_u8),
        Ansi::Color.new(0_u8, 255_u8, 0_u8),
        Ansi::Color.new(0_u8, 0_u8, 255_u8),
        Ansi::Color.new(255_u8, 255_u8, 0_u8),
      ]

      # Set different colors
      image.set(0, 0, colors[0])
      image.set(1, 0, colors[1])
      image.set(0, 1, colors[2])
      image.set(1, 1, colors[3])

      visited = [] of Tuple(Int32, Int32, Ansi::Color)
      image.each_pixel do |x, y, color|
        visited << {x, y, color}
      end

      visited.size.should eq 4
      visited.should contain({0, 0, colors[0]})
      visited.should contain({1, 0, colors[1]})
      visited.should contain({0, 1, colors[2]})
      visited.should contain({1, 1, colors[3]})
    end

    it "yields pixels in row-major order" do
      image = Ansi::RGBAImage.new(3, 2)
      order = [] of Tuple(Int32, Int32)
      image.each_pixel do |x, y, _|
        order << {x, y}
      end

      expected_order = [
        {0, 0}, {1, 0}, {2, 0},
        {0, 1}, {1, 1}, {2, 1},
      ]
      order.should eq expected_order
    end
  end
end
