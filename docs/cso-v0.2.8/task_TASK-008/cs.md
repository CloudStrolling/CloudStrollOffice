# TASK-008 现有代码查询（cs.md）

## 1. 现有部署脚本体系（deploy/scripts/，v0.2.7 约定）
全部脚本遵循统一约定：
- 经 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 统一加载环境变量（dot-source / source 方式调用）。
- 输出分级：通过/警告/失败，双平台一致不用 emoji；退出码约定失败非零。
- 安全约定：口令/密钥不打印明文。
- `$ProjectDir = Split-Path -Parent $PSScriptRoot`（.ps1）/ `PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`（.sh），日志与 PID 落位 `deploy/logs/{name}.pid`。

## 2. deploy-stop-all.ps1 / .sh（TASK-008 直接修改对象）
- **服务清单**：`$Services`（ps1）/ `SERVICES`（sh）目前为 4 项：system(9400)、biz(9200)、auth(9100)、gateway(9000)，字段：Name/Jar/Port（sh 用 `name|jar|port` 竖线分隔数组）。
- **停止顺序**：system → biz → auth → gateway（与启动相反）。TASK-008 需在其末尾追加 common（9300）。
- **停止逻辑（.ps1）**：
  - 优先读取 `deploy/logs/{name}.pid`，校验进程命令行含 jar 名后 `Stop-Process`；
  - 轮询等待退出（`Wait-ProcessGone`，默认超时 30s/间隔 2s，可配置 `-StopTimeout`/`-RetryInterval`），超时强制停止；
  - PID 文件缺失或进程不存在 → "未在运行（PID 文件/进程均未命中），幂等跳过"（通过）；
  - 回退定位 `Find-JavaPidByJar`（Get-CimInstance java.exe 命令行含 jar 名）。
- **停止逻辑（.sh）**：同语义，pgrep -f jar 名，kill SIGTERM → wait_for_proc_gone → kill -9 强杀。
- **Nacos 停止**：HTTP 探测 `http://$env:NACOS_ADDR/nacos/` 或 java 进程含 nacos 判断运行，shutdown.cmd/shutdown.sh 停止，失败回退强杀；不停止 Redis/MySQL/MariaDB。
- **汇总**：服务结果存 `$script:serviceResults`（.ps1）/ `SERVICE_RESULTS`（.sh），结尾逐服务输出停止结果与 Nacos 状态，全部通过退出 0、存在失败退出 1。

## 3. 单服务启动脚本模式（deploy-start-auth.ps1 / .sh，deploy-stop-common 参考模板）
- 标题块（SYNOPSIS/DESCRIPTION/版本/示例）。
- 前置校验：JDK 可用 + jar 包存在 + 本服务关键环境变量（缺失只列键名，不打印值）。
- 后台启动：`java -Xms256m -Xmx512m -jar <jar>`，日志 `deploy/logs/{name}-start.log`、PID `deploy/logs/{name}.pid`。
- 健康确认：HTTP 直连自身端口（auth 为 http://localhost:9100/api/v1/auth/health），TCP 端口探测备用。
- 服务契约块：`$ServiceName`/`$JarName`/`$ServicePort`/`$HealthUrl`/`$RequiredVars`/`$MissingHint`（.ps1）；`SERVICE_NAME`/`JAR_NAME`/`SERVICE_PORT`/`HEALTH_URL`/`REQUIRED_VARS`/`MISSING_HINT`（.sh）。

## 4. cloudoffice-common 服务信息（TASK-002/003 已完成）
- 服务名：cloudoffice-common；jar：`cloudoffice-common.jar`；端口：9300；健康检查端点：`/api/v1/common/health`。
- 部署产物已由 TASK-006（build-backend 更新）纳入，deploy 目录存在 `cloudoffice-common.jar`。

## 5. 相关环境变量
- `NACOS_ADDR`（Nacos 地址，load-env 关键配置兜底校验）。
- `COMMON_PORT`（common 端口，TASK-009 新增，本任务脚本端口按现有脚本惯例可先硬编码 9300，也可引用 COMMON_PORT；参考现有 4 个服务端口在停止脚本中均为硬编码常量）。

## 6. 本任务需新增/修改的文件
- `deploy/scripts/deploy-stop-all.ps1`（服务清单追加 common 居末 + 汇总含 common）
- `deploy/scripts/deploy-stop-all.sh`（同上，Bash）
- `deploy/scripts/deploy-stop-common.ps1`（单服务停止脚本，新建）
- `deploy/scripts/deploy-stop-common.sh`（单服务停止脚本，新建）
