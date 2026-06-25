<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) System Service 启动脚本 (Windows)
.DESCRIPTION
  自动注入环境变量并启动系统服务
  前置条件: 已执行 scripts/deploy-env-local.ps1
.EXAMPLE
  .\scripts\deploy-start-system.ps1
#>

$ProjectDir = Split-Path -Parent $PSScriptRoot
$JarPath = Join-Path $ProjectDir "cloudoffice-system-service\target\cloudoffice-system-service-0.0.1-SNAPSHOT.jar"

# ========== 检查必要变量 ==========
if (-not $env:NACOS_ADDR) {
  Write-Host "❌ 错误: NACOS_ADDR 未设置。请先执行:" -ForegroundColor Red
  Write-Host "   .\scripts\deploy-env-local.ps1"
  exit 1
}

if (-not (Test-Path $JarPath)) {
  Write-Host "❌ 错误: JAR 包不存在: $JarPath" -ForegroundColor Red
  Write-Host "   请先执行: mvn clean package -pl cloudoffice-system-service -am -DskipTests"
  exit 1
}

# ========== 显示配置信息 ==========
Write-Host "=============================================="
Write-Host "  云漫智企 - System Service 启动"
Write-Host "=============================================="
Write-Host "  JAR 包:        $JarPath"
Write-Host "  Nacos 地址:    $env:NACOS_ADDR"
Write-Host "=============================================="
Write-Host ""

Write-Host "🚀 启动 System Service..." -ForegroundColor Green

java -Xms256m -Xmx512m -jar "$JarPath"

Write-Host "`nSystem Service 已停止。" -ForegroundColor Yellow
