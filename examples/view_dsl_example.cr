# View DSL Example
#
# Run with: crystal run examples/view_dsl_example.cr
require "../src/term2"
include Term2::Prelude

class ViewDSLModel < Model
  getter count : Int32

  def initialize(@count = 0); end
end

class ViewDSLApp < Application(ViewDSLModel)
  def init : ViewDSLModel
    ViewDSLModel.new
  end

  def update(msg : Message, model : ViewDSLModel)
    case msg
    when KeyPress
      case msg.key
      when "q" then {model, Cmd.quit}
      when "+" then {ViewDSLModel.new(model.count + 1), Cmd.none}
      else          {model, Cmd.none}
      end
    else
      {model, Cmd.none}
    end
  end

  def view(model : ViewDSLModel) : String
    Layout.render(80, 24) do
      text "View DSL Demo".bold.underline

      v_stack do
        text "Count: #{model.count}".cyan

        h_stack(gap: 2) do
          text "[+] Increment".on_blue
          text "[q] Quit".on_red
        end
      end

      text "Footer".gray
    end
  end
end

ViewDSLApp.new.run
