/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.constant;

import lombok.experimental.UtilityClass;

/**
 * Redis Key 常量管理类。
 * <p>
 * 统一管理 Redis Key 前缀常量，并提供 Key 构建方法，
 * 确保项目中 Redis Key 的命名一致性和可维护性。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@UtilityClass
public class RedisKeyConstants {

    // ========== Key 前缀常量 ==========

    /** 用户登录态会话 Key 前缀：auth:session:{userId}:{clientType} */
    public static final String SESSION_KEY_PREFIX = "auth:session:";

    /** Token 黑名单 Key 前缀：auth:blacklist:{tokenSignature} */
    public static final String BLACKLIST_KEY_PREFIX = "auth:blacklist:";

    /** 账号状态缓存 Key 前缀：auth:account:status:{userId} */
    public static final String ACCOUNT_STATUS_KEY_PREFIX = "auth:account:status:";

    /** 租户状态缓存 Key 前缀：auth:tenant:status:{tenantId} */
    public static final String TENANT_STATUS_KEY_PREFIX = "auth:tenant:status:";

    // ========== Key 构建方法 ==========

    /**
     * 构建用户登录态会话 Key。
     * <p>
     * 格式：auth:session:{userId}:{clientType}
     * </p>
     *
     * @param userId     用户 ID，不能为 null
     * @param clientType 客户端类型，不能为 null
     * @return 完整的 Redis Key 字符串
     * @throws IllegalArgumentException 如果 userId 或 clientType 为 null
     */
    public static String buildSessionKey(Long userId, String clientType) {
        if (userId == null) {
            throw new IllegalArgumentException("userId must not be null");
        }
        if (clientType == null) {
            throw new IllegalArgumentException("clientType must not be null");
        }
        return SESSION_KEY_PREFIX + userId + ":" + clientType;
    }

    /**
     * 构建 Token 黑名单 Key。
     * <p>
     * 格式：auth:blacklist:{tokenSignature}
     * </p>
     *
     * @param tokenSignature Token 签名，不能为 null
     * @return 完整的 Redis Key 字符串
     * @throws IllegalArgumentException 如果 tokenSignature 为 null
     */
    public static String buildBlacklistKey(String tokenSignature) {
        if (tokenSignature == null) {
            throw new IllegalArgumentException("tokenSignature must not be null");
        }
        return BLACKLIST_KEY_PREFIX + tokenSignature;
    }

    /**
     * 构建账号状态缓存 Key。
     * <p>
     * 格式：auth:account:status:{userId}
     * </p>
     *
     * @param userId 用户 ID，不能为 null
     * @return 完整的 Redis Key 字符串
     * @throws IllegalArgumentException 如果 userId 为 null
     */
    public static String buildAccountStatusKey(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("userId must not be null");
        }
        return ACCOUNT_STATUS_KEY_PREFIX + userId;
    }

    /**
     * 构建租户状态缓存 Key。
     * <p>
     * 格式：auth:tenant:status:{tenantId}
     * </p>
     *
     * @param tenantId 租户 ID，不能为 null
     * @return 完整的 Redis Key 字符串
     * @throws IllegalArgumentException 如果 tenantId 为 null
     */
    public static String buildTenantStatusKey(Long tenantId) {
        if (tenantId == null) {
            throw new IllegalArgumentException("tenantId must not be null");
        }
        return TENANT_STATUS_KEY_PREFIX + tenantId;
    }
}
