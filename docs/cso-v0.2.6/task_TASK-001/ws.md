# 网络资料查询报告（#TASK-001 引入 spring-cloud-starter-bootstrap 配置引导依赖）

## 1. 查询结论摘要

| 结论 | 说明 |
| --- | --- |
| 引入依赖即可修复 import-check 报错 | Spring Cloud Alibaba 官方源码 `NacosConfigDataMissingEnvironmentPostProcessor`：classpath 存在 `spring-cloud-starter-bootstrap`（bootstrap 启用）时 `shouldProcessEnvironment` 直接返回 false，**import-check 被跳过**，`No spring.config.import property has been defined` 不再抛出 |
| 版本由 BOM 托管，模块引入不写版本号 | `spring-cloud-dependencies:2023.0.1` → import `spring-cloud-commons-dependencies:4.1.2` → 其中 dependencyManagement 明确管理 `spring-cloud-starter-bootstrap`（版本 = `${project.version}` = **4.1.2**），与项目现有 Nacos starter 引入风格一致 |
| 版本链完全兼容 | Spring Cloud Alibaba 2023.0.1.0 ↔ Spring Cloud 2023.0.1 ↔ Spring Boot 3.2.x（官方 2023.x 分支确认），项目 Java 21 满足官方 JDK 17+ 要求 |
| bootstrap 机制官方确认 | Spring Cloud Commons 官方文档：引入 starter-bootstrap 后应用创建 bootstrap 父上下文，加载 `bootstrap.yml`（含 Nacos discovery/config server-addr），`spring.application.name` 应在 bootstrap.yml 中设置 |
| 禁止引入 5.x 新版本 | Maven Central 最新 `spring-cloud-starter-bootstrap` 为 5.0.2（对应 Spring Cloud 2025.x），与项目 2023.0.1 不兼容，必须使用 BOM 托管的 4.1.2 |
| 备选方案（不采用） | 官方推荐新方式是 `spring.config.import=nacos:` + 关闭 import-check（`spring.cloud.nacos.config.import-check.enabled=false`），但会改动 yml 配置，违背 TASK-001 最小改动原则，仅作记录 |

## 2. 三方组件识别

| 组件 | 坐标 | 用途 | 来源 |
| --- | --- | --- | --- |
| spring-cloud-starter-bootstrap | `org.springframework.cloud:spring-cloud-starter-bootstrap` | 恢复 Spring Boot 3.x 下 bootstrap 上下文与 bootstrap.yml 加载，打通 Nacos 配置/注册引导链路 | Spring Cloud Commons 官方项目（spring-cloud-commons 子模块） |
| spring-cloud-starter-alibaba-nacos-config（已有） | `com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-config` | 引入后触发 import-check，是本任务报错来源；配合 bootstrap 依赖后 import-check 自动跳过 | Spring Cloud Alibaba 官方项目 |
| spring-cloud-starter-alibaba-nacos-discovery（已有） | `com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery` | 服务注册与发现，server-addr 从 bootstrap.yml 读取 | Spring Cloud Alibaba 官方项目 |

## 3. 官方文档与使用方法

### 3.1 依赖引入方式（Maven Central / Spring Cloud 官方 BOM）

根 pom 已 import `spring-cloud-dependencies:2023.0.1` BOM（cs.md 确认），该 BOM 通过 `spring-cloud-commons-dependencies:4.1.2` 间接管理 `spring-cloud-starter-bootstrap` 版本（已核对 Maven Central POM 源码：`spring-cloud-commons-dependencies-4.1.2.pom` 的 dependencyManagement 中 `spring-cloud-starter-bootstrap` 版本 = `${project.version}` = 4.1.2）。

**各服务模块实际引入（不写版本号，由父 pom 管理）：**

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bootstrap</artifactId>
</dependency>
```

**关键坑（PRD US-001 边界情况第 1 条，官方 BOM 机制决定）**：仅根 pom dependencyManagement 声明不会传递依赖给子模块，必须在 gateway/auth/biz/system 四个服务模块 `<dependencies>` 中实际引入，否则启动仍报 `No spring.config.import property has been defined`。

### 3.2 Bootstrap 上下文机制（Spring Cloud Commons 4.1.x 官方文档）

- Spring Cloud 应用启动时创建 **bootstrap 上下文**（主应用上下文的父上下文），负责从外部源（Nacos Config）加载配置属性并解密本地外部配置。
- 引导阶段使用独立的 `bootstrap.yml`（或 properties），与主上下文 `application.yml` 分开；`spring.application.name` 需在 bootstrap.yml 中设置才能用作应用 context ID（本项目 bootstrap.yml 已含）。
- 引导属性具有高优先级，bootstrap 进程默认启用，可通过 `spring.cloud.bootstrap.enabled=false` 禁用（本项目不设置，保持默认启用）。

### 3.3 import-check 修复机制（Spring Cloud Alibaba 官方源码）

`spring-cloud-starter-alibaba-nacos-config` 的 `NacosConfigDataMissingEnvironmentPostProcessor.shouldProcessEnvironment` 源码逻辑（官方 2025.1.x 分支，与 2023.0.1.0 逻辑一致）：

```java
protected boolean shouldProcessEnvironment(Environment environment) {
    // don't run if using bootstrap or legacy processing
    if (PropertyUtils.bootstrapEnabled(environment) || PropertyUtils.useLegacyProcessing(environment)) {
        return false;   // ← 引入 spring-cloud-starter-bootstrap 后走这里，import-check 跳过
    }
    String configPrefix = prefix + ".config";
    boolean configEnabled = environment.getProperty(configPrefix + ".enabled", Boolean.class, true);
    boolean importCheckEnabled = environment.getProperty(configPrefix + ".import-check.enabled", Boolean.class, true);
    return configEnabled && importCheckEnabled;  // ← 未引入 bootstrap 且 import-check 默认 true，抛 import-check 异常
}
```

即：**classpath 存在 spring-cloud-starter-bootstrap 时 `PropertyUtils.bootstrapEnabled` 为 true，import-check 直接跳过**，这正是本任务修复 `No spring.config.import property has been defined` 的官方机制依据（与 SAD ADR-014 决策一致）。

### 3.4 与 Nacos discovery/config 的配合

- bootstrap.yml 中 `spring.cloud.nacos.discovery.server-addr` 与 `spring.cloud.nacos.config.server-addr`（默认 `${NACOS_ADDR:127.0.0.1:8848}`）在 bootstrap 阶段被加载，引导 Nacos 注册/配置链路（项目四个 bootstrap.yml 已含，无需改动）。
- Nacos Config 引导属性官方示例（Spring Cloud Alibaba nacos-example bootstrap.properties）：`spring.cloud.nacos.config.server-addr`、`shared-configs[].data-id`、`extension-configs[].data-id`、`refresh-enabled=true` 等；本项目仅需 server-addr，配置已满足。
- 服务注册：Nacos Discovery 监听 `WebServerInitializedEvent`，Web 容器初始化后自动注册到 Nacos，无需额外代码。

### 3.5 备选方案（记录但不采用）

官方新式推荐为 `spring.config.import`（在 application.yml 中 `spring.config.import: nacos:{dataId}?refreshEnabled=true&group=DEFAULT_GROUP`），或显式关闭 import-check（`spring.cloud.nacos.config.import-check.enabled=false`）。两条路线均需改动配置文件，且 `spring.config.import` 方式下 Nacos 地址放 application.yml、bootstrap.yml 失效，与 ADR-014"最小改动、保持 bootstrap.yml"决策冲突，本任务不采用。

## 4. 版本兼容性核对

| 组件 | 项目使用版本 | 查询到的官方版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Spring Boot | 3.2.5 | 3.2.x（Spring Cloud Alibaba 2023.x 适配） | ✅ 兼容（2023.x 分支适配 Spring Boot 3.2.x） |
| Spring Cloud | 2023.0.1 | 2023.0.1（BOM 含 bootstrap 4.1.2） | ✅ 兼容 |
| spring-cloud-starter-bootstrap | 由 BOM 解析为 **4.1.2** | 4.1.2（spring-cloud-commons-dependencies 4.1.2 托管）；最新 5.0.2 属 Spring Cloud 2025.x | ✅ 兼容（BOM 托管 4.1.2）；⚠️ 禁止手工指定 5.x |
| Spring Cloud Alibaba | 2023.0.1.0 | 2023.0.1.0（官方命名：前三位对应 Spring Cloud 版本） | ✅ 兼容（官方 2023.x 分支：Spring Cloud 2023 & Spring Boot 3.2.x，JDK 17+） |
| JDK | 21 | 官方要求 JDK 17+ | ✅ 兼容 |
| Nacos Server | 2.3 | 官方示例推荐 2.4.2（新增鉴权）；2.3 无鉴权要求 | ✅ 兼容（本项目 Nacos 2.3 无需 username/password） |

> ⚠️ 版本差异提示：Maven Central 当前最新 `spring-cloud-starter-bootstrap:5.0.2` 对应 Spring Cloud 2025.x / Spring Boot 4.x 系列，**严禁**在项目根 pom 或模块 pom 中显式声明 5.x 版本，必须依赖 BOM 解析为 4.1.2。

## 5. 相关任务资料（排错经验与注意事项）

1. **报错本质**：`No spring.config.import property has been defined` 由 nacos-config starter 的 import-check 机制在 Spring Boot 3.x 下抛出（Spring Boot 3 起 bootstrap 默认禁用、Nacos 未通过 `spring.config.import` 引入），修复三选一：① 引入 starter-bootstrap（本项目）；② 配置 `spring.config.import=optional:nacos:`；③ 设置 `spring.cloud.nacos.config.import-check.enabled=false`。
2. **仅声明不引入无效果**：Maven 的 dependencyManagement 只管理版本、不传递依赖，四个服务模块必须各自在 `<dependencies>` 实际引入 bootstrap starter（回归报告根因 1 与 cs.md 均已证实）。
3. **引入后启动顺序**：bootstrap.yml 先于 application.yml 加载（bootstrap 为父上下文），Nacos discovery/config server-addr 在应用上下文创建前就绪；gateway 虽未引入 nacos-config，但按 SAD ADR-014 四个服务统一引入，避免 bootstrap.yml 不加载导致 discovery 引导断裂。
4. **Nacos 不可达时的表现**：引入依赖后若 Nacos 未启动，服务会报连接 Nacos 异常而启动失败（PRD 边界情况第 3 条），属于环境问题而非依赖问题；验证前需确保 Nacos 8848 可达。
5. **构建验证**：`mvn package` 应无依赖冲突（4.1.2 由 BOM 统一管理，不与其他 Spring Cloud 组件冲突）；各模块 `maven-antrun-plugin` 会在 package 阶段复制 jar 到 deploy 目录，可用作构建成功的旁证。
6. **禁止事项**：本任务仅允许 pom 依赖变更，不得改动 bootstrap.yml/application.yml（现有配置已含 nacos server-addr）、不得改动任何 Java 代码。

## 6. 参考来源（官方为主）

| 来源 | 说明 |
| --- | --- |
| https://central.sonatype.com/artifact/org.springframework.cloud/spring-cloud-starter-bootstrap | Maven Central：坐标、最新版本 5.0.2、许可 |
| https://repo1.maven.org/maven2/org/springframework/cloud/spring-cloud-dependencies/2023.0.1/spring-cloud-dependencies-2023.0.1.pom | 官方 BOM：`spring-cloud-commons.version=4.1.2` |
| https://repo1.maven.org/maven2/org/springframework/cloud/spring-cloud-commons-dependencies/4.1.2/spring-cloud-commons-dependencies-4.1.2.pom | 官方 BOM：确认 `spring-cloud-starter-bootstrap` 版本 = 4.1.2 |
| https://docs.spring.io/spring-cloud-commons/reference/4.1/spring-cloud-commons/application-context-services.html | Spring Cloud Commons 4.1.x 官方文档：Bootstrap Application Context 机制 |
| https://github.com/alibaba/spring-cloud-alibaba/blob/2023.x/README.md | Spring Cloud Alibaba 官方：2023.x 分支 = Spring Cloud 2023 + Spring Boot 3.2.x，JDK 17+ |
| https://github.com/alibaba/spring-cloud-alibaba/blob/2025.1.x/spring-cloud-alibaba-starters/spring-cloud-starter-alibaba-nacos-config/src/main/java/com/alibaba/cloud/nacos/configdata/NacosConfigDataMissingEnvironmentPostProcessor.java | 官方源码：import-check 跳过逻辑（bootstrap 启用时返回 false） |
| https://github.com/alibaba/spring-cloud-alibaba/blob/2023.x/spring-cloud-alibaba-examples/nacos-example/readme-zh.md | 官方示例：Nacos Config/Discovery 接入与 bootstrap.properties 配置 |
| https://github.com/alibaba/spring-cloud-alibaba/wiki/版本说明 | 官方 Wiki：SCA 版本命名规则（前三位对应 Spring Cloud 版本） |

## 7. 对编码阶段的直接建议

1. **改动范围（5 个 pom.xml，与 cs.md 目标一致）**：根 pom `<dependencyManagement>` 声明 `spring-cloud-starter-bootstrap`（版本随 BOM 管理，可不写或复用 `spring-cloud.version` 属性）+ gateway/auth/biz/system 四个模块 `<dependencies>` 实际引入（不写版本号）。
2. **依赖块写法**（仿照现有 Nacos starter 风格，含中文注释）：
   ```xml
   <!-- Spring Cloud Bootstrap 配置引导（恢复 bootstrap.yml 加载，修复 No spring.config.import property has been defined） -->
   <dependency>
       <groupId>org.springframework.cloud</groupId>
       <artifactId>spring-cloud-starter-bootstrap</artifactId>
   </dependency>
   ```
3. **验证命令**：`mvn package`（确认依赖解析无冲突、deploy 目录产出 4 个 jar）；启动服务后检查日志不再出现 `No spring.config.import property has been defined`，且 bootstrap.yml 中 Nacos discovery/config server-addr 被加载、服务注册到 Nacos。
4. **绝对禁止**：声明 5.x 显式版本；修改 yml / Java 代码 / 数据库结构。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
