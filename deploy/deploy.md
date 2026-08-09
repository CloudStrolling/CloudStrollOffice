# 部署方案（deploy.md）

**项目名称**：云漫智企（CloudStrollOffice）
**项目英文缩写**：cso
**适用版本**：v0.2.5（部署资产集中化）
**文档位置**：deploy/deploy.md
**最近更新**：2026-08-09

## 1. 文档说明

本文档说明云漫智企（CloudStrollOffice）v0.2.5 版本的部署方法与运维操作。

自 v0.2.5 起，项目执行"部署资产集中化"策略：**deploy 目录是部署资产的唯一落点**，交付与运维人员在 `deploy` 目录即可完成全部部署操作（jar 包、客户端产物、env 配置、部署脚本全部集中于此）。

## 2. 部署架构

| 组件 | 产物/依赖 | 默认端口 | 说明 |
| --- | --- | --- | --- |
| API 网关 cloudoffice-gateway | deploy/cloudoffice-gateway.jar | 9000 | 统一入口，客户端全部请求经网关转发 |
| 认证服务 cloudoffice-auth-service | deploy/cloudoffice-auth-service.jar | 9100 | 登录/注册/令牌/密码等认证能力 |
| 企业服务 cloudoffice-biz-service | deploy/cloudoffice-biz-service.jar | 9200 | 企业信息/人事等业务能力 |
| 系统服务 cloudoffice-system-service | deploy/cloudoffice-system-service.jar | 9400 | 系统管理能力 |
| 客户端 Web | deploy/cloudoffice-flutter-app/web/ | 任意 HTTP（如 Nginx 80） | 浏览器访问 |
| 客户端 Windows | deploy/cloudoffice-flutter-app/windows/ | — | 桌面程序（cloudoffice_flutter_app.exe） |
| MariaDB / MySQL | 基础设施 | 3306 | 业务数据库（认证库 cloudstroll_office_auth） |
| Redis | 基础设施 | 6379 | 会话/缓存 |
| Nacos | 基础设施 | 8848 | 注册中心与配置中心 |

## 3. 部署环境要求

| 项目 | 要求 | 说明 |
| --- | --- | --- |
| 操作系统 | Windows Server 2019+ / Windows 10/11 或 Linux | Windows 桌面客户端需 Windows；Web 与后端可运行于 Linux |
| JDK | 21 | 后端服务运行环境 |
| MariaDB | 10.6+（或 MySQL 5.7+） | 业务数据库 |
| Redis | 7.x（6.x 亦可） | 会话缓存 |
| Nacos | 2.3.x（standalone 模式即可） | 注册/配置中心 |
| Web 服务器 | Nginx 等任意静态服务器（仅 Web 客户端需要） | 承载 deploy/cloudoffice-flutter-app/web/ |

## 4. deploy 目录结构

```
deploy/
├── cloudoffice-gateway.jar           # 后端最终可执行 jar（v0.2.5 起统一落点）
├── cloudoffice-auth-service.jar
├── cloudoffice-biz-service.jar
├── cloudoffice-system-service.jar
├── env.json                          # 实际环境配置（从 env.example.json 复制填写）
├── env.example.json                  # 环境配置模板
├── cloudoffice-flutter-app/          # 客户端最终产物（web/、windows/）
├── build.md                          # 编译方案（本文档同目录）
├── deploy.md                         # 部署方案（本文档）
└── scripts/                          # 部署运维脚本（全部 .sh/.ps1）
    ├── build-backend.ps1 / .sh       # 一键后端编译
    ├── build-client.ps1 / .sh        # 一键客户端编译
    ├── deploy-check-env.ps1 / .sh    # 部署前置检查
    ├── deploy-db-init.ps1 / .sh      # 数据库初始化
    ├── deploy-env.ps1 / .sh          # 环境注入（已弃用，兼容保留）
    ├── deploy-env-template.ps1 / .sh # 环境模板生成
    ├── deploy-rsa-keygen.ps1 / .sh   # RSA 密钥对生成
    ├── deploy-start-services.ps1 / .sh # 基础设施检测与启动（MariaDB/Redis/Nacos）
    ├── deploy-start-gateway.ps1 / .sh  # 启动网关
    ├── deploy-start-auth.ps1 / .sh     # 启动认证服务
    ├── deploy-start-biz.ps1 / .sh      # 启动企业服务
    ├── deploy-start-system.ps1 / .sh   # 启动系统服务
    └── load-env.ps1 / .sh              # 加载 env.json 为环境变量
```

## 5. 部署步骤

### 5.1 准备部署资产

1. 获取编译产物：按 deploy/build.md 执行后端 `mvn clean package -DskipTests` 与客户端 `build-release.ps1`，确认 jar 位于 `deploy/`、客户端产物位于 `deploy/cloudoffice-flutter-app/`。
2. 确认部署主机已安装 JDK 21、MariaDB、Redis、Nacos（见第 3 节）。

### 5.2 环境配置（env.json）

```powershell
# 复制模板并填写实际值（数据库口令、RSA 密钥等）
Copy-Item deploy\env.example.json deploy\env.json
# 编辑 deploy\env.json，填写 DB_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等
```

配置项说明见第 6 节。**严禁将含真实口令的 env.json 提交到 git**。

### 5.3 生成 RSA 密钥对（首次部署必做）

```powershell
.\deploy\scripts\deploy-rsa-keygen.ps1
```

密钥输出到 `deploy/keys/`（private_key.pem / public_key.pem 及 Base64 文本）。将 Base64 内容填入 `deploy/env.json` 的 `RSA_PRIVATE_KEY` 与 `RSA_PUBLIC_KEY`，并同步 Nacos 配置。密钥变更后旧令牌全部失效，属预期行为。

### 5.4 数据库初始化

前置条件：MariaDB 已启动且可连接。

```powershell
.\deploy\scripts\deploy-db-init.ps1
```

脚本从 env.json 读取数据库连接信息，执行 `scripts/sql/` 下初始化 SQL（auth-init-v0.1.5.sql、auth-init-v0.1.6.sql 等），创建认证库 `cloudstroll_office_auth` 及表结构与初始数据。

### 5.5 启动基础设施（MariaDB / Redis / Nacos）

```powershell
.\deploy\scripts\deploy-start-services.ps1
```

脚本功能：加载 env.json → 三重检测（命令/服务/进程）MariaDB、Redis、Nacos 安装状态 → 检测运行状态，未运行则自动启动 → 输出检测结果。

### 5.6 启动后端服务

按依赖顺序逐个启动（或使用各自启动脚本）：

```powershell
# 启动网关（统一入口，建议最先启动）
.\deploy\scripts\deploy-start-gateway.ps1

# 启动业务服务（各自独立窗口）
.\deploy\scripts\deploy-start-auth.ps1
.\deploy\scripts\deploy-start-biz.ps1
.\deploy\scripts\deploy-start-system.ps1
```

也可直接执行：

```powershell
java -Xms256m -Xmx512m -jar deploy\cloudoffice-gateway.jar
java -Xms256m -Xmx512m -jar deploy\cloudoffice-auth-service.jar
# ... 其余服务同理
```

Linux 环境使用对应 .sh 脚本（如 `./deploy/scripts/deploy-start-gateway.sh`）。

### 5.7 部署客户端

**Web 客户端**：将 `deploy/cloudoffice-flutter-app/web/` 整个目录部署到 Nginx（或任意静态服务器），例如 Nginx 站点根指向该目录后访问 `http://<服务器>/`。

**Windows 客户端**：将 `deploy/cloudoffice-flutter-app/windows/` 目录拷贝到目标机器，运行 `cloudoffice_flutter_app.exe` 即可。

## 6. 配置说明（deploy/env.json）

| 配置项 | 说明 | 示例 |
| --- | --- | --- |
| NACOS_ADDR | Nacos 地址（host:port） | 127.0.0.1:8848 |
| NACOS_HOME | Nacos 安装目录（Windows 启动检测用） | D:\develop\nacos |
| DB_SERVICE_NAME / DB_PROCESS_NAME | 数据库服务/进程名（检测用，逗号分隔） | MySQL, MariaDB / mysqld, mariadbd |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | Redis 服务/进程名（检测用） | Redis / redis-server |
| DB_HOST / DB_PORT | 数据库地址与端口 | 127.0.0.1 / 3306 |
| DB_USERNAME / DB_PASSWORD | 数据库账号与口令 | root / <DB_PASSWORD> |
| DB_USER | 数据库用户（兼容项） | root |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD / REDIS_DATABASE | Redis 连接配置 | 127.0.0.1 / 6379 / 空 / 0 |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | JWT 签名 RSA 密钥对（Base64） | <RSA_PRIVATE_KEY> / <RSA_PUBLIC_KEY> |
| VERIFICATION_CODE_MOCK | 验证码模拟开关（true 跳过真实发送） | true |
| VERIFICATION_CODE_EXPIRE_SECONDS | 验证码有效期（秒） | 300 |
| VERIFICATION_CODE_SEND_INTERVAL | 验证码发送间隔（秒） | 60 |
| VERIFICATION_CODE_LENGTH | 验证码长度 | 6 |
| PASSWORD_MIN_LENGTH / PASSWORD_MAX_LENGTH | 密码长度范围 | 8 / 64 |
| MARIADB_ROOT_PASSWORD | MariaDB root 口令（Docker 编排用） | root123 |
| TZ | 时区 | Asia/Shanghai |

## 7. 启动与停止命令汇总

| 操作 | 命令 |
| --- | --- |
| 前置检查 | `.\deploy\scripts\deploy-check-env.ps1` |
| 基础设施检测与启动 | `.\deploy\scripts\deploy-start-services.ps1` |
| 启动网关 | `.\deploy\scripts\deploy-start-gateway.ps1` |
| 启动认证服务 | `.\deploy\scripts\deploy-start-auth.ps1` |
| 启动企业服务 | `.\deploy\scripts\deploy-start-biz.ps1` |
| 启动系统服务 | `.\deploy\scripts\deploy-start-system.ps1` |
| 数据库初始化 | `.\deploy\scripts\deploy-db-init.ps1` |
| RSA 密钥生成 | `.\deploy\scripts\deploy-rsa-keygen.ps1` |
| 加载环境变量 | `. .\deploy\scripts\load-env.ps1` |
| 停止服务 | 对应启动窗口 Ctrl+C；或停止 java 进程（`Stop-Process -Name java` 需甄别进程） |

Linux 环境将命令替换为 `./deploy/scripts/*.sh` 即可。

## 8. 健康检查

| 检查项 | 方式 | 预期 |
| --- | --- | --- |
| 网关存活 | 访问 http://<主机>:9000/ | 返回网关响应（如 404/401 均说明服务在运行） |
| 各服务注册 | Nacos 控制台 http://<主机>:8848/nacos/ 服务列表 | gateway/auth/biz/system 均在线 |
| 认证接口 | POST http://<主机>:9000/（客户端实际调用路径） | 返回正常业务响应 |
| 数据库连通 | 服务日志无数据库连接异常 | 正常 |
| Web 客户端 | 浏览器访问 Web 站点 | 页面可打开、可登录 |

## 9. 日志查看

- 各服务日志输出至启动窗口（PowerShell/终端标准输出）。
- 应用日志目录：项目根目录 `logs/`（如 access_log.2026-08-09.log）。
- Nacos、MariaDB、Redis 日志查看各自安装目录下日志文件。

## 10. 回滚方案

| 场景 | 回滚步骤 |
| --- | --- |
| 后端服务故障 | 1) 停止故障服务进程；2) 用上一版本 jar 覆盖 deploy/ 下对应 jar（旧 jar 归档于各版本发布包/备份目录）；3) 重新执行对应 deploy-start-*.ps1 启动；4) 健康检查 |
| 数据库结构变更异常 | 1) 使用数据库备份恢复（部署前执行 `mysqldump` 全量备份）；2) 重新启动服务 |
| 客户端 Web 异常 | 1) 将 web/ 目录替换为上一版本 Web 包；2) 刷新浏览器缓存（Ctrl+F5） |
| 客户端 Windows 异常 | 1) 覆盖安装上一版本 windows/ 目录；2) 重新运行 exe |
| 配置错误（env.json） | 1) 停止全部服务；2) 修正 env.json；3) 重新启动全部服务 |

**通用回滚建议**：发布前对 `deploy/` 目录做整体备份（jar + env.json + 客户端产物），回滚时整体还原并重启服务。

## 11. 常见问题与处理

| 问题 | 原因 | 处理 |
| --- | --- | --- |
| 服务启动报 Nacos 连接失败 | Nacos 未启动或 NACOS_ADDR 错误 | 先执行 deploy-start-services.ps1 启动基础设施，核对 env.json |
| 服务启动报数据库连接失败 | MariaDB 未启动/口令错误/库未初始化 | 检查 DB_HOST/DB_PORT/DB_PASSWORD，执行 deploy-db-init.ps1 |
| 登录报令牌校验失败 | RSA 密钥与 Nacos 配置不一致 | 重新生成密钥并同步 Nacos 配置，重启服务 |
| 客户端无法访问接口 | Web 部署未走网关地址 | 确认客户端配置的 API 地址指向网关 9000 端口 |
| env.json 未生效 | 修改后未重启服务 | 修改 env.json 后需重启对应服务 |

## 12. 参考

- 编译方案：deploy/build.md
- 产品需求文档 v0.2.5：docs/cso-v0.2.5/cso-prd-v0.2.5.md（F-001 ~ F-007 部署资产集中化需求）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
