# 数据库设计文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.0
**日期：** 2026-06-18

---

# 1. 项目数据库选型

| 项目 | 选型 |
|------|------|
| **数据库** | MariaDB 10.6 (LTS) |
| **字符集** | `utf8mb4`（支持完整 Unicode，含 Emoji 和生僻字） |
| **排序规则** | `utf8mb4_general_ci`（通用排序，兼顾性能与兼容性） |
| **时区** | `Asia/Shanghai` (UTC+8)，应用层通过 `serverTimezone=Asia/Shanghai` 指定 |
| **存储引擎** | InnoDB（支持事务、行级锁、外键、MVCC） |
| **分片策略** | 无（v0.1.0 骨架阶段无需分片，后续根据数据量评估） |
| **连接池** | HikariCP 5.x（Spring Boot 默认，性能业界最优） |
| **ORM 框架** | MyBatis-Plus 3.5.x（增强型 MyBatis，Lambda 查询、自动填充、分页插件） |
| **JDBC 驱动** | MariaDB Connector/J 3.x（兼容 MySQL 协议） |
| **连接 URL 格式** | `jdbc:mariadb://{host}:3306/{database}?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&characterEncoding=utf8mb4` |

---

# 2. 命名规范

## 2.1 数据库命名

| 对象 | 规则 | 示例 |
|------|------|------|
| 数据库 | `cloudstroll_office_{module}` | `cloudstroll_office_auth` |
| 表名 | `t_{module}_{table_name}`，单数名词 | `t_auth_user`、`t_biz_employee` |
| 字段名 | 小写 + 下划线命名法 | `user_name`、`create_time`、`login_ip` |
| 主键 | 雪花算法生成，字段名统一 `id`，类型 `BIGINT(20)` | `id` |
| 普通索引 | `idx_{table}_{column}[_{column2}]` | `idx_auth_user_user_name` |
| 唯一索引 | `uk_{table}_{column}[_{column2}]` | `uk_auth_user_login_name` |
| 外键 | 不推荐使用物理外键，通过应用层逻辑维护引用关系 | - |

## 2.2 公共字段规范

每张表必须包含以下公共字段：

| 字段名 | 类型 | 说明 | 填充策略 |
|--------|------|------|---------|
| `id` | `BIGINT(20)` | 主键 ID | 雪花算法（MyBatis-Plus ID_WORKER），全局唯一、趋势递增 |
| `create_time` | `DATETIME(3)` | 创建时间 | MyBatis-Plus `@TableField(fill = INSERT)` 自动填充 |
| `update_time` | `DATETIME(3)` | 更新时间 | MyBatis-Plus `@TableField(fill = INSERT_UPDATE)` 自动填充 |
| `deleted` | `TINYINT(1)` | 逻辑删除标记 | 0-正常，1-已删除，MyBatis-Plus 逻辑删除插件自动处理 |

## 2.3 数据库对象汇总

| 模块 | 数据库名 | 说明 |
|------|---------|------|
| 认证服务 | `cloudstroll_office_auth` | 统一认证授权中心，用户管理、角色权限 |
| 企业服务 | `cloudstroll_office_biz` | 企业核心业务，企业信息、人事、薪酬管理 |
| 系统服务 | `cloudstroll_office_system` | 基础公共服务，系统配置、日志、监控 |

> **约定：** 各服务间禁止跨库直接访问数据库，必须通过 API 调用或消息队列进行数据交换。

---

# 3. 物理模型

## 3.1 认证服务数据库 —— `cloudstroll_office_auth`

### 3.1.1 t_auth_user（用户表）

v0.1.0 骨架阶段的初始表，为基础用户模型示例，后续版本扩展完善。

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| login_name | VARCHAR | 50 | NO | - | UK | 登录用户名（唯一） |
| password | VARCHAR | 255 | NO | - | None | BCrypt 哈希加密后的密码 |
| real_name | VARCHAR | 100 | YES | NULL | None | 真实姓名 |
| email | VARCHAR | 100 | YES | NULL | UK | 电子邮箱（唯一） |
| phone | VARCHAR | 20 | YES | NULL | None | 手机号码 |
| avatar | VARCHAR | 500 | YES | NULL | None | 头像 URL |
| status | TINYINT | 1 | NO | 1 | None | 状态：0-禁用 1-启用 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记：0-正常 1-已删除 |

**索引设计：**
- `uk_auth_user_login_name` (`login_name`) —— 用户登录名唯一索引，用于登录时快速检索
- `uk_auth_user_email` (`email`) —— 邮箱唯一索引，用于邮箱登录和去重校验
- `idx_auth_user_status` (`status`) —— 用户状态索引，用于按状态筛选查询
- `idx_auth_user_create_time` (`create_time`) —— 创建时间索引，用于按时间范围查询

**DDL 语句：**

```sql
CREATE TABLE IF NOT EXISTS `t_auth_user` (
    `id` BIGINT(20) NOT NULL COMMENT '主键 ID（雪花算法）',
    `login_name` VARCHAR(50) NOT NULL COMMENT '登录用户名',
    `password` VARCHAR(255) NOT NULL COMMENT 'BCrypt 哈希加密密码',
    `real_name` VARCHAR(100) DEFAULT NULL COMMENT '真实姓名',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '电子邮箱',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号码',
    `avatar` VARCHAR(500) DEFAULT NULL COMMENT '头像 URL',
    `status` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '状态：0-禁用 1-启用',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '逻辑删除标记：0-正常 1-已删除',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_auth_user_login_name` (`login_name`) USING BTREE,
    UNIQUE KEY `uk_auth_user_email` (`email`) USING BTREE,
    KEY `idx_auth_user_status` (`status`) USING BTREE,
    KEY `idx_auth_user_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='用户表';
```

### 3.1.2 预留表（后续版本）

| 表名 | 预期用途 | 计划版本 |
|------|---------|---------|
| `t_auth_role` | 角色表，RBAC 角色定义 | v0.2.0 |
| `t_auth_permission` | 权限表，系统权限资源定义 | v0.2.0 |
| `t_auth_role_permission` | 角色-权限关联表 | v0.2.0 |
| `t_auth_user_role` | 用户-角色关联表 | v0.2.0 |

---

## 3.2 企业服务数据库 —— `cloudstroll_office_biz`

v0.1.0 骨架阶段为预留状态，以下为后续版本的预期表结构设计。

### 3.2.1 t_biz_enterprise（企业信息表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| enterprise_name | VARCHAR | 200 | NO | - | None | 企业名称 |
| unified_social_code | VARCHAR | 30 | NO | - | UK | 统一社会信用代码 |
| legal_person | VARCHAR | 100 | YES | NULL | None | 法定代表人 |
| contact_phone | VARCHAR | 20 | YES | NULL | None | 联系电话 |
| contact_email | VARCHAR | 100 | YES | NULL | None | 联系邮箱 |
| address | VARCHAR | 500 | YES | NULL | None | 企业地址 |
| industry_type | VARCHAR | 50 | YES | NULL | None | 所属行业 |
| employee_count | INT | 10 | YES | 0 | None | 员工人数 |
| status | TINYINT | 1 | NO | 0 | None | 状态：0-待审核 1-已认证 2-已禁用 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记 |

**索引设计：**
- `uk_biz_enterprise_social_code` (`unified_social_code`) —— 统一社会信用代码唯一索引
- `idx_biz_enterprise_status` (`status`) —— 企业状态索引

### 3.2.2 t_biz_department（部门表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| enterprise_id | BIGINT | 20 | NO | - | None | 所属企业 ID |
| parent_id | BIGINT | 20 | YES | NULL | None | 上级部门 ID（NULL 为根部门） |
| dept_name | VARCHAR | 100 | NO | - | None | 部门名称 |
| dept_code | VARCHAR | 50 | YES | NULL | UK | 部门编码（企业内唯一） |
| sort_order | INT | 5 | NO | 0 | None | 排序号 |
| manager_id | BIGINT | 20 | YES | NULL | None | 部门负责人（员工 ID） |
| status | TINYINT | 1 | NO | 1 | None | 状态：0-禁用 1-启用 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记 |

**索引设计：**
- `uk_biz_department_code` (`enterprise_id`, `dept_code`) —— 企业内部门编码唯一
- `idx_biz_department_enterprise` (`enterprise_id`) —— 按企业查询部门
- `idx_biz_department_parent` (`parent_id`) —— 按父部门查询子部门

### 3.2.3 t_biz_employee（员工表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| enterprise_id | BIGINT | 20 | NO | - | None | 所属企业 ID |
| department_id | BIGINT | 20 | YES | NULL | None | 所属部门 ID |
| user_id | BIGINT | 20 | YES | NULL | UK | 关联用户 ID（auth 服务） |
| employee_no | VARCHAR | 50 | NO | - | UK | 工号（企业内唯一） |
| name | VARCHAR | 100 | NO | - | None | 姓名 |
| gender | TINYINT | 1 | YES | NULL | None | 性别：0-未知 1-男 2-女 |
| id_card | VARCHAR | 18 | YES | NULL | None | 身份证号（加密存储） |
| phone | VARCHAR | 20 | YES | NULL | None | 手机号 |
| email | VARCHAR | 100 | YES | NULL | None | 邮箱 |
| hire_date | DATE | - | YES | NULL | None | 入职日期 |
| job_position | VARCHAR | 100 | YES | NULL | None | 岗位/职位 |
| work_place | VARCHAR | 200 | YES | NULL | None | 工作地 |
| employment_type | TINYINT | 1 | NO | 1 | None | 雇佣类型：1-正式 2-试用 3-实习 4-劳务 |
| status | TINYINT | 1 | NO | 1 | None | 状态：0-离职 1-在职 2-停职 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记 |

**索引设计：**
- `uk_biz_employee_no` (`enterprise_id`, `employee_no`) —— 企业内工号唯一
- `uk_biz_employee_user` (`user_id`) —— 用户 ID 唯一（一个用户对应一个员工档案）
- `idx_biz_employee_department` (`department_id`) —— 按部门查询员工
- `idx_biz_employee_status` (`status`) —— 按状态查询员工

### 3.2.4 预留表（后续版本）

| 表名 | 预期用途 | 计划版本 |
|------|---------|---------|
| `t_biz_attendance` | 考勤记录表 | v0.3.0 |
| `t_biz_leave` | 请假申请表 | v0.3.0 |
| `t_biz_workflow` | 工作流定义表 | v0.3.0 |
| `t_biz_workflow_instance` | 工作流实例表 | v0.3.0 |
| `t_biz_salary` | 薪酬记录表 | v0.4.0 |
| `t_biz_salary_detail` | 薪酬明细表 | v0.4.0 |

---

## 3.3 系统服务数据库 —— `cloudstroll_office_system`

v0.1.0 骨架阶段为预留状态，以下为后续版本的预期表结构设计。

### 3.3.1 t_sys_config（系统配置表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| config_key | VARCHAR | 100 | NO | - | UK | 配置键（唯一） |
| config_value | TEXT | - | NO | - | None | 配置值 |
| config_group | VARCHAR | 50 | NO | 'default' | None | 配置分组 |
| remark | VARCHAR | 500 | YES | NULL | None | 备注说明 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记 |

**索引设计：**
- `uk_sys_config_key` (`config_key`) —— 配置键唯一索引
- `idx_sys_config_group` (`config_group`) —— 按分组查询配置

### 3.3.2 t_sys_dict（数据字典表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| dict_type | VARCHAR | 100 | NO | - | None | 字典类型编码 |
| dict_code | VARCHAR | 50 | NO | - | None | 字典项编码 |
| dict_label | VARCHAR | 200 | NO | - | None | 字典项标签（显示值） |
| dict_value | VARCHAR | 500 | YES | NULL | None | 字典项值（实际值） |
| sort_order | INT | 5 | NO | 0 | None | 排序号 |
| status | TINYINT | 1 | NO | 1 | None | 状态：0-禁用 1-启用 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 创建时间 |
| update_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | None | 更新时间 |
| deleted | TINYINT | 1 | NO | 0 | None | 逻辑删除标记 |

**索引设计：**
- `uk_sys_dict_type_code` (`dict_type`, `dict_code`) —— 字典类型内编码唯一
- `idx_sys_dict_type` (`dict_type`) —— 按字典类型查询

### 3.3.3 t_sys_oper_log（操作日志表）

| 字段名 | 类型 | 长度/精度 | 可空 | 默认值 | 约束 | 说明 |
|--------|------|----------|------|--------|------|------|
| id | BIGINT | 20 | NO | - | PK | 主键 ID（雪花算法） |
| module | VARCHAR | 50 | NO | - | None | 操作模块（auth/biz/system） |
| operation | VARCHAR | 100 | NO | - | None | 操作描述 |
| request_method | VARCHAR | 10 | YES | NULL | None | HTTP 方法：GET/POST/PUT/DELETE |
| request_url | VARCHAR | 500 | YES | NULL | None | 请求 URL |
| request_params | TEXT | - | YES | NULL | None | 请求参数 |
| response_result | TEXT | - | YES | NULL | None | 响应结果 |
| operator_id | BIGINT | 20 | YES | NULL | None | 操作用户 ID |
| operator_name | VARCHAR | 100 | YES | NULL | None | 操作用户名 |
| operator_ip | VARCHAR | 45 | YES | NULL | None | 操作 IP 地址 |
| duration | INT | 10 | YES | NULL | None | 操作耗时（毫秒） |
| status | TINYINT | 1 | NO | 0 | None | 操作状态：0-失败 1-成功 |
| create_time | DATETIME | 3 | NO | CURRENT_TIMESTAMP | None | 操作时间 |

**索引设计：**
- `idx_sys_oper_log_module` (`module`) —— 按模块查询日志
- `idx_sys_oper_log_operator` (`operator_id`) —— 按操作人查询日志
- `idx_sys_oper_log_create_time` (`create_time`) —— 按时间范围查询日志
- `idx_sys_oper_log_status` (`status`) —— 按操作状态查询

> **注意：** 操作日志表考虑历史数据量较大，后续建议按时间进行分区（如按月分区）或归档至日志存储系统。

### 3.3.4 预留表（后续版本）

| 表名 | 预期用途 | 计划版本 |
|------|---------|---------|
| `t_sys_notice` | 系统通知/公告表 | v0.2.0 |
| `t_sys_scheduled_task` | 定时任务表 | v0.2.0 |
| `t_sys_scheduled_log` | 定时任务执行日志表 | v0.2.0 |

---

# 4. 数据字典（枚举值汇总）

## 4.1 公共枚举值

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `{table}.deleted` | 0 | 正常（未删除） |
| `{table}.deleted` | 1 | 已删除（逻辑删除） |

## 4.2 用户状态（t_auth_user.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_auth_user.status` | 0 | 禁用 |
| `t_auth_user.status` | 1 | 启用 |

## 4.3 企业状态（t_biz_enterprise.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_biz_enterprise.status` | 0 | 待审核 |
| `t_biz_enterprise.status` | 1 | 已认证 |
| `t_biz_enterprise.status` | 2 | 已禁用 |

## 4.4 员工性别（t_biz_employee.gender）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_biz_employee.gender` | 0 | 未知 |
| `t_biz_employee.gender` | 1 | 男 |
| `t_biz_employee.gender` | 2 | 女 |

## 4.5 雇佣类型（t_biz_employee.employment_type）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_biz_employee.employment_type` | 1 | 正式员工 |
| `t_biz_employee.employment_type` | 2 | 试用期员工 |
| `t_biz_employee.employment_type` | 3 | 实习生 |
| `t_biz_employee.employment_type` | 4 | 劳务派遣 |

## 4.6 员工状态（t_biz_employee.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_biz_employee.status` | 0 | 离职 |
| `t_biz_employee.status` | 1 | 在职 |
| `t_biz_employee.status` | 2 | 停职 |

## 4.7 部门状态（t_biz_department.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_biz_department.status` | 0 | 禁用 |
| `t_biz_department.status` | 1 | 启用 |

## 4.8 操作日志状态（t_sys_oper_log.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_sys_oper_log.status` | 0 | 操作失败 |
| `t_sys_oper_log.status` | 1 | 操作成功 |

## 4.9 字典状态（t_sys_dict.status）

| 字段 | 枚举值 | 含义 |
|------|--------|------|
| `t_sys_dict.status` | 0 | 禁用 |
| `t_sys_dict.status` | 1 | 启用 |

---

# 5. 安全与权限

## 5.1 数据库权限体系

| 角色 | 库/表权限 | 说明 |
|------|----------|------|
| **DBA（超级管理员）** | 所有库 `ALL PRIVILEGES` | 数据库管理员，负责数据库安装、配置、备份、优化、用户管理 |
| **应用账号（读写）** | `SELECT, INSERT, UPDATE, DELETE` + `EXECUTE` 存储过程 | 各微服务连接数据库使用的账号，按库隔离，如 `auth_app`、`biz_app` |
| **应用账号（只读）** | `SELECT` | 只读副本/报表查询使用的账号 |
| **迁移账号** | `ALTER, CREATE, INDEX, DROP, REFERENCES` | 数据库迁移/版本管理（Flyway/Liquibase）专用账号，仅在迁移时使用 |

## 5.2 账号隔离策略

| 服务 | 数据库 | 应用账号 | 说明 |
|------|--------|---------|------|
| 认证服务 | `cloudstroll_office_auth` | `auth_app` | 仅授予 auth 库权限 |
| 企业服务 | `cloudstroll_office_biz` | `biz_app` | 仅授予 biz 库权限 |
| 系统服务 | `cloudstroll_office_system` | `system_app` | 仅授予 system 库权限 |

> **关键原则：** 各微服务只连接自己的数据库，禁止跨服务直接访问数据库。账号最小权限原则，仅授予所需的操作权限。

## 5.3 敏感字段脱敏

| 表.字段 | 脱敏规则 | 说明 |
|---------|---------|------|
| `t_auth_user.password` | BCrypt 哈希加密 | 单向加密，不可逆，验证时匹配密文 |
| `t_auth_user.email` | 应用层脱敏 `a***@example.com` | 仅显示首字符和域名，日志输出需脱敏 |
| `t_auth_user.phone` | 应用层脱敏 `138****1234` | 中间四位脱敏，日志输出需脱敏 |
| `t_biz_employee.id_card` | 加密存储（AES）+ 脱敏显示 | 身份证号为高敏感数据，数据库加密存储，应用层脱敏显示 |
| `t_biz_employee.phone` | 应用层脱敏 `138****1234` | 中间四位脱敏 |
| `t_biz_employee.email` | 应用层脱敏 | 仅显示首字符和域名 |

## 5.4 SQL 安全规范

| 安全措施 | 实现方式 |
|---------|---------|
| SQL 注入防护 | MyBatis-Plus 参数预编译（`#{}`），禁止使用 `${}` 拼接 SQL 参数 |
| 敏感配置管理 | 数据库密码、JWT 密钥通过环境变量注入，禁止硬编码在代码/配置文件中 |
| 逻辑删除 | 所有业务表使用 `deleted` 字段逻辑删除，不执行物理 `DELETE` |
| 连接加密 | 生产环境启用 SSL/TLS 加密数据库连接 |
| 审计日志 | `t_sys_oper_log` 记录所有关键操作的操作人、操作时间、IP 地址、请求参数 |

---

# 6. 备份与容灾

## 6.1 备份策略

| 备份类型 | 策略 | 说明 |
|---------|------|------|
| **全量备份** | 每日凌晨 02:00 执行一次全量逻辑备份（`mariadb-dump`） | 备份所有业务库，保留最近 7 日备份文件 |
| **增量备份** | 每小时执行一次 binlog 增量备份 | 基于 MariaDB binlog 进行增量恢复，保留最近 48 小时 |
| **备份存储** | 本地磁盘 + 远程对象存储（如 S3/MinIO） | 本地用于快速恢复，远端用于容灾，建议异地存储 |
| **备份保留** | 全量备份保留 7 天，增量日志保留 48 小时 | 超期自动清理，节省存储空间 |

## 6.2 容灾方案（规划中，当前 v0.1.0 骨架阶段）

| 场景 | RPO（恢复点目标） | RTO（恢复时间目标） | 恢复策略 |
|------|------------------|------------------|---------|
| 单表数据误操作 | ≤ 5 分钟 | ≤ 15 分钟 | 利用 binlog 实现时间点恢复（PITR） |
| 单库故障 | ≤ 1 小时 | ≤ 30 分钟 | MariaDB 主从同步 + 全量备份恢复 |
| 完整站点故障 | ≤ 24 小时 | ≤ 4 小时 | 异地备份恢复 + 基础设施即代码重建 |
| 单服务进程崩溃 | - | ≤ 30 秒 | Docker 自动重启策略（`restart: always`） |

## 6.3 MariaDB 主从同步配置（规划中）

```
                    ┌──────────────┐
                    │   Master     │  ← 读写库（应用写入）
                    │  (Read/Write)│
                    └──────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                 ▼
    ┌──────────┐    ┌──────────┐    ┌──────────────┐
    │  Slave1  │    │  Slave2  │    │  延迟从库     │
    │ (读副本)  │    │ (读副本)  │    │ (延迟1小时)   │
    └──────────┘    └──────────┘    └──────────────┘
```

## 6.4 备份脚本示例

```bash
#!/bin/bash
# 每日全量备份脚本
# 用法: ./backup_full.sh {database}

BACKUP_DIR="/data/backup/mariadb"
DB_NAME=$1
DATE_TAG=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_full_${DATE_TAG}.sql.gz"

# 执行逻辑备份并压缩
mariadb-dump \
    --host=127.0.0.1 \
    --port=3306 \
    --user=backup_user \
    --password=${DB_BACKUP_PASS} \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --databases ${DB_NAME} \
    | gzip > ${BACKUP_FILE}

# 保留最近 7 天
find ${BACKUP_DIR} -name "${DB_NAME}_full_*.sql.gz" -mtime +7 -delete
```

## 6.5 备份验证

| 验证项 | 频率 | 验证方法 |
|--------|------|---------|
| 备份文件完整性 | 每次备份后 | 检查 gzip 文件校验和，确保文件未损坏 |
| 备份可恢复性 | 每周 | 在测试环境执行恢复演练，验证数据完整性 |
| 备份文件大小 | 每次备份后 | 监测备份文件大小异常变化（过小可能备份失败） |
| 备份覆盖率 | 每日 | 确认所有业务库均按计划完成备份 |

---

> **文档信息：**
> - 本文档依据架构文档（`docs/architecture.md`）中 5.1 节数据模型设计和 5.4 节数据库设计规范编写
> - 物理模型中的表结构为 v0.1.0 骨架阶段的预期设计，实际数据库建设在编码阶段逐步落实
> - 当前数据库中 `cloudoffice` 已创建但为空库，尚未执行任何 DDL
> - 本文档将在后续版本迭代中持续更新，保持与实际数据库结构一致

---

# 7. 变更记录

| 变更日期 | 版本号 | 变更说明 |
|---------|-------|---------|
| 2026-06-19 | v0.1.0 | 移除cloud-service微服务模块相关数据库设计 |
