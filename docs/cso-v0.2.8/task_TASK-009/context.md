# 任务上下文（#TASK-009 环境配置更新（env.json / env.example.json 新增 COMMON_PORT））

## 1. 任务信息

```json
{
  "id": "TASK-009",
  "title": "环境配置更新（env.json / env.example.json 新增 COMMON_PORT）",
  "description": "更新 deploy/env.json 与 deploy/env.example.json，新增 cloudoffice-common 相关环境配置项（COMMON_PORT，建议值 9300，供 common 服务 application.yml 与部署脚本读取）；env.example.json 提供示例值与注释说明，env.json 填入实际值；不影响现有 gateway/auth/biz/system 配置项；保持 env.json 不入库、env.example.json 入库的现有策略。",
  "taskType": "common",
  "userStoryId": "US-003",
  "apiId": "",
  "upstreamTaskIds": ["TASK-007"],
  "downstreamTaskIds": ["TASK-010"],
  "priority": "P0",
  "status": "执行中",
  "testMethod": "配置校验",
  "acceptanceCriteria": "env.json 与 env.example.json 均新增 COMMON_PORT（示例值与实际值正确）；现有 gateway/auth/biz/system 配置项不受影响；env.json 不入库、env.example.json 入库策略保持。"
}
```

## 2. 用户需求（US-003：deploy-start-all 一键启动含 common 的全服务）

作为（运维/部署工程师），我想要（deploy-start-all 脚本按 common → gateway → auth → biz → system 顺序一键启动全部 5 个后端服务），以便（cloudoffice-common 作为公共依赖与配置提供方最先启动，确保后续服务启动时可通过 Nacos 服务发现获取 common 的配置接口）。

### 前置条件
- 5 个服务 jar 包已构建并落位 deploy 目录；
- deploy/env.json 已配置 NACOS_ADDR 等关键项；
- 基础设施（MariaDB/Redis/Nacos）已就绪。

### 验收标准
- [ ] Given 5 个 jar 与关键环境变量就绪，When 执行 `deploy-start-all.ps1`/`.sh`，Then 按 common → gateway → auth → biz → system 顺序逐个启动，common 最先启动且健康确认后再启动 gateway
- [ ] Given common 服务启动失败，When 执行一键启动脚本，Then 输出错误提示并停止后续启动（gateway 及之后服务不启动）
- [ ] Given 全部服务启动成功，When 执行一键启动脚本，Then 输出 5 个服务的启动结果与健康状态汇总，退出码 0
- [ ] Given 某 jar 缺失或关键变量缺失，When 执行一键启动脚本，Then 输出缺失项与处理提示，以非零码退出，不启动任何服务

### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| common 启动失败 | 停止后续服务启动，提示检查 NACOS_ADDR / jar 包 |
| common 健康检查超时 | 按等待重试次数重试，仍失败则输出失败并停止 |
| common 端口被占用 | 提示检查端口占用并指导处理 |
| .ps1 与 .sh 行为不一致 | 以 v0.2.7 脚本体系约定为准对齐 |

### 关联功能编号
F-001、F-002、F-008

## 3. 项目信息

- 项目中文名称：云漫智企
- 项目英文名称：CloudStrollOffice
- 项目英文缩写：cso
- 编程语言：Java 21（Spring Boot 3.2.5 / Spring Cloud 2023.0.1）
- 项目类型：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
- 总体介绍：后端 Maven 多模块架构，由 common/gateway/auth-service/biz-service/system-service 组成；基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

## 4. 系统架构相关章节（SAD v0.2.8）

### 4.1 配置范围约束（v0.2.8）
通用配置管理仅管理运行时配置（业务参数、功能开关、限流参数、业务规则参数等），启动环境变量（NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、NACOS_HOME 等）不纳入通用配置管理范围，仍由 env.json 环境变量注入。

### 4.2 ADR-017 common 服务化改造
v0.2.8 将 cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务（端口 9300）：新增启动类、bootstrap.yml（Nacos discovery/config server-addr）、application.yml（端口、SpringDoc 分组）、健康检查端点（/api/v1/common/health）、SpringDoc OpenAPI 文档；common 同时保留公共 jar 模块能力，下游服务（gateway/auth/biz/system）仍以 Maven 依赖方式引用 common 公共类与接口；common 引入 spring-cloud-starter-bootstrap 保证 Nacos 引导链路正常。

### 4.3 ADR-019 部署顺序含 common（v0.2.8）
deploy-start-all 服务清单新增 common 并置于第一位（common→gateway→auth→biz→system）；deploy-stop-all 服务清单新增 common 并置于最后一位（system→biz→auth→gateway→common）；build-backend 编译脚本将 common 纳入编译产物输出范围，生成可部署 jar 包到 deploy 目录；deploy-start-{common} 单服务启动脚本与一键启动对应逻辑一致。

### 4.4 部署架构（端口映射）
Nacos 8848、MariaDB 3306、Redis 6379、**common 9300（v0.2.8 新增）**、网关 9000、认证服务 9100、业务服务 9200、系统服务 9400。

### 4.5 部署资产约束
根目录 `deploy` 为最终构建产物与部署资产唯一落点；`env.json`/`env.example.json` 环境配置（v0.2.8 新增 COMMON_PORT 等配置项）与 `deploy/scripts` 下全部脚本集中存放；env.json 不入库、env.example.json 入库。

### 4.6 脚本体系约束（v0.2.7 起，v0.2.8 扩展）
全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据；输出统一分级（通过/警告/失败）、退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致。

## 5. PRD 相关功能（v0.2.8）

### F-012 env.json 配置更新
- env.json 与 env.example.json 新增 cloudoffice-common 相关配置项（如 `COMMON_PORT` 或 `COMMON_SERVICE_PORT`，具体键名由详细设计确定）；
- env.example.json 作为配置模板，新增项需提供示例值与注释说明；
- env.json 为实际配置文件，新增项需填入实际值；
- 环境变量更新不得影响现有 gateway/auth/biz/system 的配置项；
- env.json 与 env.example.json 保持不入 git 仓库（env.json）与入 git 仓库（env.example.json）的现有策略。

## 6. 任务验收标准（TASK-009）
env.json 与 env.example.json 均新增 COMMON_PORT（示例值与实际值正确）；现有 gateway/auth/biz/system 配置项不受影响；env.json 不入库、env.example.json 入库策略保持。

## 7. 测试方法
配置校验（校验 env.json 与 env.example.json 的 JSON 合法性与 COMMON_PORT 存在性、键名白名单）。
