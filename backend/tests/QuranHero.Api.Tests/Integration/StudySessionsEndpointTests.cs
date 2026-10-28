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

    [Theory]
    [InlineData("unknown", 60)]
    [InlineData("revision", 0)]
    [InlineData("revision", 28801)]
    public async Task RecordSession_RejectsInvalidKindAndDuration(string kind, int durationSeconds)
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        var path = $"/api/v1/children/{childId}/study-sessions";
        using var invalid = NewRequest(HttpMethod.Post, path, owner);
        invalid.Content = JsonContent.Create(new
        {
            clientEventId = Guid.NewGuid(),
            kind,
            durationSeconds,
            occurredAt = DateTimeOffset.UtcNow
        });
        using var response = await _client.SendAsync(invalid);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData(1)]
    [InlineData(28800)]
    public async Task RecordSession_AcceptsDurationBoundaries(int durationSeconds)
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        using var request = NewRequest(HttpMethod.Post,
            $"/api/v1/children/{childId}/study-sessions", owner);
        request.Content = JsonContent.Create(new
        {
            clientEventId = Guid.NewGuid(),
            kind = "test",
            durationSeconds,
            occurredAt = DateTimeOffset.UtcNow
        });

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var session = await response.Content.ReadFromJsonAsync<SessionResponse>();
        Assert.NotNull(session);
        Assert.Equal(durationSeconds, session.DurationSeconds);
    }

    [Fact]
    public async Task RecordSession_RejectsEmptyEventIdAndMissingOccurredAt()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        var path = $"/api/v1/children/{childId}/study-sessions";

        using var emptyEvent = NewRequest(HttpMethod.Post, path, owner);
        emptyEvent.Content = JsonContent.Create(new
        {
            clientEventId = Guid.Empty,
            kind = "revision",
            durationSeconds = 60,
            occurredAt = DateTimeOffset.UtcNow
        });
        using var emptyEventResponse = await _client.SendAsync(emptyEvent);
        Assert.Equal(HttpStatusCode.BadRequest, emptyEventResponse.StatusCode);

        using var missingTime = NewRequest(HttpMethod.Post, path, owner);
        missingTime.Content = JsonContent.Create(new
        {
            clientEventId = Guid.NewGuid(),
            kind = "revision",
            durationSeconds = 60
        });
        using var missingTimeResponse = await _client.SendAsync(missingTime);
        Assert.Equal(HttpStatusCode.BadRequest, missingTimeResponse.StatusCode);
    }

    [Fact]
    public async Task RecordSession_RejectsOccurredAtTooFarInFuture()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        using var request = NewRequest(HttpMethod.Post,
            $"/api/v1/children/{childId}/study-sessions", owner);
        request.Content = JsonContent.Create(new
        {
            clientEventId = Guid.NewGuid(),
            kind = "revision",
            durationSeconds = 60,
            occurredAt = DateTimeOffset.UtcNow.AddMinutes(5).AddSeconds(1)
        });

        using var response = await _client.SendAsync(request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ListSessions_EnforcesInclusiveLimitRange()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        var path = $"/api/v1/children/{childId}/study-sessions";

        foreach (var validLimit in new[] { 1, 100 })
        {
            using var response = await _client.SendAsync(NewRequest(
                HttpMethod.Get, $"{path}?limit={validLimit}", owner));
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }

        foreach (var invalidLimit in new[] { 0, 101 })
        {
            using var response = await _client.SendAsync(NewRequest(
                HttpMethod.Get, $"{path}?limit={invalidLimit}", owner));
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
    }

    [Fact]
    public async Task GetSessionSummary_AggregatesAllSessionsAndScopesToOwner()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var otherOwner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        var path = $"/api/v1/children/{childId}/study-sessions";

        for (var index = 1; index <= 31; index++)
        {
            using var create = NewRequest(HttpMethod.Post, path, owner);
            create.Content = JsonContent.Create(new
            {
                clientEventId = Guid.NewGuid(),
                kind = "revision",
                durationSeconds = index,
                occurredAt = DateTimeOffset.UtcNow.AddSeconds(-index)
            });
            using var created = await _client.SendAsync(create);
            Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        }

        using var list = await _client.SendAsync(NewRequest(HttpMethod.Get, path, owner));
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);
        var sessions = await list.Content.ReadFromJsonAsync<IReadOnlyList<SessionResponse>>();
        Assert.NotNull(sessions);
        Assert.Equal(30, sessions.Count);

        using var summaryResponse = await _client.SendAsync(
            NewRequest(HttpMethod.Get, $"{path}/summary", owner));
        Assert.Equal(HttpStatusCode.OK, summaryResponse.StatusCode);
        var summary = await summaryResponse.Content.ReadFromJsonAsync<SessionSummaryResponse>();
        Assert.NotNull(summary);
        Assert.Equal(31, summary.SessionCount);
        Assert.Equal(496L, summary.TotalDurationSeconds);

        using var otherParent = await _client.SendAsync(
            NewRequest(HttpMethod.Get, $"{path}/summary", otherOwner));
        Assert.Equal(HttpStatusCode.NotFound, otherParent.StatusCode);

        using var anonymous = await _client.GetAsync($"{path}/summary");
        Assert.Equal(HttpStatusCode.Unauthorized, anonymous.StatusCode);
    }

    [Fact]
    public async Task GetSessionSummary_ReturnsZeroesForChildWithoutSessions()
    {
        var owner = $"parent-{Guid.NewGuid():N}";
        var childId = await CreateChildAsync(owner);
        var path = $"/api/v1/children/{childId}/study-sessions/summary";

        using var response = await _client.SendAsync(NewRequest(HttpMethod.Get, path, owner));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var summary = await response.Content.ReadFromJsonAsync<SessionSummaryResponse>();
        Assert.NotNull(summary);
        Assert.Equal(0, summary.SessionCount);
        Assert.Equal(0L, summary.TotalDurationSeconds);
    }

    private async Task<Guid> CreateChildAsync(string owner)
    {
        using var request = NewRequest(HttpMethod.Post, "/api/v1/children", owner);
        request.Content = JsonContent.Create(new { name = "Child" });
        using var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var child = await response.Content.ReadFromJsonAsync<ChildResponse>();
        Assert.NotNull(child);
        return child.Id;
    }

    private static HttpRequestMessage NewRequest(HttpMethod method, string uri, string uid)
    {
        var request = new HttpRequestMessage(method, uri);
        request.Headers.Add("X-Test-User", uid);
        return request;
    }

    private sealed record ChildResponse(Guid Id, string Name, string? AgeBand, bool IsArchived, DateTime CreatedAt, DateTime UpdatedAt);
    private sealed record SessionResponse(Guid Id, Guid ClientEventId, string Kind, int DurationSeconds, DateTimeOffset OccurredAt, DateTimeOffset ReceivedAt);
    private sealed record SessionSummaryResponse(int SessionCount, long TotalDurationSeconds);
}
