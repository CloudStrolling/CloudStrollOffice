# 网络资料查询报告（#TASK-001 新建 deploy 目录与 deploy/scripts 子目录）

## 1. 查询结论摘要

| 查询项 | 结论 |
| --- | --- |
| 本任务是否依赖三方组件 | **不依赖**（common 任务，仅文件系统操作：新建 `deploy/` 与 `deploy/scripts/`） |
| 本任务直接使用的技术 | PowerShell `New-Item -ItemType Directory -Force` 幂等创建目录（官方文档确认） |
| 下游 TASK-002/003 资料 | Maven 产物重定向（`spring-boot-maven-plugin` outputDirectory/finalName 等 4 种方式）；Flutter Windows exe 产物位置与复制方法 |
| 下游 TASK-005 资料 | 脚本迁移的路径适配要点（上溯 2 级推导项目根）、env.json/jar 路径引用调整 |
| 版本兼容性 | 全部兼容：Spring Boot 3.2.5 的 Maven 插件参数可用；Flutter x64 产物路径与 cs.md 现状一致；PowerShell 5.1 支持 -Force 嵌套创建 |

## 2. 三方组件识别（步骤 3 结论）

根据 context.md 与 cs.md 分析，**本任务（TASK-001）不需要引入任何第三方中间件、包或 SDK**——任务只要求：

1. 在项目根目录新建 `deploy` 目录（已存在则复用不覆盖）；
2. 新建 `deploy/scripts` 子目录；
3. 目录性质约束：只放最终产物、env 配置与部署脚本，不放源代码与中间产物。

但本任务是 TASK-002~TASK-005 的 P0 前置任务，为后续编码阶段提供资料支撑，特查询以下相关技术资料：

- 后端产物重定向（TASK-002/003 用）：Spring Boot Maven Plugin 输出目录配置
- 客户端产物重定向（TASK-003 用）：Flutter Windows 构建产物位置与打包
- 本任务自身操作（建目录）：PowerShell New-Item
- .gitignore 放行规则（产物入库可选）：gitignore 否定模式

## 3. 本任务直接使用的技术资料（步骤 4/6 查询结果）

### 3.1 PowerShell 创建目录（本任务编码实现方式）

**官方文档**：Microsoft Learn — `New-Item`（Microsoft.PowerShell.Management 模块）
URL: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item

关键用法（**兼容 Windows PowerShell 5.1**，即当前开发环境）：

```powershell
# 基本用法：创建单个目录
New-Item -ItemType Directory -Path "C:\ps-test\scripts"

# 推荐：-Force 幂等创建嵌套目录（目录已存在时不报错、不覆盖已有内容）
New-Item -Path "<项目根>\deploy\scripts" -ItemType Directory -Force | Out-Null
```

要点：
- `-Force` 会自动创建路径中所有缺失的中间层级目录；
- 目录已存在时 `-Force` **不会删除或覆盖**已有内容（官方 Example 8 明确说明），恰好满足"deploy 已存在时复用不覆盖"的验收要求；
- 可用 `Test-Path -PathType Container` 先校验目录是否存在；
- 空目录不会被 git 跟踪，需放入占位文件（如 `.gitkeep`）才能入库（若需入库）。

### 3.2 Spring Boot Maven Plugin 产物输出目录配置（TASK-002 后端 jar 重定向依据）

**官方文档**：Spring Boot Maven Plugin — Packaging 章节（中文镜像：https://docs.springframework.org.cn/spring-boot/maven-plugin/packaging.html）

核心参数（源码 `RepackageMojo.java` 确认）：

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `outputDirectory` | `${project.build.directory}`（即 target/） | 重新打包归档文件的输出目录；**目标目录不存在时插件会自动创建**（`getTargetFile` 中 `mkdirs()`） |
| `finalName` | `${project.build.finalName}` | 输出文件名（不含扩展名） |

产物路径 = `outputDirectory/finalName[-classifier].jar`

**方式一：直接配置 repackage 的 outputDirectory（推荐，最简洁）**

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>repackage</id>
            <goals>
                <goal>repackage</goal>
            </goals>
            <configuration>
                <outputDirectory>${project.parent.basedir}/deploy</outputDirectory>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**方式二：maven-jar-plugin 的 outputDirectory（适用于普通 jar）**

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-jar-plugin</artifactId>
    <configuration>
        <outputDirectory>${project.parent.basedir}/deploy</outputDirectory>
    </configuration>
</plugin>
```

**方式三：maven-resources-plugin 的 copy-resources（package 阶段复制，保留 target 中间产物）**

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-resources-plugin</artifactId>
    <executions>
        <execution>
            <id>copy-jar-to-deploy</id>
            <phase>package</phase>
            <goals>
                <goal>copy-resources</goal>
            </goals>
            <configuration>
                <outputDirectory>${project.parent.basedir}/deploy</outputDirectory>
                <resources>
                    <resource>
                        <directory>${project.build.directory}</directory>
                        <includes>
                            <include>*.jar</include>
                        </includes>
                    </resource>
                </resources>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**方式四：maven-antrun-plugin（ant 任务复制，最灵活）**

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-antrun-plugin</artifactId>
    <executions>
        <execution>
            <id>copy-jar</id>
            <phase>package</phase>
            <goals><goal>run</goal></goals>
            <configuration>
                <target>
                    <copy todir="${project.parent.basedir}/deploy" overwrite="true">
                        <fileset dir="${project.build.directory}">
                            <include name="*.jar"/>
                        </fileset>
                    </copy>
                </target>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**注意事项（对多模块项目尤为重要）**：
- 本项目为 Maven 多模块（父 POM + 4 个服务模块），各子模块 pom 中引用父目录需用 `${project.parent.basedir}` 而非 `${basedir}`（basedir 是当前模块目录）；
- 建议仅对 4 个服务模块（gateway/auth/biz/system）配置，公共模块 common 无启动类、不产可执行 jar，无需配置；
- 若采用"复制"方式（方式三/四），**target 中间产物保留在模块内、deploy 只放最终 jar**，符合"中间产物不进 deploy"约束；若采用"直接输出"（方式一/二），则输出时即落在 deploy，中间产物仍在 target（repackage 前有原 jar），同样满足约束。

### 3.3 Flutter Windows 产物位置与打包（TASK-003 客户端 exe 依据）

**官方文档**：
- Flutter 官方（Building Windows apps）：https://docs.flutter.dev/platform-integration/windows/building
- Flutter 官方（Build and release a Windows desktop app）：https://docs.flutter.dev/deployment/windows

关键结论：
- 构建命令：`flutter build windows --release`
- 产物路径（x64 架构化，自 Flutter 3.16 起）：`build\windows\x64\runner\Release\my_app.exe`
  （旧版为 `build\windows\runner\Release\`，本项目 cs.md 记录的为 x64 路径，即新版）
- exe 同级目录包含：`flutter_windows.dll`、`data/` 目录（资产）、及其他依赖 DLL；
- 发布到其他电脑还需要 **Visual C++ Redistributable**（msvcp140.dll、vcruntime140.dll、vcruntime140_1.dll 等）；
- **推荐做法**：`flutter build windows --release` 后在构建脚本中把 Release 目录整体复制到 `deploy/`（或仅复制 exe + dll + data 目录），由打包脚本（Inno Setup / 自研脚本）生成安装文件并输出至 deploy；
- Flutter 本身无 `--output` 参数直接改 Windows 产物路径，通常通过"构建后复制"实现重定向。

### 3.4 .gitignore 放行规则（如产物需入库时参考）

**官方文档**：Git — gitignore：https://git-scm.com/docs/gitignore

要点（Stack Overflow 高票答案与官方文档确认）：
- `!` 前缀可否定（放行）被忽略的文件，**但若父目录被整体忽略，则无法重新包含其中的文件**；
- 正确放行 deploy 下 jar/exe 的写法（放在 `*.jar`、`*.exe` 规则**之后**）：

```gitignore
*.jar
*.exe
# 放行 deploy 下的最终产物（若需要入库）
!deploy/**/*.jar
!deploy/**/*.exe
```

- 项目现状：`env.json` 规则（第 311 行）匹配任意层级，迁至 `deploy/env.json` 后仍会被忽略（符合敏感文件不入库要求，无需调整）；`*.jar`/`*.exe` 全局忽略，是否放行 deploy 下产物由 TASK-002/003 决策。

## 4. 版本兼容性核对（步骤 5）

| 组件 | 项目当前版本 | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Spring Boot Maven Plugin | Spring Boot 3.2.5（插件版本由父 POM 管理） | 官方文档最新版；`outputDirectory`/`finalName` 自 1.0.0 起存在，无破坏性变更 | **兼容**。3.2.5 完全支持上述 4 种配置方式 |
| Flutter | Dart 3 / Flutter SDK ^3.12.2（pubspec SDK 约束），实际产物路径为 `build/windows/x64/...` | 官方文档（x64 架构化路径自 Flutter 3.16 起） | **兼容**。项目产物路径与官方最新路径一致，`flutter build windows --release` 命令稳定 |
| PowerShell | Windows PowerShell 5.1（win32 开发环境） | Microsoft Learn 官方（覆盖 5.1/7.x） | **兼容**。`New-Item -Force`、`Test-Path` 在 5.1 全部可用 |
| git | 仓库使用 .gitignore | 官方 gitignore 文档 | **兼容**。否定模式规则适用于所有 git 版本 |

## 5. 相关任务资料（步骤 6 补充）

### 5.1 脚本迁移路径适配（TASK-005 关键点）

基于 cs.md 第 6 节的分析，补充业界通用做法：
- PowerShell 脚本中 `$PSScriptRoot` 是脚本所在目录；脚本从 `scripts/` 迁至 `deploy/scripts/` 后，"脚本目录 → 项目根"的上溯层级由 1 级变为 **2 级**（`Split-Path -Parent (Split-Path -Parent $PSScriptRoot)`）；
- env.json 引用：`$ProjectDir\env.json` → `$ProjectDir\deploy\env.json`；
- jar 引用：`$ProjectDir\{模块}\target\*.jar` → `$ProjectDir\deploy\*.jar`；
- Bash 同理：`SCRIPT_DIR` 上溯两级，`PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"`。

### 5.2 目录创建验收方式（本任务测试方法）

```
Test-Path -LiteralPath "<项目根>\deploy" -PathType Container   # → True
Test-Path -LiteralPath "<项目根>\deploy\scripts" -PathType Container  # → True
```

## 6. 参考资料清单

| # | 资料 | 类型 | URL |
| --- | --- | --- | --- |
| 1 | Microsoft Learn：New-Item cmdlet | 官方文档 | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item |
| 2 | Spring Boot Maven Plugin Packaging（中文） | 官方文档（镜像） | https://docs.springframework.org.cn/spring-boot/maven-plugin/packaging.html |
| 3 | Spring Boot 源码 RepackageMojo（outputDirectory/finalName 定义） | 官方源码 | https://github.com/spring-projects/spring-boot/blob/main/build-plugin/spring-boot-maven-plugin/src/main/java/org/springframework/boot/maven/RepackageMojo.java |
| 4 | Flutter 官方：Building Windows apps | 官方文档 | https://docs.flutter.dev/platform-integration/windows/building |
| 5 | Flutter 官方：Build and release a Windows desktop app | 官方文档 | https://docs.flutter.dev/deployment/windows |
| 6 | Git 官方：gitignore 文档 | 官方文档 | https://git-scm.com/docs/gitignore |
| 7 | 阿里云开发者社区：Maven 打包后 jar 输出到指定目录（4 种方式） | 技术社区 | https://developer.aliyun.com/article/1319357 |
| 8 | Stack Overflow：Unignore specific files in subdirectory | 技术社区 | https://stackoverflow.com/questions/32504123/unignore-specific-files-in-subdirectory-with-gitignore |
| 9 | 掘金译文：打包发布 Flutter 桌面应用（Windows exe/Inno Setup） | 技术社区 | https://juejin.cn/post/7412075509481963530 |

## 7. 给编码阶段的落地建议（总结）

1. **本任务（TASK-001）实现**：用 `New-Item -Path "<项目根>\deploy\scripts" -ItemType Directory -Force | Out-Null` 一次性创建两级目录；先 `Test-Path` 判断是否已存在；不需要任何三方包。
2. **TASK-002 后端 jar**：优先采用 spring-boot-maven-plugin 的 `repackage.outputDirectory`（方式一）或 maven-resources-plugin 复制（方式三）；多模块父目录引用用 `${project.parent.basedir}`。
3. **TASK-003 客户端产物**：`flutter build windows --release` 后复制 `build\windows\x64\runner\Release\` 内容到 `deploy\`（或生成安装包后放 deploy）。
4. **TASK-005 脚本迁移**：`$PSScriptRoot`/`$SCRIPT_DIR` 上溯层级由 1 级改 2 级；env.json、jar 路径统一改为 deploy 下。
5. **.gitignore**：`env.json` 无需改（仍被忽略）；jar/exe 是否放行由后续任务决定，放行写法 `!deploy/**/*.jar`。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
