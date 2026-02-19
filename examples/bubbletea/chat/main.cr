require "../../../src/term2"
require "log"

include Term2::Prelude

GAP = "\n\n"

Log.setup_from_env

class ChatModel
  include Term2::Model

  getter viewport : TC::Viewport
  getter textarea : TC::TextArea
  getter messages : Array(String)
  getter sender_style : Lipgloss::Style
  property? suspending : Bool = false

  def initialize
    @textarea = TC::TextArea.new("chat-textarea")
    @textarea.placeholder = "Send a message..."
    @textarea.focus

    @textarea.prompt = "┃ "
    @textarea.char_limit = 280

    @textarea.width = 30
    @textarea.height = 3

    @textarea.show_line_numbers = false

    @viewport = TC::Viewport.new(30, 5)
    @viewport.content = initial_welcome

    @messages = [] of String
    @sender_style = Lipgloss::Style.new.magenta

    # Ensure the textarea starts focused for direct model usage (matches Bubble Tea behavior).
    @textarea.focus
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(@textarea.focus, @textarea.blink)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    Log.debug { "chat#update msg=#{msg.class.name}" }

    case msg
    when Term2::WindowSizeMsg
      resize(msg.width, msg.height)
      return {self, Term2::Cmds.none}
    when Term2::KeyMsg
      key = msg.string
      case key
      when "ctrl+c", "esc"
        return {self, Term2::Cmds.quit}
      when "enter"
        submit_message
        return {self, Term2::Cmds.none}
      when "ctrl+z"
        @suspending = true
        return {self, Term2::Cmds.suspend}
      end
    when Term2::ResumeMsg
      @suspending = false
      return {self, Term2::Cmds.none}
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

    "#{@viewport.view.content}#{GAP}#{@textarea.view.content}"
  end

  private def initial_welcome : String
    <<-MSG
Welcome to the chat room!
Type a message and press Enter to send.
MSG
  end

  private def resize(width : Int32, height : Int32)
    gap_height = Lipgloss::Text.height(GAP)
    @viewport.width = width
    @textarea.width = width
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
    wrapper = Lipgloss::Style.new.width(@viewport.width)
    body = String.build do |io|
      io << initial_welcome
      unless @messages.empty?
        io << "\n\n"
        io << @messages.join("\n")
      end
    end
    @viewport.content = wrapper.render(body)
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ChatModel.new)
end
