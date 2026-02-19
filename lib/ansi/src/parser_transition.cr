module Ansi
  module ParserTransition
    alias Action = UInt8
    alias State = UInt8

    NoneAction     = 0_u8
    ClearAction    = 1_u8
    CollectAction  = 2_u8
    PrefixAction   = 3_u8
    DispatchAction = 4_u8
    ExecuteAction  = 5_u8
    StartAction    = 6_u8
    PutAction      = 7_u8
    ParamAction    = 8_u8
    PrintAction    = 9_u8

    IgnoreAction = NoneAction

    ActionNames = [
      "NoneAction",
      "ClearAction",
      "CollectAction",
      "PrefixAction",
      "DispatchAction",
      "ExecuteAction",
      "StartAction",
      "PutAction",
      "ParamAction",
      "PrintAction",
    ]

    GroundState             =  0_u8
    CsiEntryState           =  1_u8
    CsiIntermediateState    =  2_u8
    CsiParamState           =  3_u8
    DcsEntryState           =  4_u8
    DcsIntermediateState    =  5_u8
    DcsParamState           =  6_u8
    DcsStringState          =  7_u8
    EscapeState             =  8_u8
    EscapeIntermediateState =  9_u8
    OscStringState          = 10_u8
    SosStringState          = 11_u8
    PmStringState           = 12_u8
    ApcStringState          = 13_u8
    Utf8State               = 14_u8

    StateNames = [
      "GroundState",
      "CsiEntryState",
      "CsiIntermediateState",
      "CsiParamState",
      "DcsEntryState",
      "DcsIntermediateState",
      "DcsParamState",
      "DcsStringState",
      "EscapeState",
      "EscapeIntermediateState",
      "OscStringState",
      "SosStringState",
      "PmStringState",
      "ApcStringState",
      "Utf8State",
    ]

    PrefixShift       =    8
    IntermedShift     =   16
    FinalMask         = 0xff
    HasMoreFlag       = Int32::MIN
    ParamMask         = ~HasMoreFlag
    MissingParam      = ParamMask
    MissingCommand    = MissingParam
    MaxParam          = 65_535
    MaxParamsSize     =     32
    DefaultParamValue =      0

    TransitionActionShift =    4
    TransitionStateMask   =   15
    IndexStateShift       =    8
    DefaultTableSize      = 4096

    def self.prefix(cmd : Int32) : Int32
      (cmd >> PrefixShift) & FinalMask
    end

    def self.intermediate(cmd : Int32) : Int32
      (cmd >> IntermedShift) & FinalMask
    end

    def self.command(cmd : Int32) : Int32
      cmd & FinalMask
    end

    def self.param(params : Array(Int32), i : Int32) : Int32
      return -1 if params.empty? || i < 0 || i >= params.size
      p = params[i] & ParamMask
      return -1 if p == MissingParam
      p
    end

    def self.has_more(params : Array(Int32), i : Int32) : Bool
      return false if params.empty? || i >= params.size
      (params[i] & HasMoreFlag) != 0
    end

    # ameba:disable Metrics/CyclomaticComplexity
    def self.subparams(params : Array(Int32), i : Int32) : Array(Int32)?
      return nil if params.empty? || i < 0 || i >= params.size

      count = 0
      j = 0
      while j < params.size
        break if count == i
        count += 1 unless has_more(params, j)
        j += 1
      end

      return nil if count > i || j >= params.size

      subs = [] of Int32
      while j < params.size
        break unless has_more(params, j)
        p = param(params, j)
        p = DefaultParamValue if p == -1
        subs << p
        j += 1
      end

      p = param(params, j)
      p = DefaultParamValue if p == -1
      subs << p
      subs
    end

    def self.len(params : Array(Int32)) : Int32
      n = 0
      params.each_with_index do |_p, i|
        n += 1 unless has_more(params, i)
      end
      n
    end

    def self.range(params : Array(Int32), & : Int32, Int32, Bool -> Bool)
      params.each_with_index do |_p, i|
        break unless yield i, param(params, i), has_more(params, i)
      end
    end

    class TransitionTable
      def initialize(size : Int32 = DefaultTableSize)
        size = DefaultTableSize if size <= 0
        @data = Array(UInt8).new(size, 0_u8)
      end

      def set_default(action : Action, state : State)
        value = ((action.to_u8 << TransitionActionShift) | state).to_u8
        @data.map! { value }
      end

      def add_one(code : UInt8, state : State, action : Action, next_state : State)
        idx = (state.to_i << IndexStateShift) | code.to_i
        @data[idx] = ((action.to_u8 << TransitionActionShift) | next_state).to_u8
      end

      def add_many(codes : Array(UInt8), state : State, action : Action, next_state : State)
        codes.each do |code|
          add_one(code, state, action, next_state)
        end
      end

      def add_range(start_code : UInt8, end_code : UInt8, state : State, action : Action, next_state : State)
        i = start_code.to_i
        last = end_code.to_i
        while i <= last
          add_one(i.to_u8, state, action, next_state)
          i += 1
        end
      end

      def transition(state : State, code : UInt8) : {State, Action}
        index = (state.to_i << IndexStateShift) | code.to_i
        value = @data[index]
        next_state = (value & TransitionStateMask).to_u8
        action = (value >> TransitionActionShift).to_u8
        {next_state, action}
      end
    end

    def self.r(start_code : UInt8, end_code : UInt8) : Array(UInt8)
      a = [] of UInt8
      i = start_code.to_i
      last = end_code.to_i
      while i <= last
        a << i.to_u8
        i += 1
      end
      a
    end

    def self.generate_transition_table : TransitionTable
      table = TransitionTable.new(DefaultTableSize)
      table.set_default(NoneAction, GroundState)

      r(GroundState, Utf8State).each do |state|
        table.add_many([0x18, 0x1a, 0x99, 0x9a].map(&.to_u8), state, ExecuteAction, GroundState)
        table.add_range(0x80_u8, 0x8f_u8, state, ExecuteAction, GroundState)
        table.add_range(0x90_u8, 0x97_u8, state, ExecuteAction, GroundState)
        table.add_one(0x9c_u8, state, ExecuteAction, GroundState)
        table.add_one(0x1b_u8, state, ClearAction, EscapeState)
        table.add_one(0x98_u8, state, StartAction, SosStringState)
        table.add_one(0x9e_u8, state, StartAction, PmStringState)
        table.add_one(0x9f_u8, state, StartAction, ApcStringState)
        table.add_one(0x9b_u8, state, ClearAction, CsiEntryState)
        table.add_one(0x90_u8, state, ClearAction, DcsEntryState)
        table.add_one(0x9d_u8, state, StartAction, OscStringState)
        table.add_range(0xc2_u8, 0xdf_u8, state, CollectAction, Utf8State)
        table.add_range(0xe0_u8, 0xef_u8, state, CollectAction, Utf8State)
        table.add_range(0xf0_u8, 0xf4_u8, state, CollectAction, Utf8State)
      end

      table.add_range(0x00_u8, 0x17_u8, GroundState, ExecuteAction, GroundState)
      table.add_one(0x19_u8, GroundState, ExecuteAction, GroundState)
      table.add_range(0x1c_u8, 0x1f_u8, GroundState, ExecuteAction, GroundState)
      table.add_range(0x20_u8, 0x7e_u8, GroundState, PrintAction, GroundState)
      table.add_one(0x7f_u8, GroundState, ExecuteAction, GroundState)

      table.add_range(0x00_u8, 0x17_u8, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState)
      table.add_one(0x19_u8, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState)
      table.add_range(0x1c_u8, 0x1f_u8, EscapeIntermediateState, ExecuteAction, EscapeIntermediateState)
      table.add_range(0x20_u8, 0x2f_u8, EscapeIntermediateState, CollectAction, EscapeIntermediateState)
      table.add_one(0x7f_u8, EscapeIntermediateState, IgnoreAction, EscapeIntermediateState)
      table.add_range(0x30_u8, 0x7e_u8, EscapeIntermediateState, DispatchAction, GroundState)

      table.add_range(0x00_u8, 0x17_u8, EscapeState, ExecuteAction, EscapeState)
      table.add_one(0x19_u8, EscapeState, ExecuteAction, EscapeState)
      table.add_range(0x1c_u8, 0x1f_u8, EscapeState, ExecuteAction, EscapeState)
      table.add_one(0x7f_u8, EscapeState, IgnoreAction, EscapeState)
      table.add_range(0x30_u8, 0x4f_u8, EscapeState, DispatchAction, GroundState)
      table.add_range(0x51_u8, 0x57_u8, EscapeState, DispatchAction, GroundState)
      table.add_one(0x59_u8, EscapeState, DispatchAction, GroundState)
      table.add_one(0x5a_u8, EscapeState, DispatchAction, GroundState)
      table.add_one(0x5c_u8, EscapeState, DispatchAction, GroundState)
      table.add_range(0x60_u8, 0x7e_u8, EscapeState, DispatchAction, GroundState)
      table.add_range(0x20_u8, 0x2f_u8, EscapeState, CollectAction, EscapeIntermediateState)
      table.add_one('X'.ord.to_u8, EscapeState, StartAction, SosStringState)
      table.add_one('^'.ord.to_u8, EscapeState, StartAction, PmStringState)
      table.add_one('_'.ord.to_u8, EscapeState, StartAction, ApcStringState)
      table.add_one('P'.ord.to_u8, EscapeState, ClearAction, DcsEntryState)
      table.add_one('['.ord.to_u8, EscapeState, ClearAction, CsiEntryState)
      table.add_one(']'.ord.to_u8, EscapeState, StartAction, OscStringState)

      r(SosStringState, ApcStringState).each do |state|
        table.add_range(0x00_u8, 0x17_u8, state, PutAction, state)
        table.add_one(0x19_u8, state, PutAction, state)
        table.add_range(0x1c_u8, 0x1f_u8, state, PutAction, state)
        table.add_range(0x20_u8, 0x7f_u8, state, PutAction, state)
        table.add_one(0x1b_u8, state, DispatchAction, EscapeState)
        table.add_one(0x9c_u8, state, DispatchAction, GroundState)
        table.add_many([0x18, 0x1a].map(&.to_u8), state, IgnoreAction, GroundState)
      end

      table.add_range(0x00_u8, 0x07_u8, DcsEntryState, IgnoreAction, DcsEntryState)
      table.add_range(0x0e_u8, 0x17_u8, DcsEntryState, IgnoreAction, DcsEntryState)
      table.add_one(0x19_u8, DcsEntryState, IgnoreAction, DcsEntryState)
      table.add_range(0x1c_u8, 0x1f_u8, DcsEntryState, IgnoreAction, DcsEntryState)
      table.add_one(0x7f_u8, DcsEntryState, IgnoreAction, DcsEntryState)
      table.add_range(0x20_u8, 0x2f_u8, DcsEntryState, CollectAction, DcsIntermediateState)
      table.add_range(0x30_u8, 0x3b_u8, DcsEntryState, ParamAction, DcsParamState)
      table.add_range(0x3c_u8, 0x3f_u8, DcsEntryState, PrefixAction, DcsParamState)
      table.add_range(0x08_u8, 0x0d_u8, DcsEntryState, PutAction, DcsStringState)
      table.add_one(0x1b_u8, DcsEntryState, PutAction, DcsStringState)
      table.add_range(0x40_u8, 0x7e_u8, DcsEntryState, StartAction, DcsStringState)

      table.add_range(0x00_u8, 0x17_u8, DcsIntermediateState, IgnoreAction, DcsIntermediateState)
      table.add_one(0x19_u8, DcsIntermediateState, IgnoreAction, DcsIntermediateState)
      table.add_range(0x1c_u8, 0x1f_u8, DcsIntermediateState, IgnoreAction, DcsIntermediateState)
      table.add_range(0x20_u8, 0x2f_u8, DcsIntermediateState, CollectAction, DcsIntermediateState)
      table.add_one(0x7f_u8, DcsIntermediateState, IgnoreAction, DcsIntermediateState)
      table.add_range(0x30_u8, 0x3f_u8, DcsIntermediateState, StartAction, DcsStringState)
      table.add_range(0x40_u8, 0x7e_u8, DcsIntermediateState, StartAction, DcsStringState)

      table.add_range(0x00_u8, 0x17_u8, DcsParamState, IgnoreAction, DcsParamState)
      table.add_one(0x19_u8, DcsParamState, IgnoreAction, DcsParamState)
      table.add_range(0x1c_u8, 0x1f_u8, DcsParamState, IgnoreAction, DcsParamState)
      table.add_range(0x30_u8, 0x3b_u8, DcsParamState, ParamAction, DcsParamState)
      table.add_one(0x7f_u8, DcsParamState, IgnoreAction, DcsParamState)
      table.add_range(0x3c_u8, 0x3f_u8, DcsParamState, IgnoreAction, DcsParamState)
      table.add_range(0x20_u8, 0x2f_u8, DcsParamState, CollectAction, DcsIntermediateState)
      table.add_range(0x40_u8, 0x7e_u8, DcsParamState, StartAction, DcsStringState)

      table.add_range(0x00_u8, 0x17_u8, DcsStringState, PutAction, DcsStringState)
      table.add_one(0x19_u8, DcsStringState, PutAction, DcsStringState)
      table.add_range(0x1c_u8, 0x1f_u8, DcsStringState, PutAction, DcsStringState)
      table.add_range(0x20_u8, 0x7e_u8, DcsStringState, PutAction, DcsStringState)
      table.add_one(0x7f_u8, DcsStringState, PutAction, DcsStringState)
      table.add_range(0x80_u8, 0xff_u8, DcsStringState, PutAction, DcsStringState)
      table.add_one(0x1b_u8, DcsStringState, DispatchAction, EscapeState)
      table.add_one(0x9c_u8, DcsStringState, DispatchAction, GroundState)
      table.add_many([0x18, 0x1a].map(&.to_u8), DcsStringState, IgnoreAction, GroundState)

      table.add_range(0x00_u8, 0x17_u8, CsiParamState, ExecuteAction, CsiParamState)
      table.add_one(0x19_u8, CsiParamState, ExecuteAction, CsiParamState)
      table.add_range(0x1c_u8, 0x1f_u8, CsiParamState, ExecuteAction, CsiParamState)
      table.add_range(0x30_u8, 0x3b_u8, CsiParamState, ParamAction, CsiParamState)
      table.add_one(0x7f_u8, CsiParamState, IgnoreAction, CsiParamState)
      table.add_range(0x3c_u8, 0x3f_u8, CsiParamState, IgnoreAction, CsiParamState)
      table.add_range(0x40_u8, 0x7e_u8, CsiParamState, DispatchAction, GroundState)
      table.add_range(0x20_u8, 0x2f_u8, CsiParamState, CollectAction, CsiIntermediateState)

      table.add_range(0x00_u8, 0x17_u8, CsiIntermediateState, ExecuteAction, CsiIntermediateState)
      table.add_one(0x19_u8, CsiIntermediateState, ExecuteAction, CsiIntermediateState)
      table.add_range(0x1c_u8, 0x1f_u8, CsiIntermediateState, ExecuteAction, CsiIntermediateState)
      table.add_range(0x20_u8, 0x2f_u8, CsiIntermediateState, CollectAction, CsiIntermediateState)
      table.add_one(0x7f_u8, CsiIntermediateState, IgnoreAction, CsiIntermediateState)
      table.add_range(0x40_u8, 0x7e_u8, CsiIntermediateState, DispatchAction, GroundState)
      table.add_range(0x30_u8, 0x3f_u8, CsiIntermediateState, IgnoreAction, GroundState)

      table.add_range(0x00_u8, 0x17_u8, CsiEntryState, ExecuteAction, CsiEntryState)
      table.add_one(0x19_u8, CsiEntryState, ExecuteAction, CsiEntryState)
      table.add_range(0x1c_u8, 0x1f_u8, CsiEntryState, ExecuteAction, CsiEntryState)
      table.add_one(0x7f_u8, CsiEntryState, IgnoreAction, CsiEntryState)
      table.add_range(0x40_u8, 0x7e_u8, CsiEntryState, DispatchAction, GroundState)
      table.add_range(0x20_u8, 0x2f_u8, CsiEntryState, CollectAction, CsiIntermediateState)
      table.add_range(0x30_u8, 0x3b_u8, CsiEntryState, ParamAction, CsiParamState)
      table.add_range(0x3c_u8, 0x3f_u8, CsiEntryState, PrefixAction, CsiParamState)

      table.add_range(0x00_u8, 0x06_u8, OscStringState, IgnoreAction, OscStringState)
      table.add_range(0x08_u8, 0x17_u8, OscStringState, IgnoreAction, OscStringState)
      table.add_one(0x19_u8, OscStringState, IgnoreAction, OscStringState)
      table.add_range(0x1c_u8, 0x1f_u8, OscStringState, IgnoreAction, OscStringState)
      table.add_range(0x20_u8, 0xff_u8, OscStringState, PutAction, OscStringState)
      table.add_one(0x1b_u8, OscStringState, DispatchAction, EscapeState)
      table.add_one(0x07_u8, OscStringState, DispatchAction, GroundState)
      table.add_one(0x9c_u8, OscStringState, DispatchAction, GroundState)
      table.add_many([0x18, 0x1a].map(&.to_u8), OscStringState, IgnoreAction, GroundState)

      table
    end

    Table = generate_transition_table
  end
end
