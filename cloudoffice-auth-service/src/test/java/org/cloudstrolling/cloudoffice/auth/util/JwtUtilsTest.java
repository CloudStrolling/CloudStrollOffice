/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.*;

/**
 * JwtUtils 工具类单元测试。
 *
 * <p>测试 JWT 令牌的生成、解析、验证以及用户信息提取功能。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("JwtUtils 工具类测试")
class JwtUtilsTest {

    /** 测试用 JWT 密钥（32 字符以上，符合 HS256 要求） */
    private static final String TEST_SECRET = "testSecretKeyThatIsLongEnoughForHS256Algorithm1234567890";

    /** 测试用过期时间（1 小时） */
    private static final long TEST_EXPIRATION = 3600000L;

    /** 测试用签名算法 */
    private static final String TEST_ALGORITHM = "HS256";

    /** JwtUtils 实例 */
    private JwtUtils jwtUtils;

    /**
     * 每个测试方法前初始化 JwtUtils 实例。
     */
    @BeforeEach
    void setUp() {
        // 手动构建 JwtUtils 实例，避免依赖 Spring 上下文和 Nacos 配置
        jwtUtils = new JwtUtils(TEST_SECRET, TEST_EXPIRATION, TEST_ALGORITHM);
        jwtUtils.init();
    }

    @Test
    @DisplayName("generateToken: 应返回三段式 JWT 字符串，包含两个点分隔符")
    void generateToken_shouldReturnThreePartToken_whenCalledWithValidParams() {
        // Given: 用户 ID 和用户名
        String userId = "U001";
        String userName = "testUser";

        // When: 生成令牌
        String token = jwtUtils.generateToken(userId, userName);

        // Then: 令牌应为三段式 JWT（header.payload.signature）
        assertNotNull(token, "生成的令牌不应为空");
        String[] parts = token.split("\\.");
        assertEquals(3, parts.length, "JWT 应包含三段（header.payload.signature）");
    }

    @Test
    @DisplayName("generateToken: 不同用户生成不同令牌")
    void generateToken_shouldReturnDifferentTokens_whenCalledWithDifferentUsers() {
        // Given: 两个不同用户
        // When: 分别生成令牌
        String token1 = jwtUtils.generateToken("U001", "userA");
        String token2 = jwtUtils.generateToken("U002", "userB");

        // Then: 令牌应不同
        assertNotEquals(token1, token2, "不同用户的令牌应不同");
    }

    @Test
    @DisplayName("parseToken: 应正确解析出 userId 和 userName")
    void parseToken_shouldReturnCorrectClaims_whenTokenIsValid() {
        // Given: 生成有效令牌
        String userId = "U001";
        String userName = "testUser";
        String token = jwtUtils.generateToken(userId, userName);

        // When: 解析令牌
        Claims claims = jwtUtils.parseToken(token);

        // Then: 应正确解析出用户信息
        assertNotNull(claims, "Claims 不应为空");
        assertEquals(userId, claims.getSubject(), "subject 应等于 userId");
        assertEquals(userName, claims.get("userName", String.class), "userName 声明应等于传入的用户名");
    }

    @Test
    @DisplayName("validateToken: 有效令牌应返回 true")
    void validateToken_shouldReturnTrue_whenTokenIsValid() {
        // Given: 生成有效令牌
        String token = jwtUtils.generateToken("U001", "testUser");

        // When: 验证令牌
        boolean isValid = jwtUtils.validateToken(token);

        // Then: 应为有效
        assertTrue(isValid, "有效令牌应通过验证");
    }

    @Test
    @DisplayName("validateToken: 签名不匹配的无效令牌应返回 false")
    void validateToken_shouldReturnFalse_whenTokenHasInvalidSignature() {
        // Given: 使用不同密钥生成的令牌
        String token = jwtUtils.generateToken("U001", "testUser");

        // When: 修改令牌的签名部分（模拟签名篡改）
        String[] parts = token.split("\\.");
        String tamperedToken = parts[0] + "." + parts[1] + ".invalid_signature";

        // Then: 签名验证应失败
        boolean isValid = jwtUtils.validateToken(tamperedToken);
        assertFalse(isValid, "签名篡改的令牌应验证失败");
    }

    @Test
    @DisplayName("validateToken: 空令牌应返回 false")
    void validateToken_shouldReturnFalse_whenTokenIsNull() {
        // When: 验证 null 令牌
        boolean isValid = jwtUtils.validateToken(null);

        // Then: 应为无效
        assertFalse(isValid, "空令牌应验证失败");
    }

    @Test
    @DisplayName("validateToken: 格式错误的令牌应返回 false")
    void validateToken_shouldReturnFalse_whenTokenIsMalformed() {
        // Given: 格式错误的令牌
        String malformedToken = "not.a.jwt.token.format";

        // When: 验证格式错误的令牌
        boolean isValid = jwtUtils.validateToken(malformedToken);

        // Then: 应为无效
        assertFalse(isValid, "格式错误的令牌应验证失败");
    }

    @Test
    @DisplayName("getUserIdFromToken: 应返回正确的 userId")
    void getUserIdFromToken_shouldReturnCorrectUserId_whenTokenIsValid() {
        // Given: 生成令牌
        String userId = "U001";
        String token = jwtUtils.generateToken(userId, "testUser");

        // When: 从令牌中提取 userId
        String extractedUserId = jwtUtils.getUserIdFromToken(token);

        // Then: 应返回正确的 userId
        assertEquals(userId, extractedUserId, "提取的 userId 应与生成时一致");
    }

    @Test
    @DisplayName("getUserNameFromToken: 应返回正确的 userName")
    void getUserNameFromToken_shouldReturnCorrectUserName_whenTokenIsValid() {
        // Given: 生成令牌
        String userName = "testUser";
        String token = jwtUtils.generateToken("U001", userName);

        // When: 从令牌中提取用户名
        String extractedUserName = jwtUtils.getUserNameFromToken(token);

        // Then: 应返回正确的用户名
        assertEquals(userName, extractedUserName, "提取的用户名应与生成时一致");
    }

    @Test
    @DisplayName("init: 密钥长度不足 32 字符时应抛出异常")
    void init_shouldThrowException_whenSecretIsTooShort() {
        // Given: 密钥长度不足 32 字符
        String shortSecret = "short";

        // When/Then: 初始化时应抛出 IllegalArgumentException
        JwtUtils invalidJwtUtils = new JwtUtils(shortSecret, TEST_EXPIRATION, TEST_ALGORITHM);
        assertThrows(IllegalArgumentException.class, invalidJwtUtils::init,
                "密钥长度不足 32 字符时应抛出 IllegalArgumentException");
    }

    @Test
    @DisplayName("init: 密钥为 null 时应抛出异常")
    void init_shouldThrowException_whenSecretIsNull() {
        // Given: 密钥为 null
        // When/Then: 初始化时应抛出 IllegalArgumentException
        JwtUtils invalidJwtUtils = new JwtUtils(null, TEST_EXPIRATION, TEST_ALGORITHM);
        assertThrows(IllegalArgumentException.class, invalidJwtUtils::init,
                "密钥为 null 时应抛出 IllegalArgumentException");
    }

    @Test
    @DisplayName("generateToken: 生成包含 iat 和 exp 声明的令牌")
    void generateToken_shouldIncludeIssuedAtAndExpiration_whenTokenGenerated() throws Exception {
        // Given: 生成令牌
        String token = jwtUtils.generateToken("U001", "testUser");
        jwtUtils.parseToken(token); // 验证可正常解析

        // When: 通过反射修改过期时间为 0，使令牌立即过期
        Field expirationField = JwtUtils.class.getDeclaredField("expiration");
        expirationField.setAccessible(true);
        expirationField.set(jwtUtils, -1L); // 负值使令牌立即过期

        String expiredToken = jwtUtils.generateToken("U001", "testUser");

        // Then: 解析过期令牌应抛出 ExpiredJwtException
        assertThrows(ExpiredJwtException.class, () -> jwtUtils.parseToken(expiredToken),
                "过期令牌应抛出 ExpiredJwtException");
    }
}
