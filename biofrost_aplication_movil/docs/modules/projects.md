# Projects

Propósito: CRUD de proyectos, editor de canvas y gestión de miembros.

Pantallas:

- `ProjectsList` — listados públicos y por grupo.
- `ProjectDetail` — detalle con canvas, vídeos, stack y miembros.
- `ProjectEditor` — editor de bloques (guardar `canvas_blocks`).

Endpoints:

- `GET /api/projects/public` — galería pública.
- `POST /api/projects` — crear proyecto.
- `GET /api/projects/{id}` — obtener detalle.
- `PUT /api/projects/{id}` — actualizar (incluye canvas y visibilidad).
- `POST /api/projects/{id}/members` — agregar miembro.
- `DELETE /api/projects/{id}/members/{memberId}` — eliminar miembro.
- `PUT /api/projects/{id}/canvas` — actualizar canvas.

Modelos:

- Ver esquema `public/data/projects` en: [BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

Notas técnicas:

- Canvas: usar estructura de bloques serializables (type, content, order, metadata).
- Media: subir via `/api/storage/upload` y guardar URL en `content_blocks`.

Lecturas recomendadas:

- API docs: [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#projects)
- Frontend projects: [IntegradorHub/frontend/src/features/projects](IntegradorHub/frontend/src/features/projects)

Enfoque móvil: Sí — listas y detalle optimizados para consumo móvil; el editor de canvas en móvil será una versión simplificada del editor web (bloques básicos: heading, text, image, video).

Roles permitidos (UI): `Docente`, `Invitado`. Operaciones de escritura (crear/editar/eliminar) deberán validarse también en backend; el cliente ocultará acciones no permitidas según rol.
