package org.cloudstrolling.cloudoffice.common.vo;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 通用配置项视图对象（ConfigItemVO）。
 *
 * <p>通用配置管理查询接口（API-035/API-036）返回的配置项数据结构，
 * 字段与 DBD v0.2.8 中 t_common_config 表一一对应。</p>
 *
 * @author CloudStroll Office
 */
@Data
public class ConfigItemVO {

    /** 配置项 ID */
    private Long id;

    /** 微服务名称（gateway/auth-service/biz-service/system-service/common） */
    private String serviceName;

    /** 配置分组（业务场景分组，如 security/verification/password/token 等） */
    private String group;

    /** 配置键（精确匹配） */
    private String key;

    /** 配置值（敏感配置脱敏为掩码） */
    private String value;

    /** 数据类型（string/number/boolean/json） */
    private String dataType;

    /** 配置描述 */
    private String description;

    /** 是否敏感（true-敏感配置，查询时脱敏；false-非敏感） */
    private Boolean sensitive;

    /** 状态（0-启用/1-禁用） */
    private Integer status;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
