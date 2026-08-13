# 测试用例文档（TestCase）TASK-001
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| cloudstroll_office_common 通用配置库 | TASK-001 | 6 | P0×6 |

## 二、测试用例详情

### 模块：通用配置库（cloudstroll_office_common）- 库/表/索引/种子数据初始化

#### TC-TASK001-001：通用配置库创建成功（P0）
- **用例ID**：TC-TASK001-001
- **用例名称**：执行 v0.2.8 SQL 后数据库 cloudstroll_office_common 存在
- **所属模块**：cloudstroll_office_common（建库）
- **优先级**：P0
- **前置条件**：本地 MariaDB 可连接（DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD 从 env.json 读取）
- **测试类型**：单元测试（SQL 验证）
- **关联需求ID**：US-002 / F-004
- **测试数据**：`SHOW DATABASES LIKE 'cloudstroll_office_common'`
- **测试步骤**：
  1. 用 mariadb 客户端执行 `docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`
  2. 查询 `SHOW DATABASES LIKE 'cloudstroll_office_common'`
- **预期结果**：
  1. 脚本执行无报错、退出码 0
  2. 数据库 cloudstroll_office_common 存在
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-001 断言）
- **测试过程与结论**：通过（2026-08-13，脚本执行退出码 0，SHOW DATABASES 返回 cloudstroll_office_common）

#### TC-TASK001-002：t_common_config 表结构正确（P0）
- **用例ID**：TC-TASK001-002
- **用例名称**：t_common_config 表字段与 DBD 5.2.1 一致
- **所属模块**：cloudstroll_office_common（建表）
- **优先级**：P0
- **前置条件**：TC-TASK001-001 通过，库已创建
- **测试类型**：单元测试（SQL 验证）
- **关联需求ID**：US-002 / F-003 / F-004
- **测试数据**：`DESCRIBE cloudstroll_office_common.t_common_config`
- **测试步骤**：
  1. 执行 `USE cloudstroll_office_common; SHOW TABLES;` 确认 t_common_config 存在
  2. 执行 `DESCRIBE t_common_config` 核对 12 字段：id/service_name/config_group/config_key/config_value/data_type/description/sensitive/status/create_time/update_time/deleted
  3. 核对字段类型与默认值（id BIGINT 主键、service_name/config_group VARCHAR、config_key VARCHAR(100)、config_value TEXT、data_type 默认 string、sensitive 默认 0、status 默认 0、deleted 默认 0、create_time/update_time DEFAULT CURRENT_TIMESTAMP）
- **预期结果**：
  1. t_common_config 存在
  2. 12 个字段名、类型、默认值与 DBD 5.2.1 完全一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-002 断言）
- **测试过程与结论**：通过（2026-08-13，12 字段全部存在且类型匹配：id BIGINT/config_key VARCHAR(100)/config_value TEXT/data_type VARCHAR(20)/sensitive TINYINT 等）

#### TC-TASK001-003：索引与 DBD 6.2 一致（P0）
- **用例ID**：TC-TASK001-003
- **用例名称**：uk_service_group_key / idx_service_name / idx_config_group 索引存在
- **所属模块**：cloudstroll_office_common（索引）
- **优先级**：P0
- **前置条件**：TC-TASK001-002 通过
- **测试类型**：单元测试（SQL 验证）
- **关联需求ID**：US-002 / F-003
- **测试数据**：`SHOW INDEX FROM cloudstroll_office_common.t_common_config`
- **测试步骤**：
  1. 执行 `SHOW INDEX FROM t_common_config`
  2. 核对索引：PRIMARY（id）、uk_service_group_key（service_name, config_group, config_key 唯一）、idx_service_name（service_name）、idx_config_group（service_name, config_group）
- **预期结果**：
  1. 4 个索引（含主键）全部存在
  2. uk_service_group_key 为唯一索引（Non_unique=0），字段顺序与 DBD 6.2 一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-003 断言）
- **测试过程与结论**：通过（2026-08-13，uk_service_group_key 唯一索引（service_name,config_group,config_key）、idx_service_name、idx_config_group 均存在且字段顺序正确）

#### TC-TASK001-004：17 条种子数据插入成功（P0）
- **用例ID**：TC-TASK001-004
- **用例名称**：t_common_config 种子数据为 17 条且覆盖五个微服务
- **所属模块**：cloudstroll_office_common（种子数据）
- **优先级**：P0
- **前置条件**：TC-TASK001-001 通过
- **测试类型**：单元测试（SQL 验证）
- **关联需求ID**：US-002 / F-004
- **测试数据**：`SELECT COUNT(*) FROM t_common_config`、`SELECT DISTINCT service_name FROM t_common_config`
- **测试步骤**：
  1. 查询记录总数，断言等于 17
  2. 查询 distinct service_name，断言包含 gateway/auth-service/biz-service/system-service/common 五个值
  3. 抽查关键配置：auth-service verification/code-length=6、common config/cache-ttl-seconds=300、gateway security/whitelist-paths 非空
- **预期结果**：
  1. 总数 17 条
  2. 五个微服务均有配置项
  3. 抽查配置值与 DBD 8.3 一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-004 断言）
- **测试过程与结论**：通过（2026-08-13，17 条记录、5 个 distinct service_name；抽查 auth-service verification/code-length=6、common config/cache-ttl-seconds=300 均正确）

#### TC-TASK001-005：脚本幂等可重复执行（P0）
- **用例ID**：TC-TASK001-005
- **用例名称**：重复执行 v0.2.8 SQL 不报错、数据不重复
- **所属模块**：cloudstroll_office_common（幂等）
- **优先级**：P0
- **前置条件**：TC-TASK001-004 通过（库表已存在、种子数据已插入）
- **测试类型**：单元测试（SQL 验证）
- **关联需求ID**：US-002
- **测试数据**：再次执行 `docs/cso-v0.2.8/cso-dbd-v0.2.8.sql`
- **测试步骤**：
  1. 再次用 mariadb 客户端执行 v0.2.8 SQL 脚本
  2. 断言执行不报错、退出码 0
  3. 再次查询记录总数，断言仍为 17 条（无重复插入）
- **预期结果**：
  1. 重复执行无错误
  2. 记录总数仍为 17（INSERT IGNORE + 唯一索引保证幂等）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-005 断言）
- **测试过程与结论**：通过（2026-08-13，重复执行 v0.2.8 SQL 退出码 0，记录总数仍为 17，无重复插入）

#### TC-TASK001-006：不影响既有认证库（P0）
- **用例ID**：TC-TASK001-006
- **用例名称**：执行后 cloudstroll_office_auth 既有 9 张表不受影响
- **所属模块**：cloudstroll_office_auth（回归）
- **优先级**：P0
- **前置条件**：TC-TASK001-001 通过
- **测试类型**：单元测试（SQL 验证）/ 功能测试（回归）
- **关联需求ID**：US-002
- **测试数据**：`SHOW TABLES FROM cloudstroll_office_auth`
- **测试步骤**：
  1. 执行 `SHOW TABLES FROM cloudstroll_office_auth`
  2. 断言 9 张表（t_auth_tenant/user/role/permission/user_role/role_permission/login_log/oauth_account/verification_code）全部存在
  3. 断言未新增/未删除任何 auth 表
- **预期结果**：
  1. auth 库 9 张既有表完整
  2. 无新增表（本脚本仅新增 common 库）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1（TC-TASK001-006 断言）
- **测试过程与结论**：通过（2026-08-13，cloudstroll_office_auth 恰有 9 张基线表，无新增/删除）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 6（13 项断言全部通过） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 本地 MariaDB 未运行 | 脚本无法执行 | 启动 MariaDB 服务后重试 |
| 库已存在但表结构不一致 | 幂等建表不覆盖旧结构 | 用 SHOW/DESCRIBE 校验字段与 DBD 一致，不一致时人工对齐 |
| 与并行任务写版本文档冲突 | 测试用例文档可能被覆盖 | 写入前读取最新内容，合并写回并回读校验 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
