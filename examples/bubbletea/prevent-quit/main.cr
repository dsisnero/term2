require "../../../src/term2"

include Term2::Prelude

CHOICE_STYLE    = Term2::Style.new.padding(0, 0, 0, 1).foreground(Term2::Color.new(Term2::Color::Type::Indexed, 241))
SAVE_TEXT_STYLE = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 170))
QUIT_VIEW_STYLE = Term2::Style.new.padding(1).border(Term2::Border.rounded).border_foreground(Term2::Color.new(Term2::Color::Type::Indexed, 170))

class PreventKeymap
  getter save : TC::Key::Binding
  getter quit : TC::Key::Binding

  def initialize
    @save = TC::Key::Binding.new(TC::Key.with_keys("ctrl+s"), TC::Key.with_help("ctrl+s", "save"))
    @quit = TC::Key::Binding.new(TC::Key.with_keys("esc", "ctrl+c"), TC::Key.with_help("esc", "quit"))
  end
end

class PreventQuitModel
  include Term2::Model
  include TC::Help::KeyMap

  getter textarea : TC::TextArea
  getter help : TC::Help
  getter keymap : PreventKeymap
  getter save_text : String
  getter? has_changes : Bool
  getter? quitting : Bool

  def initialize
    @textarea = TC::TextArea.new
    @textarea.placeholder = "Only the best words"
    @textarea.focus

    @help = TC::Help.new
    @keymap = PreventKeymap.new
    @save_text = ""
    @has_changes = false
    @quitting = false
  end

  def init : Term2::Cmd
    @textarea.cursor.blink_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    if @quitting
      return update_prompt_view(msg)
    end
    update_text_view(msg)
  end

  def short_help : Array(TC::Key::Binding)
    [@keymap.save, @keymap.quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [short_help]
  end

  def view : String
    if @quitting
      if @has_changes
        text = Term2.join_horizontal(
          0.0,
          [
            "You have unsaved changes. Quit without saving?",
            CHOICE_STYLE.render("[yn]"),
          ],
        )
        return QUIT_VIEW_STYLE.render(text)
      end
      return "Very important, thank you\n"
    end

    help_view = @help.view_short(self)

    "\nType some important things.\n\n#{@textarea.view}\n\n #{SAVE_TEXT_STYLE.render(@save_text)}\n #{help_view}\n\n"
  end

  private def update_text_view(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    cmds = [] of Term2::Cmd
    case msg
    when Term2::KeyMsg
      @save_text = ""
      case
      when @keymap.save.matches?(msg)
        @save_text = "Changes saved!"
        @has_changes = false
      when @keymap.quit.matches?(msg)
        @quitting = true
        return {self, Term2::Cmds.quit}
      when msg.key.type == Term2::KeyType::Runes
        @save_text = ""
        @has_changes = true
      else
        unless @textarea.focused?
          cmds << @textarea.focus
        end
      end
    end
    @textarea, cmd = @textarea.update(msg)
    cmds << cmd
    {self, Term2::Cmds.batch(cmds)}
  end

  private def update_prompt_view(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if @keymap.quit.matches?(msg) || msg.key.to_s == "y"
        @has_changes = false
        return {self, Term2::Cmds.quit}
      end
      @quitting = false
    end
    {self, nil}
  end
end

def prevent_filter(model : Term2::Model, msg : Term2::Message?) : Term2::Message?
  return msg unless msg.is_a?(Term2::QuitMsg)
  prevent_model = model.as(PreventQuitModel)
  return if prevent_model.has_changes?
  msg
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  model = PreventQuitModel.new
  options = Term2::ProgramOptions.new(Term2::WithFilter.new(->(msg : Term2::Message?) { prevent_filter(model, msg) }))
  program = Term2::Program(PreventQuitModel).new(model, options: options)
  program.run
end
