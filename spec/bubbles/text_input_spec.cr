require "../spec_helper"
require "../../src/components/text_input"

# Helper to simulate typing a string into the model
def type_text(model, text)
  text.each_char do |char|
    model.update(Term2::KeyMsg.new(Term2::Key.new(char)))
  end
end

# Helper to simulate specific key presses
def press_key(model, key_type : Term2::KeyType)
  model.update(Term2::KeyMsg.new(Term2::Key.new(key_type)))
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
    press_key(ti, Term2::KeyType::Tab)
    ti.value.should eq "test1"

    ti.blur
    ti.view.should_not contain "test2"
  end

  it "handles slicing outside cap (no crash)" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "作業ディレクトリを指定してください"
    ti.width = 32
    # Ensure view doesn't raise
    ti.view.should be_a(String)
  end

  it "renders Chinese placeholder padded to width" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "输入消息..."
    ti.width = 20
    # Reset styles to defaults for strict string comparison
    ti.prompt_style = Term2::Style.new
    ti.placeholder_style = Term2::Style.new

    # Note: Crystal's string width calculation might differ slightly from Go's runewidth
    # depending on the libraries used, but assuming standard wide-char handling:
    ti.view.should eq "> 输入消息...       "
  end

  it "truncates long placeholder" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "A very long placeholder, or maybe not so much"
    ti.prompt_style = Term2::Style.new
    ti.placeholder_style = Term2::Style.new
    ti.width = 10

    # Note: Term2 uses "…" (ellipsis) for truncation
    ti.view.should eq "> A very …"
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
end
