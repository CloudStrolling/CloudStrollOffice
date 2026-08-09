# 网络资料查询结果（#TASK-006 构建验证与 deploy 目录纯净性/完整性校验）

## 1. 查询结论概述

本任务为 cso-v0.2.5 整体验收任务（P0），核心动作是执行 Maven 各模块 package 与 Flutter 客户端构建后，逐项校验 deploy 目录结构与内容（AC-1~AC-7）。经验证，本任务涉及的三方组件/工具均为**构建链既有组件**，无新增引入：

| 组件/工具 | 本项目使用版本 | 官方资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| maven-antrun-plugin | 3.2.0（根 pom.xml 第 59 行） | 3.2.0（2025-10-17 发布） | ✅ 完全一致，官方最新版 |
| spring-boot-maven-plugin | 3.2.5（随 Spring Boot BOM） | 3.2.x / 3.4.x 文档 | ✅ 机制稳定，repackage 行为一致 |
| Flutter CLI | SDK ^3.12.2（pubspec 约束） | 稳定渠道（__branch__main 文档） | ✅ 构建输出路径含架构子目录，与本项目 build-release 脚本一致 |
| Ant copy 任务 | 随 maven-antrun-plugin 内置（Ant 1.10+） | Ant 官方最新版 | ✅ 行为长期稳定 |
| jq（load-env.sh 依赖） | 未锁定，运行时检测 | 1.8 手册 | ✅ 1.4+ 核心语法兼容，本项目仅用基础过滤 |
| Python3（load-env.sh 回退方案） | 运行时检测 | — | ✅ 仅作 jq 回退 |

**核心结论**：本项目根 pom.xml 与各模块 pom.xml 中 maven-antrun-plugin 的配置方式（`<execution>` 绑定 package 阶段、`<copy file tofile>` 单文件复制）与官方推荐用法完全一致；Flutter 构建脚本复制 `build/windows/x64/runner/Release` 与 `build/web` 目录的行为符合官方输出契约。验收时无需升级或变更任何组件版本。

## 2. maven-antrun-plugin（3.2.0）官方文档要点

官方文档：https://maven.apache.org/plugins/maven-antrun-plugin/usage.html （版本 3.2.0，2025-10-17 发布）

### 2.1 核心机制
- 该插件**只有一个 goal：`run`**，作用是在 Maven 构建中运行 Ant 任务。
- 必须在 `<configuration><target>` 中配置 Ant 任务内容（不配 target 也能执行但什么都不做）。
- 通过 `<execution><phase>` 绑定到生命周期阶段（本项目绑定 `package`），通过 `<execution><goals><goal>run</goal>` 声明执行目标。
- 一个插件可复制多个 `<execution>` 绑定不同阶段。

### 2.2 官方模板（与本项目各模块 pom.xml 结构完全一致）
```xml
<plugin>
  <artifactId>maven-antrun-plugin</artifactId>
  <version>3.2.0</version>
  <executions>
    <execution>
      <phase>package</phase>
      <configuration>
        <target>
          <!-- Ant 任务内容，与 build.xml 中 <target> 内可写内容相同 -->
        </target>
      </configuration>
      <goals>
        <goal>run</goal>
      </goals>
    </execution>
  </executions>
</plugin>
```

### 2.3 Maven 属性可用性（本项目关键依赖点）
- Maven 的**所有属性**在 `<target>` 配置中均可直接使用，包括 `${project.build.directory}`、`${project.build.finalName}`、`${project.artifactId}` 等。
- 本项目使用 `${project.build.directory}/${project.build.finalName}.jar` 定位打包产物、`${deployDir}`（自定义属性）定位 deploy 目录，与官方"所有属性在 target 中可用"的说明一致。
- 仅当调用**外部 Ant 脚本**（`<ant antfile="build.xml"/>`）时，才只有 properties 段定义的属性与 `maven.project.*` 前缀属性可见——本项目直接在 `<target>` 内写 copy 任务，不受此限制。

### 2.4 真实项目应用样例（GitHub 检索）
- **irockel/tda**（LGPL-2.1）：`maven-antrun-plugin` 3.2.0 绑定 `prepare-package` 阶段，`<execution id="rename-licenses">` 执行文件重命名，验证了 3.2.0 版本在真实项目中的应用。
- **toolfactory/jvm-driver**（MIT）：通过 `${maven-antrun-plugin.version}=3.1.0` 属性化版本并在 `<execution>` 中使用 `${project.basedir}` 等属性，与本项目属性化版本号（`<maven-antrun-plugin.version>3.2.0</maven-antrun-plugin.version>`）模式一致。
- **appsody/stacks**（Apache-2.0）：Spring Boot 2 项目在 build/plugins 中配置 maven-antrun-plugin `<execution>` 执行构建辅助任务，是"Spring Boot + antrun 共存"的成熟样例。
- 检索未发现"整目录递归复制 target 到产物目录"的推荐做法；业界普遍采用单文件/显式 fileset 复制，佐证本项目"仅复制最终 jar 文件、不递归复制 target"的设计正确性。

## 3. Ant Copy 任务官方文档要点

官方文档：https://ant.apache.org/manual/Tasks/copy.html

### 3.1 与本项目直接相关的属性
| 属性 | 说明 | 本项目用法 |
| --- | --- | --- |
| `file` | 要复制的单个源文件 | `${project.build.directory}/${project.build.finalName}.jar` |
| `tofile` | 复制到的新文件名（可改名） | `${deployDir}/cloudoffice-auth-service.jar` 等（保持模块可辨识命名） |
| `todir` | 复制到的目标目录（与 tofile 二选一） | 未使用 |
| `overwrite` | 是否强制覆盖，**默认 false**——仅当源比目标新或目标不存在时才复制 | `overwrite="true"`（保证每次构建刷新产物） |
| `failonerror` | 源文件不存在时是否终止构建，**默认 true** | 使用默认值（构建失败即报错，符合"构建失败时不落盘失败产物"约束） |
| `preservelastmodified` | 是否保留源文件修改时间，默认 false | 未使用 |

### 3.2 官方示例对照
- 复制单个文件：`<copy file="myfile.txt" tofile="mycopy.txt"/>` — 与本项目 `<copy file="...finalName.jar" tofile="${deployDir}/...jar"/>` 完全同构。
- 单文件复制到目录：`<copy file="myfile.txt" todir="../some/other/dir"/>`。

### 3.3 重要注意事项（验收时值得关注）
- **二进制文件过滤陷阱**：使用 filterset/filter 时二进制文件会被破坏；本项目 copy 任务未启用 filtering，jar 包为纯二进制复制，安全。
- **Windows 大小写陷阱**：若目标目录已存在同文件但大小写不同，复制后文件采用源文件大小写——本项目目标文件名与源 finalName 均统一小写连字符命名，无冲突风险。
- **Unix 权限不保留**：copy 不保留文件权限（UMASK 默认权限）；本任务校验的是文件存在性与内容，不涉及权限位，不影响验收。

## 4. Spring Boot Maven Plugin 官方文档要点

官方文档（context7 收录）：https://docs.spring.io/spring-boot/3.4/maven-plugin/packaging.html（与 3.2.5 行为一致）

- `repackage` goal 作用于 Maven `package` 阶段产生的 artifact，将其重打包为可执行 jar（内含全部依赖），可用 `java -jar` 直接运行。
- 可执行 jar 输出至 **`target` 目录**（如 `target/myapplication-0.0.1-SNAPSHOT.jar`），文件名为 `${project.build.finalName}.jar`——与本项目 antrun 复制源路径 `${project.build.directory}/${project.build.finalName}.jar` 完全对应。
- 官方推荐插件配置：`<execution><goals><goal>repackage</goal></goals></execution>`。本项目各后端模块在 antrun **之前** 配置 spring-boot-maven-plugin（先 repackage 生成可执行 jar，再由 antrun 复制到 deploy），顺序正确——复制的是**最终可执行 jar**而非原始瘦 jar，符合"最终产物"定义。
- 运行方式：`java -jar target/myapplication-0.0.1-SNAPSHOT.jar`；本项目 deploy/scripts 脚本中以 `$PROJECT_DIR/cloudoffice-*.jar` 引用 deploy 下 jar，等价于官方运行方式。

## 5. Flutter 官方构建文档要点

官方文档（context7 收录 /flutter/website）：
- Web 部署：https://github.com/flutter/website/blob/main/sites/docs/src/content/deployment/web.md
- 桌面构建：https://github.com/flutter/website/blob/main/sites/docs/src/content/platform-integration/desktop.md
- Windows 打包：https://github.com/flutter/website/blob/main/sites/docs/src/content/platform-integration/windows/building.md

### 5.1 构建命令与输出目录（本项目 build-release.ps1/.sh 依据）
- `flutter build web`（release 模式）：生成 release 版应用至 **`build/web`** 目录，可通过本地 Web 服务器托管该目录内容直接部署。
- `flutter build windows`（release 模式）：生成 release 版 Windows 应用。
- **重要**：官方指出"Flutter Windows 应用的可执行文件位于**架构相关目录**（architecture-dependent folders）"——即 `build/windows/x64/runner/Release/`（x64 架构）。本项目 build-release.ps1 复制源正是 `build/windows/x64/runner/Release/*`，与官方输出契约一致。

### 5.2 Windows 分发物组成（验收 AC-3/AC-4 依据）
- 官方明确：Windows 分发需包含 `build\windows\runner\<build mode>\`（即 Release 目录）下的：
  - 可执行文件（`.exe`）；
  - 同目录下全部 `.dll`（如 flutter_windows.dll、插件 dll）；
  - `data` 目录（含 app.so、icudtl.dat、flutter_assets/ 等）。
- 与本项目 deploy/cloudoffice-flutter-app/windows/ 下产物（cloudoffice_flutter_app.exe、flutter_windows.dll、flutter_secure_storage_x_windows_plugin.dll、dartjni.dll、data/）结构一致。
- 可选：若目标机器无 Visual C++ 运行库，需将 `msvcp140.dll`、`vcruntime140.dll`、`vcruntime140_1.dll` 一并分发（本项目未内置，属可选优化，不影响 AC 验收）。

### 5.3 纯净性说明（AC-4 依据）
- 官方输出仅位于 `build/` 目录下；`build/` 为构建缓存目录，不应作为交付物。本项目 build-release 脚本仅将 `build/windows/x64/runner/Release/` 与 `build/web/` 内容复制至 deploy，构建缓存 `build/`、`.dart_tool/` 不进入 deploy，符合"仅最终产物、隔离中间产物"。
- Web 产物中 `.last_build_id` 属于 Flutter 构建产物文件（非中间产物），保留在 deploy/cloudoffice-flutter-app/web/ 属正常。

## 6. jq 官方手册要点（load-env.sh 的 JSON 解析依赖）

官方文档：https://jqlang.github.io/jq/manual/（当前 1.8）

### 6.1 与本项目 load-env.sh 直接相关的用法
- 字段提取：`.foo`（对象键取值，如 `.MYSQL_HOST`）；键含特殊字符时用 `.["foo$"]`。
- `-r` / `--raw-output`：字符串结果直接输出（不带引号），适合赋给 shell 变量。
- `-e` / `--exit-status`：输出为 false/null 时退出码 1，可用于脚本判断。
- 管道组合：`jq -r '.DB | .host'` 等价于 `jq -r '.DB.host'`。

### 6.2 跨平台调用注意事项
- Unix shell：jq 程序用**单引号**包裹（`jq '.["foo"]'`）——本项目 .sh 脚本即此用法。
- PowerShell：jq 程序用单引号包裹、内部双引号需反斜杠转义（`jq '.[\"foo\"]'`）——本项目 .ps1 脚本若调用 jq 需注意；load-env.ps1 已改用 PowerShell 原生 `ConvertFrom-Json`，不依赖 jq，规避了该问题。
- Windows 下（WSL/MSYS2/Cygwin 环境）使用原生 jq.exe 时建议加 `-b`/`--binary` 防止 LF→CRLF 转换——本项目 Windows 部署链以 ps1 为主，.sh 面向 Linux，不受影响。

### 6.3 版本兼容性
- jq 1.4~1.8 的基础过滤语法（`.foo`、`-r`、`|`）完全向下兼容；load-env.sh 仅使用基础语法，对任意 ≥1.4 的 jq 均可用，无版本锁定风险。
- load-env.sh 的 python3 回退方案（json 模块解析）在 Python 3.6+ 行为稳定，作为 jq 缺失时的兜底合理。

## 7. 相关任务资料与排错经验（验收执行建议）

### 7.1 Maven 构建与 antrun 常见问题
- **构建顺序**：必须确保 spring-boot-maven-plugin 的 repackage 在 antrun 之前执行（本项目 plugins 声明顺序已保证）。若顺序颠倒，复制到 deploy 的是未重打包的瘦 jar，`java -jar` 会报 "no main manifest attribute"。验收时可抽查 deploy 下 jar 是否可执行（`jar tf xxx.jar | grep BOOT-INF` 或直接 `java -jar` 冒烟）。
- **overwrite 语义**：Ant copy 默认"源比目标新才复制"；本项目显式 `overwrite="true"`，确保每次构建刷新 deploy 产物，避免"验收时 deploy 下是旧 jar"的假阳性。验收前应重新执行 `mvn package` 刷新产物。
- **deployDir 属性解析**：`${maven.multiModuleProjectDirectory}/deploy` 依赖 Maven 3.3.1+ 的 multiModuleProjectDirectory 机制（由 `.mvn` 目录触发）。若在子模块目录单独构建，该属性仍指向多模块根目录，保证四个模块产物统一落位 deploy。
- **Windows 构建**：antrun 的 copy 在 Windows 下对 `tofile` 的路径分隔符 `\` 与 `/` 均兼容；本项目统一 `/` 写法，跨平台无差异。

### 7.2 Flutter 构建常见问题
- **Windows 产物路径**：Flutter 3.10+ 后 Windows 可执行文件位于 `build/windows/x64/runner/Release/`（x64 架构子目录）；若项目升级 Flutter 大版本，需复查 build-release 脚本复制源路径是否仍匹配（官方 breaking change 记录）。
- **构建前清理**：`flutter clean` 后重新构建可避免旧产物残留导致 deploy 中混入过期文件；验收"纯净性"时可先 clean 再 build。
- **Web 产物部署**：官方建议用静态服务器托管 `build/web` 目录；deploy/cloudoffice-flutter-app/web/ 即等价交付物。

### 7.3 deploy 目录纯净性校验要点（AC-4 核对清单）
- 检查 deploy 下**不得出现**：`target` 目录、`build` 目录、`.dart_tool`、`__pycache__`、`*.class`、`*.o`、测试报告（surefire-reports 等）、临时文件（*.tmp）。
- 允许出现：4 个最终 jar、cloudoffice-flutter-app/（windows/ + web/ 最终产物）、env.json、env.example.json、scripts/、.gitkeep。
- 校验手段（Windows PowerShell）：`Get-ChildItem -Recurse deploy | Where-Object { $_.Name -in @('target','build','.dart_tool','__pycache__') -or $_.Extension -in @('.class','.o','.tmp') }` 应返回空。

### 7.4 脚本冒烟执行链路（AC-7）
- 验收要点指定的冒烟链路：`deploy/scripts/load-env.sh` → `deploy/scripts/deploy-check-env.sh`。
- load-env.sh 以 `SCRIPT_DIR` 定位自身、`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"` 推导 deploy 目录，再以 `$PROJECT_DIR/env.json` 加载配置——该"脚本目录推导"模式是部署脚本的通用最佳实践（避免硬编码绝对路径），本项目 deploy/scripts 全部脚本统一采用。
- 若脚本执行报错，优先检查：脚本内是否仍有指向旧路径（根目录 env.json、根目录 jar）的硬编码；PowerShell 执行策略（`Set-ExecutionPolicy -Scope Process Bypass`）是否限制 .ps1 运行。

## 8. 参考资料清单（官方优先）

| 资料 | 地址 | 用途 |
| --- | --- | --- |
| maven-antrun-plugin 官方使用指南 | https://maven.apache.org/plugins/maven-antrun-plugin/usage.html | antrun 配置模板、Maven 属性可用性 |
| Ant Copy Task 官方文档 | https://ant.apache.org/manual/Tasks/copy.html | file/tofile/overwrite 属性语义、Windows 陷阱 |
| Spring Boot Maven Plugin 官方文档 | https://docs.spring.io/spring-boot/3.4/maven-plugin/packaging.html | repackage 目标、可执行 jar 输出位置 |
| Flutter Web 部署官方文档 | https://docs.flutter.dev/deployment/web | flutter build web 输出 build/web |
| Flutter Windows 构建官方文档 | https://docs.flutter.dev/platform-integration/windows/building | Release 产物组成、架构子目录 |
| jq 官方手册 | https://jqlang.github.io/jq/manual/ | load-env.sh JSON 解析语法与跨平台注意事项 |
| GitHub 样例：irockel/tda | https://github.com/irockel/tda | maven-antrun-plugin 3.2.0 真实用法 |
| GitHub 样例：appsody/stacks | https://github.com/appsody/stacks | Spring Boot + antrun 共存模式 |

## 9. 对编码/验收的直接影响（给 TASK-006 执行者的建议）

1. **无需变更任何构建配置**：现有 maven-antrun-plugin 3.2.0 + copy(file/tofile) + overwrite=true + package 阶段绑定的方案与官方文档一致，验收通过后无版本升级压力。
2. **验收前刷新产物**：先执行根目录 `mvn clean package`（跳过测试可加 `-DskipTests`）与 `cloudoffice-flutter-app/build-release.ps1 -Platform all`，确保 deploy 下为最新产物，再执行 AC-1~AC-7 校验，避免"旧产物假阳性"。
3. **可执行性抽查**：`java -jar deploy/cloudoffice-gateway.jar`（或 `jar tf` 检查 BOOT-INF）验证 jar 为 repackage 后的可执行 jar。
4. **纯净性扫描**：按 7.3 节清单扫描 deploy，确认无 target/build/.dart_tool 等中间目录。
5. **脚本冒烟**：按 7.4 节执行 load-env.sh → deploy-check-env.sh 链路，确认 env.json 加载与路径引用正常。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
