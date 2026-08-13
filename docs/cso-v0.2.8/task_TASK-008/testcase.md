# 测试用例文档（TestCase）TASK-008
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/scripts（deploy-stop-all 停止脚本） | TASK-008 | 3 | P0×3 |
| deploy/scripts（deploy-stop-common 单服务停止脚本） | TASK-008 | 3 | P0×3 |

## 二、测试用例详情

### 模块：deploy/scripts - deploy-stop-all 停止脚本更新（TASK-008）

#### TC-TASK008-001：deploy-stop-all.ps1 服务清单含 common 且居末（P0）
- **用例ID**：TC-TASK008-001
- **用例名称**：deploy-stop-all.ps1 服务停止顺序为 system → biz → auth → gateway → common（common 最后停止）
- **所属模块**：deploy/scripts（deploy-stop-all.ps1）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-004 / F-009
- **测试数据**：deploy/scripts/deploy-stop-all.ps1
- **测试步骤**：
  1. 读取 deploy/scripts/deploy-stop-all.ps1 内容
  2. 断言 $Services 数组含 5 项：system(9400)/biz(9200)/auth(9100)/gateway(9000)/common(9300)
  3. 断言 common 位于数组最后一位（Jar=cloudoffice-common.jar，Port=9300）
  4. 断言汇总输出（结尾各服务停止结果遍历）覆盖 common
- **预期结果**：
  1. $Services 含 5 个后端服务，common 在最后
  2. 汇总输出含 common 停止结果
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本静态校验）：deploy-stop-all.ps1 服务清单含 5 项，common(Jar=cloudoffice-common.jar,Port=9300) 位于最后一位，汇总输出自动覆盖 common

#### TC-TASK008-002：deploy-stop-all.sh 服务清单含 common 且居末（P0）
- **用例ID**：TC-TASK008-002
- **用例名称**：deploy-stop-all.sh 服务停止顺序为 system → biz → auth → gateway → common（common 最后停止）
- **所属模块**：deploy/scripts（deploy-stop-all.sh）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-004 / F-009
- **测试数据**：deploy/scripts/deploy-stop-all.sh
- **测试步骤**：
  1. 读取 deploy/scripts/deploy-stop-all.sh 内容
  2. 断言 SERVICES 数组含 5 项（system|...|9400、biz|...|9200、auth|...|9100、gateway|...|9000、common|cloudoffice-common.jar|9300）
  3. 断言 common 位于数组最后一位
  4. 断言汇总输出（结尾各服务停止结果遍历）覆盖 common
- **预期结果**：
  1. SERVICES 含 5 个后端服务，common 在最后
  2. 汇总输出含 common 停止结果
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本静态校验）：deploy-stop-all.sh SERVICES 含 5 项（common|cloudoffice-common.jar|9300），common 位于最后一位，与 .ps1 契约对齐

#### TC-TASK008-003：deploy-stop-all 未运行服务幂等跳过且不影响其他服务（P0）
- **用例ID**：TC-TASK008-003
- **用例名称**：某服务进程不存在时跳过并输出"未运行"提示，不影响其他服务停止，全部未运行时退出码 0
- **所属模块**：deploy/scripts（deploy-stop-all）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成；当前环境无任何后端 java 服务运行（或指定测试环境）
- **测试类型**：功能测试（脚本执行验证）
- **关联需求ID**：US-004 / F-009
- **测试数据**：执行 deploy/scripts/deploy-stop-all.ps1（或 .sh）
- **测试步骤**：
  1. 确认当前无后端 java 服务进程运行
  2. 执行 deploy-stop-all.ps1（或 .sh）
  3. 断言输出 5 个服务（含 common）均显示"未在运行（PID 文件/进程均未命中），幂等跳过"（通过）
  4. 断言退出码为 0（全部通过）
- **预期结果**：
  1. 5 个服务均幂等通过，无失败项
  2. 退出码 0
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本实执行）：当前无后端 java 服务运行时执行 deploy-stop-all.ps1，5 个服务均输出'未在运行（PID 文件/进程均未命中），幂等跳过'（通过），退出码 0

### 模块：deploy/scripts - deploy-stop-common 单服务停止脚本（TASK-008）

#### TC-TASK008-004：deploy-stop-common.ps1 存在且契约正确（P0）
- **用例ID**：TC-TASK008-004
- **用例名称**：deploy-stop-common.ps1 存在，契约（ServiceName=common、Jar=cloudoffice-common.jar、Port=9300）正确
- **所属模块**：deploy/scripts（deploy-stop-common.ps1）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-004 / F-009
- **测试数据**：deploy/scripts/deploy-stop-common.ps1
- **测试步骤**：
  1. 确认 deploy/scripts/deploy-stop-common.ps1 存在
  2. 读取脚本内容，断言含 $ServiceName="common"、$JarName="cloudoffice-common.jar"、$ServicePort=9300
  3. 断言脚本经 load-env.ps1 加载 env.json
  4. 断言含按 PID 文件/命令行校验 + 回退按 jar 名定位 + 幂等跳过逻辑
  5. 断言输出分级（通过/警告/失败）与退出码约定（失败非零）
- **预期结果**：
  1. 脚本存在且契约正确
  2. 遵循 v0.2.7 脚本体系约定
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本静态校验）：deploy-stop-common.ps1 存在且契约正确（common/cloudoffice-common.jar/9300/load-env/幂等跳过/退出码约定）

#### TC-TASK008-005：deploy-stop-common.sh 存在且契约正确（P0）
- **用例ID**：TC-TASK008-005
- **用例名称**：deploy-stop-common.sh 存在，契约（SERVICE_NAME=common、JAR_NAME=cloudoffice-common.jar、SERVICE_PORT=9300）正确
- **所属模块**：deploy/scripts（deploy-stop-common.sh）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-004 / F-009
- **测试数据**：deploy/scripts/deploy-stop-common.sh
- **测试步骤**：
  1. 确认 deploy/scripts/deploy-stop-common.sh 存在
  2. 读取脚本内容，断言含 SERVICE_NAME="common"、JAR_NAME="cloudoffice-common.jar"、SERVICE_PORT=9300
  3. 断言脚本 source load-env.sh 加载 env.json
  4. 断言含按 PID 文件/命令行校验 + 回退按 jar 名定位 + 幂等跳过逻辑
  5. 断言输出分级与退出码约定（失败非零）
- **预期结果**：
  1. 脚本存在且契约正确
  2. 与 .ps1 行为一致（双平台契约对齐）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本静态校验）：deploy-stop-common.sh 存在且契约与 .ps1 对齐（SERVICE_NAME=common/JAR_NAME=cloudoffice-common.jar/SERVICE_PORT=9300/source load-env.sh/幂等跳过/退出码约定）

#### TC-TASK008-006：deploy-stop-common 停止运行中进程并输出汇总（P0）
- **用例ID**：TC-TASK008-006
- **用例名称**：common 进程运行时执行 deploy-stop-common 能按 PID/进程名停止并输出通过，退出码 0
- **所属模块**：deploy/scripts（deploy-stop-common）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成；测试环境可启动一个模拟 common java 进程（或环境具备真实 common 服务）
- **测试类型**：功能测试（脚本执行验证）
- **关联需求ID**：US-004 / F-009
- **测试数据**：启动 `java -jar` 模拟进程（进程名含 cloudoffice-common.jar 或写入 common.pid），执行 deploy/scripts/deploy-stop-common.ps1（或 .sh）
- **测试步骤**：
  1. 启动一个命令行含 cloudoffice-common.jar 的 java 进程（或写入 common.pid 指向测试进程）
  2. 执行 deploy-stop-common.ps1（或 .sh）
  3. 断言输出"通过"，进程已停止
  4. 断言退出码 0
- **预期结果**：
  1. 进程被成功停止（PID 文件/命令行定位）
  2. 输出通过分级，退出码 0
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task008_stop_script_checks / test_task008_stop_script_execute（对应用例见函数内报告分支）
- **测试过程与结论**：通过（2026-08-13 执行，接口测试脚本实执行）：启动命令行含 cloudoffice-common.jar 的模拟 java 进程并写 common.pid，执行 deploy-stop-common.ps1，进程按 PID 文件定位被停止、输出'已停止'通过、退出码 0

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 6（TC-TASK008-001/002/003/004/005/006，2026-08-13 执行，接口测试脚本 test_task008_stop_script_checks / test_task008_stop_script_execute） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（.sh 平台以静态校验替代实执行，双平台契约对齐，不另计跳过） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 与并行任务（TASK-004/007/009）写版本文档冲突 | 测试用例文档可能被覆盖 | 写入前读取最新内容，合并写回并回读校验 |
| .sh 平台当前 Windows 环境不可直接执行 | TC-TASK008-002/005 仅静态校验 | 静态比对 .ps1/.sh 逻辑一致性，双平台契约对齐 |
| 环境无运行中的服务 | TC-TASK008-003/006 执行验证受限 | TC-003 以全未运行幂等场景执行；TC-006 以模拟进程方式验证停止逻辑 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：

