# 📋 BIFROST INTERFACE - ESPECIFICACIÓN DE REQUISITOS

**Proyecto**: Bifrost Interface - Sistema de Gestión y Evaluación de Proyectos Académicos  
**Versión**: 1.0  
**Fecha**: Febrero 2026  
**Institución**: Universidad Tecnológica Metropolitana  

---

## 📑 ÍNDICE

1. [Actores del Sistema](#actores-del-sistema)
2. [Requisitos Funcionales (RF)](#requisitos-funcionales)
   - [Módulo de Autenticación y Perfiles](#módulo-1-autenticación-y-perfiles)
   - [Módulo de Gestión de Proyectos](#módulo-2-gestión-de-proyectos)
   - [Módulo de Evaluación](#módulo-3-evaluación)
   - [Módulo de Showcase/Catálogo](#módulo-4-showcasecatálogo)
   - [Módulo de Notificaciones](#módulo-5-notificaciones)
   - [Módulo de Analytics](#módulo-6-analytics-y-reportes)
   - [Módulo Administrativo](#módulo-7-administrativo)
   - [Módulo de Recuperación](#módulo-8-recuperación-y-auditoría)
   - [Módulo Móvil Específico](#módulo-9-funcionalidades-móviles-específicas)
   - [Módulo de Colaboración](#módulo-10-colaboración-y-comunicación)
3. [Requisitos No Funcionales (RNF)](#requisitos-no-funcionales)

---

## 👥 ACTORES DEL SISTEMA

| Actor | Descripción | Identificación |
|-------|-------------|----------------|
| **Alumno** | Estudiante que crea y participa en proyectos | Correo con 8 dígitos: `12345678@utmetropolitana.edu.mx` |
| **Docente** | Profesor que evalúa proyectos | Correo con letras: `roberto.martinez@utmetropolitana.edu.mx` |
| **Administrador** | Personal con acceso completo al sistema | Rol asignado manualmente |
| **Invitado Público** | Visitante sin autenticación | Sin correo institucional |
| **Invitado Evaluador** | Empresa/jurado externo con permisos temporales | Correo verificado + rol temporal |
| **Sistema** | Actor automático para procesos internos | - |

---

## 🎯 REQUISITOS FUNCIONALES

### MÓDULO 1: AUTENTICACIÓN Y PERFILES

#### RF-AUTH-001: Registro con Correo Institucional
- **Prioridad**: Alta
- **Actor**: Alumno, Docente
- **Descripción**: El sistema debe permitir registro únicamente con correos @utmetropolitana.edu.mx
- **Criterios de aceptación**:
  - ✅ Validar dominio institucional
  - ✅ Detectar automáticamente el rol según formato del correo:
    - **Alumno**: Correo con 8 dígitos al inicio (Regex: `^(\d{8})@alumno.utmetropolitana\.edu\.mx$`)
    - **Docente**: Correo con letras/puntos al inicio (Regex: `^[a-zA-Z.]+@utmetropolitana\.edu\.mx$`)
  - ✅ Enviar email de verificación
  - ✅ Bloquear correos no institucionales con mensaje claro
- **Casos especiales**: 
  - Correos con formato mixto deben ser rechazados
  - Permitir registro con Google SSO institucional

#### RF-AUTH-002: Login con Google SSO
- **Prioridad**: Alta
- **Actor**: Alumno, Docente
- **Descripción**: Autenticación mediante Google Sign-In con cuentas institucionales
- **Criterios de aceptación**:
  - ✅ Botón "Continuar con Google" visible
  - ✅ Validar dominio después del SSO
  - ✅ Crear perfil automáticamente en primer login
  - ✅ Recordar sesión en dispositivo (persistent login)

#### RF-AUTH-003: Gestión de Perfil de Alumno
- **Prioridad**: Media
- **Actor**: Alumno
- **Descripción**: El alumno puede editar su perfil con información académica
- **Campos obligatorios**:
  - Matrícula (autocompletada desde correo)
  - Nombre completo
  - Grupo (selección desde catálogo: 4A, 4B, 5A, 5B...)
  - Cuatrimestre actual
- **Campos opcionales**:
  - Avatar (imagen)
  - Bio corta (máx. 200 caracteres)
  - Enlaces sociales (GitHub, LinkedIn, Portfolio)
  - Especialización (Frontend, Backend, Mobile, DevOps)

#### RF-AUTH-004: Gestión de Perfil de Docente
- **Prioridad**: Media
- **Actor**: Docente
- **Descripción**: El docente puede configurar su perfil profesional
- **Campos obligatorios**:
  - Nombre completo
  - Departamento
- **Campos opcionales**:
  - Título académico (Lic., Mtro., Dr.)
  - Avatar
  - Áreas de especialización (selección múltiple)
  - Disponibilidad para asesorías

#### RF-AUTH-005: Recuperación de Contraseña
- **Prioridad**: Media
- **Actor**: Alumno, Docente
- **Descripción**: Sistema de recuperación de contraseña por email
- **Criterios de aceptación**:
  - ✅ Link de recuperación válido por 1 hora
  - ✅ Requerir nueva contraseña con validación de fortaleza
  - ✅ Invalidar links anteriores al generar uno nuevo

#### RF-AUTH-006: Cierre de Sesión Multi-Dispositivo
- **Prioridad**: Baja
- **Actor**: Alumno, Docente
- **Descripción**: Permitir cerrar sesión en todos los dispositivos simultáneamente
- **Criterios de aceptación**:
  - ✅ Botón "Cerrar sesión en todos lados"
  - ✅ Invalidar todos los tokens JWT activos
  - ✅ Notificación de seguridad vía email

---

### MÓDULO 2: GESTIÓN DE PROYECTOS

#### RF-PROJ-001: Crear Proyecto Nuevo
- **Prioridad**: Alta
- **Actor**: Alumno
- **Descripción**: El alumno líder puede crear un nuevo proyecto integrador
- **Datos requeridos**:
  - Título (3-100 caracteres)
  - Descripción corta (máx. 300 caracteres)
  - Descripción detallada (Markdown, máx. 5000 caracteres)
  - Problemática que resuelve (texto)
  - Stack tecnológico (selección múltiple + campo libre)
  - Docente asesor (búsqueda filtrada por departamento)
  - Grupo al que pertenece (autocompletado desde perfil)
- **Validaciones**:
  - ✅ Alumno solo puede tener máximo 3 proyectos activos
  - ✅ Título debe ser único por cuatrimestre
  - ✅ Al menos 1 tecnología seleccionada

#### RF-PROJ-002: Agregar Miembros al Squad
- **Prioridad**: Alta
- **Actor**: Alumno (líder del proyecto)
- **Descripción**: El creador del proyecto puede invitar compañeros por correo institucional
- **Criterios de aceptación**:
  - ✅ Buscador con autocompletado (busca por nombre/matrícula)
  - ✅ Tooltip muestra grupo y cuatrimestre del alumno
  - ✅ Máximo 6 miembros por proyecto (configurable)
  - ✅ Solo alumnos del mismo grupo pueden ser agregados
  - ✅ Notificación automática al alumno invitado
  - ✅ El invitado debe aceptar/rechazar la invitación

#### RF-PROJ-003: Roles dentro del Squad
- **Prioridad**: Media
- **Actor**: Alumno (líder)
- **Descripción**: Asignar roles específicos a cada miembro del equipo
- **Roles disponibles**:
  - Líder (1 obligatorio, quien creó el proyecto)
  - Frontend Developer
  - Backend Developer
  - Mobile Developer
  - UI/UX Designer
  - DevOps
  - QA/Tester
- **Criterios de aceptación**:
  - ✅ Un miembro puede tener múltiples roles
  - ✅ Al menos 1 miembro debe tener rol técnico asignado

#### RF-PROJ-004: Upload de Multimedia
- **Prioridad**: Alta
- **Actor**: Alumno (cualquier miembro)
- **Descripción**: Subir archivos multimedia del proyecto
- **Tipos de archivo**:
  - **Banner/Cover** (1 imagen obligatoria):
    - Formatos: JPG, PNG, WebP
    - Tamaño máx: 5 MB
    - Dimensiones recomendadas: 1920x1080
  - **Screenshots** (hasta 10):
    - Formatos: JPG, PNG, WebP
    - Tamaño máx: 3 MB cada una
  - **Video Pitch** (1 video obligatorio):
    - Formatos: MP4, WebM
    - Duración máx: 5 minutos
    - Tamaño máx: 100 MB
    - Alternativamente: URL de YouTube/Vimeo
  - **Documentación PDF** (1 archivo obligatorio):
    - Formato: PDF
    - Tamaño máx: 10 MB
    - Debe incluir: introducción, problemática, solución, stack técnico
- **Validaciones**:
  - ✅ Compresión automática de imágenes >2 MB
  - ✅ Vista previa antes de confirmar upload
  - ✅ Indicador de progreso durante carga

#### RF-PROJ-005: Edición de Proyecto
- **Prioridad**: Alta
- **Actor**: Alumno (líder o miembros con permisos)
- **Descripción**: Modificar información del proyecto en cualquier momento
- **Restricciones**:
  - ❌ No se puede cambiar el líder del proyecto (solo admin puede)
  - ❌ No se puede editar si el proyecto está en estado "Histórico"
  - ✅ Se pueden agregar/remover miembros si aún está en "Borrador" o "Activo"
- **Registro de cambios**:
  - ✅ Cada edición genera un evento inmutable
  - ✅ Visible en historial de auditoría

#### RF-PROJ-006: Estados del Proyecto (Ciclo de Vida)
- **Prioridad**: Alta
- **Actor**: Alumno, Docente, Sistema
- **Descripción**: El proyecto transita por diferentes estados
- **Estados disponibles**:
  1. **Borrador** (inicial):
     - Visible solo para el squad y docente asesor
     - Puede ser editado libremente
     - No aparece en catálogo público
  2. **Activo** (listo para evaluación):
     - Todos los campos obligatorios completados
     - Visible para docentes evaluadores
     - Aparece en catálogo público
  3. **Público** (aprobado y destacado):
     - Al menos 3 evaluaciones recibidas
     - Score promedio ≥ 70/100
     - Aparece en showcase destacado
  4. **Histórico** (archivado):
     - Proyecto de cuatrimestres anteriores
     - Solo lectura
     - Aparece en catálogo de casos de estudio
  5. **Pausado** (temporalmente inactivo):
     - El squad decidió pausar el desarrollo
     - No aparece en evaluaciones activas
- **Transiciones permitidas**:
  - Borrador → Activo (alumno, si cumple requisitos)
  - Activo → Público (sistema automático, si cumple umbral de score)
  - Activo/Público → Histórico (sistema automático al finalizar cuatrimestre)
  - Activo → Pausado (alumno líder)
  - Pausado → Activo (alumno líder)

#### RF-PROJ-007: Eliminación de Proyecto
- **Prioridad**: Baja
- **Actor**: Alumno (líder), Administrador
- **Descripción**: Eliminar un proyecto antes de publicarlo
- **Restricciones**:
  - ✅ Solo proyectos en estado "Borrador" pueden eliminarse
  - ✅ Requiere confirmación con contraseña
  - ✅ Genera evento "ProyectoEliminado" (soft delete, no borra de EventStore)
  - ✅ Notifica a todos los miembros del squad

#### RF-PROJ-008: Duplicar Proyecto (Fork)
- **Prioridad**: Baja
- **Actor**: Alumno
- **Descripción**: Crear una copia de un proyecto histórico como base para uno nuevo
- **Criterios de aceptación**:
  - ✅ Solo disponible para proyectos en estado "Histórico" o "Público"
  - ✅ Se copia: título (con sufijo "v2"), descripción, stack tecnológico
  - ✅ No se copian: multimedia, evaluaciones, miembros
  - ✅ Referencia al proyecto original visible

#### RF-PROJ-009: Exportación de Proyecto
- **Prioridad**: Media
- **Actor**: Alumno (miembros del squad)
- **Descripción**: Descargar información del proyecto en formato portable
- **Formatos disponibles**:
  - PDF (documento completo con multimedia embebida)
  - JSON (metadata estructurada para APIs)
  - Markdown (README.md estilo GitHub)
- **Contenido exportado**:
  - Toda la información del proyecto
  - Evaluaciones recibidas (solo promedios, no nombres de evaluadores)
  - Score histórico
  - Estadísticas de visualizaciones

#### RF-PROJ-010: Búsqueda Avanzada de Proyectos
- **Prioridad**: Media
- **Actor**: Todos
- **Descripción**: Buscador con filtros múltiples
- **Filtros disponibles**:
  - Texto libre (título, descripción, tecnologías)
  - Stack tecnológico (selección múltiple)
  - Grupo (4A, 4B, 5A, 5B...)
  - Cuatrimestre (Ene-Abr 2026, May-Ago 2026...)
  - Score mínimo (slider 0-100)
  - Estado (Activo, Público, Histórico)
  - Orden: Relevancia, Score, Fecha, Visualizaciones
- **Resultados**:
  - ✅ Paginación (20 proyectos por página)
  - ✅ Vista de tarjeta con preview
  - ✅ Lazy loading de imágenes

---

### MÓDULO 3: EVALUACIÓN

#### RF-EVAL-001: Evaluar Proyecto (Docente)
- **Prioridad**: Alta
- **Actor**: Docente
- **Descripción**: El docente puede calificar proyectos con criterios específicos
- **Criterios de evaluación** (cada uno de 0-100 puntos):
  1. **Innovación y Creatividad** (20%)
     - ¿Qué tan original es la solución?
  2. **Complejidad Técnica** (30%)
     - ¿Qué tan desafiante fue el stack implementado?
  3. **Calidad de Documentación** (15%)
     - ¿Qué tan completo y claro es el PDF/README?
  4. **Presentación y UX** (15%)
     - ¿Qué tan profesional se ve el producto?
  5. **Funcionalidad Completa** (20%)
     - ¿El proyecto funciona según lo prometido?
- **Interfaz de evaluación**:
  - ✅ Sliders touch-optimizados para cada criterio
  - ✅ Vista previa del proyecto en panel lateral (PDF, video, screenshots)
  - ✅ Campo de retroalimentación obligatorio (mín. 100 caracteres)
  - ✅ Separación clara: Fortalezas / Áreas de mejora / Sugerencias
- **Restricciones**:
  - ❌ Un docente no puede evaluar el mismo proyecto más de una vez
  - ✅ Solo proyectos en estado "Activo" o "Público" pueden ser evaluados
  - ✅ La evaluación genera un evento inmutable "EvaluacionRegistrada"

#### RF-EVAL-002: Evaluación Rápida (Móvil)
- **Prioridad**: Alta
- **Actor**: Docente
- **Descripción**: Versión simplificada de evaluación para app móvil
- **Flujo optimizado**:
  1. Escanear QR del proyecto (generado automáticamente)
  2. Ver resumen del proyecto
  3. Calificar con gestos touch nativos
  4. Dictar retroalimentación por voz (speech-to-text)
  5. Enviar en ~3 minutos
- **Criterios de aceptación**:
  - ✅ Modo offline: guardar en queue local si no hay conexión
  - ✅ Sincronización automática al recuperar WiFi
  - ✅ Indicador visual de evaluaciones pendientes de sincronizar

#### RF-EVAL-003: Templates de Retroalimentación
- **Prioridad**: Media
- **Actor**: Docente
- **Descripción**: Sugerencias predefinidas de feedback para acelerar evaluación
- **Ejemplos de templates**:
  - Fortalezas:
    - "Excelente arquitectura de código limpio y modular"
    - "Implementación completa de buenas prácticas de seguridad"
    - "Diseño UI/UX profesional y consistente"
  - Áreas de mejora:
    - "Falta manejo de errores en módulo de autenticación"
    - "Documentación técnica incompleta en sección de deployment"
    - "Performance deficiente en carga de listas grandes"
- **Criterios de aceptación**:
  - ✅ Dropdown de templates por categoría
  - ✅ Posibilidad de editar el texto sugerido
  - ✅ Agregar templates personalizados (guardados por docente)

#### RF-EVAL-004: Edición de Evaluación
- **Prioridad**: Media
- **Actor**: Docente
- **Descripción**: Modificar una evaluación ya enviada (con restricciones)
- **Restricciones**:
  - ✅ Solo editable dentro de las primeras 24 horas
  - ✅ Requiere confirmación con contraseña
  - ✅ Genera evento "EvaluacionModificada" (no sobrescribe la original)
  - ✅ Notificación al squad del proyecto
  - ✅ Visible en historial de auditoría

#### RF-EVAL-005: Peer Review (Evaluación entre Alumnos)
- **Prioridad**: Baja
- **Actor**: Alumno
- **Descripción**: Permitir que alumnos de otros grupos califiquen proyectos
- **Restricciones**:
  - ✅ Peso del 10% en score final (90% son docentes)
  - ✅ Máximo 3 peer reviews por proyecto
  - ✅ El alumno no puede evaluar su propio proyecto ni proyectos de su grupo
  - ✅ Criterios simplificados (3 en lugar de 5)
- **Incentivo**:
  - ✅ Alumnos que den peer reviews de calidad reciben badge "Colaborador"

#### RF-EVAL-006: Evaluación por Invitado Externo
- **Prioridad**: Baja
- **Actor**: Invitado Evaluador
- **Descripción**: Empresas o jurados externos pueden evaluar en ferias
- **Proceso**:
  1. Administrador crea cuenta temporal con email externo
  2. Asigna rol "Invitado Evaluador" con fecha de expiración
  3. El invitado accede con credenciales temporales
  4. Puede evaluar solo proyectos asignados manualmente
- **Criterios de aceptación**:
  - ✅ Peso del 15% en score final (configurable)
  - ✅ Cuenta expira automáticamente después de 7 días
  - ✅ Badge visible "Evaluado por [Empresa]" en el proyecto

#### RF-EVAL-007: Solicitar Retroalimentación Adicional
- **Prioridad**: Baja
- **Actor**: Alumno
- **Descripción**: El squad puede solicitar feedback a un docente específico
- **Criterios de aceptación**:
  - ✅ Máximo 2 solicitudes por proyecto
  - ✅ El docente recibe notificación y puede aceptar/rechazar
  - ✅ Si acepta, el proyecto se agrega a su lista de pendientes
  - ✅ Tiempo de respuesta recomendado: 5 días hábiles

#### RF-EVAL-008: Historial de Evaluaciones Recibidas
- **Prioridad**: Media
- **Actor**: Alumno (miembros del squad)
- **Descripción**: Visualizar todas las evaluaciones del proyecto en línea de tiempo
- **Información mostrada**:
  - Nombre del evaluador (o "Anónimo" si el evaluador lo marca así)
  - Fecha y hora de evaluación
  - Scores por criterio
  - Retroalimentación completa
  - Gráfica de evolución del score promedio
- **Criterios de aceptación**:
  - ✅ Ordenado por fecha (más reciente primero)
  - ✅ Filtros: Tipo de evaluador (Docente/Alumno/Externo)
  - ✅ Exportar historial a PDF

---

### MÓDULO 4: SHOWCASE/CATÁLOGO

#### RF-SHOW-001: Galería Pública de Proyectos
- **Prioridad**: Alta
- **Actor**: Invitado Público, Todos
- **Descripción**: Página principal con proyectos destacados
- **Secciones**:
  - **Destacados** (Top 10 por score)
  - **Recientes** (últimos 20 publicados)
  - **Trending** (más visualizados en últimos 7 días)
  - **Por Tecnología** (agrupados por stack)
- **Vista de tarjeta incluye**:
  - Banner del proyecto
  - Título
  - Descripción corta
  - Stack tecnológico (badges)
  - Score promedio (estrellas + número)
  - Grupo y cuatrimestre
  - Número de visualizaciones
- **Criterios de aceptación**:
  - ✅ Solo proyectos "Público" y "Histórico" visibles
  - ✅ Lazy loading de imágenes
  - ✅ Infinite scroll
  - ✅ Responsive (mobile-first)

#### RF-SHOW-002: Página de Detalle de Proyecto
- **Prioridad**: Alta
- **Actor**: Todos
- **Descripción**: Vista completa de un proyecto individual
- **Secciones**:
  - **Hero Section**: Banner, título, score, acciones
  - **Overview**: Descripción, problemática, solución
  - **Stack Tecnológico**: Badges con logos
  - **Squad**: Fotos y roles de miembros
  - **Multimedia**: Galería de screenshots + video embebido
  - **Documentación**: Visor de PDF embebido
  - **Evaluaciones**: Promedio de scores por criterio (sin nombres)
  - **Proyectos Relacionados**: Por tecnología o grupo
- **Acciones disponibles**:
  - Compartir (copiar link, WhatsApp, LinkedIn, Twitter)
  - Descargar PDF de documentación
  - Ver repositorio GitHub (si está vinculado)
  - Reportar contenido inapropiado
- **Contador de visualizaciones**:
  - ✅ Incrementar cada vez que se abre (1 vez por usuario/sesión)
  - ✅ Visible públicamente

#### RF-SHOW-003: Leaderboard/Ranking
- **Prioridad**: Alta
- **Actor**: Todos
- **Descripción**: Tabla de posiciones de proyectos
- **Criterios de ranking**:
  - Score promedio (peso 70%)
  - Número de evaluaciones (peso 15%)
  - Visualizaciones (peso 10%)
  - Complejidad técnica (peso 5%)
- **Vistas disponibles**:
  - General (todos los proyectos activos)
  - Por grupo (4A, 4B, 5A, 5B)
  - Por cuatrimestre
  - Histórico (todos los tiempos)
- **Información mostrada**:
  - Posición (#1, #2, #3...)
  - Cambio de posición (↗️ +2, ↘️ -1, → sin cambios)
  - Proyecto (nombre + banner pequeño)
  - Squad líder
  - Score
  - Número de evaluaciones
- **Criterios de aceptación**:
  - ✅ Actualización en tiempo real (Firestore listeners)
  - ✅ Paginación (top 50 visible, resto bajo demanda)
  - ✅ Indicadores visuales especiales para top 3

#### RF-SHOW-004: Filtros por Stack Tecnológico
- **Prioridad**: Media
- **Actor**: Todos
- **Descripción**: Explorar proyectos por tecnologías específicas
- **Tecnologías categorizadas**:
  - Frontend: React, Vue, Angular, Flutter, React Native...
  - Backend: Node.js, .NET, Java, Python, Go...
  - Bases de datos: MySQL, PostgreSQL, MongoDB, Firebase...
  - Cloud: AWS, Azure, GCP, Heroku...
  - Otros: Docker, Kubernetes, CI/CD...
- **Criterios de aceptación**:
  - ✅ Selección múltiple (AND lógico: "React Y .NET Y Firebase")
  - ✅ Contador de proyectos por tecnología
  - ✅ Autocompletado en búsqueda de tecnología

#### RF-SHOW-005: Compartir Proyecto en Redes Sociales
- **Prioridad**: Media
- **Actor**: Alumno, Todos
- **Descripción**: Generar links optimizados con preview cards
- **Plataformas soportadas**:
  - LinkedIn (Open Graph optimizado)
  - Twitter/X (Twitter Cards)
  - WhatsApp (preview con imagen)
  - Facebook
  - Email (mailto con template)
- **Metadata generada automáticamente**:
  - og:title = Nombre del proyecto
  - og:description = Descripción corta
  - og:image = Banner del proyecto
  - og:url = bifrost.utm.edu.mx/proyecto/[slug]
- **Criterios de aceptación**:
  - ✅ Botones de compartir visibles en página de detalle
  - ✅ Tracking de shares (analytics)
  - ✅ Copiar link con un clic (clipboard API)

#### RF-SHOW-006: Modo de Vista para Impresión
- **Prioridad**: Baja
- **Actor**: Alumno, Docente
- **Descripción**: Versión optimizada para imprimir proyecto
- **Formato**:
  - Portada con banner y título
  - Información del squad
  - Descripción y problemática
  - Stack tecnológico
  - Scores promedio
  - Evaluaciones resumidas
- **Criterios de aceptación**:
  - ✅ CSS @media print optimizado
  - ✅ Ocultar elementos de navegación
  - ✅ Salto de página automático entre secciones
  - ✅ Opción "Guardar como PDF"

#### RF-SHOW-007: Proyectos Históricos (Archivo)
- **Prioridad**: Media
- **Actor**: Todos
- **Descripción**: Catálogo de proyectos de cuatrimestres anteriores
- **Funcionalidades**:
  - Filtrado por cuatrimestre (timeline visual)
  - Búsqueda por tecnología o grupo
  - Casos de estudio destacados (curated list)
  - Badge "Proyecto Histórico" visible
- **Criterios de aceptación**:
  - ✅ Migración automática a estado "Histórico" al finalizar cuatrimestre
  - ✅ Solo lectura (no se puede editar)
  - ✅ Disponible para "Fork" por nuevas generaciones

---

### MÓDULO 5: NOTIFICACIONES

#### RF-NOTIF-001: Notificación de Nueva Evaluación
- **Prioridad**: Alta
- **Actor**: Alumno (squad)
- **Descripción**: Notificar cuando el proyecto recibe una calificación
- **Canales**:
  - Push notification (móvil)
  - In-app notification (web)
  - Email (opcional, configurable)
- **Contenido**:
  - "Tu proyecto '[Nombre]' fue evaluado por [Docente]"
  - Score recibido
  - Enlace directo a evaluación
- **Criterios de aceptación**:
  - ✅ Todos los miembros del squad reciben notificación
  - ✅ Agrupación: si recibe 3 evaluaciones en 1 hora, enviar 1 sola notificación
  - ✅ Respeto de horarios: no enviar entre 10 PM - 7 AM

#### RF-NOTIF-002: Notificación de Cambio en Ranking
- **Prioridad**: Media
- **Actor**: Alumno (squad)
- **Descripción**: Alertar cuando el proyecto sube/baja en el leaderboard
- **Criterios de activación**:
  - Cambio de ≥3 posiciones
  - Entrada al Top 10
  - Entrada al Top 3
- **Contenido**:
  - "¡Tu proyecto subió al #5! (+7 posiciones)"
  - Emoji según cambio: 🚀 (subida), 📉 (bajada)
- **Criterios de aceptación**:
  - ✅ Máximo 1 notificación de ranking por día por proyecto
  - ✅ Desactivable en configuración de usuario

#### RF-NOTIF-003: Notificación de Invitación a Proyecto
- **Prioridad**: Alta
- **Actor**: Alumno (invitado)
- **Descripción**: Alertar cuando alguien te agrega a un proyecto
- **Contenido**:
  - "[Nombre] te invitó a unirte a '[Proyecto]'"
  - Botones: Aceptar / Rechazar
  - Vista previa del proyecto
- **Criterios de aceptación**:
  - ✅ Notificación persiste hasta que se tome una acción
  - ✅ Recordatorio automático después de 48 horas si no hay respuesta
  - ✅ Si se rechaza, el líder del proyecto es notificado

#### RF-NOTIF-004: Notificación de Cambios en Proyecto (Squad)
- **Prioridad**: Baja
- **Actor**: Alumno (miembros del squad)
- **Descripción**: Alertar sobre cambios importantes en el proyecto
- **Eventos que generan notificación**:
  - Nuevo miembro agregado
  - Miembro removido
  - Estado del proyecto cambió (ej: Borrador → Activo)
  - Documentación actualizada
  - Video/banner cambiado
- **Criterios de aceptación**:
  - ✅ Batch notifications: agrupar cambios en 1 hora
  - ✅ El autor del cambio NO recibe notificación
  - ✅ Desactivable por tipo de evento

#### RF-NOTIF-005: Notificación de Solicitud de Feedback
- **Prioridad**: Media
- **Actor**: Docente
- **Descripción**: Alertar al docente cuando un squad solicita evaluación
- **Contenido**:
  - "El proyecto '[Nombre]' solicita tu retroalimentación"
  - Vista previa del proyecto
  - Botones: Ver Proyecto / Evaluar Ahora
- **Criterios de aceptación**:
  - ✅ Solo si el docente tiene habilitadas notificaciones de solicitudes
  - ✅ Recordatorio después de 3 días si no hay acción

#### RF-NOTIF-006: Centro de Notificaciones
- **Prioridad**: Media
- **Actor**: Todos
- **Descripción**: Panel centralizado con historial de notificaciones
- **Funcionalidades**:
  - Lista de notificaciones ordenadas por fecha
  - Filtros: No leídas / Todas / Por tipo
  - Marcar como leído/no leído
  - Borrar notificación individual
  - "Marcar todas como leídas"
  - Badge con contador en campana de notificaciones
- **Criterios de aceptación**:
  - ✅ Máximo 50 notificaciones guardadas
  - ✅ Auto-limpieza de notificaciones >30 días
  - ✅ Actualización en tiempo real (Firestore listeners)

#### RF-NOTIF-007: Preferencias de Notificaciones
- **Prioridad**: Media
- **Actor**: Todos
- **Descripción**: Configuración granular de qué notificaciones recibir
- **Opciones por canal**:
  - Push (móvil)
  - In-app (web)
  - Email
- **Opciones por tipo**:
  - Evaluaciones recibidas ✅
  - Cambios en ranking ✅
  - Invitaciones a proyectos ✅
  - Cambios en proyectos donde participo ✅
  - Solicitudes de feedback (solo docentes) ✅
  - Nuevos proyectos publicados (solo docentes) ⬜
- **Criterios de aceptación**:
  - ✅ Interruptor toggle para cada combinación canal-tipo
  - ✅ Opción "Silenciar todo" temporal (1 día, 3 días, 1 semana)
  - ✅ Respeto de horario nocturno (10 PM - 7 AM)

---

### MÓDULO 6: ANALYTICS Y REPORTES

#### RF-ANALYT-001: Dashboard de Estudiante
- **Prioridad**: Media
- **Actor**: Alumno
- **Descripción**: Métricas personales sobre proyectos donde participa
- **Widgets**:
  - Mis Proyectos (tarjetas con resumen)
  - Score promedio por proyecto
  - Posición en ranking
  - Evaluaciones recibidas (total y por proyecto)
  - Visualizaciones totales
  - Tecnologías más usadas (word cloud)
  - Evolución de scores (gráfica de línea)
- **Criterios de aceptación**:
  - ✅ Actualización en tiempo real
  - ✅ Filtros por cuatrimestre
  - ✅ Comparación con promedio de grupo

#### RF-ANALYT-002: Dashboard de Docente
- **Prioridad**: Media
- **Actor**: Docente
- **Descripción**: Estadísticas de actividad de evaluación
- **Widgets**:
  - Proyectos evaluados (total y este cuatrimestre)
  - Tiempo promedio de evaluación
  - Distribución de scores dados (histograma)
  - Proyectos pendientes de evaluar
  - Grupos más evaluados
  - Tecnologías más vistas en proyectos
  - Comparativa de criterios (radar chart): ¿en qué criterio soy más estricto?
- **Criterios de aceptación**:
  - ✅ Exportar reporte a PDF
  - ✅ Filtros por cuatrimestre y grupo
  - ✅ Comparación con promedio de otros docentes (anónimo)

#### RF-ANALYT-003: Dashboard Administrativo (General)
- **Prioridad**: Alta
- **Actor**: Administrador
- **Descripción**: Métricas institucionales del sistema
- **Secciones**:
  1. **Actividad del Sistema**:
     - Usuarios registrados (total y activos/mes)
     - Proyectos creados por cuatrimestre
     - Evaluaciones realizadas por cuatrimestre
     - Tráfico web (pageviews, unique visitors)
  2. **Calidad Académica**:
     - Score promedio general por cuatrimestre
     - Distribución de scores (histograma)
     - Proyectos con >90 puntos (destacados)
     - Grupos con mejor desempeño
  3. **Engagement**:
     - DAU (Daily Active Users)
     - Session duration promedio
     - Tasa de conversión (registro → proyecto publicado)
     - Tasa de evaluación (docentes activos / total)
  4. **Tecnologías Trending**:
     - Stack más usado en proyectos publicados
     - Evolución temporal de tecnologías
     - Tecnologías emergentes (nuevas este cuatrimestre)
  5. **Performance Técnico**:
     - Uptime del sistema
     - Response time API (P95)
     - Eventos en EventStore (total acumulado)
     - Tamaño de storage (GB usado)
- **Criterios de aceptación**:
  - ✅ Actualización cada 5 minutos
  - ✅ Exportar cualquier gráfica a PNG/PDF
  - ✅ Comparación año-sobre-año
  - ✅ Alertas automáticas si métricas críticas bajan (ej: uptime <99%)

#### RF-ANALYT-004: Reporte de Cuatrimestre (Exportable)
- **Prioridad**: Media
- **Actor**: Administrador
- **Descripción**: Documento completo con resultados del cuatrimestre
- **Contenido**:
  - Resumen ejecutivo
  - Estadísticas generales
  - Top 10 proyectos
  - Análisis de tecnologías usadas
  - Comparativa con cuatrimestre anterior
  - Recomendaciones para mejora
- **Formatos**:
  - PDF (diseño profesional con gráficas)
  - Excel (datos crudos para análisis)
  - PowerPoint (presentación ejecutiva)
- **Criterios de aceptación**:
  - ✅ Generación automática al finalizar cuatrimestre
  - ✅ Plantilla personalizable con logo UTM
  - ✅ Envío automático por email a Dirección Académica

#### RF-ANALYT-005: Análisis de Evaluadores
- **Prioridad**: Baja
- **Actor**: Administrador
- **Descripción**: Métricas sobre comportamiento de evaluadores
- **Análisis**:
  - Docente más activo (más evaluaciones)
  - Docente más estricto (scores más bajos promedio)
  - Docente más generoso (scores más altos)
  - Tiempo promedio de evaluación por docente
  - Consistencia de evaluaciones (desviación estándar)
- **Uso**:
  - Identificar docentes que requieren capacitación
  - Reconocer docentes comprometidos
  - Ajustar pesos de evaluaciones si hay sesgo
- **Criterios de aceptación**:
  - ✅ Datos anónimos si se comparten públicamente
  - ✅ Solo admin puede ver nombres de docentes en análisis

#### RF-ANALYT-006: Tracking de Eventos Personalizados
- **Prioridad**: Baja
- **Actor**: Administrador
- **Descripción**: Rastrear eventos específicos de interacción
- **Eventos rastreados**:
  - Click en "Ver Proyecto"
  - Reproducción de video pitch (% reproducido)
  - Descarga de PDF
  - Clicks en tecnologías (para ver cuáles interesan más)
  - Tiempo de permanencia en página de detalle
  - Compartir en redes sociales
- **Criterios de aceptación**:
  - ✅ Integración con Google Analytics 4
  - ✅ Dashboards personalizados en GA4
  - ✅ Respetar privacidad (GDPR-compliant, aunque México no requiere)

---

### MÓDULO 7: ADMINISTRATIVO

#### RF-ADMIN-001: Gestión de Usuarios
- **Prioridad**: Alta
- **Actor**: Administrador
- **Descripción**: CRUD completo de usuarios del sistema
- **Funcionalidades**:
  - Listar todos los usuarios (tabla con filtros)
  - Buscar por nombre, email, matrícula
  - Ver perfil completo de usuario
  - Editar información de usuario
  - Cambiar rol manualmente (Alumno → Docente si hay error)
  - Suspender cuenta temporalmente (ban)
  - Eliminar cuenta permanentemente (con confirmación)
- **Filtros disponibles**:
  - Por rol (Alumno, Docente, Admin)
  - Por grupo (solo alumnos)
  - Por estado (Activo, Suspendido)
  - Por fecha de registro
- **Criterios de aceptación**:
  - ✅ Paginación (50 usuarios por página)
  - ✅ Exportar lista a Excel
  - ✅ Log de auditoría de cambios realizados

#### RF-ADMIN-002: Gestión de Proyectos
- **Prioridad**: Alta
- **Actor**: Administrador
- **Descripción**: Control total sobre todos los proyectos
- **Funcionalidades**:
  - Listar todos los proyectos (incluyendo Borradores)
  - Editar cualquier proyecto
  - Cambiar estado de proyecto manualmente
  - Eliminar proyecto (soft delete)
  - Destacar proyecto en home (featured flag)
  - Marcar como "Caso de Estudio" (curated)
  - Transferir líder del proyecto a otro miembro
- **Acciones masivas**:
  - Migrar múltiples proyectos a estado "Histórico"
  - Eliminar proyectos de cuatrimestre específico
  - Re-calcular scores de múltiples proyectos
- **Criterios de aceptación**:
  - ✅ Confirmación en dos pasos para eliminaciones
  - ✅ Log de auditoría de cambios
  - ✅ Notificación al squad afectado

#### RF-ADMIN-003: Gestión de Evaluaciones
- **Prioridad**: Media
- **Actor**: Administrador
- **Descripción**: Supervisión de evaluaciones realizadas
- **Funcionalidades**:
  - Listar todas las evaluaciones
  - Ver detalle de evaluación (scores + retroalimentación)
  - Eliminar evaluación fraudulenta
  - Editar evaluación (con justificación en log)
  - Re-calcular score de proyecto después de eliminar evaluación
  - Marcar evaluación como "Destacada" (aparece en showcase)
- **Filtros**:
  - Por evaluador (docente específico)
  - Por proyecto
  - Por rango de fechas
  - Por score (ej: solo evaluaciones <50 para revisar)
- **Criterios de aceptación**:
  - ✅ Toda modificación genera evento de auditoría
  - ✅ Notificación al evaluador y al squad si se elimina

#### RF-ADMIN-004: Configuración de Catálogos
- **Prioridad**: Media
- **Actor**: Administrador
- **Descripción**: Administrar listas maestras del sistema
- **Catálogos editables**:
  1. **Grupos**:
     - Agregar/eliminar grupos (4A, 4B, 5A, 5B, 6A...)
     - Asignar cuatrimestre activo a cada grupo
  2. **Tecnologías**:
     - Agregar nueva tecnología al catálogo
     - Editar nombre/logo de tecnología
     - Categorizar (Frontend, Backend, DB, Cloud...)
     - Desactivar tecnologías obsoletas
  3. **Criterios de Evaluación**:
     - Editar nombres de criterios
     - Cambiar pesos porcentuales (debe sumar 100%)
     - Agregar/remover criterios (requiere migración de datos)
  4. **Templates de Retroalimentación**:
     - CRUD de templates globales para docentes
- **Criterios de aceptación**:
  - ✅ Validaciones de integridad (ej: no eliminar grupo con proyectos activos)
  - ✅ Migración automática si se cambian criterios
  - ✅ Versionado de configuraciones (EventStore)

#### RF-ADMIN-005: Gestión de Cuatrimestres
- **Prioridad**: Alta
- **Actor**: Administrador
- **Descripción**: Administrar periodos académicos
- **Funcionalidades**:
  - Crear nuevo cuatrimestre (ej: "Ene-Abr 2026")
  - Marcar cuatrimestre como "Activo"
  - Cerrar cuatrimestre (migra todos proyectos activos a "Histórico")
  - Ver resumen de cuatrimestre (proyectos, evaluaciones, scores)
- **Reglas de negocio**:
  - Solo 1 cuatrimestre puede estar activo a la vez
  - Al cerrar cuatrimestre, genera reporte automático
  - Proyectos en "Borrador" no migran a "Histórico" (se eliminan)
- **Criterios de aceptación**:
  - ✅ Confirmación en dos pasos para cerrar cuatrimestre
  - ✅ Notificación masiva a todos los usuarios
  - ✅ Generación automática de reporte (RF-ANALYT-004)

#### RF-ADMIN-006: Logs de Auditoría (EventStore Viewer)
- **Prioridad**: Alta
- **Actor**: Administrador
- **Descripción**: Visualizar historial completo de eventos del sistema
- **Funcionalidades**:
  - Buscar eventos por tipo (ProyectoCreado, EvaluacionRegistrada...)
  - Filtrar por usuario (ver todo lo que hizo X persona)
  - Filtrar por aggregateId (historial de un proyecto específico)
  - Filtrar por rango de fechas
  - Ver payload completo del evento (JSON)
  - Exportar eventos a JSON/CSV
- **Casos de uso**:
  - Investigación forense: "¿Quién modificó este proyecto?"
  - Auditoría académica: "¿Cuándo se evaluó este proyecto?"
  - Resolución de disputas: "Mostrar historial completo"
- **Criterios de aceptación**:
  - ✅ Paginación (100 eventos por página)
  - ✅ Búsqueda avanzada con múltiples filtros
  - ✅ Syntax highlighting para JSON

#### RF-ADMIN-007: Configuración de Sistema
- **Prioridad**: Media
- **Actor**: Administrador
- **Descripción**: Parámetros globales del sistema
- **Configuraciones disponibles**:
  - **Límites**:
    - Max proyectos activos por alumno (default: 3)
    - Max miembros por proyecto (default: 6)
    - Max tamaño de archivos (banner, PDF, video)
  - **Umbrales**:
    - Score mínimo para estado "Público" (default: 70)
    - Min evaluaciones para ranking (default: 3)
  - **Notificaciones**:
    - Horario nocturno (default: 10 PM - 7 AM)
    - Max notificaciones por día por usuario (default: 20)
  - **Mantenimiento**:
    - Modo mantenimiento (desactiva acceso para no-admins)
    - Mensaje personalizado de mantenimiento
- **Criterios de aceptación**:
  - ✅ Cambios aplican inmediatamente (cache invalidation)
  - ✅ Log de cambios de configuración
  - ✅ Validación de valores (ej: score mínimo no puede ser >100)

#### RF-ADMIN-008: Moderación de Contenido
- **Prioridad**: Media
- **Actor**: Administrador
- **Descripción**: Revisar y actuar sobre reportes de contenido inapropiado
- **Funcionalidades**:
  - Cola de proyectos reportados
  - Ver razón del reporte
  - Ver contenido reportado (título, descripción, multimedia)
  - Acciones posibles:
    - Aprobar (descartar reporte)
    - Editar proyecto (remover contenido ofensivo)
    - Suspender proyecto (ocultar temporalmente)
    - Eliminar proyecto
    - Suspender usuario que lo creó
- **Criterios de aceptación**:
  - ✅ Notificación al usuario reportado con justificación
  - ✅ Opción de apelar suspensión
  - ✅ Log de decisiones de moderación

---

### MÓDULO 8: RECUPERACIÓN Y AUDITORÍA

#### RF-RECOV-001: Endpoint de Rehidratación Manual
- **Prioridad**: Crítica
- **Actor**: Administrador
- **Descripción**: Reconstruir ReadModel desde EventStore en caso de corrupción
- **Endpoint**: `POST /api/maintenance/rehydrate`
- **Parámetros**:
  - `targetCollection`: Colección a reconstruir (ej: "ProyectosVista")
  - `fromTimestamp`: Fecha desde la cual replay (opcional, default: inicio)
  - `aggregateIds`: Lista de IDs específicos a reconstruir (opcional, default: todos)
- **Proceso**:
  1. Validar autenticación de admin
  2. Leer eventos desde EventStore ordenados por timestamp
  3. Replay de eventos aplicando lógica de proyección
  4. Reconstruir documentos en ReadModel
  5. Validar integridad de datos reconstruidos
  6. Retornar reporte de rehidratación
- **Criterios de aceptación**:
  - ✅ Timeout de 300 segundos (5 minutos)
  - ✅ Progress updates cada 10% (websocket/SSE)
  - ✅ Rollback automático si falla validación
  - ✅ Log detallado de operación
  - ✅ Notificación a equipo técnico por email

#### RF-RECOV-002: Snapshot Automático Periódico
- **Prioridad**: Media
- **Actor**: Sistema
- **Descripción**: Crear snapshots del ReadModel para optimizar rehidratación
- **Frecuencia**: Diario a las 2:00 AM
- **Proceso**:
  - Crear copia completa de ProyectosVista en colección /Snapshots/
  - Incluir timestamp y número de versión
  - Comprimir datos (JSON.stringify + gzip)
  - Guardar en Firebase Storage
  - Retener últimos 7 snapshots, eliminar anteriores
- **Criterios de aceptación**:
  - ✅ No afectar performance del sistema (horario nocturno)
  - ✅ Validar snapshot después de crearlo
  - ✅ Alerta si snapshot falla 2 días consecutivos

#### RF-RECOV-003: Replay Temporal (Time Travel)
- **Prioridad**: Baja
- **Actor**: Administrador
- **Descripción**: Ver estado del sistema en una fecha pasada
- **Endpoint**: `POST /api/maintenance/replay-to-date`
- **Parámetros**:
  - `targetDate`: Fecha y hora a la cual volver (ISO 8601)
  - `scope`: "global" (todo el sistema) o aggregateId específico
- **Resultado**:
  - Estado del sistema/proyecto como estaba en esa fecha
  - Solo visualización (read-only), no altera estado actual
- **Casos de uso**:
  - "¿Cómo estaba el proyecto X el 15 de enero?"
  - "¿Qué score tenía el proyecto cuando fue evaluado por el docente Y?"
- **Criterios de aceptación**:
  - ✅ Resultado en <10 segundos para 1 proyecto
  - ✅ Resultado en <60 segundos para scope global
  - ✅ Exportar snapshot temporal a JSON

#### RF-RECOV-004: Detección de Anomalías en EventStore
- **Prioridad**: Media
- **Actor**: Sistema
- **Descripción**: Monitoreo automático de integridad de eventos
- **Validaciones continuas**:
  - Secuencia temporal correcta (timestamps incrementales)
  - Integridad referencial (aggregateIds válidos)
  - Schema de eventos válido (JSON schema validation)
  - No duplicación de eventos (eventId único)
- **Acciones ante anomalía**:
  - Log de error crítico
  - Notificación inmediata a admin por email/Slack
  - Bloqueo de escrituras si anomalía es crítica
  - Sugerencia de acción correctiva
- **Criterios de aceptación**:
  - ✅ Validación cada 6 horas (cron job)
  - ✅ Dashboard con estado de salud de EventStore
  - ✅ Historial de anomalías detectadas

#### RF-RECOV-005: Backup Redundante (Fuera de Event Sourcing)
- **Prioridad**: Media
- **Actor**: Sistema
- **Descripción**: Backup tradicional adicional como redundancia
- **Frecuencia**: Semanal, domingos 3:00 AM
- **Alcance**:
  - EventStore completo (exportado a JSON)
  - ReadModel completo
  - Firebase Storage (multimedia)
- **Destino**:
  - Google Cloud Storage bucket (multi-región)
  - Retención: 4 semanas
  - Encriptación: AES-256
- **Criterios de aceptación**:
  - ✅ Verificación de integridad post-backup
  - ✅ Pruebas de restauración trimestrales
  - ✅ Documentación de procedimiento de restauración

---

### MÓDULO 9: FUNCIONALIDADES MÓVILES ESPECÍFICAS

#### RF-MOBILE-001: Escaneo QR de Proyectos
- **Prioridad**: Alta
- **Actor**: Docente (app móvil)
- **Descripción**: Acceder rápidamente a un proyecto escaneando código QR
- **Proceso**:
  1. Sistema genera QR único por proyecto (URL: bifrost://proyecto/[id])
  2. Alumno muestra QR en stand de feria
  3. Docente abre app → Botón "Escanear QR"
  4. Cámara detecta QR → Abre proyecto directamente
  5. Docente puede evaluar inmediatamente
- **Criterios de aceptación**:
  - ✅ QR generado automáticamente al publicar proyecto
  - ✅ QR descargable como PNG desde web
  - ✅ Deep linking: QR abre app si está instalada, sino abre web
  - ✅ Funciona offline si proyecto ya está en caché

#### RF-MOBILE-002: Modo Offline Inteligente
- **Prioridad**: Alta
- **Actor**: Docente, Alumno (app móvil)
- **Descripción**: Funcionalidad limitada sin conexión a internet
- **Datos pre-cargados en caché**:
  - Últimos 10 proyectos visualizados
  - Mis proyectos (si soy alumno)
  - PDF de proyectos cacheados
  - Notificaciones recientes
- **Acciones permitidas offline**:
  - Ver proyectos en caché
  - Crear evaluación (guardada en queue local)
  - Leer notificaciones
  - Ver mi dashboard
- **Sincronización al recuperar conexión**:
  - Subir evaluaciones pendientes automáticamente
  - Actualizar datos modificados remotamente
  - Notificación de sincronización exitosa
- **Criterios de aceptación**:
  - ✅ Indicador visual de estado: Online / Offline / Sincronizando
  - ✅ Badge con número de acciones pendientes de sincronizar
  - ✅ No pérdida de datos incluso si app se cierra offline

#### RF-MOBILE-003: Dictado por Voz (Speech-to-Text)
- **Prioridad**: Media
- **Actor**: Docente (app móvil)
- **Descripción**: Dictar retroalimentación en lugar de escribir
- **Proceso**:
  1. En formulario de evaluación → Botón micrófono
  2. Presionar y hablar
  3. Sistema transcribe a texto en tiempo real
  4. Docente puede editar texto transcrito
  5. Guardar retroalimentación
- **Tecnología**:
  - iOS: SFSpeechRecognizer (nativo)
  - Android: SpeechRecognizer (nativo)
  - Idioma: Español (México)
- **Criterios de aceptación**:
  - ✅ Precisión ≥85% en español
  - ✅ Solicitar permisos de micrófono en primer uso
  - ✅ Feedback visual mientras graba (animación de ondas)
  - ✅ Límite de 2 minutos por dictado

#### RF-MOBILE-004: Notificaciones Push Nativas
- **Prioridad**: Alta
- **Actor**: Todos (app móvil)
- **Descripción**: Notificaciones push mediante Firebase Cloud Messaging
- **Configuración**:
  - Solicitar permiso en primera ejecución
  - Registro de token FCM en Firestore
  - Asociar token a userId
- **Tipos de notificaciones** (ver RF-NOTIF-001 a 005)
- **Interacciones**:
  - Tap en notificación → Abre pantalla relevante en app
  - Swipe para descartar
  - Badge con contador en ícono de app
- **Criterios de aceptación**:
  - ✅ Notificación llega incluso si app está cerrada
  - ✅ Sonido y vibración personalizados
  - ✅ Agrupación de notificaciones del mismo tipo

#### RF-MOBILE-005: Widgets de Home Screen (Nativo)
- **Prioridad**: Baja
- **Actor**: Alumno, Docente (app móvil)
- **Descripción**: Widgets en pantalla de inicio del dispositivo
- **Widgets para Alumno**:
  - "Mi Mejor Proyecto": Muestra proyecto con mejor score
    - Banner pequeño
    - Título
    - Score y posición en ranking
    - Tap → Abre proyecto
  - "Ranking Rápido": Top 3 proyectos
- **Widgets para Docente**:
  - "Pendientes de Evaluar": Contador + lista de proyectos
  - "Mi Actividad": Evaluaciones este mes + streak
- **Plataformas**:
  - iOS: WidgetKit (iOS 14+)
  - Android: App Widgets (Android 12+)
- **Criterios de aceptación**:
  - ✅ Actualización cada 15 minutos
  - ✅ Múltiples tamaños (small, medium, large)
  - ✅ Deep linking al tap

#### RF-MOBILE-006: Modo Oscuro Automático
- **Prioridad**: Baja
- **Actor**: Todos (app móvil)
- **Descripción**: Tema oscuro que se activa según configuración del sistema
- **Comportamiento**:
  - Detectar modo oscuro del sistema operativo
  - Aplicar paleta de colores oscura automáticamente
  - Opción manual: Claro / Oscuro / Automático
- **Criterios de aceptación**:
  - ✅ Transición suave sin parpadeos
  - ✅ Persistir preferencia del usuario
  - ✅ Imágenes con overlay oscuro para legibilidad

#### RF-MOBILE-007: Compartir desde App (Native Share)
- **Prioridad**: Media
- **Actor**: Todos (app móvil)
- **Descripción**: Usar el sistema nativo de compartir del dispositivo
- **Proceso**:
  1. Ver proyecto → Botón "Compartir"
  2. Abre sheet nativo de compartir
  3. Opciones: WhatsApp, Email, Copiar link, Más...
  4. Genera link con metadata (preview card)
- **Criterios de aceptación**:
  - ✅ iOS: UIActivityViewController
  - ✅ Android: Intent.ACTION_SEND
  - ✅ Incluir imagen de preview (banner del proyecto)

---

### MÓDULO 10: COLABORACIÓN Y COMUNICACIÓN

#### RF-COLAB-001: Comentarios en Evaluaciones
- **Prioridad**: Baja
- **Actor**: Alumno (squad)
- **Descripción**: Responder a la retroalimentación de un evaluador
- **Proceso**:
  1. Ver evaluación recibida
  2. Botón "Responder" debajo de retroalimentación
  3. Escribir respuesta (máx. 500 caracteres)
  4. Enviar → Evaluador recibe notificación
- **Restricciones**:
  - Solo 1 respuesta por evaluación
  - No editable después de 24 horas
  - Tono respetuoso (validación de lenguaje ofensivo)
- **Criterios de aceptación**:
  - ✅ Visible en historial de evaluaciones
  - ✅ Evaluador puede ver respuesta en su dashboard

#### RF-COLAB-002: Menciones en Comentarios
- **Prioridad**: Baja
- **Actor**: Alumno (squad)
- **Descripción**: Mencionar a miembros del squad en respuestas
- **Sintaxis**: @nombre (autocompletado)
- **Efecto**:
  - Usuario mencionado recibe notificación
  - Link a la evaluación donde fue mencionado
- **Criterios de aceptación**:
  - ✅ Autocompletado al escribir @
  - ✅ Solo miembros del mismo squad pueden ser mencionados
  - ✅ Máximo 3 menciones por comentario

#### RF-COLAB-003: Chat Interno del Squad
- **Prioridad**: Baja
- **Actor**: Alumno (miembros del squad)
- **Descripción**: Conversación privada del equipo dentro de Bifrost
- **Funcionalidades**:
  - Chat en tiempo real (Firestore realtime listeners)
  - Mensajes de texto (máx. 1000 caracteres)
  - Enviar imágenes/archivos (hasta 5 MB)
  - Notificaciones de nuevos mensajes
  - Historial completo
- **Criterios de aceptación**:
  - ✅ Marcador de "escribiendo..." en tiempo real
  - ✅ Badge con mensajes no leídos
  - ✅ Búsqueda en historial de chat
  - ✅ Retención de 90 días, después auto-elimina

#### RF-COLAB-004: Tablero Kanban (Tareas del Proyecto)
- **Prioridad**: Baja
- **Actor**: Alumno (miembros del squad)
- **Descripción**: Gestión básica de tareas estilo Trello
- **Columnas**:
  - Por Hacer
  - En Progreso
  - Hecho
- **Tarjetas de tareas**:
  - Título
  - Descripción
  - Asignado a (miembro del squad)
  - Fecha límite
  - Etiquetas (Frontend, Backend, Bug, Feature...)
- **Acciones**:
  - Crear tarea
  - Drag & drop entre columnas
  - Editar/eliminar tarea
  - Comentar en tarea
- **Criterios de aceptación**:
  - ✅ Actualización en tiempo real para todos los miembros
  - ✅ Notificación cuando te asignan tarea
  - ✅ Filtros por asignado / etiqueta

#### RF-COLAB-005: Votación de Características
- **Prioridad**: Baja
- **Actor**: Todos
- **Descripción**: Usuarios votan por nuevas funcionalidades deseadas
- **Proceso**:
  1. Usuario sugiere feature (formulario)
  2. Admin revisa y aprueba para votación
  3. Aparece en lista pública de features propuestas
  4. Usuarios pueden votar (upvote/downvote)
  5. Admin prioriza desarrollo según votos
- **Criterios de aceptación**:
  - ✅ 1 voto por usuario por feature
  - ✅ Ordenar por número de votos
  - ✅ Marcar features implementadas

---

## 📊 MATRIZ DE PRIORIZACIÓN DE REQUISITOS

| Prioridad | Módulos Críticos | Total RFs |
|-----------|------------------|-----------|
| **Alta** | Auth, Proyectos, Evaluación, Showcase, Admin, Recuperación | ~35 |
| **Media** | Notificaciones, Analytics, Móvil-Específico | ~25 |
| **Baja** | Colaboración, Features Nice-to-Have | ~15 |

**Total estimado**: ~75 Requisitos Funcionales

---

# 🛡️ REQUISITOS NO FUNCIONALES

## RNF-1: PERFORMANCE

### RNF-PERF-001: Tiempo de Respuesta API
- **Métrica**: P95 (95% de requests)
- **Objetivo**: ≤300ms para endpoints de lectura
- **Objetivo**: ≤500ms para endpoints de escritura
- **Medición**: Google Cloud Trace

### RNF-PERF-002: Tiempo de Carga de Página (Web)
- **Métrica**: Lighthouse Performance Score
- **Objetivo**: ≥90/100 en desktop, ≥70/100 en móvil
- **Técnicas**:
  - Code splitting (React.lazy)
  - Lazy loading de imágenes
  - Optimización de bundle (Vite tree-shaking)
  - CDN para assets estáticos

### RNF-PERF-003: Tiempo de Inicio de App Móvil
- **Métrica**: Cold start time
- **Objetivo**: ≤2 segundos en dispositivos mid-range
- **Técnicas**:
  - Splash screen nativa
  - Caché agresivo de recursos iniciales
  - Lazy loading de módulos pesados

### RNF-PERF-004: Latencia de Firestore
- **Métrica**: Tiempo de lectura de documento
- **Objetivo**: <100ms para queries simples
- **Técnicas**:
  - Índices compuestos optimizados
  - Caché client-side (5 minutos TTL)
  - Queries paginadas (max 20 docs por request)

### RNF-PERF-005: Tiempo de Rehidratación
- **Métrica**: Duración de replay de EventStore
- **Objetivo**: <60 segundos para 10,000 eventos
- **Técnicas**:
  - Snapshots cada 1,000 eventos
  - Procesamiento batch de eventos
  - Índice optimizado en EventStore (aggregateId + timestamp)

### RNF-PERF-006: Optimización de Multimedia
- **Objetivo**: Reducir carga de imágenes/videos
- **Técnicas**:
  - Compresión automática de imágenes >2 MB (WebP con 80% quality)
  - Responsive images (srcset con 3 tamaños)
  - Videos en streaming (HLS para videos >50 MB)
  - CDN con cache global (Cloudflare/Firebase CDN)

---

## RNF-2: ESCALABILIDAD

### RNF-SCAL-001: Usuarios Concurrentes
- **Objetivo**: Soportar 500 usuarios concurrentes sin degradación
- **Proyección**: Escalar a 2,000 usuarios en 2 años
- **Arquitectura**:
  - Cloud Run con auto-scaling (2-10 instancias)
  - Firestore escala automáticamente
  - Load balancing automático de GCP

### RNF-SCAL-002: Almacenamiento de Eventos
- **Proyección**: 100,000 eventos/año
- **Estrategia**:
  - Particionado de EventStore por año
  - Archivado de eventos >5 años a Cold Storage
  - Compresión de payloads con gzip

### RNF-SCAL-003: Storage de Multimedia
- **Proyección**: 50 GB/cuatrimestre (400 proyectos × 125 MB promedio)
- **Estrategia**:
  - Lifecycle policy: mover a Nearline Storage después de 1 año
  - Eliminar multimedia de proyectos >3 años (retener solo metadata)

### RNF-SCAL-004: Crecimiento de Base de Datos
- **Proyección**: 5,000 documentos/año en ProyectosVista
- **Optimización**:
  - Índices solo en campos frecuentemente consultados
  - Soft delete en lugar de hard delete (mantener integridad)
  - Archivado de proyectos históricos a colección separada

---

## RNF-3: DISPONIBILIDAD (UPTIME)

### RNF-AVAIL-001: SLA de Disponibilidad
- **Objetivo**: 99.5% uptime mensual
- **Downtime permitido**: ~3.6 horas/mes
- **Medición**: Google Cloud Monitoring

### RNF-AVAIL-002: Redundancia Multi-Región
- **Firebase Firestore**: Multi-region (nam5: us-central + us-east)
- **Cloud Run**: Despliegue en 2 regiones (primary + failover)
- **Firebase Storage**: Multi-region automático

### RNF-AVAIL-003: Tolerancia a Fallos
- **Estrategias**:
  - Circuit breaker en llamadas API (Polly library)
  - Retry automático con exponential backoff
  - Graceful degradation (mostrar caché si API falla)

### RNF-AVAIL-004: Monitoreo y Alertas
- **Herramientas**:
  - Google Cloud Monitoring (métricas de infra)
  - Sentry (error tracking en aplicación)
  - Uptime checks cada 1 minuto
- **Alertas**:
  - Email + Slack si uptime <99% en ventana de 1 hora
  - Error rate >1% en últimos 5 minutos
  - API P95 >500ms

---

## RNF-4: SEGURIDAD

### RNF-SEC-001: Autenticación
- **Método**: Firebase Auth con Google SSO
- **Tokens**: JWT con expiración de 1 hora
- **Refresh tokens**: 30 días, rotación automática

### RNF-SEC-002: Autorización
- **Modelo**: RBAC (Role-Based Access Control)
- **Roles**: Alumno, Docente, Admin, Invitado
- **Validación**:
  - Firestore Security Rules (perimetral)
  - Middleware en .NET API (negocio)
  - Claims en JWT token

### RNF-SEC-003: Validación de Correos Institucionales
- **Regex**: `/^([a-zA-Z.]+|\d{8})@utmetropolitana\.edu\.mx$/`
- **Verificación**: Email verification obligatoria
- **Whitelist**: Solo dominio institucional permitido

### RNF-SEC-004: Protección de Datos Sensibles
- **Datos a encriptar**:
  - Matrículas de alumnos (AES-256 con Google Cloud KMS)
  - Información personal identificable (PII)
- **Datos NO encriptados**:
  - Información pública del proyecto (título, descripción)
  - Scores y evaluaciones (necesarios para queries)

### RNF-SEC-005: Firestore Security Rules
- **Principio**: Deny by default, allow explícitamente
- **Reglas críticas**:
  - EventStore: Append-only (no update, no delete)
  - ProyectosVista: Read según estado, Write solo Event Handlers
  - Users: Read own profile, Write solo campos permitidos
- **Testing**: Emulator tests con casos de borde

### RNF-SEC-006: Protección contra Ataques
- **OWASP Top 10**:
  - ✅ Injection: Validación de inputs, parameterized queries
  - ✅ Broken Auth: Firebase Auth (battle-tested)
  - ✅ XSS: Sanitización de HTML (DOMPurify en React)
  - ✅ CSRF: SameSite cookies, CORS restrictivo
  - ✅ SSRF: Whitelist de dominios permitidos
- **Rate Limiting**:
  - 100 requests/minuto por IP (Cloud Armor)
  - 10 evaluaciones/hora por docente (evitar spam)

### RNF-SEC-007: Auditoría de Seguridad
- **Logs de acceso**:
  - Registro de login/logout
  - Cambios de permisos
  - Acceso a datos sensibles
- **Retención**: 90 días en Cloud Logging
- **Revisión**: Mensual por administrador

### RNF-SEC-008: Cumplimiento de Privacidad
- **Políticas**:
  - Política de Privacidad visible
  - Términos de Uso aceptados en registro
  - Derecho de eliminación de cuenta (GDPR-inspired)
- **Consentimiento**:
  - Uso de cookies (analytics)
  - Notificaciones push

---

## RNF-5: USABILIDAD

### RNF-USAB-001: Compatibilidad de Navegadores (Web)
- **Soportados**:
  - Chrome ≥90 (Desktop + Android)
  - Safari ≥14 (Desktop + iOS)
  - Firefox ≥88
  - Edge ≥90
- **No soportados**: Internet Explorer

### RNF-USAB-002: Compatibilidad Móvil (App)
- **iOS**: ≥14.0 (iPhone 6s en adelante)
- **Android**: ≥8.0 Oreo (API Level 26)
- **Tablet**: Optimizado para iPad y tablets Android

### RNF-USAB-003: Responsive Design
- **Breakpoints**:
  - Mobile: 320px - 767px
  - Tablet: 768px - 1023px
  - Desktop: ≥1024px
- **Frameworks**: Tailwind CSS (mobile-first)

### RNF-USAB-004: Accesibilidad (WCAG 2.1)
- **Nivel objetivo**: AA (mínimo)
- **Requisitos**:
  - Contraste de colores ≥4.5:1
  - Navegación completa con teclado
  - Alt text en todas las imágenes
  - ARIA labels en componentes interactivos
  - Formularios con labels asociados
- **Testing**: Lighthouse Accessibility Audit

### RNF-USAB-005: Internacionalización (i18n)
- **Idiomas**:
  - Español (México) - Default
  - Inglés (futuro)
- **Formato**:
  - Fechas: DD/MM/YYYY
  - Hora: 24 horas
  - Moneda: MXN (si aplica)

### RNF-USAB-006: Tiempos de Feedback
- **Interacciones**:
  - Click en botón → Feedback visual <100ms
  - Submit de formulario → Loading indicator inmediato
  - Operación larga → Progress bar actualizado cada 2s
- **Mensajes de error**:
  - Específicos (no genéricos)
  - Accionables (con pasos de solución)
  - Tono amigable (no técnico)

### RNF-USAB-007: Onboarding de Usuarios
- **Primera ejecución**:
  - Tour guiado opcional (5 pasos)
  - Tooltips contextuales
  - Proyecto de ejemplo pre-cargado
- **Ayuda contextual**:
  - Ícono "?" en formularios complejos
  - Link a documentación relevante

---

## RNF-6: MANTENIBILIDAD

### RNF-MAINT-001: Arquitectura de Código
- **Backend**:
  - Clean Architecture (Domain, Application, Infrastructure, API)
  - CQRS explícito (separación Command/Query)
  - Inyección de dependencias (.NET DI container)
- **Frontend Web**:
  - Feature-based folders (no por tipo de archivo)
  - Custom hooks reutilizables
  - Context API para estado global
- **Frontend Móvil**:
  - BLoC pattern (Business Logic Component)
  - Repository pattern para acceso a datos

### RNF-MAINT-002: Documentación de Código
- **Objetivo**: ≥80% de clases/funciones documentadas
- **Estándar**:
  - C#: XML comments (///)
  - JavaScript/Dart: JSDoc/DartDoc
- **Generación**: Documentación auto-generada con DocFX (.NET)

### RNF-MAINT-003: Cobertura de Tests
- **Objetivo**:
  - Backend: ≥70% cobertura de código
  - Frontend: ≥50% componentes críticos
- **Tipos de tests**:
  - Unitarios: xUnit (.NET), Jest (React), test package (Flutter)
  - Integración: Testcontainers (Firestore Emulator)
  - E2E: Playwright (web), Flutter integration tests (móvil)

### RNF-MAINT-004: Logging Estructurado
- **Biblioteca**: Serilog (.NET)
- **Niveles**: Trace, Debug, Information, Warning, Error, Critical
- **Enriquecimiento**:
  - CorrelationId (rastrear request completo)
  - UserId
  - AggregateId (en eventos)
- **Destino**: Google Cloud Logging (JSON)

### RNF-MAINT-005: Versionado Semántico
- **API**: v1, v2... (breaking changes)
- **App Móvil**: MAJOR.MINOR.PATCH (semver)
  - MAJOR: Breaking changes en datos/API
  - MINOR: Nuevas features (backward compatible)
  - PATCH: Bug fixes
- **Deprecation policy**:
  - Aviso con 3 meses de anticipación
  - Soporte de versión anterior durante 6 meses

### RNF-MAINT-006: Code Quality
- **Linters**:
  - .NET: StyleCop + Roslyn Analyzers
  - JavaScript: ESLint + Prettier
  - Dart: flutter analyze
- **CI enforcement**: Build falla si hay warnings

---

## RNF-7: PORTABILIDAD

### RNF-PORT-001: Independencia de Cloud Provider
- **Estrategia**: Abstracciones para servicios cloud
- **Capas de abstracción**:
  - `IEventStore` (abstracción sobre Firestore)
  - `IBlobStorage` (abstracción sobre Firebase Storage)
  - `IAuthProvider` (abstracción sobre Firebase Auth)
- **Objetivo**: Migrar a otro provider en <2 semanas si es necesario

### RNF-PORT-002: Formato de Datos Portable
- **EventStore**: JSON estandarizado (CloudEvents spec)
- **Exports**: JSON, CSV, PDF (formatos universales)
- **No vendor lock-in**: Evitar características propietarias críticas

### RNF-PORT-003: Containerización
- **Backend**: Docker container
- **Imagen base**: mcr.microsoft.com/dotnet/aspnet:9.0
- **Orquestación**: Compatible con Kubernetes (futuro)

---

## RNF-8: RECUPERABILIDAD (DISASTER RECOVERY)

### RNF-RECOV-001: RTO (Recovery Time Objective)
- **Objetivo**: <1 minuto para rehidratación automática
- **Objetivo**: <5 minutos para intervención manual

### RNF-RECOV-002: RPO (Recovery Point Objective)
- **Objetivo**: 0 pérdida de datos (Event Sourcing)
- **Respaldo**: Snapshots diarios (pérdida máx: 24h de performance, 0 de datos)

### RNF-RECOV-003: Estrategias de Backup
- **EventStore**: Inmutable (no necesita backup tradicional)
- **ReadModel**: Reconstruible desde EventStore (backup secundario)
- **Multimedia**: Backup semanal a GCS (retención 4 semanas)

### RNF-RECOV-004: Plan de Continuidad
- **Documentación**:
  - Runbook de procedimientos de recuperación
  - Roles y responsabilidades del equipo
  - Contactos de emergencia
- **Pruebas**:
  - Simulacro de disaster recovery trimestral
  - Validación de backups mensual

---

## RNF-9: COMPLIANCE Y LEGAL

### RNF-COMP-001: Protección de Datos de Menores
- **Restricción**: Alumnos son mayores de edad (universidad)
- **Validación**: Registro solo con correo institucional (implica edad legal)

### RNF-COMP-002: Propiedad Intelectual
- **Licencia de Proyectos**:
  - Alumnos retienen copyright de sus proyectos
  - UTM obtiene licencia no-exclusiva para showcase
  - Atribución siempre visible (nombre del squad)

### RNF-COMP-003: Términos de Uso
- **Contenido obligatorio**:
  - Uso educativo exclusivamente
  - Prohibición de contenido ofensivo/ilegal
  - Derecho de UTM a moderar contenido
  - Proceso de apelación ante suspensión

### RNF-COMP-004: Política de Privacidad
- **Divulgación**:
  - Qué datos se recopilan (correo, nombre, proyectos)
  - Cómo se usan (evaluación académica, showcase)
  - Con quién se comparten (público: proyectos publicados)
  - Derechos del usuario (acceso, eliminación)

### RNF-COMP-005: Retención de Datos
- **Usuarios activos**: Indefinido mientras usen el sistema
- **Usuarios inactivos**: Eliminación después de 3 años sin login
- **Proyectos históricos**: Retención permanente (archivo académico)
- **Logs de auditoría**: 5 años (cumplimiento académico)

---

## RNF-10: COSTOS OPERATIVOS

### RNF-COST-001: Optimización de Costos Cloud
- **Estrategias**:
  - Cloud Run scale-to-zero (zero costo en inactividad)
  - Firestore: Índices mínimos necesarios (evitar lecturas innecesarias)
  - Storage: Lifecycle policies (migrar a Nearline/Coldline)
  - CDN: Cache agresivo (reducir egress costs)

### RNF-COST-002: Proyección de Costos
- **Año 1** (500 usuarios, 400 proyectos):
  - Firebase (Auth, Firestore, Storage, Hosting): Tier gratuito + overages mínimos
  - Cloud Run: ~$20-50/mes (baja carga)
  - Total estimado: $30-80/mes
- **Año 3** (2000 usuarios, 1500 proyectos):
  - Total estimado: $150-300/mes

### RNF-COST-003: Monitoreo de Costos
- **Herramienta**: Google Cloud Billing (presupuesto + alertas)
- **Alertas**:
  - 50% de presupuesto mensual alcanzado
  - 90% de presupuesto mensual alcanzado
  - Spike inusual de costos (>200% del promedio)

---

## 📊 MATRIZ DE PRIORIZACIÓN RNF

| Categoría | Prioridad | RNFs Críticos |
|-----------|-----------|---------------|
| **Performance** | Alta | PERF-001, 002, 005 |
| **Seguridad** | Crítica | SEC-001 a 008 (todos) |
| **Disponibilidad** | Alta | AVAIL-001, 003 |
| **Escalabilidad** | Media | SCAL-001, 002 |
| **Usabilidad** | Alta | USAB-001, 003, 006 |
| **Mantenibilidad** | Media | MAINT-001, 003, 005 |
| **Recuperabilidad** | Crítica | RECOV-001, 002 |

---

## 🎯 RESUMEN CUANTITATIVO

### Requisitos Funcionales
- **Total**: ~75 RF
- **Alta prioridad**: 35 (47%)
- **Media prioridad**: 25 (33%)
- **Baja prioridad**: 15 (20%)

### Requisitos No Funcionales
- **Total**: 50 RNF
- **Categorías**: 10
- **Críticos para MVP**: 25 (50%)

---

## 📅 ROADMAP DE IMPLEMENTACIÓN

### MVP (Meses 1-4)
**RFs incluidos**:
- AUTH: 001-005
- PROJ: 001-006, 010
- EVAL: 001-004
- SHOW: 001-005
- NOTIF: 001, 003, 006
- ADMIN: 001-007
- RECOV: 001-002
- MOBILE: 001-004

**RNFs incluidos**:
- Todos los de Seguridad (SEC)
- Todos los de Recuperabilidad (RECOV)
- Performance críticos (PERF-001, 002, 005)
- Disponibilidad básica (AVAIL-001)

### Fase 2 (Meses 5-6)
- Analytics completo (ANALYT-001 a 006)
- Colaboración (COLAB-001 a 003)
- Mobile avanzado (MOBILE-005 a 007)
- Optimizaciones de performance (PERF-003, 004, 006)

### Fase 3 (Meses 7-9)
- Features nice-to-have (Baja prioridad)
- Internacionalización (RNF-USAB-005)
- Multi-carrera (expansión)
- Integraciones externas (LinkedIn, GitHub)

---

**Documento generado para**: Proyecto Bifrost Interface  
**Fecha**: Febrero 2026  
**Estado**: Draft para revisión  
**Próximos pasos**: Validación con stakeholders + priorización final
