#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-check-env.sh - 环境可用性检查与运行状态检测脚本 (Bash)
# 版本: v0.2.7
# 说明:
#   基于 deploy/env.json（经 load-env 统一加载，F-001）执行：
#     阶段一 环境可用性检查（F-002~F-005）：
#       - JDK：java 命令可执行 + JAVA_HOME 有效 + 版本 21
#       - MariaDB：命令/系统服务/进程三重安装检测 + SELECT 1 连通性（口令掩码）
#       - Redis：命令/系统服务/进程三重安装检测 + redis-cli ping 返回 PONG
#       - Nacos：NACOS_HOME/bin/startup.sh 存在 + HTTP 探测 http://NACOS_ADDR/nacos/ 含 Nacos
#     阶段二 运行状态检测（F-006）：
#       - JDK：复用可用性检查结论（可用即视为就绪）
#       - MariaDB/Redis：进程 / systemd 服务活跃 / TCP 端口可达，任一命中即运行中
#       - Nacos：HTTP 探测含 Nacos 即运行中，失败再检测 java 进程命令行含 nacos 作辅助
#   输出分级（通过/警告/失败）与退出码约定（F-011）：
#     全部通过退出 0；存在失败项退出 1；存在警告但无失败退出 0 并提示警告。
#   本脚本仅做检查，不执行任何启动动作（启动由 deploy-start-services 负责）。
# 用法: ./deploy/scripts/deploy-check-env.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json） ==========
# 注：load-env.sh 为 source 型脚本，配置缺失时 return 1；在 set -e 下脚本随即退出非零。
source "$SCRIPT_DIR/load-env.sh"

# ========== 1. 全局计数与输出辅助 ==========
PASS=0
WARN=0
FAIL=0
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# 输出「通过/警告/失败」三级结果并累计计数（F-011 输出分级约定）
print_result() {
  local status="$1" message="$2"
  case "$status" in
    通过) echo -e "  ${GREEN}[通过]${NC} $message"; PASS=$((PASS + 1)) ;;
    警告) echo -e "  ${YELLOW}[警告]${NC} $message"; WARN=$((WARN + 1)) ;;
    失败) echo -e "  ${RED}[失败]${NC} $message"; FAIL=$((FAIL + 1)) ;;
  esac
}

# 逗号分隔字符串转数组（去空白、去空行，用于服务名/进程名检测清单）
split_csv() {
  echo "$1" | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' || true
}

# 命令是否存在
has_cmd() { command -v "$1" &>/dev/null; }

# systemd 服务是否存在
has_svc() {
  local s
  for s in "$@"; do
    systemctl list-units --type=service --all 2>/dev/null | grep -qw "$s" && return 0
  done
  return 1
}

# 进程是否存在（按精确名）
has_proc() {
  local p
  for p in "$@"; do
    pgrep -x "$p" &>/dev/null && return 0
  done
  return 1
}

# systemd 服务是否活跃
svc_active() {
  local s
  for s in "$@"; do
    systemctl is-active --quiet "$s" 2>/dev/null && return 0
  done
  return 1
}

# TCP 端口可达性探测（bash 内置 /dev/tcp，timeout 防挂起；用于运行状态检测 F-006）
tcp_port_open() {
  local hostname="$1" port="$2"
  if command -v timeout &>/dev/null; then
    if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$hostname/$port" 2>/dev/null; then
      return 0
    fi
  else
    if bash -c "cat < /dev/null > /dev/tcp/$hostname/$port" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006）
nacos_http_ok() {
  curl -s --max-time 5 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"
}

# ========== 2. 解析 env.json 中的可选检测清单（服务/进程名，非连接地址，允许默认清单） ==========
mapfile -t DB_SERVICES   < <(split_csv "${DB_SERVICE_NAME:-MySQL,MariaDB}")
mapfile -t DB_PROCESSES  < <(split_csv "${DB_PROCESS_NAME:-mysqld,mariadbd}")
mapfile -t REDIS_SERVICES  < <(split_csv "${REDIS_SERVICE_NAME:-Redis}")
mapfile -t REDIS_PROCESSES < <(split_csv "${REDIS_PROCESS_NAME:-redis-server}")

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) 环境可用性检查与运行状态检测"
echo "  版本: v0.2.7"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. 阶段一：环境可用性检查（F-002~F-005） ==========
echo "━━━ 阶段一: 环境可用性检查 ━━━"

# 4.1 JDK 可用性（命令可执行 + JAVA_HOME 有效 + 版本 21，合并为一项结论，F-002）
JAVA_OK=false
if has_cmd java; then
  if java -version 2>&1 | grep -q 'version "21'; then JAVA_OK=true; fi
fi
JAVA_HOME_OK=false
if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then JAVA_HOME_OK=true; fi

if [ "$JAVA_OK" = true ] && [ "$JAVA_HOME_OK" = true ]; then
  print_result "通过" "JDK 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21）"
else
  print_result "失败" "JDK 不可用（java 命令/版本 21/JAVA_HOME 任一不满足），请安装 JDK 21 并配置 JAVA_HOME"
fi

# 4.2 MariaDB 可用性（命令/服务/进程三重安装检测 + SELECT 1，F-003）
DB_INSTALL=""
for c in mariadb mysql mysqld mariadbd; do
  if has_cmd "$c"; then DB_INSTALL="命令 $c"; break; fi
done
if [ -z "$DB_INSTALL" ] && has_svc "${DB_SERVICES[@]}"; then DB_INSTALL="服务 ${DB_SERVICES[*]}"; fi
if [ -z "$DB_INSTALL" ] && has_proc "${DB_PROCESSES[@]}"; then DB_INSTALL="进程 ${DB_PROCESSES[*]}"; fi

DB_CLIENT=""
if [ -z "$DB_INSTALL" ]; then
  print_result "失败" "MariaDB 未安装（未检测到命令/系统服务/进程），请安装 MariaDB 或 MySQL，或在 env.json 中配置 DB_SERVICE_NAME/DB_PROCESS_NAME"
else
  for c in mariadb mysql; do
    if has_cmd "$c"; then DB_CLIENT="$c"; break; fi
  done
  if [ -z "$DB_CLIENT" ]; then
    print_result "失败" "MariaDB 已安装（$DB_INSTALL），但未找到 mariadb/mysql 客户端命令，无法执行 SELECT 1，请安装客户端工具"
  else
    DB_CONN_OK=false
    # 口令经 MYSQL_PWD 环境变量传递（不出现于进程命令行，消除 S-01 进程级口令泄露；
    # MYSQL_PWD 在 MySQL 官方文档标注弃用，但 MariaDB 客户端完整支持；若后续升级
    # 客户端不再支持，可改经 --defaults-extra-file 临时配置文件传递，见审核报告 S-01 决策）
    # 仅对子进程注入 MYSQL_PWD（赋值前缀语法），父 shell 环境不受污染
    if MYSQL_PWD="$DB_PASSWORD" "$DB_CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -N -B -e "SELECT 1" >/dev/null 2>&1; then DB_CONN_OK=true; fi
    if [ "$DB_CONN_OK" = true ]; then
      print_result "通过" "MariaDB 可用（安装: $DB_INSTALL；SELECT 1 连接成功，口令掩码 ****）"
    else
      print_result "失败" "MariaDB 已安装（$DB_INSTALL）但连接失败，请检查 env.json 中 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD（口令掩码 ****）"
    fi
  fi
fi

# 4.3 Redis 可用性（命令/服务/进程三重安装检测 + ping 返回 PONG，F-004）
REDIS_INSTALL=""
for c in redis-cli redis-server; do
  if has_cmd "$c"; then REDIS_INSTALL="命令 $c"; break; fi
done
if [ -z "$REDIS_INSTALL" ] && has_svc "${REDIS_SERVICES[@]}"; then REDIS_INSTALL="服务 ${REDIS_SERVICES[*]}"; fi
if [ -z "$REDIS_INSTALL" ] && has_proc "${REDIS_PROCESSES[@]}"; then REDIS_INSTALL="进程 ${REDIS_PROCESSES[*]}"; fi

if [ -z "$REDIS_INSTALL" ]; then
  print_result "失败" "Redis 未安装（未检测到命令/系统服务/进程），请安装 Redis 或在 env.json 中配置 REDIS_SERVICE_NAME/REDIS_PROCESS_NAME"
elif ! has_cmd redis-cli; then
  print_result "失败" "Redis 已安装（$REDIS_INSTALL），但未找到 redis-cli 命令，无法执行 ping，请安装 redis-cli"
else
  REDIS_PING_OK=false
  # 口令经 REDISCLI_AUTH 环境变量传递（Redis 官方推荐），命令与日志均不出现明文
  if [ -n "${REDIS_PASSWORD:-}" ]; then export REDISCLI_AUTH="$REDIS_PASSWORD"; fi
  if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q "PONG"; then REDIS_PING_OK=true; fi
  if [ "$REDIS_PING_OK" = true ]; then
    print_result "通过" "Redis 可用（安装: $REDIS_INSTALL；ping 返回 PONG）"
  else
    print_result "失败" "Redis 已安装（$REDIS_INSTALL）但 ping 失败，请检查 env.json 中 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD"
  fi
fi

# 4.4 Nacos 可用性（NACOS_HOME/startup.sh 安装检测 + HTTP 探测；已安装未启动计「警告（未运行）」F-005）
NACOS_ADDR_VALID=false
if [[ "$NACOS_ADDR" =~ ^[^:]+:[0-9]+$ ]]; then NACOS_ADDR_VALID=true; fi
NACOS_INSTALLED=false
NACOS_HTTP_OK=false
NACOS_STARTUP="$NACOS_HOME/bin/startup.sh"

if [ "$NACOS_ADDR_VALID" = false ]; then
  print_result "失败" "Nacos 地址格式非法（$NACOS_ADDR），请检查 env.json 中 NACOS_ADDR（应为 host:port）"
elif [ -z "${NACOS_HOME:-}" ] || [ ! -d "$NACOS_HOME" ] || [ ! -f "$NACOS_STARTUP" ]; then
  print_result "失败" "Nacos 未安装（NACOS_HOME 目录或 bin/startup.sh 不存在: ${NACOS_HOME:-空}），请安装 Nacos 或配置 env.json 中 NACOS_HOME"
else
  NACOS_INSTALLED=true
  if nacos_http_ok; then
    NACOS_HTTP_OK=true
    print_result "通过" "Nacos 可用（已安装: $NACOS_HOME；HTTP 探测 http://$NACOS_ADDR/nacos/ 返回 Nacos）"
  else
    print_result "警告" "Nacos 未运行（已安装: $NACOS_HOME；HTTP 探测 http://$NACOS_ADDR/nacos/ 失败）"
  fi
fi

# ========== 5. 阶段二：运行状态检测（F-006） ==========
echo ""
echo "━━━ 阶段二: 运行状态检测 ━━━"

# 5.1 JDK：复用可用性检查结论（可用即视为就绪，无独立启动检查）
if [ "$JAVA_OK" = true ] && [ "$JAVA_HOME_OK" = true ]; then
  print_result "通过" "JDK 运行状态: 就绪（复用可用性检查结论）"
else
  print_result "失败" "JDK 运行状态: 不可用（JDK 未就绪，请先解决可用性失败项）"
fi

# 5.2 MariaDB：进程 / systemd 服务活跃 / TCP 端口 任一命中即运行中
DB_RUNNING=false
if has_proc "${DB_PROCESSES[@]}"; then DB_RUNNING=true; fi
if [ "$DB_RUNNING" = false ] && svc_active "${DB_SERVICES[@]}"; then DB_RUNNING=true; fi
if [ "$DB_RUNNING" = false ] && tcp_port_open "$DB_HOST" "$DB_PORT"; then DB_RUNNING=true; fi

if [ -z "$DB_INSTALL" ]; then
  print_result "失败" "MariaDB 运行状态: 未安装（不可启动）"
elif [ "$DB_RUNNING" = true ]; then
  print_result "通过" "MariaDB 运行状态: 运行中（进程/系统服务/TCP 任一命中）"
else
  print_result "警告" "MariaDB 运行状态: 未运行（进程/系统服务/TCP 均未检测到，供 deploy-start-services 启动）"
fi

# 5.3 Redis：进程 / systemd 服务活跃 / TCP 端口 任一命中即运行中
REDIS_RUNNING=false
if has_proc "${REDIS_PROCESSES[@]}"; then REDIS_RUNNING=true; fi
if [ "$REDIS_RUNNING" = false ] && svc_active "${REDIS_SERVICES[@]}"; then REDIS_RUNNING=true; fi
if [ "$REDIS_RUNNING" = false ] && tcp_port_open "$REDIS_HOST" "$REDIS_PORT"; then REDIS_RUNNING=true; fi

if [ -z "$REDIS_INSTALL" ]; then
  print_result "失败" "Redis 运行状态: 未安装（不可启动）"
elif [ "$REDIS_RUNNING" = true ]; then
  print_result "通过" "Redis 运行状态: 运行中（进程/系统服务/TCP 任一命中）"
else
  print_result "警告" "Redis 运行状态: 未运行（进程/系统服务/TCP 均未检测到，供 deploy-start-services 启动）"
fi

# 5.4 Nacos：HTTP 探测为主（复用阶段一结果），java 进程命令行含 nacos 为辅助
NACOS_RUNNING="$NACOS_HTTP_OK"
if [ "$NACOS_RUNNING" = false ] && pgrep -f "nacos" &>/dev/null; then NACOS_RUNNING=true; fi

if [ "$NACOS_ADDR_VALID" = false ]; then
  print_result "失败" "Nacos 运行状态: 不可检测（NACOS_ADDR 格式非法）"
elif [ "$NACOS_INSTALLED" = false ]; then
  print_result "失败" "Nacos 运行状态: 未安装（不可启动）"
elif [ "$NACOS_RUNNING" = true ]; then
  print_result "通过" "Nacos 运行状态: 运行中（HTTP 探测或 java 进程含 nacos）"
else
  print_result "警告" "Nacos 运行状态: 未运行（HTTP 探测失败且未检测到 java 进程含 nacos，供 deploy-start-services 启动）"
fi

# ========== 6. 汇总与退出码（F-011） ==========
echo ""
echo "=============================================="
echo -e "  检查完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
echo "=============================================="

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}存在失败的检查项，请按上述提示处理后重新运行。${NC}"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "\n${YELLOW}存在警告项，请关注未运行/待处理组件（警告不阻断部署）。${NC}"
  exit 0
else
  echo -e "\n${GREEN}全部检查通过，可以继续进行部署。${NC}"
  exit 0
fi
