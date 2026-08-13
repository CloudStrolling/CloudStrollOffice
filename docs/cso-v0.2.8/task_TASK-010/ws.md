# 网络资料查询（TASK-010 部署文档与 readme 更新）

## 1. 结论
本任务为**纯文档更新任务**（更新 deploy/deploy.md 与 readme.md），不涉及新增三方中间件、SDK 或第三方包，无需引入任何新的外部依赖。文档内容以项目内既有权威资料（SAD v0.2.8、PRD v0.2.8、deploy 脚本实际现状、env.example.json）为唯一依据，无需网络查询外部文档。

## 2. 所需三方组件识别
- 无需查询的组件：本项目技术栈（Spring Boot/Spring Cloud/Nacos/MariaDB/Redis 等）均为既有依赖，本任务不新增、不修改任何依赖。
- 本任务仅做文档编排，直接引用项目内已确定的端口（common 9300）、启动/停止顺序契约（common→gateway→auth→biz→system / 逆序）与健康检查端点（/api/v1/common/health）。

## 3. 版本兼容性说明
- 不涉及版本变更，无版本兼容性问题。

## 4. 相关任务资料（项目内依据，非网络资料）
- SAD v0.2.8：ADR-017（common 服务化）、ADR-018（通用配置管理接口先行）、ADR-019（部署顺序含 common）；端口映射（common 9300）；部署顺序契约。
- PRD v0.2.8：F-010（deploy.md 更新）、F-011（readme.md 更新）、US-006（验收标准）。
- deploy/scripts 实际现状：deploy-start-all（common→gateway→auth→biz→system）、deploy-stop-all（system→biz→auth→gateway→common）、deploy-start-common/deploy-stop-common、build-backend（含 common jar）。
- deploy/env.example.json：已含 COMMON_PORT=9300。

## 5. 风险提示
- 文档更新必须遵循"仅追加/更新 common 相关部分，不删除或覆盖现有 gateway/auth/biz/system 内容"约束，确保与 deploy 脚本现状、SAD/PRD 契约一致。
