# ============================================================================
# CloudStrollOffice (CSO) v0.2.5 - Flutter Client Build Script Unit Test (TASK-005)
# ----------------------------------------------------------------------------
# Coverage: UT-085 ~ UT-090 in task testcase (docs/cso-v0.2.5/task_TASK-005/testcase.md)
#   UT-085: client build script exists under cloudoffice-flutter-app (P0)
#   UT-086: script contains flutter build windows --release / web --release
#           and fails fast on build failure ($LASTEXITCODE / set -e) (P0)
#   UT-087: copy actions target only final artifacts (Release dir / build/web),
#           no whole-directory recursive copy of build/ (P0, negative)
#   UT-088: client artifact naming is identifiable and does not clash with
#           the 4 backend jars; landing path matches deploy/scripts contract (P1)
#   UT-089: client build cache build/ is git-ignored; deploy client artifacts
#           (*.exe/*.dll) have a clear git policy; web/windows artifact subtrees
#           under deploy/cloudoffice-flutter-app are ignored by directory rules (P1, negative/SCM)
#   UT-090: no stale old-path references in build script (P0, negative)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-client-build-v0.2.5.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-client-build-v0.2.5.ps1 -ProjectRoot D:\path\to\repo
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
Write-Output "CSO v0.2.5 Flutter Client Build Script Unit Test (TASK-005, UT-085~UT-090)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$appDir = Join-Path $ProjectRoot "cloudoffice-flutter-app"
$ps1Path = Join-Path $appDir "build-release.ps1"
$shPath = Join-Path $appDir "build-release.sh"
$deployDir = Join-Path $ProjectRoot "deploy"
$clientDeployDir = Join-Path $deployDir "cloudoffice-flutter-app"
$scriptsDeployDir = Join-Path $deployDir "scripts"

# ----------------------------------------------------------------------------
# UT-085: client build script exists under cloudoffice-flutter-app (P0)
# ----------------------------------------------------------------------------
$ps1Exists = Test-Path -LiteralPath $ps1Path -PathType Leaf
$shExists = Test-Path -LiteralPath $shPath -PathType Leaf
$anyScript = $ps1Exists -or $shExists
$found = @()
if ($ps1Exists) { $found += "build-release.ps1" }
if ($shExists) { $found += "build-release.sh" }
Assert-Test -CaseId "UT-085" -Name "client build script exists under cloudoffice-flutter-app" `
    -Condition ($anyScript) `
    -Detail "found: $(($found -join ', ')); app dir: $appDir"

# ----------------------------------------------------------------------------
# UT-086: script contains flutter build commands and fails fast (P0)
# ----------------------------------------------------------------------------
$ps1Content = ""
$shContent = ""
if ($ps1Exists) { $ps1Content = Get-Content -LiteralPath $ps1Path -Raw -Encoding UTF8 }
if ($shExists) { $shContent = Get-Content -LiteralPath $shPath -Raw -Encoding UTF8 }

$hasWinBuild = $false
$hasWebBuild = $false
$hasFailFast = $false
$hasPubGet = $false
$buildDetail = ""
if ($ps1Exists) {
    $hasWinBuild = $ps1Content -match 'flutter build windows --release'
    $hasWebBuild = $ps1Content -match 'flutter build web --release'
    $hasFailFast = $ps1Content -match '\$LASTEXITCODE -ne 0'
    $hasPubGet = $ps1Content -match 'flutter pub get'
    $buildDetail = "ps1: winBuild=$hasWinBuild webBuild=$hasWebBuild failFast=$hasFailFast pubGet=$hasPubGet"
}
if ($shExists) {
    $shWinBuild = $shContent -match 'flutter build windows --release'
    $shWebBuild = $shContent -match 'flutter build web --release'
    $shFailFast = $shContent -match 'set -e'
    $shPubGet = $shContent -match 'flutter pub get'
    $hasWinBuild = $hasWinBuild -and $shWinBuild
    $hasWebBuild = $hasWebBuild -and $shWebBuild
    $hasFailFast = $hasFailFast -and $shFailFast
    $hasPubGet = $hasPubGet -and $shPubGet
    $buildDetail = "$buildDetail | sh: winBuild=$shWinBuild webBuild=$shWebBuild failFast(set -e)=$shFailFast pubGet=$shPubGet"
}
Assert-Test -CaseId "UT-086-1" -Name "script contains 'flutter build windows --release' and 'flutter build web --release'" `
    -Condition ($hasWinBuild -and $hasWebBuild) -Detail $buildDetail
Assert-Test -CaseId "UT-086-2" -Name 'script fails fast on build failure ($LASTEXITCODE check / set -e)' `
    -Condition $hasFailFast -Detail $buildDetail
Assert-Test -CaseId "UT-086-3" -Name "script has build prerequisite (flutter pub get)" `
    -Condition $hasPubGet -Detail $buildDetail

# ----------------------------------------------------------------------------
# UT-087: copy actions target only final artifacts, no whole-dir build/ copy (P0, negative)
# ----------------------------------------------------------------------------
# 1. Positive: copy sources are limited to final artifact dirs
$ps1FinalDirs = $false
$shFinalDirs = $false
$finalDetail = ""
if ($ps1Exists) {
    $ps1FinalDirs = ($ps1Content -match 'build\\windows\\x64\\runner\\Release') -and ($ps1Content -match 'build\\web')
    $finalDetail = "ps1: x64ReleasePath=$($ps1Content -match 'build\\windows\\x64\\runner\\Release') webPath=$($ps1Content -match 'build\\web')"
}
if ($shExists) {
    $shFinalDirs = ($shContent -match 'build/windows/x64/runner/Release') -and ($shContent -match 'build/web')
    $finalDetail = "$finalDetail | sh: x64ReleasePath=$($shContent -match 'build/windows/x64/runner/Release') webPath=$($shContent -match 'build/web')"
}
Assert-Test -CaseId "UT-087-1" -Name "copy sources limited to final artifact dirs (Release / build/web, x64 path)" `
    -Condition ($ps1FinalDirs -and $shFinalDirs) -Detail $finalDetail

# 2. Negative: no whole-directory recursive copy of build/ (copy root build cache)
$badCopyPs1 = 0
$badCopySh = 0
if ($ps1Exists) {
    # Pattern: Copy-Item -Path (Join-Path $ScriptDir "build") ... -> copies entire build dir
    $badCopyPs1 = @([regex]::Matches($ps1Content, 'Copy-Item[^\r\n]*Join-Path\s+\$ScriptDir\s+"build"\s*\)')).Count
    # Also plain "Copy-Item ... 'build'" / "Copy-Item ... \"build\"" as direct source
    $badCopyPs1 += @([regex]::Matches($ps1Content, 'Copy-Item[^\r\n]*["'']build["'']\s*,?')).Count
}
if ($shExists) {
    # Pattern: cp -R "$SCRIPT_DIR/build" ... -> copies entire build dir (not build/web, build/windows/...)
    $badCopySh = @([regex]::Matches($shContent, 'cp\s+-R[a-zA-Z]*\s+"\$SCRIPT_DIR/build"(\s|")')).Count
    $badCopySh += @([regex]::Matches($shContent, 'cp\s+-r[a-zA-Z]*\s+"\$SCRIPT_DIR/build"(\s|")')).Count
    # Pattern: cp -R build ... (unquoted whole build dir)
    $badCopySh += @([regex]::Matches($shContent, 'cp\s+-[rR][a-zA-Z]*\s+["'']?build["'']?\s+["'']?[^/]')).Count
}
Assert-Test -CaseId "UT-087-2" -Name "no whole-directory recursive copy of build/ in script (static hit count = 0)" `
    -Condition ($badCopyPs1 -eq 0 -and $badCopySh -eq 0) `
    -Detail "ps1 whole-build copy patterns: $badCopyPs1, sh whole-build copy patterns: $badCopySh"

# 3. Negative: no compile/intermediate file patterns copied into deploy
$intermediateHit = 0
if ($ps1Exists) {
    $intermediateHit += @([regex]::Matches($ps1Content, '(?i)CMakeFiles|\.vcxproj|\.obj\b|\.pdb\b')).Count
}
if ($shExists) {
    $intermediateHit += @([regex]::Matches($shContent, '(?i)CMakeFiles|\.vcxproj|\.obj\b|\.pdb\b')).Count
}
Assert-Test -CaseId "UT-087-3" -Name "no compile intermediate patterns referenced in script (obj/pdb/vcxproj/CMakeFiles)" `
    -Condition ($intermediateHit -eq 0) `
    -Detail "intermediate pattern hits: $intermediateHit"

# ----------------------------------------------------------------------------
# UT-088: client artifact naming identifiable, no clash with backend jars (P1)
# ----------------------------------------------------------------------------
$clientDeployExists = Test-Path -LiteralPath $clientDeployDir -PathType Container
$identifiable = $false
$landingContract = $false
if ($ps1Exists) {
    $identifiable = $ps1Content -match 'Join-Path \$DeployDir "cloudoffice-flutter-app"'
    $landingContract = ($ps1Content -match 'Join-Path \$ClientDeployDir "windows"') -and ($ps1Content -match 'Join-Path \$ClientDeployDir "web"')
}
$shLanding = $false
if ($shExists) {
    $shIdentifiable = $shContent -match 'CLIENT_DEPLOY_DIR="\$DEPLOY_DIR/cloudoffice-flutter-app"'
    $shLanding = ($shContent -match 'CLIENT_DEPLOY_DIR/windows') -and ($shContent -match 'CLIENT_DEPLOY_DIR/web')
    $identifiable = $identifiable -and $shIdentifiable
    $landingContract = $landingContract -and $shLanding
}
Assert-Test -CaseId "UT-088-1" -Name "client artifact landing dir deploy/cloudoffice-flutter-app is identifiable" `
    -Condition ($clientDeployExists -and $identifiable) `
    -Detail "client deploy dir exists: $clientDeployExists; identifiable naming in script: $identifiable"

# No name clash with 4 backend jars: jars live in deploy root, client artifacts
# live under deploy/cloudoffice-flutter-app/ sub-tree and use .exe/.dll/.zip ext
$jarNames = @("cloudoffice-gateway.jar", "cloudoffice-auth-service.jar", "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar")
$jarCount = 0
$missingJars = @()
foreach ($jar in $jarNames) {
    if (Test-Path -LiteralPath (Join-Path $deployDir $jar) -PathType Leaf) {
        $jarCount++
    }
    else {
        $missingJars += $jar
    }
}
# Client artifacts (exe/dll/zip) land only under deploy/cloudoffice-flutter-app sub-tree,
# not at deploy root where the 4 jars live -> namespaces do not overlap.
# Pattern matches only artifact FILE names (exe/dll/zip/msi) written directly to deploy
# root (e.g. Join-Path $DeployDir "cloudoffice_flutter_app.exe"); the definition of the
# client sub-directory (Join-Path $DeployDir "cloudoffice-flutter-app") is NOT a clash.
$clashPattern = 'Join-Path\s+\$DeployDir\s+"[^"]*\.(exe|dll|zip|msi)"'
$clashHit = 0
if ($ps1Exists) { $clashHit += @([regex]::Matches($ps1Content, $clashPattern)).Count }
if ($shExists) { $clashHit += @([regex]::Matches($shContent, $clashPattern)).Count }
Assert-Test -CaseId "UT-088-2" -Name "client artifacts never written directly to deploy root (no jar name clash)" `
    -Condition ($jarCount -eq 4 -and $clashHit -eq 0) `
    -Detail "backend jars found: $jarCount/4 (missing: $($missingJars -join ', ')); direct-to-root client artifact patterns: $clashHit"

# Landing path consistent with deploy/scripts reference contract: if any
# deploy/scripts script references the client artifact, it must point to
# deploy/cloudoffice-flutter-app (currently no reference -> vacuous pass)
$scriptRefBad = @()
if (Test-Path -LiteralPath $scriptsDeployDir -PathType Container) {
    foreach ($scriptFile in Get-ChildItem -LiteralPath $scriptsDeployDir -File | Where-Object { $_.Extension -in @(".sh", ".ps1") }) {
        $c = Get-Content -LiteralPath $scriptFile.FullName -Raw -Encoding UTF8
        if ($c -match '(?i)cloudoffice[-_]flutter[-_]app') {
            if ($c -match 'deploy[\\/]cloudoffice-flutter-app') {
                # OK: references the new client sub-directory
            }
            elseif ($c -match 'cloudoffice[-_]flutter[-_]app\.(exe|zip|msi)') {
                $scriptRefBad += $scriptFile.Name
            }
        }
    }
}
Assert-Test -CaseId "UT-088-3" -Name "landing path consistent with deploy/scripts reference contract" `
    -Condition ($scriptRefBad.Count -eq 0) `
    -Detail "scripts with stale client artifact references: $(($scriptRefBad -join ', ') -replace '^$', 'none')"

# ----------------------------------------------------------------------------
# UT-089: build cache build/ git-ignored; deploy client artifact policy (P1, negative/SCM)
# ----------------------------------------------------------------------------
# Note: git check-ignore returns exit code 0 when the path IS ignored and 1 when
# not. We capture stdout only; a non-zero exit simply yields empty output.
function Get-GitCheckIgnore {
    param([string]$Path)
    try {
        $out = & git -C $ProjectRoot check-ignore -v $Path 2>$null
        if ($LASTEXITCODE -eq 0) { return @($out | Where-Object { $_ }) }
    }
    catch { }
    return @()
}

# 1. client build cache path is git-ignored
$ignoreOut = @(Get-GitCheckIgnore -Path "cloudoffice-flutter-app/build/windows/x64/runner/Release/cloudoffice_flutter_app.exe")
$cacheIgnored = $ignoreOut.Count -gt 0
Assert-Test -CaseId "UT-089-1" -Name "client build cache build/ is git-ignored (check-ignore hit)" `
    -Condition $cacheIgnored -Detail ($ignoreOut -join "; " -replace "^$", "no ignore rule matched")

# 2. deploy client artifacts (*.exe/*.dll/*.zip) git policy: ignored (default) or whitelisted
$exeOut = @(Get-GitCheckIgnore -Path "deploy/cloudoffice-flutter-app/windows/cloudoffice_flutter_app.exe")
$dllOut = @(Get-GitCheckIgnore -Path "deploy/cloudoffice-flutter-app/windows/flutter_windows.dll")
$exeIgnored = $exeOut.Count -gt 0
$dllIgnored = $dllOut.Count -gt 0
$policyOk = $exeIgnored -and $dllIgnored
Assert-Test -CaseId "UT-089-2" -Name "deploy client artifacts *.exe/*.dll git policy clear (git-ignored by default)" `
    -Condition $policyOk `
    -Detail "exe rule: $(($exeOut -join '; ') -replace '^$', 'no rule'), dll rule: $(($dllOut -join '; ') -replace '^$', 'no rule')"

# 3. build cache not tracked by git; deploy client subtree only tracks .gitkeep
$lsBuild = @(& git -C $ProjectRoot ls-files "cloudoffice-flutter-app/build" 2>$null)
$lsClient = @(& git -C $ProjectRoot ls-files "deploy/cloudoffice-flutter-app" 2>$null)
$buildTracked = $lsBuild.Count -gt 0
$clientTrackedFiles = @($lsClient | Where-Object { $_ })
$onlyGitkeep = ($clientTrackedFiles.Count -eq 0) -or
    (($clientTrackedFiles | Where-Object { $_ -notmatch '\.gitkeep$' }).Count -eq 0)
Assert-Test -CaseId "UT-089-3" -Name "no build cache tracked; deploy client subtree tracks only .gitkeep" `
    -Condition (-not $buildTracked -and $onlyGitkeep) `
    -Detail "build tracked files: $($lsBuild.Count); deploy/client tracked: $($clientTrackedFiles -join ', ' -replace '^$', 'none')"

# 4. deploy client web/windows artifact subtrees ignored by directory rules (regression guard).
#    Regression: UT-089-3 failed in v0.2.5 - 48 web/windows build artifacts were committed.
#    .gitignore now ignores deploy/cloudoffice-flutter-app/web/* and windows/* (with .gitkeep
#    whitelisted). Verify non-exe/dll artifacts (the gap that let web files in) hit the rules.
$webOut = @(Get-GitCheckIgnore -Path "deploy/cloudoffice-flutter-app/web/index.html")
$winDataOut = @(Get-GitCheckIgnore -Path "deploy/cloudoffice-flutter-app/windows/data/icudtl.dat")
$webIgnored = $webOut.Count -gt 0
$winDataIgnored = $winDataOut.Count -gt 0
$dirRuleOk = $webIgnored -and $winDataIgnored
Assert-Test -CaseId "UT-089-4" -Name "deploy client web/windows artifact subtrees git-ignored (directory rules hit)" `
    -Condition $dirRuleOk `
    -Detail "web rule: $(($webOut -join '; ') -replace '^$', 'no rule'); windows data rule: $(($winDataOut -join '; ') -replace '^$', 'no rule')"

# ----------------------------------------------------------------------------
# UT-090: no stale old-path references in build script (P0, negative)
# ----------------------------------------------------------------------------
$oldPathHits = 0
$staleDetail = ""
if ($ps1Exists) {
    $oldRelease = @([regex]::Matches($ps1Content, 'build\\windows\\runner\\Release|build/windows/runner/Release')).Count
    $oldEnvRefs = @([regex]::Matches($ps1Content, '(?<![dD]eploy[\\/])["'']?env\.json["'']?')).Count
    $oldScriptRefs = @([regex]::Matches($ps1Content, 'scripts\\deploy-|scripts/deploy-')).Count
    $oldPathHits += $oldRelease + $oldEnvRefs + $oldScriptRefs
    $staleDetail = "ps1: oldRelease=$oldRelease rootEnvRefs=$oldEnvRefs oldScriptRefs=$oldScriptRefs"
}
if ($shExists) {
    $oldRelease = @([regex]::Matches($shContent, 'build/windows/runner/Release|build\\windows\\runner\\Release')).Count
    $oldEnvRefs = @([regex]::Matches($shContent, '(?<![dD]eploy/)["'']?env\.json["'']?')).Count
    $oldScriptRefs = @([regex]::Matches($shContent, 'scripts/deploy-|scripts\\deploy-')).Count
    $oldPathHits += $oldRelease + $oldEnvRefs + $oldScriptRefs
    $staleDetail = "$staleDetail | sh: oldRelease=$oldRelease rootEnvRefs=$oldEnvRefs oldScriptRefs=$oldScriptRefs"
}
Assert-Test -CaseId "UT-090-1" -Name "no stale old-path references (non-x64 Release path, root env.json, old scripts/) in script" `
    -Condition ($oldPathHits -eq 0) -Detail $staleDetail

# Script locates paths from its own directory (no hard-coded absolute paths)
$selfRelative = $false
$ps1SelfRef = $false
$shSelfRef = $false
if ($ps1Exists) { $ps1SelfRef = $ps1Content -match '\$PSScriptRoot' }
if ($shExists) { $shSelfRef = $shContent -match '\$\{BASH_SOURCE\[0\]\}' }
$selfRelative = $ps1SelfRef -and $shSelfRef
Assert-Test -CaseId "UT-090-2" -Name 'script path resolution based on its own directory ($PSScriptRoot / BASH_SOURCE)' `
    -Condition $selfRelative -Detail "ps1 uses PSScriptRoot: $ps1SelfRef; sh uses BASH_SOURCE[0]: $shSelfRef"

$absPathHits = 0
if ($ps1Exists) {
    $absPathHits += @([regex]::Matches($ps1Content, '(?i)[A-Z]:[\\/]')).Count
}
if ($shExists) {
    $absPathHits += @([regex]::Matches($shContent, '(?i)[A-Z]:[\\/]')).Count
}
Assert-Test -CaseId "UT-090-3" -Name "no hard-coded absolute drive paths in script" `
    -Condition ($absPathHits -eq 0) -Detail "absolute drive path hits: $absPathHits"

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
