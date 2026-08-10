# 代码查询结果（TASK-009 治理 .gitignore 排除生成/测试/调试临时与中间文件）

## 1. 查询范围与结论摘要

- 查询对象：项目根目录 `.gitignore`（336 行）完整现状、项目根目录与全部子目录（5 个 Maven 模块、Flutter 工程、deploy、scripts、docs）的临时/中间文件实测分布、git 跟踪状态（`git ls-files` / `git status` / `git check-ignore`）。
- 结论：现有 .gitignore 已覆盖**当前工作区实际存在**的全部临时/中间文件（`git status` 干净、43 条被忽略路径中无应入库文件）；本任务需新增的均为**预防性规则**（context 第 0 节缺口清单四类），按现有分区风格补入，不得误伤应入库文件。
- 本任务为纯查询任务，**不修改 .gitignore**；以下第 6 节为编码阶段（BEE）落地新增规则的直接依据。

## 2. .gitignore 现状（根目录，336 行，10+ 分区）

### 分区结构（文件行号）
| 分区 | 行号 | 关键规则 |
| --- | --- | --- |
| 操作系统 | 1-11 | `.DS_Store`、`Thumbs.db`、`*.lnk`、`*~` |
| 通用 IDE / 编辑器 | 13-34 | `.idea/`、`*.iml`、`.vscode/`、`*.swp`、`*.swo` |
| 其他 IDE / 编辑器 | 36-95 | `.classpath`、`*.apk`、`.vs/`、`*.user`、`.Rhistory` 等 |
| AI 开发工具 | 97-170 | `.opencode/`、`*.opencode.tmp`、`.claude/`、`conversation-history.jsonl`、`codex_history/`、`*.aider.*` 等 |
| 前端 / Node.js | 172-205 | `node_modules/`、`dist/`、`build/`、`output/`、`*.tsbuildinfo` |
| Python | 207-220 | `__pycache__/`、`*.py[cod]`、`*$py.class`、`.pytest_cache/`、`.coverage`、`env.bak/` |
| Java / Maven / Gradle | 222-234 | `target/`、`*.class`、`*.jar`、`*.war` |
| C/C++ / CMake | 236-248 | `*.exe`、`*.dll`、`*.o` 等 |
| Rust | 250-255 | `/target/`（仅根目录，与 Maven `target/` 不冲突） |
| Go | 257-264 | `*.test`、`*.out`、`*.prof`、`coverage.out` |
| PHP | 266-271 | `/vendor/`、`.phpunit.result.cache` |
| Dart / Flutter | 273-277 | `.dart_tool/`、`.packages`、`.flutter-plugins`、`.flutter-plugins-dependencies` |
| 客户端构建产物 | 279-286 | `deploy/cloudoffice-flutter-app/web/*` + `!*.gitkeep`；`windows/*` + `!*.gitkeep` |
| 数据库 / 缓存 / 日志 / 临时 | 288-311 | `*.log`、`logs/`、`log/`、`*.err`、`*.pid`、`work/`、`*.db`、`tmp/`、`temp/`、`.cache/`、`*.patch`、`*.bak` |
| 环境密钥 | 313-326 | `.env.*` + `!.env.example`、`keys/`、精确 `env.json`、`docs2/` |
| 包管理器 | 328-330 | `.pnp` |
| 压缩包 | 332-333 | `*.tgz` |

### 与本任务直接相关的已有规则（实测生效）
- `*.log`（290 行，覆盖 derby.log）、`logs/`（291 行，任意层级，覆盖根 logs/ 与 deploy/logs/）、`work/`（296 行）、`*.err`、`*.pid`
- `target/`（224 行，覆盖 5 个 Maven 模块 target 全部内容，含 maven-status/）
- `__pycache__/`（208 行）、`*.py[cod]`（209 行，覆盖 .pyc）
- `*.jar`（233 行）、`env.json`（324 行，精确匹配）、`keys/`（323 行）、`docs2/`（326 行）
- `deploy/cloudoffice-flutter-app/web/*`、`windows/*`（283/285 行）+ `!*.gitkeep`（284/286 行）

## 3. 实测临时/中间文件分布（本地工作区，全部已被现有规则忽略）

### 根目录
| 路径 | 类型 | 现有覆盖规则（git check-ignore 实测） |
| --- | --- | --- |
| `derby.log` | Derby 数据库调试日志（JVM 调试产物） | `.gitignore:290 *.log` |
| `logs/`（28 个 .err.log/.out.log，如 access_log.2026-08-09.log、auth-service-restart*.err.log） | 服务启停日志 | `.gitignore:291 logs/` |
| `work/Tomcat`、`work/Tomcat-1` | Tomcat 工作目录（调试残留） | `.gitignore:296 work/` |
| `.idea/`、`.opencode/`、`docs2/`、`keys/` | IDE/工具/敏感目录 | 各自分区规则 |
| `opencode.json` | **已跟踪**（git ls-files 存在；.gitignore:101 有规则但已跟踪文件不受影响，历史跟踪状态，本任务不执行 git rm --cached，仅记录） | — |

### 后端 Maven 模块（cloudoffice-common / gateway / auth-service / biz-service / system-service）
| 路径 | 类型 | 现有覆盖规则 |
| --- | --- | --- |
| `cloudoffice-{module}/target/classes/**/*.class` | 编译产物 | `.gitignore:224 target/` |
| `cloudoffice-{module}/target/test-classes/**/*.class` | 测试编译产物 | 同上 |
| `cloudoffice-{module}/target/maven-status/maven-compiler-plugin/{compile,testCompile}/{createdFiles,inputFiles}.lst` | Maven 构建状态（中间产物） | 同上（被 target/ 覆盖） |

### deploy / scripts
| 路径 | 类型 | 现有覆盖规则 |
| --- | --- | --- |
| `deploy/logs/`（auth/gateway/biz/system 的 *.log、*.err、*.pid 共 12 个） | 服务启停日志与 PID | `logs/`、`*.err`、`*.pid` |
| `deploy/cloudoffice-{module}.jar`（4 个） | 构建产物 | `*.jar` |
| `deploy/env.json`、`deploy/keys/` | 环境配置/密钥（不入库） | `env.json`（精确）、`keys/` |
| `deploy/cloudoffice-flutter-app/web/*`（.last_build_id、assets/、canvaskit/、main.dart.js、version.json 等 12 项） | 客户端 Web 构建产物 | `deploy/.../web/*` + `!*.gitkeep` |
| `deploy/cloudoffice-flutter-app/windows/*`（.exe、.dll、data/ 等 4 项） | 客户端 Windows 构建产物 | `deploy/.../windows/*` + `!*.gitkeep` |
| `scripts/API-TEST/__pycache__/`（6 个 .pyc：cso-api-test-v0.0.1/0.2.5/0.2.6/0.2.7.cpython-3xx.pyc） | Python 字节码缓存 | `__pycache__/`、`*.py[cod]` |

### Flutter 工程（cloudoffice-flutter-app，子工程自带 .gitignore 生效）
| 路径 | 类型 | 现有覆盖规则 |
| --- | --- | --- |
| `cloudoffice-flutter-app/build/` | 构建产物 | 子工程 `.gitignore:33 /build/` |
| `cloudoffice-flutter-app/.dart_tool/` | 工具缓存 | 根 `.dart_tool/` + 子工程 `.gitignore:29` |
| `cloudoffice-flutter-app/.flutter-plugins-dependencies` | Flutter 插件清单生成物 | 根 277 行 |
| `cloudoffice-flutter-app/windows/flutter/ephemeral/` | Flutter Windows 临时产物 | 子工程 .gitignore |
| `cloudoffice-flutter-app/CloudStrollOffice - 快捷方式.lnk` | 本地快捷方式 | `*.lnk` |
| `cloudoffice-flutter-app/cloudoffice_flutter_app.iml` | IDE 模块文件 | `*.iml` |

## 4. 应入库文件清单（git ls-files 逐项确认被跟踪，未被现有规则误伤）

| 类别 | 文件 | 状态 |
| --- | --- | --- |
| 环境模板 | `deploy/env.example.json` | ✓ 跟踪；`env.json` 精确规则（324 行）未误伤 |
| 占位文件 | `deploy/.gitkeep`、`deploy/scripts/.gitkeep`、`deploy/cloudoffice-flutter-app/.gitkeep`、`deploy/cloudoffice-flutter-app/web/.gitkeep`、`deploy/cloudoffice-flutter-app/windows/.gitkeep`、各 Maven 模块 src 下全部 `.gitkeep`（约 40 个）、Flutter lib/test 下 `.gitkeep` | ✓ 全部跟踪；白名单 `!*.gitkeep` 保留 |
| Maven POM | `pom.xml`（根）+ `cloudoffice-common|gateway|auth-service|biz-service|system-service/pom.xml`（5 个模块） | ✓ 全部跟踪；`*.xml` 无忽略规则 |
| 配置 | 各模块 `src/main/resources/bootstrap.yml`、`application.yml`、`src/test/resources/bootstrap.yml`、`application.yml`（共 15 个 bootstrap.yml） | ✓ 全部跟踪 |
| 源码 | 全部 `*.java`（后端）、`*.dart`（Flutter lib/、test/） | ✓ 全部跟踪 |
| 测试脚本 | `scripts/API-TEST/*.py`（4 个版本脚本 + test_auth_api.py）、全部 `cso-unit-test-*.ps1`（13 个）、`scripts/deploy-*.ps1/sh`、`deploy/scripts/*.ps1/sh`（26 个） | ✓ 全部跟踪，**不得误伤** |
| 文档 | `*.md`（根、docs/、scripts/、deploy/） | ✓ 全部跟踪 |
| 数据库脚本 | `scripts/sql/*.sql`（4 个）、`scripts/docker/**`（Dockerfile + docker-compose.yml） | ✓ 全部跟踪 |
| 其他 | `.editorconfig`、`checkstyle.xml`、`README.md`、`agent.md`、`analysis_options.yaml`、`pubspec.yaml`、`pubspec.lock` | ✓ 全部跟踪 |

## 5. git 当前跟踪状态

- `git status --porcelain`：仅 `docs/cso-v0.2.7/cso-task-v0.2.7.json`、`docs/cso-v0.2.7/version_progress.md` 已修改 + `docs/cso-v0.2.7/task_TASK-009/` 未跟踪（本任务产出），**无任何生成/测试/调试过程文件出现在待提交清单**。
- `git status --porcelain --ignored`：43 条被忽略路径，全部为临时/中间/敏感文件（target/、build/、logs/、work/、__pycache__/、jar、env.json、keys/、docs2/ 等），**无应入库文件被误忽略**。
- 备注：`opencode.json` 已被跟踪（历史状态），`.gitignore:101` 的忽略规则对已跟踪文件不生效；按任务约定本任务不执行 `git rm --cached`，如需停止跟踪须另行确认。

## 6. 缺口识别与建议新增规则（编码阶段落地依据）

### 6.1 缺口四类（context 第 0 节清单，实测当前无此类文件，为预防性规则）

**A. JVM / 应用调试产物**（建议插在"Java / Maven / Gradle"分区之后，即 234 行后）
```gitignore
# ===================== JVM / 调试产物 =====================
# 堆转储与 JVM 崩溃日志
*.hprof
hs_err_pid*.log
heapdump.*
*.dmp
# 调试转储目录与文件（dump/ 全局排除；项目内无 dump 源码目录，已核实）
dump/
*.dump
# Derby 嵌入式数据库调试日志（显式补充语义，与 *.log 规则双保险）
derby.log
```

**B. Maven / 构建中间产物**（紧接 A 分区之后，或并入 Java 分区）
```gitignore
# ===================== 构建 / 测试中间产物 =====================
# Maven 插件残留（target/ 已覆盖常规产物，以下为独立/插件级产物）
*.flattened-pom.xml
*.lastUpdated
dependency-reduced-pom.xml
maven-status/
```

**C. 测试产物与缓存**（建议并入 B 分区）
```gitignore
# 测试报告目录（target 之外独立输出时兜底）
surefire-reports/
test-output/
test-results/
# API 接口测试中间文件（精确模式；scripts/API-TEST 下 .py/.ps1 测试脚本为应入库文件，禁止整目录忽略）
scripts/API-TEST/*.tmp
scripts/API-TEST/*.token.json
```
> 实测说明：`scripts/API-TEST` 目录当前只有应入库测试脚本与已覆盖的 `__pycache__/`，无 token 缓存/临时报告文件；上两行为预防性精确规则，若编码阶段发现实际文件名不同，应以实际文件为准调整（保持精确模式，禁止通配符扩大误伤 .py/.ps1）。

**D. 工具残留**（建议插在"环境密钥"分区之前，即 312 行后）
```gitignore
# ===================== 工具残留 =====================
# API 调试 / 抓包会话文件
*.saz
*.chls
*.har
# 编辑器 / 终端会话与历史
*.history
*.session
*.trace
```
> 风险评估：本项目为 Java/Dart 工程，`.har`、`.history`、`.session`、`.trace` 均无源码扩展名冲突（已核实项目内无此类源码文件）；`*.trace` 若后续引入同名源码扩展名需改为路径前缀。

### 6.2 治理红线（落地时必须遵守）
1. `deploy/env.example.json`：现有精确 `env.json`（324 行）不得改为 `env.json*` 通配。
2. `.gitkeep` 白名单：现有 `!*.gitkeep`（284/286 行）与各 `.gitkeep` 跟踪状态不得破坏；新增规则不得出现覆盖 `.gitkeep` 的模式。
3. `pom.xml`、`bootstrap.yml`、`*.java`、`*.dart`、`*.md`、`scripts/API-TEST/*.py|*.ps1`：新规则全部为精确扩展名/目录模式，无 `*.xml`、`*.yml`、`*.py`、`*.ps1` 等通配。
4. 新规则只影响未跟踪文件；已跟踪文件（如 opencode.json）不受影响。
5. 保持现有分区注释风格（`# ===================== 分区名 =====================`）与文件尾 SPDX 头（`# SPDX-License-Identifier: Apache-2.0` / `# Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>`，335-336 行）不动。

## 7. 治理后验证方式（F-012 验收）

1. `git status --porcelain`：确认无 `*.hprof`、`*.dump`、`derby.log`、`surefire-reports`、`*.lastUpdated`、`*.saz/*.chls/*.har` 等新类型文件出现在待提交清单（可临时创建空文件 + `git status --porcelain --ignored` 验证被忽略）。
2. `git check-ignore -v` 抽查：`derby.log`、`dump/`、`maven-status/`、`surefire-reports/`、`x.saz` 等返回新规则行号。
3. `git ls-files` 复核：`deploy/env.example.json`、`.gitkeep`（deploy/scripts 等）、`pom.xml`、`bootstrap.yml`、源码与 `scripts/API-TEST/*.py|*.ps1` 仍全部被跟踪。
4. 提交信息建议：`chore: 完善 .gitignore 排除生成/测试/调试临时与中间文件`（Conventional Commits）。

## 8. 关键文件路径速查

| 文件 | 路径 |
| --- | --- |
| .gitignore | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\.gitignore` |
| 子工程 .gitignore | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\cloudoffice-flutter-app\.gitignore` |
| 环境配置模板 | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\deploy\env.example.json` |
| 部署脚本目录 | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\deploy\scripts\`（26 个 .ps1/.sh，全部入库） |
| 接口测试脚本目录 | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\scripts\API-TEST\`（.py/.ps1 入库，__pycache__ 忽略） |
| 服务日志目录 | `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\logs\`、`deploy\logs\`（忽略） |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
