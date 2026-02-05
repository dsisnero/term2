require "./types"

module Similar
  # Iterator for `DiffOp.iter_changes`.
  class ChangesIter(Old, New, T)
    include Iterator(Change(T))

    @old : Old
    @new : New
    @old_range : Range(Int32, Int32)
    @new_range : Range(Int32, Int32)
    @old_index : Int32
    @new_index : Int32
    @old_i : Int32
    @new_i : Int32
    @tag : DiffTag

    # Creates a new changes iterator.
    def initialize(old : Old, new : New, op : DiffOp)
      tag, old_range, new_range = op.as_tag_tuple
      @old = old
      @new = new
      @old_range = old_range
      @new_range = new_range
      @old_index = old_range.begin
      @new_index = new_range.begin
      @old_i = old_range.begin
      @new_i = new_range.begin
      @tag = tag
    end

    # Returns the next change, or `Iterator::Stop` when done.
    def next : Change(T) | Iterator::Stop
      case @tag
      when DiffTag::Equal
        if @old_i < @old_range.end
          value = @old[@old_i]
          @old_i += 1
          @old_index += 1
          @new_index += 1
          Change(T).new(ChangeTag::Equal, @old_index - 1, @new_index - 1, value)
        else
          stop
        end
      when DiffTag::Delete
        if @old_i < @old_range.end
          value = @old[@old_i]
          @old_i += 1
          @old_index += 1
          Change(T).new(ChangeTag::Delete, @old_index - 1, nil, value)
        else
          stop
        end
      when DiffTag::Insert
        if @new_i < @new_range.end
          value = @new[@new_i]
          @new_i += 1
          @new_index += 1
          Change(T).new(ChangeTag::Insert, nil, @new_index - 1, value)
        else
          stop
        end
      when DiffTag::Replace
        if @old_i < @old_range.end
          value = @old[@old_i]
          @old_i += 1
          @old_index += 1
          Change(T).new(ChangeTag::Delete, @old_index - 1, nil, value)
        elsif @new_i < @new_range.end
          value = @new[@new_i]
          @new_i += 1
          @new_index += 1
          Change(T).new(ChangeTag::Insert, nil, @new_index - 1, value)
        else
          stop
        end
      else
        stop
      end
    end
  end

  # Iterator for `TextDiff.iter_all_changes`.
  class AllChangesIter(Old, New, T)
    include Iterator(Change(T))

    @old : Old
    @new : New
    @ops : Array(DiffOp)
    @current_iter : ChangesIter(Old, New, T)?

    # Creates a new all changes iterator.
    def initialize(old : Old, new : New, ops : Array(DiffOp))
      @old = old
      @new = new
      @ops = ops
      @current_iter = nil
    end

    # Returns the next change, or `Iterator::Stop` when done.
    def next : Change(T) | Iterator::Stop
      loop do
        if iter = @current_iter
          change = iter.next
          if change.is_a?(Iterator::Stop)
            @current_iter = nil
          else
            return change
          end
        end

        if first = @ops.first?
          @current_iter = ChangesIter(Old, New, T).new(@old, @new, first)
          @ops = @ops[1..]
        else
          return stop
        end
      end
    end
  end
end
