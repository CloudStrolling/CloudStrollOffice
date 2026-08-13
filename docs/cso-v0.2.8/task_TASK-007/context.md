# TASK-007 需求上下文（context.md）

## 一、任务基本信息
- **任务编号**：TASK-007
- **任务名称**：部署启动脚本更新（deploy-start-all 含 common 居首 + deploy-start-common）
- **任务类型**：common（运维/部署脚本类）
- **用户故事**：US-003（deploy-start-all 一键启动含 common 的全服务）
- **上游任务**：TASK-003、TASK-004、TASK-005、TASK-006（common 服务化、config 接口、网关路由、编译脚本）
- **下游任务**：TASK-009、TASK-010（串行等待）
- **优先级**：P0
- **测试方法**：部署脚本验证
- **版本号**：0.2.8
- **项目根目录**：D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice

## 二、用户输入原文
1. cloudoffice-common不仅包括公共的函数，变量定义，也包括公用的接口，因此也需要和其他微服务一样提供api服务。
2. 不仅需要修改 cloudoffice-common的代码和配置，也需要修改编译和部署的脚本，部署文档和readme.md,deploy-stop-all脚本。
3. 在deploy-start-all脚本中，执行顺序在所有服务清单的第一位执行。
4. 在cloudoffice-common增加通用配置管理。统一配置不同微服务，不同业务场景下的所有配置工作。除去启动的环境变量外，所有需要的配置，都通过通用配置管理配置。
5. 当前这个任务只是配置的的接口，后端管理后面会增加。

## 三、PRD 用户故事 US-003 验收标准
- [ ] 5 个 jar 与关键环境变量就绪时执行 `deploy-start-all.ps1`/`.sh`，按 common → gateway → auth → biz → system 顺序逐个启动，common 最先启动且健康确认后再启动 gateway
- [ ] common 服务启动失败时，输出错误提示并停止后续启动（gateway 及之后服务不启动）
- [ ] 全部服务启动成功时，输出 5 个服务的启动结果与健康状态汇总，退出码 0
- [ ] 某 jar 缺失或关键变量缺失时，输出缺失项与处理提示，以非零码退出，不启动任何服务

边界情况：
| 场景 | 预期处理 |
| --- | --- |
| common 启动失败 | 停止后续服务启动，提示检查 NACOS_ADDR / jar 包 |
| common 健康检查超时 | 按等待重试次数重试，仍失败则输出失败并停止 |
| common 端口被占用 | 提示检查端口占用并指导处理 |
| .ps1 与 .sh 行为不一致 | 以 v0.2.7 脚本体系约定为准对齐 |

## 四、相关功能（PRD 4.8 F-008 部署启动脚本更新）
- 服务启动顺序固定为：**common → gateway → auth → biz → system**（common 在所有后端服务中最先启动）
- 启动前校验：cloudoffice-common jar 包存在（deploy/cloudoffice-common.jar）；关键环境变量就绪（NACOS_ADDR 等）
- 启动命令统一为 `java -Xms256m -Xmx512m -jar <jar>`，common 服务独立后台运行
- common 服务启动后执行健康确认：HTTP 探测 `http://localhost:{common端口}/api/v1/common/health`，确认成功后再启动 gateway
- 任一步骤失败时输出明确错误提示并停止后续启动（默认失败即停策略）
- 输出全部服务的启动结果与健康状态汇总
- 脚本遵循 v0.2.7 脚本体系约定（load-env 统一加载 env.json、输出分级通过/警告/失败、退出码失败非零、.ps1 与 .sh 双平台行为一致）

## 五、SAD 关键决策（v0.2.8）
- **ADR-017**：common 服务化改造，端口 9300，健康检查端点 /api/v1/common/health，启动类 CommonApplication
- **ADR-019**：deploy-start-all 服务清单新增 common 并置于第一位（common→gateway→auth→biz→system）；deploy-stop-all 服务清单新增 common 并置于最后一位（system→biz→auth→gateway→common）；build-backend 纳入 common 产物；deploy-start-common 单服务启动脚本与一键启动对应逻辑一致
- 脚本体系约束：统一经 load-env 从 env.json 加载配置，脚本内不硬编码环境地址与凭据；输出分级（通过/警告/失败）、退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致；RSA 密钥契约 ADR-015（DER 单行 Base64）不破坏
- 配置范围约束：通用配置管理仅管理运行时配置，启动环境变量（NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、NACOS_HOME 等）仍由 env.json 注入
- common 服务端口：9300（COMMON_PORT 环境变量，v0.2.8 新增）

## 六、环境配置项（v0.2.8 新增/相关）
- `COMMON_PORT`：cloudoffice-common 服务端口（默认 9300），env.json 与 env.example.json 新增
- 其他关键变量：NACOS_ADDR、COMMON_PORT、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD 等

## 七、本任务涉及文件清单（仅本任务范围）
- deploy/scripts/deploy-start-all.ps1（服务清单首位插入 common，按 common→gateway→auth→biz→system 顺序启动）
- deploy/scripts/deploy-start-all.sh（同上）
- deploy/scripts/deploy-start-common.ps1（新增单服务启动脚本）
- deploy/scripts/deploy-start-common.sh（新增单服务启动脚本）
- 其他单服务脚本/load-env 如需适配 common 相关的校验与配置则同步调整

## 八、v0.2.7 脚本体系既有约定（需继承）
- load-env.ps1/.sh：统一配置加载，env.json 键值注入环境变量、键名白名单校验、缺失兜底退出
- deploy-start-all.ps1/.sh：前置校验（JDK + 4 个 jar + 关键环境变量）→ 按 gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序后台启动（java -Xms256m -Xmx512m，日志/PID 落 deploy/logs/）→ 每服务 HTTP 健康确认（可配置重试次数/间隔/超时）成功后再启动下一个，任一步失败即停
- 单服务启动脚本（deploy-start-gateway/auth/biz/system）：行为与 deploy-start-all 中各服务一致
- 健康检查端点：gateway /actuator/health 或对应 health（需查 cs.md），auth/biz/system /api/v1/{module}/health
- 日志与 PID：deploy/logs/ 下 *-start.log/.err、*.pid
- 退出码约定：失败非零

## 九、编码提示
- 本任务为部署脚本更新（common 类任务），核心是更新 deploy-start-all 双平台脚本（common 居首 + 健康确认后启动 gateway）、新增 deploy-start-common 双平台单服务启动脚本、适配 load-env 白名单（如 COMMON_PORT 需要加入）。
- 所有脚本必须使用 load-env 加载 env.json，不得硬编码地址与凭据。
- .ps1 与 .sh 行为必须对齐（v0.2.7 脚本体系约定）。
- 不修改 Java 代码与配置（TASK-003 已处理 common 服务化、TASK-004 已处理 config 接口、TASK-005 已处理网关路由、TASK-006 已处理编译脚本）。
- deploy-stop-all 脚本由 TASK-008（若存在）处理，本任务聚焦启动脚本。
