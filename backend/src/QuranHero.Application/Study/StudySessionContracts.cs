using QuranHero.Domain.Study;

namespace QuranHero.Application.Study;

public sealed record RecordStudySessionCommand(
    Guid ClientEventId,
    StudySessionKind Kind,
    int DurationSeconds,
    DateTimeOffset OccurredAt);

public sealed record StudySessionView(
    Guid Id,
    Guid ClientEventId,
    StudySessionKind Kind,
    int DurationSeconds,
    DateTimeOffset OccurredAt,
    DateTimeOffset ReceivedAt);

public sealed record RecordStudySessionResult(StudySessionView Session, bool WasDuplicate, bool IsConflict = false);

public interface IStudySessionRepository
{
    Task<StudySession?> FindByClientEventIdAsync(Guid childId, Guid clientEventId, CancellationToken cancellationToken);
    Task<IReadOnlyList<StudySession>> ListAsync(Guid childId, int limit, CancellationToken cancellationToken);
    Task AddAsync(StudySession session, CancellationToken cancellationToken);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}

public interface IStudySessionService
{
    Task<RecordStudySessionResult?> RecordAsync(string ownerUid, Guid childId, RecordStudySessionCommand command, CancellationToken cancellationToken);
    Task<IReadOnlyList<StudySessionView>?> ListAsync(string ownerUid, Guid childId, int limit, CancellationToken cancellationToken);
}
