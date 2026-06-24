# 云漫智企 (CloudStrollOffice) 部署指南

**版本：** v0.1.6  
**日期：** 2026-06-24  
**适用环境：** 开发环境 / 测试环境 / 生产环境

---

## 目录

1. [环境要求](#1-环境要求)
2. [中间件部署](#2-中间件部署)
3. [配置文件说明](#3-配置文件说明)
4. [编译与构建](#4-编译与构建)
5. [Docker 部署](#5-docker-部署)
6. [手动部署](#6-手动部署)
7. [服务端口映射表](#7-服务端口映射表)
8. [健康检查与验证](#8-健康检查与验证)
9. [运维指南](#9-运维指南)
10. [常见问题](#10-常见问题)

---


## 1. 环境要求

### 1.1 硬件要求

| 环境 | CPU | 内存 | 磁盘 | 说明 |
|------|-----|------|------|------|
| 开发环境 | 4 核+ | 8 GB+ | 20 GB+ | 本地 IDE + 所有服务同时运行 |
| 测试环境 | 4 核+ | 8 GB+ | 50 GB+ | 单机或 Docker Compose 部署 |
| 生产环境（最低） | 8 核+ | 16 GB+ | 100 GB+ | 建议多节点集群部署 |

### 1.2 软件要求

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| JDK | 21+ (LTS) | 推荐 Eclipse Temurin 21 (https://adoptium.net/) |
| Maven | 3.9+ | 项目构建工具 (https://maven.apache.org/download.cgi) |
| MariaDB | 10.6+ (LTS) | 关系型数据库 (https://mariadb.org/download/) |
| Redis | 7.2.x | 缓存（登录态会话、Token 黑名单、账号/租户状态缓存）|
| Nacos | 2.3.x | 服务注册中心与配置中心 (https://nacos.io/download/) |
| Docker | 24+ | 容器化运行环境（可选，推荐） |
| Docker Compose | 2.x | 多容器编排（可选，推荐） |
| Git | 2.x | 代码版本管理 |

### 1.3 网络要求

| 端口 | 协议 | 用途 | 默认绑定 |
|------|------|------|---------|
| 8848 | TCP | Nacos 服务注册与配置 | 0.0.0.0 |
| 3306 | TCP | MariaDB 数据库连接 | 127.0.0.1 |
| 6379 | TCP | Redis 缓存 | 127.0.0.1 |
| 9000 | TCP | API 网关 | 0.0.0.0 |
| 9100-9400 | TCP | 各微服务（auth/biz/system） | 0.0.0.0 |

> **安全提示：** 生产环境应限制数据库和 Nacos 仅对内网开放，各微服务端口仅在内部子网可访问，外部统一通过网关（9000 端口）访问。

---

## 2. 中间件部署

### 2.1 Nacos（服务注册中心 & 配置中心）

#### Docker 部署（推荐）

```bash
# 单机模式启动
docker run -d \
  --name cloud-stroll-nacos \
  -p 8848:8848 \
  -e MODE=standalone \
  -e JVM_XMS=256m \
  -e JVM_XMX=512m \
  nacos/nacos-server:v2.3.0

# 验证部署
curl http://127.0.0.1:8848/nacos/
# 访问 Nacos 控制台：http://127.0.0.1:8848/nacos/ （默认账号/密码：nacos/nacos）
```

#### 手动部署

```bash
# 下载并解压
wget https://github.com/alibaba/nacos/releases/download/2.3.0/nacos-server-2.3.0.tar.gz
tar -xzf nacos-server-2.3.0.tar.gz
cd nacos/bin

# Linux/Mac 启动（单机模式）
sh startup.sh -m standalone

# Windows 启动（单机模式）
startup.cmd -m standalone

# 查看日志
tail -f ../logs/nacos.log
```

### 2.2 MariaDB（关系型数据库）

#### Docker 部署（推荐）

```bash
docker run -d \
  --name cloud-stroll-mariadb \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=root123 \
  -v mariadb-data:/var/lib/mysql \
  mariadb:10.6

# 验证连接
mariadb -h 127.0.0.1 -P 3306 -u root -proot123 -e "SELECT VERSION();"
```

#### 手动部署

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install mariadb-server-10.6

# 启动服务
sudo systemctl start mariadb
sudo systemctl enable mariadb

# 安全初始化
sudo mariadb-secure-installation
```

#### 数据库初始化

```bash
# 1. 执行基础初始化脚本创建数据库和表（v0.1.5：7 张 RBAC 核心表 + 初始数据）
mariadb -u root -p < scripts/sql/auth-init-v0.1.5.sql

# 2. 执行 v0.1.6 增量脚本（OAuth 账号关联表 + 验证码记录表 + 用户表扩展字段）
mariadb -u root -p < scripts/sql/auth-init-v0.1.6.sql

# 3. 或使用通用初始化脚本（仅建库）
mariadb -u root -p < scripts/sql/init.sql

# 验证数据库已创建
mariadb -u root -p -e "SHOW DATABASES;"
# 预期输出：
# cloudstroll_office_auth
# cloudstroll_office_biz
# cloudstroll_office_system
```

> **注意：** v0.1.6 增量脚本基于 v0.1.5 基础结构执行，使用 `CREATE TABLE IF NOT EXISTS` 和 `ADD COLUMN IF NOT EXISTS` 保证幂等性，可重复执行不会破坏已有数据。首次部署时需先执行 `auth-init-v0.1.5.sql` 再执行 `auth-init-v0.1.6.sql`。

### 2.3 Redis（缓存，v0.1.6 必须部署）

认证服务需 Redis 存储登录态会话、Token 黑名单、账号/租户状态缓存。网关也需要 Redis 进行 Token 校验。

#### Docker 部署（推荐）

```bash
docker run -d \
  --name cloud-stroll-redis \
  -p 6379:6379 \
  redis:7.2

# 验证连接
redis-cli -h 127.0.0.1 -p 6379 ping
# 返回 PONG 表示连接成功
```

#### 手动部署

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install redis-server

# 启动服务
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 检查状态
redis-cli ping
```

---

## 3. 配置文件说明

### 3.1 配置体系概述

CloudStrollOffice 使用双层配置体系：

- **bootstrap.yml** — 引导配置：Nacos 注册中心地址（启动时首先加载）
- **application.yml** — 应用配置：端口、数据库连接、JWT 密钥等

所有敏感配置均通过环境变量注入，不硬编码在配置文件中。

### 3.2 环境变量清单

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
| `VERIFICATION_CODE_MOCK` | `true` | auth-service | 验证码模拟模式（true=直接返回固定验证码，false=真实发送 v0.1.6） |
| `VERIFICATION_CODE_EXPIRE_SECONDS` | `300` | auth-service | 验证码过期时间（秒），默认 5 分钟（v0.1.6） |
| `VERIFICATION_CODE_SEND_INTERVAL` | `60` | auth-service | 验证码发送间隔（秒），默认 60 秒（v0.1.6） |
| `VERIFICATION_CODE_LENGTH` | `6` | auth-service | 验证码长度（数字位数）（v0.1.6） |
| `PASSWORD_MIN_LENGTH` | `8` | auth-service | 密码最小长度（v0.1.6） |
| `PASSWORD_MAX_LENGTH` | `64` | auth-service | 密码最大长度（v0.1.6） |
| `MARIADB_ROOT_PASSWORD` | `root123` | Docker 环境 | MariaDB root 密码（仅 docker-compose 使用） |
| `TZ` | `Asia/Shanghai` | Docker 环境 | 容器时区设置 |

### 3.3 各服务配置文件路径

| 服务 | bootstrap.yml | application.yml |
|------|--------------|-----------------|
| Gateway | `cloudoffice-gateway/src/main/resources/bootstrap.yml` | `cloudoffice-gateway/src/main/resources/application.yml` |
| auth-service | `cloudoffice-auth-service/src/main/resources/bootstrap.yml` | `cloudoffice-auth-service/src/main/resources/application.yml` |
| biz-service | `cloudoffice-biz-service/src/main/resources/bootstrap.yml` | `cloudoffice-biz-service/src/main/resources/application.yml` |
| system-service | `cloudoffice-system-service/src/main/resources/bootstrap.yml` | `cloudoffice-system-service/src/main/resources/application.yml` |

### 3.4 RSA 密钥对生成

v0.1.6 使用 RS256 非对称签名算法，需提前生成 RSA 2048 位密钥对：

```bash
# 1. 生成 RSA 2048 位私钥（PKCS#8 格式）
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
  -outform PEM -out private_key.pem

# 2. 提取公钥
openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem

# 3. 转换为 Base64（去掉 PEM 头尾和换行符）
# Linux/Mac
base64 -w0 private_key.pem > private_key_base64.txt
base64 -w0 public_key.pem > public_key_base64.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\private_key.pem")) > private_key_base64.txt
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\public_key.pem")) > public_key_base64.txt
```

将 Base64 编码的私钥和公钥分别配置到 `RSA_PRIVATE_KEY` 和 `RSA_PUBLIC_KEY` 环境变量中。

### 3.5 Nacos 配置中心（预留）

v0.1.6 阶段各服务的配置文件存储在本地 `src/main/resources/` 目录中。后续版本将迁移至 Nacos 配置中心集中管理。

---

## 4. 编译与构建

### 4.1 Maven 编译

```bash
# 克隆代码
git clone https://github.com/your-org/CloudStrollOffice.git
cd CloudStrollOffice

# 全量编译
mvn clean compile

# 全量打包（跳过测试，加快构建速度）
mvn clean package -DskipTests

# 编译并运行测试
mvn clean test

# 跳过测试并指定输出目录
mvn clean package -DskipTests -q
```

### 4.2 指定模块构建

```bash
# 仅构建公共模块（基础依赖）
mvn clean package -pl cloudoffice-common -DskipTests

# 构建网关及其依赖模块
mvn clean package -pl cloudoffice-gateway -am -DskipTests

# 构建认证服务及其依赖模块
mvn clean package -pl cloudoffice-auth-service -am -DskipTests

# 构建企业服务及其依赖模块
mvn clean package -pl cloudoffice-biz-service -am -DskipTests

# 构建系统服务及其依赖模块
mvn clean package -pl cloudoffice-system-service -am -DskipTests
```

### 4.3 编译产物

编译完成后，各模块 JAR 包位于对应模块的 `target/` 目录：

| 模块 | JAR 包路径 |
|------|-----------|
| Gateway | `cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar` |
| auth-service | `cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar` |
| biz-service | `cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar` |
| system-service | `cloudoffice-system-service/target/cloudoffice-system-service-0.0.1-SNAPSHOT.jar` |

> **注意：** `cloudoffice-common` 模块为公共依赖库，不含启动类，不生成可执行 JAR。

### 4.4 依赖管理

```bash
# 查看依赖树（排查依赖冲突）
mvn dependency:tree

# 强制更新快照依赖
mvn clean compile -U

# 下载离线依赖（用于 Docker 构建缓存）
mvn dependency:go-offline
```

---

## 5. Docker 部署

### 5.1 整体架构

Docker 部署将启动 8 个容器，分为三层：

```
┌─────────────────────────────────────────────────────────┐
│                   应用层 (4个容器)                        │
│  gateway(9000) auth-service(9100) biz-service(9200)      │
│  system-service(9400)                                    │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   中间件层 (3个容器)                      │
│  nacos(8848) mariadb(3306) redis(6379)                   │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   存储层                                  │
│  mariadb-data (持久卷)                                    │
└─────────────────────────────────────────────────────────┘
```

### 5.2 使用 Docker Compose 一键部署

```bash
# 进入 Docker 编排目录
cd scripts/docker

# 构建并启动所有服务
docker compose up -d --build

# 查看容器状态
docker compose ps

# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f gateway
docker compose logs -f auth-service

# 停止所有服务
docker compose down

# 停止并删除数据卷（清空数据库数据）
docker compose down -v
```

### 5.3 单独构建与启动单个服务

```bash
# 构建并启动网关
docker compose up -d --build gateway

# 构建并启动认证服务
docker compose up -d --build auth-service
```

### 5.4 容器启动顺序

由于服务间存在依赖关系，启动需遵循以下顺序：

1. **必须最先启动：** Nacos（注册中心）、MariaDB（数据库）
2. **之后启动：** Gateway（依赖 Nacos 获取服务列表）
3. **最后启动：** auth-service、biz-service、system-service（需 Nacos 和 Gateway 就绪）

Docker Compose 中已通过 `depends_on` 配置了启动顺序。

### 5.5 环境变量配置（含 v0.1.6 新增）

创建 `.env` 文件（基于 `.env.example`）覆盖默认配置：

```bash
# 在 project root 或 scripts/docker/ 目录下创建 .env 文件
cp .env.example .env
# 编辑 .env 修改配置
```

**`.env` 文件示例：**

```bash
# Nacos 配置
NACOS_ADDR=nacos:8848

# MariaDB 配置
MARIADB_ROOT_PASSWORD=your_secure_password
DB_HOST=mariadb
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_secure_password

# Redis 配置
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DATABASE=0

# RSA 密钥配置（JWT RS256 签名）
# 使用 OpenSSL 生成：openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048
RSA_PRIVATE_KEY=your-base64-encoded-private-key
RSA_PUBLIC_KEY=your-base64-encoded-public-key

# 验证码配置（v0.1.6）
VERIFICATION_CODE_MOCK=true
VERIFICATION_CODE_EXPIRE_SECONDS=300
VERIFICATION_CODE_SEND_INTERVAL=60
VERIFICATION_CODE_LENGTH=6

# 密码策略配置（v0.1.6）
PASSWORD_MIN_LENGTH=8
PASSWORD_MAX_LENGTH=64

# 时区
TZ=Asia/Shanghai
```

### 5.6 Docker 镜像构建说明

各服务使用多阶段构建（Multi-stage Build）优化镜像大小：

- **第一阶段（Builder）：** 基于 `maven:3.9-eclipse-temurin-21-alpine`，编译源码生成 JAR
- **第二阶段（Runtime）：** 基于 `eclipse-temurin:21-jre-alpine`，仅包含 JRE 和 JAR，镜像更小

镜像大小预估：

| 服务 | 基础镜像 | JAR 大小 | 最终镜像大小 |
|------|---------|---------|------------|
| gateway | eclipse-temurin:21-jre-alpine | ~30MB | ~180MB |
| auth-service | eclipse-temurin:21-jre-alpine | ~35MB | ~185MB |
| biz-service | eclipse-temurin:21-jre-alpine | ~30MB | ~180MB |
| system-service | eclipse-temurin:21-jre-alpine | ~30MB | ~180MB |

---

## 6. 手动部署

### 6.1 直接运行 JAR

```bash
# 1. 确保 Nacos、MariaDB 和 Redis 已启动
#    - Nacos: curl http://127.0.0.1:8848/nacos/
#    - MariaDB: mariadb -h 127.0.0.1 -u root -p -e "SELECT 1"
#    - Redis: redis-cli -h 127.0.0.1 ping

# 2. 初始化数据库（首次部署）
mariadb -u root -p < scripts/sql/auth-init-v0.1.5.sql
mariadb -u root -p < scripts/sql/auth-init-v0.1.6.sql

# 3. 编译打包
mvn clean package -DskipTests

# 4. 按顺序启动各服务
java -jar cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar \
  --NACOS_ADDR=127.0.0.1:8848 \
  --RSA_PUBLIC_KEY=your-base64-public-key

java -jar cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar \
  --NACOS_ADDR=127.0.0.1:8848 \
  --RSA_PRIVATE_KEY=your-base64-private-key \
  --RSA_PUBLIC_KEY=your-base64-public-key \
  --REDIS_HOST=127.0.0.1

java -jar cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar \
  --NACOS_ADDR=127.0.0.1:8848 \
  --DB_HOST=127.0.0.1 \
  --DB_PASSWORD=root123

java -jar cloudoffice-system-service/target/cloudoffice-system-service-0.0.1-SNAPSHOT.jar \
  --NACOS_ADDR=127.0.0.1:8848 \
  --DB_HOST=127.0.0.1 \
  --DB_PASSWORD=root123
```

### 6.2 Maven 插件启动（开发环境）

```bash
# 启动各服务（需在项目根目录执行）
mvn spring-boot:run -pl cloudoffice-gateway
mvn spring-boot:run -pl cloudoffice-auth-service
mvn spring-boot:run -pl cloudoffice-biz-service
mvn spring-boot:run -pl cloudoffice-system-service
```

---

## 7. 服务端口映射表

| 容器名称 | 服务 | 内部端口 | 外部端口 | 协议 |
|---------|------|---------|---------|------|
| `cloud-stroll-nacos` | Nacos Server | 8848 | 8848 | HTTP |
| `cloud-stroll-mariadb` | MariaDB | 3306 | 3306 | MySQL |
| `cloud-stroll-redis` | Redis | 6379 | 6379 | Redis |
| `cloud-stroll-gateway` | API 网关 | 9000 | 9000 | HTTP |
| `cloud-stroll-auth-service` | 认证服务 | 9100 | 9100 | HTTP |
| `cloud-stroll-biz-service` | 企业服务 | 9200 | 9200 | HTTP |
| `cloud-stroll-system-service` | 系统服务 | 9400 | 9400 | HTTP |

---

## 8. 健康检查与验证

### 8.1 健康检查接口

所有业务服务均提供统一格式的健康检查端点：

```bash
# 通过网关验证各服务路由
curl -s http://localhost:9000/api/v1/auth/health    | jq .
curl -s http://localhost:9000/api/v1/biz/health     | jq .
curl -s http://localhost:9000/api/v1/system/health  | jq .

# 直接访问各服务验证
curl -s http://localhost:9100/api/v1/auth/health    | jq .
curl -s http://localhost:9200/api/v1/biz/health     | jq .
curl -s http://localhost:9400/api/v1/system/health  | jq .
```

**预期响应格式：**

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

### 8.2 验证部署清单

| 序号 | 验证项 | 验证方法 | 预期结果 |
|------|--------|---------|---------|
| 1 | Nacos 可访问 | 浏览器访问 `http://localhost:8848/nacos/` | 显示 Nacos 控制台登录页 |
| 2 | MariaDB 可连接 | `mariadb -h 127.0.0.1 -u root -p -e "SELECT 1"` | 返回 1 |
| 3 | Redis 可连接 | `redis-cli -h 127.0.0.1 ping` | 返回 PONG |
| 4 | 数据库已初始化 | `mariadb -u root -p -e "USE cloudstroll_office_auth; SHOW TABLES;"` | 显示 9 张业务表 |
| 5 | Gateway 路由正常 | `curl http://localhost:9000/api/v1/auth/health` | 返回 200 和健康数据 |
| 6 | 各服务健康检查 | 分别验证 3 个健康检查接口 | 均返回 200 和 `status: "UP"` |
| 7 | API 文档可访问 | 访问 `http://localhost:9100/swagger-ui.html` | 显示 Swagger UI 页面 |
| 8 | Nacos 服务列表 | Nacos 控制台 → 服务管理 → 服务列表 | 显示 4 个已注册服务 |
| 9 | 用户登录 | `curl -X POST http://localhost:9000/api/v1/auth/login -H "Content-Type: application/json" -d '{"loginName":"admin","password":"admin123","tenantCode":"DEFAULT","clientType":"H5"}'` | 返回 200，包含 accessToken 和 refreshToken |
| 10 | 认证拦截 | 无 Token 访问 `http://localhost:9000/api/v1/auth/users` | 返回 401 未授权 |
| 11 | 发送验证码（v0.1.6） | `curl -s -X POST http://localhost:9000/api/v1/auth/verification-code/send -H "Content-Type: application/json" -d '{"target":"13800138000","mode":"SMS","purpose":"LOGIN"}'` | 返回 200 |
| 12 | 手机验证码登录（v0.1.6） | `curl -s -X POST http://localhost:9000/api/v1/auth/login -H "Content-Type: application/json" -d '{"phone":"13800138000","code":"123456","tenantCode":"DEFAULT","clientType":"H5","loginMode":"PHONE_CODE"}'` | 返回 200，包含 accessToken |
| 13 | 修改密码（v0.1.6） | `curl -s -X PUT http://localhost:9000/api/v1/auth/password/change -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"oldPassword":"admin123","newPassword":"NewPass123!"}'` | 返回 200 |
| 14 | 完善账号信息（v0.1.6） | `curl -s -X PUT http://localhost:9000/api/v1/auth/account/settlement -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"userId":1,"loginName":"newuser","password":"Password123!","phone":"13800138000"}'` | 返回 200 |

### 8.3 服务未就绪时的处理

| 场景 | 现象 | 排查步骤 |
|------|------|---------|
| Nacos 未启动 | 服务启动失败，日志显示 Nacos 连接失败 | 检查 Nacos 状态：`curl http://localhost:8848/nacos/` |
| 数据库未初始化 | SQL 执行错误 | 执行数据库初始化脚本：`mariadb -u root -p < scripts/sql/init.sql` |
| Gateway 路由 502 | 访问网关提示 502 Bad Gateway | 确认目标服务已启动并注册到 Nacos |
| JWT 密钥未配置 | auth-service 启动失败 | 设置环境变量 `JWT_SECRET`（长度 ≥ 32 字符） |

---

## 9. 运维指南

### 9.1 日志查看

```bash
# Docker 部署
docker compose logs -f --tail=100 gateway
docker compose logs -f --tail=100 auth-service

# 直接运行（日志默认输出到控制台）
# 日志级别可通过 application.yml 中的 logging.level 配置
```

### 9.2 服务重启

```bash
# Docker Compose 重启单个服务
docker compose restart gateway

# Docker Compose 重启所有服务
docker compose restart

# 直接运行：重新执行 java -jar 命令
```

### 9.3 数据库备份

```bash
# 全量备份所有业务数据库
mariadb-dump \
  --host=127.0.0.1 \
  --port=3306 \
  --user=root \
  --password=${MYSQL_ROOT_PASSWORD} \
  --single-transaction \
  --databases cloudstroll_office_auth cloudstroll_office_biz \
    cloudstroll_office_system \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### 9.4 监控

v0.1.4 骨架阶段提供以下监控能力：

- **应用日志：** 使用 `@Slf4j` + Logback 输出结构化日志
- **API 文档：** SpringDoc 自动生成 OpenAPI 3 规范文档
- **服务状态：** `/api/v1/{module}/health` 健康检查端点

后续版本将集成 Prometheus + Grafana 指标监控和 SkyWalking 链路追踪。

---

## 10. 常见问题

### 10.1 编译阶段

**Q：编译时出现 `java: 无效的源发行版: 21`**

A：请检查 `JAVA_HOME` 环境变量是否正确指向 JDK 21。

```bash
java -version  # 确认输出包含 openjdk version "21"
```

**Q：Maven 依赖下载失败**

A：尝试清除本地仓库缓存并重新下载：

```bash
mvn dependency:purge-local-repository
mvn clean compile -U
```

### 10.2 运行阶段

**Q：服务启动时报 `NacosRegistration .... failed`**

A：请确认 Nacos 服务已启动并可访问：

```bash
curl http://127.0.0.1:8848/nacos/
```

**Q：auth-service/gateway 启动失败，提示 RSA 密钥配置错误**

A：v0.1.6 使用 RS256 非对称签名，需要配置 RSA 密钥对：

```bash
# 1. 生成密钥对
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem
openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem

# 2. 获取 Base64 编码
base64 -w0 private_key.pem
base64 -w0 public_key.pem

# 3. 设置环境变量启动
export RSA_PRIVATE_KEY="<base64-private-key>"
export RSA_PUBLIC_KEY="<base64-public-key>"
java -jar cloudoffice-auth-service-0.0.1-SNAPSHOT.jar
```

**Q：认证服务启动失败，提示 Redis 连接超时**

A：请确认 Redis 已启动并可访问：

```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

**Q：访问 Gateway 路由返回 502 Bad Gateway**

A：确认目标微服务已启动并成功注册到 Nacos。在 Nacos 控制台检查服务列表。

**Q：数据库连接失败**

A：确认 MariaDB 已启动，且数据库和用户已正确配置：

```bash
mariadb -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASSWORD} \
  -e "SHOW DATABASES;"
```

### 10.3 Docker 部署

**Q：Docker 构建速度慢**

A：Maven 依赖下载较慢，建议配置国内 Maven 镜像源（在 `pom.xml` 或 `~/.m2/settings.xml` 中配置阿里云镜像）。

**Q：Docker 容器间无法通信**

A：确保所有容器处于同一 Docker 网络（`cloud-stroll-network`），Docker Compose 中已自动配置。

---

> **文档信息：**
> - 本文档适用于 CloudStrollOffice v0.1.6 用户认证增强阶段
> - 后续版本将补充 Kubernetes 部署、CI/CD 流程、生产环境安全加固等内容
> - 如有问题请联系项目维护者或提交 GitHub Issue
