package org.cloudstrolling.cloudoffice.common.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.cloudstrolling.cloudoffice.common.model.BaseEntity;

/**
 * 通用配置实体（t_common_config）。
 *
 * <p>存储 gateway/auth-service/biz-service/system-service/common 五个微服务
 * 在不同业务场景下的所有运行时配置项（启动环境变量除外）。
 * 按 service_name + config_group + config_key 三维定位，三者组合唯一。</p>
 *
 * @author CloudStroll Office
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_common_config")
public class ConfigEntity extends BaseEntity {

    /** 微服务名称（gateway/auth-service/biz-service/system-service/common） */
    @TableField("service_name")
    private String serviceName;

    /** 配置分组（业务场景分组，如 security/business/rate-limit 等） */
    @TableField("config_group")
    private String configGroup;

    /** 配置键（同一微服务同一分组下唯一） */
    @TableField("config_key")
    private String configKey;

    /** 配置值（支持字符串/数字/布尔值/JSON，由 data_type 标注类型） */
    @TableField("config_value")
    private String configValue;

    /** 数据类型：string/number/boolean/json */
    @TableField("data_type")
    private String dataType;

    /** 配置描述（说明配置项用途与取值范围） */
    private String description;

    /** 是否敏感配置：0-非敏感 1-敏感（查询接口返回时脱敏或排除） */
    private Integer sensitive;

    /** 状态：0-启用 1-禁用 */
    private Integer status;
}
