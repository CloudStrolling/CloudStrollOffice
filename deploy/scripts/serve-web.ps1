# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) Web 客户端一键启动脚本 (Windows)
.DESCRIPTION
  使用 Python 内置 http.server 将 deploy/cloudoffice-flutter-app/web 作为静态站点启动：
    1. 前置校验：python 命令可用 + 站点目录存在
    2. 端口来源：-Port 参数 > env.json 的 WEB_SERVER_PORT > 默认 8080
    3. 前台运行：python -m http.server <port> --bind 127.0.0.1 --directory <web目录>
       Ctrl+C 停止（前台模式便于调试，日志实时输出到当前终端）
  端口默认 8080（避开 gateway 9000 / auth 9100 / biz 9200 / system 9400）。
  退出码约定（F-011）：前置校验失败退出 1；服务被 Ctrl+C 中断退出 0。
  版本: v0.2.7
.EXAMPLE
  .\deploy\scripts\serve-web.ps1
  .\deploy\scripts\serve-web.ps1 -Port 9090
#>
param(
  [int]$Port = 0   # 站点端口（0 表示从 env.json 的 WEB_SERVER_PORT 读取，缺省再回退 8080）
)

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 兜底退出） ==========
$ProjectDir = Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\load-env.ps1"

# ========== 1. 解析端口（参数 > WEB_SERVER_PORT > 默认 8080） ==========
if ($Port -le 0) { $Port = [int]($env:WEB_SERVER_PORT -replace '\D', '') }
if ($Port -le 0) { $Port = 8080 }

# ========== 2. 前置校验（python 命令 / 站点目录） ==========
Write-Host ""
Write-Host "=============================================="
Write-Host "  云漫智企 (CloudStrollOffice) Web 客户端一键启动"
Write-Host "  日期: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=============================================="
Write-Host ""

$fail = $false
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Host "  [失败] 未找到 python 命令，请安装 Python 3.8+ 并配置 PATH" -ForegroundColor Red
  $fail = $true
}

$WebDir = Join-Path $ProjectDir "cloudoffice-flutter-app\web"
if (-not (Test-Path -LiteralPath $WebDir)) {
  Write-Host "  [失败] 站点目录不存在: $WebDir（请先执行 build-client 构建客户端产物）" -ForegroundColor Red
  $fail = $true
}

if ($fail) {
  Write-Host ""
  Write-Host "  前置校验未通过，请按上述缺失项处理后重新运行。" -ForegroundColor Red
  exit 1
}
Write-Host "  [通过] 前置校验：python 命令可用 + 站点目录存在" -ForegroundColor Green

# ========== 3. 启动静态站点（前台运行，Ctrl+C 停止） ==========
Write-Host ""
Write-Host "  启动静态站点: http://127.0.0.1:$Port/" -ForegroundColor Cyan
Write-Host "  站点目录: $WebDir" -ForegroundColor Cyan
Write-Host "  按 Ctrl+C 停止服务。" -ForegroundColor Cyan
Write-Host ""

# 工作目录切换到站点目录，前台阻塞运行；bind 127.0.0.1 仅本机访问（如需局域网访问可改 0.0.0.0）
Push-Location $WebDir
try {
  & python -m http.server $Port --bind 127.0.0.1 --directory $WebDir
} finally {
  Pop-Location
}

# http.server 被 Ctrl+C 中断时 $LASTEXITCODE 通常非零，此处归一化为 0（用户主动停止属预期行为）
exit 0
