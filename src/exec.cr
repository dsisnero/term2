require "./base_types"
require "./terminal"

module Term2
  # ExecMsg is dispatched to perform a blocking external command, releasing the terminal.
  class ExecMsg < Message
    getter cmd : String
    getter args : Array(String)
    getter callback : Proc(Exception?, Msg)?

    def initialize(@cmd : String, @args : Array(String) = [] of String, @callback : Proc(Exception?, Msg)? = nil)
    end
  end

  module Cmds
    # Exec a command string with optional args; callback receives exception or nil.
    def self.exec_process(cmd : String, args : Array(String) = [] of String, &block : Exception? -> Msg) : ::Term2::Cmd
      -> : Msg? { ExecMsg.new(cmd, args, block) }
    end

    def self.exec_process(cmd : String, args : Array(String) = [] of String) : ::Term2::Cmd
      -> : Msg? { ExecMsg.new(cmd, args, nil) }
    end
  end
end
