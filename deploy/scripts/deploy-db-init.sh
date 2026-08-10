#!/bin/bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# 云漫智企 (CloudStrollOffice) 数据库初始化脚本
# 版本: v0.1.7（S-04 修复：连接参数不再硬编码默认地址/凭据，一律从 env.json 读取；
#                 口令经 MYSQL_PWD 环境变量传递，不出现在进程命令行）
# 说明: 创建业务数据库并初始化表结构和初始数据
# 前置条件: MariaDB 已启动且可连接
# 用法: ./deploy/scripts/deploy-db-init.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ROOT_DIR="$(dirname "$PROJECT_DIR")"
SQL_DIR="$ROOT_DIR/scripts/sql"

# ========== 从 env.json 加载环境变量 ==========
source "$SCRIPT_DIR/load-env.sh"

# ------ 数据库连接参数（一律来自 load-env 加载的 env.json，S-04 修复：无硬编码默认值）------
: "${DB_HOST:?错误: DB_HOST 未设置，请先经 load-env 加载 env.json}"
: "${DB_PORT:?错误: DB_PORT 未设置，请先经 load-env 加载 env.json}"
: "${DB_USERNAME:?错误: DB_USERNAME 未设置，请先经 load-env 加载 env.json}"
: "${DB_PASSWORD:?错误: DB_PASSWORD 未设置，请先经 load-env 加载 env.json}"
# 口令经 MYSQL_PWD 环境变量传递（P8 修复：不出现于进程命令行；MariaDB 客户端支持）
export MYSQL_PWD="$DB_PASSWORD"
# ---------------------------------------------------------------------------------

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
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" < "$SQL_DIR/auth-init-v0.1.5.sql"
echo "  ✅ v0.1.5 基础初始化完成（7 张核心表 + 初始数据）"
echo ""

# 步骤 2: 执行 v0.1.6 增量脚本
echo "[2/3] 执行 v0.1.6 增量脚本..."
echo "  执行: mariadb -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p'****' < $SQL_DIR/auth-init-v0.1.6.sql"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" < "$SQL_DIR/auth-init-v0.1.6.sql"
echo "  ✅ v0.1.6 增量初始化完成（新增 2 张表 + 字段扩展）"
echo ""

# 步骤 3: 验证初始化结果
echo "[3/3] 验证数据库初始化..."

# 3.1 验证数据库存在
echo "  --- 数据库列表 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" \
  -e "SHOW DATABASES LIKE 'cloudstroll_office_%';"

# 3.2 验证 auth 数据库表结构
echo ""
echo "  --- cloudstroll_office_auth 表列表 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" \
  -e "USE cloudstroll_office_auth; SHOW TABLES;"

# 3.3 验证初始数据
echo ""
echo "  --- 租户表初始数据 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" \
  -e "USE cloudstroll_office_auth; SELECT id, tenant_name, tenant_code, status FROM t_auth_tenant;"

echo ""
echo "  --- 用户表初始数据 ---"
mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" \
  -e "USE cloudstroll_office_auth; SELECT id, login_name, real_name, status FROM t_auth_user;"

# 清理 MYSQL_PWD（脚本结束时消除凭据环境变量）
unset MYSQL_PWD

echo ""
echo "=============================================="
echo "  数据库初始化完成！"
echo "=============================================="
echo ""
echo "接下来可以编译打包并启动服务："
echo "  编译:   mvn clean package -DskipTests"
echo "  启动:   按顺序启动 Gateway → auth-service → biz-service → system-service"
echo "  详情:   参见 docs/deployment-guide.md"
