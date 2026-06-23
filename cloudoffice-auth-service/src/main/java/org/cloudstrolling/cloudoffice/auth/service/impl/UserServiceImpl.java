/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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
        log.info("用户注册开始 | loginName={} | tenantId={}", request.getLoginName(), request.getTenantId());

        // 1. 校验租户
        TenantEntity tenant = tenantMapper.selectById(request.getTenantId());
        if (tenant == null) {
            log.warn("租户不存在 | tenantId={}", request.getTenantId());
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }
        // 校验租户状态（0-正常，1-禁用，2-过期）
        if (tenant.getStatus() != null && tenant.getStatus() != 0) {
            if (tenant.getStatus() == 1) {
                log.warn("租户已被禁用 | tenantId={}", request.getTenantId());
                throw new BusinessException(ErrorCode.TENANT_DISABLED);
            }
            log.warn("租户已过期 | tenantId={}", request.getTenantId());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        // 校验租户有效期
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("租户已过期 | tenantId={} | expireTime={}", request.getTenantId(), tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }

        // 2. 校验 loginName 唯一性（同一租户内）
        UserEntity existingUser = userMapper.selectByTenantIdAndLoginName(
                request.getTenantId(), request.getLoginName());
        if (existingUser != null) {
            log.warn("登录名已存在 | loginName={} | tenantId={}", request.getLoginName(), request.getTenantId());
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "登录名已存在");
        }

        // 3. BCrypt 密码加密
        String encryptedPassword = passwordEncoder.encode(request.getPassword());
        log.debug("密码加密完成 | loginName={}", request.getLoginName());

        // 4. 创建用户记录
        UserEntity user = new UserEntity();
        user.setTenantId(request.getTenantId());
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
