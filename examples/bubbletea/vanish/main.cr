require "../../../src/term2"

module VanishExample
  include Term2::Prelude

  class Model
    include Term2::Model

    property done : Bool = false

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      if msg.is_a?(Term2::KeyMsg)
        @done = true
        return {self, Term2.quit}
      end
      {self, nil}
    end

    def view : Term2::View
      if @done
        Term2::View.new("")
      else
        Term2::View.new("Press any key to quit.\n(When this program quits, it will vanish without a trace.)")
      end
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(VanishExample::Model.new)
end
