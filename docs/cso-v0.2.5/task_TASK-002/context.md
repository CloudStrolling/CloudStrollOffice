# 任务上下文（#TASK-002 迁移 env.json 与 env.example.json 至 deploy 目录）

## 1. 任务信息

```json
{
  "id": "TASK-002",
  "title": "迁移 env.json 与 env.example.json 至 deploy 目录",
  "description": "将项目根目录的 env.json、env.example.json 迁移至 deploy 目录（deploy/env.json、deploy/env.example.json），迁移后项目根目录不再保留这两个文件；与部署脚本相关的路径引用在 TASK-003 脚本迁移时同步适配。对应 PRD F-005。",
  "taskType": "common",
  "userStoryId": "US-003",
  "apiId": "",
  "upstreamTaskIds": [
    "TASK-001"
  ],
  "downstreamTaskIds": [
    "TASK-006"
  ],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "文件迁移校验：根目录不存在 env.json/env.example.json，deploy 目录下存在两个文件",
  "acceptanceCriteria": "AC-5：项目根目录不再保留 env.json、env.example.json；两文件已在 deploy 目录中"
}
```

## 2. 用户需求

### US-003：环境配置与部署脚本统一迁移到 deploy
#### 故事描述
作为运维/部署工程师，我想要 env.json/env.example.json 与全部 .sh/.ps1 脚本统一位于 deploy 目录下，以便在单一位置完成环境配置与部署运维操作。
#### 前置条件
现有 env.json、env.example.json 与 scripts 下 .sh/.ps1 脚本可正常工作。
#### 验收标准
- [ ] Given 迁移执行后，When 检查根目录，Then env.json、env.example.json 不再位于项目根目录，而位于 deploy 目录
- [ ] Given 迁移执行后，When 检查根目录 scripts 与 deploy/scripts，Then 全部 .sh/.ps1 已迁移至 deploy/scripts，根目录 scripts 下不再保留
- [ ] Given 迁移执行后，When 检查 scripts 非脚本内容，Then docker、sql、API-TEST、部署指南等未被移动
- [ ] Given 迁移执行后，When 执行部署脚本，Then 脚本可正常运行，env.json 加载正常
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 脚本内路径引用旧位置 | 同步更新为 deploy 下新路径，脚本功能不受影响 |
| scripts 下存在非 sh/ps1 文件 | 保持原位置不迁移 |
#### 关联功能编号
F-005、F-006、F-007

### 对应 PRD 功能：F-005 env.json 与 env.example.json 迁移
#### 功能描述
将项目根目录下的 `env.json` 与 `env.example.json` 迁移到 `deploy` 目录，并确保相关部署脚本仍能正确引用这两个文件。
#### 业务规则
- 迁移后文件位于 `deploy/env.json`、`deploy/env.example.json`。
- 项目根目录下不再保留这两个文件（或保留方式由编码阶段确认，但默认应完成迁移，根目录不残留）。
- 依赖这两个文件的部署脚本（迁移后的 deploy/scripts 下脚本）中的路径引用必须同步更新为 `deploy` 目录下的新路径，保证 env 加载功能可用。

### 验收标准（PRD 第 7 节，本任务相关）
- **AC-5**：项目根目录不再保留 `env.json`、`env.example.json`；两文件已在 `deploy` 目录中。

### 版本背景（v0.2.5 部署资产集中化）
- G1 产物集中化：建立统一的 `deploy` 目录，作为所有模块最终构建产物的唯一落盘位置。
- G2 部署资产集中化：将环境配置（env.json、env.example.json）与部署运维脚本（scripts 下全部 .sh/.ps1）统一收拢至 `deploy` 目录。
- G3 目录纯净性：构建阶段的中间产物（编译临时文件、测试产物、过程文件等）不得进入 `deploy` 目录。

## 3. 项目信息（节选）

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）

### 编码规范（相关要点）
- 数据库脚本放 `scripts/sql/`，Docker 编排放 `scripts/docker/`，部署脚本放 `scripts/`。
- 禁止提交密钥、密码等敏感信息：RSA 密钥对、数据库密码等通过环境变量注入（`env.json` / `env.example.json` 模板管理，密钥文件放 `keys/` 并加入 .gitignore）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:）。

### 根目录关键文件与目录（迁移前现状）
- `env.json` / `env.example.json` — 环境变量模板（数据库、Redis、RSA 密钥等），位于项目根目录
- `keys/` — RSA 密钥对存放目录（敏感，不入库）
- `scripts/` — 部署脚本（deploy-*.ps1/sh）、SQL 脚本（sql/）、Docker 编排（docker/）、API 测试脚本（API-TEST/）
- `docs/` — 项目文档（project.md、sad.md、版本目录等）

## 4. 系统架构相关（节选）

### 设计目标 G-A6 部署资产集中化
以根目录 `deploy` 为全部最终构建产物（后端微服务 jar 包、客户端安装文件/exe）与部署资产（env.json/env.example.json、deploy/scripts 下 .sh/.ps1 部署运维脚本）的唯一落点，实现"产物集中、纯净交付、迁移无损"；构建中间产物（target 目录、编译临时文件、测试产物）一律不进入 deploy。

### 部署资产约束（SAD 1.2）
- 最终构建产物（后端各服务 jar 包、客户端安装文件/exe）统一输出至根目录 `deploy` 目录。
- 环境配置 `env.json`/`env.example.json` 与部署运维脚本（`deploy/scripts` 下的 .sh/.ps1）集中存放于 deploy 下。
- 构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy。
- 迁移后脚本内环境配置/密钥/产物路径引用必须同步适配，保证部署功能不因路径变化失效。

### 部署资产说明（SAD 第 6 节）
根目录 `deploy` 为最终构建产物与部署资产的唯一落点——Maven 各模块 package 生成的最终 jar 包与 Flutter 客户端构建生成的安装文件/exe 均输出到 `deploy` 目录；`env.json`/`env.example.json` 环境配置与 `deploy/scripts` 下全部 .sh/.ps1 部署运维脚本集中存放；构建中间产物（target 目录、编译临时文件、测试产物等）禁止进入 deploy；`deploy/scripts` 脚本内部对 env.json、密钥文件（keys）、jar 包等路径引用随迁移同步适配。

### ADR-013 构建产物与部署资产集中化
新建根目录 `deploy` 作为全部最终构建产物唯一落点（后端 jar 包、客户端安装文件/exe）；`env.json`/`env.example.json` 迁移至 deploy；scripts 下全部 .sh/.ps1 迁移至 `deploy/scripts` 并同步适配路径引用；构建中间产物禁止进入 deploy。

## 5. 任务执行要点（TL 提示）

1. 本任务（TASK-002）只负责 env.json 与 env.example.json 两个文件的迁移：从项目根目录移至 `deploy/` 目录（前提：TASK-001 已创建 deploy 目录）。
2. 迁移后项目根目录不得残留 env.json / env.example.json（验收 AC-5）。
3. 与部署脚本相关的路径引用适配不属本任务范围，由 TASK-003（脚本迁移）负责。
4. 迁移方式：文件移动（git mv 或 move），保留文件内容不变；env.json 可能含敏感信息（密钥/密码），注意不得提交真实密钥。
5. 测试方法：文件迁移校验——根目录不存在 env.json/env.example.json，deploy 目录下存在两个文件。
<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->