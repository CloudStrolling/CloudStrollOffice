# 网络资料查询报告（#TASK-010 全量脚本契约与双平台行为总体验证）

> 由 impm-task-coding-ws 技能执行（WS），查询时间 2026-08-10。查询范围：PowerShell 语法解析 Parser API、bash -n 语法校验、PSScriptAnalyzer / ShellCheck 静态分析、脚本退出码约定、Git .gitignore 官方语法、验证报告输出规范相关资料。

## 1. 查询结论速览

| 资料主题 | 官方来源 | 结论 | 版本兼容性 |
| --- | --- | --- | --- |
| PowerShell 语法解析 Parser API | Microsoft Learn（System.Management.Automation.Language.Parser） | `ParseFile` 静态方法可无执行校验 .ps1 语法，返回 AST + tokens + errors 数组 | **兼容**：PS 5.1（本机 win32 默认）与 PS 7.x 均内置该 API |
| bash -n 语法校验 | GNU Bash Reference Manual（devdocs/bash） | `bash -n script.sh` 只解析不执行，语法错误即非零退出；`set -n` 可在脚本内开启 | **兼容**：git-bash（bash 4.4+）/ WSL（bash 5.x）均支持，bash 2.0 起就有该选项 |
| 静态分析 PSScriptAnalyzer | PowerShell Gallery / GitHub powershell/psscriptanalyzer | `Invoke-ScriptAnalyzer` 返回 DiagnosticRecord（RuleName/Severity/Message/Line），支持 `-EnableExit` CI 退出码 | **兼容**：1.23.x 支持 Windows PowerShell 5.1 与 PS 7.x；PS 5.1 安装需先启用 TLS 1.2 |
| 静态分析 ShellCheck | GitHub koalaman/shellcheck（shellcheck.1.md / wiki） | `shellcheck file.sh` 四档严重级（error/warning/info/style），退出码 0/1/2/3/4 语义明确 | **兼容（可选项）**：Windows 需经 WSL、Docker 或独立二进制；无 shellcheck 时 `bash -n` 为最低要求 |
| PowerShell 退出码 | Microsoft Learn（about_Language_Keywords / about_Automatic_Variables） | `exit <code>` 设退出码；非零=失败；$LASTEXITCODE 读取；Windows 允许任意 int，Unix 仅 0~255 | **兼容**：PS 5.1 与 PS 7.x 一致 |
| Bash 退出状态 | GNU Bash Reference Manual（exit-status） | 0=成功，非零=失败；2=用法错误保留；126/127/128+signal 为系统保留语义 | **兼容**：所有 bash 版本一致 |
| .gitignore 语法 | git-scm.com/docs/gitignore（2.55.0） | 模式格式：`#` 注释、`!` 取反、`/` 分隔、`*`/`?`/`[]` 通配、`**` 递归；优先级：命令行 > 就近 .gitignore > info/exclude > core.excludesFile | **兼容**：git 2.42+（项目当前 git 版本）语法稳定 |

## 2. PowerShell 语法解析 Parser API（核心语法校验方法）

### 2.1 官方定义（Microsoft Learn，System.Management.Automation.Language.Parser）

`ParseFile(string fileName, out Token[] tokens, out ParseError[] errors)` 静态方法，从指定文件解析 PowerShell 脚本，**仅解析不执行**，是校验 .ps1 语法的最权威方式。

- 命名空间：System.Management.Automation.Language；程序集：System.Management.Automation.dll
- 包：Microsoft.PowerShell.5.1.ReferenceAssemblies v1.0.0（PS 5.1）/ System.Management.Automation v7.4.15+（PS 7.x）
- 返回：ScriptBlockAst；tokens 与 errors 通过引用传出；**errors 数组非空即存在语法错误**

### 2.2 官方示例（microsoftdocs/powershell-docs，about_Foreach.md）

```powershell
$parser = [System.Management.Automation.Language.Parser]
$tokens = $errors = $null
$ast = $parser::ParseFile($item.FullName, ([ref]$tokens), ([ref]$errors))
if ($errors) {
  $msg = "File '{0}' has {1} parser errors." -f $item.FullName, $errors.Count
  Write-Warning $msg
}
```

### 2.3 应用到 TASK-010 的推荐用法

```powershell
# 批量校验 deploy/scripts/*.ps1 语法（Windows PowerShell 5.1 可直接运行）
$ErrorCount = 0
Get-ChildItem -Path "$PSScriptRoot\..\..\deploy\scripts" -Filter *.ps1 | ForEach-Object {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        $ErrorCount++
        Write-Host "[失败] $($_.Name)：$($errors.Count) 个语法错误"
        $errors | ForEach-Object { Write-Host "    第 $($_.Extent.StartLineNumber) 行：$($_.Message)" }
    } else {
        Write-Host "[通过] $($_.Name) 语法校验"
    }
}
exit $ErrorCount   # 语法失败数作为退出码（失败非零，符合 F-011 约定）
```

**注意事项**：
- 必须传 `[ref]$tokens` 与 `[ref]$errors`，且先置 `$null`；
- 校验不加载执行脚本，不触发 env.json 读取与副作用，适合总体验证阶段；
- PS 5.1 与 PS 7.x API 签名一致，可在双环境复用同一校验逻辑。

## 3. bash -n 语法校验（GNU Bash 官方）

### 3.1 官方定义（GNU Bash Reference Manual / devdocs.io/bash）

bash 命令行语法：`bash [long-opt] [-ir] [-abefhkmnptuvxdBCDHP] [-o option] [-O shopt_option] [argument ...]`

- `-n`（长选项 `--noexec`）：**读取命令但不执行**，用于检查脚本语法错误；脚本可执行但无副作用的命令（如 `cd`、`export` 等）不产生实际效果；
- `set -n` 可在脚本内部开启同一行为；
- 语法有错误时 bash 向 stderr 输出错误并返回非零退出码；语法正确返回 0。

### 3.2 应用到 TASK-010 的推荐用法

```bash
# 批量校验 deploy/scripts/*.sh 语法（git-bash / WSL / Linux 均可）
#!/bin/bash
set -u
total=0; fail=0
for f in "$(cd "$(dirname "$0")/.." && pwd)"/scripts/*.sh; do
    total=$((total + 1))
    if bash -n "$f" 2>/dev/null; then
        echo "[通过] $(basename "$f") 语法校验"
    else
        fail=$((fail + 1))
        echo "[失败] $(basename "$f")：$(bash -n "$f" 2>&1 | head -1)"
    fi
done
echo "汇总行：通过 $((total - fail)) 项 | 警告 0 项 | 失败 $fail 项"
exit $((fail > 0 ? 1 : 0))
```

**注意事项**：
- `bash -n` 仅做语法检查，**不检查变量未定义、命令不存在等运行时问题**——契约自校验需配合 grep/静态核对完成；
- Windows 无原生 bash 时，验证环境必须记录：git-bash（bash 4.4+/5.x）或 WSL（bash 5.x）均可；二者语法兼容，不影响 -n 结果；
- 若本机无 bash，可降级为静态核对（括号配对、引号闭合、`fi`/`done`/`esac` 匹配），但验证报告须注明校验环境（context.md 第 7.1 节已要求记录）。

## 4. 静态分析工具（增强验证，可选项）

### 4.1 PSScriptAnalyzer（PowerShell 官方静态检查器）

- 安装：`Install-Module -Name PSScriptAnalyzer`（PowerShell Gallery；**Windows PowerShell 5.1 需先 `Set-PSRepository PSGallery -InstallationPolicy Trusted` 并启用 TLS 1.2：`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`**）；
- 调用：`Invoke-ScriptAnalyzer -Path .\script.ps1 [-Recurse] [-Severity Error, Warning] [-ExcludeRule ...] [-Settings ...] [-EnableExit] [-ReportSummary]`
- 返回 DiagnosticRecord 对象：RuleName / Severity / Message / ScriptName / Line；
- `-EnableExit`：以「错误数」作为进程退出码，适合 CI 集成；
- 内置规则示例：PSAvoidUsingWriteHost、PSAvoidUsingCmdletAliases、PSUseDeclaredVarsMoreThanAssignments 等。

**TASK-010 应用建议**：语法校验（Parser API）为必做项；PSScriptAnalyzer 作为增强项，若环境未安装则以 Parser API 结果为准并在验证报告注明。

### 4.2 ShellCheck（bash 官方社区标准静态检查器）

- 调用：`shellcheck [OPTIONS]... FILES...`；`-S severity` 设置最低严重级（error/warning/info/style）；
- 退出码（shellcheck.1.md 权威）：0=扫描成功无问题；1=扫描成功发现问题；2=部分文件无法处理；3=语法错误；4=选项错误；
- Windows 环境：经 WSL、Docker（`docker run --rm -v "$(cygpath -aw .):/mnt" koalaman/shellcheck:stable`）或独立二进制运行。

**TASK-010 应用建议**：ShellCheck 非必需（`bash -n` 为最低要求）；若环境可用则附加执行，输出中单列"静态分析（可选）"小节。

## 5. 退出码约定官方依据（契约验证基准）

### 5.1 PowerShell（Microsoft Learn about_Language_Keywords / about_Scripts）

- `exit <exitcode>` 终止脚本并设置退出码；默认 0；非零通常表示失败；
- 宿主侧读取：PowerShell 内 `$LASTEXITCODE`，cmd 内 `%ERRORLEVEL%`；
- 平台差异：Windows 允许任意 int；**Unix 仅允许 0~255 正整数**（负值自动转换）——本项目脚本主要部署于 Linux，退出码取值应保持在 0~255 内；
- `pwsh -File script.ps1`：异常=1，`exit` 值=指定值，成功=0。

### 5.2 Bash（GNU Bash Reference Manual exit-status）

- 0=成功；非零=失败（可多种失败模式）；
- 2=命令用法错误（保留）；
- 126=找到但不可执行；127=未找到命令；128+信号号=被信号终止；
- `$?` 记录最后一条命令退出状态。

### 5.3 与项目契约（F-011 / R-02 / R-03 / LLD 6.7）对照结论

| 项目契约 | 官方依据 | 一致性 |
| --- | --- | --- |
| 全部通过退出 0 | bash 0=成功 / PS exit 默认 0 | 一致 |
| 存在失败项退出非零（1） | bash 非零=失败 / PS 非零=失败 | 一致 |
| 警告但无失败按约定退出 0 | 自定契约（官方允许 0 表示"任务完成但有告警"） | 符合，验证时按项目契约核对 |
| 退出码取值范围 | 双平台均允许 0~255；PS 额外允许大整数 | 项目只用 0/1，双平台安全 |

## 6. .gitignore 官方语法（验收标准 8 核对依据）

来源：git-scm.com/docs/gitignore（最新 2.55.0，语法自 git 2.42 起稳定，与项目版本兼容）。

### 6.1 模式格式要点（验证 .gitignore 时按此逐条核对）

1. 空行不匹配任何文件（作分隔）；
2. `#` 开头为注释（需匹配字面 `#` 时用 `\#`）；
3. 行尾空格默认忽略（需保留时 `\ ` 转义）；
4. `!` 前缀取反（重新包含）；**若父目录被排除则无法重新包含子文件**（重要边界：`logs/` 排除后 `!logs/.gitkeep` 无效）；
5. `/` 为目录分隔符：**开头或中间有 `/` 则相对 .gitignore 所在目录匹配；末尾 `/` 仅匹配目录**；无 `/` 的模式匹配任意层级；
6. `*` 不匹配 `/`；`?` 匹配任意单字符（不含 `/`）；`[a-zA-Z]` 字符范围；
7. `**`：`**/foo` 任意层级、`abc/**` 目录内全部、`a/**/b` 零或多级目录；
8. 已跟踪文件不受 .gitignore 影响——需 `git rm --cached` 停止跟踪后再生效（验收标准 8 若发现旧跟踪文件需用此命令）；
9. 优先级：命令行 > 就近目录 .gitignore（更深的目录覆盖更浅的）> $GIT_COMMON_DIR/info/exclude > core.excludesFile。

### 6.2 验证命令（官方配套工具）

- `git status --porcelain`：核对工作区无过程文件（验收标准 8 核心）；
- `git check-ignore -v <path>`：逐条确认某文件被哪条规则忽略（防误伤排查）；
- `git ls-files`：确认 env.example.json、.gitkeep、pom.xml、bootstrap.yml 等应入库文件仍在跟踪中。

### 6.3 TASK-010 核对要点（对应 cs.md §6 / P9）

- 保护性规则核对：`!env.example.json`、`.gitkeep` 保留规则必须存在且不被父目录规则吞没；
- `logs/`、`*.log`、`*.err`、`*.pid` 等部署日志/进程文件排除规则应覆盖 deploy/logs；
- `*.hprof`、`hs_err_pid*.log`、`replay_pid*`、`heapdump.*`、`*.dmp`、surefire-reports/、test-output/ 等 JVM 调试与测试产物规则齐全；
- 验证方法：`git status --porcelain` 后 grep 过程文件模式，0 命中为通过（对应 cs.md §9 P9）。

## 7. 验证报告输出规范（汇总建议）

任务要求的"验证报告输出"无行业强制标准，结合项目契约（F-011 输出分级）与官方工具退出码语义，建议按以下规范输出（供 writetest/runtest 阶段参考）：

### 7.1 报告结构（建议 Markdown，落盘 docs/cso-v0.2.7/task_TASK-010/ 下）

1. **报告头**：任务编号、校验环境（OS、PowerShell 版本、bash 版本、git 版本、shellcheck 可用性）、校验时间；
2. **总览表**：12 对脚本 × 校验项（语法 .ps1 / 语法 .sh / 输出分级 / 退出码 / load-env 依赖 / 硬编码 / SPDX 头 / 密钥契约），逐项 通过/警告/失败；
3. **分项详表**：每项列出证据（行号、命中内容），失败项给出处理建议；
4. **PRD 第 7 章 8 条验收标准逐条核对表**：标准原文 → 核对结果 → 证据；
5. **退出码与汇总行**：整体汇总行「通过 N 项 | 警告 M 项 | 失败 K 项」；报告校验工具本身退出码：全部通过 0 / 存在失败 1（与 F-011 一致）；
6. **遗留问题清单**：cs.md §9 潜在问题 P1~P9 的最终判定。

### 7.2 输出分级与颜色（复用脚本契约 F-011）

- `[通过]`（绿）/ `[警告]`（黄）/ `[失败]`（红，含处理建议）；非交互终端自动降级纯文本；
- 汇总行必须存在；失败项必须伴随退出非零。

## 8. 版本兼容性核对结论（汇总）

| 校验项 | 资料版本 | 项目环境 | 兼容性结论 |
| --- | --- | --- | --- |
| Parser.ParseFile | Microsoft.PowerShell.5.1.ReferenceAssemblies v1.0.0 / System.Management.Automation 7.x | Windows PowerShell 5.1（win32 本机）+ 可选 PS 7.x | **兼容**：PS 5.1 内置，无需安装任何包 |
| bash -n | GNU Bash 5.2（手册）；git-bash 4.4+/WSL 5.x 实测支持 | deploy/*.sh 目标为 Linux bash；验证机 Windows | **兼容**：需记录验证环境（git-bash/WSL） |
| PSScriptAnalyzer | 1.23.x（支持 PS 5.1/7.x） | PS 5.1 | **兼容**：可选安装，PS 5.1 需 TLS 1.2 预置 |
| ShellCheck | 最新 stable（0.10.x） | Windows 经 WSL/Docker | **兼容（可选项）**：非必需 |
| gitignore 语法 | git 2.55.0 文档 | 项目 git 2.42+ | **兼容**：语法稳定无破坏性变更 |
| 退出码约定 | PS 5.1 官方文档 / GNU bash 5.2 | 脚本契约 0/1 | **兼容**：项目取值在双平台安全域内 |

## 9. 数据来源（官方/权威）

1. Microsoft Learn — Parser.ParseFile 方法：https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.language.parser.parsefile
2. microsoftdocs/powershell-docs — about_Foreach.md（ParseFile 示例）：https://github.com/microsoftdocs/powershell-docs/blob/main/reference/5.1/Microsoft.PowerShell.Core/About/about_Foreach.md
3. microsoftdocs/powershell-docs — about_Language_Keywords.md（exit 语法）/ about_Automatic_Variables.md（$LASTEXITCODE）：https://github.com/microsoftdocs/powershell-docs/blob/main/reference/7.7/Microsoft.PowerShell.Core/About/
4. GNU Bash Reference Manual（devdocs 镜像，bash 5.2）：https://devdocs.io/bash/invoking-bash 、https://devdocs.io/bash/exit-status 、https://devdocs.io/bash/the-set-builtin
5. PowerShell Gallery / GitHub — PSScriptAnalyzer：https://github.com/powershell/psscriptanalyzer
6. GitHub — ShellCheck：https://github.com/koalaman/shellcheck（shellcheck.1.md、wiki/Integration、wiki/Contrib）
7. Git 官方文档 — gitignore：https://git-scm.com/docs/gitignore

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
