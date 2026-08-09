<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Flutter 客户端构建脚本（Windows/PowerShell）
.DESCRIPTION
  构建 Flutter 客户端（Windows/Web）并仅将最终可交付产物复制到根目录 deploy。
  构建缓存 (build/) 与编译过程文件不进入 deploy（对应 PRD F-003/F-004，验收 AC-3/AC-4）。
.EXAMPLE
  .\build-release.ps1                  # 构建 Windows + Web
  .\build-release.ps1 -Platform web    # 仅构建 Web
  .\build-release.ps1 -Platform windows  # 仅构建 Windows
#>
param(
  [ValidateSet("all", "windows", "web")]
  [string]$Platform = "all"
)

$ErrorActionPreference = "Stop"

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
$ScriptDir = $PSScriptRoot                                          # cloudoffice-flutter-app 工程根（脚本自身目录）
$ProjectDir = Split-Path -Parent $ScriptDir                         # 项目根
$DeployDir = Join-Path $ProjectDir "deploy"                         # 最终产物统一落点
$ClientDeployDir = Join-Path $DeployDir "cloudoffice-flutter-app"   # 客户端产物子目录

# ========== 前置检查：deploy 目录必须已存在（TASK-001 已创建） ==========
if (-not (Test-Path $DeployDir)) {
  Write-Host "[错误] deploy 目录不存在: $DeployDir" -ForegroundColor Red
  exit 1
}

# ========== 依赖安装（构建前置步骤） ==========
Write-Host "==> 执行 flutter pub get ..."
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "[错误] flutter pub get 失败，已中止" -ForegroundColor Red
  exit 1
}

# ========== Windows 平台构建 ==========
if ($Platform -in @("all", "windows")) {
  Write-Host "==> 执行 flutter build windows --release ..."
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] Windows 构建失败，已中止" -ForegroundColor Red
    exit 1
  }

  # Windows 最终产物目录（Flutter 3.16+ x64 架构化路径）
  $ReleaseDir = Join-Path $ScriptDir "build\windows\x64\runner\Release"
  if (-not (Test-Path $ReleaseDir)) {
    Write-Host "[错误] 未找到 Windows 最终产物目录: $ReleaseDir" -ForegroundColor Red
    exit 1
  }

  $WinTarget = Join-Path $ClientDeployDir "windows"
  New-Item -ItemType Directory -Force -Path $WinTarget | Out-Null
  # 仅复制最终产物文件（exe/dll/data），严禁整目录递归复制 build/（AC-4）
  Copy-Item -Path (Join-Path $ReleaseDir "*") -Destination $WinTarget -Recurse -Force
  Write-Host "[完成] Windows 产物已输出: $WinTarget" -ForegroundColor Green
}

# ========== Web 平台构建 ==========
if ($Platform -in @("all", "web")) {
  Write-Host "==> 执行 flutter build web --release ..."
  flutter build web --release
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[错误] Web 构建失败，已中止" -ForegroundColor Red
    exit 1
  }

  # Web 最终产物目录（整体即为最终可交付部署包）
  $WebDir = Join-Path $ScriptDir "build\web"
  if (-not (Test-Path $WebDir)) {
    Write-Host "[错误] 未找到 Web 最终产物目录: $WebDir" -ForegroundColor Red
    exit 1
  }

  $WebTarget = Join-Path $ClientDeployDir "web"
  New-Item -ItemType Directory -Force -Path $WebTarget | Out-Null
  # 仅复制最终 Web 部署包内容，build/web 之外的构建缓存不进入 deploy（AC-4）
  Copy-Item -Path (Join-Path $WebDir "*") -Destination $WebTarget -Recurse -Force
  Write-Host "[完成] Web 产物已输出: $WebTarget" -ForegroundColor Green
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  客户端构建完成，全部最终产物已输出至 deploy"
Write-Host "=============================================="
