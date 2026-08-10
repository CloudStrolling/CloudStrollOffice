# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - deploy-start-services Test (TASK-004)
# ----------------------------------------------------------------------------
# Coverage: UT-164 ~ UT-176 + FT-092 ~ FT-104 in task testcase
#           (docs/cso-v0.2.7/task_TASK-004/testcase.md)
#   UT-164: deploy-start-services.ps1 parseable via PowerShell Parser (P0)
#   UT-165: deploy-start-services.sh syntax check via bash -n (fallback if no bash) (P0)
#   UT-166: dual-platform scripts both exist, startup flow 1:1 (P1)
#   UT-167: no hard-coded default addresses (P0, security)
#   UT-168: load-env call contract + no duplicated 8-key validation (P0)
#   UT-169: startup order static check MariaDB -> Redis -> Nacos (P0)
#   UT-170: not-installed service not started + not early exit (P0)
#   UT-171: JDK check only, never started (P0)
#   UT-172: startup method priority static check (service first, exe fallback) (P1)
#   UT-173: loop probe + timeout cap static check (P1)
#   UT-174: password masking, no plaintext (P0, security)
#   UT-175: output grading + exit code contract (P1)
#   UT-176: SPDX header + Simplified-Chinese comments + version v0.2.7 (P1)
#   FT-092: MariaDB not running -> auto start + probe confirm 'pass' (P0, env-gated)
#   FT-093: Redis not running -> auto start + ping confirm 'pass' (P0, env-gated)
#   FT-094: Nacos not running -> startup script + HTTP confirm 'pass' (P0, env-gated)
#   FT-095: already running -> idempotent skip 'already running' (P0, dynamic)
#   FT-096: not installed -> no start, 'please install', count fail, continue (P0)
#   FT-097: JDK check only, no start operation (P0, dynamic)
#   FT-098: startup timeout -> 'warning' + guidance, no false pass (P0, env-gated)
#   FT-099: permission boundary -> admin/sudo guidance (P1, env-gated)
#   FT-100: startup order MariaDB -> Redis -> Nacos in output (P0, dynamic)
#   FT-101: output grading summary + exit code contract (P0, dynamic)
#   FT-102: password masking - no DB_PASSWORD/REDIS_PASSWORD plaintext (P0)
#   FT-103: env.json missing -> env.example.json guidance + non-zero exit (P0)
#   FT-104: dual-platform behavior consistency (P1, SKIP if no bash/WSL)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-services-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-services-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass (SKIP not counted as failure), 1 = any failure
# NOTE:
#   ASCII only in this script to keep PowerShell 5.1 encoding safe. CJK
#   assertions are built from Unicode code points; source files with CJK
#   content are read explicitly as UTF-8 via .NET APIs. The real
#   deploy/env.json may contain sensitive credentials - the script only
#   checks key presence/non-empty and never prints credential values.
#   Dynamic FT scenarios that temporarily modify deploy/env.json are
#   backup/restore guarded (try/finally) so the real env.json is restored.
#   FT scenarios whose preconditions depend on real host services
#   (MariaDB/Redis/Nacos stopped/running) are environment-gated:
#   precondition not met -> SKIP (environment blocked, not a failure).
#   .sh dynamic assertions require bash/WSL; when unavailable they are
#   SKIP (static dual-platform coverage via UT-165/166/169~176).
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0
$script:FailedCases = @()
$script:SkippedCases = @()

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

function Skip-Test {
    param(
        [string]$CaseId,
        [string]$Name,
        [string]$Detail = ""
    )
    $script:Skip++
    $script:SkippedCases += "$CaseId $Name - $Detail"
    Write-Output "[SKIP] $CaseId $Name - $Detail"
}

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Test-FileExists {
    param([string]$Path)
    return (Test-Path -LiteralPath $Path -PathType Leaf)
}

# Build CJK strings from Unicode code points (keep this script ASCII-only)
function Get-CjkText {
    param([string]$Key)
    switch ($Key) {
        "pass"        { return [string][char]0x901A + [string][char]0x8FC7 }
        "warn"        { return [string][char]0x8B66 + [string][char]0x544A }
        "fail"        { return [string][char]0x5931 + [string][char]0x8D25 }
        "running"     { return [string][char]0x8FD0 + [string][char]0x884C }
        "already"     { return [string][char]0x5DF2 }
        "install"     { return [string][char]0x5B89 + [string][char]0x88C5 }
        "please"      { return [string][char]0x8BF7 }
        "first"       { return [string][char]0x5148 }
        "notinst"     { return [string][char]0x672A + [string][char]0x5B89 + [string][char]0x88C5 }
        "inst_first"  { return [string][char]0x672A + [string][char]0x5B89 + [string][char]0x88C5 + [string][char]0xFF0C + [string][char]0x8BF7 + [string][char]0x5148 + [string][char]0x5B89 + [string][char]0x88C5 }
        "trystart"    { return [string][char]0x5C1D + [string][char]0x8BD5 + [string][char]0x542F + [string][char]0x52A8 }
        "timeout"     { return [string][char]0x542F + [string][char]0x52A8 + [string][char]0x8D85 + [string][char]0x65F6 }
        "retry"       { return [string][char]0x7B49 + [string][char]0x5F85 + [string][char]0x6570 + [string][char]0x79D2 + [string][char]0x540E + [string][char]0x91CD + [string][char]0x8BD5 }
        "manual"      { return [string][char]0x624B + [string][char]0x52A8 + [string][char]0x68C0 + [string][char]0x67E5 }
        "admin"       { return [string][char]0x4EE5 + [string][char]0x7BA1 + [string][char]0x7406 + [string][char]0x5458 + [string][char]0x8EAB + [string][char]0x4EFD + [string][char]0x8FD0 + [string][char]0x884C }
        "startok"     { return [string][char]0x542F + [string][char]0x52A8 + [string][char]0x6210 + [string][char]0x529F }
        "canstart"    { return [string][char]0x53EF + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x540E + [string][char]0x7AEF + [string][char]0x670D + [string][char]0x52A1 }
        "summary"     { return [string][char]0x57FA + [string][char]0x7840 + [string][char]0x8BBE + [string][char]0x65BD + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x5B8C + [string][char]0x6210 }
        "nostart"     { return [string][char]0x65E0 + [string][char]0x9700 + [string][char]0x542F + [string][char]0x52A8 }
        "item"        { return [string][char]0x9879 }
        "run_ok"      { return [string][char]0x5DF2 + [string][char]0x8FD0 + [string][char]0x884C }
        "not_run"     { return [string][char]0x672A + [string][char]0x8FD0 + [string][char]0x884C }
        "ready"       { return [string][char]0x5C31 + [string][char]0x7EEA }
        "usable"      { return [string][char]0x53EF + [string][char]0x7528 }
        "unusable"    { return [string][char]0x4E0D + [string][char]0x53EF + [string][char]0x7528 }
        "failitems"   { return [string][char]0x5B58 + [string][char]0x5728 + [string][char]0x5931 + [string][char]0x8D25 + [string][char]0x9879 }
        "warnitems"   { return [string][char]0x5B58 + [string][char]0x5728 + [string][char]0x8B66 + [string][char]0x544A + [string][char]0x9879 }
        "allready"    { return [string][char]0x5168 + [string][char]0x90E8 + [string][char]0x5C31 + [string][char]0x7EEA }
        "manstart"    { return [string][char]0x8BF7 + [string][char]0x624B + [string][char]0x52A8 + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x670D + [string][char]0x52A1 }
    }
    return ""
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 deploy-start-services Test (TASK-004, UT-164~UT-176 + FT-092~FT-104)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$scriptsDir    = Join-Path $ProjectRoot "deploy\scripts"
$servicesPs1   = Join-Path $scriptsDir "deploy-start-services.ps1"
$servicesSh    = Join-Path $scriptsDir "deploy-start-services.sh"
$loadEnvPs1    = Join-Path $scriptsDir "load-env.ps1"
$loadEnvSh     = Join-Path $scriptsDir "load-env.sh"
$deployDir     = Join-Path $ProjectRoot "deploy"
$envJsonPath   = Join-Path $deployDir "env.json"

$ps1Exists     = Test-FileExists -Path $servicesPs1
$shExists      = Test-FileExists -Path $servicesSh
$envJsonExists = Test-FileExists -Path $envJsonPath

# CJK words used by assertions
$cjkPass       = Get-CjkText "pass"
$cjkWarn       = Get-CjkText "warn"
$cjkFail       = Get-CjkText "fail"
$cjkRunning    = Get-CjkText "running"
$cjkAlready    = Get-CjkText "already"
$cjkInstall    = Get-CjkText "install"
$cjkPlease     = Get-CjkText "please"
$cjkFirst      = Get-CjkText "first"
$cjkNotinst    = Get-CjkText "notinst"
$cjkInstFirst  = Get-CjkText "inst_first"
$cjkTrystart   = Get-CjkText "trystart"
$cjkTimeout    = Get-CjkText "timeout"
$cjkRetry      = Get-CjkText "retry"
$cjkManual     = Get-CjkText "manual"
$cjkAdmin      = Get-CjkText "admin"
$cjkStartok    = Get-CjkText "startok"
$cjkCanstart   = Get-CjkText "canstart"
$cjkSummary    = Get-CjkText "summary"
$cjkNostart    = Get-CjkText "nostart"
$cjkItem       = Get-CjkText "item"
$cjkRunOk      = Get-CjkText "run_ok"
$cjkNotRun     = Get-CjkText "not_run"
$cjkReady      = Get-CjkText "ready"
$cjkUsable     = Get-CjkText "usable"
$cjkUnusable   = Get-CjkText "unusable"
$cjkFailitems  = Get-CjkText "failitems"
$cjkWarnitems  = Get-CjkText "warnitems"
$cjkAllready   = Get-CjkText "allready"
$cjkManstart   = Get-CjkText "manstart"

# ----------------------------------------------------------------------------
# bash usability probe (bash/WSL may be unavailable on this host)
# ----------------------------------------------------------------------------
$bashUsable = $false
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd) {
    $probeOut = (& bash -n -c "true" 2>&1) 2>$null
    $bashUsable = ($LASTEXITCODE -eq 0)
}

# ============================================================================
# UT-164: deploy-start-services.ps1 syntax parseability (P0)
# ============================================================================
if (-not $ps1Exists) {
    Assert-Test -CaseId "UT-164-1" -Name "deploy-start-services.ps1 exists" -Condition $false -Detail "not found: $servicesPs1"
}
else {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($servicesPs1, [ref]$tokens, [ref]$errors) | Out-Null
    $errText = ""
    if ($errors -and $errors.Count -gt 0) {
        $errText = ($errors | ForEach-Object { "L$($_.Extent.StartLineNumber):$($_.Message)" }) -join "; "
    }
    Assert-Test -CaseId "UT-164-1" -Name "deploy-start-services.ps1 parseable via PowerShell Parser (no syntax errors, PS 5.1 compatible)" `
        -Condition (-not $errors -or $errors.Count -eq 0) `
        -Detail ("parse errors: " + $(if ($errText) { $errText } else { "none" }))
}

$ps1Text = if ($ps1Exists) { Read-Utf8File -Path $servicesPs1 } else { "" }

# key functions and main-flow blocks present
$ps1Funcs = @("Write-Result", "Split-Csv", "Test-Installed", "Test-TcpPort",
              "Test-NacosHttp", "Test-NacosJavaProcess", "Test-MariaDbUp",
              "Test-RedisUp", "Test-RedisPing", "Test-NacosUp", "Wait-ServiceUp")
$ps1FuncMiss = @($ps1Funcs | Where-Object { $ps1Exists -and -not $ps1Text.Contains($_) })
$ps1Blocks = @("JDK", "MariaDB", "Redis", "Nacos")
$ps1BlockMiss = @($ps1Blocks | Where-Object { $ps1Exists -and -not $ps1Text.Contains($_) })
Assert-Test -CaseId "UT-164-2" -Name "key functions (Write-Result/Split-Csv/Test-Installed/Test-TcpPort/Test-NacosHttp/Test-NacosJavaProcess/Test-MariaDbUp/Test-RedisUp/Test-RedisPing/Test-NacosUp/Wait-ServiceUp) + main-flow blocks (JDK/MariaDB/Redis/Nacos) present" `
    -Condition (($ps1FuncMiss.Count -eq 0) -and ($ps1BlockMiss.Count -eq 0)) `
    -Detail ("missing funcs: " + $(if ($ps1FuncMiss.Count -eq 0) { "none" } else { $ps1FuncMiss -join ", " }) +
             "; missing blocks: " + $(if ($ps1BlockMiss.Count -eq 0) { "none" } else { $ps1BlockMiss -join ", " }))

# ============================================================================
# UT-165: deploy-start-services.sh syntax check via bash -n (P0, fallback if no bash)
# ============================================================================
$shText = if ($shExists) { Read-Utf8File -Path $servicesSh } else { "" }
if (-not $shExists) {
    Assert-Test -CaseId "UT-165-1" -Name "deploy-start-services.sh exists" -Condition $false -Detail "not found: $servicesSh"
}
else {
    if ($bashUsable) {
        $native = $servicesSh
        $wslPath = $native
        if ($native -match "^([A-Za-z]):\\(.*)$") {
            $wslPath = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $out = (& bash -n $wslPath 2>&1)
        $ok = ($LASTEXITCODE -eq 0)
        Assert-Test -CaseId "UT-165-1" -Name "deploy-start-services.sh syntax check via bash -n (exit 0, no output)" `
            -Condition $ok -Detail ("bash -n output: " + $(if ($out) { ($out -join " ") } else { "none" }))
    }
    else {
        # Fallback (bash/WSL unavailable): shebang + non-empty + if/fi pairing + function def
        $hasShebang = ($shText -match "(?m)^#!")
        $nonEmpty = ($shText.Trim().Length -gt 0)
        $ifCount = ([regex]::Matches($shText, "\bif\b")).Count
        $fiCount = ([regex]::Matches($shText, "\bfi\b")).Count
        $hasFunc = ($shText -match "(?m)^print_result\s*\(\s*\)")
        $structOk = $hasShebang -and $nonEmpty -and ($ifCount -eq $fiCount) -and $hasFunc
        Assert-Test -CaseId "UT-165-1" -Name "deploy-start-services.sh fallback structure check (bash unavailable: shebang+non-empty+if/fi paired+function def)" `
            -Condition $structOk `
            -Detail ("bash usable: false; shebang: $hasShebang, non-empty: $nonEmpty, if=$ifCount fi=$fiCount, print_result func: $hasFunc")
    }
}

# version tag must be v0.2.7, not stale v0.2.0
$shVersionOk = $shExists -and $shText.Contains("v0.2.7") -and (-not $shText.Contains("v0.2.0"))
$ps1VersionOk = $ps1Exists -and $ps1Text.Contains("v0.2.7")
Assert-Test -CaseId "UT-165-2" -Name "version tag v0.2.7 in both scripts (.sh not stale v0.2.0)" `
    -Condition ($ps1VersionOk -and $shVersionOk) `
    -Detail (".ps1 v0.2.7=$ps1VersionOk, .sh v0.2.7+no-v0.2.0=$shVersionOk")

# ============================================================================
# UT-166: dual-platform scripts both exist, startup flow 1:1 (P1)
# ============================================================================
Assert-Test -CaseId "UT-166-1" -Name "deploy-start-services.ps1 and deploy-start-services.sh both exist (paired)" `
    -Condition ($ps1Exists -and $shExists) `
    -Detail (".ps1: $ps1Exists, .sh: $shExists")

# result output branches 1:1 between platforms. .ps1 uses Start-Process which
# can throw synchronously, so it has one extra Nacos catch branch output
# (startup failed -> warning); .sh launches via nohup ... & (async) and the
# startup-failed case falls into the startup-timeout warning. Both end with a
# warning + manual-check guidance (no false pass) - behavior parity holds.
$ps1ResultCalls = if ($ps1Exists) { ([regex]::Matches($ps1Text, 'Write-Result')).Count - 1 } else { 0 }   # -1: exclude function definition
$shResultCalls  = if ($shExists)  { ([regex]::Matches($shText, 'print_result')).Count - 1 } else { 0 }     # -1: exclude function definition
$parityOk = ($ps1ResultCalls -eq $shResultCalls) -or ($ps1ResultCalls -eq ($shResultCalls + 1))
Assert-Test -CaseId "UT-166-2" -Name "result output branches 1:1 between platforms (Write-Result calls == print_result calls, +1 allowed for .ps1 Nacos Start-Process catch branch; >= 8 core branches: JDK + MariaDB/Redis/Nacos)" `
    -Condition ($parityOk -and ($ps1ResultCalls -ge 8) -and ($shResultCalls -ge 8)) `
    -Detail (".ps1 Write-Result calls=$ps1ResultCalls; .sh print_result calls=$shResultCalls (equal or +1 .ps1 catch branch; >= 8 expected)")

# startup flow one-to-one: both contain the three service sections in order
$ps1MariaIdx = $ps1Text.IndexOf("MariaDB")
$ps1RedisIdx = $ps1Text.IndexOf("Redis")
$ps1NacosIdx = $ps1Text.IndexOf("Nacos")
$shMariaIdx  = $shText.IndexOf("MariaDB")
$shRedisIdx  = $shText.IndexOf("Redis")
$shNacosIdx  = $shText.IndexOf("Nacos")
$ps1FlowOk = ($ps1MariaIdx -ge 0) -and ($ps1RedisIdx -gt $ps1MariaIdx) -and ($ps1NacosIdx -gt $ps1RedisIdx)
$shFlowOk  = ($shMariaIdx  -ge 0) -and ($shRedisIdx  -gt $shMariaIdx)  -and ($shNacosIdx  -gt $shRedisIdx)
Assert-Test -CaseId "UT-166-3" -Name "startup flow sections (MariaDB before Redis before Nacos) present in both scripts 1:1 (UT-143 contract continuation)" `
    -Condition ($ps1FlowOk -and $shFlowOk) `
    -Detail (".ps1 MariaDB@$ps1MariaIdx Redis@$ps1RedisIdx Nacos@$ps1NacosIdx; .sh MariaDB@$shMariaIdx Redis@$shRedisIdx Nacos@$shNacosIdx (ascending expected)")

# ============================================================================
# UT-167: no hard-coded default addresses (P0, security)
# ============================================================================
$hardIpPattern = "192\.168\.1\.1[0-9][0-9]"
$ps1HardIp = $ps1Exists -and [regex]::IsMatch($ps1Text, $hardIpPattern)
$shHardIp  = $shExists  -and [regex]::IsMatch($shText, $hardIpPattern)
Assert-Test -CaseId "UT-167-1" -Name "no hard-coded 192.168.1.1xx default addresses in both scripts" `
    -Condition (-not $ps1HardIp -and -not $shHardIp) `
    -Detail (".ps1 hit: $ps1HardIp, .sh hit: $shHardIp (expected absent)")

$anyIpPattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
$ps1AnyIp = $ps1Exists -and [regex]::IsMatch($ps1Text, $anyIpPattern)
$shAnyIp  = $shExists  -and [regex]::IsMatch($shText, $anyIpPattern)
Assert-Test -CaseId "UT-167-2" -Name "no literal IP addresses anywhere in both scripts (connect addresses from env vars only)" `
    -Condition (-not $ps1AnyIp -and -not $shAnyIp) `
    -Detail (".ps1 literal IP: $ps1AnyIp, .sh literal IP: $shAnyIp (expected absent)")

# ============================================================================
# UT-168: load-env call contract + no duplicated 8-key validation (P0)
# ============================================================================
$ps1LoadEnvOk = $ps1Exists -and ($ps1Text -match "\`$PSScriptRoot\\load-env\.ps1")
$shLoadEnvOk  = $shExists  -and ($shText  -match '\$SCRIPT_DIR/load-env\.sh')
$shLoadEnvExitOk = $shExists -and ($shText -match 'load-env\.sh"\s*\|\|\s*exit')
Assert-Test -CaseId "UT-168-1" -Name "both scripts call load-env via PSScriptRoot / SCRIPT_DIR (.sh with || exit $? exit-code passthrough, F-001)" `
    -Condition ($ps1LoadEnvOk -and $shLoadEnvOk -and $shLoadEnvExitOk) `
    -Detail (".ps1 dot-source load-env.ps1=$ps1LoadEnvOk; .sh source load-env.sh=$shLoadEnvOk, || exit=$shLoadEnvExitOk")

# no duplicated 8-key required-config validation block (load-env already handles it)
$ps1DupKeyPattern = 'IsNullOrEmpty\(\$env:(NACOS_ADDR|NACOS_HOME|DB_HOST|DB_PORT|DB_USERNAME|DB_PASSWORD|REDIS_HOST|REDIS_PORT)'
$shDupKeyPattern = '\[ -z "\$(NACOS_ADDR|DB_HOST|DB_PORT|DB_USERNAME|DB_PASSWORD|REDIS_HOST|REDIS_PORT|REDIS_SERVICE_NAME|REDIS_PROCESS_NAME|DB_SERVICE_NAME|DB_PROCESS_NAME)"'
$ps1DupKey = $ps1Exists -and [regex]::IsMatch($ps1Text, $ps1DupKeyPattern)
$shDupKey  = $shExists  -and [regex]::IsMatch($shText, $shDupKeyPattern)
Assert-Test -CaseId "UT-168-2" -Name "no duplicated 8-key required-config validation block in both scripts (load-env F-001 unified fallback)" `
    -Condition (-not $ps1DupKey -and -not $shDupKey) `
    -Detail (".ps1 dup-key validation hit: $ps1DupKey; .sh dup-key validation hit: $shDupKey (expected absent)")

# config values read via env variables ($env:* / $*)
$ps1EnvVar = $ps1Exists -and $ps1Text.Contains("`$env:DB_HOST") -and $ps1Text.Contains("`$env:REDIS_HOST") -and $ps1Text.Contains("`$env:NACOS_ADDR")
$shEnvVar  = $shExists  -and $shText.Contains("`$DB_HOST") -and $shText.Contains("`$REDIS_HOST") -and $shText.Contains("`$NACOS_ADDR")
Assert-Test -CaseId "UT-168-3" -Name "config values read from env variables (DB_HOST/REDIS_HOST/NACOS_ADDR) in both scripts" `
    -Condition ($ps1EnvVar -and $shEnvVar) `
    -Detail (".ps1 env vars=$ps1EnvVar; .sh env vars=$shEnvVar")

# ============================================================================
# UT-169: startup order static check MariaDB -> Redis -> Nacos (P0)
# ============================================================================
$ps1SummaryIdx = $ps1Text.IndexOf($cjkSummary)
$shSummaryIdx  = $shText.IndexOf($cjkSummary)
$ps1OrderOk = $ps1FlowOk -and ($ps1SummaryIdx -gt $ps1NacosIdx)
$shOrderOk  = $shFlowOk  -and ($shSummaryIdx  -gt $shNacosIdx)
Assert-Test -CaseId "UT-169-1" -Name "startup order static: MariaDB -> Redis -> Nacos in both scripts (SAD contract, DB/cache before registry)" `
    -Condition ($ps1OrderOk -and $shOrderOk) `
    -Detail (".ps1 order ok=$ps1OrderOk; .sh order ok=$shOrderOk")

$ps1SummaryAfter = $ps1Exists -and ($ps1SummaryIdx -gt $ps1NacosIdx)
$shSummaryAfter  = $shExists  -and ($shSummaryIdx  -gt $shNacosIdx)
Assert-Test -CaseId "UT-169-2" -Name "summary and exit-code logic located after all three service sections (both platforms)" `
    -Condition ($ps1SummaryAfter -and $shSummaryAfter) `
    -Detail (".ps1 summary after Nacos=$ps1SummaryAfter; .sh summary after Nacos=$shSummaryAfter")

# ============================================================================
# UT-170: not-installed service not started + not early exit (P0)
# ============================================================================
$ps1NotinstCount = if ($ps1Exists) { ([regex]::Matches($ps1Text, [regex]::Escape($cjkInstFirst))).Count } else { 0 }
$shNotinstCount  = if ($shExists)  { ([regex]::Matches($shText,  [regex]::Escape($cjkInstFirst))).Count } else { 0 }
Assert-Test -CaseId "UT-170-1" -Name "not-installed message 'please install first' present for MariaDB/Redis/Nacos (>=2 occurrences, both platforms, F-007)" `
    -Condition (($ps1NotinstCount -ge 2) -and ($shNotinstCount -ge 2)) `
    -Detail (".ps1 'please install first' count=$ps1NotinstCount; .sh count=$shNotinstCount (>=2 expected: MariaDB+Redis, Nacos may add one)")

# no early exit 1 in not-installed branches: exit 1 appears only once in final summary
$ps1Exit1Count = if ($ps1Exists) { ([regex]::Matches($ps1Text, "\bexit\s+1\b")).Count } else { 0 }
$shExit1Count  = if ($shExists)  { ([regex]::Matches($shText,  "\bexit\s+1\b")).Count } else { 0 }
Assert-Test -CaseId "UT-170-2" -Name "no early exit 1 in not-installed detection phase (exit 1 only at final summary, once per script; flow continues to later services)" `
    -Condition (($ps1Exit1Count -eq 1) -and ($shExit1Count -eq 1)) `
    -Detail (".ps1 exit 1 count=$ps1Exit1Count; .sh exit 1 count=$shExit1Count (1 expected: final summary)")

# ============================================================================
# UT-171: JDK check only, never started (P0)
# ============================================================================
$ps1Jdk = $ps1Exists -and $ps1Text.Contains("java -version") -and $ps1Text.Contains('version "21') -and $ps1Text.Contains("JAVA_HOME") -and $ps1Text.Contains($cjkNostart)
$shJdk  = $shExists  -and $shText.Contains("java -version") -and $shText.Contains('version "21') -and $shText.Contains("JAVA_HOME") -and $shText.Contains($cjkNostart)
Assert-Test -CaseId "UT-171-1" -Name "JDK section outputs availability conclusion only (java -version + version 21 + JAVA_HOME + 'no start needed', F-006)" `
    -Condition ($ps1Jdk -and $shJdk) `
    -Detail (".ps1 JDK conclusion=$ps1Jdk; .sh JDK conclusion=$shJdk")

# no java start operation: no Start-Process java / java -jar / Start-Job java / nohup java
$ps1JavaStart = $ps1Exists -and ($ps1Text -match "Start-Process[^\r\n]*java" -or $ps1Text -match "java\s+-jar" -or $ps1Text -match "Start-Job[^\r\n]*java")
$shJavaStart  = $shExists  -and ($shText -match "java\s+-jar" -or $shText -match "nohup\s+java" -or $shText -match "Start-Process[^\r\n]*java")
Assert-Test -CaseId "UT-171-2" -Name "no java start operation anywhere in both scripts (JDK check only, never started)" `
    -Condition (-not $ps1JavaStart -and -not $shJavaStart) `
    -Detail (".ps1 java-start op hit: $ps1JavaStart; .sh java-start op hit: $shJavaStart (expected absent)")

# ============================================================================
# UT-172: startup method priority static check - service first, exe fallback (P1)
# ============================================================================
$ps1StartSvc = $ps1Exists -and $ps1Text.Contains("Start-Service") -and $ps1Text.Contains("Get-Service")
$shStartSvc  = $shExists  -and $shText.Contains("systemctl start") -and $shText.Contains("service ") -and $shText.Contains("sudo")
Assert-Test -CaseId "UT-172-1" -Name "MariaDB/Redis service-start priority present (Start-Service / systemctl start + service fallback, both platforms)" `
    -Condition ($ps1StartSvc -and $shStartSvc) `
    -Detail (".ps1 Start-Service/Get-Service=$ps1StartSvc; .sh systemctl/service/sudo=$shStartSvc")

$ps1StartExe = $ps1Exists -and $ps1Text.Contains("Start-Process") -and ($ps1Text.Contains("mysqld") -or $ps1Text.Contains("mariadbd")) -and $ps1Text.Contains("redis-server")
$shStartExe  = $shExists  -and $shText.Contains("mysqld_safe") -and $shText.Contains("redis-server --daemonize yes") -and $shText.Contains("nohup")
Assert-Test -CaseId "UT-172-2" -Name "executable fallback present (mysqld/mariadbd/redis-server via Start-Process / mysqld_safe + --daemonize yes, both platforms)" `
    -Condition ($ps1StartExe -and $shStartExe) `
    -Detail (".ps1 Start-Process exe=$ps1StartExe; .sh mysqld_safe/daemonize/nohup=$shStartExe")

$ps1NacosStart = $ps1Exists -and $ps1Text.Contains("startup.cmd") -and $ps1Text.Contains("-m standalone")
$shNacosStart  = $shExists  -and $shText.Contains("startup.sh") -and $shText.Contains("-m standalone")
Assert-Test -CaseId "UT-172-3" -Name "Nacos start via NACOS_HOME/bin/startup.cmd (Windows) or startup.sh (Linux) standalone mode" `
    -Condition ($ps1NacosStart -and $shNacosStart) `
    -Detail (".ps1 startup.cmd -m standalone=$ps1NacosStart; .sh startup.sh -m standalone=$shNacosStart")

# service/process name lists come from env.json lists (Split-Csv / split_csv), not hard-coded systemctl names
$ps1List = $ps1Exists -and $ps1Text.Contains("Split-Csv") -and $ps1Text.Contains("`$env:DB_SERVICE_NAME") -and $ps1Text.Contains("`$env:REDIS_SERVICE_NAME")
$shList  = $shExists  -and $shText.Contains("split_csv") -and $shText.Contains("DB_SERVICE_NAME") -and $shText.Contains("REDIS_SERVICE_NAME")
Assert-Test -CaseId "UT-172-4" -Name "service/process name lists parsed from env.json via Split-Csv/split_csv (no hard-coded service names, F-001)" `
    -Condition ($ps1List -and $shList) `
    -Detail (".ps1 list parsing=$ps1List; .sh list parsing=$shList")

# ============================================================================
# UT-173: loop probe + timeout cap static check (P1)
# ============================================================================
$ps1Loop = $ps1Exists -and $ps1Text.Contains("while (`$elapsed -lt `$TimeoutSeconds)") -and $ps1Text.Contains("Start-Sleep -Seconds") -and $ps1Text.Contains("Wait-ServiceUp")
$shLoop  = $shExists  -and $shText.Contains('while [ "$elapsed" -lt "$timeout" ]') -and $shText.Contains('sleep "$interval"') -and $shText.Contains("wait_for_service")
Assert-Test -CaseId "UT-173-1" -Name "loop-probe + timeout cap present (Wait-ServiceUp while loop / wait_for_service while loop, both platforms, F-007)" `
    -Condition ($ps1Loop -and $shLoop) `
    -Detail (".ps1 loop+timeout=$ps1Loop; .sh loop+timeout=$shLoop")

$ps1Warn = $ps1Exists -and $ps1Text.Contains($cjkTimeout) -and $ps1Text.Contains($cjkRetry) -and $ps1Text.Contains($cjkManual) -and $ps1Text.Contains($cjkAdmin)
$shWarn  = $shExists  -and $shText.Contains($cjkTimeout) -and $shText.Contains($cjkRetry) -and $shText.Contains($cjkManual) -and $shText.Contains("sudo")
Assert-Test -CaseId "UT-173-2" -Name "timeout branch outputs warning with guidance (wait-retry / manual check / permission hint), no false pass (both platforms)" `
    -Condition ($ps1Warn -and $shWarn) `
    -Detail (".ps1 timeout guidance=$ps1Warn; .sh timeout guidance=$shWarn")

$ps1WaitCalls = if ($ps1Exists) { ([regex]::Matches($ps1Text, "Wait-ServiceUp")).Count } else { 0 }
$shWaitCalls  = if ($shExists)  { ([regex]::Matches($shText, "wait_for_service")).Count } else { 0 }
Assert-Test -CaseId "UT-173-3" -Name "all three services (MariaDB/Redis/Nacos) use loop-probe confirm after start (Wait-ServiceUp / wait_for_service call count >= 3 and equal)" `
    -Condition (($ps1WaitCalls -ge 3) -and ($shWaitCalls -ge 3) -and ($ps1WaitCalls -eq $shWaitCalls)) `
    -Detail (".ps1 Wait-ServiceUp count=$ps1WaitCalls; .sh wait_for_service count=$shWaitCalls (>=3 and equal expected)")

# ============================================================================
# UT-174: password masking - no plaintext in output statements (P0, security)
# ============================================================================
$sensitiveVars = @("DB_PASSWORD", "REDIS_PASSWORD")
$ps1OutputLines = @($ps1Text -split "`r?`n" | Where-Object { $_ -match "Write-(Host|Error|Output|Warning)" -or $_ -match 'Write-Result "' })
$ps1SensitiveOut = @($ps1OutputLines | Where-Object {
    $line = $_
    $hit = $false
    foreach ($v in $sensitiveVars) {
        if ($line -match ('\$env:' + $v) -or $line -match ('\$\{' + $v + '\}') -or
            $line -match ('\$' + $v + '\b')) { $hit = $true; break }
    }
    $hit
})
$shOutputLines = @($shText -split "`r?`n" | Where-Object { $_ -match "(echo|printf)" })
$shSensitiveOut = @($shOutputLines | Where-Object {
    $line = $_
    $hit = $false
    foreach ($v in $sensitiveVars) {
        if ($line -match ("\$" + $v + "\b") -or $line -match ("\$\{" + $v + "\}")) { $hit = $true; break }
    }
    $hit
})
Assert-Test -CaseId "UT-174-1" -Name "output statements (Write-*/echo/printf) never reference DB_PASSWORD/REDIS_PASSWORD plaintext values" `
    -Condition ($ps1SensitiveOut.Count -eq 0 -and $shSensitiveOut.Count -eq 0) `
    -Detail (".ps1 sensitive outputs: " + $(if ($ps1SensitiveOut.Count -eq 0) { "none" } else { $ps1SensitiveOut -join "; " }) +
             "; .sh sensitive outputs: " + $(if ($shSensitiveOut.Count -eq 0) { "none" } else { $shSensitiveOut -join "; " }))

$ps1RedisAuth = $ps1Exists -and $ps1Text.Contains("REDISCLI_AUTH") -and $ps1Text.Contains("redis-cli -h `$env:REDIS_HOST -p `$env:REDIS_PORT ping")
$shRedisAuth  = $shExists  -and $shText.Contains("REDISCLI_AUTH") -and $shText.Contains('redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping')
Assert-Test -CaseId "UT-174-2" -Name "Redis confirm ping uses -h/-p from env and password passed via REDISCLI_AUTH (no plaintext in command line, both platforms)" `
    -Condition ($ps1RedisAuth -and $shRedisAuth) `
    -Detail (".ps1 REDISCLI_AUTH + -h/-p=$ps1RedisAuth; .sh REDISCLI_AUTH + -h/-p=$shRedisAuth")

# ============================================================================
# UT-175: output grading (pass/warn/fail) + exit code contract (P1)
# ============================================================================
$ps1Grading = $ps1Exists -and $ps1Text.Contains("[$($cjkPass)]") -and $ps1Text.Contains("[$($cjkWarn)]") -and $ps1Text.Contains("[$($cjkFail)]")
$shGrading  = $shExists  -and $shText.Contains("[$($cjkPass)]") -and $shText.Contains("[$($cjkWarn)]") -and $shText.Contains("[$($cjkFail)]")
$ps1Colors = $ps1Exists -and $ps1Text.Contains("ForegroundColor") -and $ps1Text.Contains("Green") -and $ps1Text.Contains("Yellow") -and $ps1Text.Contains("Red")
$shAnsi    = $shExists  -and $shText.Contains('\033[')
Assert-Test -CaseId "UT-175-1" -Name "three-level output grading with bracket text prefix [pass]/[warn]/[fail] + colors, no emoji (both platforms, F-011)" `
    -Condition ($ps1Grading -and $shGrading -and $ps1Colors -and $shAnsi) `
    -Detail (".ps1 grading=$ps1Grading colors=$ps1Colors; .sh grading=$shGrading ANSI=$shAnsi")

# .sh must not use emoji (old style) in output
$shEmoji = $shExists -and ($shText.Contains([string][char]0x2705) -or $shText.Contains([string][char]0x26A0) -or $shText.Contains([string][char]0x274C))
Assert-Test -CaseId "UT-175-2" -Name ".sh no emoji in output (check/cross/warning emoji removed, aligned with .ps1 bracket text style)" `
    -Condition (-not $shEmoji) `
    -Detail (".sh emoji present: $shEmoji (expected absent)")

$ps1ExitLogic = $ps1Exists -and $ps1Text.Contains("`$script:fail -gt 0") -and $ps1Text.Contains("`$script:warn -gt 0") -and $ps1Text.Contains("exit 1") -and $ps1Text.Contains("exit 0")
$shExitLogic  = $shExists  -and $shText.Contains('[ "$FAIL" -gt 0 ]') -and $shText.Contains('[ "$WARN" -gt 0 ]') -and $shText.Contains("exit 1") -and $shText.Contains("exit 0")
Assert-Test -CaseId "UT-175-3" -Name "exit code contract present (fail>0 -> exit 1; warn only or all pass -> exit 0 + warning hint, F-011)" `
    -Condition ($ps1ExitLogic -and $shExitLogic) `
    -Detail (".ps1 exit logic=$ps1ExitLogic; .sh exit logic=$shExitLogic")

$ps1Summary2 = $ps1Exists -and $ps1Text.Contains($cjkSummary) -and $ps1Text.Contains("`$script:pass") -and $ps1Text.Contains("`$script:warn") -and $ps1Text.Contains("`$script:fail") -and $ps1Text.Contains($cjkCanstart)
$shSummary2  = $shExists  -and $shText.Contains($cjkSummary) -and $shText.Contains("`$PASS") -and $shText.Contains("`$WARN") -and $shText.Contains("`$FAIL") -and $shText.Contains($cjkCanstart)
Assert-Test -CaseId "UT-175-4" -Name "summary shows pass/warn/fail counts + 'can start backend services' hint when all reachable (both platforms)" `
    -Condition ($ps1Summary2 -and $shSummary2) `
    -Detail (".ps1 summary counts+hint=$ps1Summary2; .sh summary counts+hint=$shSummary2")

# ============================================================================
# UT-176: SPDX header + Simplified-Chinese comments + version v0.2.7 (P1)
# ============================================================================
$ps1Spdx = $ps1Exists -and $ps1Text.Contains("SPDX-License-Identifier") -and $ps1Text.Contains("Apache-2.0") -and $ps1Text.Contains("Copyright 2026 jenemy8023")
$shSpdx  = $shExists  -and $shText.Contains("SPDX-License-Identifier") -and $shText.Contains("Apache-2.0") -and $shText.Contains("Copyright 2026 jenemy8023")
Assert-Test -CaseId "UT-176-1" -Name "SPDX-License-Identifier Apache-2.0 + Copyright 2026 jenemy8023 in both file headers" `
    -Condition ($ps1Spdx -and $shSpdx) `
    -Detail (".ps1 SPDX=$ps1Spdx; .sh SPDX=$shSpdx")

$cjkRegex = "[\u4e00-\u9fff]"
$ps1Cjk = $ps1Exists -and [regex]::IsMatch($ps1Text, $cjkRegex)
$shCjk  = $shExists  -and [regex]::IsMatch($shText, $cjkRegex)
Assert-Test -CaseId "UT-176-2" -Name "comments in Simplified Chinese (CJK) in both scripts" `
    -Condition ($ps1Cjk -and $shCjk) `
    -Detail (".ps1 CJK=$ps1Cjk; .sh CJK=$shCjk")

Assert-Test -CaseId "UT-176-3" -Name "version tag v0.2.7 unified in both scripts (not stale v0.2.0)" `
    -Condition ($ps1VersionOk -and $shVersionOk) `
    -Detail (".ps1 v0.2.7=$ps1VersionOk; .sh v0.2.7+no-v0.2.0=$shVersionOk")

# ============================================================================
# dynamic FT section - single cached run of deploy-start-services.ps1
#   - Preconditions depend on real host services (stopped/running/installed)
#     -> environment-gated: precondition not met => SKIP (not a failure).
#   - Runs once and caches output/exit code; multiple FT scenarios reuse it.
#   - FT-103 backs up deploy/env.json and restores it in finally.
# ============================================================================
$script:Ps1RunAttempted = $false
$script:Ps1RunSkipped   = $false
$script:Ps1RunOk        = $false
$script:Ps1RunOutput    = ""
$script:Ps1RunExitCode  = 0
$script:Ps1RunError     = ""

function Test-TcpPortOpen {
    param([string]$HostName = "127.0.0.1", [int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        $ok = $iar.AsyncWaitHandle.WaitOne(1200, $false)
        $connected = ($ok -and $client.Connected)
        $client.Close()
        return $connected
    }
    catch { return $false }
}

function Test-NacosHttp {
    param([string]$Addr = "127.0.0.1:8848")
    try {
        $resp = Invoke-WebRequest -Uri ("http://" + $Addr + "/nacos/") -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        return ($resp.Content -match "Nacos")
    }
    catch { return $false }
}

function Invoke-StartServicesPs1 {
    # run deploy-start-services.ps1 once, cache output + exit code
    if ($script:Ps1RunAttempted) { return }
    $script:Ps1RunAttempted = $true
    if (-not $ps1Exists) {
        $script:Ps1RunSkipped = $true
        return
    }
    if (-not $envJsonExists) {
        $script:Ps1RunSkipped = $true
        return
    }
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        # PS 5.1: Write-Host writes to information stream (6); capture 6>&1 so
        # [PASS]/[SKIP] dynamic assertions see the real script output (fix A).
        $script:Ps1RunOutput = (& $servicesPs1 6>&1 2>&1 | Out-String)
        if ($null -eq $LASTEXITCODE) { $script:Ps1RunExitCode = 0 } else { $script:Ps1RunExitCode = $LASTEXITCODE }
        $script:Ps1RunOk = $true
    }
    catch {
        $script:Ps1RunExitCode = 1
        $script:Ps1RunError = $_.Exception.Message
    }
    finally {
        $ErrorActionPreference = $oldEap
    }
}

# single cached run for dynamic FT scenarios
Write-Output ""
Write-Output "--- dynamic FT section: single cached run of deploy-start-services.ps1 ---"
Invoke-StartServicesPs1
if ($script:Ps1RunSkipped) {
    Write-Output "[INFO] dynamic .ps1 run skipped (deploy-start-services.ps1 or deploy/env.json missing); FT-092~FT-102 dynamic assertions -> SKIP"
}

# port / host constants from env.json defaults (assertions never print credentials)
$dbHost     = "127.0.0.1"
$redisHost  = "127.0.0.1"
$dbPort     = 3306
$redisPort  = 6379
$nacosPort  = 8848

# ============================================================================
# FT-092: MariaDB not running -> auto start + probe confirm 'pass' (P0, env-gated)
# ============================================================================
$dbUpBefore = Test-TcpPortOpen -HostName $dbHost -Port $dbPort
if ($script:Ps1RunOk -and (-not $dbUpBefore)) {
    $dbUpAfter = Test-TcpPortOpen -HostName $dbHost -Port $dbPort
    $mariadbMentioned = $script:Ps1RunOutput.Contains("MariaDB")
    $passMentioned    = $script:Ps1RunOutput.Contains("[" + $cjkPass + "]")
    Assert-Test -CaseId "FT-092-1" -Name "MariaDB not running -> auto start + probe confirm 'pass', TCP 3306 reachable after run (dynamic)" `
        -Condition ($mariadbMentioned -and $passMentioned -and $dbUpAfter) `
        -Detail ("MariaDB section mentioned=$mariadbMentioned, [pass] present=$passMentioned, TCP $dbPort after run=$dbUpAfter (before=$dbUpBefore)")
}
else {
    Skip-Test -CaseId "FT-092-1" -Name "MariaDB not running -> auto start + probe confirm 'pass' (dynamic)" `
        -Detail "precondition not met (MariaDB already running or run skipped); static coverage via UT-164/169/172"
}

# ============================================================================
# FT-093: Redis not running -> auto start + ping confirm 'pass' (P0, env-gated)
# ============================================================================
$redisUpBefore = Test-TcpPortOpen -HostName $redisHost -Port $redisPort
if ($script:Ps1RunOk -and (-not $redisUpBefore)) {
    $redisUpAfter = Test-TcpPortOpen -HostName $redisHost -Port $redisPort
    $redisMentioned = $script:Ps1RunOutput.Contains("Redis")
    $passMentioned  = $script:Ps1RunOutput.Contains("[" + $cjkPass + "]")
    Assert-Test -CaseId "FT-093-1" -Name "Redis not running -> auto start + ping confirm 'pass', TCP 6379 reachable after run (dynamic)" `
        -Condition ($redisMentioned -and $passMentioned -and $redisUpAfter) `
        -Detail ("Redis section mentioned=$redisMentioned, [pass] present=$passMentioned, TCP $redisPort after run=$redisUpAfter (before=$redisUpBefore)")
}
else {
    Skip-Test -CaseId "FT-093-1" -Name "Redis not running -> auto start + ping confirm 'pass' (dynamic)" `
        -Detail "precondition not met (Redis already running or run skipped); static coverage via UT-164/169/172"
}

# ============================================================================
# FT-094: Nacos not running -> startup script + HTTP confirm 'pass' (P0, env-gated)
# ============================================================================
$nacosUpBefore = Test-NacosHttp -Addr ("127.0.0.1:" + $nacosPort)
if ($script:Ps1RunOk -and (-not $nacosUpBefore)) {
    $nacosUpAfter = Test-NacosHttp -Addr ("127.0.0.1:" + $nacosPort)
    $nacosMentioned = $script:Ps1RunOutput.Contains("Nacos")
    $passMentioned  = $script:Ps1RunOutput.Contains("[" + $cjkPass + "]")
    Assert-Test -CaseId "FT-094-1" -Name "Nacos not running -> startup script + HTTP probe confirm 'pass', 8848 HTTP reachable after run (dynamic)" `
        -Condition ($nacosMentioned -and $passMentioned -and $nacosUpAfter) `
        -Detail ("Nacos section mentioned=$nacosMentioned, [pass] present=$passMentioned, HTTP $nacosPort after run=$nacosUpAfter (before=$nacosUpBefore)")
}
else {
    Skip-Test -CaseId "FT-094-1" -Name "Nacos not running -> startup script + HTTP probe confirm 'pass' (dynamic)" `
        -Detail "precondition not met (Nacos already running or run skipped); static coverage via UT-164/169/172"
}

# ============================================================================
# FT-095: already running -> idempotent skip 'already running', no failure (P0, dynamic)
# ============================================================================
$allUpBefore = (Test-TcpPortOpen -HostName $dbHost -Port $dbPort) -and
               (Test-TcpPortOpen -HostName $redisHost -Port $redisPort) -and
               (Test-NacosHttp -Addr ("127.0.0.1:" + $nacosPort))
if ($script:Ps1RunOk -and $allUpBefore) {
    $alreadyMentioned = $script:Ps1RunOutput.Contains($cjkRunOk) -or $script:Ps1RunOutput.Contains($cjkAlready + $cjkRunning)
    Assert-Test -CaseId "FT-095-1" -Name "all three services already running -> idempotent skip 'already running', exit code 0 (dynamic)" `
        -Condition ($alreadyMentioned -and ($script:Ps1RunExitCode -eq 0)) `
        -Detail ("'already running' mentioned=$alreadyMentioned, exit code=$($script:Ps1RunExitCode) (0 expected)")
}
else {
    Skip-Test -CaseId "FT-095-1" -Name "all three services already running -> idempotent skip 'already running' (dynamic)" `
        -Detail "precondition not met (not all services were running before run); static coverage via UT-169/170/175"
}

# ============================================================================
# FT-096: not installed -> no start, 'please install', count fail, continue (P0, env-gated)
# ============================================================================
$redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
$mysqldCmd = Get-Command mysqld -ErrorAction SilentlyContinue
$notInstalledSample = ($null -eq $redisCli -and (-not $redisUpBefore))
if ($script:Ps1RunOk -and $notInstalledSample) {
    $notinstMentioned = $script:Ps1RunOutput.Contains($cjkInstFirst)
    Assert-Test -CaseId "FT-096-1" -Name "not-installed service (redis-cli absent) -> 'not installed, please install first' mentioned, no start attempted, counted as failure (dynamic)" `
        -Condition $notinstMentioned `
        -Detail ("'not installed, please install first' mentioned=$notinstMentioned; redis-cli absent=$notInstalledSample")
}
else {
    Skip-Test -CaseId "FT-096-1" -Name "not-installed service -> 'please install' + count fail + continue (dynamic)" `
        -Detail "precondition not met (redis-cli present / service may be installed); static coverage via UT-170"
}

# ============================================================================
# FT-097: JDK check only, no start operation (P0, dynamic)
# ============================================================================
if ($script:Ps1RunOk) {
    $jdkConclusion = ($script:Ps1RunOutput.Contains($cjkReady) -or
                      $script:Ps1RunOutput.Contains($cjkUsable) -or
                      $script:Ps1RunOutput.Contains($cjkUnusable) -or
                      $script:Ps1RunOutput.Contains($cjkFail))
    $jdkNoStart     = (-not $script:Ps1RunOutput.Contains($cjkTrystart + "JDK")) -and
                      (-not $script:Ps1RunOutput.Contains($cjkStartok + "JDK"))
    Assert-Test -CaseId "FT-097-1" -Name "JDK section outputs availability conclusion (ready/usable/unusable/fail), no JDK start operation (dynamic)" `
        -Condition ($jdkConclusion -and $jdkNoStart) `
        -Detail ("JDK conclusion present=$jdkConclusion, no JDK 'try start/start ok' phrase=$jdkNoStart; 'no start' also statically covered by UT-171")
}
else {
    Skip-Test -CaseId "FT-097-1" -Name "JDK section outputs availability conclusion only (dynamic)" `
        -Detail "dynamic run skipped; static coverage via UT-171"
}

# ============================================================================
# FT-098: startup timeout -> 'warning' + guidance, no false pass (P0, env-gated)
# NOTE: trigger on the "[warning]" bracket prefix only. A bare "warning" word
# also appears in the summary line ("warn 0 items") of an all-pass run and
# would falsely trigger this scenario.
# ============================================================================
if ($script:Ps1RunOk -and $script:Ps1RunOutput.Contains("[" + $cjkWarn + "]")) {
    $guidancePresent = $script:Ps1RunOutput.Contains($cjkRetry) -or
                       $script:Ps1RunOutput.Contains($cjkManual) -or
                       $script:Ps1RunOutput.Contains($cjkAdmin)
    $noFalsePass = -not ($script:Ps1RunOutput.Contains($cjkPass + $cjkTimeout))
    Assert-Test -CaseId "FT-098-1" -Name "timeout branch -> 'warning' + processing guidance (wait-retry / manual check / permission), no false pass (dynamic)" `
        -Condition ($guidancePresent -and $noFalsePass) `
        -Detail ("guidance present=$guidancePresent, no 'pass'+timeout phrase=$noFalsePass; timeout mechanics statically covered by UT-173")
}
else {
    Skip-Test -CaseId "FT-098-1" -Name "startup timeout -> 'warning' + guidance, no false pass (dynamic)" `
        -Detail "precondition not met (no '[warning]' prefix in run output; summary line 'warn 0 items' is not a warning); static coverage via UT-173"
}

# ============================================================================
# FT-099: permission boundary -> admin/sudo guidance (P1, env-gated)
# NOTE: trigger on the "[failure]" bracket prefix only. A bare "failure" word
# also appears in the summary line ("fail 0 items") of an all-pass run and
# would falsely trigger this scenario.
# ============================================================================
$isAdmin = $false
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
catch { $isAdmin = $false }

if ($script:Ps1RunOk -and (-not $isAdmin) -and $script:Ps1RunOutput.Contains("[" + $cjkFail + "]")) {
    $permHint = $script:Ps1RunOutput.Contains($cjkAdmin) -or
                $script:Ps1RunOutput.Contains("sudo") -or
                $script:Ps1RunOutput.Contains("administrator")
    Assert-Test -CaseId "FT-099-1" -Name "non-admin shell + failure -> permission guidance (run as administrator / sudo) not silently swallowed (dynamic)" `
        -Condition $permHint `
        -Detail ("permission hint present=$permHint; admin hints: " + $cjkAdmin + " / sudo / administrator")
}
else {
    Skip-Test -CaseId "FT-099-1" -Name "permission boundary -> admin/sudo guidance (dynamic)" `
        -Detail "precondition not met (admin shell or no '[failure]' prefix in output or run skipped); static coverage via UT-173/175"
}

# ============================================================================
# FT-100: startup order MariaDB -> Redis -> Nacos in output (P0, dynamic)
# ============================================================================
$mIdx = $script:Ps1RunOutput.IndexOf("MariaDB")
$rIdx = $script:Ps1RunOutput.IndexOf("Redis")
$nIdx = $script:Ps1RunOutput.IndexOf("Nacos")
if ($script:Ps1RunOk -and ($mIdx -ge 0) -and ($rIdx -ge 0) -and ($nIdx -ge 0)) {
    $orderOk = ($mIdx -lt $rIdx) -and ($rIdx -lt $nIdx)
    Assert-Test -CaseId "FT-100-1" -Name "startup order in run output: MariaDB -> Redis -> Nacos (DB/cache before registry, SAD contract, dynamic)" `
        -Condition $orderOk `
        -Detail ("output index MariaDB=$mIdx, Redis=$rIdx, Nacos=$nIdx (ascending expected)")
}
else {
    Skip-Test -CaseId "FT-100-1" -Name "startup order MariaDB -> Redis -> Nacos in output (dynamic)" `
        -Detail "precondition not met (service names not all present in output or run skipped); static coverage via UT-169"
}

# ============================================================================
# FT-101: output grading summary + exit code contract (P0, dynamic)
# Scenario-aware assertion:
#   all pass     -> [pass] prefix + summary + exit 0 (no [warn]/[fail] prefix)
#   warn only    -> [warn] prefix + summary + exit 0
#   any failure  -> [fail] prefix + summary + exit 1
# ============================================================================
if ($script:Ps1RunOk) {
    $hasPassPrefix = $script:Ps1RunOutput.Contains("[" + $cjkPass + "]")
    $hasWarnPrefix = $script:Ps1RunOutput.Contains("[" + $cjkWarn + "]")
    $hasFailPrefix = $script:Ps1RunOutput.Contains("[" + $cjkFail + "]")
    $hasSummary    = $script:Ps1RunOutput.Contains($cjkSummary)
    $exitInRange   = ($script:Ps1RunExitCode -eq 0) -or ($script:Ps1RunExitCode -eq 1)
    # contract: any [failure] prefix -> exit 1; otherwise (all pass / warn only) -> exit 0
    $exitContract  = if ($hasFailPrefix) { ($script:Ps1RunExitCode -eq 1) } else { ($script:Ps1RunExitCode -eq 0) }
    Assert-Test -CaseId "FT-101-1" -Name "output grading [pass]/[warn]/[fail] prefixes + summary counts + exit code contract (0 all pass / 1 any fail, F-011, dynamic)" `
        -Condition ($hasPassPrefix -and $hasSummary -and $exitInRange -and $exitContract) `
        -Detail ("[pass]=$hasPassPrefix, [warn]=$hasWarnPrefix, [fail]=$hasFailPrefix, summary=$hasSummary, exit=$($script:Ps1RunExitCode) (contract: 1 when [failure], else 0)")
}
else {
    Skip-Test -CaseId "FT-101-1" -Name "output grading summary + exit code contract (dynamic)" `
        -Detail "dynamic run skipped; static coverage via UT-175"
}

# ============================================================================
# FT-102: password masking - no DB_PASSWORD/REDIS_PASSWORD plaintext (P0, security)
# ============================================================================
$dbPwd = $null
$redisPwd = $null
if ($envJsonExists) {
    try {
        $envObj = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $dbPwd    = $envObj.DB_PASSWORD
        $redisPwd = $envObj.REDIS_PASSWORD
    }
    catch { }
}
if ($script:Ps1RunOk -and $dbPwd) {
    $dbLeak = $script:Ps1RunOutput.Contains($dbPwd)
    Assert-Test -CaseId "FT-102-1" -Name "run output does not contain DB_PASSWORD plaintext value from env.json (dynamic, security)" `
        -Condition (-not $dbLeak) `
        -Detail ("DB_PASSWORD plaintext leak in output=$dbLeak (expected absent; value length checked, never printed)")
}
else {
    Skip-Test -CaseId "FT-102-1" -Name "run output does not contain DB_PASSWORD plaintext (dynamic)" `
        -Detail "dynamic run skipped or DB_PASSWORD absent; static coverage via UT-174"
}
if ($script:Ps1RunOk -and $redisPwd) {
    $redisLeak = $script:Ps1RunOutput.Contains($redisPwd)
    Assert-Test -CaseId "FT-102-2" -Name "run output does not contain REDIS_PASSWORD plaintext value from env.json (dynamic, security)" `
        -Condition (-not $redisLeak) `
        -Detail ("REDIS_PASSWORD plaintext leak in output=$redisLeak (expected absent; value length checked, never printed)")
}
else {
    Skip-Test -CaseId "FT-102-2" -Name "run output does not contain REDIS_PASSWORD plaintext (dynamic)" `
        -Detail "dynamic run skipped or REDIS_PASSWORD absent; static coverage via UT-174"
}

# ============================================================================
# FT-103: env.json missing -> env.example.json guidance + non-zero exit (P0)
# ============================================================================
$missingRunOutput = ""
$missingRunExit = -1
# Fix B: backup file must be an independent filename under deploy dir, not a
# Join-Path onto the env.json file itself (which produced an invalid path).
$envJsonBak = Join-Path $deployDir ".env.json.bak-cso-test"
if ($envJsonExists) {
    # switch ErrorActionPreference BEFORE any Copy-Item/Remove-Item so a failure
    # here does not abort the whole test script (fix B)
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $copied = $false
    try {
        Copy-Item -LiteralPath $envJsonPath -Destination $envJsonBak -Force
        $copied = $true
        Remove-Item -LiteralPath $envJsonPath -Force
        # Fix C: run in a SEPARATE powershell process AND clear the load-env
        # injected keys first. load-env.ps1 injects session environment
        # variables (Set-Item Env:*) into the current process, and child
        # processes inherit them - so a plain `powershell -File` child would
        # still see stale DB_HOST/NACOS_ADDR/etc. from the earlier
        # normal-scenario run and mask the missing-env.json behavior.
        $envKeysToClear = @(
            "NACOS_ADDR", "NACOS_HOME",
            "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD", "DB_USER",
            "DB_SERVICE_NAME", "DB_PROCESS_NAME",
            "REDIS_HOST", "REDIS_PORT", "REDIS_PASSWORD", "REDIS_DATABASE",
            "REDIS_SERVICE_NAME", "REDIS_PROCESS_NAME",
            "RSA_PRIVATE_KEY", "RSA_PUBLIC_KEY", "MARIADB_ROOT_PASSWORD", "TZ"
        )
        $clearExpr = ($envKeysToClear | ForEach-Object { "Remove-Item Env:$_ -ErrorAction SilentlyContinue" }) -join "; "
        $missingCmd = "$clearExpr; & '$servicesPs1'; exit `$LASTEXITCODE"
        $missingRunOutput = (& powershell -NoProfile -ExecutionPolicy Bypass -Command $missingCmd 6>&1 2>&1 | Out-String)
        if ($null -eq $LASTEXITCODE) { $missingRunExit = 0 } else { $missingRunExit = $LASTEXITCODE }
    }
    catch {
        $missingRunExit = 1
    }
    finally {
        if ($copied -and (Test-Path -LiteralPath $envJsonBak)) {
            try {
                Copy-Item -LiteralPath $envJsonBak -Destination $envJsonPath -Force
                Remove-Item -LiteralPath $envJsonBak -Force
            }
            catch { }
        }
        $ErrorActionPreference = $oldEap
    }
    $hasCopyHint = $missingRunOutput.Contains("env.example")
    Assert-Test -CaseId "FT-103-1" -Name "env.json missing -> load-env guidance (copy env.example.json) + non-zero exit (dynamic, F-001)" `
        -Condition ($hasCopyHint -and ($missingRunExit -ne 0)) `
        -Detail ("env.example hint=$hasCopyHint, exit=$missingRunExit (non-zero expected); env.json restored")
}
else {
    Skip-Test -CaseId "FT-103-1" -Name "env.json missing -> guidance + non-zero exit (dynamic)" `
        -Detail "no env.json present; cannot simulate missing scenario"
}

# ============================================================================
# FT-104: dual-platform behavior consistency (P1, SKIP if no bash/WSL)
# ============================================================================
if ($bashUsable -and $shExists) {
    $wslSh = $servicesSh
    if ($wslSh -match "^([A-Za-z]):\\(.*)$") {
        $wslSh = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
    }
    $bashOut = (& bash -n $wslSh 2>&1)
    $bashExit = $LASTEXITCODE
    $shGrading = $shText.Contains("[" + $cjkPass + "]") -and $shText.Contains("[" + $cjkWarn + "]") -and $shText.Contains("[" + $cjkFail + "]")
    $ps1Grading = $ps1Text.Contains("[" + $cjkPass + "]") -and $ps1Text.Contains("[" + $cjkWarn + "]") -and $ps1Text.Contains("[" + $cjkFail + "]")
    Assert-Test -CaseId "FT-104-1" -Name "dual-platform consistency: bash -n pass + same [pass]/[warn]/[fail] grading text in both scripts, no emoji (dynamic + static)" `
        -Condition (($bashExit -eq 0) -and $shGrading -and $ps1Grading) `
        -Detail ("bash -n exit=$bashExit, .sh grading=$shGrading, .ps1 grading=$ps1Grading")
}
else {
    Skip-Test -CaseId "FT-104-1" -Name "dual-platform behavior consistency (dynamic)" `
        -Detail "bash/WSL unavailable; static dual-platform coverage via UT-165/166/169~176"
}

# ============================================================================
# summary + exit code
# ============================================================================
Write-Output ""
Write-Output ("=" * 70)
Write-Output "cso-unit-test-start-services-v0.2.7 (TASK-004) summary"
Write-Output ("Passed : {0}" -f $script:Pass)
Write-Output ("Failed : {0}" -f $script:Fail)
Write-Output ("Skipped: {0}" -f $script:Skip)
if ($script:FailedCases.Count -gt 0) {
    Write-Output "--- failed cases ---"
    $script:FailedCases | ForEach-Object { Write-Output "  $_" }
}
if ($script:SkippedCases.Count -gt 0) {
    Write-Output "--- skipped cases (environment-gated preconditions, not failures) ---"
    $script:SkippedCases | ForEach-Object { Write-Output "  $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) {
    Write-Output ("Result: FAILED ({0} failed, {1} passed, {2} skipped)" -f $script:Fail, $script:Pass, $script:Skip)
    exit 1
}
Write-Output ("Result: PASSED ({0} passed, {1} skipped)" -f $script:Pass, $script:Skip)
exit 0
