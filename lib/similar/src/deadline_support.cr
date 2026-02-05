module Similar::DeadlineSupport
  alias Instant = Time::Instant

  def self.deadline_exceeded(deadline : Instant?) : Bool
    return false unless deadline
    Time.instant > deadline
  end

  def self.duration_to_deadline(duration : Time::Span) : Instant?
    Time.instant + duration
  end
end
