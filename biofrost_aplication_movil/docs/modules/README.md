# Documentación de Módulos - Biofrost Mobile

Carpeta que contiene la documentación por módulo de la aplicación móvil (scaffold y referencias).

Estructura:

- `core.md` - Servicios compartidos, cliente HTTP, auth tokens.
- `auth.md` - Login, registro, flujo de Firebase y endpoints `/api/auth`.
- `projects.md` - CRUD proyectos, canvas, upload media.
- `evaluations.md` - Evaluaciones docentes (oficial / sugerencia).
- `teams.md` - Gestión de equipos / miembros.
- `profile.md` - Perfil de usuario y ajustes.
- `showcase.md` - Galería pública de proyectos.
- `admin.md` - Endpoints admin (opcional en móvil).
- `storage.md` - Subida/descarga de archivos y previews.
- `ui-kit.md` - Componentes reutilizables y tokens de diseño.
- `offline.md` - Estrategia de caché y sincronización.

Fuentes de lectura principales:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md)
- [documentar/database/BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)
- [documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md](documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md)
- Frontend de referencia: [IntegradorHub/frontend/src](IntegradorHub/frontend/src)

Siguiente paso: abrir cada archivo `.md` para detallar endpoints, modelos y pantallas.

Notas sobre alcance y roles:

- En esta versión de la app móvil los módulos están diseñados para un cliente móvil (Flutter).
- Acceso en UI: los flujos expuestos por defecto en móvil estarán restringidos a los roles `Docente` y `Invitado`.
- Las validaciones de autorización definitivas deben ser aplicadas por el backend; el cliente solo oculta o muestra opciones según rol.
