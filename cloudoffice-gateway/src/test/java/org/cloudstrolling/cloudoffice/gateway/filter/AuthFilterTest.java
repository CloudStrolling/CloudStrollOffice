/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Jwts;
import org.cloudstrolling.cloudoffice.gateway.GatewayApplication;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.core.ReactiveValueOperations;
import org.springframework.http.MediaType;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.core.publisher.Mono;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * AuthFilter 全局认证过滤器集成测试。
 *
 * <p>使用 Spring Cloud Gateway 测试框架验证：
 * 白名单路径放行、无 Token 返回 401、有效 Token 透传 Header、
 * 黑名单 Token 返回 401、过期 Token 返回 401。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootTest(classes = GatewayApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.DEFINED_PORT,
        properties = {
                "server.port=9999",
                "spring.cloud.nacos.discovery.enabled=false",
                "spring.cloud.nacos.config.enabled=false",
                "spring.cloud.nacos.config.import-check.enabled=false",
                "spring.main.web-application-type=reactive",
                "spring.autoconfigure.exclude="
                        + "org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                        + "com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.data.redis.RedisReactiveAutoConfiguration,"
                        + "org.springframework.cloud.gateway.config.GatewayRedisAutoConfiguration",
                "auth.rsa.public-key=${test.rsa.public-key}",
                "auth.white-list[0]=/api/v1/auth/login",
                "auth.white-list[1]=/api/v1/auth/register",
                "auth.white-list[2]=/api/v1/auth/refresh",
                "auth.white-list[3]=/api/v1/auth/health",
                "auth.white-list[4]=/swagger-ui/**",
                "auth.white-list[5]=/v3/api-docs/**",
                "auth.white-list[6]=/favicon.ico",
                "auth.white-list[7]=/webjars/**"
        })
@Import(AuthFilterTest.TestConfig.class)
@DisplayName("AuthFilter 全局认证过滤器集成测试")
class AuthFilterTest {

    /** 测试用 RSA 密钥对。 */
    private static KeyPair keyPair;

    /** 测试用 RSA 私钥。 */
    private static java.security.PrivateKey privateKey;

    static {
        try {
            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            keyPair = generator.generateKeyPair();
            privateKey = keyPair.getPrivate();
            String base64PublicKey = Base64.getEncoder().encodeToString(
                    keyPair.getPublic().getEncoded());
            System.setProperty("test.rsa.public-key", base64PublicKey);
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate test RSA key pair", e);
        }
    }

    @Autowired
    private WebTestClient webTestClient;

    @MockBean
    private ReactiveRedisTemplate<String, Object> reactiveRedisTemplate;

    /**
     * 测试配置：提供路由和模拟 Redis 连接工厂。
     *
     * <p>路由使用自定义 {@link GatewayFilter} 直接返回响应（不通过 HTTP 代理），
     * 以避免 Tomcat + Netty 客户端代理时请求头丢失的问题。</p>
     */
    @TestConfiguration
    static class TestConfig {

        private static final ObjectMapper MAPPER = new ObjectMapper();

        @Bean
        public ReactiveRedisConnectionFactory reactiveRedisConnectionFactory() {
            return mock(ReactiveRedisConnectionFactory.class);
        }

        /**
         * 创建测试路由。
         *
         * <p>两个路由都使用自定义过滤器直接构建响应体，不调用
         * {@code chain.filter(exchange)}，从而短路 NettyRoutingFilter。</p>
         */
        @Bean
        public RouteLocator testRoutes(RouteLocatorBuilder builder) {
            return builder.routes()
                    .route("test-health", r -> r
                            .order(-1)
                            .path("/api/v1/auth/health")
                            .filters(f -> f.filter(healthFilter()))
                            .uri("http://localhost:9999"))
                    .route("test-echo", r -> r
                            .order(-1)
                            .path("/api/v1/biz/echo")
                            .filters(f -> f.filter(echoFilter()))
                            .uri("http://localhost:9999"))
                    .build();
        }

        /**
         * Health 检查过滤器：直接返回 {@code {"status":"UP"}}。
         */
        private GatewayFilter healthFilter() {
            return (exchange, chain) -> {
                try {
                    byte[] bytes = MAPPER.writeValueAsBytes(Map.of("status", "UP"));
                    exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
                    DataBuffer buffer = exchange.getResponse().bufferFactory().wrap(bytes);
                    return exchange.getResponse().writeWith(Mono.just(buffer));
                } catch (Exception e) {
                    return Mono.error(e);
                }
            };
        }

        /**
         * Echo 过滤器：读取请求中所有 {@code X-} 开头的 Header，以 JSON 返回。
         *
         * <p>AuthFilter 在 GlobalFilter 阶段已将用户信息写入请求头，
         * 此过滤器在 RouteFilter 阶段读取已写入的 Header，避免 HTTP 代理转发。</p>
         */
        private GatewayFilter echoFilter() {
            return (exchange, chain) -> {
                Map<String, String> headers = new HashMap<>();
                exchange.getRequest().getHeaders().forEach((name, values) -> {
                    if (name.startsWith("X-")) {
                        headers.put(name, String.join(",", values));
                    }
                });
                try {
                    byte[] bytes = MAPPER.writeValueAsBytes(headers);
                    exchange.getResponse().getHeaders().setContentType(MediaType.APPLICATION_JSON);
                    DataBuffer buffer = exchange.getResponse().bufferFactory().wrap(bytes);
                    return exchange.getResponse().writeWith(Mono.just(buffer));
                } catch (Exception e) {
                    return Mono.error(e);
                }
            };
        }
    }

    // ==================== Mock 设置 ====================

    /**
     * 每个测试方法前重置 Mock 行为。
     *
     * <p>默认所有 key 返回 empty（未黑名单、登录态不存在、状态缓存不存在）。
     * 需要 Redis 校验通过的测试方法应自行覆写 Mock 行为。</p>
     */
    @BeforeEach
    void setupMock() {
        ReactiveValueOperations<String, Object> valueOps = mock(ReactiveValueOperations.class);
        when(reactiveRedisTemplate.opsForValue()).thenReturn(valueOps);
        when(valueOps.get(anyString())).thenReturn(Mono.empty());
    }

    // ==================== Token 生成 ====================

    /**
     * 生成测试用 Access Token。
     */
    private String generateAccessToken(Long userId, Long tenantId, String userName,
                                       String clientType, String roles, String permissions,
                                       long expiresInMs) {
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("tenantId", tenantId)
                .claim("userName", userName)
                .claim("clientType", clientType)
                .claim("tokenType", "access")
                .claim("roles", roles)
                .claim("permissions", permissions)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiresInMs))
                .signWith(privateKey, Jwts.SIG.RS256)
                .compact();
    }

    /**
     * 生成测试用 Refresh Token（tokenType=refresh）。
     */
    private String generateRefreshToken(Long userId, Long tenantId, String userName,
                                        String clientType, long expiresInMs) {
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("tenantId", tenantId)
                .claim("userName", userName)
                .claim("clientType", clientType)
                .claim("tokenType", "refresh")
                .claim("tokenVersion", java.util.UUID.randomUUID().toString())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiresInMs))
                .signWith(privateKey, Jwts.SIG.RS256)
                .compact();
    }

    // ==================== 测试用例 ====================

    /**
     * 白名单路径应直接放行，无需 Token。
     */
    @Test
    @DisplayName("白名单路径应直接放行，无需 Token")
    void shouldPassWhiteListPath_withoutToken() {
        webTestClient.get()
                .uri("/api/v1/auth/health")
                .exchange()
                .expectStatus().isOk();
    }

    /**
     * 无 Token 访问非白名单路径应返回 401。
     */
    @Test
    @DisplayName("无 Token 访问非白名单路径应返回 401")
    void shouldReturn401_whenNoToken() {
        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401)
                .jsonPath("$.message").exists();
    }

    /**
     * 有效 Token 应通过校验并透传正确 Header。
     */
    @Test
    @DisplayName("有效 Token 应通过校验并透传正确 Header")
    void shouldPassAndForwardHeaders_withValidToken() {
        // Given: 配置 Mock 使所有 Redis 校验通过
        ReactiveValueOperations<String, Object> valueOps = mock(ReactiveValueOperations.class);
        when(reactiveRedisTemplate.opsForValue()).thenReturn(valueOps);
        // 默认：所有 key 返回 empty
        when(valueOps.get(anyString())).thenReturn(Mono.empty());
        // 登录态检查：返回非空（登录态存在）
        when(valueOps.get(argThat((String key) -> key != null && key.contains("session"))))
                .thenReturn(Mono.just("1"));

        String token = generateAccessToken(
                1001L, 1L, "testuser", "WINDOWS",
                "admin,operator", "system:user:list,system:user:create",
                7200000);

        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isOk()
                .expectBody()
                .jsonPath("$['X-User-Id']").isEqualTo("1001")
                .jsonPath("$['X-Tenant-Id']").isEqualTo("1")
                .jsonPath("$['X-User-Name']").isEqualTo("testuser")
                .jsonPath("$['X-Client-Type']").isEqualTo("WINDOWS")
                .jsonPath("$['X-Roles']").isEqualTo("admin,operator")
                .jsonPath("$['X-Permissions']").isEqualTo("system:user:list,system:user:create");
    }

    /**
     * 黑名单中的 Token 应返回 401。
     */
    @Test
    @DisplayName("黑名单中的 Token 应返回 401 TOKEN_BLACKLISTED")
    void shouldReturn401_whenTokenIsBlacklisted() {
        // Given: 配置 Redis 黑名单检查返回非空（Token 已被吊销）
        ReactiveValueOperations<String, Object> valueOps = mock(ReactiveValueOperations.class);
        when(reactiveRedisTemplate.opsForValue()).thenReturn(valueOps);
        // 默认：所有 key 返回 empty（必须先注册，再覆盖特定匹配）
        when(valueOps.get(anyString())).thenReturn(Mono.empty());
        // 覆盖：黑名单 key 返回 "1"（已黑名单）
        when(valueOps.get(argThat((String key) -> key != null && key.contains("blacklist"))))
                .thenReturn(Mono.just("1"));

        String token = generateAccessToken(
                1001L, 1L, "testuser", "WINDOWS",
                "admin", "perm1", 7200000);

        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * 登录态不存在时应返回 401 SESSION_KICKED_OUT。
     */
    @Test
    @DisplayName("登录态不存在时应返回 401 SESSION_KICKED_OUT")
    void shouldReturn401_whenSessionNotExists() {
        // Given: 配置 Session key 返回 null（登录态不存在）
        ReactiveValueOperations<String, Object> valueOps = mock(ReactiveValueOperations.class);
        when(reactiveRedisTemplate.opsForValue()).thenReturn(valueOps);
        // 默认：所有 key 返回 empty（必须先注册，再覆盖特定匹配）
        when(valueOps.get(anyString())).thenReturn(Mono.empty());
        // 黑名单检查通过（返回 empty）
        when(valueOps.get(argThat((String key) -> key != null && key.contains("blacklist"))))
                .thenReturn(Mono.empty());
        // Session 检查返回 empty（不存在）
        when(valueOps.get(argThat((String key) -> key != null && key.contains("session"))))
                .thenReturn(Mono.empty());

        String token = generateAccessToken(
                1001L, 1L, "testuser", "WINDOWS",
                "admin", "perm1", 7200000);

        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * 过期 Token 应返回 401。
     */
    @Test
    @DisplayName("过期 Token 应返回 401 TOKEN_EXPIRED")
    void shouldReturn401_whenTokenIsExpired() {
        // Given: 生成一个已过期的 Token（当前时间 - 1 小时）
        String token = generateAccessToken(
                1001L, 1L, "testuser", "WINDOWS",
                "admin", "perm1",
                -3600000); // 1小时前已过期

        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * Refresh Token（tokenType=refresh）应返回 401。
     */
    @Test
    @DisplayName("Refresh Token 应返回 401 TOKEN_INVALID")
    void shouldReturn401_whenTokenTypeIsRefresh() {
        String token = generateRefreshToken(
                1001L, 1L, "testuser", "WINDOWS", 7200000);

        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer " + token)
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * 非 Bearer 格式的 Authorization 头应返回 401。
     */
    @Test
    @DisplayName("非 Bearer 格式的 Authorization 头应返回 401")
    void shouldReturn401_whenAuthHeaderIsNotBearer() {
        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Basic dXNlcjpwYXNz")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * 空的 Authorization 头应返回 401。
     */
    @Test
    @DisplayName("空的 Authorization 头应返回 401")
    void shouldReturn401_whenAuthHeaderIsEmpty() {
        webTestClient.get()
                .uri("/api/v1/biz/echo")
                .header("Authorization", "Bearer ")
                .exchange()
                .expectStatus().isUnauthorized()
                .expectBody()
                .jsonPath("$.code").isEqualTo(401);
    }

    /**
     * 过滤器优先级应为 HIGHEST_PRECEDENCE + 10。
     */
    @Test
    @DisplayName("AuthFilter 优先级应为 HIGHEST_PRECEDENCE + 10")
    void authFilterOrder_shouldBeHighestPrecedencePlus10() {
        ReactiveRedisTemplate<String, Object> mockRedis = mock(ReactiveRedisTemplate.class);
        when(mockRedis.opsForValue()).thenReturn(mock(ReactiveValueOperations.class));

        org.cloudstrolling.cloudoffice.gateway.config.AuthProperties authProps =
                new org.cloudstrolling.cloudoffice.gateway.config.AuthProperties();
        org.cloudstrolling.cloudoffice.gateway.config.RsaKeyConfig rsaConfig =
                mock(org.cloudstrolling.cloudoffice.gateway.config.RsaKeyConfig.class);

        AuthFilter filter = new AuthFilter(authProps, rsaConfig, mockRedis);

        int expectedOrder = org.springframework.core.Ordered.HIGHEST_PRECEDENCE + 10;
        org.junit.jupiter.api.Assertions.assertEquals(expectedOrder, filter.getOrder(),
                "AuthFilter order should be HIGHEST_PRECEDENCE + 10");
    }
}
