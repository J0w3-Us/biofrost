# Refactorización de Lógica y Registro de Docentes

**Fecha:** Febrero 19, 2026

Este documento detalla los cambios realizados durante la sesión para resolver problemas de lógica en la asignación de roles, carga de materias y limpieza de datos para el módulo de Docentes en **IntegradorHub**.

---

## 1. Problemas Identificados y Resueltos

*   **Asignación de "Materia" Faltante:** Durante el registro de un nuevo docente, el sistema fallaba en asignar de forma correcta e inteligente las materias específicas de una carrera.
*   **Grupos Ocupados:** Se requería un sistema que evitara que dos docentes de la misma materia tomaran los mismos grupos en la misma carrera.
*   **Nombre Genérico "Usuario":** En el flujo de `isFirstLogin` usando Firebase/Google (OAuth), el sistema sobreescribía los nombres reales con "Usuario".
*   **Datos Huérfanos en la BD:** El entorno de pruebas contenía abundantes registros obsoletos (proyectos, evaluaciones y usuarios).

---

## 2. Fase 1: Backend - Sistema de Asignación Inteligente

Se modificó la API en `IntegradorHub.API` para introducir lógica del lado del servidor que calcula disponibilidad en tiempo real.

*   **`GetAvailableMateriasQuery` y `GetAvailableMateriasHandler`:** Se inyectó un nuevo Query en `MateriaHandlers.cs` y su correspondiente controlador `GET /api/admin/materias/available`.
*   **Lógica Funcional:**
    *   Filtra todas las materias activas por el ID de la Carrera seleccionada.
    *   Cruza la información con la colección `users` buscando a todos los Docentes.
    *   Inspecciona la propiedad `Asignaciones` de cada docente para registrar qué grupos (`GruposIds`) ya están reclamados para esa `MateriaId`.
    *   Devuelve al frontend únicamente las materias que **aún poseen grupos libres** dentro de esa carrera.

*   **`LoginHandler.cs` (Corrección de Nombre):** Se modificó la lógica para que, si el proveedor de identidad (Google/Firebase) informa un `DisplayName`, se utilice ese nombre en lugar de inicializarlo forzosamente como `"Usuario"`.

---

## 3. Fase 2: Frontend - Formulario de Registro en Cascada

Se reescribió la sección de "Docente" en la pantalla `LoginPage.jsx` para integrar el flujo dinámico dictado por el Backend.

*   **Eliminación de Hardcodeo:** Se borró el componente estático genérico `GroupSelector` para docentes y se reemplazó con un flujo asíncrono.
*   **Comportamiento en Cascada (React `useEffect`):**
    1.  El usuario selecciona su **Carrera**.
    2.  Esto detona una petición `GET /available?carreraId=X` al backend.
    3.  El usuario selecciona una **Materia Asignada** a partir del arreglo de materias permitidas que retorna la API.
    4.  El usuario elige sus **Grupos Disponibles** (múltiples *chips* de selección) en base a lo que sobró libre para esa materia en particular.
*   **Preparación de Payload:** Se formateó la variable `asignaciones` en el registro para construir el objeto estructurado (`{ carreraId, materiaId, gruposIds: [] }`) nativo esperado en el backend por el `RegisterHandler.cs`.

---

## 4. Fase 3: Limpieza Inmaculada de Base de Datos (Firebase Auth & Firestore)

Con el fin de reiniciar el sistema con seguridad para pruebas limpias, se empleó y ejecutó el **Firebase MCP Server** para borrar registros obsoletos que rompían dependencias (*foreign keys imaginarias*), protegiendo la cuenta Admin maestra:

*   **Consultas:** Detecciones de todos los documentos y sub-documentos listados.
*   **Eliminación en Cascada (Firestore):**
    *   Todos los proyectos listados en `/projects`.
    *   Todas las evaluaciones de los docentes de prueba en `/evaluations`.
    *   Todos los perfiles de `users` (más de 26 cuentas entre alumnos apócrifos y maestros de prueba obsoletos).
*   **Cuenta Aislada y Preservada:** El documento vital `uzielisaac28@gmail.com` con `Rol: SuperAdmin` quedó exento de la purga, preservando el acceso permanente al *tenant* de administración.

---

> **Resultado Final:** Todo el flujo del Rol Docente ahora es robusto, validado directamente del lado del servidor, y la base de datos se encuentra inmaculada, lista para un escenario de producción formal.
