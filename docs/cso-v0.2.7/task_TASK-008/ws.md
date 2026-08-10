# ws.md（TASK-008 清理弃用脚本残留并同步引用关系 — 网络资料查询）

## 1. 查询范围与资料识别

本任务为「清理弃用脚本残留并同步引用关系」：`git rm` 删除 deploy/scripts 下 3 个弃用脚本（deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh），并同步全部脚本与文档引用关系。**不涉及第三方中间件/包/SDK 编码**，需要的网络资料为：

| 资料主题 | 来源 | 用途 |
| --- | --- | --- |
| git rm 删除已跟踪文件 | Git 官方文档（git-scm.com，htmldocs） | 删除弃用脚本的正确命令与选项 |
| gitignore 模式语法 | Git 官方文档（git-scm.com，htmldocs） | 已跟踪文件与 .gitignore 的交互规则（TASK-009 依据，本任务仅记录） |
| Conventional Commits 提交规范 | conventionalcommits.org 官方 v1.0.0 | 删除/文档修改提交信息格式（refactor:/docs:/chore:） |
| GitHub 弃用/迁移脚本最佳实践 | apache/superset、ipfs/kubo、pantsbuild/pants 等公开仓库实践 | 弃用→移除流程、引用同步、提交命名惯例 |

## 2. git rm 官方文档要点（删除已跟踪文件）

**来源**：Git 官方文档 https://git-scm.com/docs/git-rm（htmldocs 镜像，High 信誉）。**权威结论：删除已跟踪文件必须用 `git rm`（或删除后 `git add -u`），不能只删文件不提交。**

### 2.1 命令语法（官方 Synopsis）
```
git rm [-f | --force] [-n] [-r] [--cached] [--ignore-unmatch]
       [--quiet] [--pathspec-from-file=<file> [--pathspec-file-nul]]
       [--] [<pathspec>...]
```

### 2.2 关键选项与本任务用法
| 选项 | 官方说明 | 本任务适用性 |
| --- | --- | --- |
| （无选项）`git rm <file>` | 从索引与工作区同时删除文件 | **核心用法**：删除 deploy-env.ps1 / deploy-env-template.ps1 / deploy-env-template.sh 时直接使用 |
| `--cached` | 仅从索引移除，工作区文件保留 | **不适用**：本任务为彻底删除，非"取消跟踪保留文件" |
| `-f / --force` | 覆盖"文件必须与 HEAD 一致"的检查 | 备用：若文件被本地修改需强制删除时使用 |
| `-n / --dry-run` | 预览将被删除的文件，不实际删除 | **推荐先用**：删除前 `git rm -n deploy/scripts/deploy-env.ps1` 核对路径 |
| `-r` | 递归删除目录 | 不适用（本任务为单文件删除） |
| `--ignore-unmatch` | 无匹配路径时不报错 | 可用于批量脚本幂等删除；单文件删除不必须 |
| `--quiet` | 静默输出 | 可选 |

### 2.3 官方 FAQ：已跟踪文件与 .gitignore（gitfaq.adoc）
> If a file is already tracked by Git, adding it to `.gitignore` will not stop Git from tracking it. To ignore a previously tracked file, you must first remove it from the index using `git rm --cached <file>` and then add its pattern to `.gitignore`.

- 本任务删除的 3 个脚本均为已跟踪文件，`git rm` 后提交即可完整记录删除。
- 此规则同时是 TASK-009（.gitignore 治理）的重要依据：若历史上有已跟踪的临时文件需忽略，必须先 `git rm --cached`。

## 3. gitignore 官方语法要点（TASK-009 依据，本任务不修改）

**来源**：Git 官方文档 https://git-scm.com/docs/gitignore（htmldocs，High 信誉）。

| 语法 | 官方含义 |
| --- | --- |
| `#` 行 | 注释 |
| `!` 前缀 | 否定（重新包含）之前被排除的文件；**若父目录被排除则无法用 `!` 重新包含子文件** |
| 末尾 `/` | 仅匹配目录 |
| 开头 `/` | 锚定到 .gitignore 所在目录（不递归匹配） |
| 模式中含 `/` | 相对 .gitignore 所在目录匹配，**不含 `/` 的模式匹配任意层级** |
| `*` | 匹配除 `/` 外任意字符（`?` 匹配单个字符，`[...]` 字符类） |
| `**` | 特殊含义：`**/` 开头匹配所有目录；`/**` 结尾匹配目录内无限深度内容；`a/**/b` 匹配零个或多个中间目录 |

**结论**：`*.log`、`*.pid`、`target/`、`build/` 等无斜杠模式可匹配任意层级；TASK-009 补充 `*.hprof`、`surefire-reports/` 等规则时可直接沿用这些语法。

## 4. Conventional Commits 官方规范（v1.0.0）

**来源**：conventionalcommits.org 官方 v1.0.0（High 信誉，Benchmark 94）。

### 4.1 提交格式
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 4.2 类型定义（官方）
- **必须**：`feat`（新功能）、`fix`（缺陷修复）
- **可选**：`build`、`chore`、`ci`、`docs`、`style`、`refactor`、`perf`、`test`、`revert`
- 破坏性变更：类型后加 `!`（如 `refactor!:`）或使用 `BREAKING CHANGE:` footer

### 4.3 本任务提交建议（按 context.md 规范映射）
| 提交内容 | 建议 type | 示例 |
| --- | --- | --- |
| 删除弃用脚本 + 目录树同步 | `refactor:` 或 `chore:` | `chore: remove deprecated deploy-env scripts` |
| README/deployment-guide 引用更新 | `docs:` | `docs: update script references after removing deploy-env` |

## 5. GitHub 弃用/迁移脚本最佳实践（公开仓库实证）

### 5.1 弃用→移除流程（业界共识，多仓库一致）
1. **先标注弃用**（deprecation notice），**后移除**：pantsbuild/pants 明确"弃用至少持续一个 minor release 后才移除"（Deprecation policy）；external-secrets、ohdearquant/lionagi 同样要求 alias + 警告 + CHANGELOG 条目后再移除。
   - **本项目对照**：deploy-env-template.sh 自 v0.1.7 起头部标注「【已弃用】请改用 deploy 目录下的 env.json」；deploy-env.ps1 / deploy-env-template.ps1 文件头自称「已弃用」「兼容保留」。弃用标注已跨多个版本（v0.1.7 → v0.2.7），**符合"先弃用后移除"最佳实践**；且 ADR-016 决策明确"删除弃用脚本残留"，直接执行 `git rm` 合法。
2. **移除前检查引用**：TongWu/JAVDB_AutoSpider 迁移实践明确"若仍有导入/引用则不要删除，待重写引用后再删"。
   - **本项目对照**：cs.md 已 grep 实测——deploy/scripts 下除 3 个弃用脚本自身外无任何脚本引用 deploy-env*，删除不会造成加载路径失效；剩余引用为文档（deploy.md/README.md/deployment-guide.md 等）与历史测试，需同步更新。
3. **删除命令范式**（公开仓库实证）：
   - `git rm -r scripts/<name>` + `git commit -m "Remove ..."`（pantheon-systems/kube-gce-cleanup、hyhmrright/brooks-lint、KonstantinMB/exploreyc）
   - 单个文件：`git rm <file>` 后提交（Git 官方 t3600-rm.sh 测试亦验证 `git rm` 常规用法）
4. **提交信息惯例**：删除弃用内容的提交统一用 `chore: remove deprecated ...`（apache/superset 大量实证：`chore: remove deprecated apis`、`chore: remove deprecated config keys`；ipfs/kubo：`chore: remove deprecated providers pkg`、`chore: remove deprecated go-ipfs Docker image publishing`）。
5. **文档同步是移除的一部分**：删除后同步更新目录树、README、部署指南等引用（pantheon 迁移脚本中同步 `sed -i 's/scripts\/make/devops\/make/g' Makefile` 更新引用即为此类实践）。

### 5.2 对本任务的直接结论
- 删除命令：`git rm deploy/scripts/deploy-env.ps1 deploy/scripts/deploy-env-template.ps1 deploy/scripts/deploy-env-template.sh`（可先 `-n` 预览）。
- 提交信息：`chore: remove deprecated deploy-env scripts`（或 `refactor:`），文档引用更新并入同一提交或 `docs:` 提交。
- 引用同步必须覆盖：deploy/deploy.md 目录树（72-73 行）、README.md（229 行）、docs/cso-lld.md（771-772 行）、scripts/deployment-guide.md 与 docs/deployment-guide.md（1535 行，两份同内容副本须同步）、测试脚本断言（UT-134-1/134-2、UT-143-2 反转，UT-193-3 保留）。
- 历史存档不改：docs/prompts/prompt-*.md、docs/sad.md ADR-016、v0.2.5 归档测试脚本。

## 6. 版本兼容性核对结论

| 项目 | 版本 | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| 本机 git | 2.53.0.windows.1（实测） | Git 官方最新文档（2.4x-2.5x 时代） | **兼容**：git rm / gitignore / gitfaq 文档语法在本版本全部有效，无需降级或特判 |
| Conventional Commits | — | v1.0.0 官方规范 | **兼容**：规范无版本迭代问题，项目 context.md 已采用该规范 |
| 弃用脚本（deploy-env*） | v0.1.7 起标注弃用 | 业界弃用策略（pants 等） | **兼容**：弃用标注期已跨多个版本，满足"先弃用后移除"惯例，ADR-016 决策支撑 |

> 无第三方包/SDK 引入，不存在包版本冲突；本任务纯 git 操作 + 文档同步。

## 7. 编码阶段注意事项（供 code 阶段参考）

1. **删除前先 dry-run**：`git rm -n deploy/scripts/deploy-env.ps1` 确认路径无误，再执行正式删除。
2. **一次删除三个文件**：deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh 可单条命令一并 `git rm`。
3. **不用 `--cached`**：本任务为彻底删除（工作区文件也移除），不是"取消跟踪保留文件"。
4. **删除后提交前**：按 cs.md 引用清单逐项同步文档（deploy.md、README.md、docs/cso-lld.md、scripts/deployment-guide.md、docs/deployment-guide.md），并核对测试脚本断言（UT-134/UT-143 反转属预期变更，由测试阶段处理）。
5. **提交信息**遵循 Conventional Commits：脚本删除用 `chore:`/`refactor:`，文档同步用 `docs:`；文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明。
6. **gitignore 不越界**：.gitignore 治理属于 TASK-009，本任务仅按官方规则记录语法依据，不修改 .gitignore。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
