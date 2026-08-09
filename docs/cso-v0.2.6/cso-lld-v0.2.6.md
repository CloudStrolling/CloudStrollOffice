# 详细设计文档（LLD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**编写人**：TL

> 说明：LLD 聚焦整体业务逻辑的详细设计（模块划分、业务流程、核心业务逻辑、业务规则等）；接口（API）的详细设计由 API 设计文档单独负责，LLD 中不重复编写接口定义、请求/响应参数等内容。本版本（v0.2.6）为部署与配置缺陷修复工程版本（需求来源：docs/cso-v0.2.5/regression-api-test.md 记录的回归测试问题），不涉及任何接口变更，无新增 API（API 契约 API-001~API-033 完整保留）。

## 1. 模块概述

本版本（v0.2.6）聚焦修复 v0.0.1 基线遗留的两项部署/配置缺陷（v0.2.5 回归报告审核项 T-02），目标为"4 个服务全部可启动 + API 测试闭环"（SAD ADR-014/ADR-015、PRD G-1~G-3）：

1. **bootstrap 配置引导依赖缺失**：全项目 pom 均未引入 `spring-cloud-starter-bootstrap`，Spring Boot 3.x 下 bootstrap.yml（含 Nacos discovery/config server-addr）默认不加载，auth/biz/system 启动报 `No spring.config.import property has been defined`，Nacos 配置引导链路断裂；
2. **RSA 密钥格式契约不匹配**：deploy/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 PEM 文件整体 Base64（多行、含 BEGIN/END 标记），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 严格解码契约（期望 DER 编码单行 Base64）不一致，网关启动报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。

本版本业务逻辑划分为四个工程级模块，遵循"最小修复、契约不变"（PRD 核心设计理念）原则，不新增任何业务功能，不触碰接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码：

| 模块 | 类型 | 核心职责 |
| --- | --- | --- |
| bootstrap 配置引导修复 | 构建/依赖配置（根 pom.xml + 4 个服务模块 pom） | 引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，打通 Nacos discovery/config 引导链路，消除 `No spring.config.import property has been defined` 启动报错（F-001） |
| RSA 密钥格式契约统一 | 脚本+配置（deploy/scripts/deploy-rsa-keygen.ps1、deploy/env.json） | 密钥生成脚本输出与 Java 端 RsaKeyConfig 解码逻辑保持同一格式契约（DER 编码单行 Base64，无 PEM 头尾、无换行），消除 `RSA 公钥解析失败`（F-002） |
| 服务启动与健康检查验证 | 部署链路（gateway/auth/biz/system + Nacos/MariaDB/Redis） | 重新构建 4 个服务 jar，按部署文档标准流程启动并注册到 Nacos，健康检查全部通过，启动日志无两项缺陷报错（F-003） |
| 接口回归验证闭环 | 测试资产（scripts/API-TEST/cso-api-test-v0.0.1.py、cso-api-test-v0.2.5.py） | 服务可用前提下补跑 v0.0.1 基线回归（TC-001~045，PASS=45、FAIL=0）并复核 v0.2.5 回归（TC-046~051，PASS=26、FAIL=0），输出 v0.2.6 回归报告，API 测试全部跑通（F-004/F-005） |

**模块间协作关系**：bootstrap 依赖修复 + RSA 密钥契约统一 → 重新构建并启动 4 个服务（Nacos 注册、MariaDB/Redis 依赖可用）→ 服务健康检查通过 → 执行接口回归脚本（TC-001~045 补跑 + TC-046~051 复核）→ 输出回归报告闭环。四个模块之间存在严格的先后依赖：前两个模块的修复成果是服务启动验证的前提，服务启动验证又是接口回归闭环的前提。

## 2. 模块划分与职责

### 2.1 模块依赖关系

```mermaid
flowchart LR
    POM["根 pom.xml + 4 个服务模块 pom<br/>引入 spring-cloud-starter-bootstrap"] -->|"F-001 构建通过"| BUILD["重新构建 4 个服务 jar<br/>gateway/auth/biz/system"]
    PS1["deploy/scripts/deploy-rsa-keygen.ps1<br/>输出 DER 单行 Base64"] -->|"F-002 生成密钥"| ENV["deploy/env.json<br/>RSA_PUBLIC_KEY / RSA_PRIVATE_KEY"]
    ENV -->|"环境变量注入"| START["服务启动链路<br/>bootstrap.yml 引导 + RsaKeyConfig 解析"]
    BUILD -->|"F-003 部署启动"| START
    START -->|"健康检查通过"| T001["cso-api-test-v0.0.1.py<br/>TC-001~045 动态回归"]
    START -->|"契约不变"| T046["cso-api-test-v0.2.5.py<br/>TC-046~051 复核"]
    T001 -->|"F-004 PASS=45"| RPT["v0.2.6 回归报告<br/>regression-api-test.md"]
    T046 -->|"F-005 PASS=26"| RPT
    RPT -->|"API 测试全部跑通"| DONE["验收完成"]
```

### 2.2 各模块内部职责

| 模块 | 内部构成 | 职责说明 |
| --- | --- | --- |
| bootstrap 配置引导修复 | 根 pom.xml（dependencyManagement 统一管理）、四个服务模块 pom（gateway/auth/biz/system） | 各服务模块实际引入 `spring-cloud-starter-bootstrap`（仅根 pom 声明 dependencyManagement 而不在模块引入仍会报 import-check 错误）；引入后 bootstrap.yml 恢复生效，`spring.cloud.nacos.discovery.server-addr` 与 `spring.cloud.nacos.config.server-addr` 可被加载；不得改变既有接口契约与业务代码逻辑 |
| RSA 密钥格式契约统一 | deploy/scripts/deploy-rsa-keygen.ps1（密钥生成脚本）、deploy/env.json（密钥注入载体）、RsaKeyConfig（gateway/auth 密钥解析） | 脚本输出与环境注入的密钥值必须与 Java 端解码契约严格一致：DER 编码单行 Base64（无 PEM 头尾、无换行），`Base64.getDecoder()` 可直接解码、`X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）可构造 KeySpec；私钥不得入库、不得写入日志 |
| 服务启动与健康检查验证 | 4 个服务 jar、Nacos（注册中心）、MariaDB、Redis、部署脚本（deploy/scripts/deploy-start-*.ps1/.sh） | 按部署文档标准流程启动：env.json 环境变量 + Nacos 注册 + MariaDB/Redis 依赖；启动日志不得再出现 `No spring.config.import property has been defined` 与 `RSA 公钥解析失败`；各服务健康检查返回正常状态；Nacos 控制台可见 4 个服务实例 |
| 接口回归验证闭环 | scripts/API-TEST/cso-api-test-v0.0.1.py（TC-001~045）、cso-api-test-v0.2.5.py（TC-046~051）、docs/cso-v0.2.6/regression-api-test.md（回归报告） | v0.0.1 基线脚本补跑：网关（9000）与认证服务（9100）可访问，admin/admin123 可用，TC-001~045 全部动态执行通过（PASS=45、FAIL=0），消除"待执行/环境阻塞"历史状态；v0.2.5 脚本复核保持 PASS=26、FAIL=0；回归结果记录到 v0.2.6 回归报告 |

### 2.3 修复范围与红线（不得触碰）

| 资产类别 | 范围约束 | 说明 |
| --- | --- | --- |
| 接口层 | 禁止改动 | Controller/DTO/响应体（ApiResult/PageResult）零改动，API-001~API-033 契约完整保留（PRD F-005） |
| 客户端运行时代码 | 禁止改动 | cloudoffice-flutter-app lib/ 代码零改动，客户端构建产物保持原状 |
| 业务代码逻辑 | 禁止改动 | auth-service 认证/Token/会话/验证码/RBAC 等业务逻辑不变 |
| 数据库结构 | 禁止改动 | 不新增数据表、不修改表结构（PRD 数据需求：9 张表结构不变） |
| 允许改动 | 仅限 | 构建/依赖配置（pom）、密钥生成脚本（deploy-rsa-keygen.ps1）、环境配置（deploy/env.json）、部署/回归验证流程与测试资产 |

## 3. 类图

本版本无新增业务运行时代码，核心"对象"为构建依赖配置、密钥契约与启动验证逻辑。以下用 Mermaid classDiagram 描述相关逻辑对象及其关系（RsaKeyConfig 为既有类，此处描述其与本版本契约的关系）：

```mermaid
classDiagram
    class RootPom {
        +springCloudAlibabaVersion: 2023.0.1.0
        +dependencyManagement: spring-cloud-starter-bootstrap 统一声明
        +modulePoms: common/gateway/auth/biz/system
    }
    class ModulePom {
        +artifactId: cloudoffice-{gateway|auth-service|biz-service|system-service}
        +dependencies: spring-cloud-starter-bootstrap（实际引入）
        +bootstrapLoad(): bootstrap.yml 在 Spring Boot 3.x 下生效
    }
    class BootstrapYml {
        +spring.cloud.nacos.discovery.server-addr
        +spring.cloud.nacos.config.server-addr
        +spring.application.name
        +loadOrder: 先于 application.yml 加载
    }
    class RsaKeygenScript {
        +outputFormat: DER 编码单行 Base64（无 PEM 头尾、无换行）
        +publicKey: RSA_PUBLIC_KEY
        +privateKey: RSA_PRIVATE_KEY
        +writeToEnvJson(): 注入 deploy/env.json
    }
    class EnvJson {
        +RSA_PUBLIC_KEY: DER 单行 Base64
        +RSA_PRIVATE_KEY: DER 单行 Base64
        +DB/REDIS/NACOS 连接参数: 保持不变
    }
    class RsaKeyConfig {
        +publicKey: 由 RSA_PUBLIC_KEY 解码
        +privateKey: 由 RSA_PRIVATE_KEY 解码
        +decodePublicKey(): Base64.getDecoder() + X509EncodedKeySpec
        +decodePrivateKey(): Base64.getDecoder() + PKCS8EncodedKeySpec
    }
    class JwtUtils {
        +sign(): RSA 私钥签名（RS256）
        +verify(): RSA 公钥验签
    }
    class HealthCheck {
        +serviceName
        +status: 正常
        +version
        +timestamp
    }
    class ApiTestScript {
        +baselineScript: cso-api-test-v0.0.1.py（TC-001~045）
        +v025Script: cso-api-test-v0.2.5.py（TC-046~051）
        +run(): 动态执行全部用例
        +report(): 结果写入 regression-api-test.md
    }

    RootPom --> ModulePom : dependencyManagement 声明
    ModulePom --> BootstrapYml : 依赖引入后加载
    RsaKeygenScript --> EnvJson : 生成并注入（契约一致）
    EnvJson --> RsaKeyConfig : 环境变量注入
    RsaKeyConfig --> JwtUtils : 提供密钥
    BootstrapYml --> HealthCheck : 服务启动后暴露
    HealthCheck --> ApiTestScript : 前置条件
    ApiTestScript --> RsaKeyConfig : 登录/验签链路验证
```

## 4. 核心业务流程时序图

### 4.1 修复后服务启动流程（F-001/F-003）

```mermaid
sequenceDiagram
    autonumber
    actor OP as 运维/部署人员
    participant MVN as Maven 构建
    participant BOOT as spring-cloud-starter-bootstrap 引导
    participant YML as bootstrap.yml（Nacos server-addr）
    participant NACOS as Nacos 2.3
    participant SVC as 服务实例（gateway/auth/biz/system）
    participant MDB as MariaDB/Redis

    OP->>MVN: 引入 spring-cloud-starter-bootstrap 后 mvn package
    MVN-->>OP: 4 个服务 jar 构建成功（deploy/ 目录）
    OP->>SVC: 按部署脚本启动（env.json 环境变量注入）
    SVC->>BOOT: 启动上下文初始化
    BOOT->>YML: 加载 bootstrap.yml（先于 application.yml）
    YML->>NACOS: 读取 Nacos config server-addr + discovery server-addr
    SVC->>NACOS: 注册服务实例（服务名/ip/端口）
    SVC->>MDB: 依赖可用性校验（auth 连库/全部连 Redis）
    SVC->>SVC: 启动完成，无 import-check / RSA 解析报错
    OP->>SVC: 访问健康检查端点（经网关或直连）
    SVC-->>OP: 服务名/状态正常/版本/时间戳
    NACOS-->>OP: 控制台可见 4 个服务实例
```

### 4.2 RSA 密钥生成/注入/解析流程（F-002）

```mermaid
sequenceDiagram
    autonumber
    actor OP as 运维/部署人员
    participant PS1 as deploy-rsa-keygen.ps1
    participant FILE as 密钥输出（DER 单行 Base64）
    participant ENV as deploy/env.json
    participant CFG as RsaKeyConfig（gateway/auth）
    participant JWT as JwtUtils/JWT RS256 链路

    OP->>PS1: 执行密钥生成脚本
    PS1->>FILE: 生成 RSA 2048 密钥对
    FILE->>FILE: 公钥 DER → Base64 单行（无 BEGIN/END、无换行）
    FILE->>FILE: 私钥 PKCS8 DER → Base64 单行
    PS1->>ENV: 写入 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY
    OP->>ENV: 确认 env.json 密钥为单行 Base64 契约
    ENV->>CFG: 环境变量注入
    CFG->>CFG: Base64.getDecoder() 解码 → X509/PKCS8EncodedKeySpec 构造
    CFG->>JWT: 提供公钥（验签）/私钥（auth 签名）
    JWT->>JWT: 登录签发 RS256 签名 / 网关验签通过
    JWT-->>OP: 网关启动无 "RSA 公钥解析失败"，签名验签链路正常
```

### 4.3 v0.0.1 基线接口回归闭环流程（F-004）

```mermaid
sequenceDiagram
    autonumber
    actor TE as 测试工程师
    participant GW as 网关（9000）
    participant AS as 认证服务（9100）
    participant SCRIPT as cso-api-test-v0.0.1.py
    participant MDB as MariaDB
    participant RD as Redis

    TE->>GW: 确认 4 服务健康检查通过、Nacos 已注册
    TE->>SCRIPT: 执行 python cso-api-test-v0.0.1.py http://localhost:9000
    SCRIPT->>GW: admin 登录（白名单放行）
    GW->>AS: 转发登录（RS256 签名链路验证）
    AS->>MDB: 查询租户/用户/角色权限
    AS->>RD: 会话/状态缓存
    AS-->>SCRIPT: 返回双 Token
    SCRIPT->>SCRIPT: TC-001~045 依次执行（登录/刷新/登出/用户/角色/权限/网关鉴权/健康检查）
    SCRIPT-->>TE: 退出码 0，PASS=45、FAIL=0
    TE->>TE: 汇总结果写入 v0.2.6 回归报告，闭环历史"环境阻塞"状态
```

### 4.4 既有契约无回归复核流程（F-005）

```mermaid
sequenceDiagram
    autonumber
    participant TE as 测试工程师
    participant GIT as git 变更清单
    participant DOC as API 设计文档（v0.2.6 无变更）
    participant SCRIPT as cso-api-test-v0.2.5.py

    TE->>GIT: 核对变更清单：无 Controller/DTO/响应体改动
    TE->>GIT: 核对变更清单：无客户端 lib/ 运行时代码改动
    TE->>DOC: 静态核对：API-001~API-033 完整保留、无新增/变更/删除
    TE->>SCRIPT: 执行 python cso-api-test-v0.2.5.py <项目根>
    SCRIPT-->>TE: TC-046~051 保持 PASS=26、FAIL=0
    TE->>TE: 双重确认（静态 + 动态）无回归，记录回归报告
```

## 5. 状态图

### 5.1 服务启动状态流转（本版本修复目标）

```mermaid
stateDiagram-v2
    [*] --> 构建失败 : mvn package 异常（依赖引入错误）
    构建失败 --> 构建成功 : 修正 pom 依赖后重新构建
    [*] --> 构建成功 : 引入 bootstrap 依赖后构建通过
    构建成功 --> 启动失败 : Nacos 不可达 / 密钥解析失败 / 依赖缺失
    启动失败 --> 启动成功 : 按启动日志定位修复（bootstrap/RSA/基础设施）
    启动失败 --> 启动失败 : 未修复缺陷重复启动（历史状态，v0.2.5 回归暴露）
    启动成功 --> 已注册 : 服务注册到 Nacos
    已注册 --> 健康通过 : /api/v1/{auth|biz|system}/health 返回正常
    健康通过 --> [*] : 回归前置条件就绪
    健康通过 --> 回归闭环 : TC-001~051 全部动态执行通过
    回归闭环 --> [*] : v0.2.6 验收完成
```

### 5.2 RSA 密钥格式契约状态流转

```mermaid
stateDiagram-v2
    [*] --> PEM整体Base64 : v0.0.1 历史 env.json（多行、含 BEGIN/END，v0.2.5 回归暴露）
    PEM整体Base64 --> 契约不一致 : 与 Java 严格解码契约不匹配
    契约不一致 --> 启动崩溃 : 网关报 RSA 公钥解析失败（Unable to decode key）
    启动崩溃 --> DER单行Base64 : v0.2.6 修复：deploy-rsa-keygen.ps1 重生成/重注入
    DER单行Base64 --> 契约一致 : Base64.getDecoder() 可直接解码
    契约一致 --> 解析成功 : X509/PKCS8EncodedKeySpec 构造密钥
    解析成功 --> 验签正常 : 登录签发（私钥）/网关验签（公钥）链路工作
    验签正常 --> [*] : 缺陷闭环
    解析成功 --> 配对失败 : 公钥私钥不配对（重新成对生成）
    配对失败 --> DER单行Base64 : 重新执行密钥生成脚本
```

### 5.3 回归用例状态流转（TC-001~045）

```mermaid
stateDiagram-v2
    [*] --> 待执行 : v0.0.1 阶段汇总（从未动态闭环）
    待执行 --> 环境阻塞 : 服务无法启动（v0.2.5 回归记录）
    环境阻塞 --> 动态执行 : v0.2.6 服务修复可用后补跑
    动态执行 --> 通过 : 断言全部满足（PASS）
    动态执行 --> 失败 : 断言不满足（FAIL，测试数据冲突等）
    失败 --> 动态执行 : 清理测试数据后重跑
    通过 --> [*] : TC-001~045 全部通过，回归闭环
```

## 6. 核心业务逻辑

### 6.1 bootstrap 配置引导依赖引入（F-001）

```
功能：恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路
目标：消除 auth/biz/system 启动报错 "No spring.config.import property has been defined"

方案选择（须保证最终效果一致）：
方案 A（推荐，本版本采用）：
1. 根 pom dependencyManagement 声明 spring-cloud-starter-bootstrap（版本随 Spring Cloud 2023.0.1 管理）
2. 四个服务模块（gateway/auth/biz/system）pom 实际引入该依赖
   —— 注意：仅根 pom 声明 dependencyManagement 而未在模块引入，启动仍报 import-check 错误
方案 B（备选）：
1. 各服务 bootstrap.yml/application.yml 配置 spring.config.import=optional:nacos:${...}
2. 同时关闭 nacos-config 的 import-check 强校验
   —— 注意：只配置 import 而不关闭校验仍会报错

执行检查（验收）：
- 构建通过：mvn package 无依赖解析错误
- 启动日志：不再出现 "No spring.config.import property has been defined"
- bootstrap.yml 生效：spring.cloud.nacos.discovery.server-addr / spring.cloud.nacos.config.server-addr 被加载
- 服务注册：Nacos 控制台可见 4 个服务实例
```

### 6.2 RSA 密钥生成与注入（F-002）

```
功能：deploy-rsa-keygen.ps1 输出与 Java 端解码契约一致的 DER 单行 Base64 密钥
契约定义（SAD 安全约束，ADR-015）：
- RSA_PUBLIC_KEY  = Base64(DER 编码公钥 X.509 SubjectPublicKeyInfo)，单行
- RSA_PRIVATE_KEY = Base64(PKCS8 编码私钥 PrivateKeyInfo)，单行
- 无 "-----BEGIN/END PUBLIC KEY-----" 等 PEM 头尾标记
- 无 \r\n / \n 换行符

生成流程：
1. 生成 RSA 2048 密钥对
2. 公钥：DER 编码（X.509）→ Base64 编码（单行）→ RSA_PUBLIC_KEY
3. 私钥：PKCS8 编码（PKCS#8）→ Base64 编码（单行）→ RSA_PRIVATE_KEY
4. 写入 deploy/env.json（覆盖旧 PEM 整体 Base64 值）
5. 输出提示：密钥契约说明（单行、无头尾），供运维确认

校验（注入前）：
- 值不含 "-----BEGIN" / "-----END" 子串
- 值不含换行符（单行）
- 可被 Base64.getDecoder() 严格解码（无 extra data）
```

### 6.3 RsaKeyConfig 密钥解析（F-002，既有代码逻辑）

```
功能：gateway/auth 启动时从环境变量加载 RSA 密钥（本版本不改代码，契约由脚本侧对齐）

逻辑（既有，保持不动）：
1. 读环境变量 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY（或 @Value 注入）
2. decodePublicKey：Base64.getDecoder().decode(RSA_PUBLIC_KEY) → X509EncodedKeySpec → KeyFactory RSA 生成公钥
3. decodePrivateKey：Base64.getDecoder().decode(RSA_PRIVATE_KEY) → PKCS8EncodedKeySpec → KeyFactory RSA 生成私钥
4. 解析失败 → 抛启动异常，服务终止（防止无密钥运行）

本版本契约：env.json 注入值 = 脚本输出值 = 严格 DER 单行 Base64，两端一致，运行时代码零改动。
```

### 6.4 服务启动与健康检查验证（F-003）

```
功能：验证 4 个服务修复后全部可启动、可注册、可探活
执行流程：
1. 构建：mvn package（根目录），确认 deploy/ 下 4 个最终 jar 更新
2. 启动：按部署脚本（deploy/scripts/deploy-start-*.ps1/.sh）逐个启动，env.json 环境变量注入
3. 检查启动日志：
   - 无 "No spring.config.import property has been defined"
   - 无 "RSA 公钥解析失败"
   - 无其他致命错误（Nacos 连接、端口占用等）
4. 注册检查：Nacos 控制台可见 gateway/auth/biz/system 4 个实例（服务名 cloudoffice-*）
5. 健康检查：访问 /api/v1/{auth|biz|system}/health，状态为正常
6. 任一环节失败 → 按日志定位：bootstrap 依赖 / RSA 密钥 / 基础设施，修复后重新构建启动

失败排查顺序（PRD 流程图 G/J 分支）：
① 依赖问题（import-check）→ 6.1 方案检查
② 密钥问题（RSA 解析失败）→ 6.2 重新生成注入
③ 基础设施（Nacos/MariaDB/Redis 不可达）→ 先保障基础设施可用
```

### 6.5 接口回归闭环执行（F-004/F-005）

```
功能：服务可用后完成 v0.0.1 基线动态回归与既有契约复核
执行流程：
1. 前置确认：网关（9000）、auth-service（9100）可访问；MariaDB/Redis/Nacos 正常；admin/admin123 可用
2. 基线回归：python cso-api-test-v0.0.1.py http://localhost:9000
   - TC-001~045 全部动态执行，断言全部通过
   - 期望结果：退出码 0，PASS=45、FAIL=0
3. 契约复核：python cso-api-test-v0.2.5.py <项目根>
   - TC-046~051 保持通过，期望 PASS=26、FAIL=0（TC-046-3 健康检查为可选场景，SKIP 不视为失败）
4. 结果汇总：写入 docs/cso-v0.2.6/regression-api-test.md
   - 记录 TC-001~051 执行明细、通过/失败统计、根因闭环说明、签名确认
5. 失败处理：个别用例因测试数据冲突失败 → 记录并清理测试数据后重跑，直至全部通过
```

## 7. 业务规则与约束

| 类别 | 规则 | 来源/落点 |
| --- | --- | --- |
| 依赖引入 | 四个服务模块（gateway/auth/biz/system）必须实际引入 `spring-cloud-starter-bootstrap`；仅根 pom dependencyManagement 声明不生效，启动仍报 import-check | SAD 设计约束/ADR-014、PRD F-001、US-001 |
| 配置引导 | 引入后 bootstrap.yml 必须生效：Nacos discovery/config server-addr 可加载；服务启动日志不得出现 `No spring.config.import property has been defined` | PRD F-001/F-003、US-001 |
| 密钥格式契约 | `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64（无 PEM 头尾、无换行）；与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致 | SAD 安全约束/ADR-015、PRD F-002、US-002 |
| 密钥配对 | 公钥与私钥必须成对生成，公钥验签/私钥签名配对一致；密钥损坏/截断导致解析失败时服务启动失败，须重新生成注入 | PRD US-002 边界 |
| 密钥安全 | 私钥不得入库、不得写入日志；密钥仍通过环境变量/配置文件注入，禁止硬编码 | SAD 安全约束、PRD F-002 |
| 修复范围 | 仅允许构建/依赖配置、密钥生成脚本、环境配置、部署/回归验证流程变更；禁止改动接口层（Controller/DTO/响应体）、客户端 lib/ 运行时代码、数据库表结构、业务代码逻辑 | PRD F-005、验收标准 6 |
| 数据约束 | 本版本不新增数据表、不修改表结构；MariaDB 9 张表与 Redis 缓存数据结构不变 | PRD 数据需求 |
| 启动验证 | 4 个服务全部启动成功并注册到 Nacos；健康检查全部返回正常；启动日志无两项缺陷报错 | PRD F-003、验收标准 3 |
| 回归闭环 | TC-001~045 全部动态执行通过（PASS=45、FAIL=0），消除历史"待执行/环境阻塞"状态；TC-046~051 保持 PASS=26、FAIL=0 | PRD F-004/F-005、US-003/US-004 |
| 结果记录 | 回归结果必须记录到 v0.2.6 接口回归报告（docs/cso-v0.2.6/regression-api-test.md） | PRD F-004、验收标准 7 |
| 架构约束 | 修复不改变模块依赖关系（服务间仍只依赖 common），不改变服务注册与路由（/api/v1/{module}/**） | ADR-001、API v0.2.6 |

## 8. 业务数据流

### 8.1 RSA 密钥数据流（本版本修复链路）

```
deploy-rsa-keygen.ps1（生成）
  → RSA 2048 密钥对（DER 编码：公钥 X.509 / 私钥 PKCS8）
  → Base64 单行编码（无 PEM 头尾、无换行）
  → deploy/env.json：RSA_PUBLIC_KEY / RSA_PRIVATE_KEY（覆盖旧 PEM 整体 Base64）
  → 环境变量注入 gateway + auth-service
  → RsaKeyConfig：Base64.getDecoder() 解码 → X509/PKCS8EncodedKeySpec → RSA KeyFactory
  → gateway（公钥验签）/ auth-service（私钥签名 + 公钥验签）
  → JWT RS256 双 Token 签发与网关验签链路正常
```

### 8.2 配置引导数据流（F-001 修复后）

```
服务启动（gateway/auth/biz/system）
  → spring-cloud-starter-bootstrap（依赖引入后生效）
  → bootstrap.yml 先于 application.yml 加载
  → spring.cloud.nacos.discovery.server-addr / spring.cloud.nacos.config.server-addr 生效
  → Nacos 注册中心注册实例（服务名 cloudoffice-{module}）
  → 服务实例可被发现、被网关 lb 路由
```

### 8.3 回归验证数据流

```
服务可用（4 服务健康通过 + Nacos 注册）
  → cso-api-test-v0.0.1.py http://localhost:9000
  → 网关（9000）→ 认证服务（9100）→ MariaDB（租户/用户/角色权限）/ Redis（会话/状态/验证码）
  → TC-001~045 断言结果（PASS=45、FAIL=0）
  → cso-api-test-v0.2.5.py <项目根> → TC-046~051（PASS=26、FAIL=0）
  → docs/cso-v0.2.6/regression-api-test.md（回归报告闭环）
```

## 9. 数据结构定义

### 9.1 RSA 密钥格式契约（env.json 注入值）

| 字段 | 格式要求 | 说明 |
| --- | --- | --- |
| RSA_PUBLIC_KEY | DER 编码单行 Base64 | X.509 SubjectPublicKeyInfo 经 Base64 编码；无 `-----BEGIN PUBLIC KEY-----` 头尾、无换行；Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec` 可解码 |
| RSA_PRIVATE_KEY | DER 编码单行 Base64 | PKCS#8 PrivateKeyInfo 经 Base64 编码；无 `-----BEGIN PRIVATE KEY-----` 头尾、无换行；Java 端 `Base64.getDecoder()` + `PKCS8EncodedKeySpec` 可解码 |

> 反例（v0.0.1 历史缺陷，本版本消除）：PEM 文件整体 Base64（多行、含 BEGIN/END 标记与 \r\n），`Base64.getDecoder()` 严格解码报 `extra data at the end`。

### 9.2 bootstrap 引导配置（bootstrap.yml，既有资产）

| 配置项 | 说明 |
| --- | --- |
| spring.application.name | 服务名（cloudoffice-gateway/auth-service/biz-service/system-service），Nacos 注册名 |
| spring.cloud.nacos.discovery.server-addr | Nacos 注册中心地址 |
| spring.cloud.nacos.config.server-addr | Nacos 配置中心地址 |

### 9.3 环境配置结构（deploy/env.json，本版本仅密钥值变更）

| 字段 | 变更情况 | 说明 |
| --- | --- | --- |
| RSA_PUBLIC_KEY | 变更（PEM 整体 Base64 → DER 单行 Base64） | 与 Java 解码契约一致 |
| RSA_PRIVATE_KEY | 变更（PEM 整体 Base64 → DER 单行 Base64） | 与 Java 解码契约一致 |
| 数据库连接参数 | 不变 | MariaDB host/port/user/password 等 |
| Redis 连接参数 | 不变 | Redis host/port/password 等 |
| Nacos 连接参数 | 不变 | Nacos server-addr 等 |

### 9.4 回归验证数据结构（回归报告）

| 结构 | 关键字段 | 用途 |
| --- | --- | --- |
| 脚本执行记录 | 脚本名、执行命令、用例数、通过、失败、跳过、结果 | 回归报告脚本清单 |
| 用例明细 | 用例编号（TC-001~051）、断言项、结果 | 逐用例回归记录 |
| 根因闭环说明 | 缺陷项、根因、修复内容、验证结果 | 记录 T-02 两项缺陷闭环 |

## 10. 异常处理策略

| 异常类别 | 典型场景 | 处理方式 |
| --- | --- | --- |
| import-check 启动失败 | 模块未实际引入 bootstrap 依赖，启动报 `No spring.config.import property has been defined` | 检查 6.1 方案 A 模块 pom 实际引入；采用方案 B 时检查 import-check 是否关闭（PRD US-001 边界） |
| RSA 密钥解析失败 | 密钥仍为 PEM 整体 Base64、多行含换行、损坏/截断 | 按 6.2 重新执行 deploy-rsa-keygen.ps1 生成 DER 单行 Base64 并注入 env.json；确认无 BEGIN/END 与换行（US-002 边界） |
| 公钥私钥不配对 | 误混用非成对密钥，登录签发后网关验签失败（401） | 成对重新生成并注入，重启服务 |
| Nacos 不可达 | 服务启动报连接 Nacos 异常 | 先保障基础设施可用（Nacos 8848 已启动且网络可达）后重试（US-001 边界） |
| 基础设施依赖异常 | MariaDB/Redis 不可达导致服务启动失败 | 检查 MariaDB 3306、Redis 6379 状态，恢复后重启服务 |
| 构建失败 | 依赖引入错误导致 mvn package 失败 | 修正 pom 后重新构建；deploy 不落盘失败产物 |
| 回归脚本连接拒绝 | 服务未启动时执行 cso-api-test-v0.0.1.py 崩溃（退出码 1） | 回到 6.4 服务启动验证，确认网关/认证服务可访问后再执行（US-003 边界） |
| 回归用例数据冲突 | 个别用例因测试数据残留失败 | 记录失败用例，清理测试数据（用户/验证码缓存等）后重跑，直至全部通过（US-003 边界） |
| 既有契约意外回归 | 修复过程意外改动接口层/客户端代码 | 回退改动，重新构建验证，回归报告中说明（US-004 边界） |

## 11. 日志规范

| 业务路径 | 日志级别 | 日志内容要求 |
| --- | --- | --- |
| Maven 构建 | info | 依赖解析、模块编译打包结果；引入 bootstrap 依赖后构建成功标志 |
| 服务启动（bootstrap 引导） | info / error | bootstrap.yml 加载路径、Nacos server-addr；import-check 报错需完整记录（定位修复依据） |
| RSA 密钥加载 | info / error | 密钥加载结果（成功/失败）；失败原因（解码异常、格式问题）；**禁止输出密钥内容**（红线） |
| 服务注册 | info | 服务名、实例 ip/端口、注册成功标志 |
| 健康检查 | info | 服务名、状态、版本、时间戳 |
| 回归脚本执行 | info / error | 脚本名、执行命令、用例通过/失败统计；失败用例编号与断言详情 |
| 回归报告 | info | 结果汇总写入路径、闭环说明（T-02 两项缺陷修复记录） |

**红线**：日志禁止输出 RSA 私钥、Token 原文、密码等敏感信息（NFR-004）；密钥内容不得以任何形式（debug 级亦不可）写入日志。

## 12. 性能优化点

| 风险点 | 手段 |
| --- | --- |
| bootstrap 引导对启动时长的影响 | 仅引入依赖恢复既有 bootstrap.yml 加载机制，不新增配置扫描与额外 IO，启动时长与 v0.0.1 设计一致 |
| 密钥解析开销 | RsaKeyConfig 启动时一次性解析密钥并缓存为 Bean，运行期零重复解析；本版本不改代码，契约对齐后无额外开销 |
| 密钥重新生成频率 | 仅部署/密钥轮换时执行 deploy-rsa-keygen.ps1，脚本输出契约固定，无重复手工处理成本 |
| 回归脚本全量执行 | TC-001~045 动态回归为一次全量执行（版本级验证），脚本按顺序执行不引入额外并发负载；失败重跑仅针对失败用例清理后复跑 |
| 服务重启成本 | 修复完成后一次性重启 4 个服务完成验证，后续正常迭代不重复执行本版本修复流程 |

## 13. 单元测试策略

### 13.1 测试范围与工具

本版本为部署/配置缺陷修复版本，测试以**启动验证、契约校验与接口回归**为主：

- 构建验证：`mvn package` 构建通过，deploy/ 下 4 个服务 jar 更新落位；
- 密钥契约校验：deploy-rsa-keygen.ps1 输出值满足 DER 单行 Base64 契约（无 BEGIN/END、无换行、可严格 Base64 解码）；
- 启动验证：4 个服务按部署文档启动成功，启动日志无 import-check 与 RSA 解析报错，Nacos 注册可见；
- 健康检查：`/api/v1/{auth|biz|system}/health` 返回正常状态；
- 接口回归：cso-api-test-v0.0.1.py（TC-001~045）PASS=45、FAIL=0；cso-api-test-v0.2.5.py（TC-046~051）PASS=26、FAIL=0。

### 13.2 用例划分

| 被测对象 | 用例方向 | 验收关联 |
| --- | --- | --- |
| 根 pom / 模块 pom | 4 个服务模块实际引入 spring-cloud-starter-bootstrap；依赖解析无冲突 | 验收标准 1 / US-001 |
| bootstrap.yml 引导 | 启动日志无 `No spring.config.import property has been defined`；Nacos server-addr 加载 | 验收标准 1、3 / US-001 |
| deploy-rsa-keygen.ps1 输出 | 输出为 DER 单行 Base64：无 `-----BEGIN/END` 子串、无换行符、可被严格 Base64 解码 | 验收标准 2 / US-002 |
| RsaKeyConfig 解析 | 注入 DER 单行 Base64 后 gateway/auth 启动无 `RSA 公钥解析失败`；RS256 签名验签链路正常 | 验收标准 2、3 / US-002 |
| 服务启动 | 4 个服务全部启动成功、注册到 Nacos、健康检查正常 | 验收标准 3 / US-001 |
| 基线接口回归 | cso-api-test-v0.0.1.py 执行退出码 0，TC-001~045 全部 PASS | 验收标准 4 / US-003 |
| 既有契约复核 | cso-api-test-v0.2.5.py 执行 TC-046~051 保持 PASS=26、FAIL=0；git 变更清单无接口层与客户端运行时代码改动 | 验收标准 5、6 / US-004 |
| 回归报告 | docs/cso-v0.2.6/regression-api-test.md 输出，记录 TC-001~051 动态执行结果 | 验收标准 7 |

### 13.3 边界与异常用例

- 密钥含 `-----BEGIN` 头尾 → 契约校验失败，重新生成单行格式（US-002 边界）；
- 密钥多行/含 \r\n → 严格解码失败（extra data at the end），重生成后通过；
- 公钥私钥不配对 → 登录签发后网关验签 401，成对重生成；
- 模块未实际引入依赖（仅根 pom 声明）→ 启动仍报 import-check，按 6.1 修正；
- 回归环境数据残留（用户/验证码缓存）→ 清理后重跑直至全部通过（US-003 边界）；
- TC-046-3 健康检查（可选场景）→ 服务未启动时按脚本约定 SKIP，不视为失败（US-004 边界）；
- 修复过程意外改动接口层/客户端代码 → 回退，回归报告中说明（US-004 边界）。

### 13.4 覆盖目标

- 全部 7 条验收标准（PRD 第 7 章）均有对应校验用例；
- 两项缺陷（T-02：bootstrap 依赖缺失、RSA 密钥格式契约不匹配）闭环验证全覆盖；
- 回归结果记录至 v0.2.6 版本测试用例文档与接口回归报告，全部通过方可交付。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
