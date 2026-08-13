-- ============================================================
-- CloudStrollOffice（云漫智企）数据库脚本（DBD 配套 SQL）
-- 版本：v0.2.8（cloudoffice-common 服务化改造与通用配置管理接口先行）
-- 生成日期：2026-08-13
-- 数据库：MariaDB 10.6 LTS（兼容 MySQL 5.7+）
-- 字符集：utf8mb4 | 排序规则：utf8mb4_general_ci
--
-- 变更说明：
--   v0.2.8 为"cloudoffice-common 服务化改造与通用配置管理接口先行"版本
--   （详见 PRD v0.2.8 与 SAD v0.2.8 ADR-017/ADR-018/ADR-019）：
--     1. 新建数据库 cloudstroll_office_common（通用配置库）
--     2. 新建通用配置表 t_common_config（存储五个微服务运行时配置项）
--     3. 初始化配置种子数据（验证码策略/密码策略/Token 有效期/功能开关等）
--
--   本版本【仅新增】数据库与表，不修改既有 cloudstroll_office_auth 的
--   9 张认证业务表结构与数据，不影响 cloudstroll_office_biz/
--   cloudstroll_office_system 预留库。
--
--   既有 v0.0.1 基线的建库建表与初始数据语句见本文件上文
--   （docs/cso-dbd.sql 全量基线内容），本版本仅追加 v0.2.8 变更部分。
--
-- 使用方式：
--   本脚本可重复执行（幂等，使用 CREATE DATABASE IF NOT EXISTS /
--   CREATE TABLE IF NOT EXISTS / INSERT IGNORE）。
--   mysql -u root -p < cso-dbd-v0.2.8.sql
-- ============================================================

-- ============================================================
-- 第一部分：建库（v0.2.8 新增）
-- ============================================================

CREATE DATABASE IF NOT EXISTS `cloudstroll_office_common`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

-- ============================================================
-- 第二部分：通用配置库（cloudstroll_office_common）
-- 说明：存储 gateway/auth-service/biz-service/system-service/common
--       五个微服务在不同业务场景下的所有运行时配置项
--       （启动环境变量除外）
-- 模块：cloudoffice-common（端口 9300）
-- 关联功能：F-003 通用配置管理-查询接口、F-004 配置范围、F-005 扩展预留
-- ============================================================

USE `cloudstroll_office_common`;

-- ------------------------------------------------------------
-- 2.1 通用配置表 - t_common_config
-- 说明：存储五个微服务的运行时配置项，按 service_name +
--       config_group + config_key 三维定位，三者组合唯一。
--       配置查询接口优先命中 Redis 本地缓存，缓存未命中时
--       回源本表查询并回填缓存。
-- 关联功能：F-003/F-004/F-005
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `t_common_config` (
    `id`            BIGINT(20)   NOT NULL                    COMMENT '配置项ID（雪花算法）',
    `service_name`  VARCHAR(50)  NOT NULL                    COMMENT '微服务名称（gateway/auth-service/biz-service/system-service/common）',
    `config_group`  VARCHAR(50)  NOT NULL                    COMMENT '配置分组（业务场景分组，如 security/business/rate-limit 等）',
    `config_key`    VARCHAR(100) NOT NULL                    COMMENT '配置键（同一微服务同一分组下唯一）',
    `config_value`  TEXT         DEFAULT NULL                COMMENT '配置值（支持字符串/数字/布尔/JSON，由 data_type 标注类型）',
    `data_type`     VARCHAR(20)  NOT NULL DEFAULT 'string'   COMMENT '数据类型：string/number/boolean/json',
    `description`   VARCHAR(500) DEFAULT NULL                COMMENT '配置描述（说明配置项用途与取值范围）',
    `sensitive`     TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '是否敏感配置：0-非敏感 1-敏感（查询时脱敏或排除）',
    `status`        TINYINT(4)   NOT NULL DEFAULT 0          COMMENT '状态：0-启用 1-禁用',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`       TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_service_group_key` (`service_name`, `config_group`, `config_key`) USING BTREE COMMENT '同一微服务同一分组下配置键唯一',
    KEY `idx_service_name` (`service_name`) USING BTREE COMMENT '按微服务名称查询配置项',
    KEY `idx_config_group` (`service_name`, `config_group`) USING BTREE COMMENT '按微服务名称+配置分组查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='通用配置表';

-- ============================================================
-- 第三部分：初始数据（Seed Data，v0.2.8 新增）
-- 说明：插入五个微服务的基础运行时配置项初始数据
--       使用 INSERT IGNORE 确保重复执行时不会报错
--       硬编码 ID 从 1 起始（雪花算法，开发环境）
-- ============================================================

USE `cloudstroll_office_common`;

-- ------------------------------------------------------------
-- 3.1 auth-service 配置项（验证码策略 / 密码策略 / Token / 会话）
-- ------------------------------------------------------------

-- 验证码策略
INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (1, 'auth-service', 'verification', 'code-length',              '6',    'number',  '验证码长度（位数）',                 0, 0, NOW(), NOW(), 0),
    (2, 'auth-service', 'verification', 'code-expire-minutes',      '5',    'number',  '验证码有效期（分钟）',               0, 0, NOW(), NOW(), 0),
    (3, 'auth-service', 'verification', 'send-interval-seconds',    '60',   'number',  '验证码发送频率限制（秒）',           0, 0, NOW(), NOW(), 0),
    (4, 'auth-service', 'verification', 'max-send-count',          '5',    'number',  '验证码最大发送次数',                 0, 0, NOW(), NOW(), 0),
    (5, 'auth-service', 'verification', 'mock-mode',                'true', 'boolean', '验证码模拟模式（开发环境直接返回固定验证码）', 0, 0, NOW(), NOW(), 0);

-- 密码策略
INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (6,  'auth-service', 'password', 'min-length', '8',  'number', '密码最小长度', 0, 0, NOW(), NOW(), 0),
    (7,  'auth-service', 'password', 'max-length', '64', 'number', '密码最大长度', 0, 0, NOW(), NOW(), 0);

-- Token 策略
INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (8, 'auth-service', 'token', 'access-token-expire-hours',  '2', 'number', 'Access Token 有效期（小时）', 0, 0, NOW(), NOW(), 0),
    (9, 'auth-service', 'token', 'refresh-token-expire-days',  '7', 'number', 'Refresh Token 有效期（天）', 0, 0, NOW(), NOW(), 0);

-- 会话策略
INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (10, 'auth-service', 'session', 'same-client-mutex', 'true', 'boolean', '同端互斥登录（同客户端类型新登录踢旧登录）', 0, 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 3.2 gateway 配置项（安全 / CORS / 限流）
-- ------------------------------------------------------------

INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (11, 'gateway', 'security',  'whitelist-paths',   '/api/v1/auth/login,/api/v1/auth/register,/api/v1/auth/refresh,/api/v1/auth/send-code,/api/v1/auth/forgot-password,/api/v1/*/health', 'string', '网关白名单路径（逗号分隔，无需 Token 访问）', 0, 0, NOW(), NOW(), 0),
    (12, 'gateway', 'cors',      'allowed-origins',    '*',     'string',  'CORS 允许来源',           0, 0, NOW(), NOW(), 0),
    (13, 'gateway', 'rate-limit', 'enabled',           'false', 'boolean', '网关限流开关（后续版本启用）', 0, 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 3.3 common 配置项（配置管理自身参数）
-- ------------------------------------------------------------

INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (14, 'common', 'config', 'cache-ttl-seconds', '300',   'number', '通用配置本地缓存 TTL（秒）', 0, 0, NOW(), NOW(), 0),
    (15, 'common', 'config', 'sensitive-mask',    '****',  'string', '敏感配置脱敏掩码',           0, 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 3.4 biz-service 配置项（业务服务功能开关）
-- ------------------------------------------------------------

INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (16, 'biz-service', 'business', 'enabled', 'true', 'boolean', '业务服务功能开关', 0, 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 3.5 system-service 配置项（系统服务功能开关）
-- ------------------------------------------------------------

INSERT IGNORE INTO `t_common_config` (`id`, `service_name`, `config_group`, `config_key`, `config_value`, `data_type`, `description`, `sensitive`, `status`, `create_time`, `update_time`, `deleted`)
VALUES
    (17, 'system-service', 'business', 'enabled', 'true', 'boolean', '系统服务功能开关', 0, 0, NOW(), NOW(), 0);

-- ============================================================
-- 脚本结束
-- ============================================================
-- 附：v0.2.8 版本数据库对象变更清单
-- ============================================================
-- 新增数据库：
--   cloudstroll_office_common（通用配置库）
--
-- 新增业务表（1 张）：
--   t_common_config（通用配置表）
--
-- 新增索引：
--   主键索引 1 个（PRIMARY）
--   唯一索引 1 个（uk_service_group_key: service_name + config_group + config_key）
--   普通索引 2 个（idx_service_name / idx_config_group）
--
-- 新增初始数据：
--   t_common_config 种子数据 17 条（覆盖 5 个微服务基础运行时配置）
--
-- 视图 / 存储过程 / 触发器：无
--
-- 既有数据库与表（cloudstroll_office_auth 9 张表、biz/system 预留库）：
--   无变更，沿用 v0.0.1 基线
-- ============================================================