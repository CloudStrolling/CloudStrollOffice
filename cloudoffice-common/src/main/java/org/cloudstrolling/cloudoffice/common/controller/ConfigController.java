package org.cloudstrolling.cloudoffice.common.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.cloudstrolling.cloudoffice.common.service.ConfigService;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 通用配置管理控制器（ConfigController）。
 *
 * <p>提供通用配置管理查询接口（v0.2.8，本版本仅实现查询，写入接口预留扩展点）：</p>
 * <ul>
 *   <li>API-035 {@code GET /api/v1/common/config}：按 serviceName/group/key 过滤 + 分页查询；</li>
 *   <li>API-036 {@code GET /api/v1/common/config/{serviceName}}：按微服务名称查询（不分页）。</li>
 * </ul>
 *
 * <p>响应统一使用 {@link ApiResult} 响应体；分页接口 data 为 {@link PageResult}。
 * 查询需经网关 AuthFilter 认证（非白名单端点）。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/common")
@Tag(name = "common 通用配置管理", description = "统一管理各微服务运行时配置项的查询接口")
public class ConfigController {

    private final ConfigService configService;

    /**
     * 构造器注入 ConfigService。
     *
     * @param configService 通用配置管理服务
     */
    public ConfigController(ConfigService configService) {
        this.configService = configService;
    }

    /**
     * API-035：查询配置列表（按条件过滤 + 分页）。
     *
     * @param serviceName 微服务名称（可选，gateway/auth-service/biz-service/system-service/common）
     * @param group       配置分组（可选）
     * @param key         配置键（可选，精确匹配）
     * @param page        页码（默认 1）
     * @param pageSize    每页条数（默认 10）
     * @return 统一分页结果
     */
    @GetMapping("/config")
    @Operation(summary = "查询配置列表", description = "按微服务名称/配置分组/配置键过滤查询运行时配置项，支持分页")
    public ApiResult<PageResult<ConfigItemVO>> queryConfigList(
            @Parameter(description = "微服务名称（gateway/auth-service/biz-service/system-service/common）")
            @RequestParam(value = "serviceName", required = false) String serviceName,
            @Parameter(description = "配置分组")
            @RequestParam(value = "group", required = false) String group,
            @Parameter(description = "配置键（精确匹配）")
            @RequestParam(value = "key", required = false) String key,
            @Parameter(description = "页码（从 1 开始）")
            @RequestParam(value = "page", required = false) Integer page,
            @Parameter(description = "每页条数")
            @RequestParam(value = "pageSize", required = false) Integer pageSize) {
        log.info("查询配置列表 | serviceName={} group={} key={} page={} pageSize={}",
                serviceName, group, key, page, pageSize);
        PageResult<ConfigItemVO> data = configService.queryConfigList(serviceName, group, key, page, pageSize);
        return ApiResult.success(data);
    }

    /**
     * API-036：按微服务名称查询配置（不分页）。
     *
     * @param serviceName 微服务名称（gateway/auth-service/biz-service/system-service/common）
     * @return 该微服务的全部配置项列表（敏感配置已脱敏）
     */
    @GetMapping("/config/{serviceName}")
    @Operation(summary = "按微服务查询配置", description = "按微服务名称查询该服务的全部运行时配置项（不分页）")
    public ApiResult<List<ConfigItemVO>> queryConfigsByService(
            @Parameter(description = "微服务名称（gateway/auth-service/biz-service/system-service/common）")
            @PathVariable("serviceName") String serviceName) {
        log.info("按微服务查询配置 | serviceName={}", serviceName);
        List<ConfigItemVO> data = configService.queryConfigsByService(serviceName);
        return ApiResult.success(data);
    }
}
