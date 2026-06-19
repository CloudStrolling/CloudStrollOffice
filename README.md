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

当前版本 **v0.1.4** 已完成系统服务模块的系统服务模块（cloudoffice-system-service）搭建，包含系统配置、日志、监控、定时任务骨架及健康检查端点、完整单元测试覆盖。项目已完成认证服务、企业服务、系统服务三大业务服务的基础骨架搭建，为后续业务功能开发奠定微服务基础设施。

## 功能特性

| 特性 | 说明 |
|------|------|
| 微服务架构 | 5 个 Maven 模块，服务间解耦，独立开发、测试和部署 |
| 统一响应体 | `ApiResult<T>` 统一封装所有 REST 接口响应，含状态码、消息、数据和时间戳 |
| 分层异常体系 | `BaseException` → `BusinessException` / `AuthException`，按模块划分错误码 |
| 全局异常处理 | `@RestControllerAdvice` 统一捕获 7 类异常，兜底不泄露堆栈信息 |
| JWT 令牌工具 | 基于 JJWT 0.12.6，支持令牌签发、解析、校验，HS256 签名算法 |
| Spring Security | BCrypt 密码编码器、无状态会话管理、自定义 401/403 JSON 响应 |
| API 文档 | SpringDoc (OpenAPI 3) 自动生成，按模块分组，在线调试 |
| API 网关 | Spring Cloud Gateway，路由转发、CORS 跨域、Nacos 服务发现集成 |
| 服务注册发现 | Nacos 2.3.0 统一管理，各服务启动后自动注册 |
| 健康检查链路 | 所有业务服务提供 `/api/v1/{module}/health` 健康检查端点 |
| Docker 部署 | 多阶段构建镜像 + Docker Compose 一键编排 7 个容器 |
| 开发环境配置 | IDEA 运行配置、.editorconfig、Checkstyle、代码风格统一 |

## 项目架构

```
┌────────────────────────────────────────────────────────────────────────────┐
│                             客户端层 (Client)                               │
│                    Flutter Desktop / Mobile / Web / 第三方 API              │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         API 网关层 (Gateway)                                │
│                    Spring Cloud Gateway（端口 9000）                         │
│                     路由转发 │ CORS │ 服务发现集成                           │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
            ▼                        ▼
┌────────────────────┐ ┌────────────────────┐
│   认证服务          │ │   企业服务          │
│  auth-service(9100) │ │  biz-service(9200) │
│ Spring Security +   │ │ 企业信息 / 人事管理 │
│ OAuth2 骨架 + JWT   │ │ v0.1.0 骨架        │
└──────────┬─────────┘ └──────────┬─────────┘
           │                      │
           ▼                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                          系统服务 (system-service)                          │
│                          (端口 9400)                                        │
│                    系统配置 │ 日志 │ 监控 │ 定时任务                         │
│                          v0.1.4 完成搭建                                    │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
┌────────────────────┐ ┌────────────────────┐ ┌────────────────────┐
│    MariaDB 10.6    │ │   Redis 7.2.x      │ │  RocketMQ 5.1.x    │
│    数据库层         │ │  缓存（本期预留）   │ │ 消息队列（本期预留） │
└────────────────────┘ └────────────────────┘ └────────────────────┘
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
| `cloudoffice-common` | - | 无 | 公共模块：统一响应体 `ApiResult<T>`、分页响应 `PageResult<T>`、异常体系（`BaseException`/`BusinessException`/`AuthException`）、全局异常处理器 `GlobalExceptionHandler`、实体基类 `BaseEntity`、SpringDoc 配置、MyBatis-Plus 自动填充配置、JSON 工具类等 |
| `cloudoffice-gateway` | 9000 | common, Nacos | API 网关：请求路由转发（3 条路由规则）、CORS 跨域配置、Nacos 服务发现集成 |
| `cloudoffice-auth-service` | 9100 | common, Nacos | 认证服务：Spring Security 安全配置（BCrypt 密码编码器、无状态会话、CSRF 关闭、自定义 401/403 响应）、OAuth2 授权服务器骨架配置、JWT 令牌工具类（签发/解析/校验）、健康检查接口 |
| `cloudoffice-biz-service` | 9200 | common, Nacos, MyBatis-Plus, MariaDB | 企业服务（骨架）：企业信息/人事管理业务骨架、健康检查接口 |
| `cloudoffice-system-service` | 9400 | common, Nacos, MyBatis-Plus, MariaDB | 系统服务（骨架）：系统配置/日志/监控/定时任务骨架、健康检查接口 |

## 快速开始

### 环境要求

| 环境 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 21+ (LTS) | 推荐 OpenJDK 21 或 Eclipse Temurin 21 |
| Maven | 3.9+ | 项目构建与依赖管理 |
| MariaDB | 10.6+ | 关系型数据库 |
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
# 执行数据库初始化脚本
mariadb -u root -p < scripts/sql/init.sql
```

脚本将创建以下数据库和表：

- `cloudstroll_office_auth` — 含 `t_auth_user` 用户表
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

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NACOS_ADDR` | `127.0.0.1:8848` | Nacos 服务地址 |
| `JWT_SECRET` | 开发环境默认密钥 | JWT 签名密钥（生产环境必须修改，长度 ≥ 32 字符） |
| `DB_HOST` | `127.0.0.1` | 数据库主机地址 |
| `DB_PORT` | `3306` | 数据库端口 |
| `DB_USER` | `root` | 数据库用户名 |
| `DB_PASSWORD` | `root123` | 数据库密码 |

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

**方式三：Docker Compose 一键部署**

```bash
# 构建并启动所有服务
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
│       └── config/                 # 网关配置
│
├── cloudoffice-auth-service/       # 认证服务（端口 9100）
│   └── src/main/java/org/cloudstrolling/cloudoffice/auth/
│       ├── AuthApplication.java    # 启动类
│       ├── config/                 # SecurityConfig, OAuth2Config
│       ├── controller/
│       │   └── HealthController.java
│       └── util/
│           └── JwtUtils.java       # JWT 令牌工具类
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
    │   └── init.sql                # 数据库初始化脚本
    └── docker/
        ├── docker-compose.yml      # Docker Compose 编排
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
| Redis | 6379 | 缓存（本期预留） |

## 部署架构

生产环境推荐部署方式：

```
[负载均衡器（Nginx/ALB）] ──▶ [Gateway 实例集群] ──▶ [各微服务多实例]
                                │
                                ├──▶ [auth-service:9100] ──▶ [MariaDB:3306]
                                ├──▶ [biz-service:9200]  ──▶ [MariaDB:3306]
                                └──▶ [system-service:9400] ──▶ [MariaDB:3306]
                                │
                                └──▶ [Nacos Cluster:8848] ──▶ [Nacos Cluster]
```

## 版本规划

| 版本 | 阶段 | 计划内容 |
|------|------|---------|
| v0.1.4 | 系统服务搭建 ✅ | 系统服务模块（cloudoffice-system-service）完整骨架、健康检查端点、单元测试、Docker 部署配置 |
| v0.1.0 | 基础骨架搭建 ✅ | Maven 多模块架构、公共组件、API 网关、认证服务骨架、业务服务骨架、Docker 部署模板 |
| v0.2.0 | 基础功能 | 用户登录/注册、RBAC 权限模型、企业/部门/员工 CRUD、系统配置管理 |
| v0.3.0 | 核心业务 | 工作流审批、考勤管理、云资源管理、消息通知、缓存集成 |
| v0.4.0 | 高级功能 | 薪酬管理、报表统计、审计日志、定时任务、消息队列集成 |

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
