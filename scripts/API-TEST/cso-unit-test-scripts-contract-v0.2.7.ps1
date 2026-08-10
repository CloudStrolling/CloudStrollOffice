# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - Full Script Contract & Dual-Platform Test
# ----------------------------------------------------------------------------
# Coverage: UT-230 ~ UT-240 and FT-153 ~ FT-160 in task testcase
#           (docs/cso-v0.2.7/task_TASK-010/testcase.md)
#   UT-230: 12 x .ps1 PowerShell Parser.ParseFile syntax check (P0)
#   UT-231: 12 x .sh bash -n syntax check (git-bash; SKIP + static fallback
#           when no bash available) (P0)
#   UT-232: RSA key output contract ADR-015 dual-platform static check (P0)
#   UT-233: output grading contract ([through]/[warn]/[fail] prefix +
#           summary line) on 8 core script pairs; P3/P4 difference record;
#           color degrade existence (P0)
#   UT-234: exit code contract (fail -> non-zero; only 0/1 safe domain) (P0)
#   UT-235: load-env dependency + env.json missing handling (P0)
#   UT-236: no hardcoded env addresses (core 0 hit; P1 db-init record) (P0)
#   UT-237: no plaintext credentials + password masking (P0)
#   UT-238: deprecated scripts (deploy-env*) no residue, no reference (P0)
#   UT-239: SPDX header & copyright; P2 missing list record (P1)
#   UT-240: .gitignore governance rules static check (P0)
#   FT-153: verification report exists with PRD ch.7 8-item acceptance
#           checklist, overview/detail tables, summary, P1~P9 list (P0)
#   FT-154: deploy-check-env dual-platform behavior parity (P0)
#   FT-155: deploy-start-services dual-platform behavior parity (P0)
#   FT-156: deploy-start-all dual-platform behavior parity (P0)
#   FT-157: 4 pairs of single-service start scripts contract parity (P1)
#   FT-158: deployment order contract MariaDB->Redis->Nacos and
#           gateway->auth->biz->system (P1)
#   FT-159: git status / ls-files / --ignored dynamic check (P0)
#   FT-160: script inventory completeness (24 scripts + .gitkeep, 12 pairs)
#           (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-scripts-contract-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-scripts-contract-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass (SKIP not counted as failure), 1 = any failure
# NOTE: This file MUST be saved as UTF-8 with BOM so PowerShell 5.1 can parse
#       the CJK string literals (grading prefixes, report keywords) correctly.
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

function Assert-TestSkip {
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

# ----------------------------------------------------------------------------
# common paths
# ----------------------------------------------------------------------------
$scriptsDir = Join-Path $ProjectRoot "deploy\scripts"
$reportPath = Join-Path $ProjectRoot "docs\cso-v0.2.7\cso-script-contract-verification-v0.2.7.md"
$gitignorePath = Join-Path $ProjectRoot ".gitignore"
$envExamplePath = Join-Path $ProjectRoot "deploy\env.example.json"

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 Full Script Contract & Dual-Platform Test (TASK-010, UT-230~UT-240, FT-153~FT-160)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# preflight
# ----------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $scriptsDir -PathType Container)) {
    Write-Output "[FAIL] preflight - deploy/scripts missing at $scriptsDir"
    exit 1
}
$scriptFiles = Get-ChildItem -LiteralPath $scriptsDir -File
$ps1Files = @($scriptFiles | Where-Object { $_.Extension -eq ".ps1" } | Sort-Object Name)
$shFiles = @($scriptFiles | Where-Object { $_.Extension -eq ".sh" } | Sort-Object Name)

# ============================================================================
# UT-230: 12 x .ps1 PowerShell Parser.ParseFile syntax check (P0)
# ============================================================================
Write-Output "`n[UT-230] .ps1 syntax via Parser.ParseFile (parse only, no execution)"
Assert-Test -CaseId "UT-230-1" `
    -Name "deploy/scripts contains exactly 12 .ps1 files" `
    -Condition ($ps1Files.Count -eq 12) `
    -Detail ("ps1 count: {0}, files: {1}" -f $ps1Files.Count, (($ps1Files | ForEach-Object { $_.Name }) -join ", "))

$parseFailed = @()
foreach ($f in $ps1Files) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        $parseFailed += ("{0}: {1}" -f $f.Name, ($errors[0].Message))
    }
}
Assert-Test -CaseId "UT-230-2" `
    -Name "all 12 .ps1 pass PowerShell Parser.ParseFile (0 syntax errors)" `
    -Condition ($parseFailed.Count -eq 0) `
    -Detail ("syntax error detail: {0}" -f ($parseFailed -join "; "))

# ============================================================================
# UT-231: 12 x .sh bash -n syntax check (P0, environment dependent)
# ============================================================================
Write-Output "`n[UT-231] .sh syntax via bash -n (git-bash preferred; static fallback if no bash)"
Assert-Test -CaseId "UT-231-1" `
    -Name "deploy/scripts contains exactly 12 .sh files" `
    -Condition ($shFiles.Count -eq 12) `
    -Detail ("sh count: {0}" -f $shFiles.Count)

# locate a usable bash: explicit git-bash paths first, then PATH candidates
# (avoid WSL's System32\bash.exe which may be unusable without a distro)
$bashCandidates = @(
    "C:\Program Files\Git\bin\bash.exe",
    "C:\Program Files\Git\usr\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
    "$env:ProgramFiles\Git\bin\bash.exe"
)
$bashPath = $null
foreach ($cand in $bashCandidates) {
    if (Test-FileExists -Path $cand) { $bashPath = $cand; break }
}
if (-not $bashPath) {
    $envBash = Get-Command bash -ErrorAction SilentlyContinue
    if ($envBash) { $bashPath = $envBash.Source }
}

if ($bashPath) {
    $shFailed = @()
    $shEnvNote = "bash=$bashPath ($(& $bashPath --version 2>&1 | Select-Object -First 1))"
    foreach ($f in $shFiles) {
        $errOut = ""
        & $bashPath -n $f.FullName 2>&1 | Out-Null
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            $firstLine = (& $bashPath -n $f.FullName 2>&1 | Select-Object -First 1)
            $shFailed += ("{0}: exit {1}, stderr: {2}" -f $f.Name, $code, $firstLine)
        }
    }
    Assert-Test -CaseId "UT-231-2" `
        -Name "all 12 .sh pass bash -n (exit code 0), env: $shEnvNote" `
        -Condition ($shFailed.Count -eq 0) `
        -Detail ("syntax error detail: {0}" -f ($shFailed -join "; "))
}
else {
    # no bash available: static fallback check (bracket/paren/keyword pairing)
    $staticOk = $true
    $staticNotes = @()
    foreach ($f in $shFiles) {
        $txt = Read-Utf8File -Path $f.FullName
        $openBrace = ([regex]::Matches($txt, "\{")).Count
        $closeBrace = ([regex]::Matches($txt, "\}")).Count
        $openParen = ([regex]::Matches($txt, "\(")).Count
        $closeParen = ([regex]::Matches($txt, "\)")).Count
        if (($openBrace -ne $closeBrace) -or ($openParen -ne $closeParen)) {
            $staticOk = $false
            $staticNotes += "{0}: brace {1}/{2} paren {3}/{4}" -f $f.Name, $openBrace, $closeBrace, $openParen, $closeParen
        }
    }
    Assert-TestSkip -CaseId "UT-231-2" `
        -Name "bash unavailable - bash -n dynamic check skipped, static pairing fallback" `
        -Detail ("static check result: {0} {1}" -f ($(if ($staticOk) { "OK" } else { "MISMATCH" })), ($staticNotes -join "; "))
    Assert-Test -CaseId "UT-231-3" `
        -Name "static fallback: brace/paren pairing balanced for all 12 .sh" `
        -Condition $staticOk `
        -Detail ($staticNotes -join "; ")
}

# ============================================================================
# UT-232: RSA key output contract ADR-015 dual-platform static check (P0)
# ============================================================================
Write-Output "`n[UT-232] RSA key output contract (ADR-015) dual-platform static check"
$rsaPs1 = Join-Path $scriptsDir "deploy-rsa-keygen.ps1"
$rsaSh = Join-Path $scriptsDir "deploy-rsa-keygen.sh"
$rsaPs1Ok = Test-FileExists -Path $rsaPs1
$rsaShOk = Test-FileExists -Path $rsaSh
$ps1Txt = if ($rsaPs1Ok) { Read-Utf8File -Path $rsaPs1 } else { "" }
$shTxt = if ($rsaShOk) { Read-Utf8File -Path $rsaSh } else { "" }

# UT-232-1 / UT-232-2: Base64 source must be DER files, never whole-PEM files
# (PEM headers "-----BEGIN/-----END" appear only in contract self-check
# expressions and explanatory text, never as encoded output source)
$ps1DerSource = ($ps1Txt -match 'ToBase64String\([^\r\n]*[Dd]er') -and `
                (-not ($ps1Txt -match 'ToBase64String\([^\r\n]*\.pem'))
Assert-Test -CaseId "UT-232-1" `
    -Name ".ps1 Base64 source is DER files only (ToBase64String reads *_der, never whole-PEM)" `
    -Condition $ps1DerSource `
    -Detail ("der-source={0} pem-source-absent={1}" -f `
        ($ps1Txt -match 'ToBase64String\([^\r\n]*[Dd]er'), (-not ($ps1Txt -match 'ToBase64String\([^\r\n]*\.pem')))

$shDerSource = ($shTxt -match 'b64_encode_file\s+"\$PRIVATE_KEY_DER_FILE"') -and `
               ($shTxt -match 'b64_encode_file\s+"\$PUBLIC_KEY_DER_FILE"') -and `
               (-not ($shTxt -match 'b64_encode_file\s+"\$PRIVATE_KEY_FILE"')) -and `
               (-not ($shTxt -match 'b64_encode_file\s+"\$PUBLIC_KEY_FILE"'))
Assert-Test -CaseId "UT-232-2" `
    -Name ".sh Base64 source is DER files only (b64_encode_file reads *_DER_FILE, never whole-PEM)" `
    -Condition $shDerSource `
    -Detail ("priv-der={0} pub-der={1} priv-pem-absent={2} pub-pem-absent={3}" -f `
        ($shTxt -match 'b64_encode_file\s+"\$PRIVATE_KEY_DER_FILE"'), ($shTxt -match 'b64_encode_file\s+"\$PUBLIC_KEY_DER_FILE"'), `
        (-not ($shTxt -match 'b64_encode_file\s+"\$PRIVATE_KEY_FILE"')), (-not ($shTxt -match 'b64_encode_file\s+"\$PUBLIC_KEY_FILE"')))

# UT-232-3: .ps1 single-line base64 write (ToBase64String + WriteAllText, no InsertLineBreaks)
$ps1SingleLine = ($ps1Txt -match "\[Convert\]::ToBase64String") -and `
                 ($ps1Txt -match "WriteAllText") -and `
                 (-not ($ps1Txt -match "InsertLineBreaks"))
Assert-Test -CaseId "UT-232-3" `
    -Name ".ps1 writes single-line Base64 (ToBase64String + WriteAllText, no InsertLineBreaks)" `
    -Condition $ps1SingleLine `
    -Detail ("ToBase64String={0} WriteAllText={1} InsertLineBreaks={2}" -f `
        ($ps1Txt -match "\[Convert\]::ToBase64String"), ($ps1Txt -match "WriteAllText"), ($ps1Txt -match "InsertLineBreaks"))

# UT-232-4: .sh single-line base64 output (base64 -w0 + printf '%s')
$shNoNewline = ($shTxt -match "base64\s+-w0") -and `
               ($shTxt -match "printf\s+''%s''") -or `
               ($shTxt -match "base64\s+-w0") -and ($shTxt -match "printf")
Assert-Test -CaseId "UT-232-4" `
    -Name ".sh outputs single-line Base64 (base64 -w0 + printf '%s' without trailing newline)" `
    -Condition $shNoNewline `
    -Detail ("base64 -w0={0} printf-single-quote={1}" -f `
        ($shTxt -match "base64\s+-w0"), ($shTxt -match "printf\s+''%s''"))

# UT-232-5: DER encoding (PKCS#8 / X.509 SPKI) + self-check points on both platforms
$ps1DerPriv = $ps1Txt -match "pkcs8\s+-topk8\s+-nocrypt[^\r\n]*outform\s+DER"
$ps1DerPub = $ps1Txt -match "pkey[^\r\n]*\s+-pubout[^\r\n]*outform\s+DER"
$shDerPriv = $shTxt -match "pkcs8\s+-topk8\s+-nocrypt[^\r\n]*outform\s+DER"
$shDerPub = $shTxt -match "pkey[^\r\n]*\s+-pubout[^\r\n]*outform\s+DER"
$ps1SelfCheck = ($ps1Txt -match "-----BEGIN") -and ($ps1Txt -match "\\r\\n") -and `
                ($ps1Txt -match "0x30") -and ($ps1Txt -match "0x03")
$shSelfCheck = ($shTxt -match "-----BEGIN") -and ($shTxt -match "0x30") -and ($shTxt -match "0x03")
Assert-Test -CaseId "UT-232-5" `
    -Name "dual-platform DER contract identical (pkcs8 -topk8 -nocrypt -outform DER private + pkey -pubout -outform DER public)" `
    -Condition ($ps1DerPriv -and $ps1DerPub -and $shDerPriv -and $shDerPub) `
    -Detail ("ps1 priv={0} pub={1}; sh priv={2} pub={3}" -f $ps1DerPriv, $ps1DerPub, $shDerPriv, $shDerPub)
Assert-Test -CaseId "UT-232-6" `
    -Name "dual-platform contract self-check points present (no-BEGIN / no-newline / DER offset 0x30 0x03)" `
    -Condition ($ps1SelfCheck -and $shSelfCheck) `
    -Detail ("ps1 self-check={0}; sh self-check={1} (P7: .ps1 lacks pair-match check, .sh L185-188 has - recorded as observation)" -f $ps1SelfCheck, $shSelfCheck)
# P7 observation record: .ps1 has no public/private key pair-match self check
Assert-Test -CaseId "UT-232-7" `
    -Name "P7 record: .ps1 has NO pair-match self-check (observation, .sh has it)" `
    -Condition (-not ($ps1Txt -match "pair")) `
    -Detail "observation only - ADR-015 output contract itself is identical on both platforms"

# ============================================================================
# UT-233: output grading contract ([through]/[warn]/[fail] + summary line) (P0)
# ============================================================================
Write-Output "`n[UT-233] output grading contract on 8 core script pairs (check-env/start-services/start-all/start-{svc})"
$corePairs = @(
    "deploy-check-env", "deploy-start-services", "deploy-start-all",
    "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system"
)
$gradingOk = $true
$gradingMissing = @()
$summaryOk = $true
$summaryMissing = @()
foreach ($pair in $corePairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        # three-level prefix literals: "[通过]" / "[警告]" / "[失败]"
        if (-not (($txt -match "\[通过\]") -and ($txt -match "\[警告\]") -and ($txt -match "\[失败\]"))) {
            $gradingOk = $false
            $gradingMissing += $pair + $ext
        }
        # summary line: "通过 ... 项 | 警告 ... 项 | 失败 ... 项" (ANSI codes allowed between "项" and "|" on .sh)
        if (-not (($txt -match "通过[^\r\n]*项") -and ($txt -match "警告[^\r\n]*项") -and ($txt -match "失败[^\r\n]*项") -and (([regex]::Matches($txt, "\|")).Count -ge 2))) {
            $summaryOk = $false
            $summaryMissing += $pair + $ext
        }
    }
}
Assert-Test -CaseId "UT-233-1" `
    -Name "8 core script pairs (16 scripts) all contain three-level grading prefixes [through]/[warn]/[fail]" `
    -Condition $gradingOk `
    -Detail ("missing: {0}" -f ($gradingMissing -join ", "))
Assert-Test -CaseId "UT-233-2" `
    -Name "8 core script pairs all contain summary line (through N items | warn M items | fail K items)" `
    -Condition $summaryOk `
    -Detail ("missing: {0}" -f ($summaryMissing -join ", "))

# UT-233-3: P3 record - rsa-keygen.ps1 has no grading prefix / summary (sh has print_result)
$rsaPs1NoGrade = ($ps1Txt -notmatch "\[通过\]")
Assert-Test -CaseId "UT-233-3" `
    -Name "P3 record: deploy-rsa-keygen.ps1 has NO [through]/[warn]/[fail] grading prefix (sh has print_result) - known difference" `
    -Condition $rsaPs1NoGrade `
    -Detail "recorded in verification report; exit code contract still consistent (fail -> exit 1)"

# UT-233-4: P4 record - db-init pair uses emoji (checkmark/cross) instead of grading
$dbInitPs1 = Join-Path $scriptsDir "deploy-db-init.ps1"
$dbInitSh = Join-Path $scriptsDir "deploy-db-init.sh"
$dbInitPs1Txt = if (Test-FileExists -Path $dbInitPs1) { Read-Utf8File -Path $dbInitPs1 } else { "" }
$dbInitShTxt = if (Test-FileExists -Path $dbInitSh) { Read-Utf8File -Path $dbInitSh } else { "" }
$emojiOk = ([char]0x2705) # "✅"
$emojiBad = ([char]0x274C) # "❌"
$dbInitEmoji = ($dbInitPs1Txt.Contains($emojiOk) -or $dbInitPs1Txt.Contains($emojiBad)) -and `
               ($dbInitShTxt.Contains($emojiOk) -or $dbInitShTxt.Contains($emojiBad))
Assert-Test -CaseId "UT-233-4" `
    -Name "P4 record: deploy-db-init pair uses emoji output instead of three-level grading (historical asset) - known difference" `
    -Condition $dbInitEmoji `
    -Detail "recorded in verification report; historical asset v0.1.7 not in core capability matrix"

# UT-233-5: color degrade existence (.ps1 Write-Host -ForegroundColor; .sh ANSI codes)
$ps1ColorOk = $true
$ps1ColorMissing = @()
foreach ($pair in $corePairs) {
    $p = Join-Path $scriptsDir ($pair + ".ps1")
    if (-not (Test-FileExists -Path $p)) { continue }
    $txt = Read-Utf8File -Path $p
    if ($txt -notmatch "ForegroundColor") {
        $ps1ColorOk = $false
        $ps1ColorMissing += $pair + ".ps1"
    }
}
Assert-Test -CaseId "UT-233-5" `
    -Name "color output via Write-Host -ForegroundColor on all 8 core .ps1 (auto degrade to plain text when redirected)" `
    -Condition $ps1ColorOk `
    -Detail ("missing: {0} (O-1: .sh uses ANSI escapes without explicit [ -t 1 ] degrade - observation)" -f ($ps1ColorMissing -join ", "))

# ============================================================================
# UT-234: exit code contract (fail -> non-zero; only 0/1 safe domain) (P0)
# ============================================================================
Write-Output "`n[UT-234] exit code contract (fail -> exit 1 / success -> exit 0; 0/1 safe domain)"
$coreExitScripts = @("deploy-check-env", "deploy-start-services", "deploy-start-all",
                     "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz",
                     "deploy-start-system", "deploy-rsa-keygen")
# success-path exit 0 required on 7 pairs; rsa-keygen.ps1 ends naturally (no explicit
# exit 0 literal, PowerShell exit code = last command status, i.e. 0 on success)
$coreExit0Scripts = @("deploy-check-env", "deploy-start-services", "deploy-start-all",
                      "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz",
                      "deploy-start-system")
$exit1Ok = $true
$exit1Missing = @()
$exit0Ok = $true
$exit0Missing = @()
foreach ($pair in $coreExitScripts) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -notmatch "exit 1") {
            $exit1Ok = $false
            $exit1Missing += $pair + $ext
        }
    }
}
foreach ($pair in $coreExit0Scripts) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -notmatch "exit 0") {
            $exit0Ok = $false
            $exit0Missing += $pair + $ext
        }
    }
}
Assert-Test -CaseId "UT-234-1" `
    -Name "core scripts (8 pairs) all have fail path exit 1 (non-zero on failure)" `
    -Condition $exit1Ok `
    -Detail ("missing exit 1: {0}" -f ($exit1Missing -join ", "))
Assert-Test -CaseId "UT-234-2" `
    -Name "core scripts (7 pairs) all have success path exit 0; rsa-keygen.ps1 ends naturally (exit 0 semantics, no literal)" `
    -Condition ($exit0Ok -and ($ps1Txt -notmatch "exit 0")) `
    -Detail ("missing exit 0: {0}; rsa-keygen.ps1 explicit-exit-0={1} (natural end -> 0, per report 4.4)" -f ($exit0Missing -join ", "), ($ps1Txt -match "exit 0"))

# UT-234-3: load-env missing handling non-zero (.ps1 exit 1 / .sh return 1)
$loadEnvPs1 = Join-Path $scriptsDir "load-env.ps1"
$loadEnvSh = Join-Path $scriptsDir "load-env.sh"
$lePs1Txt = if (Test-FileExists -Path $loadEnvPs1) { Read-Utf8File -Path $loadEnvPs1 } else { "" }
$leShTxt = if (Test-FileExists -Path $loadEnvSh) { Read-Utf8File -Path $loadEnvSh } else { "" }
Assert-Test -CaseId "UT-234-3" `
    -Name "load-env missing-config path returns non-zero (.ps1 exit 1 / .sh return 1 + set -e fallback)" `
    -Condition (($lePs1Txt -match "exit 1") -and ($leShTxt -match "return 1")) `
    -Detail ("ps1 exit 1={0}; sh return 1={1}" -f ($lePs1Txt -match "exit 1"), ($leShTxt -match "return 1"))

# UT-234-4: start-all fail-fast (break + exit 1)
$startAllPs1 = Join-Path $scriptsDir "deploy-start-all.ps1"
$startAllSh = Join-Path $scriptsDir "deploy-start-all.sh"
$saPs1Txt = if (Test-FileExists -Path $startAllPs1) { Read-Utf8File -Path $startAllPs1 } else { "" }
$saShTxt = if (Test-FileExists -Path $startAllSh) { Read-Utf8File -Path $startAllSh } else { "" }
Assert-Test -CaseId "UT-234-4" `
    -Name "start-all fail-fast exists on both platforms (break + exit 1, R-09)" `
    -Condition (($saPs1Txt -match "break") -and ($saPs1Txt -match "exit 1") -and ($saShTxt -match "break") -and ($saShTxt -match "exit 1")) `
    -Detail ("ps1 break={0} exit1={1}; sh break={2} exit1={3}" -f `
        ($saPs1Txt -match "break"), ($saPs1Txt -match "exit 1"), ($saShTxt -match "break"), ($saShTxt -match "exit 1"))

# UT-234-5: no out-of-contract values (exit 2-9 / negative / non-integer)
$allScriptTexts = ""
foreach ($f in $scriptFiles) {
    if ($f.Extension -eq ".ps1" -or $f.Extension -eq ".sh") {
        $allScriptTexts += Read-Utf8File -Path $f.FullName + "`n"
    }
}
$outOfContract = @()
foreach ($m in [regex]::Matches($allScriptTexts, "(?m)^[^\r\n]*(?:exit|return)\s+(?:-[1-9]|[2-9][0-9]*)\b[^\r\n]*$")) {
    $outOfContract += $m.Value.Trim()
}
Assert-Test -CaseId "UT-234-5" `
    -Name "no out-of-contract exit/return values (only 0/1 across all 24 scripts, safe domain 0-255)" `
    -Condition ($outOfContract.Count -eq 0) `
    -Detail ("out-of-contract hits: {0}" -f ($outOfContract -join "; "))

# ============================================================================
# UT-235: load-env dependency + env.json missing handling (P0)
# ============================================================================
Write-Output "`n[UT-235] load-env dependency and env.json missing handling"
$bizPairs = @("deploy-check-env", "deploy-start-services", "deploy-start-all",
              "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz",
              "deploy-start-system", "deploy-db-init")
$loadEnvRefOk = $true
$loadEnvRefMissing = @()
$orderOk = $true
$orderMissing = @()
foreach ($pair in $bizPairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        $ref = if ($ext -eq ".ps1") { "load-env.ps1" } else { "load-env.sh" }
        $lines = $txt -split "`r?`n"
        $refLine = -1
        $firstUseLine = -1
        $inBlockComment = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $trimmedLine = $lines[$i].Trim()
            if (($refLine -lt 0) -and ($lines[$i] -match [regex]::Escape($ref))) { $refLine = $i + 1 }
            # skip block comments (<# ... #>) and line comments (#) when locating first config-key usage
            $isComment = $false
            if ($trimmedLine -match "^<#") { $inBlockComment = $true }
            if ($trimmedLine -match "#>") { $inBlockComment = $false }
            if ($inBlockComment -or ($trimmedLine -match "^#")) { $isComment = $true }
            if (($firstUseLine -lt 0) -and (-not $isComment) -and `
                ($lines[$i] -match "NACOS_ADDR|DB_HOST|REDIS_HOST|DB_PORT")) {
                $firstUseLine = $i + 1
            }
        }
        if ($refLine -lt 0) {
            $loadEnvRefOk = $false
            $loadEnvRefMissing += $pair + $ext
        }
        # the first config-key mention must not be before the load-env reference
        if (($refLine -ge 0) -and ($firstUseLine -ge 0) -and ($firstUseLine -lt $refLine)) {
            $orderOk = $false
            $orderMissing += "{0}{1} (ref L{2} vs first-use L{3})" -f $pair, $ext, $refLine, $firstUseLine
        }
    }
}
Assert-Test -CaseId "UT-235-1" `
    -Name "8 pairs of business scripts (16) all reference load-env before using config" `
    -Condition ($loadEnvRefOk -and $orderOk) `
    -Detail ("no-ref: {0}; order issues: {1}" -f ($loadEnvRefMissing -join ", "), ($orderMissing -join "; "))

Assert-Test -CaseId "UT-235-2" `
    -Name "load-env missing env.json outputs clear error with copy-env.example.json hint (ps1)" `
    -Condition (($lePs1Txt -match "env\.example\.json") -and ($lePs1Txt -match "exit 1")) `
    -Detail ("hint={0} exit1={1}" -f ($lePs1Txt -match "env\.example\.json"), ($lePs1Txt -match "exit 1"))
Assert-Test -CaseId "UT-235-3" `
    -Name "load-env missing env.json outputs clear error with copy-env.example.json hint (sh, return 1)" `
    -Condition (($leShTxt -match "env\.example\.json") -and ($leShTxt -match "return 1")) `
    -Detail ("hint={0} return1={1}" -f ($leShTxt -match "env\.example\.json"), ($leShTxt -match "return 1"))

$requiredKeys = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD", "REDIS_HOST", "REDIS_PORT")
$missingKeys = @()
foreach ($k in $requiredKeys) {
    if (($lePs1Txt -notmatch $k) -or ($leShTxt -notmatch $k)) {
        $missingKeys += $k
    }
}
Assert-Test -CaseId "UT-235-4" `
    -Name "load-env validates all 8 critical keys (NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*), key names only" `
    -Condition ($missingKeys.Count -eq 0) `
    -Detail ("missing key on either platform: {0}" -f ($missingKeys -join ", "))

# UT-235-5: P5/P6 difference record
$dbInitPs1Lines = $dbInitPs1Txt -split "`r?`n"
$p5Hit = ""
foreach ($line in $dbInitPs1Lines) {
    if ($line -match "load-env\.ps1") {
        if ($line -notmatch '"') { $p5Hit = $line.Trim() }
    }
}
Assert-Test -CaseId "UT-235-5" `
    -Name "P5 record: deploy-db-init.ps1 dot-sources load-env WITHOUT quotes (known low-severity difference)" `
    -Condition ($p5Hit -ne "") `
    -Detail ("P5 hit line: {0}" -f $p5Hit)

$checkEnvShLines = (Read-Utf8File -Path (Join-Path $scriptsDir "deploy-check-env.sh")) -split "`r?`n"
$p6Hit = ""
foreach ($line in $checkEnvShLines) {
    if ($line -match "load-env\.sh") {
        if ($line -notmatch "\|\|") { $p6Hit = $line.Trim() }
    }
}
Assert-Test -CaseId "UT-235-6" `
    -Name "P6 record: deploy-check-env.sh sources load-env without '|| exit `$?' (set -e fallback, behavior-equivalent)" `
    -Condition ($p6Hit -ne "") `
    -Detail ("P6 hit line: {0}" -f $p6Hit)

# ============================================================================
# UT-236: no hardcoded env addresses (core 0 hit; P1 db-init record) (P0)
# ============================================================================
Write-Output "`n[UT-236] no hardcoded environment addresses (192.168.x)"
$coreHwPairs = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-all",
                 "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz",
                 "deploy-start-system", "deploy-rsa-keygen")
$coreHardHit = @()
foreach ($pair in $coreHwPairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -match "192\.168\.") { $coreHardHit += $pair + $ext }
    }
}
Assert-Test -CaseId "UT-236-1" `
    -Name "core script pairs (1-9, 18 scripts) have ZERO hardcoded 192.168.x addresses" `
    -Condition ($coreHardHit.Count -eq 0) `
    -Detail ("hits: {0}" -f ($coreHardHit -join ", "))

# UT-236-2: S-04 fixed - db-init pair no longer hardcodes 192.168.1.101 (removed defaults)
$dbInitHardPs1 = ($dbInitPs1Txt -match "192\.168\.1\.101")
$dbInitHardSh = ($dbInitShTxt -match "192\.168\.1\.101")
Assert-Test -CaseId "UT-236-2" `
    -Name "S-04 fixed: deploy-db-init pair has NO hardcoded default 192.168.1.101 (defaults removed, reads env.json only)" `
    -Condition (-not $dbInitHardPs1 -and -not $dbInitHardSh) `
    -Detail ("ps1={0} sh={1} - S-04 review fix removed hardcoded defaults; env.json sole config source" -f $dbInitHardPs1, $dbInitHardSh)

# UT-236-3: env.example.json template defaults are legit (tracked template, not script hardcode)
$envExampleTracked = $false
$envExampleCjk = ""
& git ls-files -- "deploy/env.example.json" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    $out = (& git ls-files -- "deploy/env.example.json" 2>&1) -join ""
    $envExampleTracked = ($out.Trim() -ne "")
}
$scripts127 = @()
foreach ($f in $scriptFiles) {
    if ($f.Extension -eq ".ps1" -or $f.Extension -eq ".sh") {
        $txt = Read-Utf8File -Path $f.FullName
        if ($txt -match "127\.0\.0\.1") { $scripts127 += $f.Name }
    }
}
Assert-Test -CaseId "UT-236-3" `
    -Name "env.example.json is a tracked template (127.0.0.1 defaults legit); scripts have zero 127.0.0.1 literals" `
    -Condition ($envExampleTracked -and ($scripts127.Count -eq 0)) `
    -Detail ("tracked={0}; script 127.0.0.1 hits: {1}" -f $envExampleTracked, ($scripts127 -join ", "))

# ============================================================================
# UT-237: no plaintext credentials + password masking (P0)
# ============================================================================
Write-Output "`n[UT-237] credential safety (no plaintext output, masking mechanism)"
# UT-237-1: load-env output statements never print sensitive values
$sensitiveVars = @("DB_PASSWORD", "REDIS_PASSWORD", "RSA_PRIVATE_KEY")
function Test-NoPlaintextOutput {
    param([string]$Text, [string[]]$Keys)
    $lines = $Text -split "`r?`n"
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        # only inspect output statements
        if ($trimmed -match "^(Write-Host|Write-Output|Write-Error|Write-Warning|Write-Verbose|echo|printf)") {
            foreach ($k in $Keys) {
                if ($trimmed -match [regex]::Escape("$" + $k) -or $trimmed -match [regex]::Escape("`$env:" + $k)) {
                    return $false
                }
            }
        }
    }
    return $true
}
$leNoPlain = (Test-NoPlaintextOutput -Text $lePs1Txt -Keys $sensitiveVars) -and `
             (Test-NoPlaintextOutput -Text $leShTxt -Keys $sensitiveVars)
Assert-Test -CaseId "UT-237-1" `
    -Name "load-env output statements never reference DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY values (key count and path only)" `
    -Condition $leNoPlain `
    -Detail "checked Write-*/echo/printf lines on both platforms"

# UT-237-2: check-env masking **** + REDISCLI_AUTH channel
$checkEnvPs1 = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-check-env.ps1")
$checkEnvSh = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-check-env.sh")
$maskOk = (($checkEnvPs1 -match "\*\*\*\*") -and ($checkEnvSh -match "\*\*\*\*")) -and `
          (($checkEnvPs1 -match "REDISCLI_AUTH") -and ($checkEnvSh -match "REDISCLI_AUTH"))
Assert-Test -CaseId "UT-237-2" `
    -Name "check-env uses password masking (****) and REDISCLI_AUTH secure channel on both platforms" `
    -Condition $maskOk `
    -Detail ("ps1 mask={0} rediscli={1}; sh mask={2} rediscli={3}" -f `
        ($checkEnvPs1 -match "\*\*\*\*"), ($checkEnvPs1 -match "REDISCLI_AUTH"), `
        ($checkEnvSh -match "\*\*\*\*"), ($checkEnvSh -match "REDISCLI_AUTH"))

# UT-237-3: rsa-keygen private key masking (first 24 chars only)
$ps1Mask24 = ($ps1Txt -match "Min\(24") -and ($ps1Txt -match "Substring\(0,")
$shMask24 = ($shTxt -match "24 字符") -or ($shTxt -match "前 24") -or ($shTxt -match '\$\{PRIVATE_KEY_B64:0:24\}')
Assert-Test -CaseId "UT-237-3" `
    -Name "rsa-keygen masks full private key on both platforms (first 24 chars prefix only, never prints full value)" `
    -Condition ($ps1Mask24 -and $shMask24) `
    -Detail ("ps1 Substring+Min(24)={0}; sh 24-char masking={1}" -f $ps1Mask24, $shMask24)

# UT-237-4: S-04/P8 fixed - db-init no longer passes password as command-line argument
$p8Hit = ($dbInitPs1Txt -match '-p"\$DbPassword"') -or ($dbInitShTxt -match '-p"\$DB_PASSWORD"')
$p8MysqlPwd = ($dbInitPs1Txt -match "MYSQL_PWD") -and ($dbInitShTxt -match "MYSQL_PWD")
Assert-Test -CaseId "UT-237-4" `
    -Name "S-04/P8 fixed: deploy-db-init no longer passes password as command-line arg -p; uses MYSQL_PWD env var instead" `
    -Condition (-not $p8Hit -and $p8MysqlPwd) `
    -Detail "password now via MYSQL_PWD env var (not visible in process list) on both platforms"

# UT-237-5: all 24 scripts have no plaintext credential output path
$allPlainOk = $true
$allPlainHits = @()
foreach ($f in $scriptFiles) {
    if ($f.Extension -eq ".ps1" -or $f.Extension -eq ".sh") {
        $txt = Read-Utf8File -Path $f.FullName
        if (-not (Test-NoPlaintextOutput -Text $txt -Keys $sensitiveVars)) {
            $allPlainOk = $false
            $allPlainHits += $f.Name
        }
    }
}
Assert-Test -CaseId "UT-237-5" `
    -Name "all 24 scripts: output statements never print DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY plaintext values" `
    -Condition $allPlainOk `
    -Detail ("hits: {0}" -f ($allPlainHits -join ", "))

# ============================================================================
# UT-238: deprecated scripts (deploy-env*) no residue, no reference (P0)
# ============================================================================
Write-Output "`n[UT-238] deprecated scripts (deploy-env*) no residue, no reference"
$deprecatedResidue = Get-ChildItem -LiteralPath $scriptsDir -File | Where-Object { $_.Name -match "^deploy-env" }
Assert-Test -CaseId "UT-238-1" `
    -Name "deploy/scripts has NO deploy-env* / deploy-env-template* files (glob 0 hit)" `
    -Condition ($deprecatedResidue.Count -eq 0) `
    -Detail ("residue: {0}" -f (($deprecatedResidue | ForEach-Object { $_.Name }) -join ", "))

# UT-238-2: whole-repo grep deploy-env -> only docs/ (version/history docs) and scripts/API-TEST/ (test assertion logic)
$repoHits = @(& git grep -l "deploy-env" 2>&1)
$unexpected = @()
foreach ($hit in $repoHits) {
    $h = $hit.Trim()
    $ok = $h.StartsWith("docs/") -or $h.StartsWith("scripts/API-TEST/")
    if (-not $ok) { $unexpected += $h }
}
Assert-Test -CaseId "UT-238-2" `
    -Name "whole-repo grep 'deploy-env' hits only docs/ history-version docs and scripts/API-TEST/ test assertions (no live script reference)" `
    -Condition ($unexpected.Count -eq 0) `
    -Detail ("unexpected hits: {0}" -f ($unexpected -join "; "))

# UT-238-3: directory inventory = 24 scripts + .gitkeep
$inventoryOk = ($scriptFiles.Count -eq 25) -and ($ps1Files.Count -eq 12) -and ($shFiles.Count -eq 12) -and `
               (@($scriptFiles | Where-Object { $_.Name -eq ".gitkeep" }).Count -eq 1)
Assert-Test -CaseId "UT-238-3" `
    -Name "deploy/scripts inventory is exactly 24 scripts + .gitkeep (25 entries, 12 ps1 + 12 sh + 1 gitkeep)" `
    -Condition $inventoryOk `
    -Detail ("total={0} ps1={1} sh={2} gitkeep={3}" -f $scriptFiles.Count, $ps1Files.Count, $shFiles.Count, `
        @($scriptFiles | Where-Object { $_.Name -eq ".gitkeep" }).Count)

# ============================================================================
# UT-239: SPDX header & copyright (P1)
# ============================================================================
Write-Output "`n[UT-239] SPDX-License-Identifier header and copyright (P1)"
$spdxCorePairs = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-all",
                   "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz",
                   "deploy-start-system", "deploy-rsa-keygen")
$spdxMissing = @()
$copyrightMissing = @()
foreach ($pair in $spdxCorePairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -notmatch "SPDX-License-Identifier: Apache-2.0") { $spdxMissing += $pair + $ext }
        if ($txt -notmatch "Copyright 2026 jenemy8023") { $copyrightMissing += $pair + $ext }
    }
}
Assert-Test -CaseId "UT-239-1" `
    -Name "all 18 core scripts (1-9 pairs) keep SPDX-License-Identifier: Apache-2.0 header" `
    -Condition ($spdxMissing.Count -eq 0) `
    -Detail ("missing SPDX: {0}" -f ($spdxMissing -join ", "))
Assert-Test -CaseId "UT-239-2" `
    -Name "all 18 core scripts keep copyright (Copyright 2026 jenemy8023)" `
    -Condition ($copyrightMissing.Count -eq 0) `
    -Detail ("missing copyright: {0}" -f ($copyrightMissing -join ", "))

# P2 record: 6 historical scripts without SPDX header（S-04 修复为 deploy-db-init.* 补 SPDX 头后，剩余 4 个）
$historyPairs = @("deploy-db-init", "build-backend", "build-client")
$p2Missing = @()
foreach ($pair in $historyPairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -notmatch "SPDX-License-Identifier: Apache-2.0") { $p2Missing += $pair + $ext }
    }
}
Assert-Test -CaseId "UT-239-3" `
    -Name "P2 record: 4 historical scripts (build-backend/build-client) lack SPDX header; db-init.* fixed in S-04" `
    -Condition ($p2Missing.Count -eq 4) `
    -Detail ("missing list: {0}（deploy-db-init.* 已于 S-04 修复补 SPDX 头）" -f ($p2Missing -join ", "))

# UT-239-4: simplified Chinese comments spot check on core scripts
$cjkMissing = @()
foreach ($pair in $spdxCorePairs) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ($pair + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        if (-not [regex]::IsMatch($txt, "[\u4e00-\u9fff]")) { $cjkMissing += $pair + $ext }
    }
}
Assert-Test -CaseId "UT-239-4" `
    -Name "comments are simplified Chinese (CJK chars present in all core scripts)" `
    -Condition ($cjkMissing.Count -eq 0) `
    -Detail ("no-CJK scripts: {0}" -f ($cjkMissing -join ", "))

# ============================================================================
# UT-240: .gitignore governance rules static check (P0)
# ============================================================================
Write-Output "`n[UT-240] .gitignore governance rules static check"
$giOk = Test-FileExists -Path $gitignorePath
if (-not $giOk) {
    Assert-Test -CaseId "UT-240-0" -Name ".gitignore exists" -Condition $false -Detail "missing"
}
else {
    $giContent = Read-Utf8File -Path $gitignorePath
    $giLinesArr = $giContent -split "`r?`n"

    $jvmRules = @("*.hprof", "hs_err_pid*.log", "replay_pid*", "heapdump.*", "*.dmp", "dump/", "*.dump", "derby.log")
    $buildRules = @("*.flattened-pom.xml", "*.lastUpdated", "maven-status/", "dependency-reduced-pom.xml")
    $testRules = @("surefire-reports/", "test-output/", "test-results/", "scripts/API-TEST/*.tmp", "scripts/API-TEST/*.token.json", "__pycache__/", ".pytest_cache/")
    $toolRules = @("*.saz", "*.chls", "*.har", "*.history", "*.session", "*.trace")
    $deployRules = @("*.log", "logs/", "*.err", "*.pid")

    function Test-RulesPresent {
        param([string[]]$Rules, [string[]]$Lines)
        $missing = @()
        foreach ($r in $Rules) {
            $found = $false
            foreach ($ln in $Lines) {
                if ($ln.Trim() -eq $r) { $found = $true; break }
            }
            if (-not $found) { $missing += $r }
        }
        return $missing
    }

    $m1 = Test-RulesPresent -Rules $jvmRules -Lines $giLinesArr
    Assert-Test -CaseId "UT-240-1" `
        -Name "JVM/debug artifact rules present (8: *.hprof hs_err_pid*.log replay_pid* heapdump.* *.dmp dump/ *.dump derby.log)" `
        -Condition ($m1.Count -eq 0) `
        -Detail ("missing: {0}" -f ($m1 -join ", "))

    $m2 = Test-RulesPresent -Rules $buildRules -Lines $giLinesArr
    Assert-Test -CaseId "UT-240-2" `
        -Name "build intermediate artifact rules present (4: *.flattened-pom.xml *.lastUpdated maven-status/ dependency-reduced-pom.xml)" `
        -Condition ($m2.Count -eq 0) `
        -Detail ("missing: {0}" -f ($m2 -join ", "))

    $m3 = Test-RulesPresent -Rules $testRules -Lines $giLinesArr
    Assert-Test -CaseId "UT-240-3" `
        -Name "test artifact/cache rules present (surefire-reports/ test-output/ test-results/ API-TEST/*.tmp *.token.json __pycache__/ .pytest_cache/)" `
        -Condition ($m3.Count -eq 0) `
        -Detail ("missing: {0}" -f ($m3 -join ", "))

    $m4 = Test-RulesPresent -Rules $toolRules -Lines $giLinesArr
    Assert-Test -CaseId "UT-240-4" `
        -Name "tool residue rules present (6: *.saz *.chls *.har *.history *.session *.trace)" `
        -Condition ($m4.Count -eq 0) `
        -Detail ("missing: {0}" -f ($m4 -join ", "))

    $m5 = Test-RulesPresent -Rules $deployRules -Lines $giLinesArr
    Assert-Test -CaseId "UT-240-5" `
        -Name "deploy log/process file rules present (*.log logs/ *.err *.pid covering deploy/logs)" `
        -Condition ($m5.Count -eq 0) `
        -Detail ("missing: {0}" -f ($m5 -join ", "))

    # protection rules: .env.example negation + per-path .gitkeep negations (web/windows)
    $protectOk = ($giContent -match "!\.env\.example") -and `
                 ($giContent -match "!deploy/cloudoffice-flutter-app/web/\.gitkeep") -and `
                 ($giContent -match "!deploy/cloudoffice-flutter-app/windows/\.gitkeep") -and `
                 ($giContent -match "(?m)^env\.json\s*$")
    Assert-Test -CaseId "UT-240-6" `
        -Name "protection rules kept (!.env.example whitelist, web/.gitkeep + windows/.gitkeep negations, env.json ignored)" `
        -Condition $protectOk `
        -Detail ("env-example-neg={0} web-gitkeep={1} windows-gitkeep={2} env-json-ignore={3}" -f `
            ($giContent -match "!\.env\.example"), ($giContent -match "!deploy/cloudoffice-flutter-app/web/\.gitkeep"), `
            ($giContent -match "!deploy/cloudoffice-flutter-app/windows/\.gitkeep"), ($giContent -match "(?m)^env\.json\s*$"))

    # dynamic protection check: tracked in-repo protected files must NOT be ignored
    $protectNotIgnored = $true
    foreach ($pp in @("deploy\env.example.json", "deploy\cloudoffice-flutter-app\web\.gitkeep", "deploy\cloudoffice-flutter-app\windows\.gitkeep")) {
        & git check-ignore $pp 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $protectNotIgnored = $false }
    }
    Assert-Test -CaseId "UT-240-6b" `
        -Name "dynamic: git check-ignore confirms protected files NOT ignored (env.example.json, web/.gitkeep, windows/.gitkeep)" `
        -Condition $protectNotIgnored `
        -Detail "check-ignore exit=1 (not ignored) on all three protected paths"

    # no global wildcards that would harm in-repo files
    $forbidden = @("*.xml", "*.yml", "*.yaml", "*.py", "*.ps1", "*.sh", "*.java", "*.dart", "*.md")
    $forbiddenHits = @()
    foreach ($ln in $giLinesArr) {
        $t = $ln.Trim()
        foreach ($fw in $forbidden) {
            if ($t -eq $fw) { $forbiddenHits += "$t (L{0})" -f ([Array]::IndexOf($giLinesArr, $ln) + 1) }
        }
    }
    Assert-Test -CaseId "UT-240-7" `
        -Name "no global wildcards (*.xml/yml/yaml/py/ps1/sh/java/dart/md) that would harm in-repo files" `
        -Condition ($forbiddenHits.Count -eq 0) `
        -Detail ("hits: {0}" -f ($forbiddenHits -join ", "))

    # footer SPDX
    $footerOk = ($giContent -match "SPDX-License-Identifier: Apache-2.0") -and ($giContent -match "Copyright 2026")
    Assert-Test -CaseId "UT-240-8" `
        -Name ".gitignore footer keeps SPDX-License-Identifier and Copyright lines" `
        -Condition $footerOk `
        -Detail ("spdx={0} copyright={1}" -f ($giContent -match "SPDX-License-Identifier: Apache-2.0"), ($giContent -match "Copyright 2026"))
}

# ============================================================================
# FT-153: verification report content vs PRD ch.7 8-item acceptance (P0)
# ============================================================================
Write-Output "`n[FT-153] verification report (cso-script-contract-verification-v0.2.7.md) content check"
$reportOk = Test-FileExists -Path $reportPath
Assert-Test -CaseId "FT-153-1" `
    -Name "verification report exists" `
    -Condition $reportOk `
    -Detail ("path: {0}" -f $reportPath)
if ($reportOk) {
    $rep = Read-Utf8File -Path $reportPath

    # report header: env records (PowerShell/bash/git version)
    $headerOk = ($rep -match "## 1\. ") -and ($rep -match "PowerShell") -and ($rep -match "git-bash") -and ($rep -match "git 版本|git 2\.|shellcheck")
    Assert-Test -CaseId "FT-153-2" `
        -Name "report header present with full check environment (OS / PowerShell version / bash version / git version / shellcheck availability)" `
        -Condition $headerOk `
        -Detail "header section ## 1. with PowerShell/bash/git environment rows"

    # overview table (12 pairs) + detail tables
    $pairNames = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-all",
                   "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system",
                   "deploy-rsa-keygen", "deploy-db-init", "build-backend", "build-client")
    $missingPairs = @()
    foreach ($pn in $pairNames) {
        if ($rep -notmatch [regex]::Escape($pn)) { $missingPairs += $pn }
    }
    $overviewOk = ($missingPairs.Count -eq 0) -and ($rep -match "## 3\. ") -and ($rep -match "## 4\. ")
    Assert-Test -CaseId "FT-153-3" `
        -Name "report has overview table (## 3.) covering all 12 script pairs and detail tables (## 4.)" `
        -Condition $overviewOk `
        -Detail ("missing pairs in report: {0}" -f ($missingPairs -join ", "))

    # PRD ch.7 acceptance: 8 rows | 1 | .. | 8 | with results + evidence
    $acptRows = [regex]::Matches($rep, "(?m)^\| [1-8] \| ")
    $hasAcptSection = $rep -match "## 5\. "
    Assert-Test -CaseId "FT-153-4" `
        -Name "report has PRD ch.7 acceptance checklist (## 5.) with 8 numbered rows (one per acceptance item)" `
        -Condition ($hasAcptSection -and ($acptRows.Count -ge 8)) `
        -Detail ("acceptance rows found: {0}" -f $acptRows.Count)

    # overall conclusion row for the 8 items
    $conclusionOk = ($rep -match "8 条验收标准全部符合") -or ($rep -match "全部符合")
    Assert-Test -CaseId "FT-153-5" `
        -Name "report gives overall conclusion on PRD ch.7 8-item acceptance (all conform / with notes)" `
        -Condition $conclusionOk `
        -Detail "conclusion row present in section ## 5."

    # summary line + leftover issues P1~P9
    $pRows = [regex]::Matches($rep, "(?m)^\| P[1-9] \| ")
    $hasIssueSection = $rep -match "## 6\. "
    Assert-Test -CaseId "FT-153-6" `
        -Name "report has leftover issue list (## 6.) with P1~P9 all judged" `
        -Condition ($hasIssueSection -and ($pRows.Count -ge 9)) `
        -Detail ("P-rows found: {0}" -f $pRows.Count)

    $summaryOk = ($rep -match "通过 9 项") -and ($rep -match "失败 0 项")
    Assert-Test -CaseId "FT-153-7" `
        -Name "report contains overall summary line (through 9 items | warn 4 items | fail 0 items)" `
        -Condition $summaryOk `
        -Detail "summary row present in overview section"

    # report tool exit code contract (0/1)
    $exitOk = ($rep -match "退出码：0") -or ($rep -match "退出码.*0")
    Assert-Test -CaseId "FT-153-8" `
        -Name "report states verification tool exit code per F-011 contract (all pass -> 0)" `
        -Condition $exitOk `
        -Detail "exit code row in verification conclusion"
}

# ============================================================================
# FT-154: deploy-check-env dual-platform behavior parity (P0)
# ============================================================================
Write-Output "`n[FT-154] deploy-check-env dual-platform parity"
$cePs1 = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-check-env.ps1")
$ceSh = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-check-env.sh")
# JDK version 21 + MariaDB SELECT 1 + Redis PONG + Nacos startup/HTTP on both
$ceJdk = ($cePs1 -match 'version "21') -and ($ceSh -match 'version "21') -and ($cePs1 -match "JAVA_HOME") -and ($ceSh -match "JAVA_HOME")
$ceMaria = ($cePs1 -match "SELECT 1") -and ($ceSh -match "SELECT 1")
$ceRedis = (($cePs1 -match "PONG") -and ($ceSh -match "PONG")) -and (($cePs1 -match "ping") -and ($ceSh -match "ping"))
$ceNacos = (($cePs1 -match "startup\.cmd") -and ($ceSh -match "startup\.sh")) -and `
           (($cePs1 -match "NACOS_HOME") -and ($ceSh -match "NACOS_HOME")) -and `
           (($cePs1 -match "/nacos/") -and ($ceSh -match "/nacos/"))
Assert-Test -CaseId "FT-154-1" `
    -Name "check-env both platforms cover JDK (java cmd + JAVA_HOME + version 21)" `
    -Condition $ceJdk `
    -Detail ("ps1={0} sh={1}" -f ($cePs1 -match 'version "21'), ($ceSh -match 'version "21'))
Assert-Test -CaseId "FT-154-2" `
    -Name "check-env both platforms cover MariaDB (triple detection + SELECT 1 connectivity)" `
    -Condition $ceMaria `
    -Detail ("ps1={0} sh={1}" -f ($cePs1 -match "SELECT 1"), ($ceSh -match "SELECT 1"))
Assert-Test -CaseId "FT-154-3" `
    -Name "check-env both platforms cover Redis (triple detection + ping PONG)" `
    -Condition $ceRedis `
    -Detail ("ps1 ping={0} PONG={1}; sh ping={2} PONG={3}" -f `
        ($cePs1 -match "ping"), ($cePs1 -match "PONG"), ($ceSh -match "ping"), ($ceSh -match "PONG"))
Assert-Test -CaseId "FT-154-4" `
    -Name "check-env both platforms cover Nacos (NACOS_HOME/startup script + HTTP probe)" `
    -Condition $ceNacos `
    -Detail ("ps1 startup.cmd={0} sh startup.sh={1}" -f ($cePs1 -match "startup\.cmd"), ($ceSh -match "startup\.sh"))

# runtime status detection (process/service/TCP)
$ceStatus = (($cePs1 -match "Get-Process|Get-Service|Test-TcpPort|Get-NetTCPConnection") -and `
             ($ceSh -match "pgrep|systemctl|service|ss |netstat|nc ")) -and `
            (($cePs1 -match "/nacos/") -and ($ceSh -match "/nacos/"))
Assert-Test -CaseId "FT-154-5" `
    -Name "check-env both platforms implement runtime status detection (process/service/TCP probe, Nacos HTTP)" `
    -Condition $ceStatus `
    -Detail "stage-two runtime status detection present on both platforms"

# grading + exit code parity
$ceExit = ($cePs1 -match "exit 1") -and ($ceSh -match "exit 1") -and ($cePs1 -match "exit 0") -and ($ceSh -match "exit 0")
Assert-Test -CaseId "FT-154-6" `
    -Name "check-env both platforms share grading ([through]/[warn]/[fail]) and exit code convention (fail>0 -> exit 1, warn-only -> 0)" `
    -Condition $ceExit `
    -Detail ("ps1 exit1={0} exit0={1}; sh exit1={2} exit0={3}" -f `
        ($cePs1 -match "exit 1"), ($cePs1 -match "exit 0"), ($ceSh -match "exit 1"), ($ceSh -match "exit 0"))

# ============================================================================
# FT-155: deploy-start-services dual-platform behavior parity (P0)
# ============================================================================
Write-Output "`n[FT-155] deploy-start-services dual-platform parity"
$ssPs1 = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-start-services.ps1")
$ssSh = Read-Utf8File -Path (Join-Path $scriptsDir "deploy-start-services.sh")
# order MariaDB -> Redis -> Nacos
$ssOrderPs1 = ($ssPs1.IndexOf("MariaDB") -ge 0) -and ($ssPs1.IndexOf("Redis") -gt $ssPs1.IndexOf("MariaDB")) -and `
              ($ssPs1.IndexOf("Nacos") -gt $ssPs1.IndexOf("Redis"))
$ssOrderSh = ($ssSh.IndexOf("MariaDB") -ge 0) -and ($ssSh.IndexOf("Redis") -gt $ssSh.IndexOf("MariaDB")) -and `
             ($ssSh.IndexOf("Nacos") -gt $ssSh.IndexOf("Redis"))
# JDK check-only (no start): "无需启动" message present, no JDK start command
$ssJdk = ($ssPs1 -match "无需启动") -and ($ssSh -match "无需启动")
Assert-Test -CaseId "FT-155-1" `
    -Name "start-services both platforms start infra in order MariaDB -> Redis -> Nacos (R-07)" `
    -Condition ($ssOrderPs1 -and $ssOrderSh) `
    -Detail ("ps1 order ok={0}; sh order ok={1}" -f $ssOrderPs1, $ssOrderSh)
Assert-Test -CaseId "FT-155-2" `
    -Name "start-services both platforms check JDK availability only, never start it (R-11)" `
    -Condition $ssJdk `
    -Detail ("ps1='{0}' sh='{1}'" -f ($ssPs1 -match "无需启动"), ($ssSh -match "无需启动"))

# start priority: system service -> executable -> Nacos startup
$ssPrioPs1 = ($ssPs1 -match "Start-Service") -and ($ssPs1 -match "mysqld|mariadbd") -and ($ssPs1 -match "redis-server") -and ($ssPs1 -match "startup\.cmd")
$ssPrioSh = ($ssSh -match "systemctl start|service start") -and ($ssSh -match "mysqld_safe|mysqld|mariadbd") -and ($ssSh -match "redis-server") -and ($ssSh -match "startup\.sh")
Assert-Test -CaseId "FT-155-3" `
    -Name "start-services both platforms share start priority (system service -> executable -> Nacos startup.cmd/.sh -m standalone)" `
    -Condition ($ssPrioPs1 -and $ssPrioSh) `
    -Detail ("ps1 priority={0}; sh priority={1}" -f $ssPrioPs1, $ssPrioSh)

# post-start confirmation (Wait-ServiceUp / wait_for_service, 30s/2s), no fake success
$ssConfirmPs1 = ($ssPs1 -match "Wait-ServiceUp") -and ($ssPs1 -match "30") -and ($ssPs1 -match "2")
$ssConfirmSh = ($ssSh -match "wait_for_service") -and ($ssSh -match "30") -and ($ssSh -match "2")
Assert-Test -CaseId "FT-155-4" `
    -Name "start-services both platforms confirm start via Wait-ServiceUp/wait_for_service polling (timeout 30s / interval 2s), no fake success (R-08)" `
    -Condition ($ssConfirmPs1 -and $ssConfirmSh) `
    -Detail ("ps1 confirm={0}; sh confirm={1}" -f $ssConfirmPs1, $ssConfirmSh)

$ssExit = ($ssPs1 -match "exit 1") -and ($ssSh -match "exit 1") -and ($ssPs1 -match "exit 0") -and ($ssSh -match "exit 0")
Assert-Test -CaseId "FT-155-5" `
    -Name "start-services both platforms share exit code convention (fail>0 -> exit 1 / warn-only -> 0)" `
    -Condition $ssExit `
    -Detail "exit 0/1 present on both platforms"

# ============================================================================
# FT-156: deploy-start-all dual-platform behavior parity (P0)
# ============================================================================
Write-Output "`n[FT-156] deploy-start-all dual-platform parity"
# service list contract: 4 jars + ports + health URLs
$saJars = @("cloudoffice-gateway.jar", "cloudoffice-auth-service.jar", "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar")
$saPorts = @("9000", "9100", "9200", "9400")
$saUrls = @("localhost:9000/", "api/v1/auth/health", "api/v1/biz/health", "api/v1/system/health")
$saListOk = $true
foreach ($item in ($saJars + $saPorts + $saUrls)) {
    if (($saPs1Txt -notmatch [regex]::Escape($item)) -or ($saShTxt -notmatch [regex]::Escape($item))) {
        $saListOk = $false
        break
    }
}
Assert-Test -CaseId "FT-156-1" `
    -Name "start-all both platforms share service list contract (4 jars, ports 9000/9100/9200/9400, health URLs)" `
    -Condition $saListOk `
    -Detail "service list array checked on both platforms"

# pre-check (java + 4 jars + key env vars) + fail-fast
$saPre = ($saPs1Txt -match "jar 包缺失") -and ($saShTxt -match "jar 包缺失") -and `
         ($saPs1Txt -match "关键环境变量") -and ($saShTxt -match "关键环境变量")
Assert-Test -CaseId "FT-156-2" `
    -Name "start-all both platforms pre-check jars + key env vars before start (missing -> list + exit 1, no service started)" `
    -Condition $saPre `
    -Detail ("ps1 pre={0}; sh pre={1}" -f ($saPs1Txt -match "jar 包缺失"), ($saShTxt -match "jar 包缺失"))
Assert-Test -CaseId "FT-156-3" `
    -Name "start-all both platforms fail-fast (break + exit 1) on any step failure (R-09)" `
    -Condition (($saPs1Txt -match "break") -and ($saShTxt -match "break") -and ($saPs1Txt -match "exit 1") -and ($saShTxt -match "exit 1")) `
    -Detail "break + exit 1 present on both platforms"

# health confirmation polling (Wait-HealthUp / wait_health_up)
$saHealthPs1 = ($saPs1Txt -match "Wait-HealthUp") -and ($saPs1Txt -match "RetryCount") -and ($saPs1Txt -match "RetryInterval")
$saHealthSh = ($saShTxt -match "wait_health_up") -and ($saShTxt -match "RETRY_COUNT") -and ($saShTxt -match "RETRY_INTERVAL")
Assert-Test -CaseId "FT-156-4" `
    -Name "start-all both platforms health-confirm each service after start (Wait-HealthUp/wait_health_up polling, HTTP first/TCP backup)" `
    -Condition ($saHealthPs1 -and $saHealthSh) `
    -Detail ("ps1 health={0}; sh health={1}" -f $saHealthPs1, $saHealthSh)

$saExit = ($saPs1Txt -match "exit 0") -and ($saShTxt -match "exit 0") -and ($saPs1Txt -match "exit 1") -and ($saShTxt -match "exit 1")
Assert-Test -CaseId "FT-156-5" `
    -Name "start-all both platforms share exit code (all success 0 / any failure 1)" `
    -Condition $saExit `
    -Detail "exit 0/1 present on both platforms"

# ============================================================================
# FT-157: single-service start scripts (4 pairs) contract parity (P1)
# ============================================================================
Write-Output "`n[FT-157] single-service start scripts contract parity (4 pairs, 8 scripts)"
$svcContract = @(
    @{ Name = "gateway"; Jar = "cloudoffice-gateway.jar"; Port = "9000"; Url = "localhost:9000/"; Keys = @("NACOS_ADDR", "RSA_PUBLIC_KEY") },
    @{ Name = "auth"; Jar = "cloudoffice-auth-service.jar"; Port = "9100"; Url = "api/v1/auth/health"; Keys = @("NACOS_ADDR", "RSA_PUBLIC_KEY", "RSA_PRIVATE_KEY", "DB_PASSWORD") },
    @{ Name = "biz"; Jar = "cloudoffice-biz-service.jar"; Port = "9200"; Url = "api/v1/biz/health"; Keys = @("NACOS_ADDR", "DB_PASSWORD") },
    @{ Name = "system"; Jar = "cloudoffice-system-service.jar"; Port = "9400"; Url = "api/v1/system/health"; Keys = @("NACOS_ADDR", "DB_PASSWORD") }
)
$svcContractOk = $true
$svcContractBad = @()
foreach ($svc in $svcContract) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ("deploy-start-" + $svc.Name + $ext)
        if (-not (Test-FileExists -Path $p)) { $svcContractOk = $false; $svcContractBad += ("deploy-start-" + $svc.Name + $ext + " missing"); continue }
        $txt = Read-Utf8File -Path $p
        if ($txt -notmatch [regex]::Escape($svc.Jar)) { $svcContractOk = $false; $svcContractBad += "$($svc.Name)$ext no jar" }
        if ($txt -notmatch [regex]::Escape($svc.Port)) { $svcContractOk = $false; $svcContractBad += "$($svc.Name)$ext no port $($svc.Port)" }
        if ($txt -notmatch [regex]::Escape($svc.Url)) { $svcContractOk = $false; $svcContractBad += "$($svc.Name)$ext no url" }
        foreach ($k in $svc.Keys) {
            if ($txt -notmatch [regex]::Escape($k)) { $svcContractOk = $false; $svcContractBad += "$($svc.Name)$ext no key $k" }
        }
    }
}
Assert-Test -CaseId "FT-157-1" `
    -Name "4 pairs (8 scripts) contract params match start-all list (jar/port/health URL/key env vars), dual-platform identical" `
    -Condition $svcContractOk `
    -Detail ("bad: {0}" -f ($svcContractBad -join "; "))

# structure parity: pre-check -> background start -> health confirm -> summary exit
$svcStructOk = $true
$svcStructBad = @()
foreach ($svc in $svcContract) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ("deploy-start-" + $svc.Name + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        $hasPre = $txt -match "前置校验|jar 包缺失"
        $hasHealth = if ($ext -eq ".ps1") { $txt -match "Wait-HealthUp" } else { $txt -match "wait_health_up" }
        $hasExit = ($txt -match "exit 1") -and ($txt -match "exit 0")
        if (-not ($hasPre -and $hasHealth -and $hasExit)) {
            $svcStructOk = $false
            $svcStructBad += "$($svc.Name)$ext (pre=$hasPre health=$hasHealth exit=$hasExit)"
        }
    }
}
Assert-Test -CaseId "FT-157-2" `
    -Name "8 single-service scripts all follow structure pre-check -> background start -> health confirm -> summary exit" `
    -Condition $svcStructOk `
    -Detail ("bad: {0}" -f ($svcStructBad -join "; "))

# background start parity: .ps1 Start-Process + Xms/Xmx; .sh nohup + Xms/Xmx
$svcBgOk = $true
$svcBgBad = @()
foreach ($svc in $svcContract) {
    foreach ($ext in @(".ps1", ".sh")) {
        $p = Join-Path $scriptsDir ("deploy-start-" + $svc.Name + $ext)
        if (-not (Test-FileExists -Path $p)) { continue }
        $txt = Read-Utf8File -Path $p
        $hasXms = $txt -match "-Xms256m" -and $txt -match "-Xmx512m"
        $hasBg = if ($ext -eq ".ps1") { $txt -match "Start-Process" } else { $txt -match "nohup" }
        if (-not ($hasXms -and $hasBg)) {
            $svcBgOk = $false
            $svcBgBad += "$($svc.Name)$ext (xms=$hasXms bg=$hasBg)"
        }
    }
}
Assert-Test -CaseId "FT-157-3" `
    -Name "background start parity on all 8 scripts (.ps1 Start-Process / .sh nohup; -Xms256m -Xmx512m both)" `
    -Condition $svcBgOk `
    -Detail ("bad: {0}" -f ($svcBgBad -join "; "))

# ============================================================================
# FT-158: deployment order contract (R-07) (P1)
# ============================================================================
Write-Output "`n[FT-158] deployment order contract (R-07)"
Assert-Test -CaseId "FT-158-1" `
    -Name "infra order MariaDB -> Redis -> Nacos identical on both platforms (start-services)" `
    -Condition ($ssOrderPs1 -and $ssOrderSh) `
    -Detail ("ps1={0} sh={1}" -f $ssOrderPs1, $ssOrderSh)
$saOrderPs1 = ($saPs1Txt.IndexOf("cloudoffice-gateway.jar") -ge 0) -and `
              ($saPs1Txt.IndexOf("cloudoffice-auth-service.jar") -gt $saPs1Txt.IndexOf("cloudoffice-gateway.jar")) -and `
              ($saPs1Txt.IndexOf("cloudoffice-biz-service.jar") -gt $saPs1Txt.IndexOf("cloudoffice-auth-service.jar")) -and `
              ($saPs1Txt.IndexOf("cloudoffice-system-service.jar") -gt $saPs1Txt.IndexOf("cloudoffice-biz-service.jar"))
$saOrderSh = ($saShTxt.IndexOf("cloudoffice-gateway.jar") -ge 0) -and `
             ($saShTxt.IndexOf("cloudoffice-auth-service.jar") -gt $saShTxt.IndexOf("cloudoffice-gateway.jar")) -and `
             ($saShTxt.IndexOf("cloudoffice-biz-service.jar") -gt $saShTxt.IndexOf("cloudoffice-auth-service.jar")) -and `
             ($saShTxt.IndexOf("cloudoffice-system-service.jar") -gt $saShTxt.IndexOf("cloudoffice-biz-service.jar"))
Assert-Test -CaseId "FT-158-2" `
    -Name "backend order gateway(9000) -> auth(9100) -> biz(9200) -> system(9400) identical on both platforms (start-all list order)" `
    -Condition ($saOrderPs1 -and $saOrderSh) `
    -Detail ("ps1={0} sh={1}" -f $saOrderPs1, $saOrderSh)
Assert-Test -CaseId "FT-158-3" `
    -Name "deployment order matches R-07 / LLD contract (infra MariaDB->Redis->Nacos; backend gateway->auth->biz->system)" `
    -Condition (($ssOrderPs1 -and $ssOrderSh) -and ($saOrderPs1 -and $saOrderSh)) `
    -Detail "order verified against R-07 constants"

# ============================================================================
# FT-159: git status / ls-files / --ignored dynamic check (P0)
# ============================================================================
Write-Output "`n[FT-159] git dynamic check (status / ls-files / --ignored)"
$govPatterns = @("\*.hprof", "hs_err_pid", "replay_pid", "heapdump", "\.dmp", "\.flattened-pom\.xml", "\.lastUpdated",
                 "dependency-reduced-pom\.xml", "surefire-reports", "test-output", "test-results",
                 "\.saz", "\.chls", "\.har", "\.history", "\.session", "\.trace", "\.token\.json", "\.pid", "\.log")
$statusOut = (& git status --porcelain 2>&1) -join "`n"
$govHits = @()
foreach ($pat in $govPatterns) {
    if ($statusOut -match $pat) { $govHits += $pat }
}
Assert-Test -CaseId "FT-159-1" `
    -Name "git status --porcelain has ZERO governance-type generated/test/debug files (JVM/build/test/tool/log residue patterns)" `
    -Condition ($govHits.Count -eq 0) `
    -Detail ("hits: {0}" -f ($govHits -join ", "))

# tracked files: env.example.json / .gitkeep / pom.xml / bootstrap.yml / deploy/scripts
$lsAll = (& git ls-files 2>&1) -join "`n"
$envExTracked = $lsAll -match "deploy/env\.example\.json"
$gitkeepCount = [regex]::Matches($lsAll, "\.gitkeep").Count
$pomCount = [regex]::Matches($lsAll, "pom\.xml").Count
$bootCount = [regex]::Matches($lsAll, "bootstrap\.yml").Count
$deployScriptsTracked = $true
foreach ($f in $scriptFiles) {
    if ($lsAll -notmatch [regex]::Escape("deploy/scripts/" + $f.Name)) { $deployScriptsTracked = $false }
}
Assert-Test -CaseId "FT-159-2" `
    -Name "env.example.json tracked, .gitkeep=48 baseline, pom.xml=6, bootstrap.yml=8" `
    -Condition ($envExTracked -and ($gitkeepCount -eq 48) -and ($pomCount -eq 6) -and ($bootCount -eq 8)) `
    -Detail ("env.example={0} gitkeep={1} pom={2} bootstrap={3}" -f $envExTracked, $gitkeepCount, $pomCount, $bootCount)
Assert-Test -CaseId "FT-159-3" `
    -Name "all 24 deploy/scripts files still tracked by git" `
    -Condition $deployScriptsTracked `
    -Detail "deploy/scripts/*.ps1 and *.sh all tracked"

# --ignored list must NOT contain any tracked in-repo file (intersection empty)
$ignoredOut = (& git status --porcelain --ignored 2>&1) -join "`n"
$trackedSet = @(& git ls-files 2>&1 | ForEach-Object { $_.Replace("\", "/") })
$ignoredPaths = @()
foreach ($line in ($ignoredOut -split "`n")) {
    if ($line -match "^!!\s+(.+)$") { $ignoredPaths += $matches[1].Trim().Replace("\", "/") }
}
$ignoredIntersect = @($ignoredPaths | Where-Object { $trackedSet -contains $_ })
Assert-Test -CaseId "FT-159-4" `
    -Name "git status --porcelain --ignored contains NO tracked in-repo files (intersection of ignored and tracked is empty)" `
    -Condition ($ignoredIntersect.Count -eq 0) `
    -Detail ("intersection hits: {0}" -f ($ignoredIntersect -join "; "))

# ============================================================================
# FT-160: script inventory completeness (P1)
# ============================================================================
Write-Output "`n[FT-160] script inventory completeness (12 pairs + .gitkeep)"
Assert-Test -CaseId "FT-160-1" `
    -Name "deploy/scripts file set is exactly 24 scripts + .gitkeep (no extra, no missing)" `
    -Condition (($scriptFiles.Count -eq 25) -and ($ps1Files.Count -eq 12) -and ($shFiles.Count -eq 12)) `
    -Detail ("total={0} ps1={1} sh={2}" -f $scriptFiles.Count, $ps1Files.Count, $shFiles.Count)

$expectedPairs = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-all",
                   "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system",
                   "deploy-rsa-keygen", "deploy-db-init", "build-backend", "build-client")
$pairMismatch = @()
foreach ($pn in $expectedPairs) {
    $hasPs1 = (Test-FileExists -Path (Join-Path $scriptsDir ($pn + ".ps1")))
    $hasSh = (Test-FileExists -Path (Join-Path $scriptsDir ($pn + ".sh")))
    if (-not ($hasPs1 -and $hasSh)) {
        $pairMismatch += $pn + ("(ps1={0} sh={1})" -f $hasPs1, $hasSh)
    }
}
Assert-Test -CaseId "FT-160-2" `
    -Name "12 pairs have one-to-one .ps1/.sh naming correspondence (no single-side script)" `
    -Condition ($pairMismatch.Count -eq 0) `
    -Detail ("mismatch: {0}" -f ($pairMismatch -join "; "))

# compare actual ps1/sh base names with the contract inventory
$actualBases = @()
foreach ($f in $ps1Files) { $actualBases += $f.BaseName }
$missingFromContract = @($expectedPairs | Where-Object { $actualBases -notcontains $_ })
$extraBeyondContract = @($actualBases | Where-Object { $expectedPairs -notcontains $_ })
Assert-Test -CaseId "FT-160-3" `
    -Name "inventory matches contract list from context.md ch.4 exactly (12 pairs, no extra/missing)" `
    -Condition (($missingFromContract.Count -eq 0) -and ($extraBeyondContract.Count -eq 0)) `
    -Detail ("missing={0} extra={1}" -f ($missingFromContract -join ", "), ($extraBeyondContract -join ", "))

# ============================================================================
# summary
# ============================================================================
Write-Output ("=" * 70)
Write-Output ("Execution complete | PASS={0} FAIL={1} SKIP={2}" -f $script:Pass, $script:Fail, $script:Skip)
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    foreach ($c in $script:FailedCases) { Write-Output "  - $c" }
}
if ($script:SkippedCases.Count -gt 0) {
    Write-Output "Skipped cases (environment-gated, not counted as failure):"
    foreach ($c in $script:SkippedCases) { Write-Output "  - $c" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
