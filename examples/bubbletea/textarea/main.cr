require "../../../src/term2"

include Term2::Prelude

class TextareaExampleModel
  include Term2::Model

  getter textarea : TC::TextArea
  getter err : Exception?

  def initialize
    ti = TC::TextArea.new
    ti.placeholder = "Once upon a time..."
    ti.focus
    @textarea = ti
    @err = nil
  end

  def init : Term2::Cmd
    @textarea.cursor.blink_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    cmds = [] of Term2::Cmd
    case msg
    when Term2::KeyMsg
      case msg.key.type
      when Term2::KeyType::Esc
        if @textarea.focused?
          @textarea.blur
        end
      when Term2::KeyType::CtrlC
        return {self, Term2::Cmds.quit}
      else
        cmds << @textarea.focus unless @textarea.focused?
      end
    when Term2::KeyPress # legacy keypress for simple chars
      cmds << @textarea.focus unless @textarea.focused?
    end

    @textarea, cmd = @textarea.update(msg)
    cmds << cmd
    {self, Term2::Cmds.batch(cmds)}
  end

  def view : String
    "Tell me a story.\n\n#{@textarea.view}\n\n(ctrl+c to quit)\n\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TextareaExampleModel.new)
end
