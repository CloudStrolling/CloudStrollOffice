# 网络资料查询报告（#TASK-006 重构单服务启动脚本 deploy-start-gateway/auth/biz/system）

## 1. 查询范围与任务对应关系

| 任务技术点 | 查询对象 | 官方资料来源 | 结论 |
| --- | --- | --- | --- |
| `java -jar` 后台启动 | java 命令语法、-Xms/-Xmx、-jar、退出状态 | Oracle JDK 21 Tool Specifications | ✅ 兼容 |
| PowerShell 后台化与日志重定向 | Start-Process（-PassThru/-RedirectStandardOutput/-RedirectStandardError/-WindowStyle） | Microsoft Learn（5.1 与 7.x 双版本） | ✅ 兼容，已本机实测 |
| Linux nohup 后台启动记录 PID | nohup 行为、`&` 后台化、`$!`、重定向 | GNU Coreutils 手册（nohup invocation） | ✅ 兼容 |
| Spring Boot 健康检查 | Actuator /actuator/health 语义 | Spring Boot Reference（Actuator） | 语义参考（本项目用自定义 /api/v1/{module}/health） |
| HTTP/TCP 探测轮询超时 | curl（-s/-m/-o）、bash /dev/tcp、PowerShell TcpClient/HttpClient | curl man page、Bash Reference Manual、Microsoft Learn | ✅ 兼容 |
| .gitignore 临时/中间文件排除 | gitignore 模式语法、已跟踪文件规则 | git-scm.com/docs/gitignore | ✅ 兼容 |

## 2. 环境版本实测（本机，2026-08-10）

| 组件 | 实测版本 | 与文档版本对照 |
| --- | --- | --- |
| OpenJDK | 21.0.9 LTS（Temurin-21.0.9+10） | 与 Oracle JDK 21 Tool Specifications 完全对应（本项目 Java 21 ✅） |
| git | 2.53.0.windows.1 | gitignore 语法自 2.42 起无实质变化（2.53.0 手册标注 no changes）✅ |
| Windows PowerShell | 5.1.19041.7548（Desktop） | 与 Microsoft Learn powershell-5.1 文档对应 ✅ |
| curl.exe | 8.13.0（Windows，Schannel） | 与 curl 8.22.0 man page 参数兼容（-s/-m/-o/-f 均为长期稳定参数）✅ |
| bash.exe | WSL 版本存在（C:\Windows\System32\bash.exe） | .sh 脚本在 Git Bash/WSL 下运行，Bash 5.x 重定向语法兼容 ✅ |

> ⚠️ PowerShell 注意：`curl` 在 PowerShell 中是 `Invoke-WebRequest` 的别名，脚本内必须显式写 `curl.exe` 才能调用真实 curl（.sh 脚本不受影响）。

## 3. java 命令官方文档要点（Oracle JDK 21 Tool Specifications）

来源：https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html

### 3.1 启动 JAR 语法与 -jar
- `java [options] -jar jarfile [args ...]`：执行 manifest 中 `Main-Class` 声明的应用入口；使用 `-jar` 时 JAR 是全部用户类来源，其他 classpath 设置被忽略。
- 本任务启动命令 `java -Xms256m -Xmx512m -jar <jar>` 与该语法完全一致，无需改动。

### 3.2 内存参数 -Xms / -Xmx（Extra Options，HotSpot）
- `-Xms size`：初始/最小堆大小，值必须为 1024 的倍数且大于 1MB（`-Xms256m` ✅）。
- `-Xmx size`：最大堆大小，值必须为 1024 的倍数且大于 2MB（`-Xmx512m` ✅）。
- 后缀 k/K（KB）、m/M（MB）、g/G（GB）均合法；不设置时 -Xmx 按系统配置运行时决定。
- 结论：`java -Xms256m -Xmx512m -jar` 参数组合合法，4 个服务一致使用。

### 3.3 退出状态（Exit Status）
- java 命令退出码：0=成功；>0=错误（如启动失败、异常终止）。脚本可通过 java 自身退出码判断是否启动即失败（结合健康轮询更可靠）。
- `javaw`（Windows）：无控制台窗口版本，启动失败时弹错误对话框——**不推荐**用于后台化（应使用 Start-Process -WindowStyle Hidden 保持 java 语义一致）。

### 3.4 后台启动适用性结论
- java 本身不提供 daemon 化能力，后台化必须由外层脚本完成：Windows 用 Start-Process（见 §4）、Linux 用 nohup + `&`（见 §5）。该结论与 TASK-005 deploy-start-all 现有实现一致。

## 4. PowerShell Start-Process 官方文档要点（Microsoft Learn）

来源：
- 5.1：https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-5.1
- 7.x：https://github.com/microsoftdocs/powershell-docs（Start-Process.md）

### 4.1 关键参数（5.1 与 7.x 一致）
| 参数 | 作用 | 本任务用途 |
| --- | --- | --- |
| `-PassThru` | 返回 System.Diagnostics.Process 对象（默认无输出） | `$proc.Id` 取 PID 写入 pid 文件 |
| `-RedirectStandardOutput <file>` | stdout 重定向到文件 | 写入 `deploy/logs/{module}-start.log` |
| `-RedirectStandardError <file>` | stderr 重定向到文件 | 写入 `deploy/logs/{module}-start.err` |
| `-WindowStyle Hidden` | 新进程窗口隐藏（仅 Windows） | 后台无窗启动 |
| `-WorkingDirectory` | 设置进程工作目录 | 可配合 jar 相对路径（可选） |
| `-Wait` | 等待进程及后代退出 | **本任务不用**（需要后台化） |

### 4.2 参数互斥与限制（必须遵守，避免脚本报错）
- **`-NoNewWindow` 与 `-WindowStyle` 不能同用**（官方 5.1 文档明确："You can't use the NoNewWindow and WindowStyle parameters in the same command."）。
- 本任务使用 `-WindowStyle Hidden` 组合，**不要**同时传 `-NoNewWindow`。
- `-RedirectStandardOutput` 与 `-RedirectStandardError` 的文件路径**必须不同**（同一文件会报错）。
- 重定向目标文件路径所在目录必须已存在（脚本先 `New-Item -Force` 创建 logs 目录）。
- 7.x 中重定向仅与 UseShellExecute=false 的默认参数集兼容；5.1 无该问题（本机 5.1 实测通过，见 §4.4）。

### 4.3 官方文档示例（5.1）
```powershell
$processOptions = @{
    FilePath = "sort.exe"
    RedirectStandardInput = "TestSort.txt"
    RedirectStandardOutput = "Sorted.txt"
    RedirectStandardError = "SortError.txt"
}
Start-Process @processOptions
```
（splatting 风格可选；本任务直接传参或 splatting 均可，与 deploy-start-all.ps1 现有风格对齐即可。）

### 4.4 本机实测验证（Windows PowerShell 5.1.19041）
执行 `Start-Process -FilePath "java" -ArgumentList "-version" -WindowStyle Hidden -RedirectStandardOutput $out -RedirectStandardError $err -PassThru`：
- ✅ 正常返回 Process 对象，`$proc.Id` 可获取 PID；
- ✅ java 的 stderr 输出（-version 打印到 stderr）完整落入 err 文件；
- ✅ 进程异步启动（未加 -Wait，控制权立即返回）；
- ✅ 进程退出后可读 `$proc.HasExited` / `$proc.ExitCode`。
- 结论：`-WindowStyle Hidden + -RedirectStandardOutput/-RedirectStandardError + -PassThru` 组合在 PS 5.1 上稳定可用，与 TASK-005 基准一致。

## 5. GNU nohup 官方文档要点（GNU Coreutils 手册）

来源：https://www.gnu.org/software/coreutils/manual/html_node/nohup-invocation.html（手册版本 9.11）

### 5.1 nohup 行为（官方原文要点）
- `nohup command [arg]...`：使命令对挂断信号（SIGHUP）免疫，注销后仍可后台运行。
- **nohup 不会自动后台化**——必须显式以 `&` 结尾才进入后台（"nohup does not automatically put the command it runs in the background; you must do that explicitly, by ending the command line with an '&'"）。✅ 与基准脚本 `nohup java ... &` 一致。
- 若 stdout 是终端，nohup 会把输出追加到 `nohup.out`（$HOME 下），因此**必须显式重定向**避免污染仓库根目录：`nohup java ... >"$LOG_FILE" 2>&1 &` ✅。
- 退出状态：125=nohup 自身失败；126=命令找到但无法调用；127=命令未找到；否则为命令自身的退出状态。脚本可用 `$?` 判断 nohup 启动是否成功。

### 5.2 PID 记录（$! 特殊变量）
- Bash 中 `$!` 为最近放入后台的异步命令的进程 ID。`echo $! > "$PID_FILE"` 与基准一致 ✅。
- 官方依据：Bash Reference Manual 特殊变量（`$!`：Expands to the process ID of the job most recently placed into the background）。

### 5.3 与基准脚本的对照
基准（TASK-005）：
```bash
nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
```
完全符合 nohup 官方语义，无需修改。重定向顺序 `>"$LOG_FILE" 2>&1` 正确（见 §7.2 重定向顺序要点）。

## 6. Spring Boot 健康检查官方文档要点

来源：Spring Boot Reference（Actuator Endpoints，spring-projects/spring-boot 文档）

### 6.1 Actuator /actuator/health 语义（官方）
- `GET /actuator/health` 返回应用健康状态；健康状态映射 HTTP 响应码：UP→200，DOWN/OUT_OF_SERVICE→503。
- 健康端点通过 HTTP 暴露的默认前缀为 `/actuator`。
- 自定义 HttpCodeStatusMapper 可改变映射，自定义 HealthIndicator 可扩展健康判定。

### 6.2 本任务适用性结论
- 本项目 4 个服务使用**自定义健康端点**（非 Actuator）：gateway `http://localhost:9000/`；auth/biz/system `http://localhost:{port}/api/v1/{module}/health`（见 context.md 5.3 契约表）。
- 健康探测的**判定标准**采用 TASK-005 现有语义：任一 HTTP 响应（含 404/401/500 等错误码）即认为服务已启动——该策略对自定义端点与 Actuator 均适用，且不依赖响应体 JSON 解析，比"仅 200 才通过"更稳健（避免端点返回非 200 但服务实际可用的误判）。
- 轮询超时参数：默认 30 次 × 2 秒间隔，单次 3 秒（.ps1 param RetryCount/RetryInterval/ProbeTimeout；.sh 环境变量 RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT），与基准一致。
- ⚠️ 建议（非强制）：若后续服务暴露 Actuator，健康 URL 可升级为 `/actuator/health` 并校验 HTTP 200 + JSON 含 `"status":"UP"`；本次重构不改变端点契约，仅按现有契约表实现。

## 7. HTTP/TCP 探测轮询技术要点

### 7.1 curl（curl.exe）关键参数（curl 8.22.0 man page / 本机 8.13.0）
| 参数 | 含义 | 用途 |
| --- | --- | --- |
| `-s, --silent` | 静默模式，隐藏进度条与错误 | 探测时避免刷屏 |
| `-S, --show-error` | 与 -s 同用时仍显示错误 | 可选调试 |
| `-m, --max-time <sec>` | 整个传输最大时间（秒） | 单次探测超时 3 秒 ✅ |
| `--connect-timeout <sec>` | 仅连接阶段超时 | 可选更细粒度控制 |
| `-o <file>` / `-O` | 输出到文件（-o - 表示丢弃到 stdout 也可用 `-o /dev/null`） | 丢弃响应体 |
| `-f, --fail` | HTTP ≥400 时退出码 22 而非 0 | **注意**：基准采用"错误码也算启动"，因此默认**不**加 -f 或忽略其退出码 |

> 与基准对照：`http_ok` 用 `curl -s -m $PROBE_TIMEOUT`，HTTP 错误码不视为失败（不传 -f 或忽略退出码）——与 6.2 判定策略一致 ✅。Windows 上 .ps1 不使用 curl，用 .NET HttpClient/TcpClient（见 7.3）。

### 7.2 Bash /dev/tcp 与重定向（Bash Reference Manual 3.6）
- `/dev/tcp/host/port`：Bash 尝试打开对应 TCP 套接字（host 可为 IP 或主机名，port 为整数或服务名）；打开失败即重定向失败 → 可作 TCP 端口探测。
- 重定向顺序语义：`>file 2>&1` 先将 stdout 指向文件再把 stderr 复制到当前 stdout（即文件）✅；`2>&1 >file` 则仅 stdout 进文件（stderr 仍终端）❌。基准 `>"$LOG_FILE" 2>&1` 顺序正确。
- `&>word` 等价于 `>word 2>&1`（现代写法）；`&>>word` 等价于 `>>word 2>&1`（追加）。
- 提示：若 bash 未启用重定向到 /dev/tcp（编译选项），`tcp_port_open` 会失败——基准已用 `timeout` 防挂起，可保留；Git Bash 下 /dev/tcp 通常可用。

### 7.3 PowerShell 端口/HTTP 探测（.NET 方式，PS 5.1 兼容）
- TCP：`System.Net.Sockets.TcpClient` + `BeginConnect`/`WaitOne(timeout)` 实现带超时探测（基准 Test-TcpPort 已实现，TcpClient.ConnectAsync 在 PS 5.1 可用性需注意——基准用异步 + WaitOne 方式，兼容 5.1 ✅）。
- HTTP：`System.Net.Http.HttpClient`（PS 5.1 中可用）或 `Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue`；基准 Test-HttpOk 接受"任一响应码即通过"的语义（HttpStatusCode 只要拿到了响应即成功）。
- 备选：`Test-NetConnection -ComputerName localhost -Port 9000 -InformationLevel Quiet`（PS 5.1 内置，但较慢，不推荐循环轮询用；TcpClient 方式更轻量）。

## 8. .gitignore 官方文档要点（git-scm.com/docs/gitignore，对应 git 2.53.0）

来源：https://git-scm.com/docs/gitignore

### 8.1 关键规则（官方原文语义）
1. **已跟踪文件不受 .gitignore 影响**："Files already tracked by Git are not affected"——若需停止跟踪必须先 `git rm --cached` 再加规则（官方 NOTES 明确）。
2. 模式优先级：同目录 .gitignore 内**最后匹配的模式决定结果**（从上到下、可被 `!` 反转）。
3. `!` 前缀否定：可重新包含被排除的文件；但**父目录被排除时无法重新包含子文件**（"It is not possible to re-include a file if a parent directory of that file is excluded"）。
4. 目录规则以 `/` 结尾：`foo/` 仅匹配目录及其下所有路径；`*.log` 无斜杠匹配任意层级。
5. 中间斜杠锚定：`doc/frotz` 相对 .gitignore 所在目录；无斜杠模式匹配任意层级。
6. `**` 特殊语义：`**/foo` 任意层级、`abc/**` 目录内全部、`a/**/b` 中间零或多级。

### 8.2 对本任务（用户输入需求 3）的应用建议
| 建议 | 规则写法 | 依据 |
| --- | --- | --- |
| 显式忽略 Tomcat 调试工作区 | `work/` | cs.md 6.3：根目录 work/ 现无规则（空目录 git 不追踪，但 Tomcat 解压/调试产物一旦产生可能混入） |
| 全局忽略部署过程产物 | `*.err`、`*.pid` | cs.md 6.3 可选建议：deploy/logs 已由 `logs/` 覆盖，其他位置产生的 err/pid 文件需全局兜底（注意 `*.err` 与既有 `*.log` 对称） |
| 已覆盖项复核（无需改动） | `*.jar`、`*.log`、`logs/`、`keys/`、`env.json`、`__pycache__/` 等 | cs.md 6.1 已用 git check-ignore 实测确认 ✅ |
| 若部署后出现已追踪的临时文件 | 先 `git rm --cached <file>` 再加规则 | 官方 NOTES 规则 1 |

> 注意：新增规则后应用 `git check-ignore -v <path>` 验证；`work/` 采用无斜杠目录规则即可匹配任意层级（与现有 `logs/`、`keys/` 风格一致）。

## 9. 版本兼容性结论汇总

| 资料 | 版本 | 项目环境 | 兼容性 | 说明 |
| --- | --- | --- | --- | --- |
| Oracle java 命令规范 | JDK 21 | OpenJDK 21.0.9 LTS | ✅ 完全兼容 | -jar/-Xms/-Xmx 语法一致 |
| Start-Process 文档 | PS 5.1 & 7.x | Windows PowerShell 5.1.19041 | ✅ 兼容（5.1 实测） | 遵守 NoNewWindow/WindowStyle 互斥 |
| GNU nohup 手册 | Coreutils 9.11 | Linux/Git Bash | ✅ 兼容 | 语义稳定多年未变 |
| Spring Boot Actuator | 3.x（本项目 3.2.5） | 自定义 /api/v1/{module}/health | ✅ 语义参考 | 不改变端点契约 |
| curl man page | 8.22.0（本机 8.13.0） | Windows 自带 curl.exe | ✅ 兼容 | -s/-m/-o/-f 长期稳定 |
| Bash Reference Manual | Bash 5.x | WSL/Git Bash | ✅ 兼容 | /dev/tcp、重定向顺序 |
| gitignore 手册 | 2.53.0（无变化） | git 2.53.0 | ✅ 完全兼容 | 语法 2.42 起稳定 |

## 10. 编码实现要点提醒（供 BEE/FEE 参考，源自官方文档）

1. **.ps1 后台启动**（与 deploy-start-all.ps1 一致）：
   `Start-Process -FilePath "java" -ArgumentList "-Xms256m","-Xmx512m","-jar",$jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru`；`$proc.Id | Out-File -Encoding ascii $pidFile`。
2. **.sh 后台启动**（与 deploy-start-all.sh 一致）：
   `nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &`；`echo $! > "$PID_FILE"`；nohup 退出码 125/126/127 可判断启动失败。
3. **日志目录先建**：.ps1 `New-Item -ItemType Directory -Force $logDir`；.sh `mkdir -p "$LOG_DIR"`（重定向目标目录不存在会导致 Start-Process/nohup 失败）。
4. **健康探测判定**：HTTP 任一响应（含 4xx/5xx）即视为启动；TCP 端口探测备用；轮询默认 30×2s、单次 3s，参数可配置。
5. **curl 注意**：.ps1 中不要用 `curl`（PowerShell 别名 Invoke-WebRequest），.ps1 采用 .NET HttpClient/TcpClient；.sh 用 `curl -s -m`。
6. **gitignore**：`work/` 与 `*.err`、`*.pid` 按 §8.2 建议补充；注意"已跟踪文件不受影响"规则，新增规则后 git check-ignore 验证。
7. 所有脚本保留 SPDX-License-Identifier（Apache-2.0）与版权声明（Copyright 2026 jenemy8023 <jenemy8023@163.com>）。

## 11. 资料出处清单

| 序号 | 资料 | 链接 |
| --- | --- | --- |
| 1 | java 命令（JDK 21） | https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html |
| 2 | Start-Process（PS 5.1） | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process?view=powershell-5.1 |
| 3 | Start-Process（PS 7.7） | https://github.com/microsoftdocs/powershell-docs/blob/main/reference/7.7/Microsoft.PowerShell.Management/Start-Process.md |
| 4 | nohup（GNU Coreutils 9.11） | https://www.gnu.org/software/coreutils/manual/html_node/nohup-invocation.html |
| 5 | Spring Boot Actuator Endpoints | https://github.com/spring-projects/spring-boot/blob/main/documentation/spring-boot-docs/src/docs/antora/modules/reference/pages/actuator/endpoints.adoc |
| 6 | curl man page（8.22.0） | https://curl.se/docs/manpage.html |
| 7 | Bash Reference Manual Redirections | https://www.gnu.org/software/bash/manual/html_node/Redirections.html |
| 8 | gitignore 文档（git 2.53.0） | https://git-scm.com/docs/gitignore |
| 9 | 本机实测记录 | Java 21.0.9 / PS 5.1.19041 / git 2.53.0 / curl.exe 8.13.0（2026-08-10 实测） |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
