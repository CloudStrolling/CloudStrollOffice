# 代码查询报告（#TASK-006 重构单服务启动脚本 deploy-start-gateway/auth/biz/system）

## 1. 任务信息与查询范围

- **任务**：重构 `deploy/scripts` 下 8 个单服务脚本（deploy-start-gateway/auth/biz/system 的 .ps1/.sh），对齐 TASK-005 产物 deploy-start-all 的行为；同时排查 .gitignore 对临时/中间文件的覆盖（用户输入需求 3）。
- **查询对象**：
  1. 8 个待重构单服务脚本完整源码（重点：校验逻辑、启动命令、前台/后台行为、输出与退出码、biz 用 DB_USER vs auth 用 DB_USERNAME 差异）；
  2. TASK-005 新增 deploy-start-all.ps1/.sh 中对应服务启动逻辑（行为对齐基准）；
  3. load-env.ps1/.sh 调用契约；
  4. 4 个 jar 实际文件名（deploy 目录落位确认）；
  5. env.example.json 键名结构（只查键名不碰真实值）；
  6. .gitignore 现状与 git 追踪状态（516 个已追踪文件扫描）。

## 2. 8 个待重构单服务脚本现状（已读全部源码，逐文件要点）

| 脚本 | 行数 | 校验变量 | 启动方式 | SPDX 头 | 输出风格 | 退出码 |
| --- | --- | --- | --- | --- | --- | --- |
| deploy-start-gateway.ps1 | 52 | NACOS_ADDR + RSA_PUBLIC_KEY + jar 存在 | **前台** `java -Xms256m -Xmx512m -jar` | 无 | ❌ 红色 emoji，无分级 | 校验失败 exit 1 |
| deploy-start-gateway.sh | 61 | NACOS_ADDR + RSA_PUBLIC_KEY + jar 存在 | **前台** `exec java`（替换进程） | 无（头注 v0.1.7 旧版） | ❌ 风格 | 校验失败 exit 1 |
| deploy-start-auth.ps1 | 59 | **9 个变量**：NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY + jar | 前台 java | 无 | ❌ 风格 | exit 1 |
| deploy-start-auth.sh | 75 | 同上 9 个变量 + jar | 前台 exec java | 无（v0.1.7） | ❌ 风格 | exit 1 |
| deploy-start-biz.ps1 | 43 | **仅 NACOS_ADDR** + jar（缺 DB_PASSWORD，与 .sh 不一致） | 前台 java | 无 | ❌ 风格 | exit 1 |
| deploy-start-biz.sh | 60 | NACOS_ADDR + DB_PASSWORD + jar（注释：biz 用 DB_USER） | 前台 exec java | 无（v0.1.7） | ❌ 风格 | exit 1 |
| deploy-start-system.ps1 | 43 | **仅 NACOS_ADDR** + jar（缺 DB_PASSWORD） | 前台 java | 无 | ❌ 风格 | exit 1 |
| deploy-start-system.sh | 58 | NACOS_ADDR + DB_PASSWORD + jar | 前台 exec java | 无（v0.1.7） | ❌ 风格 | exit 1 |

### 共性现状问题（与 context.md 5.2 一致，源码核实）
- 全部 8 个脚本**前台阻塞启动**：.ps1 直接运行 java 阻塞脚本；.sh 用 `exec java` 替换 shell 进程。无后台化、无 PID 记录、无日志落盘、无健康确认。
- **双平台校验不一致**：biz/system 的 .ps1 只校验 NACOS_ADDR（缺 DB_PASSWORD），.sh 校验 NACOS_ADDR+DB_PASSWORD；auth 双平台都校验 9 个变量（超出 F-009 契约：应只需 NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD）。
- 输出用 ❌/emoji 红色风格，无「通过/警告/失败」分级与计数。
- 无 SPDX 头；.sh 头部版本仍为 v0.1.7；注释引用已弃用脚本 `deploy-env-local.ps1/.sh`（gateway.sh 第 6 行、auth.sh 第 6 行、biz.sh 第 6 行、system.sh 第 6 行，以及各 .ps1 的 .DESCRIPTION 第 6 行）。
- 启动命令统一为 `java -Xms256m -Xmx512m -jar <jar>`（双平台、4 服务一致，可复用）。
- jar 路径计算统一：.ps1 `$ProjectDir = Split-Path -Parent $PSScriptRoot; $JarPath = Join-Path $ProjectDir "<jar名>"`；.sh `SCRIPT_DIR/PROJECT_DIR/JAR_PATH` 三段式。

## 3. 行为对齐基准：deploy-start-all.ps1/.sh（TASK-005 产物，已读全源码）

### 3.1 可复用函数清单（重构单服务脚本可直接提取使用）

**PowerShell（deploy-start-all.ps1）**：
| 函数 | 位置 | 作用 |
| --- | --- | --- |
| `Write-Result` | 45-52 行 | 输出「通过/警告/失败」三级（绿/黄/红，无 emoji）+ 全局计数 $script:pass/warn/fail |
| `Test-TcpPort` | 55-68 行 | TCP 端口探测（TcpClient 异步 + WaitOne 超时），健康确认备用 |
| `Test-HttpOk` | 71-80 行 | HTTP 存活探测（任一 HTTP 响应含 404/401/500 即认为启动） |
| `Wait-HealthUp` | 83-91 行 | 健康轮询：重试次数/间隔/单次超时可配置（默认 30 次/2 秒/3 秒），HTTP 优先、TCP 备用 |

**Bash（deploy-start-all.sh）**：
| 函数 | 位置 | 作用 |
| --- | --- | --- |
| `print_result` | 48-55 行 | 三级输出 + PASS/WARN/FAIL 计数（颜色码 GREEN/YELLOW/RED/NC，48-55 行前 44-45 行定义） |
| `has_cmd` | 58 行 | 命令存在性检查 |
| `tcp_port_open` | 61-73 行 | /dev/tcp 端口探测（timeout 防挂起） |
| `http_ok` | 77-80 行 | curl 探测（-s -m timeout，HTTP 错误码不失败） |
| `wait_health_up` | 83-91 行 | 健康轮询（RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT，默认 30/2/3） |

### 3.2 单服务启动逻辑（重构时必须对齐的 7 个要点，按 start-all 实测源码）
1. **加载配置**：`.ps1`：`$ProjectDir = Split-Path -Parent $PSScriptRoot` 后 `. "$PSScriptRoot\load-env.ps1"`（第 35-36 行）；`.sh`：`source "$SCRIPT_DIR/load-env.sh" || exit $?`（第 38 行）。env.json 缺失/关键配置缺失由 load-env 兜底退出。
2. **前置校验**：java 命令可用（ps1 第 136 行 `Get-Command java`；sh 第 116 行 `has_cmd java`）→ jar 存在（ps1 第 146 行 `Test-Path -LiteralPath`；sh 第 126 行 `[ -f "$PROJECT_DIR/$jar" ]`）→ 关键环境变量非空（ps1 第 150-156 行逐项；sh 第 131-136 行逐项，`${!v:-}` 间接引用），缺失只列键名不打印值。
3. **后台启动**：Windows：`Start-Process -FilePath "java" -ArgumentList "-Xms256m","-Xmx512m","-jar",$jarPath -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $errFile -PassThru`（第 181 行），`$proc.Id | Out-File -Encoding ascii $pidFile`（第 182 行）；Linux：`nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_FILE" 2>&1 &`（第 160 行）+ `echo $! > "$PID_FILE"`（第 161 行）。
4. **日志/PID 落位**：`deploy/logs/{module}-start.log`（.ps1 另有 `-start.err`，.sh 合并到 log）、`deploy/logs/{module}.pid`；logDir 先 `New-Item -Force`（ps1 第 169-170 行）/`mkdir -p`（sh 第 150 行）。
5. **健康确认**：HTTP 优先（gateway `http://localhost:9000/`、auth/biz/system `http://localhost:{port}/api/v1/{module}/health`），TCP 端口备用；轮询默认 30 次/间隔 2 秒/单次 3 秒。
6. **输出分级**：前置校验与启动结果均用 Write-Result/print_result；标题含版本 v0.2.7（ps1 第 122-129 行、sh 第 102-109 行）；文件头 SPDX（ps1 第 1 行、sh 第 2 行）。
7. **退出码**：前置校验任一失败 → exit 1 且不启动任何服务（ps1 第 159-164 行、sh 第 139-144 行）；启动/健康确认失败 → 记录结果 + break + 最终 exit 1（ps1 第 213-216 行、sh 第 190-192 行）；全部通过 exit 0。

### 3.3 服务契约表（start-all 中定义；单服务脚本按各自服务取对应行）
| 服务 | jar 文件名（deploy 目录已落位确认） | 端口 | 健康 URL | 关键变量（RequiredVars） | 失败排查提示 Hint |
| --- | --- | --- | --- | --- | --- |
| gateway | cloudoffice-gateway.jar | 9000 | http://localhost:9000/ | NACOS_ADDR, RSA_PUBLIC_KEY | 请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置 |
| auth | cloudoffice-auth-service.jar | 9100 | http://localhost:9100/api/v1/auth/health | NACOS_ADDR, RSA_PUBLIC_KEY, RSA_PRIVATE_KEY, DB_PASSWORD | 请检查 RSA 密钥对/DB_PASSWORD 配置 |
| biz | cloudoffice-biz-service.jar | 9200 | http://localhost:9200/api/v1/biz/health | NACOS_ADDR, DB_PASSWORD | 请检查 DB_PASSWORD 配置 |
| system | cloudoffice-system-service.jar | 9400 | http://localhost:9400/api/v1/system/health | NACOS_ADDR, DB_PASSWORD | 请检查 DB_PASSWORD 配置 |

> 注意：契约表中 auth 关键变量为 **DB_PASSWORD**（start-all 第 105 行），但 env.json 中 auth 数据库用户名键为 **DB_USERNAME**（现状脚本用 DB_USERNAME 校验）；biz/system 的 .sh 现状注释说明 biz 用 **DB_USER**。F-009 业务规则要求"biz 使用 DB_USER、auth 使用 DB_USERNAME 的差异保持现状一致"，但 start-all 契约表的 RequiredVars 只有 DB_PASSWORD 无 DB_USERNAME/DB_USER——单服务脚本校验变量以 context.md 5.3 契约表 + F-009 原文为准（gateway/auth：NACOS_ADDR、RSA_PUBLIC_KEY，auth 另需 RSA_PRIVATE_KEY；biz/system：NACOS_ADDR、DB_PASSWORD）。

## 4. load-env 调用契约（TASK-002 产物，已读源码核实）

- **PowerShell**（load-env.ps1 第 24-25 行）：`$ProjectDir = Split-Path -Parent $PSScriptRoot`；`$EnvFilePath = Join-Path $ProjectDir "env.json"`。调用方式 dot-source：`. "$PSScriptRoot\load-env.ps1"`；env.json 缺失/JSON 解析失败/8 项关键配置缺失（NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT，第 48-57 行）均 `exit 1`，缺失逐项列键名不打印值。
- **Bash**（load-env.sh 第 23-26 行）：`ENV_FILE="${1:-env.json}"`；依赖 jq 或 python3 解析（第 37-63 行）；source 型脚本失败用 `return 1` 不 exit，**调用方必须 `|| exit $?`**；8 项关键配置校验同 ps1（第 68-82 行）。
- 加载成功输出：ps1 第 74 行 `Write-Host "环境变量已从 ... 共 N 项" -ForegroundColor Green`；sh 第 65 行 `echo "环境变量已从 ... 加载 (jq/python3)，共 N 项"`。

## 5. jar 文件名与 env.json 键名确认（只查键名不碰值）

### 5.1 4 个 jar 实际文件名（deploy 根目录，glob 实测全部存在）
- `deploy/cloudoffice-gateway.jar` ✅
- `deploy/cloudoffice-auth-service.jar` ✅
- `deploy/cloudoffice-biz-service.jar` ✅
- `deploy/cloudoffice-system-service.jar` ✅

### 5.2 env.example.json 键名结构（27 个键，安全只列名）
NACOS_ADDR、NACOS_HOME、DB_SERVICE_NAME、DB_PROCESS_NAME、REDIS_SERVICE_NAME、REDIS_PROCESS_NAME、DB_HOST、DB_PORT、**DB_USERNAME**、DB_PASSWORD、**DB_USER**（与 DB_USERNAME 并存，印证 biz 用 DB_USER / auth 用 DB_USERNAME 差异）、REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY、VERIFICATION_CODE_MOCK、VERIFICATION_CODE_EXPIRE_SECONDS、VERIFICATION_CODE_SEND_INTERVAL、VERIFICATION_CODE_LENGTH、PASSWORD_MIN_LENGTH、PASSWORD_MAX_LENGTH、MARIADB_ROOT_PASSWORD、TZ。

> 用户输入中的需求 1/2（检查 jdk/mariadb/redis/nacos 可用性、一键启动未启动服务）已由 TASK-003/004 的 `deploy-check-env.ps1/.sh`、`deploy-start-services.ps1/.sh` 实现（两者均含 Write-Result 输出分级函数，grep 实测位于各自第 33 行，可作输出风格参考）；TASK-006 只重构单服务启动脚本，不重复实现基础设施检查。

## 6. .gitignore 现状与需求 3（临时/中间文件排除）调查结果

### 6.1 已覆盖情况（git check-ignore 实测确认）
| 路径/模式 | 匹配规则（.gitignore 行号） | 状态 |
| --- | --- | --- |
| deploy/*.jar（4 个） | `*.jar`（233 行） | ✅ 已忽略 |
| deploy/logs/*.log / *.err / *.pid | `*.log`（290）+ `logs/`（291） | ✅ 已忽略 |
| deploy/keys/*（pem/der/base64） | `keys/`（319 行） | ✅ 已忽略 |
| deploy/env.json | `env.json`（320 行） | ✅ 已忽略 |
| 根目录 keys/、logs/ | `keys/`、`logs/` | ✅ 已忽略 |
| 根目录 derby.log | `*.log`（290 行） | ✅ 已忽略（Derby 调试日志） |
| scripts/API-TEST/__pycache__/*.pyc | `__pycache__/`（208 行） | ✅ 已忽略 |
| target/、build/、.idea/、.opencode/、docs2/、.env.* | 各自规则 | ✅ 已忽略 |
| deploy/cloudoffice-flutter-app/web/*、windows/* | 279-286 行（保留 .gitkeep） | ✅ 已忽略 |

### 6.2 已追踪文件扫描（git ls-files 全量 516 个）
- 无 *.pid / *.err / *.log / *.tmp / *.bak / *.orig / *.out / __pycache__ / target 前缀文件混入 ✅
- deploy 目录下已追踪仅脚本、文档、.gitkeep、env.example.json，无 jar/日志/密钥 ✅
- git status 工作区干净（仅 TASK-006 文档变更）✅

### 6.3 建议补充项（供编码阶段写 .gitignore 时参考）
| 建议 | 理由 |
| --- | --- |
| 显式添加 `work/`（根目录 Tomcat 调试工作区，当前为空目录） | 现状无显式规则；git 对空目录不追踪故暂无风险，但 Tomcat 解压/调试产物一旦产生（*.jar 之外的配置、日志、脚本等）可能混入；显式忽略最稳妥 |
| 可选：`*.err`、`*.pid` 全局模式 | 当前仅靠 `logs/` 覆盖 deploy/logs；其他位置若产生 err/pid 文件不会被忽略（建议随部署脚本重构一并加入） |
| 观察项：`.opencode/` 整目录被忽略（99 行），`git ls-files .opencode/` 为 0 | impm 技能文件实际存放在 .opencode/skills 但未入库；若需团队共享技能可加 `!.opencode/skills/` 豁免（非本任务范围，仅提示） |

## 7. 重构要点汇总（供 BEE/FEE 编码实现参考）

1. **8 个脚本统一骨架**：SPDX 头（Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>）→ 加载 load-env → 定义输出函数（Write-Result/print_result）与健康探测函数（Test-HttpOk/Test-TcpPort/Wait-HealthUp 或 http_ok/tcp_port_open/wait_health_up）→ 前置校验（java 可用 + jar 存在 + 本服务关键变量非空）→ 后台启动（Start-Process/nohup + 日志 PID 落位）→ 健康确认 → 汇总退出码（失败 1/通过 0）。
2. **校验变量按服务**（F-009 + start-all 契约表）：gateway：NACOS_ADDR、RSA_PUBLIC_KEY；auth：NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD（**移除现状多余的 DB_HOST/DB_PORT/DB_USERNAME/REDIS_HOST/REDIS_PORT**）；biz/system：NACOS_ADDR、DB_PASSWORD（**.ps1 补齐 DB_PASSWORD**，对齐 .sh）。缺失提示只列键名，不打印值。
3. **DB_USER vs DB_USERNAME**：保持现状差异（biz 用 DB_USER、auth 用 DB_USERNAME 是服务自身读取逻辑差异），单服务脚本校验范围不引入 DB_USER/DB_USERNAME 校验（契约表未列）；如要保留差异说明，在脚本注释中注明即可。
4. **启动参数**：`java -Xms256m -Xmx512m -jar <jar>`（4 服务一致）。
5. **健康 URL**：gateway `http://localhost:9000/`；auth/biz/system `http://localhost:{port}/api/v1/{module}/health`（端口 9100/9200/9400）。
6. **日志/PID**：`deploy/logs/{module}-start.log`（.ps1 另写 `-start.err`）、`deploy/logs/{module}.pid`；确保 logs 目录存在（New-Item -Force / mkdir -p）。
7. **标题与版本**：脚本标题含 `版本: v0.2.7`；删除旧版 v0.1.7 头部与 deploy-env-local 引用注释。
8. **可配置参数**：.ps1 可用 param（RetryCount/RetryInterval/ProbeTimeout 默认 30/2/3）；.sh 用 RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT 环境变量覆盖。
9. **单服务脚本独立性**：4 个脚本各自独立可运行，不相互依赖（仅依赖 load-env 与 env.json）。
10. **.gitignore 补充**：按 6.3 建议添加 `work/`（及可选 `*.err`、`*.pid`），注意保持 SPDX 头在文件末尾。

## 8. 关键文件路径索引

| 文件 | 说明 |
| --- | --- |
| deploy/scripts/deploy-start-gateway/auth/biz/system.{ps1,sh} | 8 个待重构脚本（路径：D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice\deploy\scripts\） |
| deploy/scripts/deploy-start-all.{ps1,sh} | 行为对齐基准（TASK-005，221 行 / 196 行） |
| deploy/scripts/load-env.{ps1,sh} | 统一配置加载模块（TASK-002，75 行 / 84 行） |
| deploy/scripts/deploy-check-env.{ps1,sh} | TASK-003 环境可用性检查（Write-Result 输出分级参考） |
| deploy/scripts/deploy-start-services.{ps1,sh} | TASK-004 基础设施一键启动（Write-Result 参考） |
| deploy/env.example.json | 环境配置模板（27 键，含 DB_USER 与 DB_USERNAME） |
| deploy/cloudoffice-{gateway,auth-service,biz-service,system-service}.jar | 4 个服务 jar（已落位） |
| .gitignore | 332 行，覆盖已确认，补充建议见 6.3 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
