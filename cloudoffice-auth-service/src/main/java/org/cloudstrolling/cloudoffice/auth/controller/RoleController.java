/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.service.RoleService;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * 角色管理控制器。
 *
 * <p>提供角色的分页查询、全量列表、详情查询、创建、更新、删除
 * 以及权限分配等 RESTful API 端点。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth/roles")
@RequiredArgsConstructor
@Tag(name = "角色管理", description = "角色 CRUD 及权限分配接口")
public class RoleController {

    private final RoleService roleService;

    /**
     * 分页查询角色列表。
     *
     * @param page     页码（从 1 开始，默认 1）
     * @param pageSize 每页大小（默认 10）
     * @param tenantId 租户 ID
     * @return 统一分页响应
     */
    @GetMapping
    @Operation(summary = "分页查询角色列表", description = "根据租户 ID 分页查询角色列表，支持页码和每页大小参数")
    public ApiResult<PageResult<RoleEntity>> list(
            @Parameter(description = "页码，从1开始") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页大小") @RequestParam(defaultValue = "10") int pageSize,
            @Parameter(description = "租户 ID") @RequestParam Long tenantId) {
        log.debug("分页查询角色 | tenantId={} | page={} | pageSize={}", tenantId, page, pageSize);
        PageResult<RoleEntity> result = roleService.list(tenantId, page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * 查询所有角色（不分页）。
     *
     * @param tenantId 租户 ID
     * @return 统一响应，包含角色列表
     */
    @GetMapping("/list")
    @Operation(summary = "查询所有角色", description = "根据租户 ID 查询所有角色，不分页")
    public ApiResult<List<RoleEntity>> listAll(
            @Parameter(description = "租户 ID") @RequestParam Long tenantId) {
        log.debug("查询所有角色 | tenantId={}", tenantId);
        List<RoleEntity> roles = roleService.listAll(tenantId);
        return ApiResult.success(roles);
    }

    /**
     * 查询角色详情。
     *
     * @param id 角色 ID
     * @return 统一响应，包含角色信息
     */
    @GetMapping("/{id}")
    @Operation(summary = "查询角色详情", description = "根据角色 ID 查询角色详细信息")
    public ApiResult<RoleEntity> findById(
            @Parameter(description = "角色 ID") @PathVariable Long id) {
        log.debug("查询角色详情 | roleId={}", id);
        RoleEntity role = roleService.findById(id);
        return ApiResult.success(role);
    }

    /**
     * 创建角色。
     *
     * @param role 角色信息（需包含 tenantId、roleName、roleCode）
     * @return 统一响应，包含创建后的角色信息
     */
    @PostMapping
    @Operation(summary = "创建角色", description = "创建新角色，需指定租户 ID、角色名称和角色编码")
    public ApiResult<RoleEntity> create(
            @Parameter(description = "角色信息") @Valid @RequestBody RoleEntity role) {
        log.info("创建角色 | roleCode={} | roleName={}", role.getRoleCode(), role.getRoleName());
        RoleEntity created = roleService.create(role);
        return ApiResult.success(created);
    }

    /**
     * 更新角色。
     *
     * @param id   角色 ID
     * @param role 角色更新信息
     * @return 统一响应，包含更新后的角色信息
     */
    @PutMapping("/{id}")
    @Operation(summary = "更新角色", description = "根据角色 ID 更新角色信息")
    public ApiResult<RoleEntity> update(
            @Parameter(description = "角色 ID") @PathVariable Long id,
            @Parameter(description = "角色更新信息") @Valid @RequestBody RoleEntity role) {
        role.setId(id);
        log.info("更新角色 | roleId={}", id);
        RoleEntity updated = roleService.update(role);
        return ApiResult.success(updated);
    }

    /**
     * 删除角色。
     *
     * <p>若角色已被分配给用户，则返回错误提示。</p>
     *
     * @param id 角色 ID
     * @return 统一响应
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "删除角色", description = "根据角色 ID 逻辑删除角色，若角色已被分配则阻止删除")
    public ApiResult<Void> delete(
            @Parameter(description = "角色 ID") @PathVariable Long id) {
        log.info("删除角色 | roleId={}", id);
        roleService.delete(id);
        return ApiResult.success();
    }

    /**
     * 分配角色权限（全量更新）。
     *
     * <p>先删除当前角色的所有权限关联，再批量插入新的权限关联。</p>
     *
     * @param id      角色 ID
     * @param request 权限 ID 列表请求体
     * @return 统一响应
     */
    @PutMapping("/{id}/permissions")
    @Operation(summary = "分配角色权限", description = "全量更新角色的权限关联，传入权限 ID 列表")
    public ApiResult<Void> assignPermissions(
            @Parameter(description = "角色 ID") @PathVariable Long id,
            @Parameter(description = "权限 ID 列表") @RequestBody Map<String, List<Long>> request) {
        List<Long> permIds = request.get("permissionIds");
        log.info("分配角色权限 | roleId={} | permCount={}", id, permIds != null ? permIds.size() : 0);
        roleService.assignPermissions(id, permIds);
        return ApiResult.success();
    }
}
