## 11. ARQUITECTURA DEL SISTEMA (IMPLEMENTACIÓN ACTUAL)

Este proyecto implementa una arquitectura moderna, desacoplada y escalable, dividida físicamente en dos grandes bloques tecnológicos: un Backend robusto en .NET 8 y un Frontend reactivo en React 19.

### 11.1. Stack Tecnológico Actual

| Capa | Tecnología | Versión | Rol Principal |
| :--- | :--- | :--- | :--- |
| **Backend** | .NET (C#) | 8.0 | API REST, Reglas de Negocio, Orquestación. |
| **Frontend** | React | 19.x | Interfaz de Usuario, Estado Global. |
| **Build Tool** | Vite | 7.x | Empaquetado y Entorno de Desarrollo Rápido. |
| **Estilos** | Tailwind CSS | 4.x | Diseño Atómico y Responsivo. |
| **BD** | Google Firestore | NoSQL | Persistencia de Datos Documental. |
| **Auth** | Firebase Auth | SDK | Gestión de Identidad y Roles. |
| **Patrón** | CQRS + Mediator | MediatR | Separación de Comandos y Consultas. |

### 11.2. Arquitectura Backend (.NET 8) - Vertical Slice Architecture

El backend no sigue una arquitectura de capas tradicional (N-Layer), sino que adopta **Vertical Slice Architecture** (Arquitectura de Cortes Verticales). Este enfoque organiza el código por **Features** (Funcionalidades) en lugar de capas técnicas, lo que permite que cada funcionalidad (ej. "Crear Proyecto") sea autónoma y fácil de mantener.

#### Organización del Código
*   **Features/**: Es el corazón del sistema. Cada carpeta aquí representa una "Rebanada Vertical" completa.
    *   *Ejemplo:* `Features/Projects/Create` contiene:
        *   `CreateProjectCommand.cs` (La intención del usuario).
        *   `CreateProjectHandler.cs` (La lógica de negocio).
        *   `CreateProjectValidator.cs` (Reglas de validación, ej. "Título no vacío").
        *   `ProjectsController.cs` (El endpoint HTTP que expone la funcionalidad).
*   **Shared/**: Contiene el núcleo común que comparten las features, como las Entidades del Dominio (`User`, `Project`) y la configuración de Infraestructura (`FirestoreContext`).

#### Patrón CQRS (Command Query Responsibility Segregation)
Utilizamos la librería **MediatR** para desacoplar totalmente la recepción de una petición HTTP de su procesamiento.
*   **Commands (Escritura):** Acciones que modifican el estado del sistema (Create, Update, Delete). Retornan éxito o fallo.
*   **Queries (Lectura):** Acciones que solo recuperan datos. Están optimizadas para velocidad y no modifican nada.

### 11.3. Arquitectura Frontend (React 19 + Vite) - Feature Based

El frontend refleja la estructura modular del backend para reducir la carga cognitiva del desarrollador. Si existe una Feature de "Proyectos" en el backend, existe una Feature de "Proyectos" en el frontend.

#### Estructura de Componentes
*   **src/features/**: Contiene la lógica, hooks y componentes específicos de cada módulo de negocio (Auth, ProjectCanvas, Showcase).
*   **src/components/ui/**: Componentes "tontos" y reutilizables (Botones, Inputs, Cards) que siguen un sistema de diseño atómico. No contienen lógica de negocio.
*   **src/lib/**: Configuración de infraestructura frontend (Cliente de Axios, Inicialización de Firebase).

#### Flujo de Datos (Data Journey)
1.  **UI:** El usuario interactúa con un componente (ej. clic en "Guardar").
2.  **Hook:** Un Custom Hook (`useProjectOps`) despacha la acción.
3.  **API Layer:** Axios envía la petición HTTP al Backend (.NET).
4.  **CQRS:** El controlador recibe la petición y envía un *Command* a MediatR.
5.  **Handler:** El Handler ejecuta la lógica, valida reglas de negocio y persiste en Firestore.
6.  **Response:** El resultado viaja de vuelta a la UI para actualizar el estado visual.

### 11.4. Estructura de Directorios del Proyecto (Alto Nivel)

```text
/IntegradorHub-Root
│
├── /backend (Solución .NET 8 - Vertical Slice Architecture)
│   ├── /src
│   │   ├── /IntegradorHub.API
│   │   │   ├── /Features                  <-- LÓGICA DE NEGOCIO (Slices)
│   │   │   │   ├── /Auth                  (Login, Identificación de Roles)
│   │   │   │   ├── /Projects              (CRUD de Proyectos, Lógica de Squads)
│   │   │   │   └── /Evaluations           (Sistema de Feedback Docente)
│   │   │   ├── /Shared                    <-- NÚCLEO COMPARTIDO
│   │   │   │   ├── /Domain                (Entidades: User, Project)
│   │   │   │   └── /Infrastructure        (Conexión a Firestore)
│   │   │   └── Program.cs                 (Configuración de Inyección de Dependencias)
│
├── /frontend (React 19 + Vite - Feature Based)
│   ├── /src
│   │   ├── /features                      <-- MÓDULOS DE UI
│   │   │   ├── /auth                      (Formularios y Hooks de Sesión)
│   │   │   ├── /project-canvas            (Editor de Bloques estilo Notion)
│   │   │   └── /showcase                  (Galería Pública)
│   │   ├── /components                    <-- SISTEMA DE DISEÑO (Atomic)
│   │   ├── /lib                           (Configuración Axios/Firebase)
│   │   └── flujos y rutas                 (Router y Layouts)
│
└── /docs                                  <-- DOCUMENTACIÓN EXTENDIDA
```