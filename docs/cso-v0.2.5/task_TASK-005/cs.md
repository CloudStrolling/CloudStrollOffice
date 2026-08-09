# 本地代码查询报告（#TASK-005 修改 Flutter 客户端构建配置：安装产物统一输出至 deploy）

> 本报告由 impm-task-coding-cs 技能生成，供编码开发阶段使用。
> 项目：云漫智企（CloudStrollOffice，cso）｜版本：v0.2.5｜任务：TASK-005

## 1. 查询结论摘要

| 查询项 | 结论 |
| --- | --- |
| deploy 目录现状 | 已存在（TASK-001~004 完成）：env.json/env.example.json 已迁入；deploy/scripts 下已有 21 个 sh/ps1；4 个后端 jar 已落位 deploy 根目录 |
| 后端 jar 输出方式 | 根 pom.xml 定义 `${deployDir}`，各服务模块用 maven-antrun-plugin 在 package 阶段复制单个最终 jar 至 deploy（**仅复制最终产物文件，不整目录复制**） |
| 客户端构建脚本现状 | **不存在任何客户端构建脚本**（cloudoffice-flutter-app 下无 sh/ps1/bat/cmd），需新建构建脚本实现产物输出 |
| Windows 安装产物 | `flutter build windows --release` → `build/windows/x64/runner/Release/`（x64 架构化路径，Flutter 3.16+），含 `cloudoffice_flutter_app.exe`、flutter_windows.dll、dartjni.dll、flutter_secure_storage_x_windows_plugin.dll、data/ |
| Web 部署产物 | `flutter build web --release` → `build/web/` |
| 中间产物隔离 | `build/` 目录（构建缓存）已被 `.gitignore` 忽略（`/build/`），复制产物时仅复制 Release 目录内最终文件，禁止复制整个 build/ |
| 产物命名约定 | 后端 jar 直接放 deploy 根目录（cloudoffice-xxx.jar）；deploy/scripts 启动脚本从 deploy 根目录读取 jar |

## 2. deploy 目录现状（TASK-001~004 已完成的先决条件）

### 2.1 目录结构（项目根目录 `deploy/`）

```
deploy/
├── .gitkeep                      # 空目录占位（已入库）
├── env.json                      # 环境变量配置（敏感，.gitignore 忽略，不入库）
├── env.example.json              # 环境变量模板（已入库）
├── cloudoffice-gateway.jar       # 后端最终产物（*.jar 被 .gitignore 忽略，不入库）
├── cloudoffice-auth-service.jar
├── cloudoffice-biz-service.jar
├── cloudoffice-system-service.jar
└── scripts/                      # 21 个部署脚本（.sh/.ps1，已入库）
    ├── .gitkeep
    ├── load-env.sh / load-env.ps1
    ├── deploy-check-env.sh / deploy-check-env.ps1
    ├── deploy-db-init.sh / deploy-db-init.ps1
    ├── deploy-env.ps1 / deploy-env-template.sh / deploy-env-template.ps1
    ├── deploy-rsa-keygen.sh / deploy-rsa-keygen.ps1
    ├── deploy-start-gateway/auth/biz/system/services.sh(.ps1)
    └── ...（共 21 个，全部已迁移）
```

### 2.2 git 跟踪现状（git ls-files deploy 验证）

- 已入库：`.gitkeep`、`env.example.json`、`scripts/.gitkeep` 与 21 个 sh/ps1；
- 未入库（正确，符合敏感/产物不入库约定）：`env.json`（裸 `env.json` 规则匹配任意层级）、4 个 jar（`*.jar` 全局忽略）。

## 3. 后端构建产物输出模式（TASK-004 实现，客户端构建配置的直接参照）

### 3.1 根 pom.xml（`pom.xml` 第 55-56 行）

```xml
<!-- 构建产物输出：最终产物统一落点（deploy 目录，以多模块根目录相对方式定位） -->
<deployDir>${maven.multiModuleProjectDirectory}/deploy</deployDir>
```

- 采用 `${maven.multiModuleProjectDirectory}`（Maven 3.3.1+ 内置属性）定位多模块根目录，与工作目录无关。

### 3.2 服务模块 pom.xml（以 `cloudoffice-gateway/pom.xml` 第 95-116 行为例，auth/biz/system 同构）

```xml
<!-- 产物输出：package 阶段将最终可执行 jar 复制至 deploy（在 spring-boot 插件之后，复制 repackage 后的产物） -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-antrun-plugin</artifactId>
    <executions>
        <execution>
            <id>copy-final-jar-to-deploy</id>
            <phase>package</phase>
            <goals>
                <goal>run</goal>
            </goals>
            <configuration>
                <target>
                    <!-- 仅复制单个最终 jar 文件，禁止整目录递归复制 target（保证中间产物不进入 deploy） -->
                    <copy file="${project.build.directory}/${project.build.finalName}.jar"
                          tofile="${deployDir}/cloudoffice-gateway.jar"
                          overwrite="true"/>
                </target>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**可复用要点（客户端构建脚本可沿用同样的原则）：**
1. 在**构建成功后的收尾阶段**复制产物（Maven 是 package 阶段，Flutter 是 build 命令之后）；
2. **只复制最终产物文件**，不递归复制构建输出目录（target/、build/ 均为中间产物所在）；
3. 产物重命名保持模块可辨识（`cloudoffice-{模块}.jar`），`overwrite="true"` 支持重复构建覆盖；
4. 产物直接落 deploy 根目录，deploy/scripts 启动脚本按此路径读取。

## 4. Flutter 客户端工程现状（本任务改造对象）

### 4.1 工程结构与构建入口

- 工程根：`cloudoffice-flutter-app/`，独立 Flutter 工程，应用名 `cloudoffice_flutter_app`；
- `pubspec.yaml`：`version: 0.2.0+1`，SDK `^3.12.2`；依赖 dio/provider/go_router/flutter_secure_storage_x/shared_preferences；**无构建相关配置**；
- `windows/CMakeLists.txt` 第 7 行：`set(BINARY_NAME "cloudoffice_flutter_app")` —— Windows exe 文件名；
- `web/`：标准 Flutter Web 目录（index.html、manifest.json、icons/、favicon.png）；
- **不存在任何构建/打包脚本**（无 sh/ps1/bat/cmd），客户端产物输出需新建脚本实现。

### 4.2 各平台最终产物位置（构建验证的实际路径，已核实）

| 平台 | 构建命令 | 最终产物位置（构建后） | 产物内容 |
| --- | --- | --- | --- |
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/`（**x64 架构化路径**，Flutter 3.16+；旧文档写的 `build/windows/runner/Release/` 已过时） | `cloudoffice_flutter_app.exe`、`flutter_windows.dll`、`dartjni.dll`、`flutter_secure_storage_x_windows_plugin.dll`、`data/`（flutter_assets 资产） |
| Web | `flutter build web --release` | `build/web/` | index.html、main.dart.js、assets/、icons/ 等标准 Web 部署包 |

> 说明：Windows Release 目录整体即为可运行交付包（exe + 依赖 DLL + data），目标机器需安装 Visual C++ Redistributable。当前无 Inno Setup 等安装包工具配置，本任务最终交付形式（裸 Release 目录 / 压缩包 / 安装程序 exe）由编码阶段按 F-003 决定，cs.md 仅记录现状。

### 4.3 中间产物隔离现状

- `build/` 目录为 Flutter 构建缓存（编译中间产物），已被 `cloudoffice-flutter-app/.gitignore` 第 33 行 `/build/` 与根 `.gitignore` 第 183 行 `build/` 双重忽略；
- 构建过程文件（`build/windows/x64/` 下的 vcxproj、CMakeFiles、.dir 等，`build/web/` 的临时文件）均属于中间产物，**不得复制进 deploy**（AC-4）。

## 5. deploy/scripts 部署脚本的产物路径引用（客户端产物命名/放置参照）

以 `deploy/scripts/deploy-start-gateway.ps1` 第 11-12 行为例：

```powershell
$ProjectDir = Split-Path -Parent $PSScriptRoot          # 脚本在 deploy/scripts，上溯 1 级得到 deploy
$JarPath = Join-Path $ProjectDir "cloudoffice-gateway.jar"  # jar 从 deploy 根目录读取
```

- **结论**：部署运维脚本约定"最终产物放 deploy 根目录"。客户端最终产物（exe/Web 包）若直接放 deploy 根目录与后端 jar 并列，与现有约定一致，也便于 deploy/scripts 未来的客户端启动/安装脚本引用；若放 deploy 下子目录（如 `deploy/client/`），则相关脚本引用需同步适配（本任务不涉及启动脚本改造，由编码阶段权衡）。

## 6. .gitignore 相关规则（根目录 .gitignore）

| 规则 | 行号 | 影响 |
| --- | --- | --- |
| `env.json` | 第 311 行 | 裸规则匹配任意层级，`deploy/env.json` 仍被忽略（敏感文件不入库，正确，无需改动） |
| `*.jar` | 第 233 行 | deploy 下 jar 不入库（现状即如此，无需改动） |
| `*.exe` / `*.dll` | 第 244-245 行 | 客户端 exe/dll 若落位 deploy 默认不入库；如需入库须追加放行规则 `!deploy/**/*.exe` 等（位于全局规则之后） |
| `build/` | 第 183 行 | 客户端构建缓存全局忽略，无需改动 |

## 7. 相关文档与既有资料（编码阶段参考）

| 文件 | 关键内容 |
| --- | --- |
| `scripts/deployment-guide.md` 第 11 章 | Flutter 前端编译与部署：Web/Windows 构建命令、部署方式（注意其 Windows 产物路径写的是旧版 `build/windows/runner/Release/`，实际为 x64 路径） |
| `docs/cso-v0.2.5/task_TASK-001/ws.md` 第 3.3 节 | Flutter Windows 产物位置官方结论：构建后复制 Release 目录内容到 deploy（或仅复制 exe+dll+data），Flutter 无 `--output` 参数直接改 Windows 产物路径 |
| `docs/cso-v0.2.5/task_TASK-001/cs.md` | 客户端产物路径现状记录（x64 路径） |
| `docs/cso-v0.2.5/task_TASK-003/ws.md` | 脚本迁移后的路径适配记录（`$PSScriptRoot` 上溯 2 级等） |

## 8. 给编码阶段的落地建议（TL 提示汇总）

1. **新建客户端构建脚本**：`cloudoffice-flutter-app` 下新建构建脚本（如 `build-release.ps1` / `build-release.sh`，或按项目 scripts 惯例放 deploy/scripts 之外由客户端工程自带），执行 `flutter pub get` → `flutter build windows --release`（可选 Web）→ **仅复制最终产物文件**至 deploy；
2. **Windows 产物复制**：复制 `build/windows/x64/runner/Release/` 下的 `cloudoffice_flutter_app.exe`、`flutter_windows.dll`、`dartjni.dll`、`flutter_secure_storage_x_windows_plugin.dll`、`data/`（或整体复制 Release 目录内全部文件）到 deploy，**严禁复制 build/ 其余目录与文件**（AC-4）；
3. **Web 产物复制**（如本任务覆盖）：复制 `build/web/` 目录内容到 deploy（Web 包本身就是最终可交付物）；
4. **产物落点**：与后端 jar 一致放 deploy 根目录（与 deploy/scripts 启动脚本约定一致）；如有同名冲突风险，按 TASK-004 模式重命名（如 `cloudoffice-flutter-app-windows-{版本}.exe` 或目录化 `deploy/cloudoffice-flutter-app/`），由编码阶段决定；
5. **中间产物隔离**：复制动作只针对最终产物文件/目录，构建缓存 build/ 与过程文件不进入 deploy；
6. **测试方式**：构建验证——执行客户端构建后校验 exe/Web 包出现在 deploy（AC-3）、deploy 内无 build 缓存与过程文件（AC-4）。

## 9. 关键文件路径索引

| 文件 | 路径 |
| --- | --- |
| 根 Maven POM（deployDir 定义） | `pom.xml` |
| 模块 POM 产物复制示例 | `cloudoffice-gateway/pom.xml`（auth/biz/system 同构） |
| 客户端 pubspec | `cloudoffice-flutter-app/pubspec.yaml` |
| Windows exe 名称定义 | `cloudoffice-flutter-app/windows/CMakeLists.txt` |
| Windows Release 产物目录 | `cloudoffice-flutter-app/build/windows/x64/runner/Release/` |
| Web 产物目录 | `cloudoffice-flutter-app/build/web/` |
| 部署脚本路径引用示例 | `deploy/scripts/deploy-start-gateway.ps1` |
| 根 .gitignore | `.gitignore` |
| 客户端 .gitignore | `cloudoffice-flutter-app/.gitignore` |
| 部署指南（Flutter 构建章节） | `scripts/deployment-guide.md` 第 11 章 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
