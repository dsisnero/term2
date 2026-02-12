require "../../../src/term2"

module KeyboardEnhancementsExample
  include Term2::Prelude

  class Model
    include Term2::Model

    property supports_disambiguation : Bool = false
    property supports_event_types : Bool = false

    def init : Term2::Cmd
      Term2::Cmds.request_background_color
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyboardEnhancementsMsg
        @supports_disambiguation = true
        @supports_event_types = msg.supports_event_types?
      when Term2::KeyMsg
        if msg.string == "ctrl+c"
          return {self, Term2.quit}
        end
        return {self, Term2::Cmds.println("  press: #{msg.string}")}
      when Term2::BackgroundColorMsg
        # styles would be updated here in Go; no-op for rendering parity
      when Term2::KeyReleaseMsg
        return {self, Term2::Cmds.printf("release: %s", msg.string)}
      end

      {self, Term2::Cmds.none}
    end

    def view : Term2::View
      content = String.build do |io|
        io << "Terminal supports key releases: #{@supports_event_types}\n"
        io << "Terminal supports key disambiguation: #{@supports_disambiguation}\n"
        io << "This demo logs key events. Press ctrl+c to quit."
      end

      view = Term2::View.new(content: content + "\n")
      view.keyboard_enhancements.report_event_types = true
      view
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(KeyboardEnhancementsExample::Model.new)
end
