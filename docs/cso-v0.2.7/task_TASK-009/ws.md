# 网络资料查询结果（TASK-009 治理 .gitignore 排除生成/测试/调试临时与中间文件）

## 1. 查询范围与结论摘要

- 任务性质：纯 .gitignore 规则治理（无第三方中间件/SDK 依赖），需查询**官方语法规范**与**各类临时/中间产物的权威来源说明**，为编码阶段（BEE）落地新增规则提供依据。
- 已获取官方资料 7 项：gitignore 语法（git-scm.com）、jmap/hprof 堆转储（Oracle JDK 21）、JVM 崩溃日志（GitHub 官方 gitignore 模板）、Surefire 测试报告（Apache Maven）、Shade 插件 dependency-reduced-pom.xml（Apache Maven）、Flatten 插件 .flattened-pom.xml（MojoHaus）、HAR 格式（W3C）。
- 关键结论：**`dependency-reduced-pom.xml` 默认生成在模块根目录 `${basedir}`（不在 target/ 内），必须加忽略规则**；`hs_err_pid*` 与 `replay_pid*` 为 GitHub 官方 Java.gitignore 模板推荐的 JVM 崩溃日志模式；gitignore 语法确认了「已跟踪文件不受新规则影响」「! 无法重新包含已被排除目录内的文件」等关键行为。
- 本任务为纯查询任务，**不修改 .gitignore**；以下第 4 节为编码阶段落地新增规则的直接依据。

## 2. 本地环境版本（兼容性核对基准）

| 组件 | 本地版本（实测） | 用途 |
| --- | --- | --- |
| git | 2.53.0.windows.1 | .gitignore 语法解析引擎 |
| JDK | OpenJDK 21.0.9 LTS（Eclipse Temurin） | 产生 *.hprof / hs_err_pid*.log 的 JVM 本体 |
| Maven | Apache Maven 3.9.16 | 产生 surefire-reports / maven-status / dependency-reduced-pom.xml |
| 项目后端 | Spring Boot 3.2.5 / Spring Cloud 2023.0.1（Java 21） | JVM 调试产物来源 |
| 客户端 | Flutter（Dart 3，SDK ^3.12.2） | 前端构建产物（已有规则覆盖） |

## 3. 官方资料查询结果（按主题）

### 3.1 gitignore 官方语法规范（权威依据，含版本兼容性结论）

- **来源**：Git 官方手册《gitignore - Specifies intentionally untracked files to ignore》，https://git-scm.com/docs/gitignore
- **版本**：文档最新 2.55.0（2026-06-29 更新）；2.53.0「no changes」，即本地 git 2.53.0 与文档完全一致 → **兼容性：完全兼容，可直接引用**。
- **与本任务直接相关的语法要点**（编码落地时必须遵守）：

| 语法 | 官方定义 | 对本任务的意义 |
| --- | --- | --- |
| 注释行 | 以 `#` 开头为注释 | 现有分区风格 `# ===================== 分区名 =====================` 合法 |
| 否定模式 | `!` 前缀重新包含被排除文件 | 现有 `!*.gitkeep` 白名单合法；但**「无法重新包含已被排除的父目录内的文件」**——`deploy/.../web/*` 用 `*` 而非目录本身，正是为了配合 `!*.gitkeep` 生效，新增规则不得破坏该结构 |
| 目录匹配 | 末尾带 `/` 的模式只匹配目录 | `dump/`、`maven-status/`、`surefire-reports/` 均只匹配目录，不会误伤同名文件 |
| 锚定规则 | 开头/中间含 `/` 时相对 .gitignore 所在层级；否则匹配任意层级 | `target/`（224 行）匹配任意层级；`/target/`（Rust 分区）仅根目录；`*.hprof` 等无斜杠模式匹配任意层级——本任务新增规则均按此语义设计 |
| 通配符 | `*` 不跨 `/`；`?` 单字符；`[]` 字符集；`**` 跨目录 | `hs_err_pid*.log` 正确匹配 `hs_err_pid12345.log`；`*.flattened-pom.xml` 正确匹配 `cloudoffice-common/.flattened-pom.xml` |
| 已跟踪文件 | 「Files already tracked by Git are not affected」 | 新规则只影响未跟踪文件；已跟踪的 `opencode.json` 等不受影响，需 `git rm --cached` 才停止跟踪（本任务不执行） |
| 优先级 | 同一路径下，**最后匹配的模式决定结果**（同级内） | 新增规则追加在现有分区之后或插入对应分区，不得与其他分区产生互相覆盖的歧义 |

### 3.2 JVM 调试产物（*.hprof、hs_err_pid*.log）

**A. 堆转储 *.hprof**
- **来源**：Oracle 官方《The jmap Command》，https://docs.oracle.com/en/java/javase/21/docs/specs/man/jmap.html （JDK 21 工具指南，与本地 JDK 21.0.9 版本匹配 → **兼容**）
- **官方要点**：`jmap -dump:live,format=b,file=<filename>` 以 **hprof 二进制格式**（`format=b`）导出 Java 堆转储；文件由用户指定文件名（常为 `*.hprof` 或 `heap.bin` 等）。另有 `-XX:+HeapDumpOnOutOfMemoryError` 会在 OOM 时自动生成 `java_pid<pid>.hprof`。
- **官方备注**：jmap 为「experimental and unsupported」工具（未来版本可能移除），但 hprof 二进制格式为堆转储事实标准。
- **规则依据**：`*.hprof` 全局模式匹配任意层级（jmap 导出文件可出现在任意目录）；`heapdump.*` 兜底（`-XX:HeapDumpPath` 指定文件名时常见命名）。→ 支持 cs.md 建议的 `*.hprof`、`heapdump.*`、`*.dmp`。

**B. JVM 崩溃日志 hs_err_pid*.log**
- **来源**：GitHub 官方仓库 github/gitignore 的 Java.gitignore 模板（Apache/MIT 混合许可），https://raw.githubusercontent.com/github/gitignore/main/Java.gitignore
- **官方要点**：模板中明确包含：
  ```gitignore
  # virtual machine crash logs, see http://www.java.com/en/download/help/error_hotspot.xml
  hs_err_pid*
  replay_pid*
  ```
  `hs_err_pid<pid>.log` 为 HotSpot 致命错误（fatal error）时生成的崩溃日志（文件名实际带 `.log` 后缀，GitHub 模板用 `hs_err_pid*` 更宽松）；`replay_pid*` 为 `-XX:+ReplayCompiles` 相关崩溃重放文件。
- **规则依据**：cs.md 建议的 `hs_err_pid*.log` 可精确匹配实际文件名；如需与 GitHub 官方模板完全对齐可追加 `replay_pid*`（本项目无 `-XX:+ReplayCompiles` 配置，`replay_pid*` 属低成本预防性规则，可加可不加，建议加）。

### 3.3 Maven 测试/构建中间产物（surefire-reports、maven-status、dependency-reduced-pom.xml、.flattened-pom.xml、*.lastUpdated）

**A. surefire-reports（测试报告）**
- **来源**：Apache Maven Surefire 官方文档《Maven Surefire Plugin - Introduction》（最新 3.6.0-M1，2026-06-02），https://maven.apache.org/surefire/maven-surefire-plugin/
- **官方要点**：Surefire 在 `test` 阶段执行单元测试，生成两种格式报告——纯文本（`*.txt`）与 XML（`*.xml`），**默认输出到 `${basedir}/target/surefire-reports/TEST-*.xml`**。
- **兼容性**：Surefire 3.x 要求 Maven 3.6.3+；本地 Maven 3.9.16 满足 → **兼容**。本项目 5 个 Maven 模块的 `target/` 已被 224 行 `target/` 规则覆盖（surefire-reports 位于 target 内，实测 maven-status 亦被覆盖）；独立 `surefire-reports/` 规则为**兜底预防**（防止个别工具/插件将报告输出到 target 之外）。

**B. maven-status（编译状态中间产物）**
- **来源**：Maven Compiler 插件（maven-compiler-plugin，本项目 cloudoffice-common/pom.xml 第 77 行显式声明）在 `target/maven-status/maven-compiler-plugin/{compile,testCompile}/` 下写入 `createdFiles.lst`、`inputFiles.lst` 等增量编译状态文件。
- **结论**：属标准 Maven 构建中间产物，cs.md 实测其已被 `target/` 覆盖；`maven-status/` 独立规则为兜底（同 3.3.A）。

**C. dependency-reduced-pom.xml（Shade 插件，关键发现）**
- **来源**：Apache Maven Shade 官方文档《shade:shade Mojo》（最新 3.6.2，2026-03-02），https://maven.apache.org/plugins/maven-shade-plugin/shade-mojo.html
- **官方要点**（`<createDependencyReducedPom>` 与 `<dependencyReducedPomLocation>` 参数）：
  - 默认值 `createDependencyReducedPom=true`：为 shaded artifact 生成简化 POM；
  - **默认位置 `${basedir}/dependency-reduced-pom.xml`——即模块根目录，不在 target/ 内！**（除非显式配置 dependencyReducedPomLocation）
  - 若 `generateUniqueDependencyReducedPom=true` 还会在 `${basedir}` 生成 `drp-*.pom`。
- **关键意义**：本项目当前 pom.xml 未显式使用 shade 插件，但规则必须预防（Spring Boot 多模块项目未来打 uber-jar 时必然触发），**`dependency-reduced-pom.xml` 是必须新增的规则**（若不加，shade 打包一次就会把根目录的该文件暴露到 git 待提交清单）。GitHub 真实项目佐证：apache/zeppelin、apache/doris、deeplearning4j、apache/doris-spark-connector 等均在 .gitignore 中使用 `dependency-reduced-pom.xml`（多数用 `**/dependency-reduced-pom.xml` 或 `*dependency-reduced-pom.xml` 匹配所有模块）。

**D. .flattened-pom.xml（Flatten 插件）**
- **来源**：MojoHaus《Flatten Maven Plugin》（最新 1.8.0，2026-07-24），https://www.mojohaus.org/flatten-maven-plugin/
- **官方要点**：`flatten:flatten` 生成扁平化 POM 用于 install/deploy（默认输出 `${project.build.directory}/.flattened-pom.xml`，即 target 内）；`flatten:clean` 清理。
- **兼容性**：Flatten 1.8.0 支持 Maven 3.9.x 与 Java 21 → **兼容**。
- **规则依据**：默认输出在 target/（已被覆盖），但 `*.flattened-pom.xml` 为兜底预防（配置变更或插件版本差异时可能落在 target 外）。GitHub 佐证：apache/doris-spark-connector、MinecraftDev 模板等均含 `.flattened-pom.xml`。

**E. *.lastUpdated（Maven 解析失败标记）**
- **结论**：`*.lastUpdated` 为 Maven 依赖下载失败时的标记文件，默认位于本地仓库（`~/.m2/repository/...`，在项目外）；仅当项目配置 `-Dmaven.repo.local` 指向项目内目录时才会出现在仓库树中。属低成本预防性规则，与 GitHub 常见 Java .gitignore 模式一致，可加。

### 3.4 工具残留文件（*.har、*.saz、*.chls、*.history、*.session）

**A. *.har（HTTP Archive）**
- **来源**：W3C《HTTP Archive (HAR) format》规范，https://w3c.github.io/web-performance/specs/HAR/Overview.html
- **官方要点**：HAR 为 HTTP 事务归档格式（基于 JSON，UTF-8 编码），用于浏览器/抓包工具导出页面加载与请求/响应性能数据；含 `log.entries`（每个 HTTP 请求的完整记录）。
- **文档状态**：规范标注「DO NOT USE / abandoned」（2012 年历史草案，从未正式发布），但被 Chrome DevTools、Postman、Charles、Fiddler 等工具广泛采用，为事实标准。
- **规则依据**：`*.har` 是调试/抓包导出文件，属典型工具残留；本项目为 Java/Dart 工程，无 `.har` 源码扩展名冲突（cs.md 已核实）→ 可安全全局忽略。

**B. *.saz（Fiddler 会话归档）、*.chls（Charles 会话）**
- **来源**：第三方专有格式（无公开规范文档页面）：
  - `*.saz` = Telerik Fiddler 的「Session Archive Zip」（实为 ZIP 容器，内含 Raw 请求/响应与元数据），Fiddler 官方站点 telerik.com/fiddler 说明其会话保存/导出格式；
  - `*.chls` = Charles Proxy 的会话文件（专有二进制），Charles 官方站点 charlesproxy.com 说明其「Save Session」格式。
- **规则依据**：均为抓包/API 调试工具会话文件，属工具残留；本项目无同名源码扩展名 → 可全局忽略。

**C. *.history、*.session、*.trace（编辑器/终端会话）**
- **来源**：GitHub gitignore 官方仓库与社区通用模板（.NET/Node 等模板）中常见模式（如 `*.history`、`*.session` 见于各语言模板的「Session」分区）。本项目无同名源码扩展名（cs.md 已核实）→ 可加；`*.trace` 若未来引入同名源码扩展名需改路径前缀（cs.md 6.1-D 风险提示，维持）。

## 4. 版本兼容性结论汇总

| 资料 | 资料版本 | 本地版本 | 兼容性结论 |
| --- | --- | --- | --- |
| gitignore 手册 | 2.55.0（2026-06-29） | git 2.53.0 | ✅ 完全兼容（2.53.0 无变化），语法可直接引用 |
| jmap 工具手册 | JDK 21（2025） | JDK 21.0.9 LTS | ✅ 版本匹配；注意 jmap 官方标注 experimental/unsupported |
| GitHub Java.gitignore 模板 | main 分支（持续更新） | 不受版本约束 | ✅ 模板语言，无兼容性问题 |
| Maven Surefire 文档 | 3.6.0-M1（2026-06-02） | Maven 3.9.16 | ✅ Surefire 3.x 要求 Maven 3.6.3+，满足 |
| Maven Shade 文档 | 3.6.2（2026-03-02） | Maven 3.9.16 / Java 21 | ✅ 兼容（本项目未启用 shade，规则为预防性） |
| Flatten 插件文档 | 1.8.0（2026-07-24） | Maven 3.9.16 / Java 21 | ✅ 兼容（本项目未启用 flatten，规则为预防性） |
| HAR 规范 | 2012-08-14 历史草案（abandoned） | 事实标准被广泛采用 | ✅ 无版本绑定，仅作格式定性 |
| .saz / .chls | 专有格式（无公开规范） | — | ✅ 无兼容性问题，仅作类型定性 |

**总体结论**：本任务查询的所有资料版本与当前项目环境（git 2.53.0、JDK 21.0.9、Maven 3.9.16）兼容，无版本差异导致的规则失效风险；gitignore 语法行为（2.53.0 与最新 2.55.0 一致）为本任务全部新增规则的可靠性基础。

## 5. 对编码阶段（BEE）的直接建议（与 cs.md 6.1 对照）

cs.md 6.1 的缺口四类建议与官方资料核对后**全部成立**，另按官方资料补充 2 条：

| 类别 | 建议规则（cs.md 6.1） | 官方依据（本 ws.md） | 补充建议 |
| --- | --- | --- | --- |
| A. JVM/调试产物 | `*.hprof`、`hs_err_pid*.log`、`heapdump.*`、`*.dmp`、`dump/`、`*.dump`、`derby.log` | jmap 官方（hprof 二进制堆转储）；GitHub 官方模板（hs_err_pid*） | **追加 `replay_pid*`**（GitHub 官方模板与 hs_err_pid 同组推荐） |
| B. 构建中间产物 | `*.flattened-pom.xml`、`*.lastUpdated`、`dependency-reduced-pom.xml`、`maven-status/` | Shade 官方（dependency-reduced-pom.xml 默认在 ${basedir}，**必须加**）；Flatten 官方；Surefire/Compiler 官方 | 无（均为官方确认的生成物） |
| C. 测试产物 | `surefire-reports/`、`test-output/`、`test-results/`、`scripts/API-TEST/*.tmp`、`scripts/API-TEST/*.token.json` | Surefire 官方（默认 target/surefire-reports，兜底合理） | 保持精确模式，禁止通配 `*.py`/`*.ps1`（cs.md 红线） |
| D. 工具残留 | `*.saz`、`*.chls`、`*.har`、`*.history`、`*.session`、`*.trace` | W3C HAR 规范（JSON 归档）；Fiddler/Charles 专有格式 | 无（`*.trace` 保留 cs.md 风险提示） |

**落地红线（官方语法层面的强制约束，编码阶段必须遵守）**：
1. `!` 无法重新包含「已被排除的父目录」内的文件 → `deploy/cloudoffice-flutter-app/web/*` + `!*.gitkeep` 结构不得破坏（该结构正确，勿改为排除目录本身）。
2. 已跟踪文件不受新规则影响 → 新规则只预防未来文件；`opencode.json` 等已跟踪文件如需停止跟踪须 `git rm --cached`（本任务不执行，另行确认）。
3. 末尾 `/` 只匹配目录 → `dump/`、`maven-status/`、`surefire-reports/`、`test-output/`、`test-results/` 不会误伤同名文件。
4. 无 `/` 的模式匹配任意层级（`*.hprof` 等）→ 本项目无同名源码扩展名（cs.md 已核实），可全局使用；`*.trace` 保留路径前缀化预案。
5. 验证命令：`git check-ignore -v`（返回命中的规则行号）、`git status --porcelain --ignored`、`git ls-files`（复核应入库文件仍被跟踪）——与 cs.md 第 7 节一致。

## 6. 参考资料清单

| # | 资料 | 来源 | 版本/日期 |
| --- | --- | --- | --- |
| 1 | gitignore 手册（PATTERN FORMAT 全节） | https://git-scm.com/docs/gitignore | 2.55.0（2.53.0 无变化） |
| 2 | The jmap Command（JDK 21 Tool Guide） | https://docs.oracle.com/en/java/javase/21/docs/specs/man/jmap.html | JDK 21（2025） |
| 3 | github/gitignore Java.gitignore 模板 | https://raw.githubusercontent.com/github/gitignore/main/Java.gitignore | main 分支 |
| 4 | Maven Surefire Plugin Introduction | https://maven.apache.org/surefire/maven-surefire-plugin/ | 3.6.0-M1（2026-06-02） |
| 5 | Maven Shade Plugin shade:shade Mojo | https://maven.apache.org/plugins/maven-shade-plugin/shade-mojo.html | 3.6.2（2026-03-02） |
| 6 | Flatten Maven Plugin（MojoHaus） | https://www.mojohaus.org/flatten-maven-plugin/ | 1.8.0（2026-07-24） |
| 7 | W3C HTTP Archive (HAR) format | https://w3c.github.io/web-performance/specs/HAR/Overview.html | 2012-08-14 历史草案（abandoned） |
| 8 | 真实项目 .gitignore 样例（dependency-reduced-pom.xml / .flattened-pom.xml） | apache/zeppelin、apache/doris、apache/doris-spark-connector、deeplearning4j、ModelEngine-Group/fit-framework（GitHub 公开仓库，经 GitHub Code Search 检索） | 检索于 2026-08-10 |
| 9 | Fiddler（*.saz 会话归档）、Charles Proxy（*.chls 会话文件） | telerik.com/fiddler、charlesproxy.com（专有格式，无公开规范） | — |
| 10 | 本地环境版本实测（git 2.53.0 / JDK 21.0.9 / Maven 3.9.16） | 本地命令 `git --version`、`java -version`、`mvn -version` | 2026-08-10 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
