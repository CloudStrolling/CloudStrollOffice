# 任务上下文（TASK-005：修改 Flutter 客户端构建配置，安装产物统一输出至 deploy）

> 本上下文由 impm-task-coding-context 技能生成，供编码开发阶段使用。
> 项目：云漫智企（CloudStrollOffice，cso）｜版本：v0.2.5｜任务：TASK-005

## 1. 用户输入（需求来源原文）

本次修改的版本为 cso-v0.2.5。修改内容如下：
1. 新建一个目录 deploy；
2. 修改配置，将所有模块生成的最终产物（如 jar 包、安装文件、exe 文件等）都最终生成到 deploy 目录下（注意：生成阶段的中间产物不要复制过去）；
3. env.json 和 env.example.json 迁移到这个目录；
4. deploy 目录下建 scripts 子目录，将目前 scripts 下所有的 sh 和 ps1 迁移到这个子目录。

## 2. 任务信息

| 属性 | 值 |
| --- | --- |
| 任务编号 | TASK-005 |
| 任务名称 | 修改 Flutter 客户端构建配置：安装产物统一输出至 deploy |
| 任务描述 | 修改 cloudoffice-flutter-app 客户端构建脚本/配置，使客户端构建生成的最终可交付产物（Windows 安装程序 exe、Web 部署包等）输出到 deploy 目录；仅复制最终可交付产物文件，构建缓存（build/ 目录）与过程文件不进入 deploy。对应 PRD F-003、F-004。 |
| 任务类型 | common |
| 用户故事 | US-002 |
| 上游依赖 | TASK-001（新建 deploy 目录） |
| 下游任务 | TASK-006 |
| 优先级 | P0 |
| 当前状态 | 未完成 |
| 测试方法 | 构建验证：执行客户端构建后校验安装文件/exe 等最终产物出现在 deploy 目录，构建缓存/过程文件未混入 |
| 验收标准 | AC-3：执行 Flutter 客户端构建后，安装文件/exe 等最终产物出现在 deploy 目录。AC-4：构建完成后 deploy 目录内不出现构建缓存与过程文件等中间产物 |

## 3. 用户故事（US-002：最终构建产物统一输出到 deploy）

- 故事描述：作为后端/客户端开发工程师，我想要构建后的最终产物（jar 包、安装文件/exe）自动输出到 deploy 目录，以便在统一位置获取可交付产物。
- 前置条件：Maven 多模块构建配置与 Flutter 客户端构建配置可正常执行构建。
- 验收标准：
  - Given 执行 Maven 各模块 package，When 构建成功，Then 四个后端服务的最终 jar 包出现在 deploy 目录；
  - Given 执行 Flutter 客户端构建，When 构建成功，Then 安装文件/exe 等最终产物出现在 deploy 目录；
  - Given 构建完成，When 检查 deploy 目录，Then 无中间产物混入（target 类目录、编译临时文件、测试产物均不在其中）。
- 边界情况与错误处理：
  - 同名 jar 产物：产物命名保持模块可辨识，不发生覆盖；
  - 中间产物误复制：构建配置仅复制最终产物文件，不整目录递归复制。
- 关联功能编号：F-002、F-003、F-004。

## 4. 关联 PRD 功能需求（F-003、F-004 详述）

### F-003 客户端安装产物输出到 deploy
- 功能描述：修改 Flutter 客户端构建配置，使客户端构建生成的安装文件/exe 等最终产物（如 Windows 安装程序 exe、Web 部署包等）输出到 `deploy` 目录。
- 业务规则：
  - 客户端构建成功后，最终可交付产物（安装文件/exe 等）必须出现在 `deploy` 目录；
  - 若构建工具链默认输出到构建临时目录，则通过构建脚本/配置将最终产物复制到 `deploy`，中间构建过程文件不得随之进入。

### F-004 中间产物不入 deploy
- 功能描述：确保构建阶段产生的中间产物（如 Flutter 构建缓存/过程文件等）不会进入 `deploy` 目录。
- 业务规则：
  - `deploy` 目录内禁止出现 target 类中间目录、编译临时文件、测试报告等中间产物；
  - 只允许最终产物（jar 包、安装文件/exe、环境配置、部署脚本）进入 `deploy` 目录；
  - 若通过复制方式生成产物，复制动作必须仅针对最终产物文件，严禁整目录递归复制构建输出目录。

## 5. 验收标准（本任务相关）

- **AC-3**：执行 Flutter 客户端构建后，安装文件/exe 等最终产物出现在 `deploy` 目录。
- **AC-4**：构建完成后，`deploy` 目录内不出现 target 类中间目录、编译临时文件、测试产物等中间产物。

## 6. 系统架构相关（SAD v0.2.5）

### 设计目标 G-A6 部署资产集中化
以根目录 `deploy` 为全部最终构建产物（后端微服务 jar 包、客户端安装文件/exe）与部署资产（env.json/env.example.json、deploy/scripts 下 .sh/.ps1 部署运维脚本）的唯一落点，实现"产物集中、纯净交付、迁移无损"；构建中间产物（target 目录、编译临时文件、测试产物）一律不进入 deploy。

### 设计约束（部署资产约束）
- 最终构建产物（后端各服务 jar 包、客户端安装文件/exe）统一输出至根目录 `deploy` 目录；
- 环境配置 `env.json`/`env.example.json` 与部署运维脚本（`deploy/scripts` 下的 .sh/.ps1）集中存放于 deploy 下；
- 构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy；
- 迁移后脚本内环境配置/密钥/产物路径引用必须同步适配，保证部署功能不因路径变化失效。

### 技术选型（构建产物管理）
Maven 构建插件（如 maven-antrun-plugin/copy 插件）+ Flutter 构建脚本：将各模块最终产物（后端 jar 包、客户端安装文件/exe）集中输出到根目录 `deploy`，仅复制最终产物、隔离中间产物，交付人员单目录获取全部可交付资产。

### 架构决策 ADR-013
新建根目录 `deploy` 作为全部最终构建产物唯一落点（后端 jar 包、客户端安装文件/exe）；`env.json`/`env.example.json` 迁移至 deploy；scripts 下全部 .sh/.ps1 迁移至 `deploy/scripts` 并同步适配路径引用；构建中间产物禁止进入 deploy。理由：产物集中、纯净交付、迁移无损；发布/交付人员单目录收集全部可交付资产；源代码与运行/部署资产清晰分离，部署运维入口统一。日期：2026-08-09。

### 部署资产说明（SAD 第 6 章）
根目录 `deploy` 为最终构建产物与部署资产的唯一落点——Maven 各模块 package 生成的最终 jar 包与 Flutter 客户端构建生成的安装文件/exe 均输出到 `deploy` 目录；`env.json`/`env.example.json` 环境配置与 `deploy/scripts` 下全部 .sh/.ps1 部署运维脚本集中存放；构建中间产物（target 目录、编译临时文件、测试产物等）禁止进入 deploy。

## 7. 项目信息要点（project.md）

- 项目类型：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）。
- 客户端：`cloudoffice-flutter-app`，Flutter（Dart 3，SDK ^3.12.2），支持 Web 与 Windows 双平台；依赖 dio 5.4、provider 6.1、go_router 14.2、flutter_secure_storage_x 13.1、shared_preferences 2.2；dev 依赖 flutter_lints 6.0、mockito 5.4。
- 根目录关键结构：`pom.xml`（Maven 父 POM）、`checkstyle.xml`/`.editorconfig`、`env.json`/`env.example.json`、`keys/`（RSA 密钥，不入库）、`scripts/`（部署脚本 deploy-*.ps1/sh、sql/、docker/、API-TEST/）、`docs/`。
- 目录组织约定：客户端独立 Flutter 工程，按 Flutter 标准目录组织（lib/、test/、web/、windows/）。
- 提交信息遵循 Conventional Commits 规范；禁止提交密钥、密码等敏感信息。

## 8. 编码注意事项（TL 提示）

1. 本任务聚焦客户端（cloudoffice-flutter-app）构建配置，即 PRD F-003/F-004，对应验收 AC-3/AC-4；deploy 目录创建（F-001）由上游 TASK-001 负责，本任务需确认其已存在。
2. 客户端最终产物（Windows 安装程序 exe、Web 部署包等）输出位置由构建脚本/配置决定；若工具链默认输出到构建临时目录（如 build/），须通过构建脚本/配置仅复制最终产物文件到 `deploy`，严禁整目录递归复制。
3. 构建缓存（build/ 目录）与过程文件不得进入 deploy（AC-4）。
4. 脚本内部路径引用（如 env.json、jar 包路径）如涉及本任务产出物位置，须与迁移后的 deploy 目录结构保持一致。
5. 测试方式为构建验证：执行客户端构建后校验最终产物出现在 deploy、中间产物未混入。

## 9. 测试失败信息（impm-task-coding-runtest 回退记录，第 1 次失败）

- **失败用例**：FT-023（P0，端到端构建验证——执行客户端构建脚本后 Windows 安装产物出现在 deploy），另 FT-024/FT-025/FT-026/UIT-010 因依赖产物阻塞。
- **复现命令**：`powershell -ExecutionPolicy Bypass -File cloudoffice-flutter-app\build-release.ps1 -Platform all`（工作目录 cloudoffice-flutter-app，Flutter 3.44.3 / Dart 3.12.2 环境可用）。
- **实际现象**：脚本第 23 行 `$ClientDeployDir = Join-Path $DeployDir "cloudoffice-flutter-app"` 报错「无法将参数绑定到参数 Path，因为该参数是空值」（ParameterArgumentValidationErrorNullNotAllowed），EXIT=1；$ScriptDir/$ProjectDir/$DeployDir 全部为空，flutter 构建未执行。
- **根因（字节级定位）**：`cloudoffice-flutter-app\build-release.ps1` 文件编码为 **UTF-8 无 BOM + LF 行尾**（首字节 3C 23 0A；UTF8 严格解码 VALID；行尾 CRLF=0、LF=88）。Windows PowerShell 5.1 对无 BOM 文件按 ANSI(GBK) 代码页解码，UTF-8 中文注释被错误解码导致脚本解析异常、`$PSScriptRoot` 为空，所有基于脚本自定位的路径变量失效。
- **对比验证**：
  1. 同逻辑测试脚本（UTF-8 无 BOM + LF + 中文注释）在 PowerShell 5.1 下 100% 复现该错误；纯 ASCII 版正常；
  2. build-release.ps1 转 **UTF-8 带 BOM** 后路径推导全部正确（$DeployDir=项目根\deploy），正常执行至「deploy 目录不存在」前置检查；
  3. 既有 ANSI(GBK) 编码脚本 `deploy\scripts\load-env.ps1`（NOT-UTF8）在 PowerShell 5.1 下执行正常（FT-015 冒烟通过）。
- **修复建议**：将 `cloudoffice-flutter-app\build-release.ps1` 重新保存为 **ANSI/GBK 编码**（与 deploy/scripts 下既有 .ps1 一致）或 **UTF-8 带 BOM**；建议同时检查 build-release.sh 编码（当前 VALID-UTF8，Bash 下无 BOM 可正常执行，但若需与既有 .sh 一致可考虑 ANSI/UTF-8 均兼容处理）；修复后需重新执行 UT-085~090（静态断言不受编码影响，应保持通过）与 FT-023~026、UIT-010。
- **已通过项（修复后需保持）**：UT-085~090 单元测试 16/16 通过；TC-050 接口回归 5/5 通过；UIT-010 步骤 3（git 无 lib 变更）通过。
<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
