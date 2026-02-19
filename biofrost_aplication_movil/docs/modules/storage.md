# Storage / Media

Propósito: Subida, gestión y preview de archivos multimedia usados en proyectos.

Endpoints:

- `POST /api/storage/upload` — upload single file (form-data `file`, optional `folder`).
- `POST /api/storage/upload-multiple` — upload multiple files.
- `DELETE /api/storage/{*filePath}` — eliminar archivo.

Recomendaciones:

- Validar tipos y tamaños en cliente antes de upload.
- Usar presigned URLs si el backend lo soporta en el futuro.

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#storage)

Enfoque móvil: Sí — subida desde cámara/galería y manejo de múltiples archivos para proyectos.

Roles permitidos (UI): `Docente`, `Invitado`.
