using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetByTeacher;

// === QUERY ===
public record GetProjectsByTeacherQuery(string TeacherId) : IRequest<List<ProjectDto>>;

public record ProjectDto(
    string Id,
    string Titulo,
    string Materia,
    string Estado,
    string LiderId,
    int MembersCount,
    string? ThumbnailUrl,
    string? DocenteId
);

// === HANDLER ===
public class GetProjectsByTeacherHandler : IRequestHandler<GetProjectsByTeacherQuery, List<ProjectDto>>
{
    private readonly IProjectRepository _projectRepository;

    public GetProjectsByTeacherHandler(IProjectRepository projectRepository)
    {
        _projectRepository = projectRepository;
    }

    public async Task<List<ProjectDto>> Handle(GetProjectsByTeacherQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetByTeacherIdAsync(request.TeacherId);

        return projects.Select(p => new ProjectDto(
            p.Id,
            p.Titulo,
            p.Materia,
            p.Estado,
            p.LiderId,
            p.MiembrosIds?.Count ?? 0,
            p.ThumbnailUrl,
            p.DocenteId
        )).ToList();
    }
}
