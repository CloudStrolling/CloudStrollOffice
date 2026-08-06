# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.0.1
**日期**：2026-08-06
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 认证服务 - 注册功能（F-002/F-003） | T-注册 | 4 | P0×2、P1×2 |
| 认证服务 - 登录功能（F-001） | T-登录 | 6 | P0×3、P1×3 |
| 认证服务 - Token 与会话（F-004/F-006） | T-Token | 4 | P0×4 |
| 认证服务 - 登出与踢人（F-016） | T-登出 | 4 | P0×2、P1×2 |
| 认证服务 - 验证码（F-015） | T-验证码 | 4 | P0×2、P1×2 |
| 认证服务 - 密码管理（F-013） | T-密码 | 4 | P0×4 |
| 认证服务 - 手机号变更（F-014） | T-手机号 | 1 | P0×1 |
| 认证服务 - 两步注册补全（F-003） | T-补全 | 1 | P1×1 |
| 认证服务 - 用户管理（F-010） | T-用户 | 5 | P0×3、P1×2 |
| 认证服务 - 角色管理（F-011） | T-角色 | 4 | P0×2、P1×2 |
| 认证服务 - 权限管理（F-012） | T-权限 | 3 | P0×1、P1×2 |
| API 网关 - 认证拦截（F-005） | T-网关 | 3 | P0×3 |
| 认证服务 - 多租户隔离（F-008） | T-多租户 | 1 | P0×1 |
| 全部服务 - 健康检查（F-020） | T-健康 | 1 | P0×1 |
| **合计** |  | **45** | **P0×29、P1×16** |

## 二、测试用例详情
### 模块：注册功能 - 多模式注册（5 种模式）与唯一性校验
#### TC-001：用户名密码注册成功（P0）
- **用例ID**：TC-001
- **用例名称**：用户名密码注册成功
- **所属模块**：认证服务 - 注册功能
- **优先级**：P0
- **前置条件**：默认租户 DEFAULT 有效且启用；注册接口开放；模拟验证码模式（VERIFICATION_CODE_MOCK=true）
- **测试类型**：接口测试
- **关联需求ID**：US-005
- **测试数据**：registerMode=USERNAME_PASSWORD，tenantCode=DEFAULT，clientType=H5，loginName=唯一用户名（uuid），password=Pass@1234（8~64 位），userName=测试用户
- **测试步骤**：
  1. 调用 POST /api/v1/auth/register 提交注册请求
  2. 使用注册的用户名密码调用 POST /api/v1/auth/login 登录
- **预期结果**：
  1. 注册接口返回 code=0，data.userId 非空、data.registerMode=USERNAME_PASSWORD、data.accountComplete=true
  2. 登录成功返回双 Token（accessToken/refreshToken 非空，tokenType=Bearer，expiresIn=7200，refreshExpiresIn=604800）
- **自动化测试函数/脚本位置**：test_tc001_register_username_password() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-002：手机验证码注册成功（P0）
- **用例ID**：TC-002
- **用例名称**：手机验证码注册成功
- **所属模块**：认证服务 - 注册功能
- **优先级**：P0
- **前置条件**：默认租户有效；手机号租户内未被占用；验证码通道可用（模拟模式返回 mockCode）
- **测试类型**：接口测试
- **关联需求ID**：US-006
- **测试数据**：registerMode=PHONE_CODE，phone=13x+uuid 后 8 位，code=模拟模式验证码（123456 或接口返回），purpose=REGISTER
- **测试步骤**：
  1. 调用 POST /api/v1/auth/verification-code/send（purpose=REGISTER）获取验证码
  2. 调用 POST /api/v1/auth/register（registerMode=PHONE_CODE）提交注册
  3. 使用手机号+密码（或验证码登录）验证账号可登录
- **预期结果**：
  1. 发送验证码返回 code=0，data.mockCode=123456（模拟模式）
  2. 注册返回 code=0，data.userId 非空，账号绑定该手机号
  3. 新账号登录成功
- **自动化测试函数/脚本位置**：test_tc002_register_phone_code() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-003：OAuth 注册进入两步注册（P1）
- **用例ID**：TC-003
- **用例名称**：OAuth 注册进入两步注册
- **所属模块**：认证服务 - 注册功能
- **优先级**：P1
- **前置条件**：OAuth 策略可用（模拟 OAuth 回调或第三方凭证已配置）；默认租户有效
- **测试类型**：接口测试
- **关联需求ID**：US-003、US-007
- **测试数据**：registerMode=OAUTH，oauthProvider=WECHAT，oauthCode=模拟授权码（uuid）
- **测试步骤**：
  1. 调用 POST /api/v1/auth/register（registerMode=OAUTH）提交注册
  2. 检查响应 accountComplete 标记
- **预期结果**：
  1. 注册返回 code=0，data.userId 非空
  2. OAuth 信息不完整时 data.accountComplete=false，进入两步注册（需后续补全）；重复相同 oauthCode 幂等不重复创建账号
- **自动化测试函数/脚本位置**：test_tc003_register_oauth() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-004：注册异常-用户名重复与参数非法（P1）
- **用例ID**：TC-004
- **用例名称**：注册异常-用户名重复与参数非法
- **所属模块**：认证服务 - 注册功能
- **优先级**：P1
- **前置条件**：默认租户有效；已存在用户（admin）
- **测试类型**：接口测试
- **关联需求ID**：US-005
- **测试数据**：重复登录名=admin；非法参数：loginName=ab（过短）、password=123（不足 8 位）
- **测试步骤**：
  1. 使用已占用用户名 admin 调用注册接口
  2. 使用过短用户名/弱密码调用注册接口
- **预期结果**：
  1. 用户名重复返回 409（AUTH-0013 用户名已被占用）
  2. 参数非法返回 400（PARAM-0001 参数校验失败）
- **自动化测试函数/脚本位置**：test_tc004_register_duplicate_and_invalid() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：登录功能 - 4 种登录模式与失败防护
#### TC-005：用户名密码登录成功签发双 Token（P0）
- **用例ID**：TC-005
- **用例名称**：用户名密码登录成功签发双 Token
- **所属模块**：认证服务 - 登录功能
- **优先级**：P0
- **前置条件**：默认租户有效；账号存在且启用（admin/admin123 或测试注册账号）
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：loginMode=USERNAME_PASSWORD，loginName=测试账号，password=正确密码，tenantCode=DEFAULT，clientType=H5
- **测试步骤**：
  1. 调用 POST /api/v1/auth/login 提交登录请求
  2. 校验响应 Token 与用户信息
- **预期结果**：
  1. 返回 code=0，data.accessToken/refreshToken 非空，tokenType=Bearer，expiresIn=7200，refreshExpiresIn=604800
  2. data.userInfo 含 userId/userName/loginName/tenantCode/roles
- **自动化测试函数/脚本位置**：test_tc005_login_username_password() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-006：密码错误登录失败且防枚举提示（P0）
- **用例ID**：TC-006
- **用例名称**：密码错误登录失败且防枚举提示
- **所属模块**：认证服务 - 登录功能
- **优先级**：P0
- **前置条件**：账号存在
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：loginMode=USERNAME_PASSWORD，loginName=admin，password=Wrong@123
- **测试步骤**：
  1. 使用错误密码调用登录接口
  2. 使用不存在的用户名调用登录接口
- **预期结果**：
  1. 两次均返回 401（AUTH-0005 用户名或密码错误），提示文案一致不区分"用户不存在/密码错误"（防枚举）
  2. 响应不泄露密码与内部细节
- **自动化测试函数/脚本位置**：test_tc006_login_wrong_password_anti_enum() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-007：手机验证码登录（正确码成功/错误码拒绝）（P0）
- **用例ID**：TC-007
- **用例名称**：手机验证码登录（正确码成功/错误码拒绝）
- **所属模块**：认证服务 - 登录功能
- **优先级**：P0
- **前置条件**：账号已绑定手机号；验证码通道可用
- **测试类型**：接口测试
- **关联需求ID**：US-002
- **测试数据**：loginMode=PHONE_CODE，phone=已绑定手机号，code=正确验证码/错误验证码 000000
- **测试步骤**：
  1. 发送登录验证码（purpose=LOGIN）并取 mockCode
  2. 携带正确验证码调用登录接口
  3. 携带错误验证码调用登录接口
- **预期结果**：
  1. 正确验证码登录成功，返回双 Token
  2. 错误验证码返回 422（AUTH-0009 验证码错误或已过期）
- **自动化测试函数/脚本位置**：test_tc007_login_phone_code() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-008：手机+密码登录成功（P1）
- **用例ID**：TC-008
- **用例名称**：手机+密码登录成功
- **所属模块**：认证服务 - 登录功能
- **优先级**：P1
- **前置条件**：账号已绑定手机号且密码已知
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：loginMode=PHONE_PASSWORD，phone=已绑定手机号，password=正确密码
- **测试步骤**：
  1. 调用登录接口（loginMode=PHONE_PASSWORD）
- **预期结果**：
  1. 返回 code=0 并签发双 Token
- **自动化测试函数/脚本位置**：test_tc008_login_phone_password() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-009：禁用账号/租户登录被拒（P0）
- **用例ID**：TC-009
- **用例名称**：禁用账号/租户登录被拒
- **所属模块**：认证服务 - 登录功能
- **优先级**：P0
- **前置条件**：管理员账号可登录；存在普通测试账号；租户禁用场景需预置禁用租户（无则跳过）
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：禁用状态 status=0 的测试账号；禁用租户编码（预置）
- **测试步骤**：
  1. 管理员将测试账号禁用（PUT /users/{id}/status status=0）
  2. 使用被禁用账号调用登录接口
  3. （租户禁用场景）使用禁用租户编码调用登录接口
- **预期结果**：
  1. 禁用账号登录返回 403（AUTH-0006 账号已被禁用）
  2. 禁用租户登录返回 403（AUTH-0007 租户已被禁用）
- **自动化测试函数/脚本位置**：test_tc009_login_disabled() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-010：登录模式/客户端类型非法被拒（P1）
- **用例ID**：TC-010
- **用例名称**：登录模式/客户端类型非法被拒
- **所属模块**：认证服务 - 登录功能
- **优先级**：P1
- **前置条件**：账号存在
- **测试类型**：接口测试
- **关联需求ID**：US-001、US-004
- **测试数据**：loginMode=UNKNOWN_MODE；clientType=TV（非法值）
- **测试步骤**：
  1. 使用不支持的 loginMode 调用登录接口
  2. 使用非法 clientType 调用登录接口
- **预期结果**：
  1. 登录模式不支持返回 400（AUTH-0016 登录模式不支持）
  2. 客户端类型非法返回 400（AUTH-0018 客户端类型非法）
- **自动化测试函数/脚本位置**：test_tc010_login_invalid_mode_client() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：Token 与会话 - 刷新轮换、同端互斥、多端共存
#### TC-011：Token 刷新成功换发新双 Token（P0）
- **用例ID**：TC-011
- **用例名称**：Token 刷新成功换发新双 Token
- **所属模块**：认证服务 - Token 与会话
- **优先级**：P0
- **前置条件**：账号已登录持有有效 Refresh Token
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：refreshToken=有效 Refresh Token，clientType=H5
- **测试步骤**：
  1. 登录获取 Refresh Token
  2. 调用 POST /api/v1/auth/refresh 刷新
- **预期结果**：
  1. 返回 code=0，新 data.accessToken/refreshToken 非空，expiresIn=7200
  2. 新 Access Token 可正常访问受保护接口
- **自动化测试函数/脚本位置**：test_tc011_refresh_success() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-012：刷新轮换后旧 Refresh Token 失效（P0）
- **用例ID**：TC-012
- **用例名称**：刷新轮换后旧 Refresh Token 失效
- **所属模块**：认证服务 - Token 与会话
- **优先级**：P0
- **前置条件**：账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-001
- **测试数据**：refreshToken=首次登录的 Refresh Token
- **测试步骤**：
  1. 使用 Refresh Token 刷新一次（成功）
  2. 再次使用同一个旧 Refresh Token 刷新
- **预期结果**：
  1. 第一次刷新返回 code=0
  2. 第二次刷新（旧 Refresh 重放）返回 401（AUTH-0003 访问凭证已被注销/黑名单）
- **自动化测试函数/脚本位置**：test_tc012_refresh_rotation() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-013：同端互斥-同客户端新登录踢旧会话（P0）
- **用例ID**：TC-013
- **用例名称**：同端互斥-同客户端新登录踢旧会话
- **所属模块**：认证服务 - Token 与会话
- **优先级**：P0
- **前置条件**：账号可登录
- **测试类型**：接口测试
- **关联需求ID**：US-004
- **测试数据**：同一账号分别以 clientType=H5 登录两次
- **测试步骤**：
  1. 账号以 H5 登录，保存 token1
  2. 账号再次以 H5 登录，保存 token2
  3. 使用 token1、token2 分别访问受保护接口
- **预期结果**：
  1. token2 访问成功（200）
  2. token1 访问返回 401（旧会话已被踢出）
- **自动化测试函数/脚本位置**：test_tc013_same_client_mutex() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-014：多端共存-不同客户端类型同时在线（P0）
- **用例ID**：TC-014
- **用例名称**：多端共存-不同客户端类型同时在线
- **所属模块**：认证服务 - Token 与会话
- **优先级**：P0
- **前置条件**：账号可登录
- **测试类型**：接口测试
- **关联需求ID**：US-004
- **测试数据**：同一账号分别以 clientType=H5、Android 登录
- **测试步骤**：
  1. 账号以 H5 登录，保存 token1
  2. 账号以 Android 登录，保存 token2
  3. 分别使用 token1、token2 访问受保护接口
- **预期结果**：
  1. token1 访问成功（200）
  2. token2 访问成功（200），两会话共存
- **自动化测试函数/脚本位置**：test_tc014_multi_client_coexist() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：登出与踢人 - 主动登出、幂等、强制踢人
#### TC-015：主动登出后 Token 失效（P0）
- **用例ID**：TC-015
- **用例名称**：主动登出后 Token 失效
- **所属模块**：认证服务 - 登出与踢人
- **优先级**：P0
- **前置条件**：账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-015
- **测试数据**：accessToken/refreshToken=登录返回的 Token 对
- **测试步骤**：
  1. 登录获取 Token 对
  2. 调用 POST /api/v1/auth/logout（携带 Authorization + body.refreshToken）
  3. 使用登出后的 accessToken 访问受保护接口
  4. 使用登出后的 refreshToken 调用刷新接口
- **预期结果**：
  1. 登出返回 code=0
  2. 登出后 accessToken 访问返回 401（AUTH-0003 黑名单）
  3. 登出后 refreshToken 刷新返回 401（AUTH-0004 刷新凭证无效）
- **自动化测试函数/脚本位置**：test_tc015_logout_invalidates_token() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-016：重复登出幂等（P1）
- **用例ID**：TC-016
- **用例名称**：重复登出幂等
- **所属模块**：认证服务 - 登出与踢人
- **优先级**：P1
- **前置条件**：账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-015
- **测试数据**：同一 accessToken/refreshToken 重复调用登出
- **测试步骤**：
  1. 调用登出接口
  2. 再次调用登出接口（同一 Token）
- **预期结果**：
  1. 两次登出均返回 code=0（幂等，不报错）
- **自动化测试函数/脚本位置**：test_tc016_logout_idempotent() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-017：管理员强制踢人后登录态失效（P0）
- **用例ID**：TC-017
- **用例名称**：管理员强制踢人后登录态失效
- **所属模块**：认证服务 - 登出与踢人
- **优先级**：P0
- **前置条件**：管理员账号可登录（admin/admin123）；普通测试账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-015
- **测试数据**：管理员 Token；被踢用户 userId 与 Token
- **测试步骤**：
  1. 普通用户登录获取 Token
  2. 管理员调用 POST /api/v1/auth/kickout（body.userId=普通用户 ID）
  3. 普通用户使用原 Token 访问受保护接口
- **预期结果**：
  1. 踢人返回 code=0
  2. 被踢用户原 Token 访问返回 401（登录态实时失效）
- **自动化测试函数/脚本位置**：test_tc017_kickout() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-018：非管理员踢人被拒（P1）
- **用例ID**：TC-018
- **用例名称**：非管理员踢人被拒
- **所属模块**：认证服务 - 登出与踢人
- **优先级**：P1
- **前置条件**：两个普通测试账号
- **测试类型**：接口测试
- **关联需求ID**：US-015
- **测试数据**：普通用户 A 的 Token；普通用户 B 的 userId
- **测试步骤**：
  1. 普通用户 A 调用踢人接口（目标=B）
- **预期结果**：
  1. 返回 403（AUTH-0015 无权限执行该操作）
- **自动化测试函数/脚本位置**：test_tc018_kickout_forbidden() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：验证码 - 发送、频率控制、单次使用、用途绑定
#### TC-019：发送验证码成功-模拟模式返回 123456（P0）
- **用例ID**：TC-019
- **用例名称**：发送验证码成功-模拟模式返回 123456
- **所属模块**：认证服务 - 验证码
- **优先级**：P0
- **前置条件**：验证码功能开放；模拟模式 VERIFICATION_CODE_MOCK=true
- **测试类型**：接口测试
- **关联需求ID**：US-012
- **测试数据**：target=测试手机号（uuid），channel=SMS，purpose=REGISTER，tenantCode=DEFAULT
- **测试步骤**：
  1. 调用 POST /api/v1/auth/verification-code/send
- **预期结果**：
  1. 返回 code=0，data.mockCode=123456（模拟模式固定验证码）
- **自动化测试函数/脚本位置**：test_tc019_send_code_success() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-020：60 秒内重复发送验证码被拒（P0）
- **用例ID**：TC-020
- **用例名称**：60 秒内重复发送验证码被拒
- **所属模块**：认证服务 - 验证码
- **优先级**：P0
- **前置条件**：验证码功能开放
- **测试类型**：接口测试
- **关联需求ID**：US-012
- **测试数据**：同一 target/purpose 连续发送两次
- **测试步骤**：
  1. 调用发送验证码接口（第一次）
  2. 立即再次调用发送验证码接口（同一目标同一用途）
- **预期结果**：
  1. 第一次返回 code=0
  2. 第二次返回 429（AUTH-0010 验证码发送过于频繁）
- **自动化测试函数/脚本位置**：test_tc020_send_code_frequency() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-021：验证码单次使用-复用被拒（P1）
- **用例ID**：TC-021
- **用例名称**：验证码单次使用-复用被拒
- **所属模块**：认证服务 - 验证码
- **优先级**：P1
- **前置条件**：账号已绑定手机号；验证码通道可用
- **测试类型**：接口测试
- **关联需求ID**：US-002、US-012
- **测试数据**：手机号与登录验证码（purpose=LOGIN）
- **测试步骤**：
  1. 发送登录验证码并取 mockCode
  2. 使用该验证码登录（成功）
  3. 再次使用同一验证码登录
- **预期结果**：
  1. 第一次登录成功
  2. 第二次登录返回 422（AUTH-0009 验证码错误或已过期，单次有效）
- **自动化测试函数/脚本位置**：test_tc021_code_single_use() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-022：验证码用途不匹配被拒（P1）
- **用例ID**：TC-022
- **用例名称**：验证码用途不匹配被拒
- **所属模块**：认证服务 - 验证码
- **优先级**：P1
- **前置条件**：账号已绑定手机号；验证码通道可用
- **测试类型**：接口测试
- **关联需求ID**：US-012
- **测试数据**：purpose=REGISTER 的验证码用于 LOGIN 场景
- **测试步骤**：
  1. 发送 REGISTER 用途验证码（目标=已绑定手机号）并取 mockCode
  2. 使用该验证码调用 LOGIN 登录接口
- **预期结果**：
  1. 登录返回 422（AUTH-0011 验证码用途不匹配）
- **自动化测试函数/脚本位置**：test_tc022_code_purpose_mismatch() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：密码管理 - 修改密码、密码找回
#### TC-023：修改密码成功（P0）
- **用例ID**：TC-023
- **用例名称**：修改密码成功
- **所属模块**：认证服务 - 密码管理
- **优先级**：P0
- **前置条件**：账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-008
- **测试数据**：oldPassword=原密码，newPassword=New@54321（8~64 位且与旧密码不同）
- **测试步骤**：
  1. 调用 PUT /api/v1/auth/password/change（携带 Authorization）
  2. 使用新密码重新登录
- **预期结果**：
  1. 修改返回 code=0
  2. 新密码登录成功（旧登录态保持有效，与找回不同）
- **自动化测试函数/脚本位置**：test_tc023_change_password_success() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-024：修改密码旧密码错误被拒（P0）
- **用例ID**：TC-024
- **用例名称**：修改密码旧密码错误被拒
- **所属模块**：认证服务 - 密码管理
- **优先级**：P0
- **前置条件**：账号已登录
- **测试类型**：接口测试
- **关联需求ID**：US-008
- **测试数据**：oldPassword=WrongOld@123，newPassword=New@54321
- **测试步骤**：
  1. 调用修改密码接口（旧密码错误）
- **预期结果**：
  1. 返回 422（AUTH-0014 旧密码校验失败）
- **自动化测试函数/脚本位置**：test_tc024_change_password_wrong_old() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-025：密码找回发送验证码成功（P0）
- **用例ID**：TC-025
- **用例名称**：密码找回发送验证码成功
- **所属模块**：认证服务 - 密码管理
- **优先级**：P0
- **前置条件**：账号已绑定手机号
- **测试类型**：接口测试
- **关联需求ID**：US-009
- **测试数据**：target=已绑定手机号，channel=SMS
- **测试步骤**：
  1. 调用 POST /api/v1/auth/password/forgot/send-code
  2. 使用未绑定账号的目标调用（异常路径）
- **预期结果**：
  1. 已绑定目标返回 code=0，data.mockCode 非空（模拟模式）
  2. 未绑定目标返回 422（BIZ-0001 用户不存在）
- **自动化测试函数/脚本位置**：test_tc025_forgot_send_code() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-026：密码找回重置成功且旧 Token 失效（P0）
- **用例ID**：TC-026
- **用例名称**：密码找回重置成功且旧 Token 失效
- **所属模块**：认证服务 - 密码管理
- **优先级**：P0
- **前置条件**：账号已绑定手机号且已登录；验证码通道可用
- **测试类型**：接口测试
- **关联需求ID**：US-009
- **测试数据**：target=绑定手机号，channel=SMS，code=模拟验证码，newPassword=New@12345
- **测试步骤**：
  1. 发送找回验证码并取 mockCode
  2. 调用 POST /api/v1/auth/password/forgot/reset 重置密码
  3. 使用重置前登录的旧 Token 访问受保护接口
  4. 使用新密码重新登录
- **预期结果**：
  1. 重置返回 code=0
  2. 旧 Token 访问返回 401（全部登录态已清除）
  3. 新密码登录成功
  4. （异常路径）错误验证码重置返回 422（AUTH-0009）
- **自动化测试函数/脚本位置**：test_tc026_forgot_reset() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：手机号变更 - 原手机短信验证场景
#### TC-027：短信验证码变更手机号成功（含占用/不一致拒绝）（P0）
- **用例ID**：TC-027
- **用例名称**：短信验证码变更手机号成功（含占用/不一致拒绝）
- **所属模块**：认证服务 - 手机号变更
- **优先级**：P0
- **前置条件**：账号 A 绑定旧手机号并已登录；账号 B 绑定新手机号（占用校验用）；验证码通道可用
- **测试类型**：接口测试
- **关联需求ID**：US-010
- **测试数据**：scene=OLD_PHONE_SMS，oldPhone=旧手机号，newPhone=新手机号，code=发送至旧手机号的验证码
- **测试步骤**：
  1. 向旧手机号发送 PHONE_CHANGE 验证码并取 mockCode
  2. 调用 PUT /api/v1/auth/phone/change（正确参数）变更手机号
  3. 异常路径：oldPhone 与绑定不一致 → 拒绝；newPhone 已被账号 B 绑定 → 拒绝
- **预期结果**：
  1. 正确参数变更返回 code=0
  2. 原手机号不一致返回 400（PARAM-0001）
  3. 新手机号被占用返回 409（AUTH-0012 手机号已被其他账号绑定）
- **自动化测试函数/脚本位置**：test_tc027_change_phone() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：两步注册补全 - 账号完善
#### TC-028：两步注册账号补全（成功/已完善拒绝）（P1）
- **用例ID**：TC-028
- **用例名称**：两步注册账号补全（成功/已完善拒绝）
- **所属模块**：认证服务 - 两步注册补全
- **优先级**：P1
- **前置条件**：OAuth 策略可用（模拟授权码）；默认租户有效
- **测试类型**：接口测试
- **关联需求ID**：US-007
- **测试数据**：OAuth 注册返回的账号 Token；补全参数 loginName/password；普通完整账号 Token
- **测试步骤**：
  1. OAuth 模式注册账号（accountComplete=false），登录后调用 PUT /api/v1/auth/account/settlement 补全用户名/密码
  2. 使用已补全账号再次调用补全接口
- **预期结果**：
  1. 补全返回 code=0，data.accountComplete=true，补全后可用全部登录方式
  2. 已完善账号补全返回 400/422（拒绝重复补全）
- **自动化测试函数/脚本位置**：test_tc028_account_settlement() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：用户管理 - 分页、详情、更新、启禁用、角色分配
#### TC-029：用户分页查询（P0）
- **用例ID**：TC-029
- **用例名称**：用户分页查询
- **所属模块**：认证服务 - 用户管理
- **优先级**：P0
- **前置条件**：管理员已登录；租户内存在用户数据
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：pageNum=1，pageSize=10，keyword=admin，status 空
- **测试步骤**：
  1. 管理员调用 GET /api/v1/auth/users 查询
  2. 校验分页结构与字段脱敏
- **预期结果**：
  1. 返回 code=0，data.records 数组 + data.total/pageNum/pageSize
  2. 响应不含 password 字段，手机号/邮箱脱敏展示
- **自动化测试函数/脚本位置**：test_tc029_user_page_query() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-030：用户详情查询（P1）
- **用例ID**：TC-030
- **用例名称**：用户详情查询
- **所属模块**：认证服务 - 用户管理
- **优先级**：P1
- **前置条件**：管理员已登录；租户内存在用户
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：userId=分页结果中第一条用户 ID
- **测试步骤**：
  1. 管理员调用 GET /api/v1/auth/users/{userId}
  2. 调用不存在用户 ID（999999999）
- **预期结果**：
  1. 存在用户返回 code=0，data 含 userId/loginName/userName/roles/tenantCode，无 password 字段
  2. 不存在用户返回 422（BIZ-0001 用户不存在）
- **自动化测试函数/脚本位置**：test_tc030_user_detail() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-031：更新用户信息（P1）
- **用例ID**：TC-031
- **用例名称**：更新用户信息
- **所属模块**：认证服务 - 用户管理
- **优先级**：P1
- **前置条件**：管理员已登录；测试账号已注册
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：userName=更新测试，email=upd@example.com
- **测试步骤**：
  1. 管理员调用 PUT /api/v1/auth/users/{userId} 更新姓名与邮箱
  2. 查询详情核对更新结果
- **预期结果**：
  1. 更新返回 code=0，详情中 userName/email 已更新
- **自动化测试函数/脚本位置**：test_tc031_user_update() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-032：用户启禁用-登录态实时失效（P0）
- **用例ID**：TC-032
- **用例名称**：用户启禁用-登录态实时失效
- **所属模块**：认证服务 - 用户管理
- **优先级**：P0
- **前置条件**：管理员已登录；测试账号已注册并登录
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：status=0（禁用）
- **测试步骤**：
  1. 管理员调用 PUT /api/v1/auth/users/{userId}/status（status=0）
  2. 被禁用用户使用原 Token 访问受保护接口
  3. 被禁用用户重新登录
- **预期结果**：
  1. 禁用返回 code=0
  2. 原 Token 访问返回 403（AUTH-0006 账号已被禁用）
  3. 重新登录返回 403（禁用状态）
- **自动化测试函数/脚本位置**：test_tc032_user_status_disable() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-033：分配用户角色（P0）
- **用例ID**：TC-033
- **用例名称**：分配用户角色
- **所属模块**：认证服务 - 用户管理
- **优先级**：P0
- **前置条件**：管理员已登录；测试账号已注册；租户内存在角色
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：roleIds=角色列表中的角色 ID
- **测试步骤**：
  1. 管理员查询角色列表获取 roleId
  2. 调用 PUT /api/v1/auth/users/{userId}/roles 分配角色
  3. 查询用户详情核对角色
- **预期结果**：
  1. 分配返回 code=0
  2. 用户详情 roles 包含分配的角色编码
- **自动化测试函数/脚本位置**：test_tc033_user_assign_roles() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：角色管理 - CRUD 与权限分配
#### TC-034：创建角色成功（P0）
- **用例ID**：TC-034
- **用例名称**：创建角色成功
- **所属模块**：认证服务 - 角色管理
- **优先级**：P0
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：roleCode=TEST_ROLE_+uuid，roleName=自动化测试角色，tenantId=1
- **测试步骤**：
  1. 管理员调用 POST /api/v1/auth/roles 创建角色
- **预期结果**：
  1. 返回 code=0，data 含角色 id 且 roleCode 一致
- **自动化测试函数/脚本位置**：test_tc034_role_create() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-035：角色编码租户内重复被拒（P1）
- **用例ID**：TC-035
- **用例名称**：角色编码租户内重复被拒
- **所属模块**：认证服务 - 角色管理
- **优先级**：P1
- **前置条件**：管理员已登录；SUPER_ADMIN 角色已存在
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：roleCode=SUPER_ADMIN（已存在）
- **测试步骤**：
  1. 管理员调用创建角色接口（roleCode=SUPER_ADMIN）
- **预期结果**：
  1. 返回 409（角色编码租户内重复）
- **自动化测试函数/脚本位置**：test_tc035_role_duplicate_code() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-036：删除角色-被引用不可删（P1）
- **用例ID**：TC-036
- **用例名称**：删除角色-被引用不可删
- **所属模块**：认证服务 - 角色管理
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：新建临时角色 roleId；SUPER_ADMIN 角色 ID（被 admin 引用）
- **测试步骤**：
  1. 创建临时角色后调用 DELETE /api/v1/auth/roles/{roleId} 删除（未被引用）
  2. 调用 DELETE 删除 SUPER_ADMIN（被引用）
- **预期结果**：
  1. 未引用角色删除返回 code=0，删除后详情 404
  2. 被引用角色删除返回 409（存在关联用户不可删除）
- **自动化测试函数/脚本位置**：test_tc036_role_delete() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-037：角色分配权限（P0）
- **用例ID**：TC-037
- **用例名称**：角色分配权限
- **所属模块**：认证服务 - 角色管理
- **优先级**：P0
- **前置条件**：管理员已登录；权限树已初始化
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：permissionIds=权限树前若干权限 ID
- **测试步骤**：
  1. 管理员创建临时角色
  2. 查询权限树收集权限 ID
  3. 调用 PUT /api/v1/auth/roles/{roleId}/permissions 分配权限
- **预期结果**：
  1. 分配返回 code=0
- **自动化测试函数/脚本位置**：test_tc037_role_assign_permissions() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：权限管理 - 权限树与 CRUD 约束
#### TC-038：权限树查询（P0）
- **用例ID**：TC-038
- **用例名称**：权限树查询
- **所属模块**：认证服务 - 权限管理
- **优先级**：P0
- **前置条件**：管理员已登录；权限树已初始化
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：无参数
- **测试步骤**：
  1. 管理员调用 GET /api/v1/auth/permissions
- **预期结果**：
  1. 返回 code=0，data 为树形数组，节点含 permId/permCode/permName/permType/parentId/path/children
- **自动化测试函数/脚本位置**：test_tc038_permission_tree() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-039：创建权限与编码重复被拒（P1）
- **用例ID**：TC-039
- **用例名称**：创建权限与编码重复被拒
- **所属模块**：认证服务 - 权限管理
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：permCode=test:perm_+uuid，permName=自动化测试权限，parentId=0；重复编码=已存在权限编码
- **测试步骤**：
  1. 管理员调用 POST /api/v1/auth/permissions 创建权限
  2. 使用重复 permCode 再次创建
- **预期结果**：
  1. 创建返回 code=0，data 含 permId
  2. 重复编码返回 409（权限编码全局唯一）
- **自动化测试函数/脚本位置**：test_tc039_permission_create() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-040：更新/删除权限-子权限约束（P1）
- **用例ID**：TC-040
- **用例名称**：更新/删除权限-子权限约束
- **所属模块**：认证服务 - 权限管理
- **优先级**：P1
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：父权限 permId + 子权限 permId（parentId=父权限 ID）
- **测试步骤**：
  1. 管理员调用 PUT /api/v1/auth/permissions/{permId} 更新权限名称
  2. 删除存在子权限的父权限
  3. 删除子权限后再删除父权限
- **预期结果**：
  1. 更新返回 code=0，权限名称更新
  2. 有子权限的父权限删除返回 409（BIZ-0004 存在子权限，不可删除父权限）
  3. 子权限删除成功后再删除父权限成功
- **自动化测试函数/脚本位置**：test_tc040_permission_update_delete() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：网关认证 - 白名单、Token 校验、权限拦截
#### TC-041：白名单接口免 Token 放行（P0）
- **用例ID**：TC-041
- **用例名称**：白名单接口免 Token 放行
- **所属模块**：API 网关 - 认证拦截
- **优先级**：P0
- **前置条件**：网关已配置白名单（登录/注册/验证码/健康检查）
- **测试类型**：接口测试
- **关联需求ID**：US-014
- **测试数据**：无 Token 请求 /api/v1/auth/health、/api/v1/auth/login
- **测试步骤**：
  1. 无 Token 调用 GET /api/v1/auth/health
  2. 无 Token 调用 POST /api/v1/auth/login（正确凭据）
- **预期结果**：
  1. 健康检查返回 200（code=0）
  2. 登录直接放行返回 code=0 并签发 Token（无需认证）
- **自动化测试函数/脚本位置**：test_tc041_gateway_whitelist() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-042：无 Token/伪造 Token 访问受保护接口返回 401（P0）
- **用例ID**：TC-042
- **用例名称**：无 Token/伪造 Token 访问受保护接口返回 401
- **所属模块**：API 网关 - 认证拦截
- **优先级**：P0
- **前置条件**：网关已启动
- **测试类型**：接口测试
- **关联需求ID**：US-014
- **测试数据**：无 Authorization 头；Authorization: Bearer fake.token.value；Authorization: 非 Bearer 格式
- **测试步骤**：
  1. 无 Token 调用 GET /api/v1/auth/users
  2. 携带伪造 Token 调用 GET /api/v1/auth/users
  3. 携带非 Bearer 格式 Authorization 调用
- **预期结果**：
  1. 无 Token 返回 401（AUTH-0001 未携带访问凭证）
  2. 伪造 Token 返回 401（AUTH-0002 访问凭证无效或已过期）
  3. 非 Bearer 格式返回 401
- **自动化测试函数/脚本位置**：test_tc042_gateway_no_or_fake_token() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-043：普通用户访问管理接口返回 403（P0）
- **用例ID**：TC-043
- **用例名称**：普通用户访问管理接口返回 403
- **所属模块**：API 网关 - 认证拦截
- **优先级**：P0
- **前置条件**：普通测试账号已注册并登录（无管理角色）
- **测试类型**：接口测试
- **关联需求ID**：US-013、US-014
- **测试数据**：普通用户 Token 访问 GET /api/v1/auth/users
- **测试步骤**：
  1. 普通用户携带 Token 调用用户分页查询接口
- **预期结果**：
  1. 返回 403（AUTH-0015 无权限执行该操作）
- **自动化测试函数/脚本位置**：test_tc043_gateway_forbidden() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：多租户隔离 - 租户间数据不可见
#### TC-044：多租户隔离-跨租户数据不可见（P0）
- **用例ID**：TC-044
- **用例名称**：多租户隔离-跨租户数据不可见
- **所属模块**：认证服务 - 多租户隔离
- **优先级**：P0
- **前置条件**：默认租户 DEFAULT 用户数据存在；若环境预置了第二租户则执行跨租户断言，否则执行租户参数隔离断言
- **测试类型**：接口测试
- **关联需求ID**：US-013
- **测试数据**：管理员 Token；跨租户 tenantId 查询参数
- **测试步骤**：
  1. 管理员（DEFAULT 租户）查询本租户用户列表
  2. 使用其他租户 ID 作为查询参数（或伪造 X-Tenant-Id）查询
- **预期结果**：
  1. 本租户查询正常返回本租户数据
  2. 跨租户数据不可见：返回空或拒绝（不返回其他租户数据）
- **自动化测试函数/脚本位置**：test_tc044_tenant_isolation() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

### 模块：健康检查 - 四服务探活（网关路由）
#### TC-045：认证/企业/系统服务健康检查（P0）
- **用例ID**：TC-045
- **用例名称**：认证/企业/系统服务健康检查
- **所属模块**：全部服务 - 健康检查
- **优先级**：P0
- **前置条件**：网关 9000 与三服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-020
- **测试数据**：无参数
- **测试步骤**：
  1. 调用 GET /api/v1/auth/health（经网关）
  2. 调用 GET /api/v1/biz/health
  3. 调用 GET /api/v1/system/health
- **预期结果**：
  1. 认证服务返回 service=cloudoffice-auth-service，status=UP
  2. 企业服务返回 service=cloudoffice-biz-service，status=UP
  3. 系统服务返回 service=cloudoffice-system-service，status=UP
- **自动化测试函数/脚本位置**：test_tc045_health_checks() @ scripts/API-TEST/cso-api-test-v0.0.1.py
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 0 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 验证码真实发送模式下脚本无法自动获取验证码 | 验证码相关用例（TC-002/007/021/022/025/026/027）无法闭环 | 依赖 VERIFICATION_CODE_MOCK=true 模拟模式返回 mockCode；真实模式下人工查看服务端控制台并标记 SKIP |
| OAuth 第三方平台（微信/钉钉/GitHub）不可用或未配置 | TC-003/028（OAuth 注册、两步注册）阻塞 | 使用模拟授权码验证流程，仍不可用则标记 SKIP，人工验证 |
| 管理员初始密码 admin/admin123 已被修改 | 管理类用例（TC-009/017/029~040/043/044）前置失败 | 用例失败时人工核对实际管理员账号并更新脚本配置后重跑 |
| 租户禁用场景需预置禁用租户 | TC-009 租户禁用部分无法自动执行 | 环境无预置禁用租户时该部分标记 SKIP，人工验证 |
| 接口实现与反推文档存在字段差异 | 部分断言（状态码/错误码/字段名）可能失败 | 失败时以实际实现为准修正脚本或反馈修订文档，保持契约一致 |
| 测试账号数据污染（重复执行） | 唯一性校验用例误报 | 全部测试数据使用 uuid 唯一命名，用例间相互独立 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
