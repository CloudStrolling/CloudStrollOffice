# ============================================================================
# CloudStrollOffice (CSO) v0.2.6 - Build & Deploy Verify Unit Test (TASK-003)
# ----------------------------------------------------------------------------
# Coverage: UT-113 ~ UT-120 in task testcase
#           (docs/cso-v0.2.6/task_TASK-003/testcase.md)
#   UT-113: deploy/ holds 4 service jar artifacts, all exist & non-empty (P0)
#   UT-114: 4 jars are executable Spring Boot fat jars (JarLauncher Main-Class,
#           BOOT-INF/classes + BOOT-INF/lib present) (P0)
#   UT-115: BOOT-INF/lib of each jar contains spring-cloud-starter-bootstrap
#           (TASK-001 fix enters final artifacts, version 4.1.x NOT 5.x) (P0)
#   UT-116: deploy/env.json holds the 9 required startup variables (NACOS_ADDR/
#           DB_*/REDIS_*/RSA_*) all present & non-empty (P0)
#   UT-117: every $env:<KEY> referenced by the 4 startup scripts
#           (deploy-start-gateway/auth/biz/system.ps1) resolves in env.json;
#           jar paths point to deploy/ artifacts (P1)
#   UT-118: regression guard - 4 module poms still declare bootstrap dep and
#           env.json RSA keys still DER single-line Base64 (fix not reverted)(P1)
#   UT-119: git change scope contains NO Controller/DTO/interface-layer,
#           business code or client (flutter) code changes (P1, negative)
#   UT-120: each jar contains BOOT-INF/classes/bootstrap.yml with nacos
#           discovery/config server-addr placeholder ${NACOS_ADDR:127.0.0.1:8848}(P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-build-verify-v0.2.6.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-build-verify-v0.2.6.ps1 `
#       -ProjectRoot D:\path\to\repo
# Exit code: 0 = all pass, 1 = any failure
# NOTE: ASCII only in this script to keep PowerShell 5.1 encoding safe.
# NOTE: jar internal checks use .NET ZipFile API (no external jar.exe needed).
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:FailedCases = @()

Add-Type -AssemblyName System.IO.Compression.FileSystem

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

function Get-JarEntries {
    param([string]$JarPath)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
    try {
        return @($zip.Entries | ForEach-Object { $_.FullName })
    }
    finally {
        $zip.Dispose()
    }
}

function Get-JarEntryContent {
    param([string]$JarPath, [string]$EntryName)
    $zip = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
    try {
        $entry = $zip.GetEntry($EntryName)
        if ($null -eq $entry) { return "" }
        $reader = New-Object System.IO.StreamReader($entry.Open())
        try { return $reader.ReadToEnd() }
        finally { $reader.Close() }
    }
    finally {
        $zip.Dispose()
    }
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.6 Build & Deploy Verify Unit Test (TASK-003, UT-113~UT-120)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

$deployDir = Join-Path $ProjectRoot "deploy"
$jars = @(
    "cloudoffice-gateway.jar",
    "cloudoffice-auth-service.jar",
    "cloudoffice-biz-service.jar",
    "cloudoffice-system-service.jar"
)
$jarPaths = @($jars | ForEach-Object { Join-Path $deployDir $_ })
$jarShortNames = @("gateway", "auth-service", "biz-service", "system-service")

# ----------------------------------------------------------------------------
# UT-113: deploy/ holds 4 service jar artifacts, all exist & non-empty (P0)
# ----------------------------------------------------------------------------
$missingJars = @()
$emptyJars = @()
$smallJars = @()
foreach ($j in $jarPaths) {
    if (-not (Test-Path -LiteralPath $j -PathType Leaf)) {
        $missingJars += [IO.Path]::GetFileName($j)
    }
    else {
        $len = (Get-Item -LiteralPath $j).Length
        if ($len -le 0) { $emptyJars += "$([IO.Path]::GetFileName($j)):$len" }
        if ($len -lt 10MB) { $smallJars += "$([IO.Path]::GetFileName($j)):$len" }
    }
}
Assert-Test -CaseId "UT-113-1" -Name "4 service jar artifacts all exist in deploy/ (gateway/auth/biz/system)" `
    -Condition ($missingJars.Count -eq 0) `
    -Detail "missing: $(if ($missingJars) { $missingJars -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-113-2" -Name "4 jars are non-empty and reach fat-jar scale (>10MB each)" `
    -Condition (($emptyJars.Count -eq 0) -and ($smallJars.Count -eq 0)) `
    -Detail "empty: $(if ($emptyJars) { $emptyJars -join '; ' } else { 'none' }) | below 10MB: $(if ($smallJars) { $smallJars -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-114: 4 jars are executable Spring Boot fat jars (P0)
# ----------------------------------------------------------------------------
$manifestFail = @()
$bootInfFail = @()
foreach ($j in $jarPaths) {
    $manifest = Get-JarEntryContent -JarPath $j -EntryName "META-INF/MANIFEST.MF"
    $hasJarLauncher = ($manifest -match "Main-Class:\s*org\.springframework\.boot\.loader\.launch\.JarLauncher")
    if (-not $hasJarLauncher) { $manifestFail += "$([IO.Path]::GetFileName($j)):Main-Class" }
    $entries = Get-JarEntries -JarPath $j
    $hasClasses = @($entries | Where-Object { $_ -like "BOOT-INF/classes/*" }).Count -gt 0
    $hasLib = @($entries | Where-Object { $_ -like "BOOT-INF/lib/*" }).Count -gt 0
    $hasLoader = @($entries | Where-Object { $_ -like "org/springframework/boot/loader/launch/JarLauncher*" }).Count -gt 0
    if (-not ($hasClasses -and $hasLib -and $hasLoader)) {
        $bootInfFail += "$([IO.Path]::GetFileName($j)):classes=$hasClasses lib=$hasLib loader=$hasLoader"
    }
}
Assert-Test -CaseId "UT-114-1" -Name "all 4 jars have Spring Boot fat-jar Main-Class (org.springframework.boot.loader.launch.JarLauncher)" `
    -Condition ($manifestFail.Count -eq 0) `
    -Detail "failures: $(if ($manifestFail) { $manifestFail -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-114-2" -Name "all 4 jars contain BOOT-INF/classes + BOOT-INF/lib + loader classes (java -jar executable)" `
    -Condition ($bootInfFail.Count -eq 0) `
    -Detail "failures: $(if ($bootInfFail) { $bootInfFail -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-115: BOOT-INF/lib contains spring-cloud-starter-bootstrap (P0)
# ----------------------------------------------------------------------------
$bootstrapMiss = @()
$bootstrapBadVer = @()
foreach ($j in $jarPaths) {
    $entries = Get-JarEntries -JarPath $j
    $bootstrapHits = @($entries | Where-Object { $_ -match "^BOOT-INF/lib/spring-cloud-starter-bootstrap-\d+\.\d+\.\d+(\.RELEASE)?\.jar$" })
    if ($bootstrapHits.Count -eq 0) {
        $bootstrapMiss += [IO.Path]::GetFileName($j)
    }
    else {
        $ver = ($bootstrapHits[0] -replace "^BOOT-INF/lib/spring-cloud-starter-bootstrap-", "") -replace "\.jar$", ""
        if ($ver -notmatch "^4\.1\.") { $bootstrapBadVer += "$([IO.Path]::GetFileName($j)):$ver" }
    }
}
Assert-Test -CaseId "UT-115-1" -Name "BOOT-INF/lib of all 4 jars contains spring-cloud-starter-bootstrap (TASK-001 fix in artifacts)" `
    -Condition ($bootstrapMiss.Count -eq 0) `
    -Detail "missing: $(if ($bootstrapMiss) { $bootstrapMiss -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-115-2" -Name "bootstrap version inside jars stays 4.1.x family (NOT 5.x)" `
    -Condition ($bootstrapBadVer.Count -eq 0) `
    -Detail "bad versions: $(if ($bootstrapBadVer) { $bootstrapBadVer -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-116: deploy/env.json holds 9 required variables, all non-empty (P0)
# ----------------------------------------------------------------------------
$envJson = Join-Path $deployDir "env.json"
$envObj = $null
if (Test-Path -LiteralPath $envJson) {
    $envObj = Get-Content -Raw -LiteralPath $envJson | ConvertFrom-Json
}
if ($null -eq $envObj) {
    Assert-Test -CaseId "UT-116-1" -Name "deploy/env.json found (required for startup scripts)" `
        -Condition $false -Detail "missing: $envJson"
}
else {
    $requiredKeys = @(
        "NACOS_ADDR", "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD",
        "REDIS_HOST", "REDIS_PORT", "RSA_PRIVATE_KEY", "RSA_PUBLIC_KEY"
    )
    $missingKeys = @($requiredKeys | Where-Object { -not ($envObj.PSObject.Properties.Name -contains $_) })
    Assert-Test -CaseId "UT-116-1" -Name "env.json contains all 9 required keys (NACOS_ADDR/DB_*/REDIS_*/RSA_*)" `
        -Condition ($missingKeys.Count -eq 0) `
        -Detail "missing: $(if ($missingKeys) { $missingKeys -join '; ' } else { 'none' })"
    $emptyKeys = @($requiredKeys | Where-Object { [string]::IsNullOrEmpty([string]$envObj.$_) })
    Assert-Test -CaseId "UT-116-2" -Name "all 9 required key values are non-empty strings" `
        -Condition ($emptyKeys.Count -eq 0) `
        -Detail "empty: $(if ($emptyKeys) { $emptyKeys -join '; ' } else { 'none' })"
}

# ----------------------------------------------------------------------------
# UT-117: startup scripts' $env: refs all resolve in env.json; jar paths OK (P1)
# ----------------------------------------------------------------------------
$startScripts = @(
    "deploy-start-gateway.ps1", "deploy-start-auth.ps1",
    "deploy-start-biz.ps1", "deploy-start-system.ps1"
)
$envKeyNames = @()
if ($null -ne $envObj) { $envKeyNames = @($envObj.PSObject.Properties.Name) }

$unresolvedDetail = @()
foreach ($s in $startScripts) {
    $sp = Join-Path $ProjectRoot (Join-Path "deploy\scripts" $s)
    if (-not (Test-Path -LiteralPath $sp)) {
        $unresolvedDetail += "${s}:script-missing"
        continue
    }
    $content = Get-Content -Raw -LiteralPath $sp
    $envRefs = @([regex]::Matches($content, '\$env:([A-Za-z_][A-Za-z0-9_]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $bad = @($envRefs | Where-Object { $envKeyNames -notcontains $_ })
    if ($bad.Count -gt 0) {
        $unresolvedDetail += "${s}:" + ($bad -join ",")
    }
}
Assert-Test -CaseId "UT-117-1" -Name 'every $env:<KEY> referenced by 4 startup scripts exists in env.json (no dangling refs)' `
    -Condition ($unresolvedDetail.Count -eq 0) `
    -Detail "unresolved: $(if ($unresolvedDetail) { $unresolvedDetail -join '; ' } else { 'none' })"

# jar path references in startup scripts point to deploy/ artifacts
$jarPathDetail = @()
foreach ($s in $startScripts) {
    $sp = Join-Path $ProjectRoot (Join-Path "deploy\scripts" $s)
    if (-not (Test-Path -LiteralPath $sp)) { $jarPathDetail += "${s}:script-missing"; continue }
    $content = Get-Content -Raw -LiteralPath $sp
    if ($content -match 'cloudoffice-[a-z-]+\.jar') {
        $refJar = $Matches[0]
        if ($refJar -notin $jars) { $jarPathDetail += "${s}:$refJar" }
    }
    else {
        $jarPathDetail += "${s}:no-jar-ref"
    }
}
Assert-Test -CaseId "UT-117-2" -Name "startup scripts reference deploy/ artifact jar names (cloudoffice-*.jar)" `
    -Condition ($jarPathDetail.Count -eq 0) `
    -Detail "bad refs: $(if ($jarPathDetail) { $jarPathDetail -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-118: regression guard - poms keep bootstrap dep; env.json keys keep
#         DER single-line Base64 contract (fix not reverted) (P1)
# ----------------------------------------------------------------------------
$moduleDirs = @(
    "cloudoffice-gateway", "cloudoffice-auth-service",
    "cloudoffice-biz-service", "cloudoffice-system-service"
)
$bootstrapReverted = @()
$fiveXHits = @()
foreach ($m in $moduleDirs) {
    $pom = Join-Path $ProjectRoot (Join-Path $m "pom.xml")
    $content = Get-Content -Raw -LiteralPath $pom
    if (-not $content.Contains("spring-cloud-starter-bootstrap")) {
        $bootstrapReverted += $m
    }
    else {
        # no explicit 5.x version in the bootstrap dependency block
        $idx = $content.IndexOf("spring-cloud-starter-bootstrap")
        $dEnd = $content.IndexOf("</dependency>", $idx)
        if ($dEnd -lt 0) { $dEnd = $content.Length }
        $block = $content.Substring($idx, $dEnd - $idx)
        $vMatch = [regex]::Match($block, '<version>\s*([^<]+?)\s*</version>')
        if ($vMatch.Success -and $vMatch.Groups[1].Value.Trim() -match '^5\.') {
            $fiveXHits += "${m}:$($vMatch.Groups[1].Value.Trim())"
        }
    }
}
Assert-Test -CaseId "UT-118-1" -Name "all 4 module poms still declare spring-cloud-starter-bootstrap (TASK-001 fix not reverted)" `
    -Condition ($bootstrapReverted.Count -eq 0) `
    -Detail "reverted: $(if ($bootstrapReverted) { $bootstrapReverted -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-118-2" -Name "no pom declares bootstrap with explicit 5.x version (incompatible Spring Cloud 2025.x)" `
    -Condition ($fiveXHits.Count -eq 0) `
    -Detail "5.x hits: $(if ($fiveXHits) { $fiveXHits -join '; ' } else { 'none' })"

# env.json RSA keys still DER single-line Base64 (format-feature assertions only)
if ($null -ne $envObj) {
    $pubVal = [string]$envObj.RSA_PUBLIC_KEY
    $pubOk = (-not ($pubVal -match '-----BEGIN|-----END')) -and (-not ($pubVal -match '[\r\n]'))
    $privVal = [string]$envObj.RSA_PRIVATE_KEY
    $privOk = (-not ($privVal -match '-----BEGIN|-----END')) -and (-not ($privVal -match '[\r\n]'))
    $strictOk = $false
    try {
        $null = [Convert]::FromBase64String($pubVal)
        $null = [Convert]::FromBase64String($privVal)
        $strictOk = $true
    } catch { $strictOk = $false }
    Assert-Test -CaseId "UT-118-3" -Name "env.json RSA keys keep DER single-line Base64 contract (no PEM header/footer/newline, strict decodable)" `
        -Condition ($pubOk -and $privOk -and $strictOk) `
        -Detail "public key ok: $pubOk, private key ok: $privOk, strict decode ok: $strictOk (values not printed)"
}

# ----------------------------------------------------------------------------
# UT-119: git change scope contains NO Controller/DTO/interface-layer,
#         business code or client (flutter) code changes (P1, negative)
# ----------------------------------------------------------------------------
$gitBase = @("-C", $ProjectRoot)
$changed = @()
$statusOut = @(& git @gitBase status --short) 2>$null
foreach ($line in $statusOut) {
    $line = $line.TrimEnd()
    if ($line.Length -gt 3) { $changed += $line.Substring(3).Trim().Trim('"') }
}
Write-Output ("-" * 70)
Write-Output "Git change list ($($changed.Count) entries):"
$changed | ForEach-Object { Write-Output "  $_" }
Write-Output ("-" * 70)

# interface-layer hits: Controller.java / DTO.java / gateway routing config (yml in gateway module / GatewayConfig)
$interfaceHits = @($changed | Where-Object {
    $p = $_.Replace("\", "/")
    ($p -match 'Controller\.java$') -or ($p -match 'DTO\.java$') -or
    ($p -match '^cloudoffice-gateway/src/main/resources/.*\.ya?ml$')
})
# business code hits: any *.java (excluding pom.xml build files which are not java source)
$javaHits = @($changed | Where-Object { $_ -match '\.java$' })
# client code hits: cloudoffice-flutter-app/ path (lib/, pubspec.yaml, build config)
$clientHits = @($changed | Where-Object { $_.Replace("\", "/").StartsWith("cloudoffice-flutter-app/") })

Assert-Test -CaseId "UT-119-1" -Name "git changes contain NO interface-layer files (Controller/DTO/gateway routing yml)" `
    -Condition ($interfaceHits.Count -eq 0) `
    -Detail "interface hits: $(if ($interfaceHits) { $interfaceHits -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-119-2" -Name "git changes contain NO business code (*.java sources)" `
    -Condition ($javaHits.Count -eq 0) `
    -Detail "java hits: $(if ($javaHits) { $javaHits -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-119-3" -Name "git changes contain NO client code (cloudoffice-flutter-app/)" `
    -Condition ($clientHits.Count -eq 0) `
    -Detail "client hits: $(if ($clientHits) { $clientHits -join '; ' } else { 'none' })"

# ----------------------------------------------------------------------------
# UT-120: each jar contains bootstrap.yml with nacos server-addr placeholder (P1)
# ----------------------------------------------------------------------------
$ymlMiss = @()
$addrBad = @()
foreach ($j in $jarPaths) {
    $yml = Get-JarEntryContent -JarPath $j -EntryName "BOOT-INF/classes/bootstrap.yml"
    if ([string]::IsNullOrEmpty($yml)) {
        $ymlMiss += [IO.Path]::GetFileName($j)
        continue
    }
    $discOk = $yml -match "discovery:\s*\r?\n\s*server-addr:\s*\$\{NACOS_ADDR:127\.0\.0\.1:8848\}"
    $confOk = $yml -match "config:\s*\r?\n\s*server-addr:\s*\$\{NACOS_ADDR:127\.0\.0\.1:8848\}"
    if (-not ($discOk -and $confOk)) {
        $addrBad += "$([IO.Path]::GetFileName($j)):discovery=$discOk config=$confOk"
    }
}
Assert-Test -CaseId "UT-120-1" -Name "all 4 jars contain BOOT-INF/classes/bootstrap.yml (Nacos bootstrap config in artifacts)" `
    -Condition ($ymlMiss.Count -eq 0) `
    -Detail "missing: $(if ($ymlMiss) { $ymlMiss -join '; ' } else { 'none' })"
Assert-Test -CaseId "UT-120-2" -Name 'bootstrap.yml nacos discovery/config server-addr use ${NACOS_ADDR:127.0.0.1:8848} placeholder' `
    -Condition ($addrBad.Count -eq 0) `
    -Detail "bad addr: $(if ($addrBad) { $addrBad -join '; ' } else { 'none' })"

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
