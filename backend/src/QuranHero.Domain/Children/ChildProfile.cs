namespace QuranHero.Domain.Children;

public sealed class ChildProfile
{
    private static readonly HashSet<string> AllowedAgeBands = ["5-7", "8-10", "11-13", "14+"];

    private ChildProfile() { }

    public ChildProfile(string ownerUid, string name, string? ageBand)
    {
        Id = Guid.NewGuid();
        OwnerUid = ownerUid;
        Name = name;
        AgeBand = NormalizeAgeBand(ageBand);
        CreatedAt = DateTime.UtcNow;
        UpdatedAt = CreatedAt;
    }

    public Guid Id { get; private set; }
    public string OwnerUid { get; private set; } = string.Empty;
    public string Name { get; private set; } = string.Empty;
    public string? AgeBand { get; private set; }
    public bool IsArchived { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }

    public void Update(string name, string? ageBand)
    {
        Name = name;
        AgeBand = NormalizeAgeBand(ageBand);
        UpdatedAt = DateTime.UtcNow;
    }

    public void Archive()
    {
        IsArchived = true;
        UpdatedAt = DateTime.UtcNow;
    }

    private static string? NormalizeAgeBand(string? ageBand)
    {
        var normalized = ageBand?.Trim();
        if (string.IsNullOrEmpty(normalized)) return null;
        if (!AllowedAgeBands.Contains(normalized))
            throw new ArgumentException("Unsupported age band.", nameof(ageBand));
        return normalized;
    }
}
