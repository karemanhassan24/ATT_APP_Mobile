$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PSScriptRoot "..\android\app\src\main\AndroidManifest.xml"

if (-not (Test-Path $manifestPath)) {
    Write-Error "AndroidManifest.xml not found. Run: npx cap add android"
}

$permissions = @(
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_NETWORK_STATE"
)

$content = Get-Content $manifestPath -Raw

foreach ($perm in $permissions) {
    if ($content -match [regex]::Escape($perm)) {
        Write-Host "Already present: $perm"
    } else {
        $line = "    <uses-permission android:name=`"$perm`" />"
        $content = $content -replace "(<application)", "$line`r`n`$1"
        Write-Host "Added: $perm"
    }
}

if ($content -notmatch 'android:usesCleartextTraffic') {
    $content = $content -replace '<application ', '<application android:usesCleartextTraffic="true" '
    Write-Host "Enabled usesCleartextTraffic"
}

Set-Content -Path $manifestPath -Value $content -NoNewline
Write-Host "AndroidManifest.xml patched successfully"
