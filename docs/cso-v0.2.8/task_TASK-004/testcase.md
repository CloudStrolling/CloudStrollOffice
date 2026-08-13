# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| cloudoffice-common（通用配置管理查询接口 ConfigController/ConfigService/ConfigCacheManager/ConfigMapper） | TASK-004 | 10 | P0×10 |

## 二、测试用例详情

### 模块：cloudoffice-common - 通用配置管理查询接口（TASK-004）

#### TC-TASK004-001：ConfigController 类存在且路径契约正确（P0）
- **用例ID**：TC-TASK004-001
- **用例名称**：ConfigController 标注 @RestController/@RequestMapping("/api/v1/common")，含 GET /config 与 GET /config/{serviceName} 方法
- **所属模块**：cloudoffice-common（ConfigController）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-035 / API-036
- **测试数据**：cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/controller/ConfigController.java
- **测试步骤**：
  1. 反射加载 org.cloudstrolling.cloudoffice.common.controller.ConfigController 类
  2. 断言类上存在 @RestController 与 @RequestMapping("/api/v1/common")
  3. 断言存在 queryConfigList() 方法，标注 @GetMapping("/config")，返回 ApiResult
  4. 断言存在 queryConfigsByService() 方法，标注 @GetMapping("/config/{serviceName}")，返回 ApiResult
- **预期结果**：
  1. 类可被加载，注解与方法齐全
  2. 无编译错误
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/controller/ConfigControllerTest.java（configController_shouldBeAnnotatedAndHaveQueryMethods）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-002：API-035 条件过滤+分页查询返回统一 PageResult（P0）
- **用例ID**：TC-TASK004-002
- **用例名称**：GET /api/v1/common/config 按 serviceName/group/key 过滤与分页，返回 ApiResult<PageResult<ConfigItemVO>>
- **所属模块**：cloudoffice-common（ConfigService 查询编排）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-035
- **测试数据**：serviceName=auth-service、group=verification、key=code-length、page=1、pageSize=10
- **测试步骤**：
  1. mock ConfigMapper，注入 ConfigService，构造 ConfigProperties（缓存 TTL 300s、掩码 ****）
  2. 调用 queryConfigList(serviceName, group, key, page, pageSize)
  3. 断言返回 ApiResult code=200
  4. 断言 data 为 PageResult，records 为 ConfigItemVO 列表，total/page/pageSize 正确
- **预期结果**：
  1. 返回统一 ApiResult<PageResult<ConfigItemVO>>
  2. 分页字段正确，records 元素字段与 API 文档 ConfigItemVO 一致
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（queryConfigList_shouldReturnPagedResult）；cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/controller/ConfigControllerTest.java（queryConfigList_shouldDelegateToService）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-003：API-036 按微服务名称查询返回列表（P0）
- **用例ID**：TC-TASK004-003
- **用例名称**：GET /api/v1/common/config/{serviceName} 返回 ApiResult<List<ConfigItemVO>>（不分页）
- **所属模块**：cloudoffice-common（ConfigService 按服务名查询）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-036
- **测试数据**：serviceName=auth-service
- **测试步骤**：
  1. mock ConfigMapper 返回 auth-service 配置实体列表，注入 ConfigService
  2. 调用 queryConfigsByService("auth-service")
  3. 断言返回 ApiResult code=200，data 为 List<ConfigItemVO>
  4. 断言列表元素 serviceName 均为 auth-service
- **预期结果**：
  1. 返回统一 ApiResult<List<ConfigItemVO>>
  2. 列表元素全部属于指定微服务
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（queryConfigsByService_shouldReturnList）；cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/controller/ConfigControllerTest.java（queryConfigsByService_shouldDelegateToService）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-004：serviceName 合法性校验（非法返回 400）（P0）
- **用例ID**：TC-TASK004-004
- **用例名称**：serviceName 不在合法取值（gateway/auth-service/biz-service/system-service/common）时抛 BusinessException(400)
- **所属模块**：cloudoffice-common（serviceName 校验）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-035 / API-036
- **测试数据**：serviceName=non-existent、invalid-svc
- **测试步骤**：
  1. 调用 queryConfigsByService("non-existent")
  2. 断言抛出 BusinessException，getCode()=400
  3. 调用 queryConfigList("invalid-svc", null, null, 1, 10)，断言同样抛 400
- **预期结果**：
  1. 非法 serviceName 抛 BusinessException(400)
  2. 不查询数据库，不返回 500
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（query_shouldRejectInvalidServiceName）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-005：敏感配置脱敏不暴露明文（P0）
- **用例ID**：TC-TASK004-005
- **用例名称**：sensitive=1 的配置项 value 脱敏为掩码（默认 ****），sensitive=0 返回明文
- **所属模块**：cloudoffice-common（ConfigService 脱敏）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-035 / ADR-018
- **测试数据**：敏感配置项（sensitive=1，value="secret-token"）+ 非敏感配置项（sensitive=0，value="6"）
- **测试步骤**：
  1. mock ConfigMapper 返回含敏感与非敏感配置项的列表，注入 ConfigService（默认掩码 ****）
  2. 调用 queryConfigsByService("auth-service")
  3. 断言敏感配置项 value="****"（不含明文 secret-token）
  4. 断言非敏感配置项 value 保持明文
  5. 配置 ConfigProperties.sensitiveMask="####"，断言脱敏后为 "####"（掩码可覆盖）
- **预期结果**：
  1. 敏感配置不暴露明文
  2. 掩码默认 ****，可被配置覆盖
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（query_shouldMaskSensitiveConfigs、query_shouldUseCustomizableSensitiveMask）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-006：缓存优先、未命中回源回填（P0）
- **用例ID**：TC-TASK004-006
- **用例名称**：按服务名查询优先命中缓存；未命中回源 ConfigMapper 查询并回填缓存（TTL 300s）
- **所属模块**：cloudoffice-common（ConfigCacheManager 缓存编排）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / ADR-018
- **测试数据**：serviceName=gateway，缓存 TTL=300s
- **测试步骤**：
  1. mock ConfigCacheManager 与 ConfigMapper，注入 ConfigService
  2. 第一次查询：缓存未命中 → ConfigMapper 查询 → 断言 ConfigCacheManager.cacheConfigs 被调用（回填）
  3. 第二次查询：缓存命中 → 断言 ConfigMapper 未被再次调用（从缓存返回）
  4. 断言缓存写入使用 TTL 300 秒
- **预期结果**：
  1. 缓存未命中回源数据库并回填
  2. 缓存命中不再回源
  3. TTL 与 ConfigProperties.cacheTtlSeconds 一致（300s）
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（query_shouldPreferCacheAndBackfillOnMiss）；cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/config/ConfigPropertiesTest.java（defaults_shouldMatchDesign）
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-007：ConfigCacheManager 缓存读写与失效（P0）
- **用例ID**：TC-TASK004-007
- **用例名称**：ConfigCacheManager 以 serviceName 为粒度提供 getCachedConfigs/cacheConfigs/evict 能力
- **所属模块**：cloudoffice-common（ConfigCacheManager）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / ADR-018
- **测试数据**：serviceName=auth-service，配置实体列表
- **测试步骤**：
  1. mock RedisTemplate（或使用内存模拟），构造 ConfigCacheManager
  2. 调用 cacheConfigs("auth-service", list)，断言写入成功（opsForValue().set 使用 TTL）
  3. 调用 getCachedConfigs("auth-service")，断言返回列表一致
  4. 调用 evict("auth-service")，断言缓存被删除，再次 get 返回 null
  5. 断言缓存键格式为 common:config:{serviceName}
- **预期结果**：
  1. 缓存写入/读取/失效行为正确
  2. 缓存键符合约定，TTL 生效
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/cache/ConfigCacheManagerTest.java（cacheConfigs_shouldSetWithTtl、getCachedConfigs_shouldReturnCachedOrNull、evict_shouldDeleteCache、cache_shouldTolerateRedisErrors）
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-008：ConfigMapper 查询能力（P0）
- **用例ID**：TC-TASK004-008
- **用例名称**：ConfigMapper 继承 BaseMapper，按条件/按服务名查询可用
- **所属模块**：cloudoffice-common（ConfigMapper）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003
- **测试数据**：ConfigEntity 与 t_common_config 表映射
- **测试步骤**：
  1. 反射加载 ConfigMapper 类，断言继承 BaseMapper<ConfigEntity> 且标注 @Mapper
  2. 反射加载 ConfigEntity，断言 @TableName("t_common_config") 与字段映射（serviceName/group/key/value/sensitive/status）
  3. 断言 ConfigMapper 提供按条件（serviceName/group/key）与按服务名查询方法（LambdaQueryWrapper 可用）
- **预期结果**：
  1. Mapper 与实体映射正确
  2. 条件查询与按服务名查询方法齐全
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/mapper/ConfigMapperTest.java（configMapper_shouldExtendBaseMapper、configEntity_shouldMapTableAndFields）
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-009：查询结果为空返回 200 空列表（P0）
- **用例ID**：TC-TASK004-009
- **用例名称**：指定微服务无配置项或条件无匹配时返回 code=200 与空列表（非 500）
- **所属模块**：cloudoffice-common（ConfigService 边界）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-003 / API-035 / API-036
- **测试数据**：serviceName=system-service（无配置项），条件查询无匹配
- **测试步骤**：
  1. mock ConfigMapper 返回空列表，注入 ConfigService
  2. 调用 queryConfigsByService("system-service")
  3. 断言返回 ApiResult code=200，data 为空的 List
  4. 调用 queryConfigList(null, null, "not-exist-key", 1, 10)，断言 PageResult.records 为空、total=0
- **预期结果**：
  1. 返回 200 空列表，不抛异常
  2. 分页返回空 records 与 total=0
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（query_shouldReturnEmptyOnNoMatch）；接口测试 scripts/API-TEST/cso-api-test-v0.2.8.py → test_task004_config_query_endpoints
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

#### TC-TASK004-010：存储异常返回 500、不实现写入接口（P0）
- **用例ID**：TC-TASK004-010
- **用例名称**：配置存储异常返回 500；Controller 不提供 POST/PUT/DELETE 写入端点
- **所属模块**：cloudoffice-common（异常兜底 + 扩展预留）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-002 / F-005 / ADR-018
- **测试数据**：ConfigMapper 抛异常；反射检查 Controller 方法注解
- **测试步骤**：
  1. mock ConfigMapper 抛 RuntimeException，调用 queryConfigsByService("auth-service")
  2. 断言异常向上抛出（由全局 GlobalExceptionHandler 兜底返回 500，不泄露堆栈）
  3. 反射枚举 ConfigController 全部方法，断言不存在 @PostMapping/@PutMapping/@DeleteMapping 注解
- **预期结果**：
  1. 存储异常经全局处理器返回 500
  2. 本版本无任何写入端点（POST/PUT/DELETE 预留扩展点不实现）
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/service/ConfigServiceTest.java（query_shouldPropagateStorageException）；cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/controller/ConfigControllerTest.java（configController_shouldHaveNoWriteEndpoints）
- **测试过程与结论**：通过（2026-08-13 单元测试执行：cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务全部单测；接口用例因 common 服务未启动（Nacos/MariaDB/Redis 未就绪）按环境阻塞 SKIP，不计失败）

> 说明：本任务为后端接口服务，无前端界面，UI 测试不适用；接口测试（含网关认证 401、脱敏、分页契约）由 impm-task-coding-writetest 步骤在 `scripts/API-TEST/cso-api-test-v0.2.8.py` 合并实现，runtest 步骤按环境执行（common 服务未启动时按环境阻塞 SKIP）。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 单元测试 10/10（cloudoffice-common 模块 Tests run: 146, Failures: 0, Errors: 0，含本任务 8/8 单测类全部用例）；接口测试 14 项 PASS（含 TASK-002/003/005/006/008 回归） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 接口用例 5 项 SKIP（TC-TASK004-002/003/004/005/009，common 服务未启动：Nacos 8848 未运行、MariaDB/Redis 未就绪，按环境阻塞不计失败） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 与并行任务（TASK-001/002/003/005/006/008）写版本文档冲突 | 测试用例文档可能被覆盖 | 写入前读取最新内容，合并写回并回读校验 |
| common 服务端（TASK-002/003）依赖中间件 | 单元测试使用 Mockito 隔离，不依赖真实 DB/Redis/Nacos | 接口测试对未启动服务按环境阻塞 SKIP |
| 缓存依赖 Redis | 单测不启动真实 Redis | ConfigCacheManager 单测 mock RedisTemplate |
| 全量编译耗时 | 编译回归时间较长 | 使用 -DskipTests 加速，仅断言退出码与产物 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
