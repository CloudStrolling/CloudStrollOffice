-- ============================================================
-- CloudStrollOffice 认证服务数据库 v0.1.6 增量DDL脚本
-- 数据库：cloudstroll_office_auth
-- 版本：v0.1.6
-- 数据库：MariaDB 10.6 LTS
-- 字符集：utf8mb4 | 排序规则：utf8mb4_general_ci
--
-- 说明：本脚本为增量执行脚本，基于 v0.1.5 数据库结构进行扩展
--       新增 t_auth_oauth_account 表、t_auth_verification_code 表
--       扩展 t_auth_user 表字段
-- 对应 UserStory：US-011, US-012, US-013
--
-- 执行方式：
--   1. 确保已先执行 auth-init-v0.1.5.sql 完成基础库创建
--   2. 连接到目标数据库后执行本脚本
--   3. 本脚本可重复执行（幂等），不会破坏已有数据
-- ============================================================

-- ============================================================
-- 切换到认证服务数据库
-- 注意：请确保数据库已存在（由 v0.1.5 脚本创建）
-- ============================================================
USE `cloudstroll_office_auth`;

-- ============================================================
-- 1. 新建 t_auth_oauth_account 表（OAuth第三方账号关联表）
-- 说明：存储用户与第三方 OAuth 账号的绑定关系，
--       支持一个用户绑定多个第三方账号
-- 关联 UserStory：US-011
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_oauth_account` (
    `id`              BIGINT(20)   NOT NULL                    COMMENT '主键ID（雪花算法）',
    `user_id`         BIGINT(20)   NOT NULL                    COMMENT '平台用户ID，关联 t_auth_user.id',
    `oauth_provider`  VARCHAR(32)  NOT NULL                    COMMENT 'OAuth提供商（WECHAT/DINGTALK/WECHAT_WORK/ALIPAY）',
    `oauth_open_id`   VARCHAR(256) NOT NULL                    COMMENT '第三方平台用户唯一标识（openId）',
    `oauth_union_id`  VARCHAR(256) DEFAULT NULL                COMMENT '第三方平台用户统一标识（unionId，可选）',
    `oauth_nickname`  VARCHAR(128) DEFAULT NULL                COMMENT '第三方平台昵称',
    `oauth_avatar`    VARCHAR(512) DEFAULT NULL                COMMENT '第三方平台头像URL',
    `bound_time`      DATETIME     DEFAULT NULL                COMMENT '绑定时间',
    `create_time`     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_time`     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    `deleted`         TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_provider_openid` (`oauth_provider`, `oauth_open_id`) USING BTREE COMMENT '同一OAuth提供商下openId唯一',
    KEY `idx_user_id` (`user_id`) USING BTREE COMMENT '按平台用户ID查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='OAuth第三方账号关联表';

-- ============================================================
-- 2. 新建 t_auth_verification_code 表（验证码记录表）
-- 说明：记录验证码的生成、发送、校验和使用状态，
--       支持验证码生命周期管理（生成→校验→过期→使用）
-- 关联 UserStory：US-012
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_verification_code` (
    `id`          BIGINT(20)   NOT NULL                    COMMENT '主键ID（雪花算法）',
    `target`      VARCHAR(128) NOT NULL                    COMMENT '发送目标（手机号或邮箱）',
    `code`        VARCHAR(16)  NOT NULL                    COMMENT '验证码内容（6位数字）',
    `send_mode`   VARCHAR(16)  NOT NULL                    COMMENT '发送方式（SMS/EMAIL）',
    `purpose`     VARCHAR(32)  NOT NULL                    COMMENT '用途（REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE）',
    `expire_time` DATETIME     NOT NULL                    COMMENT '过期时间（创建时间+5分钟）',
    `used`        TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '是否已使用：0-未使用 1-已使用',
    `used_time`   DATETIME     DEFAULT NULL                COMMENT '使用时间（标记为已使用时记录）',
    `send_count`  INT(11)      DEFAULT 0                   COMMENT '当日已发送次数',
    `create_time` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_time` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    `deleted`     TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `idx_target_purpose` (`target`, `purpose`) USING BTREE COMMENT '按发送目标和用途查询',
    KEY `idx_expire_time` (`expire_time`) USING BTREE COMMENT '按过期时间查询（用于清理过期记录）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='验证码记录表';

-- ============================================================
-- 3. 扩展 t_auth_user 表（用户表字段扩展）
-- 说明：新增注册模式、账号完善状态、验证状态等字段
--       所有新字段均设置兼容默认值，保证 v0.1.5 现有数据兼容
-- 关联 UserStory：US-013
-- 兼容性：已有用户记录的默认值说明
--   - register_mode     = 'USERNAME'（用户名密码注册）
--   - account_settled   = 1（已完善）
--   - phone_verified    = 0（未验证）
--   - email_verified    = 0（未验证）
--   - last_password_change_time = NULL（无记录）
-- ============================================================

-- 3.1 新增 register_mode 字段（注册模式标识）
ALTER TABLE `t_auth_user` ADD COLUMN IF NOT EXISTS `register_mode` VARCHAR(32) DEFAULT 'USERNAME' COMMENT '注册模式（USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO）';

-- 3.2 新增 account_settled 字段（账号信息是否完善）
ALTER TABLE `t_auth_user` ADD COLUMN IF NOT EXISTS `account_settled` TINYINT(1) DEFAULT 1 COMMENT '账号信息是否完善：0-未完善 1-已完善';

-- 3.3 新增 phone_verified 字段（手机号是否已验证）
ALTER TABLE `t_auth_user` ADD COLUMN IF NOT EXISTS `phone_verified` TINYINT(1) DEFAULT 0 COMMENT '手机号是否已验证：0-未验证 1-已验证';

-- 3.4 新增 email_verified 字段（邮箱是否已验证）
ALTER TABLE `t_auth_user` ADD COLUMN IF NOT EXISTS `email_verified` TINYINT(1) DEFAULT 0 COMMENT '邮箱是否已验证：0-未验证 1-已验证';

-- 3.5 新增 last_password_change_time 字段（最后修改密码时间）
ALTER TABLE `t_auth_user` ADD COLUMN IF NOT EXISTS `last_password_change_time` DATETIME DEFAULT NULL COMMENT '最后修改密码时间';

-- 3.6 可选索引：为 register_mode 字段创建索引（支持按注册模式筛选查询）
ALTER TABLE `t_auth_user` ADD INDEX IF NOT EXISTS `idx_register_mode` (`register_mode`) COMMENT '注册模式索引';

-- ============================================================
-- 结束
-- ============================================================
