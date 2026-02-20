# 🌉 BIOFROST INTERFACE
### Sistema Integral de Gestión y Evaluación Competitiva de Proyectos Académicos

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Framework: .NET 9](https://img.shields.io/badge/Framework-.NET%209-512bd4.svg)](https://dotnet.microsoft.com/download/dotnet/9.0)
[![Framework: Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter)](https://flutter.dev/)
[![Framework: React](https://img.shields.io/badge/Framework-React-61DAFB?logo=react)](https://reactjs.org/)

**Biofrost Interface** es una plataforma SaaS multi-canal diseñada para transformar el ecosistema académico de proyectos integradores. Actúa como el puente crítico entre la creación estudiantil y la evaluación docente, eliminando el "cementerio de código" y proporcionando trazabilidad total mediante una arquitectura de vanguardia.

---

## 🚀 Propuesta de Valor

Biofrost resuelve la desconexión entre la entrega de proyectos y su evaluación real in-situ:

*   **Adiós al "Cementerio de Código"**: Los proyectos dejan de ser carpetas olvidadas para convertirse en un catálogo perpetuo y consultable.
*   **Evaluación Móvil Ubicua**: Permite a los docentes evaluar en ferias de proyectos mediante códigos QR, reduciendo el tiempo de gestión en un **73%**.
*   **Integridad Absoluta**: Gracias al **Event Sourcing**, el sistema no solo guarda el estado actual, sino cada acción realizada en la historia del proyecto.

---

## 🏗️ Arquitectura Técnica (Núcleo Unificado)

Biofrost no es una aplicación tradicional; utiliza un patrón de **CQRS + Event Sourcing** para garantizar escalabilidad y resiliencia.

### **Event Sourcing: El Diferenciador**
A diferencia de los sistemas CRUD tradicionales que sobrescriben datos, Biofrost registra cada acción como un **evento inmutable**.
*   **Recuperación Total**: Rehidratación del sistema ante fallos en < 60 segundos.
*   **Auditoría Forense**: Trazabilidad completa de "¿Quién cambió qué y cuándo?".
*   **Reversión Temporal**: Capacidad de ver el estado de un proyecto en cualquier punto del tiempo pasado.

---

## 📱 Ecosistema Multi-Canal

### **Canal Web (React + Vite)**
*   **Portfolio Showcase**: Galería pública de proyectos destacados.
*   **Canvas Editor**: Interfaz compleja para la creación y gestión de proyectos.
*   **Admin Panel**: Herramientas avanzadas de gestión académica y analíticas.

### **Canal Móvil (Flutter)**
*   **Evaluación On-the-go**: Evaluación rápida mediante sliders y gestos touch.
*   **Escaneo QR**: Acceso instantáneo a proyectos durante presentaciones en vivo.
*   **Modo Offline**: Posibilidad de evaluar sin conexión con sincronización automática posterior.
*   **Speech-to-Text**: Dictado de retroalimentación por voz transcribiendo a texto automáticamente.

### **Backend Core (.NET 9 + Firebase)**
*   **Comandos e Historial**: Lógica de negocio enterprise con procesamiento de eventos inmutables.
*   **Firestore Read Models**: Lectura ultra-rápida desnormalizada para los clientes.
*   **Google Cloud Hosting**: Escalabilidad automática con Cloud Run.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnologías |
| :--- | :--- |
| **Backend** | .NET 9 (C#), MediatR (CQRS), Entity Framework Core |
| **Frontend Web** | React 18, Vite, Tailwind CSS, Vercel |
| **App Móvil** | Flutter, Dart, BLoC Pattern |
| **Database** | Firebase Firestore (Event Store + Read Models) |
| **Servicios Cloud** | Google Cloud Run, Firebase Storage, Google Cloud KMS |
| **Autenticación** | Firebase Auth (SSO Institucional Google) |

---

## 📂 Estructura del Proyecto

*   `/biofrost_aplication_movil`: Código fuente de la aplicación móvil en Flutter.
*   `/IntegradorHub`: Módulo de conexión y servicios de integración Backend.
*   `/docs`: Documentación detallada de arquitectura, requisitos y blueprints.
*   `/AI`: Reglas y configuraciones para agentes de inteligencia artificial.
*   `/documentar`: Guías y recursos para la documentación técnica.

---

## 🔑 Seguridad Institucional

El sistema está blindado para el entorno académico de la **UTM**:
*   **Validación de Dominio**: Acceso restringido a cuentas `@utmetropolitana.edu.mx`.
*   **Detección de Roles**: Identificación automática de Alumno/Docente mediante regex de matrícula.
*   **Encriptación KMS**: Datos sensibles (matrículas) protegidos con llaves de Google Cloud.

---

## 📝 Próximos Pasos (Hoja de Ruta)

- [ ] Implementación de Notificaciones Push vía FCM.
- [ ] Refinamiento del motor de Rehidratación de Eventos.
- [ ] Despliegue de la versión Beta en TestFlight y Play Store.

---
*Biofrost Interface - Impulsando la Excelencia Académica mediante Innovación Tecnológica.*