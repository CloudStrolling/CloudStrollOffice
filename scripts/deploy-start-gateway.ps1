<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Gateway 服务启动脚本 (Windows)
.DESCRIPTION
  自动注入环境变量并启动 API 网关服务
  前置条件: 已执行 scripts/deploy-env-local.ps1
.EXAMPLE
  .\scripts\deploy-start-gateway.ps1
#>

$ProjectDir = Split-Path -Parent $PSScriptRoot
$JarPath = Join-Path $ProjectDir "cloudoffice-gateway\target\cloudoffice-gateway-0.0.1-SNAPSHOT.jar"

# ========== 检查必要变量 ==========
if (-not $env:NACOS_ADDR) {
  Write-Host "❌ 错误: NACOS_ADDR 未设置。请先执行:" -ForegroundColor Red
  Write-Host "   .\scripts\deploy-env-local.ps1"
  exit 1
}

if (-not $env:RSA_PUBLIC_KEY) {
  Write-Host "❌ 错误: RSA_PUBLIC_KEY 未设置。请先生成 RSA 密钥对：" -ForegroundColor Red
  Write-Host "   .\scripts\deploy-rsa-keygen.ps1"
  exit 1
}

if (-not (Test-Path $JarPath)) {
  Write-Host "❌ 错误: JAR 包不存在: $JarPath" -ForegroundColor Red
  Write-Host "   请先执行: mvn clean package -pl cloudoffice-gateway -am -DskipTests"
  exit 1
}

# ========== 显示配置信息 ==========
Write-Host "=============================================="
Write-Host "  云漫智企 - Gateway 服务启动"
Write-Host "=============================================="
Write-Host "  JAR 包:        $JarPath"
Write-Host "  Nacos 地址:    $env:NACOS_ADDR"
Write-Host "  Redis 主机:    $env:REDIS_HOST`:$env:REDIS_PORT"
Write-Host "  公钥已配置:    $(if ($env:RSA_PUBLIC_KEY) { '是' } else { '否' })"
Write-Host "=============================================="
Write-Host ""

Write-Host "🚀 启动 Gateway 服务..." -ForegroundColor Green

java -Xms256m -Xmx512m -jar "$JarPath"

# Java 进程退出后清理
Write-Host "`nGateway 服务已停止。" -ForegroundColor Yellow
