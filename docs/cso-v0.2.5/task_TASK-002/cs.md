# 代码查询结果（#TASK-002 迁移 env.json 与 env.example.json 至 deploy 目录）

## 1. 任务概述

本任务（TASK-002）为「部署资产集中化」（v0.2.5）系列任务之一，只负责将项目根目录的 `env.json`、`env.example.json` 两个环境配置文件迁移至 `deploy/` 目录（前提：TASK-001 已创建 deploy 目录），迁移后项目根目录不得残留这两个文件（验收 AC-5）。脚本路径引用适配不属本任务范围，由 TASK-003（脚本迁移）负责。

## 2. 现状盘点（本地代码查询结论）

### 2.1 项目根目录环境配置文件（待迁移对象）

| 文件 | 绝对路径 | 是否入库 | 说明 |
| --- | --- | --- | --- |
| env.json | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\env.json` | 否（`.gitignore` 第 311 行 `env.json` 规则忽略） | 真实环境配置，含数据库密码、RSA 密钥等敏感值，**禁止提交** |
| env.example.json | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\env.example.json` | 是 | 模板文件，全部为占位符/示例值，可入库 |

### 2.2 deploy 目录现状（TASK-001 已创建）

- `deploy\.gitkeep` — 占位文件（保持空目录入 git）
- `deploy\scripts\.gitkeep` — 占位文件（deploy/scripts 子目录已预建，供 TASK-003 使用）

deploy 目录已存在且为空（仅 .gitkeep），本任务直接向其中迁移 env 文件即可，无需创建目录。

### 2.3 scripts 目录现状（与 TASK-003 边界）

`scripts/` 下共 21 个 .sh/.ps1 脚本（10 个 .sh + 11 个 .ps1），另有非脚本内容（sql/、docker/、API-TEST/、deployment-guide.md）——非脚本内容按用户需求保持原位，不迁移。**本任务不处理 scripts 目录。**

## 3. env.example.json 结构（模板键清单，共 25 个键）

| 键名 | 示例值 | 用途 |
| --- | --- | --- |
| NACOS_ADDR | 127.0.0.1:8848 | Nacos 注册/配置中心地址 |
| NACOS_HOME | /opt/nacos | Nacos 安装目录 |
| DB_SERVICE_NAME / DB_PROCESS_NAME | MySQL, MariaDB / mysqld, mariadbd | 数据库服务名/进程名（启动检查用） |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | Redis / redis-server | Redis 服务名/进程名（启动检查用） |
| DB_HOST / DB_PORT / DB_USERNAME / DB_USER / DB_PASSWORD | 127.0.0.1 / 3306 / root / root / \<DB_PASSWORD\> | 数据库连接配置（密码为占位符） |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD / REDIS_DATABASE | 127.0.0.1 / 6379 / 空 / 0 | Redis 连接配置 |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | \<RSA_PRIVATE_KEY\> / \<RSA_PUBLIC_KEY\> | JWT RS256 签名密钥对（占位符） |
| VERIFICATION_CODE_MOCK / VERIFICATION_CODE_EXPIRE_SECONDS / VERIFICATION_CODE_SEND_INTERVAL / VERIFICATION_CODE_LENGTH | true / 300 / 60 / 6 | 验证码模拟开关与策略 |
| PASSWORD_MIN_LENGTH / PASSWORD_MAX_LENGTH | 8 / 64 | 密码策略 |
| MARIADB_ROOT_PASSWORD | root123 | Docker 编排 MariaDB root 密码 |
| TZ | Asia/Shanghai | 时区 |

## 4. env.json 结构（键名清单，25 个键，与模板一致）

env.json 包含全部上述 25 个键（键名与 env.example.json 一一对应），值均为真实配置（含 DB_PASSWORD、RSA_PRIVATE_KEY 等敏感值）。**查询/迁移过程中不得将敏感值写入任何文档，cs.md 仅记录键名。**

## 5. 引用 env.json / env.example.json 的位置（供 TASK-003 及文档适配参考）

> 注：以下引用适配不在本任务（TASK-002）范围内，仅记录供下游任务使用。

### 5.1 脚本内路径引用（TASK-003 需同步适配）

| 文件 | 行号 | 引用方式 |
| --- | --- | --- |
| `scripts/load-env.ps1` | 15 | `[string]$EnvFile = "env.json"`（默认相对路径，调用方传参） |
| `scripts/load-env.sh` | 8 | `ENV_FILE="${1:-env.json}"`（默认相对路径，调用方传参） |
| `scripts/deploy-start-services.ps1` | 17-19 | `Test-Path (Join-Path $ProjectDir "env.json")`（引用项目根目录） |
| `scripts/deploy-start-services.sh` | 23-25 | `if [ ! -f "$PROJECT_DIR/env.json" ]`（引用项目根目录） |
| `scripts/deploy-start-*.sh/ps1`（auth/biz/gateway/system） | 头部注释 | 注释说明"从 env.json 加载环境变量"，经 load-env 间接加载 |
| `scripts/deploy-env-template.sh/ps1` | 头部注释 | 说明"复制 env.example.json 为 env.json" |
| `scripts/deploy-rsa-keygen.sh/ps1` | 80-84 | 提示将 RSA 密钥 Base64 值写入根目录 env.json |
| `scripts/deploy-check-env.sh/ps1`、`scripts/deploy-db-init.sh/ps1` | 头部注释 | 注释引用 env.json 加载 |

### 5.2 文档引用（TASK-006 文档同步时参考）

- `docs/deployment-guide.md` — 大量引用（212-214、238、299-340、621-846、1028-1060、1534-1563 行）
- `docs/cso-dbd.md`（361 行）、`docs/sad.md`（16、23、199、212、297 行）

## 6. .gitignore 相关规则（迁移注意事项）

- `.gitignore` 第 311 行：`env.json` — **不带路径前缀**，匹配任意目录下的 env.json，因此 `deploy/env.json` 迁移后自动仍被忽略，无需修改 .gitignore。
- `env.example.json` 不在忽略规则中，可正常入库；迁移时应使用 `git mv` 保留历史（若该文件已纳入 git 管理，确认：`git ls-files env.example.json` 有跟踪记录则用 git mv，否则直接 Move-Item）。
- `env.json` 已被 git 忽略（未跟踪），迁移时只能用文件系统移动（Move-Item），不能用 git mv。

## 7. 迁移实施建议（供编码阶段参考）

1. 目标位置：`deploy/env.json`、`deploy/env.example.json`（deploy 目录已存在，无需新建）。
2. 迁移方式：
   - `env.example.json`：若已入库则 `git mv env.example.json deploy/env.example.json`，否则 `Move-Item`；
   - `env.json`：未入库（gitignore），直接用 `Move-Item env.json deploy/env.json`（PowerShell）。
3. 迁移后校验：项目根目录不存在 env.json/env.example.json；deploy 目录下存在两文件且内容与迁移前一致（可对比文件哈希）。
4. 敏感信息：env.json 含真实密钥/密码，迁移与提交过程中不得泄露；deploy/.gitkeep 保持存在以维持目录入库。
5. 边界：不修改任何脚本、不修改 .gitignore、不迁移 scripts 目录内容（TASK-003 范围）。

## 8. 结论

- 迁移对象明确：根目录 `env.json`（敏感，未入库）与 `env.example.json`（模板，已入库）2 个文件。
- 目标目录 `deploy/` 已由 TASK-001 创建（含 .gitkeep、scripts/.gitkeep），可直接写入。
- 本任务不涉及任何 Java/Dart 源代码修改；不涉及接口、数据库变更。
- 依赖 env 文件的脚本路径引用适配在 TASK-003 完成，文档同步在 TASK-006 完成，本任务仅完成文件迁移。
<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
