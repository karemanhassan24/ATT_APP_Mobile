$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "=== ATT App Mobile Setup ===" -ForegroundColor Cyan

Write-Host "`n[1/4] Installing npm packages..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "npm install failed. If you are on a corporate network, try:" -ForegroundColor Red
    Write-Host "  npm install --strict-ssl=false" -ForegroundColor Red
    Write-Host "Or push to Git and let Codemagic build in the cloud." -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/4] Adding Android platform..." -ForegroundColor Yellow
if (-not (Test-Path "android")) {
    npx cap add android
} else {
    Write-Host "android/ folder already exists, skipping cap add"
}

Write-Host "`n[3/4] Patching AndroidManifest (GPS + Internet)..." -ForegroundColor Yellow
& "$PSScriptRoot\patch-android-manifest.ps1"

Write-Host "`n[4/4] Syncing Capacitor..." -ForegroundColor Yellow
npx cap sync android

Write-Host "`n=== Setup complete ===" -ForegroundColor Green
Write-Host "Open in Android Studio: npx cap open android"
Write-Host "Or push to Git and build on Codemagic."
