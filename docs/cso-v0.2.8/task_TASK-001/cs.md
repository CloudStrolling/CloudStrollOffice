# 本地代码查询（TASK-001 通用配置库与配置表初始化）

## 1. 任务背景
TASK-001 为后端数据库初始化任务：执行 DBD v0.2.8 SQL，新建数据库 `cloudstroll_office_common`、通用配置表 `t_common_config` 及 17 条种子数据。本任务以 SQL 脚本为主要交付物，需保证与既有脚本体系（deploy-db-init 等）兼容并可在 MariaDB 10.6/10.11 执行。

## 2. 相关现有代码与配置

### 2.1 版本 SQL 脚本（本任务核心交付物）
- 路径：`docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`
- 内容：建库 `cloudstroll_office_common`、建表 `t_common_config`（12 字段 + 主键 + 3 索引）、INSERT IGNORE 17 条种子数据（auth-service 10 条 / gateway 3 条 / common 2 条 / biz-service 1 条 / system-service 1 条）
- 特性：`CREATE DATABASE IF NOT EXISTS` / `CREATE TABLE IF NOT EXISTS` / `INSERT IGNORE` 幂等，可重复执行
- 与 DBD 文档 `docs/cso-v0.2.8/cso-dbd-v0.2.8.md` 5.2.1 表结构、6.2 索引、8.3 种子数据一致

### 2.2 数据库基线脚本（参考）
- `docs/cso-dbd.sql`：v0.0.1 全量基线（auth 库 9 张表 + biz/system 预留库），v0.2.7 起为版本变更说明 + 基线指引
- `scripts/sql/init-v0.2.0-full.sql`：全量合并脚本（auth/biz/system）
- `scripts/sql/auth-init-v0.1.5.sql` / `auth-init-v0.1.6.sql`：deploy-db-init 脚本引用的认证库初始化脚本
- `scripts/sql/init.sql`：遗留初始化脚本

### 2.3 数据库初始化脚本（deploy-db-init）
- `deploy/scripts/deploy-db-init.ps1` / `.sh`：执行 auth-init-v0.1.5.sql 与 auth-init-v0.1.6.sql，验证 auth 库表结构与初始数据
- 连接参数从 `deploy/env.json`（load-env）读取，口令经 `MYSQL_PWD` 传递（S-04/P8 修复：不出现于进程命令行）
- 当前脚本仅覆盖 auth 库初始化，**未包含** common 库；v0.2.8 通用配置库的建库建表语句位于版本 SQL 脚本 `docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`
- 注意：deploy-db-init 脚本本版本是否纳入 common 库初始化由部署脚本任务（TASK-006/007/008）决定，本任务仅保证 SQL 脚本本身正确可执行

### 2.4 数据库环境
- 本地 MariaDB 10.11.18（`C:\Program Files\MariaDB 10.11\bin\mariadb.exe`）与 MariaDB 10.6（`C:\Program Files\MariaDB 10.6\bin\mariadb.exe`）客户端均可用
- `deploy/env.json` 配置：DB_HOST=127.0.0.1、DB_PORT=3306、DB_USERNAME=root、DB_PASSWORD=Jenemy19521005
- 当前已存在库：`cloudstroll_office_auth` / `cloudstroll_office_biz` / `cloudstroll_office_system`；`cloudstroll_office_common` 尚未创建
- MCP MySQL 连接（只读）已确认 MariaDB 可连，版本 10.11.18

### 2.5 cloudoffice-common 模块（下游 TASK-002/003/004 使用，本任务不修改代码）
- 结构：`cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/` 下 config/constant/dto/enums/exception/model/util 包
- 现有公共类：ApiResult、PageResult、BaseEntity、ErrorCode、GlobalExceptionHandler、MyBatisPlusConfig、SpringDocConfig 等
- 尚无 ConfigMapper/ConfigEntity（TASK-004 实现），本任务只建数据库表，不涉及代码

## 3. 关键结论
1. 本任务 SQL 脚本已由 DBD 阶段生成（`docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`），需核对与 DBD 文档一致性并执行验证；
2. 执行环境：本地 MariaDB 客户端可用，DB 连接信息在 env.json；
3. 执行验证方式：用 mariadb 客户端执行脚本，验证库/表/索引/种子数据存在，且可重复执行（幂等）；
4. 不修改任何 Java 代码；仅可能新增 SQL 执行/验证相关测试脚本（scripts/API-TEST 或临时验证命令）。
