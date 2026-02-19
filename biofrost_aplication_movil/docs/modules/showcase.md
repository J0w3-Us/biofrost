# Showcase

Propósito: Galería pública de proyectos (acceso sin autenticación para `es_publico`).

Pantallas:

- `ShowcaseList` — listados con filtros y búsqueda.
- `ShowcaseDetail` — ficha pública del proyecto.

Endpoint principal:

- `GET /api/projects/public` — retrieve public gallery.

Notas UI:

- Tarjetas con preview (imagen/video), calificación y etiqueta de materia/stack.

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#projects)

Enfoque móvil: Sí — galería optimizada para scroll móvil, lazy-loading de imágenes/videos.

Roles permitidos (UI): `Docente`, `Invitado` (acceso público para proyectos marcados como `es_publico`).
