# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.2.0
**日期：** 2026-06-24

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.2.0 | 2026-06-24 | 初始版本，定义 Flutter 前端子项目创建需求（Web + Windows 双平台、注册/登录/找回密码页面） | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）已完成了后端微服务基础架构的建设（v0.1.0 ~ v0.1.7），涵盖了以下核心能力：

- **认证服务（auth-service）**：多模式注册/登录、密码管理、手机号变更、验证码管理、JWT 双 Token（RS256）、租户管理、角色权限管理（RBAC）
- **API 网关（gateway）**：统一流量入口（端口 9000）、路由转发、CORS 配置
- **企业服务（biz-service）**：企业信息管理骨架
- **系统服务（system-service）**：系统配置、监控、健康检查
- **管理中台（admin-service）**：管理员后台用户管理、操作审计日志

然而，目前项目缺少**面向最终用户的前端应用**，所有后端 API 能力无法通过用户界面直接使用。v0.2.0 的目标是创建 Flutter 前端子项目，作为云漫智企的用户入口，使普通用户能够通过 Web 浏览器或 Windows 桌面应用完成注册、登录、找回密码等基础认证操作。

### 1.2 业务痛点

1. **缺乏用户前端**：认证服务虽然功能完备，但没有用户可直接操作的界面，用户体验完全依赖 API 调用
2. **多平台访问需求**：用户需要同时支持 Web（浏览器）和 Windows 桌面端两种访问方式，传统 Web 应用无法满足桌面端需求
3. **认证流程不闭环**：用户注册、登录、找回密码这些基础操作无法自助完成，需要外部对接或手动处理
4. **统一用户体验**：需要建立统一的 UI 风格和交互规范，为后续的业务功能页面提供基础框架

### 1.3 项目目标

1. 在项目根目录下创建 **cloudoffice-flutter-app** Flutter 前端子项目
2. 支持 **Web 平台（Chrome）** 和 **Windows 平台（VS2022）** 双平台构建
3. 实现**用户注册页面**，支持多种注册模式，与后端 `/api/v1/auth/register` 交互
4. 实现**用户登录页面**，支持多种登录模式，与后端 `/api/v1/auth/login` 交互
5. 实现**找回密码页面**，支持验证码重置流程，与后端密码找回 API 交互
6. 封装**统一 HTTP 客户端**（基于 Dio），对接后端所有认证相关 API
7. 搭建**基础导航框架**，为后续业务功能页面奠定基础

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.2.0 版本的开发，覆盖 Flutter 前端子项目 `cloudoffice-flutter-app` 的创建与全部前端认证功能页面的需求范围，涉及与后端 `cloudoffice-auth-service`、`cloudoffice-gateway` 的对接交互。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 | 页面范围 |
|------|------|----------|
| 未认证访客 | 未登录的匿名用户，可访问注册、登录、找回密码页面 | 注册页、登录页、找回密码页 |
| 已认证用户 | 已登录用户，可访问首页，可退出登录 | 首页（登录后） |

### 2.2 系统架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                       用户终端                                        │
│  ┌──────────────────┐        ┌─────────────────────┐                │
│  │  Web 浏览器(Chrome)│        │  Windows 桌面应用      │                │
│  └────────┬─────────┘        └──────────┬──────────┘                │
└───────────┼──────────────────────────────┼──────────────────────────┘
            │                              │
            └──────────────┬───────────────┘
                           │ HTTP API (localhost:9000)
                           ▼
┌──────────────────────────────────────────────────────────────────────┐
│                   cloudoffice-flutter-app (Flutter)                  │
│                                                                      │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐  │
│  │ 核心层 (core)    │  │ 功能模块 (features)│  │ 配置与共享 (config) │  │
│  │  ├─ HTTP 客户端  │  │  ├─ auth/        │  │  ├─ API 配置      │  │
│  │  ├─ 路由配置     │  │  │  ├─ 登录页    │  │  ├─ 主题配置      │  │
│  │  ├─ 安全存储     │  │  │  ├─ 注册页    │  │  └─ 常量定义      │  │
│  │  └─ 工具类       │  │  │  └─ 找回密码  │  │                    │  │
│  │                  │  │  └─ home/        │  └────────────────────┘  │
│  │                  │  │     └─ 首页      │                          │
│  └─────────────────┘  └──────────────────┘                          │
└────────────────────────────┬─────────────────────────────────────────┘
                             │ HTTP API
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│              API 网关 (cloudoffice-gateway :9000)                     │
│             路由: /api/v1/auth/** → auth-service :9100               │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────────┐
│              cloudoffice-auth-service（认证服务 :9100）                │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  API 端点 (AuthController)                                     │   │
│  │  ├─ POST /api/v1/auth/login           — 登录                   │   │
│  │  ├─ POST /api/v1/auth/register        — 注册                   │   │
│  │  ├─ POST /api/v1/auth/refresh         — Token 刷新             │   │
│  │  ├─ POST /api/v1/auth/logout          — 登出                   │   │
│  │  ├─ POST /api/v1/auth/verification-code/send  — 发送验证码     │   │
│  │  ├─ POST /api/v1/auth/password/forgot/reset   — 找回密码重置   │   │
│  │  └─ ...                                                       │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.3 页面流转关系

```
┌────────────┐      注册成功      ┌────────────┐
│  注册页面   │ ────────────────→ │            │
│ (register) │                   │  登录页面   │
└──────┬─────┘                   │  (login)   │
       │                         │            │
       │  点击"已有账号？去登录"    └─────┬──────┘
       └──────────────────────────→      │
                                         │ 登录成功
                                         ▼
                                  ┌────────────┐
                                  │   首页      │
                                  │  (home)    │
                                  └────────────┘
                                         ▲
       ┌────────────┐                   │
       │ 找回密码    │ ──────────────────┘
       │ (forgot)   │  重置成功
       └────────────┘
```

---

## 3. 功能需求

### 3.1 Flutter 子项目创建

#### FR-001: Flutter 子项目创建与双平台构建

- **描述：** 在项目根目录下创建 `cloudoffice-flutter-app` Flutter 子项目，支持 Web 和 Windows 双平台构建运行。项目命名风格与现有后端 Maven 子模块保持一致。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 在项目根目录下执行 `flutter create cloudoffice-flutter-app` 创建项目
  2. 项目目录结构符合 Flutter 标准分层规范（lib/config、lib/core、lib/features、lib/shared 等）
  3. 在 `pubspec.yaml` 中配置项目名称、描述、版本号（v0.2.0+1）
  4. 配置 Web 平台支持（`flutter config --enable-web` 已验证）
  5. 配置 Windows 平台支持（`flutter config --enable-windows-desktop` 已验证）
  6. 通过 `flutter build web` 可正常构建 Web 版本
  7. 通过 `flutter build windows` 可正常构建 Windows 版本
  8. `analysis_options.yaml` 配置 Dart 静态分析规则
  9. 项目命名 `cloudoffice-flutter-app` 与后端模块命名风格统一

#### FR-002: Flutter 项目依赖与配置

- **描述：** 配置 Flutter 项目的核心依赖库、开发环境配置和构建配置，为开发阶段和双平台构建提供保障。
- **优先级：** 高 (Must)
- **验收标准：**
  1. `pubspec.yaml` 中声明以下核心依赖：
     - `dio: ^5.x` — HTTP 网络请求库
     - `provider: ^6.x` — 状态管理
     - `flutter_secure_storage: ^9.x` — 安全存储（Token 等敏感数据）
     - `go_router: ^14.x` — 声明式路由管理
     - `flutter_svg: ^2.x` — SVG 图标支持（可选）
     - `intl: ^0.19.x` — 国际化支持（可选）
  2. 开发依赖（dev_dependencies）：
     - `flutter_test` — 测试框架
     - `flutter_lints` — 代码规范检查
     - `mockito: ^5.x` — 测试 Mock 库
     - `build_runner` — 代码生成器
  3. `pubspec.yaml` 中 Flutter SDK 版本约束：`>=3.0.0 <4.0.0`
  4. 配置 `web/index.html` 的标题和 meta 信息
  5. 配置 `windows/` 目录下 VS2022 构建配置文件
  6. 项目通过 `flutter pub get` 无错误
  7. 项目通过 `flutter analyze` 无警告

---

### 3.2 统一 HTTP 客户端与 API 对接

#### FR-003: 统一 HTTP 客户端封装

- **描述：** 基于 Dio 封装统一的 HTTP 客户端，提供请求/响应拦截器、Token 自动注入、Token 自动刷新和统一错误处理能力。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **ApiClient 类**：单例模式的 Dio 实例封装
     - 基础 URL 配置为 `http://localhost:9000`（网关地址，可通过配置修改）
     - 连接超时：15 秒，读取超时：30 秒
     - 请求头默认 `Content-Type: application/json`
  2. **ApiInterceptor 拦截器**：
     - 请求拦截器：自动从安全存储读取 `access_token`，注入 `Authorization: Bearer {token}` 请求头
     - 响应拦截器：统一解析 `ApiResult<T>` 响应体
     - 401 响应自动触发 Token 刷新流程（使用 `refresh_token` 调用 `/api/v1/auth/refresh`）
     - Token 刷新成功后重放原始请求
     - Token 刷新失败时清除本地 Token，跳转登录页
  3. **ApiResult 模型**：对应后端统一响应体
     - `code`（int，状态码）
     - `message`（String，提示信息）
     - `data`（T，泛型数据）
     - `timestamp`（long，时间戳）
     - 静态工厂方法：`isSuccess()`、`getData()`、`getMessage()`
  4. **统一错误处理**：
     - 网络异常（SocketException、TimeoutException）→ 友好提示"网络异常，请检查网络连接"
     - 后端业务错误（code ≠ 200）→ 展示后端返回的错误消息
     - 认证过期（401）→ 自动刷新或跳转登录
     - 服务器错误（5xx）→ 友好提示"服务器繁忙，请稍后重试"

#### FR-004: Auth API 数据仓库

- **描述：** 封装认证相关的后端 API 调用逻辑，将 HTTP 请求抽象为可调用的 Repository 方法，供前端页面和状态管理层使用。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **AuthRepository 类**，封装以下方法：
     - `register(RegisterRequest)` → `ApiResult<RegisterResult>`
     - `login(LoginRequest)` → `ApiResult<TokenPairDTO>`
     - `refreshToken(String refreshToken)` → `ApiResult<TokenPairDTO>`
     - `logout()` → `ApiResult<Void>`
     - `sendVerificationCode(String target, String purpose, String mode)` → `ApiResult<Void>`
     - `forgotPasswordReset(String mode, String target, String code, String newPassword)` → `ApiResult<Void>`
  2. **数据模型**（对应后端 DTO）：
     - `LoginRequest`：loginName/password/phone/smsCode/tenantCode/clientType/loginMode
     - `RegisterRequest`：loginName/password/userName/phone/email/registerMode/tenantCode
     - `SendVerificationCodeRequest`：target/purpose/mode
     - `PasswordForgotRequest`：mode/target/code/newPassword
     - `TokenPairDTO`：accessToken/refreshToken/accessTokenExpireIn/refreshTokenExpireIn/tokenType
     - `RegisterResult`：userId/loginName/userName/accountSettled/tokenPair
  3. 所有方法返回 Dart 中的 `Future<ApiResult<T>>`
  4. 捕获并转换 DioException 为业务层可理解的错误类型
  5. Repository 层不处理 UI 逻辑，仅负责数据转换和 API 调用

---

### 3.3 登录页面

#### FR-005: 用户登录页面

- **描述：** 实现用户登录功能的前端页面，支持用户名密码登录模式（基础模式），与后端 `/api/v1/auth/login` API 交互。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **页面布局**：
     - 应用 Logo 和名称展示
     - 登录表单区域居中显示
     - 底部包含"没有账号？去注册"和"忘记密码？"链接
     - 页面适配 Web 浏览器和 Windows 桌面窗口尺寸
  2. **登录表单**：
     - 登录名输入框：支持输入用户名/手机号，带输入校验（非空，长度4-64字符）
     - 密码输入框：支持密码显示/隐藏切换，带输入校验（非空，长度8-64字符）
     - "记住我"复选框（保存登录名到本地，非安全存储）
     - 登录按钮：带加载状态（loading），防止重复点击
  3. **交互逻辑**：
     - 点击登录按钮 → 校验表单 → 显示加载动画 → 调用登录 API
     - 登录成功 → 保存 TokenPairDTO（access_token + refresh_token）到安全存储 → 跳转首页
     - 登录失败 → 显示后端返回的错误信息（如"用户名或密码错误"、"账户已被锁定"等）
     - 网络异常 → 提示"网络异常，请检查网络连接"
  4. **Token 管理**：
     - access_token 和 refresh_token 使用 `flutter_secure_storage` 持久化存储
     - 应用启动时检查本地 Token 有效性（access_token 是否过期）
     - 当 access_token 过期时，自动使用 refresh_token 刷新
     - 刷新失败（refresh_token 也过期）→ 清除 Token → 显示登录页
  5. **已登录状态处理**：
     - 已登录用户打开应用时直接跳转首页，不显示登录页
     - 通过路由守卫（GoRouter redirect）实现

#### FR-006: 多模式登录支持

- **描述：** 在基础登录之上，扩展支持手机验证码登录模式，与后端多种登录模式对应。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **登录模式切换**：页面顶部提供 Tab 或切换按钮，至少支持以下两种模式：
     - "密码登录"（用户名密码模式，`USERNAME_PASSWORD`）
     - "验证码登录"（手机验证码模式，`SMS`）
  2. **手机验证码登录模式**：
     - 手机号输入框：带格式校验（11 位手机号）
     - 获取验证码按钮：点击后调用 `/api/v1/auth/verification-code/send`
     - 验证码输入框：6位数字验证码输入
     - 验证码倒计时：60 秒，倒计时期间按钮禁用并显示剩余秒数
     - 登录请求的 loginMode 为 `SMS`
  3. 各模式间切换时保留已输入的内容
  4. 未来扩展点预留：OAuth 登录（微信/支付宝等第三方登录）入口位置

---

### 3.4 注册页面

#### FR-007: 用户注册页面

- **描述：** 实现用户注册功能的前端页面，支持用户名密码注册模式，与后端 `/api/v1/auth/register` API 交互。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **页面布局**：
     - 应用 Logo 和"注册新账号"标题
     - 注册表单区域居中显示
     - 底部包含"已有账号？去登录"链接
     - 页面适配 Web 浏览器和 Windows 桌面窗口尺寸
  2. **注册表单（用户名密码注册模式 - `USERNAME`）**：
     - 用户名输入框：4-64 字符，仅允许字母、数字、下划线，带实时输入校验
     - 真实姓名输入框：2-50 字符，必填
     - 密码输入框：8-64 字符，支持显示/隐藏切换，显示密码强度指示器（弱/中/强）
     - 确认密码输入框：与密码一致性校验
     - 注册按钮：带加载状态，防止重复点击
  3. **交互逻辑**：
     - 点击注册按钮 → 前端校验表单（用户名格式、密码强度、密码一致性）→ 显示加载动画 → 调用注册 API
     - 注册成功 → 保存 TokenPairDTO（注册 API 返回的 token）→ 跳转首页或登录页
     - 注册失败 → 显示后端返回的错误信息（如"用户名已存在"）
     - 所有输入框带焦点失去校验（onBlur 触发校验）
  4. **密码强度指示器**：
     - 弱（仅字母或仅数字，长度 < 10）
     - 中（字母+数字，长度 < 12）
     - 强（字母+数字+特殊字符，长度 >= 12）
  5. **客户端校验规则**：
     - 用户名：4-64 字符，仅允许字母、数字、下划线
     - 真实姓名：2-50 字符
     - 密码：8-64 字符，密码和确认密码必须一致
     - 校验不通过时：输入框下方显示红色错误提示

#### FR-008: 多模式注册支持

- **描述：** 在用户名密码注册基础上，扩展支持手机验证码注册模式。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **注册模式切换**：页面顶部提供 Tab 或切换按钮，支持以下模式：
     - "用户名注册"（`USERNAME` 模式）
     - "手机号注册"（`PHONE` 模式）
  2. **手机验证码注册模式**：
     - 手机号输入框：11 位手机号，格式校验
     - 真实姓名输入框：2-50 字符，必填
     - 获取验证码按钮：调用 `/api/v1/auth/verification-code/send`（purpose=REGISTER）
     - 验证码输入框：6 位数字
     - 验证码倒计时：60 秒
     - 注册请求的 registerMode 为 `PHONE`
  3. 两种模式切换时保留已输入的公共字段内容

---

### 3.5 找回密码页面

#### FR-009: 找回密码页面（两步流程）

- **描述：** 实现密码找回功能的前端页面，支持通过手机号或邮箱验证码重置密码，与后端密码找回 API 交互。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **页面布局**：
     - "找回密码"标题和步骤指示器（Step 1: 身份验证 → Step 2: 重置密码）
     - 底部包含"返回登录"链接
     - 页面适配 Web 浏览器和 Windows 桌面窗口尺寸
  2. **第一步：身份验证**
     - 手机号/邮箱输入框：支持手机号或邮箱输入
     - 验证方式选择：短信验证（SMS）/邮箱验证（EMAIL）
     - 获取验证码按钮：调用 `/api/v1/auth/verification-code/send`（purpose=RESET_PASSWORD）
     - 验证码输入框：6 位数字
     - "下一步"按钮：前端校验验证码已输入
  3. **第二步：重置密码**
     - 新密码输入框：8-64 字符，显示密码强度指示器
     - 确认新密码输入框：与密码一致性校验
     - "重置密码"按钮：调用 `/api/v1/auth/password/forgot/reset` API
     - 重置成功后显示成功提示 → 自动跳转登录页（3 秒倒计时）
  4. **验证码交互**：
     - 获取验证码按钮点击后开始 60 秒倒计时
     - 倒计时期间显示"X秒后重新获取"，按钮禁用
     - 倒计时结束后恢复"获取验证码"
     - 发送验证码失败时显示错误信息
  5. **步进导航**：
     - 步骤指示器清晰显示当前所在步骤
     - 第一步完成后不可返回修改（或提供"上一步"按钮）
     - 支持从第一步到第二步的平滑过渡动画

---

### 3.6 首页与导航框架

#### FR-010: 首页/导航框架

- **描述：** 实现登录后的基础首页页面，展示用户信息，提供退出登录功能，作为后续业务功能页面的导航基础框架。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **页面结构**：
     - 顶部导航栏（AppBar）：显示应用名称和当前用户登录名
     - 主内容区域：显示欢迎信息和用户基本信息（登录名、真实姓名等）
     - 底部或侧边导航区域：预留后续功能入口位置
  2. **用户信息展示**：
     - 显示当前登录用户的登录名和真实姓名
     - 显示用户的角色信息
  3. **退出登录功能**：
     - 顶部导航栏或用户菜单中提供"退出登录"按钮
     - 点击退出 → 调用 `/api/v1/auth/logout` API
     - 退出成功后清除本地 Token 和安全存储数据
     - 跳转回登录页面
  4. **页面适配**：
     - Web 浏览器中页面宽度自适应
     - Windows 桌面应用中支持窗口大小调整，内容自适应
  5. **登录态检查**：
     - 每次启动应用时检查本地 Token 是否存在且有效
     - Token 无效时自动跳转到登录页
     - 首页为登录后默认路由（GoRouter 的 `/` 路径）

---

## 4. 非功能需求

### NFR-001: 跨平台兼容

- **描述：** 应用必须在 Web 和 Windows 两个平台上运行一致，UI 布局和行为无明显差异。
- **指标：**
  1. 同一套 Dart 代码在 Web（Chrome）和 Windows 平台上均可正常编译运行
  2. 核心认证流程（注册→登录→找回密码）在双平台上端到端测试通过
  3. 表单输入、错误提示、加载动画等交互在双平台上表现一致
  4. 布局在以下分辨率下均可正常显示：
     - Web：1280×720、1920×1080
     - Windows：800×600（最小窗口）、1280×720、1920×1080
  5. 不引入平台特定代码（除非绝对必要），保持跨平台代码统一

### NFR-002: API 通信安全性

- **描述：** 前端与后端的通信必须安全可靠，敏感数据必须妥善保护。
- **指标：**
  1. Token（access_token、refresh_token）使用 `flutter_secure_storage` 安全存储，不得存储在普通 SharedPreferences 中
  2. 日志中不得输出 Token、密码等敏感信息
  3. 密码不得在任何客户端日志、异常信息、URL 参数中明文出现
  4. 所有 API 请求通过网关（localhost:9000）转发，不直接暴露后端服务端口
  5. 请求头中 `Authorization: Bearer {token}` 在 Token 为空时不注入
  6. 登录失败时返回的通用错误信息不得透露是"用户名不存在"还是"密码错误"

### NFR-003: 代码质量

- **描述：** 保持高质量的 Flutter/Dart 代码标准，确保代码可维护、可扩展、可测试。
- **指标：**
  1. 遵循 Flutter 官方推荐的[项目结构](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)和编码规范
  2. 代码通过 `flutter analyze` 静态分析，零错误、零警告
  3. 命名规范：
     - 类名：PascalCase（如 `LoginScreen`、`AuthRepository`）
     - 文件名：snake_case（如 `login_screen.dart`、`api_client.dart`）
     - 变量/方法名：camelCase（如 `userName`、`login()`）
     - 常量：camelCase 前缀 `k`（如 `kApiBaseUrl`、`kPasswordMinLength`）
  4. 状态管理使用 Provider 模式，避免全局状态污染
  5. UI 组件与业务逻辑分离（Screen ↔ Provider ↔ Repository 三层架构）
  6. 核心逻辑（Repository、Provider）包含单元测试
  7. 注释规范：
     - 公开 API 和复杂业务逻辑需添加 Dart Doc 注释（`///`）
     - 避免无意义注释
     - TODO 注释需标注负责人和日期

### NFR-004: 性能

- **描述：** 前端应用响应性能满足日常使用需求。
- **指标：**
  1. 页面切换时间 ≤ 500ms（GoRouter 页面跳转）
  2. 登录 API 响应时间 ≤ 2s（网络正常时）
  3. 注册 API 响应时间 ≤ 2s（网络正常时）
  4. 页面首屏加载时间 ≤ 3s（Web 平台，Chrome 开发者工具模拟中等网速）
  5. Token 刷新应在后台完成，不影响用户操作体验
  6. 验证码倒计时精准（60 秒，误差 ± 1 秒）

### NFR-005: 可维护性与可扩展性

- **描述：** 代码结构应方便后续扩展新的业务功能页面。
- **指标：**
  1. 新增功能页面只需在 `lib/features/` 下创建新模块，不影响现有模块
  2. 路由配置集中管理（GoRouter），新增路由只需在路由表中添加
  3. HTTP 客户端扩展新 API 只需在对应 Repository 中添加方法
  4. 公共 UI 组件（按钮、输入框、验证码组件等）抽取到 `lib/shared/widgets/`
  5. 主题、颜色、字体等样式配置集中管理在 `lib/config/theme_config.dart`
  6. 各功能模块之间不产生直接依赖，通过 Repository 与后端交互

---

## 5. 技术栈选型

### 5.1 Flutter 核心依赖

| 依赖 | 版本 | 用途 | 备注 |
|------|------|------|------|
| Flutter SDK | 3.x | 跨平台 UI 框架 | 安装于 D:\jenemy\develop\flutter |
| Dart SDK | 3.x | 编程语言 | 随 Flutter SDK 包含 |
| dio | ^5.x | HTTP 网络请求库 | 统一 HTTP 客户端 |
| provider | ^6.x | 状态管理 | ViewModel 层状态管理 |
| flutter_secure_storage | ^9.x | 安全存储 | Token 等敏感数据持久化 |
| go_router | ^14.x | 声明式路由 | 页面导航与路由守卫 |
| flutter_lints | ^5.x | 代码规范检查 | analysis_options.yaml |

### 5.2 开发工具

| 工具 | 用途 |
|------|------|
| VS Code / IntelliJ IDEA | 代码开发 IDE |
| Chrome 浏览器 | Web 平台构建与调试 |
| Visual Studio 2022 | Windows 平台构建（MSVC 编译器） |
| Flutter DevTools | 性能分析与调试 |

### 5.3 构建命令

| 命令 | 用途 |
|------|------|
| `flutter pub get` | 获取依赖 |
| `flutter analyze` | 静态代码分析 |
| `flutter test` | 运行测试 |
| `flutter run -d chrome` | Web 开发调试 |
| `flutter run -d windows` | Windows 开发调试 |
| `flutter build web` | Web 生产构建 |
| `flutter build windows` | Windows 生产构建 |

---

## 6. API 对接清单

### 6.1 Flutter → 后端 API 调用关系

| 前端功能 | 后端 API | 方法 | 请求体 | 响应体 | 是否需要登录 |
|----------|----------|------|--------|--------|:----------:|
| 登录 | `/api/v1/auth/login` | POST | `LoginRequest` | `ApiResult<TokenPairDTO>` | ❌ |
| 注册 | `/api/v1/auth/register` | POST | `RegisterRequest` | `ApiResult<RegisterResult>` | ❌ |
| Token 刷新 | `/api/v1/auth/refresh` | POST | `RefreshTokenRequest` | `ApiResult<TokenPairDTO>` | ❌ |
| 登出 | `/api/v1/auth/logout` | POST | 空（Token 在 Header） | `ApiResult<Void>` | ✅ |
| 发送验证码 | `/api/v1/auth/verification-code/send` | POST | `SendVerificationCodeRequest` | `ApiResult<Void>` | ❌ |
| 找回密码发送验证码 | `/api/v1/auth/password/forgot/send-code` | POST | `SendVerificationCodeRequest` | `ApiResult<Void>` | ❌ |
| 找回密码重置 | `/api/v1/auth/password/forgot/reset` | POST | `PasswordForgotRequest` | `ApiResult<Void>` | ❌ |
| 修改密码 | `/api/v1/auth/password/change` | PUT | `PasswordChangeRequest` | `ApiResult<Void>` | ✅ |
| 健康检查 | `/api/v1/auth/health` | GET | 空 | `ApiResult` | ❌ |

### 6.2 客户端类型定义

Flutter 前端在调用登录/注册 API 时，需传递以下 `clientType` 值：

| 平台 | clientType 值 | 说明 |
|------|--------------|------|
| Web（Chrome） | `WEB` 或 `H5` | Web 浏览器访问 |
| Windows | `WINDOWS` | Windows 桌面应用 |

---

## 7. 约束条件

### 7.1 技术约束

1. **Flutter SDK 路径：** Flutter 安装在 `D:\jenemy\develop\flutter`，必须使用该路径的 Flutter SDK
2. **构建环境：**
   - Web 平台：必须使用 Chrome 浏览器进行开发和调试
   - Windows 平台：必须使用 Visual Studio 2022（含 MSVC 构建工具和 Windows SDK）进行构建
3. **后端 API 地址：** 开发环境下后端 API 基础地址为 `http://localhost:9000`（API 网关地址）
4. **客户端类型标识：**
   - Flutter Web 端请求中 `clientType` 固定为 `H5`
   - Flutter Windows 端请求中 `clientType` 固定为 `WINDOWS`
5. **租户编码：** 测试阶段使用默认租户编码 `default`
6. **开发语言：** 所有 Dart 代码使用简体中文注释，代码标识符使用英文
7. **运行环境：** 开发阶段需要后端微服务（gateway、auth-service、Nacos、Redis、MariaDB）正常运行

### 7.2 架构约束

1. **网关通信：** 前端应用**必须**通过 API 网关（`http://localhost:9000`）访问后端服务，不得直接访问微服务端口
2. **CORS 配置：** Web 平台访问时依赖网关配置的 CORS 策略，不得在前端绕过
3. **无状态通信：** 前端与后端采用无状态 JWT Token 认证，不依赖 Session/Cookie
4. **Token 存储：** Token 必须使用安全存储（`flutter_secure_storage`），Web 平台回退为 `flutter_secure_storage_web` 或等效的内存+localStorage 方案

### 7.3 规范约束

1. **项目命名：** Flutter 子项目名为 `cloudoffice-flutter-app`，与后端 `cloudoffice-{module}` 命名风格统一
2. **API 路径：** 对接后端的 API 路径必须以 `/api/v1/auth/` 为前缀
3. **Git 仓库：** Flutter 子项目位于根仓库的 `cloudoffice-flutter-app/` 目录，不是独立仓库
4. **版本号：** Flutter 应用版本号与项目版本号保持一致（v0.2.0+1）

### 7.4 不修改后端原则

- 本版本**不修改现有后端代码**，所有前端功能基于现有 API 实现
- 如果现有 API 无法满足前端需求，记录需求盲区，通过需求变更流程处理
- 网关已配置的 CORS 策略应能满足 Flutter Web 的跨域访问需求

---

## 8. 假设与依赖

### 8.1 外部依赖

1. **后端服务**（需正常运行）：
   - Nacos 2.3.x（注册中心和配置中心）
   - Redis 7.2.x（验证码存储、会话管理）
   - MariaDB 10.6（用户数据、验证码数据）
   - cloudoffice-gateway（端口 9000）
   - cloudoffice-auth-service（端口 9100）
2. **开发环境**：
   - Flutter SDK 3.x 已安装于 `D:\jenemy\develop\flutter`
   - Chrome 浏览器已安装，版本支持 Flutter Web
   - Visual Studio 2022 已安装，包含"使用 C++ 的桌面开发"工作负载
   - Dart SDK 环境变量已正确配置

### 8.2 环境假设

1. 后端所有微服务在开发环境中已启动并可正常访问
2. API 网关的 CORS 配置允许 `localhost` 来源的跨域请求
3. 后端 `/api/v1/auth/verification-code/send` 在开发环境中为模拟发送（验证码打印在控制台），可通过日志查看验证码
4. 开发人员进行 Flutter 开发时已配置好 Android/Linux 环境（虽然在 v0.2.0 中不是目标平台，但 Flutter SDK 初始化需要）
5. SpringDoc 生成的 OpenAPI 文档可帮助前端开发者确认 API 请求/响应结构

### 8.3 项目假设

1. **用户数据准备：** 测试注册/登录功能需要在后端准备好默认租户（`default`）数据，或注册 API 会自动创建
2. **Windows 构建工具链：** Visual Studio 2022 已正确安装，`flutter doctor -v` 显示 Windows 桌面开发工具链正常
3. **Web 构建：** Flutter Web 构建无需额外工具，`flutter build web` 可直接生成静态 Web 资源
4. **安全存储 Web 兼容：** `flutter_secure_storage` 在 Web 平台上使用 `flutter_secure_storage_web` 插件或回退方案，确保 Token 安全存储
5. **网络环境：** 开发环境网络正常，前端可访问 `localhost:9000`

---

## 9. 优先级汇总 (MoSCoW)

### 9.1 Must（必须有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-001 | Flutter 子项目创建与双平台构建 | 项目基础设施 |
| FR-002 | Flutter 项目依赖与配置 | 项目基础设施 |
| FR-003 | 统一 HTTP 客户端封装 | 核心层 |
| FR-004 | Auth API 数据仓库 | 核心层 |
| FR-005 | 用户登录页面 | 认证模块 |
| FR-007 | 用户注册页面（用户名密码模式） | 认证模块 |
| FR-009 | 找回密码页面（两步流程） | 认证模块 |

### 9.2 Should（应该有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-006 | 多模式登录支持（手机验证码登录） | 认证模块 |
| FR-008 | 多模式注册支持（手机验证码注册） | 认证模块 |
| FR-010 | 首页/导航框架 | 导航框架 |

### 9.3 Could（可以有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| - | 邮箱注册模式支持 | 认证模块 |
| - | OAuth 登录入口（微信/支付宝等第三方） | 认证模块 |
| - | 页面切换动画与过渡效果 | UI 增强 |
| - | 中英文国际化支持 | 基础设施 |

### 9.4 Won't（本期不做）

| 需求名称 | 说明 |
|----------|------|
| 业务功能页面（企业信息、人事管理等） | v0.2.0 仅完成认证相关页面，业务功能在后续版本实现 |
| 移动端（Android/iOS）支持 | 本期仅做 Web 和 Windows，移动端后续版本 |
| 主题换肤功能 | 本期仅实现一套默认主题 |
| 深色模式 | 本期不实现深色/浅色模式切换 |
| 前端单元测试全覆盖 | 本期仅覆盖核心逻辑（Repository、Provider），UI 测试后续版本 |
| 自动部署/CI/CD 流水线 | 本期不涉及自动化部署 |
| 管理员管理后台前端 | admin-service 后端已有，但管理后台前端不在本期范围内 |

---

## 10. 验收总体标准

1. 所有 Must 优先级需求必须全部完成并通过验收
2. Flutter 子项目 `cloudoffice-flutter-app` 创建在项目根目录下，命名与后端模块统一
3. `flutter analyze` 零错误、零警告
4. `flutter build web` 构建成功，Web 页面在 Chrome 中打开后：
   - 可正常显示登录页面
   - 可完成注册流程
   - 可完成登录流程并跳转首页
   - 可完成找回密码流程
   - 可完成退出登录
5. `flutter build windows` 构建成功，Windows 桌面应用运行时：
   - 上述 4 条中的功能均可正常使用
   - 窗口可调整大小，布局自适应
6. 登录/注册/找回密码功能与后端服务端到端联调通过
7. Token 自动刷新机制正常工作：access_token 过期后自动刷新，用户操作不中断
8. 错误处理：网络异常、业务错误、Token 过期等场景均有友好提示
9. 安全存储：退出登录后清除 Token，重新打开应用需重新登录
10. 核心 Repository 类和 Provider 类包含单元测试，测试通过

---

## 附录 A：项目目录结构规划

```
cloudoffice-flutter-app/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── app.dart                           # MaterialApp 配置（主题、路由）
│   ├── config/                            # 配置层
│   │   ├── api_config.dart                # API 配置（baseUrl、超时时间）
│   │   └── theme_config.dart              # 主题配置（颜色、字体、样式）
│   ├── core/                              # 核心层
│   │   ├── http/                          # HTTP 客户端
│   │   │   ├── api_client.dart            # Dio 实例封装（单例）
│   │   │   ├── api_interceptor.dart       # 请求/响应拦截器
│   │   │   └── api_result.dart            # 统一响应模型
│   │   ├── router/                        # 路由配置
│   │   │   └── app_router.dart            # GoRouter 路由表
│   │   ├── storage/                       # 本地存储
│   │   │   └── secure_storage.dart        # 安全存储封装
│   │   └── utils/                         # 工具类
│   ├── features/                          # 功能模块
│   │   ├── auth/                          # 认证模块
│   │   │   ├── models/                    # 数据模型
│   │   │   │   ├── login_request.dart
│   │   │   │   ├── register_request.dart
│   │   │   │   ├── token_pair.dart
│   │   │   │   └── register_result.dart
│   │   │   ├── providers/                 # 状态管理
│   │   │   │   ├── auth_provider.dart
│   │   │   │   └── forgot_password_provider.dart
│   │   │   ├── repositories/              # 数据仓库
│   │   │   │   └── auth_repository.dart
│   │   │   └── screens/                   # 页面
│   │   │       ├── login_screen.dart
│   │   │       ├── register_screen.dart
│   │   │       └── forgot_password_screen.dart
│   │   └── home/                          # 首页模块
│   │       ├── providers/
│   │       │   └── home_provider.dart
│   │       └── screens/
│   │           └── home_screen.dart
│   └── shared/                            # 共享组件
│       ├── widgets/                       # 公共 UI 组件
│       │   ├── custom_text_field.dart     # 自定义输入框
│       │   ├── password_field.dart        # 密码输入框（带切换可见性）
│       │   ├── verification_code_field.dart # 验证码输入框
│       │   ├── loading_button.dart        # 加载状态按钮
│       │   ├── password_strength_indicator.dart # 密码强度指示器
│       │   └── app_logo.dart              # 应用 Logo
│       └── constants/                     # 常量
│           └── app_constants.dart         # 应用常量
├── test/                                  # 测试
│   ├── core/
│   │   └── http/
│   │       └── api_client_test.dart
│   ├── features/
│   │   └── auth/
│   │       ├── repositories/
│   │       │   └── auth_repository_test.dart
│   │       └── providers/
│   │           └── auth_provider_test.dart
│   └── shared/
│       └── widgets/
├── web/                                   # Web 平台配置
│   ├── index.html
│   └── manifest.json
├── windows/                               # Windows 平台配置
│   ├── CMakeLists.txt
│   └── runner/
├── pubspec.yaml                           # 依赖配置
├── analysis_options.yaml                  # 代码分析配置
└── README.md                              # 项目说明
```

---

## 附录 B：状态管理数据流

```
用户交互（点击登录按钮）
       │
       ▼
Screen（页面层）
  - 调用 Provider 的方法
  - 监听 Provider 的状态变化
       │
       ▼
Provider（状态管理层）
  - 调用 Repository 的方法
  - 维护 UI 状态（loading/error/success）
  - 通知 Listeners 更新 UI
       │
       ▼
Repository（数据仓库层）
  - 组装请求参数
  - 调用 ApiClient 发送 HTTP 请求
  - 解析响应数据为 Model
  - 处理业务错误
       │
       ▼
ApiClient（HTTP 客户端层）
  - Dio 实例发送 HTTP 请求
  - 拦截器注入 Token / 处理 401
  - 返回原始响应
       │
       ▼
后端 API 网关 (localhost:9000)
  → auth-service → 数据库/Redis
```

---

## 附录 C：双平台构建注意事项

### Web 平台（Chrome）

| 注意事项 | 说明 |
|----------|------|
| CORS | Web 平台存在跨域限制，需确保 gateway 配置了正确的 CORS 策略 |
| 安全存储 | `flutter_secure_storage` 在 Web 上使用 `flutter_secure_storage_web` 子插件，回退到 localStorage（需自行评估安全性） |
| 路由 | 使用 URL 路径路由（GoRouter），支持浏览器前进/后退 |
| 构建输出 | `flutter build web` 产出 `build/web/` 目录，为纯静态资源 |

### Windows 平台（VS2022）

| 注意事项 | 说明 |
|----------|------|
| 构建工具 | 需要 Visual Studio 2022 且安装"使用 C++ 的桌面开发"工作负载 |
| 安全存储 | `flutter_secure_storage` 在 Windows 上使用 Credential Manager 或 DPAPI |
| 窗口管理 | 默认窗口大小 1280×720，可通过 `windows/runner/MainWindow.cpp` 配置 |
| 构建输出 | `flutter build windows` 产出 `build/windows/runner/Release/` 目录，为可执行文件 |

---

## 附录 D：错误码与处理策略

| 场景 | 后端错误码 | 前端处理策略 |
|------|-----------|-------------|
| 登录名或密码错误 | AUTH-0001 | 显示"用户名或密码错误" |
| 账户已禁用 | AUTH-0002 | 显示"账户已被禁用，请联系管理员" |
| Token 无效/过期 | AUTH-0003 | 自动刷新 Token，刷新失败则跳转登录页 |
| 用户名已存在 | AUTH-0005 | 显示"该用户名已被注册" |
| 验证码错误 | AUTH-0020 | 显示"验证码错误，请重新输入" |
| 验证码已过期 | AUTH-0021 | 显示"验证码已过期，请重新获取" |
| 发送频率超限 | AUTH-0022 | 显示"发送过于频繁，请 X 秒后再试" |
| 用户不存在 | AUTH-0012 | 显示"该账号不存在" |
| 密码强度不足 | AUTH-0030 | 提示密码复杂度要求 |
| 网络异常 | (无错误码) | 显示"网络异常，请检查网络连接" |
| 服务器内部错误 | 5xx | 显示"服务器繁忙，请稍后重试" |
