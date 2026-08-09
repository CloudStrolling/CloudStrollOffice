# 网络资料查询报告（ws.md）— TASK-003 重新构建 4 个服务 jar 并完成启动验证与健康检查

**项目**：云漫智企（CloudStrollOffice，cso）｜**版本**：v0.2.6｜**任务编号**：TASK-003
**查询角色**：WS（网络查询）｜**查询日期**：2026-08-09
**查询范围**：Spring Boot 3.2.x 服务 jar 构建与启动参数、Nacos 2.3 服务注册健康检查机制、Spring Cloud Gateway 路由与健康检查接口可达性、spring-cloud-starter-bootstrap 配置引导机制

---

## 1. 三方组件清单与版本兼容性结论

| 组件 | 项目使用版本 | 查询资料版本 | 兼容性结论 | 说明 |
| --- | --- | --- | --- | --- |
| Spring Boot | 3.2.5 | 官方文档 3.2.x 系列（context7：spring-projects/spring-boot） | ✅ 兼容 | 可执行 jar 由 `mvn package` + spring-boot-maven-plugin repackage 生成，`java -jar` 启动；3.2.5 为 3.2 线维护版本，官方文档机制一致 |
| Spring Cloud | 2023.0.1 | 官方发布列车（2023.0.x ↔ Spring Boot 3.2.x） | ✅ 兼容 | 2023.0.1 对应 Spring Boot 3.2.x 线（cs.md 已确认项目 BOM） |
| spring-cloud-starter-bootstrap | 4.1.2（TASK-001 引入） | Spring Cloud 2023.0.x BOM 托管值 4.1.2 | ✅ 兼容 | 与 Spring Cloud 2023.0.1 同代；该依赖是 Spring Boot 3.x 下恢复 bootstrap.yml 加载的官方机制 |
| Spring Cloud Alibaba | 2023.0.1.0 | 官方 Wiki 版本说明（2023.x 分支） | ✅ 兼容 | SCA 2023.x 分支适配 Spring Boot 3.2.x / Spring Cloud 2023.x；`spring-cloud-alibaba-dependencies` 以 BOM import 方式引入（GitHub 真实项目样例证实） |
| Nacos Server | 2.3 | nacos.io v2.3 官方文档 + 源码（alibaba/nacos develop 分支） | ✅ 兼容 | SCA 2023.0.1.0 内嵌 nacos-client 2.3.x，与服务端 2.3 对应；2.x 起注册采用 gRPC 长连接机制 |
| Spring Cloud Gateway | 2023.0.1 | docs.spring.io Spring Cloud Gateway Reference | ✅ 兼容 | `lb://` 负载均衡路由 + discovery locator 机制与项目路由配置一致 |
| Maven maven-antrun-plugin | 3.2.0 | Maven antrun 插件通用用法 | ✅ 兼容 | package 阶段 copy 任务复制最终 jar 至 deploy 目录，属标准插件用法 |

> 版本兼容性总体结论：项目技术栈（Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + SCA 2023.0.1.0 + Nacos 2.3）为 Spring Cloud 2023.x 官方标准组合，**版本间无冲突**；本次查询的所有官方文档机制均适用于当前版本。

---

## 2. Spring Boot 3.2.x：服务 jar 构建与启动参数（官方文档）

### 2.1 可执行 jar 构建（spring-projects/spring-boot 官方文档）

```shell
$ mvn package
```
- 官方构建流程输出：`maven-jar-plugin` 生成普通 jar → **`spring-boot-maven-plugin:repackage` 打成可执行（fat）jar**，落位于 `target/`。
- 本项目由 maven-antrun-plugin 将 `target/${finalName}.jar` 复制到 `deploy/`（cs.md §3.3 已确认）。
- **要点**：若 `mvn package` 构建成功但 target 下无可执行 jar，说明 spring-boot-maven-plugin 的 repackage 执行段缺失或模块未继承根 pom 插件管理。

### 2.2 java -jar 启动与参数

```shell
# 基础启动（官方推荐）
$ java -jar target/myapplication-0.0.1-SNAPSHOT.jar

# 远程调试（官方样例，排查启动问题可用）
$ java -agentlib:jdwp=server=y,transport=dt_socket,address=8000,suspend=n -jar target/myapplication-0.0.1-SNAPSHOT.jar

# 本项目标准启动（deploy/deploy.md）
$ java -Xms256m -Xmx512m -jar deploy\cloudoffice-gateway.jar
```
- **JVM 堆参数**：`-Xms256m -Xmx512m` 为 JVM 启动参数，置于 `-jar` 之前，官方支持任意 JVM 参数（`-X`、`-D`、`-agentlib` 等）。
- **启动成功标志**：日志出现 `Started XxxApplication in x.xxx seconds`（官方输出样例）。
- **`-D` 系统属性优先级**：命令行 `-D` 属性在 Spring Boot 外部化配置优先级中高于 application.yml/环境变量，可用于临时覆盖配置；但本项目采用 env.json 环境变量注入（load-env.ps1 → `Set-Item env:`），二者同为官方支持的外部化配置方式。

### 2.3 Maven 启动调试（备用）

```shell
$ mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dproperty1=overridden"
```
- 可在不打包时直接运行模块并传递 JVM 参数，适合快速复现启动问题。

---

## 3. spring-cloud-starter-bootstrap：bootstrap.yml 加载机制（TASK-001 修复依据，TASK-003 复核点）

### 3.1 官方机制（Spring Cloud Config / Spring Cloud 官方文档）
- **Spring Boot 2.4+ 起**，默认不再加载 `bootstrap.yml`/`bootstrap.properties`，改为 `spring.config.import` 机制（Config Data API）。
- **恢复 bootstrap 上下文的官方唯一途径**：在 classpath 引入 `org.springframework.cloud:spring-cloud-starter-bootstrap`（版本由 Spring Cloud BOM 管理，2023.0.x 对应 4.1.2）。
- 未引入该依赖且使用 Nacos Config 时，启动报错：
  `No spring.config.import property has been defined`（import-check 失败）—— 即 v0.2.5 回归根因 1 的官方错误来源。
- **本项目复核点**：4 个模块（gateway/auth/biz/system）pom 均已引入 bootstrap 依赖（TASK-001），TASK-003 启动日志**不应再出现**该报错。

### 3.2 官方 bootstrap 配置样例（spring-cloud-alibaba 官方示例 integrated-account）

```yaml
spring:
  application:
    name: integrated-account
  cloud:
    nacos:
      discovery:
        server-addr: nacos-server:8848
        group: integrated-example
      config:
        server-addr: nacos-server:8848
        file-extension: yaml
```
- 与本项目 4 个模块 bootstrap.yml 结构一致（discovery/config server-addr 均配置）。
- `spring.application.name` 是 Nacos 服务注册名与配置 dataId 的核心构成（官方文档明确）。

---

## 4. Nacos 2.3：服务注册与健康检查机制（TASK-003 验证依据）

### 4.1 注册配置（nacos.io v2.3 官方「Nacos 融合 Spring Cloud」+ spring-cloud-alibaba 官方）

```properties
# 官方 bootstrap.properties 样例（v2.3 文档）
spring.cloud.nacos.config.server-addr=127.0.0.1:8848
spring.application.name=example
```
```yaml
# discovery 注册配置（spring-cloud-alibaba 官方示例）
spring:
  cloud:
    nacos:
      discovery:
        server-addr: 127.0.0.1:8848
        # registerEnabled 默认 true：仅订阅不注册时置 false（官方 NacosDiscoveryProperties 源码）
        # service 默认取 spring.application.name；weight 1~100；namespace 环境隔离
```
- **关键配置项**（官方 NacosDiscoveryProperties 源码 + readme）：
  | 配置项 | 默认值 | 说明 |
  | --- | --- | --- |
  | `spring.cloud.nacos.discovery.server-addr` | 无 | Nacos 服务端地址（本项目 ${NACOS_ADDR:127.0.0.1:8848}） |
  | `spring.cloud.nacos.discovery.register-enabled` | true | 是否注册实例（本项目保持默认） |
  | `spring.cloud.nacos.discovery.service` | spring.application.name | 注册服务名（本项目 = cloudoffice-*） |
  | `spring.cloud.nacos.discovery.weight` | 1 | 权重 1~100 |
  | `spring.cloud.nacos.discovery.namespace` | public | 环境隔离 |

### 4.2 2.x 健康检查机制（nacos.io 官方「实例生命周期」「健康、权重与元数据」）

- **临时实例（ephemeral=true，应用默认）**：
  - gRPC SDK 客户端：**实例挂靠在客户端长连接上，连接断开即被服务端清理**，无需业务实现心跳 —— Spring Cloud Alibaba 场景由 SDK 自动维持。
  - HTTP 客户端：通过心跳续约维持（`preserved.heart.beat.interval`/`timeout` 可调）。
- **清理行为**（官方列举）：gRPC 连接断开、HTTP 心跳超时、临时 client 过期等 → 排查「实例突然消失」需同时看客户端连接、心跳日志、服务端清理日志。
- **healthy 与 enabled**：
  - `healthy`：实例是否被 Nacos 健康逻辑认为可用（心跳/健康检查器驱动）。
  - `enabled`：是否允许接收发现流量（运维侧控制）。
  - **实例存在但消费者查不到时，优先检查 enabled、healthy、cluster 过滤和保护阈值**（本项目网关 lb:// 路由依赖 Nacos 服务发现，此点即「服务已启动但网关路由 502/503」的排查方向）。
- **持久实例**：由服务端主动健康检查（TCP/HTTP/MySQL/NONE）维护，本任务不涉及。
- **注册成功日志标志**（cs.md §10）：`nacos registry, xxx ... register` / `Nacos registry ... register finished`，TASK-003 4 个服务均应出现。

### 4.3 Nacos 控制台核对（本项目验证步骤）
- 服务列表：`http://<主机>:8848/nacos/` → 应见 cloudoffice-gateway / cloudoffice-auth-service / cloudoffice-biz-service / cloudoffice-system-service 4 个服务各 1 个健康实例（cloudoffice-* 命名）。

---

## 5. Spring Cloud Gateway：路由与健康检查接口可达性（官方文档）

### 5.1 负载均衡路由（docs.spring.io Spring Cloud Gateway Reference）

```yaml
spring:
  cloud:
    gateway:
      server:
        webflux:
          routes:
          - id: myRoute
            uri: lb://service        # lb:// 协议经 LoadBalancerClient 解析为真实实例
            predicates:
            - Path=/service/**
```
- **lb:// 机制**：`lb://{service-id}` 依赖 Spring Cloud LoadBalancer 从注册中心（Nacos）发现实例；`lb://` 路由到不可见实例时表现为网关 502/503 —— **先查 Nacos 服务列表实例是否健康**。
- **本项目路由**（cs.md §7.2）：`/api/v1/auth/** → lb://cloudoffice-auth-service` 等 3 条 + `spring.cloud.gateway.discovery.locator.enabled: true`（官方推荐动态路由开关，服务注册后自动生成路由）。

### 5.2 网关 Actuator 路由端点（官方，可选用于验证路由）

```properties
management.endpoint.gateway.access=read-only
management.endpoints.web.exposure.include=gateway
```
```http
GET /actuator/gateway/routes   # 返回全部路由定义（id/predicates/filters/uri/order）
```
- 可用于 TASK-003 启动后核对 3 条 lb:// 路由是否生效（需网关暴露 actuator，本项目未强制要求）。

### 5.3 网关健康检查接口可达性结论（本项目契约）
- 网关（Reactive）无独立 HealthController，存活验证为访问 `http://<主机>:9000/`（404/401 均说明服务在运行）——与 deploy/deploy.md 一致，符合官方「网关本身无业务健康端点」惯例。
- `/api/v1/auth/health`（API-012，白名单免认证）经网关 9000 可达；`/api/v1/biz/health`（API-032）、`/api/v1/system/health`（API-033）不在网关白名单，**直连服务端口（9200/9400）免认证可达，经网关需 Token**（context.md §4 契约，本版本维持现状）。

---

## 6. Spring Boot 外部化配置优先级（env.json 环境变量注入可靠性）

Spring Boot 官方外部化配置优先级（高 → 低，与本任务相关部分）：
1. **命令行参数**（`--key=value`）
2. **JVM 系统属性**（`-Dkey=value`）
3. **操作系统环境变量**（本项目 env.json → load-env.ps1 `Set-Item env:` 注入）
4. application.yml / application-{profile}.yml（配置文件内）
5. bootstrap.yml（bootstrap 上下文，优先级低于 application）

**结论**：
- env.json 环境变量注入的 `NACOS_ADDR`/`DB_HOST`/`RSA_PUBLIC_KEY` 等可**覆盖** application.yml/bootstrap.yml 中带默认值的占位符（`${NACOS_ADDR:127.0.0.1:8848}` 语法 = 有默认值的环境变量引用，官方标准占位符语法）。
- 修改 env.json 后必须重启对应服务才生效（deploy/deploy.md 已注明）。
- 启动脚本校验（deploy-start-*.ps1 校验 9 个必需变量）与官方「环境变量注入」机制一致。

---

## 7. 健康检查接口实现样例（GitHub 真实项目）

- **官方/社区标准模式**：`@RestController` + `@GetMapping("/health")` 返回 UP 状态（eugenp/tutorials HealthCheckController、apache/incubator-seata HealthController 等真实仓库样例，与本项目 3 个 HealthController 结构一致）。
- 本项目已实现（cs.md §6）：auth/biz/system 三个 HealthController 返回 `ApiResult<Map>`（service/status/version/timestamp），符合 context.md §4 契约（服务名/状态/版本/时间戳）。
- **注意**：system-service 的 timestamp 为 `System.currentTimeMillis()`（毫秒长整型），auth/biz 为 ISO 字符串 —— 跨服务字段类型不一致属既有实现，API 测试脚本断言时需兼容（若断言统一格式可能失败，TASK-004/005 回归时留意）。

---

## 8. 任务相关排错经验（启动验证关注点）

| 现象 | 官方/社区定位方向 | 本项目处理 |
| --- | --- | --- |
| `No spring.config.import property has been defined` | 缺 spring-cloud-starter-bootstrap（Boot 3.x 默认不加载 bootstrap.yml） | TASK-001 已修复，TASK-003 启动日志**不应再出现** |
| `RSA 公钥解析失败` / `Unable to decode key` / `extra data at the end` | Base64 解码器严格模式 + KeySpec（X509/PKCS8）要求 DER 编码 | TASK-002 已修复（DER 单行 Base64 契约），TASK-003 复核 env.json 注入值为 `*_base64.txt` 内容 |
| 服务启动报 Nacos 连接失败 | Nacos 未启动或 NACOS_ADDR 错误 | 先执行 deploy-start-services.ps1（三重检测） |
| 服务启动报数据库连接失败 | DB_HOST/PORT/PASSWORD 错误 | 检查 env.json，执行 deploy-db-init.ps1 |
| 网关路由 502/503 | lb:// 服务未注册或实例不健康（enabled/healthy/protectThreshold） | 查 Nacos 控制台 cloudoffice-* 实例状态 |
| 登录报令牌校验失败 | RSA 密钥与 Nacos 配置不一致 | 重新生成密钥并同步 Nacos 配置，重启服务 |

---

## 9. 关键命令速查（TASK-003 可直接复用）

| 用途 | 命令 | 来源 |
| --- | --- | --- |
| 构建全部模块 | `mvn clean package -DskipTests`（项目根目录） | Spring Boot 官方 + build.md |
| 直接启动服务 | `java -Xms256m -Xmx512m -jar deploy\cloudoffice-{gateway\|auth-service\|biz-service\|system-service}.jar` | deploy.md + 官方 java -jar |
| 加载环境变量 | `. .\deploy\scripts\load-env.ps1` | cs.md §5.1 |
| 启动基础设施 | `. \deploy\scripts\deploy-start-services.ps1` | deploy.md |
| 健康检查 | `GET http://<主机>:{9100\|9200\|9400}/api/v1/{auth\|biz\|system}/health` | context.md §4 |
| 网关存活 | 访问 `http://<主机>:9000/`（404/401 均存活） | deploy.md |
| Nacos 注册核对 | `http://<主机>:8848/nacos/` 服务列表（cloudoffice-*） | deploy.md |

---

## 10. 参考资料清单（均为官方/权威来源）

1. Spring Boot 官方文档（context7：spring-projects/spring-boot）— 构建与运行可执行 jar、spring-boot:run JVM 参数：https://docs.spring.io/spring-boot/reference/packaging.html
2. Spring Cloud Alibaba 官方示例（context7：alibaba/spring-cloud-alibaba）— bootstrap.yaml、NacosDiscoveryProperties 配置项：https://github.com/alibaba/spring-cloud-alibaba
3. Spring Cloud Alibaba 版本说明 Wiki — 版本兼容矩阵：https://github.com/alibaba/spring-cloud-alibaba/wiki/版本说明
4. Spring Cloud Gateway Reference（docs.spring.io）— lb:// 路由、DiscoveryClient Route Definition Locator、Actuator 端点：https://docs.spring.io/spring-cloud-gateway/reference/
5. Nacos v2.3 官方文档 — Nacos 融合 Spring Cloud、实例生命周期、健康/权重/元数据、架构：https://nacos.io/docs/v2.3/what-is-nacos/
6. Spring Cloud Config Reference — spring.config.import 与 bootstrap 上下文说明：https://docs.spring.io/spring-cloud-config/docs/current/reference/html/
7. GitHub 真实项目样例 — @GetMapping("/health") 健康检查模式（eugenp/tutorials、apache/incubator-seata）；spring-cloud-alibaba-dependencies BOM import 用法（FantZero/CA）
8. Nacos 客户端源码（alibaba/nacos develop 分支）— gRPC NamingClientProxy/RedoService 长连接注册机制

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
