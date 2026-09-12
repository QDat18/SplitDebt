param(
  [switch]$Fast,
  [switch]$SkipAndroid,
  [switch]$SkipE2E
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Api = Join-Path $Root 'api'
$Frontend = Join-Path $Root 'frontend'
$Results = Join-Path $Root 'test-results'
New-Item -ItemType Directory -Force -Path $Results | Out-Null

function Section([string]$Title) {
  Write-Host "`n============================================================" -ForegroundColor Cyan
  Write-Host " $Title" -ForegroundColor Cyan
  Write-Host "============================================================" -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Không tìm thấy '$Name' trong PATH."
  }
}

$started = Get-Date
$backendProcess = $null
try {
  Section '0. Kiểm tra môi trường'
  Require-Command java
  Require-Command javac
  Require-Command flutter
  $PythonExe = $null
  $PythonArgs = @()
  if (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonExe = 'python'
  } elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonExe = 'py'
    $PythonArgs = @('-3')
  } else {
    throw "Không tìm thấy Python 3 ('python' hoặc 'py -3') trong PATH."
  }
  java -version
  flutter --version

  Section '1. LedgerMath invariant test (không cần Maven)'
  $classes = Join-Path $Results 'ledger-math-classes'
  Remove-Item -Recurse -Force $classes -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $classes | Out-Null
  & javac -d $classes `
    (Join-Path $Api 'src/main/java/com/splitdebt/api/ledger/LedgerMath.java') `
    (Join-Path $Api 'tools/LedgerMathCheck.java')
  if ($LASTEXITCODE -ne 0) { throw 'LedgerMath javac failed.' }
  & java -cp $classes com.splitdebt.api.ledger.LedgerMathCheck
  if ($LASTEXITCODE -ne 0) { throw 'LedgerMath invariant check failed.' }

  Section '2. Backend unit + integration tests + JaCoCo'
  Push-Location $Api
  try {
    & .\mvnw.cmd --batch-mode clean verify
    if ($LASTEXITCODE -ne 0) { throw 'Backend Maven tests failed.' }
  } finally { Pop-Location }

  Section '3. Flutter dependencies + static analysis'
  Push-Location $Frontend
  try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    & flutter analyze --no-fatal-infos
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed.' }

    Section '4. Flutter unit + widget tests + coverage'
    & flutter test --coverage
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }

    if (-not $Fast) {
      Section '5. Flutter Web build smoke test'
      & flutter build web --debug
      if ($LASTEXITCODE -ne 0) { throw 'Flutter Web build failed.' }

      if (-not $SkipAndroid) {
        Section '6. Android debug APK build smoke test'
        & flutter build apk --debug
        if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }
      }
    }
  } finally { Pop-Location }

  if (-not $SkipE2E) {
    Section '7. Khởi động Backend E2E riêng trên port 18080'
    $dataDir = Join-Path $Api 'data'
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
    Get-ChildItem $dataDir -Filter 'splitdebt-e2e*' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $stdout = Join-Path $Results 'backend-e2e.out.log'
    $stderr = Join-Path $Results 'backend-e2e.err.log'
    Remove-Item $stdout,$stderr -Force -ErrorAction SilentlyContinue

    $oldProfile = $env:SPRING_PROFILES_ACTIVE
    $env:SPRING_PROFILES_ACTIVE = 'e2e'
    try {
      $backendProcess = Start-Process -FilePath (Join-Path $Api 'mvnw.cmd') `
        -ArgumentList 'spring-boot:run' `
        -WorkingDirectory $Api `
        -RedirectStandardOutput $stdout `
        -RedirectStandardError $stderr `
        -PassThru
    } finally {
      if ($null -eq $oldProfile) { Remove-Item Env:SPRING_PROFILES_ACTIVE -ErrorAction SilentlyContinue }
      else { $env:SPRING_PROFILES_ACTIVE = $oldProfile }
    }

    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
      Start-Sleep -Seconds 1
      if ($backendProcess.HasExited) { break }
      try {
        $response = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:18080/api/health' -TimeoutSec 2
        if ($response.StatusCode -eq 200) { $ready = $true; break }
      } catch {}
    }
    if (-not $ready) {
      Write-Host "Backend E2E stdout: $stdout"
      Write-Host "Backend E2E stderr: $stderr"
      throw 'Backend E2E không khởi động được trên port 18080.'
    }

    Section '8. REST API end-to-end contract test'
    Push-Location $Root
    try {
      $env:SPLITDEBT_E2E_URL = 'http://127.0.0.1:18080/api'
      & $PythonExe @PythonArgs (Join-Path $Root 'tools/e2e_api.py')
      if ($LASTEXITCODE -ne 0) { throw 'REST API E2E failed.' }
    } finally {
      Remove-Item Env:SPLITDEBT_E2E_URL -ErrorAction SilentlyContinue
      Pop-Location
    }

    Section '9. Performance smoke cho endpoint /overview'
    & $PythonExe @PythonArgs (Join-Path $Root 'tools/performance_smoke.py') --requests 30 --concurrency 5 --max-p95-ms 3000
    if ($LASTEXITCODE -ne 0) { throw 'Performance smoke failed.' }

    if (-not $Fast) {
      Section '10. Flutter integration test trên Chrome với Backend E2E'
      Push-Location $Frontend
      try {
        & flutter test integration_test/auth_group_flow_test.dart -d chrome --dart-define=API_URL=http://127.0.0.1:18080/api
        if ($LASTEXITCODE -ne 0) { throw 'Flutter integration test failed.' }
      } finally { Pop-Location }
    }
  }

  Section '11. Tổng hợp coverage'
  & $PythonExe @PythonArgs (Join-Path $Root 'tools/coverage_summary.py')

  $elapsed = (Get-Date) - $started
  Write-Host "`nPASS: Toàn bộ test đã hoàn tất trong $([Math]::Round($elapsed.TotalMinutes, 2)) phút." -ForegroundColor Green
  Write-Host "JaCoCo HTML: api\target\site\jacoco\index.html"
  Write-Host "Flutter LCOV: frontend\coverage\lcov.info"
  Write-Host "E2E logs: test-results\"
}
catch {
  Write-Host "`nFAIL: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}
finally {
  if ($backendProcess -and -not $backendProcess.HasExited) {
    Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
  }
}
