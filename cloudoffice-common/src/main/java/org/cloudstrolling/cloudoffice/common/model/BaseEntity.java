package org.cloudstrolling.cloudoffice.common.model;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 基础实体类，所有数据库实体均继承此类
 * <p>
 * 提供统一的 id、createTime、updateTime、deleted 字段，
 * 配合 MyBatis-Plus 自动填充处理器完成字段自动赋值。
 * </p>
 *
 * @author CloudStroll Office
 */
@Data
public abstract class BaseEntity {

    /**
     * 主键 ID，使用雪花算法自动分配
     */
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * 创建时间，插入时自动填充
     */
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    /**
     * 更新时间，插入和更新时自动填充
     */
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    /**
     * 逻辑删除标记（0-正常，1-已删除），插入时默认 0
     */
    @TableLogic
    @TableField(fill = FieldFill.INSERT)
    private Integer deleted;
}
