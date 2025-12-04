require "../../../src/term2"
require "../../../src/logging"

include Term2::Prelude

class AltScreenModel
  include Model

  KEYWORD_STYLE = Term2::Style.new
    .foreground(Term2::Color.indexed(204))
    .background(Term2::Color.indexed(235))

  HELP_STYLE = Term2::Style.new
    .foreground(Term2::Color.indexed(241))

  property? altscreen : Bool = false
  property? quitting : Bool = false
  property? suspending : Bool = false

  def init : Cmd
    Term2::Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c", "esc"
        @quitting = true
        return {self, Term2.quit}
      when "ctrl+z"
        @suspending = true
        return {self, Cmds.suspend}
      when " "
        cmd = @altscreen ? Cmds.exit_alt_screen : Cmds.enter_alt_screen
        @altscreen = !@altscreen
        return {self, cmd}
      end
    when Term2::ResumeMsg
      @suspending = false
      return {self, Cmds.none}
    end

    {self, Cmds.none}
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
Term2.setup_logging_from_env
Term2.run(AltScreenModel.new)
