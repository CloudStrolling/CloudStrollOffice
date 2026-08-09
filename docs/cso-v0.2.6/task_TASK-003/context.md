# 任务上下文（TASK-003 重新构建 4 个服务 jar 并完成启动验证与健康检查）

**项目**：云漫智企（CloudStrollOffice，cso）｜**版本**：v0.2.6｜**任务类型**：backend（部署验证类）｜**优先级**：P0
**上游依赖**：TASK-001（bootstrap 依赖）、TASK-002（RSA 密钥契约）｜**下游**：TASK-004、TASK-005
**关联**：PRD F-003 / US-001 / US-002；API-012 / API-032 / API-033

## 1. 任务信息

**任务名称**：重新构建 4 个服务 jar 并完成启动验证与健康检查（gateway/auth/biz/system）

**任务描述**：在 TASK-001（bootstrap 依赖）与 TASK-002（RSA 密钥契约）修复完成后（PRD F-003，US-001/US-002）：
1. 在项目根目录执行 `mvn package` 重新构建 gateway/auth-service/biz-service/system-service 4 个服务 jar（确认 deploy/ 下最终产物更新）；
2. 按部署文档标准流程（deploy/env.json 环境变量注入 + Nacos 注册 + MariaDB/Redis 依赖可用）启动 4 个服务；
3. 核对启动日志不再出现 `No spring.config.import property has been defined` 与 `RSA 公钥解析失败`；
4. 确认 4 个服务全部注册到 Nacos（控制台可见 cloudoffice-* 实例）；
5. 访问健康检查接口 `/api/v1/auth/health`、`/api/v1/biz/health`、`/api/v1/system/health` 均返回服务名/状态/版本/时间戳且状态正常。

任一步骤失败按启动日志定位（bootstrap 依赖/RSA 密钥/基础设施）并修复后重新构建启动。

## 2. 需求来源：v0.2.5 回归测试问题（docs/cso-v0.2.5/regression-api-test.md）

v0.2.5 回归发现：4 个业务服务（gateway/auth/biz/system）**均无法启动**，cso-api-test-v0.0.1.py 在 admin 登录步骤即因连接拒绝崩溃（退出码 1），TC-001~045 持续"环境阻塞"。根因（v0.0.1 基线遗留缺陷，审核项 T-02）：

1. **bootstrap 依赖缺失**：全项目 pom 均未引入 `spring-cloud-starter-bootstrap`，Spring Boot 3.x 下 bootstrap.yml 默认不加载，auth/biz/system 启动报 `No spring.config.import property has been defined`，Nacos 配置引导链路断裂；
2. **RSA 密钥格式契约不匹配**：deploy/env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 PEM 文件整体 Base64（多行、含 BEGIN/END 标记与 \r\n），而 Java 端 RsaKeyConfig 使用严格 `Base64.getDecoder()` + `X509EncodedKeySpec`（期望 DER 编码单行 Base64），网关启动即报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。

**修复方向（TASK-001/TASK-002 已完成）**：引入 bootstrap 依赖（SAD ADR-014）+ 统一密钥为 DER 编码单行 Base64（SAD ADR-015）。本任务（TASK-003）为修复后的**构建 + 启动验证闭环**，即 PRD F-003。

## 3. 用户故事（PRD v0.2.6）

### US-001：恢复服务配置引导，解决服务无法启动
- 作为运维/部署人员，引入 bootstrap 配置引导依赖并恢复 bootstrap.yml 加载，使 4 个服务正常启动并注册到 Nacos。
- **前置条件**：具备 Maven 多模块项目源码与根 pom/模块 pom 修改权限；Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）已启动且网络可达。
- **验收标准（本任务相关）**：
  - Given 服务已具备 bootstrap 引导能力，When 按部署文档启动 auth/biz/system 服务，Then 启动日志不再出现 `No spring.config.import property has been defined`，服务成功注册到 Nacos；
  - Given 4 个服务启动完成，When 访问各服务健康检查接口，Then `/api/v1/{auth|biz|system}/health` 均返回正常状态。
- **边界情况**：仅根 pom 声明 dependencyManagement 而未在模块引入 → 启动仍报 import-check 错误；引入依赖后 Nacos 不可达 → 服务启动失败，需先保障基础设施可用。

### US-002：统一 RSA 密钥格式契约，消除公钥解析失败
- 作为运维/部署人员，deploy-rsa-keygen.ps1 生成的 RSA 密钥格式与 Java 端解码逻辑一致，env.json 注入的密钥可被 gateway/auth 正确解析，服务不再因 `RSA 公钥解析失败` 崩溃。
- **验收标准（本任务相关）**：
  - Given 采用方案 A（脚本侧修复），重新执行 deploy-rsa-keygen.ps1 生成密钥，Then 输出为 DER 编码单行 Base64（无 PEM 头尾、无换行），env.json 注入后网关启动无 `RSA 公钥解析失败`；
  - Given 网关与 auth 服务启动成功，When 使用签名密钥完成登录签发与网关验签，Then RS256 签名验签链路正常工作（Token 可签发、可验证）；
  - 私钥不写入日志、不进入代码仓库。

### US-003（下游相关，本任务前置铺垫）：完成 v0.0.1 基线接口动态回归闭环
- 前置条件：4 个服务已全部启动且健康检查通过；Nacos、MariaDB、Redis 运行正常，admin 账号（admin/admin123）可用。
- Given 网关（9000）与认证服务（9100）可访问，执行 `python cso-api-test-v0.0.1.py http://localhost:9000`，脚本正常跑完不再因连接拒绝崩溃。

## 4. 健康检查接口契约（API-012 / API-032 / API-033，沿用主文档 docs/cso-api.md）

| 接口编号 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- |
| API-012 | GET | /api/v1/auth/health | 认证服务健康检查：服务名/状态/版本/时间戳 | 白名单 |
| API-032 | GET | /api/v1/biz/health | 企业服务骨架探活 | 需认证（见备注） |
| API-033 | GET | /api/v1/system/health | 系统服务骨架探活 | 需认证（见备注） |

- 统一响应体 `ApiResult<T>`（code/message/data/timestamp）。
- **备注**：网关白名单仅配置 `/api/v1/auth/health`；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入白名单，**直连服务端口（9200/9400）可免认证访问**，经网关访问需携带有效 Token。本版本维持现状不做变更。
- 健康检查返回内容要求：服务名、状态（正常）、版本、时间戳。
- 网关路由：`/api/v1/auth/**` → cloudoffice-auth-service（:9100）、`/api/v1/biz/**` → cloudoffice-biz-service（:9200）、`/api/v1/system/**` → cloudoffice-system-service（:9400）；网关统一入口 9000。
- 服务注册名：cloudoffice-gateway / cloudoffice-auth-service / cloudoffice-biz-service / cloudoffice-system-service（Nacos 控制台可见 cloudoffice-* 实例）。

## 5. 编译方案要点（deploy/build.md）

- **编译命令**（项目根目录）：`mvn clean package -DskipTests`（一次性构建 5 个模块：common、gateway、auth-service、biz-service、system-service）。
- **产物落点**：package 阶段四个服务模块通过 `maven-antrun-plugin` 将最终可执行 jar **复制至 deploy 目录**（仅复制单个最终 jar，不递归 target）；输出目录由根 pom.xml 属性 `deployDir=${maven.multiModuleProjectDirectory}/deploy` 统一指定。
- **产物清单**：cloudoffice-gateway.jar（9000）、cloudoffice-auth-service.jar（9100）、cloudoffice-biz-service.jar（9200）、cloudoffice-system-service.jar（9400）→ 全部落位 deploy/。
- 便捷脚本：`.\\deploy\\scripts\\build-backend.ps1`（等价一键后端构建）。
- 常见问题：`mvn 不是内部或外部命令`（未配 PATH）、`无效的发行版本 21`（JDK 非 21）、依赖下载超时（配阿里云镜像）、构建成功但 deploy 下无 jar（模块编译失败，查 Maven 输出）。

## 6. 部署方案要点（deploy/deploy.md）

### 部署架构与端口
| 组件 | 产物 | 端口 |
| --- | --- | --- |
| API 网关 cloudoffice-gateway | deploy/cloudoffice-gateway.jar | 9000 |
| 认证服务 cloudoffice-auth-service | deploy/cloudoffice-auth-service.jar | 9100 |
| 企业服务 cloudoffice-biz-service | deploy/cloudoffice-biz-service.jar | 9200 |
| 系统服务 cloudoffice-system-service | deploy/cloudoffice-system-service.jar | 9400 |
| MariaDB / Redis / Nacos | 基础设施 | 3306 / 6379 / 8848 |

### 标准启动流程（部署步骤）
1. **准备部署资产**：按 build.md 执行 `mvn clean package -DskipTests`，确认 4 个 jar 位于 deploy/；部署主机已装 JDK 21、MariaDB、Redis、Nacos。
2. **环境配置（env.json）**：`Copy-Item deploy\\env.example.json deploy\\env.json`，填写 DB_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等（**严禁提交含真实口令的 env.json 到 git**）。
3. **生成 RSA 密钥对（首次部署必做）**：`deploy\\scripts\\deploy-rsa-keygen.ps1`，密钥输出到 deploy/keys/，将 Base64 内容填入 env.json 的 RSA_PRIVATE_KEY/RSA_PUBLIC_KEY，并同步 Nacos 配置。密钥变更后旧令牌全部失效属预期。
4. **数据库初始化**：`deploy\\scripts\\deploy-db-init.ps1`（从 env.json 读连接信息，执行 scripts/sql/ 下初始化 SQL，创建认证库 cloudstroll_office_auth）。
5. **启动基础设施**：`deploy\\scripts\\deploy-start-services.ps1`（加载 env.json → 检测/启动 MariaDB、Redis、Nacos）。
6. **启动后端服务**（建议网关最先）：
   ```powershell
   .\\deploy\\scripts\\deploy-start-gateway.ps1
   .\\deploy\\scripts\\deploy-start-auth.ps1
   .\\deploy\\scripts\\deploy-start-biz.ps1
   .\\deploy\\scripts\\deploy-start-system.ps1
   ```
   或直接：`java -Xms256m -Xmx512m -jar deploy\\cloudoffice-gateway.jar`（其余服务同理）。

### 健康检查与验证
- 网关存活：访问 `http://<主机>:9000/` 返回网关响应（404/401 均说明服务在运行）。
- 各服务注册：Nacos 控制台 `http://<主机>:8848/nacos/` 服务列表，gateway/auth/biz/system 均在线。
- 认证接口：POST `http://<主机>:9000/`（客户端实际调用路径）返回正常业务响应。
- 数据库连通：服务日志无数据库连接异常。
- 日志：各服务日志输出至启动窗口；应用日志目录项目根目录 `logs/`。

### 常见问题与处理
- 服务启动报 Nacos 连接失败 → Nacos 未启动或 NACOS_ADDR 错误，先执行 deploy-start-services.ps1。
- 服务启动报数据库连接失败 → 检查 DB_HOST/DB_PORT/DB_PASSWORD，执行 deploy-db-init.ps1。
- 登录报令牌校验失败 → RSA 密钥与 Nacos 配置不一致，重新生成密钥并同步 Nacos 配置，重启服务。
- env.json 未生效 → 修改后需重启对应服务。

## 7. 架构约束与修复契约（SAD v0.2.6）

- **ADR-014（bootstrap 配置引导依赖）**：四个服务模块（gateway/auth/biz/system）统一引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载（TASK-001 已实施）。
- **ADR-015（RSA 密钥格式契约）**：统一 RSA 密钥格式为 **DER 编码单行 Base64**（无 PEM 头尾、无换行）：deploy-rsa-keygen.ps1 输出/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码逻辑严格一致；禁止多行 PEM 整体 Base64 直接注入（TASK-002 已实施）。
- 技术约束：Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba 2023.0.1.0；服务注册到 Nacos，网关统一路由 `/api/v1/{module}/**`。
- 模块依赖单向（下游依赖 common），服务间禁止循环依赖。
- 密钥通过环境变量注入，禁止硬编码；私钥不入库、不写日志。

## 8. 验收标准（本任务）

1. `mvn package` 构建通过，deploy/ 下 4 个服务 jar 更新落位；
2. 4 个服务全部启动成功且注册到 Nacos；
3. 启动日志无 `No spring.config.import property has been defined` 与 `RSA 公钥解析失败`；
4. `/api/v1/auth/health`、`/api/v1/biz/health`、`/api/v1/system/health` 健康检查全部返回正常（服务名/状态/版本/时间戳）；
5. 网关（9000）与认证服务（9100）可访问，为回归脚本执行（TASK-004/TASK-005）提供前置条件。

## 9. 测试方法

- 服务启动日志检查（无两项缺陷报错）；
- 接口测试：调用 `/api/v1/{auth|biz|system}/health` 健康检查接口验证返回正常；
- Nacos 注册实例核对（控制台可见 cloudoffice-* 实例）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
