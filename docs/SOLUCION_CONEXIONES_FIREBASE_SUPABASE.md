# 🔥 CORRECCIÓN URGENTE: Firebase y Supabase Conexiones

## ✅ PROBLEMA RESUELTO - Backend

### ✓ Firebase/Firestore - Backend **FUNCIONANDO**

**Estado**: ✅ **CONECTADO**

Los logs confirman:

```
[INFO] Firebase credentials configured: C:\Users\fitch\...\integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json
[INFO] FirestoreContext: Initializing Firestore with project ID: integradorhub-dsm
[SUCCESS] FirestoreContext: Firestore initialized successfully
```

**Cambios aplicados**:

1. ✅ Credenciales configuradas en `Program.cs` al inicio de la aplicación
2. ✅ `FirestoreContext.cs` simplificado para usar variable de entorno
3. ✅ Logs de diagnóstico agregados
4. ✅ Endpoint `/api/auth/login` probado exitosamente

### ✓ Supabase Storage - Backend **CONFIGURADO**

**Estado**: ✅ **LISTO**

Configuración verificada en `appsettings.json`:

- URL: `https://zhnufraaybrruqdtgbwj.supabase.co`
- Bucket: `project-files`
- ServiceKey: Configurado ✓

---

## ⚠️ PROBLEMA IDENTIFICADO - Flutter/Dispositivo Móvil

### ❌ Firebase Auth - Flutter **REQUIERE CORRECCIÓN**

**Problema detectado**: El archivo `google-services.json` contiene valores placeholder que no coinciden con el proyecto real de Firebase.

**Archivo actual**:

```json
{
  "client_info": {
    "mobilesdk_app_id": "1:1008422112612:android:a1b2c3d4e5f60000", // ❌ Placeholder
    "android_client_info": {
      "package_name": "com.example.biofrost_aplication_movil"
    }
  },
  "oauth_client": [
    {
      "client_id": "1008422112612-placeholder.apps.googleusercontent.com", // ❌ Placeholder
      "client_type": 3
    }
  ]
}
```

### 🔧 SOLUCIÓN: Obtener google-services.json Correcto

#### Opción 1: Desde Firebase Console (Recomendado)

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona el proyecto: **integradorhub-dsm**
3. Ve a **Project Settings** (⚙️ ícono de engranaje)
4. Scroll down a **Your apps**
5. Si ya existe una app Android:
   - Descarga el `google-services.json` actual
6. Si NO existe una app Android:
   - Click en **Add app** → **Android**
   - Package name: `com.example.biofrost_aplication_movil`
   - Descarga el `google-services.json`
7. Reemplaza el archivo en:
   ```
   biofrost_aplication_movil/android/app/google-services.json
   ```

#### Opción 2: Manual (Si tienes acceso admin)

Si tienes acceso al archivo correcto del proyecto actual, reemplázalo manualmente.

**Ubicación**: `biofrost_aplication_movil/android/app/google-services.json`

#### Verificar Package Name

El package name debe coincidir en ambos lados:

**En Firebase Console**:

- Ve a Project Settings → Your apps
- Debe mostrar: `com.example.biofrost_aplication_movil`

**En Flutter**:

- Archivo: `android/app/build.gradle`
- Busca: `applicationId "com.example.biofrost_aplication_movil"`

Si no coinciden, debes:

1. Cambiar el applicationId en Flutter para que coincida con Firebase
2. O crear una nueva app en Firebase con el applicationId correcto

### ❌ URL del Backend - Dispositivo Móvil

**Problema**: La IP `10.0.2.2` solo funciona para **emulador Android**.

**Para dispositivo físico**, necesitas usar la IP de tu PC en la red WiFi local.

**Configuración actual**:

```dart
// app_config.dart
defaultValue: 'http://10.0.2.2:5093',  // ❌ Solo emulador
```

**Opción 1: Cambiar manualmente** (para dispositivo físico):

```dart
defaultValue: 'http://192.168.1.216:5093',  // ✓ IP de tu PC
```

**Opción 2: Usar dart-define** (recomendado):

```bash
# Para dispositivo físico
flutter run --dart-define=API_BASE_URL=http://192.168.1.216:5093

# Para emulador
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5093
```

**Opción 3: Usar script de ayuda**:

```powershell
# Para dispositivo físico
.\run-flutter.ps1 -Tipo dispositivo

# Para emulador
.\run-flutter.ps1 -Tipo emulador
```

### 🔍 Verificar Conectividad desde Dispositivo

#### Desde Emulador:

```
http://10.0.2.2:5093/api/health
```

#### Desde Dispositivo Físico:

**Paso 1**: Asegúrate que ambos (PC y móvil) estén en la misma red WiFi.

**Paso 2**: Abre Chrome en el móvil y visita:

```
http://192.168.1.216:5093/api/health
```

**Debe devolver**:

```json
{ "status": "ok", "timestamp": "..." }
```

**Si NO funciona**:

- ✅ Verifica que el backend esté corriendo en tu PC
- ✅ Verifica que el firewall permita conexiones al puerto 5093:
  ```powershell
  # Ejecutar como Administrador
  New-NetFirewallRule -DisplayName "Bifrost Backend" -Direction Inbound -LocalPort 5093 -Protocol TCP -Action Allow
  ```
- ✅ Verifica la IP de tu PC:
  ```powershell
  ipconfig
  # Buscar IPv4 Address en la sección Wi-Fi
  ```

---

## 📝 CHECKLIST de Corrección

### Backend (✅ Completado)

- [x] Firebase credentials configuradas en Program.cs
- [x] FirestoreContext simplificado
- [x] Supabase configurado
- [x] Logs de diagnóstico agregados
- [x] Backend probado y funcionando

### Flutter (🔄 Requiere acción)

- [ ] **URGENTE**: Reemplazar `google-services.json` con el archivo correcto de Firebase Console
- [ ] Verificar package name coincide con Firebase
- [ ] Configurar URL correcta según dispositivo (emulador vs físico)
- [ ] Verificar permisos de internet en AndroidManifest (✅ ya agregados)
- [ ] Probar conectividad a `http://IP:5093/api/health` desde el dispositivo

---

## 🚀 Pasos para Probar

### 1. Obtener google-services.json Correcto

```bash
# Ruta donde colocar el archivo:
biofrost_aplication_movil/android/app/google-services.json
```

### 2. Verificar IP del Backend

```powershell
# Obtener tu IP
ipconfig

# Verificar backend está activo
Invoke-RestMethod -Uri "http://TU_IP:5093/api/health"
```

### 3. Configurar Flutter según dispositivo

**Para Emulador**:

```bash
cd biofrost_aplication_movil
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5093
```

**Para Dispositivo Físico**:

```bash
cd biofrost_aplication_movil
flutter run --dart-define=API_BASE_URL=http://192.168.1.216:5093  # Usa TU IP
```

### 4. Probar Registro

**Email de prueba**:

```
Alumno: 23040999@alumno.utmetropolitana.edu.mx
Password: Test123456
```

---

## 🐛 Errores Comunes y Soluciones

### Error: "FirebaseException: [core/duplicate-app]"

**Causa**: Firebase ya está inicializado
**Solución**: Ya está manejado en el código, ignorar warning

### Error: "SocketException: Failed host lookup"

**Causa**: No hay conexión al backend
**Solución**:

1. Verificar que backend esté corriendo
2. Verificar IP correcta
3. Verificar firewall

### Error: "FirebaseAuthException: [auth/invalid-api-key]"

**Causa**: google-services.json incorrecto o placeholder
**Solución**: Descargar archivo correcto de Firebase Console

### Error: "PlatformException(signin_failed)"

**Causa**: Firebase Auth no configurado correctamente
**Solución**:

1. Reemplazar google-services.json
2. Verificar SHA-1 fingerprint en Firebase Console

---

## 📊 Estado Actual

| Componente              | Estado                    | Acción Requerida                    |
| ----------------------- | ------------------------- | ----------------------------------- |
| Backend → Firestore     | ✅ Funcionando            | Ninguna                             |
| Backend → Supabase      | ✅ Configurado            | Ninguna                             |
| Backend API             | ✅ Activo                 | Ninguna                             |
| Flutter → Firebase Auth | ❌ Requiere corrección    | **Reemplazar google-services.json** |
| Flutter → Backend       | ⚠️ Depende de dispositivo | Configurar IP correcta              |

---

## 🔗 Recursos

- [Firebase Console](https://console.firebase.google.com)
- [Obtener SHA-1 para Firebase](https://developers.google.com/android/guides/client-auth)
- [Configurar Firebase para Flutter](https://firebase.google.com/docs/flutter/setup)

---

**Última actualización**: 19 de febrero de 2026 11:52 PM
**Estado**: Backend ✅ | Flutter ⚠️ (requiere google-services.json correcto)
