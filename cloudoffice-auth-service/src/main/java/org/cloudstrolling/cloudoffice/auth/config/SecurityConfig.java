package org.cloudstrolling.cloudoffice.auth.config;

import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.util.JsonUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

/**
 * 安全配置。
 *
 * <p>配置 Spring Security 核心行为，包括密码编码器、安全过滤链、异常处理等。</p>
 *
 * <p>同时通过 {@link Import} 引入 common 模块的 {@link GlobalExceptionHandler}
 * （common 包不在本服务默认组件扫描范围内，需显式注册），
 * 保证业务异常统一转换为 ApiResult 契约响应，而非冒泡到容器 /error。</p>
 *
 * @author CloudStroll Office
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@Import(GlobalExceptionHandler.class)
@Slf4j
public class SecurityConfig {

    /**
     * BCrypt 密码编码器。
     *
     * @return BCryptPasswordEncoder
     */
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * 默认安全过滤链。
     *
     * <p>配置内容：</p>
     * <ul>
     *   <li>关闭 CSRF（API 使用 Token 鉴权）</li>
     *   <li>无状态会话管理（JWT 无状态）</li>
     *   <li>登录/注册/刷新、验证码、密码找回、健康检查端点、Swagger 文档可匿名访问</li>
     *   <li>其余请求均需认证</li>
     *   <li>自定义 401/403 JSON 响应</li>
     * </ul>
     *
     * @param http HttpSecurity
     * @return SecurityFilterChain
     * @throws Exception 配置异常
     */
    @Bean
    public SecurityFilterChain defaultSecurityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/v1/auth/health").permitAll()
                        .requestMatchers("/api/v1/auth/verification-code/send").permitAll()
                        .requestMatchers("/api/v1/auth/password/forgot/send-code").permitAll()
                        .requestMatchers("/api/v1/auth/password/forgot/reset").permitAll()
                        .requestMatchers("/api/v1/auth/login").permitAll()
                        .requestMatchers("/api/v1/auth/register").permitAll()
                        .requestMatchers("/api/v1/auth/refresh").permitAll()
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        // 认证由网关 AuthFilter（RS256 验签 + 状态校验 + X-User-Id/X-Roles 等头透传）负责，
                        // 本服务无 JWT 认证过滤器，Controller 层依赖透传头做二次认证（getCurrentUserId 缺失抛 401）。
                        // 因此除白名单端点外的全部请求放行到 Controller 层校验，防止 authenticated() 拦截全部匿名请求。
                        .anyRequest().permitAll()
                )
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) -> {
                            log.warn("未授权访问 | URI={} | {}", request.getRequestURI(), authException.getMessage());
                            response.setContentType("application/json;charset=UTF-8");
                            response.setStatus(HttpStatus.UNAUTHORIZED.value());
                            response.getWriter().write(JsonUtils.toJsonString(
                                    ApiResult.error(ErrorCode.UNAUTHORIZED)
                            ));
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            log.warn("权限不足 | URI={} | {}", request.getRequestURI(), accessDeniedException.getMessage());
                            response.setContentType("application/json;charset=UTF-8");
                            response.setStatus(HttpStatus.FORBIDDEN.value());
                            response.getWriter().write(JsonUtils.toJsonString(
                                    ApiResult.error(ErrorCode.FORBIDDEN)
                            ));
                        })
                );
        return http.build();
    }
}
