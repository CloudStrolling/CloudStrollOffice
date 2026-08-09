#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 客户端一键编译脚本 (Bash)
# 说明: 调用客户端工程内官方构建脚本 (cloudoffice-flutter-app/build-release.sh)，
#       构建 Flutter 客户端（Windows/Web），最终产物落位
#       deploy/cloudoffice-flutter-app/（唯一落点）。构建缓存 (build/)
#       与过程文件不进入 deploy（对应 PRD F-003/F-004，验收 AC-3/AC-4）
# 用法: ./deploy/scripts/build-client.sh             # 构建 Windows + Web
#       ./deploy/scripts/build-client.sh web         # 仅构建 Web
#       ./deploy/scripts/build-client.sh windows     # 仅构建 Windows
# ============================================================

set -euo pipefail

PLATFORM="${1:-all}"

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # deploy/scripts
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"                         # deploy
PROJECT_DIR="$(dirname "$DEPLOY_DIR")"                        # 项目根
CLIENT_DIR="$PROJECT_DIR/cloudoffice-flutter-app"             # 客户端工程
CLIENT_DEPLOY_DIR="$DEPLOY_DIR/cloudoffice-flutter-app"       # 客户端产物落点

# ========== 前置检查：deploy 目录必须已存在 ==========
if [ ! -d "$DEPLOY_DIR" ]; then
  echo "[错误] deploy 目录不存在: $DEPLOY_DIR"
  exit 1
fi

# ========== 前置检查：客户端工程与构建脚本存在 ==========
BUILD_SCRIPT="$CLIENT_DIR/build-release.sh"
if [ ! -f "$BUILD_SCRIPT" ]; then
  echo "[错误] 未找到客户端构建脚本: $BUILD_SCRIPT"
  exit 1
fi

# ========== 前置检查：flutter 命令可用 ==========
if ! command -v flutter >/dev/null 2>&1; then
  echo "[错误] 未找到 flutter 命令，请安装 Flutter 3.x 并配置 PATH"
  exit 1
fi

echo "=============================================="
echo "  云漫智企 - 客户端一键编译"
echo "  平台:     $PLATFORM"
echo "  产物落点: $CLIENT_DEPLOY_DIR"
echo "=============================================="

# ========== 调用客户端官方构建脚本（构建 + 产物复制一步完成） ==========
"$BUILD_SCRIPT" "$PLATFORM"

# ========== 校验最终产物落位（按平台校验对应子目录） ==========
MISSING=""
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "windows" ]; then
  [ ! -f "$CLIENT_DEPLOY_DIR/windows/cloudoffice_flutter_app.exe" ] && MISSING="$MISSING windows/cloudoffice_flutter_app.exe"
fi
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "web" ]; then
  [ ! -f "$CLIENT_DEPLOY_DIR/web/index.html" ] && MISSING="$MISSING web/index.html"
fi

if [ -n "$MISSING" ]; then
  echo "[错误] 以下客户端产物未出现在 deploy 目录:$MISSING"
  exit 1
fi

echo ""
echo "=============================================="
echo "  客户端编译完成，全部最终产物已输出至 deploy"
echo "    deploy/cloudoffice-flutter-app/"
echo "=============================================="
