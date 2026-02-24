using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Users.UpdateProfilePhoto;

namespace IntegradorHub.API.Features.Users;

[ApiController]
[Route("api/users")]
public class UsersProfileController : ControllerBase
{
    private readonly IMediator _mediator;

    public UsersProfileController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Updates the user's profile photo URL.
    /// The image should already be uploaded to Supabase Storage via /api/storage/upload.
    /// </summary>
    [HttpPut("{userId}/photo")]
    public async Task<IActionResult> UpdateProfilePhoto(string userId, [FromBody] UpdatePhotoRequest request)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return BadRequest(new { error = "User ID is required." });
        }

        if (string.IsNullOrWhiteSpace(request?.FotoUrl))
        {
            return BadRequest(new { error = "Photo URL is required." });
        }

        try
        {
            var result = await _mediator.Send(new UpdateProfilePhotoCommand(userId, request.FotoUrl));
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating profile photo: {ex.Message}");
            return StatusCode(500, new { error = "Error updating profile photo." });
        }
    }
}

public record UpdatePhotoRequest(string FotoUrl);
