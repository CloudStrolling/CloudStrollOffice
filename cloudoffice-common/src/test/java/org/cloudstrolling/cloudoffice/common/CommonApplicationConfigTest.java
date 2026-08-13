/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

import static org.junit.jupiter.api.Assertions.*;

/**
 * common 服务化改造测试（TASK-002）。
 *
 * <p>验证 CommonApplication 启动类、bootstrap.yml、application.yml 与 pom.xml
 * 的服务化配置是否正确，保证 cloudoffice-common 可独立部署且下游依赖不受影响。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("common 服务化改造测试（TASK-002）")
class CommonApplicationConfigTest {

    /** 读取 classpath 下配置文件内容。 */
    private String readClasspathResource(String name) {
        try (InputStream in = getClass().getResourceAsStream("/" + name)) {
            assertNotNull(in, "classpath 资源不存在: " + name);
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new AssertionError("读取 classpath 资源失败: " + name, e);
        }
    }

    /** 读取 pom.xml 内容（Maven 测试工作目录为模块目录）。 */
    private String readPomXml() {
        File pom = new File("pom.xml");
        if (!pom.exists()) {
            pom = new File("cloudoffice-common/pom.xml");
        }
        assertTrue(pom.exists(), "pom.xml 不存在（工作目录: " + System.getProperty("user.dir") + "）");
        try {
            return Files.readString(pom.toPath(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new AssertionError("读取 pom.xml 失败", e);
        }
    }

    @Test
    @DisplayName("TC-TASK002-001: CommonApplication 存在且标注 @SpringBootApplication/@EnableDiscoveryClient，含 main 方法")
    void commonApplication_shouldBeBootApplicationWithMain() throws Exception {
        Class<?> clazz = Class.forName("org.cloudstrolling.cloudoffice.common.CommonApplication");
        assertNotNull(clazz.getAnnotation(SpringBootApplication.class),
                "CommonApplication 应标注 @SpringBootApplication");
        assertNotNull(clazz.getAnnotation(EnableDiscoveryClient.class),
                "CommonApplication 应标注 @EnableDiscoveryClient");
        Method main = clazz.getMethod("main", String[].class);
        assertEquals(void.class, main.getReturnType(), "main 方法应返回 void");
    }

    @Test
    @DisplayName("TC-TASK002-002: bootstrap.yml 应用名与 Nacos 引导配置正确")
    void bootstrapYml_shouldContainNacosBootstrapConfig() {
        String yml = readClasspathResource("bootstrap.yml");
        assertTrue(yml.contains("name: cloudoffice-common"), "bootstrap.yml 应用名应为 cloudoffice-common");
        assertTrue(yml.contains("${NACOS_ADDR:127.0.0.1:8848}"), "Nacos server-addr 应从 NACOS_ADDR 读取");
        assertTrue(yml.contains("${NACOS_NAMESPACE:cso-dev}"), "Nacos namespace 应从 NACOS_NAMESPACE 读取");
        // A-01 修复：不得再为各服务配置 discovery/config 的 group（保持默认 DEFAULT_GROUP），
        // 否则消费方以自身 group 查询实例导致跨服务发现失效（lb:// 路由 503）
        assertFalse(yml.contains("group: cloudoffice-common"),
                "A-01 修复后 bootstrap.yml 不应再配置 group（恢复默认 DEFAULT_GROUP）");
        assertTrue(yml.contains("file-extension: yaml"), "Nacos config file-extension 应为 yaml");
        assertTrue(yml.contains("discovery:") && yml.contains("config:"),
                "bootstrap.yml 应同时含 discovery 与 config 引导配置");
    }

    @Test
    @DisplayName("TC-TASK002-003: application.yml 端口/SpringDoc 分组/数据源与缓存配置正确")
    void applicationYml_shouldContainServiceConfig() {
        String yml = readClasspathResource("application.yml");
        assertTrue(yml.contains("port: ${COMMON_PORT:9300}"), "server.port 应为 ${COMMON_PORT:9300}");
        assertTrue(yml.contains("name: cloudoffice-common"), "application.yml 应用名应为 cloudoffice-common");
        assertTrue(yml.contains("- group: common"), "SpringDoc 分组应含 common");
        assertTrue(yml.contains("paths-to-match: /api/v1/common/**"), "SpringDoc 分组路径应为 /api/v1/common/**");
        // TASK-004 起 common 服务接入通用配置管理（t_common_config 数据源 + Redis 本地缓存 + MyBatis-Plus 分页），
        // 不再排除 DataSource/MyBatis 自动配置，改为显式配置数据源、Redis 与 mybatis-plus
        assertTrue(yml.contains("jdbc:mariadb://"), "application.yml 应配置 MariaDB 数据源（通用配置库）");
        assertTrue(yml.contains("cloudstroll_office_common"), "数据源应指向 cloudstroll_office_common 库");
        assertFalse(yml.contains("DataSourceAutoConfiguration"), "TASK-004 起不应再排除 DataSourceAutoConfiguration（已接入数据源）");
        assertFalse(yml.contains("MybatisPlusAutoConfiguration"), "TASK-004 起不应再排除 MybatisPlusAutoConfiguration（已启用分页插件）");
        assertTrue(yml.contains("redis:"), "application.yml 应配置 Redis（通用配置本地缓存）");
        assertTrue(yml.contains("mybatis-plus:"), "application.yml 应配置 mybatis-plus（分页插件支持）");
        assertTrue(yml.contains("common:"), "application.yml 应配置 common.config（缓存 TTL 与脱敏掩码）");
    }

    @Test
    @DisplayName("TC-TASK002-004: pom.xml 引入 bootstrap/Nacos 依赖与可执行 jar 打包配置")
    void pomXml_shouldContainServiceDependenciesAndPackaging() {
        String pom = readPomXml();
        assertTrue(pom.contains("spring-cloud-starter-bootstrap"), "pom 应引入 spring-cloud-starter-bootstrap");
        assertTrue(pom.contains("spring-cloud-starter-alibaba-nacos-discovery"),
                "pom 应引入 nacos-discovery");
        assertTrue(pom.contains("spring-cloud-starter-alibaba-nacos-config"),
                "pom 应引入 nacos-config");
        assertTrue(pom.contains("spring-boot-maven-plugin"), "pom 应引入 spring-boot-maven-plugin");
        assertTrue(pom.contains("<classifier>exec</classifier>"),
                "spring-boot-maven-plugin 应配置 classifier=exec（保持主 artifact 为普通 jar）");
        assertTrue(pom.contains("cloudoffice-common.jar"), "antrun 应将可执行 jar 复制为 deploy/cloudoffice-common.jar");
    }

    @Test
    @DisplayName("TC-TASK002-007 支持: 公共 jar 能力类仍存在（下游依赖不受影响的静态依据）")
    void commonJarCapabilities_shouldRemain() throws Exception {
        // 静态断言：服务化改造不得破坏下游依赖的公共类/接口（编译回归由接口测试脚本执行全量构建）
        assertNotNull(Class.forName("org.cloudstrolling.cloudoffice.common.model.ApiResult"),
                "ApiResult 公共类应保留");
        assertNotNull(Class.forName("org.cloudstrolling.cloudoffice.common.model.PageResult"),
                "PageResult 公共类应保留");
        assertNotNull(Class.forName("org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler"),
                "GlobalExceptionHandler 公共类应保留");
    }
}
