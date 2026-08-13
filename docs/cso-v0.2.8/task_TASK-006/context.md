# TASK-006 需求上下文（context.md）

## 1. 任务信息
| 项 | 值 |
| --- | --- |
| 任务编号 | TASK-006 |
| 任务名称 | 编译脚本更新（build-backend 纳入 common 产物） |
| 任务描述 | 更新 build-backend 编译脚本（.ps1/.sh 双平台），在编译目标中新增 cloudoffice-common 模块，执行 mvn package 后生成可执行 jar（cloudoffice-common.jar）输出到 deploy 目录；遵循 v0.2.7 脚本体系约定（load-env 统一加载 env.json、输出分级通过/警告/失败、退出码失败非零、双平台行为一致）；不影响现有 gateway/auth/biz/system 编译产物输出。 |
| 用户故事 | US-005（编译脚本纳入 common 产物输出） |
| 功能编号 | F-007（编译脚本更新） |
| 任务类型 | common |
| 上游任务 | TASK-002（已完成：common 服务化改造） |
| 下游任务 | TASK-007（部署启动脚本）、TASK-008（部署停止脚本） |
| 优先级 | P0 |
| 测试方式 | 编译脚本验证 |
| 验收标准 | 执行 build-backend 后 deploy 目录存在 cloudoffice-common 可执行 jar；现有 gateway/auth/biz/system 产物输出不受影响；双平台行为一致、失败退出码非零。 |

## 2. 用户输入（需求原文）
1. cloudoffice-common 不仅包括公共的函数、变量定义，也包括公用的接口，因此也需要和其他微服务一样提供 api 服务。
2. 不仅需要修改 cloudoffice-common 的代码和配置，也需要修改编译和部署的脚本、部署文档和 readme.md、deploy-stop-all 脚本。
3. 在 deploy-start-all 脚本中，执行顺序在所有服务清单的第一位执行。
4. 在 cloudoffice-common 增加通用配置管理，统一配置不同微服务、不同业务场景下的所有配置工作；除启动的环境变量外，所有需要的配置都通过通用配置管理配置。
5. 当前这个任务只是配置的接口，后端管理后面会增加。

> 说明：用户输入覆盖 v0.2.8 整体需求，TASK-006 仅聚焦其中「编译脚本更新（build-backend 纳入 common 产物）」（对应用户输入第 2 点中"编译脚本"部分）。deploy-start-all / deploy-stop-all / 通用配置管理 / 文档更新分别由 TASK-007 / TASK-008 / TASK-004 / TASK-010 等并行任务处理。

## 3. 用户故事 US-005 验收标准
- [ ] Given common 模块服务化改造完成，When 执行 build-backend 脚本，Then cloudoffice-common jar 包生成并输出到 deploy 目录
- [ ] Given 编译脚本执行完成，When 检查 deploy 目录，Then 存在 common 服务的可执行 jar 包
- [ ] Given 编译脚本执行完成，When 检查现有 gateway/auth/biz/system 产物，Then 现有服务编译产物输出不受影响

边界情况：
| 场景 | 预期处理 |
| --- | --- |
| common 模块编译失败 | 输出编译错误信息，退出非零 |
| common jar 未输出到 deploy | 检查构建配置的产物输出路径 |
| 现有服务编译受影响 | 检查 common 模块变更是否影响公共依赖 |

## 4. 版本背景（v0.2.8）
- **目标 G-1 common 服务化**：cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务（端口 9300，ADR-017），具备 Nacos 服务注册、健康检查（/api/v1/common/health）、统一 ApiResult、SpringDoc OpenAPI 文档等能力；保留公共 jar 模块能力（ApiResult/PageResult/异常体系/枚举常量），下游服务（gateway/auth/biz/system）仍以 Maven 依赖方式引用 common。
- **目标 G-2 通用配置管理接口**：common 新增通用配置查询接口，统一管理五个微服务运行时配置（启动环境变量除外），本版本仅查询接口（ADR-018）。
- **目标 G-3 部署体系适配**：build-backend 将 common 纳入编译产物；deploy-start-all 中 common 居首、deploy-stop-all 中 common 居末（ADR-019）。
- **量化指标**：编译脚本将 cloudoffice-common 纳入产物输出范围，生成可部署 jar 包到 deploy 目录。

## 5. 关键设计约定（来自 SAD）
- **构建产物管理**：根目录 `deploy` 为最终构建产物唯一落点（Maven 各模块 package 生成的最终 jar 包，v0.2.8 新增 common jar）；构建中间产物（target 目录等）禁止进入 deploy。
- **脚本体系约束（v0.2.7 起）**：全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不硬编码环境地址与凭据；输出分级（通过/警告/失败）、退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致。
- **ADR-017 common 服务化改造**：common 新增启动类（@SpringBootApplication）、bootstrap.yml、application.yml（server.port=${COMMON_PORT:9300}），作为可执行 jar 构建。
- **common 服务化不得破坏现有模块依赖**：gateway/auth/biz/system 仍可依赖 common 公共类与接口。

## 6. 交付物
- deploy/scripts/build-backend.ps1（更新：纳入 cloudoffice-common 编译产物）
- deploy/scripts/build-backend.sh（更新：纳入 cloudoffice-common 编译产物）
- version_progress.md 进度记录（TASK-006 前缀）
