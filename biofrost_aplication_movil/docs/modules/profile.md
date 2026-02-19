# Profile

Propósito: Visualizar y editar perfil de usuario, avatar, grupo y asignaciones.

Pantallas:

- `ProfileView` — datos del perfil.
- `ProfileEdit` — editar campos y subir avatar.

Integración de datos:

- Usuarios almacenados en `public/data/users` — ver [BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

Endpoints relevantes:

- Auth + endpoints admin para actualizar asignaciones cuando aplique.

Lecturas recomendadas:

- [documentar/database/BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

Enfoque móvil: Sí — edición y subida de avatar pensados para cámara/galería móvil.

Roles permitidos (UI): `Docente`, `Invitado`.
