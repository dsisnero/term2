require "../../../src/term2"
require "./words"

module ClickableExample
  include Term2::Prelude

  MAX_DIALOGS = 999

  BG_TEXT_STYLE     = Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(239)).padding(1, 2)
  DIALOG_WORD_STYLE = Lipgloss::Style.new.foreground(Lipgloss::Color.hex("#E7E1CC"))
  DIALOG_STYLE      = DIALOG_WORD_STYLE
    .width(36)
    .height(8)
    .padding(1, 3)
    .border(Lipgloss::Border.rounded)
    .border_foreground(Lipgloss::Color.hex("#874BFD"))
  HOVERED_DIALOG_STYLE = DIALOG_STYLE.border_foreground(Lipgloss::Color.hex("#F25D94"))
  BUTTON_STYLE         = Lipgloss::Style.new
    .padding(0, 3)
    .foreground(Lipgloss::Color.hex("#FFF7DB"))
    .background(Lipgloss::Color.hex("#6124DF"))
  HOVERED_BUTTON_STYLE = BUTTON_STYLE.background(Lipgloss::Color.hex("#FF5F87"))

  class LayerHitMsg < Term2::Message
    getter id : String
    getter event : Term2::UVMouseEvent

    def initialize(@id : String, @event : Term2::UVMouseEvent)
    end
  end

  class Dialog
    property id : String
    property button_id : String
    property x : Int32
    property y : Int32
    property text : String
    property hovering : Bool = false
    property hovering_button : Bool = false

    def initialize(@id : String, @button_id : String, @x : Int32, @y : Int32, @text : String)
    end

    def button_view : String
      label = "Run Away"
      @hovering_button ? HOVERED_BUTTON_STYLE.render(label) : BUTTON_STYLE.render(label)
    end

    def window_view(special_word_color : Lipgloss::Color) : String
      style = @hovering ? HOVERED_DIALOG_STYLE : DIALOG_STYLE
      word = Lipgloss::Style.new.foreground(special_word_color).render(@text)
      style.render(word + DIALOG_WORD_STYLE.render(" draws near. Command?"))
    end

    def layer(special_word_color : Lipgloss::Color) : Lipgloss::Layer
      h_gap = 3
      v_gap = 1
      window = window_view(special_word_color)
      button = button_view

      button_x = Lipgloss.width(window) - Lipgloss.width(button) - 1 - h_gap
      button_y = Lipgloss.height(window) - Lipgloss.height(button) - 1 - v_gap

      button_layer = Lipgloss::Layer.new(button).id(@button_id).x(button_x).y(button_y)
      Lipgloss::Layer.new(window).id(@id).x(@x).y(@y).add_layers(button_layer)
    end
  end

  class Model
    include Term2::Model

    getter dialogs : Array(Dialog)
    property width : Int32 = 0
    property height : Int32 = 0

    @mouse_down : Bool = false
    @press_id : String = ""
    @drag_id : String = ""
    @drag_offset_x : Int32 = 0
    @drag_offset_y : Int32 = 0
    @special_word_color : Lipgloss::Color = Lipgloss::Color.hex("#73F59F")
    @id_counter : Int64 = 0_i64

    def initialize
      @dialogs = [] of Dialog
    end

    def init : Term2::Cmd
      Term2::Cmds.request_background_color
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::WindowSizeMsg
        @width = msg.width
        @height = msg.height
      when Term2::BackgroundColorMsg
        @special_word_color = msg.dark? ? Lipgloss::Color.hex("#73F59F") : Lipgloss::Color.hex("#43BF6D")
      when Term2::KeyMsg
        return {self, Term2.quit} if {"q", "ctrl+c", "esc"}.includes?(msg.string)
      when LayerHitMsg
        handle_layer_hit(msg)
      end
      {self, nil}
    end

    def view : Term2::View
      body = ""
      n = @dialogs.size
      body += "Drag to move. " if n > 0
      if n == 0 && n < MAX_DIALOGS
        body += "Click to spawn."
      elsif n >= 1 && n < MAX_DIALOGS
        body += "Click to spawn up to #{MAX_DIALOGS - n} more."
      end
      body += "\n\nPress q to quit."

      bg = Lipgloss.place(
        @width,
        @height,
        Lipgloss::Position::Top,
        Lipgloss::Position::Left,
        BG_TEXT_STYLE.render(body),
        Lipgloss.with_whitespace_chars("/"),
        Lipgloss.with_whitespace_style(Lipgloss::Style.new.foreground(Lipgloss::Color.indexed(238)))
      )

      root = Lipgloss::Layer.new(bg).id("bg")
      @dialogs.each_with_index do |dialog, idx|
        root.add_layers(dialog.layer(@special_word_color).z(idx + 1))
      end

      comp = Lipgloss.new_compositor(root)
      on_mouse = ->(event : Term2::UVMouseEvent) : Term2::Cmd do
        hit = comp.hit(event.x, event.y)
        id = hit.id
        if id.empty?
          nil
        else
          -> { LayerHitMsg.new(id, event).as(Term2::Msg) }
        end
      end

      Term2::View.new(
        content: comp.render,
        alt_screen: true,
        mouse_mode: Term2::MouseMode::AllMotion,
        on_mouse: on_mouse
      )
    end

    private def handle_layer_hit(msg : LayerHitMsg) : Nil
      mouse = msg.event.mouse
      case msg.event
      when Term2::MouseClickMsg
        return unless mouse.button == UV::MouseButton::Left
        return if @mouse_down

        @mouse_down = true
        @press_id = msg.id

        @dialogs.each_with_index do |dialog, idx|
          next unless dialog.id == msg.id

          @drag_id = msg.id
          @drag_offset_x = mouse.x - dialog.x
          @drag_offset_y = mouse.y - dialog.y

          if @dialogs.size >= 2
            dragged = @dialogs.delete_at(idx)
            @dialogs << dragged if dragged
          end
          break
        end
      when Term2::MouseMotionMsg
        if @mouse_down && !@drag_id.empty?
          @dialogs.each do |dialog|
            next unless dialog.id == @drag_id
            w = Lipgloss.width(dialog.window_view(@special_word_color))
            h = Lipgloss.height(dialog.window_view(@special_word_color))
            dialog.x = clamp(mouse.x - @drag_offset_x, 0, @width - w)
            dialog.y = clamp(mouse.y - @drag_offset_y, 0, @height - h)
            break
          end
        end

        @dialogs.each do |dialog|
          dialog.hovering = false
          dialog.hovering_button = false
          if dialog.id == msg.id
            dialog.hovering = true
          elsif dialog.button_id == msg.id
            dialog.hovering = true
            dialog.hovering_button = true
          end
        end
      when Term2::MouseReleaseMsg
        return if @press_id.empty?

        @dialogs.each_with_index do |dialog, idx|
          if msg.id == dialog.button_id && @press_id == dialog.button_id
            @dialogs.delete_at(idx)
            break
          end
        end

        if msg.id == "bg" && @press_id == "bg" && @dialogs.size < MAX_DIALOGS
          @dialogs << new_dialog(mouse.x, mouse.y)
        end

        @mouse_down = false
        @drag_id = ""
        @press_id = ""
      else
      end
    end

    private def new_dialog(x : Int32, y : Int32) : Dialog
      id = next_id
      button_id = next_id
      text = ClickableExample.next_random_word

      probe = Dialog.new(id, button_id, 0, 0, text)
      window = probe.window_view(@special_word_color)
      w = Lipgloss.width(window)
      h = Lipgloss.height(window)
      dx = clamp(x - (w // 2), 0, @width - w)
      dy = clamp(y - (h // 2), 0, @height - h)

      Dialog.new(id, button_id, dx, dy, text)
    end

    private def next_id : String
      @id_counter += 1
      "dlg-#{@id_counter}"
    end

    private def clamp(value : Int32, min : Int32, max : Int32) : Int32
      return min if value < min
      return max if value > max
      value
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ClickableExample::Model.new)
end
