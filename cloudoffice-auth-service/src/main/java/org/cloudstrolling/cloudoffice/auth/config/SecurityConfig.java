package org.cloudstrolling.cloudoffice.auth.config;

import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.util.JsonUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
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
 * @author CloudStroll Office
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
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
     *   <li>健康检查端点、Swagger 文档可匿名访问</li>
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
                        .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .anyRequest().authenticated()
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
