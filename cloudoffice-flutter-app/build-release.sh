#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) Flutter 客户端构建脚本 (Bash)
# 说明: 构建 Flutter 客户端（Windows/Web）并仅将最终可交付产物
#       复制到根目录 deploy；构建缓存 (build/) 与编译过程文件
#       不进入 deploy（对应 PRD F-003/F-004，验收 AC-3/AC-4）
# 用法: ./build-release.sh               # 构建 Windows + Web
#       ./build-release.sh web           # 仅构建 Web
#       ./build-release.sh windows       # 仅构建 Windows
# ============================================================

set -euo pipefail

PLATFORM="${1:-all}"

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # cloudoffice-flutter-app 工程根
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"                        # 项目根
DEPLOY_DIR="$PROJECT_DIR/deploy"                              # 最终产物统一落点
CLIENT_DEPLOY_DIR="$DEPLOY_DIR/cloudoffice-flutter-app"       # 客户端产物子目录

# ========== 切换工作目录到客户端工程根（flutter 命令需在工程根执行） ==========
# 本脚本以子进程方式被调用（build-client.sh 等），cd 不会影响调用方目录
cd "$SCRIPT_DIR"

# ========== 平台检测：Windows 原生构建需 Windows 环境（Git Bash/MSYS2/Cygwin） ==========
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1 ;;
  *) IS_WINDOWS=0 ;;
esac

# ========== 前置检查：deploy 目录必须已存在（TASK-001 已创建） ==========
if [ ! -d "$DEPLOY_DIR" ]; then
  echo "[错误] deploy 目录不存在: $DEPLOY_DIR"
  exit 1
fi

# ========== 依赖安装（构建前置步骤） ==========
echo "==> 执行 flutter pub get ..."
flutter pub get

# ========== Windows 平台构建（仅 Windows 环境可构建） ==========
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "windows" ]; then
  if [ "$IS_WINDOWS" != "1" ]; then
    echo "[提示] 当前非 Windows 环境，跳过 Windows 构建（请在 Windows 上执行 build-release.ps1）"
  else
    echo "==> 执行 flutter build windows --release ..."
    flutter build windows --release

    # Windows 最终产物目录（Flutter 3.16+ x64 架构化路径）
    RELEASE_DIR="$SCRIPT_DIR/build/windows/x64/runner/Release"
    if [ ! -d "$RELEASE_DIR" ]; then
      echo "[错误] 未找到 Windows 最终产物目录: $RELEASE_DIR"
      exit 1
    fi

    WIN_TARGET="$CLIENT_DEPLOY_DIR/windows"
    mkdir -p "$WIN_TARGET"
    # 仅复制最终产物文件（exe/dll/data），严禁整目录递归复制 build/（AC-4）
    cp -R "$RELEASE_DIR"/. "$WIN_TARGET"/
    echo "[完成] Windows 产物已输出: $WIN_TARGET"
  fi
fi

# ========== Web 平台构建（全平台可构建） ==========
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "web" ]; then
  echo "==> 执行 flutter build web --release ..."
  flutter build web --release

  # Web 最终产物目录（整体即为最终可交付部署包）
  WEB_DIR="$SCRIPT_DIR/build/web"
  if [ ! -d "$WEB_DIR" ]; then
    echo "[错误] 未找到 Web 最终产物目录: $WEB_DIR"
    exit 1
  fi

  WEB_TARGET="$CLIENT_DEPLOY_DIR/web"
  mkdir -p "$WEB_TARGET"
  # 仅复制最终 Web 部署包内容，build/web 之外的构建缓存不进入 deploy（AC-4）
  cp -R "$WEB_DIR"/. "$WEB_TARGET"/
  echo "[完成] Web 产物已输出: $WEB_TARGET"
fi

echo ""
echo "=============================================="
echo "  客户端构建完成，全部最终产物已输出至 deploy"
echo "=============================================="
