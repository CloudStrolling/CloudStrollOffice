# 任务上下文（TASK-004：补跑 v0.0.1 基线接口回归并闭环）

## 1. 任务信息

- **任务编号**：TASK-004
- **任务名称**：补跑 v0.0.1 基线接口回归并闭环（cso-api-test-v0.0.1.py，TC-001~045）
- **任务类型**：common
- **优先级**：P0
- **关联用户故事**：US-003（PRD F-004）
- **上游任务**：TASK-003（已完成，服务启动与健康检查验证通过）
- **下游任务**：无
- **当前状态**：未完成

### 任务描述
在 TASK-003 服务启动验证通过后（PRD F-004，US-003）：执行 `python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`，使 TC-001~045（v0.0.1 基线接口契约 API-001~API-033 动态回归：登录/刷新/登出/用户/角色/权限/网关鉴权/健康检查等）全部动态执行通过，消除历史"待执行/环境阻塞"状态（v0.2.5 回归报告记录的阻塞项）。

### 验收标准（AC）
1. 脚本正常跑完、退出码 0，不再因连接拒绝崩溃；
2. TC-001~045 全部动态执行通过，PASS=45、FAIL=0；
3. 登录、认证、网关鉴权、业务接口契约（API-001~API-033）全部动态通过；
4. 回归结果记录到 docs/cso-v0.2.6/regression-api-test.md（用例明细、统计、根因闭环说明 T-02），闭环 v0.0.1 基线遗留项。

### 测试方法
接口测试：执行 `python cso-api-test-v0.0.1.py http://localhost:9000` 动态回归，核对 TC-001~045 断言结果与退出码。

### 前置条件
- 网关（9000）、auth-service（9100）可访问（TASK-003 已验证）；
- MariaDB/Redis/Nacos 正常运行；
- admin 账号（admin/admin123）可用；
- 企业服务（9200）/系统服务（9400）仅 TC-045 需要。

## 2. 缺陷记录（TASK-003 runtest 发现，本任务需编码修复）

> **重要**：TASK-003 runtest 发现以下缺陷将阻塞本任务登录类用例，需在编码阶段修复（修复后重新构建并启动 auth-service，再执行回归脚本）。

### 缺陷 1（P0）：auth-service SecurityConfig permitAll 缺少登录/注册/刷新三端点，导致登录 401
- **位置**：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.java`（defaultSecurityFilterChain）
- **现状**（已确认）：permitAll 仅配置了
  - `/api/v1/auth/health`
  - `/api/v1/auth/verification-code/send`
  - `/api/v1/auth/password/forgot/send-code`
  - `/api/v1/auth/password/forgot/reset`
  - `/swagger-ui/**`、`/v3/api-docs/**`
  - 其余 `anyRequest().authenticated()`
- **缺失端点**（API 文档白名单契约要求放行）：
  1. `/api/v1/auth/login`（API-001 用户登录）
  2. `/api/v1/auth/register`（API-002 用户注册）
  3. `/api/v1/auth/refresh`（API-003 刷新 Token）
- **现象**：客户端/回归脚本经网关调用登录接口时，网关白名单放行后转发至 auth-service，auth-service 的 Spring Security 因无匿名放行将请求拦截返回 401，登录类用例（TC-001~004 等）全部失败。
- **修复方向**：在 SecurityConfig 的 authorizeHttpRequests 中为上述 3 个端点增加 permitAll()（与 API 文档白名单契约一致；不得删除既有 permitAll 端点，不得改动接口层 Controller/DTO/响应体契约）。修复后需重新构建并重启 auth-service，再进行回归。

## 3. 用户需求（US-003：完成 v0.0.1 基线接口动态回归闭环）

### 故事描述
作为（测试工程师），我想要（在服务可用的环境下补跑 v0.0.1 基线接口回归脚本），以便（TC-001~045 全部动态执行通过，消除"待执行/环境阻塞"历史状态，确认基线接口契约 API-001~API-033 真实可用）。

### 验收标准
- Given 网关（9000）与认证服务（9100）可访问，When 执行 `python cso-api-test-v0.0.1.py http://localhost:9000`，Then 脚本正常跑完，退出码 0，不再因连接拒绝崩溃；
- Given 基线回归脚本执行完成，When 核对 TC-001~045 执行结果，Then PASS=45、FAIL=0，登录、认证、网关鉴权、业务接口契约全部动态通过；
- Given 回归结果汇总完成，When 输出 v0.2.6 接口回归报告，Then 记录 TC-001~045 执行结果与结论，闭环 v0.0.1 基线遗留项。

### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 个别用例因测试数据冲突失败 | 记录失败用例，清理测试数据后重跑，直至全部通过 |
| 服务再次启动失败 | 回到 US-001/US-002 排查依赖与密钥配置 |
| 脚本参数与项目约定不一致 | 按脚本 README/项目文档约定传参（项目根或网关地址） |
| 回归环境数据残留（用户/验证码缓存） | 执行脚本前清理或按脚本约定重置测试数据 |

## 4. 历史阻塞根因（v0.2.5 回归报告记录，本任务需闭环 T-02）

v0.0.1 基线接口回归（TC-001~045）历史一直处于**环境阻塞**状态（脚本在 admin 登录步骤即因连接拒绝崩溃，退出码 1），根因（v0.0.1 基线遗留缺陷 T-02，v0.2.6 已由 TASK-001/TASK-002 修复）：
1. **bootstrap 依赖缺失**：全项目 pom 均未引入 `spring-cloud-starter-bootstrap`，Spring Boot 3.x 下 bootstrap.yml 默认不加载，auth/biz/system 启动报 `No spring.config.import property has been defined`（TASK-001 已修复）；
2. **RSA 密钥格式契约不匹配**：deploy/env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 PEM 文件整体 Base64（多行、含 BEGIN/END 标记），Java 端 RsaKeyConfig 使用严格 `Base64.getDecoder()` + `X509EncodedKeySpec`（期望 DER 编码单行 Base64），网关启动报 `RSA 公钥解析失败`（TASK-002 已修复）。

TASK-003 已验证 4 个服务全部启动、健康检查通过。本任务即在此基础上补跑 v0.0.1 基线回归脚本，实现 TC-001~045 动态闭环。

## 5. 回归脚本信息（scripts/API-TEST/cso-api-test-v0.0.1.py）

- **覆盖范围**：docs/cso-v0.0.1/cso-testcase-v0.0.1.md 中 TC-001 ~ TC-045 全部接口测试用例；
- **接口基准**：docs/cso-api.md（统一前缀 `/api/v1/{module}`，统一响应 ApiResult<T>，成功 code=200）；
- **用法**：`python cso-api-test-v0.0.1.py`（默认 http://localhost:9000）或 `python cso-api-test-v0.0.1.py http://10.0.0.8:9000`；
- **依赖**：requests（必装）；验证码从数据库读取需 pymysql（可选，缺失时相关用例 SKIP——注意：SKIP 不视为 FAIL，但验收要求 PASS=45、FAIL=0，建议安装 pymysql 使验证码类用例动态执行）；
- **环境变量**：DB_HOST/DB_PORT/DB_USER/DB_PWD/DB_NAME 覆盖验证码读取库连接（默认 root/root@127.0.0.1:3306/cloudstroll_office_auth）；AUTH_DIRECT_URL 覆盖认证服务直连地址（默认 http://localhost:9100）；
- **测试账号**：admin/admin123（项目初始测试账号），TENANT_CODE=DEFAULT，CLIENT_TYPE=H5；
- **关键说明**：
  - 需网关（9000）、认证服务（9100）及数据库/Redis 已启动；企业服务（9200）/系统服务（9400）仅 TC-045 需要；
  - 验证码为模拟发送模式（app.verification-code.mock=true），脚本通过 pymysql 读取 t_auth_verification_code 表获取最新验证码闭环；
  - 管理接口经网关访问，X-Tenant-Id/X-Roles 等头由网关 AuthFilter 从 JWT 自动透传；TC-043 直连认证服务时验证缺少 X-Tenant-Id 被拒；
  - OAuth 无真实第三方服务，按 oauthCode 即 openId 的模拟方式执行；
  - 脚本为每个用例创建独立测试数据（uuid 命名），用例间互不污染；管理员登录失败时管理类用例标记 SKIP；
  - 退出码 0 = 全部通过（PASS=45、FAIL=0）。

## 6. v0.0.1 基线接口契约清单（API-001~API-033）

| 编号 | 接口 | 方法/路径 | 认证要求 |
| --- | --- | --- | --- |
| API-001 | 用户登录 | POST /api/v1/auth/login | 白名单 |
| API-002 | 用户注册 | POST /api/v1/auth/register | 白名单 |
| API-003 | 刷新 Token | POST /api/v1/auth/refresh | 白名单 |
| API-004 | 用户登出 | POST /api/v1/auth/logout | 需认证 |
| API-005 | 强制踢人 | POST /api/v1/auth/kickout | 需认证 |
| API-006 | 修改密码 | PUT /api/v1/auth/password/change | 需认证 |
| API-007 | 密码找回-发送验证码 | POST /api/v1/auth/password/forgot/send-code | 白名单 |
| API-008 | 密码找回-重置密码 | POST /api/v1/auth/password/forgot/reset | 白名单 |
| API-009 | 修改手机号 | PUT /api/v1/auth/phone/change | 需认证 |
| API-010 | 完善账号信息 | PUT /api/v1/auth/account/settlement | 需认证 |
| API-011 | 发送验证码 | POST /api/v1/auth/verification-code/send | 白名单 |
| API-012 | 认证服务健康检查 | GET /api/v1/auth/health | 白名单 |
| API-013 | 分页查询用户列表 | GET /api/v1/auth/users | 需认证 |
| API-014 | 获取用户详情 | GET /api/v1/auth/users/{id} | 需认证 |
| API-015 | 更新用户信息 | PUT /api/v1/auth/users/{id} | 需认证 |
| API-016 | 逻辑删除用户 | DELETE /api/v1/auth/users/{id} | 需认证 |
| API-017 | 分配用户角色 | PUT /api/v1/auth/users/{id}/roles | 需认证 |
| API-018 | 变更用户状态 | PUT /api/v1/auth/users/{id}/status | 需认证 |
| API-019 | 分页查询角色列表 | GET /api/v1/auth/roles | 需认证 |
| API-020 | 查询所有角色 | GET /api/v1/auth/roles/list | 需认证 |
| API-021 | 获取角色详情 | GET /api/v1/auth/roles/{id} | 需认证 |
| API-022 | 创建角色 | POST /api/v1/auth/roles | 需认证 |
| API-023 | 更新角色 | PUT /api/v1/auth/roles/{id} | 需认证 |
| API-024 | 删除角色 | DELETE /api/v1/auth/roles/{id} | 需认证 |
| API-025 | 分配角色权限 | PUT /api/v1/auth/roles/{id}/permissions | 需认证 |
| API-026 | 树形权限列表 | GET /api/v1/auth/permissions/tree | 需认证 |
| API-027 | 所有权限列表 | GET /api/v1/auth/permissions/list | 需认证 |
| API-028 | 获取权限详情 | GET /api/v1/auth/permissions/{id} | 需认证 |
| API-029 | 创建权限 | POST /api/v1/auth/permissions | 需认证 |
| API-030 | 更新权限 | PUT /api/v1/auth/permissions/{id} | 需认证 |
| API-031 | 删除权限 | DELETE /api/v1/auth/permissions/{id} | 需认证 |
| API-032 | 企业服务健康检查 | GET /api/v1/biz/health | 需认证（备注见下） |
| API-033 | 系统服务健康检查 | GET /api/v1/system/health | 需认证（备注见下） |

> 备注：网关白名单仅配置了 `/api/v1/auth/health`；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入网关白名单，直连服务端口可免认证访问，经网关访问需携带有效 Token。

## 7. 项目信息与架构要点（与任务相关）

- **项目**：云漫智企（CloudStrollOffice），Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 微服务套件；
- **端口**：网关 9000、auth-service 9100、biz-service 9200、system-service 9400、Nacos 8848、MariaDB 3306、Redis 6379；
- **认证链路**：网关 AuthFilter 9 步校验（白名单放行 → Bearer 格式 → RS256 验签 → tokenType → 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传 X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）；
- **Token 方案**：JWT RS256 双 Token（Access 2h + Refresh 7d + 刷新轮换旧 Refresh 入黑名单）；
- **白名单端点**（API 文档契约）：登录/注册/刷新/验证码发送/密码找回/健康检查/OpenAPI 直接放行；
- **统一响应**：ApiResult<T>（code/message/data/timestamp），成功 code=200；错误码统一 29 个；
- **数据库**：MariaDB cloudstroll_office_auth 库 9 张表；验证码表 t_auth_verification_code（回归脚本经 pymysql 读取模拟验证码闭环）；
- **本版本修复约束**（F-005）：修复范围严格限定在依赖配置、密钥格式契约与服务启动链路，不触碰接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码；SecurityConfig 属配置层，增补 permitAll 白名单端点不违反该约束（与 API 文档白名单契约一致）。

## 8. 执行要点提示（供编码/测试阶段参考）

1. 先修复 SecurityConfig 缺失白名单端点（缺陷 1），重新构建并重启 auth-service（必要时同时重启 gateway）；
2. 确认 4 个服务健康检查通过后，执行 `python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`；
3. 核对结果：退出码 0、PASS=45、FAIL=0、SKIP 尽量为 0（SKIP 不影响 FAIL，但影响"全部动态执行"的闭环效果，建议安装 pymysql 保证验证码类用例动态执行）；
4. 个别用例因数据冲突失败时：记录失败用例 → 清理测试数据（测试用户/验证码）→ 重跑直至全部通过；
5. 回归结果记录到 `docs/cso-v0.2.6/regression-api-test.md`（用例明细、统计、根因闭环说明 T-02：bootstrap 依赖 + RSA 密钥契约 + SecurityConfig 白名单缺陷）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
