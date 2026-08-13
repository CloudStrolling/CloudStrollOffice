#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-start-all.sh - 后端服务按序一键启动脚本 (Bash)
# 版本: v0.2.8
# 说明:
#  基于 deploy/env.json（经 load-env 统一加载，F-001）执行（F-008）：
#     1. 前置校验：JDK 可用 + 5 个 jar 包存在（含 cloudoffice-common.jar）+ 各服务关键环境变量就绪
#        （任一缺失输出缺失项与处理提示，以非零码退出且不启动任何服务）
#     2. Nacos 运行状态检测：不在运行则启动（F-006/F-007，后端注册依赖），
#        启动失败/超时以非零码退出且不启动任何服务
#     3. 按 common(9300) → gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序后台启动：
#        java -Xms256m -Xmx512m -jar <jar>
#        （nohup 忽略挂断信号后台运行，日志落位 deploy/logs/{module}-start.log，
#        PID 记录 deploy/logs/{module}.pid）
#     4. 每个服务启动后健康确认：HTTP 直连自身端口（gateway GET http://localhost:9000/、
#        common GET http://localhost:{port}/api/v1/common/health、
#        auth/biz/system GET http://localhost:{port}/api/v1/{module}/health），端口探测备用；
#        循环轮询（可配置重试次数/间隔/单次超时，默认 30 次/2 秒/3 秒），
#        确认成功后再启动下一个服务；common 最先启动且健康确认成功后再启动 gateway（v0.2.8 ADR-019）
#     5. 任一步骤失败即停：输出明确错误提示（端口被占用提示检查 9000/9100/9200/9400/9300 等），
#        停止后续启动，退出非零
#     6. 全部成功输出 5 个服务启动结果与健康状态汇总，退出码 0
#   输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
#   安全约定：口令/密钥不打印明文（DB_PASSWORD / RSA_* 仅校验非空，缺失提示只列键名）。
#   可配置环境变量：RETRY_COUNT（默认 30）、RETRY_INTERVAL（默认 2）、PROBE_TIMEOUT（默认 3）。
# 用法: ./deploy/scripts/deploy-start-all.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 可配置参数（环境变量覆盖，默认值符合 F-008 契约：30 次/2 秒/3 秒）
RETRY_COUNT="${RETRY_COUNT:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"
PROBE_TIMEOUT="${PROBE_TIMEOUT:-3}"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 返回非零并透传退出码） ==========
source "$SCRIPT_DIR/load-env.sh" || exit $?

# ========== 1. 全局计数、服务结果与输出辅助（F-011 输出分级） ==========
PASS=0
WARN=0
FAIL=0
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
declare -A SERVICE_RESULTS

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

# TCP 端口可达性探测（bash 内置 /dev/tcp，timeout 防挂起；健康确认的备用方案 F-008）
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
# （curl 默认不因 HTTP 错误码失败，仅传输层错误返回非零；F-008 健康确认首选）
http_ok() {
  local url="$1" timeout="${2:-3}"
  curl -s -m "$timeout" -o /dev/null "$url" 2>/dev/null
}

# 健康确认轮询：重试次数上限内每间隔探测一次，HTTP 优先、TCP 端口探测备用（F-008，不报假成功）
wait_health_up() {
  local url="$1" port="$2" retries="$3" interval="$4" timeout="$5" i
  for ((i = 0; i < retries; i++)); do
    if http_ok "$url" "$timeout"; then return 0; fi
    if tcp_port_open "localhost" "$port"; then return 0; fi
    sleep "$interval"
  done
  return 1
}

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006/F-007）
nacos_http_ok() {
  curl -s --max-time 5 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"
}

# Nacos 运行状态探测：HTTP 探测为主 + java 进程含 nacos 辅助（F-006）
probe_nacos_up() {
  if nacos_http_ok; then return 0; fi
  if pgrep -f "nacos" &>/dev/null; then return 0; fi
  return 1
}

# Nacos 启动后循环探测确认：超时上限内每间隔探测一次，
# HTTP 探测 + gRPC 端口（NACOS 端口 +1000，客户端注册走 gRPC）均就绪才判定启动完成（F-007，不报假成功）
wait_nacos_up() {
  local timeout="$1" interval="$2" elapsed=0 grpc_port
  grpc_port=$((NACOS_PORT + 1000))
  while [ "$elapsed" -lt "$timeout" ]; do
    if nacos_http_ok && tcp_port_open "localhost" "$grpc_port"; then return 0; fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

# ========== 2. 服务清单（数组顺序即启动顺序契约：common → gateway → auth → biz → system，SAD 部署顺序；common 最先启动 v0.2.8 ADR-019） ==========
# 字段：名称 | jar 文件名 | 端口 | 健康检查 URL | 关键环境变量(逗号分隔) | 失败排查提示
# common 端口读 COMMON_PORT 环境变量（TASK-009 加入 env.json；缺省 9300）
COMMON_PORT="${COMMON_PORT:-9300}"
SERVICES=(
  "common|cloudoffice-common.jar|$COMMON_PORT|http://localhost:$COMMON_PORT/api/v1/common/health|NACOS_ADDR,COMMON_PORT,DB_PASSWORD|请检查 COMMON_PORT/DB_PASSWORD 配置"
  "gateway|cloudoffice-gateway.jar|9000|http://localhost:9000/|NACOS_ADDR,RSA_PUBLIC_KEY|请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"
  "auth|cloudoffice-auth-service.jar|9100|http://localhost:9100/api/v1/auth/health|NACOS_ADDR,RSA_PUBLIC_KEY,RSA_PRIVATE_KEY,DB_PASSWORD|请检查 RSA 密钥对/DB_PASSWORD 配置"
  "biz|cloudoffice-biz-service.jar|9200|http://localhost:9200/api/v1/biz/health|NACOS_ADDR,DB_PASSWORD|请检查 DB_PASSWORD 配置"
  "system|cloudoffice-system-service.jar|9400|http://localhost:9400/api/v1/system/health|NACOS_ADDR,DB_PASSWORD|请检查 DB_PASSWORD 配置"
)

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) 后端服务按序一键启动"
echo "  版本: v0.2.8"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. 前置校验（JDK / 5 个 jar / 关键环境变量；任一缺失→列出缺失项+处理提示→非零退出→不启动任何服务） ==========
echo "━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━"
PRECHECK_FAIL=0

# 4.1 JDK 可用性（java 命令存在即可，版本/安装完整检查由 deploy-check-env 承担）
if has_cmd java; then
  print_result "通过" "JDK: java 命令可用"
else
  print_result "失败" "JDK: 未检测到 java 命令，请安装 JDK 21 并配置 PATH/JAVA_HOME"
  PRECHECK_FAIL=1
fi

# 4.2 5 个 jar 包存在性 + 各服务关键环境变量（缺失只列键名，不打印值）
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name jar port url vars hint <<< "$entry"
  if [ ! -f "$PROJECT_DIR/$jar" ]; then
    print_result "失败" "$name: jar 包缺失（$PROJECT_DIR/$jar），请执行 build-backend 构建后将 jar 落位 deploy 目录"
    PRECHECK_FAIL=1
  fi
  IFS=',' read -ra var_list <<< "$vars"
  for v in "${var_list[@]}"; do
    if [ -z "${!v:-}" ]; then
      print_result "失败" "$name: 关键环境变量 $v 缺失或为空，请在 env.json 中配置相应键（不打印值）"
      PRECHECK_FAIL=1
    fi
  done
done

if [ "$PRECHECK_FAIL" -ne 0 ]; then
  echo ""
  echo -e "${RED}  前置校验未通过：请按上述缺失项处理（构建/落位 jar、配置 env.json）后重新运行。${NC}"
  echo -e "${RED}  本次未启动任何服务。${NC}"
  exit 1
fi
echo ""
print_result "通过" "前置校验：5 个 jar 包与关键环境变量全部就绪"

# ========== 5. Nacos 运行状态检测与启动（F-006/F-007：后端注册依赖，不在运行则启动） ==========
LOG_DIR="$PROJECT_DIR/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
NACOS_LOG_FILE="$LOG_DIR/nacos-start.log"

echo ""
echo "━━━ Nacos（运行检测 → 未运行则启动 → 循环探测确认） ━━━"
NACOS_ADDR_VALID=false
if [[ "$NACOS_ADDR" =~ ^[^:]+:[0-9]+$ ]]; then NACOS_ADDR_VALID=true; fi
NACOS_STARTUP="${NACOS_HOME:-}/bin/startup.sh"
NACOS_PORT="$(echo "$NACOS_ADDR" | awk -F: '{print $2}')"
if [ "$NACOS_ADDR_VALID" = false ]; then
  # 地址格式非法：计入失败，不尝试启动，退出非零（后端注册依赖 Nacos）
  print_result "失败" "Nacos: 地址格式非法（$NACOS_ADDR），请检查 env.json 中 NACOS_ADDR（应为 host:port）"
  echo -e "${RED}  Nacos 不可用（后端服务注册依赖 Nacos），本次不启动任何服务。${NC}"
  exit 1
elif [ -z "${NACOS_HOME:-}" ] || [ ! -d "$NACOS_HOME" ] || [ ! -f "$NACOS_STARTUP" ]; then
  # 未安装：不尝试启动，计入失败，退出非零（后端注册依赖 Nacos）
  print_result "失败" "Nacos: 未安装，请先安装（NACOS_HOME 目录或 bin/startup.sh 不存在: ${NACOS_HOME:-空}）"
  echo -e "${RED}  Nacos 不可用（后端服务注册依赖 Nacos），本次不启动任何服务。${NC}"
  exit 1
elif probe_nacos_up; then
  # 已运行：幂等跳过，不重复启动
  print_result "通过" "Nacos: 已运行（HTTP 探测或 java 进程含 nacos），幂等跳过"
else
  echo "  Nacos: 未运行，尝试启动..."
  # 执行 startup.sh -m standalone（standalone 单机模式），nohup 后台运行并保留日志
  nohup bash "$NACOS_STARTUP" -m standalone >"$NACOS_LOG_FILE" 2>&1 &
  if wait_nacos_up "$((RETRY_COUNT * RETRY_INTERVAL))" "$RETRY_INTERVAL"; then
    print_result "通过" "Nacos: 启动成功（startup.sh -m standalone，HTTP 探测确认）"
  else
    print_result "失败" "Nacos: 启动超时，请手动检查 $NACOS_LOG_FILE 与 Nacos logs/start.out；若端口 $NACOS_PORT 被占用请排查 ss -ltnp"
    echo -e "${RED}  Nacos 不可用（后端服务注册依赖 Nacos），本次不启动任何服务。${NC}"
    exit 1
  fi
fi

# ========== 6. 按序启动 + 逐服务健康确认（common → gateway → auth → biz → system，确认成功后再启动下一个；common 健康确认成功后再启动 gateway） ==========
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name jar port url vars hint <<< "$entry"
  echo ""
  echo "━━━ 启动 $name（端口 $port） ━━━"
  JAR_PATH="$PROJECT_DIR/$jar"
  LOG_FILE="$LOG_DIR/$name-start.log"
  PID_FILE="$LOG_DIR/$name.pid"
  # Linux 后台启动：nohup 忽略挂断信号，stdout/stderr 合并落盘，$! 记录后台进程 PID
  nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo "  java 已后台启动（PID: $(cat "$PID_FILE")），日志: $LOG_FILE"
  # 健康确认：HTTP 直连自身端口优先、TCP 端口探测备用；确认成功后再启动下一个服务
  if wait_health_up "$url" "$port" "$RETRY_COUNT" "$RETRY_INTERVAL" "$PROBE_TIMEOUT"; then
    SERVICE_RESULTS["$name"]="通过"
    print_result "通过" "$name: 已启动且健康确认成功（$url）"
  else
    SERVICE_RESULTS["$name"]="失败"
    print_result "失败" "$name: 健康确认超时（重试 $RETRY_COUNT 次/间隔 $RETRY_INTERVAL 秒后仍无响应）。可能原因：端口 $port 被占用（请检查 9000/9100/9200/9400/9300）、服务启动失败或依赖未就绪；请查看日志 $LOG_FILE；$hint"
    break
  fi
done

# ========== 7. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
echo ""
echo "=============================================="
echo -e "  后端服务一键启动完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
echo "  各服务启动结果与健康状态："
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name jar port url vars hint <<< "$entry"
  status="${SERVICE_RESULTS[$name]:-未执行}"
  case "$status" in
    通过) echo -e "    - ${GREEN}$name（端口 $port）: 通过${NC}" ;;
    失败) echo -e "    - ${RED}$name（端口 $port）: 失败${NC}" ;;
    *)    echo -e "    - ${YELLOW}$name（端口 $port）: 未执行${NC}" ;;
  esac
done
echo -e "    - ${GREEN}Nacos（端口 $NACOS_PORT）: 已就绪（见上节）${NC}"
echo "=============================================="

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}存在失败项（已按失败即停策略停止后续启动），请按上述提示处理后重新运行。${NC}"
  exit 1
else
  echo -e "\n${GREEN}Nacos 与 5 个后端服务（含 common）全部启动成功且健康确认通过。${NC}"
  exit 0
fi
