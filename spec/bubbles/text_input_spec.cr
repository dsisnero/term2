require "../spec_helper"
require "../../src/components/text_input"

describe Term2::Components::TextInput do
  it "manages suggestions" do
    ti = Term2::Components::TextInput.new
    ti.show_suggestions = true

    ti.set_suggestions(["test1", "test2", "test3"])
    ti.current_suggestion.should eq ""

    ti.value = "test"
    ti.update_suggestions
    ti.next_suggestion
    ti.current_suggestion.should eq "test2"

    ti.prev_suggestion
    ti.current_suggestion.should eq "test1"

    ti.accept_current_suggestion
    ti.value.should eq "test1"

    ti.blur
    ti.view.should_not contain "test2"
  end

  it "handles slicing outside cap (no crash)" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "作業ディレクトリを指定してください"
    ti.width = 32
    ti.view
  end

  it "renders Chinese placeholder padded to width" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "输入消息..."
    ti.width = 20
    ti.prompt_style = Term2::Style.new
    ti.placeholder_style = Term2::Style.new
    ti.view.should eq "> 输入消息...       "
  end

  it "truncates long placeholder" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "A very long placeholder, or maybe not so much"
    ti.prompt_style = Term2::Style.new
    ti.placeholder_style = Term2::Style.new
    ti.width = 10
    ti.view.should eq "> A very …"
  end

  it "limits input with char_limit" do
    ti = Term2::Components::TextInput.new
    ti.char_limit = 3
    ti.value = "hello"
    ti.value.should eq "hel"
  end

  it "supports validation (credit card example)" do
    ti = Term2::Components::TextInput.new
    ti.placeholder = "4505 **** **** 1234"
    ti.focus
    ti.char_limit = 20
    ti.width = 30
    ti.prompt = ""
    ti.validate = ->(s : String) : Bool {
      return false if s.size > 19
      return false if s.size == 0
      if s.size % 5 != 0 && (s[-1]? && !(s[-1] >= '0' && s[-1] <= '9'))
        return false
      end
      if s.size % 5 == 0 && s[-1]? != ' '
        return false
      end
      true
    }

    ti.insert_string("4505 1234 5678 9012")
    ti.value.should eq("4505 1234 5678 9012")

    # Invalid append should be rejected
    ti.insert_string(" 9999")
    ti.value.should eq("4505 1234 5678 9012")
  end
end
