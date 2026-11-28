<#
.SYNOPSIS
Build optimized Android release APKs and preserve their Dart symbols.
.EXAMPLE
.\build-apk.ps1
.EXAMPLE
.\build-apk.ps1 -ApiBaseUrl https://api.example.com/api
#>
[CmdletBinding()]
param(
    [string]$ApiBaseUrl
)

$ErrorActionPreference = 'Stop'
$flutterCommand = Get-Command flutter -ErrorAction Stop

# A unique directory keeps symbols from different releases from being overwritten.
$buildId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
$symbolsDirectory = Join-Path $PSScriptRoot "build/symbols/$buildId"
$flutterArguments = @(
    'build', 'apk', '--release', '--split-per-abi', '--tree-shake-icons',
    "--split-debug-info=$symbolsDirectory"
)
$apkNames = @(
    'app-armeabi-v7a-release.apk',
    'app-arm64-v8a-release.apk',
    'app-x86_64-release.apk'
)

if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $flutterArguments += "--dart-define=API_BASE_URL=$ApiBaseUrl"
}

Push-Location -LiteralPath $PSScriptRoot
try {
    New-Item -ItemType Directory -Path $symbolsDirectory -Force | Out-Null
    & $flutterCommand.Source @flutterArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter APK build failed with exit code $LASTEXITCODE."
    }

    Write-Host ''
    Write-Host 'Release APKs:'
    foreach ($apkName in $apkNames) {
        $apkPath = Join-Path $PSScriptRoot "build/app/outputs/flutter-apk/$apkName"
        $apk = Get-Item -LiteralPath $apkPath -ErrorAction Stop
        Write-Host ('{0} ({1:N2} MiB)' -f $apk.FullName, ($apk.Length / 1MB))
    }
    Write-Host "Dart symbols: $symbolsDirectory"
    Write-Host 'Keep these symbols with this release to decode crash stack traces.'
} finally {
    Pop-Location
}
