# 本地代码查询（TASK-010 部署文档与 readme 更新）

## 1. 目标文件现状

### deploy/deploy.md（当前 v0.2.7，需更新为 v0.2.8）
- 第 5 行"适用版本"为 v0.2.7；第 7 行"最近更新"为 2026-08-10。
- 第 15~22 行"v0.2.7 部署要点"：后端一键启动顺序为 **gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）**（第 19 行），单服务启动脚本（第 20 行）为 gateway/auth/biz/system。
- 第 26~36 行"部署架构"表格：无 cloudoffice-common 行；现有 4 个后端服务 + 客户端 + 基础设施。
- 第 54~57 行 deploy 目录结构：jar 清单无 cloudoffice-common.jar；第 75~79 行 scripts 清单无 deploy-start-common/deploy-stop-common/deploy-stop-all。
- 第 157~184 行"5.6 启动后端服务"：一键启动顺序为 gateway→auth→biz→system；单服务启动列表为 gateway/auth/biz/system。
- 第 196~213 行"6. 配置说明"表格：无 COMMON_PORT 项。
- 第 217~237 行"7. 启动与停止命令汇总"：一键启动顺序为 gateway→auth→biz→system，无 common。
- 第 239~251 行"8. 健康检查"：服务列表无 common 健康检查端点；第 248 行服务健康检查接口仅列 auth。
- 第 272~289 行"11. 常见问题"：端口占用提示为 9000/9100/9200/9400，无 9300；jar 缺失提示为 4 个 jar。
- 第 292~300 行"12. 参考"：无 v0.2.8 PRD 引用。

### readme.md（当前 v0.2.7，需更新为 v0.2.8）
- 第 16 行项目介绍：仅说"公共模块（common）"，未提服务化。
- 第 18 行"当前版本 v0.2.7"：需在版本规划中新增 v0.2.8 说明或调整当前版本描述。
- 第 30 行功能特性表格"微服务架构 | 5 个 Maven 模块"：可保留；需新增通用配置管理功能介绍。
- 第 144 行模块说明：`cloudoffice-common` 端口为 `-`，功能描述为纯公共模块，需补充服务化说明（端口 9300、健康检查、通用配置管理接口）。
- 第 145~149 行其他服务模块说明保留。
- 第 224~231 行"环境配置与部署脚本"资产表：最终产物描述为"后端 jar 包（auth/biz/system/gateway）"，需补 common。
- 第 330~346 行"方式四 deploy/scripts 脚本启动"：③ 后端服务按序一键启动顺序为 gateway → auth → biz → system；单服务脚本列表无 common。
- 第 348~365 行"验证部署"：健康检查端点无 /api/v1/common/health。
- 第 366~381 行健康检查响应示例保留。
- 第 502 行 API 接口列表标题"v0.1.6 完整接口；v0.2.5 为工程目录调整、v0.2.6 为配置/依赖修复，均无接口变更"：v0.2.8 有 common 接口新增，需在"健康检查"接口表补充 common 健康检查，并可补通用配置管理接口说明。
- 第 550~556 行健康检查接口表：无 /api/v1/common/health。
- 第 641~719 行项目结构：cloudoffice-common 标注"JAR 包，无启动类"（第 649 行）；deploy/scripts 清单无 common 相关脚本与 deploy-stop-all。
- 第 721~731 行端口分配表：无 cloudoffice-common（9300）。
- 第 750~764 行版本规划表：需新增 v0.2.8 行。

## 2. 已完成的上游任务产物（TASK-007/008/009，作为文档对齐依据）

### env.json / env.example.json（TASK-009）
- `COMMON_PORT` 已加入 env.example.json（第 4 行，值 `9300`）。

### deploy/scripts（TASK-007/008/009 已更新）
- `deploy-start-all.ps1/.sh`：服务清单为 **common(9300) → gateway(9000) → auth(9100) → biz(9200) → system(9400)**（数组顺序即启动顺序契约）；common 健康地址 `http://localhost:{port}/api/v1/common/health`；common 端口读 `COMMON_PORT` 环境变量（缺省 9300）；校验 5 个 jar 含 cloudoffice-common.jar。
- `deploy-stop-all.ps1/.sh`：停止顺序为 **system(9400) → biz(9200) → auth(9100) → gateway(9000) → common(9300)**，common 最后停止。
- `deploy-start-common.ps1/.sh`：单服务启动 common，jar `cloudoffice-common.jar`，端口读 COMMON_PORT（缺省 9300），健康地址 `/api/v1/common/health`，必填变量 NACOS_ADDR/COMMON_PORT/DB_PASSWORD。
- `deploy-stop-common.ps1/.sh`：单服务停止 common。
- `build-backend.ps1/.sh`：已校验/复制 5 个 jar（含 cloudoffice-common.jar），v0.2.8 新增 common 产物输出。

### 服务端代码（TASK-001~006 已完成）
- cloudoffice-common 已服务化：启动类、bootstrap.yml、application.yml（端口 9300）、健康检查端点 `/api/v1/common/health`、通用配置管理查询接口 `GET /api/v1/common/config`、`GET /api/v1/common/config/{serviceName}`。
- 网关已新增 `/api/v1/common/**` 路由与健康检查白名单。

## 3. 复用与可参考内容
- 文档风格：deploy.md / readme.md 现有表格与章节结构，仅追加/更新 common 相关部分，不删除现有 gateway/auth/biz/system 内容。
- 端口与顺序契约：以 SAD v0.2.8（ADR-017/018/019）与 deploy 脚本现状为准（common 9300，启动 common→gateway→auth→biz→system，停止 system→biz→auth→gateway→common）。
- 健康检查端点：`GET /api/v1/common/health`（返回统一 ApiResult，含服务名 cloudoffice-common、状态 UP、版本号与时间戳）。
