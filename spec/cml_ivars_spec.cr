require "./spec_helper"

describe CML::IVar do
  it "wakes readers when typed with Nil" do
    ivar = CML::IVar(Nil).new
    done = Channel(Nil).new

    spawn do
      CML.sync(ivar.read_evt)
      done.send(nil)
    end

    ivar.fill(nil)
    done.receive
  end

  it "allows repeated reads after being filled with Nil" do
    ivar = CML::IVar(Nil).new
    ivar.fill(nil)

    CML.sync(ivar.read_evt).should be_nil
    CML.sync(ivar.read_evt).should be_nil
  end
end
