<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 后端一键编译脚本 (Windows/PowerShell)
.DESCRIPTION
  在项目根目录执行 Maven 多模块 clean package，构建 gateway/auth/biz/system 四个服务，
  最终可执行 jar 由各模块 maven-antrun-plugin 自动复制至 deploy 目录（唯一落点）。
  中间产物（各模块 target/）不进入 deploy（对应 PRD F-002/F-004，验收 AC-2/AC-4）。
.EXAMPLE
  .\deploy\scripts\build-backend.ps1                 # 编译并跳过测试（默认）
  .\deploy\scripts\build-backend.ps1 -RunTests       # 编译并执行测试
.PARAMETER RunTests
  开关：执行 Maven 测试；不指定时使用 -DskipTests 跳过测试
#>
param(
  [switch]$RunTests
)

$ErrorActionPreference = "Stop"

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
$ScriptDir = $PSScriptRoot                                          # deploy/scripts
$DeployDir = Split-Path -Parent $ScriptDir                          # deploy
$ProjectDir = Split-Path -Parent $DeployDir                         # 项目根

# ========== 前置检查：deploy 目录必须已存在（v0.2.5 产物唯一落点） ==========
if (-not (Test-Path $DeployDir)) {
  Write-Host "[错误] deploy 目录不存在: $DeployDir" -ForegroundColor Red
  exit 1
}

# ========== 前置检查：mvn 命令可用 ==========
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
  Write-Host "[错误] 未找到 mvn 命令，请安装 Maven 3.8+ 并配置 PATH" -ForegroundColor Red
  exit 1
}

# ========== 构建命令 ==========
$MvnArgs = @("-f", (Join-Path $ProjectDir "pom.xml"), "clean", "package")
if (-not $RunTests) { $MvnArgs += "-DskipTests" }

Write-Host "=============================================="
Write-Host "  云漫智企 - 后端一键编译"
Write-Host "  项目根: $ProjectDir"
Write-Host "  命令:   mvn $($MvnArgs -join ' ')"
Write-Host "=============================================="

& mvn @MvnArgs
if ($LASTEXITCODE -ne 0) {
  Write-Host "[错误] Maven 构建失败（退出码 $LASTEXITCODE），已中止" -ForegroundColor Red
  exit 1
}

# ========== 校验最终产物落位 deploy（4 个服务 jar 必须齐全） ==========
$Jars = @("cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
          "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar")
$missing = $Jars | Where-Object { -not (Test-Path (Join-Path $DeployDir $_)) }
if ($missing) {
  Write-Host "[错误] 以下产物未出现在 deploy 目录：" -ForegroundColor Red
  $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
  exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  后端编译完成，全部 jar 已输出至 deploy"
$Jars | ForEach-Object { Write-Host "    deploy\$_" }
Write-Host "=============================================="
