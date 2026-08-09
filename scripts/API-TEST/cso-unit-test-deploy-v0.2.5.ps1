# ============================================================================
# CloudStrollOffice (CSO) v0.2.5 - Deploy Directory Structure Unit Test
# ----------------------------------------------------------------------------
# Coverage: UT-061 ~ UT-072 in docs/cso-v0.2.5/cso-testcase-v0.2.5.md
#   UT-061: deploy directory exists and is a container (P0)
#   UT-062: deploy/scripts sub-directory exists and is a container (P0)
#   UT-063: deploy is lowercase and a direct child of project root (P0)
#   UT-064: re-create is idempotent, existing content preserved (P1, boundary)
#   UT-065: no source code / build intermediates inside deploy (P1, negative)
#   UT-066: deploy/env.json exists and is a file (P0)
#   UT-067: deploy/env.example.json exists and is a file (P0)
#   UT-068: root env.json removed, no residue (P0, negative)
#   UT-069: root env.example.json removed, no residue (P0, negative)
#   UT-070: deploy/env.example.json content identical to pre-migration git version (P1)
#   UT-071: deploy/env.json still ignored by git, not listed in status (P1, security)
#   UT-072: deploy/env.example.json tracked by git, old root path untracked (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-v0.2.5.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-deploy-v0.2.5.ps1 -ProjectRoot D:\path\to\repo
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

Write-Output "=" * 70
Write-Output "CSO v0.2.5 Deploy Directory Unit Test (UT-061~UT-065)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "=" * 70

# ----------------------------------------------------------------------------
# UT-061: deploy directory exists and is a container (P0)
# ----------------------------------------------------------------------------
$deployPath = Join-Path $ProjectRoot "deploy"
Assert-Test -CaseId "UT-061" -Name "deploy directory exists and is a container" `
    -Condition (Test-Path -LiteralPath $deployPath -PathType Container) `
    -Detail "Path: $deployPath"

# ----------------------------------------------------------------------------
# UT-062: deploy/scripts sub-directory exists and is a container (P0)
# ----------------------------------------------------------------------------
$scriptsPath = Join-Path $deployPath "scripts"
Assert-Test -CaseId "UT-062" -Name "deploy/scripts sub-directory exists and is a container" `
    -Condition (Test-Path -LiteralPath $scriptsPath -PathType Container) `
    -Detail "Path: $scriptsPath"

# ----------------------------------------------------------------------------
# UT-063: deploy is lowercase and a direct child of project root (P0)
# ----------------------------------------------------------------------------
$rootChildren = @(Get-ChildItem -LiteralPath $ProjectRoot -Force)
$deployChildren = @($rootChildren | Where-Object { $_.Name -eq "deploy" })
$deployCount = $deployChildren.Count
$isDir = $deployCount -eq 1 -and $deployChildren[0].PSIsContainer
$noVariant = -not (@($rootChildren | Where-Object { $_.Name -match "^[Dd][Ee][Pp][Ll][Oo][Yy]$" -and $_.Name -ne "deploy" }).Count -gt 0)
Assert-Test -CaseId "UT-063" -Name "exactly one lowercase 'deploy' dir at root, no case variants" `
    -Condition ($deployCount -eq 1 -and $isDir -and $noVariant) `
    -Detail "deploy entries: $deployCount, isDir: $isDir, noVariant: $noVariant"

# ----------------------------------------------------------------------------
# UT-064: re-create is idempotent, existing content preserved (P1, boundary)
# ----------------------------------------------------------------------------
$probeFile = Join-Path $deployPath ".ut064-probe.tmp"
try {
    Set-Content -LiteralPath $probeFile -Value "idempotency-probe" -Encoding ASCII
    New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
    $probeExists = Test-Path -LiteralPath $probeFile -PathType Leaf
    # PS 5.1 Set-Content appends a trailing newline by default; Trim before compare
    $probeContent = if ($probeExists) { (Get-Content -LiteralPath $probeFile -Raw).Trim() } else { "" }
    Assert-Test -CaseId "UT-064" -Name "re-create deploy/scripts is idempotent, probe file preserved" `
        -Condition ($probeExists -and $probeContent -eq "idempotency-probe") `
        -Detail "probe exists: $probeExists, content: '$probeContent'"
}
finally {
    if (Test-Path -LiteralPath $probeFile) {
        Remove-Item -LiteralPath $probeFile -Force
    }
}

# ----------------------------------------------------------------------------
# UT-065: no source code / build intermediates inside deploy (P1, negative)
# ----------------------------------------------------------------------------
# NOTE: deploy/cloudoffice-flutter-app is the client FINAL artifact dir (TASK-005,
# AC-3): its web/ artifacts include .js/.wasm compiled output and windows/ includes
# exe/dll/data. Those are build products, not source code, so files under the
# client artifact dir are excluded from the source-file check. Source code
# anywhere else in deploy still fails.
$intermediateDirs = @(Get-ChildItem -LiteralPath $deployPath -Recurse -Directory -Force |
    Where-Object { $_.Name -eq "target" -or $_.Name -eq "build" -or $_.Name -eq "node_modules" })
$clientArtifactDir = Join-Path $deployPath "cloudoffice-flutter-app"
$sourceFiles = @(Get-ChildItem -LiteralPath $deployPath -Recurse -File -Force |
    Where-Object { $_.Extension -in @(".java", ".dart", ".kt", ".kts", ".go", ".py", ".js", ".ts", ".tsx", ".vue") } |
    Where-Object { -not $_.FullName.StartsWith($clientArtifactDir + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) })
Assert-Test -CaseId "UT-065" -Name "no build intermediates or source files under deploy" `
    -Condition ($intermediateDirs.Count -eq 0 -and $sourceFiles.Count -eq 0) `
    -Detail "intermediate dirs: $($intermediateDirs.Count), source files: $($sourceFiles.Count)"

# ----------------------------------------------------------------------------
# UT-066: deploy/env.json exists and is a file (P0)
# ----------------------------------------------------------------------------
$envJsonPath = Join-Path $deployPath "env.json"
Assert-Test -CaseId "UT-066" -Name "deploy/env.json exists and is a file" `
    -Condition (Test-Path -LiteralPath $envJsonPath -PathType Leaf) `
    -Detail "Path: $envJsonPath"

# ----------------------------------------------------------------------------
# UT-067: deploy/env.example.json exists and is a file (P0)
# ----------------------------------------------------------------------------
$envExamplePath = Join-Path $deployPath "env.example.json"
Assert-Test -CaseId "UT-067" -Name "deploy/env.example.json exists and is a file" `
    -Condition (Test-Path -LiteralPath $envExamplePath -PathType Leaf) `
    -Detail "Path: $envExamplePath"

# ----------------------------------------------------------------------------
# UT-068: root env.json no longer exists (P0, negative)
# ----------------------------------------------------------------------------
$rootEnvJson = Join-Path $ProjectRoot "env.json"
Assert-Test -CaseId "UT-068" -Name "root env.json removed, no residue" `
    -Condition (-not (Test-Path -LiteralPath $rootEnvJson)) `
    -Detail "Path checked: $rootEnvJson"

# ----------------------------------------------------------------------------
# UT-069: root env.example.json no longer exists (P0, negative)
# ----------------------------------------------------------------------------
$rootEnvExample = Join-Path $ProjectRoot "env.example.json"
Assert-Test -CaseId "UT-069" -Name "root env.example.json removed, no residue" `
    -Condition (-not (Test-Path -LiteralPath $rootEnvExample)) `
    -Detail "Path checked: $rootEnvExample"

# ----------------------------------------------------------------------------
# UT-070: deploy/env.example.json content identical to pre-migration version (P1)
#   Historical source (byte-exact via cmd redirection to keep encoding):
#     1) HEAD:env.example.json  -> migration not committed yet
#     2) commit that DELETED root env.example.json; read its parent version
#        (git log --diff-filter=D gives the delete commit; in that commit the
#        path is already gone, so show "<commit>^:env.example.json")
# ----------------------------------------------------------------------------
$hashEqual = $false
$hashDetail = "no comparison performed"
if (Test-Path -LiteralPath $envExamplePath -PathType Leaf) {
    $currentHash = (Get-FileHash -LiteralPath $envExamplePath -Algorithm SHA256).Hash
    $histFile = Join-Path ([System.IO.Path]::GetTempPath()) ("cso-ut070-" + [guid]::NewGuid().ToString("N") + ".json")
    $histRef = $null
    try {
        $cmdLine = 'git show "HEAD:env.example.json" > "' + $histFile + '" 2>nul'
        cmd /c $cmdLine | Out-Null
        $len = (Get-Item -LiteralPath $histFile -ErrorAction SilentlyContinue).Length
        if ($len -gt 0) {
            $histRef = "HEAD:env.example.json"
        }
        else {
            # Migration already committed: find the commit that deleted the root path
            $delCommit = (& git log -1 --diff-filter=D --format=%H -- "env.example.json") 2>$null
            if (-not $delCommit) {
                $delCommit = (& git log -1 --format=%H -- "env.example.json") 2>$null
            }
            if ($delCommit) {
                # Root path no longer exists in the delete commit itself; read parent version
                $cmdLine = 'git show "' + $delCommit + '^:env.example.json" > "' + $histFile + '" 2>nul'
                cmd /c $cmdLine | Out-Null
                if ((Get-Item -LiteralPath $histFile -ErrorAction SilentlyContinue).Length -gt 0) {
                    $histRef = "$delCommit^:env.example.json"
                }
            }
        }
        if ($histRef) {
            $histHash = (Get-FileHash -LiteralPath $histFile -Algorithm SHA256).Hash
            $hashEqual = ($currentHash -eq $histHash)
            $hashDetail = "current=$currentHash hist=$histHash ref=$histRef"
        }
        else {
            $hashDetail = "no historical version found in git (file not tracked?)"
        }
    }
    finally {
        if (Test-Path -LiteralPath $histFile) {
            Remove-Item -LiteralPath $histFile -Force
        }
    }
}
Assert-Test -CaseId "UT-070" -Name "deploy/env.example.json hash matches pre-migration version" `
    -Condition $hashEqual -Detail $hashDetail

# ----------------------------------------------------------------------------
# UT-071: deploy/env.json still ignored by git, not listed in status (P1, security)
# ----------------------------------------------------------------------------
$ignoreHit = $false
$ignoreDetail = "no ignore rule matched"
if (Test-Path -LiteralPath $envJsonPath -PathType Leaf) {
    $ignoreOut = (& git check-ignore -v "deploy/env.json") 2>$null
    $ignoreOut = @($ignoreOut | Where-Object { $_ })
    if ($ignoreOut.Count -gt 0) {
        $ignoreHit = $true
        $ignoreDetail = ($ignoreOut -join "; ")
    }
}
$porcelainOut = @(& git status --porcelain) 2>$null
$listed = @($porcelainOut | Where-Object { $_ -match "deploy/env\.json" })
$statusDetail = if ($listed.Count -eq 0) { "deploy/env.json not listed in git status" } else { ($listed -join "; ") }
Assert-Test -CaseId "UT-071" -Name "deploy/env.json ignored by git and not listed in status" `
    -Condition ($ignoreHit -and $listed.Count -eq 0) `
    -Detail "$ignoreDetail | $statusDetail"

# ----------------------------------------------------------------------------
# UT-072: deploy/env.example.json tracked by git, old root path untracked (P1)
# ----------------------------------------------------------------------------
$trackedNew = @(& git ls-files "deploy/env.example.json") 2>$null
$trackedOld = @(& git ls-files "env.example.json") 2>$null
$newTracked = $trackedNew.Count -gt 0 -and ($trackedNew[0] -match "deploy/env\.example\.json")
$oldGone = $trackedOld.Count -eq 0
Assert-Test -CaseId "UT-072" -Name "deploy/env.example.json tracked, root path untracked" `
    -Condition ($newTracked -and $oldGone) `
    -Detail "new path: '$($trackedNew -join ',')', old path: '$($trackedOld -join ',')'"

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
