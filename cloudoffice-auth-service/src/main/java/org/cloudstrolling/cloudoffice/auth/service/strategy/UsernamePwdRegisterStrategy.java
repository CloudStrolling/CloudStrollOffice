/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 用户名+密码注册策略。
 *
 * <p>处理 USERNAME 模式的注册流程：校验用户名/密码/手机号 → 校验唯一性
 * → BCrypt 加密密码 → 创建完整用户（accountSetled=true） → 返回注册结果。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UsernamePwdRegisterStrategy implements RegisterStrategy {

    private static final String DEFAULT_ROLE_CODE = "user";

    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final UserRoleMapper userRoleMapper;
    private final RoleMapper roleMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RegisterResult register(RegisterRequest request) {
        // 1. 校验必填字段
        Assert.hasText(request.getLoginName(), "loginName must not be empty");
        Assert.hasText(request.getPassword(), "password must not be empty");
        Assert.hasText(request.getTenantCode(), "tenantCode must not be empty");

        log.info("用户名密码注册开始 | loginName={} | tenantCode={}", request.getLoginName(), request.getTenantCode());

        // 2. 通过 tenantCode 查询租户并校验
        TenantEntity tenant = queryAndValidateTenant(request.getTenantCode());
        Long tenantId = tenant.getId();

        // 3. 校验 loginName 唯一性（同一租户内）
        checkLoginNameUnique(tenantId, request.getLoginName());

        // 4. 如果提供了手机号，校验手机号唯一性
        if (StringUtils.hasText(request.getPhone())) {
            checkPhoneUnique(request.getPhone());
        }

        // 5. BCrypt 密码加密
        String encryptedPassword = passwordEncoder.encode(request.getPassword());
        log.debug("密码加密完成 | loginName={}", request.getLoginName());

        // 6. 创建用户记录（account_settled = true）
        UserEntity user = buildUser(request, tenantId, encryptedPassword, true);
        userMapper.insert(user);
        log.info("用户记录创建成功 | userId={} | loginName={}", user.getId(), user.getLoginName());

        // 7. 分配默认角色
        assignDefaultRole(user);

        // 8. 构建返回 RegisterResult（不含 tokenPair）
        RegisterResult result = RegisterResult.builder()
                .userId(user.getId())
                .loginName(user.getLoginName())
                .userName(user.getUserName())
                .accountSettled(true)
                .build();

        log.info("用户名密码注册完成 | userId={} | loginName={}", user.getId(), user.getLoginName());
        return result;
    }

    /**
     * 根据租户编码查询并校验租户状态。
     *
     * @param tenantCode 租户编码
     * @return 租户实体
     * @throws BusinessException 如果租户不存在、已禁用或已过期
     */
    private TenantEntity queryAndValidateTenant(String tenantCode) {
        LambdaQueryWrapper<TenantEntity> tenantQuery = Wrappers.lambdaQuery(TenantEntity.class)
                .eq(TenantEntity::getTenantCode, tenantCode);
        TenantEntity tenant = tenantMapper.selectOne(tenantQuery);
        if (tenant == null) {
            log.warn("租户不存在 | tenantCode={}", tenantCode);
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }
        // 校验租户状态（0-正常，1-禁用，2-过期）
        if (tenant.getStatus() != null && tenant.getStatus() != 0) {
            if (tenant.getStatus() == 1) {
                log.warn("租户已被禁用 | tenantId={}", tenant.getId());
                throw new BusinessException(ErrorCode.TENANT_DISABLED);
            }
            log.warn("租户已过期 | tenantId={}", tenant.getId());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        // 校验租户有效期
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("租户已过期 | tenantId={} | expireTime={}", tenant.getId(), tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        return tenant;
    }

    /**
     * 校验 loginName 在指定租户内唯一。
     *
     * @param tenantId  租户 ID
     * @param loginName 登录名
     * @throws BusinessException 如果登录名已存在
     */
    private void checkLoginNameUnique(Long tenantId, String loginName) {
        UserEntity existingUser = userMapper.selectByTenantIdAndLoginName(tenantId, loginName);
        if (existingUser != null) {
            log.warn("登录名已存在 | loginName={} | tenantId={}", loginName, tenantId);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "登录名已存在");
        }
    }

    /**
     * 校验手机号全局唯一。
     *
     * @param phone 手机号
     * @throws BusinessException 如果手机号已被绑定
     */
    private void checkPhoneUnique(String phone) {
        LambdaQueryWrapper<UserEntity> phoneQuery = Wrappers.lambdaQuery(UserEntity.class)
                .eq(UserEntity::getPhone, phone);
        UserEntity existingUser = userMapper.selectOne(phoneQuery);
        if (existingUser != null) {
            log.warn("手机号已被绑定 | phone={}", phone);
            throw new BusinessException(ErrorCode.PHONE_ALREADY_BOUND);
        }
    }

    /**
     * 构建用户实体。
     *
     * @param request          注册请求
     * @param tenantId         租户 ID
     * @param encryptedPassword BCrypt 加密后的密码
     * @param accountSettled   账号信息是否完善
     * @return 用户实体
     */
    private UserEntity buildUser(RegisterRequest request, Long tenantId,
                                 String encryptedPassword, boolean accountSettled) {
        UserEntity user = new UserEntity();
        user.setTenantId(tenantId);
        user.setLoginName(request.getLoginName());
        user.setPassword(encryptedPassword);
        user.setUserName(request.getUserName());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());
        user.setStatus(0); // 0-正常
        user.setRegisterMode("USERNAME");
        user.setAccountSettled(accountSettled ? 1 : 0);
        return user;
    }

    /**
     * 为用户分配默认角色。
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
