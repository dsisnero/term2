module Ansi
  class Parser
    getter params : Array(Int32)
    property data : Array(UInt8)
    property params_len : Int32
    property data_len : Int32
    property cmd : Int32
    property state : UInt8

    def initialize
      @handler = Handler.new
      @params = [] of Int32
      @data = [] of UInt8
      @data_len = 0
      @params_len = 0
      @cmd = 0
      @state = ParserTransition::GroundState
      set_params_size(ParserTransition::MaxParamsSize)
      set_data_size(1024 * 64)
    end

    # ameba:disable Naming/AccessorMethodName
    def set_handler(h : Handler)
      @handler = h
    end

    # ameba:disable Naming/AccessorMethodName
    def set_params_size(size : Int32)
      @params = Array(Int32).new(size, ParserTransition::MissingParam)
    end

    # ameba:disable Naming/AccessorMethodName
    def set_data_size(size : Int32)
      if size <= 0
        @data = [] of UInt8
        @data_len = -1
        return
      end
      @data = Array(UInt8).new(size, 0_u8)
    end

    def params_slice : Params
      Params.new(@params[0, @params_len])
    end

    def param(i : Int32, def_value : Int32) : {Int32, Bool}
      return {def_value, false} if i < 0 || i >= @params_len
      value = @params[i] & ParserTransition::ParamMask
      return {def_value, true} if value == ParserTransition::MissingParam
      {value, true}
    end

    def command : Int32
      @cmd
    end

    def rune : Char
      rw = utf8_byte_len((@cmd & 0xff).to_u8)
      return '\u{FFFD}' if rw == -1

      bytes = Bytes.new(rw)
      i = 0
      while i < rw
        bytes[i] = ((@cmd >> (i * 8)) & 0xff).to_u8
        i += 1
      end

      str = String.new(bytes, "UTF-8", :skip)
      str.each_char.first? || '\u{FFFD}'
    end

    def control : UInt8
      (@cmd & 0xff).to_u8
    end

    def data_slice : Bytes
      if @data_len < 0
        array_to_bytes(@data)
      else
        array_to_bytes(@data[0, @data_len])
      end
    end

    def reset
      clear
      @state = ParserTransition::GroundState
    end

    def state_name : String
      ParserTransition::StateNames[@state]
    end

    def parse(bytes : Bytes)
      bytes.each do |b|
        advance(b)
      end
    end

    def parse(s : String)
      parse(s.to_slice)
    end

    def advance(b : UInt8) : UInt8
      return advance_utf8(b) if @state == ParserTransition::Utf8State

      state, action = ParserTransition::Table.transition(@state, b)

      if @state != state
        if @state == ParserTransition::EscapeState
          perform_action(ParserTransition::ClearAction, state, b)
        end
        if action == ParserTransition::PutAction &&
           @state == ParserTransition::DcsEntryState && state == ParserTransition::DcsStringState
          perform_action(ParserTransition::StartAction, state, 0_u8)
        end
      end

      if b == ESC && @state == ParserTransition::EscapeState
        perform_action(ParserTransition::ExecuteAction, state, b)
      else
        perform_action(action, state, b)
      end

      @state = state
      action
    end

    private def collect_rune(b : UInt8)
      return if @params_len >= 4

      shift = @params_len * 8
      @cmd &= ~(0xff << shift)
      @cmd |= b.to_i << shift
      @params_len += 1
    end

    private def advance_utf8(b : UInt8) : UInt8
      collect_rune(b)
      rw = utf8_byte_len((@cmd & 0xff).to_u8)
      raise "invalid rune" if rw == -1

      return ParserTransition::CollectAction if @params_len < rw

      @handler.print.try(&.call(rune))

      @state = ParserTransition::GroundState
      @params_len = 0
      ParserTransition::PrintAction
    end

    private def parse_string_cmd
      datalen = @data_len
      datalen = @data.size if @data_len < 0

      i = 0
      while i < datalen
        d = @data[i]
        break if d < '0'.ord || d > '9'.ord
        @cmd = 0 if @cmd == ParserTransition::MissingCommand
        @cmd *= 10
        @cmd += (d - '0'.ord)
        i += 1
      end
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def perform_action(action : UInt8, state : UInt8, b : UInt8)
      case action
      when ParserTransition::IgnoreAction
        return
      when ParserTransition::ClearAction
        clear
      when ParserTransition::PrintAction
        @cmd = b.to_i
        @handler.print.try(&.call(b.chr))
      when ParserTransition::ExecuteAction
        @cmd = b.to_i
        @handler.execute.try(&.call(b))
      when ParserTransition::PrefixAction
        @cmd &= ~(0xff << ParserTransition::PrefixShift)
        @cmd |= b.to_i << ParserTransition::PrefixShift
      when ParserTransition::CollectAction
        if state == ParserTransition::Utf8State
          @params_len = 0
          collect_rune(b)
        else
          @cmd &= ~(0xff << ParserTransition::IntermedShift)
          @cmd |= b.to_i << ParserTransition::IntermedShift
        end
      when ParserTransition::ParamAction
        return if @params_len >= @params.size

        if b >= '0'.ord && b <= '9'.ord
          @params[@params_len] = 0 if @params[@params_len] == ParserTransition::MissingParam
          @params[@params_len] *= 10
          @params[@params_len] += (b - '0'.ord)
        end

        if b == ':'.ord
          @params[@params_len] |= ParserTransition::HasMoreFlag
        end

        if b == ';'.ord || b == ':'.ord
          @params_len += 1
          @params[@params_len] = ParserTransition::MissingParam if @params_len < @params.size
        end
      when ParserTransition::StartAction
        if @data_len < 0
          @data.clear
        else
          @data_len = 0
        end

        if @state >= ParserTransition::DcsEntryState && @state <= ParserTransition::DcsStringState
          @cmd |= b.to_i
        else
          @cmd = ParserTransition::MissingCommand
        end
      when ParserTransition::PutAction
        if @state == ParserTransition::OscStringState && b == ';'.ord && @cmd == ParserTransition::MissingCommand
          parse_string_cmd
        end

        if @data_len < 0
          @data << b
        elsif @data_len < @data.size
          @data[@data_len] = b
          @data_len += 1
        end
      when ParserTransition::DispatchAction
        if (@params_len > 0 && @params_len < @params.size - 1) ||
           (@params_len == 0 && @params.size > 0 && @params[0] != ParserTransition::MissingParam)
          @params_len += 1
        end

        if @state == ParserTransition::OscStringState && @cmd == ParserTransition::MissingCommand
          parse_string_cmd
        end

        data = @data_len < 0 ? array_to_bytes(@data) : array_to_bytes(@data[0, @data_len])
        params = params_slice

        case @state
        when ParserTransition::CsiEntryState, ParserTransition::CsiParamState, ParserTransition::CsiIntermediateState
          @cmd |= b.to_i
          @handler.handle_csi.try(&.call(@cmd, params))
        when ParserTransition::EscapeState, ParserTransition::EscapeIntermediateState
          @cmd |= b.to_i
          @handler.handle_esc.try(&.call(@cmd))
        when ParserTransition::DcsEntryState, ParserTransition::DcsParamState, ParserTransition::DcsIntermediateState, ParserTransition::DcsStringState
          @handler.handle_dcs.try(&.call(@cmd, params, data))
        when ParserTransition::OscStringState
          @handler.handle_osc.try(&.call(@cmd, data))
        when ParserTransition::SosStringState
          @handler.handle_sos.try(&.call(data))
        when ParserTransition::PmStringState
          @handler.handle_pm.try(&.call(data))
        when ParserTransition::ApcStringState
          @handler.handle_apc.try(&.call(data))
        end
      end
    end

    private def clear
      @params[0] = ParserTransition::MissingParam if @params.size > 0
      @params_len = 0
      @cmd = 0
    end

    private def utf8_byte_len(b : UInt8) : Int32
      if b <= 0x7f
        1
      elsif b >= 0xc0 && b <= 0xdf
        2
      elsif b >= 0xe0 && b <= 0xef
        3
      elsif b >= 0xf0 && b <= 0xf7
        4
      else
        -1
      end
    end

    private def array_to_bytes(array : Array(UInt8)) : Bytes
      Bytes.new(array.size) { |i| array[i] }
    end
  end
end
