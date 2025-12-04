require "../../../src/term2"
require "log"

include Term2::Prelude

GAP = "\n\n"

Log.setup_from_env

class ChatModel
  include Model

  getter viewport : TC::Viewport
  getter textarea : TC::TextArea
  getter messages : Array(String)
  getter sender_style : Term2::Style
  property? suspending : Bool = false

  def initialize
    @textarea = TC::TextArea.new("chat-textarea")
    @textarea.placeholder = "Send a message..."
    @textarea.focus

    @textarea.prompt = "┃ "
    @textarea.char_limit = 280

    @textarea.set_width(30)
    @textarea.height = 3

    @textarea.show_line_numbers = false
    @textarea.key_map.insert_newline.set_enabled(false)

    @viewport = TC::Viewport.new(30, 5)
    @viewport.content = initial_welcome

    @messages = [] of String
    @sender_style = Term2::Style.new.foreground(Term2::Color::MAGENTA)
  end

  def init : Cmd
    Cmds.batch(@textarea.focus, @textarea.blink)
  end

  def update(msg : Message) : {Model, Cmd}
    Log.debug { "chat#update msg=#{msg.class.name}" }

    case msg
    when Term2::WindowSizeMsg
      resize(msg.width, msg.height)
      return {self, Cmds.none}
    when Term2::KeyMsg
      key = msg.key.to_s
      case key
      when "ctrl+c", "esc"
        return {self, Term2.quit}
      when "enter"
        submit_message
        return {self, Cmds.none}
      when "ctrl+z"
        @suspending = true
        return {self, Cmds.suspend}
      end
    when Term2::ResumeMsg
      @suspending = false
      return {self, Cmds.none}
    end

    new_textarea, ta_cmd = @textarea.update(msg)
    @textarea = new_textarea

    new_viewport, vp_cmd = @viewport.update(msg)
    @viewport = new_viewport

    cmd =
      if ta_cmd && vp_cmd
        Cmds.batch(ta_cmd, vp_cmd)
      elsif ta_cmd
        ta_cmd
      elsif vp_cmd
        vp_cmd
      else
        Cmds.none
      end

    {self, cmd}
  end

  def view : String
    return "" if suspending?

    "#{@viewport.view}#{GAP}#{@textarea.view}"
  end

  private def initial_welcome : String
    <<-MSG
Welcome to the chat room!
Type a message and press Enter to send.
MSG
  end

  private def resize(width : Int32, height : Int32)
    gap_height = Text.height(GAP)
    @viewport.width = width
    @textarea.set_width(width)
    @viewport.height = (height - @textarea.height - gap_height).clamp(1, height)
    update_viewport_content
    @viewport.goto_bottom
  end

  private def submit_message
    text = @textarea.value.strip
    return if text.empty?

    @messages << @sender_style.render("You: ") + text
    update_viewport_content
    @textarea.reset
    @viewport.goto_bottom
  end

  private def update_viewport_content
    wrapper = Term2::Style.new.width(@viewport.width)
    @viewport.content = wrapper.render(@messages.join("\n"))
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ChatModel.new)
end
