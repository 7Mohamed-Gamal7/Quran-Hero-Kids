namespace QuranHero.Domain.Study;

public enum StudySessionKind
{
    Memorization = 1,
    Revision = 2,
    Test = 3
}

public sealed class StudySession
{
    private StudySession() { }

    public StudySession(Guid childId, Guid clientEventId, StudySessionKind kind, int durationSeconds, DateTimeOffset occurredAt)
    {
        if (childId == Guid.Empty) throw new ArgumentException("Child id is required.", nameof(childId));
        if (clientEventId == Guid.Empty) throw new ArgumentException("Client event id is required.", nameof(clientEventId));
        if (durationSeconds is < 1 or > 28_800) throw new ArgumentOutOfRangeException(nameof(durationSeconds));

        Id = Guid.NewGuid();
        ChildId = childId;
        ClientEventId = clientEventId;
        Kind = kind;
        DurationSeconds = durationSeconds;
        OccurredAt = occurredAt.UtcDateTime;
        ReceivedAt = DateTime.UtcNow;
    }

    public Guid Id { get; private set; }
    public Guid ChildId { get; private set; }
    public Guid ClientEventId { get; private set; }
    public StudySessionKind Kind { get; private set; }
    public int DurationSeconds { get; private set; }
    public DateTime OccurredAt { get; private set; }
    public DateTime ReceivedAt { get; private set; }
}
