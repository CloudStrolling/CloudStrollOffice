/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

/**
 * {@link RsaKeyConfig} 配置类单元测试。
 *
 * <p>覆盖以下场景：</p>
 * <ul>
 *   <li>使用测试公钥验证加载成功，{@link RsaKeyConfig#getPublicKey()} 返回有效 PublicKey</li>
 *   <li>公钥配置为空时抛出 {@link IllegalArgumentException}</li>
 *   <li>公钥 Base64 编码无效时抛出 {@link IllegalArgumentException}</li>
 * </ul>
 *
 * @author CloudStroll Office
 */
@DisplayName("RsaKeyConfig 配置类单元测试")
class RsaKeyConfigTest {

    /** 测试用 RSA 2048 位公钥（Base64 编码）。 */
    private static String testPublicKeyBase64;

    /**
     * 在所有测试运行前生成一个临时 RSA 2048 位密钥对作为测试公钥。
     */
    @BeforeAll
    static void setup() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        KeyPair keyPair = generator.generateKeyPair();
        testPublicKeyBase64 = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());
    }

    @Test
    @DisplayName("使用有效公钥配置，getPublicKey() 应返回有效的 RSA PublicKey 对象")
    void getPublicKey_shouldReturnValidRsaPublicKey_whenKeyIsConfigured() {
        // Given: 使用测试生成的 RSA 2048 位公钥配置 RsaKeyConfig
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", testPublicKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyPath", "");

        // When: 执行初始化
        config.init();

        // Then: 应返回有效的 RSA PublicKey 对象
        PublicKey publicKey = config.getPublicKey();
        assertNotNull(publicKey, "RSA PublicKey 不应为 null");
        assertEquals("RSA", publicKey.getAlgorithm(), "算法应为 RSA");
        assertTrue(publicKey.getEncoded().length > 0, "公钥编码字节数组不应为空");
    }

    @Test
    @DisplayName("公钥配置为空时应抛出 IllegalArgumentException")
    void init_shouldThrowException_whenPublicKeyIsEmpty() {
        // Given: RSA 公钥和公钥路径均为空字符串
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", "");
        ReflectionTestUtils.setField(config, "publicKeyPath", "");

        // When: 调用 init()
        // Then: 应抛出 IllegalArgumentException，提示公钥未配置
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                config::init,
                "公钥为空时应抛出 IllegalArgumentException"
        );
        assertTrue(exception.getMessage().contains("未配置"),
                "异常消息应包含 '未配置' 提示信息，实际消息：" + exception.getMessage());
    }

    @Test
    @DisplayName("公钥配置为 null 时应抛出 IllegalArgumentException")
    void init_shouldThrowException_whenPublicKeyIsNull() {
        // Given: RSA 公钥和公钥路径均为 null
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", null);
        ReflectionTestUtils.setField(config, "publicKeyPath", null);

        // When: 调用 init()
        // Then: 应抛出 IllegalArgumentException，提示公钥未配置
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                config::init,
                "公钥为 null 时应抛出 IllegalArgumentException"
        );
        assertTrue(exception.getMessage().contains("未配置"),
                "异常消息应包含 '未配置' 提示信息，实际消息：" + exception.getMessage());
    }

    @Test
    @DisplayName("无效 Base64 编码时应抛出 IllegalArgumentException")
    void init_shouldThrowException_whenBase64IsInvalid() {
        // Given: RSA 公钥配置为无效的 Base64 字符串
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", "not-a-valid-base64!!!");
        ReflectionTestUtils.setField(config, "publicKeyPath", "");

        // When: 调用 init()
        // Then: 应抛出 IllegalArgumentException，提示 Base64 解码失败
        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                config::init,
                "无效 Base64 时应抛出 IllegalArgumentException"
        );
        assertTrue(exception.getMessage().contains("Base64"),
                "异常消息应包含 'Base64' 提示信息，实际消息：" + exception.getMessage());
    }

    @Test
    @DisplayName("有效 Base64 但非 RSA 公钥内容时应抛出异常")
    void init_shouldThrowException_whenBase64IsNotRsaKey() {
        // Given: 公钥配置为有效 Base64 但内容不是标准公钥格式
        String notRsaKey = Base64.getEncoder().encodeToString("not-a-rsa-key-data".getBytes());
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", notRsaKey);
        ReflectionTestUtils.setField(config, "publicKeyPath", "");

        // When: 调用 init()
        // Then: 应抛出 IllegalArgumentException
        assertThrows(
                IllegalArgumentException.class,
                config::init,
                "非 RSA 公钥内容时应抛出 IllegalArgumentException"
        );
    }

    @Test
    @DisplayName("PEM 文件路径为空且公钥也为空时应抛出异常")
    void init_shouldThrowException_whenBothKeyAndPathAreEmpty() {
        // Given: 公钥为空但 PEM 文件路径也为空
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "publicKey", "");
        ReflectionTestUtils.setField(config, "publicKeyPath", "");

        // When: 调用 init()
        // Then: 应抛出 IllegalArgumentException
        assertThrows(
                IllegalArgumentException.class,
                config::init,
                "公钥和 PEM 路径均为空时应抛出 IllegalArgumentException"
        );
    }
}
