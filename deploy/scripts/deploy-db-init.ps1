# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 数据库初始化脚本 (Windows)
.DESCRIPTION
  创建业务数据库并初始化表结构和初始数据
  前置条件: MariaDB 已启动且可连接
  S-04 修复：连接参数默认值不再硬编码地址/凭据（v0.1.7 遗留），
  一律从 env.json（经 load-env 加载）读取；口令经 MYSQL_PWD 环境变量传递，不出现在进程命令行。
.PARAMETER DbHost
  数据库主机地址（默认从 env.json 的 DB_HOST 读取）
.PARAMETER DbPort
  数据库端口（默认从 env.json 的 DB_PORT 读取）
.PARAMETER DbUser
  数据库用户名（默认从 env.json 的 DB_USERNAME 读取）
.PARAMETER DbPassword
  数据库密码（默认从 env.json 的 DB_PASSWORD 读取）
.EXAMPLE
  .\deploy\scripts\deploy-db-init.ps1
#>

param(
  [string]$DbHost = "",
  [int]$DbPort = 0,
  [string]$DbUser = "",
  [string]$DbPassword = ""
)

$ProjectDir = Split-Path -Parent $PSScriptRoot
$RootDir = Split-Path -Parent $ProjectDir

# ========== 从 env.json 加载环境变量 ==========
. $PSScriptRoot\load-env.ps1
# 参数未显式传入（默认空）时，一律从 env.json 读取（S-04 修复：无硬编码默认值）
if ([string]::IsNullOrEmpty($DbHost)) { $DbHost = $env:DB_HOST }
if ($DbPort -le 0) { $DbPort = [int]($env:DB_PORT -replace '\D','') }
if ([string]::IsNullOrEmpty($DbUser)) { $DbUser = $env:DB_USERNAME }
if ([string]::IsNullOrEmpty($DbPassword)) { $DbPassword = $env:DB_PASSWORD }
$SqlDir5 = Join-Path $RootDir "scripts\sql\auth-init-v0.1.5.sql"
$SqlDir6 = Join-Path $RootDir "scripts\sql\auth-init-v0.1.6.sql"

Write-Host "=============================================="
Write-Host "  云漫智企 - 数据库初始化"
Write-Host "=============================================="
Write-Host "  数据库主机: $DbHost`:$DbPort"
Write-Host "  用户名:     $DbUser"
Write-Host "=============================================="
Write-Host ""

# 检查 SQL 文件是否存在
if (-not (Test-Path $SqlDir5)) {
  Write-Host "❌ 错误: 未找到 $SqlDir5" -ForegroundColor Red
  exit 1
}
if (-not (Test-Path $SqlDir6)) {
  Write-Host "❌ 错误: 未找到 $SqlDir6" -ForegroundColor Red
  exit 1
}

# 步骤 1: 执行 v0.1.5 基础初始化脚本
Write-Host "[1/3] 执行 v0.1.5 基础初始化脚本..."
# 口令经 MYSQL_PWD 环境变量传递（S-04/P8 修复：不出现于进程命令行；MariaDB 客户端支持）
$oldMysqlPwd = $env:MYSQL_PWD
$env:MYSQL_PWD = $DbPassword
Write-Host "  执行: mariadb -h $DbHost -P $DbPort -u $DbUser -p'****' < auth-init-v0.1.5.sql"

try {
  Get-Content $SqlDir5 | mariadb -h $DbHost -P $DbPort -u $DbUser 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ v0.1.5 基础初始化完成（7 张核心表 + 初始数据）" -ForegroundColor Green
  } else {
    throw "SQL 执行失败"
  }
} catch {
  Write-Host "  ❌ v0.1.5 初始化失败: $_" -ForegroundColor Red
  if ($null -eq $oldMysqlPwd) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $oldMysqlPwd }
  exit 1
}

# 步骤 2: 执行 v0.1.6 增量脚本
Write-Host "[2/3] 执行 v0.1.6 增量脚本..."
try {
  Get-Content $SqlDir6 | mariadb -h $DbHost -P $DbPort -u $DbUser 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ v0.1.6 增量初始化完成（新增 2 张表 + 字段扩展）" -ForegroundColor Green
  } else {
    throw "SQL 执行失败"
  }
} catch {
  Write-Host "  ❌ v0.1.6 初始化失败: $_" -ForegroundColor Red
  if ($null -eq $oldMysqlPwd) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $oldMysqlPwd }
  exit 1
}

# 步骤 3: 验证初始化结果
Write-Host "[3/3] 验证数据库初始化..."

Write-Host "  --- 数据库列表 ---"
mariadb -h $DbHost -P $DbPort -u $DbUser -e "SHOW DATABASES LIKE 'cloudstroll_office_%';"
Write-Host ""

Write-Host "  --- cloudstroll_office_auth 表列表 ---"
mariadb -h $DbHost -P $DbPort -u $DbUser -e "USE cloudstroll_office_auth; SHOW TABLES;"
Write-Host ""

Write-Host "  --- 租户表初始数据 ---"
mariadb -h $DbHost -P $DbPort -u $DbUser -e "USE cloudstroll_office_auth; SELECT id, tenant_name, tenant_code, status FROM t_auth_tenant;"
Write-Host ""

Write-Host "  --- 用户表初始数据 ---"
mariadb -h $DbHost -P $DbPort -u $DbUser -e "USE cloudstroll_office_auth; SELECT id, login_name, real_name, status FROM t_auth_user;"
Write-Host ""

# 恢复原 MYSQL_PWD（避免污染后续命令/会话）
if ($null -eq $oldMysqlPwd) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $oldMysqlPwd }

Write-Host "=============================================="
Write-Host "  数据库初始化完成！"
Write-Host "=============================================="
Write-Host ""
Write-Host "接下来可以编译打包并启动服务："
Write-Host "  编译:   mvn clean package -DskipTests"
Write-Host "  启动:   按顺序启动 Gateway → auth-service → biz-service → system-service"
