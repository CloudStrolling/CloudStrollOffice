# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - Deprecated Script Cleanup Unit Test (TASK-008)
# ----------------------------------------------------------------------------
# Coverage: UT-215 ~ UT-223 in task testcase
#           (docs/cso-v0.2.7/task_TASK-008/testcase.md)
#   UT-215: deprecated scripts removed from workspace - Test-Path all False (P0)
#   UT-216: git tracking - deploy-env* no longer in git ls-files, delete record kept (P0)
#   UT-217: exact directory listing - 12 dual-platform pairs + .gitkeep = 25 entries (P0)
#   UT-218: kept scripts have no deploy-env* reference, load path intact (P0)
#   UT-219: deploy/deploy.md directory tree synchronized (no deploy-env*, matches dir) (P0)
#   UT-220: README.md deploy guide synchronized (env.example.json -> env.json usage) (P0)
#   UT-221: deployment-guide.md dual copies synchronized (no deploy-env*, identical) (P1)
#   UT-222: whole-project grep deploy-env no residue beyond allowed exceptions (P0)
#   UT-223: 12 script pairs complete (.ps1+.sh) + modified docs keep SPDX header (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 `
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

# git command output wrapper (cwd = project root); returns empty string on failure
# NOTE: parameter named $GitArgs - do NOT use $Args (reserved automatic variable)
function Invoke-GitCapture {
    param([string[]]$GitArgs)
    $out = ""
    try {
        $out = (& git @GitArgs 2>$null) -join "`n"
    }
    catch {
        $out = ""
    }
    return $out
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 Deprecated Script Cleanup Unit Test (TASK-008, UT-215~UT-223)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$scriptsDir = Join-Path $ProjectRoot "deploy\scripts"
$deployMd = Join-Path $ProjectRoot "deploy\deploy.md"
$readmeMd = Join-Path $ProjectRoot "README.md"
$deployGuideScripts = Join-Path $ProjectRoot "scripts\deployment-guide.md"
$deployGuideDocs = Join-Path $ProjectRoot "docs\deployment-guide.md"
$envExample = Join-Path $ProjectRoot "deploy\env.example.json"

# 12 kept script base names (capability matrix + legit scripts, dual-platform pairs)
$expectedPairs = @("load-env", "deploy-check-env", "deploy-start-services", "deploy-start-all",
                   "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system",
                   "deploy-rsa-keygen", "deploy-db-init", "build-backend", "build-client")

# 3 deprecated scripts (TASK-008 cleanup targets, removed via git rm)
$deprecatedScripts = @("deploy-env.ps1", "deploy-env-template.ps1", "deploy-env-template.sh")

# ----------------------------------------------------------------------------
# UT-215: deprecated scripts removed from workspace (P0)
# ----------------------------------------------------------------------------
$depExists = @($deprecatedScripts | Where-Object { Test-FileExists -Path (Join-Path $scriptsDir $_) })
Assert-Test -CaseId "UT-215-1" -Name "deprecated scripts all absent via Test-Path (deploy-env.ps1 / deploy-env-template.ps1 / deploy-env-template.sh)" `
    -Condition ($depExists.Count -eq 0) `
    -Detail ("still present: " + $(if ($depExists.Count -eq 0) { "none (all removed)" } else { $depExists -join ", " }))

$depNameResidue = @(Get-ChildItem -LiteralPath $scriptsDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "deploy-env*" } | ForEach-Object { $_.Name })
Assert-Test -CaseId "UT-215-2" -Name "Get-ChildItem listing has no deploy-env* file name residue" `
    -Condition ($depNameResidue.Count -eq 0) `
    -Detail ("residue files: " + $(if ($depNameResidue.Count -eq 0) { "none" } else { $depNameResidue -join ", " }))

# ----------------------------------------------------------------------------
# UT-216: git tracking - deploy-env* no longer tracked, delete record kept (P0)
# ----------------------------------------------------------------------------
$lsFiles = Invoke-GitCapture -GitArgs @("ls-files", "deploy/scripts")
$trackedResidue = @($lsFiles -split "`n" | Where-Object { $_ -match "deploy-env" })
Assert-Test -CaseId "UT-216-1" -Name "git ls-files deploy/scripts has no deploy-env* tracked files" `
    -Condition ($trackedResidue.Count -eq 0) `
    -Detail ("tracked residue: " + $(if ($trackedResidue.Count -eq 0) { "none" } else { $trackedResidue -join ", " }))

# delete record: staged D status (git rm done, not committed yet) OR git log --diff-filter=D history - either one is acceptable
$stagedStatus = Invoke-GitCapture -GitArgs @("diff", "--cached", "--name-status", "--", "deploy/scripts/")
$logDeleted = Invoke-GitCapture -GitArgs @("log", "--diff-filter=D", "--name-only", "--oneline", "--", "deploy/scripts/")
$deletedNames = @()
if ($stagedStatus) {
    $deletedNames += @($stagedStatus -split "`n" | Where-Object { $_ -match "^D\s+deploy/scripts/deploy-env" } |
        ForEach-Object { Split-Path (($_ -replace "^D\s+", "").Trim()) -Leaf })
}
if ($logDeleted) {
    $deletedNames += @($logDeleted -split "`n" | Where-Object { $_ -match "deploy-env" } | ForEach-Object { (Split-Path $_.Trim() -Leaf) })
}
$deletedNames = @($deletedNames | Sort-Object -Unique)
Assert-Test -CaseId "UT-216-2" -Name "delete record exists (staged D status via git rm, or git log --diff-filter=D history)" `
    -Condition ($deletedNames.Count -ge 3) `
    -Detail ("deleted entries found: " + $(if ($deletedNames.Count -eq 0) { "none" } else { $deletedNames -join ", " }))

$missingFromDeleted = @($deprecatedScripts | Where-Object { $_ -notin $deletedNames })
Assert-Test -CaseId "UT-216-3" -Name "all 3 deprecated scripts appear in the delete record (D)" `
    -Condition ($missingFromDeleted.Count -eq 0) `
    -Detail ("not in delete record: " + $(if ($missingFromDeleted.Count -eq 0) { "none (3/3)" } else { $missingFromDeleted -join ", " }))

# ----------------------------------------------------------------------------
# UT-217: exact directory listing - 12 dual-platform pairs + .gitkeep = 25 (P0)
# ----------------------------------------------------------------------------
$actualFiles = @(Get-ChildItem -LiteralPath $scriptsDir -File -ErrorAction SilentlyContinue |
    ForEach-Object { $_.Name } | Sort-Object)
$expectedFiles = @()
foreach ($pair in $expectedPairs) {
    $expectedFiles += "$pair.ps1"
    $expectedFiles += "$pair.sh"
}
$expectedFiles += ".gitkeep"
$expectedFiles = @($expectedFiles | Sort-Object)

Assert-Test -CaseId "UT-217-1" -Name "directory entry count = 25 (24 scripts + .gitkeep)" `
    -Condition ($actualFiles.Count -eq 25) `
    -Detail ("actual count: $($actualFiles.Count) (expected 25)")

$missingExpected = @($expectedFiles | Where-Object { $_ -notin $actualFiles })
Assert-Test -CaseId "UT-217-2" -Name "all 12 dual-platform pairs (24 files) + .gitkeep present in listing" `
    -Condition ($missingExpected.Count -eq 0) `
    -Detail ("missing entries: " + $(if ($missingExpected.Count -eq 0) { "none (25/25)" } else { $missingExpected -join ", " }))

$extraFiles = @($actualFiles | Where-Object { $_ -notin $expectedFiles })
$exactMatch = ($actualFiles.Count -eq $expectedFiles.Count -and $missingExpected.Count -eq 0 -and $extraFiles.Count -eq 0)
Assert-Test -CaseId "UT-217-3" -Name "exact listing match - no extra files (no deploy-env*, no temp/backup files)" `
    -Condition $exactMatch `
    -Detail ("extra files: " + $(if ($extraFiles.Count -eq 0) { "none (listing matches expected exactly)" } else { $extraFiles -join ", " }))

# ----------------------------------------------------------------------------
# UT-218: kept scripts have no deploy-env* reference, load path intact (P0)
# ----------------------------------------------------------------------------
$keptScripts = @(Get-ChildItem -LiteralPath $scriptsDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne ".gitkeep" -and $_.Extension -in @(".ps1", ".sh") })
$depRefFiles = @()
foreach ($f in $keptScripts) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    if ($content.Contains("deploy-env")) { $depRefFiles += $f.Name }
}
Assert-Test -CaseId "UT-218-1" -Name "no kept script (.ps1/.sh) references deploy-env* (grep = 0 hits)" `
    -Condition ($depRefFiles.Count -eq 0) `
    -Detail ("files with deploy-env reference: " + $(if ($depRefFiles.Count -eq 0) { "none" } else { $depRefFiles -join ", " }))

# spot check load-env load statements: check-env / start-services / start-all / start-gateway
$loadStmtOk = $true
$loadStmtDetail = @()
$loadStmtChecks = @(
    @("deploy-check-env.ps1", '$PSScriptRoot\load-env.ps1'),
    @("deploy-check-env.sh", '$SCRIPT_DIR/load-env.sh'),
    @("deploy-start-services.ps1", '$PSScriptRoot\load-env.ps1'),
    @("deploy-start-services.sh", '$SCRIPT_DIR/load-env.sh'),
    @("deploy-start-all.ps1", '$PSScriptRoot\load-env.ps1'),
    @("deploy-start-all.sh", '$SCRIPT_DIR/load-env.sh'),
    @("deploy-start-gateway.ps1", '$PSScriptRoot\load-env.ps1'),
    @("deploy-start-gateway.sh", '$SCRIPT_DIR/load-env.sh')
)
foreach ($rule in $loadStmtChecks) {
    $p = Join-Path $scriptsDir $rule[0]
    if (-not (Test-FileExists -Path $p)) { $loadStmtOk = $false; $loadStmtDetail += "$($rule[0]):missing"; continue }
    $content = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
    if (-not $content.Contains($rule[1])) { $loadStmtOk = $false; $loadStmtDetail += "$($rule[0]):no '$($rule[1])'" }
}
Assert-Test -CaseId "UT-218-2" -Name "spot check load-env load statement in check-env/start-services/start-all/start-gateway (.ps1+.sh)" `
    -Condition $loadStmtOk `
    -Detail ("issues: " + $(if ($loadStmtDetail.Count -eq 0) { "none (all reference load-env.ps1/load-env.sh)" } else { $loadStmtDetail -join "; " }))

# all 7 pairs (14 scripts: check-env/start-services/start-all/start-gateway/auth/biz/system) load via load-env
$mustLoadEnv = @()
foreach ($base in @("deploy-check-env", "deploy-start-services", "deploy-start-all",
                    "deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system")) {
    $mustLoadEnv += "$base.ps1"
    $mustLoadEnv += "$base.sh"
}
$notLoading = @()
foreach ($name in $mustLoadEnv) {
    $p = Join-Path $scriptsDir $name
    $content = if (Test-FileExists -Path $p) { [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8) } else { "" }
    if (-not $content.Contains("load-env")) { $notLoading += $name }
}
Assert-Test -CaseId "UT-218-3" -Name "all 14 capability scripts (7 pairs) reference load-env - dependency intact after cleanup" `
    -Condition ($notLoading.Count -eq 0) `
    -Detail ("not referencing load-env: " + $(if ($notLoading.Count -eq 0) { "none (14/14)" } else { $notLoading -join ", " }))

# ----------------------------------------------------------------------------
# UT-219: deploy/deploy.md directory tree synchronized (P0)
# ----------------------------------------------------------------------------
$deployMdText = if (Test-FileExists -Path $deployMd) { Read-Utf8File -Path $deployMd } else { "" }
Assert-Test -CaseId "UT-219-1" -Name "deploy/deploy.md has no deploy-env* declaration (tree lines 72-73 removed, P7-09 fixed)" `
    -Condition (-not $deployMdText.Contains("deploy-env")) `
    -Detail ("deploy-env hits: $($deployMdText.Contains('deploy-env')) (expected absent)")

$treeMissing = @()
foreach ($pair in $expectedPairs) {
    if (-not $deployMdText.Contains("$pair.ps1 / .sh") -and -not $deployMdText.Contains("$pair.ps1 /$pair.sh") -and -not $deployMdText.Contains("$pair.ps1")) {
        $treeMissing += $pair
    }
}
Assert-Test -CaseId "UT-219-2" -Name "deploy.md tree lists all 12 script pairs consistently with actual directory" `
    -Condition ($treeMissing.Count -eq 0) `
    -Detail ("pairs missing from tree: " + $(if ($treeMissing.Count -eq 0) { "none (12/12)" } else { $treeMissing -join ", " }))

# ----------------------------------------------------------------------------
# UT-220: README.md deploy guide synchronized (P0)
# ----------------------------------------------------------------------------
$readmeText = if (Test-FileExists -Path $readmeMd) { Read-Utf8File -Path $readmeMd } else { "" }
Assert-Test -CaseId "UT-220-1" -Name "README.md has no deploy-env* residue reference (line 229 updated)" `
    -Condition (-not $readmeText.Contains("deploy-env")) `
    -Detail ("deploy-env hits: $($readmeText.Contains('deploy-env')) (expected absent)")

$envGuideOk = $false
$envGuideDetail = ""
if ($readmeText) {
    $hasCopyItem = $readmeText.Contains("Copy-Item deploy\env.example.json deploy\env.json")
    $hasCp = $readmeText.Contains("cp deploy/env.example.json deploy/env.json")
    $hasEnvJsonRef = $readmeText.Contains("env.example.json") -and $readmeText.Contains("env.json")
    $envGuideOk = (($hasCopyItem -or $hasCp) -and $hasEnvJsonRef -and (Test-FileExists -Path $envExample))
    $envGuideDetail = "Copy-Item usage: $hasCopyItem, cp usage: $hasCp, env.example.json ref: $hasEnvJsonRef, env.example.json file: $(Test-FileExists -Path $envExample)"
}
Assert-Test -CaseId "UT-220-2" -Name "README.md guide updated to env.example.json -> env.json copy usage and env.example.json path real" `
    -Condition $envGuideOk `
    -Detail $envGuideDetail

# ----------------------------------------------------------------------------
# UT-221: deployment-guide.md dual copies synchronized (P1)
# ----------------------------------------------------------------------------
$guideScriptsText = if (Test-FileExists -Path $deployGuideScripts) { Read-Utf8File -Path $deployGuideScripts } else { "" }
$guideDocsText = if (Test-FileExists -Path $deployGuideDocs) { Read-Utf8File -Path $deployGuideDocs } else { "" }
Assert-Test -CaseId "UT-221-1" -Name "scripts/deployment-guide.md has no deploy-env* residue (row 1535 removed)" `
    -Condition (-not $guideScriptsText.Contains("deploy-env")) `
    -Detail ("deploy-env hits: $($guideScriptsText.Contains('deploy-env')) (expected absent)")
Assert-Test -CaseId "UT-221-2" -Name "docs/deployment-guide.md has no deploy-env* residue (dual copy synchronized)" `
    -Condition (-not $guideDocsText.Contains("deploy-env")) `
    -Detail ("deploy-env hits: $($guideDocsText.Contains('deploy-env')) (expected absent)")

$hashScripts = ""
$hashDocs = ""
if (Test-FileExists -Path $deployGuideScripts) { $hashScripts = (Get-FileHash -LiteralPath $deployGuideScripts -Algorithm SHA256).Hash }
if (Test-FileExists -Path $deployGuideDocs) { $hashDocs = (Get-FileHash -LiteralPath $deployGuideDocs -Algorithm SHA256).Hash }
Assert-Test -CaseId "UT-221-3" -Name "deployment-guide.md dual copies identical (SHA256 match, no single-side modification)" `
    -Condition ($hashScripts -ne "" -and $hashScripts -eq $hashDocs) `
    -Detail ("scripts copy: $hashScripts, docs copy: $hashDocs")

# ----------------------------------------------------------------------------
# UT-222: whole-project grep deploy-env no residue beyond allowed exceptions (P0)
# ----------------------------------------------------------------------------
# allowed exception list (grep deploy-env hits that do NOT count as residue):
#   - .opencode\prompts\ + docs\prompts\ historical session archives (opencode + impm exports)
#   - docs\cso-v0.2.5\ + docs\cso-v0.2.6\ historical version archives (deploy-env existed in those versions)
#   - docs\sad.md ADR-016 decision description ("remove deprecated script residue (deploy-env etc.)" is an action statement)
#   - docs\cso-v0.2.7\ this version's task docs themselves (testcase/lld/prd/issue-list/task_TASK-008/version_progress etc.)
#   - docs\cso-testcase.md main testcase doc (PM confirmed doc-merge handles it uniformly)
#   - docs\cso-prd.md historical requirement description (v0.2.5 migration scope, not modified)
#   - v0.2.5 archived test scripts (cso-unit-test-deploy-acceptance-v0.2.5.ps1 / cso-unit-test-scripts-migrate-v0.2.5.ps1)
#   - cso-unit-test-start-single-v0.2.7.ps1 (UT-193-3 negative assertion kept as regression basis)
#   - cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 (UT-134 reversed assertions + UT-134-3 P2 historical check)
#   - cso-api-test-v0.2.7.py (TC-092 assertion checks deploy-env deletion in git change list / log)
#   - this script itself (cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1, assertion logic needs deploy-env string)
$exceptionFragments = @(
    ".opencode\prompts\",
    "docs\prompts\",
    "docs\cso-v0.2.5\",
    "docs\cso-v0.2.6\",
    "docs\sad.md",
    "docs\cso-v0.2.7\",
    "docs\cso-testcase.md",
    "docs\cso-prd.md",
    "cso-unit-test-deploy-acceptance-v0.2.5.ps1",
    "cso-unit-test-scripts-migrate-v0.2.5.ps1",
    "cso-unit-test-start-single-v0.2.7.ps1",
    "cso-unit-test-deploy-scripts-issue-v0.2.7.ps1",
    "cso-api-test-v0.2.7.py",
    "cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1"
)
# scan excludes (.git, deps/artifacts, logs, keys dirs)
$excludeDirs = @(".git", "node_modules", "target", ".dart_tool", "build", "deploy\logs", "deploy\keys", ".idea", ".vscode")
$allFiles = @(Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart("\")
        $excluded = $false
        foreach ($d in $excludeDirs) {
            if ($rel.StartsWith($d, [System.StringComparison]::OrdinalIgnoreCase)) { $excluded = $true; break }
        }
        -not $excluded
    })
$residueHits = @()
foreach ($f in $allFiles) {
    $rel = $f.FullName.Substring($ProjectRoot.Length).TrimStart("\")
    $inException = $false
    foreach ($frag in $exceptionFragments) {
        if ($rel.IndexOf($frag, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $inException = $true; break }
    }
    if ($inException) { continue }
    $hit = $false
    try {
        $hit = (Select-String -LiteralPath $f.FullName -Pattern "deploy-env" -SimpleMatch -ErrorAction SilentlyContinue -Quiet)
    }
    catch { $hit = $false }
    if ($hit) { $residueHits += $rel }
}
Assert-Test -CaseId "UT-222-1" -Name "whole-project grep deploy-env has no residue beyond allowed exception list" `
    -Condition ($residueHits.Count -eq 0) `
    -Detail ("residue hits: " + $(if ($residueHits.Count -eq 0) { "none (all hits within allowed exceptions)" } else { $residueHits -join "; " }))

# ----------------------------------------------------------------------------
# UT-223: 12 script pairs complete + modified docs keep SPDX header (P1)
# ----------------------------------------------------------------------------
$pairMissing = @()
foreach ($name in $expectedPairs) {
    $hasPs1 = Test-FileExists -Path (Join-Path $scriptsDir "$name.ps1")
    $hasSh = Test-FileExists -Path (Join-Path $scriptsDir "$name.sh")
    if (-not ($hasPs1 -and $hasSh)) { $pairMissing += "$name(ps1=$hasPs1,sh=$hasSh)" }
}
Assert-Test -CaseId "UT-223-1" -Name "12 script pairs (.ps1+.sh) all complete (no single-version residue)" `
    -Condition ($pairMissing.Count -eq 0) `
    -Detail ("missing pairs: " + $(if ($pairMissing.Count -eq 0) { "none (12/12)" } else { $pairMissing -join "; " }))

$singleOnly = @($keptScripts | Where-Object {
    $base = $_.BaseName
    $otherExt = if ($_.Extension -eq ".ps1") { ".sh" } else { ".ps1" }
    -not (Test-FileExists -Path (Join-Path $scriptsDir ($base + $otherExt)))
} | ForEach-Object { $_.Name })
Assert-Test -CaseId "UT-223-2" -Name "no single-version script residue (every kept .ps1/.sh has its counterpart)" `
    -Condition ($singleOnly.Count -eq 0) `
    -Detail ("single-version files: " + $(if ($singleOnly.Count -eq 0) { "none (all paired)" } else { $singleOnly -join ", " }))

$spdxDocs = @("deploy\deploy.md", "README.md", "scripts\deployment-guide.md", "docs\deployment-guide.md")
$spdxMissing = @()
foreach ($docRel in $spdxDocs) {
    $p = Join-Path $ProjectRoot $docRel
    if (-not (Test-FileExists -Path $p)) { $spdxMissing += "$docRel:missing"; continue }
    $content = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
    # project .md docs keep the SPDX line at the END of the file (same convention as cso-*.md)
    if (-not ($content.Contains("SPDX-License-Identifier") -and $content.Contains("Copyright"))) {
        $spdxMissing += "$docRel:no-SPDX/copyright-line"
    }
}
Assert-Test -CaseId "UT-223-3" -Name "modified docs (deploy.md/README.md/deployment-guide.md x2) keep SPDX-License-Identifier + copyright header" `
    -Condition ($spdxMissing.Count -eq 0) `
    -Detail ("issues: " + $(if ($spdxMissing.Count -eq 0) { "none (all keep SPDX header)" } else { $spdxMissing -join "; " }))

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
