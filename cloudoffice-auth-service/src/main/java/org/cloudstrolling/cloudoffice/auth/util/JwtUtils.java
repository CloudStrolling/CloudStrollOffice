/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.util;

import cn.hutool.core.lang.Snowflake;
import cn.hutool.core.util.IdUtil;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.config.RsaKeyConfig;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.HexFormat;

/**
 * JWT 令牌工具类（RS256 双 Token）。
 *
 * <p>基于 RS256 非对称签名算法，提供 Access Token 和 Refresh Token
 * 的签发、解析以及签名指纹提取功能。</p>
 *
 * <p>Access Token 有效期较短（默认 2 小时），包含完整的用户身份与权限声明；
 * Refresh Token 有效期较长（默认 7 天），用于无感续签 Access Token，
 * 采用轮换策略防止重放攻击。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Component
public class JwtUtils {

    /** RSA 密钥配置（提供私钥用于签名，公钥用于验签） */
    private final RsaKeyConfig rsaKeyConfig;

    /** Access Token 过期时间，单位秒（默认 7200 秒 = 2 小时） */
    private final long accessTokenExpiration;

    /** Refresh Token 过期时间，单位秒（默认 604800 秒 = 7 天） */
    private final long refreshTokenExpiration;

    /** 雪花算法 ID 生成器，用于生成 Refresh Token 的 tokenVersion */
    private final Snowflake snowflake;

    /**
     * 构造器注入 JWT 配置。
     *
     * @param rsaKeyConfig           RSA 密钥配置
     * @param accessTokenExpiration  Access Token 过期时间（秒，默认 7200）
     * @param refreshTokenExpiration Refresh Token 过期时间（秒，默认 604800）
     */
    public JwtUtils(RsaKeyConfig rsaKeyConfig,
                    @Value("${jwt.access-token-expiration:7200}") long accessTokenExpiration,
                    @Value("${jwt.refresh-token-expiration:604800}") long refreshTokenExpiration) {
        this.rsaKeyConfig = rsaKeyConfig;
        this.accessTokenExpiration = accessTokenExpiration;
        this.refreshTokenExpiration = refreshTokenExpiration;
        // 初始化雪花算法 ID 生成器（数据中心 ID=1，机器 ID=1）
        this.snowflake = IdUtil.getSnowflake(1, 1);
        log.info("JwtUtils initialized: accessTokenExpiration={}s, refreshTokenExpiration={}s",
                accessTokenExpiration, refreshTokenExpiration);
    }

    /**
     * 获取 Access Token 过期时间（秒）。
     *
     * @return Access Token 过期时间秒数
     */
    public long getAccessTokenExpiration() {
        return accessTokenExpiration;
    }

    /**
     * 获取 Refresh Token 过期时间（秒）。
     *
     * @return Refresh Token 过期时间秒数
     */
    public long getRefreshTokenExpiration() {
        return refreshTokenExpiration;
    }

    /**
     * 生成 Access Token。
     *
     * <p>使用 RS256 算法和 RSA 私钥签名，包含以下声明：</p>
     * <ul>
     *   <li>{@code sub} — 用户 ID（字符串形式）</li>
     *   <li>{@code tenantId} — 租户 ID</li>
     *   <li>{@code clientType} — 客户端类型编码</li>
     *   <li>{@code tokenType} — 固定值 "access"</li>
     *   <li>{@code roles} — 角色编码列表</li>
     *   <li>{@code permissions} — 权限标识列表</li>
     *   <li>{@code iat} — 签发时间</li>
     *   <li>{@code exp} — 过期时间（当前时间 + 配置的 accessTokenExpiration）</li>
     * </ul>
     *
     * @param loginUser 登录用户信息
     * @return RS256 签名的 Access Token 字符串
     */
    public String generateAccessToken(LoginUserDTO loginUser) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + accessTokenExpiration * 1000L);

        String token = Jwts.builder()
                .subject(String.valueOf(loginUser.getUserId()))
                .claim("tenantId", loginUser.getTenantId())
                .claim("clientType", loginUser.getClientType())
                .claim("tokenType", "access")
                .claim("roles", loginUser.getRoles())
                .claim("permissions", loginUser.getPermissions())
                .issuedAt(now)
                .expiration(expiration)
                .signWith(rsaKeyConfig.getPrivateKey())
                .compact();

        log.debug("Generated Access Token for userId: {}, expires at: {}",
                loginUser.getUserId(), expiration);
        return token;
    }

    /**
     * 生成 Refresh Token。
     *
     * <p>使用 RS256 算法和 RSA 私钥签名，包含以下声明：</p>
     * <ul>
     *   <li>{@code sub} — 用户 ID（字符串形式）</li>
     *   <li>{@code tenantId} — 租户 ID</li>
     *   <li>{@code clientType} — 客户端类型编码</li>
     *   <li>{@code tokenType} — 固定值 "refresh"</li>
     *   <li>{@code tokenVersion} — 雪花算法生成的唯一版本号（防重放）</li>
     *   <li>{@code iat} — 签发时间</li>
     *   <li>{@code exp} — 过期时间（当前时间 + 配置的 refreshTokenExpiration）</li>
     * </ul>
     *
     * @param loginUser 登录用户信息
     * @return RS256 签名的 Refresh Token 字符串
     */
    public String generateRefreshToken(LoginUserDTO loginUser) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + refreshTokenExpiration * 1000L);

        String token = Jwts.builder()
                .subject(String.valueOf(loginUser.getUserId()))
                .claim("tenantId", loginUser.getTenantId())
                .claim("clientType", loginUser.getClientType())
                .claim("tokenType", "refresh")
                .claim("tokenVersion", snowflake.nextId())
                .issuedAt(now)
                .expiration(expiration)
                .signWith(rsaKeyConfig.getPrivateKey())
                .compact();

        log.debug("Generated Refresh Token for userId: {}, expires at: {}",
                loginUser.getUserId(), expiration);
        return token;
    }

    /**
     * 解析并验证 Access Token。
     *
     * <p>执行 RS256 公钥验签、过期时间校验，并检查 {@code tokenType="access"}。</p>
     *
     * @param token Access Token 字符串
     * @return JWT Claims 载荷
     * @throws ExpiredJwtException  Token 已过期
     * @throws SignatureException   签名验证失败
     * @throws MalformedJwtException Token 格式错误
     * @throws JwtException          tokenType 不匹配或其他 JWT 异常
     */
    public Claims parseAccessToken(String token) {
        Claims claims = parseToken(token);
        String tokenType = claims.get("tokenType", String.class);
        if (!"access".equals(tokenType)) {
            log.warn("Access Token tokenType 不匹配，期望 'access'，实际 '{}'", tokenType);
            throw new JwtException(
                    "Invalid token type: expected 'access' but got '" + tokenType + "'");
        }
        return claims;
    }

    /**
     * 解析并验证 Refresh Token。
     *
     * <p>执行 RS256 公钥验签、过期时间校验，并检查 {@code tokenType="refresh"}。</p>
     *
     * @param token Refresh Token 字符串
     * @return JWT Claims 载荷
     * @throws ExpiredJwtException  Token 已过期
     * @throws SignatureException   签名验证失败
     * @throws MalformedJwtException Token 格式错误
     * @throws JwtException          tokenType 不匹配或其他 JWT 异常
     */
    public Claims parseRefreshToken(String token) {
        Claims claims = parseToken(token);
        String tokenType = claims.get("tokenType", String.class);
        if (!"refresh".equals(tokenType)) {
            log.warn("Refresh Token tokenType 不匹配，期望 'refresh'，实际 '{}'", tokenType);
            throw new JwtException(
                    "Invalid token type: expected 'refresh' but got '" + tokenType + "'");
        }
        return claims;
    }

    /**
     * 获取 Token 的签名指纹。
     *
     * <p>对 Token 字符串进行 SHA-256 摘要计算，返回 64 字符的十六进制小写字符串。
     * 用于 Token 黑名单的 Key 标识。</p>
     *
     * @param token JWT 令牌字符串
     * @return 64 字符的 SHA-256 十六进制摘要
     */
    public String getTokenSignature(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(
                    token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 算法不可用", e);
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * 解析 JWT Token 的公共方法。
     *
     * <p>使用 RSA 公钥进行签名验证，返回标准 Claims。</p>
     *
     * @param token JWT 令牌字符串
     * @return JWT Claims 载荷
     */
    private Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(rsaKeyConfig.getPublicKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
