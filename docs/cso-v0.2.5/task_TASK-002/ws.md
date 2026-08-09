# 网络查询结果（#TASK-002 迁移 env.json 与 env.example.json 至 deploy 目录）

## 1. 任务概述

本任务（TASK-002）为 v0.2.5「部署资产集中化」系列任务之一，仅负责将项目根目录的 `env.json`、`env.example.json` 两个环境配置文件迁移至 `deploy/` 目录（`deploy/env.json`、`deploy/env.example.json`），迁移后项目根目录不得残留（验收 AC-5）。脚本路径引用适配属 TASK-003 范围，本任务不涉及。

**三方组件结论**：本任务为纯文件迁移（git 仓库内文件移动），不依赖任何第三方中间件、包或 SDK，无需引入新依赖。涉及的技术组件均为开发环境自带：Git（git mv / .gitignore）、PowerShell（Move-Item / Get-FileHash）。

## 2. 相关技术资料（官方文档）

### 2.1 Git 文件迁移：git mv（官方：https://git-scm.com/docs/git-mv）

- 语法：`git mv <source> <destination>`（单文件重命名/移动）；`git mv <source>... <destination-directory>`（移动到已存在目录）。
- 行为：成功移动后更新索引（index），但**仍需 commit** 提交。
- 关键限制：`git mv` 仅对**已被 Git 跟踪（tracked）的文件**有效；当源文件「不存在或不受 Git 控制（untracked/ignored）」时，报错 `fatal: not under version control, source=...`（官方 OPTIONS 中 `-k` 说明明确指出：error happens when a source is neither existing nor controlled by Git）。
- 常用参数：`-f`（目标已存在时强制覆盖）、`-n`（演练，只显示将发生的操作）、`-v`（显示移动明细）、`-k`（跳过会导致错误的移动）。

**对本任务的直接结论**：
- `env.example.json` 已入库（tracked）：若确认 `git ls-files env.example.json` 有记录，可用 `git mv env.example.json deploy/env.example.json` 保留历史；`git mv -n` 可先演练。
- `env.json` 被 .gitignore 忽略（未跟踪）：`git mv` 对其必然报 `not under version control`，**只能用文件系统移动命令**（Windows PowerShell 的 `Move-Item`）。

### 2.2 .gitignore 匹配规则（官方：https://git-scm.com/docs/gitignore）

- PATTERN FORMAT：如果模式**开头或中间无斜杠**（如 `env.json`），则该模式匹配 `.gitignore` 文件所在层级以下**任意目录**中的同名文件；只有在开头/中间有分隔符时才锚定相对路径。
- 已跟踪文件不受 .gitignore 影响（NOTES 节）；如需停止跟踪用 `git rm --cached`。
- 可用 `git check-ignore -v <path>` 查询某路径命中的忽略规则来源。

**对本任务的直接结论**：`.gitignore` 第 311 行 `env.json`（无路径前缀）在迁移后仍会匹配 `deploy/env.json`，**无需修改 .gitignore**，`deploy/env.json` 自动保持不被提交（安全，敏感文件不入库）；`env.example.json` 不在忽略规则内，迁移后正常入库。

### 2.3 PowerShell Move-Item（官方：https://learn.microsoft.com/powershell/module/microsoft.powershell.management/move-item）

- 语法：`Move-Item [-Path] <String[]> [[-Destination] <String>] [-Force] [-PassThru] [-WhatIf]`；另有 `-LiteralPath` 参数集（路径按字面处理、不做通配符解析）。
- 行为：将项目从原位置移动到新位置，移动后从原位置删除；若目标为**已存在的容器（目录）**，则项目移入该目录内。
- 注意事项：
  - 目标已存在同名项或目标解析为已存在的非容器项时报错，需 `-Force` 覆盖。
  - 移动是递归的（目录会连内容一起移动）；目录移动仅在**同一驱动器**内支持，文件移动可跨驱动器。
  - `-WhatIf` 可演练不实际执行；`-PassThru` 返回被移动项目对象。
- 别名：`mi`、`move`（全平台），Windows 下 `mv`。

**对本任务的直接结论**：`Move-Item -Path env.json -Destination deploy\env.json` 可实现 env.json 迁移（deploy 目录已存在，直接移入）；执行前建议先 `Move-Item -WhatIf` 演练。

### 2.4 PowerShell Get-FileHash（官方：https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/get-filehash）

- 语法：`Get-FileHash [-Path] <String[]> [[-Algorithm] <String>]`；默认算法 **SHA256**（支持 SHA1/SHA256/SHA384/SHA512/MD5）。
- 用途：两个文件哈希一致 ⇒ 内容完全一致；可用于迁移前后内容一致性校验。

**对本任务的直接结论**：迁移前后分别 `Get-FileHash env.json` / `Get-FileHash deploy\env.json` 对比哈希值，可验证迁移无损（内容不变）。

## 3. 版本兼容性核对结论

| 组件 | 本地版本（实测） | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Git | 2.53.0.windows.1（`git --version` 实测） | git-mv 文档最新 2.50.0+ 无变化、gitignore 文档 2.55.0 | 兼容。git mv 核心行为自 2.0 起稳定，`not under version control` 报错行为与文档一致 |
| PowerShell | 5.1.19041.7548（`$PSVersionTable` 实测） | Move-Item / Get-FileHash 文档均提供 powershell-5.1 版本 | 兼容。Move-Item、Get-FileHash（默认 SHA256）在 PS 5.1 完全可用，与 7.x 文档行为一致 |

无需任何升级或特殊适配。

## 4. 排错经验与注意事项（git 迁移相关）

来源：Git 官方文档 + Stack Overflow / DevErrors 技术社区（2025-2026 年实践总结）。

1. **git mv 报 `fatal: not under version control, source=...`**：
   - 原因：源文件未被跟踪——从未 add、被 `git rm --cached` 移除过、或命中 .gitignore 从未强制加入。
   - 解决（官方推荐）：对 untracked 文件直接用普通 `mv`（Windows 下 `Move-Item`）移动，再 `git add` 新路径；对 ignored 文件如需入库可 `git add -f` 后 `git mv`。
   - 排查命令：`git status`（看是否在 Untracked 列表）、`git check-ignore -v <file>`（看是否命中忽略规则）。
2. **Windows 上 git mv 路径大小写**：Windows 文件系统大小写不敏感，但 git 大小写敏感；路径大小写不符也会报 `not under version control`。本任务路径均为小写且无特殊字符，不受影响；用 Tab 补全可避免此类问题。
3. **敏感配置文件迁移提醒**：env.json 含真实密钥/密码，迁移全程不得写入任何文档、不得提交（已由 .gitignore 保证）；`deploy/.gitkeep` 保持存在以维持 deploy 目录入库。

## 5. 相关任务资料（部署资产集中化背景，供下游任务参考）

以下内容不属于本任务范围（TASK-002 仅文件迁移），为 v0.2.5 整体「产物集中到 deploy」目标提供依据，供 TASK-003 及后续任务参考：

### 5.1 Spring Boot Maven 插件输出目录（官方：https://docs.spring.io/spring-boot/maven-plugin/packaging.html）

- `spring-boot-maven-plugin`（repackage goal）支持 `outputDirectory` 参数：Directory containing the generated archive；默认 `${project.build.directory}`（即 target）。
- 将最终 jar 输出到 deploy：在插件 `<configuration>` 中设置 `<outputDirectory>${project.basedir}/../../deploy/xxx</outputDirectory>` 之类自定义路径；或用 `<finalName>` 自定义 jar 名。
- 注意：`outputDirectory` 自插件 1.0.0 起支持；本项目 Spring Boot 3.2.5 对应插件版本（3.2.x）完全支持该参数。
- 与本任务的关系：本任务只把 env 配置文件放进 deploy；jar 输出重定向属「修改配置」系列任务（TASK-00x），中间产物（target）不进入 deploy 的原则与 G3 一致。

### 5.2 Maven JAR 插件输出目录（官方：https://maven.apache.org/plugins/maven-jar-plugin/jar-mojo.html）

- maven-jar-plugin 的 jar:jar goal 有输出目录参数，默认 `${project.build.directory}`；如需把普通 jar 直接输出到自定义目录可配置该参数（与 5.1 互斥关系：spring-boot repackage 在最终阶段，优先以 5.1 为准）。

## 6. 编码阶段实施建议汇总（供 code 步骤使用）

1. **目标位置**：`deploy/env.json`、`deploy/env.example.json`（deploy 目录已由 TASK-001 创建，无需新建；deploy/scripts 子目录已预建供 TASK-003 使用）。
2. **env.example.json**（已跟踪）：优先 `git mv env.example.json deploy/env.example.json`（保留历史）；若 `git ls-files env.example.json` 无记录则退回 `Move-Item`。
3. **env.json**（被忽略，未跟踪）：用 `Move-Item -Path env.json -Destination deploy\env.json`（可先 `-WhatIf` 演练）；**不可**用 git mv。
4. **迁移后校验**：
   - 根目录不存在 `env.json` / `env.example.json`（`Test-Path` 返回 False）；
   - deploy 下存在两文件，且 `Get-FileHash`（SHA256）与迁移前一致（内容无损）。
5. **红线**：不修改任何脚本、不修改 .gitignore、不迁移 scripts 目录内容（TASK-003 范围）；不将 env.json 真实密钥写入任何文档。

## 7. 查询信息源清单

| 资料 | 来源 | 类型 |
| --- | --- | --- |
| git-mv 官方手册 | https://git-scm.com/docs/git-mv | 官方文档 |
| gitignore 官方手册 | https://git-scm.com/docs/gitignore | 官方文档 |
| Move-Item 官方手册（PS 5.1/7.x） | https://learn.microsoft.com/powershell/module/microsoft.powershell.management/move-item | 官方文档 |
| Get-FileHash 官方手册（PS 5.1/7.x） | https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/get-filehash | 官方文档 |
| git mv not under version control 排错 | Stack Overflow、DevErrors、Latchkey Learn | 技术社区 |
| Spring Boot Maven 插件 outputDirectory | https://docs.spring.io/spring-boot/maven-plugin/packaging.html | 官方文档 |
| Maven JAR 插件输出目录 | https://maven.apache.org/plugins/maven-jar-plugin/jar-mojo.html | 官方文档 |
<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
