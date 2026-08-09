# 代码审核报告
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**审核人**：TL

## 1. 审核范围

本次审核覆盖 v0.2.6 全部代码变更（git 范围 4a8e386..HEAD，TASK-001~TASK-005），变更来源为 docs/cso-v0.2.5/regression-api-test.md 记录的回归问题修复，审核重点包括：

- **构建/依赖配置（5 个 pom.xml）**：根 pom 引入 `spring-cloud-starter-bootstrap` 4.1.2（dependencyManagement），gateway/auth/biz/system 四模块实际引入；gateway pom 排除 common 传递引入的 `spring-boot-starter-web`、`springdoc-openapi-starter-webmvc-ui`、`mybatis-plus-spring-boot3-starter`（消除 WebFlux 与 MVC/DataSource 冲突）。
- **RSA 密钥契约脚本**：deploy/scripts/deploy-rsa-keygen.ps1 输出改为 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo），增加契约自校验（无 PEM 头尾、无换行、严格 Base64、DER 结构偏移校验）与私钥输出脱敏（仅打印 24 字符前缀）。
- **网关配置**：cloudoffice-gateway/src/main/resources/application.yml 白名单增补 `/api/v1/auth/logout`（登出幂等可达）。
- **common 与 auth 契约修复类 Java 文件（13 个）**：SecurityConfig（白名单增补 + `@Import(GlobalExceptionHandler)` + `anyRequest().permitAll()`）、AuthenticationService（clientType 校验、tokenSignature 会话写入、同端互斥黑名单）、LoginServiceImpl（同端互斥黑名单、isAdmin 兼容）、PermissionServiceImpl（权限树 parentId=0、子权限删除检查、409）、RoleServiceImpl（409）、TokenServiceImpl（刷新会话校验、tokenSignature）、UserServiceImpl（409）、PhoneCodeLoginStrategy（验证码用途隔离）、UsernamePasswordStrategy（防账号枚举）、UsernamePwdRegisterStrategy（409）、JwtUtils（tokenVersion、getTokenSignature 改 Base64 URL 无填充）、LoginUserDTO（+tokenSignature 内部字段）、GlobalExceptionHandler（BusinessException 按 code 映射 HTTP 状态、MissingRequestHeaderException→400）。
- **v0.0.1 回归脚本缺陷修复**：scripts/API-TEST/cso-api-test-v0.0.1.py（admin_login 每次重新登录、TC-006 断言对齐、TC-029/030 密码脱敏判定、TC-033~037 tenantId 参数、TC-036 角色 id、TC-039 201 兼容）。
- **测试资产**：cso-api-test-v0.2.6.py（TC-052~076）+ 5 个单元测试 ps1 脚本（UT-097~131）。

审核依据：PRD/LLD/API v0.2.6 文档、v0.2.5 回归报告（T-02 缺陷）、v0.2.6 回归报告（TC-001~051 PASS=72/FAIL=0、单测 PASS=90/FAIL=3）。

## 2. 审核结论

**总体结论：需修改（建议后续版本处理）**。

本版本核心修复目标（bootstrap 依赖、RSA 密钥契约、SecurityConfig 白名单、网关依赖冲突、v0.0.1 回归脚本缺陷）实现正确且经回归验证闭环（全量 API PASS=72/FAIL=0、功能单测断言全 PASS）；但存在 **2 项高危问题**（S-01 认证信任边界后移可致直连越权、A-01 设计文档红线与实际变更范围不一致）与多项中危问题需在后续版本修复。审核意见只输出问题，不修改任何代码。

## 3. 问题清单

### 3.1 安全漏洞（注入、越权、硬编码密钥、敏感信息泄露）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| S-01 | 高危 | cloudoffice-auth-service/.../config/SecurityConfig.java:81；controller/AuthController.java:351-371 | 认证信任边界整体后移至网关：`anyRequest().permitAll()` 放行全部请求，服务内二次认证 `getCurrentUserId()` 仅读取 `X-User-Id` 请求头（缺失才 401），**不校验头来源可信性**（无签名、无网关 IP 白名单）。auth-service application.yml 未配置 `server.address`（默认 0.0.0.0:9100 全网卡绑定）。一旦 9100 端口可从外部网络直达（绕过网关 9000），攻击者可伪造 `X-User-Id: 1`（admin）等头调用踢人、用户管理、角色权限管理等管理接口，实现水平/垂直越权。经网关场景因 AuthFilter 以 JWT claims 覆盖该头（替换语义）而安全，但直连场景失去全部保护。 | ① 部署层面：auth-service 绑定回环/内网地址或防火墙仅放行网关来源（最小化暴露面）；② 网关转发前先 `removeHeader` 客户端传入的 X-User-Id/X-Roles/X-Permissions 等敏感头再覆盖（纵深防御）；③ 服务内二次认证改为校验网关签名头，或在 auth-service 恢复 JWT 解析过滤链（仅验签 + 黑名单/会话校验，避免过度放行）。 |
| S-02 | 中危 | auth/service/AuthenticationService.java:280-306；service/impl/LoginServiceImpl.java:405-430；service/impl/TokenServiceImpl.java:122-127 | 同端互斥不完整：`processMutualExclusion` 仅将旧会话 **Access Token** 签名加入黑名单并删除会话，**旧 Refresh Token 未吊销**；`TokenServiceImpl.refresh` 4.1 会话校验只检查"会话存在"，不校验刷新令牌是否属于当前会话（会话仅存最新 access token 签名）。被踢设备仍可用旧 refresh token 刷新：4.1 通过（新会话存在）→ 刷新成功 → 12 步 removeSession+createSession **覆盖新会话**，新设备被"反踢下线"，同端互斥语义失效。 | ① 会话中同时持久化 refresh token 签名（LoginUserDTO 增加字段），同端互斥/登出时一并加入黑名单；② 或 refresh 时校验会话 `tokenSignature` 与请求携带 access token 的归属关系（签发时绑定），拒绝"非当前会话令牌"的刷新。 |
| S-03 | 低危 | service/impl/LoginServiceImpl.java:258-266 | 注释与实现不一致：注释声明"获取登录态并提取 Token 签名加入黑名单"，但代码仅 `removeSession` 未调用 `addToBlacklist`（踢人分支只删会话）。当前行为正确（会话删除后网关 checkSession 即 401），但安全语义依赖隐式行为，且踢所有端分支（removeAllSessions）同样无黑名单，若未来网关校验顺序调整存在隐患。 | 按注释补全黑名单逻辑（读取会话 tokenSignature 后 addToBlacklist），或修正注释说明"会话删除即失效"的语义。 |

### 3.2 性能陷阱（N+1 查询、内存泄漏、不必要的循环、大数据量全表扫描）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| P-01 | 中危 | AuthenticationService.java:289；LoginServiceImpl.java:419（addToBlacklist 调用） | 同端互斥将旧 Access Token 签名加入黑名单时 TTL 使用 `refreshTokenExpiration`（604800s=7 天），而 Access Token 本身仅 2 小时有效。每次同端登录互斥都会产生一个 7 天后才过期的黑名单 key，长期运行 Redis 中残留大量无意义 key，浪费内存。 | 黑名单 TTL 改用 `accessTokenExpiration`（或按旧 Token 剩余有效期计算），与 Access Token 实际生命周期匹配。 |
| P-02 | 信息 | — | 其余性能核查通过：无 N+1 查询、无循环内数据库查询（互斥遍历固定 6 个客户端类型枚举且为 Redis 操作）、无内存泄漏隐患、无全表扫描；网关/认证密钥为启动时一次性解析缓存。 | — |

### 3.3 代码质量（重复代码、过长函数、命名混乱、缺乏注释）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| Q-01 | 中危 | AuthenticationService.java:280-306 vs LoginServiceImpl.java:405-430 | 同端互斥逻辑重复实现两处（几乎相同，仅日志语言中文/英文不同），且两处均为活跃代码路径（login 走 AuthenticationService、logout/kickout 走 LoginService），后续修改需同步两处，易产生漂移（本版本即出现两处日志语言不一致）。 | 抽取公共方法（如 `LoginSessionService.revokeOldSessions(userId, clientType)`），统一实现与日志。 |
| Q-02 | 中危 | config/SecurityConfig.java:55-56 | 类级 Javadoc 声明"其余请求均需认证"，与实际实现 `anyRequest().permitAll()`（81 行）矛盾；78-81 行局部注释已更新但类级文档未同步，易误导后续维护者。 | 同步更新类级 Javadoc，说明"认证由网关 AuthFilter + Controller 透传头校验负责"的信任边界。 |
| Q-03 | 低危 | service/impl/LoginServiceImpl.java:505-511 | `isAdmin` 硬编码角色编码字符串 `"admin"`/`"SUPER_ADMIN"`，缺少常量定义，与项目其他角色编码引用方式不一致。 | 提取为常量（如 `RoleConstants.ADMIN` / `RoleConstants.SUPER_ADMIN`）统一管理。 |
| Q-04 | 低危 | AuthenticationService.java vs LoginServiceImpl.java（同端互斥日志） | 同逻辑日志语言不统一（中文 vs 英文），审计日志风格混乱。 | 随 Q-01 抽取公共方法时统一为项目约定语言。 |
| Q-05 | 信息 | deploy/scripts/deploy-rsa-keygen.ps1 | DER 结构契约自校验依赖硬编码偏移（私钥 `[7]=0x30`、公钥 `[4]=0x30`/`[19]=0x03`），对 RSA 2048 + rsaEncryption 固定结构成立，但若 OpenSSL 版本/参数变化（OID 长度或附加参数）会误判。 | 可保留（契约固定场景可用），后续可升级为按 DER 标签解析的通用校验。 |

### 3.4 架构合规性（分层是否清晰、是否违反依赖方向、是否绕过已定义的接口）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| A-01 | 高危 | docs/cso-v0.2.6/cso-lld-v0.2.6.md:53-61（红线表）；TASK-004 13 个 Java 文件 | 设计文档与实际交付不一致：LLD/PRD 声明"业务代码逻辑禁止改动，允许改动仅限构建/依赖配置、密钥脚本、环境配置、部署/回归流程"，但实际 TASK-004 修改了 13 个 Java 文件（认证/权限/Token/验证码/异常处理等业务逻辑）。虽 regression-api-test.md §3.3 已逐项说明（契约行为修复：409/403/429 映射、防账号枚举、验证码用途隔离、同端互斥、tokenVersion 等），但 LLD 红线表未同步更新，违反"修复范围"设计约束，审计追溯存在断点。 | LLD/PRD 补充"TASK-004 契约修复子范围"章节（明确因回归暴露而追加的服务内部行为对齐改动，未触碰 Controller/DTO/响应体），保持文档与交付一致。 |
| A-02 | 中危 | config/SecurityConfig.java:81 + controller/AuthController.java:359 | 认证职责完全后移至网关（`permitAll` + 透传头二次认证），服务端无任何 JWT 验签兜底，不满足纵深防御要求（详见 S-01）。单点认证失效（网关故障/配置错误/直连暴露）即整体失去保护。 | 增加网关来源可信机制（内网隔离、网关签名头或服务内 JWT 过滤），形成网关 + 服务端双重防线。 |
| A-03 | 通过 | — | 其余架构合规性核查通过：未触碰 Controller/DTO/响应体（API-001~033 契约完整，静态+动态双重确认）；分层清晰，改动均在 service/strategy/util/dto/exception 层；依赖方向无违反（服务仅依赖 common）；`@Import(GlobalExceptionHandler)` 显式注册解决 common 包扫描盲区；gateway 排除 common 传递依赖（webmvc/springdoc/mybatis-plus）符合 WebFlux 架构，构建与启动均验证通过。 | — |

### 3.5 测试覆盖（关键路径是否有测试、边界条件是否覆盖）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| T-01 | 中危 | scripts/API-TEST/cso-api-test-v0.0.1.py（TC-013/TC-015） | 与 S-02 对应：TC-013 仅覆盖"被踢后旧 Access Token 立即失效（黑名单 401）"，TC-015 仅覆盖"登出后刷新被拒"，**未覆盖"被踢设备用旧 refresh token 刷新"组合场景**（该场景当前可反踢新设备）。 | 增加用例：同端互斥后，旧 refresh token 刷新应返回 401（SESSION_KICKED_OUT/TOKEN_BLACKLISTED），且不得覆盖新会话。 |
| T-02 | 中危 | scripts/API-TEST/cso-api-test-v0.0.1.py（TC-043） | 与 S-01 对应：TC-043 仅覆盖"直连 auth-service 缺 X-Tenant-Id/X-User-Id 头返回 400/401"，**未覆盖伪造 X-User-Id 头直连的越权场景**。 | 增加用例：直连 auth-service 伪造 `X-User-Id: 1` 调用管理接口应被拒绝（修复 S-01 后生效）。 |
| T-03 | 低危 | cso-testcase-v0.2.6.md（TC-013） | tokenVersion 修复（同秒重复登录 Access Token 唯一性）无专门断言，仅被 TC-013 间接覆盖，回归防护不足。 | 增加断言：同一用户同秒两次登录签发的 Access Token 字符串不同。 |
| T-04 | 低危 | cso-api-test-v0.2.6.py（TC-052-4/054-4）；cso-unit-test-*-v0.2.6.ps1（UT-104-2/112-1/124-3） | 版本级 git 变更清单断言在"任务已提交入库"后永久失效（本次单测 FAIL=3、版本级脚本 FAIL=1 均源于此），每次回归都产生已知失败，污染结果统计。 | 断言改为双态判定："目标文件已入库（git log 命中）或在工作区未提交变更清单中，均视为通过"。 |
| T-05 | 通过 | — | 覆盖亮点：单测 UT-097~131 共 93 断言（PASS=90，3 项失败均为 T-04 已登记断言失效，功能断言全 PASS）；API 回归 TC-001~051 全量 PASS=72/FAIL=0/SKIP=0 且首次+幂等复跑结果一致；deploy-rsa-keygen.ps1 契约自校验（无 PEM 头尾/无换行/严格解码/DER 结构）与 RsaKeyConfig 解码契约闭环。 | — |

## 4. 优先级建议

**必须修复（下个版本优先，高危）：**
1. S-01：恢复服务端认证兜底（内网隔离 + 网关覆盖敏感头 + 服务内 JWT 验签或网关签名头校验），消除直连越权面。
2. A-01：同步更新 LLD/PRD 文档，补录 TASK-004 契约修复子范围，恢复设计文档与交付一致性。

**建议修复（中危）：**
3. S-02 + T-01：补全同端互斥的 refresh token 吊销（会话记录 refresh 签名，互斥/登出一并黑名单），并增加"被踢后刷新被拒"用例。
4. P-01：互斥黑名单 TTL 改用 accessTokenExpiration，避免 Redis key 滞留。
5. Q-01/Q-04：抽取同端互斥公共方法，统一实现与日志语言。
6. A-02：将 S-01 修复方案固化为架构决策（ADR），明确服务间信任边界。
7. T-02：增加伪造透传头直连的越权负向用例。

**建议改进（低危）：**
8. Q-02：同步 SecurityConfig 类级 Javadoc；Q-03：角色编码提取常量；S-03：踢人注释与实现对齐。
9. T-04：版本级 git 断言改双态判定，消除已知失败噪音。
10. T-03：增加 tokenVersion 唯一性断言；Q-05：密钥脚本 DER 校验可保留现状。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
