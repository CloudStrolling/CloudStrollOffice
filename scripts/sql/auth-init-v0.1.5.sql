-- ============================================================
-- CloudStrollOffice 认证服务数据库初始化脚本
-- 数据库：cloudstroll_office_auth
-- 版本：v0.1.5
-- 数据库：MariaDB 10.6 LTS
-- 字符集：utf8mb4 | 排序规则：utf8mb4_general_ci
--
-- 说明：创建认证服务 7 张核心业务表及初始数据
-- 对应 UserStory：US-006, US-007, US-009, US-010, US-011, US-012, US-022
-- ============================================================

-- ============================================================
-- 清空并重建数据库（开发/测试环境使用，生产环境请手动创建数据库）
-- ============================================================
DROP DATABASE IF EXISTS `cloudstroll_office_auth`;
CREATE DATABASE IF NOT EXISTS `cloudstroll_office_auth`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `cloudstroll_office_auth`;

-- ============================================================
-- 1. 租户表 - t_auth_tenant
-- 说明：存储 SaaS 平台企业租户信息，支持状态控制和过期管理
-- 关联 UserStory：US-007
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_tenant` (
    `id`            BIGINT(20)   NOT NULL                    COMMENT '租户ID（雪花算法）',
    `tenant_name`   VARCHAR(100) NOT NULL                    COMMENT '租户名称',
    `tenant_code`   VARCHAR(50)  NOT NULL                    COMMENT '租户编码（唯一标识）',
    `contact_name`  VARCHAR(50)  DEFAULT NULL                COMMENT '联系人姓名',
    `contact_phone` VARCHAR(20)  DEFAULT NULL                COMMENT '联系人电话',
    `status`        TINYINT(4)   NOT NULL DEFAULT 0          COMMENT '状态：0-正常 1-禁用 2-过期',
    `expire_time`   DATETIME     DEFAULT NULL                COMMENT '过期时间（NULL 表示永不过期）',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`       TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_tenant_code` (`tenant_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='租户表';

-- ============================================================
-- 2. 用户表 - t_auth_user
-- 说明：存储平台用户账号信息，多租户隔离，用户名在租户内唯一
-- 关联 UserStory：US-006
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_user` (
    `id`              BIGINT(20)   NOT NULL                    COMMENT '用户ID（雪花算法）',
    `tenant_id`       BIGINT(20)   NOT NULL                    COMMENT '租户ID，关联 t_auth_tenant.id',
    `login_name`      VARCHAR(50)  NOT NULL                    COMMENT '登录名（租户内唯一）',
    `password`        VARCHAR(255) NOT NULL                    COMMENT '密码（BCrypt 加密）',
    `user_name`       VARCHAR(50)  NOT NULL                    COMMENT '用户显示名',
    `phone`           VARCHAR(20)  DEFAULT NULL                COMMENT '手机号',
    `email`           VARCHAR(100) DEFAULT NULL                COMMENT '邮箱',
    `avatar`          VARCHAR(500) DEFAULT NULL                COMMENT '头像 URL',
    `status`          TINYINT(4)   NOT NULL DEFAULT 0          COMMENT '状态：0-正常 1-锁定 2-禁用 3-封禁',
    `last_login_time` DATETIME     DEFAULT NULL                COMMENT '最后登录时间',
    `last_login_ip`   VARCHAR(50)  DEFAULT NULL                COMMENT '最后登录 IP',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_user_login_name` (`tenant_id`, `login_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户表';

-- ============================================================
-- 3. 角色表 - t_auth_role
-- 说明：角色定义，租户内隔离，角色编码在租户内唯一
-- 关联 UserStory：US-009
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_role` (
    `id`          BIGINT(20)   NOT NULL                    COMMENT '角色ID（雪花算法）',
    `tenant_id`   BIGINT(20)   NOT NULL                    COMMENT '租户ID，关联 t_auth_tenant.id',
    `role_name`   VARCHAR(50)  NOT NULL                    COMMENT '角色名称',
    `role_code`   VARCHAR(50)  NOT NULL                    COMMENT '角色编码（租户内唯一）',
    `description` VARCHAR(500) DEFAULT NULL                COMMENT '角色描述',
    `status`      TINYINT(4)   NOT NULL DEFAULT 0          COMMENT '状态：0-正常 1-禁用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_role_code` (`tenant_id`, `role_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='角色表';

-- ============================================================
-- 4. 权限表 - t_auth_permission
-- 说明：权限点定义，支持树形结构组织菜单、按钮和 API 权限
-- 关联 UserStory：US-010
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_permission` (
    `id`          BIGINT(20)   NOT NULL                    COMMENT '权限ID（雪花算法）',
    `perm_name`   VARCHAR(100) NOT NULL                    COMMENT '权限名称',
    `perm_code`   VARCHAR(100) NOT NULL                    COMMENT '权限标识（如 system:user:list，全局唯一）',
    `perm_type`   TINYINT(4)   NOT NULL DEFAULT 1          COMMENT '类型：1-菜单 2-按钮 3-API',
    `parent_id`   BIGINT(20)   DEFAULT 0                   COMMENT '父权限ID（0 表示顶级）',
    `path`        VARCHAR(200) DEFAULT NULL                COMMENT '路由路径',
    `component`   VARCHAR(200) DEFAULT NULL                COMMENT '组件路径',
    `icon`        VARCHAR(100) DEFAULT NULL                COMMENT '图标',
    `sort_order`  INT(11)      DEFAULT 0                   COMMENT '排序号',
    `status`      TINYINT(4)   NOT NULL DEFAULT 0          COMMENT '状态：0-正常 1-禁用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     TINYINT(1)   NOT NULL DEFAULT 0          COMMENT '逻辑删除：0-正常 1-删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_perm_code` (`perm_code`) USING BTREE,
    KEY `idx_parent_id` (`parent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='权限表';

-- ============================================================
-- 5. 用户角色关联表 - t_auth_user_role
-- 说明：用户与角色的多对多关联
-- 关联 UserStory：US-011
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_user_role` (
    `id`          BIGINT(20) NOT NULL                    COMMENT '关联ID（雪花算法）',
    `user_id`     BIGINT(20) NOT NULL                    COMMENT '用户ID，关联 t_auth_user.id',
    `role_id`     BIGINT(20) NOT NULL                    COMMENT '角色ID，关联 t_auth_role.id',
    `create_time` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_user_role` (`user_id`, `role_id`) USING BTREE,
    KEY `idx_role_id` (`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户角色关联表';

-- ============================================================
-- 6. 角色权限关联表 - t_auth_role_permission
-- 说明：角色与权限的多对多关联
-- 关联 UserStory：US-012
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_role_permission` (
    `id`          BIGINT(20) NOT NULL                    COMMENT '关联ID（雪花算法）',
    `role_id`     BIGINT(20) NOT NULL                    COMMENT '角色ID，关联 t_auth_role.id',
    `perm_id`     BIGINT(20) NOT NULL                    COMMENT '权限ID，关联 t_auth_permission.id',
    `create_time` DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_role_perm` (`role_id`, `perm_id`) USING BTREE,
    KEY `idx_perm_id` (`perm_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='角色权限关联表';

-- ============================================================
-- 7. 登录日志表 - t_auth_login_log
-- 说明：记录用户登录认证的详细信息，用于安全审计
-- 关联 UserStory：US-022
-- ============================================================
CREATE TABLE IF NOT EXISTS `t_auth_login_log` (
    `id`           BIGINT(20)  NOT NULL                    COMMENT '日志ID（雪花算法）',
    `user_id`      BIGINT(20)  NOT NULL                    COMMENT '用户ID，关联 t_auth_user.id',
    `tenant_id`    BIGINT(20)  NOT NULL                    COMMENT '租户ID，关联 t_auth_tenant.id',
    `login_ip`     VARCHAR(50) NOT NULL                    COMMENT '登录 IP 地址',
    `client_type`  VARCHAR(20) NOT NULL                    COMMENT '客户端类型（WINDOWS/H5/ANDROID 等）',
    `device_info`  VARCHAR(500) DEFAULT NULL               COMMENT '设备信息',
    `login_time`   DATETIME    NOT NULL                    COMMENT '登录时间',
    `logout_time`  DATETIME    DEFAULT NULL                COMMENT '登出时间（NULL 表示未登出）',
    `login_result` TINYINT(4)  NOT NULL DEFAULT 0          COMMENT '登录结果：0-成功 1-失败',
    `fail_reason`  VARCHAR(255) DEFAULT NULL               COMMENT '失败原因',
    `create_time`  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`) USING BTREE,
    KEY `idx_log_user_time` (`user_id`, `login_time`) USING BTREE,
    KEY `idx_log_tenant_time` (`tenant_id`, `login_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='登录日志表';

-- ============================================================
-- 初始数据
-- 说明：插入系统运行必需的初始数据
-- 注意：以下使用硬编码 ID（雪花算法），开发环境以 1 起始
-- ============================================================

-- ------------------------------------------------------------
-- 1. 默认租户
-- tenant_code = 'DEFAULT'，系统默认租户
-- ------------------------------------------------------------
INSERT INTO `t_auth_tenant` (`id`, `tenant_name`, `tenant_code`, `contact_name`, `contact_phone`, `status`, `expire_time`, `create_time`, `update_time`, `deleted`)
VALUES (1, '默认租户', 'DEFAULT', '系统管理员', '13800000000', 0, NULL, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 2. 超级管理员角色
-- role_code = 'SUPER_ADMIN'，归属默认租户
-- ------------------------------------------------------------
INSERT INTO `t_auth_role` (`id`, `tenant_id`, `role_name`, `role_code`, `description`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (1, 1, '超级管理员', 'SUPER_ADMIN', '系统超级管理员，拥有所有权限', 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 3. 管理员用户
-- login_name = 'admin'，归属默认租户，密码 BCrypt 加密
-- 默认密码为 "admin123"，首次登录后请立即修改
-- ------------------------------------------------------------
INSERT INTO `t_auth_user` (`id`, `tenant_id`, `login_name`, `password`, `user_name`, `phone`, `email`, `avatar`, `status`, `last_login_time`, `last_login_ip`, `create_time`, `update_time`, `deleted`)
VALUES (1, 1, 'admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '系统管理员', '13800000000', 'admin@cloudstrolling.com', NULL, 0, NULL, NULL, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 4. 基础权限数据
-- 说明：按树形结构组织，依次为菜单 → 按钮/API
-- ------------------------------------------------------------

-- 4.1 顶级菜单：系统管理
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (1, '系统管理', 'system:manage', 1, 0, '/system', 'Layout', 'setting', 1, 0, NOW(), NOW(), 0);

-- 4.2 二级菜单：用户管理
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (2, '用户管理', 'system:user:manage', 1, 1, '/system/user', 'system/user/index', 'user', 1, 0, NOW(), NOW(), 0);

-- 4.3 二级菜单：角色管理
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (3, '角色管理', 'system:role:manage', 1, 1, '/system/role', 'system/role/index', 'role', 2, 0, NOW(), NOW(), 0);

-- 4.4 二级菜单：权限管理
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (4, '权限管理', 'system:perm:manage', 1, 1, '/system/permission', 'system/permission/index', 'permission', 3, 0, NOW(), NOW(), 0);

-- 4.5 用户管理 - 按钮权限
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (5, '用户查询', 'system:user:query', 2, 2, NULL, NULL, NULL, 1, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (6, '用户新增', 'system:user:create', 2, 2, NULL, NULL, NULL, 2, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (7, '用户修改', 'system:user:update', 2, 2, NULL, NULL, NULL, 3, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (8, '用户删除', 'system:user:delete', 2, 2, NULL, NULL, NULL, 4, 0, NOW(), NOW(), 0);

-- 4.6 角色管理 - 按钮权限
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (9, '角色查询', 'system:role:query', 2, 3, NULL, NULL, NULL, 1, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (10, '角色新增', 'system:role:create', 2, 3, NULL, NULL, NULL, 2, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (11, '角色修改', 'system:role:update', 2, 3, NULL, NULL, NULL, 3, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (12, '角色删除', 'system:role:delete', 2, 3, NULL, NULL, NULL, 4, 0, NOW(), NOW(), 0);

-- 4.7 权限管理 - 按钮权限
INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (13, '权限查询', 'system:perm:query', 2, 4, NULL, NULL, NULL, 1, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (14, '权限新增', 'system:perm:create', 2, 4, NULL, NULL, NULL, 2, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (15, '权限修改', 'system:perm:update', 2, 4, NULL, NULL, NULL, 3, 0, NOW(), NOW(), 0);

INSERT INTO `t_auth_permission` (`id`, `perm_name`, `perm_code`, `perm_type`, `parent_id`, `path`, `component`, `icon`, `sort_order`, `status`, `create_time`, `update_time`, `deleted`)
VALUES (16, '权限删除', 'system:perm:delete', 2, 4, NULL, NULL, NULL, 4, 0, NOW(), NOW(), 0);

-- ------------------------------------------------------------
-- 5. 用户-角色关联
-- 说明：将超级管理员用户分配给超级管理员角色
-- ------------------------------------------------------------
INSERT INTO `t_auth_user_role` (`id`, `user_id`, `role_id`, `create_time`)
VALUES (1, 1, 1, NOW());

-- ------------------------------------------------------------
-- 6. 角色-权限关联
-- 说明：为超级管理员角色分配所有基础权限
-- ------------------------------------------------------------
INSERT INTO `t_auth_role_permission` (`id`, `role_id`, `perm_id`, `create_time`)
VALUES
    (1,  1, 1,  NOW()),
    (2,  1, 2,  NOW()),
    (3,  1, 3,  NOW()),
    (4,  1, 4,  NOW()),
    (5,  1, 5,  NOW()),
    (6,  1, 6,  NOW()),
    (7,  1, 7,  NOW()),
    (8,  1, 8,  NOW()),
    (9,  1, 9,  NOW()),
    (10, 1, 10, NOW()),
    (11, 1, 11, NOW()),
    (12, 1, 12, NOW()),
    (13, 1, 13, NOW()),
    (14, 1, 14, NOW()),
    (15, 1, 15, NOW()),
    (16, 1, 16, NOW());
