# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.0.1
**日期**：2026-08-07
**测试负责人**：TE

> 说明：本版本为初始化基线（反推存量代码能力），测试覆盖统一认证授权底座全部功能（F-001~F-019）。
> 用例编号约定：TC-001~TC-045 为接口测试（与 scripts/API-TEST/cso-api-test-v0.0.1.py 一一对应）；
> UT-001~UT-060 为单元测试（对应 Java 测试类）；FT-001~FT-008 为功能测试；UIT-001~UIT-005 为 UI 测试。
> 接口契约以 docs/cso-api.md 与当前代码实现为准；自动化测试函数/脚本位置已标注，测试过程与结论由 runtest 步骤记录。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 注册（F-001） | init | 6 | P0×4、P1×2 |
| 登录（F-002） | init | 7 | P0×5、P1×2 |
| Token 与会话（F-003/F-004） | init | 6 | P0×5、P1×1 |
| 登出与踢人（F-004） | init | 5 | P0×4、P1×1 |
| 验证码（F-008） | init | 6 | P0×4、P1×2 |
| 密码管理（F-006） | init | 6 | P0×4、P1×2 |
| 手机号变更（F-007） | init | 2 | P0×1、P1×1 |
| 两步注册补全（F-001） | init | 2 | P0×2 |
| 用户管理（F-011） | init | 6 | P0×4、P1×2 |
| 角色管理（F-012） | init | 5 | P0×3、P1×2 |
| 权限管理（F-013） | init | 4 | P0×2、P1×2 |
| 网关认证（F-005/F-018） | init | 5 | P0×5 |
| 多租户隔离（F-010） | init | 2 | P0×2 |
| 健康检查（F-016） | init | 2 | P1×2 |
| 单元测试（登录策略） | init | 9 | P0×6、P1×3 |
| 单元测试（注册策略） | init | 10 | P0×7、P1×3 |
| 单元测试（AuthenticationService） | init | 8 | P0×8 |
| 单元测试（TokenService/JwtUtils） | init | 11 | P0×9、P1×2 |
| 单元测试（LoginSessionService） | init | 6 | P0×4、P1×2 |
| 单元测试（VerificationCodeManager） | init | 6 | P0×4、P1×2 |
| 单元测试（LoginService 登出/踢人） | init | 5 | P0×4、P1×1 |
| 单元测试（PasswordService） | init | 7 | P0×5、P1×2 |
| 单元测试（RBAC 服务） | init | 9 | P0×6、P1×3 |
| 单元测试（common） | init | 6 | P0×4、P1×2 |
| 功能测试 | init | 8 | P0×6、P1×2 |
| UI 测试 | init | 5 | P1×5 |
| **合计** |  | **118** | P0×91、P1×27 |

## 二、测试用例详情

### 模块：用户注册（F-001） - 接口测试

#### TC-001：用户名密码注册成功（P0）
- **用例ID**：TC-001
- **用例名称**：用户名密码注册成功且可自动登录
- **所属模块**：auth-service / 注册
- **优先级**：P0
- **前置条件**：系统已部署，默认租户 DEFAULT 存在，验证码模拟模式可用
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：registerMode=USERNAME，loginName=reg_{uuid8}，password=Pass@1234，tenantCode=DEFAULT，clientType=H5
- **测试步骤**：
  1. POST /api/v1/auth/register 提交 USERNAME 模式注册（loginName/password/userName/tenantCode/clientType）
  2. 使用注册的登录名密码 POST /api/v1/auth/login
- **预期结果**：
  1. 注册返回 code=200，data.userId 非空、data.accountSettled=true
  2. 登录成功返回双 Token（accessToken/refreshToken 非空）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc001_register_username_password
- **测试过程与结论**：（runtest 记录）

#### TC-002：手机验证码注册成功（P0）
- **用例ID**：TC-002
- **用例名称**：手机验证码注册成功
- **所属模块**：auth-service / 注册
- **优先级**：P0
- **前置条件**：同 TC-001
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：registerMode=PHONE_CODE，phone=13x 随机，code=模拟验证码（从库读取）
- **测试步骤**：
  1. POST /api/v1/auth/verification-code/send 向新手机号发送 REGISTER 验证码
  2. 从 t_auth_verification_code 读取最新验证码
  3. POST /api/v1/auth/register 提交 PHONE_CODE 注册
- **预期结果**：发送 code=200；注册 code=200，data.userId 非空
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc002_register_phone_code
- **测试过程与结论**：（runtest 记录）

#### TC-003：OAuth 注册进入两步注册（P1）
- **用例ID**：TC-003
- **用例名称**：OAuth 注册创建未完善账号且幂等
- **所属模块**：auth-service / 注册
- **优先级**：P1
- **前置条件**：同 TC-001；OAuth 模拟注册可用
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：registerMode=OAUTH，oauthProvider=WECHAT，oauthCode=mock_oauth_{uuid8}
- **测试步骤**：
  1. POST /api/v1/auth/register 提交 OAUTH 注册
  2. 相同 oauthCode 重复注册
- **预期结果**：
  1. 首次注册 code=200，data.userId 非空，accountSettled=false（两步注册）
  2. 重复注册返回同一 userId（幂等）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc003_register_oauth
- **测试过程与结论**：（runtest 记录）

#### TC-004：注册异常-重复与参数非法（P0）
- **用例ID**：TC-004
- **用例名称**：登录名重复与弱密码被拒
- **所属模块**：auth-service / 注册
- **优先级**：P0
- **前置条件**：admin 用户已存在（初始数据）
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：loginName=admin（重复）；password=123（弱密码）
- **测试步骤**：
  1. 用已存在的登录名 admin 注册
  2. 用长度不足的密码注册
- **预期结果**：
  1. 重复注册返回 409（唯一性冲突）
  2. 弱密码返回 400（参数校验）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc004_register_duplicate_and_invalid
- **测试过程与结论**：（runtest 记录）

#### TC-028：两步注册账号补全（P0）
- **用例ID**：TC-028
- **用例名称**：账号补全成功与已完善账号拒绝
- **所属模块**：auth-service / 注册
- **优先级**：P0
- **前置条件**：OAuth 两步注册前置可用
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：OAUTH 注册后 userId；PUT /account/settlement 提交 {userId, loginName, password}
- **测试步骤**：
  1. OAUTH 注册创建未完善账号，OAuth 登录获取 Token
  2. 携带 Token PUT /api/v1/auth/account/settlement 补全登录名与密码
  3. 对已完善账号重复调用补全
- **预期结果**：
  1. 补全成功 code=200
  2. 已完善账号补全被拒（400/403/422）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc028_account_settlement
- **测试过程与结论**：（runtest 记录）

#### UT-001：注册策略-用户名密码注册成功与默认角色分配（P0）
- **用例ID**：UT-001
- **用例名称**：UsernamePwdRegisterStrategy.register 成功创建完整账号并分配默认角色
- **所属模块**：auth-service / 注册策略
- **优先级**：P0
- **前置条件**：Mockito 环境；模拟租户存在
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：RegisterRequest（loginName/password/userName/tenantCode）
- **测试步骤**：
  1. 调用 register(request)
  2. 断言返回 RegisterResult 与 Mapper 调用
- **预期结果**：userId 非空、accountSettled=true；userMapper.insert 与 userRoleMapper.insert 各调用 1 次；密码 BCrypt 加密
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/UsernamePwdRegisterStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-002：注册策略-登录名租户内重复被拒（P0）
- **用例ID**：UT-002
- **用例名称**：UsernamePwdRegisterStrategy 登录名重复抛业务异常
- **所属模块**：auth-service / 注册策略
- **优先级**：P0
- **前置条件**：同 UT-001
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：loginName 已存在
- **测试步骤**：mock userMapper.selectByTenantIdAndLoginName 返回已存在用户，调用 register
- **预期结果**：抛 BusinessException（登录名已存在），未调用 insert
- **自动化测试函数/脚本位置**：同 UT-001
- **测试过程与结论**：（runtest 记录）

#### UT-003：注册策略-手机号已绑定被拒（P1）
- **用例ID**：UT-003
- **用例名称**：UsernamePwdRegisterStrategy 手机号全局唯一性校验
- **所属模块**：auth-service / 注册策略
- **优先级**：P1
- **前置条件**：同 UT-001
- **测试类型**：单元测试
- **关联需求ID**：F-001
- **测试数据**：request.phone 已被其他用户绑定
- **测试步骤**：mock phone 查询返回已存在用户，调用 register
- **预期结果**：抛 BusinessException（PHONE_ALREADY_BOUND）
- **自动化测试函数/脚本位置**：同 UT-001
- **测试过程与结论**：（runtest 记录）

#### UT-004：注册策略-租户不存在/禁用/过期被拒（P1）
- **用例ID**：UT-004
- **用例名称**：注册时租户状态校验（不存在/禁用/过期）
- **所属模块**：auth-service / 注册策略
- **优先级**：P1
- **前置条件**：同 UT-001
- **测试类型**：单元测试
- **关联需求ID**：F-001 / F-010
- **测试数据**：tenantCode 不存在；租户 status=1；租户过期
- **测试步骤**：分别 mock 租户查询结果，调用 register
- **预期结果**：分别抛 租户不存在 / TENANT_DISABLED / TENANT_EXPIRED
- **自动化测试函数/脚本位置**：同 UT-001
- **测试过程与结论**：（runtest 记录）

#### UT-005：注册策略-手机验证码注册成功（P0）
- **用例ID**：UT-005
- **用例名称**：PhoneCodeRegisterStrategy 校验验证码后创建账号
- **所属模块**：auth-service / 注册策略
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：phone+smsCode+userName
- **测试步骤**：mock 验证码校验通过，调用 register
- **预期结果**：注册成功；验证码校验调用 1 次；验证码无效时抛 SMS_CODE_INVALID
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/PhoneCodeRegisterStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-006：注册策略-两步注册账号未完善（P0）
- **用例ID**：UT-006
- **用例名称**：OAuth 注册创建 accountSettled=false 账号
- **所属模块**：auth-service / 注册策略
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：registerMode=OAUTH，oauthProvider/oauthCode
- **测试步骤**：调用 OAuthRegisterStrategy.register；重复 oauthCode 幂等校验
- **预期结果**：账号创建且 accountSettled=false；相同 oauthCode 返回同一账号（幂等）
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/OAuthRegisterStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-007：注册策略-无效模式被拒（P0）
- **用例ID**：UT-007
- **用例名称**：RegisterStrategyFactory 无效注册模式抛 REGISTER_MODE_INVALID
- **所属模块**：auth-service / 注册策略工厂
- **优先级**：P0
- **前置条件**：Mockito 环境，工厂已初始化
- **测试类型**：单元测试
- **关联需求ID**：F-001
- **测试数据**：registerMode=UNKNOWN
- **测试步骤**：调用 getStrategy("UNKNOWN")
- **预期结果**：抛 BusinessException（REGISTER_MODE_INVALID）
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/RegisterStrategyFactoryTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-008：注册策略工厂-5 种策略全部注册（P0）
- **用例ID**：UT-008
- **用例名称**：RegisterStrategyFactory 注册 USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO
- **所属模块**：auth-service / 注册策略工厂
- **优先级**：P0
- **前置条件**：同 UT-007
- **测试类型**：单元测试
- **关联需求ID**：F-001
- **测试数据**：5 个模式编码
- **测试步骤**：init() 后逐个 getStrategy
- **预期结果**：5 种模式均返回对应策略实例
- **自动化测试函数/脚本位置**：同 UT-007
- **测试过程与结论**：（runtest 记录）

#### UT-009：注册策略-补全账号信息（P0）
- **用例ID**：UT-009
- **用例名称**：OAuthSetInfoStrategy/PhoneSetUsernameStrategy 补全后 accountSettled=1
- **所属模块**：auth-service / 注册策略
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-001
- **测试数据**：未完善用户 + loginName/password/phone
- **测试步骤**：调用补全策略
- **预期结果**：账号信息更新，accountSettled 置 1
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/OAuthSetInfoStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-010：注册策略-密码边界（8/64 位）（P1）
- **用例ID**：UT-010
- **用例名称**：注册密码长度边界 7/8/64/65
- **所属模块**：auth-service / 注册策略
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-001 / NFR-003
- **测试数据**：password=7 位/8 位/64 位/65 位
- **测试步骤**：逐一构造 RegisterRequest 校验
- **预期结果**：7/65 位被拒（400），8/64 位通过
- **自动化测试函数/脚本位置**：同 UT-001（参数化子场景）
- **测试过程与结论**：（runtest 记录）

### 模块：多模式登录（F-002） - 接口测试

#### TC-005：用户名密码登录成功签发双 Token（P0）
- **用例ID**：TC-005
- **用例名称**：用户名密码登录成功签发双 Token
- **所属模块**：auth-service / 登录
- **优先级**：P0
- **前置条件**：admin/admin123 初始账号可用
- **测试类型**：接口测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：loginMode=USERNAME_PASSWORD，loginName=admin，password=admin123
- **测试步骤**：POST /api/v1/auth/login
- **预期结果**：code=200，data.accessToken 与 data.refreshToken 非空
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc005_login_username_password
- **测试过程与结论**：（runtest 记录）

#### TC-006：密码错误登录失败且防枚举提示（P0）
- **用例ID**：TC-006
- **用例名称**：错误密码与不存在用户返回一致提示
- **所属模块**：auth-service / 登录
- **优先级**：P0
- **前置条件**：同 TC-005
- **测试类型**：接口测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：admin+错误密码；no_such_user+错误密码
- **测试步骤**：分别 POST /api/v1/auth/login
- **预期结果**：两者返回相同 HTTP 状态与相同 message（防账号枚举）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc006_login_wrong_password_anti_enum
- **测试过程与结论**：（runtest 记录）

#### TC-007：手机验证码登录（正确码成功/错误码拒绝）（P0）
- **用例ID**：TC-007
- **用例名称**：手机验证码登录成功与错误码拒绝
- **所属模块**：auth-service / 登录
- **优先级**：P0
- **前置条件**：测试用户已注册并绑定手机号；验证码可获取（库读取）
- **测试类型**：接口测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：loginMode=PHONE_CODE，phone=13x，smsCode=正确/000000
- **测试步骤**：
  1. 发送 LOGIN 验证码并读取
  2. 正确码登录
  3. 错误码登录
- **预期结果**：正确码登录成功；错误码被拒（400/422）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc007_login_phone_code
- **测试过程与结论**：（runtest 记录）

#### TC-008：手机+密码登录成功（P0）
- **用例ID**：TC-008
- **用例名称**：手机+密码登录成功
- **所属模块**：auth-service / 登录
- **优先级**：P0
- **前置条件**：测试用户已绑定手机号
- **测试类型**：接口测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：loginMode=PHONE_PASSWORD，phone+password
- **测试步骤**：POST /api/v1/auth/login
- **预期结果**：登录成功返回双 Token
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc008_login_phone_password
- **测试过程与结论**：（runtest 记录）

#### TC-009：禁用账号/租户登录被拒（P0）
- **用例ID**：TC-009
- **用例名称**：封禁/停用账号登录被拒
- **所属模块**：auth-service / 登录
- **优先级**：P0
- **前置条件**：管理员可变更用户状态
- **测试类型**：接口测试
- **关联需求ID**：F-002 / F-011 / US-002
- **测试数据**：新建用户后置 status=3（封禁）
- **测试步骤**：
  1. 管理员 PUT /users/{id}/status 置封禁
  2. 该用户登录
- **预期结果**：登录返回 403（账号状态错误）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc009_login_disabled
- **测试过程与结论**：（runtest 记录）

#### TC-010：登录模式/客户端类型非法被拒（P1）
- **用例ID**：TC-010
- **用例名称**：无效登录模式与客户端类型被拒
- **所属模块**：auth-service / 登录
- **优先级**：P1
- **前置条件**：同 TC-005
- **测试类型**：接口测试
- **关联需求ID**：F-002
- **测试数据**：loginMode=UNKNOWN_MODE；clientType=TV
- **测试步骤**：分别 POST /api/v1/auth/login
- **预期结果**：均返回 400/422（模式/类型无效）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc010_login_invalid_mode_client
- **测试过程与结论**：（runtest 记录）

#### UT-011：登录策略-用户名密码成功（P0）
- **用例ID**：UT-011
- **用例名称**：UsernamePasswordStrategy 凭据正确认证成功
- **所属模块**：auth-service / 登录策略
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：loginName+password 匹配
- **测试步骤**：mock 租户/用户/BCrypt 比对通过，调用 authenticate
- **预期结果**：返回 AuthResult（userId/tenantId/roles/permissions 非空）
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/UsernamePasswordStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-012：登录策略-密码错误抛 LOGIN_FAILED（P0）
- **用例ID**：UT-012
- **用例名称**：UsernamePasswordStrategy 密码错误抛认证异常
- **所属模块**：auth-service / 登录策略
- **优先级**：P0
- **前置条件**：同 UT-011
- **测试类型**：单元测试
- **关联需求ID**：F-002
- **测试数据**：password 不匹配
- **测试步骤**：mock BCrypt 比对失败，调用 authenticate
- **预期结果**：抛 AuthException（LOGIN_FAILED）
- **自动化测试函数/脚本位置**：同 UT-011
- **测试过程与结论**：（runtest 记录）

#### UT-013：登录策略-用户不存在抛 USER_NOT_FOUND（P0）
- **用例ID**：UT-013
- **用例名称**：UsernamePasswordStrategy 用户不存在抛异常
- **所属模块**：auth-service / 登录策略
- **优先级**：P0
- **前置条件**：同 UT-011
- **测试类型**：单元测试
- **关联需求ID**：F-002
- **测试数据**：loginName 不存在
- **测试步骤**：mock 用户查询返回 null，调用 authenticate
- **预期结果**：抛 AuthException（USER_NOT_FOUND）
- **自动化测试函数/脚本位置**：同 UT-011
- **测试过程与结论**：（runtest 记录）

#### UT-014：登录策略-手机验证码成功（P0）
- **用例ID**：UT-014
- **用例名称**：PhoneCodeLoginStrategy 验证码正确认证成功
- **所属模块**：auth-service / 登录策略
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：phone+smsCode 正确
- **测试步骤**：mock 验证码校验通过，调用 authenticate
- **预期结果**：返回 AuthResult；验证码校验被调用 1 次
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/PhoneCodeLoginStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-015：登录策略-验证码无效被拒（P0）
- **用例ID**：UT-015
- **用例名称**：PhoneCodeLoginStrategy 验证码无效抛 SMS_CODE_INVALID
- **所属模块**：auth-service / 登录策略
- **优先级**：P0
- **前置条件**：同 UT-014
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：smsCode 错误
- **测试步骤**：mock 验证码校验失败，调用 authenticate
- **预期结果**：抛 BusinessException（SMS_CODE_INVALID）
- **自动化测试函数/脚本位置**：同 UT-014
- **测试过程与结论**：（runtest 记录）

#### UT-016：登录策略-手机+密码成功（P1）
- **用例ID**：UT-016
- **用例名称**：PhonePasswordLoginStrategy 手机号+密码认证成功
- **所属模块**：auth-service / 登录策略
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002
- **测试数据**：phone+password 匹配
- **测试步骤**：mock 用户与密码比对，调用 authenticate
- **预期结果**：认证成功返回 AuthResult
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/PhonePasswordLoginStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-017：登录策略-OAuth 认证成功/未绑定（P1）
- **用例ID**：UT-017
- **用例名称**：OAuthLoginStrategy 认证成功与未绑定用户异常
- **所属模块**：auth-service / 登录策略
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-002
- **测试数据**：oauthProvider+oauthCode
- **测试步骤**：mock OAuth 账号关联，调用 authenticate
- **预期结果**：关联存在认证成功；不存在抛对应 OAuth 错误
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/OAuthLoginStrategyTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-018：登录策略工厂-4 种策略注册与无效模式（P0）
- **用例ID**：UT-018
- **用例名称**：LoginStrategyFactory 注册 4 种策略，无效模式抛 LOGIN_MODE_INVALID
- **所属模块**：auth-service / 登录策略工厂
- **优先级**：P0
- **前置条件**：Mockito 环境，工厂已初始化
- **测试类型**：单元测试
- **关联需求ID**：F-002
- **测试数据**：USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH；UNKNOWN
- **测试步骤**：getStrategy 各模式；getStrategy("UNKNOWN")
- **预期结果**：4 种模式返回对应实例；UNKNOWN 抛 BusinessException（LOGIN_MODE_INVALID）
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../strategy/LoginStrategyFactoryTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-019：登录-密码边界与非法枚举（P1）
- **用例ID**：UT-019
- **用例名称**：登录入参密码长度边界与枚举校验
- **所属模块**：auth-service / 登录
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-002
- **测试数据**：password=7/65 位；loginMode=null
- **测试步骤**：构造 LoginRequest 校验
- **预期结果**：7/65 位与非法枚举被拒
- **自动化测试函数/脚本位置**：同 UT-011（参数化子场景）
- **测试过程与结论**：（runtest 记录）

### 模块：Token 与会话（F-003/F-004） - 接口测试

#### TC-011：Token 刷新成功换发新双 Token（P0）
- **用例ID**：TC-011
- **用例名称**：Refresh Token 刷新成功换发新双 Token
- **所属模块**：auth-service / Token
- **优先级**：P0
- **前置条件**：用户已登录
- **测试类型**：接口测试
- **关联需求ID**：F-003 / US-003
- **测试数据**：refreshToken=登录返回
- **测试步骤**：POST /api/v1/auth/refresh
- **预期结果**：code=200，返回新的 accessToken 与 refreshToken
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc011_refresh_success
- **测试过程与结论**：（runtest 记录）

#### TC-012：刷新轮换后旧 Refresh Token 失效（P0）
- **用例ID**：TC-012
- **用例名称**：旧 Refresh Token 轮换后重放被拒
- **所属模块**：auth-service / Token
- **优先级**：P0
- **前置条件**：同 TC-011
- **测试类型**：接口测试
- **关联需求ID**：F-003 / US-003
- **测试数据**：同一 refreshToken 连续刷新两次
- **测试步骤**：
  1. 第一次 refresh 成功
  2. 用同一 refreshToken 再次 refresh
- **预期结果**：第一次 200；第二次 401（黑名单防重放）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc012_refresh_rotation
- **测试过程与结论**：（runtest 记录）

#### TC-013：同端互斥-同客户端新登录踢旧会话（P0）
- **用例ID**：TC-013
- **用例名称**：同一客户端类型重复登录旧 Token 失效
- **所属模块**：auth-service / 会话
- **优先级**：P0
- **前置条件**：测试用户存在
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-002
- **测试数据**：H5 类型两次登录
- **测试步骤**：
  1. H5 登录得 token1
  2. H5 再登录得 token2
  3. 分别用 token1/token2 访问受保护接口
- **预期结果**：token2 访问 200；token1 访问 401（旧会话被踢）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc013_same_client_mutex
- **测试过程与结论**：（runtest 记录）

#### TC-014：多端共存-不同客户端类型同时在线（P0）
- **用例ID**：TC-014
- **用例名称**：不同客户端类型会话共存
- **所属模块**：auth-service / 会话
- **优先级**：P0
- **前置条件**：同 TC-013
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-002
- **测试数据**：H5 与 Android 各登录一次
- **测试步骤**：
  1. H5 登录得 token1
  2. Android 登录得 token2
  3. 分别访问受保护接口
- **预期结果**：两个 Token 均可用（多端共存）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc014_multi_client_coexist
- **测试过程与结论**：（runtest 记录）

#### UT-020：TokenService 刷新成功与轮换（P0）
- **用例ID**：UT-020
- **用例名称**：refresh 成功换发新 Token 对且旧 Token 入黑名单
- **所属模块**：auth-service / TokenService
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-003
- **测试步骤**：mock JwtUtils 与状态正常，调用 refresh
- **预期结果**：返回新 TokenPairDTO；旧签名加入黑名单；会话更新（remove+create）
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/TokenServiceImplTest.java（存量，refresh_validRefreshToken_shouldReturnNewTokenPair 等）
- **测试过程与结论**：（runtest 记录）

#### UT-021：TokenService 过期/无效/黑名单拒绝（P0）
- **用例ID**：UT-021
- **用例名称**：refresh 对过期/无效/黑名单/错误 tokenType 拒绝
- **所属模块**：auth-service / TokenService
- **优先级**：P0
- **前置条件**：同 UT-020
- **测试类型**：单元测试
- **关联需求ID**：F-003
- **测试步骤**：分别 mock 过期/无效签名/黑名单命中/access 当 refresh 使用
- **预期结果**：分别抛 REFRESH_TOKEN_EXPIRED / REFRESH_TOKEN_INVALID / TOKEN_BLACKLISTED / AuthException
- **自动化测试函数/脚本位置**：同 UT-020（refresh_expiredRefreshToken_shouldThrowAuthException 等）
- **测试过程与结论**：（runtest 记录）

#### UT-022：TokenService 用户/租户状态拦截刷新（P0）
- **用例ID**：UT-022
- **用例名称**：用户封禁/禁用/锁定与租户禁用/过期拦截刷新
- **所属模块**：auth-service / TokenService
- **优先级**：P0
- **前置条件**：同 UT-020
- **测试类型**：单元测试
- **关联需求ID**：F-003 / F-010
- **测试步骤**：mock 用户/租户各状态，调用 refresh
- **预期结果**：分别抛 ACCOUNT_BANNED/DISABLED/LOCKED、TENANT_DISABLED/EXPIRED 业务异常
- **自动化测试函数/脚本位置**：同 UT-020（refresh_bannedAccount_shouldThrowBusinessException 等）
- **测试过程与结论**：（runtest 记录）

#### UT-023：JwtUtils 双 Token 签发与载荷（P0）
- **用例ID**：UT-023
- **用例名称**：Access/Refresh Token 签发解析与 claims 正确性
- **所属模块**：auth-service / JwtUtils
- **优先级**：P0
- **前置条件**：测试 RSA 密钥环境
- **测试类型**：单元测试
- **关联需求ID**：F-003
- **测试步骤**：生成双 Token 并解析
- **预期结果**：三段式 JWT；claims 含 sub/tenantId/clientType/tokenType；Access 有效期 2h、Refresh 7d
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../util/JwtUtilsTest.java（存量，generateAccessToken_andParse_shouldReturnCorrectClaims 等）
- **测试过程与结论**：（runtest 记录）

#### UT-024：JwtUtils 异常与签名指纹（P0）
- **用例ID**：UT-024
- **用例名称**：过期/错签/错 tokenType 抛异常；签名指纹一致性与 64 位十六进制
- **所属模块**：auth-service / JwtUtils
- **优先级**：P0
- **前置条件**：同 UT-023
- **测试类型**：单元测试
- **关联需求ID**：F-003
- **测试步骤**：解析过期 Token、篡改签名 Token、错误 tokenType Token；计算签名指纹
- **预期结果**：均抛异常；同一 Token 指纹一致、不同 Token 指纹不同、指纹为 64 位十六进制
- **自动化测试函数/脚本位置**：同 UT-023（parseAccessToken_withExpiredToken_shouldThrowException 等）
- **测试过程与结论**：（runtest 记录）

#### UT-025：LoginSessionService 会话 CRUD 与黑名单（P0）
- **用例ID**：UT-025
- **用例名称**：会话创建/查询/移除/全端移除与黑名单增查
- **所属模块**：auth-service / LoginSessionService
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试步骤**：调用 createSession/getSession/removeSession/removeAllSessions/addToBlacklist/isBlacklisted
- **预期结果**：Redis 键值正确（TTL、SCAN 删除、类型序列化）；空参抛异常
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/LoginSessionServiceImplTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-026：LoginSessionService 状态缓存读写（P1）
- **用例ID**：UT-026
- **用例名称**：账号/租户状态缓存 set/get/remove
- **所属模块**：auth-service / LoginSessionService
- **优先级**：P1
- **前置条件**：同 UT-025
- **测试类型**：单元测试
- **关联需求ID**：F-010 / F-005
- **测试步骤**：调用 setAccountStatus/getAccountStatus/removeAccountStatus 等
- **预期结果**：缓存读写正确；不存在返回 null
- **自动化测试函数/脚本位置**：同 UT-025（setAccountStatus_shouldSetValue_whenCalled 等）
- **测试过程与结论**：（runtest 记录）

### 模块：登出与踢人（F-004） - 接口测试

#### TC-015：主动登出后 Token 失效（P0）
- **用例ID**：TC-015
- **用例名称**：登出后 Access/Refresh Token 均失效
- **所属模块**：auth-service / 登出
- **优先级**：P0
- **前置条件**：测试用户已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-003
- **测试数据**：accessToken+refreshToken
- **测试步骤**：
  1. POST /api/v1/auth/logout（Bearer accessToken）
  2. 用原 accessToken 访问受保护接口
  3. 用原 refreshToken 刷新
- **预期结果**：登出 200；原 accessToken 401；原 refreshToken 401
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc015_logout_invalidates_token
- **测试过程与结论**：（runtest 记录）

#### TC-016：重复登出幂等（P0）
- **用例ID**：TC-016
- **用例名称**：重复登出不报错（幂等）
- **所属模块**：auth-service / 登出
- **优先级**：P0
- **前置条件**：同 TC-015
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-003
- **测试步骤**：连续两次 POST /logout（同一 Token）
- **预期结果**：两次均返回 200
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc016_logout_idempotent
- **测试过程与结论**：（runtest 记录）

#### TC-017：管理员强制踢人后登录态失效（P0）
- **用例ID**：TC-017
- **用例名称**：管理员强制踢人后目标用户请求被拒
- **所属模块**：auth-service / 踢人
- **优先级**：P0
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-003
- **测试数据**：目标 userId
- **测试步骤**：
  1. 目标用户登录获得 Token
  2. 管理员 POST /api/v1/auth/kickout {userId}
  3. 目标用户用原 Token 访问受保护接口
- **预期结果**：踢人 200；原 Token 401
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc017_kickout
- **测试过程与结论**：（runtest 记录）

#### TC-018：非管理员踢人被拒（P0）
- **用例ID**：TC-018
- **用例名称**：普通用户调用踢人返回 403
- **所属模块**：auth-service / 踢人
- **优先级**：P0
- **前置条件**：普通用户已登录（无 admin 角色）
- **测试类型**：接口测试
- **关联需求ID**：F-004 / US-003
- **测试数据**：普通用户 Token + 目标 userId
- **测试步骤**：普通用户 POST /api/v1/auth/kickout
- **预期结果**：返回 403（PERMISSION_DENIED）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc018_kickout_forbidden
- **测试过程与结论**：（runtest 记录）

#### UT-027：LoginService 登出幂等与黑名单（P0）
- **用例ID**：UT-027
- **用例名称**：logout 入黑名单、清会话、异常不抛出（幂等）
- **所属模块**：auth-service / LoginService
- **优先级**：P0
- **前置条件**：Mockito 环境（RequestContextHolder 模拟 X-User-Id 等）
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试步骤**：调用 logout；重复 logout；Token 已失效 logout
- **预期结果**：黑名单写入、会话清除；重复/异常登出不抛错
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/LoginServiceImplTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-028：LoginService 踢人权限校验（P0）
- **用例ID**：UT-028
- **用例名称**：kickout 校验 admin 角色（含/不含 X-Roles）
- **所属模块**：auth-service / LoginService
- **优先级**：P0
- **前置条件**：同 UT-027
- **测试类型**：单元测试
- **关联需求ID**：F-004 / US-003
- **测试步骤**：admin 角色踢人；非 admin 踢人
- **预期结果**：admin 成功；非 admin 抛 PERMISSION_DENIED（403）
- **自动化测试函数/脚本位置**：同 UT-027（kickout 系列测试）
- **测试过程与结论**：（runtest 记录）

#### UT-029：LoginService 踢指定端/所有端（P1）
- **用例ID**：UT-029
- **用例名称**：kickout clientType 空与非空分支
- **所属模块**：auth-service / LoginService
- **优先级**：P1
- **前置条件**：同 UT-027
- **测试类型**：单元测试
- **关联需求ID**：F-004
- **测试步骤**：指定 clientType 踢人；不指定踢人
- **预期结果**：指定端仅移除该端会话；不指定移除全部会话（removeAllSessions）
- **自动化测试函数/脚本位置**：同 UT-027
- **测试过程与结论**：（runtest 记录）

#### UT-030：LoginLogService 登录日志记录（P1）
- **用例ID**：UT-030
- **用例名称**：登录成功/失败日志写入与失败容错
- **所属模块**：auth-service / LoginLogService
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-014
- **测试步骤**：调用 recordLoginSuccess/recordLoginFailure；DB 异常
- **预期结果**：日志实体写入正确字段；DB 异常不影响主流程
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/LoginLogServiceImplTest.java（存量）
- **测试过程与结论**：（runtest 记录）

### 模块：验证码管理（F-008） - 接口测试

#### TC-019：发送验证码成功（P0）
- **用例ID**：TC-019
- **用例名称**：发送验证码成功且库中存在 6 位验证码
- **所属模块**：auth-service / 验证码
- **优先级**：P0
- **前置条件**：验证码模拟模式（app.verification-code.mock=true）
- **测试类型**：接口测试
- **关联需求ID**：F-008 / US-008
- **测试数据**：target=13x 随机，purpose=REGISTER，mode=SMS
- **测试步骤**：POST /api/v1/auth/verification-code/send；查 t_auth_verification_code
- **预期结果**：接口 code=200；库中存在 6 位数字验证码（未使用）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc019_send_code_success
- **测试过程与结论**：（runtest 记录）

#### TC-020：60 秒内重复发送验证码被拒（P0）
- **用例ID**：TC-020
- **用例名称**：发送频率限制（60 秒）生效
- **所属模块**：auth-service / 验证码
- **优先级**：P0
- **前置条件**：同 TC-019
- **测试类型**：接口测试
- **关联需求ID**：F-008 / US-008
- **测试数据**：同一 target+purpose 连续发送两次
- **测试步骤**：连续两次 POST /verification-code/send
- **预期结果**：第一次 200；第二次 429（SMS_SEND_TOO_FREQUENT）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc020_send_code_frequency
- **测试过程与结论**：（runtest 记录）

#### TC-021：验证码单次使用-复用被拒（P0）
- **用例ID**：TC-021
- **用例名称**：验证码一次性失效
- **所属模块**：auth-service / 验证码
- **优先级**：P0
- **前置条件**：测试用户已绑定手机号
- **测试类型**：接口测试
- **关联需求ID**：F-008 / US-008
- **测试数据**：同一验证码连续用于两次 LOGIN
- **测试步骤**：
  1. 发送 LOGIN 验证码并读取
  2. 首次登录成功
  3. 用同一验证码再次登录
- **预期结果**：首次登录成功；复用被拒（400/422）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc021_code_single_use
- **测试过程与结论**：（runtest 记录）

#### TC-022：验证码用途不匹配被拒（P1）
- **用例ID**：TC-022
- **用例名称**：REGISTER 用途验证码不能用于登录
- **所属模块**：auth-service / 验证码
- **优先级**：P1
- **前置条件**：同 TC-019
- **测试类型**：接口测试
- **关联需求ID**：F-008 / US-008
- **测试数据**：REGISTER 验证码用于 PHONE_CODE 登录
- **测试步骤**：发送 REGISTER 验证码；用该码登录
- **预期结果**：登录被拒（400/422）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc022_code_purpose_mismatch
- **测试过程与结论**：（runtest 记录）

#### UT-031：验证码生成与持久化（P0）
- **用例ID**：UT-031
- **用例名称**：generateCode 生成 6 位验证码并写库写缓存
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-008
- **测试步骤**：调用 generateCode(target, mode, purpose)
- **预期结果**：返回 6 位数字（首位非 0）；insert 调用 1 次；Redis 缓存与频率标记写入
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/VerificationCodeManagerImplTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-032：验证码校验成功一次性失效（P0）
- **用例ID**：UT-032
- **用例名称**：verifyCode 正确码通过并置 used=1
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P0
- **前置条件**：同 UT-031
- **测试类型**：单元测试
- **关联需求ID**：F-008 / US-008
- **测试步骤**：mock 查询到未使用验证码，调用 verifyCode
- **预期结果**：返回 true；updateUsedStatus 被调用
- **自动化测试函数/脚本位置**：同 UT-031
- **测试过程与结论**：（runtest 记录）

#### UT-033：验证码错误/过期/已用被拒（P0）
- **用例ID**：UT-033
- **用例名称**：verifyCode 错误码/过期/已用/不存在均返回 false
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P0
- **前置条件**：同 UT-031
- **测试类型**：单元测试
- **关联需求ID**：F-008 / US-008
- **测试步骤**：分别构造错误码/过期/已用/不存在实体
- **预期结果**：均返回 false，且不置 used
- **自动化测试函数/脚本位置**：同 UT-031
- **测试过程与结论**：（runtest 记录）

#### UT-034：验证码用途隔离（P1）
- **用例ID**：UT-034
- **用例名称**：verifyCode(target, code, purpose) 按用途过滤
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P1
- **前置条件**：同 UT-031
- **测试类型**：单元测试
- **关联需求ID**：F-008
- **测试步骤**：mock selectLatestByTargetAndPurpose 返回 null（用途不匹配）
- **预期结果**：返回 false（不同用途不通用）
- **自动化测试函数/脚本位置**：同 UT-031
- **测试过程与结论**：（runtest 记录）

#### UT-035：验证码频率控制与 Redis 容错（P1）
- **用例ID**：UT-035
- **用例名称**：isSendTooFrequent 命中/未命中/Redis 异常放行
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P1
- **前置条件**：同 UT-031
- **测试类型**：单元测试
- **关联需求ID**：F-008 / NFR-002
- **测试步骤**：mock hasKey=true/false/抛异常
- **预期结果**：true/false/false（异常放行）
- **自动化测试函数/脚本位置**：同 UT-031
- **测试过程与结论**：（runtest 记录）

#### UT-036：验证码过期清理（P1）
- **用例ID**：UT-036
- **用例名称**：cleanExpiredCodes 删除过期记录
- **所属模块**：auth-service / VerificationCodeManager
- **优先级**：P1
- **前置条件**：同 UT-031
- **测试类型**：单元测试
- **关联需求ID**：F-008
- **测试步骤**：调用 cleanExpiredCodes
- **预期结果**：deleteExpired(now) 被调用
- **自动化测试函数/脚本位置**：同 UT-031
- **测试过程与结论**：（runtest 记录）

### 模块：密码管理（F-006） - 接口测试

#### TC-023：修改密码成功（P0）
- **用例ID**：TC-023
- **用例名称**：修改密码成功且新密码可登录
- **所属模块**：auth-service / 密码
- **优先级**：P0
- **前置条件**：测试用户已登录
- **测试类型**：接口测试
- **关联需求ID**：F-006 / US-004
- **测试数据**：oldPassword=Old@12345，newPassword=New@54321，confirmPassword=New@54321
- **测试步骤**：
  1. PUT /api/v1/auth/password/change
  2. 用新密码重新登录
- **预期结果**：修改 code=200；新密码登录成功
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc023_change_password_success
- **测试过程与结论**：（runtest 记录）

#### TC-024：修改密码旧密码错误被拒（P0）
- **用例ID**：TC-024
- **用例名称**：旧密码错误修改被拒
- **所属模块**：auth-service / 密码
- **优先级**：P0
- **前置条件**：同 TC-023
- **测试类型**：接口测试
- **关联需求ID**：F-006 / US-004
- **测试数据**：oldPassword=WrongOld@1
- **测试步骤**：PUT /api/v1/auth/password/change
- **预期结果**：返回 400/422（OLD_PASSWORD_INCORRECT）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc024_change_password_wrong_old
- **测试过程与结论**：（runtest 记录）

#### TC-025：密码找回发送验证码成功（P0）
- **用例ID**：TC-025
- **用例名称**：找回密码发送验证码成功/未绑定账号被拒
- **所属模块**：auth-service / 密码
- **优先级**：P0
- **前置条件**：测试用户已绑定手机号
- **测试类型**：接口测试
- **关联需求ID**：F-006 / US-004
- **测试数据**：target=已绑定手机号；未绑定手机号
- **测试步骤**：POST /api/v1/auth/password/forgot/send-code
- **预期结果**：绑定目标 200；未绑定目标 400/404/422（USER_NOT_FOUND）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc025_forgot_send_code
- **测试过程与结论**：（runtest 记录）

#### TC-026：密码找回重置成功且旧 Token 失效（P0）
- **用例ID**：TC-026
- **用例名称**：重置密码成功、旧 Token 全端失效、错误码被拒
- **所属模块**：auth-service / 密码
- **优先级**：P0
- **前置条件**：同 TC-025
- **测试类型**：接口测试
- **关联需求ID**：F-006 / US-004
- **测试数据**：target+code+newPassword；错误 code=999999
- **测试步骤**：
  1. 发送找回验证码并读取
  2. POST /password/forgot/reset
  3. 用旧 Token 访问受保护接口
  4. 新密码登录
  5. 错误验证码重置
- **预期结果**：重置 200；旧 Token 401；新密码登录成功；错误码 400/422
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc026_forgot_reset
- **测试过程与结论**：（runtest 记录）

#### UT-037：PasswordService 修改密码成功与全端下线（P0）
- **用例ID**：UT-037
- **用例名称**：changePassword 校验旧密码、更新密码、removeAllSessions
- **所属模块**：auth-service / PasswordService
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-006 / US-004
- **测试步骤**：mock 用户与 BCrypt 比对通过，调用 changePassword
- **预期结果**：updateById 调用；removeAllSessions 调用；密码为 BCrypt 密文
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../service/PasswordServiceTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-038：PasswordService 旧密码错误/新旧相同被拒（P0）
- **用例ID**：UT-038
- **用例名称**：changePassword 旧密码错误与新旧相同异常
- **所属模块**：auth-service / PasswordService
- **优先级**：P0
- **前置条件**：同 UT-037
- **测试类型**：单元测试
- **关联需求ID**：F-006 / US-004
- **测试步骤**：mock 比对失败；新旧密码相同
- **预期结果**：分别抛 OLD_PASSWORD_INCORRECT 与 新密码不能与旧密码相同
- **自动化测试函数/脚本位置**：同 UT-037
- **测试过程与结论**：（runtest 记录）

#### UT-039：PasswordService 找回发送/重置（P0）
- **用例ID**：UT-039
- **用例名称**：forgotPasswordSendCode/Reset 成功与失败分支
- **所属模块**：auth-service / PasswordService
- **优先级**：P0
- **前置条件**：同 UT-037
- **测试类型**：单元测试
- **关联需求ID**：F-006 / US-004
- **测试步骤**：发送（账号存在/不存在）；重置（验证码有效/无效）
- **预期结果**：存在发送成功、不存在抛 USER_NOT_FOUND；验证码有效重置成功并全端下线、无效抛 SMS_CODE_INVALID
- **自动化测试函数/脚本位置**：同 UT-037
- **测试过程与结论**：（runtest 记录）

#### UT-040：PasswordService 换绑手机（P0）
- **用例ID**：UT-040
- **用例名称**：changePhone 旧手机短信/邮箱场景与占用拒绝
- **所属模块**：auth-service / PasswordService
- **优先级**：P0
- **前置条件**：同 UT-037
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-004
- **测试步骤**：oldPhoneCode 场景；emailCode 场景；新手机号被占用
- **预期结果**：验证码有效更新手机号；新手机号被占用抛 PHONE_ALREADY_BOUND；缺少验证码 400
- **自动化测试函数/脚本位置**：同 UT-037
- **测试过程与结论**：（runtest 记录）

#### UT-041：PasswordService 密码边界（8/64 位）（P1）
- **用例ID**：UT-041
- **用例名称**：修改/重置密码长度边界校验
- **所属模块**：auth-service / PasswordService
- **优先级**：P1
- **前置条件**：同 UT-037
- **测试类型**：单元测试
- **关联需求ID**：F-006 / NFR-003
- **测试数据**：newPassword=7/65 位
- **测试步骤**：构造请求校验
- **预期结果**：7/65 位被拒（400）
- **自动化测试函数/脚本位置**：同 UT-037（参数化子场景）
- **测试过程与结论**：（runtest 记录）

### 模块：手机号变更（F-007） - 接口测试

#### TC-027：短信验证码变更手机号成功（含占用/不一致拒绝）（P0）
- **用例ID**：TC-027
- **用例名称**：原手机验证码换绑成功、占用拒绝、验证码不一致拒绝
- **所属模块**：auth-service / 手机号
- **优先级**：P0
- **前置条件**：测试用户 A/C 已绑定手机号；用户 B 绑定目标手机号
- **测试类型**：接口测试
- **关联需求ID**：F-007 / US-004
- **测试数据**：newPhone/oldPhoneCode/newPhoneCode（CHANGE_PHONE 用途）
- **测试步骤**：
  1. 向原手机号与新手机号发送 CHANGE_PHONE 验证码并读取
  2. PUT /api/v1/auth/phone/change（场景：旧手机短信）
  3. 新手机号被占用场景
  4. 旧手机验证码错误场景
- **预期结果**：变更成功 code=200；占用 409（PHONE_ALREADY_BOUND）；错误验证码 400/409/422
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc027_change_phone
- **测试过程与结论**：（runtest 记录）

#### UT-042：手机号变更-邮箱验证码场景（P1）
- **用例ID**：UT-042
- **用例名称**：changePhone emailCode 场景成功
- **所属模块**：auth-service / PasswordService
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-004
- **测试步骤**：mock 用户绑定邮箱，emailCode 校验通过
- **预期结果**：手机号更新成功
- **自动化测试函数/脚本位置**：同 UT-040（PasswordServiceTest）
- **测试过程与结论**：（runtest 记录）

### 模块：RBAC 权限模型（F-009/F-010） - 接口测试

#### TC-044：多租户隔离-跨租户数据不可见（P0）
- **用例ID**：TC-044
- **用例名称**：租户数据隔离生效
- **所属模块**：auth-service / 多租户
- **优先级**：P0
- **前置条件**：管理员已登录（DEFAULT 租户）
- **测试类型**：接口测试
- **关联需求ID**：F-010 / US-005
- **测试数据**：GET /users（带租户头）；跨租户参数 tenantId=999999
- **测试步骤**：
  1. 管理员查询用户列表
  2. 校验列表内用户均属 DEFAULT 租户
  3. 跨租户条件查询
- **预期结果**：列表用户租户编码均为 DEFAULT；跨租户查询不返回其他租户数据
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc044_tenant_isolation
- **测试过程与结论**：（runtest 记录）

#### UT-043：多租户-用户名/角色编码租户内唯一（P0）
- **用例ID**：UT-043
- **用例名称**：不同租户可存在相同用户名；同租户唯一
- **所属模块**：auth-service / 多租户
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-010 / US-005
- **测试步骤**：mock 租户 A/B 数据隔离查询
- **预期结果**：唯一性校验按 tenantId 维度执行
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/UserServiceImplTest.java（存量，register_shouldThrowBusinessException_whenLoginNameDuplicate 等）
- **测试过程与结论**：（runtest 记录）

#### UT-044：RBAC 权限计算-角色权限并集（P0）
- **用例ID**：UT-044
- **用例名称**：用户权限为所分配角色权限并集
- **所属模块**：auth-service / RBAC
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-009
- **测试步骤**：mock selectRoleCodesByUserId/selectPermissionCodesByUserId
- **预期结果**：登录/刷新时 JWT claims 与 DTO 含角色权限并集
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/TokenServiceImplTest.java（refresh_shouldBuildCorrectLoginUserDTO）等
- **测试过程与结论**：（runtest 记录）

### 模块：用户管理（F-011） - 接口测试

#### TC-029：用户分页查询（P0）
- **用例ID**：TC-029
- **用例名称**：管理员分页查询用户列表
- **所属模块**：auth-service / 用户管理
- **优先级**：P0
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-011 / US-005
- **测试数据**：GET /users?page=1&pageSize=10&keyword=admin
- **测试步骤**：GET /api/v1/auth/users
- **预期结果**：code=200；data 含 records/total/page/pageSize；记录不含密码字段
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc029_user_page_query
- **测试过程与结论**：（runtest 记录）

#### TC-030：用户详情查询（P0）
- **用例ID**：TC-030
- **用例名称**：用户详情查询与不存在用户
- **所属模块**：auth-service / 用户管理
- **优先级**：P0
- **前置条件**：同 TC-029
- **测试类型**：接口测试
- **关联需求ID**：F-011 / US-005
- **测试数据**：GET /users/{id}；GET /users/999999999
- **测试步骤**：查询详情；查询不存在用户
- **预期结果**：详情 code=200 且无密码字段；不存在返回 400/404/422
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc030_user_detail
- **测试过程与结论**：（runtest 记录）

#### TC-031：更新用户信息（P1）
- **用例ID**：TC-031
- **用例名称**：更新用户姓名/邮箱
- **所属模块**：auth-service / 用户管理
- **优先级**：P1
- **前置条件**：同 TC-029
- **测试类型**：接口测试
- **关联需求ID**：F-011 / US-005
- **测试数据**：PUT /users/{id} {userName, email}
- **测试步骤**：更新用户信息
- **预期结果**：code=200
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc031_user_update
- **测试过程与结论**：（runtest 记录）

#### TC-032：用户启禁用-登录态实时失效（P0）
- **用例ID**：TC-032
- **用例名称**：封禁用户登录态与再次登录均被拒
- **所属模块**：auth-service / 用户管理
- **优先级**：P0
- **前置条件**：管理员已登录；目标用户已登录
- **测试类型**：接口测试
- **关联需求ID**：F-011 / US-005
- **测试数据**：PUT /users/{id}/status {status:3}
- **测试步骤**：
  1. 管理员封禁用户
  2. 用用户旧 Token 访问
  3. 用户重新登录
- **预期结果**：封禁 200；旧 Token 访问 401/403；重新登录 403
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc032_user_status_disable
- **测试过程与结论**：（runtest 记录）

#### TC-033：分配用户角色（P1）
- **用例ID**：TC-033
- **用例名称**：为用户分配角色成功
- **所属模块**：auth-service / 用户管理
- **优先级**：P1
- **前置条件**：同 TC-029；角色列表非空
- **测试类型**：接口测试
- **关联需求ID**：F-009 / F-011 / US-005
- **测试数据**：PUT /users/{id}/roles {roleIds:[roleId]}
- **测试步骤**：分配角色
- **预期结果**：code=200
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc033_user_assign_roles
- **测试过程与结论**：（runtest 记录）

#### UT-045：UserService 用户 CRUD 与状态管理（P0）
- **用例ID**：UT-045
- **用例名称**：用户注册/封禁/解封/锁定/解锁/删除各分支
- **所属模块**：auth-service / UserService
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-011 / US-005
- **测试步骤**：调用 register/ban/unban/lock/unlock 等，覆盖已封禁/不存在/null 分支
- **预期结果**：成功分支正常；已处目标状态跳过；不存在/null 抛异常
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/UserServiceImplTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-046：UserService 唯一性与租户校验（P0）
- **用例ID**：UT-046
- **用例名称**：注册登录名重复/租户不存在/租户禁用/过期
- **所属模块**：auth-service / UserService
- **优先级**：P0
- **前置条件**：同 UT-045
- **测试类型**：单元测试
- **关联需求ID**：F-010 / F-011
- **测试步骤**：mock 各分支
- **预期结果**：分别抛 登录名已存在 / 租户不存在 / TENANT_DISABLED / TENANT_EXPIRED
- **自动化测试函数/脚本位置**：同 UT-045
- **测试过程与结论**：（runtest 记录）

#### UT-047：UserController 各端点参数与响应（P1）
- **用例ID**：UT-047
- **用例名称**：用户控制器分页/详情/更新/删除/角色/状态端点
- **所属模块**：auth-service / UserController
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-011
- **测试步骤**：调用各端点方法
- **预期结果**：返回统一 ApiResult；详情不存在返回 error(USER_NOT_FOUND)
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../controller/UserControllerTest.java（存量）
- **测试过程与结论**：（runtest 记录）

### 模块：角色管理（F-012） - 接口测试

#### TC-034：创建角色成功（P0）
- **用例ID**：TC-034
- **用例名称**：创建角色成功返回角色信息
- **所属模块**：auth-service / 角色管理
- **优先级**：P0
- **前置条件**：管理员已登录
- **测试类型**：接口测试
- **关联需求ID**：F-012 / US-005
- **测试数据**：POST /roles {roleCode, roleName}
- **测试步骤**：创建角色
- **预期结果**：code=200，data.roleCode 匹配，含 id
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc034_role_create
- **测试过程与结论**：（runtest 记录）

#### TC-035：角色编码租户内重复被拒（P0）
- **用例ID**：TC-035
- **用例名称**：角色编码重复创建被拒
- **所属模块**：auth-service / 角色管理
- **优先级**：P0
- **前置条件**：同 TC-034；SUPER_ADMIN 角色存在
- **测试类型**：接口测试
- **关联需求ID**：F-012 / US-005
- **测试数据**：roleCode=SUPER_ADMIN
- **测试步骤**：创建重复角色
- **预期结果**：返回 409
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc035_role_duplicate_code
- **测试过程与结论**：（runtest 记录）

#### TC-036：删除角色-被引用不可删（P0）
- **用例ID**：TC-036
- **用例名称**：未引用角色可删、被分配角色删除被拒
- **所属模块**：auth-service / 角色管理
- **优先级**：P0
- **前置条件**：同 TC-034
- **测试类型**：接口测试
- **关联需求ID**：F-012 / US-005
- **测试数据**：新建未引用角色；SUPER_ADMIN 被引用角色
- **测试步骤**：删除未引用角色；删除被引用角色
- **预期结果**：未引用删除 200；被引用删除 409
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc036_role_delete
- **测试过程与结论**：（runtest 记录）

#### TC-037：角色分配权限（P1）
- **用例ID**：TC-037
- **用例名称**：为角色分配权限成功
- **所属模块**：auth-service / 角色管理
- **优先级**：P1
- **前置条件**：同 TC-034；权限树非空
- **测试类型**：接口测试
- **关联需求ID**：F-009 / F-012 / US-005
- **测试数据**：PUT /roles/{id}/permissions {permissionIds:[...]}
- **测试步骤**：分配权限
- **预期结果**：code=200
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc037_role_assign_permissions
- **测试过程与结论**：（runtest 记录）

#### UT-048：RoleService 角色 CRUD（P0）
- **用例ID**：UT-048
- **用例名称**：角色分页/全量/详情/创建/更新/删除/分配权限各分支
- **所属模块**：auth-service / RoleService
- **优先级**：P0
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-012 / US-005
- **测试步骤**：调用各方法，覆盖编码冲突/不存在/被引用分支
- **预期结果**：成功分支正常；重复编码抛异常；被引用删除抛异常
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../impl/RoleServiceImplTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-049：RoleController 端点与权限分配（P1）
- **用例ID**：UT-049
- **用例名称**：角色控制器各端点
- **所属模块**：auth-service / RoleController
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-012
- **测试步骤**：调用各端点
- **预期结果**：统一 ApiResult 返回
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../controller/RoleControllerTest.java（存量）
- **测试过程与结论**：（runtest 记录）

### 模块：权限管理（F-013） - 接口测试

#### TC-038：权限树查询（P0）
- **用例ID**：TC-038
- **用例名称**：树形权限列表查询
- **所属模块**：auth-service / 权限管理
- **优先级**：P0
- **前置条件**：管理员已登录；基础权限数据存在
- **测试类型**：接口测试
- **关联需求ID**：F-013 / US-005
- **测试数据**：GET /permissions
- **测试步骤**：查询权限树
- **预期结果**：code=200，data 为列表且含 children 结构
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc038_permission_tree
- **测试过程与结论**：（runtest 记录）

#### TC-039：创建权限与编码重复被拒（P0）
- **用例ID**：TC-039
- **用例名称**：创建权限成功与编码重复拒绝
- **所属模块**：auth-service / 权限管理
- **优先级**：P0
- **前置条件**：同 TC-038
- **测试类型**：接口测试
- **关联需求ID**：F-013 / US-005
- **测试数据**：POST /permissions {permCode, permName, parentId}
- **测试步骤**：创建权限；重复创建
- **预期结果**：创建 200/201；重复 409
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc039_permission_create
- **测试过程与结论**：（runtest 记录）

#### TC-040：更新/删除权限-子权限约束（P1）
- **用例ID**：TC-040
- **用例名称**：更新权限、有子权限删除父权限被拒
- **所属模块**：auth-service / 权限管理
- **优先级**：P1
- **前置条件**：同 TC-038
- **测试类型**：接口测试
- **关联需求ID**：F-013 / US-005
- **测试数据**：父权限+子权限
- **测试步骤**：
  1. 更新父权限
  2. 删除含子权限的父权限
  3. 先删子权限再删父权限
- **预期结果**：更新 200；有子权限删除 409；子权限删除后父权限可删
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc040_permission_update_delete
- **测试过程与结论**：（runtest 记录）

#### UT-050：PermissionService 权限 CRUD 与树形（P1）
- **用例ID**：UT-050
- **用例名称**：权限树/列表/详情/创建/更新/删除分支
- **所属模块**：auth-service / PermissionService
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-013 / US-005
- **测试步骤**：调用各方法，覆盖编码重复/被关联删除分支
- **预期结果**：成功分支正常；异常分支抛对应业务异常
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../controller/PermissionControllerTest.java（存量）及 service 层（后续补充）
- **测试过程与结论**：（runtest 记录）

#### UT-051：PermissionController 端点（P1）
- **用例ID**：UT-051
- **用例名称**：权限控制器各端点统一响应
- **所属模块**：auth-service / PermissionController
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-013
- **测试步骤**：调用各端点
- **预期结果**：统一 ApiResult 返回
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../controller/PermissionControllerTest.java（存量）
- **测试过程与结论**：（runtest 记录）

### 模块：网关认证（F-005/F-018） - 接口测试

#### TC-041：白名单接口免 Token 放行（P0）
- **用例ID**：TC-041
- **用例名称**：健康检查与登录白名单免认证
- **所属模块**：gateway
- **优先级**：P0
- **前置条件**：网关/服务已启动
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-006
- **测试数据**：GET /api/v1/auth/health；POST /login
- **测试步骤**：无 Token 访问白名单接口
- **预期结果**：均返回 200
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc041_gateway_whitelist
- **测试过程与结论**：（runtest 记录）

#### TC-042：无 Token/伪造 Token 访问受保护接口返回 401（P0）
- **用例ID**：TC-042
- **用例名称**：缺失/伪造/非 Bearer Token 被拒
- **所属模块**：gateway
- **优先级**：P0
- **前置条件**：同 TC-041
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-006
- **测试数据**：无 Authorization；fake.token.value；Basic dGVzdDoxMjM=
- **测试步骤**：三种方式访问 /api/v1/auth/users
- **预期结果**：均返回 401
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc042_gateway_no_or_fake_token
- **测试过程与结论**：（runtest 记录）

#### TC-043：缺少租户头访问用户列表被拒（P0）
- **用例ID**：TC-043
- **用例名称**：直连认证服务缺少 X-Tenant-Id 返回 400
- **所属模块**：auth-service（直连） / gateway
- **优先级**：P0
- **前置条件**：认证服务 :9100 可直连
- **测试类型**：接口测试
- **关联需求ID**：F-005 / F-010 / US-006
- **测试数据**：直连 GET http://localhost:9100/api/v1/auth/users（无 X-Tenant-Id）
- **测试步骤**：
  1. 携带合法 Token 直连认证服务查询用户列表（不带头）
  2. 经网关访问（网关透传 X-Tenant-Id）对照
- **预期结果**：
  1. 直连缺头返回 400（MissingRequestHeaderException）
  2. 网关路径正常 200（透传头生效）；说明：本版本管理接口未启用接口级角色鉴权（LLD 6.6，随业务版本演进）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc043_gateway_forbidden
- **测试过程与结论**：（runtest 记录）

#### UT-052：AuthFilter 网关 9 步认证（P0）
- **用例ID**：UT-052
- **用例名称**：白名单/格式/验签/tokenType/黑名单/会话/账号/租户/透传 9 步校验
- **所属模块**：gateway / AuthFilter
- **优先级**：P0
- **前置条件**：WebFlux 测试环境（MockServerWebExchange）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-006
- **测试步骤**：构造各失败场景与成功场景调用 filter
- **预期结果**：白名单放行；格式错误/验签失败/黑名单/会话缺失 401；账号封禁/租户停用 403；成功透传 X-User-Id 等头
- **自动化测试函数/脚本位置**：cloudoffice-gateway/src/test/.../filter/AuthFilterTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-053：网关 RsaKeyConfig/RedisConfig/AuthProperties（P1）
- **用例ID**：UT-053
- **用例名称**：网关公钥加载、Redis 模板与白名单配置
- **所属模块**：gateway / config
- **优先级**：P1
- **前置条件**：测试环境
- **测试类型**：单元测试
- **关联需求ID**：F-005
- **测试步骤**：加载配置类
- **预期结果**：公钥解析正确；白名单列表可注入；Redis 模板创建成功
- **自动化测试函数/脚本位置**：cloudoffice-gateway/src/test/.../config/*Test.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-054：common 统一响应与异常体系（P0）
- **用例ID**：UT-054
- **用例名称**：ApiResult/PageResult 序列化与错误码完整性
- **所属模块**：common
- **优先级**：P0
- **前置条件**：测试环境
- **测试类型**：单元测试
- **关联需求ID**：F-018
- **测试步骤**：构建成功/错误响应；校验 29 个错误码
- **预期结果**：成功 code=200；错误映射正确；错误码无重复无遗漏
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/.../（ApiResultTest/ErrorCodeTest 等存量）
- **测试过程与结论**：（runtest 记录）

#### UT-055：common 全局异常处理器（P0）
- **用例ID**：UT-055
- **用例名称**：GlobalExceptionHandler 各类异常兜底不泄露堆栈
- **所属模块**：common
- **优先级**：P0
- **前置条件**：测试环境
- **测试类型**：单元测试
- **关联需求ID**：F-018 / NFR-007
- **测试步骤**：触发参数校验/类型转换/业务/认证/兜底异常
- **预期结果**：统一 ApiResult；响应不含堆栈；兜底 500
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/.../exception/GlobalExceptionHandlerTest.java（存量）
- **测试过程与结论**：（runtest 记录）

#### UT-056：common 枚举与 DTO（P1）
- **用例ID**：UT-056
- **用例名称**：客户端类型/登录模式/注册模式枚举与 DTO 序列化
- **所属模块**：common
- **优先级**：P1
- **前置条件**：测试环境
- **测试类型**：单元测试
- **关联需求ID**：F-018
- **测试步骤**：校验枚举值与 DTO 字段
- **预期结果**：枚举值齐全；DTO 序列化正确
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/.../（ClientTypeEnumTest/TokenPairDTOTest 等存量）
- **测试过程与结论**：（runtest 记录）

### 模块：健康检查（F-016） - 接口测试

#### TC-045：认证/企业/系统服务健康检查（P1）
- **用例ID**：TC-045
- **用例名称**：三服务健康检查端点
- **所属模块**：auth/biz/system
- **优先级**：P1
- **前置条件**：三服务与网关已启动
- **测试类型**：接口测试
- **关联需求ID**：F-016 / US-006
- **测试数据**：/api/v1/auth/health（白名单）；/api/v1/biz/health、/api/v1/system/health（需认证）
- **测试步骤**：auth health 直接访问；biz/system health 带 Token 访问
- **预期结果**：均 code=200，data.service 匹配、status=UP
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.0.1.py :: test_tc045_health_checks
- **测试过程与结论**：（runtest 记录）

#### UT-057：HealthController 健康检查响应（P1）
- **用例ID**：UT-057
- **用例名称**：健康检查返回服务名/状态/版本/时间戳
- **所属模块**：auth-service / HealthController
- **优先级**：P1
- **前置条件**：Mockito 环境
- **测试类型**：单元测试
- **关联需求ID**：F-016
- **测试步骤**：调用 health 端点
- **预期结果**：ApiResult data 含 service/status/version/timestamp
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../controller/HealthControllerTest.java（存量）
- **测试过程与结论**：（runtest 记录）

### 模块：认证编排（F-002/F-003/F-004 核心链路） - 单元测试

#### UT-058：AuthenticationService 登录成功全流程（P0）
- **用例ID**：UT-058
- **用例名称**：authenticate 策略认证→状态校验→签发双 Token→会话→日志
- **所属模块**：auth-service / AuthenticationService
- **优先级**：P0
- **前置条件**：Mockito 环境（模拟策略工厂/Token/会话/日志）
- **测试类型**：单元测试
- **关联需求ID**：F-002 / F-003
- **测试步骤**：mock 策略认证成功与用户/租户状态正常，调用 authenticate
- **预期结果**：返回 TokenPairDTO；createSession/setAccountStatus/setTenantStatus/recordLoginSuccess 被调用；同端互斥清理旧会话
- **自动化测试函数/脚本位置**：cloudoffice-auth-service/src/test/.../service/AuthenticationServiceTest.java（初始化新增）
- **测试过程与结论**：（runtest 记录）

#### UT-059：AuthenticationService 状态矩阵（P0）
- **用例ID**：UT-059
- **用例名称**：用户 5 状态×租户 3 状态×未完善账号登录被拒
- **所属模块**：auth-service / AuthenticationService
- **优先级**：P0
- **前置条件**：同 UT-058
- **测试类型**：单元测试
- **关联需求ID**：F-002 / F-010 / US-002
- **测试步骤**：逐一 mock 用户状态（0/1/2/3/4）、租户状态（0/1/2/过期）、accountSettled=0
- **预期结果**：异常状态分别抛 ACCOUNT_DISABLED/LOCKED/BANNED/EXPIRED、TENANT_DISABLED/TENANT_EXPIRED、ACCOUNT_NOT_SETTLED；正常组合登录成功
- **自动化测试函数/脚本位置**：同 UT-058
- **测试过程与结论**：（runtest 记录）

#### UT-060：AuthenticationService Redis 失败容错与互斥（P0）
- **用例ID**：UT-060
- **用例名称**：Redis 会话写入失败不影响登录；同端互斥遍历清理
- **所属模块**：auth-service / AuthenticationService
- **优先级**：P0
- **前置条件**：同 UT-058
- **测试类型**：单元测试
- **关联需求ID**：F-004 / NFR-002
- **测试步骤**：mock createSession/setAccountStatus 抛异常；mock 同设备分类存在旧会话
- **预期结果**：登录仍返回 Token（容错）；同设备分类旧会话被 removeSession
- **自动化测试函数/脚本位置**：同 UT-058
- **测试过程与结论**：（runtest 记录）

### 模块：功能测试（端到端）

#### FT-001：注册-登录-首页全流程（P0）
- **用例ID**：FT-001
- **用例名称**：新用户注册自动登录进入系统
- **所属模块**：端到端（客户端+网关+认证服务）
- **优先级**：P0
- **前置条件**：全链路环境已部署（网关 9000、auth 9100、DB、Redis）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / F-002 / US-001
- **测试数据**：随机用户名/密码/租户 DEFAULT
- **测试步骤**：
  1. 注册新用户
  2. 使用返回/新登录的双 Token 访问受保护接口
  3. 登出
- **预期结果**：注册成功、Token 可用、登出后失效，全流程闭环
- **自动化测试函数/脚本位置**：由 runtest 阶段按 TC-001/TC-005/TC-015 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-002：Token 过期自动刷新重试（P0）
- **用例ID**：FT-002
- **用例名称**：401 后携带 Refresh Token 刷新并重试原请求
- **所属模块**：端到端
- **优先级**：P0
- **前置条件**：同 FT-001
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-007
- **测试步骤**：
  1. 登录获得双 Token
  2. 登出使旧 Token 失效后模拟 401
  3. 用 Refresh Token 刷新并重试
- **预期结果**：刷新成功换发新 Token，重试请求成功；Refresh 失效时提示重新登录
- **自动化测试函数/脚本位置**：按 TC-011/TC-012/TC-015 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-003：管理员封禁-踢人-解封闭环（P0）
- **用例ID**：FT-003
- **用例名称**：管理员风险处置全流程
- **所属模块**：端到端
- **优先级**：P0
- **前置条件**：管理员与普通用户各一
- **测试类型**：功能测试
- **关联需求ID**：F-004 / F-011 / US-003 / US-005
- **测试步骤**：封禁→旧 Token 失效→解封→重新登录→强制踢人→Token 失效
- **预期结果**：每一步实时生效
- **自动化测试函数/脚本位置**：按 TC-009/TC-017/TC-032 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-004：忘记密码全流程（P0）
- **用例ID**：FT-004
- **用例名称**：发送重置验证码→重置密码→新密码登录
- **所属模块**：端到端
- **优先级**：P0
- **前置条件**：同 FT-001；测试用户已绑定手机号
- **测试类型**：功能测试
- **关联需求ID**：F-006 / US-004
- **测试步骤**：找回发送码→重置→旧 Token 失效→新密码登录
- **预期结果**：全流程成功
- **自动化测试函数/脚本位置**：按 TC-025/TC-026 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-005：换绑手机号全流程（P1）
- **用例ID**：FT-005
- **用例名称**：原手机验证码换绑新手机号并用新手机号登录
- **所属模块**：端到端
- **优先级**：P1
- **前置条件**：同 FT-001
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-004
- **测试步骤**：发送新旧手机验证码→换绑→新手机号登录
- **预期结果**：换绑成功，新手机号可登录
- **自动化测试函数/脚本位置**：按 TC-027 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-006：两步注册补全闭环（P0）
- **用例ID**：FT-006
- **用例名称**：OAuth 注册→未完善登录被拒→补全→登录成功
- **所属模块**：端到端
- **优先级**：P0
- **前置条件**：OAuth 模拟可用
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001
- **测试步骤**：OAuth 注册→未完善账号登录（被拒）→补全→登录
- **预期结果**：未完善被拒（ACCOUNT_NOT_SETTLED）；补全后登录成功
- **自动化测试函数/脚本位置**：按 TC-003/TC-028 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-007：验证码发送频率与一次性（P1）
- **用例ID**：FT-007
- **用例名称**：验证码 60 秒限频与一次性使用（客户端倒计时联动）
- **所属模块**：端到端
- **优先级**：P1
- **前置条件**：同 FT-001
- **测试类型**：功能测试
- **关联需求ID**：F-008 / US-008
- **测试步骤**：连续发送→限频；使用一次后复用→被拒
- **预期结果**：限频与一次性生效
- **自动化测试函数/脚本位置**：按 TC-019/TC-020/TC-021 组合执行
- **测试过程与结论**：（runtest 记录）

#### FT-008：多租户数据隔离（P0）
- **用例ID**：FT-008
- **用例名称**：两个租户数据互不可见
- **所属模块**：端到端
- **优先级**：P0
- **前置条件**：存在两个租户（DEFAULT 与测试租户）
- **测试类型**：功能测试
- **关联需求ID**：F-010 / US-005
- **测试步骤**：租户 A 管理员查列表→租户 B 管理员查列表→比对
- **预期结果**：各自仅见本租户数据
- **自动化测试函数/脚本位置**：按 TC-044 组合执行
- **测试过程与结论**：（runtest 记录）

### 模块：UI 测试（Flutter 客户端，F-015）

#### UIT-001：登录页多模式切换（P1）
- **用例ID**：UIT-001
- **用例名称**：登录页可切换登录模式并提交
- **所属模块**：cloudoffice-flutter-app / login_screen.dart
- **优先级**：P1
- **前置条件**：客户端已构建（Web/Windows），网关可达
- **测试类型**：UI测试
- **关联需求ID**：F-015 / US-007
- **测试数据**：admin/admin123/DEFAULT
- **测试步骤**：启动客户端→切换登录模式→输入凭据→登录
- **预期结果**：登录成功进入首页；表单本地校验生效
- **自动化测试函数/脚本位置**：flutter_test（后续版本补充，UI 测试记录见 {cso}-ui-test-record）
- **测试过程与结论**：（runtest 记录）

#### UIT-002：注册页双模式与验证码倒计时（P1）
- **用例ID**：UIT-002
- **用例名称**：注册页用户名/手机模式与发送验证码倒计时
- **所属模块**：cloudoffice-flutter-app / register_screen.dart
- **优先级**：P1
- **前置条件**：同 UIT-001
- **测试类型**：UI测试
- **关联需求ID**：F-015 / US-001 / US-008
- **测试步骤**：进入注册页→切换模式→发送验证码→注册
- **预期结果**：注册成功自动登录；发送按钮 60 秒倒计时
- **自动化测试函数/脚本位置**：flutter_test（后续版本补充）
- **测试过程与结论**：（runtest 记录）

#### UIT-003：忘记密码页流程（P1）
- **用例ID**：UIT-003
- **用例名称**：忘记密码页发送验证码与重置
- **所属模块**：cloudoffice-flutter-app / forgot_password_screen.dart
- **优先级**：P1
- **前置条件**：同 UIT-001
- **测试类型**：UI测试
- **关联需求ID**：F-015 / US-004
- **测试步骤**：进入忘记密码页→输入手机号→发送验证码→重置密码→登录
- **预期结果**：重置成功可重新登录
- **自动化测试函数/脚本位置**：flutter_test（后续版本补充）
- **测试过程与结论**：（runtest 记录）

#### UIT-004：Token 安全存储与启动恢复（P1）
- **用例ID**：UIT-004
- **用例名称**：重启应用恢复登录态
- **所属模块**：cloudoffice-flutter-app / auth provider
- **优先级**：P1
- **前置条件**：同 UIT-001
- **测试类型**：UI测试
- **关联需求ID**：F-015 / US-007
- **测试步骤**：登录→重启应用→自动恢复
- **预期结果**：启动后保持登录态（flutter_secure_storage 恢复）
- **自动化测试函数/脚本位置**：flutter_test（后续版本补充）
- **测试过程与结论**：（runtest 记录）

#### UIT-005：401 自动刷新与路由守卫（P1）
- **用例ID**：UIT-005
- **用例名称**：Token 过期自动刷新；未登录访问受限页跳登录
- **所属模块**：cloudoffice-flutter-app / api_interceptor.dart / router
- **优先级**：P1
- **前置条件**：同 UIT-001
- **测试类型**：UI测试
- **关联需求ID**：F-015 / F-003 / US-007
- **测试步骤**：构造 401 场景→观察自动刷新重试；未登录访问首页→跳转登录
- **预期结果**：自动刷新成功重试；受限路由被守卫拦截
- **自动化测试函数/脚本位置**：flutter_test（后续版本补充）
- **测试过程与结论**：（runtest 记录）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 待执行 |
| 失败 | 待执行 |
| 阻塞 | 0 |
| 跳过 | 待执行 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 文档与实现契约差异（登录模式枚举、验证码字段 channel/mode、注册响应字段） | 接口测试脚本按错误契约断言将误报失败 | 脚本以实际代码 DTO 契约为准，文档已同步；差异已在本文档用例中标注 |
| 模拟验证码模式不返回验证码（仅日志） | 验证码类用例无法闭环 | 脚本通过 MySQL 读取 t_auth_verification_code 获取验证码（pymysql 可选，不可用时标记 SKIP） |
| biz/system 健康检查未入网关白名单 | TC-045 直接访问被 401 | 脚本带 Token 访问 biz/system 健康检查；或直连服务端口 |
| 本版本管理接口未启用接口级角色鉴权（LLD 6.6） | 原"普通用户访问管理接口 403"预期不成立 | TC-043 改为缺 X-Tenant-Id 头 400 验证；接口级鉴权随业务版本演进 |
| OAuth 策略依赖第三方授权环境 | TC-003/TC-028 前置不可用时无法闭环 | 脚本对不可用场景标记 SKIP，不视为失败 |
| 部分存量模块缺少独立单元测试（AuthenticationService/PasswordService/VerificationCodeManager/策略类） | 核心链路分支覆盖不足 | 初始化阶段补充对应测试类（见用例 UT-001~UT-060 标注） |

## 五、签名确认
- 测试工程师（TE）：待执行
- 项目经理（PM）：待执行

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
