# Auth

Propósito: Flujos de autenticación y registro; gestión de roles y primer login.

Pantallas:

- `Login` — ingresar con Firebase (token enviado a `/api/auth/login`).
- `Register` — formulario extendido y llamada a `/api/auth/register`.
- `GroupSelector` — pantalla de setup inicial.

Endpoints:

- `/api/auth/login` — intercambio de token Firebase y creación de sesión en backend.
- `/api/auth/register` — registro con datos extendidos.

Requisitos y reglas:

- Soportar roles: `Alumno`, `Docente`, `Admin`, `Invitado`.
- Persistir `is_first_login` y mostrar flujo de setup si aplica.

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md)
- Frontend auth: [IntegradorHub/frontend/src/features/auth](IntegradorHub/frontend/src/features/auth)

Enfoque móvil: Sí — formularios y flujo pensados para pantalla táctil y sesión persistente en dispositivo.

Roles permitidos (UI): `Docente`, `Invitado`. El flujo de registro puede estar limitado en móvil si se requiere control administrativo (ej. crear alumnos desde admin web).
