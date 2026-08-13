# 网络资料查询（TASK-001 通用配置库与配置表初始化）

## 1. 任务背景
TASK-001 为数据库初始化任务，核心交付物为 `docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`（建库、建表、索引、种子数据），不涉及三方 SDK 引入。本任务所需网络资料为 MariaDB/MySQL 的 DDL 与数据操纵语法确认。

## 2. 数据库技术选型
- 数据库产品：MariaDB 10.6 LTS（本机另有 MariaDB 10.11.18 实例，SQL 语法兼容）
- ORM：MyBatis-Plus 3.5.6（本任务不涉及，仅建表结构需与实体约定一致）

## 3. 官方文档确认的 SQL 语法要点

### 3.1 CREATE TABLE IF NOT EXISTS + 索引定义
MariaDB 官方 CREATE TABLE 语法确认（mariadb-docs create-table.md）：
- `CREATE TABLE IF NOT EXISTS` 幂等建表，重复执行不报错；
- 索引定义 BNF 支持：`PRIMARY KEY`、`UNIQUE [INDEX|KEY]`、`INDEX|KEY`，可带 `index_type USING {BTREE|HASH|RTREE}` 与 `index_option COMMENT 'string'`；
- 本脚本用法：
  - `UNIQUE KEY uk_service_group_key (service_name, config_group, config_key) USING BTREE` ✓
  - `KEY idx_service_name (service_name) USING BTREE` ✓
  - `KEY idx_config_group (service_name, config_group) USING BTREE` ✓

### 3.2 INSERT IGNORE 幂等插入
MariaDB 官方 INSERT-SELECT 文档确认：当插入值命中主键或 UNIQUE 索引重复时，`IGNORE` 关键字使重复值跳过、不报错、不影响其他行插入。
- 本脚本 17 条种子数据均指定硬编码 id（1~17）并使用 `INSERT IGNORE`，重复执行安全；
- 唯一索引 `uk_service_group_key` 同时提供三维定位的二次幂等保护。

### 3.3 默认值 CURRENT_TIMESTAMP
MariaDB 支持 `DEFAULT CURRENT_TIMESTAMP` 与 `ON UPDATE CURRENT_TIMESTAMP`（DATETIME 列），本脚本 create_time/update_time 用法合法。

### 3.4 数据类型与字符集
- `TEXT`、`VARCHAR(50/100/500)`、`TINYINT(1)/TINYINT(4)`、`BIGINT(20)`、`DATETIME` 均为 MariaDB 合法类型；
- 库表统一 `utf8mb4` + `utf8mb4_general_ci`，兼容中文描述注释与配置值。

## 4. 版本兼容性
- 目标环境 MariaDB 10.6 LTS；本机验证环境 MariaDB 10.11.18（更高小版本，向后兼容 10.6 SQL 语法）；
- 无语法特性依赖版本差异，脚本可在 10.6/10.11 双版本执行。

## 5. 其他相关资料
- 项目既有 SQL 基线（docs/cso-dbd.sql、scripts/sql/auth-init-*.sql、init-v0.2.0-full.sql）均采用相同幂等风格（IF NOT EXISTS / INSERT IGNORE），本脚本与既有体系风格一致；
- MyBatis-Plus 雪花算法主键约定：表 id 为 BIGINT，种子数据硬编码 id 便于开发环境；生产环境由 MyBatis-Plus ASSIGN_ID 生成。

## 6. 结论
SQL 脚本语法符合 MariaDB 官方规范，幂等策略（IF NOT EXISTS / INSERT IGNORE / 唯一索引）可保证重复执行不报错，满足验收标准第 3 条；无需引入任何三方依赖。
