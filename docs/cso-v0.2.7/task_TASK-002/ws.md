# 网络资料查询结果（TASK-002 实现 load-env.ps1 / load-env.sh 统一配置加载模块）

## 0. 查询结论摘要

本任务为 v0.2.7 部署脚本重构的 **F-001（env.json 配置加载统一）落地任务**，不引入任何新增第三方包；全部依赖系统内置工具与标准库（Windows PowerShell 5.1 内置 cmdlet、Linux 的 jq / python3、Bash 内建命令）。经查询 Microsoft Learn（PowerShell 官方文档）、jqlang 官方 jq Wiki、SPDX 官方规范、Python 官方文档 shlex 模块及 Bash source 语义权威资料，并结合本机环境实测（PowerShell 5.1.19041.7548；jq/python3/python 本机均未安装，bash 经 WSL 可用），确认：

- **PowerShell 侧**：`ConvertFrom-Json`、`Set-Item Env:`、`[System.Management.Automation.Language.Parser]::ParseFile` 在 Windows PowerShell 5.1 全部可用，现有 load-env.ps1 的解析/注入机制无需改动；
- **Bash 侧**：jq 的 `to_entries | .[] | "export \(.key)=\(.value | @sh)"` + `eval` 是官方 Wiki 认可的标准「JSON → 环境变量」方案；python3 `json.load` + `shlex.quote` 是官方文档支持的回退方案；
- **source 语义**：load-env.sh 以 `source` 方式被调用，**必须用 `return` 而非 `exit`**（否则会终止父 shell），且不得引入 `set -e`（污染父 shell 状态，UT-142-2 已确认）；
- **SPDX 规范**：文件头一行 `SPDX-License-Identifier: Apache-2.0` + 版权声明，按语言注释风格书写（.ps1 用 `#`/`<# #>`、.sh 用 `#`），本项目约定保留 `Copyright 2026 jenemy8023 <jenemy8023@163.com>`。

---

## 1. 需要的三方组件与工具清单

本任务不需要新增/下载任何三方包。运行依赖如下（全部为操作系统自带或常见发行版预装）：

| 工具/组件 | 用途 | 使用场景 | 版本要求 |
| --- | --- | --- | --- |
| PowerShell `ConvertFrom-Json` | 将 env.json 解析为 PSCustomObject | load-env.ps1（Windows） | PowerShell 3.0+（本机 5.1 兼容） |
| PowerShell `Set-Item -Path Env:...` | 将键值对注入会话环境变量 | load-env.ps1（Windows） | 全版本可用 |
| PowerShell `[System.Management.Automation.Language.Parser]::ParseFile` | 脚本语法校验（不做执行） | 测试（UT-142 契约） | PowerShell 3.0+（5.1 可用） |
| jq（`to_entries` / `@sh`） | Bash 下解析 env.json 并生成 shell 安全 export 语句 | load-env.sh 首选方案（Linux/WSL） | jq 1.5+（`@sh` 1.5 起；to_entries 1.5 起；推荐 1.6+） |
| python3（`json` + `shlex`） | jq 不可用时的回退解析方案 | load-env.sh 回退（Linux/WSL） | Python 3.x（json/shlex 均为标准库） |
| Bash `source` / `return` | source 型脚本的调用与失败返回语义 | load-env.sh（Linux/WSL） | Bash 3.2+（`${!var:-}` 存在性检查兼容） |
| `bash -n` | .sh 脚本语法校验 | 测试（UT-142 契约） | bash 自带 |

> **本机实测（2026-08-10）**：`$PSVersionTable.PSVersion` = **5.1.19041.7548**；`jq`/`python3`/`python` 命令在本机 Windows 均不可用（CommandNotFoundException）；`bash` 经 WSL2 可用。→ Windows 部署走 `load-env.ps1`，Linux/WSL 部署走 `load-env.sh`，双平台脚本各自闭环，符合 SAD 1.2 约束。

---

## 2. 官方文档与使用方法

### 2.1 PowerShell ConvertFrom-Json（Microsoft Learn 官方）

- **文档地址**：https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.utility/convertfrom-json
- **核心用法**：将 JSON 格式字符串转换为 PSCustomObject，配合 `Get-Content -Raw` 读取文件：
  ```powershell
  $json = Get-Content -Raw -Encoding UTF8 $EnvFilePath | ConvertFrom-Json
  ```
- **注意事项**（官方 NOTES）：
  - 默认 PSCustomObject 保持 JSON 中属性的声明顺序（对加载顺序无关紧要，但遍历注入顺序稳定）；
  - `-AsHashtable` 参数为 PowerShell 7.3+ 新增，**5.1 不可用**，本任务现有代码用 `PSObject.Properties` 遍历，不依赖该参数，兼容；
  - JSON 解析失败（非法 JSON）会抛终止错误，现有脚本已有 try/catch 分支处理，保留即可。
- **注入环境变量（官方 about_Environment_Variables / about_Environment_Provider / Set-Item）**：
  ```powershell
  Set-Item -Path Env:UserRole -Value "Administrator"   # 单个注入
  $json.PSObject.Properties | ForEach-Object { Set-Item -Path "env:$($_.Name)" -Value $_.Value }
  ```
  - `Set-Item -Path Env:...` 在 PowerShell 5.1 完全可用；
  - 值为字符串时直接注入；env.json 全部键值均为字符串类型（含 `"300"`、`"true"` 等），与 Spring 配置绑定兼容；
  - 官方文档注明「PowerShell 7.5 起可设置空字符串，设置 $null 会移除变量」——5.1 行为不同，本任务不依赖该特性（REDIS_PASSWORD 为空字符串时注入空值即可，勿注入 $null）。

### 2.2 jq to_entries + @sh（jqlang 官方 jq Wiki）

- **文档地址**：https://github.com/jqlang/jq/wiki/Cookbook 、https://github.com/jqlang/jq/wiki/FAQ
- **官方推荐模式（FAQ：How to extract parts of JSON into shell variables?）**：
  ```bash
  eval "$(jq -r '@sh "a=\(.a) b=\(.b)"' sample.json)"
  ```
- **本任务模式（Cookbook / 社区验证，与现有 load-env.sh 一致）**：
  ```bash
  eval "$(jq -r 'to_entries | .[] | "export \(.key)=\(.value | @sh)"' "$ENV_FILE_PATH")"
  ```
  - `to_entries` 将对象转换为 `[{key, value}, ...]` 数组；
  - `@sh` 格式说明符对字符串做 shell 安全引用（POSIX sh 兼容），正确处理空白、单引号、`$`、反引号等特殊字符；
  - 注意事项：使用 `eval` 存在理论风险，但 jq `@sh` 已对所有输入转义，安全边界可控（官方与社区公认做法）；**不要改用 `for row in $(jq ...)` 循环**——会按空白分词破坏含空格值（如 DB_SERVICE_NAME=`MySQL, MariaDB` 含空格、RSA 密钥 Base64 含 `+/=` 等）；
  - 版本：`to_entries` 与 `@sh` 均为 jq 1.5+ 可用，推荐 1.6+。

### 2.3 python3 json + shlex.quote 回退（Python 官方文档）

- **文档地址**：https://docs.python.org/3/library/shlex.html 、https://docs.python.org/3/library/json.html
- **核心用法**（现有 load-env.sh 已实现，官方验证正确）：
  ```python
  import json, shlex, sys
  data = json.load(open(sys.argv[1], encoding="utf-8"))
  for k, v in data.items():
      print(f"export {k}={shlex.quote(str(v))}")
  ```
  - `shlex.quote()` 生成与 UNIX shell（bash/dash/sh）兼容的安全引用，正确处理含空格、引号、特殊字符的值；
  - json/shlex 均为 Python 标准库，Python 3.x 全部版本可用；
  - 与 jq 路径行为一致：逐个键值对输出 `export KEY=VALUE` 行，由外层 `eval` 执行注入。

### 2.4 Bash source 语义（权威资料：Bash Coding Standard / Baeldung / Linuxize）

- **核心结论（Bash Coding Standard 10.1 source-semantics）**：
  - `return`（在被 source 文件的顶层）终止 source 并把控制权交还调用者，**调用者 shell 继续运行**；
  - `exit` 直接终止调用者 shell（无论 source 嵌套多深）；
- **Baeldung（return vs exit）**：source 脚本里使用 `return` 是合法且推荐的；直接执行时顶层 `return` 会报 `return: can only 'return' from a function or sourced script`；
- **Linuxize（bash source Command）**：
  - `source` 与 `.` 等价，`source script.sh` 在当前 shell 中执行，变量/函数在 source 结束后保留；
  - 被 source 的辅助脚本中若包含 `exit` 会终止当前 shell 或脚本，应使用 `return`；
  - 被 source 的文件继承调用者的 shell 选项，**不得引入 `set -euo pipefail` 之类影响父 shell 的选项**（UT-142-2 已确认 load-env.sh 故意省略 `set -e`）；
- **检测是否被 source（可选增强，社区方案）**：
  ```bash
  (return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
  ```
  > 本任务维持现有契约：load-env.sh 固定以 `source` 方式被调用，失败用 `return 1`（F-001 契约 + cs.md 4.3），无需引入 sourced 检测。

### 2.5 PowerShell Parser.ParseFile 语法校验（Microsoft Learn 官方）

- **文档地址**：PowerShell about_Foreach 官方示例（reference/7.7 与 reference/5.1 均收录）
- **核心用法（不做执行、仅解析，UT-142 契约）**：
  ```powershell
  $parser = [System.Management.Automation.Language.Parser]
  $tokens = $errors = $null
  $ast = $parser::ParseFile($item.FullName, ([ref]$tokens), ([ref]$errors))
  if ($errors) { Write-Warning "File '{0}' has {1} parser errors." -f $item.FullName, $errors.Count }
  ```
  - `ParseFile` 返回 AST，tokens 与 errors 通过引用返回；errors 为空表示语法通过；
  - PowerShell 3.0+ 可用（**5.1 已验证兼容**），是替代旧式 `[System.Management.Automation.PSParser]::Tokenize` 的现代 API；
  - `bash -n script.sh` 为 Bash 语法校验：无错误时无输出、退出码 0。

### 2.6 SPDX-License-Identifier 版权头规范（spdx.org / linuxfoundation.org / apache.org 官方）

- **官方规范**：https://spdx.dev/learn/handling-license-info/ 、https://spdx.org/licenses/ 、https://www.apache.org/licenses/LICENSE-2.0
- **格式**（一行，按语言注释风格）：
  ```
  # SPDX-License-Identifier: Apache-2.0
  ```
  由三部分组成：注释开始字符 + `SPDX-License-Identifier:`（冒号后空白）+ SPDX 许可证 ID（如 `Apache-2.0`）。
- **Apache 官方推荐**：文件头包含版权声明与许可证声明，使用文件格式对应的注释语法，并建议同页注明文件/类名与用途。
- **本项目约定（project.md / cs.md 复用基线）**：
  - .ps1 文件头：`# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`（或 `<# #>` 块注释）；
  - .sh 文件头：`# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`；
  - 注释与文档使用简体中文。

---

## 3. 版本兼容性核对

| 依赖 | 本项目运行环境（实测） | 资料最低版本 | 兼容性结论 |
| --- | --- | --- | --- |
| PowerShell | 5.1.19041.7548 | ConvertFrom-Json 3.0+ / Set-Item Env: 全版本 / Parser.ParseFile 3.0+ | ✅ 兼容（勿用 7.3+ 的 `-AsHashtable` 与 7.5+ 空字符串特性） |
| jq | 本机未安装（Linux/WSL 部署时需 `apt install jq` 或已有） | 1.5+（to_entries/@sh） | ✅ 兼容（推荐 1.6+） |
| python3 | 本机未安装（Linux/WSL 部署时回退） | 3.x（json/shlex 标准库） | ✅ 兼容 |
| bash | WSL2 可用 | 3.2+（`${!var:-}`、`[[ ]]`） | ✅ 兼容 |
| env.json 值类型 | 全部字符串（含 `"true"`/`"300"`/`""`） | — | ✅ PowerShell/Bash 均按字符串注入，与 Spring 配置绑定兼容 |

**关键兼容提示（供 code 步骤）**：
1. **PowerShell 5.1**：`ConvertFrom-Json` 无 `-AsHashtable`；遍历注入必须用 `PSObject.Properties`（现有代码正确）；`Set-Item "env:$($_.Name)"` 键名含字母/下划线可正常工作；
2. **jq 版本**：勿使用 `@tsv` 等 1.6+ 才完善的组合，`to_entries + @sh` 在 1.5+ 稳定；
3. **Bash 存在性检查**：用 `${!var:-}`（间接参数展开）遍历缺失项集合，Bash 3.2+ 支持；需逐个列出缺失项时可用数组累积；
4. **source 语义**：load-env.sh 顶层失败必须 `return 1`（不能 `exit 1`，否则调用方 shell 被终止）；load-env.ps1 维持 `exit 1`（dot-source 语义下 exit 退出当前脚本会话，F-001 契约原文要求「退出非零」）。

---

## 4. 相关任务资料（排错经验与业务要点）

### 4.1 敏感值处理（口令/密钥不打印）
- env.json 含 DB_PASSWORD、MARIADB_ROOT_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等敏感值（cs.md 2.3）；
- 加载过程与缺失校验输出**不得打印敏感值明文**：缺失项只输出**键名**（如 `缺失关键配置: DB_PASSWORD`），不输出值；
- 成功摘要建议只输出「已加载 N 个环境变量」或非敏感键名列表；
- RSA 密钥为 DER 单行 Base64，含 `+`、`/`、`=` 字符：jq `@sh` 与 python `shlex.quote` 均能正确转义，直接注入字符串即可（不破坏 ADR-015 契约）。

### 4.2 值含特殊字符/空格的场景（常见坑）
- `DB_SERVICE_NAME = "MySQL, MariaDB"`（含逗号与空格）、`DB_PROCESS_NAME = "mysqld, mariadbd"`；
- `NACOS_HOME` 在 Windows 为 `D:\jenemy\develop\nacos`（反斜杠路径）→ 仅由 .ps1 使用；Linux 侧 env.example.json 示例为 `/opt/nacos`；
- **禁止** `for row in $(jq ...)` 分词循环加载（会按 IFS 拆分含空格值）；必须用 `@sh`/`shlex.quote` 整体转义；
- PowerShell 侧 `Set-Item Env:` 值含任意字符均安全（不经过 shell 解析）。

### 4.3 退出码与行为一致性（SAD 1.2 / F-001 三场景）
- 三场景行为：env.json 存在→加载全部键值对（成功 0）；env.json 缺失→提示复制 env.example.json 并退出非零；关键配置缺失→逐个列出缺失项并退出非零；
- 关键配置下限 8 项（PRD F-001 原文）：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT；
- 建议策略（cs.md 4.2）：「必填 8 项 + 可选键存在即校验」——DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 等键若在 env.json 中存在则校验非空，但**不得扩大为全部 25 键必填**（会与 env.example.json 占位符冲突）。

### 4.4 语法校验基线（UT-078 / UT-142，不得破坏）
- UT-078-1：load-env.sh 必须包含 `${BASH_SOURCE[0]}`、`PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`、`ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"`；
- UT-078-2：load-env.ps1 必须包含 `$PSScriptRoot`、`$ProjectDir = Split-Path -Parent $PSScriptRoot`、`Join-Path $ProjectDir $EnvFile`；
- UT-142-2：load-env.sh 属 source 型脚本，**故意省略 `set -e`**；
- 校验命令：`.ps1` 用 `[System.Management.Automation.Language.Parser]::ParseFile`；`.sh` 用 `bash -n`（不可用时降级 shebang + 非空校验）。

---

## 5. 编码建议汇总（供 code 步骤直接引用）

1. **load-env.ps1（基于现有 35 行增量修改）**：
   - 文件头新增：`# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>` + 简体中文用途注释；
   - 保留：`param([string]$EnvFile = "env.json")`、`Split-Path -Parent $PSScriptRoot`、`Join-Path`、`ConvertFrom-Json` + `PSObject.Properties` + `Set-Item "env:..."`、try/catch（UT-078-2 锁定）；
   - env.json 缺失分支：提示文案补充「请复制 deploy/env.example.json 为 env.json 并填写配置」，`exit 1`；
   - 新增关键配置校验：8 项必填数组，缺失项用 `$env:KEY` 检查并收集，逐个列出键名后 `exit 1`；
   - 敏感值：注释明示「口令/密钥不打印」，输出仅键名/计数。
2. **load-env.sh（基于现有 39 行增量修改）**：
   - 文件头新增 `# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`；
   - 保留：`BASH_SOURCE[0]` 路径推导、`ENV_FILE_PATH`、jq 优先/python3 回退、`eval` + `@sh`/`shlex.quote`、成功提示（UT-078-1 锁定）；
   - 缺失分支：补充 env.example.json 指引文案，`return 1`（**不能 `exit`**）；
   - 新增关键配置校验：8 项必填数组，用 `${!var:-}` 或数组循环检查，缺失项逐个列出后 `return 1`；
   - 不引入 `set -e`；结尾输出「已加载 N 个环境变量」摘要，不打印敏感值。
3. **双平台一致性**：三场景退出码一致（0 / 非零 / 非零）；提示文案中文一致；SPDX 头一致。

---

## 6. 参考资料清单

| 资料 | 类型 | 地址 |
| --- | --- | --- |
| ConvertFrom-Json 官方文档 | 官方 | https://learn.microsoft.com/zh-cn/powershell/module/microsoft.powershell.utility/convertfrom-json |
| PowerShell about_Environment_Variables | 官方 | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables |
| Set-Item 官方文档（Env: 示例） | 官方 | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-item |
| Parser.ParseFile 官方示例 | 官方 | PowerShell reference/5.1、7.7 Microsoft.PowerShell.Core/About/about_Foreach |
| jq Cookbook（@sh） | 官方 Wiki | https://github.com/jqlang/jq/wiki/Cookbook |
| jq FAQ（to_entries / @sh / JSON→shell 变量） | 官方 Wiki | https://github.com/jqlang/jq/wiki/FAQ |
| Python shlex 官方文档 | 官方 | https://docs.python.org/3/library/shlex.html |
| Bash Coding Standard（source 语义） | 社区标准 | https://github.com/Open-Technology-Foundation/bash-coding-standard |
| Baeldung：return vs exit | 技术社区 | https://www.baeldung.com/linux/return-vs-exit |
| Linuxize：bash source Command | 技术社区 | https://linuxize.com/post/bash-source-command |
| SPDX Handling License Info | 官方 | https://spdx.dev/learn/handling-license-info/ |
| Apache-2.0 官方许可证与样板声明 | 官方 | https://www.apache.org/licenses/LICENSE-2.0 |
| Stack Overflow：Exporting JSON to environment variables | 技术社区 | https://stackoverflow.com/questions/48512914/exporting-json-to-environment-variables |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
