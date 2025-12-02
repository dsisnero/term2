require "../src/term2"
require "../src/components/file_picker"

class FilePickerModel
  include Term2::Model
  property picker : Term2::Components::FilePicker
  property selected_file : String?

  def initialize
    @picker = Term2::Components::FilePicker.new(path: ".")
    @picker.allowed_types = [".cr", ".md", ".yml", ".json"]
    @picker.show_hidden = false
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Message) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_picker, cmd = @picker.update(msg)
    @picker = new_picker

    if @picker.did_select_file?
      @selected_file = @picker.selected_file
      return {self, Term2.quit}
    end

    {self, cmd}
  end

  def view : String
    if @selected_file
      "You selected: #{@selected_file}"
    else
      "Select a file (q to quit):\n\n" +
        @picker.view
    end
  end
end

Term2.run(FilePickerModel.new)
