/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.KickoutRequest;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证控制器。
 *
 * <p>提供登录、登出、Token 刷新、强制踢人等认证相关 API 端点。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "认证管理", description = "登录、登出、Token 刷新、强制踢人等认证接口")
public class AuthController {

    private final LoginService loginService;

    /**
     * 构造器注入。
     *
     * @param loginService 登录认证服务
     */
    public AuthController(LoginService loginService) {
        this.loginService = loginService;
    }

    /**
     * 强制踢人。
     *
     * <p>管理员强制指定用户下线。可指定客户端类型踢指定端，或不指定客户端类型踢所有端。</p>
     *
     * @param request 踢人请求，包含目标用户 ID 和可选的客户端类型
     * @return 统一响应体，踢人成功返回 200
     */
    @PostMapping("/kickout")
    @Operation(summary = "强制踢人", description = "管理员强制指定用户下线，支持踢指定端或所有端")
    public ApiResult<Void> kickout(@Valid @RequestBody KickoutRequest request) {
        loginService.kickout(request.getUserId(), request.getClientType());
        log.info("Kickout request processed | targetUserId={} | clientType={}",
                request.getUserId(), request.getClientType());
        return ApiResult.success();
    }
}
