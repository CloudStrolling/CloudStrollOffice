# 脚本使用说明（usage.md）

**项目名称**：云漫智企（CloudStrollOffice）
**项目英文缩写**：cso
**适用版本**：v0.2.7（部署脚本体系重构与仓库清洁度治理；全部脚本见本文档）
**文档位置**：deploy/scripts/usage.md
**最近更新**：2026-08-11

## 1. 文档说明

本文档详细介绍 `deploy/scripts/` 下每个脚本的功能、用法与正常返回内容，作为运维与开发人员的脚本速查手册。

### 1.1 脚本体系概览（v0.2.7）

全部脚本分为四类，每个功能均提供 PowerShell（Windows）与 Bash（Linux）双平台版本，且 **.ps1 与 .sh 行为契约完全一致**：

| 类别 | 脚本 | 说明 |
| --- | --- | --- |
| 统一配置加载 | `load-env` | 从 `deploy/env.json` 加载配置为环境变量，供其他脚本调用（F-001） |
| 环境管理 | `deploy-check-env` | 环境可用性 + 运行状态检查，仅检查不启动（F-002~F-006/F-010） |
| 环境管理 | `deploy-start-services` | 基础设施（MariaDB/Redis/Nacos）检测与一键启动（F-007） |
| 服务启动 | `deploy-start-all` | 后端 4 服务按序一键启动（F-008） |
| 服务启动 | `deploy-start-gateway` | 单服务启动：网关（F-009） |
| 服务启动 | `deploy-start-auth` | 单服务启动：认证服务（F-009） |
| 服务启动 | `deploy-start-biz` | 单服务启动：企业服务（F-009） |
| 服务启动 | `deploy-start-system` | 单服务启动：系统服务（F-009） |
| 安全工具 | `deploy-rsa-keygen` | RSA 密钥对生成（DER 单行 Base64 契约，F-011） |
| 数据库 | `deploy-db-init` | 数据库初始化（建库 + 表结构 + 初始数据） |
| 编译 | `build-backend` | 后端 Maven 多模块一键编译，jar 落位 deploy/ |
| 编译 | `build-client` | 客户端 Flutter 一键编译，产物落位 deploy/cloudoffice-flutter-app/ |
| Web 启动 | `serve-web` | 用 Python http.server 启动 Web 静态站点（http://127.0.0.1:{port}/） |

### 1.2 通用约定（F-011 输出分级与退出码，全部脚本一致）

| 约定 | 内容 |
| --- | --- |
| 输出分级 | 通过（绿）/ 警告（黄）/ 失败（红），双平台一致、不使用 emoji |
| 退出码 | 存在失败项退出 1；存在警告但无失败退出 0；全部通过退出 0 |
| 配置来源 | 除 build-* 与 load-env、deploy-rsa-keygen 外，脚本均经 `load-env` 从 `deploy/env.json` 加载配置，**不硬编码环境地址与凭据** |
| 安全约定 | `DB_PASSWORD` / `RSA_PRIVATE_KEY` 等敏感值经环境变量（MYSQL_PWD / REDISCLI_AUTH）传递，**任何输出与日志不打印明文**，缺失校验仅输出键名 |
| 前置条件 | `deploy/env.json` 必须存在且包含关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失时 load-env 明确报错并拒绝执行 |

### 1.3 环境配置准备（使用前必做）

```powershell
# 复制模板并填写实际值（数据库口令、RSA 密钥等）
Copy-Item deploy\env.example.json deploy\env.json
```

`env.json` 含真实口令与密钥，**严禁提交 git**（`.gitignore` 已排除 `env.json` 与 `keys/`）。

### 1.4 典型部署链路

```powershell
# 1. 生成 RSA 密钥对（首次必做），取 *_base64.txt 填入 env.json 的 RSA_PRIVATE_KEY / RSA_PUBLIC_KEY
.\deploy\scripts\deploy-rsa-keygen.ps1

# 2. 环境检查（可选，仅检查不启动）
.\deploy\scripts\deploy-check-env.ps1

# 3. 基础设施检测与一键启动（MariaDB → Redis → Nacos）
.\deploy\scripts\deploy-start-services.ps1

# 4. 数据库初始化
.\deploy\scripts\deploy-db-init.ps1

# 5. 后端服务按序一键启动（gateway → auth → biz → system）
.\deploy\scripts\deploy-start-all.ps1
```

> 编译产物缺省时先执行 `build-backend.ps1` 与 `build-client.ps1`；Linux 环境将命令替换为对应 `.sh` 即可（如 `./deploy/scripts/deploy-check-env.sh`）。

---

## 2. load-env.ps1 / load-env.sh — 统一配置加载模块

### 2.1 功能
从 `deploy/env.json` 读取全部键值对并注入当前会话环境变量，供其他脚本统一使用：
- `env.json` 缺失时提示复制 `env.example.json` 并填写配置，非零退出；
- 包含键名合法性白名单校验（仅允许 `[A-Za-z_][A-Za-z0-9_]*`）与 8 项关键配置缺失校验（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）；
- 敏感值仅注入环境变量，不打印明文。

### 2.2 用法（须以 dot-source / source 方式调用，加载的环境变量在当前会话生效）

```powershell
# Windows（PowerShell）
. .\deploy\scripts\load-env.ps1 [-EnvFile env.json]
```

```bash
# Linux（Bash；为 source 型脚本，失败用 return 而非 exit，避免终止父 shell）
source deploy/scripts/load-env.sh [env.json]
```

Linux 环境依赖 `jq`（优先）或 `python3`（回退）解析 JSON。

### 2.3 正常返回内容
```
环境变量已从 D:\...\deploy\env.json 加载，共 23 项        （.ps1，绿色）
环境变量已从 /path/to/deploy/env.json 加载 (jq)，共 23 项  （.sh）
```
退出码 0；任一校验失败（文件缺失/JSON 非法/非法键名/关键配置缺失）输出对应 `错误:` 信息并返回非零。

---

## 3. deploy-check-env.ps1 / deploy-check-env.sh — 环境可用性与运行状态检查

### 3.1 功能
基于 env.json 执行 **阶段一 环境可用性检查 + 阶段二 运行状态检测**，仅检查、不执行任何启动动作：
- **JDK**：java 命令可执行 + JAVA_HOME 有效 + 版本 21；
- **MariaDB**：命令/系统服务/进程三重安装检测 + SELECT 1 连通性（口令掩码 `****`）；
- **Redis**：三重安装检测 + `redis-cli ping` 返回 PONG；
- **Nacos**：NACOS_HOME 安装检测 + HTTP 探测 `http://NACOS_ADDR/nacos/` 返回含 Nacos；
- 运行状态：JDK 复用可用性结论；MariaDB/Redis 进程/系统服务 Running/TCP 端口任一命中即运行中；Nacos 以 HTTP 探测为主、java 进程命令行辅助。

### 3.2 用法

```powershell
.\deploy\scripts\deploy-check-env.ps1
```
```bash
./deploy/scripts/deploy-check-env.sh
```

### 3.3 正常返回内容（全部通过时）
```
==============================================
  云漫智企 (CloudStrollOffice) 环境可用性检查与运行状态检测
  版本: v0.2.7
  日期: 2026-08-11 12:00:00
==============================================

━━━ 阶段一: 环境可用性检查 ━━━
  [通过] JDK 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21）
  [通过] MariaDB 可用（安装: 服务 MySQL；SELECT 1 连接成功，口令掩码 ****）
  [通过] Redis 可用（安装: 服务 Redis；ping 返回 PONG）
  [通过] Nacos 可用（已安装: ...；HTTP 探测 http://127.0.0.1:8848/nacos/ 返回 Nacos）

━━━ 阶段二: 运行状态检测 ━━━
  [通过] JDK 运行状态: 就绪（复用可用性检查结论）
  [通过] MariaDB 运行状态: 运行中...
  [通过] Redis 运行状态: 运行中...
  [通过] Nacos 运行状态: 运行中...

==============================================
  检查完成: 通过 8 项 | 警告 0 项 | 失败 0 项
==============================================

全部检查通过，可以继续进行部署。
```
退出码：无失败退出 0（有警告同样退出 0 并提示）；存在失败项退出 1。

---

## 4. deploy-start-services.ps1 / deploy-start-services.sh — 基础设施一键启动

### 4.1 功能
检测并启动基础设施（F-006/F-007）：
- **JDK**：仅检查可用性，输出就绪/缺失结论，不执行启动；
- **MariaDB / Redis / Nacos**：未安装不尝试启动（计入失败）；已运行幂等跳过；未运行则按 **MariaDB → Redis → Nacos** 顺序自动启动（系统服务优先，其次可执行文件 / NACOS_HOME 启动脚本）；
- 每次启动后循环探测确认（进程/TCP/ping/HTTP，默认超时 30s、间隔 2s），**不报假成功**。

### 4.2 用法

```powershell
.\deploy\scripts\deploy-start-services.ps1
```
```bash
./deploy/scripts/deploy-start-services.sh
```
> 系统服务启动在权限不足时报错提示，此时请以管理员身份（Windows）或 sudo（Linux）重新运行。

### 4.3 正常返回内容（全部就绪时）
```
==============================================
  云漫智企 (CloudStrollOffice) 基础设施运行状态检查与一键启动
...
━━━ JDK 可用性（仅检查，不启动） ━━━
  [通过] JDK: 可用（java 命令可执行 + JAVA_HOME 有效 + 版本 21），无需启动

━━━ MariaDB（运行检测 → 启动 → 循环探测确认） ━━━
  [通过] MariaDB: 已运行（进程/系统服务/TCP 任一命中），幂等跳过

━━━ Redis（运行检测 → 启动 → 循环探测确认） ━━━
  [通过] Redis: 已运行（进程/系统服务/TCP/redis-cli ping 任一命中），幂等跳过

━━━ Nacos（运行检测 → 启动 → 循环 HTTP 探测确认） ━━━
  [通过] Nacos: 已运行（HTTP 探测或 java 进程含 nacos），幂等跳过

==============================================
  基础设施启动完成: 通过 5 项 | 警告 0 项 | 失败 0 项
  基础设施（MariaDB/Redis/Nacos）全部可达，可启动后端服务（deploy-start-all）。
==============================================

基础设施全部就绪。
```
退出码：存在失败项退出 1；存在警告无失败退出 0；全部通过退出 0。

---

## 5. deploy-start-all.ps1 / deploy-start-all.sh — 后端服务按序一键启动

### 5.1 功能
按 **gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）** 顺序后台启动 4 个后端服务（F-008）：
- **前置校验**：JDK 可用 + 4 个 jar 包存在 + 各服务关键环境变量就绪（任一缺失列出缺失项、退出码 1、不启动任何服务）；
- 每服务启动后健康确认：HTTP 直连自身端口（gateway `http://localhost:9000/`，其余 `http://localhost:{port}/api/v1/{module}/health`），TCP 端口探测备用；默认重试 30 次、间隔 2 秒、单次超时 3 秒（可配置）；
- 确认成功后再启动下一个服务；**任一步骤失败即停**，停止后续启动并退出非零；
- 启动命令：`java -Xms256m -Xmx512m -jar <jar>`，日志落位 `deploy/logs/{module}-start.log/.err`，PID 记录 `deploy/logs/{module}.pid`。

### 5.2 用法

```powershell
.\deploy\scripts\deploy-start-all.ps1
.\deploy\scripts\deploy-start-all.ps1 -RetryCount 60 -RetryInterval 2 -ProbeTimeout 3
```
```bash
./deploy/scripts/deploy-start-all.sh
RETRY_COUNT=60 RETRY_INTERVAL=2 PROBE_TIMEOUT=3 ./deploy/scripts/deploy-start-all.sh
```

PowerShell 参数（.sh 用同名环境变量覆盖，默认值相同）：
| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `-RetryCount` / `RETRY_COUNT` | 30 | 健康确认轮询重试次数 |
| `-RetryInterval` / `RETRY_INTERVAL` | 2 | 轮询间隔秒数 |
| `-ProbeTimeout` / `PROBE_TIMEOUT` | 3 | 单次 HTTP 探测超时秒数 |

### 5.3 正常返回内容（全部成功时）
```
==============================================
  云漫智企 (CloudStrollOffice) 后端服务按序一键启动
...
━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━
  [通过] JDK: java 命令可用
  [通过] 前置校验：4 个 jar 包与关键环境变量全部就绪

━━━ 启动 gateway（端口 9000） ━━━
  java 已后台启动（PID: 12345），日志: ...\deploy\logs\gateway-start.log
  [通过] gateway: 已启动且健康确认成功（http://localhost:9000/）

━━━ 启动 auth（端口 9100） ━━━
  java 已后台启动（PID: 12346），日志: ...\deploy\logs\auth-start.log
  [通过] auth: 已启动且健康确认成功（http://localhost:9100/api/v1/auth/health）

━━━ 启动 biz（端口 9200） ━━━
  ... [通过] biz: 已启动且健康确认成功

━━━ 启动 system（端口 9400） ━━━
  ... [通过] system: 已启动且健康确认成功

==============================================
  后端服务一键启动完成: 通过 6 项 | 警告 0 项 | 失败 0 项
  各服务启动结果与健康状态：
    - gateway（端口 9000）: 通过
    - auth（端口 9100）: 通过
    - biz（端口 9200）: 通过
    - system（端口 9400）: 通过
==============================================

4 个后端服务全部启动成功且健康确认通过。
```
退出码：全部通过退出 0；任一失败退出 1（并输出失败服务与排查提示：端口占用 / 日志路径 / 缺失配置键名）。

---

## 6. deploy-start-gateway / deploy-start-auth / deploy-start-biz / deploy-start-system — 单服务启动

### 6.1 功能
按需单独启动某个后端服务（F-009），行为（前置校验 / 后台启动 / 健康确认 / 日志与 PID 落位 / 安全约定）与 deploy-start-all 中对应服务启动逻辑完全一致。

各服务的契约：

| 脚本 | 服务 | 端口 | jar | 健康检查 URL | 关键环境变量 |
| --- | --- | --- | --- | --- | --- |
| deploy-start-gateway | gateway | 9000 | cloudoffice-gateway.jar | http://localhost:9000/ | NACOS_ADDR, RSA_PUBLIC_KEY |
| deploy-start-auth | auth | 9100 | cloudoffice-auth-service.jar | http://localhost:9100/api/v1/auth/health | NACOS_ADDR, RSA_PUBLIC_KEY, RSA_PRIVATE_KEY, DB_PASSWORD |
| deploy-start-biz | biz | 9200 | cloudoffice-biz-service.jar | http://localhost:9200/api/v1/biz/health | NACOS_ADDR, DB_PASSWORD |
| deploy-start-system | system | 9400 | cloudoffice-system-service.jar | http://localhost:9400/api/v1/system/health | NACOS_ADDR, DB_PASSWORD |

> 备注：auth-service 使用 `DB_USERNAME`、biz-service 使用 `DB_USER`（差异保持现状）；`DB_USERNAME` 已由 load-env 的 8 项关键配置兜底校验。

### 6.2 用法

```powershell
.\deploy\scripts\deploy-start-gateway.ps1
.\deploy\scripts\deploy-start-auth.ps1 -RetryCount 60 -RetryInterval 2 -ProbeTimeout 3
.\deploy\scripts\deploy-start-biz.ps1
.\deploy\scripts\deploy-start-system.ps1
```
```bash
./deploy/scripts/deploy-start-gateway.sh
RETRY_COUNT=60 ./deploy/scripts/deploy-start-auth.sh
./deploy/scripts/deploy-start-biz.sh
./deploy/scripts/deploy-start-system.sh
```
> 单服务启动参数与 deploy-start-all 相同（`-RetryCount` / `-RetryInterval` / `-ProbeTimeout`，默认 30/2/3）。

### 6.3 正常返回内容（以 gateway 为例）
```
==============================================
  云漫智企 (CloudStrollOffice) Gateway 服务启动
...
━━━ 前置校验（JDK / jar 包 / 关键环境变量） ━━━
  [通过] JDK: java 命令可用
  [通过] 前置校验：jar 包与关键环境变量全部就绪

  java 已后台启动（PID: 12345），日志: ...\deploy\logs\gateway-start.log
  [通过] gateway: 已启动且健康确认成功（http://localhost:9000/）

==============================================
  Gateway 服务启动完成: 通过 2 项 | 警告 0 项 | 失败 0 项
==============================================

Gateway 服务启动成功且健康确认通过。
```
退出码：全部通过退出 0；任一失败退出 1。

---

## 7. deploy-rsa-keygen.ps1 / deploy-rsa-keygen.sh — RSA 密钥对生成

### 7.1 功能
生成 RSA 2048 位密钥对，输出 **DER 编码单行 Base64**（F-011 / ADR-015）：
- 私钥 = PKCS#8 PrivateKeyInfo 的 DER 二进制转单行 Base64；
- 公钥 = X.509 SubjectPublicKeyInfo 的 DER 二进制转单行 Base64；
- 无 `-----BEGIN/END-----` 头尾、无换行，与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec` / `PKCS8EncodedKeySpec` 解码契约严格一致；
- 内置契约自校验（无 PEM 头尾、无换行、严格 Base64 可解码、DER 结构为 PKCS#8/X.509），失败即退出非零。

### 7.2 用法（依赖 OpenSSL 命令）

```powershell
.\deploy\scripts\deploy-rsa-keygen.ps1
.\deploy\scripts\deploy-rsa-keygen.ps1 -OutputDir "C:\CloudStroll\keys"
```
```bash
./deploy/scripts/deploy-rsa-keygen.sh
./deploy/scripts/deploy-rsa-keygen.sh /path/to/keys
```

默认输出到 `deploy/keys/`，共 6 个文件：
- `private_key.pem` / `public_key.pem`：PEM 格式审计副本（**不用于注入**）；
- `private_key.der` / `public_key.der`：DER 二进制（Java 契约字节来源）；
- `private_key_base64.txt` / `public_key_base64.txt`：**DER 单行 Base64，env.json 注入值来源**。

### 7.3 正常返回内容
```
==============================================
  云漫智企 RSA 密钥对生成
  输出目录: ...\deploy\keys
  输出契约: DER 编码单行 Base64（无 PEM 头尾、无换行）
==============================================

[1/4] 生成 RSA 2048 位私钥...
  -> 已生成 PEM 私钥（审计用）: ...\private_key.pem
[2/4] 提取公钥并转换为 DER 二进制...
  -> 已生成 PEM 公钥（审计用）: ...\public_key.pem
  -> 已生成 DER 私钥: ...\private_key.der
  -> 已生成 DER 公钥: ...\public_key.der
[3/4] DER 二进制转单行 Base64...
  -> 已生成: ...\private_key_base64.txt
  -> 已生成: ...\public_key_base64.txt
[4/4] 契约自校验...
  私钥 Base64 长度: 1388 字符
  公钥 Base64 长度: 392 字符
  契约校验通过: 无 PEM 头尾、无换行、严格 Base64 解码成功、DER 结构为 PKCS#8/X.509

==============================================
  生成完成！
==============================================

env.json 配置（完整值请从 *_base64.txt 拷贝，此处仅显示前 24 字符前缀）：
  "RSA_PRIVATE_KEY": "MIIEvgIBADAN..."（完整值见 private_key_base64.txt）
  "RSA_PUBLIC_KEY": "MIIBIjANBgkq..."（完整值见 public_key_base64.txt）
```
> 完整私钥值绝不打印（仅 24 字符前缀脱敏），请从 `*_base64.txt` 拷贝填入 env.json 的 `RSA_PRIVATE_KEY` / `RSA_PUBLIC_KEY` 并同步 Nacos。退出码：通过输出 0，失败输出 1。

---

## 8. deploy-db-init.ps1 / deploy-db-init.sh — 数据库初始化

### 8.1 功能
创建业务数据库并初始化表结构与初始数据（建库 cloudstroll_office_auth + 表结构 + 初始数据）：
- 连接参数一律从 env.json 读取（无硬编码默认值），口令经 MYSQL_PWD 环境变量传递（不出现在命令行）；
- 依次执行 `scripts/sql/` 下的 `auth-init-v0.1.5.sql`（7 张核心基础表 + 初始数据）与 `auth-init-v0.1.6.sql`（新增 2 张表 + 字段扩展）；
- 最后执行验证：数据库列表、表列表、租户/用户初始数据查询。
- **前置条件**：MariaDB 已启动且可连接（可由 deploy-start-services 先拉起）。

### 8.2 用法

```powershell
.\deploy\scripts\deploy-db-init.ps1
```
```bash
./deploy/scripts/deploy-db-init.sh
```
> PowerShell 版可选择覆盖连接参数：`-DbHost` / `-DbPort` / `-DbUser` / `-DbPassword`（默认均从 env.json 读取）。

### 8.3 正常返回内容
```
==============================================
  云漫智企 - 数据库初始化
==============================================
  数据库主机: 127.0.0.1:3306
  用户名:     root
==============================================

[1/3] 执行 v0.1.5 基础初始化脚本...
  执行: mariadb -h 127.0.0.1 -P 3306 -u root -p'****' < auth-init-v0.1.5.sql
  ✅ v0.1.5 基础初始化完成（7 张核心表 + 初始数据）
[2/3] 执行 v0.1.6 增量脚本...
  ✅ v0.1.6 增量初始化完成（新增 2 张表 + 字段扩展）
[3/3] 验证数据库初始化...
  --- 数据库列表 ---
  cloudstroll_office_auth
  --- cloudstroll_office_auth 表列表 ---
  t_auth_tenant
  t_auth_user
  ...
  --- 租户表初始数据 ---
  ...（id, tenant_name, tenant_code, status）
  --- 用户表初始数据 ---
  ...（id, login_name, real_name, status）

==============================================
  数据库初始化完成！
==============================================
```
退出码：全部成功退出 0；SQL 文件缺失或执行失败退出 1（脚本带 `✅`/`❌` 标识，双平台保留 emoji 差异）。

---

## 9. build-backend.ps1 / build-backend.sh — 后端一键编译

### 9.1 功能
在项目根目录执行 Maven 多模块 `clean package`，构建 gateway/auth/biz/system 四个服务，最终可执行 jar 由各模块 `maven-antrun-plugin` 自动复制至 `deploy/`（唯一落点）。**中间产物（各模块 target/）不进入 deploy**。

前置条件：deploy 目录存在、`mvn` 命令可用（Maven 3.8+）。

### 9.2 用法

```powershell
.\deploy\scripts\build-backend.ps1            # 编译并跳过测试（默认）
.\deploy\scripts\build-backend.ps1 -RunTests  # 编译并执行测试
```
```bash
./deploy/scripts/build-backend.sh              # 跳过测试（默认）
./deploy/scripts/build-backend.sh --run-tests  # 执行测试
```

### 9.3 正常返回内容
```
==============================================
  云漫智企 - 后端一键编译
  项目根: D:\...\CloudStrollOffice
  命令:   mvn -f ...\pom.xml clean package -DskipTests
==============================================
...（Maven 构建输出，BUILD SUCCESS）...

==============================================
  后端编译完成，全部 jar 已输出至 deploy
    deploy\cloudoffice-gateway.jar
    deploy\cloudoffice-auth-service.jar
    deploy\cloudoffice-biz-service.jar
    deploy\cloudoffice-system-service.jar
==============================================
```
退出码：构建成功且 4 个 jar 齐全退出 0；deploy 目录缺失 / mvn 不可用 / 构建失败 / 产物缺失退出 1。

---

## 10. build-client.ps1 / build-client.sh — 客户端一键编译

### 10.1 功能
调用客户端工程内官方构建脚本（`cloudoffice-flutter-app/build-release.ps1` / `.sh`）构建 Flutter 客户端，最终产物落位 `deploy/cloudoffice-flutter-app/`（唯一落点）。**构建缓存（build/）与过程文件不进入 deploy**。

前置条件：deploy 目录存在、`flutter` 命令可用（Flutter 3.x）。

### 10.2 用法

```powershell
.\deploy\scripts\build-client.ps1                        # 构建 Windows + Web（默认）
.\deploy\scripts\build-client.ps1 -Platform web          # 仅构建 Web
.\deploy\scripts\build-client.ps1 -Platform windows      # 仅构建 Windows
```
```bash
./deploy/scripts/build-client.sh                          # 构建 Windows + Web
./deploy/scripts/build-client.sh web                      # 仅构建 Web
./deploy/scripts/build-client.sh windows                  # 仅构建 Windows
```
> PowerShell `-Platform` 取值：`all`（默认）/ `web` / `windows`；Windows 桌面构建需 Windows 环境。

### 10.3 正常返回内容
```
==============================================
  云漫智企 - 客户端一键编译
  平台:     all
  产物落点: ...\deploy\cloudoffice-flutter-app
==============================================
...（Flutter 构建输出）...

==============================================
  客户端编译完成，全部最终产物已输出至 deploy
    deploy\cloudoffice-flutter-app\
==============================================
```
退出码：构建成功且按平台校验产物齐全（windows 含 `cloudoffice_flutter_app.exe`、web 含 `index.html`）退出 0；前置检查或构建失败退出 1。

---

## 11. serve-web.ps1 / serve-web.sh — Web 客户端一键启动

### 11.1 功能
使用 Python 内置 `http.server` 将 `deploy/cloudoffice-flutter-app/web` 作为静态站点前台启动（供 Web 客户端调试/演示）：
- **前置校验**：`python`/`python3` 命令可用 + 站点目录存在（缺一即退出 1）；
- **端口来源**：`-Port`/第一个参数 > `env.json` 的 `WEB_SERVER_PORT` > 默认 8080；
- **前台运行**：`python -m http.server <port> --bind 127.0.0.1 --directory <web目录>`，Ctrl+C 停止；
- 端口默认 8080（避开 gateway 9000 / auth 9100 / biz 9200 / system 9400）。
- 前置条件：已执行 `build-client` 生成 Web 产物（`deploy/cloudoffice-flutter-app/web/index.html`）。

### 11.2 用法

```powershell
.\deploy\scripts\serve-web.ps1              # 端口取 WEB_SERVER_PORT，缺省回退 8080
.\deploy\scripts\serve-web.ps1 -Port 9090   # 显式指定端口
```
```bash
./deploy/scripts/serve-web.sh               # 端口取 WEB_SERVER_PORT，缺省回退 8080
./deploy/scripts/serve-web.sh 9090          # 显式指定端口
```

### 11.3 正常返回内容
```
==============================================
  云漫智企 (CloudStrollOffice) Web 客户端一键启动
  日期: 2026-08-11 12:00:00
==============================================

  [通过] 前置校验：python 命令可用 + 站点目录存在

  启动静态站点: http://127.0.0.1:8080/
  站点目录: ...\deploy\cloudoffice-flutter-app\web
  按 Ctrl+C 停止服务。

  Serving HTTP on 127.0.0.1 port 8080 (http://127.0.0.1:8080/) ...
```
退出码：前置校验通过且服务被 Ctrl+C 中断退出 0；前置校验失败退出 1。

---

## 12. 输出分级与退出码速查

| 脚本 | 正常退出码 | 失败退出码 | 备注 |
| --- | --- | --- | --- |
| load-env | 0 | 1 | source 型，缺失用 return/exit 返回非零 |
| deploy-check-env | 0（警告也 0） | 1 | 失败项 >0 退出 1 |
| deploy-start-services | 0（警告也 0） | 1 | 未安装计入失败 |
| deploy-start-all | 0 | 1 | 失败即停 |
| deploy-start-gateway/auth/biz/system | 0 | 1 | 失败即停 |
| deploy-rsa-keygen | 0 | 1 | 契约自校验失败退出 |
| deploy-db-init | 0 | 1 | SQL 缺失/失败退出 |
| build-backend | 0 | 1 | jar 落位校验 |
| build-client | 0 | 1 | 产物落位校验 |
| serve-web | 0（Ctrl+C 停止） | 1 | 前置校验失败退出 |

## 13. 参考

- 编译方案：deploy/build.md
- 部署方案：deploy/deploy.md
- 产品需求文档 v0.2.7：docs/cso-v0.2.7/cso-prd-v0.2.7.md（F-001 load-env / F-007 基础设施一键启动 / F-008 后端按序一键启动 / F-009 单服务启动 / F-011 脚本契约与输出规范 / F-012 .gitignore 治理）
- 脚本契约总体验证 v0.2.7：docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md（.ps1/.sh 双平台契约自校验结果）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->