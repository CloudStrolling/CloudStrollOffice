# 任务上下文（#TASK-002 cloudoffice-common 服务化改造与通用配置管理接口先行）

## 1. 任务信息

```json
{
  "id": "TASK-002",
  "title": "cloudoffice-common 服务化改造（启动类/bootstrap.yml/application.yml/依赖）",
  "description": "将 cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务：新增 CommonApplication 启动类（org.cloudstrolling.cloudoffice.common 包，@SpringBootApplication + main），新增 bootstrap.yml（spring.application.name=cloudoffice-common，Nacos discovery/config server-addr 从环境变量 NACOS_ADDR 读取），新增 application.yml（server.port=${COMMON_PORT:9300}、SpringDoc 分组 common），pom.xml 引入 spring-cloud-starter-bootstrap 及 Spring Boot/Web/Nacos 注册依赖；保留公共 jar 模块能力（ApiResult/PageResult/异常体系/枚举常量），确保 gateway/auth/biz/system 对 common 的 Maven 依赖关系不被破坏。",
  "taskType": "common",
  "userStoryId": "US-001",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": ["TASK-003", "TASK-004", "TASK-006"],
  "priority": "P0",
  "status": "执行中",
  "testMethod": "单元测试 + 接口测试",
  "acceptanceCriteria": "common 可独立启动并注册到 Nacos（服务名 cloudoffice-common，端口 9300）；bootstrap.yml 经 spring-cloud-starter-bootstrap 正常引导 Nacos；gateway/auth/biz/system 依赖 common 公共模块编译与运行不受影响。"
}
```

## 2. 用户需求

### US-001：cloudoffice-common 服务化部署与健康检查
作为（运维/部署工程师），我想要（cloudoffice-common 作为独立微服务部署并注册到 Nacos，提供健康检查端点），以便（与其他微服务一样具备服务注册、健康检查与部署运维能力，可通过部署脚本统一管理）。

#### 前置条件
- Nacos 2.3 已启动且网络可达；
- cloudoffice-common jar 包已构建并落位 deploy 目录；
- deploy/env.json 已配置 NACOS_ADDR 等关键项。

#### 验收标准
- [ ] Given cloudoffice-common jar 与环境变量就绪，When 启动 common 服务，Then 服务成功启动并注册到 Nacos（服务名 `cloudoffice-common`）
- [ ] Given common 服务已启动，When 访问 `GET /api/v1/common/health`，Then 返回 200 与统一 ApiResult 响应体（含服务名、状态 UP、版本与时间戳）
- [ ] Given common 服务已启动，When 访问 SpringDoc Swagger UI，Then 可在线查看 common 服务接口文档（分组 `common`）
- [ ] Given common 服务化改造完成，When 编译 gateway/auth/biz/system，Then 现有服务对 common 公共模块的 Maven 依赖关系不受影响，编译与运行正常

#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| Nacos 未启动 | common 服务启动失败，输出 Nacos 连接错误提示 |
| 端口被占用 | 启动失败，提示检查端口占用并指导处理 |
| common jar 缺失 | 部署脚本输出 jar 缺失提示，不启动服务 |
| 现有服务依赖 common 编译失败 | 检查 common 模块变更是否破坏公共类/接口兼容性 |

### 关联功能
F-001、F-002（common 服务化改造与 API 接口服务）

## 3. 项目信息（docs/project.md 摘要）

- 项目中文名称：云漫智企
- 项目英文名称：CloudStrollOffice
- 项目英文缩写：cso
- 编程语言：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）
- 项目类型：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
- 数据库：MariaDB 10.6（业务关系型数据库）
- 基础设施：MariaDB 10.6（3306）、Redis 7.2（6379）、Nacos 2.3（8848）
- 后端服务：gateway（9000）、auth-service（9100）、biz-service（9200）、system-service（9400）、cloudoffice-common（本版本新增独立服务，9300）

## 4. 系统架构相关（docs/sad.md 摘要）

- Maven 多模块：cloudoffice-common 为公共模块，被 gateway/auth/biz/system 以 Maven 依赖方式引用；
- 各业务服务使用 Spring Cloud Alibaba Nacos 做注册与配置中心，bootstrap.yml 引入 spring-cloud-starter-bootstrap 引导（v0.2.6 ADR-014）；
- 统一响应体 ApiResult、分页响应 PageResult、全局异常处理体系位于 common 公共模块；
- API 路径统一规范 `/api/v1/{service}/{resource}`，SpringDoc OpenAPI 文档分组按服务划分；
- 健康检查端点路径 `/api/v1/{service}/health` 加入网关 AuthFilter 白名单。

## 5. 用户输入（本次需求原文）

1. cloudoffice-common 不仅包括公共的函数、变量定义，也包括公用的接口，因此也需要和其他微服务一样提供 api 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本，部署文档和 readme.md，deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理。统一配置不同微服务、不同业务场景下的所有配置工作。除去启动的环境变量外，所有需要的配置，都通过通用配置管理配置。
5. 当前这个任务只是配置的查询接口，后端管理后面会增加。

## 6. 编码约束

- 任务类型 common → 编码由 SSE subagent 执行；
- 只写本任务对应代码文件，禁止越界写其他任务文件；
- 写版本目录共享文档前必须先读最新内容再合并写回；
- 保留公共 jar 模块能力，确保 gateway/auth/biz/system 对 common 的 Maven 依赖关系不被破坏；
- 本任务仅交付通用配置管理查询接口，增删改接口与后端管理界面在后续版本迭代。
