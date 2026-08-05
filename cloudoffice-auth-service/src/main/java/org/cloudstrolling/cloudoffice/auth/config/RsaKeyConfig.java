/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * RSA 密钥配置类。
 *
 * <p>从配置文件或环境变量中加载 RSA 2048 位密钥对（Base64 编码），
 * 私钥用于签发 JWT，公钥用于验证 JWT 签名。</p>
 *
 * <p>密钥加载优先级：环境变量 → 配置文件 Base64 → PEM 文件路径</p>
 *
 * @author CloudStroll Office
 */
@Configuration
@Slf4j
public class RsaKeyConfig {

    /** RSA 私钥（Base64 编码），配置项：jwt.rsa.private-key */
    @Value("${jwt.rsa.private-key:}")
    private String privateKeyBase64;

    /** RSA 公钥（Base64 编码），配置项：jwt.rsa.public-key */
    @Value("${jwt.rsa.public-key:}")
    private String publicKeyBase64;

    /** RSA 私钥对象 */
    private PrivateKey privateKey;

    /** RSA 公钥对象 */
    private PublicKey publicKey;

    /**
     * 初始化加载并校验 RSA 密钥对。
     *
     * <p>执行以下校验：</p>
     * <ul>
     *   <li>私钥和公钥 Base64 编码不能为空</li>
     *   <li>Base64 解码必须成功</li>
     *   <li>私钥必须使用 PKCS8 格式</li>
     *   <li>公钥必须使用 X509 格式</li>
     *   <li>密钥强度应不低于 2048 位</li>
     *   <li>密钥对必须匹配（私钥签名 + 公钥验签）</li>
     * </ul>
     */
    @PostConstruct
    public void init() {
        // 1. 校验密钥配置不为空
        if (privateKeyBase64 == null || privateKeyBase64.isBlank()) {
            log.error("RSA 私钥未配置（jwt.rsa.private-key），服务启动拒绝");
            throw new IllegalStateException("RSA private key must be configured (jwt.rsa.private-key)");
        }
        if (publicKeyBase64 == null || publicKeyBase64.isBlank()) {
            log.error("RSA 公钥未配置（jwt.rsa.public-key），服务启动拒绝");
            throw new IllegalStateException("RSA public key must be configured (jwt.rsa.public-key)");
        }

        try {
            // 2. Base64 解码
            byte[] privateKeyBytes = Base64.getDecoder().decode(privateKeyBase64.trim());
            byte[] publicKeyBytes = Base64.getDecoder().decode(publicKeyBase64.trim());
            log.info("RSA 密钥 Base64 解码成功，私钥长度: {} 字节，公钥长度: {} 字节",
                    privateKeyBytes.length, publicKeyBytes.length);

            // 3. 加载私钥（PKCS8EncodedKeySpec）
            PKCS8EncodedKeySpec privateKeySpec = new PKCS8EncodedKeySpec(privateKeyBytes);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            this.privateKey = keyFactory.generatePrivate(privateKeySpec);
            log.info("RSA 私钥加载成功");

            // 4. 加载公钥（X509EncodedKeySpec）
            X509EncodedKeySpec publicKeySpec = new X509EncodedKeySpec(publicKeyBytes);
            this.publicKey = keyFactory.generatePublic(publicKeySpec);
            log.info("RSA 公钥加载成功");

            // 5. 校验密钥强度（不低于 2048 位）
            int keySize = getKeySize();
            if (keySize < 2048) {
                log.warn("RSA 密钥强度不足 2048 位，当前: {} 位。建议使用 2048 位或更高强度的密钥", keySize);
            } else {
                log.info("RSA 密钥强度校验通过，密钥位数: {} 位", keySize);
            }

            // 6. 校验密钥对是否匹配
            validateKeyPair();

            log.info("RsaKeyConfig 初始化成功，密钥算法: RSA/{}", keySize);
        } catch (IllegalStateException e) {
            throw e;
        } catch (IllegalArgumentException e) {
            log.error("RSA 密钥 Base64 解码失败: {}", e.getMessage());
            throw new IllegalStateException("RSA key Base64 decoding failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("RSA 密钥加载失败: {}", e.getMessage());
            throw new IllegalStateException("RSA key loading failed: " + e.getMessage(), e);
        }
    }

    /**
     * 校验 RSA 密钥对是否匹配（私钥签名 + 公钥验签）。
     *
     * @throws Exception 签名或验签异常
     */
    private void validateKeyPair() throws Exception {
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(privateKey);
        byte[] testData = "CloudStrollOffice-RSA-KeyPair-Validation".getBytes();
        signature.update(testData);
        byte[] signedData = signature.sign();

        Signature verifySignature = Signature.getInstance("SHA256withRSA");
        verifySignature.initVerify(publicKey);
        verifySignature.update(testData);
        boolean verified = verifySignature.verify(signedData);

        if (verified) {
            log.info("RSA 密钥对匹配校验通过");
        } else {
            log.error("RSA 密钥对不匹配：私钥和公钥不配对");
            throw new IllegalStateException("RSA key pair mismatch: private key and public key do not match");
        }
    }

    /**
     * 获取 RSA 密钥强度（位数）。
     *
     * @return 密钥位数
     */
    private int getKeySize() {
        if (privateKey != null) {
            // 对于 RSA 私钥，可以从 encoded 格式推断密钥强度
            // PKCS8 编码的私钥长度可估算 RSA 模数位长
            return ((java.security.interfaces.RSAKey) privateKey).getModulus().bitLength();
        }
        return 0;
    }

    /**
     * 获取 RSA 私钥。
     *
     * @return PrivateKey 对象
     */
    public PrivateKey getPrivateKey() {
        return privateKey;
    }

    /**
     * 获取 RSA 公钥。
     *
     * @return PublicKey 对象
     */
    public PublicKey getPublicKey() {
        return publicKey;
    }
}
