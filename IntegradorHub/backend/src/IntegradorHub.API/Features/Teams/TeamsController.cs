using MediatR;
using Microsoft.AspNetCore.Mvc;
using IntegradorHub.API.Features.Teams.GetAvailableStudents;
using IntegradorHub.API.Features.Teams.GetAvailableTeachers;

namespace IntegradorHub.API.Features.Teams;

[ApiController]
[Route("api/[controller]")]
public class TeamsController : ControllerBase
{
    private readonly IMediator _mediator;

    public TeamsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    /// <summary>
    /// Retorna alumnos del mismo grupo que NO tienen equipo asignado.
    /// </summary>
    [HttpGet("available-students")]
    public async Task<ActionResult<List<StudentDto>>> GetAvailableStudents([FromQuery] string groupId)
    {
        if (string.IsNullOrEmpty(groupId)) return BadRequest("El groupId es requerido");

        var query = new GetAvailableStudentsQuery(groupId);
        var students = await _mediator.Send(query);
        
        return Ok(students);
    }

    /// <summary>
    /// Retorna docentes asignados a este grupo.
    /// </summary>
    [HttpGet("available-teachers")]
    public async Task<ActionResult<List<TeacherDto>>> GetAvailableTeachers([FromQuery] string groupId)
    {
        if (string.IsNullOrEmpty(groupId)) return BadRequest("El groupId es requerido");

        var query = new GetAvailableTeachersQuery(groupId);
        var teachers = await _mediator.Send(query);
        
        return Ok(teachers);
    }
}
