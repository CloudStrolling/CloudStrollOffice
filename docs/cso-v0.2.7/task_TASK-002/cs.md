# 代码查询结果（TASK-002 实现 load-env.ps1 / load-env.sh 统一配置加载模块）

## 0. 查询结论摘要

本任务为 v0.2.7 部署脚本重构的 **F-001（env.json 配置加载统一）落地任务**：在现有 `deploy/scripts/load-env.ps1` / `load-env.sh` 基础上补齐「env.json 缺失提示 + 关键配置缺失逐个列出 + 非零退出 + SPDX 版权头 + 简体中文注释」契约。经实际读取两个现有脚本、`deploy/env.json` 与 `deploy/env.example.json` 全量键值、全部 9 个下游调用方脚本（deploy-check-env / deploy-start-services / deploy-start-gateway/auth/biz/system / deploy-db-init 的 .ps1/.sh）、相关测试脚本断言（UT-078/UT-142）及 TASK-001 issue-list，确认：

- **现有 load-env 脚本结构可复用**（路径推导、JSON 解析、注入机制均已正确），本任务只需在既有基础上做「契约补齐」，不应推翻重写；
- **关键契约缺口**：① 现有脚本无 SPDX 版权头与版权声明（issue-list P7 补记）；② env.json 缺失时提示文案不完整（未提示「复制 env.example.json 并填写配置」）；③ 无「关键配置缺失逐个列出」校验；④ 无「口令类敏感值不打印」的显式说明与实现核对。
- **保留基线**：`BASH_SOURCE[0]` / `PSScriptRoot` 路径推导与 `ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"` / `Join-Path $ProjectDir $EnvFile` 模式被历史测试 UT-078 断言（scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1 第 262-275 行）锁定，重构时不得破坏。
- **source/dot-source 语义**：load-env.sh 以 `source` 方式被调用（失败用 `return 1`，不能用 `exit`，否则会退出父 shell）；load-env.ps1 以 dot-source（`. $PSScriptRoot\load-env.ps1`）方式被调用，现有脚本内部用 `exit 1`，任务契约要求「退出非零」保持一致（F-001 原文）。

---

## 1. 查询范围与文件清单

### 1.1 本任务直接相关的现有脚本（load-env 模块）

| 文件 | 定位/作用 | 现状（v0.2.7 基线） |
| --- | --- | --- |
| `deploy/scripts/load-env.ps1` | PowerShell 统一配置加载：从 `deploy/env.json` 将键值对注入会话环境变量 | 35 行，无 SPDX 头；无关键配置校验；env.json 缺失提示不完整 |
| `deploy/scripts/load-env.sh` | Bash 统一配置加载（jq 优先、python3 回退） | 39 行，无 SPDX 头；无关键配置校验；env.json 缺失提示不完整 |
| `deploy/env.json` | 实际环境配置（唯一配置源，ADR-016） | 25 键（含真实口令，git 已忽略） |
| `deploy/env.example.json` | 环境配置模板 | 25 键，占位符值；必须保持入库 |

### 1.2 下游调用方脚本（load-env 的 9 个消费方，.ps1 与 .sh 各一份）

| 脚本 | 调用方式 | 调用前是否自查 env.json | 自身所需关键变量（load-env 补齐校验时参考） |
| --- | --- | --- | --- |
| `deploy-check-env.ps1` / `.sh` | `. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`（.ps1 第 36 行、.sh 第 22 行） | 否（直接调用） | NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT（另有硬编码默认值待 TASK-002 之外的重构处理） |
| `deploy-start-services.ps1` / `.sh` | `. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`（.ps1 第 23 行、.sh 第 29 行） | 是（第 17-21 行 / 第 23-27 行预检存在性） | NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT（第 25-26 行 / 第 31-32 行 8 项清单） |
| `deploy-start-gateway.ps1` / `.sh` | `. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`（第 15 行 / 第 17 行） | 否 | NACOS_ADDR、RSA_PUBLIC_KEY（.ps1 第 18-28 行）；.sh 第 20-29 行校验范围同 |
| `deploy-start-auth.ps1` / `.sh` | 同上（第 15 行 / 第 18 行） | 否 | 9 项：NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY（.ps1 第 18-19 行；.sh 第 21-22 行） |
| `deploy-start-biz.ps1` / `.sh` | 同上（第 15 行 / 第 17 行） | 否 | .ps1 仅 NACOS_ADDR（第 18 行）；.sh 校验 NACOS_ADDR/DB_PASSWORD（第 21-29 行）——双平台不一致（issue-list P7-02） |
| `deploy-start-system.ps1` / `.sh` | 同上（第 15 行 / 第 17 行） | 否 | 同 biz：.ps1 仅 NACOS_ADDR；.sh 校验 NACOS_ADDR/DB_PASSWORD（P7-02） |
| `deploy-db-init.ps1` / `.sh` | `. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`（第 30 行 / 第 18 行） | 否 | DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD |

> 关键点：**多数调用方（check-env/gateway/auth/biz/system/db-init）不自查 env.json**，直接依赖 load-env 在缺失时给出错误提示并退出非零。因此 load-env 的「env.json 缺失提示 + 关键配置校验」是所有调用方正确行为的前提。

### 1.3 测试脚本与断言基线（重构不得破坏）

- `scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1`（UT-078，第 260-281 行）：
  - UT-078-1：load-env.sh 必须包含 `${BASH_SOURCE[0]}`、`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`、`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"`；
  - UT-078-2：load-env.ps1 必须包含 `$PSScriptRoot`、`$ProjectDir = Split-Path -Parent $PSScriptRoot`、`Join-Path $ProjectDir $EnvFile`；
  - UT-078-3：deploy/env.json 存在性。
- `scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1`（UT-142，第 452-523 行）：
  - UT-142-1：全部 .ps1 可被 PowerShell Parser 解析（无语法错误）；
  - UT-142-2：全部 .sh 通过 `bash -n`（不可用时降级 shebang + 非空校验）；**load-env.sh 属 source 型脚本，故意省略 `set -e` 避免污染父 shell**（第 500-501 行注释明确）；
  - UT-142-3：deploy-check-env.ps1 第 35 行孤立死代码已确认（issue-list P7-05），**与 load-env.ps1 无关**。

---

## 2. 现有 load-env 脚本源码详细分析

### 2.1 load-env.ps1（35 行，完整源码要点）

```
param([string]$EnvFile = "env.json")                     # L14-16 参数化，默认 env.json
$ProjectDir = Split-Path -Parent $PSScriptRoot           # L18 = deploy（脚本位于 deploy/scripts）
$EnvFilePath = Join-Path $ProjectDir $EnvFile            # L19 = deploy/env.json
if (-not (Test-Path $EnvFilePath)) {                     # L21-24 缺失提示（现有文案不完整）
  Write-Error "环境配置文件不存在: $EnvFilePath"
  exit 1
}
$json = Get-Content -Raw -Encoding UTF8 $EnvFilePath | ConvertFrom-Json   # L27
$json.PSObject.Properties | ForEach-Object {             # L28-30 遍历注入
  Set-Item -Path "env:$($_.Name)" -Value $_.Value
}
Write-Host "环境变量已从 $EnvFilePath 加载" -ForegroundColor Green         # L31
# L32-34 catch 分支：解析失败 Write-Error + exit 1
```

**可复用**：
- 参数化 `EnvFile` 默认 `env.json`（UT-078-2 依赖）；
- `$ProjectDir = Split-Path -Parent $PSScriptRoot` 路径推导；
- `ConvertFrom-Json` + `PSObject.Properties` 遍历 + `Set-Item -Path "env:..."` 注入机制。

**遗留问题（本任务补齐项）**：
1. 文件头无 SPDX-License-Identifier 与版权声明（issue-list P7 补记 / F-011）；
2. env.json 缺失提示未提及「复制 env.example.json 并填写配置」（F-001 契约要求）；
3. 无「关键配置缺失逐个列出并退出非零」校验（F-001 契约要求）；
4. 无口令/密钥类敏感值处理的显式说明（虽不打印，但注释应明确）。

### 2.2 load-env.sh（39 行，完整源码要点）

```
ENV_FILE="${1:-env.json}"                                # L8
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # L9
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"                   # L10 = deploy
ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"                   # L11
if [ ! -f "$ENV_FILE_PATH" ]; then                       # L13-16 缺失提示（现有文案不完整）
  echo "错误: 环境配置文件不存在: $ENV_FILE_PATH" >&2
  return 1                                               # source 语义，必须 return 而非 exit
fi
# 方法1 jq（L19-23）：eval "$(jq -r 'to_entries | .[] | "export \(.key)=\(.value | @sh)"' "$ENV_FILE_PATH")"
# 方法2 python3 回退（L26-36）：json.load + shlex.quote 生成 export 语句
# 方法3（L38-39）：均不可用时报错 return 1
```

**可复用**：
- `BASH_SOURCE[0]` 推导 SCRIPT_DIR → PROJECT_DIR（UT-078-1 依赖）；
- jq 优先 / python3 回退的双解析方案（@sh 与 shlex.quote 均正确转义）；
- `return 1`（source 型脚本正确语义，不能改成 `exit`）。

**遗留问题（本任务补齐项）**：
1. 文件头无 SPDX 版权头；
2. env.json 缺失提示未提及 env.example.json；
3. 无关键配置缺失校验；
4. jq 与 python3 两种路径的成功提示文案已存在（「环境变量已从 ... 加载 (jq/python3)」），可保留。

### 2.3 deploy/env.json 实际结构（25 键，本任务加载与校验依据）

| 键 | 类型 | 值（示例，本机实际值） | 是否关键配置（F-001 建议清单） |
| --- | --- | --- | --- |
| NACOS_ADDR | string | `127.0.0.1:8848` | ✅ |
| NACOS_HOME | string | `D:\jenemy\develop\nacos` | ✅ |
| DB_HOST | string | `127.0.0.1` | ✅ |
| DB_PORT | string | `3306` | ✅ |
| DB_USERNAME | string | `root` | ✅ |
| DB_PASSWORD | string | 真实口令（敏感） | ✅ |
| REDIS_HOST | string | `127.0.0.1` | ✅ |
| REDIS_PORT | string | `6379` | ✅ |
| DB_SERVICE_NAME | string | `MySQL, MariaDB` | ⭕（可选，start-services 用） |
| DB_PROCESS_NAME | string | `mysqld, mariadbd` | ⭕ |
| REDIS_SERVICE_NAME | string | `Redis` | ⭕ |
| REDIS_PROCESS_NAME | string | `redis-server` | ⭕ |
| DB_USER | string | `root` | ⭕（兼容项） |
| REDIS_PASSWORD | string | 空 | ⭕ |
| REDIS_DATABASE | string | `0` | ⭕ |
| RSA_PRIVATE_KEY | string | DER 单行 Base64（真实私钥，敏感） | ⭕（auth/网关用，issue-list 建议纳入可选校验） |
| RSA_PUBLIC_KEY | string | DER 单行 Base64（真实公钥） | ⭕（网关必填） |
| VERIFICATION_CODE_MOCK | string | `true` | ⭕ |
| VERIFICATION_CODE_EXPIRE_SECONDS | string | `300` | ⭕ |
| VERIFICATION_CODE_SEND_INTERVAL | string | `60` | ⭕ |
| VERIFICATION_CODE_LENGTH | string | `6` | ⭕ |
| PASSWORD_MIN_LENGTH | string | `8` | ⭕ |
| PASSWORD_MAX_LENGTH | string | `64` | ⭕ |
| MARIADB_ROOT_PASSWORD | string | 真实口令（敏感） | ⭕ |
| TZ | string | `Asia/Shanghai` | ⭕ |

> 注意：全部值为字符串类型（含数字与布尔，如 `"true"`/`"300"`）。注入环境变量后均为字符串，与 Spring 配置绑定兼容。

### 2.4 deploy/env.example.json 实际结构（25 键，缺失提示的指引目标）

与 env.json 键完全一致，仅将敏感值替换为占位符：`DB_PASSWORD` → `<DB_PASSWORD>`、`RSA_PRIVATE_KEY` → `<RSA_PRIVATE_KEY>`、`RSA_PUBLIC_KEY` → `<RSA_PUBLIC_KEY>`、`MARIADB_ROOT_PASSWORD` → `root123`、`NACOS_HOME` → `/opt/nacos`（Linux 风格示例）。

---

## 3. 可复用模块与重构输入（供 code 步骤直接使用）

| 可复用资产 | 位置 | 复用建议 |
| --- | --- | --- |
| 路径推导（ps1） | load-env.ps1 L18-19 | 保留 `Split-Path -Parent $PSScriptRoot` + `Join-Path`（UT-078-2 锁定） |
| 路径推导（sh） | load-env.sh L9-11 | 保留 `BASH_SOURCE[0]` + `dirname` + `ENV_FILE_PATH`（UT-078-1 锁定） |
| JSON 解析与注入（ps1） | load-env.ps1 L27-30 | 保留 `ConvertFrom-Json` + `Set-Item "env:..."` 遍历注入 |
| JSON 解析与注入（sh） | load-env.sh L19-36 | 保留 jq 优先 / python3 回退，`eval` + `@sh`/`shlex.quote` 转义 |
| 关键配置清单 | context.md 第 5.4 节 + F-001 业务规则 | 建议至少 8 项：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT（PRD F-001 原文）；可考虑将 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 纳入可选校验 |
| 退出码约定 | F-001 / context.md | 成功 0；env.json 缺失或关键配置缺失非零（脚本内约定）；.sh 用 `return`、.ps1 用 `exit`（维持 source/dot-source 语义） |
| env.example.json | deploy/env.example.json | 缺失提示的指引目标（「复制 env.example.json 为 env.json 并填写配置」） |
| SPDX 头格式 | issue-list P7 补记 / project.md | 文件头保留 `<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->`（.sh 可用 `# SPDX-License-Identifier: Apache-2.0` 注释） |

---

## 4. 遗留问题与契约要求（本任务 code 步骤实现依据）

### 4.1 现有 load-env 的遗留问题（均属本任务补齐范围）

| 编号 | 问题 | 现状 | 契约要求（F-001） |
| --- | --- | --- | --- |
| G1 | env.json 缺失提示不完整 | `错误: 环境配置文件不存在: <path>` | 输出错误提示，明示「复制 deploy/env.example.json 为 env.json 并填写配置」，非零退出 |
| G2 | 关键配置缺失无校验 | 无 | 校验本脚本所需关键配置项（至少 NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失项逐个列出并退出非零 |
| G3 | 无 SPDX 版权头 | 两个文件均无 | 保留 SPDX-License-Identifier 与版权声明，简体中文注释 |
| G4 | 无敏感值处理注释 | 无显式说明 | 注释明确「口令/密钥不打印」，实现上不得输出 DB_PASSWORD/RSA_PRIVATE_KEY 明文 |

### 4.2 明确不在本任务范围（避免越界）

- 下游脚本自身的硬编码地址清理（deploy-check-env 192.168.1.x 等）属 TASK-002 之外的 check-env 重构（issue-list P1/P4 → TASK-003/005 等下游）——本任务只改 load-env.*；
- deploy-env.ps1 / deploy-env-template.* 弃用脚本清理属 TASK-005（issue-list P2）；
- .gitignore 治理（用户输入第 4 点）属 TASK-007（F-012）——本任务只实现 load-env；
- 关键配置「8 项」为 F-001 建议下限，如 code 步骤需兼顾 gateway/auth 的 RSA_PUBLIC_KEY 等，可在 load-env 中采用「必填 8 项 + 可选键存在即校验」策略，但不得扩大为「全部 25 键必填」（会与 env.example.json 占位符冲突）。

### 4.3 双平台行为一致性要求（SAD 1.2 / context.md TL 第 3 点）

- 三场景行为一致：env.json 存在→加载全部键值对为会话环境变量（成功退出 0）；env.json 缺失→提示复制 env.example.json 并退出非零；关键配置缺失→逐个列出缺失项并退出非零；
- 退出码一致：加载成功 0 / 缺失或关键配置缺失非零；
- 语法校验：.ps1 经 PowerShell Parser、.sh 经 `bash -n`（UT-142 契约）；
- load-env.sh 不引入 `set -e`（UT-142-2 注释明确 source 型脚本省略）。

---

## 5. 相关文档要点摘录（供后续步骤引用）

- **F-001（PRD 4.1）业务规则**：load-env 从 `deploy/env.json` 读取；env.json 不存在时输出错误提示（复制 env.example.json 为 env.json 并填写配置）并退出非零；各脚本在加载后校验所需关键配置项（至少 NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT），缺失项逐个列出并退出；脚本内不得硬编码地址与凭据。
- **SAD 1.2 脚本体系约束（v0.2.7 起）**：全部脚本统一经 load-env 从 deploy/env.json 加载；.ps1 与 .sh 双平台行为一致；输出统一分级、退出码约定（失败非零）。
- **ADR-016**：以 deploy/env.json 为唯一配置源；.ps1/.sh 行为对齐；删除弃用脚本；.gitignore 治理（本任务不含）。
- **ADR-015**：RSA 密钥 DER 单行 Base64 契约，load-env 加载 RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 时不得破坏（保持原样字符串注入）。
- **issue-list（TASK-001 交付物）**：P7-05 确认 load-env.ps1 干净（孤立行在 deploy-check-env.ps1 L35）；第 4.2 节 .gitignore 缺口供 TASK-007 使用（本任务不执行）。
- **UT-078 / UT-142（测试基线）**：详见第 1.3 节，重构后仍须满足。

---

## 6. 编码建议（供 code 步骤参考，非本任务执行）

1. 以现有 35 行 load-env.ps1 / 39 行 load-env.sh 为基础增量修改，不重写路径推导与注入逻辑；
2. 文件头新增 SPDX 版权头与版权声明；
3. env.json 缺失分支：提示文案加入「请复制 deploy 目录下的 env.example.json 为 env.json 并填写配置」；
4. 新增关键配置校验函数/代码块：定义 8 项必填数组，逐个检查（.ps1 用 `Get-Item Env:$var` / `$env:$var`、.sh 用 `${!var:-}`），缺失项收集后逐行列出并退出非零；
5. 敏感值处理：加载过程与校验输出均不得打印 DB_PASSWORD/RSA_PRIVATE_KEY 的明文值；注释中明示；
6. 保持 source/dot-source 语义（.sh 用 `return`，.ps1 用 `exit`）；
7. 保留 jq/python3 回退（.sh）与 ConvertFrom-Json（.ps1），并在成功提示中沿用「环境变量已从 ... 加载」句式；
8. 建议在脚本末尾输出加载摘要时仅列非敏感键名或「已加载 N 个环境变量」，不打印 DB_PASSWORD 等值。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
