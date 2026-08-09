# 任务上下文（#TASK-006 构建验证与 deploy 目录纯净性/完整性校验）

## 1. 任务信息

```json
{
  "id": "TASK-006",
  "title": "构建验证与 deploy 目录纯净性/完整性校验",
  "description": "整体验收：执行 Maven 各模块 package 与 Flutter 客户端构建，逐项校验 deploy 目录结构与内容——deploy 及 deploy/scripts 存在；4 个后端最终 jar 与客户端安装产物落位；deploy 内无 target 类中间目录、编译临时文件、测试产物、构建缓存；根目录不再保留 env.json/env.example.json；scripts 下 21 个 sh/ps1 全部位于 deploy/scripts 且非脚本内容未迁移；deploy/scripts 下脚本冒烟执行通过（load-env → deploy-check-env）。校验结果记录至版本测试用例文档，全部通过方可交付。对应 PRD AC-1~AC-7 全覆盖。",
  "taskType": "common",
  "userStoryId": "US-001,US-002,US-003",
  "apiId": "",
  "upstreamTaskIds": ["TASK-002", "TASK-003", "TASK-004", "TASK-005"],
  "downstreamTaskIds": [],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "全量验收校验：AC-1~AC-7 逐项核对（目录结构、构建产物落位、纯净性、迁移完整性、脚本可执行性）",
  "acceptanceCriteria": "AC-1~AC-7 全部通过：deploy 目录结构完整（含 env 两文件与 scripts 子目录）；4 个后端 jar 与客户端安装产物落位 deploy；无中间产物混入；根目录不残留 env 文件与已迁移脚本；deploy/scripts 脚本冒烟可执行"
}
```

## 2. 用户需求（PRD 用户故事）

### 本次版本用户输入（原始需求）
本次修改的版本为 cso-v0.2.5。修改内容如下：
1. 新建一个目录 deploy；
2. 修改配置，将所有模块生成的最终产物，比如 jar 包，安装文件，exe 文件啥的，都最终生成到 deploy 目录下（注意：生成阶段的中间产物不要复制过去）；
3. env.json 和 env.example.json 迁移到这个目录；
4. deploy 目录下建 scripts 子目录，将目前 scripts 下所有的 sh 和 ps1 迁移到这个子目录。

### US-001：建立统一的部署资产目录
- 作为发布/交付人员，希望项目根目录下有一个统一的 deploy 目录集中存放最终产物与部署资产，一次性收集全部可交付内容。
- 验收标准：根目录存在 deploy 目录；包含 env.json、env.example.json 与 scripts 子目录；构建完成后 deploy 不出现任何中间产物。
- 边界情况：deploy 目录已存在时复用现有目录，不重复创建、不覆盖已有有效内容；构建失败时不落盘失败产物。
- 关联功能：F-001、F-004。

### US-002：最终构建产物统一输出到 deploy
- 作为后端/客户端开发工程师，希望构建后的最终产物（jar 包、安装文件/exe）自动输出到 deploy 目录。
- 验收标准：Maven 各模块 package 成功后，四个后端服务的最终 jar 包出现在 deploy 目录；Flutter 客户端构建成功后，安装文件/exe 等最终产物出现在 deploy 目录；deploy 内无中间产物混入（target 类目录、编译临时文件、测试产物均不在其中）。
- 边界情况：同名 jar 产物需保持模块可辨识命名，不发生覆盖；构建配置仅复制最终产物文件，不整目录递归复制。
- 关联功能：F-002、F-003、F-004。

### US-003：环境配置与部署脚本统一迁移到 deploy
- 作为运维/部署工程师，希望 env.json/env.example.json 与全部 .sh/.ps1 脚本统一位于 deploy 目录下。
- 验收标准：迁移后 env.json、env.example.json 不在项目根目录而在 deploy 目录；全部 .sh/.ps1 已迁移至 deploy/scripts，根目录 scripts 下不再保留；scripts 下非脚本内容（docker、sql、API-TEST、部署指南等）未被移动；迁移后部署脚本可正常运行，env.json 加载正常。
- 边界情况：脚本内路径引用旧位置时同步更新为 deploy 下新路径；scripts 下非 sh/ps1 文件保持原位置不迁移。
- 关联功能：F-005、F-006、F-007。

## 3. 项目信息

- **项目中文名称**：云漫智企；**英文名称**：CloudStrollOffice；**英文缩写**：cso。
- **项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）。
- **技术栈**：后端 Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba 2023.0.1.0；客户端 Flutter（Dart 3，SDK ^3.12.2）；MariaDB 10.6 / Redis 7.2 / Nacos 2.3。
- **后端模块**：cloudoffice-common（公共）、cloudoffice-gateway（网关 :9000）、cloudoffice-auth-service（认证 :9100）、cloudoffice-biz-service（企业 :9200）、cloudoffice-system-service（系统 :9400）。
- **客户端**：cloudoffice-flutter-app（独立工程，Web + Windows 双平台）。
- **根目录关键文件与目录（迁移前）**：
  - `pom.xml` — Maven 父 POM；`checkstyle.xml` / `.editorconfig` — 代码规范。
  - `env.json` / `env.example.json` — 环境变量配置（数据库、Redis、RSA 密钥等），v0.2.5 迁移至 `deploy/`。
  - `keys/` — RSA 密钥对存放目录（敏感，不入库）。
  - `scripts/` — 部署脚本（deploy-*.ps1/sh）、SQL 脚本（sql/）、Docker 编排（docker/）、API 测试脚本（API-TEST/）；v0.2.5 将全部 .sh/.ps1 迁移至 `deploy/scripts/`，非脚本内容（docker、sql、API-TEST 等）不迁移。
  - `docs/` — 项目文档目录。
- **相关约定**：禁止提交密钥、密码等敏感信息；提交信息遵循 Conventional Commits；数据库脚本放 scripts/sql/、Docker 编排放 scripts/docker/、部署脚本放 scripts/（v0.2.5 起部署脚本位于 deploy/scripts/）。

## 4. 系统架构相关（SAD 摘录）

### G-A6 部署资产集中化（本任务直接相关设计目标）
以根目录 `deploy` 为全部最终构建产物（后端微服务 jar 包、客户端安装文件/exe）与部署资产（env.json/env.example.json、deploy/scripts 下 .sh/.ps1 部署运维脚本）的唯一落点，实现"产物集中、纯净交付、迁移无损"；构建中间产物（target 目录、编译临时文件、测试产物）一律不进入 deploy。

### 部署资产约束（SAD 1.2）
- 最终构建产物（后端各服务 jar 包、客户端安装文件/exe）统一输出至根目录 `deploy` 目录。
- 环境配置 `env.json`/`env.example.json` 与部署运维脚本（`deploy/scripts` 下的 .sh/.ps1）集中存放于 deploy 下。
- 构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy。
- 迁移后脚本内环境配置/密钥/产物路径引用必须同步适配，保证部署功能不因路径变化失效。

### 构建产物管理技术选型（SAD 2）
Maven 构建插件（如 maven-antrun-plugin/copy 插件）+ Flutter 构建脚本：将各模块最终产物（后端 jar 包、客户端安装文件/exe）集中输出到根目录 `deploy`，仅复制最终产物、隔离中间产物，交付人员单目录获取全部可交付资产。

### 部署架构（SAD 6 部署资产说明，v0.2.5 起）
根目录 `deploy` 为最终构建产物与部署资产的唯一落点——Maven 各模块 package 生成的最终 jar 包与 Flutter 客户端构建生成的安装文件/exe 均输出到 `deploy` 目录；`env.json`/`env.example.json` 环境配置与 `deploy/scripts` 下全部 .sh/.ps1 部署运维脚本集中存放；构建中间产物禁止进入 deploy；`deploy/scripts` 脚本内部对 env.json、密钥文件（keys）、jar 包等路径引用随迁移同步适配。

### ADR-013 构建产物与部署资产集中化（2026-08-09）
新建根目录 `deploy` 作为全部最终构建产物唯一落点（后端 jar 包、客户端安装文件/exe）；`env.json`/`env.example.json` 迁移至 deploy；scripts 下全部 .sh/.ps1 迁移至 `deploy/scripts` 并同步适配路径引用；构建中间产物禁止进入 deploy。理由：产物集中、纯净交付、迁移无损；发布/交付人员单目录收集全部可交付资产；源代码与运行/部署资产清晰分离，部署运维入口统一。

## 5. 版本验收标准（PRD 第 7 节，本任务全覆盖 AC-1~AC-7）

- **AC-1**：项目根目录存在 `deploy` 目录，且包含 `env.json`、`env.example.json` 与 `scripts` 子目录。
- **AC-2**：执行 Maven 各模块 `package` 后，auth-service、biz-service、system-service、gateway 的最终 jar 包出现在 `deploy` 目录。
- **AC-3**：执行 Flutter 客户端构建后，安装文件/exe 等最终产物出现在 `deploy` 目录。
- **AC-4**：构建完成后，`deploy` 目录内不出现 target 类中间目录、编译临时文件、测试产物等中间产物。
- **AC-5**：项目根目录不再保留 `env.json`、`env.example.json`；两文件已在 `deploy` 目录中。
- **AC-6**：根目录 `scripts` 下的全部 .sh/.ps1 文件已迁移至 `deploy/scripts`，根目录 `scripts` 下不再保留已迁移的 .sh/.ps1；scripts 下非 sh/ps1 内容（docker、sql、API-TEST 等）未被迁移。
- **AC-7**：迁移后 `deploy/scripts` 下的脚本可正常执行，脚本内 env.json 等路径引用已同步更新，部署运维功能不受影响。

## 6. 上下游依赖与执行提示

- 上游任务：TASK-002（新建 deploy 目录与迁移 env/scripts 资产）、TASK-003（后端 jar 产物输出到 deploy）、TASK-004（客户端产物输出到 deploy）、TASK-005（部署脚本路径适配与可执行性改造）——均需已完成。
- 本任务为 P0 整体验收任务，无下游任务；验收结果须记录至版本测试用例文档，全部通过方可交付。
- 校验要点：deploy 及 deploy/scripts 存在；4 个后端最终 jar 与客户端安装产物落位；deploy 内无 target 类中间目录、编译临时文件、测试产物、构建缓存；根目录不再保留 env.json/env.example.json；scripts 下 21 个 sh/ps1 全部位于 deploy/scripts 且非脚本内容未迁移；deploy/scripts 下脚本冒烟执行通过（load-env → deploy-check-env）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
