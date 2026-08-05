/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import org.cloudstrolling.cloudoffice.gateway.GatewayApplication;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * {@link AuthProperties} 配置属性类测试。
 *
 * <p>验证 {@code application.yml} 中的 {@code auth.white-list} 配置项
 * 能被正确加载并注入到 {@link AuthProperties} Bean 中。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootTest(classes = GatewayApplication.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.cloud.nacos.discovery.enabled=false",
        "spring.cloud.nacos.config.enabled=false",
        "spring.cloud.nacos.config.import-check.enabled=false",
        "spring.main.web-application-type=reactive",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration,org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration",
        "auth.rsa.public-key=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA9uVdbps/od+OpgdAvRV4ThmIim8F0EAh8i0D23zS1eprd3z34JU2So/Jun5LAJgBowDXOLEoYjaMdfDteoH89zQGGu5TInOIipmI9ebVJ95Gl2Y+cA9B5+sU08xqGXHd8msjLlNBgmReljQhD8RDmworLEueZ55JWnh04ocAe8UWRoRO6xs1swVTYWDWREXyfCf2pSfn1pLYXCKHFua/9+eeaz10UuKjbEfjScUrfVUacdSM9rrdHodTmlayzRcom7xHBDDs8uaZTc8ox9eDRT1KIUIvz3YT1w7eWxlXqhIjpkGtHy0aQjwEmNbZpcuQWdZMV+uZ5TU9wqDHWabVowIDAQAB"
})
class AuthPropertiesTest {

    @Autowired
    private AuthProperties authProperties;

    /**
     * 验证 {@link AuthProperties} Bean 能被正常注入到 Spring 上下文中。
     */
    @Test
    @DisplayName("AuthProperties Bean 应正常注入")
    void authProperties_shouldBeInjected_whenContextLoads() {
        // Then: AuthProperties Bean 不为空
        assertNotNull(authProperties, "AuthProperties Bean 应被 Spring 容器管理");
    }

    /**
     * 验证白名单配置正确读取，包含至少 7 个默认路径。
     */
    @Test
    @DisplayName("白名单应包含 7 个默认路径")
    void whiteList_shouldContainDefaultPaths_whenConfigLoaded() {
        // When: 获取白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 白名单列表不为空且包含至少 7 个默认路径
        assertNotNull(whiteList, "白名单列表不应为空");
        assertFalse(whiteList.isEmpty(), "白名单列表不应为空");
        assertTrue(whiteList.size() >= 7, "默认白名单应包含至少 7 个路径");
    }

    /**
     * 验证白名单中包含认证相关路径。
     */
    @Test
    @DisplayName("白名单应包含 /api/v1/auth/login")
    void whiteList_shouldContainLoginPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含登录路径
        assertTrue(whiteList.contains("/api/v1/auth/login"),
                "白名单应包含 /api/v1/auth/login");
    }

    /**
     * 验证白名单中包含注册路径。
     */
    @Test
    @DisplayName("白名单应包含 /api/v1/auth/register")
    void whiteList_shouldContainRegisterPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含注册路径
        assertTrue(whiteList.contains("/api/v1/auth/register"),
                "白名单应包含 /api/v1/auth/register");
    }

    /**
     * 验证白名单中包含 Token 刷新路径。
     */
    @Test
    @DisplayName("白名单应包含 /api/v1/auth/refresh")
    void whiteList_shouldContainRefreshPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含刷新路径
        assertTrue(whiteList.contains("/api/v1/auth/refresh"),
                "白名单应包含 /api/v1/auth/refresh");
    }

    /**
     * 验证白名单中包含健康检查路径。
     */
    @Test
    @DisplayName("白名单应包含 /api/v1/auth/health")
    void whiteList_shouldContainHealthPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含健康检查路径
        assertTrue(whiteList.contains("/api/v1/auth/health"),
                "白名单应包含 /api/v1/auth/health");
    }

    /**
     * 验证白名单支持 Ant 风格路径匹配（如 /swagger-ui/**）。
     */
    @Test
    @DisplayName("白名单应包含 Ant 风格路径 /swagger-ui/**")
    void whiteList_shouldSupportAntStylePath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含 Ant 风格路径
        assertTrue(whiteList.contains("/swagger-ui/**"),
                "白名单应包含 Ant 风格路径 /swagger-ui/**");
    }

    /**
     * 验证白名单中包含 Swagger API 文档路径。
     */
    @Test
    @DisplayName("白名单应包含 /v3/api-docs/**")
    void whiteList_shouldContainApiDocsPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含 API 文档路径
        assertTrue(whiteList.contains("/v3/api-docs/**"),
                "白名单应包含 /v3/api-docs/**");
    }

    /**
     * 验证白名单中包含 WebJars 路径。
     */
    @Test
    @DisplayName("白名单应包含 /webjars/**")
    void whiteList_shouldContainWebjarsPath_whenConfigLoaded() {
        // Given: 白名单列表
        List<String> whiteList = authProperties.getWhiteList();

        // Then: 应包含 WebJars 路径
        assertTrue(whiteList.contains("/webjars/**"),
                "白名单应包含 /webjars/**");
    }
}
