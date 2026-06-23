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
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;

import java.util.List;

/**
 * 手机+密码登录策略。
 *
 * <p>校验用户输入的手机号和密码，验证通过后返回认证结果。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PhonePasswordLoginStrategy implements LoginStrategy {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public AuthResult authenticate(LoginRequest request) {
        // 1. 校验 phone 和 password 不为空
        Assert.hasText(request.getPhone(), "phone must not be empty");
        Assert.hasText(request.getPassword(), "password must not be empty");

        // 2. 通过手机号查询用户
        LambdaQueryWrapper<UserEntity> userQuery = Wrappers.lambdaQuery();
        userQuery.eq(UserEntity::getPhone, request.getPhone());
        UserEntity user = userMapper.selectOne(userQuery);
        if (user == null) {
            log.warn("用户不存在 | phone={}", request.getPhone());
            throw new AuthException(ErrorCode.USER_NOT_FOUND);
        }

        // 3. BCrypt 校验密码
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("密码错误 | phone={}", request.getPhone());
            throw new AuthException(ErrorCode.LOGIN_FAILED);
        }

        // 4. 查询角色和权限列表
        List<String> roles = userMapper.selectRoleCodesByUserId(user.getId());
        List<String> permissions = userMapper.selectPermissionCodesByUserId(user.getId());

        // 5. 构建并返回 AuthResult
        log.info("手机密码登录成功 | userId={} | phone={}", user.getId(), user.getPhone());
        return AuthResult.builder()
                .userId(user.getId())
                .tenantId(user.getTenantId())
                .loginName(user.getLoginName())
                .userName(user.getUserName())
                .phone(user.getPhone())
                .roles(roles)
                .permissions(permissions)
                .build();
    }
}
