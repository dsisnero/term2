module Ansi
  alias Cmd = Int32
  alias Param = Int32

  struct Params
    include Enumerable(Int32)

    def initialize(@values : Array(Int32))
    end

    def each(& : Int32 ->) : Nil
      @values.each { |v| yield v }
    end

    def [](index : Int32) : Int32
      @values[index]
    end

    def size : Int32
      @values.size
    end

    def to_a : Array(Int32)
      @values
    end

    def param(i : Int32, def_value : Int32) : {Int32, Bool, Bool}
      return {def_value, false, false} if i < 0 || i >= @values.size
      value = @values[i]
      {param_value(value, def_value), has_more?(value), true}
    end

    def for_each(def_value : Int32, & : Int32, Int32, Bool ->) : Nil
      @values.each_with_index do |value, i|
        yield i, param_value(value, def_value), has_more?(value)
      end
    end

    def ==(other : Params) : Bool
      @values == other.to_a
    end

    def ==(other : Array(Int32)) : Bool
      @values == other
    end

    private def param_value(value : Int32, def_value : Int32) : Int32
      p = value & ParserTransition::ParamMask
      return def_value if p == ParserTransition::MissingParam
      p
    end

    private def has_more?(value : Int32) : Bool
      (value & ParserTransition::HasMoreFlag) != 0
    end
  end

  def self.to_params(params : Array(Int32)) : Params
    Params.new(params)
  end

  struct Handler
    property print : Proc(Char, Nil)?
    property execute : Proc(UInt8, Nil)?
    property handle_csi : Proc(Cmd, Params, Nil)?
    property handle_esc : Proc(Cmd, Nil)?
    property handle_dcs : Proc(Cmd, Params, Bytes, Nil)?
    property handle_osc : Proc(Int32, Bytes, Nil)?
    property handle_pm : Proc(Bytes, Nil)?
    property handle_apc : Proc(Bytes, Nil)?
    property handle_sos : Proc(Bytes, Nil)?

    def initialize(
      @print : Proc(Char, Nil)? = nil,
      @execute : Proc(UInt8, Nil)? = nil,
      @handle_csi : Proc(Cmd, Params, Nil)? = nil,
      @handle_esc : Proc(Cmd, Nil)? = nil,
      @handle_dcs : Proc(Cmd, Params, Bytes, Nil)? = nil,
      @handle_osc : Proc(Int32, Bytes, Nil)? = nil,
      @handle_pm : Proc(Bytes, Nil)? = nil,
      @handle_apc : Proc(Bytes, Nil)? = nil,
      @handle_sos : Proc(Bytes, Nil)? = nil,
    )
    end
  end
end
