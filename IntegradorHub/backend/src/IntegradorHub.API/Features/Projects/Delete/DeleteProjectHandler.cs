using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.Delete;

// === COMMAND ===
public record DeleteProjectCommand(
    string ProjectId,
    string RequestingUserId // ID del usuario que solicita eliminar (Debe ser el líder)
) : IRequest<DeleteProjectResponse>;

public record DeleteProjectResponse(bool Success, string Message);

// === HANDLER ===
public class DeleteProjectHandler : IRequestHandler<DeleteProjectCommand, DeleteProjectResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public DeleteProjectHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<DeleteProjectResponse> Handle(DeleteProjectCommand request, CancellationToken cancellationToken)
    {
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null) 
            return new DeleteProjectResponse(false, "Proyecto no encontrado");

        // Validar que sea el líder
        if (project.LiderId != request.RequestingUserId)
            throw new UnauthorizedAccessException("Solo el líder puede eliminar el proyecto.");

        // === CRITICAL: Liberar a los miembros ===
        // Si borramos el proyecto sin limpiar ProjectId en los usuarios, quedan "zombies".
        
        // 1. Obtener lista completa de usuarios afectados (Líder + Miembros)
        var usersToRelease = new List<string>(project.MiembrosIds);
        if (!usersToRelease.Contains(project.LiderId)) 
            usersToRelease.Add(project.LiderId);

        foreach (var userId in usersToRelease)
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user != null)
            {
                // Solo limpiar si efectivamente tienen este ProjectId (defensive coding)
                if (user.ProjectId == request.ProjectId)
                {
                    user.ProjectId = null;
                    await _userRepository.UpdateAsync(user);
                }
            }
        }

        // 2. Eliminar Proyecto
        await _projectRepository.DeleteAsync(request.ProjectId);

        return new DeleteProjectResponse(true, "Proyecto eliminado y equipo disuelto exitosamente.");
    }
}
