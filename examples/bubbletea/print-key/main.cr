require "../../../src/term2"

module PrintKeyExample
  include Term2::Prelude

  class Model
    include Term2::Model

    def init : Term2::Cmd
      Term2::Cmds.none
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyboardEnhancementsMsg
        return {self, Term2::Cmds.printf("Keyboard enhancements: EventTypes: %s\n", msg.supports_event_types?.to_s)}
      when Term2::KeyMsg
        if msg.string == "ctrl+c"
          return {self, Term2.quit}
        end

        format = "(%s) You pressed: %s"
        text = msg.key.text
        if !text.empty?
          format += " (text: %s)"
          return {self, Term2::Cmds.printf(format, msg.class.name, msg.string, text.inspect)}
        end
        return {self, Term2::Cmds.printf(format, msg.class.name, msg.string)}
      end

      {self, Term2::Cmds.none}
    end

    def view : Term2::View
      view = Term2::View.new(content: "Press any key to see its details printed to the terminal. Press 'ctrl+c' to quit.")
      view.keyboard_enhancements.report_event_types = true
      view
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(PrintKeyExample::Model.new)
end
