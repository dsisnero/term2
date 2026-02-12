require "../../../src/term2"

module ColorProfileExample
  include Term2::Prelude

  class Model
    include Term2::Model

    def init : Term2::Cmd
      Term2::Cmds.batch(
        Term2::Cmds.request_capability("RGB"),
        Term2::Cmds.request_capability("Tc"),
      )
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        return {self, Term2.quit}
      when Term2::ColorProfileMsg
        return {self, Term2::Cmds.println("Color profile manually set to #{msg.profile}")}
      end
      {self, Term2::Cmds.none}
    end

    def view : Term2::View
      fancy = Lipgloss::Style.new
        .foreground(Lipgloss::Color.hex("#6b50ff"))
        .render("Howdy!")

      content = "This will produce the wrong colors on Apple Terminal :)\n\n" +
                fancy +
                "\n\n" +
                "Press any key to exit."

      Term2::View.new(content: content)
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ColorProfileExample::Model.new, options: Term2::ProgramOptions.new(Term2::WithColorProfile.new(Lipgloss::ColorProfile::TrueColor)))
end
