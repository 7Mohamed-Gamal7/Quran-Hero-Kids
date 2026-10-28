using Microsoft.EntityFrameworkCore;
using QuranHero.Application.Study;
using QuranHero.Domain.Study;

namespace QuranHero.Infrastructure.Persistence;

public sealed class EfStudySessionRepository(QuranHeroDbContext db) : IStudySessionRepository
{
    public Task<StudySession?> FindByClientEventIdAsync(Guid childId, Guid clientEventId, CancellationToken cancellationToken) =>
        db.StudySessions.SingleOrDefaultAsync(
            item => item.ChildId == childId && item.ClientEventId == clientEventId,
            cancellationToken);

    public async Task AddAsync(StudySession session, CancellationToken cancellationToken) =>
        await db.StudySessions.AddAsync(session, cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken) => db.SaveChangesAsync(cancellationToken);

    public async Task<IReadOnlyList<StudySession>> ListAsync(Guid childId, int limit, CancellationToken cancellationToken) =>
        await db.StudySessions
            .Where(item => item.ChildId == childId)
            .OrderByDescending(item => item.OccurredAt)
            .ThenByDescending(item => item.Id)
            .Take(limit)
            .ToListAsync(cancellationToken);

    public async Task<StudySessionSummaryView> GetSummaryAsync(Guid childId, CancellationToken cancellationToken)
    {
        var summary = await db.StudySessions
            .Where(item => item.ChildId == childId)
            .GroupBy(_ => 1)
            .Select(sessions => new StudySessionSummaryView(
                sessions.Count(),
                sessions.Sum(item => (long)item.DurationSeconds)))
            .SingleOrDefaultAsync(cancellationToken);

        return summary ?? new StudySessionSummaryView(0, 0);
    }
}
