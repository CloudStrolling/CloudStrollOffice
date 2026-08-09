# 数据库设计文档（DBD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**编写人**：DBA

## 0. 版本变更说明
**本版本（v0.2.5）不涉及数据库结构变更。**

v0.2.5 为"部署资产集中化"工程版本，变更范围如下（详见 PRD v0.2.5 与 SAD v0.2.5）：
- 新建根目录 `deploy` 作为全部最终构建产物（后端 jar 包、客户端安装文件/exe）与部署资产（env.json / env.example.json、deploy/scripts 下 .sh/.ps1）的唯一落点；
- 修改 Maven 各模块与 Flutter 客户端构建配置，最终产物输出至 `deploy`，构建中间产物禁止进入；
- 迁移 `env.json` / `env.example.json` 至 `deploy`，迁移根目录 `scripts` 下全部 .sh/.ps1 至 `deploy/scripts` 并同步适配脚本内路径引用。

以上变更均为工程目录结构与构建/部署配置调整，**不涉及任何表结构、索引、存储过程、视图、触发器或初始化数据的增删改**。数据库设计（含 9 张认证业务表与 biz/system 预留库）完全沿用主数据库设计文档 `docs/cso-dbd.md`（v0.0.1 基线）。

## 1. 设计目标
沿用主文档 `docs/cso-dbd.md`（v0.0.1）设计目标：
- 支持认证底座业务：统一认证授权底座（注册 5 策略、登录 4 策略、双 Token 轮换、密码/手机号管理、验证码、RBAC 权限、登录日志）持久化数据支撑。
- 多租户数据隔离：基于 RBAC（用户-角色-权限）模型实现多租户数据空间隔离。
- 数据规模预估：认证底座数据量可控（万级以内），登录日志表随使用增长，后续版本规划归档。
- 一致性要求：密码 BCrypt 加密存储、逻辑删除统一、雪花算法主键与审计时间自动填充。
- 热路径性能：登录名（租户内唯一）、手机号、角色编码、权限编码等高频查询字段建立唯一索引/普通索引。

## 2. 数据库选型
**数据库产品**：MariaDB（业务关系型数据库）+ Redis（缓存数据库，非关系型，不在本 DBD 表结构范围内）
**版本**：MariaDB 10.6 (LTS) / Redis 7.2.x
**选型理由**：沿用主文档 `docs/cso-dbd.md`（v0.0.1）选型，本版本无变更。
- 兼容 MySQL 生态，JDBC 驱动 `org.mariadb.jdbc.Driver`，与 MyBatis-Plus 3.5.6 无缝集成。
- 开源免费、稳定性与性能满足企业办公场景，Docker Compose 一键编排（8 容器）部署简单。
- 认证库 `cloudstroll_office_auth` 承载 9 张业务表；`cloudstroll_office_biz` / `cloudstroll_office_system` 库仅建库预留。

## 3. ER 图
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 3 章 ER 图（9 张认证业务表实体关系），本版本无变更。

## 4. 逻辑模型
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 4 章逻辑模型（租户 / 用户 / 角色 / 权限 / 用户-角色关联 / 角色-权限关联 / 登录日志 / OAuth 账号关联 / 验证码记录 共 9 个实体），本版本无变更。

## 5. 物理模型
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 5 章物理模型，共 9 张表，本版本无变更：
| 表名 | 说明 |
| --- | --- |
| t_auth_tenant | 租户表 |
| t_auth_user | 用户表 |
| t_auth_role | 角色表 |
| t_auth_permission | 权限表 |
| t_auth_user_role | 用户角色关联表 |
| t_auth_role_permission | 角色权限关联表 |
| t_auth_login_log | 登录日志表 |
| t_auth_oauth_account | OAuth 第三方账号关联表 |
| t_auth_verification_code | 验证码记录表 |

## 6. 索引设计
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 6 章索引设计（9 张表主键索引 + 7 个唯一索引 + 9 个普通索引），本版本无变更。

## 7. 视图 / 存储过程 / 触发器设计
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 7 章，本版本无变更：
### 7.1 视图
无。用户权限查询由 Mapper XML 联表 SQL 实现，不建视图。
### 7.2 存储过程
无。验证码过期清理由服务层定时调用实现，不建存储过程。
### 7.3 触发器
无。审计字段由 MyBatis-Plus 自动填充实现，不建触发器。

## 8. 数据字典
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 8 章数据字典（枚举值汇总），本版本无变更。

## 9. 备份恢复策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 9 章，本版本无变更：
- 每日全量备份（mysqldump --single-transaction --routines --events cloudstroll_office_auth），保留最近 7 天。
- 每季度执行一次恢复演练。
- 初始脚本 `docs/cso-dbd.sql` 为全量可重复执行脚本（INSERT IGNORE 幂等）。

## 10. 安全策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 10 章，本版本无变更：
- 应用连接最小权限账号，生产禁止 root 连接应用。
- 密码一律 BCrypt 加密存储，禁止明文。
- 多租户隔离：所有业务查询限定当前租户（tenant_id）。
- 登录日志审计（IP/客户端类型/结果/失败原因）。
- 数据库密码通过环境变量注入（env.json / env.example.json 模板，v0.2.5 起存放于 `deploy` 目录）。
- 数据库与中间件处于 Docker 桥接网络内不对外暴露。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
