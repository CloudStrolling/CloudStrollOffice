#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 服务环境检测与启动脚本 (Bash)
# 版本: v0.2.0
# 说明:
#   1. 从 env.json 加载环境变量，校验配置完整性
#   2. 检测 MySQL/MariaDB、Nacos、Redis 是否安装（命令+服务+进程三重检测）
#   3. 检测服务是否运行，未运行则自动启动
#   4. 打印检测结果
#   可在 env.json 中配置 DB_SERVICE_NAME 等可选键
# 用法: ./scripts/deploy-start-services.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0; FAIL=0; WARN=0
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ========== 1. 加载环境变量 ==========
if [ ! -f "$PROJECT_DIR/env.json" ]; then
  echo -e "${RED}❌ 错误: 环境配置文件不存在: $PROJECT_DIR/env.json${NC}"
  echo "   请复制 env.example.json 为 env.json 并填写配置"
  exit 1
fi

source "$SCRIPT_DIR/load-env.sh"

REQUIRED_VARS=("NACOS_ADDR" "NACOS_HOME" "DB_HOST" "DB_PORT" "DB_USERNAME" "DB_PASSWORD"
               "REDIS_HOST" "REDIS_PORT")
MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then MISSING_VARS+=("$var"); fi
done
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo -e "${RED}❌ 错误: 以下环境变量在 env.json 中未设置：${NC}"
  for var in "${MISSING_VARS[@]}"; do echo "   - $var"; done
  exit 1
fi

# 用逗号/空格分隔 env 中配置的服务名/进程名列表
split_csv() { echo "$1" | tr ',' ' ' | xargs; }

DB_SERVICES=($(split_csv "${DB_SERVICE_NAME:-MySQL,MariaDB}"))
DB_PROCESSES=($(split_csv "${DB_PROCESS_NAME:-mysqld,mariadbd}"))
REDIS_SERVICES=($(split_csv "${REDIS_SERVICE_NAME:-Redis}"))
REDIS_PROCESSES=($(split_csv "${REDIS_PROCESS_NAME:-redis-server}"))

echo ""
echo "=============================================="
echo "  云漫智企 - 服务环境检测与启动"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="

print_result() {
  local service="$1" status="$2" message="$3"
  case "$status" in
    通过) echo -e "  ${GREEN}✅${NC} [$service] $message" ;;
    警告) echo -e "  ${YELLOW}⚠️${NC} [$service] $message" ;;
    失败) echo -e "  ${RED}❌${NC} [$service] $message" ;;
  esac
}

# 通用：是否找到可执行命令
has_cmd() { command -v "$1" &>/dev/null; }

# 通用：systemd 服务是否存在
has_svc() { systemctl list-units --type=service --all 2>/dev/null | grep -qw "$1"; }

# 通用：进程是否存在
has_proc() {
  local p; for p in "$@"; do pgrep -x "$p" &>/dev/null && return 0; done; return 1
}

# 通用：systemd 是否活跃
svc_active() {
  local s; for s in "$@"; do
    systemctl is-active --quiet "$s" 2>/dev/null && return 0
  done; return 1
}

# ========== 2. 安装检测（三重检测）==========
echo ""
echo "━━━ 阶段一: 服务安装检测 (命令 / systemd 服务 / 进程) ━━━"

# 2.1 MySQL/MariaDB
FOUND=""
for cmd in "${DB_PROCESSES[@]}"; do
  if has_cmd "$cmd"; then FOUND="命令 $cmd"; break; fi
done
if [ -z "$FOUND" ]; then
  for svc in "${DB_SERVICES[@]}"; do
    if has_svc "$svc"; then FOUND="服务 $svc"; break; fi
  done
fi
if [ -z "$FOUND" ] && has_proc "${DB_PROCESSES[@]}"; then
  FOUND="进程 ${DB_PROCESSES[*]}"
fi
if [ -n "$FOUND" ]; then
  PASS=$((PASS + 1)); print_result "MySQL/MariaDB" "通过" "已检测到 ($FOUND)"
else
  FAIL=$((FAIL + 1))
  print_result "MySQL/MariaDB" "失败" "未检测到，请安装 MySQL/MariaDB，或在 env.json 中配置 DB_PROCESS_NAME / DB_SERVICE_NAME"
fi

# 2.2 Nacos —— NACOS_HOME 目录 + startup 脚本
NACOS_HOME="${NACOS_HOME:-}"
if [ -n "$NACOS_HOME" ] && [ -d "$NACOS_HOME" ] && [ -f "$NACOS_HOME/bin/startup.sh" ]; then
  PASS=$((PASS + 1)); print_result "Nacos" "通过" "已检测到 (目录: $NACOS_HOME)"
else
  FAIL=$((FAIL + 1))
  print_result "Nacos" "失败" "NACOS_HOME 目录或 startup.sh 不存在 ($NACOS_HOME)"
fi

# 2.3 Redis
FOUND=""
for cmd in "${REDIS_PROCESSES[@]}"; do
  if has_cmd "$cmd"; then FOUND="命令 $cmd"; break; fi
done
if [ -z "$FOUND" ]; then
  for svc in "${REDIS_SERVICES[@]}"; do
    if has_svc "$svc"; then FOUND="服务 $svc"; break; fi
  done
fi
if [ -z "$FOUND" ] && has_proc "${REDIS_PROCESSES[@]}"; then
  FOUND="进程 ${REDIS_PROCESSES[*]}"
fi
if [ -n "$FOUND" ]; then
  PASS=$((PASS + 1)); print_result "Redis" "通过" "已检测到 ($FOUND)"
else
  FAIL=$((FAIL + 1))
  print_result "Redis" "失败" "未检测到，请安装 Redis，或在 env.json 中配置 REDIS_PROCESS_NAME / REDIS_SERVICE_NAME"
fi

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}❌ 存在未安装的服务，请先完成安装后重试。${NC}"
  exit 1
fi

# ========== 3. 运行检测与启动 ==========
echo ""
echo "━━━ 阶段二: 服务运行检测与启动 ━━━"

# 3.1 MySQL/MariaDB —— 进程 + systemd + mysqladmin ping 三重检测
if has_proc "${DB_PROCESSES[@]}"; then
  PASS=$((PASS + 1)); print_result "MySQL/MariaDB" "通过" "进程运行中"
elif svc_active "${DB_SERVICES[@]}"; then
  PASS=$((PASS + 1)); print_result "MySQL/MariaDB" "通过" "systemd 服务活跃"
else
  print_result "MySQL/MariaDB" "警告" "未运行，尝试启动..."
  if systemctl list-units --type=service --all 2>/dev/null | grep -qE "mysql|mariadb"; then
    local svc_name
    svc_name=$(systemctl list-units --type=service --all 2>/dev/null | grep -oE "mysql|mariadb" | head -1)
    if sudo systemctl start "$svc_name" 2>/dev/null; then
      PASS=$((PASS + 1)); print_result "MySQL/MariaDB" "通过" "已启动 (systemctl $svc_name)"
    else
      WARN=$((WARN + 1)); print_result "MySQL/MariaDB" "警告" "systemctl 启动失败"
    fi
  elif has_cmd "mysqld_safe"; then
    mysqld_safe --user=mysql &
    sleep 3
    if has_proc "${DB_PROCESSES[@]}"; then
      PASS=$((PASS + 1)); print_result "MySQL/MariaDB" "通过" "已启动 (mysqld_safe)"
    else
      WARN=$((WARN + 1)); print_result "MySQL/MariaDB" "警告" "mysqld_safe 启动失败"
    fi
  else
    WARN=$((WARN + 1)); print_result "MySQL/MariaDB" "警告" "无法自动启动，请手动启动"
  fi
fi

# 3.2 Nacos —— HTTP 探测 + 进程检测
NACOS_RUNNING=false
if curl -s --max-time 3 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"; then
  NACOS_RUNNING=true
fi
if [ "$NACOS_RUNNING" = true ]; then
  PASS=$((PASS + 1)); print_result "Nacos" "通过" "HTTP 探测正常 (http://$NACOS_ADDR/nacos/)"
elif pgrep -f "nacos" &>/dev/null; then
  PASS=$((PASS + 1)); print_result "Nacos" "通过" "进程运行中 (java - nacos)"
else
  print_result "Nacos" "警告" "未运行，尝试启动..."
  if [ -f "$NACOS_HOME/$NACOS_STARTUP_SCRIPT" ]; then
    bash "$NACOS_HOME/bin/startup.sh" &>/dev/null &
    sleep 8
    if curl -s --max-time 5 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"; then
      PASS=$((PASS + 1)); print_result "Nacos" "通过" "已启动 (http://$NACOS_ADDR/nacos/)"
    else
      WARN=$((WARN + 1)); print_result "Nacos" "警告" "Nacos 启动中，请稍后手动检查 http://$NACOS_ADDR/nacos/"
    fi
  else
    WARN=$((WARN + 1)); print_result "Nacos" "警告" "找不到启动脚本: $NACOS_HOME/bin/startup.sh"
  fi
fi

# 3.3 Redis —— 进程 + systemd + redis-cli ping 三重检测
if has_proc "${REDIS_PROCESSES[@]}"; then
  PASS=$((PASS + 1)); print_result "Redis" "通过" "进程运行中"
elif svc_active "${REDIS_SERVICES[@]}"; then
  PASS=$((PASS + 1)); print_result "Redis" "通过" "systemd 服务活跃"
elif redis-cli ping 2>/dev/null | grep -q "PONG"; then
  PASS=$((PASS + 1)); print_result "Redis" "通过" "redis-cli ping 正常"
else
  print_result "Redis" "警告" "未运行，尝试启动..."
  if systemctl list-units --type=service --all 2>/dev/null | grep -q "redis"; then
    if sudo systemctl start redis 2>/dev/null; then
      PASS=$((PASS + 1)); print_result "Redis" "通过" "已启动 (systemctl redis)"
    else
      WARN=$((WARN + 1)); print_result "Redis" "警告" "systemctl 启动失败"
    fi
  elif has_cmd "redis-server"; then
    redis-server --daemonize yes 2>/dev/null || redis-server &
    sleep 2
    if redis-cli ping 2>/dev/null | grep -q "PONG"; then
      PASS=$((PASS + 1)); print_result "Redis" "通过" "已启动 (redis-server)"
    else
      WARN=$((WARN + 1)); print_result "Redis" "警告" "redis-server 启动失败"
    fi
  else
    WARN=$((WARN + 1)); print_result "Redis" "警告" "无法自动启动，请手动启动"
  fi
fi

# ========== 汇总 ==========
echo ""
echo "=============================================="
if [ "$FAIL" -gt 0 ]; then
  echo -e "  检测结果: ${RED}失败${NC}"
elif [ "$WARN" -gt 0 ]; then
  echo -e "  检测结果: ${YELLOW}完成 (有警告)${NC}"
else
  echo -e "  检测结果: ${GREEN}全部通过${NC}"
fi
echo -e "  ${GREEN}✅ 通过: $PASS${NC} | ${YELLOW}⚠️ 警告: $WARN${NC} | ${RED}❌ 失败: $FAIL${NC}"
echo "=============================================="
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; else exit 0; fi
