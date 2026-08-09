# ============================================================================
# CloudStrollOffice (CSO) v0.2.5 - Build Output to deploy Unit Test (TASK-004)
# ----------------------------------------------------------------------------
# Coverage: UT-079 ~ UT-084 in task testcase (docs/cso-v0.2.5/task_TASK-004/testcase.md)
#   UT-079: root pom.xml defines deployDir property pointing to root deploy (P0)
#   UT-080: 4 executable modules configure copy plugin at package phase,
#           declared AFTER spring-boot-maven-plugin, using <target> syntax (P0)
#   UT-081: deploy artifact names match deploy-start-* script contract (P0)
#   UT-082: single-file copy only with overwrite=true, no whole-dir recursion (P0, negative)
#   UT-083: common module has no copy/deploy output config (P1, negative)
#   UT-084: deploy *.jar ignored by git, only .gitkeep tracked (P1, negative/SCM)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-build-deploy-v0.2.5.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-build-deploy-v0.2.5.ps1 -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
# NOTE: Regex literals use single quotes; "${...}" in regex is escaped as
#       \$\{...\} because ${name} would be parsed as a named backreference.
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
Write-Output "CSO v0.2.5 Build Output to deploy Unit Test (TASK-004, UT-079~UT-084)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$rootPom = Join-Path $ProjectRoot "pom.xml"
$moduleDirs = @(
    "cloudoffice-gateway",
    "cloudoffice-auth-service",
    "cloudoffice-biz-service",
    "cloudoffice-system-service"
)
# Contract map: module dir -> expected deploy artifact file name
$contractMap = @{
    "cloudoffice-gateway"       = "cloudoffice-gateway.jar"
    "cloudoffice-auth-service"  = "cloudoffice-auth-service.jar"
    "cloudoffice-biz-service"   = "cloudoffice-biz-service.jar"
    "cloudoffice-system-service" = "cloudoffice-system-service.jar"
}
# Start-script short name map: module dir -> deploy-start-<short>.sh/.ps1
$scriptShortMap = @{
    "cloudoffice-gateway"       = "gateway"
    "cloudoffice-auth-service"  = "auth"
    "cloudoffice-biz-service"   = "biz"
    "cloudoffice-system-service" = "system"
}

# ----------------------------------------------------------------------------
# UT-079: root pom.xml defines deployDir property pointing to root deploy (P0)
# ----------------------------------------------------------------------------
$rootContent = Get-Content -Raw -LiteralPath $rootPom
$deployDirDecl = [regex]::Match($rootContent, '<deployDir>\s*([^<]+?)\s*</deployDir>')
$deployDirExists = $deployDirDecl.Success
$deployDirValue = if ($deployDirDecl.Success) { $deployDirDecl.Groups[1].Value.Trim() } else { "" }
$expectedDeployDir = '${maven.multiModuleProjectDirectory}/deploy'
$deployDirOk = $deployDirValue -eq $expectedDeployDir
Assert-Test -CaseId "UT-079-1" -Name "root pom defines deployDir property" `
    -Condition $deployDirExists -Detail "path: $rootPom"
Assert-Test -CaseId "UT-079-2" -Name "deployDir is rooted via maven.multiModuleProjectDirectory" `
    -Condition ($deployDirExists -and $deployDirOk) `
    -Detail "value: '$deployDirValue' (expected '$expectedDeployDir')"
$deployTargetName = if ($deployDirValue -match 'deploy$') { "deploy" } else { "" }
Assert-Test -CaseId "UT-079-3" -Name "deployDir ends with lowercase 'deploy' dir name" `
    -Condition ($deployDirExists -and $deployTargetName -eq "deploy") `
    -Detail "deployDir tail: '$deployTargetName'"

# ----------------------------------------------------------------------------
# UT-080: 4 executable modules configure copy plugin at package phase,
#         AFTER spring-boot-maven-plugin, using <target> syntax (P0)
# ----------------------------------------------------------------------------
$allModuleOk = $true
$moduleDetails = @()
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom

    $hasAntrun = $content -match '<artifactId>maven-antrun-plugin</artifactId>'
    $hasPhase = $content -match '<phase>\s*package\s*</phase>'
    $bootIdx = $content.IndexOf('<artifactId>spring-boot-maven-plugin</artifactId>')
    $antrunIdx = $content.IndexOf('<artifactId>maven-antrun-plugin</artifactId>')
    $orderOk = ($bootIdx -ge 0 -and $antrunIdx -gt $bootIdx)
    $targetSyntax = $content -match '<target>' -and -not ($content -match '<tasks>')

    $ok = $hasAntrun -and $hasPhase -and $orderOk -and $targetSyntax
    if (-not $ok) { $allModuleOk = $false }
    $moduleDetails += "$m(antrun:$hasAntrun,phase:$hasPhase,afterBoot:$orderOk,targetSyntax:$targetSyntax)"
}
Assert-Test -CaseId "UT-080-1" -Name "all 4 module poms have maven-antrun-plugin" `
    -Condition $allModuleOk -Detail ($moduleDetails -join "; ")

# Per-module assertions with readable detail (UT-080-2/3/4)
$phaseDetail = @()
$orderDetail = @()
$syntaxDetail = @()
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom
    $phaseDetail += "$($m):" + ($content -match '<phase>\s*package\s*</phase>')
    $bootIdx = $content.IndexOf('<artifactId>spring-boot-maven-plugin</artifactId>')
    $antrunIdx = $content.IndexOf('<artifactId>maven-antrun-plugin</artifactId>')
    $orderDetail += "$($m):" + ($bootIdx -ge 0 -and $antrunIdx -gt $bootIdx)
    $syntaxDetail += "$($m):" + ($content -match '<target>' -and -not ($content -match '<tasks>'))
}
Assert-Test -CaseId "UT-080-2" -Name "copy plugin bound to package phase in all 4 modules" `
    -Condition (-not ($phaseDetail -match ':False')) -Detail ($phaseDetail -join "; ")
Assert-Test -CaseId "UT-080-3" -Name "antrun declared after spring-boot-maven-plugin in all 4 modules" `
    -Condition (-not ($orderDetail -match ':False')) -Detail ($orderDetail -join "; ")
Assert-Test -CaseId "UT-080-4" -Name "antrun 3.x <target> syntax used, no deprecated <tasks>" `
    -Condition (-not ($syntaxDetail -match ':False')) -Detail ($syntaxDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-081: deploy artifact names match deploy-start-* script contract (P0)
# ----------------------------------------------------------------------------
$copySrcOk = $true
$tofileDetail = @()
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom
    $contract = $contractMap[$m]
    $hasSrc = $content -match '<copy\s+file="\$\{project\.build\.directory\}/\$\{project\.build\.finalName\}\.jar"'
    $hasTo = $content -match ('tofile="\$\{deployDir\}/' + [regex]::Escape($contract) + '"')
    if (-not ($hasSrc -and $hasTo)) { $copySrcOk = $false }
    $tofileDetail += "$($m)(contract:$($contract):$hasTo,src:$hasSrc)"
}
Assert-Test -CaseId "UT-081-1" -Name "all 4 modules copy from target final jar to contract-named tofile" `
    -Condition $copySrcOk -Detail ($tofileDetail -join "; ")

$jarNames = @($moduleDirs | ForEach-Object { $contractMap[$_] })
$uniqueCount = @($jarNames | Sort-Object -Unique).Count
Assert-Test -CaseId "UT-081-2" -Name "4 artifact file names are distinct (no same-name overwrite)" `
    -Condition ($uniqueCount -eq 4) `
    -Detail "names: $($jarNames -join ', '), unique: $uniqueCount"
$noVersionSuffix = -not (@($jarNames | Where-Object { $_ -match '-[0-9]+\.[0-9]+\.[0-9]+' }).Count -gt 0)
Assert-Test -CaseId "UT-081-3" -Name "artifact names carry no version suffix (contract names)" `
    -Condition $noVersionSuffix -Detail "names: $($jarNames -join ', ')"

# deploy-start-* scripts must reference the exact contract jar names
$deployScripts = Join-Path $ProjectRoot "deploy\scripts"
$scriptRefOk = $true
$scriptDetail = @()
foreach ($m in $moduleDirs) {
    $short = $scriptShortMap[$m]                    # gateway / auth / biz / system
    $contract = $contractMap[$m]
    $shFile = Join-Path $deployScripts "deploy-start-$short.sh"
    $ps1File = Join-Path $deployScripts "deploy-start-$short.ps1"
    $shContent = Get-Content -Raw -LiteralPath $shFile
    $ps1Content = Get-Content -Raw -LiteralPath $ps1File
    $shRef = $shContent -match [regex]::Escape($contract) -and
             $shContent -notmatch 'cloudoffice-[a-z]+[\\/]target'
    $ps1Ref = $ps1Content -match [regex]::Escape($contract) -and
              $ps1Content -notmatch 'cloudoffice-[a-z]+[\\/]target'
    if (-not ($shRef -and $ps1Ref)) { $scriptRefOk = $false }
    $scriptDetail += "$short(sh:$shRef,ps1:$ps1Ref)"
}
Assert-Test -CaseId "UT-081-4" -Name "deploy-start-* scripts reference exact contract jar names" `
    -Condition $scriptRefOk -Detail ($scriptDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-082: single-file copy only with overwrite=true, no whole-dir recursion (P0, negative)
# ----------------------------------------------------------------------------
$singleFileOk = $true
$overwriteOk = $true
$singleDetail = @()
$overwriteDetail = @()
$allPoms = @($rootPom) + @($moduleDirs | ForEach-Object { Join-Path $ProjectRoot (Join-Path $_ "pom.xml") })
$recursiveHits = @()
foreach ($pom in $allPoms) {
    $content = Get-Content -Raw -LiteralPath $pom
    if ($content -match '<fileset\s+dir="\$\{project\.build\.directory\}"') {
        $recursiveHits += "$pom [fileset whole-dir]"
    }
    if ($content -match '<directory>\s*\$\{project\.build\.directory\}\s*</directory>') {
        $recursiveHits += "$pom [unfiltered directory copy]"
    }
}
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom
    $isSingle = $content -match '<copy\s+file=' -and -not ($content -match '<fileset')
    if (-not $isSingle) { $singleFileOk = $false }
    $singleDetail += "$($m):" + $isSingle
    $hasOverwrite = $content -match '<copy\s+file=' -and $content -match 'overwrite="true"'
    if (-not $hasOverwrite) { $overwriteOk = $false }
    $overwriteDetail += "$($m):" + $hasOverwrite
}
Assert-Test -CaseId "UT-082-1" -Name "all 4 modules use single-file copy (copy file/tofile, no fileset)" `
    -Condition $singleFileOk -Detail ($singleDetail -join "; ")
Assert-Test -CaseId "UT-082-2" -Name "no whole-dir recursive copy of target in any pom" `
    -Condition ($recursiveHits.Count -eq 0) -Detail ($recursiveHits -join "; " -replace $null, "none")
Assert-Test -CaseId "UT-082-3" -Name "copy overwrite=true in all 4 modules (repeat build overwrites)" `
    -Condition $overwriteOk -Detail ($overwriteDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-083: common module has no copy/deploy output config (P1, negative)
# ----------------------------------------------------------------------------
$commonPom = Join-Path $ProjectRoot "cloudoffice-common\pom.xml"
$commonContent = Get-Content -Raw -LiteralPath $commonPom
$commonNoAntrun = -not ($commonContent -match 'maven-antrun-plugin')
$commonNoCopy = -not ($commonContent -match 'maven-resources-plugin|copy-resources')
$commonNoDeploy = -not ($commonContent -match 'deployDir|tofile=|target\s*directory')
Assert-Test -CaseId "UT-083-1" -Name "common pom has no copy plugin (antrun/resources)" `
    -Condition ($commonNoAntrun -and $commonNoCopy) `
    -Detail "antrun:$commonNoAntrun copy-resources:$commonNoCopy"
Assert-Test -CaseId "UT-083-2" -Name "common pom has no deploy output configuration" `
    -Condition $commonNoDeploy -Detail "no deployDir/tofile/output to deploy"

# ----------------------------------------------------------------------------
# UT-084: deploy *.jar ignored by git, only .gitkeep tracked (P1, negative/SCM)
# ----------------------------------------------------------------------------
$gitBase = @("-C", $ProjectRoot)
$jarProbe = "deploy/cloudoffice-gateway.jar"
$ignoreOut = @(& git @gitBase check-ignore -v $jarProbe) 2>$null
$ignoreOut = @($ignoreOut | Where-Object { $_ })
$ignoreHit = $ignoreOut.Count -gt 0
$ignoreDetail = if ($ignoreHit) { ($ignoreOut -join "; ") } else { "no ignore rule matched" }
Assert-Test -CaseId "UT-084-1" -Name "deploy/*.jar hits .gitignore (git check-ignore)" `
    -Condition $ignoreHit -Detail "$jarProbe -> $ignoreDetail"

$trackedInDeploy = @(& git @gitBase ls-files "deploy") 2>$null
$trackedJars = @($trackedInDeploy | Where-Object { $_ -match '\.jar$' })
Assert-Test -CaseId "UT-084-2" -Name "no *.jar tracked under deploy (git ls-files)" `
    -Condition ($trackedJars.Count -eq 0) `
    -Detail "tracked jars: $($trackedJars -join ', ') (expected none)"

$keepRoot = @(& git @gitBase ls-files "deploy/.gitkeep") 2>$null
$keepScripts = @(& git @gitBase ls-files "deploy/scripts/.gitkeep") 2>$null
$keepOk = ($keepRoot.Count -gt 0) -and ($keepScripts.Count -gt 0)
Assert-Test -CaseId "UT-084-3" -Name "deploy/.gitkeep and deploy/scripts/.gitkeep tracked (dir committable)" `
    -Condition $keepOk `
    -Detail "root .gitkeep: $($keepRoot -join ','), scripts/.gitkeep: $($keepScripts -join ',')"

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
