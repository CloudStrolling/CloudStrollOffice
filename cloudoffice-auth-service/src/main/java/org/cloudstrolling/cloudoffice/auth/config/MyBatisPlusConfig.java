package org.cloudstrolling.cloudoffice.auth.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.apache.ibatis.reflection.MetaObject;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;

/**
 * MyBatis-Plus 配置类。
 *
 * <p>配置 Mapper 扫描路径、分页插件、自动填充处理器等功能。</p>
 *
 * <ul>
 *   <li>Mapper 扫描：{@code org.cloudstrolling.cloudoffice.auth.mapper}</li>
 *   <li>分页插件：MariaDB 分页方言</li>
 *   <li>自动填充：插入时填充 createTime / updateTime / deleted，
 *       更新时填充 updateTime</li>
 * </ul>
 *
 * @author CloudStroll Office
 */
@Configuration
@MapperScan("org.cloudstrolling.cloudoffice.auth.mapper")
public class MyBatisPlusConfig {

    /**
     * MyBatis-Plus 分页拦截器。
     *
     * <p>使用 {@link PaginationInnerInterceptor} 并指定 MariaDB 方言，
     * 支持分页查询功能。</p>
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
     * 自动填充处理器。
     *
     * <p>配合 {@link org.cloudstrolling.cloudoffice.common.model.BaseEntity} 使用，
     * 在 INSERT / UPDATE 时自动填充审计字段。</p>
     *
     * <ul>
     *   <li>insertFill：createTime、updateTime 为当前时间，deleted 为 0</li>
     *   <li>updateFill：updateTime 为当前时间</li>
     * </ul>
     *
     * @return MetaObjectHandler
     */
    @Bean
    public MetaObjectHandler metaObjectHandler() {
        return new MetaObjectHandler() {
            @Override
            public void insertFill(MetaObject metaObject) {
                this.strictInsertFill(metaObject, "createTime", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "deleted", Integer.class, 0);
            }

            @Override
            public void updateFill(MetaObject metaObject) {
                this.strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
            }
        };
    }
}
