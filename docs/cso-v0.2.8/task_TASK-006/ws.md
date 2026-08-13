# TASK-006 网络资料查询（ws.md）

## 1. 结论摘要
TASK-006（build-backend 编译脚本更新）**不引入任何新三方包、中间件或 SDK**。脚本仅做产物清单扩展（4 个 jar → 5 个 jar），使用的工具链（Maven、spring-boot-maven-plugin、maven-antrun-plugin、PowerShell 5.1、Bash）均为项目既有依赖，无版本变更与兼容性风险。

## 2. 三方组件清单
| 组件 | 用途 | 项目内版本 | 是否需变更 | 结论 |
| --- | --- | --- | --- | --- |
| Maven | 多模块构建 | 3.8+（推荐 3.9.x，build.md §2） | 否 | 构建命令不变，仅校验清单扩展 |
| spring-boot-maven-plugin | 可执行 jar 打包 | 3.2.5（父 POM 托管） | 否 | common 模块已配置 classifier=exec（TASK-002） |
| maven-antrun-plugin | 产物复制到 deploy | 3.2.0（根 pom 托管） | 否 | common 已配置 copy-final-jar-to-deploy（TASK-002） |
| PowerShell / Bash | 脚本运行环境 | PS 5.1 / bash | 否 | 脚本语法沿用现有模式 |

## 3. 关键资料要点
### 3.1 maven-antrun-plugin 产物复制契约（本项目已有模式，无需引入新配置）
- 根 pom.xml `deployDir=${maven.multiModuleProjectDirectory}/deploy` 统一定位产物落点。
- 各服务模块在 package 阶段通过 maven-antrun-plugin 将 `${project.build.directory}/${project.build.finalName}.jar` 复制到 `deploy/cloudoffice-{svc}.jar`。
- common 模块（TASK-002 已配置）：复制 `-exec.jar`（可执行 fat jar）→ `deploy/cloudoffice-common.jar`，主 artifact 保留瘦 jar 保证下游 Maven 依赖不被破坏。
- 结论：build-backend 脚本**无需在脚本内执行复制**，jar 已由 Maven 构建自动落位 deploy；脚本只需在产物校验清单中纳入 cloudoffice-common.jar。

### 3.2 Maven 多模块构建行为
- `mvn clean package -DskipTests`（根目录执行）按 modules 声明顺序构建 common → gateway → auth → biz → system 全部 5 个模块。
- 因此 build-backend 脚本现有 `mvn -f <root>/pom.xml clean package` 命令无需改动即可产出 common jar。

### 3.3 脚本双平台契约（v0.2.7 约定，build.md §1.1 F-011）
- .ps1 与 .sh 行为一致：路径推导无硬编码、前置检查、输出分级、退出码失败非零。
- 产物校验失败退出码非零（.ps1 exit 1；.sh exit 1）。

## 4. 版本兼容性
无新增依赖，无版本兼容性问题。现有 Maven 3.8+ / Spring Boot 3.2.5 / antrun 3.2.0 均满足构建需求。

## 5. 相关任务资料
- 编译方案文档：deploy/build.md §4.1/§4.2（编译命令与产物清单）、§6（便捷脚本说明）、§1.1（v0.2.7 脚本体系约定）。
- 产物清单表 build.md §4.2 需在后续文档任务（TASK-010）中补充 common 行；本任务只改脚本。
- v0.2.7 脚本契约验证文档：docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md（.ps1/.sh 双平台契约自校验方法，可作为本任务脚本修改后的验证参考）。

## 6. 网络资料（官方文档索引）
- Maven 官方：https://maven.apache.org/guides/getting-started/index.html（多模块构建）
- spring-boot-maven-plugin：https://docs.spring.io/spring-boot/3.2/maven-plugin/index.html（classifier 可执行 jar 打包）
- maven-antrun-plugin：https://maven.apache.org/plugins/maven-antrun-plugin/（copy 任务）
- PowerShell 5.1 数组与字符串操作（本机运行时环境）
