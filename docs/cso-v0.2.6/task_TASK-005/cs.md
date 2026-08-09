# 代码查询报告（TASK-005 保障既有接口契约无回归并输出 v0.2.6 回归报告）

## 1. 查询说明

- **任务**：TASK-005（common/测试验证类）——执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>` 复核 TC-046~051 保持 PASS=26、FAIL=0；核对 git 变更清单无接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码改动；静态确认 API-001~API-033 契约完整保留；汇总输出 `docs/cso-v0.2.6/regression-api-test.md` 完整回归报告。
- **本报告为纯查询成果**，未修改任何代码与文档；供 TASK-005 后续执行（writetest/runtest/code）使用。

## 2. 回归脚本结构与 TC-046~051 用例清单

### 2.1 文件位置与运行方式

- **脚本**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（534 行，纯 Python，无第三方依赖；TC-046-3 可选健康检查才用 requests）
- **运行方式**：`python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`；项目根默认为脚本上级两级（scripts/API-TEST/../..）；环境变量 `GATEWAY_URL` 可覆盖健康检查地址（默认 http://localhost:9000）
- **退出码**：0=全部通过，1=存在失败
- **脚本固定检查对象**：`VERSION_DIR = docs/cso-v0.2.5`、`API_DOC = docs/cso-v0.2.5/cso-api-v0.2.5.md`（该文件存在，glob 已确认）

### 2.2 关键函数

| 函数 | 作用 |
| --- | --- |
| `report(case_id, name, ok, detail="", skipped=False)` | 输出用例结果并汇总 PASS/FAIL/SKIP；skipped=True 不视为失败 |
| `git_changed_files()` | 执行 `git status --short`（cwd=PROJECT_ROOT），返回工作区/暂存区相对 HEAD 的变更文件清单（含未跟踪文件） |
| `is_interface_file(path)` | 接口层判定：路径以 `.java`/`.kt` 结尾且含 `/controller/`、`controller.java`、`gateway`、`route` 之一 |
| `is_build_config_change(path)` | 判定是否为 `BUILD_POM_WHITELIST` 内 5 个 pom（根 pom.xml + 4 模块 pom.xml） |
| `is_client_build_change(path)` | 判定是否为 `CLIENT_BUILD_ALLOWED` 内客户端构建配置（build-release.ps1/.sh、.gitignore） |

### 2.3 用例清单与断言构成（共 27 个断言，目标 PASS=26、FAIL=0、SKIP=1）

| 用例 | 断言 | 断言逻辑摘要 |
| --- | --- | --- |
| TC-046 无接口变更回归确认 | 3 个：046-1 / 046-2 / 046-3 | 046-1：v0.2.5 API 文档同时含"无新增接口"+"无接口变更"+"无接口删除"；046-2：`git_changed_files()` 中 `is_interface_file` 命中数为 0；046-3：（可选）GET `/api/v1/auth/health` 返回 200，异常/未装 requests 时 SKIP |
| TC-047 env 迁移不影响接口契约 | 4 个：047-1 / 047-2 / 047-2b / 047-3 | 047-1 同 046-1；047-2 无接口层文件；047-2b：除 env 配置（env.json/env.example.json）、docs/、scripts/API-TEST/、deploy/、scripts 下 .sh/.ps1 迁移项、pom 白名单、客户端构建配置外，无业务代码改动；047-3：API 文档含 "API-001" 与 "API-033" |
| TC-048 scripts 迁移不影响接口契约 | 5 个：048-1 / 048-2 / 048-2b / 048-3 / 048-4 | 048-1 同 046-1；048-2 无接口层文件；048-2b：迁移资产（deploy/scripts 下 .sh/.ps1、deploy/、docs/、scripts/API-TEST/、pom 白名单、客户端构建配置）之外无遗留；048-3 契约保留；048-4：deploy/scripts 脚本中全部接口地址引用均为既有契约（/api/v1/ 或 localhost/0.0.0.0） |
| TC-049 Maven 构建配置不影响接口契约 | 5 个：049-1 / 049-2 / 049-2b / 049-3 / 049-4 | 049-1 同 046-1；049-2 无接口层文件；049-2b：pom 白名单 + docs/ + scripts/API-TEST/ + deploy/ + 脚本迁移项 + 客户端构建配置之外无业务/接口层/客户端源码改动；049-3 契约保留；049-4 同 048-4 |
| TC-050 Flutter 客户端构建配置不影响接口契约 | 5 个：050-1 / 050-2 / 050-2b / 050-2c / 050-3 | 050-1 同 046-1；050-2 无接口层文件；050-2b：客户端构建配置 + docs/ + scripts/API-TEST/ + deploy/ + pom 白名单 + 脚本迁移项之外无改动；050-2c：变更清单中无 `cloudoffice-flutter-app/lib/` 前缀文件（专项负向校验）；050-3 契约保留 |
| TC-051 整体验收不影响接口契约 | 5 个：051-1 / 051-2 / 051-2b / 051-3 / 051-4 | 051-1 同 046-1；051-2 无接口层文件；051-2b 无 `cloudoffice-flutter-app/lib/` 改动；051-3 契约保留；051-4：deploy/scripts 中健康检查地址引用保持既有契约（/api/v1/auth/health 或含 health /api/v1/） |

**关键认知**：脚本统计的是「断言级」结果，27 个断言中 TC-046-3 为可选（SKIP），故满分为 PASS=26、FAIL=0、SKIP=1。脚本的 `git_changed_files()` 只统计**工作区相对 HEAD 的未提交变更**（含未跟踪文件）。

## 3. git 变更清单核对方法与本版本文件范围

### 3.1 核对方法（供 TASK-005 执行时使用）

- **本版本变更范围**：`git diff --name-status 2b343ac..HEAD`（2b343ac = v0.2.5 合并收尾提交，HEAD = cso-v0.2.6 分支 TASK-004 提交 67fe642）
- **接口层判定**：变更清单中是否出现 `controller/`、`*Controller.java`、网关路由（application.yml 路由段）——**已确认无任何 Controller 文件变更**（7 个 Controller：auth 5 个 + biz/system 各 1 个，均不在变更清单）
- **客户端运行时代码判定**：是否出现 `cloudoffice-flutter-app/lib/` 前缀——**已确认零改动**
- **响应体判定**：ApiResult/PageResult/错误码枚举结构是否变化——`GlobalExceptionHandler` 有修改（见 3.2），但 `ApiResult` 结构（code/message/data/timestamp）与 29 个错误码未变

### 3.2 v0.2.6 实际变更文件范围（2b343ac..HEAD，供报告引用与审计）

| 类别 | 文件 | 说明 |
| --- | --- | --- |
| 构建配置（TASK-001） | 根 `pom.xml`、gateway/auth/biz/system 4 个模块 `pom.xml` | 引入 spring-cloud-starter-bootstrap（ADR-014） |
| 密钥契约（TASK-002/003） | `deploy/scripts/deploy-rsa-keygen.ps1` | RSA 密钥输出统一 DER 单行 Base64（ADR-015） |
| 配置层（TASK-004） | `cloudoffice-auth-service/.../config/SecurityConfig.java`、`cloudoffice-gateway/src/main/resources/application.yml` | SecurityConfig 增补 login/register/refresh permitAll + 注册 GlobalExceptionHandler；网关白名单增补 `/api/v1/auth/logout`（登出幂等）。**均属配置层，非接口签名/路由结构变更** |
| 业务实现（TASK-004，服务内部实现，非接口层） | AuthenticationService、LoginServiceImpl、PermissionServiceImpl、RoleServiceImpl、TokenServiceImpl、UserServiceImpl、PhoneCodeLoginStrategy、UsernamePasswordStrategy、UsernamePwdRegisterStrategy、JwtUtils | 契约行为修复（409/429/403 映射、防账号枚举、验证码用途隔离、同端互斥、tokenVersion 雪花 ID、黑名单签名算法统一等），**未改动任何 Controller 方法签名与请求/响应 DTO 结构** |
| DTO（TASK-004，注意项） | `cloudoffice-common/.../common/dto/LoginUserDTO.java`（+3 行） | 仅新增**内部字段** `tokenSignature`（Access Token 签名指纹，用于同端互斥/登出吊销旧 Token），非对外请求/响应契约变更；TASK-004 UT-124 已回标确认"未触碰 Controller 接口签名、DTO 响应结构与客户端代码" |
| 响应体处理（TASK-004，注意项） | `cloudoffice-common/.../exception/GlobalExceptionHandler.java` | 按 ErrorCode.code 映射 HTTP 状态（409/429/403 契约）+ MissingRequestHeaderException→400；`ApiResult` 结构与 29 个错误码枚举未变，属响应体行为对齐契约，非结构变更 |
| 客户端 lib/ | **无任何文件** | 客户端运行时代码零改动 ✓ |
| 文档/测试资产 | `docs/cso-v0.2.6/`（URS/PRD/SAD/API/DBD/LLD/task/testcase/UI记录/回归报告/任务目录）、`scripts/API-TEST/`（cso-api-test-v0.2.6.py 新增、cso-api-test-v0.0.1.py 修改、4 个 cso-unit-test-*.ps1 新增）、`docs/sad.md`、`docs/prompts/` | 非接口层 |

> **报告撰写注意**：TASK-004 在修复过程中有 `LoginUserDTO.java`（内部字段新增）与 `GlobalExceptionHandler.java`（错误码→HTTP 状态映射）两处**非接口层代码改动**，需在回归报告中按 TASK-004 的 UT-124 结论说明其不构成接口契约变更（未改动 Controller 签名/请求响应 DTO 结构/ApiResult 结构），避免验收误判。

### 3.3 当前工作区状态（cs.md 生成时点）

`git status --short` 仅有：`docs/cso-v0.2.6/cso-task-v0.2.6.json`（M）、`docs/cso-v0.2.6/version_progress.md`（M）、`docs/cso-v0.2.6/task_TASK-005/`（未跟踪）——全部为文档类，无接口层/客户端运行时代码，满足脚本白名单（docs/ 允许）。

## 4. API 契约清单（API-001~API-033）

### 4.1 契约文档

- **主文档**：`docs/cso-api.md`（v0.0.1 基线，第 1 章接口清单 33 行，API-001~API-033）
- **v0.2.6 文档**：`docs/cso-v0.2.6/cso-api-v0.2.6.md`（148 行）——第 0 章声明"**本版本（v0.2.6）无新增接口、无接口变更、无接口删除**"；接口清单逐项沿用主文档（33 个接口，路径/方法/认证列完全一致）；密钥契约特别说明（ADR-015）不改变 Token 结构/验签流程/接口请求响应契约；第 146 行契约一致性说明：修复范围严格限定于构建/依赖配置与密钥格式契约，未触碰任何 Controller/DTO/响应体，契约静态+动态双重确认无回归
- **v0.2.5 文档**：`docs/cso-v0.2.5/cso-api-v0.2.5.md`（存在，脚本断言检查对象）

### 4.2 契约清单（33 个接口，静态核对基准）

| 编号 | 接口 | 方法/路径 | 认证 |
| --- | --- | --- | --- |
| API-001 | 用户登录 | POST /api/v1/auth/login | 白名单 |
| API-002 | 用户注册 | POST /api/v1/auth/register | 白名单 |
| API-003 | 刷新 Token | POST /api/v1/auth/refresh | 白名单 |
| API-004 | 用户登出 | POST /api/v1/auth/logout | 需认证（v0.2.6 网关白名单放行，服务内幂等） |
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
| API-029 | 创建权限 | POST /api/v1/auth/permissions | 需认证（201） |
| API-030 | 更新权限 | PUT /api/v1/auth/permissions/{id} | 需认证 |
| API-031 | 删除权限 | DELETE /api/v1/auth/permissions/{id} | 需认证 |
| API-032 | 企业服务健康检查 | GET /api/v1/biz/health | 需认证（备注） |
| API-033 | 系统服务健康检查 | GET /api/v1/system/health | 需认证（备注） |

- **错误码**：10 个基础码（200/400/401/403/404/405/409/429/500/503）+ AUTH-0001~0023 共 23 个认证授权码，统一响应体 `ApiResult<T>`（code/message/data/timestamp），分页 `PageResult<T>`——v0.2.6 未变。
- **契约对照结论**：`docs/cso-api.md` 与 `docs/cso-v0.2.6/cso-api-v0.2.6.md` 两文档第 1 章接口清单**逐项一致（33=33）**，v0.2.6 文档显式声明无新增/变更/删除接口，静态确认契约完整保留。

## 5. 回归报告结构与参考素材

### 5.1 v0.2.5 报告结构（docs/cso-v0.2.5/regression-api-test.md，71 行）

1. 标题 + 项目/版本/测试时间/负责人/测试类型
2. 一、脚本清单与执行结果（表格：脚本名称/执行命令/用例数/通过/失败/跳过/结果）
3. 二、接口回归明细（TC-046~TC-051 表格：用例/断言/结果，每用例多断言分列）
4. 三、基线动态回归（v0.0.1）环境阻塞说明（现象/根因/影响与建议）
5. 四、缺陷闭环补记
6. 五、结论（含 PASS/FAIL/SKIP 统计）
7. 六、签名确认（TE/PM）

### 5.2 v0.2.6 现有报告（docs/cso-v0.2.6/regression-api-test.md，128 行，TASK-004 已生成）

- 标题：接口回归测试报告（v0.2.6 / TASK-004：v0.0.1 基线接口回归闭环）
- 一、执行概览（脚本 cso-api-test-v0.0.1.py，**首次执行与幂等复跑均 PASS=45 FAIL=0 SKIP=0 退出码 0**；历史 v0.2.5 状态=环境阻塞；本次结论=T-02 闭环）
- 二、用例执行明细 TC-001~TC-045（45 行表格全部 PASS）
- 三、根因闭环说明（T-02 三项：bootstrap 依赖缺失 / RSA 密钥格式契约不匹配 / SecurityConfig 白名单缺陷，均确认闭环）
- 四、数据库结构与数据对齐（补列/改约束/密码 hash 修正）
- 五、遗留事项与建议
- 六、结论
- **TASK-005 需在此基础上「汇总」**：追加 TC-046~051 复核结果（v0.2.5 脚本）+ git 变更清单核对结论 + API-001~033 静态确认，形成 TC-001~051 全量完整回归报告，并声明"API 测试全部跑通"

### 5.3 任务目标（来自 context.md / cso-task-v0.2.6.json）

- 执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`，TC-046~051 保持 **PASS=26、FAIL=0**（TC-046-3 健康检查可选 SKIP 不视为失败）
- git 变更清单核对：无 Controller/DTO/响应体与客户端 lib/ 运行时代码改动（含 3.2 注意项说明）
- 静态确认 API-001~API-033 契约完整保留、无新增/变更/删除接口（以 v0.2.6 API 文档声明为准）
- 输出 `docs/cso-v0.2.6/regression-api-test.md` 完整回归报告（脚本清单、执行明细、统计、T-02 两项缺陷闭环说明、签名确认），声明"API 测试全部跑通"

## 6. 查询结论（供 TASK-005 直接引用）

1. **脚本可执行性**：`cso-api-test-v0.2.5.py` 存在且逻辑自洽，静态断言检查 v0.2.5 API 文档（存在）与 git 变更清单（当前工作区仅文档变更）；TC-046-3 在服务未启动/requests 缺失时 SKIP。
2. **接口层零改动**：v0.2.6 全部变更（2b343ac..HEAD）中**无任何 Controller 文件、无网关路由结构、无响应体结构变更**；LoginUserDTO 仅新增内部字段 tokenSignature、GlobalExceptionHandler 为错误码→HTTP 状态映射（行为对齐契约），均不构成对外契约变更（TASK-004 UT-124 已回标）。
3. **客户端零改动**：变更清单中无 `cloudoffice-flutter-app/lib/` 文件。
4. **契约静态确认**：docs/cso-api.md（主文档）与 cso-api-v0.2.6.md 接口清单逐项一致（API-001~033），v0.2.6 文档声明无新增/变更/删除接口。
5. **报告产出**：`docs/cso-v0.2.6/regression-api-test.md` 已有 TASK-004 的 TC-001~045 部分（PASS=45、FAIL=0），TASK-005 在其上汇总 TC-046~051（目标 PASS=26、FAIL=0、SKIP=1 可选）形成 TC-001~051 完整回归报告。
