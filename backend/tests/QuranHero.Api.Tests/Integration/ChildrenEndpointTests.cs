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

    [Fact]
    public async Task ProtectedEndpoints_RejectAnonymousRequests()
    {
        using var response = await _client.GetAsync("/api/v1/children");
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

    private static HttpRequestMessage NewRequest(HttpMethod method, string uri, string uid)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Add("X-Test-User", uid);
        return request;
    }

    private sealed record ChildResponse(Guid Id, string Name, string? AgeBand, bool IsArchived, DateTime CreatedAt, DateTime UpdatedAt);
}
