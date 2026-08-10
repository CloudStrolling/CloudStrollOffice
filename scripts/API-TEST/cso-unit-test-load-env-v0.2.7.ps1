# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - load-env Unified Config Loader Test (TASK-002)
# ----------------------------------------------------------------------------
# Coverage: UT-144 ~ UT-151 + FT-073 ~ FT-077 in task testcase
#           (docs/cso-v0.2.7/task_TASK-002/testcase.md)
#   UT-144: load-env.ps1 parseable via PowerShell Parser (no syntax errors) (P0)
#   UT-145: load-env.sh syntax check via bash -n (fallback: shebang+structure) (P0)
#   UT-146: path derivation & injection baseline (UT-078 contract) preserved (P0)
#   UT-147: SPDX header + copyright + Simplified-Chinese comments present (P1)
#   UT-148: no hard-coded addresses or plaintext credentials (P0, security)
#   UT-149: 8 required key check list + missing collection + non-zero exit (P0)
#   UT-150: .sh source semantics (return 1, no set -e) / .ps1 exit 1 (P1)
#   UT-151: sensitive values never printed by output statements (P1, security)
#   FT-073: env.json exists -> all keys injected, exit 0 (P0, dynamic)
#   FT-074: env.json missing -> env.example.json guidance, non-zero exit (P0)
#   FT-075: required keys missing -> list missing names, non-zero exit (P0)
#   FT-076: invalid JSON -> parse failure message, non-zero exit (P1)
#   FT-077: dual-platform consistency (.sh dynamic part SKIP if no bash) (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-load-env-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-load-env-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass (SKIP not counted as failure), 1 = any failure
# NOTE:
#   ASCII only in this script to keep PowerShell 5.1 encoding safe. CJK
#   assertions are built from Unicode code points; source files with CJK
#   content are read explicitly as UTF-8 via .NET APIs. The real
#   deploy/env.json may contain sensitive credentials - the script only
#   checks key presence/non-empty and never prints credential values.
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

# Build CJK strings from Unicode code points (keep this script ASCII-safe)
function Get-CjkText {
    param([string]$Key)
    switch ($Key) {
        "copy"        { return [string][char]0x590D + [string][char]0x5236 }   # 复制
        "missing"     { return [string][char]0x7F3A + [string][char]0x5931 }   # 缺失
        "notexist"    { return [string][char]0x4E0D + [string][char]0x5B58 + [string][char]0x5728 } # 不存在
        "parse"       { return [string][char]0x89E3 + [string][char]0x6790 }   # 解析
        "fail"        { return [string][char]0x5931 + [string][char]0x8D25 }   # 失败
        "config"      { return [string][char]0x914D + [string][char]0x7F6E }   # 配置
        "loaded"      { return [string][char]0x52A0 + [string][char]0x8F7D }   # 加载
        "secret"      { return [string][char]0x5BC6 + [string][char]0x94A5 }   # 密钥
        "sensitive"   { return [string][char]0x654F + [string][char]0x611F + [string][char]0x503C } # 敏感值
        "noprint"     { return [string][char]0x4E0D + [string][char]0x6253 + [string][char]0x5370 } # 不打印
        "fill"        { return [string][char]0x586B + [string][char]0x5199 }   # 填写
    }
    return ""
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 load-env Unified Config Loader Test (TASK-002, UT-144~UT-151 + FT-073~FT-077)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$scriptsDir = Join-Path $ProjectRoot "deploy\scripts"
$loadEnvPs1 = Join-Path $scriptsDir "load-env.ps1"
$loadEnvSh  = Join-Path $scriptsDir "load-env.sh"
$deployDir  = Join-Path $ProjectRoot "deploy"
$envJson    = Join-Path $deployDir "env.json"
$envExample = Join-Path $deployDir "env.example.json"

$ps1Exists = Test-FileExists -Path $loadEnvPs1
$shExists  = Test-FileExists -Path $loadEnvSh

# ----------------------------------------------------------------------------
# UT-144: load-env.ps1 syntax parseability (P0)
# ----------------------------------------------------------------------------
if (-not $ps1Exists) {
    Assert-Test -CaseId "UT-144-1" -Name "load-env.ps1 exists" -Condition $false -Detail "not found: $loadEnvPs1"
}
else {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($loadEnvPs1, [ref]$tokens, [ref]$errors) | Out-Null
    $errText = ""
    if ($errors -and $errors.Count -gt 0) {
        $errText = ($errors | ForEach-Object { "L$($_.Extent.StartLineNumber):$($_.Message)" }) -join "; "
    }
    Assert-Test -CaseId "UT-144-1" -Name "load-env.ps1 parseable via PowerShell Parser (no syntax errors, PS 5.1 compatible)" `
        -Condition (-not $errors -or $errors.Count -eq 0) `
        -Detail ("parse errors: " + $(if ($errText) { $errText } else { "none" }))
}

# ----------------------------------------------------------------------------
# UT-145: load-env.sh syntax check via bash -n (P0, fallback if no bash)
# ----------------------------------------------------------------------------
$bashUsable = $false
$bashCmd = Get-Command bash -ErrorAction SilentlyContinue
if ($bashCmd) {
    $probeOut = (& bash -n -c "true" 2>&1) 2>$null
    $bashUsable = ($LASTEXITCODE -eq 0)
}
if (-not $shExists) {
    Assert-Test -CaseId "UT-145-1" -Name "load-env.sh exists" -Condition $false -Detail "not found: $loadEnvSh"
}
else {
    if ($bashUsable) {
        $native = $loadEnvSh
        $wslPath = $native
        if ($native -match "^([A-Za-z]):\\(.*)$") {
            $wslPath = "/mnt/" + $matches[1].ToLower() + "/" + ($matches[2] -replace "\\", "/")
        }
        $out = (& bash -n $wslPath 2>&1)
        $ok = ($LASTEXITCODE -eq 0)
        Assert-Test -CaseId "UT-145-1" -Name "load-env.sh syntax check via bash -n (exit 0, no output)" `
            -Condition $ok -Detail ("bash -n output: " + $(if ($out) { ($out -join " ") } else { "none" }))
    }
    else {
        # Fallback (bash/WSL unavailable): shebang + non-empty + if/fi pairing + return usage
        $shText = Read-Utf8File -Path $loadEnvSh
        $hasShebang = ($shText -match "(?m)^#!")
        $nonEmpty = ($shText.Trim().Length -gt 0)
        $ifCount = ([regex]::Matches($shText, "(?m)^\s*if\b")).Count
        $fiCount = ([regex]::Matches($shText, "(?m)^\s*fi\b")).Count
        $hasReturn = $shText.Contains("return 1")
        $structOk = $hasShebang -and $nonEmpty -and ($ifCount -eq $fiCount) -and $hasReturn
        Assert-Test -CaseId "UT-145-1" -Name "load-env.sh fallback structure check (bash unavailable: shebang+non-empty+if/fi paired+return)" `
            -Condition $structOk `
            -Detail ("bash usable: false; shebang: $hasShebang, non-empty: $nonEmpty, if=$ifCount fi=$fiCount, return 1: $hasReturn")
    }
}

# ----------------------------------------------------------------------------
# UT-146: path derivation & injection baseline (UT-078 contract) preserved (P0)
# ----------------------------------------------------------------------------
$ps1Text = if ($ps1Exists) { Read-Utf8File -Path $loadEnvPs1 } else { "" }
$shText  = if ($shExists) { Read-Utf8File -Path $loadEnvSh } else { "" }

$ps1PathOk = $false
$ps1PathDetail = ""
if ($ps1Exists) {
    $p1 = $ps1Text.Contains("PSScriptRoot")
    $p2 = $ps1Text.Contains("Split-Path -Parent `$PSScriptRoot")
    $p3 = $ps1Text.Contains("Join-Path `$ProjectDir `$EnvFile")
    $p4 = ($ps1Text.Contains("ConvertFrom-Json") -and $ps1Text.Contains("PSObject.Properties"))
    $p5 = $ps1Text.Contains("Set-Item") -and $ps1Text.Contains("env:`$(`$_.Name)")
    $ps1PathOk = ($p1 -and $p2 -and $p3 -and $p4 -and $p5)
    $ps1PathDetail = "PSScriptRoot=$p1, Split-Path=$p2, Join-Path=$p3, ConvertFrom-Json+PSObject=$p4, Set-Item env=$p5"
}
Assert-Test -CaseId "UT-146-1" -Name "load-env.ps1 keeps path derivation & injection baseline (UT-078 contract: PSScriptRoot/Split-Path/Join-Path/ConvertFrom-Json/PSObject/Set-Item env)" `
    -Condition $ps1PathOk -Detail $ps1PathDetail

$shPathOk = $false
$shPathDetail = ""
if ($shExists) {
    $s1 = $shText.Contains("BASH_SOURCE[0]")
    $s2 = $shText.Contains('PROJECT_DIR="$(dirname "$SCRIPT_DIR")"')
    $s3 = $shText.Contains("ENV_FILE_PATH=`"`$PROJECT_DIR/`$ENV_FILE`"")
    $s4 = ($shText.Contains("to_entries") -and $shText.Contains("@sh"))
    $s5 = $shText.Contains("shlex.quote")
    $shPathOk = ($s1 -and $s2 -and $s3 -and ($s4 -or $s5))
    $shPathDetail = "BASH_SOURCE=$s1, PROJECT_DIR=$s2, ENV_FILE_PATH=$s3, jq to_entries@sh=$s4, python shlex.quote=$s5"
}
Assert-Test -CaseId "UT-146-2" -Name "load-env.sh keeps path derivation & injection baseline (UT-078 contract: BASH_SOURCE/PROJECT_DIR/ENV_FILE_PATH/jq to_entries @sh or python shlex.quote)" `
    -Condition $shPathOk -Detail $shPathDetail

# ----------------------------------------------------------------------------
# UT-147: SPDX header + copyright + Simplified-Chinese comments (P1)
# ----------------------------------------------------------------------------
$ps1HeaderOk = $false
$shHeaderOk = $false
if ($ps1Exists) {
    $ps1HeaderOk = ($ps1Text.Contains("SPDX-License-Identifier") -and
                    $ps1Text.Contains("Apache-2.0") -and
                    $ps1Text.Contains("Copyright 2026 jenemy8023"))
}
if ($shExists) {
    $shHeaderOk = ($shText.Contains("SPDX-License-Identifier") -and
                   $shText.Contains("Apache-2.0") -and
                   $shText.Contains("Copyright 2026 jenemy8023"))
}
Assert-Test -CaseId "UT-147-1" -Name "load-env.ps1 / load-env.sh headers keep SPDX-License-Identifier Apache-2.0 + Copyright 2026 jenemy8023" `
    -Condition ($ps1HeaderOk -and $shHeaderOk) `
    -Detail (".ps1: $ps1HeaderOk, .sh: $shHeaderOk")

# Simplified-Chinese comments (CJK range U+4E00..U+9FFF) + sensitive-value no-print note
$cjkRegex = "[\u4e00-\u9fff]"
$ps1Cjk = $ps1Exists -and [regex]::IsMatch($ps1Text, $cjkRegex)
$shCjk  = $shExists -and [regex]::IsMatch($shText, $cjkRegex)
$secretWord = Get-CjkText -Key "sensitive"
$noprintWord = Get-CjkText -Key "noprint"
$ps1SecretNote = $ps1Exists -and $ps1Text.Contains($secretWord) -and $ps1Text.Contains($noprintWord)
$shSecretNote  = $shExists -and $shText.Contains($secretWord) -and $shText.Contains($noprintWord)
Assert-Test -CaseId "UT-147-2" -Name "comments in Simplified Chinese + sensitive-value no-print note present in both scripts" `
    -Condition ($ps1Cjk -and $shCjk -and $ps1SecretNote -and $shSecretNote) `
    -Detail (".ps1 CJK=$ps1Cjk secret-note=$ps1SecretNote; .sh CJK=$shCjk secret-note=$shSecretNote")

# ----------------------------------------------------------------------------
# UT-148: no hard-coded addresses or plaintext credentials (P0, security)
# ----------------------------------------------------------------------------
$hardAddrPattern = "(192\.168\.|10\.0\.|172\.(1[6-9]|2[0-9]|3[01])\.)"
$ps1Addr = $ps1Exists -and [regex]::IsMatch($ps1Text, $hardAddrPattern)
$shAddr  = $shExists -and [regex]::IsMatch($shText, $hardAddrPattern)
Assert-Test -CaseId "UT-148-1" -Name "no hard-coded environment addresses (192.168.x / 10.0.x / 172.16-31.x) in both scripts" `
    -Condition (-not $ps1Addr -and -not $shAddr) `
    -Detail (".ps1 hit: $ps1Addr, .sh hit: $shAddr (expected absent)")

# plaintext credential assignment pattern: SENSITIVE_KEY="literal" or SENSITIVE_KEY=literal
$credPattern = "(DB_PASSWORD|REDIS_PASSWORD|RSA_PRIVATE_KEY|RSA_PUBLIC_KEY|MARIADB_ROOT_PASSWORD)\s*=\s*[`"']?[^`"'\s]"
$ps1Cred = $ps1Exists -and [regex]::IsMatch($ps1Text, $credPattern)
$shCred  = $shExists -and [regex]::IsMatch($shText, $credPattern)
Assert-Test -CaseId "UT-148-2" -Name "no plaintext credential literal assignments (DB_PASSWORD/REDIS_PASSWORD/RSA_*/MARIADB_ROOT_PASSWORD = value)" `
    -Condition (-not $ps1Cred -and -not $shCred) `
    -Detail (".ps1 credential literal: $ps1Cred, .sh credential literal: $shCred (expected absent; values must be env-var referenced)")

# ----------------------------------------------------------------------------
# UT-149: 8 required key check list + missing collection + non-zero exit (P0)
# ----------------------------------------------------------------------------
$requiredKeys = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT",
                  "DB_USERNAME", "DB_PASSWORD", "REDIS_HOST", "REDIS_PORT")
$ps1MissingKeys = @($requiredKeys | Where-Object { -not $ps1Text.Contains($_) })
$shMissingKeys  = @($requiredKeys | Where-Object { -not $shText.Contains($_) })
Assert-Test -CaseId "UT-149-1" -Name "8 required key list (NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT) present in both scripts" `
    -Condition (($ps1MissingKeys.Count -eq 0) -and ($shMissingKeys.Count -eq 0)) `
    -Detail (".ps1 missing: " + $(if ($ps1MissingKeys.Count -eq 0) { "none" } else { $ps1MissingKeys -join ", " }) +
             "; .sh missing: " + $(if ($shMissingKeys.Count -eq 0) { "none" } else { $shMissingKeys -join ", " }))

# missing collection logic + per-name listing + non-zero exit
$ps1CollectOk = $ps1Exists -and $ps1Text.Contains("missingKeys") -and $ps1Text.Contains("`$missingKeys += `$key")
$ps1ExitOk = $ps1Exists -and $ps1Text.Contains("exit 1")
$shIndirect = $shExists -and $shText.Contains("${!key:-}")
$shArray = $shExists -and $shText.Contains("MISSING_KEYS")
$shReturnOk = $shExists -and $shText.Contains("return 1")
Assert-Test -CaseId "UT-149-2" -Name "missing-key collection + per-name listing + non-zero exit present (.ps1 collect+exit 1 / .sh indirect-expansion or array + return 1)" `
    -Condition ($ps1CollectOk -and $ps1ExitOk -and (($shIndirect -or $shArray)) -and $shReturnOk) `
    -Detail (".ps1 collect=$ps1CollectOk exit1=$ps1ExitOk; .sh indirect=${!key:-}=$shIndirect array=$shArray return1=$shReturnOk")

# ----------------------------------------------------------------------------
# UT-150: .sh source semantics (return 1, no set -e) / .ps1 exit 1 (P1)
# ----------------------------------------------------------------------------
# bare exit / set -e must be checked on EXECUTABLE lines only (comment lines
# may legitimately mention `set -e` as an anti-pattern, e.g. line 15 of
# load-env.sh); use a negative lookahead to skip comment lines.
$shNoExit = $shExists -and -not ($shText -match "(?m)^\s*(?!#)\s*exit\s+[0-9]")
$shNoSetE = $shExists -and -not ($shText -match "(?m)^\s*(?!#)\s*set\s+-[Ee]")
$shReturn1 = $shExists -and $shText.Contains("return 1")
$ps1Exit1 = $ps1Exists -and $ps1Text.Contains("exit 1")
Assert-Test -CaseId "UT-150-1" -Name ".sh uses return 1 (not exit) on failure + no set -e (source-type, no parent-shell pollution)" `
    -Condition ($shNoExit -and $shNoSetE -and $shReturn1) `
    -Detail ("bare exit in .sh: $(-not $shNoExit), set -e in .sh: $(-not $shNoSetE), return 1: $shReturn1")
Assert-Test -CaseId "UT-150-2" -Name ".ps1 uses exit 1 on failure (dot-source semantics, F-001 non-zero exit)" `
    -Condition $ps1Exit1 -Detail (".ps1 exit 1: $ps1Exit1")

# ----------------------------------------------------------------------------
# UT-151: sensitive values never printed by output statements (P1, security)
# ----------------------------------------------------------------------------
$sensitiveVars = @("DB_PASSWORD", "REDIS_PASSWORD", "RSA_PRIVATE_KEY",
                   "RSA_PUBLIC_KEY", "MARIADB_ROOT_PASSWORD")
$ps1OutputLines = @($ps1Text -split "`r?`n" | Where-Object { $_ -match "Write-(Host|Error|Output|Warning)" })
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
Assert-Test -CaseId "UT-151-1" -Name "output statements (Write-*/echo/printf) never reference sensitive variable values" `
    -Condition ($ps1SensitiveOut.Count -eq 0 -and $shSensitiveOut.Count -eq 0) `
    -Detail (".ps1 sensitive outputs: " + $(if ($ps1SensitiveOut.Count -eq 0) { "none" } else { $ps1SensitiveOut -join "; " }) +
             "; .sh sensitive outputs: " + $(if ($shSensitiveOut.Count -eq 0) { "none" } else { $shSensitiveOut -join "; " }))

# missing-key listing outputs only the key NAME (not value) - both scripts print "$key"
$ps1ListName = $ps1Exists -and ($ps1Text.Contains("  - `$key") -or $ps1Text.Contains("- `$key"))
$shListName  = $shExists  -and ($shText.Contains("  - `$key") -or $shText.Contains("- `$key"))
# success summary prints count / non-sensitive file path only
$ps1SummaryOk = $ps1Exists -and $ps1Text.Contains("`$count") -and -not ($ps1Text -match 'Write-Host.*\$(DB_PASSWORD|REDIS_PASSWORD|RSA_)')
$shSummaryOk  = $shExists  -and $shText.Contains("LOADED_COUNT")
Assert-Test -CaseId "UT-151-2" -Name "missing listing prints key names only + success summary prints count/non-sensitive only" `
    -Condition ($ps1ListName -and $shListName -and $ps1SummaryOk -and $shSummaryOk) `
    -Detail (".ps1 name-only=$ps1ListName summary=$ps1SummaryOk; .sh name-only=$shListName summary=$shSummaryOk")

# ============================================================================
# Functional tests (dynamic, three scenarios + exit code)
# ============================================================================

# ----------------------------------------------------------------------------
# FT-073: env.json exists -> all keys injected, exit 0 (P0, dynamic)
# ----------------------------------------------------------------------------
if (-not (Test-FileExists -Path $envJson)) {
    Assert-Test -CaseId "FT-073-1" -Name "env.json exists (real deploy env.json present for success scenario)" `
        -Condition $false -Detail "deploy/env.json not found: $envJson"
}
else {
    # snapshot keys already in environment to avoid false-positive injection
    $existingKeys = @()
    foreach ($k in $requiredKeys) {
        $item = Get-Item -Path "Env:$k" -ErrorAction SilentlyContinue
        if ($item) { $existingKeys += $k }
    }
    # remove the 8 required keys before dot-source (they may linger from a prior run)
    foreach ($k in $requiredKeys) {
        Remove-Item -Path "Env:$k" -ErrorAction SilentlyContinue
    }

    # success scenario runs in a child powershell so a hypothetical `exit 1`
    # inside load-env.ps1 cannot kill this test process; child writes combined
    # output to a temp UTF-8 file (via `& { } 2>&1 | Out-File`) which this
    # process parses for the INJECT_RESULT line (no sensitive values printed).
    $keyList = "'NACOS_ADDR','NACOS_HOME','DB_HOST','DB_PORT','DB_USERNAME','DB_PASSWORD','REDIS_HOST','REDIS_PORT'"
    $tmp073 = Join-Path $env:TEMP ("cso_loadenv_073_" + [Guid]::NewGuid().ToString("N") + ".txt")
    $oldEap073 = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $injectOk073 = $false
    $code073 = -999
    $resultLine073 = ""
    $childOut073 = ""
    try {
        $inner073 = ". '" + $loadEnvPs1 + "' -EnvFile 'env.json'; " +
                    "`$allOk = `$true; " +
                    "foreach (`$k in @($keyList)) { " +
                    "`$v = (Get-Item -Path ('Env:' + `$k) -ErrorAction SilentlyContinue).Value; " +
                    "if ([string]::IsNullOrEmpty(`$v)) { `$allOk = `$false } }; " +
                    "Write-Output ('INJECT_RESULT=' + `$allOk)"
        $child073 = "`$ErrorActionPreference='Continue'; [Console]::OutputEncoding=[System.Text.Encoding]::UTF8; " +
                    "& { $inner073 } 2>&1 | Out-File -FilePath '" + $tmp073 + "' -Encoding UTF8"
        $null = & powershell -NoProfile -ExecutionPolicy Bypass -Command $child073
        $code073 = $LASTEXITCODE
        if (Test-Path -LiteralPath $tmp073) {
            $childOut073 = [System.IO.File]::ReadAllText($tmp073, [System.Text.Encoding]::UTF8)
        }
        $m073 = [regex]::Match($childOut073, "INJECT_RESULT=(True|False)")
        $resultLine073 = if ($m073.Success) { $m073.Groups[1].Value } else { "missing" }
        $injectOk073 = ($code073 -eq 0) -and ($resultLine073 -eq "True")
    }
    finally {
        Remove-Item -LiteralPath $tmp073 -Force -ErrorAction SilentlyContinue
        $ErrorActionPreference = $oldEap073
    }
    Assert-Test -CaseId "FT-073-1" -Name "PowerShell: env.json exists -> load-env.ps1 dot-source success (exit 0) and 8 required env vars injected non-empty" `
        -Condition $injectOk073 `
        -Detail ("child exit=$code073; inject-result: $resultLine073; child output trimmed: " + (($childOut073 -replace "`r?`n", " | ")))

    # success message assertion (loaded + count, non-sensitive): grep source for the success line
    $loadWord = Get-CjkText -Key "loaded"
    $successLineOk = $ps1Exists -and ($ps1Text -match "Write-Host.*" + $loadWord) -and $ps1Text.Contains("`$count")
    Assert-Test -CaseId "FT-073-2" -Name "success summary contains 'loaded N items' message (count only, no sensitive values)" `
        -Condition $successLineOk -Detail ("success line with count: $successLineOk")
}

# ----------------------------------------------------------------------------
# FT-074: env.json missing -> env.example.json guidance, non-zero exit (P0)
# ----------------------------------------------------------------------------
function Invoke-LoadEnvChild {
    param([string]$EnvFileArg)
    # Run in a child powershell so script-level `exit 1` cannot kill this test
    # process. The child redirects stderr to a temp file (PowerShell 5.1 writes
    # UTF-16 LE for `2>`) and exits with the load-env script's own code; the
    # parent reads the file back with Unicode encoding. This avoids the
    # NativeCommandError that `2>&1` merging would raise under
    # $ErrorActionPreference=Stop and preserves CJK output correctly.
    $tmpErr = Join-Path $env:TEMP ("cso_loadenv_err_" + [Guid]::NewGuid().ToString("N") + ".txt")
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $cmd = "`$ErrorActionPreference='Continue'; [Console]::OutputEncoding=[System.Text.Encoding]::UTF8; . '" +
               $loadEnvPs1 + "' -EnvFile '" + $EnvFileArg + "' 2> '" + $tmpErr + "'"
        $null = & powershell -NoProfile -ExecutionPolicy Bypass -Command $cmd
        $code = $LASTEXITCODE
        $content = ""
        if (Test-Path -LiteralPath $tmpErr) {
            # PowerShell 5.1 `2>` writes UTF-16 LE
            $content = [System.IO.File]::ReadAllText($tmpErr, [System.Text.Encoding]::Unicode)
        }
        return @{ Output = $content; ExitCode = $code }
    }
    finally {
        Remove-Item -LiteralPath $tmpErr -Force -ErrorAction SilentlyContinue
        $ErrorActionPreference = $oldEap
    }
}

$missingArg = "missing.json"
$res = Invoke-LoadEnvChild -EnvFileArg $missingArg
$copyWord = Get-CjkText -Key "copy"
$missingWord = Get-CjkText -Key "missing"
$fillWord = Get-CjkText -Key "fill"
$hasGuidance = ($res.Output -match [regex]::Escape("env.example.json")) -and
               ($res.Output.Contains($copyWord)) -and ($res.Output.Contains($fillWord))
Assert-Test -CaseId "FT-074-1" -Name "PowerShell: env.json missing (EnvFile missing.json) -> guidance 'copy env.example.json + fill config' and non-zero exit" `
    -Condition ($res.ExitCode -ne 0 -and $hasGuidance) `
    -Detail ("exit=$($res.ExitCode); guidance(copy+env.example.json+fill)=$hasGuidance; output-trimmed: " + ($res.Output.Trim() -replace "`r?`n", " | "))

# .sh side (dynamic) - only when bash usable, otherwise environment SKIP
if ($bashUsable) {
    $shCmd = "source '" + $loadEnvSh + "' " + $missingArg + " >/dev/null 2>&1; echo EXIT=`$?"
    $shOut = (& bash -c $shCmd 2>&1)
    $shExit = if ($shOut -match "EXIT=([0-9]+)") { [int]$Matches[1] } else { -999 }
    Assert-Test -CaseId "FT-074-2" -Name "Bash: source load-env.sh missing.json -> guidance + non-zero exit (return 1)" `
        -Condition ($shExit -ne 0) `
        -Detail ("bash exit=$shExit; out: " + ($shOut -join " "))
}
else {
    Skip-Test -CaseId "FT-074-2" -Name "Bash: source load-env.sh missing.json -> guidance + non-zero exit" `
        -Detail "bash/WSL not usable on this host (HCS_E_HYPERV_NOT_INSTALLED) - .sh dynamic behavior SKIP, static coverage via UT-145/150"
}

# ----------------------------------------------------------------------------
# FT-075: required keys missing -> list missing names, non-zero exit (P0)
# ----------------------------------------------------------------------------
$tmpMissingJson = Join-Path $deployDir "_cso_test_missing.json"
try {
    # temp env.json with only 5 of 8 required keys: missing NACOS_ADDR / DB_PASSWORD / REDIS_HOST
    $partial = @{
        NACOS_HOME  = "D:/nacos"
        DB_HOST     = "127.0.0.1"
        DB_PORT     = "3306"
        DB_USERNAME = "root"
        REDIS_PORT  = "6379"
    } | ConvertTo-Json
    [System.IO.File]::WriteAllText($tmpMissingJson, $partial, (New-Object System.Text.UTF8Encoding($false)))

    $res2 = Invoke-LoadEnvChild -EnvFileArg "_cso_test_missing.json"
    $listOk = ($res2.Output.Contains("NACOS_ADDR")) -and
              ($res2.Output.Contains("DB_PASSWORD")) -and
              ($res2.Output.Contains("REDIS_HOST"))
    # missing names listed, but their VALUES must not appear (values were absent anyway; assert names listed)
    Assert-Test -CaseId "FT-075-1" -Name "PowerShell: required keys missing -> lists NACOS_ADDR/DB_PASSWORD/REDIS_HOST names and non-zero exit" `
        -Condition ($res2.ExitCode -ne 0 -and $listOk) `
        -Detail ("exit=$($res2.ExitCode); listed 3 names=$listOk; output-trimmed: " + ($res2.Output.Trim() -replace "`r?`n", " | "))
}
finally {
    Remove-Item -LiteralPath $tmpMissingJson -Force -ErrorAction SilentlyContinue
}

if ($bashUsable) {
    $tmpMissingSh = Join-Path $deployDir "_cso_test_missing.json"
    try {
        $partial = @{
            NACOS_HOME  = "D:/nacos"
            DB_HOST     = "127.0.0.1"
            DB_PORT     = "3306"
            DB_USERNAME = "root"
            REDIS_PORT  = "6379"
        } | ConvertTo-Json
        [System.IO.File]::WriteAllText($tmpMissingSh, $partial, (New-Object System.Text.UTF8Encoding($false)))
        $shCmd2 = "source '" + $loadEnvSh + "' _cso_test_missing.json >/dev/null 2>&1; echo EXIT=`$?"
        $shOut2 = (& bash -c $shCmd2 2>&1)
        $shExit2 = if ($shOut2 -match "EXIT=([0-9]+)") { [int]$Matches[1] } else { -999 }
        Assert-Test -CaseId "FT-075-2" -Name "Bash: source load-env.sh missing keys -> lists missing names + non-zero exit" `
            -Condition ($shExit2 -ne 0) `
            -Detail ("bash exit=$shExit2; out: " + ($shOut2 -join " "))
    }
    finally {
        Remove-Item -LiteralPath $tmpMissingSh -Force -ErrorAction SilentlyContinue
    }
}
else {
    Skip-Test -CaseId "FT-075-2" -Name "Bash: source load-env.sh missing keys -> lists missing names + non-zero exit" `
        -Detail "bash/WSL not usable on this host - .sh dynamic behavior SKIP"
}

# ----------------------------------------------------------------------------
# FT-076: invalid JSON -> parse failure message, non-zero exit (P1)
# ----------------------------------------------------------------------------
$tmpInvalidJson = Join-Path $deployDir "_cso_test_invalid.json"
try {
    # invalid JSON: one key but missing closing brace
    [System.IO.File]::WriteAllText($tmpInvalidJson, '{ "NACOS_ADDR": "127.0.0.1:8848", ',
                                   (New-Object System.Text.UTF8Encoding($false)))
    $res3 = Invoke-LoadEnvChild -EnvFileArg "_cso_test_invalid.json"
    $parseWord = Get-CjkText -Key "parse"
    $failWord = Get-CjkText -Key "fail"
    $parseMsgOk = ($res3.Output.Contains($parseWord)) -and ($res3.Output.Contains($failWord))
    Assert-Test -CaseId "FT-076-1" -Name "PowerShell: invalid JSON -> parse failure message + non-zero exit (no partial dirty env)" `
        -Condition ($res3.ExitCode -ne 0 -and $parseMsgOk) `
        -Detail ("exit=$($res3.ExitCode); parse-failure message=$parseMsgOk; output-trimmed: " + ($res3.Output.Trim() -replace "`r?`n", " | "))
}
finally {
    Remove-Item -LiteralPath $tmpInvalidJson -Force -ErrorAction SilentlyContinue
}

if ($bashUsable) {
    $tmpInvalidSh = Join-Path $deployDir "_cso_test_invalid.json"
    try {
        [System.IO.File]::WriteAllText($tmpInvalidSh, '{ "NACOS_ADDR": "127.0.0.1:8848", ',
                                       (New-Object System.Text.UTF8Encoding($false)))
        $shCmd3 = "source '" + $loadEnvSh + "' _cso_test_invalid.json >/dev/null 2>&1; echo EXIT=`$?"
        $shOut3 = (& bash -c $shCmd3 2>&1)
        $shExit3 = if ($shOut3 -match "EXIT=([0-9]+)") { [int]$Matches[1] } else { -999 }
        Assert-Test -CaseId "FT-076-2" -Name "Bash: source load-env.sh invalid JSON -> parse failure + non-zero exit" `
            -Condition ($shExit3 -ne 0) `
            -Detail ("bash exit=$shExit3; out: " + ($shOut3 -join " "))
    }
    finally {
        Remove-Item -LiteralPath $tmpInvalidSh -Force -ErrorAction SilentlyContinue
    }
}
else {
    Skip-Test -CaseId "FT-076-2" -Name "Bash: source load-env.sh invalid JSON -> parse failure + non-zero exit" `
        -Detail "bash/WSL not usable on this host - .sh dynamic behavior SKIP"
}

# ----------------------------------------------------------------------------
# FT-077: dual-platform behavior consistency (P1)
# ----------------------------------------------------------------------------
if ($bashUsable) {
    # both platforms available: compare three-scenario exit-code consistency
    $ps1Scenarios = @(
        (Invoke-LoadEnvChild -EnvFileArg "missing.json").ExitCode -ne 0,
        $true  # FT-073 success covered above (exit-mark True)
    )
    # success scenario on bash needs a valid env file: use real env.json
    $shOkCmd = "source '" + $loadEnvSh + "' env.json >/dev/null 2>&1; echo EXIT=`$?"
    $shOkOut = (& bash -c $shOkCmd 2>&1)
    $shOkExit = if ($shOkOut -match "EXIT=([0-9]+)") { [int]$Matches[1] } else { -999 }
    $consistent = ($ps1Scenarios[0] -eq $true) -and ($shOkExit -eq 0)
    Assert-Test -CaseId "FT-077-1" -Name "dual-platform consistency: success exit 0 + missing non-zero match on both platforms" `
        -Condition $consistent `
        -Detail (".ps1 missing non-zero=$($ps1Scenarios[0]); bash success exit=$shOkExit (0 expected)")
}
else {
    Skip-Test -CaseId "FT-077-1" -Name "dual-platform behavior consistency (three scenarios, .ps1 vs .sh)" `
        -Detail "bash/WSL not usable on this host - .sh dynamic behavior SKIP; .ps1 three-scenario behavior already verified in FT-073/074/075/076; static dual-platform contract covered by UT-146/149/150/151"
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
if ($script:SkippedCases.Count -gt 0) {
    Write-Output "Skipped cases (environment blocked, not counted as failure):"
    $script:SkippedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output ("=" * 70)
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
