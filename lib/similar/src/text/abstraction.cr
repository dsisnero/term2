module Similar
  # Abstraction for string-like values used in generic text diffs.
  module DiffableStr
    abstract def size : Int32
    abstract def [](index : Int32) : Char
    abstract def slice(range : Range(Int32, Int32)) : self
    abstract def to_s : String
  end

  # Zero-cost wrapper for String to satisfy DiffableStr.
  struct StringWrapper
    include DiffableStr

    getter value : String

    def initialize(@value : String)
    end

    def size : Int32
      @value.size
    end

    def [](index : Int32) : Char
      @value[index]
    end

    def slice(range : Range(Int32, Int32)) : self
      slice = @value[range]?
      StringWrapper.new(slice || "")
    end

    def to_s : String
      @value
    end

    def ==(other : self) : Bool
      @value == other.value
    end

    def hash(hasher)
      @value.hash(hasher)
    end
  end

  # Wrapper for byte slices to satisfy DiffableStr.
  struct BytesWrapper
    include DiffableStr

    getter value : Bytes

    def initialize(@value : Bytes)
    end

    def size : Int32
      @value.size.to_i32
    end

    def [](index : Int32) : Char
      @value[index].chr
    end

    def slice(range : Range(Int32, Int32)) : self
      slice = @value[range]?
      BytesWrapper.new(slice || Bytes.new(0))
    end

    def to_s : String
      String.new(@value, "UTF-8", invalid: :skip)
    end

    def ==(other : self) : Bool
      @value == other.value
    end

    def hash(hasher)
      @value.hash(hasher)
    end
  end
end
