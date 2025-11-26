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
end

class LayoutApp < Application
  def init
    LayoutModel.new
  end

  def options : Array(Term2::ProgramOption)
    [WithAltScreen.new] of Term2::ProgramOption
  end

  def update(msg : Message, model : Model)
    layout = model.as(LayoutModel)

    case msg
    when KeyPress
      case msg.key
      when "q", "\u0003"
        {layout, Cmd.quit}
      when "1"
        {LayoutModel.new(layout.width, layout.height, 0), Cmd.none}
      when "2"
        {LayoutModel.new(layout.width, layout.height, 1), Cmd.none}
      when "3"
        {LayoutModel.new(layout.width, layout.height, 2), Cmd.none}
      when "tab"
        next_pane = (layout.selected_pane + 1) % 3
        {LayoutModel.new(layout.width, layout.height, next_pane), Cmd.none}
      else
        {layout, Cmd.none}
      end
    when WindowSizeMsg
      {LayoutModel.new(msg.width, msg.height, layout.selected_pane), Cmd.none}
    else
      {layout, Cmd.none}
    end
  end

  def view(model : Model) : String
    layout = model.as(LayoutModel)

    # Create the main screen view
    screen = Term2::View.new(0, 0, layout.width, layout.height)

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
      draw_box(io, header, "Layout Demo", layout.selected_pane == 0)

      # Draw sidebar
      draw_box(io, sidebar, "Sidebar", layout.selected_pane == 1)
      draw_content(io, sidebar.padding(1), [
        "Navigation:",
        "• Item 1",
        "• Item 2",
        "• Item 3",
      ])

      # Draw main area
      draw_box(io, main, "Main Content", layout.selected_pane == 2)
      draw_content(io, main.padding(1), [
        "View Layout System",
        "",
        "This demo shows how to:",
        "• Create views with margins",
        "• Split views vertically/horizontally",
        "• Add padding to views",
        "• Draw boxes and content",
        "",
        "Screen: #{layout.width}x#{layout.height}",
        "Selected: Pane #{layout.selected_pane + 1}",
      ])

      # Draw footer (status line)
      io << Cursor.move_to(layout.height, 1)
      io << "[1-3] Select pane | [Tab] Next pane | [q] Quit".gray
    end
  end

  private def draw_box(io : IO, view : Term2::View, title : String, selected : Bool)
    return if view.width < 4 || view.height < 3

    # Top border
    io << Cursor.move_to(view.y + 1, view.x + 1)
    if selected
      io << S.bold.cyan.apply("┌")
    else
      io << "┌".gray
    end
    title_space = view.width - 4
    border_char = selected ? (S.bold.cyan | "─") : "─".gray
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
    io << (selected ? (S.bold.cyan | "┐") : "┐".gray)

    # Side borders (styling for corners already establishes context)
    corner_style = selected ? S.bold.cyan : S.gray
    (1...view.height - 1).each do |row|
      io << Cursor.move_to(view.y + 1 + row, view.x + 1)
      io << (corner_style | "│")
      io << Cursor.move_to(view.y + 1 + row, view.x + view.width)
      io << (corner_style | "│")
    end

    # Bottom border
    io << Cursor.move_to(view.y + view.height, view.x + 1)
    io << (corner_style | "└")
    (view.width - 2).times { io << border_char }
    io << (corner_style | "┘")
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

LayoutApp.new.run

