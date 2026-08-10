# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

> 本任务（TASK-008）为清理弃用脚本残留并同步引用关系（F-011 / US-004 / ADR-016 / 上游 TASK-001 issue-list P2 + P7-09）：
> 删除 deploy/scripts 下弃用残留脚本 deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh（git rm 彻底删除，非"标注弃用保留"）；检查全部脚本与文档对弃用脚本的引用关系并同步更新，避免加载路径失效；确保移除后 deploy/scripts 目录仅保留能力矩阵脚本（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen）+ 合法脚本（deploy-db-init、build-backend、build-client）+ .gitkeep，.ps1 与 .sh 同名脚本行为一致。本任务不修改 .gitignore（治理属 TASK-009/下游任务）。
> 测试方法（任务 testMethod）：目录核对（弃用脚本已移除）；全量脚本与文档引用关系检查（grep deploy-env 确认无残留引用）。
> 用例编号延续版本测试用例文档空间（v0.2.7 中 TASK-007 末：TC-091、UT-214、FT-144、UIT-023），本任务新用例从 **TC-092、UT-215、FT-145、UIT-024** 起编号。
> 已确认的允许例外（grep deploy-env 命中但不构成残留）：docs/prompts/prompt-*.md（历史会话存档）、docs/sad.md ADR-016 决策描述、docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md（P2 问题记录）、docs/cso-v0.2.7/ 本版本任务文档自身（context/cs/ws/testcase）、v0.2.5 归档测试脚本（cso-unit-test-deploy-acceptance-v0.2.5.ps1 / cso-unit-test-scripts-migrate-v0.2.5.ps1）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 清理弃用脚本残留并同步引用关系（F-011 / US-004 / ADR-016 / 上游 TASK-001 issue-list P2+P7-09）：TASK-008 | TASK-008 | 16 | P0×9、P1×6、P2×1 |
| 其中：单元测试（弃用脚本工作区移除、git 跟踪删除、目录仅保留能力矩阵/合法脚本清单核对、保留脚本无 deploy-env 引用、deploy.md 目录树同步、README 引用同步、deployment-guide 双副本同步、全项目 grep 无残留引用、双平台成对与 SPDX 头） | TASK-008 | 9 | P0×7、P1×2 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-008 | 2 | P1×1、P2×1 |
| 其中：功能测试（git 删除记录核对、引用关系逐项人工核对、测试脚本断言反转更新核对、保留脚本冒烟验证） | TASK-008 | 4 | P0×3、P1×1 |
| 其中：UI 测试（无 UI 变更确认） | TASK-008 | 1 | P1×1 |

## 二、测试用例详情

### 模块：清理弃用脚本残留与引用关系同步 - 单元测试（静态核对）

#### UT-215：弃用脚本文件已从工作区移除（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-215-1（3 个弃用脚本 Test-Path 均 False）/UT-215-2（目录无 deploy-env* 文件名残留）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-215-1 通过（deploy-env.ps1 / deploy-env-template.ps1 / deploy-env-template.sh Test-Path 全部 False，已彻底移除）；UT-215-2 通过（Get-ChildItem 目录清单无任何 deploy-env* 文件名残留）；脚本断言级 PASS=22/FAIL=0。

#### UT-216：git 跟踪确认弃用脚本已删除（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-216-1（git ls-files 无 deploy-env 跟踪）/UT-216-2（删除记录存在：暂存 D 或 git log --diff-filter=D）/UT-216-3（3 个弃用脚本均在 D 清单）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-216-1 通过（git ls-files deploy/scripts 无任何 deploy-env* 跟踪文件）；UT-216-2 通过（删除记录齐备：暂存区 git diff --cached 显示 3 个文件均以 D 状态删除）；UT-216-3 通过（3 个弃用脚本全部在删除记录 D 清单中）。

#### UT-217：目录仅保留能力矩阵脚本与合法脚本（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-217-1（条目数=25）/UT-217-2（12 组双平台 24 文件 + .gitkeep 齐全）/UT-217-3（实际清单与预期 25 条目精确比对，无多余文件）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-217-1 通过（目录条目数=25）；UT-217-2 通过（12 组双平台 24 文件 + .gitkeep 全部在清单）；UT-217-3 通过（实际清单与预期精确匹配，无多余文件、无 deploy-env* 残留、无临时/备份文件）。

#### UT-218：保留脚本无 deploy-env* 引用，加载路径不失效（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-218-1（保留脚本 grep deploy-env=0）/UT-218-2（check-env/start-services/start-all/start-gateway 加载语句抽查）/UT-218-3（7 组 14 个能力脚本全部引用 load-env）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-218-1 通过（全部 24 个保留脚本 grep deploy-env 0 命中）；UT-218-2 通过（4 类脚本 .ps1/.sh 加载语句均正确引用 `$PSScriptRoot\load-env.ps1` / `$SCRIPT_DIR/load-env.sh`）；UT-218-3 通过（7 组 14 个能力/基础设施脚本全部引用 load-env，依赖关系完整、加载路径不失效）。

#### UT-219：deploy/deploy.md 目录树同步更新（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-219-1（deploy.md 无 deploy-env 声明）/UT-219-2（目录树 12 组脚本名与实际目录一致）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-219-1 通过（deploy/deploy.md 无任何 deploy-env* 声明，原第 72-73 行已移除）；UT-219-2 通过（目录树 12 组脚本名与实际目录一一对应，文档与事实相符）。

#### UT-220：README.md 部署指引同步更新（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-220-1（README 无 deploy-env 残留）/UT-220-2（指引已更新为 env.example.json → env.json 复制用法且 env.example.json 存在）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-220-1 通过（README.md 无 deploy-env* 残留引用，原第 229 行已更新）；UT-220-2 通过（指引已改为 `cp deploy/env.example.json deploy/env.json` / `Copy-Item deploy\env.example.json deploy\env.json` 用法且 deploy/env.example.json 文件真实存在）。

#### UT-221：deployment-guide.md 双副本引用同步（P1）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-221-1/221-2（双副本均无 deploy-env 残留）/UT-221-3（双副本 SHA256 一致）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-221-1 通过（scripts/deployment-guide.md 无 deploy-env* 残留）；UT-221-2 通过（docs/deployment-guide.md 无 deploy-env* 残留）；UT-221-3 通过（双副本 SHA256 完全一致 F1ADE3C8...CF15D，无单侧修改）。

#### UT-222：全项目 grep deploy-env 无残留引用（P0）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-222-1（全项目 grep deploy-env，允许例外清单过滤后 0 残留）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-222-1 通过（全项目递归扫描，排除 .git/node_modules/target 等目录，所有命中均可归入允许例外清单（docs/prompts 会话存档、docs/sad.md ADR-016、v0.2.5/0.2.6 历史归档、本版本任务文档、v0.2.5 归档测试、v0.2.7 测试脚本断言自身），例外之外 0 残留）。

#### UT-223：保留脚本双平台成对与文件头规范（P1）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-223-1（12 组 .ps1+.sh 全部成对）/UT-223-2（无单版本残留）/UT-223-3（deploy.md/README.md/deployment-guide.md 双副本保留 SPDX 与 Copyright）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——UT-223-1 通过（12 组 .ps1+.sh 全部成对）；UT-223-2 通过（无单版本残留）；**UT-223-3 通过（编码缺口已补齐转通过）**：deploy.md、README.md、scripts/deployment-guide.md、docs/deployment-guide.md 4 个修改文档均保留 SPDX-License-Identifier（Apache-2.0）与 Copyright 2026 jenemy8023 行（deployment-guide.md 双副本 writetest 冒烟时缺 SPDX 为真实编码缺口，编码阶段已补齐，正式执行转通过）。

### 模块：接口测试（本任务无接口变更）

#### TC-092：无接口变更确认（P1）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py test_tc092_no_api_change（TC-092-1 版本 API 文档声明无变更 /TC-092-2 git 变更无接口层文件 /TC-092-3 API-001~033 契约保留 /TC-092-4 变更范围仅限脚本清理与文档同步）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——TC-092-1 通过（cso-api-v0.2.7.md 声明本版本无新增/变更/删除接口）；TC-092-2 通过（git 变更清单无 Controller/DTO/响应体/网关路由等接口层文件）；TC-092-3 通过（API-001~API-033 全部契约在 API 文档中完整保留）；TC-092-4 通过（变更范围仅限 deploy/scripts 弃用脚本清理与文档同步，deploy-env* 删除记录在变更清单/删除记录中可见，无 .java/.dart/.yml 接口层改动，符合 ADR-016）。

#### TC-093：健康检查端点契约探活（P2，可选）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py test_tc093_health_probe（TC-093-1 gateway 9000 根路径探活 /TC-093-2~4 auth 9100、biz 9200、system 9400 健康检查探活，服务未启动按环境 SKIP）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：SKIP（环境）】**——TC-093-1~4 探活断言（gateway 9000 / auth 9100 / biz 9200 / system 9400）因本机 Python 环境未安装 requests 库无法发起 HTTP 探活，按脚本规定"requests 未安装/服务未启动时记录 SKIP，不作为失败"处理，接口静态回归已由 TC-092 全面覆盖；该探活纳入回归测试在具备 requests 的环境执行。

### 模块：功能测试（清理效果与引用关系核对）

#### FT-145：弃用脚本 git 删除记录核对（P0）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「四、功能测试记录（FT-145 ~ FT-148，TASK-008）」FT-145 节（git 删除记录核对，断言由 cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1 UT-216 覆盖）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——git 删除记录核对完成：git ls-files 无 deploy-env* 跟踪、git diff --cached 删除记录齐备（3 个弃用脚本均以 D 状态删除）、UT-216-1/2/3 全部通过，删除记录完整可审计，提交信息符合 Conventional Commits 规范（由 impm-task-coding-gitcommit 步骤执行）。

#### FT-146：全量脚本与文档引用关系逐项核对（P0）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「四、功能测试记录（FT-145 ~ FT-148，TASK-008）」FT-146 节（引用关系逐项核对，断言由 UT-218~222 覆盖）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——引用关系清单逐项处置到位：deploy/deploy.md 目录树（UT-219）、README.md 部署指引（UT-220）、deployment-guide.md 双副本（UT-221）、docs/cso-lld.md 已本任务同步、docs/cso-testcase.md 主文档按 PM 确认由 doc-merge 统一处理（UT-222 例外清单记录）、全项目 grep deploy-env 例外之外 0 残留、保留脚本加载路径不失效（UT-218），无遗漏。

#### FT-147：测试脚本断言反转更新核对（P0）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「四、功能测试记录（FT-145 ~ FT-148，TASK-008）」FT-147 节（测试脚本断言反转核对：cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 UT-134/143 反转、UT-193-3 保留）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——测试脚本断言反转核对完成：cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 中 UT-134-1/134-2（弃用脚本存在断言）已反转为负向断言、UT-143-2（单版本残留断言）已更新为"无单版本残留"、P2 问题断言（deploy.md 引用 deploy-env）已同步为历史依据核对；cso-unit-test-start-single-v0.2.7.ps1 的 UT-193-3 负向断言保留作回归依据；与本任务新脚本 UT-215~223 互补，正式执行全部通过。

#### FT-148：保留脚本清理后冒烟验证（P1）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「四、功能测试记录（FT-145 ~ FT-148，TASK-008）」FT-148 节（保留脚本冒烟：.ps1 Parser 解析零错误 / .sh 无 bash 时降级结构核对 / load-env 加载链路完整）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——保留脚本冒烟验证通过：12 个 .ps1 PowerShell Parser 解析零错误；12 个 .sh 因本机无 bash/WSL 降级为 shebang+结构核对（均含 shebang 且非空，按环境降级不作为失败）；load-env 加载链路完整（7 组 14 个能力脚本引用路径真实存在，UT-218-2/3 通过）；目录结构 25 条目精确匹配（UT-217/UT-223-1/2 通过），清理未破坏脚本可用性。

### 模块：UI 测试（无 UI 变更确认）

#### UIT-024：客户端 UI 无任何变更（P1）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「四、功能测试记录（FT-145 ~ FT-148，TASK-008）」UIT-024 节（git 变更清单静态核对无 cloudoffice-flutter-app 路径文件）
- **测试过程与结论**：**【正式执行 2026-08-10（impm-task-coding-runtest）：PASS】**——git 变更清单静态核对：TASK-008 变更仅含 deploy/scripts 弃用脚本删除、文档同步（deploy.md/README.md/lld/deployment-guide 双副本）、版本文档与测试脚本，无任何 cloudoffice-flutter-app 路径文件，客户端 UI/交互/运行行为零变更，无需 UI 测试。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 15（用例级：单元 9 + 接口 1 + 功能 4 + UI 1；断言级：单元脚本 PASS=22/FAIL=0、接口脚本 PASS=31/FAIL=0/SKIP=22） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 1（用例级：TC-093 探活因本机 Python 未安装 requests 按环境 SKIP，不作为失败） |

> **正式执行结果（2026-08-10，impm-task-coding-runtest）**：单元测试脚本 `scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1` 断言级 **PASS=22/FAIL=0**（UT-215~223 全部 22 个断言通过：弃用脚本 Test-Path 均 False、git ls-files 无跟踪且删除记录齐备、目录精确 25 条目、保留脚本与 4 类文档无 deploy-env 引用、deployment-guide 双副本 SHA256 一致、全项目 grep 例外清单过滤后 0 残留、12 组双平台成对、4 个修改文档保留 SPDX/Copyright——**UT-223-3 编码缺口（deployment-guide.md 双副本缺 SPDX 行）已由编码阶段补齐，转通过**）；接口测试脚本 `scripts/API-TEST/cso-api-test-v0.2.7.py` 全量 **PASS=31/FAIL=0/SKIP=22**（TASK-008 相关 TC-092 静态回归 4 断言全部通过；TC-093 探活 4 断言因本机 Python 未安装 requests 按环境 SKIP，不作为失败；接口静态契约由 TC-092 全面覆盖）；功能测试 FT-145~148 全部通过、UI 测试 UIT-024 通过；用例级结果：**通过 15、跳过 1（TC-093 环境 SKIP）、失败 0、阻塞 0**。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 本机无 bash/WSL | .sh 相关动态验证无法执行 | bash -n 降级为 shebang+结构核对（本任务以 grep 与目录核对为主，.sh 动态验证影响有限）；FT-148 冒烟以 .ps1 Parser 解析为主 |
| grep deploy-env 存在历史存档例外命中 | 误判为残留引用 | 明确允许例外清单（docs/prompts、sad.md ADR-016、issue-list、任务文档自身、v0.2.5 归档测试），UT-222/FT-146 断言按例外清单过滤核对 |
| 文档引用行号随编辑漂移 | 按行号定位失败 | 引用核对以内容匹配（grep 关键词）为准，不依赖固定行号；UT-219/220/221 均按内容断言 |
| docs/cso-lld.md 与 docs/cso-testcase.md 主文档同步范围 | 主文档残留 deploy-env 引用 | 与 PM 确认处理范围（本任务同步或 doc-merge 统一处理），确认结论记录于 FT-146 |
| 测试脚本断言反转遗漏 | 历史正向断言（UT-134/UT-143）与清理结果冲突持续失败 | FT-147 专项核对断言反转/移除；UT-193-3 负向断言保留作回归依据 |
| 误删合法脚本 | 删除范围扩大破坏脚本体系 | UT-217 精确清单核对（12 组双平台 + .gitkeep = 25 条目），build-*/deploy-db-init 明确不在删除范围 |
| 真实环境服务运行 | 探活/冒烟影响既有服务 | TC-093 探活仅读健康端点；FT-148 冒烟仅语法解析与静态核对，不启动服务 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（**impm-task-coding-runtest 步骤正式执行完毕**：单元测试脚本 `scripts/API-TEST/cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1` 断言级 **PASS=22/FAIL=0**——UT-215~223 全部通过，**UT-223-3 编码缺口（deployment-guide.md 双副本缺 SPDX 行）已补齐转通过**；接口测试脚本 `scripts/API-TEST/cso-api-test-v0.2.7.py` 全量 **PASS=31/FAIL=0/SKIP=22**（TC-092 静态回归全部通过，TC-093 探活因本机 Python 未安装 requests 按环境 SKIP 不作为失败，退出码 0）；功能测试 FT-145~148 全部通过、UI 测试 UIT-024 通过；用例级 **通过 15 / 失败 0 / 阻塞 0 / 跳过 1（TC-093 环境 SKIP）**；全部测试通过，TASK-008 编码开发成功完成，TE 签名确认）
- 项目经理（PM）：待执行

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
