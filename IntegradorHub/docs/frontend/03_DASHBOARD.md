# 03 — Módulo Dashboard (`features/dashboard/`)

## Resumen del Módulo

El módulo de dashboard provee el layout principal de la aplicación autenticada, la navegación lateral, y cuatro vistas clave: dashboard principal, equipo, calendario y perfil.

```
features/dashboard/
├── components/
│   ├── DashboardLayout.jsx   # Layout con sidebar + outlet
│   └── Sidebar.jsx           # Navegación lateral adaptativa por rol
└── pages/
    ├── DashboardPage.jsx     # Vista principal con proyectos activos
    ├── TeamPage.jsx          # Vista de compañeros y equipo de proyecto
    ├── CalendarPage.jsx      # Calendario de eventos y deadlines
    └── ProfilePage.jsx       # Perfil del usuario autenticado
```

---

## 1. Layout — `DashboardLayout.jsx`

### Ruta: `/*` (dentro de ProtectedRoute)

Componente estructural que define el esqueleto visual de todas las páginas autenticadas.

**Estructura:**

```
+--------------------+---------------------------+
|     Sidebar        |     <Outlet />            |
|   (nav lateral)    |  (contenido de la ruta)   |
|                    |                           |
+--------------------+---------------------------+
```

- **Sidebar:** fijo a la izquierda, ocupa altura completa.
- **Outlet:** área de contenido principal, renderiza la página hija de la ruta activa.

---

## 2. Navegación — `Sidebar.jsx`

### Propósito

Barra lateral de navegación con menú adaptativo según el rol del usuario activo.

### Elementos de Navegación por Rol

| Ruta | Ícono | Roles que lo ven |
|------|-------|-----------------|
| `/dashboard` | LayoutGrid | Todos |
| `/projects` | FolderOpen | Todos |
| `/team` | Users | Alumno, Docente |
| `/evaluations` | Star | Alumno, Docente |
| `/calendar` | Calendar | Todos |
| `/profile` | User | Todos |
| `/admin` | Shield | admin, SuperAdmin |

### Funcionalidades

- **Información de usuario:** Muestra foto de perfil (vía `ui-avatars.com` como fallback), nombre y email.
- **Indicador de ruta activa:** Resalta el ítem de navegación correspondiente a la ruta actual.
- **Logout:** Botón de cierre de sesión que llama a `logout()` del contexto.

### Estado y Lógica

```js
const { userData, logout } = useAuth();
const location = useLocation();

// Determinar ítem activo
const isActive = (path) => location.pathname === path || location.pathname.startsWith(path);
```

---

## 3. Vista Principal — `DashboardPage.jsx`

### Ruta: `/dashboard`

Pantalla de bienvenida con los proyectos activos del usuario. El contenido varía según el rol.

### Comportamiento por Rol

#### Alumno
- Muestra el proyecto activo del alumno (si existe).
- Si no tiene proyecto, muestra CTA para crear uno.
- Botón para abrir el modal de creación de proyecto.

#### Docente
- Muestra todos los proyectos del grupo asignado.
- Cada proyecto puede abrirse en el `ProjectDetailsModal`.

### Endpoints API

| Método | Endpoint | Rol | Descripción |
|--------|----------|-----|-------------|
| `GET` | `/api/projects/my-project?userId={uid}` | Alumno | Proyecto activo del alumno |
| `GET` | `/api/projects/group/{grupoId}` | Docente | Todos los proyectos del grupo |

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `projects` | `array` | Lista de proyectos a mostrar |
| `loading` | `boolean` | Estado de carga inicial |
| `showCreateModal` | `boolean` | Controla visibilidad del modal de creación |
| `selectedProject` | `object\|null` | Proyecto seleccionado para ver detalles |

### Componentes Utilizados

- `ProjectCard` — tarjeta de resumen por proyecto
- `CreateProjectForm` — formulario de creación (en modal)
- `ProjectDetailsModal` — vista detallada del proyecto

---

## 4. Vista de Equipo — `TeamPage.jsx`

### Ruta: `/team`
### Roles: Alumno, Docente

Muestra el equipo del proyecto actual y la lista de compañeros del grupo.

### Secciones de la Vista

#### Panel Izquierdo — Información del Proyecto
- Muestra el proyecto activo del alumno.
- Lista de miembros del equipo con foto de perfil.
- Botón para ver detalles completos del proyecto.

#### Panel Derecho — Compañeros de Grupo
- Lista de todos los alumnos del grupo (excepto el usuario actual).
- Buscador por nombre.
- Indica si cada compañero ya tiene proyecto asignado.

### Normalización de Datos del Backend

```js
// Backend envía PascalCase → Frontend normaliza a camelCase
const estudiante = {
  id: e.id || e.Id,
  nombre: e.nombre || e.Nombre || e.nombreCompleto || e.NombreCompleto,
  email: e.email || e.Email,
  fotoUrl: e.fotoUrl || e.FotoUrl || e.photoURL,
  tieneProyecto: e.tieneProyecto ?? e.TieneProyecto ?? false
};
```

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/projects/my-project?userId={uid}` | Proyecto del alumno actual |
| `GET` | `/api/teams/students?groupId={gid}` | Compañeros del grupo |

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `project` | `object\|null` | Proyecto del usuario |
| `classmates` | `array` | Lista de alumnos del grupo |
| `searchQuery` | `string` | Filtro de búsqueda |
| `loading` | `boolean` | Estado de carga |

---

## 5. Calendario — `CalendarPage.jsx`

### Ruta: `/calendar`
### Roles: Todos

Vista de calendario mensual que muestra eventos y fechas límite relevantes para el usuario.

### Funcionalidades

- **Navegación:** Botones anterior/siguiente para cambiar de mes.
- **Indicadores de eventos:** Los días con eventos muestran un punto de color.
- **Lista lateral:** Muestra los próximos eventos ordenados por fecha.
- **Tipos de evento:** Entregas, presentaciones, evaluaciones, reuniones.

### Estructura del Evento

```typescript
interface Event {
  id: string;
  title: string;
  date: Date | string;
  type: 'entrega' | 'presentacion' | 'evaluacion' | 'reunion';
  projectId?: string;
}
```

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `currentDate` | `Date` | Mes/año actualmente visualizado |
| `events` | `array` | Lista de eventos del período |
| `selectedDay` | `number\|null` | Día seleccionado en el calendario |

> 📌 **Nota:** En la versión actual los eventos pueden provenir del backend o estar generados localmente como placeholders. Verificar el endpoint activo en la implementación.

---

## 6. Perfil de Usuario — `ProfilePage.jsx`

### Ruta: `/profile`
### Roles: Todos

Muestra la información completa del perfil del usuario autenticado con diseño neumórfico.

### Secciones del Perfil

| Sección | Datos Mostrados | Roles |
|---------|----------------|-------|
| Información Personal | Nombre, email, foto | Todos |
| Datos Académicos | Matrícula, carrera, grupo | Alumno |
| Datos Profesionales | Cédula, especialidad, materias | Docente |
| Proyecto Activo | Título, estado, compañeros | Alumno |

### Datos Consumidos

Los datos se obtienen directamente de `userData` proveniente de `useAuth()`. No realiza fetches adicionales salvo para datos complementarios del proyecto.

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `activeSection` | `string` | Controla la sección visible en mobile |
| `project` | `object\|null` | Proyecto activo del usuario (solo Alumno) |
