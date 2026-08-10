# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Biz Service 服务启动脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）单服务启动企业服务（F-009）：
    1. 前置校验：JDK 可用 + jar 包存在 + 本服务关键环境变量就绪
       （任一缺失输出缺失项与处理提示，以非零码退出且不启动服务）
    2. 后台启动：java -Xms256m -Xmx512m -jar <jar>
       （Start-Process 隐藏窗口后台运行，日志落位 deploy/logs/biz-start.log/.err，
       PID 记录 deploy/logs/biz.pid）
    3. 健康确认：HTTP 直连自身端口（http://localhost:9200/api/v1/biz/health），端口探测备用；
       循环轮询（可配置重试次数/间隔/单次超时，默认 30 次/2 秒/3 秒）
    4. 任一步骤失败即停：输出明确错误提示，退出非零
  行为与 deploy-start-all 中 biz 服务启动逻辑一致（F-008/F-009）。
  输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
  安全约定：口令/密钥不打印明文（DB_PASSWORD 仅校验非空，缺失提示只列键名）。
  版本: v0.2.7
.EXAMPLE
  .\deploy\scripts\deploy-start-biz.ps1
.EXAMPLE
  .\deploy\scripts\deploy-start-biz.ps1 -RetryCount 60 -RetryInterval 2 -ProbeTimeout 3
#>
param(
  [int]$RetryCount = 30,    # 健康确认轮询重试次数（可配置，默认 30 次）
  [int]$RetryInterval = 2,  # 健康确认轮询间隔秒数（可配置，默认 2 秒）
  [int]$ProbeTimeout = 3    # 单次 HTTP 探测超时秒数（可配置，默认 3 秒）
)

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 兜底退出） ==========
$ProjectDir = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\load-env.ps1"

# ========== 1. 全局计数（F-011 输出分级） ==========
$script:pass = 0
$script:warn = 0
$script:fail = 0

# 输出「通过/警告/失败」三级结果并累计计数（F-011 输出分级约定，双平台一致不用 emoji）
function Write-Result {
  param([string]$Status, [string]$Message)
  switch ($Status) {
    "通过" { Write-Host "  [通过] $Message" -ForegroundColor Green;  $script:pass++ }
    "警告" { Write-Host "  [警告] $Message" -ForegroundColor Yellow; $script:warn++ }
    "失败" { Write-Host "  [失败] $Message" -ForegroundColor Red;    $script:fail++ }
  }
}

# TCP 端口可达性探测（TcpClient，超时可控；健康确认的备用方案 F-009）
function Test-TcpPort {
  param([string]$HostName, [string]$Port, [int]$TimeoutMs = 1000)
  $portNum = 0
  if (-not [int]::TryParse($Port, [ref]$portNum)) { return $false }
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
      $iar = $client.BeginConnect($HostName, $portNum, $null, $null)
      if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
      $client.EndConnect($iar)
      return $true
    } finally { $client.Dispose() }
  } catch { return $false }
}

# HTTP 存活探测：任一 HTTP 响应（含 404/401/500）即认为服务已启动（F-009 健康确认首选）
function Test-HttpOk {
  param([string]$Uri, [int]$TimeoutSec = 3)
  try {
    Invoke-WebRequest -Uri $Uri -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop | Out-Null
    return $true
  } catch {
    # 非 2xx 但存在 HTTP 响应（404/401/500 等）同样说明服务在运行；连接拒绝/超时无响应
    return ($null -ne $_.Exception.Response)
  }
}

# 健康确认轮询：重试次数上限内每间隔探测一次，HTTP 优先、TCP 端口探测备用（F-009，不报假成功）
function Wait-HealthUp {
  param([string]$Url, [string]$Port, [int]$RetryCount = 30, [int]$IntervalSeconds = 2, [int]$TimeoutSec = 3)
  for ($i = 0; $i -lt $RetryCount; $i++) {
    if (Test-HttpOk -Uri $Url -TimeoutSec $TimeoutSec) { return $true }
    if (Test-TcpPort -HostName "localhost" -Port $Port -TimeoutMs ($TimeoutSec * 1000)) { return $true }
    Start-Sleep -Seconds $IntervalSeconds
  }
  return $false
}

# ========== 2. 本服务契约（与 deploy-start-all 中 biz 子块一致，F-009） ==========
# 服务标识（用于日志/PID 命名）与 jar 文件名
$ServiceName = "biz"
$JarName     = "cloudoffice-biz-service.jar"
$ServicePort = 9200
$HealthUrl   = "http://localhost:9200/api/v1/biz/health"
# 本服务关键环境变量（F-009 契约表）：缺失只列键名，不打印值
# 注意：biz-service 使用 DB_USER（区别于 auth-service 的 DB_USERNAME，差异保持现状）；
#       DB_USER 由服务自身读取，按契约表不参与本脚本启动校验。
$RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")
$MissingHint  = "请检查 DB_PASSWORD 配置"

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) Biz Service 服务启动"
Write-Host "  版本: v0.2.7"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. 前置校验（JDK / jar 包 / 关键环境变量；任一缺失→列出缺失项+处理提示→非零退出→不启动服务） ==========
Write-Host "━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━"
$precheckFail = $false

# 4.1 JDK 可用性（java 命令存在即可，版本/安装完整检查由 deploy-check-env 承担）
if (Get-Command java -ErrorAction SilentlyContinue) {
  Write-Result "通过" "JDK: java 命令可用"
} else {
  Write-Result "失败" "JDK: 未检测到 java 命令，请安装 JDK 21 并配置 PATH/JAVA_HOME"
  $precheckFail = $true
}

# 4.2 jar 包存在性（缺失提示构建并落位）
$jarPath = Join-Path $ProjectDir $JarName
if (-not (Test-Path -LiteralPath $jarPath)) {
  Write-Result "失败" "${ServiceName}: jar 包缺失（$jarPath），请执行 build-backend 构建后将 jar 落位 deploy 目录"
  $precheckFail = $true
}

# 4.3 本服务关键环境变量（缺失只列键名，不打印值）
foreach ($v in $RequiredVars) {
  $value = (Get-Item -Path "Env:$v" -ErrorAction SilentlyContinue).Value
  if ([string]::IsNullOrEmpty($value)) {
    Write-Result "失败" "${ServiceName}: 关键环境变量 $v 缺失或为空，请在 env.json 中配置相应键（不打印值）"
    $precheckFail = $true
  }
}

if ($precheckFail) {
  Write-Host ""
  Write-Host "  前置校验未通过：$MissingHint；请按上述缺失项处理（构建/落位 jar、配置 env.json）后重新运行。" -ForegroundColor Red
  Write-Host "  本次未启动服务。" -ForegroundColor Red
  exit 1
}
Write-Host ""
Write-Result "通过" "前置校验：jar 包与关键环境变量全部就绪"

# ========== 5. 后台启动 + 健康确认（与 deploy-start-all 中 biz 子块逻辑一致，F-009） ==========
$logDir = Join-Path $ProjectDir "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "$ServiceName-start.log"
$errFile = Join-Path $logDir "$ServiceName-start.err"
$pidFile = Join-Path $logDir "$ServiceName.pid"
$startFailed = $false

try {
  # Windows 后台启动：Start-Process 隐藏窗口，stdout/stderr 重定向日志，PassThru 获取进程句柄记录 PID
  $proc = Start-Process -FilePath "java" -ArgumentList "-Xms256m", "-Xmx512m", "-jar", $jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru
  $proc.Id | Out-File -Encoding ascii $pidFile
  Write-Host "  java 已后台启动（PID: $($proc.Id)），日志: $logFile" -ForegroundColor Cyan
} catch {
  # 启动命令执行失败：输出失败分级并标记失败（跳过健康确认，失败即停）
  Write-Result "失败" "${ServiceName}: 启动命令执行失败: $($_.Exception.Message)；请确认 JDK 21 已安装且 java 在 PATH 中"
  $startFailed = $true
}

# 健康确认：HTTP 直连自身端口优先、TCP 端口探测备用（F-009）
if (-not $startFailed) {
  if (Wait-HealthUp -Url $HealthUrl -Port $ServicePort -RetryCount $RetryCount -IntervalSeconds $RetryInterval -TimeoutSec $ProbeTimeout) {
    Write-Result "通过" "${ServiceName}: 已启动且健康确认成功（$HealthUrl）"
  } else {
    Write-Result "失败" "${ServiceName}: 健康确认超时（重试 $RetryCount 次/间隔 $RetryInterval 秒后仍无响应）。可能原因：端口 $ServicePort 被占用、服务启动失败或依赖未就绪；请查看日志 $logFile / $errFile；$MissingHint"
  }
}

# ========== 6. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  Biz Service 服务启动完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项"
Write-Host "=============================================="
Write-Host ""
if ($script:fail -gt 0) {
  Write-Host "存在失败项，请按上述提示处理后重新运行。" -ForegroundColor Red
  exit 1
} else {
  Write-Host "Biz Service 服务启动成功且健康确认通过。" -ForegroundColor Green
  exit 0
}
