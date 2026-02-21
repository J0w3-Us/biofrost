using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetPublic;

// === QUERY ===
public record GetPublicProjectsQuery() : IRequest<IEnumerable<PublicProjectDto>>;



// === HANDLER ===
public class GetPublicProjectsHandler : IRequestHandler<GetPublicProjectsQuery, IEnumerable<PublicProjectDto>>
{
    private readonly IProjectRepository _projectRepository;
    private readonly IUserRepository _userRepository;

    public GetPublicProjectsHandler(IProjectRepository projectRepository, IUserRepository userRepository)
    {
        _projectRepository = projectRepository;
        _userRepository = userRepository;
    }

    public async Task<IEnumerable<PublicProjectDto>> Handle(GetPublicProjectsQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetPublicProjectsAsync();

        var result = new List<PublicProjectDto>();
        foreach (var project in projects)
        {
            var leader = await _userRepository.GetByIdAsync(project.LiderId);
            var teacher = !string.IsNullOrEmpty(project.DocenteId) ? await _userRepository.GetByIdAsync(project.DocenteId) : null;
            
            // Extract description from first text block if available
            var description = project.CanvasBlocks?.FirstOrDefault(b => b.Type == "text")?.Content ?? "";

            result.Add(new PublicProjectDto(
                project.Id,
                project.Titulo,
                project.Materia,
                project.Ciclo,
                project.StackTecnologico,
                project.ThumbnailUrl,
                project.RepositorioUrl,
                project.DemoUrl,
                project.VideoUrl,
                leader?.Nombre ?? "Desconocido",
                project.MiembrosIds ?? new List<string>(),
                teacher?.Nombre,
                project.Estado,
                description,
                project.CanvasBlocks ?? new List<CanvasBlock>(),
                project.CreatedAt.ToDateTime(),
                project.Calificacion,
                project.LiderId,
                project.PuntosTotales,
                project.ConteoVotos,
                project.Votantes ?? new Dictionary<string, int>()
            ));
        }

        return result.OrderByDescending(p => p.CreatedAt);
    }
}

public record PublicProjectDto(
    string Id,
    string Titulo,
    string Materia,
    string Ciclo,
    List<string> StackTecnologico,
    string? ThumbnailUrl,
    string? RepositorioUrl,
    string? DemoUrl,
    string? VideoUrl,
    string LiderNombre,
    List<string> MiembrosIds,
    string? DocenteNombre,
    string Estado,
    string Descripcion,
    List<CanvasBlock> Canvas,
    DateTime CreatedAt,
    double? Calificacion,
    string LiderId,
    double PuntosTotales,
    int ConteoVotos,
    Dictionary<string, int> Votantes
);
