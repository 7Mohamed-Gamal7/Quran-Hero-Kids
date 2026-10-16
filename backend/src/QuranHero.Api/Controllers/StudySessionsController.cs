using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuranHero.Application.Study;
using QuranHero.Domain.Study;

namespace QuranHero.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/children/{childId:guid}/study-sessions")]
[Produces("application/json")]
public sealed class StudySessionsController(IStudySessionService service) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<StudySessionView>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IReadOnlyList<StudySessionView>>> List(
        Guid childId,
        [FromQuery, Range(1, 100)] int limit = 30,
        CancellationToken cancellationToken = default)
    {
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        var result = await service.ListAsync(ownerUid, childId, limit, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpPost]
    [ProducesResponseType(typeof(StudySessionView), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
    public async Task<ActionResult<StudySessionView>> Record(
        Guid childId,
        RecordStudySessionRequest request,
        CancellationToken cancellationToken)
    {
        if (request.ClientEventId == Guid.Empty)
            return InvalidInput(nameof(request.ClientEventId), "A non-empty client event id is required.");
        if (!Enum.TryParse<StudySessionKind>(request.Kind, ignoreCase: true, out var kind))
            return InvalidInput(nameof(request.Kind), "Kind must be memorization, revision, or test.");
        if (request.DurationSeconds is < 1 or > 28_800)
            return InvalidInput(nameof(request.DurationSeconds), "Duration must be between 1 and 28800 seconds.");
        if (request.OccurredAt is null)
            return InvalidInput(nameof(request.OccurredAt), "OccurredAt is required.");
        if (request.OccurredAt.Value > DateTimeOffset.UtcNow.AddMinutes(5))
            return InvalidInput(nameof(request.OccurredAt), "OccurredAt cannot be more than five minutes in the future.");

        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        var result = await service.RecordAsync(ownerUid, childId,
            new RecordStudySessionCommand(request.ClientEventId, kind, request.DurationSeconds, request.OccurredAt.Value),
            cancellationToken);
        if (result is null) return NotFound();
        if (result.IsConflict)
            return Conflict(new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title = "Idempotency key was already used with a different session payload."
            });
        if (result.WasDuplicate) return Ok(result.Session);
        return CreatedAtAction(nameof(List), new { childId }, result.Session);
    }

    private string? GetOwnerUid() =>
        User.FindFirstValue("user_id") ??
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        User.FindFirstValue("sub");

    private BadRequestObjectResult InvalidInput(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });
}

public sealed record RecordStudySessionRequest
{
    [Required]
    public Guid ClientEventId { get; init; }

    [Required]
    [RegularExpression("^(memorization|revision|test)$", ErrorMessage = "Kind must be memorization, revision, or test.")]
    public string Kind { get; init; } = string.Empty;

    [Range(1, 28800)]
    public int DurationSeconds { get; init; }

    [Required]
    public DateTimeOffset? OccurredAt { get; init; }
}
