# 04 — Módulo de Proyectos (`features/projects/`)

## Resumen del Módulo

El módulo de proyectos provee todo el ciclo de vida de un proyecto integrador: listado, creación, visualización de detalles, edición de documentación en canvas y gestión del equipo.

```
features/projects/
├── pages/
│   ├── ProjectsPage.jsx         # Listado de proyectos con búsqueda
│   └── ProjectEditorPage.jsx    # Editor de canvas de documentación
└── components/
    ├── ProjectCard.jsx          # Tarjeta resumen de proyecto
    ├── CreateProjectForm.jsx    # Formulario de creación (multi-paso)
    ├── ProjectDetailsModal.jsx  # Modal de detalles con tabs
    └── CanvasEditor.jsx         # Editor de bloques de documentación
```

---

## 1. Página de Proyectos — `ProjectsPage.jsx`

### Ruta: `/projects`
### Roles: Todos

Lista y gestión de proyectos del usuario filtrada por rol.

### Comportamiento por Rol

| Rol | Datos que ve | Puede crear |
|-----|-------------|------------|
| `Alumno` | Solo su propio proyecto activo | ✅ Sí |
| `Docente` | Todos los proyectos de su grupo | ❌ No |
| `admin` | Todos los proyectos del grupo | ❌ No |

### Endpoints API

| Método | Endpoint | Rol | Descripción |
|--------|----------|-----|-------------|
| `GET` | `/api/projects/my-project?userId={uid}` | Alumno | Proyecto personal activo |
| `GET` | `/api/projects/group/{grupoId}` | Docente/Admin | Proyectos del grupo |

### Normalización para Alumno

```js
const normalized = {
  id:               p.id || p.Id,
  titulo:           p.titulo || p.Titulo,
  materia:          p.materia || p.Materia,
  estado:           p.estado || p.Estado,
  stackTecnologico: p.stackTecnologico || p.StackTecnologico || [],
  liderId:          p.liderId || p.LiderId,
  createdAt:        p.createdAt || p.CreatedAt,
  docenteId:        p.docenteId || p.DocenteId
};
```

### Filtrado

```js
const filteredProjects = projects.filter(p =>
  p.titulo.toLowerCase().includes(searchQuery.toLowerCase()) ||
  p.liderNombre.toLowerCase().includes(searchQuery.toLowerCase())
);
```

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `projects` | `array` | Lista de proyectos |
| `loading` | `boolean` | Carga inicial |
| `searchQuery` | `string` | Texto de búsqueda |
| `showCreateModal` | `boolean` | Muestra `CreateProjectForm` |
| `selectedProject` | `object\|null` | Proyecto activo en `ProjectDetailsModal` |

### Empty States

| Condición | Mensaje | CTA |
|-----------|---------|-----|
| Sin proyectos + sin búsqueda + Alumno | "Sé el primero en crear un proyecto increíble." | "Crear Proyecto Ahora" |
| Sin resultados con búsqueda | "Intenta con otros términos de búsqueda." | — |

---

## 2. Formulario de Creación — `CreateProjectForm.jsx`

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `onClose` | `function` | ✅ | Cierra el modal |
| `onSuccess` | `function` | ✅ | Callback tras creación exitosa |

### Flujo Multi-Paso

```
Paso 1: Información del Proyecto
  ├── Nombre del proyecto (requerido)
  ├── Materia (select generado desde docentes disponibles)
  ├── Docente Asesor (lista con búsqueda, filtrada por materia)
  └── Video Pitch (opcional, max 100MB, formatos: MP4/WebM/MOV)

Paso 2: Selección del Equipo
  ├── Líder (el usuario actual, no modificable)
  └── Compañeros (multi-selección, máximo 4 adicionales)
      - Búsqueda por nombre o matrícula
```

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/teams/available-teachers?groupId={gid}&carreraId={cid}` | Docentes disponibles |
| `GET` | `/api/teams/available-students?groupId={gid}` | Alumnos disponibles para equipo |
| `POST` | `/api/storage/upload?folder=project-promos` | Upload de video (multipart) |
| `POST` | `/api/projects` | Creación del proyecto |

### Payload de Creación

```javascript
{
  titulo:           string,         // Nombre del proyecto
  materia:          string,         // Nombre de la materia (del docente seleccionado)
  materiaId:        string,         // ID de la materia
  docenteId:        string,         // ID del docente asesor
  ciclo:            '2026-1',       // Ciclo escolar (default)
  userId:           string,         // UID del líder (antes: liderId)
  userGroupId:      string,         // ID del grupo (antes: grupoId)
  stackTecnologico: string[],       // Array de tecnologías (split por coma)
  miembrosIds:      string[],       // IDs de compañeros seleccionados
  videoUrl:         string | null,  // URL del video tras upload
  repositorioUrl:   ''              // Placeholder (evita null estricto en backend)
}
```

> 📌 **Nota de campo:** Los campos `userId` y `userGroupId` fueron renombrados en el DTO del backend (antes eran `liderId` y `grupoId`). El comentario en el código marca esta corrección.

### Validaciones

| Regla | Paso |
|-------|------|
| `titulo` es requerido para avanzar | Paso 1 |
| `docenteId` debe estar seleccionado | Paso 1 (al enviar) |
| Máximo 4 compañeros adicionales (sin contar el líder) | Paso 2 |
| Video: tipo `video/*` y menos de 100MB | Paso 1 |

### Indicador de Carga de Video

```
uploadProgress (0-100%)
    ↓
Barra de progreso visual animada
    ↓
Al completar: URL del video almacenada en videoUrl
```

---

## 3. Tarjeta de Proyecto — `ProjectCard.jsx`

### Propósito

Componente de presentación (presentational). Renderiza un resumen visual de un proyecto en formato tarjeta.

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `project` | `object` | ✅ | Datos del proyecto |
| `onClick` | `function` | ✅ | Handler al hacer click en la tarjeta |

### Datos Mostrados

| Campo | Posición |
|-------|---------|
| `estado` (badge con color) | Header superior derecho |
| `titulo` | Contenido principal |
| `docenteNombre` | Subtítulo |
| `stackTecnologico` (primeras 3 + contador) | Tags |
| `materia` | Footer izquierdo |
| `createdAt` (formateado) | Footer derecho |

### Lógica de Color del Badge de Estado

| Estado | Estilo |
|--------|--------|
| `'Activo'` | Verde (`bg-green-50 text-green-700`) |
| `'Completado'` | Azul (`bg-blue-50 text-blue-700`) |
| Otro | Gris (`bg-gray-50 text-gray-700`) |

### Manejo de Fechas

Soporta dos formatos de timestamp:
- **Firestore Timestamp:** `{ seconds: number }` → `new Date(seconds * 1000)`
- **ISO String / Date:** `new Date(createdAt)`

---

## 4. Modal de Detalles — `ProjectDetailsModal.jsx`

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `project` | `object` | ✅ | Datos iniciales del proyecto |
| `onClose` | `function` | ✅ | Cierra el modal |
| `onUpdate` | `function` | ❌ | Callback para refrescar la lista padre |

### Sistema de Tabs

| Tab | Contenido | Roles que lo ven |
|-----|-----------|-----------------|
| `docs` | `CanvasEditor` en modo solo lectura | Todos |
| `eval` | `EvaluationPanel` del proyecto | Todos |
| `settings` | Ajustes del proyecto | Solo Líder |

### Columna Izquierda (Metadata y Equipo)

**Card de Detalles:**
- Fecha de creación
- Ciclo escolar

**Card de Equipo:**
- Contador de miembros actuales vs. máximo (5)
- Lista de miembros con avatar y rol
- Formulario de agregar miembro (solo para el líder)

### Acciones del Proyecto

Todas las acciones destructivas requieren confirmación del usuario.

| Función | Endpoint | Descripción | Permisos |
|---------|----------|-------------|----------|
| `handleAddMember()` | `POST /api/projects/{id}/members` | Agrega miembro por matrícula | Solo Líder |
| `handleRemoveMember(memberId)` | `DELETE /api/projects/{id}/members/{memberId}` | Elimina miembro | Líder o propio miembro |
| `handleVisibilityToggle()` | `PUT /api/projects/{id}` | Cambia visibilidad pública/privada | Solo Líder |
| `handleUpdateTitle()` | `PUT /api/projects/{id}` | Actualiza título | Solo Líder |
| `handleDeleteProject()` | `DELETE /api/projects/{id}` | Elimina proyecto permanentemente | Solo Líder |

### Optimistic UI

El toggle de visibilidad aplica optimistic update:
```js
// 1. Actualiza estado local inmediatamente
setProject(prev => ({ ...prev, esPublico: newStatus }));
// 2. Llamada al backend
await api.put(...)
// 3. Si falla: revierte
setProject(prev => ({ ...prev, esPublico: !newStatus }));
```

### Normalización Interna

```js
const normalizeProjectData = (data) => {
  // Convierte todas las claves a camelCase (PascalCase → camelCase)
  const normalized = {};
  Object.keys(data).forEach(key => {
    const camelKey = key.charAt(0).toLowerCase() + key.slice(1);
    normalized[camelKey] = data[key];
  });
  // Asegura arrays vacíos para campos de colección
  if (!normalized.members) normalized.members = [];
  if (!normalized.miembrosIds) normalized.miembrosIds = [];
  return normalized;
};
```

---

## 5. Editor de Proyectos — `ProjectEditorPage.jsx`

### Ruta: `/project/:id/editor`
### Roles: Miembros del proyecto

Página dedicada de edición de documentación del proyecto con un editor tipo canvas. Accesible por URL directa o desde el botón "Editar" dentro del modal de detalles.

### Funcionamiento

1. Obtiene el `id` del proyecto desde los URL params (`useParams`).
2. Fetch a `GET /api/projects/{id}` para cargar datos actuales.
3. Normaliza `canvasBlocks` → `canvas` si el campo cambia de nombre.
4. Renderiza el `CanvasEditor` con ref expuesto para guardado manual.

### Barra de Navegación Superior

- **Botón "Volver al Dashboard":** navega a `/dashboard`.
- **Avatares del equipo:** muestra hasta 3 fotos de miembros + contador del resto.
- **Botón "Guardar":** llama a `editorRef.current.save()` y muestra estado de guardado.

### Props expuestos vía `ref` al `CanvasEditor`

| Método | Descripción |
|--------|-------------|
| `save()` | Fuerza el guardado del contenido actual del canvas |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/projects/{id}` | Carga datos del proyecto |
| `PATCH`/`PUT` | `/api/projects/{id}/canvas` | Guarda bloques del canvas (via `CanvasEditor`) |
