package org.cloudstrolling.cloudoffice.common.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;

/**
 * MyBatis-Plus 配置（自动填充处理器 + 分页插件）
 * <p>
 * 配合 {@link org.cloudstrolling.cloudoffice.common.model.BaseEntity} 使用，
 * 在 INSERT / UPDATE 时自动填充 createTime、updateTime、deleted 字段；
 * 同时注册 MariaDB 方言分页插件，支撑通用配置查询接口（API-035）的分页能力。
 * </p>
 *
 * @author CloudStroll Office
 */
@Configuration
public class MyBatisPlusConfig implements MetaObjectHandler {

    /**
     * MyBatis-Plus 分页拦截器（MariaDB 方言）。
     * <p>通用配置管理查询接口（API-035）使用 BaseMapper.selectPage 分页查询，
     * 必须注册分页插件，否则分页失效。</p>
     *
     * @return MybatisPlusInterceptor
     */
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MARIADB));
        return interceptor;
    }

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
