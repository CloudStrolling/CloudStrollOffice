# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

**任务编号**：TASK-002
**任务名称**：实现 load-env.ps1 / load-env.sh 统一配置加载模块
**任务定义**：实现 load-env.ps1 / load-env.sh 统一配置加载模块（F-001 / US-001 / ADR-016）。测试方法：PowerShell 语法解析 + Bash 语法校验（bash -n）；env.json 存在/缺失/关键配置缺失三场景行为验证与退出码核对。

> 用例编号延续主文档空间（v0.2.6 末：TC-076、UT-131、FT-068、UIT-016；TASK-001 已用 TC-077~079、UT-132~143、FT-069~072、UIT-017），本任务新用例从 **TC-080、UT-144、FT-073、UIT-018** 起编号。
> 接口契约以 docs/cso-api.md 与当前代码实现为准；自动化测试函数/脚本位置由 impm-task-coding-writetest 步骤标注，测试过程与结论由 runtest 步骤记录。
> 本任务用例明细同步并入 `docs/cso-v0.2.7/cso-testcase-v0.2.7.md`。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| load-env 统一配置加载模块（F-001 / US-001 / ADR-016）：TASK-002 | TASK-002 | 16 | P0×8、P1×7、P2×1 |
| 其中：单元测试（.ps1 语法解析、.sh bash -n、路径/注入基线保留、SPDX 头、无硬编码地址凭据、关键配置缺失校验静态核对、source 语义、敏感值不打印） | TASK-002 | 8 | P0×5、P1×3 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-002 | 2 | P1×1、P2×1 |
| 其中：功能测试（env.json 存在/缺失/关键配置缺失三场景行为验证与退出码核对、非法 JSON 边界、双平台一致性） | TASK-002 | 5 | P0×3、P1×2 |
| 其中：UI 测试（无 UI 变更确认） | TASK-002 | 1 | P1×1 |

## 二、测试用例详情

### 模块：load-env 统一配置加载 - 单元测试（语法解析与静态核对）
#### UT-144：load-env.ps1 语法可解析性（P0）
- **用例ID**：UT-144
- **用例名称**：用 [System.Management.Automation.Language.Parser]::ParseFile 解析 deploy/scripts/load-env.ps1，确认无任何语法错误（PowerShell 5.1 兼容）
- **所属模块**：deploy/scripts / load-env.ps1 语法
- **优先级**：P0
- **前置条件**：TASK-002 编码完成，load-env.ps1 已按契约更新
- **测试类型**：单元测试（语法解析）
- **关联需求ID**：US-001 / F-001 / R-01
- **测试数据**：`deploy/scripts/load-env.ps1`
- **测试步骤**：
  1. 调用 `[System.Management.Automation.Language.Parser]::ParseFile` 解析 load-env.ps1，收集 $errors
  2. 检查 errors 集合是否为空；若存在错误，逐条输出错误消息与位置
- **预期结果**：
  1. errors 为空，语法解析通过，无任何语法错误
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-144-1，已落地）
- **测试过程与结论**：2026-08-10 执行 cso-unit-test-load-env-v0.2.7.ps1，UT-144-1 结果 [PASS]：ParseFile 解析 load-env.ps1 无任何语法错误（errors 为空，PS 5.1 兼容）。**通过**

#### UT-145：load-env.sh 语法校验（bash -n）（P0）
- **用例ID**：UT-145
- **用例名称**：对 deploy/scripts/load-env.sh 执行 `bash -n` 语法校验通过（退出码 0、无输出）；环境无 bash 时降级为 shebang + 文件非空 + 关键结构（if/function 配对）核对
- **所属模块**：deploy/scripts / load-env.sh 语法
- **优先级**：P0
- **前置条件**：TASK-002 编码完成，load-env.sh 已按契约更新
- **测试类型**：单元测试（语法校验）
- **关联需求ID**：US-001 / F-001 / R-01
- **测试数据**：`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. 执行 `bash -n deploy/scripts/load-env.sh`，检查退出码与输出
  2. 无 bash 环境时：核对 shebang（`#!/usr/bin/env bash`）、文件非空、`if [ ! -f ... ]` 与 `fi` 配对、函数/变量引用闭合
- **预期结果**：
  1. bash -n 通过（退出码 0、无输出）；降级核对时 shebang 与结构合格
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-145-1，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-145-1 结果 [PASS]：本机无 bash/WSL（HCS_E_HYPERV_NOT_INSTALLED），自动走降级核对分支——shebang 存在、文件非空、if/fi 配对、含 return 1，结构合格（bash -n 动态校验留待有 bash 环境时补充，见 FT-077 环境 SKIP 说明）。**通过（降级路径）**

#### UT-146：load-env 路径推导与注入基线保留（UT-078 契约不破坏）（P0）
- **用例ID**：UT-146
- **用例名称**：静态核对 load-env.ps1 保留 `$PSScriptRoot`、`$ProjectDir = Split-Path -Parent $PSScriptRoot`、`Join-Path $ProjectDir $EnvFile` 与 `ConvertFrom-Json` + `PSObject.Properties` + `Set-Item env:` 注入；load-env.sh 保留 `${BASH_SOURCE[0]}`、`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`、`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"` 与 jq `to_entries @sh` / python3 `shlex.quote` 注入（UT-078-1/2 契约，重构不得破坏）
- **所属模块**：deploy/scripts / load-env 基线契约
- **优先级**：P0
- **前置条件**：load-env.ps1 / load-env.sh 已更新
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-001 / UT-078 基线
- **测试数据**：`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. grep load-env.ps1 中的 `PSScriptRoot`、`Split-Path -Parent $PSScriptRoot`、`Join-Path $ProjectDir $EnvFile`
  2. grep load-env.sh 中的 `BASH_SOURCE[0]`、`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`、`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"`
  3. 核对注入机制：.ps1 用 ConvertFrom-Json + PSObject.Properties + Set-Item Env:；.sh 用 jq to_entries @sh 或 python3 shlex.quote 生成 export 并 eval
- **预期结果**：
  1. 三处路径推导与两种注入模式均保留，与 UT-078 契约一致，未破坏基线
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-146-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-146-1/2 结果 [PASS]×2：.ps1 保留 PSScriptRoot/Split-Path/Join-Path/ConvertFrom-Json/PSObject.Properties/Set-Item env: 注入；.sh 保留 BASH_SOURCE[0]/PROJECT_DIR/ENV_FILE_PATH/jq to_entries @sh/python shlex.quote 注入，UT-078 契约未破坏。**通过**

#### UT-147：load-env 文件头 SPDX 版权头与简体中文注释（P1）
- **用例ID**：UT-147
- **用例名称**：load-env.ps1 与 load-env.sh 文件头均保留 `SPDX-License-Identifier: Apache-2.0` 与版权声明（Copyright 2026 jenemy8023），注释使用简体中文，注明脚本用途与敏感值不打印说明
- **所属模块**：deploy/scripts / 文件头规范
- **优先级**：P1
- **前置条件**：load-env.ps1 / load-env.sh 已更新
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-001 / project.md 编码规范
- **测试数据**：`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. 读取两文件头 5 行，核对 SPDX-License-Identifier: Apache-2.0 与 Copyright 2026 版权声明
  2. 核对正文注释为简体中文，且含「口令/密钥不打印」类敏感值处理说明
- **预期结果**：
  1. 两文件均含 SPDX 头与版权声明；注释为简体中文；有敏感值不打印说明
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-147-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-147-1/2 结果 [PASS]×2：两文件均含 SPDX-License-Identifier: Apache-2.0 与 Copyright 2026 jenemy8023；正文注释含简体中文与敏感值不打印说明。**通过**

#### UT-148：load-env 无硬编码地址与凭据（P0，安全）
- **用例ID**：UT-148
- **用例名称**：grep load-env.ps1 / load-env.sh，确认无 `192.168.1.x` 等硬编码环境地址，无明文口令/密钥字面量（DB_PASSWORD/RSA_PRIVATE_KEY 等敏感值不得以字面量出现在脚本内，全部经环境变量引用）
- **所属模块**：deploy/scripts / 硬编码地址与凭据
- **优先级**：P0
- **前置条件**：load-env.ps1 / load-env.sh 已更新
- **测试类型**：单元测试（静态核对/grep，安全）
- **关联需求ID**：US-001 / F-001 / F-010
- **测试数据**：`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. grep `192\.168\.`、`10\.0\.`、`172\.` 于两文件，确认无硬编码地址
  2. grep 敏感键名赋值模式（如 `DB_PASSWORD\s*=`、`RSA_PRIVATE_KEY\s*=` 后跟字面量字符串），确认无明文凭据
  3. 核对脚本内地址与凭据均通过 `$env:KEY` / `$KEY` 环境变量引用
- **预期结果**：
  1. 无硬编码地址；无明文口令/密钥字面量；敏感值仅经环境变量引用
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-148-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-148-1/2 结果 [PASS]×2：grep 两文件无 192.168.x/10.0.x/172.16-31.x 硬编码地址；无 DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY/MARIADB_ROOT_PASSWORD 明文赋值字面量，敏感值仅经环境变量引用。**通过**

#### UT-149：load-env 关键配置缺失校验静态核对（P0）
- **用例ID**：UT-149
- **用例名称**：静态核对 load-env.ps1 / load-env.sh 均含 8 项必填关键配置清单（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT，F-001 原文下限），校验逻辑为收集缺失项 → 逐个列出键名 → 退出非零（.ps1 `exit 1` / .sh `return 1`）
- **所属模块**：deploy/scripts / load-env 关键配置校验
- **优先级**：P0
- **前置条件**：load-env.ps1 / load-env.sh 已更新
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-001 / PRD 4.1 业务规则
- **测试数据**：`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. 检查两文件是否定义 8 项必填清单（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）
  2. 检查缺失校验逻辑：收集缺失项集合 → 逐个输出键名（不输出值）→ 退出非零
  3. 检查 .sh 使用 `${!var:-}` 间接参数展开或数组循环；.ps1 使用 `$env:KEY` 存在性检查
- **预期结果**：
  1. 8 项必填清单齐全；缺失项逐个列出键名；退出码非零
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-149-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-149-1/2 结果 [PASS]×2：8 项必填清单两文件齐全；.ps1 含 missingKeys 收集与 exit 1；.sh 含 ${!key:-} 间接展开与 return 1，缺失校验逻辑完整。**通过**

#### UT-150：load-env.sh source 语义与严格模式核对（P1）
- **用例ID**：UT-150
- **用例名称**：静态核对 load-env.sh 为 source 型脚本：env.json 缺失/关键配置缺失/解析失败分支使用 `return 1`（非 `exit`，避免终止父 shell）；文件不含 `set -e`（不污染父 shell 状态，UT-142-2 契约）；load-env.ps1 维持 `exit 1`（dot-source 语义下 F-001 要求退出非零）
- **所属模块**：deploy/scripts / load-env source 语义
- **优先级**：P1
- **前置条件**：load-env.sh / load-env.ps1 已更新
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-001 / UT-142 基线
- **测试数据**：`deploy/scripts/load-env.sh`、`deploy/scripts/load-env.ps1`
- **测试步骤**：
  1. grep load-env.sh 中失败分支使用 `return 1` 而非 `exit`
  2. 检查 load-env.sh 不含 `set -e`（或 `set -Eeuo pipefail` 等严格模式）
  3. 检查 load-env.ps1 缺失/失败分支使用 `exit 1`
- **预期结果**：
  1. .sh 失败用 return 1、无 set -e；.ps1 失败用 exit 1，符合双平台 source/dot-source 语义
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-150-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-150-1/2 结果 [PASS]×2：.sh 可执行行无裸 exit、无 set -e、失败分支用 return 1（source 型，不污染父 shell）；.ps1 失败分支用 exit 1（dot-source 语义）。**通过**

#### UT-151：敏感值不打印核对（P1，安全）
- **用例ID**：UT-151
- **用例名称**：静态核对 load-env.ps1 / load-env.sh 的输出去向不打印 DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY/MARIADB_ROOT_PASSWORD 等敏感值明文：缺失校验仅输出键名；成功摘要仅输出「已加载 N 个环境变量」或非敏感键名；输出语句（Write-Host/echo/printf）不引用敏感变量值
- **所属模块**：deploy/scripts / 敏感值脱敏
- **优先级**：P1
- **前置条件**：load-env.ps1 / load-env.sh 已更新
- **测试类型**：单元测试（静态核对，安全）
- **关联需求ID**：US-001 / F-001 / PRD 安全策略
- **测试数据**：`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. 检查输出语句（Write-Host/echo/printf/Write-Output）参数是否引用敏感变量（`$env:DB_PASSWORD`、`$DB_PASSWORD` 等）
  2. 核对缺失项输出格式仅为键名（如「缺失关键配置: DB_PASSWORD」），不输出值
  3. 核对成功摘要为计数/非敏感键名
- **预期结果**：
  1. 输出路径不打印敏感值明文；缺失项仅输出键名；成功摘要不含敏感值
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（UT-151-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，UT-151-1/2 结果 [PASS]×2：输出语句（Write-*/echo/printf）不引用敏感变量值；缺失项仅输出键名；成功摘要为计数（$count / LOADED_COUNT）不含敏感值。**通过**

### 模块：接口契约 - 接口测试（本任务无接口变更）
#### TC-080：本任务无接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-080
- **用例名称**：v0.2.7 API 设计文档（docs/cso-v0.2.7/cso-api-v0.2.7.md）声明「无新增接口、无接口变更、无接口删除」；git 变更清单无接口层代码文件（无 Controller/DTO/响应体/网关路由改动）；API-001~API-033 契约完整保留（本任务仅实现 load-env 脚本，未触碰接口层）
- **所属模块**：接口契约 / 无变更保障
- **优先级**：P1
- **前置条件**：docs/cso-v0.2.7/cso-api-v0.2.7.md 存在；TASK-002 变更范围已确定
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-001 / AC-5 / API-001~API-033
- **测试数据**：`docs/cso-v0.2.7/cso-api-v0.2.7.md`；git 变更清单（`git diff --name-status` / `git status --porcelain`）
- **测试步骤**：
  1. 核对版本 API 文档声明「无新增接口、无接口变更、无接口删除」
  2. 核对 git 变更清单无接口层文件（controller/、dto/、ApiResult/PageResult、网关路由）
  3. 核对 API-001~API-033 接口清单完整保留
- **预期结果**：
  1. API 文档声明无接口变更；git 变更清单无接口层改动；API-001~033 完整保留
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py（TC-080-1~3，已落地）
- **测试过程与结论**：2026-08-10 执行 cso-api-test-v0.2.7.py，TC-080-1/2/3 结果 [PASS]×3：版本 API 文档声明无新增/变更/删除接口；git 变更清单（git status --short 核对）无接口层代码文件改动（仅 deploy/scripts、docs 文档与 scripts/API-TEST 测试脚本）；API-001~API-033 完整保留。**通过**

#### TC-081：基础设施健康检查端点探活（可选，环境依赖）（P2）
- **用例ID**：TC-081
- **用例名称**：若 auth-service（9100）与网关（9000）已启动，探测 `GET /api/v1/auth/health`（直连 9100 与经网关 9000）返回 HTTP 200 且 ApiResult code=200、data.status=UP，验证本任务 load-env 变更未影响服务运行；服务未启动时按环境阻塞 SKIP 记录，不作为失败
- **所属模块**：接口契约 / 健康检查探活
- **优先级**：P2
- **前置条件**：auth-service 9100 与网关 9000 已启动（若未启动则按环境 SKIP）
- **测试类型**：接口测试（动态探活，环境可选）
- **关联需求ID**：API-012 / SAD 部署架构
- **测试数据**：`http://localhost:9000/api/v1/auth/health`、`http://localhost:9100/api/v1/auth/health`
- **测试步骤**：
  1. 检查 9100/9000 端口是否有服务监听（Test-NetConnection / socket 连接）
  2. 若已启动，GET /api/v1/auth/health 直连与经网关探测，核对响应状态与结构
  3. 若未启动，记录环境阻塞 SKIP（不视为失败）
- **预期结果**：
  1. 服务已启动时：两个地址均返回 HTTP 200，ApiResult code=200、status=UP
  2. 服务未启动时：SKIP 记录，说明环境原因
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py（TC-081-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，TC-081-1/2 结果 [PASS]×2：auth-service（9100）与网关（9000）均在运行中，GET /api/v1/auth/health 直连与经网关均返回 HTTP 200、ApiResult code=200、data.status=UP，本任务 load-env 变更未影响服务运行。**通过**

### 模块：load-env 统一配置加载 - 功能测试（三场景行为验证与退出码核对）
#### FT-073：env.json 存在场景——成功加载全部键值对且退出码 0（P0）
- **用例ID**：FT-073
- **用例名称**：deploy/env.json 存在且配置完整时，PowerShell dot-source load-env.ps1 / Bash source load-env.sh 后，8 项关键环境变量（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）全部注入当前会话且值与 env.json 一致；脚本退出码为 0
- **所属模块**：deploy/scripts / load-env 成功场景
- **优先级**：P0
- **前置条件**：deploy/env.json 存在且含 8 项关键配置（真实环境）；load-env.ps1 / load-env.sh 已更新
- **测试类型**：功能测试（动态验证，环境依赖）
- **关联需求ID**：US-001 / F-001 / AC-1
- **测试数据**：`deploy/env.json`（25 键完整）、`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. PowerShell：`. deploy/scripts/load-env.ps1`；执行后检查 `$?` 为 True、`$env:NACOS_ADDR`/`$env:DB_HOST`/`$env:REDIS_HOST` 等 8 项关键变量非空且值与 env.json 一致
  2. Bash：`source deploy/scripts/load-env.sh`；执行后 `echo $?` 输出 0，检查 `$NACOS_ADDR`/`$DB_HOST` 等 8 项关键变量非空且与 env.json 一致
- **预期结果**：
  1. 两平台退出码均为 0；8 项关键环境变量全部注入，值与原 env.json 一致；输出含「环境变量已从 ... 加载」成功提示
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（FT-073-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，FT-073-1/2 结果 [PASS]×2：deploy/env.json 存在（真实环境 25 键完整），PowerShell 子进程 dot-source load-env.ps1 成功（退出码 0），8 项关键环境变量全部注入非空；成功摘要含「加载 N 项」计数且不打印敏感值。**通过**

#### FT-074：env.json 缺失场景——提示复制 env.example.json 并退出非零（P0）
- **用例ID**：FT-074
- **用例名称**：将 env.json 临时移走（或传入不存在的 EnvFile 参数）后执行 load-env.ps1 / load-env.sh，输出错误提示且文案含「复制 deploy/env.example.json 为 env.json 并填写配置」，退出码非零（.ps1 `exit 1` / .sh `return 1` 后 `$?` 非零）
- **所属模块**：deploy/scripts / load-env 缺失场景
- **优先级**：P0
- **前置条件**：load-env.ps1 / load-env.sh 已更新；可临时控制 env.json 存在性（测试目录或参数）
- **测试类型**：功能测试（动态验证，三场景之一）
- **关联需求ID**：US-001 / F-001 / AC-2 / 边界场景（env.json 缺失）
- **测试数据**：临时目录（无 env.json）或参数 `-EnvFile missing.json` / `load-env.sh missing.json`
- **测试步骤**：
  1. PowerShell：在临时目录（无 env.json）执行 `. deploy/scripts/load-env.ps1`，或执行 `.\load-env.ps1 -EnvFile missing.json`，检查输出与 `$LASTEXITCODE`
  2. Bash：`source deploy/scripts/load-env.sh missing.json`，检查输出与 `$?`
  3. 核对提示文案含「env.example.json」「复制」「填写配置」
- **预期结果**：
  1. 两平台均输出含 env.example.json 指引的错误提示；退出码非零（.ps1 exit 1 / .sh return 1）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（FT-074-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，FT-074-1 结果 [PASS]：PowerShell 传 `-EnvFile missing.json` 输出错误提示且文案含 env.example.json + 复制 + 填写配置，退出码非零（exit 1）。FT-074-2 结果 [SKIP]（环境阻塞）：.sh 动态验证需 bash/WSL，本机不可用（HCS_E_HYPERV_NOT_INSTALLED），静态语义已由 UT-145/150 覆盖。**通过（.sh 侧断言环境 SKIP，不作为失败）**

#### FT-075：关键配置缺失场景——逐个列出缺失项并退出非零（P0）
- **用例ID**：FT-075
- **用例名称**：构造缺失部分关键项的临时 env.json（如删除 DB_PASSWORD、REDIS_HOST、NACOS_ADDR 三项）后执行 load-env.ps1 / load-env.sh，输出逐个列出缺失键名（DB_PASSWORD/REDIS_HOST/NACOS_ADDR），不输出缺失项值，退出码非零
- **所属模块**：deploy/scripts / load-env 关键配置缺失场景
- **优先级**：P0
- **前置条件**：load-env.ps1 / load-env.sh 已更新；可构造临时 env.json
- **测试类型**：功能测试（动态验证，三场景之一）
- **关联需求ID**：US-001 / F-001 / AC-2 / 边界场景（关键配置缺失）
- **测试数据**：临时 env.json（仅含部分键，缺失 NACOS_ADDR/DB_PASSWORD/REDIS_HOST）
- **测试步骤**：
  1. 创建临时 env.json（含 NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/REDIS_PORT，缺失 NACOS_ADDR/DB_PASSWORD/REDIS_HOST）
  2. PowerShell：`. deploy/scripts/load-env.ps1 -EnvFile <临时env.json>`，检查输出与退出码
  3. Bash：`source deploy/scripts/load-env.sh <临时env.json>`，检查输出与 `$?`
  4. 核对输出逐个列出 NACOS_ADDR/DB_PASSWORD/REDIS_HOST 三个键名且不含其值
- **预期结果**：
  1. 两平台均逐个列出缺失键名（NACOS_ADDR/DB_PASSWORD/REDIS_HOST）；不输出缺失项值；退出码非零
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（FT-075-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，FT-075-1 结果 [PASS]：构造临时 env.json（缺失 NACOS_ADDR/DB_PASSWORD/REDIS_HOST 三项）后 PowerShell 执行，输出逐个列出三个缺失键名且不含值，退出码非零（exit 1）。FT-075-2 结果 [SKIP]（环境阻塞）：.sh 动态验证需 bash/WSL，本机不可用，不作为失败。**通过（.sh 侧断言环境 SKIP）**

#### FT-076：env.json 非法 JSON 场景（边界）（P1）
- **用例ID**：FT-076
- **用例名称**：env.json 内容为非法 JSON（如缺少逗号/花括号不闭合）时，load-env.ps1 / load-env.sh 输出解析失败错误提示并退出非零（.ps1 try/catch `Write-Error` + `exit 1`；.sh 解析命令失败 + `return 1`），不产生部分注入的脏环境
- **所属模块**：deploy/scripts / load-env 非法 JSON 边界
- **优先级**：P1
- **前置条件**：load-env.ps1 / load-env.sh 已更新；可构造非法 JSON 临时文件
- **测试类型**：功能测试（动态验证，边界）
- **关联需求ID**：US-001 / F-001 / 边界与错误处理
- **测试数据**：临时非法 JSON 文件（如 `{ "NACOS_ADDR": "127.0.0.1:8848", ` 缺右花括号）
- **测试步骤**：
  1. 构造非法 JSON 临时文件（含 1-2 个关键键但语法不闭合）
  2. PowerShell：执行 load-env.ps1（-EnvFile 指向临时文件），检查输出与退出码
  3. Bash：执行 load-env.sh（参数指向临时文件），检查输出与 `$?`
- **预期结果**：
  1. 两平台均输出解析失败提示（.ps1 走 catch / .sh 走解析失败分支）；退出码非零
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（FT-076-1~2，已落地）
- **测试过程与结论**：2026-08-10 执行，FT-076-1 结果 [PASS]：构造缺右花括号的非法 JSON 临时文件后 PowerShell 执行，输出解析失败提示，退出码非零（exit 1），无部分注入脏环境。FT-076-2 结果 [SKIP]（环境阻塞）：.sh 动态验证需 bash/WSL，本机不可用，不作为失败。**通过（.sh 侧断言环境 SKIP）**

#### FT-077：双平台行为一致性验证（P1）
- **用例ID**：FT-077
- **用例名称**：在可用环境中分别执行 load-env.ps1（PowerShell）与 load-env.sh（bash/WSL）的三种场景（env.json 存在 / 缺失 / 关键配置缺失），核对双平台行为与退出码一致：存在→退出码 0 且变量注入；缺失→提示含 env.example.json 指引且退出码非零；关键配置缺失→逐个列出缺失键名且退出码非零；成功提示与缺失提示语义一致
- **所属模块**：deploy/scripts / 双平台一致性
- **优先级**：P1
- **前置条件**：FT-073/074/075 可执行（双平台环境可用：PowerShell 5.1 + bash/WSL）
- **测试类型**：功能测试（动态验证，对比）
- **关联需求ID**：US-001 / F-001 / SAD 1.2 双平台一致
- **测试数据**：deploy/env.json + 临时缺失场景文件；deploy/scripts/load-env.ps1 / load-env.sh
- **测试步骤**：
  1. 分别记录 .ps1 与 .sh 在三场景下的行为输出与退出码
  2. 对比两平台三场景的退出码与提示语义是否一致
- **预期结果**：
  1. 双平台三场景行为一致：退出码一致（0 / 非零 / 非零）；提示文案语义一致（中文）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1（FT-077-1，已落地）
- **测试过程与结论**：2026-08-10 执行，FT-077-1 结果 [SKIP]（环境阻塞）：双平台一致性动态对比需 bash/WSL，本机不可用（HCS_E_HYPERV_NOT_INSTALLED）；.ps1 三场景行为已由 FT-073/074/075/076 全部验证通过；静态双平台契约已由 UT-146/149/150/151 覆盖。**按环境 SKIP（不作为失败），留待具备 bash/WSL 的环境补充 .sh 动态一致性验证**

### 模块：UI 测试
#### UIT-018：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-018
- **用例名称**：本任务为 load-env 统一配置加载脚本实现（common 类），客户端应用界面与交互无任何变更（git 变更清单无 `cloudoffice-flutter-app/lib/` 下 .dart 界面文件与客户端配置改动，Web/Windows 客户端零修改可用）
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：TASK-002 变更范围已确定（git 变更清单可核对）
- **测试类型**：UI 测试
- **关联需求ID**：US-001 / AC-3（客户端运行时代码零改动）
- **测试数据**：git 变更清单（`git diff --name-status` + `git status --porcelain`）
- **测试步骤**：
  1. 执行 git 命令获取变更文件清单
  2. 检查清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md（UIT-018 章节，已落地）
- **测试过程与结论**：2026-08-10 执行 git status --short 核对：变更清单仅含 deploy/scripts/load-env.ps1、deploy/scripts/load-env.sh、docs/cso-v0.2.7 下文档与 scripts/API-TEST 测试脚本，无任何 `cloudoffice-flutter-app/lib/` 下 .dart 界面文件、pubspec.yaml 与客户端构建配置改动。**通过**

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 15 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 1 |

> 说明：
> 1. 本任务（TASK-002）测试用例共 16 个（单元 8、接口 2、功能 5、UI 1），已于 2026-08-10 由 impm-task-coding-runtest 步骤全部执行：
>    - 单元测试脚本 `scripts/API-TEST/cso-unit-test-load-env-v0.2.7.ps1`：PASS=19、FAIL=0、SKIP=4（SKIP 均为 .sh 动态断言，本机无 bash/WSL，环境阻塞，符合风险评估预案）；
>    - 接口测试脚本 `scripts/API-TEST/cso-api-test-v0.2.7.py`（TASK-002 相关 TC-080/081）：PASS=5、FAIL=0、SKIP=0；
>    - UI 测试 UIT-018：git 变更清单静态核对通过。
> 2. 用例级结果：通过 15、跳过 1（FT-077 双平台一致性动态对比因本机无 bash/WSL 按环境 SKIP，不作为失败；FT-074/075/076 的 .sh 侧断言同样按环境 SKIP 处理，其 PowerShell 侧主断言均通过）。
> 3. 三场景（env.json 存在/缺失/关键配置缺失）行为验证与退出码核对由 FT-073/074/075 覆盖并通过；语法校验（PowerShell Parser + bash -n 降级结构核对）由 UT-144/145 覆盖并通过。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 环境无 bash/WSL | UT-145/FT-074/075/077 的 .sh 动态验证无法执行 | bash -n 降级为 shebang+非空+结构核对；动态行为验证记录环境 SKIP，不作为失败；本机 WSL 可用时优先走 WSL bash（当前本机 WSL 不可用，已按 SKIP 记录） |
| 真实 deploy/env.json 含敏感凭据 | FT-073 动态验证会加载真实凭据 | 仅在本机开发环境执行；成功验证不打印敏感值（脚本自身契约）；测试脚本断言仅检查键存在与非空（已执行通过，未打印任何敏感值） |
| FT-074/075 需临时移走/构造 env.json | 误操作影响真实环境 | 优先使用 `-EnvFile`/参数方式指向临时文件，不改动真实 deploy/env.json；确需移走时记录原路径并事后还原（本次通过临时文件 + EnvFile 参数方式验证，未改动真实 env.json） |
| load-env.sh 被 source 时 return 语义 | 单独执行 .sh 顶层 return 报错 | 功能验证统一以 `source` 方式执行（与调用方语义一致）；直接执行场景不作为本任务用例（.sh 动态断言本次按环境 SKIP） |
| 三场景退出码核对依赖调用方环境 | 退出码 0 与 $? 判断差异 | .ps1 用 `$LASTEXITCODE`/`$?` 双判据；.sh 用 `$?` 并区分 return 与 exit 语义（本次 .ps1 侧三场景退出码均已核对通过） |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（TASK-002 16 个测试用例执行完成：通过 15、跳过 1（FT-077 环境阻塞）、失败 0；单元测试 PASS=19/FAIL=0/SKIP=4、接口测试 TC-080/081 PASS=5、UI 测试 UIT-018 通过；三场景行为与退出码核对全部通过，.sh 动态断言因本机无 bash/WSL 按环境 SKIP）
- 项目经理（PM）：待执行

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
