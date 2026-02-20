# Script de Diagnóstico Bifrost
# Verifica el estado de todas las conexiones y servicios

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BIFROST - Script de Diagnóstico v2" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$problemas = @()

# 1. Verificar Backend
Write-Host "[1/7] Verificando Backend..." -ForegroundColor Yellow
$backendProcess = Get-Process | Where-Object { $_.ProcessName -like '*IntegradorHub*' }
if ($backendProcess) {
    Write-Host "  ✓ Backend está corriendo (PID: $($backendProcess.Id))" -ForegroundColor Green
    
    # Probar health endpoint
    try {
        $health = Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/health" -Method Get -TimeoutSec 5
        Write-Host "  ✓ Health endpoint responde: $($health.status)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Health endpoint no responde" -ForegroundColor Red
        $problemas += "Backend no responde en el puerto 5093"
    }
} else {
    Write-Host "  ✗ Backend NO está corriendo" -ForegroundColor Red
    $problemas += "Backend no está ejecutándose"
    Write-Host "    Para iniciar: cd IntegradorHub\backend\src\IntegradorHub.API; dotnet run" -ForegroundColor Yellow
}

# 2. Verificar Credenciales Firebase (Backend)
Write-Host "`n[2/7] Verificando Credenciales Firebase (Backend)..." -ForegroundColor Yellow
$firebaseCreds = "C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API\integradorhub-dsm-firebase-adminsdk-fbsvc-d89dd8625c.json"
if (Test-Path $firebaseCreds) {
    Write-Host "  ✓ Credenciales Firebase encontradas" -ForegroundColor Green
    $credsSize = (Get-Item $firebaseCreds).Length
    Write-Host "    Tamaño: $credsSize bytes" -ForegroundColor Gray
    
    # Probar endpoint que usa Firestore
    try {
        $testJson = @{
            FirebaseUid = "diag-test-$(Get-Random)"
            Email = "diagnostic@test.com"
            DisplayName = "Diagnostic"
        } | ConvertTo-Json
        
        $result = Invoke-RestMethod -Uri "http://192.168.1.216:5093/api/auth/login" -Method Post -Body $testJson -ContentType "application/json" -TimeoutSec 5
        Write-Host "  ✓ Firestore conexión verificada" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Firestore no responde correctamente" -ForegroundColor Red
        $problemas += "Firestore no conectado"
    }
} else {
    Write-Host "  ✗ Credenciales Firebase NO encontradas" -ForegroundColor Red
    $problemas += "Credenciales Firebase faltantes"
}

# 3. Verificar google-services.json (Flutter)
Write-Host "`n[3/7] Verificando google-services.json (Flutter)..." -ForegroundColor Yellow
$googleServices = "C:\Users\fitch\source\visual\Bifrost\biofrost_aplication_movil\android\app\google-services.json"
if (Test-Path $googleServices) {
    Write-Host "  ✓ google-services.json encontrado" -ForegroundColor Green
    $json = Get-Content $googleServices | ConvertFrom-Json
    Write-Host "    Project ID: $($json.project_info.project_id)" -ForegroundColor Gray
    
    # Verificar si es placeholder
    $appId = $json.client[0].client_info.mobilesdk_app_id
    if ($appId -like "*a1b2c3d4e5f60000*") {
        Write-Host "  ⚠️  ADVERTENCIA: Contiene valores PLACEHOLDER" -ForegroundColor Yellow
        Write-Host "    App ID: $appId" -ForegroundColor Yellow
        $problemas += "google-services.json tiene valores placeholder (no real)"
    } else {
        Write-Host "    App ID: $appId" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✗ google-services.json NO encontrado" -ForegroundColor Red
    $problemas += "google-services.json faltante"
}

# 4. Verificar Configuración Supabase
Write-Host "`n[4/7] Verificando Configuración Supabase..." -ForegroundColor Yellow
$appsettings = "C:\Users\fitch\source\visual\Bifrost\IntegradorHub\backend\src\IntegradorHub.API\appsettings.json"
if (Test-Path $appsettings) {
    $config = Get-Content $appsettings | ConvertFrom-Json
    if ($config.Supabase.Url -and $config.Supabase.ServiceKey) {
        Write-Host "  ✓ Supabase configurado" -ForegroundColor Green
        Write-Host "    URL: $($config.Supabase.Url)" -ForegroundColor Gray
        Write-Host "    Bucket: $($config.Supabase.BucketName)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Supabase NO configurado correctamente" -ForegroundColor Red
        $problemas += "Supabase sin configuración"
    }
} else {
    Write-Host "  ✗ appsettings.json NO encontrado" -ForegroundColor Red
}

# 5. Verificar Puertos
Write-Host "`n[5/7] Verificando Puertos..." -ForegroundColor Yellow
$port5093 = Get-NetTCPConnection -LocalPort 5093 -ErrorAction SilentlyContinue
if ($port5093) {
    Write-Host "  ✓ Puerto 5093 está en uso (Backend escuchando)" -ForegroundColor Green
    Write-Host "    Estado: $($port5093.State)" -ForegroundColor Gray
} else {
    Write-Host "  ✗ Puerto 5093 NO está en uso" -ForegroundColor Red
    $problemas += "Puerto 5093 no está escuchando"
}

# 6. Verificar conectividad de red
Write-Host "`n[6/7] Verificando Conectividad de Red..." -ForegroundColor Yellow
$ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.IPAddress -notlike '169.254.*' }
Write-Host "  IPs locales disponibles:" -ForegroundColor Cyan
foreach ($ip in $ipConfig) {
    $ifName = $ip.InterfaceAlias
    if ($ifName -like '*Wi-Fi*') {
        Write-Host "    - $($ip.IPAddress) ($ifName) ← USAR ESTA PARA MÓVIL" -ForegroundColor Green
    } else {
        Write-Host "    - $($ip.IPAddress) ($ifName)" -ForegroundColor Gray
    }
}

# 7. Verificar Firewall
Write-Host "`n[7/7] Verificando Firewall..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "*Bifrost*" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "  ✓ Regla de firewall encontrada" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  No se encontró regla de firewall para Bifrost" -ForegroundColor Yellow
    Write-Host "    Si tienes problemas de conexión desde móvil, ejecuta:" -ForegroundColor Yellow
    Write-Host "    New-NetFirewallRule -DisplayName 'Bifrost Backend' -Direction Inbound -LocalPort 5093 -Protocol TCP -Action Allow" -ForegroundColor Cyan
}

# Resumen Final
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($problemas.Count -eq 0) {
    Write-Host "✓ Sistema configurado correctamente" -ForegroundColor Green
    Write-Host "`nConfiguraciones para Flutter:" -ForegroundColor Yellow
    Write-Host "  - Emulador Android: http://10.0.2.2:5093" -ForegroundColor Cyan
    Write-Host "  - Emulador iOS: http://127.0.0.1:5093" -ForegroundColor Cyan
    $wifiIP = ($ipConfig | Where-Object { $_.InterfaceAlias -like '*Wi-Fi*' } | Select-Object -First 1).IPAddress
    if ($wifiIP) {
        Write-Host "  - Dispositivo físico: http://${wifiIP}:5093" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ Se encontraron $($problemas.Count) problemas:" -ForegroundColor Red
    foreach ($problema in $problemas) {
        Write-Host "  • $problema" -ForegroundColor Yellow
    }
    
    Write-Host "`nConsulta la documentación:" -ForegroundColor Cyan
    Write-Host "  docs\SOLUCION_CONEXIONES_FIREBASE_SUPABASE.md" -ForegroundColor White
}

Write-Host "`n" -ForegroundColor Gray

