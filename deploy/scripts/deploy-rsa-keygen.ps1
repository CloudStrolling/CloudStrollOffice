# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
<#
.SYNOPSIS
   云漫智企 (CloudStrollOffice) RSA 密钥对生成脚本 (Windows)
.DESCRIPTION
   生成 RSA 2048 位密钥对，输出 DER 编码单行 Base64
   契约：公钥 = X.509 SubjectPublicKeyInfo DER 单行 Base64；私钥 = PKCS#8 PrivateKeyInfo DER 单行 Base64
        无 -----BEGIN/END----- 头尾标记、无换行符，与 Java 端 Base64.getDecoder() + X509EncodedKeySpec/PKCS8EncodedKeySpec 解码契约严格一致
   版本: v0.2.7
.PARAMETER OutputDir
   输出目录 (默认: deploy\keys)
.EXAMPLE
   .\deploy\scripts\deploy-rsa-keygen.ps1
   .\deploy\scripts\deploy-rsa-keygen.ps1 -OutputDir "C:\CloudStroll\keys"
#>

param(
  [string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "keys")
)

# 确保输出目录存在
if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# PEM 文件（仅运维审计用，不做注入 Base64）
$privateKeyFile = Join-Path $OutputDir "private_key.pem"
$publicKeyFile = Join-Path $OutputDir "public_key.pem"
# DER 二进制文件（Java 端 X509EncodedKeySpec / PKCS8EncodedKeySpec 契约的字节来源）
$privateKeyDerFile = Join-Path $OutputDir "private_key.der"
$publicKeyDerFile = Join-Path $OutputDir "public_key.der"
# 单行 Base64 输出文件（env.json 注入值来源）
$privateKeyB64File = Join-Path $OutputDir "private_key_base64.txt"
$publicKeyB64File = Join-Path $OutputDir "public_key_base64.txt"

Write-Host "=============================================="
Write-Host "  云漫智企 RSA 密钥对生成"
Write-Host "  输出目录: $OutputDir"
Write-Host "  输出契约: DER 编码单行 Base64（无 PEM 头尾、无换行）"
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

# 步骤 1: 生成 RSA 2048 位私钥（PEM 格式 PKCS#8，保留审计副本）
Write-Host "[1/4] 生成 RSA 2048 位私钥..."
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out "$privateKeyFile" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "私钥生成失败" -ForegroundColor Red; exit 1 }
Write-Host "  -> 已生成 PEM 私钥（审计用）: $privateKeyFile"

# 步骤 2: 提取公钥 PEM（审计副本）并转换为 DER 二进制（私钥 PKCS#8 / 公钥 X.509 SubjectPublicKeyInfo）
Write-Host "[2/4] 提取公钥并转换为 DER 二进制..."
openssl pkey -in "$privateKeyFile" -pubout -outform PEM -out "$publicKeyFile" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "公钥提取失败" -ForegroundColor Red; exit 1 }
# 注意：openssl pkey -outform DER 在部分发行版（如 Git for Windows 自带 OpenSSL 3.x）默认输出传统 PKCS#1 格式，
# 与 Java 端 PKCS8EncodedKeySpec 解码契约不兼容（报 algid parse error, not a sequence）；
# 必须用 openssl pkcs8 -topk8 -nocrypt 显式输出 PKCS#8 PrivateKeyInfo。
openssl pkcs8 -topk8 -nocrypt -in "$privateKeyFile" -outform DER -out "$privateKeyDerFile" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "私钥 DER 转换失败" -ForegroundColor Red; exit 1 }
openssl pkey -in "$privateKeyFile" -pubout -outform DER -out "$publicKeyDerFile" 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "公钥 DER 转换失败" -ForegroundColor Red; exit 1 }
Write-Host "  -> 已生成 PEM 公钥（审计用）: $publicKeyFile"
Write-Host "  -> 已生成 DER 私钥: $privateKeyDerFile"
Write-Host "  -> 已生成 DER 公钥: $publicKeyDerFile"

# 步骤 3: DER 二进制 -> 单行 Base64（ToBase64String 单参数重载默认无换行，对齐 Java 严格解码契约）
Write-Host "[3/4] DER 二进制转单行 Base64..."
$privateKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $privateKeyDerFile)))
$publicKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $publicKeyDerFile)))

# 写入 *_base64.txt（WriteAllText 不追加换行，保持单行契约）
[System.IO.File]::WriteAllText((Resolve-Path $OutputDir).Path + "\private_key_base64.txt", $privateKeyBase64)
[System.IO.File]::WriteAllText((Resolve-Path $OutputDir).Path + "\public_key_base64.txt", $publicKeyBase64)

Write-Host "  -> 已生成: $privateKeyB64File"
Write-Host "  -> 已生成: $publicKeyB64File"

# 步骤 4: 契约自校验（无 PEM 头尾、无换行、严格 Base64 可解码）
Write-Host "[4/4] 契约自校验..."
if ($privateKeyBase64 -match '-----BEGIN|-----END') {
  Write-Error "私钥格式错误: 包含 PEM 头尾标记，不符合 DER 单行 Base64 契约"; exit 1
}
if ($publicKeyBase64 -match '-----BEGIN|-----END') {
  Write-Error "公钥格式错误: 包含 PEM 头尾标记，不符合 DER 单行 Base64 契约"; exit 1
}
if ($privateKeyBase64 -match '[\r\n]' -or $publicKeyBase64 -match '[\r\n]') {
  Write-Error "密钥格式错误: 包含换行符，必须为单行 Base64"; exit 1
}
try {
  $null = [Convert]::FromBase64String($privateKeyBase64)
  $null = [Convert]::FromBase64String($publicKeyBase64)
} catch {
  Write-Error "密钥格式错误: 严格 Base64 解码失败（与 Java Base64.getDecoder() 等价校验）"; exit 1
}
# DER 结构契约校验：私钥必须为 PKCS#8 PrivateKeyInfo（偏移 7 处为 AlgorithmIdentifier SEQUENCE 0x30，
# 而非 PKCS#1 的 modulus INTEGER 0x02）；公钥必须为 X.509 SubjectPublicKeyInfo
# （偏移 4 处为 AlgorithmIdentifier SEQUENCE 0x30，偏移 19 处为 BIT STRING 0x03，
#  结构固定：SEQUENCE(30 82) + algId SEQUENCE(30 0D) + OID(06 09 rsaEncryption) + NULL(05 00) + BIT STRING(03)）
$privDerBytes = [Convert]::FromBase64String($privateKeyBase64)
$pubDerBytes  = [Convert]::FromBase64String($publicKeyBase64)
if ($privDerBytes.Length -lt 16 -or $privDerBytes[0] -ne 0x30 -or $privDerBytes[7] -ne 0x30) {
  Write-Error "私钥格式错误: 非 PKCS#8 PrivateKeyInfo 结构（可能为 PKCS#1），不符合 Java PKCS8EncodedKeySpec 解码契约"; exit 1
}
if ($pubDerBytes.Length -lt 24 -or $pubDerBytes[0] -ne 0x30 -or $pubDerBytes[4] -ne 0x30 -or $pubDerBytes[19] -ne 0x03) {
  Write-Error "公钥格式错误: 非 X.509 SubjectPublicKeyInfo 结构，不符合 Java X509EncodedKeySpec 解码契约"; exit 1
}
Write-Host "  私钥 Base64 长度: $($privateKeyBase64.Length) 字符"
Write-Host "  公钥 Base64 长度: $($publicKeyBase64.Length) 字符"
Write-Host "  契约校验通过: 无 PEM 头尾、无换行、严格 Base64 解码成功、DER 结构为 PKCS#8/X.509"

Write-Host ""
Write-Host "=============================================="
Write-Host "  生成完成！"
Write-Host "=============================================="
Write-Host ""

# 输出提示：只打印前 24 字符前缀（脱敏），不打印完整私钥值（敏感信息红线：私钥不得写入日志）
Write-Host "env.json 配置（完整值请从 *_base64.txt 拷贝，此处仅显示前 24 字符前缀）：" -ForegroundColor Green
Write-Host ""
Write-Host ('  "RSA_PRIVATE_KEY": "' + $privateKeyBase64.Substring(0, [Math]::Min(24, $privateKeyBase64.Length)) + '..."（完整值见 private_key_base64.txt）')
Write-Host ('  "RSA_PUBLIC_KEY": "' + $publicKeyBase64.Substring(0, [Math]::Min(24, $publicKeyBase64.Length)) + '..."（完整值见 public_key_base64.txt）')
Write-Host ""
Write-Host "  契约说明: 值为 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo），"
Write-Host "  无 -----BEGIN/END----- 头尾标记、无换行符，与 Java 端 Base64.getDecoder() + X509/PKCS8EncodedKeySpec 严格一致。"
