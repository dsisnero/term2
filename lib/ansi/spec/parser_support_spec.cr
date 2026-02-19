require "./spec_helper"

module ParserSpecSupport
  alias DispatchItem = Char | UInt8 | Int32 | CsiSequence | DcsSequence | Bytes

  struct CsiSequence
    getter cmd : Int32
    getter params : Array(Int32)

    def initialize(@cmd : Int32, @params : Array(Int32))
    end
  end

  struct DcsSequence
    getter cmd : Int32
    getter params : Array(Int32)
    getter data : Bytes

    def initialize(@cmd : Int32, @params : Array(Int32), @data : Bytes)
    end
  end

  class TestDispatcher
    getter dispatched : Array(DispatchItem)

    def initialize
      @dispatched = [] of DispatchItem
    end

    def dispatch_rune(r : Char)
      @dispatched << r
    end

    def dispatch_control(b : UInt8)
      @dispatched << b
    end

    def dispatch_esc(cmd : Int32)
      @dispatched << cmd
    end

    def dispatch_csi(cmd : Int32, params : Ansi::Params)
      @dispatched << CsiSequence.new(cmd, params.to_a.dup)
    end

    def dispatch_dcs(cmd : Int32, params : Ansi::Params, data : Bytes)
      @dispatched << DcsSequence.new(cmd, params.to_a.dup, ParserSpecSupport.clone_bytes(data))
    end

    def dispatch_osc(_cmd : Int32, data : Bytes)
      @dispatched << ParserSpecSupport.clone_bytes(data)
    end

    def dispatch_apc(data : Bytes)
      @dispatched << ParserSpecSupport.clone_bytes(data)
    end
  end

  def self.test_parser(dispatcher : TestDispatcher) : Ansi::Parser
    parser = Ansi::Parser.new
    parser.set_handler(Ansi::Handler.new(
      print: ->(r : Char) { dispatcher.dispatch_rune(r) },
      execute: ->(b : UInt8) { dispatcher.dispatch_control(b) },
      handle_esc: ->(cmd : Int32) { dispatcher.dispatch_esc(cmd) },
      handle_csi: ->(cmd : Int32, params : Ansi::Params) { dispatcher.dispatch_csi(cmd, params) },
      handle_dcs: ->(cmd : Int32, params : Ansi::Params, data : Bytes) { dispatcher.dispatch_dcs(cmd, params, data) },
      handle_osc: ->(cmd : Int32, data : Bytes) { dispatcher.dispatch_osc(cmd, data) },
      handle_apc: ->(data : Bytes) { dispatcher.dispatch_apc(data) }
    ))
    parser.set_params_size(16)
    parser.set_data_size(0)
    parser
  end

  def self.clone_bytes(data : Bytes) : Bytes
    Bytes.new(data.size) { |i| data[i] }
  end
end
