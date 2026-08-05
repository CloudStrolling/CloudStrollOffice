-- ============================================================
-- CloudStrollOffice 数据库初始化脚本
-- 字符集：utf8mb4 | 排序规则：utf8mb4_general_ci
-- ============================================================

-- 清空并重建数据库 -------------------------------------------------

DROP DATABASE IF EXISTS `cloudstroll_office_auth`;
CREATE DATABASE IF NOT EXISTS `cloudstroll_office_auth`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

DROP DATABASE IF EXISTS `cloudstroll_office_biz`;
CREATE DATABASE IF NOT EXISTS `cloudstroll_office_biz`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

DROP DATABASE IF EXISTS `cloudstroll_office_system`;
CREATE DATABASE IF NOT EXISTS `cloudstroll_office_system`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

-- 切换至 auth 数据库，创建业务表 --------------------------------

USE `cloudstroll_office_auth`;

-- 用户表
CREATE TABLE IF NOT EXISTS `t_auth_user` (
    `id`          BIGINT(20)   NOT NULL        COMMENT '主键（雪花算法）',
    `login_name`  VARCHAR(50)  NOT NULL        COMMENT '登录名',
    `password`    VARCHAR(255) NOT NULL        COMMENT '密码（BCrypt加密）',
    `real_name`   VARCHAR(50)  DEFAULT NULL    COMMENT '真实姓名',
    `email`       VARCHAR(100) DEFAULT NULL    COMMENT '邮箱',
    `phone`       VARCHAR(20)  DEFAULT NULL    COMMENT '手机号',
    `avatar`      VARCHAR(500) DEFAULT NULL    COMMENT '头像URL',
    `status`      TINYINT(4)   DEFAULT 0       COMMENT '状态（0-正常，1-禁用）',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     TINYINT(4)   DEFAULT 0       COMMENT '逻辑删除（0-正常，1-删除）',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_auth_user_login_name` (`login_name`) USING BTREE,
    KEY `idx_auth_user_status` (`status`) USING BTREE,
    KEY `idx_auth_user_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户表';
