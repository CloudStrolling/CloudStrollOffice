/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.AccountSettlementRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

/**
 * 用户业务逻辑实现。
 *
 * <p>实现用户注册、查询等核心业务方法，包含租户校验、密码加密、默认角色分配等逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final UserRoleMapper userRoleMapper;
    private final RoleMapper roleMapper;
    private final PasswordEncoder passwordEncoder;
    private final LoginSessionService loginSessionService;

    /**
     * 默认角色编码（普通用户）
     */
    private static final String DEFAULT_ROLE_CODE = "user";

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserEntity register(RegisterRequest request) {
        log.info("用户注册开始 | loginName={} | tenantCode={}", request.getLoginName(), request.getTenantCode());

        // 1. 通过 tenantCode 查询租户
        LambdaQueryWrapper<TenantEntity> tenantQuery = Wrappers.lambdaQuery(TenantEntity.class)
                .eq(TenantEntity::getTenantCode, request.getTenantCode());
        TenantEntity tenant = tenantMapper.selectOne(tenantQuery);
        if (tenant == null) {
            log.warn("租户不存在 | tenantCode={}", request.getTenantCode());
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }
        Long tenantId = tenant.getId();
        // 校验租户状态（0-正常，1-禁用，2-过期）
        if (tenant.getStatus() != null && tenant.getStatus() != 0) {
            if (tenant.getStatus() == 1) {
                log.warn("租户已被禁用 | tenantId={}", tenantId);
                throw new BusinessException(ErrorCode.TENANT_DISABLED);
            }
            log.warn("租户已过期 | tenantId={}", tenantId);
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        // 校验租户有效期
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("租户已过期 | tenantId={} | expireTime={}", tenantId, tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }

        // 2. 校验 loginName 唯一性（同一租户内）
        UserEntity existingUser = userMapper.selectByTenantIdAndLoginName(
                tenantId, request.getLoginName());
        if (existingUser != null) {
            log.warn("登录名已存在 | loginName={} | tenantId={}", request.getLoginName(), tenantId);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "登录名已存在");
        }

        // 3. BCrypt 密码加密
        String encryptedPassword = passwordEncoder.encode(request.getPassword());
        log.debug("密码加密完成 | loginName={}", request.getLoginName());

        // 4. 创建用户记录
        UserEntity user = new UserEntity();
        user.setTenantId(tenantId);
        user.setLoginName(request.getLoginName());
        user.setPassword(encryptedPassword);
        user.setUserName(request.getUserName());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());
        user.setStatus(0); // 0-正常

        userMapper.insert(user);
        log.info("用户记录创建成功 | userId={} | loginName={}", user.getId(), user.getLoginName());

        // 5. 分配默认角色
        assignDefaultRole(user);

        // 6. 返回用户信息（不含密码）
        user.setPassword(null);
        log.info("用户注册完成 | userId={} | loginName={}", user.getId(), user.getLoginName());
        return user;
    }

    @Override
    public UserEntity findById(Long id) {
        UserEntity user = userMapper.selectById(id);
        if (user != null) {
            user.setPassword(null);
            // 加载角色编码列表
            user.setRoleCodes(userMapper.selectRoleCodesByUserId(id));
        }
        return user;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void banUser(Long userId) {
        Objects.requireNonNull(userId, "userId must not be null");

        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("封禁失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        // 幂等处理：已封禁则直接返回
        if (Integer.valueOf(3).equals(user.getStatus())) {
            log.info("封禁幂等跳过：用户已是封禁状态 | userId={}", userId);
            return;
        }

        user.setStatus(3);
        userMapper.updateById(user);
        log.info("用户已封禁 | userId={}", userId);

        loginSessionService.setAccountStatus(userId, 3);
        loginSessionService.removeAllSessions(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unbanUser(Long userId) {
        Objects.requireNonNull(userId, "userId must not be null");

        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("解封失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        // 幂等处理：已是正常状态则直接返回
        if (Integer.valueOf(0).equals(user.getStatus())) {
            log.info("解封幂等跳过：用户已是正常状态 | userId={}", userId);
            return;
        }

        user.setStatus(0);
        userMapper.updateById(user);
        log.info("用户已解封 | userId={}", userId);

        loginSessionService.removeAccountStatus(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void lockUser(Long userId) {
        Objects.requireNonNull(userId, "userId must not be null");

        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("锁定失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        // 幂等处理：已锁定则直接返回
        if (Integer.valueOf(2).equals(user.getStatus())) {
            log.info("锁定幂等跳过：用户已是锁定状态 | userId={}", userId);
            return;
        }

        user.setStatus(2);
        userMapper.updateById(user);
        log.info("用户已锁定 | userId={}", userId);

        loginSessionService.setAccountStatus(userId, 2);
        loginSessionService.removeAllSessions(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unlockUser(Long userId) {
        Objects.requireNonNull(userId, "userId must not be null");

        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("解锁失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }
        // 幂等处理：已是正常状态则直接返回
        if (Integer.valueOf(0).equals(user.getStatus())) {
            log.info("解锁幂等跳过：用户已是正常状态 | userId={}", userId);
            return;
        }

        user.setStatus(0);
        userMapper.updateById(user);
        log.info("用户已解锁 | userId={}", userId);

        loginSessionService.removeAccountStatus(userId);
    }

    @Override
    public PageResult<UserEntity> list(Long tenantId, String keyword, int page, int pageSize) {
        log.debug("分页查询用户列表 | tenantId={} | keyword={} | page={} | pageSize={}",
                tenantId, keyword, page, pageSize);

        // 1. 构建分页参数
        Page<UserEntity> pageParam = new Page<>(page, pageSize);

        // 2. 构建查询条件
        LambdaQueryWrapper<UserEntity> wrapper = Wrappers.lambdaQuery(UserEntity.class)
                .eq(tenantId != null, UserEntity::getTenantId, tenantId);

        // 3. 关键词模糊搜索（login_name 或 user_name）
        if (StringUtils.hasText(keyword)) {
            wrapper.and(w -> w.like(UserEntity::getLoginName, keyword)
                    .or()
                    .like(UserEntity::getUserName, keyword));
        }

        // 4. 按创建时间降序排列
        wrapper.orderByDesc(UserEntity::getCreateTime);

        // 5. 执行分页查询
        Page<UserEntity> result = userMapper.selectPage(pageParam, wrapper);

        // 6. 密码脱敏
        result.getRecords().forEach(u -> u.setPassword(null));

        log.info("分页查询完成 | total={} | page={} | pageSize={}", result.getTotal(), page, pageSize);
        return PageResult.of(result.getRecords(), result.getTotal(), page, pageSize);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserEntity update(UserEntity user) {
        Long userId = user.getId();
        Objects.requireNonNull(userId, "userId must not be null");

        // 1. 校验用户存在
        UserEntity existing = userMapper.selectById(userId);
        if (existing == null) {
            log.warn("更新用户失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 密码变更需通过独立接口，此处屏蔽
        user.setPassword(null);

        // 3. 执行更新
        userMapper.updateById(user);
        log.info("用户信息已更新 | userId={}", userId);

        // 4. 返回更新后的用户信息
        UserEntity updated = userMapper.selectById(userId);
        updated.setPassword(null);
        return updated;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void assignRoles(Long userId, List<Long> roleIds) {
        Objects.requireNonNull(userId, "userId must not be null");

        // 1. 校验用户存在
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("角色分配失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 先删除现有角色关联（物理删除关联记录）
        LambdaQueryWrapper<UserRoleEntity> deleteWrapper = Wrappers.lambdaQuery(UserRoleEntity.class)
                .eq(UserRoleEntity::getUserId, userId);
        userRoleMapper.delete(deleteWrapper);
        log.debug("已清除用户现有角色 | userId={}", userId);

        // 3. 插入新角色关联
        if (roleIds != null && !roleIds.isEmpty()) {
            for (Long roleId : roleIds) {
                UserRoleEntity userRole = new UserRoleEntity();
                userRole.setUserId(userId);
                userRole.setRoleId(roleId);
                userRoleMapper.insert(userRole);
            }
            log.info("角色分配完成 | userId={} | roleCount={}", userId, roleIds.size());
        } else {
            log.info("角色分配完成（清空所有角色） | userId={}", userId);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long userId) {
        Objects.requireNonNull(userId, "userId must not be null");

        // 1. 校验用户存在
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("删除用户失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 逻辑删除（@TableLogic 自动填充 deleted = 1）
        userMapper.deleteById(userId);
        log.info("用户已逻辑删除 | userId={}", userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateStatus(Long userId, Integer status, String lockReason) {
        Objects.requireNonNull(userId, "userId must not be null");
        Objects.requireNonNull(status, "status must not be null");

        // 1. 校验用户存在
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("状态变更失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 幂等处理：状态相同则跳过
        if (status.equals(user.getStatus())) {
            log.info("状态变更幂等跳过：状态相同 | userId={} | status={}", userId, status);
            return;
        }

        // 3. 根据目标状态委派到对应方法
        switch (status) {
            case 0:
                // 恢复正常 - 根据当前状态选择解封或解锁
                if (Integer.valueOf(3).equals(user.getStatus())) {
                    unbanUser(userId);
                } else if (Integer.valueOf(2).equals(user.getStatus())) {
                    unlockUser(userId);
                } else {
                    // 从停用直接恢复
                    user.setStatus(0);
                    userMapper.updateById(user);
                    log.info("用户状态已恢复正常 | userId={}", userId);
                }
                break;
            case 1:
                // 停用 - 仅更新数据库
                user.setStatus(1);
                userMapper.updateById(user);
                log.info("用户已停用 | userId={}", userId);
                break;
            case 2:
                // 锁定 - 委托 lockUser 方法（含 Redis 更新）
                lockUser(userId);
                break;
            case 3:
                // 封禁 - 委托 banUser 方法（含 Redis 更新 + 清除会话）
                banUser(userId);
                break;
            default:
                log.warn("无效的用户状态 | status={}", status);
                throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "无效的用户状态");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void accountSettlement(Long userId, AccountSettlementRequest request) {
        Objects.requireNonNull(userId, "userId must not be null");
        Objects.requireNonNull(request, "request must not be null");

        // 1. 查询用户
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("账号完善失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 校验账号信息未完善
        if (user.getAccountSettled() != null && user.getAccountSettled() == 1) {
            log.warn("账号完善失败：账号信息已完善 | userId={}", userId);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "账号信息已完善，无需重复操作");
        }

        // 3. 更新登录名（如果提供）
        if (StringUtils.hasText(request.getLoginName())) {
            // 校验同一租户内登录名唯一性
            UserEntity existingUser = userMapper.selectByTenantIdAndLoginName(
                    user.getTenantId(), request.getLoginName());
            if (existingUser != null && !existingUser.getId().equals(userId)) {
                log.warn("账号完善失败：登录名已存在 | loginName={} | tenantId={}",
                        request.getLoginName(), user.getTenantId());
                throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "登录名已存在");
            }
            user.setLoginName(request.getLoginName());
        }

        // 4. 更新密码（如果提供）
        if (StringUtils.hasText(request.getPassword())) {
            String encryptedPassword = passwordEncoder.encode(request.getPassword());
            user.setPassword(encryptedPassword);
            user.setLastPasswordChangeTime(LocalDateTime.now());
        }

        // 5. 更新手机号（如果提供）
        if (StringUtils.hasText(request.getPhone())) {
            // 校验手机号是否已被其他账号绑定
            LambdaQueryWrapper<UserEntity> phoneQuery = Wrappers.lambdaQuery();
            phoneQuery.eq(UserEntity::getPhone, request.getPhone());
            UserEntity userWithPhone = userMapper.selectOne(phoneQuery);
            if (userWithPhone != null && !userWithPhone.getId().equals(userId)) {
                log.warn("账号完善失败：手机号已被其他账号绑定 | phone={}", request.getPhone());
                throw new BusinessException(ErrorCode.PHONE_ALREADY_BOUND);
            }
            user.setPhone(request.getPhone());
        }

        // 6. 设置账号信息已完善
        user.setAccountSettled(1);

        // 7. 执行更新
        userMapper.updateById(user);
        log.info("账号信息完善成功 | userId={} | loginName={}", userId, user.getLoginName());
    }

    /**
     * 为用户分配默认角色。
     *
     * <p>根据默认角色编码查询租户内对应的角色，若存在则创建用户-角色关联记录。</p>
     *
     * @param user 已创建的用户实体
     */
    private void assignDefaultRole(UserEntity user) {
        LambdaQueryWrapper<RoleEntity> queryWrapper = Wrappers.lambdaQuery(RoleEntity.class)
                .eq(RoleEntity::getTenantId, user.getTenantId())
                .eq(RoleEntity::getRoleCode, DEFAULT_ROLE_CODE)
                .eq(RoleEntity::getStatus, 0)
                .last("LIMIT 1");

        RoleEntity defaultRole = roleMapper.selectOne(queryWrapper);
        if (defaultRole != null) {
            UserRoleEntity userRole = new UserRoleEntity();
            userRole.setUserId(user.getId());
            userRole.setRoleId(defaultRole.getId());
            userRoleMapper.insert(userRole);
            log.info("默认角色分配成功 | userId={} | roleId={} | roleCode={}",
                    user.getId(), defaultRole.getId(), DEFAULT_ROLE_CODE);
        } else {
            log.warn("默认角色不存在 | tenantId={} | roleCode={}", user.getTenantId(), DEFAULT_ROLE_CODE);
        }
    }
}
