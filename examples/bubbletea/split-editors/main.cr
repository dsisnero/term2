require "../../../src/term2"

include Term2::Prelude

INITIAL_INPUTS = 2
MAX_INPUTS     = 6
MIN_INPUTS     = 1
HELP_HEIGHT    = 5

SPLIT_EDITORS_CURSOR_STYLE = Term2::Style.new.foreground(Term2::Color.indexed(212))
CURSOR_LINE_STYLE          = Term2::Style.new.background(Term2::Color.indexed(57)).foreground(Term2::Color.indexed(230))
PLACEHOLDER_STYLE          = Term2::Style.new.foreground(Term2::Color.indexed(238))
END_OF_BUFFER_STYLE        = Term2::Style.new.foreground(Term2::Color.indexed(235))
FOCUSED_PLACEHOLDER_STYLE  = Term2::Style.new.foreground(Term2::Color.indexed(99))
FOCUSED_BORDER_STYLE       = Term2::Style.new.border(Term2::Border.rounded).border_foreground(Term2::Color.indexed(238))
BLURRED_BORDER_STYLE       = Term2::Style.new.border(Term2::Border.hidden)

class SplitEditorsKeymap
  getter next : TC::Key::Binding
  getter prev : TC::Key::Binding
  getter add : TC::Key::Binding
  getter remove : TC::Key::Binding
  getter quit : TC::Key::Binding

  def initialize
    @next = TC::Key::Binding.new(TC::Key.with_keys("tab"), TC::Key.with_help("tab", "next"))
    @prev = TC::Key::Binding.new(TC::Key.with_keys("shift+tab"), TC::Key.with_help("shift+tab", "prev"))
    @add = TC::Key::Binding.new(TC::Key.with_keys("ctrl+n"), TC::Key.with_help("ctrl+n", "add an editor"))
    @remove = TC::Key::Binding.new(TC::Key.with_keys("ctrl+w"), TC::Key.with_help("ctrl+w", "remove an editor"))
    @quit = TC::Key::Binding.new(TC::Key.with_keys("esc", "ctrl+c"), TC::Key.with_help("esc", "quit"))
  end
end

def new_textarea : TC::TextArea
  t = TC::TextArea.new
  t.prompt = ""
  t.placeholder = "Type something"
  t.show_line_numbers = true
  t.cursor.style = SPLIT_EDITORS_CURSOR_STYLE
  t.placeholder = PLACEHOLDER_STYLE.render(t.placeholder)
  t.end_of_buffer_char = END_OF_BUFFER_STYLE.render(t.end_of_buffer_char.to_s)[0]
  t.key_map.delete_word_backward.enabled = false
  # Keep default key map but simplify movement keys to arrows only
  km = TC::TextArea::KeyMap.new
  km.delete_word_backward.enabled = false
  t.key_map = km
  t.blur
  t
end

class SplitEditorsModel
  include Term2::Model
  include TC::Help::KeyMap

  getter width : Int32
  getter height : Int32
  getter keymap : SplitEditorsKeymap
  getter help : TC::Help
  getter inputs : Array(TC::TextArea)
  getter focus : Int32

  def initialize
    @inputs = Array(TC::TextArea).new
    INITIAL_INPUTS.times { @inputs << new_textarea }
    @help = TC::Help.new
    @keymap = SplitEditorsKeymap.new
    @focus = 0
    @width = 0
    @height = 0
    @inputs[@focus].focus
    update_keybindings
  end

  def init : Term2::Cmd
    @inputs[@focus].cursor.blink_cmd
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    cmds = [] of Term2::Cmd
    case msg
    when Term2::KeyMsg
      case
      when @keymap.quit.matches?(msg)
        @inputs.each(&.blur)
        return {self, Term2::Cmds.quit}
      when @keymap.next.matches?(msg)
        @inputs[@focus].blur
        @focus += 1
        @focus = 0 if @focus > @inputs.size - 1
        cmds << @inputs[@focus].focus
      when @keymap.prev.matches?(msg)
        @inputs[@focus].blur
        @focus -= 1
        @focus = @inputs.size - 1 if @focus < 0
        cmds << @inputs[@focus].focus
      when @keymap.add.matches?(msg)
        @inputs << new_textarea
      when @keymap.remove.matches?(msg)
        if @inputs.size > MIN_INPUTS
          @inputs.pop
          @focus = @inputs.size - 1 if @focus > @inputs.size - 1
        end
      end
    when Term2::WindowSizeMsg
      @height = msg.height
      @width = msg.width
    end

    update_keybindings
    size_inputs

    @inputs.size.times do |i|
      @inputs[i], cmd = @inputs[i].update(msg)
      cmds << cmd
    end

    {self, Term2::Cmds.batch(cmds)}
  end

  def size_inputs
    @inputs.each do |input|
      input.width = @width // @inputs.size
      input.height = @height - HELP_HEIGHT
    end
  end

  def update_keybindings
    @keymap.add.enabled = @inputs.size < MAX_INPUTS
    @keymap.remove.enabled = @inputs.size > MIN_INPUTS
  end

  def short_help : Array(TC::Key::Binding)
    [@keymap.next, @keymap.prev, @keymap.add, @keymap.remove, @keymap.quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [short_help]
  end

  def view : String
    help_view = @help.view_short(self)
    views = @inputs.map(&.view)
    Term2.join_horizontal(0.0, views) + "\n\n" + help_view
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(SplitEditorsModel.new, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new))
end
