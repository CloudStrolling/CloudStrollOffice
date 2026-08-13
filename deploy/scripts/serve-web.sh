#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# serve-web.sh - Web 客户端一键启动脚本 (Bash)
# 版本: v0.2.7
# 说明:
#   使用 Python 内置 http.server 将 deploy/cloudoffice-flutter-app/web 作为静态站点启动：
#     1. 前置校验：python3 命令可用 + 站点目录存在
#     2. 端口来源：第一个参数 > env.json 的 WEB_SERVER_PORT > 默认 8080
#     3. 前台运行：python3 -m http.server <port> --bind 127.0.0.1 --directory <web目录>
#        Ctrl+C 停止（前台模式便于调试，日志实时输出到当前终端）
#   端口默认 8080（避开 gateway 9000 / auth 9100 / biz 9200 / system 9400）。
#   退出码约定（F-011）：前置校验失败退出 1；服务被 Ctrl+C 中断退出 0。
# 用法: ./deploy/scripts/serve-web.sh [端口]
#       默认端口取 env.json 的 WEB_SERVER_PORT，缺省回退 8080
# ============================================================

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

PORT="${1:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ========== 0. 加载环境配置（F-001，经 load-env 统一加载 env.json；缺失/关键配置缺失由 load-env 返回非零并透传退出码） ==========
source "$SCRIPT_DIR/load-env.sh" || exit $?

# ========== 1. 解析端口（参数 > WEB_SERVER_PORT > 默认 8080） ==========
if [ -z "$PORT" ]; then PORT="${WEB_SERVER_PORT:-}"; fi
if [ -z "$PORT" ]; then PORT=8080; fi

# ========== 2. 前置校验（python3 命令 / 站点目录） ==========
echo ""
echo "=============================================="
echo "  云漫智企 (CloudStrollOffice) Web 客户端一键启动"
echo "  日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo ""

FAIL=0
if ! command -v python3 >/dev/null 2>&1; then
  echo -e "  ${RED}[失败]${NC} 未找到 python3 命令，请安装 Python 3.8+ 并配置 PATH"
  FAIL=1
fi

WEB_DIR="$PROJECT_DIR/cloudoffice-flutter-app/web"
if [ ! -d "$WEB_DIR" ]; then
  echo -e "  ${RED}[失败]${NC} 站点目录不存在: $WEB_DIR（请先执行 build-client 构建客户端产物）"
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo -e "${RED}  前置校验未通过，请按上述缺失项处理后重新运行。${NC}"
  exit 1
fi
echo -e "  ${GREEN}[通过]${NC} 前置校验：python3 命令可用 + 站点目录存在"

# ========== 3. 启动静态站点（前台运行，Ctrl+C 停止） ==========
echo ""
echo -e "  ${CYAN}启动静态站点: http://127.0.0.1:$PORT/${NC}"
echo -e "  ${CYAN}站点目录: $WEB_DIR${NC}"
echo -e "  ${CYAN}按 Ctrl+C 停止服务。${NC}"
echo ""

# 后台不驻留，前台阻塞运行；bind 127.0.0.1 仅本机访问（如需局域网访问可改 0.0.0.0）
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$WEB_DIR"
# http.server 被 Ctrl+C 中断时退出码通常非零，此处归一化为 0（用户主动停止属预期行为）
exit 0
