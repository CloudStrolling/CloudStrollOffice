# 部署方案（deploy.md）

**项目名称**：云漫智企（CloudStrollOffice）
**项目英文缩写**：cso
**适用版本**：v0.2.8（cloudoffice-common 服务化改造与通用配置管理接口先行：common 独立部署、Nacos 注册、健康检查、配置查询接口、编译/部署脚本与文档更新）
**文档位置**：deploy/deploy.md
**最近更新**：2026-08-13

## 1. 文档说明

本文档说明云漫智企（CloudStrollOffice）v0.2.8 版本的部署方法与运维操作。

自 v0.2.5 起，项目执行"部署资产集中化"策略：**deploy 目录是部署资产的唯一落点**，交付与运维人员在 `deploy` 目录即可完成全部部署操作（jar 包、客户端产物、env 配置、部署脚本全部集中于此）。

**v0.2.7 部署要点（脚本体系重构，见 docs/cso-v0.2.7/cso-prd-v0.2.7.md）**：
1. 全部脚本统一经 `load-env.ps1` / `load-env.sh` 从 `deploy/env.json` 加载配置（F-001），脚本内无硬编码环境地址与凭据；
2. 部署前检查：`deploy-check-env`（F-002~F-005/F-010）基于 env.json 检查 JDK/MariaDB/Redis/Nacos 可用性与运行状态（F-006），输出通过/警告/失败分级；
3. 基础设施一键启动：`deploy-start-services`（F-007）检测未运行的 MariaDB/Redis/Nacos 并自动启动（MariaDB → Redis → Nacos），启动后探测确认，不报假成功；
4. 后端服务一键启动：`deploy-start-all`（F-008）按 **gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）** 顺序启动 4 个 Java 服务，每服务健康确认成功后再启动下一个；
5. 单服务启动脚本（F-009）：`deploy-start-gateway/auth/biz/system` 支持按需单独启动，行为与一键启动一致；
6. RSA 密钥脚本契约对齐（F-011）：`deploy-rsa-keygen.sh` 与 `.ps1` 均输出 DER 编码单行 Base64（公钥 X.509 / 私钥 PKCS#8），弃用脚本残留已移除；
7. 仓库治理（F-012）：生成、测试、调试临时/中间文件已由 `.gitignore` 排除，`git status` 不再出现过程文件。

**v0.2.8 部署要点（common 服务化与通用配置管理，见 docs/cso-v0.2.8/cso-prd-v0.2.8.md）**：
1. **common 服务化**（F-001/F-002）：cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务（端口 9300，jar `cloudoffice-common.jar`），注册到 Nacos（服务名 `cloudoffice-common`），提供健康检查端点 `/api/v1/common/health` 与 SpringDoc OpenAPI 文档（分组 common）；
2. **通用配置管理接口**（F-003）：common 新增通用配置查询接口 `GET /api/v1/common/config`、`GET /api/v1/common/config/{serviceName}`，统一管理 gateway/auth/biz/system/common 五个微服务的运行时配置（启动环境变量除外），本版本仅交付查询接口，增删改与后端管理界面在后续版本迭代；
3. **编译脚本纳入 common 产物**（F-007）：`build-backend` 将 common 纳入编译产物输出范围，生成可部署 jar 到 deploy 目录（5 个服务 jar 校验）；
4. **部署启动顺序含 common**（F-008/ADR-019）：`deploy-start-all` 服务清单新增 common 并置于第一位，按 **common（9300）→ gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）** 顺序启动，common 最先启动且健康确认成功后再启动 gateway；
5. **部署停止顺序含 common**（F-009/ADR-019）：`deploy-stop-all` 服务清单新增 common 并置于最后一位，按 **system（9400）→ biz（9200）→ auth（9100）→ gateway（9000）→ common（9300）** 逆序停止，common 最后停止；
6. **环境变量补充**（F-012）：`env.json` / `env.example.json` 新增 `COMMON_PORT`（common 服务端口，示例 9300）。

## 2. 部署架构

| 组件 | 产物/依赖 | 默认端口 | 说明 |
| --- | --- | --- | --- |
| 公共服务 cloudoffice-common | deploy/cloudoffice-common.jar | 9300 | 公共模块 + 通用配置管理服务（v0.2.8 服务化：健康检查、通用配置查询接口、SpringDoc） |
| API 网关 cloudoffice-gateway | deploy/cloudoffice-gateway.jar | 9000 | 统一入口，客户端全部请求经网关转发（Reactive WebFlux） |
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
| OpenSSL | 1.1+（仅 RSA 密钥生成脚本需要） | deploy-rsa-keygen.ps1 / .sh 依赖 openssl 命令 |
| Web 服务器 | Nginx 等任意静态服务器（仅 Web 客户端需要） | 承载 deploy/cloudoffice-flutter-app/web/ |

## 4. deploy 目录结构

```
deploy/
├── cloudoffice-common.jar            # 公共服务最终可执行 jar（v0.2.8 服务化新增）
├── cloudoffice-gateway.jar           # 后端最终可执行 jar（v0.2.5 起统一落点）
├── cloudoffice-auth-service.jar
├── cloudoffice-biz-service.jar
├── cloudoffice-system-service.jar
├── env.json                          # 实际环境配置（从 env.example.json 复制填写；不入库）
├── env.example.json                  # 环境配置模板（含 COMMON_PORT，v0.2.8）
├── keys/                             # RSA 密钥对（首次部署生成；不入库）
│   ├── private_key.pem               # PEM 私钥（审计用，不注入）
│   ├── public_key.pem                # PEM 公钥（审计用，不注入）
│   ├── private_key.der               # DER 二进制私钥（PKCS#8）
│   ├── public_key.der                # DER 二进制公钥（X.509）
│   ├── private_key_base64.txt        # DER 单行 Base64 私钥（env.json 注入值）
│   └── public_key_base64.txt         # DER 单行 Base64 公钥（env.json 注入值）
├── logs/                             # 服务启动日志与 PID（运行时生成；不入库）
├── cloudoffice-flutter-app/          # 客户端最终产物（web/、windows/）
├── build.md                          # 编译方案（本文档同目录）
├── deploy.md                         # 部署方案（本文档）
└── scripts/                          # 部署运维脚本（全部 .sh/.ps1，v0.2.7 重构，v0.2.8 扩展 common）
    ├── load-env.ps1 / .sh            # 统一配置加载模块（F-001：env.json → 环境变量）
    ├── deploy-check-env.ps1 / .sh    # 环境可用性 + 运行状态检查（F-002~F-006/F-010）
    ├── deploy-start-services.ps1 / .sh # 基础设施检测与一键启动（F-007，MariaDB→Redis→Nacos）
    ├── deploy-start-all.ps1 / .sh      # 后端服务按序一键启动总入口（F-008，common→gateway→auth→biz→system）
    ├── deploy-stop-all.ps1 / .sh       # 后端服务一键停止（F-009，system→biz→auth→gateway→common）
    ├── deploy-start-common.ps1 / .sh   # 单服务启动：公共服务（F-009，v0.2.8 新增）
    ├── deploy-stop-common.ps1 / .sh    # 单服务停止：公共服务（F-009，v0.2.8 新增）
    ├── deploy-start-gateway.ps1 / .sh  # 单服务启动：网关（F-009）
    ├── deploy-start-auth.ps1 / .sh     # 单服务启动：认证服务（F-009）
    ├── deploy-start-biz.ps1 / .sh      # 单服务启动：企业服务（F-009）
    ├── deploy-start-system.ps1 / .sh   # 单服务启动：系统服务（F-009）
    ├── deploy-rsa-keygen.ps1 / .sh     # RSA 密钥对生成（F-011，DER 单行 Base64 契约）
    ├── deploy-db-init.ps1 / .sh        # 数据库初始化
    ├── build-backend.ps1 / .sh         # 一键后端编译（v0.2.8 纳入 common 产物）
    └── build-client.ps1 / .sh          # 一键客户端编译
```

## 5. 部署步骤

### 5.1 准备部署资产

1. 获取编译产物：按 deploy/build.md 执行后端 `mvn clean package -DskipTests` 与客户端 `build-release.ps1`，确认 jar 位于 `deploy/`、客户端产物位于 `deploy/cloudoffice-flutter-app/`。
2. 确认部署主机已安装 JDK 21、MariaDB、Redis、Nacos（见第 3 节）。

### 5.2 环境配置（env.json）

全部脚本（v0.2.7 起）统一经 `load-env` 从 `deploy/env.json` 加载配置（F-001），**脚本内不硬编码环境地址与凭据**：

```powershell
# 复制模板并填写实际值（数据库口令、RSA 密钥等）
Copy-Item deploy\env.example.json deploy\env.json
# 编辑 deploy\env.json，填写 NACOS_ADDR/NACOS_HOME、DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD、
# REDIS_HOST/REDIS_PORT/REDIS_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等
```

配置项说明见第 6 节。**严禁将含真实口令的 env.json 提交到 git**（`.gitignore` 已排除 `env.json` 与 `keys/`）。

### 5.3 生成 RSA 密钥对（首次部署必做）

**密钥契约（ADR-015，v0.2.6 确立；v0.2.7 起 .ps1 与 .sh 双平台对齐，F-011）**：env.json 注入的 `RSA_PRIVATE_KEY` / `RSA_PUBLIC_KEY` 必须是 **DER 编码单行 Base64**——
- 公钥 = X.509 SubjectPublicKeyInfo 的 DER 二进制转单行 Base64（无 `-----BEGIN/END-----` 头尾、无换行）；
- 私钥 = PKCS#8 PrivateKeyInfo 的 DER 二进制转单行 Base64（同上）。

该格式与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec` / `PKCS8EncodedKeySpec` 解码契约严格一致；**严禁使用 PEM 文件整体 Base64（多行、含 BEGIN/END 标记）注入**，否则网关启动报 `RSA 公钥解析失败`（历史缺陷 T-02，v0.2.6 修复；v0.2.7 将 .sh 对齐同一契约）。

Windows 环境执行：

```powershell
.\deploy\scripts\deploy-rsa-keygen.ps1
```

Linux 环境执行：

```bash
./deploy/scripts/deploy-rsa-keygen.sh
```

脚本输出到 `deploy/keys/`（.ps1/.sh 一致）：
- `private_key.pem` / `public_key.pem`：PEM 格式审计副本（**不用于注入**）；
- `private_key.der` / `public_key.der`：DER 二进制（私钥经 `openssl pkcs8 -topk8 -nocrypt` 显式输出 PKCS#8）；
- `private_key_base64.txt` / `public_key_base64.txt`：**DER 单行 Base64，env.json 注入值来源**（脚本内置契约自校验：无 PEM 头尾、无换行、严格 Base64 可解码、DER 结构为 PKCS#8/X.509）。

将两个 `*_base64.txt` 内容分别填入 `deploy/env.json` 的 `RSA_PRIVATE_KEY` 与 `RSA_PUBLIC_KEY`，并同步 Nacos 配置。密钥变更后旧令牌全部失效，属预期行为。**私钥不写入日志、不提交 git**。

### 5.4 数据库初始化

前置条件：MariaDB 已启动且可连接（可由 5.5 步骤先拉起）。

```powershell
.\deploy\scripts\deploy-db-init.ps1
```

脚本从 env.json 读取数据库连接信息（经 load-env，口令经 MYSQL_PWD 传递不出现于命令行），执行 `scripts/sql/` 下初始化 SQL（auth-init-v0.1.5.sql、auth-init-v0.1.6.sql 等），创建认证库 `cloudstroll_office_auth` 及表结构与初始数据。

### 5.5 启动基础设施（MariaDB / Redis / Nacos）

v0.2.7 起基础设施管理与后端服务启动职责分离（F-006/F-007/F-008），分两个脚本执行：

```powershell
# 步骤一：环境检查（可选，仅检查不启动；输出通过/警告/失败分级，F-002~F-006/F-010）
.\deploy\scripts\deploy-check-env.ps1

# 步骤二：基础设施运行状态检测与一键启动（F-006/F-007）
.\deploy\scripts\deploy-start-services.ps1
```

`deploy-start-services` 脚本功能：加载 env.json → 三重检测（命令/服务/进程）MariaDB、Redis、Nacos 安装状态 → 检测运行状态 → 未运行则按 **MariaDB → Redis → Nacos** 顺序自动启动（系统服务优先，其次可执行文件 / NACOS_HOME startup 脚本）→ 启动后循环探测确认（不报假成功）→ 输出分级汇总。JDK 仅检查可用性，不执行启动。

### 5.6 启动后端服务

**推荐一键启动（F-008）**：按部署顺序 common → gateway → auth → biz → system 逐个启动 5 个服务，前置校验（JDK + 5 个 jar + 关键环境变量）+ 每服务健康确认（成功后再启动下一个，失败即停）。**common 在所有后端服务中最先启动且健康确认成功后再启动 gateway**（v0.2.8 / ADR-019）：

```powershell
.\deploy\scripts\deploy-start-all.ps1
```

**一键停止（F-009）**：按 system → biz → auth → gateway → common 逆序停止 5 个服务，common 最后停止（v0.2.8 / ADR-019）：

```powershell
.\deploy\scripts\deploy-stop-all.ps1
```

**单服务启动（F-009）**：按需单独启动（行为与一键启动中对应服务一致，均后台运行、日志落位 deploy/logs/）：

```powershell
.\deploy\scripts\deploy-start-common.ps1   # 公共服务（v0.2.8 新增，建议最先启动）
.\deploy\scripts\deploy-start-gateway.ps1  # 网关（统一入口）
.\deploy\scripts\deploy-start-auth.ps1     # 认证服务
.\deploy\scripts\deploy-start-biz.ps1      # 企业服务
.\deploy\scripts\deploy-start-system.ps1   # 系统服务
```

**单服务停止（F-009）**：

```powershell
.\deploy\scripts\deploy-stop-common.ps1    # 公共服务（v0.2.8 新增）
```

也可直接执行：

```powershell
java -Xms256m -Xmx512m -jar deploy\cloudoffice-common.jar
java -Xms256m -Xmx512m -jar deploy\cloudoffice-gateway.jar
java -Xms256m -Xmx512m -jar deploy\cloudoffice-auth-service.jar
# ... 其余服务同理
```

Linux 环境使用对应 .sh 脚本（如 `./deploy/scripts/deploy-start-all.sh`、`./deploy/scripts/deploy-start-common.sh`）。

**部署顺序契约**：common（9300）→ gateway（9000）→ auth（9100）→ biz（9200）→ system（9400），由 deploy-start-all 脚本数组顺序保证；停止顺序为 system（9400）→ biz（9200）→ auth（9100）→ gateway（9000）→ common（9300）。单服务启动亦按此顺序执行（依赖：服务经 Nacos 注册发现，基础设施须先就绪；common 作为公共依赖与配置提供方最先启动，确保后续服务启动时可通过 Nacos 服务发现获取 common 的配置接口）。

### 5.7 部署客户端

**Web 客户端**：将 `deploy/cloudoffice-flutter-app/web/` 整个目录部署到 Nginx（或任意静态服务器），例如 Nginx 站点根指向该目录后访问 `http://<服务器>/`。

**Windows 客户端**：将 `deploy/cloudoffice-flutter-app/windows/` 目录拷贝到目标机器，运行 `cloudoffice_flutter_app.exe` 即可。

## 6. 配置说明（deploy/env.json）

**deploy/env.json 是全部部署脚本（v0.2.7 起，F-001）的唯一配置源**：脚本经 `load-env.ps1` / `load-env.sh` 统一加载，脚本内不硬编码环境地址与凭据；缺失或非法时明确报错并拒绝执行。env.json 与 env.example.json 的差异（键名、契约）见模板注释与脚本契约校验。

| 配置项 | 说明 | 示例 |
| --- | --- | --- |
| NACOS_ADDR | Nacos 地址（host:port） | 127.0.0.1:8848 |
| NACOS_HOME | Nacos 安装目录（Windows 启动检测用） | D:\develop\nacos |
| COMMON_PORT | 公共服务 cloudoffice-common 端口（v0.2.8 新增） | 9300 |
| DB_SERVICE_NAME / DB_PROCESS_NAME | 数据库服务/进程名（检测用，逗号分隔） | MySQL, MariaDB / mysqld, mariadbd |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | Redis 服务/进程名（检测用） | Redis / redis-server |
| DB_HOST / DB_PORT | 数据库地址与端口 | 127.0.0.1 / 3306 |
| DB_USERNAME / DB_PASSWORD | 数据库账号与口令 | root / <DB_PASSWORD> |
| DB_USER | 数据库用户（兼容项） | root |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD / REDIS_DATABASE | Redis 连接配置 | 127.0.0.1 / 6379 / 空 / 0 |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | JWT 签名 RSA 密钥对。**v0.2.6 起必须为 DER 编码单行 Base64**（私钥 PKCS#8 / 公钥 X.509 SubjectPublicKeyInfo，无 PEM 头尾、无换行；来源为 deploy/keys/*_base64.txt） | <RSA_PRIVATE_KEY> / <RSA_PUBLIC_KEY> |
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
| 前置检查（可用性 + 运行状态） | `.\deploy\scripts\deploy-check-env.ps1` |
| 基础设施检测与一键启动 | `.\deploy\scripts\deploy-start-services.ps1` |
| 后端服务按序一键启动（common→gateway→auth→biz→system） | `.\deploy\scripts\deploy-start-all.ps1` |
| 后端服务一键停止（system→biz→auth→gateway→common） | `.\deploy\scripts\deploy-stop-all.ps1` |
| 启动公共服务 | `.\deploy\scripts\deploy-start-common.ps1` |
| 启动网关 | `.\deploy\scripts\deploy-start-gateway.ps1` |
| 启动认证服务 | `.\deploy\scripts\deploy-start-auth.ps1` |
| 启动企业服务 | `.\deploy\scripts\deploy-start-biz.ps1` |
| 启动系统服务 | `.\deploy\scripts\deploy-start-system.ps1` |
| 停止公共服务 | `.\deploy\scripts\deploy-stop-common.ps1` |
| 数据库初始化 | `.\deploy\scripts\deploy-db-init.ps1` |
| RSA 密钥生成（.ps1/.sh 契约一致） | `.\deploy\scripts\deploy-rsa-keygen.ps1` |
| 加载环境变量 | `. .\deploy\scripts\load-env.ps1` |
| 停止服务 | 对应启动窗口 Ctrl+C；或停止 java 进程（`Stop-Process -Name java` 需甄别进程）；一键启动场景可查 `deploy/logs/{module}.pid` 定位进程；推荐使用 `deploy-stop-all.ps1` 一键逆序停止（含 common） |

Linux 环境将命令替换为 `./deploy/scripts/*.sh` 即可。

**典型部署链路（一条命令拉起整个后端环境）**：
```powershell
.\deploy\scripts\deploy-start-services.ps1   # 1. 基础设施检测与一键启动（MariaDB/Redis/Nacos）
.\deploy\scripts\deploy-start-all.ps1        # 2. 后端服务按序一键启动（common→gateway→auth→biz→system）
```

## 8. 健康检查

| 检查项 | 方式 | 预期 |
| --- | --- | --- |
| 环境检查（一键） | `.\deploy\scripts\deploy-check-env.ps1` | 输出通过/警告/失败分级汇总：JDK/MariaDB/Redis/Nacos 可用性与运行状态 |
| 公共服务存活 | 访问 http://<主机>:9300/api/v1/common/health | 返回统一 ApiResult 响应体（服务名 cloudoffice-common、状态 UP、版本与时间戳） |
| 网关存活 | 访问 http://<主机>:9000/ | 返回网关响应（如 404/401 均说明服务在运行） |
| 各服务注册 | Nacos 控制台 http://<主机>:8848/nacos/ 服务列表 | common/gateway/auth/biz/system 均在线 |
| 认证接口 | POST http://<主机>:9000/（客户端实际调用路径） | 返回正常业务响应 |
| 数据库连通 | 服务日志无数据库连接异常 | 正常 |
| 服务健康检查接口 | GET http://<主机>:9000/api/v1/common/health（经网关，白名单放行）；GET http://<主机>:9000/api/v1/auth/health（经网关，带 Token） | 返回服务名/状态/版本/时间戳，状态正常 |
| Web 客户端 | 浏览器访问 Web 站点 | 页面可打开、可登录 |

**v0.2.7 验证结论**：脚本体系重构后 .ps1/.sh 双平台契约与退出码约定全部通过自校验（见 docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md）；v0.2.6 接口回归 TC-001~051 全量 PASS=72、FAIL=0 无回归。

## 9. 日志查看

- 后端服务后台启动（deploy-start-all / deploy-start-*）日志落位 **`deploy/logs/`**：`{module}-start.log`（标准输出）、`{module}-start.err`（错误）、`{module}.pid`（进程 PID）。
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
| RSA 密钥格式/密钥变更 | 1) 用 deploy-rsa-keygen.ps1 重新生成密钥（DER 单行 Base64）；2) 更新 env.json 并同步 Nacos；3) 重启 gateway/auth；4) 旧令牌失效属预期，客户端重新登录 |

**通用回滚建议**：发布前对 `deploy/` 目录做整体备份（jar + env.json + 客户端产物），回滚时整体还原并重启服务。

## 11. 常见问题与处理

| 问题 | 原因 | 处理 |
| --- | --- | --- |
| 服务启动报 Nacos 连接失败 | Nacos 未启动或 NACOS_ADDR 错误 | 先执行 deploy-start-services.ps1 启动基础设施，核对 env.json |
| 脚本报 env.json 缺失或关键配置缺失 | deploy/env.json 未创建或关键项未填 | 复制 `deploy\env.example.json` 为 `deploy\env.json` 并填写 NACOS_ADDR/NACOS_HOME/DB_*/REDIS_* 等关键项（缺失项逐个列出，仅提示键名） |
| deploy-check-env 输出失败项 | JDK 版本非 21 / MariaDB 不可连接 / Redis ping 不通 / Nacos 未运行 | 按失败项提示处理（安装 JDK 21 并配置 JAVA_HOME、检查 DB_*/REDIS_* 配置、执行 deploy-start-services 拉起基础设施），处理后重新检查 |
| deploy-start-services 启动超时 | 服务启动慢或需管理员权限 | 等待数秒重试；提示权限问题时以管理员身份运行；查看各服务日志定位（Nacos 见 Nacos logs/start.out） |
| deploy-start-all 提示 jar 缺失 | 未构建或 jar 未落位 deploy/ | 执行 `.\deploy\scripts\build-backend.ps1` 构建，确认 deploy/ 下 5 个 jar 存在（含 cloudoffice-common.jar） |
| 一键启动提示端口被占用 | 9000/9100/9200/9400/9300 端口被占用 | `netstat -ano | findstr 9300` 定位占用进程，释放端口后重试 |
| 服务启动报 `No spring.config.import property has been defined` | 模块 pom 缺少 `spring-cloud-starter-bootstrap`，bootstrap.yml 未加载（v0.0.1 基线遗留，v0.2.6 已修复） | 确认 5 个服务模块 pom 已引入该依赖并重新构建 jar；升级到 v0.2.6+ jar |
| common 服务启动失败或健康检查不通过 | Nacos 未启动 / COMMON_PORT 未配置 / DB_PASSWORD 缺失 / common jar 缺失 / 端口被占用 | 核对 env.json（NACOS_ADDR/COMMON_PORT/DB_PASSWORD），确认 cloudoffice-common.jar 已构建落位，检查 9300 端口占用，查看 deploy/logs/common-start.log |
| 网关启动报 `RSA 公钥解析失败` | env.json 密钥为 PEM 整体 Base64（多行、含 BEGIN/END），与 DER 单行 Base64 契约不符 | 用 deploy-rsa-keygen.ps1（或 .sh）重新生成密钥，取 `deploy/keys/*_base64.txt` 单行值注入 env.json，同步 Nacos，重启服务 |
| 网关启动报 "Spring MVC found on classpath" / "Failed to configure a DataSource" | 网关 jar 未排除 common 传递的 MVC/MyBatis 依赖（v0.2.6 已修复） | 使用 v0.2.6 重建的 cloudoffice-gateway.jar；自行构建时确认 gateway pom 已排除 spring-boot-starter-web / springdoc-openapi-starter-webmvc-ui / mybatis-plus-spring-boot3-starter |
| 登录报令牌校验失败 | RSA 密钥与 Nacos 配置不一致 | 重新生成密钥并同步 Nacos 配置，重启服务 |
| 客户端无法访问接口 | Web 部署未走网关地址 | 确认客户端配置的 API 地址指向网关 9000 端口 |
| env.json 未生效 | 修改后未重启服务 | 修改 env.json 后需重启对应服务 |
| Linux 下用 deploy-rsa-keygen.sh 生成的密钥网关解析失败 | v0.2.6 及以前 .sh 输出 PEM 整体 Base64，与 DER 单行 Base64 契约不符 | 升级到 v0.2.7 的 deploy-rsa-keygen.sh（已与 .ps1 契约对齐，输出 DER 单行 Base64）；重新生成密钥并同步 Nacos |
| git status 出现临时/中间文件 | .gitignore 未覆盖新类型过程文件 | 按 F-012 治理要求补充排除规则（JVM 调试产物、测试缓存、工具残留等），保持分区注释清晰 |

## 12. 参考

- 编译方案：deploy/build.md
- 产品需求文档 v0.2.8：docs/cso-v0.2.8/cso-prd-v0.2.8.md（F-001/F-002 common 服务化 / F-003~F-005 通用配置管理接口 / F-006 网关路由 / F-007 编译脚本 / F-008 启动顺序含 common / F-009 停止顺序含 common / F-010 deploy.md / F-011 readme / F-012 env.json）
- 系统架构设计 v0.2.8：docs/sad.md（ADR-017 common 服务化、ADR-018 通用配置管理接口先行、ADR-019 部署顺序含 common）
- 产品需求文档 v0.2.7：docs/cso-v0.2.7/cso-prd-v0.2.7.md（F-001 load-env 统一加载 / F-007 基础设施一键启动 / F-008 后端按序一键启动 / F-011 脚本契约 / F-012 .gitignore 治理）
- 脚本问题清单 v0.2.7：docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md（重构前问题盘点与修复闭环）
- 脚本契约总体验证 v0.2.7：docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md（.ps1/.sh 双平台契约自校验结果）
- 产品需求文档 v0.2.6：docs/cso-v0.2.6/cso-prd-v0.2.6.md（F-001 bootstrap 依赖 / F-002 RSA 密钥契约 / F-003 服务启动验证 / F-004 基线回归闭环 / F-005 契约无回归）
- 接口回归报告 v0.2.6：docs/cso-v0.2.6/regression-api-test.md（TC-001~051 全量 PASS=72、FAIL=0，T-02 闭环）
- 产品需求文档 v0.2.5：docs/cso-v0.2.5/cso-prd-v0.2.5.md（F-001 ~ F-007 部署资产集中化需求）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
