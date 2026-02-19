require "./spec_helper"

describe "Lipgloss parity: wrap APIs" do
  it "adds style reset/reopen around newlines in WrapWriter" do
    io = IO::Memory.new
    writer = Lipgloss::WrapWriter.new(io)
    writer.write("\e[31mfoo\nbar\e[0m")
    writer.close

    io.to_s.should eq("\e[31mfoo\e[0m\n\e[31mbar\e[0m")
  end

  it "adds hyperlink reset/reopen around newlines in WrapWriter" do
    io = IO::Memory.new
    writer = Lipgloss::WrapWriter.new(io)
    writer.write("\e]8;;https://example.com\afoo\nbar\e]8;;\a")
    writer.close

    io.to_s.should eq("\e]8;;https://example.com\afoo\e]8;;\a\n\e]8;;https://example.com\abar\e]8;;\a")
  end

  it "wraps and preserves active style state across wrapped lines" do
    rendered = Lipgloss.wrap("\e[31mhello world\e[0m", 6)
    rendered.includes?("\n\e[31m").should be_true
    Lipgloss::Text.strip_ansi(rendered).should eq("hello\nworld")
  end
end
