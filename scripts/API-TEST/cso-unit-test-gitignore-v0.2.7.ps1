# ============================================================================
# CloudStrollOffice (CSO) v0.2.7 - .gitignore Governance Unit & FT Test (TASK-009)
# ----------------------------------------------------------------------------
# Coverage: UT-224 ~ UT-229 and FT-149 ~ FT-152 in task testcase
#           (docs/cso-v0.2.7/task_TASK-009/testcase.md)
#   UT-224: JVM / debug artifact rules (8 patterns + section comment) (P0)
#   UT-225: build / test intermediate artifact rules (4 patterns) (P0)
#   UT-226: test report dir rules (3, trailing slash), API-TEST precise rules
#           (2, no whole-dir / script wildcard), python cache rules kept (P0)
#   UT-227: tool residue rules (6 patterns) (P0)
#   UT-228: governance red lines - no env.json* wildcard, no global wildcards
#           (*.xml/yml/py/ps1/sh/java/dart/md), !*.gitkeep whitelist kept,
#           every new rule must not match tracked in-repo files (P0)
#   UT-229: section comment style, SPDX/Copyright footer kept, no duplicate (P1)
#   FT-149: git status --porcelain has no generated/test/debug files (P0)
#   FT-150: git check-ignore effective on temp files, git status clean,
#           temp files cleaned with no residue (P0)
#   FT-151: tracked files not harmed - env.example.json, .gitkeep count,
#           pom.xml/bootstrap.yml counts, sources/docs tracked, ignored list
#           contains no in-repo files (P0)
#   FT-152: git check-ignore -v line-number spot check >= 5 path classes (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-gitignore-v0.2.7.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-gitignore-v0.2.7.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
#       .gitignore (UTF-8 with CJK comments) is read via .NET UTF-8 API.
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

# git command output wrapper (cwd = project root); fills $script:GitExit / $script:GitOut
function Invoke-Git {
    param([string[]]$GitArgs)
    $script:GitExit = 1
    try {
        $script:GitOut = (& git @GitArgs 2>&1) -join "`n"
        $script:GitExit = $LASTEXITCODE
    }
    catch {
        $script:GitOut = ""
        $script:GitExit = 1
    }
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.7 .gitignore Governance Unit & FT Test (TASK-009, UT-224~UT-229, FT-149~FT-152)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$gitignorePath = Join-Path $ProjectRoot ".gitignore"
$envExamplePath = Join-Path $ProjectRoot "deploy\env.example.json"
if (-not (Test-FileExists -Path $gitignorePath)) {
    Write-Output "[FAIL] preflight - .gitignore missing at $gitignorePath"
    exit 1
}
$giContent = Read-Utf8File -Path $gitignorePath
$giLines = $giContent -split "`r?`n"
$giTotal = $giLines.Count

# new governance rule lists (23 rules in 4 sections added by TASK-009)
$jvmRules = @("*.hprof", "hs_err_pid*.log", "replay_pid*", "heapdump.*", "*.dmp", "dump/", "*.dump", "derby.log")
$buildRules = @("*.flattened-pom.xml", "*.lastUpdated", "dependency-reduced-pom.xml", "maven-status/")
$reportRules = @("surefire-reports/", "test-output/", "test-results/")
$apiTestRules = @("scripts/API-TEST/*.tmp", "scripts/API-TEST/*.token.json")
$toolRules = @("*.saz", "*.chls", "*.har", "*.history", "*.session", "*.trace")
$allNewRules = @($jvmRules + $buildRules + $reportRules + $apiTestRules + $toolRules)

# forbidden global wildcard lines (would hit in-repo source/config files)
$forbiddenWildcards = @("*.xml", "*.yml", "*.yaml", "*.py", "*.ps1", "*.sh", "*.java", "*.dart", "*.md")

# helper: exact rule line lookup -> line number array
function Get-RuleLineNumbers {
    param([string]$Rule)
    $nums = @()
    for ($i = 0; $i -lt $giLines.Count; $i++) {
        if ($giLines[$i].Trim() -eq $Rule) {
            $nums += ($i + 1)
        }
    }
    return $nums
}

# helper: section comment line numbers (# =====...=====)
$sectionLines = @()
for ($i = 0; $i -lt $giLines.Count; $i++) {
    if ($giLines[$i] -match "^# ={5,}.*=$") {
        $sectionLines += ($i + 1)
    }
}

# ----------------------------------------------------------------------------
# UT-224: JVM / debug artifact rules present (P0)
# ----------------------------------------------------------------------------
$missingJvm = @($jvmRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -eq 0 })
Assert-Test -CaseId "UT-224-1" -Name "JVM/debug artifact rules all present (hprof/hs_err_pid/replay/heapdump/dmp/dump/derby, 8 patterns)" `
    -Condition ($missingJvm.Count -eq 0) `
    -Detail ("missing: " + $(if ($missingJvm.Count -eq 0) { "none" } else { $missingJvm -join ", " }))
$jvmSection = $false
foreach ($s in $sectionLines) {
    if ($s -lt (Get-RuleLineNumbers -Rule "*.hprof")[0]) { $jvmSection = $true }
}
Assert-Test -CaseId "UT-224-2" -Name "JVM section comment exists above rules (# =====...===== style)" `
    -Condition ($jvmSection) `
    -Detail "section comment lines: $($sectionLines -join ',')"

# ----------------------------------------------------------------------------
# UT-225: build / test intermediate artifact rules present (P0)
# ----------------------------------------------------------------------------
$missingBuild = @($buildRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -eq 0 })
Assert-Test -CaseId "UT-225-1" -Name "build/test intermediate artifact rules all present (flattened-pom/lastUpdated/dependency-reduced/maven-status, 4 patterns)" `
    -Condition ($missingBuild.Count -eq 0) `
    -Detail ("missing: " + $(if ($missingBuild.Count -eq 0) { "none" } else { $missingBuild -join ", " }))

# ----------------------------------------------------------------------------
# UT-226: test product & cache rules (P0)
# ----------------------------------------------------------------------------
$missingReport = @($reportRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -eq 0 })
$badSlash = @($reportRules | Where-Object { -not $_.EndsWith("/") })
Assert-Test -CaseId "UT-226-1" -Name "test report dir rules present with trailing slash (surefire-reports/test-output/test-results, 3 patterns)" `
    -Condition ($missingReport.Count -eq 0 -and $badSlash.Count -eq 0) `
    -Detail ("missing: " + $(if ($missingReport.Count -eq 0) { "none" } else { $missingReport -join ", " }) + " ; no-slash: " + $(if ($badSlash.Count -eq 0) { "none" } else { $badSlash -join ", " }))
$missingApi = @($apiTestRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -eq 0 })
$apiDirRules = @($giLines | Where-Object { $_.Trim() -match "^scripts/API-TEST/?$" })
$apiScriptWild = @($giLines | Where-Object { $_.Trim() -match "^scripts/API-TEST/\*\.(py|ps1|sh)$" })
Assert-Test -CaseId "UT-226-2" -Name "API-TEST precise rules present (scripts/API-TEST/*.tmp + *.token.json) and no whole-dir / script wildcard ignore" `
    -Condition ($missingApi.Count -eq 0 -and $apiDirRules.Count -eq 0 -and $apiScriptWild.Count -eq 0) `
    -Detail ("missing: " + $(if ($missingApi.Count -eq 0) { "none" } else { $missingApi -join ", " }) + " ; dir-wildcard: " + $apiDirRules.Count + " ; script-wildcard: " + $apiScriptWild.Count)
$pyCacheOk = ((Get-RuleLineNumbers -Rule "__pycache__/").Count -gt 0 -and (Get-RuleLineNumbers -Rule ".pytest_cache/").Count -gt 0)
Assert-Test -CaseId "UT-226-3" -Name "python test cache rules kept (__pycache__/ and .pytest_cache/)" `
    -Condition ($pyCacheOk) `
    -Detail "pycache lines: $((Get-RuleLineNumbers -Rule '__pycache__/').Count), pytest lines: $((Get-RuleLineNumbers -Rule '.pytest_cache/').Count)"

# ----------------------------------------------------------------------------
# UT-227: tool residue rules present (P0)
# ----------------------------------------------------------------------------
$missingTool = @($toolRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -eq 0 })
Assert-Test -CaseId "UT-227-1" -Name "tool residue rules all present (saz/chls/har/history/session/trace, 6 patterns)" `
    -Condition ($missingTool.Count -eq 0) `
    -Detail ("missing: " + $(if ($missingTool.Count -eq 0) { "none" } else { $missingTool -join ", " }))

# ----------------------------------------------------------------------------
# UT-228: governance red lines (P0)
# ----------------------------------------------------------------------------
$envJsonWild = @($giLines | Where-Object { $_.Trim() -match "^env\.json\*" })
$envJsonExact = (Get-RuleLineNumbers -Rule "env.json").Count
Assert-Test -CaseId "UT-228-1" -Name "no env.json* wildcard rule; env.json stays exact-match" `
    -Condition ($envJsonWild.Count -eq 0 -and $envJsonExact -gt 0) `
    -Detail ("env.json* lines: " + $envJsonWild.Count + " ; env.json exact lines: " + $envJsonExact)
$forbiddenHit = @($forbiddenWildcards | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -gt 0 })
Assert-Test -CaseId "UT-228-2" -Name "no global wildcards *.xml/*.yml/*.yaml/*.py/*.ps1/*.sh/*.java/*.dart/*.md" `
    -Condition ($forbiddenHit.Count -eq 0) `
    -Detail ("forbidden wildcards found: " + $(if ($forbiddenHit.Count -eq 0) { "none" } else { $forbiddenHit -join ", " }))
$webKeep = ((Get-RuleLineNumbers -Rule "!deploy/cloudoffice-flutter-app/web/.gitkeep").Count -gt 0)
$winKeep = ((Get-RuleLineNumbers -Rule "!deploy/cloudoffice-flutter-app/windows/.gitkeep").Count -gt 0)
$webStar = ((Get-RuleLineNumbers -Rule "deploy/cloudoffice-flutter-app/web/*").Count -gt 0)
$winStar = ((Get-RuleLineNumbers -Rule "deploy/cloudoffice-flutter-app/windows/*").Count -gt 0)
Assert-Test -CaseId "UT-228-3" -Name "client build exclusion structure kept (deploy/.../web/* + windows/* + !*.gitkeep whitelist)" `
    -Condition ($webKeep -and $winKeep -and $webStar -and $winStar) `
    -Detail ("web/*=" + $webStar + " windows/*=" + $winStar + " web.gitkeep!=" + $webKeep + " windows.gitkeep!=" + $winKeep)

# UT-228-4: every new rule must NOT match a tracked in-repo file.
# Use git check-ignore --no-index on representative in-repo files; exit code 1
# means NOT ignored (safe). We assert all representative files are not ignored.
Invoke-Git -GitArgs @("check-ignore", "--no-index", "deploy/env.example.json")
$envExampleIgnored = ($script:GitExit -eq 0)
Assert-Test -CaseId "UT-228-4" -Name "new rules must not ignore in-repo files - deploy/env.example.json check-ignore --no-index" `
    -Condition (-not $envExampleIgnored) `
    -Detail ("check-ignore exit: " + $script:GitExit + " (1 = not ignored, safe)")

# more in-repo representative files for UT-228-4 (pom.xml, bootstrap.yml, .gitkeep, java source, test script)
$inRepoReps = @(
    "pom.xml",
    "cloudoffice-common/pom.xml",
    "cloudoffice-gateway/pom.xml",
    "cloudoffice-auth-service/pom.xml",
    "cloudoffice-biz-service/pom.xml",
    "cloudoffice-system-service/pom.xml",
    "cloudoffice-gateway/src/main/resources/bootstrap.yml",
    "cloudoffice-auth-service/src/test/resources/bootstrap.yml",
    "cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/util/.gitkeep",
    "deploy/.gitkeep",
    "deploy/scripts/.gitkeep",
    "deploy/cloudoffice-flutter-app/web/.gitkeep",
    "deploy/cloudoffice-flutter-app/windows/.gitkeep",
    "cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/.gitkeep",
    "scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1",
    "deploy/scripts/load-env.ps1",
    "deploy/scripts/load-env.sh"
)
$dangerHits = @()
foreach ($rep in $inRepoReps) {
    Invoke-Git -GitArgs @("check-ignore", "--no-index", $rep)
    if ($script:GitExit -eq 0) { $dangerHits += $rep }
}
Assert-Test -CaseId "UT-228-4b" -Name "new rules must not ignore in-repo files - representative tracked files all safe (pom/bootstrap/gitkeep/java/scripts, check-ignore --no-index exit 1)" `
    -Condition ($dangerHits.Count -eq 0) `
    -Detail ("dangerously ignored in-repo files: " + $(if ($dangerHits.Count -eq 0) { "none" } else { $dangerHits -join ", " }))

# ----------------------------------------------------------------------------
# UT-229: section comment style, SPDX footer, no duplicate rules (P1)
# ----------------------------------------------------------------------------
$newSectionComments = @($sectionLines | Where-Object { $_ -ge 236 -and $_ -le 351 })
Assert-Test -CaseId "UT-229-1" -Name "new section comments follow # =====...===== style (JVM / build-test / tool residue sections in line range 236~351)" `
    -Condition ($newSectionComments.Count -ge 3) `
    -Detail ("new section comment lines: " + ($newSectionComments -join ","))
$spdxOk = ($giContent -match "SPDX-License-Identifier: Apache-2.0") -and ($giContent -match "Copyright 2026")
Assert-Test -CaseId "UT-229-2" -Name "SPDX-License-Identifier (Apache-2.0) and Copyright footer kept at file end" `
    -Condition ($spdxOk) `
    -Detail "footer lines present in .gitignore"
$dupRules = @($allNewRules | Where-Object { (Get-RuleLineNumbers -Rule $_).Count -gt 1 })
Assert-Test -CaseId "UT-229-3" -Name "no duplicate new rules (each of 23 new patterns appears exactly once)" `
    -Condition ($dupRules.Count -eq 0) `
    -Detail ("duplicated rules: " + $(if ($dupRules.Count -eq 0) { "none" } else { $dupRules -join ", " }))

# ----------------------------------------------------------------------------
# FT-149: git status --porcelain has no generated/test/debug files (P0)
# ----------------------------------------------------------------------------
Invoke-Git -GitArgs @("status", "--porcelain")
$statusBefore = $script:GitOut
$statusHits = @()
foreach ($line in $statusBefore -split "`n") {
    foreach ($pat in $allNewRules) {
        $bare = $pat -replace "/$", ""
        $baseName = ($bare -split "/")[-1]
        if ($baseName -eq "dump" -or $baseName -eq "maven-status") { continue }
        $pattern = [regex]::Escape($baseName)
        $pattern = $pattern -replace "\\\*", ".*"
        if ($line -match $pattern) { $statusHits += "$line <- $pat" }
    }
}
Assert-Test -CaseId "FT-149-1" -Name "git status --porcelain contains no generated/test/debug process files (21 governance patterns, 0 hits)" `
    -Condition ($statusHits.Count -eq 0) `
    -Detail ("hits: " + $(if ($statusHits.Count -eq 0) { "none" } else { ($statusHits | Select-Object -Unique) -join "; " }))

# ----------------------------------------------------------------------------
# FT-150: git check-ignore effective on temp files, clean status, no residue (P0)
# ----------------------------------------------------------------------------
$tempFiles = @(
    "heap.hprof",
    "hs_err_pid12345.log",
    "replay_pid1234",
    "heapdump.bin",
    "x.dmp",
    "cloudoffice-common/x.flattened-pom.xml",
    "cloudoffice-common/x.lastUpdated",
    "cloudoffice-common/dependency-reduced-pom.xml",
    "deploy/surefire-reports/TEST-x.xml",
    "deploy/test-output/index.html",
    "deploy/test-results/x.xml",
    "scripts/API-TEST/x.tmp",
    "scripts/API-TEST/x.token.json",
    "x.saz",
    "x.chls",
    "session.har",
    "x.history",
    "x.session",
    "x.trace",
    "derby.log"
)
$tempDirs = @(
    "deploy/dump",
    "deploy/maven-status"
)
$createdPaths = @()
try {
    foreach ($td in $tempDirs) {
        $dir = Join-Path $ProjectRoot $td
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            $createdPaths += $td
        }
    }
    foreach ($tf in $tempFiles) {
        $path = Join-Path $ProjectRoot $tf
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType File -Path $path -Force | Out-Null
            $createdPaths += $tf
        }
    }
    # dump dir extra file (covers *.dump + dump/ rules)
    $dumpFile = Join-Path $ProjectRoot "deploy\dump\x.dump"
    if (-not (Test-Path -LiteralPath $dumpFile)) {
        New-Item -ItemType File -Path $dumpFile -Force | Out-Null
        $createdPaths += "deploy/dump/x.dump"
    }
    # maven-status extra file
    $mvnFile = Join-Path $ProjectRoot "deploy\maven-status\compile\createdFiles.lst"
    $mvnParent = Split-Path -Parent $mvnFile
    if (-not (Test-Path -LiteralPath $mvnParent)) { New-Item -ItemType Directory -Path $mvnParent -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $mvnFile)) {
        New-Item -ItemType File -Path $mvnFile -Force | Out-Null
        $createdPaths += "deploy/maven-status/compile/createdFiles.lst"
    }

    # FT-150-1: every temp path must be ignored by git check-ignore
    $notIgnored = @()
    $allPaths = $tempFiles + @("deploy/dump/x.dump", "deploy/maven-status/compile/createdFiles.lst")
    foreach ($p in $allPaths) {
        Invoke-Git -GitArgs @("check-ignore", $p)
        if ($script:GitExit -ne 0) { $notIgnored += $p }
    }
    Assert-Test -CaseId "FT-150-1" -Name "git check-ignore returns 0 for all 22 governance-type temp files/dirs (rules really effective)" `
        -Condition ($notIgnored.Count -eq 0) `
        -Detail ("not ignored: " + $(if ($notIgnored.Count -eq 0) { "none" } else { $notIgnored -join ", " }))

    # FT-150-2: git status --porcelain shows none of the temp files
    Invoke-Git -GitArgs @("status", "--porcelain")
    $statusDuring = $script:GitOut
    $tempLeaks = @()
    foreach ($p in $allPaths) {
        $leaf = ($p -split "/")[-1]
        if ($statusDuring -match [regex]::Escape($leaf)) { $tempLeaks += $p }
    }
    Assert-Test -CaseId "FT-150-2" -Name "git status --porcelain shows none of the temp files after creation" `
        -Condition ($tempLeaks.Count -eq 0) `
        -Detail ("leaked: " + $(if ($tempLeaks.Count -eq 0) { "none" } else { $tempLeaks -join ", " }))
}
finally {
    # cleanup all created temp paths (reverse order: files first, dirs last)
    foreach ($p in ($createdPaths | Select-Object -Unique)) {
        $abs = Join-Path $ProjectRoot $p
        if (Test-Path -LiteralPath $abs) {
            Remove-Item -LiteralPath $abs -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
# FT-150-3: workspace restored to pre-test state (git status identical to baseline)
Invoke-Git -GitArgs @("status", "--porcelain")
$statusAfter = $script:GitOut
Assert-Test -CaseId "FT-150-3" -Name "temp files fully cleaned, git status restored to baseline (no test residue)" `
    -Condition ($statusAfter.Trim() -eq $statusBefore.Trim()) `
    -Detail "before/after identical (test created no new untracked residue)"

# ----------------------------------------------------------------------------
# FT-151: tracked in-repo files not harmed (P0)
# ----------------------------------------------------------------------------
Invoke-Git -GitArgs @("ls-files")
$lsFiles = $script:GitOut -split "`n"
$envExampleTracked = ($lsFiles | Where-Object { $_ -eq "deploy/env.example.json" }).Count -gt 0
Assert-Test -CaseId "FT-151-1" -Name "deploy/env.example.json still tracked (git ls-files)" `
    -Condition ($envExampleTracked) `
    -Detail "env.example.json in git ls-files"
$gitkeepAll = @($lsFiles | Where-Object { $_ -match "\.gitkeep$" })
$gitkeepDeploy = @($lsFiles | Where-Object { $_ -match "^deploy/.*\.gitkeep$" })
Assert-Test -CaseId "FT-151-2" -Name ".gitkeep all tracked (count=$($gitkeepAll.Count), deploy count=$($gitkeepDeploy.Count), all deploy .gitkeep present)" `
    -Condition ($gitkeepAll.Count -ge 40 -and $gitkeepDeploy.Count -ge 5) `
    -Detail ("total gitkeep: " + $gitkeepAll.Count + " ; deploy gitkeep: " + $gitkeepDeploy.Count)
$pomCount = @($lsFiles | Where-Object { $_ -match "pom\.xml$" }).Count
$bootstrapCount = @($lsFiles | Where-Object { $_ -match "bootstrap\.yml$" }).Count
Assert-Test -CaseId "FT-151-3" -Name "pom.xml count=$pomCount (6 = root+5 modules), bootstrap.yml count=$bootstrapCount (8 = 4 modules x main/test)" `
    -Condition ($pomCount -eq 6 -and $bootstrapCount -eq 8) `
    -Detail ("pom.xml: " + $pomCount + " ; bootstrap.yml: " + $bootstrapCount + " (actual repo facts; testcase planned 15 as design value)")
$javaCount = @($lsFiles | Where-Object { $_ -match "\.java$" }).Count
$dartCount = @($lsFiles | Where-Object { $_ -match "\.dart$" }).Count
$mdCount = @($lsFiles | Where-Object { $_ -match "\.md$" }).Count
$apiTestTracked = @($lsFiles | Where-Object { $_ -match "^scripts/API-TEST/.*\.(py|ps1)$" }).Count
$deployScriptsTracked = @($lsFiles | Where-Object { $_ -match "^deploy/scripts/.*\.(ps1|sh)$" }).Count
Assert-Test -CaseId "FT-151-4" -Name "sources/docs/scripts all tracked (java=$javaCount dart=$dartCount md=$mdCount apiTest=$apiTestTracked deployScripts=$deployScriptsTracked)" `
    -Condition ($javaCount -gt 0 -and $dartCount -gt 0 -and $mdCount -gt 0 -and $apiTestTracked -gt 0 -and $deployScriptsTracked -gt 0) `
    -Detail ("java=" + $javaCount + " dart=" + $dartCount + " md=" + $mdCount + " apiTest=" + $apiTestTracked + " deployScripts=" + $deployScriptsTracked)
Invoke-Git -GitArgs @("status", "--porcelain", "--ignored")
$ignoredOut = $script:GitOut
$ignoredHits = @()
foreach ($line in $ignoredOut -split "`n") {
    if (-not $line.StartsWith("!!")) { continue }   # only ignored (!!) entries, not untracked (??)
    $pathPart = $line.Substring(3)
    if ($pathPart -match "\.gitkeep$" -or $pathPart -match "pom\.xml$" -or $pathPart -match "bootstrap\.yml$" -or $pathPart -match "env\.example\.json$" -or $pathPart -match "\.java$" -or $pathPart -match "\.dart$" -or $pathPart -match "\.ps1$" -or $pathPart -match "\.py$" -or $pathPart -match "\.sh$") {
        $ignoredHits += $pathPart
    }
}
Assert-Test -CaseId "FT-151-5" -Name "git status --porcelain --ignored contains no in-repo files (gitkeep/pom/bootstrap/env.example/java/dart/scripts, 0 hits)" `
    -Condition ($ignoredHits.Count -eq 0) `
    -Detail ("ignored in-repo paths: " + $(if ($ignoredHits.Count -eq 0) { "none" } else { ($ignoredHits | Select-Object -Unique) -join "; " }))

# ----------------------------------------------------------------------------
# FT-152: git check-ignore -v line-number spot check (P1)
# NOTE: derby.log is excluded on purpose - it is double-covered by the existing
#       *.log rule (L320), git check-ignore -v shows only the last effective
#       rule, so it cannot prove new-rule independence. dump/x.dump proves the
#       new dump/ + *.dump rules instead.
# ----------------------------------------------------------------------------
$spotFiles = @(
    "heap.hprof",
    "cloudoffice-common/x.flattened-pom.xml",
    "cloudoffice-common/dependency-reduced-pom.xml",
    "deploy/dump/x.dump",
    "x.saz",
    "session.har"
)
$newRuleHits = 0
$spotDetail = @()
try {
    foreach ($sf in $spotFiles) {
        $path = Join-Path $ProjectRoot $sf
        if (-not (Test-Path -LiteralPath $path)) {
            $parent = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            New-Item -ItemType File -Path $path -Force | Out-Null
        }
        Invoke-Git -GitArgs @("check-ignore", "-v", $sf)
        $hitLines = $script:GitOut -split "`n"
        $foundNew = $false
        $resolved = ""
        foreach ($hl in $hitLines) {
            $hl = $hl.Trim()
            if ($hl -match "^\.gitignore:(\d+):([^\t]+)") {
                $hitLine = [int]$Matches[1]
                $hitRule = $Matches[2].Trim()
                if ($allNewRules -contains $hitRule) {
                    $foundNew = $true
                    $resolved = "$sf -> L$hitLine $hitRule"
                }
                else {
                    $resolved = "$sf -> L$hitLine $hitRule (fallback rule, not new)"
                }
            }
        }
        if ($foundNew) {
            $newRuleHits++
            $spotDetail += $resolved
        }
        else {
            $spotDetail += $(if ($resolved -eq "") { "$sf -> no -v output" } else { $resolved })
        }
    }
}
finally {
    foreach ($sf in $spotFiles) {
        $abs = Join-Path $ProjectRoot $sf
        if (Test-Path -LiteralPath $abs) {
            Remove-Item -LiteralPath $abs -Recurse -Force -ErrorAction SilentlyContinue
        }
        # remove empty parent dirs created for spot files (e.g. deploy/dump);
        # safe: tracked dirs always contain files/subdirs, empty dir is test residue
        $parent = Split-Path -Parent $abs
        if ((Test-Path -LiteralPath $parent) -and ((Get-ChildItem -LiteralPath $parent -Force | Measure-Object).Count -eq 0)) {
            Remove-Item -LiteralPath $parent -Force -ErrorAction SilentlyContinue
        }
    }
}
Assert-Test -CaseId "FT-152-1" -Name "git check-ignore -v hits new governance rules (>=5 of 6 spot paths resolve to new rule lines)" `
    -Condition ($newRuleHits -ge 5) `
    -Detail ("hits=" + $newRuleHits + "/6 ; " + ($spotDetail -join " | "))

# ----------------------------------------------------------------------------
# summary
# ----------------------------------------------------------------------------
Write-Output ("=" * 70)
Write-Output "Execution done | PASS=$($script:Pass) FAIL=$($script:Fail)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    foreach ($c in $script:FailedCases) {
        Write-Output "  - $c"
    }
}
Write-Output ("=" * 70)
exit $(if ($script:Fail -eq 0) { 0 } else { 1 })
