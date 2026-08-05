#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) Auth Service 启动脚本
# 版本: v0.1.7
# 说明: 自动注入环境变量并启动认证服务
# 前置条件: 已执行 source scripts/deploy-env-local.sh
#           数据库已初始化（auth-init-v0.1.5.sql + auth-init-v0.1.6.sql）
# 用法: ./scripts/deploy-start-auth.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$PROJECT_DIR/cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar"

# ========== 从 env.json 加载环境变量 ==========
source "$SCRIPT_DIR/load-env.sh"

# ========== 检查必要变量 ==========
REQUIRED_VARS=("NACOS_ADDR" "DB_HOST" "DB_PORT" "DB_USERNAME" "DB_PASSWORD"
               "REDIS_HOST" "REDIS_PORT" "RSA_PRIVATE_KEY" "RSA_PUBLIC_KEY")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING_VARS+=("$var")
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo "❌ 错误: 以下环境变量未设置："
  for var in "${MISSING_VARS[@]}"; do
    echo "   - $var"
  done
  echo ""
  echo "   请先配置项目根目录下的 env.json 文件"
  exit 1
fi

if [ ! -f "$JAR_PATH" ]; then
  echo "❌ 错误: JAR 包不存在: $JAR_PATH"
  echo "   请先执行: mvn clean package -pl cloudoffice-auth-service -am -DskipTests"
  exit 1
fi

# ========== 显示配置信息 ==========
echo "=============================================="
echo "  云漫智企 - Auth Service 启动"
echo "=============================================="
echo "  JAR 包:        $JAR_PATH"
echo "  Nacos 地址:    $NACOS_ADDR"
echo "  数据库:        $DB_HOST:$DB_PORT/$DB_AUTH_NAME"
echo "  Redis:         $REDIS_HOST:$REDIS_PORT"
echo "  验证码模式:    ${VERIFICATION_CODE_MOCK:-true}"
echo "  私钥已配置:    $(if [ -n "${RSA_PRIVATE_KEY:-}" ]; then echo '是'; else echo '否'; fi)"
echo "  公钥已配置:    $(if [ -n "${RSA_PUBLIC_KEY:-}" ]; then echo '是'; else echo '否'; fi)"
echo "=============================================="
echo ""

# ========== 启动服务 ==========
# Auth Service 所需环境变量：
# - NACOS_ADDR:      Nacos 服务地址（来源：bootstrap.yml）
# - DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD: 数据库连接（来源：application.yml）
# - REDIS_HOST/REDIS_PORT/REDIS_PASSWORD:     Redis 连接（来源：application.yml）
# - RSA_PRIVATE_KEY: RSA 私钥，用于 JWT 签名（来源：application.yml）
# - RSA_PUBLIC_KEY:  RSA 公钥，用于 JWT 验签（来源：application.yml）
# - VERIFICATION_CODE_*:  验证码相关配置（来源：application.yml）
# - PASSWORD_MIN/MAX_LENGTH: 密码策略（来源：application.yml）
echo "🚀 启动 Auth Service..."
echo ""

exec java \
  -Xms256m -Xmx512m \
  -jar "$JAR_PATH"
