require "../../../src/term2"

include Term2::Prelude

PINK = Term2::Color.new(Term2::Color::Type::RGB, {255, 117, 183})

class HelpKeys
  include TC::Help::KeyMap

  getter up : TC::Key::Binding
  getter down : TC::Key::Binding
  getter left : TC::Key::Binding
  getter right : TC::Key::Binding
  getter help : TC::Key::Binding
  getter quit : TC::Key::Binding

  def initialize
    @up = TC::Key::Binding.new(
      TC::Key.with_keys("up", "k"),
      TC::Key.with_help("↑/k", "move up"),
    )
    @down = TC::Key::Binding.new(
      TC::Key.with_keys("down", "j"),
      TC::Key.with_help("↓/j", "move down"),
    )
    @left = TC::Key::Binding.new(
      TC::Key.with_keys("left", "h"),
      TC::Key.with_help("←/h", "move left"),
    )
    @right = TC::Key::Binding.new(
      TC::Key.with_keys("right", "l"),
      TC::Key.with_help("→/l", "move right"),
    )
    @help = TC::Key::Binding.new(
      TC::Key.with_keys("?"),
      TC::Key.with_help("?", "toggle help"),
    )
    @quit = TC::Key::Binding.new(
      TC::Key.with_keys("q", "esc", "ctrl+c"),
      TC::Key.with_help("q", "quit"),
    )
  end

  def short_help : Array(TC::Key::Binding)
    [@help, @quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [
      [@up, @down, @left, @right],
      [@help, @quit],
    ]
  end
end

class HelpModel
  include Term2::Model

  getter keys : HelpKeys
  getter help : TC::Help
  getter input_style : Term2::Style
  getter last_key : String
  getter? quitting : Bool

  def initialize
    @keys = HelpKeys.new
    @help = TC::Help.new
    @input_style = Term2::Style.new.foreground(PINK)
    @last_key = ""
    @quitting = false
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @help.width = msg.width
    when Term2::KeyMsg
      case
      when @keys.up.matches?(msg)
        @last_key = "↑"
      when @keys.down.matches?(msg)
        @last_key = "↓"
      when @keys.left.matches?(msg)
        @last_key = "←"
      when @keys.right.matches?(msg)
        @last_key = "→"
      when @keys.help.matches?(msg)
        @help.show_all = !@help.show_all?
      when @keys.quit.matches?(msg)
        @quitting = true
        return {self, Term2::Cmds.quit}
      end
    end

    {self, nil}
  end

  def view : String
    return "Bye!\n" if @quitting

    status = if @last_key.empty?
               "Waiting for input..."
             else
               "You chose: " + @input_style.render(@last_key)
             end

    help_view = @help.view(@keys)
    height = 8 - status.count('\n') - help_view.count('\n')
    spacer = height > 0 ? "\n" * height : ""

    "\n#{status}#{spacer}#{help_view}"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(HelpModel.new)
end
