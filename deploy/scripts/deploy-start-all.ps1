# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 后端服务按序一键启动脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）执行（F-008）：
    1. 前置校验：JDK 可用 + 4 个 jar 包存在 + 各服务关键环境变量就绪
       （任一缺失输出缺失项与处理提示，以非零码退出且不启动任何服务）
    2. 按 gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序后台启动：
       java -Xms256m -Xmx512m -jar <jar>
       （Start-Process 隐藏窗口后台运行，日志落位 deploy/logs/{module}-start.log/.err，
       PID 记录 deploy/logs/{module}.pid）
    3. 每个服务启动后健康确认：HTTP 直连自身端口（gateway GET http://localhost:9000/、
       auth/biz/system GET http://localhost:{port}/api/v1/{module}/health），端口探测备用；
       循环轮询（可配置重试次数/间隔/单次超时，默认 30 次/2 秒/3 秒），
       确认成功后再启动下一个服务
    4. 任一步骤失败即停：输出明确错误提示（端口被占用提示检查 9000/9100/9200/9400 等），
       停止后续启动，退出非零
    5. 全部成功输出 4 个服务启动结果与健康状态汇总，退出码 0
  输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
  安全约定：口令/密钥不打印明文（DB_PASSWORD / RSA_* 仅校验非空，缺失提示只列键名）。
  版本: v0.2.7
.EXAMPLE
  .\deploy\scripts\deploy-start-all.ps1
.EXAMPLE
  .\deploy\scripts\deploy-start-all.ps1 -RetryCount 60 -RetryInterval 2 -ProbeTimeout 3
#>
param(
  [int]$RetryCount = 30,    # 健康确认轮询重试次数（可配置，默认 30 次）
  [int]$RetryInterval = 2,  # 健康确认轮询间隔秒数（可配置，默认 2 秒）
  [int]$ProbeTimeout = 3    # 单次 HTTP 探测超时秒数（可配置，默认 3 秒）
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

# TCP 端口可达性探测（TcpClient，超时可控；健康确认的备用方案 F-008）
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

# HTTP 存活探测：任一 HTTP 响应（含 404/401/500）即认为服务已启动（F-008 健康确认首选）
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

# 健康确认轮询：重试次数上限内每间隔探测一次，HTTP 优先、TCP 端口探测备用（F-008，不报假成功）
function Wait-HealthUp {
  param([string]$Url, [string]$Port, [int]$RetryCount = 30, [int]$IntervalSeconds = 2, [int]$TimeoutSec = 3)
  for ($i = 0; $i -lt $RetryCount; $i++) {
    if (Test-HttpOk -Uri $Url -TimeoutSec $TimeoutSec) { return $true }
    if (Test-TcpPort -HostName "localhost" -Port $Port -TimeoutMs ($TimeoutSec * 1000)) { return $true }
    Start-Sleep -Seconds $IntervalSeconds
  }
  return $false
}

# ========== 2. 服务清单（数组顺序即启动顺序契约：gateway → auth → biz → system，SAD 部署顺序） ==========
# 字段：名称 | jar 文件名 | 端口 | 健康检查 URL | 关键环境变量清单 | 失败排查提示
$Services = @(
  [pscustomobject]@{
    Name = "gateway"; Jar = "cloudoffice-gateway.jar"; Port = 9000
    HealthUrl   = "http://localhost:9000/"
    RequiredVars = @("NACOS_ADDR", "RSA_PUBLIC_KEY")
    Hint = "请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"
  },
  [pscustomobject]@{
    Name = "auth"; Jar = "cloudoffice-auth-service.jar"; Port = 9100
    HealthUrl   = "http://localhost:9100/api/v1/auth/health"
    RequiredVars = @("NACOS_ADDR", "RSA_PUBLIC_KEY", "RSA_PRIVATE_KEY", "DB_PASSWORD")
    Hint = "请检查 RSA 密钥对/DB_PASSWORD 配置"
  },
  [pscustomobject]@{
    Name = "biz"; Jar = "cloudoffice-biz-service.jar"; Port = 9200
    HealthUrl   = "http://localhost:9200/api/v1/biz/health"
    RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")
    Hint = "请检查 DB_PASSWORD 配置"
  },
  [pscustomobject]@{
    Name = "system"; Jar = "cloudoffice-system-service.jar"; Port = 9400
    HealthUrl   = "http://localhost:9400/api/v1/system/health"
    RequiredVars = @("NACOS_ADDR", "DB_PASSWORD")
    Hint = "请检查 DB_PASSWORD 配置"
  }
)

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) 后端服务按序一键启动"
Write-Host "  版本: v0.2.7"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. 前置校验（JDK / 4 个 jar / 关键环境变量；任一缺失→列出缺失项+处理提示→非零退出→不启动任何服务） ==========
Write-Host "━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━"
$precheckFail = $false

# 4.1 JDK 可用性（java 命令存在即可，版本/安装完整检查由 deploy-check-env 承担）
if (Get-Command java -ErrorAction SilentlyContinue) {
  Write-Result "通过" "JDK: java 命令可用"
} else {
  Write-Result "失败" "JDK: 未检测到 java 命令，请安装 JDK 21 并配置 PATH/JAVA_HOME"
  $precheckFail = $true
}

# 4.2 4 个 jar 包存在性 + 各服务关键环境变量（缺失只列键名，不打印值）
foreach ($svc in $Services) {
  $jarPath = Join-Path $ProjectDir $svc.Jar
  if (-not (Test-Path -LiteralPath $jarPath)) {
    Write-Result "失败" "$($svc.Name): jar 包缺失（$jarPath），请执行 build-backend 构建后将 jar 落位 deploy 目录"
    $precheckFail = $true
  }
  foreach ($v in $svc.RequiredVars) {
    $value = (Get-Item -Path "Env:$v" -ErrorAction SilentlyContinue).Value
    if ([string]::IsNullOrEmpty($value)) {
      Write-Result "失败" "$($svc.Name): 关键环境变量 $v 缺失或为空，请在 env.json 中配置相应键（不打印值）"
      $precheckFail = $true
    }
  }
}

if ($precheckFail) {
  Write-Host ""
  Write-Host "  前置校验未通过：请按上述缺失项处理（构建/落位 jar、配置 env.json）后重新运行。" -ForegroundColor Red
  Write-Host "  本次未启动任何服务。" -ForegroundColor Red
  exit 1
}
Write-Host ""
Write-Result "通过" "前置校验：4 个 jar 包与关键环境变量全部就绪"

# ========== 5. 按序启动 + 逐服务健康确认（gateway → auth → biz → system，确认成功后再启动下一个） ==========
$logDir = Join-Path $ProjectDir "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

foreach ($svc in $Services) {
  Write-Host ""
  Write-Host "━━━ 启动 $($svc.Name)（端口 $($svc.Port)） ━━━"
  $jarPath = Join-Path $ProjectDir $svc.Jar
  $logFile = Join-Path $logDir "$($svc.Name)-start.log"
  $errFile = Join-Path $logDir "$($svc.Name)-start.err"
  $pidFile = Join-Path $logDir "$($svc.Name).pid"
  try {
    # Windows 后台启动：Start-Process 隐藏窗口，stdout/stderr 重定向日志，PassThru 获取进程句柄记录 PID
    $proc = Start-Process -FilePath "java" -ArgumentList "-Xms256m", "-Xmx512m", "-jar", $jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru
    $proc.Id | Out-File -Encoding ascii $pidFile
    Write-Host "  java 已后台启动（PID: $($proc.Id)），日志: $logFile" -ForegroundColor Cyan
  } catch {
    $script:serviceResults[$svc.Name] = "失败"
    Write-Result "失败" "$($svc.Name): 启动命令执行失败: $($_.Exception.Message)；请确认 JDK 21 已安装且 java 在 PATH 中"
    break
  }
  # 健康确认：HTTP 直连自身端口优先、TCP 端口探测备用；确认成功后再启动下一个服务
  if (Wait-HealthUp -Url $svc.HealthUrl -Port $svc.Port -RetryCount $RetryCount -IntervalSeconds $RetryInterval -TimeoutSec $ProbeTimeout) {
    $script:serviceResults[$svc.Name] = "通过"
    Write-Result "通过" "$($svc.Name): 已启动且健康确认成功（$($svc.HealthUrl)）"
  } else {
    $script:serviceResults[$svc.Name] = "失败"
    Write-Result "失败" "$($svc.Name): 健康确认超时（重试 $RetryCount 次/间隔 $RetryInterval 秒后仍无响应）。可能原因：端口 $($svc.Port) 被占用（请检查 9000/9100/9200/9400）、服务启动失败或依赖未就绪；请查看日志 $logFile / $errFile；$($svc.Hint)"
    break
  }
}

# ========== 6. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  后端服务一键启动完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项"
Write-Host "  各服务启动结果与健康状态："
foreach ($svc in $Services) {
  $status = $script:serviceResults[$svc.Name]
  if (-not $status) { $status = "未执行" }
  $color = if ($status -eq "通过") { "Green" } elseif ($status -eq "失败") { "Red" } else { "Yellow" }
  Write-Host "    - $($svc.Name)（端口 $($svc.Port)）: $status" -ForegroundColor $color
}
Write-Host "=============================================="

if ($script:fail -gt 0) {
  Write-Host ""
  Write-Host "存在失败项（已按失败即停策略停止后续启动），请按上述提示处理后重新运行。" -ForegroundColor Red
  exit 1
} else {
  Write-Host ""
  Write-Host "4 个后端服务全部启动成功且健康确认通过。" -ForegroundColor Green
  exit 0
}
