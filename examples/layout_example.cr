# Layout Example
#
# This example demonstrates the View layout system for creating
# structured terminal UIs with splits, margins, and centering.
#
# Run with: crystal run examples/layout_example.cr
require "../src/term2"
include Term2::Prelude

class LayoutModel < Model
  getter width : Int32
  getter height : Int32
  getter selected_pane : Int32

  def initialize(@width : Int32 = 80, @height : Int32 = 24, @selected_pane : Int32 = 0)
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "1"
        {LayoutModel.new(@width, @height, 0), Cmd.none}
      when "2"
        {LayoutModel.new(@width, @height, 1), Cmd.none}
      when "3"
        {LayoutModel.new(@width, @height, 2), Cmd.none}
      when "tab"
        next_pane = (@selected_pane + 1) % 3
        {LayoutModel.new(@width, @height, next_pane), Cmd.none}
      else
        {self, Cmd.none}
      end
    when WindowSizeMsg
      {LayoutModel.new(msg.width, msg.height, @selected_pane), Cmd.none}
    else
      {self, Cmd.none}
    end
  end

  def view : String
    # Create the main screen view
    screen = Term2::View.new(0, 0, @width, @height)

    # Add 1-cell margin around edges
    content = screen.margin(top: 1, bottom: 2, left: 2, right: 2)

    # Split content: header (3 rows) + body
    header, body = content.split_vertical(3.0 / content.height)

    # Split body into sidebar (30%) and main (70%)
    sidebar, main = body.split_horizontal(0.3)

    String.build do |io|
      # Note: Framework handles cursor hide, clear screen, etc.
      # View just returns content to display.

      # Draw header
      draw_box(io, header, "Layout Demo", @selected_pane == 0)

      # Draw sidebar
      draw_box(io, sidebar, "Sidebar", @selected_pane == 1)
      draw_content(io, sidebar.padding(1), [
        "Navigation:",
        "• Item 1",
        "• Item 2",
        "• Item 3",
      ])

      # Draw main area
      draw_box(io, main, "Main Content", @selected_pane == 2)
      draw_content(io, main.padding(1), [
        "View Layout System",
        "",
        "This demo shows how to:",
        "• Create views with margins",
        "• Split views vertically/horizontally",
        "• Add padding to views",
        "• Draw boxes and content",
        "",
        "Screen: #{@width}x#{@height}",
        "Selected: Pane #{@selected_pane + 1}",
      ])

      # Draw footer (status line)
      io << Cursor.move_to(@height, 1)
      io << "[1-3] Select pane | [Tab] Next pane | [q] Quit".gray
    end
  end

  private def draw_box(io : IO, view : Term2::View, title : String, selected : Bool)
    return if view.width < 4 || view.height < 3

    # Top border
    io << Cursor.move_to(view.y + 1, view.x + 1)
    if selected
      io << "┌".bold.cyan
    else
      io << "┌".gray
    end
    title_space = view.width - 4
    border_char = selected ? "─".bold.cyan : "─".gray
    if title.size <= title_space
      padding = title_space - title.size
      left_pad = padding // 2
      right_pad = padding - left_pad
      (left_pad).times { io << border_char }
      io << " " << title << " "
      (right_pad).times { io << border_char }
    else
      (view.width - 2).times { io << border_char }
    end
    io << (selected ? "┐".bold.cyan : "┐".gray)

    # Side borders (styling for corners already establishes context)
    corner_style = selected ? S.bold.cyan : S.gray
    (1...view.height - 1).each do |row|
      io << Cursor.move_to(view.y + 1 + row, view.x + 1)
      io << corner_style.apply("│")
      io << Cursor.move_to(view.y + 1 + row, view.x + view.width)
      io << corner_style.apply("│")
    end

    # Bottom border
    io << Cursor.move_to(view.y + view.height, view.x + 1)
    io << corner_style.apply("└")
    (view.width - 2).times { io << border_char }
    io << corner_style.apply("┘")
  end

  private def draw_content(io : IO, view : Term2::View, lines : Array(String))
    lines.each_with_index do |line, idx|
      break if idx >= view.height
      io << Cursor.move_to(view.y + 1 + idx, view.x + 1)
      truncated = line.size > view.width ? line[0...view.width] : line
      io << truncated
    end
  end
end

Term2.run(LayoutModel.new, options: Term2::ProgramOptions.new(WithAltScreen.new))
