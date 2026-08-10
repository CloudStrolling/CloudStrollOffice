#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-start-biz.sh - Biz Service 服务启动脚本 (Bash)
# 版本: v0.2.7
# 说明:
#   基于 deploy/env.json（经 load-env 统一加载，F-001）单服务启动企业服务（F-009）：
#     1. 前置校验：JDK 可用 + jar 包存在 + 本服务关键环境变量就绪
#        （任一缺失输出缺失项与处理提示，以非零码退出且不启动服务）
#     2. 后台启动：java -Xms256m -Xmx512m -jar <jar>
#        （nohup 忽略挂断信号后台运行，日志落位 deploy/logs/biz-start.log，
#        PID 记录 deploy/logs/biz.pid）
#     3. 健康确认：HTTP 直连自身端口（http://localhost:9200/api/v1/biz/health），端口探测备用；
#        循环轮询（可配置重试次数/间隔/单次超时，默认 30 次/2 秒/3 秒）
#     4. 任一步骤失败即停：输出明确错误提示，退出非零
#   行为与 deploy-start-all.sh 中 biz 服务启动逻辑一致（F-008/F-009）。
#   输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
#   安全约定：口令/密钥不打印明文（DB_PASSWORD 仅校验非空，缺失提示只列键名）。
#   可配置环境变量：RETRY_COUNT（默认 30）、RETRY_INTERVAL（默认 2）、PROBE_TIMEOUT（默认 3）。
# 用法: ./deploy/scripts/deploy-start-biz.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 可配置参数（环境变量覆盖，默认值符合 F-009 契约：30 次/2 秒/3 秒）
RETRY_COUNT="${RETRY_COUNT:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"
PROBE_TIMEOUT="${PROBE_TIMEOUT:-3}"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 返回非零并透传退出码） ==========
source "$SCRIPT_DIR/load-env.sh" || exit $?

# ========== 1. 全局计数与输出辅助（F-011 输出分级） ==========
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

# 命令是否存在
has_cmd() { command -v "$1" &>/dev/null; }

# TCP 端口可达性探测（bash 内置 /dev/tcp，timeout 防挂起；健康确认的备用方案 F-009）
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

# HTTP 存活探测：任一 HTTP 响应（含 404/401/500）即认为服务已启动
# （curl 默认不因 HTTP 错误码失败，仅传输层错误返回非零；F-009 健康确认首选）
http_ok() {
  local url="$1" timeout="${2:-3}"
  curl -s -m "$timeout" -o /dev/null "$url" 2>/dev/null
}

# 健康确认轮询：重试次数上限内每间隔探测一次，HTTP 优先、TCP 端口探测备用（F-009，不报假成功）
wait_health_up() {
  local url="$1" port="$2" retries="$3" interval="$4" timeout="$5" i
  for ((i = 0; i < retries; i++)); do
    if http_ok "$url" "$timeout"; then return 0; fi
    if tcp_port_open "localhost" "$port"; then return 0; fi
    sleep "$interval"
  done
  return 1
}

# ========== 2. 本服务契约（与 deploy-start-all.sh 中 biz 子块一致，F-009） ==========
# 服务标识（用于日志/PID 命名）与 jar 文件名
SERVICE_NAME="biz"
JAR_NAME="cloudoffice-biz-service.jar"
SERVICE_PORT=9200
HEALTH_URL="http://localhost:9200/api/v1/biz/health"
# 本服务关键环境变量（F-009 契约表）：缺失只列键名，不打印值
# 注意：biz-service 使用 DB_USER（区别于 auth-service 的 DB_USERNAME，差异保持现状）；
#       DB_USER 由服务自身读取，按契约表不参与本脚本启动校验。
REQUIRED_VARS=(NACOS_ADDR DB_PASSWORD)
MISSING_HINT="请检查 DB_PASSWORD 配置"

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) Biz Service 服务启动"
echo "  版本: v0.2.7"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. 前置校验（JDK / jar 包 / 关键环境变量；任一缺失→列出缺失项+处理提示→非零退出→不启动服务） ==========
echo "━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━"
PRECHECK_FAIL=0

# 4.1 JDK 可用性（java 命令存在即可，版本/安装完整检查由 deploy-check-env 承担）
if has_cmd java; then
  print_result "通过" "JDK: java 命令可用"
else
  print_result "失败" "JDK: 未检测到 java 命令，请安装 JDK 21 并配置 PATH/JAVA_HOME"
  PRECHECK_FAIL=1
fi

# 4.2 jar 包存在性（缺失提示构建并落位）
if [ ! -f "$PROJECT_DIR/$JAR_NAME" ]; then
  print_result "失败" "$SERVICE_NAME: jar 包缺失（$PROJECT_DIR/$JAR_NAME），请执行 build-backend 构建后将 jar 落位 deploy 目录"
  PRECHECK_FAIL=1
fi

# 4.3 本服务关键环境变量（缺失只列键名，不打印值）
for v in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!v:-}" ]; then
    print_result "失败" "$SERVICE_NAME: 关键环境变量 $v 缺失或为空，请在 env.json 中配置相应键（不打印值）"
    PRECHECK_FAIL=1
  fi
done

if [ "$PRECHECK_FAIL" -ne 0 ]; then
  echo ""
  echo -e "${RED}  前置校验未通过：$MISSING_HINT；请按上述缺失项处理（构建/落位 jar、配置 env.json）后重新运行。${NC}"
  echo -e "${RED}  本次未启动服务。${NC}"
  exit 1
fi
echo ""
print_result "通过" "前置校验：jar 包与关键环境变量全部就绪"

# ========== 5. 后台启动 + 健康确认（与 deploy-start-all.sh 中 biz 子块逻辑一致，F-009） ==========
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
JAR_PATH="$PROJECT_DIR/$JAR_NAME"
LOG_FILE="$LOG_DIR/$SERVICE_NAME-start.log"
PID_FILE="$LOG_DIR/$SERVICE_NAME.pid"

# Linux 后台启动：nohup 忽略挂断信号，stdout/stderr 合并落盘，$! 记录后台进程 PID
nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "  java 已后台启动（PID: $(cat "$PID_FILE")），日志: $LOG_FILE"

# 健康确认：HTTP 直连自身端口优先、TCP 端口探测备用（F-009）
if wait_health_up "$HEALTH_URL" "$SERVICE_PORT" "$RETRY_COUNT" "$RETRY_INTERVAL" "$PROBE_TIMEOUT"; then
  print_result "通过" "$SERVICE_NAME: 已启动且健康确认成功（$HEALTH_URL）"
else
  print_result "失败" "$SERVICE_NAME: 健康确认超时（重试 $RETRY_COUNT 次/间隔 $RETRY_INTERVAL 秒后仍无响应）。可能原因：端口 $SERVICE_PORT 被占用、服务启动失败或依赖未就绪；请查看日志 $LOG_FILE；$MISSING_HINT"
fi

# ========== 6. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
echo ""
echo "=============================================="
echo -e "  Biz Service 服务启动完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
echo "=============================================="
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}存在失败项，请按上述提示处理后重新运行。${NC}"
  exit 1
else
  echo -e "${GREEN}Biz Service 服务启动成功且健康确认通过。${NC}"
  exit 0
fi
