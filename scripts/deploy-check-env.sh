#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 部署前置检查脚本
# 版本: v0.1.7
# 说明: 逐一检查中间件可用性、开发环境、网络连通性
# 用法: ./scripts/deploy-check-env.sh
# ============================================================

set -euo pipefail

PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ------ 配置区（请根据实际环境修改）------
NACOS_ADDR="${NACOS_ADDR:-192.168.1.100:8848}"
DB_HOST="${DB_HOST:-192.168.1.101}"
DB_PORT="${DB_PORT:-3306}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-<DB_PASSWORD>}"
REDIS_HOST="${REDIS_HOST:-192.168.1.102}"
REDIS_PORT="${REDIS_PORT:-6379}"
# --------------------------------------

check() {
    local desc="$1"
    local cmd="$2"
    local expected="$3"
    echo -n "[..] $desc ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}失败${NC}"
        echo -e "  ${YELLOW}预期:${NC} $expected"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) 前置环境检查"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ==================== 1. 中间件可用性检查 ====================
echo "━━━ 1. 中间件可用性检查 ━━━"

# 1.1 Nacos 检查
check "Nacos 服务 ($NACOS_ADDR)" \
    "curl -s --max-time 5 http://$NACOS_ADDR/nacos/" \
    "返回 Nacos 页面 HTML 或 JSON（含 'Nacos' 字样）"

# 1.2 MariaDB 检查
check "MariaDB 数据库 ($DB_HOST:$DB_PORT)" \
    "mariadb -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p'$DB_PASSWORD' -e 'SELECT 1'" \
    "返回 1"

# 1.3 Redis 检查
check "Redis 缓存 ($REDIS_HOST:$REDIS_PORT)" \
    "redis-cli -h $REDIS_HOST -p $REDIS_PORT ping" \
    "返回 PONG"

# ==================== 2. 开发环境检查 ====================
echo ""
echo "━━━ 2. 开发环境检查 ━━━"

# 2.1 JDK 检查
check "JDK 21 已安装" \
    "java -version 2>&1 | grep -q 'openjdk version \"21'\" \
    "java -version 输出包含 'openjdk version \"21'"

# 2.2 Maven 检查
check "Maven 3.9+ 已安装" \
    "mvn -version 2>&1 | grep -q 'Apache Maven 3.9'" \
    "mvn -version 输出包含 'Apache Maven 3.9'"

# 2.3 Git 检查
check "Git 已安装" \
    "git version 2>&1 | grep -q 'git version'" \
    "git version 输出版本号"

# 2.4 JAVA_HOME 检查
check "JAVA_HOME 环境变量已设置" \
    "test -n \"$JAVA_HOME\" && test -d \"$JAVA_HOME\"" \
    "JAVA_HOME 指向 JDK 21 安装目录"

# ==================== 3. 网络连通性检查 ====================
echo ""
echo "━━━ 3. 网络连通性检查 ━━━"

# 3.1 Nacos 端口可达
check "Nacos 端口 $NACOS_ADDR 可达" \
    "curl -s --max-time 5 http://$NACOS_ADDR/nacos/ | head -1 | grep -q ." \
    "TCP 连接成功，HTTP 返回非空响应"

# 3.2 MariaDB 端口可达
check "MariaDB 端口 $DB_HOST:$DB_PORT 可达" \
    "mariadb -h $DB_HOST -P $DB_PORT -u $DB_USERNAME -p'$DB_PASSWORD' -e 'SELECT VERSION()'" \
    "数据库连接成功，返回 MariaDB 版本号"

# 3.3 Redis 端口可达
check "Redis 端口 $REDIS_HOST:$REDIS_PORT 可达" \
    "redis-cli -h $REDIS_HOST -p $REDIS_PORT ping" \
    "返回 PONG"

# ==================== 4. 项目代码检查 ====================
echo ""
echo "━━━ 4. 项目代码检查 ━━━"

# 4.1 项目根目录存在
check "项目代码已就绪（pom.xml 存在）" \
    "test -f pom.xml" \
    "pom.xml 文件存在于项目根目录"

# 4.2 SQL 脚本存在
check "SQL 初始化脚本存在" \
    "ls scripts/sql/auth-init-v0.1.5.sql scripts/sql/auth-init-v0.1.6.sql 2>/dev/null | wc -l | grep -q 2" \
    "scripts/sql/ 目录下存在 auth-init-v0.1.5.sql 和 auth-init-v0.1.6.sql"

# 4.3 Maven 配置文件存在
check "Maven 设置可访问 (settings.xml)" \
    "test -f ~/.m2/settings.xml -o -f pom.xml" \
    "~/.m2/settings.xml 存在或项目 pom.xml 可读取"

# ==================== 汇总 ====================
echo ""
echo "=============================================="
echo -e "  检查完成: ${GREEN}$PASS 项通过${NC}, ${RED}$FAIL 项失败${NC}"
echo "=============================================="

if [ $FAIL -gt 0 ]; then
    echo ""
    echo -e "${RED}请解决上述失败的检查项后重新运行此脚本。${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}所有检查通过！可以继续进行部署。${NC}"
    exit 0
fi
