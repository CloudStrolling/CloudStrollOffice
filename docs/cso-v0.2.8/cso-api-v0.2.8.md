# 接口设计文档（API）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**编写人**：TL

## 0. 版本变更说明（v0.2.8）

**本版本（v0.2.8）新增接口 3 个（API-034~API-036），无接口变更、无接口删除。**

v0.2.8 为"cloudoffice-common 服务化改造与通用配置管理接口先行"版本（需求来源：URS v0.2.8 / PRD v0.2.8 / SAD v0.2.8 ADR-017/ADR-018/ADR-019），接口变更范围如下：

- **新增 common 服务健康检查接口（API-034）**：cloudoffice-common 服务化后提供与其他微服务一致的健康检查端点 `GET /api/v1/common/health`（白名单放行），供部署脚本（deploy-start-all）与监控探活；
- **新增通用配置管理查询接口（API-035 / API-036）**：在 cloudoffice-common 中新增通用配置管理查询接口 `GET /api/v1/common/config`（条件过滤 + 分页）与 `GET /api/v1/common/config/{serviceName}`（按微服务名称查询），统一管理 gateway/auth-service/biz-service/system-service/common 五个微服务在不同业务场景下的所有运行时配置（启动环境变量除外）；
- **网关路由扩展**：网关新增 `/api/v1/common/**` → `lb://cloudoffice-common`（Nacos 服务发现负载均衡）路由规则，使 common 健康检查与配置查询请求可经网关转发；
- **网关白名单扩展**：`/api/v1/common/health` 加入网关 AuthFilter 白名单（无 Token 访问）；`/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` 不在白名单中，需经 AuthFilter 认证（携带合法 Bearer Token）。

以上变更**仅新增接口与网关路由/白名单配置**，**不修改**既有 API-001~API-033 的接口契约；既有 33 个接口（认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个）完整保留，客户端运行时代码零改动。本版本接口设计在沿用主文档 `docs/cso-api.md`（v0.0.1 基线）的基础上追加 common 服务接口。

> 配置数据存储结构（`t_common_config` 表）详见 DBD v0.2.8（`docs/cso-v0.2.8/cso-dbd-v0.2.8.md` 第 5.2.1 节），本接口文档中的配置项字段（ConfigItemVO）与之一一对应。

## 1. 接口清单

> 本版本共 **新增 3 个接口**，累计 **36 个接口**（API-001~API-036）。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

本版本新增接口：

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-034 | common 服务健康检查 | GET | /api/v1/common/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-035 | 通用配置管理-查询配置列表 | GET | /api/v1/common/config | 按 serviceName/group/key 过滤查询配置项，支持分页 | 需认证 |
| API-036 | 通用配置管理-按微服务查询配置 | GET | /api/v1/common/config/{serviceName} | 按微服务名称查询该服务全部配置项（不分页） | 需认证 |

> 既有接口 API-001~API-033（认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个）沿用主文档 `docs/cso-api.md`（v0.0.1 基线），本版本无变更，此处不重复列出。

## 2. 接口版本策略

沿用主文档（v0.0.1）策略，本版本扩展 common 模块路由：

- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`{module}` 为业务模块标识（auth/biz/system/common），`v1` 为 API 主版本号。
- **网关路由**：Spring Cloud Gateway 通过 Nacos 服务发现路由：
  - `/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）
  - `/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）
  - `/api/v1/system/**` → `cloudoffice-system-service`（:9400）
  - `/api/v1/common/**` → `cloudoffice-common`（:9300，**v0.2.8 新增**）
- **兼容策略**：v1 内保持向后兼容，新功能只允许新增端点与可选字段，禁止修改既有端点语义；本版本仅新增 common 模块端点，既有端点语义不变，契约 API-001~API-033 完整保留。
- **在线文档**：各服务通过 SpringDoc OpenAPI 3 生成 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行），按模块分组在线调试；common 服务新增文档分组 `common`（v0.2.8 新增）。

## 3. 认证鉴权机制

沿用主文档（v0.0.1）第 3 章机制，本版本扩展 common 模块端点：

- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制（Access 2h + Refresh 7d，刷新轮换防重放）。
- **Token 传递**：`Authorization: Bearer {accessToken}` 请求头传递。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验（必须为 access）→ Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → 用户信息 Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）。
- **白名单端点（无需认证，网关直接放行）**：在既有白名单基础上，**v0.2.8 新增** `/api/v1/common/health`：
  `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/api/v1/common/health`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **通用配置查询认证要求（v0.2.8 新增）**：`/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` **不在白名单中**，需经网关 AuthFilter 认证，调用方需携带合法 Bearer Token；未携带或 Token 无效由网关返回 401/403 错误响应。
- **Header 透传**：认证通过后网关向下游服务透传 `X-User-Id`、`X-Tenant-Id`、`X-User-Name`、`X-Client-Type`、`X-Roles`、`X-Permissions`（字段说明同主文档第 3 章）。
- **角色权限**：本版本 RBAC 接口级权限点校验（鉴权注解）随业务版本演进；通用配置查询接口本版本不设接口级权限点校验，后续增删改接口与后端管理界面迭代时补充。

## 4. 通用错误码定义

沿用主文档（v0.0.1）统一错误码体系，本版本**不新增业务错误码**，通用配置查询接口复用基础错误码与既有认证授权错误码。

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

### 4.2 认证授权错误码（业务编码 AUTH-XXXX，沿用 v0.0.1 共 23 个）
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
| AUTH-0022 | 400 | 原密码错误 |
| AUTH-0023 | 400 | 短信验证码无效 |
| AUTH-0024 | 400 | 短信验证码已过期 |
| AUTH-0025 | 429 | 验证码发送过于频繁 |
| AUTH-0026 | 401 | 第三方登录失败 |
| AUTH-0027 | 404 | 第三方账号未绑定 |
| AUTH-0028 | 409 | 手机号已被其他账号绑定 |
| AUTH-0029 | 409 | 第三方账号已被其他用户绑定 |
| AUTH-0030 | 403 | 需要邮箱验证 |
| AUTH-0031 | 403 | 账号信息未完善，请先补充资料 |
| AUTH-0032 | 400 | 无效的注册模式 |
| AUTH-0033 | 400 | 无效的登录模式 |

### 4.3 统一分页结构 PageResult<T>
```json
{ "records": [], "total": 0, "page": 1, "pageSize": 10 }
```

> 说明：通用配置查询接口不引入独立错误码段；当 `serviceName` 不在合法取值（gateway/auth-service/biz-service/system-service/common）范围内时返回 400（请求参数错误）；配置数据存储异常时返回 500（系统繁忙）；查询结果为空时返回 `code=200` 且 `data.records` 为空列表（非 500 错误）。

## 5. 接口详细定义

### 5.1 common 服务健康检查（API-034）
**接口**：`GET /api/v1/common/health`（白名单，无需认证）
**功能描述**：返回 common 服务运行状态、服务名、版本与时间戳，供部署脚本与监控探活。deploy-start-all 脚本启动 common 服务后经该端点做健康确认（HTTP 探测返回 200 视为就绪）。
**请求头**：无。
**请求参数**：无。
**请求示例**：`GET /api/v1/common/health`
**响应参数**（data 为 Map）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| service | string | 服务名（cloudoffice-common） |
| status | string | 状态（UP） |
| version | string | 版本号 |
| timestamp | string | 时间戳（ISO 格式） |
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-common",
    "status": "UP",
    "version": "0.2.8-SNAPSHOT",
    "timestamp": "2026-08-13T08:00:00.000Z"
  },
  "timestamp": 1723000000000
}
```
**错误码**：500（服务异常）、503（服务不可用）

### 5.2 通用配置管理-查询配置列表（API-035）
**接口**：`GET /api/v1/common/config`（需认证，非白名单）
**功能描述**：查询各微服务（gateway/auth-service/biz-service/system-service/common）的运行时配置项，支持按微服务名称（serviceName）、配置分组（group）、配置键（key）过滤与分页查询。配置查询优先命中 Redis 本地缓存（命中时响应 ≤ 50ms），缓存未命中时回源数据库（`t_common_config`）查询并回填缓存；敏感配置项（sensitive=1）在返回时脱敏处理，不暴露明文。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**（query）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| serviceName | string | 否 | query | 微服务名称（gateway/auth-service/biz-service/system-service/common），不传返回全部微服务配置 |
| group | string | 否 | query | 配置分组（业务场景分组，如 security/verification/password/token 等） |
| key | string | 否 | query | 配置键（精确匹配） |
| page | int | 否 | query | 页码（从 1 开始，默认 1） |
| pageSize | int | 否 | query | 每页条数（默认 10） |
**请求示例**：
```
GET /api/v1/common/config?serviceName=gateway&group=security&page=1&pageSize=10
```
**响应参数**（data 为 PageResult\<ConfigItemVO\>）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| records | array | 配置项列表（字段见下方 ConfigItemVO 说明） |
| total | long | 总记录数 |
| page | int | 当前页码 |
| pageSize | int | 每页大小 |
**ConfigItemVO 关键字段**：id（配置项 ID，long）、serviceName（微服务名称，string）、group（配置分组，string）、key（配置键，string）、value（配置值，string；敏感配置脱敏为掩码）、dataType（数据类型，string/number/boolean/json）、description（配置描述，string）、sensitive（是否敏感，boolean）、status（状态，0-启用/1-禁用）、createTime（创建时间，string）、updateTime（更新时间，string）
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1001,
        "serviceName": "auth-service",
        "group": "verification",
        "key": "code-length",
        "value": "6",
        "dataType": "number",
        "description": "验证码长度（位数）",
        "sensitive": false,
        "status": 0,
        "createTime": "2026-08-13T10:00:00",
        "updateTime": "2026-08-13T10:00:00"
      },
      {
        "id": 1002,
        "serviceName": "auth-service",
        "group": "token",
        "key": "sign-secret",
        "value": "****",
        "dataType": "string",
        "description": "令牌签名密钥（敏感）",
        "sensitive": true,
        "status": 0,
        "createTime": "2026-08-13T10:00:00",
        "updateTime": "2026-08-13T10:00:00"
      }
    ],
    "total": 2,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误，serviceName 取值非法）、401（未授权/Token 无效）、500（配置存储异常）

### 5.3 通用配置管理-按微服务查询配置（API-036）
**接口**：`GET /api/v1/common/config/{serviceName}`（需认证，非白名单）
**功能描述**：按微服务名称查询该微服务的全部运行时配置项（不分页）。缓存与脱敏策略同 API-035；指定微服务无配置项时返回空列表（`code=200`，非 500 错误）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**（path）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| serviceName | string | 是 | path | 微服务名称（gateway/auth-service/biz-service/system-service/common） |
**请求示例**：`GET /api/v1/common/config/auth-service`
**响应参数**：data 为 ConfigItemVO 数组（字段同 API-035）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1001,
      "serviceName": "auth-service",
      "group": "verification",
      "key": "code-length",
      "value": "6",
      "dataType": "number",
      "description": "验证码长度（位数）",
      "sensitive": false,
      "status": 0,
      "createTime": "2026-08-13T10:00:00",
      "updateTime": "2026-08-13T10:00:00"
    }
  ],
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误，serviceName 取值非法）、401（未授权/Token 无效）、500（配置存储异常）

## 6. 状态码映射

沿用主文档（v0.0.1）第 6 章，本版本补充 common 模块接口的状态码映射：

| HTTP 状态码 | 业务码 | 场景 |
| --- | --- | --- |
| 200 | 200 | 成功（含通用配置查询返回空列表） |
| 201 | 200 | 创建权限成功（@ResponseStatus CREATED，body 内 code 仍为 200） |
| 400 | 400 / AUTH-0011 / AUTH-0012 / AUTH-0019 / AUTH-0020 / AUTH-0021 / AUTH-0022 / AUTH-0023 / AUTH-0024 / AUTH-0032 / AUTH-0033 | 参数校验失败（含 serviceName 取值非法）、验证码错误/过期、模式无效、原密码错误等 |
| 401 | 401 / AUTH-0001~0005 / AUTH-0010 / AUTH-0013 / AUTH-0026 | 未认证、Token 过期/无效/黑名单、凭据错误、被踢下线 |
| 403 | 403 / AUTH-0006~0009 / AUTH-0014 / AUTH-0015 / AUTH-0016 / AUTH-0030 / AUTH-0031 | 账号/租户状态异常、权限不足、需邮箱验证、账号未完善 |
| 404 | 404 / AUTH-0017 / AUTH-0018 / AUTH-0027 | 用户/角色/资源不存在、第三方账号未绑定 |
| 409 | 409 / AUTH-0028 / AUTH-0029 | 手机号/第三方账号已绑定、资源冲突（编码重复、关联阻止删除） |
| 429 | 429 / AUTH-0025 | 验证码发送过于频繁 |
| 500 | 500 | 系统内部错误（含配置存储异常，全局兜底，不泄露堆栈） |
| 503 | 503 | 服务暂不可用 |

## 7. 限流策略

- **验证码发送限频（沿用）**：同一目标（手机号/邮箱）60 秒内禁止重复发送，超限返回 AUTH-0025（429）；验证码有效期 5 分钟，一次性失效。
- **通用配置查询接口（v0.2.8 新增）**：配置查询以 Redis 本地缓存命中为主（命中响应 ≤ 50ms），为低频读操作，本版本不设接口级独立限流；查询接口经网关 AuthFilter 认证后放行，无特殊频率约束。
- **网关级限流（沿用）**：本版本网关未配置 RequestRateLimiter 限流器；后续版本引入 Spring Cloud Gateway RequestRateLimiter 对登录/验证码等敏感端点按 IP/用户限流。
- **登录失败策略（沿用）**：登录失败统一返回 AUTH-0010（用户名或密码错误），不泄露具体原因，防账号枚举；失败事件记录登录日志供审计。

## 8. 示例代码

### 8.1 通用配置查询 curl 调用示例（v0.2.8 新增）
```bash
# 1. 登录获取 Token
curl -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginMode":"USERNAME_PASSWORD","loginName":"admin","password":"password123","tenantCode":"default","clientType":"WINDOWS"}'

# 2. 携带 Token 查询全部微服务运行时配置（分页）
curl -X GET "http://localhost:9000/api/v1/common/config?page=1&pageSize=10" \
  -H "Authorization: Bearer {accessToken}"

# 3. 携带 Token 按微服务名称+分组过滤查询配置
curl -X GET "http://localhost:9000/api/v1/common/config?serviceName=gateway&group=security" \
  -H "Authorization: Bearer {accessToken}"

# 4. 携带 Token 按微服务名称查询该服务全部配置
curl -X GET "http://localhost:9000/api/v1/common/config/auth-service" \
  -H "Authorization: Bearer {accessToken}"

# 5. 健康检查（白名单，无需 Token）
curl -X GET "http://localhost:9000/api/v1/common/health"
```

### 8.2 通用配置查询 Java 调用示例（v0.2.8 新增）
```java
// 通过网关访问 common 配置查询接口，携带 Bearer Token
RestTemplate restTemplate = new RestTemplate();
HttpHeaders headers = new HttpHeaders();
headers.set("Authorization", "Bearer " + accessToken);
HttpEntity<Void> entity = new HttpEntity<>(headers);

// 按条件查询配置列表（分页）
ResponseEntity<String> resp = restTemplate.exchange(
    "http://localhost:9000/api/v1/common/config?serviceName=auth-service&page=1&pageSize=10",
    HttpMethod.GET, entity, String.class);
System.out.println(resp.getBody());
```

### 8.3 错误响应示例（网关拦截 401）
```json
{ "code": 401, "message": "令牌已过期，请刷新令牌", "data": null, "timestamp": 1723000000000 }
```

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
