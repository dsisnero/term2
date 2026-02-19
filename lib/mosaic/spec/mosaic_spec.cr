require "./spec_helper"
require "crimage"
require "stumpy_png"

describe Mosaic::Renderer do
  it "renders charm-wish.png correctly with default settings" do
    # Load test image
    canvas = StumpyPNG.read("temp/charm-wish.png")
    # Create renderer with same settings as Go test
    renderer = Mosaic::Renderer.new.width(80).height(40)

    # Render image
    result = renderer.render(canvas)

    Golden.require_equal("charm_wish_go_output", result, test_data_dir: "spec/fixtures")
  end

  it "implements proper dithering" do
    canvas = StumpyPNG.read("temp/charm-wish.png")
    renderer_no_dither = Mosaic::Renderer.new.width(80).height(40).dither(false)
    renderer_dither = Mosaic::Renderer.new.width(80).height(40).dither(true)

    result_no_dither = renderer_no_dither.render(canvas)
    result_dither = renderer_dither.render(canvas)

    # Dithering should produce different output for this image
    result_dither.should_not eq(result_no_dither)
  end

  it "supports color inversion" do
    canvas = StumpyPNG.read("temp/charm-wish.png")
    renderer_no_invert = Mosaic::Renderer.new.width(80).height(40).invert_colors(false)
    renderer_invert = Mosaic::Renderer.new.width(80).height(40).invert_colors(true)

    result_no_invert = renderer_no_invert.render(canvas)
    result_invert = renderer_invert.render(canvas)

    # Color inversion should produce different output for this image
    result_invert.should_not eq(result_no_invert)
  end

  it "supports different symbol sets" do
    canvas = StumpyPNG.read("temp/charm-wish.png")

    # Test each symbol type
    renderer_half = Mosaic::Renderer.new.width(80).height(40).symbol(Mosaic::Symbol::Half)
    renderer_quarter = Mosaic::Renderer.new.width(80).height(40).symbol(Mosaic::Symbol::Quarter)
    renderer_all = Mosaic::Renderer.new.width(80).height(40).symbol(Mosaic::Symbol::All)

    result_half = renderer_half.render(canvas)
    result_quarter = renderer_quarter.render(canvas)
    result_all = renderer_all.render(canvas)

    # Results should not be empty
    result_half.should_not be_empty
    result_quarter.should_not be_empty
    result_all.should_not be_empty

    # At least two symbol sets should produce different output
    # (not guaranteed but likely for our test image)
    (result_half == result_quarter && result_half == result_all).should be_false
  end

  it "ignores threshold values outside 0..255" do
    renderer = Mosaic::Renderer.new
    initial = renderer.threshold_level

    renderer.threshold(-1).threshold_level.should eq(initial)

    renderer.threshold(256).threshold_level.should eq(initial)

    renderer.threshold(42).threshold_level.should eq(42_u8)
  end

  it "uses fg/bg-only rendering when block symbols are ignored" do
    canvas = StumpyCore::Canvas.new(2, 2)
    2.times do |y|
      2.times do |x|
        canvas[x, y] = StumpyCore::RGBA.new(0, 0, 0, 255)
      end
    end

    default_output = Mosaic::Renderer.new.width(2).height(1).render(canvas)
    fg_bg_output = Mosaic::Renderer.new.width(2).height(1).ignore_block_symbols(true).render(canvas)

    ansi = /\e\[[0-9;]*m/
    default_symbols = default_output.gsub(ansi, "")
    fg_bg_symbols = fg_bg_output.gsub(ansi, "")

    default_symbols.should eq(" \n")
    fg_bg_symbols.should eq("▀\n")
  end

  it "keeps source height when only width is overridden (Go parity)" do
    canvas = StumpyCore::Canvas.new(4, 4)
    4.times do |y|
      4.times do |x|
        canvas[x, y] = StumpyCore::RGBA.new(255, 255, 255, 255)
      end
    end

    output = Mosaic::Renderer.new.width(2).render(canvas)
    stripped = output.gsub(/\e\[[0-9;]*m/, "")
    lines = stripped.chomp('\n').split('\n')

    lines.size.should eq(2)
    lines.first.size.should eq(1)
  end

  it "applies scale to rendered character-grid dimensions" do
    canvas = StumpyCore::Canvas.new(4, 4)
    4.times do |y|
      4.times do |x|
        canvas[x, y] = StumpyCore::RGBA.new(255, 255, 255, 255)
      end
    end

    scale_1 = Mosaic::Renderer.new.width(4).height(4).scale(1).render(canvas)
    scale_2 = Mosaic::Renderer.new.width(4).height(4).scale(2).render(canvas)

    clean_1 = scale_1.gsub(/\e\[[0-9;]*m/, "").chomp('\n').split('\n')
    clean_2 = scale_2.gsub(/\e\[[0-9;]*m/, "").chomp('\n').split('\n')

    clean_1.size.should eq(2)
    clean_1.first.size.should eq(2)

    clean_2.size.should eq(4)
    clean_2.first.size.should eq(4)
  end
end

describe Mosaic do
  it "provides a Go-compatible constructor wrapper" do
    Mosaic.new.should be_a(Mosaic::Renderer)
  end

  it "provides a Go-compatible render wrapper" do
    canvas = StumpyCore::Canvas.new(2, 2)
    2.times do |y|
      2.times do |x|
        canvas[x, y] = StumpyCore::RGBA.new(255, 255, 255, 255)
      end
    end

    direct = Mosaic::Renderer.new.width(2).height(1).render(canvas)
    wrapped = Mosaic.render(canvas, 2, 1)

    wrapped.should eq(direct)
  end

  it "uses Go-style value semantics for fluent option setters" do
    base = Mosaic.new
    modified = base.width(80).height(40).dither(true)

    base.output_width.should eq(0)
    base.output_height.should eq(0)
    base.dither?.should be_false

    modified.output_width.should eq(80)
    modified.output_height.should eq(40)
    modified.dither?.should be_true
  end

  it "renders decoded CrImage::Image like canvas rendering" do
    image = CrImage.read("temp/charm-wish.png")
    from_image = Mosaic.render(image, 80, 40)
    from_canvas = Mosaic.render(Mosaic.to_canvas(image), 80, 40)

    from_image.should eq(from_canvas)
  end

  it "renders image path like canvas rendering" do
    image = CrImage.read("temp/charm-wish.png")
    from_path = Mosaic.render("temp/charm-wish.png", 80, 40)
    from_canvas = Mosaic.render(Mosaic.to_canvas(image), 80, 40)

    from_path.should eq(from_canvas)
  end

  it "renders image bytes like canvas rendering" do
    image = CrImage.read("temp/charm-wish.png")
    bytes = File.read("temp/charm-wish.png").to_slice
    from_bytes = Mosaic.render(bytes, 80, 40)
    from_canvas = Mosaic.render(Mosaic.to_canvas(image), 80, 40)

    from_bytes.should eq(from_canvas)
  end

  it "renders image IO like canvas rendering" do
    io = File.open("temp/charm-wish.png")
    begin
      image = CrImage.read("temp/charm-wish.png")
      from_io = Mosaic.render(io, 80, 40)
      from_canvas = Mosaic.render(Mosaic.to_canvas(image), 80, 40)
      from_io.should eq(from_canvas)
    ensure
      io.close
    end
  end

  it "supports renderer overloads for path and decoded image" do
    renderer = Mosaic.new.width(80).height(40)
    image = CrImage.read("temp/charm-wish.png")
    canvas = Mosaic.to_canvas(image)

    renderer.render(image).should eq(renderer.render(canvas))
    renderer.render("temp/charm-wish.png").should eq(renderer.render(canvas))
  end
end
