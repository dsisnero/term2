require "../../../src/term2"
require "../../../src/components/text_input"

module CapabilityExample
  include Term2::Prelude

  class Model
    include Term2::Model

    property input : Term2::Components::TextInput
    property width : Int32 = 0

    def initialize
      @input = Term2::Components::TextInput.new
      @input.placeholder = "Enter capability name to request"
      @input.focus
    end

    def init : Term2::Cmd
      @input.focus
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::WindowSizeMsg
        @width = msg.width
      when Term2::KeyMsg
        case msg.string
        when "ctrl+c", "esc"
          return {self, Term2.quit}
        when "enter"
          input_val = @input.value
          @input.reset
          return {self, Term2::Cmds.request_capability(input_val)}
        end
      when Term2::CapabilityMsg
        return {self, Term2::Cmds.printf("Got capability: %s", msg)}
      end

      @input, cmd = @input.update(msg)
      {self, cmd}
    end

    def view : Term2::View
      w = @width
      w = 60 if w == 0 || w > 60

      instructions = Lipgloss::Style.new
        .width(w)
        .render("Query for terminal capabilities. You can enter things like 'TN', 'RGB', 'cols', and so on. This will not work in all terminals and multiplexers.")

      input_view = @input.view
      input_content = input_view.is_a?(String) ? input_view : input_view.content

      content = "\n" + instructions + "\n\n" +
                input_content +
                "\n\nPress enter to request capability, or ctrl+c to quit."

      Term2::View.new(content: content)
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(CapabilityExample::Model.new)
end
