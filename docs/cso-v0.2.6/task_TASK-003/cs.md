# 代码查询报告（cs.md）— TASK-003 重新构建 4 个服务 jar 并完成启动验证与健康检查

**项目**：云漫智企（CloudStrollOffice，cso）｜**版本**：v0.2.6｜**任务编号**：TASK-003
**查询角色**：CS（本地代码查询）｜**查询日期**：2026-08-09
**查询范围**：deploy/build.md、deploy/deploy.md、deploy/env 注入与启动脚本、健康检查 Controller、Nacos 注册配置（bootstrap.yml/application.yml）、pom 构建配置、RSA 密钥契约

---

## 1. 任务相关结论速览

| 事项 | 结论 | 证据位置 |
| --- | --- | --- |
| bootstrap 依赖（TASK-001） | 已修复：根 pom dependencyManagement 显式声明 `spring-cloud-starter-bootstrap` 4.1.2，4 个模块 pom 均已引入 | pom.xml:87-91；gateway pom:36、auth pom:74、biz pom:54、system pom:54 |
| RSA 密钥契约（TASK-002） | 已修复：deploy-rsa-keygen.ps1 输出 DER 单行 Base64 并契约自校验；Java 端严格 Base64 + X509/PKCS8EncodedKeySpec | deploy/scripts/deploy-rsa-keygen.ps1:70-101；gateway RsaKeyConfig.java:113-116、auth RsaKeyConfig.java:76-89 |
| 构建命令 | `mvn clean package -DskipTests`（项目根目录），antrun 自动复制 jar 至 deploy/ | deploy/build.md:51-61；pom.xml:56 |
| 部署启动流程 | 准备资产 → env.json → RSA 密钥 → DB 初始化 → 启动基础设施 → 启动 4 服务 | deploy/deploy.md:71-134 |
| 健康检查接口 | auth/biz/system 三个 HealthController 均已实现 `/api/v1/{module}/health`，返回 service/status/version/timestamp | 3 个 HealthController.java |
| Nacos 注册 | 4 个模块 bootstrap.yml 均已配置 nacos discovery/config server-addr | 4 个 bootstrap.yml |

---

## 2. v0.2.5 回归问题记录（docs/cso-v0.2.5/regression-api-test.md）

**本任务直接依据**：v0.2.5 接口回归发现 4 个业务服务均无法启动（TC-001~045 环境阻塞，cso-api-test-v0.0.1.py admin 登录连接拒绝崩溃退出码 1）。

### 2.1 根因 1：bootstrap 依赖缺失（已由 TASK-001 修复）
- 现象：auth/biz/system 启动报 `No spring.config.import property has been defined`（nacos-config import-check 失败）；Spring Boot 3.x 下 bootstrap.yml 默认不加载，Nacos 配置引导链路断裂。
- 修复验证（TASK-003 需复核）：根 pom `dependencyManagement` 已显式声明 `org.springframework.cloud:spring-cloud-starter-bootstrap:4.1.2`（版本与 Spring Cloud 2023.0.1 BOM 托管值一致；因 dependencyManagement 显式声明会遮蔽 import BOM 同坐标条目，故必须写版本），4 个模块均已引入该依赖。

### 2.2 根因 2：RSA 密钥格式契约不匹配（已由 TASK-002 修复）
- 现象：deploy/env.json 的 RSA 密钥为 PEM 文件整体 Base64（多行、含 BEGIN/END 标记与 \r\n），网关启动报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。
- 修复验证（TASK-003 需复核）：deploy-rsa-keygen.ps1 已改为输出 **DER 编码单行 Base64**（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo），无 PEM 头尾、无换行，并内置契约自校验（无 BEGIN/END 标记、无 \r\n、严格 Base64 可解码）。

### 2.3 修复建议（regression-api-test.md 第 3.3 节，v0.2.6 对应任务）
1. 引入 bootstrap 依赖（TASK-001 已完成）；
2. 修正 RSA 密钥生成/注入格式（TASK-002 已完成）；
3. **修复后重新构建 4 个 jar 并启动服务，补跑 cso-api-test-v0.0.1.py 完成 TC-001~045 动态回归**（TASK-003 构建启动 + TASK-004/005 回归执行）。

---

## 3. 编译方案（deploy/build.md）

### 3.1 编译命令（项目根目录）
```powershell
mvn clean package -DskipTests
```
- 一次性构建 5 个模块：cloudoffice-common、cloudoffice-gateway、cloudoffice-auth-service、cloudoffice-biz-service、cloudoffice-system-service。
- `-DskipTests` 可选：跳过测试加速构建；完整测试去掉该参数。
- 便捷脚本：`.\deploy\scripts\build-backend.ps1`（等价一键后端构建，含产物落位校验；`-RunTests` 开关执行测试）。

### 3.2 产物落点（deploy 目录，最终产物唯一落点）
| 产物 | 落点 | 默认端口 |
| --- | --- | --- |
| cloudoffice-gateway.jar | deploy/ | 9000 |
| cloudoffice-auth-service.jar | deploy/ | 9100 |
| cloudoffice-biz-service.jar | deploy/ | 9200 |
| cloudoffice-system-service.jar | deploy/ | 9400 |

### 3.3 构建机制（根 pom.xml + 模块 pom.xml）
- 根 pom.xml:56：`<deployDir>${maven.multiModuleProjectDirectory}/deploy</deployDir>` 统一指定输出目录。
- 根 pom.xml:176-180：`maven-antrun-plugin` 版本 3.2.0（pluginManagement 管理）。
- 4 个服务模块 pom 均含 `copy-final-jar-to-deploy` 执行段，package 阶段将 `${project.build.directory}/${project.build.finalName}.jar` **单个最终 jar** 复制至 `${deployDir}/cloudoffice-*.jar`（仅复制单个文件，不递归 target，保证中间产物不进入 deploy）：
  - gateway pom:104-116 → tofile="${deployDir}/cloudoffice-gateway.jar"
  - auth pom:139-151 → tofile="${deployDir}/cloudoffice-auth-service.jar"
  - biz pom:88-100 → tofile="${deployDir}/cloudoffice-biz-service.jar"
  - system pom:88-100 → tofile="${deployDir}/cloudoffice-system-service.jar"

### 3.4 编译环境与常见问题
- JDK 21（JAVA_HOME）、Maven 3.8+（推荐 3.9.x）；根 pom Java 21 / Spring Boot 3.2.5 / Spring Cloud 2023.0.1 / SCA 2023.0.1.0。
- 常见问题：`mvn 不是内部或外部命令`（未配 PATH）；`无效的发行版本 21`（JDK 非 21）；依赖下载超时（配阿里云镜像）；构建成功但 deploy 下无 jar（某模块编译失败，查 Maven 输出）。

---

## 4. 部署方案（deploy/deploy.md）

### 4.1 部署架构与端口
| 组件 | 产物/依赖 | 默认端口 |
| --- | --- | --- |
| API 网关 cloudoffice-gateway | deploy/cloudoffice-gateway.jar | 9000 |
| 认证服务 cloudoffice-auth-service | deploy/cloudoffice-auth-service.jar | 9100 |
| 企业服务 cloudoffice-biz-service | deploy/cloudoffice-biz-service.jar | 9200 |
| 系统服务 cloudoffice-system-service | deploy/cloudoffice-system-service.jar | 9400 |
| MariaDB / Redis / Nacos | 基础设施 | 3306 / 6379 / 8848 |

### 4.2 标准启动流程（部署步骤）
1. **准备部署资产**：按 build.md 执行 `mvn clean package -DskipTests`，确认 4 个 jar 位于 deploy/；部署主机已装 JDK 21、MariaDB、Redis、Nacos。
2. **环境配置（env.json）**：`Copy-Item deploy\env.example.json deploy\env.json`，填写 DB_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等（严禁提交含真实口令的 env.json 到 git）。
3. **生成 RSA 密钥对（首次部署必做）**：`.\deploy\scripts\deploy-rsa-keygen.ps1`，密钥输出到 deploy/keys/，将 Base64 内容填入 env.json 并同步 Nacos 配置；密钥变更后旧令牌全部失效属预期。
4. **数据库初始化**：`.\deploy\scripts\deploy-db-init.ps1`（从 env.json 读连接信息，执行 scripts/sql/ 下初始化 SQL，创建认证库 cloudstroll_office_auth）。
5. **启动基础设施**：`.\deploy\scripts\deploy-start-services.ps1`（加载 env.json → 三重检测 MariaDB/Redis/Nacos → 未运行自动启动 → 输出检测结果）。
6. **启动后端服务**（建议网关最先）：
   ```powershell
   .\deploy\scripts\deploy-start-gateway.ps1
   .\deploy\scripts\deploy-start-auth.ps1
   .\deploy\scripts\deploy-start-biz.ps1
   .\deploy\scripts\deploy-start-system.ps1
   ```
   或直接：`java -Xms256m -Xmx512m -jar deploy\cloudoffice-gateway.jar`（其余服务同理）。

### 4.3 健康检查与验证方式
| 检查项 | 方式 | 预期 |
| --- | --- | --- |
| 网关存活 | 访问 http://<主机>:9000/ | 返回网关响应（404/401 均说明服务在运行） |
| 各服务注册 | Nacos 控制台 http://<主机>:8848/nacos/ 服务列表 | gateway/auth/biz/system 均在线（cloudoffice-* 实例） |
| 认证接口 | POST http://<主机>:9000/（客户端实际调用路径） | 返回正常业务响应 |
| 数据库连通 | 服务日志无数据库连接异常 | 正常 |

### 4.4 常见问题与处理
- 服务启动报 Nacos 连接失败 → Nacos 未启动或 NACOS_ADDR 错误，先执行 deploy-start-services.ps1。
- 服务启动报数据库连接失败 → 检查 DB_HOST/DB_PORT/DB_PASSWORD，执行 deploy-db-init.ps1。
- 登录报令牌校验失败 → RSA 密钥与 Nacos 配置不一致，重新生成密钥并同步 Nacos 配置，重启服务。
- env.json 未生效 → 修改后需重启对应服务。

---

## 5. env.json 注入方式与配置项

### 5.1 load-env.ps1（deploy/scripts/load-env.ps1）
- 功能：读取 `deploy/env.json`（默认参数 EnvFile=env.json，也可 -EnvFile 指定），将每个键值对 `Set-Item -Path "env:$($_.Name)"` 注入当前会话环境变量。
- 路径定位：`$ProjectDir = Split-Path -Parent $PSScriptRoot`（基于脚本位置推导 deploy 目录，无硬编码绝对路径）。
- 用法：`. .\deploy\scripts\load-env.ps1`（点号调用，注入到当前会话）。

### 5.2 env.example.json 配置键清单（deploy/env.example.json，25 项）
| 类别 | 键 |
| --- | --- |
| Nacos | NACOS_ADDR（127.0.0.1:8848）、NACOS_HOME |
| 服务检测 | DB_SERVICE_NAME、DB_PROCESS_NAME、REDIS_SERVICE_NAME、REDIS_PROCESS_NAME |
| 数据库 | DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、DB_USER |
| Redis | REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE |
| RSA 密钥 | RSA_PRIVATE_KEY、RSA_PUBLIC_KEY（DER 单行 Base64） |
| 验证码 | VERIFICATION_CODE_MOCK、VERIFICATION_CODE_EXPIRE_SECONDS、VERIFICATION_CODE_SEND_INTERVAL、VERIFICATION_CODE_LENGTH |
| 密码策略 | PASSWORD_MIN_LENGTH、PASSWORD_MAX_LENGTH |
| 其他 | MARIADB_ROOT_PASSWORD、TZ |

### 5.3 启动脚本环境变量校验（deploy/scripts/deploy-start-*.ps1）
- **deploy-start-gateway.ps1**：`.\deploy\scripts\load-env.ps1` 加载 → 校验 NACOS_ADDR、RSA_PUBLIC_KEY 非空 → 校验 jar 存在 → `java -Xms256m -Xmx512m -jar "$JarPath"` 前台启动。
- **deploy-start-auth.ps1**：加载 env → 校验 9 个必需变量（NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY）→ 校验 jar → java 前台启动。
- **deploy-start-biz.ps1 / deploy-start-system.ps1**：同 auth 模式（加载 env.json + 变量校验 + java 启动）。
- **deploy-start-services.ps1**：加载 env → 校验 8 个基础设施变量（NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*）→ 命令+服务+进程三重检测 MariaDB/Redis/Nacos → 未运行自动启动。
- 所有脚本基于 `$PSScriptRoot` 推导路径，`$JarPath = Join-Path $ProjectDir "cloudoffice-xxx.jar"`。

### 5.4 RSA 密钥生成契约（deploy/scripts/deploy-rsa-keygen.ps1，TASK-002 修复版）
- 输出到 `deploy/keys/`：private_key.pem / public_key.pem（审计用）、private_key.der / public_key.der（DER 二进制）、**private_key_base64.txt / public_key_base64.txt（env.json 注入值来源，DER 单行 Base64）**。
- 生成链路：`openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048` → `openssl pkey -outform DER`（私钥 PKCS#8）/ `-pubout -outform DER`（公钥 X.509 SubjectPublicKeyInfo）→ `[Convert]::ToBase64String()` 单行 Base64（WriteAllText 不追加换行）。
- 契约自校验（第 4 步）：无 `-----BEGIN/-----END` 头尾、无 `[\r\n]` 换行、`[Convert]::FromBase64String` 严格解码成功（与 Java `Base64.getDecoder()` 等价校验）。
- 脱敏：仅打印前 24 字符前缀，私钥不写入日志（敏感信息红线）。

---

## 6. 健康检查 Controller 实现（3 个服务）

### 6.1 认证服务 cloudoffice-auth-service
- 文件：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/HealthController.java`
- 注解：`@RestController` + `@RequestMapping("/api/v1/auth")` + `@GetMapping("/health")` + `@Slf4j`
- 依赖：`@Autowired Environment env`
- 返回：`ApiResult<Map<String, Object>>`，键值：service=`spring.application.name`（默认 cloudoffice-auth-service）、status=`UP`、version=`0.0.1-SNAPSHOT`、timestamp=`Instant.now().toString()`（ISO 时间）；log.debug 记录。

### 6.2 企业服务 cloudoffice-biz-service
- 文件：`cloudoffice-biz-service/src/main/java/org/cloudstrolling/cloudoffice/biz/controller/HealthController.java`
- 注解：`@RestController` + `@RequestMapping("/api/v1/biz")` + `@GetMapping("/health")`
- 依赖：`@Autowired Environment env`；LoggerFactory 手动日志
- 返回：同结构（默认服务名 cloudoffice-biz-service、status=UP、version=0.0.1-SNAPSHOT、timestamp=Instant.now()）；log.info 记录。

### 6.3 系统服务 cloudoffice-system-service
- 文件：`cloudoffice-system-service/src/main/java/org/cloudstrolling/cloudoffice/system/controller/HealthController.java`
- 注解：`@RestController` + `@RequestMapping("/api/v1/system")` + `@GetMapping("/health")` + `@Slf4j` + SpringDoc `@Tag/@Operation`
- 依赖：构造器注入 `Environment env`
- 返回：同结构（默认服务名 cloudoffice-system-service、status=UP、version=0.0.1-SNAPSHOT、**timestamp=System.currentTimeMillis()（毫秒长整型）**）；log.info 记录。

### 6.4 网关（无 HealthController）
- 网关为 Spring Cloud Gateway（Reactive），无独立健康检查 Controller；存活验证为访问 `http://<主机>:9000/` 返回网关响应（404/401 均说明服务在运行）。
- 统一响应体：`org.cloudstrolling.cloudoffice.common.model.ApiResult`（common 模块，`ApiResult.success(info)`）。

### 6.5 接口契约与认证（context.md 汇总，沿用 docs/cso-api.md）
| 接口编号 | 方法 | 路径 | 认证 |
| --- | --- | --- | --- |
| API-012 | GET | /api/v1/auth/health | 白名单（免认证） |
| API-032 | GET | /api/v1/biz/health | 需认证（网关白名单未含，直连 9200 免认证） |
| API-033 | GET | /api/v1/system/health | 需认证（网关白名单未含，直连 9400 免认证） |

- 网关白名单（application.yml `auth.white-list`）包含：`/api/v1/auth/health`、login/register/refresh、verification-code/send、password/forgot/send-code、password/forgot/reset、/swagger-ui/**、/v3/api-docs/**、/favicon.ico、/webjars/**。

---

## 7. Nacos 注册配置（bootstrap.yml + 网关路由）

### 7.1 bootstrap.yml（4 个模块 main/resources，结构一致）
```yaml
spring:
  application:
    name: cloudoffice-{gateway|auth-service|biz-service|system-service}
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
      config:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
        file-extension: yaml
```
- 文件位置：gateway/auth/biz/system 各模块 `src/main/resources/bootstrap.yml`（test/resources 下亦有同名测试资源）。
- 注册名与 context.md 契约一致：cloudoffice-gateway / cloudoffice-auth-service / cloudoffice-biz-service / cloudoffice-system-service。
- 依赖 TASK-001 修复的 `spring-cloud-starter-bootstrap` 才可被 Spring Boot 3.x 加载。

### 7.2 网关路由与配置（cloudoffice-gateway/src/main/resources/application.yml）
- 端口：9000；Redis 连接 ${REDIS_HOST:127.0.0.1}:${REDIS_PORT:6379}（password/database 可配）。
- 路由 3 条：`/api/v1/auth/**` → lb://cloudoffice-auth-service、`/api/v1/biz/**` → lb://cloudoffice-biz-service、`/api/v1/system/**` → lb://cloudoffice-system-service；discovery locator enabled。
- CORS 全放行（allowedOriginPatterns: *）。
- RSA 公钥配置：`auth.rsa.public-key=${RSA_PUBLIC_KEY:}`（环境变量优先），兜底 PEM 路径 `${RSA_PUBLIC_KEY_PATH:}`。

---

## 8. RSA 密钥 Java 端解码契约（TASK-002 修复验证）

### 8.1 网关 RsaKeyConfig（cloudoffice-gateway/.../config/RsaKeyConfig.java）
- `@Value("${auth.rsa.public-key:}")` + `${auth.rsa.public-key-path:}` 兜底（readPemFile 自动剥 PEM 头尾与空行）。
- 解码：`byte[] keyBytes = Base64.getDecoder().decode(keyContent.trim())` + `X509EncodedKeySpec` + `KeyFactory.getInstance("RSA").generatePublic(keySpec)`。
- 校验：公钥为空拒绝启动；Base64 解码失败/KeySpec 生成失败抛 IllegalArgumentException（对应 v0.2.5 的 `RSA 公钥解析失败` 报错点）；强度 < 2048 位 WARN。

### 8.2 认证服务 RsaKeyConfig（cloudoffice-auth-service/.../config/RsaKeyConfig.java）
- `@Value("${jwt.rsa.private-key:}")` / `@Value("${jwt.rsa.public-key:}")`（环境变量 → 配置 → PEM 路径）。
- 解码：严格 `Base64.getDecoder().decode(x.trim())` + 私钥 `PKCS8EncodedKeySpec` / 公钥 `X509EncodedKeySpec`。
- 校验：密钥缺失拒绝启动；Base64 解码失败抛 IllegalStateException；强度 ≥ 2048 位；**密钥对匹配校验**（SHA256withRSA 私钥签名 + 公钥验签，不配对拒绝启动）。

> 结论：TASK-002 修复后，env.json 注入值必须是 **DER 编码单行 Base64**（公钥 X.509 SPKI / 私钥 PKCS#8 PKI），与 deploy-rsa-keygen.ps1 输出严格一致；TASK-003 启动验证时应确认 env.json 中的密钥为 *_base64.txt 内容。

---

## 9. 本任务可直接复用的命令与脚本清单

| 用途 | 命令/脚本 | 位置 |
| --- | --- | --- |
| 后端全量构建 | `mvn clean package -DskipTests`（根目录）或 `.\deploy\scripts\build-backend.ps1` | deploy/build.md:51-61 |
| 基础设施检测与启动 | `.\deploy\scripts\deploy-start-services.ps1` | deploy/deploy.md:107 |
| 启动网关 | `.\deploy\scripts\deploy-start-gateway.ps1` | deploy/deploy.md:118 |
| 启动认证服务 | `.\deploy\scripts\deploy-start-auth.ps1` | deploy/deploy.md:121 |
| 启动企业服务 | `.\deploy\scripts\deploy-start-biz.ps1` | deploy/deploy.md:122 |
| 启动系统服务 | `.\deploy\scripts\deploy-start-system.ps1` | deploy/deploy.md:123 |
| 直接启动 | `java -Xms256m -Xmx512m -jar deploy\cloudoffice-{gateway|auth-service|biz-service|system-service}.jar` | deploy/deploy.md:126-132 |
| RSA 密钥生成（DER 单行 Base64） | `.\deploy\scripts\deploy-rsa-keygen.ps1` | deploy/deploy.md:88-92 |
| 数据库初始化 | `.\deploy\scripts\deploy-db-init.ps1` | deploy/deploy.md:99 |
| 加载环境变量 | `. .\deploy\scripts\load-env.ps1` | deploy/deploy.md:175 |
| 健康检查（3 服务） | `GET http://<主机>:{9100|9200|9400}/api/v1/{auth|biz|system}/health`（直连） | context.md §4 |
| Nacos 注册核对 | 控制台 http://<主机>:8848/nacos/ 服务列表（cloudoffice-* 实例） | deploy/deploy.md:185 |

---

## 10. 关键日志/错误关键字（TASK-003 验证关注点）

| 关键字 | 含义 | 状态 |
| --- | --- | --- |
| `No spring.config.import property has been defined` | bootstrap 缺失导致 nacos-config import-check 失败 | TASK-001 已修复，启动日志**不应再出现** |
| `RSA 公钥解析失败` / `Unable to decode key` / `extra data at the end` | RSA 密钥格式非 DER 单行 Base64 | TASK-002 已修复，启动日志**不应再出现** |
| `Nacos registry ... register finished` / `nacos registry, xxx ... register` | Nacos 注册成功 | 4 个服务均应出现 |
| `RSA 公钥加载成功` / `RsaKeyConfig 初始化成功` | 密钥加载成功 | gateway/auth 应出现 |
| `Started GatewayApplication/AuthApplication/BizApplication/SystemApplication` | 服务启动完成 | 4 个服务均应出现 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
