# 任务上下文（TASK-004 重构 deploy-start-services.ps1 / .sh 基础设施运行状态检查与一键启动）

## 0. 用户输入原文与任务定义

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成，测试，调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
重构 deploy-start-services.ps1 与 deploy-start-services.sh：加载 env.json 并检测 MariaDB/Redis/Nacos 运行状态；对未运行且已安装的服务按 MariaDB → Redis → Nacos 顺序自动启动（启动方式优先级：系统服务 Start-Service / systemctl → 可执行文件 mysqld/mariadbd/redis-server → Nacos 执行 NACOS_HOME/bin/startup.cmd 或 startup.sh）；每次启动后再次探测确认（进程/TCP/ping/HTTP），不报假成功，启动超时或失败输出警告/失败并给出处理建议；未安装服务不尝试启动，输出"未安装，请先安装"并计入失败；JDK 仅检查可用性不执行启动；已运行服务幂等跳过输出"已运行"；口令掩码不打印明文（F-006、F-007）。

### 本任务在 v0.2.7 脚本体系中的位置
- 上游：TASK-001（问题清单）、TASK-002（load-env.ps1/.sh 统一配置加载，已完成）、TASK-003（deploy-check-env 可用性检查与运行状态检测，已完成，本任务可复用其检测函数）。
- 本任务：重构 deploy-start-services.ps1/.sh 基础设施运行状态检查与一键启动（F-006、F-007）。
- 下游：TASK-008（后端服务按序一键启动 deploy-start-all）、TASK-010（单服务启动脚本保持可用）。

---

## 1. 任务信息

```json
{
  "id": "TASK-004",
  "title": "重构 deploy-start-services.ps1 / .sh 基础设施运行状态检查与一键启动",
  "description": "重构 deploy-start-services.ps1 与 deploy-start-services.sh：加载 env.json 并检测 MariaDB/Redis/Nacos 运行状态；对未运行且已安装的服务按 MariaDB → Redis → Nacos 顺序自动启动（启动方式优先级：系统服务 Start-Service / systemctl → 可执行文件 mysqld/mariadbd/redis-server → Nacos 执行 NACOS_HOME/bin/startup.cmd 或 startup.sh）；每次启动后再次探测确认（进程/TCP/ping/HTTP），不报假成功，启动超时或失败输出警告/失败并给出处理建议；未安装服务不尝试启动，输出'未安装，请先安装'并计入失败；JDK 仅检查可用性不执行启动；已运行服务幂等跳过输出'已运行'；口令掩码不打印明文（F-006、F-007）。",
  "taskType": "common",
  "userStoryId": "US-002",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001", "TASK-002"],
  "downstreamTaskIds": ["TASK-008", "TASK-010"],
  "priority": "P0",
  "status": "未完成",
  "testMethod": ".ps1/.sh 语法校验；未运行/已运行/未安装三场景启动与探测确认验证；启动超时与权限边界处理验证；口令掩码输出检查",
  "acceptanceCriteria": "deploy-start-services.ps1/.sh 检测到未运行的 MariaDB/Redis/Nacos 时自动启动并再次探测确认，输出'通过'；未安装服务不尝试启动并输出'未安装，请先安装'计入失败；JDK 不执行启动仅输出可用性结论；已运行服务幂等跳过；启动超时输出警告不报假成功；日志不泄露 DB_PASSWORD/REDIS_PASSWORD 明文"
}
```

## 2. 用户需求

### US-002：基础设施未启动时一键拉起
#### 故事描述
作为（运维/部署工程师），我想要（检查 MariaDB/Redis/Nacos 是否已启动，并将未启动的服务一键启动），以便（在部署准备阶段用一条命令完成基础设施拉起，无需手工逐个启动）。
#### 前置条件
- 部署主机已安装 MariaDB/MySQL、Redis、Nacos（安装位置/服务名/进程名在 env.json 配置）；
- 具备启动系统服务的权限（Windows 管理员 / Linux sudo，按环境需要）。
#### 验收标准
- [ ] Given MariaDB 未运行，When 执行 `deploy-start-services.ps1`/`.sh`，Then 脚本自动启动 MariaDB（优先系统服务，其次可执行文件）并再次探测确认，输出"通过"
- [ ] Given Redis 未运行，When 执行 `deploy-start-services.ps1`/`.sh`，Then 脚本自动启动 Redis（优先系统服务，其次 redis-server）并 ping 确认，输出"通过"
- [ ] Given Nacos 未运行，When 执行 `deploy-start-services.ps1`/`.sh`，Then 脚本执行 `NACOS_HOME/bin/startup.cmd`（Windows）或 `startup.sh`（Linux）启动并 HTTP 探测确认，输出"通过"
- [ ] Given 某服务未安装，When 执行启动脚本，Then 脚本不尝试启动该服务，输出"未安装，请先安装"并计入失败/提示
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 服务启动超时 | 输出"警告"并给出等待重试/手动检查建议，不报假成功 |
| 启动命令需要管理员权限 | 输出权限提示，指导以管理员身份执行 |
| 密码在启动命令中出现 | 日志以掩码（`****`）显示，不打印 DB_PASSWORD/REDIS_PASSWORD 明文 |
| JDK 被误认为需要启动 | 仅输出可用性结论（就绪/缺失），不执行启动操作 |
#### 关联功能编号
F-006、F-007

## 3. 项目信息

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**数据库**：MariaDB 10.6（认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）；Redis 7.2.x（会话/黑名单/状态缓存）
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件。后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），配套 Flutter 客户端（Web + Windows）。已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册等。基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

### 与本任务相关的项目规范（project.md 摘要）
- 部署资产：最终构建产物统一输出到根目录 `deploy`；`env.json`/`env.example.json` 与 `deploy/scripts` 下全部 .sh/.ps1 集中存放；构建中间产物禁止进入 deploy。
- 文件头保留 SPDX-License-Identifier 与版权声明；注释使用简体中文。
- 禁止提交密钥、密码等敏感信息（RSA 密钥对、数据库密码等通过 env.json 注入，密钥文件放 keys/ 并加入 .gitignore）；不提交日志与临时文件。

## 4. 系统架构相关

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### 部署顺序与端口（SAD 部署架构）
- 后端服务按依赖顺序启动：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）。
- 基础设施：Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）。
- **基础设施启动顺序：MariaDB → Redis → Nacos（数据库与缓存先于注册中心，避免服务注册时依赖缺失）**。
- 各服务提供 `/api/v1/{module}/health` 健康检查端点；部署 jar 落位 deploy 目录（cloudoffice-gateway.jar 等）。

### 关键配置项（env.json，load-env 加载）
- Nacos：`NACOS_ADDR`（host:port）、`NACOS_HOME`（安装目录，检测/启动用）。
- 数据库：`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`DB_USER`（兼容项）、`DB_SERVICE_NAME`、`DB_PROCESS_NAME`。
- Redis：`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`、`REDIS_SERVICE_NAME`、`REDIS_PROCESS_NAME`。
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

### 输出分级与退出码约定（F-011）
- 成功项前缀"通过"（绿色）、警告项"警告"（黄色）、失败项"失败"（红色）；汇总显示通过/警告/失败计数。
- 全部通过退出 0；存在失败项退出非零（1）；存在警告但无失败退出 0 并提示警告。

## 5. 上游可复用代码与检测函数（TASK-002/TASK-003 已完成）

### 5.1 load-env.ps1 / load-env.sh（TASK-002 已完成，deploy/scripts/load-env.ps1、load-env.sh）
- 统一从 `deploy/env.json` 加载全部键值对为会话环境变量；env.json 缺失时提示复制 env.example.json 并以非零码退出；关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT 8 项）缺失时逐个列出缺失键名退出非零。
- **PowerShell 调用方式**：`dot-source`，`.\deploy\scripts\load-env.ps1`（本脚本内部已处理 env.json 缺失与关键配置缺失，下游脚本无需重复校验）。
- **Bash 调用方式**：`source "$SCRIPT_DIR/load-env.sh"`（source 型脚本，失败 return 1；注意调用方不得引入 set -e 之外的冲突）。

### 5.2 deploy-check-env.ps1 / .sh（TASK-003 已完成，可复用检测函数）
本任务应复用 TASK-003 已重构的检测逻辑（.ps1 与 .sh 各函数），保持一致契约：
- **Write-Result / print_result**（.ps1 第 33-40 行 / .sh 第 38-45 行）：输出"通过/警告/失败"三级并累计计数（$script:pass/$script:warn/$script:fail 或 PASS/WARN/FAIL）。
- **Split-Csv / split_csv**（.ps1 第 44-47 行 / .sh 第 48-50 行）：逗号分隔字符串转数组，用于 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME 检测清单。
- **Test-Installed**（.ps1 第 50-62 行）：命令/系统服务/进程三重安装检测，任一命中返回命中方式（如 "命令 mariadb" / "服务 MySQL" / "进程 mysqld"）。.sh 对应为 has_cmd/has_svc/has_proc 组合（第 53-71 行）。
- **Test-TcpPort / tcp_port_open**（.ps1 第 65-78 行 / .sh 第 83-95 行）：TCP 端口可达性探测（TcpClient 超时 / /dev/tcp），用于运行状态检测。
- **Test-NacosHttp / nacos_http_ok**（.ps1 第 81-86 行 / .sh 第 98-100 行）：HTTP 探测 `http://NACOS_ADDR/nacos/` 响应含 "Nacos"。
- **Test-NacosJavaProcess**（.ps1 第 89-95 行）：java.exe 命令行含 nacos 的辅助判断；.sh 用 `pgrep -f "nacos"`。
- **svc_active**（.sh 第 74-80 行）：systemd 服务是否活跃。
- **MariaDB/Redis 运行状态检测逻辑**（.ps1 第 213-248 行 / .sh 第 220-246 行）：进程 / 系统服务 Running / TCP 端口 任一命中即运行中。
- **Nacos 运行状态检测**（.ps1 第 250-262 行 / .sh 第 248-260 行）：HTTP 探测为主 + java 进程含 nacos 辅助。
- **口令掩码与安全约定**：MariaDB `-p"$env:DB_PASSWORD"`（.ps1 第 146 行）/ 数组参数 `-p"$DB_PASSWORD"`（.sh 第 154 行），日志仅显示 `****`；Redis 用 `REDISCLI_AUTH` 环境变量传递口令（.ps1 第 169 行 / .sh 第 179 行），命令与日志不出现明文。

### 5.3 env.json 检测清单解析（TASK-003 已确立）
- `.ps1`：`$dbSvcName = if ($env:DB_SERVICE_NAME) { Split-Csv $env:DB_SERVICE_NAME } else { @("MySQL", "MariaDB") }`（.ps1 第 98-101 行）。
- `.sh`：`mapfile -t DB_SERVICES < <(split_csv "${DB_SERVICE_NAME:-MySQL,MariaDB}")`（.sh 第 103-106 行）。

## 6. 现状问题与重构要点（TASK-001 issue-list 与本任务相关部分）

### 6.1 当前 deploy-start-services.ps1/.sh 的问题（重构前现状）
- **P1**：硬编码默认地址残留（现状脚本已改经 load-env 加载，需确认无 192.168.1.100 等）。
- **P4**：未纳入 JDK 可用性结论（F-006 要求输出 JDK 就绪/缺失）。
- **P5**：输出分级与退出码不统一——.ps1 第 48 行 icon 为空字符（emoji 不显示）、有警告仍 exit 0（.ps1 第 219 行 / .sh 第 239 行）；.sh 用 `✅/⚠️/❌` emoji + ANSI 色，双平台风格不一致；.sh 第 14 行 set -e 下 source load-env.sh 的返回值处理。
- **P7-10**：mariadb 命令 `-p'$DB_PASSWORD'` 明文出现在命令字符串中（需改为掩码/环境变量传参）。
- **P7-11**：Nacos HTTP 探测使用 `/nacos/` 页面 HTML 匹配（沿用，契约与 check-env 一致）。
- **P7-12**：Nacos 启动后固定等待 8 秒再探测，非循环轮询 + 超时上限（需改为循环探测 + 超时上限，如 30s 内每 2s 探测）。
- **P7-13**：.sh 版本号陈旧（v0.2.0），重构时统一为 v0.2.7。

### 6.2 重构要点（对照 F-006/F-007 业务规则）
1. **启动顺序**：MariaDB → Redis → Nacos（数据库与缓存先于注册中心）。
2. **JDK**：仅检查可用性（java 命令 + JAVA_HOME + 版本 21，可复用 TASK-003 逻辑），不执行启动，输出"就绪/缺失"结论。
3. **已运行服务**：幂等跳过，输出"已运行"。
4. **未安装服务**：不尝试启动，输出"未安装，请先安装"并计入失败（按脚本约定决定是否继续执行后续服务）。
5. **启动方式优先级**：
   - MariaDB/Redis：系统服务（Windows `Start-Service` / Linux `sudo systemctl start`）→ 可执行文件（`mysqld`/`mariadbd`/`redis-server`，Windows `Start-Process` / Linux 后台启动 + `--daemonize yes`）。
   - Nacos：Windows 执行 `NACOS_HOME/bin/startup.cmd`（standalone 模式）/ Linux 执行 `bash NACOS_HOME/bin/startup.sh`。
6. **启动后再次探测确认**（进程/TCP/HTTP），确认成功输出"通过"；启动超时（循环探测 + 超时上限）或失败输出"警告/失败"并给出处理建议（等待重试/手动检查/权限提示），不得报假成功。
7. **口令掩码**：启动与检测命令中的口令不得明文打印（DB_PASSWORD/REDIS_PASSWORD）；Redis 用 REDISCLI_AUTH 环境变量。
8. **输出分级与退出码**：统一"通过/警告/失败"三级（双平台一致，不依赖 emoji 而用 [通过]/[警告]/[失败] 文本 + 颜色）；全部通过退出 0，存在失败退出 1，仅警告退出 0。
9. **汇总输出**：输出各服务状态汇总，全部可达提示可启动后端服务。

## 7. 本任务执行要点（TL 提示）
1. 本任务为 F-006/F-007 落地，是 deploy-start-services.ps1/.sh 的重构（双平台），应最大限度复用 TASK-003 已完成的检测函数与 TASK-002 的 load-env，保持 .ps1/.sh 行为一致。
2. 关键验收：三场景（未运行→启动确认/已运行→幂等跳过/未安装→不尝试启动计入失败）；JDK 仅输出可用性；启动超时输出警告不报假成功；日志不泄露口令明文。
3. 脚本文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明，版本号统一 v0.2.7，注释使用简体中文。
4. 本任务不涉及接口（apiId 为空）与数据库变更。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
