param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd('/')

if ($BaseUrl -notmatch '^https://.+' -and $BaseUrl -notmatch '^http://localhost(:\d+)?(/.*)?$') {
    Write-Error "BaseUrl phai bat dau bang https:// (hoac http://localhost khi chay local): '$BaseUrl'"
    exit 1
}

function Report-Pass([string]$msg) {
    Write-Host "[PASS] $msg" -ForegroundColor Green
}

function Report-Fail([string]$msg) {
    Write-Host "[FAIL] $msg" -ForegroundColor Red
}

$Token = $null
$Password = "SmokeTest!" + [Guid]::NewGuid().ToString("N").Substring(0, 12)
$Email = "smoke_" + [Guid]::NewGuid().ToString("N").Substring(0, 10) + "@example.com"
$Failed = $false

try {
    # 1. GET /health (wait up to 120s)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $healthy = $false
    while ($sw.Elapsed.TotalSeconds -lt 120) {
        try {
            $null = Invoke-RestMethod -Method Get -Uri "$BaseUrl/health" -TimeoutSec 15
            $healthy = $true
            break
        } catch {
            Start-Sleep -Seconds 3
        }
    }
    $sw.Stop()
    if (-not $healthy) {
        Report-Fail "GET /health khong phan hoi sau 120 giay"
        exit 1
    }
    Report-Pass ("GET /health ({0} ms)" -f [int]$sw.Elapsed.TotalMilliseconds)

    # 2. Register and login
    $regBody = @{
        fullName   = "Smoke Test User"
        email      = $Email
        password   = $Password
        consents   = @{
            termsVersion   = "2026-11-26"
            privacyVersion = "2026-11-26"
            ageConfirmed   = $true
        }
        platform   = "android"
        appVersion = "1.0.0"
    } | ConvertTo-Json -Depth 4

    $null = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/register" -ContentType "application/json; charset=utf-8" -Body $regBody
    $loginBody = @{
        email    = $Email
        password = $Password
    } | ConvertTo-Json
    $loginRes = Invoke-RestMethod -Method Post -Uri "$BaseUrl/auth/login" -ContentType "application/json; charset=utf-8" -Body $loginBody
    $Token = $loginRes.data.token
    if ([string]::IsNullOrWhiteSpace($Token)) {
        Report-Fail "Dang nhap khong tra ve token"
        exit 1
    }
    Report-Pass "Dang ky & dang nhap ($Email)"

    $Headers = @{ Authorization = "Bearer $Token" }

    # 3. Create group, send chat message, read back
    $groupBody = @{ name = "Smoke Deploy Group" } | ConvertTo-Json
    $groupRes = Invoke-RestMethod -Method Post -Uri "$BaseUrl/groups" -Headers $Headers -ContentType "application/json; charset=utf-8" -Body $groupBody
    $groupId = $groupRes.data.id

    $clientMsgId = [Guid]::NewGuid().ToString()
    $msgBody = @{
        content         = "Smoke deploy ping"
        clientMessageId = $clientMsgId
    } | ConvertTo-Json
    $sentRes = Invoke-RestMethod -Method Post -Uri "$BaseUrl/groups/$groupId/messages" -Headers $Headers -ContentType "application/json; charset=utf-8" -Body $msgBody
    $sentId = $sentRes.data.id

    $listRes = Invoke-RestMethod -Method Get -Uri "$BaseUrl/groups/$groupId/messages" -Headers $Headers
    $found = @($listRes.data.messages | Where-Object { $_.id -eq $sentId })
    if ($found.Count -lt 1) {
        Report-Fail "Doc lai tin chat khong thay tin vua gui"
        $Failed = $true
    } else {
        Report-Pass "Tao nhom, gui va doc lai tin chat (groupId=$groupId)"
    }
} catch {
    Report-Fail ("Loi trong qua trinh smoke: " + $_.Exception.Message)
    $Failed = $true
} finally {
    # 4. Delete smoke account
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        try {
            $delHeaders = @{ Authorization = "Bearer $Token" }
            $delBody = @{ password = $Password } | ConvertTo-Json
            $null = Invoke-RestMethod -Method Post -Uri "$BaseUrl/users/me/deletion" -Headers $delHeaders -ContentType "application/json; charset=utf-8" -Body $delBody
            Report-Pass "Xoa tai khoan smoke"
        } catch {
            Report-Fail ("Xoa tai khoan smoke that bai: " + $_.Exception.Message)
            $Failed = $true
        }
    }
}

if ($Failed) {
    exit 1
}
exit 0

