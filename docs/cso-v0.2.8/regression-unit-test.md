# 回归测试报告（单元测试）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8（cloudoffice-common 服务化改造与通用配置管理）
**测试日期**：2026-08-13（第一次回归 11:38 ~ 11:47；REVIEW-FIX 后第二次回归 12:18 ~ 12:20）
**测试负责人**：TE
**测试类型**：版本回归测试 - 单元测试（Maven 全量 Java 单元测试 + v0.2.8 新增 .ps1 单元测试脚本）

---

## 一、测试环境

| 项目 | 值 |
| --- | --- |
| 操作系统 | Windows 10（win32） |
| JDK | Temurin-21.0.9+10（Eclipse Adoptium） |
| Maven | Apache Maven 3.9.16 |
| PowerShell | 5.1（执行 .ps1 单元测试脚本） |
| 执行命令 | `mvn test -fae`（全量 Maven 单元测试，fail-at-end 确保全部模块执行）；`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice` |
| 测试时间 | 第一次：2026-08-13 11:38 ~ 11:40（Maven）；11:47（.ps1 脚本）；第二次（REVIEW-FIX 后）：2026-08-13 12:18:31 ~ 12:19:32（Maven）；12:20（.ps1 脚本） |
| 项目根目录 | D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice |

## 二、执行范围

1. Maven 多模块全量单元测试（`mvn test -fae`）：覆盖 cloudoffice-common、cloudoffice-gateway、cloudoffice-auth-service、cloudoffice-biz-service、cloudoffice-system-service 全部 5 个后端模块的 Java 单元测试。
2. v0.2.8 新增 .ps1 单元测试脚本 `cso-unit-test-db-common-config-v0.2.8.ps1`（对应 TASK-001 通用配置库/表/索引/种子数据，覆盖 TC-TASK001-001~006）。
3. REVIEW-FIX 审核修复（提交 116e1a0，修复 A-01 Nacos group / A-02 API-035 缓存优先 / A-03 status 过滤 / S-01 Redis 序列化安全）后，对 cloudoffice-common 与 cloudoffice-gateway 模块执行全量复测，确认无回归。

## 三、统计结果（Maven 全量单元测试）

### 3.1 第一次回归（REVIEW-FIX 前）

| 模块 | Tests | Failures | Errors | Skipped | 结论 |
| --- | --- | --- | --- | --- | --- |
| cloudoffice-common | 146 | 0 | 0 | 0 | 通过 |
| cloudoffice-gateway | 33 | 0 | 0 | 0 | 通过 |
| cloudoffice-auth-service | 253 | 21 | 6 | 0 | 失败（历史遗留，非 v0.2.8 引入，详见第四节） |
| cloudoffice-biz-service | 3 | 0 | 0 | 0 | 通过 |
| cloudoffice-system-service | 3 | 0 | 0 | 0 | 通过 |
| **合计** | **438** | **21** | **6** | **0** | - |

### 3.2 第二次回归（REVIEW-FIX 后，2026-08-13 12:19）

| 模块 | Tests | Failures | Errors | Skipped | 结论 |
| --- | --- | --- | --- | --- | --- |
| cloudoffice-common | **151** | 0 | 0 | 0 | **通过（较前次 +5：JsonUtils.parseArray 3 项 + ConfigService 缓存优先 2 项）** |
| cloudoffice-gateway | 33 | 0 | 0 | 0 | 通过 |
| cloudoffice-auth-service | 253 | 21 | 6 | 0 | 失败（与第一次完全一致的 27 项历史遗留，REVIEW-FIX 未触碰 auth 测试/实现，详见第四节） |
| cloudoffice-biz-service | 3 | 0 | 0 | 0 | 通过 |
| cloudoffice-system-service | 3 | 0 | 0 | 0 | 通过 |
| **合计** | **443** | **21** | **6** | **0** | - |

- 全量 443 个用例：**通过 416 / 失败 21 / 错误 6 / 跳过 0**，通过率（不含错误与失败）= 416/443 = 93.90%。
- v0.2.8 本版本涉及的 cloudoffice-common（通用配置管理 ConfigController/ConfigService/ConfigCacheManager/ConfigMapper/ConfigProperties/HealthController 等）与 cloudoffice-gateway（AuthFilter common 白名单）模块单元测试 **151 + 33 = 184 个全部通过**，含 TASK-001~TASK-005 全部新增用例与 REVIEW-FIX 新增用例（TC-TASK004-002-2/002-3、TC-REVIEWFIX-001~004）。
- REVIEW-FIX 修复点均有对应测试验证：A-01（CommonApplicationConfigTest 断言 bootstrap.yml 不含 group，通过 5/5）、A-02（ConfigServiceTest 新增缓存优先 2 项，通过 10/10）、S-01（JsonUtilsTest parseArray 3 项，通过 10/10；ConfigCacheManagerTest 值 JSON 字符串序列化，通过 4/4）。

### v0.2.8 新增 .ps1 单元测试脚本结果

| 脚本名称 | 关联任务 | PASS | FAIL | SKIP | 退出码 | 结论 |
| --- | --- | --- | --- | --- | --- | --- |
| cso-unit-test-db-common-config-v0.2.8.ps1 | TASK-001 | 13 | 0 | 0 | 0 | 通过（第二次复测 2026-08-13 12:20，与第一次一致） |

- 覆盖 TC-TASK001-001（cloudstroll_office_common 库存在）、TC-TASK001-002（t_common_config 表 12 列结构）、TC-TASK001-003（uk_service_group_key / idx_service_name / idx_config_group 索引）、TC-TASK001-004（17 条种子数据 / 5 个服务覆盖 / auth-service 验证码长度 6 / common cache-ttl-seconds 300）、TC-TASK001-005（SQL 脚本幂等重跑，行数不变）、TC-TASK001-006（auth 库 9 张基线表无增删）。

## 四、失败用例明细与归因分析（cloudoffice-auth-service）

### 4.1 归因结论（重要）

**全部 27 项失败/错误均为历史遗留问题，非 v0.2.8 引入、亦非 REVIEW-FIX 引入的回归缺陷。** 依据：
1. git 证据：`git log 92fbb23..HEAD -- cloudoffice-auth-service/src/main` 仅涉及 `src/main/resources/bootstrap.yml`（TASK-001 需求分析整理提交），**无任何 Java 实现代码变更**；REVIEW-FIX 提交（116e1a0）未触碰 auth-service 的 src/main 与 src/test 任何 Java 文件（仅 bootstrap.yml 移除 group 配置 2 行）。
2. 失败相关实现类（TokenServiceImpl、JwtUtils、PhoneCodeLoginStrategy、UsernamePasswordStrategy、UserServiceImpl、RoleServiceImpl、GlobalExceptionHandler 等）最近一次修改提交均为 `a57da2a（cso-v0.2.6-回归测试和版本文档整理完成）`，即失败根因是 v0.2.6 及更早版本实现变更后测试断言未同步，属于存量测试与实现契约不一致。
3. 第二次回归（12:19）auth-service 失败清单与第一次回归（11:38）**逐项完全一致**（21 Failures + 6 Errors），进一步证明 REVIEW-FIX 未对 auth-service 造成任何回归影响。

### 4.2 失败明细（21 Failures + 6 Errors，两次回归完全一致）

| 序号 | 测试类 / 方法 | 现象 | 归因 |
| --- | --- | --- | --- |
| 1 | UserControllerTest.updateUser_shouldReturn404_whenUserNotFound | Status expected 400 but was 404 | 实现（GlobalExceptionHandler）对 USER_NOT_FOUND 返回 HTTP 404，测试断言仍为 400（v0.2.6 实现变更未同步测试） |
| 2 | UserControllerTest.assignRoles_shouldReturn404_whenUserNotFound | Status expected 400 but was 404 | 同上 |
| 3 | UserControllerTest.deleteUser_shouldReturn404_whenUserNotFound | Status expected 400 but was 404 | 同上 |
| 4 | UserControllerTest.updateStatus_shouldReturn404_whenUserNotFound | Status expected 400 but was 404 | 同上 |
| 5 | RoleControllerTest.assignPermissions_shouldReturn404_whenRoleNotFound | Status expected 400 but was 404 | 同上（ROLE_NOT_FOUND 返回 404） |
| 6 | UserServiceImplTest.register_shouldThrowBusinessException_whenLoginNameDuplicate | expected 400 but was 409 | 实现重复登录名抛 409（CONFLICT），测试断言为 400 |
| 7 | RoleServiceImplTest.create_shouldThrow_whenRoleCodeDuplicate | expected 400 but was 409 | 实现角色码重复抛 409，测试断言为 400 |
| 8 | RoleServiceImplTest.update_shouldThrow_whenRoleCodeConflicts | expected 400 but was 409 | 同上 |
| 9 | RoleServiceImplTest.delete_shouldThrow_whenRoleReferenced | expected 400 but was 409 | 实现角色被引用抛 409，测试断言为 400 |
| 10 | UsernamePasswordStrategyTest.authenticate_shouldThrow_whenUserNotFound | expected 404 but was 401 | 实现用户不存在统一返回 401（避免账号枚举），测试断言为 404 |
| 11 | TokenServiceImplTest$AccountStatus.refresh_userNotFound_shouldThrowAuthException | expected USER_NOT_FOUND(404) but was 401 | 实现 refresh 时用户不存在抛 AuthException(401)，测试断言为 404 |
| 12 | TokenServiceImplTest$AccountStatus.refresh_deletedUser_shouldThrowAuthException | expected USER_NOT_FOUND(404) but was 401 | 同上 |
| 13 | TokenServiceImplTest$AccountStatus.refresh_bannedAccount_shouldThrowBusinessException | expected BusinessException but was AuthException | 实现被封禁账号 refresh 抛 AuthException，测试断言为 BusinessException |
| 14 | TokenServiceImplTest$AccountStatus.refresh_disabledAccount_shouldThrowBusinessException | expected BusinessException but was AuthException | 同上（禁用账号） |
| 15 | TokenServiceImplTest$AccountStatus.refresh_lockedAccount_shouldThrowBusinessException | expected BusinessException but was AuthException | 同上（锁定账号） |
| 16 | TokenServiceImplTest$TenantStatus.refresh_disabledTenant_shouldThrowBusinessException | expected BusinessException but was AuthException | 实现禁用租户 refresh 抛 AuthException，测试断言为 BusinessException |
| 17 | TokenServiceImplTest$TenantStatus.refresh_deletedTenant_shouldThrowBusinessException | expected BusinessException but was AuthException | 同上（删除租户） |
| 18 | TokenServiceImplTest$TenantStatus.refresh_expiredTenant_shouldThrowBusinessException | expected BusinessException but was AuthException | 同上（过期租户） |
| 19 | TokenServiceImplTest$TenantStatus.refresh_tenantNotFound_shouldThrowBusinessException | expected BusinessException but was AuthException | 同上（租户不存在） |
| 20 | TokenServiceImplTest$HappyPath.refresh_validRefreshToken_shouldReturnNewTokenPair | AuthException「账号在其他设备登录，已被禁止」 | 实现 refresh 时登录会话唯一性校验抛 AuthException，测试 mock 的会话状态与实现校验逻辑不一致 |
| 21 | TokenServiceImplTest$HappyPath.refresh_shouldAddOldTokenToBlacklistAndUpdateSession | 同上 | 同上 |
| 22 | TokenServiceImplTest$HappyPath.refresh_shouldBuildCorrectLoginUserDTO | 同上 | 同上 |
| 23 | TokenServiceImplTest$EdgeCases.refresh_nullRoles_shouldStillSucceed | 同上 | 同上 |
| 24 | TokenServiceImplTest$EdgeCases.refresh_sameTokenTwice_secondCallShouldBeRejected | 同上 | 同上 |
| 25 | PhoneCodeLoginStrategyTest.authenticate_shouldThrow_whenCodeInvalid | expected BusinessException but was PotentialStubbingProblem | 测试对 verifyCode 的 stub 参数为 2 个（null, null），实现实际调用 3 个参数（phone, code, purpose），Mockito 严格桩参数不匹配（v0.2.6 起 verifyCode 增加 purpose 参数，测试未同步） |
| 26 | PhoneCodeLoginStrategyTest.authenticate_shouldReturnAuthResult_whenCodeValid | PotentialStubbingProblem | 同上（严格桩参数不匹配） |
| 27 | JwtUtilsTest.getTokenSignature_shouldReturn64CharHexString | SHA-256 应为 64 个十六进制字符，实际 43 | 实现 getTokenSignature 返回 Base64 编码（43 字符），测试断言为 64 位 hex（v0.2.6 实现变更未同步测试） |

> 归因汇总：上述失败全部指向 **v0.2.6 版本实现变更（错误码语义 400→404/409/401、异常类型 BusinessException→AuthException、verifyCode 三参数签名、JwtUtils 签名编码）未同步更新存量测试断言**。v0.2.8 与 REVIEW-FIX 均未触碰 auth-service 的 Java 实现与测试代码，不构成 v0.2.8 回归缺陷。建议在后续版本由编码环节（SSE）统一更新 auth-service 存量测试断言或由 TE 补充契约对齐用例，本次回归如实记录不阻塞版本结论。

## 五、回归结论

1. **REVIEW-FIX 后第二次回归**：v0.2.8 涉及模块（cloudoffice-common + cloudoffice-gateway）单元测试 **184/184 全部通过**（common 151 + gateway 33），较第一次回归 common 146 + gateway 33 无任何用例由通过变失败；REVIEW-FIX 新增 5 个单元测试方法全部通过，**审核修复未引入回归缺陷**。
2. REVIEW-FIX 四个修复项均有对应测试佐证：A-01（bootstrap.yml 不含 group）、A-02（API-035 缓存优先：serviceName 非空缓存命中不回源 / 为空直连不缓存）、A-03（status=0 启用项过滤）、S-01（Redis 值 String 序列化 + JsonUtils.parseArray 固定类型反序列化）。
3. biz/system 模块 6 个用例全部通过；auth-service 253 个用例中 226 个通过，27 项失败/错误经 git 证据与两次回归一致性判定为 **v0.2.6 及更早实现变更未同步测试断言的存量问题，非 v0.2.8 引入、非 REVIEW-FIX 引入**。
4. v0.2.8 新增 .ps1 单元测试脚本 PASS=13/FAIL=0/SKIP=0（第二次复测一致），数据库（cloudstroll_office_common 库、t_common_config 表、索引、种子数据、幂等）契约全部验证通过。
5. **单元测试回归判定：v0.2.8 相关范围通过（REVIEW-FIX 后无回归）；auth-service 存量失败 27 项如实记录并移交后续版本处理，不阻塞本版本。**

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
