# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/deploy.md 部署文档 | TASK-010 | 5 | P0：5 |
| readme.md 项目说明 | TASK-010 | 4 | P0：4 |

## 二、测试用例详情
### 模块：deploy/deploy.md 部署文档更新（TASK-010）

#### TC-TASK010-001：deploy.md 端口映射表含 cloudoffice-common（P0）
- **用例ID**：TC-TASK010-001
- **用例名称**：deploy.md 服务端口映射表新增 cloudoffice-common（9300）
- **所属模块**：deploy/deploy.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成，deploy.md 已更新
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010
- **测试数据**：deploy/deploy.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md
  2. 断言包含 "cloudoffice-common" 且同段落含端口 "9300"
- **预期结果**：
  1. 端口映射表含 cloudoffice-common（9300）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-002：deploy.md 启动顺序为 common→gateway→auth→biz→system（P0）
- **用例ID**：TC-TASK010-002
- **用例名称**：deploy.md 一键启动顺序更新为 common 最先启动
- **所属模块**：deploy/deploy.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010
- **测试数据**：deploy/deploy.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md
  2. 断言存在 "common → gateway → auth → biz → system"（或等价表述含 common 首位）
- **预期结果**：
  1. 启动顺序含 common 在第一位
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-003：deploy.md 停止顺序为 system→biz→auth→gateway→common（P0）
- **用例ID**：TC-TASK010-003
- **用例名称**：deploy.md 一键停止顺序更新为 common 最后停止
- **所属模块**：deploy/deploy.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010
- **测试数据**：deploy/deploy.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md
  2. 断言存在 "system → biz → auth → gateway → common"（或等价表述含 common 末位）
- **预期结果**：
  1. 停止顺序含 common 在最后一位
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-004：deploy.md 健康检查端点含 /api/v1/common/health（P0）
- **用例ID**：TC-TASK010-004
- **用例名称**：deploy.md 健康检查说明新增 common 健康检查端点
- **所属模块**：deploy/deploy.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010
- **测试数据**：deploy/deploy.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md
  2. 断言包含 "/api/v1/common/health"
- **预期结果**：
  1. 健康检查端点说明含 /api/v1/common/health
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-005：deploy.md 环境变量说明含 COMMON_PORT（P0）
- **用例ID**：TC-TASK010-005
- **用例名称**：deploy.md 环境变量说明补充 COMMON_PORT 等 common 相关配置项
- **所属模块**：deploy/deploy.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010
- **测试数据**：deploy/deploy.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md
  2. 断言包含 "COMMON_PORT"
- **预期结果**：
  1. 环境变量说明含 common 相关配置项（COMMON_PORT）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

### 模块：readme.md 项目说明更新（TASK-010）

#### TC-TASK010-006：readme.md 项目介绍含 common 服务化说明（P0）
- **用例ID**：TC-TASK010-006
- **用例名称**：readme.md 项目介绍补充 cloudoffice-common 服务化说明
- **所属模块**：readme.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-011
- **测试数据**：readme.md 文本内容
- **测试步骤**：
  1. 读取 readme.md
  2. 断言包含 "cloudoffice-common" 且含服务化相关表述（如 "独立部署" / "微服务" / "服务化"）
- **预期结果**：
  1. 项目介绍含 common 服务化说明
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-007：readme.md 功能清单含通用配置管理功能介绍（P0）
- **用例ID**：TC-TASK010-007
- **用例名称**：readme.md 功能清单新增通用配置管理功能介绍
- **所属模块**：readme.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-011
- **测试数据**：readme.md 文本内容
- **测试步骤**：
  1. 读取 readme.md
  2. 断言包含 "通用配置管理" 且含功能介绍（统一管理/查询）
- **预期结果**：
  1. 功能清单含通用配置管理功能介绍
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-008：readme.md 端口映射含 cloudoffice-common（P0）
- **用例ID**：TC-TASK010-008
- **用例名称**：readme.md 端口分配表新增 cloudoffice-common（9300）
- **所属模块**：readme.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-011
- **测试数据**：readme.md 文本内容
- **测试步骤**：
  1. 读取 readme.md
  2. 断言包含 "cloudoffice-common" 且同段落/端口表含 "9300"
- **预期结果**：
  1. 端口映射表含 cloudoffice-common（9300）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

#### TC-TASK010-009：现有 gateway/auth/biz/system 内容未被删除或覆盖（P0）
- **用例ID**：TC-TASK010-009
- **用例名称**：文档更新后现有 gateway/auth/biz/system 部署说明与功能介绍保留
- **所属模块**：deploy/deploy.md、readme.md
- **优先级**：P0
- **前置条件**：TASK-010 编码完成
- **测试类型**：功能测试（文档校验）
- **关联需求ID**：US-006 / F-010 / F-011
- **测试数据**：deploy/deploy.md、readme.md 文本内容
- **测试步骤**：
  1. 读取 deploy/deploy.md，断言仍包含 gateway/auth/biz/system 各自端口（9000/9100/9200/9400）与服务说明
  2. 读取 readme.md，断言仍包含 gateway/auth/biz/system 模块说明与端口
- **预期结果**：
  1. 现有 gateway/auth/biz/system 内容未被删除或覆盖
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task010_docs_checks
- **测试过程与结论**：通过（2026-08-13 执行接口测试脚本 test_task010_docs_checks，TC-TASK010-001~009 全部 PASS）

> 说明：本任务为文档更新（deploy.md / readme.md），无代码逻辑变更，单元测试/接口测试/UI 测试不适用；以功能测试（文档内容校验）覆盖。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | TC-TASK010-001~009 全部通过（9/9，2026-08-13 test_task010_docs_checks 执行，PASS=9） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 文档与脚本现状不一致 | 部署文档指引与脚本行为脱节 | 校验以 deploy 脚本实际现状与 SAD/PRD 契约为基准 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
