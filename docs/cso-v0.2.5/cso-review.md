# 代码审核报告
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**审核人**：TL

## 1. 审核范围

本版本（v0.2.5）为部署资产集中化改造（PRD F-001~F-007，TASK-001~006），无运行时代码与接口变更。审核范围覆盖本次版本全部代码/脚本/配置改动：

| 类别 | 文件范围 |
| --- | --- |
| Maven 构建配置 | 根 pom.xml、cloudoffice-gateway/pom.xml、cloudoffice-auth-service/pom.xml、cloudoffice-biz-service/pom.xml、cloudoffice-system-service/pom.xml |
| Flutter 构建脚本 | cloudoffice-flutter-app/build-release.ps1、build-release.sh |
| 部署运维脚本（迁移+适配） | deploy/scripts/ 下 21 个 .sh/.ps1（load-env、deploy-check-env、deploy-db-init、deploy-env、deploy-env-template、deploy-rsa-keygen、deploy-start-auth/biz/gateway/system/services） |
| 环境配置 | deploy/env.json（未入库）、deploy/env.example.json |
| 版本管理 | .gitignore（客户端产物忽略规则、env.json/keys 忽略）、deploy/ 目录结构 |
| 测试资产 | scripts/API-TEST/cso-api-test-v0.2.5.py、cso-unit-test-deploy-v0.2.5.ps1、cso-unit-test-scripts-migrate-v0.2.5.ps1、cso-unit-test-build-deploy-v0.2.5.ps1、cso-unit-test-client-build-v0.2.5.ps1、cso-unit-test-deploy-acceptance-v0.2.5.ps1 |
| 测试记录 | docs/cso-v0.2.5/regression-unit-test.md、regression-api-test.md、cso-testcase-v0.2.5.md |

审核依据：URS/PRD/LLD v0.2.5、SAD（docs/sad.md）、任务清单 cso-task-v0.2.5.json、git 提交 72e9c49~1a61b33 全部变更。

## 2. 审核结论

**结论：需修改后交付。**

- 发现 1 项严重安全问题（S-01：真实数据库口令与 RSA 私钥硬编码入库），必须立即处置；
- 发现 2 项 Linux 侧功能缺陷（Q-01、Q-02：deploy-start-services.sh 自动启动分支失效）；
- 版本管理缺陷 UT-089-3（客户端产物误入库）已在 TASK-005-修复（1a61b33）中闭环修复，但回归报告尚未更新复测记录；
- 接口基线回归（TC-001~045）环境阻塞问题（bootstrap 依赖缺失、RSA 密钥格式契约不匹配）在本版本再次暴露，且与本次迁移的 deploy-rsa-keygen.ps1 直接相关，需回退编码/部署环节修复。

本版本核心目标（deploy 目录集中化、产物落位、脚本迁移、路径适配）实现正确：pom.xml 产物输出与 LLD 设计一致（仅复制最终 jar、overwrite、模块可辨识命名），脚本路径均基于脚本自身目录推导无硬编码绝对路径，AC-1~AC-7 静态校验通过（UT-091~096 全通过）。

## 3. 问题清单

### 3.1 安全漏洞（注入、越权、硬编码密钥、敏感信息泄露）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| S-01 | 严重 | deploy/scripts/deploy-env.ps1（第 25、29、32 行） | 该"已弃用"脚本中硬编码了真实数据库口令 `DB_PASSWORD = 'Jenemy19521005'` 与真实 RSA 私钥/公钥（JWT RS256 签名密钥）的 Base64 值，且文件已被 git 跟踪（TASK-003 迁移入库，git ls-files 确认）。任何可访问仓库的人员均可获得数据库口令与 JWT 签名私钥，可伪造任意用户 Token。 | ① 将 deploy-env.ps1 内容替换为占位符，或直接删除该弃用脚本（仅保留 deploy-env-template.ps1）；② 立即轮换数据库口令与 RSA 密钥对（重新生成并更新 deploy/env.json、Nacos 配置）；③ 仓库如需对外共享，须用 git filter-repo 重写历史清除泄露凭据。 |
| S-02 | 中 | deploy/scripts/deploy-check-env.ps1（第 92 行）、deploy-db-init.ps1（第 62、76、91、95、99、103 行） | 数据库口令以命令行参数 `-p"$DbPassword"` 传入 mariadb，口令会出现在进程命令行（任务管理器/进程列表）中，存在口令泄露风险；deploy-check-env.ps1 中还有以明文拼接的 `$connStr`。 | 改用 .NET MySqlConnector 连接检查（脚本中已有该意图但未实现），或至少保证口令不落日志/不回显；Windows 下 mariadb 客户端无 stdin 密码读取，建议文档中明确风险并优先使用连接器方式。 |
| S-03 | 低 | deploy/env.example.json（第 25 行） | 示例配置中 `MARIADB_ROOT_PASSWORD` 为弱口令默认值 `root123`，虽为模板值但易被直接带入生产。 | 模板可接受，建议在 env.example.json 注释/部署文档中标注"仅限本地开发，生产必须修改"，避免误用。 |

### 3.2 性能陷阱（N+1 查询、内存泄漏、不必要的循环、大数据量全表扫描）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| P-01 | 低 | cloudoffice-flutter-app/build-release.ps1（第 56-58、79-81 行）、build-release.sh（第 54-56、74-76 行） | 每次构建全量复制 Web（数十 MB~上百 MB）与 Windows 产物到 deploy/cloudoffice-flutter-app，且复制前不清空目标目录，重复构建会在目标目录残留上次构建的陈旧文件（如旧版 canvaskit/*.wasm、AssetManifest 等），导致部署包不一致与磁盘冗余。 | 复制前清空目标子目录（如 Remove-Item "$WebTarget/*" -Recurse -Force / rm -rf "$WEB_TARGET"/*）后再复制，保证产物与本次构建严格一致。 |
| P-02 | 低 | 根 pom.xml + 4 个模块 pom.xml（maven-antrun-plugin copy） | 全量构建时 4 个 jar（各 50~70MB）每次全量复制至 deploy，重复构建开销恒定且覆盖旧版本；符合 LLD overwrite 设计，风险可控。 | 无需修改；可在构建说明中提示"从根目录执行 mvn package 一次构建"即可满足产物最新化。 |

### 3.3 代码质量（重复代码、过长函数、命名混乱、缺乏注释）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| Q-01 | 中 | deploy/scripts/deploy-start-services.sh（第 154-155 行） | 在脚本顶层（非函数内）使用 `local svc_name`，bash 报错 "local: can only be used in a function" 且返回非零；在 `set -euo pipefail` 下，MariaDB 未运行且存在 mysql/mariadb systemd 服务时，自动启动分支直接退出，功能失效。 | 删除 `local` 关键字改为普通赋值（第 154-155 行），或将该段逻辑提取为函数。 |
| Q-02 | 中 | deploy/scripts/deploy-start-services.sh（第 185 行） | 引用未定义变量 `$NACOS_STARTUP_SCRIPT`（脚本中从未定义，env.json 亦无此键），`[ -f "$NACOS_HOME/$NACOS_STARTUP_SCRIPT" ]` 恒为假，Nacos 自动启动分支永远走 else，输出"找不到启动脚本"的误导性信息。 | 改为 `if [ -f "$NACOS_HOME/bin/startup.sh" ]`（与第 110 行检测逻辑一致）。 |
| Q-03 | 中 | deploy/scripts/deploy-check-env.ps1（第 35、90 行） | 第 35 行为无意义死代码（表达式结果未使用）；第 90 行 `New-Object System.Data.Common.DbProviderFactory` 试图实例化抽象类必然抛错（try 内被吞），变量 `$conn` 从未使用，与注释"使用 .NET MySQL 连接检查"不符，且 `$connStr` 已拼接含口令的连接串。 | 删除两行无效代码；如需 .NET 连接检查请正确实现（MySqlConnector/MySql.Data），否则仅保留 mariadb 命令行检查并去掉误导注释。 |
| Q-04 | 低 | deploy/scripts/deploy-env.ps1、deploy-env-template.ps1 | 两个文件内容高度重复（重复模板），且 deploy-env.ps1 标注"已弃用"仍保留并含真实凭据（S-01 载体），易造成混淆误用。 | 删除 deploy-env.ps1，统一走 env.json + load-env.ps1 的现行方式；如需保留模板仅保留 template 版本。 |
| Q-05 | 低 | deploy/scripts/deploy-env.ps1/template、deploy-start-auth.ps1/sh 等注释 | 注释仍引用"已执行 deploy/scripts/deploy-env-local.ps1"（该复制后本地文件不在仓库中、流程已弃用），与实际 env.json 流程不符，易误导使用者。 | 统一更新注释，指向"复制 deploy/env.example.json 为 deploy/env.json 并填写，由 load-env 自动加载"的现行流程。 |
| Q-06 | 低 | deploy/scripts/load-env.sh（第 27-33 行） | python3 回退方式将路径直接内插进 Python 源码 `open('$ENV_FILE_PATH')`，若路径含单引号将导致语法错误/命令注入（当前路径由脚本自身推导，风险低）。 | 通过环境变量传递路径（如 `ENV_FILE_PATH="$ENV_FILE_PATH" python3 -c '... os.environ["ENV_FILE_PATH"] ...'`），避免字符串内插。 |

### 3.4 架构合规性（分层是否清晰、是否违反依赖方向、是否绕过已定义的接口）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| A-01 | 低 | 根 pom.xml（deployDir 属性） | `deployDir=${maven.multiModuleProjectDirectory}/deploy` 依赖 Maven 多模块根定位；若开发者在某个模块子目录单独执行 `mvn package`（不带 -am），该属性可能定位到模块级目录，产物落位错乱。 | 在构建文档/脚本中明确约束"必须从根目录执行 mvn package"；或改用 `${project.parent.basedir}/deploy`（模块均继承根 pom，父路径稳定）。 |
| A-02 | 低 | 4 个模块 pom.xml（antrun 配置） | 产物输出任务在 4 个模块各自声明（复制 4 份相似配置），LLD 建议"根 pom 统一配置各模块继承"；当前版本号已统一在根 pom pluginManagement，但执行配置仍分散，后续调整易遗漏。 | 可接受现状（各模块 finalName 不同需各自声明目标文件名）；建议至少将目标文件名约定与注释统一，降低维护成本。 |
| A-03 | 信息 | 全部迁移脚本 | 本版本无运行时代码/接口变更，未违反依赖方向；迁移脚本路径均基于 `$PSScriptRoot` / `BASH_SOURCE` 推导（deploy/scripts → deploy 上级），无硬编码绝对路径，符合 LLD 9.2 路径适配约定，AC-7 冒烟验证通过。 | 无需处理（正面确认）。 |

### 3.5 测试覆盖（关键路径是否有测试、边界条件是否覆盖）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| T-01 | 中 | .gitignore、deploy/cloudoffice-flutter-app/ | UT-089-3（客户端产物入库规则）回归失败（51 个构建产物被 git 跟踪）已由 TASK-005-修复（1a61b33）修复（新增忽略规则 + git rm --cached，当前 git ls-files 已仅剩 .gitkeep）；但 regression-unit-test.md 记录时间早于修复提交，报告仍显示 1 项失败未闭环。 | 版本收尾前重跑 scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1 复测，并在 regression-unit-test.md 补充复测通过记录，关闭失败项。 |
| T-02 | 中 | deploy/scripts/deploy-rsa-keygen.ps1、deploy/env.json、各模块 pom.xml | 接口回归显示 v0.0.1 基线动态接口回归（TC-001~045）环境阻塞：① 服务模块缺 spring-cloud-starter-bootstrap 依赖，bootstrap.yml（Nacos 配置）不生效，服务全部无法启动；② deploy/env.json 中 RSA 密钥为 PEM 整体 Base64（多行含 BEGIN/END），与 Java 端 `Base64.getDecoder()` + X509EncodedKeySpec（DER 单行 Base64）契约不匹配，网关启动即解析失败。该 45 个基线用例从未动态闭环，且与本次迁移的 deploy-rsa-keygen.ps1（输出 PEM Base64 格式）直接相关。 | 回退编码/部署环节修复：① 根 pom/各模块引入 spring-cloud-starter-bootstrap（或按需配置 spring.config.import=optional:nacos: 并关闭 import-check）；② deploy-rsa-keygen.ps1 输出 DER 单行 Base64（或 Java 端改用 MIME 解码器剥除 PEM 头尾）；③ 修复后重新构建启动服务，补跑 cso-api-test-v0.0.1.py 完成 TC-001~045 动态闭环。 |
| T-03 | 低 | deploy/scripts/deploy-start-services.sh、deploy-check-env.ps1 | Linux 侧自动启动分支（Q-01/Q-02）与 Windows 侧 mariadb 检查分支（Q-03）无自动化测试覆盖（静态校验脚本仅断言路径/存在性，未执行真实分支）。 | 补充静态断言（如 grep 校验 `local svc_name` 不在函数外、`NACOS_STARTUP_SCRIPT` 未引用）或增加冒烟执行覆盖，防止功能缺陷回归。 |

## 4. 优先级建议

### 必须修复项（阻断交付）
1. **S-01**：deploy-env.ps1 真实口令与 RSA 私钥入库 —— 替换为占位符/删除文件 + 轮换凭据（必要时重写 git 历史）。
2. **Q-01 / Q-02**：deploy-start-services.sh 顶层 `local` 用法与未定义变量 NACOS_STARTUP_SCRIPT —— 修复 Linux 侧自动启动功能。
3. **T-01**：重跑 UT-089 相关用例并更新回归报告，闭环产品缺陷记录。
4. **T-02**：bootstrap 依赖缺失与 RSA 密钥格式契约不匹配 —— 修复后补跑 TC-001~045 基线接口回归。

### 建议改进项（下一版本或随本次收尾处理）
5. **S-02 / Q-03**：数据库口令命令行暴露与 check-env 无效 .NET 检查代码 —— 清理无效代码，口令传递方式改进。
6. **P-01**：客户端构建产物复制前清空目标目录，保证产物一致性。
7. **Q-04 / Q-05 / Q-06**：删除弃用 deploy-env.ps1、更新脚本注释、load-env.sh 路径传参方式加固。
8. **A-01**：明确"从根目录构建"约束或改用 `${project.parent.basedir}` 定位 deployDir。
9. **S-03 / T-03**：env.example.json 弱口令提示标注；补充脚本分支测试覆盖。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
