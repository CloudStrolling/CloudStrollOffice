# 任务上下文（TASK-005 网关路由与白名单扩展（/api/v1/common/** 路由））

## 1. 任务信息

```json
{
  "id": "TASK-005",
  "title": "网关路由与白名单扩展（/api/v1/common/** 路由）",
  "description": "在 cloudoffice-gateway 路由配置中新增 /api/v1/common/** → lb://cloudoffice-common（Nacos 服务发现负载均衡）路由规则；将 /api/v1/common/health 加入网关 AuthFilter 白名单（无 Token 放行，与 auth/biz/system 健康检查端点一致）；/api/v1/common/config 与 /api/v1/common/config/{serviceName} 保持非白名单（需经 AuthFilter 认证）。不影响既有 gateway/auth/biz/system 路由与白名单规则。",
  "taskType": "backend",
  "userStoryId": "US-002",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": ["TASK-007"],
  "priority": "P0",
  "status": "执行中",
  "testMethod": "接口测试",
  "acceptanceCriteria": "/api/v1/common/** 经网关转发至 common 服务；/api/v1/common/health 白名单放行（无 Token 返回 200）；/api/v1/common/config 需认证（无 Token 返回 401/403）；既有路由不受影响。"
}
```

## 2. 用户需求（US-002：通过通用配置管理接口查询运行时配置）

**故事描述**：作为（后端开发工程师），我想要（通过通用配置管理 API 接口按微服务名称、配置分组、配置键查询运行时配置项），以便（在业务代码中统一获取所需配置，替代硬编码与分散的配置文件查询）。

**前置条件**：
- cloudoffice-common 服务已启动并注册到 Nacos；
- 网关已配置 `/api/v1/common/**` 路由规则；
- 通用配置管理数据已初始化（配置项已录入）；
- 调用方持有合法 Bearer Token。

**验收标准**：
- 携带合法 Bearer Token，请求 `GET /api/v1/common/config`，返回全部微服务的运行时配置项列表（统一 ApiResult 响应体）
- 携带合法 Bearer Token，请求 `GET /api/v1/common/config/auth-service`，返回 auth-service 微服务的运行时配置项列表
- 携带合法 Bearer Token，请求 `GET /api/v1/common/config?serviceName=gateway&group=security`，返回 gateway 微服务 security 分组下的配置项列表
- 配置项中含敏感配置，查询返回时脱敏或排除，不暴露明文
- 未携带 Bearer Token 或 Token 无效，请求配置查询接口，网关 AuthFilter 返回 401/403 错误响应
- 查询的微服务名称不存在，返回空列表或未找到提示（非 500 错误）

**关联功能**：F-003、F-004、F-005、F-006

## 3. 用户输入（v0.2.8 需求原文）

1. cloudoffice-common 不仅包括公共的函数、变量定义，也包括公用的接口，因此也需要和其他微服务一样提供 API 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本、部署文档和 readme.md、deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理。统一配置不同微服务、不同业务场景下的所有配置工作。除去启动的环境变量外，所有需要的配置，都通过通用配置管理配置。
5. 当前这个任务只是配置的接口，后端管理后面会增加。

## 4. 项目背景（docs/project.md 摘要）

- **项目**：云漫智企（CloudStrollOffice），基于 Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 的微服务企业办公套件。
- **后端模块**：common（公共模块，v0.2.8 服务化）/ gateway（9000）/ auth-service（9100）/ biz-service（9200）/ system-service（9400）。
- **基础设施**：Nacos 2.3（8848，注册/配置中心）、MariaDB 10.6（3306）、Redis 7.2（6379）。
- **项目英文缩写**：cso；**当前版本**：v0.2.8。

## 5. 系统架构相关章节（docs/sad.md 摘要）

### 5.1 网关（cloudoffice-gateway，:9000）
- **路由分发** `/api/v1/{module}/**`：现有 auth/biz/system 路由；**v0.2.8 新增** `/api/v1/common/**` → `lb://cloudoffice-common`（Nacos 服务发现负载均衡）。
- **AuthFilter 全局认证过滤器**：9 步校验（白名单放行 → Bearer 格式 → RS256 验签 → tokenType → 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传 X-User-Id/X-Tenant-Id 等）。
- **白名单端点**：登录/注册/刷新/验证码发送/密码找回/健康检查（含 `/api/v1/common/health`）/OpenAPI 直接放行；其余请求必须携带合法 Bearer Token。
- **通用配置查询接口**（`/api/v1/common/config`、`/api/v1/common/config/{serviceName}`）**不在白名单**中，需经 AuthFilter 认证。

### 5.2 common 服务（v0.2.8 服务化，:9300）
- 公共 jar 模块能力保留：ApiResult/PageResult、统一异常体系（29 错误码）、枚举常量、Redis Key 常量、SpringDoc 配置。
- API 服务新增：健康检查 `/api/v1/common/health`（白名单放行）、通用配置管理查询 `/api/v1/common/config`、SpringDoc OpenAPI 文档（分组 common）。
- 服务名：`cloudoffice-common`，注册到 Nacos。

### 5.3 关键架构约束（ADR）
- **ADR-002**：认证校验统一收敛到网关 AuthFilter，下游服务不重复验签。
- **ADR-011**：全接口统一 ApiResult（code/message/data/timestamp）+ 29 错误码 + 全局异常处理器。
- **ADR-017**：common 服务化改造（端口 9300，spring-cloud-starter-bootstrap）。
- **ADR-018**：通用配置管理接口先行（非白名单需认证）。
- **ADR-019**：部署顺序含 common（common→gateway→auth→biz→system）。

## 6. 本任务范围界定

**本任务（TASK-005）只做网关侧改动**：
1. cloudoffice-gateway 路由配置新增 `/api/v1/common/** → lb://cloudoffice-common` 路由规则。
2. 网关 AuthFilter 白名单新增 `/api/v1/common/health`（无 Token 放行）。
3. `/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` 保持非白名单（需认证）。
4. 不影响既有 gateway/auth/biz/system 路由与白名单规则。

**不在本任务范围**（由并行任务负责）：
- TASK-001：通用配置库与配置表初始化（DBD SQL）。
- TASK-002：cloudoffice-common 服务化改造（启动类/yml/依赖）。
- TASK-003：common 健康检查端点（HealthController）。
- TASK-004：通用配置管理查询接口（ConfigController/Service 等）。
- TASK-006~010：编译脚本、部署脚本、env.json、部署文档/readme 更新。

**注意**：本任务可能与其他任务并行执行，写入版本目录共享文档（testcase/dbd/api/ui-test-record/API-TEST 脚本）前必须先读取最新内容再合并写回；只写本任务目录与任务对应代码文件（gateway 模块）。
