#!/bin/bash
# ============================================================
# 从 env.json 加载环境变量 (Bash)
# 依赖: jq (优先) 或 python3 (回退)
# 用法: source scripts/load-env.sh [env.json]
# ============================================================

ENV_FILE="${1:-env.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"

if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "错误: 环境配置文件不存在: $ENV_FILE_PATH" >&2
  return 1
fi

# 方法1: 使用 jq
if command -v jq &>/dev/null; then
  eval "$(jq -r 'to_entries | .[] | "export \(.key)=\(.value | @sh)"' "$ENV_FILE_PATH")"
  echo "环境变量已从 $ENV_FILE_PATH 加载 (jq)"
  return 0
fi

# 方法2: 使用 python3
if command -v python3 &>/dev/null; then
  eval "$(python3 -c "
import json, shlex
with open('$ENV_FILE_PATH') as f:
    data = json.load(f)
for k, v in data.items():
    print(f'export {k}={shlex.quote(str(v))}')
")"
  echo "环境变量已从 $ENV_FILE_PATH 加载 (python3)"
  return 0
fi

echo "错误: 需要 jq 或 python3 来解析 JSON 配置文件" >&2
return 1
