# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.1.0
**日期：** 2026-06-18

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.0 | 2026-06-18 | 初始版本，定义微服务项目基础骨架搭建需求 | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序，旨在为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。

当前项目处于从零搭建的初始阶段，需要首先完成微服务项目的基础架构搭建，包括 Maven 多模块骨架、公共组件、API 网关、认证服务和各业务服务的骨架模块，为后续业务功能的开发奠定基础。

### 1.2 业务痛点

1. **无统一技术底座：** 项目从零起步，缺乏统一的 Maven 多模块项目结构，各模块依赖版本管理混乱
2. **缺乏公共组件：** 缺少统一的响应封装、异常处理和基础实体类，各模块各自实现将导致代码冗余和不一致
3. **无服务治理基础：** 缺少服务注册发现、网关路由、统一认证等微服务基础设施
4. **开发规范不统一：** 缺少统一的代码风格、包结构、命名规范约束

### 1.3 项目目标

1. 搭建标准化的 Maven 多模块微服务项目骨架
2. 完成公共通用组件的封装和集成
3. 搭建 API 网关作为统一入口
4. 搭建认证服务基础骨架
5. 搭建各业务服务骨架模块
6. 同步生成 IDEA 配置和开发脚本模板

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.1.0 版本的开发，覆盖微服务项目骨架搭建的全部需求范围。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 |
|------|------|
| 后端开发工程师 | 负责微服务模块的开发和维护 |
| 系统架构师 | 负责整体技术架构设计和规范制定 |
| DevOps 工程师 | 负责项目构建、部署和运维 |

### 2.2 系统上下文

本阶段为基础设施搭建阶段，不涉及具体的业务功能实现。系统上下文如下：

```
[开发者/IDE] ──▶ [Maven 多模块项目]
                      ├── cloudoffice-common        (公共模块)
                      ├── cloudoffice-gateway        (API 网关)
                      ├── cloudoffice-auth-service   (认证服务)
                      ├── cloudoffice-biz-service    (企业服务)
                      ├── cloudoffice-cloud-service  (云服务)
                      └── cloudoffice-system-service (系统服务)
                      ├── scripts/                   (脚本模板)
                      └── .idea/                     (IDEA 配置)
                             │
                             ▼
                      [Nacos 注册中心/配置中心]
                             │
                             ▼
                      [MariaDB / Redis 等中间件]
```

---

## 3. 功能需求

### FR-001: Maven 多模块项目骨架搭建

- **描述：** 创建顶层父 POM 及 6 个子模块的 Maven 项目结构。父 POM 通过 `<dependencyManagement>` 统一管理所有第三方依赖版本，子模块正确继承父 POM，确保项目在 IDEA 中可正常导入和编译。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 父 POM 文件 `pom.xml` 位于项目根目录，定义项目坐标 `org.cloudstrolling:cloudoffice`，版本号 `0.0.1-SNAPSHOT`
  2. 父 POM 通过 `<dependencyManagement>` 统一管理以下依赖版本：Spring Boot 3.2.5、Spring Cloud 2023.0.1、Spring Cloud Alibaba 2023.0.1.0、MyBatis-Plus 3.5.6、Hutool 5.8.26、SpringDoc 2.5.0、Lombok 1.18.32 等（详见依赖版本汇总表）
  3. 父 POM 通过 `<modules>` 聚合 6 个子模块：`cloudoffice-common`、`cloudoffice-gateway`、`cloudoffice-auth-service`、`cloudoffice-biz-service`、`cloudoffice-cloud-service`、`cloudoffice-system-service`
  4. 各子模块的 `pom.xml` 正确声明 `<parent>` 指向父 POM，子模块中不出现硬编码的版本号
  5. 使用 `mvn clean compile` 命令可正常编译整个项目，无报错
  6. 项目在 IntelliJ IDEA 中可正常导入，模块结构完整显示

### FR-002: 公共模块通用组件

- **描述：** 在 `cloudoffice-common` 模块中提供所有微服务共享的通用组件，包括统一响应体、通用异常体系、基础实体类、通用工具类、SpringDoc 配置等。此模块不依赖任何业务模块，作为纯依赖被其他模块引用。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **统一响应体 `ApiResult<T>`（或 `R<T>`）：**
     - 包含字段：`code`（状态码，Integer）、`message`（提示信息，String）、`data`（数据，泛型 T）、`timestamp`（时间戳，Long）
     - 提供静态工厂方法：`success()`、`success(T data)`、`error(String message)`、`error(Integer code, String message)`
  2. **通用异常体系：**
     - 定义 `BaseException` 抽象基类，继承 `RuntimeException`，包含 `code` 和 `message` 字段
     - 定义 `BusinessException` 业务异常类
     - 定义全局异常处理器 `GlobalExceptionHandler`，使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一拦截处理异常，返回 `ApiResult` 格式
     - 定义各模块的错误码枚举（AUTH、BIZ、CLOUD、SYS、COMMON 错误码段）
  3. **基础实体类 `BaseEntity`：**
     - 包含公共字段：`id`（主键，Long，雪花算法生成）、`createTime`（LocalDateTime，创建时间）、`updateTime`（LocalDateTime，更新时间）、`deleted`（Integer，逻辑删除标志，0-正常，1-删除）
     - 使用 MyBatis-Plus 注解（`@TableId`、`@TableLogic`、`@TableField`）
  4. **通用工具类：**
     - 至少提供字符串工具、集合工具、日期时间工具等通用方法封装
     - 工具类使用 `final class` + 私有构造器模式
  5. **SpringDoc 配置类：**
     - 提供 OpenAPI 3 配置（`@OpenAPIDefinition`），包含项目基本信息、联系人信息
     - 配置分组支持（按模块分组）

### FR-003: API 网关基础配置

- **描述：** 搭建 `cloudoffice-gateway` 模块，集成 Spring Cloud Gateway + Nacos 服务发现，配置基本路由转发规则和 CORS 跨域支持。作为微服务架构的统一入口，负责请求路由分发。
- **优先级：** 高 (Must)
- **验收标准：**
  1. gateway 模块可正常启动，监听端口 9000
  2. 集成 Nacos 服务发现（`spring.cloud.nacos.discovery`），启动后可在 Nacos 控制台看到服务实例
  3. 配置基础路由规则，支持将请求按路径前缀转发到对应服务（如 `/api/v1/auth/**` → auth-service）
  4. 配置全局 CORS 策略，支持跨域请求
  5. 配置 `bootstrap.yml`，从 Nacos 配置中心加载配置
  6. 配置拦截器或过滤器链路（至少预留扩展点）

### FR-004: 认证服务骨架搭建

- **描述：** 搭建 `cloudoffice-auth-service` 模块，集成 Spring Security + OAuth2 骨架，提供 JWT 令牌生成和校验工具类。作为统一认证中心，为后续登录认证、单点登录（SSO）功能提供基础。
- **优先级：** 中 (Should)
- **验收标准：**
  1. auth-service 可正常启动，监听端口 9100
  2. 集成 Nacos 服务发现，启动后在 Nacos 控制台可见
  3. 集成 Spring Security 基本配置（安全配置类 `SecurityConfig`）
  4. OAuth2 授权服务器骨架配置（授权模式预留）
  5. 提供 JWT 工具类 `JwtUtils`：支持令牌生成（含用户信息）、令牌解析、令牌校验、支持 HS256/RS256 算法
  6. 提供加密工具类（BCrypt 密码编码器集成）
  7. 配置 `bootstrap.yml` 从 Nacos 加载配置

### FR-005: 企业服务骨架搭建

- **描述：** 搭建 `cloudoffice-biz-service` 模块，创建标准的 Spring Boot 应用骨架，集成 Nacos 服务发现，建立标准的包结构（config、controller、service、mapper、entity、dto、vo、enums、exception、filter、interceptor、util）。作为企业信息管理、人事管理等业务模块的承载服务。
- **优先级：** 中 (Should)
- **验收标准：**
  1. biz-service 可正常启动，监听端口 9200
  2. 集成 Nacos 服务发现，启动后在 Nacos 控制台可见
  3. 按照规范建立完整的包目录结构
  4. 配置 `bootstrap.yml` 从 Nacos 加载配置
  5. 提供一个测试端点（如 `/api/v1/biz/health`）验证服务可正常访问

### FR-006: 云服务骨架搭建

- **描述：** 搭建 `cloudoffice-cloud-service` 模块，创建标准的 Spring Boot 应用骨架，集成 Nacos 服务发现，建立标准的包结构。作为云资源管理、资源编排等业务模块的承载服务。
- **优先级：** 中 (Should)
- **验收标准：**
  1. cloud-service 可正常启动，监听端口 9300
  2. 集成 Nacos 服务发现，启动后在 Nacos 控制台可见
  3. 按照规范建立完整的包目录结构
  4. 配置 `bootstrap.yml` 从 Nacos 加载配置
  5. 提供一个测试端点（如 `/api/v1/cloud/health`）验证服务可正常访问

### FR-007: 系统服务骨架搭建

- **描述：** 搭建 `cloudoffice-system-service` 模块，创建标准的 Spring Boot 应用骨架，集成 Nacos 服务发现，建立标准的包结构。作为系统配置、日志、监控、定时任务等公共服务模块的承载服务。
- **优先级：** 中 (Should)
- **验收标准：**
  1. system-service 可正常启动，监听端口 9400
  2. 集成 Nacos 服务发现，启动后在 Nacos 控制台可见
  3. 按照规范建立完整的包目录结构
  4. 配置 `bootstrap.yml` 从 Nacos 加载配置
  5. 提供一个测试端点（如 `/api/v1/system/health`）验证服务可正常访问

### FR-008: IDEA 配置文件与开发环境最佳实践

- **描述：** 生成 `.idea/` 目录下的 IntelliJ IDEA 统一配置文件，包括代码风格配置、运行配置、Checkstyle 配置、Alibaba Java Coding Guidelines 配置等，确保所有开发者使用统一的开发环境配置。
- **优先级：** 低 (Could)
- **验收标准：**
  1. 提供 IDEA 代码风格配置文件（Google Style 或 Alibaba 规范风格），缩进 4 空格、UTF-8 编码、120 字符行宽
  2. 提供各模块的 Spring Boot 运行配置（Run Configuration）
  3. 提供 Checkstyle 配置文件，匹配 Alibaba Java 开发规范
  4. 提供 `.editorconfig` 配置文件

### FR-009: 脚本与 Docker 模板

- **描述：** 在 `scripts/` 目录下提供 Docker 部署模板和数据库初始化脚本模板，为后续容器化部署和数据库初始化做准备。
- **优先级：** 低 (Could)
- **验收标准：**
  1. `scripts/docker/` 目录包含各服务的 Dockerfile 模板
  2. `scripts/docker/` 目录包含 `docker-compose.yml` 基础模板（含 Nacos、MariaDB、Redis 等中间件）
  3. `scripts/sql/` 目录包含数据库初始化脚本模板（包含基础表结构示例）

---

## 4. 非功能需求

### NFR-001: 可用性

- **描述：** 系统基础骨架在开发环境下应能快速启动和正常运行，保证开发效率。
- **指标：**
  - 单个微服务模块从启动到可提供服务的时间 ≤ 30 秒
  - 各服务模块在 Nacos 注册成功后，网关能正确识别并路由

### NFR-002: 可维护性

- **描述：** 项目代码应具有良好的可读性、一致性和可维护性，降低团队协作成本。
- **指标：**
  - 代码遵循《阿里巴巴 Java 开发手册》规范
  - 所有类、方法、变量使用规范的命名方式（见 project.md 命名规范）
  - 使用 Lombok 减少样板代码
  - 统一使用构造器注入替代 `@Autowired` 字段注入

### NFR-003: 可扩展性

- **描述：** 微服务架构应支持独立部署和水平扩展，新增业务服务时只需新建模块并按规范接入即可。
- **指标：**
  - 新增微服务模块时，只需添加子模块并继承父 POM，无需修改其他模块代码
  - 各服务模块无直接代码依赖，仅通过 API 或消息队列通信
  - 网关路由配置支持动态添加新服务的路由规则

### NFR-004: 构建效率

- **描述：** Maven 构建过程应高效稳定，支持增量编译和多模块并行构建。
- **指标：**
  - 全项目首次完整编译时间 ≤ 120 秒
  - 单模块增量编译时间 ≤ 10 秒
  - Maven 构建过程无 Warning 报错

### NFR-005: 代码规范一致性

- **描述：** 所有模块使用统一的代码风格、包结构和命名规范。
- **指标：**
  - 所有模块使用相同的包结构模板（config、controller、service、mapper、entity、dto、vo 等）
  - 包命名遵循 `org.cloudstrolling.cloudoffice.{module}` 规范
  - 遵循 Conventional Commits 提交规范

---

## 5. 技术栈选型

### 5.1 核心框架

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| JDK | OpenJDK | 21 (LTS) | 长期支持版本，支持虚拟线程、模式匹配等新特性 |
| Spring Boot | Spring Boot | 3.2.5 | 应用框架基础 |
| Spring Cloud | Spring Cloud | 2023.0.1 | 微服务框架 |
| Spring Cloud Alibaba | Spring Cloud Alibaba | 2023.0.1.0 | 阿里巴巴微服务套件 |
| 构建工具 | Maven | 3.9.x | 项目构建与依赖管理 |

### 5.2 中间件

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 注册中心 | Nacos | 2.3.x | 服务注册与发现（本期必须可用） |
| 配置中心 | Nacos | 2.3.x | 统一配置管理（本期必须可用） |
| API 网关 | Spring Cloud Gateway | 内嵌 | 本期使用 Spring Cloud Gateway，后续可引入 APISIX |
| 数据库 | MariaDB | 10.6 (LTS) | 关系型数据库（本期预留，非必须连接） |
| 缓存 | Redis | 7.2.x | 高性能内存缓存（本期预留） |
| 消息队列 | RocketMQ | 5.1.x | 分布式消息中间件（本期预留） |

### 5.3 开发框架与组件

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| ORM 框架 | MyBatis-Plus | 3.5.6 | 增强型 MyBatis 框架 |
| 认证授权 | Spring Security + JWT + OAuth2 | - | 单点登录认证（本期搭建骨架） |
| API 文档 | SpringDoc (OpenAPI 3) | 2.5.0 | RESTful API 文档 |
| 连接池 | HikariCP | 5.x | 高性能 JDBC 连接池 |
| 工具库 | Hutool | 5.8.26 | Java 工具类库 |
| JSON 处理 | Jackson | 2.16.x | JSON 序列化/反序列化 |
| 代码简化 | Lombok | 1.18.32 | 减少样板代码 |

---

## 6. 约束条件

### 6.1 技术约束

1. **JDK 版本：** 必须使用 Java 21 (OpenJDK 21 LTS)，不得使用更低版本
2. **构建工具：** 必须使用 Maven 3.9.x 进行项目构建
3. **注册中心：** 必须集成 Nacos 2.3.x 作为服务注册中心和配置中心
4. **数据库：** 使用 MariaDB 10.6 (LTS) 作为关系型数据库
5. **Spring 版本：** 必须使用 Spring Boot 3.2.x + Spring Cloud 2023.x
6. **包命名：** 统一使用 `org.cloudstrolling.cloudoffice.{module}` 包命名空间
7. **模块命名：** 统一使用 `cloudoffice-{module}` 模块命名格式

### 6.2 规范约束

1. **代码规范：** 严格遵守《阿里巴巴 Java 开发手册》
2. **提交规范：** 遵循 Conventional Commits 规范
3. **接口规范：** API 路径遵循 `/api/v1/{module}/{resource}` RESTful 风格
4. **数据库规范：** 每张表包含 `create_time`、`update_time`、`deleted` 公共字段，主键使用雪花算法

### 6.3 环境约束

1. 开发环境：IntelliJ IDEA（推荐 2023.x 及以上版本）
2. 操作系统：Windows / macOS / Linux 均可
3. 版本控制：Git

---

## 7. 假设与依赖

### 7.1 外部依赖

1. **Nacos 服务：** 开发环境中需要部署并运行 Nacos 2.3.x 服务（单机模式可满足开发需求）
2. **MariaDB 服务：** 后续阶段需要使用，本期为预留状态
3. **Redis 服务：** 后续阶段需要使用，本期为预留状态
4. **RocketMQ 服务：** 后续阶段需要使用，本期为预留状态

### 7.2 环境假设

1. 开发人员本地已安装 JDK 21（OpenJDK 21 LTS）
2. 开发人员本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. 开发人员本地已安装 IntelliJ IDEA（推荐 Ultimate 版）
4. 开发人员本地已安装 Git 客户端
5. 所有开发人员具备 Java 微服务开发经验
6. Nacos 服务的地址默认为 `127.0.0.1:8848`，可通过环境变量 `NACOS_SERVER_ADDR` 覆盖

### 7.3 项目假设

1. 本期 v0.1.0 仅搭建骨架，不实现具体业务功能
2. 所有模块的数据库连接为可选配置，无数据库也可正常启动
3. 开发阶段默认使用 `dev` 环境配置，通过 Nacos 命名空间隔离

---

## 8. 优先级汇总 (MoSCoW)

| 优先级 | 需求编号 | 需求名称 |
|--------|----------|----------|
| **Must (必须有)** | FR-001 | Maven 多模块项目骨架搭建 |
| **Must (必须有)** | FR-002 | 公共模块通用组件 |
| **Must (必须有)** | FR-003 | API 网关基础配置 |
| **Should (应该有)** | FR-004 | 认证服务骨架搭建 |
| **Should (应该有)** | FR-005 | 企业服务骨架搭建 |
| **Should (应该有)** | FR-006 | 云服务骨架搭建 |
| **Should (应该有)** | FR-007 | 系统服务骨架搭建 |
| **Could (可以有)** | FR-008 | IDEA 配置文件与开发环境最佳实践 |
| **Could (可以有)** | FR-009 | 脚本与 Docker 模板 |

---

## 9. 模块间依赖关系

```
cloudoffice-common (无依赖)
       ▲
       │ 依赖
       │
┌──────┴──────┬──────────┬──────────┬──────────────┐
│             │          │          │              │
▼             ▼          ▼          ▼              ▼
gateway   auth-service  biz-service  cloud-service  system-service
(依赖       (依赖         (依赖        (依赖           (依赖
 common)    common)      common)     common)        common)
```

- **common 模块：** 基础模块，无其他模块依赖
- **gateway 模块：** 依赖 common，通过 Nacos 发现其他服务
- **auth-service 模块：** 依赖 common
- **biz-service 模块：** 依赖 common
- **cloud-service 模块：** 依赖 common
- **system-service 模块：** 依赖 common

> **注意：** 各业务服务模块之间无直接代码依赖，服务间通信通过 OpenFeign（同步）或 RocketMQ（异步）实现，不在本期搭建范围内。

---

## 10. 验收总体标准

1. 所有 Must 优先级需求必须全部完成并通过验收
2. 所有 Should 优先级需求应在资源允许的情况下尽量完成
3. Could 优先级需求可根据实际进度酌情调整
4. 项目通过 `mvn clean compile` 编译无错误
5. 各服务模块均可在本地开发环境中正常启动
6. 所有模块在 Nacos 注册中心中可见
