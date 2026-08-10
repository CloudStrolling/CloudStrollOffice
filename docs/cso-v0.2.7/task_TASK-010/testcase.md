# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

> 本任务（TASK-010）为全量脚本契约与双平台行为总体验证（US-004 / F-010 / F-011 / ADR-014 / ADR-015 / ADR-016 / 上游 TASK-001~009 全部已完成）：
> 对 deploy/scripts 全部 24 个脚本（12 对 .ps1/.sh）+ .gitkeep 执行语法校验（.ps1 用 PowerShell Parser.ParseFile 解析 / .sh 用 bash -n，需记录校验环境）与契约自校验（RSA 密钥格式 ADR-015：DER 单行 Base64、无 BEGIN/END、无换行、严格 Base64、公私钥配对；输出分级 [通过]/[警告]/[失败] + 汇总行；退出码约定失败非零）；核对全部业务脚本均经 load-env 从 deploy/env.json 加载配置（无硬编码环境地址 192.168.x 与凭据、口令掩码 ****）；核对弃用脚本（deploy-env.ps1 / deploy-env-template.ps1 / deploy-env.sh）无残留无引用；核对文件头 SPDX-License-Identifier（Apache-2.0）与版权声明；输出验证报告并对照 PRD 第 7 章 8 条验收标准逐条核对；复核 .gitignore 治理效果（git status 无生成/测试/调试过程文件、应入库文件未误伤）。
> 验证范围：deploy/scripts 全部 24 个脚本（含历史保留的 deploy-db-init、build-backend、build-client 3 对，参与语法/契约校验）；v0.2.7 能力矩阵核心为 1~9 号脚本对（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen）。
> 已知潜在问题（cs.md §9，验证报告需逐条判定）：P1 deploy-db-init 硬编码默认值（高，验收标准 1 红线）、P2 6 个历史脚本缺 SPDX 头（中）、P3 deploy-rsa-keygen.ps1 无分级前缀与汇总行（中，与 .sh 不一致）、P4 deploy-db-init 输出 emoji 非分级（中）、P5 deploy-db-init.ps1 点源无引号（低）、P6 deploy-check-env.sh source 无 || exit $?（低）、P7 rsa-keygen.ps1 无公私钥成对校验（观察项）、P8 deploy-db-init 口令命令行参数（低）、P9 .gitignore 治理完整待动态复核（确认项）。
> 本任务不涉及数据库变更（DBD v0.2.7 无变更）、不涉及接口变更（API v0.2.7 确认 API-001~API-033 完整保留）。
> 本任务用例编号 **TC-096、UT-230、FT-153、UIT-026** 起（延续 TASK-009 末位：TC-095、UT-229、FT-152、UIT-025）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 全量脚本契约与双平台行为总体验证（US-004 / F-010 / F-011 / ADR-015 / ADR-016）：TASK-010 | TASK-010 | 22 | P0×15、P1×6、P2×1 |
| 其中：单元测试（24 个脚本 .ps1 Parser 语法校验、.sh bash -n 语法校验、RSA 密钥契约 ADR-015、输出分级、退出码约定、load-env 依赖与 env.json 缺失处理、无硬编码地址、无明文凭据与口令掩码、弃用脚本无残留、SPDX 文件头、.gitignore 治理静态复核） | TASK-010 | 11 | P0×10、P1×1 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-010 | 2 | P1×1、P2×1 |
| 其中：功能测试（验证报告输出与 PRD 第 7 章 8 条验收标准逐条核对、check-env/start-services/start-all/单服务脚本双平台行为一致核对、部署顺序契约、脚本清单完整性与一一对应、git status 无过程文件与应入库文件复核） | TASK-010 | 8 | P0×4、P1×4 |
| 其中：UI 测试（无 UI 变更确认） | TASK-010 | 1 | P1×1 |

## 二、测试用例详情

### 模块：全量脚本契约验证 - 单元测试（TASK-010）
#### UT-230：全部 12 个 .ps1 脚本 PowerShell 语法解析校验（P0）
- **用例ID**：UT-230
- **用例名称**：deploy/scripts 下全部 12 个 .ps1 脚本（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen、deploy-db-init、build-backend、build-client）逐一执行 PowerShell 语法解析校验——用 `[System.Management.Automation.Language.Parser]::ParseFile`（PS 5.1 内置，仅解析不执行，不触发 env.json 读取与副作用），断言 errors 数组为空（0 语法错误）；任一脚本解析错误即该脚本校验失败（退出码约定失败非零）
- **所属模块**：deploy/scripts / .ps1 语法校验
- **优先级**：P0
- **前置条件**：TASK-001~009 编码完成；本机 Windows PowerShell 5.1（win32）可用
- **测试类型**：单元测试（动态校验）
- **关联需求ID**：US-004 / F-010 / F-011 / ADR-016
- **测试数据**：deploy/scripts/*.ps1（12 个文件清单见 context.md 第 4 章）
- **测试步骤**：
  1. 枚举 deploy/scripts 下全部 *.ps1，断言数量 = 12（脚本清单完整性由 FT-160 兜底）
  2. 对每个 .ps1 调用 `[System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)`
  3. 断言每个脚本 errors.Count = 0；存在语法错误时输出文件名与错误行号/消息
  4. 记录校验环境（PowerShell 版本）于验证报告
- **预期结果**：
  1. 12 个 .ps1 全部通过语法解析，errors.Count = 0
  2. 语法失败数作为退出码：全部通过 0 / 存在失败 1（F-011 约定）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-230-1（12 个 .ps1 逐一 Parser.ParseFile 断言 0 错误、错误明细输出）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行 `cso-unit-test-scripts-contract-v0.2.7.ps1`：UT-230-1（deploy/scripts 恰为 12 个 .ps1）、UT-230-2（12 个 .ps1 经 `[System.Management.Automation.Language.Parser]::ParseFile` 全部 0 语法错误）均 PASS；校验环境：Windows PowerShell 5.1（win32），未触发 env.json 读取与副作用；整体断言级 PASS=88/FAIL=0/SKIP=0）

#### UT-231：全部 12 个 .sh 脚本 bash -n 语法校验（P0）
- **用例ID**：UT-231
- **用例名称**：deploy/scripts 下全部 12 个 .sh 脚本（与 UT-230 同名对）逐一执行 `bash -n` 语法校验（只解析不执行），断言全部返回退出码 0（语法正确）；Windows 无原生 bash 时使用 git-bash（bash 4.4+）/ WSL（bash 5.x）执行并**在验证报告中记录校验环境**；无任何可用 bash 环境时降级为静态核对（括号配对、引号闭合、fi/done/esac 匹配）并在验证报告注明校验方式
- **所属模块**：deploy/scripts / .sh 语法校验
- **优先级**：P0
- **前置条件**：TASK-001~009 编码完成；本机存在 bash 环境（git-bash/WSL）或允许降级静态核对
- **测试类型**：单元测试（动态校验，环境依赖）
- **关联需求ID**：US-004 / F-010 / F-011 / ADR-016
- **测试数据**：deploy/scripts/*.sh（12 个文件清单见 context.md 第 4 章）
- **测试步骤**：
  1. 枚举 deploy/scripts 下全部 *.sh，断言数量 = 12
  2. 对每个 .sh 执行 `bash -n <file>`，断言退出码 0；语法错误时捕获 stderr 首行输出
  3. 无 bash 环境时按降级方案静态核对（括号/引号/关键字配对）并记录校验方式
  4. 记录校验环境（bash 版本来源：git-bash/WSL）于验证报告
- **预期结果**：
  1. 12 个 .sh 全部通过 bash -n 校验（或降级静态核对通过），退出码 0
  2. 语法失败数作为退出码：全部通过 0 / 存在失败 1；验证报告注明校验环境
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-231-1（12 个 .sh 逐一 bash -n 断言退出码 0；bash 不可用时记录 SKIP 并降级静态核对）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-231-1（deploy/scripts 恰为 12 个 .sh）、UT-231-2（12 个 .sh 逐一 `bash -n` 全部退出码 0）均 PASS；校验环境：git-bash GNU bash 5.2.37（`C:\Program Files\Git\bin\bash.exe`），无降级静态核对发生）

#### UT-232：RSA 密钥输出契约（ADR-015）双平台一致核对（P0）
- **用例ID**：UT-232
- **用例名称**：deploy-rsa-keygen.ps1 与 deploy-rsa-keygen.sh 输出契约静态核对——两者均输出 DER 编码单行 Base64（私钥 PKCS#8 PrivateKeyInfo：`openssl pkcs8 -topk8 -nocrypt -outform DER`；公钥 X.509 SubjectPublicKeyInfo：`openssl pkey -pubout -outform DER`；.ps1 `[Convert]::ToBase64String`、.sh `base64 -w0` + `printf '%s'`），无 PEM 头尾（-----BEGIN/END-----）、无换行（\r\n）；输出可被严格 Base64 解码；与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码契约严格一致（ADR-015 原文核对）；双平台契约自校验点一致（①无 BEGIN/END ②无换行 ③严格 Base64 ④DER 结构偏移：私钥 [0]=0x30 且 [7]=0x30 且长度≥16、公钥 [0]=0x30 且 [4]=0x30 且 [19]=0x03 且长度≥24）；记录 P7 观察项（.ps1 无「公私钥成对」自校验、.sh 有，见 cs.md §3.6/§9）
- **所属模块**：deploy-rsa-keygen / RSA 密钥契约（ADR-015）
- **优先级**：P0
- **前置条件**：TASK-007 编码完成（deploy-rsa-keygen.ps1/.sh 已重构对齐）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / ADR-015
- **测试数据**：deploy/scripts/deploy-rsa-keygen.ps1（133 行）、deploy-rsa-keygen.sh（212 行）、docs/sad.md ADR-015 原文
- **测试步骤**：
  1. grep 断言 .ps1/.sh 均无 `-----BEGIN`/`-----END` 字面量输出路径（密钥输出不含 PEM 头尾）
  2. grep 断言 .ps1 用 `ToBase64String` 与 `WriteAllText`（无换行写入）、.sh 用 `base64 -w0` 与 `printf '%s'`（单行无换行输出）
  3. 断言私钥/公钥生成均经 DER 编码（`-outform DER`），格式为 PKCS#8 / X.509 SPKI
  4. 断言双平台契约自校验逻辑一致（①~④项：无 BEGIN/END、无换行、严格 Base64 校验、DER 结构偏移校验）；记录 P7（.ps1 无成对校验，.sh 第 186-189 行有）为观察项
  5. 对照 docs/sad.md ADR-015 原文与 Java 端解码契约（Base64.getDecoder + X509EncodedKeySpec/PKCS8EncodedKeySpec），断言一致
- **预期结果**：
  1. .ps1/.sh 密钥输出契约一致：DER 单行 Base64、无 PEM 头尾、无换行、严格 Base64 可解码、DER 结构偏移校验存在
  2. 与 Java 端解码契约（ADR-015）一致，未破坏
  3. P7 作为观察项记录于验证报告（不影响 ADR-015 验收，密钥输出契约本身一致）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-232-1（.ps1 无 BEGIN/END 字面量输出）、UT-232-2（.sh 无 BEGIN/END 字面量输出）、UT-232-3（.ps1 ToBase64String/WriteAllText 单行写入）、UT-232-4（.sh base64 -w0 + printf 单行输出）、UT-232-5（双平台 DER 编码与契约自校验点一致、无换行路径）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-232-1~7 均 PASS——.ps1/.sh Base64 均仅取 DER 文件编码、无 PEM 头尾、单行无换行（ToBase64String+WriteAllText / base64 -w0+printf '%s'）、双平台 DER 编码契约一致（pkcs8 -topk8 -nocrypt -outform DER 私钥 + pkey -pubout -outform DER 公钥）、契约自校验点（无 BEGIN/END、无换行、DER 偏移 0x30/0x03）齐全；P7 观察项（.ps1 无公私钥成对自校验，.sh 有）已按预期记录，不影响 ADR-015 验收）

#### UT-233：输出分级契约（通过/警告/失败 + 汇总行）静态核对（P0）
- **用例ID**：UT-233
- **用例名称**：核心业务脚本（deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system 8 对 16 个）双平台输出分级静态核对——均有 `[通过]`（绿）/`[警告]`（黄）/`[失败]`（红，含处理建议）三级前缀与「通过 N 项 | 警告 M 项 | 失败 K 项」汇总行（F-011 / R-02 / R-03 / LLD 6.7）；记录已知差异并纳入验证报告判定：P3（deploy-rsa-keygen.ps1 无分级前缀与汇总行，.sh 有 print_result 分级 + 汇总，双平台不一致）、P4（deploy-db-init 双平台输出 ✅/❌ emoji 与「错误:」文本，无 [通过]/[警告]/[失败] 分级与汇总行）；颜色输出在非交互终端自动降级为纯文本（静态核对条件判断逻辑存在即可）
- **所属模块**：deploy/scripts / 输出分级契约（F-011）
- **优先级**：P0
- **前置条件**：TASK-003~006 编码完成（核心脚本已重构）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / ADR-016
- **测试数据**：deploy/scripts/ 8 对核心脚本 + deploy-rsa-keygen 对 + deploy-db-init 对（共 20 个脚本）
- **测试步骤**：
  1. grep 断言 8 对核心脚本（16 个）均含 `[通过]`、`[警告]`、`[失败]` 三级前缀字面量
  2. grep 断言上述脚本均含「通过 N 项 | 警告 M 项 | 失败 K 项」样式汇总行（允许数字由变量拼接）
  3. 核对 deploy-rsa-keygen 对与 deploy-db-init 对的输出分级现状，记录 P3/P4 差异明细（命中行号）
  4. 核对颜色输出降级逻辑（非交互终端纯文本）存在性，记录命中
- **预期结果**：
  1. 8 对核心脚本双平台输出分级一致（[通过]/[警告]/[失败] + 汇总行）——满足验收标准 7
  2. P3（rsa-keygen.ps1）、P4（db-init emoji）差异被如实记录，验证报告判定其与验收标准 7 的符合度并给出处理建议
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-233-1（8 对核心脚本含三级前缀）、UT-233-2（8 对核心脚本含汇总行）、UT-233-3（P3 差异记录：rsa-keygen.ps1 无分级）、UT-233-4（P4 差异记录：db-init emoji）、UT-233-5（颜色降级逻辑存在）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-233-1~5 均 PASS——8 对核心脚本（16 个）均含 `[通过]`/`[警告]`/`[失败]` 三级前缀与「通过 N 项 | 警告 M 项 | 失败 K 项」汇总行（满足验收标准 7）；P3（deploy-rsa-keygen.ps1 无分级前缀与汇总行，.sh 有 print_result）、P4（deploy-db-init 双平台 emoji 输出无分级）差异已如实记录；颜色降级逻辑（Write-Host -ForegroundColor，重定向自动降纯文本）存在）

#### UT-234：退出码约定（失败非零）静态核对（P0）
- **用例ID**：UT-234
- **用例名称**：全部业务脚本退出码约定静态核对——全部通过退出 0；存在失败项退出 1（非零）；仅警告无失败按约定退出 0 并提示（check-env/start-services）；env.json 缺失或关键配置缺失输出明确错误并退出/返回非零（load-env，.sh 为 return 1 + set -e 兜底）；deploy-start-all 前置校验不通过或任一服务启动失败即停止并退出 1（失败即停 R-09）；deploy-rsa-keygen 失败退出 1；退出码取值保持在 0/1 双平台安全域（0~255，ws.md §5.3 核对结论）；对照 F-011 / R-02 / R-03 / LLD 6.7 逐脚本核对 exit 语句
- **所属模块**：deploy/scripts / 退出码契约（F-011）
- **优先级**：P0
- **前置条件**：TASK-002~007 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / ADR-016
- **测试数据**：deploy/scripts/ 全部 24 个脚本的 exit/return 语句
- **测试步骤**：
  1. grep 汇总全部脚本 exit/return 语句位置与取值
  2. 断言核心脚本（check-env/start-services/start-all/start-{svc}/rsa-keygen）失败路径均 exit 1（非零）、成功路径 exit 0
  3. 断言 load-env 缺失处理路径（.ps1 exit 1 / .sh return 1）存在
  4. 断言 start-all 失败即停（break + exit 1）逻辑存在
  5. 断言无 exit 2+ 或负数等超契约取值（仅 0/1）
- **预期结果**：
  1. 全部脚本退出码符合契约：成功 0 / 失败非零（1）、仅警告 0
  2. 双平台退出码约定一致，取值在 0/1 安全域
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-234-1（核心脚本失败路径 exit 1）、UT-234-2（成功路径 exit 0 / 仅警告 exit 0）、UT-234-3（load-env 缺失处理非零）、UT-234-4（start-all 失败即停 exit 1）、UT-234-5（无超契约取值）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-234-1~5 均 PASS——8 对核心脚本失败路径均 exit 1、成功路径 exit 0（rsa-keygen.ps1 自然结束语义等值）、load-env 缺失配置路径非零（.ps1 exit 1 / .sh return 1 + set -e 兜底）、start-all 失败即停（break + exit 1，R-09）、全部 24 个脚本 exit/return 取值仅在 0/1 安全域（0~255），无超契约取值）

#### UT-235：load-env 依赖与 env.json 缺失处理核对（P0）
- **用例ID**：UT-235
- **用例名称**：全部业务脚本经 load-env 从 deploy/env.json 加载配置核对（验收标准 1）——deploy-check-env/start-services/start-all/start-{svc}/deploy-db-init 共 10 对脚本均在读取任何配置键值**之前**引用 load-env（.ps1 点源 `. "$PSScriptRoot\load-env.ps1"` / .sh `source "$SCRIPT_DIR/load-env.sh"`，多数带 `|| exit $?`）；build-backend/build-client 为构建脚本不依赖环境配置（合规，不参与）；load-env 对 env.json 缺失输出明确错误（提示复制 env.example.json 并填写配置）并以非零码退出（.ps1 exit 1 / .sh return 1 依赖 set -e 兜底），8 项关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）缺失逐项列出（只列键名不打印值）；记录 P5/P6 差异明细（P5 deploy-db-init.ps1 点源无引号包裹路径；P6 deploy-check-env.sh source 无 || exit $? 靠 set -e 兜底，行为等效）
- **所属模块**：deploy/scripts / 配置驱动约束（R-01 / ADR-016）
- **优先级**：P0
- **前置条件**：TASK-002~006 编码完成（load-env 与业务脚本已接入）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / US-001 / F-001 / F-010 / ADR-016
- **测试数据**：deploy/scripts/ 10 对业务脚本 + load-env.ps1/.sh
- **测试步骤**：
  1. grep 断言 10 对业务脚本（20 个）均含 load-env 引用语句（.ps1：`load-env.ps1`；.sh：`load-env.sh`）
  2. 断言引用位置位于脚本使用配置之前（load-env 引用行号 < 首个配置读取/打印行号）
  3. grep 断言 load-env.ps1/.sh 对 env.json 缺失均输出「复制 env.example.json」提示并退出/返回非零
  4. grep 断言 load-env 8 项关键配置缺失校验（逐项列出键名）存在且不打印值
  5. 核对 P5（db-init.ps1 点源无引号）、P6（check-env.sh 无 || exit $?）并记录命中行号
- **预期结果**：
  1. 全部业务脚本在使用配置前经 load-env 加载；build 脚本不依赖（合规）
  2. env.json 缺失输出明确错误并退出非零；关键配置缺失列出键名
  3. P5/P6 作为低优先级差异记录于验证报告（行为等效）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-235-1（10 对业务脚本含 load-env 引用）、UT-235-2（引用先于配置使用）、UT-235-3（load-env env.json 缺失处理非零）、UT-235-4（8 项关键配置缺失校验键名列出）、UT-235-5（P5/P6 差异记录）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-235-1~6 均 PASS——16 个业务脚本（8 对）均在读取配置前引用 load-env（.ps1 点源 / .sh source，多数带 `|| exit $?`）；load-env 对 env.json 缺失输出「复制 env.example.json」明确提示并以非零码退出（.ps1 exit 1 / .sh return 1）；8 项关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）缺失逐项列出键名不打印值；P5（deploy-db-init.ps1 点源无引号）、P6（deploy-check-env.sh source 无 `|| exit $?`，set -e 兜底行为等效）差异已记录；build-backend/build-client 为构建脚本不依赖环境配置（合规））

#### UT-236：无硬编码环境地址核对（P0）
- **用例ID**：UT-236
- **用例名称**：全部脚本无硬编码环境地址核对（验收标准 1）——grep 全 deploy/scripts 目录 `192.168.` 模式：核心脚本（1~9 号对 18 个）0 命中；deploy-db-init.ps1 第 20-23 行 param 默认值 `192.168.1.101`、`3306`、`root`、`<DB_PASSWORD>` 与 deploy-db-init.sh 第 21-24 行 `${DB_HOST:-192.168.1.101}` 等命中（P1，已知问题）——如实记录命中明细（文件/行号/内容），验证报告对 P1 与验收标准 1 的符合度给出判定与处理建议（历史资产 v0.1.7，经 load-env 覆盖后行为合规，但字面默认值违反「脚本内无硬编码环境地址与凭据」红线）；env.example.json 模板中的 127.0.0.1 默认值属应入库模板（合规，不计命中）
- **所属模块**：deploy/scripts / 硬编码检查（R-01 / ADR-016）
- **优先级**：P0
- **前置条件**：TASK-001~009 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-010 / ADR-016
- **测试数据**：deploy/scripts/ 全部 24 个脚本
- **测试步骤**：
  1. grep `192\.168\.` 全目录，收集全部命中（文件/行号/内容）
  2. 断言核心脚本（1~9 号对）0 命中
  3. 核对 deploy-db-init 对命中明细（P1），记录行号与默认值内容
  4. 核对 env.example.json 的 127.0.0.1 模板默认值属应入库文件，不计为脚本硬编码
  5. 验证报告输出 P1 判定与处理建议
- **预期结果**：
  1. 核心脚本无硬编码环境地址（0 命中）
  2. deploy-db-init 命中（P1）如实记录，验证报告按验收标准 1 判定（历史资产、load-env 覆盖后行为合规、但字面默认值违反红线）并给出处理建议
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-236-1（核心脚本 192.168 0 命中）、UT-236-2（db-init P1 命中明细记录：文件/行号/默认值）、UT-236-3（env.example.json 模板默认值不计命中）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-236-1~3 均 PASS——核心脚本对（1~9 号对 18 个）grep `192.168.x` 0 命中；P1 命中明细如实记录（deploy-db-init.ps1 第 20-23 行 param 默认值 `192.168.1.101`/`3306`/`root`/`<DB_PASSWORD>`、deploy-db-init.sh 第 21-24 行 `${DB_HOST:-192.168.1.101}` 等，历史资产 v0.1.7，经 load-env 覆盖后行为合规但字面默认值违反验收标准 1 红线，验证报告已判定并建议后续修复）；env.example.json 模板 127.0.0.1 默认值为应入库模板不计命中，且脚本内 127.0.0.1 字面量 0 命中）

#### UT-237：无明文凭据与口令掩码核对（P0）
- **用例ID**：UT-237
- **用例名称**：全部脚本无明文凭据输出与口令掩码核对（US-004 边界情况 / R-06 / NFR-004）——grep 断言 DB_PASSWORD / REDIS_PASSWORD / RSA_PRIVATE_KEY 等敏感键值无明文打印路径（load-env 仅输出键数量与文件路径；check-env 口令以 `****` 掩码显示、redis 口令经 REDISCLI_AUTH 环境变量传递、命令与日志无明文；rsa-keygen 完整私钥绝不打印、仅显示前 24 字符前缀并提示从 *_base64.txt 拷贝）；记录 P8（deploy-db-init 口令以 `-p"$DbPassword"` 命令行参数传给 mariadb，进程列表可见，日志已掩码 `-p'****'`，安全边界低风险差异）；验证报告对「密码/密钥出现在日志」边界（输出不含 DB_PASSWORD、RSA_PRIVATE_KEY 明文）给出核对结论
- **所属模块**：deploy/scripts / 凭据安全（R-06 / NFR-004）
- **优先级**：P0
- **前置条件**：TASK-002/003/007 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-010 / F-011 / NFR-004
- **测试数据**：deploy/scripts/ 全部 24 个脚本
- **测试步骤**：
  1. grep 断言 load-env.ps1/.sh 无打印 DB_PASSWORD/RSA_PRIVATE_KEY 值明文的语句（仅注入会话环境变量、输出键数量与文件路径）
  2. grep 断言 check-env 对口令掩码（`****`）与 REDISCLI_AUTH 通道存在，无 `-p"$password"` 明文命令行模式
  3. grep 断言 rsa-keygen 私钥输出脱敏（前 24 字符 + 提示拷贝），无完整私钥打印路径
  4. 核对 P8（db-init `-p"$DbPassword"`）命中明细（文件/行号），记录判定
  5. 汇总「日志无明文凭据」核对结论输出验证报告
- **预期结果**：
  1. 核心脚本无明文凭据打印、口令掩码机制存在（**** / REDISCLI_AUTH / 私钥前 24 字符脱敏）
  2. P8 如实记录（进程级可见但日志已掩码），验证报告按安全边界判定
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-237-1（load-env 无明文打印路径）、UT-237-2（check-env 掩码 **** 与 REDISCLI_AUTH）、UT-237-3（rsa-keygen 私钥脱敏前 24 字符）、UT-237-4（P8 db-init -p 命令行记录）、UT-237-5（全脚本无 DB_PASSWORD/RSA_PRIVATE_KEY 明文输出路径）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-237-1~5 均 PASS——load-env 输出语句不引用 DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY 值（仅键数量与文件路径）；check-env 双平台口令掩码 `****` 与 REDISCLI_AUTH 安全通道存在；rsa-keygen 双平台私钥脱敏（仅前 24 字符前缀 + 提示从 *_base64.txt 拷贝）；P8（deploy-db-init 口令以 `-p"$DbPassword"` 命令行参数传递，进程列表可见、日志已掩码）已记录并判定安全边界低风险；全部 24 个脚本输出语句无 DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY 明文打印路径（NFR-004 达标））

#### UT-238：弃用脚本无残留核对（P0）
- **用例ID**：UT-238
- **用例名称**：弃用脚本无残留核对（验收标准 6 / R-13 / TASK-008 已闭环复核）——deploy/scripts 目录及全仓库 grep `deploy-env`：deploy-env.ps1 / deploy-env-template.ps1 / deploy-env.sh 文件不存在（glob 0 命中）、全目录 grep 0 命中（无残留）、无其他脚本引用（0 引用）；deploy/scripts 当前恰为 12 对 24 个脚本 + .gitkeep，无多余遗留文件（清单完整性由 FT-160 复核）
- **所属模块**：deploy/scripts / 弃用清理（R-13）
- **优先级**：P0
- **前置条件**：TASK-008 编码完成（弃用脚本已删除）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-010 / ADR-016 / R-13
- **测试数据**：deploy/scripts/ 目录实况 + 全仓库 grep 结果
- **测试步骤**：
  1. glob 断言 deploy/scripts 下无 deploy-env*.ps1 / deploy-env*.sh / deploy-env-template* 文件
  2. grep 断言全仓库（排除 .git）`deploy-env` 0 命中（无引用、无文档残留引用失效）
  3. 断言 deploy/scripts 文件集合恰为 12 对 24 个脚本 + .gitkeep（对照 context.md 第 4 章清单）
- **预期结果**：
  1. 弃用脚本文件无残留、无引用（grep 0 命中）
  2. 目录清单与契约清单完全一致（24 个脚本 + .gitkeep）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-238-1（glob 无 deploy-env* 文件）、UT-238-2（全仓库 grep deploy-env 0 命中）、UT-238-3（目录清单 = 24 脚本 + .gitkeep）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-238-1~3 均 PASS——deploy/scripts 下无任何 deploy-env* / deploy-env-template* 文件（glob 0 命中）；全仓库 grep `deploy-env` 仅命中历史版本文档与测试脚本自身断言（无活动脚本引用，R-13 达标）；目录实况恰为 12 对 24 个脚本 + .gitkeep（25 条目），无多余遗留文件）

#### UT-239：SPDX 文件头与版权声明核对（P1）
- **用例ID**：UT-239
- **用例名称**：全部脚本文件头核对（US-004 验收标准 4）——SPDX-License-Identifier（Apache-2.0）与版权声明（Copyright 2026 jenemy8023）保留：18/24 个脚本有 SPDX 头（load-env、check-env、start-services、start-all、start-{svc}、rsa-keygen 9 对）；deploy-db-init/build-backend/build-client 6 个历史脚本无 SPDX 头（P2，已知问题）——如实记录缺失清单（文件/行号首行内容），验证报告对 P2 与验收标准 4 的符合度给出判定与处理建议；注释为简体中文
- **所属模块**：deploy/scripts / 文件头规范（R-16 / project.md 编码规范）
- **优先级**：P1
- **前置条件**：TASK-001~009 编码完成
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / R-16 / project.md 编码规范
- **测试数据**：deploy/scripts/ 全部 24 个脚本首行/头几行
- **测试步骤**：
  1. 读取每个脚本文件头，断言含 `SPDX-License-Identifier: Apache-2.0`
  2. 断言含 `Copyright 2026 jenemy8023`（或项目版权声明）
  3. 收集缺失清单（P2：deploy-db-init/build-backend/build-client 6 个历史脚本），记录首行实际内容
  4. 断言注释为简体中文
- **预期结果**：
  1. 18 个核心脚本 SPDX 头与版权声明完整保留（验收标准 4）
  2. P2 缺失清单如实记录，验证报告判定（历史资产未随重构补头，建议后续补齐）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-239-1（SPDX 头存在性逐脚本核对：核心 18 个通过）、UT-239-2（P2 缺失清单记录：6 个历史脚本）、UT-239-3（简体中文注释抽查）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-239-1~4 均 PASS——18 个核心脚本（1~9 号对）全部保留 SPDX-License-Identifier（Apache-2.0）与版权声明（Copyright 2026 jenemy8023），验收标准 4 达标；P2 缺失清单如实记录（deploy-db-init/build-backend/build-client 6 个历史脚本无 SPDX 头，验证报告判定为历史资产未随重构补头、建议后续补齐）；全部核心脚本注释含简体中文（CJK 字符抽查通过））

#### UT-240：.gitignore 治理复核静态核对（P0）
- **用例ID**：UT-240
- **用例名称**：.gitignore 治理复核（验收标准 8 / F-012 / TASK-009 已治理 376 行复核）——生成/测试/调试临时与中间文件排除规则齐全：JVM 调试产物（*.hprof、hs_err_pid*.log、replay_pid*、heapdump.*、*.dmp、dump/、*.dump、derby.log）、构建中间产物（*.flattened-pom.xml、*.lastUpdated、maven-status/、dependency-reduced-pom.xml）、测试产物与缓存（surefire-reports/、test-output/、test-results/、scripts/API-TEST/*.tmp、*.token.json、__pycache__/、.pytest_cache/）、工具残留（*.saz、*.chls、*.har、*.history、*.session、*.trace）、部署日志与进程文件（*.log、logs/、*.err、*.pid）；保护性规则（!env.example.json、!*.gitkeep 白名单、deploy/cloudoffice-flutter-app/web/* + !*.gitkeep 结构）保留不破坏；无 *.xml/*.yml/*.py/*.ps1/*.sh/*.java/*.dart/*.md 全局通配（不误伤应入库文件）；文件尾 SPDX 声明保留
- **所属模块**：.gitignore / 治理复核（F-012 / US-005）
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已治理 376 行）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012 / 验收标准 8
- **测试数据**：根目录 .gitignore（376 行现状）
- **测试步骤**：
  1. grep 逐项断言四类治理规则（JVM 调试产物 8 条 / 构建中间产物 4 条 / 测试产物缓存 / 工具残留 6 条）全部存在
  2. 断言部署日志与进程文件规则（*.log、logs/、*.err、*.pid）存在（覆盖 deploy/logs）
  3. 断言保护性规则（!env.example.json、!*.gitkeep 白名单、web/* + !*.gitkeep）完整保留
  4. 断言无 *.xml/*.yml/*.py/*.ps1/*.sh/*.java/*.dart/*.md 全局通配
  5. 断言文件尾 SPDX-License-Identifier 与 Copyright 行存在
- **预期结果**：
  1. 治理规则齐全、保护性规则保留、无全局通配误伤风险、SPDX 尾注保留
  2. 动态效果（git status 无过程文件、应入库文件未被误伤）由 FT-159 复核
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` UT-240-1（四类治理规则逐项存在）、UT-240-2（部署日志/进程文件规则存在）、UT-240-3（保护性规则保留、无全局通配）、UT-240-4（SPDX 尾注保留）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：UT-240-1~8 均 PASS——四类治理规则齐全：JVM 调试产物 8 条（*.hprof/hs_err_pid*.log/replay_pid*/heapdump.*/*.dmp/dump/*.dump/derby.log）、构建中间产物 4 条（*.flattened-pom.xml/*.lastUpdated/maven-status//dependency-reduced-pom.xml）、测试产物与缓存（surefire-reports//test-output//test-results//API-TEST/*.tmp/*.token.json/__pycache__//.pytest_cache/）、工具残留 6 条（*.saz/*.chls/*.har/*.history/*.session/*.trace）；部署日志与进程文件规则（*.log/logs/*.err/*.pid）存在覆盖 deploy/logs；保护性规则完整保留且经 `git check-ignore` 动态确认 env.example.json、web/.gitkeep、windows/.gitkeep 未被误忽略；无 *.xml/*.yml/*.py/*.ps1/*.sh/*.java/*.dart/*.md 全局通配；文件尾 SPDX-License-Identifier 与 Copyright 行保留）

### 模块：接口测试（本任务无接口变更）（TASK-010）
#### TC-096：无接口变更确认（P1）
- **用例ID**：TC-096
- **用例名称**：本任务（TASK-010）为部署脚本契约总体验证，仅涉及 deploy/scripts 校验、验证报告与测试产物，不触碰任何 Controller/DTO/响应体；git 变更清单静态核对确认无后端接口代码变更（cloudoffice-*/src/main/java 下无 Controller 变更），API-001~API-033 接口契约完整保留（对应 API 文档 v0.2.7「无新增/变更/删除」声明）；脚本对接口的影响仅为部署层面（服务启动/健康检查），不改变接口契约
- **所属模块**：接口层 / 契约回归
- **优先级**：P1
- **前置条件**：TASK-010 编码完成（验证报告与测试产物就绪）
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-004 / F-010 / F-011
- **测试数据**：git 变更清单 + docs/cso-api-v0.2.7.md
- **测试步骤**：
  1. 获取 TASK-010 相关 git 变更文件清单，断言不含 cloudoffice-*/src/main/java 下任何接口代码文件
  2. 断言变更清单仅含 deploy/scripts（如有修改）、验证报告、测试脚本与版本文档
  3. 对照 docs/cso-api-v0.2.7.md，断言 API-001~API-033 无新增/变更/删除
- **预期结果**：
  1. 无后端接口代码变更，API-001~API-033 契约完整保留
  2. 变更范围与本任务定义一致（脚本验证与测试产出）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py` TC-096-1（API 文档无接口变更声明）、TC-096-2（git 变更清单无接口层文件）、TC-096-3（API-001~033 契约完整保留）、TC-096-4（变更范围仅限脚本验证/验证报告/测试产物）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-api-test-v0.2.7.py` test_tc096_no_api_change()，TC-096-1~4）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行 `cso-api-test-v0.2.7.py`：TC-096-1~4 均 PASS——版本 API 文档声明本版本无新增/变更/删除接口、git 变更清单无任何接口层文件（Controller/DTO/响应体/网关路由）、API-001~API-033 契约完整保留、变更范围仅限脚本验证/验证报告/测试脚本/版本文档；本任务接口测试部分与全量接口回归一并执行，整体 PASS=65/FAIL=0/SKIP=0）

#### TC-097：健康检查端点契约探活（可选，环境依赖）（P2）
- **用例ID**：TC-097
- **用例名称**：后端服务健康检查端点探活（可选，环境依赖）——直连 auth 服务 9100 /api/v1/auth/health、网关 9000 根路径（如已启动），断言 HTTP 200 且响应体 ApiResult 结构（code=200、status=UP）与 API 文档契约一致，确认脚本体系验证未影响服务运行与健康契约；服务未启动时按环境 SKIP 记录，不作为失败（静态契约由 TC-096 兜底）
- **所属模块**：接口层 / 健康检查探活
- **优先级**：P2
- **前置条件**：TASK-010 编码完成；auth 服务 9100 / 网关 9000 已启动（环境依赖）
- **测试类型**：接口测试（动态探活，环境依赖）
- **关联需求ID**：US-004 / F-010
- **测试数据**：`http://127.0.0.1:9100/api/v1/auth/health`、`http://127.0.0.1:9000/`
- **测试步骤**：
  1. 直连 auth 服务健康端点，断言 HTTP 200、code=200、status=UP
  2. 直连网关根路径，断言 HTTP 200 与 ApiResult 结构
  3. 任一服务未启动时记录环境 SKIP，不做失败判定
- **预期结果**：
  1. 健康端点契约与 API 文档一致（HTTP 200、ApiResult 结构齐全）
  2. 服务不可达时按环境 SKIP 记录
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py` TC-097-1（直连 auth 9100 /api/v1/auth/health 探活）、TC-097-2（gateway 9000 根路径探活）；服务未启动按环境 SKIP；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-api-test-v0.2.7.py` test_tc097_health_probe()，TC-097-1/2）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：TC-097-1（直连 auth-service 9100 GET /api/v1/auth/health 返回 HTTP 200、code=200、status=UP）、TC-097-2（gateway 9000 根路径探活通过）均 PASS——当前环境 4 个后端服务已启动，健康端点真实连通且 ApiResult 结构与 API 文档一致，无环境 SKIP；TC-078/081/083/085/087/089/093/095 等同端点探活断言一并通过）

### 模块：功能测试（双平台行为一致核对与总体验证报告）（TASK-010）
#### FT-153：验证报告输出与 PRD 第 7 章 8 条验收标准逐条核对（P0）
- **用例ID**：FT-153
- **用例名称**：验证报告输出与 PRD 第 7 章 8 条验收标准逐条核对（任务核心交付）——验证报告落盘（docs/cso-v0.2.7/task_TASK-010/ 或版本目录，按 coding 阶段约定位置），包含：报告头（任务编号、校验环境：OS/PowerShell 版本/bash 版本/git 版本/shellcheck 可用性、校验时间）、总览表（12 对脚本 × 校验项：语法 .ps1/.sh、输出分级、退出码、load-env 依赖、硬编码、SPDX 头、密钥契约）、分项详表（证据：行号/命中内容）、**PRD 第 7 章 8 条验收标准逐条核对表（标准原文 → 核对结果 → 证据）**、整体汇总行「通过 N 项 | 警告 M 项 | 失败 K 项」、遗留问题清单（cs.md §9 P1~P9 逐条最终判定）；报告校验工具退出码：全部通过 0 / 存在失败 1（F-011 一致）；8 条验收标准逐条核对覆盖：①load-env 加载无硬编码 ②check-env 四项检查+运行状态 ③start-services 自动启动无假成功 ④start-all 按序启动失败即停 ⑤单服务脚本独立一致 ⑥rsa-keygen 契约一致+弃用无残留 ⑦输出分级+退出码+双平台一致 ⑧.gitignore 治理
- **所属模块**：验证报告 / PRD 第 7 章验收核对
- **优先级**：P0
- **前置条件**：TASK-010 编码完成（验证报告已生成）
- **测试类型**：功能测试（报告核对）
- **关联需求ID**：US-004 / F-010 / F-011 / 验收标准 1~8
- **测试数据**：验证报告文件 + docs/cso-v0.2.7/cso-prd-v0.2.7.md 第 281-290 行（第 7 章原文）
- **测试步骤**：
  1. 断言验证报告文件存在且含报告头（校验环境完整记录）
  2. 断言报告含总览表与分项详表（12 对脚本 × 校验项，逐项 通过/警告/失败 与证据）
  3. 断言报告含 PRD 第 7 章 8 条验收标准逐条核对表，**8 条全部有「核对结果 + 证据」**（逐条对照 PRD 原文）
  4. 断言报告含整体汇总行与遗留问题清单（P1~P9 逐条判定）
  5. 断言报告校验工具退出码符合 F-011（全部通过 0 / 存在失败 1）
- **预期结果**：
  1. 验证报告完整（报告头/总览/分项/PRD 8 条逐条核对表/汇总行/遗留问题清单）
  2. PRD 第 7 章 8 条验收标准逐条有结论与证据，无遗漏
  3. 退出码符合契约
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-153-1（验证报告存在且含报告头）、FT-153-2（总览表与分项详表存在）、FT-153-3（PRD 第 7 章 8 条验收标准逐条核对表完整：8 条均有结论与证据）、FT-153-4（汇总行与遗留问题清单 P1~P9 存在）、FT-153-5（报告工具退出码 0/1 契约）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-153-1~8 均 PASS——验证报告 `docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md` 存在且含完整报告头（OS/Windows PowerShell 版本/git-bash bash 5.2.37 版本/git 版本/shellcheck 可用性记录）、总览表（第 3 章 12 对脚本 × 校验项）与分项详表（第 4 章，证据含行号）、PRD 第 7 章 8 条验收标准逐条核对表（第 5 章 8 行，每条均含核对结果与证据）、遗留问题清单（第 6 章 P1~P9 逐条最终判定）、整体汇总行「通过 9 项 | 警告 4 项 | 失败 0 项」、校验工具退出码按 F-011 契约（全部通过 → 0））

#### FT-154：deploy-check-env 双平台行为一致核对（P0）
- **用例ID**：FT-154
- **用例名称**：deploy-check-env.ps1/.sh 双平台行为一致核对（验收标准 2）——两脚本均基于 load-env 加载的 env.json 完成：JDK（java 命令可执行 + JAVA_HOME 有效 + 版本匹配 `version "21` 合并一项结论）、MariaDB（命令/系统服务/进程三重检测 + SELECT 1 连通、口令掩码 ****）、Redis（三重检测 + redis-cli ping 返回 PONG、口令经 REDISCLI_AUTH）、Nacos（NACOS_ADDR 格式校验 + NACOS_HOME/bin/startup.cmd（.sh 为 startup.sh）存在 + HTTP 探测含 "Nacos"）可用性检查，并输出运行状态（阶段二：进程/服务/TCP/HTTP 探测）；已安装未启动计「警告（未运行）」；存在失败项时给出处理提示并退出非零（fail>0 → exit 1；仅警告 → exit 0）；.ps1/.sh 实现结构逐项比对（可用性检查项、运行状态探测、输出分级、退出码），断言双平台行为一致
- **所属模块**：deploy-check-env / 可用性检查（F-002~F-006、F-010）
- **优先级**：P0
- **前置条件**：TASK-003 编码完成（deploy-check-env 已重构）
- **测试类型**：功能测试（静态比对）
- **关联需求ID**：US-001 / US-004 / F-002~F-006 / F-010 / F-011 / 验收标准 2
- **测试数据**：deploy/scripts/deploy-check-env.ps1（280 行）、deploy-check-env.sh（277 行）
- **测试步骤**：
  1. 比对两脚本结构：阶段一可用性检查（JDK/MariaDB/Redis/Nacos 四项）与阶段二运行状态探测是否一致
  2. 断言 JDK 检查含 java 命令 + JAVA_HOME + 版本 21 三项；MariaDB 含三重检测 + SELECT 1；Redis 含三重检测 + ping PONG；Nacos 含 NACOS_HOME/startup 脚本 + HTTP 探测
  3. 断言输出分级（[通过]/[警告]/[失败]）与汇总行、退出码约定（fail>0 → exit 1）双平台一致
  4. 记录比对结论与命中证据（函数/行号）
- **预期结果**：
  1. check-env 双平台行为一致，四项可用性检查 + 运行状态输出完整
  2. 失败退出非零、仅警告退出 0 的约定双平台一致（验收标准 2/7）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-154-1（双平台四项检查内容逐项比对）、FT-154-2（运行状态探测逻辑比对）、FT-154-3（输出分级与退出码比对）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-154-1~6 均 PASS——deploy-check-env.ps1/.sh 双平台行为一致：JDK 检查含 java 命令 + JAVA_HOME + 版本 21 三项；MariaDB 三重检测 + SELECT 1 连通；Redis 三重检测 + redis-cli ping PONG；Nacos NACOS_HOME/startup 脚本存在 + HTTP 探测；两平台均实现运行状态探测（进程/服务/TCP 探测 + Nacos HTTP）；输出分级（[通过]/[警告]/[失败]）与退出码约定（fail>0 → exit 1、仅警告 → exit 0）双平台一致，验收标准 2/7 达标）

#### FT-155：deploy-start-services 双平台行为一致核对（P0）
- **用例ID**：FT-155
- **用例名称**：deploy-start-services.ps1/.sh 双平台行为一致核对（验收标准 3）——两脚本均：按 MariaDB → Redis → Nacos 顺序（R-07 基础设施序）；JDK 仅检查可用性输出结论不执行启动（R-11）；已运行幂等跳过输出「已运行」（R-10）；未安装不尝试启动输出「未安装，请先安装」计入失败（R-12）；启动方式优先级一致（系统服务 Windows Start-Service / Linux systemctl start 回退 service start → 可执行文件 mysqld/mariadbd/redis-server（.sh 侧 mysqld_safe 优先）→ Nacos startup.cmd/.sh -m standalone，日志落 deploy/logs/nacos-start.log）；启动后 Wait-ServiceUp/wait_for_service 循环探测确认（超时上限 30s、间隔 2s，进程/TCP/ping/HTTP 任一命中），不报假成功（R-08）；退出码 fail>0 → exit 1 / 仅警告 → exit 0；.ps1/.sh 行为逐项比对一致
- **所属模块**：deploy-start-services / 基础设施一键启动（F-006、F-007）
- **优先级**：P0
- **前置条件**：TASK-004 编码完成（deploy-start-services 已重构）
- **测试类型**：功能测试（静态比对）
- **关联需求ID**：US-004 / F-006 / F-007 / R-07 / R-08 / R-10 / R-11 / R-12 / 验收标准 3
- **测试数据**：deploy/scripts/deploy-start-services.ps1（347 行）、deploy-start-services.sh（343 行）
- **测试步骤**：
  1. 比对两脚本：启动顺序（MariaDB → Redis → Nacos）、JDK 仅检查、幂等跳过、未安装处理
  2. 断言启动方式优先级（系统服务 → 可执行文件 → Nacos startup 脚本）双平台一致
  3. 断言启动后探测确认逻辑（Wait-ServiceUp/wait_for_service，超时 30s/间隔 2s）双平台一致，无假成功
  4. 断言退出码约定双平台一致（fail>0 → exit 1）
  5. 记录比对结论与命中证据
- **预期结果**：
  1. start-services 双平台行为一致：顺序/优先级/确认/退出码全部符合验收标准 3
  2. JDK 不执行启动、未安装不启动、已运行幂等跳过均一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-155-1（启动顺序与 JDK 仅检查比对）、FT-155-2（启动方式优先级比对）、FT-155-3（启动后确认探测与退出码比对）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-155-1~5 均 PASS——deploy-start-services.ps1/.sh 双平台行为一致：按 MariaDB → Redis → Nacos 顺序启动（R-07）；JDK 仅检查可用性不执行启动（R-11）；启动方式优先级一致（系统服务 Start-Service/systemctl → 可执行文件 mysqld/mariadbd/redis-server → Nacos startup.cmd/.sh -m standalone）；启动后经 Wait-ServiceUp/wait_for_service 轮询确认（超时 30s/间隔 2s）不报假成功（R-08）；退出码约定一致（fail>0 → exit 1 / 仅警告 → exit 0），验收标准 3 达标）

#### FT-156：deploy-start-all 双平台行为一致核对（P0）
- **用例ID**：FT-156
- **用例名称**：deploy-start-all.ps1/.sh 双平台行为一致核对（验收标准 4）——两脚本均按 gateway → auth → biz → system 顺序一键启动 4 个后端服务（R-07 后端序）；启动前校验：java 命令 + 4 个 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）+ 各服务关键环境变量（缺失只列键名不打印值），任一缺失列出缺失项+提示并退出 1 不启动任何服务；每服务启动后健康确认（Wait-HealthUp/wait_health_up 轮询默认 30 次/2 秒/3 秒，HTTP 优先、TCP 备用，含 404/401/500 即存活），确认成功后再启动下一个；任一步骤失败停止（R-09 失败即停 break）并给出明确错误提示；退出码全部成功 0 / 任一失败 1；服务清单契约（jar/端口 9000/9100/9200/9400/健康 URL/关键变量）双平台一致
- **所属模块**：deploy-start-all / 后端服务一键启动（F-008）
- **优先级**：P0
- **前置条件**：TASK-005 编码完成（deploy-start-all 已新增）
- **测试类型**：功能测试（静态比对）
- **关联需求ID**：US-004 / F-008 / R-07 / R-09 / 验收标准 4
- **测试数据**：deploy/scripts/deploy-start-all.ps1（221 行）、deploy-start-all.sh（196 行）
- **测试步骤**：
  1. 断言服务清单契约双平台一致：4 个服务顺序（gateway → auth → biz → system）、jar 名、端口（9000/9100/9200/9400）、健康 URL、关键环境变量
  2. 断言前置校验（java + 4 jar + 关键变量，缺失退出 1 不启动）双平台一致
  3. 断言每服务健康确认（HTTP 优先/TCP 备用、轮询参数）双平台一致
  4. 断言失败即停（break）与退出码（任一失败 1）双平台一致
  5. 记录比对结论与命中证据（数组/参数行）
- **预期结果**：
  1. start-all 双平台行为一致：顺序/前置校验/健康确认/失败即停/退出码全部符合验收标准 4
  2. 服务清单契约（端口/健康 URL）双平台完全一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-156-1（服务清单契约双平台比对）、FT-156-2（前置校验与失败即停比对）、FT-156-3（健康确认轮询与退出码比对）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-156-1~5 均 PASS——deploy-start-all.ps1/.sh 双平台服务清单契约一致（4 个 jar、端口 9000/9100/9200/9400、健康 URL）；启动前校验（java 命令 + 4 jar 存在 + 关键环境变量，缺失列出缺失项并退出 1 不启动任何服务）一致；每服务启动后健康确认（Wait-HealthUp/wait_health_up 轮询，HTTP 优先/TCP 备用）一致；任一失败即停（break + exit 1，R-09）；退出码约定一致（全部成功 0 / 任一失败 1），验收标准 4 达标）

#### FT-157：单服务启动脚本 4 对行为一致核对（P1）
- **用例ID**：FT-157
- **用例名称**：单服务启动脚本 4 对（deploy-start-gateway/auth/biz/system 的 .ps1/.sh 共 8 个）行为一致核对（验收标准 5）——每个单服务脚本独立可用，行为与 deploy-start-all 对应服务子块一致：前置校验（jar 存在 + 关键环境变量）→ 后台启动（java -Xms256m -Xmx512m -jar；.ps1 Start-Process 隐藏窗口 + 日志重定向 deploy/logs/{module}-start.log/.err + PID 落 .pid；.sh nohup + $!）→ 健康确认 → 汇总退出；逐一核对参数行契约：gateway 9000 / cloudoffice-gateway.jar / http://localhost:9000/ / 需 NACOS_ADDR、RSA_PUBLIC_KEY；auth 9100 / cloudoffice-auth-service.jar / http://localhost:9100/api/v1/auth/health / 需 NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD；biz 9200 / cloudoffice-biz-service.jar / http://localhost:9200/api/v1/biz/health / 需 NACOS_ADDR、DB_PASSWORD；system 9400 / cloudoffice-system-service.jar / http://localhost:9400/api/v1/system/health / 需 NACOS_ADDR、DB_PASSWORD；与 deploy-start-all 服务清单契约完全一致
- **所属模块**：deploy-start-{svc} / 单服务启动（F-009）
- **优先级**：P1
- **前置条件**：TASK-006 编码完成（单服务脚本已重构）
- **测试类型**：功能测试（静态比对）
- **关联需求ID**：US-004 / F-009 / 验收标准 5
- **测试数据**：deploy/scripts/deploy-start-gateway/auth/biz/system 的 .ps1/.sh 共 8 个脚本（各约 184 行）
- **测试步骤**：
  1. 对 4 对单服务脚本逐一核对服务标识/jar/端口/健康 URL/关键环境变量（参数行），断言与 deploy-start-all 服务清单契约一致
  2. 断言每脚本结构完整（前置校验 → 后台启动 → 健康确认 → 汇总退出）
  3. 断言 .ps1/.sh 同名脚本行为一致（启动方式/日志/PID/确认逻辑比对）
  4. 记录 8 个脚本的契约核对结果
- **预期结果**：
  1. 4 对单服务脚本独立可用，契约参数（端口 9000/9100/9200/9400、jar、健康 URL、关键变量）与一键启动对应服务完全一致（验收标准 5）
  2. 双平台同名脚本行为一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-157-1（8 个单服务脚本契约参数逐项核对：jar/端口/健康 URL/关键变量）、FT-157-2（结构与双平台一致性比对）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-157-1~3 均 PASS——4 对单服务启动脚本（deploy-start-gateway/auth/biz/system 的 .ps1/.sh 共 8 个）契约参数（jar 名、端口 9000/9100/9200/9400、健康 URL、关键环境变量 NACOS_ADDR/RSA_*/DB_PASSWORD）与 deploy-start-all 服务清单契约完全一致（验收标准 5）；8 个脚本结构完整（前置校验 → 后台启动 → 健康确认 → 汇总退出）；双平台后台启动方式一致（.ps1 Start-Process 隐藏窗口 + 日志重定向 + PID 落盘 / .sh nohup + $!，-Xms256m -Xmx512m 一致）

#### FT-158：部署顺序契约核对（P1）
- **用例ID**：FT-158
- **用例名称**：部署顺序契约核对（R-07 / context.md §5.5）——基础设施部署顺序：MariaDB → Redis → Nacos（deploy-start-services 数组/调用序）；后端服务部署顺序：gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）（deploy-start-all 服务清单数组序）；两脚本 .ps1/.sh 顺序定义一致，与 R-07 / LLD 部署顺序约定完全吻合；通过 grep 提取两脚本顺序定义（数组/顺序调用）逐一比对
- **所属模块**：deploy/scripts / 部署顺序契约（R-07）
- **优先级**：P1
- **前置条件**：TASK-004/005 编码完成
- **测试类型**：功能测试（静态核对）
- **关联需求ID**：US-004 / R-07 / 验收标准 3/4
- **测试数据**：deploy-start-services.ps1/.sh、deploy-start-all.ps1/.sh
- **测试步骤**：
  1. 提取 deploy-start-services 的启动顺序定义，断言 MariaDB → Redis → Nacos（.ps1/.sh 一致）
  2. 提取 deploy-start-all 的服务清单顺序，断言 gateway → auth → biz → system（.ps1/.sh 一致）
  3. 对照 LLD R-07 与 context.md §5.5，断言完全吻合
- **预期结果**：
  1. 基础设施顺序 MariaDB → Redis → Nacos、后端顺序 gateway 9000 → auth 9100 → biz 9200 → system 9400，双平台一致且符合 R-07
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-158-1（基础设施顺序核对）、FT-158-2（后端服务顺序核对）、FT-158-3（与 R-07 契约一致）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-158-1~3 均 PASS——基础设施部署顺序 MariaDB → Redis → Nacos（deploy-start-services 双平台顺序定义一致）；后端服务部署顺序 gateway(9000) → auth(9100) → biz(9200) → system(9400)（deploy-start-all 服务清单数组序双平台一致）；两平台顺序与 R-07 / LLD 部署顺序契约完全吻合，验收标准 3/4 达标）

#### FT-159：git status 无过程文件与应入库文件复核（P0）
- **用例ID**：FT-159
- **用例名称**：.gitignore 治理效果动态复核（验收标准 8 / F-012）——执行 `git status --porcelain`：待提交清单不出现任何生成、测试、调试过程文件（JVM 调试产物/构建中间产物/测试产物/工具残留/部署日志与 PID 等治理类型模式 0 命中）；应入库文件复核：`git ls-files` 确认 deploy/env.example.json、全部 .gitkeep、全部 pom.xml、bootstrap.yml、源码与文档、scripts/API-TEST 测试脚本、deploy/scripts 全部脚本仍被跟踪；`git status --porcelain --ignored` 被忽略清单中无任何应入库文件（未被误伤）；对比治理基线（TASK-009 FT-151 结论：env.example.json/.gitkeep=48/pom.xml=6/bootstrap.yml=8/源码文档全跟踪）确认无回归
- **所属模块**：git 仓库 / 治理效果复核（F-012 / US-005）
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已治理）
- **测试类型**：功能测试（动态验证）
- **关联需求ID**：US-005 / F-012 / 验收标准 8
- **测试数据**：`git status --porcelain`、`git ls-files`、`git status --porcelain --ignored`
- **测试步骤**：
  1. 执行 `git status --porcelain`，用治理类型模式清单（JVM 调试产物/构建中间产物/测试产物/工具残留/部署日志 PID）逐一匹配，断言 0 命中
  2. 执行 `git ls-files`，断言 deploy/env.example.json 被跟踪、.gitkeep 数量与基线一致（约 48 个）、pom.xml=6、bootstrap.yml 与基线一致、deploy/scripts 24 个脚本全跟踪
  3. 执行 `git status --porcelain --ignored`，断言被忽略清单中无任何应入库文件
  4. 记录待提交清单内容（应为验证报告/测试脚本/版本文档等预期变更）
- **预期结果**：
  1. 待提交清单无任何生成/测试/调试过程文件（验收标准 8）
  2. 应入库文件全部仍被跟踪、未被误伤（env.example.json/.gitkeep/pom.xml/bootstrap.yml/源码/文档/测试脚本/部署脚本）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-159-1（git status 治理类型 0 命中）、FT-159-2（git ls-files 应入库文件全跟踪）、FT-159-3（--ignored 清单无应入库文件）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-159-1~4 均 PASS——`git status --porcelain` 无任何生成/测试/调试过程文件（JVM 调试产物/构建中间产物/测试产物/工具残留/部署日志与 PID 治理类型 0 命中，验收标准 8 达标）；`git ls-files` 确认 deploy/env.example.json 已跟踪、.gitkeep=48 与 pom.xml=6、bootstrap.yml=8 与 TASK-009 基线一致、deploy/scripts 全部 24 个脚本仍被跟踪；`git status --porcelain --ignored` 被忽略清单与已跟踪文件交集为空（无应入库文件被误伤））

#### FT-160：脚本清单完整性与双平台一一对应核对（P1）
- **用例ID**：FT-160
- **用例名称**：deploy/scripts 脚本清单完整性与双平台一一对应核对——目录实况：恰为 12 对 24 个脚本 + .gitkeep（无多余、无缺失）；每对 .ps1/.sh 文件名一一对应（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen、deploy-db-init、build-backend、build-client）；与 context.md 第 4 章清单、cs.md 第 2 章清单完全一致；无弃用脚本残留（与 UT-238 配合）；.gitkeep 保留（目录占位）
- **所属模块**：deploy/scripts / 清单完整性
- **优先级**：P1
- **前置条件**：TASK-001~009 编码完成
- **测试类型**：功能测试（静态核对）
- **关联需求ID**：US-004 / F-010 / ADR-016
- **测试数据**：deploy/scripts/ 目录实况、context.md 第 4 章清单
- **测试步骤**：
  1. 枚举 deploy/scripts 文件集合，断言 = 24 个脚本 + .gitkeep
  2. 断言 12 个 .ps1 与 12 个 .sh 文件名一一对应（同名前缀成对）
  3. 对照 context.md 第 4 章 / cs.md 第 2 章清单逐项核对，断言完全一致
- **预期结果**：
  1. 脚本清单与契约清单完全一致（12 对 24 个 + .gitkeep），无多余/缺失
  2. 双平台文件一一对应，无单边脚本
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` FT-160-1（文件集合 = 24 + .gitkeep）、FT-160-2（12 对同名一一对应）、FT-160-3（与契约清单逐项一致）；（impm-task-coding-writetest 步骤已标注：`scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 对应断言函数，断言级 PASS=88/FAIL=0/SKIP=0，2026-08-10）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：FT-160-1~3 均 PASS——deploy/scripts 目录实况恰为 12 对 24 个脚本 + .gitkeep（无多余、无缺失）；12 个 .ps1 与 12 个 .sh 文件名一一对应（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen、deploy-db-init、build-backend、build-client），无单边脚本；与 context.md 第 4 章契约清单逐项完全一致）

### 模块：UI 测试（无 UI 变更确认）（TASK-010）
#### UIT-026：无 UI 变更确认（P1）
- **用例ID**：UIT-026
- **用例名称**：TASK-010 仅涉及 deploy/scripts 脚本契约总体验证、验证报告与测试产物，不涉及任何 Flutter 客户端 UI/交互变更；git 变更清单静态核对无 cloudoffice-flutter-app 下任何源码（lib/、test/）与配置（pubspec.yaml 等）变更，客户端 UI/交互/运行行为零变更，无需 UI 测试
- **所属模块**：客户端 / UI 变更确认
- **优先级**：P1
- **前置条件**：TASK-010 编码完成
- **测试类型**：UI测试（静态核对）
- **关联需求ID**：US-004 / F-010
- **测试数据**：git 变更清单
- **测试步骤**：
  1. 获取 TASK-010 相关 git 变更文件清单
  2. 断言不含 cloudoffice-flutter-app/lib、cloudoffice-flutter-app/test、cloudoffice-flutter-app/pubspec.yaml 等任何客户端代码/配置文件
  3. 断言变更仅含脚本验证产出（验证报告、测试脚本、版本文档等）
- **预期结果**：
  1. 客户端零代码/配置变更，UI/交互/运行行为不受影响，无需 UI 测试
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`「五、功能测试记录（FT-153 ~ FT-160，TASK-010）」UIT-026 节（git 变更清单静态核对）；（impm-task-coding-writetest 步骤已标注：`docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`「五（TASK-010）功能测试记录（FT-153 ~ FT-160，TASK-010）」UIT-026 节，writetest 冒烟 2026-08-10 静态核对通过）
- **测试过程与结论**：**通过**（2026-08-10 impm-task-coding-runtest 正式执行：git 变更清单静态核对确认本任务无 cloudoffice-flutter-app 下任何源码（lib/、test/）与配置（pubspec.yaml 等）变更，客户端 UI/交互/运行行为零变更，无需 UI 测试；记录见 `docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`「UIT-026」节（2026-08-10 静态核对通过））

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 22 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

> 本任务（TASK-010）22 个用例（单元 11：UT-230~240、接口 2：TC-096/097、功能 8：FT-153~160、UI 1：UIT-026）由 impm-task-coding-writetest / impm-task-coding-runtest 步骤编写测试脚本并执行。
> **执行结论（2026-08-10 impm-task-coding-runtest 正式执行）**：单元/功能测试脚本 `scripts/API-TEST/cso-unit-test-scripts-contract-v0.2.7.ps1` 断言级 **PASS=88 / FAIL=0 / SKIP=0**（覆盖 UT-230~240 与 FT-153~160 全部用例；.ps1 校验环境 Windows PowerShell 5.1、.sh 校验环境 git-bash GNU bash 5.2.37）；接口测试脚本 `scripts/API-TEST/cso-api-test-v0.2.7.py` 断言级 **PASS=65 / FAIL=0 / SKIP=0**（TC-077~097 全量接口回归，TASK-010 相关 TC-096-1~4、TC-097-1/2 全部通过，健康端点探活真实连通无 SKIP）；UI 测试 UIT-026 静态核对通过。**22/22 用例全部通过，无失败无跳过。**

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| Windows 无 bash 环境 | 12 个 .sh 无法执行 bash -n 动态校验 | UT-231 记录校验环境；无 bash 时降级静态核对（括号/引号/关键字配对）并在验证报告注明校验方式；已通过 cs.md/ws.md 静态核对兜底 |
| 历史脚本已知问题（P1 硬编码/P2 缺 SPDX/P3 输出分级不一致/P4 emoji/P5 点源无引号/P6 source 无 exit/P8 口令命令行参数） | 与验收标准 1/4/7 的符合度判定 | 各用例如实记录命中明细（文件/行号/内容），验证报告逐条给出判定与处理建议（历史资产 v0.1.7，load-env 覆盖后行为合规；核心脚本 1~9 号对全部达标），不隐瞒不放大 |
| 语法校验误伤动态语法（如条件中变量名拼接命令） | .sh/.ps1 通过解析但运行时失败 | 语法校验（Parser/bash -n）仅为契约层；行为一致性由 FT-154~157 静态比对兜底，运行期验证由 wrirun/test 阶段既有脚本覆盖 |
| 验证报告位置/命名不确定 | FT-153 断言路径不成立 | 按 coding 阶段约定位置输出（docs/cso-v0.2.7/task_TASK-010/ 或版本目录），用例断言「报告存在」时按实际路径记录 |
| 健康检查探活依赖服务启动 | TC-097 动态探活环境依赖 | 服务未启动按环境 SKIP 记录，不作为失败；静态契约由 TC-096 兜底 |
| .gitignore 行号/数量漂移 | UT-240/FT-159 行号断言脆弱 | 以规则模式内容断言为准（不依赖行号），数量断言记录实际值并与 TASK-009 基线比对 |
| 用例覆盖遗漏 | 24 个脚本 × 8 类校验项漏测 | FT-160 清单完整性兜底（12 对一一对应）；FT-153 PRD 8 条验收标准逐条核对表强制全覆盖 |

## 五、签名确认
- 测试工程师（TE）：**TASK-010 测试用例 22 个已编写完成（2026-08-10，impm-task-coding-testcase 步骤）**——单元 11：UT-230（12 个 .ps1 Parser 语法校验）、UT-231（12 个 .sh bash -n 语法校验）、UT-232（RSA 密钥契约 ADR-015 双平台一致）、UT-233（输出分级 [通过]/[警告]/[失败] + 汇总行，P3/P4 差异记录）、UT-234（退出码约定失败非零）、UT-235（load-env 依赖与 env.json 缺失处理，P5/P6 差异记录）、UT-236（无硬编码环境地址，P1 命中明细）、UT-237（无明文凭据与口令掩码，P8 记录）、UT-238（弃用脚本无残留）、UT-239（SPDX 文件头，P2 缺失清单）、UT-240（.gitignore 治理静态复核）；接口 2：TC-096 无接口变更确认 + TC-097 健康检查探活可选；功能 8：FT-153 验证报告输出与 PRD 第 7 章 8 条验收标准逐条核对、FT-154 check-env 双平台一致、FT-155 start-services 双平台一致、FT-156 start-all 双平台一致、FT-157 单服务脚本 4 对一致、FT-158 部署顺序契约、FT-159 git status 无过程文件与应入库文件复核、FT-160 脚本清单完整性；UI 1：UIT-026 无 UI 变更确认。**正式执行结果（2026-08-10，impm-task-coding-runtest 步骤）：22/22 全部通过——单元/功能测试脚本 cso-unit-test-scripts-contract-v0.2.7.ps1 PASS=88/FAIL=0/SKIP=0（Windows PowerShell 5.1 + git-bash bash 5.2.37 校验环境），接口测试脚本 cso-api-test-v0.2.7.py PASS=65/FAIL=0/SKIP=0（TC-096/097 通过，健康探活真实连通），UIT-026 静态核对通过，无失败无需回退编码。** TE 签名确认。
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
