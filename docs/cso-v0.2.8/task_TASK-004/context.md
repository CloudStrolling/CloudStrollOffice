# TASK-004 编码上下文（context.md）

## 一、任务信息
- **任务编号**：TASK-004
- **任务名称**：通用配置管理查询接口（ConfigController/ConfigService/ConfigCacheManager/ConfigMapper）
- **任务类型**：common（SSE subagent 负责编码）
- **用户故事**：US-002（通过通用配置管理接口查询运行时配置）
- **关联接口**：API-035（GET /api/v1/common/config）、API-036（GET /api/v1/common/config/{serviceName}）
- **上下游依赖**：上游 TASK-001、TASK-002（已完成）；下游 TASK-007
- **优先级**：P0
- **测试方法**：单元测试 + 接口测试

## 二、需求上下文（来自 PRD v0.2.8 与用户输入）

### 2.1 用户输入（$ARGUMENTS 原文要点）
1. cloudoffice-common 不仅包括公共的函数、变量定义，也包括公用的接口，因此也需要和其他微服务一样提供 API 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本、部署文档、readme.md、deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理，统一配置不同微服务、不同业务场景下的所有配置工作；除去启动的环境变量外，所有需要的配置都通过通用配置管理配置。
5. 当前这个任务只是配置的查询接口，后端管理界面后面会增加。

### 2.2 本任务功能范围（F-003 通用配置管理-查询接口）
- 在 cloudoffice-common 中实现通用配置管理**查询接口**：
  - `GET /api/v1/common/config`：按 serviceName/group/key 过滤 + page/pageSize 分页（API-035）；
  - `GET /api/v1/common/config/{serviceName}`：按微服务名称查询不分页（API-036）。
- **ConfigService** 核心编排：缓存优先（Redis，命中 ≤50ms）→ 未命中回源数据库 t_common_config 并回填缓存（TTL 300s）→ 敏感配置脱敏。
- **ConfigCacheManager**：管理以 serviceName 为粒度的缓存读写与失效。
- **ConfigMapper**：按条件/按服务名查询。
- **serviceName 合法性校验**：合法取值 gateway/auth-service/biz-service/system-service/common，非法返回 400。
- **敏感配置脱敏**：sensitive=1 的配置项脱敏为掩码（默认 `****`，可由 common 配置 `sensitive-mask` 覆盖）。
- **仅实现查询**，接口层 RESTful 与数据层预留 POST/PUT/DELETE 扩展点（不实现写入）。
- **验收标准**：API-035/API-036 支持按服务名/分组/键过滤与分页查询，返回统一 ApiResult；缓存命中 ≤50ms、未命中回源回填；敏感配置脱敏不暴露明文；serviceName 非法返回 400、结果为空返回 200 空列表、存储异常返回 500；不实现任何写入接口。

## 三、架构上下文（SAD v0.2.8）
- **common 服务化（ADR-017）**：cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务，端口 **9300**，服务名 `cloudoffice-common`，注册到 Nacos，引入 `spring-cloud-starter-bootstrap`。
- **通用配置管理（ADR-018）**：配置查询经网关 AuthFilter 认证（非白名单端点）；配置数据优先命中 Redis 本地缓存（≤50ms），未命中回源数据库 t_common_config 并回填；敏感配置脱敏。
- **组件划分**：CommonApplication（启动类）、HealthController、ConfigController、ConfigService、ConfigMapper（MyBatis-Plus）、ConfigCacheManager（Redis 缓存）、公共模块 jar（ApiResult/PageResult/异常体系）。
- **技术栈**：Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + MyBatis-Plus 3.5.6 + SpringDoc 2.5.0 + Hutool 5.8.26 + Lombok；Redis Lettuce 连接池（common max-active 8）；common HikariCP（maximum-pool-size 10、minimum-idle 2）。
- **统一响应**：ApiResult<T>（code/message/data/timestamp）、PageResult<T>（records/total/page/pageSize）、29 个统一错误码、全局异常处理（@RestControllerAdvice）。
- **接口路径规范**：`/api/v1/common/{resource}`。

## 四、接口契约（API v0.2.8）
### API-035 GET /api/v1/common/config
- 请求参数（query）：serviceName（可选）、group（可选）、key（可选，精确匹配）、page（默认1）、pageSize（默认10）。
- 响应：`ApiResult<PageResult<ConfigItemVO>>`。
- ConfigItemVO 字段：id(long)、serviceName、group、key、value（敏感脱敏为掩码）、dataType(string/number/boolean/json)、description、sensitive(boolean)、status(0-启用/1-禁用)、createTime、updateTime。
- 错误码：400（serviceName 非法）、401（未授权）、500（配置存储异常）。

### API-036 GET /api/v1/common/config/{serviceName}
- 请求参数（path）：serviceName（必填）。
- 响应：`ApiResult<List<ConfigItemVO>>`（不分页）。
- 指定微服务无配置项时返回空列表（code=200）。
- 错误码：400（serviceName 非法）、401（未授权）、500（配置存储异常）。

## 五、数据层上下文（DBD v0.2.8 t_common_config）
- 表 `t_common_config`：id（自增主键）、serviceName、group、key、value、dataType、description、sensitive（0/1）、status（0-启用/1-禁用）、createTime、updateTime、逻辑删除标记。
- 数据覆盖 gateway/auth-service/biz-service/system-service/common 五个微服务运行时配置；启动环境变量不纳入。

## 六、编码约束
- 只写本任务对应代码文件（cloudoffice-common 模块 ConfigController/ConfigService/ConfigCacheManager/ConfigMapper 等），不越界修改其他服务代码。
- 接口层与数据层预留 POST/PUT/DELETE 扩展点，但不实现写入。
- 不实现任何写入接口、不提供后端管理界面。
- 不得破坏现有 gateway/auth/biz/system 对 common 公共模块的 Maven 依赖关系。
- 日志禁止输出密码与 Token。
- 代码风格遵循项目现有约定（Lombok、Hutool、MyBatis-Plus、统一 ApiResult）。
