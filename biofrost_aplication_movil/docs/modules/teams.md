# Teams

Propósito: Crear y administrar equipos, buscar alumnos disponibles y asignar docentes.

Pantallas:

- `TeamBuilder` — crear equipo, agregar miembros.
- `AvailableStudents` — lista de estudiantes sin equipo.

Endpoints:

- `GET /api/teams/available-students?groupId=` — alumnos disponibles.
- `GET /api/teams/available-teachers?groupId=` — docentes asignados.
- Usar también `POST /api/projects/{id}/members` para agregar miembros.

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#teams)

Enfoque móvil: Sí — flujos para crear/editar equipos adaptados a pantallas móviles.

Roles permitidos (UI): `Docente`, `Invitado`.
