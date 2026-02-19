require "../../../src/term2"
require "../../../src/logging"

include Term2::Prelude

class AltScreenModel
  include Term2::Model

  KEYWORD_STYLE = Lipgloss::Style.new
    .foreground(Lipgloss::Color.indexed(204))
    .background(Lipgloss::Color.indexed(235))

  HELP_STYLE = Lipgloss::Style.new
    .foreground(Lipgloss::Color.indexed(241))

  property? altscreen : Bool = false
  property? quitting : Bool = false
  property? suspending : Bool = false

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.string
      when "q", "ctrl+c", "esc"
        @quitting = true
        return {self, Term2::Cmds.quit}
      when "ctrl+z"
        @suspending = true
        return {self, Term2::Cmds.suspend}
      when " ", "space"
        cmd = @altscreen ? Term2::Cmds.exit_alt_screen : Term2::Cmds.enter_alt_screen
        @altscreen = !@altscreen
        return {self, cmd}
      end
    when Term2::ResumeMsg
      @suspending = false
      return {self, Term2::Cmds.none}
    end

    {self, Term2::Cmds.none}
  end

  def view : String
    return "" if quitting? || suspending?

    mode = @altscreen ? " altscreen mode " : " inline mode "
    String.build do |io|
      io << "\n\n  You're in "
      io << KEYWORD_STYLE.render(mode)
      io << "\n\n\n"
      io << HELP_STYLE.render("  space: switch modes • ctrl-z: suspend • q: exit")
      io << "\n"
    end
  end
end

# Enable env-configured logging if desired (LOG_LEVEL, LOG_OUTPUT)
unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.setup_logging_from_env
  Term2.run(AltScreenModel.new)
end
