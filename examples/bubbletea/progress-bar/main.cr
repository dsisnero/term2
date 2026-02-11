require "../../../src/term2"

module ProgressBarExample
  include Term2::Prelude

  BODY = Lipgloss::Style.new.padding(1, 2)

  class Model
    include Term2::Model

    property value : Int32 = 50
    property width : Int32 = 0
    property state : Term2::ProgressBarState = Term2::ProgressBarState::Indeterminate

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::WindowSizeMsg
        @width = msg.width
      when Term2::KeyMsg
        case msg.string
        when "q", "ctrl+c"
          return {self, Term2.quit}
        when "up", "k"
          @value += 10 if @value < 100
        when "down", "j"
          @value -= 10 if @value > 0
        when "left", "h"
          @state = Term2::ProgressBarState.from_value(@state.value - 1) if @state.value > 0
        when "right", "l"
          @state = Term2::ProgressBarState.from_value(@state.value + 1) if @state.value < 4
        end
      end

      {self, nil}
    end

    def view : Term2::View
      body_width = @width > 0 ? @width - BODY.horizontal_padding : 80
      content = BODY.width(body_width).render(
        "This demo requires a terminal emulator that supports an indeterminate progress bar, such a Windows Terminal or Ghostty. In other terminals (including tmux in a supporting terminal) nothing will happen.\n\nPress up/down to change value, left/right to change state, q to quit."
      )

      Term2::View.new(
        content: content,
        progress_bar: Term2::ProgressBar.new(@state, @value)
      )
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ProgressBarExample::Model.new)
end
