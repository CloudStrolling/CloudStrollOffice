# 接口设计文档（API）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**编写人**：TL

## 0. 版本变更说明（v0.2.7）

**本版本（v0.2.7）无新增接口、无接口变更、无接口删除。**

v0.2.7 为"部署脚本体系重构与仓库清洁度治理"工程版本（需求来源：用户输入——检查并重构 `deploy\scripts` 目录下所有脚本，实现环境可用性检查、基础设施一键启动、后端服务按序一键启动三大能力，并治理 `.gitignore` 排除临时/中间文件），变更范围如下（详见 PRD v0.2.7 与 SAD v0.2.7 ADR-016）：
- **F-001 env.json 配置加载统一**：新增 `load-env.ps1` / `load-env.sh` 统一从 `deploy/env.json` 加载环境配置（NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*/RSA 密钥等），脚本内不硬编码环境地址与凭据；
- **F-002~F-005 环境可用性检查**：`deploy-check-env.ps1` / `.sh` 基于 env.json 检查 JDK（命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程 + SELECT 1）、Redis（命令/服务/进程 + redis-cli ping）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测）可用性；
- **F-006~F-007 基础设施运行状态检查与一键启动**：`deploy-start-services.ps1` / `.sh` 检测未运行的 MariaDB/Redis/Nacos 并自动启动（系统服务优先，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认；
- **F-008~F-009 后端服务按序一键启动**：`deploy-start-all.ps1` / `.sh` 按 gateway → auth → biz → system 顺序一键启动 4 个后端服务，逐服务健康确认；单服务启动脚本（deploy-start-gateway/auth/biz/system）保持可用；
- **F-010~F-011 脚本契约与输出规范**：移除硬编码默认地址与弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1），.sh 与 .ps1 密钥输出契约对齐（DER 单行 Base64，不破坏 ADR-015），输出分级（通过/警告/失败）与退出码约定（失败非零）统一；
- **F-012 .gitignore 临时/中间文件治理**：在 `.gitignore` 中补充生成、测试、调试过程中的临时/中间文件排除规则（JVM 调试产物、测试缓存、构建中间产物、工具残留等）。

以上变更均为**部署运维层脚本重构与仓库治理类工作**，**不触碰接口层（Controller/DTO/响应体）**，对外接口契约 **API-001~API-033 完整保留，客户端运行时代码零改动**（PRD v0.2.7 第 6 章数据需求明确：不新增业务数据表、不修改既有表结构；SAD ADR-016 明确：仅涉及部署运维层，不改变后端架构、接口契约与数据库设计）。本版本接口设计完全沿用主文档 `docs/cso-api.md`（v0.0.1 基线，v0.2.5 / v0.2.6 确认无变更后继续沿用）。

## 1. 接口清单

> 沿用主文档 `docs/cso-api.md`（v0.0.1）第 1 章接口清单，本版本无新增/变更/删除，共 **33 个接口**。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-001 | 用户登录 | POST | /api/v1/auth/login | 4 种登录模式（用户名密码/手机验证码/OAuth），签发双 Token | 白名单 |
| API-002 | 用户注册 | POST | /api/v1/auth/register | 5 种注册策略，返回用户信息与双 Token | 白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换，旧 Token 入黑名单 | 白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | Token 入黑名单并清除登录态，幂等 | 需认证 |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员踢指定端或所有端 | 需认证 |
| API-006 | 修改密码 | PUT | /api/v1/auth/password/change | 校验旧密码，成功后清除全部登录态 | 需认证 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 手机短信或邮箱发送重置验证码 | 白名单 |
| API-008 | 密码找回-重置密码 | POST | /api/v1/auth/password/forgot/reset | 校验验证码后重置密码 | 白名单 |
| API-009 | 修改手机号 | PUT | /api/v1/auth/phone/change | 原手机短信验证码或邮箱验证码校验 | 需认证 |
| API-010 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全登录名/密码/手机号 | 需认证 |
| API-011 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 注册/登录/重置密码/换绑手机用途，60 秒限频 | 白名单 |
| API-012 | 认证服务健康检查 | GET | /api/v1/auth/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-013 | 分页查询用户列表 | GET | /api/v1/auth/users | 按租户分页，支持关键字模糊搜索 | 需认证 |
| API-014 | 获取用户详情 | GET | /api/v1/auth/users/{id} | 返回用户信息及角色编码列表 | 需认证 |
| API-015 | 更新用户信息 | PUT | /api/v1/auth/users/{id} | 更新姓名/手机号/邮箱（不含密码） | 需认证 |
| API-016 | 逻辑删除用户 | DELETE | /api/v1/auth/users/{id} | 标记 deleted=1 | 需认证 |
| API-017 | 分配用户角色 | PUT | /api/v1/auth/users/{id}/roles | 全量更新（先删后插） | 需认证 |
| API-018 | 变更用户状态 | PUT | /api/v1/auth/users/{id}/status | 0-正常/1-停用/2-锁定/3-封禁 | 需认证 |
| API-019 | 分页查询角色列表 | GET | /api/v1/auth/roles | 按租户分页 | 需认证 |
| API-020 | 查询所有角色 | GET | /api/v1/auth/roles/list | 按租户查询，不分页 | 需认证 |
| API-021 | 获取角色详情 | GET | /api/v1/auth/roles/{id} | 按 ID 查询角色 | 需认证 |
| API-022 | 创建角色 | POST | /api/v1/auth/roles | 角色编码租户内唯一 | 需认证 |
| API-023 | 更新角色 | PUT | /api/v1/auth/roles/{id} | 更新角色信息 | 需认证 |
| API-024 | 删除角色 | DELETE | /api/v1/auth/roles/{id} | 已被用户分配则阻止删除 | 需认证 |
| API-025 | 分配角色权限 | PUT | /api/v1/auth/roles/{id}/permissions | 全量更新权限关联（先删后插） | 需认证 |
| API-026 | 树形权限列表 | GET | /api/v1/auth/permissions/tree | 按 parentId 自关联树形结构 | 需认证 |
| API-027 | 所有权限列表 | GET | /api/v1/auth/permissions/list | 平铺列表 | 需认证 |
| API-028 | 获取权限详情 | GET | /api/v1/auth/permissions/{id} | 按 ID 查询权限 | 需认证 |
| API-029 | 创建权限 | POST | /api/v1/auth/permissions | permCode 全局唯一，返回 201 | 需认证 |
| API-030 | 更新权限 | PUT | /api/v1/auth/permissions/{id} | 更新权限信息 | 需认证 |
| API-031 | 删除权限 | DELETE | /api/v1/auth/permissions/{id} | 已被角色关联则阻止删除 | 需认证 |
| API-032 | 企业服务健康检查 | GET | /api/v1/biz/health | 企业服务骨架探活 | 需认证（见备注） |
| API-033 | 系统服务健康检查 | GET | /api/v1/system/health | 系统服务骨架探活 | 需认证（见备注） |

> 备注：当前网关白名单仅配置了 `/api/v1/auth/health`（API-012）；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入白名单，直连服务端口可免认证访问，经网关访问需携带有效 Token（后续版本可将其加入白名单，与 PRD 目标对齐）。本版本维持该现状，不做变更。

## 2. 接口版本策略

沿用主文档 `docs/cso-api.md`（v0.0.1）第 2 章，本版本无变更：
- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`v1` 为 API 主版本号。
- **网关路由**：`/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）、`/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）、`/api/v1/system/**` → `cloudoffice-system-service`（:9400）。
- **兼容策略**：v1 内保持向后兼容；本版本无任何端点新增、删除或语义变更，契约 API-001~API-033 完整保留。
- **在线文档**：SpringDoc OpenAPI 3 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行）。

## 3. 认证鉴权机制

沿用主文档 `docs/cso-api.md`（v0.0.1）第 3 章，本版本无变更：
- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制（Access 2h + Refresh 7d，刷新轮换防重放）。
- **Token 传递**：`Authorization: Bearer {accessToken}` 请求头传递。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）。
- **白名单端点**：`/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **v0.2.7 特别说明（脚本契约）**：本版本重构部署脚本体系，`deploy-start-all` / `deploy-start-{svc}` 启动后端服务后通过 HTTP 探测健康检查接口（如 `/api/v1/auth/health`）确认服务就绪；脚本仅调用既有健康检查接口做部署确认，**不新增、不修改任何认证鉴权机制与接口请求/响应契约**，客户端无需任何修改。

## 4. 通用错误码定义

沿用主文档 `docs/cso-api.md`（v0.0.1）第 4 章，本版本无变更：
- 统一响应体 `ApiResult<T>`（code/message/data/timestamp），错误码枚举定义于 `cloudoffice-common` 的 `ErrorCode`。

### 4.1 基础错误码（HTTP 状态码映射）
| 错误码 | 说明 |
| --- | --- |
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，请先登录 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 405 | 请求方法不支持 |
| 409 | 资源冲突 |
| 429 | 请求频率过高 |
| 500 | 系统繁忙，请稍后重试 |
| 503 | 服务暂不可用 |

### 4.2 认证授权错误码（业务编码 AUTH-XXXX，共 23 个）
| 业务编码 | 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌 |
| AUTH-0002 | 401 | 令牌无效 |
| AUTH-0003 | 401 | 令牌已被吊销 |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 401 | 刷新令牌无效 |
| AUTH-0006 | 403 | 账号已被禁用 |
| AUTH-0007 | 403 | 账号已被锁定 |
| AUTH-0008 | 403 | 账号已被封禁 |
| AUTH-0009 | 403 | 账号已过期 |
| AUTH-0010 | 401 | 用户名或密码错误 |
| AUTH-0011 | 400 | 验证码错误 |
| AUTH-0012 | 400 | 无效的客户端类型 |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线 |
| AUTH-0014 | 403 | 租户已被禁用 |
| AUTH-0015 | 403 | 租户已过期 |
| AUTH-0016 | 403 | 权限不足 |
| AUTH-0017 | 404 | 角色不存在 |
| AUTH-0018 | 404 | 用户不存在 |
| AUTH-0019 | 400 | 验证码已过期 |
| AUTH-0020 | 400 | 密码重置令牌无效 |
| AUTH-0021 | 400 | 密码重置令牌已过期 |
| AUTH-0022 | 409 | 用户名已存在 |
| AUTH-0023 | 409 | 手机号已被注册 |

## 5. 接口详细定义

**本版本（v0.2.7）无新增接口**，API-001~API-033 的接口详细定义（请求头/请求参数/请求示例/响应参数/响应示例/错误码）**完全沿用主文档 `docs/cso-api.md`（v0.0.1）第 5 章**，本版本不做重复编写与任何变更。

## 6. 状态码映射

沿用主文档 `docs/cso-api.md`（v0.0.1）第 6 章，本版本无变更：
- HTTP 状态码与业务错误码映射关系保持不变（200/400/401/403/404/405/409/429/500/503 + AUTH-0001~0023）。

## 7. 限流策略

沿用主文档 `docs/cso-api.md`（v0.0.1）第 7 章，本版本无变更：
- 验证码发送类接口（API-007/API-011）60 秒发送频率限制、5 分钟有效期、错误次数限制防暴力尝试；
- 其余接口按业务规则限流，本版本不引入网关 RequestRateLimiter（规划后续版本）。

## 8. 示例代码

沿用主文档 `docs/cso-api.md`（v0.0.1）第 8 章示例代码（curl/Java/Flutter dio 调用示例），本版本无变更。

---

**契约一致性说明（v0.2.7）**：本版本变更范围严格限定于部署运维层脚本重构（load-env / deploy-check-env / deploy-start-services / deploy-start-all / deploy-start-{svc} / deploy-rsa-keygen 双平台对齐）与仓库治理（.gitignore 补充临时/中间文件排除规则），未触碰任何 Controller/DTO/响应体；API 契约 API-001~API-033 经本文档与主文档逐项核对静态确认无变更，动态回归由 v0.2.7 回归测试（既有接口回归）进一步确认无回归。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
