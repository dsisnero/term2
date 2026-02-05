module Similar::Algorithms
  # A `DiffHook` that combines deletions and insertions to give blocks
  # of maximal length, and replacements when appropriate.
  #
  # It will replace `DiffHook.insert` and `DiffHook.delete` events when
  # possible with `DiffHook.replace` events.  Note that even though the
  # text processing in the crate does not use replace events and always resolves
  # then back to delete and insert, it's useful to always use the replacer to
  # ensure a consistent order of inserts and deletes.  This is why for instance
  # the text diffing automatically uses this hook internally.
  class Replace(D) < DiffHook
    @d : D
    @del : Tuple(Int32, Int32, Int32)?
    @ins : Tuple(Int32, Int32, Int32)?
    @eq : Tuple(Int32, Int32, Int32)?

    # Creates a new replace hook wrapping another hook.
    def initialize(@d : D)
      @del = nil
      @ins = nil
      @eq = nil
    end

    # Extracts the inner hook.
    def inner : D
      @d
    end

    # Consumes the hook and returns the inner hook.
    def into_inner : D
      @d
    end

    private def flush_eq : Nil
      if eq = @eq
        @d.equal(eq[0], eq[1], eq[2])
        @eq = nil
      end
    end

    private def flush_del_ins : Nil
      if del = @del
        if ins = @ins
          @d.replace(del[0], del[1], ins[1], ins[2])
          @del = nil
          @ins = nil
        else
          @d.delete(del[0], del[1], del[2])
          @del = nil
        end
      elsif ins = @ins
        @d.insert(ins[0], ins[1], ins[2])
        @ins = nil
      end
    end

    def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
      flush_del_ins

      if eq = @eq
        # Merge consecutive equal segments
        @eq = {eq[0], eq[1], eq[2] + len}
      else
        @eq = {old_index, new_index, len}
      end
    end

    def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
      flush_eq
      if del = @del
        # Consecutive delete, merge
        @del = {del[0], del[1] + old_len, del[2]}
      else
        @del = {old_index, old_len, new_index}
      end
    end

    def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
      flush_eq
      if ins = @ins
        # Consecutive insert, merge
        @ins = {ins[0], ins[1], ins[2] + new_len}
      else
        @ins = {old_index, new_index, new_len}
      end
    end

    def replace(old_index : Int32, old_len : Int32, new_index : Int32, new_len : Int32) : Nil
      flush_eq
      @d.replace(old_index, old_len, new_index, new_len)
    end

    def finish : Nil
      flush_eq
      flush_del_ins
      @d.finish
    end
  end
end
