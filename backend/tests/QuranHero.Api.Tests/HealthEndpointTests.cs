using System.Net;
using System.Net.Http.Json;
using QuranHero.Api.Tests.Infrastructure;

namespace QuranHero.Api.Tests;

public sealed class HealthEndpointTests : IClassFixture<IntegrationTestFactory>
{
    private readonly HttpClient _client;

    public HealthEndpointTests(IntegrationTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetHealth_ReturnsOkAndHealthyStatus()
    {
        using var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<HealthResponse>();
        Assert.NotNull(body);
        Assert.Equal("ok", body.Status);
    }

    [Fact]
    public async Task GetReadiness_ReturnsOkWhenSqliteDatabaseCanConnect()
    {
        using var response = await _client.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<HealthResponse>();
        Assert.NotNull(body);
        Assert.Equal("ready", body.Status);
    }

    private sealed record HealthResponse(string Status);
}
