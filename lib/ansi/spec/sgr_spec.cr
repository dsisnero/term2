require "./spec_helper"

describe "Ansi SGR functions" do
  describe ".select_graphic_rendition" do
    # Test cases from Go's sgr_test.go
    test_cases = [] of {name: String, args: Array(Ansi::Attr), want: String}

    test_cases << {
      name: "no attributes",
      args: [] of Ansi::Attr,
      want: "\e[m",
    }

    test_cases << {
      name: "single basic attribute",
      args: [Ansi::BoldAttr],
      want: "\e[1m",
    }

    test_cases << {
      name: "multiple basic attributes",
      args: [Ansi::BoldAttr, Ansi::ItalicAttr, Ansi::UnderlineAttr],
      want: "\e[1;3;4m",
    }

    test_cases << {
      name: "foreground colors",
      args: [Ansi::RedForegroundColorAttr, Ansi::BoldAttr],
      want: "\e[31;1m",
    }

    test_cases << {
      name: "background colors",
      args: [Ansi::BlueBackgroundColorAttr, Ansi::BoldAttr],
      want: "\e[44;1m",
    }

    test_cases << {
      name: "bright colors",
      args: [Ansi::BrightRedForegroundColorAttr, Ansi::BrightBlueBackgroundColorAttr],
      want: "\e[91;104m",
    }

    test_cases << {
      name: "reset attributes",
      args: [Ansi::ResetAttr],
      want: "\e[0m",
    }

    test_cases << {
      name: "negative attribute value",
      args: [-1] of Ansi::Attr,
      want: "\e[0m",
    }

    test_cases << {
      name: "custom attribute value",
      args: [99] of Ansi::Attr,
      want: "\e[99m",
    }

    test_cases << {
      name: "mixed known and custom attributes",
      args: [Ansi::BoldAttr, 99, Ansi::ItalicAttr],
      want: "\e[1;99;3m",
    }

    test_cases << {
      name: "all text decorations",
      args: [
        Ansi::BoldAttr,
        Ansi::FaintAttr,
        Ansi::ItalicAttr,
        Ansi::UnderlineAttr,
        Ansi::SlowBlinkAttr,
        Ansi::ReverseAttr,
        Ansi::ConcealAttr,
        Ansi::StrikethroughAttr,
      ] of Ansi::Attr,
      want: "\e[1;2;3;4;5;7;8;9m",
    }

    test_cases << {
      name: "all color reset attributes",
      args: [
        Ansi::DefaultForegroundColorAttr,
        Ansi::DefaultBackgroundColorAttr,
        Ansi::DefaultUnderlineColorAttr,
      ] of Ansi::Attr,
      want: "\e[39;49;59m",
    }

    test_cases << {
      name: "extended color attributes",
      args: [
        Ansi::ExtendedForegroundColorAttr,
        Ansi::ExtendedBackgroundColorAttr,
        Ansi::ExtendedUnderlineColorAttr,
      ] of Ansi::Attr,
      want: "\e[38;48;58m",
    }

    test_cases.each do |test_case|
      it test_case[:name] do
        Ansi.select_graphic_rendition(test_case[:args]).should eq test_case[:want]
      end
    end
  end

  describe ".sgr" do
    # Test that SGR is an alias for select_graphic_rendition
    test_cases = [] of {name: String, args: Array(Ansi::Attr)}

    test_cases << {
      name: "empty args",
      args: [] of Ansi::Attr,
    }

    test_cases << {
      name: "single arg",
      args: [Ansi::BoldAttr],
    }

    test_cases << {
      name: "multiple args",
      args: [Ansi::BoldAttr, Ansi::RedForegroundColorAttr, Ansi::BlueBackgroundColorAttr],
    }

    test_cases.each do |test_case|
      it test_case[:name] do
        sgr_result = Ansi.sgr(test_case[:args])
        select_result = Ansi.select_graphic_rendition(test_case[:args])
        sgr_result.should eq select_result
      end
    end
  end
end
