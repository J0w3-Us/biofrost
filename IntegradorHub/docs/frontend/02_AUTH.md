# 02 — Módulo de Autenticación (`features/auth/`)

## Resumen del Módulo

Este módulo gestiona todo el ciclo de vida de la autenticación: login, registro, manejo de sesión, guards de ruta y selección de grupo. El estado global de autenticación se distribuye mediante React Context.

```
features/auth/
├── hooks/
│   └── useAuth.jsx           # AuthContext + AuthProvider + hook
├── pages/
│   └── LoginPage.jsx         # Pantalla de login y registro
└── components/
    ├── GroupSelector.jsx     # Selector de grupo tras login
    ├── RoleGuard.jsx         # Guard de ruta por rol
    └── LoginButton.jsx       # Botón de login con Google
```

---

## 1. Hook de Autenticación — `useAuth.jsx`

### Contexto: `AuthContext`

Provider global que envuelve toda la aplicación. Expone el estado y las acciones de autenticación a cualquier componente descendiente.

**Uso:**
```jsx
const { userData, isAuthenticated, loading, logout, refreshUserData } = useAuth();
```

### Estado del Contexto

| Propiedad | Tipo | Descripción |
|-----------|------|-------------|
| `userData` | `object \| null` | Datos completos del usuario (normalizados) |
| `isAuthenticated` | `boolean` | `true` si el usuario tiene sesión activa |
| `loading` | `boolean` | `true` mientras se verifica el estado de auth inicial |
| `logout()` | `async function` | Cierra sesión en Firebase y limpia el estado |
| `refreshUserData()` | `async function` | Fuerza una re-sincronización con el backend |

### Modelo de Datos del Usuario (Normalizado)

```typescript
interface UserData {
  userId: string;          // Firebase UID
  email: string;
  nombre: string;
  rol: 'Alumno' | 'Docente' | 'admin' | 'SuperAdmin';
  grupoId: string | null;
  carreraId: string | null;
  matricula: string | null;
  photoURL: string | null;
  // ...otros campos del backend
}
```

> 📌 **Normalización:** El backend devuelve propiedades en `PascalCase` (ej. `Nombre`, `UserId`). El hook las mapea a `camelCase` antes de almacenarlas. La prioridad para el nombre es: **Backend > Firebase displayName > "Usuario"**.

### Flujo de Autenticación

```
Firebase onAuthStateChanged
    ↓
¿firebaseUser existe?
    ├── SÍ → GET /api/users/{uid}
    │         ├── Respuesta OK → normalizar → setUserData
    │         └── Error 404 → setUserData(null) [usuario no registrado en backend]
    └── NO → setUserData(null), setIsAuthenticated(false)
```

### Funciones Clave

#### `logout()`

```js
signOut(auth) → setUserData(null) → setIsAuthenticated(false)
```

#### `refreshUserData()`

Realiza nuevamente el fetch al backend con el UID actual de Firebase. Útil tras completar el registro o actualizar el perfil.

---

## 2. Pantalla de Login — `LoginPage.jsx`

### Ruta: `/login`

Pantalla de autenticación con soporte para múltiples flujos y detección automática de rol.

### Estados de la Pantalla (Modo)

La página opera como una máquina de estados con los siguientes modos:

| Modo (`mode`) | Descripción |
|--------------|-------------|
| `'login'` | Formulario estándar de email + contraseña |
| `'register-info'` | Formulario de datos adicionales para nuevo usuario |
| `'select-group'` | Selector de grupo (pos-registro/login) |

### Detección Automática de Rol

```js
const REGEX_ALUMNO = /^\d{8}@utm\.mx$/;    // ej: 12345678@utm.mx
const REGEX_DOCENTE = /^[a-zA-Z]+@utm\.mx$/; // ej: jperez@utm.mx

function detectarRol(email) {
  if (REGEX_ALUMNO.test(email)) return 'Alumno';
  if (REGEX_DOCENTE.test(email)) return 'Docente';
  return 'Invitado';
}
```

### Flujo de Login (Email/Contraseña)

```
handleLogin()
    ↓
signInWithEmailAndPassword(auth, email, password)
    ├── Éxito → checkAdminSetup() → refreshUserData() → redirect
    └── Error
        ├── auth/user-not-found | auth/invalid-credential
        │   └── password.length >= 6 → setMode('register-info')
        ├── auth/wrong-password → mostrar error
        └── otros → mostrar error
```

### Flujo de Registro

```
handleRegistro()
    ↓
validarCampos() → si error → mostrar error
    ↓
createUserWithEmailAndPassword(auth, email, password)
    ↓
Construir payload según rol detectado:
  Alumno:  { nombre, apellido, matricula, carreraId, grupoId, ... }
  Docente: { nombre, apellido, cedula, especialidad, ... }
    ↓
POST /api/auth/register
    ↓
refreshUserData() → setMode('login') → redirect a dashboard
```

### Flujo de Login con Google

```
handleGoogleSignIn()
    ↓
signInWithPopup(auth, googleProvider)
    └── Solo permite dominio @utm.mx
    ↓
GET /api/users/{uid}
    ├── 200 OK → usuario existe → refreshUserData() → redirect
    └── 404   → usuario nuevo → setMode('register-info')
```

### Función `checkAdminSetup()`

Asigna automáticamente privilegios de `SuperAdmin` al usuario con email hardcodeado:

```js
// ⚠️ HARDCODED — Requiere generalización
if (user.email === 'uzielisaac28@gmail.com') {
  await api.post(`/api/users/${user.uid}/make-admin`);
}
```

> ⚠️ **Deuda técnica:** El email del super-admin inicial está hardcodeado. Debe migrarse a una variable de entorno o configuración de base de datos.

### Endpoints API Utilizados

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/api/users/{uid}` | Verifica existencia del usuario |
| `POST` | `/api/auth/register` | Registra nuevo usuario con datos de perfil |
| `POST` | `/api/users/{uid}/make-admin` | Otorga rol SuperAdmin |

### Campos del Componente (Estado Local)

| Estado | Tipo | Función |
|--------|------|---------|
| `mode` | string | Controla la vista activa |
| `email` | string | Campo email del formulario |
| `password` | string | Campo contraseña |
| `nombre`, `apellido` | string | Datos del registro |
| `matricula` | string | Solo para Alumno |
| `cedula` | string | Solo para Docente |
| `carreraId` | string | ID de carrera seleccionada |
| `detectedRole` | string | Rol inferido del email |
| `error` | string | Mensaje de error para mostrar al usuario |
| `loading` | boolean | Estado de carga de operaciones async |

---

## 3. Componente `GroupSelector.jsx`

### Propósito

Permite al usuario seleccionar su grupo académico tras completar el login o registro. Aparece cuando el usuario no tiene `grupoId` asignado.

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `onGroupSelected` | `function` | ✅ | Callback ejecutado al confirmar la selección |
| `role` | `string` | ✅ | Rol del usuario (`'Alumno'` o `'Docente'`) |

### Comportamiento

```
useEffect → GET /api/admin/groups
    ↓
Lista grupos disponibles
    ↓
Usuario selecciona grupo(s):
  Alumno:  selección única
  Docente: selección múltiple
    ↓
PUT /api/users/{userId}/group  o  PUT /api/users/{userId}/groups
    ↓
onGroupSelected() → continúa flujo de auth
```

---

## 4. Componente `RoleGuard.jsx`

### Propósito

Guard de ruta que verifica si el usuario autenticado posee alguno de los roles requeridos. Si no, redirige al dashboard.

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `allowedRoles` | `string[]` | ✅ | Lista de roles autorizados |

### Uso en el Router

```jsx
// Solo Alumnos y Docentes pueden acceder a /team y /evaluations
<Route element={<RoleGuard allowedRoles={['Alumno', 'Docente']} />}>
  <Route path="/team" element={<TeamPage />} />
  <Route path="/evaluations" element={<EvaluationsPage />} />
</Route>

// Solo administradores pueden acceder al panel de admin
<Route element={<RoleGuard allowedRoles={['admin', 'SuperAdmin']} />}>
  <Route path="/admin/*" element={<AdminPanel />} />
</Route>
```

### Lógica

```js
const { userData } = useAuth();
const hasAccess = allowedRoles.includes(userData?.rol);
return hasAccess ? <Outlet /> : <Navigate to="/dashboard" replace />;
```

---

## 5. Componente `LoginButton.jsx`

### Propósito

Botón estilizado que dispara el flujo de autenticación con Google vía popup.

### Props

| Prop | Tipo | Requerido | Descripción |
|------|------|-----------|-------------|
| `onSuccess` | `function` | ✅ | Callback tras login exitoso |
| `onError` | `function` | ❌ | Callback en caso de error |

### Comportamiento

1. Llama a `signInWithPopup(auth, googleProvider)`.
2. Restringe al dominio `@utm.mx` mediante el parámetro `hd` del proveedor.
3. En caso de éxito, invoca `onSuccess` con el resultado de Firebase.
