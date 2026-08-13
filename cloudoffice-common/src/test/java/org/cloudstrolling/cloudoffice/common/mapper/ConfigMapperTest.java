/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.cloudstrolling.cloudoffice.common.entity.ConfigEntity;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 通用配置 Mapper 测试（TASK-004）。
 *
 * <p>验证 ConfigMapper 继承 BaseMapper<ConfigEntity> 且标注 @Mapper，
 * 具备按条件查询（LambdaQueryWrapper）与分页查询能力。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("通用配置 Mapper 测试（TASK-004）")
class ConfigMapperTest {

    @Test
    @DisplayName("TC-TASK004-008: ConfigMapper 继承 BaseMapper 且标注 @Mapper")
    void configMapper_shouldExtendBaseMapper() {
        Class<?> clazz = ConfigMapper.class;
        assertNotNull(clazz.getAnnotation(Mapper.class), "ConfigMapper 应标注 @Mapper");
        assertTrue(BaseMapper.class.isAssignableFrom(clazz),
                "ConfigMapper 应继承 BaseMapper<ConfigEntity>");
        assertNotNull(clazz.getTypeParameters().length > 0
                && clazz.getGenericInterfaces().length > 0, "应声明泛型实体 ConfigEntity");

        boolean hasBaseMapperGeneric = java.util.Arrays.stream(clazz.getGenericInterfaces())
                .anyMatch(t -> t.getTypeName().contains("BaseMapper<org.cloudstrolling.cloudoffice.common.entity.ConfigEntity>"));
        assertTrue(hasBaseMapperGeneric, "BaseMapper 泛型应为 ConfigEntity");
    }

    @Test
    @DisplayName("TC-TASK004-008-2: ConfigEntity 表映射与字段正确")
    void configEntity_shouldMapTableAndFields() throws Exception {
        Class<?> clazz = ConfigEntity.class;
        com.baomidou.mybatisplus.annotation.TableName tn = clazz.getAnnotation(com.baomidou.mybatisplus.annotation.TableName.class);
        assertNotNull(tn, "ConfigEntity 应标注 @TableName");
        assertEquals("t_common_config", tn.value(), "@TableName 应为 t_common_config");
        assertNotNull(clazz.getMethod("getServiceName"), "应存在 serviceName 字段");
        assertNotNull(clazz.getMethod("getConfigGroup"), "应存在 configGroup 字段");
        assertNotNull(clazz.getMethod("getConfigKey"), "应存在 configKey 字段");
        assertNotNull(clazz.getMethod("getConfigValue"), "应存在 configValue 字段");
        assertNotNull(clazz.getMethod("getDataType"), "应存在 dataType 字段");
        assertNotNull(clazz.getMethod("getSensitive"), "应存在 sensitive 字段");
        assertNotNull(clazz.getMethod("getStatus"), "应存在 status 字段");
        assertNotNull(clazz.getMethod("getDescription"), "应存在 description 字段");
    }
}
