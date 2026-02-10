require "./base_types"

module Term2
  # Raised when an executed process exits unsuccessfully.
  class ExecError < Exception
    getter cmd : String
    getter exit_status : Int32?

    def initialize(@cmd : String, message : String, @exit_status : Int32? = nil)
      super(message)
    end
  end

  # ExecMsg is sent to the update loop to request running an external process
  # in a blocking fashion. The terminal will be released (raw mode disabled,
  # cursor shown) while the process runs, and restored afterwards.
  class ExecMsg < ControlMsg
    getter cmd : String
    getter args : Array(String)
    getter env : Hash(String, String)?
    getter callback : Proc(Exception?, Msg?)?

    def initialize(@cmd : String, @args : Array(String) = [] of String, @env = nil, @callback = nil)
    end
  end

  # Extend Cmds module with exec_process
  module Cmds
    # Creates a command that runs an external process.
    # The terminal is paused (raw mode disabled) while the command runs.
    # The block receives the error (if any) or nil when the process finishes.
    def self.exec_process(cmd : String, args : Array(String) = [] of String, env : Hash(String, String)? = nil, &block : Exception? -> Msg?) : ::Term2::Cmd
      -> { ExecMsg.new(cmd, args, env, block).as(Msg?) }
    end

    # Creates a command that runs an external process without a callback.
    def self.exec_process(cmd : String, args : Array(String) = [] of String, env : Hash(String, String)? = nil) : ::Term2::Cmd
      -> { ExecMsg.new(cmd, args, env, nil).as(Msg?) }
    end
  end
end
