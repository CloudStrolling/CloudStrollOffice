# 网络查询结果（TASK-004：补跑 v0.0.1 基线接口回归并闭环）

## 1. 任务要点回顾

- **任务**：修复 auth-service `SecurityConfig.java` permitAll 白名单缺失（login/register/refresh 三端点），重新构建重启后执行 `python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`，使 TC-001~045（API-001~API-033）全部动态通过（PASS=45、FAIL=0、退出码 0），闭环 v0.0.1 基线遗留项 T-02。
- **涉及三方组件**：Spring Security 6.x（auth-service 安全过滤链）、Spring Cloud Gateway（网关转发与下游联动）、Python requests（回归脚本）、pymysql（验证码读取，可选）。
- **现状确认**（已读源码）：`SecurityConfig.java` 第 60~61 行已正确关闭 CSRF（`.csrf(AbstractHttpConfigurer::disable)`）并设置无状态会话（`SessionCreationPolicy.STATELESS`）；第 62~68 行 permitAll 仅含 5 组端点，缺少 `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`。

## 2. Spring Security 6.x：authorizeHttpRequests 与 permitAll 正确配置方式

### 2.1 官方配置范式（lambda DSL，Spring Security 6.x 唯一推荐写法）

官方文档（Spring Security Reference 6.x，`servlet/authorization/authorize-http-requests`）确认：

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(AbstractHttpConfigurer::disable)
        .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests((authorize) -> authorize
            .requestMatchers("/api/v1/auth/login").permitAll()
            .requestMatchers("/api/v1/auth/register").permitAll()
            .requestMatchers("/api/v1/auth/refresh").permitAll()
            .anyRequest().authenticated()
        )
        .build();
}
```

要点：
1. **lambda DSL（`authorizeHttpRequests(auth -> ...)`）是 5.8+ / 6.x 标准写法**，旧版 `authorizeRequests()` 已废弃移除；项目现有写法（第 62 行）完全正确，无需改写。
2. **匹配顺序即优先级**：`AuthorizationFilter` 对请求应用**第一条匹配**的规则；`anyRequest()` 必须放在**最后**兜底（项目现状正确）。官方文档明确警告：若先写 `requestMatchers("/**")` 会吞掉后续所有规则（Invalid Request Matcher Order 示例）。
3. **多个路径可合并**：`requestMatchers("/a", "/b")` 等价于分开写两条规则（项目第 67 行 `/swagger-ui/**`, `/v3/api-docs/**` 即此用法）；修复时可新增一行 `.requestMatchers("/api/v1/auth/login", "/api/v1/auth/register", "/api/v1/auth/refresh").permitAll()`，或按项目风格分三行，二者等价。
4. **Ant 风格路径匹配**：`/api/v1/auth/login` 为精确路径；`/**` 为通配。permitAll 只放行授权规则，不绕过认证过滤器链中的其他环节。

### 2.2 CSRF 与无状态会话（本项目已正确处理，无需改动）

- 官方文档确认：**Spring Security 默认开启 CSRF**，对 POST/PUT/DELETE 等非安全方法默认拦截返回 403。本项目 auth-service 已在第 60 行 `csrf(AbstractHttpConfigurer::disable)` 关闭，**无需修改**——回归脚本大量 POST 用例（TC-001~011、019~026、034、037、039 等）不会遇到 403 陷阱。
- 无状态会话（第 61 行）与 JWT 双 Token 方案匹配，无 session 依赖，回归脚本无需处理 Cookie。

### 2.3 版本兼容性结论（重要）

| 项目 | 项目实际版本 | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Spring Boot | 3.2.5 | 3.2.x | 内置 Spring Security 6.2.x |
| Spring Security | 6.2.x（随 Boot 3.2.5） | 官方 Reference 6.5 / 6.x 系列 | **兼容**：authorizeHttpRequests lambda DSL、permitAll、requestMatchers、csrf disable 等 API 自 6.0 稳定，6.2 与 6.5 写法一致 |
| 真实样例佐证 | GitHub m42hub/m42hub-api（Spring Boot 3 + Security 6） | `.requestMatchers("/api/v1/auth/login").permitAll()` 逐行写法 | 与项目现有 SecurityConfig 第 63 行风格完全一致 |

> 结论：修复只需在现有 `authorizeHttpRequests` 块内增补 3 个端点的 `permitAll()`（按项目风格逐行书写），不涉及 DSL 升级、不触碰 CSRF/会话配置、不改动接口层契约，符合 F-005 修复约束。

## 3. Spring Cloud Gateway 与下游服务 Security 联动

### 3.1 联动机制（官方文档确认）

- 网关（WebFlux + Spring Cloud Gateway）只做**请求转发**：匹配路由 → 执行 Global/局部过滤器（鉴权、透传头）→ 转发至下游服务。下游 auth-service 是普通 Spring Boot MVC 应用，**独立执行自身 SecurityFilterChain**。
- 官方文档 `AddRequestHeader`/`SetRequestHeader` GatewayFilter 与自定义 GlobalFilter（developer-guide）确认：网关可在转发前给请求**添加/覆写 HTTP 头**，下游服务从 `HttpServletRequest` 头部读取透传信息。本项目 AuthFilter 透传 `X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions` 即官方推荐模式。
- 版本兼容性：项目 Spring Cloud 2023.0.1 → Spring Cloud Gateway 4.1.x；查询的官方 Reference 4.3 文档的过滤器/路由机制与 4.1 一致（全局过滤器 API、路由谓词、Header 过滤器均为长期稳定 API）。

### 3.2 白名单两层校验原则（本任务排障关键）

- **网关层**：`auth.white-list`（application.yml 第 50~61 行）放行后直接转发，**不再校验 JWT**；已正确包含 login/register/refresh/health/验证码/密码找回/OpenAPI，无需修改。
- **下游服务层**：auth-service 的 Spring Security 对收到的每个请求**独立执行自身过滤链**。网关放行 ≠ 下游放行——请求经网关转发到 auth-service 后，仍会被 SecurityConfig 的 `anyRequest().authenticated()` 拦截返回 401。**这就是缺陷 1 的根因机制**。
- **修复原则**：下游 permitAll 白名单必须与网关 white-list、API 文档白名单契约保持一致（三层一致）。TC-043 直连 auth-service（不经网关）时，白名单端点同样可匿名访问，其余端点因缺 `X-User-Id` 头被 401 拒绝——符合预期（`getCurrentUserId()` 缺失抛 UNAUTHORIZED）。

### 3.3 下游服务透传头校验注意

- 需认证接口依赖网关透传的 `X-User-Id` 等头；TC-043 验证"直连认证服务缺少租户头被拒"即依赖此设计，**不应**在 auth-service 做兜底放行。

## 4. Python requests 回归脚本最佳实践

### 4.1 安装与基础用法（官方文档确认）

```console
$ python -m pip install requests   # 官方推荐安装方式，requests 2.x
```

| 最佳实践 | 官方写法 | 与本项目脚本的关系 |
| --- | --- | --- |
| 统一请求封装 | `requests.request(method, url, json=..., headers=..., timeout=...)` | 脚本 `req()` 封装（cs.md 第 88 行）已采用 |
| 超时控制 | `requests.get(url, timeout=3)`；超时抛 `requests.exceptions.Timeout` | 建议脚本给每请求设置 timeout，避免服务假死时挂死 |
| 状态码断言 | `r.status_code == requests.codes.ok`（即 200） | 脚本 `api_ok()` 断言 HTTP 200 且 body.code==200，与 ApiResult 契约一致 |
| 抛错检查 | `r.raise_for_status()` 对 4xx/5xx 抛 HTTPError | 断言业务 code 时用 ApiResult.code 而非 raise_for_status（本项目 401 也返回 JSON body，需按 body.code 判断） |
| Session 复用 | `with requests.Session() as s:` 自动管理连接池/Cookie | 脚本为无状态 JWT 接口，逐请求携带 Authorization 头，无需 Session 持久化 |

### 4.2 连接拒绝崩溃根因与处理（与历史"环境阻塞"直接相关）

- **根因确认（官方源码行为）**：requests 在连接拒绝/网络不可达时抛 `requests.exceptions.ConnectionError`；重试耗尽（MaxRetryError）时最终 fallback 为 `ConnectionError`（requests/adapters.py 官方源码确认）。**v0.2.5 回归"脚本在 admin 登录步骤崩溃、退出码 1"即此异常未被捕获**。
- **处理建议**：脚本顶层/`req()` 内捕获 `requests.exceptions.RequestException`（ConnectionError/Timeout 等统一父类），打印明确错误信息后按用例标记 FAIL 或直接退出并返回退出码 1——保证"脚本正常跑完"而非崩溃。TASK-004 执行时服务已可用（TASK-003 验证），该异常不应再出现，但捕获逻辑可增强健壮性。
- **退出码约定**：官方及社区惯例 `sys.exit(0)` = 全部通过，`sys.exit(1)` = 存在失败；脚本已实现该约定（cs.md 第 2.1 节），验收标准"退出码 0"即据此。

### 4.3 pymysql 可选依赖（验证码闭环）

- 官方文档：`python -m pip install pymysql`；`pymysql.connect(host, port, user, password, database)` 建立连接。
- 作用：脚本 `fetch_code_from_db()` 读取 `t_auth_verification_code` 表最新未用验证码，使 TC-002/007/019/021/022/025 等验证码类用例**动态执行**而非 SKIP。验收要求 PASS=45、FAIL=0 且建议 SKIP=0，故执行环境必须安装 pymysql 并可连库（默认 root/root@127.0.0.1:3306/cloudstroll_office_auth）。

## 5. 验证码模拟机制（业务方案确认）

- **开关**：`app.verification-code.mock=true`（auth-service application.yml 第 62~67 行）→ `SimulatedVerificationCodeService`（`@ConditionalOnProperty`）只 log 不真实发送，验证码仍**落库** `t_auth_verification_code`（`VerificationCodeManagerImpl.generateCode`，6 位随机码 100000~999999）。
- **闭环链路**：脚本调 `/verification-code/send` 触发模拟发送 → 读库取最新未用验证码（`used=0 ORDER BY id DESC LIMIT 1`）→ 携带验证码完成登录/注册/找回 → 服务端校验后置 `used=1`（一次性）。
- **用途约定核对**：注册 `REGISTER`、登录 `LOGIN`、换绑 `CHANGE_PHONE` 直传；密码找回脚本传 `RESET_PASSWORD`，服务端 `PasswordService` 内部转 `RESET_PWD` 落库，脚本按 `RESET_PWD` 读取——已核对一致，无需改动。
- **限频注意**：TC-020 依赖 Redis 频率键（60s 间隔），脚本用独立新手机号，正常通过；若重跑遇 429，换新测试数据即可。

## 6. 查询结论与修复建议（供编码阶段使用）

1. **修复方案（唯一必须改动）**：`SecurityConfig.java` 第 62~68 行 `authorizeHttpRequests` 块内增补 3 端点 permitAll（按项目逐行风格）：
   ```java
   .requestMatchers("/api/v1/auth/login").permitAll()
   .requestMatchers("/api/v1/auth/register").permitAll()
   .requestMatchers("/api/v1/auth/refresh").permitAll()
   ```
   必须插在 `.anyRequest().authenticated()` **之前**；不得删除既有 permitAll；不得改动 CSRF/会话/异常处理配置与接口层代码。
2. **无需改动**：网关 white-list（已放行三端点）、CSRF（已关闭）、会话（已 STATELESS）、验证码机制（mock 落库已闭环）、回归脚本（契约已对齐）。
3. **回归执行前置**：确保 `python -m pip install requests pymysql`；4 服务健康检查通过（TASK-003）；执行 `python scripts/API-TEST/cso-api-test-v0.0.1.py http://localhost:9000`。
4. **验收核对**：退出码 0、PASS=45、FAIL=0、SKIP=0（安装 pymysql 后验证码类用例动态执行）；结果与 T-02 闭环说明（bootstrap 依赖 + RSA 密钥契约 + SecurityConfig 白名单缺陷）写入 `docs/cso-v0.2.6/regression-api-test.md`。

## 7. 资料清单与版本兼容性总结

| 资料 | 来源（权威性） | 版本说明 | 兼容性 |
| --- | --- | --- | --- |
| Spring Security Reference 6.5 — authorizeHttpRequests / permitAll / matcher 顺序 | docs.spring.io（官方，High） | 6.5 参考文档 | 与项目 6.2.x 兼容（DSL 自 6.0 稳定） |
| Spring Security Reference — CSRF 默认开启与禁用（servlet） | docs.spring.io（官方） | 6.x | 项目已正确关闭，无需改动 |
| Spring Cloud Gateway Reference 4.3 — GlobalFilter / AddRequestHeader / 路由 | docs.spring.io（官方） | 4.3 参考 | 与项目 4.1.x 机制一致 |
| requests 官方文档（Quickstart / Advanced） | psf/requests（GitHub 官方，High） | 2.x | 与项目脚本依赖一致 |
| requests 源码 adapters.py — ConnectionError 抛出具因 | psf/requests（官方源码） | 2.x | 解释 v0.2.5 脚本崩溃根因 |
| GitHub 生产样例 m42hub/m42hub-api SecurityConfig | GitHub 真实仓库（佐证） | Boot 3 + Security 6 | permitAll 逐行写法与项目一致 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
