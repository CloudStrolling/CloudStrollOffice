# 代码查询结果（TASK-004：补跑 v0.0.1 基线接口回归并闭环）

## 1. 任务要点回顾

- **任务**：执行 `python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`，使 TC-001~045 全部动态执行通过（PASS=45、FAIL=0、退出码 0），闭环 v0.0.1 基线遗留项 T-02（v0.2.5 回归报告记录的环境阻塞）。
- **已确认缺陷（需编码修复）**：auth-service `SecurityConfig.java` 的 permitAll 白名单缺少 `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh` 三端点，导致登录类用例（TC-001~004、TC-005~010 等）被 auth-service 的 Spring Security 拦截返回 401。
- **上游状态**：TASK-003 已完成（4 服务启动、健康检查通过）；bootstrap 依赖缺失（T-02 根因 1）与 RSA 密钥格式契约（T-02 根因 2）已由 TASK-001/TASK-002 修复。

## 2. 回归脚本结构与被测接口（scripts/API-TEST/cso-api-test-v0.0.1.py，共 1245 行）

### 2.1 用法与配置
- 用法：`python cso-api-test-v0.0.1.py [网关地址]`（默认 `http://localhost:9000`），传入网关地址（9000）即任务要求方式。
- 环境变量：`DB_HOST/DB_PORT/DB_USER/DB_PWD/DB_NAME`（验证码读取库连接，默认 root/root@127.0.0.1:3306/cloudstroll_office_auth）；`AUTH_DIRECT_URL`（认证服务直连地址，默认 `http://localhost:9100`，TC-043 使用）。
- 测试账号：`admin/admin123`、`TENANT_CODE=DEFAULT`、`CLIENT_TYPE=H5`；依赖 requests（必装）、pymysql（验证码闭环，缺失时验证码类用例 SKIP——不影响 FAIL 但影响"全部动态执行"）。
- 退出码：`0 = 全部通过（FAIL=0）`，`1 = 存在失败`。

### 2.2 关键辅助函数（供编码/排障参考）
| 函数 | 行号 | 作用 |
| --- | --- | --- |
| `req(method, path, token, json, headers)` | 88 | 统一请求封装，返回 (resp, body) |
| `api_ok(resp, body)` | 103 | 断言 HTTP 200 且 body.code==200 |
| `login(...)` | 108 | 登录（支持 4 种模式），返回 (accessToken, refreshToken, body) |
| `admin_login()` | 127 | 管理员登录并缓存 ADMIN_TOKEN（管理类用例复用） |
| `register_username(...)` | 139 | USERNAME 模式注册，返回 (userId, body) |
| `send_code(target, purpose, mode)` | 153 | 调 `/verification-code/send` 发验证码 |
| `fetch_code_from_db(target, purpose)` | 159 | pymysql 读库取最新未用验证码（`SELECT code FROM t_auth_verification_code WHERE target=%s AND purpose=%s AND used=0 ORDER BY id DESC LIMIT 1`） |
| `db_available()` | 181 | 检查 pymysql 可用性 |
| `protected_get(token)` | 190 | 携带 token 访问 GET `/users`（网关透传租户头），返回 HTTP 状态码 |

### 2.3 45 个用例与 API-001~033 映射（main 中按序执行）
| 用例 | 覆盖 API | 用例 | 覆盖 API |
| --- | --- | --- | --- |
| TC-001 用户名密码注册 | API-002 | TC-024 旧密码错误被拒 | API-006 |
| TC-002 手机验证码注册 | API-002/011 | TC-025 找回发送验证码 | API-007 |
| TC-003 OAuth 两步注册 | API-002 | TC-026 找回重置密码 | API-008 |
| TC-004 重复登录名/弱密码 | API-002 | TC-027 变更手机号 | API-009 |
| TC-005 用户名密码登录 | API-001 | TC-028 账号补全 | API-010 |
| TC-006 防账号枚举 | API-001 | TC-029 用户分页 | API-013 |
| TC-007 手机验证码登录 | API-001/011 | TC-030 用户详情 | API-014 |
| TC-008 手机+密码登录 | API-001 | TC-031 更新用户 | API-015 |
| TC-009 封禁登录被拒 | API-001/018 | TC-032 用户启禁用 | API-018 |
| TC-010 无效模式/客户端 | API-001 | TC-033 分配角色 | API-017 |
| TC-011 刷新成功 | API-003 | TC-034 创建角色 | API-022 |
| TC-012 刷新轮换防重放 | API-003 | TC-035 角色编码重复 | API-022 |
| TC-013 同端互斥 | API-001/013 | TC-036 删除角色 | API-024 |
| TC-014 多端共存 | API-001/013 | TC-037 角色分配权限 | API-025 |
| TC-015 登出后 Token 失效 | API-004/003 | TC-038 权限树 | API-026 |
| TC-016 重复登出幂等 | API-004 | TC-039 创建权限 | API-029 |
| TC-017 管理员踢人 | API-005 | TC-040 更新/删除权限 | API-030/031 |
| TC-018 非管理员踢人被拒 | API-005 | TC-041 白名单免 Token | API-012/001 |
| TC-019 发送验证码成功 | API-011 | TC-042 缺失/伪造 Token 401 | 网关鉴权 |
| TC-020 发送限频 429 | API-011 | TC-043 租户头透传 | 网关鉴权 |
| TC-021 验证码一次性 | API-011/001 | TC-044 多租户隔离 | API-013 |
| TC-022 验证码用途隔离 | API-011/001 | TC-045 三服务健康检查 | API-012/032/033 |
| TC-023 修改密码成功 | API-006 | | |

### 2.4 用例依赖的服务
- 网关 9000（全部用例）、auth-service 9100（全部经网关或 TC-043 直连）；biz-service 9200 / system-service 9400 仅 TC-045 需要（需携带有效 Token 经网关访问，因网关白名单未包含这两路径）。
- 管理类用例（TC-009、017、029~040 等）依赖 `admin_login()` 成功，否则 SKIP——登录被 401 阻断时整批用例受影响，故 SecurityConfig 缺陷为 P0。

## 3. 缺陷 1 修复位置（auth-service SecurityConfig）

- **文件**：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.java`（共 90 行）
- **修复位置**：`defaultSecurityFilterChain(HttpSecurity http)` 方法内 `authorizeHttpRequests` 块（**第 62~69 行**）：
  - 现状 permitAll 仅含：`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`，其余 `anyRequest().authenticated()`（第 68 行）。
  - **缺失**（需增补 `.requestMatchers(...).permitAll()`）：`/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`。
- 接口层契约（AuthController.java 的 `@PostMapping("/login"|"/register"|"/refresh")`，第 116/134/152 行）无需改动；修复仅限 SecurityConfig 配置层，与 API 文档白名单契约一致，不违反 F-005 修复约束。
- 修改后需重新构建 auth-service jar 并重启（必要时同时重启 gateway），再执行回归脚本。

## 4. 网关白名单配置（已正确，无需修改）

- **文件**：`cloudoffice-gateway/src/main/resources/application.yml`（`auth.white-list`，**第 50~61 行**）：
  `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
  - 登录/注册/刷新三端点**网关层已放行**，缺陷只在 auth-service 层（SecurityConfig）。
- **配置类**：`cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/AuthProperties.java`（`@ConfigurationProperties(prefix="auth")`，`whiteList` 字段，第 34 行）。
- **过滤器**：`cloudoffice-gateway/.../filter/AuthFilter.java`——第 1 步白名单放行（第 130~135 行 `isWhiteListPath`），第 2~9 步 Bearer 格式→RS256 验签→tokenType→黑名单→登录态→账号状态→租户状态→Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）；`isWhiteListPath` 用 Ant 风格 `PATH_MATCHER` 匹配（第 237~248 行）。

## 5. 验证码模拟读取逻辑（回归闭环依据）

- **开关**：`cloudoffice-auth-service/src/main/resources/application.yml` 第 62~67 行 `app.verification-code.mock=true`（开发模拟模式）+ expire-seconds=300、send-interval-seconds=60、length=6。
- **模拟发送**：`cloudoffice-auth-service/.../service/impl/SimulatedVerificationCodeService.java`（`@ConditionalOnProperty(name="app.verification-code.mock", havingValue="true", matchIfMissing=true)`，仅 log.info 输出验证码，不真实发送）。
- **落库**：`VerificationCodeManagerImpl.generateCode(target, mode, purpose)`（第 62~100 行）：6 位随机码（100000~999999）→ 插入 `t_auth_verification_code`（target/code/send_mode/purpose/expire_time/used=0）→ Redis 缓存 + 频率控制标记（60s）。
- **校验**：`verifyCodeInternal`（第 132~162 行）：存在性→过期→已用（used==1 拒绝）→内容匹配→标记 used=1（单次使用闭环）。
- **用途约定**（脚本与落库必须一致，已核对一致）：
  - 注册 `REGISTER`、登录 `LOGIN`、换绑 `CHANGE_PHONE`（脚本 send_code 直传）；
  - 密码找回：脚本请求 purpose=`RESET_PASSWORD`，`PasswordService.forgotPasswordSendCode`（第 132 行）内部转 `RESET_PWD` 落库，脚本 `fetch_code_from_db(phone, "RESET_PWD")` 读取——匹配。
- **表结构**：`scripts/sql/init-v0.2.0-full.sql` 第 249~265 行 `t_auth_verification_code`（字段 target/code/send_mode/purpose/expire_time/used/used_time/send_count + 审计字段，索引 idx_target_purpose）。
- **注意**：TC-020 限频用例依赖 Redis 频率键（`buildVerificationCodeFreqKey`），两次发送间隔需 >60s 或数据独立（脚本用新手机号，正常通过）。

## 6. API-001~033 关键接口实现（控制器映射清单）

- **AuthController**（`@RequestMapping("/api/v1/auth")`，文件 `cloudoffice-auth-service/.../controller/AuthController.java`，共 372 行）：
  - `POST /login`（116）、`POST /register`（134）、`POST /refresh`（152）、`POST /logout`（173）、`POST /kickout`（199）、`PUT /password/change`（220）、`POST /password/forgot/send-code`（238）、`POST /password/forgot/reset`（256）、`PUT /phone/change`（276）、`PUT /account/settlement`（294）、`POST /verification-code/send`（321）。
  - 私有方法 `getCurrentUserId()`（351）：从网关透传 `X-User-Id` 头取当前用户 ID，缺失抛 UNAUTHORIZED——TC-043 直连缺头被拒依赖此逻辑。
- **UserController**（`@RequestMapping("/api/v1/auth/users")`）：`GET`（分页，67）、`GET /{id}`（88）、`PUT /{id}`（109）、`DELETE /{id}`（134）、`PUT /{id}/roles`（152）、`PUT /{id}/status`（178）。
- **RoleController**（`@RequestMapping("/api/v1/auth/roles")`）：`GET`（分页，57）、`GET /list`（74）、`GET /{id}`（89）、`POST`（104）、`PUT /{id}`（120）、`DELETE /{id}`（139）、`PUT /{id}/permissions`（157）。
- **PermissionController**（`@RequestMapping("/api/v1/auth/permissions")`）：`GET /tree`（61）、`GET /list`（73）、`GET /{id}`（86）、`POST`（102）、`PUT /{id}`（119）、`DELETE /{id}`（138）。
- **HealthController**（`@RequestMapping("/api/v1/auth")`，`GET /health`，37 行）：返回 ApiResult，data 含 service/status=UP/version/timestamp（ISO 字符串）。
- 全部接口统一返回 `ApiResult<T>`（成功 code=200）；用户/角色/权限管理接口均需认证（网关校验 JWT 并透传租户头）。

## 7. v0.2.5 回归报告问题记录（docs/cso-v0.2.5/regression-api-test.md，需闭环）

- **TC-001~045 状态**：环境阻塞（脚本在 admin 登录连接拒绝崩溃，退出码 1），非契约失败。
- **根因 T-02（v0.0.1 基线遗留）**：
  1. 全项目 pom 缺 `spring-cloud-starter-bootstrap`，bootstrap.yml 不加载、Nacos 引导断裂（**TASK-001 已修复**，改动 5 个 pom.xml）；
  2. env.json RSA 密钥为 PEM 整体 Base64（多行含 BEGIN/END），Java 端期望 DER 单行 Base64，网关启动报"RSA 公钥解析失败"（**TASK-002 已修复**，改动 deploy-rsa-keygen.ps1 与 env.json，运行时代码零改动）。
- **本任务新增修复项**：SecurityConfig 白名单缺陷（上文第 3 节），修复后重新构建重启 auth-service，再执行回归脚本，将结果与 T-02 闭环说明写入 `docs/cso-v0.2.6/regression-api-test.md`。

## 8. 相关脚本与版本资产

- `scripts/API-TEST/cso-api-test-v0.0.1.py`（本任务回归脚本，TC-001~045，1245 行）；
- `scripts/API-TEST/cso-api-test-v0.2.6.py`（TASK-001~003 回归脚本，TC-052~064，静态契约确认 + 健康检查探活 + RS256 链路，非本任务执行对象）；
- `docs/cso-v0.2.6/`：已有 cso-api-v0.2.6.md、cso-testcase-v0.2.6.md、cso-task-v0.2.6.json、cso-urs/prd/lld/dbd 及 task_TASK-001~004 目录；
- `docs/cso-v0.2.6/version_progress.md`：impm-task-coding-context TASK-004-已完成、impm-task-coding TASK-004-执行中（本步骤 cs 完成后由 impm_progress 记录 TASK-004-已完成）。

## 9. 查询结论（供编码/测试阶段使用）

1. **编码修复范围**：仅 `SecurityConfig.java` 第 62~69 行 authorizeHttpRequests 增补 login/register/refresh 三端点 permitAll；不触碰 Controller/DTO/响应体与客户端代码。
2. **修复后动作**：重新构建 auth-service（`mvn -pl cloudoffice-auth-service -am package` 或按 deploy 方案），重启 auth-service（必要时 gateway）；TASK-003 已确认 4 服务可启动。
3. **回归执行**：`python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`，期望 PASS=45、FAIL=0、退出码 0；验证码类用例需确保 pymysql 可连库（root/root@127.0.0.1:3306/cloudstroll_office_auth）。
4. **数据清理**：用例均用 uuid 独立数据，重复执行无冲突；历史残留测试数据不影响断言（唯一性校验只针对重名），如有失败按 context 约定清理后重跑。
5. **结果记录**：回归结果与 T-02 闭环说明写入 `docs/cso-v0.2.6/regression-api-test.md`。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
