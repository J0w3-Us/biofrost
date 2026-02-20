# Registro de Cambios - Debugging de Roles y Restauración de Módulos
**Fecha:** 10 de Febrero de 2026
**Objetivo:** Solucionar inconsistencias críticas en roles, restaurar el acceso al Panel de Administración y estabilizar el Frontend.

## 🚨 Problemas Críticos Resueltos (Hotfixes)

### 1. Lógica de Roles: "Invitado" vs "Docente"
*   **Problema:** Usuarios con correo institucional (`@utmetropolitana.edu.mx`) se quedaban estancados en el rol "Invitado", impidiendo el acceso a funciones de docente.
*   **Solución (Backend - `LoginHandler.cs`):**
    *   Se implementó una **Regla de Negocio Forzada**:
        *   Si el correo es `uzielisaac28@gmail.com` ➔ **SuperAdmin** (Indiscutible).
        *   Si el correo es `Uziel.Pech@utmetropolitana.edu.mx` ➔ **Docente** (Indiscutible).
        *   Si el correo termina en `@utmetropolitana.edu.mx` (y no es alumno) ➔ **Docente** (Automático).
    *   Se eliminó la dependencia de que un usuario "existente" mantuviera su rol antiguo si este era incorrecto.

### 2. Frontend Crash ("White Screen of Death")
*   **Problema:** Al iniciar sesión, la aplicación se ponía en blanco o el usuario caía a "Invitado" inmediatamente.
*   **Causa:** La función `setDoc` de Firebase fallaba porque el campo `grupoId` era `undefined`.
*   **Solución (`useAuth.jsx`):** Se sanitizaron los datos antes de enviar a Firestore:
    ```javascript
    grupoId: normalizedUser.grupoId || null, // Convierte undefined a null
    matricula: normalizedUser.matricula || null
    ```

---

## 🛠️ Módulos Funcionales y Restaurados

Se recuperó el acceso y la funcionalidad completa de los siguientes módulos del **Panel de Administración**:

1.  **Gestión de Grupos y Carreras:**
    *   Visualización y control de estructura académica.
2.  **Módulo de Materias (`MateriasPanel`):**
    *   Funcionalidad para asignar materias a planes de estudio.
3.  **Módulo de Docentes (`TeachersPanel`):**
    *   Permite ver a los usuarios con rol "Docente" y asignarles materias/grupos.
4.  **Módulo de Alumnos (`StudentsPanel`):**
    *   Gestión de estudiantes inscritos.

---

## �️ Restauración del Frontend (`App.jsx`)

El enrutamiento de la aplicación (Routing) fue reparado para soportar correctamente la navegación protegida:

*   **Rutas Protegidas (`ProtectedRoute`):** Ahora validan correctamente el estado de autenticación.
*   **Redirección Inteligente:**
    *   Si eres **Admin/SuperAdmin**, el sistema te permite ver la Sidebar de Administración y acceder a `/admin`.
    *   Se flexibilizó la verificación de roles para aceptar tanto `"admin"` como `"SuperAdmin"` (case-insensitive), evitando bloqueos por mayúsculas/minúsculas.

---

## 📝 Notas Técnicas
*   **Servidor Backend:** Se solucionó un conflicto de puertos (`Address already in use`) que impedía que los cambios de código se reflejaran en tiempo real.
*   **Persistencia:** La base de datos (Firestore) se mantuvo íntegra durante todo el proceso.

---
*Documento generado automáticamente por Antigravity tras sesión de debugging y restauración.*
