# Script para diagnosticar problemas SSL/certificados en Firebase
# Ejecuta este script si ves errores como "Trust anchor for certification path not found"

Write-Host "🔍 Diagnóstico SSL/Firebase para Android" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Verificar conexión básica
Write-Host "`n1. Verificando conectividad básica..." -ForegroundColor Yellow
try {
    $ping = Test-Connection -ComputerName "firebase.googleapis.com" -Count 2 -Quiet
    if ($ping) {
        Write-Host "   ✓ Conectividad a Firebase OK" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No hay conectividad a Firebase" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠️ Error verificando conectividad: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Verificar emulador/dispositivo
Write-Host "`n2. Verificando configuración del emulador/dispositivo..." -ForegroundColor Yellow
try {
    $adbDevices = & adb devices
    $connectedDevices = ($adbDevices | Select-String "device$").Count
    
    if ($connectedDevices -gt 0) {
        Write-Host "   ✓ Dispositivo/emulador conectado" -ForegroundColor Green
        
        # Verificar si es emulador y si tiene Google Play
        $emulators = & adb devices | Select-String "emulator"
        if ($emulators) {
            Write-Host "   📱 Usando emulador - asegúrate de que tenga Google Play Services" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   ❌ No hay dispositivos conectados" -ForegroundColor Red
    }
} catch {
    Write-Host "   ⚠️ Error verificando dispositivos: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Verificar fecha/hora del dispositivo
Write-Host "`n3. Verificando fecha/hora del dispositivo..." -ForegroundColor Yellow
try {
    $deviceDate = & adb shell date 2>$null
    if ($deviceDate) {
        Write-Host "   📅 Fecha del dispositivo: $deviceDate" -ForegroundColor Green
        Write-Host "   💡 Asegúrate de que la fecha/hora sea correcta (SSL es sensible a esto)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️ No se pudo verificar fecha del dispositivo" -ForegroundColor Yellow
}

# 4. Pasos de resolución
Write-Host "`n🔧 PASOS PARA RESOLVER PROBLEMAS SSL:" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

Write-Host "`n1. VERIFICA EL EMULADOR:" -ForegroundColor White
Write-Host "   • Usa un emulador con Google Play Store (no el básico)" -ForegroundColor White
Write-Host "   • API nivel 28+ recomendado" -ForegroundColor White
Write-Host "   • Reinicia el emulador si es necesario" -ForegroundColor White

Write-Host "`n2. CONFIGURA RED:" -ForegroundColor White
Write-Host "   • Si usas proxy corporativo, configura excepciones para:" -ForegroundColor White
Write-Host "     - *.googleapis.com" -ForegroundColor Gray
Write-Host "     - *.google.com" -ForegroundColor Gray
Write-Host "     - *.gstatic.com" -ForegroundColor Gray
Write-Host "   • Prueba con red móvil si WiFi corporativo bloquea" -ForegroundColor White

Write-Host "`n3. LIMPIA Y RECONSTRUYE:" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter run --verbose" -ForegroundColor Gray

Write-Host "`n4. SI PERSISTE EL ERROR:" -ForegroundColor White
Write-Host "   • App Check está deshabilitado temporalmente en main.dart" -ForegroundColor White
Write-Host "   • Esto permite desarrollo sin SSL estricto" -ForegroundColor White
Write-Host "   • Habilítalo cuando resuelvas los certificados" -ForegroundColor White

Write-Host "`n5. PARA PRODUCCIÓN:" -ForegroundColor White
Write-Host "   • Usa dispositivos reales con Google Play Services" -ForegroundColor White
Write-Host "   • Habilita App Check con el proveedor correcto" -ForegroundColor White
Write-Host "   • Configura SafetyNet o Play Integrity" -ForegroundColor White

Write-Host "`n🚀 Ejecuta ahora:" -ForegroundColor Cyan
Write-Host "flutter run --verbose" -ForegroundColor Yellow
Write-Host "`nBusca en los logs:" -ForegroundColor Cyan
Write-Host "• '✓ Firebase Core initialized successfully'" -ForegroundColor Green
Write-Host "• '⚠️ App Check DISABLED for SSL troubleshooting'" -ForegroundColor Yellow