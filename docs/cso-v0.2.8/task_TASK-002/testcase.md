# 测试用例文档（TestCase）— TASK-002

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**任务编号**：TASK-002
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| cloudoffice-common 服务化改造 | TASK-002 | 7 | P0×7 |

## 二、测试用例详情

### 模块：cloudoffice-common - 服务化改造（启动类/配置/pom）

#### TC-TASK002-001：CommonApplication 启动类存在且注解正确（P0）
- **用例ID**：TC-TASK002-001
- **用例名称**：CommonApplication 类存在，标注 @SpringBootApplication/@EnableDiscoveryClient 并含 main 方法
- **所属模块**：cloudoffice-common（启动类）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-001 / F-001
- **测试数据**：cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/CommonApplication.java
- **测试步骤**：
  1. 反射加载 org.cloudstrolling.cloudoffice.common.CommonApplication 类
  2. 断言类上存在 @SpringBootApplication 注解
  3. 断言类上存在 @EnableDiscoveryClient 注解
  4. 断言存在 main(String[]) 方法
- **预期结果**：
  1. 类可被加载，注解与 main 方法齐全
  2. 无编译错误
- **自动化测试函数/脚本位置**：cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/CommonApplicationConfigTest.java（commonApplication_shouldBeBootApplicationWithMain）
- **测试过程与结论**：通过（单元测试 2026-08-13 执行：Tests run: 120, Failures: 0, Errors: 0）

#### TC-TASK002-002：bootstrap.yml 引导配置正确（P0）
- **用例ID**：TC-TASK002-002
- **用例名称**：bootstrap.yml 含应用名 cloudoffice-common 与 Nacos discovery/config 引导配置
- **所属模块**：cloudoffice-common（bootstrap.yml）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-001 / F-001
- **测试数据**：cloudoffice-common/src/main/resources/bootstrap.yml
- **测试步骤**：
  1. 读取 classpath:bootstrap.yml 内容
  2. 断言 spring.application.name 为 cloudoffice-common
  3. 断言 spring.cloud.nacos.discovery.server-addr 含 ${NACOS_ADDR
  4. 断言 spring.cloud.nacos.config.server-addr 含 ${NACOS_ADDR
  5. 断言存在 namespace ${NACOS_NAMESPACE 与 file-extension yaml
- **预期结果**：
  1. 上述配置项全部存在且取值正确
- **自动化测试函数/脚本位置**：CommonApplicationConfigTest.java（bootstrapYml_shouldContainNacosBootstrapConfig）
- **测试过程与结论**：通过（单元测试 2026-08-13 执行）

#### TC-TASK002-003：application.yml 运行配置正确（P0）
- **用例ID**：TC-TASK002-003
- **用例名称**：application.yml 端口 ${COMMON_PORT:9300}、springdoc 分组 common、DataSource/MyBatis 自动配置排除
- **所属模块**：cloudoffice-common（application.yml）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-001 / F-001 / F-002
- **测试数据**：cloudoffice-common/src/main/resources/application.yml
- **测试步骤**：
  1. 读取 classpath:application.yml 内容
  2. 断言 server.port 为 ${COMMON_PORT:9300}
  3. 断言 springdoc.group-configs 含 group: common
  4. 断言 spring.autoconfigure.exclude 含 DataSourceAutoConfiguration 与 MybatisPlusAutoConfiguration
- **预期结果**：
  1. 上述配置项全部存在且取值正确
- **自动化测试函数/脚本位置**：CommonApplicationConfigTest.java（applicationYml_shouldContainServiceConfig）
- **测试过程与结论**：通过（单元测试 2026-08-13 执行）

#### TC-TASK002-004：pom.xml 依赖与打包配置正确（P0）
- **用例ID**：TC-TASK002-004
- **用例名称**：pom.xml 引入 bootstrap/Nacos 依赖、spring-boot-maven-plugin（classifier=exec）与 deploy 复制插件
- **所属模块**：cloudoffice-common（pom.xml）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成
- **测试类型**：单元测试
- **关联需求ID**：US-001 / US-005 / F-001 / F-007
- **测试数据**：cloudoffice-common/pom.xml
- **测试步骤**：
  1. 读取 cloudoffice-common/pom.xml 内容
  2. 断言包含 spring-cloud-starter-bootstrap 依赖
  3. 断言包含 spring-cloud-starter-alibaba-nacos-discovery 与 spring-cloud-starter-alibaba-nacos-config 依赖
  4. 断言 build 段包含 spring-boot-maven-plugin（configuration.classifier=exec）与 maven-antrun-plugin（tofile 含 cloudoffice-common.jar）
- **预期结果**：
  1. 上述依赖与插件配置全部存在
- **自动化测试函数/脚本位置**：CommonApplicationConfigTest.java（pomXml_shouldContainServiceDependenciesAndPackaging）
- **测试过程与结论**：通过（单元测试 2026-08-13 执行）

#### TC-TASK002-005：构建产物可执行 jar 落位 deploy（P0）
- **用例ID**：TC-TASK002-005
- **用例名称**：mvn package 后 deploy/cloudoffice-common.jar 存在且含 Spring Boot Loader
- **所属模块**：cloudoffice-common（构建产物）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成、Maven 环境就绪
- **测试类型**：接口测试（构建产物校验）
- **关联需求ID**：US-005 / F-007
- **测试数据**：mvn -pl cloudoffice-common -am package（或 build-backend）
- **测试步骤**：
  1. 执行 mvn -pl cloudoffice-common -am clean package -DskipTests
  2. 检查 deploy/cloudoffice-common.jar 是否存在
  3. 检查 jar 内 org/springframework/boot/loader 目录存在（可执行 fat jar）
  4. 检查 target/cloudoffice-common-0.0.1-SNAPSHOT.jar 仍为普通 jar（瘦 jar，下游依赖不受影响）
- **预期结果**：
  1. deploy/cloudoffice-common.jar 存在且可执行
  2. 主 artifact 仍为瘦 jar
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py（test_task002_build_artifact）
- **测试过程与结论**：通过（接口测试 2026-08-13 执行：deploy/cloudoffice-common.jar 为可执行 fat jar，loader/启动类/yml 齐全；主 artifact 瘦 jar 0.04MB < 2MB）

#### TC-TASK002-006：common 服务独立启动冒烟（P0）
- **用例ID**：TC-TASK002-006
- **用例名称**：java -jar 启动 cloudoffice-common.jar 后监听 9300 端口
- **所属模块**：cloudoffice-common（独立启动）
- **优先级**：P0
- **前置条件**：Nacos 已运行（服务注册依赖）、COMMON_PORT 环境变量或默认 9300
- **测试类型**：接口测试（启动冒烟）
- **关联需求ID**：US-001 / F-001 / F-002
- **测试数据**：java -Xms256m -Xmx512m -jar deploy/cloudoffice-common.jar（NACOS_ADDR/COMMON_PORT 注入）
- **测试步骤**：
  1. 后台启动 common jar（注入 NACOS_ADDR）
  2. 等待启动，探测 localhost:9300 TCP 端口与 /v3/api-docs（或根路径）HTTP 响应
  3. 校验 Nacos 服务列表出现 cloudoffice-common（如 Nacos 控制台可达）
  4. 停止进程并清理 PID
- **预期结果**：
  1. 服务启动成功，9300 端口监听
  2. 注册到 Nacos（服务名 cloudoffice-common）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py（test_task002_startup_smoke）
- **测试过程与结论**：阻塞（环境：Nacos 8848 未运行，启动失败于 Nacos 服务注册步骤——NacosException: Client not connected, current status:STARTING；日志 deploy/logs/common-start-test.log 证明应用上下文、DataSource 排除、Web 服务器均已正确初始化至注册步骤，符合 PRD US-001 边界场景"Nacos 未启动→启动失败输出 Nacos 连接错误提示"；Nacos 就绪后即可注册成功）

#### TC-TASK002-007：下游服务依赖不受影响（编译回归）（P0）
- **用例ID**：TC-TASK002-007
- **用例名称**：common 服务化后 gateway/auth/biz/system 对 common 的 Maven 依赖编译正常
- **所属模块**：全量 Maven 多模块（编译回归）
- **优先级**：P0
- **前置条件**：TASK-002 编码完成
- **测试类型**：功能测试（编译回归）
- **关联需求ID**：US-001 / F-001
- **测试数据**：mvn -q clean package（全量 reactor）
- **测试步骤**：
  1. 在项目根目录执行 mvn -q clean package -DskipTests
  2. 断言构建成功（退出码 0）
  3. 检查 deploy 下 gateway/auth/biz/system jar 均生成
- **预期结果**：
  1. 全量编译通过，无依赖冲突
  2. 4 个既有服务 jar 正常输出
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py（test_task002_downstream_compile）
- **测试过程与结论**：通过（2026-08-13 执行 mvn clean package -DskipTests 退出码 0；deploy 下 common/gateway/auth/biz/system 5 个 jar 齐全，下游服务编译不受影响）

> 说明：本任务为后端服务化改造，无前端界面，UI 测试不适用。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 6 |
| 失败 | 0 |
| 阻塞 | 1 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| Nacos 未运行 | TC-006 启动冒烟无法验证注册 | 检测 Nacos 状态，未运行则记录阻塞并说明，其余用例照常执行 |
| 全量编译耗时 | TC-007 回归编译时间较长 | 使用 -q 静默模式，仅断言退出码与产物 |
| 与并行任务写测试用例文档冲突 | 版本测试用例文档被覆盖 | 写入前读最新内容，合并写回并回读校验 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
