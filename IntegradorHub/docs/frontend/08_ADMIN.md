# 08 — Panel de Administración (`features/admin/`)

## Resumen del Módulo

El módulo de administración provee herramientas de gestión para el personal administrativo institucional. Agrupa múltiples sub-paneles para la administración de grupos, carreras, materias, alumnos y docentes.

```
features/admin/
├── pages/
│   ├── AdminPanel.jsx      # Panel principal — gestión de grupos
│   ├── AdminPage.jsx       # Página contenedora del módulo
│   ├── CarrerasPanel.jsx   # Gestión de carreras
│   ├── MateriasPanel.jsx   # Gestión de materias
│   ├── StudentsPanel.jsx   # Gestión de alumnos
│   └── TeachersPanel.jsx   # Gestión de docentes
└── components/
    └── AsignacionSelector.jsx  # Selector de asignaciones
```

> ⚠️ **Acceso restringido:** Todas las páginas verifican que el usuario tenga rol `admin` o `SuperAdmin`. Si no cumple la condición, redirige automáticamente a `/dashboard`.

---

## 1. Panel Principal — `AdminPanel.jsx`

### Ruta: `/admin`
### Roles: `admin`, `SuperAdmin`

Panel central de administración. Muestra la gestión de **grupos** como vista por defecto y provee navegación a los demás sub-paneles.

### Tabs de Navegación

| Tab | Ruta / Acción | Descripción |
|-----|---------------|-------------|
| **Grupos** | Vista local (sin ruta) | Gestión de grupos académicos |
| **Carreras** | `navigate('/admin/carreras')` | Gestión de carreras |
| **Materias** | `navigate('/admin/materias')` | Gestión de materias |
| **Alumnos** | `navigate('/admin/students')` | Gestión de estudiantes |
| **Docentes** | `navigate('/admin/teachers')` | Gestión de profesores |

### Secciones del Panel

#### Header
- Saludo personalizado con el nombre del administrador.
- Avatar con iniciales generadas dinámicamente.
- Menú desplegable al hacer click en el avatar → botón de **Cerrar Sesión**.

#### Tabla de Grupos

Columnas:
| Columna | Descripción |
|---------|-------------|
| Nombre | Identificador del grupo (ej: `5A`, `6B`) |
| Carrera | Carrera académica asignada |
| Turno | `Matutino` o `Vespertino` |
| Ciclo Activo | Ciclo escolar actual (ej: `2024-2`) |
| Acciones | Botones Editar y Eliminar |

### CRUD de Grupos

#### Crear Grupo

```
Click "Nuevo Grupo"
    ↓
Modal con formulario
    ↓
POST /api/admin/groups
    └── Body: { nombre, carrera, turno, cicloActivo }
```

#### Editar Grupo

```
Click Editar (ícono lápiz)
    ↓
Modal prellenado con datos del grupo
    ↓
PUT /api/admin/groups/{id}
    └── Body: { nombre, carrera, turno, cicloActivo }
```

#### Eliminar Grupo

```
Click Eliminar (ícono papelera)
    ↓
confirm() nativo del navegador
    ↓
DELETE /api/admin/groups/{id}
```

### Campos del Formulario de Grupo

| Campo | Tipo | Default | Opciones |
|-------|------|---------|---------|
| `nombre` | `text` | `''` | Libre (ej: `5A`) |
| `carrera` | `select` | `'DSM'` | `DSM` + las de `/api/admin/carreras` |
| `turno` | `select` | `'Matutino'` | `Matutino`, `Vespertino` |
| `cicloActivo` | `text` | `'2024-2'` | Libre (ej: `2026-1`) |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/groups` | Lista todos los grupos |
| `GET` | `/api/admin/carreras` | Lista carreras (para el select) |
| `POST` | `/api/admin/groups` | Crea un nuevo grupo |
| `PUT` | `/api/admin/groups/{id}` | Actualiza un grupo |
| `DELETE` | `/api/admin/groups/{id}` | Elimina un grupo |

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `grupos` | `array` | Lista de grupos del sistema |
| `carreras` | `array` | Lista de carreras disponibles |
| `loading` | `boolean` | Carga inicial de datos |
| `showModal` | `boolean` | Visibilidad del modal de formulario |
| `editingGrupo` | `object\|null` | Grupo en edición (`null` = creación) |
| `formData` | `object` | Datos del formulario activo |
| `error` | `string` | Mensaje de error para el banner |
| `activeTab` | `string` | Tab activo en la navegación |
| `showLogoutMenu` | `boolean` | Visibilidad del menú de avatar |

### Guardia de Acceso (en `useEffect`)

```js
const isAdmin = userData?.rol === 'SuperAdmin' || userData?.rol?.toLowerCase() === 'admin';
if (!isAdmin) {
  navigate('/dashboard');
  return;
}
```

> 📌 **Nota:** La verificación doble (`SuperAdmin` y `admin` case-insensitive) garantiza compatibilidad con variaciones en el campo `rol` del backend.

---

## 2. Gestión de Carreras — `CarrerasPanel.jsx`

### Ruta: `/admin/carreras`
### Roles: `admin`, `SuperAdmin`

CRUD de carreras académicas registradas en el sistema.

### Campos de Carrera

| Campo | Descripción |
|-------|-------------|
| `id` | Clave corta de la carrera (ej: `DSM`, `ISC`) |
| `nombre` | Nombre completo de la carrera |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/carreras` | Lista todas las carreras |
| `POST` | `/api/admin/carreras` | Crea una nueva carrera |
| `PUT` | `/api/admin/carreras/{id}` | Actualiza una carrera |
| `DELETE` | `/api/admin/carreras/{id}` | Elimina una carrera |

---

## 3. Gestión de Materias — `MateriasPanel.jsx`

### Ruta: `/admin/materias`
### Roles: `admin`, `SuperAdmin`

CRUD de materias del plan de estudios. Las materias se asocian a docentes para determinar qué cursos puede asesorar cada profesor.

### Campos de Materia

| Campo | Descripción |
|-------|-------------|
| `id` | Identificador único |
| `nombre` | Nombre de la materia |
| `carreraId` | ID de la carrera a la que pertenece |
| `semestre` | Semestre en que se imparte |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/materias` | Lista todas las materias |
| `POST` | `/api/admin/materias` | Crea una nueva materia |
| `PUT` | `/api/admin/materias/{id}` | Actualiza una materia |
| `DELETE` | `/api/admin/materias/{id}` | Elimina una materia |

---

## 4. Gestión de Alumnos — `StudentsPanel.jsx`

### Ruta: `/admin/students`
### Roles: `admin`, `SuperAdmin`

Visualización y gestión de alumnos registrados. Permite asignar o reasignar grupos.

### Campos del Alumno (listado)

| Campo | Descripción |
|-------|-------------|
| `nombre` | Nombre completo |
| `email` | Correo institucional |
| `matricula` | Matrícula del alumno |
| `grupoId` | Grupo al que pertenece |
| `rol` | Siempre `'Alumno'` |

### Acciones Disponibles

| Acción | Descripción |
|--------|-------------|
| Ver detalle | Muestra información completa del alumno |
| Asignar grupo | Usa `AsignacionSelector` para cambiar el grupo |
| Eliminar (si aplica) | Requiere confirmación |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/students` | Lista todos los alumnos |
| `PUT` | `/api/users/{uid}/group` | Reasigna el grupo del alumno |

---

## 5. Gestión de Docentes — `TeachersPanel.jsx`

### Ruta: `/admin/teachers`
### Roles: `admin`, `SuperAdmin`

Visualización y gestión de docentes registrados. Permite asignar materias y grupos.

### Campos del Docente (listado)

| Campo | Descripción |
|-------|-------------|
| `nombre` | Nombre completo |
| `email` | Correo institucional |
| `cedula` | Cédula profesional |
| `especialidad` | Área de especialización |
| `materiasIds` | IDs de materias asignadas |

### Acciones Disponibles

| Acción | Descripción |
|--------|-------------|
| Ver detalle | Información completa del docente |
| Asignar materias y grupos | Usa `AsignacionSelector` |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/teachers` | Lista todos los docentes |
| `PUT` | `/api/users/{uid}/groups` | Asigna grupos al docente |

---

## 6. Componente `AsignacionSelector.jsx`

### Propósito

Selector reutilizable para asignaciones administrativas (grupos para alumnos, materias + grupos para docentes).

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `type` | `'group' \| 'materia'` | ✅ | Tipo de entidad a asignar |
| `currentValue` | `string \| string[]` | ✅ | Valor(es) actualmente asignado(s) |
| `userId` | `string` | ✅ | UID del usuario a modificar |
| `onSave` | `function` | ✅ | Callback tras guardar exitosamente |
| `multiple` | `boolean` | ❌ | Si permite selección múltiple |

---

## Resumen de Endpoints del Módulo Admin

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/admin/groups` | Listar grupos |
| `POST` | `/api/admin/groups` | Crear grupo |
| `PUT` | `/api/admin/groups/{id}` | Editar grupo |
| `DELETE` | `/api/admin/groups/{id}` | Eliminar grupo |
| `GET` | `/api/admin/carreras` | Listar carreras |
| `POST` | `/api/admin/carreras` | Crear carrera |
| `PUT` | `/api/admin/carreras/{id}` | Editar carrera |
| `DELETE` | `/api/admin/carreras/{id}` | Eliminar carrera |
| `GET` | `/api/admin/materias` | Listar materias |
| `POST` | `/api/admin/materias` | Crear materia |
| `PUT` | `/api/admin/materias/{id}` | Editar materia |
| `DELETE` | `/api/admin/materias/{id}` | Eliminar materia |
| `GET` | `/api/admin/students` | Listar alumnos |
| `GET` | `/api/admin/teachers` | Listar docentes |
| `PUT` | `/api/users/{uid}/group` | Asignar grupo a alumno |
| `PUT` | `/api/users/{uid}/groups` | Asignar grupos a docente |
