/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.AssignRolesRequest;
import org.cloudstrolling.cloudoffice.auth.dto.UserStatusRequest;
import org.cloudstrolling.cloudoffice.auth.dto.UserUpdateRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 用户管理控制器。
 *
 * <p>提供用户 CRUD、状态变更、角色分配等管理功能。
 * 所有接口需通过 JWT 认证后访问，租户信息从请求头中提取。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth/users")
@Tag(name = "用户管理", description = "用户 CRUD、状态变更、角色分配等管理接口")
public class UserController {

    private final UserService userService;

    /**
     * 构造器注入。
     *
     * @param userService 用户业务服务
     */
    public UserController(UserService userService) {
        this.userService = userService;
    }

    /**
     * 分页查询用户列表。
     *
     * <p>支持按 login_name 和 user_name 模糊搜索，结果按创建时间降序排列。</p>
     *
     * @param tenantId 租户 ID（从请求头获取）
     * @param page     当前页码（从1开始，默认1）
     * @param pageSize 每页条数（默认10）
     * @param keyword  搜索关键词（可选）
     * @return 分页结果
     */
    @GetMapping
    @Operation(summary = "分页查询用户列表", description = "支持按登录名和用户名模糊搜索")
    public ApiResult<PageResult<UserEntity>> list(
            @RequestHeader("X-Tenant-Id") Long tenantId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String keyword) {
        log.debug("分页查询用户请求 | tenantId={} | page={} | pageSize={} | keyword={}",
                tenantId, page, pageSize, keyword);
        PageResult<UserEntity> result = userService.list(tenantId, keyword, page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * 获取用户详情。
     *
     * <p>返回用户基本信息及角色编码列表。</p>
     *
     * @param id 用户 ID
     * @return 用户详情（不含密码，含角色编码列表）
     */
    @GetMapping("/{id}")
    @Operation(summary = "获取用户详情", description = "返回用户基本信息及角色编码列表")
    public ApiResult<UserEntity> getUserById(@PathVariable Long id) {
        log.debug("查询用户详情 | userId={}", id);
        UserEntity user = userService.findById(id);
        if (user == null) {
            log.warn("用户不存在 | userId={}", id);
            return ApiResult.error(ErrorCode.USER_NOT_FOUND.getCode(), ErrorCode.USER_NOT_FOUND.getMessage());
        }
        return ApiResult.success(user);
    }

    /**
     * 更新用户基本信息。
     *
     * <p>支持更新用户名、手机号、邮箱等基本信息。密码变更需通过独立的密码修改接口。</p>
     *
     * @param id      用户 ID
     * @param request 更新请求体
     * @return 更新后的用户信息
     */
    @PutMapping("/{id}")
    @Operation(summary = "更新用户信息", description = "修改用户基本信息（不含密码）")
    public ApiResult<UserEntity> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UserUpdateRequest request) {
        log.debug("更新用户信息 | userId={}", id);
        UserEntity user = new UserEntity();
        user.setId(id);
        user.setUserName(request.getUserName());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());

        UserEntity updated = userService.update(user);
        log.info("用户信息已更新 | userId={}", id);
        return ApiResult.success(updated);
    }

    /**
     * 逻辑删除用户。
     *
     * <p>将用户标记为已删除状态（deleted=1），已删除用户无法通过查询接口获取。</p>
     *
     * @param id 用户 ID
     * @return 操作结果
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "逻辑删除用户", description = "将用户标记为已删除状态")
    public ApiResult<Void> deleteUser(@PathVariable Long id) {
        log.debug("删除用户 | userId={}", id);
        userService.delete(id);
        log.info("用户已删除 | userId={}", id);
        return ApiResult.success();
    }

    /**
     * 全量更新用户角色。
     *
     * <p>先删除用户现有角色关联，再插入传入的角色 ID 列表（先删后插）。</p>
     *
     * @param id      用户 ID
     * @param request 角色分配请求体，包含角色 ID 列表
     * @return 操作结果
     */
    @PutMapping("/{id}/roles")
    @Operation(summary = "分配用户角色", description = "全量更新用户角色（先删后插）")
    public ApiResult<Void> assignRoles(
            @PathVariable Long id,
            @Valid @RequestBody AssignRolesRequest request) {
        log.debug("分配用户角色 | userId={} | roleCount={}", id, request.getRoleIds().size());
        userService.assignRoles(id, request.getRoleIds());
        log.info("用户角色已分配 | userId={} | roleCount={}", id, request.getRoleIds().size());
        return ApiResult.success();
    }

    /**
     * 变更用户状态。
     *
     * <p>支持以下状态变更：</p>
     * <ul>
     *   <li><strong>0</strong> — 恢复正常</li>
     *   <li><strong>1</strong> — 停用</li>
     *   <li><strong>2</strong> — 锁定（同步更新 Redis 缓存）</li>
     *   <li><strong>3</strong> — 封禁（同步清除所有登录态会话）</li>
     * </ul>
     *
     * @param id      用户 ID
     * @param request 状态变更请求体
     * @return 操作结果
     */
    @PutMapping("/{id}/status")
    @Operation(summary = "变更用户状态", description = "支持正常/停用/锁定/封禁四种状态切换")
    public ApiResult<Void> updateStatus(
            @PathVariable Long id,
            @Valid @RequestBody UserStatusRequest request) {
        log.debug("变更用户状态 | userId={} | status={}", id, request.getStatus());
        userService.updateStatus(id, request.getStatus(), request.getLockReason());
        log.info("用户状态已变更 | userId={} | status={}", id, request.getStatus());
        return ApiResult.success();
    }
}
