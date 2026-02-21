using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Users;

/// <summary>
/// Endpoint público de lectura de usuarios por UID.
/// Consumido por la app móvil Biofrost tras el login con Firebase.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _userRepository;

    public UsersController(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    /// <summary>
    /// Obtiene el perfil completo de un usuario por Firebase UID.
    ///
    /// Consumido por la app móvil en auth_service.dart →
    /// ApiEndpoints.userById(uid) → GET /api/users/{uid}
    /// </summary>
    [HttpGet("{uid}")]
    public async Task<ActionResult<UserProfileDto>> GetByUid(string uid)
    {
        var user = await _userRepository.GetByIdAsync(uid);

        if (user == null)
            return NotFound(new { message = "Usuario no encontrado." });

        return Ok(new UserProfileDto(
            UserId: user.Id,
            Email: user.Email,
            Nombre: user.Nombre,
            ApellidoPaterno: user.ApellidoPaterno,
            ApellidoMaterno: user.ApellidoMaterno,
            Rol: user.Rol,
            FotoUrl: user.FotoUrl,
            GrupoId: user.GrupoId,
            CarreraId: user.CarreraId,
            Matricula: user.Matricula,
            Cedula: null,           // no almacenado en User actualmente
            EspecialidadDocente: user.EspecialidadDocente,
            Profesion: user.Profesion,
            Organizacion: user.Organizacion,
            Asignaciones: user.Asignaciones
        ));
    }
}

/// <summary>
/// DTO de perfil de usuario para la app móvil.
/// Mapea al UserReadModel de Flutter (camelCase) — PascalCase para .NET.
/// </summary>
public record UserProfileDto(
    string UserId,
    string Email,
    string Nombre,
    string? ApellidoPaterno,
    string? ApellidoMaterno,
    string Rol,
    string? FotoUrl,
    string? GrupoId,
    string? CarreraId,
    string? Matricula,
    string? Cedula,
    string? EspecialidadDocente,
    string? Profesion,
    string? Organizacion,
    List<AsignacionDocente>? Asignaciones
);
