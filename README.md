# 云漫智企 - CloudStrollOffice

[![Java](https://img.shields.io/badge/Java-21-blue.svg)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2023.0.1-brightgreen.svg)](https://spring.io/projects/spring-cloud)
[![MyBatis-Plus](https://img.shields.io/badge/MyBatis--Plus-3.5.6-orange.svg)](https://baomidou.com/)
[![MariaDB](https://img.shields.io/badge/MariaDB-10.6-blue.svg)](https://mariadb.org/)
[![Nacos](https://img.shields.io/badge/Nacos-2.3.0-green.svg)](https://nacos.io/)
[![License](https://img.shields.io/badge/License-Apache%202.0-red.svg)](https://www.apache.org/licenses/LICENSE-2.0)

## 项目简介

**云漫智企 (CloudStrollOffice)** 是一个基于 **Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x** 技术栈构建的微服务企业办公套件。

项目采用 Maven 多模块架构，由认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）、API 网关（gateway）及公共模块（common）组成，为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。

当前版本 **v0.1.5** 已完整实现**登录认证与权限管理系统**：基于 RBAC 多租户权限模型（7 张数据库表），支持 6 种客户端类型（Windows/Ubuntu/H5/Android/iOS/WeChatMini）混合登录，同端互斥 + 多端共存；采用 JWT RS256 双 Token（Access Token 2h + Refresh Token 7d）配合 Redis 登录态管理；网关层 AuthFilter 全局认证拦截统一鉴权；完整覆盖登录/注册/登出/Token 刷新/强制踢人/封禁解封/用户角色权限管理/登录日志审计能力，351 个单元测试全部通过。

## 功能特性

| 特性 | 说明 |
|------|------|
| 微服务架构 | 5 个 Maven 模块，服务间解耦，独立开发、测试和部署 |
| RBAC 权限模型 | 用户-角色-权限三层关联，支持多租户数据隔离 |
| 多租户隔离 | 租户独立数据空间，用户名在租户内唯一，租户间数据不可见 |
| 多端混合登录 | 支持 6 种客户端类型（Windows/Ubuntu/H5/Android/iOS/WeChatMini）同端互斥、多端共存 |
| JWT RS256 双 Token | 非对称签名（RSA 2048 位），Access Token 2h + Refresh Token 7d，支持轮换机制 |
| Redis 会话管理 | 登录态会话 + Token 黑名单 + 账号/租户状态缓存，支持主动登出、强制踢人实时生效 |
| 网关全局认证 | Spring Cloud Gateway AuthFilter 统一拦截，9 步校验流程，用户信息 Header 透传 |
| 统一响应体 | `ApiResult<T>` 统一封装所有 REST 接口响应，含状态码、消息、数据和时间戳 |
| 分层异常体系 | `BaseException` → `BusinessException` / `AuthException`，29 个错误码全覆盖 |
| 全局异常处理 | `@RestControllerAdvice` 统一捕获 10+ 类异常，兜底不泄露堆栈信息 |
| Spring Security | BCrypt 密码编码器、无状态会话管理、自定义 401/403 JSON 响应 |
| 登录日志审计 | 记录登录 IP、客户端类型、登录结果、失败原因，支持安全事件追溯 |
| API 文档 | SpringDoc (OpenAPI 3) 自动生成，按模块分组，在线调试 |
| API 网关 | Spring Cloud Gateway，路由转发、CORS 跨域、Nacos 服务发现集成 |
| 服务注册发现 | Nacos 2.3.0 统一管理，各服务启动后自动注册 |
| 健康检查链路 | 所有业务服务提供 `/api/v1/{module}/health` 健康检查端点 |
| Docker 部署 | 多阶段构建镜像 + Docker Compose 一键编排 8 个容器 |
| 开发环境配置 | IDEA 运行配置、.editorconfig、Checkstyle、代码风格统一 |

## 项目架构

```
┌────────────────────────────────────────────────────────────────────────────┐
│                             客户端层 (Client)                               │
│          PC端 / H5 / Android / iOS / 微信小程序 / 第三方 API                 │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         API 网关层 (Gateway)                                │
│                    Spring Cloud Gateway（端口 9000）                         │
│       路由转发 │ CORS │ Nacos 服务发现 │ ⭐ AuthFilter 全局认证拦截            │
│        RS256 公钥验签 │ Redis 黑名单/登录态/状态校验 │ Header 透传            │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
┌────────────────────────┐ ┌────────────────┐ ┌────────────────────┐
│   认证服务 (v0.1.5)     │ │   企业服务       │ │   系统服务          │
│  auth-service (9100)   │ │ biz-service     │ │ system-service     │
│                        │ │  (9200)         │ │  (9400)            │
│  ⭐ 登录/注册/登出       │ │   企业信息管理    │ │  系统配置 │ 日志     │
│  ⭐ 双Token签发+轮换    │ │   人事管理       │ │  监控 │ 定时任务    │
│  ⭐ RBAC权限管理        │ │  v0.1.0 骨架     │ │  v0.1.4 完成搭建    │
│  ⭐ 角色/权限CRUD       │ │                 │ │                    │
│  ⭐ 登录日志审计        │ │                 │ │                    │
│  ⭐ 用户管理/封禁/踢人   │ │                 │ │                    │
└────────────────────────┘ └────────────────┘ └────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
┌────────────────────┐ ┌────────────────────┐
│    MariaDB 10.6    │ │   Redis 7.2.x      │
│    数据库层         │ │   缓存层            │
│  7 张 RBAC 业务表   │ │  登录态会话 │ 黑名单 │
│  用户/租户/角色/权限  │ │  账号状态 │ 租户状态 │
└────────────────────┘ └────────────────────┘
                                    │
┌────────────────────────────────────────────────────────────────────────────┐
│                              基础设施层                                     │
│                 Nacos 2.3.x (注册中心/配置中心) │ Docker Compose             │
└────────────────────────────────────────────────────────────────────────────┘
```

## 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 编程语言 | Java (OpenJDK) | 21 LTS |
| 应用框架 | Spring Boot | 3.2.5 |
| 微服务框架 | Spring Cloud | 2023.0.1 |
| 服务注册/配置 | Spring Cloud Alibaba - Nacos | 2023.0.1.0 / 2.3.0 |
| API 网关 | Spring Cloud Gateway | 内置于 Spring Cloud |
| ORM 框架 | MyBatis-Plus | 3.5.6 |
| 数据库 | MariaDB | 10.6 (LTS) |
| 连接池 | HikariCP | 5.x |
| 安全框架 | Spring Security | 内置于 Spring Boot |
| JWT 库 | JJWT (io.jsonwebtoken) | 0.12.6 |
| 缓存 | Redis (Spring Data Redis) | 7.2.x |
| API 文档 | SpringDoc (springdoc-openapi) | 2.5.0 |
| 工具库 | Hutool | 5.8.26 |
| JSON 处理 | Jackson | 2.16.x |
| 代码简化 | Lombok | 1.18.32 |
| 密码加密 | BCrypt (Spring Security Crypto) | 内置于 Spring Boot |
| 数据库驱动 | MariaDB Connector/J | 3.3.3 |
| 构建工具 | Maven | 3.9+ |
| 单元测试 | JUnit 5 + Mockito | 内置于 Spring Boot Starter Test |

## 模块说明

| 模块 | 端口 | 依赖 | 功能描述 |
|------|------|------|---------|
| `cloudoffice-common` | - | 无 | 公共模块：统一响应体 `ApiResult<T>`、分页响应 `PageResult<T>`、异常体系（`BaseException`/`BusinessException`/`AuthException`）、全局异常处理器 `GlobalExceptionHandler`、实体基类 `BaseEntity`、SpringDoc 配置、MyBatis-Plus 自动填充配置、JSON 工具类、TokenPairDTO/LoginUserDTO、ClientTypeEnum、RedisKeyConstants、29 个错误码（含 19 个认证授权错误码） |
| `cloudoffice-gateway` | 9000 | common, Nacos, Redis | API 网关：请求路由转发（3 条路由规则）、CORS 跨域配置、Nacos 服务发现集成、`AuthFilter` 全局认证过滤器（9 步校验流程：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传） |
| `cloudoffice-auth-service` | 9100 | common, Nacos, MyBatis-Plus, MariaDB, Redis | 认证服务：RBAC 多租户权限模型（7 张数据表）、6 种客户端类型混合登录（同端互斥 + 多端共存）、JWT RS256 双 Token（Access Token 2h + Refresh Token 7d + 轮换机制）、BCrypt 密码编码、Redis 登录态/黑名单/状态缓存管理、账号注册/登录/登出/Token 刷新/强制踢人/封禁解封、用户/角色/权限 CRUD 管理 API、登录日志审计 |
| `cloudoffice-biz-service` | 9200 | common, Nacos, MyBatis-Plus, MariaDB | 企业服务（骨架）：企业信息/人事管理业务骨架、健康检查接口 |
| `cloudoffice-system-service` | 9400 | common, Nacos, MyBatis-Plus, MariaDB | 系统服务（骨架）：系统配置/日志/监控/定时任务骨架、健康检查接口 |

## 快速开始

### 环境要求

| 环境 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 21+ (LTS) | 推荐 OpenJDK 21 或 Eclipse Temurin 21 |
| Maven | 3.9+ | 项目构建与依赖管理 |
| MariaDB | 10.6+ | 关系型数据库 |
| Redis | 7.2.x | 缓存（登录态会话、Token 黑名单、状态缓存） |
| Nacos | 2.3.x | 服务注册中心与配置中心 |
| Docker (可选) | 24+ | 容器化部署 |

### 1. 克隆项目

```bash
git clone https://github.com/your-org/CloudStrollOffice.git
cd CloudStrollOffice
```

### 2. 初始化数据库

```bash
# 确保 MariaDB 已启动并运行
# 执行 v0.1.5 认证服务数据库初始化脚本（7 张核心 RBAC 表 + 初始数据）
mariadb -u root -p < scripts/sql/auth-init-v0.1.5.sql

# 或使用通用初始化脚本（仅建库）
mariadb -u root -p < scripts/sql/init.sql
```

认证服务初始化脚本将创建 `cloudstroll_office_auth` 数据库及 7 张业务表：

| 表名 | 说明 | 关联 UserStory |
|------|------|---------------|
| `t_auth_tenant` | 租户表（多租户隔离） | US-007 |
| `t_auth_user` | 用户表（租户内登录名唯一） | US-006 |
| `t_auth_role` | 角色表（租户内编码唯一） | US-009 |
| `t_auth_permission` | 权限表（树形结构组织） | US-010 |
| `t_auth_user_role` | 用户-角色关联表（多对多） | US-011 |
| `t_auth_role_permission` | 角色-权限关联表（多对多） | US-012 |
| `t_auth_login_log` | 登录日志审计表 | US-022 |

脚本还包含初始数据：默认租户 `DEFAULT`、超级管理员角色 `SUPER_ADMIN`、管理员用户 `admin`（密码 `admin123`）及基础权限数据。

- `cloudstroll_office_biz` — 预留，仅建库不建表
- `cloudstroll_office_system` — 预留，仅建库不建表

### 3. 启动 Nacos

```bash
# 方式一：Docker 启动
docker run -d \
  --name nacos-server \
  -p 8848:8848 \
  -e MODE=standalone \
  nacos/nacos-server:v2.3.0

# 方式二：使用 Docker Compose（一并启动数据库等服务）
docker compose -f scripts/docker/docker-compose.yml up -d nacos mariadb
```

### 4. 配置文件说明

各服务的配置文件位于 `src/main/resources/` 目录下：

- `bootstrap.yml` — Nacos 注册中心地址配置（默认 `127.0.0.1:8848`，可通过 `NACOS_ADDR` 环境变量覆盖）
- `application.yml` — 服务端口、数据库连接、JWT 密钥等配置

关键环境变量：

| 变量名 | 默认值 | 适用服务 | 说明 |
|--------|--------|---------|------|
| `NACOS_ADDR` | `127.0.0.1:8848` | 全部 | Nacos 服务地址 |
| `DB_HOST` | `127.0.0.1` | auth/biz/system | 数据库主机地址 |
| `DB_PORT` | `3306` | auth/biz/system | 数据库端口 |
| `DB_USERNAME` | `root` | auth/biz/system | 数据库用户名 |
| `DB_PASSWORD` | `root` | auth/biz/system | 数据库密码 |
| `REDIS_HOST` | `127.0.0.1` | auth/gateway | Redis 主机地址 |
| `REDIS_PORT` | `6379` | auth/gateway | Redis 端口 |
| `REDIS_PASSWORD` | (空) | auth/gateway | Redis 密码 |
| `REDIS_DATABASE` | `0` | auth/gateway | Redis 数据库编号 |
| `RSA_PRIVATE_KEY` | (必填) | auth-service | RSA 私钥（Base64 编码），用于 JWT RS256 签名 |
| `RSA_PUBLIC_KEY` | (必填) | auth/gateway | RSA 公钥（Base64 编码），用于 JWT RS256 验签 |

> **RSA 密钥对生成：** 生产环境使用 OpenSSL 生成 RSA 2048 位密钥对：
> ```bash
> # 生成私钥并转换为 PKCS#8 格式
> openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem
>
> # 提取公钥
> openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem
>
> # 转换为 Base64（去掉 PEM 头尾和换行）
> base64 -w0 private_key.pem > private_key_base64.txt
> base64 -w0 public_key.pem > public_key_base64.txt
> ```

### 5. 编译项目

```bash
# 全量编译（跳过测试以加快速度）
mvn clean compile -DskipTests

# 编译并运行所有测试
mvn clean test

# 打包为 JAR
mvn clean package -DskipTests
```

### 6. 启动服务

**方式一：IDEA 一键启动**

在 IntelliJ IDEA 中，导航至 `Run` → `Edit Configurations`，选择目标服务的运行配置（已预置）并点击运行。建议按以下顺序启动：

1. Nacos 注册中心（外部启动）
2. GatewayApplication（端口 9000）
3. AuthApplication（端口 9100）
4. BizApplication（端口 9200）
5. SystemApplication（端口 9400）

**方式二：命令行启动**

```bash
# 启动网关
mvn spring-boot:run -pl cloudoffice-gateway

# 启动认证服务
mvn spring-boot:run -pl cloudoffice-auth-service

# 启动企业服务
mvn spring-boot:run -pl cloudoffice-biz-service

# 启动系统服务
mvn spring-boot:run -pl cloudoffice-system-service
```

**方式三：Docker Compose 一键部署（推荐）**

```bash
# 构建并启动所有服务（Nacos + MariaDB + Redis + 4 个微服务）
docker compose -f scripts/docker/docker-compose.yml up -d --build
```

### 7. 验证部署

各服务健康检查端点：

```bash
# 验证网关路由可用性
curl http://localhost:9000/api/v1/auth/health
curl http://localhost:9000/api/v1/biz/health
curl http://localhost:9000/api/v1/system/health

# 直接验证服务
curl http://localhost:9100/api/v1/auth/health
curl http://localhost:9200/api/v1/biz/health
curl http://localhost:9400/api/v1/system/health

# 查看 API 文档
open http://localhost:9100/swagger-ui.html
```

健康检查响应示例：

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

### 8. 验证认证 API（v0.1.5）

```bash
# 注册新用户
curl -X POST http://localhost:9000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "loginName": "newuser",
    "password": "Password123!",
    "userName": "新用户",
    "tenantCode": "DEFAULT"
  }'

# 登录获取 Token
curl -s -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "loginName": "admin",
    "password": "admin123",
    "tenantCode": "DEFAULT",
    "clientType": "H5"
  }' | jq .

# 使用 Access Token 访问需认证接口
TOKEN="<上一步返回的 accessToken>"
curl -s http://localhost:9000/api/v1/auth/users?page=1\&size=10 \
  -H "Authorization: Bearer $TOKEN" | jq .

# 刷新 Token
REFRESH_TOKEN="<登录返回的 refreshToken>"
curl -s -X POST http://localhost:9000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}" | jq .

# 登出
curl -s -X POST http://localhost:9000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## API 接口列表（v0.1.5）

### 认证接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 | 白名单 |
| POST | `/api/v1/auth/login` | 用户登录 | 白名单 |
| POST | `/api/v1/auth/refresh` | 刷新 Token | 白名单 |
| POST | `/api/v1/auth/logout` | 用户登出 | 需认证 |
| POST | `/api/v1/auth/kickout` | 强制踢人（管理员） | 需认证 |

### 用户管理接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/v1/auth/users` | 用户分页列表 | 需认证 |
| GET | `/api/v1/auth/users/{userId}` | 用户详情 | 需认证 |
| PUT | `/api/v1/auth/users/{userId}` | 更新用户信息 | 需认证 |
| PUT | `/api/v1/auth/users/{userId}/status` | 更新用户状态（封禁/解封） | 需认证 |
| PUT | `/api/v1/auth/users/{userId}/roles` | 分配用户角色 | 需认证 |
| DELETE | `/api/v1/auth/users/{userId}` | 删除用户 | 需认证 |

### 角色管理接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/v1/auth/roles` | 角色列表 | 需认证 |
| POST | `/api/v1/auth/roles` | 创建角色 | 需认证 |
| PUT | `/api/v1/auth/roles/{roleId}` | 更新角色 | 需认证 |
| DELETE | `/api/v1/auth/roles/{roleId}` | 删除角色 | 需认证 |
| PUT | `/api/v1/auth/roles/{roleId}/permissions` | 分配角色权限 | 需认证 |

### 权限管理接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/v1/auth/permissions` | 权限树形列表 | 需认证 |
| POST | `/api/v1/auth/permissions` | 创建权限 | 需认证 |
| PUT | `/api/v1/auth/permissions/{permId}` | 更新权限 | 需认证 |
| DELETE | `/api/v1/auth/permissions/{permId}` | 删除权限 | 需认证 |

### 健康检查

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/auth/health` | 认证服务健康检查 |
| GET | `/api/v1/biz/health` | 企业服务健康检查 |
| GET | `/api/v1/system/health` | 系统服务健康检查 |

## 开发指南

### IDEA 导入

1. 确保已安装 JDK 21 并配置 `JAVA_HOME` 环境变量
2. 安装 IntelliJ IDEA 2023.2+（推荐 Ultimate 版）
3. 安装以下插件：
   - **Lombok** — 必须安装，否则编译报错
   - **Alibaba Java Coding Guidelines** — 代码规范检查（可选但推荐）
   - **Spring Assistant** — Spring Boot 配置提示（可选）
4. 打开项目：`File` → `Open` → 选择项目根目录
5. IDEA 自动识别 Maven 项目，等待依赖下载完成
6. 运行配置已在 `.idea/runConfigurations/` 中预置，可直接使用

### 运行配置

IDEA 运行配置已预设于 `.idea/runConfigurations/` 目录下：

| 配置名称 | 对应模块 | 端口 | 启动类 |
|---------|---------|------|--------|
| `GatewayApplication` | cloudoffice-gateway | 9000 | `GatewayApplication` |
| `AuthApplication` | cloudoffice-auth-service | 9100 | `AuthApplication` |
| `BizApplication` | cloudoffice-biz-service | 9200 | `BizApplication` |
| `SystemApplication` | cloudoffice-system-service | 9400 | `SystemApplication` |

### 编译与测试

```bash
# 全量编译
mvn clean compile

# 运行所有测试
mvn clean test

# 运行指定模块测试
mvn clean test -pl cloudoffice-common
mvn clean test -pl cloudoffice-auth-service

# 打包
mvn clean package -DskipTests

# 查看依赖树
mvn dependency:tree

# 清除并强制更新快照依赖
mvn clean compile -U
```

### 代码风格

- 遵循《阿里巴巴 Java 开发手册》，配置了 `checkstyle.xml` 和 `.editorconfig`
- 缩进使用 4 个空格，禁止使用 Tab
- 文件编码统一 UTF-8
- 行宽不超过 120 字符
- 大括号风格采用 K&R 风格
- 使用 Lombok 减少样板代码（`@Data`、`@Slf4j`、`@Builder` 等）
- 统一使用构造器注入替代 `@Autowired` 字段注入
- API 路径规范：`/api/v1/{module}/{resource}`

## 项目结构

```
CloudStrollOffice/
├── pom.xml                         # 父 POM，统一依赖管理
├── opencode.json                   # OpenCode AI 开发工具配置
├── .editorconfig                   # 跨编辑器代码风格配置
├── checkstyle.xml                  # Checkstyle 规则配置
├── .gitignore                      # Git 忽略规则
│
├── cloudoffice-common/             # 公共模块（JAR 包，无启动类）
│   └── src/main/java/org/cloudstrolling/cloudoffice/common/
│       ├── config/                 # MyBatis-Plus 配置、SpringDoc 配置
│       │   ├── MyBatisPlusConfig.java
│       │   └── SpringDocConfig.java
│       ├── exception/              # 异常定义
│       │   ├── ErrorCode.java      # 错误码枚举
│       │   ├── BaseException.java  # 异常基类
│       │   ├── BusinessException.java
│       │   ├── AuthException.java
│       │   └── GlobalExceptionHandler.java
│       ├── model/                  # 公共模型
│       │   ├── ErrorCode.java      # 错误码接口
│       │   ├── ApiResult.java      # 统一响应体
│       │   ├── BaseEntity.java     # 实体基类
│       │   └── PageResult.java     # 分页响应
│       └── util/
│           └── JsonUtils.java      # JSON 工具类
│
├── cloudoffice-gateway/            # API 网关（端口 9000）
│   └── src/main/java/org/cloudstrolling/cloudoffice/gateway/
│       ├── GatewayApplication.java # 启动类
│       ├── config/                 # RsaKeyConfig, RedisConfig, AuthProperties
│       └── filter/
│           └── AuthFilter.java     # 全局认证过滤器（9 步校验 + Header 透传）
│
├── cloudoffice-auth-service/       # 认证服务（端口 9100，v0.1.5 完整认证）
│   └── src/main/java/org/cloudstrolling/cloudoffice/auth/
│       ├── AuthApplication.java    # 启动类
│       ├── config/                 # SecurityConfig, RsaKeyConfig, RedisConfig, MyBatisPlusConfig
│       ├── controller/
│       │   ├── AuthController.java    # 登录/注册/登出/刷新/踢人 5 个端点
│       │   ├── UserController.java    # 用户 CRUD + 状态管理 + 角色分配
│       │   ├── RoleController.java    # 角色 CRUD + 权限分配
│       │   ├── PermissionController.java  # 权限树 CRUD
│       │   └── HealthController.java
│       ├── entity/                 # 7 个实体类（User/Tenant/Role/Permission/UserRole/RolePermission/LoginLog）
│       ├── dto/                    # 7 个请求 DTO
│       ├── mapper/                 # 7 个 Mapper 接口
│       ├── service/
│       │   ├── LoginService.java / impl      # 登录认证（13 步完整流程）
│       │   ├── LoginSessionService.java/impl # Redis 会话管理
│       │   ├── LoginLogService.java/impl     # 登录日志审计
│       │   ├── TokenService.java/impl        # 双 Token 签发 + 轮换
│       │   ├── UserService.java/impl         # 用户管理
│       │   ├── RoleService.java/impl         # 角色管理
│       │   └── PermissionService.java/impl   # 权限管理
│       └── util/
│           ├── JwtUtils.java         # JWT RS256 双 Token 工具类
│           └── ...
│
├── cloudoffice-biz-service/        # 企业服务（端口 9200）
│   └── src/main/java/org/cloudstrolling/cloudoffice/biz/
│       ├── BizApplication.java     # 启动类
│       ├── config/
│       └── controller/
│           └── HealthController.java
│
├── cloudoffice-system-service/     # 系统服务（端口 9400）
│   └── src/main/java/org/cloudstrolling/cloudoffice/system/
│       ├── SystemApplication.java  # 启动类
│       ├── config/
│       └── controller/
│           └── HealthController.java
│
├── docs/                           # 项目文档
│   ├── project.md                  # 项目信息、编码规范、项目地图
│   ├── architecture.md             # 架构文档
│   ├── dbd.md                      # 数据库设计文档
│   ├── sds/                        # 技术规格说明书
│   ├── prds/                       # PRD 文档
│   ├── requires/                   # 需求文档
│   ├── origin-requires/            # 原始需求文档
│   └── prompts/                    # AI 交互历史记录
│
└── scripts/                        # 脚本与模板
    ├── sql/
    │   ├── init.sql                # 通用数据库初始化脚本（仅建库）
    │   └── auth-init-v0.1.5.sql    # 认证服务 v0.1.5 数据库初始化（7 表 + 初始数据）
    └── docker/
        ├── docker-compose.yml      # Docker Compose 编排（8 个容器）
        ├── gateway/Dockerfile
        ├── auth-service/Dockerfile
        ├── biz-service/Dockerfile
        └── system-service/Dockerfile
```

## 端口分配

| 服务 | 端口 | 说明 |
|------|------|------|
| cloudoffice-gateway | 9000 | API 网关 |
| cloudoffice-auth-service | 9100 | 认证服务 |
| cloudoffice-biz-service | 9200 | 企业服务 |
| cloudoffice-system-service | 9400 | 系统服务 |
| Nacos Server | 8848 | 注册中心 & 配置中心 |
| MariaDB | 3306 | 关系型数据库 |
| Redis | 6379 | 缓存（登录态/黑名单/状态缓存） |

## 部署架构

生产环境推荐部署方式：

```
[负载均衡器（Nginx/ALB）] ──▶ [Gateway 实例集群] ──▶ [各微服务多实例]
                                │
                                ├──▶ [auth-service:9100] ──▶ [MariaDB:3306]
                                │                         └──▶ [Redis:6379]
                                ├──▶ [biz-service:9200]  ──▶ [MariaDB:3306]
                                ├──▶ [system-service:9400] ──▶ [MariaDB:3306]
                                │
                                └──▶ [Nacos Cluster:8848] ──▶ [Nacos Cluster]
```

## 版本规划

| 版本 | 阶段 | 计划内容 |
|------|------|---------|
| v0.1.5 | 登录认证与权限管理 ✅ | RBAC 多租户权限模型（7 表）、6 种客户端混合登录、JWT RS256 双 Token、Redis 登录态管理、网关 AuthFilter 全局认证、登录日志审计、用户/角色/权限管理 API、351 个单元测试 |
| v0.1.4 | 系统服务搭建 ✅ | 系统服务模块（cloudoffice-system-service）完整骨架、健康检查端点、单元测试、Docker 部署配置 |
| v0.1.0 | 基础骨架搭建 ✅ | Maven 多模块架构、公共组件、API 网关、认证服务骨架、业务服务骨架、Docker 部署模板 |
| v0.2.0 | 基础功能 | 企业/部门/员工 CRUD、系统配置管理、消息通知 |
| v0.3.0 | 核心业务 | 工作流审批、考勤管理、云资源管理、消息队列集成 |
| v0.4.0 | 高级功能 | 薪酬管理、报表统计、审计日志、定时任务、缓存集成 |

## 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：
- `feat:` — 新功能
- `fix:` — 缺陷修复
- `docs:` — 文档变更
- `refactor:` — 重构
- `test:` — 测试
- `chore:` — 构建/工具

## 许可证

本项目基于 Apache License 2.0 许可证开源。

```
Copyright 2026 CloudStrolling/jenemy8023

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
