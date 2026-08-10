# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

**任务编号**：TASK-003
**任务名称**：重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测
**任务定义**：重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测（基于 load-env 加载的 env.json 配置去除硬编码默认地址；实现 JDK/MariaDB/Redis/Nacos 可用性检查与运行状态检测；Nacos 已安装未启动计"警告（未运行）"；输出通过/警告/失败分级汇总与退出码约定；移除无关检查项）。测试方法：.ps1/.sh 语法校验；JDK/MariaDB/Redis/Nacos 各环境通过/失败/警告场景与退出码验证；源码硬编码地址检查；口令掩码输出检查。

> 用例编号延续主文档空间（v0.2.6 末：TC-076、UT-131、FT-068、UIT-016；TASK-001 已用 TC-077~079、UT-132~143、FT-069~072、UIT-017；TASK-002 已用 TC-080~081、UT-144~151、FT-073~077、UIT-018），本任务新用例从 **TC-082、UT-152、FT-078、UIT-019** 起编号。
> 接口契约以 docs/cso-api.md 与当前代码实现为准；自动化测试函数/脚本位置已由 impm-task-coding-writetest 步骤标注（本文件回标），测试过程与结论由 writetest 步骤完成断言级验证、runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）。
> 本任务用例明细同步并入 `docs/cso-v0.2.7/cso-testcase-v0.2.7.md`。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy-check-env 环境可用性检查与运行状态检测重构（F-002~F-006 / F-010 / F-011 / US-001 / ADR-016）：TASK-003 | TASK-003 | 29 | P0×19、P1×9、P2×1 |
| 其中：单元测试（.ps1 语法解析、.sh bash -n、双平台成对与检查项一一对应、无硬编码地址、load-env 调用契约、可用性检查逻辑、Nacos 警告（未运行）逻辑、运行状态检测逻辑、输出分级与退出码约定、口令掩码不打印明文、无关项移除与死代码清理、SPDX 头与版本号） | TASK-003 | 12 | P0×7、P1×5 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-003 | 2 | P1×1、P2×1 |
| 其中：功能测试（JDK/MariaDB/Redis/Nacos 通过/失败/警告场景与退出码验证、Nacos 已安装未启动计警告（未运行）、运行状态检测场景、env.json 缺失场景、输出分级与退出码、口令掩码输出检查、双平台一致性） | TASK-003 | 14 | P0×11、P1×3 |
| 其中：UI 测试（无 UI 变更确认） | TASK-003 | 1 | P1×1 |

## 二、测试用例详情

### 模块：deploy-check-env 环境可用性检查与运行状态检测 - 单元测试（语法校验与静态核对）
#### UT-152：deploy-check-env.ps1 语法可解析性（P0）
- **用例ID**：UT-152
- **用例名称**：用 [System.Management.Automation.Language.Parser]::ParseFile 解析 deploy/scripts/deploy-check-env.ps1，确认无任何语法错误（PowerShell 5.1 兼容；重构后无孤立死代码行、无未闭合结构）
- **所属模块**：deploy/scripts / deploy-check-env.ps1 语法
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env.ps1 已按 F-010/F-011 契约重构
- **测试类型**：单元测试（语法解析）
- **关联需求ID**：US-001 / F-010 / F-011 / UT-142-1 基线
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`
- **测试步骤**：
  1. 调用 `[System.Management.Automation.Language.Parser]::ParseFile` 解析 deploy-check-env.ps1，收集 $errors
  2. 检查 errors 集合是否为空；若存在错误，逐条输出错误消息与位置
  3. 确认文件不存在旧版孤立死代码行（如 `$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive`，P7-05）与无效对象创建（如 `New-Object System.Data.Common.DbProviderFactory`，P7-06）
- **预期结果**：
  1. errors 为空，语法解析通过，无任何语法错误
  2. 死代码行已删除，无 P7-05/P7-06 残留
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`（统一入口），断言 UT-152-1（ParseFile 无语法错误）、UT-152-2（无 P7-05/P7-06 死代码）
- **测试过程与结论**：writetest 试运行 UT-152-1/2 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-153：deploy-check-env.sh 语法校验（bash -n）（P0）
- **用例ID**：UT-153
- **用例名称**：对 deploy/scripts/deploy-check-env.sh 执行 `bash -n` 语法校验通过（退出码 0、无输出）；环境无 bash 时降级为 shebang + 文件非空 + 关键结构（if/fi、函数定义）配对核对
- **所属模块**：deploy/scripts / deploy-check-env.sh 语法
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env.sh 已按 F-010/F-011 契约重构
- **测试类型**：单元测试（语法校验）
- **关联需求ID**：US-001 / F-010 / F-011 / UT-142-2 基线
- **测试数据**：`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 执行 `bash -n deploy/scripts/deploy-check-env.sh`，检查退出码与输出
  2. 无 bash 环境时：核对 shebang（`#!/usr/bin/env bash`）、文件非空、`if ... fi` 配对、函数定义完整、数组参数写法（无 eval 拼接）
  3. 确认版本号标注为 v0.2.7（G9，非陈旧 v0.1.7）
- **预期结果**：
  1. bash -n 通过（退出码 0、无输出）；降级核对时 shebang 与结构合格
  2. 版本号标注 v0.2.7
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-153-1（bash -n 不可用时降级结构核对通过）、UT-153-2（.sh 版本号 v0.2.7）
- **测试过程与结论**：writetest 试运行 UT-153-1/2 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-154：deploy-check-env 双平台脚本成对存在且检查项一一对应（P1）
- **用例ID**：UT-154
- **用例名称**：确认 deploy-check-env.ps1 与 deploy-check-env.sh 成对存在（UT-143-1 基线），且双平台检查项结构一一对应：可用性检查（JDK/MariaDB/Redis/Nacos 四项）+ 运行状态检测（JDK 就绪/MariaDB/Redis/Nacos 四项），无一方多出/缺少检查项
- **所属模块**：deploy/scripts / 双平台一致性
- **优先级**：P1
- **前置条件**：TASK-003 编码完成，双版本脚本均已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-010 / F-011 / UT-143-1 基线
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 检查两个文件是否均存在（Test-Path）
  2. 分别提取两平台可用性检查项（JDK/MariaDB/Redis/Nacos）与运行状态检测项（JDK/MariaDB/Redis/Nacos）清单
  3. 比对两平台检查项是否一一对应（名称、判定逻辑、输出分级、退出码语义一致）
- **预期结果**：
  1. 两个文件均存在
  2. 双平台检查项一一对应（不再出现 .ps1 10 项 vs .sh 13 项的结构差异，P4）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-154-1（双文件存在）、UT-154-2（.ps1 检查项结构含可用性+运行状态各四项）、UT-154-3（.sh 检查项结构同）
- **测试过程与结论**：writetest 试运行 UT-154-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-155：deploy-check-env 无硬编码默认地址（P0，安全）
- **用例ID**：UT-155
- **用例名称**：grep 检索 deploy-check-env.ps1 / deploy-check-env.sh，确认重构后无任何硬编码默认地址残留（192.168.1.100 / 192.168.1.101 / 192.168.1.102 等 IP 地址与端口默认值；不再出现 `${VAR:-192.168...}` 或 param 块默认地址，P1 问题清除）
- **所属模块**：deploy/scripts / 硬编码默认地址
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对/grep，安全）
- **关联需求ID**：US-001 / F-010 / F-001 / P1
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. grep 检索 `192\.168\.1\.1[0-9][0-9]` 于两个脚本文件
  2. grep 检索 `${[A-Z_]+:-[0-9]` 与 `param(` 等默认值兜底写法
  3. 确认脚本内连接类地址（NACOS_ADDR/DB_HOST/REDIS_HOST）全部来自 load-env 加载的环境变量，无默认兜底
- **预期结果**：
  1. 两个脚本均无 `192.168.1.1xx` 硬编码地址命中
  2. 无 `${VAR:-默认地址}` 与 param 块默认地址兜底
  3. 配置全部来自 env.json（经 load-env 注入），缺失时由 load-env 或脚本校验报错退出
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-155-1（.ps1 无 192.168.1.1xx）、UT-155-2（.sh 无 192.168.1.1xx）、UT-155-3（双平台均无 `${VAR:-默认}` 与 param 默认地址兜底）
- **测试过程与结论**：writetest 试运行 UT-155-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-156：deploy-check-env 经 load-env 加载配置与关键配置校验静态核对（P0）
- **用例ID**：UT-156
- **用例名称**：静态核对 deploy-check-env.ps1 以 `. $PSScriptRoot\load-env.ps1`、deploy-check-env.sh 以 `source "$SCRIPT_DIR/load-env.sh"` 调用 load-env（F-001 契约），并校验本脚本所需关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失时逐个列出键名并退出非零
- **所属模块**：deploy/scripts / load-env 调用契约
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构；TASK-002 load-env 已交付
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-001 / F-010
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`、`deploy/scripts/load-env.ps1`、`deploy/scripts/load-env.sh`
- **测试步骤**：
  1. 检查 .ps1 是否在脚本开头 dot-source 调用 load-env.ps1（`$PSScriptRoot` 路径拼接）
  2. 检查 .sh 是否在脚本开头 source 调用 load-env.sh（`$SCRIPT_DIR` 路径拼接）
  3. 检查脚本加载后是否校验关键配置项（至少 8 项：NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失时逐个列出键名（不打印值）并以非零码退出
  4. 检查 NACOS_ADDR 格式合法性校验（非 host:port 时输出失败提示检查 env.json，F-005）
- **预期结果**：
  1. 双平台均正确调用 load-env 加载 env.json
  2. 关键配置缺失逐项列出并退出非零
  3. NACOS_ADDR 非法格式有校验分支
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-156-1（.ps1 dot-source load-env.ps1）、UT-156-2（.sh source load-env.sh）、UT-156-3（双平台关键配置校验含 8 项 + NACOS_ADDR 格式校验）
- **测试过程与结论**：writetest 试运行 UT-156-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-157：JDK/MariaDB/Redis/Nacos 可用性检查逻辑静态核对（P0）
- **用例ID**：UT-157
- **用例名称**：静态核对 deploy-check-env 双版本可用性检查逻辑与 F-002~F-005 一致：JDK（`java -version` 含 `version "21` + JAVA_HOME 非空且目录有效合并判定）；MariaDB（命令 mariadb/mysql/mysqld/mariadbd、服务 DB_SERVICE_NAME、进程 DB_PROCESS_NAME 三重安装检测 + SELECT 1 连通性）；Redis（命令 redis-cli/redis-server、服务 REDIS_SERVICE_NAME、进程 REDIS_PROCESS_NAME 三重检测 + redis-cli ping 返回 PONG）；Nacos（NACOS_HOME 存在且 bin/startup.cmd|sh 存在 + HTTP 探测 `http://NACOS_ADDR/nacos/` 含 "Nacos"）
- **所属模块**：deploy/scripts / 可用性检查逻辑
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-002 / F-003 / F-004 / F-005
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 检查 JDK 检查是否合并「命令可执行 + JAVA_HOME 有效 + 版本 21」为一项可用性结论（任一失败输出"失败"并提示安装 JDK 21 / 配置 JAVA_HOME）
  2. 检查 MariaDB 是否含命令/服务/进程三重安装检测（服务与进程名支持逗号分隔多值）与 SELECT 1 连通性检测
  3. 检查 Redis 是否含命令/服务/进程三重安装检测与 redis-cli ping 返回 PONG 判定
  4. 检查 Nacos 是否含 NACOS_HOME + bin/startup.cmd|sh 安装检测与 HTTP 探测（`http://NACOS_ADDR/nacos/` 含 "Nacos"）可用性判定
  5. 确认无 Maven/Git/pom.xml/SQL/Maven settings 等无关检查项（F-010）或已降为可选信息（不参与计数）
- **预期结果**：
  1. 四项可用性检查逻辑与 F-002~F-005 完全对齐
  2. 无关检查项已移除或降为可选信息
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-157-1（JDK 合并判定+版本 21+JAVA_HOME 有效）、UT-157-2（MariaDB 三重安装+SELECT 1）、UT-157-3（Redis 三重安装+ping PONG）、UT-157-4（Nacos NACOS_HOME+startup+HTTP 含 Nacos）、UT-157-5（无 Maven/Git/pom.xml/SQL 无关检查项）
- **测试过程与结论**：writetest 试运行 UT-157-1~5 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-158：Nacos 已安装未启动计"警告（未运行）"逻辑静态核对（P0）
- **用例ID**：UT-158
- **用例名称**：静态核对 deploy-check-env 双版本 Nacos 判定逻辑：NACOS_HOME 存在且 bin/startup.cmd|sh 存在（已安装）但 HTTP 探测失败时输出"警告（未运行）"而非"失败/未安装"（F-005 关键规则），运行状态与可用性分开输出
- **所属模块**：deploy/scripts / Nacos 判定逻辑
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-005 / F-006 / P4
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 检查脚本 Nacos 安装检测分支：NACOS_HOME 存在且 startup.cmd|sh 存在 → 判定"已安装"
  2. 检查已安装但 HTTP 探测失败时的输出分级是否为"警告"且文案含"未运行"
  3. 检查未安装（NACOS_HOME 缺失或 startup 脚本缺失）时是否输出"失败"并提示安装 Nacos / 配置 NACOS_HOME
  4. 检查运行状态输出是否与可用性输出分开（未运行/运行中/未安装三态）
- **预期结果**：
  1. 已安装未启动 → "警告（未运行）"，计入警告计数，不计失败、不计未安装
  2. 未安装 → "失败"并提示处理建议
  3. 可用性状态与运行状态分开输出
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-158-1（已安装判定 NACOS_HOME+startup）、UT-158-2（已安装未启动→警告+未运行文案）、UT-158-3（未安装→失败+安装提示）、UT-158-4（可用性/运行状态分开输出）
- **测试过程与结论**：writetest 试运行 UT-158-1~4 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-159：运行状态检测逻辑静态核对（F-006）（P1）
- **用例ID**：UT-159
- **用例名称**：静态核对 deploy-check-env 双版本运行状态检测逻辑：JDK 复用可用性结论视为"就绪"；MariaDB/Redis 进程（DB_PROCESS_NAME/REDIS_PROCESS_NAME）存在、系统服务（DB_SERVICE_NAME/REDIS_SERVICE_NAME）Running、或 TCP 端口（3306/6379）可达任一命中即"运行中"；Nacos HTTP 探测含 "Nacos" 即"运行中"，探测失败再检测 java 进程命令行含 nacos 作辅助判断
- **所属模块**：deploy/scripts / 运行状态检测逻辑
- **优先级**：P1
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-006 / P4
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 检查 JDK 运行状态是否复用可用性结论（可用即"就绪"，无独立启动检查）
  2. 检查 MariaDB/Redis 运行状态是否实现「进程/服务/TCP 端口任一命中即运行中」
  3. 检查 Nacos 运行状态是否以 HTTP 探测为主、java 进程命令行含 nacos 为辅助
  4. 检查 .ps1 用 Get-Process/Get-Service/TcpClient（或 Test-NetConnection），.sh 用 pgrep/systemctl（或 service）/`/dev/tcp`（或 nc），平台命令适配正确
- **预期结果**：
  1. 运行状态检测覆盖 JDK/MariaDB/Redis/Nacos 四项且逻辑与 F-006 一致
  2. 双平台检测手段各自适配（Windows PowerShell / Linux Bash）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-159-1（JDK 复用可用性→就绪）、UT-159-2（MariaDB/Redis 进程/服务/TCP 任一命中）、UT-159-3（Nacos HTTP 为主+java 进程辅助）、UT-159-4（平台命令适配 Get-Process/Get-Service 与 pgrep/systemctl//dev/tcp）
- **测试过程与结论**：writetest 试运行 UT-159-1~4 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-160：输出分级（通过/警告/失败）与退出码约定静态核对（P1）
- **用例ID**：UT-160
- **用例名称**：静态核对 deploy-check-env 双版本输出与退出码契约（F-011）：输出三级分级（通过绿色/警告黄色/失败红色；汇总显示通过/警告/失败计数）；退出码约定（全部通过退出 0；存在失败项退出非零 1；存在警告但无失败退出 0 并提示警告）；.ps1 用 Write-Host + 颜色、.sh 用 printf + ANSI（无 ANSI 环境可降级为纯文本前缀）
- **所属模块**：deploy/scripts / 输出分级与退出码
- **优先级**：P1
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-011 / P5
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 检查输出函数是否实现"通过/警告/失败"三级分级（非仅两级）
  2. 检查汇总是否显示通过/警告/失败计数
  3. 检查退出码逻辑：失败>0 → exit 1；警告>0 且失败=0 → exit 0 并提示警告；全通过 → exit 0
  4. 检查 .sh 是否避免 `eval` 拼接命令（改用数组参数，P7-10）
- **预期结果**：
  1. 三级输出分级与计数齐全
  2. 退出码约定与 F-011 一致
  3. .sh 无 eval 拼接，无注入/口令泄露风险
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-160-1（三级分级+汇总计数）、UT-160-2（退出码约定）、UT-160-3（.ps1 Write-Host 颜色）、UT-160-4（.sh printf+ANSI 且无 eval 拼接）
- **测试过程与结论**：writetest 试运行 UT-160-1~4 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-161：口令掩码不打印明文静态核对（P0，安全）
- **用例ID**：UT-161
- **用例名称**：静态核对 deploy-check-env 双版本口令处理：脚本输出/日志不得打印 DB_PASSWORD、REDIS_PASSWORD 明文；口令在命令中以掩码显示（如 `-p****`）或不出现（Redis 用 REDISCLI_AUTH 环境变量）；命令构造避免 eval 拼接；无含明文密码的连接字符串/死代码（P7-06）
- **所属模块**：deploy/scripts / 口令掩码安全
- **优先级**：P0
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对，安全）
- **关联需求ID**：US-001 / F-003 / F-004 / F-001 / P7-10
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. grep 检索脚本内是否直接输出 `$env:DB_PASSWORD`/`$DB_PASSWORD`/`$env:REDIS_PASSWORD`/`$REDIS_PASSWORD` 明文到 Write-Host/printf/echo
  2. 检查 MariaDB 命令构造是否含明文口令（如 `-p"$DB_PASSWORD"` 直接拼入日志）——正确做法为数组参数/掩码显示
  3. 检查 Redis 是否优先使用 REDISCLI_AUTH 环境变量传递口令（Bash）或等效方式（PowerShell）
  4. 检查是否无 `eval` 拼接命令、无含明文密码的连接字符串（`$connStr`）死代码
- **预期结果**：
  1. 脚本输出不含任何口令明文
  2. 口令传递方式安全（数组参数/环境变量），无 eval 拼接
  3. 无明文连接字符串死代码
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-161-1（无明文口令输出路径）、UT-161-2（命令构造掩码/数组参数）、UT-161-3（无 eval 拼接、无 $connStr 死代码）
- **测试过程与结论**：writetest 试运行 UT-161-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-162：无关检查项移除与死代码清理静态核对（P1）
- **用例ID**：UT-162
- **用例名称**：静态核对 deploy-check-env 双版本已移除与"可用性检查 + 运行状态检查"无关的检查项（Maven 版本/Git 版本/pom.xml 存在性/SQL 脚本存在性/Maven settings，F-010），并清理死代码（P7-05 孤立行、P7-06 无效 DbProviderFactory）
- **所属模块**：deploy/scripts / 检查范围收敛
- **优先级**：P1
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-010 / P4 / P7-05 / P7-06
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. grep 检索 `mvn -version`、`git version`、`pom.xml`、`settings.xml`、`auth-init` 等无关检查关键字，确认已移除或降为可选信息（不参与计数）
  2. grep 检索 `DbProviderFactory`、`CurrentFileSystemDrive`、`$connStr` 等死代码关键字，确认已删除
  3. 确认 Nacos 不再重复 HTTP 探测（可用性探测与连通性检查重复，P4）
- **预期结果**：
  1. 无关检查项已移除或降为可选信息
  2. 死代码全部清理
  3. Nacos 探测无重复
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-162-1（无 Maven/Git/pom.xml/SQL 无关项参与计数）、UT-162-2（无 DbProviderFactory/CurrentFileSystemDrive/$connStr 死代码）、UT-162-3（Nacos 可用性探测无重复 HTTP）
- **测试过程与结论**：writetest 试运行 UT-162-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### UT-163：文件头 SPDX 版权头、简体中文注释与版本号标注（P1）
- **用例ID**：UT-163
- **用例名称**：静态核对 deploy-check-env.ps1 / deploy-check-env.sh 文件头保留 `# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`（G10/P7-14），注释为简体中文（F-011），版本号统一标注 v0.2.7（G9/P7-13）
- **所属模块**：deploy/scripts / 文件规范
- **优先级**：P1
- **前置条件**：TASK-003 编码完成，deploy-check-env 双版本已重构
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-001 / F-011 / P7-13 / P7-14
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`
- **测试步骤**：
  1. 读取两文件头 3~10 行，核对 SPDX-License-Identifier 与版权声明存在
  2. 抽查脚本内注释语言为简体中文
  3. 核对版本号标注为 v0.2.7（非 v0.1.7 陈旧版本）
- **预期结果**：
  1. SPDX 版权头存在（Apache-2.0）
  2. 注释为简体中文
  3. 版本号标注 v0.2.7
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 UT-163-1（.ps1 文件头 SPDX+版本号）、UT-163-2（.sh 文件头 SPDX+版本号）、UT-163-3（双平台注释为简体中文）
- **测试过程与结论**：writetest 试运行 UT-163-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

### 模块：接口测试（API 契约与健康检查）
#### TC-082：本任务无接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-082
- **用例名称**：本任务为部署脚本重构（deploy-check-env.ps1/.sh），不涉及后端 API 接口变更；核对 docs/cso-api.md 中 API-001~API-033 契约完整保留，git 变更清单中无 backend 接口实现文件（Java Controller/Service/Mapper/网关路由）改动
- **所属模块**：接口契约 / API 回归
- **优先级**：P1
- **前置条件**：TASK-003 变更范围已确定（git 变更清单可核对）
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-001 / API-001~API-033 保留
- **测试数据**：docs/cso-api.md、git 变更清单（`git diff --name-status` + `git status --porcelain`）
- **测试步骤**：
  1. 执行 git 命令获取变更文件清单
  2. 检查清单中是否出现 backend 接口实现文件（*.java Controller/Service/Mapper、网关路由配置、pom.xml 依赖变更）
  3. 核对 docs/cso-api.md 声明 API-001~API-033 完整保留
- **预期结果**：
  1. 变更清单仅含 deploy/scripts/deploy-check-env.ps1、deploy-check-env.sh、docs 文档与测试脚本，无 backend 接口实现改动
  2. API-001~API-033 契约完整保留，既有接口不受影响
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py`，断言 TC-082-1（git 变更清单无 backend Java/网关路由/pom 改动）、TC-082-2（docs/cso-api.md 保留 API-001~API-033）、TC-082-3（变更仅含 deploy 脚本与 docs/scripts）
- **测试过程与结论**：writetest 试运行 TC-082-1/2/3 均 PASS；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### TC-083：基础设施健康检查端点探活（可选，环境依赖）（P2）
- **用例ID**：TC-083
- **用例名称**：对已启动的 backend 服务健康检查端点进行 HTTP 探活（网关 9000 `/api/v1/gateway/health`、auth 9100 `/api/v1/auth/health`），确认基础设施（MariaDB/Redis/Nacos）就绪后服务正常对外（环境依赖，服务未启动按环境 SKIP）
- **所属模块**：接口契约 / 健康检查探活
- **优先级**：P2
- **前置条件**：backend 服务已启动（本机 9000/9100 等端口开放）
- **测试类型**：接口测试（动态探活）
- **关联需求ID**：US-001 / SAD 部署架构（health 端点契约）
- **测试数据**：`http://127.0.0.1:9000/api/v1/gateway/health`、`http://127.0.0.1:9100/api/v1/auth/health`
- **测试步骤**：
  1. 向 9000 端口网关 health 端点发送 HTTP GET
  2. 向 9100 端口 auth health 端点发送 HTTP GET
  3. 检查响应 HTTP 状态码与响应体是否含 code=200、status=UP 等健康标志
- **预期结果**：
  1. 两个端点 HTTP 200 且健康标志正常（服务可用）
  2. 若服务未启动按环境阻塞 SKIP 记录，不作为失败
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py`，断言 TC-083-1（网关 9000 health HTTP 200 + 健康标志）、TC-083-2（auth 9100 health HTTP 200 + 健康标志）
- **测试过程与结论**：writetest 试运行 TC-083-1/2 均 PASS（本机 auth 9100 与网关 9000 健康检查可达）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

### 模块：deploy-check-env 功能测试（动态场景与退出码验证）
#### FT-078：JDK 可用性检查通过场景——java 21 + JAVA_HOME 有效（P0）
- **用例ID**：FT-078
- **用例名称**：执行 deploy-check-env（本机 JDK 21 + JAVA_HOME 有效），JDK 可用性检查输出"通过"，汇总包含 JDK 通过项，退出码符合约定（无失败时 0）
- **所属模块**：deploy/scripts / JDK 可用性检查（F-002）
- **优先级**：P0
- **前置条件**：本机安装 JDK 21，JAVA_HOME 已设置且指向有效目录；deploy/env.json 存在且配置完整（经 load-env 可加载）
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-002 / AC-1
- **测试数据**：`deploy/env.json`（真实配置）、`deploy/scripts/deploy-check-env.ps1`（Windows 执行；.sh 在有 bash/WSL 环境执行）
- **测试步骤**：
  1. 执行 `deploy/scripts/deploy-check-env.ps1`（或 .sh）
  2. 观察 JDK 检查输出分级与提示
  3. 记录退出码
- **预期结果**：
  1. JDK 检查输出"通过"（命令可执行 + JAVA_HOME 有效 + 版本 21 命中）
  2. JDK 运行状态显示"就绪"
  3. 退出码符合 F-011 约定（JDK 通过且无其他失败时 0）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，动态执行 `. $checkEnvPs1`（子进程捕获 UTF-8 输出与退出码），断言 FT-078-1
- **测试过程与结论**：writetest 试运行 **FT-078-1 PASS**（本机 JDK 21 + JAVA_HOME 有效，JDK 通过+就绪）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-079：JDK 缺失/版本非 21 场景——输出失败并提示，退出码非零（P0）
- **用例ID**：FT-079
- **用例名称**：构造 JDK 缺失或版本非 21 场景（临时移除 java 命令路径 / 将 JAVA_HOME 指向无效目录 / 模拟 `java -version` 输出非 21），执行 deploy-check-env，JDK 可用性检查输出"失败"并给出处理提示（安装 JDK 21 / 配置 JAVA_HOME），脚本退出码非零
- **所属模块**：deploy/scripts / JDK 可用性检查（F-002）
- **优先级**：P0
- **前置条件**：可临时调整 PATH/JAVA_HOME 环境变量（测试后还原）；deploy/env.json 配置完整
- **测试类型**：功能测试（动态执行，失败路径）
- **关联需求ID**：US-001 / F-002 / AC-2
- **测试数据**：测试用临时 PATH/JAVA_HOME（不含 java 21 或指向无效目录）
- **测试步骤**：
  1. 备份当前 JAVA_HOME 与 PATH，将其修改为不含 JDK 21 或指向无效目录（或模拟 java 版本输出非 21）
  2. 执行 deploy-check-env，观察 JDK 检查输出
  3. 记录退出码
  4. 还原 JAVA_HOME 与 PATH
- **预期结果**：
  1. JDK 检查输出"失败"并提示安装 JDK 21 / 配置 JAVA_HOME
  2. 脚本退出码非零（1），计入失败汇总
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，子进程 PreCmd 设置 `JAVA_HOME=C:\__cso_invalid_jdk__`（无效目录），断言 FT-079-1
- **测试过程与结论**：writetest 试运行 **FT-079-1 PASS**（JAVA_HOME 指向无效目录→JDK 失败+安装提示+退出码非零）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-080：MariaDB 可用性检查通过场景——SELECT 1 成功（P0）
- **用例ID**：FT-080
- **用例名称**：执行 deploy-check-env（本机 MariaDB 已安装并运行，DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD 正确），MariaDB 可用性检查输出"通过"（安装检测命中 + SELECT 1 成功），运行状态显示"运行中"
- **所属模块**：deploy/scripts / MariaDB 可用性检查（F-003）
- **优先级**：P0
- **前置条件**：本机 MariaDB/MySQL 已安装并运行；deploy/env.json 中 DB_* 配置正确
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-003 / AC-1
- **测试数据**：`deploy/env.json`（真实 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME）
- **测试步骤**：
  1. 执行 deploy-check-env
  2. 观察 MariaDB 可用性检查输出（安装检测 + SELECT 1）
  3. 观察 MariaDB 运行状态输出；记录退出码
- **预期结果**：
  1. MariaDB 输出"通过"（命令/服务/进程任一命中已安装，SELECT 1 成功可连接）
  2. 运行状态显示"运行中"（进程/服务/TCP 任一命中）
  3. 退出码符合约定
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 FT-080-1
- **测试过程与结论**：writetest 试运行 **FT-080-1 SKIP**（本机无 mariadb/mysql 客户端命令可执行 SELECT 1，环境门控；MariaDB 安装/连通逻辑由 UT-157-2/UT-161 静态兜底）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-081：MariaDB 已安装但不可连接场景——输出失败并提示连接参数（P0）
- **用例ID**：FT-081
- **用例名称**：构造 MariaDB 已安装但不可连接场景（临时将 DB_PORT 指向未监听端口 / 将 DB_USERNAME 或 DB_PASSWORD 改为错误值），执行 deploy-check-env，MariaDB 安装检测通过但 SELECT 1 失败，输出"失败"并提示检查 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD，脚本退出码非零
- **所属模块**：deploy/scripts / MariaDB 可用性检查（F-003）
- **优先级**：P0
- **前置条件**：本机 MariaDB 已安装（安装检测可命中）；可临时构造错误连接参数（测试后还原 env.json 或使用测试 env 文件）
- **测试类型**：功能测试（动态执行，失败路径）
- **关联需求ID**：US-001 / F-003 / AC-2
- **测试数据**：测试用错误 DB_PORT（如 13306）或错误 DB_PASSWORD；注意不得在日志中打印口令明文
- **测试步骤**：
  1. 备份 env.json，将 DB_PORT 改为未监听端口（或 DB_PASSWORD 改为错误值）
  2. 执行 deploy-check-env，观察 MariaDB 检查输出
  3. 记录退出码；还原 env.json
- **预期结果**：
  1. MariaDB 安装检测命中（已安装）但连通性失败，输出"失败"并提示检查连接参数
  2. 脚本退出码非零（1）
  3. 输出中不出现口令明文
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 FT-081-1
- **测试过程与结论**：writetest 试运行 **FT-081-1 SKIP**（本机无 mariadb/mysql 客户端命令可构造 SELECT 1 失败场景，环境门控；失败提示逻辑由 UT-157-2/UT-161 静态兜底）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-082：Redis 可用性检查通过场景——ping 返回 PONG（P0）
- **用例ID**：FT-082
- **用例名称**：执行 deploy-check-env（本机 Redis 已安装并运行），Redis 可用性检查输出"通过"（安装检测命中 + redis-cli ping 返回 PONG），运行状态显示"运行中"
- **所属模块**：deploy/scripts / Redis 可用性检查（F-004）
- **优先级**：P0
- **前置条件**：本机 Redis 已安装并运行；deploy/env.json 中 REDIS_HOST/REDIS_PORT 正确（REDIS_PASSWORD 为空或正确）
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-004 / AC-1
- **测试数据**：`deploy/env.json`（真实 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME）
- **测试步骤**：
  1. 执行 deploy-check-env
  2. 观察 Redis 可用性检查输出（安装检测 + ping PONG）
  3. 观察 Redis 运行状态输出；记录退出码
- **预期结果**：
  1. Redis 输出"通过"（命令/服务/进程任一命中已安装，ping 返回 PONG）
  2. 运行状态显示"运行中"
  3. 退出码符合约定
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 FT-082-1
- **测试过程与结论**：writetest 试运行 **FT-082-1 SKIP**（本机无 redis-cli 客户端命令可执行 ping，环境门控；Redis 安装/连通逻辑由 UT-157-3/UT-161 静态兜底）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-083：Redis 已安装但 ping 不通场景——输出失败并提示（P0）
- **用例ID**：FT-083
- **用例名称**：构造 Redis 已安装但 ping 不通场景（临时将 REDIS_PORT 改为未监听端口 / REDIS_PASSWORD 改为错误值），执行 deploy-check-env，Redis 安装检测通过但 ping 失败，输出"失败"并提示检查 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD，脚本退出码非零
- **所属模块**：deploy/scripts / Redis 可用性检查（F-004）
- **优先级**：P0
- **前置条件**：本机 Redis 已安装（安装检测可命中）；可临时构造错误连接参数（测试后还原）
- **测试类型**：功能测试（动态执行，失败路径）
- **关联需求ID**：US-001 / F-004 / AC-2
- **测试数据**：测试用错误 REDIS_PORT（如 16379）或错误 REDIS_PASSWORD
- **测试步骤**：
  1. 备份 env.json，将 REDIS_PORT 改为未监听端口（或 REDIS_PASSWORD 改为错误值）
  2. 执行 deploy-check-env，观察 Redis 检查输出
  3. 记录退出码；还原 env.json
- **预期结果**：
  1. Redis 安装检测命中但 ping 失败，输出"失败"并提示检查 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD
  2. 脚本退出码非零（1）
  3. 输出中不出现口令明文
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，断言 FT-083-1
- **测试过程与结论**：writetest 试运行 **FT-083-1 SKIP**（本机无 redis-cli 客户端命令可构造 ping 失败场景，环境门控；失败提示逻辑由 UT-157-3/UT-161 静态兜底）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-084：Nacos 已安装未启动场景——计"警告（未运行）"而非未安装（P0）
- **用例ID**：FT-084
- **用例名称**：NACOS_HOME 存在且 bin/startup.cmd|sh 存在（已安装）但 Nacos 服务未启动（HTTP 探测失败）场景，执行 deploy-check-env，Nacos 检查输出"警告（未运行）"而非"失败/未安装"，计入警告计数；存在警告但无失败时退出码为 0 并提示有警告
- **所属模块**：deploy/scripts / Nacos 判定（F-005 关键规则）
- **优先级**：P0
- **前置条件**：NACOS_HOME 指向含 bin/startup.cmd|sh 的 Nacos 安装目录，且 Nacos 服务未启动（8848 端口未开放）；其余环境正常
- **测试类型**：功能测试（动态执行，警告路径）
- **关联需求ID**：US-001 / F-005 / F-006 / AC 边界情况
- **测试数据**：`deploy/env.json`（NACOS_HOME 指向已安装目录；确保 8848 未监听）
- **测试步骤**：
  1. 确认 NACOS_HOME 指向含 bin/startup.cmd|sh 的目录且 Nacos 未启动（8848 未开放）
  2. 执行 deploy-check-env，观察 Nacos 可用性/运行状态输出
  3. 记录汇总计数与退出码
- **预期结果**：
  1. Nacos 输出"警告（未运行）"（已安装未启动），计入警告计数，不计失败、不计未安装
  2. 运行状态显示"未运行"（供 F-007 启动衔接）
  3. 存在警告但无失败时退出码 0 并提示有警告
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，子进程 PreCmd 设置 `NACOS_ADDR=127.0.0.1:48848`（未监听端口，NACOS_HOME 仍指向已安装目录），断言 FT-084-1
- **测试过程与结论**：writetest 试运行 **FT-084-1 PASS**（NACOS_HOME 已安装 + 48848 探测失败→警告（未运行）+ 汇总 warn≥1 + 退出码 0 并提示警告）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-085：Nacos 未安装场景——输出失败并提示（P0）
- **用例ID**：FT-085
- **用例名称**：NACOS_HOME 目录不存在或 bin/startup.cmd|sh 缺失（未安装）场景，执行 deploy-check-env，Nacos 可用性检查输出"失败"并提示安装 Nacos / 配置 NACOS_HOME，脚本退出码非零
- **所属模块**：deploy/scripts / Nacos 可用性检查（F-005）
- **优先级**：P0
- **前置条件**：可临时将 NACOS_HOME 指向不存在目录（测试后还原）
- **测试类型**：功能测试（动态执行，失败路径）
- **关联需求ID**：US-001 / F-005 / AC-2
- **测试数据**：测试用 NACOS_HOME（指向不存在目录）
- **测试步骤**：
  1. 备份 env.json，将 NACOS_HOME 改为不存在目录（或缺失 startup 脚本）
  2. 执行 deploy-check-env，观察 Nacos 检查输出
  3. 记录退出码；还原 env.json
- **预期结果**：
  1. Nacos 输出"失败"并提示安装 Nacos / 配置 NACOS_HOME
  2. 脚本退出码非零（1）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，子进程 PreCmd 设置 `NACOS_HOME=C:\__cso_invalid_nacos__`（不存在目录），断言 FT-085-1
- **测试过程与结论**：writetest 试运行 **FT-085-1 PASS**（NACOS_HOME 无效→Nacos 失败+安装/配置提示+退出码非零）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-086：Nacos 运行中场景——可用性与运行状态均通过（P1）
- **用例ID**：FT-086
- **用例名称**：Nacos 已安装并已启动（HTTP 探测 `http://NACOS_ADDR/nacos/` 响应含 "Nacos"）场景，执行 deploy-check-env，Nacos 可用性输出"通过"且运行状态显示"运行中"
- **所属模块**：deploy/scripts / Nacos 可用性与运行状态（F-005/F-006）
- **优先级**：P1
- **前置条件**：Nacos 2.3 已安装并启动（8848 端口开放，控制台可访问）；NACOS_ADDR/NACOS_HOME 正确
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-005 / F-006
- **测试数据**：`deploy/env.json`（NACOS_ADDR=127.0.0.1:8848、NACOS_HOME 指向已安装目录）
- **测试步骤**：
  1. 确认 Nacos 已启动（浏览器或 curl 访问 `http://127.0.0.1:8848/nacos/` 响应含 "Nacos"）
  2. 执行 deploy-check-env，观察 Nacos 可用性与运行状态输出
  3. 记录退出码
- **预期结果**：
  1. Nacos 可用性输出"通过"（已安装 + HTTP 探测成功）
  2. 运行状态显示"运行中"
  3. 退出码符合约定
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，HTTP 探测 `http://NACOS_ADDR/nacos/` 含 "Nacos" 后动态执行，断言 FT-086-1
- **测试过程与结论**：writetest 试运行 **FT-086-1 PASS**（本机 Nacos 已运行：8848 探测响应含 Nacos，可用性通过+运行状态运行中）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-087：env.json 缺失/关键配置不完整场景——提示复制 env.example.json 并退出非零（P0）
- **用例ID**：FT-087
- **用例名称**：deploy/env.json 缺失（临时移走）或关键配置不完整（删除 NACOS_ADDR/DB_HOST 等键）场景，执行 deploy-check-env，脚本（经 load-env 兜底）输出明确错误提示（复制 env.example.json 为 env.json 并填写配置 / 逐个列出缺失项）并以非零码退出
- **所属模块**：deploy/scripts / 配置加载与校验（F-001）
- **优先级**：P0
- **前置条件**：可临时移走 deploy/env.json 或构造缺失键的测试 env 文件（测试后还原）
- **测试类型**：功能测试（动态执行，失败路径）
- **关联需求ID**：US-001 / F-001 / AC-3
- **测试数据**：测试用 env 文件（缺失关键键）或临时移走 deploy/env.json
- **测试步骤**：
  1. 备份 deploy/env.json；移走它（或构造缺失 NACOS_ADDR/DB_HOST 等键的测试 env 文件并用 load-env -EnvFile 指向）
  2. 执行 deploy-check-env，观察输出
  3. 记录退出码；还原 deploy/env.json
- **预期结果**：
  1. 输出明确错误提示（复制 env.example.json 并填写配置 / 逐项列出缺失键名，不打印值）
  2. 脚本以非零码退出
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，try/finally 备份还原真实 deploy/env.json，断言 FT-087-1
- **测试过程与结论**：writetest 试运行 **FT-087-1 PASS**（移走 env.json 后输出复制 env.example.json+填写提示且退出码非零；原文件已还原）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-088：运行状态检测场景——MariaDB/Redis 进程/服务/TCP 任一命中判定运行中（P1）
- **用例ID**：FT-088
- **用例名称**：在本机执行 deploy-check-env，验证运行状态检测：JDK 复用可用性结论显示"就绪"；MariaDB/Redis 通过进程（DB_PROCESS_NAME/REDIS_PROCESS_NAME）或系统服务（DB_SERVICE_NAME/REDIS_SERVICE_NAME）或 TCP 端口（3306/6379）任一命中判定"运行中"；Nacos 以 HTTP 探测为准
- **所属模块**：deploy/scripts / 运行状态检测（F-006）
- **优先级**：P1
- **前置条件**：本机 MariaDB/Redis 正常运行；deploy/env.json 配置完整
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-006 / AC-1
- **测试数据**：`deploy/env.json`（DB_PROCESS_NAME/REDIS_PROCESS_NAME/DB_SERVICE_NAME/REDIS_SERVICE_NAME 等）
- **测试步骤**：
  1. 执行 deploy-check-env
  2. 观察 JDK 运行状态输出（应为"就绪"）
  3. 观察 MariaDB/Redis 运行状态输出（应为"运行中"）
  4. 观察 Nacos 运行状态输出（以 HTTP 探测结果为准）
- **预期结果**：
  1. JDK 显示"就绪"（复用可用性结论）
  2. MariaDB/Redis 显示"运行中"（进程/服务/TCP 任一命中）
  3. Nacos 显示与 HTTP 探测一致的状态
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，动态执行并按探测结果逐项断言，断言 FT-088-1/2/3
- **测试过程与结论**：writetest 试运行 **FT-088-1 PASS（JDK 就绪）、FT-088-2 PASS（MariaDB 运行中：进程 mysqld/mariadbd + 3306 可达）、FT-088-3 PASS（Redis 运行中：redis-server 进程 + 6379 可达）**；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-089：输出分级汇总与退出码约定——全通过 0 / 有失败 1 / 有警告无失败 0（P0）
- **用例ID**：FT-089
- **用例名称**：执行 deploy-check-env，验证输出分级汇总与退出码约定（F-011）：输出含"通过/警告/失败"三级分级与计数；退出码——全部通过退出 0；存在失败项退出 1；存在警告但无失败退出 0 并提示警告
- **所属模块**：deploy/scripts / 输出分级与退出码（F-011）
- **优先级**：P0
- **前置条件**：deploy/env.json 配置完整，可构造全通过/有失败/有警告三类场景
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-011 / R-02 / R-03
- **测试数据**：`deploy/env.json`（正常配置 + 临时错误配置构造失败/警告场景）
- **测试步骤**：
  1. 正常环境下执行 deploy-check-env，观察输出分级与计数，记录退出码（预期 0，无警告无失败）
  2. 构造失败场景（如临时改错 DB_PORT）执行，记录退出码（预期 1，存在失败项）
  3. 构造警告场景（Nacos 已安装未启动）执行，记录退出码（预期 0 并提示警告）
- **预期结果**：
  1. 输出含"通过/警告/失败"三级与计数汇总
  2. 退出码约定：全通过 0 / 有失败 1 / 有警告无失败 0 并提示警告
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，解析汇总行 `Parse-SummaryLine` 并按退出码契约断言，断言 FT-089-1
- **测试过程与结论**：writetest 试运行 **FT-089-1 PASS**（三级分级+汇总计数+退出码契约与 F-011 一致）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-090：口令掩码输出检查——脚本输出不含 DB_PASSWORD/REDIS_PASSWORD 明文（P0，安全）
- **用例ID**：FT-090
- **用例名称**：执行 deploy-check-env 并捕获全部输出，检查输出中不含 DB_PASSWORD、REDIS_PASSWORD 明文（真实口令不得出现），口令相关显示均为掩码（`****`）；同时核对脚本内无明文口令输出路径
- **所属模块**：deploy/scripts / 口令掩码（F-003/F-004，安全）
- **优先级**：P0
- **前置条件**：deploy/env.json 含真实 DB_PASSWORD（或测试口令）
- **测试类型**：功能测试（动态执行，安全）
- **关联需求ID**：US-001 / F-003 / F-004 / F-001
- **测试数据**：`deploy/env.json`（真实 DB_PASSWORD/REDIS_PASSWORD）、脚本执行输出
- **测试步骤**：
  1. 执行 deploy-check-env 并将 stdout/stderr 捕获到临时文件
  2. 用测试脚本读取真实 DB_PASSWORD/REDIS_PASSWORD 值
  3. 在捕获输出中检索口令明文是否出现（应不出现）；检查口令相关显示是否为 `****` 掩码
- **预期结果**：
  1. 输出中不含 DB_PASSWORD/REDIS_PASSWORD 明文（含失败/错误提示路径）
  2. 口令参数显示为掩码（`****`）或通过环境变量传递（命令串中无口令）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，捕获输出检索真实口令明文与掩码 `****`（口令处理分支到达时），断言 FT-090-1
- **测试过程与结论**：writetest 试运行 **FT-090-1 PASS**（输出无口令明文；掩码 `****` 在口令处理分支到达时断言条件化）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

#### FT-091：双平台行为一致性验证（P1）
- **用例ID**：FT-091
- **用例名称**：在具备双平台执行能力的环境中，分别执行 deploy-check-env.ps1（Windows PowerShell）与 deploy-check-env.sh（Linux bash/WSL），比对两平台检查项、输出分级、退出码与提示语义一致（F-010/F-011 双平台行为一致）
- **所属模块**：deploy/scripts / 双平台一致性
- **优先级**：P1
- **前置条件**：Windows（PowerShell 5.1）与 Linux（bash）环境可用（WSL 或远程）；deploy/env.json 配置完整
- **测试类型**：功能测试（动态执行）
- **关联需求ID**：US-001 / F-010 / F-011
- **测试数据**：`deploy/scripts/deploy-check-env.ps1`、`deploy/scripts/deploy-check-env.sh`、`deploy/env.json`
- **测试步骤**：
  1. 在 Windows 执行 .ps1，记录各检查项输出分级与退出码
  2. 在 Linux（bash/WSL）执行 .sh，记录各检查项输出分级与退出码
  3. 比对两平台检查项清单、输出分级（通过/警告/失败）与退出码语义是否一致
- **预期结果**：
  1. 双平台检查项一一对应，输出分级与退出码语义一致（正常场景退出码一致）
  2. 提示文案语义一致（简体中文）
  3. 环境无 bash/WSL 时按环境 SKIP 记录，不作为失败（由 UT-154 静态一致性兜底）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`，检测 bash/WSL 可用后执行 .sh 冒烟 + bash -n 对比，断言 FT-091-1
- **测试过程与结论**：writetest 试运行 **FT-091-1 SKIP**（本机无 bash/WSL 环境，按环境 SKIP；双平台一致性由 UT-154/UT-159/UT-160 静态兜底）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

### 模块：UI 测试
#### UIT-019：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-019
- **用例名称**：本任务为 deploy-check-env 部署脚本重构（common 类），客户端应用界面与交互无任何变更（git 变更清单无 `cloudoffice-flutter-app/lib/` 下 .dart 界面文件与客户端配置改动，Web/Windows 客户端零修改可用）
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：TASK-003 变更范围已确定（git 变更清单可核对）
- **测试类型**：UI 测试
- **关联需求ID**：US-001 / AC-3（客户端运行时代码零改动）
- **测试数据**：git 变更清单（`git diff --name-status` + `git status --porcelain`）
- **测试步骤**：
  1. 执行 git 命令获取变更文件清单
  2. 检查清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更
- **自动化测试函数/脚本位置**：功能/UI 测试记录 `docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md` UIT-019 章节（静态核对 git 变更清单）
- **测试过程与结论**：writetest 静态核对 **UIT-019 PASS**（git 变更清单无 cloudoffice-flutter-app 文件）；runtest 步骤确认（2026-08-10 执行：PASS=48/FAIL=0/SKIP=5，退出码 0）

## 三、执行汇总
| 结果 | 数量 | 说明 |
| --- | --- | --- |
| 通过 | 24 | 单元 12（UT-152~163）、接口 2（TC-082/083）、功能 9（FT-078/079/084/085/086/087/088/089/090）、UI 1（UIT-019） |
| 失败 | 0 | — |
| 阻塞 | 0 | — |
| 跳过 | 5 | 功能 5（FT-080/081 缺 mariadb/mysql 客户端命令、FT-082/083 缺 redis-cli 命令、FT-091 缺 bash/WSL）——均按环境 SKIP，不作为失败 |

> 说明：本任务 29 个用例由 writetest 步骤完成自动化脚本编写与断言级试运行（`scripts/API-TEST/cso-unit-test-check-env-v0.2.7.ps1`：PASS=48 / FAIL=0 / SKIP=5；`scripts/API-TEST/cso-api-test-v0.2.7.py`：PASS=17 / FAIL=0 / SKIP=0，含 TASK-001/002/003 全部接口用例）；本机 JDK 21/MariaDB/Redis/Nacos 均运行，FT-078/086/088 通过场景实测；SKIP 均为环境门控（缺客户端命令或 bash/WSL），由 UT-154/157~162 静态核对兜底。**runtest 步骤（2026-08-10）最终执行确认：单元测试脚本实测 PASS=48/FAIL=0/SKIP=5、退出码 0；接口测试脚本实测 PASS=17/FAIL=0/SKIP=0、退出码 0；全部通过，已同步主测试用例文档。**

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 动态场景依赖真实环境（JDK/MariaDB/Redis/Nacos 已装/已启动状态） | FT-078~088 无法精确构造通过/失败/警告场景 | 失败/警告场景通过临时修改 env.json 或 PATH/JAVA_HOME 构造（测试后还原）；环境不支持时按 SKIP 记录并以 UT-157~162 静态核对兜底 |
| 环境无 bash/WSL | UT-153 / FT-091 .sh 动态验证无法执行 | bash -n 降级为 shebang+非空+结构核对；双平台一致性动态对比按环境 SKIP，由 UT-154 静态一致性兜底 |
| 真实 deploy/env.json 含敏感凭据 | FT-080/081/090 动态验证会加载真实凭据 | 仅在本机开发环境执行；成功验证不打印敏感值（脚本自身契约）；FT-090 专项核对输出无口令明文；测试脚本断言仅检查键存在与非空 |
| FT-079/081/083/085/087 需临时改 env.json / PATH / JAVA_HOME | 误操作影响真实环境 | 优先使用 -EnvFile 参数/临时环境变量方式指向测试值，不改动真实 deploy/env.json；确需移走/修改时记录原值并事后还原 |
| Nacos 警告（未运行）场景依赖 8848 端口状态 | FT-084 无法稳定构造 | 执行前确认 8848 未监听（未启动）即满足前置；Nacos 意外启动时按环境 SKIP 记录，由 UT-158 静态逻辑核对兜底 |
| 本任务为重构类，改动面小但影响下游 TASK-008/010 | 重构引入回归 | 双平台静态一致性（UT-154）+ 语法校验（UT-152/153）+ 关键逻辑静态核对（UT-157~162）多重保障 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（自动化测试函数/脚本位置已回标；writetest 断言级试运行 PASS=48/FAIL=0/SKIP=5 + 接口 PASS=17/FAIL=0；**runtest 最终执行确认（2026-08-10）：单元测试 PASS=48/FAIL=0/SKIP=5、接口 PASS=17/FAIL=0/SKIP=0，均退出码 0，全部通过**，TE 签名确认）
- 项目经理（PM）：（待执行）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
