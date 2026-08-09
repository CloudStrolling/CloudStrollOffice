<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 环境变量注入脚本 (Windows PowerShell) 【已弃用】

.DESCRIPTION
  ⚠️ 安全警告（代码审核 S-01 修复说明）：
     本文件历史版本曾硬编码真实数据库口令与 RSA 私钥/公钥，并随 TASK-003
     提交入库，相关凭据已视为泄露。所有部署环境必须立即轮换：
       1. 数据库口令：重新设置 MariaDB 密码并更新 deploy/env.json；
       2. RSA 密钥对：运行 deploy/scripts/deploy-rsa-keygen.ps1 重新生成，
          更新 deploy/env.json 的 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY，
          并同步 Nacos 配置。
     本脚本自 v0.2.5 修复起不再包含任何真实凭据，仅保留占位符。

  ⚠️ 本脚本已弃用，现行推荐方式：
     复制 deploy/env.example.json 为 deploy/env.json 并填写配置，
     运行服务时由 deploy/scripts/load-env.ps1 自动加载。

  本脚本保留仅用于兼容旧流程：
     敏感变量优先从 deploy/env.json 读取；若未配置，则提示通过
     环境变量或交互输入注入（不再内嵌任何真实值）。

.USAGE
  # 现行方式（推荐）：
  Copy-Item deploy/env.example.json deploy/env.json   # 编辑填写实际值
  .\deploy\scripts\load-env.ps1                        # 加载环境变量

  # 兼容方式（本脚本）：敏感值优先取 deploy/env.json，未配置时提示注入
  .\deploy\scripts\deploy-env.ps1

  # 启动服务
  java -jar deploy/cloudoffice-gateway.jar
#>

# ============================================================
# 敏感变量获取：优先从 deploy/env.json 加载（不存在则跳过）
# ============================================================
$EnvJson = Join-Path (Split-Path -Parent $PSScriptRoot) "env.json"
if (Test-Path $EnvJson) {
  . "$PSScriptRoot\load-env.ps1" -EnvFile "env.json"
} else {
  Write-Host "提示: 未找到 $EnvJson，敏感变量将保留占位符，请通过环境变量注入" -ForegroundColor Yellow
}

# ============================================================
# 第一组：必填敏感变量（占位符；真实值从 env.json / 环境变量注入）
# ============================================================

# 数据库密码（MariaDB root 或业务用户密码）
if ([string]::IsNullOrEmpty($env:DB_PASSWORD)) { $env:DB_PASSWORD = '<DB_PASSWORD>' }

# RSA 私钥（Base64 编码，用于 JWT RS256 签名）
# 生成方式: .\deploy\scripts\deploy-rsa-keygen.ps1
if ([string]::IsNullOrEmpty($env:RSA_PRIVATE_KEY)) { $env:RSA_PRIVATE_KEY = '<RSA_PRIVATE_KEY>' }

# RSA 公钥（Base64 编码，用于 JWT RS256 验签）
if ([string]::IsNullOrEmpty($env:RSA_PUBLIC_KEY)) { $env:RSA_PUBLIC_KEY = '<RSA_PUBLIC_KEY>' }

# Redis 密码（若无密码则为空）
if ([string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $env:REDIS_PASSWORD = '' }

# ============================================================
# 第二组：必填连接变量（请根据实际中间件地址修改）
# ============================================================

# Nacos 服务注册与配置中心地址
$env:NACOS_ADDR = '<NACOS_HOST>:8848'

# 数据库主机地址
$env:DB_HOST = '<DB_HOST>'

# 数据库端口
$env:DB_PORT = '3306'

# 数据库用户名
$env:DB_USERNAME = '<DB_USERNAME>'

# biz-service 和 system-service 使用的数据库用户名
$env:DB_USER = '<DB_USERNAME>'

# Redis 主机地址
$env:REDIS_HOST = '<REDIS_HOST>'

# Redis 端口
$env:REDIS_PORT = '6379'

# ============================================================
# 第三组：可选业务变量（通常使用默认值即可）
# ============================================================

# ---------- 验证码配置 ----------
$env:VERIFICATION_CODE_MOCK = 'true'
$env:VERIFICATION_CODE_EXPIRE_SECONDS = '300'
$env:VERIFICATION_CODE_SEND_INTERVAL = '60'
$env:VERIFICATION_CODE_LENGTH = '6'

# ---------- 密码策略配置 ----------
$env:PASSWORD_MIN_LENGTH = '8'
$env:PASSWORD_MAX_LENGTH = '64'

Write-Host "环境变量已加载（请确认敏感变量非占位符）"
Write-Host "  NACOS_ADDR:       $env:NACOS_ADDR"
Write-Host "  DB_HOST:          $env:DB_HOST"
Write-Host "  DB_PORT:          $env:DB_PORT"
Write-Host "  DB_USERNAME:      $env:DB_USERNAME"
Write-Host "  REDIS_HOST:       $env:REDIS_HOST"
Write-Host "  REDIS_PORT:       $env:REDIS_PORT"
Write-Host "  RSA 密钥已配置:   $(if ($env:RSA_PRIVATE_KEY -and $env:RSA_PRIVATE_KEY -notlike '<*') { '是' } else { '否（占位符）' })"
Write-Host "  DB 密码已配置:    $(if ($env:DB_PASSWORD -and $env:DB_PASSWORD -notlike '<*') { '是' } else { '否（占位符）' })"
Write-Host ""
Write-Host "  ⚠️ 如敏感变量仍为占位符（<DB_PASSWORD>/<RSA_PRIVATE_KEY> 等），请："
Write-Host '     ① 编辑 deploy/env.json 后通过 load-env.ps1 加载；或'
Write-Host '     ② 在运行前设置进程环境变量（如 $env:DB_PASSWORD = "实际值"）注入。'
