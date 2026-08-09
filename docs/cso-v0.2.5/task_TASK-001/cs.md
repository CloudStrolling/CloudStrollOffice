# 代码查询报告（#TASK-001 新建 deploy 目录与 deploy/scripts 子目录）

## 1. 查询结论摘要

| 查询项 | 结论 |
| --- | --- |
| deploy 目录 | **当前不存在**，需在项目根目录新建 `deploy` 及 `deploy/scripts` 子目录 |
| env 文件 | `env.json` / `env.example.json` 位于项目根目录，后续任务（TASK-004）需迁移至 deploy |
| scripts 下 .sh/.ps1 | 共 **21 个**（10 个 .sh + 11 个 .ps1），后续任务（TASK-005）需迁移至 deploy/scripts |
| 后端产物 | 各服务模块 jar 默认输出至 `各模块/target/*.jar`（无 finalName / outputDirectory 自定义），后续任务需配置重定向至 deploy |
| 客户端产物 | Flutter Windows 构建默认输出 `cloudoffice-flutter-app/build/windows/.../Release/*.exe`，Web 输出 `build/web/`，后续任务需配置重定向 |
| .gitignore | `env.json`（根目录）、`*.jar`、`*.exe` 已全局忽略，产物与 env 迁入 deploy 后需调整忽略规则（后续任务处理） |

## 2. 项目根目录现状（与任务相关的目录与文件）

```
D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
├── pom.xml                    # Maven 父 POM（org.cloudstrolling/cloudoffice/0.0.1-SNAPSHOT）
├── env.json                   # 实际环境配置（含 DB 密码、RSA 密钥，敏感，已被 .gitignore 忽略）
├── env.example.json           # 环境配置模板（占位符形式，入库）
├── keys/                      # RSA 密钥对目录（敏感，不入库）
├── scripts/                   # 部署脚本 + sql + docker + API-TEST（21 个 .sh/.ps1 待迁移）
├── cloudoffice-common/        # 公共模块（jar，无启动类）
├── cloudoffice-gateway/       # API 网关（端口 9000）
├── cloudoffice-auth-service/  # 认证服务（端口 9100）
├── cloudoffice-biz-service/   # 企业服务（端口 9200）
├── cloudoffice-system-service/# 系统服务（端口 9400）
├── cloudoffice-flutter-app/   # Flutter 客户端（Web + Windows）
└── docs/                      # 项目文档
```

**注意**：deploy 目录当前不存在（glob 校验 `deploy/**/*` 无结果，根目录列表无 deploy 项），本任务需新建。

## 3. 环境配置文件（env.json / env.example.json）

### 3.1 env.json（根目录，敏感，实际配置）
- 路径：`env.json`（项目根目录）
- 内容：26 个配置项，含 `NACOS_ADDR`、`NACOS_HOME`、`DB_HOST/PORT/USERNAME/PASSWORD`、`REDIS_*`、`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`、`VERIFICATION_CODE_*`、`PASSWORD_MIN/MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ` 等
- 关键点：**含明文数据库密码与 RSA 私钥**，属敏感文件；已被 `.gitignore` 第 311 行 `env.json` 忽略（注意：该规则匹配任意层级 env.json，迁至 `deploy/env.json` 后仍会被忽略，无需额外规则）

### 3.2 env.example.json（根目录，模板）
- 路径：`env.example.json`（项目根目录）
- 内容：与 env.json 结构一致，敏感值为占位符（`<DB_PASSWORD>`、`<RSA_PRIVATE_KEY>` 等），`MARIADB_ROOT_PASSWORD` 示例值 `root123`，`NACOS_HOME` 示例 `/opt/nacos`
- 关键点：模板文件，无敏感信息，正常入库

### 3.3 迁移注意
- 两个文件需整体迁移至 `deploy/` 下（后续 TASK-004），文件名保持不变（`deploy/env.json`、`deploy/env.example.json`）
- 所有脚本通过 `env.json` 读取环境变量，迁移后脚本内 `PROJECT_DIR` 定位逻辑需同步适配（见第 6 节）

## 4. scripts 目录下 .sh / .ps1 脚本清单（21 个，TASK-005 迁移对象）

### 4.1 环境加载与初始化（4 个）
| 文件 | 作用 |
| --- | --- |
| `scripts/load-env.sh` | 从 env.json 加载环境变量（Bash，依赖 jq 或 python3） |
| `scripts/load-env.ps1` | 从 env.json 加载环境变量（PowerShell） |
| `scripts/deploy-rsa-keygen.sh` | RSA 密钥对生成脚本（Bash） |
| `scripts/deploy-rsa-keygen.ps1` | RSA 密钥对生成脚本（PowerShell） |

### 4.2 环境配置模板（3 个）
| 文件 | 作用 |
| --- | --- |
| `scripts/deploy-env.ps1` | 复制 deploy-env-template.ps1 为 deploy-env-local.ps1（旧版环境变量方式，已弃用） |
| `scripts/deploy-env-template.sh` | 环境变量模板（Bash，旧版，已弃用） |
| `scripts/deploy-env-template.ps1` | 环境变量模板（PowerShell，旧版，已弃用） |

### 4.3 环境检查与数据库初始化（4 个）
| 文件 | 作用 |
| --- | --- |
| `scripts/deploy-check-env.sh` | 环境检查（Bash）：校验 env.json 配置项、SQL 脚本存在性等 |
| `scripts/deploy-check-env.ps1` | 环境检查（PowerShell） |
| `scripts/deploy-db-init.sh` | 数据库初始化（Bash）：执行 scripts/sql 下 SQL |
| `scripts/deploy-db-init.ps1` | 数据库初始化（PowerShell） |

### 4.4 服务启动脚本（10 个）
| 文件 | 对应服务 | jar 路径引用 |
| --- | --- | --- |
| `scripts/deploy-start-gateway.sh` / `.ps1` | gateway | `cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar` |
| `scripts/deploy-start-auth.sh` / `.ps1` | auth-service | `cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar` |
| `scripts/deploy-start-biz.sh` / `.ps1` | biz-service | `cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar` |
| `scripts/deploy-start-system.sh` / `.ps1` | system-service | `cloudoffice-system-service/target/cloudoffice-system-service-0.0.1-SNAPSHOT.jar` |
| `scripts/deploy-start-services.sh` / `.ps1` | 环境自检（中间件安装/运行检查） | 不直接引用 jar |

### 4.5 统计
- **共 21 个**：`.sh` 10 个、`.ps1` 11 个（其中 deploy-env.ps1 无对应 .sh 版本）
- 迁移后目标：`deploy/scripts/`（保持文件名与成对关系不变）

### 4.6 scripts 下非迁移内容（保持原位，不进入 deploy）
- `scripts/sql/` — 数据库初始化 SQL（init.sql、init-v0.2.0-full.sql、auth-init-v0.1.5/0.1.6.sql）
- `scripts/docker/` — Docker 编排（docker-compose.yml + 4 个模块 Dockerfile）
- `scripts/API-TEST/` — API 测试脚本（test_auth_api.py、cso-api-test-v0.0.1.py 等）
- `scripts/deployment-guide.md` — 部署指南文档
- 依据 F-006：deploy/scripts 只存放 .sh/.ps1，sql、docker、API-TEST 等不迁移

## 5. 构建配置（后续产物重定向到 deploy 的依据）

### 5.1 Maven 父 POM（pom.xml）
- `groupId=org.cloudstrolling`、`artifactId=cloudoffice`、`version=0.0.1-SNAPSHOT`、`packaging=pom`
- 5 个子模块：common、gateway、auth-service、biz-service、system-service
- `<build>` 仅 pluginManagement 中配置了 spring-boot-maven-plugin（排除 lombok），**无 finalName、无输出目录重定向配置**

### 5.2 各服务模块 pom.xml（gateway / auth-service / biz-service / system-service）
- `packaging=jar`，均使用 `spring-boot-maven-plugin`
- **无 finalName、无 outputDirectory 配置** → 默认产物：`{模块}/target/{artifactId}-0.0.1-SNAPSHOT.jar`（可执行 fat jar）
- 例如：`cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar`

### 5.3 cloudoffice-common（公共模块）
- 仅 maven-compiler-plugin，**无 spring-boot-maven-plugin**（无启动类，不产可执行 jar，仅作为依赖被各服务引用；最终产物不包含 common 的独立 jar）

### 5.4 Flutter 客户端（cloudoffice-flutter-app）
- `pubspec.yaml`：`name: cloudoffice_flutter_app`、`version: 0.2.0+1`、SDK `^3.12.2`
- Windows 平台工程：`windows/`（CMake 构建，runner 主程序）
- 默认产物位置（Flutter 标准输出，无自定义）：
  - Windows exe：`build/windows/x64/runner/Release/*.exe`（或 Debug 变体）
  - Web：`build/web/`
- 后续如需将安装文件/exe 输出到 deploy，可通过 `flutter build windows --release` 后复制产物，或在 CMake/打包阶段配置输出路径

## 6. 脚本内路径引用（迁移适配关键点，供 TASK-005 参考）

所有脚本均以"自身所在目录"推导项目根目录，迁移到 `deploy/scripts/` 后 PROJECT_DIR 推导结果不变（仍是项目根），但以下引用需核对：

| 引用位置 | 现状 | 迁移后影响 |
| --- | --- | --- |
| `load-env.sh`（第 8-11 行） | `ENV_FILE="${1:-env.json}"`，`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`，`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"` | PROJECT_DIR 推导仍正确（deploy/scripts 上一级为 deploy，再上一级才是根目录——**需改为两级上溯**） |
| `load-env.ps1`（第 18-19 行） | `$ProjectDir = Split-Path -Parent $PSScriptRoot`，`$EnvFilePath = Join-Path $ProjectDir $EnvFile` | 同上，迁移后 ProjectDir 推导需两级上溯 |
| `deploy-start-*.sh/ps1`（各 1 处） | `JAR_PATH="$PROJECT_DIR/{模块}/target/{模块}-0.0.1-SNAPSHOT.jar"` | jar 落点改为 `deploy/` 后，JAR_PATH 需同步改为 `$PROJECT_DIR/deploy/{jar 名}` |
| `deploy-start-services.ps1`（第 14、17 行） | `$ProjectDir = Split-Path -Parent $PSScriptRoot`，检查 `$ProjectDir\env.json` | env.json 迁至 deploy 后，检查路径需改为 `$ProjectDir\deploy\env.json` |
| `deploy-start-services.sh`（第 23 行） | `$PROJECT_DIR/env.json` | 同上 |
| `deploy-db-init.sh`（第 14 行） | `SQL_DIR="$PROJECT_DIR/scripts/sql"` | sql 不迁移，路径不变，但 PROJECT_DIR 推导随脚本位置变化需核对 |
| `deploy-check-env.sh/ps1`（各 2 处） | 检查 `scripts/sql/auth-init-v*.sql` | sql 不迁移，检查路径不变，PROJECT_DIR 推导需核对 |

**关键结论**：脚本迁移后 `$PSScriptRoot` / `$SCRIPT_DIR` 从 `scripts/` 变为 `deploy/scripts/`，所有"从脚本目录上溯到项目根"的逻辑都需要从"上溯 1 级"调整为"上溯 2 级"；env.json 与 jar 路径引用需要从"根目录/模块 target"调整为"deploy 下"。此部分由 TASK-005 具体实现，本任务只需建目录。

## 7. .gitignore 相关注意事项（供后续任务参考）

| 规则 | 位置 | 说明 |
| --- | --- | --- |
| `env.json` | 第 311 行 | 匹配任意层级 env.json，迁移至 `deploy/env.json` 后仍被忽略（保持不入库，正确） |
| `keys/` | 第 310 行 | 密钥目录忽略，不随 env 迁移 |
| `*.jar` / `*.exe` | 第 233 / 244 行 | **全局忽略**，若产物落入 `deploy/` 后需要入库，须在 .gitignore 增加 `!deploy/**/*.jar` 等放行规则（由后续构建产物任务决定是否入库） |
| `target/` | 第 224 行 | Maven 中间产物忽略（中间产物不进入 deploy，无需调整） |
| `build/` | 第 183 行 | Flutter 构建中间产物忽略（同上） |

## 8. 可复用信息与编码提示（供编码 agent 使用）

1. **本任务只建目录骨架**：项目根目录新建 `deploy/` 与 `deploy/scripts/`；deploy 已存在则复用不覆盖（当前不存在，实际为新建）。可用 `New-Item -ItemType Directory` / `mkdir` 实现。
2. **目录命名**：固定小写 `deploy`、`deploy/scripts`（F-001、F-006）。
3. **目录性质约束**：deploy 只放最终产物（后端 jar、客户端安装文件/exe）、env.json/env.example.json、deploy/scripts 下 .sh/.ps1；不得放源代码与中间产物（target、build 等）。
4. **env 与脚本迁移由后续任务负责**：TASK-004（env 迁移）、TASK-005（脚本迁移）、TASK-002/003（构建产物配置），本任务无需执行迁移动作。
5. **验证方式**：目录结构校验——项目根目录存在 `deploy` 目录且含 `scripts` 子目录（`Test-Path deploy\scripts`）。
6. **下游任务依赖**：TASK-001 是 TASK-002~TASK-005 的前置任务（P0），建好目录后即可解除阻塞。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
