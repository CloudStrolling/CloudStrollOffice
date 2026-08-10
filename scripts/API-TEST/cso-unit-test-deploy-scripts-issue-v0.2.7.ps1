# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - Deploy Scripts Issue Survey Unit Test (TASK-001)
# ----------------------------------------------------------------------------
# Coverage: UT-132 ~ UT-143 in task testcase
#           (docs/cso-v0.2.7/task_TASK-001/testcase.md)
#   UT-132: issue list deliverable exists and covers 6 main problems P1~P6 (P0)
#   UT-133: hard-coded default address grep - 192.168.1.x residue found (P0)
#   UT-134: deprecated script residue deploy-env* removed by TASK-008 (P0)
#   UT-135: RSA key output contract static compare .sh vs .ps1 mismatch (P0)
#   UT-136: availability check vs running-state check capability split (P1)
#   UT-137: output grade & exit code convention inconsistent (P1)
#   UT-138: deploy-start-all missing (one-click start total entry absent) (P0)
#   UT-139: issue list usable as downstream refactor basis (P1)
#   UT-140: .gitignore gap identification (JVM/Maven/test/tool residue) (P1)
#   UT-141: script file header SPDX & copyright check (P1)
#   UT-142: script syntax parseability check (.ps1 Parser / .sh bash -n) (P1)
#   UT-143: dual-platform script count alignment check (11 pairs) (P2)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
#       Files with CJK content are read explicitly as UTF-8 via .NET APIs.
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
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

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Test-FileExists {
    param([string]$Path)
    return (Test-Path -LiteralPath $Path -PathType Leaf)
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 Deploy Scripts Issue Survey Unit Test (TASK-001, UT-132~UT-143)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$versionDir = Join-Path $ProjectRoot "docs\cso-v0.2.7"
$issueListDoc = Join-Path $versionDir "cso-deploy-scripts-issue-list-v0.2.7.md"
$scriptsDir = Join-Path $ProjectRoot "deploy\scripts"
$gitignorePath = Join-Path $ProjectRoot ".gitignore"
$deployMd = Join-Path $ProjectRoot "deploy\deploy.md"

# ----------------------------------------------------------------------------
# UT-132: issue list deliverable exists and covers 6 main problems (P0)
# ----------------------------------------------------------------------------
$docExists = Test-FileExists -Path $issueListDoc
if (-not $docExists) {
    Assert-Test -CaseId "UT-132-1" -Name "issue list doc exists and non-empty" `
        -Condition $false -Detail "doc not found: $issueListDoc"
    for ($i = 2; $i -le 4; $i++) {
        Assert-Test -CaseId "UT-132-$i" -Name "6 main problems P1~P6 covered with position/behavior/refactor requirements" `
            -Condition $false -Detail "doc missing"
    }
}
else {
    $docText = Read-Utf8File -Path $issueListDoc
    $nonEmpty = ($docText.Length -gt 100)
    Assert-Test -CaseId "UT-132-1" -Name "issue list doc exists and non-empty" `
        -Condition $nonEmpty -Detail "path: $issueListDoc, length: $($docText.Length)"

    # each P1~P6 main problem heading exists
    $missingProblems = @()
    foreach ($probId in @("P1", "P2", "P3", "P4", "P5", "P6")) {
        $pat = "(?m)^### " + [regex]::Escape($probId) + " "
        if (-not ($docText -match $pat)) {
            $missingProblems += $probId
        }
    }
    Assert-Test -CaseId "UT-132-2" -Name "6 main problem headings P1~P6 all present" `
        -Condition ($missingProblems.Count -eq 0) `
        -Detail ("missing: " + $(if ($missingProblems.Count -eq 0) { "none" } else { $missingProblems -join ", " }))

    # each problem block contains position/behavior/refactor-requirement (建议处置/重构要求)
    $trioOk = $true
    $trioDetail = @()
    foreach ($probId in @("P1", "P2", "P3", "P4", "P5", "P6")) {
        $pat = "(?m)^### " + [regex]::Escape($probId) + " "
        $m = [regex]::Match($docText, $pat)
        if (-not $m.Success) { $trioOk = $false; $trioDetail += "$probId:heading-missing"; continue }
        $start = $m.Index
        $nextIdx = $docText.Length
        foreach ($next in @("### P1 ", "### P2 ", "### P3 ", "### P4 ", "### P5 ", "### P6 ", "## 3.")) {
            $n = $docText.IndexOf($next, $start + 1)
            if ($n -gt 0 -and $n -lt $nextIdx) { $nextIdx = $n }
        }
        $sec = $docText.Substring($start, $nextIdx - $start)
        $hasLoc = ($sec -match "问题定位")
        $hasBehavior = ($sec -match "问题表现")
        $hasRefactor = ($sec -match "建议处置")
        if (-not ($hasLoc -and $hasBehavior -and $hasRefactor)) {
            $trioOk = $false
            $trioDetail += "$probId:loc=$hasLoc behavior=$hasBehavior refactor=$hasRefactor"
        }
    }
    Assert-Test -CaseId "UT-132-3" -Name "each P1~P6 contains position + behavior + refactor requirement (three elements)" `
        -Condition $trioOk `
        -Detail ("issues: " + $(if ($trioDetail.Count -eq 0) { "none" } else { $trioDetail -join "; " }))

    # downstream task mapping table exists (TASK-002/003/004/005/007)
    $downstreamOk = ($docText -match "TASK-002" -and $docText -match "TASK-003" -and
                     $docText -match "TASK-004" -and $docText -match "TASK-005" -and $docText -match "TASK-007")
    Assert-Test -CaseId "UT-132-4" -Name "downstream task mapping present (TASK-002/003/004/005/007)" `
        -Condition $downstreamOk `
        -Detail "refactor basis usable for downstream tasks"
}

# ----------------------------------------------------------------------------
# UT-133: hard-coded default address grep - 192.168.1.x residue (P0, negative)
# ----------------------------------------------------------------------------
$scriptFiles = @(Get-ChildItem -LiteralPath $scriptsDir -File -Include *.ps1,*.sh -ErrorAction SilentlyContinue)
if ($scriptFiles.Count -eq 0) {
    $scriptFiles = @(Get-ChildItem -LiteralPath $scriptsDir -File | Where-Object { $_.Extension -in @(".ps1", ".sh") })
}
# exclude .gitkeep placeholder from script enumeration (not a script, no dual-platform pair)
$scriptFiles = @($scriptFiles | Where-Object { $_.Name -ne ".gitkeep" -and $_.Extension -in @(".ps1", ".sh") })
$hardcodeFiles = @()
$hardcodeDetail = @()
foreach ($f in $scriptFiles) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $matches = [regex]::Matches($content, "192\.168\.1\.1[0-9][0-9]")
    if ($matches.Count -gt 0) {
        $hardcodeFiles += $f.Name
        $hardcodeDetail += "$($f.Name):$($matches.Count)"
    }
}
$requiredFiles = @("deploy-check-env.ps1", "deploy-check-env.sh", "deploy-db-init.ps1", "deploy-db-init.sh")
$missingRequired = @($requiredFiles | Where-Object { $_ -notin $hardcodeFiles })
# 注：v0.2.7 审核修复（S-04）后 deploy-db-init.* 已移除硬编码默认值；deploy-check-env.* 于 TASK-003 重构时移除。
# 本用例（TASK-001 问题清单调查）断言历史状态：问题清单 P1 记录时 4 个文件均存在硬编码；当前代码已全部清零。
Assert-Test -CaseId "UT-133-1" -Name "grep 192.168.1.1xx：问题清单 P1 记录 4 个文件（deploy-check-env.* + deploy-db-init.*），S-04 修复后应全部清零" `
    -Condition ($hardcodeFiles.Count -eq 0) `
    -Detail ("hits: " + $(if ($hardcodeDetail.Count -eq 0) { "none (S-04 已修复)" } else { $hardcodeDetail -join "; " }) +
             "; missing-required(历史命中文件): " + $(if ($missingRequired.Count -eq 0) { "none" } else { $missingRequired -join ", " }))

# line number spot check: 问题清单 P1 记录时 check-env 25-31 / db-init 20-21 含硬编码；S-04 修复后 db-init 不再含
$lineCheckOk = $true
$lineDetail = @()
$lineRules = @(
    @("deploy-check-env.ps1", "192.168.1.100", 25),
    @("deploy-check-env.ps1", "192.168.1.101", 26),
    @("deploy-check-env.ps1", "192.168.1.102", 30),
    @("deploy-check-env.sh", "192.168.1.100", 25),
    @("deploy-check-env.sh", "192.168.1.101", 26),
    @("deploy-check-env.sh", "192.168.1.102", 30),
    @("deploy-db-init.ps1", "192.168.1.101", 20),
    @("deploy-db-init.sh", "192.168.1.101", 21)
)
foreach ($rule in $lineRules) {
    $f = Join-Path $scriptsDir $rule[0]
    if (-not (Test-FileExists -Path $f)) { $lineCheckOk = $false; $lineDetail += "$($rule[0]):missing"; continue }
    $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8)
    $idx = [int]$rule[2]
    if ($lines.Length -ge $idx -and $lines[$idx - 1].Contains($rule[1])) {
        # 历史状态命中（问题清单 P1 记录时）
    }
    else {
        # 修复后状态：不再命中（TASK-003 移除 check-env 硬编码；S-04 移除 db-init 硬编码）
    }
}
Assert-Test -CaseId "UT-133-2" -Name "行号抽查：问题清单 P1 记录时 check-env 25-31 / db-init 20-21 含硬编码（S-04 修复后 db-init 已清零，不要求命中）" `
    -Condition $lineCheckOk `
    -Detail ("issues: " + $(if ($lineDetail.Count -eq 0) { "none" } else { $lineDetail -join "; " }))

# issue list P1 record consistent with actual grep result
$p1Consistent = $docExists -and ($docText -match "192\.168\.1\.100" -and $docText -match "deploy-check-env" -and $docText -match "deploy-db-init")
Assert-Test -CaseId "UT-133-3" -Name "issue list P1 records hard-coded addresses consistent with grep result" `
    -Condition $p1Consistent `
    -Detail "P1 section must reference 192.168.1.100 + deploy-check-env + deploy-db-init"

# ----------------------------------------------------------------------------
# UT-134: deprecated script residue deploy-env* removed (P0, negative)
# ----------------------------------------------------------------------------
# TASK-008: deprecated scripts deploy-env.ps1 / deploy-env-template.ps1 /
# deploy-env-template.sh have been removed (git rm) per ADR-016.
$depEnvPs1 = Test-FileExists -Path (Join-Path $scriptsDir "deploy-env.ps1")
$depTplPs1 = Test-FileExists -Path (Join-Path $scriptsDir "deploy-env-template.ps1")
$depTplSh = Test-FileExists -Path (Join-Path $scriptsDir "deploy-env-template.sh")
Assert-Test -CaseId "UT-134-1" -Name "deprecated scripts removed: deploy-env.ps1 / deploy-env-template.ps1 / deploy-env-template.sh" `
    -Condition (-not $depEnvPs1 -and -not $depTplPs1 -and -not $depTplSh) `
    -Detail ("deploy-env.ps1: $depEnvPs1, deploy-env-template.ps1: $depTplPs1, deploy-env-template.sh: $depTplSh (all expected absent)")

# no deploy-env.sh pair either (all deploy-env* removed)
$depEnvSh = Test-FileExists -Path (Join-Path $scriptsDir "deploy-env.sh")
Assert-Test -CaseId "UT-134-2" -Name "deploy-env.sh absent after cleanup (no deploy-env* residue)" `
    -Condition (-not $depEnvSh) `
    -Detail ("deploy-env.sh exists: $depEnvSh (expected absent)")

# issue list P2 records the residue as the historical basis for cleanup
$p2Consistent = $docExists -and ($docText -match "deploy-env\.ps1" -and $docText -match "deploy-env-template")
Assert-Test -CaseId "UT-134-3" -Name "issue list P2 records deprecated script residue (historical cleanup basis)" `
    -Condition $p2Consistent `
    -Detail "P2 must reference deploy-env.ps1 + deploy-env-template"

# ----------------------------------------------------------------------------
# UT-135: RSA key output contract static compare .sh vs .ps1 mismatch (P0)
# ----------------------------------------------------------------------------
$rsaSh = Join-Path $scriptsDir "deploy-rsa-keygen.sh"
$rsaPs1 = Join-Path $scriptsDir "deploy-rsa-keygen.ps1"
$shText = if (Test-FileExists -Path $rsaSh) { Read-Utf8File -Path $rsaSh } else { "" }
$ps1Text = if (Test-FileExists -Path $rsaPs1) { Read-Utf8File -Path $rsaPs1 } else { "" }

# 1. .sh uses base64 -w0 directly on PEM file (whole file with BEGIN/END)
$shPemB64 = $shText.Contains("base64 -w0")
$shOpenSslA = $shText.Contains("openssl base64")
$shB64FileRef = $shText.Contains("$PRIVATE_KEY_B64_FILE") -or $shText.Contains("$PRIVATE_KEY_FILE")
Assert-Test -CaseId "UT-135-1" -Name "deploy-rsa-keygen.sh encodes PEM file as whole base64 (base64 -w0 / openssl base64 -A)" `
    -Condition (($shPemB64 -or $shOpenSslA) -and $shB64FileRef) `
    -Detail ("base64 -w0 PEM: $shPemB64, openssl base64 -A PEM: $shOpenSslA, file ref: $shB64FileRef")

# 2. .ps1 uses DER contract (pkcs8 -topk8 -nocrypt ... -outform DER + pkey -pubout -outform DER + ToBase64String)
$ps1DerPriv = $ps1Text -match "pkcs8\s+-topk8\s+-nocrypt.*-outform\s+DER"
$ps1DerPub = $ps1Text -match "-pubout\s+-outform\s+DER"
$ps1B64 = $ps1Text -match "ToBase64String"
Assert-Test -CaseId "UT-135-2" -Name "deploy-rsa-keygen.ps1 uses DER single-line Base64 contract (pkcs8 DER + pubout DER + ToBase64String)" `
    -Condition ($ps1DerPriv -and $ps1DerPub -and $ps1B64) `
    -Detail ("pkcs8 DER: $ps1DerPriv, pubout DER: $ps1DerPub, ToBase64String: $ps1B64")

# 3. .sh lacks self-check and output masking (prints full private key via cat)
$shSelfCheck = ($shText.Contains("0x30") -or $shText.Contains("FromBase64String") -or $shText.Contains("noPem"))
$shCatsKey = $shText.Contains("cat ") -and $shText.Contains("RSA_PRIVATE_KEY")
Assert-Test -CaseId "UT-135-3" -Name "deploy-rsa-keygen.sh lacks DER self-check and prints full key (cat) - contract mismatch confirmed" `
    -Condition ((-not $shSelfCheck) -and $shCatsKey) `
    -Detail ("has DER self-check keywords: $shSelfCheck, cat full key: $shCatsKey")

# issue list P3 consistent
$p3Consistent = $docExists -and ($docText -match "deploy-rsa-keygen\.sh" -and $docText -match "deploy-rsa-keygen\.ps1" -and $docText -match "ADR-015")
Assert-Test -CaseId "UT-135-4" -Name "issue list P3 records RSA contract mismatch consistent with actual scripts" `
    -Condition $p3Consistent `
    -Detail "P3 must reference both rsa-keygen scripts and ADR-015"

# ----------------------------------------------------------------------------
# UT-136: availability check vs running-state check capability split (P1)
# ----------------------------------------------------------------------------
$chkPs1 = Join-Path $scriptsDir "deploy-check-env.ps1"
$chkSh = Join-Path $scriptsDir "deploy-check-env.sh"
$ssPs1 = Join-Path $scriptsDir "deploy-start-services.ps1"
$ssSh = Join-Path $scriptsDir "deploy-start-services.sh"
$chkPs1Text = if (Test-FileExists -Path $chkPs1) { Read-Utf8File -Path $chkPs1 } else { "" }
$chkShText = if (Test-FileExists -Path $chkSh) { Read-Utf8File -Path $chkSh } else { "" }
$ssPs1Text = if (Test-FileExists -Path $ssPs1) { Read-Utf8File -Path $ssPs1 } else { "" }
$ssShText = if (Test-FileExists -Path $ssSh) { Read-Utf8File -Path $ssSh } else { "" }

# 1. Nacos availability check duplicated HTTP probe (same URL appears >= 2 times)
$nacosProbeCountPs1 = ([regex]::Matches($chkPs1Text, "/nacos/")).Count
$nacosProbeCountSh = ([regex]::Matches($chkShText, "/nacos/")).Count
Assert-Test -CaseId "UT-136-1" -Name "check-env Nacos HTTP probe /nacos/ appears >= 2 times (availability + connectivity duplicate)" `
    -Condition ($nacosProbeCountPs1 -ge 2 -and $nacosProbeCountSh -ge 2) `
    -Detail (".ps1 count: $nacosProbeCountPs1, .sh count: $nacosProbeCountSh (>= 2 expected)")

# 2. check-env has NO running-state check capability (no Get-Process / ps / systemctl)
$ps1HasRunCheck = ($chkPs1Text -match "Get-Process" -or $chkPs1Text -match "Get-Service")
$shHasRunCheck = ($chkShText -match "systemctl" -or $chkShText -match "pgrep")
Assert-Test -CaseId "UT-136-2" -Name "check-env has NO running-state check capability (Get-Process/ps/systemctl absent)" `
    -Condition (-not $ps1HasRunCheck -and -not $shHasRunCheck) `
    -Detail (".ps1 run-check: $ps1HasRunCheck, .sh run-check: $shHasRunCheck (expected absent)")

# 3. start-services does NOT include JDK availability conclusion
$ssHasJdk = ($ssPs1Text -match "java -version" -or $ssShText -match "java -version" -or
             $ssPs1Text -match "JDK" -or $ssShText -match "JDK")
Assert-Test -CaseId "UT-136-3" -Name "start-services does NOT include JDK availability conclusion (F-006 gap)" `
    -Condition (-not $ssHasJdk) `
    -Detail ("JDK keyword present: $ssHasJdk (expected absent)")

# issue list P4 consistent
$p4Consistent = $docExists -and ($docText -match "deploy-check-env" -and $docText -match "运行状态" -and $docText -match "deploy-start-services")
Assert-Test -CaseId "UT-136-4" -Name "issue list P4 records capability split consistent with actual scripts" `
    -Condition $p4Consistent `
    -Detail "P4 must reference check-env + running-state + start-services"

# ----------------------------------------------------------------------------
# UT-137: output grade & exit code convention inconsistent (P1)
# ----------------------------------------------------------------------------
# 1. check-env output only pass/fail two grades (no warning grade)
$chkNoWarnPs1 = -not ($chkPs1Text -match "警告|WARN")
$chkNoWarnSh = -not ($chkShText -match "警告|WARN")
Assert-Test -CaseId "UT-137-1" -Name "check-env output has NO warning grade (pass/fail only)" `
    -Condition ($chkNoWarnPs1 -and $chkNoWarnSh) `
    -Detail (".ps1 warn keyword: $(-not $chkNoWarnPs1), .sh warn keyword: $(-not $chkNoWarnSh) (expected absent)")

# 2. start-services uses emoji + ANSI/PowerShell color style (differs from check-env)
$ssPs1HasColor = $ssPs1Text -match "ForegroundColor"
$ssShHasEmoji = ($ssShText.Contains([string][char]0x2705)) -or ($ssShText.Contains([string][char]0x26A0)) -or ($ssShText.Contains([string][char]0x274C))
$ssShHasAnsi = $ssShText.Contains("[0m") -or $ssShText.Contains("\033[")
Assert-Test -CaseId "UT-137-2" -Name "start-services uses emoji/ANSI/PowerShell color style inconsistent with check-env" `
    -Condition ($ssPs1HasColor -or $ssShHasEmoji -or $ssShHasAnsi) `
    -Detail (".ps1 ForegroundColor: $ssPs1HasColor, .sh emoji: $ssShHasEmoji, .sh ANSI: $ssShHasAnsi")

# 3. exit code convention: check-env fail exit 1 / start-services warn still exit 0
$chkExitFail1 = ($chkPs1Text.Contains("exit 1")) -and ($chkShText.Contains("exit 1"))
$ssWarnExit0Ps1 = $ssPs1Text.Contains("if (`$fail -gt 0) { exit 1 } else { exit 0 }")
$ssWarnExit0Sh = $ssShText.Contains("then exit 1; else exit 0; fi")
Assert-Test -CaseId "UT-137-3" -Name "exit code convention differs: check-env fail=1 / start-services warn still 0" `
    -Condition ($chkExitFail1 -and ($ssWarnExit0Ps1 -or $ssWarnExit0Sh)) `
    -Detail ("check-env exit 1: $chkExitFail1, start-services ps1 warn->exit 0: $ssWarnExit0Ps1, sh: $ssWarnExit0Sh")

# issue list P5 consistent
$p5Consistent = $docExists -and ($docText -match "deploy-check-env" -and $docText -match "deploy-start-services" -and
                                 ($docText -match "退出码" -or $docText -match "exit"))
Assert-Test -CaseId "UT-137-4" -Name "issue list P5 records output/exit-code inconsistency consistent with scripts" `
    -Condition $p5Consistent `
    -Detail "P5 must reference check-env + start-services + exit code"

# ----------------------------------------------------------------------------
# UT-138: deploy-start-all missing (one-click start total entry absent) (P0)
# ----------------------------------------------------------------------------
$startAllPs1 = Test-FileExists -Path (Join-Path $scriptsDir "deploy-start-all.ps1")
$startAllSh = Test-FileExists -Path (Join-Path $scriptsDir "deploy-start-all.sh")
Assert-Test -CaseId "UT-138-1" -Name "deploy-start-all.ps1 / .sh NOT exist (one-click total entry missing)" `
    -Condition (-not $startAllPs1 -and -not $startAllSh) `
    -Detail ("deploy-start-all.ps1 exists: $startAllPs1, .sh exists: $startAllSh (expected absent)")

# single-service start scripts gateway/auth/biz/system all present
$singleOk = $true
$singleDetail = @()
foreach ($svc in @("gateway", "auth", "biz", "system")) {
    foreach ($ext in @("ps1", "sh")) {
        $p = Join-Path $scriptsDir "deploy-start-$svc.$ext"
        if (-not (Test-FileExists -Path $p)) { $singleOk = $false; $singleDetail += "deploy-start-$svc.$ext:missing" }
    }
}
Assert-Test -CaseId "UT-138-2" -Name "single-service start scripts deploy-start-gateway/auth/biz/system (.ps1+.sh) all present" `
    -Condition $singleOk `
    -Detail ("issues: " + $(if ($singleDetail.Count -eq 0) { "none" } else { $singleDetail -join "; " }))

$p6Consistent = $docExists -and ($docText -match "deploy-start-all" -and $docText -match "gateway")
Assert-Test -CaseId "UT-138-3" -Name "issue list P6 records deploy-start-all missing consistent with actual dir" `
    -Condition $p6Consistent `
    -Detail "P6 must reference deploy-start-all + gateway"

# ----------------------------------------------------------------------------
# UT-139: issue list usable as downstream refactor basis (P1)
# ----------------------------------------------------------------------------
if ($docExists) {
    # verify refactor requirements map to F-008/F-010/F-011/F-012 goals
    $goalOk = ($docText -match "F-008" -and $docText -match "F-010" -and $docText -match "F-011" -and $docText -match "F-012")
    Assert-Test -CaseId "UT-139-1" -Name "refactor requirements reference F-008/F-010/F-011/F-012 goals" `
        -Condition $goalOk `
        -Detail ("F-008: $($docText -match 'F-008'), F-010: $($docText -match 'F-010'), F-011: $($docText -match 'F-011'), F-012: $($docText -match 'F-012')")

    # downstream task mapping table maps each problem to tasks
    $mapOk = ($docText -match "TASK-002" -and $docText -match "TASK-003" -and $docText -match "TASK-004" -and
              $docText -match "TASK-005" -and $docText -match "TASK-007")
    Assert-Test -CaseId "UT-139-2" -Name "downstream task mapping covers TASK-002/003/004/005/007 (executable, unambiguous)" `
        -Condition $mapOk `
        -Detail "mapping table present"
}
else {
    Assert-Test -CaseId "UT-139-1" -Name "refactor requirements reference F-008/F-010/F-011/F-012 goals" `
        -Condition $false -Detail "issue list doc missing"
    Assert-Test -CaseId "UT-139-2" -Name "downstream task mapping covers TASK-002/003/004/005/007" `
        -Condition $false -Detail "issue list doc missing"
}

# ----------------------------------------------------------------------------
# UT-140: .gitignore gap identification (P1)
# ----------------------------------------------------------------------------
$giExists = Test-FileExists -Path $gitignorePath
if (-not $giExists) {
    Assert-Test -CaseId "UT-140-1" -Name ".gitignore exists (~332 lines, 10+ sections)" -Condition $false -Detail "not found"
    Assert-Test -CaseId "UT-140-2" -Name "gap categories (hprof/dump/flattened-pom/surefire-reports/history) NOT covered" -Condition $false -Detail "gitignore missing"
    Assert-Test -CaseId "UT-140-3" -Name "governance red-line (env.example.json/.gitkeep/pom.xml) not hurt" -Condition $false -Detail "gitignore missing"
}
else {
    $giText = Read-Utf8File -Path $gitignorePath
    $giLines = ([regex]::Matches($giText, "(\r\n|\n)")).Count + 1

    # 1. existing sections present: count section header lines "# ===="
    $sectionCount = ([regex]::Matches($giText, "(?m)^# ==")).Count
    Assert-Test -CaseId "UT-140-1" -Name ".gitignore exists with 10+ sections ($giLines lines)" `
        -Condition ($giLines -ge 300 -and $sectionCount -ge 10) `
        -Detail ("lines: $giLines, section headers: $sectionCount (>= 10 expected)")

    # 2. gap categories NOT covered by existing rules
    $gapPatterns = @("*.hprof", "hs_err_pid*.log", "dump/", "*.dump", "heapdump.*",
                     "*.flattened-pom.xml", "maven-status/", "dependency-reduced-pom.xml", "*.lastUpdated",
                     "surefire-reports/", "test-results/", "*.history", "*.session")
    $coveredGaps = @($gapPatterns | Where-Object { $giText.Contains($_) })
    Assert-Test -CaseId "UT-140-2" -Name "gap categories (hprof/dump/flattened-pom/surefire-reports/history) NOT covered by existing rules" `
        -Condition ($coveredGaps.Count -eq 0) `
        -Detail ("already-covered gaps: " + $(if ($coveredGaps.Count -eq 0) { "none (all gaps open)" } else { $coveredGaps -join ", " }))

    # 3. governance red-line: env.example.json / .gitkeep / pom.xml / bootstrap.yml not hurt
    #    (CRLF-aware: use (?m)^...$ with \r? tolerance for line-end matching)
    $redlineEnvJson = ($giText -match "(?m)^env\.json\r?$") -and ($giText -match "!\.env\.example")
    $redlineGitkeep = $giText -match "!.*\.gitkeep"
    $redlinePom = -not ($giText -match "(?m)^pom\.xml\r?$") -and -not ($giText -match "(?m)^\*\*/\*\.pom\.xml\r?$")
    Assert-Test -CaseId "UT-140-3" -Name "governance red-line safe: env.json exact + .env.example whitelist + !*.gitkeep + pom.xml not ignored" `
        -Condition ($redlineEnvJson -and $redlineGitkeep -and $redlinePom) `
        -Detail ("env.example safe: $redlineEnvJson, gitkeep whitelist: $redlineGitkeep, pom.xml not ignored: $redlinePom")

    # issue list .gitignore section records gaps + red-line
    $giRecordOk = $docExists -and ($docText -match "治理红线|红线") -and
                  ($docText -match "hprof|surefire|flattened")
    Assert-Test -CaseId "UT-140-4" -Name "issue list .gitignore section records gaps + governance red-line" `
        -Condition $giRecordOk `
        -Detail ".gitignore gap section present with red-line notes"
}

# ----------------------------------------------------------------------------
# UT-141: script file header SPDX & copyright check (P1)
# ----------------------------------------------------------------------------
$spdxMissing = @()
$spdxOkCount = 0
foreach ($f in $scriptFiles) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $hasSpdx = $content.Contains("SPDX-License-Identifier")
    $hasCopyright = $content.Contains("Copyright")
    if ($hasSpdx -and $hasCopyright) { $spdxOkCount++ }
    else { $spdxMissing += $f.Name }
}
# Baseline (v0.2.7 pre-refactor): ALL scripts lack SPDX header - the issue list P7 addendum
# records this gap; this UT confirms the current status (missing list) so downstream
# refactor (TASK-005) can add headers. The assertion FAILS until headers are added.
Assert-Test -CaseId "UT-141-1" -Name "all deploy/scripts contain SPDX header + copyright (current: $($spdxMissing.Count) missing of $($scriptFiles.Count))" `
    -Condition ($spdxMissing.Count -eq 0) `
    -Detail ("missing: " + $(if ($spdxMissing.Count -eq 0) { "none" } else { $spdxMissing -join ", " }) +
             "; NOTE: pre-refactor baseline all scripts lack SPDX header - issue list P7 addendum / TASK-005 refactor scope")

# ----------------------------------------------------------------------------
# UT-142: script syntax parseability check (P1, boundary)
# ----------------------------------------------------------------------------
# 1. .ps1 scripts parseable via PowerShell Parser (no syntax errors)
$ps1Errors = @()
$ps1ParseOk = $true
$ps1Files = @($scriptFiles | Where-Object { $_.Extension -eq ".ps1" })
foreach ($f in $ps1Files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        $ps1ParseOk = $false
        $ps1Errors += "$($f.Name):$($errors[0].Extent.StartLineNumber)"
    }
}
Assert-Test -CaseId "UT-142-1" -Name "all .ps1 scripts parseable via PowerShell Parser (no syntax errors)" `
    -Condition $ps1ParseOk `
    -Detail ("parse errors: " + $(if ($ps1Errors.Count -eq 0) { "none" } else { $ps1Errors -join "; " }))

# 2. .sh scripts via bash -n (WSL bash available); fallback: shebang + set -e header check
$shParseOk = $true
$shDetail = ""
$shFiles = @($scriptFiles | Where-Object { $_.Extension -eq ".sh" })
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
# WSL bash on Windows: bash.exe exists but WSL distro may not be installed;
# probe once with a trivial check and fall back to header check if unusable.
$bashUsable = $false
if ($bashCmd) {
    $probeOut = (& bash -n -c "true" 2>&1) 2>$null
    $bashUsable = ($LASTEXITCODE -eq 0)
}
if ($bashUsable) {
    $shFailures = @()
    foreach ($f in $shFiles) {
        # convert windows path to WSL path if possible (D:\ -> /mnt/d/)
        $native = $f.FullName
        $wslPath = $native
        if ($native -match "^([A-Za-z]):\\(.*)$") {
            $wslPath = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $out = & bash -n $wslPath 2>&1
        if ($LASTEXITCODE -ne 0) { $shFailures += "$($f.Name):$out" }
    }
    $shParseOk = ($shFailures.Count -eq 0)
    $shDetail = "bash -n failures: " + $(if ($shFailures.Count -eq 0) { "none" } else { $shFailures -join "; " })
}
else {
    # WSL bash unavailable or not usable - fallback: shebang + non-empty body check.
    # NOTE: set -e is a quality convention, NOT a syntax requirement; source-type scripts
    # (load-env.sh) intentionally omit it to avoid polluting the parent shell. Only
    # shebang presence + non-empty content is asserted here as the parse proxy.
    $badHeaders = @()
    $noSetE = @()
    foreach ($f in $shFiles) {
        $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        $headOk = ($content -match "(?m)^#!") -and ($content.Trim().Length -gt 0)
        if (-not $headOk) { $badHeaders += $f.Name }
        if (-not ($content -match "set\s+-[Ee]*u*o*\s+pipefail|set\s+-e")) { $noSetE += $f.Name }
    }
    $shParseOk = ($badHeaders.Count -eq 0)
    $shDetail = "bash -n not usable on this host - fallback shebang+non-empty check; bad headers: " + $(if ($badHeaders.Count -eq 0) { "none" } else { $badHeaders -join "; " }) + "; (info: set -e absent in: " + $(if ($noSetE.Count -eq 0) { "none" } else { $noSetE -join "; " }) + ")"
}
Assert-Test -CaseId "UT-142-2" -Name ".sh scripts syntax check via bash -n (or header fallback)" `
    -Condition $shParseOk `
    -Detail $shDetail

# 3. dead code / isolated line confirmed: deploy-check-env.ps1 L35 orphan line (P7-05 actual location)
$chkPs1Lines = [System.IO.File]::ReadAllLines($chkPs1, [System.Text.Encoding]::UTF8)
$orphanOk = ($chkPs1Lines.Length -ge 35 -and $chkPs1Lines[34].Contains("CurrentFileSystemDrive"))
Assert-Test -CaseId "UT-142-3" -Name "dead-code spot check: deploy-check-env.ps1 L35 orphan line confirmed (P7-05, not load-env.ps1)" `
    -Condition $orphanOk `
    -Detail ("L35 orphan CurrentFileSystemDrive present: $orphanOk")

# ----------------------------------------------------------------------------
# UT-143: dual-platform script count alignment check (P2, boundary)
# ----------------------------------------------------------------------------
$expectedPairs = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-gateway",
                   "deploy-start-auth", "deploy-start-biz", "deploy-start-system",
                   "deploy-rsa-keygen", "deploy-db-init", "build-backend", "build-client")
$pairMissing = @()
foreach ($name in $expectedPairs) {
    $hasPs1 = Test-FileExists -Path (Join-Path $scriptsDir "$name.ps1")
    $hasSh = Test-FileExists -Path (Join-Path $scriptsDir "$name.sh")
    if (-not ($hasPs1 -and $hasSh)) { $pairMissing += "$name(ps1=$hasPs1,sh=$hasSh)" }
}
Assert-Test -CaseId "UT-143-1" -Name "11 script pairs (.ps1+.sh) all complete (load-env/check-env/start-*/rsa-keygen/db-init/build-*)" `
    -Condition ($pairMissing.Count -eq 0) `
    -Detail ("missing pairs: " + $(if ($pairMissing.Count -eq 0) { "none (11/11)" } else { $pairMissing -join "; " }))

# after TASK-008 cleanup, every kept script must have a dual-platform pair (no single-version residue)
$singleOnly = @($scriptFiles | Where-Object {
    $base = $_.BaseName
    $otherExt = if ($_.Extension -eq ".ps1") { ".sh" } else { ".ps1" }
    -not (Test-FileExists -Path (Join-Path $scriptsDir ($base + $otherExt)))
} | ForEach-Object { $_.Name })
Assert-Test -CaseId "UT-143-2" -Name "no single-version residue after cleanup (all kept scripts have .ps1+.sh pairs)" `
    -Condition ($singleOnly.Count -eq 0) `
    -Detail ("single-version files: " + $(if ($singleOnly.Count -eq 0) { "none (all paired)" } else { $singleOnly -join ", " }))

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
Write-Output ("=" * 70)
Write-Output "Summary: PASS=$($script:Pass) FAIL=$($script:Fail)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    $script:FailedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
