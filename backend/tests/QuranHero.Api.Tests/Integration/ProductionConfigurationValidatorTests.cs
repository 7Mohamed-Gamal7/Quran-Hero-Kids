using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using QuranHero.Api.Configuration;
using QuranHero.Infrastructure;
using QuranHero.Infrastructure.Persistence;

namespace QuranHero.Api.Tests.Integration;

public sealed class ProductionConfigurationValidatorTests
{
    [Theory]
    [InlineData("Firebase:ProjectId")]
    [InlineData("ConnectionStrings:QuranHero")]
    public void ProductionRequiresEachMandatorySetting(string missingSetting)
    {
        var settings = ValidProductionSettings();
        settings.Remove(missingSetting);
        var configuration = BuildConfiguration(settings);

        var exception = Assert.Throws<InvalidOperationException>(() =>
            ProductionConfigurationValidator.Validate(configuration, Environment("Production")));

        Assert.Contains(missingSetting, exception.Message);
        Assert.DoesNotContain("quran-hero-test-project", exception.Message);
        Assert.DoesNotContain("Server=localhost", exception.Message);
    }

    [Fact]
    public void ProductionReportsAllMissingSettingsWithoutEchoingValues()
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>());

        var exception = Assert.Throws<InvalidOperationException>(() =>
            ProductionConfigurationValidator.Validate(configuration, Environment("Production")));

        Assert.Contains("Firebase:ProjectId", exception.Message);
        Assert.Contains("ConnectionStrings:QuranHero", exception.Message);
    }

    [Theory]
    [InlineData("Development")]
    [InlineData("Testing")]
    public void DevelopmentAndTestingDoNotRequireProductionSettings(string environmentName)
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>());

        var exception = Record.Exception(() =>
            ProductionConfigurationValidator.Validate(configuration, Environment(environmentName)));

        Assert.Null(exception);
    }

    [Fact]
    public void StagingRequiresProductionSettingsToo()
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>());

        var exception = Assert.Throws<InvalidOperationException>(() =>
            ProductionConfigurationValidator.Validate(configuration, Environment("Staging")));

        Assert.Contains("Firebase:ProjectId", exception.Message);
        Assert.Contains("ConnectionStrings:QuranHero", exception.Message);
    }

    [Fact]
    public void ValidProductionSettingsPassValidation()
    {
        var configuration = BuildConfiguration(ValidProductionSettings());

        var exception = Record.Exception(() =>
            ProductionConfigurationValidator.Validate(configuration, Environment("Production")));

        Assert.Null(exception);
    }

    [Fact]
    public void ProductionRejectsSqliteProvider()
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>
        {
            ["Database:Provider"] = "Sqlite",
            ["ConnectionStrings:QuranHero"] = "Data Source=:memory:"
        });
        var services = new ServiceCollection();

        var exception = Assert.Throws<InvalidOperationException>(() =>
            services.AddInfrastructure(configuration, Environment("Production")));

        Assert.Contains("Production environments must use SQL Server/Azure SQL", exception.Message);
    }

    [Theory]
    [InlineData("Development")]
    [InlineData("Testing")]
    public void DevelopmentAndTestingCanUseSqlite(string environmentName)
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>
        {
            ["Database:Provider"] = "Sqlite",
            ["ConnectionStrings:QuranHero"] = "Data Source=:memory:"
        });
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure(configuration, Environment(environmentName));
        using var provider = services.BuildServiceProvider();
        var options = provider.GetRequiredService<DbContextOptions<QuranHeroDbContext>>();

        Assert.Contains(options.Extensions, extension => extension.GetType().Name == "SqliteOptionsExtension");
    }

    [Fact]
    public void ProductionDefaultsToSqlServer()
    {
        var configuration = BuildConfiguration(new Dictionary<string, string?>
        {
            ["ConnectionStrings:QuranHero"] = "Server=localhost;Database=QuranHeroKids;Integrated Security=True;TrustServerCertificate=True"
        });
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure(configuration, Environment("Production"));
        using var provider = services.BuildServiceProvider();
        var options = provider.GetRequiredService<DbContextOptions<QuranHeroDbContext>>();

        Assert.Contains(options.Extensions, extension => extension.GetType().Name == "SqlServerOptionsExtension");
    }

    private static Dictionary<string, string?> ValidProductionSettings() => new()
    {
        ["Firebase:ProjectId"] = "quran-hero-test-project",
        ["ConnectionStrings:QuranHero"] = "Server=localhost;Database=QuranHeroKids;Integrated Security=True;TrustServerCertificate=True"
    };

    private static IConfiguration BuildConfiguration(IDictionary<string, string?> settings) =>
        new ConfigurationBuilder().AddInMemoryCollection(settings).Build();

    private static IHostEnvironment Environment(string environmentName) => new TestHostEnvironment
    {
        EnvironmentName = environmentName,
        ApplicationName = "QuranHero.Api.Tests",
        ContentRootPath = Directory.GetCurrentDirectory(),
        ContentRootFileProvider = new NullFileProvider()
    };

    private sealed class TestHostEnvironment : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = string.Empty;
        public string ApplicationName { get; set; } = string.Empty;
        public string ContentRootPath { get; set; } = string.Empty;
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }
}
