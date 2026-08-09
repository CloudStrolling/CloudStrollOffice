# ============================================================================
# CloudStrollOffice (CSO) v0.2.6 - Bootstrap Dependency Unit Test (TASK-001)
# ----------------------------------------------------------------------------
# Coverage: UT-097 ~ UT-104 in task testcase
#           (docs/cso-v0.2.6/task_TASK-001/testcase.md)
#   UT-097: root pom dependencyManagement declares spring-cloud-starter-bootstrap (P0)
#   UT-098: gateway module pom actually imports spring-cloud-starter-bootstrap (P0)
#   UT-099: auth-service module pom actually imports spring-cloud-starter-bootstrap (P0)
#   UT-100: biz-service module pom actually imports spring-cloud-starter-bootstrap (P0)
#   UT-101: system-service module pom actually imports spring-cloud-starter-bootstrap (P0)
#   UT-102: no explicit 5.x version of spring-cloud-starter-bootstrap anywhere (P1, negative)
#   UT-103: bootstrap.yml / application.yml untouched by this task (P1, negative)
#   UT-104: git change scope limited to pom.xml only, no java/dart/xml sources (P1, negative)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-bootstrap-dependency-v0.2.6.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-bootstrap-dependency-v0.2.6.ps1 `
#       -ProjectRoot D:\path\to\repo
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
Write-Output "CSO v0.2.6 Bootstrap Dependency Unit Test (TASK-001, UT-097~UT-104)"
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
# All 6 poms scanned by UT-102 (root + 4 modules + common)
$allPoms = @($rootPom) + @($moduleDirs | ForEach-Object { Join-Path $ProjectRoot (Join-Path $_ "pom.xml") })
$allPoms += Join-Path $ProjectRoot "cloudoffice-common\pom.xml"

$bootstrapArtifact = "spring-cloud-starter-bootstrap"

# ----------------------------------------------------------------------------
# UT-097: root pom dependencyManagement declares spring-cloud-starter-bootstrap (P0)
# ----------------------------------------------------------------------------
$rootContent = Get-Content -Raw -LiteralPath $rootPom
$dmStart = $rootContent.IndexOf('<dependencyManagement>')
$dmEnd = $rootContent.IndexOf('</dependencyManagement>')
$dmSection = ""
if ($dmStart -ge 0 -and $dmEnd -gt $dmStart) {
    $dmSection = $rootContent.Substring($dmStart, $dmEnd - $dmStart)
}
# UT-097-1: artifact declared inside dependencyManagement section
$bootstrapInDm = $dmSection.Contains($bootstrapArtifact)
Assert-Test -CaseId "UT-097-1" -Name "root pom dependencyManagement declares spring-cloud-starter-bootstrap" `
    -Condition $bootstrapInDm -Detail "path: $rootPom (dependencyManagement section found: $($dmSection.Length -gt 0))"

# UT-097-2: groupId must be org.springframework.cloud (exact coordinate match)
$groupIdOk = $false
if ($bootstrapInDm) {
    $bIdx = $dmSection.IndexOf($bootstrapArtifact)
    $gStart = $dmSection.LastIndexOf('<groupId>', $bIdx)
    $gEnd = $dmSection.IndexOf('</groupId>', $gStart)
    if ($gStart -ge 0 -and $gEnd -gt $gStart) {
        $groupId = $dmSection.Substring($gStart + 9, $gEnd - $gStart - 9).Trim()
        $groupIdOk = ($groupId -eq 'org.springframework.cloud')
    }
}
Assert-Test -CaseId "UT-097-2" -Name "bootstrap coordinate groupId is org.springframework.cloud" `
    -Condition $groupIdOk -Detail "groupId: '$groupId' (expected 'org.springframework.cloud')"

# UT-097-3: explicit version 4.1.2 (BOM-managed value), NOT 5.x
$versionOk = $false
$bootstrapVersion = ""
if ($bootstrapInDm) {
    $bIdx = $dmSection.IndexOf($bootstrapArtifact)
    $depEnd = $dmSection.IndexOf('</dependency>', $bIdx)
    if ($depEnd -lt 0) { $depEnd = $dmSection.Length }
    $depBlock = $dmSection.Substring($bIdx, $depEnd - $bIdx)
    $vMatch = [regex]::Match($depBlock, '<version>\s*([^<]+?)\s*</version>')
    if ($vMatch.Success) {
        $bootstrapVersion = $vMatch.Groups[1].Value.Trim()
        $versionOk = ($bootstrapVersion -eq '4.1.2')
    }
}
Assert-Test -CaseId "UT-097-3" -Name "bootstrap explicit version is 4.1.2 (Spring Cloud 2023.0.1 BOM value)" `
    -Condition $versionOk -Detail "version: '$bootstrapVersion' (expected '4.1.2', must NOT be 5.x)"

# UT-097-4: declaration grouped after Spring Cloud Alibaba BOM import (Spring Cloud family)
$alibabaIdx = $dmSection.IndexOf('spring-cloud-alibaba-dependencies')
$bIdx4 = $dmSection.IndexOf($bootstrapArtifact)
Assert-Test -CaseId "UT-097-4" -Name "bootstrap declaration placed after Spring Cloud Alibaba BOM import (grouped with Spring Cloud deps)" `
    -Condition ($alibabaIdx -ge 0 -and $bIdx4 -gt $alibabaIdx) `
    -Detail "alibaba BOM index: $alibabaIdx, bootstrap index: $bIdx4"

# ----------------------------------------------------------------------------
# UT-098 ~ UT-101: 4 module poms actually import spring-cloud-starter-bootstrap (P0)
# ----------------------------------------------------------------------------
$importDetail = @()
$noVersionDetail = @()
$nacosGroupDetail = @()
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom

    # must be inside <dependencies> section (actual import, not just parent declaration)
    $depStart = $content.IndexOf('<dependencies>')
    $depEndTag = $content.IndexOf('</dependencies>')
    $depSection = ""
    if ($depStart -ge 0 -and $depEndTag -gt $depStart) {
        $depSection = $content.Substring($depStart, $depEndTag - $depStart)
    }
    $hasImport = $depSection.Contains($bootstrapArtifact)
    if (-not $hasImport) { $importDetail += "$($m):missing" } else { $importDetail += "$($m):ok" }

    # dependency block must NOT carry explicit <version> (managed by parent dependencyManagement)
    $noVer = $true
    if ($hasImport) {
        $bIdx = $depSection.IndexOf($bootstrapArtifact)
        $dEnd = $depSection.IndexOf('</dependency>', $bIdx)
        if ($dEnd -lt 0) { $dEnd = $depSection.Length }
        $block = $depSection.Substring($bIdx, $dEnd - $bIdx)
        $noVer = -not $block.Contains('<version>')
    }
    if (-not $noVer) { $noVersionDetail += "$($m):has-version" } else { $noVersionDetail += "$($m):no-version" }

    # grouped near nacos starter (discovery/config) for auth/biz/system; gateway has nacos-discovery
    $nacosIdx = $depSection.IndexOf('nacos')
    $bIdxN = $depSection.IndexOf($bootstrapArtifact)
    $groupOk = ($nacosIdx -ge 0 -and $bIdxN -gt $nacosIdx)
    if (-not $groupOk) { $nacosGroupDetail += "$($m):misplaced" } else { $nacosGroupDetail += "$($m):ok" }
}
Assert-Test -CaseId "UT-098" -Name "gateway pom <dependencies> actually imports spring-cloud-starter-bootstrap" `
    -Condition ($importDetail[0] -eq "cloudoffice-gateway:ok") `
    -Detail "gateway: $($importDetail[0])"
Assert-Test -CaseId "UT-099" -Name "auth-service pom <dependencies> actually imports spring-cloud-starter-bootstrap" `
    -Condition ($importDetail[1] -eq "cloudoffice-auth-service:ok") `
    -Detail "auth-service: $($importDetail[1])"
Assert-Test -CaseId "UT-100" -Name "biz-service pom <dependencies> actually imports spring-cloud-starter-bootstrap" `
    -Condition ($importDetail[2] -eq "cloudoffice-biz-service:ok") `
    -Detail "biz-service: $($importDetail[2])"
Assert-Test -CaseId "UT-101" -Name "system-service pom <dependencies> actually imports spring-cloud-starter-bootstrap" `
    -Condition ($importDetail[3] -eq "cloudoffice-system-service:ok") `
    -Detail "system-service: $($importDetail[3])"

# all 4 module imports carry no explicit version (parent dependencyManagement manages it)
Assert-Test -CaseId "UT-098-2/099-2/100-2/101-2" -Name "all 4 module bootstrap imports have NO explicit <version> (parent-managed)" `
    -Condition (-not (@($noVersionDetail | Where-Object { $_ -match 'has-version' }).Count -gt 0)) `
    -Detail ($noVersionDetail -join "; ")

# grouped after nacos starter in all 4 modules (reasonable grouping)
Assert-Test -CaseId "UT-097-5/098-1/099-1/100-1/101-1" -Name "bootstrap import grouped after nacos starter block in all 4 modules" `
    -Condition (-not (@($nacosGroupDetail | Where-Object { $_ -match 'misplaced' }).Count -gt 0)) `
    -Detail ($nacosGroupDetail -join "; ")

# ----------------------------------------------------------------------------
# UT-102: no explicit 5.x version of spring-cloud-starter-bootstrap anywhere (P1, negative)
# ----------------------------------------------------------------------------
$fiveXHits = @()
$explicitVersions = @()
foreach ($pom in $allPoms) {
    if (-not (Test-Path -LiteralPath $pom)) { continue }
    $content = Get-Content -Raw -LiteralPath $pom
    $idx = 0
    while (($idx = $content.IndexOf($bootstrapArtifact, $idx)) -ge 0) {
        $dEnd = $content.IndexOf('</dependency>', $idx)
        if ($dEnd -lt 0) { $dEnd = $content.Length }
        $block = $content.Substring($idx, $dEnd - $idx)
        $vMatch = [regex]::Match($block, '<version>\s*([^<]+?)\s*</version>')
        if ($vMatch.Success) {
            $ver = $vMatch.Groups[1].Value.Trim()
            $explicitVersions += "$([IO.Path]::GetFileName($pom)):$ver"
            if ($ver -match '^5\.') {
                $fiveXHits += "$([IO.Path]::GetFileName($pom)):$ver"
            }
        }
        $idx = $dEnd
    }
}
Assert-Test -CaseId "UT-102-1" -Name "no pom declares spring-cloud-starter-bootstrap with 5.x version (Spring Cloud 2025.x incompatible)" `
    -Condition ($fiveXHits.Count -eq 0) `
    -Detail ("5.x hits: " + $(if ($fiveXHits.Count -eq 0) { "none" } else { $fiveXHits -join "; " }))
# any explicit version must stay in 4.1.x (BOM 2023.0.1 family)
$badVersionHits = @($explicitVersions | Where-Object { $_ -notmatch ':4\.1\.' })
Assert-Test -CaseId "UT-102-2" -Name "all explicit bootstrap versions (if any) are 4.1.x family" `
    -Condition ($badVersionHits.Count -eq 0) `
    -Detail ("explicit versions: " + $(if ($explicitVersions.Count -eq 0) { "none" } else { $explicitVersions -join "; " }))

# ----------------------------------------------------------------------------
# UT-103: bootstrap.yml / application.yml untouched by this task (P1, negative)
# ----------------------------------------------------------------------------
$gitBase = @("-C", $ProjectRoot)
$changed = @()
$statusOut = @(& git @gitBase status --short) 2>$null
foreach ($line in $statusOut) {
    $line = $line.TrimEnd()
    if ($line.Length -gt 3) { $changed += $line.Substring(3).Trim().Trim('"') }
}
$ymlChanged = @($changed | Where-Object { $_ -match '\.ya?ml$' })
Assert-Test -CaseId "UT-103-1" -Name "no bootstrap.yml / application.yml changed by TASK-001 (4 modules untouched)" `
    -Condition ($ymlChanged.Count -eq 0) `
    -Detail ("yml changes: " + $(if ($ymlChanged.Count -eq 0) { "none" } else { $ymlChanged -join "; " }))

# ----------------------------------------------------------------------------
# UT-104: git change scope limited to pom.xml + docs/scripts assets, no java/dart/xml (P1, negative)
# ----------------------------------------------------------------------------
$javaHits = @($changed | Where-Object { $_ -match '\.java$' })
$dartHits = @($changed | Where-Object { $_ -match '\.dart$' })
# xml hits excluding the 5 pom.xml build files (root + 4 modules)
$xmlHits = @($changed | Where-Object {
    $p = $_.Replace("\", "/")
    ($p -match '\.xml$') -and -not ($p -eq "pom.xml") -and -not ($p -match '^cloudoffice-(gateway|auth-service|biz-service|system-service)/pom\.xml$')
})
# client runtime code changes (cloudoffice-flutter-app/lib or pubspec.yaml)
$clientHits = @($changed | Where-Object {
    $p = $_.Replace("\", "/")
    $p.StartsWith("cloudoffice-flutter-app/")
})
$srcHits = @($javaHits + $dartHits + $xmlHits + $clientHits)
Assert-Test -CaseId "UT-104-1" -Name "git change scope contains NO *.java / *.dart / Mapper xml / client code" `
    -Condition ($srcHits.Count -eq 0) `
    -Detail ("source hits: " + $(if ($srcHits.Count -eq 0) { "none" } else { $srcHits -join "; " }))

# all 5 poms (root + 4 modules) must be present in the change list
$pomChanged = @($changed | Where-Object {
    $p = $_.Replace("\", "/")
    ($p -eq "pom.xml") -or ($p -match '^cloudoffice-(gateway|auth-service|biz-service|system-service)/pom\.xml$')
})
Assert-Test -CaseId "UT-104-2" -Name "5 poms (root + 4 modules) present in change list" `
    -Condition ($pomChanged.Count -eq 5) `
    -Detail ("pom changes: $($pomChanged.Count) " + $($pomChanged -join ", "))

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
