# TASK-006 现有代码查询（cs.md）

## 1. 结论摘要
TASK-006（编译脚本更新 build-backend 纳入 common 产物）只需修改 **deploy/scripts/build-backend.ps1** 与 **deploy/scripts/build-backend.sh** 两个文件：
1. 脚本头部注释更新为包含 common 的 5 个服务说明；
2. 产物校验清单由 4 个 jar 扩展为 5 个 jar（新增 `cloudoffice-common.jar`）；
3. 完成输出汇总同时展示 5 个 jar。

**common 模块自身的 Maven 构建链路已由 TASK-002 完成**，无需本任务修改：
- `cloudoffice-common/pom.xml` 已配置 spring-boot-maven-plugin（classifier=exec，产出 `cloudoffice-common-exec.jar`）与 maven-antrun-plugin（`copy-final-jar-to-deploy` 执行段，package 阶段将 exec jar 复制为 `deploy/cloudoffice-common.jar`）。
- `CommonApplication.java` 启动类已存在（org.cloudstrolling.cloudoffice.common 包，@SpringBootApplication + @EnableDiscoveryClient）。
- 根 pom.xml `<modules>` 已含 cloudoffice-common，`mvn clean package` 默认全模块构建，common jar 自动落位 deploy。

## 2. 现有脚本分析

### 2.1 deploy/scripts/build-backend.ps1（67 行，待更新）
- 路径定位：基于 $PSScriptRoot 推导 ScriptDir → DeployDir → ProjectDir，无硬编码绝对路径。
- 前置检查：deploy 目录存在、mvn 命令可用。
- 构建命令：`mvn -f <root>/pom.xml clean package`，默认 `-DskipTests`，`-RunTests` 开关执行测试。
- **产物校验（第 53-61 行）**：`$Jars` 数组目前只有 4 个（gateway/auth/biz/system），需新增 `"cloudoffice-common.jar"`。
- **完成输出（第 63-67 行）**：遍历 $Jars 输出，新增后自动展示 5 个。
- 头部注释（第 3-7 行）描述"构建 gateway/auth/biz/system 四个服务"，需更新为"5 个服务（含 common）"。

### 2.2 deploy/scripts/build-backend.sh（72 行，待更新）
- set -euo pipefail；路径定位同 .ps1。
- 构建命令 `mvn "${MVN_ARGS[@]}"`（-f 根 pom clean package，默认 skipTests）。
- **产物校验（第 52-58 行）**：for 循环检查 4 个 jar，需新增 `cloudoffice-common.jar`。
- **完成输出（第 65-72 行）**：for 循环输出 4 个 jar，需新增 common。
- 头部注释（第 3-8 行）描述"构建 gateway/auth/biz/system 四个服务"，需更新为 5 个服务。

## 3. common 模块构建配置（TASK-002 已完成，仅参考）
- `cloudoffice-common/pom.xml`：
  - spring-boot-maven-plugin `<classifier>exec</classifier>` → 可执行 fat jar 以 `-exec.jar` 产出，主 artifact 仍为普通瘦 jar，保证下游依赖不被破坏。
  - maven-antrun-plugin execution id=`copy-final-jar-to-deploy`，phase=package，复制 `${project.build.directory}/${project.build.finalName}-exec.jar` → `${deployDir}/cloudoffice-common.jar`。
- `deployDir` 属性来自根 pom：`${maven.multiModuleProjectDirectory}/deploy`。
- 部署产物当前状态：deploy 目录已有 5 个 jar（gateway/auth/biz/system/common），common.jar 53443458 字节（2026-08-13 09:43 构建），证明 common 可执行 jar 构建链路已通。

## 4. 现有产物清单（deploy/）
| 产物 | 存在 | 说明 |
| --- | --- | --- |
| cloudoffice-gateway.jar | 是 | 55773876 字节 |
| cloudoffice-auth-service.jar | 是 | 75564418 字节 |
| cloudoffice-biz-service.jar | 是 | 58582097 字节 |
| cloudoffice-system-service.jar | 是 | 58582533 字节 |
| cloudoffice-common.jar | 是 | 53443458 字节（TASK-002 构建产物） |

## 5. 构建约定（deploy/build.md）
- 后端编译命令：`mvn clean package -DskipTests`（根目录），依次构建 5 个模块（common/gateway/auth/biz/system）。
- 产物唯一落点：deploy/（antrun 仅复制单个最终 jar，中间产物 target 不进入 deploy）。
- 便捷脚本 build-backend.ps1/.sh 与文档命令等价。
- v0.2.7 脚本体系约定：load-env 统一加载 env.json、输出分级（通过/警告/失败）、退出码失败非零、双平台行为一致。

## 6. 可复用模式
- build-backend 脚本采用"路径推导 + 前置检查 + mvn 构建 + 产物校验 + 汇总输出"结构，本任务沿用该结构，仅扩展 jar 清单与注释。
- 无需 load-env（编译脚本不依赖 env.json），无需引入新依赖或三方包。

## 7. 本任务不涉及的文件
- deploy/scripts/deploy-start-all、deploy-stop-all、deploy-start-common 等 → 由 TASK-007/TASK-008 负责。
- deploy/env.json、env.example.json → 由 TASK-009 负责。
- deploy/deploy.md、readme.md → 由 TASK-010 负责。
- cloudoffice-common 源码 → 由 TASK-003/TASK-004 负责。
