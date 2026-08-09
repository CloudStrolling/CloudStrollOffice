# ============================================================================
# CloudStrollOffice (CSO) v0.2.5 - Scripts Migration Unit Test (TASK-003)
# ----------------------------------------------------------------------------
# Coverage: UT-073 ~ UT-078 in task testcase (docs/cso-v0.2.5/task_TASK-003/testcase.md)
#   UT-073: deploy/scripts contains all 21 scripts (10 .sh + 11 .ps1), all files (P0)
#   UT-074: no .sh/.ps1 residue under root scripts (excluding scripts/API-TEST) (P0, negative)
#   UT-075: non-script content under scripts stays in place (P0, negative)
#   UT-076: 21 scripts tracked by git under deploy/scripts, old paths untracked,
#           rename history preserved (git mv, staged R status or git log --follow) (P1)
#   UT-077: no stale path references left in migrated scripts (P1, negative/consistency)
#   UT-078: load-env scripts still derive PROJECT_DIR from own location, so env.json
#           resolves to deploy/env.json automatically (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-scripts-migrate-v0.2.5.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-scripts-migrate-v0.2.5.ps1 -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
# NOTE: Security - this script NEVER prints the content of any migrated script
#       (deploy-env.ps1 contains real secrets tracked by git historically).
#       UT-077 only reports matched pattern + line number, not line content.
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

Write-Output "=" * 70
Write-Output "CSO v0.2.5 Scripts Migration Unit Test (TASK-003, UT-073~UT-078)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "=" * 70

$deployScripts = Join-Path $ProjectRoot "deploy\scripts"
$rootScripts = Join-Path $ProjectRoot "scripts"

# Expected script list (21 scripts, 10 .sh + 11 .ps1, same names as pre-migration)
$scriptNames = @(
    "load-env.sh", "load-env.ps1",
    "deploy-check-env.sh", "deploy-check-env.ps1",
    "deploy-db-init.sh", "deploy-db-init.ps1",
    "deploy-env.ps1",
    "deploy-env-template.sh", "deploy-env-template.ps1",
    "deploy-rsa-keygen.sh", "deploy-rsa-keygen.ps1",
    "deploy-start-auth.sh", "deploy-start-auth.ps1",
    "deploy-start-gateway.sh", "deploy-start-gateway.ps1",
    "deploy-start-biz.sh", "deploy-start-biz.ps1",
    "deploy-start-system.sh", "deploy-start-system.ps1",
    "deploy-start-services.sh", "deploy-start-services.ps1"
)

# ----------------------------------------------------------------------------
# UT-073: deploy/scripts contains all 21 scripts, all file type (P0)
# ----------------------------------------------------------------------------
$shCount = @(Get-ChildItem -LiteralPath $deployScripts -File -Filter "*.sh" -ErrorAction SilentlyContinue).Count
$ps1Count = @(Get-ChildItem -LiteralPath $deployScripts -File -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
Assert-Test -CaseId "UT-073-1" -Name "10 .sh + 11 .ps1 = 21 scripts under deploy/scripts" `
    -Condition ($shCount -eq 10 -and $ps1Count -eq 11) `
    -Detail "sh=$shCount ps1=$ps1Count (expected sh=10 ps1=11)"

$missing = @($scriptNames | Where-Object { -not (Test-Path -LiteralPath (Join-Path $deployScripts $_) -PathType Leaf) })
Assert-Test -CaseId "UT-073-2" -Name "every one of the 21 expected scripts exists as a file" `
    -Condition ($missing.Count -eq 0) `
    -Detail "missing: $($missing -join ', ')"

$extra = @(Get-ChildItem -LiteralPath $deployScripts -File | Where-Object { $_.Extension -in @(".sh", ".ps1") -and $scriptNames -notcontains $_.Name })
Assert-Test -CaseId "UT-073-3" -Name "no extra .sh/.ps1 beyond the expected 21" `
    -Condition ($extra.Count -eq 0) `
    -Detail "extra: $($extra.Name -join ', ')"

# ----------------------------------------------------------------------------
# UT-074: no .sh/.ps1 residue under root scripts (P0, negative)
#   Scope: root scripts itself + its sub-dirs EXCEPT scripts/API-TEST which is
#   test asset kept in place by design (AC-6: non sh/ps1 content stays).
# ----------------------------------------------------------------------------
$residue = @()
if (Test-Path -LiteralPath $rootScripts) {
    $residue = @(Get-ChildItem -LiteralPath $rootScripts -Recurse -File |
        Where-Object {
            $_.Extension -in @(".sh", ".ps1") -and
            $_.FullName -notlike "*$([System.IO.Path]::DirectorySeparatorChar)API-TEST*"
        })
}
Assert-Test -CaseId "UT-074" -Name "no .sh/.ps1 residue under scripts (API-TEST excluded)" `
    -Condition ($residue.Count -eq 0) `
    -Detail "residue count: $($residue.Count) $($residue.FullName -join '; ')"

# ----------------------------------------------------------------------------
# UT-075: non-script content under scripts stays in place (P0, negative)
# ----------------------------------------------------------------------------
$sqlDir = Join-Path $rootScripts "sql"
$dockerDir = Join-Path $rootScripts "docker"
$apiTestDir = Join-Path $rootScripts "API-TEST"
$guideFile = Join-Path $rootScripts "deployment-guide.md"
$sqlOk = Test-Path -LiteralPath $sqlDir -PathType Container
$sqlFiles = @(Get-ChildItem -LiteralPath $sqlDir -File -Filter "*.sql" -ErrorAction SilentlyContinue)
$sqlCountOk = $sqlFiles.Count -eq 4
$dockerOk = Test-Path -LiteralPath $dockerDir -PathType Container
$dockerComposeOk = Test-Path -LiteralPath (Join-Path $dockerDir "docker-compose.yml") -PathType Leaf
$dockerDockerfiles = @(Get-ChildItem -LiteralPath $dockerDir -Recurse -File -Filter "Dockerfile" -ErrorAction SilentlyContinue)
$dockerFilesOk = $dockerDockerfiles.Count -eq 4
$apiTestOk = Test-Path -LiteralPath $apiTestDir -PathType Container
$guideOk = Test-Path -LiteralPath $guideFile -PathType Leaf
Assert-Test -CaseId "UT-075-1" -Name "scripts/sql container with 4 sql files in place" `
    -Condition ($sqlOk -and $sqlCountOk) `
    -Detail "sql dir: $sqlOk, sql files: $($sqlFiles.Count)/4"
Assert-Test -CaseId "UT-075-2" -Name "scripts/docker container with compose + 4 Dockerfiles in place" `
    -Condition ($dockerOk -and $dockerComposeOk -and $dockerFilesOk) `
    -Detail "docker dir: $dockerOk, compose: $dockerComposeOk, Dockerfiles: $($dockerDockerfiles.Count)/4"
Assert-Test -CaseId "UT-075-3" -Name "scripts/API-TEST container in place" `
    -Condition $apiTestOk -Detail "path: $apiTestDir"
Assert-Test -CaseId "UT-075-4" -Name "scripts/deployment-guide.md file in place" `
    -Condition $guideOk -Detail "path: $guideFile"

# ----------------------------------------------------------------------------
# UT-076: git tracking & history preservation (P1)
#   Two states supported:
#     a) migration committed: git log --follow on deploy/scripts/load-env.sh
#        must trace history (rename recognized);
#     b) migration staged (not committed yet): git diff --cached -M shows
#        R (rename) status for the 21 files -> proves git mv used, history
#        will be traceable after commit.
# ----------------------------------------------------------------------------
$trackedNew = @(& git ls-files "deploy/scripts" | Where-Object { $_ -match '\.(sh|ps1)$' })
$trackedCount = $trackedNew.Count
$oldTracked = @(& git ls-files "scripts" | Where-Object { $_ -match '\.(sh|ps1)$' -and $_ -notmatch '^scripts/API-TEST/' })
$oldGone = $oldTracked.Count -eq 0
Assert-Test -CaseId "UT-076-1" -Name "21 scripts tracked under deploy/scripts by git" `
    -Condition ($trackedCount -eq 21) `
    -Detail "tracked: $trackedCount/21"
Assert-Test -CaseId "UT-076-2" -Name "old root scripts paths untracked (no duplicates)" `
    -Condition $oldGone `
    -Detail "old tracked .sh/.ps1: $($oldTracked -join ', ')"

$historyOk = $false
$historyDetail = "no trace performed"
$headHasDeployScripts = @(& git ls-tree -r --name-only HEAD | Where-Object { $_ -match '^deploy/scripts/.+\.(sh|ps1)$' }).Count -gt 0
if ($headHasDeployScripts) {
    # State (a): migration already committed -> verify follow history on sample
    $logOut = @(& git log --oneline --follow -- "deploy/scripts/load-env.sh") 2>$null
    $logOut = @($logOut | Where-Object { $_ })
    $historyOk = $logOut.Count -gt 0
    $historyDetail = "committed state: git log --follow returned $($logOut.Count) commits"
}
else {
    # State (b): migration staged -> verify rename detection (git mv evidence)
    # NOTE: do NOT pass a path filter here -- with a path filter git reports the
    # new path as plain A (added) and rename detection is suppressed. Run without
    # filter and match entries whose new path starts with deploy/scripts.
    $nameStatus = @(& git diff --cached --name-status -M) 2>$null
    $nameStatus = @($nameStatus | Where-Object { $_ })
    $renamed = @($nameStatus | Where-Object {
        $_ -match '^R' -and $_ -match 'deploy/scripts/.*\.(sh|ps1)$' -and $_ -notmatch '^R.*\t.*\t.*\t' })
    $historyOk = $renamed.Count -eq 21
    $historyDetail = "staged state: rename entries $($renamed.Count)/21 (git mv evidence)"
}
Assert-Test -CaseId "UT-076-3" -Name "rename history preserved (git mv evidence or --follow trace)" `
    -Condition $historyOk -Detail $historyDetail

# ----------------------------------------------------------------------------
# UT-077: no stale path references inside migrated scripts (P1, negative)
#   Forbidden patterns (case-insensitive) that would break after migration:
#     - $PROJECT_DIR/scripts/  or  $ProjectDir\scripts\   (old SQL dir ref)
#     - any $VAR/scripts/ ref except ROOT_DIR/RootDir root-derivation
#     - cloudoffice-*/target/  (old jar path to module target)
#     - ./scripts/... or .\scripts\... (old comment refs)
#   Positive checks:
#     - deploy-db-init.sh/ps1 derive ROOT_DIR/RootDir and use root scripts/sql
#     - deploy-start-{auth,gateway,biz,system}.sh/ps1 point jar to deploy artifacts
# ----------------------------------------------------------------------------
$scriptFiles = @(Get-ChildItem -LiteralPath $deployScripts -File | Where-Object { $_.Extension -in @(".sh", ".ps1") })
$staleHits = @()
foreach ($f in $scriptFiles) {
    $lines = @(Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if (-not $line) { continue }
        # 1) literal old PROJECT_DIR/scripts refs (sh) / $ProjectDir\scripts\ (ps1)
        if ($line -match '\$PROJECT_DIR[\\/]scripts[\\/]' -or $line -match '\$ProjectDir\\scripts\\') {
            $staleHits += "$($f.Name):$($i+1) [old PROJECT_DIR/scripts ref]"
            continue
        }
        # 2) any variable-based scripts/ ref that is NOT ROOT_DIR/RootDir derivation
        if ($line -match '\$\{?[A-Za-z_][A-Za-z0-9_]*\}?[\\/]scripts[\\/]') {
            if ($line -notmatch 'ROOT_DIR|RootDir') {
                $staleHits += "$($f.Name):$($i+1) [stale var scripts/ ref]"
                continue
            }
        }
        # 3) old jar path via module target dir
        if ($line -match 'cloudoffice-[a-z]+[\\/]target[\\/]' -or $line -match '\$PROJECT_DIR[\\/]cloudoffice-[a-z]+[\\/]target') {
            $staleHits += "$($f.Name):$($i+1) [old target jar path]"
            continue
        }
        # 4) old relative scripts/ refs in comments/docs
        if ($line -match '\./scripts/deploy-rsa-keygen' -or $line -match '\.\\scripts\\deploy-rsa-keygen' -or $line -match '\./scripts/' -or $line -match '\.\\scripts\\') {
            $staleHits += "$($f.Name):$($i+1) [old ./scripts ref]"
            continue
        }
    }
}
Assert-Test -CaseId "UT-077-1" -Name "no stale path references in any of the 21 scripts" `
    -Condition ($staleHits.Count -eq 0) `
    -Detail ($staleHits -join "; ")

$dbInitSh = Join-Path $deployScripts "deploy-db-init.sh"
$dbInitPs1 = Join-Path $deployScripts "deploy-db-init.ps1"
$dbShContent = Get-Content -Raw -LiteralPath $dbInitSh
$dbPs1Content = Get-Content -Raw -LiteralPath $dbInitPs1
$dbInitShOk = ($dbShContent -match 'ROOT_DIR="\$\(dirname "\$PROJECT_DIR"\)"') -and
              ($dbShContent -match 'SQL_DIR="\$ROOT_DIR/scripts/sql"')
$dbInitPs1Ok = ($dbPs1Content -match '\$RootDir = Split-Path -Parent \$ProjectDir') -and
               ($dbPs1Content -match 'Join-Path \$RootDir "scripts\\sql\\')
Assert-Test -CaseId "UT-077-2" -Name "deploy-db-init scripts derive root and point to root scripts/sql" `
    -Condition ($dbInitShOk -and $dbInitPs1Ok) `
    -Detail "sh root-derivation: $dbInitShOk, ps1 root-derivation: $dbInitPs1Ok"

$startModules = @("auth", "gateway", "biz", "system")
$jarRefsOk = $true
$jarDetail = @()
foreach ($m in $startModules) {
    $sh = Join-Path $deployScripts "deploy-start-$m.sh"
    $ps1 = Join-Path $deployScripts "deploy-start-$m.ps1"
    $shContent = Get-Content -Raw -LiteralPath $sh
    $ps1Content = Get-Content -Raw -LiteralPath $ps1
    # jar artifact names: auth/biz/system = cloudoffice-{m}-service.jar,
    #                     gateway = cloudoffice-gateway.jar (no -service suffix)
    $shOk = $shContent -match ('JAR_PATH="\$PROJECT_DIR/cloudoffice-' + $m + '(-service)?\.jar"') -and
            $shContent -notmatch 'cloudoffice-[a-z]+[\\/]target'
    $ps1Ok = $ps1Content -match ('Join-Path \$ProjectDir "cloudoffice-' + $m + '(-service)?\.jar"') -and
             $ps1Content -notmatch 'cloudoffice-[a-z]+[\\/]target'
    if (-not ($shOk -and $ps1Ok)) { $jarRefsOk = $false }
    $jarDetail += "$m(sh:$shOk,ps1:$ps1Ok)"
}
Assert-Test -CaseId "UT-077-3" -Name "deploy-start-* scripts point jar to deploy artifacts (no target/)" `
    -Condition $jarRefsOk -Detail ($jarDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-078: load-env mechanism preserved, auto-resolves deploy/env.json (P1)
# ----------------------------------------------------------------------------
$loadEnvSh = Join-Path $deployScripts "load-env.sh"
$loadEnvPs1 = Join-Path $deployScripts "load-env.ps1"
$shContent = Get-Content -Raw -LiteralPath $loadEnvSh
$ps1Content = Get-Content -Raw -LiteralPath $loadEnvPs1
$shOk = $shContent -match '\$\{BASH_SOURCE\[0\]\}' -and
        $shContent -match 'PROJECT_DIR="\$\(dirname "\$SCRIPT_DIR"\)"' -and
        $shContent -match 'ENV_FILE_PATH="\$PROJECT_DIR/\$ENV_FILE"'
$ps1Ok = $ps1Content -match '\$PSScriptRoot' -and
         $ps1Content -match '\$ProjectDir = Split-Path -Parent \$PSScriptRoot' -and
         $ps1Content -match 'Join-Path \$ProjectDir \$EnvFile'
Assert-Test -CaseId "UT-078-1" -Name "load-env.sh derives PROJECT_DIR from own script dir (BASH_SOURCE)" `
    -Condition $shOk -Detail "BASH_SOURCE[0] + dirname PROJECT_DIR + ENV_FILE_PATH pattern"
Assert-Test -CaseId "UT-078-2" -Name "load-env.ps1 derives ProjectDir from PSScriptRoot parent" `
    -Condition $ps1Ok -Detail "PSScriptRoot + Split-Path -Parent + Join-Path pattern"

# Static derivation: scripts live in deploy/scripts -> PROJECT_DIR = deploy ->
# ENV_FILE_PATH = deploy/env.json (matches TASK-002 migrated location)
$envJsonInDeploy = Test-Path -LiteralPath (Join-Path $ProjectRoot "deploy\env.json") -PathType Leaf
Assert-Test -CaseId "UT-078-3" -Name "derivation: PROJECT_DIR=deploy -> deploy/env.json (present)" `
    -Condition $envJsonInDeploy -Detail "deploy/env.json exists, load-env will auto-resolve it"

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
Write-Output "=" * 70
Write-Output "Summary: PASS=$($script:Pass) FAIL=$($script:Fail)"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    $script:FailedCases | ForEach-Object { Write-Output "  - $_" }
}
Write-Output "=" * 70
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
