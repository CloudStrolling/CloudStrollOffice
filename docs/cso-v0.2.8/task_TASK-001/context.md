# 任务上下文（TASK-001 通用配置库与配置表初始化）

## 1. 任务信息

- 任务编号：TASK-001
- 任务名称：通用配置库与配置表初始化（cloudstroll_office_common + t_common_config + 种子数据）
- 任务类型：backend
- 用户故事：US-002（通过通用配置管理接口查询运行时配置）
- 优先级：P0
- 测试方式：单元测试 + 接口测试
- 前置任务：无
- 后置任务：TASK-004

## 2. 任务描述

执行 DBD v0.2.8 SQL：新建数据库 `cloudstroll_office_common`，新建通用配置表 `t_common_config`（含主键 id、service_name/config_group/config_key/config_value/data_type/description/sensitive/status 及审计字段 create_time/update_time/deleted），建立 `uk_service_group_key` 唯一索引、`idx_service_name` 与 `idx_config_group` 普通索引，并 INSERT IGNORE 插入 17 条种子数据覆盖 gateway/auth-service/biz-service/system-service/common 五个微服务的基础运行时配置（验证码策略/密码策略/Token 有效期/会话/网关白名单/CORS/限流/配置缓存 TTL 与脱敏掩码等）。

**仅新增库表与数据，不修改 cloudstroll_office_auth 既有 9 张表。**

## 3. 验收标准

1. 数据库 `cloudstroll_office_common` 创建成功；
2. `t_common_config` 表结构与索引（uk_service_group_key / idx_service_name / idx_config_group）与 DBD 5.2.1/6.2 一致；
3. 17 条种子数据幂等插入（重复执行不报错）；
4. 不修改 `cloudstroll_office_auth` 既有表。

## 4. 用户故事（US-002）需求上下文

- 通用配置管理接口（API-035/API-036，TASK-004 实现）查询时优先命中 Redis 本地缓存（命中 ≤ 50ms），未命中回源数据库 `t_common_config` 并回填缓存（TTL 300s）；
- 配置项按 service_name + config_group + config_key 三维定位唯一；
- sensitive=1 的敏感配置项查询返回时脱敏为掩码（默认 `****`）；
- 查询接口需经网关 AuthFilter 认证（非白名单），本任务仅建库建表，不实现接口。

## 5. 项目关键信息

- 项目名称：云漫智企（CloudStrollOffice），英文缩写 cso；
- 数据库：MariaDB 10.6 LTS（兼容 MySQL 5.7+），字符集 utf8mb4，排序规则 utf8mb4_general_ci；
- ORM：MyBatis-Plus 3.5.6（雪花算法主键、逻辑删除 @TableLogic）；
- 认证库：cloudstroll_office_auth（9 张表，v0.0.1 基线，本任务不修改）；
- 通用配置库：cloudstroll_office_common（本任务新增，1 张表 t_common_config）。

## 6. 相关文档

- DBD：docs/cso-v0.2.8/cso-dbd-v0.2.8.md（5.2.1 表结构、6.2 索引、8.3 种子数据）；
- SQL：docs/cso-v0.2.8/cso-dbd-v0.2.8.sql（已生成，需执行验证）；
- 主文档 SQL：docs/cso-dbd.sql（v0.0.1 基线全量，可重复执行）。
