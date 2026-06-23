/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.PermissionEntity;
import org.cloudstrolling.cloudoffice.auth.service.PermissionService;
import org.cloudstrolling.cloudoffice.auth.vo.PermissionVO;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 权限管理控制器。
 *
 * <p>提供权限的树形查询、CRUD 操作等 REST API 端点。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth/permissions")
@Tag(name = "权限管理", description = "权限的树形查询、CRUD 操作等接口")
public class PermissionController {

    private final PermissionService permissionService;

    /**
     * 构造器注入。
     *
     * @param permissionService 权限业务服务
     */
    public PermissionController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    /**
     * 获取树形权限列表。
     *
     * <p>返回按 parent_id 自关联组织的树形权限结构，每个父权限包含子权限列表。</p>
     *
     * @return 树形结构的权限列表
     */
    @GetMapping("/tree")
    @Operation(summary = "树形权限列表", description = "获取按 parent_id 组织的树形权限结构")
    public ApiResult<List<PermissionVO>> tree() {
        List<PermissionVO> tree = permissionService.tree();
        return ApiResult.success(tree);
    }

    /**
     * 获取所有权限列表。
     *
     * @return 所有权限的列表
     */
    @GetMapping("/list")
    @Operation(summary = "所有权限列表", description = "获取所有权限的平铺列表")
    public ApiResult<List<PermissionEntity>> list() {
        List<PermissionEntity> list = permissionService.listAll();
        return ApiResult.success(list);
    }

    /**
     * 获取权限详情。
     *
     * @param id 权限 ID
     * @return 权限实体
     */
    @GetMapping("/{id}")
    @Operation(summary = "权限详情", description = "根据权限 ID 获取权限详细信息")
    public ApiResult<PermissionEntity> getById(@PathVariable("id") Long id) {
        PermissionEntity permission = permissionService.findById(id);
        if (permission == null) {
            return ApiResult.error(404, "权限不存在");
        }
        return ApiResult.success(permission);
    }

    /**
     * 创建权限。
     *
     * @param permission 权限实体（不包含 ID）
     * @return 创建成功的权限实体
     */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "创建权限", description = "创建一个新的权限点，perm_code 必须全局唯一")
    public ApiResult<PermissionEntity> create(@Valid @RequestBody PermissionEntity permission) {
        PermissionEntity created = permissionService.create(permission);
        log.info("权限创建 | permId={} | permCode={} | permName={}",
                created.getId(), created.getPermCode(), created.getPermName());
        return ApiResult.success(created);
    }

    /**
     * 更新权限。
     *
     * @param id         权限 ID
     * @param permission 更新后的权限实体
     * @return 更新后的权限实体
     */
    @PutMapping("/{id}")
    @Operation(summary = "更新权限", description = "根据权限 ID 更新权限信息")
    public ApiResult<PermissionEntity> update(@PathVariable("id") Long id,
                                              @Valid @RequestBody PermissionEntity permission) {
        permission.setId(id);
        PermissionEntity updated = permissionService.update(permission);
        log.info("权限更新 | permId={} | permCode={} | permName={}",
                updated.getId(), updated.getPermCode(), updated.getPermName());
        return ApiResult.success(updated);
    }

    /**
     * 删除权限。
     *
     * <p>逻辑删除权限。若权限已被角色关联则阻止删除。</p>
     *
     * @param id 权限 ID
     * @return 统一响应体
     */
    @DeleteMapping("/{id}")
    @Operation(summary = "删除权限", description = "逻辑删除权限（如已被角色关联则阻止删除）")
    public ApiResult<Void> delete(@PathVariable("id") Long id) {
        permissionService.delete(id);
        log.info("权限删除成功 | permId={}", id);
        return ApiResult.success();
    }
}
