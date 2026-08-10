# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - deploy-start-{gateway,auth,biz,system} Test (TASK-006)
# ----------------------------------------------------------------------------
# Coverage: UT-190 ~ UT-202 + FT-119 ~ FT-133 in task testcase
#           (docs/cso-v0.2.7/task_TASK-006/testcase.md)
#   UT-190: 4 x deploy-start-{svc}.ps1 parseable via PowerShell Parser (P0)
#   UT-191: 4 x deploy-start-{svc}.sh syntax check via bash -n (fallback if no bash) (P0)
#   UT-192: dual-platform scripts both exist, name/file 1:1 pairing (P1)
#   UT-193: SPDX header + copyright + version v0.2.7 + no deprecated references (P0)
#   UT-194: load-env call contract + no hard-coded addresses (P0)
#   UT-195: per-service required-vars scope (gateway/auth/biz/system) static (P0)
#   UT-196: biz DB_USER vs auth DB_USERNAME difference kept (P1)
#   UT-197: jar existence precheck + unified start command (P0)
#   UT-198: backgrounded start + log/PID placement (P0)
#   UT-199: health confirm logic (HTTP first + TCP backup + 30/2/3 defaults) (P0)
#   UT-200: output grading [pass]/[warn]/[fail] + exit-code contract F-011 (P0)
#   UT-201: no plaintext sensitive value in output (P0, security)
#   UT-202: static consistency with deploy-start-all per-service block (P0)
#   FT-119: gateway.ps1 missing RSA_PUBLIC_KEY -> key name + [fail] + exit 1 (P0, dynamic)
#   FT-120: auth.ps1 missing RSA_PRIVATE_KEY -> key name + [fail] + exit 1 (P0, dynamic)
#   FT-121: biz.ps1 missing DB_PASSWORD -> key name + exit 1 + no start (P0, dynamic)
#   FT-122: system.ps1 missing DB_PASSWORD -> key name + exit 1 + no start (P0, dynamic)
#   FT-123: gateway.ps1 jar missing -> jar name + hint + exit 1 + no start (P0, dynamic)
#   FT-124: auth.ps1 jar missing -> jar name + hint + exit 1 + no start (P0, dynamic)
#   FT-125: biz.ps1 jar missing -> jar name + hint + exit 1 + no start (P0, dynamic)
#   FT-126: system.ps1 jar missing -> jar name + hint + exit 1 + no start (P0, dynamic)
#   FT-127: gateway.ps1 all ready -> backgrounded + health ok + exit 0 (P0, env-gated)
#   FT-128: auth.ps1 all ready -> backgrounded + health ok + exit 0 (P0, env-gated)
#   FT-129: biz.ps1 all ready -> backgrounded + health ok + exit 0 (P0, env-gated)
#   FT-130: system.ps1 all ready -> backgrounded + health ok + exit 0 (P0, env-gated)
#   FT-131: env.json missing -> copy env.example guidance + non-zero exit (P0, dynamic)
#   FT-132: .sh dual-platform behavior (P1, SKIP if no bash/WSL)
#   FT-133: already-running idempotent run + grading summary + exit code (P1, env-gated)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-single-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-start-single-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo [-RunServiceTests]
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
#   the TASK-005 start-all test).
#   FT-127~130/133 require real backend services (already-running idempotent
#   scenario) - they only run when -RunServiceTests is given; otherwise SKIP
#   (environment gated, static coverage via UT-197~202). The 4 backend
#   services may be running on this host: default run NEVER starts a real
#   service, so running services are never disturbed.
#   .sh dynamic assertions require bash/WSL; when unavailable they are
#   SKIP (static dual-platform coverage via UT-191/195/202).
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$RunServiceTests
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0
$script:FailedCases = @()
$script:SkippedCases = @()
$script:LastRunOutput = ""   # cache of the latest isolated dynamic run output (security check)

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
        "pass"           { return [string][char]0x901A + [string][char]0x8FC7 }          # 通过
        "warn"           { return [string][char]0x8B66 + [string][char]0x544A }          # 警告
        "fail"           { return [string][char]0x5931 + [string][char]0x8D25 }          # 失败
        "missempty"      { return [string][char]0x7F3A + [string][char]0x5931 + [string][char]0x6216 + [string][char]0x4E3A + [string][char]0x7A7A }  # 缺失或为空
        "noprint"        { return [string][char]0x4E0D + [string][char]0x6253 + [string][char]0x5370 + [string][char]0x503C }                          # 不打印值
        "keyenv"         { return [string][char]0x5173 + [string][char]0x952E + [string][char]0x73AF + [string][char]0x5883 + [string][char]0x53D8 + [string][char]0x91CF }  # 关键环境变量
        "jarmiss"        { return "jar " + [string][char]0x5305 + [string][char]0x7F3A + [string][char]0x5931 }                                        # jar 包缺失
        "nostart"        { return [string][char]0x672C + [string][char]0x6B21 + [string][char]0x672A + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x670D + [string][char]0x52A1 }  # 本次未启动服务
        "check"          { return [string][char]0x8BF7 + [string][char]0x68C0 + [string][char]0x67E5 }                                                # 请检查
        "config"         { return [string][char]0x914D + [string][char]0x7F6E }                                                                        # 配置
        "copy"           { return [string][char]0x590D + [string][char]0x5236 }                                                                        # 复制
        "fillconfig"     { return [string][char]0x586B + [string][char]0x5199 + [string][char]0x914D + [string][char]0x7F6E }                          # 填写配置
        "hconfirm"       { return [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 }                          # 健康确认
        "hconfirmok"     { return [string][char]0x5DF2 + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x4E14 + [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 + [string][char]0x6210 + [string][char]0x529F }  # 已启动且健康确认成功
        "htimeout"       { return [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 + [string][char]0x8D85 + [string][char]0x65F6 }  # 健康确认超时
        "viewlog"        { return [string][char]0x8BF7 + [string][char]0x67E5 + [string][char]0x770B + [string][char]0x65E5 + [string][char]0x5FD7 }  # 请查看日志
        "summaryline"    { return [string][char]0x670D + [string][char]0x52A1 + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x5B8C + [string][char]0x6210 }  # 服务启动完成
        "startokmsg"     { return [string][char]0x670D + [string][char]0x52A1 + [string][char]0x542F + [string][char]0x52A8 + [string][char]0x6210 + [string][char]0x529F + [string][char]0x4E14 + [string][char]0x5065 + [string][char]0x5EB7 + [string][char]0x786E + [string][char]0x8BA4 + [string][char]0x901A + [string][char]0x8FC7 }  # 服务启动成功且健康确认通过
        "precheckfail"   { return [string][char]0x524D + [string][char]0x7F6E + [string][char]0x6821 + [string][char]0x9A8C + [string][char]0x672A + [string][char]0x901A + [string][char]0x8FC7 }  # 前置校验未通过
        "keypair"        { return [string][char]0x5BC6 + [string][char]0x94A5 + [string][char]0x5BF9 }                                                  # 密钥对
        "item"           { return [string][char]0x9879 }                                                                                                # 项
        "version"        { return [string][char]0x7248 + [string][char]0x672C }                                                                        # 版本
        "allready"       { return [string][char]0x5168 + [string][char]0x90E8 + [string][char]0x5C31 + [string][char]0x7EEA }                          # 全部就绪
        "miss"           { return [string][char]0x7F3A + [string][char]0x5931 }                                                                        # 缺失
    }
    return ""
}

# ============================================================================
# locate assets + read scripts
# ============================================================================
$deployDir     = Join-Path $ProjectRoot "deploy"
$scriptsDir    = Join-Path $deployDir "scripts"
$envJsonPath   = Join-Path $deployDir "env.json"
$logDir        = Join-Path $deployDir "logs"
$envJsonExists = Test-FileExists $envJsonPath

# service contract table (same as task testcase / deploy-start-all)
$services = @(
    @{ Name = "gateway"; Jar = "cloudoffice-gateway.jar";      Port = 9000; Ps1 = "deploy-start-gateway.ps1"; Sh = "deploy-start-gateway.sh" },
    @{ Name = "auth";    Jar = "cloudoffice-auth-service.jar"; Port = 9100; Ps1 = "deploy-start-auth.ps1";    Sh = "deploy-start-auth.sh" },
    @{ Name = "biz";     Jar = "cloudoffice-biz-service.jar";  Port = 9200; Ps1 = "deploy-start-biz.ps1";     Sh = "deploy-start-biz.sh" },
    @{ Name = "system";  Jar = "cloudoffice-system-service.jar"; Port = 9400; Ps1 = "deploy-start-system.ps1"; Sh = "deploy-start-system.sh" }
)

$ps1Files = @{}
$shFiles  = @{}
foreach ($svc in $services) {
    $ps1Files[$svc.Name] = Join-Path $scriptsDir $svc.Ps1
    $shFiles[$svc.Name]  = Join-Path $scriptsDir $svc.Sh
}
$ps1Texts = @{}
$shTexts  = @{}
foreach ($svc in $services) {
    $ps1Texts[$svc.Name] = if (Test-FileExists $ps1Files[$svc.Name]) { Read-Utf8File $ps1Files[$svc.Name] } else { "" }
    $shTexts[$svc.Name]  = if (Test-FileExists $shFiles[$svc.Name])  { Read-Utf8File $shFiles[$svc.Name] }  else { "" }
}

$allPs1Path = Join-Path $scriptsDir "deploy-start-all.ps1"
$allShPath  = Join-Path $scriptsDir "deploy-start-all.sh"
$allPs1Text = if (Test-FileExists $allPs1Path) { Read-Utf8File $allPs1Path } else { "" }
$allShText  = if (Test-FileExists $allShPath)  { Read-Utf8File $allShPath }  else { "" }

# bash usability probe (WSL shim may exist while distro cannot run)
$bashUsable = $false
if (Get-Command bash -ErrorAction SilentlyContinue) {
    $null = (& bash -c "true" 2>&1)
    if ($LASTEXITCODE -eq 0) { $bashUsable = $true }
}

# CJK shortcuts
$cjkPass         = Get-CjkText "pass"
$cjkWarn         = Get-CjkText "warn"
$cjkFail         = Get-CjkText "fail"
$cjkMissEmpty    = Get-CjkText "missempty"
$cjkNoPrint      = Get-CjkText "noprint"
$cjkKeyEnv       = Get-CjkText "keyenv"
$cjkJarMiss      = Get-CjkText "jarmiss"
$cjkNoStart      = Get-CjkText "nostart"
$cjkCheck        = Get-CjkText "check"
$cjkConfig       = Get-CjkText "config"
$cjkCopy         = Get-CjkText "copy"
$cjkFillConfig   = Get-CjkText "fillconfig"
$cjkHConfirm     = Get-CjkText "hconfirm"
$cjkHConfirmOk   = Get-CjkText "hconfirmok"
$cjkHTimeout     = Get-CjkText "htimeout"
$cjkViewLog      = Get-CjkText "viewlog"
$cjkSummaryLine  = Get-CjkText "summaryline"
$cjkStartOkMsg   = Get-CjkText "startokmsg"
$cjkPrecheckFail = Get-CjkText "precheckfail"
$cjkKeyPair      = Get-CjkText "keypair"
$cjkItem         = Get-CjkText "item"
$cjkVersion      = Get-CjkText "version"
$cjkAllReady     = Get-CjkText "allready"
$cjkMiss         = Get-CjkText "miss"

# expected per-service required vars (F-009 contract table)
$requiredVarsMap = @{
    gateway = @("NACOS_ADDR", "RSA_PUBLIC_KEY")
    auth    = @("NACOS_ADDR", "RSA_PUBLIC_KEY", "RSA_PRIVATE_KEY", "DB_PASSWORD")
    biz     = @("NACOS_ADDR", "DB_PASSWORD")
    system  = @("NACOS_ADDR", "DB_PASSWORD")
}
# expected health URL contract
$healthUrlMap = @{
    gateway = "http://localhost:9000/"
    auth    = "http://localhost:9100/api/v1/auth/health"
    biz     = "http://localhost:9200/api/v1/biz/health"
    system  = "http://localhost:9400/api/v1/system/health"
}

Write-Output ""
Write-Output "CSO v0.2.7 deploy-start-{svc} Test (TASK-006, UT-190~UT-202 + FT-119~FT-133)"

# ============================================================================
# UT-190: 4 x .ps1 parseable via PowerShell Parser (P0)
# ============================================================================
$ps1ParseOk = $true
$ps1ParseDetail = ""
foreach ($svc in $services) {
    $p = $ps1Files[$svc.Name]
    $parseErrors = $null
    $tokens = $null
    [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) { $ps1ParseOk = $false; $ps1ParseDetail += "$($svc.Name) errors=$($parseErrors.Count); " }
}
Assert-Test -CaseId "UT-190-1" -Name "4 x deploy-start-{svc}.ps1 parseable via PowerShell Parser, zero errors (P0)" `
    -Condition $ps1ParseOk -Detail ("parse ok=$ps1ParseOk $ps1ParseDetail")

$ps1MainOk = $true
foreach ($svc in $services) {
    $t = $ps1Texts[$svc.Name]
    $hasBlocks = $t.Contains('$PSScriptRoot\load-env.ps1') -and
        $t.Contains("function Write-Result") -and
        $t.Contains("Get-Command java") -and
        $t.Contains("Start-Process") -and
        $t.Contains("Wait-HealthUp") -and
        $t.Contains("exit 1") -and $t.Contains("exit 0")
    if (-not $hasBlocks) { $ps1MainOk = $false; $ps1ParseDetail += "$($svc.Name) missing main blocks; " }
}
Assert-Test -CaseId "UT-190-2" -Name "main flow blocks present in all 4 .ps1 (load-env/precheck/start/health-confirm/summary+exit)" `
    -Condition $ps1MainOk -Detail ("main blocks ok=$ps1MainOk")

# ============================================================================
# UT-191: 4 x .sh syntax check via bash -n (P0, fallback if no bash)
# ============================================================================
$shSyntaxOk = $true
$shSyntaxDetail = ""
if ($bashUsable) {
    foreach ($svc in $services) {
        $wslSh = $shFiles[$svc.Name]
        if ($wslSh -match "^([A-Za-z]):\\(.*)$") {
            $wslSh = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $null = (& bash -n $wslSh 2>&1)
        if ($LASTEXITCODE -ne 0) { $shSyntaxOk = $false; $shSyntaxDetail += "$($svc.Name) bash -n exit=$($LASTEXITCODE); " }
    }
    Assert-Test -CaseId "UT-191-1" -Name "4 x deploy-start-{svc}.sh syntax check via bash -n, exit code 0 (P0)" `
        -Condition $shSyntaxOk -Detail ("bash -n ok=$shSyntaxOk $shSyntaxDetail")
}
else {
    # fallback structure check: shebang + non-empty + balanced if/fi + key functions
    $shFallbackOk = $true
    foreach ($svc in $services) {
        $t = $shTexts[$svc.Name]
        $ifCount = ([regex]::Matches($t, "\bif\b")).Count
        $fiCount = ([regex]::Matches($t, "\bfi\b")).Count
        $ok = $t.StartsWith("#!/usr/bin/env bash") -and ($t.Length -gt 0) -and
            ($ifCount -eq $fiCount) -and
            $t.Contains("print_result()") -and $t.Contains("wait_health_up()")
        if (-not $ok) { $shFallbackOk = $false; $shSyntaxDetail += "$($svc.Name) structure fail (if=$ifCount fi=$fiCount); " }
    }
    Assert-Test -CaseId "UT-191-1" -Name "4 x deploy-start-{svc}.sh structure fallback (shebang+non-empty+if/fi balanced+functions) (P0)" `
        -Condition $shFallbackOk -Detail ("fallback ok=$shFallbackOk $shSyntaxDetail")
}
$shLoadEnvOk = (($services | ForEach-Object {
    $shTexts[$_.Name].Contains('source "$SCRIPT_DIR/load-env.sh" || exit $?')
} | Where-Object { -not $_ }).Count -eq 0)
$shMainOk = (($services | ForEach-Object {
    $t = $shTexts[$_.Name]
    $t.Contains("nohup java") -and $t.Contains("exit 1") -and $t.Contains("exit 0") -and $t.Contains("wait_health_up")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-191-2" -Name "load-env source with exit-code propagation + main flow blocks present (all 4 .sh)" `
    -Condition ($shLoadEnvOk -and $shMainOk) -Detail ("load-env || exit=$shLoadEnvOk, main blocks=$shMainOk")

# ============================================================================
# UT-192: dual-platform scripts both exist, name/file 1:1 pairing (P1)
# ============================================================================
$filesAllOk = (($services | ForEach-Object {
    (Test-FileExists $ps1Files[$_.Name]) -and (Test-FileExists $shFiles[$_.Name]) -and
    ($ps1Texts[$_.Name].Length -gt 0) -and ($shTexts[$_.Name].Length -gt 0)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-192-1" -Name "8 single-service scripts exist and non-empty (4 services x .ps1/.sh) (P1)" `
    -Condition $filesAllOk -Detail ("8 files ok=$filesAllOk")

$pairConsistent = (($services | ForEach-Object {
    $pt = $ps1Texts[$_.Name]; $st = $shTexts[$_.Name]
    $pt.Contains($_.Jar) -and $st.Contains($_.Jar) -and
    $pt.Contains($healthUrlMap[$_.Name]) -and $st.Contains($healthUrlMap[$_.Name]) -and
    $pt.Contains("$($_.Port)") -and $st.Contains("$($_.Port)")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-192-2" -Name "same-name .ps1/.sh pairs align per service (jar/port/health URL identical) (P1)" `
    -Condition $pairConsistent -Detail ("pair consistency ok=$pairConsistent")

# ============================================================================
# UT-193: SPDX header + copyright + version + no deprecated references (P0)
# ============================================================================
$spdxOk = (($services | ForEach-Object {
    ($ps1Texts[$_.Name].Contains("SPDX-License-Identifier: Apache-2.0") -and
     $ps1Texts[$_.Name].Contains("Copyright 2026 jenemy8023")) -and
    ($shTexts[$_.Name].Contains("SPDX-License-Identifier: Apache-2.0") -and
     $shTexts[$_.Name].Contains("Copyright 2026 jenemy8023"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-193-1" -Name "all 8 scripts carry SPDX header + copyright (UT-141-1 back-to-pass) (P0)" `
    -Condition $spdxOk -Detail ("SPDX ok=$spdxOk (8/8 expected)")

$verOk = (($services | ForEach-Object {
    ($ps1Texts[$_.Name].Contains("v0.2.7") -and (-not $ps1Texts[$_.Name].Contains("v0.1.7"))) -and
    ($shTexts[$_.Name].Contains("v0.2.7") -and (-not $shTexts[$_.Name].Contains("v0.1.7")))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-193-2" -Name "script version v0.2.7, no v0.1.7 leftover in any of the 8 scripts (P0)" `
    -Condition $verOk -Detail ("version ok=$verOk (v0.2.7 expected, v0.1.7 absent)")

$deprecatedOk = (($services | ForEach-Object {
    (-not $ps1Texts[$_.Name].Contains("deploy-env-local")) -and
    (-not $ps1Texts[$_.Name].Contains("deploy-env.ps1")) -and
    (-not $shTexts[$_.Name].Contains("deploy-env-local")) -and
    (-not $shTexts[$_.Name].Contains("deploy-env.sh"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-193-3" -Name "no deprecated script references (deploy-env-local / deploy-env.ps1) in 8 scripts (P0)" `
    -Condition $deprecatedOk -Detail ("deprecated refs absent=$deprecatedOk")

# ============================================================================
# UT-194: load-env call contract + no hard-coded addresses (P0)
# ============================================================================
$loadEnvCallOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains('. "$PSScriptRoot\load-env.ps1"') -and
    $shTexts[$_.Name].Contains('source "$SCRIPT_DIR/load-env.sh" || exit $?')
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-194-1" -Name "all 8 scripts call load-env (.ps1 dot-source / .sh source with exit-code propagation, F-001) (P0)" `
    -Condition $loadEnvCallOk -Detail ("load-env call ok=$loadEnvCallOk (8/8 expected)")

$hardCodeOk = (($services | ForEach-Object {
    (-not [regex]::IsMatch($ps1Texts[$_.Name], "192\.168\.1\.1\d\d")) -and
    (-not [regex]::IsMatch($shTexts[$_.Name], "192\.168\.1\.1\d\d"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-194-2" -Name "no hard-coded 192.168.1.1xx default address in any of the 8 scripts (P0)" `
    -Condition $hardCodeOk -Detail ("hard-code hits absent=$hardCodeOk")

$pathCalcOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains("Split-Path -Parent `$PSScriptRoot") -and
    $shTexts[$_.Name].Contains('dirname "$SCRIPT_DIR"')
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-194-3" -Name "project dir resolved (Split-Path -Parent PSScriptRoot / dirname SCRIPT_DIR) in all 8 scripts (P0)" `
    -Condition $pathCalcOk -Detail ("path calc ok=$pathCalcOk")

# ============================================================================
# UT-195: per-service required-vars scope static (P0)
# ============================================================================
$reqVarOk = (($services | ForEach-Object {
    $expected = $requiredVarsMap[$_.Name]
    $ps1Def = "@(`"" + ($expected -join '", "') + "`")"
    $shDef  = "(" + ($expected -join " ") + ")"
    $ps1Texts[$_.Name].Contains('$RequiredVars = ' + $ps1Def) -and
    $shTexts[$_.Name].Contains("REQUIRED_VARS=(" + $shDef.Substring(1))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-195-1" -Name "per-service required-vars lists match F-009 contract (gateway/auth/biz/system) in all 8 scripts (P0)" `
    -Condition $reqVarOk -Detail ("required-vars defs ok=$reqVarOk")

# auth scope converged from 9 vars to 4: no DB_HOST/DB_PORT/DB_USERNAME/REDIS_* in auth RequiredVars line
$authPs1Line = ($ps1Texts["auth"] -split "`r?`n" | Where-Object { $_ -match "RequiredVars = @" }) -join " "
$authShLine  = ($shTexts["auth"]  -split "`r?`n" | Where-Object { $_ -match "REQUIRED_VARS=" }) -join " "
$authConverged = (-not [regex]::IsMatch($authPs1Line, "DB_HOST|DB_PORT|DB_USERNAME|REDIS_HOST|REDIS_PORT")) -and `
    (-not [regex]::IsMatch($authShLine, "DB_HOST|DB_PORT|DB_USERNAME|REDIS_HOST|REDIS_PORT"))
Assert-Test -CaseId "UT-195-2" -Name "auth no longer validates DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT (9 vars converged to 4) (P0)" `
    -Condition $authConverged -Detail ("auth converged=$authConverged (ps1 line: $authPs1Line; sh line: $authShLine)")

# biz/system .ps1 now also validates DB_PASSWORD (aligned with .sh)
$bizSysPs1DbPwd = $ps1Texts["biz"].Contains('$RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")') -and `
    $ps1Texts["system"].Contains('$RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")')
$bizSysShDbPwd = $shTexts["biz"].Contains("REQUIRED_VARS=(NACOS_ADDR DB_PASSWORD)") -and `
    $shTexts["system"].Contains("REQUIRED_VARS=(NACOS_ADDR DB_PASSWORD)")
Assert-Test -CaseId "UT-195-3" -Name "biz/system both platforms validate DB_PASSWORD (P7-02 gap fixed, .ps1 aligned with .sh) (P0)" `
    -Condition ($bizSysPs1DbPwd -and $bizSysShDbPwd) -Detail ("biz/system .ps1 DB_PASSWORD=$bizSysPs1DbPwd, .sh=$bizSysShDbPwd")

# missing-hint lists key names only: scripts carry "不打印值" marker
$noPrintHintOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains($cjkMissEmpty) -and $ps1Texts[$_.Name].Contains($cjkNoPrint) -and
    $shTexts[$_.Name].Contains($cjkMissEmpty) -and $shTexts[$_.Name].Contains($cjkNoPrint)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-195-4" -Name "missing env hint lists key names only (缺失或为空 + 不打印值 markers in all 8 scripts) (P0)" `
    -Condition $noPrintHintOk -Detail ("key-name-only hint ok=$noPrintHintOk")

# ============================================================================
# UT-196: biz DB_USER vs auth DB_USERNAME difference kept (P1)
# ============================================================================
$dbUserDiffOk = $ps1Texts["biz"].Contains("DB_USER") -and $ps1Texts["biz"].Contains("DB_USERNAME") -and `
    $ps1Texts["auth"].Contains("DB_USERNAME") -and $ps1Texts["auth"].Contains("DB_USER") -and `
    $shTexts["biz"].Contains("DB_USER") -and $shTexts["biz"].Contains("DB_USERNAME") -and `
    $shTexts["auth"].Contains("DB_USERNAME") -and $shTexts["auth"].Contains("DB_USER")
Assert-Test -CaseId "UT-196-1" -Name "biz uses DB_USER / auth uses DB_USERNAME difference comment kept in both platforms (P1)" `
    -Condition $dbUserDiffOk -Detail ("DB_USER/DB_USERNAME diff comments ok=$dbUserDiffOk")

$dbUserNotInVars = (($services | ForEach-Object {
    $ps1Line = ($ps1Texts[$_.Name] -split "`r?`n" | Where-Object { $_ -match "RequiredVars = @" }) -join " "
    $shLine  = ($shTexts[$_.Name]  -split "`r?`n" | Where-Object { $_ -match "REQUIRED_VARS=" }) -join " "
    (-not $ps1Line.Contains("DB_USER")) -and (-not $shLine.Contains("DB_USER"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-196-2" -Name "DB_USER/DB_USERNAME not part of any RequiredVars validation (comment-only difference) (P1)" `
    -Condition $dbUserNotInVars -Detail ("DB_USER excluded from validation=$dbUserNotInVars")

# ============================================================================
# UT-197: jar existence precheck + unified start command (P0)
# ============================================================================
$jarNameOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains($_.Jar) -and $shTexts[$_.Name].Contains($_.Jar)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-197-1" -Name "each script carries its own jar file name (gateway/auth/biz/system 1:1) (P0)" `
    -Condition $jarNameOk -Detail ("jar names ok=$jarNameOk")

$jarCheckOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains("Test-Path -LiteralPath `$jarPath") -and
    $shTexts[$_.Name].Contains('[ ! -f "$PROJECT_DIR/$JAR_NAME" ]')
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-197-2" -Name "jar existence precheck present (Test-Path -LiteralPath / [ -f ]) in all 8 scripts (P0)" `
    -Condition $jarCheckOk -Detail ("jar precheck ok=$jarCheckOk")

$startCmdOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains('"-Xms256m", "-Xmx512m", "-jar"') -and
    $shTexts[$_.Name].Contains("java -Xms256m -Xmx512m -jar")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-197-3" -Name "unified start command java -Xms256m -Xmx512m -jar <jar> in all 8 scripts (P0)" `
    -Condition $startCmdOk -Detail ("start command ok=$startCmdOk (8/8 expected)")

# ============================================================================
# UT-198: backgrounded start + log/PID placement (P0)
# ============================================================================
$ps1BgOk = (($services | ForEach-Object {
    $t = $ps1Texts[$_.Name]
    $t.Contains("Start-Process -FilePath `"java`"") -and $t.Contains("-WindowStyle Hidden") -and
    $t.Contains("-RedirectStandardOutput") -and $t.Contains("-RedirectStandardError") -and
    $t.Contains("-PassThru") -and $t.Contains("Out-File -Encoding ascii") -and
    (-not $t.Contains("-Wait")) -and (-not $t.Contains("-NoNewWindow"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-198-1" -Name ".ps1 background start: Start-Process Hidden + dual redirect + PassThru + PID file, no -Wait/-NoNewWindow (all 4) (P0)" `
    -Condition $ps1BgOk -Detail (".ps1 backgrounding ok=$ps1BgOk")

$shBgOk = (($services | ForEach-Object {
    $t = $shTexts[$_.Name]
    $t.Contains("nohup java") -and $t.Contains('2>&1 &') -and $t.Contains('echo $! >') -and $t.Contains(".pid")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-198-2" -Name ".sh background start: nohup java + 2>&1 & + echo $! PID file (all 4) (P0)" `
    -Condition $shBgOk -Detail (".sh backgrounding ok=$shBgOk")

$logPidOk = (($services | ForEach-Object {
    $m = $_.Name
    # log/PID file names are built from the service-name variable
    # ($ServiceName / $SERVICE_NAME), so assert the joined suffix patterns
    # plus the service name itself (1:1 module mapping).
    ($ps1Texts[$m].Contains($m) -and $ps1Texts[$m].Contains("-start.log") -and
     $ps1Texts[$m].Contains("-start.err") -and $ps1Texts[$m].Contains(".pid") -and
     $ps1Texts[$m].Contains("New-Item -ItemType Directory -Force")) -and
    ($shTexts[$m].Contains($m) -and $shTexts[$m].Contains("-start.log") -and
     $shTexts[$m].Contains(".pid") -and $shTexts[$m].Contains("mkdir -p"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-198-3" -Name "log/PID paths deploy/logs/{module}-start.log(-.err)/.pid + logs dir creation in all 8 scripts (P0)" `
    -Condition $logPidOk -Detail ("log/PID placement ok=$logPidOk")

# ============================================================================
# UT-199: health confirm logic (P0)
# ============================================================================
$healthUrlOk = (($services | ForEach-Object {
    $url = $healthUrlMap[$_.Name]
    $ps1Texts[$_.Name].Contains($url) -and $shTexts[$_.Name].Contains($url)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-199-1" -Name "per-service health URL matches contract (gateway root / auth|biz|system /api/v1/{m}/health) in all 8 scripts (P0)" `
    -Condition $healthUrlOk -Detail ("health URLs ok=$healthUrlOk")

$pollDefaultOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains("[int]`$RetryCount = 30") -and
    $ps1Texts[$_.Name].Contains("[int]`$RetryInterval = 2") -and
    $ps1Texts[$_.Name].Contains("[int]`$ProbeTimeout = 3") -and
    $shTexts[$_.Name].Contains('RETRY_COUNT="${RETRY_COUNT:-30}"') -and
    $shTexts[$_.Name].Contains('RETRY_INTERVAL="${RETRY_INTERVAL:-2}"') -and
    $shTexts[$_.Name].Contains('PROBE_TIMEOUT="${PROBE_TIMEOUT:-3}"')
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-199-2" -Name "polling defaults 30 retries/2s interval/3s timeout configurable (param / env vars) in all 8 scripts (P0)" `
    -Condition $pollDefaultOk -Detail ("poll defaults ok=$pollDefaultOk")

$probeOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains("Test-HttpOk") -and $ps1Texts[$_.Name].Contains("Test-TcpPort") -and
    $shTexts[$_.Name].Contains("http_ok") -and $shTexts[$_.Name].Contains("tcp_port_open")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-199-3" -Name "HTTP probe first + TCP port backup present in all 8 scripts (P0)" `
    -Condition $probeOk -Detail ("probe funcs ok=$probeOk")

$healthFailOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains($cjkHTimeout) -and $ps1Texts[$_.Name].Contains($cjkFail) -and
    $shTexts[$_.Name].Contains($cjkHTimeout) -and $shTexts[$_.Name].Contains($cjkFail)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-199-4" -Name "health-confirm failure -> [fail] grading + non-zero exit path in all 8 scripts (P0)" `
    -Condition $healthFailOk -Detail ("health fail path ok=$healthFailOk")

# ============================================================================
# UT-200: output grading + exit code contract F-011 (P0)
# ============================================================================
$gradingOk = (($services | ForEach-Object {
    ($ps1Texts[$_.Name].Contains("`"$cjkPass`"") -and $ps1Texts[$_.Name].Contains("`"$cjkWarn`"") -and
     $ps1Texts[$_.Name].Contains("`"$cjkFail`"") -and $ps1Texts[$_.Name].Contains("-ForegroundColor Green") -and
     $ps1Texts[$_.Name].Contains("-ForegroundColor Yellow") -and $ps1Texts[$_.Name].Contains("-ForegroundColor Red")) -and
    ($shTexts[$_.Name].Contains("$cjkPass)") -and $shTexts[$_.Name].Contains("$cjkWarn)") -and
     $shTexts[$_.Name].Contains("$cjkFail)") -and $shTexts[$_.Name].Contains('\033[0;32m') -and
     $shTexts[$_.Name].Contains('\033[1;33m') -and $shTexts[$_.Name].Contains('\033[0;31m'))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-200-1" -Name "output grading [pass]/[warn]/[fail] + colors in all 8 scripts (F-011) (P0)" `
    -Condition $gradingOk -Detail ("grading ok=$gradingOk")

$noEmojiOk = (($services | ForEach-Object {
    (-not [regex]::IsMatch($ps1Texts[$_.Name], "[\u2705\u274C\u26A0\uD83D\uD83C]")) -and
    (-not [regex]::IsMatch($shTexts[$_.Name], "[\u2705\u274C\u26A0\uD83D\uD83C]"))
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-200-2" -Name "no emoji output (no check/cross/warning emoji) in all 8 scripts (F-011) (P0)" `
    -Condition $noEmojiOk -Detail ("no emoji ok=$noEmojiOk")

$exitCodeOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains("exit 0") -and $ps1Texts[$_.Name].Contains("exit 1") -and
    $shTexts[$_.Name].Contains("exit 0") -and $shTexts[$_.Name].Contains("exit 1")
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-200-3" -Name "exit-code contract present: all pass exit 0 / any fail exit 1 (F-011) in all 8 scripts (P0)" `
    -Condition $exitCodeOk -Detail ("exit codes ok=$exitCodeOk")

# ============================================================================
# UT-201: no plaintext sensitive value in output (P0, security)
# ============================================================================
$sensitiveVars = @("DB_PASSWORD", "RSA_PRIVATE_KEY", "RSA_PUBLIC_KEY")
$ps1SensitiveHit = 0
$shSensitiveHit = 0
foreach ($svc in $services) {
    $ps1OutLines = @($ps1Texts[$svc.Name] -split "`r?`n" | Where-Object { $_ -match "Write-(Host|Error|Output|Warning)" -or $_ -match 'Write-Result "' })
    foreach ($line in $ps1OutLines) {
        foreach ($v in $sensitiveVars) {
            if ($line -match ('\$env:' + $v) -or $line -match ('\$\{' + $v + '\}') -or $line -match ('\$' + $v + '\b')) {
                $ps1SensitiveHit++
            }
        }
    }
    $shOutLines = @($shTexts[$svc.Name] -split "`r?`n" | Where-Object { $_ -match "echo|print_result" })
    foreach ($line in $shOutLines) {
        foreach ($v in $sensitiveVars) {
            if ($line -match ('\$' + $v + '\b') -or $line -match ('\$\{' + $v + '\}')) {
                $shSensitiveHit++
            }
        }
    }
}
Assert-Test -CaseId "UT-201-1" -Name "no output statement directly emits DB_PASSWORD/RSA_* values (static, security) (P0)" `
    -Condition (($ps1SensitiveHit -eq 0) -and ($shSensitiveHit -eq 0)) `
    -Detail (".ps1 sensitive-emit lines=$ps1SensitiveHit, .sh sensitive-emit lines=$shSensitiveHit (0 expected)")

$keyNameOnlyOk = (($services | ForEach-Object {
    $ps1Texts[$_.Name].Contains($cjkNoPrint) -and $shTexts[$_.Name].Contains($cjkNoPrint)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-201-2" -Name "missing hints list key names only (不打印值 marker) in all 8 scripts (P0)" `
    -Condition $keyNameOnlyOk -Detail ("key-name-only ok=$keyNameOnlyOk")

# ============================================================================
# UT-202: static consistency with deploy-start-all per-service block (P0)
# ============================================================================
# extract per-service block from start-all.ps1 (between 'Name = "svc"' and next 'Name = "')
function Get-AllPs1ServiceBlock {
    param([string]$Text, [string]$Name)
    $start = $Text.IndexOf('Name = "' + $Name + '"')
    if ($start -lt 0) { return "" }
    $next = $Text.IndexOf('Name = "', $start + 5)
    if ($next -lt 0) { return $Text.Substring($start) }
    return $Text.Substring($start, $next - $start)
}
function Get-AllShServiceBlock {
    param([string]$Text, [string]$Name)
    $start = $Text.IndexOf('"' + $Name + '|')
    if ($start -lt 0) { return "" }
    $next = $Text.IndexOf('|', $start)   # first '|' after name
    $end  = $Text.IndexOf("`n", $start)
    if ($end -lt 0) { $end = $Text.Length }
    return $Text.Substring($start, $end - $start)
}
$consistentWithAll = $true
$consistentDetail = ""
foreach ($svc in $services) {
    $m = $svc.Name
    $allBlock = Get-AllPs1ServiceBlock -Text $allPs1Text -Name $m
    $ps1T = $ps1Texts[$m]
    $okBlock = ($allBlock.Length -gt 0) -and
        $allBlock.Contains($svc.Jar) -and $ps1T.Contains($svc.Jar) -and
        $allBlock.Contains($healthUrlMap[$m]) -and $ps1T.Contains($healthUrlMap[$m]) -and
        $allBlock.Contains("Port = $($svc.Port)") -and $ps1T.Contains("$($svc.Port)")
    if (-not $okBlock) { $consistentWithAll = $false; $consistentDetail += "$m .ps1 block mismatch; " }
    $allShBlock = Get-AllShServiceBlock -Text $allShText -Name $m
    $shT = $shTexts[$m]
    $okShBlock = ($allShBlock.Length -gt 0) -and
        $allShBlock.Contains($svc.Jar) -and $shT.Contains($svc.Jar) -and
        $allShBlock.Contains($healthUrlMap[$m]) -and $shT.Contains($healthUrlMap[$m]) -and
        $allShBlock.Contains("|$($svc.Port)|") -and $shT.Contains("$($svc.Port)")
    if (-not $okShBlock) { $consistentWithAll = $false; $consistentDetail += "$m .sh block mismatch; " }
}
Assert-Test -CaseId "UT-202-1" -Name "single-service jar/port/health URL consistent with start-all per-service block (all 8 scripts) (P0)" `
    -Condition $consistentWithAll -Detail ("consistency ok=$consistentWithAll $consistentDetail")

# required-vars list identical between single-service scripts and start-all blocks
$reqVarConsistent = (($services | ForEach-Object {
    $m = $_.Name
    $expected = $requiredVarsMap[$m]
    $allPs1Block = Get-AllPs1ServiceBlock -Text $allPs1Text -Name $m
    $allShBlock  = Get-AllShServiceBlock -Text $allShText  -Name $m
    $ps1Ok = $ps1Texts[$m].Contains('$RequiredVars = @("' + ($expected -join '", "') + '")') -and
        (($expected | ForEach-Object { $allPs1Block.Contains('"' + $_ + '"') } | Where-Object { -not $_ }).Count -eq 0)
    $shOk = $shTexts[$m].Contains("REQUIRED_VARS=(" + ($expected -join " ") + ")") -and
        (($expected | ForEach-Object { $allShBlock.Contains($_) } | Where-Object { -not $_ }).Count -eq 0)
    $ps1Ok -and $shOk
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-202-2" -Name "required-vars list identical to start-all per-service block (all 8 scripts) (P0)" `
    -Condition $reqVarConsistent -Detail ("required-vars consistency ok=$reqVarConsistent")

# failure hint identical to start-all (gateway NACOS_ADDR/RSA_PUBLIC_KEY, auth RSA key pair/DB_PASSWORD, biz/system DB_PASSWORD)
$hintMap = @{
    gateway = $cjkCheck + " NACOS_ADDR/RSA_PUBLIC_KEY " + $cjkConfig
    auth    = $cjkCheck + " RSA " + $cjkKeyPair + "/DB_PASSWORD " + $cjkConfig
    biz     = $cjkCheck + " DB_PASSWORD " + $cjkConfig
    system  = $cjkCheck + " DB_PASSWORD " + $cjkConfig
}
$hintConsistent = (($services | ForEach-Object {
    $m = $_.Name
    $hint = $hintMap[$m]
    $ps1Texts[$m].Contains($hint) -and $shTexts[$m].Contains($hint)
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-202-3" -Name "failure hints match start-all per-service hints (NACOS_ADDR/RSA_PUBLIC_KEY / RSA key pair/DB_PASSWORD / DB_PASSWORD) (P0)" `
    -Condition $hintConsistent -Detail ("hints ok=$hintConsistent")

# start params / log path / polling defaults identical with start-all
$startAllBaseline = ($allPs1Text.Contains('"-Xms256m", "-Xmx512m", "-jar"') -and `
    $allShText.Contains("java -Xms256m -Xmx512m -jar")) -and `
    ($allPs1Text.Contains("[int]`$RetryCount = 30") -and $allShText.Contains('RETRY_COUNT="${RETRY_COUNT:-30}"'))
$ps1SameAsAll = (($services | ForEach-Object {
    $m = $_.Name
    $singleStart = $ps1Texts[$m].Contains('"-Xms256m", "-Xmx512m", "-jar"') -and
        $ps1Texts[$m].Contains("[int]`$RetryCount = 30") -and $ps1Texts[$m].Contains("$m-start.log")
    $allHasBlock = $allPs1Text.Contains("Name = `"$m`"")
    $singleStart -and $allHasBlock
} | Where-Object { -not $_ }).Count -eq 0)
Assert-Test -CaseId "UT-202-4" -Name "start params/polling defaults/log paths identical with start-all baseline (all 4 .ps1) (P0)" `
    -Condition ($startAllBaseline -and $ps1SameAsAll) `
    -Detail ("start-all baseline=$startAllBaseline, single .ps1 aligned=$ps1SameAsAll")

# ============================================================================
# dynamic FT section: isolated runner helpers
# ============================================================================
$script:singleUnderTest = ""   # script under test used by Invoke-SinglePs1Isolated

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
    $listening = @()
    foreach ($p in @(9000, 9100, 9200, 9400)) {
        if (Test-TcpPortOpen -HostName "localhost" -Port $p) { $listening += $p }
    }
    return $listening
}

function Invoke-SinglePs1Isolated {
    # run a single-service .ps1 in a SEPARATE powershell process with the
    # load-env injected environment keys cleared first; returns @{Output; Exit}
    # ErrorActionPreference is forced to Continue during the native-call
    # redirect (PowerShell 5.1 wraps child stderr as error records which
    # would raise under EAP=Stop - e.g. load-env Write-Error on missing key).
    param([string]$ExtraArgs = "")
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $keys = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT", "DB_USERNAME",
                  "DB_PASSWORD", "DB_USER", "DB_SERVICE_NAME", "DB_PROCESS_NAME",
                  "REDIS_HOST", "REDIS_PORT", "REDIS_PASSWORD", "REDIS_DATABASE",
                  "REDIS_SERVICE_NAME", "REDIS_PROCESS_NAME", "RSA_PRIVATE_KEY",
                  "RSA_PUBLIC_KEY", "MARIADB_ROOT_PASSWORD", "TZ")
        $clearExpr = ($keys | ForEach-Object { "Remove-Item Env:$_ -ErrorAction SilentlyContinue" }) -join "; "
        $cmd = "$clearExpr; & '$($script:singleUnderTest)' $ExtraArgs; exit `$LASTEXITCODE"
        $out = (& powershell -NoProfile -ExecutionPolicy Bypass -Command $cmd 6>&1 2>&1 | Out-String)
        $code = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
        $script:LastRunOutput = $out
        return @{ Output = $out; Exit = $code }
    }
    finally {
        $ErrorActionPreference = $oldEap
    }
}

# ============================================================================
# FT-119~122: key env var missing scenarios (P0, dynamic, backup/restore guarded)
# ============================================================================
# NOTE: gateway/auth missing-scenario targets (RSA_PUBLIC_KEY / RSA_PRIVATE_KEY)
# are NOT part of load-env's 8-key baseline, so the single-service script's own
# RequiredVars check is exercised. biz/system targets (DB_PASSWORD) ARE part of
# the load-env baseline, so load-env fails first (still key name + exit 1 +
# no start) - both paths satisfy the case expectations.
$envVarScenarios = @(
    @{ CaseId = "FT-119"; Svc = "gateway"; Key = "RSA_PUBLIC_KEY"; Detail = "gateway missing RSA_PUBLIC_KEY" },
    @{ CaseId = "FT-120"; Svc = "auth";    Key = "RSA_PRIVATE_KEY"; Detail = "auth missing RSA_PRIVATE_KEY" },
    @{ CaseId = "FT-121"; Svc = "biz";     Key = "DB_PASSWORD";      Detail = "biz missing DB_PASSWORD" },
    @{ CaseId = "FT-122"; Svc = "system";  Key = "DB_PASSWORD";      Detail = "system missing DB_PASSWORD" }
)
if ($ps1Files["gateway"] -and $envJsonExists) {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $parsed = $null
    try { $parsed = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $parsed = $null }
    if ($null -ne $parsed) {
        $origSecrets = @{}
        foreach ($v in $sensitiveVars) {
            $val = $parsed.$v
            if ($val -and ($val -is [string]) -and ($val.Length -ge 4)) { $origSecrets[$v] = $val }
        }
        foreach ($scn in $envVarScenarios) {
            $bakPath = Join-Path $deployDir (".env.json.bak-cso-test-" + $scn.CaseId.ToLower())
            $modified = $false
            try {
                Copy-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
                $obj = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $obj.PSObject.Properties.Remove($scn.Key)
                [System.IO.File]::WriteAllText($envJsonPath, ($obj | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)
                $modified = $true
                $script:singleUnderTest = $ps1Files[$scn.Svc]
                $beforePorts = @(Get-ListeningPorts)
                $run = Invoke-SinglePs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
                $afterPorts = @(Get-ListeningPorts)
                $newPorts = @($afterPorts | Where-Object { $beforePorts -notcontains $_ })
                $hasKeyName  = $run.Output.Contains($scn.Key)
                $hasFailGrad = $run.Output.Contains($cjkFail)
                $hasMissMsg  = $run.Output.Contains($cjkMiss) -or $run.Output.Contains($cjkMissEmpty)
                $leakFound = $false
                foreach ($s in $origSecrets.Values) { if ($run.Output.Contains($s)) { $leakFound = $true } }
                Assert-Test -CaseId ($scn.CaseId + "-1") -Name ($scn.Detail + " -> key name listed + [fail] grading + exit 1 + no service started (dynamic)") `
                    -Condition ($hasKeyName -and $hasFailGrad -and $hasMissMsg -and ($run.Exit -eq 1) -and ($newPorts.Count -eq 0) -and (-not $leakFound)) `
                    -Detail ("key name=$hasKeyName, fail grading=$hasFailGrad, missing msg=$hasMissMsg, exit=$($run.Exit) (1 expected), new ports=$($newPorts -join ',') (none expected), secret leak=$leakFound (absent expected); env.json restored")
            }
            catch {
                Assert-Test -CaseId ($scn.CaseId + "-1") -Name ($scn.Detail + " (dynamic)") `
                    -Condition $false -Detail ("scenario error: $($_.Exception.Message)")
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
    }
    else {
        foreach ($scn in $envVarScenarios) {
            Skip-Test -CaseId ($scn.CaseId + "-1") -Name ($scn.Detail + " (dynamic)") -Detail "env.json not parseable as JSON; cannot construct missing-key scenario safely"
        }
    }
}
else {
    foreach ($scn in $envVarScenarios) {
        Skip-Test -CaseId ($scn.CaseId + "-1") -Name ($scn.Detail + " (dynamic)") -Detail "precondition not met (single-service .ps1/env.json absent)"
    }
}

# ============================================================================
# FT-123~126: jar missing scenarios (P0, dynamic, backup/restore guarded)
# ============================================================================
foreach ($svc in $services) {
    $caseId = switch ($svc.Name) { "gateway" { "FT-123" } "auth" { "FT-124" } "biz" { "FT-125" } "system" { "FT-126" } }
    $jarPath = Join-Path $deployDir $svc.Jar
    if ((Test-FileExists $ps1Files[$svc.Name]) -and $envJsonExists -and (Test-FileExists $jarPath)) {
        $beforePorts = @(Get-ListeningPorts)
        $bakPath = Join-Path $deployDir ("." + $svc.Jar + ".bak-cso-test")
        $oldEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $moved = $false
        try {
            Move-Item -LiteralPath $jarPath -Destination $bakPath -Force -ErrorAction Stop
            $moved = $true
            $script:singleUnderTest = $ps1Files[$svc.Name]
            $run = Invoke-SinglePs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
            $afterPorts = @(Get-ListeningPorts)
            $newPorts = @($afterPorts | Where-Object { $beforePorts -notcontains $_ })
            $hasJarName  = $run.Output.Contains($svc.Jar)
            $hasMissHint = $run.Output.Contains($cjkJarMiss)
            $hasFailGrad = $run.Output.Contains($cjkFail)
            Assert-Test -CaseId ($caseId + "-1") -Name ("deploy-start-" + $svc.Name + ".ps1 jar missing -> jar name + hint + [fail] + exit 1 + no start (dynamic)") `
                -Condition ($hasJarName -and $hasMissHint -and $hasFailGrad -and ($run.Exit -eq 1) -and ($newPorts.Count -eq 0)) `
                -Detail ("jar name=$hasJarName, miss hint=$hasMissHint, fail grading=$hasFailGrad, exit=$($run.Exit) (1 expected), new ports=$($newPorts -join ',') (none expected); jar restored")
        }
        catch {
            # jar locked by running Java service -> cannot construct scenario safely
            Skip-Test -CaseId ($caseId + "-1") -Name ("deploy-start-" + $svc.Name + ".ps1 jar missing (dynamic)") `
                -Detail ("jar file locked by a running Java service (move failed: $($_.Exception.Message)); cannot construct scenario safely; static coverage via UT-197/202")
        }
        finally {
            if ($moved -and (Test-Path -LiteralPath $bakPath)) {
                try { Move-Item -LiteralPath $bakPath -Destination $jarPath -Force } catch { }
            }
            $ErrorActionPreference = $oldEap
        }
    }
    else {
        Skip-Test -CaseId ($caseId + "-1") -Name ("deploy-start-" + $svc.Name + ".ps1 jar missing (dynamic)") `
            -Detail "precondition not met (single-service .ps1/env.json/jar absent); static coverage via UT-197/202"
    }
}

# ============================================================================
# FT-131: env.json missing -> load-env fallback (P0, dynamic, guarded)
# ============================================================================
if ($ps1Files["gateway"] -and $envJsonExists) {
    $bakPath = Join-Path $deployDir ".env.json.bak-cso-test-ft131"
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $moved = $false
    try {
        Move-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
        $moved = $true
        $script:singleUnderTest = $ps1Files["gateway"]
        $run = Invoke-SinglePs1Isolated
        $hasCopyHint = $run.Output.Contains("env.example") -and $run.Output.Contains($cjkCopy)
        $hasFillHint = $run.Output.Contains($cjkFillConfig)
        Assert-Test -CaseId "FT-131-1" -Name "env.json missing -> load-env guidance (copy env.example.json + fill config) + non-zero exit (dynamic, F-001)" `
            -Condition ($hasCopyHint -and $hasFillHint -and ($run.Exit -ne 0)) `
            -Detail ("copy hint=$hasCopyHint, fill hint=$hasFillHint, exit=$($run.Exit) (non-zero expected); env.json restored")
    }
    catch {
        Assert-Test -CaseId "FT-131-1" -Name "env.json missing -> load-env guidance + non-zero exit (dynamic)" `
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
    Skip-Test -CaseId "FT-131-1" -Name "env.json missing -> copy env.example guidance + non-zero exit (dynamic)" `
        -Detail "precondition not met (deploy-start-gateway.ps1/env.json absent); load-env fallback covered by TASK-002 tests"
}

# ============================================================================
# FT-132: .sh dual-platform behavior (P1, SKIP if no bash/WSL)
# ============================================================================
if ($bashUsable -and (Test-FileExists $shFiles["gateway"])) {
    # run one .sh missing-key scenario (gateway RSA_PUBLIC_KEY) to verify
    # .sh behavior parity with .ps1; guarded env.json backup/restore.
    $bakPath = Join-Path $deployDir ".env.json.bak-cso-test-ft132"
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $modified = $false
    $shRunOut = ""
    $shRunExit = -1
    try {
        Copy-Item -LiteralPath $envJsonPath -Destination $bakPath -Force
        $obj = Get-Content -LiteralPath $envJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $obj.PSObject.Properties.Remove("RSA_PUBLIC_KEY")
        [System.IO.File]::WriteAllText($envJsonPath, ($obj | ConvertTo-Json -Depth 5), [System.Text.Encoding]::UTF8)
        $modified = $true
        $wslSh = $shFiles["gateway"]
        if ($wslSh -match "^([A-Za-z]):\\(.*)$") {
            $wslSh = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $beforePorts = @(Get-ListeningPorts)
        $shRunOut = (& bash $wslSh 2>&1 | Out-String)
        $shRunExit = $LASTEXITCODE
        $afterPorts = @(Get-ListeningPorts)
        $newPorts = @($afterPorts | Where-Object { $beforePorts -notcontains $_ })
        $hasKeyName  = $shRunOut.Contains("RSA_PUBLIC_KEY")
        $hasFailGrad = $shRunOut.Contains($cjkFail)
        Assert-Test -CaseId "FT-132-1" -Name ".sh dual-platform behavior: gateway.sh missing RSA_PUBLIC_KEY -> key name + [fail] + exit 1 (dynamic)" `
            -Condition ($hasKeyName -and $hasFailGrad -and ($shRunExit -eq 1) -and ($newPorts.Count -eq 0)) `
            -Detail ("key name=$hasKeyName, fail grading=$hasFailGrad, exit=$shRunExit (1 expected), new ports=$($newPorts -join ',') (none expected); env.json restored")
    }
    catch {
        Assert-Test -CaseId "FT-132-1" -Name ".sh dual-platform behavior (dynamic)" `
            -Condition $false -Detail ("scenario error: $($_.Exception.Message)")
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
    Skip-Test -CaseId "FT-132-1" -Name ".sh dual-platform behavior (dynamic)" `
        -Detail "bash/WSL unavailable; static dual-platform coverage via UT-191/195/202"
}

# ============================================================================
# FT-127~130/133: all-ready / already-running idempotent scenarios
# (P0/P1, env-gated by -RunServiceTests; default run NEVER starts a service)
# ============================================================================
$allPortsUp = ((Get-ListeningPorts).Count -eq 4)
$jarsAllExist = (($services | ForEach-Object { Test-FileExists (Join-Path $deployDir $_.Jar) } | Where-Object { -not $_ }).Count -eq 0)

if ($RunServiceTests -and $envJsonExists -and $jarsAllExist) {
    # For each service: if the service port is already listening (this host
    # runs the 4 backend services) -> idempotent scenario: the script
    # background-starts a java instance, health confirm hits the running
    # service, exit 0, log/PID files generated. Short retries keep the
    # spawned instance risk minimal (Spring Boot fails fast on occupied port).
    foreach ($svc in $services) {
        $caseId = switch ($svc.Name) { "gateway" { "FT-127" } "auth" { "FT-128" } "biz" { "FT-129" } "system" { "FT-130" } }
        $portUp = Test-TcpPortOpen -HostName "localhost" -Port $svc.Port
        $logFile = Join-Path $logDir ($svc.Name + "-start.log")
        $pidFile = Join-Path $logDir ($svc.Name + ".pid")
        if (Test-Path -LiteralPath $logFile) { Remove-Item -LiteralPath $logFile -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue }
        $script:singleUnderTest = $ps1Files[$svc.Name]
        $run = Invoke-SinglePs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
        $hasPassGrad = $run.Output.Contains($cjkPass)
        $hasHealthOk = $run.Output.Contains($cjkHConfirmOk) -or $run.Output.Contains($cjkStartOkMsg)
        $hasSummary  = $run.Output.Contains($cjkSummaryLine) -and $run.Output.Contains($cjkPass) -and $run.Output.Contains($cjkItem)
        $logCreated  = Test-FileExists $logFile
        $pidCreated  = Test-FileExists $pidFile
        $scenario = if ($portUp) { "already-running idempotent" } else { "fresh-start" }
        Assert-Test -CaseId ($caseId + "-1") -Name ("deploy-start-" + $svc.Name + ".ps1 all ready -> backgrounded start + health ok + summary + exit 0 (" + $scenario + ", dynamic)") `
            -Condition ($hasPassGrad -and $hasHealthOk -and $hasSummary -and ($run.Exit -eq 0) -and $logCreated -and $pidCreated) `
            -Detail ("pass grading=$hasPassGrad, health ok=$hasHealthOk, summary=$hasSummary, exit=$($run.Exit) (0 expected), log created=$logCreated, pid created=$pidCreated; service port up=$portUp")
    }
    # FT-133: already-running repeat run -> idempotent pass + grading summary + exit 0
    if ($allPortsUp) {
        $script:singleUnderTest = $ps1Files["gateway"]
        $run = Invoke-SinglePs1Isolated "-RetryCount 2 -RetryInterval 1 -ProbeTimeout 2"
        $hasFailGrad = $run.Output.Contains($cjkFail)
        $hasSummary  = $run.Output.Contains($cjkSummaryLine) -and $run.Output.Contains($cjkPass) -and $run.Output.Contains($cjkWarn) -and $run.Output.Contains($cjkFail) -and $run.Output.Contains($cjkItem)
        Assert-Test -CaseId "FT-133-1" -Name "already-running repeat run -> pass grading summary (pass/warn/fail counts) + exit 0 (idempotent, dynamic)" `
            -Condition ($hasSummary -and (-not $hasFailGrad) -and ($run.Exit -eq 0)) `
            -Detail ("summary with counts=$hasSummary, fail grading=$hasFailGrad (absent expected), exit=$($run.Exit) (0 expected)")
    }
    else {
        Skip-Test -CaseId "FT-133-1" -Name "already-running repeat run -> summary + exit 0 (dynamic)" `
            -Detail "not all 4 ports listening (all ports up=$allPortsUp); idempotent scenario requires running services"
    }
}
else {
    $detail = "environment gated (-RunServiceTests required) and/or precondition not met: env.json=$envJsonExists, 4 jars=$jarsAllExist"
    foreach ($svc in $services) {
        $caseId = switch ($svc.Name) { "gateway" { "FT-127" } "auth" { "FT-128" } "biz" { "FT-129" } "system" { "FT-130" } }
        Skip-Test -CaseId ($caseId + "-1") -Name ("deploy-start-" + $svc.Name + ".ps1 all ready -> backgrounded start + health ok + exit 0 (dynamic, service run)") -Detail $detail
    }
    Skip-Test -CaseId "FT-133-1" -Name "already-running repeat run + grading summary + exit code (dynamic)" -Detail $detail
}

# ============================================================================
# summary + exit code
# ============================================================================
Write-Output ""
Write-Output ("=" * 70)
Write-Output "cso-unit-test-start-single-v0.2.7 (TASK-006) summary"
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
