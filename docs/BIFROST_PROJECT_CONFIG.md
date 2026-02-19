# ⚙️ BIFROST INTERFACE - CONFIGURACIÓN DEL PROYECTO

**Proyecto**: Bifrost Interface  
**Stack Backend**: ASP.NET Core Web API (.NET 9)  
**Base de Datos**: MongoDB Atlas  
**Arquitectura**: Clean Architecture + CQRS + Event Sourcing  
**Versión**: 1.0  
**Fecha**: Febrero 2026

---

## 📋 ÍNDICE

1. [Stack Tecnológico](#stack-tecnológico)
2. [Estructura de la Solución](#estructura-de-la-solución)
3. [Estructura de Carpetas](#estructura-de-carpetas)
4. [Dependencias (NuGet Packages)](#dependencias-nuget-packages)
5. [Configuración de MongoDB](#configuración-de-mongodb)
6. [Configuración del API](#configuración-del-api)
7. [Guía de Inicio Rápido](#guía-de-inicio-rápido)

---

## STACK TECNOLÓGICO

```
┌──────────────────────────────────────────────────────────────┐
│                    STACK BIFROST BACKEND                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  🔧 RUNTIME                                                 │
│  ├─ .NET 9 (LTS)                                            │
│  ├─ ASP.NET Core Web API                                    │
│  └─ C# 13                                                   │
│                                                              │
│  🗄️ BASE DE DATOS                                           │
│  ├─ MongoDB Atlas (Cloud)                                    │
│  ├─ MongoDB.Driver 3.x (NuGet)                              │
│  └─ Change Streams (Proyecciones en tiempo real)             │
│                                                              │
│  🔐 AUTENTICACIÓN                                           │
│  ├─ Firebase Auth (Google SSO)                               │
│  └─ JWT Bearer Tokens                                        │
│                                                              │
│  ☁️ CLOUD                                                    │
│  ├─ Google Cloud Platform (GCP)                              │
│  ├─ Cloud Run (Contenedores serverless)                      │
│  ├─ Cloud Storage (Multimedia)                               │
│  └─ Firebase (Auth + Hosting)                                │
│                                                              │
│  📱 FRONTENDS (Futuros)                                      │
│  ├─ React 18 + Vite (Web)                                    │
│  └─ Flutter / Dart (Móvil iOS/Android)                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## ESTRUCTURA DE LA SOLUCIÓN

La solución sigue **Clean Architecture** con separación estricta de responsabilidades:

```
┌──────────────────────────────────────────────────────────────┐
│                 CLEAN ARCHITECTURE LAYERS                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               Bifrost.API                              │  │
│  │  (Capa de Presentación / Entry Point)                  │  │
│  │  • Controllers REST                                    │  │
│  │  • Middleware (Auth, Error Handling, CORS)              │  │
│  │  • Program.cs (Composición de DI)                      │  │
│  │  Depende de: Application, Infrastructure               │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │           Bifrost.Application                          │  │
│  │  (Casos de Uso / Lógica de Aplicación)                 │  │
│  │  • Command Handlers (CQRS - Escritura)                 │  │
│  │  • Query Handlers (CQRS - Lectura)                     │  │
│  │  • DTOs y Validators                                   │  │
│  │  • Interfaces de Servicios                             │  │
│  │  Depende de: Domain                                    │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │              Bifrost.Domain                            │  │
│  │  (Núcleo / Entidades / Lógica de Negocio Pura)        │  │
│  │  • Entidades (Proyecto, Evaluacion, Usuario, Evento)   │  │
│  │  • Value Objects (Multimedia, MiembroSquad, etc.)      │  │
│  │  • Enums (EstadoProyecto, RolUsuario, etc.)            │  │
│  │  • Interfaces de Repositorios                          │  │
│  │  Depende de: NADA (capa más interna)                   │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Bifrost.Infrastructure                       │  │
│  │  (Implementaciones Externas)                           │  │
│  │  • MongoDB Repositories                                │  │
│  │  • Event Store Implementation                          │  │
│  │  • Firebase Auth Integration                           │  │
│  │  • Cloud Storage Service                               │  │
│  │  • Background Services (Projections)                   │  │
│  │  Depende de: Application (para implementar interfaces) │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Diagrama de Dependencias entre Proyectos

```
                    Bifrost.API
                   /           \
                  ▼             ▼
     Bifrost.Application    Bifrost.Infrastructure
                  \             /
                   ▼           ▼
                  Bifrost.Domain
                  (sin dependencias)
```

**Regla de oro**: Las dependencias siempre apuntan hacia adentro.
- `Domain` NO conoce a `Infrastructure` ni a `Application`.
- `Infrastructure` implementa interfaces definidas en `Domain`.
- `API` compone todo via Dependency Injection.

---

## ESTRUCTURA DE CARPETAS

```
Bifrost/
├── 📄 Bifrost.sln                          ← Solución principal
├── 📄 .gitignore
├── 📄 README.md
│
├── 📁 docs/                                 ← Documentación del proyecto
│   ├── BIFROST_EXECUTIVE_UNIFIED_v2.md      ← Documento ejecutivo
│   ├── BIFROST_MONGODB_DATA_MODELS.md       ← Modelos de datos MongoDB
│   ├── bifrost_requisitos.md                ← Requisitos funcionales y no funcionales
│   ├── BIFROST_DATA_MODELS_CLASSES.md       ← Clases C# de los modelos
│   ├── BIFROST_PROJECT_CONFIG.md            ← Este documento
│   ├── BIFROST_GIT_REPOSITORY.md            ← Configuración del repositorio
│   └── BIFROST_SYSTEM_ARCHITECTURE.md       ← Diagrama de arquitectura
│
├── 📁 src/                                  ← Código fuente
│   │
│   ├── 📁 Bifrost.Domain/                  ← 🟢 CAPA INTERNA (sin dependencias)
│   │   ├── Bifrost.Domain.csproj
│   │   ├── 📁 Common/
│   │   │   └── BaseEntity.cs                ← Clase base con auditoría
│   │   ├── 📁 Entities/
│   │   │   ├── Proyecto.cs                  ← Read Model del proyecto
│   │   │   ├── Evaluacion.cs                ← Read Model de reseña/evaluación
│   │   │   ├── Usuario.cs                   ← Read Model del usuario
│   │   │   ├── Evento.cs                    ← Evento inmutable (Event Store)
│   │   │   └── Snapshot.cs                  ← Snapshot de aggregate
│   │   ├── 📁 Enums/
│   │   │   ├── EstadoProyecto.cs            ← Borrador, Activo, Publico, Historico
│   │   │   ├── RolUsuario.cs                ← Alumno, Docente, Administrador
│   │   │   ├── TipoEvaluador.cs             ← Docente, Empresa, Jurado, Alumno
│   │   │   ├── EstadoEvaluacion.cs          ← Borrador, Completada
│   │   │   └── TipoMultimedia.cs            ← Banner, Screenshot, Video, Pdf
│   │   ├── 📁 ValueObjects/
│   │   │   ├── MiembroSquad.cs              ← Miembro del equipo
│   │   │   ├── MultimediaProyecto.cs        ← Video, Banner, Screenshots, PDF
│   │   │   ├── MetadataAcademica.cs         ← Docente asesor, grupo, carrera
│   │   │   ├── MetricasProyecto.cs          ← Scores, engagement
│   │   │   └── ProyectoValueObjects.cs      ← TecnologiaStack, CambioEstado, etc.
│   │   └── 📁 Interfaces/
│   │       ├── IEventStore.cs               ← Contrato del Event Store
│   │       ├── IProyectoRepository.cs       ← Contrato del repo de proyectos
│   │       ├── IEvaluacionRepository.cs     ← Contrato del repo de evaluaciones
│   │       └── IUsuarioRepository.cs        ← Contrato del repo de usuarios
│   │
│   ├── 📁 Bifrost.Application/             ← 🟡 CASOS DE USO
│   │   ├── Bifrost.Application.csproj
│   │   ├── 📁 Commands/                    ← CQRS Write Side
│   │   │   ├── 📁 Proyectos/
│   │   │   │   ├── CrearProyectoCommand.cs
│   │   │   │   ├── AgregarMiembroCommand.cs
│   │   │   │   ├── SubirMultimediaCommand.cs
│   │   │   │   └── CambiarEstadoCommand.cs
│   │   │   ├── 📁 Evaluaciones/
│   │   │   │   ├── IniciarEvaluacionCommand.cs
│   │   │   │   ├── CalificarCriterioCommand.cs
│   │   │   │   └── CompletarEvaluacionCommand.cs
│   │   │   └── 📁 Usuarios/
│   │   │       ├── RegistrarUsuarioCommand.cs
│   │   │       └── ActualizarPerfilCommand.cs
│   │   ├── 📁 Queries/                     ← CQRS Read Side
│   │   │   ├── 📁 Proyectos/
│   │   │   │   ├── GetProyectoByIdQuery.cs
│   │   │   │   ├── GetProyectosPublicosQuery.cs
│   │   │   │   ├── BuscarProyectosQuery.cs
│   │   │   │   └── GetLeaderboardQuery.cs
│   │   │   ├── 📁 Evaluaciones/
│   │   │   │   ├── GetEvaluacionesPorProyectoQuery.cs
│   │   │   │   └── GetHistorialEvaluadorQuery.cs
│   │   │   └── 📁 Usuarios/
│   │   │       ├── GetUsuarioByEmailQuery.cs
│   │   │       └── GetDocentesDisponiblesQuery.cs
│   │   ├── 📁 DTOs/
│   │   │   ├── ProyectoDto.cs
│   │   │   ├── EvaluacionDto.cs
│   │   │   ├── UsuarioDto.cs
│   │   │   └── MultimediaDto.cs
│   │   ├── 📁 Validators/
│   │   │   ├── CrearProyectoValidator.cs
│   │   │   └── EvaluacionValidator.cs
│   │   └── 📁 Interfaces/
│   │       ├── IFileStorageService.cs
│   │       └── INotificationService.cs
│   │
│   ├── 📁 Bifrost.Infrastructure/          ← 🔵 IMPLEMENTACIONES EXTERNAS
│   │   ├── Bifrost.Infrastructure.csproj
│   │   ├── DependencyInjection.cs           ← Registro de servicios en DI
│   │   ├── 📁 Persistence/
│   │   │   ├── MongoDbInitializer.cs        ← Creación de índices al startup
│   │   │   └── 📁 Repositories/
│   │   │       ├── MongoEventStore.cs       ← Implementación del Event Store
│   │   │       ├── MongoProyectoRepository.cs
│   │   │       ├── MongoEvaluacionRepository.cs
│   │   │       └── MongoUsuarioRepository.cs
│   │   ├── 📁 Services/
│   │   │   ├── GcsFileStorageService.cs     ← Google Cloud Storage
│   │   │   ├── FirebaseAuthService.cs       ← Firebase Auth
│   │   │   └── EventProjectionService.cs    ← Background Service para proyecciones
│   │   └── 📁 Configuration/
│   │       ├── MongoDbSettings.cs
│   │       └── FirebaseSettings.cs
│   │
│   └── 📁 Bifrost.API/                     ← 🔴 ENTRY POINT
│       ├── Bifrost.API.csproj
│       ├── Program.cs                       ← Host builder + DI composition
│       ├── appsettings.json                 ← Config base
│       ├── appsettings.Development.json     ← Config de desarrollo
│       ├── 📁 Controllers/
│       │   ├── ProyectosController.cs
│       │   ├── EvaluacionesController.cs
│       │   ├── UsuariosController.cs
│       │   └── MaintenanceController.cs     ← Endpoint de rehidratación
│       ├── 📁 Middleware/
│       │   ├── ExceptionHandlerMiddleware.cs
│       │   └── RequestLoggingMiddleware.cs
│       └── 📁 Filters/
│           └── ValidationFilterAttribute.cs
│
├── 📁 tests/                                ← Tests (futuro)
│   ├── 📁 Bifrost.Domain.Tests/
│   ├── 📁 Bifrost.Application.Tests/
│   └── 📁 Bifrost.API.Tests/
│
└── 📁 AI/                                   ← Artefactos de IA/diseño existentes
    └── 📁 web_prototypes/
```

---

## DEPENDENCIAS (NuGet Packages)

### Bifrost.Domain

```xml
<PackageReference Include="MongoDB.Bson" Version="3.*" />
```

> Solo `MongoDB.Bson` para los atributos de serialización `[BsonElement]`, `[BsonId]`, etc.
> NO depende de `MongoDB.Driver` (ese va en Infrastructure).

### Bifrost.Application

```xml
<!-- Referencias a proyectos -->
<ProjectReference Include="..\Bifrost.Domain\Bifrost.Domain.csproj" />

<!-- Paquetes -->
<PackageReference Include="FluentValidation" Version="11.*" />
```

### Bifrost.Infrastructure

```xml
<!-- Referencias a proyectos -->
<ProjectReference Include="..\Bifrost.Application\Bifrost.Application.csproj" />

<!-- Paquetes -->
<PackageReference Include="MongoDB.Driver" Version="3.*" />                         <!-- Driver de MongoDB -->
<PackageReference Include="Microsoft.Extensions.DependencyInjection.Abstractions" /> <!-- DI -->
<PackageReference Include="Microsoft.Extensions.Configuration.Abstractions" />       <!-- Config -->
<PackageReference Include="Microsoft.Extensions.Configuration.Binder" />             <!-- Config binding -->
<PackageReference Include="Microsoft.Extensions.Logging.Abstractions" />             <!-- Logging -->
```

### Bifrost.API

```xml
<!-- Referencias a proyectos -->
<ProjectReference Include="..\Bifrost.Application\Bifrost.Application.csproj" />
<ProjectReference Include="..\Bifrost.Infrastructure\Bifrost.Infrastructure.csproj" />

<!-- Paquetes (la mayoría vienen con el template de Web API) -->
<PackageReference Include="Microsoft.AspNetCore.OpenApi" />
```

---

## CONFIGURACIÓN DE MONGODB

### appsettings.json

```json
{
  "ConnectionStrings": {
    "MongoDB": "mongodb://localhost:27017"
  },
  "MongoDB": {
    "DatabaseName": "bifrost"
  }
}
```

### appsettings.Production.json (NO incluido en Git)

```json
{
  "ConnectionStrings": {
    "MongoDB": "mongodb+srv://bifrost_app:<password>@cluster0.xxxxx.mongodb.net/bifrost?retryWrites=true&w=majority"
  }
}
```

### Colecciones MongoDB

| Colección | Propósito | Tipo |
|-----------|-----------|------|
| `events` | Event Store (inmutable) | Write Side |
| `snapshots` | Snapshots de aggregates | Write Side |
| `proyectos_view` | Vista materializada de proyectos | Read Side |
| `evaluaciones_view` | Vista materializada de evaluaciones | Read Side |
| `usuarios_view` | Vista materializada de usuarios | Read Side |
| `analytics_view` | Métricas agregadas (futuro) | Read Side |
| `notificaciones_view` | Cola de notificaciones (futuro) | Read Side |

---

## CONFIGURACIÓN DEL API

### Program.cs (Composición)

```csharp
var builder = WebApplication.CreateBuilder(args);

// Servicios
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Infraestructura (MongoDB, Repositorios, Servicios)
builder.Services.AddInfrastructure(builder.Configuration);

// CORS para frontend
builder.Services.AddCors(options =>
{
    options.AddPolicy("BifrostCors", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:5173")
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

var app = builder.Build();

// Inicialización de MongoDB (crea índices al startup)
using (var scope = app.Services.CreateScope())
{
    var initializer = scope.ServiceProvider.GetRequiredService<MongoDbInitializer>();
    await initializer.InitializeAsync();
}

// Pipeline HTTP
if (app.Environment.IsDevelopment())
    app.MapOpenApi();

app.UseCors("BifrostCors");
app.UseAuthorization();
app.MapControllers();
app.Run();
```

---

## GUÍA DE INICIO RÁPIDO

### Prerrequisitos

- [.NET 9 SDK](https://dotnet.microsoft.com/download) instalado
- [MongoDB Community Server](https://www.mongodb.com/try/download/community) o MongoDB Atlas
- Git

### Pasos para ejecutar

```bash
# 1. Clonar el repositorio
git clone <url-del-repo>
cd Bifrost

# 2. Restaurar paquetes NuGet
dotnet restore Bifrost.sln

# 3. Compilar la solución
dotnet build Bifrost.sln

# 4. Ejecutar el API
dotnet run --project src/Bifrost.API

# 5. El API estará disponible en:
#    http://localhost:5000 (HTTP)
#    OpenAPI docs: http://localhost:5000/openapi/v1.json
```

### Verificar MongoDB

```bash
# Conectar a MongoDB local
mongosh

# Verificar que la base de datos "bifrost" fue creada
show dbs
use bifrost
show collections
# Deberías ver: events, snapshots, proyectos_view, evaluaciones_view, usuarios_view
```

---

**Documento generado para**: Bifrost Interface — Sprint 1  
**Fecha**: Febrero 2026  
**Estado**: Referencia de configuración del proyecto
