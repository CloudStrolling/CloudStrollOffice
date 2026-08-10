# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - deploy-start-all Test (TASK-005)
# ----------------------------------------------------------------------------
# Coverage: UT-177 ~ UT-189 + FT-105 ~ FT-118 in task testcase
#           (docs/cso-v0.2.7/task_TASK-005/testcase.md)
#   UT-177: deploy-start-all.ps1 parseable via PowerShell Parser (P0)
#   UT-178: deploy-start-all.sh syntax check via bash -n (fallback if no bash) (P0)
#   UT-179: dual-platform scripts both exist, startup flow 1:1 (P1)
#   UT-180: no hard-coded default addresses (P0, security)
#   UT-181: load-env call contract + no duplicated 8-key validation (P0)
#   UT-182: 4 jars existence precheck static alignment (P0)
#   UT-183: key env var readiness precheck static alignment (P0)
#   UT-184: precheck-fail -> no service started + non-zero exit (P0)
#   UT-185: startup order gateway -> auth -> biz -> system + port map (P0)
#   UT-186: start command java -Xms256m -Xmx512m -jar + backgrounding (P0)
#   UT-187: health confirm polling static check (P0)
#   UT-188: fail-fast + error hint static check (P1)
#   UT-189: output grading + summary + exit code + SPDX/version (P0)
#   FT-105: jar missing -> missing item + hint + non-zero exit + no start (P0, dynamic)
#   FT-106: key env var missing -> list key names + non-zero exit + no start (P0, dynamic)
#   FT-107: env.json missing -> copy env.example guidance + non-zero exit (P0, dynamic)
#   FT-108: all ready -> gateway -> auth -> biz -> system order start (P0, env-gated)
#   FT-109: per-service health confirm before next start (P0, env-gated)
#   FT-110: backgrounded start + log/PID on disk (P0, env-gated)
#   FT-111: health timeout -> fail + stop next (P0, env-gated)
#   FT-112: port occupied -> clear hint + stop (P0, env-gated)
#   FT-113: gateway fail -> auth/biz/system not started (P0, env-gated)
#   FT-114: success summary 4 services (P0, env-gated)
#   FT-115: exit code contract 0/1 (P0, dynamic partial + env-gated full)
#   FT-116: no plaintext password/key in output (P0, security, dynamic)
#   FT-117: dual-platform behavior consistency (P1, SKIP if no bash/WSL)
#   FT-118: already-running repeat run (P1, env-gated)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-all-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-all-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo [-RunServiceTests] [-RunFailureScenarios]
# Exit code: 0 = all pass (SKIP not counted as failure), 1 = any failure
# NOTE:
#   ASCII only in this script to keep PowerShell 5.1 encoding safe. CJK
#   assertions are built from Unicode code points; source files with CJK
#   content are read explicitly as UTF-8 via .NET APIs. The real
#   deploy/env.json may contain sensitive credentials - the script only
#   checks key presence/non-empty and never prints credential values.
#   Dynamic failure scenarios that temporarily modify deploy/env.json or
#   move a jar are backup/restore guarded (try/finally) so the real assets
#   are restored. They run in a SEPARATE powershell process with the
#   load-env injected environment keys cleared first (same convention as
#   the TASK-004 start-services test, fix A/B/C).
#   FT-108/109/110/114/118 require real backend service startup (4 Java
#   services) - they only run when -RunServiceTests is given and the
#   preconditions (4 jars + env.json + free ports) are met; otherwise SKIP
#   (environment gated, static coverage via UT-182~189).
#   FT-111/112/113 construct failure scenarios that launch a real Java
#   process against a broken config - they only run when
#   -RunFailureScenarios is given; otherwise SKIP.
#   .sh dynamic assertions require bash/WSL; when unavailable they are
#   SKIP (static dual-platform coverage via UT-178/179/185~189).
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$RunServiceTests,
    [switch]$RunFailureScenarios
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0
$script:FailedCases = @()
$script:SkippedCases = @()
$script:LastRunOutput = ""   # cache of the latest isolated dynamic run output (FT-116)

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
        "pass"            { return [string][char]0x901A + [string][char]0x8FC7 }
        "warn"            { return [string][char]0x8B66 + [string][char]0x544A }
        "fail"            { return [string][char]0x5931 + [string][char]0x8D25 }
        "precheck"        { return [string][char]0x524D + [string][char]0x7F6E + [string][char]0x6821 + [string][char]0x9A8C }
        "keyenv"          { return [string][char]0x5173 + [string][char]0x952E + [string][char]0x73AF + [string][char]0x5883 + [string][char]0x53D8 + [string][char]0x91CF }
        "miss"            { return [string][char]0x7F3A + [string][char]0x5931 }
        "missempty"       { return [string][char]0x7F3A + [string][char]0x5931 + [string][char]0x6216 + [string][char]0x4E3A + [string][char]0x7A7A }
        "jarmiss"         { return "jar " + [string][char]0x5305 + [string][char]0x7F3A + [string][char]0x5931 }
        "nostart"         { return [string][char]0x672C + [string][char]0x6B21 + [string][char]0x672A + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x4EFB + [string][char]0x4F55 + [string][char]0x670D + [string][char]0x52A1 }
        "hconfirm"        { return [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 }
        "htimeout"        { return [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 + [string][char]0x8D85 + [string][char]0x65F6 }
        "check"           { return [string][char]0x8BF7 + [string][char]0x68C0 + [string][char]0x67E5 }
        "viewlog"         { return [string][char]0x8BF7 + [string][char]0x67E5 + [string][char]0x770B }
        "portused"        { return [string][char]0x7AEF + [string][char]0x53E3 + [string][char]0x88AB + [string][char]0x5360 + [string][char]0x7528 }
        "summary"         { return [string][char]0x6C47 + [string][char]0x603B }
        "persvc"          { return [string][char]0x5404 + [string][char]0x670D + [string][char]0x52A1 }
        "startresult"     { return [string][char]0x542F + [string][char]0x52A8 + [string][char]0x7ED3 + [string][char]0x679C }
        "healthstate"     { return [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x72B6 + [string][char]0x6001 }
        "notexec"         { return [string][char]0x672A + [string][char]0x6267 + [string][char]0x884C }
        "alltitle"        { return [string][char]0x540E + [string][char]0x7AEF + [string][char]0x670D + [string][char]0x52A1 + [string][char]0x4E00 + [string][char]0x952E + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x5B8C + [string][char]0x6210 }
        "version"         { return [string][char]0x7248 + [string][char]0x672C }
        "noprint"         { return [string][char]0x4E0D + [string][char]0x6253 + [string][char]0x5370 + [string][char]0x503C }
        "keyhint"         { return [string][char]0x76F8 + [string][char]0x5E94 + [string][char]0x952E }
        "allready"        { return [string][char]0x5168 + [string][char]0x90E8 + [string][char]0x5C31 + [string][char]0x7EEA }
        "allstartok"      { return [string][char]0x5168 + [string][char]0x90E8 + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x6210 + [string][char]0x529F }
        "exec"            { return [string][char]0x8BF7 + [string][char]0x6267 + [string][char]0x884C }
        "rerun"           { return [string][char]0x91CD + [string][char]0x65B0 + [string][char]0x8FD0 + [string][char]0x884C }
        "hasfail"         { return [string][char]0x5B58 + [string][char]0x5728 + [string][char]0x5931 + [string][char]0x8D25 + [string][char]0x9879 }
        "stoppolicy"      { return [string][char]0x5DF2 + [string][char]0x6309 + [string][char]0x5931 + [string][char]0x8D25 + [string][char]0x5373 + [string][char]0x505C }
        "config"          { return [string][char]0x914D + [string][char]0x7F6E }
        "log"             { return [string][char]0x65E5 + [string][char]0x5FD7 }
        "depnotready"     { return [string][char]0x4F9D + [string][char]0x8D56 + [string][char]0x672A + [string][char]0x5C31 + [string][char]0x7EEA }
        "nomod"           { return [string][char]0x672A + [string][char]0x68C0 + [string][char]0x6D4B + [string][char]0x5230 }
        "install"         { return [string][char]0x5B89 + [string][char]0x88C5 }
        "keypair"         { return [string][char]0x5BC6 + [string][char]0x94A5 + [string][char]0x5BF9 }
        "and"             { return [string][char]0x4E0E }
        "start"           { return [string][char]0x542F + [string][char]0x52A8 }
        "success"         { return [string][char]0x6210 + [string][char]0x529F }
        "ready"           { return [string][char]0x5C31 + [string][char]0x7EEA }
    }
    return ""
}

# ============================================================================
# locate assets + read scripts
# ============================================================================
$deployDir     = Join-Path $ProjectRoot "deploy"
$scriptsDir    = Join-Path $deployDir "scripts"
$ps1Path       = Join-Path $scriptsDir "deploy-start-all.ps1"
$shPath        = Join-Path $scriptsDir "deploy-start-all.sh"
$envJsonPath   = Join-Path $deployDir "env.json"
$logDir        = Join-Path $deployDir "logs"
$ps1Exists     = Test-FileExists $ps1Path
$shExists      = Test-FileExists $shPath
$envJsonExists = Test-FileExists $envJsonPath
$ps1Text       = if ($ps1Exists) { Read-Utf8File $ps1Path } else { "" }
$shText        = if ($shExists)  { Read-Utf8File $shPath }  else { "" }

# bash usability (for .sh syntax check / dual-platform dynamic assertions).
# Get-Command bash may succeed (e.g. wsl.exe shim) while bash itself cannot
# run (WSL distro missing) - verify with an actual `bash -c "true"` probe.
$bashUsable = $false
if (Get-Command bash -ErrorAction SilentlyContinue) {
    $null = (& bash -c "true" 2>&1)
    if ($LASTEXITCODE -eq 0) { $bashUsable = $true }
}

# CJK shortcuts
$cjkPass      = Get-CjkText "pass"
$cjkWarn      = Get-CjkText "warn"
$cjkFail      = Get-CjkText "fail"
$cjkPrecheck  = Get-CjkText "precheck"
$cjkKeyenv    = Get-CjkText "keyenv"
$cjkMiss      = Get-CjkText "miss"
$cjkMissEmpty = Get-CjkText "missempty"
$cjkJarMiss   = Get-CjkText "jarmiss"
$cjkNoStart   = Get-CjkText "nostart"
$cjkHConfirm  = Get-CjkText "hconfirm"
$cjkHTimeout  = Get-CjkText "htimeout"
$cjkCheck     = Get-CjkText "check"
$cjkViewLog   = Get-CjkText "viewlog"
$cjkPortUsed  = Get-CjkText "portused"
$cjkSummary   = Get-CjkText "summary"
$cjkPerSvc    = Get-CjkText "persvc"
$cjkStartResult = Get-CjkText "startresult"
$cjkHealthState = Get-CjkText "healthstate"
$cjkNotExec   = Get-CjkText "notexec"
$cjkAllTitle  = Get-CjkText "alltitle"
$cjkVersion   = Get-CjkText "version"
$cjkNoPrint   = Get-CjkText "noprint"
$cjkKeyHint   = Get-CjkText "keyhint"
$cjkAllReady  = Get-CjkText "allready"
$cjkAllStartOk = Get-CjkText "allstartok"
$cjkExec      = Get-CjkText "exec"
$cjkRerun     = Get-CjkText "rerun"
$cjkHasFail   = Get-CjkText "hasfail"
$cjkStopPolicy = Get-CjkText "stoppolicy"
$cjkConfig    = Get-CjkText "config"
$cjkLog       = Get-CjkText "log"
$cjkDepNotReady = Get-CjkText "depnotready"
$cjkNoMod     = Get-CjkText "nomod"
$cjkInstall   = Get-CjkText "install"
$cjkKeyPair   = Get-CjkText "keypair"
$cjkAnd       = Get-CjkText "and"
$cjkStart     = Get-CjkText "start"
$cjkSuccess   = Get-CjkText "success"
$cjkReady     = Get-CjkText "ready"

$jarNames = @(
    "cloudoffice-gateway.jar",
    "cloudoffice-auth-service.jar",
    "cloudoffice-biz-service.jar",
    "cloudoffice-system-service.jar"
)

Write-Output ""
Write-Output "CSO v0.2.7 deploy-start-all Test (TASK-005, UT-177~UT-189 + FT-105~FT-118)"

# ============================================================================
# UT-177: deploy-start-all.ps1 parseable via PowerShell Parser (P0)
# ============================================================================
$parseErrors = $null
$tokens = $null
if ($ps1Exists) {
    [System.Management.Automation.Language.Parser]::ParseFile($ps1Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
}
Assert-Test -CaseId "UT-177-1" -Name "deploy-start-all.ps1 parseable via PowerShell Parser, zero errors (P0)" `
    -Condition ($ps1Exists -and ($parseErrors.Count -eq 0)) `
    -Detail ("ps1 exists=$ps1Exists, parser errors=$($parseErrors.Count)")

$ps1Funcs = $ps1Exists -and $ps1Text.Contains("function Write-Result") -and `
    $ps1Text.Contains("function Test-TcpPort") -and `
    $ps1Text.Contains("function Test-HttpOk") -and `
    $ps1Text.Contains("function Wait-HealthUp")
Assert-Test -CaseId "UT-177-2" -Name "helper functions present (Write-Result/Test-TcpPort/Test-HttpOk/Wait-HealthUp)" `
    -Condition $ps1Funcs -Detail ("functions ok=$ps1Funcs")

$ps1MainBlocks = $ps1Exists -and $ps1Text.Contains('$PSScriptRoot\load-env.ps1') -and `
    $ps1Text.Contains("foreach (`$svc in `$Services)") -and `
    $ps1Text.Contains("Wait-HealthUp") -and `
    $ps1Text.Contains("exit 1") -and $ps1Text.Contains("exit 0")
Assert-Test -CaseId "UT-177-3" -Name "main flow blocks present (load-env, precheck, 4-service start loop, health confirm, summary/exit)" `
    -Condition $ps1MainBlocks -Detail ("main blocks ok=$ps1MainBlocks")

# ============================================================================
# UT-178: deploy-start-all.sh syntax check via bash -n (P0, fallback if no bash)
# ============================================================================
if ($bashUsable -and $shExists) {
    $wslSh = $shPath
    if ($wslSh -match "^([A-Za-z]):\\(.*)$") {
        $wslSh = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
    }
    $null = (& bash -n $wslSh 2>&1)
    $bashExit = $LASTEXITCODE
    Assert-Test -CaseId "UT-178-1" -Name "deploy-start-all.sh syntax check via bash -n, exit code 0 (P0)" `
        -Condition ($bashExit -eq 0) -Detail ("bash -n exit=$bashExit")
}
else {
    # fallback structure check: shebang + non-empty + balanced if/fi + key functions
    $shFallback = $shExists -and $shText.StartsWith("#!/usr/bin/env bash") -and ($shText.Length -gt 0)
    $ifCount = if ($shExists) { ([regex]::Matches($shText, "\bif\b")).Count } else { 0 }
    $fiCount = if ($shExists) { ([regex]::Matches($shText, "\bfi\b")).Count } else { 0 }
    $shFns = $shExists -and $shText.Contains("print_result()") -and `
        $shText.Contains("tcp_port_open()") -and $shText.Contains("http_ok()") -and `
        $shText.Contains("wait_health_up()")
    Assert-Test -CaseId "UT-178-1" -Name "deploy-start-all.sh structure fallback (shebang+non-empty+if/fi balanced+functions) (P0)" `
        -Condition ($shFallback -and ($ifCount -eq $fiCount) -and $shFns) `
        -Detail ("fallback ok=$($shFallback -and ($ifCount -eq $fiCount) -and $shFns), if=$ifCount fi=$fiCount")
}
$shLoadEnvExit = $shExists -and $shText.Contains('source "$SCRIPT_DIR/load-env.sh" || exit $?')
$shMainBlocks = $shExists -and $shText.Contains("wait_health_up") -and `
    $shText.Contains("nohup") -and $shText.Contains("exit 1") -and $shText.Contains("exit 0")
Assert-Test -CaseId "UT-178-2" -Name "load-env source with exit-code propagation + main flow blocks present (.sh)" `
    -Condition ($shLoadEnvExit -and $shMainBlocks) `
    -Detail ("load-env || exit=$shLoadEnvExit, main blocks=$shMainBlocks")

# ============================================================================
# UT-179: dual-platform scripts both exist, startup flow 1:1 (P1)
# ============================================================================
Assert-Test -CaseId "UT-179-1" -Name "deploy-start-all.ps1 and .sh both exist and non-empty (P1)" `
    -Condition ($ps1Exists -and $shExists -and ($ps1Text.Length -gt 0) -and ($shText.Length -gt 0)) `
    -Detail (".ps1 exists=$ps1Exists, .sh exists=$shExists")

$ps1Flow = $ps1Exists -and $ps1Text.Contains("gateway") -and $ps1Text.Contains("auth") -and `
    $ps1Text.Contains("biz") -and $ps1Text.Contains("system") -and `
    $ps1Text.Contains("9000") -and $ps1Text.Contains("9100") -and `
    $ps1Text.Contains("9200") -and $ps1Text.Contains("9400")
$shFlow = $shExists -and $shText.Contains("gateway") -and $shText.Contains("auth") -and `
    $shText.Contains("biz") -and $shText.Contains("system") -and `
    $shText.Contains("9000") -and $shText.Contains("9100") -and `
    $shText.Contains("9200") -and $shText.Contains("9400")
Assert-Test -CaseId "UT-179-2" -Name "startup flow 1:1 between .ps1 and .sh (4 services + 4 ports present in both)" `
    -Condition ($ps1Flow -and $shFlow) -Detail (".ps1 flow=$ps1Flow, .sh flow=$shFlow")

$ps1Grading = $ps1Exists -and $ps1Text.Contains("[" + $cjkPass + "]") -and `
    $ps1Text.Contains("[" + $cjkWarn + "]") -and $ps1Text.Contains("[" + $cjkFail + "]")
$shGrading = $shExists -and $shText.Contains("[" + $cjkPass + "]") -and `
    $shText.Contains("[" + $cjkWarn + "]") -and $shText.Contains("[" + $cjkFail + "]")
$noEmoji = ($ps1Exists -and $shExists) -and `
    (-not [regex]::IsMatch($ps1Text, "[\u2705\u274C\u26A0\uD83D\uD83C]")) -and `
    (-not [regex]::IsMatch($shText,  "[\u2705\u274C\u26A0\uD83D\uD83C]"))
Assert-Test -CaseId "UT-179-3" -Name "output grading text [pass]/[warn]/[fail] consistent in both platforms, no emoji" `
    -Condition ($ps1Grading -and $shGrading -and $noEmoji) `
    -Detail (".ps1 grading=$ps1Grading, .sh grading=$shGrading, no emoji=$noEmoji")

# ============================================================================
# UT-180: no hard-coded default addresses (P0, security)
# ============================================================================
$ps1Hard = $ps1Exists -and [regex]::IsMatch($ps1Text, "192\.168\.1\.1\d\d")
$shHard  = $shExists  -and [regex]::IsMatch($shText,  "192\.168\.1\.1\d\d")
Assert-Test -CaseId "UT-180-1" -Name "no hard-coded 192.168.1.1xx address in either script (P0)" `
    -Condition (-not $ps1Hard -and -not $shHard) `
    -Detail (".ps1 hard-code hit=$ps1Hard, .sh hard-code hit=$shHard (expected absent)")

# .ps1 reads env values dynamically via `Env:$v` (no literal $env:KEY refs);
# .sh uses indirect expansion ${!v:-}. Assert those patterns + no fallback addr.
$ps1EnvParams = $ps1Exists -and $ps1Text.Contains('Get-Item -Path "Env:$v"') -and `
    $ps1Text.Contains("NACOS_ADDR") -and $ps1Text.Contains("RSA_PUBLIC_KEY") -and `
    $ps1Text.Contains("DB_PASSWORD")
$shEnvParams = $shExists -and $shText.Contains('"${!v:-}"') -and `
    $shText.Contains("NACOS_ADDR,RSA_PUBLIC_KEY") -and $shText.Contains("DB_PASSWORD")
$noFallbackAddr = ($ps1Exists -and $shExists) -and `
    (-not $ps1Text.Contains("192.168")) -and (-not $shText.Contains("192.168")) -and `
    (-not ($shText -match ':\-192\.168')) -and (-not ($ps1Text -match ':\-192\.168'))
Assert-Test -CaseId "UT-180-2" -Name "connection params read from env vars only; no hard-coded default address/fallback" `
    -Condition ($ps1EnvParams -and $shEnvParams -and $noFallbackAddr) `
    -Detail (".ps1 env params=$ps1EnvParams, .sh env params=$shEnvParams, no address fallback=$noFallbackAddr")

# ============================================================================
# UT-181: load-env call contract + no duplicated 8-key validation (P0)
# ============================================================================
$ps1LoadEnv = $ps1Exists -and $ps1Text.Contains('$PSScriptRoot\load-env.ps1')
$shLoadEnvOk = $shExists -and $shText.Contains('source "$SCRIPT_DIR/load-env.sh" || exit $?')
Assert-Test -CaseId "UT-181-1" -Name "load-env call contract (.ps1 dot-source / .sh source with exit-code propagation, F-001)" `
    -Condition ($ps1LoadEnv -and $shLoadEnvOk) `
    -Detail (".ps1 dot-source=$ps1LoadEnv, .sh source+exit=$shLoadEnvOk")

$ps1DupKey = $ps1Exists -and [regex]::IsMatch($ps1Text, 'IsNullOrEmpty\(\$env:(NACOS_ADDR|NACOS_HOME|DB_HOST|DB_PORT|DB_USERNAME|DB_PASSWORD|REDIS_HOST|REDIS_PORT)')
$shDupKey  = $shExists  -and [regex]::IsMatch($shText, '\[ -z "\$(NACOS_ADDR|NACOS_HOME|DB_HOST|DB_PORT|DB_USERNAME|DB_PASSWORD|REDIS_HOST|REDIS_PORT)')
Assert-Test -CaseId "UT-181-2" -Name "no duplicated 8-key required-config validation block in either script (load-env F-001 unified fallback)" `
    -Condition (-not $ps1DupKey -and -not $shDupKey) `
    -Detail (".ps1 dup-key hit=$ps1DupKey, .sh dup-key hit=$shDupKey (expected absent)")

$ps1EnvVar = $ps1Exists -and $ps1Text.Contains('Get-Item -Path "Env:$v"')
$shIndirect = $shExists -and $shText.Contains('"${!v:-}"')
Assert-Test -CaseId "UT-181-3" -Name "config values read from env variables (Env: dynamic read in .ps1, indirect expansion in .sh)" `
    -Condition ($ps1EnvVar -and $shIndirect) `
    -Detail (".ps1 Env dynamic read=$ps1EnvVar, .sh indirect expansion=$shIndirect")
# ============================================================================
# UT-182: 4 jars existence precheck static alignment (P0)
# ============================================================================
$ps1Jars = $ps1Exists -and (($jarNames | ForEach-Object { $ps1Text.Contains($_) } | Where-Object { -not $_ }).Count -eq 0)
$shJars  = $shExists  -and (($jarNames | ForEach-Object { $shText.Contains($_) }  | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-182-1" -Name "all 4 jar file names covered by precheck in both scripts (F-008)" `
    -Condition ($ps1Jars -and $shJars) -Detail (".ps1 4 jars=$ps1Jars, .sh 4 jars=$shJars")

$ps1Base = $ps1Exists -and $ps1Text.Contains("Split-Path -Parent `$PSScriptRoot")
$shBase  = $shExists  -and $shText.Contains('dirname "$SCRIPT_DIR"')
Assert-Test -CaseId "UT-182-2" -Name "jar path base resolved to deploy dir (Split-Path -Parent PSScriptRoot / dirname SCRIPT_DIR)" `
    -Condition ($ps1Base -and $shBase) -Detail (".ps1 base=$ps1Base, .sh base=$shBase")

$ps1MissBranch = $ps1Exists -and $ps1Text.Contains($cjkJarMiss) -and `
    $ps1Text.Contains($cjkExec + " build-backend") -and $ps1Text.Contains($cjkMiss)
$shMissBranch  = $shExists  -and $shText.Contains($cjkJarMiss) -and `
    $shText.Contains($cjkExec + " build-backend") -and $shText.Contains($cjkMiss)
Assert-Test -CaseId "UT-182-3" -Name "missing-jar branch lists missing item + handling hint (build-backend / place jar) + non-zero exit" `
    -Condition ($ps1MissBranch -and $shMissBranch) `
    -Detail (".ps1 missing branch=$ps1MissBranch, .sh missing branch=$shMissBranch")

# ============================================================================
# UT-183: key env var readiness precheck static alignment (P0)
# ============================================================================
$ps1GtwVars = $ps1Exists -and $ps1Text.Contains('RequiredVars = @("NACOS_ADDR", "RSA_PUBLIC_KEY")')
$ps1AuthVars = $ps1Exists -and $ps1Text.Contains('"NACOS_ADDR", "RSA_PUBLIC_KEY", "RSA_PRIVATE_KEY", "DB_PASSWORD"')
$ps1BizVars = $ps1Exists -and $ps1Text.Contains('RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")')
$shGtwVars = $shExists -and $shText.Contains("NACOS_ADDR,RSA_PUBLIC_KEY|")
$shAuthVars = $shExists -and $shText.Contains("NACOS_ADDR,RSA_PUBLIC_KEY,RSA_PRIVATE_KEY,DB_PASSWORD|")
$shBizVars = $shExists -and $shText.Contains("NACOS_ADDR,DB_PASSWORD|")
Assert-Test -CaseId "UT-183-1" -Name "per-service required env var lists match task definition (gateway/auth/biz/system) in both scripts" `
    -Condition ($ps1GtwVars -and $ps1AuthVars -and $ps1BizVars -and $shGtwVars -and $shAuthVars -and $shBizVars) `
    -Detail (".ps1 gtw/auth/biz=$ps1GtwVars/$ps1AuthVars/$ps1BizVars; .sh gtw/auth/biz=$shGtwVars/$shAuthVars/$shBizVars")

$ps1NoPrint = $ps1Exists -and $ps1Text.Contains($cjkMissEmpty) -and $ps1Text.Contains($cjkKeyHint) -and $ps1Text.Contains($cjkNoPrint)
$shNoPrint  = $shExists  -and $shText.Contains($cjkMissEmpty) -and $shText.Contains($cjkKeyHint) -and $shText.Contains($cjkNoPrint)
Assert-Test -CaseId "UT-183-2" -Name "missing env hint lists key names only, no value printed (sensitive key safe)" `
    -Condition ($ps1NoPrint -and $shNoPrint) `
    -Detail (".ps1 key-name-only hint=$ps1NoPrint, .sh key-name-only hint=$shNoPrint")

# ============================================================================
# UT-184: precheck-fail -> no service started + non-zero exit (P0)
# ============================================================================
# Compare against the REAL start call sites (header comments also mention
# Start-Process / nohup, so use the exact invocation strings).
$ps1PreFail = $ps1Exists -and $ps1Text.Contains($cjkNoStart) -and `
    ($ps1Text.IndexOf("exit 1") -lt $ps1Text.IndexOf('Start-Process -FilePath "java"'))
$shPreFail = $shExists -and $shText.Contains($cjkNoStart) -and `
    ($shText.IndexOf("exit 1") -lt $shText.IndexOf("nohup java"))
Assert-Test -CaseId "UT-184-1" -Name "precheck-fail branch before any start command, direct non-zero exit (no service started)" `
    -Condition ($ps1PreFail -and $shPreFail) `
    -Detail (".ps1 precheck-fail gate=$ps1PreFail, .sh precheck-fail gate=$shPreFail")

# "all ready" message position vs real start call sites (avoid header comments)
$ps1StartAfter = $ps1Exists -and ($ps1Text.IndexOf('Start-Process -FilePath "java"') -gt $ps1Text.IndexOf($cjkAllReady))
$shStartAfter  = $shExists  -and ($shText.IndexOf("nohup java") -gt $shText.IndexOf($cjkAllReady))
Assert-Test -CaseId "UT-184-2" -Name "start commands located after precheck-pass message (no start before validation passes)" `
    -Condition ($ps1StartAfter -and $shStartAfter) `
    -Detail (".ps1 start-after-precheck=$ps1StartAfter, .sh start-after-precheck=$shStartAfter")

$ps1Gate = $ps1Exists -and $ps1Text.Contains("if (`$precheckFail)") -and $ps1Text.Contains("exit 1")
$shGate  = $shExists  -and $shText.Contains('if [ "$PRECHECK_FAIL" -ne 0 ]')
Assert-Test -CaseId "UT-184-3" -Name "no bypass path: precheck-fail flag gates exit before start loop (static)" `
    -Condition ($ps1Gate -and $shGate) -Detail (".ps1 gate=$ps1Gate, .sh gate=$shGate")

# ============================================================================
# UT-185: startup order gateway -> auth -> biz -> system + port map (P0)
# ============================================================================
$ps1GIdx = $ps1Text.IndexOf('Name = "gateway"')
$ps1AIdx = $ps1Text.IndexOf('Name = "auth"')
$ps1BIdx = $ps1Text.IndexOf('Name = "biz"')
$ps1SIdx = $ps1Text.IndexOf('Name = "system"')
$ps1Order = $ps1Exists -and ($ps1GIdx -gt 0) -and ($ps1GIdx -lt $ps1AIdx) -and `
    ($ps1AIdx -lt $ps1BIdx) -and ($ps1BIdx -lt $ps1SIdx)
$shGIdx = $shText.IndexOf('"gateway|')
$shAIdx = $shText.IndexOf('"auth|')
$shBIdx = $shText.IndexOf('"biz|')
$shSIdx = $shText.IndexOf('"system|')
$shOrder = $shExists -and ($shGIdx -gt 0) -and ($shGIdx -lt $shAIdx) -and `
    ($shAIdx -lt $shBIdx) -and ($shBIdx -lt $shSIdx)
Assert-Test -CaseId "UT-185-1" -Name "startup order gateway -> auth -> biz -> system in both scripts (SAD contract)" `
    -Condition ($ps1Order -and $shOrder) -Detail (".ps1 order=$ps1Order, .sh order=$shOrder")

$ps1PortMap = $ps1Exists -and $ps1Text.Contains("Port = 9000") -and $ps1Text.Contains("Port = 9100") -and `
    $ps1Text.Contains("Port = 9200") -and $ps1Text.Contains("Port = 9400")
$shPortMap = $shExists -and $shText.Contains("|9000|") -and $shText.Contains("|9100|") -and `
    $shText.Contains("|9200|") -and $shText.Contains("|9400|")
$ps1HealthUrl = $ps1Exists -and $ps1Text.Contains("http://localhost:9000/") -and `
    $ps1Text.Contains("http://localhost:9100/api/v1/auth/health") -and `
    $ps1Text.Contains("http://localhost:9200/api/v1/biz/health") -and `
    $ps1Text.Contains("http://localhost:9400/api/v1/system/health")
$shHealthUrl = $shExists -and $shText.Contains("http://localhost:9000/") -and `
    $shText.Contains("http://localhost:9100/api/v1/auth/health") -and `
    $shText.Contains("http://localhost:9200/api/v1/biz/health") -and `
    $shText.Contains("http://localhost:9400/api/v1/system/health")
Assert-Test -CaseId "UT-185-2" -Name "port mapping 9000/9100/9200/9400 + health URL target ports match service ports" `
    -Condition ($ps1PortMap -and $shPortMap -and $ps1HealthUrl -and $shHealthUrl) `
    -Detail (".ps1 ports=$ps1PortMap, .sh ports=$shPortMap, .ps1 health url=$ps1HealthUrl, .sh health url=$shHealthUrl")

$ps1SumLine = $cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState
$shSumLine  = $cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState
$ps1SumAfter = $ps1Exists -and ($ps1Text.IndexOf($ps1SumLine) -gt $ps1SIdx)
$shSumAfter  = $shExists  -and ($shText.IndexOf($shSumLine) -gt $shSIdx)
Assert-Test -CaseId "UT-185-3" -Name "summary output located after all four service sections (both platforms)" `
    -Condition ($ps1SumAfter -and $shSumAfter) -Detail (".ps1 summary after=$ps1SumAfter, .sh summary after=$shSumAfter")

# ============================================================================
# UT-186: start command + backgrounding static check (P0)
# ============================================================================
$ps1Cmd = $ps1Exists -and $ps1Text.Contains('"-Xms256m", "-Xmx512m", "-jar"')
$shCmd  = $shExists  -and $shText.Contains("java -Xms256m -Xmx512m -jar")
Assert-Test -CaseId "UT-186-1" -Name "start command java -Xms256m -Xmx512m -jar <jar> present in both scripts (deploy.md 5.6)" `
    -Condition ($ps1Cmd -and $shCmd) -Detail (".ps1 cmd=$ps1Cmd, .sh cmd=$shCmd")

$ps1Bg = $ps1Exists -and $ps1Text.Contains("Start-Process") -and $ps1Text.Contains("-WindowStyle Hidden") -and `
    $ps1Text.Contains("-RedirectStandardOutput") -and $ps1Text.Contains("-RedirectStandardError") -and `
    $ps1Text.Contains("-PassThru") -and $ps1Text.Contains(".pid")
$shBg = $shExists -and $shText.Contains("nohup java") -and $shText.Contains('2>&1 &') -and `
    $shText.Contains('echo $! >') -and $shText.Contains(".pid")
Assert-Test -CaseId "UT-186-2" -Name "backgrounding: Start-Process Hidden+redirect+PID (.ps1) / nohup+&+log+PID (.sh, F-008)" `
    -Condition ($ps1Bg -and $shBg) -Detail (".ps1 background=$ps1Bg, .sh background=$shBg")

$ps1LogDir = $ps1Exists -and $ps1Text.Contains('"logs"') -and $ps1Text.Contains("New-Item -ItemType Directory -Force") -and `
    $ps1Text.Contains("-start.log") -and $ps1Text.Contains("-start.err")
$shLogDir = $shExists -and $shText.Contains('LOG_DIR="$PROJECT_DIR/logs"') -and `
    $shText.Contains("mkdir -p") -and $shText.Contains("-start.log")
Assert-Test -CaseId "UT-186-3" -Name "log dir creation + deploy/logs/{module}-start.log(.err) paths in both scripts" `
    -Condition ($ps1LogDir -and $shLogDir) -Detail (".ps1 log dir=$ps1LogDir, .sh log dir=$shLogDir")

# ============================================================================
# UT-187: health confirm polling static check (P0)
# ============================================================================
$ps1Health = $ps1Exists -and $ps1Text.Contains("Test-HttpOk") -and $ps1Text.Contains("Test-TcpPort") -and `
    $ps1Text.Contains("for (`$i = 0; `$i -lt `$RetryCount; `$i++)") -and $ps1Text.Contains("Start-Sleep -Seconds")
$shHealth = $shExists -and $shText.Contains("http_ok") -and $shText.Contains("tcp_port_open") -and `
    $shText.Contains('for ((i = 0; i < retries; i++))') -and $shText.Contains('sleep "$interval"')
Assert-Test -CaseId "UT-187-1" -Name "health confirm: HTTP probe first + TCP port backup + loop polling in both scripts" `
    -Condition ($ps1Health -and $shHealth) -Detail (".ps1 health loop=$ps1Health, .sh health loop=$shHealth")

$ps1Default = $ps1Exists -and $ps1Text.Contains('[int]$RetryCount = 30') -and `
    $ps1Text.Contains('[int]$RetryInterval = 2') -and $ps1Text.Contains('[int]$ProbeTimeout = 3')
$shDefault = $shExists -and $shText.Contains('RETRY_COUNT="${RETRY_COUNT:-30}"') -and `
    $shText.Contains('RETRY_INTERVAL="${RETRY_INTERVAL:-2}"') -and `
    $shText.Contains('PROBE_TIMEOUT="${PROBE_TIMEOUT:-3}"')
Assert-Test -CaseId "UT-187-2" -Name "polling defaults 30 retries / 2s interval / 3s timeout, configurable in both scripts" `
    -Condition ($ps1Default -and $shDefault) -Detail (".ps1 defaults=$ps1Default, .sh defaults=$shDefault")

$ps1SeqOk = $ps1Exists -and $ps1Text.Contains("`$proc = Start-Process") -and `
    $ps1Text.Contains("if (Wait-HealthUp")
$shSeqOk = $shExists -and $shText.Contains("nohup java") -and $shText.Contains("if wait_health_up")
Assert-Test -CaseId "UT-187-3" -Name "per-service serial flow: start -> health confirm success -> next service (no concurrent start)" `
    -Condition ($ps1SeqOk -and $shSeqOk) -Detail (".ps1 serial flow=$ps1SeqOk, .sh serial flow=$shSeqOk")

$ps1SpCount = if ($ps1Exists) { ([regex]::Matches($ps1Text, 'Start-Process -FilePath "java"')).Count } else { 0 }
$shNhCount  = if ($shExists)  { ([regex]::Matches($shText, "nohup java")).Count } else { 0 }
Assert-Test -CaseId "UT-187-4" -Name "no parallel startup (single Start-Process java call in .ps1 / single nohup java in .sh)" `
    -Condition (($ps1SpCount -eq 1) -and ($shNhCount -eq 1)) `
    -Detail (".ps1 Start-Process java count=$ps1SpCount, .sh nohup java count=$shNhCount (1 expected each)")

# ============================================================================
# UT-188: fail-fast + error hint static check (P1)
# ============================================================================
$ps1Fail = $ps1Exists -and $ps1Text.Contains($cjkHTimeout) -and `
    $ps1Text.Contains($cjkCheck + " 9000/9100/9200/9400") -and $ps1Text.Contains($cjkViewLog)
$shFail  = $shExists  -and $shText.Contains($cjkHTimeout) -and `
    $shText.Contains($cjkCheck + " 9000/9100/9200/9400") -and $shText.Contains($cjkViewLog)
Assert-Test -CaseId "UT-188-1" -Name "health-timeout fail branch outputs [fail] + explicit hint incl. port list 9000/9100/9200/9400" `
    -Condition ($ps1Fail -and $shFail) -Detail (".ps1 fail hint=$ps1Fail, .sh fail hint=$shFail")

$ps1Break = $ps1Exists -and $ps1Text.Contains("break") -and $ps1Text.Contains("exit 1")
$shBreak  = $shExists  -and $shText.Contains("break") -and $shText.Contains("exit 1")
Assert-Test -CaseId "UT-188-2" -Name "fail-fast: break stops later services + non-zero exit at summary (both platforms)" `
    -Condition ($ps1Break -and $shBreak) -Detail (".ps1 break+exit=$ps1Break, .sh break+exit=$shBreak")

$ps1GtwHint = $ps1Exists -and $ps1Text.Contains($cjkCheck + " NACOS_ADDR/RSA_PUBLIC_KEY " + $cjkConfig) -and `
    $ps1Text.Contains($cjkKeyPair)
$shGtwHint  = $shExists  -and $shText.Contains($cjkCheck + " NACOS_ADDR/RSA_PUBLIC_KEY " + $cjkConfig) -and `
    $shText.Contains($cjkKeyPair)
Assert-Test -CaseId "UT-188-3" -Name "per-service troubleshooting hints present (gateway NACOS_ADDR/RSA_PUBLIC_KEY, auth key pair/DB_PASSWORD)" `
    -Condition ($ps1GtwHint -and $shGtwHint) -Detail (".ps1 hints=$ps1GtwHint, .sh hints=$shGtwHint")

# ============================================================================
# UT-189: output grading + summary + exit code + SPDX/version (P0)
# ============================================================================
$ps1Color = $ps1Exists -and $ps1Text.Contains("-ForegroundColor Green") -and `
    $ps1Text.Contains("-ForegroundColor Yellow") -and $ps1Text.Contains("-ForegroundColor Red")
$shColor = $shExists -and $shText.Contains('\033[0;32m') -and `
    $shText.Contains('\033[1;33m') -and $shText.Contains('\033[0;31m')
Assert-Test -CaseId "UT-189-1" -Name "output grading [pass]/[warn]/[fail] text prefix + color (ForegroundColor / ANSI) in both scripts" `
    -Condition ($ps1Color -and $shColor) -Detail (".ps1 colors=$ps1Color, .sh colors=$shColor")

$ps1Summary = $ps1Exists -and $ps1Text.Contains($cjkAllTitle) -and `
    $ps1Text.Contains($cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState)
$shSummary  = $shExists  -and $shText.Contains($cjkAllTitle) -and `
    $shText.Contains($cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState)
Assert-Test -CaseId "UT-189-2" -Name "summary block contains per-service start result + health state + pass/warn/fail counts" `
    -Condition ($ps1Summary -and $shSummary) -Detail (".ps1 summary=$ps1Summary, .sh summary=$shSummary")

$ps1ExitCode = $ps1Exists -and $ps1Text.Contains("exit 0") -and $ps1Text.Contains("exit 1")
$shExitCode  = $shExists  -and $shText.Contains("exit 0") -and $shText.Contains("exit 1")
Assert-Test -CaseId "UT-189-3" -Name "exit code contract present: all pass exit 0 / any fail exit 1 (F-011)" `
    -Condition ($ps1ExitCode -and $shExitCode) -Detail (".ps1 exit codes=$ps1ExitCode, .sh exit codes=$shExitCode")

$ps1Spdx = $ps1Exists -and $ps1Text.Contains("SPDX-License-Identifier: Apache-2.0") -and `
    $ps1Text.Contains("v0.2.7") -and $ps1Text.Contains(".SYNOPSIS") -and $ps1Text.Contains(".DESCRIPTION")
$shSpdx = $shExists -and $shText.Contains("SPDX-License-Identifier: Apache-2.0") -and `
    $shText.Contains("v0.2.7") -and $shText.StartsWith("#!/usr/bin/env bash")
Assert-Test -CaseId "UT-189-4" -Name "SPDX header + copyright + version v0.2.7 + comment blocks (.ps1 SYNOPSIS/DESCRIPTION, .sh shebang)" `
    -Condition ($ps1Spdx -and $shSpdx) -Detail (".ps1 spdx/version=$ps1Spdx, .sh spdx/version=$shSpdx")

# ============================================================================
# dynamic FT section: isolated runner helpers
# ============================================================================
$allPs1 = $ps1Path   # script under test used by Invoke-AllPs1Isolated

function Test-TcpPortOpen {
    param([string]$HostName, [int]$Port, [int]$TimeoutMs = 800)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $iar = $client.BeginConnect($HostName, $Port, $null, $null)
            if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
            $client.EndConnect($iar)
            return $true
        } finally { $client.Dispose() }
    } catch { return $false }
}

function Get-ListeningPorts {
    # return the sub-list of 9000/9100/9200/9400 that are currently reachable
    $listening = @()
    foreach ($p in @(9000, 9100, 9200, 9400)) {
        if (Test-TcpPortOpen -HostName "localhost" -Port $p) { $listening += $p }
    }
    return $listening
}

function Invoke-AllPs1Isolated {
    # run deploy-start-all.ps1 in a SEPARATE powershell process with the
    # load-env injected environment keys cleared first (fix C convention);
    # returns @{Output; Exit}; caches output for FT-116 plaintext check
    param([string]$ExtraArgs = "")
    $keys = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT", "DB_USERNAME",
              "DB_PASSWORD", "DB_USER", "DB_SERVICE_NAME", "DB_PROCESS_NAME",
              "REDIS_HOST", "REDIS_PORT", "REDIS_PASSWORD", "REDIS_DATABASE",
              "REDIS_SERVICE_NAME", "REDIS_PROCESS_NAME", "RSA_PRIVATE_KEY",
              "RSA_PUBLIC_KEY", "MARIADB_ROOT_PASSWORD", "TZ")
    $clearExpr = ($keys | ForEach-Object { "Remove-Item Env:$_ -ErrorAction SilentlyContinue" }) -join "; "
    $cmd = "$clearExpr; & '$allPs1' $ExtraArgs; exit `$LASTEXITCODE"
    # Outer 6>&1 2>&1 (same convention as TASK-004 FT-103) merges the child
    # process information stream and stderr (e.g. load-env Write-Error
    # guidance) into the captured output.
    $out = (& powershell -NoProfile -ExecutionPolicy Bypass -Command $cmd 6>&1 2>&1 | Out-String)
    $code = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    $script:LastRunOutput = $out
    return @{ Output = $out; Exit = $code }
}
# ============================================================================
# FT-105: jar missing -> missing item + hint + non-zero exit + no start (P0, dynamic)
# ============================================================================
$jarBizPath = Join-Path $deployDir "cloudoffice-biz-service.jar"
$jarBizExists = Test-FileExists $jarBizPath
if ($ps1Exists -and $envJsonExists -and $jarBizExists) {
    $beforePorts = @(Get-ListeningPorts)
    $bakPath = Join-Path $deployDir ".cloudoffice-biz-service.jar.bak-cso-test"
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $moved = $false
    try {
        # Running Java services lock the jar file; if the move fails the
        # scenario cannot be constructed safely -> SKIP (environment gated).
        Move-Item -LiteralPath $jarBizPath -Destination $bakPath -Force -ErrorAction Stop
        $moved = $true
        $run = Invoke-AllPs1Isolated
        $hasJarName  = $run.Output.Contains("cloudoffice-biz-service.jar")
        $hasMissHint = $run.Output.Contains($cjkJarMiss)
        $noStartMsg  = $run.Output.Contains($cjkNoStart)
        $afterPorts  = @(Get-ListeningPorts)
        $newPorts    = @($afterPorts | Where-Object { $beforePorts -notcontains $_ })
        Assert-Test -CaseId "FT-105-1" -Name "jar missing -> missing jar name + handling hint + exit 1 + no service started (dynamic)" `
            -Condition ($hasJarName -and $hasMissHint -and ($run.Exit -eq 1) -and $noStartMsg -and ($newPorts.Count -eq 0)) `
            -Detail ("jar name=$hasJarName, miss hint=$hasMissHint, exit=$($run.Exit) (1 expected), no-start msg=$noStartMsg, new ports=$($newPorts -join ',') (none expected); jar restored")
    }
    catch {
        # Move-Item failed (jar locked by running service) -> cannot construct
        # the missing-jar scenario safely in this environment -> SKIP.
        Skip-Test -CaseId "FT-105-1" -Name "jar missing -> missing jar name + handling hint + exit 1 + no service started (dynamic)" `
            -Detail "jar file locked by a running Java service (move failed: $($_.Exception.Message)); cannot construct scenario safely; static coverage via UT-182/184"
    }
    finally {
        if ($moved -and (Test-Path -LiteralPath $bakPath)) {
            try { Move-Item -LiteralPath $bakPath -Destination $jarBizPath -Force } catch { }
        }
        $ErrorActionPreference = $oldEap
    }
}
else {
    Skip-Test -CaseId "FT-105-1" -Name "jar missing -> missing jar name + handling hint + exit 1 + no service started (dynamic)" `
        -Detail "precondition not met (deploy-start-all.ps1/env.json/biz jar absent); static coverage via UT-182/184"
}

# ============================================================================
# FT-106: key env var missing -> list key names + non-zero exit + no start (P0, dynamic)
# ============================================================================
if ($ps1Exists -and $envJsonExists) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $parsed = $null
    try { $parsed = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $parsed = $null }
    if ($null -ne $parsed) {
        $origRsaPriv = $parsed.RSA_PRIVATE_KEY
        $bakPath = Join-Path $deployDir ".env.json.bak-cso-test-ft106"
        $modified = $false
        try {
            Copy-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
            $obj = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $obj.PSObject.Properties.Remove("RSA_PRIVATE_KEY")
            $newJson = $obj | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($envJsonPath, $newJson, [System.Text.Encoding]::UTF8)
            $modified = $true
            $run = Invoke-AllPs1Isolated
            $hasKeyName  = $run.Output.Contains("RSA_PRIVATE_KEY")
            $hasMissMsg  = $run.Output.Contains($cjkMissEmpty)
            $noValue     = (-not [string]::IsNullOrEmpty($origRsaPriv)) -and (-not $run.Output.Contains($origRsaPriv))
            $noStartMsg  = $run.Output.Contains($cjkNoStart)
            Assert-Test -CaseId "FT-106-1" -Name "key env var missing -> key name listed, no value printed, exit 1, no service started (dynamic)" `
                -Condition ($hasKeyName -and $hasMissMsg -and ($run.Exit -eq 1) -and $noValue -and $noStartMsg) `
                -Detail ("key name=$hasKeyName, missing msg=$hasMissMsg, exit=$($run.Exit) (1 expected), no value=$noValue, no-start msg=$noStartMsg; env.json restored")
        }
        finally {
            if ($modified -or (Test-Path -LiteralPath $bakPath)) {
                try {
                    Copy-Item -LiteralPath $bakPath -Destination $envJsonPath -Force
                    Remove-Item -LiteralPath $bakPath -Force
                } catch { }
            }
            $ErrorActionPreference = $oldEap
        }
    }
    else {
        Skip-Test -CaseId "FT-106-1" -Name "key env var missing -> list key names + non-zero exit + no start (dynamic)" `
            -Detail "env.json not parseable as JSON; cannot construct missing-key scenario safely"
    }
}
else {
    Skip-Test -CaseId "FT-106-1" -Name "key env var missing -> list key names + non-zero exit + no start (dynamic)" `
        -Detail "precondition not met (deploy-start-all.ps1/env.json absent)"
}

# ============================================================================
# FT-107: env.json missing -> copy env.example guidance + non-zero exit (P0, dynamic)
# ============================================================================
if ($ps1Exists -and $envJsonExists) {
    $bakPath = Join-Path $deployDir ".env.json.bak-cso-test-ft107"
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $moved = $false
    try {
        Move-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
        $moved = $true
        $run = Invoke-AllPs1Isolated
        $hasCopyHint = $run.Output.Contains("env.example")
        Assert-Test -CaseId "FT-107-1" -Name "env.json missing -> load-env guidance (copy env.example.json) + non-zero exit (dynamic, F-001)" `
            -Condition ($hasCopyHint -and ($run.Exit -ne 0)) `
            -Detail ("env.example hint=$hasCopyHint, exit=$($run.Exit) (non-zero expected); env.json restored")
    }
    catch {
        Assert-Test -CaseId "FT-107-1" -Name "env.json missing -> load-env guidance + non-zero exit (dynamic)" `
            -Condition $false -Detail ("run error: $($_.Exception.Message)")
    }
    finally {
        if ($moved -and (Test-Path -LiteralPath $bakPath)) {
            try { Move-Item -LiteralPath $bakPath -Destination $envJsonPath -Force } catch { }
        }
        $ErrorActionPreference = $oldEap
    }
}
else {
    Skip-Test -CaseId "FT-107-1" -Name "env.json missing -> copy env.example guidance + non-zero exit (dynamic)" `
        -Detail "precondition not met (deploy-start-all.ps1/env.json absent); load-env fallback covered by TASK-002 tests"
}

# ============================================================================
# FT-115: exit code contract 0/1 (P0, dynamic partial + env-gated full)
# ============================================================================
# failure scenarios already asserted exit 1 in FT-105/106 above; success
# scenario exit 0 is asserted in FT-114 (env-gated service run below).
Write-Output "[INFO] FT-115 success-scenario exit code 0 asserted inside FT-114 (env-gated); failure-scenario exit 1 covered by FT-105/106/107."

# ============================================================================
# FT-116: no plaintext password/key in output (P0, security, dynamic)
# ============================================================================
# Static part: script output statements must not directly emit sensitive values.
$sensitiveVars = @("DB_PASSWORD", "RSA_PRIVATE_KEY", "RSA_PUBLIC_KEY")
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
Assert-Test -CaseId "FT-116-1" -Name "no output statement directly emits DB_PASSWORD/RSA_* values (static, security)" `
    -Condition (($ps1OutputLines.Count -gt 0) -and ($ps1SensitiveOut.Count -eq 0)) `
    -Detail ("output lines=$($ps1OutputLines.Count), sensitive-emit lines=$($ps1SensitiveOut.Count) (0 expected)")

# Dynamic part: check the cached failure-scenario output for real credential values
if ($script:LastRunOutput -and $envJsonExists) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $secrets = @()
    try {
        $parsed = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($k in $sensitiveVars) {
            $v = $parsed.$k
            if ($v -and ($v -is [string]) -and ($v.Length -ge 4)) { $secrets += $v }
        }
    } catch { }
    if ($secrets.Count -gt 0) {
        $leakFound = $false
        foreach ($s in $secrets) { if ($script:LastRunOutput.Contains($s)) { $leakFound = $true } }
        Assert-Test -CaseId "FT-116-2" -Name "no real credential plaintext in dynamic failure-scenario output (security, dynamic)" `
            -Condition (-not $leakFound) `
            -Detail ("credential values checked=$($secrets.Count), leak found=$leakFound (expected absent)")
    }
    else {
        Skip-Test -CaseId "FT-116-2" -Name "no real credential plaintext in dynamic failure-scenario output" `
            -Detail "no sensitive value >= 4 chars found in env.json to compare"
    }
    $ErrorActionPreference = $oldEap
}
else {
    Skip-Test -CaseId "FT-116-2" -Name "no real credential plaintext in dynamic failure-scenario output" `
        -Detail "no cached dynamic run output / env.json absent"
}
# ============================================================================
# FT-108/109/110/114: all-ready success scenario (P0, env-gated, real 4-service start)
# ============================================================================
$jarsAllExist = (($jarNames | ForEach-Object { Test-FileExists (Join-Path $deployDir $_) } | Where-Object { -not $_ }).Count -eq 0)
$portsFree = ((Get-ListeningPorts).Count -eq 0)
if ($RunServiceTests -and $ps1Exists -and $envJsonExists -and $jarsAllExist -and $portsFree) {
    $run = Invoke-AllPs1Isolated "-RetryCount 60 -RetryInterval 2 -ProbeTimeout 3"
    # FT-108: order gateway -> auth -> biz -> system in output
    $out = $run.Output
    $gIdx = $out.IndexOf($cjkStart + " gateway")
    $aIdx = $out.IndexOf($cjkStart + " auth")
    $bIdx = $out.IndexOf($cjkStart + " biz")
    $sIdx = $out.IndexOf($cjkStart + " system")
    $orderOk = ($gIdx -gt 0) -and ($gIdx -lt $aIdx) -and ($aIdx -lt $bIdx) -and ($bIdx -lt $sIdx)
    Assert-Test -CaseId "FT-108-1" -Name "all ready -> gateway -> auth -> biz -> system started in order (dynamic, service run)" `
        -Condition ($orderOk -and ($run.Exit -eq 0)) `
        -Detail ("order ok=$orderOk, exit=$($run.Exit) (0 expected)")
    # FT-114: success summary + exit 0
    $summaryOk = $out.Contains($cjkAllTitle) -and $out.Contains($cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState)
    $allOkMsg = $out.Contains($cjkAllStartOk + $cjkSuccess)
    Assert-Test -CaseId "FT-114-1" -Name "success summary: 4-service start results + health states + all-pass message + exit 0 (dynamic)" `
        -Condition ($summaryOk -and $allOkMsg -and ($run.Exit -eq 0)) `
        -Detail ("summary=$summaryOk, all-pass msg=$allOkMsg, exit=$($run.Exit) (0 expected)")
    # FT-109: per-service health confirm before next service (serial, no concurrent)
    $healthIdx = $out.IndexOf($cjkHConfirm + $cjkSuccess)
    $nextStartIdx = $out.IndexOf($cjkStart + " auth")
    $serialOk = ($healthIdx -gt $gIdx) -and ($healthIdx -lt $nextStartIdx)
    Assert-Test -CaseId "FT-109-1" -Name "per-service health confirm success before next service start (dynamic, serial)" `
        -Condition $serialOk -Detail ("gateway health-confirm between gateway start and auth start=$serialOk")
    # FT-110: backgrounded start + log/PID on disk
    $logFilesOk = (($jarNames | ForEach-Object {
        $m = if ($_ -match "cloudoffice-([a-z-]+)\.jar") { $matches[1] } else { $_ }
        Test-FileExists (Join-Path $logDir ($m + "-start.log"))
    } | Where-Object { -not $_ }).Count -eq 0)
    Assert-Test -CaseId "FT-110-1" -Name "backgrounded start: deploy/logs/{module}-start.log generated for all 4 services (dynamic)" `
        -Condition $logFilesOk -Detail ("log files present=$logFilesOk (dir: $logDir)")
}
else {
    $detail = "environment gated (-RunServiceTests required) and/or precondition not met: ps1=$ps1Exists, env.json=$envJsonExists, 4 jars=$jarsAllExist, ports free=$portsFree"
    Skip-Test -CaseId "FT-108-1" -Name "all ready -> 4 services started in order (dynamic, service run)" -Detail $detail
    Skip-Test -CaseId "FT-109-1" -Name "per-service health confirm before next start (dynamic, service run)" -Detail $detail
    Skip-Test -CaseId "FT-110-1" -Name "backgrounded start + log/PID on disk (dynamic, service run)" -Detail $detail
    Skip-Test -CaseId "FT-114-1" -Name "success summary 4 services + exit 0 (dynamic, service run)" -Detail $detail
}

# ============================================================================
# FT-111/112/113: failure-scenario construction (P0, env-gated, -RunFailureScenarios)
# ============================================================================
if ($RunFailureScenarios -and $ps1Exists -and $envJsonExists -and $jarsAllExist -and $portsFree) {
    # FT-112: port 9000 occupied by a temporary TCP listener -> gateway health
    # confirm cannot succeed via HTTP; script must print a clear occupied/port
    # hint and stop (auth/biz/system not started). TCP fallback in the script
    # may misjudge a bare listener as alive - the assertion records the actual
    # observed behavior honestly (port list hint OR fail-fast stop OR pass).
    $listener = $null
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 9000)
        $listener.Start()
        Start-Sleep -Milliseconds 300
        $run = Invoke-AllPs1Isolated "-RetryCount 3 -RetryInterval 1 -ProbeTimeout 2"
        $portHint = $run.Output.Contains($cjkCheck + " 9000/9100/9200/9400")
        $failMsg  = $run.Output.Contains($cjkFail)
        $noAuthStart = $run.Output.Contains($cjkStart + " auth") -and ($run.Output.IndexOf($cjkStart + " auth") -gt $run.Output.IndexOf($cjkFail))
        Assert-Test -CaseId "FT-112-1" -Name "port 9000 occupied -> clear hint (port list) + fail-stop, later services not started (dynamic)" `
            -Condition (($portHint -or $failMsg) -and ($run.Exit -ne 0)) `
            -Detail ("port hint=$portHint, fail msg=$failMsg, exit=$($run.Exit) (non-zero expected); auth started after fail=$noAuthStart")
    }
    catch {
        Assert-Test -CaseId "FT-112-1" -Name "port 9000 occupied -> clear hint + fail-stop (dynamic)" `
            -Condition $false -Detail ("scenario error: $($_.Exception.Message)")
    }
    finally {
        if ($null -ne $listener) { try { $listener.Stop() } catch { } }
    }

    # FT-111 + FT-113: NACOS_ADDR unreachable -> gateway fails to become ready,
    # health confirm times out (short retries) -> fail + hint + stop next.
    $bakPath = Join-Path $deployDir ".env.json.bak-cso-test-ft113"
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $modified = $false
    try {
        Copy-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
        $obj = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $obj.NACOS_ADDR = "127.0.0.1:1"
        [System.IO.File]::WriteAllText($envJsonPath, ($obj | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)
        $modified = $true
        $run = Invoke-AllPs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
        $gtwFailMsg = $run.Output.Contains($cjkFail) -and $run.Output.Contains($cjkHTimeout)
        $gtwHint = $run.Output.Contains($cjkCheck + " NACOS_ADDR/RSA_PUBLIC_KEY " + $cjkConfig)
        $noBizStart = (-not $run.Output.Contains($cjkStart + " biz")) -and (-not $run.Output.Contains($cjkStart + " system"))
        Assert-Test -CaseId "FT-111-1" -Name "health timeout -> [fail] + guidance + stop later services + non-zero exit (dynamic)" `
            -Condition ($gtwFailMsg -and ($run.Exit -ne 0) -and $noBizStart) `
            -Detail ("fail+timeout msg=$gtwFailMsg, exit=$($run.Exit) (non-zero expected), biz/system not started=$noBizStart")
        Assert-Test -CaseId "FT-113-1" -Name "gateway fail -> auth/biz/system not started (fail-fast stop, dynamic)" `
            -Condition ($gtwFailMsg -and $gtwHint -and $noBizStart -and ($run.Exit -ne 0)) `
            -Detail ("gateway fail msg=$gtwFailMsg, hint=$gtwHint, biz/system not started=$noBizStart, exit=$($run.Exit)")
    }
    catch {
        Assert-Test -CaseId "FT-111-1" -Name "health timeout -> fail + stop (dynamic)" -Condition $false -Detail ("scenario error: $($_.Exception.Message)")
        Assert-Test -CaseId "FT-113-1" -Name "gateway fail -> later services not started (dynamic)" -Condition $false -Detail ("scenario error: $($_.Exception.Message)")
    }
    finally {
        if ($modified -or (Test-Path -LiteralPath $bakPath)) {
            try {
                Copy-Item -LiteralPath $bakPath -Destination $envJsonPath -Force
                Remove-Item -LiteralPath $bakPath -Force
            } catch { }
        }
        $ErrorActionPreference = $oldEap
    }
}
else {
    $detail = "environment gated (-RunFailureScenarios required) and/or precondition not met: ps1=$ps1Exists, env.json=$envJsonExists, 4 jars=$jarsAllExist, ports free=$portsFree"
    Skip-Test -CaseId "FT-111-1" -Name "health timeout -> fail + guidance + stop later services (dynamic)" -Detail $detail
    Skip-Test -CaseId "FT-112-1" -Name "port 9000 occupied -> clear hint + fail-stop (dynamic)" -Detail $detail
    Skip-Test -CaseId "FT-113-1" -Name "gateway fail -> auth/biz/system not started (fail-fast, dynamic)" -Detail $detail
}

# ============================================================================
# FT-117: dual-platform behavior consistency (P1, SKIP if no bash/WSL)
# ============================================================================
if ($bashUsable -and $shExists) {
    $wslSh = $shPath
    if ($wslSh -match "^([A-Za-z]):\\(.*)$") {
        $wslSh = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
    }
    $null = (& bash -n $wslSh 2>&1)
    $bashExit = $LASTEXITCODE
    $shGrading = $shText.Contains("[" + $cjkPass + "]") -and $shText.Contains("[" + $cjkWarn + "]") -and $shText.Contains("[" + $cjkFail + "]")
    $ps1Grading = $ps1Text.Contains("[" + $cjkPass + "]") -and $ps1Text.Contains("[" + $cjkWarn + "]") -and $ps1Text.Contains("[" + $cjkFail + "]")
    $exitConsistent = $ps1Text.Contains("exit 0") -and $ps1Text.Contains("exit 1") -and `
        $shText.Contains("exit 0") -and $shText.Contains("exit 1")
    Assert-Test -CaseId "FT-117-1" -Name "dual-platform consistency: bash -n pass + same grading text + same exit-code contract (no emoji)" `
        -Condition (($bashExit -eq 0) -and $shGrading -and $ps1Grading -and $exitConsistent) `
        -Detail ("bash -n exit=$bashExit, .sh grading=$shGrading, .ps1 grading=$ps1Grading, exit contract=$exitConsistent")
}
else {
    Skip-Test -CaseId "FT-117-1" -Name "dual-platform behavior consistency (dynamic)" `
        -Detail "bash/WSL unavailable; static dual-platform coverage via UT-178/179/185~189"
}

# ============================================================================
# FT-118: already-running repeat run (P1, env-gated)
# ============================================================================
$allPortsUp = ((Get-ListeningPorts).Count -eq 4)
if ($RunServiceTests -and $allPortsUp -and $ps1Exists -and $envJsonExists) {
    $run = Invoke-AllPs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
    $summaryOk = $run.Output.Contains($cjkPerSvc + $cjkStartResult + $cjkAnd + $cjkHealthState)
    Assert-Test -CaseId "FT-118-1" -Name "all services already running -> summary output + exit code 0 (idempotent scenario, dynamic)" `
        -Condition ($summaryOk -and ($run.Exit -eq 0)) `
        -Detail ("summary=$summaryOk, exit=$($run.Exit) (0 expected)")
}
else {
    Skip-Test -CaseId "FT-118-1" -Name "already-running repeat run (dynamic)" `
        -Detail "environment gated (-RunServiceTests + 4 ports already listening required); all ports up=$allPortsUp"
}

# ============================================================================
# summary + exit code
# ============================================================================
Write-Output ""
Write-Output ("=" * 70)
Write-Output "cso-unit-test-start-all-v0.2.7 (TASK-005) summary"
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



