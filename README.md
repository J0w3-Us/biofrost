# BIOFROST INTERFACE

**Sistema Integral de Gestión y Evaluación Competitiva de Proyectos Académicos**

**License:** MIT

Biofrost es una plataforma multi‑canal (web + móvil + backend) diseñada para conectar la entrega de proyectos académicos con su evaluación en campo, garantizando trazabilidad, auditoría y capacidad offline para escenarios presenciales (ferias, exposiciones, jurados).

**Resumen rápido**

- **Propósito:** Facilitar la evaluación y registro de proyectos integradores, optimizando el tiempo de docentes y preservando un historial completo de acciones.
- **Enfoque:** UX móvil para evaluadores in‑situ; portal web para publicación, edición y administración.

**Focos de la aplicación**

**Aplicación Web (frontend)**

- **Stack:** React 18 + Vite + Tailwind CSS
- **Objetivo:** repositorio público/privado de proyectos, panel administrativo, y editor tipo "canvas" para crear y gestionar entregas.
- **Casos de uso:** exhibición de proyectos, revisiones por comité, análisis y reportes, gestión de usuarios y roles.

**Aplicación Móvil (biofrost_aplication_movil)**

- **Stack:** Flutter (Dart)
- **Objetivo:** evaluación rápida e in‑situ por parte de docentes y jurados.
- **Características clave:** escaneo QR para acceso rápido, flujo de evaluación con sliders y checklists, modo offline con sincronización posterior, dictado (speech‑to‑text) para comentarios, notificaciones push.

**Backend Core**

- **Stack:** .NET 9 (C#) con patrón CQRS + Event Sourcing; Firestore como read store; Google Cloud para hosting.
- **Objetivo:** inmutabilidad de eventos, rehidratación de estado y consultas optimizadas para UI.

**Beneficios clave**

- Trazabilidad completa de acciones y cambios.
- Evaluación móvil eficiente para ferias y presentaciones.
- Recuperación y auditoría por diseño (Event Sourcing).

**Estructura relevante del repositorio**

- `biofrost_aplication_movil/` — código fuente Flutter (app móvil).
- `frontend/` — código React (portal web y admin).
- `IntegradorHub/` — backend y servicios de integración.
- `docs/` — documentación arquitectónica y guías.

## Quickstart (desarrolladores)

### Mobile (Flutter)

```powershell
cd biofrost_aplication_movil
flutter pub get
flutter run
```

### Web (React)

```bash
cd frontend
npm install
npm run dev
```

## Configuración Firebase

- Registra las apps (Android/iOS/Web) en Firebase y coloca `google-services.json` / `GoogleService-Info.plist` en los directorios nativos correspondientes.

## Contribuir

- Abre un issue describiendo el cambio o bug.
- Crea PRs pequeños y enfocados; sigue el patrón de commits del repo.

## Contacto

- Equipo de desarrollo: ver documentación interna en `docs/`.

---

_Este README está optimizado para dejar claro el foco de la aplicación web y móvil, facilitar el onboarding de desarrolladores y acelerar pruebas en entornos académicos._
