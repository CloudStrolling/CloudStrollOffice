package org.cloudstrolling.cloudoffice.common.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.cloudstrolling.cloudoffice.common.entity.ConfigEntity;

/**
 * 通用配置 Mapper（t_common_config）。
 *
 * <p>提供通用配置表的条件查询与按微服务名称查询能力（继承 {@link BaseMapper}），
 * 查询接口优先命中 Redis 本地缓存，缓存未命中时回源本表查询并回填缓存。
 * 本版本仅提供查询能力，写入能力（增删改）预留扩展点。</p>
 *
 * @author CloudStroll Office
 */
@Mapper
public interface ConfigMapper extends BaseMapper<ConfigEntity> {
}
