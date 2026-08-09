# ============================================================================
# CloudStrollOffice (CSO) v0.2.5 - Deploy Acceptance Static Unit Test (TASK-006)
# ----------------------------------------------------------------------------
# Coverage: UT-091 ~ UT-096 in task testcase (docs/cso-v0.2.5/task_TASK-006/testcase.md)
#   UT-091: deploy dir structure complete - env.json, env.example.json and
#           scripts/ sub-dir all present under deploy (P0, AC-1)
#   UT-092: 4 backend final jars landed in deploy, non-empty, contract-named,
#           no same-name clash, matching deploy-start-* script references (P0, AC-2)
#   UT-093: client final artifacts landed in deploy/cloudoffice-flutter-app,
#           windows/ (exe + dll + data) and web/ (index.html + assets) ready,
#           no name clash with backend jars (P1, AC-3)
#   UT-094: no build intermediates inside deploy - blacklist dirs and files
#           (target/build/.dart_tool/__pycache__/surefire-reports, *.class/*.o/
#           *.tmp/*.log/*.obj/*.pdb) all zero-hit (P0, AC-4, negative)
#   UT-095: root env.json and env.example.json removed, no residue (P0, AC-5, negative)
#   UT-096: all 21 .sh/.ps1 (10 sh + 11 ps1) live in deploy/scripts, no .sh/.ps1
#           residue under root scripts, non-script content (sql/docker/API-TEST/
#           deployment-guide.md) stays in place and NOT migrated into
#           deploy/scripts (P0, AC-6, negative)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-acceptance-v0.2.5.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-acceptance-v0.2.5.ps1 -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
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

Write-Output ("=" * 70)
Write-Output "CSO v0.2.5 Deploy Acceptance Static Unit Test (TASK-006, UT-091~UT-096)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$deployPath = Join-Path $ProjectRoot "deploy"
$deployScripts = Join-Path $deployPath "scripts"
$rootScripts = Join-Path $ProjectRoot "scripts"

# ----------------------------------------------------------------------------
# UT-091: deploy directory structure complete (P0, AC-1)
# ----------------------------------------------------------------------------
$deployIsDir = Test-Path -LiteralPath $deployPath -PathType Container
$scriptsIsDir = Test-Path -LiteralPath $deployScripts -PathType Container
$envJsonPath = Join-Path $deployPath "env.json"
$envExamplePath = Join-Path $deployPath "env.example.json"
$envJsonIsFile = Test-Path -LiteralPath $envJsonPath -PathType Leaf
$envExampleIsFile = Test-Path -LiteralPath $envExamplePath -PathType Leaf
Assert-Test -CaseId "UT-091-1" -Name "deploy exists and is a container" `
    -Condition $deployIsDir -Detail "Path: $deployPath"
Assert-Test -CaseId "UT-091-2" -Name "deploy/scripts exists and is a container" `
    -Condition $scriptsIsDir -Detail "Path: $deployScripts"
Assert-Test -CaseId "UT-091-3" -Name "deploy/env.json exists and is a file" `
    -Condition $envJsonIsFile -Detail "Path: $envJsonPath"
Assert-Test -CaseId "UT-091-4" -Name "deploy/env.example.json exists and is a file" `
    -Condition $envExampleIsFile -Detail "Path: $envExamplePath"

# ----------------------------------------------------------------------------
# UT-092: 4 backend final jars in deploy, contract-named (P0, AC-2)
# ----------------------------------------------------------------------------
$contractJars = @(
    "cloudoffice-auth-service.jar",
    "cloudoffice-biz-service.jar",
    "cloudoffice-system-service.jar",
    "cloudoffice-gateway.jar"
)
$missingJars = @($contractJars | Where-Object { -not (Test-Path -LiteralPath (Join-Path $deployPath $_) -PathType Leaf) })
$emptyJars = @()
$jarSizes = @()
foreach ($jar in $contractJars) {
    $jarPath = Join-Path $deployPath $jar
    if (Test-Path -LiteralPath $jarPath -PathType Leaf) {
        $size = (Get-Item -LiteralPath $jarPath).Length
        $jarSizes += "$jar=$size"
        if ($size -le 0) { $emptyJars += $jar }
    }
}
Assert-Test -CaseId "UT-092-1" -Name "all 4 contract backend jars exist under deploy" `
    -Condition ($missingJars.Count -eq 0) `
    -Detail "missing: $($missingJars -join ', ')"
Assert-Test -CaseId "UT-092-2" -Name "all 4 jars non-empty (>0 bytes)" `
    -Condition ($emptyJars.Count -eq 0) `
    -Detail "sizes: $($jarSizes -join '; ')"
$uniqueJars = @($contractJars | Sort-Object -Unique).Count
Assert-Test -CaseId "UT-092-3" -Name "4 jar names distinct, no same-name overwrite" `
    -Condition ($uniqueJars -eq 4) -Detail "unique: $uniqueJars/4"

# Contract check: deploy-start-{auth,biz,system,gateway}.sh/.ps1 reference
# the exact contract jar names and never the module target/ path.
$scriptRefOk = $true
$scriptRefDetail = @()
$startShortMap = @{
    "auth"    = "cloudoffice-auth-service.jar"
    "biz"     = "cloudoffice-biz-service.jar"
    "system"  = "cloudoffice-system-service.jar"
    "gateway" = "cloudoffice-gateway.jar"
}
foreach ($short in $startShortMap.Keys) {
    $contract = $startShortMap[$short]
    $shFile = Join-Path $deployScripts "deploy-start-$short.sh"
    $ps1File = Join-Path $deployScripts "deploy-start-$short.ps1"
    $shOk = $false
    $ps1Ok = $false
    if (Test-Path -LiteralPath $shFile -PathType Leaf) {
        $shContent = Get-Content -Raw -LiteralPath $shFile
        $shOk = ($shContent -match [regex]::Escape($contract)) -and
               ($shContent -notmatch 'cloudoffice-[a-z]+[\\/]target')
    }
    if (Test-Path -LiteralPath $ps1File -PathType Leaf) {
        $ps1Content = Get-Content -Raw -LiteralPath $ps1File
        $ps1Ok = ($ps1Content -match [regex]::Escape($contract)) -and
                 ($ps1Content -notmatch 'cloudoffice-[a-z]+[\\/]target')
    }
    if (-not ($shOk -and $ps1Ok)) { $scriptRefOk = $false }
    $scriptRefDetail += "$short(sh:$shOk,ps1:$ps1Ok)"
}
Assert-Test -CaseId "UT-092-4" -Name "deploy-start-* scripts reference exact contract jar names (no target/ path)" `
    -Condition $scriptRefOk -Detail ($scriptRefDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-093: client final artifacts under deploy/cloudoffice-flutter-app (P1, AC-3)
# ----------------------------------------------------------------------------
$clientDeployDir = Join-Path $deployPath "cloudoffice-flutter-app"
$clientDirOk = Test-Path -LiteralPath $clientDeployDir -PathType Container
Assert-Test -CaseId "UT-093-1" -Name "deploy/cloudoffice-flutter-app exists and is a container" `
    -Condition $clientDirOk -Detail "Path: $clientDeployDir"

$winDir = Join-Path $clientDeployDir "windows"
$winOk = Test-Path -LiteralPath $winDir -PathType Container
$exeFiles = @(Get-ChildItem -LiteralPath $winDir -File -Filter "*.exe" -ErrorAction SilentlyContinue)
$exeNonEmpty = @($exeFiles | Where-Object { $_.Length -gt 0 }).Count -gt 0
$dllFiles = @(Get-ChildItem -LiteralPath $winDir -File -Filter "*.dll" -ErrorAction SilentlyContinue)
$dllNonEmpty = @($dllFiles | Where-Object { $_.Length -gt 0 }).Count -gt 0
$dataDirOk = Test-Path -LiteralPath (Join-Path $winDir "data") -PathType Container
Assert-Test -CaseId "UT-093-2" -Name "windows/ has non-empty .exe, dependency .dll and data/" `
    -Condition ($winOk -and $exeNonEmpty -and $dllNonEmpty -and $dataDirOk) `
    -Detail "exe: $($exeFiles.Count) ($($exeFiles.Name -join ', ')), dll: $($dllFiles.Count), data/: $dataDirOk"

$webDir = Join-Path $clientDeployDir "web"
$webOk = Test-Path -LiteralPath $webDir -PathType Container
$indexHtml = Join-Path $webDir "index.html"
$indexOk = (Test-Path -LiteralPath $indexHtml -PathType Leaf) -and ((Get-Item -LiteralPath $indexHtml -ErrorAction SilentlyContinue).Length -gt 0)
$webAssetsOk = Test-Path -LiteralPath (Join-Path $webDir "assets") -PathType Container
Assert-Test -CaseId "UT-093-3" -Name "web/ has non-empty index.html and assets/" `
    -Condition ($webOk -and $indexOk -and $webAssetsOk) `
    -Detail "index.html: $indexOk, assets/: $webAssetsOk"

# No name clash: no *.exe / *.dll at deploy top level (client artifacts live
# inside cloudoffice-flutter-app subtree only, separated from backend jars).
$topExe = @(Get-ChildItem -LiteralPath $deployPath -File -Filter "*.exe" -ErrorAction SilentlyContinue)
$topDll = @(Get-ChildItem -LiteralPath $deployPath -File -Filter "*.dll" -ErrorAction SilentlyContinue)
Assert-Test -CaseId "UT-093-4" -Name "no client artifact name clash at deploy top level (exe/dll isolated in subtree)" `
    -Condition ($topExe.Count -eq 0 -and $topDll.Count -eq 0) `
    -Detail "top exe: $($topExe.Count), top dll: $($topDll.Count)"

# ----------------------------------------------------------------------------
# UT-094: no build intermediates inside deploy (P0, AC-4, negative)
# ----------------------------------------------------------------------------
$dirBlacklist = @("target", "build", ".dart_tool", "__pycache__", "surefire-reports", "CMakeFiles")
$fileExtBlacklist = @(".class", ".o", ".tmp", ".log", ".obj", ".pdb", ".ilk", ".vcxproj")
$badDirs = @()
if (Test-Path -LiteralPath $deployPath) {
    $badDirs = @(Get-ChildItem -LiteralPath $deployPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $dirBlacklist -contains $_.Name })
}
$badFiles = @()
if (Test-Path -LiteralPath $deployPath) {
    $badFiles = @(Get-ChildItem -LiteralPath $deployPath -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $fileExtBlacklist -contains $_.Extension.ToLower() })
}
Assert-Test -CaseId "UT-094-1" -Name "no blacklisted intermediate dirs (target/build/.dart_tool/__pycache__/surefire-reports/CMakeFiles)" `
    -Condition ($badDirs.Count -eq 0) `
    -Detail "hit dirs: $($badDirs.FullName -join '; ')"
Assert-Test -CaseId "UT-094-2" -Name "no blacklisted intermediate files (*.class/*.o/*.tmp/*.log/*.obj/*.pdb/*.ilk/*.vcxproj)" `
    -Condition ($badFiles.Count -eq 0) `
    -Detail "hit files: $($badFiles.FullName -join '; ')"

# ----------------------------------------------------------------------------
# UT-095: root env.json / env.example.json removed, no residue (P0, AC-5, negative)
# ----------------------------------------------------------------------------
$rootEnvJson = Join-Path $ProjectRoot "env.json"
$rootEnvExample = Join-Path $ProjectRoot "env.example.json"
Assert-Test -CaseId "UT-095-1" -Name "root env.json no longer exists (no residue)" `
    -Condition (-not (Test-Path -LiteralPath $rootEnvJson)) -Detail "Path checked: $rootEnvJson"
Assert-Test -CaseId "UT-095-2" -Name "root env.example.json no longer exists (no residue)" `
    -Condition (-not (Test-Path -LiteralPath $rootEnvExample)) -Detail "Path checked: $rootEnvExample"
Assert-Test -CaseId "UT-095-3" -Name "positive counterpart: deploy/env.json and deploy/env.example.json present" `
    -Condition ($envJsonIsFile -and $envExampleIsFile) `
    -Detail "deploy/env.json: $envJsonIsFile, deploy/env.example.json: $envExampleIsFile"

# ----------------------------------------------------------------------------
# UT-096: 21 scripts in deploy/scripts, no residue, non-script content in place
#         (P0, AC-6, negative)
# ----------------------------------------------------------------------------
$shCount = @(Get-ChildItem -LiteralPath $deployScripts -File -Filter "*.sh" -ErrorAction SilentlyContinue).Count
$ps1Count = @(Get-ChildItem -LiteralPath $deployScripts -File -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
Assert-Test -CaseId "UT-096-1" -Name "deploy/scripts has 10 .sh + 11 .ps1 = 21 scripts" `
    -Condition ($shCount -eq 10 -and $ps1Count -eq 11) `
    -Detail "sh=$shCount ps1=$ps1Count (expected sh=10 ps1=11)"

$scriptNames = @(
    "load-env.sh", "load-env.ps1",
    "deploy-check-env.sh", "deploy-check-env.ps1",
    "deploy-db-init.sh", "deploy-db-init.ps1",
    "deploy-env.ps1",
    "deploy-env-template.sh", "deploy-env-template.ps1",
    "deploy-rsa-keygen.sh", "deploy-rsa-keygen.ps1",
    "deploy-start-auth.sh", "deploy-start-auth.ps1",
    "deploy-start-biz.sh", "deploy-start-biz.ps1",
    "deploy-start-gateway.sh", "deploy-start-gateway.ps1",
    "deploy-start-services.sh", "deploy-start-services.ps1",
    "deploy-start-system.sh", "deploy-start-system.ps1"
)
$missingScripts = @($scriptNames | Where-Object { -not (Test-Path -LiteralPath (Join-Path $deployScripts $_) -PathType Leaf) })
Assert-Test -CaseId "UT-096-2" -Name "every one of the 21 expected scripts exists as a file" `
    -Condition ($missingScripts.Count -eq 0) `
    -Detail "missing: $($missingScripts -join ', ')"

# Negative: no .sh/.ps1 residue at root scripts top level (non-recursive).
$rootResidue = @()
if (Test-Path -LiteralPath $rootScripts) {
    $rootResidue = @(Get-ChildItem -LiteralPath $rootScripts -File |
        Where-Object { $_.Extension -in @(".sh", ".ps1") })
}
Assert-Test -CaseId "UT-096-3" -Name "no .sh/.ps1 residue at root scripts top level" `
    -Condition ($rootResidue.Count -eq 0) `
    -Detail "residue: $($rootResidue.Name -join ', ')"

# Negative: non-script content stays in place AND is NOT migrated into deploy/scripts.
$sqlDir = Join-Path $rootScripts "sql"
$dockerDir = Join-Path $rootScripts "docker"
$apiTestDir = Join-Path $rootScripts "API-TEST"
$guideFile = Join-Path $rootScripts "deployment-guide.md"
$sqlInPlace = Test-Path -LiteralPath $sqlDir -PathType Container
$dockerInPlace = Test-Path -LiteralPath $dockerDir -PathType Container
$apiTestInPlace = Test-Path -LiteralPath $apiTestDir -PathType Container
$guideInPlace = Test-Path -LiteralPath $guideFile -PathType Leaf
Assert-Test -CaseId "UT-096-4" -Name "non-script content stays in place (scripts/sql, scripts/docker, scripts/API-TEST, deployment-guide.md)" `
    -Condition ($sqlInPlace -and $dockerInPlace -and $apiTestInPlace -and $guideInPlace) `
    -Detail "sql:$sqlInPlace docker:$dockerInPlace API-TEST:$apiTestInPlace guide:$guideInPlace"

$deployNonScript = @(Get-ChildItem -LiteralPath $deployScripts -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -notin @(".sh", ".ps1") -and $_.Name -ne ".gitkeep" })
Assert-Test -CaseId "UT-096-5" -Name "no non-script content migrated into deploy/scripts (only 21 scripts + .gitkeep)" `
    -Condition ($deployNonScript.Count -eq 0) `
    -Detail "extra non-script: $($deployNonScript.Name -join ', ')"

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
