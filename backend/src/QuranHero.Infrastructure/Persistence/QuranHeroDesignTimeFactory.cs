using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace QuranHero.Infrastructure.Persistence;

public sealed class QuranHeroDesignTimeFactory : IDesignTimeDbContextFactory<QuranHeroDbContext>
{
    public QuranHeroDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__QuranHero")
            ?? "Server=localhost;Database=QuranHeroKids;Integrated Security=true;TrustServerCertificate=True";
        var options = new DbContextOptionsBuilder<QuranHeroDbContext>()
            .UseSqlServer(connectionString)
            .Options;
        return new QuranHeroDbContext(options);
    }
}
