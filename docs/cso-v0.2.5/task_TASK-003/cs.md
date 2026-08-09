# 代码查询结果（#TASK-003 迁移 scripts 下全部 .sh/.ps1 至 deploy/scripts 并适配路径）

## 1. 任务概述

本任务（TASK-003）为「部署资产集中化」（v0.2.5）系列任务之一，负责：
1. 将项目根目录 `scripts/` 下全部 **10 个 .sh + 11 个 .ps1（共 21 个脚本）** 迁移至 `deploy/scripts/` 子目录（前提：TASK-001 已创建 deploy 目录、TASK-002 已迁移 env 文件）；
2. 同步适配脚本内部对 env.json、keys 密钥目录、jar 包等路径引用为 deploy 相对路径（验收 AC-6/AC-7）；
3. `scripts/` 下非 sh/ps1 内容（`API-TEST/`、`docker/`、`sql/`、`deployment-guide.md`）**保持原位不迁移**；
4. 冒烟验证 `load-env → deploy-check-env` 可正常执行。

用户输入还包含第 2 点「修改配置，将所有模块最终产物（jar/安装文件/exe）生成到 deploy 目录」与第 4 点「deploy/scripts 子目录」，其中部署目录与脚本迁移在本任务范围内；**构建产物输出配置（Maven/Flutter 侧）不在本任务上下文清单中，本 cs 仅记录现状供相关任务（TASK-004/005 等）使用**。

## 2. 现状盘点（本地代码查询结论）

### 2.1 deploy 目录现状（TASK-001/002 已完成）

| 路径 | 内容 | 说明 |
| --- | --- | --- |
| `deploy/.gitkeep` | 占位文件 | 保持空目录入 git |
| `deploy/scripts/.gitkeep` | 占位文件 | deploy/scripts 已预建，本任务直接迁入脚本 |
| `deploy/env.json` | 真实环境配置（26 个键） | 已迁移（TASK-002），含敏感值，git 忽略 |
| `deploy/env.example.json` | 模板（26 个键） | 已迁移（TASK-002），已入库 |

### 2.2 scripts 目录现状（21 个待迁移脚本）

全部 21 个脚本均**已被 git 跟踪**（`git ls-files` 确认，见下），迁移应使用 `git mv` 保留历史：

```text
scripts/load-env.sh / load-env.ps1
scripts/deploy-check-env.sh / deploy-check-env.ps1
scripts/deploy-db-init.sh / deploy-db-init.ps1
scripts/deploy-env.ps1（仅 ps1，无 sh）
scripts/deploy-env-template.sh / deploy-env-template.ps1
scripts/deploy-rsa-keygen.sh / deploy-rsa-keygen.ps1
scripts/deploy-start-auth.sh / deploy-start-auth.ps1
scripts/deploy-start-gateway.sh / deploy-start-gateway.ps1
scripts/deploy-start-biz.sh / deploy-start-biz.ps1
scripts/deploy-start-system.sh / deploy-start-system.ps1
scripts/deploy-start-services.sh / deploy-start-services.ps1
```

### 2.3 scripts 非脚本内容（保持原位不迁移）

| 路径 | 内容 | 说明 |
| --- | --- | --- |
| `scripts/sql/` | 4 个 SQL（init.sql、init-v0.2.0-full.sql、auth-init-v0.1.5.sql、auth-init-v0.1.6.sql） | 数据库脚本，**不迁移** |
| `scripts/docker/` | docker-compose.yml + 4 个 Dockerfile（gateway/auth/biz/system） | 容器编排，**不迁移** |
| `scripts/API-TEST/` | 接口测试脚本（cso-api-test-v0.2.5.py 等）与 TASK-001/002 回归测试（cso-unit-test-deploy-v0.2.5.ps1） | 测试资产，**不迁移** |
| `scripts/deployment-guide.md` | 部署指南（与 docs/deployment-guide.md 内容一致，MD5 相同） | 文档，**不迁移** |

### 2.4 git 工作区状态

- `git status --porcelain`：` M docs/cso-v0.2.5/version_progress.md`、`?? docs/cso-v0.2.5/task_TASK-003/`——21 个脚本均已在版本库中（无未提交改动），可直接 `git mv`。

## 3. 21 个脚本路径引用分析（迁移后需适配点，核心结论）

> 关键机制：全部脚本都以 `SCRIPT_DIR`/`$PSScriptRoot`（脚本自身所在目录）为基准计算 `PROJECT_DIR`（父目录）。迁移到 `deploy/scripts/` 后 `PROJECT_DIR` 自动变为 `deploy/`，因此**以 PROJECT_DIR 为基准引用 env.json 的代码自动适配**；**以 PROJECT_DIR 为基准引用 `scripts/...`（SQL）或模块 target/（jar）的代码会失效，必须适配**。

### 3.1 自动适配（迁移后无需修改）

| 文件 | 位置 | 逻辑 | 迁移后行为 |
| --- | --- | --- | --- |
| `load-env.sh` | L8-11 | `ENV_FILE="${1:-env.json}"`；`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"` | PROJECT_DIR=deploy → `deploy/env.json` ✓ |
| `load-env.ps1` | L15-19 | `$ProjectDir = Split-Path -Parent $PSScriptRoot`；`$EnvFilePath = Join-Path $ProjectDir $EnvFile` | 同上 ✓ |
| `deploy-start-services.sh` | L23-25 | `if [ ! -f "$PROJECT_DIR/env.json" ]` | 自动指向 deploy/env.json ✓（文案"复制 env.example.json 为 env.json"建议顺带更新为 deploy 路径） |
| `deploy-start-services.ps1` | L17-19 | `Test-Path (Join-Path $ProjectDir "env.json")` | 同上 ✓ |
| 全部脚本 | 通用 | `source "$SCRIPT_DIR/load-env.sh"` / `. $PSScriptRoot\load-env.ps1`（同目录引用） | 迁移后 load-env 同目录存在 ✓ |

### 3.2 必须适配（迁移后路径失效或语义变化）

| 文件 | 行号 | 现状代码 | 问题 | 适配方向 |
| --- | --- | --- | --- | --- |
| `deploy-db-init.sh` | L12-14, L36-55 | `SQL_DIR="$PROJECT_DIR/scripts/sql"` | 迁移后 PROJECT_DIR=deploy → `deploy/scripts/sql` 不存在（sql 不迁移） | 改为指向根目录 `scripts/sql`：如 `SQL_DIR="$(dirname "$PROJECT_DIR")/scripts/sql"` 或项目根推导 |
| `deploy-db-init.ps1` | L26, L34-35 | `$SqlDir5 = Join-Path $ProjectDir "scripts\sql\auth-init-v0.1.5.sql"` | 同上 | 同上（根目录 scripts/sql） |
| `deploy-check-env.sh` | L120-127 | `test -f pom.xml`、`ls scripts/sql/auth-init-v0.1.5.sql ...`（相对运行目录） | 迁移后若从 deploy/scripts 运行，pom.xml/scripts/sql 不在当前目录 | 建议改为基于 PROJECT_DIR 推导根目录的绝对路径，或文档化"须从项目根目录执行" |
| `deploy-check-env.ps1` | L135-142 | `Test-Path "pom.xml"`、`Test-Path "scripts/sql/auth-init-v0.1.5.sql"` | 同上 | 同上 |
| `deploy-start-auth.sh` | L13-15 | `JAR_PATH="$PROJECT_DIR/cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar"` | 迁移后指向 `deploy/cloudoffice-auth-service/target/...` 不存在 | 指向 deploy 下最终产物（构建产物输出任务后 jar 位于 deploy 下，具体文件名/子目录以构建配置任务为准） |
| `deploy-start-gateway.sh` | L13-14 | 同上（gateway） | 同上 | 同上 |
| `deploy-start-biz.sh` | L13-14 | 同上（biz） | 同上 | 同上 |
| `deploy-start-system.sh` | L13-14 | 同上（system） | 同上 | 同上 |
| `deploy-start-auth.ps1` | L11-12 | `$JarPath = Join-Path $ProjectDir "cloudoffice-auth-service\target\..."` | 同上 | 同上 |
| `deploy-start-gateway.ps1` | L11-12 | 同上（gateway） | 同上 | 同上 |
| `deploy-start-biz.ps1` | L11-12 | 同上（biz） | 同上 | 同上 |
| `deploy-start-system.ps1` | L11-12 | 同上（system） | 同上 | 同上 |
| `deploy-rsa-keygen.sh` | L12, L82 | `OUTPUT_DIR="${1:-keys}"`（相对当前目录）；提示"写入项目根目录 env.json" | 默认输出到运行目录 keys/；文案指向根目录 env.json | 建议默认输出到 deploy 下（如 `deploy/keys` 或保持根目录 keys/ 由编码阶段定夺）；文案更新为 deploy/env.json |
| `deploy-rsa-keygen.ps1` | L14, L80 | `OutputDir = "keys"`；提示"写入项目根目录 env.json" | 同上 | 同上 |
| `deploy-env-template.sh` | L18, L23 | 注释引用 `./scripts/deploy-rsa-keygen.sh` | 迁移后 scripts/ 下无此脚本 | 注释改为 `deploy/scripts/deploy-rsa-keygen.sh` |
| `deploy-env-template.ps1` | L22 | 注释引用 `.\scripts\deploy-rsa-keygen.ps1` | 同上 | 同上 |
| `deploy-env.ps1` | L9-17, L28 | 注释引用 `scripts/deploy-env-template.ps1`、`java -jar cloudoffice-gateway/target/...jar` | 同上 + jar 路径旧 | 注释改为 deploy/scripts/... 与 deploy 下产物 |
| `deploy-start-gateway.sh` | L27 | 注释引用 `./scripts/deploy-rsa-keygen.sh` | 同上 | 改为 `deploy/scripts/deploy-rsa-keygen.sh` |
| `deploy-start-gateway.ps1` | L26 | 注释引用 `.\scripts\deploy-rsa-keygen.ps1` | 同上 | 同上 |

> 注：`deploy-start-*.sh/ps1` 中"请先执行: mvn clean package -pl ..."的提示无需修改（Maven 命令本身不变）。

## 4. 构建产物输出配置现状（用户需求 2 相关，供相关任务参考）

- **父 POM `pom.xml`**（L142-160）：仅 `pluginManagement` 中配置 spring-boot-maven-plugin（lombok exclude），**无任何产物输出到 deploy 的配置**。
- **各模块 pom.xml**：gateway/auth/biz/system 四个模块仅声明 spring-boot-maven-plugin（无 finalName、无复制插件）；common 模块仅 maven-compiler-plugin（纯依赖库，无产物）。
- **结论**：当前 `mvn clean package` 产物仍位于各模块 `target/` 目录；「最终产物输出到根目录 deploy」需要新增构建配置（如 maven-antrun-plugin/maven-resources-plugin 复制，或 maven-deploy 到指定目录），并注意 SAD 约束：**构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy**，只复制最终 jar。
- **Dockerfile（scripts/docker/ 下，保持原位）**：多阶段构建在容器内 COPY `target/*.jar`，与宿主机 deploy 目录无耦合，不受影响。
- **Flutter 客户端**：`cloudoffice-flutter-app/` 构建产物位于 `build/web/`、`build/windows/runner/Release/`（exe），目前无输出到 deploy 的脚本/配置（deployment-guide.md 第 11 章为人工复制方式）。

## 5. 其他引用点（不迁移文件，但路径引用需知悉）

| 位置 | 引用内容 | 处理 |
| --- | --- | --- |
| `scripts/docker/docker-compose.yml` | `build.context: ../../`、`dockerfile: scripts/docker/*/Dockerfile`（相对 context） | 文件不迁移，路径保持有效，无需改 |
| `README.md` | L152-158 `scripts/sql/...`、L193/L283 `scripts/docker/...` | 文档引用，属文档同步任务（TASK-006） |
| `docs/deployment-guide.md` | 大量 `scripts/`、`env.json` 引用（L156-314、L355-381、L627-1065、L1528-1567 等） | 文档同步任务（TASK-006） |
| `scripts/deployment-guide.md` | 同上（与 docs 版本 MD5 一致） | 文件不迁移，内容同步任务 |
| `docs/project.md` 项目地图 | `scripts/ — 部署脚本（deploy-*.ps1/sh）...` | 项目地图更新（impm-project-update） |
| `.gitignore` | L310 `keys/`、L311 `env.json`、L233 `*.jar`、L244 `*.exe` | `env.json` 无路径前缀，迁移后 deploy/env.json 自动仍被忽略 ✓；deploy 下 jar/exe 产物因 `*.jar`/`*.exe` 规则被忽略（产物不入库，符合预期，无需改） |
| 后端代码（auth-service/gateway/biz/system/common） | 全局搜索 `env.json|scripts/|deploy`：**无任何引用** | 迁移不影响运行时 |
| Flutter 代码（cloudoffice-flutter-app） | 同上：无引用 | 迁移不影响客户端 |

## 6. 敏感信息提示（迁移注意事项）

- `scripts/deploy-env.ps1`（L25、L29、L32）内含**真实数据库密码与 RSA 私钥/公钥 Base64**，且该文件已被 git 跟踪（历史已入库，为既有问题）。本任务照搬迁移（git mv），**不得在 cs.md/任何文档中输出密钥值**；如需处理敏感信息遗留问题，另行评估（不在本任务范围）。
- `deploy/env.json` 含真实敏感值（git 已忽略），冒烟验证时不得打印其内容。

## 7. 迁移实施建议（供编码阶段参考）

1. **迁移方式**：21 个脚本均已被 git 跟踪，统一使用 `git mv scripts/xxx.sh deploy/scripts/xxx.sh`（PowerShell 下 `git mv` 逐文件执行），保留文件历史。
2. **迁移后校验**（对应 AC-6）：
   - 根目录 `scripts/` 下不再存在任何 `.sh`/`.ps1`（`Get-ChildItem scripts -Recurse -Include *.sh,*.ps1` 为空）；
   - `deploy/scripts/` 下存在全部 21 个脚本；
   - `scripts/sql/`、`scripts/docker/`、`scripts/API-TEST/`、`scripts/deployment-guide.md` 保持原位。
3. **路径适配清单**：按第 3.2 节逐文件修改（SQL 目录 → 根目录 scripts/sql；jar 路径 → deploy 下最终产物；注释 scripts/ → deploy/scripts/；rsa-keygen 输出与文案 → deploy 语境）。
4. **冒烟验证**（对应 AC-7）：
   - `load-env`：`source deploy/scripts/load-env.sh` 应输出从 `deploy/env.json` 加载成功（Bash）；`. .\deploy\scripts\load-env.ps1`（PowerShell）同理；
   - `deploy-check-env`：`bash deploy/scripts/deploy-check-env.sh` 可正常执行（中间件检查项可失败，但脚本自身须能运行到汇总）。
5. **边界**：不迁移 scripts 下非脚本内容；不修改 .gitignore；不修改 docker-compose/Dockerfile；构建产物输出配置（用户需求 2）不在本任务范围内。

## 8. 结论

- 迁移对象明确：`scripts/` 下 21 个 .sh/.ps1（10 sh + 11 ps1），目标 `deploy/scripts/`，均已被 git 跟踪 → `git mv` 保留历史。
- 关键适配点共 19 处（见 3.2 表）：4 个 start 脚本 sh/ps1 共 8 处 jar 路径、db-init 2 处 SQL 路径、check-env 2 处根目录相对路径、rsa-keygen 2 处 keys 输出与文案、env-template/env/start-gateway 注释 5 处 scripts/ 路径。
- 自动适配点 6 处（load-env 2 个 + services 2 个 + 全部同目录 load-env 引用）：因 PROJECT_DIR 自动变为 deploy，env.json 加载无需改动。
- 非脚本内容（sql/docker/API-TEST/deployment-guide.md）保持原位；文档与项目地图的路径引用更新属文档同步任务（TASK-006）。
- 构建产物输出到 deploy 的 Maven/Flutter 配置当前不存在，需由对应构建配置任务新增（本任务不涉及）。
<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
