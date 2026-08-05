/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import io.jsonwebtoken.Claims;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.enums.ClientTypeEnum;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

/**
 * 登录认证业务服务实现类。
 *
 * <p>实现 {@link LoginService} 接口，提供登录、登出、强制踢人等认证业务逻辑，
 * 涉及 {@link UserMapper}、{@link TenantMapper}、{@link LoginSessionService}、
 * {@link LoginLogMapper} 等组件协作。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
public class LoginServiceImpl implements LoginService {

    /** 管理员角色编码 */
    private static final String ADMIN_ROLE_CODE = "admin";

    /** 正常状态 */
    private static final int STATUS_NORMAL = 0;

    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final LoginSessionService loginSessionService;
    private final LoginLogMapper loginLogMapper;
    private final JwtUtils jwtUtils;
    private final LoginLogService loginLogService;
    private final PasswordEncoder passwordEncoder;
    private final long refreshTokenExpiration;

    /**
     * 构造器注入依赖。
     *
     * @param userMapper              用户 Mapper
     * @param tenantMapper            租户 Mapper
     * @param loginSessionService     Redis 登录态管理服务
     * @param loginLogMapper          登录日志 Mapper
     * @param jwtUtils                JWT 令牌工具类
     * @param loginLogService         登录日志审计服务
     * @param passwordEncoder         BCrypt 密码编码器
     * @param refreshTokenExpiration  Refresh Token 过期时间（秒）
     */
    public LoginServiceImpl(UserMapper userMapper,
                            TenantMapper tenantMapper,
                            LoginSessionService loginSessionService,
                            LoginLogMapper loginLogMapper,
                            JwtUtils jwtUtils,
                            LoginLogService loginLogService,
                            PasswordEncoder passwordEncoder,
                            @Value("${jwt.refresh-token-expiration:604800}") long refreshTokenExpiration) {
        Assert.notNull(userMapper, "userMapper must not be null");
        Assert.notNull(tenantMapper, "tenantMapper must not be null");
        Assert.notNull(loginSessionService, "loginSessionService must not be null");
        Assert.notNull(loginLogMapper, "loginLogMapper must not be null");
        Assert.notNull(jwtUtils, "jwtUtils must not be null");
        Assert.notNull(loginLogService, "loginLogService must not be null");
        Assert.notNull(passwordEncoder, "passwordEncoder must not be null");
        this.userMapper = userMapper;
        this.tenantMapper = tenantMapper;
        this.loginSessionService = loginSessionService;
        this.loginLogMapper = loginLogMapper;
        this.jwtUtils = jwtUtils;
        this.loginLogService = loginLogService;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenExpiration = refreshTokenExpiration;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public TokenPairDTO login(LoginRequest request) {
        // 1. 参数校验
        Assert.hasText(request.getLoginName(), "loginName must not be empty");
        Assert.hasText(request.getPassword(), "password must not be empty");
        Assert.hasText(request.getTenantCode(), "tenantCode must not be empty");
        Assert.hasText(request.getClientType(), "clientType must not be empty");

        // 2. 校验 clientType 合法性
        Optional<ClientTypeEnum> clientTypeOpt = ClientTypeEnum.fromCode(request.getClientType());
        if (clientTypeOpt.isEmpty()) {
            log.warn("Login failed: invalid clientType={}", request.getClientType());
            throw new BusinessException(ErrorCode.CLIENT_TYPE_INVALID);
        }
        ClientTypeEnum clientTypeEnum = clientTypeOpt.get();

        // 3. 查询租户
        LambdaQueryWrapper<TenantEntity> tenantQuery = Wrappers.lambdaQuery();
        tenantQuery.eq(TenantEntity::getTenantCode, request.getTenantCode());
        TenantEntity tenant = tenantMapper.selectOne(tenantQuery);

        // 4. 校验租户状态
        if (tenant == null) {
            log.warn("Login failed: tenant not found | tenantCode={}", request.getTenantCode());
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }
        checkTenantStatus(tenant);

        // 5. 查询用户
        UserEntity user = userMapper.selectByTenantIdAndLoginName(tenant.getId(), request.getLoginName());
        if (user == null) {
            log.warn("Login failed: user not found | loginName={} | tenantId={}",
                    request.getLoginName(), tenant.getId());
            throw new AuthException(ErrorCode.LOGIN_FAILED);
        }

        // 6. 校验用户状态
        checkUserStatus(user);

        // 7. BCrypt 密码校验
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("Login failed: password mismatch | loginName={}", request.getLoginName());
            String loginIp = getClientIp();
            loginLogService.recordLoginFailure(request.getLoginName(), loginIp,
                    request.getClientType(), "密码错误");
            throw new AuthException(ErrorCode.LOGIN_FAILED);
        }

        // 8. 查询角色和权限
        List<String> roles = userMapper.selectRoleCodesByUserId(user.getId());
        List<String> permissions = userMapper.selectPermissionCodesByUserId(user.getId());

        // 9. 构建 LoginUserDTO
        LoginUserDTO loginUser = LoginUserDTO.builder()
                .userId(user.getId())
                .tenantId(tenant.getId())
                .userName(user.getUserName())
                .clientType(request.getClientType())
                .roles(roles != null ? new ArrayList<>(roles) : new ArrayList<>())
                .permissions(permissions != null ? new ArrayList<>(permissions) : new ArrayList<>())
                .build();

        // 10. 签发双 Token
        String accessToken = jwtUtils.generateAccessToken(loginUser);
        String refreshToken = jwtUtils.generateRefreshToken(loginUser);

        long nowMillis = System.currentTimeMillis();
        long accessTokenExpireIn = nowMillis + jwtUtils.getAccessTokenExpiration() * 1000L;
        long refreshTokenExpireIn = nowMillis + refreshTokenExpiration * 1000L;

        TokenPairDTO tokenPair = TokenPairDTO.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .accessTokenExpireIn(accessTokenExpireIn)
                .refreshTokenExpireIn(refreshTokenExpireIn)
                .tokenType("Bearer")
                .build();

        // 获取客户端 IP
        String loginIp = getClientIp();

        // 11. 同端互斥处理：清理同设备分类的旧会话
        processMutualExclusion(user.getId(), clientTypeEnum);

        // 12. 写入 Redis 登录态会话
        try {
            loginSessionService.createSession(user.getId(), request.getClientType(),
                    loginUser, refreshTokenExpiration);
        } catch (Exception e) {
            log.error("Failed to create session for userId={}", user.getId(), e);
        }

        // 13. 写入账号/租户状态缓存
        try {
            loginSessionService.setAccountStatus(user.getId(), user.getStatus());
            loginSessionService.setTenantStatus(tenant.getId(), tenant.getStatus());
        } catch (Exception e) {
            log.error("Failed to cache status for userId={}", user.getId(), e);
        }

        // 14. 记录登录成功日志
        loginLogService.recordLoginSuccess(tenant.getId(), user.getId(),
                user.getLoginName(), loginIp, request.getClientType(), null);

        // 15. 更新用户表的 last_login_time 和 last_login_ip
        user.setLastLoginTime(LocalDateTime.now());
        user.setLastLoginIp(loginIp);
        userMapper.updateById(user);

        log.info("User login successful | userId={} | tenantId={} | clientType={} | ip={}",
                user.getId(), tenant.getId(), request.getClientType(), loginIp);

        // 16. 返回 TokenPairDTO（密码已在实体中，返回前不清空密码实体字段）
        return tokenPair;
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
     * 获取客户端 IP 地址。
     *
     * <p>优先从 X-Forwarded-For 请求头获取，其次从 getRemoteAddr() 获取。</p>
     *
     * @return 客户端 IP 地址，无法获取时返回 "unknown"
     */
    private String getClientIp() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes)
                    RequestContextHolder.currentRequestAttributes();
            if (attributes == null) {
                return "unknown";
            }
            String ip = attributes.getRequest().getHeader("X-Forwarded-For");
            if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                ip = attributes.getRequest().getRemoteAddr();
            }
            return ip != null ? ip : "unknown";
        } catch (Exception e) {
            log.warn("Failed to get client IP", e);
            return "unknown";
        }
    }

    /**
     * 校验租户状态。
     *
     * <p>检查租户是否被禁用或已过期。</p>
     *
     * @param tenant 租户实体
     * @throws BusinessException 如果租户已禁用或已过期
     */
    private void checkTenantStatus(TenantEntity tenant) {
        if (tenant.getStatus() != null && tenant.getStatus() == 1) {
            log.warn("Tenant disabled | tenantId={} | tenantCode={}",
                    tenant.getId(), tenant.getTenantCode());
            throw new BusinessException(ErrorCode.TENANT_DISABLED);
        }
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("Tenant expired | tenantId={} | tenantCode={} | expireTime={}",
                    tenant.getId(), tenant.getTenantCode(), tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
    }

    /**
     * 校验用户状态。
     *
     * <p>检查用户账号是否被禁用、锁定、封禁或已过期。
     * 用户状态：0-正常，1-禁用，2-锁定，3-封禁，4-过期。</p>
     *
     * @param user 用户实体
     * @throws BusinessException 如果账号状态异常
     */
    private void checkUserStatus(UserEntity user) {
        if (user.getStatus() == null || user.getStatus() == STATUS_NORMAL) {
            return;
        }
        switch (user.getStatus()) {
            case 1:
                log.warn("Account disabled | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_DISABLED);
            case 2:
                log.warn("Account locked | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_LOCKED);
            case 3:
                log.warn("Account banned | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_BANNED);
            case 4:
                log.warn("Account expired | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_EXPIRED);
            default:
                log.warn("Unknown account status | userId={} | status={}", user.getId(), user.getStatus());
                throw new BusinessException(ErrorCode.ACCOUNT_DISABLED);
        }
    }

    /**
     * 处理同端互斥。
     *
     * <p>遍历所有客户端类型，找出与当前登录客户端类型同设备分类的已有会话，
     * 清理旧会话的 Redis 登录态。</p>
     *
     * @param userId         用户 ID
     * @param clientTypeEnum 当前登录的客户端类型枚举
     */
    private void processMutualExclusion(Long userId, ClientTypeEnum clientTypeEnum) {
        try {
            for (ClientTypeEnum type : ClientTypeEnum.values()) {
                if (type.isSameCategory(clientTypeEnum)) {
                    LoginUserDTO oldSession = loginSessionService.getSession(userId, type.getCode());
                    if (oldSession != null) {
                        loginSessionService.removeSession(userId, type.getCode());
                        log.info("Mutual exclusion: removed old session | userId={} | clientType={}",
                                userId, type.getCode());
                    }
                }
            }
        } catch (Exception e) {
            log.error("Mutual exclusion processing failed | userId={}", userId, e);
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
