/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.interfaces.RSAKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * RSA 公钥加载配置类。
 *
 * <p>从环境变量 / 配置文件 / PEM 文件三种途径加载 RSA 公钥，
 * 加载优先级（从高到低）：环境变量 → 配置文件 Base64 → PEM 文件路径。</p>
 *
 * <p>提供 {@link #getPublicKey()} 方法供 {@code AuthFilter} 等组件调用，
 * 在 {@link PostConstruct @PostConstruct} 阶段完成公钥的加载与校验，
 * 公钥为空时服务启动失败。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Getter
@Configuration
public class RsaKeyConfig {

    /**
     * Base64 编码的 RSA 公钥字符串。
     *
     * <p>支持通过环境变量 {@code RSA_PUBLIC_KEY} 或配置文件
     * {@code auth.rsa.public-key} 设置。环境变量优先级高于配置文件。</p>
     */
    @Value("${auth.rsa.public-key:}")
    private String publicKey;

    /**
     * PEM 公钥文件路径。
     *
     * <p>支持通过环境变量 {@code RSA_PUBLIC_KEY_PATH} 或配置文件
     * {@code auth.rsa.public-key-path} 设置。仅在 {@link #publicKey}
     * 为空时生效。</p>
     */
    @Value("${auth.rsa.public-key-path:}")
    private String publicKeyPath;

    /**
     * 解码后的 RSA {@link PublicKey} 对象，供 {@code AuthFilter} 验签使用。
     */
    private PublicKey rsaPublicKey;

    /**
     * 初始化方法：加载并校验 RSA 公钥。
     *
     * <p>加载顺序（优先级从高到低）：</p>
     * <ol>
     *   <li>环境变量 {@code RSA_PUBLIC_KEY} 或配置文件 {@code auth.rsa.public-key}</li>
     *   <li>PEM 文件路径（环境变量 {@code RSA_PUBLIC_KEY_PATH} 或配置文件
     *       {@code auth.rsa.public-key-path}）</li>
     * </ol>
     *
     * <p>校验规则：</p>
     * <ul>
     *   <li>公钥为空时抛出 {@link IllegalArgumentException}，服务拒绝启动</li>
     *   <li>Base64 解码失败时抛出异常并打印解码异常信息</li>
     *   <li>密钥位数不足 2048 位时打印 WARN 级别日志提示密钥强度不足</li>
     * </ul>
     */
    @PostConstruct
    public void init() {
        // 尝试从配置/环境变量获取公钥内容（Spring 已按优先级解析环境变量）
        String keyContent = publicKey;
        String source = "环境变量/配置文件";

        // 如果配置的 Base64 公钥为空，尝试从 PEM 文件路径读取
        if ((keyContent == null || keyContent.isEmpty()) && publicKeyPath != null
                && !publicKeyPath.isEmpty()) {
            try {
                keyContent = readPemFile(publicKeyPath);
                source = "PEM 文件";
                log.info("从 PEM 文件加载 RSA 公钥成功，路径：{}", publicKeyPath);
            } catch (IOException e) {
                log.error("读取 RSA 公钥 PEM 文件失败，路径：{}", publicKeyPath, e);
                throw new IllegalArgumentException(
                        "读取 RSA 公钥 PEM 文件失败，请检查文件路径是否正确：" + publicKeyPath, e);
            }
        }

        // 校验公钥不能为空
        if (keyContent == null || keyContent.isEmpty()) {
            log.error("RSA 公钥未配置。请通过以下任一方式配置："
                    + "1) 环境变量 RSA_PUBLIC_KEY；"
                    + "2) 配置文件 auth.rsa.public-key；"
                    + "3) PEM 文件路径 auth.rsa.public-key-path（或环境变量 RSA_PUBLIC_KEY_PATH）");
            throw new IllegalArgumentException("RSA 公钥未配置，服务启动失败");
        }

        // Base64 解码并构建 PublicKey 对象
        try {
            byte[] keyBytes = Base64.getDecoder().decode(keyContent.trim());
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            rsaPublicKey = keyFactory.generatePublic(keySpec);

            // 检查密钥强度
            int keySize = ((RSAKey) rsaPublicKey).getModulus().bitLength();
            if (keySize < 2048) {
                log.warn("RSA 公钥强度不足：当前 {} 位，建议使用 2048 位或更高的密钥", keySize);
            } else {
                log.info("RSA 公钥加载成功（来源：{}，算法：{}，位数：{} 位）", source,
                        rsaPublicKey.getAlgorithm(), keySize);
            }
        } catch (IllegalArgumentException e) {
            log.error("RSA 公钥 Base64 解码失败，请检查公钥格式是否正确", e);
            throw new IllegalArgumentException("RSA 公钥 Base64 解码失败，请检查公钥格式", e);
        } catch (Exception e) {
            log.error("RSA 公钥加载失败，请检查公钥格式是否有效", e);
            throw new IllegalArgumentException("RSA 公钥加载失败：" + e.getMessage(), e);
        }
    }

    /**
     * 获取解码后的 RSA 公钥对象。
     *
     * @return RSA {@link PublicKey} 对象，在 {@link #init()} 成功后可用
     */
    public PublicKey getPublicKey() {
        return rsaPublicKey;
    }

    /**
     * 从 PEM 文件读取 Base64 编码的公钥内容。
     *
     * <p>自动跳过 PEM 文件的头部（{@code -----BEGIN PUBLIC KEY-----}）和尾部标记
     * （{@code -----END PUBLIC KEY-----}），仅提取 Base64 编码的密钥数据。</p>
     *
     * @param filePath PEM 文件路径
     * @return Base64 编码的密钥字符串（不含 PEM 标记和换行符）
     * @throws IOException 文件不存在或读取失败时抛出
     */
    private String readPemFile(String filePath) throws IOException {
        Path path = Paths.get(filePath);
        if (!Files.exists(path)) {
            throw new IOException("PEM 文件不存在：" + filePath);
        }
        StringBuilder keyData = new StringBuilder();
        Files.lines(path).forEach(line -> {
            String trimmed = line.trim();
            if (!trimmed.startsWith("-----") && !trimmed.isEmpty()) {
                keyData.append(trimmed);
            }
        });
        if (keyData.isEmpty()) {
            throw new IOException("PEM 文件内容为空或格式不正确：" + filePath);
        }
        return keyData.toString();
    }
}
