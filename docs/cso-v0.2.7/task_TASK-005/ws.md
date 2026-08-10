# 网络资料查询报告（TASK-005 新增 deploy-start-all.ps1 / .sh 后端服务按序一键启动）

## 0. 查询概览

| 项目 | 内容 |
| --- | --- |
| 任务编号 | TASK-005 |
| 任务目标 | 新增 `deploy/scripts/deploy-start-all.ps1` / `.sh`（F-008 后端服务按序一键启动总入口） |
| 涉及技术点 | Java `-jar` 启动 Spring Boot、PowerShell `Start-Process` 后台启动、Linux `nohup` 后台启动与 PID 记录、HTTP 健康探测轮询、端口占用检测 |
| 资料来源 | Spring Boot 官方文档（context7）、微软 PowerShell 官方文档（Learn）、curl 官方手册、GitHub 真实项目样例 |
| 版本兼容性 | 全部兼容（详见 §5） |

## 1. Java 21 + Spring Boot：`java -jar` 启动方式（官方）

### 1.1 可执行 JAR 启动（Spring Boot 官方文档 "Running a packaged application"）
- 官方唯一推荐启动方式：`java -jar target/myapplication-0.0.1-SNAPSHOT.jar`（Spring Boot 内嵌 Web 服务器，一条命令即可运行）。
- 启动成功标志：控制台输出 Spring Boot Banner 与 `Started <Application> in x.xxx seconds`；本任务可结合 JVM 参数 `-Xms256m -Xmx512m`（项目 deploy.md 5.6 节契约）与 `-jar <jar>` 拼接启动命令。

### 1.2 健康检查端点（官方 Actuator 与项目自定义对照）
- 官方默认：Spring Boot Actuator 健康端点路径为 `GET /actuator/health`（HTTP 暴露前缀 `/actuator`），返回整体健康状态（聚合全部 HealthIndicator）。
- **本项目差异（重要）**：项目各服务未采用 Actuator 默认端点，而是自定义 `HealthController`：
  - gateway：`GET http://localhost:9000/`（根路径响应即存活，无 /api/v1/gateway/health）；
  - auth：`GET http://localhost:9100/api/v1/auth/health`；
  - biz：`GET http://localhost:9200/api/v1/biz/health`；
  - system：`GET http://localhost:9400/api/v1/system/health`。
  - **必须直连各服务自身端口**（biz/system 的 health 不在网关白名单，经网关 9000 需 Token）。
- 健康确认判定标准：HTTP 探测返回任意响应（网关根路径 404/401 亦说明服务在运行）即为存活；端口探测（TCP 连通）作为备用方案。

## 2. PowerShell `Start-Process` 后台启动（微软官方文档）

### 2.1 核心参数（Windows PowerShell 5.1 与 7.x 均支持，本任务直接使用）
| 参数 | 说明 | 本任务用途 |
| --- | --- | --- |
| `-PassThru` | 返回 `System.Diagnostics.Process` 对象（默认无输出） | 获取启动进程句柄，供后续判活/记录 PID |
| `-RedirectStandardOutput <file>` | 将进程 stdout 重定向到文件 | 后台日志落盘（deploy/logs/{module}-start.log） |
| `-RedirectStandardError <file>` | 将进程 stderr 重定向到文件（须与 stdout 不同文件） | 错误日志落盘（deploy/logs/{module}-start.err） |
| `-ArgumentList <string[]>` | 参数数组，cmdlet 以单空格拼接传给新进程 | 传 `-Xms256m`,`-Xmx512m`,`-jar`,jar 路径 |
| `-WindowStyle Hidden` | 隐藏窗口启动 | 后台化、无窗口打扰 |
| `-NoNewWindow` | 在当前控制台窗口运行（**不能与 -WindowStyle 同用**） | 备选方案 |
| `-Wait` | 等待进程树退出（默认异步立即返回） | 本任务**不用**（需后台化） |

### 2.2 关键行为（官方 Notes）
- 默认**异步启动**：`Start-Process` 立即返回控制权，进程独立于调用进程存活 —— 正适合"启动后继续轮询健康"的编排需求。
- `-ArgumentList` 官方建议：含空格/引号的参数需转义双引号；`-ArgumentList` 数组元素之间由 cmdlet 自动加单空格拼接。**建议路径无空格时直接用数组元素传参**（本任务 jar 路径为 deploy 目录下固定文件名，无空格）。
- 新进程默认继承当前会话全部环境变量（load-env 注入的 NACOS_ADDR 等可被 java 子进程读取）。

### 2.3 真实样例（Azure-Samples/azure-spring-boot-samples，run_all.ps1）
```powershell
Start-Process java -ArgumentList '-jar', ('gateway/target/'+(Get-ChildItem gateway/target/*.jar -name)) -RedirectStandardOutput 'target/gateway.log' -NoNewWindow
```
> 与 TASK-004 已确立的 `Start-Process -FilePath "cmd.exe" -ArgumentList "/c", ... -RedirectStandardOutput $log -RedirectStandardError $err -PassThru` 模式同源；本任务用 `-FilePath "java"` 直启即可。

## 3. Linux `nohup` 后台启动与 PID 记录

### 3.1 标准模式（GNU coreutils nohup）
```bash
nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_DIR/module-start.log" 2>&1 &
echo $! > "$LOG_DIR/module.pid"   # $! 为最近后台进程 PID
```
- `nohup ... &`：忽略挂断信号后台运行，进程脱离终端生命周期；
- `> log 2>&1`：stdout/stderr 合并落盘（先 `mkdir -p` 日志目录）；
- `$!`：Bash 特殊变量，记录最近一次后台进程 PID，用于后续停止/判活。

### 3.2 真实样例（spring-petclinic-microservices，run_all.sh）
```bash
mkdir -p target
nohup java -jar spring-petclinic-config-server/target/*.jar --server.port=8888 --spring.profiles.active=chaos-monkey > target/config-server.log 2>&1 &
echo "Waiting for config server to start"
sleep 20
```
> 官方/社区通用做法：每服务 nohup 后台启动 + 日志落盘 + 等待/健康确认后再启动下一个 —— 与本任务 F-008"逐服务健康确认后再启动下一个"完全一致。

## 4. HTTP 探测轮询与超时处理

### 4.1 PowerShell 侧（Invoke-WebRequest，微软官方文档）
| 要点 | 说明 |
| --- | --- |
| `-TimeoutSec <sec>` | **Windows PowerShell 5.1 原生支持**（7.4+ 改名 `-ConnectionTimeoutSeconds`，`-TimeoutSec` 保留为别名）—— 本任务单次探测超时 3 秒用它 |
| 非 2xx 响应 | 抛**终止错误**，需 `try/catch` 或 `-ErrorAction SilentlyContinue` 吞掉再判定（404 说明服务在运行，也视为存活） |
| `-SkipHttpErrorCheck` | **仅 PowerShell 7.0+**，5.1 不支持 —— 本任务不得使用，统一 try/catch |
| `-MaximumRetryCount`/`-RetryIntervalSec` | 内置重试，但 5.1 语义有限 —— 本任务用自实现轮询循环（TASK-004 Wait-ServiceUp 模式）更可控 |

轮询模式（参照 TASK-004 `Wait-ServiceUp`，建议默认重试 30 次、间隔 2 秒、单次超时 3 秒）：
```powershell
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    try { Invoke-WebRequest -Uri $Url -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop | Out-Null; return $true }
    catch { Start-Sleep -Seconds 2 }
} while ((Get-Date) -lt $deadline)
return $false
```
> 注意：5.1 下 `Invoke-WebRequest` 对非 2xx 抛终止错误进 catch，捕获即代表"服务有响应"（含 404/401），可判存活。

### 4.2 Linux 侧（curl 官方手册）
| 参数 | 说明 |
| --- | --- |
| `-s, --silent` | 静默，禁用进度条 |
| `-S, --show-error` | 与 -s 同用时失败仍显示错误信息 |
| `-m, --max-time <seconds>` | 单次传输最大耗时（支持小数），防挂起 —— 本任务单次超时 3 秒 |
| `--connect-timeout <seconds>` | 仅限制连接阶段 |
| `--retry <num>` | 瞬态错误重试（超时、HTTP 408/429/5xx），默认 0 不重试 |
| `-f, --fail` | HTTP ≥400 返回码时以失败退出（结合 `--retry` 才重试 4xx/5xx） |
| 状态码判定 | curl 默认不因 HTTP 错误码失败（仅传输层错误），探测存活可用 `curl -s -m 3 http://localhost:9000/ >/dev/null && echo alive` |

轮询模式（参照 TASK-004 `wait_for_service` 与市场真实样例）：
```bash
for i in $(seq 1 $RETRY_COUNT); do
    if curl -s -m 3 "http://localhost:$port/health" > /dev/null 2>&1; then
        return 0
    fi
    sleep 2
done
return 1
```
> 真实样例：marketagents-ai/MarketAgents `check_api_health()` 使用 `for i in $(seq 1 $retries); do curl -s "http://localhost:$port/health" > /dev/null; ... sleep $wait_time`；Azure/aks-engine `retrycmd()` 使用 `for i in $(seq 1 $retries); do timeout $timeout ${@} && break || ...` —— 均为本任务可参照的成熟模式。

### 4.3 端口占用检测
- **Windows**（Get-NetTCPConnection，NetTCPIP 模块官方文档）：
  ```powershell
  Get-NetTCPConnection -LocalPort 9000 -State Listen -ErrorAction SilentlyContinue
  # 存在返回对象 => 端口被占用；配合 -OwningProcess 可查占用进程 PID
  ```
  > 也可用 TASK-003 `Test-TcpPort`（TcpClient BeginConnect + WaitOne）做连通性探测（备用健康确认）。
- **Linux**：`ss -ltn | grep :9000`（或 TASK-003 `/dev/tcp` + timeout 方案）。
- 失败提示示例（任务契约）："端口被占用，请检查 9000/9100/9200/9400"。

## 5. 版本兼容性核对结论

| 组件 | 项目当前版本 | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Java | OpenJDK 21.0.9 LTS（本地实测） | Spring Boot 3.x 官方要求 Java 17+（兼容至 21/25） | ✅ 完全兼容，`java -jar` 启动无版本问题 |
| Spring Boot | 3.2.5 | 官方 docs（3.x 主线） | ✅ 兼容；注意本项目健康端点为自定义 `/api/v1/{module}/health`，非 Actuator 默认路径 |
| Windows PowerShell | 5.1.19041（本地实测） | Microsoft Learn 7.x 文档 + 5.1 文档 | ✅ 兼容；**必须按 5.1 编写**：用 `-TimeoutSec`（勿用 7.4 新名）；**禁用** `-SkipHttpErrorCheck`（7.0+）、`-Environment`（7.4+）、`-UseNewEnvironment`（7.4+ 语义变更）；`Start-Process -PassThru/-RedirectStandardOutput/-RedirectStandardError/-WindowStyle/-ArgumentList` 5.1 全部支持 |
| Bash / nohup | Linux（发行版内置 GNU coreutils） | GNU coreutils 标准 | ✅ 兼容，`nohup ... &` + `$!` 为通用标准用法 |
| curl | Linux 内置（常见 7.x/8.x） | curl 官方手册 8.22.0 | ✅ 兼容，`-s/-m/--connect-timeout/--retry` 均为多年稳定选项 |
| 项目脚本体系 | v0.2.7（load-env / TASK-003/004 模式） | 本文档查询结果 | ✅ 可直接复用 TASK-004 `Start-Process` 后台化与 `Wait-ServiceUp`/`wait_for_service` 轮询模式 |

## 6. 编码要点汇总（供 code 直接使用）

1. **启动命令契约**：`java -Xms256m -Xmx512m -jar <deploy/xxx.jar>`（deploy.md 5.6 节），4 个 jar 名固定：cloudoffice-gateway.jar / cloudoffice-auth-service.jar / cloudoffice-biz-service.jar / cloudoffice-system-service.jar。
2. **Windows 后台启动**：`Start-Process -FilePath "java" -ArgumentList "-Xms256m","-Xmx512m","-jar",$JarPath -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru`（日志先 `New-Item -Force` 目录）。
3. **Linux 后台启动**：`nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_DIR/module-start.log" 2>&1 &`，紧接 `echo $!` 记录 PID。
4. **健康确认**（首选 HTTP 直连，端口探测备用）：gateway `GET http://localhost:9000/`（任意响应即存活）；auth/biz/system `GET http://localhost:{9100|9200|9400}/api/v1/{auth|biz|system}/health`；轮询默认重试 30 次、间隔 2 秒、单次超时 3 秒（可配置）。
5. **PowerShell 5.1 兼容**：`Invoke-WebRequest -TimeoutSec 3` 包 try/catch 判响应；禁用 7.x 专属参数。
6. **失败即停**：任一服务前置校验失败或健康确认超时 → 输出明确错误提示（端口占用提示检查 9000/9100/9200/9400；gateway 失败提示检查 NACOS_ADDR/RSA_PUBLIC_KEY）→ 停止后续启动 → exit 1。
7. **安全**：DB_PASSWORD、RSA 密钥仅校验非空，缺失只列键名，不得打印明文；输出分级 [通过]/[警告]/[失败]（F-011）。

## 7. 资料来源

| 来源 | 地址 |
| --- | --- |
| Spring Boot 官方文档：运行应用 / 系统需求 / Actuator | https://github.com/spring-projects/spring-boot（docs/antora，running-your-application、system-requirements、actuator/endpoints） |
| PowerShell Start-Process 官方文档 | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process |
| PowerShell Invoke-WebRequest 官方文档 | https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest |
| Get-NetTCPConnection 官方文档 | https://learn.microsoft.com/en-us/powershell/module/nettcpip/get-nettcpconnection |
| curl 官方手册 | https://curl.se/docs/manpage.html |
| 样例：PowerShell Start-Process java | https://github.com/Azure-Samples/azure-spring-boot-samples（run_all.ps1） |
| 样例：nohup java -jar 多服务顺序启动 | https://github.com/spring-petclinic/spring-petclinic-microservices（scripts/run_all.sh） |
| 样例：Shell 健康轮询 | https://github.com/marketagents-ai/MarketAgents（start_market_agents.sh）、https://github.com/Azure/aks-engine（parts/k8s/cloud-init/artifacts/cse_helpers.sh） |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
