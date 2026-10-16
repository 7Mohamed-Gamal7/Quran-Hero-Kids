using System.Net;
using System.Text.Json;
using QuranHero.Api.Tests.Infrastructure;

namespace QuranHero.Api.Tests.Integration;

public sealed class OpenApiContractTests : IClassFixture<IntegrationTestFactory>
{
    private readonly HttpClient _client;

    public OpenApiContractTests(IntegrationTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SwaggerDocument_DescribesRoutesResponsesAndBearerRequirements()
    {
        using var response = await _client.GetAsync("/swagger/v1/swagger.json");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        await using var stream = await response.Content.ReadAsStreamAsync();
        using var document = await JsonDocument.ParseAsync(stream);
        var root = document.RootElement;
        Assert.Equal("Quran Hero Kids API", root.GetProperty("info").GetProperty("title").GetString());
        Assert.Equal("v1", root.GetProperty("info").GetProperty("version").GetString());

        var paths = root.GetProperty("paths");
        var childrenGet = paths.GetProperty("/api/v1/children").GetProperty("get");
        AssertBearerRequired(childrenGet);
        AssertHasResponse(childrenGet, "200");
        AssertHasResponse(childrenGet, "400");
        AssertHasResponse(childrenGet, "401");

        var childCreate = paths.GetProperty("/api/v1/children").GetProperty("post");
        AssertBearerRequired(childCreate);
        AssertHasResponse(childCreate, "201");
        AssertHasResponse(childCreate, "400");
        AssertHasResponse(childCreate, "401");
        AssertResponseSchema(childCreate, "201", "ChildProfileView");

        var childPath = paths.GetProperty("/api/v1/children/{id}");
        AssertHasResponse(childPath.GetProperty("get"), "400");
        AssertHasResponse(childPath.GetProperty("get"), "404");
        AssertHasResponse(childPath.GetProperty("put"), "400");
        AssertHasResponse(childPath.GetProperty("put"), "404");
        AssertHasResponse(childPath.GetProperty("delete"), "204");

        var sessionsPath = paths.GetProperty("/api/v1/children/{childId}/study-sessions");
        var sessionsGet = sessionsPath.GetProperty("get");
        var sessionsPost = sessionsPath.GetProperty("post");
        AssertBearerRequired(sessionsGet);
        AssertBearerRequired(sessionsPost);
        AssertHasResponse(sessionsGet, "400");
        AssertHasResponse(sessionsGet, "404");
        AssertHasResponse(sessionsPost, "201");
        AssertHasResponse(sessionsPost, "400");
        AssertHasResponse(sessionsPost, "401");
        AssertHasResponse(sessionsPost, "404");
        AssertHasResponse(sessionsPost, "409");
        AssertResponseSchema(sessionsPost, "201", "StudySessionView");

        var schemas = root.GetProperty("components").GetProperty("schemas");
        var childRequest = schemas.GetProperty("CreateChildRequest").GetProperty("properties");
        Assert.True(childRequest.TryGetProperty("name", out var nameSchema));
        Assert.Equal(100, nameSchema.GetProperty("maxLength").GetInt32());
        Assert.True(childRequest.TryGetProperty("ageBand", out var ageBandSchema));
        Assert.True(ageBandSchema.TryGetProperty("pattern", out _));

        var sessionRequest = schemas.GetProperty("RecordStudySessionRequest").GetProperty("properties");
        Assert.Equal("uuid", sessionRequest.GetProperty("clientEventId").GetProperty("format").GetString());
        var kindSchema = sessionRequest.GetProperty("kind");
        Assert.Equal("^(memorization|revision|test)$", kindSchema.GetProperty("pattern").GetString());
        var durationSchema = sessionRequest.GetProperty("durationSeconds");
        Assert.Equal(1, durationSchema.GetProperty("minimum").GetInt32());
        Assert.Equal(28800, durationSchema.GetProperty("maximum").GetInt32());
        Assert.Equal("date-time", sessionRequest.GetProperty("occurredAt").GetProperty("format").GetString());

        var healthGet = paths.GetProperty("/health").GetProperty("get");
        AssertHasResponse(healthGet, "200");
        Assert.False(healthGet.TryGetProperty("security", out _),
            "The public health endpoint must not require bearer auth in OpenAPI.");
    }

    private static void AssertBearerRequired(JsonElement operation)
    {
        Assert.True(operation.TryGetProperty("security", out var security));
        Assert.Contains(security.EnumerateArray(), requirement =>
            requirement.TryGetProperty("Bearer", out _));
    }

    private static void AssertHasResponse(JsonElement operation, string statusCode)
    {
        Assert.True(operation.GetProperty("responses").TryGetProperty(statusCode, out _),
            $"Expected OpenAPI operation to document HTTP {statusCode}.");
    }

    private static void AssertResponseSchema(JsonElement operation, string statusCode, string schemaName)
    {
        var response = operation.GetProperty("responses").GetProperty(statusCode);
        var schema = response.GetProperty("content").GetProperty("application/json").GetProperty("schema");
        Assert.Equal($"#/components/schemas/{schemaName}", schema.GetProperty("$ref").GetString());
    }
}
