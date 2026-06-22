/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.filter;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.constant.RedisKeyConstants;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.gateway.config.AuthProperties;
import org.cloudstrolling.cloudoffice.gateway.config.RsaKeyConfig;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.util.PathMatcher;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.List;

/**
 * 全局认证过滤器 {@code AuthFilter}。
 *
 * <p>实现 {@link GlobalFilter} + {@link Ordered} 接口，在网关层对所有请求进行统一认证拦截。</p>
 *
 * <p><b>校验流程（8 步）：</b></p>
 * <ol>
 *   <li><b>白名单放行</b>：判断请求路径是否在白名单中，是则直接放行</li>
 *   <li><b>Bearer 格式校验</b>：检查 {@code Authorization} 头格式为 {@code Bearer {token}}</li>
 *   <li><b>RS256 公钥验签</b>：解析 JWT Token 验证签名</li>
 *   <li><b>tokenType 校验</b>：验证 {@code tokenType = "access"}（仅 access token 通过）</li>
 *   <li><b>Redis 黑名单查询</b>：检查 Token 签名是否在黑名单中</li>
 *   <li><b>登录态查询</b>：查询 Redis 中是否存在登录会话</li>
 *   <li><b>账号状态校验</b>：检查账号状态缓存（封禁/禁用返回 403）</li>
 *   <li><b>租户状态校验</b>：检查租户状态缓存（禁用/过期返回 403）</li>
 *   <li><b>Header 透传</b>：将用户信息放入请求头转发给下游服务</li>
 * </ol>
 *
 * <p><b>透传 Header：</b></p>
 * <ul>
 *   <li>{@code X-User-Id} — 用户 ID</li>
 *   <li>{@code X-Tenant-Id} — 租户 ID</li>
 *   <li>{@code X-User-Name} — 用户名</li>
 *   <li>{@code X-Client-Type} — 客户端类型</li>
 *   <li>{@code X-Roles} — 角色编码列表（逗号分隔）</li>
 *   <li>{@code X-Permissions} — 权限标识列表（逗号分隔）</li>
 * </ul>
 *
 * <p><b>优先级：</b>{@link Ordered#HIGHEST_PRECEDENCE} + 10</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Component
public class AuthFilter implements GlobalFilter, Ordered {

    /**
     * Ant 风格路径匹配器，用于判断请求路径是否匹配白名单模式。
     */
    private static final PathMatcher PATH_MATCHER = new AntPathMatcher();

    /**
     * Bearer Token 前缀。
     */
    private static final String BEARER_PREFIX = "Bearer ";

    /**
     * Jackson ObjectMapper，用于将响应体序列化为 JSON 字符串。
     */
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private final AuthProperties authProperties;
    private final RsaKeyConfig rsaKeyConfig;
    private final org.springframework.data.redis.core.ReactiveRedisTemplate<String, Object> reactiveRedisTemplate;

    /**
     * 构造器注入。
     *
     * @param authProperties          认证配置属性（含白名单）
     * @param rsaKeyConfig            RSA 公钥配置
     * @param reactiveRedisTemplate   响应式 Redis 模板
     */
    public AuthFilter(AuthProperties authProperties,
                      RsaKeyConfig rsaKeyConfig,
                      org.springframework.data.redis.core.ReactiveRedisTemplate<String, Object> reactiveRedisTemplate) {
        this.authProperties = authProperties;
        this.rsaKeyConfig = rsaKeyConfig;
        this.reactiveRedisTemplate = reactiveRedisTemplate;
    }

    /**
     * 获取过滤器优先级。
     *
     * @return {@link Ordered#HIGHEST_PRECEDENCE} + 10
     */
    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }

    /**
     * 核心过滤方法。
     *
     * @param exchange 当前请求-响应交换对象
     * @param chain    过滤器链
     * @return {@link Mono#empty()} 表示过滤完成
     */
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // ========== 第 1 步：白名单放行 ==========
        String path = exchange.getRequest().getURI().getPath();
        if (isWhiteListPath(path)) {
            log.debug("白名单路径放行：{}", path);
            return chain.filter(exchange);
        }

        // ========== 第 2 步：Bearer 格式校验 ==========
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader == null || !authHeader.startsWith(BEARER_PREFIX)) {
            log.warn("缺少 Authorization 头或格式不正确，路径：{}", path);
            return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_INVALID);
        }

        String token = authHeader.substring(BEARER_PREFIX.length()).trim();
        if (token.isEmpty()) {
            log.warn("Authorization 头中 Token 为空，路径：{}", path);
            return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_INVALID);
        }

        // ========== 第 3 步：RS256 公钥验签 + 解析 Claims ==========
        Claims claims;
        try {
            claims = parseToken(token);
        } catch (ExpiredJwtException e) {
            log.warn("Token 已过期，路径：{}", path);
            return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_EXPIRED);
        } catch (JwtException e) {
            log.warn("Token 签名验证失败，路径：{}，错误：{}", path, e.getMessage());
            return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_INVALID);
        }

        // ========== 第 4 步：tokenType 校验 ==========
        String tokenType = claims.get("tokenType", String.class);
        if (!"access".equals(tokenType)) {
            log.warn("Token 类型不正确，期望 access，实际：{}，路径：{}", tokenType, path);
            return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_INVALID);
        }

        // 提取用户信息
        Long userId = Long.parseLong(claims.getSubject());
        Long tenantId = claims.get("tenantId", Long.class);
        String userName = claims.get("userName", String.class);
        String clientType = claims.get("clientType", String.class);

        // 提取角色和权限（以逗号分隔的字符串形式存储）
        String rolesStr = commaSeparateClaim(claims.get("roles"));
        String permissionsStr = commaSeparateClaim(claims.get("permissions"));

        // 获取 Token 签名指纹（SHA-256），用于黑名单 Key
        String tokenSignature = getTokenSignature(token);

        // ========== 第 5-8 步：Redis 顺序校验 ==========
        return checkBlacklist(tokenSignature)
                .flatMap(blacklisted -> {
                    if (Boolean.TRUE.equals(blacklisted)) {
                        log.warn("Token 在黑名单中，userId：{}", userId);
                        return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.TOKEN_BLACKLISTED);
                    }
                    return checkSession(userId, clientType)
                            .flatMap(sessionExists -> {
                                if (Boolean.FALSE.equals(sessionExists)) {
                                    log.warn("登录态不存在，userId：{}，clientType：{}", userId, clientType);
                                    return writeErrorResponse(exchange, HttpStatus.UNAUTHORIZED, ErrorCode.SESSION_KICKED_OUT);
                                }
                                return checkAccountStatus(userId)
                                        .flatMap(accountStatus -> {
                                            if (!accountStatus.isEmpty()) {
                                                ErrorCode statusError = getAccountStatusError(accountStatus);
                                                if (statusError != null) {
                                                    log.warn("账号状态异常，userId：{}，status：{}", userId, accountStatus);
                                                    return writeErrorResponse(exchange, HttpStatus.FORBIDDEN, statusError);
                                                }
                                            }
                                            return checkTenantStatus(tenantId)
                                                    .flatMap(tenantStatus -> {
                                                        if (!tenantStatus.isEmpty()) {
                                                            ErrorCode statusError = getTenantStatusError(tenantStatus);
                                                            if (statusError != null) {
                                                                log.warn("租户状态异常，tenantId：{}，status：{}", tenantId, tenantStatus);
                                                                return writeErrorResponse(exchange, HttpStatus.FORBIDDEN, statusError);
                                                            }
                                                        }
                                                        // ========== 第 9 步：Header 透传 ==========
                                                        return forwardWithHeaders(
                                                                exchange, chain, userId, tenantId,
                                                                userName, clientType, rolesStr, permissionsStr);
                                                    });
                                        });
                            });
                })
                .onErrorResume(e -> {
                    log.error("AuthFilter 处理异常，路径：{}，错误：{}", path, e.getMessage(), e);
                    return writeErrorResponse(exchange, HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_ERROR);
                });
    }

    // ==================== 白名单校验 ====================

    /**
     * 判断请求路径是否在白名单中。
     *
     * <p>支持 Ant 风格路径匹配（如 {@code /swagger-ui/**}）。</p>
     *
     * @param path 请求路径
     * @return 如果路径匹配任意白名单模式则返回 {@code true}
     */
    private boolean isWhiteListPath(String path) {
        List<String> whiteList = authProperties.getWhiteList();
        if (whiteList == null || whiteList.isEmpty()) {
            return false;
        }
        for (String pattern : whiteList) {
            if (PATH_MATCHER.match(pattern, path)) {
                return true;
            }
        }
        return false;
    }

    // ==================== Token 解析 ====================

    /**
     * 使用 RSA 公钥解析并验证 JWT Token。
     *
     * @param token JWT 字符串
     * @return JWT Claims
     * @throws ExpiredJwtException Token 已过期
     * @throws JwtException        Token 签名无效或格式错误
     */
    private Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(rsaKeyConfig.getPublicKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    // ==================== Token 签名指纹 ====================

    /**
     * 获取 Token 的签名指纹（SHA-256 摘要）。
     *
     * <p>用于构建 Redis 黑名单 Key，确保相同 Token 产生相同指纹。</p>
     *
     * @param token JWT 字符串
     * @return Base64 URL 安全编码的 SHA-256 摘要（无填充）
     */
    private String getTokenSignature(String token) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    // ==================== Claims 辅助方法 ====================

    /**
     * 将 JWT Claims 中的角色/权限值转换为逗号分隔的字符串。
     *
     * <p>支持 {@link List} 类型（序列化为逗号分隔）和 {@link String} 类型（直接返回）。</p>
     *
     * @param claim Claim 值
     * @return 逗号分隔的字符串，如果为 null 则返回空字符串
     */
    @SuppressWarnings("unchecked")
    private String commaSeparateClaim(Object claim) {
        if (claim == null) {
            return "";
        }
        if (claim instanceof List) {
            return String.join(",", (List<String>) claim);
        }
        return claim.toString();
    }

    // ==================== Redis 黑名单校验 ====================

    /**
     * 检查 Token 签名是否在 Redis 黑名单中。
     *
     * @param tokenSignature Token 签名指纹
     * @return 如果 Token 在黑名单中则返回 {@link Mono#just Mono&lt;Boolean&gt;(true)}
     */
    private Mono<Boolean> checkBlacklist(String tokenSignature) {
        String key = RedisKeyConstants.buildBlacklistKey(tokenSignature);
        return reactiveRedisTemplate.opsForValue().get(key)
                .map(value -> value != null)
                .defaultIfEmpty(false);
    }

    // ==================== Redis 登录态校验 ====================

    /**
     * 检查 Redis 中是否存在用户登录会话。
     *
     * @param userId     用户 ID
     * @param clientType 客户端类型
     * @return 如果登录态存在则返回 {@link Mono#just Mono&lt;Boolean&gt;(true)}
     */
    private Mono<Boolean> checkSession(Long userId, String clientType) {
        String key = RedisKeyConstants.buildSessionKey(userId, clientType);
        return reactiveRedisTemplate.opsForValue().get(key)
                .map(value -> value != null)
                .defaultIfEmpty(false);
    }

    // ==================== Redis 账号状态校验 ====================

    /**
     * 查询 Redis 中账号状态缓存。
     *
     * @param userId 用户 ID
     * @return 账号状态值，如果缓存不存在则返回 {@link Mono#just Mono&lt;String&gt;(null)}
     */
    private Mono<String> checkAccountStatus(Long userId) {
        String key = RedisKeyConstants.buildAccountStatusKey(userId);
        return reactiveRedisTemplate.opsForValue().get(key)
                .map(value -> value != null ? value.toString() : "")
                .defaultIfEmpty("");
    }

    /**
     * 根据账号状态值获取对应的错误码。
     *
     * @param status 账号状态（1-禁用，2-锁定，3-封禁）
     * @return 对应的错误码，状态正常时返回 {@code null}
     */
    private ErrorCode getAccountStatusError(String status) {
        return switch (status) {
            case "1" -> ErrorCode.ACCOUNT_DISABLED;
            case "2" -> ErrorCode.ACCOUNT_LOCKED;
            case "3" -> ErrorCode.ACCOUNT_BANNED;
            default -> null;
        };
    }

    // ==================== Redis 租户状态校验 ====================

    /**
     * 查询 Redis 中租户状态缓存。
     *
     * @param tenantId 租户 ID
     * @return 租户状态值，如果缓存不存在则返回 {@link Mono#just Mono&lt;String&gt;(null)}
     */
    private Mono<String> checkTenantStatus(Long tenantId) {
        String key = RedisKeyConstants.buildTenantStatusKey(tenantId);
        return reactiveRedisTemplate.opsForValue().get(key)
                .map(value -> value != null ? value.toString() : "")
                .defaultIfEmpty("");
    }

    /**
     * 根据租户状态值获取对应的错误码。
     *
     * @param status 租户状态（1-禁用，2-过期）
     * @return 对应的错误码，状态正常时返回 {@code null}
     */
    private ErrorCode getTenantStatusError(String status) {
        return switch (status) {
            case "1" -> ErrorCode.TENANT_DISABLED;
            case "2" -> ErrorCode.TENANT_EXPIRED;
            default -> null;
        };
    }

    // ==================== Header 透传 ====================

    /**
     * 将用户信息从 JWT Claims 中提取并放入请求头，放行请求到下游服务。
     *
     * @param exchange        当前请求-响应交换对象
     * @param chain           过滤器链
     * @param userId          用户 ID
     * @param tenantId        租户 ID
     * @param userName        用户名
     * @param clientType      客户端类型
     * @param rolesStr        角色编码列表（逗号分隔）
     * @param permissionsStr  权限标识列表（逗号分隔）
     * @return 过滤完成信号
     */
    private Mono<Void> forwardWithHeaders(ServerWebExchange exchange, GatewayFilterChain chain,
                                          Long userId, Long tenantId, String userName,
                                          String clientType, String rolesStr, String permissionsStr) {
        ServerHttpRequest mutatedRequest = exchange.getRequest().mutate()
                .header("X-User-Id", String.valueOf(userId))
                .header("X-Tenant-Id", String.valueOf(tenantId))
                .header("X-User-Name", userName != null ? userName : "")
                .header("X-Client-Type", clientType != null ? clientType : "")
                .header("X-Roles", rolesStr)
                .header("X-Permissions", permissionsStr)
                .build();

        log.debug("AuthFilter 校验通过，userId：{}，tenantId：{}，path：{}", userId, tenantId, exchange.getRequest().getURI().getPath());

        return chain.filter(exchange.mutate().request(mutatedRequest).build());
    }

    // ==================== 错误响应 ====================

    /**
     * 使用 {@link ServerHttpResponse} 写入统一格式的错误响应。
     *
     * <p>响应格式：</p>
     * <pre>{@code
     * {
     *   "code": 401,
     *   "message": "令牌已过期",
     *   "data": null,
     *   "timestamp": 1718000000000
     * }
     * }</pre>
     *
     * @param exchange   当前请求-响应交换对象
     * @param httpStatus HTTP 状态码
     * @param errorCode  错误码枚举
     * @return {@link Mono#empty()} 表示响应已写入
     */
    private Mono<Void> writeErrorResponse(ServerWebExchange exchange, HttpStatus httpStatus, ErrorCode errorCode) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(httpStatus);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);

        ApiResult<Void> apiResult = ApiResult.error(errorCode.getCode(), errorCode.getMessage());
        String jsonBody;
        try {
            jsonBody = OBJECT_MAPPER.writeValueAsString(apiResult);
        } catch (JsonProcessingException e) {
            log.error("序列化错误响应失败", e);
            jsonBody = "{\"code\":" + errorCode.getCode() + ",\"message\":\"" + errorCode.getMessage() + "\",\"data\":null,\"timestamp\":" + System.currentTimeMillis() + "}";
        }

        byte[] bytes = jsonBody.getBytes(StandardCharsets.UTF_8);
        DataBuffer buffer = response.bufferFactory().wrap(bytes);
        return response.writeWith(Mono.just(buffer));
    }
}
