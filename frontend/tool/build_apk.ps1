param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"

if ($ApiBaseUrl -notmatch '^https://.+') {
    Write-Error "ApiBaseUrl phai bat dau bang https:// (nhan duoc: '$ApiBaseUrl')"
    exit 1
}

$FrontendDir = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $FrontendDir
try {
    $KeyPropsPath = Join-Path $FrontendDir "android\key.properties"
    $HasKeyProps = Test-Path $KeyPropsPath
    if (-not $HasKeyProps) {
        Write-Warning "Khong tim thay android/key.properties - ban release se duoc ky bang khoa debug!"
    }

    Write-Host "=== Building universal release APK ===" -ForegroundColor Cyan
    flutter build apk --release "--dart-define=API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Write-Host "=== Building split-per-abi release APKs ===" -ForegroundColor Cyan
    flutter build apk --release --split-per-abi "--dart-define=API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $ApkDir = Join-Path $FrontendDir "build\app\outputs\flutter-apk"
    $Apks = Get-ChildItem -Path $ApkDir -Filter "*.apk" | Sort-Object Name

    Write-Host ""
    Write-Host "=== Release APKs ===" -ForegroundColor Green
    foreach ($apk in $Apks) {
        $hash = (Get-FileHash -Path $apk.FullName -Algorithm SHA256).Hash
        $sizeMb = [Math]::Round($apk.Length / 1MB, 2)
        Write-Host ("{0} ({1} MB / {2} bytes)" -f $apk.FullName, $sizeMb, $apk.Length)
        Write-Host ("  SHA-256: {0}" -f $hash)
    }

    if (-not $HasKeyProps) {
        Write-Host ""
        Write-Warning "Chua co android/key.properties: cac APK tren duoc ky bang khoa debug, khong dung de phat hanh cap nhat de len nhau giua cac may."
    }
} finally {
    Pop-Location
}
