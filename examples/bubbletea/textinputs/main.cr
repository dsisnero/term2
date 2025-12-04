require "../../../src/term2"

include Term2::Prelude

class TextinputsModel
  include Term2::Model

  FOCUSED_STYLE          = Term2::Style.new.foreground(Term2::Color.indexed(205))
  BLURRED_STYLE          = Term2::Style.new.foreground(Term2::Color.indexed(240))
  CURSOR_STYLE           = FOCUSED_STYLE
  NO_STYLE               = Term2::Style.new
  HELP_STYLE             = BLURRED_STYLE
  CURSOR_MODE_HELP_STYLE = Term2::Style.new.foreground(Term2::Color.indexed(244))

  FOCUSED_BUTTON = FOCUSED_STYLE.render("[ Submit ]")
  BLURRED_BUTTON = "[ #{BLURRED_STYLE.render("Submit")} ]"

  getter focus_index : Int32
  getter inputs : Array(TC::TextInput)
  getter cursor_mode : TC::Cursor::Mode

  def initialize
    @inputs = [] of TC::TextInput
    @cursor_mode = TC::Cursor::Mode::Blink
    init_inputs
    @focus_index = 0
  end

  def init_inputs
    3.times do |i|
      t = TC::TextInput.new
      t.cursor.style = CURSOR_STYLE
      t.char_limit = 32

      case i
      when 0
        t.placeholder = "Nickname"
        t.focus
        t.prompt_style = FOCUSED_STYLE
        t.text_style = FOCUSED_STYLE
      when 1
        t.placeholder = "Email"
        t.char_limit = 64
      when 2
        t.placeholder = "Password"
        t.echo_mode = TC::TextInput::EchoMode::Password
      end
      @inputs << t
    end
  end

  def init : Term2::Cmd
    Term2::Cmds.message(TC::Cursor::BlinkMsg.new(0))
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "esc"
        return {self, Term2::Cmds.quit}
      when "q"
        return {self, Term2::Cmds.quit}
      when "ctrl+r"
        @cursor_mode = case @cursor_mode
                       when TC::Cursor::Mode::Blink
                         TC::Cursor::Mode::Static
                       when TC::Cursor::Mode::Static
                         TC::Cursor::Mode::Hide
                       else
                         TC::Cursor::Mode::Blink
                       end
        cmds = @inputs.map { |i| i.cursor.mode = @cursor_mode; nil }
        return {self, Term2::Cmds.batch(cmds)}
      when "tab", "shift+tab", "enter", "up", "down"
        s = msg.key.to_s
        if s == "enter" && @focus_index == @inputs.size
          # Only submit if password has been filled
          if !@inputs[2].value.empty?
            return {self, Term2::Cmds.quit}
          end
        end
        if s == "up" || s == "shift+tab"
          @focus_index -= 1
        else
          @focus_index += 1
        end
        if @focus_index > @inputs.size
          @focus_index = 0
        elsif @focus_index < 0
          @focus_index = @inputs.size
        end

        cmds = [] of Term2::Cmd
        @inputs.each_with_index do |input, idx|
          if idx == @focus_index
            cmds << input.focus
            input.prompt_style = FOCUSED_STYLE
            input.text_style = FOCUSED_STYLE
          else
            input.blur
            input.prompt_style = NO_STYLE
            input.text_style = NO_STYLE
          end
        end
        return {self, Term2::Cmds.batch(cmds)}
      end
    end

    cmd = update_inputs(msg)
    {self, cmd}
  end

  def update_inputs(msg : Term2::Msg) : Term2::Cmd
    cmds = [] of Term2::Cmd
    @inputs.each_with_index do |input, i|
      @inputs[i], cmd = input.update(msg)
      cmds << cmd
    end
    Term2::Cmds.batch(cmds)
  end

  def view : String
    b = String.build do |io|
      @inputs.each_with_index do |input, i|
        io << input.view
        io << "\n" if i < @inputs.size - 1
      end
      button = @focus_index == @inputs.size ? FOCUSED_BUTTON : BLURRED_BUTTON
      io << "\n\n#{button}\n\n"
      io << HELP_STYLE.render("cursor mode is ")
      io << CURSOR_MODE_HELP_STYLE.render(@cursor_mode.to_s)
      io << HELP_STYLE.render(" (ctrl+r to change style)")
    end
    b
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(TextinputsModel.new)
end
