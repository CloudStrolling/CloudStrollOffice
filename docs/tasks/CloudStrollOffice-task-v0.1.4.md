# 任务清单

**项目：** CloudStrollOffice
**版本：** v0.1.4
**对应PRD：** `docs/prds/CloudStrollOffice-prd-v0.1.4.md`
**对应架构：** `docs/architecture.md`
**对应SDS：** `docs/sds/CloudStrollOffice-sds-v0.1.4.md`
**对应项目文件：** `docs/project.md`
**生成日期：** 2026-06-19

# 1. 模块任务清单：

| 模块 | 功能 | 任务编码 | 任务内容 |
|------|------|---------|---------|
| 系统服务 | 启动入口 | TASK-001 | 创建 SystemApplication 启动类 |
| 系统服务 | 应用配置 | TASK-002 | 配置 bootstrap.yml 和 application.yml ✅ |
| 系统服务 | Maven配置 | TASK-003 | 配置 pom.xml Maven 依赖 |
| 系统服务 | 健康检查 | TASK-004 | 实现 HealthController 健康检查接口 ✅ |
| 系统服务 | 骨架目录 | TASK-005 | 建立标准包目录结构 |
| 系统服务 | 测试配置 | TASK-006 | 配置测试环境 bootstrap.yml |
| 系统服务 | 单元测试 | TASK-007 | 编写系统服务单元测试 |

# 2. 系统服务模块

## 2.1 启动入口

### 2.1.1 TASK-001：创建 SystemApplication 启动类

**任务ID：** TASK-001
**任务名称：** 创建 SystemApplication 启动类
**任务类型：** backend
**关联UserStory：** US-001
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-002（应用配置）、TASK-004（健康检查）

#### 上下文读取
- **PRD US-001 AC4**：启动类需标注 `@SpringBootApplication` 和 `@EnableDiscoveryClient` 注解，包含标准 main 方法
- **PRD US-001 AC5**：配置排除 `DataSourceAutoConfiguration`，允许无数据库启动
- **PRD 4.1 模块规格**：包名 `org.cloudstrolling.cloudoffice.system`，模块名 `cloudoffice-system-service`
- **SDS 2.4 关键类说明**：SystemApplication 类功能描述，排除数据源自动配置
- **SDS 9.3 配置模板**：`spring.autoconfigure.exclude` 排除数据源
- **architecture.md 2.5**：系统服务模块职责描述
- **project.md 文件组织规范**：启动类命名规范，@author/@since 注释规范

#### 详细业务描述
在 `src/main/java/org/cloudstrolling/cloudoffice/system/` 目录下创建 `SystemApplication.java`，作为 cloudoffice-system-service 模块的 Spring Boot 启动类。

**核心要求：**
1. 包声明：`package org.cloudstrolling.cloudoffice.system;`
2. 注解：`@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)` + `@EnableDiscoveryClient`
3. 包含标准 `main` 方法，调用 `SpringApplication.run(SystemApplication.class, args)`
4. 类注释：包含 `@author CloudStrolling` 和 `@since 1.0`
5. 方法注释：`@param args` 命令行参数说明
6. 文件头：SPDX-License-Identifier 和 Copyright 信息
7. 使用 `@Slf4j` 记录启动日志（启动完成时输出 INFO 日志）

**关键决策：**
- 排除 `DataSourceAutoConfiguration`：即使 MariaDB 未启动，服务也能正常启动，仅输出 WARN 日志
- `@EnableDiscoveryClient`：启用 Nacos 服务注册，服务启动后自动注册到 Nacos

#### 测试验收方法
- 启动类在 IDE 中可直接运行
- `@SpringBootTest` 上下文加载测试通过
- 启动类上存在 `@EnableDiscoveryClient` 注解（通过反射验证）
- 编译通过：`mvn clean compile -pl cloudoffice-system-service -am`

---

### 2.1.2 TASK-002：配置 bootstrap.yml 和 application.yml

**任务ID：** TASK-002
**任务名称：** 配置应用配置文件
**任务类型：** backend
**关联UserStory：** US-003
**优先级：** P0
**当前状态：** commit_finish

#### 上下游任务
- 上游任务：TASK-001（启动类）
- 下游任务：TASK-003（Maven配置）

#### 上下文读取
- **PRD US-003 AC1**：`spring.application.name` 为 `cloudoffice-system-service`，连接 Nacos 注册中心和配置中心
- **PRD US-003 AC2**：监听端口 9400
- **PRD US-003 AC3**：数据源配置通过环境变量注入，默认值 `127.0.0.1:3306`
- **PRD US-003 AC4**：MyBatis-Plus 驼峰映射、SQL 日志、逻辑删除配置
- **PRD US-003 AC5**：SpringDoc 配置，`/swagger-ui.html` 和 `/v3/api-docs` 可访问
- **PRD US-003 AC6**：日志级别 `org.cloudstrolling` 为 DEBUG
- **PRD 3.4 安全性**：数据库密码通过环境变量 `DB_PASSWORD` 注入，禁止硬编码
- **SDS 9.3 配置模板**：bootstrap.yml 和 application.yml 完整配置模板
- **SDS 3.3 数据库连接配置**：排除 DataSourceAutoConfiguration，环境变量覆盖默认值
- **SDS 3.4 MyBatis-Plus 配置**：驼峰映射、SQL 日志、逻辑删除

#### 详细业务描述
创建两个配置文件：

**bootstrap.yml（配置 Nacos 注册/配置中心）：**
- `spring.application.name`: `cloudoffice-system-service`
- `spring.cloud.nacos.discovery.server-addr`: `${NACOS_ADDR:127.0.0.1:8848}`
- `spring.cloud.nacos.config.server-addr`: `${NACOS_ADDR:127.0.0.1:8848}`
- `spring.cloud.nacos.config.file-extension`: `yaml`

**application.yml（配置应用层参数）：**
- `server.port`: 9400
- 数据源配置（所有参数支持环境变量覆盖）：
  - `spring.datasource.url`: `${DB_URL:jdbc:mariadb://localhost:3306/cloudstroll_office_system?useUnicode=true&characterEncoding=utf8mb4&serverTimezone=Asia/Shanghai}`
  - `spring.datasource.username`: `${DB_USER:root}`
  - `spring.datasource.password`: `${DB_PASSWORD:root123}`
  - `spring.datasource.driver-class-name`: `org.mariadb.jdbc.Driver`
- 排除数据源自动配置：`spring.autoconfigure.exclude` 包含 `org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration`
- MyBatis-Plus 配置：
  - `map-underscore-to-camel-case`: true
  - `log-impl`: `org.apache.ibatis.logging.stdout.StdOutImpl`
  - 逻辑删除字段: `deleted`，已删除值 `1`，正常值 `0`
- SpringDoc 配置：启用 api-docs 和 swagger-ui
- 日志级别：`org.cloudstrolling`: DEBUG

#### 测试验收方法
- 服务启动后监听端口 9400
- 健康检查端点可访问
- `/swagger-ui.html` 返回 Swagger UI 页面
- `/v3/api-docs` 返回 OpenAPI 3 JSON

---

### 2.1.3 TASK-003：配置 pom.xml Maven 依赖

**任务ID：** TASK-003
**任务名称：** 配置 Maven 模块依赖
**任务类型：** backend
**关联UserStory：** US-001
**优先级：** P0
**当前状态：** commit_finish

#### 上下游任务
- 上游任务：TASK-002（应用配置）
- 下游任务：无

#### 上下文读取
- **PRD US-001 AC5**：artifactId 为 `cloudoffice-system-service`，版本由父 POM 统一管理
- **PRD 4.2 依赖清单**：全部 7 项依赖及其作用域
- **SDS 2.2 模块依赖关系**：模块依赖图及依赖清单 Scope
- **project.md 依赖管理规范**：依赖版本在父 POM 统一管理，子模块不出现硬编码版本号
- **父 POM 路径**：`../pom.xml`

#### 详细业务描述
在 `cloudoffice-system-service` 模块下创建 `pom.xml`，包含以下配置：

**父 POM 引用：**
```xml
<parent>
    <groupId>org.cloudstrolling</groupId>
    <artifactId>cloudoffice</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <relativePath>../pom.xml</relativePath>
</parent>
```

**必须声明的依赖：**
| 依赖 | groupId:artifactId | Scope |
|------|-------------------|-------|
| Spring Boot Web | `org.springframework.boot:spring-boot-starter-web` | compile |
| MyBatis-Plus | `com.baomidou:mybatis-plus-spring-boot3-starter` | compile |
| MariaDB 驱动 | `org.mariadb.jdbc:mariadb-java-client` | compile |
| Nacos 服务发现 | `com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery` | compile |
| Nacos 配置中心 | `com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-config` | compile |
| 公共模块 | `org.cloudstrolling:cloudoffice-common` | compile |
| Lombok | `org.projectlombok:lombok` | provided |
| 测试框架 | `org.springframework.boot:spring-boot-starter-test` | test |

**构建插件：**
- `spring-boot-maven-plugin`：Spring Boot 打包插件

**注意事项：**
- 所有依赖版本均在父 POM 的 `<dependencyManagement>` 中管理，子模块不出现版本号
- 包类型为 `jar`

#### 测试验收方法
- `mvn clean compile -pl cloudoffice-system-service -am` 编译通过
- 编译后的 target 目录生成正确的 class 文件

---

## 2.2 健康检查接口

### 2.2.1 TASK-004：实现 HealthController 健康检查接口

**任务ID：** TASK-004
**任务名称：** 实现健康检查 REST 接口
**任务类型：** backend
**关联UserStory：** US-002
**优先级：** P0
**当前状态：** review-finish ✅

#### 上下游任务
- 上游任务：TASK-001（启动类）
- 下游任务：TASK-007（单元测试）

#### 上下文读取
- **PRD US-002 AC1~AC5**：健康检查完整响应格式定义
- **PRD 4.3 接口规范**：请求/响应 JSON 完整示例
- **SDS 4.2 外部 REST API**：GET /api/v1/system/health 接口设计
- **SDS 6.5 可维护性**：SpringDoc 注解（`@Schema`、`@Operation`）规范
- **architecture.md 6.3 接口契约**：ApiResult 统一响应体格式
- **project.md 编码规范**：
  - 构造器注入替代 `@Autowired` 字段注入
  - `@Slf4j` 注解记录日志
  - SpringDoc 注解生成 API 文档
- **SDS 4.2 响应字段说明**：`data.timestamp` 为 Long 类型（毫秒时间戳）

#### 详细业务描述
在 `src/main/java/org/cloudstrolling/cloudoffice/system/controller/` 目录下创建 `HealthController.java`，实现健康检查端点。

**核心要求：**

1. **类注解：**
   - `@RestController`
   - `@RequestMapping("/api/v1/system")`
   - `@Slf4j`
   - `@Tag(name = "系统服务健康检查", description = "系统服务健康检查与基础信息获取")`

2. **依赖注入：**
   - 使用构造器注入注入 `Environment env`（`@RequiredArgsConstructor` 或显式构造函数）
   - 禁止使用 `@Autowired` 字段注入

3. **端点方法：**
   - `@GetMapping("/health")`
   - `@Operation(summary = "健康检查", description = "返回系统服务运行状态，用于容器编排平台的就绪探针和存活探针检测")`
   - 返回类型：`ApiResult<Map<String, Object>>`

4. **响应体 data 字段（精确遵循 PRD 4.3 规范）：**
   - `service`：从 `spring.application.name` 获取，兜底值 `"cloudoffice-system-service"`
   - `status`：固定 `"UP"`
   - `version`：固定 `"0.0.1-SNAPSHOT"`（后续版本从 build-info 获取）
   - `timestamp`：`System.currentTimeMillis()` 返回 Long 类型（毫秒时间戳）

5. **日志记录：**
   - 每次请求记录 INFO 日志：`"健康检查被调用，状态：UP"`
   - 异常时记录 ERROR 日志

6. **文件注释：**
   - 类注释包含 `@author CloudStrolling` 和 `@since 1.0`
   - 方法注释包含 `@return` 描述
   - 文件头 SPDX-License-Identifier 和 Copyright

**关键决策：**
- `data.timestamp` 使用 Long 类型（epoch millis），而非 `Instant.now().toString()` 字符串格式，以匹配 PRD/SDS 响应格式定义
- 构造器注入优先（遵循 project.md 规范）

#### 测试验收方法
- `curl http://localhost:9400/api/v1/system/health` 返回：
  ```json
  {
    "code": 200,
    "message": "操作成功",
    "data": {
      "service": "cloudoffice-system-service",
      "status": "UP",
      "version": "0.0.1-SNAPSHOT",
      "timestamp": 1718000000000
    },
    "timestamp": 1718000000000
  }
  ```
- HTTP 状态码 200
- POST 请求返回 405
- 错误路径返回 404

---

## 2.3 骨架目录

### 2.3.1 TASK-005：建立标准包目录结构

**任务ID：** TASK-005
**任务名称：** 建立标准包目录结构
**任务类型：** backend
**关联UserStory：** US-004
**优先级：** P1
**当前状态：** completed ✅

#### 上下游任务
- 上游任务：TASK-001（启动类）
- 下游任务：无

#### 上下文读取
- **PRD US-004 AC1**：13 个标准目录列表
- **PRD US-004 AC2**：与 auth-service 和 biz-service 目录结构一致
- **PRD US-004 AC3**：包名遵循 `org.cloudstrolling.cloudoffice.system.{subpackage}`
- **PRD US-004 AC4**：resources 目录存在 bootstrap.yml 和 application.yml
- **SDS 2.3 标准包目录结构**：完整的目录树结构
- **project.md 文件组织规范**：13 个标准目录及功能说明

#### 详细业务描述
在 `src/main/java/org/cloudstrolling/cloudoffice/system/` 下创建以下 13 个标准包目录，每个目录放入 `.gitkeep` 占位文件（确保空目录被 Git 跟踪）：

| 目录 | 用途说明 | 预留状态 |
|------|---------|---------|
| `config/` | 配置类（MyBatis-Plus 配置、SpringDoc 配置等） | 预留 |
| `controller/` | 控制器层（含 HealthController.java） | 已实现 |
| `service/` | 业务逻辑层接口 | 预留 |
| `service/impl/` | 业务逻辑实现类 | 预留 |
| `mapper/` | 数据访问层（MyBatis-Plus Mapper） | 预留 |
| `entity/` | 实体类（数据库表映射） | 预留 |
| `dto/` | 数据传输对象 | 预留 |
| `vo/` | 视图对象（页面展示 VO） | 预留 |
| `enums/` | 枚举类 | 预留 |
| `exception/` | 模块级异常处理类 | 预留 |
| `filter/` | 过滤器 | 预留 |
| `interceptor/` | 拦截器 | 预留 |
| `util/` | 模块级工具类 | 预留 |

**注意事项：**
- 目录结构必须与 auth-service、biz-service 完全一致
- 包声明遵循 `org.cloudstrolling.cloudoffice.system.{subpackage}` 规范
- 资源文件 `src/main/resources/` 下包含 `bootstrap.yml` 和 `application.yml`

#### 测试验收方法
- 目录结构符合 SDS 2.3 规范
- 13 个目录全部创建且包含 `.gitkeep` 文件
- 目录结构与 auth-service 和 biz-service 对比一致

---

## 2.4 测试配置

### 2.4.1 TASK-006：配置测试环境 bootstrap.yml

**任务ID：** TASK-006
**任务名称：** 配置测试环境 bootstrap.yml
**任务类型：** test
**关联UserStory：** US-005
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-001（启动类）、TASK-002（应用配置）
- 下游任务：TASK-007（单元测试）

#### 上下文读取
- **PRD US-005 AC5**：测试环境 Nacos 服务发现和配置中心被禁用
- **PRD 3.6 测试**：测试可在不依赖外部中间件（Nacos、MariaDB）的环境下独立运行
- **SDS 2.3 测试模块**：`src/test/resources/bootstrap.yml` 测试 Nacos 禁用配置
- **SDS 6.6 测试要求**：测试环境禁用 Nacos，排除 DataSourceAutoConfiguration

#### 详细业务描述
在 `src/test/resources/` 目录下创建 `bootstrap.yml`，用于测试环境配置：

**必须禁用的配置：**
```yaml
spring:
  cloud:
    nacos:
      discovery:
        enabled: false        # 禁用 Nacos 服务发现
      config:
        enabled: false        # 禁用 Nacos 配置中心
        import-check:
          enabled: false      # 禁用 Nacos 配置导入检查
```

**目的：**
- 测试运行时不需要启动 Nacos 服务
- 测试不依赖外部中间件，可在无网络环境独立运行
- `@SpringBootTest` 加载上下文时不会尝试连接 Nacos

#### 测试验收方法
- 测试运行时 `spring.cloud.nacos.discovery.enabled=false` 生效
- `mvn test -pl cloudoffice-system-service` 在无 Nacos 环境下通过

---

## 2.5 单元测试

### 2.5.1 TASK-007：编写系统服务单元测试

**任务ID：** TASK-007
**任务名称：** 编写系统服务单元测试
**任务类型：** test
**关联UserStory：** US-005
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-001（启动类）、TASK-004（健康检查）、TASK-006（测试配置）
- 下游任务：无

#### 上下文读取
- **PRD US-005 AC1~AC6**：6 条单元测试验收标准
- **PRD 3.6 测试**：JUnit 5 + Mockito，Given-When-Then 模式
- **SDS 2.4 关键类说明**：SystemApplicationTest 和 HealthControllerTest 测试内容
- **SDS 6.6 测试要求**：环境独立性、测试命名规范
- **project.md 测试规范**：`@SpringBootTest` + `@AutoConfigureMockMvc`，命名规范 `{methodName}_{scenario}_{expectedResult}`

#### 详细业务描述

创建两个测试类：

**① SystemApplicationTest.java**
- 路径：`src/test/java/org/cloudstrolling/cloudoffice/system/SystemApplicationTest.java`
- 注解：`@SpringBootTest(classes = SystemApplication.class, properties = {"spring.cloud.nacos.discovery.enabled=false", "spring.cloud.nacos.config.enabled=false", "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration"})`

**测试用例 1：`contextLoads_shouldLoadSuccessfully_whenApplicationStarts`**
- Given：Spring 测试上下文已加载
- When：执行测试方法
- Then：Spring 上下文加载成功（`assertNotNull(SystemApplication.class)`）
- 验证目标：启动类无编译错误，Spring 容器可正常初始化

**测试用例 2：`enableDiscoveryClient_shouldBePresent_whenAnnotationCheck`**
- Given：SystemApplication 启动类
- When：通过反射获取 `@EnableDiscoveryClient` 注解
- Then：注解存在（`assertNotNull`）
- 验证目标：启动类正确标注了服务发现注解

**② HealthControllerTest.java**
- 路径：`src/test/java/org/cloudstrolling/cloudoffice/system/controller/HealthControllerTest.java`
- 注解：`@DisplayName("System HealthController 测试")`（class 级）
- 测试方式：纯单元测试，直接实例化 HealthController，通过反射注入 Mock Environment
- 不需要 `@SpringBootTest`，独立运行

**测试用例：`health_shouldReturn200AndApiResult_whenCalled`**
- Given：HealthController 实例化，Mock Environment 返回 spring.application.name 为 `"cloudoffice-system-service"`
- When：调用 `healthController.health()`
- Then：
  - `result` 不为空
  - `result.code` 为 200
  - `result.message` 为 `"操作成功"`
  - `data.service` 为 `"cloudoffice-system-service"`
  - `data.status` 为 `"UP"`
  - `data.version` 不为空（`"0.0.1-SNAPSHOT"`）
  - `data.timestamp` 不为空
  - 顶层 `result.timestamp` 存在且为正数

**注意事项：**
- 测试方法命名遵循 `{methodName}_{scenario}_{expectedResult}` 规范
- 测试类使用 class 级别的 `@DisplayName`
- 测试方法使用 `@Test` 和 `@DisplayName`
- 遵循 Given-When-Then 结构化注释模式
- 测试环境必须可以无外部中间件独立运行

#### 测试验收方法
- `mvn test -pl cloudoffice-system-service` 全部通过
- 测试在无 Nacos、无 MariaDB 环境下独立通过
- 启动测试验证上下文加载和注解存在
- 健康检查测试验证 200 状态码和所有响应体字段
