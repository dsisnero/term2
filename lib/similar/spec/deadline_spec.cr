require "./spec_helper"

class DeadlineBlockHook < Similar::Algorithms::DiffHook
  def equal(old_index : Int32, new_index : Int32, len : Int32) : Nil
  end

  def delete(old_index : Int32, old_len : Int32, new_index : Int32) : Nil
  end

  def insert(old_index : Int32, new_index : Int32, new_len : Int32) : Nil
  end

  def finish : Nil
  end
end

describe Similar::DeadlineSupport do
  it "returns deadline exceeded for past deadline" do
    deadline = Similar::DeadlineSupport.duration_to_deadline(Time::Span.new(nanoseconds: -1))
    Similar::DeadlineSupport.deadline_exceeded(deadline).should be_true
  end

  it "does not exceed future deadline" do
    deadline = Similar::DeadlineSupport.duration_to_deadline(Time::Span.new(nanoseconds: 50_000_000))
    Similar::DeadlineSupport.deadline_exceeded(deadline).should be_false
  end
end

describe Similar::Algorithms::Myers do
  it "respects deadline" do
    old = (0...200).map(&.to_s)
    new = (200...400).map(&.to_s)
    hook = DeadlineBlockHook.new
    deadline = Similar::DeadlineSupport.duration_to_deadline(Time::Span.new(nanoseconds: 1))
    Similar::Algorithms::Myers.diff_deadline(old, 0...old.size, new, 0...new.size, hook, deadline)
  end
end
