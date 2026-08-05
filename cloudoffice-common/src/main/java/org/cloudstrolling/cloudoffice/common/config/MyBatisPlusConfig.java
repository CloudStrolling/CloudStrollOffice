package org.cloudstrolling.cloudoffice.common.config;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;

/**
 * MyBatis-Plus 自动填充处理器
 * <p>
 * 配合 {@link org.cloudstrolling.cloudoffice.common.model.BaseEntity} 使用，
 * 在 INSERT / UPDATE 时自动填充 createTime、updateTime、deleted 字段。
 * </p>
 *
 * @author CloudStroll Office
 */
@Configuration
public class MyBatisPlusConfig implements MetaObjectHandler {

    /**
     * 插入时自动填充
     * <ul>
     *   <li>createTime → 当前时间</li>
     *   <li>updateTime → 当前时间</li>
     *   <li>deleted → 0（正常）</li>
     * </ul>
     */
    @Override
    public void insertFill(MetaObject metaObject) {
        this.strictInsertFill(metaObject, "createTime", LocalDateTime.class, LocalDateTime.now());
        this.strictInsertFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
        this.strictInsertFill(metaObject, "deleted", Integer.class, 0);
    }

    /**
     * 更新时自动填充
     * <ul>
     *   <li>updateTime → 当前时间</li>
     * </ul>
     */
    @Override
    public void updateFill(MetaObject metaObject) {
        this.strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
    }
}
