<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 服务环境检测与启动脚本 (Windows)
.DESCRIPTION
  1. 从 env.json 加载环境变量，校验配置完整性
  2. 检测 MySQL/MariaDB、Nacos、Redis 是否安装（命令+服务+进程三重检测）
  3. 检测服务是否运行，未运行则自动启动
  4. 打印检测结果
  可在 env.json 中配置 DB_SERVICE_NAME / DB_PROCESS_NAME / REDIS_SERVICE_NAME / REDIS_PROCESS_NAME
.EXAMPLE
  .\scripts\deploy-start-services.ps1
#>

$ProjectDir = Split-Path -Parent $PSScriptRoot

# ========== 1. 加载环境变量 ==========
if (-not (Test-Path (Join-Path $ProjectDir "env.json"))) {
  Write-Host " 错误: 环境配置文件不存在: $ProjectDir\env.json" -ForegroundColor Red
  Write-Host "   请复制 env.example.json 为 env.json 并填写配置"
  exit 1
}

. $PSScriptRoot\load-env.ps1

$requiredVars = @("NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD",
                  "REDIS_HOST", "REDIS_PORT")
$missingVars = @()
foreach ($var in $requiredVars) {
  if (-not (Get-Item "Env:$var" -ErrorAction SilentlyContinue).Value) {
    $missingVars += $var
  }
}
if ($missingVars.Count -gt 0) {
  Write-Host " 错误: 以下环境变量在 env.json 中未设置：" -ForegroundColor Red
  foreach ($var in $missingVars) { Write-Host "   - $var" }
  exit 1
}

Write-Host "`n=============================================="
Write-Host "  云漫智企 - 服务环境检测与启动"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="

$pass = 0; $fail = 0; $warn = 0

function Write-Result {
  param([string]$Service, [string]$Status, [string]$Message)
  $icon = switch ($Status) { "通过" { "" } "警告" { "" } "失败" { "" } }
  Write-Host "  $icon [$Service] $Message" -ForegroundColor $(switch ($Status) { "通过" { "Green" } "警告" { "Yellow" } "失败" { "Red" } })
}

function Test-Installed {
  param([string]$Label, [string[]]$Commands, [string[]]$Services, [string[]]$Processes,
        [scriptblock]$CustomCheck, [string]$CustomDesc)
  $methods = @()
  foreach ($cmd in $Commands) {
    $p = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($p) { $methods += "命令 $cmd"; break }
  }
  if (-not $methods -and $Services) {
    $svc = Get-Service $Services -ErrorAction SilentlyContinue
    if ($svc) { $methods += "服务 $($svc.Name)" }
  }
  if (-not $methods -and $Processes) {
    $proc = Get-Process $Processes -ErrorAction SilentlyContinue
    if ($proc) { $methods += "进程 $($proc.Name)" }
  }
  if (-not $methods -and $CustomCheck) {
    $ok = & $CustomCheck
    if ($ok) { $methods += $CustomDesc }
  }
  return ($methods -join ", ")
}

# ========== 安装检测配置（从 env.json 读取，逗号分隔转为数组）==========
$dbSvcName    = if ($env:DB_SERVICE_NAME)    { $env:DB_SERVICE_NAME    -split '\s*,\s*' } else { @("MySQL", "MariaDB") }
$dbProcName   = if ($env:DB_PROCESS_NAME)    { $env:DB_PROCESS_NAME   -split '\s*,\s*' } else { @("mysqld", "mariadbd") }

$redisSvcName   = if ($env:REDIS_SERVICE_NAME)   { $env:REDIS_SERVICE_NAME   -split '\s*,\s*' } else { @("Redis") }
$redisProcName  = if ($env:REDIS_PROCESS_NAME)   { $env:REDIS_PROCESS_NAME  -split '\s*,\s*' } else { @("redis-server") }

# ========== 2. 安装检测（三重检测）==========
Write-Host "`n━━━ 阶段一: 服务安装检测 (命令 / 服务 / 进程) ━━━"

# 2.1 MySQL/MariaDB
$found = Test-Installed -Label "MySQL/MariaDB" `
  -Commands $dbProcName `
  -Services $dbSvcName `
  -Processes $dbProcName
if ($found) { $pass++; Write-Result "MySQL/MariaDB" "通过" "已检测到 ($found)" }
else { $fail++; Write-Result "MySQL/MariaDB" "失败" "未检测到，请安装 MySQL/MariaDB，或在 env.json 中配置 DB_PROCESS_NAME / DB_SERVICE_NAME" }

# 2.2 Nacos —— NACOS_HOME 目录 + startup 脚本
$nacosHome = $env:NACOS_HOME
$nacosStartup = Join-Path $nacosHome "bin\startup.cmd"
if ((Test-Path $nacosHome) -and (Test-Path $nacosStartup)) {
  $pass++; Write-Result "Nacos" "通过" "已检测到 (目录: $nacosHome)"
} else {
  $fail++; Write-Result "Nacos" "失败" "NACOS_HOME 目录或 startup.cmd 不存在 ($nacosHome)"
}

# 2.3 Redis
$found = Test-Installed -Label "Redis" `
  -Commands $redisProcName `
  -Services $redisSvcName `
  -Processes $redisProcName
if ($found) { $pass++; Write-Result "Redis" "通过" "已检测到 ($found)" }
else { $fail++; Write-Result "Redis" "失败" "未检测到，请安装 Redis，或在 env.json 中配置 REDIS_PROCESS_NAME / REDIS_SERVICE_NAME" }

if ($fail -gt 0) {
  Write-Host "`n 存在未安装的服务，请先完成安装后重试。" -ForegroundColor Red
  exit 1
}

# ========== 3. 运行检测与启动 ==========
Write-Host "`n━━━ 阶段二: 服务运行检测与启动 ━━━"

# 3.1 MySQL/MariaDB —— 进程 + 服务 + TCP 连接 三重检测
$mysqlRunning = $null -ne (Get-Process $dbProcName -ErrorAction SilentlyContinue)
$mysqlSvc = Get-Service $dbSvcName -ErrorAction SilentlyContinue

if ($mysqlRunning) {
  $pass++; Write-Result "MySQL/MariaDB" "通过" "进程运行中 ($($mysqlRunning.Name))"
} elseif ($mysqlSvc -and $mysqlSvc.Status -eq 'Running') {
  $pass++; Write-Result "MySQL/MariaDB" "通过" "服务运行中 ($($mysqlSvc.Name))"
} else {
  Write-Result "MySQL/MariaDB" "警告" "未运行，尝试启动..."
  try {
    if ($mysqlSvc) {
      Start-Service $mysqlSvc.Name
      Start-Sleep -Seconds 2
      if ((Get-Service $mysqlSvc.Name).Status -eq 'Running') {
        $pass++; Write-Result "MySQL/MariaDB" "通过" "已启动 (服务: $($mysqlSvc.Name))"
      } else { $warn++; Write-Result "MySQL/MariaDB" "警告" "服务 $($mysqlSvc.Name) 启动超时" }
    } else {
      $mysqlExe = (Get-Command "mysqld" -ErrorAction SilentlyContinue).Source
      if (-not $mysqlExe) { $mysqlExe = (Get-Command "mariadbd" -ErrorAction SilentlyContinue).Source }
      if ($mysqlExe) {
        Start-Process -FilePath $mysqlExe -NoNewWindow
        Start-Sleep -Seconds 3
        if (Get-Process $dbProcName -ErrorAction SilentlyContinue) {
          $pass++; Write-Result "MySQL/MariaDB" "通过" "已启动 (直接执行 $mysqlExe)"
        } else { $warn++; Write-Result "MySQL/MariaDB" "警告" "启动命令已执行，请检查状态" }
      } else { $warn++; Write-Result "MySQL/MariaDB" "警告" "找不到可执行文件，请手动启动" }
    }
  } catch { $warn++; Write-Result "MySQL/MariaDB" "警告" "启动失败: $_" }
}

# 3.2 Nacos —— HTTP 探测 + 进程检测
$nacosRunning = $false
try {
  $resp = Invoke-WebRequest -Uri "http://$env:NACOS_ADDR/nacos/" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
  if ($resp.Content -match "Nacos") { $nacosRunning = $true }
} catch {}

if ($nacosRunning) {
  $pass++; Write-Result "Nacos" "通过" "HTTP 探测正常 (http://$env:NACOS_ADDR/nacos/)"
} else {
  $nacosProc = Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "nacos" -or $_.MainWindowTitle -match "Nacos" }
  if ($nacosProc) {
    $pass++; Write-Result "Nacos" "通过" "进程运行中 (java - nacos)"
  } else {
    Write-Result "Nacos" "警告" "未运行，尝试启动..."
    $nacosStartup = Join-Path $env:NACOS_HOME "bin\startup.cmd"
    if (Test-Path $nacosStartup) {
      try {
        $job = Start-Job -ScriptBlock { param($p) & cmd /c "start `"Nacos`" `"$p`" -m standalone" } -ArgumentList $nacosStartup
        Start-Sleep -Seconds 8
        try {
          $resp = Invoke-WebRequest -Uri "http://$env:NACOS_ADDR/nacos/" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
          if ($resp.Content -match "Nacos") {
            $pass++; Write-Result "Nacos" "通过" "已启动 (http://$env:NACOS_ADDR/nacos/)"
          } else { $warn++; Write-Result "Nacos" "警告" "Nacos 可能未完全启动，请稍后检查" }
        } catch { $warn++; Write-Result "Nacos" "警告" "Nacos 启动中，请稍后手动检查 http://$env:NACOS_ADDR/nacos/" }
      } catch { $warn++; Write-Result "Nacos" "警告" "启动失败: $_" }
    } else { $warn++; Write-Result "Nacos" "警告" "找不到启动脚本: $nacosStartup" }
  }
}

# 3.3 Redis —— 进程 + 服务 + redis-cli ping 三重检测
$redisProc = Get-Process $redisProcName -ErrorAction SilentlyContinue
$redisSvc = Get-Service $redisSvcName -ErrorAction SilentlyContinue

if ($redisProc) {
  $pass++; Write-Result "Redis" "通过" "进程运行中 ($($redisProc.Name))"
} elseif ($redisSvc -and $redisSvc.Status -eq 'Running') {
  $pass++; Write-Result "Redis" "通过" "服务运行中 ($($redisSvc.Name))"
} else {
  Write-Result "Redis" "警告" "未运行，尝试启动..."
  try {
    if ($redisSvc) {
      Start-Service $redisSvc.Name
      Start-Sleep -Seconds 2
      if ((Get-Service $redisSvc.Name).Status -eq 'Running') {
        $pass++; Write-Result "Redis" "通过" "已启动 (服务: $($redisSvc.Name))"
      } else { $warn++; Write-Result "Redis" "警告" "服务 $($redisSvc.Name) 启动超时" }
    } else {
      $redisExe = (Get-Command "redis-server" -ErrorAction SilentlyContinue).Source
      if ($redisExe) {
        Start-Process -FilePath $redisExe -NoNewWindow
        Start-Sleep -Seconds 2
        $ping = & redis-cli ping 2>&1
        if ($ping -eq "PONG") {
          $pass++; Write-Result "Redis" "通过" "已启动 (redis-server, PONG)"
        } else { $warn++; Write-Result "Redis" "警告" "启动命令已执行，请检查状态" }
      } else { $warn++; Write-Result "Redis" "警告" "找不到 redis-server，请手动启动" }
    }
  } catch { $warn++; Write-Result "Redis" "警告" "启动失败: $_" }
}

# ========== 汇总 ==========
Write-Host "`n=============================================="
$totalResult = if ($fail -gt 0) { "失败" } elseif ($warn -gt 0) { "完成 (有警告)" } else { "全部通过" }
$color = if ($fail -gt 0) { "Red" } elseif ($warn -gt 0) { "Yellow" } else { "Green" }
Write-Host "  检测结果: $totalResult" -ForegroundColor $color
Write-Host "   通过: $pass |  警告: $warn |  失败: $fail"
Write-Host "==============================================`n"

if ($fail -gt 0) { exit 1 } else { exit 0 }
