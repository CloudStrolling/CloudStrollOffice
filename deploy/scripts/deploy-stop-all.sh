#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-stop-all.sh - 后端服务一键停止脚本 (Bash)
# 版本: v0.2.8
# 说明:
#   基于 deploy/env.json（经 load-env 统一加载，F-001）停止 deploy-start-all 启动的全部服务（F-008 逆操作）：
#     1. 停止顺序与启动相反：system(9400) → biz(9200) → auth(9100) → gateway(9000) → common(9300)，
#       common 在所有后端服务中最后停止（v0.2.8 F-009，确保其他服务停止过程中仍可访问配置接口）；
#     2. 停止方式：优先读取 deploy/logs/{name}.pid 记录的 PID，校验进程命令行含 jar 名后 kill (SIGTERM)，
#        轮询等待进程退出（默认超时 30 秒/间隔 2 秒），超时 kill -9 (SIGKILL)；
#        PID 文件缺失或进程不存在视为已停止（幂等通过）；
#        进程定位回退：pgrep -f 命令行含 jar 名；
#     3. 停止 Nacos（部署链路启动的基础设施，F-007 逆操作）：执行 NACOS_HOME/bin/shutdown.sh 停止，
#        失败回退按 java 进程含 nacos 定位停止；
#     4. 明确不停止 Redis / MySQL / MariaDB（数据库基础设施，F-006 保持运行）。
#   输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
#   安全约定：口令/密钥不打印明文。
#   可配置环境变量：STOP_TIMEOUT（默认 30）、RETRY_INTERVAL（默认 2）。
# 用法: ./deploy/scripts/deploy-stop-all.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 可配置参数（环境变量覆盖，默认值符合 F-008 逆操作契约：30 秒/间隔 2 秒）
STOP_TIMEOUT="${STOP_TIMEOUT:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-2}"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 返回非零并透传退出码） ==========
source "$SCRIPT_DIR/load-env.sh" || exit $?

# ========== 1. 全局计数、服务结果与输出辅助（F-011 输出分级） ==========
PASS=0
WARN=0
FAIL=0
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
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

# 按 jar 名定位 java 进程（回退定位，返回第一个命中的 PID；未命中返回空）
find_java_pid_by_jar() {
  local jar="$1"
  pgrep -f "$jar" 2>/dev/null | head -n1 || true
}

# 等待进程退出：超时上限内每间隔探测一次，进程消失返回 0（F-008 逆操作，不报假成功）
wait_for_proc_gone() {
  local pid="$1" timeout="$2" interval="$3" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if ! kill -0 "$pid" 2>/dev/null; then return 0; fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

# Nacos HTTP 探测：http://NACOS_ADDR/nacos/ 响应含 Nacos（F-005/F-006/F-007）
nacos_http_ok() {
  curl -s --max-time 5 "http://$NACOS_ADDR/nacos/" 2>/dev/null | grep -q "Nacos"
}

# Nacos 运行状态探测：HTTP 探测为主 + java 进程含 nacos 辅助
probe_nacos_up() {
  if nacos_http_ok; then return 0; fi
  if pgrep -f "nacos" &>/dev/null; then return 0; fi
  return 1
}

# 等待服务关闭：超时上限内每间隔探测一次，探测返回非零（未运行）即成功（不报假成功）
wait_for_down() {
  local fn="$1" timeout="$2" interval="$3" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if ! "$fn"; then return 0; fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

# ========== 2. 服务清单（停止顺序与启动相反：system → biz → auth → gateway → common，F-008 逆操作；common 最后停止 v0.2.8 F-009） ==========
# 字段：名称 | jar 文件名 | 端口
SERVICES=(
  "system|cloudoffice-system-service.jar|9400"
  "biz|cloudoffice-biz-service.jar|9200"
  "auth|cloudoffice-auth-service.jar|9100"
  "gateway|cloudoffice-gateway.jar|9000"
  "common|cloudoffice-common.jar|9300"
)

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) 后端服务一键停止"
  echo "  版本: v0.2.8"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. 停止 5 个后端服务（system → biz → auth → gateway → common，按 PID 文件 + 命令行校验，回退按 jar 名定位；common 最后停止 v0.2.8 F-009） ==========
LOG_DIR="$PROJECT_DIR/logs"

for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name jar port <<< "$entry"
  echo ""
  echo "━━━ 停止 $name（端口 $port） ━━━"
  PID_FILE="$LOG_DIR/$name.pid"
  TARGET_PID=""

  # 4.1 优先：读取 PID 文件并校验进程命令行含 jar 名（避免误杀无关进程）
  if [ -f "$PID_FILE" ]; then
    PID_VALUE="$(tr -d '[:space:]' < "$PID_FILE" 2>/dev/null || true)"
    if [[ "$PID_VALUE" =~ ^[0-9]+$ ]] && kill -0 "$PID_VALUE" 2>/dev/null; then
      if tr '\0' ' ' < "/proc/$PID_VALUE/cmdline" 2>/dev/null | grep -q "$jar"; then
        TARGET_PID="$PID_VALUE"
      fi
    fi
  fi

  # 4.2 回退：java 进程命令行含 jar 名定位
  if [ -z "$TARGET_PID" ]; then
    TARGET_PID="$(find_java_pid_by_jar "$jar")"
  fi

  # 4.3 未命中：视为已停止（幂等通过）
  if [ -z "$TARGET_PID" ]; then
    SERVICE_RESULTS["$name"]="通过"
    print_result "通过" "$name: 未在运行（PID 文件/进程均未命中），幂等跳过"
    continue
  fi

  # 4.4 停止进程：kill (SIGTERM) 优雅停止，等待退出，超时 kill -9 (SIGKILL)
  if kill "$TARGET_PID" 2>/dev/null; then
    if wait_for_proc_gone "$TARGET_PID" "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
      SERVICE_RESULTS["$name"]="通过"
      print_result "通过" "$name: 已停止（PID $TARGET_PID，进程已退出）"
    else
      kill -9 "$TARGET_PID" 2>/dev/null || true
      if wait_for_proc_gone "$TARGET_PID" "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
        SERVICE_RESULTS["$name"]="通过"
        print_result "通过" "$name: 已停止（PID $TARGET_PID，SIGKILL 强杀退出）"
      else
        SERVICE_RESULTS["$name"]="失败"
        print_result "失败" "$name: 进程 $TARGET_PID 停止超时（SIGTERM/SIGKILL 后仍运行），请手动执行 kill -9 $TARGET_PID 排查"
      fi
    fi
  else
    SERVICE_RESULTS["$name"]="失败"
    print_result "失败" "$name: 发送 SIGTERM 失败（PID $TARGET_PID 已退出或权限不足），请手动检查"
  fi
done

# ========== 5. 停止 Nacos（部署链路启动的基础设施，F-007 逆操作；不停止 Redis/MySQL/MariaDB） ==========
echo ""
echo "━━━ 停止 Nacos（基础设施，NACOS_ADDR: $NACOS_ADDR） ━━━"
if ! probe_nacos_up; then
  SERVICE_RESULTS["nacos"]="通过"
  print_result "通过" "Nacos: 未在运行（HTTP 探测或 java 进程含 nacos 未命中），幂等跳过"
else
  NACOS_SHUTDOWN="$NACOS_HOME/bin/shutdown.sh"
  if [ -f "$NACOS_SHUTDOWN" ]; then
    bash "$NACOS_SHUTDOWN" >/dev/null 2>&1 || true
  else
    echo "  Nacos: shutdown.sh 不存在（$NACOS_SHUTDOWN），回退按 java 进程含 nacos 定位停止"
  fi
  if wait_for_down probe_nacos_up "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
    SERVICE_RESULTS["nacos"]="通过"
    print_result "通过" "Nacos: 已停止（shutdown.sh，HTTP/进程探测确认）"
  else
    # 回退：强杀 java 进程含 nacos
    pkill -f "nacos" 2>/dev/null || true
    if wait_for_down probe_nacos_up "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
      SERVICE_RESULTS["nacos"]="通过"
      print_result "通过" "Nacos: 已通过进程强杀停止"
    else
      SERVICE_RESULTS["nacos"]="失败"
      print_result "失败" "Nacos: 停止超时（shutdown.sh 与强杀均未生效），请手动执行 $NACOS_SHUTDOWN 排查"
    fi
  fi
fi

# ========== 6. 汇总与退出码（F-008/F-011：全部成功退出 0，任一失败退出 1） ==========
echo ""
echo "=============================================="
echo -e "  后端服务一键停止完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
echo "  各服务停止结果："
for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name jar port <<< "$entry"
  status="${SERVICE_RESULTS[$name]:-未执行}"
  case "$status" in
    通过) echo -e "    - ${GREEN}$name（端口 $port）: 通过${NC}" ;;
    失败) echo -e "    - ${RED}$name（端口 $port）: 失败${NC}" ;;
    *)    echo -e "    - ${YELLOW}$name（端口 $port）: 未执行${NC}" ;;
  esac
done
NACOS_STATUS="${SERVICE_RESULTS[nacos]:-未执行}"
case "$NACOS_STATUS" in
  通过) echo -e "    - ${GREEN}Nacos: 通过${NC}" ;;
  失败) echo -e "    - ${RED}Nacos: 失败${NC}" ;;
  *)    echo -e "    - ${YELLOW}Nacos: 未执行${NC}" ;;
esac
echo "=============================================="
echo ""
echo -e "  ${CYAN}Redis / MySQL / MariaDB 数据库基础设施保持运行（不在本脚本停止范围）。${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}存在失败项，请按上述提示处理后重试。${NC}"
  exit 1
else
  echo -e "\n${GREEN}全部服务已停止。${NC}"
  exit 0
fi
