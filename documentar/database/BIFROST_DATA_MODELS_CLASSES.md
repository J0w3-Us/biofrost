---

## 10. MODELOS DE DATOS EN FIRESTORE (IMPLEMENTACIÓN ACTUAL)

Este apartado describe los esquemas de las colecciones principales en Google Firestore, la base de datos utilizada en la implementación actual del proyecto.

### 10.1. Colección: `public/data/users`

Almacena el perfil profesional de alumnos, docentes y super administradores.
*   **ID:** `uid` (ID de usuario de Firebase Auth)
*   **Campos:**
    *   `nombre_completo` (string)
    *   `rol` (string: "Alumno", "Docente", "SuperAdmin", "Invitado")
    *   `email` (string)
    *   `matricula` (string, solo para alumnos)
    *   `grupo_id` (string, solo para alumnos)
    *   `grupos_docente` (array de strings, solo para docentes, IDs de los grupos asignados)
    *   `prioridad_docente` (string, solo para docentes, e.g., "Alta", "Baja")
    *   `avatar_url` (string, opcional)
    *   `created_at` (timestamp)
    *   `updated_at` (timestamp)
    *   `is_first_login` (boolean)

### 10.2. Colección: `public/data/projects`

Repositorio central de proyectos.
*   **ID:** Generado automáticamente (o definido por el sistema)
*   **Campos:**
    *   `titulo` (string)
    *   `slug` (string, identificador URL amigable)
    *   `lider_id` (string, UID del líder del proyecto)
    *   `miembros` (array de strings, UIDs de los miembros del squad)
    *   `grupo_contexto` (string, ID del grupo al que pertenece el proyecto)
    *   `docente_asignado` (string, ID del docente asesor asignado)
    *   `estado` (string: "Borrador", "Privado", "Público", "Histórico")
    *   `content_blocks` (array de objetos, estructura flexible para el contenido del canvas)
        *   Cada objeto puede tener `type` (e.g., "heading", "text", "image", "video", "code"), `content`, `order`, `metadata`.
    *   `stack_tecnico` (array de strings, tecnologías usadas)
    *   `fecha_creacion` (timestamp)
    *   `fecha_ultima_actualizacion` (timestamp)
    *   `calificacion` (number, score promedio)
    *   `comentarios_docente` (string)
    *   `es_publico` (boolean)

### 10.3. Colección: `public/data/evaluations`

Feedback técnico vinculado a proyectos.
*   **ID:** Generado automáticamente
*   **Campos:**
    *   `proyecto_id` (string, ID del proyecto evaluado)
    *   `docente_id` (string, ID del docente evaluador)
    *   `comentario` (string, Markdown, retroalimentación general)
    *   `tipo` (string: "oficial", "sugerencia")
    *   `calificacion` (number, 0-100, solo para tipo "oficial")
    *   `visto_por_equipo` (boolean)
    *   `created_at` (timestamp)
    *   `updated_at` (timestamp)