$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PSScriptRoot "..\android\app\src\main\AndroidManifest.xml"

if (-not (Test-Path $manifestPath)) {
    Write-Error "AndroidManifest.xml not found. Run: npx cap add android"
}

$permissions = @(
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.VIBRATE"
)

$content = Get-Content $manifestPath -Raw

foreach ($perm in $permissions) {
    if ($content -match [regex]::Escape($perm)) {
        Write-Host "Already present: $perm"
    } else {
        $line = "    <uses-permission android:name=`"$perm`" />"
        if ($content -match "<application") {
            $content = $content -replace "(<application)", "$line`r`n`$1"
            Write-Host "Added: $perm"
        } else {
            Write-Error "No <application tag found in AndroidManifest.xml"
        }
    }
}

if ($content -notmatch "android\.hardware\.location\.gps") {
    $feature = '    <uses-feature android:name="android.hardware.location.gps" android:required="false" />'
    $content = $content -replace "(<application)", "$feature`r`n`$1"
    Write-Host "Added GPS hardware feature"
}

if ($content -notmatch 'android:usesCleartextTraffic') {
    $content = $content -replace '<application ', '<application android:usesCleartextTraffic="true" '
    Write-Host "Enabled usesCleartextTraffic"
}

foreach ($required in @("ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION")) {
    if ($content -notmatch "android\.permission\.$required") {
        Write-Error "FAILED: missing $required in AndroidManifest.xml"
    }
}

Set-Content -Path $manifestPath -Value $content -NoNewline
Write-Host "AndroidManifest.xml patched and verified successfully"
