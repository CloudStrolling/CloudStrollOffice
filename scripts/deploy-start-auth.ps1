<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Auth Service 启动脚本 (Windows)
.DESCRIPTION
  自动注入环境变量并启动认证服务
  前置条件: 已执行 scripts/deploy-env-local.ps1
.EXAMPLE
  .\scripts\deploy-start-auth.ps1
#>

$ProjectDir = Split-Path -Parent $PSScriptRoot
$JarPath = Join-Path $ProjectDir "cloudoffice-auth-service\target\cloudoffice-auth-service-0.0.1-SNAPSHOT.jar"

# ========== 检查必要变量 ==========
$requiredVars = @("NACOS_ADDR", "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD",
                  "REDIS_HOST", "REDIS_PORT", "RSA_PRIVATE_KEY", "RSA_PUBLIC_KEY")
$missingVars = @()

foreach ($var in $requiredVars) {
  if (-not (Get-Item "Env:$var" -ErrorAction SilentlyContinue).Value) {
    $missingVars += $var
  }
}

if ($missingVars.Count -gt 0) {
  Write-Host "❌ 错误: 以下环境变量未设置：" -ForegroundColor Red
  foreach ($var in $missingVars) {
    Write-Host "   - $var"
  }
  Write-Host "`n   请先执行: .\scripts\deploy-env-local.ps1"
  exit 1
}

if (-not (Test-Path $JarPath)) {
  Write-Host "❌ 错误: JAR 包不存在: $JarPath" -ForegroundColor Red
  Write-Host "   请先执行: mvn clean package -pl cloudoffice-auth-service -am -DskipTests"
  exit 1
}

# ========== 显示配置信息 ==========
Write-Host "=============================================="
Write-Host "  云漫智企 - Auth Service 启动"
Write-Host "=============================================="
Write-Host "  JAR 包:        $JarPath"
Write-Host "  Nacos 地址:    $env:NACOS_ADDR"
Write-Host "  数据库:        $env:DB_HOST`:$env:DB_PORT"
Write-Host "  Redis:         $env:REDIS_HOST`:$env:REDIS_PORT"
Write-Host "  验证码模式:    $(if ($env:VERIFICATION_CODE_MOCK -eq 'true') { '模拟' } else { '真实' })"
Write-Host "=============================================="
Write-Host ""

Write-Host "🚀 启动 Auth Service..." -ForegroundColor Green

java -Xms256m -Xmx512m -jar "$JarPath"

Write-Host "`nAuth Service 已停止。" -ForegroundColor Yellow
