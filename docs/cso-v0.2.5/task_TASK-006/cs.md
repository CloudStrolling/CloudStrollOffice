# 代码查询结果（#TASK-006 构建验证与 deploy 目录纯净性/完整性校验）

## 1. 查询范围与结论概述

本任务为 v0.2.5 整体验收任务（P0），需逐项核对 deploy 目录结构、构建产物落位、纯净性、迁移完整性、脚本可执行性（AC-1~AC-7）。经本地代码查询确认：

- **deploy 目录结构已完整就绪**（由上游 TASK-001~005 完成）：env 两文件、scripts 子目录（21 个 sh/ps1）、4 个后端 jar、客户端产物均已落位；
- **构建配置已生效**：根 pom.xml 定义 `deployDir` 属性，四个后端模块通过 maven-antrun-plugin 在 package 阶段仅复制单个最终 jar 至 deploy；Flutter 通过 `build-release.ps1/.sh` 复制最终产物至 deploy/cloudoffice-flutter-app；
- **迁移完整**：根目录不再有 env.json/env.example.json；scripts 顶层无 sh/ps1 残留，非脚本内容（sql、docker、API-TEST、deployment-guide.md）保持在原位；
- **脚本路径已适配**：deploy/scripts 下脚本以 `SCRIPT_DIR → PROJECT_DIR(=deploy)` 相对定位 env.json 与 jar 包，冒烟链路 load-env → deploy-check-env 可执行。

## 2. deploy 目录现状（AC-1/AC-2/AC-3/AC-4 直接核对对象）

根目录 `deploy/` 已存在，结构如下：

```
deploy/
├── .gitkeep                                # 占位（目录可提交）
├── env.json                                # 环境配置（已迁移，根目录不再保留）
├── env.example.json                        # 环境配置模板（已迁移）
├── cloudoffice-auth-service.jar            # 认证服务最终 jar（AC-2）
├── cloudoffice-biz-service.jar             # 企业服务最终 jar（AC-2）
├── cloudoffice-gateway.jar                 # 网关最终 jar（AC-2）
├── cloudoffice-system-service.jar          # 系统服务最终 jar（AC-2）
├── cloudoffice-flutter-app/                # 客户端最终产物子目录（AC-3）
│   ├── .gitkeep
│   ├── windows/                            # Windows 安装产物（exe/dll/data）
│   │   ├── cloudoffice_flutter_app.exe
│   │   ├── flutter_windows.dll
│   │   ├── flutter_secure_storage_x_windows_plugin.dll
│   │   ├── dartjni.dll
│   │   └── data/（app.so、icudtl.dat、flutter_assets/ 等）
│   └── web/                                # Web 部署包
│       ├── index.html、main.dart.js、manifest.json、version.json
│       ├── flutter_bootstrap.js、flutter.js、flutter_service_worker.js
│       ├── favicon.png、icons/、canvaskit/、assets/、.last_build_id
└── scripts/                                # 部署脚本子目录（21 个 sh/ps1，AC-6）
    ├── .gitkeep
    ├── load-env.sh / load-env.ps1
    ├── deploy-check-env.sh / deploy-check-env.ps1
    ├── deploy-env.ps1（仅 ps1）
    ├── deploy-env-template.sh / deploy-env-template.ps1
    ├── deploy-db-init.sh / deploy-db-init.ps1
    ├── deploy-rsa-keygen.sh / deploy-rsa-keygen.ps1
    ├── deploy-start-auth.sh / deploy-start-auth.ps1
    ├── deploy-start-biz.sh / deploy-start-biz.ps1
    ├── deploy-start-gateway.sh / deploy-start-gateway.ps1
    ├── deploy-start-services.sh / deploy-start-services.ps1
    └── deploy-start-system.sh / deploy-start-system.ps1
```

脚本数量核对：`deploy/scripts` 下 .sh 共 **10 个**、.ps1 共 **11 个**，合计 **21 个**，与验收要点"21 个 sh/ps1"一致。
纯净性核对：deploy 内**不存在** target 类目录、编译临时文件、测试产物、构建缓存（无 build/、.dart_tool/、__pycache__ 等），符合 AC-4。

## 3. scripts 目录现状（AC-6 非脚本内容保留）

根目录 `scripts/` 仅保留非 sh/ps1 内容（未被迁移，符合预期）：

- `scripts/deployment-guide.md` — 部署指南文档
- `scripts/sql/` — init.sql、init-v0.2.0-full.sql、auth-init-v0.1.5.sql、auth-init-v0.1.6.sql
- `scripts/docker/` — auth-service/biz-service/gateway/system-service 四个 Dockerfile + docker-compose.yml
- `scripts/API-TEST/` — 接口/单元测试脚本（cso-api-test-v0.2.5.py、cso-unit-test-*-v0.2.5.ps1、test_auth_api.py、__pycache__）

根目录 `scripts/` 顶层仅剩 `deployment-guide.md`，**无 sh/ps1 残留**。

## 4. Maven 构建配置（TASK-003 成果，AC-2/AC-4 依据）

### 4.1 根 pom.xml（cloudoffice/pom.xml）
- 第 56 行：`<deployDir>${maven.multiModuleProjectDirectory}/deploy</deployDir>` — 最终产物统一落点，以多模块根目录相对定位；
- 第 59 行：`<maven-antrun-plugin.version>3.2.0</maven-antrun-plugin.version>`；
- 第 165-170 行：pluginManagement 中登记 maven-antrun-plugin。

### 4.2 各后端模块 pom.xml（auth-service / biz-service / gateway / system-service）
统一模式（以 cloudoffice-auth-service/pom.xml 第 130-151 行为例）：
- 构建插件顺序：`spring-boot-maven-plugin`（repackage 可执行 jar）在前，`maven-antrun-plugin` 在后；
- execution `copy-final-jar-to-deploy` 绑定 package 阶段；
- 复制语句：`<copy file="${project.build.directory}/${project.build.finalName}.jar" tofile="${deployDir}/cloudoffice-auth-service.jar" overwrite="true"/>`；
- **关键设计**：仅复制单个最终 jar 文件（file/tofile），禁止整目录递归复制 target，保证中间产物不进入 deploy（AC-4）。

各模块产物命名契约（与 deploy/scripts/deploy-start-* 脚本引用一致）：
| 模块目录 | 产出文件名 |
| cloudoffice-auth-service | cloudoffice-auth-service.jar |
| cloudoffice-biz-service | cloudoffice-biz-service.jar |
| cloudoffice-gateway | cloudoffice-gateway.jar |
| cloudoffice-system-service | cloudoffice-system-service.jar |

### 4.3 cloudoffice-common
无任何 copy/deploy 输出配置（纯公共库，不产出部署 jar，符合 UT-083 负向约束）。

## 5. Flutter 客户端构建（TASK-004 成果，AC-3/AC-4 依据）

- **构建脚本**：`cloudoffice-flutter-app/build-release.ps1`（Windows/PowerShell）与 `cloudoffice-flutter-app/build-release.sh`（Bash），参数 `-Platform all|windows|web`；
- **路径定位**：由脚本自身目录推导 —— `$ProjectDir = Split-Path $PSScriptRoot`，`$DeployDir = deploy`，`$ClientDeployDir = deploy/cloudoffice-flutter-app`；前置检查 deploy 必须存在；
- **Windows 产物**：`flutter build windows --release` → 复制 `build/windows/x64/runner/Release/*` → `deploy/cloudoffice-flutter-app/windows/`；
- **Web 产物**：`flutter build web --release` → 复制 `build/web/*` → `deploy/cloudoffice-flutter-app/web/`；
- **纯净性**：仅复制最终产物（exe/dll/data 或 web 部署包），构建缓存 build/ 不进入 deploy（AC-4）。

## 6. deploy/scripts 脚本路径适配（TASK-005 成果，AC-7 依据）

统一定位模式：`SCRIPT_DIR`=脚本自身目录（deploy/scripts），`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`=deploy。

| 脚本 | 关键路径引用 | 适配结果 |
| load-env.sh | `ENV_FILE_PATH=$PROJECT_DIR/$ENV_FILE`（默认 env.json → deploy/env.json），jq 优先、python3 回退 | 正确 |
| deploy-check-env.sh | `ROOT_DIR`=项目根；`source "$SCRIPT_DIR/load-env.sh"`；SQL 检查用 `$ROOT_DIR/scripts/sql/...`；pom.xml 检查用 `$ROOT_DIR/pom.xml` | 正确 |
| deploy-start-services.sh | 检查 `$PROJECT_DIR/env.json`（deploy/env.json）；`source load-env.sh` | 正确 |
| deploy-start-auth.sh | `JAR_PATH="$PROJECT_DIR/cloudoffice-auth-service.jar"`（deploy/ 下 jar）；`source load-env.sh` | 正确 |

冒烟链路（验收要点指定）：`load-env.sh` → `deploy-check-env.sh`，两脚本路径引用均指向 deploy 内 env.json，可正常执行。

## 7. .gitignore 相关规则（AC-4/AC-5 补充依据）

- 第 224 行 `target/` — Maven 中间产物忽略；
- 第 233-234 行 `*.jar`、`*.war` — 后端 jar 产物忽略（deploy 下 jar 不提交）；
- 第 244-248 行 `*.exe`、`*.dll` 等 — 客户端产物忽略；
- 第 274-277 行 `.dart_tool/`、`.flutter-plugins*` — Flutter 构建缓存忽略；
- 第 311 行 `env.json` — 环境配置不入库（deploy/env.json 同样命中）；
- deploy 目录通过 `deploy/.gitkeep`、`deploy/scripts/.gitkeep`、`deploy/cloudoffice-flutter-app/.gitkeep` 占位提交。

## 8. 测试脚本与验收记录（本任务执行依据）

- 上游任务已有测试脚本位于 `scripts/API-TEST/`（非脚本内容，未迁移）：
  - `cso-unit-test-deploy-v0.2.5.ps1`（UT-061~UT-072：deploy 目录/scripts/env 迁移校验）
  - `cso-unit-test-scripts-migrate-v0.2.5.ps1`（脚本迁移完整性校验）
  - `cso-unit-test-build-deploy-v0.2.5.ps1`（UT-079~UT-084：deployDir 属性、jar 命名契约、common 无输出、git 策略）
  - `cso-unit-test-client-build-v0.2.5.ps1`（UT-088/UT-089：客户端产物落位与 deploy 纯净性）
  - `cso-api-test-v0.2.5.py`（接口测试）
- 版本测试用例文档：`docs/cso-v0.2.5/cso-testcase-v0.2.5.md` — 当前尚无 TASK-006 验收记录（grep 未命中），本任务执行后需将 AC-1~AC-7 校验结果记录至该文档。

## 9. 复用组件与注意事项

- **可复用**：`deploy/scripts/load-env.sh`（env.json 加载，jq/python3 双方案）、`deploy/scripts/load-env.ps1`（PowerShell 版）、deploy 目录相对路径定位模式（SCRIPT_DIR/PROJECT_DIR/ROOT_DIR 三层推导，无硬编码绝对路径）；
- **注意**：验收时应确认 deploy 下 jar 为最新构建产物（构建后刷新）；客户端 Web 产物含 `.last_build_id` 属 Flutter 构建产物文件，非中间产物；scripts/API-TEST 下 ps1 属"非脚本内容（API-TEST）"未迁移，符合 AC-6 约定。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
