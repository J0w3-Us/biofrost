# 05 — Módulo de Evaluaciones (`features/evaluations/`)

## Resumen del Módulo

El módulo de evaluaciones permiten a los docentes emitir sugerencias y calificaciones oficiales sobre los proyectos, y a los alumnos consultar el feedback recibido.

```
features/evaluations/
├── pages/
│   └── EvaluationsPage.jsx     # Selección de proyecto a evaluar
└── components/
    └── EvaluationPanel.jsx     # Panel de evaluaciones con formulario
```

---

## 1. Página de Evaluaciones — `EvaluationsPage.jsx`

### Ruta: `/evaluations`
### Roles: Alumno, Docente

Pantalla de acceso a evaluaciones. El contenido varía según el rol del usuario.

### Comportamiento por Rol

#### Alumno
- Muestra las evaluaciones de su proyecto activo directamente.
- Acceso inmediato al `EvaluationPanel` si ya tiene proyecto.
- Si no tiene proyecto activo, muestra mensaje de estado vacío.

#### Docente
- Muestra un listado de todos los proyectos de sus grupos asignados.
- Al seleccionar un proyecto, renderiza el `EvaluationPanel` con ese proyecto.
- Puede navegar entre proyectos sin salir de la pantalla.

### Endpoints API

| Método | Endpoint | Rol | Descripción |
|--------|----------|-----|-------------|
| `GET` | `/api/projects/my-project?userId={uid}` | Alumno | Proyecto del alumno |
| `GET` | `/api/projects/group/{grupoId}` | Docente | Proyectos del grupo |

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `projects` | `array` | Lista de proyectos disponibles (Docente) |
| `selectedProjectId` | `string\|null` | Proyecto actualmente evaluado |
| `loading` | `boolean` | Carga inicial |

---

## 2. Panel de Evaluaciones — `EvaluationPanel.jsx`

### Propósito

Componente central de evaluaciones. Muestra el historial de evaluaciones de un proyecto específico y permite a los docentes enviar nuevas evaluaciones.

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `projectId` | `string` | ✅ | ID del proyecto a evaluar |

### Tipos de Evaluación

| Tipo | Descripción | ¿Tiene calificación? | ¿Quién puede emitir? |
|------|-------------|---------------------|---------------------|
| `sugerencia` | Comentario constructivo sin nota | ❌ | Cualquier docente |
| `oficial` | Calificación definitiva con justificación | ✅ (0–100) | Solo docente titular o admin |

### Permisos de Evaluación

```js
const isDocente = userData?.rol === 'Docente';
const isAdmin = userData?.rol === 'admin' || userData?.rol === 'SuperAdmin';
const isTitular = project?.docenteId === userData?.userId;
const canGradeOfficially = isDocente && (isTitular || isAdmin);
```

| Permiso | Condición |
|---------|-----------|
| Ver evaluaciones | Todos los usuarios autenticados |
| Enviar sugerencias | Cualquier docente |
| Emitir calificación oficial | Docente titular del proyecto O administrador |
| Cambiar visibilidad de evaluación | Docentes y administradores |

### Flujo de Datos

```
useEffect [projectId, userId]
    ↓
Promise.all([fetchEvaluations(), fetchProject()])
    ↓
Evaluaciones ordenadas por fecha descendente
```

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/projects/{projectId}` | Datos del proyecto (para verificar titular) |
| `GET` | `/api/evaluations/project/{projectId}` | Lista de evaluaciones del proyecto |
| `POST` | `/api/evaluations` | Crea nueva evaluación |
| `PATCH` | `/api/evaluations/{id}/visibility` | Cambia visibilidad pública/privada |

### Payload de Creación

```javascript
{
  projectId:    string,
  docenteId:    string,         // UID del docente que evalúa
  docenteNombre: string,        // Nombre para mostrar
  tipo:         'sugerencia' | 'oficial',
  contenido:    string,         // Texto de la evaluación (requerido)
  calificacion: number | null   // Solo si tipo === 'oficial' (0-100)
}
```

### Payload de Visibilidad

```javascript
{
  userId:    string,
  esPublico: boolean
}
```

### Calificación Actual

```js
// Se muestra siempre en el header del panel
const latestOfficial = evaluations.find(e => e.tipo === 'oficial' && e.calificacion !== null);
const currentGrade = latestOfficial?.calificacion ?? null;
```

> El grade actual es siempre **la calificación oficial más reciente**, no un promedio.

### Formulario de Nueva Evaluación (Solo Docentes)

**Control de tipo:**
- Si `canGradeOfficially === true`: Muestra toggle `Sugerencia | Oficial`.
- Si `canGradeOfficially === false`: Solo puede enviar sugerencias (badge informativo "Solo Sugerencias (No titular)").

**Calificación (solo tipo `oficial`):**
- Slider de rango 0–100.
- Valor por defecto: 80.
- Muestra el valor numerico en tiempo real.

**Textarea de contenido:**
- Placeholder adaptativo según tipo de evaluación.
- Requiere texto no vacío para habilitar el botón de envío.

### Visualización de Evaluaciones

Cada evaluación en la lista muestra:
- Nombre del docente autor
- Badge de tipo (`Oficial` / `Sugerencia`)
- Icono de visibilidad (toggle para docentes/admin, indicador para alumnos)
- Calificación (solo evaluaciones oficiales)
- Fecha y hora formateada (localización `es-MX`)
- Contenido del texto

### Control de Visibilidad

```js
// Actualización optimista del estado local
const toggleVisibility = async (evaluation) => {
  await api.patch(`/api/evaluations/${evaluation.id}/visibility`, {
    userId, esPublico: !evaluation.esPublico
  });
  // Actualiza localmente sin reload completo
  setEvaluations(prev =>
    prev.map(e => e.id === evaluation.id ? { ...e, esPublico: !e.esPublico } : e)
  );
};
```

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `evaluations` | `array` | Lista de evaluaciones del proyecto |
| `project` | `object\|null` | Datos del proyecto (para permisos) |
| `loading` | `boolean` | Carga inicial |
| `submitting` | `boolean` | Estado de envío del formulario |
| `tipo` | `string` | Tipo de evaluación del formulario |
| `contenido` | `string` | Texto del formulario |
| `calificacion` | `number` | Valor del slider (default: 80) |
