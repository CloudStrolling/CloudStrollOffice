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

import static org.junit.jupiter.api.Assertions.*;

/**
 * TokenPairDTO 双 Token 响应 DTO 测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("TokenPairDTO 双 Token 响应 DTO 测试")
class TokenPairDTOTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("无参构造 + 链式 setter 应正确设置字段值")
    void noArgsConstructor_withChainSetters_shouldSetFields() {
        // Given
        TokenPairDTO dto = new TokenPairDTO();

        // When
        TokenPairDTO result = dto
                .setAccessToken("access_token_value")
                .setRefreshToken("refresh_token_value")
                .setAccessTokenExpireIn(3600L)
                .setRefreshTokenExpireIn(7200L)
                .setTokenType("Bearer");

        // Then
        assertSame(dto, result, "链式 setter 应返回同一对象");
        assertEquals("access_token_value", dto.getAccessToken());
        assertEquals("refresh_token_value", dto.getRefreshToken());
        assertEquals(3600L, dto.getAccessTokenExpireIn());
        assertEquals(7200L, dto.getRefreshTokenExpireIn());
        assertEquals("Bearer", dto.getTokenType());
    }

    @Test
    @DisplayName("全参构造应正确设置所有字段")
    void allArgsConstructor_shouldSetAllFields() {
        // Given
        TokenPairDTO dto = new TokenPairDTO(
                "access",
                "refresh",
                3600L,
                7200L,
                "Bearer"
        );

        // Then
        assertEquals("access", dto.getAccessToken());
        assertEquals("refresh", dto.getRefreshToken());
        assertEquals(3600L, dto.getAccessTokenExpireIn());
        assertEquals(7200L, dto.getRefreshTokenExpireIn());
        assertEquals("Bearer", dto.getTokenType());
    }

    @Test
    @DisplayName("Builder 模式应正确构建对象")
    void builder_shouldBuildObject() {
        // Given / When
        TokenPairDTO dto = TokenPairDTO.builder()
                .accessToken("builder_access")
                .refreshToken("builder_refresh")
                .accessTokenExpireIn(1800L)
                .refreshTokenExpireIn(3600L)
                .tokenType("Bearer")
                .build();

        // Then
        assertEquals("builder_access", dto.getAccessToken());
        assertEquals("builder_refresh", dto.getRefreshToken());
        assertEquals(1800L, dto.getAccessTokenExpireIn());
        assertEquals(3600L, dto.getRefreshTokenExpireIn());
        assertEquals("Bearer", dto.getTokenType());
    }

    @Test
    @DisplayName("serialVersionUID 应存在且值为 1L")
    void serialVersionUID_shouldExist() throws Exception {
        // Given / When
        java.lang.reflect.Field field = TokenPairDTO.class.getDeclaredField("serialVersionUID");
        field.setAccessible(true);
        long serialVersionUID = field.getLong(null);

        // Then
        assertEquals(1L, serialVersionUID);
    }

    @Test
    @DisplayName("无参构造后字段默认值应为 null（非原始类型）")
    void noArgsConstructor_shouldSetDefaultsToNull() {
        // Given / When
        TokenPairDTO dto = new TokenPairDTO();

        // Then
        assertNull(dto.getAccessToken());
        assertNull(dto.getRefreshToken());
        assertNull(dto.getAccessTokenExpireIn());
        assertNull(dto.getRefreshTokenExpireIn());
        assertNull(dto.getTokenType());
    }

    @Test
    @DisplayName("JSON 序列化和反序列化应正确保留字段值")
    void jsonSerialization_shouldPreserveFields() throws JsonProcessingException {
        // Given
        TokenPairDTO original = TokenPairDTO.builder()
                .accessToken("json_access")
                .refreshToken("json_refresh")
                .accessTokenExpireIn(3600L)
                .refreshTokenExpireIn(7200L)
                .tokenType("Bearer")
                .build();

        // When
        String json = objectMapper.writeValueAsString(original);
        TokenPairDTO deserialized = objectMapper.readValue(json, TokenPairDTO.class);

        // Then
        assertEquals(original.getAccessToken(), deserialized.getAccessToken());
        assertEquals(original.getRefreshToken(), deserialized.getRefreshToken());
        assertEquals(original.getAccessTokenExpireIn(), deserialized.getAccessTokenExpireIn());
        assertEquals(original.getRefreshTokenExpireIn(), deserialized.getRefreshTokenExpireIn());
        assertEquals(original.getTokenType(), deserialized.getTokenType());
    }

    @Test
    @DisplayName("Java 对象序列化和反序列化应正确保留字段值")
    void javaSerialization_shouldPreserveFields() throws IOException, ClassNotFoundException {
        // Given
        TokenPairDTO original = TokenPairDTO.builder()
                .accessToken("ser_access")
                .refreshToken("ser_refresh")
                .accessTokenExpireIn(3600L)
                .refreshTokenExpireIn(7200L)
                .tokenType("Bearer")
                .build();

        // When
        byte[] bytes;
        try (ByteArrayOutputStream bos = new ByteArrayOutputStream();
             ObjectOutputStream oos = new ObjectOutputStream(bos)) {
            oos.writeObject(original);
            bytes = bos.toByteArray();
        }

        TokenPairDTO deserialized;
        try (ByteArrayInputStream bis = new ByteArrayInputStream(bytes);
             ObjectInputStream ois = new ObjectInputStream(bis)) {
            deserialized = (TokenPairDTO) ois.readObject();
        }

        // Then
        assertEquals(original.getAccessToken(), deserialized.getAccessToken());
        assertEquals(original.getRefreshToken(), deserialized.getRefreshToken());
        assertEquals(original.getAccessTokenExpireIn(), deserialized.getAccessTokenExpireIn());
        assertEquals(original.getRefreshTokenExpireIn(), deserialized.getRefreshTokenExpireIn());
        assertEquals(original.getTokenType(), deserialized.getTokenType());
    }
}
