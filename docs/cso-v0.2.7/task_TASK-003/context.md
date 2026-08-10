# 任务上下文（TASK-003 重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测）

## 0. 用户输入原文与本任务定位

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成、测试、调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测（基于 load-env 加载的 env.json 配置去除硬编码默认地址；实现 JDK/MariaDB/Redis/Nacos 可用性检查与运行状态检测；Nacos 已安装未启动计"警告（未运行）"；输出通过/警告/失败分级汇总与退出码约定；移除无关检查项）。

### 本任务职责边界（TL 提示）
- 本任务仅重构 **deploy-check-env.ps1 / deploy-check-env.sh** 两个脚本（环境可用性检查 + 运行状态检测），**不涉及** deploy-start-services（TASK-008 一键启动）、deploy-start-all / 单服务脚本（TASK-010）、rsa-keygen（其他任务）、.gitignore 治理（TASK-007）。
- 上游依赖：TASK-001（问题清单，P1/P4/P5 定位）、TASK-002（load-env 模块已完成，F-001）。
- 下游任务：TASK-008、TASK-010。

---

## 1. 任务信息

```json
{
  "id": "TASK-003",
  "title": "重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测",
  "description": "重构 deploy-check-env.ps1 与 deploy-check-env.sh：基于 load-env 加载的 env.json 配置（去除硬编码默认地址），实现 JDK（java 命令可执行 + JAVA_HOME 有效 + 版本 21）、MariaDB（命令/系统服务/进程三重检测 + SELECT 1，口令掩码不打印明文）、Redis（三重检测 + redis-cli ping 返回 PONG）、Nacos（NACOS_HOME/bin/startup.cmd|sh 存在 + HTTP 探测 http://NACOS_ADDR/nacos/ 含 Nacos）可用性检查；输出运行状态检测（进程/系统服务/TCP 端口/HTTP，JDK 复用可用性结论视为就绪）；Nacos 已安装未启动计'警告（未运行）'而非未安装；输出通过/警告/失败分级汇总与退出码约定（失败非零）；移除 Maven/Git 版本等无关检查项或降为可选信息（F-002~F-006、F-010）。",
  "taskType": "common",
  "userStoryId": "US-001",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001", "TASK-002"],
  "downstreamTaskIds": ["TASK-008", "TASK-010"],
  "priority": "P0",
  "status": "未完成",
  "testMethod": ".ps1/.sh 语法校验；JDK/MariaDB/Redis/Nacos 各环境通过/失败/警告场景与退出码验证；源码硬编码地址检查；口令掩码输出检查",
  "acceptanceCriteria": "deploy-check-env.ps1/.sh 基于 env.json 完成 JDK/MariaDB/Redis/Nacos 可用性检查并输出运行状态；环境缺失时输出'失败'与处理提示并以非零码退出；env.json 缺失或关键配置不完整时输出明确错误提示退出非零；Nacos 已安装未启动计'警告（未运行）'；输出分级与退出码符合 F-011 规范；无硬编码默认地址；口令不打印明文"
}
```

## 2. 用户需求

### US-001：基于 env.json 一键检查环境可用性
#### 故事描述
作为（运维/部署工程师），我想要（基于 deploy/env.json 一键检查 JDK/MariaDB/Redis/Nacos 四类环境的可用性），以便（确认环境是否满足部署前置条件，避免人工逐个验证与配置遗漏）。
#### 前置条件
- 已按 deploy.md 完成 `deploy/env.json` 配置（至少含 NACOS_ADDR、NACOS_HOME、DB_*、REDIS_* 关键项）；
- 部署主机已安装（或未安装待检测）JDK 21、MariaDB/MySQL、Redis、Nacos。
#### 验收标准
- [ ] Given deploy/env.json 存在且配置完整，When 执行 `deploy-check-env.ps1`（Windows）或 `deploy-check-env.sh`（Linux），Then 脚本从 env.json 加载配置，逐项检查 JDK/MariaDB/Redis/Nacos 可用性并输出通过/失败/警告汇总
- [ ] Given 某环境缺失（如 JDK 未安装），When 执行检查脚本，Then 对应检查项输出"失败"并给出处理提示（安装 JDK 21 / 配置 JAVA_HOME），脚本以非零码退出
- [ ] Given env.json 缺失或关键配置不完整，When 执行检查脚本，Then 输出明确错误提示（复制 env.example.json 并填写配置）并以非零码退出
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| JDK 版本非 21 | 输出"失败"并提示安装 JDK 21 |
| MariaDB 已安装但不可连接 | 安装检测通过但 SELECT 1 失败，输出"失败"提示检查连接参数 |
| Redis 已安装但 ping 不通 | 输出"失败"提示检查 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD |
| Nacos 已安装但未启动 | HTTP 探测失败计为"警告（未运行）"，与运行状态检查衔接，不误判为未安装 |
| 环境地址硬编码残留 | 检查脚本源码确认无 192.168.1.100 等硬编码地址 |
#### 关联功能编号
F-001、F-002、F-003、F-004、F-005、F-006、F-010

## 3. 本任务相关功能详细描述（PRD v0.2.7 摘录）

### F-001 env.json 配置加载统一（load-env 已完成，TASK-002 交付）
- load-env.ps1 / load-env.sh 从 `deploy/env.json` 读取键值对注入会话环境变量；env.json 缺失时输出错误提示并以非零码退出；关键配置校验下限 8 项：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT，缺失项逐个列出键名（不打印值）并退出非零；
- 各脚本必须经 load-env 加载后校验本脚本所需的关键配置项，缺失项逐个列出并退出；
- **脚本内不得硬编码环境地址与凭据**，全部读取自 env.json 加载后的环境变量。

### F-002 JDK 可用性检查
- 检测项：`java -version` 输出包含 `version "21`（或 `openjdk version "21`）且命令可执行；`JAVA_HOME` 环境变量已设置且目录有效（Test-Path / -d）；
- 任一检测项失败输出"失败"并给出处理建议（安装 JDK 21 或配置 JAVA_HOME），计入失败汇总；
- JDK 为运行时环境，仅检查可用性，不执行启动操作。

### F-003 MariaDB 可用性检查
- 安装检测（任一命中即已安装）：命令（mariadb/mysql/mysqld/mariadbd 可执行）、系统服务（DB_SERVICE_NAME，逗号分隔多值）、进程（DB_PROCESS_NAME，逗号分隔多值）；
- 连通性检测：`SELECT 1` 验证（PowerShell 用 mariadb/mysql 命令行，Linux 用 mariadb/mysql 或 mysqladmin ping）；连接失败输出"失败"并提示检查 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD；
- **密码不得明文打印**：命令中口令以掩码显示（如 `-p'****'`），日志不输出 DB_PASSWORD 明文；
- 定位为"可用性"（已安装 + 可连接），与运行状态检测（F-006）区分。

### F-004 Redis 可用性检查
- 安装检测（任一命中即已安装）：命令（redis-cli/redis-server 可执行）、系统服务（REDIS_SERVICE_NAME）、进程（REDIS_PROCESS_NAME）；
- 连通性检测：`redis-cli -h REDIS_HOST -p REDIS_PORT ping` 返回 `PONG` 视为通过；若 env.json 配置 REDIS_PASSWORD 且客户端支持，按配置带口令验证（口令不打印明文）；
- 连接失败输出"失败"并提示检查 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD；
- 定位为"可用性"（已安装 + 可连通），与运行状态检测（F-006）区分。

### F-005 Nacos 可用性检查
- 安装检测：NACOS_HOME 目录存在且 `bin/startup.cmd`（Windows）/ `bin/startup.sh`（Linux）存在，即视为已安装；
- 可用性探测：HTTP 请求 `http://NACOS_ADDR/nacos/`，响应内容含 "Nacos" 视为连通（当前可用）；**若 Nacos 尚未启动但安装存在，HTTP 探测失败应计为"警告（未运行）"而非"未安装"**，与运行状态检测（F-006）衔接；
- NACOS_ADDR 未配置或格式非法（非 host:port）时输出失败并提示检查 env.json；
- 定位为"可用性"（已安装 + 可达），与运行状态检测（F-006）区分。

### F-006 运行状态检测
- JDK：不执行"启动"检查，仅复用 F-002 可用性检查结论（可用即视为"就绪"）；
- MariaDB/Redis：进程（DB_PROCESS_NAME/REDIS_PROCESS_NAME）存在、系统服务（DB_SERVICE_NAME/REDIS_SERVICE_NAME）为 Running、或 TCP 端口（3306/6379）可达，任一命中即视为运行中；
- Nacos：HTTP 探测 `http://NACOS_ADDR/nacos/` 返回含 "Nacos" 内容视为运行中；探测失败时再检测 java 进程命令行含 nacos 关键字作为辅助判断；
- 运行状态与可用性状态分开输出：已安装但未运行 → 状态"未运行"（供 F-007 启动），已安装且运行 → "运行中"，未安装 → "未安装"（不可启动）；
- 输出汇总表格/分级行，格式与 F-011 输出规范一致。

### F-010 前置检查脚本整合
- 删除脚本内硬编码默认地址（192.168.1.100/101/102 等），全部参数从 env.json（经 load-env 加载）读取；
- 检查范围对齐 F-002~F-005（JDK/MariaDB/Redis/Nacos 可用性）+ F-006（运行状态）；
- 输出分级汇总（通过/失败/警告），存在失败项时给出处理提示并以非零码退出，全部通过退出码 0；
- 移除与"可用性检查 + 运行状态检查"无关的检查项（如 Maven/Git 版本检查、项目代码检查等）或将其降为可选信息输出；
- 保留 .ps1/.sh 双版本且行为一致。

### F-011 脚本契约与输出规范
- 输出分级约定：成功项前缀"通过"（绿色）、警告项"警告"（黄色）、失败项"失败"（红色）；汇总显示通过/警告/失败计数；
- 退出码约定：全部通过退出 0；存在失败项退出非零（1）；存在警告但无失败按脚本约定（建议退出 0 并提示警告）；
- 脚本文件保留 SPDX-License-Identifier 与版权声明（Apache License 2.0），简体中文注释；
- .ps1 与 .sh 同名脚本行为一致、可独立验证（语法校验 + 契约自校验）。

## 4. 项目信息

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**数据库**：MariaDB 10.6（认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）；Redis 7.2.x（会话/黑名单/状态缓存）
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件。后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），配套 Flutter 客户端（Web + Windows）。已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册等。基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

### 与本任务相关的项目规范（project.md 摘要）
- 部署资产：最终构建产物统一输出到根目录 `deploy`；`env.json`/`env.example.json` 与 `deploy/scripts` 下全部 .sh/.ps1 集中存放；构建中间产物禁止进入 deploy。
- 文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明；注释使用简体中文。
- 禁止提交密钥、密码等敏感信息（DB_PASSWORD、RSA 私钥等通过 env.json 注入，日志/输出不得打印明文）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范。

## 5. 系统架构相关

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### 部署顺序与端口（SAD 部署架构）
- 后端服务按依赖顺序启动：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）。
- 基础设施：Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）。
- 基础设施启动顺序：MariaDB → Redis → Nacos（数据库与缓存先于注册中心）。
- 各服务提供 `/api/v1/{module}/health` 健康检查端点；部署 jar 落位 deploy 目录（cloudoffice-gateway.jar 等）。

### 关键配置项（env.json，load-env 加载）
- Nacos：`NACOS_ADDR`（host:port）、`NACOS_HOME`（安装目录，检测/启动用）。
- 数据库：`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`DB_USER`（兼容项）、`DB_SERVICE_NAME`、`DB_PROCESS_NAME`。
- Redis：`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`、`REDIS_SERVICE_NAME`、`REDIS_PROCESS_NAME`。
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64，本任务不涉及密钥处理）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

## 6. TASK-001 问题清单相关依据（issue-list.md 摘录，重点 P1/P4/P5）

### P1 硬编码默认地址（对应 F-010 / R-01 配置驱动）
- **问题定位**：`deploy-check-env.ps1` 第 25-31 行（param 默认值 `NacosAddr="192.168.1.100:8848"`、`DbHost="192.168.1.101"`、`RedisHost="192.168.1.102"`）；`deploy-check-env.sh` 第 25-31 行（`NACOS_ADDR:-192.168.1.100:8848`、`DB_HOST:-192.168.1.101`、`REDIS_HOST:-192.168.1.102`）。
- **问题表现**：脚本以硬编码默认地址为主、从 env.json 加载为辅；以「默认值等于硬编码值」判断是否回退 env，env 未设置时静默回退到错误地址，不报错、不退出。
- **建议处置**：全部删除硬编码默认地址；关键配置（NACOS_ADDR / DB_HOST / REDIS_HOST 等）缺失时显式报错并按「参数错误退出码 2」退出；脚本一律经 load-env 从 deploy/env.json 读取。

### P4 可用性检查与运行状态检查能力分散（对应 F-002~F-006 / F-010）
- **问题定位**：`deploy-check-env.ps1` 第 81-84 行（1.1 Nacos 可用性检查误放「中间件可用性检查」段内做 HTTP 探测）与第 129-132 行（3.1 Nacos 端口连通性检查重复 HTTP 探测 `/nacos/`）；`.sh` 第 60-62 行与第 103-105 行同样重复；check-env 整体无「运行状态检查」能力（无进程/服务状态检测）。
- **问题表现**：① Nacos 可用性检查与连通性检查重复 HTTP 探测（同一 URL 探测两次）；② 检查范围混入 Maven/Git/JAVA_HOME/SQL 文件等「开发环境项」，与 F-002~F-006 不对齐；③ 「运行状态检查」能力在 check-env 中完全缺失；④ 双平台检查项数量与结构不一致（.ps1 实际 10 项 Check、.sh 实际 13 项：.sh 多出 3.2 MariaDB 连通、3.3 Redis 连通、4.3 Maven settings）。
- **建议处置**：重构 check-env 对齐 F-002~F-006：可用性检查（命令/安装/版本）与运行状态检查（进程/服务/端口探测）分离；Nacos 探测统一使用 2.x 的 v1 readiness 接口（`/nacos/v1/console/health/readiness`，v2 接口在 2.3 部分 404）；双平台检查项一一对应；无关开发环境项移除或降级为可选。
- **补充（P7-11）**：Nacos HTTP 探测原使用 `/nacos/` 页面 HTML 匹配；建议统一使用 `/nacos/v1/console/health/readiness`（本任务任务定义明确要求 HTTP 探测 `http://NACOS_ADDR/nacos/` 含 "Nacos" 判定，以任务定义/PRD 为准，两种方式均应识别"运行中"）。

### P5 输出格式与退出码约定不统一（对应 F-011 / R-02 / R-03）
- **问题定位**：`deploy-check-env.ps1` 第 51-68 行（Check 函数仅输出「通过/失败」两档，无「警告」分级）、第 154-159 行（失败 `exit 1`、成功 `exit 0`）；`deploy-check-env.sh` 第 34-47 行（`eval "$cmd"` 执行命令字符串，第 39 行有注入/引号风险，如 `-p'$DB_PASSWORD'` 传参）、第 142-149 行（失败 `exit 1`、成功 `exit 0`）。
- **建议处置**：统一「通过/警告/失败」三级输出（.ps1 用 Write-Host + 颜色、.sh 用 printf + 可选 ANSI，双平台分级一致）；统一退出码：全部通过 0 / 失败非零（参数错误 2 / 依赖缺失 3 可选细化）、警告默认 0；.sh 将 eval 改写为直接命令 + 数组参数（如 `cmd=(mariadb -h "$host" ...); "${cmd[@]}"`）；口令类参数掩码显示（`****`）、日志不打印明文。

### 与本任务相关的附加发现（P7，供参考）
- P7-05：`deploy-check-env.ps1` 第 35 行孤立死代码行（`$MyInvocation...CurrentFileSystemDrive`），重构时删除。
- P7-06：`deploy-check-env.ps1` 第 89-90 行 `$connStr` 含明文密码、`New-Object System.Data.Common.DbProviderFactory` 无效创建（死代码），重构时删除、改用 SELECT 1 且口令参数掩码。
- P7-10：mariadb 命令 `-p'$DB_PASSWORD'` 明文出现在命令字符串中（`set -x` / eval 调试时会泄露），重构时口令参数掩码、避免 eval 拼接。
- P7-11：Nacos HTTP 探测使用 `/nacos/` 页面 HTML 匹配（任务定义要求），注意探测稳定性。
- P7-13：.sh 版本号陈旧（v0.1.7），重构时统一版本号标注。

## 7. TASK-002 已交付 load-env 模块契约（直接复用依据）

### load-env.ps1（PowerShell，dot-source 调用）
- 用法：`. .\deploy\scripts\load-env.ps1 [-EnvFile env.json]`；`$ProjectDir = Split-Path -Parent $PSScriptRoot`，`$EnvFilePath = Join-Path $ProjectDir env.json`；
- env.json 缺失：Write-Error 提示复制 env.example.json 并 `exit 1`；解析失败 `exit 1`；
- 关键配置校验 8 项（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失逐个列出键名并 `exit 1`；
- 加载成功输出 "环境变量已从 ... 加载，共 N 项"（绿色）。

### load-env.sh（Bash，source 调用）
- 用法：`source deploy/scripts/load-env.sh [env.json]`；失败用 `return 1`（不得引入 `set -e`）；
- 依赖 jq（优先）或 python3（回退）解析 env.json 并 export 键值对；
- env.json 缺失/解析失败/关键配置缺失均 `return 1` 并输出错误提示；
- 加载成功输出 "环境变量已从 ... 加载 (jq/python3)，共 N 项"。

## 8. 本任务执行要点（TL 提示）
1. 本任务重构 **deploy/scripts/deploy-check-env.ps1** 与 **deploy/scripts/deploy-check-env.sh** 双版本，必须经 load-env 加载配置、保持双平台行为一致。
2. 检查范围对齐 PRD F-002~F-006：JDK（java 命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程三重检测 + SELECT 1，口令掩码）、Redis（三重检测 + ping PONG）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测含 "Nacos"）；运行状态检测（进程/系统服务/TCP 端口/HTTP，JDK 复用可用性结论视为就绪）。
3. 关键规则：**Nacos 已安装未启动计"警告（未运行）"而非"未安装"**；输出「通过/警告/失败」三级分级汇总；退出码约定（全部通过 0 / 失败非零 1，参数错误可细化 2）；删除硬编码默认地址（192.168.1.100 等）；移除 Maven/Git 版本等无关检查项或降为可选信息；口令不打印明文（掩码 `****`）。
4. 编码质量：删除死代码（P7-05/06）、避免 eval 拼接与引号注入（P7-10）、文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明、简体中文注释、统一版本号标注。
5. 验证方式：.ps1/.sh 语法校验；JDK/MariaDB/Redis/Nacos 各环境通过/失败/警告场景与退出码验证；源码硬编码地址检查（grep 192.168.1.100）；口令掩码输出检查。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
