#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-rsa-keygen.sh - RSA 密钥对生成脚本 (Bash)
# 版本: v0.2.7
#
# 功能（F-011 / ADR-015 / ADR-016）：
#   1. 生成 RSA 2048 位密钥对，输出 DER 编码单行 Base64；
#   2. 契约：公钥 = X.509 SubjectPublicKeyInfo DER 单行 Base64；私钥 = PKCS#8 PrivateKeyInfo DER 单行 Base64，
#      无 -----BEGIN/END----- 头尾标记、无换行符，与 Java 端 Base64.getDecoder() +
#      X509EncodedKeySpec / PKCS8EncodedKeySpec 解码契约严格一致（与 deploy-rsa-keygen.ps1 双平台对齐）；
#   3. 契约自校验：无 PEM 头尾、无换行、严格 Base64 可解码、DER 结构偏移、公钥私钥成对；
#   4. 输出脱敏：完整私钥值绝不打印（NFR-004 敏感信息红线），仅显示前 24 字符前缀；
#   5. 输出分级（通过/失败）与退出码约定（F-011）：全部通过退出 0，失败退出非零（1）。
#
# 用法: ./deploy/scripts/deploy-rsa-keygen.sh [输出目录]
#       默认输出到 deploy 目录下的 keys/ 文件夹
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${1:-$PROJECT_DIR/keys}"
mkdir -p "$OUTPUT_DIR"

# 输出文件清单（与 deploy-rsa-keygen.ps1 完全一致，共 6 个文件）
PRIVATE_KEY_FILE="$OUTPUT_DIR/private_key.pem"            # PEM 私钥（仅运维审计用，不做注入 Base64）
PUBLIC_KEY_FILE="$OUTPUT_DIR/public_key.pem"              # PEM 公钥（仅运维审计用）
PRIVATE_KEY_DER_FILE="$OUTPUT_DIR/private_key.der"        # DER 私钥（PKCS#8 PrivateKeyInfo，Java 契约字节来源）
PUBLIC_KEY_DER_FILE="$OUTPUT_DIR/public_key.der"          # DER 公钥（X.509 SubjectPublicKeyInfo）
PRIVATE_KEY_B64_FILE="$OUTPUT_DIR/private_key_base64.txt" # 单行 Base64 私钥（env.json 注入值来源）
PUBLIC_KEY_B64_FILE="$OUTPUT_DIR/public_key_base64.txt"   # 单行 Base64 公钥

# ========== 输出分级与失败处理辅助（F-011：通过/失败，双平台一致不用 emoji） ==========
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASS=0; FAIL=0

# 输出「通过/失败」结果并累计计数
print_result() {
  local status="$1" message="$2"
  case "$status" in
    通过) echo -e "  ${GREEN}[通过]${NC} $message"; PASS=$((PASS + 1)) ;;
    失败) echo -e "  ${RED}[失败]${NC} $message"; FAIL=$((FAIL + 1)) ;;
  esac
}

# 契约校验失败：输出失败分级并退出非零（F-011 退出码约定）
fail_exit() {
  print_result "失败" "$1"
  echo "  退出码: 1"
  exit 1
}

echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) RSA 密钥对生成"
echo "  版本: v0.2.7"
echo "  输出目录: $OUTPUT_DIR"
echo "  输出契约: DER 编码单行 Base64（无 PEM 头尾、无换行）"
echo "=============================================="
echo ""

# ========== 0. OpenSSL 可用性预检（在生成链路之前执行，失败退出非零） ==========
if ! command -v openssl >/dev/null 2>&1; then
  fail_exit "未找到 OpenSSL。请先安装 OpenSSL 后重试。"
fi
echo "  OpenSSL: $(openssl version)"

# 单行 Base64 编码工具探测：GNU base64 -w0 优先；macOS/BSD 回退 openssl base64 -A
# （-A 输出不含换行；BSD base64 的 -w0 行为不保证，探测以「编码输出不含换行」为判定标准。
#  换行检测必须用 bash 原生模式匹配 [[ ]]，不能依赖 grep——grep 按行处理输入，
#  模式中的换行符会被拆分为空模式从而误匹配任何输入）
USE_GNU_BASE64=1
if ! printf 'test' | base64 -w0 >/dev/null 2>&1; then
  USE_GNU_BASE64=0
elif [[ "$(printf 'test' | base64 -w0 2>/dev/null)" == *$'\n'* ]]; then
  # base64 -w0 输出仍含换行（BSD 兼容差异），回退 openssl base64 -A
  USE_GNU_BASE64=0
fi
if [ "$USE_GNU_BASE64" -eq 0 ] && ! printf 'test' | openssl base64 -A >/dev/null 2>&1; then
  fail_exit "未找到可用的单行 Base64 编码工具（需要 base64 -w0 或 openssl base64 -A）"
fi

# 单行 Base64 编码（输入文件 -> 单行 Base64；命令替换自动剥离尾部换行，保证契约单行）
b64_encode_file() {
  if [ "$USE_GNU_BASE64" -eq 1 ]; then base64 -w0 "$1"; else openssl base64 -A -in "$1"; fi
}

# 单行 Base64 编码（stdin -> 单行 Base64）
b64_encode_stdin() {
  if [ "$USE_GNU_BASE64" -eq 1 ]; then base64 -w0; else openssl base64 -A; fi
}

# 严格 Base64 解码校验（与 Java Base64.getDecoder() 等价：拒绝换行与非法字符）
b64_decode_ok() {
  if [ "$USE_GNU_BASE64" -eq 1 ]; then
    printf '%s' "$1" | base64 -d >/dev/null 2>&1
  else
    printf '%s' "$1" | openssl base64 -d -A >/dev/null 2>&1
  fi
}

# 取 DER 文件第 $2 个字节（0 起）的十进制值（od 为 POSIX 命令，Linux/macOS 均支持）
byte_at() {
  od -An -j "$2" -N 1 -t u1 "$1" | tr -d ' \n'
}

# ========== 1. 生成 RSA 2048 位私钥（PEM 审计副本） ==========
echo ""
echo "━━━ [1/4] 生成 RSA 2048 位私钥 ━━━"
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out "$PRIVATE_KEY_FILE" 2>/dev/null
print_result "通过" "已生成 PEM 私钥（审计用）: $PRIVATE_KEY_FILE"

# ========== 2. 提取公钥 PEM + 转换 DER（私钥 PKCS#8 / 公钥 X.509） ==========
echo ""
echo "━━━ [2/4] 提取公钥并转换为 DER 二进制 ━━━"
openssl pkey -in "$PRIVATE_KEY_FILE" -pubout -outform PEM -out "$PUBLIC_KEY_FILE" 2>/dev/null
print_result "通过" "已生成 PEM 公钥（审计用）: $PUBLIC_KEY_FILE"
# 注意：openssl pkey -outform DER 在部分发行版（如 Git for Windows 自带 OpenSSL 3.x）默认输出传统 PKCS#1 格式，
# 与 Java 端 PKCS8EncodedKeySpec 解码契约不兼容（报 algid parse error, not a sequence）；
# 必须用 openssl pkcs8 -topk8 -nocrypt 显式输出 PKCS#8 PrivateKeyInfo（与 .ps1 链路一致）。
openssl pkcs8 -topk8 -nocrypt -in "$PRIVATE_KEY_FILE" -outform DER -out "$PRIVATE_KEY_DER_FILE" 2>/dev/null
print_result "通过" "已生成 DER 私钥（PKCS#8 PrivateKeyInfo）: $PRIVATE_KEY_DER_FILE"
openssl pkey -in "$PRIVATE_KEY_FILE" -pubout -outform DER -out "$PUBLIC_KEY_DER_FILE" 2>/dev/null
print_result "通过" "已生成 DER 公钥（X.509 SubjectPublicKeyInfo）: $PUBLIC_KEY_DER_FILE"

# ========== 3. DER -> 单行 Base64（作用于 .der 文件而非 .pem，修复 P3 契约错误） ==========
echo ""
echo "━━━ [3/4] DER 二进制转单行 Base64 ━━━"
PRIVATE_KEY_B64="$(b64_encode_file "$PRIVATE_KEY_DER_FILE")"
PUBLIC_KEY_B64="$(b64_encode_file "$PUBLIC_KEY_DER_FILE")"
# 写入 *_base64.txt：printf '%s' 不追加换行，保持单行契约（对齐 .ps1 的 WriteAllText）
printf '%s' "$PRIVATE_KEY_B64" > "$PRIVATE_KEY_B64_FILE"
printf '%s' "$PUBLIC_KEY_B64" > "$PUBLIC_KEY_B64_FILE"
print_result "通过" "已生成: $PRIVATE_KEY_B64_FILE"
print_result "通过" "已生成: $PUBLIC_KEY_B64_FILE"

# ========== 4. 契约自校验（与 .ps1 四道校验同标准 + 成对性校验） ==========
echo ""
echo "━━━ [4/4] 契约自校验 ━━━"

# 校验 1：无 PEM 头尾标记
if printf '%s' "$PRIVATE_KEY_B64" | grep -Eq -- '-----BEGIN|-----END'; then
  fail_exit "私钥格式错误: 包含 PEM 头尾标记，不符合 DER 单行 Base64 契约"
fi
if printf '%s' "$PUBLIC_KEY_B64" | grep -Eq -- '-----BEGIN|-----END'; then
  fail_exit "公钥格式错误: 包含 PEM 头尾标记，不符合 DER 单行 Base64 契约"
fi

# 校验 2：无换行（bash 原生模式匹配检测 \r/\n；GNU base64 -d 默认接受换行，
# 不能单独作为无换行证明，必须单独检查；grep 按行处理无法检测换行，故用 [[ ]]）
if [[ "$PRIVATE_KEY_B64" == *$'\r'* || "$PRIVATE_KEY_B64" == *$'\n'* ]]; then
  fail_exit "私钥格式错误: 包含换行符，必须为单行 Base64"
fi
if [[ "$PUBLIC_KEY_B64" == *$'\r'* || "$PUBLIC_KEY_B64" == *$'\n'* ]]; then
  fail_exit "公钥格式错误: 包含换行符，必须为单行 Base64"
fi

# 校验 3：严格 Base64 解码（正则字符集预检 + 长度 4 倍数 + 实际解码，与 Java Base64.getDecoder() 等价）
for b64 in "$PRIVATE_KEY_B64" "$PUBLIC_KEY_B64"; do
  if ! printf '%s' "$b64" | grep -Eq '^[A-Za-z0-9+/]+={0,2}$'; then
    fail_exit "密钥格式错误: 包含非法 Base64 字符，与 Java Base64.getDecoder() 严格解码契约不符"
  fi
  if [ $(( ${#b64} % 4 )) -ne 0 ]; then
    fail_exit "密钥格式错误: Base64 长度非 4 的倍数，与 Java Base64.getDecoder() 严格解码契约不符"
  fi
  if ! b64_decode_ok "$b64"; then
    fail_exit "密钥格式错误: 严格 Base64 解码失败（与 Java Base64.getDecoder() 等价校验）"
  fi
done

# 校验 4：DER 结构偏移（私钥 PKCS#8 [0]=0x30/[7]=0x30 且长度>=16；公钥 X.509 [0]=0x30/[4]=0x30/[19]=0x03 且长度>=24）
PRIV_DER_LEN="$(wc -c < "$PRIVATE_KEY_DER_FILE")"
PUB_DER_LEN="$(wc -c < "$PUBLIC_KEY_DER_FILE")"
PRIV_B0="$(byte_at "$PRIVATE_KEY_DER_FILE" 0)"; PRIV_B7="$(byte_at "$PRIVATE_KEY_DER_FILE" 7)"
PUB_B0="$(byte_at "$PUBLIC_KEY_DER_FILE" 0)";  PUB_B4="$(byte_at "$PUBLIC_KEY_DER_FILE" 4)"; PUB_B19="$(byte_at "$PUBLIC_KEY_DER_FILE" 19)"
if [ -z "$PRIV_B0" ] || [ -z "$PRIV_B7" ] || [ "$PRIV_DER_LEN" -lt 16 ] || [ "$PRIV_B0" != "48" ] || [ "$PRIV_B7" != "48" ]; then
  fail_exit "私钥格式错误: 非 PKCS#8 PrivateKeyInfo 结构（可能为 PKCS#1），不符合 Java PKCS8EncodedKeySpec 解码契约"
fi
if [ -z "$PUB_B0" ] || [ -z "$PUB_B4" ] || [ -z "$PUB_B19" ] || [ "$PUB_DER_LEN" -lt 24 ] || [ "$PUB_B0" != "48" ] || [ "$PUB_B4" != "48" ] || [ "$PUB_B19" != "3" ]; then
  fail_exit "公钥格式错误: 非 X.509 SubjectPublicKeyInfo 结构，不符合 Java X509EncodedKeySpec 解码契约"
fi

# 校验 5：公钥私钥成对（从私钥 DER 派生公钥 DER 与 public_key.der 比对；与 auth RsaKeyConfig validateKeyPair 配对语义一致）
DERIVED_PUB_B64="$(openssl pkey -in "$PRIVATE_KEY_DER_FILE" -inform DER -pubout -outform DER 2>/dev/null | b64_encode_stdin)"
if [ "$DERIVED_PUB_B64" != "$PUBLIC_KEY_B64" ]; then
  fail_exit "密钥对错误: 公钥与私钥不成对（私钥派生公钥与 public_key.der 不一致）"
fi

print_result "通过" "契约自校验通过: 无 PEM 头尾、无换行、严格 Base64 解码成功、DER 结构为 PKCS#8/X.509、公私钥成对"
echo "  私钥 Base64 长度: ${#PRIVATE_KEY_B64} 字符"
echo "  公钥 Base64 长度: ${#PUBLIC_KEY_B64} 字符"

# ========== 5. 输出脱敏提示（NFR-004：完整私钥绝不打印，仅前 24 字符前缀） ==========
echo ""
echo "=============================================="
echo "  生成完成！"
echo "=============================================="
echo ""
echo "env.json 配置（完整值请从 *_base64.txt 拷贝，此处仅显示前 24 字符前缀，敏感信息不打印明文）："
echo ""
echo "  \"RSA_PRIVATE_KEY\": \"${PRIVATE_KEY_B64:0:24}...\"（完整值见 private_key_base64.txt）"
echo "  \"RSA_PUBLIC_KEY\": \"${PUBLIC_KEY_B64:0:24}...\"（完整值见 public_key_base64.txt）"
echo ""
echo "  契约说明: 值为 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo），"
echo "  无 -----BEGIN/END----- 头尾标记、无换行符，与 Java 端 Base64.getDecoder() + X509/PKCS8EncodedKeySpec 严格一致。"
echo ""

# ========== 6. 汇总与退出码（F-011：全部通过退出 0，失败退出 1） ==========
echo -e "  结果汇总: ${GREEN}通过 $PASS 项${NC} | ${RED}失败 $FAIL 项${NC}"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
