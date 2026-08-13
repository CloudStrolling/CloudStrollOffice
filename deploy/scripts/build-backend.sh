#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 后端一键编译脚本 (Bash)
# 说明: 在项目根目录执行 Maven 多模块 clean package，构建
#       common/gateway/auth/biz/system 五个服务，最终可执行
#       jar 由各模块 maven-antrun-plugin 自动复制至 deploy 目录
#       （唯一落点）。中间产物（各模块 target/）不进入 deploy
#       （对应 PRD F-002/F-004/F-007，验收 AC-2/AC-4；
#       v0.2.8 新增 cloudoffice-common 服务化产物输出）
# 用法: ./deploy/scripts/build-backend.sh            # 跳过测试（默认）
#       ./deploy/scripts/build-backend.sh --run-tests # 执行测试
# ============================================================

set -euo pipefail

RUN_TESTS=0
if [ "${1:-}" = "--run-tests" ]; then
  RUN_TESTS=1
fi

# ========== 路径定位（基于脚本自身目录推导，无硬编码绝对路径） ==========
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # deploy/scripts
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"                         # deploy
PROJECT_DIR="$(dirname "$DEPLOY_DIR")"                        # 项目根

# ========== 前置检查：deploy 目录必须已存在 ==========
if [ ! -d "$DEPLOY_DIR" ]; then
  echo "[错误] deploy 目录不存在: $DEPLOY_DIR"
  exit 1
fi

# ========== 前置检查：mvn 命令可用 ==========
if ! command -v mvn >/dev/null 2>&1; then
  echo "[错误] 未找到 mvn 命令，请安装 Maven 3.8+ 并配置 PATH"
  exit 1
fi

# ========== 构建命令 ==========
MVN_ARGS=("-f" "$PROJECT_DIR/pom.xml" "clean" "package")
if [ "$RUN_TESTS" = "0" ]; then
  MVN_ARGS+=("-DskipTests")
fi

echo "=============================================="
echo "  云漫智企 - 后端一键编译"
echo "  项目根: $PROJECT_DIR"
echo "  命令:   mvn ${MVN_ARGS[*]}"
echo "=============================================="

mvn "${MVN_ARGS[@]}"

# ========== 校验最终产物落位 deploy（5 个服务 jar 必须齐全，v0.2.8 新增 common） ==========
MISSING=""
for jar in cloudoffice-common.jar cloudoffice-gateway.jar cloudoffice-auth-service.jar \
           cloudoffice-biz-service.jar cloudoffice-system-service.jar; do
  if [ ! -f "$DEPLOY_DIR/$jar" ]; then
    MISSING="$MISSING $jar"
  fi
done

if [ -n "$MISSING" ]; then
  echo "[错误] 以下产物未出现在 deploy 目录:$MISSING"
  exit 1
fi

echo ""
echo "=============================================="
echo "  后端编译完成，5 个服务 jar 已输出至 deploy"
for jar in cloudoffice-common.jar cloudoffice-gateway.jar cloudoffice-auth-service.jar \
           cloudoffice-biz-service.jar cloudoffice-system-service.jar; do
  echo "    deploy/$jar"
done
echo "=============================================="
