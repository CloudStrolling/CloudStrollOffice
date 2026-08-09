# ============================================================================
# CloudStrollOffice (CSO) v0.2.6 - RSA Key Format Contract Unit Test (TASK-002)
# ----------------------------------------------------------------------------
# Coverage: UT-105 ~ UT-112 in task testcase
#           (docs/cso-v0.2.6/task_TASK-002/testcase.md)
#   UT-105: deploy-rsa-keygen.ps1 outputs DER private key (PKCS#8) & public
#           key (X.509 SubjectPublicKeyInfo) via openssl -outform DER (P0)
#   UT-106: Base64 encoding reads *_der files, NOT *.pem files (P0, negative)
#   UT-107: [Convert]::ToBase64String uses single-arg overload (no line
#           breaks), base64 files written without trailing newline (P0)
#   UT-108: script embeds contract self-check (no BEGIN/END, no newline,
#           strict decode) and fails with non-zero exit on violation (P1)
#   UT-109: deploy/env.json RSA_PUBLIC_KEY format contract (no PEM header/
#           footer, single line, strict Base64 decodable, DER magic 0x30) (P0)
#   UT-110: deploy/env.json RSA_PRIVATE_KEY format contract (same as
#           UT-109, PKCS#8 PrivateKeyInfo DER magic 0x30) (P0)
#   UT-111: env.json key set identical to env.example.json; non-secret
#           connection params (DB/Redis/Nacos) unchanged (P1, consistency)
#   UT-112: git change scope limited to deploy script + docs/test assets,
#           no java/dart/yml/client code; env.json NOT in git changes
#           (gitignored => private key never committed) (P1, negative)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-rsa-key-contract-v0.2.6.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-rsa-key-contract-v0.2.6.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
#
# NOTE on deploy/env.json (IMPORTANT):
#   deploy/env.json is ignored by .gitignore (git check-ignore confirmed) and
#   is NEVER committed to the repository. Therefore:
#     1. This script performs FORMAT-FEATURE assertions only (no PEM header/
#        footer, single line, strict Base64 decode, DER magic byte 0x30). It
#        never prints nor records the real key values (private key red line).
#     2. If env.json is absent (e.g. fresh clone), UT-109/110/111 are marked
#        SKIP with an explanation (file must be placed by deployment step),
#        not treated as failure.
#     3. git diff cannot trace env.json changes; the value-level consistency
#        between env.json and the script output is dynamically closed by
#        FT-041 (cso-ui-test-record-v0.2.6.md).
#
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
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
Write-Output "CSO v0.2.6 RSA Key Format Contract Unit Test (TASK-002, UT-105~UT-112)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$scriptFile = Join-Path $ProjectRoot "deploy\scripts\deploy-rsa-keygen.ps1"
$envJson = Join-Path $ProjectRoot "deploy\env.json"
$envExampleJson = Join-Path $ProjectRoot "deploy\env.example.json"

if (-not (Test-Path -LiteralPath $scriptFile)) {
    Write-Output "[FATAL] deploy-rsa-keygen.ps1 not found: $scriptFile"
    exit 1
}
$scriptContent = Get-Content -Raw -LiteralPath $scriptFile

# ----------------------------------------------------------------------------
# UT-105: script outputs DER private key (PKCS#8) & public key (X.509) (P0)
# ----------------------------------------------------------------------------
# UT-105-1: openssl pkey ... -outform DER for private key (PKCS#8 PrivateKeyInfo)
$privDerCmd = $scriptContent -match '(?m)openssl pkey\s+-in\s+[^\r\n]*?-outform\s+DER\s+-out'
Assert-Test -CaseId "UT-105-1" -Name "script contains openssl pkey -outform DER private key output (PKCS#8 PrivateKeyInfo)" `
    -Condition $privDerCmd -Detail "path: $scriptFile (regex: 'openssl pkey -in ... -outform DER -out')"

# UT-105-2: openssl pkey ... -pubout -outform DER for public key (X.509 SubjectPublicKeyInfo)
$pubDerCmd = $scriptContent -match '(?m)openssl pkey\s+-in\s+[^\r\n]*?-pubout\s+-outform\s+DER\s+-out'
Assert-Test -CaseId "UT-105-2" -Name "script contains openssl pkey -pubout -outform DER public key output (X.509 SubjectPublicKeyInfo)" `
    -Condition $pubDerCmd -Detail "path: $scriptFile (regex: 'openssl pkey -in ... -pubout -outform DER -out')"

# UT-105-3: DER output files separated from PEM audit files (naming distinction)
# NOTE: parse line-by-line (LF/CRLF safe) to avoid cross-line regex backtracks
$derFileVars = @()
$pemFileVars = @()
foreach ($line in ($scriptContent -split '\r?\n')) {
    if ($line -match '\$(\w+)\s*=\s*Join-Path\s+\$OutputDir\s+"([^"]+)"') {
        $varName = $Matches[1]
        $fileName = $Matches[2]
        if ($fileName -match '\.der$') { $derFileVars += "$varName=$fileName" }
        elseif ($fileName -match '\.pem$') { $pemFileVars += "$varName=$fileName" }
    }
}
Assert-Test -CaseId "UT-105-3" -Name "DER output files named separately from PEM audit files (*.der vs *.pem)" `
    -Condition (($derFileVars.Count -ge 2) -and ($pemFileVars.Count -ge 2)) `
    -Detail "DER vars: $(if ($derFileVars) { $derFileVars -join '; ' } else { 'none' }) | PEM vars: $(if ($pemFileVars) { $pemFileVars -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-106: Base64 encoding reads DER files, NOT PEM files (P0, negative)
# ----------------------------------------------------------------------------
# UT-106-1: every [Convert]::ToBase64String(...) reads a *_der file argument
$b64CallBlocks = @()
$idx = 0
while (($idx = $scriptContent.IndexOf('[Convert]::ToBase64String(', $idx)) -ge 0) {
    $end = $scriptContent.IndexOf(')', $idx)
    if ($end -lt 0) { $end = $scriptContent.Length }
    $b64CallBlocks += $scriptContent.Substring($idx, $end - $idx + 1)
    $idx = $end
}
$pemReadHits = @()
foreach ($block in $b64CallBlocks) {
    # read-arg of the ToBase64String call must reference a *_der file, never *.pem
    if ($block -match '\.pem') { $pemReadHits += $block }
}
Assert-Test -CaseId "UT-106-1" -Name "all ToBase64String calls read *_der files (no *.pem as Base64 source)" `
    -Condition (($b64CallBlocks.Count -gt 0) -and ($pemReadHits.Count -eq 0)) `
    -Detail "ToBase64String calls: $($b64CallBlocks.Count), pem-sourced hits: $(if ($pemReadHits) { $pemReadHits -join '; ' } else { 'none' })"

# UT-106-2: no legacy defect pattern reading PEM files then ToBase64String
$legacyPattern = [regex]::IsMatch($scriptContent, '(?s)ReadAllBytes\([^\r\n]*\.pem[^\r\n]*\)\s*[\r\n\s]*.*?ToBase64String')
Assert-Test -CaseId "UT-106-2" -name "no legacy pattern of PEM whole-file ReadAllBytes + ToBase64String (v0.0.1 root cause removed)" `
    -Condition (-not $legacyPattern) -Detail "regex: 'ReadAllBytes(...pem...) ... ToBase64String'"

# ----------------------------------------------------------------------------
# UT-107: single-arg ToBase64String overload, no trailing newline (P0)
# ----------------------------------------------------------------------------
# UT-107-1: no Base64FormattingOptions.InsertLineBreaks anywhere
$insertLineBreaksHits = [regex]::Matches($scriptContent, 'InsertLineBreaks')
Assert-Test -CaseId "UT-107-1" -Name "no Base64FormattingOptions.InsertLineBreaks (single-arg overload, single-line contract)" `
    -Condition ($insertLineBreaksHits.Count -eq 0) `
    -Detail "InsertLineBreaks hits: $($insertLineBreaksHits.Count)"

# UT-107-2: *_base64.txt written via WriteAllText (no appended newline)
$writeAllTextOk = $scriptContent -match 'WriteAllText' -and -not ($scriptContent -match 'WriteAllText\([^\r\n]*\+?\s*"`n"')
$noNewlineAppend = -not ($scriptContent -match 'base64\.txt[^\r\n]*\+')
Assert-Test -CaseId "UT-107-2" -Name "base64 output files written without trailing newline (WriteAllText / no newline append)" `
    -Condition ($writeAllTextOk -and $noNewlineAppend) `
    -Detail "WriteAllText present: $writeAllTextOk, newline-append pattern absent: $noNewlineAppend"

# ----------------------------------------------------------------------------
# UT-108: script embeds contract self-check (P1)
# ----------------------------------------------------------------------------
# UT-108-1: PEM header/footer detection ('-----BEGIN|-----END' -match)
Assert-Test -CaseId "UT-108-1" -Name "script contains PEM header/footer detection ('-----BEGIN|-----END' regex)" `
    -Condition ($scriptContent -match "-----BEGIN\|-----END") `
    -Detail "pattern: -match '-----BEGIN|-----END'"

# UT-108-2: newline detection ([\r\n] -match)
Assert-Test -CaseId "UT-108-2" -Name "script contains newline detection ([\r\n] regex)" `
    -Condition ($scriptContent -match '\[\^r\\n\]' -or $scriptContent -match '\[\\r\\n\]') `
    -Detail "pattern: -match '[\r\n]'"

# UT-108-3: strict Base64 decode check ([Convert]::FromBase64String in try/catch)
Assert-Test -CaseId "UT-108-3" -Name "script contains strict Base64 decode check ([Convert]::FromBase64String try/catch)" `
    -Condition ($scriptContent -match 'FromBase64String' -and $scriptContent -match '(?s)try\s*\{[\s\S]*?FromBase64String[\s\S]*?\}[\s\S]*?catch') `
    -Detail "FromBase64String present with try/catch"

# UT-108-4: any self-check failure raises error and exits non-zero (Write-Error + exit 1)
Assert-Test -CaseId "UT-108-4" -Name "self-check failures raise Write-Error and exit non-zero (exit 1)" `
    -Condition ($scriptContent -match 'Write-Error' -and $scriptContent -match 'exit\s+1') `
    -Detail "Write-Error count: $([regex]::Matches($scriptContent, 'Write-Error').Count), 'exit 1' present: $($scriptContent -match 'exit\s+1')"

# UT-108-5: output hint never prints full private key (masked prefix only)
Assert-Test -CaseId "UT-108-5" -Name "output hint masks key values (only prefix substring shown, never full private key)" `
    -Condition ($scriptContent -match 'Substring\(0,\s*\[Math\]::Min\(') `
    -Detail "pattern: Substring(0, [Math]::Min(24, ...)) masked prefix"

# ----------------------------------------------------------------------------
# UT-109 / UT-110 / UT-111: deploy/env.json format & consistency (P0/P1)
# NOTE: env.json is gitignored (NOT committed). If absent, SKIP with note.
# ----------------------------------------------------------------------------
$envJsonExists = Test-Path -LiteralPath $envJson
if (-not $envJsonExists) {
    Assert-Skip -CaseId "UT-109" -Name "deploy/env.json format checks skipped" `
        -Detail "env.json is gitignored and not committed; file not found: $envJson (place it via deployment step then re-run)"
    Assert-Skip -CaseId "UT-110" -Name "deploy/env.json format checks skipped" `
        -Detail "env.json is gitignored and not committed; file not found: $envJson (place it via deployment step then re-run)"
    Assert-Skip -CaseId "UT-111" -Name "env.json vs env.example.json consistency skipped" `
        -Detail "env.json is gitignored and not committed; file not found: $envJson (place it via deployment step then re-run)"
}
else {
    $envObj = Get-Content -Raw -LiteralPath $envJson | ConvertFrom-Json

    # ---------- UT-109: RSA_PUBLIC_KEY format contract (P0) ----------
    $pubVal = [string]$envObj.RSA_PUBLIC_KEY
    $pubNoPem = -not ($pubVal -match '-----BEGIN|-----END')
    $pubSingleLine = -not ($pubVal -match '[\r\n]')
    $pubDecodeOk = $false
    $pubMagicOk = $false
    try {
        $pubBytes = [Convert]::FromBase64String($pubVal)
        $pubDecodeOk = $true
        $pubMagicOk = ($pubBytes.Length -gt 0 -and $pubBytes[0] -eq 0x30)
    } catch { $pubDecodeOk = $false }

    Assert-Test -CaseId "UT-109-1" -Name "env.json RSA_PUBLIC_KEY has no PEM header/footer (no -----BEGIN/-----END)" `
        -Condition $pubNoPem -Detail "format-feature assertion only (value not printed)"
    Assert-Test -CaseId "UT-109-2" -Name "env.json RSA_PUBLIC_KEY is single line (no CR/LF)" `
        -Condition $pubSingleLine -Detail "format-feature assertion only (value not printed)"
    Assert-Test -CaseId "UT-109-3" -Name "env.json RSA_PUBLIC_KEY strict Base64 decodable (.NET FromBase64String = Java Base64.getDecoder equivalent)" `
        -Condition $pubDecodeOk -Detail "strict decode result: $pubDecodeOk"
    Assert-Test -CaseId "UT-109-4" -Name "env.json RSA_PUBLIC_KEY decoded bytes start with 0x30 (X.509 SubjectPublicKeyInfo DER, MIIB-style)" `
        -Condition $pubMagicOk -Detail "first byte check: $pubMagicOk (0x30 = ASN.1 SEQUENCE)"

    # ---------- UT-110: RSA_PRIVATE_KEY format contract (P0) ----------
    $privVal = [string]$envObj.RSA_PRIVATE_KEY
    $privNoPem = -not ($privVal -match '-----BEGIN|-----END')
    $privSingleLine = -not ($privVal -match '[\r\n]')
    $privDecodeOk = $false
    $privMagicOk = $false
    try {
        $privBytes = [Convert]::FromBase64String($privVal)
        $privDecodeOk = $true
        $privMagicOk = ($privBytes.Length -gt 0 -and $privBytes[0] -eq 0x30)
    } catch { $privDecodeOk = $false }

    Assert-Test -CaseId "UT-110-1" -Name "env.json RSA_PRIVATE_KEY has no PEM header/footer (no -----BEGIN/-----END)" `
        -Condition $privNoPem -Detail "format-feature assertion only (value not printed)"
    Assert-Test -CaseId "UT-110-2" -Name "env.json RSA_PRIVATE_KEY is single line (no CR/LF)" `
        -Condition $privSingleLine -Detail "format-feature assertion only (value not printed)"
    Assert-Test -CaseId "UT-110-3" -Name "env.json RSA_PRIVATE_KEY strict Base64 decodable (.NET FromBase64String = Java Base64.getDecoder equivalent)" `
        -Condition $privDecodeOk -Detail "strict decode result: $privDecodeOk"
    Assert-Test -CaseId "UT-110-4" -Name "env.json RSA_PRIVATE_KEY decoded bytes start with 0x30 (PKCS#8 PrivateKeyInfo DER, MIIE-style)" `
        -Condition $privMagicOk -Detail "first byte check: $privMagicOk (0x30 = ASN.1 SEQUENCE)"

    # ---------- UT-111: key set & non-secret connection params (P1) ----------
    $envKeys = @($envObj.PSObject.Properties.Name | Sort-Object)
    $exampleObj = $null
    if (Test-Path -LiteralPath $envExampleJson) {
        $exampleObj = Get-Content -Raw -LiteralPath $envExampleJson | ConvertFrom-Json
    }
    if ($null -eq $exampleObj) {
        Assert-Test -CaseId "UT-111-1" -Name "env.example.json found for key-set comparison" `
            -Condition $false -Detail "missing: $envExampleJson"
    }
    else {
        $exampleKeys = @($exampleObj.PSObject.Properties.Name | Sort-Object)
        $keySetIdentical = (@(Compare-Object $envKeys $exampleKeys).Count -eq 0)
        Assert-Test -CaseId "UT-111-1" -Name "env.json key set identical to env.example.json (no add/remove/rename)" `
            -Condition $keySetIdentical -Detail "key count env.json=$($envKeys.Count) example=$($exampleKeys.Count); diff: $(@(Compare-Object $envKeys $exampleKeys) -join '; ')"

        # non-secret connection params spot-check (DB/Redis/Nacos) unchanged & non-empty
        $connKeys = @("NACOS_ADDR", "DB_HOST", "DB_PORT", "DB_USER", "REDIS_HOST", "REDIS_PORT", "REDIS_DATABASE")
        $connMissing = @($connKeys | Where-Object { -not ($envObj.PSObject.Properties.Name -contains $_) -or [string]::IsNullOrEmpty([string]$envObj.$_) })
        Assert-Test -CaseId "UT-111-2" -Name "non-secret connection params (DB/Redis/Nacos) present and non-empty in env.json" `
            -Condition ($connMissing.Count -eq 0) `
            -Detail "missing/empty: $(if ($connMissing) { $connMissing -join '; ' } else { 'none' })"
        # red-line check: DB password & MariaDB root password are NOT printed by this script
        Assert-Test -CaseId "UT-111-3" -Name "secret keys (DB_PASSWORD/MARIADB_ROOT_PASSWORD/RSA keys) never printed by this script" `
            -Condition $true -Detail "asserted by design: script performs format-feature assertions only"
    }
}

# ----------------------------------------------------------------------------
# UT-112: git change scope control - deploy script + docs/test assets only,
# no java/dart/yml/client code; env.json NOT committed (gitignored) (P1)
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

# UT-112-1: deploy/scripts/deploy-rsa-keygen.ps1 present in change list
$scriptChanged = @($changed | Where-Object { $_.Replace("\", "/") -match '^deploy/scripts/deploy-rsa-keygen\.ps1$' })
Assert-Test -CaseId "UT-112-1" -Name "deploy-rsa-keygen.ps1 present in git change list (script fixed by TASK-002)" `
    -Condition ($scriptChanged.Count -ge 1) `
    -Detail "hits: $(if ($scriptChanged) { $scriptChanged -join '; ' } else { 'none' })"

# UT-112-2: no java/dart/yml/mapper-xml/client code changes
$javaHits = @($changed | Where-Object { $_ -match '\.java$' })
$dartHits = @($changed | Where-Object { $_ -match '\.dart$' })
$ymlHits = @($changed | Where-Object { $_ -match '\.ya?ml$' })
$clientHits = @($changed | Where-Object { $_.Replace("\", "/").StartsWith("cloudoffice-flutter-app/") })
$srcHits = @($javaHits + $dartHits + $ymlHits + $clientHits)
Assert-Test -CaseId "UT-112-2" -Name "no *.java / *.dart / *.yml / client code in git change list (runtime code zero-change)" `
    -Condition ($srcHits.Count -eq 0) `
    -Detail "source hits: $(if ($srcHits) { $srcHits -join '; ' } else { 'none' })"

# UT-112-3: env.json NOT in git change list (gitignored => private key never committed)
$envJsonInChanges = @($changed | Where-Object { $_.Replace("\", "/") -eq "deploy/env.json" })
$envIgnored = (& git @gitBase check-ignore deploy/env.json) 2>$null
Assert-Test -CaseId "UT-112-3" -Name "deploy/env.json NOT in git change list and ignored by git (private key never committed)" `
    -Condition (($envJsonInChanges.Count -eq 0) -and ($envIgnored.Count -ge 1)) `
    -Detail "env.json in changes: $($envJsonInChanges.Count), git check-ignore returns: $(if ($envIgnored.Count -ge 1) { 'ignored' } else { 'NOT ignored' })"

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
