# Bifrost - Guía Rápida de Inicio

## 🚀 Inicio Rápido

### 1. Verificar Estado del Sistema

```powershell
# Ejecutar desde la raíz del proyecto
.\diagnostico.ps1
```

Este script verifica:

- ✅ Backend está corriendo
- ✅ Credenciales Firebase están configuradas
- ✅ google-services.json está presente
- ✅ Puertos están abiertos
- ✅ IPs disponibles
- ✅ Endpoints de autenticación funcionan

### 2. Iniciar Backend

```powershell
# Opción A: Desde la raíz
cd IntegradorHub\backend\src\IntegradorHub.API
dotnet run

# Opción B: Usar path completo
cd C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API
dotnet run
```

**Verificar que está activo:**

```powershell
# En otro terminal
curl http://192.168.1.216:5093/api/health
# Debe devolver: {"status":"ok","timestamp":"..."}
```

### 3. Ejecutar Flutter

#### Con el Script de Ayuda (Recomendado)

```powershell
# Para emulador Android (default)
.\run-flutter.ps1

# Para dispositivo físico (detecta IP automáticamente)
.\run-flutter.ps1 -Tipo dispositivo

# Para WiFi específica
.\run-flutter.ps1 -Tipo wifi

# Para IP personalizada
.\run-flutter.ps1 -Tipo custom -CustomIP "192.168.1.100"
```

#### Sin el Script

```powershell
cd biofrost_aplication_movil

# Para emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5093

# Para dispositivo físico
flutter run --dart-define=API_BASE_URL=http://192.168.1.216:5093
```

## 🔧 Solución de Problemas

### Error: "Cuenta existente" al registrarse

**Causa**: El email ya está registrado en Firebase Auth de un intento anterior.

**Solución**:

1. Usa otro email de prueba
2. O elimina el usuario desde Firebase Console:
   - https://console.firebase.google.com
   - Proyecto: `integradorhub-dsm`
   - Authentication → Users → Buscar y eliminar

### Error: "Error de conexión" al iniciar sesión

**Causa**: El usuario no existe en Firebase Auth o la contraseña es incorrecta.

**Solución**:

1. Primero regístrate con ese email
2. Si ya te registraste, verifica:
   - Que la contraseña sea correcta (mínimo 6 caracteres)
   - Que el backend esté activo (ejecutar `.\diagnostico.ps1`)
   - Que la IP esté configurada correctamente

### Backend no responde

```powershell
# 1. Verificar si está corriendo
Get-Process | Where-Object { $_.ProcessName -like '*IntegradorHub*' }

# 2. Si no está, iniciarlo
cd IntegradorHub\backend\src\IntegradorHub.API
dotnet run

# 3. Verificar logs
Get-Content -Tail 20 backend_v2.log
```

## 📱 Formatos de Email Válidos

El sistema detecta automáticamente el rol según el email:

- **Alumno**: `23041234@alumno.utmetropolitana.edu.mx`
  - 8 dígitos + `@alumno.utmetropolitana.edu.mx`
- **Docente**: `profesor.nombre@utmetropolitana.edu.mx`
  - Letras y puntos + `@utmetropolitana.edu.mx`
- **Invitado**: `cualquier@gmail.com`
  - Cualquier otro dominio

## 🧪 Cuentas de Prueba

Puedes crear estas cuentas para probar:

```
Alumno:
Email: 23040001@alumno.utmetropolitana.edu.mx
Password: Test123456
GrupoId: 5A
CarreraId: dsm

Docente:
Email: profesor.test@utmetropolitana.edu.mx
Password: Test123456
Profesion: Ingeniero en Sistemas

Invitado:
Email: externo@gmail.com
Password: Test123456
Organizacion: Freelance
```

## 🌐 URLs y Configuraciones

### Backend

- **Local**: http://192.168.1.216:5093
- **Health**: http://192.168.1.216:5093/api/health
- **Swagger**: http://192.168.1.216:5093/swagger

### Frontend (Flutter)

- **Emulador Android**: http://10.0.2.2:5093
- **Emulador iOS**: http://127.0.0.1:5093
- **Dispositivo físico**: http://192.168.1.216:5093 (IP de tu PC)

### Firebase

- **Console**: https://console.firebase.google.com
- **Proyecto**: integradorhub-dsm
- **Auth**: Firebase Authentication
- **Database**: Cloud Firestore

### Supabase

- **URL**: https://zhnufraaybrruqdtgbwj.supabase.co
- **Bucket**: project-files

## 📂 Estructura del Proyecto

```
Bifrost/
├── IntegradorHub/               # Backend .NET
│   └── backend/
│       └── src/
│           └── IntegradorHub.API/
│               ├── Features/     # Módulos por feature
│               ├── Shared/       # Código compartido
│               └── appsettings.json
│
├── biofrost_aplication_movil/   # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   └── src/
│   │       ├── core/            # Servicios core
│   │       └── features/        # Módulos por feature
│   ├── android/
│   │   └── app/
│   │       └── google-services.json
│   └── pubspec.yaml
│
├── docs/                         # Documentación
│   └── CONEXION_Y_AUTH_FIXES.md # Guía detallada de fixes
│
├── diagnostico.ps1               # Script de diagnóstico
└── run-flutter.ps1               # Script de ejecución Flutter
```

## 🔍 Comandos Útiles

### Ver logs en tiempo real

**Backend:**

```powershell
cd IntegradorHub\backend\src\IntegradorHub.API
Get-Content -Tail 50 -Wait backend_v2.log
```

**Flutter:**

```bash
flutter logs
```

### Limpiar y reconstruir

**Flutter:**

```bash
flutter clean
flutter pub get
flutter run
```

**Backend:**

```powershell
dotnet clean
dotnet build
dotnet run
```

### Probar endpoints manualmente

```powershell
# Health check
Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/health"

# Login
$json = @{
    FirebaseUid = "test-uid-123"
    Email = "test@gmail.com"
    DisplayName = "Test User"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/auth/login" `
    -Method Post -Body $json -ContentType "application/json"
```

## 📚 Documentación Adicional

- [Guía Completa de Fixes](./docs/CONEXION_Y_AUTH_FIXES.md)
- [Arquitectura del Sistema](./documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md)
- [Modelos de Datos](./documentar/database/BIFROST_DATA_MODELS_CLASSES.md)
- [Reglas de Negocio](./documentar/functions/BUSINESS_RULES.md)

## 💡 Tips

1. **Siempre ejecuta `.\diagnostico.ps1` antes de empezar** para verificar que todo esté configurado.

2. **Usa el script `run-flutter.ps1`** en lugar de comandos manuales para evitar errores de configuración.

3. **Revisa los logs** si algo falla:
   - Backend: `Get-Content -Tail 50 backend_v2.log`
   - Flutter: Ver la consola donde ejecutaste `flutter run`

4. **Para dispositivos físicos**, asegúrate de que:
   - El dispositivo y el PC estén en la misma red WiFi
   - El firewall permita conexiones al puerto 5093

5. **Si Firebase Auth falla**, verifica:
   - Que `google-services.json` esté en `android/app/`
   - Que el paquete de la app coincida con el configurado en Firebase

## 🆘 Soporte

Si encuentras problemas:

1. Ejecuta `.\diagnostico.ps1` y revisa el output
2. Lee [CONEXION_Y_AUTH_FIXES.md](./docs/CONEXION_Y_AUTH_FIXES.md) para soluciones detalladas
3. Revisa los logs del backend y Flutter
4. Verifica que las IPs y puertos sean correctos para tu configuración

---

**Última actualización**: 19 de febrero de 2026
