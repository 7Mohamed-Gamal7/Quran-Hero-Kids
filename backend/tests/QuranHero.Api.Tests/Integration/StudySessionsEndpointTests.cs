using System.Net;
using System.Net.Http.Json;
using QuranHero.Api.Tests.Infrastructure;

namespace QuranHero.Api.Tests.Integration;

public sealed class StudySessionsEndpointTests : IClassFixture<IntegrationTestFactory>
{
    private readonly HttpClient _client;

    public StudySessionsEndpointTests(IntegrationTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task RecordSession_IsIdempotentAndScopedToChildOwner()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var otherOwner = $"parent-{Guid.NewGuid():N}";
        using var createChild = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        createChild.Content = JsonContent.Create(new { name = "Child" });
        using var childResponse = await _client.SendAsync(createChild);
        Assert.Equal(HttpStatusCode.Created, childResponse.StatusCode);
        var child = await childResponse.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(child);

        var eventId = Guid.NewGuid();
        var payload = new { clientEventId = eventId, kind = "revision", durationSeconds = 75, occurredAt = DateTimeOffset.UtcNow };
        var path = $"/api/v1/children/{child.Id}/study-sessions";

        using var first = NewRequest(HttpMethod.Post, path, owner);
        first.Content = JsonContent.Create(payload);
        using var firstResponse = await _client.SendAsync(first);
        Assert.Equal(HttpStatusCode.Created, firstResponse.StatusCode);

        using var retry = NewRequest(HttpMethod.Post, path, owner);
        retry.Content = JsonContent.Create(payload);
        using var retryResponse = await _client.SendAsync(retry);
        Assert.Equal(HttpStatusCode.OK, retryResponse.StatusCode);

        using var conflictingRetry = NewRequest(HttpMethod.Post, path, owner);
        conflictingRetry.Content = JsonContent.Create(new { clientEventId = eventId, kind = "revision", durationSeconds = 120, occurredAt = payload.occurredAt });
        using var conflictingResponse = await _client.SendAsync(conflictingRetry);
        Assert.Equal(HttpStatusCode.Conflict, conflictingResponse.StatusCode);

        using var list = await _client.SendAsync(NewRequest(HttpMethod.Get, path, owner));
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        var sessions = await list.Content.ReadFromJsonAsync<IReadOnlyList<SessionResponse>>();
        Assert.NotNull(sessions);
        Assert.Single(sessions);
        Assert.Equal(eventId, sessions[0].ClientEventId);

        using var otherParent = await _client.SendAsync(NewRequest(HttpMethod.Get, path, otherOwner));
        Assert.Equal(HttpStatusCode.NotFound, otherParent.StatusCode);

        using var anonymous = await _client.PostAsJsonAsync(path, payload);
        Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode);
    }

    [Fact]
    public async Task RecordSession_RejectsInvalidKindAndDuration()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        using var createChild = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        createChild.Content = JsonContent.Create(new { name = "Child" });
        using var childResponse = await _client.SendAsync(createChild);
        var child = await childResponse.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(child);

        var path = $"/api/v1/children/{child.Id}/study-sessions";
        using var invalid = NewRequest(HttpMethod.Post, path, owner);
        invalid.Content = JsonContent.Create(new { clientEventId = Guid.NewGuid(), kind = "unknown", durationSeconds = 0, occurredAt = DateTimeOffset.UtcNow });
        using var response = await _client.SendAsync(invalid);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private static HttpRequestMessage NewRequest(HttpMethod method, string uri, string uid)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Add("X-Test-User", uid);
        return request;
    }

    private sealed record ChildResponse(Guid Id, string Name, string? AgeBand, bool IsArchived, DateTime CreatedAt, DateTime UpdatedAt);
    private sealed record SessionResponse(Guid Id, Guid ClientEventId, string Kind, int DurationSeconds, DateTimeOffset OccurredAt, DateTimeOffset ReceivedAt);
}
