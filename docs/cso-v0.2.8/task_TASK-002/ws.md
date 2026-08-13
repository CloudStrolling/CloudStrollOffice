# 网络资料查询（#TASK-002 cloudoffice-common 服务化改造）

## 1. Nacos 服务注册/配置（Spring Cloud Alibaba 2023.0.1.0）

- **官方文档**（Context7 `/alibaba/spring-cloud-alibaba`，nacos-example readme-zh）：
  - Nacos 服务发现 starter：`com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery`，注册配置走 `spring.cloud.nacos.discovery.server-addr`；
  - Nacos 配置中心 starter：`com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-config`；
  - **版本说明**：2023.0.1.x 中 nacos-config 推荐使用 `spring.config.import` 替代 bootstrap 模式；但本项目自 v0.2.6（ADR-014）起统一采用 **bootstrap.yml + spring-cloud-starter-bootstrap** 引导 Nacos，且 auth/gateway/biz/system 四服务均以此方式稳定运行。**TASK-002 遵循既有工程约定（bootstrap 模式），保持四服务一致**，不切换为 spring.config.import，避免破坏已运行的注册/配置链路。
- **bootstrap 模式要点**：`spring-cloud-starter-bootstrap` 恢复 Spring Boot 3.x 下的 bootstrap.yml 加载（修复 `No spring.config.import property has been defined`）；bootstrap.yml 中配置 `spring.application.name`（服务注册名）、`spring.cloud.nacos.discovery.server-addr`、`spring.cloud.nacos.config.server-addr`、namespace、group、file-extension（yaml）。Nacos 中不存在的 dataId 配置在 bootstrap 模式下仅告警不阻断启动（与 auth-service 现状一致）。
- **健康检查**：服务注册后 Nacos 控制台服务列表可见；健康确认由部署脚本 HTTP 探测 `/api/v1/common/health`（TASK-003 实现端点）。

## 2. Spring Boot 3.2.5 可执行 jar 打包（spring-boot-maven-plugin）

- **repackage 目标**：`spring-boot-maven-plugin` 默认在 package 阶段将应用 jar 重打为可执行 fat jar（BOOT-INF/classes + BOOT-INF/lib + org.springframework.boot.loader）。
- **classifier 参数**：配置 `<configuration><classifier>exec</classifier></configuration>` 后，repackage 产物为 `${finalName}-exec.jar`（可执行 fat jar），**主 artifact `${finalName}.jar` 仍为普通瘦 jar**。
- **本任务用途**：common 既是可独立部署服务（需要可执行 jar 落位 deploy），又是 gateway/auth/biz/system 的 Maven 依赖（需要瘦 jar artifact，避免依赖方 classpath 拿到 BOOT-INF/classes 无法解析）。**必须使用 classifier=exec**，保证两种角色兼容。
- **maven-antrun-plugin**：各服务模块统一用 `maven-antrun-plugin` 在 package 阶段将最终 jar 复制为 `deploy/{模块}.jar`（唯一落点，父 POM `${deployDir}` 已定义）。common 复制源为 `target/cloudoffice-common-0.0.1-SNAPSHOT-exec.jar`，目标 `deploy/cloudoffice-common.jar`。

## 3. SpringDoc OpenAPI 3（springdoc-openapi 2.5.0）

- **分组配置**：`springdoc.group-configs`（YAML）支持按 `group` + `paths-to-match` 声明分组，无需 Java @Bean；示例：
  ```yaml
  springdoc:
    group-configs:
      - group: common
        paths-to-match: /api/v1/common/**
  ```
- **约定**：common 服务独立部署，application.yml 中启用 api-docs/swagger-ui，分组 `common`，与 API 文档（cso-api-v0.2.8.md）第 2 节"common 服务新增文档分组 common"一致。
- **说明**：common 模块共享的 `SpringDocConfig` 已有 auth/biz/cloud/system 四个 @Bean 分组（pathsToMatch /api/auth/** 等旧路径），common 独立运行时这些分组不匹配端点但无碍启动；为**避免改动共享类**影响下游服务，common 分组通过 application.yml `group-configs` 声明（TASK-003 实现 HealthController 后分组即生效）。

## 4. DataSource 自动配置排除

- **问题**：common pom 已含 `mybatis-plus-spring-boot3-starter`，其自动配置 `MybatisPlusAutoConfiguration` 需要 `DataSource`；common 独立启动无数据源配置将报 `Failed to configure a DataSource`（与 gateway 历史缺陷同因，build.md 第 39 行记录）。
- **方案**：common 的 application.yml 通过 `spring.autoconfigure.exclude` 排除 `org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration` 与 `com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration`。该排除仅对 common 自身 application.yml 生效，不影响下游服务（下游用各自 application.yml 加载，MyBatis 功能不受影响）。TASK-004 增加配置查询（需连 t_common_config）时再补充数据源配置与取消排除。

## 5. 小结

| 主题 | 结论 |
| --- | --- |
| Nacos 引导 | bootstrap.yml + spring-cloud-starter-bootstrap（沿用 ADR-014） |
| 可执行 jar | spring-boot-maven-plugin classifier=exec，antrun 复制 deploy/cloudoffice-common.jar |
| 下游依赖安全 | classifier=exec 保证 common 主 artifact 仍为瘦 jar |
| SpringDoc 分组 | application.yml springdoc.group-configs group=common |
| 数据源 | 排除 DataSource/MyBatis 自动配置，common 独立启动不依赖 DB |
