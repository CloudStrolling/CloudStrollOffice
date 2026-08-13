# 本地代码查询（#TASK-002 cloudoffice-common 服务化改造）

## 1. cloudoffice-common 现状（改造前）

| 文件 | 现状 | 说明 |
| --- | --- | --- |
| cloudoffice-common/pom.xml | packaging=jar，无启动类、无 spring-boot-maven-plugin、无 Nacos/bootstrap 依赖 | 纯公共 jar 模块；含 spring-boot-starter-web、mybatis-plus-spring-boot3-starter、springdoc-openapi-starter-webmvc-ui、hutool-all、spring-security-core、lombok、spring-boot-starter-test |
| src/main/java/.../common/util/JsonUtils.java | 公共工具类 | 保留 |
| src/main/java/.../common/model/ | ApiResult / PageResult / BaseEntity / ErrorCode | 保留（下游依赖） |
| src/main/java/.../common/dto/ | TokenPairDTO / LoginUserDTO | 保留 |
| src/main/java/.../common/enums/ | ClientTypeEnum / LoginModeEnum / RegisterModeEnum / OAuthProviderEnum | 保留 |
| src/main/java/.../common/exception/ | BaseException / BusinessException / AuthException / ErrorCode / GlobalExceptionHandler（@RestControllerAdvice） | 保留；GlobalExceptionHandler 引用 spring-security-core 的 BadCredentialsException / AccessDeniedException |
| src/main/java/.../common/constant/RedisKeyConstants.java | Redis 键常量 | 保留 |
| src/main/java/.../common/config/ | SpringDocConfig（@Configuration，4 个 @Bean GroupedOpenApi：auth/biz/cloud/system，pathsToMatch 为 /api/auth/** 等旧路径）、MyBatisPlusConfig（@Configuration，实现 MetaObjectHandler） | **注意**：common 独立启动时组件扫描会加载二者；MyBatis-Plus 自动配置会触发 DataSource 依赖，需排除 |

## 2. 服务化参考样板（auth-service，与其对齐）

- `cloudoffice-auth-service/pom.xml`：已引入 `spring-cloud-starter-alibaba-nacos-discovery`、`spring-cloud-starter-alibaba-nacos-config`、`spring-cloud-starter-bootstrap`（4.1.2，父 POM dependencyManagement 显式管理版本）；build 段含 `spring-boot-maven-plugin` + `maven-antrun-plugin`（package 阶段将 `${project.build.directory}/${project.build.finalName}.jar` 复制为 `deploy/cloudoffice-auth-service.jar`）。
- `bootstrap.yml`：`spring.application.name=cloudoffice-auth-service`；Nacos discovery/config server-addr 均 `${NACOS_ADDR:127.0.0.1:8848}`、namespace `${NACOS_NAMESPACE:cso-dev}`、group 服务名、config file-extension yaml。
- `application.yml`：`server.port: 9100`（auth 固定端口）；springdoc api-docs/swagger-ui enabled；`spring.application.name` 重复声明。
- `AuthApplication.java`：`@SpringBootApplication @EnableDiscoveryClient @EnableConfigurationProperties` + main。
- `HealthController.java`（auth 参考，TASK-003 的 common 版由下游任务实现）：`/api/v1/auth/health` 返回 ApiResult<Map>（service/status/version/timestamp），Environment 读取服务名。

## 3. 父 POM 与下游依赖约束

- 父 `pom.xml`：`spring-cloud-bootstrap 4.1.2` 已在 dependencyManagement 显式管理（遮蔽 BOM）；`spring-cloud-dependencies 2023.0.1`、`spring-cloud-alibaba-dependencies 2023.0.1.0` BOM 管理 Nacos 依赖版本；`${deployDir}=${maven.multiModuleProjectDirectory}/deploy`。
- 模块顺序：cloudoffice-common 为第一模块（modules 首位），auth/biz/system/gateway 均依赖 common。
- **gateway 排除项**（build.md 第 39 行 + gateway pom）：依赖 common 时排除 `spring-boot-starter-web`、`springdoc-openapi-starter-webmvc-ui`、`mybatis-plus-spring-boot3-starter`（Reactive WebFlux 不兼容 MVC / 无 DataSource）。common 新增 Nacos/bootstrap 依赖后，gateway 已自有这些依赖，无需新增排除。
- **下游编译/运行不受影响的保证**：reactor 内 `mvn clean package` 时下游对 common 使用 target/classes 直接解析，不受 common 的 repackage 影响；为保证独立 `mvn install`/单独模块构建场景下 common 作为依赖仍为**瘦 jar**，common 的 spring-boot-maven-plugin 需配置 `<classifier>exec</classifier>`（可执行 fat jar 以 -exec.jar 产出，主 artifact 仍为普通 jar）。

## 4. 部署脚本/文档现状（供理解，不在本任务修改）

| 文件 | 现状（v0.2.7） |
| --- | --- |
| deploy/scripts/build-backend.ps1/.sh | 校验 4 个 jar（gateway/auth/biz/system），common 不在其中（TASK-006 修改） |
| deploy/scripts/deploy-start-all.ps1/.sh | SERVICES 数组顺序 gateway→auth→biz→system，校验 4 个 jar；v0.2.7 标题与注释（TASK-007 修改） |
| deploy/scripts/deploy-stop-all.ps1/.sh | 停止顺序 system→biz→auth→gateway（TASK-008 修改） |
| deploy/scripts/deploy-start-{gateway|auth|biz|system}.* | 单服务启动脚本（TASK-007 新增 common 版） |
| deploy/deploy.md / readme.md | 4 服务部署说明（TASK-010 修改） |
| deploy/env.json / env.example.json | 无 COMMON_PORT（TASK-009 修改） |
| deploy/build.md | 5 模块构建说明（不含 common 服务化说明） |

## 5. 本任务（TASK-002）编码结论

1. **CommonApplication.java**：新建 `org.cloudstrolling.cloudoffice.common.CommonApplication`，`@SpringBootApplication @EnableDiscoveryClient` + main（参考 AuthApplication）。
2. **bootstrap.yml**：新建，应用名 `cloudoffice-common`，Nacos discovery/config server-addr `${NACOS_ADDR:127.0.0.1:8848}`、namespace `${NACOS_NAMESPACE:cso-dev}`、group `cloudoffice-common`、file-extension yaml（对齐 auth）。
3. **application.yml**：新建，`server.port: ${COMMON_PORT:9300}`；`spring.application.name: cloudoffice-common`；**排除 DataSource/MyBatis 自动配置**（common 独立启动不依赖数据库，避免 "Failed to configure a DataSource"；TASK-004 增加配置查询时再补数据源）；springdoc 分组 `common`（group-configs paths-to-match `/api/v1/common/**`，避免改动共享 SpringDocConfig 的 @Bean，也与 TASK-003 约定分组名一致）。
4. **pom.xml**：新增 `spring-cloud-starter-bootstrap`、`spring-cloud-starter-alibaba-nacos-discovery`、`spring-cloud-starter-alibaba-nacos-config`；build 段新增 `spring-boot-maven-plugin`（classifier=exec，保持主 artifact 为普通 jar，保护下游依赖）+ `maven-antrun-plugin`（package 将 `-exec.jar` 复制为 `deploy/cloudoffice-common.jar`）。
5. **保留**：公共 jar 能力（ApiResult/PageResult/异常体系/枚举/工具/常量）与全部现有类不动。

## 6. 版本共享文档（读最新）

- `docs/cso-v0.2.8/cso-prd-v0.2.8.md`：F-001/F-002 common 服务化与 API 服务；US-001 验收。
- `docs/cso-v0.2.8/cso-api-v0.2.8.md`：API-034 common health（TASK-003）、API-035/036 配置查询（TASK-004）。
- `docs/cso-v0.2.8/cso-dbd-v0.2.8.md`：t_common_config 表（TASK-001/004 使用）。
- 任务边界：TASK-003（HealthController+SpringDoc 分组）、TASK-004（配置查询）、TASK-005（网关路由/白名单）、TASK-006~010（脚本/文档/env）均为其他任务，本任务不改。
