# 06 — Páginas Públicas (`features/public/`)

## Resumen del Módulo

Las páginas públicas son accesibles sin autenticación. Permiten a cualquier visitante explorar los proyectos publicados por los alumnos y consultar el ranking institucional.

```
features/public/
├── pages/
│   ├── ShowcasePage.jsx    # Galería de proyectos públicos
│   └── RankingPage.jsx     # Ranking de proyectos por puntuación
└── components/
    └── ShowcaseCard.jsx    # Tarjeta de proyecto en la galería
```

---

## 1. Galería de Proyectos — `ShowcasePage.jsx`

### Ruta: `/showcase`
### Acceso: Público (sin autenticación)

Galería visual de todos los proyectos marcados como públicos por sus equipos.

### Secciones de la Pantalla

#### Header / Hero (sticky)
- Título "Galería de Proyectos"
- Subtítulo institucional
- Campo de búsqueda en tiempo real

#### Barra de Filtros por Tecnología
- Botón "Todas" (quita el filtro activo)
- Un botón por cada tecnología única extraída de los proyectos (`stackTecnologico`)
- Filtraje local (no requiere llamada adicional a la API)

#### Grid de Proyectos
- Usa el componente `ShowcaseCard`
- Muestra skeleton loaders mientras carga
- Estado vacío con ilustración cuando no hay resultados

#### Modal de Detalles
- Reutiliza `ProjectDetailsModal` en modo solo lectura
- Se activa al hacer click en cualquier `ShowcaseCard`

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/projects/public` | Lista de proyectos públicos |

### Lógica de Filtrado (Local)

```js
// Se ejecuta cada vez que cambia searchTerm, selectedStack o projects
const filterProjects = () => {
  let filtered = projects;

  if (searchTerm) {
    filtered = filtered.filter(p =>
      p.titulo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.materia?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }

  if (selectedStack) {
    filtered = filtered.filter(p =>
      p.stackTecnologico?.includes(selectedStack)
    );
  }

  setFilteredProjects(filtered);
};
```

### Extracción de Stacks Únicos

```js
const stacks = new Set();
response.data.forEach(p => {
  p.stackTecnologico?.forEach(tech => stacks.add(tech));
});
setAllStacks(Array.from(stacks).sort()); // Ordenado alfabéticamente
```

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `projects` | `array` | Todos los proyectos públicos |
| `filteredProjects` | `array` | Proyectos tras aplicar filtros |
| `selectedProject` | `object\|null` | Proyecto activo en el modal |
| `loading` | `boolean` | Estado de carga inicial |
| `searchTerm` | `string` | Texto de búsqueda |
| `selectedStack` | `string\|null` | Tecnología seleccionada como filtro |
| `allStacks` | `string[]` | Lista de tecnologías únicas disponibles |

---

## 2. Ranking de Proyectos — `RankingPage.jsx`

### Ruta: `/ranking`
### Acceso: Público (sin autenticación)

Tabla de clasificación de proyectos públicos ordenados por `puntosTotales`.

### Secciones de la Pantalla

#### Header (Dark Hero)
- Fondo `slate-950` con textura sutil
- Badge "Leaderboard Oficial"
- Título y descripción del ranking

#### Podio (Top 3)

Los tres primeros proyectos se muestran en un layout de podio visual:

| Posición | Estilo | Offset vertical |
|----------|--------|----------------|
| 🥇 1° lugar | Borde dorado, escala 1.05, gradiente amarillo | Centro (más alto) |
| 🥈 2° lugar | Borde gris, estilo plata | `md:translate-y-4` |
| 🥉 3° lugar | Borde naranja, estilo bronce | `md:translate-y-8` |

Cada tarjeta del podio muestra:
- Número de posición (visual grande)
- Título del proyecto
- Nombre del líder
- Puntos totales con ícono

#### Tabla General (Posiciones 4–20)

Tabla con columnas:
| Columna | Descripción |
|---------|-------------|
| Posición | `#4`, `#5`, ... |
| Proyecto | Título + materia |
| Líder | Nombre del líder del proyecto |
| Puntos Totales | Puntuación (`puntosTotales`) |

### Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/projects/public` | Mismo endpoint que Showcase |

### Ordenamiento

```js
const sorted = response.data.sort(
  (a, b) => (b.puntosTotales || 0) - (a.puntosTotales || 0)
);
```

> 📌 **Nota:** El ranking usa el mismo endpoint que el Showcase (`/api/projects/public`). La diferencia es solo el ordenamiento y la presentación visual. Considerar crear un endpoint dedicado `/api/projects/ranking` con paginación para escalabilidad.

### Límites de Visualización

- **Podio:** 3 proyectos máximo
- **Tabla:** 17 proyectos adicionales (posiciones 4–20)
- **Total visible:** 20 proyectos

### Estado Local

| Estado | Tipo | Descripción |
|--------|------|-------------|
| `projects` | `array` | Proyectos ordenados por puntuación |
| `loading` | `boolean` | Estado de carga |

### Variables Derivadas

```js
const top3 = projects.slice(0, 3);
const rest = projects.slice(3, 20);
```

---

## Modelo de Proyecto Público

Estructura esperada para un proyecto en las páginas públicas:

```typescript
interface PublicProject {
  id:               string;
  titulo:           string;
  materia:          string;
  liderNombre:      string;
  stackTecnologico: string[];
  puntosTotales:    number;
  estado:           'Activo' | 'Completado';
  videoUrl?:        string;
  esPublico:        true;      // Siempre true en este endpoint
}
```
