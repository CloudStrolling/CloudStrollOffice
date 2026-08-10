#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>
# ============================================================
# load-env.sh - 统一配置加载模块 (Bash)
#
# 功能（F-001 契约）：
#   1. 从 deploy/env.json 读取全部键值对并注入当前 shell 环境变量；
#   2. env.json 缺失时提示复制 deploy/env.example.json 为 env.json 并填写配置，返回非零；
#   3. 关键配置缺失时逐个列出缺失项（仅键名，不打印值），返回非零；
#   4. 脚本内不硬编码环境地址与凭据（全部经环境变量引用）。
#
# 用法：
#   source deploy/scripts/load-env.sh [env.json]
#   说明：本脚本为 source 型脚本，失败使用 return 而非 exit（避免终止父 shell）；
#         不得引入 set -e 等严格模式（避免污染父 shell 状态）。
#
# 安全约定：DB_PASSWORD / RSA_PRIVATE_KEY 等敏感值仅注入环境变量，
#           任何输出均不打印其明文（缺失校验仅输出键名）。
#
# 依赖：jq（优先）或 python3（回退）。
# ============================================================

ENV_FILE="${1:-env.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"
EXAMPLE_FILE_PATH="$PROJECT_DIR/env.example.json"

# env.json 缺失：提示复制模板并填写配置，返回非零
if [ ! -f "$ENV_FILE_PATH" ]; then
  echo "错误: 环境配置文件不存在: $ENV_FILE_PATH" >&2
  echo "请复制 $EXAMPLE_FILE_PATH 为 $ENV_FILE_PATH 并填写配置后重试。" >&2
  return 1
fi

# 选择解析器：jq 优先，python3 回退；解析失败返回非零
if command -v jq &>/dev/null; then
  # S-05 修复：键名合法性白名单校验（仅允许 [A-Za-z_][A-Za-z0-9_]*），
  # 非法键名直接报错退出（env.json 为运维本地受控文件，非法键名属配置错误）；
  # 输出时键名与值均经 @sh 转义，双重防注入
  if ! INVALID_KEYS="$(jq -r 'to_entries | .[].key | select(test("^[A-Za-z_][A-Za-z0-9_]*$") | not)' "$ENV_FILE_PATH" 2>/dev/null)"; then
    echo "错误: 解析 $ENV_FILE_PATH 失败 (jq)" >&2
    return 1
  fi
  if [ -n "$INVALID_KEYS" ]; then
    echo "错误: $ENV_FILE_PATH 含非法键名（仅允许字母/数字/下划线，首字符须为字母或下划线）：" >&2
    echo "$INVALID_KEYS" | sed 's/^/  - /' >&2
    return 1
  fi
  if ! EXPORT_CMDS="$(jq -r 'to_entries | .[] | "export \(.key | @sh)=\(.value | @sh)"' "$ENV_FILE_PATH" 2>&1)"; then
    echo "错误: 解析 $ENV_FILE_PATH 失败 (jq)" >&2
    return 1
  fi
  eval "$EXPORT_CMDS"
  LOADED_COUNT="$(jq -r 'length' "$ENV_FILE_PATH" 2>/dev/null)"
  LOADER_NAME="jq"
elif command -v python3 &>/dev/null; then
  # 路径经 argv 传入，避免拼接注入与引号问题；键名与值均经 shlex.quote 转义（S-05 修复）
  # 先捕获 stderr（键名非法等错误信息），仅解析成功时 eval stdout 内容
  PY_ERR="$(python3 -c '
import json, shlex, re, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for k, v in data.items():
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", k):
        print("错误: 环境配置文件含非法键名: {0}（仅允许字母/数字/下划线，首字符须为字母或下划线）".format(k), file=sys.stderr)
        sys.exit(2)
    print("export {0}={1}".format(k, shlex.quote(str(v))))
' "$ENV_FILE_PATH" 2>&1 >/dev/null)"
  if ! EXPORT_CMDS="$(python3 -c '
import json, shlex, re, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for k, v in data.items():
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", k):
        sys.exit(2)
    print("export {0}={1}".format(k, shlex.quote(str(v))))
' "$ENV_FILE_PATH" 2>/dev/null)"; then
    if [ -n "$PY_ERR" ]; then
      echo "$PY_ERR" >&2
    else
      echo "错误: 解析 $ENV_FILE_PATH 失败 (python3)" >&2
    fi
    return 1
  fi
  eval "$EXPORT_CMDS"
  LOADED_COUNT="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1], encoding="utf-8"))))' "$ENV_FILE_PATH" 2>/dev/null)"
  LOADER_NAME="python3"
else
  echo "错误: 需要 jq 或 python3 来解析 JSON 配置文件" >&2
  return 1
fi

echo "环境变量已从 $ENV_FILE_PATH 加载 ($LOADER_NAME)，共 $LOADED_COUNT 项"

# 关键配置校验（F-001 业务规则下限 8 项）：缺失项逐个列出键名，不打印值
REQUIRED_KEYS=(NACOS_ADDR NACOS_HOME DB_HOST DB_PORT DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PORT)
MISSING_KEYS=()
for key in "${REQUIRED_KEYS[@]}"; do
  value="${!key:-}"
  if [ -z "$value" ]; then
    MISSING_KEYS+=("$key")
  fi
done
if [ "${#MISSING_KEYS[@]}" -gt 0 ]; then
  echo "错误: 以下关键配置缺失或为空（请检查 $ENV_FILE_PATH，必要时复制 $EXAMPLE_FILE_PATH 填写配置）：" >&2
  for key in "${MISSING_KEYS[@]}"; do
    echo "  - $key" >&2
  done
  return 1
fi

return 0
