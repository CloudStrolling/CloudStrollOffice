# TASK-007 现有代码查询（cs.md）

## 一、相关脚本清单（deploy/scripts/）
| 脚本 | 现状 | 本任务是否需要修改 |
| --- | --- | --- |
| deploy-start-all.ps1 | v0.2.7，服务清单 4 个（gateway→auth→biz→system），顺序即启动顺序 | 修改：服务清单首位新增 common，更新标题/校验/汇总为 5 个服务 |
| deploy-start-all.sh | v0.2.7，同上 | 修改：同上 |
| deploy-start-common.ps1 | 不存在 | 新增：单服务启动脚本 |
| deploy-start-common.sh | 不存在 | 新增：单服务启动脚本 |
| deploy-start-gateway/auth/biz/system .ps1/.sh | v0.2.7 单服务启动脚本 | 不改（契约已与 deploy-start-all 对齐，本次不改其内容） |
| deploy-stop-all.ps1/.sh | v0.2.8，已含 common 居末（TASK-008 已完成） | 不改 |
| deploy-stop-common.ps1/.sh | v0.2.8 已存在（TASK-008 完成） | 不改（可作单服务脚本模板参考） |
| load-env.ps1/.sh | v0.2.7 统一配置加载，白名单校验键名，关键配置缺失兜底退出 | 不改（COMMON_PORT 由 TASK-009 加入 env.json，load-env 自动加载） |
| build-backend.ps1/.sh | v0.2.8，已含 common 产物校验（TASK-006 完成） | 不改 |

## 二、deploy-start-all.ps1 关键结构（v0.2.7）
- 加载：`$ProjectDir = Split-Path -Parent $PSScriptRoot`，dot-source `load-env.ps1`
- 输出分级：Write-Result 函数（通过/警告/失败，计数 $script:pass/warn/fail）
- 探测函数：Test-TcpPort / Test-HttpOk / Wait-HealthUp（RetryCount=30/Interval=2/Timeout=3，HTTP 优先 TCP 备用）
- Nacos 处理：Test-NacosHttp / Test-NacosJavaProcess / Test-NacosUp / Wait-NacosUp，未运行则启动，失败即停退出非零
- **服务清单 $Services 数组**（pscustomobject：Name/Jar/Port/HealthUrl/RequiredVars/Hint）——顺序即启动顺序契约
- 前置校验：JDK + 各服务 jar + RequiredVars 非空校验，缺失输出缺失项并退出 1 不启动任何服务
- 启动循环：`Start-Process java -Xms256m -Xmx512m -jar <jar>` 隐藏窗口，日志 $logDir/{name}-start.log/.err，PID $logDir/{name}.pid
- 健康确认：Wait-HealthUp（HTTP 直连自身端口优先、TCP 备用），失败 break（失败即停）
- 汇总：遍历 $Services 输出启动结果与健康状态，失败退出 1

## 三、deploy-start-all.sh 关键结构（v0.2.7）
- 加载：`source "$SCRIPT_DIR/load-env.sh" || exit $?`，set -euo pipefail
- 输出分级：print_result 函数
- 探测函数：tcp_port_open / http_ok / wait_health_up / nacos_http_ok / probe_nacos_up / wait_nacos_up
- **服务清单 $SERVICES 数组**（`name|jar|port|url|vars,hint` 以 | 分隔字符串），IFS='|' 解析
- 前置校验/启动循环/健康确认/汇总逻辑与 .ps1 对应

## 四、单服务脚本模板参考（deploy-start-gateway.ps1/.sh，v0.2.7）
- 结构：加载 load-env → 全局计数 → 服务契约变量（$ServiceName/$JarName/$ServicePort/$HealthUrl/$RequiredVars/$MissingHint）→ 标题 → 前置校验（JDK/jar/环境变量）→ 后台启动 + 健康确认 → 汇总与退出码
- deploy-start-common.ps1/.sh 参照此结构编写，契约值：
  - ServiceName = "common"
  - JarName = "cloudoffice-common.jar"
  - ServicePort = 9300（读 $env:COMMON_PORT，缺省 9300）
  - HealthUrl = "http://localhost:{port}/api/v1/common/health"
  - RequiredVars = @("NACOS_ADDR", "COMMON_PORT", "DB_PASSWORD")（common 需连 DB 读 t_common_config 与 Redis 缓存，但 DB_PASSWORD 等已由 load-env 关键校验兜底；此处校验 NACOS_ADDR、COMMON_PORT、DB_PASSWORD）
  - MissingHint = "请检查 COMMON_PORT/DB_PASSWORD 配置"

## 五、common 服务配置（cloudoffice-common/src/main/resources/）
- bootstrap.yml：`spring.application.name=cloudoffice-common`，Nacos discovery/config server-addr=${NACOS_ADDR:127.0.0.1:8848}，namespace=${NACOS_NAMESPACE:cso-dev}，group=cloudoffice-common
- application.yml：`server.port=${COMMON_PORT:9300}`；datasource url 含 DB_COMMON_NAME（默认 cloudstroll_office_common）；redis 配置；springdoc 分组 common（paths-to-match /api/v1/common/**）
- 结论：common 独立启动时使用环境变量 NACOS_ADDR、COMMON_PORT、DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD、REDIS_*、NACOS_NAMESPACE，其中 COMMON_PORT 是新增键（TASK-009 补入 env.json）

## 六、健康检查端点（TASK-003 已完成）
- `GET /api/v1/common/health`，返回统一 ApiResult（code=200、data 含服务名 cloudoffice-common、状态 UP、版本与时间戳）

## 七、env.json 现状
- 当前无 COMMON_PORT 键（TASK-009 处理）；load-env 关键校验 8 项（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）不含 COMMON_PORT
- 部署脚本中 COMMON_PORT 需做缺省兜底（9300），并纳入前置校验 RequiredVars（缺失输出缺失项提示，符合 PRD 关键变量校验契约）

## 八、编码要点
1. deploy-start-all 双平台：服务清单首位插入 common 条目，顺序变为 common→gateway→auth→biz→system；标题/前置校验文案/汇总的"4 个服务"改"5 个服务"；版本号 v0.2.7→v0.2.8；端口占用提示增加 9300
2. common 条目：Port 读取 $env:COMMON_PORT（缺省 9300），HealthUrl=http://localhost:{port}/api/v1/common/health，RequiredVars=@("NACOS_ADDR","COMMON_PORT","DB_PASSWORD")，Hint="请检查 COMMON_PORT/DB_PASSWORD 配置"
3. 新增 deploy-start-common.ps1/.sh：参照 deploy-start-gateway 模板，契约见上
4. 与 deploy-stop-all（TASK-008 已完成）保持对称：启动 common 居首、停止 common 居末
5. 严格遵循 v0.2.7 脚本体系约定：load-env 统一加载、输出分级、退出码非零、双平台一致、口令不打印明文
