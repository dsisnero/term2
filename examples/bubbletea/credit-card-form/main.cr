require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

enum Field
  CCN
  EXP
  CVV
end

HOT_PINK = Term2::Color.new(Term2::Color::Type::RGB, {255, 6, 183})
DARK_GRAY = Term2::Color.new(Term2::Color::Type::RGB, {118, 118, 118})

INPUT_STYLE = Term2::Style.new.foreground(HOT_PINK)
CONTINUE_STYLE = Term2::Style.new.foreground(DARK_GRAY)

class CreditCardModel
  include Term2::Model

  getter inputs : Array(TC::TextInput)
  getter focused : Int32
  getter error : Exception?

  def initialize
    @inputs = Array(TC::TextInput).new(3) { TC::TextInput.new }
    @inputs = Array(TC::TextInput).new(3) { TC::TextInput.new }
    setup_inputs
    @focused = 0
    @error = nil
  end

  def init : Term2::Cmd
    TC::Cursor::BlinkMsg # dummy to ensure module load
    TC::TextInput.new.blink
    TC::Cursor.new.focus_cmd
    Term2::Cmds.batch(@inputs.first.focus, @inputs.first.cursor.blink_cmd)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    cmds = [] of Term2::Cmd

    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "enter"
        if @focused == @inputs.size - 1
          return {self, Term2::Cmds.quit}
        end
        next_input
      when "ctrl+c", "esc"
        return {self, Term2::Cmds.quit}
      when "shift+tab", "ctrl+p"
        prev_input
      when "tab", "ctrl+n"
        next_input
      end

      @inputs.each(&.blur)
      cmds << @inputs[@focused].focus
    end

    @inputs.each_with_index do |input, idx|
      new_input, cmd = input.update(msg)
      @inputs[idx] = new_input
      cmds << cmd if cmd
    end

    {self, Term2::Cmds.batch(cmds.compact)}
  end

  def view : String
    String.build do |str|
      str << "Total: $21.50:\n\n"
      str << INPUT_STYLE.width(30).render("Card Number") << "\n"
      str << @inputs[Field::CCN.value].view << "\n\n"
      str << INPUT_STYLE.width(6).render("EXP") << "  " << INPUT_STYLE.width(6).render("CVV") << "\n"
      str << @inputs[Field::EXP.value].view << "  " << @inputs[Field::CVV.value].view << "\n\n"
      str << CONTINUE_STYLE.render("Continue ->") << "\n\n"
    end
  end

  private def setup_inputs
    # CCN
    @inputs[Field::CCN.value].placeholder = "4505 **** **** 1234"
    @inputs[Field::CCN.value].char_limit = 20
    @inputs[Field::CCN.value].width = 30
    @inputs[Field::CCN.value].prompt = ""
    @inputs[Field::CCN.value].validate = ->(s : String) { ccn_validator(s) }

    # EXP
    @inputs[Field::EXP.value].placeholder = "MM/YY"
    @inputs[Field::EXP.value].char_limit = 5
    @inputs[Field::EXP.value].width = 5
    @inputs[Field::EXP.value].prompt = ""
    @inputs[Field::EXP.value].validate = ->(s : String) { exp_validator(s) }

    # CVV
    @inputs[Field::CVV.value].placeholder = "XXX"
    @inputs[Field::CVV.value].char_limit = 3
    @inputs[Field::CVV.value].width = 5
    @inputs[Field::CVV.value].prompt = ""
    @inputs[Field::CVV.value].validate = ->(s : String) { cvv_validator(s) }

    @inputs[Field::CCN.value].focus
  end

  private def next_input
    @focused = (@focused + 1) % @inputs.size
  end

  private def prev_input
    @focused -= 1
    @focused = @inputs.size - 1 if @focused < 0
  end

  private def ccn_validator(s : String) : Bool
    return false if s.size > 19
    return true if s.empty?
    if s.size % 5 != 0 && (s[-1]? && !(s[-1] >= '0' && s[-1] <= '9'))
      return false
    end
    if s.size % 5 == 0 && s[-1]? != ' '
      return false
    end
    digits = s.gsub(" ", "")
    digits.each_char do |ch|
      return false unless ch >= '0' && ch <= '9'
    end
    true
  end

  private def exp_validator(s : String) : Bool
    return true if s.empty?
    stripped = s.gsub("/", "")
    return false unless stripped.each_char.all? { |ch| ch >= '0' && ch <= '9' }
    if s.size >= 3 && (s.index("/") != 2 || s.rindex("/") != 2)
      return false
    end
    true
  end

  private def cvv_validator(s : String) : Bool
    return true if s.empty?
    return false unless s.size <= 3 && s.each_char.all? { |ch| ch >= '0' && ch <= '9' }
    true
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(CreditCardModel.new)
end
