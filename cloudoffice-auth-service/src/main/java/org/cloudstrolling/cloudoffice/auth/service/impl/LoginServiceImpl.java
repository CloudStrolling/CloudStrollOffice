/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import io.jsonwebtoken.Claims;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.enums.ClientTypeEnum;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;
import java.util.Optional;

/**
 * 登录认证业务服务实现类。
 *
 * <p>实现 {@link LoginService} 接口，提供登录、登出、强制踢人等认证业务逻辑，
 * 涉及 {@link UserMapper}、{@link LoginSessionService}、{@link LoginLogMapper} 等组件协作。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
public class LoginServiceImpl implements LoginService {

    /** 管理员角色编码 */
    private static final String ADMIN_ROLE_CODE = "admin";

    private final UserMapper userMapper;
    private final LoginSessionService loginSessionService;
    private final LoginLogMapper loginLogMapper;
    private final JwtUtils jwtUtils;
    private final LoginLogService loginLogService;

    /**
     * 构造器注入依赖。
     *
     * @param userMapper          用户 Mapper
     * @param loginSessionService Redis 登录态管理服务
     * @param loginLogMapper      登录日志 Mapper
     * @param jwtUtils            JWT 令牌工具类
     * @param loginLogService     登录日志审计服务
     */
    public LoginServiceImpl(UserMapper userMapper,
                            LoginSessionService loginSessionService,
                            LoginLogMapper loginLogMapper,
                            JwtUtils jwtUtils,
                            LoginLogService loginLogService) {
        Assert.notNull(userMapper, "userMapper must not be null");
        Assert.notNull(loginSessionService, "loginSessionService must not be null");
        Assert.notNull(loginLogMapper, "loginLogMapper must not be null");
        Assert.notNull(jwtUtils, "jwtUtils must not be null");
        Assert.notNull(loginLogService, "loginLogService must not be null");
        this.userMapper = userMapper;
        this.loginSessionService = loginSessionService;
        this.loginLogMapper = loginLogMapper;
        this.jwtUtils = jwtUtils;
        this.loginLogService = loginLogService;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void kickout(Long targetUserId, String clientType) {
        Assert.notNull(targetUserId, "targetUserId must not be null");

        // 1. 校验操作者权限（需登录用户有管理员权限）
        LoginUserDTO operator = getCurrentOperator();
        if (operator == null || !isAdmin(operator)) {
            log.warn("Kickout permission denied | operator={} | targetUserId={} | clientType={}",
                    operator != null ? operator.getUserId() : "unknown", targetUserId, clientType);
            throw new BusinessException(ErrorCode.PERMISSION_DENIED);
        }

        log.info("Kickout initiated | operatorId={} | targetUserId={} | clientType={}",
                operator.getUserId(), targetUserId, clientType);

        // 2. 校验目标用户存在（BaseEntity 的 @TableLogic 已自动过滤已删除记录）
        UserEntity targetUser = userMapper.selectById(targetUserId);
        if (targetUser == null) {
            log.warn("Kickout target user not found | targetUserId={}", targetUserId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        if (StringUtils.hasText(clientType)) {
            // 3a. 如 clientType 非空：踢指定端的登录态
            Optional<ClientTypeEnum> clientTypeOpt = ClientTypeEnum.fromCode(clientType);
            if (clientTypeOpt.isEmpty()) {
                log.warn("Kickout invalid clientType | clientType={}", clientType);
                throw new BusinessException(ErrorCode.CLIENT_TYPE_INVALID);
            }

            // 获取登录态并提取 Token 签名加入黑名单
            LoginUserDTO session = loginSessionService.getSession(targetUserId, clientType);
            if (session != null) {
                // 登录态删除
                loginSessionService.removeSession(targetUserId, clientType);
                log.info("Kickout removed session | targetUserId={} | clientType={}", targetUserId, clientType);
            } else {
                log.debug("Kickout no active session | targetUserId={} | clientType={}", targetUserId, clientType);
            }
        } else {
            // 3b. 如 clientType 为空：踢所有端的登录态
            loginSessionService.removeAllSessions(targetUserId);
            log.info("Kickout removed all sessions | targetUserId={}", targetUserId);
        }

        // 4. 审计日志记录
        recordKickoutLog(targetUserId, clientType, operator);

        log.info("Kickout completed | operatorId={} | targetUserId={} | clientType={}",
                operator.getUserId(), targetUserId, clientType);
    }

    @Override
    public void logout(String accessToken, String clientType) {
        try {
            // 1. 解析 Access Token，获取用户信息和过期时间
            Claims claims = jwtUtils.parseAccessToken(accessToken);
            Long userId = Long.parseLong(claims.getSubject());

            // 2. 获取 Token 签名指纹
            String signature = jwtUtils.getTokenSignature(accessToken);

            // 3. 计算 Token 剩余有效期（秒），最小为 1 秒
            Date expiration = claims.getExpiration();
            long remainingTtl = Math.max(1,
                    (expiration.getTime() - System.currentTimeMillis()) / 1000);

            // 4. 将 Token 加入黑名单（失败不影响后续清理）
            try {
                loginSessionService.addToBlacklist(signature, remainingTtl);
            } catch (Exception e) {
                log.warn("Failed to add token to blacklist: {}", e.getMessage());
            }

            // 5. 删除 Redis 登录态会话（失败不影响日志更新）
            try {
                loginSessionService.removeSession(userId, clientType);
            } catch (Exception e) {
                log.warn("Failed to remove session: {}", e.getMessage());
            }

            // 6. 更新登录日志登出时间
            try {
                loginLogService.updateLogoutTime(userId, clientType);
            } catch (Exception e) {
                log.warn("Failed to update logout time: {}", e.getMessage());
            }

            log.info("User logged out successfully | userId={} | clientType={} | ttl={}s",
                    userId, clientType, remainingTtl);
        } catch (Exception e) {
            // 幂等处理：重复登出或 Token 已失效时仅记录警告，不抛出异常
            log.warn("Logout encountered issue (idempotent handling): {}", e.getMessage());
        }
    }

    /**
     * 从当前请求上下文中获取操作者信息。
     *
     * <p>从请求头中提取网关透传的用户信息：</p>
     * <ul>
     *   <li>X-User-Id — 用户 ID</li>
     *   <li>X-Tenant-Id — 租户 ID</li>
     *   <li>X-User-Name — 用户名</li>
     *   <li>X-Client-Type — 客户端类型</li>
     *   <li>X-Roles — 角色编码列表（逗号分隔）</li>
     *   <li>X-Permissions — 权限标识列表（逗号分隔）</li>
     * </ul>
     *
     * @return 操作者信息，无法获取时返回 null
     */
    private LoginUserDTO getCurrentOperator() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes)
                    RequestContextHolder.currentRequestAttributes();
            if (attributes == null) {
                return null;
            }

            String userIdStr = attributes.getRequest().getHeader("X-User-Id");
            String tenantIdStr = attributes.getRequest().getHeader("X-Tenant-Id");
            String userName = attributes.getRequest().getHeader("X-User-Name");
            String clientType = attributes.getRequest().getHeader("X-Client-Type");
            String rolesStr = attributes.getRequest().getHeader("X-Roles");
            String permissionsStr = attributes.getRequest().getHeader("X-Permissions");

            if (userIdStr == null || userIdStr.isEmpty()) {
                return null;
            }

            LoginUserDTO operator = LoginUserDTO.builder()
                    .userId(Long.valueOf(userIdStr))
                    .tenantId(tenantIdStr != null ? Long.valueOf(tenantIdStr) : null)
                    .userName(userName)
                    .clientType(clientType)
                    .build();

            if (StringUtils.hasText(rolesStr)) {
                List<String> roles = List.of(rolesStr.split(","));
                operator.setRoles(roles);
            }

            if (StringUtils.hasText(permissionsStr)) {
                List<String> permissions = List.of(permissionsStr.split(","));
                operator.setPermissions(permissions);
            }

            return operator;
        } catch (Exception e) {
            log.warn("Failed to get current operator from request context", e);
            return null;
        }
    }

    /**
     * 判断操作者是否为管理员。
     *
     * @param operator 操作者信息
     * @return 如果是管理员返回 true，否则 false
     */
    private boolean isAdmin(LoginUserDTO operator) {
        return operator.getRoles() != null
                && operator.getRoles().stream()
                .anyMatch(ADMIN_ROLE_CODE::equalsIgnoreCase);
    }

    /**
     * 记录强制踢人审计日志。
     *
     * @param targetUserId 目标用户 ID
     * @param clientType   客户端类型（可能为 null）
     * @param operator     操作者信息
     */
    private void recordKickoutLog(Long targetUserId, String clientType, LoginUserDTO operator) {
        try {
            LoginLogEntity logEntity = new LoginLogEntity();
            logEntity.setUserId(targetUserId);
            logEntity.setTenantId(operator.getTenantId());
            logEntity.setClientType(clientType != null ? clientType : "ALL");
            logEntity.setLoginTime(LocalDateTime.now());
            logEntity.setLoginResult(2); // 2-登出/踢人
            logEntity.setFailReason("管理员(ID:" + operator.getUserId() + ")强制踢人");
            loginLogMapper.insert(logEntity);
            log.info("Kickout audit log recorded | targetUserId={} | operatorId={}", targetUserId, operator.getUserId());
        } catch (Exception e) {
            // 审计日志写入失败不影响踢人主流程，仅记录错误日志
            log.error("Failed to record kickout audit log | targetUserId={}", targetUserId, e);
        }
    }
}
