require "../types"

module Similar::Algorithms
  # A `DiffHook` that captures all diff operations.
  class Capture < DiffHook
    @ops : Array(Similar::DiffOp)

    # Creates a new capture hook.
    def initialize
      @ops = [] of Similar::DiffOp
    end

    # Creates a new capture hook from an existing array.
    def self.new(ops : Array(Similar::DiffOp))
      instance = new
      instance.ops = ops
      instance
    end

    protected setter ops

    # Converts the capture hook into a vector of ops.
    def ops : Array(Similar::DiffOp)
      @ops
    end

    # Isolate change clusters by eliminating ranges with no changes.
    #
    # This is equivalent to calling `Similar.group_diff_ops` on `Capture.ops`.
    def grouped_ops(n : Int32) : Array(Array(Similar::DiffOp))
      Similar.group_diff_ops(@ops, n)
    end

    # Accesses the captured operations.
    def ops_ref : Array(Similar::DiffOp)
      @ops
    end

    def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
      @ops << Similar::DiffOp::Equal.new(old_index, new_index, len)
    end

    def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
      @ops << Similar::DiffOp::Delete.new(old_index, old_len, new_index)
    end

    def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
      @ops << Similar::DiffOp::Insert.new(old_index, new_index, new_len)
    end

    def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
      @ops << Similar::DiffOp::Replace.new(old_index, old_len, new_index, new_len)
    end
  end
end
