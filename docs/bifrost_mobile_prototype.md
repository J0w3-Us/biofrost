# **UX Project Blueprint — Prototipo Móvil**

## **Nombre del Proyecto: BIFROST Interface — App Móvil (Flutter)**

**Plataforma**: iOS + Android (Flutter / Dart)  
**Arquitectura Backend**: .NET 9 + CQRS + Event Sourcing  
**Base de Datos**: MongoDB Atlas (Event Store + Read Models)  
**Autenticación**: Firebase Auth (Google SSO Institucional)  
**Fecha**: Febrero 2026  
**Equipo**: Product Owner — Uziel Isaac Pech Balam · Scrum Master — Jose Yael López Hu

---

### **1. EL PROBLEMA**
**¿Qué sabes del problema que quieres resolver y qué hay que hacer para resolverlo?**

*   **Problema Supuesto:**
    Los docentes evaluadores de proyectos integradores están **atados al escritorio** para calificar. En ferias, exposiciones y eventos presenciales, la retroalimentación se pierde porque no existe un canal móvil para evaluar en el momento. Los alumnos, por su parte, carecen de un medio inmediato para consultar el estado de sus proyectos y recibir notificaciones en tiempo real.

*   **Datos Duros (Evidencia cualitativa y cuantitativa):**
    *   **45+ proyectos integradores por cuatrimestre** se archivan sin reutilización en Teams/Drive.
    *   **Zero acceso móvil** a la evaluación: el 100% de las calificaciones se realizan desde escritorio.
    *   Un docente pierde **88 minutos por sesión de evaluación** al tener que anotar feedback en papel y regresar a oficina para capturarlo.
    *   Evaluación de 8 proyectos en feria: **120 min** (método tradicional) vs. **32 min** (Bifrost Móvil).
    *   **0% de trazabilidad** en los cambios de proyectos y evaluaciones (sin historial inmutable).
    *   **Cero notificaciones push** para informar al squad sobre nuevas evaluaciones o cambios en el ranking.

*   **Preguntas Sobresalientes:**
    *   ¿Cómo permitir que un docente evalúe un proyecto en ≤4 minutos directamente desde su celular?
    *   ¿Cómo garantizar que la evaluación funcione sin conexión a internet y se sincronice automáticamente al recuperar señal?
    *   ¿Cómo convertir la retroalimentación verbal en texto estructurado con speech-to-text nativo?
    *   ¿Cómo traducir los eventos inmutables del backend (Event Sourcing) en una UX fluida y en tiempo real para el usuario móvil?

---

### **2. ESCENARIO IDEAL**
**¿Cómo se ve el problema una vez resuelto?**

*   **Visión:**
    Una aplicación móvil nativa (Flutter) que funciona como **canal de evaluación rápida, consulta en tiempo real y notificaciones push** para el ecosistema Bifrost. El docente evalúa in-situ; el alumno monitorea su proyecto desde cualquier lugar.

*   **Cómo se miran estas actividades:**

    *   **El Docente (Evaluador Móvil):**
        1.  Abre la app → Escanea el QR del proyecto en el stand de la feria.
        2.  Ve el resumen del proyecto (PDF embebido, video pitch, squad).
        3.  Califica 5 criterios con **sliders touch nativos** en ~2 minutos.
        4.  Dicta la retroalimentación por voz (**speech-to-text**) o escribe manualmente.
        5.  Envía la evaluación en **≤4 minutos**; el squad recibe una **notificación push** inmediata.
        6.  Si no hay internet, la evaluación se guarda en la **cola offline** y se sincroniza automáticamente al recuperar WiFi.

    *   **El Alumno (Consulta & Monitoreo):**
        1.  Recibe una **push notification**: _"Tu proyecto 'Sistema de Inventario' fue evaluado por Lic. Roberto M. — Score: 90/100"_.
        2.  Abre la app → Dashboard con sus proyectos, score promedio, posición en ranking y evaluaciones recibidas.
        3.  Navega al detalle del proyecto para ver retroalimentación completa, gráficas de evolución y comentarios.
        4.  Comparte su proyecto en LinkedIn/WhatsApp directamente desde la app.

    *   **El Administrador (Supervisión Remota):**
        1.  Consulta estadísticas generales desde el dashboard administrativo móvil.
        2.  Recibe alertas críticas en push (ej: anomalías en EventStore, evaluaciones sospechosas).

---

### **3. ACTORES DEL SISTEMA MÓVIL**

| Actor | Rol en la App Móvil | Identificación |
|-------|---------------------|----------------|
| **Alumno** | Consulta proyectos, recibe notificaciones, ve evaluaciones, comparte perfil | Correo 8 dígitos: `12345678@utmetropolitana.edu.mx` |
| **Docente** | Evalúa proyectos, escanea QR, dicta feedback por voz, gestiona su dashboard | Correo letras: `roberto.martinez@utmetropolitana.edu.mx` |
| **Administrador** | Supervisión de métricas, alertas críticas | Rol asignado manualmente |
| **Invitado Evaluador** | Evalúa proyectos asignados en ferias con cuenta temporal | Correo verificado + rol temporal (expira en 7 días) |

---

### **4. REQUERIMIENTOS FUNCIONALES MÓVILES**

#### **Módulo 1: Autenticación y Perfil**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-AUTH-001** | Login con Google SSO | Alta | Autenticación mediante Google Sign-In con cuentas `@utmetropolitana.edu.mx`. Botón "Continuar con Google", validación de dominio post-SSO, persistent login en dispositivo. |
| **RF-M-AUTH-002** | Detección automática de rol | Alta | Al autenticarse, el sistema detecta el rol según el formato del correo: 8 dígitos → Alumno, letras/puntos → Docente. Sin configuración manual. |
| **RF-M-AUTH-003** | Perfil de Alumno | Media | Visualizar y editar: matrícula (auto-completada), nombre, grupo (catálogo: 4A, 4B, 5A…), avatar, bio (máx. 200 chars), enlaces sociales (GitHub, LinkedIn, Portfolio), especialización. |
| **RF-M-AUTH-004** | Perfil de Docente | Media | Visualizar y editar: nombre, departamento, título académico (Lic./Mtro./Dr.), avatar, áreas de especialización, disponibilidad para asesorías. |
| **RF-M-AUTH-005** | Cierre de sesión | Baja | Cerrar sesión en el dispositivo actual. Opción "Cerrar sesión en todos los dispositivos" (invalida todos los tokens JWT). |

#### **Módulo 2: Dashboard Principal**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-DASH-001** | Dashboard de Alumno | Alta | Pantalla principal con: tarjetas de "Mis Proyectos" (score, posición en ranking, evaluaciones recibidas), evolución de scores (gráfica de línea), notificaciones recientes, posición en leaderboard. Actualización en tiempo real. |
| **RF-M-DASH-002** | Dashboard de Docente | Alta | Pantalla principal con: proyectos evaluados (total y cuatrimestre), tiempo promedio de evaluación, distribución de scores dados (histograma), proyectos pendientes de evaluar, acceso rápido a "Evaluar" y "Escanear QR". |
| **RF-M-DASH-003** | Dashboard Administrativo | Media | Resumen institucional: usuarios activos, proyectos por estado, score promedio general, alertas del sistema, eventos recientes del EventStore. |

#### **Módulo 3: Evaluación Móvil (Core Feature)**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-EVAL-001** | Escaneo QR de Proyecto | Alta | Botón "Escanear QR" que activa la cámara. Al detectar el código (URL `bifrost://proyecto/[id]`), abre directamente el proyecto. QR generado automáticamente al publicar proyecto. Deep linking si la app está instalada. |
| **RF-M-EVAL-002** | Vista Resumida del Proyecto | Alta | Al abrir un proyecto desde QR o lista: muestra banner, título, grupo, descripción corta, stack tecnológico (badges), squad (avatares), botones para "Ver PDF", "Ver Video" y "Evaluar". |
| **RF-M-EVAL-003** | Formulario de Evaluación Touch | Alta | Evaluación con **5 criterios** vía sliders touch nativos (0-20 pts cada uno): Innovación y Creatividad (20%), Complejidad Técnica (30%), Calidad de Documentación (15%), Presentación y UX (15%), Funcionalidad Completa (20%). Campo de retroalimentación obligatorio (mín. 100 caracteres) separado en: Fortalezas, Áreas de Mejora, Sugerencias. |
| **RF-M-EVAL-004** | Dictado por Voz (Speech-to-Text) | Media | Botón de micrófono en el campo de retroalimentación. Presionar → Hablar → Transcripción en tiempo real (SFSpeechRecognizer en iOS, SpeechRecognizer en Android). Idioma: Español (MX). Precisión ≥85%. Feedback visual con animación de ondas mientras graba. Límite: 2 min por dictado. |
| **RF-M-EVAL-005** | Templates de Retroalimentación | Media | Dropdown de sugerencias predefinidas categorizadas (Fortalezas / Áreas de Mejora / Sugerencias). Editable después de seleccionar. Docente puede guardar sus propios templates. |
| **RF-M-EVAL-006** | Envío y Confirmación | Alta | Al enviar, genera evento inmutable `EvaluacionCompletada` con: scoreTotal, breakdown por criterio, tiempoTotalMinutos, contexto (modalidad: "Móvil", dispositivo, ubicación opcional). Notificación push automática al squad del proyecto. |
| **RF-M-EVAL-007** | Modo Offline Inteligente | Alta | Si no hay conexión: la evaluación se guarda en **cola local** (SQLite/Hive). Indicador visual: 🟢 Online / 🟡 Sincronizando / 🔴 Offline. Badge con número de acciones pendientes. Sincronización automática al recuperar WiFi. Sin pérdida de datos aunque la app se cierre offline. |
| **RF-M-EVAL-008** | Restricciones de Evaluación | Alta | Un docente NO puede evaluar el mismo proyecto más de una vez. Solo proyectos en estado "Activo" o "Público" pueden ser evaluados. Evaluación editable solo dentro de las primeras 24 horas (genera evento `EvaluacionEditada`). |

#### **Módulo 4: Consulta de Proyectos y Showcase**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-SHOW-001** | Galería de Proyectos | Alta | Feed scrollable con tarjetas: banner (lazy loading), título, descripción corta, stack (badges), score (estrellas + número), grupo, cuatrimestre, vistas. Filtros: estado, grupo, tecnología, score mínimo. Solo proyectos "Público" e "Histórico". Paginación (20 por carga). |
| **RF-M-SHOW-002** | Detalle de Proyecto | Alta | Pantalla completa: Hero Section (banner + título + score + acciones), Overview (descripción, problemática), Stack Tecnológico (badges con logos), Squad (fotos, roles), Multimedia (galería de screenshots, video embebido), PDF (visor embebido), Evaluaciones (promedios por criterio en radar chart, sin nombres de evaluadores). |
| **RF-M-SHOW-003** | Leaderboard / Ranking | Alta | Tabla de posiciones: posición (#1, #2…), cambio de posición (↗️, ↘️, →), proyecto (nombre + banner mini), líder, score, evaluaciones. Vistas: General, Por Grupo, Por Cuatrimestre, Histórico. Actualización en tiempo real via snapshots de Firestore. Top 3 con indicadores visuales especiales (🥇🥈🥉). |
| **RF-M-SHOW-004** | Búsqueda Avanzada | Media | Buscador con searchbar + filtros: texto libre (título, descripción, tecnologías), stack tecnológico (selección múltiple), grupo, cuatrimestre, score mínimo, estado. Orden por: relevancia, score, fecha, visualizaciones. |
| **RF-M-SHOW-005** | Compartir Proyecto (Native Share) | Media | Botón "Compartir" que invoca el sheet nativo del dispositivo (UIActivityViewController iOS / Intent.ACTION_SEND Android). Opciones: WhatsApp, LinkedIn, Email, Copiar link. Incluye imagen preview (banner). Genera link con metadata Open Graph. |

#### **Módulo 5: Notificaciones Push**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-NOTIF-001** | Nueva Evaluación Recibida | Alta | Push: _"Tu proyecto '[Nombre]' fue evaluado por [Docente]. Score: XX/100"_. Todos los miembros del squad la reciben. Agrupación: si llegan 3+ en 1 hora, se envía resumen. Respeto de horario nocturno (10 PM - 7 AM). |
| **RF-M-NOTIF-002** | Cambio en Ranking | Media | Push: _"¡Tu proyecto subió al #5! (+7 posiciones) 🚀"_. Se activa con cambio ≥3 posiciones, entrada al Top 10 o Top 3. Máximo 1 notificación de ranking por día. Desactivable. |
| **RF-M-NOTIF-003** | Invitación a Proyecto | Alta | Push: _"[Nombre] te invitó a unirte a '[Proyecto]'"_. Botones: Aceptar / Rechazar. Persiste hasta que el usuario tome acción. Recordatorio automático a las 48 horas. |
| **RF-M-NOTIF-004** | Cambios en Proyecto (Squad) | Baja | Push para: nuevo miembro, miembro removido, cambio de estado, documentación actualizada. Batch: agrupa cambios en 1 hora. El autor del cambio NO recibe notificación. |
| **RF-M-NOTIF-005** | Centro de Notificaciones | Media | Panel con lista ordenada por fecha. Filtros: No leídas / Todas / Por tipo. Marcar como leído/no leído. Badge con contador en campana. Máximo 50 guardadas. Auto-limpieza >30 días. Actualización en tiempo real. |
| **RF-M-NOTIF-006** | Preferencias de Notificaciones | Media | Toggles por tipo de notificación (evaluaciones, ranking, invitaciones, cambios). Opción "Silenciar todo" temporal (1 día / 3 días / 1 semana). Horario nocturno configurable. |

#### **Módulo 6: Funcionalidades Nativas Específicas**

| ID | Requisito | Prioridad | Descripción |
|----|-----------|-----------|-------------|
| **RF-M-NATIVE-001** | Modo Oscuro Automático | Baja | Detecta configuración del sistema operativo. Aplica paleta oscura automáticamente. Opciones: Claro / Oscuro / Automático. Transición suave sin parpadeos. |
| **RF-M-NATIVE-002** | Widgets de Home Screen | Baja | **Alumno**: "Mi Mejor Proyecto" (banner mini + título + score + ranking). "Ranking Rápido" (Top 3). **Docente**: "Pendientes de Evaluar" (contador + lista). "Mi Actividad" (evaluaciones este mes). iOS WidgetKit (14+), Android App Widgets (12+). Actualización cada 15 min. |
| **RF-M-NATIVE-003** | Visor PDF Embebido | Alta | Visualizar PDFs de documentación directamente en la app sin descargar externamente. Caché local para acceso offline. Zoom, scroll, búsqueda en contenido. |
| **RF-M-NATIVE-004** | Reproductor de Video | Alta | Reproducción de video pitch embebido. Soporta: MP4 directo, YouTube, Vimeo. Controles nativos (play, pause, seek, fullscreen). Tracking de % reproducido. |
| **RF-M-NATIVE-005** | Caché Local Inteligente | Alta | Pre-carga automática de últimos 10 proyectos visualizados. PDFs de proyectos cacheados. Notificaciones recientes. Dashboard propio. Indicador de espacio utilizado en configuración. |

---

### **5. MODELOS DE DATOS RELEVANTES PARA MÓVIL**

Los modelos siguen la arquitectura **CQRS + Event Sourcing** con **MongoDB Atlas**. El móvil consume los **Read Models** (optimizados para lectura rápida) y genera **Commands** que producen eventos inmutables en el Event Store.

#### **5.1 Event Store — Eventos Generados desde Móvil**

##### **EvaluacionIniciada** (Desde app móvil)
```javascript
{
  aggregateId: "EVAL-001",
  aggregateType: "Evaluacion",
  eventType: "EvaluacionIniciada",
  version: 1,
  timestamp: ISODate("2026-02-10T10:00:00.000Z"),
  payload: {
    proyectoId: "PROJ-001",
    proyectoTitulo: "Sistema de Ventas para PYMES",
    evaluadorId: "DOC-002",
    evaluadorNombre: "Mtra. Ana López",
    evaluadorTipo: "Docente",       // "Docente", "Empresa", "Jurado"
    modalidad: "Móvil",             // Identifica canal
    dispositivo: "iPhone 13 Pro",
    ubicacion: {                     // Geolocalización (opcional)
      lat: 20.967278,
      lng: -89.624137,
      nombre: "Feria de Proyectos UTM"
    }
  },
  metadata: {
    userId: "ana.lopez@utmetropolitana.edu.mx",
    userName: "Mtra. Ana López",
    userRole: "Docente",
    commandId: "cmd_67ab1234567890",
    correlationId: "corr_request_123",
    source: "mobile-ios",            // "mobile-ios", "mobile-android"
    ipAddress: "192.168.1.100",
    userAgent: "BifrostApp/1.0 (iOS 17.2)"
  }
}
```

##### **CriterioCalificado** (Por cada criterio evaluado)
```javascript
{
  aggregateId: "EVAL-001",
  aggregateType: "Evaluacion",
  eventType: "CriterioCalificado",
  version: 2,
  payload: {
    criterio: "innovacion",  // "innovacion", "calidadTecnica", "documentacion", "presentacion", "impacto"
    score: 18,               // 0-20 puntos
    comentario: "Excelente uso de IA predictiva, solución novedosa",
    tiempoEvaluacionSegundos: 120
  },
  metadata: { source: "mobile-ios", /* ... */ }
}
```

##### **RetroalimentacionRegistrada**
```javascript
{
  aggregateId: "EVAL-001",
  aggregateType: "Evaluacion",
  eventType: "RetroalimentacionRegistrada",
  version: 7,
  payload: {
    retroalimentacionGeneral: "Proyecto muy completo con alta calidad técnica...",
    aspectosPositivos: [
      "Arquitectura escalable y bien documentada",
      "UI/UX intuitiva y profesional"
    ],
    areasMejora: [
      "Incrementar cobertura de tests (45%)",
      "Manejo de errores más robusto"
    ],
    recomendaciones: [
      "Despliegue en GCP para demo público",
      "Preparar caso de estudio para feria"
    ]
  },
  metadata: { source: "mobile-ios", /* ... */ }
}
```

##### **EvaluacionCompletada**
```javascript
{
  aggregateId: "EVAL-001",
  aggregateType: "Evaluacion",
  eventType: "EvaluacionCompletada",
  version: 8,
  payload: {
    scoreTotal: 87,
    scoresPorCriterio: {
      innovacion: 18,
      calidadTecnica: 17,
      documentacion: 16,
      presentacion: 19,
      impacto: 17
    },
    tiempoTotalMinutos: 3.75,
    iniciadaEn: ISODate("2026-02-10T10:00:00Z"),
    completadaEn: ISODate("2026-02-10T10:03:45Z")
  },
  metadata: { source: "mobile-ios", /* ... */ }
}
```

#### **5.2 Read Models — Datos Consumidos por el Móvil**

##### **`proyectos_view`** (Lectura principal)
```javascript
{
  _id: "PROJ-001",

  // Información Básica
  titulo: "Sistema de Ventas para PYMES",
  descripcionCorta: "Plataforma de ventas online con IA predictiva",
  descripcionDetallada: "## Problemática\n\nLas PYMES...",  // Markdown

  // Stack Tecnológico
  stackTecnologico: [
    { nombre: "React", categoria: "Frontend", logo: "https://..." },
    { nombre: "Node.js", categoria: "Backend", logo: "https://..." },
    { nombre: "MongoDB", categoria: "Database", logo: "https://..." }
  ],
  tags: ["IA", "PYMES", "Ventas", "Predictivo"],

  // Multimedia (URLs para el móvil)
  multimedia: {
    banner: {
      publicUrl: "https://storage.googleapis.com/.../banner.jpg",
      thumbnailUrl: "https://storage.googleapis.com/.../banner_thumb.jpg"
    },
    screenshots: [
      { publicUrl: "...", thumbnailUrl: "...", caption: "Dashboard principal", orden: 1 }
    ],
    videoPitch: {
      tipo: "upload",
      publicUrl: "https://storage.googleapis.com/.../pitch.mp4",
      streamingUrl: "https://storage.googleapis.com/.../pitch.m3u8",  // HLS
      posterUrl: "https://storage.googleapis.com/.../pitch_poster.jpg",
      metadata: { duracionSegundos: 285, resolucion: "1080p" }
    },
    documentacionPDF: {
      publicUrl: "https://storage.googleapis.com/.../documentacion.pdf",
      metadata: { paginas: 45, sizeMB: 8.3 }
    }
  },

  // Squad
  lider: {
    id: "USR-12345678",
    nombre: "Juan Pérez López",
    avatarUrl: "https://storage.googleapis.com/.../avatar.jpg",
    grupo: "5A"
  },
  miembros: [
    {
      id: "USR-87654321",
      nombre: "María García Rodríguez",
      avatarUrl: "...",
      roles: ["Frontend Developer", "UI/UX Designer"]
    }
  ],

  // Académico
  academico: {
    docenteAsesor: { id: "DOC-001", nombre: "Dr. Roberto Martínez" },
    grupo: "5A",
    cuatrimestre: "2026-1",
    carrera: "DSM"
  },

  // Estado
  estado: "Público",  // "Borrador", "Activo", "Público", "Histórico", "Pausado"

  // Métricas (para Dashboard y Leaderboard)
  metrics: {
    totalEvaluaciones: 8,
    scorePromedio: 87.5,
    scoreDistribucion: {
      innovacion: 18.5,
      calidadTecnica: 17.2,
      documentacion: 16.8,
      presentacion: 19.0,
      impacto: 16.0
    },
    vistas: 1247,
    likes: 89,
    comentarios: 23
  },

  // Búsqueda
  busqueda: {
    popularidad: 87.5,
    ultimaActividad: ISODate("2026-02-15T18:20:00Z")
  }
}
```

##### **`evaluaciones_view`** (Evaluaciones recibidas por proyecto)
```javascript
{
  _id: "EVAL-001",
  proyectoId: "PROJ-001",
  proyectoTitulo: "Sistema de Ventas para PYMES",

  evaluador: {
    id: "DOC-002",
    nombre: "Mtra. Ana López",
    avatarUrl: "...",
    tipo: "Docente"
  },

  criterios: {
    innovacion:      { score: 18, comentario: "..." },
    calidadTecnica:  { score: 17, comentario: "..." },
    documentacion:   { score: 16, comentario: "..." },
    presentacion:    { score: 19, comentario: "..." },
    impacto:         { score: 17, comentario: "..." }
  },

  retroalimentacion: {
    general: "Proyecto muy completo...",
    aspectosPositivos: ["...", "..."],
    areasMejora: ["...", "..."],
    recomendaciones: ["...", "..."]
  },

  scoreTotal: 87,
  tiempoTotalMinutos: 3.75,
  contexto: {
    modalidad: "Móvil",
    dispositivo: "iPhone 13 Pro",
    ubicacion: { lat: 20.967278, lng: -89.624137, nombre: "Feria UTM" }
  },

  creadoEn: ISODate("2026-02-10T10:00:00Z"),
  completadoEn: ISODate("2026-02-10T10:03:45Z")
}
```

##### **`usuarios_view`** (Perfil del usuario en app)
```javascript
{
  _id: "USR-12345678",
  firebaseUid: "firebase_uid_abc123xyz",
  email: "12345678@utmetropolitana.edu.mx",
  nombre: "Juan Pérez López",
  avatarUrl: "https://storage.googleapis.com/.../avatar.jpg",
  rol: "Alumno",

  perfil: {
    tipo: "Alumno",
    matricula: "12345678",
    grupo: "5A",
    cuatrimestre: 10,
    carrera: "DSM",
    bio: "Desarrollador Full Stack apasionado por IA y UX",
    social: {
      github: "https://github.com/juanperez",
      linkedin: "https://linkedin.com/in/juanperez",
      portfolio: "https://juanperez.dev"
    },
    skills: {
      lenguajes: ["JavaScript", "Python", "Dart"],
      frameworks: ["React", "Flutter", "TensorFlow"]
    }
  },

  stats: {
    proyectosCreados: 3,
    proyectosParticipados: 5,
    evaluacionesRecibidas: 24,
    scorePromedioProyectos: 85.3,
    ultimoLogin: ISODate("2026-02-10T16:00:00Z")
  },

  proyectos: {
    lider: ["PROJ-001", "PROJ-007"],
    participante: ["PROJ-012", "PROJ-034"]
  },

  preferencias: {
    idioma: "es-MX",
    tema: "dark",
    notificaciones: {
      push: {
        enabled: true,
        fcmToken: "fcm_token_abc123...",
        tipos: {
          nuevaEvaluacion: true,
          invitacionSquad: true,
          cambioRanking: true,
          mensajesDirectos: true
        }
      }
    }
  }
}
```

##### **`notificaciones_view`** (Cola de notificaciones para el móvil)
```javascript
{
  _id: "NOTIF-001",
  usuarioId: "USR-12345678",
  tipo: "nueva_evaluacion",    // "nueva_evaluacion", "cambio_ranking", "invitacion", "cambio_proyecto"
  titulo: "Nueva evaluación recibida",
  cuerpo: "Tu proyecto 'Sistema de Inventario' fue evaluado por Lic. Roberto M.",
  data: {
    proyectoId: "PROJ-001",
    evaluacionId: "EVAL-001",
    score: 90
  },
  leida: false,
  entregada: true,
  timestamp: ISODate("2026-02-10T10:09:00Z"),
  expiraEn: ISODate("2026-03-12T10:09:00Z")  // Auto-limpieza a 30 días
}
```

---

### **6. HIPÓTESIS**
**¿Qué indicadores dirían que hemos resuelto el problema?**

*   **Creencia:**
    Creemos que al ofrecer **un canal móvil especializado para evaluación**, con **sliders touch, dictado por voz y modo offline**, los docentes evaluarán más rápido, con mayor frecuencia y con retroalimentación más rica. Al recibir **notificaciones push en tiempo real**, los alumnos estarán más comprometidos con la calidad de sus proyectos.

*   **Indicadores de Éxito:**
    *   **Reducción del 73%** en tiempo de evaluación por proyecto (de 15 min a ≤4 min).
    *   **100% de acceso móvil** a evaluación (capacidad nueva, antes 0%).
    *   **Modo offline funcional** en el 100% de los intentos (zero pérdida de datos).
    *   **>40% de open rate** en notificaciones push.
    *   **Ratio de uso 60% móvil / 40% web** durante ferias y eventos.
    *   **>95% tasa de registro** entre la población estudiantil DSM.
    *   **Promedio >5 evaluaciones por proyecto** gracias a la facilidad móvil.

---

### **7. OBJETIVOS**
**¿Qué queremos lograr con la app móvil?**

*   **Logros Esperados:**
    *   **Movilidad total para docentes**: evaluar desde cualquier lugar, en cualquier momento.
    *   **Feedback inmediato**: retroalimentación en caliente, no días después.
    *   **Engagement estudiantil**: monitoreo constante del progreso via notificaciones y dashboard.
    *   **Resiliencia offline**: zero pérdida de datos incluso sin conexión.
    *   **Sincronización cross-platform**: evaluación en móvil refleja instantáneamente en web (leaderboard, dashboards).

*   **Métricas Objetivo — Año 1:**

    | KPI | Objetivo | Método de Medición |
    |-----|----------|--------------------|
    | Tiempo promedio de evaluación (móvil) | ≤4 minutos | Analytics timing events |
    | Evaluaciones realizadas desde móvil | >60% del total | Metadata `source: "mobile-*"` en cada evento |
    | Tasa de sincronización offline exitosa | 100% | Logs de cola offline |
    | Open rate de notificaciones push | >40% | Firebase Cloud Messaging analytics |
    | DAU (Daily Active Users) en app | >200 durante cuatrimestre | Firebase Analytics |
    | Cold start time | ≤2 segundos | Performance profiling Flutter |
    | Crash-free sessions | >99.5% | Firebase Crashlytics |

---

### **8. VALOR**
**¿Cuál es el beneficio que la app móvil aporta?**

*   **Para el Docente:**
    *   **Libertad operativa**: Evalúa in-situ en la feria, en la cafetería, en transporte — sin depender de un escritorio.
    *   **Ahorro radical**: 8 proyectos × 4 min = **32 min** (vs. 120 min en método tradicional). **88 minutos ahorrados por sesión**.
    *   **Dictado por voz**: Retroalimentación verbal transcrita automáticamente, eliminando la necesidad de escribir en pantalla pequeña.
    *   **Trazabilidad total**: Cada evaluación es un evento inmutable con timestamp, ubicación y dispositivo.

*   **Para el Alumno:**
    *   **Feedback inmediato**: Notificación push segundos después de ser evaluado. Sin esperar días.
    *   **Monitoreo en cualquier lugar**: Dashboard con scores, ranking y evaluaciones accesible desde el bolsillo.
    *   **Portafolio compartible**: Comparte su proyecto verificado institucionalmente en LinkedIn/WhatsApp con un tap.

*   **Para la Institución (UTM):**
    *   **Mayor cobertura de evaluación**: El canal móvil incrementa significativamente la frecuencia y cantidad de evaluaciones.
    *   **Datos enriquecidos**: Cada evaluación móvil incluye metadata de contexto (ubicación, dispositivo, tiempo) para analytics.
    *   **Imagen de innovación**: App nativa posiciona a la UTM como institución tecnológicamente avanzada.

---

### **9. REQUISITOS NO FUNCIONALES MÓVILES**

| Categoría | Requisito | Objetivo |
|-----------|-----------|----------|
| **Performance** | Cold start time | ≤2 segundos en dispositivos mid-range |
| **Performance** | API Response Time (P95) | ≤300ms lectura, ≤500ms escritura |
| **Performance** | Firestore read latency | <100ms para queries simples |
| **Compatibilidad** | iOS | ≥14.0 (iPhone 6s en adelante) |
| **Compatibilidad** | Android | ≥8.0 Oreo (API Level 26) |
| **Compatibilidad** | Tablet | Optimizado para iPad y tablets Android |
| **Seguridad** | Autenticación | Firebase Auth, JWT con expiración 1h, refresh 30 días |
| **Seguridad** | Datos sensibles | Matrículas encriptadas AES-256 (Google Cloud KMS) |
| **Seguridad** | Correos institucionales | Regex: `/^([a-zA-Z.]+|\d{8})@utmetropolitana\.edu\.mx$/` |
| **Disponibilidad** | Uptime | >99.5% mensual |
| **Disponibilidad** | Modo offline | Cola local con sincronización automática, zero pérdida |
| **Usabilidad** | Accesibilidad | WCAG 2.1 nivel AA (contraste ≥4.5:1, ARIA labels) |
| **Usabilidad** | Internacionalización | Español (MX) default, fechas DD/MM/YYYY, hora 24h |
| **Usabilidad** | Modo oscuro | Light / Dark / Auto (detectar SO) |
| **Arquitectura** | Patrón | BLoC (Business Logic Component) + Repository Pattern |
| **Calidad** | Cobertura de tests | ≥50% componentes críticos (Flutter test + integration tests) |
| **Calidad** | Linting | `flutter analyze` sin warnings |
| **Recuperabilidad** | RTO | <1 min (rehidratación automática desde EventStore) |
| **Recuperabilidad** | RPO | 0 pérdida de datos (Event Sourcing) |

---

### **10. FLUJO PRINCIPAL DE EVALUACIÓN MÓVIL**

```
┌──────────────────────────┐
│  1. Login con Google SSO │
│     @utmetropolitana     │
│     Detección de rol     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  2. Dashboard Docente    │
│  ┌────────────────────┐  │
│  │ Pendientes: 5      │  │
│  │ Evaluados: 12      │  │
│  │ Tiempo prom: 3.5m  │  │
│  │ [Escanear QR] 📷   │  │
│  └────────────────────┘  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  3. Escaneo QR           │
│     [Cámara activa]      │
│     Proyecto detectado   │
│     → Deep link          │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  4. Vista Resumida       │
│  ┌────────────────────┐  │
│  │ 🖼️ Banner          │  │
│  │ Sistema Inventario │  │
│  │ Grupo 5B · DSM     │  │
│  │ React · Node · Mongo│ │
│  │ [Ver PDF] [Video]  │  │
│  │ [⭐ Evaluar]       │  │
│  └────────────────────┘  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  5. Calificación Touch   │
│                          │
│  Innovación (20%)        │
│  ◯────────●──────◯       │
│  0       18      20      │
│                          │
│  Complejidad Téc. (30%)  │
│  ◯──────────●────◯       │
│  0        17     20      │
│                          │
│  Documentación (15%)     │
│  ◯────────●──────◯       │
│  0       16      20      │
│                          │
│  Presentación (15%)      │
│  ◯──────────●────◯       │
│  0        19     20      │
│                          │
│  Funcionalidad (20%)     │
│  ◯──────────●────◯       │
│  0        17     20      │
│                          │
│  Score: 87/100           │
│  [Siguiente →]           │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  6. Retroalimentación    │
│                          │
│  🎤 [Dictar por voz]    │
│  ⌨️ [Escribir]          │
│                          │
│  📗 Fortalezas:          │
│  "Excelente uso de..."   │
│  [+ Template ▼]          │
│                          │
│  📙 Áreas de Mejora:     │
│  "Falta manejo de..."    │
│  [+ Template ▼]          │
│                          │
│  📘 Sugerencias:          │
│  "Considerar GCP..."     │
│  [+ Template ▼]          │
│                          │
│  [📤 Enviar Evaluación]  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│  7. Confirmación         │
│                          │
│  ✅ Evaluación enviada    │
│  Score: 87/100           │
│  Tiempo: 3 min 45 seg   │
│                          │
│  📱 Notificación push    │
│  enviada al squad        │
│                          │
│  [Evaluar otro] [Inicio] │
└──────────────────────────┘
```

---

### **11. NAVEGACIÓN DE LA APP**

```
Bottom Navigation Bar (3-4 tabs según rol):

┌─────────────────────────────────────────┐
│                                         │
│            [Contenido Activo]           │
│                                         │
├─────────┬──────────┬──────────┬────────┤
│  🏠     │  🔍     │  📷/⭐  │  👤    │
│ Inicio  │ Explorar │ Evaluar* │ Perfil │
└─────────┴──────────┴──────────┴────────┘

* Tab "Evaluar" visible solo para Docentes
  → Incluye acceso directo a Escanear QR

Flujo de navegación:
├─ Inicio
│   ├─ Dashboard (según rol)
│   ├─ Notificaciones (campana 🔔)
│   └─ Mis Proyectos (alumno) / Pendientes (docente)
│
├─ Explorar
│   ├─ Galería / Showcase
│   ├─ Leaderboard
│   ├─ Búsqueda avanzada
│   └─ Filtros
│
├─ Evaluar (Docentes)
│   ├─ Escanear QR
│   ├─ Lista de proyectos evaluables
│   └─ Historial de mis evaluaciones
│
└─ Perfil
    ├─ Mi información
    ├─ Configuración
    ├─ Preferencias de notificaciones
    ├─ Tema (Claro/Oscuro/Auto)
    └─ Cerrar sesión
```

---

### **12. PLAN DE IMPLEMENTACIÓN MÓVIL (4 semanas — Sprints 5-6)**

| Semana | Entregables |
|--------|-------------|
| **Semana 1-2** | Setup Flutter project (iOS + Android). Integración Firebase (Auth + Firestore + Storage). Navegación bottom bar (Dashboard, Evaluar, Perfil). Login con Google SSO (Sign-In widgets nativos). |
| **Semana 3** | Dashboard de proyectos (lectura `proyectos_view`). Vista de detalle de proyecto (PDF viewer, video player). Formulario de evaluación touch-optimizado. Sliders nativos para calificación. |
| **Semana 4** | Notificaciones push (FCM). Modo offline básico (cola local). Escaneo QR de proyectos. Testing en dispositivos físicos. |
| **Entregable** | App móvil funcional en TestFlight + Play Console (beta). |

---

*Documento generado como input para diseño de prototipo y desarrollo del canal móvil Flutter.*  
*Fuente: BIFROST_EXECUTIVE_UNIFIED_v2.md · BIFROST_MONGODB_DATA_MODELS.md · bifrost_requisitos.md*  
*Versión: 1.0 — Febrero 2026*
