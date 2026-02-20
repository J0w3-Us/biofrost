using MediatR;
using IntegradorHub.API.Shared.Domain.Entities;
using IntegradorHub.API.Shared.Domain.Interfaces;

namespace IntegradorHub.API.Features.Projects.GetByGroup;

// === QUERY ===
public record GetProjectsByGroupQuery(string GroupId) : IRequest<List<ProjectDto>>;



// === HANDLER ===
public class GetProjectsByGroupHandler : IRequestHandler<GetProjectsByGroupQuery, List<ProjectDto>>
{
    private readonly IProjectRepository _projectRepository;

    public GetProjectsByGroupHandler(IProjectRepository projectRepository)
    {
        _projectRepository = projectRepository;
    }

    public async Task<List<ProjectDto>> Handle(GetProjectsByGroupQuery request, CancellationToken cancellationToken)
    {
        var projects = await _projectRepository.GetByGroupIdAsync(request.GroupId);
        
        return projects.Select(p => new ProjectDto(
            p.Id,
            p.Titulo,
            p.Materia,
            p.Estado,
            p.StackTecnologico,
            p.LiderId,
            p.MiembrosIds.Count,
            p.ThumbnailUrl,
            p.DocenteId
        )).ToList();
    }
}

public record ProjectDto(
    string Id,
    string Titulo,
    string Materia,
    string Estado,
    List<string> StackTecnologico,
    string LiderId,
    int MembersCount,
    string? ThumbnailUrl,
    string? DocenteId
);
