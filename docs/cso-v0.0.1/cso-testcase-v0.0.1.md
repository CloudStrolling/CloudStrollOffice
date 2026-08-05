# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice，英文缩写 cso）
**版本号**：v0.0.1（初始化归档版本，对应实际业务版本 v0.1.6）
**日期**：2026-08-05
**测试负责人**：TE

> 本文档为存量项目初始化归档（v0.0.1）的测试用例文档，基于 docs/cso-prd.md、docs/cso-lld.md、docs/cso-api.md 反推生成。项目已有 15 个测试类、206 个单元测试（JUnit5 + Mockito），后端 REST 接口 33 个端点（统一前缀 `/api/v1/{module}`，统一响应 `ApiResult<T>`），客户端为 Flutter（Dart 3）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 认证服务核心逻辑（单元测试，引用已有 15 测试类 206 用例） | impm-init-testcase | 15 | P0×7 / P1×8 |
| 认证管理接口（登录/注册/刷新/登出/踢人/改密/找回/手机号/补全/验证码，API-001~011） | impm-init-testcase | 28 | P0×6 / P1×17 / P2×5 |
| RBAC 管理接口（用户/角色/权限 CRUD 与分配，API-012~030） | impm-init-testcase | 26 | P1×8 / P2×18 |
| 健康检查与通用鉴权（API-031~033 及 401/403 通用场景） | impm-init-testcase | 3 | P0×1 / P1×2 |
| Flutter 客户端认证模块（功能/UI 测试，F-017） | impm-init-testcase | 9 | P0×2 / P1×5 / P2×2 |
| **合计** |  | **81** | P0×16 / P1×32 / P2×25 / P3×8 |

## 二、测试用例详情

### 模块：认证服务核心逻辑 - 单元测试（JUnit5 + Mockito，已有测试类引用）

#### TC-UNIT-001：JWT RS256 双 Token 签发与解析（P0）
- **用例ID**：TC-UNIT-001
- **用例名称**：JWT RS256 双 Token 签发与解析
- **所属模块**：认证服务核心逻辑 / 会话安全（F-007）
- **优先级**：P0
- **前置条件**：测试环境已配置 RSA 密钥对；`mvn test` 可执行
- **测试类型**：单元测试
- **关联需求ID**：F-007
- **测试数据**：用户 ID=1、登录名 admin、租户编码 default、客户端类型 WINDOWS
- **测试步骤**：
  1. 调用 `JwtUtils.generateTokenPair` 生成双 Token
  2. 解析 Access Token 校验 Claims（userId/loginName/tenantCode/clientType/tokenType）
  3. 校验过期时间：Access=7200s、Refresh=604800s
  4. 用错误密钥验签，断言失败
  5. 校验 tokenType=refresh 的 Token 不能作为 access 使用
- **预期结果**：
  1. 生成 Access Token + Refresh Token 且格式合法（三段式 JWT）
  2. Claims 与签名指纹（fingerprint）与签发输入一致
  3. 过期时间与配置一致
  4. 密钥不匹配时验签抛出异常
  5. tokenType 校验拦截非法类型
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/util/JwtUtilsTest.java`（17 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-002：RSA 密钥对加载与验签（P0）
- **用例ID**：TC-UNIT-002
- **用例名称**：RSA 密钥对加载与验签
- **所属模块**：认证服务核心逻辑 / 会话安全（F-007）
- **优先级**：P0
- **前置条件**：`cloudoffice-auth-service/src/test/resources` 存在测试密钥对
- **测试类型**：单元测试
- **关联需求ID**：F-007
- **测试数据**：RSA 2048 位公私钥（测试资源）
- **测试步骤**：
  1. 加载 RSA 公钥/私钥配置
  2. 使用私钥签名、公钥验签
  3. 校验密钥算法与长度
  4. 加载非法密钥断言异常
- **预期结果**：
  1. 公钥/私钥加载成功且类型为 RSA
  2. 签名可被公钥验证
  3. 密钥长度 2048 位
  4. 非法密钥抛异常
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/config/RsaKeyConfigTest.java`（10 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-003：安全配置装配与密码编码器（P1）
- **用例ID**：TC-UNIT-003
- **用例名称**：安全配置装配与密码编码器
- **所属模块**：认证服务核心逻辑 / 安全配置
- **优先级**：P1
- **前置条件**：Spring 测试上下文可加载
- **测试类型**：单元测试
- **关联需求ID**：F-013
- **测试数据**：明文密码 `admin123`
- **测试步骤**：
  1. 校验 `SecurityConfig` Bean 装配成功
  2. 校验 `PasswordEncoder` 为 BCrypt 实现
  3. 编码后密文与明文不相等、可匹配校验
- **预期结果**：
  1. 安全配置 Bean 正常装配
  2. 密码编码器为 BCrypt 且校验通过
  3. 无状态会话配置生效
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfigTest.java`（4 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-004：登录服务核心流程（P0）
- **用例ID**：TC-UNIT-004
- **用例名称**：登录服务核心流程（登录/登出/踢人）
- **所属模块**：认证服务核心逻辑 / 多模式登录（F-001、F-008）
- **优先级**：P0
- **前置条件**：Mockito 模拟 Mapper/Redis/JWT 依赖
- **测试类型**：单元测试
- **关联需求ID**：F-001 / F-008 / F-012
- **测试数据**：登录名 admin、密码 admin123、租户 default、客户端 WINDOWS
- **测试步骤**：
  1. 执行用户名密码登录成功路径
  2. 执行密码错误路径断言 AUTH-0010
  3. 执行账号封禁/租户禁用路径断言 AUTH-0008/AUTH-0014
  4. 验证同端互斥：同 clientType 二次登录顶掉旧会话
  5. 执行登出幂等（重复登出不报错）
  6. 执行踢人：管理员成功、非管理员断言 AUTH-0016
  7. 验证登录日志记录成功/失败
- **预期结果**：
  1. 登录成功返回 TokenPairDTO，会话写入 Redis
  2. 失败路径返回对应业务错误码并记录登录日志
  3. 同端互斥清理旧会话，多端共存保留各自会话
  4. 登出幂等成功，Token 入黑名单
  5. 踢人仅管理员可执行
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/LoginServiceImplTest.java`（39 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-005：Token 刷新轮换（P0）
- **用例ID**：TC-UNIT-005
- **用例名称**：Token 刷新轮换
- **所属模块**：认证服务核心逻辑 / 会话安全（F-007）
- **优先级**：P0
- **前置条件**：Mockito 模拟依赖
- **测试类型**：单元测试
- **关联需求ID**：F-007
- **测试数据**：有效 Refresh Token、过期 Refresh Token、黑名单 Refresh Token
- **测试步骤**：
  1. 使用有效 Refresh Token 刷新，断言返回新双 Token
  2. 断言旧 Refresh Token 被加入黑名单（防重放）
  3. 过期/无效/黑名单 Refresh Token 分别断言 AUTH-0004/AUTH-0005/AUTH-0003
  4. 用户/租户状态异常断言 AUTH-0008/AUTH-0014
- **预期结果**：
  1. 刷新成功返回新 Token 对且旧 Refresh Token 立即失效
  2. 异常路径返回对应错误码
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/TokenServiceImplTest.java`（20 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-006：会话与黑名单管理（P0）
- **用例ID**：TC-UNIT-006
- **用例名称**：Redis 会话与黑名单管理
- **所属模块**：认证服务核心逻辑 / 会话管理（F-008）
- **优先级**：P0
- **前置条件**：Mockito 模拟 RedisTemplate
- **测试类型**：单元测试
- **关联需求ID**：F-008
- **测试数据**：用户 ID=1、签名指纹、TTL=7200
- **测试步骤**：
  1. 创建/获取/删除会话
  2. 批量删除用户所有会话（SCAN 匹配 `auth:session:{userId}:*`）
  3. 黑名单增加与查询（TTL 最小 1 秒边界）
  4. 账号/租户状态缓存读写与删除
- **预期结果**：
  1. 会话 Key 结构、TTL 与设计一致
  2. 批量删除遍历全部客户端类型会话
  3. 黑名单命中返回 true、未命中返回 false
  4. 状态缓存读写一致
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/LoginSessionServiceImplTest.java`（29 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-007：登录日志审计（P1）
- **用例ID**：TC-UNIT-007
- **用例名称**：登录日志审计
- **所属模块**：认证服务核心逻辑 / 安全审计（F-012）
- **优先级**：P1
- **前置条件**：Mockito 模拟 Mapper
- **测试类型**：单元测试
- **关联需求ID**：F-012
- **测试数据**：IP=127.0.0.1、clientType=WINDOWS、登录成功/失败
- **测试步骤**：
  1. 登录成功记录日志（IP/客户端类型/结果）
  2. 登录失败记录日志（失败原因）
  3. 登出时更新登出时间
- **预期结果**：
  1. 日志实体字段与输入一致，成功/失败均落库
  2. 登出时间正确更新
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/LoginLogServiceImplTest.java`（5 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-008：用户服务核心逻辑（P1）
- **用例ID**：TC-UNIT-008
- **用例名称**：用户服务核心逻辑（账号补全/更新/状态/角色分配）
- **所属模块**：认证服务核心逻辑 / RBAC（F-003、F-004）
- **优先级**：P1
- **前置条件**：Mockito 模拟 Mapper 依赖
- **测试类型**：单元测试
- **关联需求ID**：F-003 / F-004
- **测试数据**：用户 ID=1、手机号 13800138000、角色 ID 集合 [101,102]
- **测试步骤**：
  1. 账号补全成功/重复补全断言 AUTH-0031
  2. 用户信息更新（不含密码）
  3. 用户状态变更（0~3）
  4. 全量分配用户角色（先删后插）
  5. 用户不存在断言 AUTH-0018
- **预期结果**：
  1. 补全后 accountSettled=true 且不可重复补全
  2. 更新不触碰密码字段
  3. 状态在 0-3 范围内生效
  4. 角色关联先删后插结果正确
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/UserServiceImplTest.java`（21 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-009：角色服务核心逻辑（P1）
- **用例ID**：TC-UNIT-009
- **用例名称**：角色服务核心逻辑（CRUD/删除阻止/权限分配）
- **所属模块**：认证服务核心逻辑 / RBAC（F-004）
- **优先级**：P1
- **前置条件**：Mockito 模拟 Mapper 依赖
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试数据**：租户 ID=1、角色编码 HR、权限 ID 集合 [201,202]
- **测试步骤**：
  1. 创建/更新/查询角色
  2. 删除未被分配角色成功
  3. 删除已被分配角色断言阻止（409）
  4. 全量分配角色权限（先删后插）
- **预期结果**：
  1. 角色 CRUD 结果正确、租户内编码唯一
  2. 已分配角色删除被阻止
  3. 权限关联先删后插结果正确
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/service/impl/RoleServiceImplTest.java`（16 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-010：认证控制器端点（P0）
- **用例ID**：TC-UNIT-010
- **用例名称**：认证控制器端点（MockMvc）
- **所属模块**：认证服务核心逻辑 / 接口层（F-001~F-011）
- **优先级**：P0
- **前置条件**：MockMvc + Mockito 模拟服务依赖
- **测试类型**：单元测试
- **关联需求ID**：F-001 / F-002 / F-007 / F-009 / F-010 / F-011
- **测试数据**：登录/注册/刷新/登出/踢人/改密/找回/换绑/补全/验证码请求体
- **测试步骤**：
  1. 逐一调用 AuthController 11 个端点（登录/注册/刷新/登出/踢人/改密/找回发送/找回重置/改手机号/补全/发验证码）
  2. 验证成功路径 HTTP 200 与 ApiResult 结构
  3. 验证异常路径（X-User-Id 缺失、Bearer 格式错误、参数非法）
- **预期结果**：
  1. 端点全量覆盖，响应体 `code/message/data/timestamp` 结构正确
  2. 异常路径返回对应 400/401/403 状态与业务码
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/AuthControllerTest.java`（10 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-011：用户控制器端点（P1）
- **用例ID**：TC-UNIT-011
- **用例名称**：用户控制器端点（分页/详情/更新/删除/角色/状态）
- **所属模块**：认证服务核心逻辑 / 接口层（F-004）
- **优先级**：P1
- **前置条件**：MockMvc + Mockito 模拟服务依赖
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试数据**：用户 ID=1、page=1、pageSize=10、status=3
- **测试步骤**：
  1. 调用用户分页/详情/更新/删除/分配角色/变更状态 6 个端点
  2. 验证成功与异常（不存在/参数非法）路径
- **预期结果**：
  1. 各端点响应结构正确、分页字段完整
  2. 异常路径返回 AUTH-0018/400
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/UserControllerTest.java`（13 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-012：角色控制器端点（P1）
- **用例ID**：TC-UNIT-012
- **用例名称**：角色控制器端点（CRUD 与权限分配）
- **所属模块**：认证服务核心逻辑 / 接口层（F-004）
- **优先级**：P1
- **前置条件**：MockMvc + Mockito 模拟服务依赖
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试数据**：角色 ID=101、权限 ID 集合 [201,202,203]
- **测试步骤**：
  1. 调用角色分页/列表/详情/创建/更新/删除/分配权限端点
  2. 验证成功与异常路径
- **预期结果**：
  1. 各端点响应结构正确
  2. 异常路径返回 AUTH-0017/409/400
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/RoleControllerTest.java`（10 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-013：权限控制器端点（P1）
- **用例ID**：TC-UNIT-013
- **用例名称**：权限控制器端点（树/列表/CRUD）
- **所属模块**：认证服务核心逻辑 / 接口层（F-004）
- **优先级**：P1
- **前置条件**：MockMvc + Mockito 模拟服务依赖
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试数据**：权限 ID=201、permCode=role:create
- **测试步骤**：
  1. 调用权限树/列表/详情/创建/更新/删除端点
  2. 验证成功与异常路径（创建 201、编码重复 409）
- **预期结果**：
  1. 树形结构按 parentId 正确嵌套、平铺列表正确
  2. 创建成功 HTTP 201，编码重复返回 409
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/PermissionControllerTest.java`（9 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-014：健康检查控制器（P1）
- **用例ID**：TC-UNIT-014
- **用例名称**：健康检查控制器响应结构
- **所属模块**：认证服务核心逻辑 / 运维支撑（F-014）
- **优先级**：P1
- **前置条件**：MockMvc
- **测试类型**：单元测试
- **关联需求ID**：F-014
- **测试数据**：GET /api/v1/auth/health
- **测试步骤**：
  1. 调用健康检查端点
  2. 断言响应 data 含 service/status/version/timestamp
- **预期结果**：
  1. HTTP 200，service=cloudoffice-auth-service、status=UP
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/HealthControllerTest.java`（1 个测试方法）
- **测试过程与结论**：（待执行）

#### TC-UNIT-015：应用上下文加载（P1）
- **用例ID**：TC-UNIT-015
- **用例名称**：认证服务应用上下文加载
- **所属模块**：认证服务核心逻辑 / 工程基线
- **优先级**：P1
- **前置条件**：测试环境配置完整
- **测试类型**：单元测试
- **关联需求ID**：F-013
- **测试数据**：Spring Boot 应用上下文
- **测试步骤**：
  1. 加载应用上下文
  2. 断言核心 Bean（Controller/Service/Config）存在
- **预期结果**：
  1. 上下文加载成功、无 Bean 装配异常
- **自动化测试函数/脚本位置**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/AuthApplicationTest.java`（2 个测试方法）
- **测试过程与结论**：（待执行）

### 模块：认证管理接口 - /api/v1/auth（接口测试）

#### TC-API-001：用户名密码登录成功（P0）
- **用例ID**：TC-API-001
- **用例名称**：用户名密码登录成功签发双 Token
- **所属模块**：认证管理接口（API-001）
- **优先级**：P0
- **前置条件**：网关（9000）与认证服务（9100）已启动；测试账号 admin/admin123 存在（租户 default）
- **测试类型**：接口测试
- **关联需求ID**：F-001
- **测试数据**：loginMode=USERNAME_PASSWORD、loginName=admin、password=admin123、tenantCode=default、clientType=WINDOWS
- **测试步骤**：
  1. POST /api/v1/auth/login 携带上述请求体
  2. 断言 HTTP 200、code=200
  3. 断言 data 含 accessToken/refreshToken/tokenType=Bearer/accessTokenExpireIn=7200/refreshTokenExpireIn=604800
- **预期结果**：
  1. 返回双 Token，过期秒数与文档一致
  2. 消息为"登录成功"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_login_success`
- **测试过程与结论**：（待执行）

#### TC-API-002：登录-密码错误（P0）
- **用例ID**：TC-API-002
- **用例名称**：登录密码错误返回 AUTH-0010
- **所属模块**：认证管理接口（API-001）
- **优先级**：P0
- **前置条件**：同 TC-API-001
- **测试类型**：接口测试
- **关联需求ID**：F-001
- **测试数据**：password=wrongpass（错误密码）
- **测试步骤**：
  1. POST /api/v1/auth/login 携带错误密码
  2. 断言 HTTP 401、业务码 AUTH-0010
- **预期结果**：
  1. 返回"用户名或密码错误"，不返回 Token
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_login_wrong_password`
- **测试过程与结论**：（待执行）

#### TC-API-003：登录-无效客户端类型（P1）
- **用例ID**：TC-API-003
- **用例名称**：登录客户端类型非法返回 AUTH-0012
- **所属模块**：认证管理接口（API-001）
- **优先级**：P1
- **前置条件**：同 TC-API-001
- **测试类型**：接口测试
- **关联需求ID**：F-001
- **测试数据**：clientType=TV（非法值）
- **测试步骤**：
  1. POST /api/v1/auth/login 携带非法 clientType
  2. 断言 HTTP 400、业务码 AUTH-0012
- **预期结果**：
  1. 返回"无效的客户端类型"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_login_invalid_client_type`
- **测试过程与结论**：（待执行）

#### TC-API-004：登录-无效登录模式（P1）
- **用例ID**：TC-API-004
- **用例名称**：登录模式非法返回 AUTH-0033
- **所属模块**：认证管理接口（API-001）
- **优先级**：P1
- **前置条件**：同 TC-API-001
- **测试类型**：接口测试
- **关联需求ID**：F-001
- **测试数据**：loginMode=UNKNOWN_MODE
- **测试步骤**：
  1. POST /api/v1/auth/login 携带非法 loginMode
  2. 断言 HTTP 400、业务码 AUTH-0033
- **预期结果**：
  1. 返回"无效的登录模式"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_login_invalid_mode`
- **测试过程与结论**：（待执行）

#### TC-API-005：登录-账号封禁拦截（P1）
- **用例ID**：TC-API-005
- **用例名称**：封禁账号登录返回 AUTH-0008
- **所属模块**：认证管理接口（API-001）
- **优先级**：P1
- **前置条件**：存在被封禁测试账号（status=3）
- **测试类型**：接口测试
- **关联需求ID**：F-001 / F-008
- **测试数据**：封禁账号凭证
- **测试步骤**：
  1. POST /api/v1/auth/login 使用封禁账号
  2. 断言 HTTP 403、业务码 AUTH-0008
- **预期结果**：
  1. 返回"账号已被封禁"，登录被拦截
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_login_banned_account`
- **测试过程与结论**：（待执行）

#### TC-API-006：用户名模式注册成功（P0）
- **用例ID**：TC-API-006
- **用例名称**：USERNAME 模式注册成功
- **所属模块**：认证管理接口（API-002）
- **优先级**：P0
- **前置条件**：网关与认证服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-002
- **测试数据**：registerMode=USERNAME、loginName=新用户（唯一）、password=Password123、userName=张三、tenantCode=default
- **测试步骤**：
  1. POST /api/v1/auth/register 携带上述请求体
  2. 断言 HTTP 200、code=200
  3. 断言 data 含 userId/loginName/userName/accountSettled=true/tokenPair
- **预期结果**：
  1. 注册成功返回用户信息与 Token 对，默认角色已分配
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_register_success`
- **测试过程与结论**：（待执行）

#### TC-API-007：注册-登录名重复（P1）
- **用例ID**：TC-API-007
- **用例名称**：注册登录名重复返回 409
- **所属模块**：认证管理接口（API-002）
- **优先级**：P1
- **前置条件**：同 TC-API-006
- **测试类型**：接口测试
- **关联需求ID**：F-002
- **测试数据**：已存在登录名 admin
- **测试步骤**：
  1. 使用已存在登录名 POST /api/v1/auth/register
  2. 断言 HTTP 409（用户名唯一性冲突）
- **预期结果**：
  1. 返回资源冲突错误，不创建重复账号
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_register_duplicate_login_name`
- **测试过程与结论**：（待执行）

#### TC-API-008：注册-参数不合法（P2）
- **用例ID**：TC-API-008
- **用例名称**：注册参数非法返回 400
- **所属模块**：认证管理接口（API-002）
- **优先级**：P2
- **前置条件**：同 TC-API-006
- **测试类型**：接口测试
- **关联需求ID**：F-002
- **测试数据**：loginName=ab（长度不足 4）、password=123（长度不足 8）
- **测试步骤**：
  1. POST /api/v1/auth/register 携带非法参数
  2. 断言 HTTP 400
- **预期结果**：
  1. 返回参数错误，不创建账号
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_register_invalid_params`
- **测试过程与结论**：（待执行）

#### TC-API-009：刷新 Token 成功（P0）
- **用例ID**：TC-API-009
- **用例名称**：Refresh Token 换发新双 Token
- **所属模块**：认证管理接口（API-003）
- **优先级**：P0
- **前置条件**：已登录获取 Refresh Token
- **测试类型**：接口测试
- **关联需求ID**：F-007
- **测试数据**：TC-API-001 登录返回的 refreshToken
- **测试步骤**：
  1. POST /api/v1/auth/refresh 携带 refreshToken
  2. 断言 HTTP 200、code=200、返回新 accessToken/refreshToken
- **预期结果**：
  1. 刷新成功返回新 Token 对，消息为"刷新成功"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_refresh_success`
- **测试过程与结论**：（待执行）

#### TC-API-010：刷新-无效 Refresh Token（P1）
- **用例ID**：TC-API-010
- **用例名称**：无效 Refresh Token 刷新返回 AUTH-0005
- **所属模块**：认证管理接口（API-003）
- **优先级**：P1
- **前置条件**：同 TC-API-009
- **测试类型**：接口测试
- **关联需求ID**：F-007
- **测试数据**：refreshToken=invalid.token.value
- **测试步骤**：
  1. POST /api/v1/auth/refresh 携带无效 Token
  2. 断言 HTTP 401、业务码 AUTH-0005
- **预期结果**：
  1. 返回"刷新令牌无效"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_refresh_invalid_token`
- **测试过程与结论**：（待执行）

#### TC-API-011：刷新-旧 Refresh Token 重放（P1）
- **用例ID**：TC-API-011
- **用例名称**：旧 Refresh Token 重放返回 AUTH-0003
- **所属模块**：认证管理接口（API-003）
- **优先级**：P1
- **前置条件**：同 TC-API-009
- **测试类型**：接口测试
- **关联需求ID**：F-007
- **测试数据**：已轮换过的旧 refreshToken
- **测试步骤**：
  1. 首次刷新成功
  2. 用首次使用的旧 refreshToken 再次刷新
  3. 断言 HTTP 401、业务码 AUTH-0003（黑名单）
- **预期结果**：
  1. 旧 Refresh Token 已入黑名单，重放被拒绝
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_refresh_replay_rejected`
- **测试过程与结论**：（待执行）

#### TC-API-012：登出成功且幂等（P0）
- **用例ID**：TC-API-012
- **用例名称**：登出成功且重复登出幂等
- **所属模块**：认证管理接口（API-004）
- **优先级**：P0
- **前置条件**：已登录获取 Access Token
- **测试类型**：接口测试
- **关联需求ID**：F-008
- **测试数据**：Authorization: Bearer <accessToken>
- **测试步骤**：
  1. POST /api/v1/auth/logout 携带 Token
  2. 断言 HTTP 200、code=200、message=登出成功
  3. 再次调用登出断言仍成功（幂等）
- **预期结果**：
  1. 登出成功且重复登出不报错
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_logout_success_and_idempotent`
- **测试过程与结论**：（待执行）

#### TC-API-013：登出后 Token 失效（P1）
- **用例ID**：TC-API-013
- **用例名称**：登出后原 Token 访问受保护接口返回 401
- **所属模块**：认证管理接口（API-004）
- **优先级**：P1
- **前置条件**：已登录并登出
- **测试类型**：接口测试
- **关联需求ID**：F-008
- **测试数据**：已登出账号的 accessToken
- **测试步骤**：
  1. 登录获取 Token → 登出
  2. 用原 Token GET /api/v1/auth/users
  3. 断言 HTTP 401（黑名单拦截）
- **预期结果**：
  1. 原 Token 被网关黑名单拦截，返回 401
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_logout_token_invalidated`
- **测试过程与结论**：（待执行）

#### TC-API-014：管理员强制踢人成功（P1）
- **用例ID**：TC-API-014
- **用例名称**：管理员强制指定用户下线
- **所属模块**：认证管理接口（API-005）
- **优先级**：P1
- **前置条件**：管理员账号（admin/admin123）与普通测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-001 / F-008
- **测试数据**：targetUserId=测试账号 ID、clientType=WINDOWS
- **测试步骤**：
  1. 管理员 POST /api/v1/auth/kickout 指定 userId 与 clientType
  2. 断言 HTTP 200、code=200
  3. 目标用户原 Token 访问接口断言 401
- **预期结果**：
  1. 踢人成功，目标用户对应端会话立即失效
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_kickout_success`
- **测试过程与结论**：（待执行）

#### TC-API-015：踢人-非管理员权限不足（P1）
- **用例ID**：TC-API-015
- **用例名称**：非管理员踢人返回 AUTH-0016
- **所属模块**：认证管理接口（API-005）
- **优先级**：P1
- **前置条件**：普通测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / F-008
- **测试数据**：普通账号 Token、目标 userId
- **测试步骤**：
  1. 普通账号 POST /api/v1/auth/kickout
  2. 断言 HTTP 403、业务码 AUTH-0016
- **预期结果**：
  1. 权限不足被拒绝
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_kickout_forbidden`
- **测试过程与结论**：（待执行）

#### TC-API-016：修改密码成功（P0）
- **用例ID**：TC-API-016
- **用例名称**：修改密码成功并清除登录态
- **所属模块**：认证管理接口（API-006）
- **优先级**：P0
- **前置条件**：测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-009
- **测试数据**：oldPassword=旧密码、newPassword=NewPass123、confirmPassword=NewPass123
- **测试步骤**：
  1. PUT /api/v1/auth/password/change 携带正确旧密码与新密码
  2. 断言 HTTP 200、code=200
  3. 用旧 Token 访问受保护接口断言 401（登录态已清除）
  4. 用新密码重新登录断言成功
- **预期结果**：
  1. 改密成功，所有登录态会话失效，新密码可登录
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_change_password_success`
- **测试过程与结论**：（待执行）

#### TC-API-017：改密-原密码错误（P1）
- **用例ID**：TC-API-017
- **用例名称**：改密原密码错误返回 AUTH-0022
- **所属模块**：认证管理接口（API-006）
- **优先级**：P1
- **前置条件**：测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-009
- **测试数据**：oldPassword=WrongOld123（错误）
- **测试步骤**：
  1. PUT /api/v1/auth/password/change 携带错误旧密码
  2. 断言 HTTP 400、业务码 AUTH-0022
- **预期结果**：
  1. 返回"原密码错误"，密码未变更
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_change_password_wrong_old`
- **测试过程与结论**：（待执行）

#### TC-API-018：改密-确认密码不一致（P2）
- **用例ID**：TC-API-018
- **用例名称**：改密确认密码不一致返回 400
- **所属模块**：认证管理接口（API-006）
- **优先级**：P2
- **前置条件**：测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-009
- **测试数据**：newPassword=NewPass123、confirmPassword=DiffPass456
- **测试步骤**：
  1. PUT /api/v1/auth/password/change 携带不一致的确认密码
  2. 断言 HTTP 400
- **预期结果**：
  1. 返回参数错误，密码未变更
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_change_password_confirm_mismatch`
- **测试过程与结论**：（待执行）

#### TC-API-019：密码找回-发送验证码（P1）
- **用例ID**：TC-API-019
- **用例名称**：密码找回发送重置验证码
- **所属模块**：认证管理接口（API-007）
- **优先级**：P1
- **前置条件**：存在已绑定手机号的测试账号
- **测试类型**：接口测试
- **关联需求ID**：F-009 / F-011
- **测试数据**：target=测试手机号、purpose=RESET_PASSWORD、mode=SMS
- **测试步骤**：
  1. POST /api/v1/auth/password/forgot/send-code
  2. 断言 HTTP 200、code=200
- **预期结果**：
  1. 验证码发送成功（开发环境模拟发送）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_forgot_send_code_success`
- **测试过程与结论**：（待执行）

#### TC-API-020：密码找回-目标用户不存在（P1）
- **用例ID**：TC-API-020
- **用例名称**：找回验证码目标用户不存在返回 AUTH-0018
- **所属模块**：认证管理接口（API-007）
- **优先级**：P1
- **前置条件**：网关与认证服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-009 / F-011
- **测试数据**：target=19999999999（未注册手机号）
- **测试步骤**：
  1. POST /api/v1/auth/password/forgot/send-code
  2. 断言 HTTP 404、业务码 AUTH-0018
- **预期结果**：
  1. 返回"用户不存在"，不发送验证码
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_forgot_send_code_user_not_found`
- **测试过程与结论**：（待执行）

#### TC-API-021：密码找回-重置密码成功（P1）
- **用例ID**：TC-API-021
- **用例名称**：验证码重置密码成功
- **所属模块**：认证管理接口（API-008）
- **优先级**：P1
- **前置条件**：已发送重置验证码并获取验证码（模拟模式）
- **测试类型**：接口测试
- **关联需求ID**：F-009
- **测试数据**：mode=SMS、target=测试手机号、code=获取到的验证码、newPassword=ResetPass123
- **测试步骤**：
  1. POST /api/v1/auth/password/forgot/reset 携带正确验证码
  2. 断言 HTTP 200、code=200
  3. 使用新密码登录断言成功
- **预期结果**：
  1. 密码重置成功，旧登录态清除，新密码可登录
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_forgot_reset_success`
- **测试过程与结论**：（待执行）

#### TC-API-022：密码找回-验证码错误（P2）
- **用例ID**：TC-API-022
- **用例名称**：重置密码验证码错误返回 AUTH-0011
- **所属模块**：认证管理接口（API-008）
- **优先级**：P2
- **前置条件**：已发送重置验证码
- **测试类型**：接口测试
- **关联需求ID**：F-009 / F-011
- **测试数据**：code=000000（错误验证码）
- **测试步骤**：
  1. POST /api/v1/auth/password/forgot/reset 携带错误验证码
  2. 断言 HTTP 400、业务码 AUTH-0011
- **预期结果**：
  1. 返回"验证码错误"，密码未变更
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_forgot_reset_wrong_code`
- **测试过程与结论**：（待执行）

#### TC-API-023：修改手机号成功（P1）
- **用例ID**：TC-API-023
- **用例名称**：短信验证码变更手机号成功
- **所属模块**：认证管理接口（API-009）
- **优先级**：P1
- **前置条件**：测试账号已登录且绑定原手机号；已获取新旧手机号验证码
- **测试类型**：接口测试
- **关联需求ID**：F-010 / F-011
- **测试数据**：newPhone=新手机号、oldPhoneCode=旧手机验证码、newPhoneCode=新手机验证码
- **测试步骤**：
  1. 发送原/新手机号 CHANGE_PHONE 用途验证码并获取
  2. PUT /api/v1/auth/phone/change 携带验证码
  3. 断言 HTTP 200、code=200
  4. 用户详情断言手机号已更新
- **预期结果**：
  1. 手机号变更成功，新旧验证码校验通过
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_change_phone_success`
- **测试过程与结论**：（待执行）

#### TC-API-024：修改手机号-新手机已被绑定（P2）
- **用例ID**：TC-API-024
- **用例名称**：新手机号已被其他账号绑定返回 AUTH-0028
- **所属模块**：认证管理接口（API-009）
- **优先级**：P2
- **前置条件**：存在两个已绑定手机号的账号
- **测试类型**：接口测试
- **关联需求ID**：F-010
- **测试数据**：newPhone=其他账号已绑定手机号
- **测试步骤**：
  1. PUT /api/v1/auth/phone/change 使用已被占用的新手机号
  2. 断言 HTTP 409、业务码 AUTH-0028
- **预期结果**：
  1. 返回"手机号已被其他账号绑定"，变更被拒绝
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_change_phone_already_bound`
- **测试过程与结论**：（待执行）

#### TC-API-025：完善账号信息成功（P1）
- **用例ID**：TC-API-025
- **用例名称**：两步注册账号补全成功
- **所属模块**：认证管理接口（API-010）
- **优先级**：P1
- **前置条件**：存在 accountSettled=false 的两步注册账号并已登录
- **测试类型**：接口测试
- **关联需求ID**：F-003
- **测试数据**：userId=当前用户 ID、loginName=新登录名、password=Password123、phone=新手机号
- **测试步骤**：
  1. PUT /api/v1/auth/account/settlement 携带 userId 与补全信息
  2. 断言 HTTP 200、code=200
  3. 用户详情断言 accountSettled=true
- **预期结果**：
  1. 账号补全成功，状态转为已完善
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_account_settlement_success`
- **测试过程与结论**：（待执行）

#### TC-API-026：完善账号-重复补全（P2）
- **用例ID**：TC-API-026
- **用例名称**：已完善账号重复补全返回 AUTH-0031
- **所属模块**：认证管理接口（API-010）
- **优先级**：P2
- **前置条件**：accountSettled=true 的账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-003
- **测试数据**：userId=当前用户 ID、loginName=新登录名
- **测试步骤**：
  1. PUT /api/v1/auth/account/settlement 对已完善账号补全
  2. 断言 HTTP 403、业务码 AUTH-0031
- **预期结果**：
  1. 返回"账号信息未完善，请先补充资料"对应提示（不可重复补全）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_account_settlement_already_settled`
- **测试过程与结论**：（待执行）

#### TC-API-027：发送验证码成功（P1）
- **用例ID**：TC-API-027
- **用例名称**：注册用途发送短信验证码
- **所属模块**：认证管理接口（API-011）
- **优先级**：P1
- **前置条件**：网关与认证服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-011
- **测试数据**：target=13800138000、purpose=REGISTER、mode=SMS
- **测试步骤**：
  1. POST /api/v1/auth/verification-code/send
  2. 断言 HTTP 200、code=200
- **预期结果**：
  1. 验证码发送成功（开发环境模拟发送，可从控制台读取）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_send_verification_code_success`
- **测试过程与结论**：（待执行）

#### TC-API-028：发送验证码-频率限制（P1）
- **用例ID**：TC-API-028
- **用例名称**：60 秒内重复发送验证码返回 AUTH-0025
- **所属模块**：认证管理接口（API-011）
- **优先级**：P1
- **前置条件**：同 TC-API-027
- **测试类型**：接口测试
- **关联需求ID**：F-011
- **测试数据**：同一 target+purpose 连续发送两次
- **测试步骤**：
  1. 第一次发送成功
  2. 立即第二次发送同一目标同一用途
  3. 断言 HTTP 429、业务码 AUTH-0025
- **预期结果**：
  1. 第二次发送被频率限制拦截
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_send_verification_code_too_frequent`
- **测试过程与结论**：（待执行）

### 模块：RBAC 管理接口 - /api/v1/auth/users、/roles、/permissions（接口测试）

#### TC-API-029：分页查询用户列表（P1）
- **用例ID**：TC-API-029
- **用例名称**：管理员分页查询用户列表
- **所属模块**：用户管理接口（API-012）
- **优先级**：P1
- **前置条件**：管理员已登录；携带 X-Tenant-Id=1
- **测试类型**：接口测试
- **关联需求ID**：F-004 / F-005
- **测试数据**：page=1、pageSize=10、keyword=admin
- **测试步骤**：
  1. GET /api/v1/auth/users?page=1&pageSize=10&keyword=admin
  2. 断言 HTTP 200、code=200
  3. 断言 data 含 records/total/page/pageSize，用户记录不含密码字段
- **预期结果**：
  1. 分页结构完整，keyword 模糊匹配生效
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_page_query`
- **测试过程与结论**：（待执行）

#### TC-API-030：获取用户详情（P1）
- **用例ID**：TC-API-030
- **用例名称**：获取用户详情含角色编码列表
- **所属模块**：用户管理接口（API-013）
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：GET /api/v1/auth/users/{adminId}
- **测试步骤**：
  1. GET /api/v1/auth/users/{id}
  2. 断言 HTTP 200、code=200、data 含用户基本字段
- **预期结果**：
  1. 返回用户基本信息（不含密码）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_detail`
- **测试过程与结论**：（待执行）

#### TC-API-031：用户详情-不存在（P2）
- **用例ID**：TC-API-031
- **用例名称**：查询不存在用户返回 AUTH-0018
- **所属模块**：用户管理接口（API-013）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：id=999999999（不存在）
- **测试步骤**：
  1. GET /api/v1/auth/users/999999999
  2. 断言 HTTP 404、业务码 AUTH-0018
- **预期结果**：
  1. 返回"用户不存在"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_detail_not_found`
- **测试过程与结论**：（待执行）

#### TC-API-032：更新用户信息（P2）
- **用例ID**：TC-API-032
- **用例名称**：更新用户姓名/手机号/邮箱
- **所属模块**：用户管理接口（API-014）
- **优先级**：P2
- **前置条件**：管理员已登录；存在可更新测试用户
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：userName=李四、email=lisi@example.com
- **测试步骤**：
  1. PUT /api/v1/auth/users/{id} 携带更新字段
  2. 断言 HTTP 200、code=200、data 反映更新结果
- **预期结果**：
  1. 更新成功且不含密码变更
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_update`
- **测试过程与结论**：（待执行）

#### TC-API-033：逻辑删除用户（P2）
- **用例ID**：TC-API-033
- **用例名称**：逻辑删除用户后查询不可见
- **所属模块**：用户管理接口（API-015）
- **优先级**：P2
- **前置条件**：管理员已登录；存在可删除测试用户
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：DELETE /api/v1/auth/users/{id}
- **测试步骤**：
  1. DELETE /api/v1/auth/users/{id}
  2. 断言 HTTP 200、code=200
  3. 分页查询断言该用户不可见
- **预期结果**：
  1. 删除成功且查询不可见（deleted=1）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_delete`
- **测试过程与结论**：（待执行）

#### TC-API-034：分配用户角色（P1）
- **用例ID**：TC-API-034
- **用例名称**：全量分配用户角色
- **所属模块**：用户管理接口（API-016）
- **优先级**：P1
- **前置条件**：管理员已登录；角色存在
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：roleIds=[101]
- **测试步骤**：
  1. PUT /api/v1/auth/users/{id}/roles 携带 roleIds
  2. 断言 HTTP 200、code=200
  3. 用户详情断言角色编码列表已更新
- **预期结果**：
  1. 角色分配成功（先删后插）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_assign_roles`
- **测试过程与结论**：（待执行）

#### TC-API-035：变更用户状态-封禁（P1）
- **用例ID**：TC-API-035
- **用例名称**：封禁用户后其登录态实时失效
- **所属模块**：用户管理接口（API-017）
- **优先级**：P1
- **前置条件**：管理员已登录；普通测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / F-008
- **测试数据**：status=3、lockReason=违规操作
- **测试步骤**：
  1. PUT /api/v1/auth/users/{id}/status 设置 status=3
  2. 断言 HTTP 200、code=200
  3. 被封禁账号原 Token 访问接口断言 403
  4. 被封禁账号重新登录断言 AUTH-0008
- **预期结果**：
  1. 封禁实时生效，旧会话失效、新登录被拦截
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_status_ban`
- **测试过程与结论**：（待执行）

#### TC-API-036：变更用户状态-非法状态值（P2）
- **用例ID**：TC-API-036
- **用例名称**：状态值超出 0-3 范围返回 400
- **所属模块**：用户管理接口（API-017）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：status=9（非法）
- **测试步骤**：
  1. PUT /api/v1/auth/users/{id}/status 携带 status=9
  2. 断言 HTTP 400
- **预期结果**：
  1. 参数错误，状态未变更
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_user_status_invalid`
- **测试过程与结论**：（待执行）

#### TC-API-037：分页查询角色列表（P1）
- **用例ID**：TC-API-037
- **用例名称**：按租户分页查询角色列表
- **所属模块**：角色管理接口（API-018）
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / F-005
- **测试数据**：page=1、pageSize=10、tenantId=1
- **测试步骤**：
  1. GET /api/v1/auth/roles?page=1&pageSize=10&tenantId=1
  2. 断言 HTTP 200、code=200、分页结构完整
- **预期结果**：
  1. 返回该租户角色分页数据
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_page_query`
- **测试过程与结论**：（待执行）

#### TC-API-038：查询所有角色（P2）
- **用例ID**：TC-API-038
- **用例名称**：不分页查询租户全部角色
- **所属模块**：角色管理接口（API-019）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：tenantId=1
- **测试步骤**：
  1. GET /api/v1/auth/roles/list?tenantId=1
  2. 断言 HTTP 200、code=200、data 为数组
- **预期结果**：
  1. 返回角色数组（不分页）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_list`
- **测试过程与结论**：（待执行）

#### TC-API-039：查询角色详情（P2）
- **用例ID**：TC-API-039
- **用例名称**：查询角色详情
- **所属模块**：角色管理接口（API-020）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：GET /api/v1/auth/roles/{roleId}
- **测试步骤**：
  1. GET /api/v1/auth/roles/{id}
  2. 断言 HTTP 200、code=200、data 含 roleCode/roleName
- **预期结果**：
  1. 返回角色详情
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_detail`
- **测试过程与结论**：（待执行）

#### TC-API-040：创建角色（P1）
- **用例ID**：TC-API-040
- **用例名称**：创建角色成功
- **所属模块**：角色管理接口（API-021）
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：tenantId=1、roleCode=TEST_ROLE_{uuid}、roleName=测试角色、status=1
- **测试步骤**：
  1. POST /api/v1/auth/roles 携带唯一 roleCode
  2. 断言 HTTP 200、code=200、data 含新角色 ID
- **预期结果**：
  1. 角色创建成功
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_create`
- **测试过程与结论**：（待执行）

#### TC-API-041：创建角色-编码重复（P2）
- **用例ID**：TC-API-041
- **用例名称**：租户内角色编码重复返回 409
- **所属模块**：角色管理接口（API-021）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：roleCode=SUPER_ADMIN（已存在）
- **测试步骤**：
  1. POST /api/v1/auth/roles 使用已存在 roleCode
  2. 断言 HTTP 409
- **预期结果**：
  1. 返回资源冲突，不创建角色
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_create_duplicate_code`
- **测试过程与结论**：（待执行）

#### TC-API-042：更新角色（P2）
- **用例ID**：TC-API-042
- **用例名称**：更新角色信息
- **所属模块**：角色管理接口（API-022）
- **优先级**：P2
- **前置条件**：管理员已登录；存在测试角色
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：roleName=更新后的角色名
- **测试步骤**：
  1. PUT /api/v1/auth/roles/{id} 携带 roleName
  2. 断言 HTTP 200、code=200、data 反映更新
- **预期结果**：
  1. 角色更新成功
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_update`
- **测试过程与结论**：（待执行）

#### TC-API-043：删除角色（P2）
- **用例ID**：TC-API-043
- **用例名称**：逻辑删除未分配角色
- **所属模块**：角色管理接口（API-023）
- **优先级**：P2
- **前置条件**：管理员已登录；存在未分配测试角色
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：DELETE /api/v1/auth/roles/{id}
- **测试步骤**：
  1. DELETE /api/v1/auth/roles/{id}
  2. 断言 HTTP 200、code=200
  3. 角色详情断言不可查
- **预期结果**：
  1. 删除成功（逻辑删除）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_delete`
- **测试过程与结论**：（待执行）

#### TC-API-044：删除已分配角色被阻止（P2）
- **用例ID**：TC-API-044
- **用例名称**：删除已被分配角色返回 409
- **所属模块**：角色管理接口（API-023）
- **优先级**：P2
- **前置条件**：管理员已登录；存在已分配给用户的角色（如 SUPER_ADMIN）
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：DELETE /api/v1/auth/roles/{已分配角色ID}
- **测试步骤**：
  1. DELETE /api/v1/auth/roles/{id}
  2. 断言 HTTP 409
- **预期结果**：
  1. 返回"角色已被分配，阻止删除"
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_delete_in_use`
- **测试过程与结论**：（待执行）

#### TC-API-045：分配角色权限（P1）
- **用例ID**：TC-API-045
- **用例名称**：全量分配角色权限
- **所属模块**：角色管理接口（API-024）
- **优先级**：P1
- **前置条件**：管理员已登录；测试角色与权限存在
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：permissionIds=[201,202]
- **测试步骤**：
  1. PUT /api/v1/auth/roles/{id}/permissions 携带 permissionIds
  2. 断言 HTTP 200、code=200
- **预期结果**：
  1. 权限分配成功（先删后插）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_role_assign_permissions`
- **测试过程与结论**：（待执行）

#### TC-API-046：树形权限列表（P1）
- **用例ID**：TC-API-046
- **用例名称**：获取树形权限列表
- **所属模块**：权限管理接口（API-025）
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：GET /api/v1/auth/permissions/tree
- **测试步骤**：
  1. GET /api/v1/auth/permissions/tree
  2. 断言 HTTP 200、code=200、data 为树形数组
  3. 断言根节点含 children 子节点
- **预期结果**：
  1. 权限按 parentId 正确嵌套组织
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_tree`
- **测试过程与结论**：（待执行）

#### TC-API-047：所有权限列表（P2）
- **用例ID**：TC-API-047
- **用例名称**：获取平铺权限列表
- **所属模块**：权限管理接口（API-026）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：GET /api/v1/auth/permissions/list
- **测试步骤**：
  1. GET /api/v1/auth/permissions/list
  2. 断言 HTTP 200、code=200、data 为数组
- **预期结果**：
  1. 返回权限平铺列表
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_list`
- **测试过程与结论**：（待执行）

#### TC-API-048：权限详情（P2）
- **用例ID**：TC-API-048
- **用例名称**：查询权限详情
- **所属模块**：权限管理接口（API-027）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：GET /api/v1/auth/permissions/{permId}
- **测试步骤**：
  1. GET /api/v1/auth/permissions/{id}
  2. 断言 HTTP 200、code=200、data 含 permCode
- **预期结果**：
  1. 返回权限详情；不存在返回 404
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_detail`
- **测试过程与结论**：（待执行）

#### TC-API-049：创建权限（P1）
- **用例ID**：TC-API-049
- **用例名称**：创建权限成功（HTTP 201）
- **所属模块**：权限管理接口（API-028）
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：permCode=test:perm_{uuid}、permName=测试权限、parentId=0、type=2、sort=1
- **测试步骤**：
  1. POST /api/v1/auth/permissions 携带唯一 permCode
  2. 断言 HTTP 201、code=200、data 含新权限 ID
- **预期结果**：
  1. 权限创建成功
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_create`
- **测试过程与结论**：（待执行）

#### TC-API-050：创建权限-编码重复（P2）
- **用例ID**：TC-API-050
- **用例名称**：权限编码全局重复返回 409
- **所属模块**：权限管理接口（API-028）
- **优先级**：P2
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：permCode=user:list（已存在）
- **测试步骤**：
  1. POST /api/v1/auth/permissions 使用已存在 permCode
  2. 断言 HTTP 409
- **预期结果**：
  1. 返回资源冲突，不创建权限
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_create_duplicate_code`
- **测试过程与结论**：（待执行）

#### TC-API-051：更新权限（P2）
- **用例ID**：TC-API-051
- **用例名称**：更新权限信息
- **所属模块**：权限管理接口（API-029）
- **优先级**：P2
- **前置条件**：管理员已登录；存在测试权限
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：permName=更新后权限名、sort=4
- **测试步骤**：
  1. PUT /api/v1/auth/permissions/{id} 携带更新字段
  2. 断言 HTTP 200、code=200、data 反映更新
- **预期结果**：
  1. 权限更新成功
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_update`
- **测试过程与结论**：（待执行）

#### TC-API-052：删除权限（P2）
- **用例ID**：TC-API-052
- **用例名称**：逻辑删除未关联权限
- **所属模块**：权限管理接口（API-030）
- **优先级**：P2
- **前置条件**：管理员已登录；存在未关联测试权限
- **测试类型**：接口测试
- **关联需求ID**：F-004
- **测试数据**：DELETE /api/v1/auth/permissions/{id}
- **测试步骤**：
  1. DELETE /api/v1/auth/permissions/{id}
  2. 断言 HTTP 200、code=200
  3. 权限详情断言不可查；已被角色关联的权限删除返回 409
- **预期结果**：
  1. 删除成功（逻辑删除）；被引用权限阻止删除
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_permission_delete`
- **测试过程与结论**：（待执行）

### 模块：健康检查与通用鉴权（接口测试）

#### TC-API-053：认证服务健康检查（P1）
- **用例ID**：TC-API-053
- **用例名称**：认证服务健康检查
- **所属模块**：健康检查（API-031）
- **优先级**：P1
- **前置条件**：网关与认证服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-014
- **测试数据**：GET /api/v1/auth/health
- **测试步骤**：
  1. GET /api/v1/auth/health（无需 Token）
  2. 断言 HTTP 200、code=200、data.service=cloudoffice-auth-service、data.status=UP
- **预期结果**：
  1. 健康检查通过，服务名/状态/版本/时间戳字段齐全
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_health_auth`
- **测试过程与结论**：（待执行）

#### TC-API-054：企业服务健康检查（P2）
- **用例ID**：TC-API-054
- **用例名称**：企业服务健康检查
- **所属模块**：健康检查（API-032）
- **优先级**：P2
- **前置条件**：网关与企业服务（9200）已启动
- **测试类型**：接口测试
- **关联需求ID**：F-015
- **测试数据**：GET /api/v1/biz/health
- **测试步骤**：
  1. GET /api/v1/biz/health
  2. 断言 HTTP 200、code=200、data.service=cloudoffice-biz-service
- **预期结果**：
  1. 健康检查通过，服务名正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_health_biz`
- **测试过程与结论**：（待执行）

#### TC-API-055：系统服务健康检查（P2）
- **用例ID**：TC-API-055
- **用例名称**：系统服务健康检查
- **所属模块**：健康检查（API-033）
- **优先级**：P2
- **前置条件**：网关与系统服务（9400）已启动
- **测试类型**：接口测试
- **关联需求ID**：F-016
- **测试数据**：GET /api/v1/system/health
- **测试步骤**：
  1. GET /api/v1/system/health
  2. 断言 HTTP 200、code=200、data.service=cloudoffice-system-service
- **预期结果**：
  1. 健康检查通过，服务名正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_health_system`
- **测试过程与结论**：（待执行）

#### TC-API-056：未携带 Token 访问受保护接口（P0）
- **用例ID**：TC-API-056
- **用例名称**：无 Token 访问受保护接口返回 401
- **所属模块**：通用鉴权（F-006）
- **优先级**：P0
- **前置条件**：网关与认证服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-006
- **测试数据**：GET /api/v1/auth/users 不带 Authorization 头
- **测试步骤**：
  1. 不带 Token 请求受保护接口
  2. 断言 HTTP 401
- **预期结果**：
  1. 网关拦截返回 401（未授权）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_unauthorized_access`
- **测试过程与结论**：（待执行）

#### TC-API-057：非管理员访问管理接口（P1）
- **用例ID**：TC-API-057
- **用例名称**：普通用户访问管理接口返回 AUTH-0016
- **所属模块**：通用鉴权（F-004 / F-006）
- **优先级**：P1
- **前置条件**：普通测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / F-006
- **测试数据**：普通账号 Token 请求 GET /api/v1/auth/users
- **测试步骤**：
  1. 普通账号 Token GET /api/v1/auth/users
  2. 断言 HTTP 403、业务码 AUTH-0016
- **预期结果**：
  1. 权限不足被拒绝
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.0.1.py` 的 `test_admin_api_forbidden`
- **测试过程与结论**：（待执行）

### 模块：Flutter 客户端认证模块 - 功能/UI 测试（F-017）

#### TC-FUNC-001：登录页 UI 与登录流程（P0）
- **用例ID**：TC-FUNC-001
- **用例名称**：登录页 UI 与用户名密码登录流程
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P0
- **前置条件**：Flutter 客户端可运行（模拟器/真机/H5）；后端服务与网关已启动
- **测试类型**：功能测试 / UI测试
- **关联需求ID**：F-017 / F-001
- **测试数据**：登录名 admin、密码 admin123、租户 default、客户端类型（Android/iOS/H5 等）
- **测试步骤**：
  1. 打开登录页 `lib/features/auth/screens/login_screen.dart`
  2. 校验页面元素（登录名/密码输入框、登录按钮、注册入口、忘记密码入口）
  3. 输入正确凭证点击登录
  4. 断言跳转主页并展示用户信息
- **预期结果**：
  1. 页面元素完整、布局正常
  2. 登录成功进入主界面，Token 已安全存储
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行，后续版本补充自动化脚本）
- **测试过程与结论**：（待执行）

#### TC-FUNC-002：登录页输入校验（P1）
- **用例ID**：TC-FUNC-002
- **用例名称**：登录页输入校验（空值/格式）
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P1
- **前置条件**：同 TC-FUNC-001
- **测试类型**：功能测试 / UI测试
- **关联需求ID**：F-017
- **测试数据**：空登录名、短密码、非法手机号、非法邮箱
- **测试步骤**：
  1. 空登录名/密码点击登录，断言校验提示
  2. 密码强度不达标时断言提示（密码 8-64 位）
  3. 手机验证码模式输入非法手机号断言格式提示
- **预期结果**：
  1. 各非法输入在提交前被 `lib/core/utils/validators.dart` 拦截并提示
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-003：注册页 UI 与注册流程（P1）
- **用例ID**：TC-FUNC-003
- **用例名称**：注册页 UI 与用户名密码注册流程
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P1
- **前置条件**：同 TC-FUNC-001
- **测试类型**：功能测试 / UI测试
- **关联需求ID**：F-017 / F-002
- **测试数据**：新登录名、Password123、用户姓名
- **测试步骤**：
  1. 从登录页进入注册页 `register_screen.dart`
  2. 输入注册信息提交
  3. 断言注册成功自动登录进入系统
- **预期结果**：
  1. 注册成功返回用户信息并进入系统
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-004：找回密码页 UI 与重置流程（P2）
- **用例ID**：TC-FUNC-004
- **用例名称**：找回密码页 UI 与验证码重置流程
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P2
- **前置条件**：同 TC-FUNC-001
- **测试类型**：功能测试 / UI测试
- **关联需求ID**：F-017 / F-009
- **测试数据**：已绑定手机号/邮箱、验证码、新密码
- **测试步骤**：
  1. 从登录页进入忘记密码页 `forgot_password_screen.dart`
  2. 输入目标与验证码，设置新密码提交
  3. 断言提示成功并可跳转登录页用新密码登录
- **预期结果**：
  1. 重置成功，流程引导清晰
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-005：ApiInterceptor Token 注入与 401 自动刷新（P0）
- **用例ID**：TC-FUNC-005
- **用例名称**：Token 注入与 401 自动刷新重试
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P0
- **前置条件**：客户端已登录（Token 已存储）
- **测试类型**：功能测试
- **关联需求ID**：F-017 / F-007 / F-008
- **测试数据**：已登录会话、模拟 Access Token 过期
- **测试步骤**：
  1. 发起受保护接口请求，断言 `ApiInterceptor` 自动注入 `Authorization: Bearer`
  2. 模拟 Access Token 过期（服务端或拦截器强制 401）
  3. 断言拦截器自动调用刷新接口并用新 Token 重试原请求
  4. 断言刷新失败时跳转登录页
- **预期结果**：
  1. 请求自动携带 Token；401 时自动刷新并重试；刷新失败回登录页
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-006：Token 安全存储（P1）
- **用例ID**：TC-FUNC-006
- **用例名称**：Token 安全存储（SecureStorage）
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P1
- **前置条件**：客户端已登录
- **测试类型**：功能测试
- **关联需求ID**：F-017 / F-007
- **测试数据**：登录后 Token 对
- **测试步骤**：
  1. 登录成功后断言 Token 写入 `lib/core/storage/secure_storage.dart`
  2. 检查存储介质断言使用系统安全存储（Keychain/Keystore），禁止明文落盘（SharedPreferences）
  3. 重启客户端断言 Token 仍可读取（登录态保持）
- **预期结果**：
  1. Token 仅存于安全存储，重启后登录态保持
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-007：登录态保持与退出登录（P1）
- **用例ID**：TC-FUNC-007
- **用例名称**：登录态保持与退出登录
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P1
- **前置条件**：客户端已登录
- **测试类型**：功能测试
- **关联需求ID**：F-017 / F-008
- **测试数据**：已登录会话
- **测试步骤**：
  1. 重启客户端断言免登录进入系统
  2. 点击退出登录，断言调用登出接口并清除本地 Token
  3. 重新打开断言回登录页
- **预期结果**：
  1. 重启保持登录；退出后本地 Token 清除并回登录页
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-008：同端互斥与多端共存体验（P2）
- **用例ID**：TC-FUNC-008
- **用例名称**：同端互斥与多端共存客户端体验
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P2
- **前置条件**：两台设备或同一设备不同客户端类型（如 Android + H5）
- **测试类型**：功能测试
- **关联需求ID**：F-008
- **测试数据**：同账号不同客户端类型
- **测试步骤**：
  1. 同账号在 Android 端登录后，再次在 Android 端登录，断言旧会话被顶掉（触发被踢提示）
  2. 同账号在 Android + H5 分别登录，断言两端会话共存
- **预期结果**：
  1. 同端互斥（旧会话提示被踢下线），多端共存互不影响
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

#### TC-FUNC-009：验证码组件与倒计时（P2）
- **用例ID**：TC-FUNC-009
- **用例名称**：验证码输入组件与发送倒计时
- **所属模块**：Flutter 客户端认证模块（F-017）
- **优先级**：P2
- **前置条件**：客户端可运行
- **测试类型**：UI测试
- **关联需求ID**：F-017 / F-011
- **测试数据**：目标手机号/邮箱
- **测试步骤**：
  1. 在注册/找回页面点击发送验证码
  2. 断言验证码框组件 `lib/shared/widgets/verification_code_field.dart` 出现
  3. 断言发送按钮进入 60 秒倒计时且不可重复点击
- **预期结果**：
  1. 验证码组件正常，倒计时生效，60 秒内不可重复发送
- **自动化测试函数/脚本位置**：（功能/UI 测试手工执行）
- **测试过程与结论**：（待执行）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 |  |
| 失败 |  |
| 阻塞 |  |
| 跳过 |  |

> 说明：单元测试（TC-UNIT-001~015）引用已有 15 个测试类共 206 个测试方法，执行方式 `cd cloudoffice-auth-service && mvn test`；接口测试（TC-API-001~057）执行方式 `python scripts/API-TEST/cso-api-test-v0.0.1.py`；功能/UI 测试（TC-FUNC-001~009）由测试工程师手工执行并记录。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 验证码为模拟发送模式（VERIFICATION_CODE_MOCK=true），接口测试依赖开发环境控制台获取验证码 | 自动化脚本无法完全闭环验证码流程 | 开发环境模拟模式返回可读验证码；生产环境验证码用例降级为人工执行 |
| 接口测试需真实启动网关（9000）+ 认证服务（9100）+ 数据库/Redis | 测试环境未就绪时接口用例阻塞 | 提供 docker-compose 一键启动；接口脚本支持 `--skip` 参数跳过依赖用例 |
| 改密/重置密码/封禁类用例会修改测试账号状态 | 用例间存在状态依赖 | 脚本为每个用例创建独立测试账号（uuid 命名），用例间不共享状态 |
| 功能/UI 测试依赖 Flutter 设备环境 | 手工测试成本高 | 本版本按手工执行记录，后续版本引入 flutter_test 集成测试 |
| 网关 AuthFilter 9 步校验为网关侧逻辑 | 单元测试无法覆盖 | 通过接口测试（401/403 场景）补充集成验证 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
