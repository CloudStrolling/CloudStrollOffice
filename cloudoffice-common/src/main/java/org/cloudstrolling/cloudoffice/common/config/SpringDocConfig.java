package org.cloudstrolling.cloudoffice.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * SpringDoc OpenAPI 3 配置类
 *
 * <p>提供全局 OpenAPI 文档信息和按模块分组配置。</p>
 *
 * @author CloudStrolling Team
 */
@Configuration
public class SpringDocConfig {

    /**
     * 自定义 OpenAPI 信息。
     *
     * @return OpenAPI 实例
     */
    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("云漫智企 (CloudStrollOffice)")
                        .version("v0.1.0")
                        .description("云漫智企 RESTful API 文档")
                        .contact(new Contact()
                                .name("CloudStrolling Team")
                                .email("dev@cloudstrolling.com"))
                        .license(new License()
                                .name("Apache 2.0")
                                .url("https://www.apache.org/licenses/LICENSE-2.0")));
    }

    /**
     * 认证模块分组。
     *
     * @return GroupedOpenApi 实例
     */
    @Bean
    public GroupedOpenApi authGroupApi() {
        return GroupedOpenApi.builder()
                .group("auth")
                .displayName("认证模块")
                .pathsToMatch("/api/auth/**")
                .build();
    }

    /**
     * 业务模块分组。
     *
     * @return GroupedOpenApi 实例
     */
    @Bean
    public GroupedOpenApi bizGroupApi() {
        return GroupedOpenApi.builder()
                .group("biz")
                .displayName("业务模块")
                .pathsToMatch("/api/biz/**")
                .build();
    }

    /**
     * 云资源模块分组。
     *
     * @return GroupedOpenApi 实例
     */
    @Bean
    public GroupedOpenApi cloudGroupApi() {
        return GroupedOpenApi.builder()
                .group("cloud")
                .displayName("云资源模块")
                .pathsToMatch("/api/cloud/**")
                .build();
    }

    /**
     * 系统管理模块分组。
     *
     * @return GroupedOpenApi 实例
     */
    @Bean
    public GroupedOpenApi systemGroupApi() {
        return GroupedOpenApi.builder()
                .group("system")
                .displayName("系统管理模块")
                .pathsToMatch("/api/system/**")
                .build();
    }
}
