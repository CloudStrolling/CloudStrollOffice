#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) Gateway 服务启动脚本
# 版本: v0.1.7
# 说明: 自动注入环境变量并启动 API 网关服务
# 前置条件: 已执行 source scripts/deploy-env-local.sh
# 用法: ./scripts/deploy-start-gateway.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$PROJECT_DIR/cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar"

# ========== 从 env.json 加载环境变量 ==========
source "$SCRIPT_DIR/load-env.sh"

# ========== 检查必要变量 ==========
if [ -z "${NACOS_ADDR:-}" ]; then
  echo "❌ 错误: NACOS_ADDR 未设置。请先配置项目根目录下的 env.json 文件"
  exit 1
fi

if [ -z "${RSA_PUBLIC_KEY:-}" ]; then
  echo "❌ 错误: RSA_PUBLIC_KEY 未设置。请先生成 RSA 密钥对并配置到 env.json："
  echo "   ./scripts/deploy-rsa-keygen.sh"
  exit 1
fi

if [ ! -f "$JAR_PATH" ]; then
  echo "❌ 错误: JAR 包不存在: $JAR_PATH"
  echo "   请先执行: mvn clean package -pl cloudoffice-gateway -am -DskipTests"
  exit 1
fi

# ========== 显示配置信息 ==========
echo "=============================================="
echo "  云漫智企 - Gateway 服务启动"
echo "=============================================="
echo "  JAR 包:        $JAR_PATH"
echo "  Nacos 地址:    ${NACOS_ADDR:-未设置}"
echo "  Redis 主机:    ${REDIS_HOST:-127.0.0.1}:${REDIS_PORT:-6379}"
echo "  公钥已配置:    $(if [ -n "${RSA_PUBLIC_KEY:-}" ]; then echo '是'; else echo '否'; fi)"
echo "=============================================="
echo ""

# ========== 启动服务 ==========
# Gateway 所需环境变量：
# - NACOS_ADDR:      Nacos 服务地址（来源：bootstrap.yml）
# - REDIS_HOST:      Redis 主机地址（来源：application.yml）
# - REDIS_PORT:      Redis 端口（来源：application.yml）
# - REDIS_PASSWORD:  Redis 密码（来源：application.yml）
# - REDIS_DATABASE:  Redis 数据库编号（来源：application.yml）
# - RSA_PUBLIC_KEY:  RSA 公钥（来源：application.yml，用于 Token 验签）
echo "🚀 启动 Gateway 服务..."
echo ""

exec java \
  -Xms256m -Xmx512m \
  -jar "$JAR_PATH"
