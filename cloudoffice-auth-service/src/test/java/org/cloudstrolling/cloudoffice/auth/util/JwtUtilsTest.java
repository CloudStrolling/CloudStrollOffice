/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.SignatureException;
import org.cloudstrolling.cloudoffice.auth.config.RsaKeyConfig;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

/**
 * JwtUtils 工具类单元测试（RS256 双 Token）。
 *
 * <p>测试 RS256 签名算法的 Access Token / Refresh Token 签发、解析、
 * tokenType 校验、过期校验、签名指纹提取和签名错误处理。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("JwtUtils 工具类测试（RS256 双 Token）")
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class JwtUtilsTest {

    /** 测试用 Access Token 有效期（2 小时，单位秒） */
    private static final long ACCESS_TOKEN_EXPIRATION = 7200L;

    /** 测试用 Refresh Token 有效期（7 天，单位秒） */
    private static final long REFRESH_TOKEN_EXPIRATION = 604800L;

    /** 极短的有效期（1 纳秒），用于生成立即过期的 Token */
    private static final long IMMEDIATE_EXPIRATION = 0L;

    /** RSA 密钥对（用于 JwtUtils 验证通过） */
    private static KeyPair validKeyPair;

    /** 另一个 RSA 密钥对（用于签名错误场景） */
    private static KeyPair invalidKeyPair;

    @Mock
    private RsaKeyConfig rsaKeyConfig;

    /** JwtUtils 实例（正常有效期） */
    private JwtUtils jwtUtils;

    /** JwtUtils 实例（立即过期） */
    private JwtUtils expiredJwtUtils;

    /** 测试用 LoginUserDTO */
    private LoginUserDTO loginUser;

    /**
     * 在所有测试之前生成 RSA 密钥对。
     */
    @BeforeAll
    static void setUpOnce() throws NoSuchAlgorithmException {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        validKeyPair = generator.generateKeyPair();
        invalidKeyPair = generator.generateKeyPair();
    }

    /**
     * 每个测试方法前初始化 JwtUtils 实例。
     * 使用 Mockito 模拟 RsaKeyConfig，返回生成的 RSA 密钥对。
     */
    @BeforeEach
    void setUp() {
        when(rsaKeyConfig.getPrivateKey()).thenReturn(validKeyPair.getPrivate());
        when(rsaKeyConfig.getPublicKey()).thenReturn(validKeyPair.getPublic());

        jwtUtils = new JwtUtils(rsaKeyConfig, ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION);
        expiredJwtUtils = new JwtUtils(rsaKeyConfig, IMMEDIATE_EXPIRATION, IMMEDIATE_EXPIRATION);

        loginUser = LoginUserDTO.builder()
                .userId(1001L)
                .tenantId(10L)
                .userName("testUser")
                .clientType("WINDOWS")
                .roles(List.of("admin", "operator"))
                .permissions(List.of("system:user:list", "system:user:create"))
                .build();
    }

    // ==================== Access Token 测试 ====================

    @Test
    @DisplayName("generateAccessToken: 应生成 RS256 签名的三段式 JWT")
    void generateAccessToken_shouldReturnThreePartToken() {
        // When: 签发 Access Token
        String token = jwtUtils.generateAccessToken(loginUser);

        // Then: 应为三段式 JWT
        assertNotNull(token, "生成的令牌不应为空");
        String[] parts = token.split("\\.");
        assertEquals(3, parts.length, "JWT 应包含三段（header.payload.signature）");
    }

    @Test
    @DisplayName("generateAccessToken → parseAccessToken: 应正确解析所有声明")
    void generateAccessToken_andParse_shouldReturnCorrectClaims() {
        // Given: 签发 Access Token
        String token = jwtUtils.generateAccessToken(loginUser);

        // When: 解析 Access Token
        Claims claims = jwtUtils.parseAccessToken(token);

        // Then: 应正确解析出所有声明
        assertNotNull(claims, "Claims 不应为空");
        assertEquals("1001", claims.getSubject(), "sub 应等于用户 ID 的字符串形式");
        assertEquals(10L, claims.get("tenantId", Long.class), "tenantId 应正确");
        assertEquals("WINDOWS", claims.get("clientType", String.class), "clientType 应正确");
        assertEquals("access", claims.get("tokenType", String.class), "tokenType 应为 access");
        assertNotNull(claims.getIssuedAt(), "iat 不应为空");
        assertNotNull(claims.getExpiration(), "exp 不应为空");

        // 验证 roles 和 permissions
        @SuppressWarnings("unchecked")
        List<String> roles = claims.get("roles", List.class);
        assertTrue(roles.contains("admin"), "roles 应包含 admin");
        assertTrue(roles.contains("operator"), "roles 应包含 operator");

        @SuppressWarnings("unchecked")
        List<String> permissions = claims.get("permissions", List.class);
        assertTrue(permissions.contains("system:user:list"), "permissions 应包含 system:user:list");
        assertTrue(permissions.contains("system:user:create"), "permissions 应包含 system:user:create");
    }

    @Test
    @DisplayName("generateAccessToken: Access Token 有效期应为 2 小时")
    void generateAccessToken_shouldHaveTwoHourExpiration() {
        // Given: 签发 Access Token
        String token = jwtUtils.generateAccessToken(loginUser);

        // When: 解析 Claims
        Claims claims = jwtUtils.parseAccessToken(token);
        Date now = new Date();
        Date exp = claims.getExpiration();

        // Then: 过期时间应在当前时间之后约 2 小时（允许 5 秒偏差）
        long expectedExp = now.getTime() + ACCESS_TOKEN_EXPIRATION * 1000L;
        long actualExp = exp.getTime();
        assertTrue(Math.abs(actualExp - expectedExp) < 5000,
                "过期时间与预期相差应小于 5 秒，实际差值: " + Math.abs(actualExp - expectedExp) + "ms");
    }

    // ==================== Refresh Token 测试 ====================

    @Test
    @DisplayName("generateRefreshToken: 应生成 RS256 签名的三段式 JWT")
    void generateRefreshToken_shouldReturnThreePartToken() {
        // When: 签发 Refresh Token
        String token = jwtUtils.generateRefreshToken(loginUser);

        // Then: 应为三段式 JWT
        assertNotNull(token, "生成的令牌不应为空");
        String[] parts = token.split("\\.");
        assertEquals(3, parts.length, "JWT 应包含三段（header.payload.signature）");
    }

    @Test
    @DisplayName("generateRefreshToken → parseRefreshToken: 应正确解析所有声明")
    void generateRefreshToken_andParse_shouldReturnCorrectClaims() {
        // Given: 签发 Refresh Token
        String token = jwtUtils.generateRefreshToken(loginUser);

        // When: 解析 Refresh Token
        Claims claims = jwtUtils.parseRefreshToken(token);

        // Then: 应正确解析出所有声明
        assertNotNull(claims, "Claims 不应为空");
        assertEquals("1001", claims.getSubject(), "sub 应等于用户 ID 的字符串形式");
        assertEquals("refresh", claims.get("tokenType", String.class), "tokenType 应为 refresh");
        assertNotNull(claims.get("tokenVersion", Long.class), "tokenVersion 不应为空");
        assertNotNull(claims.getIssuedAt(), "iat 不应为空");
        assertNotNull(claims.getExpiration(), "exp 不应为空");

        // Refresh Token 也应包含 tenantId 和 clientType（用于校验上下文）
        assertEquals(10L, claims.get("tenantId", Long.class), "tenantId 应正确");
        assertEquals("WINDOWS", claims.get("clientType", String.class), "clientType 应正确");
    }

    @Test
    @DisplayName("generateRefreshToken: Refresh Token 有效期应为 7 天")
    void generateRefreshToken_shouldHaveSevenDayExpiration() {
        // Given: 签发 Refresh Token
        String token = jwtUtils.generateRefreshToken(loginUser);

        // When: 解析 Claims
        Claims claims = jwtUtils.parseRefreshToken(token);
        Date now = new Date();
        Date exp = claims.getExpiration();

        // Then: 过期时间应在当前时间之后约 7 天（允许 5 秒偏差）
        long expectedExp = now.getTime() + REFRESH_TOKEN_EXPIRATION * 1000L;
        long actualExp = exp.getTime();
        assertTrue(Math.abs(actualExp - expectedExp) < 5000,
                "过期时间与预期相差应小于 5 秒，实际差值: " + Math.abs(actualExp - expectedExp) + "ms");
    }

    @Test
    @DisplayName("generateRefreshToken: 每次生成的 tokenVersion 应不同")
    void generateRefreshToken_shouldHaveDifferentTokenVersion() {
        // When: 连续签发两个 Refresh Token
        String token1 = jwtUtils.generateRefreshToken(loginUser);
        String token2 = jwtUtils.generateRefreshToken(loginUser);

        // Then: 两个 token 的 tokenVersion 应不同
        Claims claims1 = jwtUtils.parseRefreshToken(token1);
        Claims claims2 = jwtUtils.parseRefreshToken(token2);
        Long version1 = claims1.get("tokenVersion", Long.class);
        Long version2 = claims2.get("tokenVersion", Long.class);
        assertNotNull(version1, "tokenVersion 不应为 null");
        assertNotNull(version2, "tokenVersion 不应为 null");
        assertNotEquals(version1, version2, "每次生成的 tokenVersion 应不同");
    }

    // ==================== tokenType 校验测试 ====================

    @Test
    @DisplayName("parseAccessToken: 使用 Refresh Token 解析应抛出异常")
    void parseAccessToken_withRefreshToken_shouldThrowException() {
        // Given: 签发 Refresh Token
        String refreshToken = jwtUtils.generateRefreshToken(loginUser);

        // When/Then: 使用 parseAccessToken 解析 Refresh Token 应抛出异常
        assertThrows(JwtException.class, () -> jwtUtils.parseAccessToken(refreshToken),
                "使用 Access Token 解析方法解析 Refresh Token 应抛出 JwtException");
    }

    @Test
    @DisplayName("parseRefreshToken: 使用 Access Token 解析应抛出异常")
    void parseRefreshToken_withAccessToken_shouldThrowException() {
        // Given: 签发 Access Token
        String accessToken = jwtUtils.generateAccessToken(loginUser);

        // When/Then: 使用 parseRefreshToken 解析 Access Token 应抛出异常
        assertThrows(JwtException.class, () -> jwtUtils.parseRefreshToken(accessToken),
                "使用 Refresh Token 解析方法解析 Access Token 应抛出 JwtException");
    }

    // ==================== Token 过期测试 ====================

    @Test
    @DisplayName("parseAccessToken: 过期 Token 应抛出 ExpiredJwtException")
    void parseAccessToken_withExpiredToken_shouldThrowException() {
        // Given: 使用立即过期的配置签发 Access Token
        String expiredToken = expiredJwtUtils.generateAccessToken(loginUser);

        // When/Then: 解析过期 Token 应抛出 ExpiredJwtException
        assertThrows(ExpiredJwtException.class, () -> jwtUtils.parseAccessToken(expiredToken),
                "过期 Token 应抛出 ExpiredJwtException");
    }

    @Test
    @DisplayName("parseRefreshToken: 过期 Token 应抛出 ExpiredJwtException")
    void parseRefreshToken_withExpiredToken_shouldThrowException() {
        // Given: 使用立即过期的配置签发 Refresh Token
        String expiredToken = expiredJwtUtils.generateRefreshToken(loginUser);

        // When/Then: 解析过期 Token 应抛出 ExpiredJwtException
        assertThrows(ExpiredJwtException.class, () -> jwtUtils.parseRefreshToken(expiredToken),
                "过期 Token 应抛出 ExpiredJwtException");
    }

    // ==================== 签名指纹测试 ====================

    @Test
    @DisplayName("getTokenSignature: 相同 Token 应返回相同签名指纹")
    void getTokenSignature_shouldReturnSameDigestForSameToken() {
        // Given: 签发一个 Token
        String token = jwtUtils.generateAccessToken(loginUser);

        // When: 两次获取签名指纹
        String signature1 = jwtUtils.getTokenSignature(token);
        String signature2 = jwtUtils.getTokenSignature(token);

        // Then: 两次结果应相同
        assertNotNull(signature1, "签名指纹不应为空");
        assertEquals(signature1, signature2, "相同 Token 的签名指纹应相同");
    }

    @Test
    @DisplayName("getTokenSignature: 不同 Token 应返回不同签名指纹")
    void getTokenSignature_shouldReturnDifferentDigestForDifferentTokens() {
        // Given: 签发两个不同的 Token
        String token1 = jwtUtils.generateAccessToken(loginUser);
        String token2 = jwtUtils.generateRefreshToken(loginUser);

        // When: 获取签名指纹
        String signature1 = jwtUtils.getTokenSignature(token1);
        String signature2 = jwtUtils.getTokenSignature(token2);

        // Then: 不同 Token 的签名指纹应不同
        assertNotEquals(signature1, signature2, "不同 Token 的签名指纹应不同");
    }

    @Test
    @DisplayName("getTokenSignature: 返回的指纹应为 64 字符的十六进制字符串（SHA-256）")
    void getTokenSignature_shouldReturn64CharHexString() {
        // Given: 签发一个 Token
        String token = jwtUtils.generateAccessToken(loginUser);

        // When: 获取签名指纹
        String signature = jwtUtils.getTokenSignature(token);

        // Then: 应为 64 字符的十六进制字符串（SHA-256 摘要）
        assertNotNull(signature, "签名指纹不应为空");
        assertEquals(64, signature.length(), "SHA-256 指纹应为 64 个十六进制字符");
        assertTrue(signature.matches("[0-9a-f]{64}"), "签名指纹应为 64 位小写十六进制字符串");
    }

    // ==================== 签名错误测试 ====================

    @Test
    @DisplayName("parseAccessToken: 使用不同密钥签名的 Token 应抛出 SignatureException")
    void parseAccessToken_withWrongSignature_shouldThrowException() {
        // Given: 使用不同私钥签名的 Access Token
        String fakeToken = Jwts.builder()
                .subject("1001")
                .claim("tokenType", "access")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 3600_000))
                .signWith(invalidKeyPair.getPrivate())
                .compact();

        // When/Then: 用 JwtUtils 的公钥解析应抛出 SignatureException
        assertThrows(SignatureException.class, () -> jwtUtils.parseAccessToken(fakeToken),
                "签名不匹配的 Token 应抛出 SignatureException");
    }

    @Test
    @DisplayName("parseRefreshToken: 格式错误的 Token 应抛出异常")
    void parseRefreshToken_withMalformedToken_shouldThrowException() {
        // Given: 格式错误的 Token
        String malformedToken = "not.a.valid.jwt";

        // When/Then: 解析应抛出异常
        assertThrows(JwtException.class, () -> jwtUtils.parseRefreshToken(malformedToken),
                "格式错误的 Token 应抛出异常");
    }

    @Test
    @DisplayName("parseAccessToken: null Token 应抛出异常")
    void parseAccessToken_withNullToken_shouldThrowException() {
        // When/Then: 解析 null 应抛出异常（JJWT 内部抛出 IllegalArgumentException）
        assertThrows(IllegalArgumentException.class, () -> jwtUtils.parseAccessToken(null),
                "null Token 应抛出 IllegalArgumentException");
    }
}
