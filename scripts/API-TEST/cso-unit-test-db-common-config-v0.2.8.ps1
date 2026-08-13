# ============================================================================
# CloudStrollOffice (CSO) v0.2.8 - common config DB init Test (TASK-001)
# ----------------------------------------------------------------------------
# Coverage: TC-TASK001-001 ~ TC-TASK001-006 in version testcase
#           (docs/cso-v0.2.8/cso-testcase-v0.2.8.md)
#   TC-TASK001-001: database cloudstroll_office_common created (P0)
#   TC-TASK001-002: t_common_config table structure matches DBD 5.2.1 (P0)
#   TC-TASK001-003: indexes uk_service_group_key/idx_service_name/
#                   idx_config_group match DBD 6.2 (P0)
#   TC-TASK001-004: 17 seed rows covering 5 services (P0)
#   TC-TASK001-005: SQL script idempotent (re-run no error, no dup) (P0)
#   TC-TASK001-006: cloudstroll_office_auth 9 tables untouched (P0, regression)
# Usage:
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-db-common-config-v0.2.8.ps1
#   powershell -ExecutionPolicy Bypass -File cso-unit-test-db-common-config-v0.2.8.ps1 `
#       -ProjectRoot D:\path\to\repo [-MariaDbCli path-to-mariadb.exe]
# Exit code: 0 = all pass (SKIP not counted as failure), 1 = any failure
# NOTE:
#   ASCII only in this script to keep PowerShell 5.1 encoding safe.
#   DB connection parameters are read from deploy/env.json via load-env.ps1;
#   password passed through MYSQL_PWD env var, never in command line.
#   The SQL script (docs/cso-v0.2.8/cso-dbd-v0.2.8.sql) is executed and
#   verified for structure/seed data/idempotency/regression.
# ============================================================================
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$MariaDbCli = ""
)

$ErrorActionPreference = "Stop"
$script:Pass = 0
$script:Fail = 0
$script:Skip = 0
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
        $script:FailedCases += "$CaseId $Name ($Detail)"
        Write-Output "[FAIL] $CaseId $Name $Detail"
    }
}

function Invoke-MariaDbSql {
    param([string]$Sql)
    $env:MYSQL_PWD = $env:DB_PASSWORD
    try {
        $out = & $script:MariaDbCli -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USERNAME --default-character-set=utf8mb4 -N -e $Sql 2>&1
        $code = $LASTEXITCODE
        return @{ Output = $out; ExitCode = $code }
    }
    finally {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    }
}

function Invoke-MariaDbScript {
    param([string]$ScriptPath)
    $env:MYSQL_PWD = $env:DB_PASSWORD
    try {
        & cmd /c "`"$script:MariaDbCli`" -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USERNAME --default-character-set=utf8mb4 < `"$ScriptPath`"" 2>&1 | Out-Null
        return $LASTEXITCODE
    }
    finally {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    }
}

# ========== Load env (DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD) ==========
. (Join-Path $ProjectRoot "deploy\scripts\load-env.ps1")

if ([string]::IsNullOrEmpty($MariaDbCli)) {
    $candidates = @(
        "C:\Program Files\MariaDB 10.11\bin\mariadb.exe",
        "C:\Program Files\MariaDB 10.6\bin\mariadb.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $MariaDbCli = $c; break }
    }
}
if ([string]::IsNullOrEmpty($MariaDbCli) -or -not (Test-Path -LiteralPath $MariaDbCli)) {
    Write-Output "[FAIL] mariadb client not found; pass -MariaDbCli path"
    exit 1
}
$script:MariaDbCli = $MariaDbCli

$sqlPath = Join-Path $ProjectRoot "docs\cso-v0.2.8\cso-dbd-v0.2.8.sql"
if (-not (Test-Path -LiteralPath $sqlPath)) {
    Write-Output "[FAIL] SQL script not found: $sqlPath"
    exit 1
}

Write-Output "==============================================================="
Write-Output "CloudStrollOffice v0.2.8 - common config DB init test (TASK-001)"
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output "MariaDB cli: $MariaDbCli"
Write-Output "DB: $env:DB_HOST`:$env:DB_PORT as $env:DB_USERNAME"
Write-Output "==============================================================="

# ---------- TC-TASK001-001: database created ----------
Write-Output "[1/6] TC-TASK001-001 database cloudstroll_office_common created"
$r = Invoke-MariaDbSql -Sql "SHOW DATABASES LIKE 'cloudstroll_office_common';"
Assert-Test "TC-TASK001-001" "database cloudstroll_office_common exists" `
    ($r.ExitCode -eq 0 -and ($r.Output -match "cloudstroll_office_common")) `
    "exit=$($r.ExitCode) out=$($r.Output -join ';')"

# ---------- TC-TASK001-002: table structure matches DBD 5.2.1 ----------
Write-Output "[2/6] TC-TASK001-002 table t_common_config structure"
$r = Invoke-MariaDbSql -Sql "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='cloudstroll_office_common' AND TABLE_NAME='t_common_config' ORDER BY ORDINAL_POSITION;"
$expectedCols = @('id','service_name','config_group','config_key','config_value','data_type','description','sensitive','status','create_time','update_time','deleted')
$cols = @()
foreach ($line in $r.Output) {
    $fields = $line -split "`t"
    if ($fields.Count -ge 1) { $cols += $fields[0].Trim() }
}
$missing = $expectedCols | Where-Object { $_ -notin $cols }
Assert-Test "TC-TASK001-002" "12 columns present and match DBD 5.2.1" `
    ($r.ExitCode -eq 0 -and $missing.Count -eq 0 -and $cols.Count -eq 12) `
    "cols=$($cols -join ',') missing=$($missing -join ',')"

# type spot checks
$r = Invoke-MariaDbSql -Sql "SELECT COLUMN_NAME, COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='cloudstroll_office_common' AND TABLE_NAME='t_common_config' AND COLUMN_NAME IN ('id','config_key','config_value','data_type','sensitive');"
$typeMap = @{}
foreach ($line in $r.Output) {
    $fields = $line -split "`t"
    if ($fields.Count -ge 2) { $typeMap[$fields[0].Trim()] = $fields[1].Trim() }
}
Assert-Test "TC-TASK001-002" "id BIGINT / config_key VARCHAR(100) / config_value TEXT / data_type VARCHAR(20) / sensitive TINYINT" `
    ($typeMap['id'] -match 'bigint' -and $typeMap['config_key'] -match 'varchar\(100\)' -and $typeMap['config_value'] -eq 'text' -and $typeMap['data_type'] -match 'varchar\(20\)' -and $typeMap['sensitive'] -match 'tinyint') `
    ($typeMap | Out-String)

# ---------- TC-TASK001-003: indexes match DBD 6.2 ----------
Write-Output "[3/6] TC-TASK001-003 indexes"
$r = Invoke-MariaDbSql -Sql "SHOW INDEX FROM cloudstroll_office_common.t_common_config;"
$indexMap = @{}
foreach ($line in $r.Output) {
    $fields = $line -split "`t"
    if ($fields.Count -ge 3) {
        $key = $fields[2].Trim()
        $col = $fields[4].Trim()
        if (-not $indexMap.ContainsKey($key)) { $indexMap[$key] = @() }
        $indexMap[$key] += $col
    }
}
Assert-Test "TC-TASK001-003" "uk_service_group_key unique (service_name,config_group,config_key)" `
    ($indexMap.ContainsKey('uk_service_group_key') -and ($indexMap['uk_service_group_key'] -join ',') -eq 'service_name,config_group,config_key') `
    ("keys=" + ($indexMap.Keys -join ',') + " uk=" + ($indexMap['uk_service_group_key'] -join ','))
Assert-Test "TC-TASK001-003" "idx_service_name exists on service_name" `
    ($indexMap.ContainsKey('idx_service_name') -and $indexMap['idx_service_name'][0] -eq 'service_name') `
    ("idx_service_name=" + ($indexMap['idx_service_name'] -join ','))
Assert-Test "TC-TASK001-003" "idx_config_group exists on (service_name,config_group)" `
    ($indexMap.ContainsKey('idx_config_group') -and ($indexMap['idx_config_group'] -join ',') -eq 'service_name,config_group') `
    ("idx_config_group=" + ($indexMap['idx_config_group'] -join ','))

# ---------- TC-TASK001-004: 17 seed rows across 5 services ----------
Write-Output "[4/6] TC-TASK001-004 seed data 17 rows / 5 services"
$r = Invoke-MariaDbSql -Sql "SELECT COUNT(*) FROM cloudstroll_office_common.t_common_config;"
Assert-Test "TC-TASK001-004" "17 seed rows inserted" `
    ($r.ExitCode -eq 0 -and $r.Output -match '^17$') `
    "count=$($r.Output -join ';')"

$r = Invoke-MariaDbSql -Sql "SELECT COUNT(DISTINCT service_name) FROM cloudstroll_office_common.t_common_config;"
Assert-Test "TC-TASK001-004" "5 distinct services covered" `
    ($r.ExitCode -eq 0 -and $r.Output -match '^5$') `
    "svc=$($r.Output -join ';')"

# spot checks: code-length=6 / cache-ttl-seconds=300
$r = Invoke-MariaDbSql -Sql "SELECT config_value FROM cloudstroll_office_common.t_common_config WHERE service_name='auth-service' AND config_group='verification' AND config_key='code-length';"
Assert-Test "TC-TASK001-004" "auth-service verification/code-length = 6" `
    ($r.ExitCode -eq 0 -and $r.Output -match '^6$') `
    "value=$($r.Output -join ';')"

$r = Invoke-MariaDbSql -Sql "SELECT config_value FROM cloudstroll_office_common.t_common_config WHERE service_name='common' AND config_group='config' AND config_key='cache-ttl-seconds';"
Assert-Test "TC-TASK001-004" "common config/cache-ttl-seconds = 300" `
    ($r.ExitCode -eq 0 -and $r.Output -match '^300$') `
    "value=$($r.Output -join ';')"

# ---------- TC-TASK001-005: SQL script idempotent ----------
Write-Output "[5/6] TC-TASK001-005 SQL script idempotent re-run"
$code = Invoke-MariaDbScript -ScriptPath $sqlPath
Assert-Test "TC-TASK001-005" "re-run SQL script exits 0 (no error)" `
    ($code -eq 0) "exit=$code"

$r = Invoke-MariaDbSql -Sql "SELECT COUNT(*) FROM cloudstroll_office_common.t_common_config;"
Assert-Test "TC-TASK001-005" "row count stays 17 after re-run (no dup)" `
    ($r.ExitCode -eq 0 -and $r.Output -match '^17$') `
    "count=$($r.Output -join ';')"

# ---------- TC-TASK001-006: auth DB 9 tables untouched ----------
Write-Output "[6/6] TC-TASK001-006 auth DB regression"
$r = Invoke-MariaDbSql -Sql "SHOW TABLES FROM cloudstroll_office_auth;"
$tables = @()
foreach ($line in $r.Output) {
    if ($line.Trim().Length -gt 0) { $tables += $line.Trim() }
}
$expectedAuthTables = @(
    't_auth_tenant','t_auth_user','t_auth_role','t_auth_permission',
    't_auth_user_role','t_auth_role_permission','t_auth_login_log',
    't_auth_oauth_account','t_auth_verification_code'
)
$missingAuth = $expectedAuthTables | Where-Object { $_ -notin $tables }
$extraAuth = $tables | Where-Object { $_ -notin $expectedAuthTables }
Assert-Test "TC-TASK001-006" "auth DB has exactly 9 baseline tables (no add/remove)" `
    ($missingAuth.Count -eq 0 -and $extraAuth.Count -eq 0) `
    "tables=$($tables -join ',') missing=$($missingAuth -join ',') extra=$($extraAuth -join ',')"

Write-Output "==============================================================="
Write-Output "Summary: PASS=$script:Pass FAIL=$script:Fail SKIP=$script:Skip"
if ($script:FailedCases.Count -gt 0) {
    Write-Output "Failed cases:"
    foreach ($c in $script:FailedCases) { Write-Output "  - $c" }
}
Write-Output "==============================================================="
if ($script:Fail -gt 0) { exit 1 }
exit 0
