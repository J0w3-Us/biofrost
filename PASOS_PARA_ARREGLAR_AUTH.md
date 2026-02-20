# 🔧 Pasos para Arreglar Errores de Autenticación

## ✅ Estado Actual del Sistema

✔️ **Backend funcionando correctamente**  
✔️ **Firebase/Firestore Backend conectado**  
✔️ **Supabase configurado**  
✔️ **API respondiendo en puerto 5093**

❌ **PROBLEMA IDENTIFICADO:** `google-services.json` tiene valores PLACEHOLDER

---

## 🎯 Solución: 3 Pasos Simples

### **Paso 1: Descargar google-services.json Real desde Firebase Console**

1. Abre tu navegador y ve a: **https://console.firebase.google.com**

2. Inicia sesión con la cuenta que tiene acceso al proyecto **integradorhub-dsm**

3. Selecciona el proyecto **integradorhub-dsm**

4. Haz clic en el **ícono de engranaje (⚙️)** en la esquina superior izquierda

5. Selecciona **"Configuración del proyecto"** / **"Project Settings"**

6. Ve a la pestaña **"General"**

7. Busca la sección **"Tus aplicaciones"** / **"Your apps"**

8. **¿Tu app Android ya está registrada?**
   - **SÍ:** Haz clic en el botón **"Descargar google-services.json"**
   - **NO:** Debes registrar tu app primero:
     - Haz clic en el ícono de Android
     - Nombre del paquete: `com.example.biofrost_aplication_movil`
     - Apodo de la app (opcional): `Bifrost Mobile`
     - Haz clic en **"Registrar app"**
     - Descarga el archivo **google-services.json**

9. **Reemplaza** el archivo en tu proyecto:
   ```
   Bifrost\biofrost_aplication_movil\android\app\google-services.json
   ```

---

### **Paso 2: Configurar Firewall (Ejecutar como Administrador)**

Para que tu dispositivo móvil pueda conectarse al backend en tu PC:

1. Abre PowerShell **como Administrador**:
   - Click derecho en el botón de Windows
   - Selecciona **"Terminal (Admin)"** o **"PowerShell (Admin)"**

2. Navega al directorio Bifrost:

   ```powershell
   cd C:\Users\fitch\source\visual\Bifrost
   ```

3. Ejecuta el script de configuración:
   ```powershell
   .\configurar_firewall.ps1
   ```

---

### **Paso 3: Ejecutar la App con la Configuración Correcta**

#### **Opción A: Para Emulador Android**

```powershell
cd biofrost_aplication_movil
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5093
```

#### **Opción B: Para Dispositivo Físico (Por USB o WiFi)**

```powershell
cd biofrost_aplication_movil
flutter run --dart-define=API_BASE_URL=http://192.168.1.216:5093
```

#### **Opción C: Usar el Script Automático**

```powershell
cd C:\Users\fitch\source\visual\Bifrost

# Para emulador:
.\run-flutter.ps1 -Tipo emulador

# Para dispositivo físico:
.\run-flutter.ps1 -Tipo dispositivo
```

---

## 🧪 Verificar que Todo Funciona

### **1. Verificar que el Backend está corriendo:**

```powershell
cd C:\Users\fitch\source\visual\Bifrost
.\diagnostico.ps1
```

Deberías ver:

```
✓ Backend está corriendo
✓ Health endpoint responde: ok
✓ Credenciales Firebase encontradas
✓ Firestore conexión verificada
✓ google-services.json encontrado
✓ Supabase configurado
```

### **2. Verificar conectividad desde tu móvil:**

- Abre **Chrome** en tu teléfono
- Navega a: `http://192.168.1.216:5093/api/health`
- Deberías ver: `{"status":"ok","timestamp":"..."}`

Si NO puedes acceder:

- ✔️ Verifica que tu móvil y PC estén en la **misma red WiFi**
- ✔️ Desactiva temporalmente el firewall de Windows para probar
- ✔️ Verifica que CloudflareWARP no esté bloqueando la conexión

---

## 📱 Probar Login y Registro

Una vez completados los 3 pasos:

1. **Abre la app Bifrost** en tu dispositivo/emulador

2. **Haz clic en "Registrarse con Google"** o **"Iniciar Sesión"**

3. **Deberías ver:**
   - Ventana de autenticación de Google
   - Login exitoso
   - Pantalla de bienvenida

4. **Si funciona:**
   - ✅ Firebase Auth está conectado correctamente
   - ✅ Backend recibe la autenticación
   - ✅ Usuario se guarda en Firestore
   - ✅ Supabase Storage está listo para archivos

---

## 🔍 Solución de Problemas

### **Error: "Cuenta ya existe" con cuenta inventada**

**Causa:** El archivo `google-services.json` tiene valores placeholder  
**Solución:** Completar Paso 1 - descargar archivo real de Firebase Console

### **Error: "Error de conexión" al iniciar sesión**

**Opción 1:** Backend no está corriendo

```powershell
cd IntegradorHub\backend\src\IntegradorHub.API
dotnet run
```

**Opción 2:** IP incorrecta

- Emulador debe usar: `10.0.2.2:5093`
- Dispositivo debe usar: `192.168.1.216:5093`

**Opción 3:** Firewall bloqueando puerto 5093

- Ejecutar `.\configurar_firewall.ps1` como Administrador

### **Error: "Firebase Auth Failed"**

**Causa:** `google-services.json` no coincide con Firebase Console  
**Solución:**

1. Verificar que el package name sea `com.example.biofrost_aplication_movil`
2. Verificar que la app esté registrada en Firebase Console
3. Descargar nuevo `google-services.json`

---

## 📋 Checklist Final

Antes de contactar soporte, verifica:

- [ ] Backend corriendo (puerto 5093)
- [ ] `google-services.json` descargado de Firebase Console (no placeholder)
- [ ] Firewall configurado (regla para puerto 5093)
- [ ] App corriendo con IP correcta (10.0.2.2 o 192.168.1.216)
- [ ] Móvil en misma red WiFi que PC (para dispositivo físico)
- [ ] `http://192.168.1.216:5093/api/health` responde desde navegador del móvil

---

## 📚 Documentación Técnica Completa

Para más detalles sobre la arquitectura y configuración:

- `docs\SOLUCION_CONEXIONES_FIREBASE_SUPABASE.md` - Guía técnica detallada
- `docs\BIFROST_PROJECT_CONFIG.md` - Configuración general del proyecto

---

**¿Sigues teniendo problemas?** Ejecuta `.\diagnostico.ps1` y comparte el output completo.
