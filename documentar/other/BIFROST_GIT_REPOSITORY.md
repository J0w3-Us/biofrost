# 🗃️ BIFROST INTERFACE - REPOSITORIO GIT

**Proyecto**: Bifrost Interface  
**Plataforma de hosting**: GitHub  
**Estrategia de branching**: Git Flow simplificado  
**Versión**: 1.0  
**Fecha**: Febrero 2026

---

## 📋 ÍNDICE

1. [Estructura del Repositorio](#estructura-del-repositorio)
2. [Estrategia de Branching](#estrategia-de-branching)
3. [Convenciones de Commits](#convenciones-de-commits)
4. [Configuración del .gitignore](#configuración-del-gitignore)
5. [Protección de Secretos](#protección-de-secretos)
6. [Flujo de Trabajo del Equipo](#flujo-de-trabajo-del-equipo)

---

## ESTRUCTURA DEL REPOSITORIO

```
Bifrost/                           ← Raíz del repositorio
├── 📄 .gitignore                   ← Reglas de exclusión
├── 📄 Bifrost.sln                  ← Solución C#
├── 📄 README.md                    ← Documentación principal del repo
│
├── 📁 docs/                        ← Documentación del proyecto
│   ├── BIFROST_EXECUTIVE_UNIFIED_v2.md
│   ├── BIFROST_MONGODB_DATA_MODELS.md
│   ├── bifrost_requisitos.md
│   ├── BIFROST_DATA_MODELS_CLASSES.md
│   ├── BIFROST_PROJECT_CONFIG.md
│   ├── BIFROST_GIT_REPOSITORY.md    ← Este documento
│   └── BIFROST_SYSTEM_ARCHITECTURE.md
│
├── 📁 src/                         ← Código fuente (.NET)
│   ├── Bifrost.Domain/
│   ├── Bifrost.Application/
│   ├── Bifrost.Infrastructure/
│   └── Bifrost.API/
│
├── 📁 tests/                       ← Tests unitarios y de integración
│
└── 📁 AI/                          ← Artefactos de diseño y prototipos
    └── web_prototypes/
```

---

## ESTRATEGIA DE BRANCHING

Se utiliza **Git Flow simplificado** adaptado para un equipo pequeño (2 personas):

```
                    ┌──── hotfix/fix-auth ────┐
                    │                          │
main ●──────●──────●──────────────────────────●──────●
              \                                      /
               \    develop                         /
                ●──────●──────●──────●──────●──────●
                        \      \      /      /
                         \      \    /      /
                 feature/  \   feature/   /
                 auth       \  eval      /
                             \          /
                              \feature /
                               \proyectos
```

### Ramas principales

| Rama | Propósito | Protegida |
|------|-----------|-----------|
| `main` | Código en producción. Solo se hace merge desde `develop` | ✅ Sí |
| `develop` | Rama de integración. Features se fusionan aquí | ✅ Sí |

### Ramas de trabajo

| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feature/` | Nueva funcionalidad | `feature/auth-google-sso` |
| `fix/` | Corrección de bug | `fix/evaluacion-score-calculation` |
| `hotfix/` | Corrección urgente en producción | `hotfix/security-patch` |
| `docs/` | Solo documentación | `docs/api-endpoints` |
| `refactor/` | Refactorización sin cambio funcional | `refactor/clean-repositories` |

### Reglas de branching

1. **NUNCA** hacer commit directo a `main`
2. **NUNCA** hacer commit directo a `develop`
3. **Siempre** crear feature branch desde `develop`
4. **Siempre** crear PR (Pull Request) para merge
5. **Mínimo** 1 review antes de merge

---

## CONVENCIONES DE COMMITS

Se sigue la convención de **Conventional Commits**:

```
<tipo>(<alcance>): <descripción corta>

[cuerpo opcional]

[footer opcional]
```

### Tipos permitidos

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `feat` | Nueva funcionalidad | `feat(auth): agregar login con Google SSO` |
| `fix` | Corrección de bug | `fix(eval): corregir cálculo de score total` |
| `docs` | Documentación | `docs(models): agregar diagrama de clases` |
| `style` | Formato (sin cambio lógico) | `style(api): formatear controllers` |
| `refactor` | Refactorización | `refactor(repo): extraer base repository` |
| `test` | Tests | `test(domain): agregar tests para Proyecto` |
| `chore` | Mantenimiento | `chore(deps): actualizar MongoDB.Driver` |
| `ci` | CI/CD | `ci: agregar GitHub Actions workflow` |

### Alcances principales

| Alcance | Descripción |
|---------|-------------|
| `auth` | Autenticación y perfiles |
| `proj` | Gestión de proyectos |
| `eval` | Evaluaciones/reseñas |
| `media` | Multimedia (video, imágenes) |
| `api` | Controllers y endpoints |
| `domain` | Entidades y value objects |
| `infra` | Infrastructure y MongoDB |
| `docs` | Documentación |

### Ejemplos de commits

```
feat(proj): crear modelo de datos para Proyecto

- Agregar entidad Proyecto con todos los campos de RF-PROJ-001
- Agregar value objects: MultimediaProyecto, MiembroSquad
- Crear interfaz IProyectoRepository
- Documentar relación con requisitos en XML comments

Refs: RF-PROJ-001, RF-PROJ-002, RF-PROJ-004
```

```
fix(eval): corregir score cuando hay 0 evaluaciones

El scorePromedio arrojaba NaN cuando no había evaluaciones.
Se agrega validación para retornar 0 en ese caso.

Fixes #12
```

---

## CONFIGURACIÓN DEL .gitignore

```gitignore
# ===== .NET Build =====
bin/
obj/
*.user
*.suo
*.vs
.vs/
[Dd]ebug/
[Rr]elease/

# ===== Secretos =====
appsettings.Production.json
appsettings.Staging.json
*.pfx
*.key

# ===== IDE =====
.idea/
*.swp
*~

# ===== OS =====
.DS_Store
Thumbs.db
desktop.ini

# ===== NuGet =====
*.nupkg
**/packages/*

# ===== Node (frontend futuro) =====
node_modules/
dist/
.next/
```

### ⚠️ Archivos que NUNCA deben subirse

| Archivo | Razón |
|---------|-------|
| `appsettings.Production.json` | Contiene connection string de MongoDB Atlas |
| `*.pfx`, `*.key` | Certificados SSL |
| `bin/`, `obj/` | Archivos compilados |
| `.vs/` | Configuración local del IDE |

---

## PROTECCIÓN DE SECRETOS

### Archivos de configuración por entorno

```
appsettings.json                 ← Base (en Git) - valores por defecto para desarrollo
appsettings.Development.json     ← Desarrollo local (en Git) - MongoDB localhost
appsettings.Production.json      ← Producción (NO en Git) - MongoDB Atlas
appsettings.Staging.json         ← Staging (NO en Git)
```

### Variables sensibles que NO deben estar en Git

| Variable | Ubicación segura |
|----------|-----------------|
| MongoDB Atlas connection string | GCP Secret Manager o variable de entorno |
| Firebase Admin SDK credentials | GCP Secret Manager |
| JWT signing key | GCP Secret Manager |

### Configuración recomendada para producción

```bash
# En Google Cloud Run, usar variables de entorno:
gcloud run deploy bifrost-api \
  --set-env-vars "ConnectionStrings__MongoDB=mongodb+srv://..." \
  --set-env-vars "Firebase__ProjectId=bifrost-utm"
```

---

## FLUJO DE TRABAJO DEL EQUIPO

### Para un equipo de 2 personas (Scrum)

```
┌─────────────────────────────────────────────────────────────┐
│                 FLUJO DE TRABAJO GIT                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. PLANIFICACIÓN DEL SPRINT                                │
│     └─ Definir features y asignar a miembros                │
│                                                             │
│  2. CREAR FEATURE BRANCH                                    │
│     git checkout develop                                    │
│     git pull origin develop                                 │
│     git checkout -b feature/nombre-feature                  │
│                                                             │
│  3. DESARROLLO                                              │
│     git add .                                               │
│     git commit -m "feat(scope): descripción"                │
│     (commits pequeños y frecuentes)                         │
│                                                             │
│  4. PUSH Y PULL REQUEST                                     │
│     git push origin feature/nombre-feature                  │
│     Crear PR en GitHub → develop                            │
│     Asignar al compañero como reviewer                      │
│                                                             │
│  5. CODE REVIEW                                             │
│     El compañero revisa, aprueba o solicita cambios         │
│                                                             │
│  6. MERGE                                                   │
│     Squash merge a develop                                  │
│     Eliminar feature branch                                 │
│                                                             │
│  7. RELEASE                                                 │
│     Al final del sprint:                                    │
│     Merge develop → main                                    │
│     Tag: v1.0.0-sprint1                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Comandos rápidos

```bash
# Crear feature branch
git checkout develop && git pull
git checkout -b feature/mi-feature

# Guardar progreso
git add . && git commit -m "feat(scope): descripción"

# Sincronizar con develop
git fetch origin && git rebase origin/develop

# Subir y crear PR
git push origin feature/mi-feature
# → Crear PR en GitHub

# Después del merge, limpiar
git checkout develop && git pull
git branch -d feature/mi-feature
```

### Versionado semántico

```
v<MAJOR>.<MINOR>.<PATCH>-<sprint>

Ejemplo: v1.0.0-sprint1
         v1.1.0-sprint2 (nueva funcionalidad)
         v1.1.1-sprint2 (corrección)
```

---

**Documento generado para**: Bifrost Interface — Sprint 1  
**Fecha**: Febrero 2026  
**Equipo**: Jose Yael López Hu & Uziel Isaac Pech Balam
