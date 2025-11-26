require "../src/term2"
require "../src/bubbles/file_picker"

class FilePickerModel < Term2::Model
  property picker : Term2::Bubbles::FilePicker
  property selected_file : String?

  def initialize
    @picker = Term2::Bubbles::FilePicker.new(path: ".")
    @picker.allowed_types = [".cr", ".md", ".yml", ".json"]
    @picker.show_hidden = false
  end
end

class FilePickerDemo < Term2::Application(FilePickerModel)
  def init : {FilePickerModel, Term2::Cmd}
    {FilePickerModel.new, Term2::Cmd.none}
  end

  def update(msg : Term2::Message, model : FilePickerModel) : {FilePickerModel, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {model, Term2::Cmd.quit}
      end
    end

    new_picker, cmd = model.picker.update(msg)
    model.picker = new_picker

    if model.picker.did_select_file?
      model.selected_file = model.picker.selected_file
      return {model, Term2::Cmd.quit}
    end

    {model, cmd}
  end

  def view(model : FilePickerModel) : String
    if model.selected_file
      "You selected: #{model.selected_file}"
    else
      "Select a file (q to quit):\n\n" +
        model.picker.view
    end
  end
end

FilePickerDemo.new.run
