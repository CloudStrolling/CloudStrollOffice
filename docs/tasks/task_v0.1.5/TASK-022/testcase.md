# 测试用例文档

**项目名称：** CloudStrollOffice（云逛办公）
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.5
**日期：** 2026-06-23

---

## 模块：认证服务（cloudoffice-auth-service） - 登录认证业务逻辑

### TC-TASK-022-001：正常登录成功（P0）

**前置条件**：
- 租户已初始化，状态正常（status=0）
- 用户已注册，状态正常（status=0），密码已 BCrypt 加密
- 模拟 TenantMapper.selectByTenantCode() 返回有效租户
- 模拟 UserMapper.selectByTenantIdAndLoginName() 返回有效用户
- 模拟 BCryptPasswordEncoder.matches() 返回 true
- 模拟 UserMapper.selectRoleCodesByUserId() 返回角色列表
- 模拟 UserMapper.selectPermissionCodesByUserId() 返回权限列表
- 模拟 JwtUtils.generateAccessToken() 返回 accessToken 字符串
- 模拟 JwtUtils.generateRefreshToken() 返回 refreshToken 字符串
- 模拟 JwtUtils.getTokenSignature() 返回签名指纹
- 模拟 LoginSessionService 方法正常执行

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="admin", password="Abc12345", tenantCode="DEFAULT", clientType="WINDOWS" | 返回 TokenPairDTO 对象，非 null |
| 2 | 验证返回的 accessToken | - | 等于 mock 的 accessToken 值 |
| 3 | 验证返回的 refreshToken | - | 等于 mock 的 refreshToken 值 |
| 4 | 验证返回的 tokenType | - | "Bearer" |
| 5 | 验证 accessTokenExpiresIn | - | 大于当前时间戳（正值） |
| 6 | 验证 refreshTokenExpiresIn | - | 大于当前时间戳（正值） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-002：租户不存在（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回 null
- 请求参数中 tenantCode 为一个不存在的编码

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | tenantCode="NOT_EXIST" | 抛出 BusinessException |
| 2 | 验证异常 HTTP 状态码 | - | 404 |
| 3 | 验证异常消息 | - | "租户不存在" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-003：租户已禁用（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回租户实体，status=1（禁用）
- 用户数据正常

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | tenantCode="DISABLED_TENANT" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | TENANT_DISABLED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "租户已被禁用" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-004：租户已过期（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回租户实体，status=2（过期）
- 用户数据正常

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | tenantCode="EXPIRED_TENANT" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | TENANT_EXPIRED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "租户已过期" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-005：用户不存在（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回 null

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="nonexistent_user" | 抛出 AuthException |
| 2 | 验证异常错误码 | - | LOGIN_FAILED |
| 3 | 验证异常 HTTP 状态码 | - | 401 |
| 4 | 验证异常消息 | - | "用户名或密码错误" |
| 5 | 验证未记录登录失败日志 | - | LoginLogService.recordLoginFailure 未被调用 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-006：密码错误（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回有效用户
- BCryptPasswordEncoder.matches() 返回 false

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | password="WrongPassword123" | 抛出 AuthException |
| 2 | 验证异常错误码 | - | LOGIN_FAILED |
| 3 | 验证异常 HTTP 状态码 | - | 401 |
| 4 | 验证异常消息 | - | "用户名或密码错误" |
| 5 | 验证记录了登录失败日志 | - | LoginLogService.recordLoginFailure 被调用，failReason 不为空 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-007：用户已禁用（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回用户实体，status=1（禁用）

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="disabled_user" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | ACCOUNT_DISABLED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "账号已被禁用" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-008：用户已锁定（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回用户实体，status=2（锁定）

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="locked_user" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | ACCOUNT_LOCKED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "账号已被锁定" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-009：用户已封禁（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回用户实体，status=3（封禁）

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="banned_user" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | ACCOUNT_BANNED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "账号已被封禁" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-010：用户账号已过期（P0）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回用户实体，status=4（过期）
- 或用户实体的 expire_time 早于当前时间

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName="expired_user" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | ACCOUNT_EXPIRED |
| 3 | 验证异常 HTTP 状态码 | - | 403 |
| 4 | 验证异常消息 | - | "账号已过期" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-011：同端互斥（P0）

**前置条件**：
- 用户已存在 Windows 端登录会话（已调用 createSession）
- LoginSessionService.getSession() 返回非 null 的旧会话数据
- 用户再次使用同一 clientType=WINDOWS 登录
- 密码校验通过

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType="WINDOWS" | 返回 TokenPairDTO，登录成功 |
| 2 | 验证同端互斥处理 | - | LoginSessionService.removeSession() 被调用，参数为 userId 和 "WINDOWS" |
| 3 | 验证旧 Token 加入黑名单 | - | LoginSessionService.addToBlacklist() 被调用，参数为旧 Token 签名 |
| 4 | 验证新会话创建 | - | LoginSessionService.createSession() 被调用 |
| 5 | 验证日志记录 | - | LoginLogService.recordLoginSuccess() 被调用 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-012：多端共存（P0）

**前置条件**：
- 用户已存在 Windows 端登录会话
- 用户使用不同的 clientType=H5 再次登录
- 密码校验通过

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType="H5" | 返回 TokenPairDTO，登录成功 |
| 2 | 验证不同端不受影响 | - | LoginSessionService.removeSession() 未因旧 Windows 会话而被调用（检查 clientType 为 "WINDOWS" 的参数） |
| 3 | 验证新 H5 会话创建 | - | LoginSessionService.createSession() 被调用，参数 userId 和 "H5" |
| 4 | 验证旧 Windows 端会话仍存在 | - | LoginSessionService.removeSession() 未以 "WINDOWS" 为 clientType 被调用 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-013：无效 clientType（P1）

**前置条件**：
- ClientTypeEnum.fromCode() 返回 Optional.empty()

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType="INVALID_TYPE" | 抛出 BusinessException |
| 2 | 验证异常错误码 | - | CLIENT_TYPE_INVALID |
| 3 | 验证异常 HTTP 状态码 | - | 400 |
| 4 | 验证异常消息 | - | "无效的客户端类型" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-014：Redis 异常降级（P1）

**前置条件**：
- 所有前置校验通过（租户、用户、密码均有效）
- LoginSessionService.createSession() 抛出 RuntimeException
- 密码校验通过

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | 正常登录数据 | 返回 TokenPairDTO，登录成功（不因 Redis 异常而中断） |
| 2 | 验证 Redis 异常被捕获 | - | 未抛出 Redis 相关异常 |
| 3 | 验证错误日志已记录 | - | 日志输出 Redis 操作失败的 error 级别日志，但不包含连接详情（如 IP/密码） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-015：登录成功日志记录验证（P1）

**前置条件**：
- 登录成功流程（步骤 1-7）全部完成
- 模拟 LoginLogService.recordLoginSuccess()

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | 正常登录数据 | 返回 TokenPairDTO |
| 2 | 验证 recordLoginSuccess 被调用 | - | LoginLogService.recordLoginSuccess() 被精确调用 1 次 |
| 3 | 验证 login_time 参数 | - | login_time 参数为调用时刻（非 null） |
| 4 | 验证 login_result/login_status 参数 | - | login_result 或 表示成功的参数 |
| 5 | 验证 client_type 参数 | - | client_type 等于请求的 "WINDOWS" |
| 6 | 验证 tenantId 参数 | - | 等于租户的 ID |
| 7 | 验证 userId 参数 | - | 等于用户的 ID |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-016：登录成功会话写入验证（P1）

**前置条件**：
- 登录成功流程（步骤 1-7）全部完成
- 模拟 JwtUtils.getTokenSignature() 返回特定签名

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | 正常登录数据 | 返回 TokenPairDTO |
| 2 | 验证 createSession 被调用 | - | LoginSessionService.createSession() 被调用 |
| 3 | 验证 createSession 参数 userId | - | 等于用户 ID |
| 4 | 验证 createSession 参数 clientType | - | 等于 "WINDOWS" |
| 5 | 验证 createSession 参数 sessionData | - | sessionData Map 包含 accessToken、refreshToken、loginTime、ip、deviceInfo |
| 6 | 验证 TTL 设置 | - | createSession 内部设置的 TTL 为 7 天（604800 秒） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-017：密码为空（P1）

**前置条件**：
- LoginRequest 的 password 字段为 null 或空字符串

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | password=null | 抛出 IllegalArgumentException |
| 2 | 调用 loginService.login(request) | password="" | 抛出 IllegalArgumentException |
| 3 | 验证异常信息提示密码不能为空 | - | 异常消息包含 "password" 或 "密码" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-018：loginName 为空（P1）

**前置条件**：
- LoginRequest 的 loginName 字段为 null 或空字符串

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | loginName=null | 抛出 IllegalArgumentException |
| 2 | 调用 loginService.login(request) | loginName="" | 抛出 IllegalArgumentException |
| 3 | 验证异常信息提示登录名不能为空 | - | 异常消息包含 "loginName" 或 "登录名" |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-019：tenantCode 为空（P1）

**前置条件**：
- LoginRequest 的 tenantCode 字段为 null 或空字符串

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | tenantCode=null | 抛出 IllegalArgumentException |
| 2 | 调用 loginService.login(request) | tenantCode="" | 抛出 IllegalArgumentException |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-020：clientType 为空（P1）

**前置条件**：
- LoginRequest 的 clientType 字段为 null 或空字符串

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType=null | 抛出 IllegalArgumentException |
| 2 | 调用 loginService.login(request) | clientType="" | 抛出 IllegalArgumentException |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-021：密码校验失败后用户表未更新（P1）

**前置条件**：
- TenantMapper.selectByTenantCode() 返回有效租户
- UserMapper.selectByTenantIdAndLoginName() 返回有效用户
- BCryptPasswordEncoder.matches() 返回 false

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | password="WrongPassword123" | 抛出 AuthException |
| 2 | 验证用户表未更新 | - | UserMapper.updateById() 未被调用（last_login_time 和 last_login_ip 未更新） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-022：登录成功后更新用户表的 last_login_time 和 last_login_ip（P1）

**前置条件**：
- 登录成功流程全部完成
- 模拟获取请求 IP 地址的方法（如 request.getRemoteAddr()）

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | 正常登录数据 | 返回 TokenPairDTO |
| 2 | 验证用户表更新被调用 | - | UserMapper.updateById() 被调用 |
| 3 | 验证 last_login_time 被更新 | - | 更新后的 UserEntity 中 lastLoginTime 不为 null |
| 4 | 验证 last_login_ip 被更新 | - | 更新后的 UserEntity 中 lastLoginIp 等于预期的 IP 地址 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

## 模块：认证服务（cloudoffice-auth-service） - LoginLogService 日志记录

### TC-TASK-022-023：recordLoginSuccess 正常记录登录成功日志（P1）

**前置条件**：
- LoginLogMapper 模拟正常插入操作

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginLogService.recordLoginSuccess(1L, 100L, "admin", "192.168.1.1", "WINDOWS", "Chrome 120") | tenantId=1L, userId=100L, loginName="admin", loginIp="192.168.1.1", clientType="WINDOWS", deviceInfo="Chrome 120" | 方法正常执行，无异常抛出 |
| 2 | 验证 LoginLogMapper.insert 被调用 | - | insert 方法被精确调用 1 次 |
| 3 | 验证 LoginLogEntity 字段 tenantId | - | 等于 1L |
| 4 | 验证 LoginLogEntity 字段 userId | - | 等于 100L |
| 5 | 验证 LoginLogEntity 字段 loginName | - | 等于 "admin" |
| 6 | 验证 LoginLogEntity 字段 loginIp | - | 等于 "192.168.1.1" |
| 7 | 验证 LoginLogEntity 字段 clientType | - | 等于 "WINDOWS" |
| 8 | 验证 LoginLogEntity 字段 deviceInfo | - | 等于 "Chrome 120" |
| 9 | 验证 LoginLogEntity 字段 loginStatus | - | 等于 1（成功） |
| 10 | 验证 LoginLogEntity 字段 loginTime | - | 不为 null（当前时间） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-024：recordLoginFailure 正常记录登录失败日志（P1）

**前置条件**：
- LoginLogMapper 模拟正常插入操作

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginLogService.recordLoginFailure("admin", "192.168.1.1", "WINDOWS", "密码错误") | loginName="admin", loginIp="192.168.1.1", clientType="WINDOWS", failReason="密码错误" | 方法正常执行，无异常抛出 |
| 2 | 验证 LoginLogMapper.insert 被调用 | - | insert 方法被精确调用 1 次 |
| 3 | 验证 LoginLogEntity 字段 loginName | - | 等于 "admin" |
| 4 | 验证 LoginLogEntity 字段 loginIp | - | 等于 "192.168.1.1" |
| 5 | 验证 LoginLogEntity 字段 clientType | - | 等于 "WINDOWS" |
| 6 | 验证 LoginLogEntity 字段 failReason | - | 等于 "密码错误" |
| 7 | 验证 LoginLogEntity 字段 loginStatus | - | 等于 0（失败） |
| 8 | 验证 LoginLogEntity 字段 loginTime | - | 不为 null（当前时间） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-025：日志记录异常降级（P2）

**前置条件**：
- LoginLogMapper.insert() 抛出 RuntimeException
- 主登录流程已通过所有校验

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginLogService.recordLoginSuccess(...) | 正常参数 | Mapper 异常被 try-catch 捕获，未向上传播异常 |
| 2 | 验证日志输出 | - | 日志记录 error 级别信息，提示日志写入失败 |
| 3 | 调用 loginLogService.recordLoginFailure(...) | 正常参数 | Mapper 异常被 try-catch 捕获，未向上传播异常 |
| 4 | 验证主流程不受影响 | - | 即使日志写入失败，登录主流程继续正常执行 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-026：loginIp 为 unknown 时记录正确（P2）

**前置条件**：
- 请求中无法获取 IP 地址，loginIp 传入 "unknown"

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginLogService.recordLoginSuccess(1L, 100L, "admin", "unknown", "WINDOWS", null) | loginIp="unknown", deviceInfo=null | 方法正常执行 |
| 2 | 验证 loginIp 字段 | - | 等于 "unknown" |
| 3 | 验证 deviceInfo 字段 | - | 为 null 或空字符串（根据实现） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-027：日志方法参数为 null 时的健壮性（P2）

**前置条件**：
- LoginLogMapper.insert() 模拟正常插入

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginLogService.recordLoginSuccess(null, null, null, null, null, null) | 所有参数为 null | 方法不抛出 NullPointerException（降级处理） |
| 2 | 调用 loginLogService.recordLoginFailure(null, null, null, null) | 所有参数为 null | 方法不抛出 NullPointerException（降级处理） |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-028：同端互斥时仅清理同设备分类的旧会话（P1）

**前置条件**：
- 用户已存在 UBUNTU（PC 类）和 ANDROID（MOBILE 类）的登录会话
- 用户使用 WINDOWS（PC 类）登录，密码校验通过

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType="WINDOWS" | 返回 TokenPairDTO |
| 2 | 验证同分类 PC 端旧会话被清理 | - | LoginSessionService.removeSession() 被调用，参数为 UBUNTU 对应的 clientType |
| 3 | 验证不同分类 MOBILE 端旧会话未被清理 | - | LoginSessionService.removeSession() 未被调用，参数为 ANDROID 对应的 clientType |
| 4 | 验证 UBUNTU 的旧 Token 加入黑名单 | - | LoginSessionService.addToBlacklist() 被调用，参数为 UBUNTU 会话的 Token 签名 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

### TC-TASK-022-029：无旧会话时同端互斥逻辑跳过（P1）

**前置条件**：
- 用户首次登录，无任何现有会话
- LoginSessionService.getSession() 返回 null

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 loginService.login(request) | clientType="WINDOWS" | 返回 TokenPairDTO |
| 2 | 验证未执行清理操作 | - | LoginSessionService.removeSession() 未被调用 |
| 3 | 验证未执行黑名单操作 | - | LoginSessionService.addToBlacklist() 未被调用（旧 Token 签名相关） |
| 4 | 验证正常创建新会话 | - | LoginSessionService.createSession() 被调用 |

**关联任务**：TASK-022
**自动化测试脚本**：{待编写}
**测试过程**：{待执行}
**测试结论**：{待执行}

---

**测试用例总数**：29 个

**统计汇总**：

| 优先级 | 数量 | 说明 |
|--------|------|------|
| P0 | 12 | 核心登录流程（正常/异常流程） |
| P1 | 13 | 边界场景（参数为空/日志验证/互斥细节） |
| P2 | 4 | 降级场景/健壮性 |
| **总计** | **29** | 完整覆盖登录业务逻辑 |
