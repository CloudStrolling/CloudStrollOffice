# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/（env.json / env.example.json 新增 COMMON_PORT） | TASK-009 | 6 | P0×6 |

## 二、测试用例详情
### 模块：deploy - 环境配置更新（TASK-009）

#### TC-TASK009-001：env.example.json 新增 COMMON_PORT 且示例值正确（P0）
- **用例ID**：TC-TASK009-001
- **用例名称**：env.example.json（入库模板）新增 COMMON_PORT 键，示例值正确
- **所属模块**：deploy/env.example.json
- **优先级**：P0
- **前置条件**：TASK-009 编码完成，env.example.json 已更新
- **测试类型**：功能测试（配置校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：解析 deploy/env.example.json
- **测试步骤**：
  1. 解析 deploy/env.example.json，断言 JSON 合法
  2. 断言存在 COMMON_PORT 键
  3. 断言 COMMON_PORT 值合法（数字字符串，如 "9300"）
- **预期结果**：
  1. JSON 解析成功，无语法错误
  2. COMMON_PORT 存在且示例值正确
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

#### TC-TASK009-002：env.json 新增 COMMON_PORT 且实际值正确（P0）
- **用例ID**：TC-TASK009-002
- **用例名称**：env.json（实际配置）新增 COMMON_PORT 键，实际值正确
- **所属模块**：deploy/env.json
- **优先级**：P0
- **前置条件**：TASK-009 编码完成，env.json 已更新
- **测试类型**：功能测试（配置校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：解析 deploy/env.json
- **测试步骤**：
  1. 解析 deploy/env.json，断言 JSON 合法
  2. 断言存在 COMMON_PORT 键
  3. 断言 COMMON_PORT 值与实际端口（9300）一致
- **预期结果**：
  1. JSON 解析成功，无语法错误
  2. COMMON_PORT 存在且实际值正确
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

#### TC-TASK009-003：现有 gateway/auth/biz/system 配置项不受影响（P0）
- **用例ID**：TC-TASK009-003
- **用例名称**：env.json 与 env.example.json 新增 COMMON_PORT 后，现有配置项完整保留
- **所属模块**：deploy/env.json、deploy/env.example.json
- **优先级**：P0
- **前置条件**：TASK-009 编码完成
- **测试类型**：功能测试（配置校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：对比更新前后键集合
- **测试步骤**：
  1. 解析 env.json，断言原有关键键存在（NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY 等）
  2. 解析 env.example.json，断言原有关键键存在（同上）
  3. 断言仅新增 COMMON_PORT，未删除/改名任何既有键
- **预期结果**：
  1. 现有全部配置键完整保留
  2. 仅新增 COMMON_PORT 键，值不影响其他键
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

#### TC-TASK009-004：env.json 与 env.example.json 键集合一致（P0）
- **用例ID**：TC-TASK009-004
- **用例名称**：env.json 与 env.example.json 键集合一致，便于复制模板后直接使用
- **所属模块**：deploy/env.json、deploy/env.example.json
- **优先级**：P0
- **前置条件**：TASK-009 编码完成
- **测试类型**：功能测试（配置校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：比较两文件键集合
- **测试步骤**：
  1. 解析 env.json 与 env.example.json，获取两文件键集合
  2. 断言两文件键集合一致（均为新增 COMMON_PORT 后的完整键集）
- **预期结果**：
  1. 两文件键集合一致，env.example.json 可作为 env.json 模板
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

#### TC-TASK009-005：COMMON_PORT 符合 load-env 键名白名单（P0）
- **用例ID**：TC-TASK009-005
- **用例名称**：COMMON_PORT 键名符合 load-env 键名合法性白名单规则
- **所属模块**：deploy/scripts/load-env
- **优先级**：P0
- **前置条件**：TASK-009 编码完成
- **测试类型**：功能测试（配置校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：键名 "COMMON_PORT"
- **测试步骤**：
  1. 用正则 `^[A-Za-z_][A-Za-z0-9_]*$` 校验 "COMMON_PORT"
  2. 断言匹配，load-env 键名合法性校验通过
- **预期结果**：
  1. COMMON_PORT 符合白名单正则，load-env 加载不报非法键名
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

#### TC-TASK009-006：env.json 不入库、env.example.json 入库策略保持（P0）
- **用例ID**：TC-TASK009-006
- **用例名称**：env.json 保持不入库（.gitignore 排除），env.example.json 可入库
- **所属模块**：.gitignore / deploy/
- **优先级**：P0
- **前置条件**：TASK-009 编码完成
- **测试类型**：功能测试（仓库策略校验）
- **关联需求ID**：US-003 / F-012
- **测试数据**：git check-ignore deploy/env.json；git check-ignore deploy/env.example.json
- **测试步骤**：
  1. 执行 `git check-ignore deploy/env.json`，断言退出码 0（被忽略）
  2. 执行 `git check-ignore deploy/env.example.json`，断言退出码非 0（未被忽略，可入库）
- **预期结果**：
  1. env.json 被 git 忽略（不入库）
  2. env.example.json 未被忽略（可入库）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.8.py → test_task009_env_config_checks
- **测试过程与结论**：通过（2026-08-13 11:11 执行接口测试脚本 test_task009_env_config_checks，PASS）

> 说明：本任务为环境配置文件更新（无代码逻辑变更），单元测试/接口测试/UI 测试不适用；以功能测试（配置校验 + git 仓库策略校验）覆盖。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 6（TC-TASK009-001/002/003/004/005/006 全部通过，接口脚本 test_task009_env_config_checks 执行，2026-08-13） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| env.json 为本地实际配置文件（不入库） | 编码仅修改工作区文件，提交时可能遗漏 | 编码步骤直接修改文件，测试读取工作区最新内容；git 提交仅提交 env.example.json |
| 与并行任务写版本文档冲突 | 测试用例文档可能被覆盖 | 写入前读取最新内容，合并写回并回读校验 |

## 五、签名确认
- 测试工程师（TE）：
- 项目经理（PM）：
