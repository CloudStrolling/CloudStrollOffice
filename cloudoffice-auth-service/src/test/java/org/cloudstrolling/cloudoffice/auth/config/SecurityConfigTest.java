/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;

/**
 * SecurityConfig 安全配置测试。
 *
 * <p>测试密码编码器的正确行为。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("SecurityConfig 测试")
class SecurityConfigTest {

    private SecurityConfig securityConfig;

    @BeforeEach
    void setUp() {
        // 直接构造 SecurityConfig 实例，无需 Spring 上下文
        securityConfig = new SecurityConfig();
    }

    @Test
    @DisplayName("passwordEncoder: 应返回 BCryptPasswordEncoder 实例")
    void passwordEncoder_shouldReturnBCryptPasswordEncoderInstance_whenCalled() {
        // When: 调用 passwordEncoder 方法
        BCryptPasswordEncoder encoder = securityConfig.passwordEncoder();

        // Then: 应返回非空的 BCryptPasswordEncoder 实例
        assertNotNull(encoder, "passwordEncoder 不应返回 null");
        assertInstanceOf(BCryptPasswordEncoder.class, encoder,
                "passwordEncoder 应返回 BCryptPasswordEncoder 实例");
    }

    @Test
    @DisplayName("BCrypt 编码: 正确密码应匹配编码后的结果")
    void bcryptEncoder_shouldMatchEncodedPassword_whenPasswordIsCorrect() {
        // Given: BCryptPasswordEncoder 实例和原始密码
        BCryptPasswordEncoder encoder = securityConfig.passwordEncoder();
        String rawPassword = "testPassword123!";

        // When: 对密码进行编码
        String encodedPassword = encoder.encode(rawPassword);

        // Then: 编码后的密码应与原始密码不同，但可以匹配
        assertNotNull(encodedPassword, "编码后的密码不应为空");
        assertNotEquals(rawPassword, encodedPassword, "编码后的密码不应与原始密码相同");
        assertTrue(encoder.matches(rawPassword, encodedPassword),
                "正确密码应匹配编码后的密码");
    }

    @Test
    @DisplayName("BCrypt 编码: 错误密码不应匹配编码后的结果")
    void bcryptEncoder_shouldNotMatch_whenPasswordIsWrong() {
        // Given: BCryptPasswordEncoder 实例和原始密码
        BCryptPasswordEncoder encoder = securityConfig.passwordEncoder();
        String rawPassword = "testPassword123!";

        // When: 对密码进行编码
        String encodedPassword = encoder.encode(rawPassword);

        // Then: 错误密码不应匹配
        assertFalse(encoder.matches("wrongPassword", encodedPassword),
                "错误密码不应匹配编码后的密码");
        assertFalse(encoder.matches("", encodedPassword),
                "空字符串不应匹配编码后的密码");
    }

    @Test
    @DisplayName("BCrypt 编码: 每次编码结果应不同（随机盐值）")
    void bcryptEncoder_shouldProduceDifferentEncodings_whenCalledMultipleTimes() {
        // Given: BCryptPasswordEncoder 实例和相同的原始密码
        BCryptPasswordEncoder encoder = securityConfig.passwordEncoder();
        String rawPassword = "samePassword";

        // When: 对同一密码编码两次
        String encoded1 = encoder.encode(rawPassword);
        String encoded2 = encoder.encode(rawPassword);

        // Then: 每次编码结果应不同（因为 BCrypt 使用随机盐值）
        assertNotEquals(encoded1, encoded2,
                "BCrypt 使用随机盐值，每次编码结果应不同");

        // 但两次编码的密码都能通过匹配验证
        assertTrue(encoder.matches(rawPassword, encoded1));
        assertTrue(encoder.matches(rawPassword, encoded2));
    }
}
