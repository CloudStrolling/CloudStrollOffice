/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;

/**
 * 测试 RSA 公钥提供工具类。
 *
 * <p>用于在测试类中生成测试用的 RSA 2048 位公钥，避免因 {@link
 * org.cloudstrolling.cloudoffice.gateway.config.RsaKeyConfig RsaKeyConfig}
 * 在 {@code @SpringBootTest} 全量加载时因缺少公钥配置而启动失败。</p>
 *
 * <p>使用方式：在测试类中添加静态初始化块：</p>
 * <pre>{@code
 * static { TestRsaKeyProvider.initialize(); }
 * }</pre>
 *
 * <p>然后在 {@code @SpringBootTest(properties = ...)} 中添加：</p>
 * <pre>{@code
 * "auth.rsa.public-key=${test.rsa.public-key}"
 * }</pre>
 *
 * @author CloudStroll Office
 */
public final class TestRsaKeyProvider {

    private static volatile boolean initialized = false;

    private TestRsaKeyProvider() {
        // 工具类，禁止实例化
    }

    /**
     * 初始化测试 RSA 公钥系统属性。
     *
     * <p>生成一个 RSA 2048 位密钥对，将公钥的 Base64 编码设置为系统属性
     * {@code test.rsa.public-key}，供测试类通过 {@code @SpringBootTest(properties = ...)}
     * 引用。</p>
     *
     * <p>此方法是幂等的：仅在首次调用时生成密钥，后续调用直接返回。</p>
     */
    public static void initialize() {
        if (initialized) {
            return;
        }
        synchronized (TestRsaKeyProvider.class) {
            if (initialized) {
                return;
            }
            try {
                KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
                generator.initialize(2048);
                KeyPair keyPair = generator.generateKeyPair();
                String base64Key = Base64.getEncoder().encodeToString(
                        keyPair.getPublic().getEncoded());
                System.setProperty("test.rsa.public-key", base64Key);
                initialized = true;
            } catch (Exception e) {
                throw new RuntimeException("无法生成测试 RSA 密钥对", e);
            }
        }
    }
}
