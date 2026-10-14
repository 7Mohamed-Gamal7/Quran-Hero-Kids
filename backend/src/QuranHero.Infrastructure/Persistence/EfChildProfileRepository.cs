using Microsoft.EntityFrameworkCore;
using QuranHero.Application.Children;
using QuranHero.Domain.Children;

namespace QuranHero.Infrastructure.Persistence;

public sealed class EfChildProfileRepository(QuranHeroDbContext db) : IChildProfileRepository
{
    public async Task<IReadOnlyList<ChildProfile>> ListAsync(string ownerUid, bool includeArchived, CancellationToken cancellationToken)
    {
        var query = db.ChildProfiles.Where(profile => profile.OwnerUid == ownerUid);
        if (!includeArchived) query = query.Where(profile => !profile.IsArchived);
        return await query.OrderBy(profile => profile.CreatedAt).ToListAsync(cancellationToken);
    }

    public Task<ChildProfile?> FindAsync(Guid id, string ownerUid, bool includeArchived, CancellationToken cancellationToken)
    {
        var query = db.ChildProfiles.Where(profile => profile.Id == id && profile.OwnerUid == ownerUid);
        if (!includeArchived) query = query.Where(profile => !profile.IsArchived);
        return query.SingleOrDefaultAsync(cancellationToken);
    }

    public Task AddAsync(ChildProfile profile, CancellationToken cancellationToken)
    {
        return db.ChildProfiles.AddAsync(profile, cancellationToken).AsTask();
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken) => db.SaveChangesAsync(cancellationToken);
}
