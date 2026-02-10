require "../spec_helper"
require "../../src/components/text_area"

class Term2::Components::TextArea
  def cursor_line_number_for_spec : Int32
    cursor_line_number
  end
end

def new_text_area : Term2::Components::TextArea
  textarea = Term2::Components::TextArea.new
  textarea.prompt = "> "
  textarea.placeholder = "Hello, World!"
  textarea.focus
  textarea
end

def send_string(textarea : Term2::Components::TextArea, str : String) : Term2::Components::TextArea
  str.each_char do |ch|
    if ch == '\n'
      textarea, _ = textarea.update(Term2::TestHelpers.key_msg("enter"))
    else
      textarea, _ = textarea.update(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key(ch)))
    end
    textarea.view.content
  end
  textarea
end

def strip_string(str : String) : String
  stripped = Lipgloss::Text.strip_ansi(str)
  lines = stripped.split("\n")
  trimmed = lines.map(&.rstrip).reject(&.empty?)
  trimmed.join("\n")
end

def view_lines(*lines : String) : String
  lines.join("\n")
end

describe Term2::Components::TextArea do
  it "matches bubbletea view cases" do
    cases = [
      {
        name: "placeholder",
        model: ->(m : Term2::Components::TextArea) { m },
        view: view_lines(
          ">   1 Hello, World!",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "single line",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line"
          m
        },
        view: view_lines(
          ">   1 the first line",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 14,
      },
      {
        name: "multiple lines",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line\nthe second line\nthe third line"
          m
        },
        view: view_lines(
          ">   1 the first line",
          ">   2 the second line",
          ">   3 the third line",
          ">",
          ">",
          ">",
        ),
        cursor_row: 2,
        cursor_col: 14,
      },
      {
        name: "single line without line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line"
          m.show_line_numbers = false
          m
        },
        view: view_lines(
          "> the first line",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 14,
      },
      {
        name: "multipline lines without line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line\nthe second line\nthe third line"
          m.show_line_numbers = false
          m
        },
        view: view_lines(
          "> the first line",
          "> the second line",
          "> the third line",
          ">",
          ">",
          ">",
        ),
        cursor_row: 2,
        cursor_col: 14,
      },
      {
        name: "single line and custom end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line"
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          ">   1 the first line",
          "> *",
          "> *",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 14,
      },
      {
        name: "multiple lines and custom end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line\nthe second line\nthe third line"
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          ">   1 the first line",
          ">   2 the second line",
          ">   3 the third line",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 2,
        cursor_col: 14,
      },
      {
        name: "single line without line numbers and custom end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line"
          m.show_line_numbers = false
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          "> the first line",
          "> *",
          "> *",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 14,
      },
      {
        name: "multiple lines without line numbers and custom end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line\nthe second line\nthe third line"
          m.show_line_numbers = false
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          "> the first line",
          "> the second line",
          "> the third line",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 2,
        cursor_col: 14,
      },
      {
        name: "single line and custom prompt",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line"
          m.prompt = "* "
          m
        },
        view: view_lines(
          "*   1 the first line",
          "*",
          "*",
          "*",
          "*",
          "*",
        ),
        cursor_row: 0,
        cursor_col: 14,
      },
      {
        name: "multiple lines and custom prompt",
        model: ->(m : Term2::Components::TextArea) {
          m.value = "the first line\nthe second line\nthe third line"
          m.prompt = "* "
          m
        },
        view: view_lines(
          "*   1 the first line",
          "*   2 the second line",
          "*   3 the third line",
          "*",
          "*",
          "*",
        ),
        cursor_row: 2,
        cursor_col: 14,
      },
      {
        name: "type single line",
        model: ->(m : Term2::Components::TextArea) {
          send_string(m, "foo")
        },
        view: view_lines(
          ">   1 foo",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 3,
      },
      {
        name: "type multiple lines",
        model: ->(m : Term2::Components::TextArea) {
          send_string(m, "foo\nbar\nbaz")
        },
        view: view_lines(
          ">   1 foo",
          ">   2 bar",
          ">   3 baz",
          ">",
          ">",
          ">",
        ),
        cursor_row: 2,
        cursor_col: 3,
      },
      {
        name: "softwrap",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.prompt = ""
          m.set_width(5)
          send_string(m, "foo bar baz")
        },
        view: view_lines(
          "foo",
          "bar",
          "baz",
          "",
          "",
          "",
        ),
        cursor_row: 2,
        cursor_col: 3,
      },
      {
        name: "single line character limit",
        model: ->(m : Term2::Components::TextArea) {
          m.char_limit = 7
          send_string(m, "foo bar baz")
        },
        view: view_lines(
          ">   1 foo bar",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 7,
      },
      {
        name: "multiple lines character limit",
        model: ->(m : Term2::Components::TextArea) {
          m.char_limit = 19
          send_string(m, "foo bar baz\nfoo bar baz")
        },
        view: view_lines(
          ">   1 foo bar baz",
          ">   2 foo bar",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 7,
      },
      {
        name: "set width",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(10)
          send_string(m, "12")
        },
        view: view_lines(
          ">   1 12",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 2,
      },
      {
        name: "set width max length text minus one",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(10)
          send_string(m, "123")
        },
        view: view_lines(
          ">   1 123",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 3,
      },
      {
        name: "set width max length text",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(10)
          send_string(m, "1234")
        },
        view: view_lines(
          ">   1 1234",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 0,
      },
      {
        name: "set width max length text plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(10)
          send_string(m, "12345")
        },
        view: view_lines(
          ">   1 1234",
          ">     5",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "set width set max width minus one",
        model: ->(m : Term2::Components::TextArea) {
          m.max_width = 10
          m.set_width(11)
          send_string(m, "123")
        },
        view: view_lines(
          ">   1 123",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 3,
      },
      {
        name: "set width set max width",
        model: ->(m : Term2::Components::TextArea) {
          m.max_width = 10
          m.set_width(11)
          send_string(m, "1234")
        },
        view: view_lines(
          ">   1 1234",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 0,
      },
      {
        name: "set width set max width plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.max_width = 10
          m.set_width(11)
          send_string(m, "12345")
        },
        view: view_lines(
          ">   1 1234",
          ">     5",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "set width min width minus one",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(6)
          send_string(m, "123")
        },
        view: view_lines(
          ">   1 1",
          ">     2",
          ">     3",
          ">",
          ">",
          ">",
        ),
        cursor_row: 3,
        cursor_col: 0,
      },
      {
        name: "set width min width",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(7)
          send_string(m, "123")
        },
        view: view_lines(
          ">   1 1",
          ">     2",
          ">     3",
          ">",
          ">",
          ">",
        ),
        cursor_row: 3,
        cursor_col: 0,
      },
      {
        name: "set width min width no line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.set_width(0)
          send_string(m, "123")
        },
        view: view_lines(
          "> 1",
          "> 2",
          "> 3",
          ">",
          ">",
          ">",
        ),
        cursor_row: 3,
        cursor_col: 0,
      },
      {
        name: "set width min width no line numbers no prompt",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.prompt = ""
          m.set_width(0)
          send_string(m, "123")
        },
        view: view_lines(
          "1",
          "2",
          "3",
          "",
          "",
          "",
        ),
        cursor_row: 3,
        cursor_col: 0,
      },
      {
        name: "set width min width plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(8)
          send_string(m, "123")
        },
        view: view_lines(
          ">   1 12",
          ">     3",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "set width without line numbers max length text minus one",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.set_width(6)
          send_string(m, "123")
        },
        view: view_lines(
          "> 123",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 3,
      },
      {
        name: "set width without line numbers max length text",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.set_width(6)
          send_string(m, "1234")
        },
        view: view_lines(
          "> 1234",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 0,
      },
      {
        name: "set width without line numbers max length text plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = false
          m.set_width(6)
          send_string(m, "12345")
        },
        view: view_lines(
          "> 1234",
          "> 5",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "set width with style",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.set_width(12)
          send_string(m, "1")
        },
        view: view_lines(
          "┌──────────┐",
          "│>   1 1   │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 0,
        cursor_col: 1,
      },
      {
        name: "set width with style max width minus one",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.set_width(12)
          send_string(m, "123")
        },
        view: view_lines(
          "┌──────────┐",
          "│>   1 123 │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 0,
        cursor_col: 3,
      },
      {
        name: "set width with style max width",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.set_width(12)
          send_string(m, "1234")
        },
        view: view_lines(
          "┌──────────┐",
          "│>   1 1234│",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 1,
        cursor_col: 0,
      },
      {
        name: "set width with style max width plus one",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.set_width(12)
          send_string(m, "12345")
        },
        view: view_lines(
          "┌──────────┐",
          "│>   1 1234│",
          "│>     5   │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "set width without line numbers with style",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.show_line_numbers = false
          m.set_width(12)
          send_string(m, "123456")
        },
        view: view_lines(
          "┌──────────┐",
          "│> 123456  │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 0,
        cursor_col: 6,
      },
      {
        name: "set width without line numbers with style max width minus one",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.show_line_numbers = false
          m.set_width(12)
          send_string(m, "1234567")
        },
        view: view_lines(
          "┌──────────┐",
          "│> 1234567 │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 0,
        cursor_col: 7,
      },
      {
        name: "set width without line numbers with style max width",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.show_line_numbers = false
          m.set_width(12)
          send_string(m, "12345678")
        },
        view: view_lines(
          "┌──────────┐",
          "│> 12345678│",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 1,
        cursor_col: 0,
      },
      {
        name: "set width without line numbers with style max width plus one",
        model: ->(m : Term2::Components::TextArea) {
          styles = m.styles
          styles.focused.base = Lipgloss::Style.new.border(Lipgloss::Border.normal)
          m.styles = styles
          m.focus
          m.show_line_numbers = false
          m.set_width(12)
          send_string(m, "123456789")
        },
        view: view_lines(
          "┌──────────┐",
          "│> 12345678│",
          "│> 9       │",
          "│>         │",
          "│>         │",
          "│>         │",
          "│>         │",
          "└──────────┘",
        ),
        cursor_row: 1,
        cursor_col: 1,
      },
      {
        name: "placeholder min width",
        model: ->(m : Term2::Components::TextArea) {
          m.set_width(0)
          m
        },
        view: view_lines(
          ">   1 H",
          ">     e",
          ">     l",
          ">     l",
          ">     o",
          ">     ,",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line"
          m.show_line_numbers = false
          m
        },
        view: view_lines(
          "> placeholder the first line",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
          m.show_line_numbers = false
          m
        },
        view: view_lines(
          "> placeholder the first line",
          "> placeholder the second line",
          "> placeholder the third line",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line with line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line"
          m.show_line_numbers = true
          m
        },
        view: view_lines(
          ">   1 placeholder the first line",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines with line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
          m.show_line_numbers = true
          m
        },
        view: view_lines(
          ">   1 placeholder the first line",
          ">     placeholder the second line",
          ">     placeholder the third line",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line with end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line"
          m.show_line_numbers = false
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          "> placeholder the first line",
          "> *",
          "> *",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines with with end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
          m.show_line_numbers = false
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          "> placeholder the first line",
          "> placeholder the second line",
          "> placeholder the third line",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line with line numbers and end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line"
          m.show_line_numbers = true
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          ">   1 placeholder the first line",
          "> *",
          "> *",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines with line numbers and end of buffer character",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line\nplaceholder the second line\nplaceholder the third line"
          m.show_line_numbers = true
          m.end_of_buffer_char = "*"
          m
        },
        view: view_lines(
          ">   1 placeholder the first line",
          ">     placeholder the second line",
          ">     placeholder the third line",
          "> *",
          "> *",
          "> *",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line that is longer than the max width"
          m.set_width(40)
          m.show_line_numbers = false
          m
        },
        view: view_lines(
          "> placeholder the first line that is",
          "> longer than the max width",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line that is longer than the max width\nplaceholder the second line that is longer than the max width"
          m.show_line_numbers = false
          m.set_width(40)
          m
        },
        view: view_lines(
          "> placeholder the first line that is",
          "> longer than the max width",
          "> placeholder the second line that is",
          "> longer than the max width",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width with line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line that is longer than the max width"
          m.show_line_numbers = true
          m.set_width(40)
          m
        },
        view: view_lines(
          ">   1 placeholder the first line that is",
          ">     longer than the max width",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width with line numbers",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "placeholder the first line that is longer than the max width\nplaceholder the second line that is longer than the max width"
          m.show_line_numbers = true
          m.set_width(40)
          m
        },
        view: view_lines(
          ">   1 placeholder the first line that is",
          ">     longer than the max width",
          ">     placeholder the second line that",
          ">     is longer than the max width",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width at limit",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "123456789012345678"
          m.show_line_numbers = false
          m.set_width(20)
          m
        },
        view: view_lines(
          "> 123456789012345678",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width at limit plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "1234567890123456789"
          m.show_line_numbers = false
          m.set_width(20)
          m
        },
        view: view_lines(
          "> 123456789012345678",
          "> 9",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width with line numbers at limit",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "12345678901234"
          m.show_line_numbers = true
          m.set_width(20)
          m
        },
        view: view_lines(
          ">   1 12345678901234",
          ">",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder single line that is longer than max width with line numbers at limit plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "123456789012345"
          m.show_line_numbers = true
          m.set_width(20)
          m
        },
        view: view_lines(
          ">   1 12345678901234",
          ">     5",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width at limit",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "123456789012345678\n123456789012345678"
          m.show_line_numbers = false
          m.set_width(20)
          m
        },
        view: view_lines(
          "> 123456789012345678",
          "> 123456789012345678",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width at limit plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "1234567890123456789\n1234567890123456789"
          m.show_line_numbers = false
          m.set_width(20)
          m
        },
        view: view_lines(
          "> 123456789012345678",
          "> 9",
          "> 123456789012345678",
          "> 9",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width with line numbers at limit",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "12345678901234\n12345678901234"
          m.show_line_numbers = true
          m.set_width(20)
          m
        },
        view: view_lines(
          ">   1 12345678901234",
          ">     12345678901234",
          ">",
          ">",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder multiple lines that are longer than max width with line numbers at limit plus one",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "123456789012345\n123456789012345"
          m.show_line_numbers = true
          m.set_width(20)
          m
        },
        view: view_lines(
          ">   1 12345678901234",
          ">     5",
          ">     12345678901234",
          ">     5",
          ">",
          ">",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "placeholder chinese character",
        model: ->(m : Term2::Components::TextArea) {
          m.placeholder = "输入消息..."
          m.show_line_numbers = true
          m.set_width(20)
          m
        },
        view: view_lines(
          ">   1 输入消息...",
          ">",
          ">",
          ">",
          ">",
          ">",
          "",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "page up moves to beginning when near top",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = true
          m.set_height(4)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 3
          m.cursor_col = 0
          m.viewport.y_offset = 0

          m, _ = m.update(Term2::TestHelpers.key_msg("pgup"))
          m
        },
        view: view_lines(
          ">   1 Line 1",
          ">   2 Line 2",
          ">   3 Line 3",
          ">   4 Line 4",
        ),
        cursor_row: 0,
        cursor_col: 0,
      },
      {
        name: "page up snaps to first visible line when not on it",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = true
          m.set_height(4)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 5
          m.cursor_col = 0
          m.viewport.y_offset = 3

          m, _ = m.update(Term2::TestHelpers.key_msg("pgup"))
          m
        },
        view: view_lines(
          ">   4 Line 4",
          ">   5 Line 5",
          ">   6 Line 6",
          ">   7 Line 7",
        ),
        cursor_row: 3,
        cursor_col: 0,
      },
      {
        name: "page up moves up by full page when on first visible line",
        model: ->(m : Term2::Components::TextArea) {
          m.show_line_numbers = true
          m.set_height(3)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 5
          m.cursor_col = 0
          m.viewport.y_offset = 5

          m, _ = m.update(Term2::TestHelpers.key_msg("pgup"))
          m
        },
        view: view_lines(
          ">   3 Line 3",
          ">   4 Line 4",
          ">   5 Line 5",
        ),
        cursor_row: 2,
        cursor_col: 0,
      },
      {
        name: "page down moves to end when near bottom",
        model: ->(m : Term2::Components::TextArea) {
          m.set_height(3)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 8
          m.cursor_col = 0
          m.viewport.y_offset = 7

          m, _ = m.update(Term2::TestHelpers.key_msg("pgdown"))
          m
        },
        view: view_lines(
          ">   8 Line 8",
          ">   9 Line 9",
          ">  10 Line 10",
        ),
        cursor_row: 9,
        cursor_col: 0,
      },
      {
        name: "page down snaps to last visible line when not on it",
        model: ->(m : Term2::Components::TextArea) {
          m.set_height(3)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 3
          m.cursor_col = 0
          m.viewport.y_offset = 3

          m, _ = m.update(Term2::TestHelpers.key_msg("pgdown"))
          m
        },
        view: view_lines(
          ">   4 Line 4",
          ">   5 Line 5",
          ">   6 Line 6",
        ),
        cursor_row: 5,
        cursor_col: 0,
      },
      {
        name: "page down moves down by full page when on last visible line",
        model: ->(m : Term2::Components::TextArea) {
          m.set_height(3)
          m.set_width(20)

          lines = Array(String).new(10) { |i| "Line #{i + 1}" }
          m.value = lines.join("\n")
          m.viewport.content = m.view.content

          m.cursor_line = 4
          m.cursor_col = 0
          m.viewport.y_offset = 2

          m, _ = m.update(Term2::TestHelpers.key_msg("pgdown"))
          m
        },
        view: view_lines(
          ">   6 Line 6",
          ">   7 Line 7",
          ">   8 Line 8",
        ),
        cursor_row: 7,
        cursor_col: 0,
      },
    ]

    cases.each do |test_case|
      textarea = new_text_area
      textarea = test_case[:model].call(textarea)

      view = strip_string(textarea.view.content)
      want_view = strip_string(test_case[:view])
      view.should eq(want_view)

      cursor_row = textarea.cursor_line_number_for_spec
      cursor_col = textarea.line_info.column_offset
      cursor_row.should eq(test_case[:cursor_row])
      cursor_col.should eq(test_case[:cursor_col])
    end
  end
end
