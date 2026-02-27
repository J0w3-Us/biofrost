# Script para limpiar completamente el proyecto Flutter y reconstruir
# Útil cuando hay problemas de certificados SSL o caché corrupto

Write-Host "🧹 Limpiando proyecto Flutter y caché..." -ForegroundColor Yellow

try {
    # Limpiar Flutter
    Write-Host "Ejecutando flutter clean..."
    flutter clean

    # Limpiar caché de Dart
    Write-Host "Limpiando caché de Dart..."
    dart pub cache clean

    # Limpiar Gradle (Android)
    Write-Host "Limpiando Gradle..."
    Set-Location android
    .\gradlew clean
    Set-Location ..

    # Reinstalar dependencias
    Write-Host "📦 Reinstalando dependencias..." -ForegroundColor Green
    flutter pub get

    # Reconstruir archivos generados
    Write-Host "🔨 Reconstruyendo archivos generados..." -ForegroundColor Blue
    flutter packages pub run build_runner build --delete-conflicting-outputs

    Write-Host "✅ Limpieza completa terminada" -ForegroundColor Green
    Write-Host "💡 Consejo: Si persisten problemas de SSL, verifica:" -ForegroundColor Cyan
    Write-Host "   • Conectividad del dispositivo/emulador"
    Write-Host "   • Fecha y hora del dispositivo correcta"  
    Write-Host "   • Google Play Services instalado (emulador)"
    Write-Host "   • Proxy o firewall corporativo"
}
catch {
    Write-Host "❌ Error durante la limpieza: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}