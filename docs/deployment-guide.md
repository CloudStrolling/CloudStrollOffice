# 云漫智企 (CloudStrollOffice) 部署指南

**版本：** v0.1.7  
**日期：** 2026-06-25  
**适用环境：** 开发环境 / 测试环境 / 生产环境  

---

## 目录

1. [前置条件确认](#1-前置条件确认)
2. [环境变量配置](#2-环境变量配置)
3. [数据库初始化](#3-数据库初始化)
4. [编译打包](#4-编译打包)
5. [启动服务](#5-启动服务)
6. [服务停止与重启](#6-服务停止与重启)
7. [服务端口映射表](#7-服务端口映射表)
8. [健康检查与验证](#8-健康检查与验证)
9. [运维指南](#9-运维指南)
10. [常见问题](#10-常见问题)

---

## 1. 前置条件确认

> **目的：** 在开始部署前，逐一确认所有中间件、开发工具和网络环境已就绪。  
> **假设：** Nacos、MariaDB、Redis 已由运维团队部署完毕，本清单仅验证其可用性。

### 1.1 中间件可用性检查

#### 1.1.1 Nacos 服务注册与配置中心

```bash
# 目的：验证 Nacos 服务是否可访问
# 命令：
curl -s http://<NACOS_HOST>:8848/nacos/

# 预期输出：返回包含 "Nacos" 字样的 HTML 页面内容
# 例如（部分内容）：
# <!DOCTYPE html>
# <html lang="en">
# <head><title>Nacos</title></head>
# ...
# 或通过浏览器访问 http://<NACOS_HOST>:8848/nacos/ 能看到 Nacos 控制台登录页
```

| 检查项 | 命令 | 预期结果 |
|--------|------|---------|
| Nacos HTTP 可达 | `curl -s http://<HOST>:8848/nacos/` | 返回 HTML，包含 "Nacos" |
| Nacos 控制台 | 浏览器访问 `http://<HOST>:8848/nacos/` | 显示登录页面（默认账号/密码：nacos/nacos） |

> **参数说明：** 将 `<NACOS_HOST>` 替换为实际的 Nacos 服务器 IP 或域名。如果 Nacos 使用非 8848 端口，请替换端口号。

#### 1.1.2 MariaDB 关系型数据库

```bash
# 目的：验证 MariaDB 服务是否可连接
# 命令：
mariadb -h <DB_HOST> -P <DB_PORT> -u <DB_USERNAME> -p'<DB_PASSWORD>' -e "SELECT VERSION();"

# 预期输出：
# +-----------------+
# | VERSION()       |
# +-----------------+
# | 10.6.18-MariaDB |
# +-----------------+
```

| 检查项 | 命令 | 预期结果 |
|--------|------|---------|
| MariaDB 连接 | `mariadb -h <HOST> -P 3306 -u root -p'<PASSWORD>' -e "SELECT 1"` | 返回 1 |

> **参数说明：**
> - `<DB_HOST>`：MariaDB 服务器 IP（如 192.168.1.101）
> - `<DB_PORT>`：MariaDB 端口（默认 3306）
> - `<DB_USERNAME>`：数据库用户名（默认 root）
> - `<DB_PASSWORD>`：数据库密码

#### 1.1.3 Redis 缓存

```bash
# 目的：验证 Redis 服务是否可连接
# 命令：
redis-cli -h <REDIS_HOST> -p <REDIS_PORT> ping
# 或带密码：
# redis-cli -h <REDIS_HOST> -p <REDIS_PORT> -a '<REDIS_PASSWORD>' ping

# 预期输出：
# PONG
```

| 检查项 | 命令 | 预期结果 |
|--------|------|---------|
| Redis 连接 | `redis-cli -h <HOST> -p 6379 ping` | 返回 PONG |

> **参数说明：**
> - `<REDIS_HOST>`：Redis 服务器 IP（如 192.168.1.102）
> - `<REDIS_PORT>`：Redis 端口（默认 6379）
> - 如果 Redis 设置了密码，需加 `-a '<PASSWORD>'` 参数

### 1.2 开发环境检查

| 检查项 | 最低版本 | 检查命令 | 预期结果 |
|--------|---------|---------|---------|
| JDK | 21 LTS | `java -version` | 输出包含 `openjdk version "21"` |
| Maven | 3.9+ | `mvn -version` | 输出包含 `Apache Maven 3.9` |
| Git | 2.x | `git version` | 输出版本号 |
| JAVA_HOME | 指向 JDK 21 | `echo $JAVA_HOME` (Linux) / `echo %JAVA_HOME%` (Windows CMD) | 路径指向 JDK 21 安装目录 |

```bash
# JDK 检查完整示例
java -version
# 预期输出：
# openjdk version "21.0.3" 2024-04-16 LTS
# OpenJDK Runtime Environment Temurin-21.0.3+9 (build 21.0.3+9-LTS)
# OpenJDK 64-Bit Server VM Temurin-21.0.3+9 (build 21.0.3+9-LTS, mixed mode, sharing)

# Maven 检查完整示例
mvn -version
# 预期输出：
# Apache Maven 3.9.6 (bc0240f3c744dd6b6ec2920b3cd08dcc295161ae)
# Maven home: C:\tools\apache-maven-3.9.6
# Java version: 21.0.3, vendor: Eclipse Adoptium, runtime: C:\Program Files\Eclipse Adoptium\jdk-21.0.3.9-hotspot
# Default locale: zh_CN, platform encoding: UTF-8
# OS name: "windows 11", version: "10.0", arch: "amd64", family: "windows"
```

### 1.3 网络连通性检查

确保部署服务器能够访问各中间件的指定端口：

| 源 | 目标 | 端口 | 协议 | 用途 | 验证命令 |
|----|------|------|------|------|---------|
| 部署服务器 | Nacos | 8848 | TCP/HTTP | 服务注册与发现 | `curl -s http://<NACOS_HOST>:8848/nacos/` |
| 部署服务器 | MariaDB | 3306 | TCP/MySQL | 数据库连接 | `mariadb -h <DB_HOST> -P 3306 -u root -p'<PASS>' -e "SELECT 1"` |
| 部署服务器 | Redis | 6379 | TCP/Redis | 缓存访问 | `redis-cli -h <REDIS_HOST> -p 6379 ping` |

> **网络排查提示：**
> - Linux: `telnet <HOST> <PORT>` 或 `nc -zv <HOST> <PORT>`
> - Windows: `Test-NetConnection -ComputerName <HOST> -Port <PORT>` (PowerShell)
> - 如果连接超时，请检查防火墙和安全组规则是否开放了对应端口

### 1.4 项目代码就绪

```bash
# 方式一：Git 克隆（首次部署）
git clone <REPO_URL>
cd CloudStrollOffice

# 方式二：本地已有代码
cd CloudStrollOffice

# 验证项目结构
ls -la pom.xml
ls scripts/sql/
# 预期输出：pom.xml 存在，scripts/sql/ 目录下包含 auth-init-v0.1.5.sql 和 auth-init-v0.1.6.sql
```

---

## 2. 环境变量配置

> **目的：** 本项目所有敏感配置（数据库密码、RSA 密钥等）均通过环境变量注入，不硬编码在配置文件中。部署前必须先正确配置环境变量。

### 2.1 环境变量清单

环境变量分为三组：必填敏感变量、必填连接变量、可选业务变量。

#### 第一组：必填敏感变量

| 变量名 | 适用服务 | 说明 | 默认值 |
|--------|---------|------|--------|
| `DB_PASSWORD` | auth/biz/system | 数据库密码 | `root` (auth) / `root123` (biz/system) |
| `RSA_PRIVATE_KEY` | auth-service | RSA 私钥（Base64 编码），用于 JWT RS256 签名 | (必填，无默认值) |
| `RSA_PUBLIC_KEY` | auth/gateway | RSA 公钥（Base64 编码），用于 JWT RS256 验签 | (必填，无默认值) |
| `REDIS_PASSWORD` | auth/gateway | Redis 密码（如无密码则为空） | (空) |

> **安全提示：** 以上变量包含敏感信息，严禁提交到版本控制系统。建议使用 `.env` 文件（已加入 `.gitignore`）或专门的密钥管理服务。

#### 第二组：必填连接变量

| 变量名 | 默认值 | 适用服务 | 说明 |
|--------|--------|---------|------|
| `NACOS_ADDR` | `127.0.0.1:8848` | 全部 | Nacos 服务地址 |
| `DB_HOST` | `127.0.0.1` | auth/biz/system | 数据库主机地址 |
| `DB_PORT` | `3306` | auth/biz/system | 数据库端口 |
| `DB_USERNAME` | `root` | auth-service | 数据库用户名（auth-service 使用） |
| `DB_USER` | `root` | biz/system | 数据库用户名（biz/system-service 使用） |
| `REDIS_HOST` | `127.0.0.1` | auth/gateway | Redis 主机地址 |
| `REDIS_PORT` | `6379` | auth/gateway | Redis 端口 |
| `REDIS_DATABASE` | `0` | auth/gateway | Redis 数据库编号 |

> **注意：** auth-service 使用 `DB_USERNAME`，而 biz-service 和 system-service 使用 `DB_USER`。两者通常设置为相同值，但环境变量名称不同。

#### 第三组：可选业务变量

| 变量名 | 默认值 | 适用服务 | 说明 |
|--------|--------|---------|------|
| `VERIFICATION_CODE_MOCK` | `true` | auth-service | 验证码模拟模式：`true`=控制台打印（开发用），`false`=真实发送 |
| `VERIFICATION_CODE_EXPIRE_SECONDS` | `300` | auth-service | 验证码过期时间（秒），默认 5 分钟 |
| `VERIFICATION_CODE_SEND_INTERVAL` | `60` | auth-service | 验证码发送间隔（秒），默认 60 秒 |
| `VERIFICATION_CODE_LENGTH` | `6` | auth-service | 验证码长度（数字位数） |
| `PASSWORD_MIN_LENGTH` | `8` | auth-service | 密码最小长度 |
| `PASSWORD_MAX_LENGTH` | `64` | auth-service | 密码最大长度 |

### 2.2 环境变量文件模板

创建 `.env` 文件（或直接 export），将所有 `<PLACEHOLDER>` 替换为实际值：

```bash
# ============================================================
# CloudStrollOffice 环境变量配置
# 说明：将所有 <PLACEHOLDER> 替换为实际值
# 使用方法：source .env （Linux）或在 PowerShell 中逐条设置
# ============================================================

# ===================== 第一组：必填敏感变量 =====================
export DB_PASSWORD='<DB_PASSWORD>'            # 数据库密码（必须修改！）
export RSA_PRIVATE_KEY='<RSA_PRIVATE_KEY>'     # RSA 私钥 Base64（必须生成！）
export RSA_PUBLIC_KEY='<RSA_PUBLIC_KEY>'       # RSA 公钥 Base64（必须生成！）
export REDIS_PASSWORD='<REDIS_PASSWORD>'       # Redis 密码（无密码则为空）

# ===================== 第二组：必填连接变量 =====================
export NACOS_ADDR='192.168.1.100:8848'         # Nacos 服务地址
export DB_HOST='192.168.1.101'                  # 数据库主机
export DB_PORT='3306'                           # 数据库端口
export DB_USERNAME='root'                       # 数据库用户名（auth-service）
export DB_USER='root'                           # 数据库用户名（biz/system-service）
export REDIS_HOST='192.168.1.102'               # Redis 主机
export REDIS_PORT='6379'                        # Redis 端口

# ===================== 第三组：可选业务变量 =====================
export VERIFICATION_CODE_MOCK='true'            # true=模拟模式（开发用）
export VERIFICATION_CODE_EXPIRE_SECONDS='300'
export VERIFICATION_CODE_SEND_INTERVAL='60'
export VERIFICATION_CODE_LENGTH='6'
export PASSWORD_MIN_LENGTH='8'
export PASSWORD_MAX_LENGTH='64'
```

### 2.3 RSA 密钥生成

v0.1.6+ 使用 RS256 非对称签名算法，必须先生成 RSA 2048 位密钥对：

**一键生成脚本：**

```bash
# Linux/macOS
./scripts/deploy-rsa-keygen.sh

# Windows PowerShell
.\scripts\deploy-rsa-keygen.ps1
```

**手动生成步骤：**

```bash
# 步骤 1：生成 RSA 2048 位私钥（PKCS#8 格式）
openssl genpkey -algorithm RSA \
  -pkeyopt rsa_keygen_bits:2048 \
  -outform PEM \
  -out private_key.pem

# 步骤 2：从私钥提取公钥
openssl pkey -in private_key.pem \
  -pubout \
  -outform PEM \
  -out public_key.pem

# 步骤 3：转换为 Base64 编码（去掉 PEM 头尾和换行符）
# Linux/macOS
base64 -w0 private_key.pem > private_key_base64.txt
base64 -w0 public_key.pem > public_key_base64.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\private_key.pem")) > private_key_base64.txt
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".\public_key.pem")) > public_key_base64.txt

# 步骤 4：查看 Base64 编码的内容（复制到环境变量中）
cat private_key_base64.txt   # Linux
type private_key_base64.txt  # Windows
```

**预期输出示例：**
```
# 私钥 Base64 以 MIIEvQ 开头，长度约 2800 字符
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...

# 公钥 Base64 以 MIIBIj 开头，长度约 450 字符
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
```

> **验证：** 将 Base64 私钥和公钥分别设置到 `RSA_PRIVATE_KEY` 和 `RSA_PUBLIC_KEY` 环境变量中。如果密钥不匹配，auth-service 启动时会报 JWT 签名验证失败错误。

### 2.4 环境变量注入方式

提供三种注入方式，根据部署环境选择。

#### 方式一：Linux/macOS export（临时，当前 Shell 生效）

```bash
# 使用环境变量模板文件（推荐）
cp scripts/deploy-env-template.sh scripts/deploy-env-local.sh
# 编辑 scripts/deploy-env-local.sh，替换所有 <PLACEHOLDER>
vim scripts/deploy-env-local.sh

# 加载环境变量
source scripts/deploy-env-local.sh

# 验证环境变量已加载
echo $NACOS_ADDR
echo $DB_HOST
```

#### 方式二：Windows PowerShell（临时，当前会话生效）

```powershell
# 使用环境变量模板文件（推荐）
Copy-Item scripts/deploy-env-template.ps1 scripts/deploy-env-local.ps1
# 编辑 scripts/deploy-env-local.ps1，替换所有 <PLACEHOLDER>

# 执行加载环境变量
.\scripts\deploy-env-local.ps1

# 验证
$env:NACOS_ADDR
$env:DB_HOST
```

#### 方式三：Windows CMD setx（永久，系统级）

```batch
:: 注意：setx 仅对新打开的 CMD 窗口生效，需管理员权限
setx NACOS_ADDR "192.168.1.100:8848" /M
setx DB_HOST "192.168.1.101" /M
setx DB_PORT "3306" /M
setx DB_USERNAME "root" /M
setx DB_PASSWORD "YourP@ss" /M

:: 说明：setx /M 设置系统级环境变量，需要管理员权限
:: RSA 密钥值太长生僻，不适合用 setx 设置，建议从文件读取
```

> **推荐做法：** 开发环境使用方式一（Linux export）或方式二（PowerShell）；生产环境使用 systemd `EnvironmentFile`（详见第 9 章）。

---

## 3. 数据库初始化

> **目的：** 创建业务数据库、表结构并插入初始数据。  
> **前置条件：** MariaDB 已启动且 1.1.2 节检查通过。

### 3.1 执行初始化脚本

**一键初始化脚本（推荐）：**

```bash
# Linux/macOS - 使用环境变量中的数据库连接参数
./scripts/deploy-db-init.sh

# Windows PowerShell
.\scripts\deploy-db-init.ps1
```

**手动执行（分步）：**

```bash
# 步骤 1：执行 v0.1.5 基础初始化脚本
# 此脚本会：
#   - 创建 cloudstroll_office_auth 数据库（如已存在则先删除再重建）
#   - 创建 7 张 RBAC 核心业务表：t_auth_tenant（租户）、t_auth_user（用户）、
#     t_auth_role（角色）、t_auth_permission（权限）、t_auth_user_role（用户角色关联）、
#     t_auth_role_permission（角色权限关联）、t_auth_login_log（登录日志）
#   - 插入初始数据：默认租户、超级管理员账号、基础角色和权限
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  < scripts/sql/auth-init-v0.1.5.sql

# 步骤 2：执行 v0.1.6 增量脚本
# 此脚本会：
#   - 创建 t_auth_oauth_account（OAuth 第三方账号关联表）
#   - 创建 t_auth_verification_code（验证码记录表）
#   - 扩展 t_auth_user 表字段（增加 user_name、last_login_time、last_login_ip 等）
#   - 使用 CREATE TABLE IF NOT EXISTS 和 ADD COLUMN IF NOT EXISTS 保证幂等性
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  < scripts/sql/auth-init-v0.1.6.sql
```

> **注意：**
> - 首次部署必须**先执行 v0.1.5**，再执行 **v0.1.6**（v0.1.6 是在 v0.1.5 基础上的增量扩展）
> - v0.1.6 脚本是幂等的，可重复执行不会破坏已有数据
> - v0.1.5 脚本包含 `DROP DATABASE IF EXISTS`，会清空已有数据！生产环境请谨慎使用

### 3.2 验证表结构

```bash
# 验证 auth 数据库已创建
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  -e "SHOW DATABASES LIKE 'cloudstroll_office_%';"
# 预期输出：
# +--------------------------------+
# | Database (cloudstroll_office_%) |
# +--------------------------------+
# | cloudstroll_office_auth        |
# +--------------------------------+

# 验证表结构
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  -e "USE cloudstroll_office_auth; SHOW TABLES;"
# 预期输出（共 9 张表）：
# +----------------------------------+
# | Tables_in_cloudstroll_office_auth|
# +----------------------------------+
# | t_auth_login_log                 |
# | t_auth_oauth_account             |  (v0.1.6 新增)
# | t_auth_permission                |
# | t_auth_role                      |
# | t_auth_role_permission           |
# | t_auth_tenant                    |
# | t_auth_user                      |
# | t_auth_user_role                 |
# | t_auth_verification_code         |  (v0.1.6 新增)
# +----------------------------------+

# 验证 biz 和 system 数据库是否存在
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  -e "SHOW DATABASES;"
# 预期输出中应包含：
# cloudstroll_office_auth
# cloudstroll_office_biz
# cloudstroll_office_system
```

### 3.3 验证初始数据

```bash
# 验证租户初始数据（预期：1 条记录）
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  -e "USE cloudstroll_office_auth; SELECT id, tenant_name, tenant_code, status FROM t_auth_tenant;"
# 预期输出：
# +----+----------------+-------------+--------+
# | id | tenant_name    | tenant_code | status |
# +----+----------------+-------------+--------+
# |  1 | 默认租户        | DEFAULT     |      0 |
# +----+----------------+-------------+--------+

# 验证用户初始数据（预期：1 条记录，超级管理员）
mariadb -h 192.168.1.101 -P 3306 -u root -p'YourP@ss' \
  -e "USE cloudstroll_office_auth; SELECT id, login_name, real_name, status FROM t_auth_user;"
# 预期输出：
# +----+-----------+-----------+--------+
# | id | login_name| real_name | status |
# +----+-----------+-----------+--------+
# |  1 | admin     | 系统管理员 |      0 |
# +----+-----------+-----------+--------+
```

---

## 4. 编译打包

> **目的：** 将 Java 源码编译为可执行的 JAR 包。  
> **前置条件：** 前置环境检查通过（JDK 21、Maven 3.9+ 已就绪）。

### 4.1 环境准备确认

在编译前再次确认：

```bash
# 确认 JDK 版本
java -version
# 确认 Maven 版本
mvn -version
# 确认项目根目录（pom.xml 必须在当前目录）
ls pom.xml
```

### 4.2 全量编译打包

```bash
# 目的：编译所有模块并打包为可执行 JAR，跳过测试以加快构建速度
# 命令说明：
#   clean       - 清除之前的编译产物
#   package     - 打包为 JAR
#   -DskipTests - 跳过测试执行（但会编译测试代码）
mvn clean package -DskipTests
```

**预期输出（最后几行）：**

```
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary for CloudStroll Office 0.0.1-SNAPSHOT:
[INFO]
[INFO] cloudoffice-common ................................. SUCCESS [  3.245 s]
[INFO] cloudoffice-gateway ................................ SUCCESS [  8.123 s]
[INFO] cloudoffice-auth-service .......................... SUCCESS [ 12.456 s]
[INFO] cloudoffice-biz-service ........................... SUCCESS [  5.678 s]
[INFO] cloudoffice-system-service ........................ SUCCESS [  4.567 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  34.069 s
[INFO] ------------------------------------------------------------------------
```

> **耗时参考：** 首次编译约 30~60 秒（取决于网络和机器性能），后续增量编译更快。如果依赖下载慢，建议配置国内 Maven 镜像（阿里云等）。

### 4.3 验证编译产物

编译完成后，检查各模块生成的 JAR 包：

```bash
# 列出所有可执行 JAR 包
ls -lh cloudoffice-gateway/target/cloudoffice-gateway-*.jar
ls -lh cloudoffice-auth-service/target/cloudoffice-auth-service-*.jar
ls -lh cloudoffice-biz-service/target/cloudoffice-biz-service-*.jar
ls -lh cloudoffice-system-service/target/cloudoffice-system-service-*.jar
```

**预期输出（文件大小约 30~50MB 每个）：**

```
-rw-r--r-- 1 user user 32M Jun 25 10:00 cloudoffice-gateway-0.0.1-SNAPSHOT.jar
-rw-r--r-- 1 user user 38M Jun 25 10:00 cloudoffice-auth-service-0.0.1-SNAPSHOT.jar
-rw-r--r-- 1 user user 30M Jun 25 10:00 cloudoffice-biz-service-0.0.1-SNAPSHOT.jar
-rw-r--r-- 1 user user 30M Jun 25 10:00 cloudoffice-system-service-0.0.1-SNAPSHOT.jar
```

> **注意：** `cloudoffice-common` 模块是公共依赖库，不含启动类，不生成可执行 JAR。

### 4.4 按需单模块编译

如果只需要修改并重启某个服务，可以只编译该模块及其依赖，节省时间：

```bash
# 仅编译 common 模块（基础依赖变更时）
mvn clean package -pl cloudoffice-common -DskipTests

# 仅编译 gateway 及其依赖（-am = also-make，同时编译依赖模块）
mvn clean package -pl cloudoffice-gateway -am -DskipTests

# 仅编译 auth-service 及其依赖
mvn clean package -pl cloudoffice-auth-service -am -DskipTests

# 仅编译 biz-service 及其依赖
mvn clean package -pl cloudoffice-biz-service -am -DskipTests

# 仅编译 system-service 及其依赖
mvn clean package -pl cloudoffice-system-service -am -DskipTests
```

> **参数说明：**
> - `-pl <module>`：指定要编译的模块（project list）
> - `-am`：also make，自动编译依赖的模块（如 cloudoffice-common）

### 4.5 运行测试

```bash
# 目的：运行所有模块的单元测试，验证代码正确性
# 注意：测试需要 Nacos/MariaDB/Redis 全部就绪
mvn clean test

# 仅运行特定模块的测试
mvn clean test -pl cloudoffice-auth-service

# 运行测试并生成测试报告
mvn clean test surefire-report:report
```

**预期输出：**

```
[INFO] Tests run: XX, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

---

## 5. 启动服务

> **目的：** 按正确的依赖顺序启动所有微服务，并验证各服务正常运行。

### 5.1 启动顺序说明

各服务之间存在依赖关系，必须按下图顺序启动：

```
                         ┌─────────────────────────┐
                         │    中间件（已就绪）      │
                         │  Nacos :8848            │
                         │  MariaDB :3306          │
                         │  Redis  :6379           │
                         └──────────┬──────────────┘
                                    │ 依赖 Nacos 注册中心
                                    ▼
                         ┌─────────────────────────┐
                         │ ① Gateway (端口 9000)   │
                         │   依赖: Nacos + Redis    │
                         └──────────┬──────────────┘
                                    │ 依赖 Gateway 路由就绪（可选）
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ ② auth-service  │    │ ③ biz-service   │    │ ④ system-service│
│   端口 9100      │    │   端口 9200      │    │   端口 9400      │
│   依赖:          │    │   依赖:          │    │   依赖:          │
│   Nacos          │    │   Nacos          │    │   Nacos          │
│   MariaDB        │    │   MariaDB        │    │   MariaDB        │
│   Redis          │    │                  │    │                  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

**启动顺序总结：**
1. Gateway（端口 9000）— 最先启动（仅依赖 Nacos + Redis，启动最快）
2. auth-service（端口 9100）— Gateway 启动后即可启动
3. biz-service（端口 9200）— 可与 auth-service 并行启动
4. system-service（端口 9400）— 可与 auth-service 并行启动

> **说明：** 服务之间通过 Nacos 和 Gateway 进行通信，不需要严格的串行等待。只要 Nacos 就绪，各个服务可以同时启动。Gateway 依赖 Nacos 和 Redis，建议最先启动。

### 5.2 启动 Gateway（端口 9000）

**Gateway 的作用：** API 网关，所有外部请求的统一入口，负责路由转发、Token 校验、跨域处理等。依赖 Nacos（服务发现）和 Redis（Token 黑名单缓存）。

**第一步：注入环境变量**

```bash
# Linux/macOS（替换 <PLACEHOLDER> 为实际值）
export NACOS_ADDR=192.168.1.100:8848
export REDIS_HOST=192.168.1.102
export REDIS_PORT=6379
export REDIS_PASSWORD='<REDIS_PASSWORD>'  # 无密码则为空
export RSA_PUBLIC_KEY="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
```

```powershell
# Windows PowerShell
$env:NACOS_ADDR = "192.168.1.100:8848"
$env:REDIS_HOST = "192.168.1.102"
$env:REDIS_PORT = "6379"
$env:REDIS_PASSWORD = "<REDIS_PASSWORD>"
$env:RSA_PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
```

**第二步：启动服务**

```bash
# Linux/macOS
java -Xms256m -Xmx512m \
  -jar cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar

# 或使用启动脚本（需先加载环境变量）
./scripts/deploy-start-gateway.sh
```

```powershell
# Windows PowerShell
java -Xms256m -Xmx512m `
  -jar cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar

# 或使用启动脚本
.\scripts\deploy-start-gateway.ps1
```

**第三步：验证启动成功**

```bash
# 查看启动日志（应包含以下关键信息）
# 1. Nacos 注册成功
# 2. Redis 连接成功
# 3. 端口 9000 已监听
# 4. 路由规则已加载

# 检查 Gateway 健康状态
# 方式一：检查健康检查接口（需通过 Gateway 自身）
curl -s http://localhost:9000/actuator/health

# 方式二：检查日志输出
# 2026-06-25T10:00:00.000+08:00  INFO [cloudoffice-gateway,,] 12345 --- [main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 9000 (http) with context path ''
# 2026-06-25T10:00:00.000+08:00  INFO [cloudoffice-gateway,,] 12345 --- [main] o.s.c.n.d.s.c.n.NacosContextRefresher    : [Nacos Config] Service "cloudoffice-gateway" has been registered to Nacos
```

**预期输出（健康检查）：**

```json
{
  "status": "UP"
}
```

### 5.3 启动 auth-service（端口 9100）

**auth-service 的作用：** 统一认证与授权服务，负责用户登录/注册、Token 签发/刷新/校验、OAuth 第三方登录、验证码、密码管理等。**所需环境变量最多**（Nacos + MariaDB + Redis + RSA 密钥对）。

**第一步：注入环境变量**

```bash
# Linux/macOS - auth-service 需要最完整的变量集
export NACOS_ADDR=192.168.1.100:8848
export DB_HOST=192.168.1.101
export DB_PORT=3306
export DB_USERNAME=root
export DB_PASSWORD='YourP@ss'
export REDIS_HOST=192.168.1.102
export REDIS_PORT=6379
export REDIS_PASSWORD='<REDIS_PASSWORD>'  # 无密码则为空
export RSA_PRIVATE_KEY="MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC..."
export RSA_PUBLIC_KEY="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
export VERIFICATION_CODE_MOCK=true         # 开发环境建议设为 true
```

```powershell
# Windows PowerShell
$env:NACOS_ADDR = "192.168.1.100:8848"
$env:DB_HOST = "192.168.1.101"
$env:DB_PORT = "3306"
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "YourP@ss"
$env:REDIS_HOST = "192.168.1.102"
$env:REDIS_PORT = "6379"
$env:REDIS_PASSWORD = "<REDIS_PASSWORD>"
$env:RSA_PRIVATE_KEY = "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC..."
$env:RSA_PUBLIC_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
$env:VERIFICATION_CODE_MOCK = "true"
```

**第二步：启动服务**

```bash
# Linux/macOS
java -Xms256m -Xmx512m \
  -jar cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
./scripts/deploy-start-auth.sh
```

```powershell
# Windows PowerShell
java -Xms256m -Xmx512m `
  -jar cloudoffice-auth-service/target/cloudoffice-auth-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
.\scripts\deploy-start-auth.ps1
```

**第三步：验证启动成功**

```bash
# 通过 Gateway 验证 auth-service 路由可达（Gateway 必须在运行）
curl -s http://localhost:9000/api/v1/auth/health

# 或直接访问 auth-service
curl -s http://localhost:9100/api/v1/auth/health
```

**预期输出：**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-auth-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-06-25T10:00:00Z"
  },
  "timestamp": 1770000000000
}
```

**启动失败排查：** 如果 auth-service 启动失败，最常见的三个原因：
1. `RSA_PRIVATE_KEY` 或 `RSA_PUBLIC_KEY` 未设置 → 检查环境变量
2. Redis 连接超时 → 检查 Redis 服务状态
3. 数据库连接失败 → 检查 MariaDB 服务状态和数据库初始化

### 5.4 启动 biz-service（端口 9200）

**biz-service 的作用：** 企业业务服务，负责企业管理相关功能。依赖 Nacos 和 MariaDB。

**第一步：注入环境变量**

```bash
# Linux/macOS
# 注意：biz-service 使用 DB_USER 而不是 DB_USERNAME
export NACOS_ADDR=192.168.1.100:8848
export DB_USER=root          # 注意变量名不同！
export DB_PASSWORD='YourP@ss'
# 可选：如果数据库 URL 非默认，设置完整 URL
# export DB_URL="jdbc:mariadb://192.168.1.101:3306/cloudstroll_office_biz?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai"
```

```powershell
# Windows PowerShell
$env:NACOS_ADDR = "192.168.1.100:8848"
$env:DB_USER = "root"
$env:DB_PASSWORD = "YourP@ss"
```

**第二步：启动服务**

```bash
# Linux/macOS
java -Xms256m -Xmx512m \
  -jar cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
./scripts/deploy-start-biz.sh
```

```powershell
# Windows PowerShell
java -Xms256m -Xmx512m `
  -jar cloudoffice-biz-service/target/cloudoffice-biz-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
.\scripts\deploy-start-biz.ps1
```

**第三步：验证启动成功**

```bash
# 通过 Gateway 验证（推荐）
curl -s http://localhost:9000/api/v1/biz/health

# 或直接访问
curl -s http://localhost:9200/api/v1/biz/health
```

**预期输出：**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-biz-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-06-25T10:00:00Z"
  },
  "timestamp": 1770000000000
}
```

### 5.5 启动 system-service（端口 9400）

**system-service 的作用：** 系统管理服务，负责系统级别的配置管理功能。依赖 Nacos 和 MariaDB。

**第一步：注入环境变量**

```bash
# Linux/macOS
# 与 biz-service 使用相同的变量名体系
export NACOS_ADDR=192.168.1.100:8848
export DB_USER=root
export DB_PASSWORD='YourP@ss'
# 可选：
# export DB_URL="jdbc:mariadb://192.168.1.101:3306/cloudstroll_office_system?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai"
```

```powershell
# Windows PowerShell
$env:NACOS_ADDR = "192.168.1.100:8848"
$env:DB_USER = "root"
$env:DB_PASSWORD = "YourP@ss"
```

**第二步：启动服务**

```bash
# Linux/macOS
java -Xms256m -Xmx512m \
  -jar cloudoffice-system-service/target/cloudoffice-system-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
./scripts/deploy-start-system.sh
```

```powershell
# Windows PowerShell
java -Xms256m -Xmx512m `
  -jar cloudoffice-system-service/target/cloudoffice-system-service-0.0.1-SNAPSHOT.jar

# 使用启动脚本
.\scripts\deploy-start-system.ps1
```

**第三步：验证启动成功**

```bash
# 通过 Gateway 验证（推荐）
curl -s http://localhost:9000/api/v1/system/health

# 或直接访问
curl -s http://localhost:9400/api/v1/system/health
```

**预期输出：**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-system-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-06-25T10:00:00Z"
  },
  "timestamp": 1770000000000
}
```

### 5.6 验证全链路

所有服务启动完成后，通过 Gateway 验证完整链路的可用性：

```bash
# 1. 验证所有服务健康检查（通过 Gateway）
echo "=== 1/4: Auth 服务 ================================="
curl -s http://localhost:9000/api/v1/auth/health | python -m json.tool 2>/dev/null || curl -s http://localhost:9000/api/v1/auth/health

echo ""
echo "=== 2/4: Biz 服务 ================================="
curl -s http://localhost:9000/api/v1/biz/health | python -m json.tool 2>/dev/null || curl -s http://localhost:9000/api/v1/biz/health

echo ""
echo "=== 3/4: System 服务 ==============================="
curl -s http://localhost:9000/api/v1/system/health | python -m json.tool 2>/dev/null || curl -s http://localhost:9000/api/v1/system/health

echo ""
echo "=== 4/4: 用户登录功能验证 ========================="
curl -s -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "loginName": "admin",
    "password": "admin123",
    "tenantCode": "DEFAULT",
    "clientType": "H5"
  }' | python -m json.tool 2>/dev/null || curl -s -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginName":"admin","password":"admin123","tenantCode":"DEFAULT","clientType":"H5"}'
```

**预期输出（用户登录成功）：**

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 7200
  },
  "timestamp": 1770000000000
}
```

> **验证通过标志：** 所有健康检查返回 `status: "UP"`，且登录接口返回包含 `accessToken` 的 JSON 响应。

---

## 6. 服务停止与重启

> **目的：** 优雅地停止各服务，以及在配置变更或故障后的重启操作。

### 6.1 优雅停止服务

#### 6.1.1 停止单个服务（前台运行模式）

如果 Java 进程在前台运行，按 `Ctrl + C` 发送中断信号，Spring Boot 会自动执行优雅关闭：

```bash
# 在前台终端中按
Ctrl + C

# 日志输出（Spring Boot 的优雅关闭日志）：
# 2026-06-25T12:00:00.000+08:00  INFO [cloudoffice-gateway,,] 12345 --- [Thread-5] o.s.b.w.e.tomcat.GracefulShutdown        : Graceful shutdown start
# 2026-06-25T12:00:00.500+08:00  INFO [cloudoffice-gateway,,] 12345 --- [Thread-5] o.s.b.w.e.tomcat.GracefulShutdown        : Graceful shutdown complete
# 2026-06-25T12:00:00.500+08:00  INFO [cloudoffice-gateway,,] 12345 --- [Thread-5] o.s.c.n.d.s.c.n.NacosContextRefresher    : [Nacos Config] Service "cloudoffice-gateway" has been deregistered from Nacos
```

#### 6.1.2 停止单个服务（后台运行模式，Linux）

```bash
# 查找进程 PID
ps aux | grep cloudoffice-gateway
# 或
jps -l | grep cloudoffice

# 优雅停止（发送 SIGTERM 信号）
kill -15 <PID>

# 等待进程退出
sleep 5

# 确认进程已停止
ps -p <PID> || echo "进程已停止"

# 如果 30 秒后仍未停止，强制结束
# kill -9 <PID>  # 不推荐，仅作为最后手段
```

#### 6.1.3 停止所有服务

```bash
# 使用 jps 查找所有 CloudStrollOffice 进程并停止
jps -l | grep cloudoffice | awk '{print $1}' | while read pid; do
  echo "Stopping PID $pid ..."
  kill -15 $pid
done

# 等待所有进程退出
sleep 10

# 检查是否还有残留进程
jps -l | grep cloudoffice || echo "所有服务已停止"
```

#### 6.1.4 Windows 下停止服务

```powershell
# 查找 Java 进程
Get-Process -Name java | Where-Object { $_.CommandLine -match "cloudoffice" } | Select-Object Id, ProcessName

# 优雅停止（发送 Ctrl+C 信号）
# Windows 下前台进程直接关闭窗口即可
# 后台进程：

# 方式一：按进程名停止
Stop-Process -Name "java" -Force  # 会停止所有 Java 进程

# 方式二：按端口停止（推荐，使用 netstat 查找 PID）
$port = 9000  # 改为对应服务端口
$pid = netstat -ano | Select-String "LISTENING.*:$port" | ForEach-Object { $_ -split '\s+' | Select-Object -Last 1 }
if ($pid) { Stop-Process -Id $pid -Force }
```

### 6.2 重启指南

#### 6.2.1 场景一：修改配置后重启

```bash
# 1. 重新加载环境变量（如果修改了 .env 文件）
source scripts/deploy-env-local.sh

# 2. 停止旧进程
kill -15 $(jps -l | grep cloudoffice-gateway | awk '{print $1}')

# 3. 等待 5 秒确保旧进程已释放端口
sleep 5

# 4. 重新启动
./scripts/deploy-start-gateway.sh
```

#### 6.2.2 场景二：代码修改后重启

```bash
# 1. 重新编译修改的模块
mvn clean package -pl cloudoffice-auth-service -am -DskipTests

# 2. 停止旧进程
kill -15 $(jps -l | grep cloudoffice-auth-service | awk '{print $1}')

# 3. 等待旧进程退出
sleep 5

# 4. 重新启动
./scripts/deploy-start-auth.sh
```

#### 6.2.3 场景三：全量重启

```bash
# 1. 按逆序停止所有服务
jps -l | grep cloudoffice | awk '{print $1}' | xargs -r kill -15

# 2. 等待所有进程退出
sleep 10

# 3. 重新编译（可选，如果代码有变更）
mvn clean package -DskipTests

# 4. 重新加载环境变量
source scripts/deploy-env-local.sh

# 5. 按顺序启动
./scripts/deploy-start-gateway.sh &
sleep 15        # 等待 Gateway 完全启动
./scripts/deploy-start-auth.sh &
./scripts/deploy-start-biz.sh &
./scripts/deploy-start-system.sh &

# 6. 验证全链路
echo "等待服务全部启动（30 秒）..."
sleep 30
curl -s http://localhost:9000/api/v1/auth/health
curl -s http://localhost:9000/api/v1/biz/health
curl -s http://localhost:9000/api/v1/system/health
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
| RSA 密钥未配置 | auth-service 启动失败，日志提示密钥错误 | 设置 `RSA_PRIVATE_KEY` 和 `RSA_PUBLIC_KEY` 环境变量 |

---

## 9. 运维指南

### 9.1 日志查看

```bash
# Docker 部署
docker compose logs -f --tail=100 gateway
docker compose logs -f --tail=100 auth-service

# 直接运行（日志默认输出到控制台）
# 日志级别可通过 application.yml 中的 logging.level 配置

# 后台运行时重定向日志到文件
nohup java -jar cloudoffice-gateway-0.0.1-SNAPSHOT.jar > logs/gateway.log 2>&1 &
nohup java -jar cloudoffice-auth-service-0.0.1-SNAPSHOT.jar > logs/auth-service.log 2>&1 &
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

# 定期备份脚本示例（crontab，每天凌晨 2 点）
# 0 2 * * * /opt/cloudstroll/scripts/backup.sh
```

### 9.4 监控

v0.1.4 骨架阶段提供以下监控能力：

- **应用日志：** 使用 `@Slf4j` + Logback 输出结构化日志
- **API 文档：** SpringDoc 自动生成 OpenAPI 3 规范文档
- **服务状态：** `/api/v1/{module}/health` 健康检查端点

后续版本将集成 Prometheus + Grafana 指标监控和 SkyWalking 链路追踪。

### 9.5 systemd 服务配置（生产环境推荐）

生产环境建议使用 systemd 管理服务，确保服务崩溃后自动重启：

```ini
# /etc/systemd/system/cloudstroll-gateway.service
[Unit]
Description=CloudStrollOffice API Gateway
After=network.target
Wants=network.target

[Service]
Type=simple
User=cloudstroll
Group=cloudstroll
EnvironmentFile=/etc/cloudstroll/env/gateway.conf
WorkingDirectory=/opt/cloudstroll
ExecStart=/usr/bin/java -Xms256m -Xmx512m -jar /opt/cloudstroll/cloudoffice-gateway-0.0.1-SNAPSHOT.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**注册并启动：**

```bash
sudo cp cloudstroll-gateway.service /etc/systemd/system/
sudo mkdir -p /etc/cloudstroll/env
sudo cp gateway.conf /etc/cloudstroll/env/
sudo chmod 600 /etc/cloudstroll/env/*.conf
sudo systemctl daemon-reload
sudo systemctl enable cloudstroll-gateway.service
sudo systemctl start cloudstroll-gateway.service
sudo systemctl status cloudstroll-gateway.service
```

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

**Q：Maven 编译速度慢**

A：配置国内 Maven 镜像加速依赖下载。在 `~/.m2/settings.xml` 中添加阿里云镜像：

```xml
<mirrors>
  <mirror>
    <id>aliyunmaven</id>
    <mirrorOf>*</mirrorOf>
    <name>阿里云公共仓库</name>
    <url>https://maven.aliyun.com/repository/public</url>
  </mirror>
</mirrors>
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

**Q：auth-service 启动后登录接口返回 500**

A：检查是否已执行数据库初始化脚本（auth-init-v0.1.6.sql），可能缺少 `t_auth_verification_code` 表。

**Q：Windows 下读取 Base64 密钥文件到环境变量**

A：使用 PowerShell 命令：

```powershell
$env:RSA_PRIVATE_KEY = Get-Content -Path "C:\keys\private_key_base64.txt" -Raw
$env:RSA_PUBLIC_KEY = Get-Content -Path "C:\keys\public_key_base64.txt" -Raw
# 注意：-Raw 参数保留原始内容，不加 Raw 会自动添加换行符导致密钥格式错误
```

### 10.3 Docker 部署

**Q：Docker 构建速度慢**

A：Maven 依赖下载较慢，建议配置国内 Maven 镜像源（在 `pom.xml` 或 `~/.m2/settings.xml` 中配置阿里云镜像）。

**Q：Docker 容器间无法通信**

A：确保所有容器处于同一 Docker 网络（`cloud-stroll-network`），Docker Compose 中已自动配置。

---

## 附录 A：部署脚本清单

以下脚本位于 `scripts/` 目录下，用于辅助部署：

| 脚本文件名 | 用途 | Linux/macOS | Windows |
|-----------|------|-------------|---------|
| `deploy-check-env.*` | 前置环境检查 | `deploy-check-env.sh` | `deploy-check-env.ps1` |
| `deploy-env-template.*` | 环境变量模板 | `deploy-env-template.sh` | `deploy-env-template.ps1` |
| `deploy-rsa-keygen.*` | RSA 密钥对生成 | `deploy-rsa-keygen.sh` | `deploy-rsa-keygen.ps1` |
| `deploy-db-init.*` | 数据库初始化 | `deploy-db-init.sh` | `deploy-db-init.ps1` |
| `deploy-start-gateway.*` | 启动 Gateway | `deploy-start-gateway.sh` | `deploy-start-gateway.ps1` |
| `deploy-start-auth.*` | 启动 auth-service | `deploy-start-auth.sh` | `deploy-start-auth.ps1` |
| `deploy-start-biz.*` | 启动 biz-service | `deploy-start-biz.sh` | `deploy-start-biz.ps1` |
| `deploy-start-system.*` | 启动 system-service | `deploy-start-system.sh` | `deploy-start-system.ps1` |

**快速部署流程（推荐步骤）：**

```bash
# 1. 检查环境
./scripts/deploy-check-env.sh

# 2. 生成 RSA 密钥对
./scripts/deploy-rsa-keygen.sh

# 3. 配置环境变量
cp scripts/deploy-env-template.sh scripts/deploy-env-local.sh
# 编辑 deploy-env-local.sh，替换所有 <PLACEHOLDER>
source scripts/deploy-env-local.sh

# 4. 初始化数据库
./scripts/deploy-db-init.sh

# 5. 编译打包
mvn clean package -DskipTests

# 6. 按顺序启动服务
./scripts/deploy-start-gateway.sh
# (新开终端或后台运行)
source scripts/deploy-env-local.sh
./scripts/deploy-start-auth.sh
./scripts/deploy-start-biz.sh
./scripts/deploy-start-system.sh
```

---

> **文档信息：**
> - 本文档适用于 CloudStrollOffice v0.1.6 用户认证增强阶段
> - 后续版本将补充 Kubernetes 部署、CI/CD 流程、生产环境安全加固等内容
> - 如有问题请联系项目维护者或提交 GitHub Issue
