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
      opts.add(Term2::WithoutSignalHandler.new)
      opts.add(Term2::WithFilter.new(filter))

      program = Term2::Program(TeaFilterModel).new(model, options: opts)

      (prevent_count + 1).times { program.process_message(Term2::QuitMsg.new) }

      shutdowns.get.should eq(prevent_count)
    end
  end
end
