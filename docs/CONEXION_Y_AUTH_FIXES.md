# Guía de Solución: Errores de Autenticación y Conexión

## 📋 Resumen de Cambios Aplicados

### 1. **Corrección de Credenciales Firebase (Backend)**

**Archivo**: `IntegradorHub\backend\src\IntegradorHub.API\Shared\Infrastructure\FirestoreContext.cs`

**Problema**: La ruta relativa `../../../` para localizar las credenciales de Firebase no funcionaba correctamente en todos los entornos.

**Solución**:

- Busca primero en el directorio actual
- Si no encuentra, busca en el directorio padre
- Normaliza la ruta con `Path.GetFullPath()`
- Agrega logs detallados para debugging
- Lanza excepción si no encuentra el archivo

**Código actualizado**:

```csharp
var credentialsPath = Path.Combine(
    Directory.GetCurrentDirectory(),
    "integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json"
);

if (!File.Exists(credentialsPath))
{
    credentialsPath = Path.Combine(
        Directory.GetCurrentDirectory(),
        "..",
        "integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json"
    );
}

credentialsPath = Path.GetFullPath(credentialsPath);
```

### 2. **Permisos de Internet (Flutter)**

**Archivo**: `biofrost_aplication_movil\android\app\src\main\AndroidManifest.xml`

**Problema**: Faltaban permisos de internet en el AndroidManifest.

**Solución**: Agregados permisos necesarios:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

## 🔧 Configuración de Conexión

### Backend (.NET)

**Configuración actual**: `http://192.168.1.216:5093`

**Bases de datos configuradas**:

- **Firebase/Firestore**: `integradorhub-dsm`
- **Supabase**: `https://zhnufraaybrruqdtgbwj.supabase.co`
- **Storage Bucket**: `project-files`

### Frontend (Flutter)

**Configuración actual**: `http://192.168.1.216:5093`

**Importante**: Dependiendo del dispositivo:

- **Emulador Android**: Usar `http://10.0.2.2:5093`
- **Emulador iOS**: Usar `http://127.0.0.1:5093`
- **Dispositivo físico**: Usar la IP local del PC (ej: `http://192.168.1.216:5093`)

### Cómo cambiar la URL del backend:

```bash
# Opción 1: Usar dart-define al ejecutar
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5093

# Opción 2: Editar app_config.dart (defaultValue)
# lib/src/core/config/app_config.dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5093',  // ← Cambiar aquí
);
```

## 🐛 Solución de Errores Comunes

### Error: "Cuenta existente" al registrarse con email inventado

**Causa**: El email ya fue registrado parcialmente en Firebase Auth en un intento anterior que falló.

**Solución**:

1. **Opción A - Limpiar Firebase Auth**:
   - Ve a la consola de Firebase
   - Authentication → Users
   - Busca y elimina el email problemático

2. **Opción B - Usar otro email de prueba**:

   ```
   # Emails válidos según regex:
   - Alumno: 23041234@alumno.utmetropolitana.edu.mx
   - Docente: nombre.apellido@utmetropolitana.edu.mx
   - Invitado: cualquier@gmail.com
   ```

3. **Opción C - Rollback automático** (ya implementado):
   El código de Flutter ahora hace rollback automático si el backend falla:
   ```dart
   catch (e) {
     await _rollbackFirebaseUser(fbUser);  // Elimina de Firebase
     state = state.copyWith(errorMessage: e.userMessage);
   }
   ```

### Error: "Error de conexión" al iniciar sesión

**Causas posibles**:

1. **El backend no está corriendo**

   ```bash
   # Verificar si está activo:
   curl http://192.168.1.216:5093/api/health

   # Debería devolver:
   {"status":"ok","timestamp":"..."}
   ```

2. **Firewall bloqueando el puerto 5093**

   ```bash
   # Windows: Abrir PowerShell como Admin
   New-NetFirewallRule -DisplayName "Backend Bifrost" -Direction Inbound -LocalPort 5093 -Protocol TCP -Action Allow
   ```

3. **IP incorrecta para el dispositivo**
   - Emulador Android necesita: `10.0.2.2:5093`
   - Dispositivo físico necesita: IP del PC en la red local

   ```bash
   # Obtener tu IP local (Windows):
   ipconfig
   # Buscar: IPv4 Address en la sección WiFi/Ethernet
   ```

4. **Usuario no existe en Firebase Auth**
   - Primero debes registrarte antes de hacer login
   - O el usuario se eliminó de Firebase pero sigue en Firestore

### Error: "No se pudo conectar al servidor"

**Solución paso a paso**:

1. **Verificar backend está corriendo**:

   ```bash
   cd C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API
   dotnet run
   ```

2. **Verificar logs del backend**:

   ```bash
   Get-Content -Tail 20 backend_v2.log
   ```

3. **Probar endpoint manualmente**:

   ```bash
   # PowerShell:
   Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/health" -Method Get
   ```

4. **Verificar conectividad desde dispositivo**:
   - Si es emulador: Usar Chrome en el emulador para abrir `http://10.0.2.2:5093/api/health`
   - Si es físico: Asegurarse que ambos estén en la misma red WiFi

## 🧪 Probar Autenticación

### Desde PowerShell/Terminal:

**Probar Login**:

```powershell
$json = @{
    FirebaseUid = "test-uid-$(Get-Random)"
    Email = "test@gmail.com"
    DisplayName = "Test User"
    PhotoUrl = $null
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/auth/login" `
    -Method Post -Body $json -ContentType "application/json"
```

**Probar Register**:

```powershell
$json = @{
    FirebaseUid = "register-uid-$(Get-Random)"
    Email = "23041234@alumno.utmetropolitana.edu.mx"
    Nombre = "Juan"
    ApellidoPaterno = "Perez"
    ApellidoMaterno = "Lopez"
    Rol = "Alumno"
    GrupoId = "5A"
    CarreraId = "dsm"
    Matricula = "23041234"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/auth/register" `
    -Method Post -Body $json -ContentType "application/json"
```

### Desde la App Flutter:

**Para Registro**:

1. Usa un email que **NO** exista en Firebase Auth
2. Formato según rol:
   - Alumno: `23041234@alumno.utmetropolitana.edu.mx`
   - Docente: `profesor.nombre@utmetropolitana.edu.mx`
   - Invitado: `cualquier@gmail.com`
3. Contraseña mínimo 6 caracteres
4. Completa todos los campos requeridos según el rol

**Para Login**:

1. Primero debes haberte registrado con ese email
2. Usar la misma contraseña que usaste en el registro
3. Si falla, revisa los logs de la app con:
   ```bash
   flutter logs
   ```

## 🔍 Debugging Avanzado

### Verificar estado de Firebase:

```dart
// En cualquier parte de tu código Flutter:
print('Firebase initialized: ${Firebase.apps.isNotEmpty}');
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

### Ver logs completos de Flutter:

```bash
# Terminal 1: Correr app
flutter run

# Terminal 2: Ver logs
flutter logs
```

### Ver logs del backend en tiempo real:

```bash
cd C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API
Get-Content -Tail 50 -Wait backend_v2.log
```

## 📊 Estado Actual de Conexiones

✅ **Backend → Firestore**: Conectado (credenciales corregidas)
✅ **Backend → Supabase**: Conectado (URL y ServiceKey configurados)
✅ **Backend → Firebase Storage**: Conectado (via admin SDK)
✅ **Backend API Health**: Funcionando (`/api/health` responde)
✅ **Backend Auth Endpoints**: Funcionando (`/api/auth/login` y `/api/auth/register`)

⚠️ **Flutter → Backend**: Requiere configurar IP correcta según dispositivo
⚠️ **Flutter → Firebase Auth**: Requiere permisos de internet (ya agregados)

## 🚀 Pasos para Probar la Aplicación

1. **Iniciar Backend**:

   ```bash
   cd C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API
   dotnet run
   ```

2. **Configurar IP en Flutter** (si usas emulador):
   - Editar `lib/src/core/config/app_config.dart`
   - Cambiar `192.168.1.216` por `10.0.2.2`

3. **Ejecutar App**:

   ```bash
   cd C:\Users\fitch\source\visual\Bifrost\biofrost_aplication_movil
   flutter run
   ```

4. **Registrar usuario de prueba**:
   - Email: `23041999@alumno.utmetropolitana.edu.mx`
   - Contraseña: `Test123456`
   - Rellenar campos requeridos

5. **Verificar logs**:
   - Flutter: Ver consola donde corriste `flutter run`
   - Backend: `Get-Content -Tail 50 backend_v2.log`

## 📝 Notas Importantes

1. **Roles detectados automáticamente**:
   - `@alumno.utmetropolitana.edu.mx` → Alumno
   - `@utmetropolitana.edu.mx` → Docente
   - Otros dominios → Invitado

2. **Flujo de autenticación correcto**:

   ```
   REGISTRO:
   Flutter → Firebase Auth (crear cuenta)
          → Backend API (sincronizar perfil)
          → Firestore (persistir datos)

   LOGIN:
   Flutter → Firebase Auth (autenticar)
          → Backend API (obtener perfil)
          → Local Storage (cachear sesión)
   ```

3. **Estructura de la base de datos**:
   - **Firebase/Firestore**: Datos de usuarios, proyectos, grupos, evaluaciones
   - **Supabase**: Almacenamiento de archivos (documentos, imágenes)
   - **Firebase Auth**: Autenticación y gestión de sesiones

## 🔐 Credenciales y Configuración

### Firebase

- **Project ID**: `integradorhub-dsm`
- **Auth Domain**: `integradorhub-dsm.firebaseapp.com`
- **Credentials**: `integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json`

### Supabase

- **URL**: `https://zhnufraaybrruqdtgbwj.supabase.co`
- **Bucket**: `project-files`

### Backend

- **URL Local**: `http://192.168.1.216:5093`
- **Swagger**: `http://192.168.1.216:5093/swagger`
- **Health Check**: `http://192.168.1.216:5093/api/health`

---

**Última actualización**: 19 de febrero de 2026
**Estado**: Backend funcionando ✅ | Flutter requiere pruebas con configuración correcta ⚠️
