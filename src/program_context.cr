require "cml"

module Term2
  # External cancellation context for Program instances.
  class ProgramContext
    getter cancel_evt : CML::Event(Nil)

    def initialize
      @cancelled = Atomic(Bool).new(false)
      @cancel_var = CML::IVar(Nil).new
      @cancel_evt = @cancel_var.i_get_evt
    end

    def cancel : Nil
      return if @cancelled.swap(true)
      @cancel_var.i_put(nil) rescue nil
    end

    def cancelled? : Bool
      @cancelled.get
    end
  end
end
