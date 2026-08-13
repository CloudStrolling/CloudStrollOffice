# TASK-004 网络资料查询（ws.md）

## 一、涉及的第三方组件（TASK-004 通用配置管理查询接口）

| 组件 | 用途 | 项目版本 | 资料版本兼容性 |
| --- | --- | --- | --- |
| MyBatis-Plus 3.5.6（mybatis-plus-spring-boot3-starter） | 条件查询（LambdaQueryWrapper）、分页（selectPage） | 3.5.6（父 POM dependencyManagement 管理） | 已按 Spring Boot 3.x 引入（mybatis-plus-spring-boot3-starter 即针对 Boot 3 的 starter），兼容 |
| Spring Data Redis（spring-boot-starter-data-redis，Lettuce） | 通用配置本地缓存（RedisTemplate 读写、TTL） | 由 Spring Boot 3.2.5 BOM 管理 | 兼容；auth 服务已同版本使用（RedisConfig 模式可参照） |
| Hutool 5.8.26 | JSON 序列化/工具（可选） | 5.8.26 | 兼容 |
| SpringDoc OpenAPI 2.5.0 | common 分组文档（已配置，无需改动） | 2.5.0 | 兼容 |

> 注：cloudoffice-common pom **当前未引入 spring-boot-starter-data-redis**，TASK-004 需新增该依赖（auth 服务已用同版本，无版本冲突；网关 pom 已在依赖 common 时排除了 MVC/springdoc/mybatis，data-redis 属可传递依赖，需评估网关是否受影响——网关已自带 data-redis 用于响应式校验，无冲突）。

## 二、MyBatis-Plus 分页与条件查询官方用法（官方文档 data-interface / wrapper）
- **分页查询**：`IPage<T> page = new Page<>(pageNum, pageSize); IPage<T> result = mapper.selectPage(page, wrapper);`
  - `result.getRecords()` 取记录列表、`result.getTotal()` 取总条数（long）。
- **条件构造**：`LambdaQueryWrapper<T>` 类型安全：
  - `wrapper.eq(Entity::getField, value)` 等值；`wrapper.like(...)` 模糊；可链式组合多条件。
  - 空条件判断：`StrUtil.isNotBlank(x)` 后再 `eq`，实现可选参数过滤。
- **select 指定字段**：`wrapper.select(Entity::getId, ...)`（本任务 VO 转换走实体全字段，通常不裁剪）。
- **注意**：分页需配置 MyBatis-Plus 分页插件（本项目 auth 服务 MyBatisPlusConfig 已配 PaginationInnerInterceptor？需确认 common 侧 MyBatisPlusConfig 是否含分页插件——common 现有 MyBatisPlusConfig 只实现 MetaObjectHandler，**分页插件缺失时 selectPage 仅返回全部数据不分页**，TASK-004 需在 common 的 MyBatisPlusConfig 中补充分页插件拦截器）。

## 三、Spring Data Redis 缓存用法（官方文档 template.adoc / ValueOperations）
- **注入模板**：`@Resource private RedisTemplate<String, Object> redisTemplate;` 或 `StringRedisTemplate`。
- **Key 序列化**：Key 用 StringRedisSerializer；Value 用 Jackson2JsonRedisSerializer（含类型信息，参照 auth RedisConfig 的 @Bean redisTemplate）。
- **读写带 TTL**：
  - `ValueOperations<String,Object> ops = template.opsForValue();`
  - `ops.set(key, value)` 写；
  - `ops.get(key)` 读（返回 Object，需类型转换/反序列化）；
  - `ops.set(key, value, Duration.ofSeconds(ttl))` 写并设置 TTL（推荐 `set(K,V,Expiration)`/`set(K,V,long,TimeUnit)`，对应官方 ValueOperations.set(K,V,Expiration)）；
  - `template.delete(key)` 删除（缓存失效）；`template.expire(key, Duration)` 更新过期时间。
- **缓存键设计**：以 serviceName 为粒度，建议 `common:config:{serviceName}`（放入 RedisKeyConstants 常量，沿用 auth 的 `auth:*` 前缀风格）。

## 四、版本兼容性结论
- 全部组件与 Spring Boot 3.2.5 / Java 21 兼容，无已知冲突。
- cloudoffice-common 新增 spring-boot-starter-data-redis：与 auth 服务（已用）同版本；与 gateway 的响应式 Redis（ReactiveRedisTemplate）不冲突（不同 Bean）。
- 新增 DataSource（MariaDB）与 mybatis-plus 数据源配置：common 独立启动需数据库 `cloudstroll_office_common` 存在（DBD v0.2.8 建库脚本），否则启动报 DataSource 错误——TASK-004 编码需在 application.yml 配置 datasource 并移除 DataSource/MyBatis 自动配置排除（或保持排除仅当服务化时用外部配置）。

## 五、相关方案要点（敏感配置脱敏）
- 脱敏实现：查询结果转换 VO 时，`sensitive==1` 的配置项 `value` 替换为掩码；掩码默认 `****`，可由 common 服务自身配置 `common.config.sensitive-mask`（@ConfigurationProperties 注入）覆盖（与 DBD 种子 `common/config/sensitive-mask` 呼应）。
- 缓存回填策略：未命中 → 查询数据库 → 写入缓存（TTL 默认 300s，可配置）→ 返回；敏感脱敏发生在回填/返回前，确保缓存不存明文敏感值。
- serviceName 合法性校验：白名单枚举 gateway/auth-service/biz-service/system-service/common，非法抛 BusinessException(400)。
