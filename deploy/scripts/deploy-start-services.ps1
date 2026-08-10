# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 基础设施运行状态检查与一键启动脚本 (Windows)
.DESCRIPTION
  基于 deploy/env.json（经 load-env 统一加载，F-001）执行（F-006/F-007）：
    1. JDK 可用性检查（仅输出就绪/缺失结论，不执行启动）
    2. MariaDB/Redis/Nacos 运行状态检测：
       - 未安装：不尝试启动，输出"未安装，请先安装"并计入失败
       - 已运行：幂等跳过，输出"已运行"
       - 未运行且已安装：按 MariaDB → Redis → Nacos 顺序自动启动
         启动方式优先级：系统服务（Start-Service）→ 可执行文件（mysqld/mariadbd/redis-server）
         Nacos 执行 NACOS_HOME/bin/startup.cmd -m standalone
       - 每次启动后循环探测确认（进程/TCP/ping/HTTP，超时上限 30s、间隔 2s），不报假成功
  输出分级（通过/警告/失败）与退出码约定（F-011）：
    全部通过退出 0；存在失败项退出 1；存在警告但无失败退出 0 并提示警告。
  安全约定：口令掩码不打印明文（DB_PASSWORD / REDIS_PASSWORD 经 REDISCLI_AUTH 传递）。
  版本: v0.2.7
.EXAMPLE
  .\deploy\scripts\deploy-start-services.ps1
#>

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 兜底退出） ==========
$ProjectDir = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\load-env.ps1"

# ========== 1. 全局计数与输出辅助（F-011 输出分级） ==========
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

# 逗号分隔字符串转数组（去空白，用于服务名/进程名检测清单）
function Split-Csv {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
  return @($Value -split '\s*,\s*' | Where-Object { $_ })
}

# 安装三重检测：命令 / 系统服务 / 进程，任一命中即返回命中方式（F-007 未安装判定）
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

# TCP 端口可达性探测（TcpClient，超时可控；用于运行状态检测与启动后确认 F-006/F-007）
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

# MariaDB 运行状态探测：进程 / 系统服务 Running / TCP 端口 任一命中即运行中（F-006）
function Test-MariaDbUp {
  if (Get-Process -Name $dbProcName -ErrorAction SilentlyContinue) { return $true }
  foreach ($svc in $dbSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq 'Running') { return $true }
  }
  return (Test-TcpPort -HostName $env:DB_HOST -Port $env:DB_PORT)
}

# Redis 运行状态探测：进程 / 系统服务 Running / TCP 端口 / redis-cli ping PONG（口令经 REDISCLI_AUTH，F-006）
function Test-RedisPing {
  # 口令经 REDISCLI_AUTH 环境变量传递（Redis 官方推荐），命令与日志均不出现明文
  if (-not [string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $env:REDISCLI_AUTH = $env:REDIS_PASSWORD }
  if (-not (Get-Command redis-cli -ErrorAction SilentlyContinue)) { return $false }
  try {
    $pong = & redis-cli -h $env:REDIS_HOST -p $env:REDIS_PORT ping 2>&1
    return ($pong -match "PONG")
  } catch { return $false }
}
function Test-RedisUp {
  if (Get-Process -Name $redisProcName -ErrorAction SilentlyContinue) { return $true }
  foreach ($svc in $redisSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq 'Running') { return $true }
  }
  if (Test-TcpPort -HostName $env:REDIS_HOST -Port $env:REDIS_PORT) { return $true }
  return (Test-RedisPing)
}

# Nacos 运行状态探测：HTTP 探测为主 + java 进程含 nacos 辅助（F-006）
function Test-NacosUp {
  if (Test-NacosHttp) { return $true }
  return (Test-NacosJavaProcess)
}

# 启动后循环探测确认：超时上限内每间隔探测一次，任一命中即返回 $true（F-007，不报假成功）
function Wait-ServiceUp {
  param([scriptblock]$Probe, [int]$TimeoutSeconds = 30, [int]$IntervalSeconds = 2)
  $elapsed = 0
  while ($elapsed -lt $TimeoutSeconds) {
    try { if (& $Probe) { return $true } } catch { }
    Start-Sleep -Seconds $IntervalSeconds
    $elapsed += $IntervalSeconds
  }
  return $false
}

# ========== 2. 解析 env.json 中的可选检测清单（服务/进程名，非连接地址，允许默认清单） ==========
$dbSvcName     = if ($env:DB_SERVICE_NAME)     { Split-Csv $env:DB_SERVICE_NAME }     else { @("MySQL", "MariaDB") }
$dbProcName    = if ($env:DB_PROCESS_NAME)     { Split-Csv $env:DB_PROCESS_NAME }     else { @("mysqld", "mariadbd") }
$redisSvcName  = if ($env:REDIS_SERVICE_NAME)  { Split-Csv $env:REDIS_SERVICE_NAME }  else { @("Redis") }
$redisProcName = if ($env:REDIS_PROCESS_NAME)  { Split-Csv $env:REDIS_PROCESS_NAME }  else { @("redis-server") }

# ========== 3. 标题 ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) 基础设施运行状态检查与一键启动"
Write-Host "  版本: v0.2.7"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ========== 4. JDK 可用性检查（F-006：仅输出结论，不执行启动） ==========
Write-Host "━━━ JDK 可用性（仅检查，不启动） ━━━"
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
  Write-Result "通过" "JDK: 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21），无需启动"
} else {
  Write-Result "失败" "JDK: 不可用（java 命令/版本 21/JAVA_HOME 任一不满足），请安装 JDK 21 并配置 JAVA_HOME（仅检查不启动，不阻断基础设施启动）"
}

# ========== 5. MariaDB：运行检测与启动（F-006/F-007，启动顺序第一位） ==========
Write-Host ""
Write-Host "━━━ MariaDB（运行检测 → 启动 → 循环探测确认） ━━━"
$dbInstall = Test-Installed -Commands @("mariadb", "mysql", "mysqld", "mariadbd") -Services $dbSvcName -Processes $dbProcName
if (-not $dbInstall) {
  # 未安装：不尝试启动，计入失败，继续后续服务
  Write-Result "失败" "MariaDB: 未安装，请先安装（未检测到命令/系统服务/进程，或配置 DB_SERVICE_NAME/DB_PROCESS_NAME）"
} elseif (Test-MariaDbUp) {
  # 已运行：幂等跳过，不重复启动
  Write-Result "通过" "MariaDB: 已运行（进程/系统服务/TCP 任一命中），幂等跳过"
} else {
  $dbStatus = ""; $dbMsg = ""
  Write-Host "  MariaDB: 未运行，尝试启动..." -ForegroundColor Cyan
  $started = $false
  # 方式一：系统服务（Windows Start-Service，优先）
  $foundSvc = $null
  foreach ($svc in $dbSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) { $foundSvc = $s; break }
  }
  if ($foundSvc) {
    try {
      Start-Service -Name $foundSvc.Name -ErrorAction Stop
      $started = Wait-ServiceUp -Probe { Test-MariaDbUp }
    } catch {
      Write-Host "  MariaDB: 系统服务 $($foundSvc.Name) 启动失败: $($_.Exception.Message)（若权限不足请以管理员身份运行）" -ForegroundColor Yellow
    }
    if ($started) {
      $dbStatus = "通过"; $dbMsg = "MariaDB: 已通过系统服务 $($foundSvc.Name) 启动（循环探测确认）"
    } else {
      $dbStatus = "警告"; $dbMsg = "MariaDB: 系统服务 $($foundSvc.Name) 启动超时或失败，请等待数秒后重试，或手动检查服务状态与 mysqld 日志；若为权限问题请以管理员身份运行"
    }
  } else {
    # 方式二：可执行文件（无系统服务时兜底）
    $foundExe = $null
    foreach ($p in $dbProcName) {
      $exe = (Get-Command $p -ErrorAction SilentlyContinue).Source
      if ($exe) { $foundExe = $exe; break }
    }
    if (-not $foundExe) {
      $dbStatus = "警告"; $dbMsg = "MariaDB: 未找到系统服务或可执行文件（$($dbProcName -join ', ')），请手动启动服务"
    } else {
      try {
        # S-03 修复：兜底启动携带 env.json 端口配置（--port），使启动实例与配置一致；
        # 凭据（DB_USERNAME/DB_PASSWORD）存于数据库内部用户，无需命令行传递；
        # 若数据目录未初始化，mysqld 无法直接启动，请先初始化数据目录或改用系统服务启动
        $dbArgs = @("--port=$env:DB_PORT")
        Start-Process -FilePath $foundExe -ArgumentList $dbArgs -WindowStyle Hidden -PassThru | Out-Null
        $started = Wait-ServiceUp -Probe { Test-MariaDbUp }
      } catch {
        Write-Host "  MariaDB: 启动 $foundExe 失败: $($_.Exception.Message)" -ForegroundColor Yellow
      }
      if ($started) {
        $dbStatus = "通过"; $dbMsg = "MariaDB: 已通过可执行文件 $foundExe 启动（携带 env.json 端口 $env:DB_PORT，循环探测确认）"
      } else {
        $dbStatus = "警告"; $dbMsg = "MariaDB: 可执行文件 $foundExe 启动超时或失败，请等待数秒后重试，或手动检查 mysqld 日志；若数据目录未初始化请先初始化再启动；若为权限问题请以管理员身份运行；请注意本次为兜底启动，请核对实例端口/数据目录与 env.json 配置一致性"
      }
    }
  }
  Write-Result $dbStatus $dbMsg
}

# ========== 6. Redis：运行检测与启动（F-006/F-007，启动顺序第二位） ==========
Write-Host ""
Write-Host "━━━ Redis（运行检测 → 启动 → 循环探测确认） ━━━"
$redisInstall = Test-Installed -Commands @("redis-cli", "redis-server") -Services $redisSvcName -Processes $redisProcName
if (-not $redisInstall) {
  # 未安装：不尝试启动，计入失败，继续后续服务
  Write-Result "失败" "Redis: 未安装，请先安装（未检测到命令/系统服务/进程，或配置 REDIS_SERVICE_NAME/REDIS_PROCESS_NAME）"
} elseif (Test-RedisUp) {
  # 已运行：幂等跳过，不重复启动
  Write-Result "通过" "Redis: 已运行（进程/系统服务/TCP/redis-cli ping 任一命中），幂等跳过"
} else {
  $redisStatus = ""; $redisMsg = ""
  Write-Host "  Redis: 未运行，尝试启动..." -ForegroundColor Cyan
  $started = $false
  # 方式一：系统服务（Windows Start-Service，优先）
  $foundSvc = $null
  foreach ($svc in $redisSvcName) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) { $foundSvc = $s; break }
  }
  if ($foundSvc) {
    try {
      Start-Service -Name $foundSvc.Name -ErrorAction Stop
      $started = Wait-ServiceUp -Probe { Test-RedisUp }
    } catch {
      Write-Host "  Redis: 系统服务 $($foundSvc.Name) 启动失败: $($_.Exception.Message)（若权限不足请以管理员身份运行）" -ForegroundColor Yellow
    }
    if ($started) {
      $redisStatus = "通过"; $redisMsg = "Redis: 已通过系统服务 $($foundSvc.Name) 启动（循环探测确认）"
    } else {
      $redisStatus = "警告"; $redisMsg = "Redis: 系统服务 $($foundSvc.Name) 启动超时或失败，请等待数秒后重试，或手动检查服务状态与 redis 日志；若为权限问题请以管理员身份运行"
    }
  } else {
    # 方式二：可执行文件（无系统服务时兜底）
    $foundExe = $null
    foreach ($p in $redisProcName) {
      $exe = (Get-Command $p -ErrorAction SilentlyContinue).Source
      if ($exe) { $foundExe = $exe; break }
    }
    if (-not $foundExe) {
      $redisStatus = "警告"; $redisMsg = "Redis: 未找到系统服务或可执行文件（$($redisProcName -join ', ')），请手动启动服务"
    } else {
      try {
        # S-03 修复：兜底启动携带 env.json 端口与口令配置（--port/--requirepass），
        # 使启动实例与 env.json 一致（带 REDISCLI_AUTH 的 ping 探测可正常通过）；
        # 注意：--requirepass 口令会出现在进程命令行（Redis 无 MYSQL_PWD 等价方案），
        # 如需彻底隐藏口令请改用系统服务或配置文件方式启动
        $redisArgs = @("--port", "$env:REDIS_PORT")
        if (-not [string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $redisArgs += @("--requirepass", $env:REDIS_PASSWORD) }
        Start-Process -FilePath $foundExe -ArgumentList $redisArgs -WindowStyle Hidden -PassThru | Out-Null
        $started = Wait-ServiceUp -Probe { Test-RedisUp }
      } catch {
        Write-Host "  Redis: 启动 $foundExe 失败: $($_.Exception.Message)" -ForegroundColor Yellow
      }
      if ($started) {
        $redisStatus = "通过"; $redisMsg = "Redis: 已通过可执行文件 $foundExe 启动（携带 env.json 端口 $env:REDIS_PORT，循环探测确认）"
      } else {
        $redisStatus = "警告"; $redisMsg = "Redis: 可执行文件 $foundExe 启动超时或失败，请等待数秒后重试，或手动检查 redis 日志；请注意本次为兜底启动，请核对实例端口/口令与 env.json 配置一致性；若为权限问题请以管理员身份运行"
      }
    }
  }
  Write-Result $redisStatus $redisMsg
}

# ========== 7. Nacos：运行检测与启动（F-006/F-007，启动顺序第三位） ==========
Write-Host ""
Write-Host "━━━ Nacos（运行检测 → 启动 → 循环 HTTP 探测确认） ━━━"
$nacosAddrValid = $env:NACOS_ADDR -match '^[^:]+:\d+$'
$nacosStartup = Join-Path $env:NACOS_HOME "bin\startup.cmd"
if (-not $nacosAddrValid) {
  # 地址格式非法：计入失败，不尝试启动
  Write-Result "失败" "Nacos: 地址格式非法（$env:NACOS_ADDR），请检查 env.json 中 NACOS_ADDR（应为 host:port）"
} elseif (-not (Test-Path $env:NACOS_HOME) -or -not (Test-Path $nacosStartup)) {
  # 未安装：不尝试启动，计入失败，继续后续流程
  Write-Result "失败" "Nacos: 未安装，请先安装（NACOS_HOME 目录或 bin\startup.cmd 不存在: $env:NACOS_HOME）"
} elseif (Test-NacosUp) {
  # 已运行：幂等跳过，不重复启动
  Write-Result "通过" "Nacos: 已运行（HTTP 探测或 java 进程含 nacos），幂等跳过"
} else {
  Write-Host "  Nacos: 未运行，尝试启动..." -ForegroundColor Cyan
  # 确保日志目录存在，启动日志落盘便于失败定位（不含口令类明文）
  $logDir = Join-Path $ProjectDir "logs"
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $nacosLog = Join-Path $logDir "nacos-start.log"
  $nacosErr = Join-Path $logDir "nacos-start.err"
  try {
    # Windows 下经 cmd /c 执行 startup.cmd -m standalone（standalone 单机模式），隐藏窗口并重定向日志
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$nacosStartup`" -m standalone" -WindowStyle Hidden -RedirectStandardOutput $nacosLog -RedirectStandardError $nacosErr -PassThru | Out-Null
    $started = Wait-ServiceUp -Probe { Test-NacosUp }
    if ($started) {
      Write-Result "通过" "Nacos: 启动成功（startup.cmd -m standalone，HTTP 探测确认）"
    } else {
      Write-Result "警告" "Nacos: 启动超时，请等待数秒后重试，或手动检查 $nacosLog 与 Nacos logs/start.out；若端口 8848 被占用请排查 netstat -ano"
    }
  } catch {
    Write-Result "警告" "Nacos: 启动失败: $($_.Exception.Message)，请手动执行 $nacosStartup -m standalone 排查"
  }
}

# ========== 8. 汇总与退出码（F-011） ==========
Write-Host ""
Write-Host "=============================================="
$summaryColor = if ($script:fail -gt 0) { "Red" } elseif ($script:warn -gt 0) { "Yellow" } else { "Green" }
Write-Host "  基础设施启动完成: 通过 $script:pass 项 | 警告 $script:warn 项 | 失败 $script:fail 项" -ForegroundColor $summaryColor
if ($script:fail -eq 0 -and $script:warn -eq 0) {
  Write-Host "  基础设施（MariaDB/Redis/Nacos）全部可达，可启动后端服务（deploy-start-all）。" -ForegroundColor Green
}
Write-Host "=============================================="

if ($script:fail -gt 0) {
  Write-Host "`n存在失败项，请按上述提示处理后重新运行。" -ForegroundColor Red
  exit 1
} elseif ($script:warn -gt 0) {
  Write-Host "`n存在警告项，请关注启动超时/待处理服务（警告不阻断部署）。" -ForegroundColor Yellow
  exit 0
} else {
  Write-Host "`n基础设施全部就绪。" -ForegroundColor Green
  exit 0
}
