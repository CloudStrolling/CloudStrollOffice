# 任务上下文（#TASK-006 重构单服务启动脚本 deploy-start-gateway/auth/biz/system）

## 1. 任务信息

```json
{
  "id": "TASK-006",
  "title": "重构单服务启动脚本 deploy-start-gateway/auth/biz/system",
  "description": "重构 deploy-start-gateway、deploy-start-auth、deploy-start-biz、deploy-start-system 共 8 个单服务脚本（.ps1/.sh）：加载 env.json，校验本服务所需关键变量（gateway/auth 校验 NACOS_ADDR、RSA_PUBLIC_KEY，auth 另需 RSA_PRIVATE_KEY；biz/system 校验 NACOS_ADDR、DB_PASSWORD，biz 使用 DB_USER 与 auth 使用 DB_USERNAME 的差异保持现状一致）与对应 jar 存在后，以 java -Xms256m -Xmx512m -jar <jar> 启动；行为与 deploy-start-all 中对应服务启动逻辑一致；输出分级（通过/警告/失败）与退出码约定符合 F-011 规范（F-009）。",
  "taskType": "common",
  "userStoryId": "US-003",
  "apiId": "",
  "upstreamTaskIds": [
    "TASK-002",
    "TASK-005"
  ],
  "downstreamTaskIds": [
    "TASK-008",
    "TASK-010"
  ],
  "priority": "P1",
  "status": "未完成",
  "testMethod": ".ps1/.sh 语法校验；4 个服务各场景（关键变量缺失/jar 缺失/启动成功）行为验证，与 start-all 对应逻辑一致性核对",
  "acceptanceCriteria": "4 个单服务脚本各自独立可运行；校验本服务关键变量与 jar 存在后启动对应服务；行为与 deploy-start-all 对应服务启动逻辑一致；输出分级与退出码符合 F-011 规范"
}
```

## 2. 用户需求（US-003 相关部分）

### US-003：按部署顺序一键启动全部后端服务
#### 故事描述
作为（运维/部署工程师），我想要（按部署顺序 gateway → auth → biz → system 一键启动全部 Java 后台服务），以便（一条命令完成整个后端环境拉起，避免按错顺序、遗漏服务、逐个开窗口的低效与出错风险）。
#### 前置条件
- 4 个服务 jar 包已构建并落位 deploy 目录（cloudoffice-gateway.jar 等）；
- `deploy/env.json` 已配置 NACOS_ADDR、RSA_PRIVATE_KEY/RSA_PUBLIC_KEY、DB_PASSWORD 等关键项；
- 基础设施（MariaDB/Redis/Nacos）已就绪（可由 US-002 脚本先行拉起）。
#### 关联功能编号
F-001、F-008、F-009

### 本任务对应功能 F-009：单服务启动脚本保持可用（PRD 4.9 节）
#### 功能描述
保留并重构单个服务启动脚本（deploy-start-gateway/auth/biz/system），加载 env.json、校验必备变量与 jar 存在后启动对应服务，供按需单独启动使用。
#### 业务规则
- 4 个单服务脚本（gateway/auth/biz/system）各自独立可运行，行为与 F-008 中对应服务启动逻辑一致；
- 各脚本校验本服务所需变量：gateway/auth 校验 NACOS_ADDR、RSA_PUBLIC_KEY（auth 另需 RSA_PRIVATE_KEY）；biz/system 校验 NACOS_ADDR、DB_PASSWORD（biz 使用 DB_USER、auth 使用 DB_USERNAME 的差异保持与现状一致）；
- 校验 jar 存在后以 `java -Xms256m -Xmx512m -jar <jar>` 启动；
- 脚本输出与 F-011 输出规范一致。

### 输出规范 F-011（PRD 4.11 节，与本任务相关部分）
- 输出分级约定：成功项前缀"通过"（绿色）、警告项"警告"（黄色）、失败项"失败"（红色）；汇总显示通过/警告/失败计数；
- 退出码约定：全部通过退出 0；存在失败项退出非零（1）；存在警告但无失败按脚本约定（建议退出 0 并提示警告）；
- 脚本文件保留 SPDX-License-Identifier 与版权声明（Apache License 2.0），简体中文注释；
- .ps1 与 .sh 同名脚本行为一致、可独立验证。

## 3. 项目信息（精简）

**项目中文名称**：云漫智企　**项目英文名称**：CloudStrollOffice　**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**总体介绍**：云漫智企是基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件，后端由 common（公共模块）、gateway（API 网关 :9000）、auth-service（认证服务 :9100）、biz-service（企业服务 :9200）、system-service（系统服务 :9400）组成；基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3（注册/配置中心），支持 Docker Compose 一键编排。v0.2.7 聚焦部署脚本体系重构与仓库清洁度治理。

### 编码规范要点（脚本相关）
- 注释规范：关键逻辑必须有简体中文注释；文件头保留 SPDX-License-Identifier 与版权声明。
- 其他规范：禁止提交密钥、密码等敏感信息；提交信息遵循 Conventional Commits（refactor: 等）。
- 安全约定：DB_PASSWORD / RSA_* 等敏感值仅校验非空，缺失提示只列键名，任何输出不打印明文。

## 4. 系统架构相关（SAD 精简）

### G-A7 部署运维自动化（v0.2.7）
以 `deploy/env.json` 为唯一配置源，重构 `deploy/scripts` 全部脚本（.ps1/.sh 双平台），形成"环境可用性检查（deploy-check-env）→ 基础设施运行状态检查与一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all，gateway→auth→biz→system）→ 单服务启动（deploy-start-{svc}）"的脚本能力矩阵，统一经 load-env 加载配置、输出分级（通过/警告/失败）与退出码约定，实现"一条命令完成整个后端环境拉起"。

### 脚本体系约束（v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据；
- 单服务启动脚本（deploy-start-gateway/auth/biz/system）与一键启动（deploy-start-all）对应逻辑一致；
- .ps1 与 .sh 双平台行为对齐，输出分级（通过/警告/失败）与退出码约定统一（失败非零）；
- RSA 密钥格式契约（ADR-015，DER 编码单行 Base64）在脚本重构中不得破坏。

### ADR-016 部署脚本体系重构与配置驱动（2026-08-10）
v0.2.7 系统性重构 `deploy/scripts` 全部脚本：以 `deploy/env.json` 为唯一配置源；能力划分为可用性检查、基础设施一键启动、后端服务按序一键启动与单服务启动四类；.ps1 与 .sh 双平台行为对齐，输出分级与退出码约定统一；删除弃用脚本残留；`.sh` 与 `.ps1` 密钥输出契约对齐（不破坏 ADR-015）。仅涉及部署运维层，不改变后端架构、接口契约与数据库设计。

## 5. 现有代码与重构对齐基准（编码要点，TL 收集）

### 5.1 待重构文件（8 个）
`deploy/scripts/` 下：deploy-start-gateway.ps1/.sh、deploy-start-auth.ps1/.sh、deploy-start-biz.ps1/.sh、deploy-start-system.ps1/.sh

### 5.2 现状问题清单（重构前）
| 问题 | 说明 |
| --- | --- |
| 前台阻塞启动 | 4 个 .ps1 直接 `java -Xms256m -Xmx512m -jar "$JarPath"` 前台运行（.sh 用 `exec java` 替换进程），脚本被阻塞，无后台化、无 PID 记录、无日志落盘、无健康确认 |
| 校验变量不一致 | gateway 校验 NACOS_ADDR+RSA_PUBLIC_KEY；auth 校验 9 个变量（含 DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT 等，超出 F-009 契约）；biz/system .ps1 只校验 NACOS_ADDR（缺 DB_PASSWORD），.sh 校验 NACOS_ADDR+DB_PASSWORD——双平台行为不一致 |
| 无输出分级 | 错误输出用 ❌/红色 emoji 风格，无"通过/警告/失败"分级与计数汇总 |
| 无健康确认 | 启动后不探测端口/HTTP，无法确认服务真正起来 |
| 契约残留 | .sh 头部版本仍为 v0.1.7（旧版）；注释引用已弃用的 deploy-env-local 脚本；.ps1 无 SPDX 头；.sh 无 SPDX 头 |
| DB_USER 差异 | biz .sh 现状校验 DB_PASSWORD 且注释说明 biz 使用 DB_USER（与 auth 的 DB_USERNAME 不同），需保持此差异 |

### 5.3 行为对齐基准：deploy-start-all.ps1/.sh（TASK-005 产物，本任务目标一致性的唯一基准）
deploy-start-all 中"单服务启动 + 健康确认"逻辑（每个服务子块，重构单服务脚本须与此一致）：
1. **加载配置**：`$ProjectDir = Split-Path -Parent $PSScriptRoot; . "$PSScriptRoot\load-env.ps1"`（.sh：`source "$SCRIPT_DIR/load-env.sh" || exit $?`）；缺失 env.json / 关键配置由 load-env 兜底退出。
2. **前置校验**：java 命令可用（`Get-Command java` / `has_cmd java`）；jar 包存在（`Test-Path -LiteralPath $jarPath` / `[ -f "$PROJECT_DIR/$jar" ]`）；关键环境变量非空（缺失只列键名，不打印值）。
3. **后台启动**：
   - Windows：`$proc = Start-Process -FilePath "java" -ArgumentList "-Xms256m", "-Xmx512m", "-jar", $jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru`；`$proc.Id | Out-File -Encoding ascii $pidFile`。
   - Linux：`nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &`；`echo $! > "$PID_FILE"`。
   - 日志/PID 落位：`deploy/logs/{module}-start.log`（.ps1 另有 -start.err）、`deploy/logs/{module}.pid`。
4. **健康确认**：`Wait-HealthUp`（HTTP 优先：gateway `http://localhost:9000/`、auth/biz/system `http://localhost:{port}/api/v1/{module}/health`；TCP 端口探测备用），循环轮询默认 30 次/间隔 2 秒/单次超时 3 秒（.ps1 参数 RetryCount/RetryInterval/ProbeTimeout 可配置；.sh 环境变量 RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT 可配置）。
5. **输出分级**：`Write-Result "通过"|"警告"|"失败"`（.ps1 绿/黄/红，不用 emoji；.sh print_result 同）+ 全局计数 PASS/WARN/FAIL；标题含版本 v0.2.7。
6. **退出码**：存在失败项退出 1（并提示处理），全部通过退出 0。
7. **服务契约表**（start-all 中定义，重构单服务脚本按各自服务取对应行）：
   | 服务 | jar 文件名 | 端口 | 健康 URL | 关键变量 | 失败提示 |
   | --- | --- | --- | --- | --- | --- |
   | gateway | cloudoffice-gateway.jar | 9000 | http://localhost:9000/ | NACOS_ADDR, RSA_PUBLIC_KEY | 请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置 |
   | auth | cloudoffice-auth-service.jar | 9100 | http://localhost:9100/api/v1/auth/health | NACOS_ADDR, RSA_PUBLIC_KEY, RSA_PRIVATE_KEY, DB_PASSWORD | 请检查 RSA 密钥对/DB_PASSWORD 配置 |
   | biz | cloudoffice-biz-service.jar | 9200 | http://localhost:9200/api/v1/biz/health | NACOS_ADDR, DB_PASSWORD | 请检查 DB_PASSWORD 配置 |
   | system | cloudoffice-system-service.jar | 9400 | http://localhost:9400/api/v1/system/health | NACOS_ADDR, DB_PASSWORD | 请检查 DB_PASSWORD 配置 |

### 5.4 load-env 模块契约（TASK-002 产物，已就绪）
- `. "$PSScriptRoot\load-env.ps1"`（dot-source，退出码非零即终止）；`.sh` 为 `source "$SCRIPT_DIR/load-env.sh"`（source 型，失败 return 非零，调用方 `|| exit $?`）。
- env.json 缺失：提示复制 env.example.json 并填写配置，非零退出。
- 关键配置下限 8 项校验：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT；缺失逐项列键名、不打印值。
- 安全约定：敏感值仅注入会话环境变量，任何输出不打印明文。

### 5.5 重构验收对照（本任务验收标准）
- 4 个单服务脚本各自独立可运行（不依赖其他单服务脚本）；
- 校验本服务关键变量（按 5.3 契约表）与 jar 存在后启动对应服务；
- 行为与 deploy-start-all 对应服务启动逻辑一致（后台化启动、日志/PID 落位、健康确认、失败处理）；
- 输出分级（通过/警告/失败）与退出码符合 F-011（失败退出 1，全部通过退出 0）；
- .ps1 与 .sh 双平台行为一致；文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明，简体中文注释；
- 不打印 DB_PASSWORD / RSA_* 明文（缺失提示只列键名）。

### 5.6 相关上游任务产物
- TASK-002：load-env.ps1/.sh（统一配置加载模块，已就绪，见 5.4）；
- TASK-003/004：deploy-check-env / deploy-start-services（提供"检测函数 + 输出分级 Write-Result/print_result"既有模式，单服务脚本可复用同款输出函数风格）；
- TASK-005：deploy-start-all.ps1/.sh（后端服务按序一键启动，本任务行为对齐基准，见 5.3）。
- 下游：TASK-008（代码注释）、TASK-010（代码审核）依赖本任务完成。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
