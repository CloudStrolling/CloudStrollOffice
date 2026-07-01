<#
.SYNOPSIS
   从 env.json 加载环境变量 (PowerShell)
.DESCRIPTION
   读取项目根目录的 env.json 文件，将每个键值对设置为当前会话的环境变量
   支持从 json/yaml/yml 文件读取
.PARAMETER EnvFile
   环境配置文件路径，相对于项目根目录 (默认: env.json)
.EXAMPLE
   . .\scripts\load-env.ps1
   . .\scripts\load-env.ps1 -EnvFile env.json
#>

param(
  [string]$EnvFile = "env.json"
)

$ProjectDir = Split-Path -Parent $PSScriptRoot
$EnvFilePath = Join-Path $ProjectDir $EnvFile

if (-not (Test-Path $EnvFilePath)) {
  Write-Error "环境配置文件不存在: $EnvFilePath"
  exit 1
}

try {
  $json = Get-Content -Raw -Encoding UTF8 $EnvFilePath | ConvertFrom-Json
  $json.PSObject.Properties | ForEach-Object {
    Set-Item -Path "env:$($_.Name)" -Value $_.Value
  }
  Write-Host "环境变量已从 $EnvFilePath 加载" -ForegroundColor Green
} catch {
  Write-Error "解析 $EnvFilePath 失败: $_"
  exit 1
}
