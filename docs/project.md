# 项目基本信息
**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（Maven 多模块后端）、Dart/Flutter（客户端）
**项目类型**：微服务企业办公套件（Spring Boot 3.2.5 + Spring Cloud 2023.0.1 + Spring Cloud Alibaba/Nacos 2.3.0 + MyBatis-Plus 3.5.6 + Spring Security + JWT RS256 + SpringDoc）
**本地化语言**：简体中文
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 构建的微服务企业办公套件，由认证服务（auth-service 9100）、企业服务（biz-service 9200）、系统服务（system-service 9400）、API 网关（gateway 9000）及公共模块（common）组成，提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力；当前版本 v0.1.6 已实现多模式登录/注册、RBAC 权限模型、JWT 双 Token、Redis 会话管理等。

# 数据库信息
**是否使用数据库**：是
**数据库产品**：MariaDB（主数据库）、Redis 7.2.x（缓存）
**数据库版本**：MariaDB 10.6 (LTS)

# 编码规范
## 文件组织规范
- 后端按 Maven 多模块组织：cloudoffice-common（公共模块）、cloudoffice-gateway（API 网关）、cloudoffice-auth-service（认证服务）、cloudoffice-biz-service（企业服务）、cloudoffice-system-service（系统服务）；公共代码统一放 cloudoffice-common，避免模块间循环依赖。
- 客户端代码按 Flutter 标准工程组织，位于 cloudoffice-flutter-app。
- 数据库脚本与 Docker 编排文件统一放 scripts 目录。
## 命名规范
- Java 后端遵循 Java 社区约定：包名全小写、类名 PascalCase、方法/变量 camelCase、常量 UPPER_SNAKE_CASE；服务类以 Service 结尾、控制器以 Controller 结尾、Mapper 以 Mapper 结尾。
- Flutter/Dart 客户端遵循 Dart 官方风格：文件/目录 snake_case、类名 PascalCase、变量/函数 camelCase。
- REST 接口路径统一为小写复数名词 + 资源层级，如 /api/v1/users。
## 代码风格
- Java 后端统一使用 checkstyle.xml 校验代码风格（项目根目录提供 checkstyle 配置），缩进 4 空格。
- Dart/Flutter 使用官方 dart format 风格，缩进 2 空格。
- 遵循 .editorconfig 统一各 IDE 的缩进、换行、编码设置。
## 注释规范
- 关键类、函数、复杂逻辑必须有简体中文注释；注释说明"为什么"而非"是什么"。
- 对外接口（Controller、Service）必须编写 Javadoc/DartDoc 说明用途与关键参数。
## 日志规范
- 统一日志级别（DEBUG/INFO/WARN/ERROR），关键业务路径（登录、认证、审批、支付等）必须记录日志。
- 禁止在日志中输出密码、Token、密钥、个人敏感信息。
## 测试规范
- 测试先行（TDD）：编码前先写测试用例，编码后测试必须全部通过。
- 后端单元测试与接口测试脚本按 impm 规范存放于 scripts 目录，测试用例文档由 impm 流程统一维护。
## 统一错误处理规范
- 后端统一错误码与错误信息格式，全局异常处理器统一封装错误响应，禁止吞异常。
- 认证/权限失败统一返回规范化的错误结构与 HTTP 状态码。
## 其他规范
- 禁止提交密钥、密码、环境变量等敏感信息（RSA 密钥存放于 keys/ 目录且已 gitignore；环境配置通过 env.json/env.example.json 管理）。
- 不提交日志与临时文件；不提交 node_modules、target、build 等构建产物。

# 项目地图
（由 impm-project-update 技能通过扫描源码目录自动维护，列出各源码目录与关键文件、函数、类的说明。）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
