using System.Net;
using System.Net.Http.Json;
using QuranHero.Api.Tests.Infrastructure;

namespace QuranHero.Api.Tests.Integration;

public sealed class ChildrenEndpointTests : IClassFixture<IntegrationTestFactory>
{
    private readonly HttpClient _client;

    public ChildrenEndpointTests(IntegrationTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Theory]
    [InlineData("GET", "/api/v1/children")]
    [InlineData("POST", "/api/v1/children")]
    [InlineData("GET", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000")]
    [InlineData("PUT", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000")]
    [InlineData("DELETE", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000")]
    [InlineData("POST", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000/archive")]
    [InlineData("GET", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000/study-sessions")]
    [InlineData("POST", "/api/v1/children/123e4567-e89b-42d3-a456-426614174000/study-sessions")]
    public async Task ProtectedEndpoints_RejectAnonymousRequests(string method, string path)
    {
        using var request = new HttpRequestMessage(new HttpMethod(method), path);
        using var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Children_CrudAndArchive_IsolatedByOwner()
    {
        var owner = $"owner-{Guid.NewGuid():N}";
        var otherOwner = $"owner-{Guid.NewGuid():N}";
        using var ownerRequest = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        ownerRequest.Content = JsonContent.Create(new { name = "Aisha", ageBand = "8-10" });

        using var createResponse = await _client.SendAsync(ownerRequest);
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(created);
        Assert.Equal("Aisha", created.Name);
        Assert.Equal("8-10", created.AgeBand);
        Assert.False(created.IsArchived);

        using var listResponse = await _client.SendAsync(NewRequest(HttpMethod.Get, "/api/v1/children", owner));
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var ownerChildren = await listResponse.Content.ReadFromJsonAsync<IReadOnlyList<ChildResponse>>();
        Assert.NotNull(ownerChildren);
        Assert.Single(ownerChildren);
        Assert.Equal(created.Id, ownerChildren[0].Id);

        using var otherListResponse = await _client.SendAsync(NewRequest(HttpMethod.Get, "/api/v1/children", otherOwner));
        var otherChildren = await otherListResponse.Content.ReadFromJsonAsync<IReadOnlyList<ChildResponse>>();
        Assert.Equal(HttpStatusCode.OK, otherListResponse.StatusCode);
        Assert.NotNull(otherChildren);
        Assert.Empty(otherChildren);

        using var forbiddenRead = await _client.SendAsync(NewRequest(HttpMethod.Get, $"/api/v1/children/{created.Id}", otherOwner));
        Assert.Equal(HttpStatusCode.NotFound, forbiddenRead.StatusCode);

        using var updateRequest = NewRequest(HttpMethod.Put, $"/api/v1/children/{created.Id}", owner);
        updateRequest.Content = JsonContent.Create(new { name = "Aisha Updated", ageBand = "8-10" });
        using var updateResponse = await _client.SendAsync(updateRequest);
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        var updated = await updateResponse.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(updated);
        Assert.Equal("Aisha Updated", updated.Name);

        using var forbiddenUpdate = NewRequest(HttpMethod.Put, $"/api/v1/children/{created.Id}", otherOwner);
        forbiddenUpdate.Content = JsonContent.Create(new { name = "Hijack" });
        using var forbiddenUpdateResponse = await _client.SendAsync(forbiddenUpdate);
        Assert.Equal(HttpStatusCode.NotFound, forbiddenUpdateResponse.StatusCode);

        using var archiveResponse = await _client.SendAsync(NewRequest(HttpMethod.Delete, $"/api/v1/children/{created.Id}", owner));
        Assert.Equal(HttpStatusCode.NoContent, archiveResponse.StatusCode);

        using var activeListResponse = await _client.SendAsync(NewRequest(HttpMethod.Get, "/api/v1/children", owner));
        var activeChildren = await activeListResponse.Content.ReadFromJsonAsync<IReadOnlyList<ChildResponse>>();
        Assert.NotNull(activeChildren);
        Assert.Empty(activeChildren);

        using var archivedListResponse = await _client.SendAsync(NewRequest(HttpMethod.Get, "/api/v1/children?includeArchived=true", owner));
        var archivedChildren = await archivedListResponse.Content.ReadFromJsonAsync<IReadOnlyList<ChildResponse>>();
        Assert.NotNull(archivedChildren);
        Assert.Single(archivedChildren);
        Assert.True(archivedChildren[0].IsArchived);
    }

    [Fact]
    public async Task CreateChild_RejectsWhitespaceOnlyName()
    {
        using var request = NewRequest(HttpMethod.Post, "/api/v1/children", $"owner-{Guid.NewGuid():N}");
        request.Content = JsonContent.Create(new { name = "   " });
        using var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateChild_RejectsUnapprovedAgeBand()
    {
        using var request = NewRequest(HttpMethod.Post, "/api/v1/children", $"owner-{Guid.NewGuid():N}");
        request.Content = JsonContent.Create(new { name = "Child", ageBand = "2017" });
        using var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/v1/children?includeArchived=invalid")]
    [InlineData("/api/v1/children/123e4567-e89b-42d3-a456-426614174000?includeArchived=invalid")]
    public async Task InvalidBooleanQuery_ReturnsValidationProblem(string path)
    {
        using var response = await _client.SendAsync(
            NewRequest(HttpMethod.Get, path, $"owner-{Guid.NewGuid():N}"));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ChildName_EnforcesMaximumLengthOnCreateAndUpdate()
    {
        var owner = $"owner-{Guid.NewGuid():N}";
        using var valid = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        valid.Content = JsonContent.Create(new { name = new string('A', 100) });
        using var validResponse = await _client.SendAsync(valid);
        Assert.Equal(HttpStatusCode.Created, validResponse.StatusCode);
        var created = await validResponse.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(created);

        using var tooLong = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        tooLong.Content = JsonContent.Create(new { name = new string('B', 101) });
        using var tooLongResponse = await _client.SendAsync(tooLong);
        Assert.Equal(HttpStatusCode.BadRequest, tooLongResponse.StatusCode);

        using var invalidUpdate = NewRequest(HttpMethod.Put, $"/api/v1/children/{created.Id}", owner);
        invalidUpdate.Content = JsonContent.Create(new { name = new string('C', 101) });
        using var invalidUpdateResponse = await _client.SendAsync(invalidUpdate);
        Assert.Equal(HttpStatusCode.BadRequest, invalidUpdateResponse.StatusCode);
    }

    [Fact]
    public async Task MissingChild_ReturnsNotFoundAcrossChildAndSessionOperations()
    {
        var owner = $"owner-{Guid.NewGuid():N}";
        var id = Guid.NewGuid();
        var childPath = $"/api/v1/children/{id}";
        var sessionsPath = $"{childPath}/study-sessions";

        using var getChild = await _client.SendAsync(NewRequest(HttpMethod.Get, childPath, owner));
        Assert.Equal(HttpStatusCode.NotFound, getChild.StatusCode);

        using var updateChild = NewRequest(HttpMethod.Put, childPath, owner);
        updateChild.Content = JsonContent.Create(new { name = "Valid" });
        using var updateResponse = await _client.SendAsync(updateChild);
        Assert.Equal(HttpStatusCode.NotFound, updateResponse.StatusCode);

        using var deleteChild = await _client.SendAsync(NewRequest(HttpMethod.Delete, childPath, owner));
        Assert.Equal(HttpStatusCode.NotFound, deleteChild.StatusCode);

        using var archiveChild = await _client.SendAsync(NewRequest(HttpMethod.Post, $"{childPath}/archive", owner));
        Assert.Equal(HttpStatusCode.NotFound, archiveChild.StatusCode);

        using var listSessions = await _client.SendAsync(NewRequest(HttpMethod.Get, sessionsPath, owner));
        Assert.Equal(HttpStatusCode.NotFound, listSessions.StatusCode);

        using var recordSession = NewRequest(HttpMethod.Post, sessionsPath, owner);
        recordSession.Content = JsonContent.Create(new
        {
            clientEventId = Guid.NewGuid(),
            kind = "memorization",
            durationSeconds = 60,
            occurredAt = DateTimeOffset.UtcNow
        });
        using var recordResponse = await _client.SendAsync(recordSession);
        Assert.Equal(HttpStatusCode.NotFound, recordResponse.StatusCode);
    }

    private static HttpRequestMessage NewRequest(HttpMethod method, string uri, string uid)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Add("X-Test-User", uid);
        return request;
    }

    private sealed record ChildResponse(Guid Id, string Name, string? AgeBand, bool IsArchived, DateTime CreatedAt, DateTime UpdatedAt);
}
