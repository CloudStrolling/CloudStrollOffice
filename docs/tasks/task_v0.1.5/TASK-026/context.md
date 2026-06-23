# TASK-026 上下文

## 任务信息
- **任务编号：** TASK-026
- **任务名称：** 账号封禁/解封业务逻辑
- **版本：** v0.1.5
- **关联UserStory：** US-018

## PRD US-018 验收标准
- **AC1：** 封禁用户（status=3）→ 数据库更新 + Redis缓存 `auth:account:status:{userId}` 更新为 3
- **AC2：** 封禁后 → 所有端登录态会话删除 + 关联 Token 入黑名单
- **AC3：** 被封禁用户任何 API 请求 → 网关返回 403 ACCOUNT_BANNED
- **AC4：** 解封用户（status=0）→ 数据库更新 + Redis缓存删除
- **AC5：** 解封后重新登录成功

## 边界情况
- 目标用户不存在 → 返回 404 USER_NOT_FOUND
- 重复封禁（幂等处理）→ 返回操作成功
- 非管理员操作 → 返回 403 PERMISSION_DENIED
- 封禁自己 → 允许操作

## SDS 关键信息
- 用户状态：0-正常，1-禁用，2-锁定，3-封禁
- 账号状态缓存 Key：`auth:account:status:{userId}`
- 封禁流程：更新DB → 更新Redis缓存 → 清除所有端登录态
- 解封流程：更新DB → 删除Redis缓存

## 依赖的上游任务
- **TASK-015** ✅ UserMapper（`selectById` / `updateById`）
- **TASK-019** ✅ LoginSessionService（`removeAllSessions` / `setAccountStatus` / `removeAccountStatus`）

## 实现方法签名
```java
void banUser(Long userId);     // 封禁（status=3）
void unbanUser(Long userId);   // 解封（status=0）
void lockUser(Long userId);    // 锁定（status=2）
void unlockUser(Long userId);  // 解锁（status=0）
```

## 实现细节
- `banUser/lockUser`：校验用户存在 → 幂等判断（已封禁/锁定则跳过）→ DB更新状态 → Redis缓存更新 → 清除所有端会话
- `unbanUser/unlockUser`：校验用户存在 → 幂等判断（已是正常则跳过）→ DB更新状态为 0 → Redis缓存删除
- 所有方法：`Objects.requireNonNull` 空值校验 + `@Transactional` 事务注解
- 异常：用户不存在抛出 `BusinessException(ErrorCode.USER_NOT_FOUND)`

## 状态
- ✅ `UserService.java` — 接口定义完成，含 6 个方法
- ✅ `UserServiceImpl.java` — 实现完成，含 `LoginSessionService` 依赖
- ✅ `UserServiceImplTest.java` — 21 个测试全部通过（5 注册 + 16 状态变更）
- ✅ `mvn compile` 通过
- ✅ `mvn test` 通过（21/21）
