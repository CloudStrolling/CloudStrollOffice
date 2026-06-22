/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.dto;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.*;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * LoginUserDTO 登录用户信息 DTO 测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("LoginUserDTO 登录用户信息 DTO 测试")
class LoginUserDTOTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("无参构造 + 链式 setter 应正确设置字段值")
    void noArgsConstructor_withChainSetters_shouldSetFields() {
        // Given
        LoginUserDTO dto = new LoginUserDTO();
        List<String> roles = Arrays.asList("admin", "user");
        List<String> permissions = Arrays.asList("read", "write");

        // When
        LoginUserDTO result = dto
                .setUserId(1L)
                .setTenantId(100L)
                .setUserName("test_user")
                .setClientType("WEB")
                .setRoles(roles)
                .setPermissions(permissions);

        // Then
        assertSame(dto, result, "链式 setter 应返回同一对象");
        assertEquals(1L, dto.getUserId());
        assertEquals(100L, dto.getTenantId());
        assertEquals("test_user", dto.getUserName());
        assertEquals("WEB", dto.getClientType());
        assertSame(roles, dto.getRoles());
        assertSame(permissions, dto.getPermissions());
    }

    @Test
    @DisplayName("全参构造应正确设置所有字段")
    void allArgsConstructor_shouldSetAllFields() {
        // Given
        List<String> roles = Arrays.asList("admin", "user");
        List<String> permissions = Arrays.asList("read", "write");
        LoginUserDTO dto = new LoginUserDTO(
                1L,
                100L,
                "test_user",
                "WEB",
                roles,
                permissions
        );

        // Then
        assertEquals(1L, dto.getUserId());
        assertEquals(100L, dto.getTenantId());
        assertEquals("test_user", dto.getUserName());
        assertEquals("WEB", dto.getClientType());
        assertSame(roles, dto.getRoles());
        assertSame(permissions, dto.getPermissions());
    }

    @Test
    @DisplayName("Builder 模式应正确构建对象")
    void builder_shouldBuildObject() {
        // Given / When
        LoginUserDTO dto = LoginUserDTO.builder()
                .userId(2L)
                .tenantId(200L)
                .userName("builder_user")
                .clientType("APP")
                .roles(Arrays.asList("manager"))
                .permissions(Arrays.asList("approve"))
                .build();

        // Then
        assertEquals(2L, dto.getUserId());
        assertEquals(200L, dto.getTenantId());
        assertEquals("builder_user", dto.getUserName());
        assertEquals("APP", dto.getClientType());
        assertEquals(Collections.singletonList("manager"), dto.getRoles());
        assertEquals(Collections.singletonList("approve"), dto.getPermissions());
    }

    @Test
    @DisplayName("serialVersionUID 应存在且值为 1L")
    void serialVersionUID_shouldExist() throws Exception {
        // Given / When
        java.lang.reflect.Field field = LoginUserDTO.class.getDeclaredField("serialVersionUID");
        field.setAccessible(true);
        long serialVersionUID = field.getLong(null);

        // Then
        assertEquals(1L, serialVersionUID);
    }

    @Test
    @DisplayName("无参构造后 roles 和 permissions 应默认空列表")
    void noArgsConstructor_shouldHaveEmptyRolesAndPermissions() {
        // Given / When
        LoginUserDTO dto = new LoginUserDTO();

        // Then
        assertNotNull(dto.getRoles(), "roles 不应为 null");
        assertNotNull(dto.getPermissions(), "permissions 不应为 null");
        assertTrue(dto.getRoles().isEmpty(), "roles 应为空列表");
        assertTrue(dto.getPermissions().isEmpty(), "permissions 应为空列表");
    }

    @Test
    @DisplayName("Builder 模式下未设置 roles/permissions 应使用 @Builder.Default 空列表")
    void builder_withoutRolesAndPermissions_shouldUseDefaultEmptyList() {
        // Given / When
        LoginUserDTO dto = LoginUserDTO.builder()
                .userId(3L)
                .tenantId(300L)
                .userName("default_user")
                .clientType("WEB")
                .build();

        // Then
        assertNotNull(dto.getRoles(), "roles 不应为 null");
        assertNotNull(dto.getPermissions(), "permissions 不应为 null");
        assertTrue(dto.getRoles().isEmpty(), "roles 应为空列表");
        assertTrue(dto.getPermissions().isEmpty(), "permissions 应为空列表");
    }

    @Test
    @DisplayName("JSON 序列化和反序列化应正确保留字段值")
    void jsonSerialization_shouldPreserveFields() throws JsonProcessingException {
        // Given
        LoginUserDTO original = LoginUserDTO.builder()
                .userId(4L)
                .tenantId(400L)
                .userName("json_user")
                .clientType("WEB")
                .roles(Arrays.asList("admin", "user"))
                .permissions(Arrays.asList("create", "delete"))
                .build();

        // When
        String json = objectMapper.writeValueAsString(original);
        LoginUserDTO deserialized = objectMapper.readValue(json, LoginUserDTO.class);

        // Then
        assertEquals(original.getUserId(), deserialized.getUserId());
        assertEquals(original.getTenantId(), deserialized.getTenantId());
        assertEquals(original.getUserName(), deserialized.getUserName());
        assertEquals(original.getClientType(), deserialized.getClientType());
        assertEquals(original.getRoles(), deserialized.getRoles());
        assertEquals(original.getPermissions(), deserialized.getPermissions());
    }

    @Test
    @DisplayName("Java 对象序列化和反序列化应正确保留字段值")
    void javaSerialization_shouldPreserveFields() throws IOException, ClassNotFoundException {
        // Given
        LoginUserDTO original = LoginUserDTO.builder()
                .userId(5L)
                .tenantId(500L)
                .userName("ser_user")
                .clientType("APP")
                .roles(Arrays.asList("admin"))
                .permissions(Arrays.asList("read"))
                .build();

        // When
        byte[] bytes;
        try (ByteArrayOutputStream bos = new ByteArrayOutputStream();
             ObjectOutputStream oos = new ObjectOutputStream(bos)) {
            oos.writeObject(original);
            bytes = bos.toByteArray();
        }

        LoginUserDTO deserialized;
        try (ByteArrayInputStream bis = new ByteArrayInputStream(bytes);
             ObjectInputStream ois = new ObjectInputStream(bis)) {
            deserialized = (LoginUserDTO) ois.readObject();
        }

        // Then
        assertEquals(original.getUserId(), deserialized.getUserId());
        assertEquals(original.getTenantId(), deserialized.getTenantId());
        assertEquals(original.getUserName(), deserialized.getUserName());
        assertEquals(original.getClientType(), deserialized.getClientType());
        assertEquals(original.getRoles(), deserialized.getRoles());
        assertEquals(original.getPermissions(), deserialized.getPermissions());
    }
}
