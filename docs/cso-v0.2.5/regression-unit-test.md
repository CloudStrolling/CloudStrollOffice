# 单元测试回归报告（regression-unit-test）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**测试时间**：2026-08-09 16:02 ~ 16:34（UT-089-3 复测补记：2026-08-09，TASK-005-修复 1a61b33 之后）
**测试负责人**：TE
**测试类型**：全量单元测试回归（Maven Java 单元测试 + v0.2.5 PowerShell 静态校验脚本）

## 一、运行环境

| 项 | 值 |
| --- | --- |
| 操作系统 | Windows 10 x64（amd64） |
| JDK | Eclipse Adoptium 21.0.9（JAVA_HOME: C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot） |
| Maven | Apache Maven 3.9.16（D:\jenemy\develop\maven\apache-maven-3.9.16） |
| PowerShell | Windows PowerShell 5.1 |
| 项目根目录 | D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice |

## 二、执行命令

| 批次 | 执行命令 |
| --- | --- |
| Maven 全量 | `mvn test`（根目录，Reactor 全 6 模块：root/common/gateway/auth/biz/system） |
| UT-061~072（TASK-001/002） | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-deploy-v0.2.5.ps1 -ProjectRoot <根>` |
| UT-073~078（TASK-003） | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-scripts-migrate-v0.2.5.ps1 -ProjectRoot <根>` |
| UT-079~084（TASK-004） | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-build-deploy-v0.2.5.ps1 -ProjectRoot <根>` |
| UT-085~090（TASK-005） | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-client-build-v0.2.5.ps1 -ProjectRoot <根>` |
| UT-091~096（TASK-006） | `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-deploy-acceptance-v0.2.5.ps1 -ProjectRoot <根>` |

## 三、统计结果

| 批次 | 用例数 | 通过 | 失败 | 说明 |
| --- | --- | --- | --- | --- |
| Maven（common） | 115 | 115 | 0 | BUILD SUCCESS |
| Maven（gateway） | 30 | 30 | 0 | BUILD SUCCESS |
| Maven（auth-service） | 253 | 253 | 0 | BUILD SUCCESS |
| Maven（biz-service） | 3 | 3 | 0 | BUILD SUCCESS |
| Maven（system-service） | 3 | 3 | 0 | BUILD SUCCESS |
| Maven 小计 | 404 | 404 | 0 | Reactor 6/6 SUCCESS，总耗时 01:11 min |
| UT-061~072（TASK-001/002） | 12 | 12 | 0 | 复测通过（首测 2 项脚本缺陷，见下） |
| UT-073~078（TASK-003） | 17 | 17 | 0 | 脚本内断言细分 17 项 |
| UT-079~084（TASK-004） | 19 | 19 | 0 | 脚本内断言细分 19 项 |
| UT-085~090（TASK-005） | 17 | 17 | 0 | 复测通过（TASK-005-修复 1a61b33 后，断言含 UT-089-1~4） |
| UT-091~096（TASK-006） | 22 | 22 | 0 | 脚本内断言细分 22 项 |
| PowerShell 小计 | 87 | 87 | 0 | 断言级别 87 项 |
| **合计** | **491** | **491** | **0** | 通过率 100% |

## 四、失败用例清单及原因

### 4.1 UT-089-3：deploy 客户端产物入库规则（P1，负向/版本管理）——已修复并复测通过（闭环）

- **现象（首测）**：`git ls-files deploy/cloudoffice-flutter-app` 显示 51 个文件被 git 跟踪，断言要求"deploy 客户端子树仅跟踪 .gitkeep"。
- **失败明细（首测）**：deploy/cloudoffice-flutter-app/web/ 下 48 个文件（main.dart.js、canvaskit/*.js、*.wasm、assets/*、icons/* 等）与 windows/data/ 下 3 个文件（icudtl.dat、flutter_assets/* 等）已被 git 跟踪。
- **根因分析**：
  1. 根 .gitignore 第 244/245 行已忽略 `*.exe`/`*.dll`（windows 顶层 exe/dll 未被跟踪），但 **web/ 构建产物（.js/.wasm/.png/.json/.otf/.ttf）无任何忽略规则**；
  2. TASK-005 提交（1dabc84，2026-08-09 15:25:41）将 55 个 deploy 文件一并提交入库（其中 51 个为客户端构建产物），违反"deploy 产物集中、构建产物不入库"的版本管理契约（UT-089 用例要求、AC 验收口径）。
- **修复内容（TASK-005-修复，commit 1a61b33）**：根 .gitignore 新增 deploy 下客户端产物忽略规则（deploy/cloudoffice-flutter-app/web/、deploy/cloudoffice-flutter-app/windows/data/ 等目录规则），并执行 `git rm --cached` 移除已跟踪的 51 个构建产物（保留 .gitkeep）；修复后 `git ls-files deploy/cloudoffice-flutter-app` 仅剩 .gitkeep。
- **复测记录**：重跑 `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\API-TEST\cso-unit-test-client-build-v0.2.5.ps1 -ProjectRoot <根>`，**UT-085~090 共 17 项断言全部通过（PASS=17 FAIL=0，含 UT-089-1~4）**，UT-089-3 已闭环。
- **影响**：仓库恢复纯净（构建产物不再入库），后续构建产物更新不再产生噪音 diff。

### 4.2 已修复的测试脚本缺陷（首测失败 → TE 修复脚本 → 复测通过，不计入最终失败）

| 用例 | 首测现象 | 根因 | 修复内容 | 复测 |
| --- | --- | --- | --- | --- |
| UT-065（TASK-001，P1） | deploy 检出 10 个"源文件" | 脚本把 `.js` 列为源文件黑名单，而 TASK-005 后 Flutter Web 构建产物（main.dart.js、canvaskit/*.js 等 10 个 .js）合法落位 deploy/cloudoffice-flutter-app/web，断言与产物契约冲突 | 脚本排除客户端产物目录（deploy/cloudoffice-flutter-app）下的文件后再做源文件扫描 | 通过 |
| UT-070（TASK-001，P1） | 找不到 env.example.json 历史版本 | 脚本用 `git log -1 -- env.example.json` 返回的是 TASK-002 删除提交（39f6be9），该提交中路径已不存在，`git show <commit>:env.example.json` 必然失败；迁移提交后历史获取分支失效 | 脚本改用 `git log --diff-filter=D` 找删除提交，读取其父提交版本（`<commit>^:env.example.json`）比对哈希 | 通过 |

## 五、结论

- **全量单元测试通过 491/491（100%）**：UT-089-3（TASK-005 提交时客户端构建产物误入库的版本管理缺陷）已由 TASK-005-修复（commit 1a61b33）修复，复测 cso-unit-test-client-build-v0.2.5.ps1 全部 17 项断言通过（PASS=17 FAIL=0），**UT-089-3 已闭环**。
- 首测暴露的 2 个测试脚本缺陷（UT-065/UT-070）已由 TE 修复脚本并复测通过，脚本修改记录于 git diff（scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1）。
- 失败闭环情况：产品缺陷闭环 1/1（UT-089-3）；测试脚本缺陷闭环 2/2。

## 六、签名确认

- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：待确认

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
