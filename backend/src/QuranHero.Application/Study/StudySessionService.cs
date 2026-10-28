using QuranHero.Application.Children;
using QuranHero.Domain.Study;

namespace QuranHero.Application.Study;

public sealed class StudySessionService(
    IChildProfileRepository children,
    IStudySessionRepository sessions) : IStudySessionService
{
    public async Task<RecordStudySessionResult?> RecordAsync(
        string ownerUid,
        Guid childId,
        RecordStudySessionCommand command,
        CancellationToken cancellationToken)
    {
        if (await children.FindAsync(childId, ownerUid, includeArchived: false, cancellationToken) is null)
            return null;

        var existing = await sessions.FindByClientEventIdAsync(childId, command.ClientEventId, cancellationToken);
        if (existing is not null)
        {
            var matches = existing.Kind == command.Kind &&
                          existing.DurationSeconds == command.DurationSeconds &&
                          existing.OccurredAt == command.OccurredAt.UtcDateTime;
            return new RecordStudySessionResult(ToView(existing), WasDuplicate: matches, IsConflict: !matches);
        }

        var session = new StudySession(childId, command.ClientEventId, command.Kind, command.DurationSeconds, command.OccurredAt);
        await sessions.AddAsync(session, cancellationToken);
        await sessions.SaveChangesAsync(cancellationToken);
        return new RecordStudySessionResult(ToView(session), WasDuplicate: false);
    }

    public async Task<IReadOnlyList<StudySessionView>?> ListAsync(
        string ownerUid,
        Guid childId,
        int limit,
        CancellationToken cancellationToken)
    {
        if (await children.FindAsync(childId, ownerUid, includeArchived: false, cancellationToken) is null)
            return null;
        var items = await sessions.ListAsync(childId, limit, cancellationToken);
        return items.Select(ToView).ToArray();
    }

    public async Task<StudySessionSummaryView?> GetSummaryAsync(
        string ownerUid,
        Guid childId,
        CancellationToken cancellationToken)
    {
        if (await children.FindAsync(childId, ownerUid, includeArchived: false, cancellationToken) is null)
            return null;

        return await sessions.GetSummaryAsync(childId, cancellationToken);
    }

    private static StudySessionView ToView(StudySession session) => new(
        session.Id,
        session.ClientEventId,
        session.Kind,
        session.DurationSeconds,
        new DateTimeOffset(DateTime.SpecifyKind(session.OccurredAt, DateTimeKind.Utc)),
        new DateTimeOffset(DateTime.SpecifyKind(session.ReceivedAt, DateTimeKind.Utc)));
}
