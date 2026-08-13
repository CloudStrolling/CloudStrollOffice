#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# deploy-stop-common.sh - Common 服务停止脚本 (Bash)
# 版本: v0.2.8
# 说明:
#   基于 deploy/env.json（经 load-env 统一加载，F-001）单服务停止 common 服务（v0.2.8 F-009，与 deploy-stop-all 中 common 停止逻辑一致）：
#     1. 停止方式：优先读取 deploy/logs/common.pid 记录的 PID，校验进程命令行含 cloudoffice-common.jar 后 kill (SIGTERM)，
#        轮询等待进程退出（默认超时 30 秒/间隔 2 秒），超时 kill -9 (SIGKILL)；
#        PID 文件缺失或进程不存在视为已停止（幂等通过）；
#        进程定位回退：pgrep -f 命令行含 cloudoffice-common.jar；
#     2. 不停止 Nacos / Redis / MySQL / MariaDB 基础设施（本脚本仅停止 common 单服务）。
#   输出分级（通过/警告/失败）与退出码约定（F-011）：全部通过退出 0；存在失败项退出 1。
#   安全约定：口令/密钥不打印明文。
#   可配置环境变量：STOP_TIMEOUT（默认 30）、RETRY_INTERVAL（默认 2）。
# 用法: ./deploy/scripts/deploy-stop-common.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 可配置参数（环境变量覆盖，默认值符合 v0.2.8 F-009 契约：30 秒/间隔 2 秒）
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

# 等待进程退出：超时上限内每间隔探测一次，进程消失返回 0（不报假成功）
wait_for_proc_gone() {
  local pid="$1" timeout="$2" interval="$3" elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    if ! kill -0 "$pid" 2>/dev/null; then return 0; fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

# ========== 2. 本服务契约（与 deploy-stop-all 中 common 子块一致，v0.2.8 F-009） ==========
SERVICE_NAME="common"
JAR_NAME="cloudoffice-common.jar"
SERVICE_PORT=9300

# ========== 3. 标题 ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) Common 服务停止"
echo "  版本: v0.2.8"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

# ========== 4. 停止 common 服务（按 PID 文件 + 命令行校验，回退按 jar 名定位；幂等跳过） ==========
LOG_DIR="$PROJECT_DIR/logs"
echo "━━━ 停止 $SERVICE_NAME（端口 $SERVICE_PORT） ━━━"
PID_FILE="$LOG_DIR/$SERVICE_NAME.pid"
TARGET_PID=""

# 4.1 优先：读取 PID 文件并校验进程命令行含 jar 名（避免误杀无关进程）
if [ -f "$PID_FILE" ]; then
  PID_VALUE="$(tr -d '[:space:]' < "$PID_FILE" 2>/dev/null || true)"
  if [[ "$PID_VALUE" =~ ^[0-9]+$ ]] && kill -0 "$PID_VALUE" 2>/dev/null; then
    if tr '\0' ' ' < "/proc/$PID_VALUE/cmdline" 2>/dev/null | grep -q "$JAR_NAME"; then
      TARGET_PID="$PID_VALUE"
    fi
  fi
fi

# 4.2 回退：java 进程命令行含 jar 名定位
if [ -z "$TARGET_PID" ]; then
  TARGET_PID="$(find_java_pid_by_jar "$JAR_NAME")"
fi

# 4.3 未命中：视为已停止（幂等通过）
if [ -z "$TARGET_PID" ]; then
  SERVICE_RESULTS["$SERVICE_NAME"]="通过"
  print_result "通过" "$SERVICE_NAME: 未在运行（PID 文件/进程均未命中），幂等跳过"
else
  # 4.4 停止进程：kill (SIGTERM) 优雅停止，等待退出，超时 kill -9 (SIGKILL)
  if kill "$TARGET_PID" 2>/dev/null; then
    if wait_for_proc_gone "$TARGET_PID" "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
      SERVICE_RESULTS["$SERVICE_NAME"]="通过"
      print_result "通过" "$SERVICE_NAME: 已停止（PID $TARGET_PID，进程已退出）"
    else
      kill -9 "$TARGET_PID" 2>/dev/null || true
      if wait_for_proc_gone "$TARGET_PID" "$STOP_TIMEOUT" "$RETRY_INTERVAL"; then
        SERVICE_RESULTS["$SERVICE_NAME"]="通过"
        print_result "通过" "$SERVICE_NAME: 已停止（PID $TARGET_PID，SIGKILL 强杀退出）"
      else
        SERVICE_RESULTS["$SERVICE_NAME"]="失败"
        print_result "失败" "$SERVICE_NAME: 进程 $TARGET_PID 停止超时（SIGTERM/SIGKILL 后仍运行），请手动执行 kill -9 $TARGET_PID 排查"
      fi
    fi
  else
    SERVICE_RESULTS["$SERVICE_NAME"]="失败"
    print_result "失败" "$SERVICE_NAME: 发送 SIGTERM 失败（PID $TARGET_PID 已退出或权限不足），请手动检查"
  fi
fi

# ========== 5. 汇总与退出码（F-011：全部成功退出 0，任一失败退出 1） ==========
echo ""
echo "=============================================="
echo -e "  Common 服务停止完成: ${GREEN}通过 $PASS 项${NC} | ${YELLOW}警告 $WARN 项${NC} | ${RED}失败 $FAIL 项${NC}"
STATUS="${SERVICE_RESULTS[$SERVICE_NAME]:-未执行}"
case "$STATUS" in
  通过) echo -e "    - ${GREEN}$SERVICE_NAME（端口 $SERVICE_PORT）: 通过${NC}" ;;
  失败) echo -e "    - ${RED}$SERVICE_NAME（端口 $SERVICE_PORT）: 失败${NC}" ;;
  *)    echo -e "    - ${YELLOW}$SERVICE_NAME（端口 $SERVICE_PORT）: 未执行${NC}" ;;
esac
echo "=============================================="
echo ""
echo -e "  ${CYAN}本脚本仅停止 common 单服务；Nacos / Redis / MySQL / MariaDB 基础设施保持运行。${NC}"

if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}存在失败项，请按上述提示处理后重试。${NC}"
  exit 1
else
  echo -e "\n${GREEN}Common 服务已停止。${NC}"
  exit 0
fi
