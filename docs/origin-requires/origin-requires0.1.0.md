# 云漫智企 (CloudStrollOffice) 架构设计文档 v1.0.0

---

## 1. 概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）是一个基于 Java 和 Spring Boot 技术栈构建的微服务互联网应用程序，旨在为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。

### 1.2 设计目标

- 采用微服务架构，实现服务解耦和独立部署
- 统一技术栈和中间件选型，降低维护成本
- 支持单点登录（SSO），提供统一认证授权
- 高可用、可扩展、可观测

### 1.3 本期工作内容：

- 搭建微服务的项目群的总体框架，文件夹 pom等内容。
- 生成idea的基础配置和最佳实践


---

## 2. 技术栈选型

### 2.1. 技术栈总体设计
**后端** Java + SpringBoot 微服务框架。
**前端** 用Flutter，支持Windwos，Ubuntu，H5（手机，PC双端），Android，IOS，Arm64 deb等格式。并通过MPFlutter支持微信小程序。

### 2.2 核心框架

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| JDK | OpenJDK | 21 (LTS) | 长期支持版本，性能优异 |
| Spring Boot | Spring Boot | 3.2.x | 应用框架基础 |
| Spring Cloud | Spring Cloud | 2023.x | 微服务框架 |
| Spring Cloud Alibaba | Spring Cloud Alibaba | 2023.x | 阿里巴巴微服务套件 |
| 构建工具 | Maven | 3.9.x | 项目构建与依赖管理 |

### 2.3 中间件选型

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 注册中心 | Nacos | 2.3.x | 服务注册与发现 |
| 配置中心 | Nacos | 2.3.x | 统一配置管理 |
| API 网关 | APISIX | 3.8.x | 高性能动态 API 网关 |
| 消息队列 | RocketMQ | 5.1.x | 分布式消息中间件 |
| 缓存 | Redis | 7.2.x | 高性能内存缓存 |
| 数据库 | MariaDB | 10.6 (LTS) | 关系型数据库 |
| 分布式事务 | Seata | 2.0.x | 分布式事务解决方案 |

### 2.4 开发框架与组件

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| ORM 框架 | MyBatis-Plus | 3.5.x | 增强型 MyBatis 框架 |
| 认证授权 | Spring Security + JWT + OAuth2 | 最新 | 单点登录认证 |
| API 文档 | SpringDoc (OpenAPI 3) | 2.x | RESTful API 文档 |
| 监控 | Prometheus + Grafana + SkyWalking | 最新 | 可观测性方案 |
| 连接池 | HikariCP | 5.x | 高性能 JDBC 连接池 |
| 工具库 | Hutool | 5.8.x | Java 工具类库 |
| JSON 处理 | Jackson | 2.16.x | JSON 序列化/反序列化 |

---

## 3. 架构设计

### 3.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        客户端层 (Client)                         │
│              Web / Mobile / Third-Party API                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      API 网关层 (APISIX)                         │
│         路由转发 │ 负载均衡 │ 限流熔断 │ 认证鉴权                 │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  认证服务      │    │    企业服务       │    │    云服务        │
│ auth-service  │    │   biz-service    │    │  cloud-service   │
└───────────────┘    └──────────────────┘    └──────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      系统服务 (system-service)                    │
│              日志 │ 监控 │ 配置 │ 定时任务                         │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   MariaDB     │    │     Redis        │    │   RocketMQ       │
│   数据库层     │    │    缓存层         │    │   消息队列层      │
└───────────────┘    └──────────────────┘    └──────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                      基础设施层                                   │
│         Nacos │ Seata │ Prometheus │ Grafana │ SkyWalking        │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 服务划分

| 服务名称 | 包名 | 端口 | 职责描述 |
|----------|------|------|----------|
| gateway | org.cloudstrolling.cloudoffice.gateway | 9000 | API 网关，路由转发、限流、认证 |
| auth-service | org.cloudstrolling.cloudoffice.auth | 9100 | 用户认证、授权、OAuth2、JWT |
| biz-service | org.cloudstrolling.cloudoffice.biz | 9200 | 企业信息管理、业务流程 |
| cloud-service | org.cloudstrolling.cloudoffice.cloud | 9300 | 云资源管理、资源编排 |
| system-service | org.cloudstrolling.cloudoffice.system | 9400 | 系统配置、日志、监控、定时任务 |
| common | org.cloudstrolling.cloudoffice.common | - | 公共模块，通用组件、工具类 |

### 3.3 服务间通信

- **同步通信**: OpenFeign + Ribbon (负载均衡)
- **异步通信**: RocketMQ (消息队列)
- **分布式事务**: Seata (AT 模式)

### 3.4 认证授权架构

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  客户端   │────▶│  APISIX 网关  │────▶│ auth-service │
└──────────┘     └──────────────┘     └──────────────┘
                        │                     │
                        ▼                     ▼
                  验证 JWT 令牌          生成/刷新 JWT
                  传递用户信息           OAuth2 授权流程
```

- 采用 JWT + OAuth2 组合方案
- 网关层统一验证 JWT 令牌
- auth-service 负责令牌签发、刷新和 OAuth2 授权流程
- 微服务间通过传递 JWT 实现单点登录

---

## 4. 项目结构

### 4.1 目录结构

```
CloudStrollOffice/
├── pom.xml                          # 父 POM
├── docs/                            # 项目文档
├── cloudoffice-common/                 # 公共模块
├── cloudoffice-gateway/                # API 网关
├── cloudoffice-auth-service/           # 认证服务
├── cloudoffice-biz-service/            # 企业服务
├── cloudoffice-cloud-service/          # 云服务（已移除）
├── cloudoffice-system-service/         # 系统服务
├── .idea/                           # IDEA 配置文件
└── scripts/                         # 脚本文件
    ├── docker/                      # Docker 配置
    └── sql/                         # 数据库脚本
```

### 4.2 模块包结构

每个微服务模块遵循以下标准包结构：

```
org.cloudstrolling.cloudoffice.{module}
├── config/          # 配置类
├── controller/      # 控制器层
├── service/         # 业务逻辑层
│   └── impl/        # 业务实现类
├── mapper/          # 数据访问层
├── entity/          # 实体类
├── dto/             # 数据传输对象
├── vo/              # 视图对象
├── enums/           # 枚举类
├── exception/       # 异常处理
├── filter/          # 过滤器
├── interceptor/     # 拦截器
└── util/            # 工具类
```

---

## 5. 配置管理

### 5.1 配置中心 (Nacos)

所有微服务统一使用 Nacos 作为配置中心，配置按以下维度管理：

- **共享配置**: 所有服务共用的配置（数据源、Redis、RocketMQ 等）
- **服务配置**: 各服务独立的业务配置
- **环境配置**: dev / test / prod 多环境隔离

### 5.2 配置文件规范

```yaml
# bootstrap.yml (从 Nacos 加载配置)
spring:
  cloud:
    nacos:
      config:
        server-addr: ${NACOS_SERVER_ADDR:127.0.0.1:8848}
        namespace: ${NACOS_NAMESPACE:dev}
        group: ${NACOS_GROUP:DEFAULT_GROUP}
        file-extension: yaml
```

---

## 6. 数据库设计原则

- 每个微服务独立数据库，避免跨服务直接访问数据库
- 使用 MyBatis-Plus 进行 ORM 映射
- 数据库连接池使用 HikariCP
- 统一使用雪花算法生成主键 ID

---

## 7. 监控与可观测性

### 7.1 监控体系

| 组件 | 用途 |
|------|------|
| Prometheus | 指标采集与存储 |
| Grafana | 指标可视化 |
| SkyWalking | 分布式链路追踪 |

### 7.2 监控指标

- JVM 指标：内存、GC、线程
- 应用指标：QPS、响应时间、错误率
- 数据库指标：连接数、慢查询
- 缓存指标：命中率、内存使用

---

## 8. 安全设计

- 网关层统一进行身份认证和权限校验
- 采用 JWT 无状态令牌，支持令牌刷新
- 敏感数据加密存储（密码使用 BCrypt）
- API 接口防重放攻击
- SQL 注入防护（MyBatis-Plus 预编译）

---

## 9. 部署架构

### 9.1 部署方式

- 容器化部署 (Docker + Docker Compose)
- 支持 Kubernetes 编排部署

### 9.2 环境规划

| 环境 | 用途 | Nacos 命名空间 |
|------|------|----------------|
| dev | 开发环境 | dev |
| test | 测试环境 | test |
| prod | 生产环境 | prod |

---

## 10. 依赖版本汇总

| 依赖 | 版本 |
|------|------|
| Java | 21 |
| Spring Boot | 3.2.5 |
| Spring Cloud | 2023.0.1 |
| Spring Cloud Alibaba | 2023.0.1.0 |
| Nacos Client | 2.3.1 |
| MyBatis-Plus | 3.5.6 |
| RocketMQ Client | 5.1.4 |
| Redis (Lettuce) | 6.3.1 |
| Seata | 2.0.0 |
| SpringDoc | 2.5.0 |
| Hutool | 5.8.26 |
| Lombok | 1.18.32 |
| MariaDB Driver | 3.3.3 |
| SkyWalking Agent | 9.1.0 |

---

## 附录

### A. 命名规范

- 项目包名：`org.cloudstrolling.cloudbiz`
- 服务命名：`cloudbiz-{module}-service`
- 数据库表命名：`t_{module}_{table_name}`
- API 路径：`/api/v1/{module}/{resource}`

### B. 开发工具

- IDE：IntelliJ IDEA
- 代码管理：Git
- API 调试：Postman / Apifox
- 代码质量：SonarQube
