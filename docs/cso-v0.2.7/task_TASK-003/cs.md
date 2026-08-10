# 代码查询结果（TASK-003 重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测）

## 0. 查询结论摘要

本任务为 v0.2.7 部署脚本重构的 **F-002~F-006（JDK/MariaDB/Redis/Nacos 可用性检查 + 运行状态检测）与 F-010/F-011（前置检查整合与输出/退出码规范）落地任务**。经实际读取 `deploy/scripts/deploy-check-env.ps1`（160 行）、`deploy-check-env.sh`（150 行）完整源码、TASK-002 已交付的 `load-env.ps1`（75 行）/`load-env.sh`（84 行）调用契约、`deploy/env.json`（27 键）与 `env.example.json` 全量键值、TASK-001 issue-list（P1/P4/P5/P7 定位）及 PRD F-002~F-006/F-010/F-011 详细规则，确认：

- **现有 deploy-check-env 双版本脚本整体不可复用，应重构而非增量修改**：硬编码默认地址（P1）、Nacos 重复 HTTP 探测与检查能力分散（P4）、无警告分级与输出/退出码不统一（P5）、混入 Maven/Git/SQL 等无关检查项、.sh 用 `eval` 拼接命令（注入/口令泄露风险）、.ps1 有孤立死代码（P7-05/06）、双平台检查项数量不一致（.ps1 10 项 vs .sh 13 项）；
- **必须复用的基线**：TASK-002 已交付的 `load-env.ps1` / `load-env.sh`（F-001 契约：env.json 缺失/关键配置缺失提示并退出非零、不硬编码地址凭据、口令不打印明文）；TASK-002 交付后 `deploy/env.json` 已含全部关键配置（NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*/DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME 等 27 键）；
- **可参考的现成模式**：`deploy-start-services.ps1/.sh` 中已有的「命令/服务/进程三重安装检测」函数（`Test-Installed` / `has_cmd` / `has_svc` / `has_proc`）与「通过/警告/失败」三级输出模式（`Write-Result` / `print_result`），可直接改造复用于 check-env；
- **验收红线（F-011/acceptanceCriteria）**：无硬编码默认地址（grep 192.168.1.1xx 不命中 check-env）；Nacos 已安装未启动计"警告（未运行）"；口令不打印明文（`****` 掩码）；输出「通过/警告/失败」三级汇总；退出码全部通过 0 / 存在失败非零（1）；.ps1/.sh 行为一致且可独立语法校验。

---

## 1. 查询范围与文件清单

### 1.1 本任务直接改造的目标文件（重构对象）

| 文件 | 定位/作用 | 现状（v0.2.7 基线） |
| --- | --- | --- |
| `deploy/scripts/deploy-check-env.ps1` | Windows 部署前置检查脚本 | 160 行；10 项 Check；硬编码 param 默认地址；无警告分级；L35 孤立死代码（P7-05）；L89-90 明文连接串+无效 DbProviderFactory（P7-06）；无 SPDX 头（P7-14） |
| `deploy/scripts/deploy-check-env.sh` | Linux 部署前置检查脚本 | 150 行；13 项 Check；硬编码默认地址；`eval` 拼接命令（P5/P7-10）；版本 v0.1.7（P7-13）；无 SPDX 头（P7-14） |

> 两者均被 git 跟踪（`git ls-files` 确认），重构后仍须保留双平台一一对应（UT-143 契约）。

### 1.2 依赖与可复用模块（TASK-002 已交付，本任务直接复用）

| 文件 | 定位/作用 | 调用契约（重构脚本必须遵守） |
| --- | --- | --- |
| `deploy/scripts/load-env.ps1` | 统一配置加载（Windows，dot-source） | `. $PSScriptRoot\load-env.ps1`；env.json 缺失/解析失败/关键配置 8 项缺失均 `exit 1`；成功输出绿色提示；口令不打印明文 |
| `deploy/scripts/load-env.sh` | 统一配置加载（Linux，source） | `source "$SCRIPT_DIR/load-env.sh"`；失败用 `return 1`（不引入 `set -e`，UT-142-2 契约）；依赖 jq 或 python3 |
| `deploy/env.json` | 唯一配置源 | 27 键全部为字符串类型；含 DB_PASSWORD/RSA_PRIVATE_KEY 等敏感值（git 已忽略） |
| `deploy/env.example.json` | 配置模板（必须入库） | 缺失提示的指引目标（「复制 env.example.json 为 env.json 并填写配置」） |

### 1.3 参考脚本（运行检测/三重检测/三级输出的现成模式来源）

- `deploy/scripts/deploy-start-services.ps1`（219 行）— `Test-Installed` 函数（命令/服务/进程三重检测）、`Write-Result` 三级输出、运行检测（进程/服务/HTTP 探测）与启动确认框架（F-007 下游 TASK-008 使用，本任务仅借鉴其检测与输出模式）。
- `deploy/scripts/deploy-start-services.sh`（239 行）— `has_cmd`/`has_svc`/`has_proc`/`svc_active` 辅助函数、`print_result` 三级输出、`curl` HTTP 探测（`grep -q "Nacos"`）。

### 1.4 测试基线（重构后仍需满足的语法契约，UT-142）

- UT-142-1：全部 .ps1 经 `[System.Management.Automation.Language.Parser]::ParseFile` 无语法错误；
- UT-142-2：全部 .sh 经 `bash -n` 通过（WSL 不可用时降级 shebang + 非空校验；`set -e` 仅质量约定非语法要求，load-env.sh 故意省略，deploy-check-env.sh 为普通执行脚本可保留严格模式）；
- UT-143-1：`deploy-check-env` 的 .ps1+.sh 双平台成对存在。

---

## 2. 现有 deploy-check-env.ps1 源码详细分析（160 行）

### 2.1 硬编码地址位置（P1，必须全部删除）

```
L24-32  param(
  [string]$NacosAddr = "192.168.1.100:8848",   # L25
  [string]$DbHost = "192.168.1.101",           # L26
  [int]$DbPort = 3306,                         # L27
  [string]$DbUser = "root",                    # L28
  [string]$DbPassword = "<DB_PASSWORD>",       # L29
  [string]$RedisHost = "192.168.1.102",        # L30
  [int]$RedisPort = 6379                       # L31
)
L40-46  以「默认值等于硬编码值」判断是否回退 env：
  if (-not $DbPassword -or $DbPassword -eq "<DB_PASSWORD>") { $DbPassword = $env:DB_PASSWORD }
  if ($NacosAddr -eq "192.168.1.100:8848") { $NacosAddr = $env:NACOS_ADDR }
  ...（DbHost/DbPort/DbUser/RedisHost/RedisPort 同理）
```

**问题**：① 硬编码默认地址为主、env.json 为辅；② 「默认值==硬编码值」回退判断脆弱（env 未配置时静默连到 192.168.1.x 错误地址，不报错不退出）；③ `param` 暴露口令型参数 `DbPassword`。

**重构要求（F-010）**：删除 `param` 块全部默认值/参数化，一律经 load-env 从 env.json 读取；关键配置缺失由 load-env 8 项校验兜底。

### 2.2 检查项清单与输出/退出码（P4/P5）

**现有 10 项 Check（按执行顺序）**：

| 段 | 检查项 | 行号 | 判定逻辑 | 归属（F-002~F-006 对齐度） |
| --- | --- | --- | --- | --- |
| 1.1 | Nacos 可用性 | L81-84 | `Invoke-WebRequest http://$NacosAddr/nacos/` 内容含 "Nacos" | ✅ F-005 可用性探测（但位置误放中间件段、与 3.1 重复） |
| 1.2 | MariaDB 可用性 | L87-94 | `mariadb -h ... -p"$DbPassword" -e "SELECT 1"`；L89-90 死代码 `$connStr` 明文 + `New-Object System.Data.Common.DbProviderFactory` 无效创建 | ⚠️ F-003 连通性部分（缺安装三重检测；含死代码 P7-06） |
| 1.3 | Redis 可用性 | L97-100 | `redis-cli -h $RedisHost -p $RedisPort ping` 返回 PONG | ⚠️ F-004 连通性部分（缺安装三重检测） |
| 2.1 | JDK 21 已安装 | L106-109 | `java -version` 匹配 `openjdk version "21` | ✅ F-002 版本检查（缺 JAVA_HOME 有效性合并判定） |
| 2.2 | Maven 3.9+ | L111-114 | `mvn -version` 匹配 `Apache Maven 3.9` | ❌ 无关项（F-010 要求移除/降级可选） |
| 2.3 | Git 已安装 | L116-119 | `git version` 匹配 `git version` | ❌ 无关项 |
| 2.4 | JAVA_HOME 已设置 | L121-123 | `$env:JAVA_HOME` 非空且 Test-Path | ✅ F-002 一部分（应并入 JDK 可用性） |
| 3.1 | Nacos 端口可达 | L129-132 | `Invoke-WebRequest http://$NacosAddr/nacos/` 响应非空 | ❌ 与 1.1 重复 HTTP 探测（P4） |
| 4.1 | 项目代码 pom.xml | L138-140 | `Test-Path $RootDir\pom.xml` | ❌ 无关项（F-010 移除） |
| 4.2 | SQL 脚本存在 | L142-146 | `scripts\sql\auth-init-v0.1.5.sql` + `v0.1.6.sql` 均存在 | ❌ 无关项（F-010 移除） |

**输出与退出码（P5）**：
- L51-68 `Check` 函数：仅「通过（绿）/失败（红）+ 预期提示」两档，**无「警告」分级**（F-011 要求三级）；
- L148-152 汇总 `检查完成: $pass 项通过, $fail 项失败`；
- L154-159 退出码：`if ($fail -gt 0) { exit 1 } else { exit 0 }`——有警告但无失败时为 0（符合 F-011 建议，但当前无警告档故恒为 0/1）。

**其它问题**：
- L35 孤立死代码 `$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive`（P7-05，删除）；
- L89-90 死代码：`$connStr` 含明文密码字符串（未输出）、`New-Object System.Data.Common.DbProviderFactory` 无效创建（P7-06，删除）；
- L92 `-p"$DbPassword"` 命令拼接明文口令（PowerShell 不会显示在进程表，但应改为掩码显示日志）；
- 文件头 L1-22 注释块无 SPDX-License-Identifier 与版权声明（P7-14）。

---

## 3. 现有 deploy-check-env.sh 源码详细分析（150 行）

### 3.1 硬编码地址位置（P1，必须全部删除）

```
L24-31  # ------ 配置区（从 env.json 加载或默认值）------
  NACOS_ADDR="${NACOS_ADDR:-192.168.1.100:8848}"   # L25
  DB_HOST="${DB_HOST:-192.168.1.101}"              # L26
  DB_PORT="${DB_PORT:-3306}"                       # L27
  DB_USERNAME="${DB_USERNAME:-root}"               # L28
  DB_PASSWORD="${DB_PASSWORD:-<DB_PASSWORD>}"      # L29
  REDIS_HOST="${REDIS_HOST:-192.168.1.102}"        # L30
  REDIS_PORT="${REDIS_PORT:-6379}"                 # L31
```

**问题**：同 .ps1——以 `${VAR:-default}` 兜底硬编码地址，env 未设置时静默回退错误地址。重构时删除全部默认值行，变量直接使用 load-env 注入的环境变量（必要时仅做空值防御，不赋默认地址）。

### 3.2 检查项清单与输出/退出码（P4/P5）

**现有 13 项 Check（比 .ps1 多 3 项，双平台结构不一致）**：

| 段 | 检查项 | 行号 | 判定逻辑 | 归属 |
| --- | --- | --- | --- | --- |
| 1.1 | Nacos 服务 | L60-62 | `curl -s http://$NACOS_ADDR/nacos/`（无 grep，仅非空即通过） | ⚠️ F-005 部分（未校验含 "Nacos"） |
| 1.2 | MariaDB | L65-67 | `mariadb ... -p'$DB_PASSWORD' -e 'SELECT 1'`（eval 拼接，口令明文） | ⚠️ F-003（P7-10 泄露风险） |
| 1.3 | Redis | L70-72 | `redis-cli -h ... ping` 返回 PONG | ⚠️ F-004 |
| 2.1 | JDK 21 | L79-81 | `java -version 2>&1 | grep -q 'openjdk version \"21'` | ✅ F-002 |
| 2.2 | Maven 3.9+ | L84-86 | `mvn -version ... grep Apache Maven 3.9` | ❌ 无关项 |
| 2.3 | Git | L89-91 | `git version ... grep git version` | ❌ 无关项 |
| 2.4 | JAVA_HOME | L94-96 | `test -n "$JAVA_HOME" && test -d "$JAVA_HOME"` | ✅ F-002 |
| 3.1 | Nacos 端口可达 | L103-105 | `curl ... | head -1 | grep -q .` | ❌ 与 1.1 重复（P4） |
| 3.2 | MariaDB 端口可达 | L108-110 | `mariadb ... -p'$DB_PASSWORD' -e 'SELECT VERSION()'`（重复连通） | ❌ 重复 |
| 3.3 | Redis 端口可达 | L113-115 | `redis-cli ping`（重复） | ❌ 重复 |
| 4.1 | pom.xml | L122-124 | `test -f "$ROOT_DIR/pom.xml"` | ❌ 无关项 |
| 4.2 | SQL 脚本 | L127-129 | `ls auth-init-v0.1.5.sql v0.1.6.sql | wc -l | grep -q 2` | ❌ 无关项 |
| 4.3 | Maven settings | L132-134 | `test -f ~/.m2/settings.xml -o -f pom.xml` | ❌ 无关项 |

**输出与退出码（P5）**：
- L34-47 `check()`：`eval "$cmd"` 执行命令字符串——**注入/引号风险**（如 `-p'$DB_PASSWORD'` 传参，`set -x` 调试时泄露明文口令，P7-10）；仅「通过（绿）/失败（红）+ 预期提示」两档，无警告分级；
- L136-140 汇总 `检查完成: $PASS 项通过, $FAIL 项失败`；
- L142-149 退出码：失败 `exit 1`、成功 `exit 0`。

**其它问题**：
- L9 `set -euo pipefail`（普通执行脚本可保留，与 load-env.sh 不同）；
- L4 版本号 v0.1.7（P7-13，重构时统一版本标注）；
- 文件头 L1-8 无 SPDX-License-Identifier 与版权声明（P7-14）。

---

## 4. load-env 调用契约（TASK-002 已交付，直接复用依据）

### 4.1 load-env.ps1（PowerShell，dot-source 调用）

- 用法：`. .\deploy\scripts\load-env.ps1 [-EnvFile env.json]`；
- 路径推导：`$ProjectDir = Split-Path -Parent $PSScriptRoot`（= deploy），`$EnvFilePath = Join-Path $ProjectDir $EnvFile`；
- env.json 缺失：Write-Error 提示「复制 env.example.json 为 env.json 并填写配置」并 `exit 1`；解析失败 `exit 1`；
- 关键配置校验 8 项（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失逐个列出键名并 `exit 1`；
- 加载成功输出「环境变量已从 ... 加载，共 N 项」（绿色）；**任何输出不含 DB_PASSWORD/RSA_PRIVATE_KEY 明文**。

### 4.2 load-env.sh（Bash，source 调用）

- 用法：`source deploy/scripts/load-env.sh [env.json]`；
- 依赖 jq（优先）或 python3（回退）解析 env.json 并 export 键值对（`to_entries`/`@sh` 与 `shlex.quote` 正确转义含空格与特殊字符值）；
- env.json 缺失/解析失败/关键配置缺失均 `return 1` 并输出错误提示（含 env.example.json 指引）；
- **不得引入 `set -e`**（source 型脚本污染父 shell，UT-142-2 契约）；成功输出「环境变量已从 ... 加载 (jq/python3)，共 N 项」。

### 4.3 本脚本（deploy-check-env）所需关键配置（load-env 8 项已覆盖）

| 配置键 | 用途 | 检查场景 |
| --- | --- | --- |
| NACOS_ADDR | Nacos 地址 host:port | F-005 可用性探测 / F-006 运行状态 HTTP 探测 |
| NACOS_HOME | Nacos 安装目录 | F-005 安装检测（bin/startup.cmd 或 startup.sh 存在性） |
| DB_HOST / DB_PORT / DB_USERNAME / DB_PASSWORD | MariaDB 连接 | F-003 连通性 SELECT 1 |
| DB_SERVICE_NAME / DB_PROCESS_NAME | MariaDB 安装/运行检测（逗号分隔多值） | F-003 三重检测 / F-006 运行状态 |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD | Redis 连接 | F-004 ping（REDIS_PASSWORD 可选，配置则带口令） |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | Redis 安装/运行检测 | F-004 三重检测 / F-006 运行状态 |
| JAVA_HOME（系统环境变量，非 env.json） | JDK 检测 | F-002（java 命令 + JAVA_HOME + 版本 21） |

> 注：env.json 的 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME 为可选键（load-env 不强制），check-env 使用时应做空值防御（如 `$env:DB_SERVICE_NAME` 为空时用默认 `MySQL, MariaDB` 作为检测名列表——这是检测默认值而非连接地址，允许保留；同理进程名 `mysqld, mariadbd` / `redis-server`）。

---

## 5. deploy/env.json 配置结构（27 键，全部字符串类型）

| 键 | 值示例（本机） | 敏感 | 本任务使用 |
| --- | --- | --- | --- |
| NACOS_ADDR | `127.0.0.1:8848` | 否 | ✅ F-005/F-006 |
| NACOS_HOME | `D:\jenemy\develop\nacos`（Windows）/ `/opt/nacos`（模板） | 否 | ✅ F-005 安装检测 |
| DB_SERVICE_NAME | `MySQL, MariaDB` | 否 | ✅ F-003/F-006 |
| DB_PROCESS_NAME | `mysqld, mariadbd` | 否 | ✅ F-003/F-006 |
| REDIS_SERVICE_NAME | `Redis` | 否 | ✅ F-004/F-006 |
| REDIS_PROCESS_NAME | `redis-server` | 否 | ✅ F-004/F-006 |
| DB_HOST | `127.0.0.1` | 否 | ✅ F-003 |
| DB_PORT | `3306` | 否 | ✅ F-003 |
| DB_USERNAME | `root` | 否 | ✅ F-003 |
| DB_PASSWORD | 真实口令 | **是** | ✅ F-003（口令掩码 `****`） |
| DB_USER | `root` | 否 | ⭕ 兼容项（biz 用，本任务不用） |
| REDIS_HOST | `127.0.0.1` | 否 | ✅ F-004 |
| REDIS_PORT | `6379` | 否 | ✅ F-004 |
| REDIS_PASSWORD | 空 | **是** | ⭕ F-004 可选（配置则带口令验证，掩码） |
| REDIS_DATABASE | `0` | 否 | ⭕ 本任务不用 |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | DER 单行 Base64 | **是** | ⭕ 本任务不用（不打印） |
| VERIFICATION_CODE_* / PASSWORD_* / MARIADB_ROOT_PASSWORD / TZ | 应用参数 | 部分 | ⭕ 本任务不用 |

> env.example.json 与 env.json 键一致，仅敏感值替换为占位符（`<DB_PASSWORD>` 等）、NACOS_HOME 为 Linux 风格 `/opt/nacos`。

---

## 6. 可复用模块与遗留问题（供 code 步骤直接使用）

### 6.1 可复用资产

| 可复用资产 | 位置 | 复用建议 |
| --- | --- | --- |
| load-env.ps1 / load-env.sh | TASK-002 已交付 | 脚本开头调用（`. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`）；env.json 缺失/关键配置缺失的提示与退出由 load-env 兜底，本脚本无需重复实现 |
| 三重安装检测模式（ps1） | deploy-start-services.ps1 L52-73 `Test-Installed` | 改造为返回布尔/命中方式的简洁函数，用于 F-003/F-004 安装检测（命令 → 服务 → 进程） |
| 三重安装检测辅助（sh） | deploy-start-services.sh L66-82 `has_cmd`/`has_svc`/`has_proc` | 直接复制改造（注意 sh 版 `has_svc`/`svc_active` 用 systemctl，Linux 适用） |
| 三级输出模式 | deploy-start-services.ps1 L46-50 `Write-Result` / .sh L57-64 `print_result` | 作为「通过/警告/失败」三级输出模板（.ps1 用 Write-Host + 颜色，.sh 用 printf + ANSI） |
| 逗号分隔转数组（ps1） | deploy-start-services.ps1 L76-80 `-split '\s*,\s*'` | 解析 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME |
| 逗号分隔转数组（sh） | deploy-start-services.sh L44-49 `split_csv`（tr/xargs） | 同上 |
| TCP 端口探测（sh） | deploy-start-services.sh 参考 `curl` 方案 | F-006 运行状态 TCP/HTTP 探测（.ps1 用 Test-NetConnection 或 TcpClient，.sh 用 `curl`/`nc` 或 `/dev/tcp`） |
| env.example.json | deploy/env.example.json | 错误提示的指引目标文案统一为「复制 env.example.json 为 env.json 并填写配置」 |

### 6.2 遗留问题与重构处置（本任务 code 步骤实现依据）

| 编号 | 问题 | 现状定位 | 重构处置 |
| --- | --- | --- | --- |
| G1 | 硬编码默认地址（P1） | .ps1 L25-31 / .sh L25-31 | 删除 param 块与 `${VAR:-default}` 默认值行，一律经 load-env 读取；连接类地址（NACOS_ADDR/DB_HOST/REDIS_HOST）不做默认兜底；服务/进程名可保留默认清单（非地址） |
| G2 | Nacos 重复探测（P4） | .ps1 L81-84 + L129-132 / .sh L60-62 + L103-105 | 合并为一次 HTTP 探测：可用性探测 + 运行状态探测共用 `http://NACOS_ADDR/nacos/` 含 "Nacos" 判定（任务定义/PRD 明确）；issue-list P7-11 建议 `/nacos/v1/console/health/readiness`，两种均应识别"运行中"——实现时以 PRD 为准优先 `/nacos/` |
| G3 | 无关检查项（F-010） | Maven/Git/SQL/pom.xml/Maven settings（.ps1 L111-119/L138-146；.sh L84-91/L122-134） | 移除或降为可选信息输出；JDK 检查并入 F-002（命令+JAVA_HOME+版本 21 合并为一个可用性结论） |
| G4 | 运行状态检查缺失（P4） | check-env 无 Get-Process/Get-Service/systemctl/pgrep | 新增 F-006 运行状态检测段：JDK 复用可用性结论（就绪）；MariaDB/Redis 进程/服务/TCP 任一命中=运行中；Nacos HTTP 探测含 "Nacos"=运行中，失败再检测 java 进程命令行含 nacos |
| G5 | 无警告分级（P5） | Check 函数仅通过/失败 | 输出三级「通过/警告/失败」；Nacos 已安装未启动计"警告（未运行）"而非失败 |
| G6 | 退出码约定（F-011） | 仅 0/1 | 全部通过退出 0；存在失败项退出非零（1）；存在警告但无失败退出 0 并提示警告 |
| G7 | eval 拼接与口令明文（P5/P7-10） | .sh L39 `eval "$cmd"` / L66 `-p'$DB_PASSWORD'` | 改写为直接命令 + 数组参数（`cmd=(mariadb -h "$host" ...); "${cmd[@]}"`）；口令参数掩码显示（`****`）、日志不打印明文 |
| G8 | 死代码（P7-05/06） | .ps1 L35 / L89-90 | 删除孤立行、无效 DbProviderFactory、含明文密码的连接字符串；SELECT 1 用命令行且口令掩码 |
| G9 | 版本号陈旧（P7-13） | .sh v0.1.7 | 统一版本标注（如 v0.2.7） |
| G10 | 无 SPDX 头（P7-14） | 双版本均无 | 文件头保留 `# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`；简体中文注释 |

### 6.3 明确不在本任务范围（避免越界）

- 基础设施一键启动（MariaDB/Redis/Nacos 启动动作）属 TASK-008（deploy-start-services 重构），本任务仅输出「未运行」状态（供 F-007 使用），**不执行启动**；
- 后端服务按序一键启动属 TASK-010（deploy-start-all 新增），本任务不涉及；
- 单服务启动脚本（deploy-start-gateway/auth/biz/system）重构属 TASK-005（issue-list P1/P5 涉及），本任务不改；
- rsa-keygen 契约对齐属 TASK-006（issue-list P3）；
- .gitignore 治理属 TASK-007（用户输入第 4 点，本任务不执行；当前 .gitignore 332 行已覆盖日志/临时/env.json/客户端产物，缺口清单见 issue-list 4.2）；
- deploy-env* 弃用脚本清理属 TASK-005（issue-list P2）。

### 6.4 双平台行为一致性要求（SAD 1.2 / F-010 / F-011）

- 检查项一一对应：可用性检查（JDK 命令+JAVA_HOME+版本 21 / MariaDB 三重+SELECT 1 / Redis 三重+ping / Nacos 安装+HTTP）+ 运行状态检测（进程/服务/TCP/HTTP）四项一一对应；
- 输出分级与退出码一致（通过/警告/失败三级；全部通过 0 / 失败非零 / 警告无失败 0）；
- 语法校验：.ps1 经 PowerShell Parser、.sh 经 `bash -n`（UT-142 契约）；.sh 为普通执行脚本可保留 `set -euo pipefail`（与 load-env.sh 的 source 语义不同）。

---

## 7. 相关文档要点摘录（供后续步骤引用）

- **F-002（PRD 4.2）**：JDK 检测项 = `java -version` 输出含 `version "21`（或 `openjdk version "21`）+ JAVA_HOME 已设置且目录有效；任一失败输出"失败"并给处理建议（安装 JDK 21 / 配置 JAVA_HOME）；JDK 仅检查可用性不执行启动。
- **F-003（PRD 4.3）**：MariaDB 安装检测任一命中即已安装（命令 mariadb/mysql/mysqld/mariadbd、系统服务 DB_SERVICE_NAME 逗号分隔多值、进程 DB_PROCESS_NAME 逗号分隔多值）；连通性 SELECT 1（ps1 用 mariadb/mysql 命令行，sh 用 mariadb/mysql 或 mysqladmin ping）；口令掩码 `-p'****'`；定位"可用性"（已安装+可连接）与运行状态区分。
- **F-004（PRD 4.4）**：Redis 安装检测任一命中（redis-cli/redis-server、REDIS_SERVICE_NAME、REDIS_PROCESS_NAME）；`redis-cli -h REDIS_HOST -p REDIS_PORT ping` 返回 PONG 通过；REDIS_PASSWORD 配置且客户端支持则带口令验证（不打印明文）。
- **F-005（PRD 4.5）**：Nacos 安装检测 = NACOS_HOME 存在且 `bin/startup.cmd`（Windows）/ `bin/startup.sh`（Linux）存在；HTTP 探测 `http://NACOS_ADDR/nacos/` 响应含 "Nacos" 视为连通；**Nacos 尚未启动但安装存在，HTTP 探测失败计"警告（未运行）"而非"未安装"**；NACOS_ADDR 未配置或格式非法（非 host:port）输出失败并提示检查 env.json。
- **F-006（PRD 4.6）**：JDK 复用 F-002 结论视为"就绪"；MariaDB/Redis 进程/服务为 Running/TCP 端口（3306/6379）任一命中即运行中；Nacos HTTP 探测含 "Nacos" 视为运行中，探测失败再检测 java 进程命令行含 nacos 作辅助判断；运行状态与可用性分开输出（未运行/运行中/未安装）。
- **F-010（PRD 4.10）**：删除硬编码默认地址；检查范围对齐 F-002~F-005+F-006；输出分级汇总，存在失败项给处理提示并退出非零，全部通过退出 0；移除 Maven/Git 版本、项目代码检查等无关项或降为可选信息；保留 .ps1/.sh 双版本且行为一致。
- **F-011（PRD 4.11）**：输出分级约定（通过绿色/警告黄色/失败红色；汇总显示计数）；退出码约定（全部通过 0 / 失败非零 1 / 警告无失败建议 0 并提示警告）；文件头保留 SPDX 与版权声明；.ps1/.sh 行为一致、可独立验证。
- **部署顺序与端口（SAD）**：基础设施 MariaDB 3306 / Redis 6379 / Nacos 8848，启动顺序 MariaDB → Redis → Nacos；后端 gateway 9000 → auth 9100 → biz 9200 → system 9400（本任务不启动，仅输出状态供下游衔接）。
- **issue-list（TASK-001 交付物）**：P1 硬编码地址定位（check-env.ps1 L25-31 / .sh L25-31）；P4 能力分散（Nacos 重复探测 L81-84+L129-132 / L60-62+L103-105；无运行状态检查；双平台 10 vs 13 项）；P5 输出与退出码（check-env 无警告档；.sh eval 注入风险）；P7-05/06/10/11/13/14 附加发现。
- **测试基线**：UT-142-1/2（语法校验）、UT-143-1（双平台成对）重构后须继续满足；issue-list 测试（UT-133/136/137/138/140/141）为「现状确认」型断言，重构后部分将转否定（由 code/runtest 步骤的 TASK-003 新测试用例覆盖）。

---

## 8. 编码建议（供 code 步骤参考，非本任务执行）

1. **整体结构**：脚本开头调用 load-env（`. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`）；无 param 块、无 `192.168.1.x` 默认地址；定义三级输出辅助函数（通过/警告/失败 + 计数）；
2. **检查顺序与分组**：阶段一「可用性检查」（JDK → MariaDB → Redis → Nacos，对应 F-002~F-005）→ 阶段二「运行状态检测」（JDK 复用可用性结论为"就绪"；MariaDB/Redis 进程/服务/TCP；Nacos HTTP + java 进程辅助，对应 F-006）→ 输出汇总；
3. **JDK 可用性**：合并为一项——`java -version` 含 `version "21`（兼容 openjdk/temurin 等前缀）且 JAVA_HOME 已设置且目录有效；任一失败"失败"并提示安装 JDK 21 / 配置 JAVA_HOME；
4. **MariaDB**：安装三重检测（命令 mariadb/mysql/mysqld/mariadbd → 服务 DB_SERVICE_NAME 逗号分隔 → 进程 DB_PROCESS_NAME 逗号分隔）；连通 SELECT 1（命令存在才执行）；口令掩码——.ps1 输出显示 `-p****` 不打印实际口令、.sh 用数组参数 `cmd=(mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1")`，日志不打印 `$DB_PASSWORD` 明文；
5. **Redis**：安装三重检测（命令 redis-cli/redis-server → 服务 REDIS_SERVICE_NAME → 进程 REDIS_PROCESS_NAME）；`redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping` 返回 PONG；REDIS_PASSWORD 非空且支持 `-a` 时带口令（掩码）；
6. **Nacos**：安装检测 `NACOS_HOME` 存在 + `bin/startup.cmd`（ps1）/`bin/startup.sh`（sh）存在；可用性探测 HTTP `http://NACOS_ADDR/nacos/` 含 "Nacos"；**安装存在但探测失败 → "警告（未运行）"**；未安装 → "失败"并提示安装 Nacos/配置 NACOS_HOME；NACOS_ADDR 缺失/格式非法 → "失败"提示检查 env.json；
7. **运行状态检测**：MariaDB/Redis 进程（Get-Process / pgrep）或服务 Running 或 TCP 端口（3306/6379）可达任一命中=运行中，否则"未运行"；Nacos HTTP 含 "Nacos"=运行中，失败再检测 java 进程命令行含 nacos（ps1 用 `Get-CimInstance Win32_Process` 过滤 CommandLine，sh 用 `pgrep -f nacos`）；
8. **汇总与退出码**：汇总 `通过: X | 警告: Y | 失败: Z`；`失败 > 0 → exit 1`；`警告 > 0 且失败 = 0 → exit 0` 并提示有警告；全通过 → exit 0；
9. **安全与规范**：文件头 SPDX + 版权声明、简体中文注释、统一版本号（v0.2.7）；删除一切死代码；避免 eval；.sh 保留 `set -euo pipefail`（普通执行脚本）；
10. **验证提示（testMethod）**：.ps1 经 Parser 校验、.sh 经 `bash -n`；grep 192.168.1.1xx 不得命中 check-env；口令掩码输出检查（脚本输出不含 DB_PASSWORD 明文）；各环境通过/失败/警告场景与退出码验证（JDK 缺失→失败+非零；Nacos 已安装未启动→警告+0；全通过→0）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
