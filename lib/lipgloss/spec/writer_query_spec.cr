require "./spec_helper"

describe "Lipgloss parity: writer/query APIs" do
  it "supports print family APIs" do
    io = IO::Memory.new
    previous = Lipgloss.writer
    begin
      Lipgloss.writer = io
      Lipgloss.print("a", 1)
      Lipgloss.println("x", "y")
      Lipgloss.printf("%s-%d", "q", 7)
      io.to_s.should eq("a1x y\nq-7")
    ensure
      Lipgloss.writer = previous
    end
  end

  it "supports fprint family and sprint family APIs" do
    io = IO::Memory.new
    Lipgloss.fprint(io, "foo", 2)
    Lipgloss.fprintln(io, "a", "b")
    Lipgloss.fprintf(io, "%s:%d", "z", 9)
    io.to_s.should eq("foo2a b\nz:9")

    Lipgloss.sprint("a", 1).should eq("a1")
    Lipgloss.sprintln("a", "b").should eq("a b\n")
    Lipgloss.sprintf("%s:%d", "x", 3).should eq("x:3")
  end

  it "provides background query compatibility APIs" do
    input = IO::Memory.new("\e]11;rgb:1a/2b/3c\a")
    output = IO::Memory.new
    parsed = Lipgloss.background_color(input, output)
    parsed.should eq(Lipgloss::Color.rgb(0x1a, 0x2b, 0x3c))
    output.to_s.should eq(Lipgloss::OSC_BG_QUERY)

    Lipgloss.has_dark_background(IO::Memory.new("\e]11;rgb:ff/ff/ff\a"), IO::Memory.new).should be_false
    Lipgloss.has_dark_background(IO::Memory.new("\e]11;rgb:00/00/00\a"), IO::Memory.new).should be_true
  end
end
