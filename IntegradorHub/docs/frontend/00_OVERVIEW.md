# IntegradorHub — Frontend Documentation

> **Versión:** 1.0  
> **Stack:** React 18 + Vite + Tailwind CSS + Firebase + Framer Motion  
> **Ruta raíz:** `IntegradorHub/frontend/`

---

## Índice

| # | Módulo | Archivo |
|---|--------|---------|
| 1 | Arquitectura y configuración general | [01_ARCHITECTURE.md](./01_ARCHITECTURE.md) |
| 2 | Autenticación (`auth`) | [02_AUTH.md](./02_AUTH.md) |
| 3 | Dashboard y Layout | [03_DASHBOARD.md](./03_DASHBOARD.md) |
| 4 | Gestión de Proyectos | [04_PROJECTS.md](./04_PROJECTS.md) |
| 5 | Evaluaciones | [05_EVALUATIONS.md](./05_EVALUATIONS.md) |
| 6 | Páginas Públicas | [06_PUBLIC_PAGES.md](./06_PUBLIC_PAGES.md) |
| 7 | Componentes UI Reutilizables | [07_UI_COMPONENTS.md](./07_UI_COMPONENTS.md) |
| 8 | Panel de Administración | [08_ADMIN.md](./08_ADMIN.md) |

---

## Descripción General

**IntegradorHub** es una plataforma web institucional para la gestión de proyectos integradores universitarios. Conecta a tres actores principales:

| Rol | Descripción |
|-----|-------------|
| `Alumno` | Crea y gestiona proyectos, forma equipos, consulta evaluaciones |
| `Docente` | Asesora proyectos, emite evaluaciones oficiales y sugerencias |
| `admin` / `SuperAdmin` | Gestiona usuarios, grupos, carreras y configuración del sistema |

La aplicación sigue una arquitectura **SPA (Single Page Application)** construida con React, con enrutamiento cliente mediante React Router v6. La autenticación es manejada por **Firebase Authentication** con sincronización contra el backend .NET.

---

## Estructura de Directorios

```
frontend/src/
├── main.jsx                        # Entry point React
├── App.jsx                         # Router principal + AuthProvider
├── lib/
│   ├── axios.js                    # Instancia Axios configurada
│   └── firebase.js                 # Inicialización Firebase SDK
├── components/
│   └── ui/                         # Componentes de diseño reutilizables
│       ├── Button.jsx
│       ├── Input.jsx
│       ├── Modal.jsx
│       ├── Card.jsx
│       ├── Badge.jsx
│       └── CloudBackground.jsx
└── features/
    ├── auth/                       # Autenticación y guards
    ├── dashboard/                  # Layout, sidebar y páginas principales
    ├── projects/                   # CRUD y editor de proyectos
    ├── evaluations/                # Panel de evaluaciones
    ├── profile/                    # Perfil de usuario
    ├── public/                     # Showcase y Ranking (sin auth)
    └── admin/                      # Panel de administración
```

---

## Tecnologías Principales

| Tecnología | Versión | Uso |
|------------|---------|-----|
| React | 18.x | UI framework |
| Vite | 5.x | Build tool y dev server |
| React Router DOM | 6.x | Enrutamiento cliente |
| Tailwind CSS | 3.x | Estilos utilitarios |
| Firebase SDK | 10.x | Auth, Firestore, Storage |
| Axios | 1.x | HTTP client con interceptores |
| Framer Motion | 11.x | Animaciones y transiciones |
| @react-three/fiber | — | Fondo 3D animado (CloudBackground) |
| Lucide React | — | Iconografía |

---

## Variables de Entorno

El proyecto requiere un archivo `.env` en `frontend/` con las siguientes claves:

```env
VITE_FIREBASE_API_KEY=
VITE_FIREBASE_AUTH_DOMAIN=
VITE_FIREBASE_PROJECT_ID=
VITE_FIREBASE_STORAGE_BUCKET=
VITE_FIREBASE_MESSAGING_SENDER_ID=
VITE_FIREBASE_APP_ID=
VITE_API_BASE_URL=https://localhost:7001
```

> ⚠️ Nunca incluir estas variables en control de versiones. Usar `.env.local` para desarrollo y secrets del CI/CD para producción.

---

## Patrones de Diseño Aplicados

### CQRS en el Frontend

- **Queries (lectura):** Llamadas `GET` a la API en `useEffect`. Los datos se almacenan en estado local (`useState`) y se usan únicamente para renderizado.
- **Commands (escritura):** Llamadas `POST`, `PUT`, `PATCH`, `DELETE` disparadas por acciones del usuario. Nunca se reutiliza el mismo modelo de lectura para escritura.

### Normalización de Datos

El backend .NET devuelve propiedades en `PascalCase`. El frontend normaliza todas las respuestas a `camelCase` antes de almacenarlas en el estado. Esta lógica se concentra en:
- `useAuth.jsx` → normalización del usuario
- `ProjectDetailsModal.jsx` → normalización de datos del proyecto

### Protección de Rutas

- `ProtectedRoute` → Verifica si el usuario está autenticado. Redirige a `/login` si no lo está.
- `RoleGuard` → Verifica el rol del usuario. Redirige a `/dashboard` si el rol no está permitido.
