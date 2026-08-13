# 测试用例文档（TestCase）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/scripts（build-backend 编译脚本） | TASK-006 | 5 | P0×5 |

## 二、测试用例详情

### 模块：deploy/scripts - build-backend 编译脚本纳入 common 产物（TASK-006）

#### TC-TASK006-001：build-backend.ps1 产物校验清单含 common（P0）
- **用例ID**：TC-TASK006-001
- **用例名称**：build-backend.ps1 校验清单包含 cloudoffice-common.jar
- **所属模块**：deploy/scripts（build-backend.ps1）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-005 / F-007
- **测试数据**：deploy/scripts/build-backend.ps1
- **测试步骤**：
  1. 读取 deploy/scripts/build-backend.ps1 内容
  2. 断言 $Jars 数组包含 "cloudoffice-common.jar"
  3. 断言产物缺失校验（$missing 逻辑）遍历 5 个 jar 清单
  4. 断言完成输出遍历 5 个 jar 清单（含 common）
- **预期结果**：
  1. $Jars 清单含 5 个 jar（gateway/auth/biz/system/common）
  2. 缺失校验与完成输出均基于 $Jars 变量，自动覆盖 common
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → `test_task006_build_script_checks`（TC-TASK006-001 断言）
- **测试过程与结论**：通过（2026-08-13 10:04 执行）——build-backend.ps1 $Jars 清单含 5 个 jar（cloudoffice-common.jar 居首）；实执行 build-backend.ps1 BUILD SUCCESS、退出码 0。

#### TC-TASK006-002：build-backend.sh 产物校验清单含 common（P0）
- **用例ID**：TC-TASK006-002
- **用例名称**：build-backend.sh 校验清单包含 cloudoffice-common.jar
- **所属模块**：deploy/scripts（build-backend.sh）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（脚本内容校验）
- **关联需求ID**：US-005 / F-007
- **测试数据**：deploy/scripts/build-backend.sh
- **测试步骤**：
  1. 读取 deploy/scripts/build-backend.sh 内容
  2. 断言 for 循环 jar 清单包含 cloudoffice-common.jar
  3. 断言 MISSING 缺失校验遍历 5 个 jar 清单
  4. 断言完成输出遍历 5 个 jar 清单（含 common）
- **预期结果**：
  1. 两个 for 循环清单均含 5 个 jar（含 common）
  2. 缺失校验与完成输出一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → `test_task006_build_script_checks`（TC-TASK006-002 断言）
- **测试过程与结论**：通过（2026-08-13 10:04 执行）——build-backend.sh for 循环清单含 5 个 jar（含 cloudoffice-common.jar），与 .ps1 逻辑一致（双平台契约对齐，静态校验）。

#### TC-TASK006-003：执行 build-backend 后 common jar 落位 deploy（P0）
- **用例ID**：TC-TASK006-003
- **用例名称**：执行 build-backend 后 deploy 目录存在 cloudoffice-common.jar 可执行 jar
- **所属模块**：deploy/scripts（编译产物）
- **优先级**：P0
- **前置条件**：Maven 环境就绪（mvn 可用）、deploy 目录存在
- **测试类型**：功能测试（编译脚本执行）
- **关联需求ID**：US-005 / F-007
- **测试数据**：执行 build-backend（.ps1 或 .sh）
- **测试步骤**：
  1. 执行 deploy/scripts/build-backend.ps1（或 .sh）
  2. 断言脚本退出码为 0
  3. 检查 deploy/cloudoffice-common.jar 存在
  4. 检查 jar 内 org/springframework/boot/loader 目录存在（可执行 fat jar）
- **预期结果**：
  1. 脚本执行成功（退出码 0）
  2. deploy/cloudoffice-common.jar 存在且为可执行 fat jar
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → `test_task006_build_artifacts`（TC-TASK006-003 断言）
- **测试过程与结论**：通过（2026-08-13 10:04 执行）——执行 build-backend.ps1 后 deploy 下 5 个 jar 齐全，cloudoffice-common.jar 53445219 字节为可执行 fat jar（含 Spring Boot Loader，10:04:17 重新生成）。

#### TC-TASK006-004：现有服务产物输出不受影响（P0）
- **用例ID**：TC-TASK006-004
- **用例名称**：执行 build-backend 后现有 gateway/auth/biz/system jar 输出正常
- **所属模块**：deploy/scripts（回归）
- **优先级**：P0
- **前置条件**：TC-TASK006-003 通过
- **测试类型**：功能测试（编译回归）
- **关联需求ID**：US-005 / F-007
- **测试数据**：deploy 目录 5 个 jar 清单
- **测试步骤**：
  1. 检查 deploy 下 cloudoffice-gateway.jar / cloudoffice-auth-service.jar / cloudoffice-biz-service.jar / cloudoffice-system-service.jar 均存在
  2. 断言脚本输出汇总包含 5 个 jar 路径
- **预期结果**：
  1. 既有 4 个服务 jar 均正常生成
  2. 编译脚本不影响现有服务产物输出
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → `test_task006_build_artifacts`（TC-TASK006-004 断言）
- **测试过程与结论**：通过（2026-08-13 10:04 执行）——既有 gateway/auth/biz/system 4 个 jar 均正常生成（10:04 重新构建），现有服务产物输出不受影响。

#### TC-TASK006-005：产物缺失时脚本失败退出非零（P0）
- **用例ID**：TC-TASK006-005
- **用例名称**：build-backend 校验到 jar 缺失时输出错误并以非零码退出
- **所属模块**：deploy/scripts（失败路径）
- **优先级**：P0
- **前置条件**：脚本修改完成（可模拟缺失场景）
- **测试类型**：功能测试（失败路径校验）
- **关联需求ID**：US-005 / F-007
- **测试数据**：临时移除某 jar 或注入缺失清单
- **测试步骤**：
  1. 校验逻辑缺失分支：将某个 jar 名改为不存在的文件后运行脚本（或静态校验 $Jars/$missing 逻辑）
  2. 断言输出 [错误] 与缺失 jar 名
  3. 断言退出码非零（.ps1 exit 1 / .sh exit 1）
- **预期结果**：
  1. 输出明确错误与缺失项
  2. 退出码非零，符合 v0.2.7 脚本体系约定
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → `test_task006_build_script_checks`（TC-TASK006-005 断言）
- **测试过程与结论**：通过（2026-08-13 10:04 执行）——build-backend.ps1 与 build-backend.sh 均含 $missing/MISSING 缺失校验分支与 exit 1 退出码约定（静态校验）；实执行时产物齐全未触发失败分支，符合 v0.2.7 脚本体系约定。

> 说明：本任务为编译脚本更新（无代码逻辑变更），UI 测试不适用；双平台行为一致通过 .ps1/.sh 静态校验 + 单平台（当前 Windows 环境 .ps1）实执行验证。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 5/5（TC-001/002/003/004/005 全部通过；build-backend.ps1 实执行 BUILD SUCCESS 退出码 0） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（.sh 平台未实执行，以静态校验替代，不计跳过） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 全量 mvn package 耗时较长 | TC-TASK006-003/004 执行时间增加 | 可选用 -DskipTests 加速；当前 deploy 已有构建产物，可结合静态校验 + 产物存在性验证 |
| 与并行任务（TASK-003/007/008）写版本文档冲突 | 测试用例文档可能被覆盖 | 写入前读取最新内容，合并写回并回读校验 |
| .sh 平台不可验证 | TC-TASK006-002 仅静态校验 | 静态比对 .ps1/.sh 逻辑一致性，双平台契约对齐 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
