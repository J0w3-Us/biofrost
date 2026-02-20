using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.Rate;

// === COMMAND ===
public record RateProjectCommand(
    string ProjectId,
    string UserId,
    int Stars // 1 to 5
) : IRequest<RateProjectResponse>;

public record RateProjectResponse(bool Success, string Message, double NewTotalPoints);

// === HANDLER ===
public class RateProjectHandler : IRequestHandler<RateProjectCommand, RateProjectResponse>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public RateProjectHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<RateProjectResponse> Handle(RateProjectCommand request, CancellationToken cancellationToken)
    {
        // 1. Get Project
        var project = await _projectRepository.GetByIdAsync(request.ProjectId);
        if (project == null)
            throw new KeyNotFoundException("Proyecto no encontrado");

        // 2. Validate User
        // Leader cannot vote for their own project (conflict of interest / spam prevention)
        if (project.LiderId == request.UserId)
            throw new InvalidOperationException("El líder del proyecto no puede votar por su propio proyecto.");

        // 3. Validate Stars
        if (request.Stars < 1 || request.Stars > 5)
            throw new ArgumentException("La calificación debe ser entre 1 y 5 estrellas.");

        // 4. Calculate Points (1 Star = 10 Points)
        int newPoints = request.Stars * 10;
        int previousPoints = 0;

        // 5. Check if User already voted
        if (project.Votantes.ContainsKey(request.UserId))
        {
            // User is changing their vote
            previousPoints = project.Votantes[request.UserId] * 10; // Convert old stars to points
            project.Votantes[request.UserId] = request.Stars; // Update map
        }
        else
        {
            // New Vote
            project.Votantes.Add(request.UserId, request.Stars);
            project.ConteoVotos++;
        }

        // 6. Update Total Score
        // Formula: CurrentTotal - OldUserPoints + NewUserPoints
        project.PuntosTotales = project.PuntosTotales - previousPoints + newPoints;

        // 7. Save Changes
        await _projectRepository.UpdateAsync(project);

        return new RateProjectResponse(true, "Voto registrado correctamente", project.PuntosTotales);
    }
}
