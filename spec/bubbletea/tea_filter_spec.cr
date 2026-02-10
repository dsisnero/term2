require "../spec_helper"

class TeaFilterModel
  include Term2::Model

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::QuitMsg
      {self, Term2::Cmds.quit}
    else
      {self, nil}
    end
  end

  def view : Term2::View
    Term2.new_view("")
  end
end

describe "Bubbletea parity: filter" do
  it "filters QuitMsg configurable times" do
    [0, 1, 2].each do |prevent_count|
      io = IO::Memory.new
      output_io = IO::Memory.new
      model = TeaFilterModel.new
      shutdowns = Atomic(Int32).new(0)

      # Updated Filter Signature: (Model, Message) -> Message?
      filter = ->(_m : Term2::Model, msg : Term2::Msg) {
        if msg.is_a?(Term2::QuitMsg)
          if shutdowns.get < prevent_count
            shutdowns.add(1)
            # Return nil to suppress the message
            return
          end
        end
        # Return the message as a nullable type
        msg.as(Term2::Msg?)
      }

      # No casting needed if the lambda signature matches
      opts = Term2::ProgramOptions.new
      opts.add(Term2::WithInput.new(io))
      opts.add(Term2::WithOutput.new(output_io))
      opts.add(Term2::WithFilter.new(filter))

      program = Term2::Program(TeaFilterModel).new(model, options: opts)

      spawn do
        # Keep sending quit until it sticks
        while shutdowns.get <= prevent_count
          sleep 1.millisecond
          program.quit

          # Break if the program has actually stopped
          break if program.shutdown_evt.poll.is_a?(CML::Enabled(Nil))
        end
      end

      program.run

      shutdowns.get.should eq(prevent_count)
    end
  end
end
