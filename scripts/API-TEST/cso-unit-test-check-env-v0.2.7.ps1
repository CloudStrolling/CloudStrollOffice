# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - deploy-check-env Test (TASK-003)
# ----------------------------------------------------------------------------
# Coverage: UT-152 ~ UT-163 + FT-078 ~ FT-091 in task testcase
#           (docs/cso-v0.2.7/task_TASK-003/testcase.md)
#   UT-152: deploy-check-env.ps1 parseable via PowerShell Parser (P0)
#   UT-153: deploy-check-env.sh syntax check via bash -n (fallback if no bash) (P0)
#   UT-154: dual-platform scripts both exist, check items 1:1 (P1)
#   UT-155: no hard-coded default addresses (P0, security)
#   UT-156: load-env call contract + required keys check + NACOS_ADDR format (P0)
#   UT-157: availability check logic static alignment (JDK/MariaDB/Redis/Nacos) (P0)
#   UT-158: Nacos "warning (not running)" logic (P0)
#   UT-159: running-state detection logic (P1)
#   UT-160: output grading (pass/warn/fail) + exit code contract (P1)
#   UT-161: password masking, no plaintext in output (P0, security)
#   UT-162: unrelated check items removed, dead code cleaned (P1)
#   UT-163: SPDX header + Simplified-Chinese comments + version v0.2.7 (P1)
#   FT-078: JDK availability pass scenario (P0, dynamic, env-gated)
#   FT-079: JDK missing / JAVA_HOME invalid -> fail + non-zero exit (P0, dynamic)
#   FT-080: MariaDB availability pass scenario (P0, dynamic, env-gated)
#   FT-081: MariaDB installed but not connectable -> fail + non-zero exit (P0)
#   FT-082: Redis availability pass scenario (P0, dynamic, env-gated)
#   FT-083: Redis installed but ping fail -> fail + non-zero exit (P0)
#   FT-084: Nacos installed-not-started -> warning (not running) (P0)
#   FT-085: Nacos not installed -> fail + non-zero exit (P0)
#   FT-086: Nacos running scenario (P1, dynamic, env-gated)
#   FT-087: env.json missing -> env.example.json guidance + non-zero exit (P0)
#   FT-088: running-state detection scenario (P1, dynamic, env-gated)
#   FT-089: output grading summary + exit code contract (P0)
#   FT-090: password masking - no DB_PASSWORD/REDIS_PASSWORD plaintext (P0)
#   FT-091: dual-platform behavior consistency (P1, SKIP if no bash/WSL)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-check-env-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-check-env-v0.2.7.ps1 `
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
#   (JDK 21 / MariaDB / Redis / Nacos running) are environment-gated:
#   precondition not met -> SKIP (environment blocked, not a failure).
#   .sh dynamic assertions require bash/WSL; when unavailable they are
#   SKIP (static dual-platform coverage via UT-153/154/157~162).
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
        "notrun"      { return [string][char]0x672A + [string][char]0x8FD0 + [string][char]0x884C }
        "running"     { return [string][char]0x8FD0 + [string][char]0x884C + [string][char]0x4E2D }
        "ready"       { return [string][char]0x5C31 + [string][char]0x7EEA }
        "install"     { return [string][char]0x5B89 + [string][char]0x88C5 }
        "installed"   { return [string][char]0x5DF2 + [string][char]0x5B89 + [string][char]0x88C5 }
        "notinst"     { return [string][char]0x672A + [string][char]0x5B89 + [string][char]0x88C5 }
        "please"      { return [string][char]0x8BF7 }
        "summary"     { return [string][char]0x68C0 + [string][char]0x67E5 + [string][char]0x5B8C + [string][char]0x6210 }
        "ver"         { return [string][char]0x7248 + [string][char]0x672C }
        "runstate"    { return [string][char]0x8FD0 + [string][char]0x884C + [string][char]0x72B6 + [string][char]0x6001 }
        "phase"       { return [string][char]0x9636 + [string][char]0x6BB5 }
        "envfile"     { return [string][char]0x73AF + [string][char]0x5883 + [string][char]0x914D + [string][char]0x7F6E + [string][char]0x6587 + [string][char]0x4EF6 }
        "copy"        { return [string][char]0x590D + [string][char]0x5236 }
        "fill"        { return [string][char]0x586B + [string][char]0x5199 }
        "connfail"    { return [string][char]0x8FDE + [string][char]0x63A5 + [string][char]0x5931 + [string][char]0x8D25 }
        "addrbad"     { return [string][char]0x5730 + [string][char]0x5740 + [string][char]0x683C + [string][char]0x5F0F + [string][char]0x975E + [string][char]0x6CD5 }
        "usable"      { return [string][char]0x53EF + [string][char]0x7528 }
        "unusable"    { return [string][char]0x4E0D + [string][char]0x53EF + [string][char]0x7528 }
        "nohit"       { return [string][char]0x672A + [string][char]0x68C0 + [string][char]0x6D4B + [string][char]0x5230 }
        "reuse"       { return [string][char]0x590D + [string][char]0x7528 }
        "item"        { return [string][char]0x9879 }
        "check"       { return [string][char]0x68C0 + [string][char]0x67E5 }
        "pleasecheck" { return [string][char]0x8BF7 + [string][char]0x68C0 + [string][char]0x67E5 }
        "service"     { return [string][char]0x670D + [string][char]0x52A1 }
        "process"     { return [string][char]0x8FDB + [string][char]0x7A0B }
        "cannot"      { return [string][char]0x65E0 + [string][char]0x6CD5 }
        "run"         { return [string][char]0x8FD0 + [string][char]0x884C }
    }
    return ""
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 deploy-check-env Test (TASK-003, UT-152~UT-163 + FT-078~FT-091)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$scriptsDir   = Join-Path $ProjectRoot "deploy\scripts"
$checkEnvPs1  = Join-Path $scriptsDir "deploy-check-env.ps1"
$checkEnvSh   = Join-Path $scriptsDir "deploy-check-env.sh"
$loadEnvPs1   = Join-Path $scriptsDir "load-env.ps1"
$loadEnvSh    = Join-Path $scriptsDir "load-env.sh"
$deployDir    = Join-Path $ProjectRoot "deploy"
$envJsonPath  = Join-Path $deployDir "env.json"

$ps1Exists = Test-FileExists -Path $checkEnvPs1
$shExists  = Test-FileExists -Path $checkEnvSh
$envJsonExists = Test-FileExists -Path $envJsonPath

# CJK words used by assertions
$cjkPass        = Get-CjkText "pass"
$cjkWarn        = Get-CjkText "warn"
$cjkFail        = Get-CjkText "fail"
$cjkNotrun      = Get-CjkText "notrun"
$cjkRunning     = Get-CjkText "running"
$cjkReady       = Get-CjkText "ready"
$cjkInstall     = Get-CjkText "install"
$cjkInstalled   = Get-CjkText "installed"
$cjkNotinst     = Get-CjkText "notinst"
$cjkPlease      = Get-CjkText "please"
$cjkSummary     = Get-CjkText "summary"
$cjkVer         = Get-CjkText "ver"
$cjkRunstate    = Get-CjkText "runstate"
$cjkPhase       = Get-CjkText "phase"
$cjkEnvfile     = Get-CjkText "envfile"
$cjkCopy        = Get-CjkText "copy"
$cjkFill        = Get-CjkText "fill"
$cjkConnfail    = Get-CjkText "connfail"
$cjkAddrbad     = Get-CjkText "addrbad"
$cjkUsable      = Get-CjkText "usable"
$cjkUnusable    = Get-CjkText "unusable"
$cjkNohit       = Get-CjkText "nohit"
$cjkReuse       = Get-CjkText "reuse"
$cjkItem        = Get-CjkText "item"
$cjkCheck       = Get-CjkText "check"
$cjkPleasecheck = Get-CjkText "pleasecheck"
$cjkService     = Get-CjkText "service"
$cjkProcess     = Get-CjkText "process"
$cjkCannot      = Get-CjkText "cannot"

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
# UT-152: deploy-check-env.ps1 syntax parseability (P0)
# ============================================================================
if (-not $ps1Exists) {
    Assert-Test -CaseId "UT-152-1" -Name "deploy-check-env.ps1 exists" -Condition $false -Detail "not found: $checkEnvPs1"
}
else {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($checkEnvPs1, [ref]$tokens, [ref]$errors) | Out-Null
    $errText = ""
    if ($errors -and $errors.Count -gt 0) {
        $errText = ($errors | ForEach-Object { "L$($_.Extent.StartLineNumber):$($_.Message)" }) -join "; "
    }
    Assert-Test -CaseId "UT-152-1" -Name "deploy-check-env.ps1 parseable via PowerShell Parser (no syntax errors, PS 5.1 compatible)" `
        -Condition (-not $errors -or $errors.Count -eq 0) `
        -Detail ("parse errors: " + $(if ($errText) { $errText } else { "none" }))
}

# dead code (P7-05/P7-06) removed: no orphan line / invalid object creation
$ps1Text = if ($ps1Exists) { Read-Utf8File -Path $checkEnvPs1 } else { "" }
$ps1DeadCodeHit = $ps1Text.Contains("CurrentFileSystemDrive") -or $ps1Text.Contains("DbProviderFactory")
Assert-Test -CaseId "UT-152-2" -Name "dead code removed (no CurrentFileSystemDrive orphan line, no DbProviderFactory invalid object)" `
    -Condition (-not $ps1DeadCodeHit) `
    -Detail ("dead code hit: $ps1DeadCodeHit (expected absent)")

# ============================================================================
# UT-153: deploy-check-env.sh syntax check via bash -n (P0, fallback if no bash)
# ============================================================================
$shText = if ($shExists) { Read-Utf8File -Path $checkEnvSh } else { "" }
if (-not $shExists) {
    Assert-Test -CaseId "UT-153-1" -Name "deploy-check-env.sh exists" -Condition $false -Detail "not found: $checkEnvSh"
}
else {
    if ($bashUsable) {
        $native = $checkEnvSh
        $wslPath = $native
        if ($native -match "^([A-Za-z]):\\(.*)$") {
            $wslPath = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $out = (& bash -n $wslPath 2>&1)
        $ok = ($LASTEXITCODE -eq 0)
        Assert-Test -CaseId "UT-153-1" -Name "deploy-check-env.sh syntax check via bash -n (exit 0, no output)" `
            -Condition $ok -Detail ("bash -n output: " + $(if ($out) { ($out -join " ") } else { "none" }))
    }
    else {
        # Fallback (bash/WSL unavailable): shebang + non-empty + if/fi pairing + function def + version
        $hasShebang = ($shText -match "(?m)^#!")
        $nonEmpty = ($shText.Trim().Length -gt 0)
        # global \bif\b vs \bfi\b pairing (single-line "if ...; then ...; fi" forms
        # keep if/fi on the same line, so line-anchored counting is not reliable)
        $ifCount = ([regex]::Matches($shText, "\bif\b")).Count
        $fiCount = ([regex]::Matches($shText, "\bfi\b")).Count
        $hasFunc = ($shText -match "(?m)^print_result\s*\(\s*\)")
        $structOk = $hasShebang -and $nonEmpty -and ($ifCount -eq $fiCount) -and $hasFunc
        Assert-Test -CaseId "UT-153-1" -Name "deploy-check-env.sh fallback structure check (bash unavailable: shebang+non-empty+if/fi paired+function def)" `
            -Condition $structOk `
            -Detail ("bash usable: false; shebang: $hasShebang, non-empty: $nonEmpty, if=$ifCount fi=$fiCount, print_result func: $hasFunc")
    }
}

# version tag must be v0.2.7, not stale v0.1.7
$shVersionOk = $shExists -and $shText.Contains("v0.2.7") -and (-not $shText.Contains("v0.1.7"))
$ps1VersionOk = $ps1Exists -and $ps1Text.Contains("v0.2.7") -and (-not $ps1Text.Contains("v0.1.7"))
Assert-Test -CaseId "UT-153-2" -Name "version tag v0.2.7 in both scripts (not stale v0.1.7)" `
    -Condition ($shVersionOk -and $ps1VersionOk) `
    -Detail (".ps1 v0.2.7=$ps1VersionOk, .sh v0.2.7=$shVersionOk")

# ============================================================================
# UT-154: dual-platform scripts both exist, check items 1:1 (P1)
# ============================================================================
Assert-Test -CaseId "UT-154-1" -Name "deploy-check-env.ps1 and deploy-check-env.sh both exist (paired)" `
    -Condition ($ps1Exists -and $shExists) `
    -Detail (".ps1: $ps1Exists, .sh: $shExists")

$ps1ResultCalls = if ($ps1Exists) { ([regex]::Matches($ps1Text, 'Write-Result "')).Count } else { 0 }
$shResultCalls  = if ($shExists)  { ([regex]::Matches($shText, 'print_result "')).Count } else { 0 }
Assert-Test -CaseId "UT-154-2" -Name "availability(4) + running-state(4) result outputs 1:1 between platforms (Write-Result calls == print_result calls >= 8)" `
    -Condition (($ps1ResultCalls -eq $shResultCalls) -and ($ps1ResultCalls -ge 8)) `
    -Detail (".ps1 Write-Result calls=$ps1ResultCalls; .sh print_result calls=$shResultCalls (equal and >= 8 expected)")

$ps1PhaseCount = if ($ps1Exists) { ([regex]::Matches($ps1Text, $cjkPhase)).Count } else { 0 }
$shPhaseCount  = if ($shExists)  { ([regex]::Matches($shText, $cjkPhase)).Count } else { 0 }
$ps1Components = @("JDK", "MariaDB", "Redis", "Nacos") | ForEach-Object { $ps1Exists -and $ps1Text.Contains($_) }
$shComponents  = @("JDK", "MariaDB", "Redis", "Nacos") | ForEach-Object { $shExists  -and $shText.Contains($_) }
$bothComponents = (($ps1Components | Where-Object { -not $_ }).Count -eq 0) -and (($shComponents | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-154-3" -Name "both phases + four components (JDK/MariaDB/Redis/Nacos) present in both scripts (availability + running state)" `
    -Condition ($ps1PhaseCount -ge 2 -and $shPhaseCount -ge 2 -and $bothComponents) `
    -Detail (".ps1 phase-markers=$ps1PhaseCount, .sh phase-markers=$shPhaseCount (>=2 expected), components both=$bothComponents")

# ============================================================================
# UT-155: no hard-coded default addresses (P0, security)
# ============================================================================
$hardIpPattern = "192\.168\.1\.1[0-9][0-9]"
$ps1HardIp = $ps1Exists -and [regex]::IsMatch($ps1Text, $hardIpPattern)
$shHardIp  = $shExists  -and [regex]::IsMatch($shText, $hardIpPattern)
Assert-Test -CaseId "UT-155-1" -Name "no hard-coded 192.168.1.1xx default addresses in both scripts" `
    -Condition (-not $ps1HardIp -and -not $shHardIp) `
    -Detail (".ps1 hit: $ps1HardIp, .sh hit: $shHardIp (expected absent)")

# no literal IP addresses at all (connect addresses must come from env.json via load-env)
$anyIpPattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
$ps1AnyIp = $ps1Exists -and [regex]::IsMatch($ps1Text, $anyIpPattern)
$shAnyIp  = $shExists  -and [regex]::IsMatch($shText, $anyIpPattern)
Assert-Test -CaseId "UT-155-2" -Name "no literal IP addresses anywhere in both scripts (connect addresses from env vars only)" `
    -Condition (-not $ps1AnyIp -and -not $shAnyIp) `
    -Detail (".ps1 literal IP: $ps1AnyIp, .sh literal IP: $shAnyIp (expected absent)")

# no ${VAR:-default} numeric fallback and no param() default-address block
$envFallbackPattern = "\$\{[A-Z_]+:-[0-9]"
$ps1EnvFallback = $ps1Exists -and [regex]::IsMatch($ps1Text, $envFallbackPattern)
$shEnvFallback  = $shExists  -and [regex]::IsMatch($shText, $envFallbackPattern)
# script-level param() block with a default IP address is forbidden (function
# params like TimeoutMs = 1000 are allowed - they are not connect addresses)
$ps1ParamDefault = $ps1Exists -and ($ps1Text -match "param\s*\([^)]*=\s*[`"']?(\d{1,3}\.){3}\d{1,3}")
Assert-Test -CaseId "UT-155-3" -Name "no numeric env-var fallback (${VAR:-digits}) and no param() default-address block in .ps1" `
    -Condition (-not $ps1EnvFallback -and -not $shEnvFallback -and -not $ps1ParamDefault) `
    -Detail (".ps1 fallback=$ps1EnvFallback, .sh fallback=$shEnvFallback, .ps1 param(=$ps1ParamDefault (all expected absent)")

# ============================================================================
# UT-156: load-env call contract + required keys check + NACOS_ADDR format (P0)
# ============================================================================
$ps1LoadEnvOk = $ps1Exists -and ($ps1Text -match "\`$PSScriptRoot\\load-env\.ps1")
$shLoadEnvOk  = $shExists  -and ($shText  -match '\$SCRIPT_DIR/load-env\.sh')
Assert-Test -CaseId "UT-156-1" -Name "both scripts call load-env via PSScriptRoot / SCRIPT_DIR (F-001 contract)" `
    -Condition ($ps1LoadEnvOk -and $shLoadEnvOk) `
    -Detail (".ps1 dot-source load-env.ps1=$ps1LoadEnvOk; .sh source load-env.sh=$shLoadEnvOk")

$requiredKeys = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT",
                  "DB_USERNAME", "DB_PASSWORD", "REDIS_HOST", "REDIS_PORT")
$ps1KeyMiss = @($requiredKeys | Where-Object { $ps1Exists -and -not $ps1Text.Contains($_) })
$shKeyMiss  = @($requiredKeys | Where-Object { $shExists  -and -not $shText.Contains($_) })
Assert-Test -CaseId "UT-156-2" -Name "8 required keys (NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT) referenced in both scripts" `
    -Condition (($ps1KeyMiss.Count -eq 0) -and ($shKeyMiss.Count -eq 0)) `
    -Detail (".ps1 missing: " + $(if ($ps1KeyMiss.Count -eq 0) { "none" } else { $ps1KeyMiss -join ", " }) +
             "; .sh missing: " + $(if ($shKeyMiss.Count -eq 0) { "none" } else { $shKeyMiss -join ", " }))

# NACOS_ADDR format validation branch (F-005): host:port regex + failure message
# (literal substring match - the source contains a regex literal such as
# '^[^:]+:\d+$' inside a -match expression, so matching it with regex would
# confuse the character-class syntax)
$ps1AddrFormat = $ps1Exists -and $ps1Text.Contains("^[^:]+:\d+$")
$shAddrFormat  = $shExists  -and $shText.Contains("^[^:]+:[0-9]+$")
$ps1AddrBadMsg = $ps1Exists -and $ps1Text.Contains($cjkAddrbad)
$shAddrBadMsg  = $shExists  -and $shText.Contains($cjkAddrbad)
Assert-Test -CaseId "UT-156-3" -Name "NACOS_ADDR format validation (host:port regex) + 'address format illegal' message in both scripts (F-005)" `
    -Condition ($ps1AddrFormat -and $shAddrFormat -and $ps1AddrBadMsg -and $shAddrBadMsg) `
    -Detail (".ps1 regex=$ps1AddrFormat msg=$ps1AddrBadMsg; .sh regex=$shAddrFormat msg=$shAddrBadMsg")

# ============================================================================
# UT-157: availability check logic static alignment (P0)
# ============================================================================
$ps1Jdk = $ps1Exists -and $ps1Text.Contains("java -version") -and $ps1Text.Contains('version "21') -and $ps1Text.Contains("JAVA_HOME")
$shJdk  = $shExists  -and $shText.Contains("java -version") -and $shText.Contains('version "21') -and $shText.Contains("JAVA_HOME")
Assert-Test -CaseId "UT-157-1" -Name "JDK availability logic: java -version + 'version 21' + JAVA_HOME valid merged into one conclusion (F-002)" `
    -Condition ($ps1Jdk -and $shJdk) `
    -Detail (".ps1 JDK logic=$ps1Jdk; .sh JDK logic=$shJdk")

$ps1Db = $ps1Exists -and $ps1Text.Contains("SELECT 1") -and $ps1Text.Contains("mariadb") -and $ps1Text.Contains("mysqld") -and $ps1Text.Contains("mariadbd")
$shDb  = $shExists  -and $shText.Contains("SELECT 1") -and $shText.Contains("mariadb") -and $shText.Contains("mysqld") -and $shText.Contains("mariadbd")
Assert-Test -CaseId "UT-157-2" -Name "MariaDB availability logic: command/service/process triple install check + SELECT 1 connectivity (F-003)" `
    -Condition ($ps1Db -and $shDb) `
    -Detail (".ps1 MariaDB logic=$ps1Db; .sh MariaDB logic=$shDb")

$ps1Redis = $ps1Exists -and $ps1Text.Contains("redis-cli") -and $ps1Text.Contains("redis-server") -and $ps1Text.Contains("PONG")
$shRedis  = $shExists  -and $shText.Contains("redis-cli") -and $shText.Contains("redis-server") -and $shText.Contains("PONG")
Assert-Test -CaseId "UT-157-3" -Name "Redis availability logic: command/service/process triple install check + redis-cli ping returns PONG (F-004)" `
    -Condition ($ps1Redis -and $shRedis) `
    -Detail (".ps1 Redis logic=$ps1Redis; .sh Redis logic=$shRedis")

$ps1Nacos = $ps1Exists -and $ps1Text.Contains("startup.cmd") -and $ps1Text.Contains("/nacos/") -and $ps1Text.Contains("Invoke-WebRequest")
$shNacos  = $shExists  -and $shText.Contains("startup.sh") -and $shText.Contains("/nacos/") -and $shText.Contains("curl")
Assert-Test -CaseId "UT-157-4" -Name "Nacos availability logic: NACOS_HOME/bin/startup.cmd|sh exists + HTTP probe /nacos/ contains Nacos (F-005)" `
    -Condition ($ps1Nacos -and $shNacos) `
    -Detail (".ps1 Nacos logic=$ps1Nacos; .sh Nacos logic=$shNacos")

$unrelatedPatterns = @("pom.xml", "settings.xml", "mvn -version", "git version")
$ps1Unrelated = @($unrelatedPatterns | Where-Object { $ps1Exists -and $ps1Text.Contains($_) })
$shUnrelated  = @($unrelatedPatterns | Where-Object { $shExists  -and $shText.Contains($_) })
Assert-Test -CaseId "UT-157-5" -Name "unrelated check items (pom.xml/settings.xml/mvn -version/git version) removed from both scripts (F-010)" `
    -Condition (($ps1Unrelated.Count -eq 0) -and ($shUnrelated.Count -eq 0)) `
    -Detail (".ps1 unrelated: " + $(if ($ps1Unrelated.Count -eq 0) { "none" } else { $ps1Unrelated -join ", " }) +
             "; .sh unrelated: " + $(if ($shUnrelated.Count -eq 0) { "none" } else { $shUnrelated -join ", " }))

# ============================================================================
# UT-158: Nacos installed-not-started -> warning (not running) logic (P0)
# ============================================================================
$ps1NacosWarn = $ps1Exists -and $ps1Text.Contains($cjkWarn) -and $ps1Text.Contains($cjkNotrun) -and $ps1Text.Contains($cjkInstalled)
$shNacosWarn  = $shExists  -and $shText.Contains($cjkWarn) -and $shText.Contains($cjkNotrun) -and $shText.Contains($cjkInstalled)
Assert-Test -CaseId "UT-158-1" -Name "installed-not-started Nacos graded as warning 'not running' (not fail / not not-installed) in both scripts (F-005)" `
    -Condition ($ps1NacosWarn -and $shNacosWarn) `
    -Detail (".ps1 warn+notrun+installed=$ps1NacosWarn; .sh warn+notrun+installed=$shNacosWarn")

$ps1NacosInstalledFlag = $ps1Exists -and $ps1Text.Contains("`$nacosInstalled = `$true")
$shNacosInstalledFlag  = $shExists  -and $shText.Contains("NACOS_INSTALLED=true")
Assert-Test -CaseId "UT-158-2" -Name "Nacos installed flag set when NACOS_HOME+startup script present (both platforms)" `
    -Condition ($ps1NacosInstalledFlag -and $shNacosInstalledFlag) `
    -Detail (".ps1 installed flag=$ps1NacosInstalledFlag; .sh installed flag=$shNacosInstalledFlag")

$ps1NacosNotinst = $ps1Exists -and $ps1Text.Contains($cjkNotinst) -and $ps1Text.Contains($cjkPlease) -and $ps1Text.Contains($cjkInstall)
$shNacosNotinst  = $shExists  -and $shText.Contains($cjkNotinst) -and $shText.Contains($cjkPlease) -and $shText.Contains($cjkInstall)
Assert-Test -CaseId "UT-158-3" -Name "not-installed Nacos graded as fail with install guidance 'please install Nacos / configure NACOS_HOME' (both platforms)" `
    -Condition ($ps1NacosNotinst -and $shNacosNotinst) `
    -Detail (".ps1 fail+please+install=$ps1NacosNotinst; .sh fail+please+install=$shNacosNotinst")

# availability output and running-state output are separated (phase 2 has its own Nacos running-state line)
$ps1NacosRunState = $ps1Exists -and $ps1Text.Contains("Nacos " + $cjkRunstate)
$shNacosRunState  = $shExists  -and $shText.Contains("Nacos " + $cjkRunstate)
Assert-Test -CaseId "UT-158-4" -Name "availability status and running-state output separated (Nacos running-state line present in phase 2)" `
    -Condition ($ps1NacosRunState -and $shNacosRunState) `
    -Detail (".ps1 Nacos running-state line=$ps1NacosRunState; .sh Nacos running-state line=$shNacosRunState")

# ============================================================================
# UT-159: running-state detection logic (P1)
# ============================================================================
$ps1JdkReady = $ps1Exists -and $ps1Text.Contains("JDK " + $cjkRunstate) -and $ps1Text.Contains($cjkReuse)
$shJdkReady  = $shExists  -and $shText.Contains("JDK " + $cjkRunstate) -and $shText.Contains($cjkReuse)
Assert-Test -CaseId "UT-159-1" -Name "JDK running state reuses availability conclusion (ready, no separate start check)" `
    -Condition ($ps1JdkReady -and $shJdkReady) `
    -Detail (".ps1 JDK ready reuse=$ps1JdkReady; .sh JDK ready reuse=$shJdkReady")

$ps1DbRedisRun = $ps1Exists -and $ps1Text.Contains("Get-Process") -and $ps1Text.Contains("Get-Service") -and $ps1Text.Contains("TcpClient")
$shDbRedisRun  = $shExists  -and $shText.Contains("has_proc") -and $shText.Contains("svc_active") -and $shText.Contains("tcp_port_open")
Assert-Test -CaseId "UT-159-2" -Name "MariaDB/Redis running state: process / service running / TCP port any-hit -> running (platform-adapted commands)" `
    -Condition ($ps1DbRedisRun -and $shDbRedisRun) `
    -Detail (".ps1 Get-Process/Get-Service/TcpClient=$ps1DbRedisRun; .sh has_proc/svc_active/tcp_port_open=$shDbRedisRun")

$ps1NacosRun = $ps1Exists -and $ps1Text.Contains("CommandLine") -and $ps1Text.Contains("nacos") -and $ps1Text.Contains($cjkReuse)
$shNacosRun  = $shExists  -and $shText.Contains("pgrep -f") -and $shText.Contains("nacos")
Assert-Test -CaseId "UT-159-3" -Name "Nacos running state: HTTP probe primary + java process command-line contains nacos as auxiliary (F-006)" `
    -Condition ($ps1NacosRun -and $shNacosRun) `
    -Detail (".ps1 java commandline nacos=$ps1NacosRun; .sh pgrep -f nacos=$shNacosRun")

# ============================================================================
# UT-160: output grading (pass/warn/fail) + exit code contract (P1)
# ============================================================================
$ps1Colors = $ps1Exists -and $ps1Text.Contains("ForegroundColor") -and $ps1Text.Contains("Green") -and $ps1Text.Contains("Yellow") -and $ps1Text.Contains("Red")
$shAnsi    = $shExists  -and $shText.Contains('\033[')
$ps1Grading = $ps1Exists -and $ps1Text.Contains($cjkPass) -and $ps1Text.Contains($cjkWarn) -and $ps1Text.Contains($cjkFail)
$shGrading  = $shExists  -and $shText.Contains($cjkPass) -and $shText.Contains($cjkWarn) -and $shText.Contains($cjkFail)
Assert-Test -CaseId "UT-160-1" -Name "three-level output grading (pass/warn/fail) with colors (.ps1 Write-Host colors / .sh ANSI)" `
    -Condition ($ps1Colors -and $shAnsi -and $ps1Grading -and $shGrading) `
    -Detail (".ps1 colors=$ps1Colors grading=$ps1Grading; .sh ANSI=$shAnsi grading=$shGrading")

$ps1Summary = $ps1Exists -and $ps1Text.Contains($cjkSummary) -and $ps1Text.Contains("`$script:pass") -and $ps1Text.Contains("`$script:warn") -and $ps1Text.Contains("`$script:fail")
$shSummary  = $shExists  -and $shText.Contains($cjkSummary) -and $shText.Contains("$PASS") -and $shText.Contains("$WARN") -and $shText.Contains("$FAIL")
Assert-Test -CaseId "UT-160-2" -Name "summary shows pass/warn/fail counts (both platforms)" `
    -Condition ($ps1Summary -and $shSummary) `
    -Detail (".ps1 summary counts=$ps1Summary; .sh summary counts=$shSummary")

$ps1Exit = $ps1Exists -and $ps1Text.Contains("exit 1") -and $ps1Text.Contains("exit 0")
$shExit  = $shExists  -and $shText.Contains("exit 1") -and $shText.Contains("exit 0")
Assert-Test -CaseId "UT-160-3" -Name "exit code contract present (fail>0 -> exit 1; warn only or all pass -> exit 0, F-011)" `
    -Condition ($ps1Exit -and $shExit) `
    -Detail (".ps1 exit 1/0=$ps1Exit; .sh exit 1/0=$shExit")

# .sh must avoid eval command concatenation on EXECUTABLE lines (comment lines
# may legitimately mention eval as an anti-pattern, e.g. the array-params note)
$shNoEval = $true
if ($shExists) {
    $shCodeLines = @($shText -split "`r?`n" | Where-Object { $_ -notmatch "^\s*#" })
    $shNoEval = -not (($shCodeLines | Where-Object { $_ -match "\beval\s" }).Count -gt 0)
}
Assert-Test -CaseId "UT-160-4" -Name ".sh avoids eval command concatenation (array params, no injection/plaintext risk, P7-10)" `
    -Condition $shNoEval -Detail (".sh eval present (executable lines): $(-not $shNoEval) (expected absent)")

# ============================================================================
# UT-161: password masking - no plaintext in output statements (P0, security)
# ============================================================================
$sensitiveVars = @("DB_PASSWORD", "REDIS_PASSWORD")
# .ps1: output statements (Write-*) must not reference sensitive values
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
Assert-Test -CaseId "UT-161-1" -Name "output statements (Write-*/echo/printf) never reference DB_PASSWORD/REDIS_PASSWORD plaintext values" `
    -Condition ($ps1SensitiveOut.Count -eq 0 -and $shSensitiveOut.Count -eq 0) `
    -Detail (".ps1 sensitive outputs: " + $(if ($ps1SensitiveOut.Count -eq 0) { "none" } else { $ps1SensitiveOut -join "; " }) +
             "; .sh sensitive outputs: " + $(if ($shSensitiveOut.Count -eq 0) { "none" } else { $shSensitiveOut -join "; " }))

$ps1RedisAuth = $ps1Exists -and $ps1Text.Contains("REDISCLI_AUTH")
$shRedisAuth  = $shExists  -and $shText.Contains("REDISCLI_AUTH")
Assert-Test -CaseId "UT-161-2" -Name "Redis password passed via REDISCLI_AUTH env var (no plaintext in command line) both platforms" `
    -Condition ($ps1RedisAuth -and $shRedisAuth) `
    -Detail (".ps1 REDISCLI_AUTH=$ps1RedisAuth; .sh REDISCLI_AUTH=$shRedisAuth")

$ps1NoConnStr = $ps1Exists -and (-not $ps1Text.Contains("connStr"))
$shNoConnStr  = $shExists  -and (-not $shText.Contains("connStr"))
Assert-Test -CaseId "UT-161-3" -Name "no plaintext connection-string dead code (connStr) in both scripts (P7-06)" `
    -Condition ($ps1NoConnStr -and $shNoConnStr) `
    -Detail (".ps1 connStr present: $(-not $ps1NoConnStr); .sh connStr present: $(-not $shNoConnStr) (expected absent)")

# ============================================================================
# UT-162: unrelated check items removed, dead code cleaned (P1)
# ============================================================================
$deadPatterns = @("DbProviderFactory", "CurrentFileSystemDrive", "connStr", "pom.xml", "settings.xml", "auth-init")
$ps1Dead = @($deadPatterns | Where-Object { $ps1Exists -and $ps1Text.Contains($_) })
$shDead  = @($deadPatterns | Where-Object { $shExists  -and $shText.Contains($_) })
Assert-Test -CaseId "UT-162-1" -Name "dead code / unrelated items (DbProviderFactory/CurrentFileSystemDrive/connStr/pom.xml/settings.xml/auth-init) fully removed" `
    -Condition (($ps1Dead.Count -eq 0) -and ($shDead.Count -eq 0)) `
    -Detail (".ps1 hits: " + $(if ($ps1Dead.Count -eq 0) { "none" } else { $ps1Dead -join ", " }) +
             "; .sh hits: " + $(if ($shDead.Count -eq 0) { "none" } else { $shDead -join ", " }))

# Nacos HTTP probe must not be duplicated (single probe function definition + single probe call site)
$ps1IwrCount = if ($ps1Exists) { ([regex]::Matches($ps1Text, "Invoke-WebRequest")).Count } else { 99 }
$shCurlCount = if ($shExists)  { ([regex]::Matches($shText, "\bcurl\b")).Count } else { 99 }
Assert-Test -CaseId "UT-162-2" -Name "Nacos HTTP probe not duplicated (single Invoke-WebRequest / curl call site per platform, P4)" `
    -Condition ($ps1IwrCount -eq 1 -and $shCurlCount -eq 1) `
    -Detail (".ps1 Invoke-WebRequest count=$ps1IwrCount; .sh curl count=$shCurlCount (1 expected)")

# ============================================================================
# UT-163: SPDX header + Simplified-Chinese comments + version v0.2.7 (P1)
# ============================================================================
$ps1Spdx = $ps1Exists -and $ps1Text.Contains("SPDX-License-Identifier") -and $ps1Text.Contains("Apache-2.0") -and $ps1Text.Contains("Copyright 2026 jenemy8023")
$shSpdx  = $shExists  -and $shText.Contains("SPDX-License-Identifier") -and $shText.Contains("Apache-2.0") -and $shText.Contains("Copyright 2026 jenemy8023")
Assert-Test -CaseId "UT-163-1" -Name "SPDX-License-Identifier Apache-2.0 + Copyright 2026 jenemy8023 in both file headers (G10/P7-14)" `
    -Condition ($ps1Spdx -and $shSpdx) `
    -Detail (".ps1 SPDX=$ps1Spdx; .sh SPDX=$shSpdx")

$cjkRegex = "[\u4e00-\u9fff]"
$ps1Cjk = $ps1Exists -and [regex]::IsMatch($ps1Text, $cjkRegex)
$shCjk  = $shExists  -and [regex]::IsMatch($shText, $cjkRegex)
Assert-Test -CaseId "UT-163-2" -Name "comments in Simplified Chinese (CJK) in both scripts (F-011)" `
    -Condition ($ps1Cjk -and $shCjk) `
    -Detail (".ps1 CJK=$ps1Cjk; .sh CJK=$shCjk")

Assert-Test -CaseId "UT-163-3" -Name "version tag v0.2.7 unified in both scripts (G9, not stale v0.1.7)" `
    -Condition ($ps1VersionOk -and $shVersionOk) `
    -Detail (".ps1 v0.2.7=$ps1VersionOk; .sh v0.2.7=$shVersionOk")

# ============================================================================
# Functional tests (dynamic)
# ============================================================================

# ----------------------------------------------------------------------------
# Helper: execute deploy-check-env.ps1 in a child powershell via cmd, capturing
# UTF-8 output (chcp 65001) and exit code. PreCmd can set env vars for scenario.
# ----------------------------------------------------------------------------
function Invoke-CheckEnvPs1 {
    param([string]$ScriptPath, [string]$PreCmd = "")
    $tmp = Join-Path $env:TEMP ("cso_checkenv_" + [Guid]::NewGuid().ToString("N") + ".txt")
    try {
        $cmdLine = "chcp 65001 >nul 2>&1"
        if ($PreCmd) { $cmdLine = $PreCmd + " & " + $cmdLine }
        $cmdLine += " & powershell -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" > `"$tmp`" 2>&1"
        $null = & cmd /c $cmdLine
        $code = $LASTEXITCODE
        $content = ""
        if (Test-Path -LiteralPath $tmp) {
            $content = [System.IO.File]::ReadAllText($tmp, [System.Text.Encoding]::UTF8)
        }
        return @{ Output = $content; ExitCode = $code }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------------------------------------------------------
# Helper: parse summary line "check complete: pass N item(s) | warn N item(s) | fail N item(s)"
# Returns hashtable { ok, pass, warn, fail } or ok=false.
# ----------------------------------------------------------------------------
function Parse-SummaryLine {
    param([string]$Output)
    $pattern = [regex]::Escape($cjkPass) + "\s*(\d+)\s*" + [regex]::Escape($cjkItem) + "\s*\|\s*" +
               [regex]::Escape($cjkWarn) + "\s*(\d+)\s*" + [regex]::Escape($cjkItem) + "\s*\|\s*" +
               [regex]::Escape($cjkFail) + "\s*(\d+)\s*" + [regex]::Escape($cjkItem)
    $m = [regex]::Match($Output, $pattern)
    if ($m.Success) {
        return @{ ok = $true; pass = [int]$m.Groups[1].Value; warn = [int]$m.Groups[2].Value; fail = [int]$m.Groups[3].Value }
    }
    return @{ ok = $false; pass = -1; warn = -1; fail = -1 }
}

# ----------------------------------------------------------------------------
# Helper: load real env.json as object (never print credential values)
# ----------------------------------------------------------------------------
function Get-EnvJsonObject {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return (Get-Content -Raw -Encoding UTF8 $Path | ConvertFrom-Json)
}

# ----------------------------------------------------------------------------
# FT-078: JDK availability pass scenario (P0, env-gated)
# ----------------------------------------------------------------------------
$java21Ok = $false
$javaHomeOk = $false
if (Get-Command java -ErrorAction SilentlyContinue) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $javaVer = & java -version 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $javaVer -match 'version "21') { $java21Ok = $true }
    }
    catch { $java21Ok = $false }
    finally { $ErrorActionPreference = $oldEap }
}
if (-not [string]::IsNullOrEmpty($env:JAVA_HOME) -and (Test-Path $env:JAVA_HOME)) { $javaHomeOk = $true }

if ($java21Ok -and $javaHomeOk -and $envJsonExists) {
    $res078 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $jdkPassLine = $res078.Output.Contains("JDK " + $cjkUsable)
    $jdkFailLine = $res078.Output.Contains("JDK " + $cjkUnusable)
    Assert-Test -CaseId "FT-078-1" -Name "JDK availability pass scenario: 'JDK usable' output when java 21 + JAVA_HOME valid" `
        -Condition ($jdkPassLine -and (-not $jdkFailLine)) `
        -Detail ("JDK usable line present: $jdkPassLine; JDK unusable line present: $jdkFailLine (unusable expected absent); exit=$($res078.ExitCode)")
}
else {
    Skip-Test -CaseId "FT-078-1" -Name "JDK availability pass scenario (java 21 + valid JAVA_HOME)" `
        -Detail "host does not satisfy precondition (java21=$java21Ok, JAVA_HOME valid=$javaHomeOk, env.json=$envJsonExists) - environment blocked, static logic covered by UT-157-1"
}

# ----------------------------------------------------------------------------
# FT-079: JDK missing / JAVA_HOME invalid scenario -> fail + non-zero exit (P0)
# ----------------------------------------------------------------------------
# NOTE: javaOk AND javaHomeOk both required; an invalid JAVA_HOME alone makes
# the JDK conclusion fail (java command stays available via PATH, that is fine).
$jdkFailPreCmd = "set JAVA_HOME=C:\__cso_invalid_jdk__"
$res079 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1 -PreCmd $jdkFailPreCmd
$jdkUnusable = $res079.Output.Contains("JDK " + $cjkUnusable)
$jdkGuidance = $res079.Output.Contains($cjkPlease + $cjkInstall) -and $res079.Output.Contains("JDK 21")
Assert-Test -CaseId "FT-079-1" -Name "JDK missing/invalid scenario: 'JDK unusable' + install guidance, script exits non-zero (1)" `
    -Condition (($jdkUnusable -or $jdkGuidance) -and $res079.ExitCode -ne 0) `
    -Detail ("JDK unusable=$jdkUnusable; install guidance(please install JDK 21)=$jdkGuidance; exit=$($res079.ExitCode) (non-zero expected)")

# ----------------------------------------------------------------------------
# FT-080: MariaDB availability pass scenario (P0, env-gated)
# ----------------------------------------------------------------------------
$dbClientCmd = $null
if (Get-Command mariadb -ErrorAction SilentlyContinue) { $dbClientCmd = "mariadb" }
elseif (Get-Command mysql -ErrorAction SilentlyContinue) { $dbClientCmd = "mysql" }
$envJsonObj = Get-EnvJsonObject -Path $envJsonPath
$dbProbeOk = $false
if ($dbClientCmd -and $envJsonObj) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $null = & $dbClientCmd -h $envJsonObj.DB_HOST -P $envJsonObj.DB_PORT -u $envJsonObj.DB_USERNAME -p"$envJsonObj.DB_PASSWORD" -N -B -e "SELECT 1" 2>&1
        $dbProbeOk = ($LASTEXITCODE -eq 0)
    }
    finally {
        $ErrorActionPreference = $oldEap
    }
}
if ($dbClientCmd -and $dbProbeOk -and $envJsonExists) {
    $res080 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $dbPassLine = $res080.Output.Contains("MariaDB " + $cjkUsable)
    $dbFailLine = $res080.Output.Contains($cjkConnfail)
    Assert-Test -CaseId "FT-080-1" -Name "MariaDB availability pass scenario: 'MariaDB usable' (install hit + SELECT 1 OK) when DB reachable" `
        -Condition ($dbPassLine -and (-not $dbFailLine)) `
        -Detail ("MariaDB usable line present: $dbPassLine; connfail line present: $dbFailLine (absent expected); exit=$($res080.ExitCode)")
}
else {
    Skip-Test -CaseId "FT-080-1" -Name "MariaDB availability pass scenario (mariadb/mysql client + SELECT 1 reachable)" `
        -Detail "host does not satisfy precondition (client=$dbClientCmd, SELECT 1 probe=$dbProbeOk, env.json=$envJsonExists) - environment blocked, static logic covered by UT-157-2"
}

# ----------------------------------------------------------------------------
# FT-081: MariaDB installed but not connectable -> fail + non-zero exit (P0)
# ----------------------------------------------------------------------------
if ($dbClientCmd -and $envJsonExists) {
    $backup081 = [System.IO.File]::ReadAllText($envJsonPath, [System.Text.Encoding]::UTF8)
    try {
        $json081 = Get-Content -Raw -Encoding UTF8 $envJsonPath | ConvertFrom-Json
        $json081.DB_PORT = "13306"   # un-listened port -> SELECT 1 fails
        [System.IO.File]::WriteAllText($envJsonPath, ($json081 | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
        $res081 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
        $connFailMsg = $res081.Output.Contains($cjkConnfail) -and $res081.Output.Contains($cjkPleasecheck)
        Assert-Test -CaseId "FT-081-1" -Name "MariaDB installed but not connectable: 'connection failed + please check env.json' and non-zero exit" `
            -Condition ($connFailMsg -and $res081.ExitCode -eq 1) `
            -Detail ("connfail+pleasecheck present: $connFailMsg; exit=$($res081.ExitCode) (1 expected)")
    }
    finally {
        [System.IO.File]::WriteAllText($envJsonPath, $backup081, (New-Object System.Text.UTF8Encoding($false)))
    }
}
else {
    Skip-Test -CaseId "FT-081-1" -Name "MariaDB installed but not connectable (needs mariadb/mysql client + real env.json)" `
        -Detail "host does not satisfy precondition (client=$dbClientCmd, env.json=$envJsonExists) - environment blocked"
}

# ----------------------------------------------------------------------------
# FT-082: Redis availability pass scenario (P0, env-gated)
# ----------------------------------------------------------------------------
$redisCliOk = $null -ne (Get-Command redis-cli -ErrorAction SilentlyContinue)
$redisProbeOk = $false
if ($redisCliOk -and $envJsonObj) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        if (-not [string]::IsNullOrEmpty($envJsonObj.REDIS_PASSWORD)) { $env:REDISCLI_AUTH = [string]$envJsonObj.REDIS_PASSWORD }
        $pong = & redis-cli -h $envJsonObj.REDIS_HOST -p $envJsonObj.REDIS_PORT ping 2>&1
        $redisProbeOk = ($pong -match "PONG")
    }
    finally {
        Remove-Item -Path Env:REDISCLI_AUTH -ErrorAction SilentlyContinue
        $ErrorActionPreference = $oldEap
    }
}
if ($redisCliOk -and $redisProbeOk -and $envJsonExists) {
    $res082 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $redisPassLine = $res082.Output.Contains("Redis " + $cjkUsable)
    $redisFailLine = $res082.Output.Contains("ping " + $cjkFail) -or $res082.Output.Contains("Redis " + $cjkUnusable)
    Assert-Test -CaseId "FT-082-1" -Name "Redis availability pass scenario: 'Redis usable' (install hit + ping PONG) when Redis reachable" `
        -Condition ($redisPassLine -and (-not $redisFailLine)) `
        -Detail ("Redis usable line present: $redisPassLine; Redis fail/ping-fail line present: $redisFailLine (absent expected); exit=$($res082.ExitCode)")
}
else {
    Skip-Test -CaseId "FT-082-1" -Name "Redis availability pass scenario (redis-cli + ping PONG reachable)" `
        -Detail "host does not satisfy precondition (redis-cli=$redisCliOk, ping probe=$redisProbeOk, env.json=$envJsonExists) - environment blocked, static logic covered by UT-157-3"
}

# ----------------------------------------------------------------------------
# FT-083: Redis installed but ping fail -> fail + non-zero exit (P0)
# ----------------------------------------------------------------------------
if ($redisCliOk -and $envJsonExists) {
    $backup083 = [System.IO.File]::ReadAllText($envJsonPath, [System.Text.Encoding]::UTF8)
    try {
        $json083 = Get-Content -Raw -Encoding UTF8 $envJsonPath | ConvertFrom-Json
        $json083.REDIS_PORT = "16379"   # un-listened port -> ping fails
        [System.IO.File]::WriteAllText($envJsonPath, ($json083 | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
        $res083 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
        $pingFailMsg = $res083.Output.Contains("ping " + $cjkFail) -and $res083.Output.Contains($cjkPleasecheck)
        Assert-Test -CaseId "FT-083-1" -Name "Redis installed but ping fail: 'ping failed + please check env.json' and non-zero exit" `
            -Condition ($pingFailMsg -and $res083.ExitCode -eq 1) `
            -Detail ("pingfail+pleasecheck present: $pingFailMsg; exit=$($res083.ExitCode) (1 expected)")
    }
    finally {
        [System.IO.File]::WriteAllText($envJsonPath, $backup083, (New-Object System.Text.UTF8Encoding($false)))
    }
}
else {
    Skip-Test -CaseId "FT-083-1" -Name "Redis installed but ping fail (needs redis-cli + real env.json)" `
        -Detail "host does not satisfy precondition (redis-cli=$redisCliOk, env.json=$envJsonExists) - environment blocked"
}

# ----------------------------------------------------------------------------
# FT-084: Nacos installed-not-started -> warning (not running) (P0)
# ----------------------------------------------------------------------------
if ($envJsonExists) {
    $backup084 = [System.IO.File]::ReadAllText($envJsonPath, [System.Text.Encoding]::UTF8)
    $fakeNacosHome = Join-Path $env:TEMP ("cso_fake_nacos_" + [Guid]::NewGuid().ToString("N"))
    try {
        # fake NACOS_HOME with bin/startup.cmd (installed), NACOS_ADDR points to an un-listened port (not started)
        New-Item -ItemType Directory -Path (Join-Path $fakeNacosHome "bin") -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $fakeNacosHome "bin\startup.cmd"), "# fake startup", (New-Object System.Text.UTF8Encoding($false)))
        $json084 = Get-Content -Raw -Encoding UTF8 $envJsonPath | ConvertFrom-Json
        $json084.NACOS_HOME = $fakeNacosHome
        $json084.NACOS_ADDR = "127.0.0.1:48848"   # guaranteed not listening
        [System.IO.File]::WriteAllText($envJsonPath, ($json084 | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
        $res084 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
        $warnNotRun = $res084.Output.Contains($cjkWarn) -and $res084.Output.Contains($cjkNotrun)
        $failOrNotinst = $res084.Output.Contains("Nacos " + $cjkUnusable) -or $res084.Output.Contains("Nacos " + $cjkNotinst)
        $summary084 = Parse-SummaryLine -Output $res084.Output
        $warnCounted = $summary084.ok -and ($summary084.warn -ge 1)
        $exitConsistent = $summary084.ok -and ($res084.ExitCode -eq $(if ($summary084.fail -gt 0) { 1 } else { 0 }))
        Assert-Test -CaseId "FT-084-1" -Name "Nacos installed-not-started: graded warning 'not running' (counted in warning, not fail/not-installed) + exit consistent with summary (F-005)" `
            -Condition ($warnNotRun -and (-not $failOrNotinst) -and $warnCounted -and $exitConsistent) `
            -Detail ("warn+notrun present: $warnNotRun; Nacos fail/notinst line present: $failOrNotinst (absent expected); summary pass=$($summary084.pass) warn=$($summary084.warn) fail=$($summary084.fail); exit=$($res084.ExitCode) consistent=$exitConsistent")
    }
    finally {
        Remove-Item -LiteralPath $fakeNacosHome -Recurse -Force -ErrorAction SilentlyContinue
        [System.IO.File]::WriteAllText($envJsonPath, $backup084, (New-Object System.Text.UTF8Encoding($false)))
    }
}
else {
    Skip-Test -CaseId "FT-084-1" -Name "Nacos installed-not-started warning scenario (needs real env.json)" `
        -Detail "env.json absent ($envJsonExists) - environment blocked, static logic covered by UT-158"
}

# ----------------------------------------------------------------------------
# FT-085: Nacos not installed -> fail + non-zero exit (P0)
# ----------------------------------------------------------------------------
if ($envJsonExists) {
    $backup085 = [System.IO.File]::ReadAllText($envJsonPath, [System.Text.Encoding]::UTF8)
    try {
        $json085 = Get-Content -Raw -Encoding UTF8 $envJsonPath | ConvertFrom-Json
        $json085.NACOS_HOME = "C:\__cso_no_such_nacos__"   # non-existent dir -> not installed
        [System.IO.File]::WriteAllText($envJsonPath, ($json085 | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))
        $res085 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
        $notinstMsg = $res085.Output.Contains("Nacos " + $cjkNotinst) -and $res085.Output.Contains($cjkPlease + $cjkInstall)
        Assert-Test -CaseId "FT-085-1" -Name "Nacos not installed: 'Nacos not-installed + please install' and non-zero exit (1)" `
            -Condition ($notinstMsg -and $res085.ExitCode -eq 1) `
            -Detail ("notinst+please-install present: $notinstMsg; exit=$($res085.ExitCode) (1 expected)")
    }
    finally {
        [System.IO.File]::WriteAllText($envJsonPath, $backup085, (New-Object System.Text.UTF8Encoding($false)))
    }
}
else {
    Skip-Test -CaseId "FT-085-1" -Name "Nacos not installed scenario (needs real env.json)" `
        -Detail "env.json absent ($envJsonExists) - environment blocked"
}

# ----------------------------------------------------------------------------
# FT-086: Nacos running scenario (P1, env-gated)
# ----------------------------------------------------------------------------
$nacosAddrProbe = "127.0.0.1:8848"
if ($envJsonObj -and $envJsonObj.NACOS_ADDR) { $nacosAddrProbe = [string]$envJsonObj.NACOS_ADDR }
$nacosHttpRunning = $false
try {
    $respNacos = Invoke-WebRequest -Uri "http://$nacosAddrProbe/nacos/" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    $nacosHttpRunning = ($respNacos.Content -match "Nacos")
}
catch { $nacosHttpRunning = $false }

if ($nacosHttpRunning -and $envJsonExists) {
    $res086 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $nacosUsable = $res086.Output.Contains("Nacos " + $cjkUsable)
    $nacosRunState = $res086.Output.Contains("Nacos " + $cjkRunstate) -and $res086.Output.Contains($cjkRunning)
    Assert-Test -CaseId "FT-086-1" -Name "Nacos running scenario: availability pass + running state 'running' (HTTP probe returns Nacos)" `
        -Condition ($nacosUsable -and $nacosRunState) `
        -Detail ("Nacos usable=$nacosUsable; Nacos running-state running=$nacosRunState; exit=$($res086.ExitCode)")
}
else {
    Skip-Test -CaseId "FT-086-1" -Name "Nacos running scenario (HTTP probe http://$nacosAddrProbe/nacos/ contains Nacos)" `
        -Detail "Nacos service not detected running (probe=$nacosHttpRunning, env.json=$envJsonExists) - environment blocked"
}

# ----------------------------------------------------------------------------
# FT-087: env.json missing -> env.example.json guidance + non-zero exit (P0)
# ----------------------------------------------------------------------------
if ($envJsonExists) {
    $backup087 = [System.IO.File]::ReadAllText($envJsonPath, [System.Text.Encoding]::UTF8)
    $movedDest = ""
    try {
        $movedDest = Join-Path $env:TEMP ("cso_envjson_backup_" + [Guid]::NewGuid().ToString("N") + ".json")
        Move-Item -LiteralPath $envJsonPath -Destination $movedDest -Force
        $res087 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
        $guidance = $res087.Output.Contains($cjkEnvfile) -and $res087.Output.Contains("env.example.json") -and
                    $res087.Output.Contains($cjkCopy) -and $res087.Output.Contains($cjkFill)
        Assert-Test -CaseId "FT-087-1" -Name "env.json missing: guidance 'copy env.example.json + fill config' and non-zero exit (load-env F-001)" `
            -Condition ($guidance -and $res087.ExitCode -ne 0) `
            -Detail ("guidance(copy+env.example.json+fill)=$guidance; exit=$($res087.ExitCode) (non-zero expected)")
    }
    finally {
        if (Test-Path -LiteralPath $movedDest) {
            Move-Item -LiteralPath $movedDest -Destination $envJsonPath -Force
        }
        else {
            [System.IO.File]::WriteAllText($envJsonPath, $backup087, (New-Object System.Text.UTF8Encoding($false)))
        }
    }
}
else {
    Skip-Test -CaseId "FT-087-1" -Name "env.json missing scenario (deploy/env.json absent on this host - cannot restore)" `
        -Detail "real deploy/env.json not present ($envJsonExists) - scenario cannot be safely constructed, load-env missing path covered by FT-074"
}

# ----------------------------------------------------------------------------
# FT-088: running-state detection scenario (P1, env-gated per item)
# ----------------------------------------------------------------------------
$dbRunningProbe = $false
if ($envJsonObj) {
    $dbProcHit = Get-Process -Name @("mysqld", "mariadbd") -ErrorAction SilentlyContinue
    if ($dbProcHit) { $dbRunningProbe = $true }
    else {
        $tcpDb = Test-NetConnection -ComputerName $envJsonObj.DB_HOST -Port $envJsonObj.DB_PORT -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($tcpDb) { $dbRunningProbe = $true }
    }
}
$redisRunningProbe = $false
if ($envJsonObj) {
    $redisProcHit = Get-Process -Name "redis-server" -ErrorAction SilentlyContinue
    if ($redisProcHit) { $redisRunningProbe = $true }
    else {
        $tcpRedis = Test-NetConnection -ComputerName $envJsonObj.REDIS_HOST -Port $envJsonObj.REDIS_PORT -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($tcpRedis) { $redisRunningProbe = $true }
    }
}

$anyRunProbe = ($java21Ok -and $javaHomeOk) -or $dbRunningProbe -or $redisRunningProbe
if ($anyRunProbe -and $envJsonExists) {
    $res088 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    if ($java21Ok -and $javaHomeOk) {
        $jdkReadyLine = $res088.Output.Contains("JDK " + $cjkRunstate) -and $res088.Output.Contains($cjkReady)
        Assert-Test -CaseId "FT-088-1" -Name "JDK running state shows 'ready' (reuse availability conclusion)" `
            -Condition $jdkReadyLine -Detail ("JDK running-state ready line=$jdkReadyLine")
    }
    else {
        Skip-Test -CaseId "FT-088-1" -Name "JDK running state 'ready' (java 21 + valid JAVA_HOME required)" `
            -Detail "host precondition not met (java21=$java21Ok, JAVA_HOME valid=$javaHomeOk) - environment blocked"
    }
    if ($dbRunningProbe) {
        $dbRunningLine = $res088.Output.Contains("MariaDB " + $cjkRunstate) -and $res088.Output.Contains($cjkRunning)
        Assert-Test -CaseId "FT-088-2" -Name "MariaDB running state shows 'running' (process/service/TCP any-hit)" `
            -Condition $dbRunningLine -Detail ("MariaDB running-state running line=$dbRunningLine")
    }
    else {
        Skip-Test -CaseId "FT-088-2" -Name "MariaDB running state 'running' (process/TCP probe required)" `
            -Detail "host precondition not met (dbRunningProbe=$dbRunningProbe) - environment blocked"
    }
    if ($redisRunningProbe) {
        $redisRunningLine = $res088.Output.Contains("Redis " + $cjkRunstate) -and $res088.Output.Contains($cjkRunning)
        Assert-Test -CaseId "FT-088-3" -Name "Redis running state shows 'running' (process/service/TCP any-hit)" `
            -Condition $redisRunningLine -Detail ("Redis running-state running line=$redisRunningLine")
    }
    else {
        Skip-Test -CaseId "FT-088-3" -Name "Redis running state 'running' (process/TCP probe required)" `
            -Detail "host precondition not met (redisRunningProbe=$redisRunningProbe) - environment blocked"
    }
}
else {
    Skip-Test -CaseId "FT-088-1" -Name "running-state detection scenario (JDK ready / MariaDB running / Redis running probes)" `
        -Detail ("no running probe satisfied on this host (jdk21=$java21Ok javaHome=$javaHomeOk dbRunning=$dbRunningProbe redisRunning=$redisRunningProbe) or env.json absent ($envJsonExists)")
}

# ----------------------------------------------------------------------------
# FT-089: output grading summary + exit code contract (P0)
# ----------------------------------------------------------------------------
if ($envJsonExists) {
    $res089 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $summary089 = Parse-SummaryLine -Output $res089.Output
    $gradingText = $res089.Output.Contains($cjkPass) -and $res089.Output.Contains($cjkWarn) -and $res089.Output.Contains($cjkFail)
    $exitConsistent = $summary089.ok -and ($res089.ExitCode -eq $(if ($summary089.fail -gt 0) { 1 } else { 0 }))
    Assert-Test -CaseId "FT-089-1" -Name "output grading: summary shows pass/warn/fail counts and exit code consistent (fail>0 -> 1, else 0, F-011)" `
        -Condition ($summary089.ok -and $gradingText -and $exitConsistent) `
        -Detail ("summary parsed: $($summary089.ok); grading text present: $gradingText; pass=$($summary089.pass) warn=$($summary089.warn) fail=$($summary089.fail); exit=$($res089.ExitCode) consistent=$exitConsistent")
}
else {
    Skip-Test -CaseId "FT-089-1" -Name "output grading summary + exit code contract (needs real env.json)" `
        -Detail "env.json absent ($envJsonExists) - environment blocked, static exit contract covered by UT-160"
}

# ----------------------------------------------------------------------------
# FT-090: password masking - no DB_PASSWORD/REDIS_PASSWORD plaintext (P0)
# ----------------------------------------------------------------------------
if ($envJsonExists) {
    $res090 = Invoke-CheckEnvPs1 -ScriptPath $checkEnvPs1
    $dbPassVal = if ($envJsonObj -and $envJsonObj.DB_PASSWORD) { [string]$envJsonObj.DB_PASSWORD } else { "" }
    $redisPassVal = if ($envJsonObj -and $envJsonObj.REDIS_PASSWORD) { [string]$envJsonObj.REDIS_PASSWORD } else { "" }
    $dbPassLeak = (-not [string]::IsNullOrEmpty($dbPassVal)) -and $res090.Output.Contains($dbPassVal)
    $redisPassLeak = (-not [string]::IsNullOrEmpty($redisPassVal)) -and $res090.Output.Contains($redisPassVal)
    # Mask "****" is only displayed when the script reaches password-handling
    # branches (MariaDB usable/connfail, Redis usable/pingfail). On hosts where
    # MariaDB/Redis are not installed there is no credential output at all, so
    # the mask is not required; the P0 contract is "no plaintext leak" above.
    $dbRedisSecMsg = $res090.Output.Contains("MariaDB " + $cjkUsable) -or $res090.Output.Contains($cjkConnfail) -or
                     $res090.Output.Contains("Redis " + $cjkUsable) -or $res090.Output.Contains("ping " + $cjkFail)
    $maskShown = (-not $dbRedisSecMsg) -or $res090.Output.Contains("****")
    Assert-Test -CaseId "FT-090-1" -Name "script output contains no DB_PASSWORD / REDIS_PASSWORD plaintext (masked **** displayed, F-003/F-004 security)" `
        -Condition ((-not $dbPassLeak) -and (-not $redisPassLeak) -and $maskShown) `
        -Detail ("DB_PASSWORD plaintext leaked: $dbPassLeak; REDIS_PASSWORD plaintext leaked: $redisPassLeak; mask '****' shown(required only in password branches): $maskShown; exit=$($res090.ExitCode)")
}
else {
    Skip-Test -CaseId "FT-090-1" -Name "password masking output check (needs real env.json with credentials)" `
        -Detail "env.json absent ($envJsonExists) - environment blocked, static masking covered by UT-161"
}

# ----------------------------------------------------------------------------
# FT-091: dual-platform behavior consistency (P1)
# ----------------------------------------------------------------------------
if ($bashUsable) {
    $native = $checkEnvSh
    $wslPath = $native
    if ($native -match "^([A-Za-z]):\\(.*)$") {
        $wslPath = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
    }
    $shOut = (& bash -c "bash -n '$wslPath' && echo SH_SYNTAX_OK" 2>&1)
    $shOk = ($LASTEXITCODE -eq 0)
    Assert-Test -CaseId "FT-091-1" -Name "dual-platform consistency: bash -n passes on .sh when bash/WSL available" `
        -Condition $shOk -Detail ("bash -n output: " + ($shOut -join " "))
}
else {
    Skip-Test -CaseId "FT-091-1" -Name "dual-platform behavior consistency (dynamic .ps1 vs .sh comparison)" `
        -Detail "bash/WSL not usable on this host - .sh dynamic behavior SKIP, not a failure; static dual-platform contract covered by UT-153/154/157~162"
}

# ============================================================================
# Summary
# ============================================================================
Write-Output ("=" * 70)
Write-Output "Summary: PASS=$($script:Pass) FAIL=$($script:Fail) SKIP=$($script:Skip)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    $script:FailedCases | ForEach-Object { Write-Output "  - $_" }
}
if ($script:SkippedCases.Count -gt 0) {
    Write-Output "Skipped cases (environment blocked, not counted as failure):"
    $script:SkippedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }

