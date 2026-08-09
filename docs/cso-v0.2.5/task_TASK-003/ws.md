# 网络资料查询结果（#TASK-003 迁移 scripts 下全部 .sh/.ps1 至 deploy/scripts 并适配路径）

## 1. 任务与查询范围

本任务（TASK-003）将项目根目录 `scripts/` 下 21 个 .sh/.ps1 脚本（10 sh + 11 ps1）迁移至 `deploy/scripts/`，并同步适配脚本内路径引用。作为 WS，本文件汇总以下查询结果：

| 查询主题 | 用途 |
| --- | --- |
| `git mv` 官方文档与最佳实践 | 迁移脚本并保留 git 历史（AC-6） |
| Bash 脚本自身目录/父目录获取标准写法 | 迁移后 `SCRIPT_DIR`/`PROJECT_DIR` 基准路径适配 |
| PowerShell `$PSScriptRoot`/`Split-Path`/`Join-Path`/`Test-Path` | ps1 脚本路径适配 |
| Maven 产物输出到指定目录的方案 | 用户需求 2「jar 包生成到 deploy」供后续构建配置任务参考 |
| Flutter Windows/Web 构建产物路径 | 用户需求 2「安装文件/exe 生成到 deploy」供后续任务参考 |

## 2. Git：git mv（官方文档 + 社区最佳实践）

### 2.1 官方文档（git-scm.com/docs/git-mv，中文版可用）

- 用途：移动或重命名一个文件、一个目录或一个符号链接；移动成功后索引自动更新（等价于 `mv` + `git add` + `git rm` 的组合），**保留文件历史**（`git log --follow <新路径>` 可跨重命名边界追踪完整历史）。
- 语法：
  ```bash
  git mv [-v] [-f] [-n] [-k] <源文件> <目标文件>
  git mv [-v] [-f] [-n] [-k] <源文件> ... <目标目录>
  ```
- 选项：
  - `-f`/`--force`：目标已存在时强制移动；
  - `-k`：跳过会导致错误的移动（源不存在/不受 git 控制/无 -f 覆盖）；
  - `-n`/`--dry-run`：预演，仅显示将发生的操作（迁移前核对清单可用）；
  - `-v`/`--verbose`：报告移动时的名称变化。
- 关键点：Git 不显式跟踪"重命名"本身，重命名是在提交时按内容相似度自动识别（status 显示 `renamed: old -> new`）；**用普通 `mv` + `git add -A` 也能被识别**，但官方推荐 `git mv` 一步完成移动+暂存，更稳妥。
- 批量移动示例：`git mv file1.txt file2.txt deploy/scripts/`（最后一个参数必须是已存在的目录；`deploy/scripts` 已预建含 .gitkeep，符合）。

### 2.2 版本兼容性核对

- 本地环境：`git version 2.53.0.windows.1`（Git for Windows）。
- `git mv` 为 Git 1.x 起的稳定命令，与本地版本完全兼容；`-n` 预演选项建议先跑一遍核对 21 个脚本清单。
- 结论：**兼容**，迁移直接用 `git mv scripts/xxx deploy/scripts/xxx`（ps1 逐文件执行即可）。

## 3. Bash：脚本自身目录与父目录获取（核心适配技术）

### 3.1 业界标准写法（多次权威社区确认）

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

逐段语义：
- `${BASH_SOURCE[0]}`：当前脚本自身路径（相对/绝对取决于调用方式）。**与 `$0` 不同，脚本被 `source` 加载时 `$0` 指向主调脚本，`${BASH_SOURCE[0]}` 始终指向被加载脚本自身**——本项目 `load-env.sh` 被各 deploy 脚本 source，必须用 `BASH_SOURCE[0]`。
- `dirname`：提取路径的目录部分（路径不含 `/` 时输出 `.`）。
- `cd ... && pwd`：切到该目录后输出绝对路径，**不受执行时当前工作目录影响**。
- 该写法处理"相对路径调用、目录含空格、source 嵌套"均可靠。

### 3.2 父目录（项目根）推导——本项目核心适配模式

```bash
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
```

- 本项目全部脚本现有机制：`PROJECT_DIR` 由脚本所在目录（`SCRIPT_DIR`）推导。
- 迁移后 `SCRIPT_DIR = <项目根>/deploy/scripts`，`PROJECT_DIR = <项目根>/deploy`，因此以 `$PROJECT_DIR/env.json` 为基准的引用**自动指向 deploy/env.json，无需改动**（已验证：f/prompts.chat、elizaOS/eliza 等真实仓库均采用 `SCRIPT_DIR` + `PROJECT_DIR="$(dirname "$SCRIPT_DIR")"` 同款模式）。
- 需要引用项目根（如 `scripts/sql`）时的写法（与现有模式同构，供 deploy-db-init.sh 适配参考）：
  ```bash
  ROOT_DIR="$(dirname "$PROJECT_DIR")"          # deploy 的父目录 = 项目根
  SQL_DIR="$ROOT_DIR/scripts/sql"
  ```

### 3.3 符号链接与 readlink（备选，Git Bash 可用）

- 若脚本可能经符号链接调用，先用 `readlink -f`（GNU coreutils，Git for Windows 自带）解析：
  ```bash
  SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
  SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
  ```
- 本项目脚本无符号链接调用场景，`readlink` 非必需，3.1/3.2 的标准写法即可。

### 3.4 版本兼容性核对

- 本地为 Git Bash（随 Git for Windows 2.53.0 分发，bash 4.x），`cd`/`dirname`/`pwd`/`readlink` 均为内置或 GNU coreutils，与上述写法兼容。
- 结论：**兼容**；适配 deploy-db-init.sh（SQL 目录）、deploy-check-env.sh（pom.xml/scripts/sql 根目录判断）时直接采用 3.2 的 `ROOT_DIR` 推导。

## 4. PowerShell：$PSScriptRoot 与路径处理（Microsoft 官方文档）

### 4.1 核心自动变量与 cmdlet

| 名称 | 说明 | 官方文档 |
| --- | --- | --- |
| `$PSScriptRoot` | 自动变量，脚本所在目录（PowerShell 3.0+ 引入），与执行时工作目录无关 | learn.microsoft.com（about_Automatic_Variables） |
| `Split-Path -Path <p> -Parent` | 返回路径的父目录部分（去掉最后一段）；`-Leaf` 返回最后一段；`-IsAbsolute` 判断绝对/相对 | learn.microsoft.com Split-Path |
| `Join-Path <父> <子>` | 按当前 provider 的分隔符拼接路径 | learn.microsoft.com Join-Path |
| `Test-Path <p>` | 路径存在返回 True 否则 False | learn.microsoft.com Test-Path |

- 旧版兼容写法（PS 2.0，本项目不需要）：`Split-Path $MyInvocation.MyCommand.Path`。

### 4.2 本项目 ps1 适配模式（迁移后基准自动变化）

- 现状（cs.md 确认）：`$ProjectDir = Split-Path -Parent $PSScriptRoot`，迁移后 `$PSScriptRoot = <根>/deploy/scripts` → `$ProjectDir = <根>/deploy`，`Join-Path $ProjectDir "env.json"` 自动指向 deploy/env.json，**自动适配**。
- 需要指向项目根（scripts/sql）时（deploy-db-init.ps1 / deploy-check-env.ps1 适配参考）：
  ```powershell
  $RootDir = Split-Path -Parent $ProjectDir        # deploy 的父目录 = 项目根
  $SqlPath = Join-Path $RootDir "scripts\sql\auth-init-v0.1.5.sql"
  ```

### 4.3 版本兼容性核对

- 本地环境：`PSVersion 5.1.19041.7548`（Windows PowerShell 5.1，系统自带）。
- `$PSScriptRoot` 需 3.0+，`Split-Path`/`Join-Path`/`Test-Path` 位于 Microsoft.PowerShell.Management 模块（5.1 原生，未 deprecated）。
- 结论：**兼容**；脚本无需兼容 PS 2.0，`$PSScriptRoot` 直接使用。

## 5. Maven 产物输出到指定目录（用户需求 2 参考，供后续构建配置任务使用）

> 说明：cs.md 结论——当前父 POM 与各模块 pom.xml 均无产物输出配置，`mvn clean package` 产物在各自 `target/`；「最终产物集中到 deploy」由后续任务实现。以下为可选方案（按推荐度排序），均满足 SAD「只复制最终产物、中间产物不入 deploy」约束。

### 5.1 方案 A：maven-antrun-plugin（推荐，复制控制最灵活）

在 package 阶段用 Ant `copy` 任务，只复制 `target` 下的最终 jar（`*.jar`），不复制中间文件：

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-antrun-plugin</artifactId>
  <version>3.1.0</version>
  <executions>
    <execution>
      <id>copy-final-jar</id>
      <phase>package</phase>
      <goals><goal>run</goal></goals>
      <configuration>
        <target>
          <mkdir dir="${project.basedir}/../deploy"/>
          <copy todir="${project.basedir}/../deploy" overwrite="true" failonerror="false">
            <fileset dir="${project.build.directory}" erroronmissingdir="false">
              <include name="*.jar"/>
            </fileset>
          </copy>
        </target>
      </configuration>
    </execution>
  </executions>
</plugin>
```

关键 Ant 属性：`${basedir}`=模块根、`${project.build.directory}`=target 目录、`${project.build.finalName}`=jar 前缀名。`erroronmissingdir=false` 保证 target 缺失时跳过不报错（clean 后不 package 的场景）。

### 5.2 方案 B：maven-resources-plugin copy-resources（Maven 原生）

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-resources-plugin</artifactId>
  <version>3.3.1</version>
  <executions>
    <execution>
      <id>copy-final-jar</id>
      <phase>package</phase>
      <goals><goal>copy-resources</goal></goals>
      <configuration>
        <outputDirectory>${project.basedir}/../deploy</outputDirectory>
        <resources>
          <resource>
            <directory>${project.build.directory}</directory>
            <includes><include>*.jar</include></includes>
          </resource>
        </resources>
      </configuration>
    </execution>
  </executions>
</plugin>
```

### 5.3 其他备选（不推荐用于本场景）

- maven-jar-plugin `outputDirectory`：直接改 jar 输出目录，会移出 target（与 spring-boot-maven-plugin repackage 阶段联动需谨慎），且对 non-jar 产物无效；
- distributionManagement `file:` 仓库：语义是"发布到仓库"，需走 `mvn deploy`，不贴合"构建即落 deploy"；
- maven-dependency-plugin copy-dependencies：用于复制依赖 jar，不复制本项目最终 jar。

### 5.4 版本兼容性核对

- maven-antrun-plugin 3.1.0 / maven-resources-plugin 3.3.1 均要求 Maven 3.6.3+，本项目使用 Spring Boot 3.2.5 父 POM（Maven 3.6.3+ 环境），**兼容**。
- 注：本项目 spring-boot-maven-plugin 在 `pluginManagement` 中管理，新增插件建议同样放入父 POM `pluginManagement` + 各模块声明（与现有结构一致）。

## 6. Flutter 构建产物路径（用户需求 2 参考，供客户端产物任务使用）

### 6.1 Windows 桌面（官方 docs.flutter.dev/platform-integration/windows/building）

- 命令：`flutter build windows --release`。
- 产物目录：`build\windows\runner\Release\`；**新版 Flutter（x64 架构目标）为 `build\windows\x64\runner\Release\`**（Microsoft Learn 2026-07 文档与 Flutter 社区 2026 年资料均确认 x64 子目录为当前预期路径）。
- 可分发内容包括：`*.exe` + 同目录全部 `*.dll`（如 flutter_windows.dll）+ `data` 目录 + Visual C++ 运行库（msvcp140.dll、vcruntime140.dll、vcruntime140_1.dll，可 application-local 方式置于 exe 旁）。
- 打包为安装程序常见方案：Inno Setup / WiX / Advanced Installer（将 Release 目录内容作为源，输出单文件 setup.exe 到 deploy）。
- 版本兼容性：本项目 pubspec 声明 SDK `^3.12.2`（Dart 3，较新 Flutter），**以 `build\windows\x64\runner\Release\` 为实际预期路径**；cs.md 记录的 `build/windows/runner/Release/` 为旧版路径，编码/文档阶段以实际构建输出为准（可 `Get-ChildItem build/windows -Recurse -Filter *.exe` 核对）。

### 6.2 Web（官方 docs.flutter.dev/platform-integration/web）

- 命令：`flutter build web --release`。
- 产物目录：`build\web\`（静态站点，可整体复制到 deploy 作为 Web 交付物）。

### 6.3 与 SAD 约束的对应

- 中间产物（`build/` 目录、`target/` 目录、编译临时文件、测试产物）一律不进入 deploy；只复制最终产物（jar / exe+依赖+data / web 静态文件）——与 ADR-013、部署资产约束一致。

## 7. 迁移实施注意事项（综合网络资料 + cs.md 的适配要点）

1. **迁移命令**：21 个脚本均被 git 跟踪，`git mv scripts/<name> deploy/scripts/<name>` 逐文件执行（ps1 同理）；先 `git mv -n`（dry-run）核对清单再正式执行；`deploy/scripts` 已存在（含 .gitkeep）。
2. **自动适配机制**：迁移后 `PROJECT_DIR`（sh：`dirname "$SCRIPT_DIR"`；ps1：`Split-Path -Parent $PSScriptRoot`）自动变为 deploy → `env.json` 加载路径自动正确，**不要**多此一举改成指向根目录。
3. **必须适配点**（cs.md 3.2 节共 19 处）：
   - SQL 目录：`deploy-db-init.sh` 用 `ROOT_DIR="$(dirname "$PROJECT_DIR")"` + `$ROOT_DIR/scripts/sql`；ps1 用 `Split-Path -Parent $ProjectDir` 同构；
   - jar 路径（4 个 start 脚本 sh/ps1 共 8 处）：指向 deploy 下最终产物（具体文件名/子目录待构建配置任务定稿，可先用 `deploy/*.jar` 或约定子目录占位）；
   - `deploy-check-env.sh/ps1` 的 `pom.xml`、`scripts/sql` 判断：改为基于根目录的绝对路径（`ROOT_DIR` 推导）或文档化执行目录要求；
   - 注释引用（env-template/env/start-gateway 5 处）：`scripts/deploy-rsa-keygen.sh` → `deploy/scripts/deploy-rsa-keygen.sh`；
   - `deploy-rsa-keygen.sh/ps1` 输出目录与提示文案：默认 `keys/` 与「项目根目录 env.json」文案需随 deploy 语境更新。
4. **冒烟验证**（对应 AC-7）：`source deploy/scripts/load-env.sh`（Bash）与 `. .\deploy\scripts\load-env.ps1`（PowerShell）应从 `deploy/env.json` 加载成功；`bash deploy/scripts/deploy-check-env.sh` 能完整运行到汇总（中间件检查项可失败，脚本本身不能报路径错误）。注意 load-env 用 `${BASH_SOURCE[0]}` 而非 `$0`（被 source 时 `$0` 指主调脚本）。
5. **敏感信息**：`deploy-env.ps1` 内含真实 DB 密码与 RSA 密钥（历史遗留已入库），本任务照搬迁移（git mv），文档中不得输出密钥值；`deploy/env.json` 冒烟验证时不得打印内容。
6. **范围边界**：`scripts/sql/`、`scripts/docker/`、`scripts/API-TEST/`、`scripts/deployment-guide.md` 保持原位；不改 .gitignore（`env.json` 无路径前缀规则对 `deploy/env.json` 仍生效）；Maven/Flutter 构建产物配置属后续任务。

## 8. 结论

- 本任务技术点均为**成熟稳定的基础能力**（git mv、Bash 变量、PowerShell 内置 cmdlet），无第三方依赖引入；经版本核对，本地 Git 2.53.0 / PowerShell 5.1 / Git Bash 均与查询资料**完全兼容**。
- 迁移与适配的推荐写法（SCRIPT_DIR/PROJECT_DIR 推导、ROOT_DIR 取项目根）已由 GitHub 真实项目（elizaOS、prompts.chat 等）验证，可直接采用。
- Maven（maven-antrun-plugin / maven-resources-plugin）与 Flutter（build/windows/x64/runner/Release、build/web）产物输出方案已汇总，供本版本构建配置任务（用户需求 2）直接参考。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
