<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 客户端一键编译脚本 (Windows/PowerShell)
.DESCRIPTION
  调用客户端工程内官方构建脚本 (cloudoffice-flutter-app/build-release.ps1)，
  构建 Flutter 客户端（Windows/Web），最终产物落位 deploy/cloudoffice-flutter-app/
  （唯一落点）。构建缓存 (build/) 与过程文件不进入 deploy（对应 PRD F-003/F-004，验收 AC-3/AC-4）。
.EXAMPLE
  .\deploy\scripts\build-client.ps1                  # 构建 Windows + Web（默认）
  .\deploy\scripts\build-client.ps1 -Platform web    # 仅构建 Web
  .\deploy\scripts\build-client.ps1 -Platform windows # 仅构建 Windows
.PARAMETER Platform
  构建平台：all（默认）/ web / windows
#>
param(
  [ValidateSet("all", "windows", "web")]
  [string]$Platform = "all"
)

$ErrorActionPreference = "Stop"

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
$ScriptDir = $PSScriptRoot                                          # deploy/scripts
$DeployDir = Split-Path -Parent $ScriptDir                          # deploy
$ProjectDir = Split-Path -Parent $DeployDir                         # 项目根
$ClientDir = Join-Path $ProjectDir "cloudoffice-flutter-app"        # 客户端工程
$ClientDeployDir = Join-Path $DeployDir "cloudoffice-flutter-app"   # 客户端产物落点

# ========== 前置检查：deploy 目录必须已存在 ==========
if (-not (Test-Path $DeployDir)) {
  Write-Host "[错误] deploy 目录不存在: $DeployDir" -ForegroundColor Red
  exit 1
}

# ========== 前置检查：客户端工程与构建脚本存在 ==========
$BuildScript = Join-Path $ClientDir "build-release.ps1"
if (-not (Test-Path $BuildScript)) {
  Write-Host "[错误] 未找到客户端构建脚本: $BuildScript" -ForegroundColor Red
  exit 1
}

# ========== 前置检查：flutter 命令可用 ==========
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "[错误] 未找到 flutter 命令，请安装 Flutter 3.x 并配置 PATH" -ForegroundColor Red
  exit 1
}

Write-Host "=============================================="
Write-Host "  云漫智企 - 客户端一键编译"
Write-Host "  平台:     $Platform"
Write-Host "  产物落点: $ClientDeployDir"
Write-Host "=============================================="

# ========== 调用客户端官方构建脚本（构建 + 产物复制一步完成） ==========
& $BuildScript -Platform $Platform
if ($LASTEXITCODE -ne 0) {
  Write-Host "[错误] 客户端构建失败，已中止" -ForegroundColor Red
  exit 1
}

# ========== 校验最终产物落位（按平台校验对应子目录） ==========
$missing = @()
if ($Platform -in @("all", "windows") -and -not (Test-Path (Join-Path $ClientDeployDir "windows\cloudoffice_flutter_app.exe"))) {
  $missing += "windows\cloudoffice_flutter_app.exe"
}
if ($Platform -in @("all", "web") -and -not (Test-Path (Join-Path $ClientDeployDir "web\index.html"))) {
  $missing += "web\index.html"
}
if ($missing) {
  Write-Host "[错误] 以下客户端产物未出现在 deploy 目录：" -ForegroundColor Red
  $missing | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
  exit 1
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  客户端编译完成，全部最终产物已输出至 deploy"
Write-Host "    deploy\cloudoffice-flutter-app\"
Write-Host "=============================================="
