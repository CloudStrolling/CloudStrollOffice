<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) RSA 密钥对生成脚本 (Windows)
.DESCRIPTION
  生成 RSA 2048 位密钥对并输出 Base64 编码
.PARAMETER OutputDir
  输出目录 (默认: keys)
.EXAMPLE
  .\scripts\deploy-rsa-keygen.ps1
  .\scripts\deploy-rsa-keygen.ps1 -OutputDir "C:\CloudStroll\keys"
#>

param(
  [string]$OutputDir = "keys"
)

# 确保输出目录存在
if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$privateKeyFile = Join-Path $OutputDir "private_key.pem"
$publicKeyFile = Join-Path $OutputDir "public_key.pem"
$privateKeyB64File = Join-Path $OutputDir "private_key_base64.txt"
$publicKeyB64File = Join-Path $OutputDir "public_key_base64.txt"

Write-Host "=============================================="
Write-Host "  云漫智企 RSA 密钥对生成"
Write-Host "  输出目录: $OutputDir"
Write-Host "=============================================="
Write-Host ""

# 检查 OpenSSL 是否可用
$opensslAvailable = $false
try {
  $null = openssl version 2>&1
  $opensslAvailable = $true
} catch {
  Write-Host "错误: 未找到 OpenSSL。请先安装 OpenSSL。" -ForegroundColor Red
  Write-Host "  下载地址: http://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Yellow
  exit 1
}

# 步骤 1: 生成 RSA 2048 位私钥（PKCS#8 格式）
Write-Host "[1/4] 生成 RSA 2048 位私钥..."
openssl genpkey -algorithm RSA `
  -pkeyopt rsa_keygen_bits:2048 `
  -outform PEM `
  -out "$privateKeyFile" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "私钥生成失败" -ForegroundColor Red; exit 1 }
Write-Host "  -> 已生成: $privateKeyFile"

# 步骤 2: 提取公钥
Write-Host "[2/4] 提取公钥..."
openssl pkey -in "$privateKeyFile" `
  -pubout `
  -outform PEM `
  -out "$publicKeyFile" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Host "公钥提取失败" -ForegroundColor Red; exit 1 }
Write-Host "  -> 已生成: $publicKeyFile"

# 步骤 3: 转换为 Base64
Write-Host "[3/4] 转换为 Base64 编码..."
$privateKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $privateKeyFile)))
$publicKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $publicKeyFile)))

[System.IO.File]::WriteAllText((Resolve-Path $OutputDir).Path + "\private_key_base64.txt", $privateKeyBase64)
[System.IO.File]::WriteAllText((Resolve-Path $OutputDir).Path + "\public_key_base64.txt", $publicKeyBase64)

Write-Host "  -> 已生成: $privateKeyB64File"
Write-Host "  -> 已生成: $publicKeyB64File"

# 步骤 4: 验证
Write-Host "[4/4] 验证密钥对..."
$privLen = $privateKeyBase64.Length
$pubLen = $publicKeyBase64.Length
Write-Host "  私钥 Base64 长度: $privLen 字符"
Write-Host "  公钥 Base64 长度: $pubLen 字符"

Write-Host ""
Write-Host "=============================================="
Write-Host "  生成完成！"
Write-Host "=============================================="
Write-Host ""

Write-Host "环境变量设置（将以下 Base64 值分别设置为环境变量）：" -ForegroundColor Green
Write-Host ""
Write-Host '$env:RSA_PRIVATE_KEY = "'$privateKeyBase64'"'
Write-Host '$env:RSA_PUBLIC_KEY = "'$publicKeyBase64'"'
Write-Host ""

Write-Host "===== .env 文件片段（可复制到 .env 文件中）====="
Write-Host "RSA_PRIVATE_KEY=$privateKeyBase64"
Write-Host "RSA_PUBLIC_KEY=$publicKeyBase64"
