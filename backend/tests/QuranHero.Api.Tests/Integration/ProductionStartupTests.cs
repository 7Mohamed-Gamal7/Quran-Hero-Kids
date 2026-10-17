using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace QuranHero.Api.Tests.Integration;

public sealed class ProductionStartupTests
{
    [Fact]
    public async Task ProductionStartup_DoesNotRunDatabaseMigrations()
    {
        using var factory = new ProductionApiFactory();
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private sealed class ProductionApiFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Production");
            builder.UseSetting("Firebase:ProjectId", "quran-hero-test-project");
            builder.UseSetting("Database:Provider", "SqlServer");
            builder.UseSetting("ConnectionStrings:QuranHero",
                "Server=127.0.0.1,1;Database=QuranHeroKids;Integrated Security=True;Encrypt=False;Connect Timeout=1");
        }
    }
}
