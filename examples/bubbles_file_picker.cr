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

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_picker, cmd = @picker.update(msg)
    @picker = new_picker

    if @picker.did_select_file?
      selected = @picker.selected_file
      if selected && !selected.empty?
        @selected_file = selected
        return {self, Term2.quit}
      end
    end

    {self, cmd}
  end

  def view : String
    if selected = @selected_file
      "You selected: #{@selected_file}"
    else
      "  Pick a file:\n\n#{@picker.view.content}"
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(FilePickerModel.new)
end
