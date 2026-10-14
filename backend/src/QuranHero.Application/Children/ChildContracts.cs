using QuranHero.Domain.Children;

namespace QuranHero.Application.Children;

public sealed record CreateChildCommand(string Name, string? AgeBand);
public sealed record UpdateChildCommand(string Name, string? AgeBand);
public sealed record ChildProfileView(Guid Id, string Name, string? AgeBand, bool IsArchived, DateTime CreatedAt, DateTime UpdatedAt);

public interface IChildProfileRepository
{
    Task<IReadOnlyList<ChildProfile>> ListAsync(string ownerUid, bool includeArchived, CancellationToken cancellationToken);
    Task<ChildProfile?> FindAsync(Guid id, string ownerUid, bool includeArchived, CancellationToken cancellationToken);
    Task AddAsync(ChildProfile profile, CancellationToken cancellationToken);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}

public interface IChildProfileService
{
    Task<IReadOnlyList<ChildProfileView>> ListAsync(string ownerUid, bool includeArchived, CancellationToken cancellationToken);
    Task<ChildProfileView?> GetAsync(Guid id, string ownerUid, bool includeArchived, CancellationToken cancellationToken);
    Task<ChildProfileView> CreateAsync(string ownerUid, CreateChildCommand command, CancellationToken cancellationToken);
    Task<ChildProfileView?> UpdateAsync(Guid id, string ownerUid, UpdateChildCommand command, CancellationToken cancellationToken);
    Task<bool> ArchiveAsync(Guid id, string ownerUid, CancellationToken cancellationToken);
}
