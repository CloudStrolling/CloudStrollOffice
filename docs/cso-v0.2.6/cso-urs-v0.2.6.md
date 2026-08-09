# 用户需求说明书（URS）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**编写人**：BA

## 1. 业务目标
本版本依据 v0.2.5 回归测试报告（docs/cso-v0.2.5/regression-api-test.md）中记录的服务无法启动问题（根因：bootstrap 依赖缺失、RSA 密钥格式契约不匹配），修复部署与配置缺陷，使 4 个业务服务（gateway/auth/biz/system）能够正常启动，并完成 v0.0.1 基线接口动态回归（TC-001~045）闭环。具体量化目标：

- G-1：4 个业务服务（gateway/auth/biz/system）在标准部署流程下全部成功启动，健康检查通过率 100%。
- G-2：v0.0.1 基线接口回归脚本（cso-api-test-v0.0.1.py，TC-001~045）全部动态执行通过，通过率 100%（PASS=45、FAIL=0）。
- G-3：v0.2.5 接口回归脚本（cso-api-test-v0.2.5.py，TC-046~051）保持通过，既有接口契约（API-001~API-033）不受影响（PASS=26、FAIL=0）。

## 2. 用户角色
| 角色名称 | 角色说明 | 使用场景 |
| --- | --- | --- |
| 运维/部署人员 | 负责环境配置（env.json、Nacos）、构建与启动服务 | 按部署文档准备密钥与环境变量、构建 jar、启动并验证服务健康 |
| 测试工程师（TE） | 负责接口回归测试执行与结果记录 | 补跑 v0.0.1 基线接口回归（TC-001~045）及本版本接口回归 |
| 企业用户（最终用户） | 通过 Web/Windows 客户端使用办公套件业务功能 | 登录认证、业务操作，依赖服务可用性 |

## 3. 业务场景
### 3.1 场景：服务启动与配置引导修复
- 触发条件：v0.2.5 回归测试发现 4 个服务均无法启动（连接拒绝），API 基线测试环境阻塞。
- 参与角色：运维/部署人员、测试工程师。
- 操作流程：
  1. 运维/部署人员引入 spring-cloud-starter-bootstrap 依赖，恢复 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路；
  2. 运维/部署人员统一 RSA 密钥格式契约（DER 单行 Base64），保证 deploy/env.json 中 RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 与 Java 端 Base64.getDecoder() + X509EncodedKeySpec 解码逻辑一致；
  3. 重新构建 4 个服务 jar 并启动，验证服务注册到 Nacos、健康检查通过。

### 3.2 场景：API 基线动态回归闭环
- 触发条件：服务启动修复完成后，需要验证 v0.0.1 基线接口契约（API-001~API-033，TC-001~045）真实可用。
- 参与角色：测试工程师。
- 操作流程：
  1. 测试工程师执行 cso-api-test-v0.0.1.py（TC-001~045），确认登录、认证、业务接口动态回归全部通过；
  2. 执行 cso-api-test-v0.2.5.py（TC-046~051）确认既有接口契约无回归；
  3. 输出回归测试报告，更新测试结论。

## 4. 功能需求（高层）
| 需求编号 | 需求名称 | 需求描述 | 优先级 |
| --- | --- | --- | --- |
| FR-001 | 引入 bootstrap 配置引导依赖 | 在根 pom 或各服务模块引入 spring-cloud-starter-bootstrap（或等价启用 spring.config.import=optional:nacos: 并关闭 import-check），保证 bootstrap.yml 生效，Nacos 配置/注册引导链路恢复，消除服务启动报错 `No spring.config.import property has been defined` | 高 |
| FR-002 | 修复 RSA 密钥格式契约 | 统一 RSA 密钥格式：deploy-rsa-keygen.ps1 生成/env.json 注入的 RSA_PUBLIC_KEY、RSA_PRIVATE_KEY 与 Java 端 RsaKeyConfig 解码契约一致（DER 编码单行 Base64，或 Java 端兼容剥离 PEM 头尾的多行 Base64），消除网关启动报错 `RSA 公钥解析失败` | 高 |
| FR-003 | 服务可正常启动并健康检查通过 | 修复后重新构建 gateway、auth、biz、system 4 个服务 jar，全部成功启动、注册到 Nacos、健康检查接口返回正常 | 高 |
| FR-004 | v0.0.1 基线接口回归闭环 | 补跑 scripts/API-TEST/cso-api-test-v0.0.1.py，TC-001~045 全部动态执行通过（登录、认证、网关鉴权、业务接口契约），消除历史"待执行"状态 | 高 |
| FR-005 | 既有接口契约无回归 | 本版本修复不得改变既有接口契约（API-001~API-033），cso-api-test-v0.2.5.py（TC-046~051）保持通过 | 中 |

## 5. 非功能需求（高层）
| 编号 | 类别 | 需求描述 | 指标 |
| --- | --- | --- | --- |
| NFR-001 | 可靠性 | 4 个服务按部署文档标准流程启动全部成功，健康检查通过 | 成功率 100%，无 `No spring.config.import` / `RSA 公钥解析失败` 报错 |
| NFR-002 | 兼容性 | 修复不改变对外接口契约与业务行为，客户端无需修改 | API-001~API-033 契约完整，接口脚本断言零失败 |
| NFR-003 | 可维护性 | 密钥生成脚本与 Java 解码契约保持一致，部署文档同步说明格式要求 | env.json 密钥格式与 RsaKeyConfig 解码逻辑一致，配置无歧义 |
| NFR-004 | 性能 | 配置引导与启动流程不引入显著性能损耗 | 服务启动耗时与常规水平相当，无新增明显延迟 |

## 6. 约束条件
- 技术栈约束：Java 21、Spring Boot 3.2.5、Spring Cloud 2023.0.1、Maven 多模块；bootstrap.yml 加载方式须符合 Spring Boot 3.x 机制。
- 基础设施约束：依赖 MariaDB 10.6（3306）、Redis 7.2（6379）、Nacos 2.3（8848）环境可用。
- 契约约束：本版本不得变更既有接口契约（API-001~API-033），不得变更客户端运行时代码。
- 范围约束：修复项为 v0.0.1 基线遗留问题（审核项 T-02），修复范围限定在依赖配置、密钥格式契约与服务启动链路，不扩展新业务功能。

## 7. 假设与依赖
- 假设 v0.2.5 回归报告（docs/cso-v0.2.5/regression-api-test.md）记录的根因（bootstrap 依赖缺失、RSA 密钥格式不匹配）为服务无法启动的全部原因；若修复后仍有启动问题，需继续排查并纳入本版本或后续版本处理。
- 依赖部署环境：Nacos、MariaDB、Redis 已启动且网络可达，部署环境可执行 jar 构建与启动。
- 依赖 deploy/env.json 与 deploy-rsa-keygen.ps1 脚本可按修复后的契约更新；如实际采用 Java 端兼容方案（MIME 解码/剥离 PEM 头尾），需同步更新部署文档说明。
- 本版本修复完成并验证通过后，由 TE 输出 v0.2.6 回归测试报告，确认 API 测试全部跑通。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
