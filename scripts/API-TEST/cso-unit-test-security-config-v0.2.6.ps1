# ============================================================================
# CloudStrollOffice (CSO) v0.2.6 - SecurityConfig Whitelist Unit Test (TASK-004)
# ----------------------------------------------------------------------------
# Coverage: UT-121 ~ UT-125 in docs/cso-v0.2.6/task_TASK-004/testcase.md
#   UT-121: permitAll for /api/v1/auth/login|register|refresh BEFORE anyRequest (P0)
#   UT-122: existing whitelist endpoints (health / verification-code-send /
#           password-forgot-send-code / password-forgot-reset / swagger-ui /
#           v3-api-docs) all preserved (P0)
#   UT-123: anyRequest() fallback rule still exists as the LAST rule (P0)
#           NOTE: implementation uses anyRequest().permitAll() + gateway
#           AuthFilter + Controller-level X-User-Id re-check (401 on missing);
#           security boundary is gateway+Controller layer, matcher order intact
#   UT-124: git change scope - no Controller.java / no client flutter code /
#           no route structure change (Java changes limited to internal impl) (P1)
#   UT-125: built jar contains SecurityConfig.class with login/register/refresh
#           endpoint constants (fix not rolled back in artifact) (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-security-config-v0.2.6.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-security-config-v0.2.6.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only to keep PowerShell 5.1 encoding safe.
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0
$script:FailedCases = @()

function Assert-Test {
    param(
        [string]$CaseId,
        [string]$Name,
        [bool]$Condition,
        [string]$Detail = ""
    )
    if ($Condition) {
        $script:Pass++
        Write-Output "[PASS] $CaseId $Name"
    }
    else {
        $script:Fail++
        $script:FailedCases += "$CaseId $Name - $Detail"
        Write-Output "[FAIL] $CaseId $Name - $Detail"
    }
}

function Assert-Skip {
    param(
        [string]$CaseId,
        [string]$Name,
        [string]$Detail = ""
    )
    $script:Skip++
    Write-Output "[SKIP] $CaseId $Name - $Detail"
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.6 SecurityConfig Whitelist Unit Test (TASK-004, UT-121~UT-125)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$securityConfig = Join-Path $ProjectRoot "cloudoffice-auth-service\src\main\java\org\cloudstrolling\cloudoffice\auth\config\SecurityConfig.java"
if (-not (Test-Path -LiteralPath $securityConfig)) {
    Write-Output "[FATAL] SecurityConfig.java not found: $securityConfig"
    exit 1
}
$content = Get-Content -Raw -LiteralPath $securityConfig
$contentLf = $content -replace "`r`n", "`n"

# ----------------------------------------------------------------------------
# UT-121: three endpoints permitAll present and BEFORE anyRequest (P0)
# ----------------------------------------------------------------------------
$loginMatch = $content -match 'requestMatchers\("/api/v1/auth/login"\)\.permitAll\(\)'
$registerMatch = $content -match 'requestMatchers\("/api/v1/auth/register"\)\.permitAll\(\)'
$refreshMatch = $content -match 'requestMatchers\("/api/v1/auth/refresh"\)\.permitAll\(\)'

Assert-Test -CaseId "UT-121-1" -Name "SecurityConfig contains permitAll for /api/v1/auth/login" `
    -Condition $loginMatch -Detail "regex: requestMatchers(\"/api/v1/auth/login\").permitAll()"

Assert-Test -CaseId "UT-121-2" -Name "SecurityConfig contains permitAll for /api/v1/auth/register" `
    -Condition $registerMatch -Detail "regex: requestMatchers(\"/api/v1/auth/register\").permitAll()"

Assert-Test -CaseId "UT-121-3" -Name "SecurityConfig contains permitAll for /api/v1/auth/refresh" `
    -Condition $refreshMatch -Detail "regex: requestMatchers(\"/api/v1/auth/refresh\").permitAll()"

$idxLogin = $contentLf.IndexOf('"/api/v1/auth/login"')
$idxRegister = $contentLf.IndexOf('"/api/v1/auth/register"')
$idxRefresh = $contentLf.IndexOf('"/api/v1/auth/refresh"')
$idxAnyRequest = $contentLf.IndexOf('.anyRequest()')
$orderOk = ($idxLogin -ge 0) -and ($idxRegister -ge 0) -and ($idxRefresh -ge 0) `
    -and ($idxAnyRequest -gt $idxLogin) -and ($idxAnyRequest -gt $idxRegister) `
    -and ($idxAnyRequest -gt $idxRefresh)
Assert-Test -CaseId "UT-121-4" -Name "three whitelist rules located BEFORE anyRequest() (match order = priority)" `
    -Condition $orderOk -Detail "anyRequest idx=$idxAnyRequest | login=$idxLogin register=$idxRegister refresh=$idxRefresh (all must precede anyRequest)"

# ----------------------------------------------------------------------------
# UT-122: existing whitelist endpoints ALL preserved (P0)
# ----------------------------------------------------------------------------
$existingEndpoints = @(
    @{ Id = "UT-122-1"; Path = '/api/v1/auth/health'; Label = "health" },
    @{ Id = "UT-122-2"; Path = '/api/v1/auth/verification-code/send'; Label = "verification-code-send" },
    @{ Id = "UT-122-3"; Path = '/api/v1/auth/password/forgot/send-code'; Label = "password-forgot-send-code" },
    @{ Id = "UT-122-4"; Path = '/api/v1/auth/password/forgot/reset'; Label = "password-forgot-reset" },
    @{ Id = "UT-122-5"; Path = '/swagger-ui/**'; Label = "swagger-ui" },
    @{ Id = "UT-122-6"; Path = '/v3/api-docs/**'; Label = "v3-api-docs" }
)
foreach ($ep in $existingEndpoints) {
    # 字符串包含判断（避免正则转义歧义）：路径必须以带引号的字符串形式出现在
    # authorizeHttpRequests 块内（如 requestMatchers("/api/v1/auth/health") 或
    # requestMatchers("/swagger-ui/**", "/v3/api-docs/**") 合并写法）
    $pathToken = '"' + $ep.Path + '"'
    $cond = $content.Contains($pathToken) -and $content.Contains('.permitAll()')
    Assert-Test -CaseId $ep.Id -Name "existing whitelist endpoint preserved: $($ep.Label) ($($ep.Path))" `
        -Condition ([bool]$cond) -Detail "path token present in SecurityConfig permitAll rules"
}

$permits = [regex]::Matches($content, 'requestMatchers\([^\r\n]*\)\.permitAll\(\)')
Assert-Test -CaseId "UT-122-7" -Name "permitAll matcher count >= 7 (6 existing groups + 3 new, swagger+v3 merged)" `
    -Condition ($permits.Count -ge 7) -Detail "permitAll requestMatchers count=$($permits.Count) (expect >= 7)"

# ----------------------------------------------------------------------------
# UT-123: anyRequest() fallback rule exists as the LAST rule (P0)
# ----------------------------------------------------------------------------
$anyRequestRule = $content -match '\.anyRequest\(\)\.permitAll\(\)'
Assert-Test -CaseId "UT-123-1" -Name "anyRequest() fallback rule exists (impl: anyRequest().permitAll() + gateway AuthFilter + Controller X-User-Id 401 re-check)" `
    -Condition $anyRequestRule -Detail "regex: .anyRequest().permitAll()"

$lastMatcherIdx = -1
foreach ($m in [regex]::Matches($contentLf, 'requestMatchers\([^\r\n]*\)\.permitAll\(\)')) {
    if ($m.Index -gt $lastMatcherIdx) { $lastMatcherIdx = $m.Index }
}
$anyIdx = $contentLf.IndexOf('.anyRequest()')
Assert-Test -CaseId "UT-123-2" -Name "anyRequest() is the LAST rule of authorizeHttpRequests block (after all permitAll matchers)" `
    -Condition (($anyIdx -ge 0) -and ($anyIdx -gt $lastMatcherIdx)) `
    -Detail "anyRequest idx=$anyIdx | last permitAll matcher idx=$lastMatcherIdx (anyRequest must come after)"

# ----------------------------------------------------------------------------
# UT-124: git change scope control (P1, negative/scope)
# ----------------------------------------------------------------------------
$gitBase = @("-C", $ProjectRoot)
$changed = @()
$statusOut = @(& git @gitBase status --short) 2>$null
foreach ($line in $statusOut) {
    $line = $line.TrimEnd()
    if ($line.Length -gt 3) { $changed += $line.Substring(3).Trim().Trim('"') }
}
Write-Output ("-" * 70)
Write-Output "Git change list ($($changed.Count) entries):"
$changed | ForEach-Object { Write-Output "  $_" }
Write-Output ("-" * 70)

$controllerHits = @($changed | Where-Object { $_ -match 'Controller\.java$' })
Assert-Test -CaseId "UT-124-1" -Name "no Controller.java in git change list (interface signature zero-change)" `
    -Condition ($controllerHits.Count -eq 0) `
    -Detail "Controller hits: $(if ($controllerHits) { $controllerHits -join '; ' } else { 'none' })"

$clientHits = @($changed | Where-Object { $_.Replace("\", "/").StartsWith("cloudoffice-flutter-app/") })
Assert-Test -CaseId "UT-124-2" -Name "no cloudoffice-flutter-app client code in git change list (client zero-change)" `
    -Condition ($clientHits.Count -eq 0) `
    -Detail "client hits: $(if ($clientHits) { $clientHits -join '; ' } else { 'none' })"

$gwYml = Join-Path $ProjectRoot "cloudoffice-gateway\src\main\resources\application.yml"
# 路由结构零变更：git diff 中 application.yml 仅允许 white-list 增补（logout），
# 不得出现路由段（id/uri/predicates/- Path=）新增或修改（路由结构变更判定）
$routeDiffChanged = $false
$gwDiffOut = @(& git @gitBase diff -- "cloudoffice-gateway/src/main/resources/application.yml") 2>$null
$routeHits = @($gwDiffOut | Where-Object {
    $_ -match '^[+-]' -and ($_ -match 'Path\s*=' -or $_ -match 'predicates' -or $_ -match '^\+\s*uri:' -or $_ -match '^\+\s*- id:')
})
$logoutAdded = @($gwDiffOut | Where-Object { $_ -match '^\+' -and $_ -match 'logout' })
$routeDiffChanged = ($routeHits.Count -eq 0) -and ($logoutAdded.Count -ge 1)
Assert-Test -CaseId "UT-124-3" -Name "gateway application.yml diff: white-list logout added, NO route section (id/uri/predicates/Path) changes" `
    -Condition $routeDiffChanged -Detail "route-structure diff hits=$($routeHits.Count) (expect 0), logout whitelist added=$($logoutAdded.Count) (expect >= 1)"

# ----------------------------------------------------------------------------
# UT-125: jar contains SecurityConfig.class with three endpoint constants (P1)
# ----------------------------------------------------------------------------
$jar = Join-Path $ProjectRoot "deploy\cloudoffice-auth-service.jar"
if (-not (Test-Path -LiteralPath $jar)) {
    Assert-Skip -CaseId "UT-125" -Name "auth-service jar absent" `
        -Detail "jar not found: $jar (build by FT-058 first, then re-run)"
}
else {
    $jarItem = Get-Item -LiteralPath $jar
    $jarDate = $jarItem.LastWriteTime.ToString("yyyy-MM-dd")
    Assert-Test -CaseId "UT-125-1" -Name "deploy/cloudoffice-auth-service.jar exists and is a fresh rebuild artifact (timestamp today)" `
        -Condition ($jarDate -eq ([DateTime]::Now.ToString("yyyy-MM-dd"))) `
        -Detail "jar time=$($jarItem.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) size=$($jarItem.Length)"

    $classFound = $false
    $endpointConstantsFound = @()
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $jar))
        try {
            $entry = $zip.Entries | Where-Object { $_.FullName -like "*org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.class" } | Select-Object -First 1
            if ($null -ne $entry) {
                $classFound = $true
                $reader = New-Object System.IO.StreamReader($entry.Open())
                try {
                    $classText = $reader.ReadToEnd()
                    foreach ($ep in @("/api/v1/auth/login", "/api/v1/auth/register", "/api/v1/auth/refresh")) {
                        if ($classText.Contains($ep)) { $endpointConstantsFound += $ep }
                    }
                }
                finally { $reader.Dispose() }
            }
        }
        finally { $zip.Dispose() }
    }
    catch {
        Write-Output "  [WARN] jar class extraction failed: $($_.Exception.Message)"
    }

    Assert-Test -CaseId "UT-125-2" -Name "jar contains SecurityConfig.class under BOOT-INF/classes (fix compiled into artifact)" `
        -Condition $classFound -Detail "SecurityConfig.class in jar: $classFound"

    Assert-Test -CaseId "UT-125-3" -Name "SecurityConfig.class bytes contain login/register/refresh endpoint constants (fix not rolled back)" `
        -Condition ($endpointConstantsFound.Count -ge 3) `
        -Detail "constants found: $(if ($endpointConstantsFound) { $endpointConstantsFound -join ', ' } else { 'none' }) (expect 3)"
}

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
Write-Output ("=" * 70)
Write-Output "Summary: PASS=$($script:Pass) FAIL=$($script:Fail) SKIP=$($script:Skip)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    $script:FailedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
