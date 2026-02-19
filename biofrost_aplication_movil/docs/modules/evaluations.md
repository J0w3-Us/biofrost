# Evaluations

Propósito: Sistema de retroalimentación y calificación de proyectos.

Pantallas:

- `EvaluationsList` — evaluaciones por proyecto.
- `EvaluationForm` — formulario para docentes (tipo `oficial` o `sugerencia`).

Endpoints:

- `POST /api/evaluations` — crear evaluación.
- `GET /api/evaluations/project/{projectId}` — listar evaluaciones de un proyecto.

Reglas de negocio importantes:

- `oficial` solo puede crearla el docente titular o docente con `EsAltaPrioridad`.
- `oficial` requiere `calificacion` numérica 0-100.

Modelos de datos:

- Ver `public/data/evaluations` en: [BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#evaluations)

Enfoque móvil: Sí — formularios de evaluación adaptados para móvil; controles para asegurar entrada válida.

Roles permitidos (UI): `Docente`, `Invitado`. Creación de evaluaciones `oficial` solo mostrada a `Docente` (el backend impone la regla).
