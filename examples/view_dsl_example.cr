# View DSL Example
#
# Run with: crystal run examples/view_dsl_example.cr
require "../src/term2"
include Term2::Prelude

class ViewDSLModel < Model
  getter count : Int32

  def initialize(@count = 0); end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q" then {self, Term2.quit}
      when "+" then {ViewDSLModel.new(@count + 1), Cmd.none}
      else          {self, Cmd.none}
      end
    else
      {self, Cmd.none}
    end
  end

  def view : String
    Layout.render(80, 24) do
      text "View DSL Demo".bold.underline

      v_stack do
        text "Count: #{@count}".cyan

        h_stack(gap: 2) do
          text "[+] Increment".on_blue
          text "[q] Quit".on_red
        end
      end

      text "Footer".gray
    end
  end
end

Term2.run(ViewDSLModel.new)
