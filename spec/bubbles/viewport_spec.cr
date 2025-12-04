require "../spec_helper"
require "../../src/components/viewport"

DEFAULT_HORIZONTAL_STEP = 6

DEFAULT_LIST = [
  "57 Precepts of narcissistic comedy character Zote from an awesome \"Hollow knight\" game (https://store.steampowered.com/app/367520/Hollow_Knight/).",
  "Precept One: 'Always Win Your Battles'. Losing a battle earns you nothing and teaches you nothing. Win your battles, or don't engage in them at all!",
  "Precept Two: 'Never Let Them Laugh at You'. Fools laugh at everything, even at their superiors. But beware, laughter isn't harmless! Laughter spreads like a disease, and soon everyone is laughing at you. You need to strike at the source of this perverse merriment quickly to stop it from spreading.",
  "Precept Three: 'Always Be Rested'. Fighting and adventuring take their toll on your body. When you rest, your body strengthens and repairs itself. The longer you rest, the stronger you become.",
  "Precept Four: 'Forget Your Past'. The past is painful, and thinking about your past can only bring you misery. Think about something else instead, such as the future, or some food.",
  "Precept Five: 'Strength Beats Strength'. Is your opponent strong? No matter! Simply overcome their strength with even more strength, and they'll soon be defeated.",
  "Precept Six: 'Choose Your Own Fate'. Our elders teach that our fate is chosen for us before we are even born. I disagree.",
  "Precept Seven: 'Mourn Not the Dead'. When we die, do things get better for us or worse? There's no way to tell, so we shouldn't bother mourning. Or celebrating for that matter.",
  "Precept Eight: 'Travel Alone'. You can rely on nobody, and nobody will always be loyal. Therefore, nobody should be your constant companion.",
  "Precept Nine: 'Keep Your Home Tidy'. Your home is where you keep your most prized possession - yourself. Therefore, you should make an effort to keep it nice and clean.",
  "Precept Ten: 'Keep Your Weapon Sharp'. I make sure that my weapon, 'Life Ender', is kept well-sharpened at all times. This makes it much easier to cut things.",
  "Precept Eleven: 'Mothers Will Always Betray You'. This Precept explains itself.",
  "Precept Twelve: 'Keep Your Cloak Dry'. If your cloak gets wet, dry it as soon as you can. Wearing wet cloaks is unpleasant, and can lead to illness.",
  "Precept Thirteen: 'Never Be Afraid'. Fear can only hold you back. Facing your fears can be a tremendous effort. Therefore, you should just not be afraid in the first place.",
  "Precept Fourteen: 'Respect Your Superiors'. If someone is your superior in strength or intellect or both, you need to show them your respect. Don't ignore them or laugh at them.",
  "Precept Fifteen: 'One Foe, One Blow'. You should only use a single blow to defeat an enemy. Any more is a waste. Also, by counting your blows as you fight, you'll know how many foes you've defeated.",
  "...",
] of String

describe Term2::Components::Viewport do
  it "initializes defaults" do
    m = Term2::Components::Viewport.new(10, 10)
    m.horizontal_step = DEFAULT_HORIZONTAL_STEP
    m.initialized?.should be_true
    m.horizontal_step.should eq DEFAULT_HORIZONTAL_STEP
    m.mouse_wheel_delta.should eq 3
    m.mouse_wheel_enabled?.should be_true
  end

  it "keeps horizontal step when setting initial values" do
    m = Term2::Components::Viewport.new(0, 0)
    m.horizontal_step = DEFAULT_HORIZONTAL_STEP
    m.set_initial_values
    m.horizontal_step.should eq DEFAULT_HORIZONTAL_STEP
  end

  it "sets horizontal step with non-negative values" do
    m = Term2::Components::Viewport.new(10, 10)
    m.horizontal_step = DEFAULT_HORIZONTAL_STEP
    m.horizontal_step.should eq DEFAULT_HORIZONTAL_STEP
    m.set_horizontal_step(-1)
    m.horizontal_step.should eq 0
  end

  it "scrolls left and clamps at zero" do
    m = Term2::Components::Viewport.new(10, 10)
    m.longest_line_width = 100
    m.x_offset.should eq 0
    m.scroll_left(m.horizontal_step)
    m.x_offset.should eq 0

    m.x_offset = DEFAULT_HORIZONTAL_STEP * 2
    m.horizontal_step = DEFAULT_HORIZONTAL_STEP
    m.scroll_left(m.horizontal_step)
    m.x_offset.should eq DEFAULT_HORIZONTAL_STEP
  end

  it "scrolls right within bounds" do
    m = Term2::Components::Viewport.new(10, 10)
    m.set_horizontal_step(DEFAULT_HORIZONTAL_STEP)
    m.set_content("Some line that is longer than width")
    m.x_offset.should eq 0
    m.scroll_right(m.horizontal_step)
    m.x_offset.should eq DEFAULT_HORIZONTAL_STEP
  end

  it "resets indent" do
    m = Term2::Components::Viewport.new(10, 10)
    m.x_offset = 500
    m.set_x_offset(0)
    m.x_offset.should eq 0
  end

  describe "#visible_lines" do
    it "handles empty list" do
      m = Term2::Components::Viewport.new(10, 10)
      m.visible_lines.should be_empty
      m.x_offset = 5
      m.visible_lines.should be_empty
    end

    it "returns lines clamped to width" do
      number_of_lines = 10
      m = Term2::Components::Viewport.new(10, number_of_lines)
      m.set_content(DEFAULT_LIST.join("\n"))
      list = m.visible_lines
      list.size.should eq number_of_lines
      last_idx = number_of_lines - 1
      list[last_idx].should eq DEFAULT_LIST[last_idx][0, m.width]
    end

    it "respects y offset" do
      number_of_lines = 10
      m = Term2::Components::Viewport.new(10, number_of_lines)
      m.set_content(DEFAULT_LIST.join("\n"))
      m.y_offset = 5
      list = m.visible_lines
      list.size.should eq number_of_lines
      list[0].should_not eq DEFAULT_LIST[0]
      last_idx = number_of_lines - 1
      list[last_idx].should eq DEFAULT_LIST[m.y_offset + last_idx][0, m.width]
    end

    it "supports horizontal scroll with y offset" do
      number_of_lines = 10
      m = Term2::Components::Viewport.new(10, number_of_lines)
      m.horizontal_step = DEFAULT_HORIZONTAL_STEP
      m.set_content(DEFAULT_LIST.join("\n"))
      m.set_y_offset(7)

      list = m.visible_lines
      list.size.should eq number_of_lines
      last_idx = number_of_lines - 1
      list[last_idx].should eq DEFAULT_LIST.last

      percept_prefix = "Precept"
      list[0].starts_with?(percept_prefix).should be_true

      m.scroll_right(m.horizontal_step)
      list = m.visible_lines
      new_prefix = percept_prefix[m.x_offset, percept_prefix.size - m.x_offset]
      list[0].starts_with?(new_prefix).should be_true
      list[last_idx].should eq "" # "..." trimmed away

      m.scroll_left(m.horizontal_step)
      list = m.visible_lines
      list[0].starts_with?(percept_prefix).should be_true
      list[last_idx].should eq DEFAULT_LIST.last
    end

    it "handles double-width characters when scrolling horizontally" do
      init_list = ["あいうえお", "Aあいうえお", "あいうえお", "Aあいうえお"]
      number_of_lines = init_list.size
      m = Term2::Components::Viewport.new(20, number_of_lines)
      m.lines = init_list
      m.longest_line_width = 30
      m.set_horizontal_step(5)

      list = m.visible_lines
      list.size.should eq number_of_lines
      list.last.should eq init_list.last

      m.scroll_right(m.horizontal_step)
      list = m.visible_lines
      list.each do |line|
        line.should eq "うえお"
      end

      m.scroll_left(m.horizontal_step)
      list = m.visible_lines
      list.should eq init_list

      m.x_offset = 0
      m.scroll_left(m.horizontal_step)
      list = m.visible_lines
      list.should eq init_list
    end
  end

  it "prevents right overscroll" do
    content = "Content is short"
    m = Term2::Components::Viewport.new(content.size + 1, 5)
    m.set_content(content)
    10.times { m.scroll_right(m.horizontal_step) }
    m.visible_lines[0].should eq content
  end
end
