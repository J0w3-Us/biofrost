# Script para Configurar Firewall para Bifrost Backend
# EJECUTAR COMO ADMINISTRADOR

Write-Host "Configurando Firewall para Bifrost Backend..." -ForegroundColor Cyan

# Verificar si ya existe la regla
$existingRule = Get-NetFirewallRule -DisplayName "Bifrost Backend" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "✓ La regla de firewall ya existe" -ForegroundColor Green
    Write-Host "  Estado: $($existingRule.Enabled)" -ForegroundColor Gray
} else {
    try {
        New-NetFirewallRule -DisplayName 'Bifrost Backend' -Direction Inbound -LocalPort 5093 -Protocol TCP -Action Allow | Out-Null
        Write-Host "✓ Regla de firewall creada exitosamente" -ForegroundColor Green
        Write-Host "  Puerto 5093 ahora es accesible desde otros dispositivos" -ForegroundColor Gray
    } catch {
        Write-Host "✗ Error al crear regla de firewall: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nAsegúrate de ejecutar este script como Administrador:" -ForegroundColor Yellow
        Write-Host "  1. Click derecho en PowerShell" -ForegroundColor Cyan
        Write-Host "  2. Selecciona 'Ejecutar como Administrador'" -ForegroundColor Cyan
        Write-Host "  3. Ejecuta: .\configurar_firewall.ps1" -ForegroundColor Cyan
    }
}

Write-Host "`nPresiona cualquier tecla para continuar..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
