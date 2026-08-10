# 数据库设计文档（DBD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**编写人**：DBA

## 0. 版本变更说明
**本版本（v0.2.7）不涉及数据库结构变更。**

v0.2.7 为"部署脚本体系重构与仓库清洁度治理"工程版本（需求来源：用户输入——检查并重构 deploy\scripts 目录下所有脚本，实现环境可用性检查、基础设施一键启动、后端服务按序一键启动三大能力，并治理 .gitignore 排除临时/中间文件），变更范围如下（详见 PRD v0.2.7 与 SAD v0.2.7 ADR-016）：
- **F-001 env.json 配置加载统一**：新增 `load-env.ps1` / `load-env.sh`，全部脚本统一从 `deploy/env.json` 加载配置（NACOS_*/DB_*/REDIS_*/RSA_* 等），脚本内不硬编码环境地址与凭据；
- **F-002~F-005 环境可用性检查**：`deploy-check-env.ps1` / `.sh` 基于 env.json 检查 JDK（java 命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程 + SELECT 1）、Redis（命令/服务/进程 + redis-cli ping）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测）的可用性；
- **F-006~F-007 运行状态检测与基础设施一键启动**：`deploy-start-services.ps1` / `.sh` 检测 MariaDB/Redis/Nacos 是否已启动，未启动者自动启动（系统服务优先，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认；
- **F-008~F-009 后端服务按序一键启动**：`deploy-start-all.ps1` / `.sh` 按 gateway → auth → biz → system 顺序一键启动 4 个后端服务，启动前校验 jar 包与关键环境变量，逐服务健康确认；单服务启动脚本（deploy-start-gateway/auth/biz/system）保持可用；
- **F-010~F-011 前置检查整合与契约对齐**：`deploy-check-env` 去除硬编码默认地址（192.168.1.100 等），输出分级（通过/警告/失败）与退出码约定统一；deploy-rsa-keygen.sh 与 .ps1 输出契约一致（DER 编码单行 Base64，不破坏 ADR-015）；删除弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1）；
- **F-012 .gitignore 临时/中间文件治理**：补充 JVM 调试产物、测试缓存、构建中间产物、工具残留等排除规则。

以上变更均为**部署运维层脚本重构与仓库治理类工作**，**不涉及任何表结构、索引、存储过程、视图、触发器或初始化数据的增删改**（PRD v0.2.7 第 6 章数据需求明确：不新增业务数据表、不修改既有表结构；MariaDB cloudstroll_office_auth 等 9 张表数据结构不变，仅依赖其可用性与运行状态完成脚本验证；deploy/env.json 仅调整连接参数读取方式，不改变数据库连接目标与结构）。数据库设计（含 9 张认证业务表与 biz/system 预留库）完全沿用主数据库设计文档 `docs/cso-dbd.md`（v0.0.1 基线，v0.2.5 / v0.2.6 确认无变更后继续沿用）。

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
- v0.2.7 部署脚本（deploy-check-env / deploy-start-services）通过 `SELECT 1`、`redis-cli ping`、HTTP 探测等对上述基础设施做可用性与运行状态检查，连接参数统一读取自 `deploy/env.json`（经 load-env 加载），不改变数据库选型与结构。

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
说明：本版本仅将部署脚本读取数据库/Redis/Nacos 连接参数的方式统一为经 `load-env` 从 `deploy/env.json` 加载（DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME、REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DATABASE/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME、NACOS_ADDR/NACOS_HOME），参数值与数据库连接目标不变，不涉及任何表字段枚举值变化。

## 9. 备份恢复策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 9 章，本版本无变更：
- 每日全量备份（mysqldump --single-transaction --routines --events cloudstroll_office_auth），保留最近 7 天。
- 每季度执行一次恢复演练。
- 初始脚本 `docs/cso-dbd.sql` 为全量可重复执行脚本（INSERT IGNORE 幂等）；部署脚本引用的副本 `scripts/sql/init-v0.2.0-full.sql` 保持可用（v0.2.6 回归测试依赖其初始化测试数据，v0.2.7 脚本重构不改变该引用关系）。

## 10. 安全策略
沿用主文档 `docs/cso-dbd.md`（v0.0.1）第 10 章，本版本无变更：
- 应用连接最小权限账号，生产禁止 root 连接应用。
- 密码一律 BCrypt 加密存储，禁止明文。
- 多租户隔离：所有业务查询限定当前租户（tenant_id）。
- 登录日志审计（IP/客户端类型/结果/失败原因）。
- 数据库密码通过环境变量注入（`deploy/env.json` / `env.example.json` 模板）；v0.2.7 重构后脚本统一经 load-env 加载，脚本输出对 DB_PASSWORD / REDIS_PASSWORD 一律掩码（`****`）显示、日志不打印明文，避免脚本化操作引入凭据泄露风险。
- 数据库与中间件处于 Docker 桥接网络内不对外暴露。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
