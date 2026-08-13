# TASK-008 需求上下文（context.md）

## 1. 任务信息
- 任务编号：TASK-008
- 任务名称：部署停止脚本更新（deploy-stop-all 含 common 居末 + deploy-stop-common）
- taskType：common
- 用户故事：US-004（deploy-stop-all 一键停止含 common 的全服务）
- 优先级：P0
- 上游依赖：TASK-006（编译脚本更新，已完成，common jar 已纳入产物输出）
- 下游依赖：TASK-010（部署文档与 readme 更新）
- 验收标准：deploy-stop-all 按 system→biz→auth→gateway→common 逆序停止，common 最后停止；全部停止成功输出汇总并退出码 0；某服务未运行时跳过并提示、不影响其他服务；双平台行为一致。

## 2. 用户输入（v0.2.8 相关）
1. cloudoffice-common 不仅包括公共的函数、变量定义，也包括公用的接口，因此也需要和其他微服务一样提供 api 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本，部署文档和 readme.md、deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理。统一配置不同微服务、不同业务场景下的所有配置工作。除去启动的环境变量外，所有需要的配置，都通过通用配置管理配置。
5. 当前这个任务只是配置的查询接口，后端管理后面会增加。

## 3. PRD 用户故事 US-004 要点（F-009 部署停止脚本更新）
- 服务停止顺序固定为：system → biz → auth → gateway → common（common 在所有后端服务中最后停止）。
- 停止方式：按 PID 或进程名终止对应 Java 进程（与现有单服务停止逻辑一致）。
- common 服务最后停止，确保其他服务在停止过程中仍可访问配置接口。
- 停止后输出各服务停止结果汇总。
- 脚本遵循 v0.2.7 脚本体系约定（load-env 统一加载 env.json、输出分级通过/警告/失败、退出码失败非零、.ps1 与 .sh 双平台行为一致）。
- 边界情况：某服务进程不存在时跳过并输出"未运行"提示，继续停止后续服务；停止命令需管理员权限时输出权限提示；.ps1 与 .sh 行为不一致时以 v0.2.7 脚本体系约定为准对齐。
- 验收标准：
  - 5 个服务正在运行时，按 system→biz→auth→gateway→common 逆序停止，common 最后停止；
  - 全部停止成功输出 5 个服务停止结果汇总，退出码 0；
  - 某服务已停止或不存在进程时跳过该服务并输出提示，不影响其他服务停止。

## 4. SAD 架构设计要点
- ADR-019：deploy-stop-all 服务清单新增 common 并置于最后一位（system→biz→auth→gateway→common），common 最后停止。
- 脚本体系约束：全部部署脚本统一经 load-env 从 deploy/env.json 加载配置，脚本内不得硬编码环境地址与凭据；输出分级（通过/警告/失败）、退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致。
- common 服务端口 9300，服务名 cloudoffice-common，健康检查端点 /api/v1/common/health。
- deploy-stop-all 现有逻辑还包含停止 Nacos（基础设施），不停止 Redis/MySQL/MariaDB。

## 5. 现有脚本现状（deploy-stop-all）
- deploy-stop-all.ps1（v0.2.7）：
  - 服务清单 $Services：system(9400)/biz(9200)/auth(9100)/gateway(9000)，共 4 个后端服务。
  - 停止顺序 system→biz→auth→gateway（与启动相反）。
  - 停止方式：优先读取 deploy/logs/{name}.pid 记录的 PID，校验进程命令行含 jar 名后 Stop-Process；轮询等待退出（默认超时 30 秒/间隔 2 秒），超时强制停止；PID 文件缺失或进程不存在视为已停止（幂等通过）；回退按 java 进程命令行含 jar 名定位（Find-JavaPidByJar）。
  - 停止 Nacos（Test-NacosUp：HTTP 探测 http://NACOS_ADDR/nacos/ 或 java 进程含 nacos）；不停止 Redis/MySQL/MariaDB。
  - 输出分级与汇总：通过 $script:pass / 警告 $script:warn / 失败 $script:fail；全部通过退出 0，存在失败退出 1。
  - 汇总输出各服务（含 Nacos）停止结果。
- deploy-stop-all.sh（v0.2.7）：与 .ps1 行为一致的 Bash 实现，SERVICES 数组含 4 个服务，pgrep -f jar 名定位，kill SIGTERM / kill -9 强杀。

## 6. 本任务产出范围（只写本任务对应文件）
- deploy/scripts/deploy-stop-all.ps1：服务清单新增 common（置于最后，system→biz→auth→gateway→common），汇总输出含 common。
- deploy/scripts/deploy-stop-all.sh：同上，Bash 版本。
- deploy/scripts/deploy-stop-common.ps1：单服务停止脚本（common 服务，端口 9300，jar cloudoffice-common.jar）。
- deploy/scripts/deploy-stop-common.sh：同上，Bash 版本。
- 测试用例：docs/cso-v0.2.8/task_TASK-008/testcase.md；合并到版本 testcase 文档。
- 版本目录共享文档：如需要变更（dbd/api/ui-test-record/api-test 脚本）按写冲突规避规则先读再合并写回。
