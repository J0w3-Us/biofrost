# Script de Ayuda para Ejecutar Bifrost Flutter
# Facilita la ejecución con diferentes configuraciones de red

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("emulador", "dispositivo", "wifi", "custom")]
    [string]$Tipo = "emulador",
    
    [Parameter(Mandatory=$false)]
    [string]$CustomIP
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BIFROST - Flutter Runner" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$projectPath = "C:\Users\fitch\source\visual\Bifrost\biofrost_aplication_movil"

# Determinar URL del backend
$apiUrl = switch ($Tipo) {
    "emulador" {
        "http://10.0.2.2:5093"
    }
    "dispositivo" {
        # Obtener IP WiFi automáticamente
        $wifiIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Wi-Fi*' }).IPAddress
        if ($wifiIP) {
            "http://${wifiIP}:5093"
        } else {
            "http://192.168.1.216:5093"
        }
    }
    "wifi" {
        "http://192.168.1.216:5093"
    }
    "custom" {
        if ($CustomIP) {
            "http://${CustomIP}:5093"
        } else {
            Write-Host "Error: Debes especificar -CustomIP cuando usas -Tipo custom" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "Configuración seleccionada:" -ForegroundColor Yellow
Write-Host "  Tipo: $Tipo" -ForegroundColor Cyan
Write-Host "  API URL: $apiUrl" -ForegroundColor Cyan

# Verificar que el backend está activo
Write-Host "`nVerificando backend..." -ForegroundColor Yellow
try {
    # Para emulador, verificar con la IP real
    $checkUrl = if ($Tipo -eq "emulador") { "http://192.168.1.216:5093/api/health" } else { "$apiUrl/api/health" }
    $health = Invoke-RestMethod -Uri $checkUrl -Method Get -TimeoutSec 3
    Write-Host "  ✓ Backend está activo ($($health.status))" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Backend NO responde" -ForegroundColor Red
    Write-Host "    Para iniciar: cd IntegradorHub\backend\src\IntegradorHub.API; dotnet run" -ForegroundColor Yellow
    $continue = Read-Host "`n¿Deseas continuar de todas formas? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        exit 1
    }
}

# Cambiar al directorio del proyecto
Set-Location $projectPath

# Limpiar build anterior
Write-Host "`nLimpiando build anterior..." -ForegroundColor Yellow
flutter clean | Out-Null

# Obtener dependencias
Write-Host "Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get | Out-Null

# Construir comandos
Write-Host "`nIniciando Flutter..." -ForegroundColor Yellow
Write-Host "Comando: flutter run --dart-define=API_BASE_URL=$apiUrl`n" -ForegroundColor Gray

# Ejecutar Flutter con la configuración
flutter run --dart-define=API_BASE_URL=$apiUrl

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Ejecución finalizada" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
