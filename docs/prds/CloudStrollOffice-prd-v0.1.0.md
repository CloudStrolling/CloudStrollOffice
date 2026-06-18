# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.0
**日期：** 2026-06-18

---

## 1. 产品概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 微服务技术栈构建的企业管理平台。当前项目处于从零搭建的初始阶段，需要首先完成微服务项目的基础架构搭建，包括 Maven 多模块骨架、公共组件、API 网关、认证服务和各业务服务的骨架模块，为后续业务功能的开发奠定基础，解决传统企业管理软件单体架构笨重、扩展困难、技术栈陈旧的问题。

### 1.2 产品目标

- 搭建基于微服务架构的企业管理平台基础骨架，实现服务解耦与独立部署，完成 Maven 多模块项目结构、公共通用组件封装和 API 网关统一入口
- 统一技术栈和中间件选型（Spring Boot 3.2.x、Spring Cloud 2023.x、Nacos、MariaDB、Redis 等），降低维护成本，提升开发效率
- 搭建认证服务骨架和各业务服务（企业服务、云服务、系统服务）骨架模块，为后续业务功能（人事管理、工作流审批、薪酬管理等）提供可扩展的基础设施

### 1.3 核心设计理念

- **微服务优先**：每个业务域独立为服务，通过 API 网关统一入口，支持独立开发、测试、部署和扩展
- **统一治理**：通过 Nacos 统一注册发现与配置管理，父 POM 统一管理所有第三方依赖版本，子模块无硬编码版本号
- **规范驱动**：从项目起始阶段就建立统一的代码风格、包结构、命名规范和错误处理体系，确保团队协作一致性

### 1.4 术语表（Glossary）

| 术语 | 英文 | 定义 |
|------|------|------|
| 云漫智企 | CloudStrollOffice | 基于微服务架构的企业综合管理平台 |
| 公共模块 | Common Module | 提供统一响应体、通用异常、基础实体、工具类等共享组件的模块，所有业务服务的公共依赖 |
| API 网关 | API Gateway | 基于 Spring Cloud Gateway 的统一入口，负责请求路由转发、CORS 跨域支持 |
| 认证服务 | Auth Service | 负责用户认证、授权、OAuth2 骨架、JWT 令牌管理的统一认证服务 |
| 企业服务 | Biz Service | 负责企业信息管理、人事管理、工作流审批等业务模块的承载服务 |
| 云服务 | Cloud Service | 负责云资源管理与资源编排等业务模块的承载服务 |
| 系统服务 | System Service | 负责系统配置、日志管理、监控告警、定时任务等公共服务模块的承载服务 |
| Nacos | Nacos | 阿里巴巴开源的动态服务发现、配置管理平台，本阶段作为注册中心和配置中心使用 |

---

## 2. 目标用户

| 用户角色 | 使用场景 | 核心诉求 |
|---------|---------|---------|
| 后端开发工程师 | 在微服务骨架基础上进行业务功能开发 | 框架清晰、规范统一、开箱即用的公共组件 |
| 系统架构师 | 设计和维护微服务架构，制定技术规范 | 模块化架构、统一治理、可观测性、可扩展性 |
| DevOps 工程师 | 部署和维护服务集群，管理 CI/CD 流程 | 容器化部署模板、配置中心管理、环境一致性 |

---

## 3. 用户故事（User Stories）

### US-001: Maven 多模块项目骨架搭建

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-001（Maven 多模块项目骨架搭建）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 搭建 Maven 多模块项目骨架，父 POM 通过 `<dependencyManagement>` 统一管理所有第三方依赖版本，6 个子模块正确继承父 POM
- **以便** 项目可在 IDEA 中正常导入和编译，各模块依赖版本统一管理，消除版本冲突风险

#### 前置条件
1. 本地已安装 JDK 21（OpenJDK 21 LTS）
2. 本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. 本地已安装 IntelliJ IDEA（推荐 2023.x 及以上版本）
4. Git 仓库已初始化，项目根目录已创建

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given 父 POM 和所有子模块 POM 已创建，When 在项目根目录执行 `mvn clean compile`，Then 整个项目编译成功，控制台输出 `BUILD SUCCESS`，无错误和 Warning
- [ ] **AC2：** Given 父 POM 已通过 `<dependencyManagement>` 定义所有依赖版本（Spring Boot 3.2.5、Spring Cloud 2023.0.1 等），When 查看各子模块的 `pom.xml`，Then 所有第三方依赖均未出现硬编码版本号，版本号统一引用父 POM 管理
- [ ] **AC3：** Given IDEA 已通过 Import Project 导入项目，When 查看 Project 面板中的模块结构，Then 正确显示 6 个子模块（`cloudoffice-common`、`cloudoffice-gateway`、`cloudoffice-auth-service`、`cloudoffice-biz-service`、`cloudoffice-cloud-service`、`cloudoffice-system-service`），模块图标正常

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 本地 JDK 版本低于 21 | Maven 编译失败，提示 `java.lang.UnsupportedClassVersionError` 或 `source/target 版本不支持` |
| 子模块未正确声明 `<parent>` 或 parent 坐标错误 | Maven 编译报错 `Non-resolvable parent POM`，提示找不到父 POM |
| 依赖版本在 `<dependencyManagement>` 中遗漏 | Maven 使用默认版本或编译报错 `DependencyResolutionException`，需补充版本声明 |
| Maven 本地仓库缓存冲突 | 执行 `mvn clean compile -U` 强制更新快照依赖后重试 |

#### 交付物
- `pom.xml` — 项目根目录父 POM（定义坐标 `org.cloudstrolling:cloudoffice:0.0.1-SNAPSHOT`，含 `<dependencyManagement>` 和 `<modules>`）
- `cloudoffice-common/pom.xml` — 公共模块 POM
- `cloudoffice-gateway/pom.xml` — API 网关模块 POM
- `cloudoffice-auth-service/pom.xml` — 认证服务模块 POM
- `cloudoffice-biz-service/pom.xml` — 企业服务模块 POM
- `cloudoffice-cloud-service/pom.xml` — 云服务模块 POM
- `cloudoffice-system-service/pom.xml` — 系统服务模块 POM

#### 备注
- 父 POM 坐标：`org.cloudstrolling:cloudoffice`，版本 `0.0.1-SNAPSHOT`
- 需在 `<dependencyManagement>` 中统一管理的核心版本包括：Spring Boot 3.2.5、Spring Cloud 2023.0.1、Spring Cloud Alibaba 2023.0.1.0、MyBatis-Plus 3.5.6、Hutool 5.8.26、SpringDoc 2.5.0、Lombok 1.18.32
- 子模块 `<parent>` 需正确声明 relativePath（`../pom.xml`），确保继承链正确

---

### US-002: 公共模块通用组件

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-002（公共模块通用组件）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 在 `cloudoffice-common` 模块中封装统一响应体 `ApiResult<T>`、通用异常体系、基础实体类 `BaseEntity`、SpringDoc 配置和通用工具类
- **以便** 所有业务服务模块可复用公共组件，保证响应格式统一、异常处理一致，减少重复开发

#### 前置条件
1. US-001（Maven 多模块骨架）已完成，common 子模块 POM 已创建
2. 父 POM 中已声明 MyBatis-Plus、SpringDoc、Lombok、Hutool、Jackson 等依赖版本
3. 包命名空间已确认为 `org.cloudstrolling.cloudoffice.common`

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given common 模块已引入其他服务模块作为依赖，When 在业务 Controller 中调用 `ApiResult.success(data)` 返回响应，Then 客户端收到的 JSON 中包含 `code`（200）、`message`（"操作成功"）、`data`（泛型数据）、`timestamp`（当前时间戳）四个字段
- [ ] **AC2：** Given `GlobalExceptionHandler` 已通过 `@RestControllerAdvice` 注册，When 业务代码抛出 `BusinessException("BIZ-0001", "企业信息不存在")`，Then 全局异常处理器捕获并返回 HTTP 400 状态码 + `ApiResult` 格式错误体，其中 `code` 为 `14001`、`message` 为 "企业信息不存在"
- [ ] **AC3：** Given 实体类继承 `BaseEntity`，When 使用 MyBatis-Plus 插入数据，Then 自动填充 `id`（雪花算法）、`createTime`（当前时间）、`updateTime`（当前时间）、`deleted`（0-正常），无需手动赋值
- [ ] **AC4：** Given SpringDoc 配置类已定义分组，When 启动任意服务并访问 `http://localhost:{port}/swagger-ui.html`，Then 正确显示 OpenAPI 3 文档页面，包含项目名称、版本号和联系人信息

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 全局异常处理器遇到未注册的异常类型（如 NPE） | `GlobalExceptionHandler` 通过 `@ExceptionHandler(Exception.class)` 捕获兜底，返回 HTTP 500 + `ApiResult.error(COMMON-0001, "系统繁忙，请稍后重试")`，并打印完整堆栈日志 |
| 工具类被外部通过 `new` 实例化 | 编译期正常但 IDE 给出警告（工具类使用 `final class` + 私有构造器，通过类名静态方法调用） |
| SpringDoc 分组匹配不到任何 Controller | 文档页面显示空分组，不报错或崩溃 |
| `BaseEntity.deleted` 未设置值 | MyBatis-Plus 逻辑删除插件自动填充默认值 0 |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/model/ApiResult.java` — 统一响应体
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/BaseException.java` — 异常抽象基类
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/BusinessException.java` — 业务异常类
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/GlobalExceptionHandler.java` — 全局异常处理器
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java` — 错误码枚举（含 AUTH/BIZ/CLOUD/SYS/COMMON 分段）
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/model/BaseEntity.java` — 基础实体类（含 id、createTime、updateTime、deleted）
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/config/SpringDocConfig.java` — SpringDoc OpenAPI 3 配置
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/util/` — 通用工具类目录

#### 备注
- common 模块作为纯依赖模块，不得依赖任何业务模块
- 统一响应体 `ApiResult<T>` 中的 `code` 字段使用 Integer 类型，遵循 HTTP 状态码语义（200 成功、400 参数错误、401 未认证、403 无权限、500 服务器错误）
- 错误码分段见 project.md 规范（AUTH-0001~9999、BIZ-0001~9999、CLOUD-0001~9999、SYS-0001~9999、COMMON-0001~9999）

---

### US-003: API 网关基础配置

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-003（API 网关基础配置）

#### 故事描述
- **作为** 系统架构师
- **我想要** 搭建 `cloudoffice-gateway` 模块，集成 Spring Cloud Gateway + Nacos 服务发现，配置基本路由转发规则和 CORS 跨域支持
- **以便** 微服务架构有统一的请求入口，前端只需要与网关交互，后端服务可独立演进

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. Nacos 2.3.x 服务已启动并可访问（默认地址 `127.0.0.1:8848`）
3. US-002（common 模块）已编译完成
4. 运行网关的端口 9000 未被占用

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given Nacos 服务已启动且 gateway 的 `bootstrap.yml` 已配置 Nacos 注册中心地址，When 启动 gateway 模块，Then 服务监听端口 9000，在 Nacos 控制台「服务管理」页面可看到 `cloudoffice-gateway` 服务实例
- [ ] **AC2：** Given gateway 已启动且 auth-service、biz-service 等服务已注册到 Nacos，When 发送 GET 请求 `http://localhost:9000/api/v1/auth/health`，Then 网关正确转发请求到 auth-service 的健康检查端点并返回 200 响应
- [ ] **AC3：** Given gateway 配置了全局 CORS 策略，When 前端应用从 `http://localhost:8080` 发送跨域 OPTIONS 预检请求，Then 响应头中包含 `Access-Control-Allow-Origin: *` 或指定域名、`Access-Control-Allow-Methods: GET,POST,PUT,DELETE` 等 CORS 头部

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 请求路径匹配路由规则，但目标服务未启动 | 网关返回 HTTP 502 Bad Gateway，日志记录 `Service Unavailable` |
| 请求路径不匹配任何路由规则 | 网关返回 HTTP 404 Not Found |
| Nacos 连接失败（地址错误或服务未启动） | 网关启动失败，日志提示 `NacosRegistration failed`，排查 Nacos 地址和连通性 |
| 请求超时（上游服务响应超过 30 秒） | 网关返回 HTTP 504 Gateway Timeout |
| 跨域请求携带自定义头（如 Authorization） | CORS 策略允许自定义头，预检请求通过后正常转发 |

#### 交付物
- `cloudoffice-gateway/pom.xml` — 网关模块 POM（含 Spring Cloud Gateway、Nacos Discovery、LoadBalancer 依赖）
- `cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/GatewayApplication.java` — 网关启动类
- `cloudoffice-gateway/src/main/resources/bootstrap.yml` — 网关 Nacos 配置（注册中心、配置中心地址）
- `cloudoffice-gateway/src/main/resources/application.yml` — 网关应用配置（路由规则、CORS 策略、端口 9000）
- `cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/` — 网关配置类目录

#### 备注
- 路由规则示例：`/api/v1/auth/**` → `cloudoffice-auth-service`、`/api/v1/biz/**` → `cloudoffice-biz-service` 等
- 本阶段使用 Spring Cloud Gateway 内嵌实现，后续可根据需要引入 APISIX 作为高性能网关替代方案
- 鉴权过滤器（JWT 校验）在本期预留扩展点，具体实现在下期迭代中完成

---

### US-004: 认证服务骨架搭建

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-004（认证服务骨架搭建）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 搭建认证服务骨架，集成 Spring Security + OAuth2 基本配置，提供 JWT 令牌生成/校验工具类和 BCrypt 密码加密工具
- **以便** 后续登录认证、单点登录（SSO）和令牌鉴权功能有现成的安全基础框架

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. Nacos 2.3.x 服务已启动并可访问
3. US-002（common 模块）已编译完成，可被 auth-service 依赖
4. 运行端口 9100 未被占用

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given auth-service 的 `bootstrap.yml` 已配置 Nacos 注册中心，When 启动 auth-service 模块（端口 9100），Then 在 Nacos 控制台可看到 `cloudoffice-auth-service` 服务实例，且健康检查端点 `http://localhost:9100/api/v1/auth/health` 返回 200
- [ ] **AC2：** Given `JwtUtils` 已正确配置签名密钥和过期时间，When 调用 `JwtUtils.generateToken("U10001", "admin")`，Then 返回一个有效的 JWT 令牌字符串（格式为 `xxx.yyy.zzz`），通过 `parseToken` 可正确解析出用户 ID 为 `U10001`、用户名为 `admin`
- [ ] **AC3：** Given 使用一个过期或签名被篡改的 JWT 令牌，When 调用 `JwtUtils.validateToken(invalidToken)`，Then 抛出 `ExpiredJwtException` 或 `SignatureException`，全局异常处理器将其转换为 `ApiResult` 错误响应，`code` 为 401
- [ ] **AC4：** Given `SecurityConfig` 已配置，When 访问需要认证的端点（如 OAuth2 授权端点），Then 未提供有效令牌时返回 HTTP 401 Unauthorized 或重定向到登录页面

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| JWT 签名密钥未在配置文件中设置 | 服务启动失败，提示 `secret key must be configured`，防止使用默认弱密钥 |
| 传入 `null` 或空字符串作为令牌 | `JwtUtils` 抛出 `IllegalArgumentException`，全局异常处理器返回 400 错误 |
| JWT 令牌结构正确但签名不匹配（被篡改） | `validateToken` 抛出 `SignatureException`，返回 401，同时记录安全告警日志 |
| BCrypt 密码编码器输入 `null` 密码 | 抛出 `IllegalArgumentException` |

#### 交付物
- `cloudoffice-auth-service/pom.xml` — 认证服务 POM（含 Spring Security、OAuth2、JWT、Nacos 依赖）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/AuthApplication.java` — 启动类
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.java` — Spring Security 安全配置类
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/OAuth2Config.java` — OAuth2 授权服务器骨架配置
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/util/JwtUtils.java` — JWT 工具类（生成、解析、校验）
- `cloudoffice-auth-service/src/main/resources/bootstrap.yml` — Nacos 配置

#### 备注
- JWT 支持 HS256（对称）和 RS256（非对称）两种算法，通过配置切换
- OAuth2 授权模式本期仅为骨架预留，不实现完整的授权码流程，具体业务集成在 v0.2.0 实现
- 密码加密统一使用 BCrypt（Spring Security 内置 `BCryptPasswordEncoder`）
- 默认 JWT 过期时间：24 小时，可通过配置调整

---

### US-005: 企业服务骨架搭建

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-005（企业服务骨架搭建）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 搭建企业服务骨架模块，创建标准的 Spring Boot 应用，集成 Nacos 服务发现，建立标准的包目录结构（config、controller、service、mapper、entity、dto、vo、enums 等）
- **以便** 后续企业信息管理、人事管理等业务功能有标准化的代码组织框架，新功能开发遵循统一规范

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. Nacos 2.3.x 服务已启动并可访问
3. US-002（common 模块）已编译完成，可被 biz-service 依赖
4. 运行端口 9200 未被占用

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given biz-service 的 `bootstrap.yml` 已配置 Nacos 注册中心，When 启动 biz-service 模块（端口 9200），Then 在 Nacos 控制台可看到 `cloudoffice-biz-service` 服务实例
- [ ] **AC2：** Given biz-service 已启动，When 发送 GET 请求 `http://localhost:9200/api/v1/biz/health`，Then 返回 `ApiResult` 格式的成功响应，`data` 中包含服务状态信息
- [ ] **AC3：** Given 项目已导入 IDEA，When 展开 `cloudoffice-biz-service/src/main/java/org/cloudstrolling/cloudoffice/biz/` 目录，Then 包结构包含 `config/`、`controller/`、`service/`（含 `impl/`）、`mapper/`、`entity/`、`dto/`、`vo/`、`enums/`、`exception/`、`filter/`、`interceptor/`、`util/` 等标准目录

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Nacos 连接失败（地址错误） | 服务启动失败，日志提示 `NacosRegistration failed`，检查 Nacos 地址配置 |
| 健康检查端点内部异常 | 返回 `ApiResult.error()`，`code` 为 500，日志记录异常详情 |
| bootstrap.yml 中配置中心配置缺失 | 服务启动使用本地 `application.yml` 配置，不影响基本启动 |

#### 交付物
- `cloudoffice-biz-service/pom.xml` — 企业服务 POM（含 Nacos、Spring Boot Web、common 依赖）
- `cloudoffice-biz-service/src/main/java/org/cloudstrolling/cloudoffice/biz/BizApplication.java` — 启动类
- `cloudoffice-biz-service/src/main/resources/bootstrap.yml` — Nacos 配置
- `cloudoffice-biz-service/src/main/resources/application.yml` — 应用配置
- 标准包结构下的各目录占位文件（`.gitkeep` 或空目录）

#### 备注
- 本期仅搭建骨架，不实现具体业务功能，所有业务逻辑在后续版本迭代开发
- 企业服务是核心业务模块，后续将承载企业信息管理、部门管理、员工管理、考勤等人事功能

---

### US-006: 云服务骨架搭建

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-006（云服务骨架搭建）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 搭建云服务骨架模块，创建标准的 Spring Boot 应用，集成 Nacos 服务发现，建立标准的包目录结构
- **以便** 后续云资源管理、资源编排等业务功能有标准化的代码组织框架

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. Nacos 2.3.x 服务已启动并可访问
3. US-002（common 模块）已编译完成
4. 运行端口 9300 未被占用

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given cloud-service 的 `bootstrap.yml` 已配置 Nacos 注册中心，When 启动 cloud-service 模块（端口 9300），Then 在 Nacos 控制台可看到 `cloudoffice-cloud-service` 服务实例
- [ ] **AC2：** Given cloud-service 已启动，When 发送 GET 请求 `http://localhost:9300/api/v1/cloud/health`，Then 返回 `ApiResult` 格式的成功响应
- [ ] **AC3：** Given 项目已导入 IDEA，When 展开 `cloudoffice-cloud-service` 的包目录，Then 包结构包含 config、controller、service、mapper、entity、dto、vo、enums、exception、filter、interceptor、util 等标准目录

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Nacos 连接失败 | 日志提示 `NacosRegistration failed`，检查 Nacos 连通性 |
| 健康检查端点异常 | 返回 `ApiResult.error()` + 500 状态码 |
| 端口 9300 被占用 | 启动失败，报 `Address already in use`，更换端口或释放占用 |

#### 交付物
- `cloudoffice-cloud-service/pom.xml` — 云服务 POM
- `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/CloudApplication.java` — 启动类
- `cloudoffice-cloud-service/src/main/resources/bootstrap.yml` — Nacos 配置
- `cloudoffice-cloud-service/src/main/resources/application.yml` — 应用配置
- 标准包结构下的各目录

#### 备注
- 本期仅搭建骨架，云服务是面向云资源管理场景的业务模块，功能将在后续版本实现
- 云服务可能涉及云主机管理、存储管理、网络资源编排等业务领域

---

### US-007: 系统服务骨架搭建

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-007（系统服务骨架搭建）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 搭建系统服务骨架模块，创建标准的 Spring Boot 应用，集成 Nacos 服务发现，建立标准的包目录结构
- **以便** 后续系统配置管理、日志管理、监控告警、定时任务等公共服务功能有标准化的代码组织框架

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. Nacos 2.3.x 服务已启动并可访问
3. US-002（common 模块）已编译完成
4. 运行端口 9400 未被占用

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given system-service 的 `bootstrap.yml` 已配置 Nacos 注册中心，When 启动 system-service 模块（端口 9400），Then 在 Nacos 控制台可看到 `cloudoffice-system-service` 服务实例
- [ ] **AC2：** Given system-service 已启动，When 发送 GET 请求 `http://localhost:9400/api/v1/system/health`，Then 返回 `ApiResult` 格式的成功响应
- [ ] **AC3：** Given 项目已导入 IDEA，When 展开 `cloudoffice-system-service` 的包目录，Then 包结构包含 config、controller、service、mapper、entity、dto、vo、enums、exception、filter、interceptor、util 等标准目录

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Nacos 连接失败 | 日志提示 `NacosRegistration failed`，检查 Nacos 连通性 |
| 健康检查端点异常 | 返回 `ApiResult.error()` + 500 状态码 |
| 端口 9400 被占用 | 启动失败，报 `Address already in use` |

#### 交付物
- `cloudoffice-system-service/pom.xml` — 系统服务 POM
- `cloudoffice-system-service/src/main/java/org/cloudstrolling/cloudoffice/system/SystemApplication.java` — 启动类
- `cloudoffice-system-service/src/main/resources/bootstrap.yml` — Nacos 配置
- `cloudoffice-system-service/src/main/resources/application.yml` — 应用配置
- 标准包结构下的各目录

#### 备注
- 本期仅搭建骨架，系统服务是基础公共服务模块，后续将承载系统参数管理、操作日志、定时任务（XXL-Job 或 Spring Task）、监控等功能
- 定时任务框架选型后续决策，本期不做绑定

---

### US-008: IDEA 配置文件与开发环境最佳实践

**优先级：** 低
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-008（IDEA 配置文件与开发环境最佳实践）

#### 故事描述
- **作为** 后端开发工程师
- **我想要** 将 `.idea/` 目录下的 IDEA 统一配置文件（代码风格、运行配置、Checkstyle、EditorConfig）纳入版本管理
- **以便** 所有开发者使用一致的代码格式和运行环境配置，减少因代码风格差异导致的合并冲突

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. 已安装 IntelliJ IDEA
3. 已在 IDEA 中安装 Alibaba Java Coding Guidelines 插件和 Checkstyle-IDEA 插件

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given `.idea/codeStyles/` 目录下包含代码风格配置文件，When 开发者导入项目到 IDEA，Then 代码缩进自动为 4 空格、编码为 UTF-8、行宽限制为 120 字符
- [ ] **AC2：** Given 项目根目录包含 `.editorconfig` 文件，When 开发者使用任意编辑器（VS Code、IDEA 等）打开项目，Then 编辑器自动应用 `.editorconfig` 中的缩进和编码规则
- [ ] **AC3：** Given `.idea/runConfigurations/` 目录包含各模块的 Spring Boot 运行配置，When 开发者打开 IDEA Run/Debug 下拉菜单，Then 可看到 6 个服务的运行配置项（GatewayApplication、AuthApplication、BizApplication、CloudApplication、SystemApplication 等），一键启动和调试

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 开发者未安装 Checkstyle 插件 | IDEA 忽略 Checkstyle 配置，不影响基本开发，建议安装插件后生效 |
| `.editorconfig` 与 IDEA 配置冲突 | `.editorconfig` 优先级高于 IDEA 配置，以 `.editorconfig` 为准 |
| `.idea/` 目录被 `.gitignore` 忽略 | 需在 `.gitignore` 中放开关键配置文件路径，仅推送必要配置，排除 workspace.xml 等本地无关文件 |

#### 交付物
- `.editorconfig` — 跨编辑器代码风格配置
- `.idea/codeStyles/Project.xml` — IDEA 代码风格配置（Google Style / Alibaba 规范风格）
- `.idea/codeStyles/codeStyleConfig.xml` — 代码风格引用配置
- `.idea/runConfigurations/GatewayApplication.xml` — 网关模块运行配置
- `.idea/runConfigurations/AuthApplication.xml` — 认证服务运行配置
- `.idea/runConfigurations/BizApplication.xml` — 企业服务运行配置
- `.idea/runConfigurations/CloudApplication.xml` — 云服务运行配置
- `.idea/runConfigurations/SystemApplication.xml` — 系统服务运行配置
- `checkstyle.xml` — Checkstyle 规则文件（匹配 Alibaba Java 开发规范）

#### 备注
- `.idea/` 目录中仅提交必要的配置文件（代码风格、运行配置、检查规则），不提交 `workspace.xml`、`tasks.xml`、`usage.statistics.xml` 等本地无关文件
- `.gitignore` 需配置允许追踪核心 `.idea/` 配置文件的规则
- Checkstyle 规则文件也可放置于项目根目录，独立于 `.idea/`，方便非 IDEA 用户使用

---

### US-009: 脚本与 Docker 模板

**优先级：** 低
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.0.md`
需求编号：FR-009（脚本与 Docker 模板）

#### 故事描述
- **作为** DevOps 工程师
- **我想要** 在 `scripts/` 目录下提供 Dockerfile 部署模板、docker-compose 编排模板和数据库初始化 SQL 脚本模板
- **以便** 为后续容器化部署和数据库初始化做好准备，新开发者能通过 docker-compose 快速启动开发环境

#### 前置条件
1. US-001（Maven 多模块骨架）已完成
2. 本地开发环境已安装 Docker 和 Docker Compose（可选，模板文件本身无需运行环境）

#### 验收标准（Acceptance Criteria）
> 采用 Given-When-Then 格式，确保可测试。

- [ ] **AC1：** Given `scripts/docker/` 目录已创建，When 查看目录内容，Then 包含各微服务（gateway、auth-service、biz-service、cloud-service、system-service）的 Dockerfile 模板，使用多阶段构建方式
- [ ] **AC2：** Given `scripts/docker/docker-compose.yml` 已创建，When 查看文件内容，Then 包含 Nacos、MariaDB、Redis 等中间件的基础服务定义，以及各微服务的构建和运行配置
- [ ] **AC3：** Given `scripts/sql/` 目录已创建，When 查看目录内容，Then 包含数据库初始化脚本模板，至少包含一个基础表结构示例（如 `t_auth_user` 用户表），含 `create_time`、`update_time`、`deleted` 等公共字段

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Dockerfile 中基础镜像版本不可用 | 构建失败，需更新 Dockerfile 中的基础镜像标签 |
| docker-compose.yml 中端口冲突 | 修改 `ports` 映射，避免与本地已启动的服务端口冲突 |
| SQL 脚本中的表已存在 | 需在脚本中使用 `CREATE TABLE IF NOT EXISTS` 或先执行 `DROP TABLE IF EXISTS` |

#### 交付物
- `scripts/docker/gateway/Dockerfile` — 网关 Docker 构建模板
- `scripts/docker/auth-service/Dockerfile` — 认证服务 Docker 构建模板
- `scripts/docker/biz-service/Dockerfile` — 企业服务 Docker 构建模板
- `scripts/docker/cloud-service/Dockerfile` — 云服务 Docker 构建模板
- `scripts/docker/system-service/Dockerfile` — 系统服务 Docker 构建模板
- `scripts/docker/docker-compose.yml` — Docker Compose 编排模板（含 Nacos、MariaDB、Redis 等中间件）
- `scripts/sql/init.sql` — 数据库初始化脚本模板（含基础表结构示例）

#### 备注
- Dockerfile 使用多阶段构建（Multi-stage Build），第一阶段 Maven 编译打包，第二阶段 JRE 运行
- `docker-compose.yml` 中 Nacos 服务使用 `standalone` 单机模式，MariaDB 使用 `10.6` LTS 版本
- SQL 脚本预留各模块的数据库 `CREATE DATABASE` 语句和基础表结构，具体业务表在后续版本迭代中添加
- 本阶段的 Docker 模板为基础模板，Java 应用本身未实现业务逻辑，Dockerfile 仅为可构建的占位模板

---

## 4. 非功能性需求（Non-Functional Requirements）

### 4.1 性能

| 指标 | 目标值 | 对应需求 |
|------|--------|---------|
| 单个微服务模块启动时间 | ≤ 30 秒（从启动到可提供服务） | NFR-001 |
| 全项目首次完整 Maven 编译时间 | ≤ 120 秒 | NFR-004 |
| 单模块增量编译时间 | ≤ 10 秒 | NFR-004 |
| 各服务注册到 Nacos 后的路由识别时间 | ≤ 5 秒 | NFR-001 |

### 4.2 可用性

| 指标 | 目标值 | 对应需求 |
|------|--------|---------|
| 开发环境服务快速启动 | 各服务模块可在无数据库连接的情况下正常启动（仅打印连接失败的 WARN 日志，不阻塞启动） | NFR-001 |
| Nacos 连接容错 | Nacos 不可用时，服务启动失败须给出明确错误提示，指导开发者检查 Nacos 地址和状态 | NFR-001 |
| 文档可用性 | SpringDoc OpenAPI 3 文档可在线访问，支持 Try-it-out 在线调试（服务启动后即可使用） | NFR-002 |

### 4.3 可靠性

| 指标 | 目标值 | 对应需求 |
|------|--------|---------|
| 全局异常兜底 | 未捕获的异常类型走通用兜底处理器，返回 HTTP 500 + 友好提示，不泄露堆栈详情到客户端 | NFR-002 |
| 服务间解耦 | 各服务模块无直接代码依赖，仅通过 API 或消息队列通信，一个服务故障不影响其他服务启动和运行 | NFR-003 |
| Maven 构建稳定性 | 构建过程无 Warning 报错，依赖版本无冲突 | NFR-004 |

### 4.4 安全性

| 指标 | 目标值 | 对应需求 |
|------|--------|---------|
| 密码加密 | 所有密码存储使用 BCrypt 加密算法 | 约束条件 |
| JWT 令牌安全 | JWT 签名密钥通过配置文件 + 环境变量注入，禁止硬编码，支持 HS256/RS256 算法切换 | FR-004 |
| 敏感配置保护 | 数据库密码、JWT 密钥等敏感信息通过 Nacos 配置中心或环境变量管理，不得出现在代码库中 | 约束条件 |
| SQL 注入防护 | 使用 MyBatis-Plus 预编译机制，禁止拼接 SQL 语句 | 约束条件 |

### 4.5 可维护性

| 指标 | 目标值 | 对应需求 |
|------|--------|---------|
| 代码规范一致性 | 遵循《阿里巴巴 Java 开发手册》，统一使用构造器注入替代 `@Autowired` 字段注入 | NFR-002 / NFR-005 |
| 包结构一致性 | 所有业务服务模块使用相同的标准包结构（config、controller、service、mapper、entity、dto、vo 等） | NFR-005 |
| 命名规范一致性 | 包名 `org.cloudstrolling.cloudoffice.{module}`，模块名 `cloudoffice-{module}`，API 路径 `/api/v1/{module}/{resource}` | NFR-005 |
| 依赖管理标准化 | 所有第三方依赖版本在父 POM 中统一管理，子模块不出现硬编码版本号 | NFR-003 |
| Git 提交规范 | 遵循 Conventional Commits 规范（`feat:`、`fix:`、`docs:`、`refactor:` 等） | NFR-002 |
| 代码审查 | 统一代码风格工具（Checkstyle + Alibaba Java Coding Guidelines）自动检查代码规范 | NFR-002 |

---

## 5. 附录

### 5.1 技术栈版本汇总表

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| JDK | OpenJDK | 21 (LTS) | 长期支持版本，支持虚拟线程、模式匹配等新特性 |
| Spring Boot | Spring Boot | 3.2.5 | 应用框架基础 |
| Spring Cloud | Spring Cloud | 2023.0.1 | 微服务框架 |
| Spring Cloud Alibaba | Spring Cloud Alibaba | 2023.0.1.0 | 阿里巴巴微服务套件 |
| Maven | Maven | 3.9.x | 项目构建与依赖管理 |
| Nacos | Nacos (服务端) | 2.3.x | 服务注册发现 & 配置中心 |
| Spring Cloud Gateway | Gateway (内嵌) | 内置于 Spring Cloud | API 网关路由转发（本阶段使用） |
| MariaDB | MariaDB (服务端) | 10.6 (LTS) | 关系型数据库（本期预留） |
| Redis | Redis (服务端) | 7.2.x | 高性能缓存（本期预留） |
| RocketMQ | RocketMQ | 5.1.x | 分布式消息（本期预留） |
| MyBatis-Plus | MyBatis-Plus | 3.5.6 | ORM 框架 |
| Spring Security | Spring Security | 内置于 Spring Boot | 认证授权框架 |
| JWT | jjwt (io.jsonwebtoken) | 0.12.x | JWT 令牌生成与校验 |
| SpringDoc | springdoc-openapi | 2.5.0 | OpenAPI 3 文档生成 |
| HikariCP | HikariCP | 5.x | JDBC 连接池 |
| Hutool | Hutool | 5.8.26 | Java 工具类库 |
| Jackson | Jackson | 2.16.x | JSON 序列化/反序列化 |
| Lombok | Lombok | 1.18.32 | 减少样板代码 |

### 5.2 MoSCoW 优先级矩阵

| 优先级 | 需求编号 | US 编号 | 需求名称 |
|--------|----------|---------|----------|
| **Must (必须有)** | FR-001 | US-001 | Maven 多模块项目骨架搭建 |
| **Must (必须有)** | FR-002 | US-002 | 公共模块通用组件 |
| **Must (必须有)** | FR-003 | US-003 | API 网关基础配置 |
| **Should (应该有)** | FR-004 | US-004 | 认证服务骨架搭建 |
| **Should (应该有)** | FR-005 | US-005 | 企业服务骨架搭建 |
| **Should (应该有)** | FR-006 | US-006 | 云服务骨架搭建 |
| **Should (应该有)** | FR-007 | US-007 | 系统服务骨架搭建 |
| **Could (可以有)** | FR-008 | US-008 | IDEA 配置文件与开发环境最佳实践 |
| **Could (可以有)** | FR-009 | US-009 | 脚本与 Docker 模板 |

### 5.3 模块间依赖关系

```
cloudoffice-common (无依赖，纯工具模块)
       ▲
       │ 所有业务模块依赖 common
       │
┌──────┴──────┬──────────┬──────────┬──────────────┐
│             │          │          │              │
▼             ▼          ▼          ▼              ▼
gateway   auth-service  biz-service  cloud-service  system-service
(端口9000)  (端口9100)   (端口9200)   (端口9300)     (端口9400)
```

- **common 模块：** 基础模块，无其他模块依赖，所有业务服务模块通过 Maven 依赖引用
- **gateway 模块：** 依赖 common，通过 Nacos 服务发现将请求路由到下游服务
- **auth-service：** 依赖 common，独立认证模块
- **biz-service：** 依赖 common，企业业务模块
- **cloud-service：** 依赖 common，云资源模块
- **system-service：** 依赖 common，系统公共模块
- **各业务服务之间无直接代码依赖**，服务间通信通过 OpenFeign（同步）或 RocketMQ（异步）在后续版本中实现

### 5.4 验收总体标准

1. 所有 Must 优先级需求（US-001、US-002、US-003）必须全部完成并通过验收
2. 所有 Should 优先级需求（US-004、US-005、US-006、US-007）应在资源允许的情况下尽量完成
3. Could 优先级需求（US-008、US-009）可根据实际进度酌情调整
4. 项目通过 `mvn clean compile` 编译无错误
5. 各服务模块均可在本地开发环境中正常启动
6. 所有模块在 Nacos 注册中心中可见
7. 所有公共组件（统一响应体、异常处理、基础实体）通过单元测试验证

---

> **文档信息：**
> 本文档由 Business Analyst 根据需求文档 `CloudStrollOffice-requirement-v0.1.0.md` 生成，为 v0.1.0 骨架搭建阶段的 PRD 文档，所有用户故事面向微服务基础架构搭建，不涉及具体业务功能实现。
