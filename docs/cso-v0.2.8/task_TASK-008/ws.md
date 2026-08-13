# TASK-008 网络资料查询（ws.md）

## 1. 技术背景
本任务为部署停止脚本更新（deploy-stop-all / deploy-stop-common，.ps1/.sh 双平台），核心是进程定位与终止，涉及技术均为 PowerShell 5.1 与 Bash 内置能力，不引入三方包。以下为官方文档要点与最佳实践（用于与现有 v0.2.7 脚本体系对齐）。

## 2. PowerShell 进程管理（deploy-stop-all.ps1 / deploy-stop-common.ps1）
- **Get-Process**：按 PID 或名称查询进程，`Get-Process -Id <pid> -ErrorAction SilentlyContinue` 进程不存在时不报错返回 $null。官方文档：learn.microsoft.com/powershell/module/microsoft.powershell.management/get-process。
- **Get-CimInstance Win32_Process**：查询进程命令行，`-Filter "Name = 'java.exe'"` + `Where-Object { $_.CommandLine -match ... }`，用于按 jar 名定位进程（现有脚本 Find-JavaPidByJar 已实现）。
- **Stop-Process**：终止进程，`Stop-Process -Id <pid>`（默认发 WM_CLOSE），`-Force` 强制终止（相当于 taskkill /F）。官方文档：learn.microsoft.com/powershell/module/microsoft.powershell.management/stop-process。
- **轮询等待退出**：循环 `Get-Process -Id <pid> -ErrorAction SilentlyContinue` 判断进程是否消失，超时上限内每间隔探测一次（现有脚本 Wait-ProcessGone 已实现，默认 30s/2s）。
- **进程定位安全原则**：优先读取 PID 文件 + 校验进程命令行含 jar 名（避免误杀无关 java 进程），PID 文件缺失或进程不存在视为已停止（幂等）。

## 3. Bash 进程管理（deploy-stop-all.sh / deploy-stop-common.sh）
- **pgrep -f <pattern>**：按完整命令行匹配进程并返回 PID，`pgrep -f "cloudoffice-common.jar" | head -n1`。官方文档：man pgrep。
- **kill <pid>**：默认发送 SIGTERM（优雅停止），`kill -0 <pid>` 探测进程是否存在（存在返回 0），`kill -9` SIGKILL 强杀。
- **wait_for_proc_gone**：`kill -0` 循环探测进程退出，超时后 `kill -9` 强杀（现有脚本已实现）。
- **/proc/<pid>/cmdline 校验**：读取 PID 文件后校验命令行含 jar 名（现有脚本已实现，`tr '\0' ' ' < /proc/$PID/cmdline`）。

## 4. 版本兼容性
- 目标环境 PowerShell 5.1（当前开发机实测 5.1.19041，java 21 可用）。所用 cmdlet（Get-Process/Get-CimInstance/Stop-Process/Test-Path/Get-Content）均为 PS 5.1 内置，无兼容性问题。
- Bash 侧使用 pgrep/kill/sleep/tr/grep 等 POSIX 标准命令，与现有 .sh 脚本保持一致。
- 不引入任何三方模块/包，无版本兼容风险。

## 5. 本任务关键实践结论
- deploy-stop-common 复用 deploy-stop-all 的进程定位/停止/等待逻辑，只针对 common 单服务（jar=cloudoffice-common.jar，端口=9300）。
- deploy-stop-all 在服务清单末尾追加 common（system→biz→auth→gateway→common），汇总输出含 common。
- 保持 v0.2.7 脚本体系约定：load-env 加载 env.json、输出分级（通过/警告/失败）、退出码失败非零、双平台行为一致、口令不打印明文。
