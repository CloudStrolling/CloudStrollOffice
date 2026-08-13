# TASK-009 网络资料查询（ws.md）

## 1. 技术背景
本任务为环境配置更新（deploy/env.json、deploy/env.example.json 新增 COMMON_PORT），仅涉及 JSON 配置文件编辑，不引入任何三方包、中间件或 SDK。以下为 JSON 配置与现有项目脚本体系的要点整理（用于与现有 v0.2.7 脚本体系对齐）。

## 2. JSON 配置文件格式要点
- env.json 与 env.example.json 为标准 JSON 对象（键值均为字符串），不支持行内注释，示例值通过键名自解释（如 `COMMON_PORT` 即 common 服务端口）。
- 新增键需保持键名大写蛇形（UPPER_SNAKE_CASE），与现有键风格一致（NACOS_ADDR、DB_PORT、REDIS_PORT、WEB_SERVER_PORT 等）。
- JSON 键顺序不影响 load-env 读取（jq / PowerShell ConvertFrom-Json 均按键读取），但为可读性应与现有分组风格保持一致。

## 3. 项目脚本体系约定（v0.2.7 起，v0.2.8 扩展）
- 全部部署脚本统一经 `load-env.ps1` / `load-env.sh` 从 deploy/env.json 加载配置，脚本内不硬编码环境地址与凭据。
- load-env 键名合法性白名单校验：仅允许 `[A-Za-z_][A-Za-z0-9_]*`，`COMMON_PORT` 符合该规则，无需修改 load-env。
- 关键配置校验（REQUIRED_KEYS 下限 8 项：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT）；COMMON_PORT 非必需键，无需加入 REQUIRED_KEYS。
- 输出分级（通过/警告/失败）与退出码约定（失败非零）、.ps1 与 .sh 双平台行为一致。

## 4. 端口键命名参考
- 现有端口相关键：`DB_PORT`、`REDIS_PORT`、`WEB_SERVER_PORT`（serve-web 脚本读取）。
- v0.2.8 SAD/PRD 建议 common 服务端口 9300，application.yml 已使用 `${COMMON_PORT:9300}` 占位符读取环境变量（TASK-007 服务化时已配置）。
- 因此新增键名 `COMMON_PORT`（与 application.yml 占位符一致），示例值/实际值均为 `"9300"`。

## 5. 版本兼容性
- 不引入三方依赖，无版本兼容风险。
- env.json（实际配置，不入库）与 env.example.json（模板，入库）均需同步新增 COMMON_PORT，保持结构一致，避免复制模板后缺失导致 common 服务端口异常。

## 6. 本任务关键实践结论
- 仅在 deploy/env.example.json 与 deploy/env.json 各新增 `"COMMON_PORT": "9300"`。
- env.example.json 作为模板提供示例值；env.json 填入实际值（9300）。
- 现有 gateway/auth/biz/system 配置项不动；env.json 不入库、env.example.json 入库策略保持。
- 无代码、脚本、SQL、API 变更。
