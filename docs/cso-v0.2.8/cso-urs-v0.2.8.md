# 用户需求说明书（URS）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：0.2.8
**日期**：2026-08-13
**编写人**：BA

## 1. 业务目标
- **G-001 common 服务化**：将 cloudoffice-common 从纯公共 jar 模块升级为可独立部署的微服务，提供通用配置管理等 API 接口服务，使其与其他微服务（gateway/auth/biz/system）具备同等的服务注册、健康检查与部署运维能力。
- **G-002 通用配置管理**：在 cloudoffice-common 中新增通用配置管理能力，统一管理不同微服务、不同业务场景下的所有配置项；除启动所需的环境变量（如 NACOS_ADDR、DB_PASSWORD、RSA 密钥等）外，所有运行时配置均通过通用配置管理接口进行读取与管理。
- **G-003 部署体系适配**：同步更新编译脚本、部署脚本（deploy-start-all、deploy-stop-all）、部署文档（deploy.md）与 readme.md，使 cloudoffice-common 作为独立服务纳入一键启动/停止流程，且在启动顺序中位于所有后端服务清单的第一位（最先启动）。
- **G-004 配置接口先行**：本版本仅交付通用配置管理的读取/查询接口能力，配置的后端管理界面（增删改）在后续版本迭代增加。

## 2. 用户角色
| 角色名称 | 角色说明 | 使用场景 |
| --- | --- | --- |
| 运维人员 | 负责部署运维与配置管理 | 通过部署脚本一键启动/停止全部服务（含 common）；通过通用配置管理接口查询各微服务、各业务场景的运行时配置项 |
| 后端开发者 | 各微服务开发人员 | 在业务代码中通过通用配置管理接口获取所需配置项，替代硬编码与分散的配置文件 |
| 系统管理员 | 平台系统管理 | 后续版本通过后端管理界面管理配置项（本版本仅接口先行，管理界面后续迭代） |

## 3. 业务场景
### 3.1 全服务一键部署启动
运维人员执行 deploy-start-all 脚本，脚本首先启动基础设施（Nacos/MariaDB/Redis），然后按 common → gateway → auth → biz → system 的顺序依次启动后端服务。cloudoffice-common 作为所有微服务的公共依赖与配置提供方，需在所有业务服务之前率先启动并完成健康确认，确保后续服务启动时可通过 Nacos 服务发现获取 common 的配置接口。

### 3.2 全服务一键停止
运维人员执行 deploy-stop-all 脚本，脚本按 system → biz → auth → gateway → common 的逆序停止全部后端服务，最后停止 Nacos 基础设施。cloudoffice-common 作为最后停止的服务，确保其他服务在停止过程中仍可访问配置接口。

### 3.3 运行时配置查询
后端开发者或运维人员通过通用配置管理 API 接口，按微服务名称与配置键（或配置分组）查询当前生效的配置项值。配置项覆盖不同微服务（gateway/auth/biz/system/common）在不同业务场景下的所有运行时配置，不包括启动环境变量（如 NACOS_ADDR、DB_PASSWORD、RSA 密钥等由 env.json 注入的启动参数）。

### 3.4 配置接口扩展预留
本版本交付通用配置管理的查询接口，后续版本将增加配置项的增删改管理接口与后端管理界面。当前接口设计需预留扩展能力，确保后续管理功能可平滑接入。

## 4. 功能需求（高层）
| 需求编号 | 需求名称 | 需求描述 | 优先级 |
| --- | --- | --- | --- |
| FR-001 | common 服务化改造 | 将 cloudoffice-common 从纯公共 jar 模块改造为可独立部署的 Spring Boot 微服务，增加启动类、bootstrap.yml（Nacos 注册/配置引导）、application.yml、健康检查端点等，使其可注册到 Nacos 并提供 API 服务 | 高 |
| FR-002 | common API 接口服务 | cloudoffice-common 提供与其他微服务一致的 API 服务能力，包括统一 ApiResult 响应、SpringDoc OpenAPI 文档、健康检查端点（/api/v1/common/health）等 | 高 |
| FR-003 | 通用配置管理-查询接口 | 提供通用配置管理的查询接口，支持按微服务名称、配置分组、配置键等维度查询运行时配置项；配置数据来源与存储方案由详细设计确定 | 高 |
| FR-004 | 通用配置管理-配置范围 | 通用配置管理覆盖所有微服务（gateway/auth/biz/system/common）在不同业务场景下的运行时配置；启动环境变量（NACOS_ADDR、DB_PASSWORD、RSA 密钥等）不纳入通用配置管理范围 | 高 |
| FR-005 | 通用配置管理-扩展预留 | 配置管理接口设计预留后续增删改管理能力，本版本仅实现查询接口，后端管理界面与写入接口在后续版本迭代 | 中 |
| FR-006 | 编译脚本更新 | 更新 build-backend 编译脚本，将 cloudoffice-common 纳入编译产物输出范围，生成可部署的 jar 包到 deploy 目录 | 高 |
| FR-007 | 部署启动脚本更新 | 更新 deploy-start-all 脚本（.ps1/.sh 双平台），在服务清单中将 cloudoffice-common 置于第一位（gateway 之前），按 common → gateway → auth → biz → system 顺序启动并逐服务健康确认 | 高 |
| FR-008 | 部署停止脚本更新 | 更新 deploy-stop-all 脚本（.ps1/.sh 双平台），在服务清单中增加 cloudoffice-common，按 system → biz → auth → gateway → common 逆序停止 | 高 |
| FR-009 | 部署文档更新 | 更新 deploy.md 部署文档，补充 cloudoffice-common 服务的端口分配、启动顺序、健康检查端点、环境变量等信息 | 高 |
| FR-010 | readme 更新 | 更新 readme.md，补充 cloudoffice-common 服务化说明与通用配置管理功能介绍 | 中 |
| FR-011 | env.json 配置更新 | 如需新增 cloudoffice-common 相关的环境配置项（如端口、Nacos 配置组等），同步更新 env.json 与 env.example.json | 高 |

## 5. 非功能需求（高层）
| 编号 | 类别 | 需求描述 | 指标 |
| --- | --- | --- | --- |
| NFR-001 | 性能 | 通用配置查询接口响应时间 | 单次查询 ≤ 200ms（本地缓存命中时 ≤ 50ms） |
| NFR-002 | 可用性 | cloudoffice-common 服务健康检查端点可用 | /api/v1/common/health 返回 200 |
| NFR-003 | 兼容性 | common 服务化改造不影响现有 gateway/auth/biz/system 对 common 公共模块的依赖关系 | 现有服务编译与运行不受影响 |
| NFR-004 | 可扩展性 | 通用配置管理接口设计支持后续增删改接口与管理界面的平滑扩展 | 接口层预留扩展点，数据层支持读写扩展 |
| NFR-005 | 部署一致性 | deploy-start-all/deploy-stop-all 双平台（.ps1/.sh）行为一致，输出分级与退出码约定统一 | 与 v0.2.7 脚本体系约定一致 |
| NFR-006 | 安全性 | 通用配置查询接口需经网关 AuthFilter 认证（非白名单端点），配置中敏感信息（如密码、密钥）不在查询接口返回 | 敏感配置项脱敏或排除 |

## 6. 约束条件
- **技术约束**：cloudoffice-common 服务化改造须基于现有技术栈（Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba 2023.0.1.0），须引入 spring-cloud-starter-bootstrap 依赖保证 Nacos 配置引导链路正常；不得引入与现有技术栈重复的第三方框架。
- **架构约束**：common 作为公共模块被 gateway/auth/biz/system 依赖，服务化改造后不得破坏现有模块依赖关系（下游服务仍可依赖 common 的公共类与接口）；common 服务自身注册到 Nacos，网关统一路由 /api/v1/common/**。
- **部署约束**：cloudoffice-common 的 jar 包须输出到 deploy 目录；deploy-start-all 中 common 须在服务清单第一位执行（所有后端服务中最先启动）；deploy-stop-all 中 common 须在所有后端服务中最后停止。
- **配置范围约束**：通用配置管理仅管理运行时配置，启动环境变量（NACOS_ADDR、DB_PASSWORD、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、NACOS_HOME 等）不纳入通用配置管理范围，仍由 env.json 环境变量注入。
- **版本范围约束**：本版本仅交付配置查询接口，不包含配置增删改接口与后端管理界面。
- **脚本体系约束**：部署脚本更新须遵循 v0.2.7 脚本体系约定（load-env 统一加载 env.json、输出分级通过/警告/失败、退出码失败非零、.ps1 与 .sh 双平台行为一致）。

## 7. 假设与依赖
- **假设**：cloudoffice-common 服务化后分配独立端口（具体端口由详细设计确定，建议在 9300 或其他未占用端口）。
- **假设**：通用配置管理的配置数据存储方案（数据库表或 Nacos 配置中心或 Redis 缓存）由详细设计阶段确定，本 URS 不限定存储方案。
- **假设**：通用配置管理接口经网关路由 /api/v1/common/** 转发，需在网关路由配置中新增 common 路由规则。
- **依赖**：cloudoffice-common 服务化依赖 Nacos 注册中心与配置中心正常运行。
- **依赖**：通用配置管理接口依赖网关 AuthFilter 认证体系（非白名单端点需携带合法 Bearer Token）。
- **依赖**：现有 gateway/auth/biz/system 服务对 common 公共模块的 Maven 依赖关系不受服务化改造影响。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->