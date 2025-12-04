require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

class ClearErrorMsg < Term2::Message; end

def clear_error_after(duration : Time::Span) : Term2::Cmd
  Term2::Cmds.tick(duration) { ClearErrorMsg.new }
end

class FilePickerModel
  include Term2::Model

  getter filepicker : TC::FilePicker
  getter selected_file : String = ""
  getter? quitting : Bool = false
  getter err : String?

  def initialize
    fp = TC::FilePicker.new
    fp.allowed_types = [".mod", ".sum", ".go", ".txt", ".md"]
    fp.current_directory = ENV["HOME"]? || Dir.current
    @filepicker = fp
    @err = nil
  end

  def init : Term2::Cmd
    @filepicker.init
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q"
        @quitting = true
        return {self, Term2::Cmds.quit}
      end
    when ClearErrorMsg
      @err = nil
    end

    new_fp, cmd = @filepicker.update(msg)
    @filepicker = new_fp

    if @filepicker.did_select_file?
      if path = @filepicker.selected_file
        @selected_file = path
      end
    end

    if @filepicker.error
      @err = @filepicker.error
      @selected_file = ""
      return {self, Term2::Cmds.batch(cmd, clear_error_after(2.seconds))}
    end

    {self, cmd}
  end

  def view : String
    return "" if quitting?
    prefix = if err = @err
               @filepicker.error_style.render(err)
             elsif @selected_file.empty?
               "Pick a file:"
             else
               "Selected file: " + @filepicker.selected_style.render(@selected_file)
             end
    "#{prefix}\n\n#{@filepicker.view}\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(FilePickerModel.new)
end
