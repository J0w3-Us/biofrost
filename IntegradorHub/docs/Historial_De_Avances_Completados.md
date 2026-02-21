# 📜 Historial de Tareas y Características Completadas

Este documento sirve como bitácora y registro de las características, módulos y correcciones que han sido finalizadas con éxito en el sistema IntegradorHub.

---

## ✅ Módulo de Registro y Asignación de Docentes (Febrero 2026)

### 1. Sistema de Asignación Inteligente (Backend)
- Se desarrolló el endpoint `/api/admin/materias/available` en `MateriasController.cs`.
- Se implementó la lógica en `MateriaHandlers.cs` (`GetAvailableMateriasHandler`) para que el sistema consulte dinámicamente qué materias tienen grupos disponibles y qué grupos pertenecen a cierta carrera, evitando asignaciones a grupos fantasma o vacíos.

### 2. Formulario de Registro Dinámico en Cascada (Frontend)
- Se refactorizó por completo el componente `LoginPage.jsx` para el rol de `Docente`.
- Se introdujo un formulario progresivo tipo cascada:
  1. El docente elige su **Carrera**.
  2. El sistema filtra y le permite elegir una **Materia** disponible de esa carrera.
  3. El sistema muestra los **Grupos** específicos de esa materia para que el docente seleccione uno o varios.
- La carga de datos (payload) de registro se actualizó para enviar el arreglo complejo de `Asignaciones` al backend.

### 3. Solución de "Race Condition" en la Creación de Usuarios (Fullstack)
- **El Problema:** Al registrarse un nuevo docente con Google, su nombre completo y materias se perdían, quedando con el nombre por defecto "Usuario" y sin asignaturas. Esto ocurría porque Firebase activaba el inicio de sesión automático instantáneo (`LoginHandler`) que sobreescribía el registro original detallado (`RegisterHandler`) que se estaba procesando al mismo tiempo.
- **La Solución:**
  - **Backend:** Se construyó una nueva barrera de seguridad `CreateIfNotExistsAsync()` en el repositorio de usuarios (`UserRepository.cs`) utilizando la capacidad nativa de Firestore para evitar la sobreescritura si el documento ya fue creado.
  - **Frontend:** Se eliminó la escritura redundante (`setDoc`) directa a la base de datos que existía en el hook `useAuth.jsx`. Ahora el Backend de C# es nuestra única fuente de la verdad para modificaciones a los perfiles de usuario.
- **Resultado:** Los nombres reales (incluyendo nombres compuestos largos o cortos) y las asignaciones de todos los nuevos docentes ahora se guardan intactos y a la primera.

### 4. Auditoría y Limpieza de Datos (Base de Datos Firestore)
- Se generaron scripts de limpieza profunda para eliminar datos corruptos o de prueba.
- Se depuraron las colecciones `users`, `projects` y `evaluations`.
- Se establecieron protocolos para mantener viva e intacta la cuenta de administrador principal (`uzielisaac28@gmail.com`) durante las limpiezas destructivas.

---
*Fin del registro de esta actualización.*
