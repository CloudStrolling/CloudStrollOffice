<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 环境变量模板 (Windows PowerShell)
.DESCRIPTION
  在使用此脚本前，将所有 <PLACEHOLDER> 替换为实际值。
  在 PowerShell 中执行此脚本以注入环境变量到当前会话。
.USAGE
  # 步骤1: 复制模板
  Copy-Item scripts/deploy-env-template.ps1 scripts/deploy-env-local.ps1

  # 步骤2: 编辑 scripts/deploy-env-local.ps1，替换所有 <PLACEHOLDER>

  # 步骤3: 执行注入环境变量
  .\scripts\deploy-env-local.ps1

  # 步骤4: 启动服务
  java -jar cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar
#>

# ============================================================
# 第一组：必填敏感变量（请务必替换 <PLACEHOLDER>）
# ============================================================

# 数据库密码（MariaDB root 或业务用户密码）
$env:DB_PASSWORD = '<DB_PASSWORD>'

# RSA 私钥（Base64 编码，用于 JWT RS256 签名）
# 生成方式: .\scripts\deploy-rsa-keygen.ps1
$env:RSA_PRIVATE_KEY = '<RSA_PRIVATE_KEY>'

# RSA 公钥（Base64 编码，用于 JWT RS256 验签）
$env:RSA_PUBLIC_KEY = '<RSA_PUBLIC_KEY>'

# Redis 密码（若无密码则为空）
$env:REDIS_PASSWORD = '<REDIS_PASSWORD>'

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

Write-Host "环境变量已加载（请确认所有 <PLACEHOLDER> 已被替换）"
Write-Host "  NACOS_ADDR:       $env:NACOS_ADDR"
Write-Host "  DB_HOST:          $env:DB_HOST"
Write-Host "  DB_PORT:          $env:DB_PORT"
Write-Host "  DB_USERNAME:      $env:DB_USERNAME"
Write-Host "  REDIS_HOST:       $env:REDIS_HOST"
Write-Host "  REDIS_PORT:       $env:REDIS_PORT"
Write-Host "  RSA 密钥已配置:   $(if ($env:RSA_PRIVATE_KEY) { '是' } else { '否' })"
Write-Host "  DB 密码已配置:    $(if ($env:DB_PASSWORD) { '是' } else { '否' })"
