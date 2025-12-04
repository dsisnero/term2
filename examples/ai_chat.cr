# AI Chat style demo for Term2.
# Run with: crystal run examples/ai_chat.cr
require "../src/term2"
include Term2::Prelude

struct ChatMessage
  getter role : String
  getter text : String

  def initialize(@role : String, @text : String)
  end
end

class AiChatModel
  include Model

  HEADER_STYLE    = Term2::Style.new.bold(true).foreground(Term2::Color::YELLOW)
  ROLE_STYLES     = {
    "user"      => Term2::Style.new.foreground(Term2::Color::CYAN).bold(true),
    "assistant" => Term2::Style.new.foreground(Term2::Color::GREEN),
    "system"    => Term2::Style.new.faint(true),
  }
  BUBBLE_STYLE   = Term2::Style.new.padding(0, 1)
  META_STYLE     = Term2::Style.new.faint(true)
  SLASH_COMMANDS = [
    {name: "/model", desc: "choose model and reasoning effort (not wired)"},
    {name: "/approvals", desc: "choose what Codex can do without approval (not wired)"},
    {name: "/review", desc: "review current changes and find issues (not wired)"},
    {name: "/new", desc: "start a new chat during a conversation (not wired)"},
    {name: "/init", desc: "create an AGENTS.md file with instructions (not wired)"},
    {name: "/compact", desc: "summarize conversation to prevent hitting context limit (not wired)"},
    {name: "/undo", desc: "ask Codex to undo a turn (not wired)"},
    {name: "/diff", desc: "show git diff (including untracked files) (not wired)"},
    {name: "/system", desc: "set system prompt"},
    {name: "/clear", desc: "clear history"},
    {name: "/help", desc: "this help"},
  ]

  getter messages : Array(ChatMessage)
  getter input : Term2::Components::TextInput
  getter model_name : String
  getter system_prompt : String
  getter window_width : Int32
  getter window_height : Int32
  @command_filter : String = ""
  @command_index : Int32 = 0

  def initialize
    @messages = [
      ChatMessage.new("system", "You are a helpful AI. Type /help for commands."),
      ChatMessage.new("assistant", "Hey there! Ask me something or try /model llama3."),
    ]
    @input = Term2::Components::TextInput.new("chat-input")
    @input.width = 80
    @viewport = Term2::Components::Viewport.new(80, 18)
    @model_name = "gpt-4o"
    @system_prompt = "You are a helpful AI."
    @window_width = 80
    @window_height = 24
  end

  def init : Cmd
    Cmds.batch(@input.focus, redraw_viewport)
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Term2::WindowSizeMsg
      resize(msg.width, msg.height)
      return {self, redraw_viewport}
    when Term2::KeyMsg
      if msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
      # submit on Enter
      if msg.key.to_s == "enter"
        submit_input
        return {self, redraw_viewport}
      end
    end

    {self, Cmds.none}
  end

  def view : String
    String.build do |io|
      io << HEADER_STYLE.render("AI Chat  (model: #{@model_name})") << "\n"
      io << META_STYLE.render("Slash commands: /model, /system, /clear, /help, /approvals, /review, /new, /init, /compact, /undo, /diff") << "\n\n"
      io << @viewport.view << "\n"
      io << "\n"
      io << @input.view
    end
  end

  private def submit_input
    text = @input.value.strip
    return if text.empty?

    append("user", text)
    append("assistant", synth_response(text))

    @input.value = ""
    @input.cursor_pos = 0
  end

  private def handle_command(text : String)
    parts = text.split(/\s+/, 2)
    cmd = parts[0]
    payload = parts[1]? || ""

    case cmd
    when "/clear"
      @messages.clear
      append("system", "History cleared.")
    when "/help"
      append("system", <<-HELP.strip)
        Commands:
          /model <name>      choose model and reasoning effort (not wired)
          /approvals         choose what Codex can do without approval (not wired)
          /review            review current changes and find issues (not wired)
          /new               start a new chat during a conversation (not wired)
          /init              create an AGENTS.md file with instructions (not wired)
          /compact           summarize conversation to prevent hitting context limit (not wired)
          /undo              ask Codex to undo a turn (not wired)
          /diff              show git diff (including untracked files) (not wired)
          /system <prompt>   set system prompt
          /clear             clear history
          /help              this help
      HELP
    when "/approvals", "/review", "/new", "/init", "/compact", "/undo", "/diff"
      append("system", "Command #{cmd} noted (UI only, not wired).")
    when "/model"
      if payload.empty?
        append("system", "Usage: /model <name>")
      else
        @model_name = payload
        append("system", "Model switched to #{payload}")
      end
    when "/system"
      if payload.empty?
        append("system", "Usage: /system <prompt>")
      else
        @system_prompt = payload
        append("system", "System prompt updated.")
      end
    else
      append("system", "Unknown command: #{cmd}")
    end
  end

  private def append(role : String, text : String)
    @messages << ChatMessage.new(role, text)
  end

  private def synth_response(prompt : String) : String
    # Placeholder response to mimic an AI reply
    %(Echoing "#{prompt}" using #{@model_name}. (Not actually calling an API.))
  end

  private def redraw_viewport : Cmd
    Cmds.message(UpdateViewportMsg.new)
  end

  class UpdateViewportMsg < Message; end

  def update(msg : UpdateViewportMsg) : {Model, Cmd}
    refresh_viewport
    {self, Cmds.none}
  end

  private def refresh_viewport
    body = @messages.map { |m| format_message(m) }.join("\n\n")
    @viewport.content = body
    @viewport.y_offset = @viewport.max_y_offset
  end

  private def resize(width : Int32, height : Int32)
    @window_width = width
    @window_height = height

    header_reserved = 2 # header + meta
    padding_reserved = 2 # blank lines around viewport/input
    input_reserved = 1
    total_reserved = header_reserved + padding_reserved + input_reserved

    new_height = (height - total_reserved).clamp(1, height)
    @viewport.width = width
    @viewport.height = new_height
    @input.width = width
  end

  private def format_message(msg : ChatMessage) : String
    role_style = ROLE_STYLES[msg.role]? || Term2::Style.new
    label_raw = msg.role.upcase.ljust(9)
    role_label = role_style.render(label_raw)
    label_width = Term2::Text.width(label_raw)
    wrapped = wrap_text(msg.text, @viewport.width - label_width - 2)
    wrapped.lines.map_with_index do |line, idx|
      prefix = idx == 0 ? "#{role_label} " : " " * (label_width + 1)
      BUBBLE_STYLE.render("#{prefix}#{line}")
    end.join("\n")
  end

  private def wrap_text(text : String, width : Int32) : String
    return text if width <= 0
    words = text.split(" ")
    lines = [] of String
    current_words = [] of String
    current_width = 0

    words.each do |word|
      word_width = Term2::Text.width(word)
      extra = current_width > 0 ? 1 : 0
      if current_width > 0 && (current_width + extra + word_width) > width
        lines << current_words.join(" ")
        current_words.clear
        current_width = 0
      end
      current_words << word
      current_width += (current_width > 0 ? 1 : 0) + word_width
    end

    lines << current_words.join(" ") unless current_words.empty?
    lines.join("\n")
  end

end

Term2.run(AiChatModel.new)
