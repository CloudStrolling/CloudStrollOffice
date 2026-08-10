# 网络查询结果（TASK-001 梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单）

## 0. 查询结论摘要

本任务为 v0.2.7「部署脚本体系重构与仓库清洁度治理」的先行梳理任务。WS 按任务需要查询了 PowerShell/Bash 脚本规范、MariaDB/Redis/Nacos 服务启动与健康检查方式、Java 21 JDK 环境变量检测、OpenSSL RSA 密钥（DER/PKCS#8/X.509）生成方式、.gitignore 规则编写最佳实践、Spring Boot 健康检查端点、后台启动 Java 服务等资料，并逐一核对了与项目当前版本（Java 21 / Spring Boot 3.2.5 / MariaDB 10.6 / Redis 7.2.x / Nacos 2.3 / PowerShell / OpenSSL / Git）的兼容性。查询结果与 cs.md 输出的 P1~P7 问题清单相互印证，可为 TASK-002/003/004/005/007 重构提供权威资料依据。

## 1. 项目技术栈与资料版本兼容性总表

| 组件 | 项目当前版本 | 查询资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| Java JDK | Java 21（项目要求） | OpenJDK 21（Red Hat 官方文档） | ✅ 兼容；Java 9+ 移除 tools.jar，检测须用 `$JAVA_HOME/bin/java`（或 java.exe），不得再用 tools.jar 判断（JEP 220） |
| Spring Boot | 3.2.5 | Spring Boot Actuator 3.x 官方文档 | ✅ 兼容；`/actuator/health` 返回 `{"status":"UP"}`；任一组件的 DOWN → HTTP 503；项目自定义 `/api/v1/{module}/health` 属业务健康端点，二者可并存，脚本探测以项目契约为准 |
| MariaDB | 10.6 | MariaDB 官方/社区文档（10.6+） | ✅ 兼容；`mysqladmin ping` 输出 `mysqld is alive`；systemd 服务名 `mariadb`/`mysqld`；`mysqld_safe` 适用传统启动 |
| Redis | 7.2.x | Redis 官方文档（redis-7-2-commands） | ✅ 兼容；`redis-cli PING` → `PONG`；`redis-server --daemonize yes` 后台启动；Redis 7.x 无内置 Windows 服务，Windows 部署需以进程/服务方式另行注册 |
| Nacos | 2.3 | Nacos 官方文档 + GitHub issue | ✅ 兼容（关键）；2.x 稳定健康检查接口为 **v1**：`/nacos/v1/console/health/liveness`（存活）、`/nacos/v1/console/health/readiness`（就绪，返回 200+`OK`）；**v2 接口在 2.x 部分版本 404**，v3 接口仅 3.x 提供——项目为 2.3 时脚本应使用 v1 接口（cs.md 提及现有脚本 HTTP 探测与 F-002~F-006 错位，建议以 v1 readiness 为准） |
| PowerShell | Windows 平台（5.1 / 7.x 并存） | Microsoft Learn（PS 7.6 / PSScriptAnalyzer） | ✅ 兼容（注意）；`param()` 必须为第一个可执行语句；外部命令退出码读 `$LASTEXITCODE`；`Get-Service`/`Start-Service` 仅 Windows 平台可用；PS 7.4+ 可用 `$PSNativeCommandUseErrorActionPreference`（旧版勿依赖） |
| Bash | Linux 平台 | Google Shell Style Guide / Libre DevOps / Greg's Wiki | ✅ 兼容；`set -Eeuo pipefail` 为推荐基线，但 `set -e` 有条件/管道/函数盲区，关键命令须显式检查退出码 |
| OpenSSL | Windows/Linux 均需 | OpenSSL 官方文档（3.x） | ✅ 兼容；`genpkey` + `pkcs8 -topk8 -nocrypt -outform DER`（私钥 PKCS#8）、`pkey -pubout -outform DER`（公钥 X.509），单行 Base64 用 `base64 -w0`（Linux）或 `[Convert]::ToBase64String`（Windows） |
| Git | 仓库当前版本 | git-scm.com/docs/gitignore（官方） | ✅ 兼容；模式规则见第 9 节，治理红线（不误伤已跟踪/模板文件）须严格遵循 |

## 2. PowerShell 脚本规范（官方文档要点）

来源：Microsoft Learn（PowerShell 7.6 / PSScriptAnalyzer 规则）、PowerShell Team 博客、PowerShell Tips。

1. **结构基线**：`param()` 块必须是脚本第一个可执行语句（在 Import-Module 等之前）；`[CmdletBinding()]` 启用通用参数（-Verbose/-WhatIf/-ErrorAction）。
2. **参数验证**：`[ValidateNotNullOrEmpty()]`、`[ValidateSet(...)]`、`[ValidateScript({...})]` 在脚本逻辑前拦截非法输入——对应 TASK-005 单服务脚本"所需变量清单校验"。
3. **严格模式**：`Set-StrictMode -Version Latest`；`$ErrorActionPreference = 'Stop'` 使错误转为终止错误，配合 try/catch/finally。
4. **退出码约定**（官方惯例）：0=成功；1=一般未捕获错误；2=配置/参数错误；3=依赖未找到。脚本结尾显式 `exit 0`；`throw` 产生退出码 1；`exit N` 精确控制进程退出码。→ 与 PRD F-011「全部通过 0 / 失败非零」方向一致，可细化"参数错误=2、依赖缺失=3"。
5. **输出通道**：PSScriptAnalyzer `AvoidUsingWriteHost` 规则——函数内输出应使用 `Write-Output`（进管道）或 `Write-Verbose`（日志）；`Write-Host` 仅用于纯展示（需 `Show` 动词）。脚本顶层对用户的"通过/警告/失败"分级输出可直接用 `Write-Host`（宿主展示），但对外契约输出用 `Write-Output`。
6. **外部程序退出码**：原生命令退出码存入 `$LASTEXITCODE`；PowerShell 7.4+ 可设 `$PSNativeCommandUseErrorActionPreference = $true` 使非零退出码成为错误（7.4 以下版本勿依赖）。
7. **Windows 服务管理**（对应 start-services 的 .ps1 侧）：
   - `Get-Service -Name <svc>` 查看状态（Status 属性：Running/Stopped）；
   - `Start-Service -Name <svc>` 启动（服务已运行时忽略不报错）；需管理员权限；
   - `sc.exe query <svc>` / `sc.exe start <svc>` 为底层命令行等价物；
   - 启动类型 Disabled 时 `Start-Service` 失败，可用 `Get-CimInstance Win32_Service` 查 StartMode。
8. **后台启动**（对应 F-008 一键启动）：`Start-Process -FilePath java -ArgumentList '-jar', '<jar>' -RedirectStandardOutput <log> -RedirectStandardError <err.log>`；需要脱离父窗口持续运行可配合 `-WindowStyle Hidden`（Windows 上真正脱离会话需任务计划/服务化，脚本内以独立进程 + 日志重定向为准）。

## 3. Bash 脚本规范（官方/权威资料要点）

来源：Google Shell Style Guide、Libre DevOps Bash Standards、Greg's Wiki（BashFAQ/105）、SIPB Safe Shell、ShellCheck。

1. **shebang 与严格模式**：`#!/usr/bin/env bash` + `set -Eeuo pipefail`（-E errtrace / -e errexit / -u nounset / -o pipefail）。
2. **set -e 的盲区**（必须显式处理）：条件（if/&&/||/!）、管道非末段（pipefail 缓解）、函数在条件上下文调用时整体失去 errexit。结论：`set -e` 是安全网而非策略，关键命令失败须显式 `cmd || { log_error "..."; exit 1; }`。
3. **local 掩盖退出码**：`local x="$(cmd)"` 恒成功，`$?` 被吞；应「先声明后赋值」：`local x; x="$(cmd)" || handle`。
4. **清理陷阱**：创建临时文件/后台进程的脚本须 `trap cleanup EXIT INT TERM`，处理函数内先捕获 `$?` 以保留原始退出码。
5. **退出码约定**：0=成功；2=用法/参数错误（镜像标准 CLI）；127=命令未找到；128+N=信号终止。不要结尾盲目 `exit 0`（会掩盖最终命令失败）。
6. **eval 风险**（对应 cs.md P5 中 `.sh` 用 `eval "$cmd"` 的问题）：eval 执行字符串存在注入与引号风险（如 `-p'$DB_PASSWORD'`），应改写为直接命令 + 数组参数（`cmd=(mysqladmin ping -h "$host" ...); "${cmd[@]}"`），避免字符串拼接传参。
7. **检测工具**：ShellCheck 定期静态检查（官网 https://www.shellcheck.net/）。
8. **JDK 检测**（对应 F-002）：`[[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]` 优先，回退 `type -p java`，均失败时报错退出 1；Java 9+ 不得依赖 tools.jar。

## 4. MariaDB 10.6 启动与健康检查

来源：MariaDB 官方文档（runebook Healthcheck.sh 篇）、Linux 部署资料、阿里云 MySQL 运维资料。

1. **启动方式**（按优先级，.sh 侧）：
   - systemd：`sudo systemctl start mariadb`（服务名 mariadb 或 mysqld）；`systemctl is-active --quiet mariadb` 检查；
   - SysV/传统：`/etc/init.d/mysql start` 或 `service mysql start`；
   - 无服务管理器（源码/免安装）：`nohup mysqld_safe --defaults-file=<my.cnf> &`（mysqld_safe 会拉起并监控 mysqld）。
2. **健康检查**：
   - `mysqladmin ping -h <host> -P <port> [-u root -p<pwd>]` → 输出 `mysqld is alive`，退出码 0；
   - `mysql -u <user> -p<pwd> -e "SELECT VERSION();" -sN` → 端到端验证（连接+认证+查询），更全面；
   - 进程检查：`pgrep mysqld` / `pgrep mariadbd`；端口检查：`ss -tulpn | grep 3306`。
3. **排错要点**：`journalctl -u mariadb -xe`、数据目录权限（chown mysql:mysql）、端口冲突。
4. **Windows 侧**：以 Windows 服务名（如 `MariaDB`）为准，`Get-Service`/`sc.exe query` 检查、`Start-Service` 启动；服务启动成功后同样以 `mysqladmin ping` 确认。

## 5. Redis 7.2 启动与健康检查

来源：Redis 官方文档（redis-7-2-commands / PING）。

1. **健康检查**：`redis-cli -h <host> -p <port> [-a <password>] PING` → 返回 `PONG` 即存活（注意 `-a` 明文口令，脚本中建议用 `REDISCLI_AUTH` 环境变量代替命令行参数，避免进程列表泄露）。
2. **启动方式（Linux）**：`redis-server /path/to/redis.conf --daemonize yes`（后台）；systemd 服务名 `redis` 或 `redis-server`。
3. **Windows 侧**：Redis 官方不支持 Windows 原生服务，Windows 部署通常以进程方式（redis-server.exe）或第三方服务包装启动；脚本检测以端口（6379）+ PING 为准更稳妥，服务名检测仅作辅助。
4. **确认口径**：端口监听 + `PING→PONG` 双确认（对应 F-004 运行状态检查）。

## 6. Nacos 2.3 启动与健康检查（版本兼容性关键）

来源：Nacos 官方监控手册、GitHub issue（#13820、#13437、#3959）。

1. **健康检查接口（2.x 用 v1，勿用 v2/v3）**：
   - 存活：`GET /nacos/v1/console/health/liveness`
   - 就绪：`GET /nacos/v1/console/health/readiness` → 就绪时 HTTP 200 且响应文本 `OK`
   - 说明：v2 接口（/nacos/v2/console/health/...）在 2.x 部分版本返回 404；v3 接口仅 3.x 提供。项目为 Nacos 2.3，脚本统一使用 **v1** 接口，`curl -sf http://<addr>/nacos/v1/console/health/readiness` 判定。
2. **启动方式**：进入 `$NACOS_HOME/bin`，Linux 用 `sh startup.sh -m standalone`，Windows 用 `startup.cmd`；启动后轮询 readiness 直到 200（参考现有脚本 8 秒固定等待 → 建议改为循环探测 + 超时上限）。
3. **端口**：默认 8848（8849 偏移可由配置变更，脚本应从 env.json 读取 NACOS_ADDR）。
4. **注意**：Nacos 依赖 MySQL/内嵌 Derby 作为存储，启动成功 ≠ 就绪，readiness 返回非 200 时仍应判失败（对应 cs.md P4 中"可用性检查误放连通性检查"的修正方向）。

## 7. Java 21 JDK 环境变量检测

来源：Red Hat OpenJDK 21 文档、Apache Cordova PR#1406、Gradle 脚本惯例。

1. **检测顺序（推荐）**：
   1) `$JAVA_HOME` 已设置且 `$JAVA_HOME/bin/java`（Windows 为 `bin\java.exe`）存在且可执行；
   2) 否则 `type -p java` / `Get-Command java` 在 PATH 中；
   3) 均失败：报错「JAVA_HOME 未设置且 PATH 中无 java」退出非零。
2. **版本确认**：`java -version` 解析主版本号（如 `openjdk version "21.0.x"`），可与项目要求的 Java 21 比对（可选，F-002 建议输出 JDK 版本结论）。
3. **Java 9+ 注意**：JEP 220 移除 `tools.jar`，不得以 `lib/tools.jar` 是否存在判断 JDK 安装（旧脚本通病，需在重构中规避）。
4. **PowerShell 侧**：`$env:JAVA_HOME` 读取、`Test-Path "$env:JAVA_HOME\bin\java.exe"` 判断、`java -version 2>&1` 取版本。

## 8. OpenSSL 生成 RSA 密钥（DER 编码契约，ADR-015 落地依据）

来源：OpenSSL 官方文档（openssl-genpkey / openssl-pkcs8 / openssl-pkey）、PKCS#8 DER 生成样例。

1. **权威命令链（与 .ps1 v0.2.6 已对齐流程一致，.sh 应按此对齐）**：
   - 生成私钥（PEM 临时审计副本）：`openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out private.pem`
   - 私钥转 PKCS#8 DER：`openssl pkcs8 -topk8 -nocrypt -in private.pem -outform DER -out private.der`（显式 PKCS#8，避免 PKCS#1 造成 Java `algid parse error`）
   - 公钥转 X.509（SubjectPublicKeyInfo）DER：`openssl pkey -in private.pem -pubout -outform DER -out public.der`
   - 单行 Base64：Linux `base64 -w0 private.der`；Windows `[Convert]::ToBase64String([IO.File]::ReadAllBytes(...))`
2. **Java 端解码契约（必须严格一致）**：`Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/ `PKCS8EncodedKeySpec`（私钥）。
3. **自校验建议**（.ps1 已有，.sh 需对齐）：
   - 无 PEM 头尾（首字符不得为 `-`）、无换行；
   - Base64 严格解码可逆；
   - DER 结构偏移校验：私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`；
   - 输出脱敏：仅打印前 24 字符（避免完整私钥入日志，对应 NFR-004）。

## 9. .gitignore 规则编写最佳实践（Git 官方文档）

来源：git-scm.com/docs/gitignore、GitHub docs（Ignoring files）、GitHub gitignore 模板库。

1. **模式规则要点**：
   - 空行=分隔；`#` 注释；`!` 取反（不能重新包含已被排除的目录内的文件——父目录排除后内部模式无效）；
   - 结尾 `/` 仅匹配目录；`/` 开头或中间出现→相对 .gitignore 所在层级；否则可匹配任意层级；
   - `*` 不匹配 `/`；`**` 特殊含义（`**/foo`、`abc/**`、`a/**/b`）；
   - 尾随空格被忽略（可用 `\ ` 转义）。
2. **层级优先级**：命令行 > 就近 .gitignore > $GIT_COMMON_DIR/info/exclude > core.excludesFile；就近目录的 .gitignore 可覆盖父级。
3. **已跟踪文件不受影响**：需 `git rm --cached <path>` 后再加入规则（治理红线：TASK-007 若需停跟既有文件必须用此命令）。
4. **全局排除**：`~/.config/git/ignore`（用户级，不提交）。
5. **官方模板**：github/gitignore 仓库按语言/平台提供模板，可作新增分区参考。
6. **对 F-012 的建议**：新增规则带路径前缀或精确模式（避免误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml、*.java、*.dart、*.md）；建议补充：`*.hprof`、`hs_err_pid*.log`、`*.dump`、`heapdump.*`、`dump/`、`*.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated`、`**/surefire-reports/`、`**/test-results/`、`*.history`、`*.session`、API 调试产物（`*.har` 等需评估）。

## 10. Spring Boot 健康检查端点与后台启动（服务级健康确认）

来源：Spring Boot Actuator 官方文档、SAE/腾讯云实践。

1. **Actuator 标准端点**：`GET /actuator/health` → `{"status":"UP"}`；任一组件 DOWN → HTTP 503；`/actuator/health/liveness|readiness` 探针需 `management.endpoint.health.probes.enabled=true`。
2. **项目现状**：各服务提供 `/api/v1/{module}/health` 自定义健康端点（SAD 部署架构），脚本按此契约探测；Spring Boot 3.2.5 自带 Actuator 端点可作补充（无需改代码，仅作信息参考）。
3. **健康轮询模式（F-008 一键启动复用）**：`nohup java -jar <jar> > <log> 2>&1 &`（Linux）→ 循环 `curl -sf <health_url>` 直到 200 或超时（如 60s），超时判启动失败退出非零（对应"失败即停"R-09）。
4. **PowerShell 侧**：`Start-Process -FilePath java -ArgumentList '-jar','<jar>' -RedirectStandardOutput <log> -RedirectStandardError <err>` + 循环 `Invoke-RestMethod`/`Test-NetConnection` 探测健康端点。

## 11. 对 TASK-001 问题清单与下游重构任务的支撑结论

| cs.md 问题 | 权威资料支撑 | 对下游任务的落地建议 |
| --- | --- | --- |
| P1 硬编码默认地址（192.168.1.x） | 配置驱动原则（SAD G-A7 / R-01）；PowerShell param 校验、Bash `-u` 未定义变量报错 | TASK-002/005 删除硬编码，全部经 load-env 从 env.json 读取；缺失关键配置显式报错退出（参数错误退出码 2） |
| P2 弃用脚本残留（deploy-env*） | Git 跟踪确认（cs.md 1.3） | 按 ADR-016 移除并同步修正 deploy.md 目录树（P7 附加发现） |
| P3 RSA 密钥输出契约不一致（.sh 对 PEM 整体 Base64） | OpenSSL 官方命令链（第 8 节）：必须 `pkcs8 -topk8 -nocrypt -outform DER` + `pkey -pubout -outform DER` + 单行 Base64 | TASK-007（或 F-011 对应任务）按第 8 节对齐 .sh，含自校验与脱敏 |
| P4 可用性/运行状态检查能力分散 | MariaDB/Redis/Nacos 检查方式（第 4~6 节）；Nacos 2.x 用 v1 readiness | TASK-002/003 对齐 F-002~F-006：可用性检查与运行状态检查分离，Nacos 探测统一 v1 readiness |
| P5 输出格式与退出码不统一 | PowerShell 退出码惯例（0/1/2/3）、Bash 退出码惯例（0/2/127/128+N） | 统一"通过/警告/失败"分级与退出码：全部通过 0 / 失败非零（参数错误 2 / 依赖缺失 3 可选细化）；.ps1 用 Write-Host 分级展示 + 显式 exit；.sh 用 printf + 显式 exit |
| P6 缺少一键启动总入口 | nohup + health 轮询模式（第 10 节）；部署顺序契约 gateway→auth→biz→system | TASK-004 新增 deploy-start-all，逐服务后台启动 + 健康轮询确认，失败即停 |
| 附加（P10~P12、P17~P18） | Start-Process 后台化、JDK 检测（第 7 节）、DB_URL 显示 | TASK-005 单服务脚本统一变量校验清单与后台启动；TASK-002/005 清理显示层不一致与死代码 |
| .gitignore 缺口 | Git 官方模式规则（第 9 节） | TASK-007 按第 9.6 节清单补充规则，遵守"不误伤模板/已跟踪文件"红线 |

## 12. 参考链接汇总

- PowerShell：Microsoft Learn（about_Error_Handling / Get-Service / Start-Service / Validating Parameter Input）、PSScriptAnalyzer（AvoidUsingWriteHost）、PowerShell Team（Exit Codes）
- Bash：Google Shell Style Guide、Libre DevOps Bash Standards、Greg's Wiki BashFAQ/105、SIPB Safe Shell、ShellCheck
- MariaDB：MariaDB 官方 Healthcheck.sh 说明、Linux 服务管理资料
- Redis：Redis 官方命令文档（PING / redis-7-2-commands）
- Nacos：nacos.io 监控手册、GitHub issue #13820 / #13437 / #3959
- JDK：Red Hat OpenJDK 21 配置文档、Apache Cordova PR#1406（JEP 220）
- OpenSSL：docs.openssl.org（genpkey / pkcs8 / pkey）、PKCS#8 DER 生成样例
- Git：git-scm.com/docs/gitignore、GitHub Docs（Ignoring files）、github/gitignore 模板库
- Spring Boot：docs.spring.io Actuator Health 官方文档

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
