# 代码查询结果（#TASK-004 修改 Maven 构建配置：后端 jar 最终产物统一输出至 deploy）

## 1. 任务需求摘要
修改根 `pom.xml` 与 gateway、auth-service、biz-service、system-service 四个可执行模块 `pom.xml`，在 package 阶段将各模块最终可执行 jar 复制/输出至根目录 `deploy`（deployDir 以根目录相对方式定位）；产物命名保持模块可辨识（如 `cloudoffice-gateway.jar`、`cloudoffice-auth-service.jar` 等），避免同名覆盖，重复构建 overwrite 覆盖旧版本；仅复制最终 jar 文件，禁止整目录递归复制 target（编译类、测试产物等中间产物不得进入 deploy）；common 模块为库依赖不参与输出。对应 PRD F-002、F-004。

## 2. 现状盘点（上游 TASK-001/002/003 已完成部分）
| 事项 | 现状 | 说明 |
| --- | --- | --- |
| deploy 目录 | 已存在 | `deploy/` 含 `.gitkeep`、`env.json`、`env.example.json`、`scripts/`（由 TASK-001 创建） |
| env.json / env.example.json | 已迁移至 `deploy/` | TASK-002 通过 git mv 完成（UT-061~072 已验证） |
| 部署脚本迁移 | 已完成 | TASK-003 将 21 个 .sh/.ps1（10 .sh + 11 .ps1）git mv 至 `deploy/scripts/`（UT-073~078 已验证） |
| 构建产物输出配置 | **未配置（本任务核心）** | 根 pom 与 4 个模块 pom 均无任何 deploy 输出插件配置 |

## 3. 待修改文件（TASK-004 编码范围）

### 3.1 根 pom.xml（D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\pom.xml，162 行）
- 父项目：groupId `org.cloudstrolling`、artifactId `cloudoffice`、version `0.0.1-SNAPSHOT`、packaging `pom`。
- modules 声明 5 个子模块：`cloudoffice-common`、`cloudoffice-gateway`、`cloudoffice-auth-service`、`cloudoffice-biz-service`、`cloudoffice-system-service`。
- `<build>` 仅有 `<pluginManagement>`，内部只有 `spring-boot-maven-plugin`（配置了排除 lombok），**无任何产物复制/输出插件**。
- 编码提示：可在根 pom 的 `<properties>` 增加 deployDir 属性（以根目录相对方式定位，如 `${maven.multiModuleProjectDirectory}/deploy`），并声明 copy 类插件（SAD 技术栈已指定 maven-antrun-plugin/copy 插件方案）。

### 3.2 四个可执行模块 pom.xml（结构完全一致）
| 文件 | artifactId | 默认 jar 产物名（target 下） | 目标产物名（deploy 下） |
| --- | --- | --- | --- |
| `cloudoffice-gateway/pom.xml`（97 行） | cloudoffice-gateway | cloudoffice-gateway-0.0.1-SNAPSHOT.jar | **cloudoffice-gateway.jar** |
| `cloudoffice-auth-service/pom.xml`（132 行） | cloudoffice-auth-service | cloudoffice-auth-service-0.0.1-SNAPSHOT.jar | **cloudoffice-auth-service.jar** |
| `cloudoffice-biz-service/pom.xml`（81 行） | cloudoffice-biz-service | cloudoffice-biz-service-0.0.1-SNAPSHOT.jar | **cloudoffice-biz-service.jar** |
| `cloudoffice-system-service/pom.xml`（81 行） | cloudoffice-system-service | cloudoffice-system-service-0.0.1-SNAPSHOT.jar | **cloudoffice-system-service.jar** |

- 四者共同结构：parent 指向根 pom（relativePath `../pom.xml`）、`packaging` jar、`<build><plugins>` 仅 `spring-boot-maven-plugin`（无 configuration，无 finalName）。
- 编码提示：在各自 `<build><plugins>` 中追加复制插件（package 阶段），将 `${project.build.directory}/${project.build.finalName}.jar` 复制为 `${deployDir}/cloudoffice-{module}.jar`；只复制文件不复制目录，overwrite 覆盖旧版本。

### 3.3 cloudoffice-common/pom.xml（86 行）
- 库模块（`packaging` jar），无启动类，`<build>` 仅有 maven-compiler-plugin，**无 spring-boot-maven-plugin**。
- 编码提示：不参与产物输出，**保持不动**。

## 4. 产物命名契约（与既有脚本/测试强一致，必须遵守）
`deploy/scripts/deploy-start-*.sh/.ps1` 已按以下命名引用 jar（TASK-003 迁移时同步适配，UT-077-3 断言）：

```bash
# deploy/scripts/deploy-start-auth.sh 第 15 行
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"   # = deploy
JAR_PATH="$PROJECT_DIR/cloudoffice-auth-service.jar"
```

- gateway → `cloudoffice-gateway.jar`（无 -service 后缀）
- auth/biz/system → `cloudoffice-{m}-service.jar`
- 与任务描述"产物命名保持模块可辨识（如 cloudoffice-gateway.jar、cloudoffice-auth-service.jar 等）"完全一致。

## 5. 构建相关事实
- Spring Boot 3.2.5（spring-boot-starter-parent），spring-boot-maven-plugin 打可执行 jar，版本 0.0.1-SNAPSHOT。
- 构建命令参考（脚本提示语）：`mvn clean package -pl cloudoffice-auth-service -am -DskipTests`；全量：`mvn clean package`。
- `.gitignore` 已忽略 `*.jar`、`*.war`（第 233-234 行）——deploy 下的 jar 产物不入库属预期行为；`env.json` 被忽略（第 311 行），`deploy/env.json` 同样被 git 忽略（UT-071 已验证）；`docs2/` 被忽略（第 313 行）。
- `deploy/.gitkeep` 与 `deploy/scripts/.gitkeep` 已入库，保证空目录可提交。

## 6. 注意事项 / 风险提示（供编码参考）
- **Dockerfile 构建隔离**：`scripts/docker/{gateway,auth-service,biz-service,system-service}/Dockerfile` 为多阶段构建（`mvn clean package` 后从 `target/` COPY jar），构建上下文为根目录。若根 pom 新增复制插件，Docker 构建时会在容器内 `${maven.multiModuleProjectDirectory}/deploy` 产生复制动作（容器内 WORKDIR=/build，不影响镜像产物），属无害冗余；如需规避可在编码时评估。
- **中间产物隔离**：复制插件必须只复制单个 jar 文件（`<file>`），禁止 `<fileset>` 整目录复制 target，否则违反 AC-4（deploy 内不得出现 target 类中间目录、编译临时文件、测试产物）。
- **重复构建覆盖**：复制配置需 overwrite=true（antrun copy 默认覆盖，或 maven-resources-plugin 注意覆盖行为），保证"重复构建 overwrite 覆盖旧版本"。
- **deployDir 定位**：以根目录相对方式定位（如 `${maven.multiModuleProjectDirectory}/deploy`），避免各模块 `../deploy` 相对路径因 -pl/-am 构建顺序产生歧义。
- **common 模块排除**：common 无 spring-boot-maven-plugin，也不得配置复制插件，否则会把库 jar 误输出至 deploy。

## 7. 测试方法（任务自带）
- 构建验证：执行 `mvn package`（或 `mvn clean package`）后校验 deploy 下存在 4 个最终 jar（gateway/auth/biz/system，文件名符合契约），且无 target 类中间目录、无编译临时文件、无测试产物。
- 验收标准：AC-2（4 个 jar 出现在 deploy）、AC-4（deploy 内无中间产物）。

## 8. 可复用组件结论
- 本任务为纯构建配置改动，**无 Java 代码工具类可复用**。
- 可复用资产：SAD 技术栈已确定的构建插件方案（maven-antrun-plugin / copy 插件）；既有 `deploy/scripts/deploy-start-*.sh` 的 jar 命名与路径契约（直接决定产物命名）；`deploy/scripts/load-env.sh` 的 deploy 相对定位模式（`BASH_SOURCE` → PROJECT_DIR=deploy）可作为"以根目录相对方式定位"的参考。
- 相关测试资产：`scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1`（UT-061~072，deploy 结构测试）、`scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1`（UT-073~078，脚本迁移测试）——TASK-004 的 jar 输出测试可沿用类似断言风格。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
