# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 环境可用性检查与运行状态检测脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）执行：
    阶段一 环境可用性检查（F-002~F-005）：
      - JDK：java 命令可执行 + JAVA_HOME 有效 + 版本 21
      - MariaDB：命令/系统服务/进程三重安装检测 + SELECT 1 连通性（口令掩码）
      - Redis：命令/系统服务/进程三重安装检测 + redis-cli ping 返回 PONG
      - Nacos：NACOS_HOME/bin/startup.cmd 存在 + HTTP 探测 http://NACOS_ADDR/nacos/ 含 Nacos
    阶段二 运行状态检测（F-006）：
      - JDK：复用可用性检查结论（可用即视为就绪）
      - MariaDB/Redis：进程 / 系统服务 Running / TCP 端口可达，任一命中即运行中
      - Nacos：HTTP 探测含 Nacos 即运行中，失败再检测 java 进程命令行含 nacos 作辅助
  输出分级（通过/警告/失败）与退出码约定（F-011）：
    全部通过退出 0；存在失败项退出 1；存在警告但无失败退出 0 并提示警告。
  本脚本仅做检查，不执行任何启动动作（启动由 deploy-start-services 负责）。
  版本: v0.2.7
.EXAMPLE
  .\deploy\scripts\deploy-check-env.ps1
#>

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json） ==========
. "$PSScriptRoot\load-env.ps1"

# ========== 1. 全局计数与输出辅助 ==========
$script:pass = 0
$script:warn = 0
$script:fail = 0

# 输出「通过/警告/失败」三级结果并累计计数（F-011 输出分级约定）
function Write-Result {
  param([string]$Status, [string]$Message)
  switch ($Status) {
    "通过" { Write-Host "  [通过] $Message" -ForegroundColor Green;  $script:pass++ }
    "警告" { Write-Host "  [警告] $Message" -ForegroundColor Yellow; $script:warn++ }
    "失败" { Write-Host "  [失败] $Message" -ForegroundColor Red;    $script:fail++ }
  }
}

# 逗号分隔字符串转数组（去空白，用于服务名/进程名检测清单）
function Split-Csv {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
  return @($Value -split '\s*,\s*' | Where-Object { $_ })
}

# 安装三重检测：命令 / 系统服务 / 进程，任一命中即返回命中方式（F-003/F-004）
function Test-Installed {
  param([string[]]$Commands, [string[]]$Services, [string[]]$Processes)
  foreach ($cmd in $Commands) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return "命令 $cmd" }
  }
  foreach ($svc in $Services) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) { return "服务 $svc" }
  }
  foreach ($proc in $Processes) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) { return "进程 $proc" }
  }
  return $null
}

# TCP 端口可达性探测（TcpClient，超时可控；用于运行状态检测 F-006）
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

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006）
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

# ========== 2. 解析 env.json 中的可选检测清单（服务/进程名，非连接地址，允许默认清单） ==========
$dbSvcName     = if ($env:DB_SERVICE_NAME)     { Split-Csv $env:DB_SERVICE_NAME }     else { @("MySQL", "MariaDB") }
$dbProcName    = if ($env:DB_PROCESS_NAME)     { Split-Csv $env:DB_PROCESS_NAME }     else { @("mysqld", "mariadbd") }
$redisSvcName  = if ($env:REDIS_SERVICE_NAME)  { Split-Csv $env:REDIS_SERVICE_NAME }  else { @("Redis") }
$redisProcName = if ($env:REDIS_PROCESS_NAME)  { Split-Csv $env:REDIS_PROCESS_NAME }  else { @("redis-server") }

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) 环境可用性检查与运行状态检测"
Write-Host "  版本: v0.2.7"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. 阶段一：环境可用性检查（F-002~F-005） ==========
Write-Host "━━━ 阶段一: 环境可用性检查 ━━━"

# 4.1 JDK 可用性（命令可执行 + JAVA_HOME 有效 + 版本 21，合并为一项结论，F-002）
$javaOk = $false
$javaHomeOk = $false
if (Get-Command java -ErrorAction SilentlyContinue) {
  try {
    $javaVer = & java -version 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $javaVer -match 'version "21') { $javaOk = $true }
  } catch { $javaOk = $false }
}
if (-not [string]::IsNullOrEmpty($env:JAVA_HOME) -and (Test-Path $env:JAVA_HOME)) { $javaHomeOk = $true }

if ($javaOk -and $javaHomeOk) {
  Write-Result "通过" "JDK 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21）"
} else {
  Write-Result "失败" "JDK 不可用（java 命令/版本 21/JAVA_HOME 任一不满足），请安装 JDK 21 并配置 JAVA_HOME"
}

# 4.2 MariaDB 可用性（命令/服务/进程三重安装检测 + SELECT 1，F-003）
$dbInstall = Test-Installed -Commands @("mariadb", "mysql", "mysqld", "mariadbd") -Services $dbSvcName -Processes $dbProcName

if (-not $dbInstall) {
  Write-Result "失败" "MariaDB 未安装（未检测到命令/系统服务/进程），请安装 MariaDB 或 MySQL，或在 env.json 中配置 DB_SERVICE_NAME/DB_PROCESS_NAME"
} else {
  $dbClient = (Get-Command mariadb -ErrorAction SilentlyContinue).Source
  if (-not $dbClient) { $dbClient = (Get-Command mysql -ErrorAction SilentlyContinue).Source }
  if (-not $dbClient) {
    Write-Result "失败" "MariaDB 已安装（$dbInstall），但未找到 mariadb/mysql 客户端命令，无法执行 SELECT 1，请安装客户端工具"
  } else {
    $connOk = $false
    try {
      # 口令经 MYSQL_PWD 环境变量传递（不出现于进程命令行，消除 S-01 进程级口令泄露；
      # MYSQL_PWD 在 MySQL 官方文档标注弃用，但 MariaDB 客户端完整支持；若后续升级
      # 客户端不再支持，可改经 --defaults-extra-file 临时配置文件传递，见审核报告 S-01 决策）
      $oldMysqlPwd = $env:MYSQL_PWD
      $env:MYSQL_PWD = $env:DB_PASSWORD
      try {
        # 命令不含 -p 参数，口令仅经环境变量传递；日志仅显示掩码 ****
        $null = & $dbClient -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USERNAME -N -B -e "SELECT 1" 2>&1
        if ($LASTEXITCODE -eq 0) { $connOk = $true }
      } finally {
        # 恢复原 MYSQL_PWD（避免污染后续命令）
        if ($null -eq $oldMysqlPwd) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue } else { $env:MYSQL_PWD = $oldMysqlPwd }
      }
    } catch { $connOk = $false }
    if ($connOk) {
      Write-Result "通过" "MariaDB 可用（安装: $dbInstall；SELECT 1 连接成功，口令掩码 ****）"
    } else {
      Write-Result "失败" "MariaDB 已安装（$dbInstall）但连接失败，请检查 env.json 中 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD（口令掩码 ****）"
    }
  }
}

# 4.3 Redis 可用性（命令/服务/进程三重安装检测 + ping 返回 PONG，F-004）
$redisInstall = Test-Installed -Commands @("redis-cli", "redis-server") -Services $redisSvcName -Processes $redisProcName

if (-not $redisInstall) {
  Write-Result "失败" "Redis 未安装（未检测到命令/系统服务/进程），请安装 Redis 或在 env.json 中配置 REDIS_SERVICE_NAME/REDIS_PROCESS_NAME"
} else {
  if (-not (Get-Command redis-cli -ErrorAction SilentlyContinue)) {
    Write-Result "失败" "Redis 已安装（$redisInstall），但未找到 redis-cli 命令，无法执行 ping，请安装 redis-cli"
  } else {
    $pingOk = $false
    try {
      # 口令经 REDISCLI_AUTH 环境变量传递（Redis 官方推荐），命令与日志均不出现明文
      if (-not [string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $env:REDISCLI_AUTH = $env:REDIS_PASSWORD }
      $pong = & redis-cli -h $env:REDIS_HOST -p $env:REDIS_PORT ping 2>&1
      if ($pong -match "PONG") { $pingOk = $true }
    } catch { $pingOk = $false }
    if ($pingOk) {
      Write-Result "通过" "Redis 可用（安装: $redisInstall；ping 返回 PONG）"
    } else {
      Write-Result "失败" "Redis 已安装（$redisInstall）但 ping 失败，请检查 env.json 中 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD"
    }
  }
}

# 4.4 Nacos 可用性（NACOS_HOME/startup.cmd 安装检测 + HTTP 探测；已安装未启动计「警告（未运行）」F-005）
$nacosAddrValid = $env:NACOS_ADDR -match '^[^:]+:\d+$'
$nacosInstalled = $false
$script:nacosHttpOk = $false
$nacosStartup = Join-Path $env:NACOS_HOME "bin\startup.cmd"

if (-not $nacosAddrValid) {
  Write-Result "失败" "Nacos 地址格式非法（$env:NACOS_ADDR），请检查 env.json 中 NACOS_ADDR（应为 host:port）"
} elseif (-not (Test-Path $env:NACOS_HOME) -or -not (Test-Path $nacosStartup)) {
  Write-Result "失败" "Nacos 未安装（NACOS_HOME 目录或 bin\startup.cmd 不存在: $env:NACOS_HOME），请安装 Nacos 或配置 env.json 中 NACOS_HOME"
} else {
  $nacosInstalled = $true
  $script:nacosHttpOk = Test-NacosHttp
  if ($script:nacosHttpOk) {
    Write-Result "通过" "Nacos 可用（已安装: $env:NACOS_HOME；HTTP 探测 http://$env:NACOS_ADDR/nacos/ 返回 Nacos）"
  } else {
    Write-Result "警告" "Nacos 未运行（已安装: $env:NACOS_HOME；HTTP 探测 http://$env:NACOS_ADDR/nacos/ 失败）"
  }
}

# ========== 5. 阶段二：运行状态检测（F-006） ==========
Write-Host ""
Write-Host "━━━ 阶段二: 运行状态检测 ━━━"

# 5.1 JDK：复用可用性检查结论（可用即视为就绪，无独立启动检查）
if ($javaOk -and $javaHomeOk) {
  Write-Result "通过" "JDK 运行状态: 就绪（复用可用性检查结论）"
} else {
  Write-Result "失败" "JDK 运行状态: 不可用（JDK 未就绪，请先解决可用性失败项）"
}

# 5.2 MariaDB：进程 / 系统服务 Running / TCP 端口 任一命中即运行中
$dbRunning = $false
if (Get-Process -Name $dbProcName -ErrorAction SilentlyContinue) { $dbRunning = $true }
if (-not $dbRunning) {
  foreach ($svc in $dbSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq 'Running') { $dbRunning = $true; break }
  }
}
if (-not $dbRunning -and (Test-TcpPort -HostName $env:DB_HOST -Port $env:DB_PORT)) { $dbRunning = $true }

if (-not $dbInstall) {
  Write-Result "失败" "MariaDB 运行状态: 未安装（不可启动）"
} elseif ($dbRunning) {
  Write-Result "通过" "MariaDB 运行状态: 运行中（进程/系统服务/TCP 任一命中）"
} else {
  Write-Result "警告" "MariaDB 运行状态: 未运行（进程/系统服务/TCP 均未检测到，供 deploy-start-services 启动）"
}

# 5.3 Redis：进程 / 系统服务 Running / TCP 端口 任一命中即运行中
$redisRunning = $false
if (Get-Process -Name $redisProcName -ErrorAction SilentlyContinue) { $redisRunning = $true }
if (-not $redisRunning) {
  foreach ($svc in $redisSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq 'Running') { $redisRunning = $true; break }
  }
}
if (-not $redisRunning -and (Test-TcpPort -HostName $env:REDIS_HOST -Port $env:REDIS_PORT)) { $redisRunning = $true }

if (-not $redisInstall) {
  Write-Result "失败" "Redis 运行状态: 未安装（不可启动）"
} elseif ($redisRunning) {
  Write-Result "通过" "Redis 运行状态: 运行中（进程/系统服务/TCP 任一命中）"
} else {
  Write-Result "警告" "Redis 运行状态: 未运行（进程/系统服务/TCP 均未检测到，供 deploy-start-services 启动）"
}

# 5.4 Nacos：HTTP 探测为主（复用阶段一结果），java 进程命令行含 nacos 为辅助
$nacosRunning = $script:nacosHttpOk
if (-not $nacosRunning) { $nacosRunning = Test-NacosJavaProcess }

if (-not $nacosAddrValid) {
  Write-Result "失败" "Nacos 运行状态: 不可检测（NACOS_ADDR 格式非法）"
} elseif (-not $nacosInstalled) {
  Write-Result "失败" "Nacos 运行状态: 未安装（不可启动）"
} elseif ($nacosRunning) {
  Write-Result "通过" "Nacos 运行状态: 运行中（HTTP 探测或 java 进程含 nacos）"
} else {
  Write-Result "警告" "Nacos 运行状态: 未运行（HTTP 探测失败且未检测到 java 进程含 nacos，供 deploy-start-services 启动）"
}

# ========== 6. 汇总与退出码（F-011） ==========
Write-Host ""
Write-Host "=============================================="
$summaryColor = if ($script:fail -gt 0) { "Red" } elseif ($script:warn -gt 0) { "Yellow" } else { "Green" }
Write-Host "  检查完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项" -ForegroundColor $summaryColor
Write-Host "=============================================="

if ($script:fail -gt 0) {
  Write-Host "`n存在失败的检查项，请按上述提示处理后重新运行。" -ForegroundColor Red
  exit 1
} elseif ($script:warn -gt 0) {
  Write-Host "`n存在警告项，请关注未运行/待处理组件（警告不阻断部署）。" -ForegroundColor Yellow
  exit 0
} else {
  Write-Host "`n全部检查通过，可以继续进行部署。" -ForegroundColor Green
  exit 0
}
