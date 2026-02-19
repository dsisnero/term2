require "./spec_helper"

def sort_strings(values : Array(String)) : Array(String)
  values.sort
end

def contains_option?(opts : Array(String), target : String) : Bool
  opts.includes?(target)
end

describe "Ansi::Kitty::Options" do
  it "builds options" do
    tests = [
      {
        name:     "default options",
        options:  Ansi::Kitty::Options.new,
        expected: [] of String,
      },
      {
        name:    "basic transmission options",
        options: begin
          o = Ansi::Kitty::Options.new
          o.format = Ansi::Kitty::PNG
          o.id = 1
          o.action = Ansi::Kitty::TransmitAndPut
          o
        end,
        expected: ["f=100", "i=1", "a=T"],
      },
      {
        name:    "display options",
        options: begin
          o = Ansi::Kitty::Options.new
          o.x = 100
          o.y = 200
          o.z = 3
          o.width = 400
          o.height = 300
          o
        end,
        expected: ["x=100", "y=200", "z=3", "w=400", "h=300"],
      },
      {
        name:    "compression and chunking",
        options: begin
          o = Ansi::Kitty::Options.new
          o.compression = Ansi::Kitty::Zlib
          o.chunk = true
          o.size = 1024
          o
        end,
        expected: ["S=1024", "o=z"],
      },
      {
        name:    "delete options",
        options: begin
          o = Ansi::Kitty::Options.new
          o.delete = Ansi::Kitty::DeleteID
          o.delete_resources = true
          o
        end,
        expected: ["d=I"],
      },
      {
        name:    "virtual placement",
        options: begin
          o = Ansi::Kitty::Options.new
          o.virtual_placement = true
          o.parent_id = 5
          o.parent_placement_id = 2
          o
        end,
        expected: ["U=1", "P=5", "Q=2"],
      },
      {
        name:    "cell positioning",
        options: begin
          o = Ansi::Kitty::Options.new
          o.offset_x = 10
          o.offset_y = 20
          o.columns = 80
          o.rows = 24
          o
        end,
        expected: ["X=10", "Y=20", "c=80", "r=24"],
      },
      {
        name:    "transmission details",
        options: begin
          o = Ansi::Kitty::Options.new
          o.transmission = Ansi::Kitty::File
          o.file = "/tmp/image.png"
          o.offset = 100
          o.number = 2
          o.placement_id = 3
          o
        end,
        expected: ["p=3", "I=2", "t=f", "O=100"],
      },
      {
        name:    "quiet mode and format",
        options: begin
          o = Ansi::Kitty::Options.new
          o.quite = 2_u8
          o.format = Ansi::Kitty::RGB
          o
        end,
        expected: ["f=24", "q=2"],
      },
      {
        name:    "all zero values",
        options: begin
          o = Ansi::Kitty::Options.new
          o.format = 0
          o.action = 0_u8
          o.delete = 0_u8
          o
        end,
        expected: [] of String,
      },
    ]

    tests.each do |test_case|
      got = test_case[:options].options
      sort_strings(got).should eq(sort_strings(test_case[:expected]))
    end
  end

  it "validates options output" do
    tests = [
      {
        name:    "format validation",
        options: begin
          o = Ansi::Kitty::Options.new
          o.format = 999
          o
        end,
        check: ->(opts : Array(String)) { contains_option?(opts, "f=999") },
      },
      {
        name:    "delete with resources",
        options: begin
          o = Ansi::Kitty::Options.new
          o.delete = Ansi::Kitty::DeleteID
          o.delete_resources = true
          o
        end,
        check: ->(opts : Array(String)) { contains_option?(opts, "d=I") },
      },
      {
        name:    "transmission with file",
        options: begin
          o = Ansi::Kitty::Options.new
          o.file = "/tmp/test.png"
          o
        end,
        check: ->(opts : Array(String)) { contains_option?(opts, "t=f") },
      },
    ]

    tests.each do |test_case|
      got = test_case[:options].options
      test_case[:check].call(got).should be_true
    end
  end

  it "renders to string" do
    tests = [
      {
        name:    "empty options",
        options: Ansi::Kitty::Options.new,
        want:    "",
      },
      {
        name:    "full options",
        options: begin
          o = Ansi::Kitty::Options.new
          o.action = 'A'.ord.to_u8
          o.quite = 'Q'.ord.to_u8
          o.compression = 'C'.ord.to_u8
          o.transmission = 'T'.ord.to_u8
          o.delete = 'd'.ord.to_u8
          o.delete_resources = true
          o.id = 123
          o.placement_id = 456
          o.number = 789
          o.format = 1
          o.image_width = 800
          o.image_height = 600
          o.size = 1024
          o.offset = 10
          o.chunk = true
          o.x = 100
          o.y = 200
          o.z = 300
          o.width = 400
          o.height = 500
          o.offset_x = 50
          o.offset_y = 60
          o.columns = 4
          o.rows = 3
          o.virtual_placement = true
          o.parent_id = 999
          o.parent_placement_id = 888
          o
        end,
        want: "f=1,q=81,i=123,p=456,I=789,s=800,v=600,t=T,S=1024,O=10,U=1,P=999,Q=888,x=100,y=200,z=300,w=400,h=500,X=50,Y=60,c=4,r=3,d=D,a=A",
      },
    ]

    tests.each do |test_case|
      test_case[:options].to_s.should eq(test_case[:want])
    end
  end

  it "marshals to text" do
    tests = [
      {
        name:    "marshal empty options",
        options: Ansi::Kitty::Options.new,
        want:    "".to_slice,
      },
      {
        name:    "marshal with values",
        options: begin
          o = Ansi::Kitty::Options.new
          o.action = 'A'.ord.to_u8
          o.id = 123
          o.width = 400
          o.height = 500
          o.quite = 2_u8
          o.do_not_move_cursor = true
          o
        end,
        want: "q=2,i=123,C=1,w=400,h=500,a=A".to_slice,
      },
    ]

    tests.each do |test_case|
      test_case[:options].marshal_text.should eq(test_case[:want])
    end
  end

  it "unmarshals from text" do
    tests = [
      {
        name: "unmarshal empty",
        text: "".to_slice,
        want: Ansi::Kitty::Options.new,
      },
      {
        name: "unmarshal basic options",
        text: "a=A,i=123,w=400,h=500".to_slice,
        want: begin
          o = Ansi::Kitty::Options.new
          o.action = 'A'.ord.to_u8
          o.id = 123
          o.width = 400
          o.height = 500
          o
        end,
      },
      {
        name: "unmarshal with invalid number",
        text: "i=abc".to_slice,
        want: Ansi::Kitty::Options.new,
      },
      {
        name: "unmarshal with delete resources",
        text: "d=D".to_slice,
        want: begin
          o = Ansi::Kitty::Options.new
          o.delete = 'd'.ord.to_u8
          o.delete_resources = true
          o
        end,
      },
      {
        name: "unmarshal with boolean chunk",
        text: "m=1".to_slice,
        want: begin
          o = Ansi::Kitty::Options.new
          o.chunk = true
          o
        end,
      },
      {
        name: "unmarshal with virtual placement",
        text: "U=1".to_slice,
        want: begin
          o = Ansi::Kitty::Options.new
          o.virtual_placement = true
          o
        end,
      },
      {
        name: "unmarshal with invalid format",
        text: "invalid=format".to_slice,
        want: Ansi::Kitty::Options.new,
      },
      {
        name: "unmarshal with missing value",
        text: "a=".to_slice,
        want: Ansi::Kitty::Options.new,
      },
    ]

    tests.each do |test_case|
      o = Ansi::Kitty::Options.new
      o.unmarshal_text(test_case[:text])
      o.should eq(test_case[:want])
    end
  end
end
