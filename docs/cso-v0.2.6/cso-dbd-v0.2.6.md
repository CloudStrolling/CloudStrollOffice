# 数据库设计文档（DBD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**编写人**：DBA

## 0. 版本变更说明
**本版本（v0.2.6）不涉及数据库结构变更。**

v0.2.6 为"部署与配置缺陷修复"工程版本（需求来源：docs/cso-v0.2.5/regression-api-test.md 记录的回归测试问题），变更范围如下（详见 PRD v0.2.6 与 SAD v0.2.6）：
- **F-001 引入 bootstrap 配置引导依赖**：全项目 pom 引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载，消除 auth/biz/system 启动报错 `No spring.config.import property has been defined`（SAD ADR-014）；
- **F-002 修复 RSA 密钥格式契约**：deploy-rsa-keygen.ps1 生成/env.json 注入的 `RSA_PUBLIC_KEY`、`RSA_PRIVATE_KEY` 由 PEM 整体 Base64 统一为 DER 编码单行 Base64，与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致，消除网关启动报错 `RSA 公钥解析失败`（SAD ADR-015）；
- **F-003~F-005 验证闭环**：4 服务启动与健康检查验证、v0.0.1 基线接口回归（TC-001~045）、既有接口契约无回归保障（TC-046~051），均为部署验证与测试类活动。

以上变更均为**构建/依赖配置与密钥格式契约类修复**，**不涉及任何表结构、索引、存储过程、视图、触发器或初始化数据的增删改**（PRD v0.2.6 第 6 章数据需求明确：不新增数据表、不修改表结构；MariaDB cloudstroll_office_auth 等 9 张表数据结构不变，仅依赖其可用性完成服务启动验证）。数据库设计（含 9 张认证业务表与 biz/system 预留库）完全沿用主数据库设计文档 `docs/cso-dbd.md`（v0.0.1 基线，v0.2.5 确认无变更后继续沿用）。

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
说明：本版本仅调整 `deploy/env.json` 中 RSA 密钥配置值的**格式**（PEM 整体 Base64 → DER 单行 Base64），不涉及任何表字段枚举值变化；数据库密码、Redis、Nacos 连接参数保持不变。

## 9. 备份恢复策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 9 章，本版本无变更：
- 每日全量备份（mysqldump --single-transaction --routines --events cloudstroll_office_auth），保留最近 7 天。
- 每季度执行一次恢复演练。
- 初始脚本 `docs/cso-dbd.sql` 为全量可重复执行脚本（INSERT IGNORE 幂等）；部署脚本引用的副本 `scripts/sql/init-v0.2.0-full.sql` 保持可用（v0.2.6 回归测试依赖其初始化测试数据）。

## 10. 安全策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 10 章，本版本无变更：
- 应用连接最小权限账号，生产禁止 root 连接应用。
- 密码一律 BCrypt 加密存储，禁止明文。
- 多租户隔离：所有业务查询限定当前租户（tenant_id）。
- 登录日志审计（IP/客户端类型/结果/失败原因）。
- 数据库密码通过环境变量注入（env.json / env.example.json 模板，存放于 `deploy` 目录）；RSA 密钥亦经环境变量注入，私钥不得入库、不得写入日志（v0.2.6 修复后格式契约为 DER 单行 Base64，安全属性不变）。
- 数据库与中间件处于 Docker 桥接网络内不对外暴露。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
