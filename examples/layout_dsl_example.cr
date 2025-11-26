# Layout DSL Example
#
# Recreating the layout_example.cr using the new Layout DSL.
#
# Run with: crystal run examples/layout_dsl_example.cr
require "../src/term2"
include Term2::Prelude

class LayoutDSLModel < Model
  getter width : Int32
  getter height : Int32
  getter selected_pane : Int32

  def initialize(@width : Int32 = 80, @height : Int32 = 24, @selected_pane : Int32 = 0)
  end
end

class LayoutDSLApp < Application(LayoutDSLModel)
  def init : LayoutDSLModel
    LayoutDSLModel.new
  end

  def options : Array(Term2::ProgramOption)
    [WithAltScreen.new] of Term2::ProgramOption
  end

  def update(msg : Message, model : LayoutDSLModel)
    case msg
    when KeyPress
      case msg.key
      when "q", "\u0003"
        {model, Cmd.quit}
      when "1"
        {LayoutDSLModel.new(model.width, model.height, 0), Cmd.none}
      when "2"
        {LayoutDSLModel.new(model.width, model.height, 1), Cmd.none}
      when "3"
        {LayoutDSLModel.new(model.width, model.height, 2), Cmd.none}
      when "tab"
        next_pane = (model.selected_pane + 1) % 3
        {LayoutDSLModel.new(model.width, model.height, next_pane), Cmd.none}
      else
        {model, Cmd.none}
      end
    when WindowSizeMsg
      {LayoutDSLModel.new(msg.width, msg.height, model.selected_pane), Cmd.none}
    else
      {model, Cmd.none}
    end
  end

  def view(model : LayoutDSLModel) : String
    Layout.render(model.width, model.height) do
      # Main container with margin
      padding(1, flex: 1) do
        # Header (Fixed height)
        border("Layout Demo", active: model.selected_pane == 0) do
          text "Header Content"
        end

        # Body (Flexible height)
        h_stack(flex: 1) do
          # Sidebar (30% approx - using flex weights)
          border("Sidebar", active: model.selected_pane == 1, flex: 3) do
            padding(1) do
              text "Navigation:"
              text "• Item 1"
              text "• Item 2"
              text "• Item 3"
            end
          end

          # Main Content (70% approx)
          border("Main Content", active: model.selected_pane == 2, flex: 7) do
            padding(1) do
              text "View Layout System"
              text ""
              text "This demo shows how to:"
              text "• Create views with margins"
              text "• Split views vertically/horizontally"
              text "• Add padding to views"
              text "• Draw boxes and content"
              text ""
              text "Screen: #{model.width}x#{model.height}"
              text "Selected: Pane #{model.selected_pane + 1}"
            end
          end
        end

        # Footer
        text "[1-3] Select pane | [Tab] Next pane | [q] Quit".gray
      end
    end
  end
end

LayoutDSLApp.new.run
