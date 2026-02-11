require "../../../src/term2"
require "../../../src/components/text_input"

module SetTerminalColorExample
  include Term2::Prelude

  enum ColorChoice
    None
    Foreground
    Background
    Cursor
  end

  enum State
    Choose
    Input
  end

  class Model
    include Term2::Model

    property ti : Term2::Components::TextInput
    property choice : ColorChoice = ColorChoice::None
    property state : State = State::Choose
    property choice_index : Int32 = 0
    property err : String? = nil
    property fg : Lipgloss::Color? = nil
    property bg : Lipgloss::Color? = nil
    property cc : Lipgloss::Color? = nil

    def initialize
      @ti = Term2::Components::TextInput.new
      @ti.placeholder = "#ff00ff"
      @ti.char_limit = 156
      @ti.width = 20
      @ti.blur
    end

    def init : Term2::Cmd
      Term2::Components::TextInput.blink
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        case msg.string
        when "ctrl+c", "q"
          return {self, Term2.quit}
        end

        case @state
        when State::Choose
          @ti.blur
          case msg.string
          when "j", "down"
            @choice_index = (@choice_index + 1) % 3
          when "k", "up"
            @choice_index = (@choice_index - 1) % 3
            @choice_index += 3 if @choice_index < 0
          when "enter"
            @state = State::Input
            @ti.focus
            @choice = case @choice_index
                      when 0 then ColorChoice::Foreground
                      when 1 then ColorChoice::Background
                      else        ColorChoice::Cursor
                      end
          end
        when State::Input
          @ti.focus
          case msg.string
          when "esc"
            reset_selection
            @ti.blur
          when "enter"
            value = @ti.value
            color = parse_hex_color(value)
            if color.nil?
              @err = "invalid color: #{value}"
            else
              chosen = @choice
              reset_selection
              @ti.reset
              @err = nil
              case chosen
              when ColorChoice::Foreground then @fg = color
              when ColorChoice::Background then @bg = color
              when ColorChoice::Cursor     then @cc = color
              else
              end
              @ti.blur
            end
          else
            @ti, cmd = @ti.update(msg)
            return {self, cmd}
          end
        end
      end

      {self, nil}
    end

    def view : Term2::View
      content = String.build do |s|
        instructions = Lipgloss::Style.new.width(40).render("Choose a terminal-wide color to set. All settings will be cleared on exit.")

        case @state
        when State::Choose
          s << instructions << "\n\n"
          [ColorChoice::Foreground, ColorChoice::Background, ColorChoice::Cursor].each_with_index do |choice, idx|
            s << (idx == @choice_index ? " > " : "   ")
            s << choice_name(choice) << "\n"
          end
        when State::Input
          s << "Enter a color in hex format:\n\n"
          s << @ti.view.content
          s << "\n"
        end

        if err = @err
          s << "\nError: " << err
        end

        s << "\nPress q to quit"
        case @state
        when State::Choose
          s << ", j/k to move, and enter to select"
        when State::Input
          s << ", and enter to submit, esc to go back"
        end
        s << "\n"
      end

      Term2::View.new(
        content: content,
        foreground_color: @fg,
        background_color: @bg
      )
    end

    private def choice_name(choice : ColorChoice) : String
      case choice
      when ColorChoice::Foreground then "Foreground"
      when ColorChoice::Background then "Background"
      when ColorChoice::Cursor     then "Cursor"
      else                              "Unknown"
      end
    end

    private def parse_hex_color(value : String) : Lipgloss::Color?
      stripped = value.strip
      return nil unless stripped.matches?(/\A#?(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/)
      Lipgloss::Color.hex(stripped)
    rescue
      nil
    end

    private def reset_selection : Nil
      @choice = ColorChoice::None
      @choice_index = 0
      @state = State::Choose
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SetTerminalColorExample::Model.new)
end
