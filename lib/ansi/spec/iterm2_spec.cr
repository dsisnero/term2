require "./spec_helper"
require "base64"

describe "Ansi::Iterm2 (port of Go iterm2_test.go)" do
  describe "ITerm2 integration" do
    it "generates empty file escape sequence" do
      file = Ansi::Iterm2::File.new
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;File=\a"
    end

    it "generates basic file with name and size" do
      file = Ansi::Iterm2::File.new(name: "test.png", size: 1024_i64)
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;File=name=test.png;size=1024\a"
    end

    it "generates file with dimensions" do
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        width: Ansi::Iterm2.pixels(100),
        height: Ansi::Iterm2::AUTO
      )
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;File=name=test.png;width=100px;height=auto\a"
    end

    it "generates file with all options" do
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        size: 1024_i64,
        width: Ansi::Iterm2.cells(100),
        height: Ansi::Iterm2.percent(50),
        ignore_aspect_ratio: true,
        inline: true,
        do_not_move_cursor: true
      )
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;File=name=test.png;size=1024;width=100;height=50%;preserveAspectRatio=0;inline=1;doNotMoveCursor=1\a"
    end

    it "generates file with content (base64 encoded)" do
      content = "test-content"
      encoded_content = Base64.strict_encode(content)
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        content: encoded_content.to_slice
      )
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;File=name=test.png:#{encoded_content}\a"
    end

    it "generates multipart file" do
      file = Ansi::Iterm2::MultipartFile.new(
        name: "test.png",
        size: 1024_i64,
        width: Ansi::Iterm2.pixels(100),
        height: Ansi::Iterm2.percent(50)
      )
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;MultipartFile=name=test.png;size=1024;width=100px;height=50%\a"
    end

    it "generates file part" do
      file = Ansi::Iterm2::FilePart.new(content: "part-content".to_slice)
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;FilePart=part-content\a"
    end

    it "generates file end" do
      file = Ansi::Iterm2::FileEnd.new
      result = Ansi.iterm2(file.to_s)
      result.should eq "\e]1337;FileEnd\a"
    end
  end

  describe "helper functions" do
    describe "Cells" do
      it "returns string without units" do
        [
          {0, "0"},
          {10, "10"},
          {-5, "-5"},
          {100, "100"},
        ].each do |input, expected|
          Ansi::Iterm2.cells(input).should eq expected
        end
      end
    end

    describe "Pixels" do
      it "returns string with px suffix" do
        [
          {0, "0px"},
          {10, "10px"},
          {-5, "-5px"},
          {100, "100px"},
        ].each do |input, expected|
          Ansi::Iterm2.pixels(input).should eq expected
        end
      end
    end

    describe "Percent" do
      it "returns string with % suffix" do
        [
          {0, "0%"},
          {10, "10%"},
          {-5, "-5%"},
          {100, "100%"},
        ].each do |input, expected|
          Ansi::Iterm2.percent(input).should eq expected
        end
      end
    end

    it "AUTO constant is 'auto'" do
      Ansi::Iterm2::AUTO.should eq "auto"
    end
  end
end

# Port of file_test.go
describe "Ansi::Iterm2 file tests (from Go file_test.go)" do
  describe "File string representation" do
    it "empty file returns empty options string" do
      file = Ansi::Iterm2::File.new
      # In Go, empty file returns empty string
      # In Crystal, File.to_s returns "File="
      file.to_s.should eq "File="
    end

    it "basic file with name and size" do
      file = Ansi::Iterm2::File.new(name: "test.png", size: 1024_i64)
      file.to_s.should eq "File=name=test.png;size=1024"
    end

    it "file with dimensions" do
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        width: "100px",
        height: "auto"
      )
      file.to_s.should eq "File=name=test.png;width=100px;height=auto"
    end

    it "file with all options" do
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        size: 1024_i64,
        width: "100px",
        height: "50%",
        ignore_aspect_ratio: true,
        inline: true,
        do_not_move_cursor: true
      )
      file.to_s.should eq "File=name=test.png;size=1024;width=100px;height=50%;preserveAspectRatio=0;inline=1;doNotMoveCursor=1"
    end

    it "file with content (base64 encoded)" do
      sample_content = "test-content"
      encoded_content = Base64.strict_encode(sample_content)
      file = Ansi::Iterm2::File.new(
        name: "test.png",
        content: encoded_content.to_slice
      )
      file.to_s.should eq "File=name=test.png:#{encoded_content}"
    end
  end

  describe "MultipartFile string representation" do
    it "basic multipart file" do
      file = Ansi::Iterm2::MultipartFile.new(
        name: "test.png",
        size: 1024_i64,
        width: "100px",
        height: "50%"
      )
      file.to_s.should eq "MultipartFile=name=test.png;size=1024;width=100px;height=50%"
    end
  end

  describe "FilePart string representation" do
    it "basic file part" do
      sample_content = "test-content".to_slice
      file = Ansi::Iterm2::FilePart.new(content: sample_content)
      file.to_s.should eq "FilePart=test-content"
    end
  end

  describe "FileEnd string representation" do
    it "file end" do
      file = Ansi::Iterm2::FileEnd.new
      file.to_s.should eq "FileEnd"
    end
  end
end
