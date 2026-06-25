#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) Biz Service 启动脚本
# 版本: v0.1.7
# 说明: 自动注入环境变量并启动企业服务
# 前置条件: 已执行 source scripts/deploy-env-local.sh
# 用法: ./scripts/deploy-start-biz.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
JAR_PATH="$PROJECT_DIR/cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar"

# ========== 检查必要变量 ==========
# biz-service 使用 DB_USER 环境变量（不同于 auth-service 的 DB_USERNAME）
if [ -z "${NACOS_ADDR:-}" ]; then
  echo "❌ 错误: NACOS_ADDR 未设置。请先执行: source scripts/deploy-env-local.sh"
  exit 1
fi

if [ -z "${DB_PASSWORD:-}" ]; then
  echo "❌ 错误: DB_PASSWORD 未设置。请先执行: source scripts/deploy-env-local.sh"
  exit 1
fi

if [ ! -f "$JAR_PATH" ]; then
  echo "❌ 错误: JAR 包不存在: $JAR_PATH"
  echo "   请先执行: mvn clean package -pl cloudoffice-biz-service -am -DskipTests"
  exit 1
fi

# ========== 显示配置信息 ==========
echo "=============================================="
echo "  云漫智企 - Biz Service 启动"
echo "=============================================="
echo "  JAR 包:        $JAR_PATH"
echo "  Nacos 地址:    ${NACOS_ADDR:-未设置}"
echo "  数据库 URL:    ${DB_URL:-jdbc:mariadb://${DB_HOST:-localhost}:3306/cloudstroll_office_biz}"
echo "  DB 用户名:     ${DB_USER:-root}"
echo "=============================================="
echo ""

# ========== 启动服务 ==========
# Biz Service 所需环境变量（注意：biz-service 使用 DB_USER 和 DB_PASSWORD）：
# - NACOS_ADDR:  Nacos 服务地址（来源：bootstrap.yml）
# - DB_URL:      完整 JDBC 连接 URL（来源：application.yml，有默认值）
# - DB_USER:     数据库用户名（来源：application.yml）
# - DB_PASSWORD: 数据库密码（来源：application.yml）
# - REDIS:       biz-service 暂不需要 Redis（根据 application.yml 判断）
echo "🚀 启动 Biz Service..."
echo ""

exec java \
  -Xms256m -Xmx512m \
  -jar "$JAR_PATH"
