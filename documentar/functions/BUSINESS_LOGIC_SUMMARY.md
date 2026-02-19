# IntegradorHub — Documentación de Lógica de Negocio

**Sistema**: IntegradorHub (Kiosko Bifrost DSM)  
**Propósito**: Plataforma académica para gestión, evaluación y showcase de proyectos integradores  
**Fecha**: Febrero 2026  
**Versión**: 1.0

---

## 📋 Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Lógica de Negocio Central](#2-lógica-de-negocio-central)
3. [Actores y Roles del Sistema](#3-actores-y-roles-del-sistema)
4. [Flujos de Negocio Principales](#4-flujos-de-negocio-principales)
5. [Reglas de Negocio Críticas](#5-reglas-de-negocio-críticas)
6. [Arquitectura Implementada vs Diseñada](#6-arquitectura-implementada-vs-diseñada)
7. [Discrepancias Técnicas Detectadas](#7-discrepancias-técnicas-detectadas)
8. [Convenciones y Estándares](#8-convenciones-y-estándares)
9. [Roadmap de Unificación](#9-roadmap-de-unificación)
10. [Referencias y Recursos](#10-referencias-y-recursos)

---

## 1. RESUMEN EJECUTIVO

### El Problema que Resolvemos

IntegradorHub aborda el "Cementerio de Código Académico": proyectos valiosos que mueren tras ser calificados, sin trazabilidad, visibilidad ni reutilización del conocimiento generado.

**Datos del Contexto:**

- 45+ proyectos integradores por cuatrimestre se archivan sin seguimiento
- 0% de trazabilidad: imposible auditar cambios o recuperar estados previos
- Evaluación fragmentada: docentes pierden 4+ horas/semana en logística manual
- Sin visibilidad profesional: alumnos egresan sin portafolio verificable

### La Solución Implementada

Sistema multi-rol que transforma proyectos académicos en activos profesionales mediante:

1. **Gestión Contextual de Squads**: Filtrado automático por grupo académico para mantener integridad de equipos
2. **Sistema de Evaluación Dual**: Evaluaciones oficiales (con calificación) y sugerencias (retroalimentación) con validación de permisos
3. **Showcase Público**: Galería verificable de proyectos para reclutamiento y networking institucional
4. **Reconocimiento Automático de Roles**: Identificación por dominio de correo (`@utmetropolitana.edu.mx`) con regex para asignar permisos

### Stack Tecnológico Real

```
Backend:  .NET 8 Web API + CQRS (MediatR) + Vertical Slice Architecture
Frontend: React 19 + Vite + Tailwind CSS
Database: Google Cloud Firestore (NoSQL documental)
Auth:     Firebase Authentication (Google SSO + JWT)
Storage:  Supabase Storage (multimedia)
Hosting:  Firebase Hosting (frontend) + Cloud Run potencial (backend)
```

---

## 2. LÓGICA DE NEGOCIO CENTRAL

### 2.1. El Modelo de "Triada Académica"

La arquitectura de negocio se basa en una relación jerárquica estricta:

```
Usuario → Grupo → Proyecto → Docente
```

**Principios Fundamentales:**

1. **Aislamiento por Grupo**: Cada alumno pertenece a UN solo grupo (ej. 5B DSM). Esta membresía determina:
   - Qué compañeros puede invitar a su squad
   - Qué docentes puede asignar a su proyecto
   - Qué proyectos puede visualizar

2. **Exclusividad de Proyecto**: Un alumno solo puede pertenecer a UN proyecto activo simultáneamente (`project_id` en User es único y mutable)

3. **Contexto del Líder**: Cuando un alumno crea un proyecto, el sistema inyecta automáticamente su `grupo_id` al proyecto, estableciendo el "ecosistema" del squad

### 2.2. Estados del Ciclo de Vida del Proyecto

**Estados Implementados** (backend real):

| Estado       | Descripción                      | Visibilidad                      | Transición Permitida Por |
| ------------ | -------------------------------- | -------------------------------- | ------------------------ |
| `Borrador`   | Proyecto en construcción inicial | Solo líder                       | Líder                    |
| `EnRevision` | Enviado para evaluación docente  | Líder + Squad + Docente asignado | Líder                    |
| `Aprobado`   | Validado por docente titular     | Líder + Squad + Docente + Admin  | Docente/Admin            |
| `Finalizado` | Proyecto completado y entregado  | Público si `es_publico=true`     | Admin                    |

**Estados Propuestos** (documentación ideal, no implementados):

- `Activo`: En desarrollo colaborativo
- `Publico`: En showcase
- `Historico`: Archivado como legado institucional

**⚠️ Discrepancia**: La documentación en `docs/` propone estados diferentes a los implementados en código. Ver [Sección 7](#7-discrepancias-técnicas-detectadas).

### 2.3. Modelo de Evaluación Dual

El sistema distingue dos tipos de feedback docente:

#### Evaluación Oficial

- **Propósito**: Calificación formal del proyecto (0-100 puntos)
- **Requisito de Negocio**: Solo puede crearla:
  - Docente titular del proyecto (`project.docente_id == evaluador.id`), O
  - Docente con materia de alta prioridad asignada al grupo
- **Efecto**: Impacta directamente la calificación final del alumno
- **Validación en Backend**: `CreateEvaluationHandler` verifica permisos y rechaza con 403 si no cumple

#### Evaluación Sugerencia

- **Propósito**: Retroalimentación técnica sin calificación
- **Requisito**: Cualquier docente puede crearla
- **Campo `calificacion`**: Debe ser `null`
- **Efecto**: Orientación para mejora, no impacta calificación

---

## 3. ACTORES Y ROLES DEL SISTEMA

### 3.1. Identificación Automática por Correo

El sistema usa **Regex de Dominio** sobre el email institucional para asignar roles:

```csharp
// Alumno: 8 dígitos al inicio
Regex: ^(\d{8})@utmetropolitana\.edu\.mx$
Ejemplo: 20241234@utmetropolitana.edu.mx
Rol Asignado: "Alumno"
Obligatorio: Matrícula + Grupo

// Docente: Caracteres alfabéticos
Regex: ^[a-zA-Z.]+@utmetropolitana\.edu\.mx$
Ejemplo: juan.perez@utmetropolitana.edu.mx
Rol Asignado: "Docente"
Obligatorio: Asignaciones (Carrera → Materia → Grupos)

// Invitado/Externo: Cualquier otro dominio
Ejemplo: reclutador@empresa.com
Rol Asignado: "Invitado"
Permisos: Solo lectura de proyectos públicos
```

### 3.2. Matriz de Permisos por Rol

| Acción                 | Alumno (Líder)        | Alumno (Miembro)      | Docente             | Admin | Invitado |
| ---------------------- | --------------------- | --------------------- | ------------------- | ----- | -------- |
| Crear Proyecto         | ✅                    | ❌                    | ❌                  | ✅    | ❌       |
| Editar Proyecto        | ✅ (solo si es líder) | ❌                    | ❌                  | ✅    | ❌       |
| Agregar Miembros       | ✅ (solo su grupo)    | ❌                    | ❌                  | ✅    | ❌       |
| Eliminar Miembros      | ✅                    | ❌                    | ❌                  | ✅    | ❌       |
| Editar Canvas          | ✅                    | ✅ (si es miembro)    | ❌                  | ✅    | ❌       |
| Evaluar (Oficial)      | ❌                    | ❌                    | ✅ (con validación) | ❌    | ❌       |
| Evaluar (Sugerencia)   | ❌                    | ❌                    | ✅ (cualquiera)     | ❌    | ❌       |
| Ver Proyectos Públicos | ✅                    | ✅                    | ✅                  | ✅    | ✅       |
| Ver Proyectos Privados | ✅ (solo su proyecto) | ✅ (solo su proyecto) | ✅ (de sus grupos)  | ✅    | ❌       |
| Eliminar Proyecto      | ✅                    | ❌                    | ❌                  | ✅    | ❌       |
| Gestionar Materias     | ❌                    | ❌                    | ❌                  | ✅    | ❌       |
| Gestionar Grupos       | ❌                    | ❌                    | ❌                  | ✅    | ❌       |

### 3.3. Definición de Actores

#### Alumno (Miembro del Squad)

**Perfil de Negocio**: Generador de contenido técnico, constructor de portafolio profesional

**Responsabilidades**:

- Crear y gestionar proyectos integradores cuando actúa como Líder
- Colaborar en el canvas del proyecto cuando es miembro
- Mantener su perfil actualizado con stack tecnológico
- Decidir visibilidad pública/privada de su proyecto

**Restricciones de Negocio**:

- Solo puede agregar miembros de su mismo grupo
- Solo puede estar en UN proyecto activo a la vez
- No puede evaluar proyectos (ni el suyo)
- No puede modificar su matrícula después del primer registro

#### Docente (Evaluador Contextual)

**Perfil de Negocio**: Garante de calidad técnica, mentor académico

**Responsabilidades**:

- Evaluar proyectos de sus grupos asignados
- Emitir retroalimentación oficial (con calificación) o sugerencias
- Validar propuestas de proyectos antes de aprobación
- Monitorear progreso de squads bajo su supervisión

**Restricciones de Negocio**:

- Solo ve proyectos de grupos que tiene asignados en el cuatrimestre
- Solo puede crear evaluación oficial si es docente titular O tiene materia de alta prioridad
- Puede crear evaluaciones sugerencia sin restricciones
- No puede editar proyectos directamente (solo evaluar)

#### Admin (Super Administrador)

**Perfil de Negocio**: Control maestro del sistema, gestor de catálogos académicos

**Responsabilidades**:

- Dar de alta materias, carreras y grupos
- Asignar prioridades a docentes
- Realizar hard-delete de datos erróneos
- Gestionar ciclos académicos (apertura/cierre de cuatrimestres)
- Promover proyectos destacados a estado Histórico

**Poderes Especiales**:

- Acceso total a todos los proyectos (públicos y privados)
- Puede modificar cualquier entidad del sistema
- Único rol que puede eliminar permanentemente datos

#### Invitado (Reclutador/Externo)

**Perfil de Negocio**: Consumidor de talento, visualizador de showcase

**Responsabilidades**:

- Explorar galería pública de proyectos
- Filtrar por stack tecnológico y carrera
- Ver pitch videos y documentación de proyectos públicos

**Restricciones de Negocio**:

- Read-only absoluto
- No puede ver proyectos privados
- No puede crear ningún recurso
- No tiene acceso a datos personales de alumnos (solo perfil público)

---

## 4. FLUJOS DE NEGOCIO PRINCIPALES

### 4.1. Flujo de Registro e Identificación

```
1. Usuario intenta login con Google (Firebase Auth)
   ↓
2. Sistema extrae email y ejecuta regex de dominio
   ↓
3a. Si es @utmetropolitana.edu.mx (alumno con 8 dígitos):
    → Backend detecta isFirstLogin=true
    → Frontend redirecciona a /register
    → Alumno completa: Nombre, Apellidos, Matrícula (obligatorio), Grupo (select)
    → Backend valida matrícula única y crea User con rol="Alumno"
    → Frontend redirecciona a /dashboard

3b. Si es @utmetropolitana.edu.mx (docente alfabético):
    → Backend detecta isFirstLogin=true
    → Frontend redirecciona a /register
    → Docente completa: Nombre, Apellidos, Profesión, Grupos que imparte (multiselect)
    → Backend crea User con rol="Docente" y asignaciones vacías (Admin las llena después)
    → Frontend redirecciona a /dashboard/evaluations

3c. Si es otro dominio:
    → Backend asigna rol="Invitado" automáticamente
    → Frontend redirecciona a /showcase (galería pública)
```

**Regla de Negocio Crítica**: La matrícula es clave única. Si un alumno intenta registrarse con una matrícula ya existente, el backend rechaza con error 400 "Matrícula ya registrada".

### 4.2. Flujo de Creación de Proyecto (Squad Building)

```
1. Alumno (Líder potencial) hace clic en "Crear Proyecto"
   ↓
2. Frontend muestra formulario con campos:
   - Título (obligatorio)
   - Materia (select de materias de su carrera)
   - Ciclo (auto-detectado: 2026-1)
   - Stack Tecnológico (tags multiselect)
   - Docente Asesor (select filtrado por grupo del líder)
   - Miembros del Squad (buscador con filtro de grupo)
   ↓
3. Sistema ejecuta filtros de negocio:
   - Buscador de miembros: GET /api/teams/available-students?groupId={liderr.grupoId}
   - Solo retorna alumnos:
     * Del mismo grupo que el líder
     * Que NO tengan project_id asignado (disponibles)
   - Tooltip al hover: Muestra matrícula y foto para confirmar identidad
   ↓
4. Líder envía POST /api/projects con payload:
   {
     "titulo": "...",
     "materiaId": "...",
     "userId": "leader-id",
     "userGroupId": "grupo-id",
     "docenteId": "docente-id",
     "miembrosIds": ["alumno1-id", "alumno2-id"]
   }
   ↓
5. Backend (CreateProjectHandler) valida:
   - Todos los miembrosIds pertenecen al mismo grupo del líder ✅
   - Docente tiene asignado ese grupo ✅
   - Líder no tiene ya un proyecto activo ✅
   - Ningún miembro tiene ya un project_id ✅
   ↓
6. Si validaciones pasan:
   - Crea Project con estado="Borrador", liderId=userId, grupoId=userGroupId
   - Actualiza User.project_id de todos los miembros (incluyendo líder)
   - Retorna 201 Created con ID del proyecto
   ↓
7. Frontend redirecciona a /projects/{id}/edit (canvas editor)
```

**Regla de Negocio Crítica**: La exclusividad de proyecto se garantiza con transacciones. Si dos líderes intentan agregar al mismo alumno simultáneamente, el segundo falla con error 400 "Alumno ya asignado a otro proyecto".

### 4.3. Flujo de Evaluación Docente

```
1. Docente navega a /evaluations (Dashboard de evaluación)
   ↓
2. Sistema carga proyectos:
   - GET /api/projects/group/{groupId} para cada grupo asignado al docente
   - Frontend muestra lista de proyectos en estado "EnRevision" o "Aprobado"
   ↓
3. Docente selecciona un proyecto y hace clic en "Evaluar"
   ↓
4. Frontend muestra formulario de evaluación:
   - Tipo: Oficial | Sugerencia (radio buttons)
   - Contenido: Textarea markdown para retroalimentación
   - Calificación: Number input (0-100) — solo habilitado si tipo="Oficial"
   ↓
5. Docente envía POST /api/evaluations con payload:
   {
     "projectId": "...",
     "docenteId": "...",
     "docenteNombre": "...",
     "tipo": "oficial" | "sugerencia",
     "contenido": "...",
     "calificacion": 85 | null
   }
   ↓
6. Backend (CreateEvaluationHandler) valida reglas de negocio:
   - Si tipo="oficial":
     * Verifica que docente sea titular del proyecto (project.docenteId == evaluador.id) ✅
     * O que docente tenga materia con esAltaPrioridad=true ✅
     * Si no cumple → Retorna 403 Forbidden "No autorizado para evaluación oficial"
   - Si tipo="sugerencia":
     * No valida permisos especiales (cualquier docente puede) ✅
   - Valida que calificacion sea null si tipo="sugerencia" ✅
   ↓
7. Si validaciones pasan:
   - Crea Evaluation en Firestore
   - Actualiza Project.calificacion si tipo="oficial" (promedio de evaluaciones oficiales)
   - Envía notificación push al líder del proyecto (futuro)
   - Retorna 200 OK con evaluación creada
   ↓
8. Frontend muestra éxito y recarga lista de proyectos evaluados
```

**Regla de Negocio Crítica**: Solo puede haber UNA evaluación oficial por docente por proyecto. Si un docente intenta evaluar oficialmente dos veces, el backend actualiza la evaluación anterior en vez de crear nueva.

### 4.4. Flujo de Publicación de Showcase

```
1. Líder del proyecto navega a /projects/{id}
   ↓
2. Frontend muestra toggle "Estado de Visibilidad":
   - 🔒 Privado (default) → Solo visible para squad y docente
   - 🌍 Público → Visible en galería de invitados
   ↓
3. Líder hace clic en "Hacer Público"
   ↓
4. Frontend valida que estén completos:
   - Título ✅
   - Video URL ✅
   - Al menos 1 bloque de canvas ✅
   - Al menos 1 miembro además del líder ✅
   ↓
5. Si validaciones pasan:
   - PUT /api/projects/{id} con payload:
     {
       "titulo": "...",
       "esPublico": true
     }
   ↓
6. Backend actualiza Project.es_publico=true
   ↓
7. Proyecto ahora aparece en GET /api/projects/public (galería de invitados)
   ↓
8. Frontend muestra badge "🌍 Público" en el card del proyecto
```

**Regla de Negocio**: Solo el líder puede cambiar el estado de visibilidad. Miembros del squad pueden ver el toggle pero no modificarlo.

---

## 5. REGLAS DE NEGOCIO CRÍTICAS

### 5.1. Reglas de Membresía y Squads

| ID     | Regla                                                | Validación                                                | Mensaje de Error                             |
| ------ | ---------------------------------------------------- | --------------------------------------------------------- | -------------------------------------------- |
| RN-001 | Un alumno solo puede pertenecer a UN proyecto activo | Backend verifica `project_id` antes de agregar            | "Alumno ya asignado al proyecto {titulo}"    |
| RN-002 | Los miembros de un squad deben ser del mismo grupo   | Backend filtra por `grupo_id` del líder                   | "Solo puedes agregar compañeros de tu grupo" |
| RN-003 | El docente asignado debe impartir clase al grupo     | Backend valida `docente.asignaciones` contiene `grupo_id` | "Docente no asignado a tu grupo"             |
| RN-004 | La matrícula del alumno es única e inmutable         | Backend rechaza duplicados y bloquea edición              | "Matrícula ya registrada"                    |
| RN-005 | Un proyecto no puede tener más de 5 miembros         | Frontend deshabilita botón "Agregar" al llegar a 5        | "Squad completo (máximo 5 miembros)"         |

### 5.2. Reglas de Evaluación

| ID     | Regla                                                           | Validación                                                    | Mensaje de Error                           |
| ------ | --------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------ |
| RN-101 | Solo docentes con permisos pueden crear evaluación oficial      | Backend verifica titular o alta prioridad                     | "No autorizado para evaluación oficial"    |
| RN-102 | Evaluaciones sugerencia no llevan calificación                  | Backend rechaza si `tipo="sugerencia"` y `calificacion!=null` | "Sugerencias no admiten calificación"      |
| RN-103 | Evaluaciones oficiales requieren calificación                   | Backend rechaza si `tipo="oficial"` y `calificacion==null`    | "Evaluación oficial requiere calificación" |
| RN-104 | Calificación debe estar entre 0 y 100                           | Backend valida rango                                          | "Calificación inválida (0-100)"            |
| RN-105 | Solo un docente puede evaluar oficialmente una vez por proyecto | Backend actualiza existente en vez de crear                   | N/A (comportamiento automático)            |

### 5.3. Reglas de Visibilidad y Estados

| ID     | Regla                                                    | Validación                                           | Mensaje de Error                        |
| ------ | -------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------- |
| RN-201 | Proyectos en Borrador solo visibles por líder            | Backend filtra por `liderId`                         | N/A (no retorna en query)               |
| RN-202 | Proyectos EnRevision visibles por squad + docente        | Backend filtra por `miembrosIds` o `docenteId`       | N/A (no retorna en query)               |
| RN-203 | Proyectos Públicos aparecen en galería de invitados      | Backend filtra con `where("es_publico", "==", true)` | N/A                                     |
| RN-204 | Solo el líder puede cambiar estado Borrador → EnRevision | Frontend deshabilita botón para miembros             | "Solo el líder puede enviar a revisión" |
| RN-205 | Solo Admin puede marcar proyecto como Finalizado         | Backend rechaza si `rol != "Admin"`                  | "Acción reservada para administradores" |

### 5.4. Reglas de Autenticación y Registro

| ID     | Regla                                             | Validación                                          | Mensaje de Error                                  |
| ------ | ------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------- |
| RN-301 | Email institucional determina rol automáticamente | Backend ejecuta regex en `LoginHandler`             | N/A (asignación automática)                       |
| RN-302 | Primer login obliga a completar registro          | Backend retorna `isFirstLogin=true`                 | N/A (redirección a /register)                     |
| RN-303 | Matrícula solo alfanumérica, 8 caracteres         | Backend valida con regex `^\d{8}$`                  | "Matrícula inválida"                              |
| RN-304 | Invitados no pueden crear recursos                | Backend rechaza POST/PUT/DELETE si `rol="Invitado"` | "Acceso de solo lectura"                          |
| RN-305 | Docentes sin asignaciones no ven proyectos        | Frontend no carga dashboard si `asignaciones==null` | "Contacta al administrador para asignarte grupos" |

---

## 6. ARQUITECTURA IMPLEMENTADA VS DISEÑADA

### 6.1. Comparativa de Arquitecturas

| Aspecto                    | Visión Ideal (Docs)                          | Realidad Implementada (Código)                                            | Gap/Razón                                                                          |
| -------------------------- | -------------------------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **Backend Framework**      | .NET 9                                       | .NET 8                                                                    | Versión estable disponible en desarrollo                                           |
| **Base de Datos**          | MongoDB Atlas + Event Sourcing               | Google Cloud Firestore (NoSQL documental)                                 | Firestore elegido por integración con Firebase Auth y menor complejidad operativa  |
| **Patrón de Persistencia** | Event Sourcing completo (eventos inmutables) | CQRS simplificado (Commands/Queries sin evento sourcing)                  | Event Sourcing requiere EventStore especializado; se postponió para MVP            |
| **Estados de Proyecto**    | Borrador, Activo, Publico, Historico         | Borrador, EnRevision, Aprobado, Finalizado                                | Nombres más descriptivos del flujo académico real                                  |
| **Frontend Build Tool**    | No especificado                              | Vite 7.x                                                                  | Elegido por velocidad de HMR y compatibilidad con React 19                         |
| **Naming Convention**      | camelCase consistente                        | Mixto: snake_case (Firestore), PascalCase (DTOs C#), camelCase (frontend) | Falta capa de normalización; ver [Sección 7](#7-discrepancias-técnicas-detectadas) |
| **Multitenancy**           | No especificado                              | Implícito por grupo académico                                             | Aislamiento natural por filtros de `grupo_id`                                      |
| **Notificaciones**         | Push notifications móviles                   | No implementadas (futuro)                                                 | Requiere FCM (Firebase Cloud Messaging)                                            |
| **Analytics**              | Dashboard con métricas históricas            | No implementado (futuro)                                                  | Requiere agregaciones y time-series                                                |

### 6.2. Decisión Arquitectónica: Firestore vs MongoDB

**Por qué Firestore ganó en la implementación real:**

1. **Integración Nativa**: Firebase Auth + Firestore comparten SDK y contexto de autenticación
2. **Tiempo de Desarrollo**: Sin configuración de servidor; operaciones CRUD listas out-of-the-box
3. **Seguridad Declarativa**: Firestore Rules permite expresar reglas de negocio en sintaxis simple
4. **Escalabilidad Automática**: No requiere sharding manual ni replica sets
5. **Costo Controlado**: Free tier generoso para MVP educativo

**Qué se perdió vs MongoDB:**

- Transacciones multi-documento complejas (limitadas en Firestore)
- Agregaciones avanzadas (Firestore no tiene `$lookup` ni pipelines complejos)
- Flexibilidad de índices compuestos (Firestore requiere declaración explícita en `firestore.indexes.json`)

### 6.3. Decisión Arquitectónica: CQRS sin Event Sourcing

**Implementado:**

- Command Handlers que modifican estado (CreateProjectCommand → guardar en Firestore)
- Query Handlers que leen estado actual (GetPublicProjectsQuery → leer de Firestore)
- Estado mutable: Actualizaciones reemplazan datos anteriores

**No Implementado (de la visión ideal):**

- EventStore con eventos inmutables (ej. `ProyectoCreado`, `MiembroAgregado`)
- Rehidratación de estado desde eventos históricos
- Proyecciones asíncronas con Change Streams
- Capacidad de "time travel" (ver proyecto como estaba en fecha X)

**Justificación**: Event Sourcing agrega complejidad significativa:

- Requiere EventStore especializado (tabla de eventos + snapshots)
- Lógica de rehidratación de aggregates
- Manejo de event versioning
- Testing más complejo

Para el MVP académico, CQRS puro (sin eventos) ofrece 80% del beneficio con 20% de la complejidad.

---

## 7. DISCREPANCIAS TÉCNICAS DETECTADAS

### 7.1. 🔴 [CRÍTICO] Convención de Nombres Inconsistente

**Problema**: Tres convenciones coexisten sin capa de normalización automática.

| Capa                    | Convención   | Ejemplo                                  | Ubicación                                            |
| ----------------------- | ------------ | ---------------------------------------- | ---------------------------------------------------- |
| **Firestore (BD)**      | `snake_case` | `lider_id`, `es_publico`, `miembros_ids` | `Project.cs` con `[FirestoreProperty("snake_case")]` |
| **Backend (DTOs)**      | `PascalCase` | `LiderId`, `EsPublico`, `MiembrosIds`    | `ProjectDetailsDto.cs`                               |
| **Frontend (esperado)** | `camelCase`  | `liderId`, `esPublico`, `miembrosIds`    | Código React/JS                                      |

**Impacto Actual**:

- Frontend debe normalizar manualmente en `useAuth.jsx`:
  ```javascript
  const normalizedUser = {
    userId: response.data.userId || response.data.UserId,
    grupoId: response.data.grupoId || response.data.GrupoId,
    // ... repetido para cada campo
  };
  ```
- Propenso a errores: Olvido de normalización causa `undefined` en componentes
- Complejidad de debugging: `liderId` vs `LiderId` vs `lider_id` según contexto

**Recomendación**:

1. **Opción A (Recomendada)**: Configurar `JsonSerializerOptions` en `Program.cs`:

   ```csharp
   builder.Services.AddControllers()
       .AddJsonOptions(options => {
           options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
       });
   ```

   - ✅ Automático: Backend serializa DTOs a camelCase sin cambiar código
   - ✅ Frontend elimina normalización manual
   - ⚠️ Firestore sigue en snake_case (correcto, no afecta API)

2. **Opción B**: Crear `ApiAdapter.js` en frontend:
   ```javascript
   export const normalizeBackendResponse = (data) => {
     return Object.keys(data).reduce((acc, key) => {
       const camelKey = key.charAt(0).toLowerCase() + key.slice(1);
       acc[camelKey] = data[key];
       return acc;
     }, {});
   };
   ```

   - ✅ No requiere cambios en backend
   - ⚠️ Debe aplicarse en TODA llamada API (fácil de olvidar)

**Prioridad**: 🔴 Alta — Afecta todos los endpoints y componentes

### 7.2. 🔴 [CRÍTICO] Autenticación Sin JWT Claims

**Problema**: Endpoints aceptan `userId` en body/query en vez de extraerlo del token JWT.

**Código Vulnerable Actual**:

```csharp
// ProjectsController.cs - CreateProject
public async Task<ActionResult> Create([FromBody] CreateProjectRequest request)
{
    // TODO: Obtener UserId del token JWT
    // Por ahora confiamos en el request.UserId (INSEGURO)
    var command = new CreateProjectCommand(
        request.UserId, // ⚠️  Cliente puede falsificar este valor
        //...
    );
}
```

**Frontend Enviando UserId**:

```javascript
// CreateProjectForm.jsx
await api.post("/api/projects", {
  userId: userData.userId, // ⚠️  Modificable desde DevTools
  titulo: form.titulo,
  // ...
});
```

**Impacto de Seguridad**:

- Alumno A puede crear proyectos como Alumno B modificando `userId` en request
- Líder puede agregar miembros con `userId` falso, bypasseando validaciones de grupo
- Docente puede falsificar `docenteId` para evaluar proyectos fuera de su alcance

**Solución Requerida**:

1. **Backend**: Extraer `userId` de `ClaimsPrincipal`:
   ```csharp
   var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
       ?? throw new UnauthorizedAccessException("Token inválido");
   ```
2. **Frontend**: Eliminar `userId` de todos los payloads
3. **Middleware**: Validar token JWT en cada request (actualmente no implementado)

**Endpoints Afectados**:

- `POST /api/projects` (userId)
- `PUT /api/projects/{id}` (userId implícito en auth)
- `POST /api/projects/{id}/members` (leaderId)
- `DELETE /api/projects/{id}/members/{memberId}` (requestingUserId query)
- `PUT /api/projects/{id}/canvas` (userId)
- `DELETE /api/projects/{id}` (requestingUserId query)

**Prioridad**: 🔴 Alta — Vulnerabilidad de seguridad crítica antes de producción

### 7.3. 🟡 [MEDIO] Rutas de API con Casing Inconsistente

**Problema**: Documentación muestra diferentes formatos de rutas.

**Fuentes Conflictivas**:

| Documento                 | Formato                    | Ejemplo                                                 |
| ------------------------- | -------------------------- | ------------------------------------------------------- |
| `API_DOCS.md`             | lowercase                  | `/api/projects/group/{groupId}`                         |
| `endpoints.md`            | PascalCase                 | `/api/Projects/group/{groupId}`                         |
| `.gemini/modulos/`        | Mixto                      | `/api/projects/by-group/:id`                            |
| Backend Real (controller) | `[controller]` placeholder | `/api/[controller]` → `/api/Projects` (ASP.NET default) |

**Comportamiento Real**:

- ASP.NET Core routing es **case-insensitive** por defecto
- `/api/projects` y `/api/Projects` funcionan ambos
- Frontend usa lowercase consistentemente

**Riesgo**:

- Confusión en equipos externos (documentación desincronizada)
- Potencial break si se cambia configuración de routing a case-sensitive

**Recomendación**:

1. Normalizar todas las docs a lowercase (convención REST estándar)
2. Actualizar `API_DOCS.md` como fuente canónica
3. Deprecar `endpoints.md` y `.gemini/modulos/` o sincronizarlos vía script

**Prioridad**: 🟡 Media — No afecta funcionalidad pero genera fricción

### 7.4. 🟡 [MEDIO] Schema de Errores No Estandarizado

**Problema**: Backend retorna diferentes formatos de error según el controlador.

**Ejemplos de Respuestas Actuales**:

```javascript
// Caso 1: BadRequest con string
{
  "title": "Bad Request",
  "status": 400,
  "detail": "Alumno ya asignado a otro proyecto"
}

// Caso 2: Forbid con string
{
  "title": "Forbidden",
  "status": 403,
  "detail": "No autorizado para evaluación oficial"
}

// Caso 3: NotFound con string
{
  "title": "Not Found",
  "status": 404,
  "detail": "Proyecto no encontrado"
}
```

**Problemas**:

- Frontend no puede distinguir entre error de validación (mostrar inline) vs error de servidor (mostrar toast)
- No hay campo `code` para internacionalización de mensajes
- No hay campo `fieldErrors` para validaciones específicas de formulario

**Schema Propuesto**:

```typescript
interface ErrorResponse {
  code: string; // "PROJECT_NOT_FOUND", "MEMBER_ALREADY_ASSIGNED"
  message: string; // Mensaje legible para usuario
  status: number; // 400, 403, 404, 500
  fieldErrors?: {
    // Solo para errores de validación
    [field: string]: string; // { "titulo": "Campo requerido" }
  };
  timestamp: string; // ISO 8601
  path: string; // Endpoint que falló
}
```

**Implementación**:

1. Crear `ErrorResponse.cs` en `Shared/Domain/Common`
2. Crear middleware `GlobalExceptionHandler` que envuelva excepciones
3. Documentar códigos de error en `API_DOCS.md`

**Prioridad**: 🟡 Media — Mejora UX pero no bloquea funcionalidad

### 7.5. 🟢 [BAJO] Storage Upload Sin Documentación de Respuesta

**Problema**: `POST /api/storage/upload` no documenta formato de respuesta en `API_DOCS.md`.

**Código Frontend Actual**:

```javascript
// CanvasEditor.jsx
const response = await api.post(
  "/api/storage/upload?folder=projects",
  formData,
);
const imageUrl = response.data.url; // ⚠️  Formato no documentado
```

**Formato Real** (inspeccionado en código):

```json
{
  "path": "projects/abc123.png",
  "url": "https://storage.supabase.co/...abc123.png",
  "size": 245678,
  "mimeType": "image/png"
}
```

**Falta Documentar**:

- Límite de tamaño por archivo (actualmente no validado)
- Tipos MIME permitidos (actualmente permite todo)
- Rate limiting (sin implementar)
- Política de eliminación de archivos huérfanos

**Recomendación**:

1. Agregar sección en `API_DOCS.md`:

   ```markdown
   ### POST /api/storage/upload

   **Request**: `multipart/form-data`
   **Query**: `?folder=projects|users|thumbnails`
   **Límites**:

   - Tamaño máximo: 10 MB
   - Tipos permitidos: image/_, video/_, application/pdf

   **Response**:
   {
   "path": "string",
   "url": "string",
   "size": "number",
   "mimeType": "string"
   }
   ```

2. Implementar validación de tamaño en backend
3. Agregar tests de contrato

**Prioridad**: 🟢 Baja — Funcionalidad estable pero documentación incompleta

### 7.6. 🟢 [BAJO] Frontend Asume Permisos Sin Validación Backend

**Problema**: Componentes muestran/ocultan botones basados en `userData.rol` del cliente, pero backend no valida uniformemente.

**Ejemplo**:

```javascript
// ProjectDetailsModal.jsx
{
  isLeader && <button onClick={handleAddMember}>Agregar Miembro</button>;
}
```

**Riesgo**:

- Si frontend tiene bug o usuario modifica `localStorageData`, puede ver botones prohibidos
- Backend debe SIEMPRE validar permisos independientemente de lo que muestre frontend
- Actualmente algunos endpoints validan, otros confían en el request

**Casos Sin Validación Backend**:

- `PUT /api/projects/{id}/canvas` solo verifica que userId sea miembro, no que tenga permiso de edición
- `POST /api/projects/{id}/members` confía en `LeaderId` del body

**Recomendación**:

1. Crear `PermissionService.cs` que centralice validaciones:
   ```csharp
   public async Task<bool> CanEditProject(string userId, string projectId)
   {
       var project = await _projectRepo.GetByIdAsync(projectId);
       return project.LiderId == userId || project.MiembrosIds.Contains(userId);
   }
   ```
2. Usar en todos los handlers antes de ejecutar lógica
3. Opcionalmente: Exponer endpoint `GET /api/projects/{id}/permissions` para que frontend sincronice UI

**Prioridad**: 🟢 Baja — Backend protege operaciones críticas; mejora defensa en profundidad

---

## 8. CONVENCIONES Y ESTÁNDARES

### 8.1. Convenciones de Código Backend

#### Naming Conventions

```csharp
// Entidades del Dominio: PascalCase
public class Project { }
public class User { }

// Propiedades de Firestore: snake_case con atributo
[FirestoreProperty("lider_id")]
public string LiderId { get; set; }

// DTOs: PascalCase + sufijo Dto
public record ProjectDetailsDto(string Id, string Titulo);

// Commands/Queries: PascalCase + sufijo Command/Query
public record CreateProjectCommand(string Titulo, string UserId);
public record GetPublicProjectsQuery();

// Handlers: PascalCase + sufijo Handler
public class CreateProjectHandler : IRequestHandler<CreateProjectCommand, CreateProjectResponse> { }
```

#### Vertical Slice Organization

```
Features/
├── Projects/
│   ├── ProjectsController.cs          ← Entry point HTTP
│   ├── Create/
│   │   ├── CreateProjectCommand.cs
│   │   ├── CreateProjectHandler.cs
│   │   └── CreateProjectValidator.cs
│   ├── GetByGroup/
│   │   ├── GetProjectsByGroupQuery.cs
│   │   └── GetProjectsByGroupHandler.cs
│   └── Update/
│       ├── UpdateProjectCommand.cs
│       └── UpdateProjectHandler.cs
```

**Regla**: Cada feature es autónoma. Solo comparte `Shared/Domain/Entities` y `Shared/Infrastructure`.

#### Error Handling

```csharp
// En Handler: Lanzar excepciones específicas
if (project == null)
    throw new KeyNotFoundException($"Proyecto {id} no encontrado");

if (user.Rol != "Docente")
    throw new UnauthorizedAccessException("Solo docentes pueden evaluar");

// En Controller: Capturar y mapear a respuestas HTTP
try {
    var response = await _mediator.Send(command);
    return Ok(response);
}
catch (KeyNotFoundException ex) {
    return NotFound(ex.Message);
}
catch (UnauthorizedAccessException ex) {
    return Forbid(ex.Message);
}
```

### 8.2. Convenciones de Código Frontend

#### Component Organization

```
src/features/projects/
├── components/
│   ├── ProjectCard.jsx              ← Componente presentacional puro
│   ├── CreateProjectForm.jsx        ← Componente con lógica (hooks)
│   └── ProjectDetailsModal.jsx
├── pages/
│   ├── ProjectsPage.jsx             ← Vista completa (router)
│   └── ProjectEditorPage.jsx
└── hooks/                           ← (futuro) Custom hooks
    └── useProjectOperations.js
```

#### Prop Naming

```javascript
// Props Booleanas: prefijo "is", "has", "can"
<ProjectCard
  isPublic={project.esPublico}
  canEdit={isLeader}
/>

// Event Handlers: prefijo "on" o "handle"
<Button onClick={handleSubmit} />
<Form onSuccess={onProjectCreated} />

// Data Props: sustantivos descriptivos
<EvaluationPanel
  project={selectedProject}
  evaluations={evaluationsList}
/>
```

#### State Management

```javascript
// Estado Local: useState para UI efímero
const [isModalOpen, setIsModalOpen] = useState(false);

// Estado de Autenticación: Context API (useAuth)
const { userData, rol, isAuthenticated } = useAuth();

// Estado de Servidor: React Query (futuro recomendado)
const { data: projects, isLoading } = useQuery("projects", fetchProjects);
```

### 8.3. Convenciones de Base de Datos (Firestore)

#### Colecciones y Documentos

```
/users/{userId}                   ← Colección raíz de usuarios
/projects/{projectId}             ← Colección raíz de proyectos
/evaluations/{evaluationId}       ← Colección raíz de evaluaciones
/groups/{groupId}                 ← Colección administrativa
/materias/{materiaId}             ← Colección administrativa
/carreras/{carreraId}             ← Colección administrativa
```

**Regla**: Sin subcollections anidadas para simplificar queries. Usar referencias (IDs) en vez de embeds para relaciones.

#### Campos Reservados

Todos los documentos deben incluir:

```javascript
{
  "created_at": "2026-02-17T10:30:00Z",  // ISO 8601
  "updated_at": "2026-02-17T14:22:00Z",  // ISO 8601
  // ... campos específicos del documento
}
```

#### Indices Compuestos

Declarados en `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "projects",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "grupo_id", "order": "ASCENDING" },
        { "fieldPath": "estado", "order": "ASCENDING" }
      ]
    }
  ]
}
```

**Regla**: Todo query con múltiples filtros o ordenamiento requiere índice declarado.

### 8.4. Convenciones de API REST

#### Rutas

```
GET    /api/projects              ← Listar (con filtros en query)
POST   /api/projects              ← Crear
GET    /api/projects/{id}         ← Obtener por ID
PUT    /api/projects/{id}         ← Actualizar completo
PATCH  /api/projects/{id}         ← Actualizar parcial (no usado)
DELETE /api/projects/{id}         ← Eliminar

// Acciones específicas: sustantivo plural + ID + acción
POST   /api/projects/{id}/members      ← Agregar miembro
DELETE /api/projects/{id}/members/{memberId}  ← Eliminar miembro
PUT    /api/projects/{id}/canvas       ← Actualizar canvas
```

#### Status Codes

| Código                      | Uso                          | Ejemplo                        |
| --------------------------- | ---------------------------- | ------------------------------ |
| `200 OK`                    | Operación exitosa (GET, PUT) | GET /api/projects/123          |
| `201 Created`               | Recurso creado (POST)        | POST /api/projects             |
| `204 No Content`            | Eliminación exitosa          | DELETE /api/projects/123       |
| `400 Bad Request`           | Error de validación          | Payload inválido               |
| `401 Unauthorized`          | Sin token JWT                | Header Authorization faltante  |
| `403 Forbidden`             | Permiso denegado             | Docente intenta crear proyecto |
| `404 Not Found`             | Recurso no existe            | GET /api/projects/999          |
| `500 Internal Server Error` | Error no manejado            | Excepción en backend           |

---

## 9. ROADMAP DE UNIFICACIÓN

### Fase 1: Correcciones Críticas (Sprint Actual)

**Prioridad**: 🔴 Bloquea producción

| ID    | Tarea                                                | Estimación | Responsable Sugerido |
| ----- | ---------------------------------------------------- | ---------- | -------------------- |
| U-001 | Implementar JSON camelCase serialization en backend  | 2h         | Backend Dev          |
| U-002 | Eliminar `userId` de payloads frontend               | 4h         | Frontend Dev         |
| U-003 | Implementar extracción de `userId` desde JWT Claims  | 6h         | Backend Dev          |
| U-004 | Crear middleware de validación de token JWT          | 4h         | Backend Dev          |
| U-005 | Actualizar `API_DOCS.md` con convenciones de nombres | 2h         | Tech Writer          |

**Total Estimado**: 18 horas (2.5 días)

### Fase 2: Mejoras de Arquitectura (Próximo Sprint)

**Prioridad**: 🟡 Mejora calidad técnica

| ID    | Tarea                                               | Estimación | Responsable Sugerido |
| ----- | --------------------------------------------------- | ---------- | -------------------- |
| U-101 | Crear `ErrorResponse` estándar y documentar códigos | 4h         | Backend Dev          |
| U-102 | Implementar `GlobalExceptionHandler` middleware     | 6h         | Backend Dev          |
| U-103 | Documentar formato de upload en `API_DOCS.md`       | 1h         | Tech Writer          |
| U-104 | Agregar validación de tamaño/tipo MIME en Storage   | 3h         | Backend Dev          |
| U-105 | Normalizar rutas en todas las docs (lowercase)      | 2h         | Tech Writer          |
| U-106 | Crear `PermissionService.cs` centralizado           | 8h         | Backend Dev          |
| U-107 | Agregar tests de contrato para endpoints críticos   | 12h        | QA/Backend Dev       |

**Total Estimado**: 36 horas (4.5 días)

### Fase 3: Funcionalidades Avanzadas (Backlog)

**Prioridad**: 🟢 Nice-to-have

| ID    | Tarea                                   | Estimación | Dependencias               |
| ----- | --------------------------------------- | ---------- | -------------------------- |
| U-201 | Implementar notificaciones push (FCM)   | 16h        | U-003 (JWT)                |
| U-202 | Crear dashboard de analytics para Admin | 40h        | U-102 (logs estructurados) |
| U-203 | Migrar a Event Sourcing (opcional)      | 80h        | Decisión arquitectónica    |
| U-204 | Implementar GraphQL endpoint (opcional) | 40h        | U-107 (contratos)          |
| U-205 | Crear app móvil Flutter                 | 200h       | U-001, U-002, U-003        |

**Total Estimado**: 376 horas (47 días)

### Criterios de Aceptación por Fase

#### Fase 1 Completa Cuando:

- [ ] Todas las respuestas API usan camelCase consistente
- [ ] Frontend no envía `userId` en ningún payload
- [ ] Backend extrae `userId` de token JWT en TODOS los endpoints sensibles
- [ ] Middleware rechaza requests sin token válido con 401
- [ ] `API_DOCS.md` actualizado con ejemplos corregidos

#### Fase 2 Completa Cuando:

- [ ] Todos los errores siguen `ErrorResponse` schema
- [ ] `API_DOCS.md` documenta todos los códigos de error posibles
- [ ] Storage valida tamaño y MIME type, rechaza archivos inválidos
- [ ] Toda la documentación usa rutas lowercase
- [ ] `PermissionService` usado en todos los handlers que modifican recursos
- [ ] 80%+ cobertura de tests de contrato en endpoints críticos

#### Fase 3 Completa Cuando:

- [ ] Funcionalidad específica implementada y testeada
- [ ] Documentación actualizada
- [ ] Aprobada por Product Owner

---

## 10. REFERENCIAS Y RECURSOS

### Documentación Técnica

- **API Completa**: [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md)
- **Reglas de Negocio Detalladas**: [documentar/functions/BUSINESS_RULES.md](documentar/functions/BUSINESS_RULES.md)
- **Modelos de Datos**: [documentar/database/BIFROST_DATA_MODELS_CLASSES.md](documentar/database/BIFROST_DATA_MODELS_CLASSES.md)

### Documentación de Producto

- **Visión Ejecutiva**: [docs/BIFROST_EXECUTIVE_UNIFIED_v2.md](docs/BIFROST_EXECUTIVE_UNIFIED_v2.md)
- **Historias de Usuario (Alumno)**: [docs/news/BIFROST_STUDENT_BLUEPRINT.md](docs/news/BIFROST_STUDENT_BLUEPRINT.md)
- **Historias de Usuario (Docente)**: [docs/news/BIFROST_USER_STORIES.md](docs/news/BIFROST_USER_STORIES.md)
- **Configuración del Proyecto**: [docs/BIFROST_PROJECT_CONFIG.md](docs/BIFROST_PROJECT_CONFIG.md)

### Código Fuente

- **Backend**: `IntegradorHub/backend/src/IntegradorHub.API/`
- **Frontend**: `IntegradorHub/frontend/src/`
- **Entidades del Dominio**: `IntegradorHub/backend/src/IntegradorHub.API/Shared/Domain/Entities/`

### Herramientas y Dependencias

- **.NET 8 SDK**: https://dotnet.microsoft.com/download/dotnet/8.0
- **MediatR**: https://github.com/jbogard/MediatR
- **Firestore SDK**: https://cloud.google.com/firestore/docs/client/libraries
- **React 19**: https://react.dev/
- **Vite**: https://vitejs.dev/

---

**Última Actualización**: Febrero 18, 2026  
**Responsable**: Equipo IntegradorHub  
**Versión del Documento**: 1.0

- (B) Implementar una plantilla de `apiAdapters.js` en frontend y un ejemplo de test que demuestre la normalización de una respuesta real.

Elige A o B y procedo. Si eliges A, empezaré extrayendo campos de los DTOs backend y ejemplos del `API_DOCS.md` para los endpoints prioritarios.
