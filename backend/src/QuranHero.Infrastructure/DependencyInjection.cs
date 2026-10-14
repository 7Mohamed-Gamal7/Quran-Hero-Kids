using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using QuranHero.Application.Children;
using QuranHero.Application.Study;
using QuranHero.Infrastructure.Persistence;

namespace QuranHero.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        var provider = configuration["Database:Provider"] ?? (environment.IsDevelopment() || environment.IsEnvironment("Testing") ? "Sqlite" : "SqlServer");
        var connectionString = configuration.GetConnectionString("QuranHero");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing"))
                throw new InvalidOperationException("ConnectionStrings:QuranHero must be configured outside Development and Testing.");
            connectionString = $"Data Source={Path.Combine(Path.GetTempPath(), "quran-hero-kids", "quran-hero-kids.db")}";
        }

        var database = provider.Trim().ToLowerInvariant();
        if (!environment.IsDevelopment() && !environment.IsEnvironment("Testing") && database is not ("sqlserver" or "azuresql"))
            throw new InvalidOperationException("Production environments must use SQL Server/Azure SQL.");

        if (database == "sqlite")
        {
            var databasePath = ExtractDatabasePath(connectionString);
            if (databasePath is not null) Directory.CreateDirectory(Path.GetDirectoryName(databasePath)!);
            services.AddDbContext<QuranHeroDbContext>(options => options.UseSqlite(connectionString));
        }
        else if (database is "sqlserver" or "azuresql")
        {
            services.AddDbContext<QuranHeroDbContext>(options => options.UseSqlServer(connectionString));
        }
        else
        {
            throw new InvalidOperationException($"Unsupported Database:Provider '{provider}'. Use Sqlite or SqlServer.");
        }

        services.AddScoped<IChildProfileRepository, EfChildProfileRepository>();
        services.AddScoped<IStudySessionRepository, EfStudySessionRepository>();
        return services;
    }

    private static string? ExtractDatabasePath(string connectionString)
    {
        var builder = new Microsoft.Data.Sqlite.SqliteConnectionStringBuilder(connectionString);
        return builder.DataSource is { Length: > 0 } dataSource && dataSource != ":memory:" && !dataSource.Contains('|')
            ? Path.GetFullPath(dataSource)
            : null;
    }
}
