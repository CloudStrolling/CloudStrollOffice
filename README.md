# 云漫智企 - CloudStrollOffice

[![Java](https://img.shields.io/badge/Java-21-blue.svg)](https://openjdk.org/projects/jdk/21/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2023.0.1-brightgreen.svg)](https://spring.io/projects/spring-cloud)
[![MyBatis-Plus](https://img.shields.io/badge/MyBatis--Plus-3.5.6-orange.svg)](https://baomidou.com/)
[![MariaDB](https://img.shields.io/badge/MariaDB-10.6-blue.svg)](https://mariadb.org/)
[![Nacos](https://img.shields.io/badge/Nacos-2.3.0-green.svg)](https://nacos.io/)
[![Flutter](https://img.shields.io/badge/Flutter-3.12.2-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/License-Apache%202.0-red.svg)](https://www.apache.org/licenses/LICENSE-2.0)

## 项目简介

**云漫智企 (CloudStrollOffice)** 是一个基于 **Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x** 技术栈构建的微服务企业办公套件，配套 **Flutter 多端客户端**（支持 Web 与 Windows 双平台）。

项目采用 Maven 多模块架构，由认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）、API 网关（gateway）及公共模块（common）组成，为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。

当前版本 **v0.2.6** 完成**部署与配置缺陷修复**（依据 `docs/cso-v0.2.5/regression-api-test.md` 记录的问题）：① **bootstrap 依赖修复**（ADR-014）——根 pom 与 gateway/auth/biz/system 四个服务模块 pom 统一引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载，消除 `No spring.config.import property has been defined`；② **RSA 密钥格式契约修复**（ADR-015）——`deploy-rsa-keygen.ps1` 输出与 `deploy/env.json` 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64，与 Java 端 RsaKeyConfig 解码契约严格一致，消除网关 `RSA 公钥解析失败`；③ **SecurityConfig 白名单修复**（TASK-004）——permitAll 增补 login/register/refresh 三端点、注册全局异常处理器并映射 409/429/403 状态码等契约行为对齐。修复后 4 个服务全部正常启动，**API 回归测试全量跑通**：TC-001~051 全量 PASS=72、FAIL=0、SKIP=0（v0.0.1 基线接口契约 API-001~033 动态回归闭环 + v0.2.5 契约无回归复核），接口层零改动、客户端无需任何修改。

上一版本 **v0.2.5** 完成**部署资产集中化**：新建统一的 `deploy` 目录作为所有最终构建产物（后端 jar 包、客户端安装文件/exe）与部署资产（env.json、env.example.json、全部 .sh/.ps1 部署运维脚本）的唯一落点；修改 Maven 各模块与 Flutter 客户端构建配置，使最终产物统一输出到 `deploy` 目录，中间产物（target 等）不进入 deploy；根目录 `scripts` 下仅保留 docker、sql、API-TEST、部署指南等非脚本内容。

再上一版本 **v0.1.6** 在 v0.1.5 RBAC 权限体系基础上新增**用户认证增强**能力：多模式登录（用户名密码/手机验证码/手机+密码/OAuth）与多模式注册（用户名密码/手机验证码/OAuth）；两步注册机制（先注册后补全信息）；密码管理（修改密码/密码找回）；手机号变更（原手机可用→短信验证，原手机停用→邮箱验证）；验证码管理（生成/发送/校验/频率控制）。新增 2 张数据库表（OAuth 账号关联表、验证码记录表），用户表扩展 5 个字段，206 个单元测试全部通过。

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
| 多模式登录 | 4 种登录方式（用户名密码/手机验证码/手机+密码/OAuth），策略工厂模式编排 |
| 多模式注册 | 3 种注册方式（用户名密码/手机验证码/OAuth），含两步注册（先注册后补全信息） |
| 密码管理 | 修改密码（旧密码校验）和密码找回（验证码重置），重置后自动清除所有登录态 |
| 手机号变更 | 原手机可用时短信验证变更，原手机停用时邮箱验证变更 |
| 验证码管理 | 验证码生成、发送（模拟/真实）、校验、频率控制（60 秒间隔）和生命周期管理 |
| Flutter 客户端 | 独立客户端工程，支持 Web 与 Windows 双平台，dio 网络层 + provider 状态管理 + go_router 路由 |
| API 文档 | SpringDoc (OpenAPI 3) 自动生成，按模块分组，在线调试 |
| API 网关 | Spring Cloud Gateway，路由转发、CORS 跨域、Nacos 服务发现集成 |
| 服务注册发现 | Nacos 2.3.0 统一管理，各服务启动后自动注册 |
| 健康检查链路 | 所有业务服务提供 `/api/v1/{module}/health` 健康检查端点 |
| 部署资产集中化 | `deploy` 目录统一存放最终产物（jar/客户端安装包）、环境配置与部署脚本，中间产物严格隔离（v0.2.5） |
| bootstrap 配置引导 | 全项目 pom 统一引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路（v0.2.6 / ADR-014） |
| RSA 密钥契约统一 | `deploy-rsa-keygen.ps1` 输出与 `env.json` 注入值统一为 DER 编码单行 Base64，与 Java 端解码契约严格一致，消除网关公钥解析失败（v0.2.6 / ADR-015） |
| API 回归闭环 | v0.0.1 基线接口回归（TC-001~045）全部动态执行通过，接口契约 API-001~033 静态+动态双重确认无回归（v0.2.6） |
| Docker 部署 | 多阶段构建镜像 + Docker Compose 一键编排 8 个容器 |
| 开发环境配置 | IDEA 运行配置、.editorconfig、Checkstyle、代码风格统一 |

## 项目架构

```
┌────────────────────────────────────────────────────────────────────────────┐
│                             客户端层 (Client)                               │
│          PC端 / H5 / Android / iOS / 微信小程序 / 第三方 API                 │
│          ┌─────────────────────────────────────────────────────┐           │
│          │  Flutter 客户端 (cloudoffice-flutter-app)            │           │
│          │  Web / Windows 双平台，产物输出至 deploy/            │           │
│          └─────────────────────────────────────────────────────┘           │
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
│   认证服务 (v0.1.6)     │ │   企业服务       │ │   系统服务          │
│  auth-service (9100)   │ │ biz-service     │ │ system-service     │
│                        │ │  (9200)         │ │  (9400)            │
│  ⭐ 4种登录策略(SP工厂)   │ │  企业信息管理    │ │  系统配置 │ 日志     │
│  ⭐ 5种注册策略(SP工厂)   │ │  人事管理       │ │  监控 │ 定时任务    │
│  ⭐ 两步注册/账号补全     │ │  v0.1.0 骨架     │ │  v0.1.4 完成搭建    │
│  ⭐ 密码管理/密码找回     │ │                 │ │                    │
│  ⭐ 手机号变更           │ │                 │ │                    │
│  ⭐ 验证码管理/频率控制   │ │                 │ │                    │
│  ⭐ 认证编排(AuthenticationService)│ │                 │ │                    │
└────────────────────────┘ └────────────────┘ └────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
┌────────────────────┐ ┌────────────────────┐
│    MariaDB 10.6    │ │   Redis 7.2.x      │
│    数据库层         │ │   缓存层            │
│  9 张认证业务表     │ │  登录态会话 │ 黑名单 │
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
| 客户端语言 | Dart | 3 (Flutter SDK ^3.12.2) |
| 客户端框架 | Flutter | 3.x（Web / Windows 双平台） |

## 模块说明

| 模块 | 端口 | 依赖 | 功能描述 |
|------|------|------|---------|
| `cloudoffice-common` | - | 无 | 公共模块：统一响应体 `ApiResult<T>`、分页响应 `PageResult<T>`、异常体系（`BaseException`/`BusinessException`/`AuthException`）、全局异常处理器 `GlobalExceptionHandler`、实体基类 `BaseEntity`、SpringDoc 配置、MyBatis-Plus 自动填充配置、JSON 工具类、TokenPairDTO/LoginUserDTO、ClientTypeEnum/LoginModeEnum（4种登录模式）/RegisterModeEnum（5种注册模式）/OAuthProviderEnum（4种OAuth提供商）、RedisKeyConstants（含验证码前缀常量）、29 个错误码 |
| `cloudoffice-gateway` | 9000 | common, Nacos, Redis | API 网关：请求路由转发（3 条路由规则）、CORS 跨域配置、Nacos 服务发现集成、`AuthFilter` 全局认证过滤器（9 步校验流程：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传） |
| `cloudoffice-auth-service` | 9100 | common, Nacos, MyBatis-Plus, MariaDB, Redis | 认证服务：RBAC 多租户权限模型（7 张数据表）+ OAuth 账号关联表 + 验证码记录表（共 9 表）；6 种客户端类型混合登录（同端互斥 + 多端共存）；JWT RS256 双 Token（Access Token 2h + Refresh Token 7d + 轮换机制）；BCrypt 密码编码；多模式登录（4 种：用户名密码/手机验证码/手机+密码/OAuth，LoginStrategy 策略工厂模式）；多模式注册（5 种：用户名密码/手机验证码/OAuth/手机号设用户名/OAuth补全信息，RegisterStrategy 策略工厂模式 + 两步注册机制）；认证编排服务 AuthenticationService（统一编排登录/注册流程）；密码管理（修改密码/密码找回重置，重置后自动清除所有登录态）；手机号变更（原手机可用→短信验证，原手机停用→邮箱验证）；验证码管理（VerificationCodeManager 生成/校验/频率控制 + VerificationCodeService 发送，模拟模式 mock）；Redis 登录态/黑名单/状态缓存管理；用户/角色/权限 CRUD 管理 API；登录日志审计 |
| `cloudoffice-biz-service` | 9200 | common, Nacos, MyBatis-Plus, MariaDB | 企业服务（骨架）：企业信息/人事管理业务骨架、健康检查接口 |
| `cloudoffice-system-service` | 9400 | common, Nacos, MyBatis-Plus, MariaDB | 系统服务（骨架）：系统配置/日志/监控/定时任务骨架、健康检查接口 |
| `cloudoffice-flutter-app` | - | dio / provider / go_router 等 | Flutter 客户端（独立工程）：Web + Windows 双平台；登录/注册/忘记密码/首页等页面；AuthProvider 认证状态管理；ApiClient 网络封装（Token 注入、401 自动刷新、白名单）；SecureStorage Token 安全存储 |

## 快速开始

### 环境要求

| 环境 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 21+ (LTS) | 推荐 OpenJDK 21 或 Eclipse Temurin 21 |
| Maven | 3.9+ | 项目构建与依赖管理 |
| MariaDB | 10.6+ | 关系型数据库 |
| Redis | 7.2.x | 缓存（登录态会话、Token 黑名单、状态缓存） |
| Nacos | 2.3.x | 服务注册中心与配置中心 |
| Flutter | 3.x (SDK ^3.12.2) | 客户端构建（可选，仅客户端开发需要） |
| Docker (可选) | 24+ | 容器化部署 |

### 1. 克隆项目

```bash
git clone https://github.com/your-org/CloudStrollOffice.git
cd CloudStrollOffice
```

### 2. 初始化数据库

```bash
# 确保 MariaDB 已启动并运行
# 执行 v0.1.5 基础初始化脚本（7 张核心 RBAC 表 + 初始数据）
mariadb -u root -p < scripts/sql/auth-init-v0.1.5.sql

# 执行 v0.1.6 增量初始化脚本（OAuth 账号关联表 + 验证码记录表 + 用户表扩展字段）
mariadb -u root -p < scripts/sql/auth-init-v0.1.6.sql

# 或使用通用初始化脚本（仅建库）
mariadb -u root -p < scripts/sql/init.sql
```

认证服务初始化脚本将创建 `cloudstroll_office_auth` 数据库及 9 张业务表：

| 表名 | 说明 | 关联 UserStory |
|------|------|---------------|
| `t_auth_tenant` | 租户表（多租户隔离） | US-007 |
| `t_auth_user` | 用户表（租户内登录名唯一） | US-006 |
| `t_auth_role` | 角色表（租户内编码唯一） | US-009 |
| `t_auth_permission` | 权限表（树形结构组织） | US-010 |
| `t_auth_user_role` | 用户-角色关联表（多对多） | US-011 |
| `t_auth_role_permission` | 角色-权限关联表（多对多） | US-012 |
| `t_auth_login_log` | 登录日志审计表 | US-022 |
| `t_auth_oauth_account` | OAuth 第三方账号关联表（v0.1.6） | US-011 |
| `t_auth_verification_code` | 验证码记录表（v0.1.6） | US-012 |

v0.1.6 增量脚本在 v0.1.5 基础上新增以上 2 张表，并通过 ALTER TABLE 为 `t_auth_user` 表扩展 5 个字段（`register_mode`、`account_settled`、`phone_verified`、`email_verified`、`last_password_change_time`）。

脚本还包含初始数据：默认租户 `DEFAULT`、超级管理员角色 `SUPER_ADMIN`、管理员用户 `admin`（密码 `admin123`）及基础权限数据。

> **v0.2.6 数据库对齐说明：** 回归测试中发现数据库与代码/DBD 契约存在脱节（数据库按旧脚本初始化），已在运行环境按 `docs/cso-dbd.sql` 最新契约补齐（均为加列/改约束，未破坏既有数据与索引）：`t_auth_user` 补 `lock_reason` 列、`t_auth_login_log`/`t_auth_user_role`/`t_auth_role_permission` 补 `update_time`、`deleted` 列、`t_auth_user.password` 允许 NULL（PHONE_CODE/OAuth 注册无密码模式）、admin 密码修正为 admin123 的 BCrypt hash。后续版本建议同步历史初始化脚本（`scripts/sql/init-v0.2.0-full.sql` 等）。

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

### 4. 环境配置与部署脚本（v0.2.5 起位于 deploy 目录）

自 **v0.2.5** 起，环境配置与部署运维脚本统一收拢至 `deploy` 目录：

| 资产 | 位置 | 说明 |
|------|------|------|
| 环境配置 | `deploy/env.json` / `deploy/env.example.json` | 实际环境配置与模板（数据库、Redis、RSA 密钥等） |
| 部署脚本 | `deploy/scripts/` | 全部 .sh/.ps1 部署运维脚本（环境检查、DB 初始化、RSA 密钥生成、服务启停、load-env 等） |
| 最终产物 | `deploy/` | 后端 jar 包（auth/biz/system/gateway）、客户端安装产物（cloudoffice-flutter-app/） |

```bash
# 从模板生成环境配置
cd deploy/scripts
./deploy-env.sh          # 或 PowerShell: .\deploy-env.ps1
```

各服务的配置文件位于各模块 `src/main/resources/` 目录下：

- `bootstrap.yml` — Nacos 注册中心地址配置（默认 `127.0.0.1:8848`，可通过 `NACOS_ADDR` 环境变量覆盖）
- `application.yml` — 服务端口、数据库连接、JWT 密钥等配置

关键环境变量（详见 `deploy/env.example.json`）：

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
| `RSA_PRIVATE_KEY` | (必填) | auth-service | RSA 私钥（DER 编码单行 Base64），用于 JWT RS256 签名 |
| `RSA_PUBLIC_KEY` | (必填) | auth/gateway | RSA 公钥（DER 编码单行 Base64），用于 JWT RS256 验签 |
| `VERIFICATION_CODE_MOCK` | `true` | auth-service | 验证码模拟模式（true=直接返回固定验证码，false=真实发送） |
| `VERIFICATION_CODE_EXPIRE_SECONDS` | `300` | auth-service | 验证码过期时间（秒），默认 5 分钟 |
| `VERIFICATION_CODE_SEND_INTERVAL` | `60` | auth-service | 验证码发送间隔（秒），默认 60 秒 |
| `VERIFICATION_CODE_LENGTH` | `6` | auth-service | 验证码长度（数字位数） |
| `PASSWORD_MIN_LENGTH` | `8` | auth-service | 密码最小长度 |
| `PASSWORD_MAX_LENGTH` | `64` | auth-service | 密码最大长度 |

> **RSA 密钥对生成（v0.2.6 契约）：** 生产环境使用 `deploy/scripts/deploy-rsa-keygen.sh`（或 .ps1）自动生成。v0.2.6 起（ADR-015），脚本输出与 `env.json` 注入值统一为 **DER 编码单行 Base64**（无 PEM 头尾、无换行），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致；手动生成时请按以下方式转换：
> ```bash
> # 生成私钥并转换为 PKCS#8 DER 格式
> openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER -out private_key.der
>
> # 提取公钥（DER 格式）
> openssl pkey -in private_key.der -pubout -outform DER -out public_key.der
>
> # 转换为单行 Base64
> base64 -w0 private_key.der > private_key_base64.txt
> base64 -w0 public_key.der > public_key_base64.txt
> ```
> 注意：**禁止**将含 PEM 头尾（`-----BEGIN/END-----`）或换行的多行 Base64 直接注入 `env.json`，否则网关启动报 `RSA 公钥解析失败`。

### 5. 编译项目

```bash
# 全量编译（跳过测试以加快速度）
mvn clean compile -DskipTests

# 编译并运行所有测试
mvn clean test

# 打包为 JAR（最终 jar 将输出到 deploy 目录，v0.2.5 起）
mvn clean package -DskipTests
```

> **v0.2.5 说明：** 构建完成后，auth-service、biz-service、system-service、gateway 的最终可执行 jar 包统一出现在 `deploy` 目录，无需在各模块 target 目录中查找。

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

**方式四：deploy/scripts 脚本启动（v0.2.5 起）**

```bash
# 在 deploy/scripts 下执行
./deploy-start-services.sh    # 一键启动全部服务（或 .\deploy-start-services.ps1）
./deploy-start-auth.sh        # 单独启动认证服务
./deploy-start-biz.sh         # 单独启动企业服务
./deploy-start-system.sh      # 单独启动系统服务
./deploy-start-gateway.sh     # 单独启动网关
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

### 8. 验证认证 API（v0.1.6 能力，v0.2.5/v0.2.6 均无接口变更）

```bash
# 注册新用户（用户名密码模式）
curl -X POST http://localhost:9000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "loginName": "newuser",
    "password": "Password123!",
    "userName": "新用户",
    "tenantCode": "DEFAULT",
    "registerMode": "USERNAME"
  }'

# 注册新用户（手机验证码模式）
curl -X POST http://localhost:9000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "code": "123456",
    "tenantCode": "DEFAULT",
    "registerMode": "PHONE_CODE"
  }'

# 登录获取 Token（用户名密码）
curl -s -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "loginName": "admin",
    "password": "admin123",
    "tenantCode": "DEFAULT",
    "clientType": "H5",
    "loginMode": "USERNAME_PASSWORD"
  }' | jq .

# 登录获取 Token（手机验证码）
curl -s -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "code": "123456",
    "tenantCode": "DEFAULT",
    "clientType": "H5",
    "loginMode": "PHONE_CODE"
  }' | jq .

# 发送验证码
curl -s -X POST http://localhost:9000/api/v1/auth/verification-code/send \
  -H "Content-Type: application/json" \
  -d '{
    "target": "13800138000",
    "mode": "SMS",
    "purpose": "LOGIN"
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

# 修改密码
curl -s -X PUT http://localhost:9000/api/v1/auth/password/change \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "oldPassword": "admin123",
    "newPassword": "NewPass123!"
  }' | jq .

# 密码找回 - 发送验证码
curl -s -X POST http://localhost:9000/api/v1/auth/password/forgot/send-code \
  -H "Content-Type: application/json" \
  -d '{
    "target": "13800138000",
    "mode": "SMS"
  }' | jq .

# 密码找回 - 重置密码
curl -s -X POST http://localhost:9000/api/v1/auth/password/forgot/reset \
  -H "Content-Type: application/json" \
  -d '{
    "target": "13800138000",
    "mode": "SMS",
    "code": "123456",
    "newPassword": "NewPass123!"
  }' | jq .

# 修改手机号
curl -s -X PUT http://localhost:9000/api/v1/auth/phone/change \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "oldPhone": "13800138000",
    "newPhone": "13900139000",
    "code": "123456"
  }' | jq .

# 完善账号信息（两步注册第二步）
curl -s -X PUT http://localhost:9000/api/v1/auth/account/settlement \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "userId": 1,
    "loginName": "newuser",
    "password": "Password123!",
    "phone": "13800138000"
  }' | jq .

# 登出
curl -s -X POST http://localhost:9000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN" | jq .
```

## API 接口列表（v0.1.6 完整接口；v0.2.5 为工程目录调整、v0.2.6 为配置/依赖修复，均无接口变更）

### 认证接口

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册（支持 5 种注册模式） | 白名单 |
| POST | `/api/v1/auth/login` | 用户登录（支持 4 种登录模式） | 白名单 |
| POST | `/api/v1/auth/refresh` | 刷新 Token | 白名单 |
| POST | `/api/v1/auth/logout` | 用户登出 | 需认证 |
| POST | `/api/v1/auth/kickout` | 强制踢人（管理员） | 需认证 |
| POST | `/api/v1/auth/verification-code/send` | 发送验证码（支持短信/邮箱） | 白名单 |
| POST | `/api/v1/auth/password/forgot/send-code` | 密码找回-发送验证码 | 白名单 |
| POST | `/api/v1/auth/password/forgot/reset` | 密码找回-重置密码 | 白名单 |
| PUT | `/api/v1/auth/password/change` | 修改密码 | 需认证 |
| PUT | `/api/v1/auth/phone/change` | 修改手机号 | 需认证 |
| PUT | `/api/v1/auth/account/settlement` | 完善账号信息（两步注册第二步） | 需认证 |

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

# 打包（最终 jar 输出到 deploy 目录，v0.2.5 起）
mvn clean package -DskipTests

# 客户端构建（Flutter，产物输出到 deploy/cloudoffice-flutter-app）
cd cloudoffice-flutter-app
flutter build web
flutter build windows

# 查看依赖树
mvn dependency:tree

# 清除并强制更新快照依赖
mvn clean compile -U
```

### API 回归测试（v0.2.6 全量跑通）

服务全部启动后，可执行接口回归脚本验证接口契约（v0.2.6 回归结果：TC-001~051 全量 PASS=72、FAIL=0、SKIP=0）：

```bash
# v0.0.1 基线接口契约回归（TC-001~045，需 Python 3 + requests，网关 9000 可达）
python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000

# v0.2.5 契约无回归复核（TC-046~051，断言级）
python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>

# v0.2.6 版本级统一入口（TC-052~076，覆盖依赖/密钥/构建/契约断言）
python scripts/API-TEST/cso-api-test-v0.2.6.py <项目根>
```

> 注意：`cso-api-test-v0.2.6.py` 中 TC-052-4/TC-054-4 为版本级 git 变更清单断言，在相关文件已提交入库后不再出现在工作区变更清单，该断言会按约定失效（已登记，非代码缺陷），不影响验收结论。

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
│       ├── constant/               # RedisKeyConstants（Redis Key 常量）
│       ├── dto/                    # LoginUserDTO、TokenPairDTO
│       ├── enums/                  # ClientTypeEnum、LoginModeEnum、RegisterModeEnum、OAuthProviderEnum
│       ├── exception/              # 异常定义（ErrorCode、BaseException、GlobalExceptionHandler 等）
│       ├── model/                  # 公共模型（ApiResult、PageResult、BaseEntity）
│       └── util/                   # JsonUtils
│
├── cloudoffice-gateway/            # API 网关（端口 9000）
│   └── src/main/java/org/cloudstrolling/cloudoffice/gateway/
│       ├── GatewayApplication.java # 启动类
│       ├── config/                 # RsaKeyConfig, RedisConfig, AuthProperties
│       └── filter/
│           └── AuthFilter.java     # 全局认证过滤器（9 步校验 + Header 透传）
│
├── cloudoffice-auth-service/       # 认证服务（端口 9100，v0.1.6 用户认证增强）
│   └── src/main/java/org/cloudstrolling/cloudoffice/auth/
│       ├── AuthApplication.java    # 启动类
│       ├── config/                 # SecurityConfig、RsaKeyConfig、RedisConfig、PasswordProperties 等
│       ├── controller/             # AuthController（12 端点）、UserController、RoleController、PermissionController、HealthController
│       ├── entity/                 # 9 个实体类
│       ├── dto/                    # 12 个请求 DTO + 2 个结果 DTO
│       ├── mapper/                 # 9 个 Mapper 接口
│       ├── service/                # AuthenticationService、LoginService、TokenService、PasswordService、验证码服务、用户/角色/权限服务等
│       ├── strategy/               # login（4 策略）、register（5 策略）
│       └── util/                   # JwtUtils
│
├── cloudoffice-biz-service/        # 企业服务（端口 9200，骨架）
├── cloudoffice-system-service/     # 系统服务（端口 9400，骨架）
│
├── cloudoffice-flutter-app/        # Flutter 客户端（Web + Windows 双平台）
│   ├── lib/
│   │   ├── main.dart / app.dart    # 入口与根组件
│   │   ├── config/                 # ApiConfig、ThemeConfig
│   │   ├── core/                   # http（ApiClient/ApiInterceptor）、router、storage、utils
│   │   ├── features/               # auth（login/register/forgot）、home
│   │   └── shared/                 # constants、widgets
│   └── test/                       # 27 个测试文件
│
├── deploy/                         # 部署资产集中化目录（v0.2.5 起）
│   ├── cloudoffice-auth-service.jar     # 认证服务最终 jar 包
│   ├── cloudoffice-biz-service.jar      # 企业服务最终 jar 包
│   ├── cloudoffice-system-service.jar   # 系统服务最终 jar 包
│   ├── cloudoffice-gateway.jar          # 网关最终 jar 包
│   ├── cloudoffice-flutter-app/         # 客户端构建产物（web/、windows/）
│   ├── env.json / env.example.json      # 环境配置与模板（RSA 密钥为 DER 单行 Base64，v0.2.6 契约）
│   └── scripts/                         # 部署运维脚本（.sh/.ps1，13 组）
│
├── docs/                           # 项目文档
│   ├── project.md                  # 项目信息、编码规范、项目地图
│   ├── sad.md                      # 系统架构设计文档
│   ├── cso-urs.md / cso-prd.md / cso-api.md / cso-dbd.md / cso-dbd.sql / cso-lld.md / cso-testcase.md  # 主文档
│   ├── cso-v0.2.6/                 # 版本目录（URS/PRD/API/DBD/LLD/Task/Testcase/Review/回归报告/进度等）
│   └── deployment-guide.md         # 部署指南
│
└── scripts/                        # 脚本与模板（v0.2.5 后仅保留非 sh/ps1 内容）
    ├── sql/                        # 数据库初始化脚本（init.sql、auth-init-v0.1.5.sql 等）
    ├── docker/                     # Docker Compose 编排与 Dockerfile
    ├── API-TEST/                   # 接口自动化测试脚本（cso-api-test-v0.0.1/v0.2.5/v0.2.6.py + 单元测试 ps1 脚本）
    └── deployment-guide.md         # 部署指南副本
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

部署资产统一位于 `deploy` 目录（v0.2.5 起）：最终 jar 包、客户端安装产物、env.json 环境配置与 `deploy/scripts` 部署脚本。详细编译与部署方案见 `deploy/build.md`、`deploy/deploy.md`（由 impm-deploy-update 技能维护）。

## 版本规划

| 版本 | 阶段 | 计划内容 |
|------|------|---------|
| v0.2.6 | 部署与配置缺陷修复 ✅ | 修复 v0.2.5 回归报告记录的 T-02 缺陷：5 个 pom 引入 spring-cloud-starter-bootstrap（ADR-014）、RSA 密钥统一 DER 单行 Base64 契约（ADR-015）、SecurityConfig 白名单增补（login/register/refresh）与全局异常处理器注册等契约行为对齐；4 服务全部正常启动，API 回归全量跑通（TC-001~051 PASS=72、FAIL=0、SKIP=0），接口契约 API-001~033 无回归 |
| v0.2.5 | 部署资产集中化 ✅ | 新建 deploy 目录；后端 jar/客户端安装产物统一输出到 deploy；env.json 与 env.example.json 迁移；deploy/scripts 子目录建立；scripts 下全部 sh/ps1 迁移并适配路径；中间产物不入 deploy |
| v0.1.6 | 用户认证增强 ✅ | 多模式登录（4种登录策略）+ 多模式注册（5种注册策略）+ 两步注册/账号补全 + 密码管理（修改/找回）+ 手机号变更 + 验证码管理（模拟/真实发送）+ 认证编排服务 AuthenticationService + 9 张数据表 + 234 个单元测试 |
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

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
