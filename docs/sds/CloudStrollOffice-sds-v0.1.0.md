# 软件设计规格说明书（SDS）

**项目中文名称：** 云漫智企
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.0
**日期：** 2026-06-18

---

## 1. 技术方案概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）是一个基于 **Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x** 技术栈构建的微服务企业管理平台。v0.1.0 阶段为从零搭建的初始骨架阶段，目标是完成微服务项目的基础架构搭建，包括 Maven 多模块骨架、公共通用组件、API 网关、认证服务骨架和三个业务服务（企业服务、云服务、系统服务）骨架模块，为后续业务功能的开发奠定微服务基础设施。

**解决的问题：** 传统企业管理软件单体架构笨重、扩展困难、技术栈陈旧的问题。

### 1.2 架构风格

- **选用风格：** 微服务架构（Microservices Architecture）
- **选型理由：** 每个业务域（认证/企业/云/系统）职责清晰，天然适合微服务拆分；支持各服务独立开发、测试、部署和扩展；团队可并行开发不同服务，提升研发效率。

**架构层次图：**

```
┌─────────────────────────────────────────────────────────────────┐
│                        客户端层 (Client)                         │
│               Flutter Desktop / Mobile / Web / 第三方 API         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API 网关层 (Gateway)                          │
│                Spring Cloud Gateway（端口 9000）                   │
│              路由转发 │ CORS │ 负载均衡 │ 服务发现集成               │
└─────────────────────────────────────────────────────────────────┘
                              │
      ┌───────────────────────┼───────────────────────┐
      ▼                       ▼                       ▼
┌─────────────┐   ┌───────────────┐   ┌──────────────────┐
│  认证服务    │   │  企业服务       │   │  云服务           │
│ auth-service│   │  biz-service   │   │  cloud-service   │
│  (端口 9100) │   │  (端口 9200)   │   │  (端口 9300)     │
│ Spring Sec  │   │  企业信息/人事  │   │  云资源管理/编排   │
│ OAuth2+JWT  │   │  v0.1.0 骨架   │   │  v0.1.0 骨架     │
└─────────────┘   └───────────────┘   └──────────────────┘
      │                 │                     │
      ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                        系统服务 (system-service)                  │
│                        (端口 9400)                                │
│                 系统配置 │ 日志 │ 监控 │ 定时任务                   │
│                       v0.1.0 骨架                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
      ┌───────────────────────┼───────────────────────┐
      ▼                       ▼                       ▼
┌─────────────┐   ┌───────────────┐   ┌──────────────────┐
│ MariaDB 10.6│   │  Redis 7.2.x  │   │  RocketMQ 5.1.x  │
│  数据库层    │   │ 缓存（本期预留）│   │  消息队列（本期预留）│
└─────────────┘   └───────────────┘   └──────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                      基础设施层                                   │
│        Nacos 2.3.x (注册/配置中心) │ Docker Compose                │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 核心工作流

v0.1.0 骨架阶段的核心工作流较为简单，主要覆盖服务注册发现和健康检查链路：

```
[客户端] ──HTTP请求──▶ [API Gateway (9000)]
                          │
                          ├─ /api/v1/auth/**    ──▶ [auth-service (9100)]
                          ├─ /api/v1/biz/**     ──▶ [biz-service (9200)]
                          ├─ /api/v1/cloud/**   ──▶ [cloud-service (9300)]
                          └─ /api/v1/system/**  ──▶ [system-service (9400)]
                          │
                          ▼
                   返回 ApiResult<T> JSON 响应
```

**认证流程（下期版本完善）：**
```
[客户端] ──▶ [Gateway] ──▶ [auth-service: 登录获取JWT] ──▶ JWT令牌返回
[客户端] ──▶ [Gateway(携带JWT)] ──▶ [目标服务鉴权] ──▶ 业务响应
```

**服务注册与发现工作流：**
```
[各微服务启动] ──注册服务实例──▶ [Nacos Server (8848)]
[Gateway启动]  ──订阅服务列表──▶ [Nacos Server]
[客户端请求]   ──▶ [Gateway] ──负载均衡──▶ [目标服务实例]
```

### 1.4 关键设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **微服务优先** | 每个业务域独立为服务，通过 API 网关统一入口 | 6 个 Maven 子模块独立部署，通过 Nacos 服务发现注册 |
| **统一治理** | 依赖版本、代码风格、错误处理、配置管理统一 | 父 POM `<dependencyManagement>`、Checkstyle、统一响应体、Nacos 配置中心 |
| **规范驱动** | 从项目起始即建立统一的编码规范 | 标准包结构、构造器注入、命名规范、错误码分段 |
| **渐进演进** | v0.1.0 搭建骨架，后续版本逐步注入业务功能 | 本期不引入 Redis/RocketMQ/Seata 等重量级中间件，仅预留扩展点 |
| **防御性编程** | 全局异常兜底、参数校验、不允许泄露堆栈详情到客户端 | `@RestControllerAdvice` + `GlobalExceptionHandler` |
| **无状态设计** | 服务实例无状态，支持水平扩展 | JWT 无状态令牌，Session 信息不存储在服务本地 |

### 1.5 对应 PRD UserStory 一览

| 用户故事编号 | 技术方案覆盖章节 |
|-------------|----------------|
| US-001: Maven 多模块项目骨架搭建 | 第 2 章 模块概要设计（2.1 模块清单） |
| US-002: 公共模块通用组件 | 第 2.2 节 common 模块设计、第 4 章 接口设计（4.5 统一响应体） |
| US-003: API 网关基础配置 | 第 2.2 节 gateway 模块设计、第 4 章 接口设计（4.1 路由表） |
| US-004: 认证服务骨架搭建 | 第 2.2 节 auth-service 模块设计、第 5 章 安全设计 |
| US-005: 企业服务骨架搭建 | 第 2.2 节 biz-service 模块设计 |
| US-006: 云服务骨架搭建 | 第 2.2 节 cloud-service 模块设计 |
| US-007: 系统服务骨架搭建 | 第 2.2 节 system-service 模块设计 |
| US-008: IDEA 配置文件与开发环境最佳实践 | 第 7.3 节 开发环境配置 |
| US-009: 脚本与 Docker 模板 | 第 7.1 节 容器化部署模板 |

---

## 2. 模块概要设计

### 2.1 模块清单

| 模块编号 | 模块名称 | 模块类型 | Maven artifactId | 端口 | 功能描述 |
|---------|---------|---------|-----------------|------|---------|
| M-001 | cloudoffice-common | 公共依赖模块 | cloudoffice-common | - | 统一响应体、通用异常体系、基础实体、SpringDoc 配置、通用工具类 |
| M-002 | cloudoffice-gateway | API 网关 | cloudoffice-gateway | 9000 | 统一流量入口、路由转发、CORS 跨域、Nacos 服务发现集成 |
| M-003 | cloudoffice-auth-service | 认证服务 | cloudoffice-auth-service | 9100 | Spring Security + OAuth2 骨架、JWT 令牌工具、BCrypt 密码加密 |
| M-004 | cloudoffice-biz-service | 业务服务 | cloudoffice-biz-service | 9200 | 企业信息/人事管理业务骨架（本期仅搭建骨架） |
| M-005 | cloudoffice-cloud-service | 业务服务 | cloudoffice-cloud-service | 9300 | 云资源管理业务骨架（本期仅搭建骨架） |
| M-006 | cloudoffice-system-service | 业务服务 | cloudoffice-system-service | 9400 | 系统配置/日志/监控/定时任务骨架（本期仅搭建骨架） |

### 2.2 模块间相互关系

**依赖关系图：**

```
┌─────────────────────────────────────────────────────────────────┐
│                    cloudoffice-common                            │
│  (无业务依赖，所有服务模块的公共依赖，不含启动类，打包为 JAR)          │
│  包含: ApiResult<T>, BaseEntity, BaseException,                  │
│        BusinessException, GlobalExceptionHandler,                │
│        ErrorCode, SpringDocConfig, 工具类                        │
└─────────────────────────────────────────────────────────────────┘
                    ▲           ▲           ▲           ▲
                    │依赖       │依赖       │依赖       │依赖
                    │           │           │           │
┌───────────┐ ┌───────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐
│  gateway  │ │auth-service│ │biz-service││cloud-service││system-service│
│ (端口9000) │ │(端口9100) │ │(端口9200) ││(端口9300)  ││ (端口9400)   │
└───────────┘ └───────────┘ └──────────┘ └───────────┘ └──────────────┘
                                                    │
                                                    │ 统一注册到
                                                    ▼
                                          ┌──────────────────┐
                                          │ Nacos 注册中心    │
                                          │ (端口 8848)       │
                                          └──────────────────┘
```

**模块间关系约束：**
- **common 模块：** 纯依赖模块，无任何对外 REST 接口，不启动 Spring Boot 应用，不依赖任何业务模块
- **gateway 模块：** 依赖 common，通过 Nacos 服务发现将请求路由到下游服务，不直接依赖任何业务服务
- **各业务服务（auth/biz/cloud/system）：** 均依赖 common 模块，各服务之间无直接代码依赖
- **服务间通信：** v0.1.0 骨架阶段不需要服务间调用的业务场景，服务间通信机制（OpenFeign/RocketMQ）将在后续版本引入

**路由映射关系：**

| 路由路径 | 目标服务 | 负载均衡策略 |
|---------|---------|------------|
| `/api/v1/auth/**` | `cloudoffice-auth-service` | 轮询 |
| `/api/v1/biz/**` | `cloudoffice-biz-service` | 轮询 |
| `/api/v1/cloud/**` | `cloudoffice-cloud-service` | 轮询 |
| `/api/v1/system/**` | `cloudoffice-system-service` | 轮询 |

---

## 3. 数据设计

### 3.1 数据库选型与部署策略

| 项目 | 选型 | 说明 |
|------|------|------|
| 数据库引擎 | MariaDB 10.6 (LTS) | 完全兼容 MySQL 协议，性能更优，LTS 版本支持 5 年维护 |
| 字符集 | `utf8mb4` | 支持完整 Unicode，含 Emoji 和生僻字 |
| 排序规则 | `utf8mb4_general_ci` | 通用排序，兼顾性能与兼容性 |
| 存储引擎 | InnoDB | 支持事务、行级锁、MVCC |
| 连接池 | HikariCP 5.x | Spring Boot 默认，零额外配置 |
| ORM 框架 | MyBatis-Plus 3.5.x | 增强型 MyBatis，提供 Lambda 查询、自动填充、分页插件 |
| 分片策略 | 无（v0.1.0 无需分片） | 后续根据数据量评估 |
| 缓存 | 本期预留 | Redis 7.2.x 客户端依赖预留，不实际使用 |
| 时区 | Asia/Shanghai (UTC+8) | 应用层通过连接参数指定 |

### 3.2 数据库模式（Schema）

遵循每服务独立数据库原则，共规划 4 个数据库：

| 数据库编号 | 数据库名 | 所属服务 | 当前状态 |
|-----------|---------|---------|---------|
| DB-001 | `cloudstroll_office_auth` | 认证服务 | ✔ 本期创建（含一张基础表） |
| DB-002 | `cloudstroll_office_biz` | 企业服务 | ⏳ 预留（本期仅建库不建表） |
| DB-003 | `cloudstroll_office_cloud` | 云服务 | ⏳ 预留（本期仅建库不建表） |
| DB-004 | `cloudstroll_office_system` | 系统服务 | ⏳ 预留（本期仅建库不建表） |

### 3.3 表结构设计

#### 3.3.1 认证服务表

**表名：** `t_auth_user`

**说明：** 用户表，v0.1.0 骨架阶段的基础表结构示例，为认证服务提供用户模型。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | - | 主键 ID（雪花算法生成） |
| login_name | VARCHAR(50) | UNIQUE NOT NULL | - | 登录用户名 |
| password | VARCHAR(255) | NOT NULL | - | BCrypt 哈希加密后的密码 |
| real_name | VARCHAR(100) | - | NULL | 真实姓名 |
| email | VARCHAR(100) | UNIQUE | NULL | 电子邮箱 |
| phone | VARCHAR(20) | - | NULL | 手机号码 |
| avatar | VARCHAR(500) | - | NULL | 头像 URL |
| status | TINYINT(1) | NOT NULL | 1 | 状态：0-禁用 1-启用 |
| create_time | DATETIME(3) | NOT NULL | CURRENT_TIMESTAMP | 创建时间 |
| update_time | DATETIME(3) | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | 更新时间 |
| deleted | TINYINT(1) | NOT NULL | 0 | 逻辑删除：0-正常 1-已删除 |

**索引设计：**

| 索引名 | 类型 | 字段 | 唯一 | 说明 |
|--------|------|------|------|------|
| PRIMARY | BTREE | id | 是 | 主键索引 |
| uk_auth_user_login_name | BTREE | login_name | 是 | 登录名唯一，用于登录快速检索 |
| uk_auth_user_email | BTREE | email | 是 | 邮箱唯一，用于邮箱登录和去重 |
| idx_auth_user_status | BTREE | status | 否 | 状态索引，用于按状态筛选 |
| idx_auth_user_create_time | BTREE | create_time | 否 | 时间索引，用于时间范围查询 |

#### 3.3.2 其他服务表（预留设计）

以下表结构在 v0.1.0 阶段为预留设计，数据库仅建库不建表，物理 DDL 在后续版本创建。

- **企业服务：** `t_biz_enterprise`（企业信息表）、`t_biz_department`（部门表）、`t_biz_employee`（员工表）—— 计划 v0.2.0
- **云服务：** `t_cloud_resource`（云资源表）—— 计划 v0.3.0
- **系统服务：** `t_sys_config`（系统配置表）、`t_sys_dict`（数据字典表）、`t_sys_oper_log`（操作日志表）—— 计划 v0.2.0

> 详细表结构定义参见 `docs/dbd.md` 数据库设计文档。

### 3.4 数据库设计规范

| 类别 | 规则 |
|------|------|
| 数据库 | 每服务独立数据库，命名 `cloudstroll_office_{module}` |
| 表命名 | `t_{module}_{table_name}`（单数名词） |
| 字段命名 | 小写下划线命名法（`user_name`） |
| 主键 | 雪花算法（BIGINT），字段名统一 `id` |
| 公共字段 | 每表必须包含 `id`、`create_time`、`update_time`、`deleted`（逻辑删除） |
| 索引命名 | 普通索引 `idx_{table}_{column}`，唯一索引 `uk_{table}_{column}` |
| 禁止物理外键 | 引用关系通过应用层维护 |

### 3.5 数据流设计

v0.1.0 骨架阶段的数据流较为简单：

| 数据流 | 源 | 目标 | 方式 | 格式 | 说明 |
|--------|-----|------|------|------|------|
| 注册服务实例 | 各微服务 | Nacos Server | gRPC/HTTP | 服务元数据 | 服务启动时自动注册，心跳维持 |
| 获取服务列表 | Gateway | Nacos Server | gRPC/HTTP | 服务实例列表 | 路由转发时动态获取 |
| 请求路由转发 | Gateway | 业务服务 | HTTP | JSON | 根据路径匹配规则转发 |
| 健康检查响应 | 业务服务 | 客户端 | HTTP GET | JSON (ApiResult) | 确认服务存活状态 |
| API 文档 | 业务服务 | 客户端 | HTTP GET | JSON/HTML | SpringDoc 自动生成 |

**数据一致性策略（本期）：**
- 单服务内事务使用本地数据库事务（`@Transactional`）保证 ACID
- 跨服务分布式事务（Seata）在后续版本引入
- 缓存与数据库一致性（Cache-Aside）在后续引入 Redis 时启用

### 3.6 缓存设计（本期预留）

| 缓存类型 | 缓存用途 | 预计引入版本 | 说明 |
|---------|---------|-------------|------|
| Redis 会话缓存 | 用户登录会话/令牌黑名单 | v0.2.0 | TTL 自动过期 |
| Redis 业务缓存 | 热点业务数据缓存 | v0.3.0 | Cache-Aside 模式 |
| Redis 分布式锁 | 防止并发操作 | v0.3.0 | 基于 Redis SETNX |

**本期 Redis 处理策略：**
- 父 POM 中声明 `spring-boot-starter-data-redis` 依赖，但各服务不启用 Redis 自动配置
- 不在 application.yml 中配置 Redis 连接信息
- 不在代码中使用 Redis 相关功能
- 后续版本需要时，只需添加配置即可启用

---

## 4. 接口设计

### 4.1 API 接口规范

| 项目 | 规范 |
|------|------|
| 对外接口协议 | RESTful（HTTP/1.1） |
| 数据格式 | JSON（UTF-8） |
| 版本策略 | URL 路径版本 `/api/v1/` |
| 认证方式 | 本期骨架无认证，后续 JWT Bearer Token |
| HTTP 方法 | GET（查询）、POST（创建）、PUT（更新）、DELETE（删除） |
| 响应格式 | 统一 `ApiResult<T>` 封装 |

### 4.2 API 路由表（Gateway 配置）

| 路由路径 | 目标服务 | 目标服务 ID | 负载均衡策略 | 说明 |
|---------|---------|------------|------------|------|
| `/api/v1/auth/**` | 认证服务 | `cloudoffice-auth-service` | 轮询 | 认证相关请求 |
| `/api/v1/biz/**` | 企业服务 | `cloudoffice-biz-service` | 轮询 | 企业业务请求 |
| `/api/v1/cloud/**` | 云服务 | `cloudoffice-cloud-service` | 轮询 | 云资源请求 |
| `/api/v1/system/**` | 系统服务 | `cloudoffice-system-service` | 轮询 | 系统管理请求 |

**Gateway 配置要点：**
- 监听端口：9000
- 路由断言：基于 Path 路径匹配
- 过滤器：本阶段仅做路由转发，不添加鉴权过滤器（预留扩展点）
- CORS 配置：允许来自开发前端的跨域请求（`Access-Control-Allow-Origin: *`），允许的自定义 Headers 包括 `Authorization`、`Content-Type` 等

### 4.3 各服务健康检查接口

所有业务服务均提供健康检查端点，统一使用以下模式：

#### 4.3.1 认证服务健康检查

```
GET /api/v1/auth/health
```

**函数签名：**
```java
@RestController
@RequestMapping("/api/v1/auth")
public class HealthController {
    
    @GetMapping("/health")
    public ApiResult<HealthResponse> health();
}
```

**请求参数：** 无

**响应示例（200）：**
```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "service": "cloudoffice-auth-service",
        "status": "UP",
        "version": "0.0.1-SNAPSHOT",
        "timestamp": "2026-06-18T10:00:00Z"
    },
    "timestamp": 1770000000000
}
```

**错误场景：**

| 场景 | HTTP 状态码 | code | message |
|------|------------|------|---------|
| 服务内部异常 | 500 | 500 | 系统繁忙，请稍后重试 |

#### 4.3.2 企业服务健康检查

```
GET /api/v1/biz/health
```

**函数签名：**
```java
@RestController
@RequestMapping("/api/v1/biz")
public class HealthController {
    
    @GetMapping("/health")
    public ApiResult<HealthResponse> health();
}
```

**请求参数：** 无

**响应示例（200）：**
```json
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "service": "cloudoffice-biz-service",
        "status": "UP",
        "version": "0.0.1-SNAPSHOT",
        "timestamp": "2026-06-18T10:00:00Z"
    },
    "timestamp": 1770000000000
}
```

#### 4.3.3 云服务健康检查

```
GET /api/v1/cloud/health
```

**函数签名：**
```java
@RestController
@RequestMapping("/api/v1/cloud")
public class HealthController {
    
    @GetMapping("/health")
    public ApiResult<HealthResponse> health();
}
```

#### 4.3.4 系统服务健康检查

```
GET /api/v1/system/health
```

**函数签名：**
```java
@RestController
@RequestMapping("/api/v1/system")
public class HealthController {
    
    @GetMapping("/health")
    public ApiResult<HealthResponse> health();
}
```

#### 4.3.5 HealthResponse 数据结构

```java
public class HealthResponse {
    private String service;     // 服务名称（Spring Application Name）
    private String status;      // 服务状态：UP / DOWN
    private String version;     // 服务版本号
    private String timestamp;   // 当前时间（ISO 8601 格式）
}
```

### 4.4 SpringDoc OpenAPI 文档接口

```
GET /swagger-ui.html          —   Swagger UI 页面（HTML）
GET /v3/api-docs              —   OpenAPI 3 规范 JSON
```

**说明：**
- 所有服务模块通过 SpringDoc 自动生成 API 文档
- SpringDoc 配置由 common 模块的 `SpringDocConfig` 统一提供
- v0.1.0 阶段仅在开发环境启用，后续通过配置控制是否在生产环境暴露

### 4.5 统一响应体定义

```java
/**
 * 统一响应体
 * @param <T> 泛型数据类型
 */
public class ApiResult<T> {
    private Integer code;       // 状态码（200 成功，400 参数错误，401 未认证，403 无权限，500 服务器错误）
    private String message;     // 提示信息
    private T data;             // 泛型数据（成功时返回，失败时为 null）
    private Long timestamp;     // 当前时间戳（毫秒）
}

/**
 * 统一分页响应
 * @param <T> 泛型数据类型
 */
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}
```

**工厂方法定义：**

```java
public class ApiResult<T> {
    // 成功响应（带数据）
    public static <T> ApiResult<T> success(T data);
    
    // 成功响应（无数据）
    public static <T> ApiResult<T> success();
    
    // 失败响应（带错误码和消息）
    public static <T> ApiResult<T> error(String code, String message);
    
    // 失败响应（HTTP 状态码 + 错误消息）
    public static <T> ApiResult<T> error(Integer code, String message);
}
```

### 4.6 统一错误码定义

**错误码枚举：**

```java
public enum ErrorCode {
    // 成功
    SUCCESS(200, "操作成功"),
    
    // 公共错误 （COMMON 段）
    COMMON_BAD_REQUEST(400, "请求参数错误"),
    COMMON_INTERNAL_ERROR(500, "系统繁忙，请稍后重试"),
    COMMON_NOT_FOUND(404, "请求的资源不存在"),
    COMMON_METHOD_NOT_ALLOWED(405, "请求方法不支持"),
    COMMON_SERVICE_UNAVAILABLE(503, "服务暂不可用"),
    
    // 认证错误 （AUTH 段）
    AUTH_UNAUTHORIZED(401, "认证失败，请重新登录"),
    AUTH_FORBIDDEN(403, "权限不足，无法访问"),
    AUTH_TOKEN_EXPIRED(401, "令牌已过期，请重新获取"),
    AUTH_TOKEN_INVALID(401, "无效的令牌"),
    AUTH_INVALID_CREDENTIALS(401, "用户名或密码错误"),
    
    // 业务错误段（错误码字符串格式）
    // AUTH-0001 ~ AUTH-9999, BIZ-0001 ~ BIZ-9999, 
    // CLOUD-0001 ~ CLOUD-9999, SYS-0001 ~ SYS-9999,
    // COMMON-0001 ~ COMMON-9999
}
```

**错误码分段规则（详见 project.md）：**

| 错误码段 | 模块 | HTTP 状态码映射 |
|---------|------|---------------|
| AUTH-0001 ~ AUTH-9999 | 认证服务 | 401 / 403 |
| BIZ-0001 ~ BIZ-9999 | 企业服务 | 400 / 404 |
| CLOUD-0001 ~ CLOUD-9999 | 云服务 | 400 / 404 |
| SYS-0001 ~ SYS-9999 | 系统服务 | 400 / 404 |
| COMMON-0001 ~ COMMON-9999 | 公共模块 | 400 / 500 |

### 4.7 全局异常处理

**异常处理体系类图：**

```
RuntimeException
    └── BaseException (抽象基类，继承 RuntimeException)
            ├── BusinessException (业务异常，可携带模块级错误码)
            ├── AuthException (认证异常，AUTH 段错误码)
            └── ... 后续扩展
```

**全局异常处理器定义：**

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    // 处理参数校验异常（@Validated）
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ApiResult<?> handleValidationException(MethodArgumentNotValidException ex);
    
    // 处理业务异常
    @ExceptionHandler(BusinessException.class)
    public ApiResult<?> handleBusinessException(BusinessException ex);
    
    // 处理认证异常
    @ExceptionHandler(AuthException.class)
    public ApiResult<?> handleAuthException(AuthException ex);
    
    // 处理参数类型绑定异常
    @ExceptionHandler(BindException.class)
    public ApiResult<?> handleBindException(BindException ex);
    
    // 处理 HTTP 请求方法不支持
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ApiResult<?> handleMethodNotSupportedException(HttpRequestMethodNotSupportedException ex);
    
    // 处理 404 资源不存在
    @ExceptionHandler(NoHandlerFoundException.class)
    public ApiResult<?> handleNoHandlerFoundException(NoHandlerFoundException ex);
    
    // 通用兜底处理器（捕获所有未注册的异常）
    @ExceptionHandler(Exception.class)
    public ApiResult<?> handleException(Exception ex);
}
```

**已知异常场景与处理策略：**

| 异常场景 | 处理器 | HTTP 状态码 | 错误信息 | 日志级别 |
|---------|--------|------------|---------|---------|
| 请求参数校验失败（`@Valid`） | `MethodArgumentNotValidException` | 400 | 参数校验失败的具体字段信息 | WARN |
| 业务异常 | `BusinessException` | 400/404 | 业务错误码 + 业务提示信息 | WARN |
| JWT 令牌过期 | `ExpiredJwtException` | 401 | 令牌已过期，请重新获取 | WARN |
| JWT 签名不匹配 | `SignatureException` | 401 | 无效的令牌（同时记录安全告警） | ERROR |
| 参数类型绑定失败 | `BindException` | 400 | 参数类型错误 | WARN |
| 请求方法不支持 | `HttpRequestMethodNotSupportedException` | 405 | 请求方法不支持 | WARN |
| 404 未找到 | `NoHandlerFoundException` | 404 | 请求的资源不存在 | WARN |
| NPE 等未捕获异常 | `Exception`（兜底） | 500 | 系统繁忙，请稍后重试（不泄露堆栈） | ERROR（打印完整堆栈） |
| Nacos 连接失败 | 服务启动时失败 | - | NacosRegistration failed | ERROR |

### 4.8 错误处理响应格式

```json
// HTTP 400 - 参数校验失败
{
    "code": 400,
    "message": "参数校验失败",
    "data": {
        "field": "userName",
        "error": "用户名不能为空"
    },
    "timestamp": 1770000000000
}

// HTTP 401 - 认证失败
{
    "code": 401,
    "message": "认证失败，请重新登录",
    "data": null,
    "timestamp": 1770000000000
}

// HTTP 500 - 服务内部错误（未捕获异常）
{
    "code": 500,
    "message": "系统繁忙，请稍后重试",
    "data": null,
    "timestamp": 1770000000000
}
```

### 4.9 Gateway 错误场景处理

| 场景 | HTTP 状态码 | 响应体 |
|------|------------|--------|
| 请求路径匹配路由规则，但目标服务未启动 | 502 Bad Gateway | 网关返回默认错误页面，记录 `Service Unavailable` 日志 |
| 请求路径不匹配任何路由规则 | 404 Not Found | 网关返回默认 404 页面 |
| 请求超时（上游 30 秒无响应） | 504 Gateway Timeout | 网关返回默认超时页面 |
| Nacos 服务发现异常 | 502 Bad Gateway | 网关返回默认错误页面 |

---

## 5. 安全设计

### 5.1 安全分层模型

| 层次 | 防护措施 | 实现方式 | v0.1.0 阶段 |
|------|---------|---------|------------|
| 传输层 | 加密传输 | HTTPS（后续配置证书）/ 内网 HTTP | ⏳ 后续配置 |
| 认证层 | 身份验证 | JWT 令牌 + OAuth2 骨架配置 | ✔ 本期搭建骨架 |
| 授权层 | 权限控制 | RBAC（基于角色的访问控制，后续实现） | ⏳ 后续版本 |
| 数据层 | 数据保护 | BCrypt 密码加密、敏感配置环境变量注入 | ✔ 本期启用 |
| 审计层 | 操作审计 | 操作日志记录（后续实现完整审计功能） | ⏳ 后续版本 |

### 5.2 认证机制

| 认证方式 | 适用场景 | v0.1.0 实现方案 |
|---------|---------|----------------|
| JWT 无状态令牌 | API 鉴权 | `JwtUtils` 工具类提供令牌生成/解析/校验方法，不实际集成到过滤器链 |
| OAuth2 授权码 | 第三方应用授权 | `OAuth2Config` 骨架配置，预留扩展点，不实现完整授权码流程 |
| BCrypt 密码 | 用户密码存储 | `BCryptPasswordEncoder` Bean 注册，可在需要时注入使用 |
| 表单登录 | 用户登录 | Spring Security 默认表单登录配置（v0.1.0 骨架阶段使用默认配置） |

#### JwtUtils 工具类设计

**函数签名：**

```java
@Component
@Slf4j
public class JwtUtils {

    /**
     * 生成 JWT 令牌
     *
     * @param userId   用户 ID
     * @param userName 用户名
     * @return JWT 令牌字符串（格式：xxx.yyy.zzz）
     */
    public String generateToken(String userId, String userName);
    
    /**
     * 解析 JWT 令牌
     *
     * @param token JWT 令牌字符串
     * @return Claims 载荷对象
     * @throws ExpiredJwtException     令牌已过期
     * @throws SignatureException      签名不匹配（令牌被篡改）
     * @throws IllegalArgumentException 令牌为 null 或空字符串
     */
    public Claims parseToken(String token);
    
    /**
     * 校验 JWT 令牌有效性
     *
     * @param token JWT 令牌字符串
     * @return true - 有效，false - 无效或已过期
     */
    public boolean validateToken(String token);
    
    /**
     * 从令牌中获取用户 ID
     *
     * @param token JWT 令牌字符串
     * @return 用户 ID
     */
    public String getUserIdFromToken(String token);
    
    /**
     * 从令牌中获取用户名
     *
     * @param token JWT 令牌字符串
     * @return 用户名
     */
    public String getUserNameFromToken(String token);
}
```

**配置属性：**

```yaml
# application.yml
jwt:
  secret: ${JWT_SECRET:your-secret-key-at-least-256-bits-long}  # 签名密钥，通过环境变量注入
  expiration: 86400000  # 过期时间（毫秒），默认 24 小时
  algorithm: HS256      # 签名算法：HS256 / RS256
```

**已知错误场景：**

| 场景 | 异常类型 | 处理方式 |
|------|---------|---------|
| 令牌为 null 或空字符串 | `IllegalArgumentException` | 全局异常处理返回 400 |
| 令牌已过期 | `ExpiredJwtException` | 全局异常处理返回 401 |
| 签名不匹配（被篡改） | `SignatureException` | 全局异常处理返回 401，记录安全告警日志 |
| 令牌格式错误（非三段式） | `MalformedJwtException` | 全局异常处理返回 401 |
| 签名密钥未配置（空密钥） | 启动时校验失败 | 服务启动失败，提示 `secret key must be configured` |

### 5.3 密码安全

| 项目 | 方案 |
|------|------|
| 密码存储 | BCrypt 哈希加密（`BCryptPasswordEncoder`） |
| 加密强度 | `strength = 10`（默认） |
| 明文密码存储 | 禁止 |
| 密码传输 | 后续 HTTPS 启用后加密传输 |

### 5.4 数据安全

| 数据类型 | 处理方式 | 存储位置 | 当前阶段 |
|---------|---------|---------|---------|
| JWT 签名密钥 | 配置文件 + 环境变量注入 | `application.yml` 或环境变量 `JWT_SECRET` | ✔ 本期实现 |
| 用户密码 | BCrypt 哈希加密 | `t_auth_user.password` | ✔ 本期工具类可用 |
| 数据库密码 | 环境变量注入 | 环境变量 / Nacos 配置中心 | ✔ 本期规范要求 |
| 个人身份信息（手机/邮箱） | 应用层日志脱敏 | 数据库明文存储（本期） | ⏳ 后续加密存储 |
| 身份证号 | AES 加密存储 + 脱敏显示 | 数据库加密字段 | ⏳ 后续版本 |

### 5.5 SQL 注入防护

| 防护措施 | 实现方式 |
|---------|---------|
| SQL 预编译 | MyBatis-Plus 参数预编译（`#{}`），禁止使用 `${}` 拼接 SQL |
| 动态查询 | 使用 MyBatis-Plus Lambda 查询或 QueryWrapper，避免 XML 拼接 |
| 代码审查 | 代码审查时重点关注 SQL 拼接场景 |

### 5.6 审计日志

| 项目 | 说明 |
|------|------|
| 记录事件 | 登录/登出、JWT 令牌异常（过期、签名不匹配） |
| 日志格式 | 结构化日志（slf4j + Logback） |
| 敏感数据脱敏 | 密码、手机号、邮箱等敏感信息在日志中脱敏处理 |
| 日志级别 | 安全事件使用 ERROR 级别，便于告警 |

---

## 6. 非功能需求设计

### 6.1 性能指标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 单个微服务模块启动时间 | ≤ 30 秒（首次启动从 jar 到提供服务） | 手动计时 / CI 脚本 |
| 全项目首次完整 Maven 编译时间 | ≤ 120 秒 | `mvn clean compile` 计时 |
| 单模块增量编译时间 | ≤ 10 秒 | IDE 增量编译 |
| 各服务注册到 Nacos 后的路由识别时间 | ≤ 5 秒 | Nacos 控制台观察 |
| 各服务健康检查接口响应时间 | ≤ 500ms | Postman / curl 实测 |

### 6.2 可用性

| 项目 | 目标 | 实现方式 |
|------|------|---------|
| 开发环境服务启动 | 各服务在无数据库连接时可正常启动 | 不强制依赖数据库（WARN 日志，不阻塞启动） |
| Nacos 连接容错 | Nacos 不可用时服务启动失败并给出明确错误提示 | 错误信息明确提示 Nacos 连接失败原因 |
| API 文档可用性 | SpringDoc 文档在服务启动后可在线访问 | `/swagger-ui.html` 和 `/v3/api-docs` 默认启用 |
| 无单点故障（本期） | 骨架阶段暂不考虑多实例部署 | 后续多实例需通过 Nacos 负载均衡 |

### 6.3 可扩展性

| 扩展维度 | 策略 | 说明 |
|---------|------|------|
| 服务水平扩展 | 无状态设计 + Nacos 负载均衡 | 新实例启动后自动注册到 Nacos，Gateway 自动分发流量 |
| 业务功能扩展 | 新增模块或扩展现有模块 | 新增服务模块只需注册到 Nacos 即可加入集群 |
| 数据库读扩展 | 读写分离（后续版本） | 后续引入 MariaDB 主从 + 多数据源配置 |
| 数据库写扩展 | 分库分表（后续版本） | 当前阶段无需分片，后续根据数据量评估 |

### 6.4 可靠性

| 机制 | 方案 | 说明 |
|------|------|------|
| 全局异常兜底 | `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)` | 100% 未捕获异常走通用兜底处理器 |
| 错误信息保护 | 不泄露异常堆栈详情到客户端 | `message` 字段返回友好提示，堆栈仅打印到日志 |
| 服务间解耦 | 各服务模块无直接代码依赖 | 一个服务故障不影响其他服务启动和运行 |
| 构建稳定性 | Maven 依赖版本统一管理 | 父 POM `<dependencyManagement>` + `mvn clean compile -U` |

### 6.5 可观测性

| 类型 | 方案 | 采集内容 | 本期状态 |
|------|------|---------|---------|
| 日志 | Logback（slf4j）+ `@Slf4j` | 业务日志、错误日志、安全告警日志 | ✔ 本期启用 |
| 指标 | Prometheus + Actuator（预留） | JVM 指标 / 请求 QPS / 延迟 | ⏳ 后续集成 |
| 链路追踪 | SkyWalking（预留） | 全链路追踪 | ⏳ 后续集成 |
| 告警 | 钉钉/企业微信（预留） | 异常告警 | ⏳ 后续集成 |
| 文档 | SpringDoc OpenAPI 3 | API 文档在线调试 | ✔ 本期启用 |

**日志规范（详见 project.md）：**

| 级别 | 使用场景 |
|------|----------|
| TRACE | 调试跟踪，仅在开发环境开启 |
| DEBUG | 开发调试，详细运行信息 |
| INFO | 重要业务节点（服务启动、健康检查等） |
| WARN | 潜在问题或非预期但可处理的场景 |
| ERROR | 异常错误，需人工介入的场景 |

---

## 7. 部署与运维设计

### 7.1 容器化部署模板

v0.1.0 阶段提供 Docker 部署模板，实际部署为可选。模板文件位于 `scripts/docker/` 目录。

**Dockerfile 模板（多阶段构建）：**

```
# 第一阶段：构建（Maven 编译打包）
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
COPY cloudoffice-common/pom.xml cloudoffice-common/
COPY cloudoffice-gateway/pom.xml cloudoffice-gateway/
...
RUN mvn clean package -DskipTests

# 第二阶段：运行（JRE 运行）
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/{module}/target/*.jar app.jar
EXPOSE {port}
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Docker Compose 编排：**

```yaml
version: '3.8'
services:
  nacos:
    image: nacos/nacos-server:v2.3.0
    ports:
      - "8848:8848"
    environment:
      - MODE=standalone
  
  mariadb:
    image: mariadb:10.6
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
  
  # ... 各微服务定义
```

### 7.2 环境划分

| 环境 | 用途 | 部署方式 | 数据策略 |
|------|------|---------|---------|
| 开发环境（dev） | 本地开发调试 | IDE 直接启动 / Docker Compose | 各开发者独立，数据隔离 |
| 测试环境（test） | 集成测试 / 功能验证 | Docker Compose / CI 服务器 | 测试数据，定期重置 |
| 生产环境（prod） | 线上正式运行 | Docker / Kubernetes（后续） | 生产数据，主从备份 |

### 7.3 开发环境配置

| 配置项 | 默认值 | 配置方式 |
|--------|--------|---------|
| Nacos 地址 | `127.0.0.1:8848` | `bootstrap.yml` / 环境变量 |
| MariaDB 地址 | `127.0.0.1:3306` | `application.yml` / 环境变量 |
| JWT 密钥 | 环境变量 `JWT_SECRET` | 环境变量注入 |
| SpringDoc 启用 | 开发环境默认启用 | `springdoc.api-docs.enabled=true` |

**IDEA 运行配置（US-008）：**
- `.idea/runConfigurations/` 目录提供各服务的 Spring Boot 运行配置
- 使用 `.editorconfig` 保证跨编辑器代码风格一致
- Checkstyle + Alibaba Java Coding Guidelines 自动检查代码规范

### 7.4 CI/CD 流程（规划）

| 阶段 | 工具 | 说明 |
|------|------|------|
| 代码管理 | Git | GitHub / GitLab |
| CI 工具 | GitHub Actions / Jenkins | 自动构建和测试 |
| 代码扫描 | SonarQube / Checkstyle | 代码质量检查 |
| 单元测试 | JUnit 5 + Mockito | 测试覆盖率 ≥ 80% |
| 镜像构建 | Docker Build | 多阶段构建 |
| 部署策略 | Docker Compose | 灰度发布（后续版本） |

### 7.5 数据库备份策略

| 备份类型 | 频率 | 保留周期 | 说明 |
|---------|------|---------|------|
| 全量备份 | 每日凌晨 02:00 | 7 天 | `mariadb-dump` 逻辑备份 |
| 增量备份 | 每小时 | 48 小时 | 基于 binlog |
| 备份存储 | 本地 + 远程 | - | 本地快速恢复，远端容灾 |

---

## 8. 风险与缓解措施

| 风险编号 | 风险描述 | 可能性 | 影响 | 缓解措施 | 责任人 | 状态 |
|---------|---------|-------|------|---------|-------|------|
| RISK-001 | 团队成员对微服务架构（Nacos、Gateway、OAuth2）不熟悉，上手慢 | 中 | 中 | 1. 提供本地开发环境快速启动指南；2. 编写详细的技术文档和示例代码；3. 每个组件提供独立测试验证步骤 | TL | 已缓解 |
| RISK-002 | Nacos 配置或服务地址变更导致服务无法启动 | 中 | 高 | 1. 所有配置集中在 `bootstrap.yml`，通过环境变量覆盖；2. 提供 Nacos 连通性检查脚本；3. README 中说明 Nacos 部署要求和检查步骤 | 后端工程师 | 已缓解 |
| RISK-003 | Maven 依赖版本冲突或下载失败导致构建失败 | 低 | 高 | 1. 父 POM 统一版本管理，子模块无硬编码版本；2. 使用 `mvn dependency:tree` 检查依赖冲突；3. CI 环境使用 `-U` 强制更新快照 | TL | 已缓解 |
| RISK-004 | JWT 密钥泄露导致安全风险 | 低 | 高 | 1. JWT 密钥通过环境变量注入，禁止硬编码；2. 密钥长度 ≥ 256 位；3. 支持 HS256/RS256 算法切换，后续可引入定期轮换 | 后端工程师 | 已缓解 |
| RISK-005 | 数据库连接配置或 SQL 兼容性问题 | 低 | 中 | 1. 基于 MariaDB 10.6 LTS 开发，不使用特有语法确保兼容 MySQL；2. 使用 MyBatis-Plus 预编译，兼容性问题影响范围可控 | 后端工程师 | 已接受 |
| RISK-006 | 骨架阶段过度设计导致后续开发负担 | 中 | 中 | 1. 严格遵循 PRD 中 v0.1.0 范围，不引入未规划的功能；2. 预留扩展点但不实际实现；3. 复杂度评估后在技术评审中确认 | TL | 已缓解 |
| RISK-007 | 网关路由配置错误导致请求无法正确转发 | 低 | 高 | 1. 路由规则在 `application.yml` 集中配置；2. 提供健康检查端点验证路由可用性；3. 启动后通过 curl 测试各路由 | 后端工程师 | 已缓解 |

---

## 9. 附录

### 附录 A：术语表

| 术语 | 英文 | 定义 |
|------|------|------|
| 云漫智企 | CloudStrollOffice | 基于微服务架构的企业综合管理平台 |
| 公共模块 | Common Module | 提供统一响应体、通用异常、基础实体、工具类等共享组件的模块 |
| API 网关 | API Gateway | 基于 Spring Cloud Gateway 的统一入口，负责请求路由转发和 CORS 跨域支持 |
| 认证服务 | Auth Service | 负责用户认证、授权、OAuth2 骨架、JWT 令牌管理的统一认证服务 |
| 企业服务 | Biz Service | 负责企业信息管理、人事管理、工作流审批等业务模块的承载服务 |
| 云服务 | Cloud Service | 负责云资源管理与资源编排等业务模块的承载服务 |
| 系统服务 | System Service | 负责系统配置、日志管理、监控告警、定时任务等公共服务模块的承载服务 |
| Nacos | Nacos | 阿里巴巴开源的动态服务发现、配置管理平台 |
| SpringDoc | SpringDoc | OpenAPI 3 规范的开源 API 文档生成工具 |
| JWT | JSON Web Token | 基于 JSON 的无状态令牌格式，用于身份认证和信息交换 |
| BCrypt | BCrypt | 基于 Blowfish 密码算法的密码哈希函数，自动加盐、可调成本 |
| MyBatis-Plus | MyBatis-Plus | 增强型 MyBatis ORM 框架，提供代码生成器、Lambda 查询、分页插件 |
| HikariCP | HikariCP | 高性能 JDBC 连接池，Spring Boot 默认连接池 |
| ApiResult | ApiResult | 统一响应体，包含 code、message、data、timestamp 四个字段 |

### 附录 B：依赖版本汇总

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| OpenJDK | JDK | 21 (LTS) | 长期支持版本，支持虚拟线程、模式匹配等新特性 |
| Spring Boot | Spring Boot | 3.2.5 | 应用框架基础 |
| Spring Cloud | Spring Cloud | 2023.0.1 | 微服务框架 |
| Spring Cloud Alibaba | Alibaba | 2023.0.1.0 | 阿里巴巴微服务套件 |
| Maven | Maven | 3.9.x | 项目构建与依赖管理 |
| Nacos | Nacos Server | 2.3.x | 服务注册发现 & 配置中心 |
| Spring Cloud Gateway | Gateway | 内置于 Spring Cloud | API 网关路由转发 |
| MariaDB | MariaDB Server | 10.6 (LTS) | 关系型数据库 |
| MyBatis-Plus | MyBatis-Plus | 3.5.6 | ORM 框架 |
| Spring Security | Security | 内置于 Spring Boot | 认证授权框架 |
| jjwt | io.jsonwebtoken | 0.12.x | JWT 令牌生成与校验 |
| SpringDoc | springdoc-openapi | 2.5.0 | OpenAPI 3 文档生成 |
| HikariCP | HikariCP | 5.x | JDBC 连接池 |
| Hutool | Hutool | 5.8.26 | Java 工具类库 |
| Jackson | Jackson | 2.16.x | JSON 序列化/反序列化 |
| Lombok | Lombok | 1.18.32 | 减少样板代码 |
| Spring Boot Starter Test | Test | 3.2.5 | 单元测试框架 |
| JUnit 5 | JUnit | 5.10.x | 测试框架 |
| Mockito | Mockito | 5.x | Mock 框架 |

### 附录 C：端口分配表

| 服务 | 端口 | 说明 |
|------|------|------|
| cloudoffice-gateway | 9000 | API 网关 |
| cloudoffice-auth-service | 9100 | 认证服务 |
| cloudoffice-biz-service | 9200 | 企业服务 |
| cloudoffice-cloud-service | 9300 | 云服务 |
| cloudoffice-system-service | 9400 | 系统服务 |
| Nacos Server | 8848 | 注册中心 & 配置中心 |
| MariaDB | 3306 | 关系型数据库 |
| Redis | 6379 | 缓存（本期预留） |

### 附录 D：参考文档

| 文档名称 | 路径 |
|---------|------|
| 原始需求文档 | `docs/origin-requires/origin-requires0.1.0.md` |
| 需求文档（v0.1.0） | `docs/requires/CloudStrollOffice-requirement-v0.1.0.md` |
| PRD 文档（v0.1.0） | `docs/prds/CloudStrollOffice-prd-v0.1.0.md` |
| 架构文档 | `docs/architecture.md` |
| 数据库设计文档 | `docs/dbd.md` |
| 项目信息与编码规范 | `docs/project.md` |

---

> **文档信息：**
> - 本文档由 Tech Lead 根据 PRD（`CloudStrollOffice-prd-v0.1.0.md`）、架构文档（`architecture.md`）和数据库设计文档（`dbd.md`）生成
> - 对应 v0.1.0 骨架搭建阶段，仅包含项目初始化和基础设施搭建的技术规格
> - 详细设计（类结构、方法签名实现、SQL 语句等）在任务清单（task）和编码阶段体现
> - 本文档将在后续版本迭代中持续更新
