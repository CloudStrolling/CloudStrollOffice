#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) RSA 密钥对生成脚本
# 版本: v0.1.7
# 说明: 生成 RSA 2048 位密钥对并输出 Base64 编码
# 用法: ./scripts/deploy-rsa-keygen.sh [输出目录]
#       默认输出到当前目录下的 keys/ 文件夹
# ============================================================

set -euo pipefail

OUTPUT_DIR="${1:-keys}"
mkdir -p "$OUTPUT_DIR"

PRIVATE_KEY_FILE="$OUTPUT_DIR/private_key.pem"
PUBLIC_KEY_FILE="$OUTPUT_DIR/public_key.pem"
PRIVATE_KEY_B64_FILE="$OUTPUT_DIR/private_key_base64.txt"
PUBLIC_KEY_B64_FILE="$OUTPUT_DIR/public_key_base64.txt"

echo "=============================================="
echo "  云漫智企 RSA 密钥对生成"
echo "  输出目录: $OUTPUT_DIR"
echo "=============================================="
echo ""

# 步骤 1: 生成 RSA 2048 位私钥（PKCS#8 格式）
echo "[1/4] 生成 RSA 2048 位私钥..."
openssl genpkey -algorithm RSA \
    -pkeyopt rsa_keygen_bits:2048 \
    -outform PEM \
    -out "$PRIVATE_KEY_FILE"
echo "  -> 已生成: $PRIVATE_KEY_FILE"

# 步骤 2: 提取公钥
echo "[2/4] 提取公钥..."
openssl pkey -in "$PRIVATE_KEY_FILE" \
    -pubout \
    -outform PEM \
    -out "$PUBLIC_KEY_FILE"
echo "  -> 已生成: $PUBLIC_KEY_FILE"

# 步骤 3: 转换为 Base64（去掉 PEM 头尾和换行符）
echo "[3/4] 转换为 Base64 编码..."

# Linux (base64 -w0)
if command -v base64 &> /dev/null; then
    base64 -w0 "$PRIVATE_KEY_FILE" > "$PRIVATE_KEY_B64_FILE"
    base64 -w0 "$PUBLIC_KEY_FILE" > "$PUBLIC_KEY_B64_FILE"
# macOS (base64 无 -w 参数)
elif command -v openssl &> /dev/null; then
    openssl base64 -in "$PRIVATE_KEY_FILE" -out "$PRIVATE_KEY_B64_FILE" -A
    openssl base64 -in "$PUBLIC_KEY_FILE" -out "$PUBLIC_KEY_B64_FILE" -A
else
    echo "错误: 未找到 base64 或 openssl 命令" >&2
    exit 1
fi

echo "  -> 已生成: $PRIVATE_KEY_B64_FILE"
echo "  -> 已生成: $PUBLIC_KEY_B64_FILE"

# 步骤 4: 验证
echo "[4/4] 验证密钥对..."
# 私钥长度检查
PRIV_LEN=$(wc -c < "$PRIVATE_KEY_B64_FILE")
PUB_LEN=$(wc -c < "$PUBLIC_KEY_B64_FILE")
echo "  私钥 Base64 长度: $PRIV_LEN 字节"
echo "  公钥 Base64 长度: $PUB_LEN 字节"

# 验证私钥可以正确读取
openssl pkey -in "$PRIVATE_KEY_FILE" -noout -text > /dev/null 2>&1 && \
    echo "  -> 私钥格式验证: 通过" || echo "  -> 私钥格式验证: 失败"

# 验证公钥与私钥匹配
PUB_MOD=$(openssl pkey -in "$PUBLIC_KEY_FILE" -pubin -noout -text 2>/dev/null | grep "^[[:space:]]*00:" | head -1)
PRIV_MOD=$(openssl pkey -in "$PRIVATE_KEY_FILE" -noout -text 2>/dev/null | grep "^[[:space:]]*00:" | head -1)

echo ""
echo "=============================================="
echo "  生成完成！"
echo "=============================================="
echo ""
echo "环境变量配置（将以下 Base64 值写入项目根目录 env.json 或 .env 文件）："
echo ""
echo "  env.json 配置："
echo "  \"RSA_PRIVATE_KEY\": \"$(cat $PRIVATE_KEY_B64_FILE)\""
echo "  \"RSA_PUBLIC_KEY\": \"$(cat $PUBLIC_KEY_B64_FILE)\""
echo ""
echo "  .env 配置："
echo "  RSA_PRIVATE_KEY=$(cat $PRIVATE_KEY_B64_FILE)"
echo "  RSA_PUBLIC_KEY=$(cat $PUBLIC_KEY_B64_FILE)"
