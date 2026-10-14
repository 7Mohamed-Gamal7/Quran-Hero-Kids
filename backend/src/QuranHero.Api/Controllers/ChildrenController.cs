using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuranHero.Application.Children;

namespace QuranHero.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/children")]
[Produces("application/json")]
public sealed class ChildrenController(IChildProfileService service) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<ChildProfileView>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<ChildProfileView>>> List(
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        return Ok(await service.ListAsync(ownerUid, includeArchived, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ChildProfileView), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChildProfileView>> Get(
        Guid id,
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        var profile = await service.GetAsync(id, ownerUid, includeArchived, cancellationToken);
        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpPost]
    [ProducesResponseType(typeof(ChildProfileView), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ChildProfileView>> Create(CreateChildRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            ModelState.AddModelError(nameof(request.Name), "Name cannot be blank.");
            return ValidationProblem(ModelState);
        }
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        var profile = await service.CreateAsync(ownerUid, new CreateChildCommand(request.Name, request.AgeBand), cancellationToken);
        return CreatedAtAction(nameof(Get), new { id = profile.Id }, profile);
    }

    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ChildProfileView), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ChildProfileView>> Update(Guid id, UpdateChildRequest request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            ModelState.AddModelError(nameof(request.Name), "Name cannot be blank.");
            return ValidationProblem(ModelState);
        }
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        var profile = await service.UpdateAsync(id, ownerUid, new UpdateChildCommand(request.Name, request.AgeBand), cancellationToken);
        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpPost("{id:guid}/archive")]
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Archive(Guid id, CancellationToken cancellationToken)
    {
        var ownerUid = GetOwnerUid();
        if (ownerUid is null) return Unauthorized();
        return await service.ArchiveAsync(id, ownerUid, cancellationToken) ? NoContent() : NotFound();
    }

    private string? GetOwnerUid() =>
        User.FindFirstValue("user_id") ??
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        User.FindFirstValue("sub");
}

public sealed record CreateChildRequest
{
    [Required]
    [StringLength(100, MinimumLength = 1)]
    public string Name { get; init; } = string.Empty;

    [RegularExpression("^(5-7|8-10|11-13|14\\+)$")]
    public string? AgeBand { get; init; }
}

public sealed record UpdateChildRequest
{
    [Required]
    [StringLength(100, MinimumLength = 1)]
    public string Name { get; init; } = string.Empty;

    [RegularExpression("^(5-7|8-10|11-13|14\\+)$")]
    public string? AgeBand { get; init; }
}
