require "../../../src/term2"

module CanvasExample
  include Term2::Prelude
  ASCII_BORDER = Lipgloss::Border.new("-", "-", "|", "|", "+", "+", "+", "+", "|", "|", "+", "+", "+")

  class Model
    include Term2::Model

    property width : Int32 = 0
    property flip : Bool = false
    property quitting : Bool = false

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::WindowSizeMsg
        @width = msg.width
      when Term2::KeyMsg
        case msg.string
        when "q", "ctrl+c", "esc"
          @quitting = true
          return {self, Term2.quit}
        else
          @flip = !@flip
        end
      end

      {self, nil}
    end

    def view : Term2::View
      view = Term2::View.new
      return view if @quitting

      z = @flip ? [1, 0] : [0, 1]

      footer = Lipgloss::Style.new
        .height(13)
        .align_vertical(Lipgloss::Position::Bottom)
        .render("Press any key to swap the cards, or q to quit.")

      card_a = new_card("Hello").z(z[0])
      card_b = new_card("Goodbye").z(z[1]).x(10).y(2)
      comp = Lipgloss.new_compositor(Lipgloss::Layer.new(footer), card_a, card_b)
      view.set_content(comp.render)
      view
    end

    private def new_card(text : String) : Lipgloss::Layer
      Lipgloss::Layer.new(
        Lipgloss::Style.new
          .width(20)
          .height(10)
          .border(ASCII_BORDER)
          .align(Lipgloss::Position::Center, Lipgloss::Position::Center)
          .render(text)
      )
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(CanvasExample::Model.new)
end
