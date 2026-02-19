require "./spec_helper"

describe "Ansi.graphics_helpers" do
  describe ".kitty_graphics" do
    it "generates empty payload with no options" do
      result = Ansi.kitty_graphics(Bytes.empty)
      result.should eq "\e_G\e\\"
    end

    it "generates payload without options" do
      payload = "test".to_slice
      result = Ansi.kitty_graphics(payload)
      result.should eq "\e_G;test\e\\"
    end

    it "generates payload with options" do
      payload = "test".to_slice
      opts = ["a=t", "f=100"]
      result = Ansi.kitty_graphics(payload, opts)
      result.should eq "\e_Ga=t,f=100;test\e\\"
    end

    it "generates multiple options without payload" do
      opts = ["q=2", "C=1", "f=24"]
      result = Ansi.kitty_graphics(Bytes.empty, opts)
      result.should eq "\e_Gq=2,C=1,f=24\e\\"
    end

    it "handles special characters in payload" do
      payload = "\e_G".to_slice
      opts = ["a=t"]
      result = Ansi.kitty_graphics(payload, opts)
      result.should eq "\e_Ga=t;\e_G\e\\"
    end

    it "handles empty options array" do
      payload = "data".to_slice
      result = Ansi.kitty_graphics(payload, [] of String)
      result.should eq "\e_G;data\e\\"
    end
  end

  describe ".sixel_graphics" do
    it "generates sixel escape sequence with parameters" do
      payload = "sixel data".to_slice
      result = Ansi.sixel_graphics(1, 2, 3, payload)
      result.should eq "\eP1;2;3qsixel data\e\\"
    end

    it "omits negative p1 parameter" do
      payload = Bytes.empty
      result = Ansi.sixel_graphics(-1, 2, 3, payload)
      result.should eq "\eP;2;3q\e\\"
    end

    it "omits negative p2 parameter" do
      payload = Bytes.empty
      result = Ansi.sixel_graphics(1, -1, 3, payload)
      result.should eq "\eP1;;3q\e\\"
    end

    it "omits p3 when zero or negative" do
      payload = Bytes.empty
      result = Ansi.sixel_graphics(1, 2, 0, payload)
      result.should eq "\eP1;2q\e\\"

      result = Ansi.sixel_graphics(1, 2, -5, payload)
      result.should eq "\eP1;2q\e\\"
    end

    it "handles empty payload" do
      result = Ansi.sixel_graphics(1, 2, 3, Bytes.empty)
      result.should eq "\eP1;2;3q\e\\"
    end
  end

  describe ".iterm2" do
    it "generates iTerm2 escape sequence" do
      result = Ansi.iterm2("File=name=test.png")
      result.should eq "\e]1337;File=name=test.png\a"
    end

    it "handles empty data" do
      result = Ansi.iterm2("")
      result.should eq "\e]1337;\a"
    end
  end
end
