require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

class EditorFinishedMsg < Term2::Message
  getter err : Exception?

  def initialize(@err : Exception?); end
end

def open_editor_cmd : Term2::Cmd
  editor = ENV["EDITOR"]? || "vim"
  Term2::Cmds.exec_process(editor) { |err| EditorFinishedMsg.new(err) }
end

class ExecModel
  include Term2::Model

  property? alt_screen_active : Bool = false
  property err : Exception? = nil

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "a"
        @alt_screen_active = !@alt_screen_active
        return {self, @alt_screen_active ? Term2::Cmds.enter_alt_screen : Term2::Cmds.exit_alt_screen}
      when "e"
        return {self, open_editor_cmd}
      when "ctrl+c", "q"
        return {self, Term2::Cmds.quit}
      end
    when EditorFinishedMsg
      if msg.err
        @err = msg.err
        return {self, Term2::Cmds.quit}
      end
    end
    {self, nil}
  end

  def view : String
    if err = @err
      "Error: #{err.message}\n"
    else
      "Press 'e' to open your EDITOR.\nPress 'a' to toggle the altscreen\nPress 'q' to quit.\n"
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ExecModel.new)
end
