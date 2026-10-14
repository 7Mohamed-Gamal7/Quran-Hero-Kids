using QuranHero.Domain.Children;

namespace QuranHero.Application.Children;

public sealed class ChildProfileService(IChildProfileRepository repository) : IChildProfileService
{
    public async Task<IReadOnlyList<ChildProfileView>> ListAsync(string ownerUid, bool includeArchived, CancellationToken cancellationToken)
    {
        var profiles = await repository.ListAsync(ownerUid, includeArchived, cancellationToken);
        return profiles.Select(ToView).ToArray();
    }

    public async Task<ChildProfileView?> GetAsync(Guid id, string ownerUid, bool includeArchived, CancellationToken cancellationToken)
    {
        var profile = await repository.FindAsync(id, ownerUid, includeArchived, cancellationToken);
        return profile is null ? null : ToView(profile);
    }

    public async Task<ChildProfileView> CreateAsync(string ownerUid, CreateChildCommand command, CancellationToken cancellationToken)
    {
        var profile = new ChildProfile(ownerUid, command.Name.Trim(), command.AgeBand);
        await repository.AddAsync(profile, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return ToView(profile);
    }

    public async Task<ChildProfileView?> UpdateAsync(Guid id, string ownerUid, UpdateChildCommand command, CancellationToken cancellationToken)
    {
        var profile = await repository.FindAsync(id, ownerUid, includeArchived: false, cancellationToken);
        if (profile is null) return null;
        profile.Update(command.Name.Trim(), command.AgeBand);
        await repository.SaveChangesAsync(cancellationToken);
        return ToView(profile);
    }

    public async Task<bool> ArchiveAsync(Guid id, string ownerUid, CancellationToken cancellationToken)
    {
        var profile = await repository.FindAsync(id, ownerUid, includeArchived: false, cancellationToken);
        if (profile is null) return false;
        profile.Archive();
        await repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static ChildProfileView ToView(ChildProfile profile) =>
        new(profile.Id, profile.Name, profile.AgeBand, profile.IsArchived, profile.CreatedAt, profile.UpdatedAt);
}
