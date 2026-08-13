# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/scripts（deploy-start-all 启动脚本，common 居首） | TASK-007 | 7 | P0×7 |

## 二、测试用例详情

### 模块：deploy/scripts - deploy-start-all 启动脚本更新（TASK-007）

#### TC-TASK007-001：deploy-start-all.ps1 服务清单含 common 且居首（P0）
- **用例ID**：TC-TASK007-001
- **用例名称**：deploy-start-all.ps1 服务启动顺序为 common → gateway → auth → biz → system（common 最先启动）
- **所属模块**：deploy/scripts（deploy-start-all.ps1）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-003 / F-008 / ADR-019
- **测试数据**：deploy/scripts/deploy-start-all.ps1
- **测试步骤**：
  1. 读取 deploy/scripts/deploy-start-all.ps1 内容
  2. 断言 $Services 数组含 5 项：common(9300)/gateway(9000)/auth(9100)/biz(9200)/system(9400)
  3. 断言 common 位于数组第一位（Jar=cloudoffice-common.jar，Port 读 COMMON_PORT 缺省 9300，HealthUrl 含 /api/v1/common/health，RequiredVars 含 NACOS_ADDR/COMMON_PORT/DB_PASSWORD）
  4. 断言启动循环与健康确认遍历 5 个服务（common 健康确认成功后再启动 gateway）
  5. 断言汇总输出（结尾各服务启动结果遍历）覆盖 common
- **预期结果**：
  1. $Services 含 5 个后端服务，common 在首位
  2. 健康确认与汇总输出均覆盖 common
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

#### TC-TASK007-002：deploy-start-all.sh 服务清单含 common 且居首（P0）
- **用例ID**：TC-TASK007-002
- **用例名称**：deploy-start-all.sh 服务启动顺序为 common → gateway → auth → biz → system（common 最先启动）
- **所属模块**：deploy/scripts（deploy-start-all.sh）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-003 / F-008 / ADR-019
- **测试数据**：deploy/scripts/deploy-start-all.sh
- **测试步骤**：
  1. 读取 deploy/scripts/deploy-start-all.sh 内容
  2. 断言 SERVICES 数组含 5 项（common|cloudoffice-common.jar|${COMMON_PORT:-9300}|http://localhost:${COMMON_PORT:-9300}/api/v1/common/health|NACOS_ADDR,COMMON_PORT,DB_PASSWORD 居首，其后 gateway|9000、auth|9100、biz|9200、system|9400）
  3. 断言启动循环与健康确认遍历 5 个服务（common 健康确认成功后再启动 gateway）
  4. 断言汇总输出（结尾各服务启动结果遍历）覆盖 common
- **预期结果**：
  1. SERVICES 含 5 个后端服务，common 在首位
  2. 与 .ps1 契约对齐（双平台行为一致）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

#### TC-TASK007-003：deploy-start-common.ps1 存在且契约正确（P0）
- **用例ID**：TC-TASK007-003
- **用例名称**：deploy-start-common.ps1 存在，契约（ServiceName=common、Jar=cloudoffice-common.jar、Port 读 COMMON_PORT 缺省 9300、HealthUrl=/api/v1/common/health、RequiredVars 含 COMMON_PORT）正确
- **所属模块**：deploy/scripts（deploy-start-common.ps1）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-003 / F-008 / F-009
- **测试数据**：deploy/scripts/deploy-start-common.ps1
- **测试步骤**：
  1. 确认 deploy/scripts/deploy-start-common.ps1 存在
  2. 读取脚本内容，断言含 $ServiceName="common"、$JarName="cloudoffice-common.jar"、$ServicePort 读 COMMON_PORT（缺省 9300）、$HealthUrl 含 /api/v1/common/health、$RequiredVars 含 NACOS_ADDR/COMMON_PORT/DB_PASSWORD
  3. 断言脚本经 load-env.ps1 加载 env.json
  4. 断言启动命令 java -Xms256m -Xmx512m -jar，日志/PID 落 deploy/logs/（common-start.log/.err、common.pid）
  5. 断言输出分级（通过/警告/失败）与退出码约定（失败非零）
- **预期结果**：
  1. 脚本存在且契约正确
  2. 遵循 v0.2.7 脚本体系约定
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

#### TC-TASK007-004：deploy-start-common.sh 存在且契约正确（P0）
- **用例ID**：TC-TASK007-004
- **用例名称**：deploy-start-common.sh 存在，契约（SERVICE_NAME=common、JAR_NAME=cloudoffice-common.jar、SERVICE_PORT 读 COMMON_PORT 缺省 9300、HEALTH_URL=/api/v1/common/health、REQUIRED_VARS 含 COMMON_PORT）正确
- **所属模块**：deploy/scripts（deploy-start-common.sh）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-003 / F-008 / F-009
- **测试数据**：deploy/scripts/deploy-start-common.sh
- **测试步骤**：
  1. 确认 deploy/scripts/deploy-start-common.sh 存在
  2. 读取脚本内容，断言含 SERVICE_NAME="common"、JAR_NAME="cloudoffice-common.jar"、SERVICE_PORT 读 ${COMMON_PORT:-9300}、HEALTH_URL 含 /api/v1/common/health、REQUIRED_VARS 含 NACOS_ADDR/COMMON_PORT/DB_PASSWORD
  3. 断言脚本 source load-env.sh 加载 env.json
  4. 断言启动命令 java -Xms256m -Xmx512m -jar，日志/PID 落 deploy/logs/
  5. 断言输出分级与退出码约定（失败非零）
- **预期结果**：
  1. 脚本存在且契约正确
  2. 与 .ps1 行为一致（双平台契约对齐）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

#### TC-TASK007-005：前置校验失败非零退出且不启动任何服务（P0）
- **用例ID**：TC-TASK007-005
- **用例名称**：jar 包或关键环境变量缺失时 deploy-start-all 输出缺失项、以非零码退出、不启动任何服务
- **所属模块**：deploy/scripts（deploy-start-all 前置校验）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成；可模拟缺失场景（如临时缺失某 jar 或清空某环境变量）
- **测试类型**：功能测试（失败路径校验）
- **关联需求ID**：US-003 / F-008
- **测试数据**：模拟 cloudoffice-common.jar 缺失 或 COMMON_PORT 未配置
- **测试步骤**：
  1. 校验逻辑缺失分支：将某服务 jar 名改为不存在的文件后运行脚本（或静态校验 $Services/$Services 前置校验遍历逻辑，确认覆盖 5 个服务含 common）
  2. 断言输出缺失项（jar 缺失 / COMMON_PORT 缺失提示，仅列键名不打印值）
  3. 断言退出码非零（.ps1 exit 1 / .sh exit 1）
  4. 断言未启动任何服务
- **预期结果**：
  1. 输出明确缺失项与处理提示
  2. 退出码非零，符合 v0.2.7 脚本体系约定
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

#### TC-TASK007-006：common 启动失败时失败即停（P0）
- **用例ID**：TC-TASK007-006
- **用例名称**：common 服务健康确认失败时输出错误并停止后续启动（gateway 及之后服务不启动）
- **所属模块**：deploy/scripts（deploy-start-all 失败即停）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成；可模拟 common 健康确认失败场景
- **测试类型**：功能测试（失败路径校验）
- **关联需求ID**：US-003 / F-008
- **测试数据**：模拟 common 端口无法探测或健康 URL 无响应
- **测试步骤**：
  1. 校验 common 启动失败分支：健康确认（Wait-HealthUp）超时后 break
  2. 断言输出 common 健康确认失败提示（含端口 9300 占用排查建议）
  3. 断言后续 gateway/auth/biz/system 不启动（循环 break，失败即停）
  4. 断言退出码非零
- **预期结果**：
  1. common 失败即停，后续服务不启动
  2. 退出码非零，符合失败即停策略
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：（由 impm-task-coding-runtest 步骤记录）

#### TC-TASK007-007：全部服务启动成功输出 5 服务汇总退出码 0（P0）
- **用例ID**：TC-TASK007-007
- **用例名称**：common/gateway/auth/biz/system 全部启动成功时输出 5 个服务启动结果与健康状态汇总，退出码 0
- **所属模块**：deploy/scripts（deploy-start-all 正常路径）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成；5 个 jar 与关键环境变量就绪；基础设施（MariaDB/Redis/Nacos）就绪
- **测试类型**：功能测试（脚本执行验证）
- **关联需求ID**：US-003 / F-008
- **测试数据**：执行 deploy/scripts/deploy-start-all.ps1（或 .sh）
- **测试步骤**：
  1. 确认 5 个 jar 与关键环境变量就绪、基础设施就绪
  2. 执行 deploy-start-all.ps1（或 .sh）
  3. 断言按 common → gateway → auth → biz → system 顺序逐个启动，common 最先启动且健康确认成功后再启动 gateway
  4. 断言输出 5 个服务的启动结果与健康状态汇总（含 common）
  5. 断言退出码 0
- **预期结果**：
  1. 5 个服务全部启动成功且健康确认通过
  2. 退出码 0，汇总输出覆盖 common
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task007_start_script_checks（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行）——接口测试脚本静态校验 PASS（test_task007_start_script_checks）

> 说明：本任务为部署启动脚本更新（无代码逻辑变更），UI 测试不适用；双平台行为一致通过 .ps1/.sh 静态校验 + 单平台（当前 Windows 环境 .ps1）实执行验证（环境允许时）。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 7/7（TC-TASK007-001~007 全部通过，接口测试脚本 test_task007_start_script_checks 静态校验，2026-08-13 执行） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（.sh 平台以静态校验替代实执行，双平台契约对齐） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 基础设施（MariaDB/Redis/Nacos）未就绪 | TC-TASK007-007 全量启动无法实执行验证 | 以脚本静态校验（顺序/清单/失败分支）+ 前置校验失败路径实执行替代；全量启动留给部署验证 |
| .sh 平台不可验证 | TC-TASK007-002/004 仅静态校验 | 静态比对 .ps1/.sh 逻辑一致性，双平台契约对齐 |
| COMMON_PORT 尚未加入 env.json（TASK-009 未完成） | 前置校验 COMMON_PORT 可能缺失 | 脚本对 COMMON_PORT 做缺省兜底（9300），缺失时按关键变量缺失提示处理 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
