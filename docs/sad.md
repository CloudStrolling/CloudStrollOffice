# 系统架构设计文档（SAD）
**项目名称**：云漫智企（CloudStrollOffice，英文缩写 cso）
**版本号**：v0.0.1（初始化归档版本，对应实际业务版本 v0.1.6）
**日期**：2026-08-05
**编写人**：SA

## 1. 设计目标与约束

### 1.1 设计目标

- **微服务拆分与职责隔离**：按业务域拆分为认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）三个业务服务 + API 网关（gateway） + 公共模块（common），认证与业务解耦，服务独立开发、测试、部署与伸缩，为后续企业信息、人事、工作流、薪酬等模块演进预留独立扩展空间。
- **统一认证与安全纵深防御**：以"网关统一认证 + 认证服务统一签发"为核心，实现多端（PC/H5/Android/iOS/微信小程序等 6 种客户端类型）一次登录、全端通行；通过 JWT RS256 双 Token、Redis 黑名单/登录态/状态四重校验、BCrypt 密码散列、登录日志审计等机制保障账号与会话安全。
- **多租户 RBAC 权限模型**：建立用户-角色-权限三层关联 + 租户隔离的数据模型，用户名在租户内唯一、租户间数据不可见，支撑多企业共用一套系统的 SaaS 化运营。
- **可扩展的认证能力**：登录（4 种模式）与注册（5 种模式）采用策略接口 + 工厂编排模式，新增登录/注册模式只需新增策略实现，不修改主流程代码。
- **统一规范与可观测性**：所有 REST 接口统一返回 `ApiResult<T>`、分页返回 `PageResult<T>`；29 个错误码全覆盖、全局异常统一封装；三个业务服务均提供健康检查端点，支撑基础运维监控。

### 1.2 设计约束

- **技术约束**：基于 Java 21 LTS + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈，服务间通过 Nacos 服务发现通信；关系型数据使用 MariaDB 10.6 (LTS)，缓存使用 Redis 7.2.x；客户端使用 Flutter（Dart 3）跨端实现。
- **资源约束**：本版本部署以 Docker Compose 单机编排为主（8 个容器），生产环境通过负载均衡器接入网关集群；RSA 密钥对、数据库密码等敏感信息仅通过环境变量注入，密钥文件不入库。
- **时间约束**：本版本为存量项目初始化归档（v0.0.1，对应业务版本 v0.1.6），需将现有代码能力完整反推固化为架构基线；biz-service 与 system-service 当前为骨架，仅提供健康检查，业务能力在后续版本填充。
- **合规与安全约束**：遵循 Apache License 2.0；密码禁止明文存储与日志输出；Token、验证码等敏感信息禁止日志输出；异常兜底不泄露堆栈与内部信息；登录/踢人/改密等安全事件必须留痕。

## 2. 技术栈选型及理由

| 技术方向 | 选型 | 理由 |
| --- | --- | --- |
| 编程语言 | Java 21 (OpenJDK LTS) | 长期支持版本，虚拟线程、模式匹配等新特性提升并发与代码表达力，与 Spring Boot 3.2.x 兼容 |
| 后端框架 | Spring Boot 3.2.5 | 快速构建微服务，自动装配与生态完善，内嵌 Tomcat，版本与 Java 21 对齐 |
| 微服务框架 | Spring Cloud 2023.0.1 | 微服务治理标准框架，提供网关、负载均衡、配置管理等基础设施能力 |
| 服务注册/配置中心 | Spring Cloud Alibaba Nacos 2023.0.1.0 / 2.3.0 | 服务发现 + 动态配置一体化，中文社区活跃，运维成本低 |
| API 网关 | Spring Cloud Gateway | 基于 WebFlux 的响应式网关，性能高，支持全局过滤器实现统一认证拦截 |
| ORM 框架 | MyBatis-Plus 3.5.6 | 灵活 SQL 控制 + 通用 CRUD 封装，契合复杂多表查询场景，提供分页插件与自动填充 |
| 关系型数据库 | MariaDB 10.6 (LTS) | MySQL 完全兼容、开源免费、性能稳定，社区版 LTS 长期维护 |
| 数据库连接池 | HikariCP 5.x | Spring Boot 默认连接池，性能业界领先，低开销高吞吐 |
| 缓存 | Redis 7.2.x（Spring Data Redis） | 高性能内存缓存，支撑登录态会话、Token 黑名单、账号/租户状态与验证码的实时读写 |
| 安全框架 | Spring Security（内置） | BCrypt 密码编码器 + 无状态会话管理 + 自定义 401/403 JSON 响应 |
| JWT 库 | JJWT (io.jsonwebtoken) 0.12.6 | 标准 JWT 实现，支持 RS256 非对称签名、Claims 解析与过期校验 |
| API 文档 | SpringDoc (springdoc-openapi) 2.5.0 | OpenAPI 3 自动生成，按模块分组，支持 Swagger UI 在线调试 |
| 密码加密 | BCrypt（Spring Security Crypto） | 自带盐值的慢哈希算法，抗彩虹表攻击 |
| JSON 处理 | Jackson 2.16.x | Spring 默认 JSON 库，性能与生态成熟 |
| 工具库 | Hutool 5.8.26 | 雪花 ID、加密、集合等通用工具封装，减少样板代码 |
| 代码简化 | Lombok 1.18.32 | @Data/@Slf4j/@Builder 减少样板代码 |
| 数据库驱动 | MariaDB Connector/J 3.3.3 | MariaDB 官方驱动 |
| 构建工具 | Maven 3.9+ | 多模块依赖管理成熟，父 POM 统一版本管控 |
| 单元测试 | JUnit 5 + Mockito | Spring Boot Starter Test 内置，认证服务已有 206+ 个单元测试 |
| 客户端 | Flutter（Dart 3） | 一套代码覆盖 Android/iOS/H5/桌面端，降低多端维护成本 |

## 3. 系统上下文图

```mermaid
C4Context
    title 云漫智企（CloudStrollOffice）系统上下文图
    Person(pc, "PC 端用户", "企业员工/管理员，浏览器访问")
    Person(mobile, "移动端用户", "Android/iOS/微信小程序用户")
    Person(h5, "H5 用户", "移动浏览器访客")
    Person(admin, "系统管理员", "初始化系统、租户与权限，全局安全管控")
    Person(ops, "运维人员", "健康检查与系统监控")
    Person(thirdparty, "第三方平台", "OAuth 提供商（微信/Gitee 等）")

    System(cso, "云漫智企系统", "微服务企业办公套件：统一认证（多模式登录注册、JWT RS256 双 Token、RBAC 多租户权限）+ 企业信息/人事/工作流/薪酬等业务能力")

    Rel(pc, "cso", "登录/注册/办公操作（HTTPS）")
    Rel(mobile, "cso", "移动端登录/注册/办公操作（HTTPS）")
    Rel(h5, "cso", "H5 登录/注册/办公操作（HTTPS）")
    Rel(admin, "cso", "租户/用户/角色/权限管理")
    Rel(ops, "cso", "健康检查/监控")
    Rel(cso, "thirdparty", "OAuth 授权回调校验")
```

## 4. 容器图

```mermaid
C4Container
    title 云漫智企容器图

    Person(user, "客户端", "PC / H5 / Android / iOS / 微信小程序 / 第三方 API")

    Container(gw, "API 网关 gateway", "Java 21 / Spring Cloud Gateway", "端口 9000：路由转发、CORS、Nacos 服务发现、AuthFilter 全局认证拦截（9 步校验）、用户信息 Header 透传")
    Container(auth, "认证服务 auth-service", "Java 21 / Spring Boot + MyBatis-Plus", "端口 9100：多模式登录注册、JWT RS256 双 Token、RBAC 多租户权限、密码/手机号/验证码管理、登录日志审计")
    Container(biz, "企业服务 biz-service", "Java 21 / Spring Boot", "端口 9200：企业信息/人事管理骨架、健康检查")
    Container(sys, "系统服务 system-service", "Java 21 / Spring Boot", "端口 9400：系统配置/日志/监控/定时任务骨架、健康检查")
    Container(common, "公共模块 common", "Java 21 / JAR", "统一响应体、异常体系、错误码、公共配置与 DTO/枚举/工具类")

    ContainerDb(db, "MariaDB 10.6", "关系型数据库", "认证库 cloudstroll_office_auth（9 张表：租户/用户/角色/权限/关联表/登录日志/OAuth 账号/验证码记录）")
    ContainerDb(redis, "Redis 7.2.x", "缓存", "登录态会话、Token 黑名单、账号/租户状态缓存、验证码缓存与频率计数")
    Container(nacos, "Nacos 2.3.0", "注册中心/配置中心", "服务注册发现、配置管理")

    Rel(user, "gw", "HTTPS 请求（Bearer Token）", "9000")
    Rel(gw, "auth", "路由转发 /api/v1/auth/**", "9100")
    Rel(gw, "biz", "路由转发 /api/v1/biz/**", "9200")
    Rel(gw, "sys", "路由转发 /api/v1/system/**", "9400")
    Rel(auth, "db", "业务数据读写", "3306")
    Rel(biz, "db", "业务数据读写（预留）", "3306")
    Rel(sys, "db", "业务数据读写（预留）", "3306")
    Rel(auth, "redis", "会话/黑名单/状态/验证码", "6379")
    Rel(gw, "redis", "黑名单/登录态/状态校验", "6379")
    Rel(gw, "nacos", "服务发现/配置", "8848")
    Rel(auth, "nacos", "注册与配置", "8848")
    Rel(biz, "nacos", "注册与配置", "8848")
    Rel(sys, "nacos", "注册与配置", "8848")
    Rel(auth, "common", "依赖公共模块", "")
    Rel(gw, "common", "依赖公共模块", "")
```

## 5. 组件图

### 5.1 API 网关（cloudoffice-gateway）组件图

```mermaid
C4Component
    title 网关容器内部组件

    ContainerDb(redis, "Redis", "黑名单/登录态/状态缓存")
    Container(auth, "auth-service", "认证服务")
    ContainerDb(nacos, "Nacos", "注册中心")

    Component(gw_app, "GatewayApplication", "启动类", "网关启动入口")
    Component(auth_filter, "AuthFilter", "全局认证过滤器", "9 步校验：白名单放行 → Bearer 格式 → RS256 公钥验签 → tokenType → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传（X-User-Id / X-Tenant-Id / X-User-Name / X-Client-Type / X-Roles / X-Permissions）")
    Component(rsa_cfg, "RsaKeyConfig", "RSA 公钥配置", "提供 RS256 验签公钥")
    Component(redis_cfg, "RedisConfig", "Redis 配置", "响应式 Redis 客户端连接")
    Component(auth_props, "AuthProperties", "认证属性", "白名单路径、Header 名称等配置")

    Rel(gw_app, "auth_filter", "装配全局过滤器")
    Rel(auth_filter, "rsa_cfg", "读取公钥验签")
    Rel(auth_filter, "redis_cfg", "黑名单/登录态/状态查询")
    Rel(auth_filter, "redis", "读写黑名单与状态")
    Rel(auth_filter, "nacos", "服务发现路由转发")
    Rel(auth_filter, "auth", "转发至认证服务")
```

### 5.2 认证服务（cloudoffice-auth-service）组件图

```mermaid
C4Component
    title 认证服务容器内部组件

    ContainerDb(redis, "Redis", "会话/黑名单/验证码/状态缓存")
    ContainerDb(db, "MariaDB", "cloudstroll_office_auth（9 表）")

    Component(auth_ctl, "AuthController", "认证接口层", "12 个端点：登录/注册/刷新/登出/踢人/发送验证码/密码修改/密码找回/手机号变更/账号补全等")
    Component(user_ctl, "UserController", "用户管理接口", "分页/详情/更新/状态/角色分配/删除")
    Component(role_ctl, "RoleController", "角色管理接口", "CRUD + 权限分配")
    Component(perm_ctl, "PermissionController", "权限管理接口", "树形列表/CRUD")

    Component(auth_svc, "AuthenticationService", "认证编排服务", "统一编排登录/注册流程，按模式路由策略工厂")
    Component(login_svc, "LoginService", "登录认证服务", "13 步完整登录流程（参数校验→策略校验→租户/账号状态→会话管理→签发双 Token）")
    Component(token_svc, "TokenService", "Token 服务", "双 Token 签发 + 刷新轮换（旧 Refresh Token 入黑名单）")
    Component(session_svc, "LoginSessionService", "会话管理服务", "Redis 登录态/黑名单/踢人实时失效")
    Component(log_svc, "LoginLogService", "登录日志审计", "记录 IP/客户端类型/结果/失败原因")
    Component(pwd_svc, "PasswordService", "密码管理服务", "修改/找回/重置，成功后清除全部登录态")
    Component(vc_mgr, "VerificationCodeManager", "验证码管理器", "生成/校验/频率控制/生命周期")
    Component(vc_svc, "VerificationCodeService", "验证码发送服务", "短信/邮箱发送，支持模拟模式")
    Component(rbac_svc, "UserService / RoleService / PermissionService", "RBAC 管理服务", "用户-角色-权限三层关联维护")

    Component(login_factory, "LoginStrategyFactory", "登录策略工厂", "按 loginMode 路由")
    Component(login_strategies, "LoginStrategy 接口 + 4 策略", "用户名密码/手机验证码/手机+密码/OAuth", "UsernamePasswordLoginStrategy、PhoneCodeLoginStrategy、PhonePasswordLoginStrategy、OAuthLoginStrategy")
    Component(reg_factory, "RegisterStrategyFactory", "注册策略工厂", "按 registerMode 路由")
    Component(reg_strategies, "RegisterStrategy 接口 + 5 策略", "用户名密码/手机验证码/OAuth/手机号设用户名/OAuth 补全信息", "UsernamePwdRegisterStrategy、PhoneCodeRegisterStrategy、OAuthRegisterStrategy、PhoneSetUsernameStrategy、OAuthSetInfoStrategy")

    Component(jwt_utils, "JwtUtils", "JWT 工具类", "RS256 双 Token 签发/解析/签名指纹（雪花 ID tokenVersion）")
    Component(sec_cfg, "SecurityConfig", "Spring Security", "BCrypt 编码器、无状态会话、401/403 JSON、白名单")
    Component(entity_mapper, "9 Entity + 9 Mapper", "数据访问层", "User/Tenant/Role/Permission/UserRole/RolePermission/LoginLog/OAuthAccount/VerificationCode")
    Component(common_dep, "common 模块", "公共依赖", "ApiResult/PageResult/异常体系/错误码/RedisKeyConstants/DTO/枚举")

    Rel(auth_ctl, "auth_svc", "登录/注册/刷新等请求")
    Rel(user_ctl, "rbac_svc", "用户管理请求")
    Rel(role_ctl, "rbac_svc", "角色管理请求")
    Rel(perm_ctl, "rbac_svc", "权限管理请求")
    Rel(auth_svc, "login_factory", "按 loginMode 路由登录策略")
    Rel(auth_svc, "reg_factory", "按 registerMode 路由注册策略")
    Rel(login_svc, "login_strategies", "调用策略校验凭证")
    Rel(login_svc, "token_svc", "签发双 Token")
    Rel(login_svc, "session_svc", "会话管理")
    Rel(login_svc, "log_svc", "记录登录日志")
    Rel(token_svc, "jwt_utils", "RS256 签名")
    Rel(pwd_svc, "vc_mgr", "验证码校验")
    Rel(vc_svc, "vc_mgr", "验证码生成/频率控制")
    Rel(auth_svc, "sec_cfg", "BCrypt 编码校验")
    Rel(entity_mapper, "db", "SQL 读写")
    Rel(auth_svc, "common_dep", "复用公共能力")
```

## 6. 部署架构图

```mermaid
flowchart TB
    subgraph client["客户端层"]
        PC["PC 浏览器"] 
        H5["H5 浏览器"]
        APP["Android / iOS App（Flutter）"]
        WX["微信小程序"]
        API3["第三方 API"]
    end

    subgraph docker["Docker Compose 编排（cloud-stroll-network 桥接网络）"]
        subgraph infra["基础设施容器"]
            NACOS["Nacos 2.3.0<br/>端口 8848<br/>注册中心/配置中心"]
            DB["MariaDB 10.6<br/>端口 3306<br/>数据卷 mariadb-data"]
            REDIS["Redis 7.2<br/>端口 6379"]
        end
        subgraph app["微服务容器（多阶段构建镜像）"]
            GW["cloud-stroll-gateway<br/>端口 9000<br/>AuthFilter 认证拦截"]
            AUTH["cloud-stroll-auth-service<br/>端口 9100<br/>RSA_PRIVATE_KEY / RSA_PUBLIC_KEY"]
            BIZ["cloud-stroll-biz-service<br/>端口 9200<br/>骨架"]
            SYS["cloud-stroll-system-service<br/>端口 9400<br/>骨架"]
        end
    end

    PC --> GW
    H5 --> GW
    APP --> GW
    WX --> GW
    API3 --> GW

    GW -->|"/api/v1/auth/**"| AUTH
    GW -->|"/api/v1/biz/**"| BIZ
    GW -->|"/api/v1/system/**"| SYS
    GW -->|"黑名单/登录态/状态校验"| REDIS

    AUTH -->|"9 张业务表"| DB
    BIZ --> DB
    SYS --> DB
    AUTH -->|"会话/黑名单/验证码"| REDIS

    GW --> NACOS
    AUTH --> NACOS
    BIZ --> NACOS
    SYS --> NACOS
```

**端口规划**：

| 容器/服务 | 端口 | 说明 |
| --- | --- | --- |
| gateway | 9000 | API 网关（唯一对外入口） |
| auth-service | 9100 | 认证服务 |
| biz-service | 9200 | 企业服务 |
| system-service | 9400 | 系统服务 |
| Nacos | 8848 | 注册中心 & 配置中心 |
| MariaDB | 3306 | 关系型数据库 |
| Redis | 6379 | 缓存 |

生产环境推荐拓扑：`负载均衡器（Nginx/ALB） → 网关实例集群 → 各微服务多实例（经 Nacos 注册发现） → MariaDB/Redis`；RSA 密钥对（`RSA_PRIVATE_KEY`/`RSA_PUBLIC_KEY`）、数据库密码等敏感配置仅通过环境变量注入，不写入镜像与仓库。

## 7. 安全架构

### 7.1 认证与授权

- **JWT RS256 双 Token**：RSA 2048 位非对称密钥对，认证服务持有私钥签名，网关持公钥验签。Access Token 有效期 2 小时，Refresh Token 有效期 7 天；刷新采用轮换机制，旧 Refresh Token 立即加入黑名单防重放。
- **网关统一认证（AuthFilter 9 步校验）**：白名单放行 → `Authorization: Bearer` 格式校验 → RS256 公钥验签 → `tokenType=access` 校验 → Redis 黑名单检查 → 登录态校验 → 账号状态校验（封禁 403） → 租户状态校验（禁用 403） → 用户信息 Header 透传（X-User-Id / X-Tenant-Id / X-User-Name / X-Client-Type / X-Roles / X-Permissions）。
- **多模式身份校验**：登录/注册按模式经策略工厂路由，密码走 BCrypt 校验、验证码走 Redis 一次性校验、OAuth 走第三方授权校验。
- **RBAC 多租户授权**：用户-角色-权限三层关联，租户间数据不可见，用户名/角色编码在租户内唯一；管理类接口由管理员角色操作。

### 7.2 传输与数据安全

- **传输安全**：生产环境经 HTTPS（负载均衡器终结 TLS）接入网关；网关配置 CORS 跨域策略。
- **密码安全**：密码使用 BCrypt 加盐散列存储，禁止明文；日志与响应禁止输出密码、Token、验证码等敏感信息。
- **密钥管理**：RSA 私钥/公钥、数据库密码等仅通过环境变量注入（`RSA_PRIVATE_KEY`/`RSA_PUBLIC_KEY`/`DB_PASSWORD` 等），密钥文件放 keys/ 且不入库，禁止提交仓库。
- **会话失效实时性**：登出、强制踢人（指定端/所有端）、改密、重置密码、账号封禁、租户停用均实时写入 Redis 黑名单/状态缓存，网关校验即刻生效。

### 7.3 审计与防滥用

- **登录日志审计**：登录全量记录（IP、客户端类型、结果、失败原因），安全事件可追溯。
- **验证码防爆破**：6 位数字、5 分钟过期、60 秒发送频率限制、一次性使用；开发环境模拟模式（`VERIFICATION_CODE_MOCK=true`）生产必须关闭。
- **统一异常不泄露**：全局异常处理器统一封装为标准 `ApiResult`，兜底不泄露堆栈与内部信息；网关/认证服务对 401/403 输出自定义 JSON 响应体。

## 8. 性能架构

- **缓存加速**：Redis 承载登录态会话、Token 黑名单、账号/租户状态缓存、验证码与频率计数，热点读取不落库；验证码默认 TTL 300 秒、会话按 Token 有效期管理，黑名单 TTL 对齐 Refresh Token 生命周期（7 天）。
- **连接池**：数据库使用 HikariCP 连接池（默认按 Spring Boot 配置），支撑服务高并发读写。
- **无状态会话**：服务不保存本地会话状态，认证状态全部外置 Redis，支持多实例水平伸缩。
- **高效 ID 生成**：JWT tokenVersion 使用 Hutool 雪花算法（Snowflake）生成，支持分布式唯一。
- **分页查询**：MyBatis-Plus 分页插件统一处理列表查询，避免全表扫描。
- **监控与健康检查**：三个业务服务提供 `/api/v1/{module}/health` 健康检查端点，返回服务名/状态/版本/时间戳；结合 Spring Boot Actuator 与容器健康检查保障可用性。
- **网关性能**：Spring Cloud Gateway 基于 WebFlux 响应式模型，全局过滤器为纯异步链路；认证校验均走 Redis 高速查询，避免同步阻塞。

## 9. 数据流图

### 9.1 认证请求总览数据流

```mermaid
flowchart LR
    C["客户端（PC/H5/App/小程序）"] -->|"1. 登录/注册/刷新（白名单）"| G["API 网关"]
    G -->|"2. 路由转发"| A["认证服务"]
    A -->|"3a. 凭证校验（BCrypt/验证码/OAuth）"| R["Redis"]
    A -->|"3b. 用户/租户/角色查询"| D["MariaDB"]
    A -->|"4. 签发双 Token + 记录登录态/日志"| C
    C -->|"5. 携带 Bearer Token 访问业务接口"| G
    G -->|"6. AuthFilter 9 步校验（验签/黑名单/登录态/账号/租户状态）"| R
    G -->|"7. 透传 X-User-Id 等 Header 转发"| B["业务服务（auth/biz/system）"]
    B -->|"8. 业务数据读写"| D
```

### 9.2 登录流程数据流

```mermaid
sequenceDiagram
    participant U as 用户/客户端
    participant G as API 网关
    participant A as 认证服务
    participant S as 登录策略（策略工厂）
    participant R as Redis
    participant DB as MariaDB

    U->>G: POST /api/v1/auth/login（loginMode + tenantCode + clientType + 凭证）
    G->>A: 白名单放行，路由转发
    A->>A: AuthenticationService 编排，参数校验
    A->>S: LoginStrategyFactory 按 loginMode 匹配策略
    alt 用户名密码模式
        S->>DB: 查询用户，BCrypt 校验密码
    else 手机验证码模式
        S->>R: 校验验证码（一次性，防爆破）
    else OAuth 模式
        S->>外部: OAuth 授权回调校验
    end
    S->>A: 返回用户实体
    A->>DB: 校验租户状态、账号状态（并刷新状态缓存）
    A->>R: 会话管理（同端互斥/多端共存），记录登录态
    A->>DB: 记录登录日志（t_auth_login_log）
    A-->>U: 签发双 Token（Access 2h + Refresh 7d）
    U->>G: 携带 Bearer Token 访问业务接口
    G->>G: AuthFilter 9 步校验（验签/黑名单/登录态/账号/租户状态）
    G->>R: 黑名单/登录态/状态查询
    G-->>U: 校验通过，透传 X-User-Id 等 Header 转发至业务服务
```

### 9.3 Token 刷新与登出/踢人数据流

```mermaid
sequenceDiagram
    participant U as 客户端
    participant A as 认证服务
    participant R as Redis
    participant J as JwtUtils

    U->>A: POST /refresh（refreshToken）
    A->>J: 验签 + 解析 Refresh Token
    A->>R: 校验 Refresh Token 未在黑名单、登录态有效
    A->>R: 旧 Refresh Token 加入黑名单（轮换防重放）
    A->>J: 签发新双 Token（tokenVersion 雪花 ID）
    A-->>U: 返回新 Token 对

    U->>A: POST /logout（幂等）
    A->>R: 清除登录态 + Token 入黑名单
    A-->>U: 登出成功

    Admin->>A: POST /kickout（userId + 可选 clientType）
    A->>R: 指定端/所有端 Token 入黑名单、清除登录态
    Admin-->>U: 目标用户后续请求被网关拦截（401）
```

## 10. 架构决策记录（ADR）

| 编号 | 决策主题 | 决策内容 | 理由 | 日期 |
| --- | --- | --- | --- | --- |
| ADR-001 | 微服务架构选型 | 采用 Spring Cloud 微服务架构，拆分为 gateway/auth/biz/system/common 五个模块，而非单体应用 | 业务域（认证/企业/系统）职责独立，支持独立开发、部署与伸缩；企业信息、人事、工作流、薪酬等模块演进需要独立扩展空间 | 2026-08-05 |
| ADR-002 | 认证独立服务 + 网关统一认证 | 认证能力独立成 auth-service，网关 AuthFilter 统一拦截全部请求做认证校验，而非在业务服务内各自鉴权 | 认证与业务解耦；安全策略集中管控（白名单/验签/黑名单/状态校验单点维护）；下游服务通过可信 Header 识别用户，避免重复实现与口径漂移 | 2026-08-05 |
| ADR-003 | JWT 采用 RS256 非对称签名 | 使用 RSA 2048 位密钥对，认证服务私钥签名、网关公钥验签，而非 HS256 对称密钥 | 私钥集中管理，网关与服务仅持有公钥即可验签，防密钥单点泄露扩散；支持网关多实例安全共享校验能力 | 2026-08-05 |
| ADR-004 | 双 Token + 轮换机制 | Access Token 2h + Refresh Token 7d，刷新时旧 Refresh Token 入黑名单轮换 | 短效 Access Token 降低泄露风险；Refresh Token 轮换防重放；无感续签兼顾安全与体验 | 2026-08-05 |
| ADR-005 | Redis 承载会话与状态 | 登录态、Token 黑名单、账号/租户状态、验证码均存 Redis | 登出/踢人/改密/封禁等操作可实时使会话失效（网关即时拦截）；多实例共享状态；验证码 TTL 与频率控制天然契合 Redis 特性 | 2026-08-05 |
| ADR-006 | 多租户 RBAC 权限模型 | 用户-角色-权限三层关联 + 租户数据隔离，用户名租户内唯一 | 多企业共用一套系统（SaaS 化）；三层模型权限粒度灵活，租户间数据不可见保障隔离 | 2026-08-05 |
| ADR-007 | 登录/注册策略工厂模式 | LoginStrategy（4 种）/ RegisterStrategy（5 种）接口 + 工厂按模式路由 | 新增登录/注册模式只需新增策略实现类，不修改主流程代码；开闭原则，认证能力可扩展 | 2026-08-05 |
| ADR-008 | 数据库选型 MariaDB 10.6 | 采用 MariaDB 10.6 (LTS) 而非 MySQL 企业版 | MySQL 完全兼容、开源免费、社区版 LTS 长期维护，无商业授权成本 | 2026-08-05 |
| ADR-009 | ORM 选型 MyBatis-Plus | 采用 MyBatis-Plus 3.5.6 而非 Spring Data JPA | 复杂多表 SQL 灵活可控、通用 CRUD 减少样板代码、分页插件与自动填充内置，契合企业办公套件查询场景 | 2026-08-05 |
| ADR-010 | 密码 BCrypt 散列存储 | 密码使用 BCrypt（Spring Security Crypto）加盐散列，禁止明文 | 自带盐值的慢哈希抗彩虹表与暴力破解；生态集成简单 | 2026-08-05 |
| ADR-011 | 网关 Header 透传用户信息 | 网关验签后以 X-User-Id 等 Header 透传用户信息，下游服务不再解析 Token | 验签与身份解析集中一次完成，下游服务轻量可信；避免各服务重复解析 JWT 的性能开销与不一致 | 2026-08-05 |
| ADR-012 | 客户端选型 Flutter | 移动端采用 Flutter（Dart 3）跨端框架 | 一套代码覆盖 Android/iOS/H5/桌面端，降低多端开发与维护成本，与后端 REST API 天然配合 | 2026-08-05 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
