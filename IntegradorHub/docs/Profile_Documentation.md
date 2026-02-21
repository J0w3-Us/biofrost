# Documentación de la Sección de Perfil

Esta documentación detalla la estructura de datos, el flujo de integración y los componentes visuales de la nueva sección de perfil en IntegradorHub.

## Estructura de Datos (Firestore)

Los datos del usuario se sincronizan automáticamente desde el Backend (.NET) a Firestore a través del hook `useAuth`. La colección principal es `users`.

### Esquema de la Colección `users`

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `userId` | `string` | ID único del usuario (Firebase UID). |
| `email` | `string` | Correo electrónico del usuario. |
| `nombre` | `string` | Nombre(s) del usuario. |
| `apellidoPaterno` | `string?` | Apellido paterno (opcional). |
| `apellidoMaterno` | `string?` | Apellido materno (opcional). |
| `fotoUrl` | `string?` | URL de la foto de perfil almacenada en el backend o Google. |
| `rol` | `string` | Rol del usuario (`Alumno`, `Docente`, `Invitado`, `SuperAdmin`). |
| `matricula` | `string?` | Matrícula (solo Alumnos). |
| `grupoId` | `string?` | ID del grupo (solo Alumnos). |
| `carreraId` | `string?` | ID de la carrera (solo Alumnos). |
| `profesion` | `string?` | Profesión (solo Docentes). |
| `especialidadDocente`| `string?` | Especialidad (solo Docentes). |
| `organizacion` | `string?` | Organización (solo Invitados). |
| `updatedAt` | `timestamp` | Fecha de la última sincronización. |

## Integración de Datos

### 1. Backend (.NET)
El `LoginHandler.cs` extiende el objeto `LoginResponse` para incluir todos los campos del perfil. Estos datos se recuperan de la base de datos de Firestore (como source of truth en el backend) y se envían al frontend tras un login exitoso.

### 2. Frontend (`useAuth.jsx`)
El hook `useAuth` realiza las siguientes acciones:
1.  Llama al endpoint `/api/auth/login`.
2.  **Normalización**: Mapea los campos de PascalCase (backend) a camelCase (frontend).
3.  **Limpieza**: Asegura que ningún campo sea `undefined` (convirtiéndolos a `null`) para evitar errores de Firebase.
4.  **Sincronización**: Guarda una copia de los datos actualizados en Firestore (`setDoc` con `merge: true`).

## Guía de Estilos y Componentes

### Estética Premium
La sección de perfil sigue una línea de diseño **Neumorphic / Liquid Glass**:
-   **Header**: Banner oscuro con patrón geométrico y gradiente sutil.
-   **Tarjetas**: Uso de la clase CSS `neu-flat` para elevación y `neu-pressed` para campos de información.
-   **Iconografía**: Lucide-react con colores temáticos para cada categoría.

### Renderizado Dinámico
La página de perfil adapta su contenido según el rol del usuario:
-   **Alumno**: Muestra Matrícula, Carrera y Grupo.
-   **Docente**: Muestra Profesión y Especialidad.
-   **Invitado**: Muestra Organización.

---
> [!NOTE]
> Para futuras mejoras, se planea que los IDs de Carrera y Grupo se resuelvan a nombres legibles mediante una consulta adicional a sus respectivas colecciones.
