# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

> 本任务（TASK-006）为重构单服务启动脚本 deploy-start-gateway/auth/biz/system 共 8 个脚本（.ps1/.sh）：
> 加载 env.json（经 load-env），校验本服务所需关键变量（gateway/auth 校验 NACOS_ADDR、RSA_PUBLIC_KEY，auth 另需 RSA_PRIVATE_KEY、DB_PASSWORD；biz/system 校验 NACOS_ADDR、DB_PASSWORD；biz 使用 DB_USER 与 auth 使用 DB_USERNAME 的差异保持现状一致）与对应 jar 存在后，以 `java -Xms256m -Xmx512m -jar <jar>` 启动；行为与 deploy-start-all 中对应服务启动逻辑一致（后台化启动、日志/PID 落位、健康确认、失败处理）；输出分级（通过/警告/失败）与退出码约定符合 F-011 规范（失败退出 1，全部通过退出 0）。
> 测试方法（任务 testMethod）：.ps1/.sh 语法校验；4 个服务各场景（关键变量缺失/jar 缺失/启动成功）行为验证；与 deploy-start-all 对应服务启动逻辑一致性核对。
> 用例编号延续版本测试用例文档空间（v0.2.7 中 TASK-005 末：TC-087、UT-189、FT-118、UIT-021），本任务新用例从 **TC-088、UT-190、FT-119、UIT-022** 起编号。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 单服务启动脚本重构 deploy-start-gateway/auth/biz/system（F-009 / F-001 / F-011 / US-003 / ADR-016）：TASK-006 | TASK-006 | 31 | P0×21、P1×9、P2×1 |
| 其中：单元测试（.ps1 语法解析、.sh bash -n、双平台成对与文件名对齐、SPDX 头与版本号、load-env 调用契约、各服务关键变量校验范围、biz DB_USER vs auth DB_USERNAME 差异、jar 存在性校验与启动命令、后台化启动与日志/PID 落位、健康确认逻辑、输出分级与退出码约定、敏感信息不打印明文、与 deploy-start-all 对应逻辑一致性静态核对） | TASK-006 | 13 | P0×10、P1×3 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查端点契约核对/探活可选） | TASK-006 | 2 | P1×1、P2×1 |
| 其中：功能测试（4 个服务各场景：关键变量缺失/jar 缺失/启动成功行为验证与退出码、env.json 缺失场景、.sh 双平台行为、已运行幂等与输出分级汇总） | TASK-006 | 15 | P0×11、P1×4 |
| 其中：UI 测试（无 UI 变更确认） | TASK-006 | 1 | P1×1 |

## 二、测试用例详情

### 模块：单服务启动脚本重构 - 单元测试（语法校验与静态核对）
#### UT-190：8 个单服务脚本 .ps1 语法可解析性（P0）
- **用例ID**：UT-190
- **用例名称**：deploy-start-gateway/auth/biz/system 共 4 个 .ps1 脚本经 PowerShell Parser 解析无语法错误（`[System.Management.Automation.Language.Parser]::ParseFile` 无 Error，断言 Errors.Count=0），重构后各单服务脚本可独立解析
- **所属模块**：deploy/scripts / deploy-start-gateway.ps1、deploy-start-auth.ps1、deploy-start-biz.ps1、deploy-start-system.ps1
- **优先级**：P0
- **前置条件**：TASK-006 编码完成，8 个单服务脚本已按 F-009/F-001/F-011 契约重构
- **测试类型**：单元测试（语法解析）
- **关联需求ID**：US-003 / F-009 / F-011 / ADR-016
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`、`deploy-start-auth.ps1`、`deploy-start-biz.ps1`、`deploy-start-system.ps1`
- **测试步骤**：
  1. 使用 PowerShell Parser API 逐个解析 4 个 .ps1（`[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)`）
  2. 断言每个脚本 `$errors.Count -eq 0`
  3. 抽查各脚本主流程关键块（load-env 加载、前置校验、后台启动、健康确认、汇总与退出码）是否存在
- **预期结果**：
  1. 4 个 .ps1 语法解析零错误，脚本可独立解析
  2. 主流程关键块齐全，脚本结构完整
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-190-1：4 个 .ps1 Parser 零错误；UT-190-2：主流程关键块齐全）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，cso-unit-test-start-single-v0.2.7.ps1）：UT-190-1/UT-190-2 断言全部 [PASS]——4 个 .ps1 经 PowerShell Parser 解析零错误（Errors.Count=0），主流程关键块（load-env 加载 / 前置校验 / Start-Process 后台启动 / Wait-HealthUp 健康确认 / exit 0/1）齐全

#### UT-191：8 个单服务脚本 .sh 语法校验（bash -n）（P0）
- **用例ID**：UT-191
- **用例名称**：deploy-start-gateway/auth/biz/system 共 4 个 .sh 脚本经 `bash -n` 语法校验无错误（Linux bash 或 Git Bash/WSL 下执行 `bash -n deploy/scripts/deploy-start-*.sh` 退出码 0），重构后各单服务脚本可独立解析
- **所属模块**：deploy/scripts / deploy-start-gateway.sh、deploy-start-auth.sh、deploy-start-biz.sh、deploy-start-system.sh
- **优先级**：P0
- **前置条件**：TASK-006 编码完成，4 个 .sh 已按契约重构
- **测试类型**：单元测试（语法校验）
- **关联需求ID**：US-003 / F-009 / F-011 / ADR-016
- **测试数据**：`deploy/scripts/deploy-start-gateway.sh`、`deploy-start-auth.sh`、`deploy-start-biz.sh`、`deploy-start-system.sh`
- **测试步骤**：
  1. 逐个执行 `bash -n deploy/scripts/deploy-start-*.sh`，断言退出码为 0 且无语法错误输出（环境无 bash/WSL 时降级为 shebang + 非空 + if/fi 配对 + 关键函数/流程块结构核对）
  2. 抽查各脚本主流程关键块（load-env 加载、前置校验、后台启动、健康确认、汇总与退出码）是否存在
  3. 核对 `source "$SCRIPT_DIR/load-env.sh" || exit $?` 语义正确（配置缺失时退出码透传）
- **预期结果**：
  1. `bash -n` 通过，脚本可独立解析（或结构核对通过）
  2. 主流程关键块齐全
  3. load-env source 返回值处理正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-191-1：bash -n 校验/结构 fallback；UT-191-2：load-env source || exit $? 与主流程块）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，本机无可用 bash/WSL，降级结构核对）：UT-191-1 结构 fallback 通过（shebang + 非空 + if/fi 配对 + print_result/wait_health_up 函数齐全），UT-191-2 load-env source || exit $? 语义与主流程块核对通过

#### UT-192：双平台成对存在与文件名对齐（P1）
- **用例ID**：UT-192
- **用例名称**：deploy-start-gateway/auth/biz/system 的 .ps1 与 .sh 共 8 个脚本全部存在且非空，文件名与对应服务一一对齐（deploy-start-gateway.ps1 ↔ deploy-start-gateway.sh 等 4 对），双平台成对完整
- **所属模块**：deploy/scripts / 双平台一致性
- **优先级**：P1
- **前置条件**：TASK-006 编码完成，8 个脚本均已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009 / F-011 / SAD 1.2
- **测试数据**：`deploy/scripts/deploy-start-gateway/auth/biz/system.{ps1,sh}`
- **测试步骤**：
  1. 检查 deploy/scripts 下 8 个单服务脚本文件均存在且非空
  2. 核对 4 对 .ps1/.sh 同名对应关系
  3. 核对双平台脚本各自针对同一服务（jar 名/端口/健康 URL 一致）
- **预期结果**：
  1. 8 个脚本齐全（gateway/auth/biz/system × .ps1/.sh）
  2. 同名脚本成对且服务对应关系正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-192-1：8 脚本存在且非空；UT-192-2：同名 .ps1/.sh 按服务对齐）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-192-1/UT-192-2 断言 [PASS]——8 个单服务脚本存在且非空，.ps1/.sh 同名按服务对齐（jar 文件名 / 端口 / 健康 URL 一致）

#### UT-193：SPDX 头与版权声明、版本号与弃用引用清理（P0）
- **用例ID**：UT-193
- **用例名称**：8 个单服务脚本文件头均含 SPDX-License-Identifier（Apache-2.0）与版权声明（Copyright 2026 jenemy8023 <jenemy8023@163.com>），脚本标题含版本 v0.2.7，注释中无对已弃用脚本 deploy-env-local 的引用（重构补齐 P7-14 缺口、清理 v0.1.7 旧版本残留）
- **所属模块**：deploy/scripts / 文件头规范
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-009 / F-011 / project.md 编码规范 / ADR-016
- **测试数据**：`deploy/scripts/deploy-start-gateway/auth/biz/system.{ps1,sh}`
- **测试步骤**：
  1. 逐个读取 8 个脚本文件头，核对 SPDX-License-Identifier 与版权声明行存在
  2. grep 核对标题/注释中的版本号含 v0.2.7、不含旧版 v0.1.7
  3. grep 核对无 deploy-env-local / deploy-env.ps1 等弃用脚本引用
- **预期结果**：
  1. 8/8 脚本含 SPDX 头与版权声明（对应 UT-141-1 转通过）
  2. 版本号 v0.2.7、无旧版残留、无弃用脚本引用
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-193-1/2/3：SPDX+版权、版本 v0.2.7 无 v0.1.7、无弃用脚本引用）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-193-1/2/3 [PASS]——8/8 脚本含 SPDX-License-Identifier（Apache-2.0）与版权声明（Copyright 2026 jenemy8023），版本 v0.2.7 且无 v0.1.7 残留，无 deploy-env-local / deploy-env.ps1 弃用引用（UT-141-1 转通过）

#### UT-194：load-env 调用契约（双平台）（P0）
- **用例ID**：UT-194
- **用例名称**：8 个单服务脚本统一经 load-env 加载 env.json：.ps1 以 dot-source 方式 `. "$PSScriptRoot\load-env.ps1"` 加载、.sh 以 `source "$SCRIPT_DIR/load-env.sh" || exit $?` 加载（退出码透传），脚本内不硬编码环境地址与凭据；缺失 env.json / 关键配置由 load-env 兜底非零退出
- **所属模块**：deploy/scripts / load-env 契约
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；TASK-002 load-env 已就绪
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-001 / F-009 / ADR-016
- **测试数据**：8 个单服务脚本 + `deploy/scripts/load-env.ps1` / `load-env.sh`
- **测试步骤**：
  1. 逐个核对 8 个脚本的 load-env 调用语句（.ps1 dot-source / .sh source || exit $?）
  2. grep 核对脚本内无硬编码 IP/端口/凭据默认值（192.168.1.x 等）
  3. 核对脚本路径计算（$ProjectDir = Split-Path -Parent $PSScriptRoot / SCRIPT_DIR-PROJECT_DIR 三段式）
- **预期结果**：
  1. 8/8 脚本调用 load-env，加载失败退出码透传
  2. 无硬编码地址与凭据
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-194-1/2/3：load-env 调用契约、无硬编码地址、路径计算）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-194-1/2/3 [PASS]——8/8 脚本调用 load-env（.ps1 dot-source / .sh source || exit $? 退出码透传），无硬编码 192.168.1.1xx 默认地址，路径计算正确（Split-Path -Parent PSScriptRoot / dirname SCRIPT_DIR）

#### UT-195：各服务关键变量校验范围静态核对（P0）
- **用例ID**：UT-195
- **用例名称**：4 个单服务脚本按 F-009/契约表校验本服务关键变量，双平台校验范围一致：gateway 校验 NACOS_ADDR、RSA_PUBLIC_KEY；auth 校验 NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD（移除现状多余的 DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT 校验）；biz/system 校验 NACOS_ADDR、DB_PASSWORD（biz/system 的 .ps1 补齐 DB_PASSWORD 对齐 .sh）；缺失提示只列键名、不打印值
- **所属模块**：deploy/scripts / 关键变量校验（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009
- **测试数据**：8 个单服务脚本（校验变量清单按服务：gateway=NACOS_ADDR,RSA_PUBLIC_KEY；auth=NACOS_ADDR,RSA_PUBLIC_KEY,RSA_PRIVATE_KEY,DB_PASSWORD；biz/system=NACOS_ADDR,DB_PASSWORD）
- **测试步骤**：
  1. 逐个核对 8 个脚本校验的变量清单与契约表一致（gateway/auth/biz/system 各自对应）
  2. 核对 auth 脚本不再校验 DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT（现状 9 变量收敛为 4 变量）
  3. 核对 biz/system 双平台均校验 DB_PASSWORD（.ps1/.sh 对齐）
  4. 核对缺失提示只列键名不打印值
- **预期结果**：
  1. 各服务校验范围与 F-009/契约表完全一致
  2. 双平台校验范围一致（P7-02 转通过）
  3. 缺失提示不含敏感值
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-195-1/2/3/4：各服务校验范围、auth 9 变量收敛 4、biz/system DB_PASSWORD 双平台对齐、键名提示）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-195-1/2/3/4 [PASS]——各服务校验范围与 F-009 契约完全一致（gateway=NACOS_ADDR,RSA_PUBLIC_KEY；auth 另需 RSA_PRIVATE_KEY,DB_PASSWORD；biz/system=NACOS_ADDR,DB_PASSWORD）；auth 9 变量收敛为 4（不再校验 DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT）；biz/system .ps1 补齐 DB_PASSWORD 与 .sh 对齐；缺失提示只列键名（缺失或为空 + 不打印值标记齐全）

#### UT-196：biz 用 DB_USER 与 auth 用 DB_USERNAME 差异保持（P1）
- **用例ID**：UT-196
- **用例名称**：biz 使用 DB_USER、auth 使用 DB_USERNAME 的差异在脚本注释中说明并保持（不因重构丢失）；单服务脚本校验范围不引入 DB_USER/DB_USERNAME 校验（契约表未列，仅注释说明差异，与 start-all 契约表 RequiredVars 一致）
- **所属模块**：deploy/scripts / DB_USER vs DB_USERNAME 差异（F-009）
- **优先级**：P1
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009
- **测试数据**：`deploy/scripts/deploy-start-biz.{ps1,sh}`、`deploy-start-auth.{ps1,sh}`、`deploy/env.example.json`（含 DB_USER 与 DB_USERNAME 双键）
- **测试步骤**：
  1. 核对 biz 脚本注释中说明 biz 使用 DB_USER（与 auth 的 DB_USERNAME 不同的说明保留）
  2. 核对 auth 脚本注释中说明 auth 使用 DB_USERNAME
  3. 核对两脚本校验变量清单均不含 DB_USER/DB_USERNAME（差异仅注释说明，不参与启动校验）
- **预期结果**：
  1. biz 用 DB_USER、auth 用 DB_USERNAME 差异说明保持，与现状一致
  2. 校验范围与契约表一致，无 DB_USER/DB_USERNAME 校验
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-196-1/2：DB_USER/DB_USERNAME 差异注释保持且不参与校验）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-196-1/2 [PASS]——biz 使用 DB_USER 与 auth 使用 DB_USERNAME 的差异注释在双平台保持，DB_USER/DB_USERNAME 均不参与任何 RequiredVars 校验（差异仅注释说明）

#### UT-197：jar 存在性校验与启动命令（P0）
- **用例ID**：UT-197
- **用例名称**：8 个单服务脚本均校验对应 jar 存在（.ps1 `Test-Path -LiteralPath $jarPath` / .sh `[ -f "$PROJECT_DIR/$jar" ]`），jar 缺失输出缺失提示并退出非零；启动命令统一为 `java -Xms256m -Xmx512m -jar <jar>`（jar 文件名：cloudoffice-gateway.jar / cloudoffice-auth-service.jar / cloudoffice-biz-service.jar / cloudoffice-system-service.jar，路径 deploy/ 根目录）
- **所属模块**：deploy/scripts / jar 校验与启动命令（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；4 个 jar 已落位 deploy 目录
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009
- **测试数据**：8 个单服务脚本；`deploy/cloudoffice-gateway.jar` 等 4 个 jar 文件名
- **测试步骤**：
  1. 逐个核对 8 个脚本的 jar 路径计算（$ProjectDir/Join-Path 或 PROJECT_DIR）与存在性校验语句
  2. 核对 4 个脚本 jar 文件名与 deploy 目录实际 jar 一一对应
  3. 核对启动命令参数 `java -Xms256m -Xmx512m -jar` 在 8 个脚本中一致
- **预期结果**：
  1. jar 存在性校验齐全，缺失退出非零
  2. jar 文件名对应正确，启动命令统一
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-197-1/2/3：jar 名对应、存在性校验、统一启动命令）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-197-1/2/3 [PASS]——4 服务 jar 文件名 1:1 对应（cloudoffice-gateway.jar 等），jar 存在性校验齐全（Test-Path -LiteralPath / [ ! -f ]，缺失退出非零），启动命令统一 java -Xms256m -Xmx512m -jar

#### UT-198：后台化启动与日志/PID 落位（P0）
- **用例ID**：UT-198
- **用例名称**：8 个单服务脚本均后台化启动并落位日志/PID：.ps1 用 `Start-Process -FilePath "java" -ArgumentList "-Xms256m","-Xmx512m","-jar",$jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru` 并以 `$proc.Id | Out-File -Encoding ascii $pidFile` 记录 PID（不用 -Wait、不用 -NoNewWindow 与 -WindowStyle 混用）；.sh 用 `nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &` + `echo $! > "$PID_FILE"`；日志/PID 落位 deploy/logs/{module}-start.log（.ps1 另有 -start.err）、deploy/logs/{module}.pid；logs 目录先创建（New-Item -Force / mkdir -p）
- **所属模块**：deploy/scripts / 后台化与日志落位（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009 / SAD ADR-016
- **测试数据**：8 个单服务脚本
- **测试步骤**：
  1. 逐个核对 .ps1 的 Start-Process 参数（-WindowStyle Hidden + 双重定向 + -PassThru，无 -Wait/-NoNewWindow）
  2. 逐个核对 .sh 的 nohup 后台化 + $! PID 记录
  3. 核对日志/PID 文件路径（deploy/logs/{module}-start.log / -start.err / {module}.pid）与 logs 目录创建语句
- **预期结果**：
  1. 双平台后台化方式与 TASK-005 start-all 基准一致
  2. 日志/PID 落位路径正确，logs 目录确保存在
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-198-1/2/3：后台化 Start-Process Hidden/nohup、日志/PID 落位）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-198-1/2/3 [PASS]——.ps1 用 Start-Process Hidden + 双重定向 + PassThru + PID 落盘（无 -Wait / -NoNewWindow 混用）；.sh 用 nohup + 2>&1 & + echo $!；日志/PID 落位 deploy/logs/{module}-start.log（-start.err）/.pid 与 logs 目录创建（New-Item -Force / mkdir -p）齐全

#### UT-199：健康确认逻辑（P0）
- **用例ID**：UT-199
- **用例名称**：8 个单服务脚本均含健康确认：HTTP 优先（gateway `http://localhost:9000/`、auth/biz/system `http://localhost:{port}/api/v1/{module}/health`，端口 9100/9200/9400），TCP 端口探测备用；轮询默认重试 30 次/间隔 2 秒/单次超时 3 秒，.ps1 用 param（RetryCount/RetryInterval/ProbeTimeout）可配置、.sh 用环境变量（RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT）可覆盖；与 start-all 的 Wait-HealthUp / wait_health_up 逻辑一致
- **所属模块**：deploy/scripts / 健康确认（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009
- **测试数据**：8 个单服务脚本；健康 URL 契约：gateway http://localhost:9000/、auth http://localhost:9100/api/v1/auth/health、biz http://localhost:9200/api/v1/biz/health、system http://localhost:9400/api/v1/system/health
- **测试步骤**：
  1. 逐个核对 4 个服务的健康 URL 与契约表一致
  2. 核对健康探测判定（任一 HTTP 响应即视为启动、TCP 备用）与轮询参数默认值/可配置性
  3. 核对健康确认失败时输出失败分级并退出非零
- **预期结果**：
  1. 健康 URL 与契约一致
  2. 轮询参数默认 30/2/3 可配置，失败处理符合 F-011
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-199-1/2/3/4：健康 URL、轮询默认 30/2/3、HTTP+TCP、失败分支）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-199-1/2/3/4 [PASS]——健康 URL 与契约一致（gateway 9000 根路径、auth/biz/system /api/v1/{m}/health），轮询默认 30 次 / 间隔 2 秒 / 超时 3 秒可配置（param / 环境变量），HTTP 优先 + TCP 备用，健康确认失败输出失败分级并退出非零

#### UT-200：输出分级与退出码约定（F-011）（P0）
- **用例ID**：UT-200
- **用例名称**：8 个单服务脚本输出分级（通过/警告/失败，.ps1 Write-Result 绿/黄/红、.sh print_result，不用 emoji）与退出码约定（存在失败项退出 1 并提示处理，全部通过退出 0；警告不阻塞退出 0）符合 F-011；标题含版本 v0.2.7
- **所属模块**：deploy/scripts / 输出分级与退出码（F-011）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：8 个单服务脚本
- **测试步骤**：
  1. 逐个核对输出分级函数（Write-Result / print_result）与「通过/警告/失败」文本前缀、颜色
  2. 核对无 emoji 输出（无 ❌/✅/⚠️ 等）
  3. 核对退出码路径：前置校验失败 exit 1、健康确认失败 exit 1、全部通过 exit 0
- **预期结果**：
  1. 输出分级与 F-011 一致（不用 emoji）
  2. 退出码约定：失败 1、通过 0
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-200-1/2/3：输出分级+颜色、无 emoji、exit 0/1）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-200-1/2/3 [PASS]——输出分级 通过/警告/失败 + 绿/黄/红配色（.ps1 -ForegroundColor / .sh ANSI），无 emoji 输出，退出码约定符合 F-011（存在失败 exit 1、全部通过 exit 0，警告不阻塞退出 0）

#### UT-201：敏感信息不打印明文（P0，安全）
- **用例ID**：UT-201
- **用例名称**：8 个单服务脚本对 DB_PASSWORD / RSA_PRIVATE_KEY / RSA_PUBLIC_KEY 等敏感值仅校验非空、不打印值；缺失提示只列键名（如"请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"）；输出语句与日志落盘内容均无敏感明文引用（静态核对 0 处敏感输出行）
- **所属模块**：deploy/scripts / 安全（F-011 / project.md）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-009 / F-011 / project.md 安全约定
- **测试数据**：8 个单服务脚本
- **测试步骤**：
  1. grep 核对 8 个脚本中无直接输出 DB_PASSWORD / RSA_PRIVATE_KEY / RSA_PUBLIC_KEY 值（或 $DB_PASSWORD 等变量值）的语句
  2. 核对缺失提示仅列键名
  3. 核对日志文件内容不写敏感值（Write-* 输出流无凭据变量值）
- **预期结果**：
  1. 无敏感明文输出（缺失提示只列键名）
  2. 日志不落明文凭据
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-201-1/2：输出语句无敏感值引用、键名提示）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对，安全）：UT-201-1/2 [PASS]——8 个脚本输出语句 0 处直接引用 DB_PASSWORD / RSA_PRIVATE_KEY / RSA_PUBLIC_KEY 变量值，缺失提示只列键名（不打印值标记齐全），日志不落明文凭据

#### UT-202：与 deploy-start-all 对应服务启动逻辑一致性静态核对（P0）
- **用例ID**：UT-202
- **用例名称**：8 个单服务脚本与 deploy-start-all.ps1/.sh 中对应服务子块逐项静态比对一致：加载配置（load-env）、前置校验（java 可用 + jar 存在 + 关键变量非空）、后台启动（Start-Process -WindowStyle Hidden 双重定向 / nohup &）、日志/PID 落位（deploy/logs/{module}-start.log、-start.err、{module}.pid）、健康确认（HTTP URL 与轮询参数）、失败处理（失败分级 + 退出 1）、输出分级与退出码（F-011）；单服务脚本仅处理本服务一个子块，逻辑与 start-all 对应服务完全一致
- **所属模块**：deploy/scripts / 与 deploy-start-all 一致性（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；TASK-005 deploy-start-all 已就绪（行为对齐唯一基准）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-003 / F-009 / ADR-016
- **测试数据**：8 个单服务脚本 + `deploy/scripts/deploy-start-all.ps1` / `deploy-start-all.sh`
- **测试步骤**：
  1. 以 start-all 各服务子块为基准，逐项比对 4 个单服务脚本的加载/校验/启动/健康/退出码逻辑
  2. 核对启动参数（-Xms256m -Xmx512m）、日志/PID 路径、健康 URL、轮询默认值一致
  3. 核对失败提示文案与 start-all 对应服务失败提示一致（如 gateway"请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"、auth"请检查 RSA 密钥对/DB_PASSWORD 配置"）
  4. 核对 .ps1 与 .sh 同名脚本行为对齐（含 biz/system 的 DB_PASSWORD 校验双平台一致）
- **预期结果**：
  1. 单服务脚本与 start-all 对应服务子块逻辑完全一致（P7-01/P7-02 转通过）
  2. 失败提示与输出分级/退出码一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（断言 UT-202-1/2/3/4：与 deploy-start-all 对应服务 jar/端口/健康 URL/变量/提示/参数一致性）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：UT-202-1/2/3/4 [PASS]——单服务脚本与 deploy-start-all 对应服务子块逐项一致（jar / 端口 / 健康 URL / RequiredVars / 失败提示文案 / 启动参数 -Xms256m -Xmx512m / 轮询默认值 / 日志路径），P7-01/P7-02 转通过

### 模块：单服务启动脚本重构 - 接口测试（无接口变更确认）
#### TC-088：API 契约静态核对——单服务脚本健康 URL 与接口文档一致（P1）
- **用例ID**：TC-088
- **用例名称**：本任务（TASK-006 单服务脚本重构）无接口变更，API-001~API-033 契约完整保留；4 个单服务脚本使用的健康检查端点与 API 文档一致：gateway `http://localhost:9000/`（根路径）、auth `/api/v1/auth/health`（API-012）、biz `/api/v1/biz/health`（API-032）、system `/api/v1/system/health`（API-033），脚本仅调用既有健康端点做部署确认，不新增不修改接口契约
- **所属模块**：接口契约 / 健康检查端点（API-012/032/033）
- **优先级**：P1
- **前置条件**：TASK-006 编码完成；API v0.2.7 文档已确认无接口变更
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-003 / F-009 / API v0.2.7 契约
- **测试数据**：8 个单服务脚本 + `docs/cso-api.md` / `docs/cso-v0.2.7/cso-api-v0.2.7.md`
- **测试步骤**：
  1. 核对 git 变更清单中无接口层文件（Controller/DTO/响应体）改动
  2. 逐个核对 4 个单服务脚本健康 URL 与 API 文档健康端点（API-012/032/033 及 gateway 根路径）一致
  3. 核对脚本仅调用健康端点做部署确认（无新增接口调用）
- **预期结果**：
  1. 接口层零改动，API-001~API-033 契约完整保留
  2. 脚本健康 URL 与 API 文档完全一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py`（test_tc088_no_api_change：TC-088-1 文档声明、TC-088-2 git 变更无接口层、TC-088-3 健康 URL 契约核对）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，cso-api-test-v0.2.7.py）：TC-088-1/2/3 [PASS]——版本 API 文档声明本版本无新增/变更/删除接口；git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）；8 个单服务脚本健康 URL 与 API 文档一致（gateway 根路径 / API-012 / API-032 / API-033）且仅 GET 探测既有健康端点

#### TC-089：健康端点契约探活（可选）（P2）
- **用例ID**：TC-089
- **用例名称**：当 4 个后端服务运行中时，按单服务脚本健康 URL 动态探活确认端点可访问（gateway 9000 根路径、auth 9100 /api/v1/auth/health、biz 9200 /api/v1/biz/health、system 9400 /api/v1/system/health 任一 HTTP 响应即视为可访问）；服务未启动时按环境 SKIP 记录，不作为失败
- **所属模块**：接口契约 / 健康检查端点探活（API-012/032/033）
- **优先级**：P2
- **前置条件**：4 个后端服务运行中（可选，未启动按环境 SKIP）
- **测试类型**：接口测试（动态探活，环境依赖）
- **关联需求ID**：US-003 / F-009 / API v0.2.7 契约
- **测试数据**：健康 URL：http://localhost:9000/、http://localhost:9100/api/v1/auth/health、http://localhost:9200/api/v1/biz/health、http://localhost:9400/api/v1/system/health
- **测试步骤**：
  1. 探测 4 个健康 URL（任一 HTTP 响应即通过）
  2. 记录各端点响应状态
- **预期结果**：
  1. 运行中的服务端点均可访问（与脚本健康确认判定一致）
  2. 服务未启动时按环境 SKIP，不作为失败
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py`（test_tc089_health_probe：TC-089-1~4 健康端点探活，服务未启动按环境 SKIP）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，4 服务运行中动态探活）：TC-089-1~4 [PASS]——gateway 9000 根路径、auth 9100 /api/v1/auth/health、biz 9200 /api/v1/biz/health、system 9400 /api/v1/system/health 全部可访问（code=200、status=UP），与脚本健康确认判定一致

### 模块：单服务启动脚本重构 - 功能测试（场景行为验证）
#### FT-119：deploy-start-gateway.ps1 关键变量缺失场景（P0）
- **用例ID**：FT-119
- **用例名称**：Given 环境变量中缺失 RSA_PUBLIC_KEY（或 NACOS_ADDR 之一），When 执行 `deploy-start-gateway.ps1`，Then 输出失败分级并逐个列出缺失键名（只列键名不打印值）与处理提示"请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"，退出码 1，且不启动服务
- **所属模块**：deploy-start-gateway / 关键变量缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；可安全构造临时 env 副本（不改真实 env.json 值）
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`；临时 env.json 副本（缺失 RSA_PUBLIC_KEY）
- **测试步骤**：
  1. 独立进程执行 deploy-start-gateway.ps1（使用临时 env 副本加载，缺失 RSA_PUBLIC_KEY），捕获输出与退出码
  2. 断言输出列出缺失键名 RSA_PUBLIC_KEY（不打印值），输出失败分级
  3. 断言退出码为 1，且未启动任何 Java 进程
- **预期结果**：
  1. 缺失键名逐项列出（不打印值），失败分级输出
  2. 退出码 1，不启动服务
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-119-1 动态断言：临时 env 副本缺失 RSA_PUBLIC_KEY，键名+失败分级+退出 1+无新端口+无明文）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，动态断言）：临时 env 副本缺失 RSA_PUBLIC_KEY 执行 deploy-start-gateway.ps1，输出列出缺失键名 RSA_PUBLIC_KEY（不打印值）+ 失败分级，退出码 1，未启动新服务（端口无新增监听），无敏感明文泄漏；env.json 已还原

#### FT-120：deploy-start-auth.ps1 关键变量缺失场景（P0）
- **用例ID**：FT-120
- **用例名称**：Given 环境变量中缺失 RSA_PRIVATE_KEY（或 DB_PASSWORD / RSA_PUBLIC_KEY / NACOS_ADDR 之一），When 执行 `deploy-start-auth.ps1`，Then 输出失败分级并列出缺失键名（只列键名不打印值）与处理提示"请检查 RSA 密钥对/DB_PASSWORD 配置"，退出码 1，且不启动服务
- **所属模块**：deploy-start-auth / 关键变量缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；可安全构造临时 env 副本
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-auth.ps1`；临时 env.json 副本（缺失 RSA_PRIVATE_KEY）
- **测试步骤**：
  1. 独立进程执行 deploy-start-auth.ps1（临时 env 副本缺失 RSA_PRIVATE_KEY），捕获输出与退出码
  2. 断言输出列出缺失键名 RSA_PRIVATE_KEY（不打印值），输出失败分级
  3. 断言退出码为 1，且未启动任何 Java 进程
- **预期结果**：
  1. 缺失键名列出（不打印值），失败分级输出
  2. 退出码 1，不启动服务
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-120-1 动态断言：临时 env 副本缺失 RSA_PRIVATE_KEY，键名+失败分级+退出 1+无新端口+无明文）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，动态断言）：临时 env 副本缺失 RSA_PRIVATE_KEY 执行 deploy-start-auth.ps1，输出列出缺失键名 RSA_PRIVATE_KEY（不打印值）+ 失败分级，退出码 1，未启动新服务（端口无新增监听），无敏感明文泄漏；env.json 已还原

#### FT-121：deploy-start-biz.ps1 关键变量缺失场景（P0）
- **用例ID**：FT-121
- **用例名称**：Given 环境变量中缺失 DB_PASSWORD（或 NACOS_ADDR），When 执行 `deploy-start-biz.ps1`，Then 输出失败分级并列出缺失键名 DB_PASSWORD（只列键名不打印值）与处理提示"请检查 DB_PASSWORD 配置"，退出码 1，且不启动服务（验证 .ps1 补齐 DB_PASSWORD 校验与 .sh 对齐）
- **所属模块**：deploy-start-biz / 关键变量缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；可安全构造临时 env 副本
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-biz.ps1`；临时 env.json 副本（缺失 DB_PASSWORD）
- **测试步骤**：
  1. 独立进程执行 deploy-start-biz.ps1（临时 env 副本缺失 DB_PASSWORD），捕获输出与退出码
  2. 断言输出列出缺失键名 DB_PASSWORD（不打印值），输出失败分级
  3. 断言退出码为 1，且未启动任何 Java 进程
- **预期结果**：
  1. 缺失键名列出（不打印值），失败分级输出（P7-02 biz .ps1 缺口转通过）
  2. 退出码 1，不启动服务
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-121-1 动态断言：临时 env 副本缺失 DB_PASSWORD，键名+退出 1+无新端口（load-env 兜底路径））
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，动态断言）：临时 env 副本缺失 DB_PASSWORD 执行 deploy-start-biz.ps1（DB_PASSWORD 属 load-env 基线，走 load-env 兜底路径），输出列出缺失键名 DB_PASSWORD（不打印值）+ 失败分级，退出码 1，未启动新服务（P7-02 biz .ps1 缺口转通过）；env.json 已还原

#### FT-122：deploy-start-system.ps1 关键变量缺失场景（P0）
- **用例ID**：FT-122
- **用例名称**：Given 环境变量中缺失 DB_PASSWORD（或 NACOS_ADDR），When 执行 `deploy-start-system.ps1`，Then 输出失败分级并列出缺失键名 DB_PASSWORD（只列键名不打印值）与处理提示"请检查 DB_PASSWORD 配置"，退出码 1，且不启动服务（验证 .ps1 补齐 DB_PASSWORD 校验与 .sh 对齐）
- **所属模块**：deploy-start-system / 关键变量缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；可安全构造临时 env 副本
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-system.ps1`；临时 env.json 副本（缺失 DB_PASSWORD）
- **测试步骤**：
  1. 独立进程执行 deploy-start-system.ps1（临时 env 副本缺失 DB_PASSWORD），捕获输出与退出码
  2. 断言输出列出缺失键名 DB_PASSWORD（不打印值），输出失败分级
  3. 断言退出码为 1，且未启动任何 Java 进程
- **预期结果**：
  1. 缺失键名列出（不打印值），失败分级输出
  2. 退出码 1，不启动服务
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-122-1 动态断言：临时 env 副本缺失 DB_PASSWORD，键名+退出 1+无新端口（load-env 兜底路径））
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，动态断言）：临时 env 副本缺失 DB_PASSWORD 执行 deploy-start-system.ps1（load-env 兜底路径），输出列出缺失键名 DB_PASSWORD（不打印值）+ 失败分级，退出码 1，未启动新服务（端口无新增监听）；env.json 已还原

#### FT-123：deploy-start-gateway.ps1 jar 缺失场景（P0）
- **用例ID**：FT-123
- **用例名称**：Given 前置校验通过但 `deploy/cloudoffice-gateway.jar` 缺失（临时移走），When 执行 `deploy-start-gateway.ps1`，Then 输出失败分级与 jar 缺失提示（指明 cloudoffice-gateway.jar 路径），退出码 1，且不启动服务（验证后还原 jar）
- **所属模块**：deploy-start-gateway / jar 缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 未被运行中 Java 进程锁定（可临时移走/还原）
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`；`deploy/cloudoffice-gateway.jar`（临时移走并还原）
- **测试步骤**：
  1. 备份并临时移走 deploy/cloudoffice-gateway.jar
  2. 独立进程执行 deploy-start-gateway.ps1，捕获输出与退出码
  3. 断言输出 jar 缺失提示（指明 jar 文件名），退出码 1，未启动服务
  4. 还原 jar 文件
- **预期结果**：
  1. jar 缺失提示明确，失败分级输出
  2. 退出码 1，不启动服务；jar 已还原
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-123-1 动态断言：临时移走 jar+还原；jar 被运行中服务锁定时按环境 SKIP）
- **测试过程与结论**：**跳过**（环境安全降级，不作为失败）：deploy/cloudoffice-gateway.jar 被运行中 Java 服务锁定（临时移走失败），无法安全构造 jar 缺失场景；静态覆盖由 UT-197/UT-202 提供

#### FT-124：deploy-start-auth.ps1 jar 缺失场景（P0）
- **用例ID**：FT-124
- **用例名称**：Given 前置校验通过但 `deploy/cloudoffice-auth-service.jar` 缺失（临时移走），When 执行 `deploy-start-auth.ps1`，Then 输出失败分级与 jar 缺失提示（指明 cloudoffice-auth-service.jar），退出码 1，且不启动服务（验证后还原 jar）
- **所属模块**：deploy-start-auth / jar 缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 未被运行中 Java 进程锁定
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-auth.ps1`；`deploy/cloudoffice-auth-service.jar`（临时移走并还原）
- **测试步骤**：
  1. 备份并临时移走 deploy/cloudoffice-auth-service.jar
  2. 独立进程执行 deploy-start-auth.ps1，捕获输出与退出码
  3. 断言输出 jar 缺失提示（指明 jar 文件名），退出码 1，未启动服务
  4. 还原 jar 文件
- **预期结果**：
  1. jar 缺失提示明确，失败分级输出
  2. 退出码 1，不启动服务；jar 已还原
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-124-1 动态断言：临时移走 jar+还原；jar 被运行中服务锁定时按环境 SKIP）
- **测试过程与结论**：**跳过**（环境安全降级，不作为失败）：deploy/cloudoffice-auth-service.jar 被运行中 Java 服务锁定（临时移走失败），无法安全构造 jar 缺失场景；静态覆盖由 UT-197/UT-202 提供

#### FT-125：deploy-start-biz.ps1 jar 缺失场景（P0）
- **用例ID**：FT-125
- **用例名称**：Given 前置校验通过但 `deploy/cloudoffice-biz-service.jar` 缺失（临时移走），When 执行 `deploy-start-biz.ps1`，Then 输出失败分级与 jar 缺失提示（指明 cloudoffice-biz-service.jar），退出码 1，且不启动服务（验证后还原 jar）
- **所属模块**：deploy-start-biz / jar 缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 未被运行中 Java 进程锁定
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-biz.ps1`；`deploy/cloudoffice-biz-service.jar`（临时移走并还原）
- **测试步骤**：
  1. 备份并临时移走 deploy/cloudoffice-biz-service.jar
  2. 独立进程执行 deploy-start-biz.ps1，捕获输出与退出码
  3. 断言输出 jar 缺失提示（指明 jar 文件名），退出码 1，未启动服务
  4. 还原 jar 文件
- **预期结果**：
  1. jar 缺失提示明确，失败分级输出
  2. 退出码 1，不启动服务；jar 已还原
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-125-1 动态断言：临时移走 jar+还原；jar 被运行中服务锁定时按环境 SKIP）
- **测试过程与结论**：**跳过**（环境安全降级，不作为失败）：deploy/cloudoffice-biz-service.jar 被运行中 Java 服务锁定（临时移走失败），无法安全构造 jar 缺失场景；静态覆盖由 UT-197/UT-202 提供

#### FT-126：deploy-start-system.ps1 jar 缺失场景（P0）
- **用例ID**：FT-126
- **用例名称**：Given 前置校验通过但 `deploy/cloudoffice-system-service.jar` 缺失（临时移走），When 执行 `deploy-start-system.ps1`，Then 输出失败分级与 jar 缺失提示（指明 cloudoffice-system-service.jar），退出码 1，且不启动服务（验证后还原 jar）
- **所属模块**：deploy-start-system / jar 缺失（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 未被运行中 Java 进程锁定
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-system.ps1`；`deploy/cloudoffice-system-service.jar`（临时移走并还原）
- **测试步骤**：
  1. 备份并临时移走 deploy/cloudoffice-system-service.jar
  2. 独立进程执行 deploy-start-system.ps1，捕获输出与退出码
  3. 断言输出 jar 缺失提示（指明 jar 文件名），退出码 1，未启动服务
  4. 还原 jar 文件
- **预期结果**：
  1. jar 缺失提示明确，失败分级输出
  2. 退出码 1，不启动服务；jar 已还原
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-126-1 动态断言：临时移走 jar+还原；jar 被运行中服务锁定时按环境 SKIP）
- **测试过程与结论**：**跳过**（环境安全降级，不作为失败）：deploy/cloudoffice-system-service.jar 被运行中 Java 服务锁定（临时移走失败），无法安全构造 jar 缺失场景；静态覆盖由 UT-197/UT-202 提供

#### FT-127：deploy-start-gateway.ps1 全部就绪启动成功（P0）
- **用例ID**：FT-127
- **用例名称**：Given 关键变量齐全且 jar 存在（或服务已运行端口监听），When 执行 `deploy-start-gateway.ps1`，Then 后台化启动服务（Start-Process 隐藏窗口 + 日志/PID 落盘 deploy/logs/gateway-start.log、gateway-start.err、gateway.pid），健康确认通过（http://localhost:9000/ 任一响应），输出通过分级与汇总，退出码 0
- **所属模块**：deploy-start-gateway / 启动成功（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 存在、关键变量齐全、9000 端口可探测（服务运行中亦可，幂等）
- **测试类型**：功能测试（正向场景，环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`；短重试参数（RetryCount 缩短）
- **测试步骤**：
  1. 独立进程执行 deploy-start-gateway.ps1（短重试参数），捕获输出与退出码
  2. 断言输出含"通过"分级与启动/健康确认结果，退出码 0
  3. 核对 deploy/logs/ 下 gateway-start.log、gateway.pid 已生成（.ps1 另有 gateway-start.err）
  4. 核对 9000 端口已监听（服务已运行场景健康确认直接通过）
- **预期结果**：
  1. 启动成功输出通过分级与汇总，退出码 0
  2. 日志/PID 落盘正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-127-1 动态断言：需 -RunServiceTests 授权；已运行幂等/端口空闲场景，默认 SKIP 保护运行中服务）
- **测试过程与结论**：**跳过**（环境门控，不作为失败）：-RunServiceTests 未授权（本机 4 个后端服务运行中，默认运行绝不启动真实服务以保护既有服务）；启动成功行为由 UT-197~202 静态覆盖

#### FT-128：deploy-start-auth.ps1 全部就绪启动成功（P0）
- **用例ID**：FT-128
- **用例名称**：Given 关键变量齐全且 jar 存在（或服务已运行端口监听），When 执行 `deploy-start-auth.ps1`，Then 后台化启动服务（日志/PID 落盘 deploy/logs/auth-start.log、auth-start.err、auth.pid），健康确认通过（http://localhost:9100/api/v1/auth/health 任一响应），输出通过分级与汇总，退出码 0
- **所属模块**：deploy-start-auth / 启动成功（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 存在、关键变量齐全、9100 端口可探测
- **测试类型**：功能测试（正向场景，环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-auth.ps1`；短重试参数
- **测试步骤**：
  1. 独立进程执行 deploy-start-auth.ps1（短重试参数），捕获输出与退出码
  2. 断言输出含"通过"分级与启动/健康确认结果，退出码 0
  3. 核对 deploy/logs/ 下 auth-start.log、auth.pid 已生成
- **预期结果**：
  1. 启动成功输出通过分级与汇总，退出码 0
  2. 日志/PID 落盘正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-128-1 动态断言：需 -RunServiceTests 授权；已运行幂等/端口空闲场景，默认 SKIP 保护运行中服务）
- **测试过程与结论**：**跳过**（环境门控，不作为失败）：-RunServiceTests 未授权（本机 4 个后端服务运行中，默认运行绝不启动真实服务以保护既有服务）；启动成功行为由 UT-197~202 静态覆盖

#### FT-129：deploy-start-biz.ps1 全部就绪启动成功（P0）
- **用例ID**：FT-129
- **用例名称**：Given 关键变量齐全且 jar 存在（或服务已运行端口监听），When 执行 `deploy-start-biz.ps1`，Then 后台化启动服务（日志/PID 落盘 deploy/logs/biz-start.log、biz-start.err、biz.pid），健康确认通过（http://localhost:9200/api/v1/biz/health 任一响应），输出通过分级与汇总，退出码 0
- **所属模块**：deploy-start-biz / 启动成功（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 存在、关键变量齐全、9200 端口可探测
- **测试类型**：功能测试（正向场景，环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-biz.ps1`；短重试参数
- **测试步骤**：
  1. 独立进程执行 deploy-start-biz.ps1（短重试参数），捕获输出与退出码
  2. 断言输出含"通过"分级与启动/健康确认结果，退出码 0
  3. 核对 deploy/logs/ 下 biz-start.log、biz.pid 已生成
- **预期结果**：
  1. 启动成功输出通过分级与汇总，退出码 0
  2. 日志/PID 落盘正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-129-1 动态断言：需 -RunServiceTests 授权；已运行幂等/端口空闲场景，默认 SKIP 保护运行中服务）
- **测试过程与结论**：**跳过**（环境门控，不作为失败）：-RunServiceTests 未授权（本机 4 个后端服务运行中，默认运行绝不启动真实服务以保护既有服务）；启动成功行为由 UT-197~202 静态覆盖

#### FT-130：deploy-start-system.ps1 全部就绪启动成功（P0）
- **用例ID**：FT-130
- **用例名称**：Given 关键变量齐全且 jar 存在（或服务已运行端口监听），When 执行 `deploy-start-system.ps1`，Then 后台化启动服务（日志/PID 落盘 deploy/logs/system-start.log、system-start.err、system.pid），健康确认通过（http://localhost:9400/api/v1/system/health 任一响应），输出通过分级与汇总，退出码 0
- **所属模块**：deploy-start-system / 启动成功（F-009）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；jar 存在、关键变量齐全、9400 端口可探测
- **测试类型**：功能测试（正向场景，环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-system.ps1`；短重试参数
- **测试步骤**：
  1. 独立进程执行 deploy-start-system.ps1（短重试参数），捕获输出与退出码
  2. 断言输出含"通过"分级与启动/健康确认结果，退出码 0
  3. 核对 deploy/logs/ 下 system-start.log、system.pid 已生成
- **预期结果**：
  1. 启动成功输出通过分级与汇总，退出码 0
  2. 日志/PID 落盘正确
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-130-1 动态断言：需 -RunServiceTests 授权；已运行幂等/端口空闲场景，默认 SKIP 保护运行中服务）
- **测试过程与结论**：**跳过**（环境门控，不作为失败）：-RunServiceTests 未授权（本机 4 个后端服务运行中，默认运行绝不启动真实服务以保护既有服务）；启动成功行为由 UT-197~202 静态覆盖

#### FT-131：env.json 缺失场景（load-env 兜底）（P0）
- **用例ID**：FT-131
- **用例名称**：Given deploy/env.json 缺失（临时移走），When 执行任意单服务脚本（如 deploy-start-gateway.ps1），Then load-env 统一兜底输出"请复制 deploy/env.example.json 为 deploy/env.json 并填写配置后重试"提示，退出码 1（非零），不进入前置校验与启动流程（验证后还原 env.json）
- **所属模块**：deploy/scripts / load-env 兜底（F-001）
- **优先级**：P0
- **前置条件**：TASK-006 编码完成；可安全移走/还原 deploy/env.json（或经 -EnvFile 指向不存在路径构造）
- **测试类型**：功能测试（负向场景）
- **关联需求ID**：US-003 / F-001 / F-009
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`；deploy/env.json（临时移走并还原）
- **测试步骤**：
  1. 备份并临时移走 deploy/env.json
  2. 独立进程执行 deploy-start-gateway.ps1，捕获输出与退出码
  3. 断言输出 env.json 缺失提示（复制 env.example.json 指引），退出码 1
  4. 还原 deploy/env.json
- **预期结果**：
  1. load-env 兜底提示明确，退出码 1
  2. env.json 已还原
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-131-1 动态断言：临时移走 env.json+还原，load-env 兜底复制 env.example 提示+非零退出）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，动态断言）：临时移走 deploy/env.json 执行 deploy-start-gateway.ps1，load-env 兜底输出复制 env.example.json + 填写配置后重试指引，退出码非零（1），未进入前置校验与启动流程；env.json 已还原

#### FT-132：.sh 双平台行为场景（P1，环境依赖）
- **用例ID**：FT-132
- **用例名称**：Given Linux/Git Bash/WSL 环境可用，When 执行 4 个 .sh 单服务脚本的关键变量缺失与 jar 缺失场景（与 .ps1 对应场景行为一致），Then 输出分级与退出码与 .ps1 一致（缺失键名列出不打印值、退出 1、不启动）；环境无可用 bash 时按环境 SKIP 记录，双平台一致性由 UT-191/195/202 静态兜底
- **所属模块**：deploy/scripts / 双平台行为（F-011 / SAD 1.2）
- **优先级**：P1
- **前置条件**：可用 bash 环境（Linux/Git Bash/WSL）；可安全构造临时 env 副本
- **测试类型**：功能测试（环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-gateway.sh`、`deploy-start-auth.sh`、`deploy-start-biz.sh`、`deploy-start-system.sh`
- **测试步骤**：
  1. bash 可用时：临时 env 副本缺失关键变量，执行 .sh 脚本（source load-env.sh || exit 语义），断言缺失键名列出、退出码 1
  2. bash 可用时：临时移走 jar 执行 .sh 脚本，断言 jar 缺失提示、退出码 1（事后还原）
  3. 核对 .sh 输出分级与退出码与 .ps1 一致
  4. 环境无 bash 时按环境 SKIP 记录（UT-191/195/202 静态兜底）
- **预期结果**：
  1. .sh 行为与 .ps1 一致（缺失场景退出 1、输出分级）
  2. 环境不具备时 SKIP 不作为失败
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-132-1 动态断言：bash 可用时执行 .sh 缺失键场景；本机无 bash/WSL 按环境 SKIP，静态由 UT-191/195/202 兜底）
- **测试过程与结论**：**跳过**（环境不具备，不作为失败）：本机无可用 bash/WSL（bash 探测失败），无法执行 .sh 动态场景；双平台行为由 UT-191/UT-195/UT-202 静态兜底

#### FT-133：已运行幂等与输出分级/退出码汇总（P1）
- **用例ID**：FT-133
- **用例名称**：Given 4 个服务已运行（端口监听）且脚本全部就绪，When 再次执行单服务脚本（如 deploy-start-gateway.ps1 短重试参数），Then 健康确认因服务已就绪直接通过（不重复拉起新服务），输出通过分级与汇总（通过/警告/失败计数与处理提示），退出码 0（幂等场景）；失败场景输出失败分级与汇总，退出码 1（F-011）
- **所属模块**：deploy/scripts / 幂等与输出汇总（F-009 / F-011）
- **优先级**：P1
- **前置条件**：TASK-006 编码完成；对应服务已运行（或可安全拉起后还原）
- **测试类型**：功能测试（环境依赖）
- **关联需求ID**：US-003 / F-009 / F-011
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1` 等 4 个脚本；短重试参数
- **测试步骤**：
  1. 服务已运行时执行对应单服务脚本（短重试参数），断言健康确认直接通过、输出通过分级与汇总、退出码 0
  2. 失败场景（变量缺失）执行，断言输出失败分级与汇总、退出码 1
  3. 核对输出含通过/警告/失败计数与处理提示（F-011）
- **预期结果**：
  1. 已运行场景幂等通过（不重复拉起），退出码 0
  2. 失败场景退出码 1，输出分级汇总完整（F-011）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1`（FT-133-1 动态断言：需 -RunServiceTests 授权；已运行幂等汇总+退出 0；失败场景分级汇总由 FT-119~122 覆盖）
- **测试过程与结论**：**跳过**（环境门控，不作为失败）：-RunServiceTests 未授权（已运行幂等场景需授权动态执行）；幂等与输出汇总逻辑由 UT-202 静态兜底，失败场景分级汇总由 FT-119~122 动态覆盖

### 模块：UI 测试（无 UI 变更确认）
#### UIT-022：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-022
- **用例名称**：确认本任务（TASK-006 重构单服务启动脚本）不涉及客户端 Flutter 应用 UI 变更：cloudoffice-flutter-app 无任何代码改动，UI 界面/交互/样式与 v0.2.6 完全一致
- **所属模块**：客户端 UI（Flutter）
- **优先级**：P1
- **前置条件**：TASK-006 编码完成
- **测试类型**：UI测试
- **关联需求ID**：US-003 / API v0.2.7 契约（UI 无变更）
- **测试数据**：`cloudoffice-flutter-app` 目录
- **测试步骤**：
  1. 检查本任务改动范围仅限 deploy/scripts 单服务脚本（deploy-start-gateway/auth/biz/system 的 .ps1/.sh）与 .gitignore
  2. 核对 cloudoffice-flutter-app 无任何代码改动（git status/diff）
- **预期结果**：
  1. 客户端代码无改动
  2. UI 行为与上一版本一致，无需 UI 测试执行
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`（UIT-022 节：git 变更清单静态核对，无 cloudoffice-flutter-app 文件）
- **测试过程与结论**：**通过**（2026-08-10 runtest 执行，静态核对）：git 变更清单仅含 deploy/scripts/deploy-start-gateway/auth/biz/system 的 .ps1/.sh（8 个）、.gitignore、docs/cso-v0.2.7/ 文档与 scripts/API-TEST/ 测试脚本，cloudoffice-flutter-app 下无任何文件改动（*.dart / pubspec.yaml 零变更），客户端 UI 与 v0.2.6 完全一致，无需 UI 测试执行

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 21 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 10 |

> 执行结果已由 impm-task-coding-runtest 于 2026-08-10 记录：通过 21 / 失败 0 / 阻塞 0 / 跳过 10（跳过均为环境门控/环境不具备/运行中服务锁定，不作为失败；动态启动场景按环境安全降级 SKIP，未影响运行中服务）。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 真实服务启动场景依赖环境（4 服务运行状态/端口占用） | FT-127~130 无法精确构造"全部就绪"场景 | 服务已运行时可验证幂等通过（健康确认直接通过）；环境不满足时按 SKIP 记录，以 UT-197~202 静态核对兜底 |
| 失败场景构造（jar 缺失/关键变量缺失） | 误操作影响真实环境与既有服务 | jar 缺失用临时移走+还原（jar 被运行中 Java 锁定无法移走时按环境 SKIP）；变量缺失用临时 env 副本（不改真实 env.json 值） |
| 环境无 bash/WSL | UT-191 .sh 语法校验与 FT-132 双平台动态对比无法执行 | bash -n 降级为 shebang+非空+结构核对；双平台行为由 UT-191/195/202 静态兜底，动态对比按环境 SKIP |
| deploy/env.json 含真实敏感凭据 | FT-119~122/133 动态验证会加载真实凭据 | 仅在本机开发环境执行；缺失场景用临时 env 副本（不含敏感值）；成功验证不打印敏感值（脚本自身契约 + UT-201 静态核对） |
| 单服务脚本真实拉起后端服务 | 端口与既有服务冲突、测试后遗留进程 | 执行前记录端口/进程基线，测试后按基线清理测试拉起的新进程；与既有服务冲突的用例按环境 SKIP |
| 健康确认轮询耗时（默认 30 次 × 2 秒） | 超时场景测试耗时 | 测试通过参数缩短重试次数/间隔构造快速超时；默认参数行为由 UT-199 静态核对 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（TASK-006 测试用例 31 个编写完成：单元 13（UT-190~202）、接口 2（TC-088/089）、功能 15（FT-119~133）、UI 1（UIT-022）；自动化测试函数/脚本由 impm-task-coding-writetest 编写，执行结果已由 impm-task-coding-runtest 于 2026-08-10 记录：通过 21 / 失败 0 / 阻塞 0 / 跳过 10）
- 项目经理（PM）：待执行

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
