# 编译方案（build.md）

**项目名称**：云漫智企（CloudStrollOffice）
**项目英文缩写**：cso
**适用版本**：v0.2.5（部署资产集中化）
**文档位置**：deploy/build.md
**最近更新**：2026-08-09

## 1. 文档说明

本文档说明云漫智企（CloudStrollOffice）v0.2.5 版本全部最终产物的编译方法与步骤。

自 v0.2.5 起，项目执行"部署资产集中化"策略：**deploy 目录是所有最终构建产物的唯一落点**（对应 PRD F-001 ~ F-007）：
- 后端微服务 jar 包 → `deploy/`（cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）
- 客户端产物 → `deploy/cloudoffice-flutter-app/`（web/、windows/）
- 环境配置 → `deploy/env.json`、`deploy/env.example.json`
- 编译/部署脚本 → `deploy/scripts/`

**中间产物（各模块 target 目录、客户端 build 缓存、测试产物等）严禁进入 deploy 目录**（AC-4）。

## 2. 编译环境要求

| 项目 | 要求 | 说明 |
| --- | --- | --- |
| 操作系统 | Windows 10/11 或 Linux | Windows 桌面客户端原生构建需 Windows 环境；Web 与后端可在 Linux 构建 |
| JDK | 21（如 Eclipse Temurin 21 / Oracle JDK 21） | 后端编译与运行，需配置 `JAVA_HOME` |
| Maven | 3.8+（推荐 3.9.x） | 后端多模块构建 |
| Flutter SDK | 3.x（Dart 3，pubspec 要求 SDK ^3.12.2） | 客户端构建，需配置 PATH |
| Git | 2.x | 拉取源码 |

## 3. 依赖安装

### 3.1 后端依赖（Maven）

Maven 构建时自动从中央仓库下载依赖，无需手动安装。如网络受限，可在 `~/.m2/settings.xml` 中配置阿里云镜像加速。

### 3.2 客户端依赖（Flutter）

在客户端工程目录 `cloudoffice-flutter-app/` 下执行：

```powershell
flutter pub get
```

构建脚本（build-release.ps1 / build-release.sh）会自动执行该步骤。

## 4. 后端编译（Maven 多模块）

### 4.1 编译命令

在**项目根目录**执行（一次性构建全部模块）：

```powershell
mvn clean package -DskipTests
```

说明：
- 依次构建 5 个模块：cloudoffice-common、cloudoffice-gateway、cloudoffice-auth-service、cloudoffice-biz-service、cloudoffice-system-service。
- package 阶段，四个服务模块通过 `maven-antrun-plugin` 将**最终可执行 jar 复制至 deploy 目录**（仅复制单个最终 jar 文件，不递归复制 target，保证中间产物不进入 deploy）。
- `-DskipTests` 可选：跳过测试加速构建；执行完整测试请去掉该参数。
- 构建输出目录由根 pom.xml 属性 `deployDir=${maven.multiModuleProjectDirectory}/deploy` 统一指定。

### 4.2 后端编译产物

| 产物 | 落点 | 默认端口 | 说明 |
| --- | --- | --- | --- |
| cloudoffice-gateway.jar | deploy/ | 9000 | API 网关（统一入口） |
| cloudoffice-auth-service.jar | deploy/ | 9100 | 认证服务 |
| cloudoffice-biz-service.jar | deploy/ | 9200 | 企业服务 |
| cloudoffice-system-service.jar | deploy/ | 9400 | 系统服务 |

### 4.3 中间产物控制

- 各模块 `target/` 目录为构建中间产物，保留在模块目录内，**不进入 deploy**。
- antrun 插件仅复制 `${project.build.directory}/${project.build.finalName}.jar` 单个最终文件（各模块 pom.xml 中 `copy-final-jar-to-deploy` 执行段）。

## 5. 客户端编译（Flutter）

### 5.1 编译命令

客户端提供官方构建脚本（位于 `cloudoffice-flutter-app/` 目录）：
- Windows：`build-release.ps1`
- Linux/macOS：`build-release.sh`

```powershell
# 构建 Windows + Web 全部平台（默认）
.\cloudoffice-flutter-app\build-release.ps1

# 仅构建 Web（可部署到任意 HTTP 服务器）
.\cloudoffice-flutter-app\build-release.ps1 -Platform web

# 仅构建 Windows 桌面
.\cloudoffice-flutter-app\build-release.ps1 -Platform windows
```

Bash 环境用法：`./build-release.sh`、`./build-release.sh web`、`./build-release.sh windows`。

也可以直接使用 Flutter 原生命令（在 `cloudoffice-flutter-app/` 目录）：

```powershell
flutter pub get
flutter build windows --release   # Windows 桌面（仅 Windows 环境）
flutter build web --release       # Web 部署包
```

**注意**：原生命令的产物输出在客户端 `build/` 目录下，需按 build-release 脚本的方式将最终产物复制到 `deploy/cloudoffice-flutter-app/`；推荐直接使用 build-release 脚本，一步完成"构建 + 落位 deploy"。

### 5.2 客户端编译产物

| 产物 | 落点 | 说明 |
| --- | --- | --- |
| Windows 桌面产物（exe/dll/data） | deploy/cloudoffice-flutter-app/windows/ | 桌面客户端，主程序 cloudoffice_flutter_app.exe |
| Web 部署包 | deploy/cloudoffice-flutter-app/web/ | Web 静态站点，可部署到任意 HTTP 服务器 |

### 5.3 中间产物控制

- 客户端 `build/` 目录（构建缓存与编译过程文件）**不进入 deploy**。
- build-release 脚本仅复制最终产物目录内容（`build/windows/x64/runner/Release`、`build/web`），严禁整目录递归复制 `build/`（AC-4）。

## 6. 便捷编译脚本（deploy/scripts/）

自 v0.2.5 起，`deploy/scripts/` 提供一键编译入口（与本文档命令等价）：

| 脚本 | 说明 |
| --- | --- |
| build-backend.ps1 / build-backend.sh | 一键构建后端全部模块，jar 自动落位 deploy/ |
| build-client.ps1 / build-client.sh | 一键构建客户端（Windows+Web 或指定平台），产物落位 deploy/cloudoffice-flutter-app/ |

用法示例（PowerShell）：

```powershell
.\deploy\scripts\build-backend.ps1
.\deploy\scripts\build-client.ps1             # 构建 Windows + Web
.\deploy\scripts\build-client.ps1 -Platform web
```

## 7. 常见问题与处理

| 问题 | 原因 | 处理 |
| --- | --- | --- |
| mvn 不是内部或外部命令 | Maven 未安装或未配置 PATH | 安装 Maven 3.8+，配置 MAVEN_HOME 与 PATH |
| 编译报错：无效的发行版本 21 | 本机 JDK 版本不是 21 | 安装 JDK 21，检查 `java -version` 与 JAVA_HOME |
| flutter 不是内部或外部命令 | Flutter SDK 未配置 PATH | 安装 Flutter 3.x，执行 `flutter doctor` 自检 |
| Maven 依赖下载失败/超时 | 网络受限或仓库不可达 | 配置阿里云 Maven 镜像后重试 |
| Windows 构建失败（MSVC 相关报错） | 缺少 Visual Studio C++ 工具链 | 安装 VS 2022 并勾选"使用 C++ 的桌面开发"工作负载 |
| 构建成功但 deploy 下没有 jar | 某模块编译失败或未执行 package | 查看 Maven 输出修复后重新 `mvn clean package` |
| deploy 目录出现 target/build 中间目录 | 手工整目录复制了构建输出 | 删除误复制内容，改用 antrun / build-release 脚本方式 |

## 8. 参考

- 部署方案：deploy/deploy.md
- 产品需求文档 v0.2.5：docs/cso-v0.2.5/cso-prd-v0.2.5.md（F-001 ~ F-007 构建产物集中化需求）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
