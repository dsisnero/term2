require "../src/term2"
include Term2::Prelude

input = Components::TextInput.new(placeholder: "Type here")
model, cmd = input.init(focused: true)

class Demo < Application
  def initialize(@input : Components::TextInput, @model : Components::TextInput::Model, @cmd : Cmd)
  end

  def init
    {@model, @cmd}
  end

  def update(msg : Message, model : Model)
    if msg.is_a?(KeyPress)
      @input.update(msg, model.as(Components::TextInput::Model))
    else
      {model, Cmd.none}
    end
  end

  def view(model : Model) : String
    @input.view(model.as(Components::TextInput::Model))
  end
end

Demo.new(input, model, cmd).run
