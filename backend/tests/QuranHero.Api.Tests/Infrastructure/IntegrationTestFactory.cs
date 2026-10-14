using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Microsoft.Data.Sqlite;
using QuranHero.Infrastructure.Persistence;

namespace QuranHero.Api.Tests.Infrastructure;

public sealed class IntegrationTestFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("Data Source=:memory:");

    public IntegrationTestFactory()
    {
        _connection.Open();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<QuranHeroDbContext>>();
            services.AddSingleton(_connection);
            services.AddDbContext<QuranHeroDbContext>(options => options.UseSqlite(_connection));
            services.AddAuthentication(TestAuthenticationDefaults.Scheme)
                .AddScheme<TestAuthenticationOptions, TestAuthenticationHandler>(TestAuthenticationDefaults.Scheme, _ => { });
            services.PostConfigure<AuthenticationOptions>(options =>
            {
                options.DefaultAuthenticateScheme = TestAuthenticationDefaults.Scheme;
                options.DefaultChallengeScheme = TestAuthenticationDefaults.Scheme;
                options.DefaultScheme = TestAuthenticationDefaults.Scheme;
            });
        });
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) _connection.Dispose();
        base.Dispose(disposing);
    }
}

internal static class TestAuthenticationDefaults
{
    public const string Scheme = "IntegrationTest";
}

internal sealed class TestAuthenticationOptions : AuthenticationSchemeOptions;

internal sealed class TestAuthenticationHandler(
    Microsoft.Extensions.Options.IOptionsMonitor<TestAuthenticationOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder)
    : AuthenticationHandler<TestAuthenticationOptions>(options, logger, encoder)
{
    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("X-Test-User", out var values) || string.IsNullOrWhiteSpace(values))
            return Task.FromResult(AuthenticateResult.NoResult());

        var uid = values.ToString();
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, uid),
            new Claim("sub", uid)
        };
        var identity = new ClaimsIdentity(claims, TestAuthenticationDefaults.Scheme);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, TestAuthenticationDefaults.Scheme);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
