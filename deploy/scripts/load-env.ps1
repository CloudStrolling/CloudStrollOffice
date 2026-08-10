# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# load-env.ps1 - 统一配置加载模块 (PowerShell)
#
# 功能（F-001 契约）：
#   1. 从 deploy/env.json 读取全部键值对并注入当前会话环境变量；
#   2. env.json 缺失时提示复制 deploy/env.example.json 为 env.json 并填写配置，退出非零；
#   3. 关键配置缺失时逐个列出缺失项（仅键名，不打印值），退出非零；
#   4. 脚本内不硬编码环境地址与凭据（全部经环境变量引用）。
#
# 用法：
#   . .\deploy\scripts\load-env.ps1 [-EnvFile env.json]
#   说明：以 dot-source 方式调用，加载后的环境变量在当前会话生效。
#
# 安全约定：DB_PASSWORD / RSA_PRIVATE_KEY 等敏感值仅注入会话环境变量，
#           任何输出均不打印其明文（缺失校验仅输出键名）。
# ============================================================

param(
  [string]$EnvFile = "env.json"
)

# 项目配置目录为 deploy（脚本位于 deploy/scripts），统一从 deploy/env.json 读取
$ProjectDir = Split-Path -Parent $PSScriptRoot
$EnvFilePath = Join-Path $ProjectDir $EnvFile
$ExampleFilePath = Join-Path $ProjectDir "env.example.json"

# env.json 缺失：提示复制模板并填写配置，非零退出
if (-not (Test-Path $EnvFilePath)) {
  Write-Error "环境配置文件不存在: $EnvFilePath"
  Write-Error "请复制 $ExampleFilePath 为 $EnvFilePath 并填写配置后重试。"
  exit 1
}

try {
  $json = Get-Content -Raw -Encoding UTF8 $EnvFilePath | ConvertFrom-Json
  # S-05 修复：键名合法性白名单校验（仅允许 [A-Za-z_][A-Za-z0-9_]*），
  # 非法键名逐个列出并退出（env.json 为运维本地受控文件，非法键名属配置错误）
  $invalidKeys = @($json.PSObject.Properties | Where-Object { $_.Name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$' } | ForEach-Object { $_.Name })
  if ($invalidKeys.Count -gt 0) {
    Write-Error "$EnvFilePath 含非法键名（仅允许字母/数字/下划线，首字符须为字母或下划线）："
    foreach ($key in $invalidKeys) { Write-Error "  - $key" }
    exit 1
  }
  $json.PSObject.Properties | ForEach-Object {
    # 将键值对注入当前会话环境变量；值为字符串原样注入，不打印敏感值
    Set-Item -Path "env:$($_.Name)" -Value $_.Value
  }
} catch {
  Write-Error "解析 $EnvFilePath 失败: $_"
  Write-Error "请检查文件是否为合法 JSON，必要时复制 $ExampleFilePath 重新填写。"
  exit 1
}

# 关键配置校验（F-001 业务规则下限 8 项）：缺失项逐个列出键名，不打印值
$requiredKeys = @(
  "NACOS_ADDR",
  "NACOS_HOME",
  "DB_HOST",
  "DB_PORT",
  "DB_USERNAME",
  "DB_PASSWORD",
  "REDIS_HOST",
  "REDIS_PORT"
)
$missingKeys = @()
foreach ($key in $requiredKeys) {
  $value = (Get-Item -Path "Env:$key" -ErrorAction SilentlyContinue).Value
  if ([string]::IsNullOrEmpty($value)) {
    $missingKeys += $key
  }
}
if ($missingKeys.Count -gt 0) {
  Write-Error "以下关键配置缺失或为空（请检查 $EnvFilePath，必要时复制 $ExampleFilePath 填写配置）："
  foreach ($key in $missingKeys) {
    Write-Error "  - $key"
  }
  exit 1
}

# 加载成功：仅输出文件路径与键值对数量，不打印任何敏感值
# 注意：PS 5.1 成员枚举特性下 Properties.Count 会逐元素取 Count（返回 8 个 1 的数组），必须显式数组化
$count = @($json.PSObject.Properties).Count
Write-Host "环境变量已从 $EnvFilePath 加载，共 $count 项" -ForegroundColor Green
