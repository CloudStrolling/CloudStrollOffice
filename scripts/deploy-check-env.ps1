<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 部署前置检查脚本 (Windows)
.DESCRIPTION
  逐一检查中间件可用性、开发环境、网络连通性
.PARAMETER NacosAddr
  Nacos 服务地址 (默认: 192.168.1.100:8848)
.PARAMETER DbHost
  数据库主机 (默认: 192.168.1.101)
.PARAMETER DbPort
  数据库端口 (默认: 3306)
.PARAMETER DbUser
  数据库用户名 (默认: root)
.PARAMETER DbPassword
  数据库密码
.PARAMETER RedisHost
  Redis 主机 (默认: 192.168.1.102)
.PARAMETER RedisPort
  Redis 端口 (默认: 6379)
.EXAMPLE
  .\scripts\deploy-check-env.ps1 -DbPassword "YourP@ss"
#>

param(
  [string]$NacosAddr = "192.168.1.100:8848",
  [string]$DbHost = "192.168.1.101",
  [int]$DbPort = 3306,
  [string]$DbUser = "root",
  [string]$DbPassword = "<DB_PASSWORD>",
  [string]$RedisHost = "192.168.1.102",
  [int]$RedisPort = 6379
)

# ========== 从 env.json 加载环境变量 ==========
$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive
. "$PSScriptRoot\load-env.ps1"
if (-not $DbPassword -or $DbPassword -eq "<DB_PASSWORD>") { $DbPassword = $env:DB_PASSWORD }
if ($NacosAddr -eq "192.168.1.100:8848") { $NacosAddr = $env:NACOS_ADDR }
if (-not $DbHost -or $DbHost -eq "192.168.1.101") { $DbHost = $env:DB_HOST }
if ($DbPort -eq 3306) { $DbPort = [int]($env:DB_PORT -replace '\D','') }
if (-not $DbUser -or $DbUser -eq "root") { $DbUser = $env:DB_USERNAME }
if (-not $RedisHost -or $RedisHost -eq "192.168.1.102") { $RedisHost = $env:REDIS_HOST }
if ($RedisPort -eq 6379) { $RedisPort = [int]($env:REDIS_PORT -replace '\D','') }

$pass = 0
$fail = 0

function Check {
  param([string]$Desc, [scriptblock]$Cmd, [string]$Expected)

  Write-Host -NoNewline "[..] $Desc ... "
  try {
    $result = & $Cmd
    if ($LASTEXITCODE -eq 0 -or $?) {
      Write-Host "通过" -ForegroundColor Green
      $script:pass++
    } else {
      throw "命令执行失败"
    }
  } catch {
    Write-Host "失败" -ForegroundColor Red
    Write-Host "  预期: $Expected" -ForegroundColor Yellow
    $script:fail++
  }
}

Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) 前置环境检查"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

# ==================== 1. 中间件可用性检查 ====================
Write-Host "━━━ 1. 中间件可用性检查 ━━━"

# 1.1 Nacos 检查
Check -Desc "Nacos 服务 ($NacosAddr)" -Expected "返回 Nacos 页面 HTML 或 JSON" -Cmd {
  $resp = Invoke-WebRequest -Uri "http://$NacosAddr/nacos/" -TimeoutSec 5 -UseBasicParsing
  if ($resp.Content -match "Nacos") { return $true } else { throw "未返回 Nacos 内容" }
}

# 1.2 MariaDB 检查
Check -Desc "MariaDB 数据库 ($DbHost`:$DbPort)" -Expected "返回 1" -Cmd {
  # 使用 .NET MySQL 连接检查
  $connStr = "Server=$DbHost;Port=$DbPort;Database=mysql;User ID=$DbUser;Password=$DbPassword;"
  $conn = New-Object System.Data.Common.DbProviderFactory
  # Fallback: try using mysql command line if available
  $result = mariadb -h $DbHost -P $DbPort -u $DbUser -p"$DbPassword" -e "SELECT 1" 2>&1
  if ($LASTEXITCODE -eq 0) { return $true } else { throw "数据库连接失败" }
}

# 1.3 Redis 检查
Check -Desc "Redis 缓存 ($RedisHost`:$RedisPort)" -Expected "返回 PONG" -Cmd {
  $result = redis-cli -h $RedisHost -p $RedisPort ping 2>&1
  if ($result -eq "PONG") { return $true } else { throw "Redis 连接失败" }
}

# ==================== 2. 开发环境检查 ====================
Write-Host ""
Write-Host "━━━ 2. 开发环境检查 ━━━"

Check -Desc "JDK 21 已安装" -Expected "java -version 输出包含 'openjdk version 21'" -Cmd {
  $v = java -version 2>&1
  if ($v -match 'openjdk version "21') { return $true } else { throw "JDK 版本不匹配" }
}

Check -Desc "Maven 3.9+ 已安装" -Expected "mvn -version 输出版本号" -Cmd {
  $v = mvn -version 2>&1
  if ($v -match 'Apache Maven 3\.9') { return $true } else { throw "Maven 版本不匹配" }
}

Check -Desc "Git 已安装" -Expected "git version 输出版本号" -Cmd {
  $v = git version 2>&1
  if ($v -match 'git version') { return $true } else { throw "Git 未安装" }
}

Check -Desc "JAVA_HOME 环境变量已设置" -Expected "JAVA_HOME 指向 JDK 21 安装目录" -Cmd {
  if ($env:JAVA_HOME -and (Test-Path $env:JAVA_HOME)) { return $true } else { throw "JAVA_HOME 未设置" }
}

# ==================== 3. 网络连通性检查 ====================
Write-Host ""
Write-Host "━━━ 3. 网络连通性检查 ━━━"

Check -Desc "Nacos 端口 $NacosAddr 可达" -Expected "HTTP 返回非空响应" -Cmd {
  $resp = Invoke-WebRequest -Uri "http://$NacosAddr/nacos/" -TimeoutSec 5 -UseBasicParsing
  if ($resp.Content.Length -gt 0) { return $true } else { throw "响应为空" }
}

# ==================== 4. 项目代码检查 ====================
Write-Host ""
Write-Host "━━━ 4. 项目代码检查 ━━━"

Check -Desc "项目代码已就绪" -Expected "pom.xml 文件存在" -Cmd {
  if (Test-Path "pom.xml") { return $true } else { throw "pom.xml 不存在" }
}

Check -Desc "SQL 初始化脚本存在" -Expected "scripts/sql/ 目录下存在 SQL 文件" -Cmd {
  $f1 = Test-Path "scripts/sql/auth-init-v0.1.5.sql"
  $f2 = Test-Path "scripts/sql/auth-init-v0.1.6.sql"
  if ($f1 -and $f2) { return $true } else { throw "SQL 文件缺失" }
}

# ==================== 汇总 ====================
Write-Host ""
Write-Host "=============================================="
Write-Host "  检查完成: $pass 项通过, $fail 项失败" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })
Write-Host "=============================================="

if ($fail -gt 0) {
  Write-Host "`n请解决上述失败的检查项后重新运行此脚本。" -ForegroundColor Red
  exit 1
} else {
  Write-Host "`n所有检查通过！可以继续进行部署。" -ForegroundColor Green
  exit 0
}
