using MediatR;
using IntegradorHub.API.Shared.Domain.Interfaces;
using IntegradorHub.API.Features.Evaluations.GetByProject;

namespace IntegradorHub.API.Features.Evaluations.GetByDocente;

// === QUERY ===
public record GetEvaluationsByDocenteQuery(string DocenteId)
    : IRequest<IEnumerable<EvaluationDto>>;

// === HANDLER ===
public class GetEvaluationsByDocenteHandler
    : IRequestHandler<GetEvaluationsByDocenteQuery, IEnumerable<EvaluationDto>>
{
    private readonly IEvaluationRepository _evaluationRepository;

    public GetEvaluationsByDocenteHandler(IEvaluationRepository evaluationRepository)
    {
        _evaluationRepository = evaluationRepository;
    }

    public async Task<IEnumerable<EvaluationDto>> Handle(
        GetEvaluationsByDocenteQuery request,
        CancellationToken cancellationToken)
    {
        var evaluations = await _evaluationRepository.GetByDocenteIdAsync(request.DocenteId);

        return evaluations
            .OrderByDescending(e => e.CreatedAt.ToDateTime())
            .Select(e => new EvaluationDto(
                e.Id,
                e.ProjectId,
                e.DocenteId,
                e.DocenteNombre,
                e.Tipo,
                e.Contenido,
                e.Calificacion,
                e.CreatedAt.ToDateTime(),
                e.EsPublico
            ));
    }
}
