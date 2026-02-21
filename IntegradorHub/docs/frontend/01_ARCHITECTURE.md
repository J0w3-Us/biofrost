# 01 — Arquitectura y Configuración General

## Archivos de Entrada

### `src/main.jsx`

Punto de entrada de la aplicación React. Monta el componente raíz `<App />` dentro de `StrictMode`.

```jsx
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
```

**Responsabilidades:**
- Inicializar el DOM tree de React.
- No contiene lógica de negocio.

---

### `src/App.jsx`

Componente raíz que configura el enrutamiento completo de la aplicación y envuelve todo el árbol con `AuthProvider`.

#### Estructura del Router

```
/                   → Navigate a /dashboard
/login              → LoginPage
/showcase           → ShowcasePage          (público, sin auth)
/ranking            → RankingPage           (público, sin auth)

[ProtectedRoute]
├── /dashboard      → DashboardLayout
│   ├── /dashboard  → DashboardPage
│   ├── /           → (RoleGuard: Alumno, Docente)
│   │   ├── /team          → TeamPage
│   │   └── /evaluations   → EvaluationsPage
│   ├── /projects          → ProjectsPage
│   ├── /profile           → ProfilePage
│   └── /calendar          → CalendarPage
│
├── /project/:id/editor    → ProjectEditorPage
│
└── (RoleGuard: admin, SuperAdmin)
    └── /admin      → AdminPanel
        ├── /admin/subjects   → SubjectsPanel
        ├── /admin/students   → StudentsPanel
        ├── /admin/teachers   → TeachersPanel
        └── /admin/careers    → CareersPanel
```

#### Componentes Internos de `App.jsx`

##### `ProtectedRoute`

```jsx
function ProtectedRoute({ children }) {
  const { isAuthenticated, loading } = useAuth();
  // Muestra spinner durante carga
  // Redirige a /login si no autenticado
  return isAuthenticated ? children : <Navigate to="/login" replace />;
}
```

| Estado | Comportamiento |
|--------|---------------|
| `loading === true` | Muestra spinner de carga |
| `isAuthenticated === false` | Redirige a `/login` (replace) |
| `isAuthenticated === true` | Renderiza `children` |

---

## Librerías de Infraestructura

### `src/lib/axios.js`

Instancia de Axios preconfigurada para todas las llamadas a la API backend.

**Configuración:**
```js
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: { 'Content-Type': 'application/json' }
});
```

**Interceptor de Request:**

Adjunta el token Firebase ID Token en el header `Authorization: Bearer <token>` de cada solicitud.

```
Request saliente
    ↓
Interceptor: getIdToken(auth.currentUser)
    ↓
Agrega header Authorization
    ↓
Request enviado al backend
```

> 📌 **TODO en código:** La obtención del token tiene un bloque marcado para completar la integración con `auth.currentUser.getIdToken()`.

**Interceptor de Response:**

| Código HTTP | Acción |
|-------------|--------|
| `401 Unauthorized` | Log en consola. (TODO: redirigir a `/login`) |
| Otro error | Propaga el error normalmente |

**Exporta:** instancia `api` (default export).

---

### `src/lib/firebase.js`

Inicializa el SDK de Firebase con la configuración inyectada desde variables de entorno (`import.meta.env`).

**Servicios exportados:**

| Export | Tipo | Descripción |
|--------|------|-------------|
| `app` | FirebaseApp | Instancia principal de Firebase |
| `auth` | Auth | Firebase Authentication |
| `db` | Firestore | Firestore Database |
| `storage` | Storage | Firebase Cloud Storage |
| `googleProvider` | GoogleAuthProvider | Proveedor OAuth Google, con parámetro `hd: 'utm.mx'` para restringir a dominio institucional |

**Configuración de proveedor Google:**
```js
googleProvider.setCustomParameters({ hd: 'utm.mx' });
```

> ⚠️ El parámetro `hd` (Hosted Domain) restringe el selector de cuentas de Google al dominio `utm.mx`. Sin embargo, es una restricción de UX, no de seguridad: la validación real debe hacerse en el backend.
