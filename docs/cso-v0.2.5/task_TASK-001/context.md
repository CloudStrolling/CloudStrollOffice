# 任务上下文（#TASK-001 新建 deploy 目录与 deploy/scripts 子目录）

## 1. 任务信息

```json
{
  "id": "TASK-001",
  "title": "新建 deploy 目录与 deploy/scripts 子目录",
  "description": "在项目根目录新建 deploy 目录及 deploy/scripts 子目录，作为最终构建产物（后端 jar、客户端安装文件/exe）、环境配置（env.json/env.example.json）与部署运维脚本的唯一落点。deploy 已存在时复用现有目录，不重复创建、不覆盖已有有效内容；目录只存放最终产物、环境配置与部署脚本，不得存放源代码与中间产物。对应 PRD F-001、F-006。",
  "taskType": "common",
  "userStoryId": "US-001",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": [
    "TASK-002",
    "TASK-003",
    "TASK-004",
    "TASK-005"
  ],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "目录结构校验：检查项目根目录存在 deploy 目录且包含 scripts 子目录",
  "acceptanceCriteria": "AC-1：项目根目录存在 deploy 目录，且包含 env.json、env.example.json 与 scripts 子目录（env 与脚本由后续任务迁移后满足）；deploy 已存在时复用不覆盖"
}
```

## 2. 用户需求（PRD 用户故事）

### US-001：建立统一的部署资产目录
#### 故事描述
作为发布/交付人员，我想要项目根目录下有一个统一的 deploy 目录集中存放最终产物与部署资产，以便一次性收集全部可交付内容，无需在多个目录间查找。
#### 前置条件
项目已具备多模块构建能力与现有 scripts/env 资产。
#### 验收标准
- [ ] Given 项目根目录，When 版本 v0.2.5 落地，Then 根目录存在 deploy 目录
- [ ] Given deploy 目录，When 查看目录内容，Then 包含 env.json、env.example.json 与 scripts 子目录
- [ ] Given 构建完成后，When 检查 deploy 目录，Then 不出现任何中间产物
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| deploy 目录已存在 | 复用现有目录，不重复创建、不覆盖已有有效内容 |
| 构建失败 | 不产生最终产物，deploy 目录不落盘失败产物 |
#### 关联功能编号
F-001、F-004

### 关联 PRD 功能描述要点
- **F-001 新建 deploy 目录**：位于项目根目录下，与 src（后端多模块根）、cloudoffice-flutter-app、scripts、docs 等平级；只存放最终产物、环境配置与部署脚本，不得存放任何源代码与中间产物；目录命名固定为小写 `deploy`。
- **F-006 deploy/scripts 子目录建立**：目录结构为 `deploy/scripts`，只存放部署运维脚本（.sh/.ps1），不存放 sql、docker、API-TEST 等非脚本内容。

### 用户输入（v0.2.5 修改内容）
1. 新建一个目录 deploy；
2. 修改配置，将所有模块生成的最终产物（jar 包、安装文件、exe 等）最终生成到 deploy 目录下（生成阶段的中间产物不要复制过去）；
3. env.json 与 env.example.json 迁移到这个目录；
4. deploy 目录下建 scripts 子目录，将目前 scripts 下所有的 sh 和 ps1 迁移到这个子目录。

## 3. 项目信息（project.md 摘要）

**项目中文名称**：云漫智企　**项目英文名称**：CloudStrollOffice　**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）

### 与任务相关的项目地图（根目录关键文件与目录）
- `pom.xml` — Maven 父 POM（groupId: org.cloudstrolling，统一依赖管理）
- `checkstyle.xml` / `.editorconfig` — 代码风格与规范配置
- `env.json` / `env.example.json` — 环境变量模板（数据库、Redis、RSA 密钥等，位于项目根目录，本任务需迁移至 deploy）
- `keys/` — RSA 密钥对存放目录（敏感，不入库）
- `scripts/` — 部署脚本（deploy-*.ps1/sh）、SQL 脚本（sql/）、Docker 编排（docker/）、API 测试脚本（API-TEST/）
- `docs/` — 项目文档（project.md、sad.md、版本目录等）

### 相关编码规范（摘录）
- 数据库脚本放 `scripts/sql/`，Docker 编排放 `scripts/docker/`，部署脚本放 `scripts/`（迁移后部署脚本位于 deploy/scripts）。
- 禁止提交密钥、密码等敏感信息：RSA 密钥对、数据库密码等通过环境变量注入（`env.json` / `env.example.json` 模板管理，密钥文件放 `keys/` 并加入 .gitignore）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:）。

## 4. 系统架构相关（sad.md 摘要）

### 设计目标
- **G-A6 部署资产集中化**：以根目录 `deploy` 为全部最终构建产物（后端微服务 jar 包、客户端安装文件/exe）与部署资产（env.json/env.example.json、deploy/scripts 下 .sh/.ps1 部署运维脚本）的唯一落点，实现"产物集中、纯净交付、迁移无损"；构建中间产物（target 目录、编译临时文件、测试产物）一律不进入 deploy。

### 设计约束（部署资产约束）
- 最终构建产物（后端各服务 jar 包、客户端安装文件/exe）统一输出至根目录 `deploy` 目录；
- 环境配置 `env.json`/`env.example.json` 与部署运维脚本（`deploy/scripts` 下的 .sh/.ps1）集中存放于 deploy 下；
- 构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy；
- 迁移后脚本内环境配置/密钥/产物路径引用必须同步适配，保证部署功能不因路径变化失效。

### 架构决策记录
- **ADR-013 构建产物与部署资产集中化**：新建根目录 `deploy` 作为全部最终构建产物唯一落点（后端 jar 包、客户端安装文件/exe）；`env.json`/`env.example.json` 迁移至 deploy；scripts 下全部 .sh/.ps1 迁移至 `deploy/scripts` 并同步适配路径引用；构建中间产物禁止进入 deploy。理由：产物集中、纯净交付、迁移无损；发布/交付人员单目录收集全部可交付资产；源代码与运行/部署资产清晰分离，部署运维入口统一。（2026-08-09）

## 5. 任务要点小结（供编码使用）

1. **交付物**：项目根目录新建 `deploy` 目录及 `deploy/scripts` 子目录；deploy 已存在时复用现有目录，不重复创建、不覆盖已有有效内容。
2. **目录性质**：deploy 只存放最终产物（后端 jar、客户端安装文件/exe）、环境配置（env.json/env.example.json）与部署脚本（.sh/.ps1）；不得存放源代码与中间产物。
3. **env 与脚本迁移由后续任务负责**（env 迁移 TASK-004、脚本迁移 TASK-005 等），本任务只需建好目录骨架。
4. **验收标准 AC-1**：项目根目录存在 deploy 目录，且包含 env.json、env.example.json 与 scripts 子目录（env 与脚本由后续任务迁移后满足）；deploy 已存在时复用不覆盖。
5. **测试方法**：目录结构校验——检查项目根目录存在 deploy 目录且包含 scripts 子目录。
6. **依赖关系**：无上游依赖（upstream 为空），是 TASK-002~TASK-005 的前置任务（P0 优先级）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
