require "../spec_helper"

private class SlowIndex
  def initialize(@values : Array(Int32))
  end

  def size : Int32
    @values.size
  end

  def [](index : Int32) : Int32
    sleep 1.millisecond
    @values[index]
  end
end

describe Similar::Algorithms::Myers do
  it "test_deadline_reached" do
    a = (0...100).to_a
    b = (0...100).to_a
    b[10] = 99
    b[50] = 99
    b[25] = 99

    slow_a = SlowIndex.new(a)
    slow_b = SlowIndex.new(b)

    d = Similar::Algorithms::Replace.new(Similar::Algorithms::Capture.new)
    deadline = Similar::DeadlineSupport.duration_to_deadline(50.milliseconds)
    Similar::Algorithms::Myers.diff_deadline(slow_a, 0...a.size, slow_b, 0...b.size, d, deadline)

    ops = d.into_inner.ops
    ops.size.should be >= 1
  end
end
