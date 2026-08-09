# 单元测试回归报告（Unit Test Regression）

**项目名称**：云漫智企（CloudStrollOffice）
**项目英文缩写**：cso
**版本号**：v0.2.6
**测试时间**：2026-08-09 23:06:21 ~ 23:06:23
**测试负责人**：TE
**测试类型**：单元测试回归（全量）

## 一、测试时间与运行环境

| 项目 | 内容 |
| --- | --- |
| 测试时间 | 2026-08-09 23:06:21 ~ 23:06:23 |
| 运行环境 | Windows（win32）· PowerShell 5.1（调用 powershell -NoProfile -ExecutionPolicy Bypass -File） |
| 项目根目录 | D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice |
| 测试对象 | scripts/API-TEST/cso-unit-test-*-v0.2.6.ps1 系列（5 个脚本，对应 TASK-001~005 全部单元测试用例） |
| 覆盖用例 | UT-097~UT-131（v0.2.6 全部单元测试用例，TASK-001~005） |

## 二、执行命令

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-rsa-key-contract-v0.2.6.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-security-config-v0.2.6.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1 -ProjectRoot D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice
```

## 三、统计结果

| 脚本 | 关联任务 | 覆盖用例 | 通过 | 失败 | 跳过 | 退出码 |
| --- | --- | --- | --- | --- | --- | --- |
| cso-unit-test-bootstrap-dependency-v0.2.6.ps1 | TASK-001（bootstrap 依赖修复） | UT-097~104 | 14 | 1 | 0 | 1 |
| cso-unit-test-rsa-key-contract-v0.2.6.ps1 | TASK-002（RSA 密钥格式契约） | UT-105~112 | 25 | 1 | 0 | 1 |
| cso-unit-test-build-verify-v0.2.6.ps1 | TASK-003（4 服务启动验证） | UT-113~120 | 18 | 0 | 0 | 0 |
| cso-unit-test-security-config-v0.2.6.ps1 | TASK-004（SecurityConfig 白名单修复） | UT-121~125 | 18 | 1 | 0 | 1 |
| cso-unit-test-api-contract-regression-v0.2.6.ps1 | TASK-005（契约无回归保障） | UT-126~131 | 15 | 0 | 0 | 0 |
| **合计** | TASK-001~005 | UT-097~131 | **90** | **3** | **0** | — |

- 断言总数：93（90 PASS + 3 FAIL）
- 通过率：90/93 = 96.8%（3 项失败均为版本级 git 变更断言在"已提交"状态下的已知失效，非代码缺陷，详见第四节）

## 四、失败用例清单及原因

| 序号 | 用例ID | 脚本 | 失败断言 | 现象 | 原因分析 | 判定 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | UT-104-2 | cso-unit-test-bootstrap-dependency-v0.2.6.ps1 | 5 个 pom（根 pom + 4 模块）应在 git 变更清单 | 实际 pom 变更数=0，FAIL | 该断言检查**工作区未提交变更**中是否含 5 个 pom；TASK-001 的 pom 修改已于提交 `fda56a1 cso-v0.2.6-TASK-001` 入库，工作区当前仅 2 项未提交变更（docs/cso-testcase.md、docs/cso-v0.2.6/version_progress.md，为本次回归文档更新） | 断言失效（已提交状态），非代码缺陷。git log 证据：pom.xml 最新修改提交 fda56a1（TASK-001） |
| 2 | UT-112-1 | cso-unit-test-rsa-key-contract-v0.2.6.ps1 | deploy-rsa-keygen.ps1 应在 git 变更清单 | 实际 hits: none，FAIL | 同 UT-104-2 现象：deploy/scripts/deploy-rsa-keygen.ps1 已于提交 `b42558d cso-v0.2.6-TASK-002` 入库（后续 TASK-003 提交 cb25c6b 亦有涉及），不再出现在工作区未提交变更清单 | 断言失效（已提交状态），非代码缺陷。git log 证据：deploy-rsa-keygen.ps1 最新修改提交 b42558d（TASK-002） |
| 3 | UT-124-3 | cso-unit-test-security-config-v0.2.6.ps1 | 网关 application.yml 白名单 logout 增补应在 git diff 中出现（≥1） | 实际 logout whitelist added=0，FAIL | 同 UT-104-2 现象：网关 application.yml 的白名单 logout 增补已于提交 `67fe642 cso-v0.2.6-TASK-004` 入库，`git diff` 不再显示该变更（路由结构 diff hits=0 部分 PASS，logout 增补 hits=0 断言失效） | 断言失效（已提交状态），非代码缺陷。git log 证据：cloudoffice-gateway/src/main/resources/application.yml 最新修改提交 67fe642（TASK-004） |

> **失败性质说明**：3 项失败均为「版本级 git 变更清单断言」在版本提交已完成后的**已知失效现象**（断言设计为验证"任务编码时"的变更清单，任务提交入库后工作区变更清单不再包含目标文件）。该现象与 TASK-004/TASK-005 执行记录中已登记的同类断言行为（cso-api-test-v0.2.6.py 的 TC-052-4/TC-054-4 版本级变更控制断言在提交后失效）完全一致，非产品代码缺陷、非接口契约回归。git log 证据确认相关修复（pom bootstrap 依赖、RSA 密钥脚本、网关白名单）均已正确提交入库，且全部**功能断言**（UT-097~103、UT-105~111、UT-113~120、UT-121~123、UT-125~131 共 90 项）全部 PASS，修复效果未回退。

## 五、结论

- v0.2.6 全量单元测试执行完成：**PASS=90、FAIL=3、SKIP=0**（3 项失败均为已提交状态下的版本级 git 变更断言失效，非代码缺陷，附 git log 证据）。
- 全部功能断言通过，TASK-001~005 五项修复（bootstrap 依赖、RSA 密钥格式契约、4 服务构建产物、SecurityConfig 白名单、接口契约静态核对）均验证有效、无回退。
- 若后续版本需要消除此类断言失效，可调整断言为「目标文件已入库（git log 命中）或在工作区变更清单中，均视为通过」，已作为注意项在回归报告中登记。
- 单元测试回归判定：**通过**（核心功能断言全部 PASS；3 项版本级断言失效如实记录，不影响版本质量结论）。
