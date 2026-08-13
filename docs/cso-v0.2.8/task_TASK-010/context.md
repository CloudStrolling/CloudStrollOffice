# 任务上下文（TASK-010 部署文档与 readme 更新）

## 1. 任务信息

```json
{
  "id": "TASK-010",
  "title": "部署文档与 readme 更新（deploy.md / readme.md）",
  "description": "更新 deploy/deploy.md 与 readme.md：deploy.md 端口映射表新增 cloudoffice-common（9300）、启动顺序更新为 common→gateway→auth→biz→system、停止顺序更新为 system→biz→auth→gateway→common、健康检查端点新增 /api/v1/common/health、环境变量补充 COMMON_PORT 等；readme.md 项目介绍补充 common 服务化说明、功能清单新增通用配置管理功能介绍、端口映射与部署说明同步更新；仅追加/更新 common 相关部分，不删除或覆盖现有 gateway/auth/biz/system 内容。",
  "taskType": "common",
  "userStoryId": "US-006",
  "apiId": "",
  "upstreamTaskIds": ["TASK-007", "TASK-008", "TASK-009"],
  "downstreamTaskIds": [],
  "priority": "P1",
  "status": "执行中",
  "testMethod": "文档校验",
  "acceptanceCriteria": "deploy.md 含 common 端口/启动顺序/停止顺序/健康检查端点/环境变量说明；readme.md 含 common 服务化说明与通用配置管理功能介绍；现有 gateway/auth/biz/system 内容未被删除或覆盖。"
}
```

## 2. 用户需求（US-006：部署文档与 readme 更新）

### 故事描述
作为（运维/部署工程师），我想要（deploy.md 与 readme.md 已更新，补充 cloudoffice-common 服务化说明与通用配置管理功能介绍），以便（了解 common 服务的端口、启动顺序、健康检查端点等部署信息）。

### 前置条件
- cloudoffice-common 服务化改造完成；
- 部署脚本更新完成。

### 验收标准
- [ ] Given 文档更新完成，When 查看 deploy.md，Then 服务端口映射表含 cloudoffice-common，启动顺序为 common → gateway → auth → biz → system，停止顺序为 system → biz → auth → gateway → common
- [ ] Given 文档更新完成，When 查看 deploy.md，Then 健康检查端点说明含 `/api/v1/common/health`，环境变量说明含 common 相关配置项
- [ ] Given 文档更新完成，When 查看 readme.md，Then 项目介绍含 common 服务化说明，功能清单含通用配置管理功能介绍
- [ ] Given 文档更新完成，When 检查现有内容，Then 现有 gateway/auth/biz/system 的部署说明与功能介绍未被删除或覆盖

### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 端口信息遗漏 | 补充 common 服务端口到端口映射表 |
| 启动/停止顺序未更新 | 确保启动顺序含 common 在第一位，停止顺序含 common 在最后一位 |
| 现有内容被覆盖 | 保留现有内容，仅追加或更新 common 相关部分 |

### 关联功能编号
F-010（deploy.md 部署文档更新）、F-011（readme.md 更新）

## 3. 项目信息

- 项目中文名称：云漫智企（CloudStrollOffice）
- 项目英文缩写：cso
- 项目类型：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
- 后端语言：Java 21（Spring Boot 3.2.5 / Spring Cloud 2023.0.1 / Spring Cloud Alibaba 2023.0.1.0）
- 数据库：MariaDB 10.6（认证库 9 张表 + 通用配置表 + biz/system 预留）
- 基础设施：MariaDB 10.6（3306）、Redis 7.2（6379）、Nacos 2.3（8848）

## 4. 系统架构相关（SAD 摘录）

- **G-A8 common 服务化与通用配置管理（v0.2.8）**：cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务（端口 9300），具备 Nacos 服务注册、健康检查端点（/api/v1/common/health）、统一 ApiResult 响应、SpringDoc OpenAPI 文档等能力；新增通用配置管理查询接口，统一管理 gateway/auth/biz/system/common 五个微服务运行时配置（启动环境变量除外），本版本仅交付查询接口；同步更新编译脚本（build-backend 纳入 common 产物）、部署启动脚本（deploy-start-all 中 common 位于第一位）、部署停止脚本（deploy-stop-all 中 common 最后停止）、部署文档（deploy.md）与 readme.md。
- **端口映射**：Nacos 8848、MariaDB 3306、Redis 6379、common 9300（v0.2.8 新增）、网关 9000、认证服务 9100、业务服务 9200、系统服务 9400。
- **部署顺序（v0.2.8，ADR-019）**：deploy-start-all 服务清单新增 common 并置于第一位（common→gateway→auth→biz→system），common 最先启动且健康确认后再启动 gateway；deploy-stop-all 服务清单新增 common 并置于最后一位（system→biz→auth→gateway→common）；build-backend 编译脚本将 common 纳入编译产物输出范围；deploy-start-{common} 单服务启动脚本与一键启动对应逻辑一致。
- **env.json 新增配置项**：COMMON_PORT 等（v0.2.8 新增），env.json 与 env.example.json 同步更新。
- **健康检查端点**：`GET /api/v1/common/health`（白名单放行，返回统一 ApiResult 响应体，含服务名 cloudoffice-common、状态 UP、版本号与时间戳）。
- **网关路由**：新增 `/api/v1/common/**` → `lb://cloudoffice-common`。

## 5. 本任务范围与约束

- 仅更新 **deploy/deploy.md** 与 **readme.md** 两个文档；
- deploy.md：端口映射表新增 cloudoffice-common（9300）、启动顺序更新为 common→gateway→auth→biz→system、停止顺序更新为 system→biz→auth→gateway→common、健康检查端点新增 /api/v1/common/health、环境变量说明补充 COMMON_PORT 等；
- readme.md：项目介绍补充 common 服务化说明、功能清单新增通用配置管理功能介绍、端口映射与部署说明同步更新；
- **约束**：仅追加/更新 common 相关部分，不删除或覆盖现有 gateway/auth/biz/system 内容；
- 本任务为文档校验型任务（testMethod=文档校验），验收为文档内容核对。
