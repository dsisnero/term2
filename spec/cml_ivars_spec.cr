require "./spec_helper"

describe CML::IVar do
  it "wakes readers when typed with Nil" do
    ivar = CML::IVar(Nil).new
    done = Channel(Nil).new

    spawn do
      CML.sync(ivar.i_get_evt)
      done.send(nil)
    end

    ivar.i_put(nil)
    done.receive
  end

  it "allows repeated reads after being i_puted with Nil" do
    ivar = CML::IVar(Nil).new
    ivar.i_put(nil)

    CML.sync(ivar.i_get_evt).should be_nil
    CML.sync(ivar.i_get_evt).should be_nil
  end
end
