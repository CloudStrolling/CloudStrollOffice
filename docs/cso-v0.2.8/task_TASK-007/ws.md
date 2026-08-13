# TASK-007 网络资料查询（ws.md）

## 一、任务三方依赖评估
本任务为**部署运维脚本更新**（PowerShell 5.1 .ps1 与 Bash .sh 双平台），纯脚本实现，**不引入任何第三方包/SDK/中间件**，无需查询三方包文档。

## 二、使用的技术要点（均为脚本内既有能力，无新增依赖）
1. **PowerShell 5.1（Windows）**：
   - `Start-Process` 后台启动 java（-WindowStyle Hidden 隐藏窗口、-RedirectStandardOutput/-RedirectStandardError 日志重定向、-PassThru 获取进程句柄记录 PID）
   - `Invoke-WebRequest -UseBasicParsing` HTTP 存活探测（任意响应含 404/401/500 即认为服务在运行）
   - `System.Net.Sockets.TcpClient.BeginConnect/EndConnect` TCP 端口探测
   - `Get-CimInstance Win32_Process` 按命令行定位 java 进程（deploy-stop 用）
   - `Get-Item Env:<key>` 环境变量读取（空值判断仅列键名不打印值）
2. **Bash（Linux）**：
   - `nohup java -jar ... &` + `echo $! > pid` 后台启动并记录 PID
   - `curl -s -m <timeout> -o /dev/null <url>` HTTP 存活探测
   - `timeout 1 bash -c "cat < /dev/null > /dev/tcp/<host>/<port>"` TCP 端口探测
   - `pgrep -f` 进程定位
   - `set -euo pipefail` 严格模式（source load-env.sh 除外）
3. **env 变量注入**：COMMON_PORT 通过 `deploy/env.json` 经 load-env 统一加载注入环境变量，common 应用 `server.port=${COMMON_PORT:9300}` 读取；脚本内做缺省兜底（9300）。

## 三、版本兼容性核对
- 现有脚本均基于 v0.2.7 脚本体系契约（load-env 统一加载、输出分级通过/警告/失败、退出码失败非零、双平台行为一致），本任务在其上扩展 common 条目，无版本兼容风险。
- Java 21 启动参数 `-Xms256m -Xmx512m -jar` 为全项目既有约定，保持不变。
- 健康检查端点 `GET /api/v1/common/health`（TASK-003 已实现）为本任务健康确认依据。

## 四、相关业务方案/排错要点
1. **失败即停（fail-fast）策略**：任一步骤失败立即 break 并退出非零，不启动后续服务；前置校验失败时完全不启动任何服务。
2. **健康确认不报假成功**：HTTP 探测优先（服务返回任一 HTTP 响应视为存活）、TCP 端口探测备用，仅在两者均无响应时才判定失败。
3. **幂等跳过**：已运行服务（如 Nacos）不重复启动；停止脚本对不存在进程幂等通过。
4. **端口占用排错**：提示检查 9000/9100/9200/9400/9300，使用 netstat -ano（Windows）/ ss -ltnp（Linux）定位。
5. **安全约定**：口令/密钥不打印明文，缺失校验只列键名。

## 五、结论
无外部资料依赖，直接沿用项目既有脚本体系契约与模板（deploy-start-gateway 单服务脚本 + deploy-start-all 一键启动脚本）即可完成本任务。
