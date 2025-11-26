require "./spec_helper"

describe Term2::Components::TextInput do
  it "shows placeholder when unfocused" do
    input = Term2::Components::TextInput.new(placeholder: "Type...")
    model, _ = input.init
    model = model.as(Term2::Components::TextInput::Model)

    input.view(model).should contain("Type...")
  end

  it "inserts characters and responds to key bindings" do
    input = Term2::Components::TextInput.new
    model, _ = input.init
    model = model.as(Term2::Components::TextInput::Model)

    model, _ = input.update(Term2::Components::TextInput::Focus.new, model)
    model = model.as(Term2::Components::TextInput::Model)

    %w[h i].each do |char|
      model, _ = input.update(Term2::KeyPress.new(char), model)
      model = model.as(Term2::Components::TextInput::Model)
    end

    model, _ = input.update(Term2::KeyPress.new("\u0002"), model) # move left
    model = model.as(Term2::Components::TextInput::Model)

    model, _ = input.update(Term2::KeyPress.new("\u007F"), model) # backspace
    model = model.as(Term2::Components::TextInput::Model)

    model.value.should eq("i")
    model.cursor.should eq(0)
  end
end
