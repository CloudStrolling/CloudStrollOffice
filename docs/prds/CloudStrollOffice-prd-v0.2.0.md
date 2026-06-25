# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.2.0
**日期：** 2026-06-24

---

## 1. 产品概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）已完成后端微服务基础架构建设（v0.1.0 ~ v0.1.7），涵盖认证服务、API 网关等核心能力。然而项目目前缺少面向最终用户的前端应用，所有后端 API 能力无法通过用户界面直接使用。v0.2.0 旨在创建 Flutter 前端子项目，作为云漫智企的用户入口，使普通用户能够通过 Web 浏览器或 Windows 桌面应用完成注册、登录、找回密码等基础认证操作。

### 1.2 产品目标

- **目标 1：** 在项目根目录下创建 `cloudoffice-flutter-app` Flutter 前端子项目，支持 Web（Chrome）和 Windows（VS2022）双平台构建运行
- **目标 2：** 实现用户注册、登录、找回密码三大认证功能的前端页面，与后端认证 API 端到端对接，形成完整的用户认证闭环

### 1.3 核心设计理念

- **分层解耦**：UI 层（Screen）↔ 状态管理层（Provider）↔ 数据仓库层（Repository）↔ HTTP 客户端层（ApiClient）严格分层，各层职责单一、可独立测试
- **平台一致**：同一套 Dart 代码在 Web 和 Windows 双平台运行表现一致，不引入平台特定代码（除非绝对必要），保持跨平台代码统一

### 1.4 术语表（Glossary）

| 术语 | 英文 | 定义 |
|------|------|------|
| 访问令牌 | access_token | 短时效 JWT Token（默认 30 分钟），用于 API 请求鉴权 |
| 刷新令牌 | refresh_token | 长时效 JWT Token（默认 7 天），用于获取新的 access_token |
| Token 对 | TokenPairDTO | access_token + refresh_token 的集合，由登录/注册 API 返回 |
| 安全存储 | Secure Storage | 使用 `flutter_secure_storage` 实现的敏感数据持久化方案 |
| 统一响应体 | ApiResult | 后端统一响应格式，包含 code/message/data/timestamp |
| 网关 | Gateway | API 网关（端口 9000），前端所有请求通过网关转发到后端微服务 |

---

## 2. 目标用户

| 用户角色 | 使用场景 | 核心诉求 |
|---------|---------|---------|
| 未认证访客 | 首次访问云漫智企，需要注册账号或登录已有账号 | 快速完成注册/登录，便捷找回密码 |
| 已认证用户 | 已登录用户访问系统首页 | 查看个人信息，退出登录，为后续业务功能提供导航基础 |

---

## 3. 用户故事（User Stories）

### US-001: Flutter 子项目创建与双平台构建

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-001（Flutter 子项目创建与双平台构建）

#### 故事描述
- **作为** 项目开发者
- **我想要** 在项目根目录下创建 `cloudoffice-flutter-app` Flutter 子项目并配置 Web 和 Windows 双平台构建支持
- **以便** 后端团队成员能够理解前端项目结构，并确保双平台的前端应用可正常构建运行

#### 前置条件
- Flutter SDK 3.x 已安装于 `D:\jenemy\develop\flutter`，且 `flutter doctor` 全部通过
- Chrome 浏览器已安装，支持 Flutter Web 调试
- Visual Studio 2022 已安装，包含"使用 C++ 的桌面开发"工作负载
- Dart SDK 环境变量已正确配置

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 项目根目录下尚未存在 Flutter 项目，When 执行 `flutter create cloudoffice-flutter-app`，Then 在项目根目录下生成完整的 Flutter 项目目录结构
- [ ] **AC2：** Given `cloudoffice-flutter-app` 目录已创建，When 执行 `flutter build web`，Then 构建成功并在 `build/web/` 目录输出静态资源
- [ ] **AC3：** Given `cloudoffice-flutter-app` 目录已创建，When 执行 `flutter build windows`，Then 构建成功并在 `build/windows/runner/Release/` 目录输出可执行文件
- [ ] **AC4：** Given Flutter 子项目已创建，When 检查 `pubspec.yaml` 中的项目名称，Then 项目名称为 `cloudoffice_flutter_app`（Dart 包命名规范），description 包含"云漫智企"或"CloudStrollOffice"描述
- [ ] **AC5：** Given Flutter 子项目已创建，When 检查项目目录结构，Then 存在 `lib/config/`、`lib/core/`、`lib/features/`、`lib/shared/` 等分层目录
- [ ] **AC6：** Given 项目已创建，When 检查 `analysis_options.yaml`，Then 已配置 Dart 静态分析规则

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `flutter create` 时目标目录已存在 | Flutter CLI 报错提示"目标目录已存在"，需手动删除或指定其他目录 |
| `flutter build web` 时缺少 Web 平台支持 | 提示运行 `flutter config --enable-web`，配置后重新构建 |
| `flutter build windows` 时缺少 VS2022 构建工具 | `flutter doctor` 检测到 Windows 桌面开发工具链缺失，提示安装 VS2022 及"使用 C++ 的桌面开发"工作负载 |
| Flutter SDK 版本不满足最低要求 | `flutter create` 或 `flutter pub get` 时提示 SDK 版本约束不满足，需升级 Flutter SDK 至 3.x |

#### 交付物
- `cloudoffice-flutter-app/` — Flutter 子项目根目录
- `cloudoffice-flutter-app/pubspec.yaml` — 项目依赖与元信息配置
- `cloudoffice-flutter-app/analysis_options.yaml` — Dart 静态分析规则配置

#### 备注
- Flutter 项目命名使用 `cloudoffice_flutter_app`（Dart 包命名规范：下划线命名），但目录名保持 `cloudoffice-flutter-app`（与后端模块中划线命名风格统一）
- `flutter doctor -v` 需确认所有平台工具链正常后再开始开发

---

### US-002: Flutter 项目依赖与配置

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-002（Flutter 项目依赖与配置）

#### 故事描述
- **作为** 项目开发者
- **我想要** 配置 Flutter 项目的核心依赖库、开发环境配置和构建配置
- **以便** 为后续功能开发阶段和双平台构建提供依赖环境和工具链保障

#### 前置条件
- US-001（Flutter 子项目创建与双平台构建）已完成
- `cloudoffice-flutter-app` 目录已存在且可正常执行 Flutter 命令

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `pubspec.yaml` 文件已存在，When 检查 dependencies 和 dev_dependencies 配置，Then 已包含 `dio: ^5.x`、`provider: ^6.x`、`flutter_secure_storage: ^9.x`、`go_router: ^14.x`、`flutter_lints: ^5.x`、`mockito: ^5.x` 等核心依赖
- [ ] **AC2：** Given `pubspec.yaml` 已配置所有核心依赖，When 执行 `flutter pub get`，Then 无错误输出，所有依赖成功下载
- [ ] **AC3：** Given 依赖已成功获取，When 执行 `flutter analyze`，Then 零错误、零警告
- [ ] **AC4：** Given `web/index.html` 文件已存在，When 检查文件内容，Then title 和 meta 信息已配置为云漫智企相关内容
- [ ] **AC5：** Given `windows/` 目录已存在，When 检查 VS2022 构建配置文件，Then `CMakeLists.txt` 和 `runner/` 目录下的配置正确
- [ ] **AC6：** Given `pubspec.yaml` 已配置，When 检查 Flutter SDK 版本约束，Then `environment.sdk` 设置为 `>=3.0.0 <4.0.0`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `flutter pub get` 时网络不可用 | 提示网络错误，显示失败原因，依赖未下载时编译不通过 |
| 某个依赖版本冲突 | `flutter pub get` 输出版本冲突详情，需手动调整版本号 |
| `flutter analyze` 检测出代码规范问题 | 输出具体警告/错误信息及文件位置，需修正后再提交 |
| `flutter_secure_storage` Web 平台兼容性 | Web 平台使用 `flutter_secure_storage_web` 子插件，回退到 localStorage 方案 |

#### 交付物
- `cloudoffice-flutter-app/pubspec.yaml` — 完整依赖配置
- `cloudoffice-flutter-app/web/index.html` — Web 平台入口 HTML
- `cloudoffice-flutter-app/windows/` — Windows 平台 VS2022 构建配置

#### 备注
- 所有第三方依赖版本建议锁定到具体次版本号（如 `^5.4.0`），避免大版本自动升级导致不兼容
- `flutter_secure_storage` 在 Web 平台存在安全性局限（回退到 localStorage），后续可评估是否需要增强方案
- `mockito` 需要配合 `build_runner` 使用

---

### US-003: 统一 HTTP 客户端封装

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-003（统一 HTTP 客户端封装）

#### 故事描述
- **作为** 前端开发者
- **我想要** 基于 Dio 封装统一的 HTTP 客户端，提供请求/响应拦截器、Token 自动注入、Token 自动刷新和统一错误处理能力
- **以便** 后续所有功能模块复用同一套 HTTP 通信基础设施，无需重复处理鉴权、错误转换等横切关注点

#### 前置条件
- US-002（Flutter 项目依赖与配置）已完成
- `dio` 依赖已通过 `flutter pub get` 成功安装
- `flutter_secure_storage` 依赖已安装

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given ApiClient 类已实现，When 获取 ApiClient 单例实例，Then 基础 URL 配置为 `http://localhost:9000`，连接超时 15 秒，读取超时 30 秒，默认请求头包含 `Content-Type: application/json`
- [ ] **AC2：** Given 安全存储中已存在有效的 `access_token`，When ApiInterceptor 的请求拦截器拦截到需认证的 HTTP 请求，Then 自动在请求头注入 `Authorization: Bearer {token}`
- [ ] **AC3：** Given 后端返回 401 状态码（access_token 过期），When 响应拦截器检测到 401，Then 自动使用 `refresh_token` 调用 `/api/v1/auth/refresh` 获取新的 Token 对，并将原始请求重放
- [ ] **AC4：** Given Token 刷新失败（refresh_token 也已过期），When 响应拦截器处理 401 失败，Then 清除本地安全存储中的 Token 数据，通过路由跳转到登录页面
- [ ] **AC5：** Given 发生网络异常（SocketException/TimeoutException），When ApiClient 发送请求失败，Then 统一返回友好提示"网络异常，请检查网络连接"
- [ ] **AC6：** Given 后端返回 5xx 服务器错误，When ApiClient 收到响应，Then 统一返回友好提示"服务器繁忙，请稍后重试"

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 安全存储中 Token 为空，发送非认证请求 | 请求拦截器不注入 `Authorization` 头，请求正常发送 |
| Token 刷新请求自身返回 401 | 不进入递归刷新流程，直接清除 Token 并跳转登录页 |
| 多个并发请求同时触发 401 导致重复刷新 | 实现 Token 刷新锁机制，仅第一个请求触发刷新，后续 401 请求等待刷新完成后重放 |
| 网络断开后重连成功 | 重新发送请求，自动恢复 Token 注入机制 |
| 后端返回业务错误码（code ≠ 200） | 响应拦截器不解体业务错误，交由上层（Repository/Provider）处理 |
| 刷新 Token 时接口返回其他业务错误 | 按业务错误处理策略，不清除 Token，返回错误消息 |

#### 交付物
- `lib/core/http/api_client.dart` — Dio 实例封装（单例模式）
- `lib/core/http/api_interceptor.dart` — 请求/响应拦截器
- `lib/core/http/api_result.dart` — 统一响应模型（泛型 `ApiResult<T>`）
- `lib/core/storage/secure_storage.dart` — 安全存储封装

#### 备注
- Token 刷新需实现并发锁机制，防止短时间内多个请求同时触发 Token 刷新
- ApiResult 泛型需支持 Dart 的 `fromJson` 工厂构造函数，兼容 `json_serializable`
- 拦截器中需注意避免死循环（Token 刷新请求本身的 401 不应触发再次刷新）

---

### US-004: Auth API 数据仓库

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-004（Auth API 数据仓库）

#### 故事描述
- **作为** 前端开发者
- **我想要** 封装认证相关的后端 API 调用逻辑到 AuthRepository 中，将 HTTP 请求抽象为可调用的 Repository 方法
- **以便** 页面和状态管理层（Provider）可以简洁地调用认证功能，无需关心 HTTP 请求细节

#### 前置条件
- US-003（统一 HTTP 客户端封装）已完成
- API 配置（baseUrl、超时等）已就绪
- 后端认证服务的 API 端点已明确

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given AuthRepository 类已实现，When 调用 `login(LoginRequest)` 方法，Then 向 `POST /api/v1/auth/login` 发送请求并返回 `Future<ApiResult<TokenPairDTO>>`
- [ ] **AC2：** Given AuthRepository 类已实现，When 调用 `register(RegisterRequest)` 方法，Then 向 `POST /api/v1/auth/register` 发送请求并返回 `Future<ApiResult<RegisterResult>>`
- [ ] **AC3：** Given AuthRepository 类已实现，When 调用 `sendVerificationCode(target, purpose, mode)` 方法，Then 向 `POST /api/v1/auth/verification-code/send` 发送请求并返回 `Future<ApiResult<Void>>`
- [ ] **AC4：** Given AuthRepository 类已实现，When 调用 `forgotPasswordReset(mode, target, code, newPassword)` 方法，Then 向 `POST /api/v1/auth/password/forgot/reset` 发送请求并返回 `Future<ApiResult<Void>>`
- [ ] **AC5：** Given AuthRepository 类已实现，When 验证数据模型类，Then `LoginRequest`、`RegisterRequest`、`TokenPairDTO`、`RegisterResult` 等模型类的字段与后端 DTO 定义一致，且包含 `fromJson`/`toJson` 序列化方法
- [ ] **AC6：** Given DioException 在 API 调用中发生，When AuthRepository 捕获异常，Then 转换为业务层可理解的错误类型（业务错误码映射），不暴露原始 DioException

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 后端返回 `ApiResult` 中 code ≠ 200 | Repository 返回包含错误码和错误消息的 `ApiResult`，不抛出异常 |
| 发送验证码时目标手机号/邮箱格式无效 | Repository 不调用 API，直接返回格式校验错误 |
| Dio 请求超时（30 秒无响应） | Repository 捕获 TimeoutException，返回"请求超时，请稍后重试"错误 |
| 后端返回未知格式的响应体 | Repository 尝试解析 JSON，失败后返回"服务器响应异常"错误 |
| Token 刷新请求失败（网络原因） | Repository 保留原 DioException 信息，转换为"网络异常，无法刷新登录状态" |

#### 交付物
- `lib/features/auth/repositories/auth_repository.dart` — AuthRepository 数据仓库类
- `lib/features/auth/models/login_request.dart` — 登录请求模型
- `lib/features/auth/models/register_request.dart` — 注册请求模型
- `lib/features/auth/models/token_pair.dart` — Token 对模型
- `lib/features/auth/models/register_result.dart` — 注册结果模型

#### 备注
- Repository 层仅负责数据转换和 API 调用，不处理 UI 逻辑
- 数据模型类建议使用 `freezed` 或手写 `fromJson`/`toJson` 工厂方法
- 所有 Repository 方法返回类型统一为 `Future<ApiResult<T>>`，上层通过 `ApiResult.isSuccess()` 判断成功/失败

---

### US-005: 用户登录页面

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-005（用户登录页面）

#### 故事描述
- **作为** 未认证访客
- **我想要** 在登录页面输入用户名和密码进行登录
- **以便** 通过身份验证后访问系统首页，享受系统提供的业务服务

#### 前置条件
- US-004（Auth API 数据仓库）已完成
- GoRouter 路由配置已就绪
- 后端网关和认证服务正常运行

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 未登录用户访问登录页面，When 页面加载完成，Then 显示应用 Logo、登录表单（登录名输入框、密码输入框、登录按钮）、"没有账号？去注册"和"忘记密码？"链接
- [ ] **AC2：** Given 用户已输入有效的登录名和密码，When 点击登录按钮，Then 按钮显示 loading 状态且禁用重复点击，调用 `AuthRepository.login()` API，登录成功后保存 TokenPair 到安全存储并跳转首页
- [ ] **AC3：** Given 用户输入了错误的登录名或密码，When 点击登录按钮，Then 登录失败后显示后端返回的错误信息（如"用户名或密码错误"），登录按钮恢复正常状态
- [ ] **AC4：** Given 用户已登录且 Token 有效，When 打开应用访问登录页路径，Then GoRouter 路由守卫自动跳转首页，不显示登录页
- [ ] **AC5：** Given 用户勾选了"记住我"复选框并登录成功，When 下次打开登录页，Then 登录名输入框自动填充上次保存的登录名
- [ ] **AC6：** Given 用户连续输入无效表单内容（登录名为空、密码长度不足），When 点击登录按钮，Then 前端表单校验拦截，显示具体校验错误提示，不调用 API

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 登录名输入为空 | 输入框下方显示"请输入登录名"红色错误提示，登录按钮不可用 |
| 密码长度小于 8 位 | 输入框下方显示"密码长度不能少于 8 位"红色错误提示 |
| 登录 API 返回"账户已被禁用"（AUTH-0002） | 页面显示错误提示"账户已被禁用，请联系管理员" |
| 登录 API 返回"验证码错误"（AUTH-0020） | 页面显示错误提示"验证码错误，请重新输入" |
| 登录时网络中断 | 页面显示"网络异常，请检查网络连接"，登录按钮恢复正常 |
| 已登录用户手动输入登录页 URL | GoRouter 路由守卫拦截，自动重定向到首页 |

#### 交付物
- `lib/features/auth/screens/login_screen.dart` — 登录页面 UI
- `lib/features/auth/providers/auth_provider.dart` — 登录状态管理
- `lib/shared/widgets/custom_text_field.dart` — 自定义输入框组件
- `lib/shared/widgets/password_field.dart` — 密码输入框组件（含显示/隐藏切换）
- `lib/shared/widgets/loading_button.dart` — 加载状态按钮组件

#### 备注
- Token 校验和路由守卫逻辑在 `app_router.dart` 中实现，与登录页面松耦合
- 登录页面的"记住我"功能仅保存登录名到本地存储（非安全存储），不保存密码
- Web 平台需注意 `flutter_secure_storage` 的兼容性

---

### US-006: 多模式登录支持

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-006（多模式登录支持）

#### 故事描述
- **作为** 未认证访客
- **我想要** 在登录页面切换使用手机验证码模式进行登录
- **以便** 我可以通过手机接收验证码快速完成登录，无需记忆密码

#### 前置条件
- US-005（用户登录页面）已完成
- 后端验证码发送 API（`/api/v1/auth/verification-code/send`）正常运行
- 后端手机验证码登录策略已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 登录页面已加载，When 页面顶部提供"密码登录"和"验证码登录"两个 Tab 切换按钮，Then "密码登录"为默认选中状态，"验证码登录"可切换
- [ ] **AC2：** Given 用户切换到"验证码登录"模式，When 页面渲染，Then 显示手机号输入框、获取验证码按钮、验证码输入框，密码输入框隐藏
- [ ] **AC3：** Given 用户在验证码登录模式下输入 11 位有效手机号，When 点击"获取验证码"按钮，Then 按钮显示"60 秒后重新获取"并开始倒计时，按钮禁用，调用 `sendVerificationCode` API
- [ ] **AC4：** Given 验证码倒计时正在进行，When 倒计时结束，Then 按钮恢复为"获取验证码"并重新可用
- [ ] **AC5：** Given 用户切换到"密码登录"模式再切回"验证码登录"，When 两种模式间切换，Then 已输入的内容（如手机号）保留
- [ ] **AC6：** Given 用户在验证码登录模式下输入有效手机号和验证码，When 点击登录按钮，Then 调用登录 API 时 `loginMode` 参数为 `SMS`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 手机号格式不正确（非 11 位数字） | 获取验证码按钮禁用，显示"请输入正确的手机号"错误提示 |
| 获取验证码频率超限（后端返回 AUTH-0022） | 显示"发送过于频繁，请稍后重试"，倒计时不启动 |
| 验证码输入不是 6 位数字 | 登录按钮禁用，提示"请输入 6 位数字验证码" |
| 切换 Tab 时正在倒计时 | 切换到验证码登录 Tab 时恢复倒计时状态 |
| 验证码登录 API 返回"验证码错误"（AUTH-0020） | 显示"验证码错误，请重新输入"，验证码输入框清空 |

#### 交付物
- `lib/features/auth/screens/login_screen.dart` — 更新：增加多模式 Tab 切换
- `lib/shared/widgets/verification_code_field.dart` — 验证码输入框组件
- `lib/config/api_config.dart` — 如有需要更新 API 配置

#### 备注
- 未来扩展点：页面底部预留 OAuth 第三方登录入口位置（微信/支付宝等），本期仅占位不可用
- 验证码倒计时使用 `Timer.periodic` 实现，注意页面销毁时释放 Timer 资源
- 各模式间切换保留已输入内容的实现方式：Provider 中维护各模式的表单状态

---

### US-007: 用户注册页面

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-007（用户注册页面）

#### 故事描述
- **作为** 未认证访客
- **我想要** 在注册页面输入用户名、真实姓名和密码创建新账号
- **以便** 拥有系统账户后可以登录并使用系统功能

#### 前置条件
- US-004（Auth API 数据仓库）已完成
- GoRouter 路由配置已就绪
- 后端注册 API（`/api/v1/auth/register`）正常运行

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 未登录用户访问注册页面，When 页面加载完成，Then 显示应用 Logo、"注册新账号"标题、注册表单（用户名/真实姓名/密码/确认密码输入框）、注册按钮、"已有账号？去登录"链接
- [ ] **AC2：** Given 用户输入有效的注册信息（用户名 4-64 字符字母数字下划线、真实姓名 2-50 字符、密码 8-64 字符且满足强度要求、确认密码一致），When 点击注册按钮，Then 按钮显示 loading 状态，调用 `AuthRepository.register()` API，注册成功后保存 Token 并跳转首页或登录页
- [ ] **AC3：** Given 用户输入的用户名已存在（后端返回 AUTH-0005），When 注册 API 调用失败，Then 页面显示"该用户名已被注册"错误提示，注册按钮恢复正常
- [ ] **AC4：** Given 用户输入密码时，When 密码输入框内容变化，Then 下方实时显示密码强度指示器（弱/中/强三级）
- [ ] **AC5：** Given 用户输入了不符合规则的表单项（如用户名含特殊字符、密码与确认密码不一致），When 用户从输入框移出焦点（onBlur），Then 对应输入框下方显示红色校验错误提示
- [ ] **AC6：** Given 注册成功后返回 TokenPairDTO，When 处理注册响应，Then 将 access_token 和 refresh_token 保存到安全存储

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 用户名包含特殊字符（如 @、#、空格） | onBlur 校验时提示"用户名仅允许字母、数字和下划线" |
| 密码强度为"弱"时提交注册 | 前端可提交（仅提示），密码强度不做强制阻塞 |
| 确认密码与密码不一致 | onBlur 校验时提示"两次输入的密码不一致" |
| 真实姓名为空或不足 2 字符 | 提示"真实姓名至少 2 个字符" |
| 注册 API 网络超时 | 显示"网络异常，请检查网络连接" |
| 注册成功但 Token 保存失败 | 提示"注册成功，但登录状态保存失败，请前往登录页登录" |

#### 交付物
- `lib/features/auth/screens/register_screen.dart` — 注册页面 UI
- `lib/features/auth/providers/auth_provider.dart` — 更新：增加注册状态管理
- `lib/shared/widgets/password_strength_indicator.dart` — 密码强度指示器组件
- `lib/core/utils/validators.dart` — 表单校验工具函数

#### 备注
- 密码强度计算规则：弱（仅字母或仅数字，长度 < 10）、中（字母+数字，长度 < 12）、强（字母+数字+特殊字符，长度 >= 12）
- 用户名校验建议使用正则表达式：`^[a-zA-Z0-9_]{4,64}$`
- 注册成功后跳转首页还是登录页需确认产品策略——本版本默认跳转首页

---

### US-008: 多模式注册支持

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-008（多模式注册支持）

#### 故事描述
- **作为** 未认证访客
- **我想要** 在注册页面切换使用手机号验证码模式进行注册
- **以便** 我可以通过手机号快速注册账号，无需设置用户名

#### 前置条件
- US-007（用户注册页面）已完成
- 后端手机验证码注册策略已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 注册页面已加载，When 页面顶部提供"用户名注册"和"手机号注册"两个 Tab 切换按钮，Then "用户名注册"为默认选中状态
- [ ] **AC2：** Given 用户切换到"手机号注册"模式，When 页面渲染，Then 显示手机号输入框、真实姓名输入框、获取验证码按钮、验证码输入框、密码输入框和确认密码输入框隐藏
- [ ] **AC3：** Given 用户在手机号注册模式下输入 11 位有效手机号和真实姓名，When 点击"获取验证码"按钮，Then 调用 `sendVerificationCode` API（purpose=REGISTER），按钮进入 60 秒倒计时
- [ ] **AC4：** Given 用户输入有效手机号、验证码和真实姓名，When 点击注册按钮，Then 调用注册 API 时 `registerMode` 参数为 `PHONE`，注册成功后保存 Token 并跳转首页
- [ ] **AC5：** Given 用户在"用户名注册"和"手机号注册"之间切换，When 切换 Tab，Then 公共字段（真实姓名）的输入内容保留，私有字段（用户名/密码 或 手机号/验证码）重置
- [ ] **AC6：** Given 手机号注册模式下手机号格式错误，When 用户点击注册按钮，Then 前端校验拦截，显示"请输入正确的手机号"提示

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 手机号已被其他账号绑定 | 注册 API 返回相关错误码，页面显示"该手机号已被注册" |
| 验证码错误或已过期 | 显示"验证码错误，请重新获取" |
| 验证码发送失败 | 倒计时重置，按钮恢复，显示"验证码发送失败，请稍后重试" |
| 从手机号模式切回用户名模式时 | 真实姓名保留，手机号/验证码清空 |
| 手机号注册模式下密码字段不存在 | 注册成功后直接返回 TokenPairDTO（后端按 PHONE 模式处理） |

#### 交付物
- `lib/features/auth/screens/register_screen.dart` — 更新：增加多模式注册 Tab 切换

#### 备注
- 手机号注册模式可能不需要密码，需与后端确认 PHONE 模式的注册逻辑
- 手机号注册成功后如果后端返回的是未补全的账户（`accountSettled=false`），需后续版本支持账号补全功能
- 验证码组件可与 US-006 的验证码输入框组件复用

---

### US-009: 找回密码页面

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-009（找回密码页面）

#### 故事描述
- **作为** 未认证访客
- **我想要** 在忘记密码时通过手机或邮箱验证码重置我的密码
- **以便** 无需联系管理员即可自助恢复账号访问权限

#### 前置条件
- US-004（Auth API 数据仓库）已完成
- 后端密码找回相关 API（send-code / reset）正常运行
- 验证码发送服务正常

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 未登录用户访问找回密码页面，When 页面加载完成，Then 显示"找回密码"标题、步骤指示器（Step 1: 身份验证 → Step 2: 重置密码）、"返回登录"链接
- [ ] **AC2：** Given 用户处于第一步（身份验证），When 用户输入有效手机号/邮箱，选择验证方式（短信/邮箱），获取验证码并输入正确的 6 位验证码，Then 点击"下一步"按钮后进入第二步（重置密码）
- [ ] **AC3：** Given 用户处于第二步（重置密码），When 用户输入新密码（8-64 字符）和确认新密码且两者一致，点击"重置密码"按钮，Then 调用 `forgotPasswordReset` API，重置成功后显示成功提示并自动跳转登录页（3 秒倒计时）
- [ ] **AC4：** Given 用户在第一步点击"获取验证码"按钮，When 验证码发送成功，Then 按钮进入 60 秒倒计时，显示"X 秒后重新获取"，按钮禁用
- [ ] **AC5：** Given 用户在新密码输入框输入密码，When 密码长度变化，Then 显示密码强度指示器（弱/中/强）
- [ ] **AC6：** Given 用户完成密码重置，When 3 秒倒计时结束前，Then 页面显示"密码重置成功，X 秒后自动跳转登录页"并倒计时

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 手机号/邮箱未注册（后端返回 AUTH-0012） | 第一步显示"该账号不存在"提示 |
| 验证码输入错误（后端返回 AUTH-0020） | 第一步显示"验证码错误，请重新输入" |
| 新密码与确认密码不一致 | 第二步显示"两次输入的密码不一致" |
| 新密码与旧密码相同（后端返回 AUTH-0032） | 第二步显示"新密码不能与旧密码相同" |
| 重置密码 API 网络超时 | 显示"网络异常，请检查网络连接"，按钮恢复正常 |
| 用户在第二步点击浏览器的返回按钮 | 可回到第一步重新验证（需确认产品策略是否支持回退） |
| 验证码已过期（后端返回 AUTH-0021） | 显示"验证码已过期，请重新获取" |

#### 交付物
- `lib/features/auth/screens/forgot_password_screen.dart` — 找回密码页面 UI（两步流程）
- `lib/features/auth/providers/forgot_password_provider.dart` — 找回密码状态管理

#### 备注
- 两步流程中第一步的验证状态（验证码已验证）需在 Provider 中维护，切换第二步时携带验证凭据
- 步骤间过渡建议使用 PageView 或 AnimatedSwitcher 实现平滑动画
- 密码强度指示器可复用 US-007 中的 `PasswordStrengthIndicator` 组件
- 验证码场景的倒计时组件可复用 US-006 中的验证码倒计时逻辑

---

### US-010: 首页与导航框架

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.2.0.md`
需求编号：FR-010（首页/导航框架）

#### 故事描述
- **作为** 已认证用户
- **我想要** 登录后看到首页，展示我的个人信息，并可以退出登录
- **以便** 确认我已成功登录，并为后续业务功能页面提供导航基础框架

#### 前置条件
- US-005（用户登录页面）已完成
- GoRouter 路由表已配置首页路由
- 用户已登录且 Token 有效

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户已登录且 Token 有效，When 登录成功或应用启动，Then 默认跳转到首页（路由 `/`），页面顶部显示应用名称导航栏，主内容区域显示欢迎信息和用户基本信息（登录名、真实姓名）
- [ ] **AC2：** Given 用户在首页，When 点击顶部导航栏中的"退出登录"按钮，Then 显示确认对话框，确认后调用 `AuthRepository.logout()` API，清除本地安全存储中的 Token，跳转回登录页面
- [ ] **AC3：** Given 用户 Token 已过期且刷新失败，When 应用启动时路由守卫检测到 Token 无效，Then 自动跳转到登录页面，不显示首页
- [ ] **AC4：** Given 用户在首页，When 调整浏览器窗口或 Windows 桌面窗口大小，Then 页面内容自适应显示，无布局错乱

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 退出登录 API 调用失败（网络异常） | 清除本地 Token 并跳转登录页（离线退出），不阻塞用户退出操作 |
| 用户 Token 已过期但正在查看首页 | 路由守卫处于静默状态，不影响已加载页面的查看；下次页面导航时触发 Token 刷新或跳转登录 |
| 首页用户信息加载失败 | 显示占位信息"用户信息加载中..."，不影响页面其他部分显示 |
| 用户手动输入无效路由路径 | GoRouter 根据登录状态跳转到首页（已登录）或登录页（未登录） |
| 退出登录确认对话框取消 | 用户取消确认后停留在首页，不做任何操作 |

#### 交付物
- `lib/features/home/screens/home_screen.dart` — 首页页面 UI
- `lib/features/home/providers/home_provider.dart` — 首页状态管理（用户信息、退出登录）
- `lib/core/router/app_router.dart` — 更新：首页路由配置与路由守卫

#### 备注
- 首页为后续业务功能页面的"占位容器"，目前底部/侧边导航区域预留入口位置，后续版本添加具体业务功能
- 退出登录的确认对话框提供操作确认，防止误触
- 首页无需调用额外 API 获取用户信息——用户信息在登录成功时由后端返回（通过 TokenPairDTO 或其他方式），Provider 中持有用户信息

---

## 4. 非功能性需求（Non-Functional Requirements）

### 4.1 性能

- 页面切换时间 ≤ 500ms（GoRouter 页面跳转）
- 登录/注册 API 响应时间 ≤ 2s（网络正常时）
- 页面首屏加载时间 ≤ 3s（Web 平台，Chrome 开发者工具模拟中等网速）
- Token 刷新应在后台完成，不影响用户操作体验
- 验证码倒计时精准（60 秒，误差 ± 1 秒）

### 4.2 可用性

- 所有用户界面使用简体中文，错误提示友好易懂
- 所有表单输入框提供实时校验和聚焦/失焦校验（onBlur）
- 加载状态（Loading）在 API 调用期间通过按钮或遮罩明确展示
- 表单提交按钮在加载状态下禁用，防止重复提交
- 页面布局适配 Web 浏览器（1280×720、1920×1080）和 Windows 桌面窗口（800×600 最小窗口、1280×720、1920×1080）

### 4.3 可靠性

- 网络异常时显示"网络异常，请检查网络连接"友好提示，不崩溃
- Token 自动刷新失败时清除 Token 并跳转登录页，不出现白屏或卡死
- 所有 API 调用设置超时机制（连接超时 15s、读取超时 30s）
- 验证码倒计时组件在页面销毁时释放 Timer 资源

### 4.4 安全性

- Token（access_token、refresh_token）使用 `flutter_secure_storage` 安全存储，不得存储在普通 SharedPreferences 中
- 日志中不得输出 Token、密码等敏感信息
- 密码不得在任何客户端日志、异常信息、URL 参数中明文出现
- 所有 API 请求通过网关（localhost:9000）转发，不直接暴露后端微服务端口
- 请求头中 `Authorization: Bearer {token}` 在 Token 为空时不注入
- 登录失败时显示的通用错误信息不得透露是"用户名不存在"还是"密码错误"

### 4.5 可维护性

- 遵循 Flutter 官方推荐的编码规范和项目结构
- 代码通过 `flutter analyze` 静态分析，零错误、零警告
- 严格遵循命名规范：类名 PascalCase、文件名 snake_case、变量/方法名 camelCase、常量前缀 `k`
- UI 组件与业务逻辑严格分离（Screen ↔ Provider ↔ Repository 三层架构）
- 新增功能页面只需在 `lib/features/` 下创建新模块，不影响现有模块
- 公共 UI 组件抽取到 `lib/shared/widgets/`，避免重复代码
- 核心逻辑（Repository、Provider）包含单元测试

---

## 5. 附录

### 5.1 API 对接清单

| 前端功能 | 后端 API | 方法 | 是否需要登录 |
|----------|----------|------|:----------:|
| 登录 | `/api/v1/auth/login` | POST | ❌ |
| 注册 | `/api/v1/auth/register` | POST | ❌ |
| Token 刷新 | `/api/v1/auth/refresh` | POST | ❌ |
| 登出 | `/api/v1/auth/logout` | POST | ✅ |
| 发送验证码 | `/api/v1/auth/verification-code/send` | POST | ❌ |
| 找回密码重置 | `/api/v1/auth/password/forgot/reset` | POST | ❌ |

### 5.2 用户故事与功能需求映射

| US 编号 | 关联 FR | 标题 | 优先级 |
|---------|---------|------|--------|
| US-001 | FR-001 | Flutter 子项目创建与双平台构建 | 高 |
| US-002 | FR-002 | Flutter 项目依赖与配置 | 高 |
| US-003 | FR-003 | 统一 HTTP 客户端封装 | 高 |
| US-004 | FR-004 | Auth API 数据仓库 | 高 |
| US-005 | FR-005 | 用户登录页面 | 高 |
| US-006 | FR-006 | 多模式登录支持 | 中 |
| US-007 | FR-007 | 用户注册页面 | 高 |
| US-008 | FR-008 | 多模式注册支持 | 中 |
| US-009 | FR-009 | 找回密码页面 | 高 |
| US-010 | FR-010 | 首页与导航框架 | 中 |

### 5.3 目录结构规划

```
cloudoffice-flutter-app/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── app.dart                           # MaterialApp 配置
│   ├── config/
│   │   ├── api_config.dart                # API 基础配置
│   │   └── theme_config.dart              # 主题配置
│   ├── core/
│   │   ├── http/
│   │   │   ├── api_client.dart            # Dio 实例封装
│   │   │   ├── api_interceptor.dart       # 请求/响应拦截器
│   │   │   └── api_result.dart            # 统一响应模型
│   │   ├── router/
│   │   │   └── app_router.dart            # GoRouter 路由表
│   │   ├── storage/
│   │   │   └── secure_storage.dart        # 安全存储封装
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── models/                    # 数据模型
│   │   │   ├── providers/                 # 状态管理
│   │   │   ├── repositories/              # 数据仓库
│   │   │   └── screens/                   # 页面
│   │   └── home/
│   │       ├── providers/
│   │       └── screens/
│   └── shared/
│       ├── widgets/                       # 公共 UI 组件
│       └── constants/                     # 常量
├── test/                                  # 测试
├── web/                                   # Web 平台配置
├── windows/                               # Windows 平台配置
├── pubspec.yaml
└── analysis_options.yaml
```
