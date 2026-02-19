# IntegradorHub.API — API Documentation

This document lists the API endpoints available in `IntegradorHub.API` with example request bodies.

> Base URL: http(s)://<host>:<port>

---

## Resumen de Endpoints (Tabla rápida)

| Método | Ruta                                       | Descripción                                                   |
| -----: | ------------------------------------------ | ------------------------------------------------------------- |
|    GET | /api/projects/public                       | Obtener todos los proyectos públicos (galería).               |
|   POST | /api/projects                              | Crear un nuevo proyecto (Alumno líder).                       |
|    GET | /api/projects/group/{groupId}              | Obtener proyectos de un grupo específico.                     |
|    GET | /api/projects/{id}                         | Obtener detalles completos de un proyecto.                    |
|   POST | /api/projects/{id}/members                 | Agregar un miembro al proyecto (solo líder).                  |
| DELETE | /api/projects/{id}/members/{memberId}      | Eliminar un miembro del proyecto.                             |
|    PUT | /api/projects/{id}/canvas                  | Actualizar el canvas (contenido) del proyecto.                |
| DELETE | /api/projects/{id}                         | Eliminar un proyecto (solo líder).                            |
|    PUT | /api/projects/{id}                         | Actualizar proyecto (título, video, canvas, visibilidad).     |
|   POST | /api/evaluations                           | Crear una evaluación / Calificar (docente con validaciones).  |
|    GET | /api/evaluations/project/{projectId}       | Obtener todas las evaluaciones de un proyecto.                |
|   POST | /api/auth/login                            | Login (procesa token Firebase, detecta rol).                  |
|   POST | /api/auth/register                         | Registrar usuario (alumno/docente/admin) con datos completos. |
|   POST | /api/storage/upload                        | Subir un archivo (single) al storage.                         |
|   POST | /api/storage/upload-multiple               | Subir múltiples archivos.                                     |
| DELETE | /api/storage/{\*filePath}                  | Eliminar un archivo del storage (ruta codificada).            |
|    GET | /api/teams/available-students?groupId=     | Obtener alumnos del grupo sin equipo asignado.                |
|    GET | /api/teams/available-teachers?groupId=     | Obtener docentes asignados al grupo.                          |
|   POST | /api/admin/seed-admin                      | Crear usuario admin inicial (seed, uso único).                |
|    GET | /api/admin/users/students?grupoId=         | Listar alumnos (opcional: filtrar por grupo).                 |
|    GET | /api/admin/users/teachers                  | Listar docentes.                                              |
|    PUT | /api/admin/users/students/{userId}         | Actualizar grupo de un alumno.                                |
|    PUT | /api/admin/users/teachers/{userId}         | Actualizar asignaciones de un docente.                        |
|    GET | /api/admin/groups                          | Listar grupos activos.                                        |
|    GET | /api/admin/groups/{id}                     | Obtener grupo por id.                                         |
|   POST | /api/admin/groups                          | Crear un grupo.                                               |
|    PUT | /api/admin/groups/{id}                     | Actualizar un grupo.                                          |
| DELETE | /api/admin/groups/{id}                     | Eliminar (marcar inactivo) un grupo.                          |
|    GET | /api/admin/materias                        | Listar materias (opcional filtrar por carrera).               |
|    GET | /api/admin/materias/by-carrera/{carreraId} | Listar materias por carrera.                                  |
|   POST | /api/admin/materias                        | Crear materia.                                                |
|    PUT | /api/admin/materias/{id}                   | Actualizar materia.                                           |
| DELETE | /api/admin/materias/{id}                   | Eliminar (marcar inactivo) materia.                           |
|    GET | /api/admin/carreras                        | Listar carreras.                                              |
|   POST | /api/admin/carreras                        | Crear carrera.                                                |
| DELETE | /api/admin/carreras/{id}                   | Eliminar carrera.                                             |

> Nota: Esta tabla rápida resume las rutas encontradas en los controladores; la sección abajo contiene descripciones más detalladas, roles y ejemplos.

## Roles usados

| Role            | Descripción                                      | Claim / Notas                                   |
| :-------------- | :----------------------------------------------- | :---------------------------------------------- |
| `Admin`         | Administrador con todos los permisos del sistema | `role=Admin`                                    |
| `Docente`       | Usuario con rol de docente / teacher             | `role=Docente`                                  |
| `Alumno`        | Usuario con rol de estudiante                    | `role=Alumno`                                   |
| `Authenticated` | Cualquier usuario autenticado                    | Debe presentar JWT válido; claim `uid` presente |
| `Public`        | Acceso público (sin autenticación)               | Sin token requerido                             |

### Modelo de autorización

- El API usa autenticación por JWT. Se espera un claim `role` con valores como `Admin`, `Docente`, `Alumno`.
- Para permisos de propietario (owner) se compara el `uid` del token con el `UserId`/propietario del recurso.
- Las filas de `Role` indican roles esperados; la columna `Authorization` (abajo) especifica si se requiere autenticación, claims concretos o comprobación de `owner`.

## Endpoints públicos (Acceso no-admin)

Los siguientes endpoints pueden ser consumidos por usuarios autenticados o públicamente según el caso; no requieren el rol de `Admin`.

### Auth (`/api/auth`)

| Method   | Endpoint             | Description                                      | Role   | Authorization |
| :------- | :------------------- | :----------------------------------------------- | :----- | :------------ |
| **POST** | `/api/auth/login`    | Authentication handling for Firebase users.      | Public | None (public) |
| **POST** | `/api/auth/register` | Registers a new user with extended profile data. | Public | None (public) |

Login example:

```json
{
  "FirebaseUid": "",
  "Email": "<EDIT>",
  "DisplayName": "<EDIT>",
  "PhotoUrl": "<EDIT>"
}
```

Register example (minimal):

```json
{
  "FirebaseUid": "",
  "Email": "<EDIT>",
  "Nombre": "<EDIT>",
  "ApellidoPaterno": "<EDIT>",
  "ApellidoMaterno": "<EDIT>",
  "Rol": "<EDIT>",
  "GrupoId": "",
  "Matricula": "<EDIT>",
  "CarreraId": "",
  "Profesion": "<NULLABLE>",
  "Organizacion": "<NULLABLE>",
  "Asignaciones": [],
  "GruposDocente": [],
  "CarrerasIds": []
}
```

### Projects (`/api/projects`)

| Method     | Endpoint                                | Description                                      | Role                                  | Authorization                                                   |
| :--------- | :-------------------------------------- | :----------------------------------------------- | :------------------------------------ | :-------------------------------------------------------------- |
| **GET**    | `/api/projects/public`                  | Retrieves all public projects for the gallery.   | Public                                | None (public)                                                   |
| **POST**   | `/api/projects`                         | Creates a new project.                           | Authenticated (Alumno/Docente)        | JWT required; `role` ∈ {Alumno,Docente}                         |
| **GET**    | `/api/projects/group/{groupId}`         | Retrieves projects for a specific group.         | Authenticated                         | JWT required; must belong to `groupId` or be `Docente`          |
| **GET**    | `/api/projects/{id}`                    | Retrieves detailed project information.          | Authenticated / Public (if EsPublico) | If `EsPublico` → public; otherwise JWT and member/Docente/Admin |
| **PUT**    | `/api/projects/{id}`                    | Updates project details.                         | Authenticated (owner)                 | JWT required; `uid` must match owner or `role=Admin`            |
| **DELETE** | `/api/projects/{id}`                    | Deletes a project (requires `requestingUserId`). | Authenticated (owner)                 | JWT required; `uid` must match owner or `role=Admin`            |
| **POST**   | `/api/projects/{id}/members`            | Adds a member to the project team.               | Authenticated (owner/leader)          | JWT required; owner/leader or `role=Admin`                      |
| **DELETE** | `/api/projects/{id}/members/{memberId}` | Removes a member (requires `requestingUserId`).  | Authenticated (owner)                 | JWT required; owner or `role=Admin`                             |
| **PUT**    | `/api/projects/{id}/canvas`             | Updates the project's canvas content.            | Authenticated (owner/member)          | JWT required; member of project or owner/Admin                  |

Create project example:

```json
{
  "Titulo": "<EDIT>",
  "Materia": "<EDIT>",
  "MateriaId": "",
  "Ciclo": "<EDIT>",
  "StackTecnologico": [],
  "RepositorioUrl": "<EDIT>",
  "VideoUrl": "<EDIT>",
  "UserId": "",
  "UserGroupId": "",
  "DocenteId": "",
  "MiembrosIds": []
}
```

Add member example:

```json
{
  "LeaderId": "",
  "EmailOrMatricula": "<EDIT>"
}
```

Update project example:

```json
{
  "Titulo": "<EDIT>",
  "VideoUrl": "<EDIT>",
  "CanvasBlocks": [],
  "EsPublico": false
}
```

Update canvas example:

```json
{
  "Blocks": [],
  "UserId": ""
}
```

### Evaluations (`/api/evaluations`)

Las evaluaciones son el mecanismo principal para calificar y retroalimentar proyectos. Existen dos tipos: **oficial** (con calificación numérica) y **sugerencia** (solo comentarios).

| Method   | Endpoint                               | Description                                       | Role                                       | Authorization                                            |
| :------- | :------------------------------------- | :------------------------------------------------ | :----------------------------------------- | :------------------------------------------------------- |
| **POST** | `/api/evaluations`                     | Creates a new evaluation for a project.           | Authenticated (Docente)                    | JWT required; `role=Docente` con validaciones especiales |
| **GET**  | `/api/evaluations/project/{projectId}` | Retrieves all evaluations for a specific project. | Authenticated (project members / docentes) | JWT required; project members or `role=Docente`/`Admin`  |

#### Tipos de Evaluación:

1. **Evaluación Oficial** (`"tipo": "oficial"`)
   - **Solo** pueden crear: Docente titular del proyecto OR Docente con materia de alta prioridad
   - **Requiere**: Calificación numérica entre 0-100
   - **Valida**: Que el docente tenga los permisos necesarios
   - **Efecto**: Calificación oficial del proyecto

2. **Evaluación Sugerencia** (`"tipo": "sugerencia"`)
   - **Pueden crear**: Cualquier docente
   - **No requiere**: Calificación numérica (solo comentarios)
   - **Efecto**: Retroalimentación y observaciones

#### Validaciones Especiales para Evaluaciones Oficiales:

- **Docente Titular**: Si el docente es el asignado directamente al proyecto (`project.DocenteId == docente.Id`)
- **Materia Alta Prioridad**: Si el docente tiene asignada alguna materia marcada con `EsAltaPrioridad = true`
- **Error si**: Docente sin permisos intenta crear evaluación oficial

POST example (Evaluación Oficial):

```json
{
  "ProjectId": "project-001",
  "DocenteId": "docente-001",
  "DocenteNombre": "Dr. Juan Pérez",
  "Tipo": "oficial",
  "Contenido": "Proyecto bien estructurado, cumple con los objetivos de aprendizaje. Buena implementación técnica.",
  "Calificacion": 85
}
```

POST example (Evaluación Sugerencia):

```json
{
  "ProjectId": "project-001",
  "DocenteId": "docente-002",
  "DocenteNombre": "Ing. María López",
  "Tipo": "sugerencia",
  "Contenido": "Sugiero mejorar la documentación del código y agregar más comentarios explicativos.",
  "Calificacion": null
}
```

#### Respuesta de Evaluación:

```json
{
  "Id": "eval-abc123",
  "ProjectId": "project-001",
  "DocenteId": "docente-001",
  "DocenteNombre": "Dr. Juan Pérez",
  "Tipo": "oficial",
  "Contenido": "Proyecto bien estructurado...",
  "Calificacion": 85,
  "CreatedAt": "2026-02-17T14:30:00Z"
}
```

### Storage (`/api/storage`)

| Method     | Endpoint                       | Description                                                   | Role                          | Authorization                                                     |
| :--------- | :----------------------------- | :------------------------------------------------------------ | :---------------------------- | :---------------------------------------------------------------- |
| **POST**   | `/api/storage/upload`          | Uploads a single file (query `folder`). Form field: `file`.   | Authenticated                 | JWT required; user can upload to own folders or permitted folders |
| **POST**   | `/api/storage/upload-multiple` | Uploads multiple files (query `folder`). Form field: `files`. | Authenticated                 | JWT required; user can upload to own folders or permitted folders |
| **DELETE** | `/api/storage/{*filePath}`     | Deletes a file from storage.                                  | Authenticated (owner / Admin) | JWT required; owner of file or `role=Admin`                       |

Note: Use `multipart/form-data` in Postman for upload endpoints. Query `?folder=projects` is supported.

### Teams (`/api/teams`)

| Method  | Endpoint                                    | Description                                    | Role                            | Authorization                           |
| :------ | :------------------------------------------ | :--------------------------------------------- | :------------------------------ | :-------------------------------------- |
| **GET** | `/api/teams/available-students?groupId=...` | Retrieves students without a team for a group. | Authenticated (Docente / Admin) | JWT required; `role=Docente` or `Admin` |
| **GET** | `/api/teams/available-teachers?groupId=...` | Retrieves teachers assigned to a group.        | Authenticated (Admin / Docente) | JWT required; `role=Docente` or `Admin` |

---

## Filtrado por roles

A continuación se listan los endpoints que pueden ser utilizados sin rol de `Admin`, y al final los que requieren explícitamente el rol de `Admin`.

- **Sin requerir rol `Admin` (puede requerir autenticación):**
  - `/api/auth/*` (login, register)
  - `/api/projects/*` (incluye `/api/projects/public`)
  - `/api/evaluations/*`
  - `/api/storage/*` (subida/gestión de archivos para usuarios con permisos)
  - `/api/teams/*` (consultas de estudiantes/teachers disponibles)

- **Requiere rol `Admin`:**
  - `/api/admin/*` (seed-admin)
  - `/api/admin/carreras/*`
  - `/api/admin/groups/*`
  - `/api/admin/materias/*`
  - `/api/admin/users/*`

---

## Admin (`/api/admin`)

| Method   | Endpoint                | Description                                  | Role  |
| :------- | :---------------------- | :------------------------------------------- | :---- |
| **POST** | `/api/admin/seed-admin` | Creates the initial admin user in Firestore. | Admin |

Request example (JSON):

```json
{
  "Uid": "",
  "Email": "<EDIT>"
}
```

---

## Admin - Carreras (`/api/admin/carreras`)

| Method     | Endpoint                   | Description             | Role  |
| :--------- | :------------------------- | :---------------------- | :---- |
| **GET**    | `/api/admin/carreras`      | Retrieves all careers.  | Admin |
| **POST**   | `/api/admin/carreras`      | Creates a new career.   | Admin |
| **DELETE** | `/api/admin/carreras/{id}` | Deletes a career by ID. | Admin |

POST example:

```json
{
  "Nombre": "<EDIT>",
  "Nivel": "<EDIT>"
}
```

---

## Admin - Groups (`/api/admin/groups`)

| Method     | Endpoint                 | Description                       | Role  |
| :--------- | :----------------------- | :-------------------------------- | :---- |
| **GET**    | `/api/admin/groups`      | Retrieves all active groups.      | Admin |
| **GET**    | `/api/admin/groups/{id}` | Retrieves a specific group by ID. | Admin |
| **POST**   | `/api/admin/groups`      | Creates a new group.              | Admin |
| **PUT**    | `/api/admin/groups/{id}` | Updates an existing group.        | Admin |
| **DELETE** | `/api/admin/groups/{id}` | Deletes (soft deletes) a group.   | Admin |

POST / PUT example:

```json
{
  "Nombre": "<EDIT>",
  "Carrera": "<EDIT>",
  "Turno": "<EDIT>",
  "CicloActivo": "<EDIT>"
}
```

---

## Admin - Materias (`/api/admin/materias`)

| Method     | Endpoint                                     | Description                                                 | Role  |
| :--------- | :------------------------------------------- | :---------------------------------------------------------- | :---- |
| **GET**    | `/api/admin/materias`                        | Retrieves all active subjects (optional query `carreraId`). | Admin |
| **GET**    | `/api/admin/materias/by-carrera/{carreraId}` | Retrieves subjects filtered by career ID.                   | Admin |
| **POST**   | `/api/admin/materias`                        | Creates a new subject.                                      | Admin |
| **PUT**    | `/api/admin/materias/{id}`                   | Updates an existing subject.                                | Admin |
| **DELETE** | `/api/admin/materias/{id}`                   | Deletes (soft deletes) a subject.                           | Admin |

POST / PUT example:

```json
{
  "Nombre": "<EDIT>",
  "Clave": "<EDIT>",
  "CarreraId": "",
  "Cuatrimestre": 0,
  "EsAltaPrioridad": false
}
```

---

## Admin - Users (`/api/admin/users`)

| Method  | Endpoint                             | Description                                    | Role  |
| :------ | :----------------------------------- | :--------------------------------------------- | :---- |
| **GET** | `/api/admin/users/students`          | Retrieves students (optional query `grupoId`). | Admin |
| **GET** | `/api/admin/users/teachers`          | Retrieves all teachers.                        | Admin |
| **PUT** | `/api/admin/users/students/{userId}` | Updates a student's group.                     | Admin |
| **PUT** | `/api/admin/users/teachers/{userId}` | Updates a teacher's assignments.               | Admin |

PUT example (update student group):

```json
{
  "GrupoId": ""
}
```

PUT example (update teacher assignments):

```json
{
  "Asignaciones": [{ "CarreraId": "", "MateriaId": "", "GruposIds": [] }]
}
```

---

## Tips to test with Postman

- Start the API and copy the `Now listening on:` host and port.
- Use `GET /api/health` to confirm the server is up.
- Use `Content-Type: application/json` for JSON endpoints.
- For file uploads use `form-data` and select `File` type on the key.

---

## Estructura de Datos y Nomenclatura

### Nombres de Campos en Firestore

**IMPORTANTE**: Todos los documentos en Firestore usan nomenclatura `snake_case` según los atributos `[FirestoreProperty]` en las entidades:

#### User (users collection)

```json
{
  "email": "string",
  "nombre": "string",
  "apellido_paterno": "string",
  "apellido_materno": "string",
  "matricula": "string?",
  "foto_url": "string?",
  "rol": "Alumno|Docente|SuperAdmin|Invitado",
  "grupo_id": "string?",
  "carrera_id": "string?",
  "project_id": "string?",
  "asignaciones": [
    { "carrera_id": "string", "materia_id": "string", "grupos_ids": ["string"] }
  ],
  "profesion": "string?",
  "especialidad_docente": "string?",
  "organizacion": "string?",
  "created_at": "string (ISO 8601)",
  "updated_at": "string (ISO 8601)",
  "is_first_login": "boolean"
}
```

#### Project (projects collection)

```json
{
  "titulo": "string",
  "materia": "string",
  "materia_id": "string",
  "ciclo": "string (format: YYYY-N)",
  "grupo_id": "string",
  "lider_id": "string",
  "miembros_ids": ["string"],
  "docente_id": "string?",
  "estado": "Borrador|EnRevision|Aprobado|Finalizado",
  "stack_tecnologico": ["string"],
  "repositorio_url": "string?",
  "video_url": "string?",
  "demo_url": "string?",
  "thumbnail_url": "string?",
  "canvas_blocks": [
    {
      "id": "string",
      "type": "text|heading|image|video|code",
      "content": "string",
      "order": "number",
      "metadata": {}
    }
  ],
  "created_at": "Timestamp",
  "updated_at": "Timestamp",
  "calificacion": "number? (0-100)",
  "comentarios_docente": "string?",
  "es_publico": "boolean"
}
```

#### Evaluation (evaluations collection)

```json
{
  "project_id": "string",
  "docente_id": "string",
  "docente_nombre": "string",
  "tipo": "oficial|sugerencia",
  "contenido": "string",
  "calificacion": "number? (0-100, solo para tipo oficial)",
  "created_at": "Timestamp",
  "updated_at": "Timestamp"
}
```

#### Group (groups collection)

```json
{
  "nombre": "string",
  "carrera": "string",
  "turno": "Matutino|Vespertino",
  "ciclo_activo": "string (format: YYYY-N)",
  "docentes_ids": ["string"],
  "is_active": "boolean",
  "created_at": "Timestamp"
}
```

#### Materia (materias collection)

```json
{
  "nombre": "string",
  "clave": "string",
  "carrera_id": "string",
  "cuatrimestre": "number (1-10)",
  "is_active": "boolean",
  "es_alta_prioridad": "boolean",
  "created_at": "Timestamp"
}
```

#### Carrera (carreras collection)

```json
{
  "nombre": "string",
  "nivel": "TSU|Ingeniería|Licenciatura",
  "activo": "boolean"
}
```

### Estados de Proyecto (ProjectState Enum)

- `Borrador`: Proyecto en construcción
- `EnRevision`: Enviado para revisión del docente
- `Aprobado`: Aprobado por el docente
- `Finalizado`: Proyecto completado y entregado

### Roles de Usuario (UserRole Enum)

- `Alumno`: Estudiante que puede crear proyectos
- `Docente`: Profesor que evalúa proyectos
- `SuperAdmin`: Administrador del sistema
- `Invitado`: Usuario externo (no implementado completamente)

### Tipos de Evaluación

- `oficial`: Evaluación con calificación numérica (0-100), solo por docente titular
- `sugerencia`: Retroalimentación sin calificación, cualquier docente

---

## Ejemplos de Respuesta Completos

### GET /api/projects/{id} - Success Response

```json
{
  "id": "proj-abc123",
  "titulo": "Sistema de Punto de Venta",
  "materia": "Proyecto Integrador I",
  "materiaId": "mat-001",
  "ciclo": "2026-1",
  "grupoId": "grupo-001",
  "liderId": "user-001",
  "liderNombre": "Ana López",
  "miembros": [
    {
      "id": "user-002",
      "nombre": "Carlos García",
      "email": "20260002@alumno.utmetropolitana.edu.mx"
    }
  ],
  "docenteId": "teacher-001",
  "docenteNombre": "Juan Pérez",
  "estado": "Borrador",
  "stackTecnologico": [".NET 8", "Angular", "Supabase"],
  "repositorioUrl": "https://github.com/utm/pos-system",
  "videoUrl": "https://youtu.be/demo-001",
  "canvasBlocks": [
    {
      "id": "block-001",
      "type": "heading",
      "content": "Descripción del Proyecto",
      "order": 1,
      "metadata": {}
    }
  ],
  "createdAt": "2026-02-15T14:30:00Z",
  "updatedAt": "2026-02-17T09:00:00Z",
  "esPublico": false
}
```

### POST /api/auth/login - Success Response

```json
{
  "userId": "user-abc123",
  "email": "20260001@alumno.utmetropolitana.edu.mx",
  "nombre": "Ana López",
  "rol": "Alumno",
  "isFirstLogin": false,
  "grupoId": "grupo-2026-dsm-a"
}
```

### POST /api/evaluations - Success Response

```json
{
  "success": true,
  "message": "Evaluación creada correctamente",
  "evaluationId": "eval-xyz789"
}
```

---

## Códigos de Estado HTTP

- `200 OK`: Operación exitosa
- `201 Created`: Recurso creado exitosamente
- `204 No Content`: Operación exitosa sin contenido de respuesta (DELETE, PUT)
- `400 Bad Request`: Datos inválidos o violación de reglas de negocio
- `401 Unauthorized`: Token inválido o expirado
- `403 Forbidden`: Usuario autenticado pero sin permisos para la operación
- `404 Not Found`: Recurso no encontrado
- `500 Internal Server Error`: Error del servidor

---

File generated from controllers and entities in `src/IntegradorHub.API/`.
