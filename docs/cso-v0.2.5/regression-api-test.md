# 接口测试回归报告（regression-api-test）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**测试时间**：2026-08-09 16:32 ~ 16:36
**测试负责人**：TE
**测试类型**：接口回归（v0.2.5 无接口变更，接口回归 = 静态契约确认 + 基线动态回归环境评估）

## 一、脚本清单与执行结果

| 脚本名称 | 执行命令 | 用例数 | 通过 | 失败 | 跳过 | 结果 |
| --- | --- | --- | --- | --- | --- | --- |
| scripts/API-TEST/cso-api-test-v0.2.5.py | `python cso-api-test-v0.2.5.py <项目根>`（Python 3.13.11/miniconda3） | 27（TC-046~051 断言级） | 26 | 0 | 1 | **通过**（退出码 0） |
| scripts/API-TEST/cso-api-test-v0.0.1.py | `python cso-api-test-v0.0.1.py http://localhost:9000` | 45（TC-001~045） | 0 | 0 | 0 | **环境阻塞**（脚本在 admin 登录连接拒绝即崩溃，退出码 1） |

## 二、v0.2.5 接口回归明细（cso-api-test-v0.2.5.py）

覆盖 TC-046~TC-051（TASK-001~006 无接口变更回归确认）：

| 用例 | 断言 | 结果 |
| --- | --- | --- |
| TC-046 | ① 版本 API 文档无新增/变更/删除接口 ② git 变更清单未触碰接口层文件 ③ 健康检查连通性（可选） | 通过（TC-046-3 服务未启动按可选 SKIP） |
| TC-047 | ① API 文档无接口变更 ② git 变更清单无接口层改动 ③ env 迁移后变更仅为文档/测试资产 ④ 既有契约 API-001~API-033 完整保留 | 通过 |
| TC-048 | ① API 文档无接口变更 ② git 变更清单无接口层改动 ③ 脚本迁移后无业务代码/接口层改动 ④ 契约完整 ⑤ deploy/scripts 脚本接口地址引用无变化 | 通过 |
| TC-049 | ① API 文档无接口变更 ② git 变更清单无接口层改动 ③ 构建配置修改后无业务代码/接口层/客户端资源改动 ④ 契约完整 ⑤ 脚本接口地址引用无变化 | 通过 |
| TC-050 | ① API 文档无接口变更 ② git 变更清单无接口层改动 ③ 客户端构建配置修改后无业务代码/接口层/运行时代码改动 ④ lib/ 无改动 ⑤ 契约完整 | 通过 |
| TC-051 | ① API 文档无接口变更 ② git 变更清单无接口层改动 ③ 无客户端运行时代码（lib/）改动 ④ 契约完整 ⑤ deploy/scripts 脚本健康检查接口地址引用保持既有契约 | 通过 |

**结论**：v0.2.5 接口回归 PASS=26、FAIL=0、SKIP=1（TC-046-3 健康检查因服务未启动按脚本约定的可选场景 SKIP，不视为失败）。本版本无接口变更声明成立，既有接口契约（API-001~API-033）在文档与代码层面均未受影响。

## 三、v0.0.1 基线动态接口回归（TC-001~045）——环境阻塞说明

### 3.1 现象

cso-api-test-v0.0.1.py 需要网关（9000）+ 认证服务（9100）+ 数据库/Redis 运行。本机 MariaDB（3306）与 Redis（6379）正常，Nacos（8848）已启动，但 4 个业务服务（gateway/auth/biz/system）**均无法启动**，脚本在 admin 登录步骤即因连接拒绝崩溃（退出码 1），TC-001~045 无法动态执行。

### 3.2 根因（启动失败，产品/配置缺陷）

1. **所有服务模块缺少 `spring-cloud-starter-bootstrap` 依赖**（全项目 pom 均未引入）：
   - auth/biz/system 启动报 `No spring.config.import property has been defined`（nacos-config 的 import-check 失败）；
   - bootstrap.yml（含 nacos discovery/config server-addr）在 Spring Boot 3.x 下默认不加载，Nacos 配置引导链路断裂。
2. **env.json 中 RSA 密钥格式与 Java 解码契约不匹配**：
   - deploy/env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 **PEM 文件整体 Base64（多行，含 BEGIN/END 标记与 \r\n）**（deploy-rsa-keygen.ps1 生成格式）；
   - Java 端 RsaKeyConfig（gateway/auth）使用严格 `Base64.getDecoder()` + `X509EncodedKeySpec`（期望 **DER 编码的 Base64，单行**），网关启动即报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。

### 3.3 影响与建议

- 影响：TC-001~045（v0.0.1 基线接口契约动态回归）本次无法闭环；该 45 个用例在 v0.0.1 阶段汇总亦为"待执行"（从未完成动态闭环），v0.2.5 回归再次暴露。
- 建议（回退编码/部署环节）：
  1. 在根 pom 或各模块引入 `spring-cloud-starter-bootstrap`（或按需启用 `spring.config.import=optional:nacos:` 与关闭 import-check），保证 bootstrap.yml 生效；
  2. 修正 RSA 密钥生成/注入格式：deploy-rsa-keygen.ps1 输出 DER 单行 Base64（或 Java 端改用 MIME 解码器并剥除 PEM 头尾），保证 env.json 密钥与代码契约一致；
  3. 修复后重新构建 4 个 jar 并启动服务，补跑 cso-api-test-v0.0.1.py 完成 TC-001~045 动态回归。

## 四、缺陷闭环补记（TASK-006 回退修复，2026-08-09）

- **UT-089-3（版本管理缺陷）已闭环**：TASK-005-修复（commit 1a61b33）修复了 deploy 客户端构建产物误入库问题（.gitignore 新增忽略规则 + `git rm --cached`）；复测 scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1 全部 17 项断言通过（**PASS=17 FAIL=0**），UT-089-3 已闭环，详见 regression-unit-test.md。
- **TC-001~045（v0.0.1 基线接口动态回归）仍为环境阻塞**：根因（bootstrap 依赖缺失 + RSA 密钥格式契约不匹配）属 v0.0.1 基线遗留问题（审核项 T-02），涉及运行时代码变更超出 v0.2.5 部署资产集中化范围，本版本不修复，记录为后续版本待办；本项不阻塞 v0.2.5 交付（v0.2.5 无接口变更，契约静态确认已通过）。

## 五、结论

- v0.2.5 接口回归（TC-046~051）：**通过**（PASS=26、FAIL=0、SKIP=1 可选），无接口变更声明成立。
- 版本管理缺陷闭环：**UT-089-3 已闭环**（1/1，TASK-005-修复 1a61b33，复测 PASS=17 FAIL=0）。
- v0.0.1 基线接口回归（TC-001~045）：**环境阻塞**（服务无法启动），非契约失败；根因为长期遗留的 bootstrap 依赖缺失与 RSA 密钥格式契约不一致（T-02，v0.0.1 基线遗留），本版本按修复范围不处理，记录待办（闭环 0/1，不影响本版本交付）。
- 接口脚本本身无需修改（v0.2.5 脚本通过；v0.0.1 脚本逻辑正常，仅环境不可用）。

## 六、签名确认

- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：待确认

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
