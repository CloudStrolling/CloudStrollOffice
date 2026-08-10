# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - RSA Key Contract Alignment Unit & Functional
# Test (TASK-007)
# ----------------------------------------------------------------------------
# Coverage: UT-203 ~ UT-214 + FT-134 ~ FT-144 in task testcase
#           (docs/cso-v0.2.7/task_TASK-007/testcase.md)
#   UT-203: deploy-rsa-keygen.ps1 parses with zero errors (PowerShell Parser)
#   UT-204: deploy-rsa-keygen.sh passes bash -n (or structural fallback when
#           no bash/WSL available on this host)
#   UT-205: .ps1/.sh pair exists & non-empty; 6-file output manifest aligned
#   UT-206: SPDX-License-Identifier + copyright header + version v0.2.7 on
#           both scripts, no stale v0.1.7 (P0)
#   UT-207: generation chain static check (.sh == .ps1): genpkey ->
#           pkey -pubout PEM -> pkcs8 -topk8 -nocrypt DER -> pkey -pubout DER
#           (private key DER MUST use pkcs8 -topk8 -nocrypt, never pkey
#           -outform DER direct; no PEM whole-file base64 legacy pattern)
#   UT-208: single-line Base64 implementation (GNU base64 -w0 / macOS
#           openssl base64 -A branch; encodes .der files; no trailing newline)
#   UT-209: contract self-check static check (no PEM / no newline / strict
#           Base64 / DER structure offsets; fail non-zero)
#   UT-210: output masking (never print full private key; 24-char prefix only)
#   UT-211: Java decode contract static check (auth/gateway RsaKeyConfig
#           Base64.getDecoder + PKCS8EncodedKeySpec/X509EncodedKeySpec;
#           zero Java change via git)
#   UT-212: OpenSSL availability pre-check before generation chain
#   UT-213: key-pair guarantee (public key derived from same private key)
#   UT-214: RSA 2048 generation parameter consistency (.ps1 == .sh,
#           matches auth RsaKeyConfig key-size contract)
#   FT-134: run .ps1 full chain (OpenSSL pre-check -> generate -> self-check
#           -> masked output), exit 0, 6 artifacts non-empty
#   FT-135: .ps1 artifact external contract (no PEM, single line, strict
#           Base64 decode, DER structure offsets)
#   FT-136: .ps1 artifact key-pair verification (SHA256withRSA sign/verify)
#   FT-137: run .sh full chain (SKIP if no bash/WSL on host)
#   FT-138: .sh artifact contract check (SKIP if no .sh artifacts)
#   FT-139: .ps1/.sh output alignment (SKIP for .sh side; .ps1 artifact
#           length scale asserted: priv 1624 chars / pub 392 chars)
#   FT-140: Java end-to-end decode via jshell (strict decode + PKCS#8/X.509
#           KeySpec parse + SHA256withRSA pair; SKIP if no artifact or jshell)
#   FT-141: output masking at runtime (captured .ps1 log contains no full
#           private key value)
#   FT-142: OpenSSL missing scenario (restricted PATH) -> install prompt +
#           non-zero exit + no artifacts
#   FT-143: repeated run idempotency & artifact overwrite (exit 0 twice)
#   FT-144: custom output directory parameter (auto-create, artifacts land)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-rsa-key-contract-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-rsa-key-contract-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure (SKIP is not a failure)
#
# Environment notes:
#   - This host (Windows, PowerShell 5.1): bash.exe is a WSL2 gateway but no
#     distro installed => .sh dynamic assertions are SKIPPED (environment),
#     bash -n degrades to structural check (shebang + set -euo pipefail +
#     if/fi pairing + key functions).
#   - openssl is NOT on PATH; the script locates Git-for-Windows openssl
#     (C:\Program Files\Git\usr\bin\openssl.exe) and injects its directory
#     into PATH for child-process runs. If no openssl found, FT-134/135/136/
#     139/140/141/143/144 dynamic sections degrade to environment SKIP and
#     FT-142 (missing-openssl scenario) is executed dynamically instead.
#   - jshell (JDK 21 Adoptium) is used for FT-140 Java end-to-end contract.
#   - All assertions are ASCII-safe (no Chinese literals in this script to
#     keep PowerShell 5.1 encoding safe); Chinese text checks use [char] code
#     points where required.
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

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 RSA Key Contract Alignment Unit & Functional Test (TASK-007)"
Write-Output "Coverage: UT-203~UT-214, FT-134~FT-144"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$ps1File = Join-Path $ProjectRoot "deploy\scripts\deploy-rsa-keygen.ps1"
$shFile  = Join-Path $ProjectRoot "deploy\scripts\deploy-rsa-keygen.sh"
$authJava = Join-Path $ProjectRoot "cloudoffice-auth-service\src\main\java\org\cloudstrolling\cloudoffice\auth\config\RsaKeyConfig.java"
$gwJava   = Join-Path $ProjectRoot "cloudoffice-gateway\src\main\java\org\cloudstrolling\cloudoffice\gateway\config\RsaKeyConfig.java"

$fatal = $false
foreach ($f in @($ps1File, $shFile, $authJava, $gwJava)) {
    if (-not (Test-Path -LiteralPath $f)) {
        Write-Output "[FATAL] missing file: $f"
        $fatal = $true
    }
}
if ($fatal) { exit 1 }

$ps1Content = Read-Utf8File $ps1File
$shContent  = Read-Utf8File $shFile
$authContent = Read-Utf8File $authJava
$gwContent   = Read-Utf8File $gwJava

# ---------------------------------------------------------------------------
# Environment probes
# ---------------------------------------------------------------------------
# bash availability (WSL2 gateway with no distro fails => bash -n degraded)
$bashAvailable = $false
$bashExe = (Get-Command bash -ErrorAction SilentlyContinue).Source
if ($bashExe) {
    $probeOut = (& $bashExe --version 2>&1 | Out-String)
    if ($LASTEXITCODE -eq 0 -and $probeOut -match "GNU bash") { $bashAvailable = $true }
}

# openssl availability: PATH first, then Git-for-Windows locations
$opensslExe = (Get-Command openssl -ErrorAction SilentlyContinue).Source
$gitOpensslCandidates = @(
    "C:\Program Files\Git\usr\bin\openssl.exe",
    "C:\Program Files\Git\mingw64\bin\openssl.exe"
)
if (-not $opensslExe) {
    foreach ($c in $gitOpensslCandidates) {
        if (Test-Path -LiteralPath $c) { $opensslExe = $c; break }
    }
}
$opensslAvailable = [bool]$opensslExe

# jshell availability (JDK 21 Adoptium)
$jshellExe = (Get-Command jshell -ErrorAction SilentlyContinue).Source
if (-not $jshellExe -and (Test-Path "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\bin\jshell.exe")) {
    $jshellExe = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\bin\jshell.exe"
}
$jshellAvailable = [bool]$jshellExe

Write-Output ("-" * 70)
Write-Output "Environment: bashAvailable=$bashAvailable opensslAvailable=$opensslAvailable (exe=$opensslExe) jshellAvailable=$jshellAvailable"
Write-Output ("-" * 70)

# ===========================================================================
# UT-203: deploy-rsa-keygen.ps1 syntax parse (P0)
# ===========================================================================
$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($ps1File, [ref]$tokens, [ref]$parseErrors)
Assert-Test -CaseId "UT-203-1" -Name ".ps1 parses with zero syntax errors (PowerShell Parser)" `
    -Condition ($parseErrors.Count -eq 0) `
    -Detail "parse errors: $($parseErrors.Count) - $($parseErrors | ForEach-Object { $_.Message } | Select-Object -First 3)"

$ps1HasPreCheck  = $ps1Content -match "openssl\s+version"
$ps1HasGenpkey   = $ps1Content -match "genpkey\s+-algorithm\s+RSA\s+-pkeyopt\s+rsa_keygen_bits:2048"
$ps1HasPkcs8     = $ps1Content -match "pkcs8\s+-topk8\s+-nocrypt"
$ps1HasToB64     = $ps1Content -match "\[Convert\]::ToBase64String"
$ps1HasSelfCheck = $ps1Content -match "FromBase64String"
$ps1HasMask      = $ps1Content -match "Substring\(0,\s*\[Math\]::Min\("
Assert-Test -CaseId "UT-203-2" -Name ".ps1 main flow blocks present (openssl pre-check/genpkey/pkcs8/ToBase64String/self-check/mask)" `
    -Condition ($ps1HasPreCheck -and $ps1HasGenpkey -and $ps1HasPkcs8 -and $ps1HasToB64 -and $ps1HasSelfCheck -and $ps1HasMask) `
    -Detail "preCheck=$ps1HasPreCheck genpkey=$ps1HasGenpkey pkcs8=$ps1HasPkcs8 toB64=$ps1HasToB64 selfCheck=$ps1HasSelfCheck mask=$ps1HasMask"

# ===========================================================================
# UT-204: deploy-rsa-keygen.sh syntax check (bash -n) (P0)
# ===========================================================================
if ($bashAvailable) {
    $bashOut = (& $bashExe -n $shFile 2>&1 | Out-String)
    Assert-Test -CaseId "UT-204-1" -Name ".sh passes bash -n (exit 0, no syntax errors)" `
        -Condition ($LASTEXITCODE -eq 0 -and $bashOut.Trim().Length -eq 0) `
        -Detail "bash -n exit=$LASTEXITCODE output=$bashOut"
}
else {
    Assert-Skip -CaseId "UT-204-1" -Name ".sh bash -n skipped (no usable bash/WSL on host)" `
        -Detail "bash.exe is WSL2 gateway without distro (exit -1); degraded to structural check UT-204-2"
}

# UT-204-2 structural fallback: shebang + set -euo pipefail + if/fi pairing + key functions
$shLines = $shContent -split "\r?\n"
$ifCount = @($shLines | Where-Object { $_.Trim() -match "^if\s" }).Count
$fiCount = @($shLines | Where-Object { $_.Trim() -match "^fi\s*$" -or $_.Trim() -match "; fi\s*$" }).Count
$hasShebang = $shContent.StartsWith("#!")
$hasSetEuo  = $shContent -match "set\s+-euo\s+pipefail"
$keyFuncs = @("print_result", "fail_exit", "b64_encode_file", "b64_encode_stdin", "b64_decode_ok", "byte_at")
$funcHits = @($keyFuncs | Where-Object { $shContent -match ("(?m)^" + $_ + "\(\)") })
$flowBlocks = @("[1/4]", "[2/4]", "[3/4]", "[4/4]")
$flowHits = @($flowBlocks | Where-Object { $shContent.Contains($_) })
Assert-Test -CaseId "UT-204-2" -Name ".sh structural check (shebang + set -euo pipefail + if/fi pairing + key functions + flow blocks)" `
    -Condition ($hasShebang -and $hasSetEuo -and ($ifCount -eq $fiCount -and $ifCount -ge 3) -and ($funcHits.Count -eq $keyFuncs.Count) -and ($flowHits.Count -eq $flowBlocks.Count)) `
    -Detail "shebang=$hasShebang setEuo=$hasSetEuo if=$ifCount fi=$fiCount funcs=$($funcHits -join ',') flows=$($flowHits -join ',')"

$hasFailExit1 = $shContent -match "exit\s+1"
Assert-Test -CaseId "UT-204-3" -Name ".sh failure semantics: set -euo pipefail + fail_exit exits non-zero" `
    -Condition ($hasSetEuo -and $hasFailExit1) `
    -Detail "setEuo=$hasSetEuo failExit1=$hasFailExit1"

# ===========================================================================
# UT-205: dual-platform pair & 6-file output manifest alignment (P1)
# ===========================================================================
$ps1FileInfo = Get-Item -LiteralPath $ps1File
$shFileInfo  = Get-Item -LiteralPath $shFile
Assert-Test -CaseId "UT-205-1" -Name ".ps1/.sh pair exists and non-empty" `
    -Condition (($ps1FileInfo.Length -gt 0) -and ($shFileInfo.Length -gt 0)) `
    -Detail "ps1 bytes=$($ps1FileInfo.Length) sh bytes=$($shFileInfo.Length)"

$manifest = @(
    "private_key.pem", "public_key.pem",
    "private_key.der", "public_key.der",
    "private_key_base64.txt", "public_key_base64.txt"
)
$ps1Missing = @($manifest | Where-Object { $ps1Content -notmatch [regex]::Escape($_) })
$shMissing  = @($manifest | Where-Object { $shContent -notmatch [regex]::Escape($_) })
Assert-Test -CaseId "UT-205-2" -Name "6-file output manifest identical in .ps1 and .sh (pem x2 + der x2 + base64.txt x2)" `
    -Condition (($ps1Missing.Count -eq 0) -and ($shMissing.Count -eq 0)) `
    -Detail "ps1 missing: $(if ($ps1Missing) { $ps1Missing -join ';' } else { 'none' }) | sh missing: $(if ($shMissing) { $shMissing -join ';' } else { 'none' })"

$shHasDer = ($shContent -match "private_key\.der" -and $shContent -match "public_key\.der")
Assert-Test -CaseId "UT-205-3" -Name ".sh declares .der intermediates (P3-2 fix: no longer pem+base64 only)" `
    -Condition $shHasDer -Detail "private_key.der/public_key.der present in .sh"

# ===========================================================================
# UT-206: SPDX header + copyright + version alignment (P0)
# ===========================================================================
# .sh (refactored by TASK-007) MUST have SPDX + copyright + v0.2.7, no v0.1.7
$shSpdx     = $shContent -match "SPDX-License-Identifier:\s*Apache-2\.0"
$shCopyright = $shContent -match "Copyright\s+2026\s+jenemy8023\s+<jenemy8023@163\.com>"
$shVer027   = $shContent -match "v0\.2\.7"
$shOldVer   = $shContent -match "v0\.1\.7"
Assert-Test -CaseId "UT-206-1" -Name ".sh header: SPDX-License-Identifier (Apache-2.0) + copyright + version v0.2.7, no v0.1.7 residue" `
    -Condition ($shSpdx -and $shCopyright -and $shVer027 -and (-not $shOldVer)) `
    -Detail "spdx=$shSpdx copyright=$shCopyright ver027=$shVer027 oldVer=$shOldVer"

# .ps1 (baseline, unchanged by TASK-007): SPDX + copyright are REQUIRED by
# UT-206 testcase expectation (P0). If the coding step kept .ps1 untouched
# without these header lines, this assertion FAILS and must be fed back to
# the coding step (or the expectation confirmed by PM).
$ps1Spdx     = $ps1Content -match "SPDX-License-Identifier"
$ps1Copyright = $ps1Content -match "Copyright"
$ps1Ver027   = $ps1Content -match "v0\.2\.7"
Assert-Test -CaseId "UT-206-2" -Name ".ps1 header: SPDX-License-Identifier (Apache-2.0) + copyright present (P0, testcase expectation)" `
    -Condition ($ps1Spdx -and $ps1Copyright) `
    -Detail "ps1 spdx=$ps1Spdx copyright=$ps1Copyright - if FALSE, .ps1 header needs SPDX/copyright (coding gap to be fed back)"

Assert-Test -CaseId "UT-206-3" -Name ".ps1 version marker v0.2.7 present (dual-platform version aligned)" `
    -Condition $ps1Ver027 `
    -Detail "ps1 ver027=$ps1Ver027 - if FALSE, .ps1 version marker missing (coding gap to be fed back)"

# ===========================================================================
# UT-207: generation chain static check (.sh == .ps1) (P0)
# ===========================================================================
$shGenpkey = $shContent -match "openssl\s+genpkey\s+-algorithm\s+RSA\s+-pkeyopt\s+rsa_keygen_bits:2048\s+-outform\s+PEM"
$ps1Genpkey = $ps1Content -match "openssl\s+genpkey\s+-algorithm\s+RSA\s+-pkeyopt\s+rsa_keygen_bits:2048\s+-outform\s+PEM"
Assert-Test -CaseId "UT-207-1" -Name "step1 genpkey RSA 2048 -outform PEM present in .sh and .ps1 (identical)" `
    -Condition ($shGenpkey -and $ps1Genpkey) -Detail "sh=$shGenpkey ps1=$ps1Genpkey"

$shPubPem = $shContent -match 'openssl\s+pkey\s+-in\s+"\$PRIVATE_KEY_FILE"\s+-pubout\s+-outform\s+PEM'
$ps1PubPem = $ps1Content -match 'openssl\s+pkey\s+-in\s+"\$privateKeyFile"\s+-pubout\s+-outform\s+PEM'
Assert-Test -CaseId "UT-207-2" -Name "step2 pkey -pubout -outform PEM (audit public PEM) in .sh and .ps1" `
    -Condition ($shPubPem -and $ps1PubPem) -Detail "sh=$shPubPem ps1=$ps1PubPem"

# Private key DER MUST be pkcs8 -topk8 -nocrypt -outform DER (PKCS#8 PrivateKeyInfo),
# NOT openssl pkey -outform DER direct (OpenSSL 3.x emits legacy PKCS#1 => breaks
# PKCS8EncodedKeySpec). Positive: pkcs8 -topk8 -nocrypt present; Negative: no
# "pkey -in <priv> -outform DER" without -pubout in either script.
$shPkcs8 = $shContent -match 'openssl\s+pkcs8\s+-topk8\s+-nocrypt\s+-in\s+"\$PRIVATE_KEY_FILE"\s+-outform\s+DER'
$ps1Pkcs8 = $ps1Content -match 'openssl\s+pkcs8\s+-topk8\s+-nocrypt\s+-in\s+"\$privateKeyFile"\s+-outform\s+DER'
$shPrivPkeyDerDirect = $shContent -match 'pkey\s+-in\s+"\$PRIVATE_KEY_FILE"\s+-outform\s+DER' -and (-not ($shContent -match 'pkey\s+-in\s+"\$PRIVATE_KEY_FILE"\s+-pubout\s+-outform\s+DER'))
$ps1PrivPkeyDerDirect = $ps1Content -match 'pkey\s+-in\s+"\$privateKeyFile"\s+-outform\s+DER' -and (-not ($ps1Content -match 'pkey\s+-in\s+"\$privateKeyFile"\s+-pubout\s+-outform\s+DER'))
Assert-Test -CaseId "UT-207-3" -Name "private DER uses pkcs8 -topk8 -nocrypt -outform DER (never pkey -outform DER direct) on both platforms" `
    -Condition ($shPkcs8 -and $ps1Pkcs8 -and (-not $shPrivPkeyDerDirect) -and (-not $ps1PrivPkeyDerDirect)) `
    -Detail "shPkcs8=$shPkcs8 ps1Pkcs8=$ps1Pkcs8 shPkeyDirect=$shPrivPkeyDerDirect ps1PkeyDirect=$ps1PrivPkeyDerDirect"

$shPubDer = $shContent -match 'openssl\s+pkey\s+-in\s+"\$PRIVATE_KEY_FILE"\s+-pubout\s+-outform\s+DER\s+-out\s+"\$PUBLIC_KEY_DER_FILE"'
$ps1PubDer = $ps1Content -match 'openssl\s+pkey\s+-in\s+"\$privateKeyFile"\s+-pubout\s+-outform\s+DER\s+-out\s+"\$publicKeyDerFile"'
Assert-Test -CaseId "UT-207-4" -Name "step4 pkey -pubout -outform DER (X.509 public DER) in .sh and .ps1" `
    -Condition ($shPubDer -and $ps1PubDer) -Detail "sh=$shPubDer ps1=$ps1PubDer"

# Negative (P3-1): no PEM whole-file Base64 legacy pattern:
#   base64 -w0 "$PRIVATE_KEY_FILE" / openssl base64 -A -in <pem>
$shPemBase64Direct = ($shContent -match 'base64\s+-w0\s+"\$PRIVATE_KEY_FILE"' -or $shContent -match 'base64\s+-w0\s+"\$PUBLIC_KEY_FILE"') -or ($shContent -match 'openssl\s+base64\s+-A\s+-in\s+"\$PRIVATE_KEY_FILE"')
$shB64SourceDer = ($shContent -match 'b64_encode_file\s+"\$PRIVATE_KEY_DER_FILE"' -and $shContent -match 'b64_encode_file\s+"\$PUBLIC_KEY_DER_FILE"')
Assert-Test -CaseId "UT-207-5" -Name ".sh Base64 encodes .der files (no PEM whole-file base64 legacy pattern P3-1)" `
    -Condition ($shB64SourceDer -and (-not $shPemBase64Direct)) `
    -Detail "b64SourceDer=$shB64SourceDer pemDirect=$shPemBase64Direct"

# ===========================================================================
# UT-208: single-line Base64 implementation (incl. macOS branch) (P0)
# ===========================================================================
Assert-Test -CaseId "UT-208-1" -Name ".sh single-line Base64 acts on .der files (b64_encode_file private/public key DER)" `
    -Condition $shB64SourceDer -Detail "b64_encode_file on PRIVATE/PUBLIC_KEY_DER_FILE: $shB64SourceDer"

$shGnuW0  = $shContent -match "base64\s+-w0"
$shMacA   = $shContent -match "openssl\s+base64\s+-A"
Assert-Test -CaseId "UT-208-2" -Name ".sh has GNU base64 -w0 branch and macOS/BSD openssl base64 -A fallback branch" `
    -Condition ($shGnuW0 -and $shMacA) -Detail "gnuW0=$shGnuW0 macA=$shMacA"

$shNoNewline = $shContent -match 'printf\s+''%s''\s+"\$PRIVATE_KEY_B64"' -and $shContent -match 'printf\s+''%s''\s+"\$PUBLIC_KEY_B64"'
$ps1WriteAllText = $ps1Content -match "WriteAllText"
$ps1NoLineBreak = -not ($ps1Content -match "InsertLineBreaks")
Assert-Test -CaseId "UT-208-3" -Name "no trailing newline write (.sh printf '%s'; .ps1 WriteAllText, no InsertLineBreaks)" `
    -Condition ($shNoNewline -and $ps1WriteAllText -and $ps1NoLineBreak) `
    -Detail "shPrintf=$shNoNewline ps1WriteAllText=$ps1WriteAllText ps1InsertLineBreaks=$(-not $ps1NoLineBreak)"

# ===========================================================================
# UT-209: contract self-check logic static check (P0)
# ===========================================================================
$shCheckPem   = $shContent -match "BEGIN\|-----END"
$shCheckCrLf  = $shContent.Contains("`$'\r'") -and $shContent.Contains("`$'\n'")
$shStrictB64  = $shContent.Contains('^[A-Za-z0-9+/]+={0,2}$') -and $shContent.Contains("% 4 )) -ne 0") -and $shContent.Contains("b64_decode_ok")
$shDerOffset  = $shContent -match "PRIV_DER_LEN" -and $shContent -match "PUB_B19" -and $shContent -match "lt 16" -and $shContent -match "lt 24"
Assert-Test -CaseId "UT-209-1" -Name ".sh has all 4 contract self-checks (no PEM / no newline / strict Base64 / DER offsets)" `
    -Condition ($shCheckPem -and $shCheckCrLf -and $shStrictB64 -and $shDerOffset) `
    -Detail "checkPem=$shCheckPem checkCrLf=$shCheckCrLf strictB64=$shStrictB64 derOffset=$shDerOffset"

# DER structure offsets identical to .ps1: priv [0]=0x30 && [7]=0x30 (len>=16);
# pub [0]=0x30 && [4]=0x30 && [19]=0x03 (len>=24). In .sh decimal: 0x30=48, 0x03=3.
$shOffsetPattern = $shContent -match "PRIV_B0" -and $shContent -match "PRIV_B7" -and $shContent -match "PUB_B0" -and $shContent -match "PUB_B4" -and $shContent -match "PUB_B19"
$ps1OffsetPattern = $ps1Content -match "privDerBytes\[7\]\s+-ne\s+0x30" -and $ps1Content -match "pubDerBytes\[19\]\s+-ne\s+0x03" -and $ps1Content -match "pubDerBytes\[4\]\s+-ne\s+0x30"
Assert-Test -CaseId "UT-209-2" -Name "DER offset criteria match .ps1 (priv [0]=0x30/[7]=0x30 len>=16; pub [0]=0x30/[4]=0x30/[19]=0x03 len>=24)" `
    -Condition ($shOffsetPattern -and $ps1OffsetPattern) `
    -Detail "shOffsets=$shOffsetPattern ps1Offsets=$ps1OffsetPattern"

Assert-Test -CaseId "UT-209-3" -Name "self-check failure path prints fail grade and exits non-zero (fail_exit -> exit 1)" `
    -Condition ($shContent -match "fail_exit" -and $shContent -match "exit\s+1") `
    -Detail "failExit defined & exit 1 present"

# ===========================================================================
# UT-210: output masking static check (P0, security)
# ===========================================================================
$shNoCat = -not ($shContent -match 'cat\s+"\$PRIVATE_KEY_B64_FILE"') -and -not ($shContent -match 'cat\s+"\$PUBLIC_KEY_B64_FILE"')
$shMask24 = $shContent -match '\$\{PRIVATE_KEY_B64:0:24\}' -and $shContent -match '\$\{PUBLIC_KEY_B64:0:24\}'
Assert-Test -CaseId "UT-210-1" -Name ".sh never cats full private/public key Base64 files (P3-4 fix)" `
    -Condition $shNoCat -Detail "cat of *_base64.txt present: $(-not $shNoCat)"
Assert-Test -CaseId "UT-210-2" -Name ".sh prints only 24-char prefix (B64 slice 0:24 pattern)" `
    -Condition $shMask24 -Detail "mask24=$shMask24"
Assert-Test -CaseId "UT-210-3" -Name ".ps1 prints only 24-char prefix (Substring(0, [Math]::Min(24,...)))" `
    -Condition $ps1HasMask -Detail "ps1 mask prefix: $ps1HasMask"

$shResultExit = $shContent.Contains('"$FAIL" -eq 0') -and $shContent.Contains("exit 0") -and $shContent.Contains("exit 1")
Assert-Test -CaseId "UT-210-4" -Name ".sh result grading & exit code convention (all pass exit 0 / any fail exit 1, F-011)" `
    -Condition $shResultExit -Detail "result exit convention: $shResultExit"

# ===========================================================================
# UT-211: Java decode contract static check (P0)
# ===========================================================================
$authGetDecoder  = $authContent -match "Base64\.getDecoder\(\)\.decode"
$authPkcs8Spec   = $authContent -match "PKCS8EncodedKeySpec"
$authX509Spec    = $authContent -match "X509EncodedKeySpec"
Assert-Test -CaseId "UT-211-1" -Name "auth RsaKeyConfig keeps strict decode + PKCS8EncodedKeySpec + X509EncodedKeySpec contract lines (ADR-015 intact)" `
    -Condition ($authGetDecoder -and $authPkcs8Spec -and $authX509Spec) `
    -Detail "getDecoder=$authGetDecoder pkcs8=$authPkcs8Spec x509=$authX509Spec"

$gwGetDecoder = $gwContent -match "Base64\.getDecoder\(\)\.decode"
$gwX509Spec   = $gwContent -match "X509EncodedKeySpec"
Assert-Test -CaseId "UT-211-2" -Name "gateway RsaKeyConfig keeps strict decode + X509EncodedKeySpec contract lines (ADR-015 intact)" `
    -Condition ($gwGetDecoder -and $gwX509Spec) `
    -Detail "getDecoder=$gwGetDecoder x509=$gwX509Spec"

# Java zero-change via git (ADR-015): RsaKeyConfig files must NOT be in change list
$gitChanged = @()
$statusOut = @(& git -C $ProjectRoot status --short) 2>$null
foreach ($line in $statusOut) {
    $line = $line.TrimEnd()
    if ($line.Length -gt 3) { $gitChanged += $line.Substring(3).Trim().Trim('"') }
}
$javaChanged = @($gitChanged | Where-Object { $_.Replace("\", "/") -match "RsaKeyConfig\.java$" })
Assert-Test -CaseId "UT-211-3" -Name "Java zero-change: RsaKeyConfig.java NOT in git change list (ADR-015, TASK-007 must not touch Java)" `
    -Condition ($javaChanged.Count -eq 0) `
    -Detail "RsaKeyConfig.java changed files: $(if ($javaChanged) { $javaChanged -join ';' } else { 'none' })"

$shJavaContractNote = $shContent -match "Base64\.getDecoder" -or $shContent -match "PKCS8EncodedKeySpec"
Assert-Test -CaseId "UT-211-4" -Name ".sh self-check semantics aligned with Java strict decode contract (script doc/note references getDecoder/PKCS8EncodedKeySpec)" `
    -Condition $shJavaContractNote -Detail "sh java-contract note: $shJavaContractNote"

# ===========================================================================
# UT-212: OpenSSL availability pre-check (P1)
# ===========================================================================
$shPreCheck = $shContent -match "command\s+-v\s+openssl" -and $shContent -match "fail_exit" -and $shContent -match "OpenSSL"
$ps1PreCheck = $ps1Content -match "openssl\s+version" -and $ps1Content -match "exit\s+1" -and $ps1Content -match "OpenSSL"
Assert-Test -CaseId "UT-212-1" -Name ".sh contains openssl pre-check (command -v openssl -> fail_exit non-zero)" `
    -Condition $shPreCheck -Detail "shPreCheck=$shPreCheck"
Assert-Test -CaseId "UT-212-2" -Name ".ps1 keeps openssl pre-check (openssl version try/catch -> exit 1)" `
    -Condition $ps1PreCheck -Detail "ps1PreCheck=$ps1PreCheck"

# pre-check must run BEFORE the generation chain (line order)
$shPreLine = 0; $shGenLine = 0; $ln = 0
foreach ($l in $shLines) {
    $ln++
    if ($shPreLine -eq 0 -and $l -match "command\s+-v\s+openssl") { $shPreLine = $ln }
    if ($shGenLine -eq 0 -and $l -match "openssl\s+genpkey") { $shGenLine = $ln }
}
Assert-Test -CaseId "UT-212-3" -Name ".sh openssl pre-check executes before generation chain (line order)" `
    -Condition ($shPreLine -gt 0 -and $shGenLine -gt 0 -and $shPreLine -lt $shGenLine) `
    -Detail "preCheckLine=$shPreLine genpkeyLine=$shGenLine"

# ===========================================================================
# UT-213: key-pair guarantee static check (P1)
# ===========================================================================
Assert-Test -CaseId "UT-213-1" -Name ".ps1 public key derived from same private key (pkey -in privateKeyFile -pubout)" `
    -Condition $ps1PubPem -Detail "ps1 pubout from privateKeyFile: $ps1PubPem"
Assert-Test -CaseId "UT-213-2" -Name ".sh public key derived from same private key (pkey -in PRIVATE_KEY_FILE -pubout)" `
    -Condition $shPubPem -Detail "sh pubout from PRIVATE_KEY_FILE: $shPubPem"
$authKeyPair = $authContent -match "SHA256withRSA" -and $authContent -match "validateKeyPair" -and $authContent -match "verify\("
Assert-Test -CaseId "UT-213-3" -Name "auth RsaKeyConfig validateKeyPair (private sign + public verify) semantic present" `
    -Condition $authKeyPair -Detail "sha256withRSA=$($authContent -match 'SHA256withRSA') validateKeyPair=$($authContent -match 'validateKeyPair')"

# ===========================================================================
# UT-214: RSA key strength parameter static check (P1)
# ===========================================================================
$sh2048 = $shContent -match "rsa_keygen_bits:2048"
$ps12048 = $ps1Content -match "rsa_keygen_bits:2048"
Assert-Test -CaseId "UT-214-1" -Name ".ps1 genpkey uses -pkeyopt rsa_keygen_bits:2048 (RSA 2048)" `
    -Condition $ps12048 -Detail "ps1 rsa_keygen_bits:2048: $ps12048"
Assert-Test -CaseId "UT-214-2" -Name ".sh genpkey parameter identical to .ps1 (RSA 2048, strength not changed by refactor)" `
    -Condition ($sh2048 -and $ps12048) -Detail "sh2048=$sh2048 ps12048=$ps12048"
$authKeySize = $authContent -match "keySize\s*<\s*2048" -or $authContent -match "bitLength"
Assert-Test -CaseId "UT-214-3" -Name "auth RsaKeyConfig key-size contract (>=2048 bits check) present" `
    -Condition $authKeySize -Detail "auth key-size check: $authKeySize"

# ===========================================================================
# FT dynamic section
# ===========================================================================
Write-Output ("-" * 70)
Write-Output "Functional (FT) dynamic section"
Write-Output ("-" * 70)

$script:tmpOutDir = Join-Path $env:TEMP ("cso-rsa-test-" + [guid]::NewGuid().ToString("N"))
if ($opensslExe) {
    $opensslDir = Split-Path -Parent $opensslExe
    if ($env:PATH -notlike "*$opensslDir*") { $env:PATH = "$opensslDir;$env:PATH" }
}

function Invoke-Ps1Keygen {
    param(
        [string]$OutDir,
        [string]$PreCmd = ""
    )
    # Runs deploy-rsa-keygen.ps1 in a child PowerShell (chcp 65001 for UTF-8),
    # returns @{ ExitCode = ..; Output = .. }
    $inner = "chcp 65001 >nul & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ps1File`" -OutputDir `"$OutDir`""
    if ($PreCmd) { $inner = "$PreCmd & $inner" }
    $out = (cmd /c $inner 2>&1 | Out-String)
    $exit = $LASTEXITCODE
    return @{ ExitCode = $exit; Output = $out }
}

function Test-ArtifactContract {
    param(
        [string]$B64,
        [string]$Kind   # "private" | "public"
    )
    $noPem = $B64 -notmatch "-----BEGIN|-----END"
    $singleLine = $B64 -notmatch "[\r\n]"
    $strictOk = $false
    try { $bytes = [Convert]::FromBase64String($B64); $strictOk = $true } catch { $strictOk = $false }
    $derOk = $false
    if ($strictOk) {
        if ($Kind -eq "private") {
            $derOk = ($bytes.Length -ge 16 -and $bytes[0] -eq 0x30 -and $bytes[7] -eq 0x30)
        }
        else {
            $derOk = ($bytes.Length -ge 24 -and $bytes[0] -eq 0x30 -and $bytes[4] -eq 0x30 -and $bytes[19] -eq 0x03)
        }
    }
    return @{ NoPem = $noPem; SingleLine = $singleLine; Strict = $strictOk; Der = $derOk }
}

function New-Ps1Artifacts {
    # Generates fresh artifacts into $script:tmpOutDir via .ps1; returns
    # @{ ExitCode; Output; PrivB64; PubB64 } or $null if openssl unavailable.
    if (-not $opensslAvailable) { return $null }
    if (Test-Path -LiteralPath $script:tmpOutDir) {
        Remove-Item -LiteralPath $script:tmpOutDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $script:tmpOutDir -Force | Out-Null
    $r = Invoke-Ps1Keygen -OutDir $script:tmpOutDir
    $privB64 = ""
    $pubB64 = ""
    $privFile = Join-Path $script:tmpOutDir "private_key_base64.txt"
    $pubFile  = Join-Path $script:tmpOutDir "public_key_base64.txt"
    if ((Test-Path -LiteralPath $privFile) -and (Test-Path -LiteralPath $pubFile)) {
        $privB64 = (Read-Utf8File $privFile).Trim()
        $pubB64 = (Read-Utf8File $pubFile).Trim()
    }
    return @{ ExitCode = $r.ExitCode; Output = $r.Output; PrivB64 = $privB64; PubB64 = $pubB64 }
}

# ---- FT-134: .ps1 full chain run (P0) -------------------------------------
if ($opensslAvailable) {
    $a = New-Ps1Artifacts
    $artifactsOk = $true
    foreach ($name in @("private_key.pem", "public_key.pem", "private_key.der", "public_key.der", "private_key_base64.txt", "public_key_base64.txt")) {
        $p = Join-Path $script:tmpOutDir $name
        if (-not (Test-Path -LiteralPath $p) -or ((Get-Item -LiteralPath $p).Length -eq 0)) { $artifactsOk = $false }
    }
    Assert-Test -CaseId "FT-134-1" -Name ".ps1 full chain exit 0 (OpenSSL pre-check -> generate -> self-check -> masked output)" `
        -Condition ($a.ExitCode -eq 0) -Detail "exit=$($a.ExitCode)"
    Assert-Test -CaseId "FT-134-2" -Name "6 artifacts generated and non-empty (pem x2 + der x2 + base64.txt x2)" `
        -Condition $artifactsOk -Detail "outDir=$script:tmpOutDir"
    # .ps1 success grade text is Chinese (UTF-8); when run under Windows
    # PowerShell 5.1 the child-process console encoding may garble it, so the
    # grade assertion uses stable ASCII substrings (masked key hint + artifact
    # mention). The pass semantics are guaranteed by exit code 0 (all contract
    # self-checks passed inside the script) + 6 non-empty artifacts.
    Assert-Test -CaseId "FT-134-3" -Name ".ps1 output contains masked key hints (RSA_PRIVATE_KEY) and artifact mention (pass grade implied by exit 0)" `
        -Condition ($a.Output -match "RSA_PRIVATE_KEY" -and $a.Output -match "private_key_base64.txt") `
        -Detail "masked hint mention: $($a.Output -match 'RSA_PRIVATE_KEY'), artifact name mention: $($a.Output -match 'private_key_base64.txt')"
}
else {
    Assert-Skip -CaseId "FT-134" -Name ".ps1 full chain run skipped (no openssl on host)" -Detail "no openssl executable found"
}

# ---- FT-135: .ps1 artifact external contract (P0) -------------------------
if ($opensslAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "private_key_base64.txt"))) {
    $privB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "private_key_base64.txt")).Trim()
    $pubB64  = (Read-Utf8File (Join-Path $script:tmpOutDir "public_key_base64.txt")).Trim()
    $cPriv = Test-ArtifactContract -B64 $privB64 -Kind "private"
    $cPub  = Test-ArtifactContract -B64 $pubB64 -Kind "public"
    Assert-Test -CaseId "FT-135-1" -Name ".ps1 private_key_base64.txt: no PEM / single line / strict decode / PKCS#8 DER offsets ([0]=0x30 [7]=0x30 len>=16)" `
        -Condition ($cPriv.NoPem -and $cPriv.SingleLine -and $cPriv.Strict -and $cPriv.Der) `
        -Detail "noPem=$($cPriv.NoPem) singleLine=$($cPriv.SingleLine) strict=$($cPriv.Strict) der=$($cPriv.Der)"
    Assert-Test -CaseId "FT-135-2" -Name ".ps1 public_key_base64.txt: no PEM / single line / strict decode / X.509 DER offsets ([0]=0x30 [4]=0x30 [19]=0x03 len>=24)" `
        -Condition ($cPub.NoPem -and $cPub.SingleLine -and $cPub.Strict -and $cPub.Der) `
        -Detail "noPem=$($cPub.NoPem) singleLine=$($cPub.SingleLine) strict=$($cPub.Strict) der=$($cPub.Der)"
}
else {
    Assert-Skip -CaseId "FT-135" -Name ".ps1 artifact contract check skipped (no artifacts)" -Detail "requires FT-134 artifacts"
}

# ---- FT-136: .ps1 artifact key-pair verification (P0) ---------------------
if ($opensslAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "private_key.pem")) -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "public_key.pem"))) {
    $privPem = Join-Path $script:tmpOutDir "private_key.pem"
    $pubPem  = Join-Path $script:tmpOutDir "public_key.pem"
    $dataFile = Join-Path $script:tmpOutDir "_pair_test_data.bin"
    [System.IO.File]::WriteAllBytes($dataFile, [System.Text.Encoding]::UTF8.GetBytes("CloudStrollOffice-RSA-KeyPair-Validation"))
    $sigFile = Join-Path $script:tmpOutDir "_pair_test.sig"
    $null = & $opensslExe dgst -sha256 -sign $privPem -out $sigFile $dataFile 2>$null
    $signExit = $LASTEXITCODE
    $verifyOut = (& $opensslExe dgst -sha256 -verify $pubPem -signature $sigFile $dataFile 2>&1 | Out-String)
    $verifyExit = $LASTEXITCODE
    $pairOk = ($signExit -eq 0 -and $verifyExit -eq 0 -and $verifyOut -match "Verified OK")
    Assert-Test -CaseId "FT-136-1" -Name ".ps1 artifact key-pair verified (SHA256withRSA sign with private + verify with public => true, same as auth validateKeyPair)" `
        -Condition $pairOk -Detail "signExit=$signExit verifyExit=$verifyExit out=$verifyOut.Trim()"
}
else {
    Assert-Skip -CaseId "FT-136" -Name ".ps1 artifact key-pair verification skipped (no openssl or artifacts)" -Detail "requires openssl + FT-134 artifacts"
}

# ---- FT-137: .sh full chain run (P0, environment-dependent) ---------------
if ($bashAvailable) {
    $shOutDir = Join-Path $script:tmpOutDir "sh-run"
    $shOut = (& $bashExe $shFile $shOutDir 2>&1 | Out-String)
    $shExit = $LASTEXITCODE
    Assert-Test -CaseId "FT-137-1" -Name ".sh full chain exit 0" -Condition ($shExit -eq 0) -Detail "exit=$shExit"
    $shArtifactsOk = $true
    foreach ($name in @("private_key.pem", "public_key.pem", "private_key.der", "public_key.der", "private_key_base64.txt", "public_key_base64.txt")) {
        if (-not (Test-Path -LiteralPath (Join-Path $shOutDir $name))) { $shArtifactsOk = $false }
    }
    Assert-Test -CaseId "FT-137-2" -Name ".sh generates 6 artifacts" -Condition $shArtifactsOk -Detail "outDir=$shOutDir"
}
else {
    Assert-Skip -CaseId "FT-137" -Name ".sh full chain run skipped (no usable bash/WSL on host)" `
        -Detail "bash.exe is WSL2 gateway without distro; verify on Linux deployment target in regression"
}

# ---- FT-138: .sh artifact contract check (P0) -----------------------------
if ($bashAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "sh-run\private_key_base64.txt"))) {
    $shPrivB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "sh-run\private_key_base64.txt")).Trim()
    $shPubB64  = (Read-Utf8File (Join-Path $script:tmpOutDir "sh-run\public_key_base64.txt")).Trim()
    $cShPriv = Test-ArtifactContract -B64 $shPrivB64 -Kind "private"
    $cShPub  = Test-ArtifactContract -B64 $shPubB64 -Kind "public"
    Assert-Test -CaseId "FT-138-1" -Name ".sh private_key_base64.txt passes external contract (no PEM/single line/strict/DER PKCS#8)" `
        -Condition ($cShPriv.NoPem -and $cShPriv.SingleLine -and $cShPriv.Strict -and $cShPriv.Der) `
        -Detail "noPem=$($cShPriv.NoPem) singleLine=$($cShPriv.SingleLine) strict=$($cShPriv.Strict) der=$($cShPriv.Der)"
    Assert-Test -CaseId "FT-138-2" -Name ".sh public_key_base64.txt passes external contract (no PEM/single line/strict/DER X.509)" `
        -Condition ($cShPub.NoPem -and $cShPub.SingleLine -and $cShPub.Strict -and $cShPub.Der) `
        -Detail "noPem=$($cShPub.NoPem) singleLine=$($cShPub.SingleLine) strict=$($cShPub.Strict) der=$($cShPub.Der)"
}
else {
    Assert-Skip -CaseId "FT-138" -Name ".sh artifact contract check skipped (no .sh artifacts)" -Detail "requires FT-137 artifacts on bash-capable host"
}

# ---- FT-139: .ps1/.sh output alignment (P0) -------------------------------
if ($opensslAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "private_key_base64.txt"))) {
    $privB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "private_key_base64.txt")).Trim()
    $pubB64  = (Read-Utf8File (Join-Path $script:tmpOutDir "public_key_base64.txt")).Trim()
    # RSA-2048 PKCS#8 private DER = 1218 bytes => Base64 1624 chars;
    # X.509 public DER = 294 bytes => Base64 392 chars (DER single-line scale)
    $privLenOk = ($privB64.Length -eq 1624)
    $pubLenOk  = ($pubB64.Length -eq 392)
    Assert-Test -CaseId "FT-139-1" -Name ".ps1 artifact Base64 length at DER single-line scale (private 1624 chars, public 392 chars)" `
        -Condition ($privLenOk -and $pubLenOk) `
        -Detail "privLen=$($privB64.Length) (expected 1624) pubLen=$($pubB64.Length) (expected 392)"
    # .sh side alignment: skipped without bash (static equivalence covered by UT-207/208)
    if ($bashAvailable) {
        $shPrivB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "sh-run\private_key_base64.txt")).Trim()
        $shPubB64  = (Read-Utf8File (Join-Path $script:tmpOutDir "sh-run\public_key_base64.txt")).Trim()
        $alignOk = ($shPrivB64.Length -eq $privB64.Length -and $shPubB64.Length -eq $pubB64.Length `
                    -and $shPrivB64 -notmatch "-----BEGIN" -and $shPubB64 -notmatch "-----BEGIN")
        Assert-Test -CaseId "FT-139-2" -Name ".sh artifact aligned with .ps1 (same DER single-line length scale, no PEM markers, P3 fix evidence)" `
            -Condition $alignOk -Detail "shPrivLen=$($shPrivB64.Length) ps1PrivLen=$($privB64.Length) shPubLen=$($shPubB64.Length) ps1PubLen=$($pubB64.Length)"
    }
    else {
        Assert-Skip -CaseId "FT-139-2" -Name ".sh vs .ps1 output alignment skipped (no bash/WSL)" -Detail "static equivalence covered by UT-207-3/4/5 and UT-208-1/2"
    }
}
else {
    Assert-Skip -CaseId "FT-139" -Name "output alignment check skipped (no openssl)" -Detail "requires FT-134 artifacts"
}

# ---- FT-140: Java end-to-end decode contract via jshell (P0) --------------
if ($opensslAvailable -and $jshellAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "private_key_base64.txt"))) {
    $privB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "private_key_base64.txt")).Trim()
    $pubB64  = (Read-Utf8File (Join-Path $script:tmpOutDir "public_key_base64.txt")).Trim()
    $jshScript = Join-Path $script:tmpOutDir "cso_rsa_java_check.jsh"
    $privEsc = $privB64.Replace('"', '\"')
    $pubEsc  = $pubB64.Replace('"', '\"')
    $jshContent = @"
import java.security.*;
import java.security.spec.*;
import java.util.Base64;
String privB64 = "$privEsc";
String pubB64 = "$pubEsc";
byte[] privBytes = Base64.getDecoder().decode(privB64);
byte[] pubBytes = Base64.getDecoder().decode(pubB64);
PKCS8EncodedKeySpec privSpec = new PKCS8EncodedKeySpec(privBytes);
X509EncodedKeySpec pubSpec = new X509EncodedKeySpec(pubBytes);
KeyFactory kf = KeyFactory.getInstance("RSA");
PrivateKey priv = kf.generatePrivate(privSpec);
PublicKey pub = kf.generatePublic(pubSpec);
Signature s = Signature.getInstance("SHA256withRSA");
s.initSign(priv);
s.update("CloudStrollOffice-RSA-KeyPair-Validation".getBytes("UTF-8"));
byte[] sig = s.sign();
Signature v = Signature.getInstance("SHA256withRSA");
v.initVerify(pub);
v.update("CloudStrollOffice-RSA-KeyPair-Validation".getBytes("UTF-8"));
boolean paired = v.verify(sig);
boolean rejected = false;
try { Base64.getDecoder().decode(privB64 + "\nAAAA"); } catch (IllegalArgumentException e) { rejected = true; }
System.out.println("RSA_JAVA_OK=" + (paired && rejected));
/exit
"@
    # .jsh must be written WITHOUT BOM (jshell rejects \ufeff); UTF8Encoding($false)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($jshScript, $jshContent, $utf8NoBom)
    # jshell writes prompts/errors to stderr => NativeCommandError under EAP=Stop;
    # temporarily relax EAP and merge stderr into output for matching.
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $javaOut = (& $jshellExe -q $jshScript 2>&1 | Out-String)
    $ErrorActionPreference = $oldEap
    $javaOk = ($javaOut -match "RSA_JAVA_OK=true")
    Assert-Test -CaseId "FT-140-1" -Name "Java end-to-end: strict decode (rejects newline) + PKCS#8 private parse + X.509 public parse + SHA256withRSA pair true" `
        -Condition $javaOk -Detail "jshell result: $(($javaOut | Select-String -Pattern 'RSA_JAVA_OK' | Select-Object -First 1).Line.Trim())"
}
else {
    Assert-Skip -CaseId "FT-140" -Name "Java end-to-end contract skipped" `
        -Detail "requires artifacts + jshell (openssl=$opensslAvailable jshell=$jshellAvailable artifacts=$(Test-Path -LiteralPath (Join-Path $script:tmpOutDir 'private_key_base64.txt')))"
}

# ---- FT-141: output masking at runtime (P0, security) ---------------------
if ($opensslAvailable -and (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "private_key_base64.txt"))) {
    # Run FIRST, then read artifacts: the .ps1 run regenerates the key pair,
    # so the output log and the artifact values MUST come from the same batch
    # (comparing the run's log against the PREVIOUS batch would fail because
    # each run generates a fresh RSA key with a different prefix).
    $r = Invoke-Ps1Keygen -OutDir $script:tmpOutDir
    $outputAll = $r.Output
    $privB64 = (Read-Utf8File (Join-Path $script:tmpOutDir "private_key_base64.txt")).Trim()
    $fullLeak = $outputAll.Contains($privB64)
    Assert-Test -CaseId "FT-141-1" -Name ".ps1 runtime log does NOT contain full private key Base64 (NFR-004 red line)" `
        -Condition (-not $fullLeak) -Detail "full private key in output: $fullLeak"
    if ($fullLeak) {
        # do not print the leaked value; print only the fact
        Assert-Test -CaseId "FT-141-2" -Name "prefix-only masking (24 chars) verified in output" -Condition $false -Detail "full leak detected, skipping prefix check (security)"
    }
    else {
        # find the masked prefix line: "RSA_PRIVATE_KEY": "<24chars>..."
        $maskMatch = [regex]::Match($outputAll, '"RSA_PRIVATE_KEY": "(.{24})\.\.\."')
        $maskedPrefixOk = $maskMatch.Success -and $maskMatch.Groups[1].Value -eq $privB64.Substring(0, 24)
        Assert-Test -CaseId "FT-141-2" -Name ".ps1 output shows 24-char prefix only (masked, no full value)" `
            -Condition $maskedPrefixOk -Detail "masked prefix match: $($maskMatch.Success)"
    }
}
else {
    Assert-Skip -CaseId "FT-141" -Name ".ps1 runtime masking check skipped (no openssl)" -Detail "requires FT-134 run"
}

# ---- FT-142: OpenSSL missing scenario (P1) --------------------------------
# Restricted PATH (no openssl dir) -> .ps1 must prompt install and exit non-zero
# NOTE: PATH cleanup must also strip the ACTUAL openssl directory found on
# this host (Git-for-Windows OR miniconda env), otherwise openssl stays
# reachable and the missing-scenario cannot be reproduced (observed on hosts
# where openssl lives under C:\Users\<user>\miniconda3\envs\*\Library\bin).
$cleanPath = $env:PATH
$stripDirs = @("C:\Program Files\Git\usr\bin", "C:\Program Files\Git\mingw64\bin")
if ($opensslExe) {
    $stripDirs += (Split-Path -Parent $opensslExe)
}
foreach ($p in ($stripDirs | Select-Object -Unique)) {
    $cleanPath = ($cleanPath -split ";" | Where-Object { $_ -ne $p -and $_ -ne "" }) -join ";"
}
$inner = "chcp 65001 >nul & set PATH=$cleanPath & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ps1File`" -OutputDir `"$script:tmpOutDir\missing-openssl`""
$out142 = (cmd /c $inner 2>&1 | Out-String)
$exit142 = $LASTEXITCODE
$promptOk = $out142 -match "OpenSSL"
$noArtifacts = -not (Test-Path -LiteralPath (Join-Path $script:tmpOutDir "missing-openssl\private_key.pem"))
Assert-Test -CaseId "FT-142-1" -Name "OpenSSL missing: .ps1 prompts OpenSSL install guidance" `
    -Condition $promptOk -Detail "output mentions OpenSSL: $promptOk"
Assert-Test -CaseId "FT-142-2" -Name "OpenSSL missing: non-zero exit and no artifacts produced" `
    -Condition ($exit142 -ne 0 -and $noArtifacts) -Detail "exit=$exit142 artifactsAbsent=$noArtifacts"

# ---- FT-143: repeated run idempotency & overwrite (P1) --------------------
if ($opensslAvailable) {
    $r1 = Invoke-Ps1Keygen -OutDir $script:tmpOutDir
    $r2 = Invoke-Ps1Keygen -OutDir $script:tmpOutDir
    $filesNow = @(Get-ChildItem -LiteralPath $script:tmpOutDir -File | Where-Object { $_.Name -notlike "_*" -and $_.Name -notlike "*.jsh" })
    $artifactNames = @("private_key.pem", "public_key.pem", "private_key.der", "public_key.der", "private_key_base64.txt", "public_key_base64.txt")
    $noResidue = ($filesNow.Count -eq 6) -and (@($filesNow | Where-Object { $_.Name -notin $artifactNames }).Count -eq 0)
    Assert-Test -CaseId "FT-143-1" -Name "repeated .ps1 runs both exit 0 (idempotent)" -Condition (($r1.ExitCode -eq 0) -and ($r2.ExitCode -eq 0)) -Detail "run1=$($r1.ExitCode) run2=$($r2.ExitCode)"
    Assert-Test -CaseId "FT-143-2" -Name "no residue beyond 6 artifacts after repeated runs (overwrite normal)" -Condition $noResidue -Detail "files in outDir: $($filesNow.Count) (expect 6)"
}
else {
    Assert-Skip -CaseId "FT-143" -Name "repeated run idempotency skipped (no openssl)" -Detail "requires FT-134 run"
}

# ---- FT-144: custom output directory parameter (P1) -----------------------
if ($opensslAvailable) {
    $customDir = Join-Path $env:TEMP ("cso-rsa-custom-" + [guid]::NewGuid().ToString("N"))
    $r = Invoke-Ps1Keygen -OutDir $customDir
    $customOk = (Test-Path -LiteralPath $customDir) -and (Test-Path -LiteralPath (Join-Path $customDir "private_key_base64.txt")) `
                -and (Test-Path -LiteralPath (Join-Path $customDir "public_key_base64.txt"))
    Assert-Test -CaseId "FT-144-1" -Name "custom output directory auto-created and 6 artifacts land there (.ps1 -OutputDir)" `
        -Condition ($customOk -and $r.ExitCode -eq 0) -Detail "exit=$($r.ExitCode) customDirOk=$customOk dir=$customDir"
    if (Test-Path -LiteralPath $customDir) {
        Remove-Item -LiteralPath $customDir -Recurse -Force
    }
}
else {
    Assert-Skip -CaseId "FT-144" -Name "custom output directory scenario skipped (no openssl)" -Detail "requires openssl"
}

# ---------------------------------------------------------------------------
# Cleanup temp artifacts
# ---------------------------------------------------------------------------
if (Test-Path -LiteralPath $script:tmpOutDir) {
    Remove-Item -LiteralPath $script:tmpOutDir -Recurse -Force
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Output ("=" * 70)
Write-Output "Summary: PASS=$($script:Pass) FAIL=$($script:Fail) SKIP=$($script:Skip)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    $script:FailedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }

# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
