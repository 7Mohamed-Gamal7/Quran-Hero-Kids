using Microsoft.EntityFrameworkCore;
using QuranHero.Domain.Children;
using QuranHero.Domain.Study;

namespace QuranHero.Infrastructure.Persistence;

public sealed class QuranHeroDbContext(DbContextOptions<QuranHeroDbContext> options) : DbContext(options)
{
    public DbSet<ChildProfile> ChildProfiles => Set<ChildProfile>();
    public DbSet<StudySession> StudySessions => Set<StudySession>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var child = modelBuilder.Entity<ChildProfile>();
        child.ToTable("child_profiles");
        child.HasKey(profile => profile.Id);
        child.Property(profile => profile.OwnerUid).HasMaxLength(128).IsRequired();
        child.Property(profile => profile.Name).HasMaxLength(100).IsRequired();
        child.Property(profile => profile.AgeBand).HasMaxLength(8);
        child.Property(profile => profile.CreatedAt).IsRequired();
        child.Property(profile => profile.UpdatedAt).IsRequired();
        child.HasIndex(profile => new { profile.OwnerUid, profile.IsArchived });

        var session = modelBuilder.Entity<StudySession>();
        session.ToTable("study_sessions");
        session.HasKey(item => item.Id);
        session.Property(item => item.Kind).HasConversion<string>().HasMaxLength(24).IsRequired();
        session.Property(item => item.DurationSeconds).IsRequired();
        session.Property(item => item.OccurredAt).IsRequired();
        session.Property(item => item.ReceivedAt).IsRequired();
        session.HasIndex(item => new { item.ChildId, item.ClientEventId }).IsUnique();
        session.HasIndex(item => new { item.ChildId, item.OccurredAt });
        session.HasOne<ChildProfile>().WithMany().HasForeignKey(item => item.ChildId).OnDelete(DeleteBehavior.Cascade);
    }
}
