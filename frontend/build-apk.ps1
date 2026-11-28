<# Build one signed APK for sharing. The API must already be reachable over HTTPS. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ApiBaseUrl,
    [switch]$EnableFcm,
    [switch]$AllowBasicOcr,
    [switch]$SplitPerAbi
)
$ErrorActionPreference = 'Stop'
$flutter = (Get-Command flutter -ErrorAction Stop).Source
$uri = $null
if (-not [Uri]::TryCreate($ApiBaseUrl.Trim(), [UriKind]::Absolute, [ref]$uri) -or
    $uri.Scheme -ne 'https' -or $uri.HostNameType -ne [UriHostNameType]::Dns -or
    $uri.Host -notmatch '^[a-z0-9][a-z0-9.-]*\.[a-z0-9]+$' -or
    $uri.Host -match '\.(localhost|local|test|invalid|example)$' -or
    $uri.AbsolutePath.TrimEnd('/') -ne '/api' -or $uri.Query -or $uri.Fragment -or $uri.UserInfo) {
    throw 'Provide a publicly reachable HTTPS URL ending in /api (not localhost or an emulator IP).'
}
$ApiBaseUrl = $uri.AbsoluteUri.TrimEnd('/')
$ready = Invoke-RestMethod -Uri "$ApiBaseUrl/ready" -TimeoutSec 35 -MaximumRedirection 0
if ($ready.service -ne 'SplitDebt' -or $ready.database -ne $true) { throw 'Backend or database is not ready.' }
if (-not $AllowBasicOcr -and ($ready.ocr -ne $true -or $ready.structure -ne $true)) {
    throw 'OCR models are not warmed up. Run warmup.cmd (or server warmup.py). Use -AllowBasicOcr only for a basic OCR demo.'
}
$signingPath = Join-Path $PSScriptRoot 'android/key.properties'
if (-not (Test-Path -LiteralPath $signingPath)) { throw 'Missing android/key.properties. Follow the release signing instructions.' }
$assetPath = Join-Path $PSScriptRoot 'assets/client.env'
$original = [IO.File]::ReadAllBytes($assetPath)
$publicLines = @('FIREBASE_ENABLED=false')
if ($EnableFcm) {
    $source = Join-Path $PSScriptRoot '.env'
    if (-not (Test-Path -LiteralPath $source)) { throw 'Missing frontend/.env with Android Firebase client configuration.' }
    $allowed = @('API_KEY','APP_ID','MESSAGING_SENDER_ID','PROJECT_ID','STORAGE_BUCKET')
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $source) {
        if ($line -match '^\s*FIREBASE_ANDROID_([A-Z_]+)\s*=\s*(.*?)\s*$' -and $allowed -contains $Matches[1]) {
            $name = $Matches[1]; $value = $Matches[2].Trim().Trim('"').Trim("'")
            if ($value -notmatch '^[A-Za-z0-9_.:/-]+$' -or $value -match '^YOUR_') { throw "Invalid public Firebase client value: $name" }
            $values[$name] = $value
        }
    }
    foreach ($name in @('API_KEY','APP_ID','MESSAGING_SENDER_ID','PROJECT_ID')) {
        if (-not $values.ContainsKey($name)) { throw "Missing FIREBASE_ANDROID_$name" }
    }
    $publicLines = @('FIREBASE_ENABLED=true') + @($values.Keys | Sort-Object | ForEach-Object { "FIREBASE_ANDROID_$_=$($values[$_])" })
}
$id = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path (Split-Path $PSScriptRoot -Parent) "release-output/$id"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$publicText = ($publicLines -join "`n") + "`n"
Push-Location -LiteralPath $PSScriptRoot
try {
    [IO.File]::WriteAllText($assetPath, $publicText, $utf8)
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    & $flutter analyze --no-fatal-infos --no-fatal-warnings
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analyzer errors must be fixed.' }
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
    $arguments = @('build','apk','--release',"--dart-define=API_BASE_URL=$ApiBaseUrl", "--split-debug-info=$out/symbols")
    $names = @('app-release.apk')
    if ($SplitPerAbi) { $arguments += '--split-per-abi'; $names = @('app-armeabi-v7a-release.apk','app-arm64-v8a-release.apk','app-x86_64-release.apk') }
    New-Item -ItemType Directory -Path $out -Force | Out-Null
    & $flutter @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Flutter release build failed.' }
    # Verify Android signature rather than relying only on Gradle exit status.
    $sdk = $env:ANDROID_SDK_ROOT
    if (-not $sdk) { $sdk = $env:ANDROID_HOME }
    if (-not $sdk -and (Test-Path 'android/local.properties')) {
        $sdkLine = Get-Content 'android/local.properties' | Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
        if ($sdkLine) { $sdk = ($sdkLine -replace '^sdk\.dir=', '').Replace('\:', ':').Replace('\\', '\') }
    }
    if (-not $sdk) { throw 'Android SDK location unknown. Set ANDROID_HOME.' }
    $signer = Get-ChildItem -LiteralPath (Join-Path $sdk 'build-tools') -Filter apksigner.bat -Recurse -File | Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $signer) { throw 'Android Build Tools apksigner.bat is missing.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    foreach ($name in $names) {
        $apk = Join-Path $PSScriptRoot "build/app/outputs/flutter-apk/$name"
        & $signer.FullName verify --print-certs $apk
        if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed.' }
        $archive = [IO.Compression.ZipFile]::OpenRead($apk)
        try {
            if ($archive.GetEntry('assets/flutter_assets/.env')) { throw 'Unsafe private .env found in APK.' }
            $entry = $archive.GetEntry('assets/flutter_assets/assets/client.env')
            if (-not $entry) { throw 'Missing public configuration asset.' }
            $reader = New-Object IO.StreamReader($entry.Open())
            try { if ($reader.ReadToEnd() -ne $publicText) { throw 'Unexpected configuration asset in APK.' } } finally { $reader.Dispose() }
        } finally { $archive.Dispose() }
        $destination = Join-Path $out $name
        Copy-Item -LiteralPath $apk -Destination $destination
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
        "$hash  $name" | Add-Content -LiteralPath (Join-Path $out 'SHA256SUMS.txt') -Encoding ascii
        Write-Host "APK: $destination"
    }
    Write-Host 'Test on a real Android phone using mobile data before sharing.'
} finally {
    [IO.File]::WriteAllBytes($assetPath, $original)
    Pop-Location
}
