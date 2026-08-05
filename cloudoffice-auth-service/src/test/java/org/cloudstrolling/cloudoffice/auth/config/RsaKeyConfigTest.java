/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.config;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RsaKeyConfig 配置类单元测试。
 *
 * @author CloudStroll Office
 */
@DisplayName("RsaKeyConfig RSA 密钥配置测试")
class RsaKeyConfigTest {

    /** 测试用 RSA 2048 位私钥（Base64 编码，PKCS8 格式） */
    private static String testPrivateKeyBase64;

    /** 测试用 RSA 2048 位公钥（Base64 编码，X509 格式） */
    private static String testPublicKeyBase64;

    /**
     * 在所有测试之前生成测试用的 RSA 2048 位密钥对。
     */
    @BeforeAll
    static void setUp() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            KeyPair keyPair = keyPairGenerator.generateKeyPair();

            testPrivateKeyBase64 = Base64.getEncoder().encodeToString(keyPair.getPrivate().getEncoded());
            testPublicKeyBase64 = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate test RSA key pair", e);
        }
    }

    @Test
    @DisplayName("init_shouldLoadKeysSuccessfully_whenValidBase64KeysProvided")
    void init_shouldLoadKeysSuccessfully_whenValidBase64KeysProvided() {
        // Given: RsaKeyConfig 实例，设置有效的公私钥 Base64 编码
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);

        // When: 调用 init() 方法初始化
        config.init();

        // Then: 公私钥加载成功且正确
        PrivateKey privateKey = config.getPrivateKey();
        PublicKey publicKey = config.getPublicKey();

        assertNotNull(privateKey, "私钥不应为空");
        assertNotNull(publicKey, "公钥不应为空");
        assertEquals("RSA", privateKey.getAlgorithm(), "私钥算法应为 RSA");
        assertEquals("RSA", publicKey.getAlgorithm(), "公钥算法应为 RSA");
        assertEquals(2048, ((java.security.interfaces.RSAKey) privateKey).getModulus().bitLength(),
                "密钥位数应为 2048 位");
    }

    @Test
    @DisplayName("getPrivateKey_shouldReturnValidPrivateKey_whenLoadedSuccessfully")
    void getPrivateKey_shouldReturnValidPrivateKey_whenLoadedSuccessfully() {
        // Given: RsaKeyConfig 已成功加载密钥
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);
        config.init();

        // When: 获取私钥
        PrivateKey privateKey = config.getPrivateKey();

        // Then: 私钥不为空且为 RSA 算法
        assertNotNull(privateKey, "getPrivateKey() 不应返回 null");
        assertInstanceOf(PrivateKey.class, privateKey, "返回值应为 PrivateKey 类型");
        assertEquals("RSA", privateKey.getAlgorithm());
    }

    @Test
    @DisplayName("getPublicKey_shouldReturnValidPublicKey_whenLoadedSuccessfully")
    void getPublicKey_shouldReturnValidPublicKey_whenLoadedSuccessfully() {
        // Given: RsaKeyConfig 已成功加载密钥
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);
        config.init();

        // When: 获取公钥
        PublicKey publicKey = config.getPublicKey();

        // Then: 公钥不为空且为 RSA 算法
        assertNotNull(publicKey, "getPublicKey() 不应返回 null");
        assertInstanceOf(PublicKey.class, publicKey, "返回值应为 PublicKey 类型");
        assertEquals("RSA", publicKey.getAlgorithm());
    }

    @Test
    @DisplayName("init_shouldThrowException_whenPrivateKeyIsBlank")
    void init_shouldThrowException_whenPrivateKeyIsBlank() {
        // Given: RsaKeyConfig 实例，私钥为空
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", "  ");
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException 并提示私钥未配置
        assertTrue(exception.getMessage().contains("private key"),
                "异常信息应包含 'private key'");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenPublicKeyIsBlank")
    void init_shouldThrowException_whenPublicKeyIsBlank() {
        // Given: RsaKeyConfig 实例，公钥为空
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyBase64", "  ");

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException 并提示公钥未配置
        assertTrue(exception.getMessage().contains("public key"),
                "异常信息应包含 'public key'");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenBothKeysAreNull")
    void init_shouldThrowException_whenBothKeysAreNull() {
        // Given: RsaKeyConfig 实例，公私钥均为 null
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", null);
        ReflectionTestUtils.setField(config, "publicKeyBase64", null);

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException（优先检查私钥）
        assertNotNull(exception, "应抛出 IllegalStateException");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenPrivateKeyIsNull")
    void init_shouldThrowException_whenPrivateKeyIsNull() {
        // Given: RsaKeyConfig 实例，私钥为 null
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", null);
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException 并提示私钥未配置
        assertTrue(exception.getMessage().contains("private key"),
                "异常信息应包含 'private key'");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenBase64DecodeFails")
    void init_shouldThrowException_whenBase64DecodeFails() {
        // Given: RsaKeyConfig 实例，私钥为无效的 Base64 编码
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", "invalid-base64!!!");
        ReflectionTestUtils.setField(config, "publicKeyBase64", testPublicKeyBase64);

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException 并提示 Base64 解码失败
        assertTrue(exception.getMessage().contains("Base64"),
                "异常信息应包含 'Base64'");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenPublicKeyBase64DecodeFails")
    void init_shouldThrowException_whenPublicKeyBase64DecodeFails() {
        // Given: RsaKeyConfig 实例，公钥为无效的 Base64 编码
        RsaKeyConfig config = new RsaKeyConfig();
        ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
        ReflectionTestUtils.setField(config, "publicKeyBase64", "not-valid-base64!!!");

        // When: 调用 init() 方法
        IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

        // Then: 抛出 IllegalStateException 并提示 Base64 解码失败
        assertTrue(exception.getMessage().contains("Base64"),
                "异常信息应包含 'Base64'");
    }

    @Test
    @DisplayName("init_shouldThrowException_whenKeysDoNotMatch")
    void init_shouldThrowException_whenKeysDoNotMatch() {
        // Given: RsaKeyConfig 实例，使用不匹配的密钥对（私钥和公钥来自不同的密钥对）
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA");
            keyPairGenerator.initialize(2048);
            KeyPair differentKeyPair = keyPairGenerator.generateKeyPair();

            RsaKeyConfig config = new RsaKeyConfig();
            ReflectionTestUtils.setField(config, "privateKeyBase64", testPrivateKeyBase64);
            ReflectionTestUtils.setField(config, "publicKeyBase64",
                    Base64.getEncoder().encodeToString(differentKeyPair.getPublic().getEncoded()));

            // When: 调用 init() 方法
            IllegalStateException exception = assertThrows(IllegalStateException.class, config::init);

            // Then: 抛出 IllegalStateException 并提示密钥对不匹配
            assertTrue(exception.getMessage().contains("key pair"),
                    "异常信息应包含 'key pair'");
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate different RSA key pair for test", e);
        }
    }
}
