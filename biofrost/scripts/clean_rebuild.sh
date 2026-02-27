#!/bin/bash

# Script para limpiar completamente el proyecto Flutter y reconstruir
# Útil cuando hay problemas de certificados SSL o caché corrupto

echo "🧹 Limpiando proyecto Flutter y caché..."

# Limpiar Flutter
flutter clean

# Limpiar caché de Dart
dart pub cache clean

# Limpiar Gradle (Android)
cd android || exit 1
./gradlew clean
cd ..

# Reinstalar dependencias
echo "📦 Reinstalando dependencias..."
flutter pub get

# Reconstruir archivos generados
echo "🔨 Reconstruyendo archivos generados..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo "✅ Limpieza completa terminada"
echo "💡 Consejo: Si persisten problemas de SSL, verifica:"
echo "   • Conectividad del dispositivo/emulador"
echo "   • Fecha y hora del dispositivo correcta"
echo "   • Google Play Services instalado (emulador)"
echo "   • Proxy o firewall corporativo"