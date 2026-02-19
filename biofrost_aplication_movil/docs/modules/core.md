# Core

Propósito: Servicios compartidos y utilidades que usan todos los módulos.

Contiene:

- Cliente HTTP (configuración de baseUrl, interceptores de token).
- Manejo de sesión: persistencia de token, refresh y logout.
- Inicialización de Firebase (Auth, Storage) y utilitarios comunes.
- Manejo global de errores y log.

Endpoints relevantes:

- Autenticación: [IntegradorHub API Auth](documentar/functions/API_DOCS.md#auth)

Modelos y referencias:

- Modelos de usuario y configuración: [BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

Lecturas recomendadas:

- [documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md](documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md)

Enfoque móvil: Sí — diseñado para usarse desde el cliente Flutter de la app.

Roles permitidos (UI): `Docente`, `Invitado` — el cliente mostrará solo opciones permitidas para estos roles; la autorización final la valida el backend.
