/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BaseEntity 基础实体测试。
 * <p>
 * 通过匿名子类验证 Lombok @Data 生成的 getter/setter，
 * 以及 MyBatis-Plus 注解的存在性和配置。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("BaseEntity 基础实体测试")
class BaseEntityTest {

    @Test
    @DisplayName("匿名子类应具有所有字段并通过 Lombok getter/setter 访问")
    void anonymousSubclass_shouldHaveAllFields() {
        // 创建匿名子类实例
        BaseEntity entity = new BaseEntity() {};
        LocalDateTime now = LocalDateTime.now();

        // 验证 setter 正常
        entity.setId(12345L);
        entity.setCreateTime(now);
        entity.setUpdateTime(now);
        entity.setDeleted(0);

        // 验证 getter 返回值
        assertEquals(12345L, entity.getId());
        assertEquals(now, entity.getCreateTime());
        assertEquals(now, entity.getUpdateTime());
        assertEquals(0, entity.getDeleted());
    }

    @Test
    @DisplayName("id 字段应具有 @TableId(type = IdType.ASSIGN_ID) 注解")
    void idField_shouldHaveTableIdAnnotation() throws Exception {
        Field idField = BaseEntity.class.getDeclaredField("id");
        TableId tableId = idField.getAnnotation(TableId.class);

        assertNotNull(tableId, "id 字段缺少 @TableId 注解");
        assertEquals(IdType.ASSIGN_ID, tableId.type(),
                "@TableId 的 type 应为 ASSIGN_ID（雪花算法）");
    }

    @Test
    @DisplayName("createTime 字段应具有 @TableField(fill = FieldFill.INSERT) 注解")
    void createTimeField_shouldHaveInsertFillAnnotation() throws Exception {
        Field field = BaseEntity.class.getDeclaredField("createTime");
        TableField tableField = field.getAnnotation(TableField.class);

        assertNotNull(tableField, "createTime 字段缺少 @TableField 注解");
        assertEquals(FieldFill.INSERT, tableField.fill(),
                "createTime 的 fill 策略应为 INSERT");
    }

    @Test
    @DisplayName("updateTime 字段应具有 @TableField(fill = FieldFill.INSERT_UPDATE) 注解")
    void updateTimeField_shouldHaveInsertUpdateFillAnnotation() throws Exception {
        Field field = BaseEntity.class.getDeclaredField("updateTime");
        TableField tableField = field.getAnnotation(TableField.class);

        assertNotNull(tableField, "updateTime 字段缺少 @TableField 注解");
        assertEquals(FieldFill.INSERT_UPDATE, tableField.fill(),
                "updateTime 的 fill 策略应为 INSERT_UPDATE");
    }

    @Test
    @DisplayName("deleted 字段应具有 @TableLogic 和 @TableField(fill = FieldFill.INSERT) 注解")
    void deletedField_shouldHaveTableLogicAndInsertFillAnnotation() throws Exception {
        Field field = BaseEntity.class.getDeclaredField("deleted");
        TableLogic tableLogic = field.getAnnotation(TableLogic.class);
        TableField tableField = field.getAnnotation(TableField.class);

        assertNotNull(tableLogic, "deleted 字段缺少 @TableLogic 注解");
        assertNotNull(tableField, "deleted 字段缺少 @TableField 注解");
        assertEquals(FieldFill.INSERT, tableField.fill(),
                "deleted 的 fill 策略应为 INSERT");
    }
}
