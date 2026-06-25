#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 数据库初始化脚本
# 版本: v0.1.7
# 说明: 创建业务数据库并初始化表结构和初始数据
# 前置条件: MariaDB 已启动且可连接
# 用法: ./scripts/deploy-db-init.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SQL_DIR="$PROJECT_DIR/scripts/sql"

# ------ 数据库连接参数（使用环境变量或默认值）------
DB_HOST="${DB_HOST:-192.168.1.101}"
DB_PORT="${DB_PORT:-3306}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-<DB_PASSWORD>}"
# -------------------------------------------------

echo "=============================================="
echo "  云漫智企 - 数据库初始化"
echo "=============================================="
echo "  数据库主机: $DB_HOST:$DB_PORT"
echo "  用户名:     $DB_USERNAME"
echo "  SQL 目录:   $SQL_DIR"
echo "=============================================="
echo ""

# 检查 SQL 文件是否存在
if [ ! -f "$SQL_DIR/auth-init-v0.1.5.sql" ]; then
  echo "❌ 错误: 未找到 $SQL_DIR/auth-init-v0.1.5.sql"
  exit 1
fi
if [ ! -f "$SQL_DIR/auth-init-v0.1.6.sql" ]; then
  echo "❌ 错误: 未找到 $SQL_DIR/auth-init-v0.1.6.sql"
  exit 1
fi

# 步骤 1: 执行 v0.1.5 基础初始化脚本
echo "[1/3] 执行 v0.1.5 基础初始化脚本..."
echo "  执行: mariadb -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p'****' < $SQL_DIR/auth-init-v0.1.5.sql"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" < "$SQL_DIR/auth-init-v0.1.5.sql"
echo "  ✅ v0.1.5 基础初始化完成（7 张核心表 + 初始数据）"
echo ""

# 步骤 2: 执行 v0.1.6 增量脚本
echo "[2/3] 执行 v0.1.6 增量脚本..."
echo "  执行: mariadb -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p'****' < $SQL_DIR/auth-init-v0.1.6.sql"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" < "$SQL_DIR/auth-init-v0.1.6.sql"
echo "  ✅ v0.1.6 增量初始化完成（新增 2 张表 + 字段扩展）"
echo ""

# 步骤 3: 验证初始化结果
echo "[3/3] 验证数据库初始化..."

# 3.1 验证数据库存在
echo "  --- 数据库列表 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
  -e "SHOW DATABASES LIKE 'cloudstroll_office_%';"

# 3.2 验证 auth 数据库表结构
echo ""
echo "  --- cloudstroll_office_auth 表列表 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
  -e "USE cloudstroll_office_auth; SHOW TABLES;"

# 3.3 验证初始数据
echo ""
echo "  --- 租户表初始数据 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
  -e "USE cloudstroll_office_auth; SELECT id, tenant_name, tenant_code, status FROM t_auth_tenant;"

echo ""
echo "  --- 用户表初始数据 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" \
  -e "USE cloudstroll_office_auth; SELECT id, login_name, real_name, status FROM t_auth_user;"

echo ""
echo "=============================================="
echo "  数据库初始化完成！"
echo "=============================================="
echo ""
echo "接下来可以编译打包并启动服务："
echo "  编译:   mvn clean package -DskipTests"
echo "  启动:   按顺序启动 Gateway → auth-service → biz-service → system-service"
echo "  详情:   参见 docs/deployment-guide.md"
