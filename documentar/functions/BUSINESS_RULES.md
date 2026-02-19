# Reglas de Negocio y Validaciones — IntegradorHub.API

> Documento técnico que describe las reglas de negocio implementadas en el backend, extraídas directamente del análisis de handlers, validators y repositorios.

---

## Validaciones de Proyecto (CreateProjectValidator)

### Campos Obligatorios

1. **Título**: No vacío, máximo 100 caracteres (`RuleFor(x => x.Titulo).NotEmpty().MaximumLength(100)`)
2. **Materia**: No vacío (`RuleFor(x => x.Materia).NotEmpty()`)
3. **MateriaId**: No vacío (`RuleFor(x => x.MateriaId).NotEmpty()`)
4. **Ciclo**: Formato `YYYY-N` (regex: `^\d{4}-\d$`, ejemplo: `2024-1`, `2026-2`)
5. **StackTecnologico**: Al menos una tecnología (`Must(x => x.Count > 0)`)

### Validaciones de URLs

6. **RepositorioUrl**: Si se proporciona, debe ser URI absoluta válida
7. **VideoUrl**: Si se proporciona, debe ser URI absoluta válida

### Límites de Equipo

8. **Tamaño máximo**: 5 integrantes totales (líder + 4 invitados máximo)
   - Validación en `CreateProjectValidator`: `RuleFor(x => x.MiembrosIds).Must(x => x.Count <= 4)`
   - Validación en `AddMemberHandler`: Verifica `project.MiembrosIds.Count >= 5`

---

## Reglas de Exclusividad y Permisos

### Creación de Proyectos (CreateProjectHandler)

9. **Rol requerido**: Solo usuarios con `rol = "Alumno"` pueden crear proyectos
10. **Exclusividad de proyecto**: Un alumno NO puede crear proyecto si ya tiene `project_id` asignado
    - Error lanzado: `"Ya perteneces a un equipo. Debes salirte antes de crear uno nuevo."`

### Asignación de Docente

11. **Docente titular opcional**: Si se asigna `docente_id`:
    - El docente debe existir en la base de datos
    - Debe tener `rol = "Docente"` o `rol = "Admin"`
    - Debe estar asignado al grupo del líder (verificado en `asignaciones -> grupos_ids`)
    - Excepción: Rol `Admin` puede ser asignado sin restricción de grupo

### Invitación de Miembros (CreateProjectHandler, AddMemberHandler)

12. **Mismo grupo**: Los miembros invitados DEBEN pertenecer al mismo `grupo_id` que el líder
13. **Sin proyecto previo**: Los invitados NO deben tener `project_id` asignado
    - Error: `"El alumno {nombre} ya tiene un proyecto asignado."`
14. **Búsqueda por email o matrícula**:
    - Si `MemberEmailOrMatricula` contiene `@` → buscar por `email`
    - Si no contiene `@` → buscar por `matricula` dentro del grupo

---

## Gestión de Miembros

### Agregar Miembro (AddMemberHandler)

15. **Permisos**: Solo el líder (`project.lider_id == request.LeaderId`) puede agregar miembros
16. **Campos obligatorios**: `ProjectId`, `MemberEmailOrMatricula`, `LeaderId` (validados por FluentValidation)
17. **Límite verificado**: No agregar si ya hay 5 integrantes

### Remover Miembro (RemoveMemberHandler)

18. **Permisos**: Puede remover:
    - El líder puede remover a cualquier miembro (excepto a sí mismo)
    - Un miembro puede auto-removerse (`request.MemberIdToRemove == request.RequestingUserId`)
19. **Protección del líder**: NO se puede eliminar al líder sin transferir liderazgo
    - Error: `"No se puede eliminar al líder del proyecto. Transfiere el liderazgo o elimina el proyecto."`
20. **Consistencia**: Al remover, se limpia `project_id = null` en el documento del usuario

---

## Edición de Proyectos

### Actualizar Canvas (UpdateCanvasHandler)

21. **Permisos**: Líder o cualquier miembro listado en `miembros_ids` puede editar canvas
22. **Validación**: Verifica que `userId` esté en `lider_id` o en `miembros_ids`

### Actualizar Proyecto (UpdateProjectHandler)

23. **Campos editables**: `titulo`, `video_url`, `canvas_blocks`, `es_publico`
24. **Permisos**: Solo el líder o miembros del proyecto (con `uid` en `lider_id` o `miembros_ids`) pueden actualizar el proyecto.
25. **UpdatedAt automático**: Se actualiza `updated_at` con timestamp actual en cada modificación

---

## Eliminación de Proyectos (DeleteProjectHandler)

26. **Permisos**: Solo el líder puede eliminar el proyecto
27. **Limpieza de referencias**: Al eliminar:
    - Obtiene todos los usuarios afectados (líder + miembros)
    - Limpia `project_id = null` en cada usuario
    - Elimina el documento del proyecto de Firestore
28. **Validación defensiva**: Solo limpia `project_id` si coincide con el proyecto eliminado

---

## Evaluaciones y Calificaciones

### Crear Evaluación (CreateEvaluationHandler) - **ALTA PRIORIDAD**

29. **Proyecto existente**: El `project_id` debe existir en Firestore
30. **Rol y Asignación requeridos**: Solo docentes con `rol = "Docente"` y **asignados al grupo del proyecto** pueden crear evaluaciones.
31. **Tipos válidos**: `"oficial"` o `"sugerencia"` únicamente

### Reglas para Evaluaciones Oficiales (Con Calificación)

32. **Permisos especiales**: Una evaluación oficial SOLO puede ser creada por:
    - **Docente titular**: El `docente_id` asignado directamente al proyecto (`project.DocenteId == request.DocenteId`)
    - **Docente con materia de alta prioridad**: Cualquier docente que tenga asignada una materia marcada con `EsAltaPrioridad = true`
33. **Validación de materias prioritarias**:
    - Sistema verifica todas las asignaciones del docente (`docente.Asignaciones`)
    - Para cada asignación, consulta la materia correspondiente (`IMateriaRepository.GetByIdAsync`)
    - Si encuentra al menos una materia con `materia.EsAltaPrioridad == true`, autoriza evaluación oficial
34. **Calificación obligatoria**:
    - Requiere `calificacion` entre 0 y 100 (entero)
    - Error si está ausente o fuera de rango: `"Las evaluaciones oficiales requieren una calificación entre 0 y 100"`

35. **Error de autorización**: Si el docente no cumple los criterios anteriores:
    - `"Solo el docente titular o asesores con materias prioritarias pueden realizar evaluaciones oficiales."`

### Evaluaciones Sugerencia (Sin Calificación)

36. **Acceso amplio**: Cualquier docente con `rol = "Docente"` puede crear evaluaciones tipo sugerencia
37. **Sin calificación**: Campo `calificacion` debe ser `null` para tipo sugerencia
38. **Propósito**: Retroalimentación, observaciones, sugerencias de mejora

### Consulta de Evaluaciones

39. **Listado por proyecto**: `GetEvaluationsByProjectQuery` retorna todas las evaluaciones de un proyecto
40. **DTO de respuesta**: Incluye `Id`, `ProjectId`, `DocenteId`, `DocenteNombre`, `Tipo`, `Contenido`, `Calificacion`, `CreatedAt`

### Materias de Alta Prioridad

41. **Definición**: Materias marcadas con `EsAltaPrioridad = true` en la entidad `Materia`
42. **Propósito**: Otorgar permisos especiales de evaluación oficial a docentes asesores/especialistas
43. **Casos de uso**: Materias como "Proyecto Integrador", "Tesis", "Práticas Profesionales"
44. **Verificación**: Sistema consulta dinámicamente las materias asignadas al docente para validar permisos

---

## Value Objects y Validaciones Especiales

### Email (Email.cs)

34. **No vacío**: Email no puede ser `null` o vacío
35. **Detección automática de rol**:
    - **Reglas de Negocio Forzadas (Hotfix - ver CHANGELOG_SESSION.md):**
        *   Si el correo es `uzielisaac28@gmail.com` ➔ **SuperAdmin** (Indiscutible).
        *   Si el correo es `Uziel.Pech@utmetropolitana.edu.mx` ➔ **Docente** (Indiscutible).
    - **Alumno**: Patrón `^(\d{8})@utmetropolitana\.edu\.mx$` (8 dígitos al inicio del correo)
    - **Docente**: Patrón `^[a-zA-Z.]+@utmetropolitana\.edu\.mx$` (letras/puntos al inicio, y si no es Alumno)
    - **Admin**: Asignado manualmente por un SuperAdmin (no por patrón de correo).
    - **Invitado**: Cualquier otro email válido o si el dominio no es `utmetropolitana.edu.mx`.
36. **Extracción de matrícula**: Para alumnos, extrae los primeros 8 dígitos como matrícula

---

## Storage y Archivos (StorageController)

### Upload Single File

37. **Tamaño máximo**: 100 MB por archivo
38. **Tipos permitidos**: `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `application/pdf`, `video/mp4`, `video/webm`, `video/quicktime`
39. **Validación**: Rechaza si el archivo no cumple tipo o tamaño

### Upload Multiple Files

40. **Tamaño por archivo**: 10 MB máximo (diferente al single upload)
41. **Respuesta**: Devuelve objeto con arrays `uploaded` (exitosos) y `errors` (fallidos)

---

## Manejo de Errores y Excepciones

42. **KeyNotFoundException**: Cuando un recurso (proyecto, usuario, grupo, etc.) no existe
43. **UnauthorizedAccessException**: Cuando el usuario no tiene permisos para la operación
44. **ArgumentException**: Para validaciones de input (tipo de evaluación inválido, calificación fuera de rango)
45. **InvalidOperationException**: Para violaciones de reglas de negocio (alumno ya tiene proyecto, miembro de otro grupo)

---

## Consistencia de Datos

### Actualizaciones Multi-Entidad

46. **Crear proyecto**: Actualiza `project_id` en usuarios de forma secuencial (no transaccional)
47. **Eliminar proyecto**: Limpia `project_id` de todos los miembros antes de borrar el proyecto
48. **Remover miembro**: Actualiza proyecto Y usuario para mantener consistencia

### Recomendaciones de Mejora

- Implementar transacciones atómicas para operaciones multi-entidad
- Agregar mecanismo de rollback o idempotencia en caso de fallos parciales
- Usar `ClaimsPrincipal` en controllers en lugar de `userId` en body
- Normalizar límites de tamaño de archivos entre endpoints (actualmente 100MB vs 10MB)

---

## Nomenclatura de Campos en Firestore

**IMPORTANTE**: Todos los campos en Firestore usan `snake_case` según los atributos `[FirestoreProperty]`:

- `apellido_paterno`, `apellido_materno` (NO `apellidoPaterno`)
- `grupo_id`, `carrera_id`, `project_id` (NO `grupoId`, `carreraId`)
- `miembros_ids`, `docentes_ids` (NO `miembrosIds`)
- `stack_tecnologico`, `repositorio_url`, `video_url`
- `created_at`, `updated_at`, `is_active`, `is_first_login`

Consultar entidades en `/Shared/Domain/Entities/` para referencias exactas.
