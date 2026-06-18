# 架构文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.0
**日期：** 2026-06-18

---

## 1. 系统架构概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务企业管理平台，旨在为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。v0.1.0 阶段完成基础骨架搭建，为后续业务功能开发奠定微服务基础设施。

### 1.2 架构风格

- **选用风格：** 微服务架构（Microservices Architecture）
- **选型理由：** 传统企业管理软件多为单体架构，存在扩展困难、技术栈陈旧、模块间耦合严重等问题。微服务架构通过服务解耦与独立部署，支持各业务域独立开发、测试、部署和扩展，符合 PRD 中 "微服务优先" 的核心设计理念，满足 NFR-003（服务间解耦）的要求。

### 1.3 架构层次图

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              客户端层 (Client)                            │
│                   Flutter Desktop / Mobile / Web / 第三方 API              │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          API 网关层 (Gateway)                              │
│                  Spring Cloud Gateway（端口 9000）                          │
│               路由转发 │ CORS │ 负载均衡 │ 服务发现集成                       │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────────┐
        ▼                         ▼                             ▼
┌─────────────────┐   ┌──────────────────────┐   ┌──────────────────────────┐
│  认证服务         │   │   企业服务            │   │   云服务                  │
│  auth-service   │   │   biz-service        │   │   cloud-service          │
│  (端口 9100)     │   │   (端口 9200)        │   │   (端口 9300)            │
│  Spring Security│   │   企业信息/人事管理      │   │   云资源管理/资源编排       │
│  OAuth2 + JWT   │   │   v0.1.0 骨架阶段      │   │   v0.1.0 骨架阶段         │
└─────────────────┘   └──────────────────────┘   └──────────────────────────┘
        │                       │                           │
        ▼                       ▼                           ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          系统服务 (system-service)                         │
│                          (端口 9400)                                       │
│                     系统配置 │ 日志 │ 监控 │ 定时任务                        │
│                         v0.1.0 骨架阶段                                    │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────────┐
        ▼                         ▼                             ▼
┌─────────────────┐   ┌──────────────────────┐   ┌──────────────────────────┐
│   MariaDB 10.6  │   │   Redis 7.2.x        │   │   RocketMQ 5.1.x         │
│  数据库层         │   │  缓存层（本期预留）    │   │  消息队列层（本期预留）     │
│  每服务独立数据库  │   │                      │   │                          │
└─────────────────┘   └──────────────────────┘   └──────────────────────────┘
                                  │
┌──────────────────────────────────────────────────────────────────────────┐
│                         基础设施层                                          │
│   Nacos 2.3.x (注册/配置中心) │ Seata 2.0.x │ Prometheus │ Grafana        │
└──────────────────────────────────────────────────────────────────────────┘
```

### 1.4 核心架构特点

| 特点 | 说明 |
|------|------|
| 服务解耦 | 每个业务域独立为微服务（auth/biz/cloud/system），通过 API 网关统一入口，服务间无直接代码依赖 |
| 统一治理 | Nacos 统一注册发现与配置管理，父 POM 统一管理所有第三方依赖版本 |
| 规范驱动 | 从项目起始阶段建立统一的包结构、命名规范、异常处理体系和代码风格 |
| 渐进演进 | v0.1.0 搭建骨架，后续版本逐步注入业务功能、中间件集成和增强特性 |
| 容器化部署 | 基于 Docker + Docker Compose 的部署模板，支持多环境配置隔离 |

---

## 2. 模块设计

### 2.1 公共模块（cloudoffice-common）

- **职责：** 提供所有业务服务共享的通用组件，包括统一响应体 `ApiResult<T>`、通用异常体系（`BaseException`、`BusinessException`、`GlobalExceptionHandler`、`ErrorCode`）、基础实体类 `BaseEntity`、SpringDoc OpenAPI 3 配置以及通用工具类（Hutool 封装等）。该模块**不依赖任何业务模块**。
- **依赖：** Spring Boot Starter Web、SpringDoc、MyBatis-Plus、Lombok、Hutool、Jackson
- **接口：** 无对外 REST 接口，作为 Maven 依赖被其他模块引用
- **说明：** 纯依赖模块，不含启动类，被打包为 JAR 供各服务引用

### 2.2 API 网关（cloudoffice-gateway）

- **职责：** 微服务统一流量入口，基于 Spring Cloud Gateway 实现请求路由转发、CORS 跨域支持、Nacos 服务发现集成。本阶段预留鉴权过滤器扩展点。
- **依赖：** Spring Cloud Gateway、Spring Cloud Alibaba Nacos Discovery、Spring Cloud LoadBalancer、common 模块
- **端口：** 9000
- **路由规则：**
  - `/api/v1/auth/**` → `cloudoffice-auth-service`
  - `/api/v1/biz/**` → `cloudoffice-biz-service`
  - `/api/v1/cloud/**` → `cloudoffice-cloud-service`
  - `/api/v1/system/**` → `cloudoffice-system-service`

### 2.3 认证服务（cloudoffice-auth-service）

- **职责：** 统一认证授权中心，集成 Spring Security + OAuth2 骨架，提供 JWT 令牌生成/解析/校验工具类、BCrypt 密码编码器。本阶段为骨架搭建，完整 OAuth2 授权码流程在 v0.2.0 实现。
- **依赖：** Spring Boot Starter Web、Spring Security、OAuth2、jjwt、Nacos Discovery/Config、common 模块
- **端口：** 9100
- **说明：** 独立的认证模块，后续将承载用户管理、角色权限、SSO 等功能

### 2.4 企业服务（cloudoffice-biz-service）

- **职责：** 企业核心业务承载服务，本阶段为骨架模块，建立标准包目录结构。后续将承载企业信息管理、部门管理、员工管理、考勤管理、工作流审批、薪酬管理等业务功能。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、common 模块
- **端口：** 9200
- **说明：** v0.1.0 仅搭建骨架，不实现具体业务逻辑

### 2.5 云服务（cloudoffice-cloud-service）

- **职责：** 云资源管理承载服务，本阶段为骨架模块。后续将承载云主机管理、存储管理、网络资源编排等业务功能。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、common 模块
- **端口：** 9300
- **说明：** v0.1.0 仅搭建骨架，不实现具体业务逻辑

### 2.6 系统服务（cloudoffice-system-service）

- **职责：** 基础公共服务承载服务，本阶段为骨架模块。后续将承载系统参数配置管理、操作日志、监控告警、定时任务等功能。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、common 模块
- **端口：** 9400
- **说明：** v0.1.0 仅搭建骨架，定时任务框架选型后续决策，本期不做绑定

### 模块关系图

```
┌────────────────────────────────────────────────────────────────┐
│                    cloudoffice-common                           │
│            (无业务依赖，所有服务模块的公共依赖)                       │
└────────────────────────────────────────────────────────────────┘
                    ▲           ▲           ▲           ▲
                    │依赖       │依赖       │依赖       │依赖
                    │           │           │           │
┌───────────┐ ┌───────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐
│  gateway  │ │auth-service│ │biz-service││cloud-service││system-service│
│ (端口9000) │ │(端口9100) │ │(端口9200) ││(端口9300)  ││ (端口9400)   │
└───────────┘ └───────────┘ └──────────┘ └───────────┘ └──────────────┘
                    │           │           │
                    └───────────┼───────────┘
                                │
                    ┌───────────▼───────────┐
                    │    Nacos 注册中心       │
                    │  (服务发现与配置管理)     │
                    └───────────────────────┘
```

- **注意：** 各业务服务之间无直接代码依赖，服务间通信通过 OpenFeign（同步）或 RocketMQ（异步）在后续版本实现

---

## 3. 技术选型

### 3.1 技术栈全景

| 领域 | 技术方案 | 版本要求 | 选型理由 |
|------|---------|---------|---------|
| 编程语言 | OpenJDK | 21 LTS | 长期支持版本，支持虚拟线程、模式匹配、Record 等新特性，性能优异 |
| 构建工具 | Apache Maven | 3.9.x | 成熟的 Java 项目构建管理工具，多模块支持完善，与 IDEA 集成度高 |
| 微服务框架 | Spring Boot + Spring Cloud | 3.2.5 / 2023.0.1 | 业界主流微服务方案，生态成熟，社区活跃，与 Spring Cloud Alibaba 配合良好 |
| 注册/配置中心 | Nacos | 2.3.x | 支持服务注册发现与配置管理二合一，阿里云原生生态核心组件 |
| API 网关 | Spring Cloud Gateway | 内置于 Spring Cloud | 基于 Spring WebFlux 响应式编程，性能优于 Zuul，与 Nacos 原生集成 |
| 关系型数据库 | MariaDB | 10.6 LTS | MySQL 的完全兼容替代品，性能更优，协议兼容，社区版无功能阉割 |
| ORM 框架 | MyBatis-Plus | 3.5.6 | 增强型 MyBatis，提供代码生成器、分页插件、Lambda 查询，开发效率高 |
| 连接池 | HikariCP | 5.x | Spring Boot 默认连接池，性能业界最优，零额外配置即可使用 |
| 缓存 | Redis | 7.2.x | 高性能内存缓存，（本期预留，仅引入客户端依赖） |
| 消息队列 | RocketMQ | 5.1.x | 阿里巴巴开源的高性能消息中间件，（本期预留，仅引入客户端依赖） |
| 分布式事务 | Seata | 2.0.x | AT 模式无侵入业务代码，与 Spring Cloud Alibaba 深度集成，（本期预留） |
| 认证授权 | Spring Security + OAuth2 + JWT | 内置于 Spring Boot | 业界标准安全框架，OAuth2 支持完善，JWT 无状态令牌方案 |
| JWT 库 | jjwt (io.jsonwebtoken) | 0.12.x | Spring 官方推荐 JWT 实现，支持 HS256/RS256 算法 |
| API 文档 | SpringDoc (OpenAPI 3) | 2.5.0 | 自动生成 OpenAPI 3 规范文档，支持 Swagger UI 在线调试 |
| JSON 处理 | Jackson | 2.16.x | Spring Boot 默认 JSON 框架，性能高，与 Spring 深度集成 |
| 工具库 | Hutool | 5.8.26 | 功能全面的 Java 工具类库，减少重复造轮子 |
| 代码简化 | Lombok | 1.18.32 | 减少 Getter/Setter/Constructor 等样板代码 |
| 可观测性 | Prometheus + Grafana + SkyWalking | 最新 | 业界标准监控方案（本期规划，后续版本集成） |
| 容器化 | Docker + Docker Compose | 最新 | 标准化部署，开发/测试/生产环境一致性 |

### 3.2 架构决策记录（ADR）

| ADR编号 | 决策内容 | 选项对比 | 最终选择 | 理由 | 后果/权衡 |
|---------|---------|---------|---------|------|----------|
| ADR-001 | 架构风格选型 | 单体架构 vs 微服务架构 | 微服务架构 | ① 各业务域（认证/企业/云/系统）职责清晰，天然适合微服务拆分；② 支持独立开发、测试、部署和扩展，满足 NFR-003 服务解耦要求；③ 团队可并行开发不同服务，提升研发效率 | 引入了服务间通信（OpenFeign/RocketMQ）、分布式事务（Seata）、服务治理等额外的架构复杂度，需要更多的运维投入 |
| ADR-002 | 微服务框架选型 | Spring Cloud Alibaba vs Spring Cloud Netflix | Spring Cloud Alibaba | ① Netflix 组件多数进入维护期（Hystrix 停更、Ribbon 停更、Zuul 停更）；② Alibaba 组件（Nacos、Sentinel、Seata、RocketMQ）生态活跃，持续迭代；③ 国产技术栈，中文文档丰富，社区支持好 | 对阿里云生态的依赖性增强，但各组件均为开源项目，不存在厂商锁定风险 |
| ADR-003 | 注册/配置中心选型 | Nacos vs Eureka vs Zookeeper | Nacos | ① 同时支持服务注册发现和配置管理，减少运维组件数量；② Eureka 2.x 已停更；③ Nacos 支持配置动态刷新、命名空间隔离、灰度发布等高级特性；④ 与 Spring Cloud Alibaba 深度集成 | Nacos Server 需要额外部署维护，相比 Eureka 仅注册中心功能，部署成本略高 |
| ADR-004 | API 网关选型 | Spring Cloud Gateway vs APISIX vs Kong | Spring Cloud Gateway（本期） | ① 与 Spring Cloud 生态原生集成，开发配置一致性好；② 基于 WebFlux 响应式编程，性能高；③ 本阶段功能需求简单（路由转发 + CORS），Gateway 足够胜任 | 后期若需高级功能（动态路由、插件热加载），可迁移至 APISIX；Gateway 的配置变更需重启服务 |
| ADR-005 | 关系型数据库选型 | MariaDB vs MySQL vs PostgreSQL | MariaDB 10.6 LTS | ① 完全兼容 MySQL 协议和 SQL 语法，迁移零成本；② 相比 MySQL，MariaDB 有更优的查询优化器和性能（如子查询优化、窗口函数）；③ LTS 版本支持 5 年维护，社区版与商业版功能无差异 | MySQL 的流行度和生态资源略高于 MariaDB，但 MariaDB 在兼容性上无差异 |
| ADR-006 | ORM 框架选型 | MyBatis-Plus vs JPA/Hibernate | MyBatis-Plus 3.5.x | ① MyBatis-Plus 在 MyBatis 基础上提供代码生成器、Lambda 查询、分页插件、乐观锁插件等增强功能；② 相比 JPA，MyBatis 更贴近 SQL，便于 DBA 审查和优化 SQL；③ 团队对 MyBatis 熟悉度更高，学习成本低 | 相比 JPA，MyBatis-Plus 需要手写部分 XML 映射文件，自动化程度略低；关联查询需手动编写 |
| ADR-007 | 服务间同步通信 | OpenFeign + LoadBalancer vs RestTemplate + Ribbon | OpenFeign + Spring Cloud LoadBalancer | ① OpenFeign 声明式 HTTP 客户端，代码简洁，可读性好；② Spring Cloud 2023.x 已移除 Ribbon，官方推荐 LoadBalancer 替代；③ OpenFeign 与 Spring MVC 注解兼容，学习成本低 | 相比 RPC 框架（如 Dubbo），HTTP 通信性能略低，但本阶段业务规模下完全可接受 |
| ADR-008 | 主键生成策略 | 雪花算法 vs UUID vs 自增 ID | 雪花算法（MyBatis-Plus ID_WORKER） | ① 分布式环境下的唯一 ID 生成方案，不依赖数据库；② ID 为 Long 类型，相比 UUID（String）占用空间小，索引效率高；③ 趋势递增，利于 B+Tree 索引维护 | 需要配置工作机器 ID 避免冲突；时间回拨问题需额外处理（MP 已内置处理） |
| ADR-009 | 密码加密方案 | BCrypt vs SHA-256 vs MD5 | BCrypt | ① Spring Security 内置支持，开箱即用；② 自动加盐，抗彩虹表攻击；③ 可配置计算成本（strength），未来可增加难度；④ 相比 MD5/SHA 的快速计算特性，BCrypt 慢哈希更安全 | 密码验证性能较慢（约 10ms/次），但登录场景下可接受 |
| ADR-010 | 配置文件管理 | Nacos 配置中心 vs 本地配置文件 | 本地配置文件为主 + Nacos 配置中心骨架 | ① 本阶段为骨架搭建，功能简单，本地配置文件足够；② 预留 Nacos 配置中心 bootstrap.yml 配置，后续动态配置需求可直接启用；③ 敏感配置通过环境变量注入，不留存于代码仓库 | 配置变更需重启服务，本阶段可接受；后续版本启用配置中心后可热更新 |

---

## 4. 数据流

### 4.1 核心业务数据流（v0.1.0 骨架阶段）

```
[客户端]
    │
    │ HTTP 请求
    ▼
[API 网关 (端口 9000)]
    │
    │ 路由转发（基于路径 /api/v1/{module}/**）
    ▼
[目标微服务]
    │
    ├─→ 健康检查端点 → 返回 ApiResult 响应
    │
    └─→ SpringDoc 文档 → 返回 OpenAPI 3 JSON/UI
    │
    ▼
[客户端] ←─── JSON 响应 (ApiResult 格式)

认证流程（下一版本完善）：
[客户端] → [Gateway] → [auth-service: 登录] → JWT 令牌返回
[客户端] → [Gateway(携带JWT)] → [目标服务] → 业务响应
```

### 4.2 模块间数据流转

| 数据流 | 发起方 | 接收方 | 通信方式 | 数据格式 | 说明 |
|--------|--------|--------|---------|---------|------|
| 注册服务实例 | 各微服务 | Nacos Server | gRPC/HTTP | 服务元数据 | 服务启动时自动注册 |
| 获取服务列表 | Gateway | Nacos Server | gRPC/HTTP | 服务实例列表 | 路由转发的服务发现 |
| 请求路由转发 | Gateway | 业务服务 | HTTP | JSON | 根据路径匹配规则转发 |
| 健康检查 | 客户端 | 各服务 | HTTP GET | JSON (ApiResult) | 确认服务存活状态 |
| API 文档 | 客户端 | 各服务 | HTTP GET | JSON/HTML | SpringDoc 自动生成 |

### 4.3 数据存储流转

| 数据类型 | 产生阶段 | 存储位置 | 消费阶段 | 生命周期 |
|---------|---------|---------|---------|---------|
| JWT 签名密钥 | 配置阶段 | 配置文件/环境变量 | 令牌签发与校验 | 持久（定期轮换） |
| BCrypt 密码 | 用户注册 | 数据库（本期预留） | 登录验证 | 持久 |
| 用户会话 | 登录认证 | Redis（本期预留） | 令牌校检 | 临时（TTL 控制） |
| 业务数据 | 业务操作 | MariaDB（本期预留） | 业务查询 | 持久 |

---

## 5. 数据架构

### 5.1 数据模型概览

v0.1.0 为骨架搭建阶段，数据库设计以基础表结构模板为主。各服务独立数据库：

```
cloudstroll_office_auth        # 认证服务数据库
  └── t_auth_user              # 用户表（基础结构示例）

cloudstroll_office_biz         # 企业服务数据库（预留）

cloudstroll_office_cloud       # 云服务数据库（预留）

cloudstroll_office_system      # 系统服务数据库（预留）
```

### 5.2 存储策略

| 数据类型 | 存储方案 | 理由 | 一致性要求 |
|---------|---------|------|-----------|
| 用户账号与认证数据 | MariaDB（auth 库） | 关系型数据，支持事务 | 强一致性 |
| 企业业务数据 | MariaDB（biz 库） | 关系型数据，需 ACID 保证 | 强一致性 |
| 云资源数据 | MariaDB（cloud 库） | 关系型数据 | 强一致性 |
| 系统配置与日志 | MariaDB（system 库） | 关系型数据 | 最终一致性（日志可接受） |
| 用户登录会话/令牌黑名单 | Redis | 高速读写，TTL 自动过期 | 最终一致性 |
| 操作日志/审计日志 | MariaDB / 文件 | 持久化存储，支持查询 | 最终一致性 |

### 5.3 数据一致性策略

- **单服务内事务：** 使用本地数据库事务（@Transactional）保证 ACID
- **跨服务分布式事务：** 使用 Seata AT 模式保证最终一致性（本期预留，后续引入）
- **缓存与数据库一致性：** 采用 Cache-Aside 模式，更新数据库后主动失效缓存（后续集成 Redis 时启用）
- **消息队列异步通信：** RocketMQ 事务消息保证生产者本地事务与消息发送的原子性（后续集成）

### 5.4 数据库设计规范

| 类别 | 规则 |
|------|------|
| 数据库 | 每服务独立数据库，命名 `cloudstroll_office_{module}` |
| 表命名 | `t_{module}_{table_name}`（如 `t_auth_user`）|
| 字段命名 | 下划线命名法（如 `user_name`、`create_time`）|
| 主键 | 雪花算法（BIGINT），字段名统一 `id` |
| 公共字段 | 每表必须包含 `id`、`create_time`、`update_time`、`deleted`（逻辑删除）|
| 索引命名 | 普通索引 `idx_{table}_{column}`，唯一索引 `uk_{table}_{column}` |

---

## 6. 接口设计

### 6.1 外部接口

| 接口名称 | 协议 | 路径 | 认证方式 | 调用方 | 说明 |
|---------|------|------|---------|--------|------|
| 网关入口 | HTTP | `http://localhost:9000/api/v1/{module}/**` | JWT（下期实现） | Flutter 客户端/第三方 | 统一 API 入口 |
| 认证-健康检查 | HTTP GET | `/api/v1/auth/health` | 无 | 客户端/监控 | 认证服务存活检测 |
| 企业-健康检查 | HTTP GET | `/api/v1/biz/health` | 无 | 客户端/监控 | 企业服务存活检测 |
| 云-健康检查 | HTTP GET | `/api/v1/cloud/health` | 无 | 客户端/监控 | 云服务存活检测 |
| 系统-健康检查 | HTTP GET | `/api/v1/system/health` | 无 | 客户端/监控 | 系统服务存活检测 |
| API 文档 | HTTP GET | `/swagger-ui.html` 或 `/v3/api-docs` | 无（开发环境） | 开发者 | SpringDoc 在线文档 |

### 6.2 内部接口

| 接口名称 | 通信方式 | 数据格式 | 调用关系 | 说明 |
|---------|---------|---------|---------|------|
| 服务注册 | Nacos SDK | 服务元数据 | 各服务 → Nacos Server | 自动注册与心跳维持 |
| 配置拉取 | Nacos SDK | YAML/Properties | 各服务 → Nacos Server | bootstrap.yml 指定配置中心地址 |
| 服务发现 | Spring Cloud LoadBalancer | 服务实例列表 | Gateway → Nacos Server | 路由转发时动态获取服务地址 |

### 6.3 接口契约（统一响应体）

```java
// 统一响应体
public class ApiResult<T> {
    private Integer code;       // 状态码（200 成功、400 参数错误、401 未认证、403 无权限、500 服务器错误）
    private String message;     // 提示信息
    private T data;             // 泛型数据
    private Long timestamp;     // 时间戳
}

// 统一分页响应
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}

// 健康检查响应示例
// GET /api/v1/auth/health
// Response:
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "service": "cloudoffice-auth-service",
        "status": "UP",
        "timestamp": "2026-06-18T10:00:00Z"
    },
    "timestamp": 1770000000000
}
```

### 6.4 API 路由表

| 路由路径 | 目标服务 | 负载均衡策略 | 说明 |
|---------|---------|------------|------|
| `/api/v1/auth/**` | `cloudoffice-auth-service` | 轮询 | 认证相关请求 |
| `/api/v1/biz/**` | `cloudoffice-biz-service` | 轮询 | 企业业务请求 |
| `/api/v1/cloud/**` | `cloudoffice-cloud-service` | 轮询 | 云资源请求 |
| `/api/v1/system/**` | `cloudoffice-system-service` | 轮询 | 系统管理请求 |

---

## 7. 非功能性需求落地（NFR Implementation）

| PRD-NFR编号 | 非功能性需求 | 架构决策 | 量化指标 |
| --------- | -------- | ------------- | -------------- |
| NFR-001 | 性能 - 模块启动时间 ≤ 30 秒 | 去除不必要的自动配置，懒加载非关键组件；各服务不强制依赖数据库连接，无 DB 时可启动（WARN 日志） | 单模块首次启动 ≤ 30 秒 |
| NFR-001 | 可用性 - Nacos 连接容错 | Nacos 连接失败时服务启动失败并给出明确错误提示，指导开发者检查 Nacos 地址和运行状态 | 错误信息明确提示 Nacos 连接失败原因 |
| NFR-002 | 可靠性 - 全局异常兜底 | `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)` 兜底所有未捕获异常，返回统一错误体，不泄露堆栈明细到客户端 | 100% 未捕获异常走通用兜底处理器 |
| NFR-002 | 可维护性 - API 文档 | SpringDoc 自动生成 OpenAPI 3 文档，支持在线调试 | 各服务 `/swagger-ui.html` 可访问 |
| NFR-003 | 可维护性 - 服务间解耦 | 各服务模块无直接代码依赖，仅通过 Nacos 服务发现 + HTTP API 通信 | 一个服务故障不影响其他服务启动和运行 |
| NFR-004 | 性能 - Maven 编译 | 父 POM 统一依赖版本管理，子模块无硬编码版本 | 首次完整编译 ≤ 120 秒，增量编译 ≤ 10 秒 |
| NFR-005 | 可维护性 - 代码规范一致性 | 统一包结构、命名规范、构造器注入、Checkstyle + Alibaba 规范检查 | 通过 Checkstyle 规则验证 |
| 约束条件 | 安全性 - SQL 注入防护 | MyBatis-Plus 预编译机制，禁止拼接 SQL | 无 SQL 注入风险 |
| 约束条件 | 安全性 - 敏感配置 | JWT 密钥、数据库密码等通过环境变量 + 配置文件管理，禁止硬编码 | 代码仓库无明文敏感信息 |

---

## 8. 部署与运维视图

### 8.1 部署架构

```
[开发者本地环境 / CI/CD]
    │
    ├─ Docker Compose 编排
    │
    ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Docker 宿主机                               │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Nacos 2.3.x │  │  MariaDB 10.6│  │  Redis 7.2.x│  (本期预留)  │
│  │  端口: 8848  │  │  端口: 3306  │  │  端口: 6379 │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐         │
│  │   Gateway   │  │ Auth Service│  │  Biz Service      │         │
│  │   :9000     │  │   :9100     │  │   :9200           │         │
│  └─────────────┘  └─────────────┘  └──────────────────┘         │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────────────┐                  │
│  │  Cloud Service   │  │  System Service      │                  │
│  │   :9300          │  │   :9400              │                  │
│  └──────────────────┘  └──────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 环境划分

| 环境 | 用途 | 部署方式 | 数据策略 |
| ----- | ---- | ------- | -------- |
| 开发环境（dev） | 本地开发调试 | 本地 IDE 直接启动 / Docker Compose | 各开发者独立，数据隔离 |
| 测试环境（test） | 集成测试 / 功能验证 | Docker Compose / CI 服务器 | 测试数据，定期重置 |
| 生产环境（prod） | 线上正式运行 | Docker / Kubernetes（后续） | 生产数据，主从备份 |

### 8.3 可观测性

| 类型 | 方案 | 采集内容 | 当前阶段 |
| ---- | ----------------------- | ------------- | -------- |
| 日志 | Logback（slf4j）| 业务日志/错误日志/访问日志 | ✔ 本期启用 |
| 指标 | Prometheus + Grafana | JVM 指标/QPS/延迟/错误率 | ⏳ 后续版本 |
| 链路追踪 | SkyWalking | 请求全链路追踪 | ⏳ 后续版本 |
| 告警 | 钉钉/企业微信 | SLA 违反/错误阈值 | ⏳ 后续版本 |

### 8.4 灾难恢复

| 场景 | RPO | RTO | 恢复策略 | 当前阶段 |
| ----- | ---- | ---- | --------- | -------- |
| 单服务进程崩溃 | - | ≤ 30 秒 | Docker 自动重启策略（restart: always） | ✔ 本期规划 |
| 数据库故障 | ≤ 1 小时 | ≤ 30 分钟 | MariaDB 主从同步 + 定期全量备份 | ⏳ 规划中 |
| 完整站点故障 | ≤ 24 小时 | ≤ 4 小时 | 备份恢复 + 基础设施即代码重建 | ⏳ 规划中 |

---

## 9. 安全架构

### 9.1 安全分层

| 层次 | 防护措施 | 实现方式 | 当前阶段 |
| --- | ------ | -------------------- | -------- |
| 传输层 | 加密传输 | HTTPS（后续配置证书）/ 内网 HTTP | ⏳ 后续配置 |
| 认证层 | 身份验证 | JWT 令牌 + OAuth2 授权码流程（骨架） | ✔ 本期搭建骨架 |
| 授权层 | 权限控制 | RBAC（基于角色的访问控制，后续实现） | ⏳ 后续版本 |
| 数据层 | 数据保护 | BCrypt 密码加密、敏感配置环境变量注入 | ✔ 本期启用 |
| 审计层 | 操作审计 | 操作日志记录（后续实现完整审计功能） | ⏳ 后续版本 |

### 9.2 敏感数据处理

| 数据类型 | 处理方式 | 存储位置 | 当前阶段 |
| -------- | ------- | ---------- | -------- |
| JWT 签名密钥 | 配置文件 + 环境变量注入 | `application.yml` 或环境变量 | ✔ 本期实现 |
| 用户密码 | BCrypt 哈希加密 | 数据库（本期预留） | ✔ 本期工具类可用 |
| 数据库密码 | 环境变量注入 | 环境变量 / Nacos 配置中心 | ✔ 本期规范要求 |
| 个人身份信息 | 脱敏/加密（后续实现） | 加密数据库 | ⏳ 后续版本 |

### 9.3 认证授权架构

```
┌──────────┐        ┌──────────────┐        ┌─────────────────┐
│  客户端   │ ──────▶│  Gateway      │ ──────▶│  auth-service    │
│ (Flutter) │        │  (端口 9000)  │        │  (端口 9100)     │
└──────────┘        └──────────────┘        └─────────────────┘
                         │                          │
                         ▼                          ▼
                   验证 JWT 令牌               生成/刷新 JWT
                   （下期实现）              OAuth2 骨架（本期搭建）
```

**本期安全实现清单：**
- auth-service 集成 Spring Security 基本配置（SecurityConfig）
- OAuth2 授权服务器骨架配置（OAuth2Config），但不实现完整授权码流程
- JWTUtils 工具类：支持 HS256/RS256 算法，提供 `generateToken`、`parseToken`、`validateToken` 方法
- BCryptPasswordEncoder 密码编码器
- 敏感配置通过环境变量管理，禁止硬编码

---

## 10. 目录结构

```
CloudStrollOffice/
├── pom.xml                                    # 父 POM（依赖版本统一管理，定义 6 个子模块）
├── opencode.json                              # OpenCode AI 开发工具配置
├── .gitignore                                 # Git 忽略规则
├── .editorconfig                              # 跨编辑器代码风格配置
├── checkstyle.xml                             # Checkstyle 规则文件
│
├── .opencode/                                 # AI 开发工具配置目录
│   ├── agents/                                # Agent 配置
│   └── skills/                                # 技能实现
│
├── docs/                                      # 项目文档目录
│   ├── project.md                             # 项目信息文档（本文件）
│   ├── architecture.md                        # 架构文档
│   ├── origin-requires/                       # 原始需求文档
│   ├── requires/                              # 需求文档
│   ├── prds/                                  # PRD 文档
│   ├── sds/                                   # 技术规格说明书
│   ├── tasks/                                 # 任务清单
│   └── prompts/                               # AI 交互历史记录
│
├── cloudoffice-common/                        # 公共模块（通用组件、工具类）
│   ├── pom.xml
│   └── src/main/java/org/cloudstrolling/cloudoffice/common/
│       ├── model/
│       │   ├── ApiResult.java                 # 统一响应体
│       │   └── BaseEntity.java                # 基础实体（id/createTime/updateTime/deleted）
│       ├── exception/
│       │   ├── BaseException.java             # 异常抽象基类
│       │   ├── BusinessException.java         # 业务异常
│       │   ├── GlobalExceptionHandler.java    # 全局异常处理器
│       │   └── ErrorCode.java                 # 错误码枚举
│       ├── config/
│       │   └── SpringDocConfig.java           # SpringDoc OpenAPI 3 配置
│       └── util/                              # 通用工具类目录
│
├── cloudoffice-gateway/                       # API 网关（端口 9000）
│   ├── pom.xml
│   └── src/
│       ├── main/java/org/cloudstrolling/cloudoffice/gateway/
│       │   ├── GatewayApplication.java        # 网关启动类
│       │   └── config/                        # 网关配置类目录
│       └── main/resources/
│           ├── bootstrap.yml                  # Nacos 注册/配置中心配置
│           └── application.yml                # 路由规则、CORS、端口配置
│
├── cloudoffice-auth-service/                  # 认证服务（端口 9100）
│   ├── pom.xml
│   └── src/
│       ├── main/java/org/cloudstrolling/cloudoffice/auth/
│       │   ├── AuthApplication.java           # 认证服务启动类
│       │   ├── config/
│       │   │   ├── SecurityConfig.java        # Spring Security 安全配置
│       │   │   └── OAuth2Config.java          # OAuth2 骨架配置
│       │   ├── util/
│       │   │   └── JwtUtils.java              # JWT 工具类（生成/解析/校验）
│       │   ├── controller/                    # 控制器层（预留）
│       │   ├── service/                       # 业务逻辑层（预留）
│       │   │   └── impl/
│       │   ├── mapper/                        # 数据访问层（预留）
│       │   ├── entity/                        # 实体类（预留）
│       │   ├── dto/                           # 数据传输对象（预留）
│       │   ├── vo/                            # 视图对象（预留）
│       │   ├── enums/                         # 枚举类（预留）
│       │   ├── exception/                     # 异常处理（预留）
│       │   ├── filter/                        # 过滤器（预留）
│       │   └── interceptor/                   # 拦截器（预留）
│       └── main/resources/
│           ├── bootstrap.yml                  # Nacos 配置
│           └── application.yml                # 应用配置
│
├── cloudoffice-biz-service/                   # 企业服务（端口 9200）
│   ├── pom.xml
│   └── src/main/java/org/cloudstrolling/cloudoffice/biz/
│       ├── BizApplication.java                # 企业服务启动类
│       ├── config/                            # 配置类
│       ├── controller/                        # 控制器层
│       ├── service/                           # 业务逻辑层
│       │   └── impl/
│       ├── mapper/                            # 数据访问层
│       ├── entity/                            # 实体类
│       ├── dto/                               # 数据传输对象
│       ├── vo/                                # 视图对象
│       ├── enums/                             # 枚举类
│       ├── exception/                         # 异常处理
│       ├── filter/                            # 过滤器
│       ├── interceptor/                       # 拦截器
│       └── util/                              # 工具类
│       └── main/resources/
│           ├── bootstrap.yml
│           └── application.yml
│
├── cloudoffice-cloud-service/                 # 云服务（端口 9300）
│   ├── pom.xml
│   └── src/main/java/org/cloudstrolling/cloudoffice/cloud/
│       ├── CloudApplication.java
│       ├── config/
│       ├── controller/
│       ├── service/
│       │   └── impl/
│       ├── mapper/
│       ├── entity/
│       ├── dto/
│       ├── vo/
│       ├── enums/
│       ├── exception/
│       ├── filter/
│       └── interceptor/
│       └── main/resources/
│           ├── bootstrap.yml
│           └── application.yml
│
├── cloudoffice-system-service/                # 系统服务（端口 9400）
│   ├── pom.xml
│   └── src/main/java/org/cloudstrolling/cloudoffice/system/
│       ├── SystemApplication.java
│       ├── config/
│       ├── controller/
│       ├── service/
│       │   └── impl/
│       ├── mapper/
│       ├── entity/
│       ├── dto/
│       ├── vo/
│       ├── enums/
│       ├── exception/
│       ├── filter/
│       └── interceptor/
│       └── main/resources/
│           ├── bootstrap.yml
│           └── application.yml
│
├── scripts/                                   # 脚本与模板
│   ├── docker/                                # Docker 部署模板
│   │   ├── gateway/Dockerfile
│   │   ├── auth-service/Dockerfile
│   │   ├── biz-service/Dockerfile
│   │   ├── cloud-service/Dockerfile
│   │   ├── system-service/Dockerfile
│   │   └── docker-compose.yml                 # Compose 编排（含 Nacos/MariaDB/Redis）
│   └── sql/
│       └── init.sql                           # 数据库初始化脚本模板
│
└── .idea/                                     # IDEA 统一配置
    ├── codeStyles/
    │   ├── Project.xml                        # 代码风格（Alibaba 规范）
    │   └── codeStyleConfig.xml                # 代码风格引用配置
    └── runConfigurations/                     # 运行配置
        ├── GatewayApplication.xml
        ├── AuthApplication.xml
        ├── BizApplication.xml
        ├── CloudApplication.xml
        └── SystemApplication.xml
```

---

## 11. 架构质量属性

| 质量属性 | 实现策略 | 验证方式 |
| -------- | ----------------- | ----------- |
| **可维护性** | 微服务拆分 + 标准包结构 + 统一编码规范 + Checkstyle 自动化检查 | 代码审查 / Checkstyle 检查 / SonarQube 扫描 |
| **可测试性** | 构造器注入 + 接口隔离 + ApiResult 统一响应体 | 单元测试覆盖率 ≥ 80% / JUnit 5 + Mockito |
| **可扩展性** | 微服务架构 + Nacos 服务发现 + 无状态设计 | 新增服务模块只需注册到 Nacos 即可加入集群 |
| **可靠性** | 全局异常兜底 + ApiResult 统一错误返回 + 不泄露堆栈到客户端 | 异常场景测试 / 错误码覆盖验证 |
| **可移植性** | 容器化部署（Docker）+ Maven 多模块 + 配置与环境解耦（Nacos/环境变量） | 跨环境部署验证（dev/test/prod）|
| **性能** | 各服务独立启动 + 懒加载配置 + 无硬依赖数据库启动（NFR-001）| 启动时间 ≤ 30 秒 / Maven 编译时间 ≤ 120 秒 |
| **安全性** | BCrypt 密码加密 + JWT 无状态令牌 + 敏感配置环境变量 + MyBatis-Plus 预编译防 SQL 注入 | 安全审查 / 渗透测试（后续）|

---

## 12. 附录

### A. 接口规范模板

```java
// 统一响应体格式
public class ApiResult<T> {
    private Integer code;       // 状态码
    private String message;     // 提示信息
    private T data;             // 数据
    private Long timestamp;     // 时间戳
}

// 分页响应格式
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}
```

### B. 文档命名规范

| 文档类型 | 目录 | 文件名格式 | 示例 |
| ----- | ---- | -------- | ------ |
| 需求文档 | `docs/requires/` | `{ProjectName}-requirement-v{version}.md` | `CloudStrollOffice-requirement-v0.1.0.md` |
| PRD 文档 | `docs/prds/` | `{ProjectName}-prd-v{version}.md` | `CloudStrollOffice-prd-v0.1.0.md` |
| 架构文档 | `docs/` | `architecture.md` | `architecture.md` |
| 技术规格 | `docs/sds/` | `{ProjectName}-sds-v{version}.md` | `CloudStrollOffice-sds-v0.1.0.md` |
| 数据库设计 | `docs/` | `dbd.md` | `dbd.md` |
| 项目信息 | `docs/` | `project.md` | `project.md` |

### C. 版本号规则

- **格式：** `v{主版本}.{次版本}.{修订号}`
- **递增规则：**
  - **主版本：** 架构重大变更、不兼容的 API 修改
  - **次版本：** 新功能添加、API 扩展（向下兼容）
  - **修订号：** Bug 修复、性能优化（向下兼容）

### D. 参考文档

- `docs/requires/CloudStrollOffice-requirement-v0.1.0.md` — 需求文档
- `docs/prds/CloudStrollOffice-prd-v0.1.0.md` — PRD 文档
- `docs/origin-requires/origin-requires0.1.0.md` — 原始需求文档
- `docs/project.md` — 项目信息与编码规范
- `opencode.json` — OpenCode AI 配置
