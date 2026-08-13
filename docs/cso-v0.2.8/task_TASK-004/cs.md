# TASK-004 现有代码查询（cs.md）

## 一、模块结构（cloudoffice-common，v0.2.8 已服务化）
基包：`org.cloudstrolling.cloudoffice.common`
- 启动类：`CommonApplication.java`（@SpringBootApplication + @EnableDiscoveryClient，main 方法）
- 配置：`config/MyBatisPlusConfig.java`（MetaObjectHandler 自动填充 createTime/updateTime/deleted）、`config/SpringDocConfig.java`
- 常量：`constant/RedisKeyConstants.java`（@UtilityClass，Key 前缀常量 + 构建方法）
- 公共模型：`model/ApiResult.java`、`model/PageResult.java`、`model/BaseEntity.java`、`model/ErrorCode.java`（接口）
- 异常：`exception/BaseException.java`、`BusinessException.java`、`AuthException.java`、`GlobalExceptionHandler.java`（@RestControllerAdvice）
- 控制器：`controller/HealthController.java`（GET /api/v1/common/health）
- 工具：`util/JsonUtils.java`

## 二、关键代码模式（TASK-004 实现参照）

### 2.1 统一响应体 ApiResult<T>（model/ApiResult.java）
- 字段：code(Integer)/message(String)/data(T)/timestamp(Long，构造自动填充毫秒)
- 静态工厂：`success(T data)`（code=200、message=操作成功）、`success(String,T)`、`success()`、`error(code,msg)`、`error(ErrorCode)`、`error(code,msg,data)`
- 链式 @Accessors(chain=true) + @Data

### 2.2 分页结果 PageResult<T>（model/PageResult.java）
- 字段：records(List，默认 new ArrayList)/total(Long)/page(Integer)/pageSize(Integer)
- 静态工厂：`empty()`（total=0/page=1/pageSize=10）、`of(records,total,page,pageSize)`

### 2.3 基础实体 BaseEntity（model/BaseEntity.java）
- 字段：id(@TableId ASSIGN_ID 雪花)、createTime(@TableField fill=INSERT)、updateTime(fill=INSERT_UPDATE)、deleted(@TableLogic + fill=INSERT)
- 与 MyBatisPlusConfig 自动填充配合，@TableName 由子类标注

### 2.4 异常体系
- `ErrorCode`（接口）：getCode()/getMessage()
- `BusinessException(Integer code,String message)`：可传错误码+消息，GlobalExceptionHandler 按 code 映射 HTTP 状态（HttpStatus.resolve）
- `GlobalExceptionHandler`：已处理参数校验/业务异常/兜底 Exception（500 INTERNAL_ERROR，不泄露堆栈）

### 2.5 Redis 使用模式（参照 auth-service config/RedisConfig.java）
- `RedisTemplate<String, Object>` + StringRedisSerializer(key) + Jackson2JsonRedisSerializer(value 含类型信息)
- 注解 @Configuration + @Bean redisTemplate(RedisConnectionFactory)
- 依赖：spring-boot-starter-data-redis（auth pom 中引入，common pom 当前**未引入**，需补充）

### 2.6 Mapper 模式（参照 auth-service mapper/UserMapper.java）
- `@Mapper public interface XxxMapper extends BaseMapper<Entity>`，方法加 @Param
- MyBatis-Plus 内置条件构造器（LambdaQueryWrapper）满足条件查询/分页

### 2.7 配置属性模式（参照 auth PasswordProperties/VerificationCodeProperties）
- @ConfigurationProperties(prefix="...") + @Component/@ConfigurationPropertiesScan，构造注入

## 三、TASK-004 编码将新增/修改的文件（cloudoffice-common 模块内）
| 文件 | 说明 |
| --- | --- |
| entity/ConfigEntity.java | t_common_config 实体，@TableName("t_common_config")，继承 BaseEntity |
| mapper/ConfigMapper.java | @Mapper extends BaseMapper<ConfigEntity>，条件/按服务名查询 |
| vo/ConfigItemVO.java | 响应 VO（id/serviceName/group/key/value/dataType/description/sensitive/status/createTime/updateTime） |
| config/ConfigProperties.java | 通用配置管理属性（cacheTtlSeconds=300、sensitiveMask=****） |
| config/RedisConfig.java | RedisTemplate Bean（common 新增，参照 auth） |
| cache/ConfigCacheManager.java | 以 serviceName 为粒度的缓存读写与失效 |
| service/ConfigService.java | 缓存优先→回源数据库→回填缓存→脱敏 编排 |
| controller/ConfigController.java | GET /api/v1/common/config、GET /api/v1/common/config/{serviceName} |
| resources/application.yml | 补充 DataSource（cloudstroll_office_common）/Redis/mybatis-plus 配置 |
| pom.xml | 补充 spring-boot-starter-data-redis 依赖（若缺失） |

## 四、数据库表结构（DBD v0.2.8 §5.2.1 t_common_config）
- 库：`cloudstroll_office_common`；表：`t_common_config`
- 字段：id(BIGINT 主键)、service_name(VARCHAR 50)、config_group(VARCHAR 50)、config_key(VARCHAR 100)、config_value(TEXT)、data_type(VARCHAR 20，默认 string)、description(VARCHAR 500)、sensitive(TINYINT 0/1)、status(TINYINT 0-启用/1-禁用)、create_time/update_time(DATETIME)、deleted(TINYINT 逻辑删除)
- 唯一索引 uk_service_group_key(service_name,config_group,config_key)；普通索引 idx_service_name(service_name)、idx_config_group(service_name,config_group)
- 合法 serviceName：gateway/auth-service/biz-service/system-service/common
- dataType：string/number/boolean/json
- 种子数据：common/config/cache-ttl-seconds=300、common/config/sensitive-mask=**** 等

## 五、接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py）
- 已含 TASK-002/003/005/006 用例（report()/http_get() 辅助函数、PASS/FAIL/SKIP 汇总、main() 入口）
- TASK-004 需**先读最新脚本再合并追加**：新增 TASK-004 接口测试函数（API-035/036 查询契约、serviceName 非法 400、敏感脱敏、空列表 200 等）并在 main() 注册
- 约定：网关不可达/服务未启动按环境阻塞 SKIP；退出码 0=通过、1=失败

## 六、单元测试模式（参照 HealthControllerTest / CommonApplicationConfigTest）
- 纯 JUnit5 + Mockito mock 构造，不依赖 Spring 上下文/真实 DB/Redis
- @DisplayName 中文用例名，TC-TASK004-XXX 编号
- common 当前 application.yml 排除 DataSource/MyBatis 自动配置，新增 DataSource/Redis 配置后需保证现有测试（读 classpath 资源字符串断言）仍通过；ConfigService 等用 Mockito 隔离依赖测试，避免上下文启动依赖真实中间件

## 七、重要约束
- TASK-004 只写 cloudoffice-common 模块代码与本任务目录文件，不越界修改 gateway/auth/biz/system
- 不实现 POST/PUT/DELETE 写入，接口层/数据层预留扩展点
- 不得破坏下游服务对 common 的 Maven 依赖（新增依赖需评估：data-redis 会被下游间接引入，auth 已用同版本无冲突）
- 日志禁止输出敏感配置明文
