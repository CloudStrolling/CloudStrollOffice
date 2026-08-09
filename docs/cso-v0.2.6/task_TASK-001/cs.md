# 代码查询报告（#TASK-001 引入 spring-cloud-starter-bootstrap 配置引导依赖）

## 1. 查询结论摘要

| 结论 | 说明 |
| --- | --- |
| 全项目 6 个 pom.xml **均未声明/引入** `spring-cloud-starter-bootstrap` | grep `bootstrap`/`spring.config.import` 于所有 pom.xml 无任何匹配，与回归报告根因 1 一致 |
| 根 pom 已导入 `spring-cloud-dependencies` BOM（2023.0.1） | 该 BOM 已托管 `spring-cloud-starter-bootstrap`（4.1.x）版本，模块 pom 引入时**可不写版本号**，与现有 Nacos starter 引入方式一致 |
| 四个服务模块均有 `bootstrap.yml` 但当前不会加载 | Spring Boot 3.x 默认不加载 bootstrap.yml，需引入依赖后恢复引导 |
| auth/biz/system 三个模块引入了 `spring-cloud-starter-alibaba-nacos-config` | 触发 import-check，启动报 `No spring.config.import property has been defined`（与回归报告一致）；gateway 未引入 nacos-config 但也含 bootstrap.yml，按 SAD ADR-014 四个服务模块统一引入 |
| `cloudoffice-common` 无需引入 | 公共 JAR 无启动类、无 Nacos 引导需求，不在修改范围 |
| 配置文件本身无需改动 | 四个 bootstrap.yml 已含 nacos discovery/config server-addr，格式统一（10 行），与 ADR-014 部署说明一致 |

## 2. 修改目标文件清单（5 个 pom.xml，仅依赖声明）

| 文件（绝对路径） | 现状 | 所需改动 |
| --- | --- | --- |
| `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\pom.xml` | `<dependencyManagement>` 已 import spring-cloud-dependencies BOM（L66-72）与 spring-cloud-alibaba BOM（L75-81）；无 bootstrap 声明 | 在 dependencyManagement 中声明 `spring-cloud-starter-bootstrap`（放在 Spring Cloud BOM import 之后，仿照其他依赖块；版本随 BOM 管理可不写或显式声明） |
| `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\cloudoffice-gateway\pom.xml` | `<dependencies>` 含 gateway/nacos-discovery/loadbalancer/redis/commons-pool2/lombok/jjwt/common/test（L20-86） | `<dependencies>` 中实际引入 `spring-cloud-starter-bootstrap`（不写版本号，由父 pom dependencyManagement 管理） |
| `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\cloudoffice-auth-service\pom.xml` | `<dependencies>` 含 web/security/oauth2-auth-server/jjwt/nacos-discovery/**nacos-config**/common/mybatis-plus/mariadb/redis/commons-pool2/validation/lombok/test（L20-121） | 同上，实际引入 `spring-cloud-starter-bootstrap` |
| `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\cloudoffice-biz-service\pom.xml` | `<dependencies>` 含 web/mybatis-plus/mariadb/nacos-discovery/**nacos-config**/common/lombok/test（L20-70） | 同上，实际引入 `spring-cloud-starter-bootstrap` |
| `D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\cloudoffice-system-service\pom.xml` | `<dependencies>` 含 web/mybatis-plus/mariadb/nacos-discovery/**nacos-config**/common/lombok/test（L20-70） | 同上，实际引入 `spring-cloud-starter-bootstrap` |

> 关键坑（PRD US-001 边界情况）：仅根 pom dependencyManagement 声明而不在模块 pom 实际引入，模块仍不会获得该依赖，启动仍报 import-check 错误，必须四个服务模块各自引入。

## 3. 根 pom.xml 现状（dependencyManagement 复用点）

- **版本属性**（`<properties>`，L34-60）：`spring-cloud.version=2023.0.1`、`spring-cloud-alibaba.version=2023.0.1.0`，BOM import 均引用 `${...}` 属性，本任务可复用 `spring-cloud.version`（即 2023.0.1 BOM 管理 bootstrap 版本）。
- **dependencyManagement 现有声明**（L63-145）：Spring Cloud BOM、Spring Cloud Alibaba BOM、MyBatis-Plus、Hutool、SpringDoc、Lombok、JJWT×3、MariaDB 驱动、cloudoffice-common。新声明建议插入在 Spring Cloud Alibaba BOM（L81）之后、MyBatis-Plus（L83）之前，与 Spring Cloud 系列依赖归组。
- **父 POM**：`spring-boot-starter-parent 3.2.5`（Spring Boot 3.x 默认禁用 bootstrap 加载机制，故必须引入 starter-bootstrap 恢复）。

## 4. 四个服务模块 pom.xml 现状（可仿照的依赖块写法）

各模块均以 `<parent>` 指向根 pom（`relativePath=../pom.xml`），依赖声明统一不写版本号、由父 pom 管理。可仿照现有 Nacos starter 依赖块：

```xml
<!-- Nacos 服务发现（现有写法示例，cloudoffice-auth-service L60-63） -->
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
</dependency>
```

新增 bootstrap 依赖块建议（不写版本号）：

```xml
<!-- Spring Cloud Bootstrap 配置引导（恢复 bootstrap.yml 加载，修复 No spring.config.import property has been defined） -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bootstrap</artifactId>
</dependency>
```

- 各模块均有 `maven-antrun-plugin` 的 `copy-final-jar-to-deploy` 执行块（package 阶段复制 jar 到 `${deployDir}`），构建验证可复用：`mvn package` 后检查 `deploy/cloudoffice-{gateway|auth-service|biz-service|system-service}.jar` 生成。

## 5. 配置文件现状（bootstrap.yml / application.yml，**本任务不改动**）

### bootstrap.yml（四个模块完全同构，各 10 行）
| 模块 | 文件路径 | 关键内容 |
| --- | --- | --- |
| gateway | `cloudoffice-gateway/src/main/resources/bootstrap.yml` | `spring.application.name: cloudoffice-gateway`；nacos discovery/config `server-addr: ${NACOS_ADDR:127.0.0.1:8848}`、`file-extension: yaml` |
| auth-service | `cloudoffice-auth-service/src/main/resources/bootstrap.yml` | `spring.application.name: cloudoffice-auth-service`；同上 |
| biz-service | `cloudoffice-biz-service/src/main/resources/bootstrap.yml` | `spring.application.name: cloudoffice-biz-service`；同上 |
| system-service | `cloudoffice-system-service/src/main/resources/bootstrap.yml` | `spring.application.name: cloudoffice-system-service`；同上 |

### application.yml（端口与数据源，与启动验证相关）
| 模块 | 文件路径 | 端口 | 其他要点 |
| --- | --- | --- | --- |
| gateway | `cloudoffice-gateway/src/main/resources/application.yml` | 9000 | Redis 配置；gateway routes（auth/biz/system lb 路由）；RSA 公钥；白名单 |
| auth-service | `cloudoffice-auth-service/src/main/resources/application.yml` | 9100 | MariaDB（cloudstroll_office_auth）+ Redis；springdoc；mybatis-plus；jwt；验证码 mock |
| biz-service | `cloudoffice-biz-service/src/main/resources/application.yml` | 9200 | 数据源（cloudstroll_office_biz，`autoconfigure.exclude` DataSourceAutoConfiguration）；springdoc |
| system-service | `cloudoffice-system-service/src/main/resources/application.yml` | 9400 | 数据源（cloudstroll_office_system，`autoconfigure.exclude` DataSourceAutoConfiguration）；springdoc |

## 6. 回归报告依据（docs/cso-v0.2.5/regression-api-test.md，用户输入指定文档）

- §3.2 根因 1（L39-41）：所有服务模块缺少 `spring-cloud-starter-bootstrap` 依赖（全项目 pom 均未引入）；auth/biz/system 启动报 `No spring.config.import property has been defined`（nacos-config 的 import-check 失败）；bootstrap.yml 在 Spring Boot 3.x 下默认不加载，Nacos 配置引导链路断裂。
- §3.3 建议（L50）：在根 pom 或各模块引入 `spring-cloud-starter-bootstrap`（或按需启用 `spring.config.import=optional:nacos:` 与关闭 import-check），保证 bootstrap.yml 生效。
- L57/L63：TC-001~045 基线接口回归为**环境阻塞**（服务无法启动），审核项 **T-02**（v0.0.1 基线遗留，本版本 v0.2.6 修复）。
- 注意：T-02 还包含"RSA 密钥格式契约不匹配"另一子项，不在 TASK-001 范围内（TASK-001 仅处理 bootstrap 依赖），如需一并修复属后续任务。

## 7. 可复用依赖管理结论（供编码阶段直接使用）

1. **版本管理**：`spring-cloud-dependencies` BOM（2023.0.1）已通过根 pom dependencyManagement import，`spring-cloud-starter-bootstrap` 版本由该 BOM 托管（对应 Spring Cloud 2023.0.x 下的 4.1.x），各模块引入时**不写版本号**即可，与全项目依赖声明风格一致。
2. **仅需 5 处改动**：根 pom dependencyManagement 声明 1 处 + 四个服务模块 dependencies 各 1 处；不涉及 common 模块、不涉及任何 yml 与 Java 代码。
3. **验证命令**：`mvn package`（依赖解析无冲突、deploy 目录产出 4 个可执行 jar）；启动后日志无 `No spring.config.import property has been defined`、bootstrap.yml 中 NACOS_ADDR 被加载。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
