# 任务上下文（#TASK-003 common 健康检查端点与 API 服务（HealthController + SpringDoc））

## 1. 任务信息

```json
{
  "id": "TASK-003",
  "title": "common 健康检查端点与 API 服务（HealthController + SpringDoc）",
  "description": "在 cloudoffice-common 中实现健康检查端点 GET /api/v1/common/health（API-034），返回统一 ApiResult 响应体（code=200、data 含服务名 cloudoffice-common、状态 UP、版本与时间戳）；配置 SpringDoc OpenAPI 文档分组 common，可通过 Swagger UI 在线查看与调试 common 服务接口；全部接口统一 ApiResult 响应与全局异常处理器兜底，不泄露堆栈。",
  "taskType": "common",
  "userStoryId": "US-001",
  "apiId": "API-034",
  "upstreamTaskIds": ["TASK-002"],
  "downstreamTaskIds": ["TASK-007"],
  "priority": "P0",
  "status": "执行中",
  "testMethod": "接口测试",
  "acceptanceCriteria": "GET /api/v1/common/health 返回 200 与统一 ApiResult（含服务名/状态 UP/版本/时间戳）；SpringDoc 文档分组 common 可在线访问；响应体格式与 auth/biz/system 健康检查端点一致。"
}
```

## 2. 用户需求（US-001：cloudoffice-common 服务化部署与健康检查）

- 故事描述：运维/部署工程师希望 cloudoffice-common 作为独立微服务部署并注册到 Nacos，提供健康检查端点，与其他微服务一样具备服务注册、健康检查与部署运维能力。
- 前置条件：Nacos 2.3 已启动；cloudoffice-common jar 包已构建并落位 deploy 目录；deploy/env.json 已配置 NACOS_ADDR 等关键项。
- 验收标准：
  1. common 服务启动后成功注册到 Nacos（服务名 `cloudoffice-common`）。
  2. 访问 `GET /api/v1/common/health` 返回 200 与统一 ApiResult 响应体（含服务名、状态 UP、版本与时间戳）。
  3. 访问 SpringDoc Swagger UI 可在线查看 common 服务接口文档（分组 `common`）。
  4. 服务化改造不影响现有 gateway/auth/biz/system 对 common 公共模块的 Maven 依赖关系，现有服务编译与运行正常。
- 边界情况：Nacos 未启动时 common 启动失败并输出 Nacos 连接错误提示；端口被占用时提示检查端口占用；common jar 缺失时部署脚本提示不启动；现有服务依赖 common 编译失败时检查公共类/接口兼容性。
- 关联功能：F-001（common 服务化改造）、F-002（common API 接口服务）。

## 3. 用户输入（本次需求要点）

1. cloudoffice-common 不仅包括公共函数、变量定义，也包括公用接口，因此也需要和其他微服务一样提供 API 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本、部署文档和 readme.md、deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理，统一配置不同微服务、不同业务场景下的所有配置工作。除去启动的环境变量外，所有需要的配置都通过通用配置管理配置。
5. 当前任务只是配置的接口，后端管理后面会增加。

> 注：通用配置管理接口（/api/v1/common/config）为独立任务（TASK-006 或下游），本任务（TASK-003）聚焦健康检查端点与 API 服务基础能力。

## 4. 项目信息（关键摘录）

- 项目中文名称：云漫智企
- 项目英文名称：CloudStrollOffice
- 项目英文缩写：cso
- 技术栈：Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba 2023.0.1.0（Nacos 2.3）
- 项目类型：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
- 基础设施：MariaDB 10.6（3306）、Redis 7.2（6379）、Nacos 2.3（8848）
- 服务端口：gateway 9000、auth-service 9100、biz-service 9200、system-service 9400、**common 9300（v0.2.8 新增）**

## 5. 系统架构相关章节（SAD 关键摘录）

### 5.1 common 服务化（ADR-017）
- cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务（端口 9300）。
- 新增启动类（@SpringBootApplication）、bootstrap.yml（Nacos discovery/config server-addr，服务名 cloudoffice-common）、application.yml（端口、SpringDoc 分组）。
- common 同时保留公共 jar 模块能力（ApiResult/PageResult/异常体系/枚举常量），下游服务仍以 Maven 依赖方式引用 common 公共类与接口，服务化改造不得破坏现有模块依赖关系。
- common 需引入 `spring-cloud-starter-bootstrap`（与 ADR-014 一致），保证 bootstrap.yml 在 Spring Boot 3.x 下正常加载。

### 5.2 API 服务（F-002）
- 健康检查端点 `GET /api/v1/common/health` 返回统一 ApiResult 响应体（code=200、消息 healthy、data 含服务名 `cloudoffice-common`、状态 `UP`、版本号与时间戳），格式与 auth/biz/system 健康检查端点一致。
- SpringDoc OpenAPI 文档分组 `common`，可通过 Swagger UI 在线查看与调试。
- 全部接口统一 ApiResult 响应 + 全局异常处理器兜底，不泄露堆栈。
- API 路径统一规范 `/api/v1/common/{resource}`。

### 5.3 网关与白名单（F-006）
- 网关路由 `/api/v1/common/**` → `lb://cloudoffice-common`。
- 健康检查端点 `/api/v1/common/health` 加入网关 AuthFilter 白名单（无 Token 访问）。

### 5.4 通用配置管理（ADR-018，本任务不实现，仅了解）
- 查询接口 `GET /api/v1/common/config`、`GET /api/v1/common/config/{serviceName}`，需认证（非白名单）。
- 本版本仅查询接口，增删改与后端管理界面后续版本迭代。

## 6. 参考实现（现有健康检查端点契约）

现有 auth/biz/system 均有健康检查端点 `GET /api/v1/{module}/health`，本任务 common 端点需与其响应体格式一致（统一 ApiResult：code=200、消息、data 含服务名/状态 UP/版本/时间戳）。具体实现可参考 cloudoffice-common 公共模块中已有的 ApiResult 类与各服务 HealthController 的写法。
