# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 后端服务一键停止脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）停止 deploy-start-all 启动的全部服务（F-008 逆操作）：
    1. 停止顺序与启动相反：system(9400) → biz(9200) → auth(9100) → gateway(9000) → common(9300)，
      common 在所有后端服务中最后停止（v0.2.8 F-009，确保其他服务停止过程中仍可访问配置接口）；
    2. 停止方式：优先读取 deploy/logs/{name}.pid 记录的 PID，校验进程命令行含 jar 名后 Stop-Process 停止，
       轮询等待进程退出（默认超时 30 秒/间隔 2 秒），超时强制停止；
       PID 文件缺失或进程不存在视为已停止（幂等通过）；
       进程定位回退：java 进程命令行含 jar 名；
    3. 停止 Nacos（部署链路启动的基础设施，F-007 逆操作）：执行 NACOS_HOME/bin/shutdown.cmd 停止，
       失败回退按 java 进程命令行含 nacos 定位停止；
    4. 明确不停止 Redis / MySQL / MariaDB（数据库基础设施，F-006 保持运行）。
  输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
  安全约定：口令/密钥不打印明文。
  版本: v0.2.8
.EXAMPLE
  .\deploy\scripts\deploy-stop-all.ps1
.EXAMPLE
  .\deploy\scripts\deploy-stop-all.ps1 -StopTimeout 60 -RetryInterval 2
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

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006/F-007）
function Test-NacosHttp {
  try {
    $resp = Invoke-WebRequest -Uri "http://$env:NACOS_ADDR/nacos/" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    return ($resp.Content -match "Nacos")
  } catch { return $false }
}

# Nacos java 进程辅助判断：java.exe 命令行含 nacos（F-006 辅助探测）
function Test-NacosJavaProcess {
  try {
    $procs = Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match 'nacos' }
    return ($null -ne $procs)
  } catch { return $false }
}

# Nacos 运行状态探测：HTTP 探测为主 + java 进程含 nacos 辅助（F-006）
function Test-NacosUp {
  if (Test-NacosHttp) { return $true }
  return (Test-NacosJavaProcess)
}

# 等待进程退出：超时上限内每间隔探测一次，进程消失返回 $true（F-008 逆操作，不报假成功）
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

# 等待服务关闭：超时上限内每间隔探测一次，探测返回 $false（未运行）即成功（不报假成功）
function Wait-ServiceDown {
  param([scriptblock]$Probe, [int]$TimeoutSeconds = 30, [int]$IntervalSeconds = 2)
  $elapsed = 0
  while ($elapsed -lt $TimeoutSeconds) {
    try { if (-not (& $Probe)) { return $true } } catch { return $true }
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

# ========== 2. 服务清单（停止顺序与启动相反：system → biz → auth → gateway → common，F-008 逆操作；common 最后停止 v0.2.8 F-009） ==========
# 字段：名称 | jar 文件名 | 端口
$Services = @(
  [pscustomobject]@{ Name = "system"; Jar = "cloudoffice-system-service.jar"; Port = 9400 },
  [pscustomobject]@{ Name = "biz"; Jar = "cloudoffice-biz-service.jar"; Port = 9200 },
  [pscustomobject]@{ Name = "auth"; Jar = "cloudoffice-auth-service.jar"; Port = 9100 },
  [pscustomobject]@{ Name = "gateway"; Jar = "cloudoffice-gateway.jar"; Port = 9000 },
  [pscustomobject]@{ Name = "common"; Jar = "cloudoffice-common.jar"; Port = 9300 }
)

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) 后端服务一键停止"
  Write-Host "  版本: v0.2.8"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. 停止 5 个后端服务（system → biz → auth → gateway → common，按 PID 文件 + 命令行校验，回退按 jar 名定位；common 最后停止 v0.2.8 F-009） ==========
$logDir = Join-Path $ProjectDir "logs"

foreach ($svc in $Services) {
  Write-Host ""
  Write-Host "━━━ 停止 $($svc.Name)（端口 $($svc.Port)） ━━━"
  $pidFile = Join-Path $logDir "$($svc.Name).pid"
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
        if ($cmdline -and $cmdline -match [regex]::Escape($svc.Jar)) { $targetPid = [int]$pidText }
      }
    }
  }

  # 4.2 回退：java 进程命令行含 jar 名定位
  if (-not $targetPid) { $targetPid = Find-JavaPidByJar -JarName $svc.Jar }

  # 4.3 未命中：视为已停止（幂等通过）
  if (-not $targetPid) {
    $script:serviceResults[$svc.Name] = "通过"
    Write-Result "通过" "$($svc.Name): 未在运行（PID 文件/进程均未命中），幂等跳过"
    continue
  }

  # 4.4 停止进程：Stop-Process 停止，等待退出，超时强制停止
  try {
    Stop-Process -Id $targetPid -ErrorAction Stop
  } catch {
    try { Stop-Process -Id $targetPid -Force -ErrorAction Stop } catch { }
  }
  if (Wait-ProcessGone -ProcessId $targetPid -TimeoutSeconds $StopTimeout -IntervalSeconds $RetryInterval) {
    $script:serviceResults[$svc.Name] = "通过"
    Write-Result "通过" "$($svc.Name): 已停止（PID $targetPid，进程已退出）"
  } else {
    $script:serviceResults[$svc.Name] = "失败"
    Write-Result "失败" "$($svc.Name): 进程 $targetPid 停止超时（$StopTimeout 秒后仍在运行），请手动执行 taskkill /F /PID $targetPid 排查"
  }
}

# ========== 5. 停止 Nacos（部署链路启动的基础设施，F-007 逆操作；不停止 Redis/MySQL/MariaDB） ==========
Write-Host ""
Write-Host "━━━ 停止 Nacos（基础设施，NACOS_ADDR: $env:NACOS_ADDR） ━━━"
if (-not (Test-NacosUp)) {
  $script:serviceResults["nacos"] = "通过"
  Write-Result "通过" "Nacos: 未在运行（HTTP 探测或 java 进程含 nacos 未命中），幂等跳过"
} else {
  $nacosShutdown = Join-Path $env:NACOS_HOME "bin\shutdown.cmd"
  if (Test-Path $nacosShutdown) {
    try {
      Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$nacosShutdown`"" -WindowStyle Hidden -Wait | Out-Null
    } catch {
      Write-Host "  Nacos: shutdown.cmd 执行失败，回退按 java 进程含 nacos 定位停止" -ForegroundColor Yellow
    }
  } else {
    Write-Host "  Nacos: shutdown.cmd 不存在（$nacosShutdown），回退按 java 进程含 nacos 定位停止" -ForegroundColor Yellow
  }
  if (Wait-ServiceDown -Probe { Test-NacosUp } -TimeoutSeconds $StopTimeout -IntervalSeconds $RetryInterval) {
    $script:serviceResults["nacos"] = "通过"
    Write-Result "通过" "Nacos: 已停止（shutdown.cmd，HTTP/进程探测确认）"
  } else {
    # 回退：强杀 java 进程含 nacos
    $nacosProcs = Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match 'nacos' }
    if ($nacosProcs) {
      foreach ($p in $nacosProcs) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }
      if (Wait-ServiceDown -Probe { Test-NacosUp } -TimeoutSeconds $StopTimeout -IntervalSeconds $RetryInterval) {
        $script:serviceResults["nacos"] = "通过"
        Write-Result "通过" "Nacos: 已通过 java 进程强杀停止"
      } else {
        $script:serviceResults["nacos"] = "失败"
        Write-Result "失败" "Nacos: 停止超时（shutdown.cmd 与强杀均未生效），请检查 Nacos 日志"
      }
    } else {
      $script:serviceResults["nacos"] = "失败"
      Write-Result "失败" "Nacos: shutdown.cmd 停止超时且未找到 java 进程含 nacos，请手动执行 $nacosShutdown 排查"
    }
  }
}

# ========== 6. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  后端服务一键停止完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项"
Write-Host "  各服务停止结果："
foreach ($svc in $Services) {
  $status = $script:serviceResults[$svc.Name]
  if (-not $status) { $status = "未执行" }
  $color = if ($status -eq "通过") { "Green" } elseif ($status -eq "失败") { "Red" } else { "Yellow" }
  Write-Host "    - $($svc.Name)（端口 $($svc.Port)）: $status" -ForegroundColor $color
}
$nacosStatus = $script:serviceResults["nacos"]
if (-not $nacosStatus) { $nacosStatus = "未执行" }
$nacosColor = if ($nacosStatus -eq "通过") { "Green" } elseif ($nacosStatus -eq "失败") { "Red" } else { "Yellow" }
Write-Host "    - Nacos（端口 $(($env:NACOS_ADDR -split ':')[1])）: $nacosStatus" -ForegroundColor $nacosColor
Write-Host "=============================================="
Write-Host ""
Write-Host "  Redis / MySQL / MariaDB 数据库基础设施保持运行（不在本脚本停止范围）。" -ForegroundColor Cyan

if ($script:fail -gt 0) {
  Write-Host ""
  Write-Host "存在失败项，请按上述提示处理后重试。" -ForegroundColor Red
  exit 1
} else {
  Write-Host ""
  Write-Host "全部服务已停止。" -ForegroundColor Green
  exit 0
}
