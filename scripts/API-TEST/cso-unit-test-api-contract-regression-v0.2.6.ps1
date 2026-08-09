# ============================================================================
# CloudStrollOffice (CSO) v0.2.6 - API Contract Regression Unit Test (TASK-005)
# ----------------------------------------------------------------------------
# Coverage: UT-126 ~ UT-131 in task testcase
#           (docs/cso-v0.2.6/task_TASK-005/testcase.md)
#   UT-126: v0.2.5 regression script cso-api-test-v0.2.5.py fully contains
#           TC-046~TC-051 (6 cases, 27 assertions) (P0)
#   UT-127: git change list (2b343ac..HEAD) has NO Controller / gateway route
#           structure / ApiResult-ResponseBody change (P0, negative)
#   UT-128: git change list has NO cloudoffice-flutter-app/lib/ runtime code
#           change (P0, negative)
#   UT-129: API contract static check - docs/cso-api.md (baseline) vs
#           docs/cso-v0.2.6/cso-api-v0.2.6.md interface list identical
#           item-by-item (API-001~API-033, 33=33) (P1)
#   UT-130: cso-api-v0.2.6.md explicitly declares no new/changed/deleted
#           interface + contract consistency note exists (P1, negative)
#   UT-131: non-interface-layer notes - LoginUserDTO internal field
#           tokenSignature + GlobalExceptionHandler status mapping do NOT
#           constitute contract change (P1)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-api-contract-regression-v0.2.6.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-api-contract-regression-v0.2.6.ps1 `
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

function Normalize-Row {
    # normalize a markdown table data row: trim each column, join with '|'
    param([string]$Row)
    $cols = $Row.Trim('|') -split '\|'
    $cols = @($cols | ForEach-Object { $_.Trim() })
    return ($cols -join '|')
}

Write-Output ("=" * 70)
Write-Output "CSO v0.2.6 API Contract Regression Unit Test (TASK-005, UT-126~UT-131)"
Write-Output "Project root: $ProjectRoot"
Write-Output "Start time : $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output ("=" * 70)

# ----------------------------------------------------------------------------
# common config
# ----------------------------------------------------------------------------
$v025Script = Join-Path $ProjectRoot "scripts\API-TEST\cso-api-test-v0.2.5.py"
$mainApiDoc = Join-Path $ProjectRoot "docs\cso-api.md"
$v26ApiDoc = Join-Path $ProjectRoot "docs\cso-v0.2.6\cso-api-v0.2.6.md"
$gitBaseCommit = "2b343ac"

# git change list: git diff --name-status 2b343ac..HEAD (paths only)
$gitBase = @("-C", $ProjectRoot)
$nameStatus = @(& git @gitBase diff --name-status "$gitBaseCommit..HEAD") 2>$null
$changed = @($nameStatus | ForEach-Object {
    $line = $_.TrimEnd()
    if ($line.Length -gt 2) { $line.Substring(2).Trim().Trim('"') } else { "" }
} | Where-Object { $_ -ne "" })

# ----------------------------------------------------------------------------
# UT-126: v0.2.5 regression script fully contains TC-046~TC-051 (P0)
# ----------------------------------------------------------------------------
$scriptExists = Test-Path -LiteralPath $v025Script -PathType Leaf
if (-not $scriptExists) {
    Assert-Test -CaseId "UT-126-1" -Name "cso-api-test-v0.2.5.py exists (534 lines, 6 cases, 27 assertions)" `
        -Condition $false -Detail "script not found: $v025Script"
    Assert-Test -CaseId "UT-126-2" -Name "27 assertion ids (TC-046 3 / TC-047 4 / TC-048 5 / TC-049 5 / TC-050 5 / TC-051 5) all present" `
        -Condition $false -Detail "script missing"
    Assert-Test -CaseId "UT-126-3" -Name "TC-046-3 optional (skipped=True) + exit code 0 convention + argv project root" `
        -Condition $false -Detail "script missing"
}
else {
    $v025Text = Read-Utf8File -Path $v025Script

    # 1. case ids TC-046 ~ TC-051 all present (no gap)
    $missingCases = @(46..51 | Where-Object { -not $v025Text.Contains(("TC-{0:D3}" -f $_)) })
    Assert-Test -CaseId "UT-126-1" -Name "cso-api-test-v0.2.5.py contains TC-046~TC-051 (6 cases, no gap)" `
        -Condition ($missingCases.Count -eq 0) `
        -Detail ("missing ids: " + $(if ($missingCases.Count -eq 0) { "none" } else { $missingCases -join ", " }))

    # 2. assertion composition: 27 assertion ids total
    $assertGroups = @(
        @("TC-046-1", "TC-046-2", "TC-046-3"),
        @("TC-047-1", "TC-047-2", "TC-047-2b", "TC-047-3"),
        @("TC-048-1", "TC-048-2", "TC-048-2b", "TC-048-3", "TC-048-4"),
        @("TC-049-1", "TC-049-2", "TC-049-2b", "TC-049-3", "TC-049-4"),
        @("TC-050-1", "TC-050-2", "TC-050-2b", "TC-050-2c", "TC-050-3"),
        @("TC-051-1", "TC-051-2", "TC-051-2b", "TC-051-3", "TC-051-4")
    )
    $missingAsserts = @()
    foreach ($g in $assertGroups) {
        foreach ($a in $g) {
            if (-not $v025Text.Contains($a)) { $missingAsserts += $a }
        }
    }
    $totalAsserts = ($assertGroups | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Assert-Test -CaseId "UT-126-2" -Name "assertion composition check: 27 ids present (26 target PASS + TC-046-3 optional)" `
        -Condition ($missingAsserts.Count -eq 0 -and $totalAsserts -eq 27) `
        -Detail ("total: $totalAsserts, missing: " + $(if ($missingAsserts.Count -eq 0) { "none" } else { $missingAsserts -join ", " }))

    # 3. TC-046-3 optional scene (report skipped=True) + exit code 0 convention + argv run mode
    $skipOk = ($v025Text.Contains("TC-046-3") -and $v025Text.Contains("skipped=True"))
    $exitOk = $v025Text.Contains("return 0 if FAIL == 0 else 1")
    $argvOk = $v025Text.Contains("sys.argv")
    Assert-Test -CaseId "UT-126-3" -Name "TC-046-3 optional (skipped=True) + exit 0=all-pass + python <project root> argv mode" `
        -Condition ($skipOk -and $exitOk -and $argvOk) `
        -Detail ("skipped convention: $skipOk, exit code convention: $exitOk, argv mode: $argvOk")
}

# ----------------------------------------------------------------------------
# UT-127: git change list has NO interface-layer change (P0, negative)
# ----------------------------------------------------------------------------
# 1. no Controller file / controller path change (7 Controllers not in list)
$controllerHits = @($changed | Where-Object {
    $p = $_.Replace("\", "/")
    ($p -match 'Controller\.java$') -or ($p -match '/controller/')
})
Assert-Test -CaseId "UT-127-1" -Name "git change list has NO *Controller.java / controller/ path (auth 5 + biz/system 1 each untouched)" `
    -Condition ($controllerHits.Count -eq 0) `
    -Detail ("controller hits: " + $(if ($controllerHits.Count -eq 0) { "none" } else { $controllerHits -join "; " }))

# 2. no gateway route structure change (application.yml whitelist tweak is NOT a route change)
$gwYml = @($changed | Where-Object { $_ -match 'cloudoffice-gateway/.*application\.ya?ml$' })
$routeBad = @()
if ($gwYml.Count -gt 0) {
    foreach ($ym in $gwYml) {
        $ymlDiff = @(& git @gitBase diff "$gitBaseCommit..HEAD" -- $ym) 2>$null
        $routeBad += @($ymlDiff | Where-Object {
            ($_ -match '^\+\s*(routes|predicates|filters|id:)\s*:') -or ($_ -match '^\-\s*(routes|predicates|filters|id:)\s*:') -or
            ($_ -match 'RouteDefinition')
        })
    }
}
Assert-Test -CaseId "UT-127-2" -Name "gateway application.yml has NO route structure change (routes/predicates/filters untouched)" `
    -Condition ($routeBad.Count -eq 0) `
    -Detail ("route-structure diff lines: " + $(if ($routeBad.Count -eq 0) { "none" } else { $routeBad -join "; " }))

# 3. ApiResult / PageResult / ErrorCode response-body files unchanged
$respBodyHits = @($changed | Where-Object {
    $_ -match 'ApiResult\.java$' -or $_ -match 'PageResult\.java$' -or $_ -match 'ErrorCode\.java$'
})
Assert-Test -CaseId "UT-127-3" -Name "ApiResult.java / PageResult.java / ErrorCode.java NOT in change list (response-body structure intact)" `
    -Condition ($respBodyHits.Count -eq 0) `
    -Detail ("response-body hits: " + $(if ($respBodyHits.Count -eq 0) { "none" } else { $respBodyHits -join "; " }))

# ----------------------------------------------------------------------------
# UT-128: git change list has NO client lib/ runtime code change (P0, negative)
# ----------------------------------------------------------------------------
$clientHits = @($changed | Where-Object { $_.Replace("\", "/").StartsWith("cloudoffice-flutter-app/") })
Assert-Test -CaseId "UT-128-1" -Name "git change list has NO cloudoffice-flutter-app/ file (lib/ runtime code zero change)" `
    -Condition ($clientHits.Count -eq 0) `
    -Detail ("client hits: " + $(if ($clientHits.Count -eq 0) { "none" } else { $clientHits -join "; " }))

# ----------------------------------------------------------------------------
# UT-129: API contract static check - baseline vs v0.2.6 list identical (P1)
# ----------------------------------------------------------------------------
$mainExists = Test-Path -LiteralPath $mainApiDoc -PathType Leaf
$v26Exists = Test-Path -LiteralPath $v26ApiDoc -PathType Leaf
if (-not ($mainExists -and $v26Exists)) {
    Assert-Test -CaseId "UT-129-1" -Name "both API docs exist and each has 33 interface rows" `
        -Condition $false -Detail "docs/cso-api.md exists: $mainExists, docs/cso-v0.2.6/cso-api-v0.2.6.md exists: $v26Exists"
    Assert-Test -CaseId "UT-129-2" -Name "33 rows identical item-by-item (id/name/method/path/auth)" `
        -Condition $false -Detail "docs missing"
    Assert-Test -CaseId "UT-129-3" -Name "key endpoint spot check (API-001/004/012/032/033)" `
        -Condition $false -Detail "docs missing"
}
else {
    $mainDoc = Read-Utf8File -Path $mainApiDoc
    $v26Doc = Read-Utf8File -Path $v26ApiDoc

    # 1. interface list rows: lines starting with "| API-XXX |" inside chapter 1 table
    $mainRows = @([regex]::Matches($mainDoc, '(?m)^\|\s*API-\d{3}\s*\|[^\r\n]*') | ForEach-Object { $_.Value.Trim() })
    $v26Rows = @([regex]::Matches($v26Doc, '(?m)^\|\s*API-\d{3}\s*\|[^\r\n]*') | ForEach-Object { $_.Value.Trim() })
    Assert-Test -CaseId "UT-129-1" -Name "interface list rows: docs/cso-api.md = 33 AND cso-api-v0.2.6.md = 33 (33=33)" `
        -Condition ($mainRows.Count -eq 33 -and $v26Rows.Count -eq 33) `
        -Detail ("main: $($mainRows.Count) rows, v0.2.6: $($v26Rows.Count) rows (expected 33 each)")

    # 2. item-by-item compare (normalized: id|name|method|path|note|auth)
    $mNorm = @($mainRows | ForEach-Object { Normalize-Row $_ })
    $vNorm = @($v26Rows | ForEach-Object { Normalize-Row $_ })
    $diffCount = -1
    if ($mNorm.Count -eq $vNorm.Count -and $mNorm.Count -eq 33) {
        $diffCount = 0
        for ($i = 0; $i -lt 33; $i++) {
            if ($mNorm[$i] -ne $vNorm[$i]) { $diffCount++ }
        }
    }
    Assert-Test -CaseId "UT-129-2" -Name "33 interface rows identical item-by-item (id/name/method/path/note/auth, no add/change/delete)" `
        -Condition ($diffCount -eq 0) `
        -Detail ("differing rows: " + $(if ($diffCount -eq 0) { "0/33" } else { "$diffCount/33" }))

    # 3. key endpoint spot check: API-001 login whitelist / API-004 logout /
    #    API-012 health whitelist / API-032 biz / API-033 system
    $spotOk = $true
    $spotDetail = @()
    $spotRules = @(
        @("API-001", "/api/v1/auth/login", "white"),
        @("API-004", "/api/v1/auth/logout", "auth"),
        @("API-012", "/api/v1/auth/health", "white"),
        @("API-032", "/api/v1/biz/health", ""),
        @("API-033", "/api/v1/system/health", "")
    )
    foreach ($doc in @($mainDoc, $v26Doc)) {
        foreach ($r in $spotRules) {
            $row = [regex]::Match($doc, '(?m)^\|\s*' + [regex]::Escape($r[0]) + '\s*\|[^\r\n]*').Value
            if (-not $row) { $spotOk = $false; $spotDetail += "$($r[0]):row-missing"; continue }
            if (-not $row.Contains($r[1])) { $spotOk = $false; $spotDetail += "$($r[0]):path-missing" }
            if ($r[2] -eq "white" -and -not $row.Contains("白名单")) { $spotOk = $false; $spotDetail += "$($r[0]):whitelist-flag-missing" }
        }
    }
    Assert-Test -CaseId "UT-129-3" -Name "key endpoint spot check (API-001 login whitelist / API-004 logout / API-012 health whitelist / API-032 biz / API-033 system) both docs" `
        -Condition $spotOk `
        -Detail ("spot issues: " + $(if ($spotDetail.Count -eq 0) { "none" } else { $spotDetail -join "; " }))
}

# ----------------------------------------------------------------------------
# UT-130: cso-api-v0.2.6.md declares no new/changed/deleted interface (P1)
# ----------------------------------------------------------------------------
if (-not $v26Exists) {
    Assert-Test -CaseId "UT-130-1" -Name "chapter 0 declares no new / no change / no delete interface (3 statements)" `
        -Condition $false -Detail "cso-api-v0.2.6.md missing"
    Assert-Test -CaseId "UT-130-2" -Name "chapter 1 list contains API-001 and API-033 (head+tail complete)" `
        -Condition $false -Detail "cso-api-v0.2.6.md missing"
    Assert-Test -CaseId "UT-130-3" -Name "contract consistency note exists (fix scope limited to build/dependency + key contract)" `
        -Condition $false -Detail "cso-api-v0.2.6.md missing"
}
else {
    $v26Doc = Read-Utf8File -Path $v26ApiDoc

    # 1. chapter 0 (version change note) declares all three statements
    $chap0 = $v26Doc
    $c0 = $v26Doc.IndexOf("## 0.")
    $c1 = $v26Doc.IndexOf("## 1.")
    if ($c0 -ge 0 -and $c1 -gt $c0) { $chap0 = $v26Doc.Substring($c0, $c1 - $c0) }
    $s1 = $chap0.Contains("无新增接口")
    $s2 = $chap0.Contains("无接口变更")
    $s3 = $chap0.Contains("无接口删除")
    Assert-Test -CaseId "UT-130-1" -Name "cso-api-v0.2.6.md chapter 0 declares no-new + no-change + no-delete interface (all 3 statements)" `
        -Condition ($s1 -and $s2 -and $s3) `
        -Detail ("no-new: $s1, no-change: $s2, no-delete: $s3 (all must be True)")

    # 2. interface list contains API-001 (head) and API-033 (tail)
    $has001 = $v26Doc.Contains("| API-001 |")
    $has033 = $v26Doc.Contains("| API-033 |")
    Assert-Test -CaseId "UT-130-2" -Name "chapter 1 interface list contains API-001 and API-033 (33 interfaces complete)" `
        -Condition ($has001 -and $has033) `
        -Detail ("API-001 row: $has001, API-033 row: $has033")

    # 3. contract consistency note at the end (fix scope limited to build/dependency & key contract, no Controller/DTO/response touch)
    $note1 = $v26Doc.Contains("不触碰接口层")
    $note2 = $v26Doc.Contains("Controller/DTO/响应体")
    $note3 = $v26Doc.Contains("构建/依赖配置与密钥格式契约")
    Assert-Test -CaseId "UT-130-3" -Name "contract consistency note exists (fix scope: build/dependency + key contract, no Controller/DTO/response-body touch)" `
        -Condition ($note1 -and $note2 -and $note3) `
        -Detail ("no-interface-touch note: $note1, Controller/DTO/response note: $note2, fix-scope note: $note3")
}

# ----------------------------------------------------------------------------
# UT-131: non-interface-layer notes - LoginUserDTO & GlobalExceptionHandler (P1)
# ----------------------------------------------------------------------------
# 1. LoginUserDTO.java: in change list, added field lines only tokenSignature (internal field)
$dtoHit = @($changed | Where-Object { $_ -match 'LoginUserDTO\.java$' } | Select-Object -First 1)
$dtoOk = $false
$dtoDetail = "LoginUserDTO.java not in change list"
if ($dtoHit.Count -gt 0) {
    $dtoDiff = @(& git @gitBase diff "$gitBaseCommit..HEAD" -- $dtoHit) 2>$null
    $added = @($dtoDiff | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' })
    $fieldLines = @($added | Where-Object { $_ -match 'private\s+' })
    $otherFields = @($fieldLines | Where-Object { $_ -notmatch 'tokenSignature' })
    $hasTokenSig = @($added | Where-Object { $_ -match 'tokenSignature' }).Count -gt 0
    $dtoOk = ($hasTokenSig -and $otherFields.Count -eq 0)
    $dtoDetail = "added lines: $($added.Count), field lines: $($fieldLines.Count), non-tokenSignature field lines: $($otherFields.Count)"
}
Assert-Test -CaseId "UT-131-1" -Name "LoginUserDTO.java change = internal field tokenSignature ONLY (no other field/contract change)" `
    -Condition $dtoOk -Detail $dtoDetail

# 2. GlobalExceptionHandler.java: in change list, adds error-code -> HTTP status
#    mapping (HttpStatus.resolve) + MissingRequestHeaderException -> 400;
#    ApiResult structure & 29 error codes untouched (UT-127-3)
$gehHit = @($changed | Where-Object { $_ -match 'GlobalExceptionHandler\.java$' } | Select-Object -First 1)
$gehOk = $false
$gehDetail = "GlobalExceptionHandler.java not in change list"
if ($gehHit.Count -gt 0) {
    $gehDiff = @(& git @gitBase diff "$gitBaseCommit..HEAD" -- $gehHit) 2>$null
    $added = @($gehDiff | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' })
    $hasResolve = @($added | Where-Object { $_ -match 'HttpStatus\.resolve' }).Count -gt 0
    $hasMissingHeader = @($added | Where-Object { $_ -match 'MissingRequestHeaderException' }).Count -gt 0
    $gehOk = ($hasResolve -and $hasMissingHeader)
    $gehDetail = "HttpStatus.resolve mapping: $hasResolve, MissingRequestHeaderException->400: $hasMissingHeader (ApiResult & 29 ErrorCode enum intact per UT-127-3)"
}
Assert-Test -CaseId "UT-131-2" -Name "GlobalExceptionHandler.java change = error-code->HTTP status mapping (409/429/403) + MissingRequestHeader->400 only" `
    -Condition $gehOk -Detail $gehDetail

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
