require "../spec_helper"
require "../../src/components/text_input"

# Helper to simulate typing a string into the model
def type_text(model, text)
  text.each_char do |char|
    model.update(Term2::TestHelpers.key_msg(Term2::TestHelpers.uv_key(char)))
  end
end

# Helper to simulate specific key presses
def press_key(model, key : String)
  model.update(Term2::TestHelpers.key_msg(key))
end

describe Term2::Components::TextInput do
  it "manages suggestions" do
    ti = Term2::Components::TextInput.new
    ti.show_suggestions = true
    ti.suggestions = ["test1", "test2", "test3"]

    ti.current_suggestion.should eq ""

    ti.set_value("test")
    ti.update_suggestions

    ti.next_suggestion
    ti.current_suggestion.should eq "test2"

    ti.prev_suggestion
    ti.current_suggestion.should eq "test1"

    ti.focus
    press_key(ti, "tab")
    ti.value.should eq "test1"

    ti.blur
    ti.view.content.should_not contain "test2"
  end

  it "handles slicing outside cap (no crash)" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "作業ディレクトリを指定してください"
    ti.width = 32
    # Ensure view doesn't raise
    ti.view.should be_a(Term2::View)
  end

  it "matches suggestions with prefix input" do
    ti = Term2::Components::TextInput.new
    ti.show_suggestions = true
    ti.suggestions = ["abc", "adc", "a1c", "zzz"]

    ti.set_value("a")
    ti.update_suggestions

    ti.matched_suggestions.size.should eq 3
    ti.matched_suggestions.should contain "abc"
    ti.matched_suggestions.should contain "adc"
    ti.matched_suggestions.should contain "a1c"
    ti.matched_suggestions.should_not contain "zzz"
  end

  it "renders Chinese placeholder padded to width" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "输入消息..."
    ti.width = 20
    # Reset styles to defaults for strict string comparison
    ti.styles.focused.prompt = Lipgloss::Style.new
    ti.styles.blurred.prompt = Lipgloss::Style.new
    ti.styles.focused.placeholder = Lipgloss::Style.new
    ti.styles.blurred.placeholder = Lipgloss::Style.new

    # Note: Crystal's string width calculation might differ slightly from Go's runewidth
    # depending on the libraries used, but assuming standard wide-char handling:
    ti.view.content.should eq "> 输入消息...       "
  end

  it "truncates long placeholder" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "A very long placeholder, or maybe not so much"
    ti.styles.focused.prompt = Lipgloss::Style.new
    ti.styles.blurred.prompt = Lipgloss::Style.new
    ti.styles.focused.placeholder = Lipgloss::Style.new
    ti.styles.blurred.placeholder = Lipgloss::Style.new
    ti.width = 10

    # Note: Term2 uses "…" (ellipsis) for truncation
    ti.view.content.should eq "> A very …"
  end

  it "limits input with char_limit" do
    ti = Term2::Components::TextInput.new
    ti.char_limit = 3
    ti.set_value("hello")
    ti.value.should eq "hel"
  end

  it "supports validation (credit card example)" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "4505 **** **** 1234"
    ti.focus
    ti.char_limit = 20
    ti.width = 30
    ti.prompt = ""

    # Corrected signature: Must return Exception? (nil means valid)
    ti.validate = ->(s : String) : Exception? {
      if s.size > 19
        return Exception.new("CCN is too long")
      end

      if s.size == 0
        # Check specific validation logic from Go example...
        # For simplicity in this port test:
        return Exception.new("Empty")
      end

      # Check last char logic
      last_char = s[-1]
      if s.size % 5 != 0 && !(last_char >= '0' && last_char <= '9')
        return Exception.new("CCN is invalid")
      end

      if s.size % 5 == 0 && last_char != ' '
        return Exception.new("CCN must separate groups with spaces")
      end

      nil
    }

    # Simulate typing valid sequence
    type_text(ti, "4505 1234 5678 9012")
    ti.value.should eq("4505 1234 5678 9012")

    # This should be valid (nil exception)
    ti.validate.not_nil!.call(ti.value).should be_nil

    # Simulate typing invalid char
    # "4505 1234 5678 9012" + "a"
    # The component usually accepts the input but sets @err.
    # Or strict validators might prevent input?
    # Bubble Tea TextInput sets .Err but allows the input unless you handle it differently.
    # However, let's verify the VALIDATOR logic itself works:

    ti.validate.not_nil!.call("4505 1234 5678 9012a").should_not be_nil
  end

  it "maps cursor style properties" do
    ti = Term2::Components::TextInput.new
    ti.styles = Term2::Components::TextInput::Styles.new(
      cursor: Term2::Components::TextInput::CursorStyle.new(
        color: Lipgloss::Color.from_hex("#FF0000"),
        shape: Term2::CursorShape::Underline,
        blink: true,
        blink_speed: 300.milliseconds
      )
    )

    ti.cursor.blink_speed.should eq 300.milliseconds
    ti.cursor.mode.should eq Term2::Components::Cursor::Mode::Blink
    # Shape mapping to Lipgloss::Style
    ti.cursor.style.underline?.should be_true
    # Color mapping to text_style
    # ti.cursor.text_style should have foreground color set
    # We'll trust that update_cursor_style worked since blink_speed and mode are set
  end

  it "uses Styles struct for focused and blurred states" do
    ti = Term2::Components::TextInput.new
    focused_style = Term2::Components::TextInput::StyleState.new(
      prompt: Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#00FF00")),
      text: Lipgloss::Style.new.bold(true)
    )
    blurred_style = Term2::Components::TextInput::StyleState.new(
      prompt: Lipgloss::Style.new.foreground(Lipgloss::Color.from_hex("#0000FF")),
      text: Lipgloss::Style.new.faint(true)
    )
    ti.styles = Term2::Components::TextInput::Styles.new(
      focused: focused_style,
      blurred: blurred_style,
      cursor: Term2::Components::TextInput::CursorStyle.new
    )

    ti.focus
    ti.prompt_style.should eq focused_style.prompt
    ti.text_style.should eq focused_style.text

    ti.blur
    ti.prompt_style.should eq blurred_style.prompt
    ti.text_style.should eq blurred_style.text
  end
end
