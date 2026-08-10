#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-start-services.sh - 基础设施运行状态检查与一键启动脚本 (Bash)
# 版本: v0.2.7
# 说明:
#   基于 deploy/env.json（经 load-env 统一加载，F-001）执行（F-006/F-007）：
#     1. JDK 可用性检查（仅输出就绪/缺失结论，不执行启动）
#     2. MariaDB/Redis/Nacos 运行状态检测：
#        - 未安装：不尝试启动，输出"未安装，请先安装"并计入失败
#        - 已运行：幂等跳过，输出"已运行"
#        - 未运行且已安装：按 MariaDB → Redis → Nacos 顺序自动启动
#          启动方式优先级：系统服务（systemctl start / service）→ 可执行文件
#          （mysqld/mariadbd/redis-server）；Nacos 执行 NACOS_HOME/bin/startup.sh -m standalone
#        - 每次启动后循环探测确认（进程/TCP/ping/HTTP，超时上限 30s、间隔 2s），不报假成功
#   输出分级（通过/警告/失败）与退出码约定（F-011）：
#     全部通过退出 0；存在失败项退出 1；存在警告但无失败退出 0 并提示警告。
#   安全约定：口令掩码不打印明文（DB_PASSWORD / REDIS_PASSWORD 经 REDISCLI_AUTH 传递）。
# 用法: ./deploy/scripts/deploy-start-services.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 返回非零并透传退出码） ==========
source "$SCRIPT_DIR/load-env.sh" || exit $?

# ========== 1. 全局计数与输出辅助 ==========
PASS=0
WARN=0
FAIL=0
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# 输出「通过/警告/失败」三级结果并累计计数（F-011 输出分级约定，双平台一致不用 emoji）
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

# TCP 端口可达性探测（bash 内置 /dev/tcp，timeout 防挂起；用于运行状态检测与启动后确认 F-006/F-007）
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

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006/F-007）
nacos_http_ok() {
  curl -s --max-time 5 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"
}

# Redis ping 探测：口令经 REDISCLI_AUTH 环境变量传递（Redis 官方推荐），命令与日志均不出现明文
redis_ping_ok() {
  if [ -n "${REDIS_PASSWORD:-}" ]; then export REDISCLI_AUTH="$REDIS_PASSWORD"; fi
  redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2>/dev/null | grep -q "PONG"
}

# MariaDB 运行状态探测：进程 / 系统服务活跃 / TCP 端口 任一命中即运行中（F-006）
probe_mariadb_up() {
  if has_proc "${DB_PROCESSES[@]}"; then return 0; fi
  if svc_active "${DB_SERVICES[@]}"; then return 0; fi
  if tcp_port_open "$DB_HOST" "$DB_PORT"; then return 0; fi
  return 1
}

# Redis 运行状态探测：进程 / 系统服务活跃 / TCP 端口 / redis-cli ping PONG 任一命中（F-006）
probe_redis_up() {
  if redis_ping_ok; then return 0; fi
  if has_proc "${REDIS_PROCESSES[@]}"; then return 0; fi
  if svc_active "${REDIS_SERVICES[@]}"; then return 0; fi
  if tcp_port_open "$REDIS_HOST" "$REDIS_PORT"; then return 0; fi
  return 1
}

# Nacos 运行状态探测：HTTP 探测为主 + java 进程含 nacos 辅助（F-006）
probe_nacos_up() {
  if nacos_http_ok; then return 0; fi
  if pgrep -f "nacos" &>/dev/null; then return 0; fi
  return 1
}

# 启动后循环探测确认：超时上限内每间隔探测一次，任一命中即返回 0（F-007，不报假成功）
wait_for_service() {
  local fn="$1" timeout="${2:-30}" interval="${3:-2}" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if "$fn"; then return 0; fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

# ========== 2. 解析 env.json 中的可选检测清单（服务/进程名，非连接地址，允许默认清单） ==========
mapfile -t DB_SERVICES   < <(split_csv "${DB_SERVICE_NAME:-MySQL,MariaDB}")
mapfile -t DB_PROCESSES  < <(split_csv "${DB_PROCESS_NAME:-mysqld,mariadbd}")
mapfile -t REDIS_SERVICES  < <(split_csv "${REDIS_SERVICE_NAME:-Redis}")
mapfile -t REDIS_PROCESSES < <(split_csv "${REDIS_PROCESS_NAME:-redis-server}")

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) 基础设施运行状态检查与一键启动"
echo "  版本: v0.2.7"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. JDK 可用性检查（F-006：仅输出结论，不执行启动） ==========
echo "━━━ JDK 可用性（仅检查，不启动） ━━━"
JAVA_OK=false
if has_cmd java; then
  if java -version 2>&1 | grep -q 'version "21'; then JAVA_OK=true; fi
fi
JAVA_HOME_OK=false
if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then JAVA_HOME_OK=true; fi
if [ "$JAVA_OK" = true ] && [ "$JAVA_HOME_OK" = true ]; then
  print_result "通过" "JDK: 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21），无需启动"
else
  print_result "失败" "JDK: 不可用（java 命令/版本 21/JAVA_HOME 任一不满足），请安装 JDK 21 并配置 JAVA_HOME（仅检查不启动，不阻断基础设施启动）"
fi

# ========== 5. MariaDB：运行检测与启动（F-006/F-007，启动顺序第一位） ==========
echo ""
echo "━━━ MariaDB（运行检测 → 启动 → 循环探测确认） ━━━"
DB_INSTALL=""
for c in mariadb mysql mysqld mariadbd; do
  if has_cmd "$c"; then DB_INSTALL="命令 $c"; break; fi
done
if [ -z "$DB_INSTALL" ] && has_svc "${DB_SERVICES[@]}"; then DB_INSTALL="服务 ${DB_SERVICES[*]}"; fi
if [ -z "$DB_INSTALL" ] && has_proc "${DB_PROCESSES[@]}"; then DB_INSTALL="进程 ${DB_PROCESSES[*]}"; fi

if [ -z "$DB_INSTALL" ]; then
  # 未安装：不尝试启动，计入失败，继续后续服务
  print_result "失败" "MariaDB: 未安装，请先安装（未检测到命令/系统服务/进程，或配置 DB_SERVICE_NAME/DB_PROCESS_NAME）"
elif probe_mariadb_up; then
  # 已运行：幂等跳过，不重复启动
  print_result "通过" "MariaDB: 已运行（进程/系统服务/TCP 任一命中），幂等跳过"
else
  echo "  MariaDB: 未运行，尝试启动..."
  DB_STATUS=""
  DB_MSG=""
  # 方式一：系统服务（systemctl start 优先，无 systemctl 时回退 service）
  FOUND_SVC=""
  for svc in "${DB_SERVICES[@]}"; do
    if has_svc "$svc"; then FOUND_SVC="$svc"; break; fi
  done
  if [ -n "$FOUND_SVC" ]; then
    if command -v systemctl &>/dev/null; then
      if ! sudo systemctl start "$FOUND_SVC" 2>&1; then
        echo "  MariaDB: systemctl start $FOUND_SVC 失败（若权限不足请使用 sudo 重试）"
      fi
    else
      if ! sudo service "$FOUND_SVC" start 2>&1; then
        echo "  MariaDB: service $FOUND_SVC start 失败（若权限不足请使用 sudo 重试）"
      fi
    fi
    if wait_for_service probe_mariadb_up; then
      DB_STATUS="通过"; DB_MSG="MariaDB: 已通过系统服务 $FOUND_SVC 启动（循环探测确认）"
    else
      DB_STATUS="警告"; DB_MSG="MariaDB: 系统服务 $FOUND_SVC 启动超时或失败，请等待数秒后重试，或手动检查服务状态与 mariadb 日志；若为权限问题请使用 sudo"
    fi
  else
    # 方式二：可执行文件（无系统服务时兜底）
    FOUND_EXE=""
    for p in "${DB_PROCESSES[@]}"; do
      if has_cmd "$p"; then FOUND_EXE="$p"; break; fi
    done
    if [ -z "$FOUND_EXE" ]; then
      DB_STATUS="警告"; DB_MSG="MariaDB: 未找到系统服务或可执行文件（${DB_PROCESSES[*]}），请手动启动服务"
    else
      # S-03 修复：兜底启动携带 env.json 端口配置（--port），使启动实例与配置一致；
      # 凭据（DB_USERNAME/DB_PASSWORD）存于数据库内部用户，无需命令行传递；
      # 若数据目录未初始化，mysqld 无法直接启动，请先初始化数据目录或改用系统服务启动
      if has_cmd mysqld_safe; then
        nohup mysqld_safe --port="$DB_PORT" >/dev/null 2>&1 &
      else
        nohup "$FOUND_EXE" --port="$DB_PORT" >/dev/null 2>&1 &
      fi
      if wait_for_service probe_mariadb_up; then
        DB_STATUS="通过"; DB_MSG="MariaDB: 已通过可执行文件 $FOUND_EXE 启动（携带 env.json 端口 $DB_PORT，循环探测确认）"
      else
        DB_STATUS="警告"; DB_MSG="MariaDB: 可执行文件 $FOUND_EXE 启动超时或失败，请等待数秒后重试，或手动检查 mariadb 日志；若数据目录未初始化请先初始化再启动；若为权限问题请使用 sudo；请注意本次为兜底启动，请核对实例端口/数据目录与 env.json 配置一致性"
      fi
    fi
  fi
  print_result "$DB_STATUS" "$DB_MSG"
fi

# ========== 6. Redis：运行检测与启动（F-006/F-007，启动顺序第二位） ==========
echo ""
echo "━━━ Redis（运行检测 → 启动 → 循环探测确认） ━━━"
REDIS_INSTALL=""
for c in redis-cli redis-server; do
  if has_cmd "$c"; then REDIS_INSTALL="命令 $c"; break; fi
done
if [ -z "$REDIS_INSTALL" ] && has_svc "${REDIS_SERVICES[@]}"; then REDIS_INSTALL="服务 ${REDIS_SERVICES[*]}"; fi
if [ -z "$REDIS_INSTALL" ] && has_proc "${REDIS_PROCESSES[@]}"; then REDIS_INSTALL="进程 ${REDIS_PROCESSES[*]}"; fi

if [ -z "$REDIS_INSTALL" ]; then
  # 未安装：不尝试启动，计入失败，继续后续服务
  print_result "失败" "Redis: 未安装，请先安装（未检测到命令/系统服务/进程，或配置 REDIS_SERVICE_NAME/REDIS_PROCESS_NAME）"
elif probe_redis_up; then
  # 已运行：幂等跳过，不重复启动
  print_result "通过" "Redis: 已运行（进程/系统服务/TCP/redis-cli ping 任一命中），幂等跳过"
else
  echo "  Redis: 未运行，尝试启动..."
  REDIS_STATUS=""
  REDIS_MSG=""
  # 方式一：系统服务（systemctl start 优先，无 systemctl 时回退 service）
  FOUND_SVC=""
  for svc in "${REDIS_SERVICES[@]}"; do
    if has_svc "$svc"; then FOUND_SVC="$svc"; break; fi
  done
  if [ -n "$FOUND_SVC" ]; then
    if command -v systemctl &>/dev/null; then
      if ! sudo systemctl start "$FOUND_SVC" 2>&1; then
        echo "  Redis: systemctl start $FOUND_SVC 失败（若权限不足请使用 sudo 重试）"
      fi
    else
      if ! sudo service "$FOUND_SVC" start 2>&1; then
        echo "  Redis: service $FOUND_SVC start 失败（若权限不足请使用 sudo 重试）"
      fi
    fi
    if wait_for_service probe_redis_up; then
      REDIS_STATUS="通过"; REDIS_MSG="Redis: 已通过系统服务 $FOUND_SVC 启动（循环探测确认）"
    else
      REDIS_STATUS="警告"; REDIS_MSG="Redis: 系统服务 $FOUND_SVC 启动超时或失败，请等待数秒后重试，或手动检查 redis 日志；若为权限问题请使用 sudo"
    fi
  else
    # 方式二：可执行文件（无系统服务时兜底；daemonize 失败时 nohup 后台启动）
    FOUND_EXE=""
    for p in "${REDIS_PROCESSES[@]}"; do
      if has_cmd "$p"; then FOUND_EXE="$p"; break; fi
    done
    if [ -z "$FOUND_EXE" ]; then
      REDIS_STATUS="警告"; REDIS_MSG="Redis: 未找到系统服务或可执行文件（${REDIS_PROCESSES[*]}），请手动启动服务"
    else
      # S-03 修复：兜底启动携带 env.json 端口与口令配置（--port/--requirepass），
      # 使启动实例与 env.json 一致（带 REDISCLI_AUTH 的 ping 探测可正常通过）；
      # 注意：--requirepass 口令会出现在进程命令行（Redis 无 MYSQL_PWD 等价方案），
      # 如需彻底隐藏口令请改用系统服务或配置文件方式启动
      REDIS_ARGS=(--port "$REDIS_PORT")
      if [ -n "${REDIS_PASSWORD:-}" ]; then REDIS_ARGS+=(--requirepass "$REDIS_PASSWORD"); fi
      redis-server "${REDIS_ARGS[@]}" --daemonize yes >/dev/null 2>&1 || (nohup redis-server "${REDIS_ARGS[@]}" >/dev/null 2>&1 &)
      if wait_for_service probe_redis_up; then
        REDIS_STATUS="通过"; REDIS_MSG="Redis: 已通过可执行文件 $FOUND_EXE 启动（携带 env.json 端口 $REDIS_PORT，循环探测确认）"
      else
        REDIS_STATUS="警告"; REDIS_MSG="Redis: 可执行文件 $FOUND_EXE 启动超时或失败，请等待数秒后重试，或手动检查 redis 日志；请注意本次为兜底启动，请核对实例端口/口令与 env.json 配置一致性；若为权限问题请使用 sudo"
      fi
    fi
  fi
  print_result "$REDIS_STATUS" "$REDIS_MSG"
fi

# ========== 7. Nacos：运行检测与启动（F-006/F-007，启动顺序第三位） ==========
echo ""
echo "━━━ Nacos（运行检测 → 启动 → 循环 HTTP 探测确认） ━━━"
NACOS_ADDR_VALID=false
if [[ "$NACOS_ADDR" =~ ^[^:]+:[0-9]+$ ]]; then NACOS_ADDR_VALID=true; fi
NACOS_STARTUP="${NACOS_HOME:-}/bin/startup.sh"
if [ "$NACOS_ADDR_VALID" = false ]; then
  # 地址格式非法：计入失败，不尝试启动
  print_result "失败" "Nacos: 地址格式非法（$NACOS_ADDR），请检查 env.json 中 NACOS_ADDR（应为 host:port）"
elif [ -z "${NACOS_HOME:-}" ] || [ ! -d "$NACOS_HOME" ] || [ ! -f "$NACOS_STARTUP" ]; then
  # 未安装：不尝试启动，计入失败，继续后续流程
  print_result "失败" "Nacos: 未安装，请先安装（NACOS_HOME 目录或 bin/startup.sh 不存在: ${NACOS_HOME:-空}）"
elif probe_nacos_up; then
  # 已运行：幂等跳过，不重复启动
  print_result "通过" "Nacos: 已运行（HTTP 探测或 java 进程含 nacos），幂等跳过"
else
  echo "  Nacos: 未运行，尝试启动..."
  # 确保日志目录存在，启动日志落盘便于失败定位（不含口令类明文）
  LOG_DIR="$PROJECT_DIR/logs"
  mkdir -p "$LOG_DIR" 2>/dev/null || true
  # 执行 startup.sh -m standalone（standalone 单机模式），nohup 后台运行并保留日志
  nohup bash "$NACOS_STARTUP" -m standalone >"$LOG_DIR/nacos-start.log" 2>&1 &
  if wait_for_service probe_nacos_up; then
    print_result "通过" "Nacos: 启动成功（startup.sh -m standalone，HTTP 探测确认）"
  else
    print_result "警告" "Nacos: 启动超时，请等待数秒后重试，或手动检查 $LOG_DIR/nacos-start.log 与 Nacos logs/start.out；若端口 8848 被占用请排查 ss -ltnp"
  fi
fi

# ========== 8. 汇总与退出码（F-011） ==========
echo ""
echo "=============================================="
echo -e "  基础设施启动完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  echo -e "  基础设施（MariaDB/Redis/Nacos）全部可达，可启动后端服务（deploy-start-all）。"
fi
echo "=============================================="

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}存在失败项，请按上述提示处理后重新运行。${NC}"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo -e "\n${YELLOW}存在警告项，请关注启动超时/待处理服务（警告不阻断部署）。${NC}"
  exit 0
else
  echo -e "\n${GREEN}基础设施全部就绪。${NC}"
  exit 0
fi
