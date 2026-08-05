/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;

import java.util.List;

/**
 * 用户名+密码登录策略。
 *
 * <p>校验用户输入的用户名和密码，验证通过后返回认证结果。
 * 使用 BCrypt 密码加密算法进行密码比对。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UsernamePasswordStrategy implements LoginStrategy {

    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public AuthResult authenticate(LoginRequest request) {
        // 1. 校验 loginName 和 password 不为空
        Assert.hasText(request.getLoginName(), "loginName must not be empty");
        Assert.hasText(request.getPassword(), "password must not be empty");
        Assert.hasText(request.getTenantCode(), "tenantCode must not be empty");

        // 2. 通过 tenantCode 查询租户
        LambdaQueryWrapper<TenantEntity> tenantQuery = Wrappers.lambdaQuery();
        tenantQuery.eq(TenantEntity::getTenantCode, request.getTenantCode());
        TenantEntity tenant = tenantMapper.selectOne(tenantQuery);
        if (tenant == null) {
            log.warn("租户不存在 | tenantCode={}", request.getTenantCode());
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }

        // 3. 通过 loginName + tenantId 查询用户
        UserEntity user = userMapper.selectByTenantIdAndLoginName(tenant.getId(), request.getLoginName());
        if (user == null) {
            log.warn("用户不存在 | loginName={} | tenantId={}", request.getLoginName(), tenant.getId());
            throw new AuthException(ErrorCode.USER_NOT_FOUND);
        }

        // 4. BCrypt 校验密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("密码错误 | loginName={}", request.getLoginName());
            throw new AuthException(ErrorCode.LOGIN_FAILED);
        }

        // 5. 查询角色和权限列表
        List<String> roles = userMapper.selectRoleCodesByUserId(user.getId());
        List<String> permissions = userMapper.selectPermissionCodesByUserId(user.getId());

        // 6. 构建并返回 AuthResult
        log.info("用户名密码登录成功 | userId={} | loginName={}", user.getId(), user.getLoginName());
        return AuthResult.builder()
                .userId(user.getId())
                .tenantId(tenant.getId())
                .loginName(user.getLoginName())
                .userName(user.getUserName())
                .phone(user.getPhone())
                .roles(roles)
                .permissions(permissions)
                .build();
    }
}
