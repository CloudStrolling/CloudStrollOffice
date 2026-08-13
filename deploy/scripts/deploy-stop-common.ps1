# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Common 服务停止脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）单服务停止 common 服务（v0.2.8 F-009，与 deploy-stop-all 中 common 停止逻辑一致）：
    1. 停止方式：优先读取 deploy/logs/common.pid 记录的 PID，校验进程命令行含 cloudoffice-common.jar 后 Stop-Process 停止，
       轮询等待进程退出（默认超时 30 秒/间隔 2 秒），超时强制停止；
       PID 文件缺失或进程不存在视为已停止（幂等通过）；
       进程定位回退：java 进程命令行含 cloudoffice-common.jar；
    2. 不停止 Nacos / Redis / MySQL / MariaDB 基础设施（本脚本仅停止 common 单服务）。
  输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
  安全约定：口令/密钥不打印明文。
  版本: v0.2.8
.EXAMPLE
  .\deploy\scripts\deploy-stop-common.ps1
.EXAMPLE
  .\deploy\scripts\deploy-stop-common.ps1 -StopTimeout 60 -RetryInterval 2
#>
param(
  [int]$StopTimeout = 30,    # 等待进程退出的总超时秒数（可配置，默认 30 秒）
  [int]$RetryInterval = 2    # 轮询间隔秒数（可配置，默认 2 秒）
)

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 兜底退出） ==========
$ProjectDir = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\load-env.ps1"

# ========== 1. 全局计数与服务结果（F-011 输出分级） ==========
$script:pass = 0
$script:warn = 0
$script:fail = 0
$script:serviceResults = @{}

# 输出「通过/警告/失败」三级结果并累计计数（F-011 输出分级约定，双平台一致不用 emoji）
function Write-Result {
  param([string]$Status, [string]$Message)
  switch ($Status) {
    "通过" { Write-Host "  [通过] $Message" -ForegroundColor Green;  $script:pass++ }
    "警告" { Write-Host "  [警告] $Message" -ForegroundColor Yellow; $script:warn++ }
    "失败" { Write-Host "  [失败] $Message" -ForegroundColor Red;    $script:fail++ }
  }
}

# 等待进程退出：超时上限内每间隔探测一次，进程消失返回 $true（不报假成功）
function Wait-ProcessGone {
  param([int]$ProcessId, [int]$TimeoutSeconds = 30, [int]$IntervalSeconds = 2)
  $elapsed = 0
  while ($elapsed -lt $TimeoutSeconds) {
    if (-not (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) { return $true }
    Start-Sleep -Seconds $IntervalSeconds
    $elapsed += $IntervalSeconds
  }
  return $false
}

# 按 jar 名定位 java 进程（回退定位，返回第一个命中的 PID；未命中返回 $null）
function Find-JavaPidByJar {
  param([string]$JarName)
  $found = Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match [regex]::Escape($JarName) }
  if ($found) { return [int]$found[0].ProcessId }
  return $null
}

# ========== 2. 本服务契约（与 deploy-stop-all 中 common 子块一致，v0.2.8 F-009） ==========
$ServiceName = "common"
$JarName     = "cloudoffice-common.jar"
$ServicePort = 9300

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) Common 服务停止"
Write-Host "  版本: v0.2.8"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. 停止 common 服务（按 PID 文件 + 命令行校验，回退按 jar 名定位；幂等跳过） ==========
$logDir = Join-Path $ProjectDir "logs"
Write-Host "━━━ 停止 $ServiceName（端口 $ServicePort） ━━━"
$pidFile = Join-Path $logDir "$ServiceName.pid"
$targetPid = $null

# 4.1 优先：读取 PID 文件并校验进程命令行含 jar 名（避免误杀无关进程）
if (Test-Path -LiteralPath $pidFile) {
  $pidText = (Get-Content -LiteralPath $pidFile -Raw | Out-String).Trim()
  if ($pidText -match '^\d+$') {
    $proc = Get-Process -Id ([int]$pidText) -ErrorAction SilentlyContinue
    if ($proc) {
      $cmdline = $null
      try {
        $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId = $pidText" -ErrorAction SilentlyContinue).CommandLine
      } catch { }
      if ($cmdline -and $cmdline -match [regex]::Escape($JarName)) { $targetPid = [int]$pidText }
    }
  }
}

# 4.2 回退：java 进程命令行含 jar 名定位
if (-not $targetPid) { $targetPid = Find-JavaPidByJar -JarName $JarName }

# 4.3 未命中：视为已停止（幂等通过）
if (-not $targetPid) {
  $script:serviceResults[$ServiceName] = "通过"
  Write-Result "通过" "${ServiceName}: 未在运行（PID 文件/进程均未命中），幂等跳过"
} else {
  # 4.4 停止进程：Stop-Process 停止，等待退出，超时强制停止
  try {
    Stop-Process -Id $targetPid -ErrorAction Stop
  } catch {
    try { Stop-Process -Id $targetPid -Force -ErrorAction Stop } catch { }
  }
  if (Wait-ProcessGone -ProcessId $targetPid -TimeoutSeconds $StopTimeout -IntervalSeconds $RetryInterval) {
    $script:serviceResults[$ServiceName] = "通过"
    Write-Result "通过" "${ServiceName}: 已停止（PID $targetPid，进程已退出）"
  } else {
    $script:serviceResults[$ServiceName] = "失败"
    Write-Result "失败" "${ServiceName}: 进程 $targetPid 停止超时（$StopTimeout 秒后仍在运行），请手动执行 taskkill /F /PID $targetPid 排查"
  }
}

# ========== 5. 汇总与退出码（F-011：全部成功退出 0，任一失败退出 1） ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  Common 服务停止完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项"
$status = $script:serviceResults[$ServiceName]
if (-not $status) { $status = "未执行" }
$color = if ($status -eq "通过") { "Green" } elseif ($status -eq "失败") { "Red" } else { "Yellow" }
Write-Host "    - $ServiceName（端口 $ServicePort）: $status" -ForegroundColor $color
Write-Host "=============================================="
Write-Host ""
Write-Host "  本脚本仅停止 common 单服务；Nacos / Redis / MySQL / MariaDB 基础设施保持运行。" -ForegroundColor Cyan

if ($script:fail -gt 0) {
  Write-Host ""
  Write-Host "存在失败项，请按上述提示处理后重试。" -ForegroundColor Red
  exit 1
} else {
  Write-Host ""
  Write-Host "Common 服务已停止。" -ForegroundColor Green
  exit 0
}
