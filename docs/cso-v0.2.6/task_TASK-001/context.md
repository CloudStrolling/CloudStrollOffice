# 任务上下文（#TASK-001 引入 spring-cloud-starter-bootstrap 配置引导依赖（根 pom + 4 个服务模块 pom））

## 0. 需求来源与问题背景（用户输入：v0.2.5 回归报告）

- **需求来源**：v0.2.6 版本根据 `docs/cso-v0.2.5/regression-api-test.md` 记录的 v0.0.1 基线遗留缺陷（审核项 T-02）修复，确保 4 个服务可启动、API 测试全部跑通。
- **问题现象（v0.2.5 回归报告 §3.2 根因 1）**：所有服务模块缺少 `spring-cloud-starter-bootstrap` 依赖（全项目 pom 均未引入）：
  - auth/biz/system 启动报 `No spring.config.import property has been defined`（nacos-config 的 import-check 失败）；
  - bootstrap.yml（含 nacos discovery/config server-addr）在 Spring Boot 3.x 下默认不加载，Nacos 配置引导链路断裂。
- **影响**：4 个业务服务（gateway/auth/biz/system）均无法启动，v0.0.1 基线接口回归（TC-001~045）持续处于"环境阻塞"状态。
- **建议（回归报告 §3.3）**：在根 pom 或各模块引入 `spring-cloud-starter-bootstrap`（或按需启用 `spring.config.import=optional:nacos:` 与关闭 import-check），保证 bootstrap.yml 生效；修复后重新构建 4 个 jar 并启动服务。

## 1. 任务信息

```json
{
  "id": "TASK-001",
  "title": "引入 spring-cloud-starter-bootstrap 配置引导依赖（根 pom + 4 个服务模块 pom）",
  "description": "修复 v0.0.1 基线遗留缺陷（v0.2.5 回归报告审核项 T-02，SAD ADR-014，PRD F-001）：在根 pom.xml 的 dependencyManagement 统一声明 spring-cloud-starter-bootstrap（版本随 Spring Cloud 2023.0.1 管理），并在 gateway/auth-service/biz-service/system-service 四个服务模块 pom 中实际引入该依赖（仅根 pom 声明而不在模块引入仍会报 import-check 错误）。引入后恢复 bootstrap.yml（含 spring.cloud.nacos.discovery.server-addr 与 spring.cloud.nacos.config.server-addr）在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路，消除 auth/biz/system 启动报错 No spring.config.import property has been defined。仅允许构建/依赖配置变更，不得改动接口层（Controller/DTO/响应体）、业务代码逻辑、数据库结构。",
  "taskType": "backend",
  "userStoryId": "US-001",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": [
    "TASK-003"
  ],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "构建验证：mvn package 依赖解析无冲突；启动验证：服务启动日志不再出现 No spring.config.import property has been defined",
  "acceptanceCriteria": "1. 根 pom dependencyManagement 与 4 个服务模块 pom 均包含 spring-cloud-starter-bootstrap 依赖；2. mvn package 构建通过、无依赖解析错误；3. 服务启动日志不再出现 No spring.config.import property has been defined；4. bootstrap.yml 生效，Nacos discovery/config server-addr 被正确加载；5. 无接口层/业务代码/客户端代码改动"
}
```

## 2. 用户需求（PRD US-001 / F-001，v0.2.6）

### US-001：恢复服务配置引导，解决服务无法启动
#### 故事描述
作为（运维/部署人员），我想要（引入 bootstrap 配置引导依赖并恢复 bootstrap.yml 加载），以便（gateway/auth/biz/system 4 个服务能够正常启动并注册到 Nacos，打通 API 测试环境）。
#### 前置条件
- 具备 Maven 多模块项目源码与根 pom/模块 pom 修改权限；
- Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）已启动且网络可达。
#### 验收标准
- [ ] Given 全项目 pom 未引入 bootstrap 相关依赖，When 在根 pom 或 4 个服务模块引入 `spring-cloud-starter-bootstrap`（或等价启用 `spring.config.import=optional:nacos:` 并关闭 import-check）并重新构建，Then 构建成功且 bootstrap.yml 生效，Nacos discovery/config server-addr 被正确加载
- [ ] Given 服务已具备 bootstrap 引导能力，When 按部署文档启动 auth/biz/system 服务，Then 启动日志不再出现 `No spring.config.import property has been defined`，服务成功注册到 Nacos
- [ ] Given 4 个服务启动完成，When 访问各服务健康检查接口，Then `/api/v1/{auth|biz|system}/health` 均返回正常状态
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 仅根 pom 声明 dependencyManagement 而未在模块引入 | 启动仍报 import-check 错误，需在模块实际引入依赖 |
| 方案 B 使用 spring.config.import | 需同步关闭 import-check，否则仍报错 |
| 引入依赖后 Nacos 不可达 | 服务启动失败，报连接 Nacos 异常，需先保障基础设施可用 |
| 修复后仍有其他启动问题 | 纳入本版本继续排查或记录后续版本处理（URS 假设项） |
#### 关联功能编号
F-001、F-003

### F-001 引入 bootstrap 配置引导依赖（PRD §4.1 摘要）
- 在根 pom（dependencyManagement）或各服务模块 pom 引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（含 nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载机制，打通 Nacos 配置引导链路，消除 auth/biz/system 启动报错 `No spring.config.import property has been defined`。
- 业务规则：引入后 bootstrap.yml 必须重新生效；不得改变既有接口契约与业务代码逻辑，仅允许构建/依赖配置变更。

## 3. 项目信息（docs/project.md）

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**总体介绍**：微服务企业办公套件，后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册（策略工厂）、密码管理、验证码管理等；基础设施依赖 MariaDB 10.6 / Redis 7.2 / Nacos 2.3。

### 关键编码规范（节选）
- 后端按 Maven 多模块组织：公共代码统一放 `cloudoffice-common`，各业务模块只依赖 common，禁止模块间互相依赖与循环依赖；包根为 `org.cloudstrolling.cloudoffice.{模块}`。
- 类名/接口名 UpperCamelCase，方法名/变量名 lowerCamelCase，常量 UPPER_SNAKE_CASE；接口命名不带 I 前缀。
- 遵循《阿里巴巴 Java 开发手册》（checkstyle.xml 强制执行）；缩进 4 空格、UTF-8、行宽 ≤120、K&R 大括号。
- 关键类、方法、复杂业务逻辑必须有简体中文注释；文件头保留 SPDX-License-Identifier 与版权声明。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:）。
- 禁止提交密钥、密码等敏感信息。

### 相关项目地图（节选）
- 根目录 `pom.xml` — Maven 父 POM（groupId: org.cloudstrolling，统一依赖管理，dependencyManagement 声明版本）
- `cloudoffice-gateway/` — API 网关（端口 9000）：GatewayApplication、AuthFilter（9 步校验）、RsaKeyConfig 等
- `cloudoffice-auth-service/` — 认证服务（端口 9100）：AuthApplication、各 Controller/Service/策略等
- `cloudoffice-biz-service/` — 企业服务（端口 9200，骨架）：BizApplication、HealthController
- `cloudoffice-system-service/` — 系统服务（端口 9400，骨架）：SystemApplication、HealthController
- `cloudoffice-common/` — 公共模块（JAR，无启动类）：ApiResult/PageResult/ErrorCode 等
- 各服务模块均含 `src/main/resources/bootstrap.yml`（Nacos discovery/config server-addr）与 `application.yml`

## 4. 系统架构相关（SAD）

### ADR-014 bootstrap 配置引导依赖（核心决策）
- **决策内容**：四个服务模块（gateway/auth/biz/system）统一引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路。
- **理由**：Spring Boot 3.x 默认不加载 bootstrap.yml，全项目 pom 缺该依赖导致 auth/biz/system 启动报 `No spring.config.import property has been defined`、Nacos 引导断裂（v0.0.1 基线遗留缺陷 T-02，v0.2.6 修复）；引入依赖为最小改动且不改变接口契约。

### 1.2 设计约束（技术约束节选）
- 后端统一 Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba 2023.0.1.0；gateway/auth/biz/system 四个服务模块**必须**引入 `spring-cloud-starter-bootstrap`（Spring Cloud 2023.0.1 配置引导依赖），保证 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下正常加载，Nacos 配置/注册引导链路不得断裂（v0.2.6 修复 v0.0.1 基线遗留缺陷）。

### 技术栈选型（节选）
- 配置引导：`spring-cloud-starter-bootstrap`（Spring Cloud 2023.0.1）——Spring Boot 3.x 下 bootstrap.yml 默认不加载，需显式引入该依赖恢复 Nacos 配置/注册引导链路，消除 `No spring.config.import property has been defined` 启动报错。

### 部署说明（节选）
- 各服务已引入 `spring-cloud-starter-bootstrap`，启动时 bootstrap.yml（Nacos discovery/config server-addr）先于 application.yml 加载，完成 Nacos 配置引导与注册；端口：Nacos 8848、MariaDB 3306、Redis 6379、网关 9000、认证 9100、业务 9200、系统 9400。

## 5. 任务实现要点（TL 提示）

1. **修改范围（仅 pom.xml，5 个文件）**：
   - 根 `pom.xml`：`<dependencyManagement>` 中声明 `spring-cloud-starter-bootstrap`（版本随 Spring Cloud 2023.0.1 BOM 管理，可复用 spring-cloud-dependencies BOM 的版本属性或显式声明版本）；
   - `cloudoffice-gateway/pom.xml`、`cloudoffice-auth-service/pom.xml`、`cloudoffice-biz-service/pom.xml`、`cloudoffice-system-service/pom.xml`：`<dependencies>` 中实际引入 `spring-cloud-starter-bootstrap`（不写版本号，由父 pom dependencyManagement 管理）。
2. **关键坑**：仅根 pom dependencyManagement 声明而不在模块 pom 实际引入，模块仍不会获得该依赖，启动仍报 `No spring.config.import property has been defined`（PRD US-001 边界情况第 1 条）。
3. **禁止事项**：不得改动接口层（Controller/DTO/响应体）、业务代码逻辑、数据库结构、客户端代码；不得修改 bootstrap.yml/application.yml（若既有配置已含 nacos server-addr 且服务无需改动）。
4. **验证**：`mvn package` 依赖解析无冲突；启动后日志无 `No spring.config.import property has been defined`，bootstrap.yml 中 Nacos discovery/config server-addr 被正确加载。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
