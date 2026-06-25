# 任务清单

**项目：** CloudStrollOffice
**版本：** v0.2.0
**对应PRD：** `docs/prds/CloudStrollOffice-prd-v0.2.0.md`
**对应架构：** `docs/architecture.md`
**对应SDS：** `docs/sds/CloudStrollOffice-sds-v0.2.0.md`
**对应项目文件：** `docs/project.md`
**生成日期：** 2026-06-24

---

# 1. 模块任务清单

| 模块 | 功能 | 任务编码 | 任务内容 |
|------|------|---------|---------|
| 项目基础设施 | 子项目创建与双平台配置 | TASK-001 | Flutter 子项目创建与分层目录结构搭建 |
| 项目基础设施 | 依赖与代码规范配置 | TASK-002 | 配置 pubspec.yaml 和 analysis_options.yaml |
| 项目基础设施 | Web/Windows 平台构建配置 | TASK-003 | 配置 Web 平台 index.html 和 Windows 平台构建配置 |
| 核心层 | 统一响应模型 | TASK-004 | 实现 ApiResult 泛型统一响应模型 |
| 核心层 | 安全存储封装 | TASK-005 | 实现 SecureStorage 安全存储封装 |
| 核心层 | HTTP 客户端封装 | TASK-006 | 实现 ApiClient（Dio 单例封装） |
| 核心层 | 请求/响应拦截器 | TASK-007 | 实现 ApiInterceptor（Token 注入、自动刷新、刷新锁机制） |
| 核心层 | 配置类 | TASK-008 | 实现 ApiConfig 和 ThemeConfig 配置类 |
| 数据模型 | 认证数据模型 | TASK-009 | 实现 7 个认证相关数据模型类 |
| 数据仓库 | Auth API 仓库 | TASK-010 | 实现 AuthRepository 封装 6 个认证 API |
| 状态管理 | AuthProvider | TASK-011 | 实现 AuthProvider（登录/注册/登出状态管理） |
| 状态管理 | ForgotPasswordProvider | TASK-012 | 实现 ForgotPasswordProvider（两步找回密码状态管理） |
| 状态管理 | HomeProvider | TASK-013 | 实现 HomeProvider（首页用户信息状态管理） |
| 路由与入口 | 路由配置 | TASK-014 | 实现 AppRouter（GoRouter 路由表 + 路由守卫） |
| 路由与入口 | 应用入口 | TASK-015 | 实现 main.dart 和 app.dart 应用入口与 Provider 注册 |
| 共享组件 | 校验工具与常量 | TASK-016 | 实现表单校验工具函数和常量定义 |
| 共享组件 | 基础表单组件 | TASK-017 | 实现 CustomTextField、PasswordField、LoadingButton 组件 |
| 共享组件 | 验证码与密码强度组件 | TASK-018 | 实现 VerificationCodeField 和 PasswordStrengthIndicator |
| 页面实现 | 登录页面 | TASK-019 | 实现 LoginScreen（用户名密码登录模式） |
| 页面实现 | 多模式登录扩展 | TASK-020 | 扩展 LoginScreen 支持手机验证码登录 Tab 切换 |
| 页面实现 | 注册页面 | TASK-021 | 实现 RegisterScreen（用户名密码注册模式） |
| 页面实现 | 多模式注册扩展 | TASK-022 | 扩展 RegisterScreen 支持手机号注册 Tab 切换 |
| 页面实现 | 找回密码页面 | TASK-023 | 实现 ForgotPasswordScreen（两步找回密码流程） |
| 页面实现 | 首页 | TASK-024 | 实现 HomeScreen（用户信息展示 + 退出登录） |
| 测试 | 核心层与数据仓库测试 | TASK-025 | 编写核心层和数据仓库单元测试 |
| 测试 | Provider 层测试 | TASK-026 | 编写 Provider 层单元测试 |

---

# 2. 模块一：项目基础设施

## 2.1 子项目创建与双平台配置

### 2.1.1 TASK-001：Flutter 子项目创建与分层目录结构搭建

**任务ID：** `TASK-001`
**任务名称：** Flutter 子项目创建与分层目录结构搭建
**任务类型：** `frontend`
**关联UserStory：** `US-001`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** 无（首个任务）
- **下游任务：** `TASK-002`, `TASK-003`

#### 上下文读取

- **PRD US-001：** 第 50-94 行（Flutter 子项目创建与双平台构建），具体关注：
  - AC1-AC6 验收标准（子项目目录、双平台构建、分层结构）
  - 边界情况与错误处理表格
  - 交付物清单
- **SDS 第 7 章：** 第 1294-1391 行（构建与部署设计），关注 Web 和 Windows 构建命令和输出目录
- **SDS 第 6.3.1 节：** 第 1210-1236 行（Flutter 目录结构约定），关注 `lib/` 下分层目录布局
- **project.md 第 592-665 行：** Flutter 前端子项目规划目录结构

#### 详细业务描述

在项目根目录下创建 `cloudoffice-flutter-app` Flutter 子项目。执行 `flutter create cloudoffice-flutter-app` 生成 Flutter 项目骨架，然后按 SDS 6.3.1 节的分层结构要求，创建以下目录结构：

```
cloudoffice-flutter-app/lib/
├── config/              # 配置类
├── core/
│   ├── http/            # HTTP 客户端封装
│   ├── router/          # 路由配置
│   ├── storage/         # 本地存储
│   └── utils/           # 工具类
├── features/
│   ├── auth/            # 认证功能
│   │   ├── models/      # 数据模型
│   │   ├── providers/   # 状态管理
│   │   ├── repositories/# 数据仓库
│   │   └── screens/     # 页面
│   └── home/            # 首页
│       ├── providers/   # 状态管理
│       └── screens/     # 页面
└── shared/
    ├── widgets/         # 公共 UI 组件
    └── constants/       # 常量定义
```

#### 测试验收方法

1. 验证 `cloudoffice-flutter-app/` 目录存在且为 Flutter 项目（包含 `pubspec.yaml`、`lib/` 等）
2. 验证 `pubspec.yaml` 中 `name` 为 `cloudoffice_flutter_app`
3. 验证分层目录结构完整，`lib/config/`、`lib/core/http/`、`lib/core/router/`、`lib/core/storage/`、`lib/core/utils/`、`lib/features/auth/models/`、`lib/features/auth/providers/`、`lib/features/auth/repositories/`、`lib/features/auth/screens/`、`lib/features/home/providers/`、`lib/features/home/screens/`、`lib/shared/widgets/`、`lib/shared/constants/` 目录已创建
4. 验证 `flutter create` 默认生成的 `web/` 和 `windows/` 平台目录已存在

---

## 2.2 依赖与代码规范配置

### 2.2.1 TASK-002：配置 pubspec.yaml 和 analysis_options.yaml

**任务ID：** `TASK-002`
**任务名称：** 配置 pubspec.yaml 依赖声明与 analysis_options.yaml 静态分析规则
**任务类型：** `frontend`
**关联UserStory：** `US-002`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-001`
- **下游任务：** `TASK-003`, `TASK-004`, `TASK-005`, `TASK-006`

#### 上下文读取

- **PRD US-002：** 第 97-140 行（Flutter 项目依赖与配置），关注 AC1-AC6 验收标准
- **SDS 附录 D：** 第 1457-1484 行（pubspec.yaml 完整依赖配置）
- **SDS 第 6.3.4 节：** 第 1265-1290 行（analysis_options.yaml 严格规则配置）
- **project.md 第 592-665 行：** Flutter 项目信息

#### 详细业务描述

配置 `cloudoffice-flutter-app/pubspec.yaml` 文件，声明以下核心依赖：

**运行时依赖：**
- `dio: ^5.4.0` — HTTP 客户端
- `provider: ^6.1.0` — 状态管理
- `flutter_secure_storage: ^9.2.0` — 安全存储
- `go_router: ^14.2.0` — 声明式路由

**开发依赖：**
- `flutter_test`（SDK 自带）
- `flutter_lints: ^5.0.0` — 代码规范检查
- `mockito: ^5.4.0` — 单元测试 Mock
- `build_runner: ^2.4.0` — 代码生成

配置 `analysis_options.yaml`，包含 SDS 6.3.4 节中的严格 lint 规则：
- `prefer_const_constructors`、`avoid_print`、`prefer_single_quotes` 等

配置 SDK 版本约束：`sdk: '>=3.0.0 <4.0.0'`

执行 `flutter pub get` 验证所有依赖下载成功。
执行 `flutter analyze` 验证零错误、零警告。

#### 测试验收方法

1. 执行 `flutter pub get` 无错误输出
2. 执行 `flutter analyze` 零错误、零警告
3. 检查 `pubspec.yaml` 包含所有核心依赖且版本号正确
4. 检查 `analysis_options.yaml` 包含 SDS 6.3.4 中列出的 lint 规则

---

## 2.3 Web/Windows 平台构建配置

### 2.3.1 TASK-003：配置 Web 平台和 Windows 平台构建配置

**任务ID：** `TASK-003`
**任务名称：** 配置 Web/Windows 双平台构建配置
**任务类型：** `frontend`
**关联UserStory：** `US-001`, `US-002`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-002`
- **下游任务：** `TASK-008`, `TASK-014`, `TASK-015`

#### 上下文读取

- **SDS 第 7.3 节：** 第 1381-1391 行（双平台构建差异化配置表）
- **SDS 第 7.1 节：** 第 1296-1337 行（Web 构建流程和部署注意事项）
- **SDS 第 7.2 节：** 第 1338-1380 行（Windows 构建流程和环境要求）

#### 详细业务描述

配置 Web 和 Windows 双平台构建环境：

**Web 平台配置（`web/index.html`）：**
- 修改 `<title>` 为"云漫智企"
- 配置 `<meta>` 信息
- 确认 Flutter Web 使用 CanvasKit 渲染引擎

**Windows 平台配置（`windows/`）：**
- 修改 `windows/runner/main.cpp` 设置窗口标题为"云漫智企"
- 配置窗口默认尺寸 1280×720
- 配置窗口最小尺寸 800×600（`SetMinimumSize`）
- 检查 `windows/runner/CMakeLists.txt` 配置

执行验证：
- `flutter build web` 构建成功
- `flutter build windows` 构建成功

#### 测试验收方法

1. `flutter build web` 构建成功，`build/web/` 目录输出静态资源
2. `flutter build windows` 构建成功，`build/windows/runner/Release/` 输出可执行文件
3. 检查 `web/index.html` 中 title 为"云漫智企"
4. 检查 Windows runner 配置中窗口标题和尺寸符合要求

---

# 3. 模块二：核心层（core）

## 3.1 统一响应模型

### 3.1.1 TASK-004：实现 ApiResult 泛型统一响应模型

**任务ID：** `TASK-004`
**任务名称：** 实现 ApiResult 泛型统一响应模型
**任务类型：** `frontend`
**关联UserStory：** `US-003`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-002`
- **下游任务：** `TASK-006`, `TASK-009`, `TASK-010`

#### 上下文读取

- **SDS 第 3.1.2 节：** 第 289-303 行（ApiResult 模型字段定义、isSuccess/fromJson/toJson 方法定义）
- **PRD US-003 AC1：** 第 162 行（ApiResult 统一响应体定义）
- **SDS 第 4.4.2 节：** 第 1044-1058 行（后端业务错误码映射表，ApiResult 的 code 字段含义）

#### 详细业务描述

在 `lib/core/http/api_result.dart` 文件中实现泛型统一响应模型 `ApiResult<T>`：

```dart
class ApiResult<T> {
  final int? code;
  final String? message;
  final T? data;
  final int? timestamp;

  // 构造函数、fromJson、toJson、isSuccess 方法
  bool isSuccess() => code == 200;
}
```

关键细节：
- `fromJson` 工厂构造函数需要接收 JSON 和 `T Function(Map<String, dynamic>)` 转换函数
- `isSuccess()` 方法通过 `code == 200` 判断业务成功
- 提供静态工厂方法 `ApiResult.success(data)` 和 `ApiResult.error(message)` 用于测试
- 所有字段为 `final`，支持 `const` 构造函数

#### 测试验收方法

1. 单元测试验证 `ApiResult<String>.fromJson()` 能正确解析 JSON
2. 验证 `isSuccess()` 在 code=200 时返回 true，其他值返回 false
3. 验证静态工厂方法 `success()` 和 `error()` 正确初始化字段

---

## 3.2 安全存储封装

### 3.2.1 TASK-005：实现 SecureStorage 安全存储封装

**任务ID：** `TASK-005`
**任务名称：** 实现 SecureStorage 安全存储封装
**任务类型：** `frontend`
**关联UserStory：** `US-003`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-002`
- **下游任务：** `TASK-007`, `TASK-010`, `TASK-011`

#### 上下文读取

- **SDS 第 3.2 节：** 第 306-338 行（安全存储封装设计，含完整代码和 Web 平台回退说明）
- **SDS 第 5.1 节：** 第 1093-1103 行（Token 管理机制中安全存储的角色）
- **PRD US-003：** 第 143-189 行（统一 HTTP 客户端封装中对安全存储的要求）

#### 详细业务描述

在 `lib/core/storage/secure_storage.dart` 文件中实现安全存储封装 `SecureStorage`：

```dart
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenType = 'token_type';

  Future<void> saveTokenPair(TokenPair pair);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<bool> hasTokens();
}
```

关键细节：
- 单例模式实现
- 封装 4 个 Token 相关 Key 的存取
- `saveTokenPair()` 保存 access_token、refresh_token、token_type 三个值
- `clearTokens()` 清除所有 Token 相关存储
- `hasTokens()` 检查 access_token 是否存在且非空

#### 测试验收方法

1. 单元测试验证 Token 保存和读取功能
2. 验证 `clearTokens()` 后 `hasTokens()` 返回 false
3. 验证 `saveTokenPair(null)` 不会抛出异常

---

## 3.3 HTTP 客户端封装

### 3.3.1 TASK-006：实现 ApiClient（Dio 单例封装）

**任务ID：** `TASK-006`
**任务名称：** 实现 ApiClient（Dio 单例 HTTP 客户端封装）
**任务类型：** `frontend`
**关联UserStory：** `US-003`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-002`, `TASK-008`
- **下游任务：** `TASK-007`, `TASK-010`

#### 上下文读取

- **SDS 第 4.1.1 节：** 第 371-441 行（ApiClient 完整接口定义，含 DioException 分类处理表）
- **PRD US-003 AC1：** 第 162 行（baseUrl、超时、默认请求头配置）

#### 详细业务描述

在 `lib/core/http/api_client.dart` 文件中实现基于 Dio 的单例 HTTP 客户端 `ApiClient`：

```dart
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  // Dio 配置：
  // - baseUrl: ApiConfig.baseUrl (http://localhost:9000)
  // - connectTimeout: 15 秒
  // - receiveTimeout: 30 秒
  // - headers: Content-Type: application/json, Accept: application/json
  
  // 注册拦截器：
  // - _dio.interceptors.add(ApiInterceptor())

  // 公开方法：get、post、put、delete 封装 Dio 原生方法
}
```

关键细节：
- 单例模式实现
- 在构造函数中初始化 Dio 实例并注册拦截器
- 封装 get/post/put/delete 四个 HTTP 方法，参数兼容 Dio 的 Options、queryParameters
- 使用 SDS 第 4.1.1 节中的异常分类处理表对 DioException 进行归类

#### 测试验收方法

1. 单元测试验证 ApiClient 单例模式（两次 `ApiClient()` 返回同一实例）
2. 验证 Dio 实例的 baseUrl 配置为 `ApiConfig.baseUrl`
3. 验证 connectTimeout 和 receiveTimeout 配置正确

---

### 3.3.2 TASK-007：实现 ApiInterceptor（请求/响应拦截器）

**任务ID：** `TASK-007`
**任务名称：** 实现 ApiInterceptor（请求/响应拦截器 + Token 注入 + 自动刷新 + 刷新锁）
**任务类型：** `frontend`
**关联UserStory：** `US-003`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-005`, `TASK-006`
- **下游任务：** `TASK-010`

#### 上下文读取

- **SDS 第 4.1.2 节：** 第 443-525 行（ApiInterceptor 完整代码设计，含白名单路径、Token 刷新并发锁机制流程图）
- **SDS 第 5.1 节：** 第 1093-1103 行（Token 刷新锁机制设计说明）
- **PRD US-003 AC2-AC6：** 第 163-167 行（拦截器行为验收标准）

#### 详细业务描述

在 `lib/core/http/api_interceptor.dart` 文件中实现拦截器 `ApiInterceptor`：

**请求拦截（`onRequest`）：**
1. 判断路径是否在白名单中（登录、注册、刷新、验证码等路径不注入 Token）
2. 白名单路径直接放行
3. 非白名单路径从 SecureStorage 获取 access_token，注入 `Authorization: Bearer {token}`
4. 如果 Token 为空，不注入 Authorization 头

**响应拦截（`onError`）：**
1. 检测 HTTP 401 状态码
2. 非 401 错误直接传递到下层

**Token 自动刷新（`_handleTokenRefresh`）：**
1. 刷新锁机制（`_isRefreshing` 标志）
2. 第一个 401 请求触发 Token 刷新，后续请求加入等待队列
3. 调用 `/api/v1/auth/refresh` 获取新 Token
4. 刷新成功：更新 SecureStorage，重放等待队列中的所有请求
5. 刷新失败：清除 Token，跳转登录页
6. 刷新接口自身 401 不进入递归刷新（白名单判断）

**白名单路径：**
```dart
const whiteList = [
  '/api/v1/auth/login',
  '/api/v1/auth/register',
  '/api/v1/auth/refresh',
  '/api/v1/auth/verification-code/send',
  '/api/v1/auth/password/forgot/send-code',
  '/api/v1/auth/password/forgot/reset',
];
```

#### 测试验收方法

1. 单元测试验证白名单路径不注入 Token
2. 单元测试验证非白名单路径注入 Token
3. 验证 Token 为空时白名单和非白名单请求均不注入 Authorization 头
4. 模拟 401 响应，验证 Token 刷新流程被触发
5. 验证刷新锁机制：并发 2 个 401 请求，仅触发一次刷新 API 调用

---

## 3.4 配置类

### 3.4.1 TASK-008：实现 ApiConfig 和 ThemeConfig 配置类

**任务ID：** `TASK-008`
**任务名称：** 实现 ApiConfig 和 ThemeConfig 配置类
**任务类型：** `frontend`
**关联UserStory：** `US-001`, `US-002`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-001`
- **下游任务：** `TASK-006`, `TASK-014`, `TASK-015`

#### 上下文读取

- **SDS 附录 C：** 第 1439-1456 行（api_config.dart 和 theme_config.dart 默认值）
- **SDS 第 6.2 节：** 第 1173-1204 行（跨平台适配策略，clientType 检测逻辑）

#### 详细业务描述

在 `lib/config/api_config.dart` 中实现 API 配置类：

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:9000';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration readTimeout = Duration(seconds: 30);
  static String get clientType {
    if (kIsWeb) return 'H5';
    return 'WINDOWS';
  }
}
```

在 `lib/config/theme_config.dart` 中实现主题配置类：
- 设置 primaryColor 为 `Color(0xFF1976D2)`（蓝色主题）
- 配置 Material 3 主题
- 配置 InputDecoration 主题（圆角、边框色等）
- 配置 ElevatedButton 主题（圆角、背景色、禁用态）
- 配置 Text 主题（字号、字重、颜色）

#### 测试验收方法

1. 验证 ApiConfig.baseUrl 为 `http://localhost:9000`
2. 验证 ApiConfig.clientType 在 Web 返回 'H5'，Windows 返回 'WINDOWS'
3. 验证 ThemeConfig 返回的 ThemeData 包含正确的 primaryColor

---

# 4. 模块三：数据模型

## 4.1 认证数据模型

### 4.1.1 TASK-009：实现认证相关数据模型类

**任务ID：** `TASK-009`
**任务名称：** 实现认证相关 7 个数据模型类
**任务类型：** `frontend`
**关联UserStory：** `US-004`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-004`
- **下游任务：** `TASK-010`

#### 上下文读取

- **SDS 第 3.1.1 节：** 第 213-255 行（4 个请求模型完整定义：LoginRequest、RegisterRequest、SendVerificationCodeRequest、PasswordForgotRequest）
- **SDS 第 3.1.2 节：** 第 257-303 行（4 个响应模型完整定义：TokenPair、RegisterResult、UserInfo、ApiResult）
- **SDS 第 4.2 节：** 第 683-786 行（TokenPair、RegisterResult、UserInfo 的完整 Dart 代码）

#### 详细业务描述

在 `lib/features/auth/models/` 目录下实现以下 7 个数据模型类：

1. **LoginRequest**（`login_request.dart`）：包含 loginName、password、phone、smsCode、tenantCode、clientType、loginMode 字段，使用 `fromJson`/`toJson` 序列化

2. **RegisterRequest**（`register_request.dart`）：包含 loginName、password、userName、phone、email、registerMode、tenantCode 字段

3. **SendVerificationCodeRequest**（`send_verification_code_request.dart`）：包含 target、purpose、mode 字段

4. **PasswordForgotRequest**（`password_forgot_request.dart`）：包含 mode、target、code、newPassword 字段

5. **TokenPair**（`token_pair.dart`）：包含 accessToken、refreshToken、accessTokenExpireIn、refreshTokenExpireIn、tokenType 字段，完整 `fromJson`/`toJson`

6. **RegisterResult**（`register_result.dart`）：包含 userId、loginName、userName、accountSettled、tokenPair（嵌套 TokenPair 对象）

7. **UserInfo**（`user_info.dart`）：包含 userId、loginName、userName、phone、email、avatar 字段

注意：所有模型使用手写 `fromJson`/`toJson`（不引入 json_serializable），遵循 SDS 第 4.2 节中的代码模板。

#### 测试验收方法

1. 单元测试验证每个模型的 `fromJson` 能正确解析 JSON 数据
2. 单元测试验证 `toJson` 能正确序列化为 JSON Map
3. 验证嵌套模型（RegisterResult 中的 tokenPair）反序列化正确
4. 验证 JSON 中值为 null 的字段在模型中为 null

---

# 5. 模块四：数据仓库（Repository）

## 5.1 Auth API 数据仓库

### 5.1.1 TASK-010：实现 AuthRepository

**任务ID：** `TASK-010`
**任务名称：** 实现 AuthRepository 封装 6 个认证 API
**任务类型：** `frontend`
**关联UserStory：** `US-004`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-004`, `TASK-006`, `TASK-009`
- **下游任务：** `TASK-011`, `TASK-012`, `TASK-013`

#### 上下文读取

- **SDS 第 4.1.3 节：** 第 527-618 行（AuthRepository 完整接口定义，含 6 个方法的详细签名、API 路径、错误场景、统一处理逻辑代码）
- **SDS 附录 B：** 第 1427-1437 行（后端 API 端点速查表）
- **PRD 第 5.1 节：** 第 581-591 行（API 对接清单）

#### 详细业务描述

在 `lib/features/auth/repositories/auth_repository.dart` 文件中实现 `AuthRepository`，封装以下 6 个认证 API 调用方法：

1. **login(LoginRequest)** → `POST /api/v1/auth/login` → `ApiResult<TokenPair>`
2. **register(RegisterRequest)** → `POST /api/v1/auth/register` → `ApiResult<RegisterResult>`
3. **refreshToken(String)** → `POST /api/v1/auth/refresh` → `ApiResult<TokenPair>`
4. **logout()** → `POST /api/v1/auth/logout` → `ApiResult<void>`
5. **sendVerificationCode(target, purpose, mode)** → `POST /api/v1/auth/verification-code/send` → `ApiResult<void>`
6. **forgotPasswordReset(mode, target, code, newPassword)** → `POST /api/v1/auth/password/forgot/reset` → `ApiResult<void>`

所有方法遵循统一错误处理模式（SDS 第 4.1.3 节代码块）：
- 调用 `ApiClient.post()` 发送 HTTP 请求
- 响应通过 `ApiResult.fromJson()` 反序列化
- DioException 转换为友好提示的 ApiResult
- 未知异常兜底返回"服务器响应异常"

#### 测试验收方法

1. 单元测试验证每个方法对应正确的 API 路径和 HTTP 方法
2. 验证 `login()` 调用 `POST /api/v1/auth/login` 并传递正确的请求体
3. 验证 DioException 被转换为 ApiResult.error 返回
4. 验证成功响应被正确反序列化为对应的模型类型

---

# 6. 模块五：状态管理（Provider）

## 6.1 AuthProvider

### 6.1.1 TASK-011：实现 AuthProvider

**任务ID：** `TASK-011`
**任务名称：** 实现 AuthProvider（登录/注册/登出状态管理）
**任务类型：** `frontend`
**关联UserStory：** `US-004`, `US-005`, `US-007`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-005`, `TASK-010`
- **下游任务：** `TASK-014`, `TASK-019`, `TASK-021`

#### 上下文读取

- **SDS 第 4.3.1 节：** 第 800-893 行（AuthProvider 完整接口定义，含状态属性、方法签名、状态流转矩阵）
- **SDS 第 4.4.3 节：** 第 1060-1087 行（Provider 层错误处理规范代码）

#### 详细业务描述

在 `lib/features/auth/providers/auth_provider.dart` 文件中实现 `AuthProvider`（继承 `ChangeNotifier`）：

**状态属性：**
- `isLoading` — 是否正在加载
- `errorMessage` — 错误信息
- `currentUser` — 当前用户信息（UserInfo）
- `isLoggedIn` — 是否已登录

**认证方法：**
- `login(loginName, password)` — 用户名密码登录，成功后保存 Token，设置 currentUser，更新 isLoggedIn
- `loginWithSmsCode(phone, smsCode)` — 手机验证码登录
- `register(loginName, password, userName)` — 用户名模式注册
- `registerWithPhone(phone, smsCode, userName)` — 手机号模式注册
- `logout()` — 登出，调用后端 API，无论成功与否清除本地 Token
- `checkLoginStatus()` — 检查 SecureStorage 中是否存在 access_token

**内部方法：**
- `_saveTokenPair()` / `_clearTokens()` — Token 持久化管理
- `_setLoading()` / `_setError()` — 状态设置 + notifyListeners

状态流转遵循 SDS 第 4.3.1 节的状态流转矩阵。

#### 测试验收方法

1. 单元测试验证 `login()` 调用 AuthRepository.login()
2. 验证登录成功后 `isLoggedIn` 为 true，Token 被保存
3. 验证登录失败后 `errorMessage` 不为 null，`isLoggedIn` 为 false
4. 验证 `logout()` 清除 Token 并设置 `isLoggedIn` 为 false
5. 验证 `checkLoginStatus()` 根据 Token 存在性返回正确值

---

## 6.2 ForgotPasswordProvider

### 6.2.1 TASK-012：实现 ForgotPasswordProvider

**任务ID：** `TASK-012`
**任务名称：** 实现 ForgotPasswordProvider（两步找回密码状态管理）
**任务类型：** `frontend`
**关联UserStory：** `US-009`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-010`
- **下游任务：** `TASK-023`

#### 上下文读取

- **SDS 第 4.3.2 节：** 第 895-999 行（ForgotPasswordProvider 完整接口定义，含验证码倒计时实现、Timer 资源管理）
- **SDS 第 1.3 节工作流 4：** 第 127-137 行（找回密码流程描述）

#### 详细业务描述

在 `lib/features/auth/providers/forgot_password_provider.dart` 文件中实现 `ForgotPasswordProvider`：

**步骤状态：**
- `currentStep` — 0=身份验证, 1=重置密码
- `isLoading`、`errorMessage` — 通用状态

**第一步（身份验证）相关：**
- `verificationMode` — 验证方式（SMS / EMAIL）
- `target` — 目标（手机号或邮箱）
- `verificationCode` — 验证码
- `countdownSeconds` — 验证码倒计时（60s）
- `codeSent` — 验证码是否已发送
- `identityVerified` — 身份验证是否通过

**第二步（重置密码）相关：**
- `newPassword`、`confirmPassword` — 新密码和确认密码
- `successCountdown` — 重置成功倒计时（3s）
- `resetSuccessful` — 重置是否成功

**方法：**
- `sendVerificationCode()` — 发送验证码，启动 60s 倒计时
- `verifyIdentity()` — 校验验证码通过后进入第二步
- `resetPassword()` — 提交密码重置，成功后启动 3s 倒计时
- `startCountdown()` / `startSuccessCountdown()` — Timer.periodic 实现倒计时
- `dispose()` — 释放 Timer 资源，防止泄漏

#### 测试验收方法

1. 验证 `sendVerificationCode()` 调用 AuthRepository.sendVerificationCode()
2. 验证倒计时行为：`countdownSeconds` 从 60 递减到 0，到 0 时 `codeSent` 为 false
3. 验证 `verifyIdentity()` 成功后 `identityVerified` 为 true，`currentStep` 变为 1
4. 验证 `resetPassword()` 成功后 `resetSuccessful` 为 true，`successCountdown` 为 3
5. 验证 `dispose()` 后 Timer 已取消

---

## 6.3 HomeProvider

### 6.3.1 TASK-013：实现 HomeProvider

**任务ID：** `TASK-013`
**任务名称：** 实现 HomeProvider（首页用户信息状态管理）
**任务类型：** `frontend`
**关联UserStory：** `US-010`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-010`
- **下游任务：** `TASK-024`

#### 上下文读取

- **SDS 第 4.3.3 节：** 第 1001-1026 行（HomeProvider 完整接口定义）
- **PRD US-010：** 第 487-530 行（首页功能描述，退出登录行为）

#### 详细业务描述

在 `lib/features/home/providers/home_provider.dart` 文件中实现 `HomeProvider`：

```dart
class HomeProvider extends ChangeNotifier {
  bool isLoading = false;
  UserInfo? userInfo;

  // 加载用户信息（从登录时保存的数据或 API 获取）
  Future<void> loadUserInfo();

  // 退出登录
  Future<void> logout();
}
```

**`logout()` 方法逻辑：**
1. 调用 `AuthRepository.logout()` API
2. 无论成功与否，清除 SecureStorage 中的 Token
3. 通过 AuthProvider 或路由跳转登录页
4. 注意：退出登录 API 调用失败（网络异常）时，依然清除本地 Token 并跳转登录页

#### 测试验收方法

1. 单元测试验证 `logout()` 调用 AuthRepository.logout()
2. 验证退出后清除 Token
3. 验证 `loadUserInfo()` 正确设置 `userInfo` 属性

---

# 7. 模块六：路由与入口配置

## 7.1 路由配置

### 7.1.1 TASK-014：实现 AppRouter（GoRouter 路由表 + 路由守卫）

**任务ID：** `TASK-014`
**任务名称：** 实现 AppRouter（GoRouter 路由表 + 路由守卫）
**任务类型：** `frontend`
**关联UserStory：** `US-001`, `US-005`, `US-010`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-011`, `TASK-015`
- **下游任务：** `TASK-019`, `TASK-021`, `TASK-023`, `TASK-024`

#### 上下文读取

- **SDS 第 4.1.4 节：** 第 620-679 行（AppRouter 完整代码设计，含 GoRouter 路由声明和路由守卫逻辑）
- **PRD US-010 AC3：** 第 507 行（路由守卫：Token 无效时自动跳转登录页）
- **PRD US-005 AC4：** 第 265 行（已登录用户访问登录页自动跳转首页）

#### 详细业务描述

在 `lib/core/router/app_router.dart` 文件中实现 `AppRouter`：

**路由表（4 个路由）：**
- `/login` → LoginScreen（登录页）
- `/register` → RegisterScreen（注册页）
- `/forgot-password` → ForgotPasswordScreen（找回密码页）
- `/` → HomeScreen（首页）

**路由守卫（`_guard` 回调）：**
1. 已登录用户访问 `/login`、`/register`、`/forgot-password` → 重定向到 `/`
2. 未登录用户访问 `/` → 重定向到 `/login`
3. 其他情况不重定向（返回 null）

关键细节：
- 路由守卫使用 `context.read<AuthProvider>()` 获取登录状态
- 初始路由设置为 `/login`
- 使用 `GoRouter` 的 `redirect` 参数实现守卫逻辑

#### 测试验收方法

1. 验证 GoRouter 配置包含 4 个路由
2. 验证未登录时访问 `/` 被重定向到 `/login`
3. 验证已登录时访问 `/login` 被重定向到 `/`
4. 验证 GoRouter 能正确构建页面

---

## 7.2 应用入口

### 7.2.1 TASK-015：实现 main.dart 和 app.dart

**任务ID：** `TASK-015`
**任务名称：** 实现 main.dart 和 app.dart 应用入口与 Provider 注册
**任务类型：** `frontend`
**关联UserStory：** `US-001`, `US-005`, `US-007`, `US-009`, `US-010`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-008`, `TASK-011`, `TASK-012`, `TASK-013`, `TASK-014`
- **下游任务：** `TASK-019`, `TASK-021`, `TASK-023`, `TASK-024`

#### 上下文读取

- **SDS 第 6.3.1 节：** 第 1210-1236 行（目录结构约定，main.dart 和 app.dart 位置）
- **SDS 第 1.2 节：** 第 46-85 行（架构图中 app.dart 和 main.dart 的角色）
- **PRD 第 5.3 节：** 第 607-643 行（目录结构中 main.dart 和 app.dart 说明）

#### 详细业务描述

实现两个应用入口文件：

**`lib/main.dart`：** Flutter 应用入口
```dart
void main() {
  runApp(const CloudStrollOfficeApp());
}
```

**`lib/app.dart`：** MaterialApp 配置（`CloudStrollOfficeApp` Widget）
```dart
class CloudStrollOfficeApp extends StatelessWidget {
  // MultiProvider 注册：
  // - ChangeNotifierProvider<AuthProvider>
  // - ChangeNotifierProvider<ForgotPasswordProvider>
  // - ChangeNotifierProvider<HomeProvider>
  
  // MaterialApp.router 配置：
  // - title: '云漫智企'
  // - theme: ThemeConfig.lightTheme
  // - routerConfig: AppRouter().router
}
```

关键细节：
- 使用 `MultiProvider` 在应用顶层注册所有 Provider
- 使用 `MaterialApp.router` 方式集成 GoRouter
- 应用主题从 `ThemeConfig` 获取

#### 测试验收方法

1. 验证 `main()` 函数可正常启动应用（不崩溃）
2. 验证 `CloudStrollOfficeApp` 包含所有 3 个 Provider 注册
3. 验证 MaterialApp 正确配置 theme 和 router

---

# 8. 模块七：共享组件（shared）

## 8.1 校验工具与常量

### 8.1.1 TASK-016：实现表单校验工具函数和常量定义

**任务ID：** `TASK-016`
**任务名称：** 实现表单校验工具函数和常量定义
**任务类型：** `frontend`
**关联UserStory：** `US-005`, `US-007`, `US-009`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-001`
- **下游任务：** `TASK-017`, `TASK-019`, `TASK-021`, `TASK-023`

#### 上下文读取

- **SDS 第 5.3 节：** 第 1116-1137 行（客户端校验规则一览表，含正则和提示信息）
- **SDS 附录 C：** 第 1443-1448 行（api_config.dart 默认值）

#### 详细业务描述

**`lib/core/utils/validators.dart`：** 实现表单校验工具函数

```dart
class Validators {
  /// 校验登录名（4-64 字符，字母数字下划线）
  static String? validateLoginName(String? value);

  /// 校验密码（8-64 字符）
  static String? validatePassword(String? value);

  /// 校验确认密码（与密码一致）
  static String? validateConfirmPassword(String? value, String password);

  /// 校验手机号（11 位，1[3-9]开头）
  static String? validatePhone(String? value);

  /// 校验验证码（6 位数字）
  static String? validateVerificationCode(String? value);

  /// 校验真实姓名（2-50 字符）
  static String? validateUserName(String? value);
}
```

校验规则来自 SDS 第 5.3 节校验规则一览表。

**`lib/shared/constants/app_constants.dart`：** 常量定义
- `kApiBaseUrl` — API 基础地址
- `kPasswordMinLength` — 密码最小长度 8
- `kPasswordMaxLength` — 密码最大长度 64
- `kCountdownSeconds` — 验证码倒计时秒数 60
- `kSuccessCountdownSeconds` — 成功倒计时秒数 3
- `kCodeLength` — 验证码长度 6

#### 测试验收方法

1. 单元测试验证所有校验函数在合法输入时返回 null
2. 验证所有校验函数在非法输入时返回对应的错误提示
3. 验证 `validateConfirmPassword` 在两次密码不一致时返回正确的错误信息

---

## 8.2 基础表单组件

### 8.2.1 TASK-017：实现公共表单组件

**任务ID：** `TASK-017`
**任务名称：** 实现 CustomTextField、PasswordField、LoadingButton 组件
**任务类型：** `frontend`
**关联UserStory：** `US-005`, `US-007`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-016`
- **下游任务：** `TASK-019`, `TASK-021`, `TASK-023`

#### 上下文读取

- **SDS 第 1.4 节：** 第 141-151 行（关键设计原则中的防重复提交、LoadingButton）
- **PRD US-005 交付物：** 第 280-289 行（CustomTextField、PasswordField、LoadingButton 交付物列表）
- **PRD US-007 交付物：** 第 379-388 行（公共组件需求）

#### 详细业务描述

在 `lib/shared/widgets/` 目录下实现三个公共表单组件：

**`custom_text_field.dart` — CustomTextField：**
- 基于 `TextFormField` 封装
- 支持属性：labelText、hintText、prefixIcon、validator、onChanged、keyboardType
- 统一材质设计风格（圆角、边框色）
- 支持错误状态显示

**`password_field.dart` — PasswordField：**
- 继承 CustomTextField 样式
- 包含显示/隐藏密码切换（眼睛图标按钮）
- 默认 `obscureText: true`
- 支持 `suffixIcon` 自定义

**`loading_button.dart` — LoadingButton：**
- 基于 `ElevatedButton` 封装
- `isLoading` 属性控制加载状态
- 加载状态下显示 `CircularProgressIndicator`，按钮禁用
- 支持 `label`（按钮文本）和 `onPressed` 回调
- 防止重复提交（加载状态下 `onPressed` 为 null）

#### 测试验收方法

1. 组件预览验证 CustomTextField 正常显示标签和提示文本
2. 验证 PasswordField 点击眼睛图标切换密码可见性
3. 验证 LoadingButton 在 `isLoading=true` 时显示加载动画且禁用点击
4. 验证 LoadingButton 在 `isLoading=false` 时正常响应点击

---

## 8.3 验证码与密码强度组件

### 8.3.1 TASK-018：实现 VerificationCodeField 和 PasswordStrengthIndicator

**任务ID：** `TASK-018`
**任务名称：** 实现验证码输入框组件和密码强度指示器组件
**任务类型：** `frontend`
**关联UserStory：** `US-006`, `US-008`, `US-009`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-016`
- **下游任务：** `TASK-019`, `TASK-022`, `TASK-023`

#### 上下文读取

- **PRD US-006 交付物：** 第 330-338 行（VerificationCodeField 需求）
- **PRD US-007 交付物：** 第 379-388 行（PasswordStrengthIndicator 需求，密码强度计算规则）
- **SDS 第 5.3 节：** 第 1127-1137 行（验证码校验规则 6 位数字）

#### 详细业务描述

**`verification_code_field.dart` — VerificationCodeField：**
- 手机号输入框 + 获取验证码按钮组合组件
- `phoneController` — 手机号输入控制器
- `codeController` — 验证码输入控制器
- `countdownSeconds` — 倒计时秒数（外部传入，由 Provider 管理）
- `isCountingDown` — 是否正在倒计时
- `onSendCode` — 获取验证码回调
- 手机号未输入或格式错误时，获取验证码按钮禁用
- 验证码输入框自动限制 6 位数字输入

**`password_strength_indicator.dart` — PasswordStrengthIndicator：**
- 输入密码时实时显示强度等级
- 三个等级：弱（红色）、中（橙色）、强（绿色）
- 计算规则（SDS PRD US-007 备注）：
  - 弱（仅字母或仅数字，长度 < 10）
  - 中（字母+数字，长度 < 12）
  - 强（字母+数字+特殊字符，长度 >= 12）
- 以进度条或分段指示器形式展示

#### 测试验收方法

1. 验证 VerificationCodeField 手机号输入验证功能
2. 验证获取验证码按钮的禁用/启用逻辑正确
3. 验证 PasswordStrengthIndicator 对不同密码返回正确的强度等级
4. 验证密码强度指示器颜色随强度变化正确

---

# 9. 模块八：页面实现

## 9.1 登录页面

### 9.1.1 TASK-019：实现 LoginScreen（用户名密码登录模式）

**任务ID：** `TASK-019`
**任务名称：** 实现 LoginScreen 基础版（用户名密码登录模式）
**任务类型：** `frontend`
**关联UserStory：** `US-005`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-011`, `TASK-014`, `TASK-016`, `TASK-017`
- **下游任务：** `TASK-020`, `TASK-024`

#### 上下文读取

- **PRD US-005：** 第 243-291 行（完整页面描述、AC1-AC6 验收标准、边界情况处理）
- **SDS 第 1.3 节工作流 1：** 第 89-98 行（用户登录流程）
- **SDS 第 4.3.1 节：** 第 800-893 行（AuthProvider 登录方法定义）

#### 详细业务描述

在 `lib/features/auth/screens/login_screen.dart` 文件中实现登录页面：

**页面布局（AC1）：**
- 顶部显示应用 Logo（AppLogo 组件，可先用文本占位）
- 登录表单：登录名输入框（CustomTextField）、密码输入框（PasswordField）
- 登录按钮（LoadingButton）
- "没有账号？去注册"链接 → 跳转 `/register`
- "忘记密码？"链接 → 跳转 `/forgot-password`
- "记住我"复选框（保存登录名到 SharedPreferences）

**交互逻辑（AC2-AC6）：**
- 表单提交前进行前端校验（Validators）
- 点击登录：调用 `AuthProvider.login()`，显示加载状态
- 登录成功：GoRouter 自动跳转首页
- 登录失败：显示错误信息
- 前端校验拦截：登录名为空、密码长度不足时显示错误提示
- "记住我"功能：仅保存登录名，不保存密码

#### 测试验收方法

1. Widget 测试验证页面元素完整显示（Logo、表单、按钮、链接）
2. 验证点击登录按钮触发 `AuthProvider.login()`
3. 验证登录失败时错误信息显示
4. 验证"记住我"功能保存登录名

---

### 9.1.2 TASK-020：扩展 LoginScreen 支持手机验证码登录模式

**任务ID：** `TASK-020`
**任务名称：** 扩展 LoginScreen 支持手机验证码登录 Tab 切换
**任务类型：** `frontend`
**关联UserStory：** `US-006`
**优先级：** `P2`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-019`
- **下游任务：** 无

#### 上下文读取

- **PRD US-006：** 第 293-338 行（完整多模式登录描述、AC1-AC6 验收标准）
- **SDS 第 4.3.1 节：** 第 825-835 行（AuthProvider 的 loginWithSmsCode 方法）

#### 详细业务描述

扩展 `LoginScreen` 增加多模式登录 Tab 切换：

**Tab 栏（AC1）：**
- "密码登录"（默认选中）和"验证码登录"两个 Tab
- 使用 `TabBar` 或自定义 SegmentedButton

**验证码登录模式（AC2-AC5）：**
- 手机号输入框（复用 VerificationCodeField 组件）
- 获取验证码按钮 + 60 秒倒计时
- 验证码输入框（6 位数字）
- 输入 11 位有效手机号后可用获取验证码
- 密码输入框隐藏（密码模式下显示）

**交互逻辑（AC6）：**
- 切换 Tab 时保留已输入内容（Provider 中维护各模式表单状态）
- 验证码模式登录时 `loginMode` 参数为 `SMS`
- 倒计时使用 Provider 管理，切换到验证码 Tab 时恢复倒计时状态

#### 测试验收方法

1. 验证两个 Tab 可正常切换
2. 验证验证码模式下表单元素与密码模式不同
3. 验证获取验证码按钮逻辑正确（手机号校验、倒计时）
4. 验证验证码模式下登录调用 `AuthProvider.loginWithSmsCode()`

---

## 9.2 注册页面

### 9.2.1 TASK-021：实现 RegisterScreen（用户名密码注册模式）

**任务ID：** `TASK-021`
**任务名称：** 实现 RegisterScreen 基础版（用户名密码注册模式）
**任务类型：** `frontend`
**关联UserStory：** `US-007`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-011`, `TASK-014`, `TASK-016`, `TASK-017`, `TASK-018`
- **下游任务：** `TASK-022`

#### 上下文读取

- **PRD US-007：** 第 341-388 行（完整页面描述、AC1-AC6 验收标准、边界情况处理）
- **SDS 第 1.3 节工作流 2：** 第 100-110 行（用户注册流程）
- **SDS 第 4.3.1 节：** 第 837-844 行（AuthProvider 的 register 方法）

#### 详细业务描述

在 `lib/features/auth/screens/register_screen.dart` 文件中实现注册页面：

**页面布局（AC1）：**
- 顶部显示应用 Logo
- "注册新账号"标题
- 注册表单：用户名输入框、真实姓名输入框、密码输入框（PasswordField）、确认密码输入框
- 注册按钮（LoadingButton）
- "已有账号？去登录"链接 → 跳转 `/login`

**交互逻辑（AC2-AC6）：**
- 表单实时校验 + onBlur 校验（Validators）
- 密码输入时实时显示密码强度指示器（PasswordStrengthIndicator）
- 用户名正则校验：`^[a-zA-Z0-9_]{4,64}$`
- 确认密码与密码一致性校验
- 点击注册：调用 `AuthProvider.register()`，显示加载状态
- 注册成功：保存 Token 并跳转首页
- 注册失败（用户名已存在等）：显示后端返回的错误信息

#### 测试验收方法

1. Widget 测试验证页面元素完整显示
2. 验证点击注册按钮触发 `AuthProvider.register()`
3. 验证表单校验功能（用户名格式、密码强度、确认密码一致）
4. 验证密码强度指示器实时响应密码输入变化

---

### 9.2.2 TASK-022：扩展 RegisterScreen 支持手机号注册模式

**任务ID：** `TASK-022`
**任务名称：** 扩展 RegisterScreen 支持手机号注册 Tab 切换
**任务类型：** `frontend`
**关联UserStory：** `US-008`
**优先级：** `P2`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-021`
- **下游任务：** 无

#### 上下文读取

- **PRD US-008：** 第 391-433 行（完整多模式注册描述、AC1-AC6 验收标准）
- **SDS 第 4.3.1 节：** 第 845-850 行（AuthProvider 的 registerWithPhone 方法）

#### 详细业务描述

扩展 `RegisterScreen` 增加多模式注册 Tab 切换：

**Tab 栏（AC1）：**
- "用户名注册"（默认选中）和"手机号注册"两个 Tab

**手机号注册模式（AC2-AC4）：**
- 手机号输入框（复用 VerificationCodeField）
- 真实姓名输入框（保留）
- 获取验证码按钮 + 60 秒倒计时（purpose=REGISTER）
- 验证码输入框（6 位数字）
- 密码输入框和确认密码输入框隐藏

**交互逻辑（AC5-AC6）：**
- 公共字段（真实姓名）的输入在切换 Tab 时保留
- 私有字段（用户名/密码 或 手机号/验证码）切换时重置
- 手机号注册时 `registerMode` 参数为 `PHONE`
- 手机号格式校验拦截无效请求

#### 测试验收方法

1. 验证两个 Tab 可正常切换
2. 验证手机号模式下表单元素变化正确
3. 验证切换 Tab 时公共字段保留、私有字段重置
4. 验证手机号注册调用 `AuthProvider.registerWithPhone()`

---

## 9.3 找回密码页面

### 9.3.1 TASK-023：实现 ForgotPasswordScreen

**任务ID：** `TASK-023`
**任务名称：** 实现 ForgotPasswordScreen（两步找回密码流程）
**任务类型：** `frontend`
**关联UserStory：** `US-009`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-012`, `TASK-014`, `TASK-016`, `TASK-017`, `TASK-018`
- **下游任务：** 无

#### 上下文读取

- **PRD US-009：** 第 437-483 行（完整页面描述、AC1-AC6 验收标准、边界情况）
- **SDS 第 1.3 节工作流 4：** 第 127-137 行（找回密码流程）
- **SDS 第 4.3.2 节：** 第 895-999 行（ForgotPasswordProvider 完整接口）

#### 详细业务描述

在 `lib/features/auth/screens/forgot_password_screen.dart` 文件中实现找回密码页面：

**页面布局（AC1）：**
- "找回密码"标题
- 步骤指示器（Step 1: 身份验证 → Step 2: 重置密码）
- "返回登录"链接 → 跳转 `/login`

**Step 1 — 身份验证（AC2, AC4）：**
- 验证方式选择（短信/邮箱，本期优先实现短信方式）
- 目标输入框（手机号或邮箱）
- 获取验证码按钮 + 60 秒倒计时（VerificationCodeField 组件）
- 验证码输入框（6 位数字）
- "下一步"按钮（仅在验证码输入后可用）

**Step 2 — 重置密码（AC3, AC5, AC6）：**
- 新密码输入框（PasswordField + PasswordStrengthIndicator）
- 确认密码输入框
- "重置密码"按钮（LoadingButton）
- 成功提示："密码重置成功，3 秒后自动跳转登录页"（倒计时）

**交互逻辑：**
- 使用 `ForgotPasswordProvider` 管理两步流程状态
- 步骤间过渡使用 AnimatedSwitcher 或 PageView 平滑动画
- 第一步通过验证后才能进入第二步
- 密码重置成功后 3 秒自动跳转登录页

#### 测试验收方法

1. Widget 测试验证页面元素完整显示
2. 验证两步流程的步骤切换逻辑
3. 验证获取验证码和倒计时功能
4. 验证密码重置成功后的倒计时跳转

---

## 9.4 首页

### 9.4.1 TASK-024：实现 HomeScreen

**任务ID：** `TASK-024`
**任务名称：** 实现 HomeScreen（用户信息展示 + 退出登录）
**任务类型：** `frontend`
**关联UserStory：** `US-010`
**优先级：** `P2`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-013`, `TASK-014`
- **下游任务：** 无

#### 上下文读取

- **PRD US-010：** 第 487-530 行（完整首页描述、AC1-AC4 验收标准、边界情况）
- **SDS 第 4.3.3 节：** 第 1001-1026 行（HomeProvider 接口定义）

#### 详细业务描述

在 `lib/features/home/screens/home_screen.dart` 文件中实现首页页面：

**页面布局（AC1）：**
- 顶部导航栏：应用名称"云漫智企"（左侧）+ "退出登录"按钮（右侧）
- 主内容区域：
  - 欢迎信息（"欢迎回来，{userName}"）
  - 用户基本信息卡片：登录名、真实姓名、手机号（脱敏）、邮箱（脱敏）
  - 预留底部导航区域（后续版本添加业务功能入口）

**交互逻辑（AC2-AC4）：**
- 退出登录：弹出确认对话框 → 确认后调用 `HomeProvider.logout()`
- 退出成功：清除 Token，跳转登录页
- 退出失败（API 调用失败）：仍清除本地 Token，跳转登录页（离线退出）
- 页面内容自适应窗口尺寸（响应式布局）

#### 测试验收方法

1. Widget 测试验证页面元素完整显示
2. 验证退出登录点击弹出确认对话框
3. 验证确认后调用 HomeProvider.logout()
4. 验证用户信息正常展示

---

# 10. 模块九：测试

## 10.1 核心层与数据仓库测试

### 10.1.1 TASK-025：编写核心层和数据仓库单元测试

**任务ID：** `TASK-025`
**任务名称：** 编写核心层和数据仓库单元测试
**任务类型：** `test`
**关联UserStory：** `US-003`, `US-004`
**优先级：** `P2`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-004`, `TASK-005`, `TASK-006`, `TASK-007`, `TASK-008`, `TASK-009`, `TASK-010`
- **下游任务：** 无

#### 上下文读取

- **SDS 第 4.1.1 节：** 第 371-441 行（ApiClient 接口和异常处理矩阵）
- **SDS 第 4.1.2 节：** 第 443-525 行（ApiInterceptor 白名单和刷新锁逻辑）
- **SDS 第 4.1.3 节：** 第 527-618 行（AuthRepository 6 个方法签名和错误场景）
- **SDS 第 3.2 节：** 第 317-338 行（SecureStorage 设计）
- **PRD US-003 验收标准：** 第 162-167 行
- **PRD US-004 验收标准：** 第 211-218 行

#### 详细业务描述

在 `test/` 目录下编写以下单元测试：

**`test/core/http/api_result_test.dart`：**
- 测试 `fromJson` 工厂构造函数
- 测试 `isSuccess()` 方法
- 测试 `toJson()` 序列化
- 测试静态工厂方法 `success()` 和 `error()`

**`test/core/http/api_client_test.dart`：**
- 测试单例模式
- 测试 Dio 实例基础配置

**`test/core/http/api_interceptor_test.dart`：**
- 测试白名单路径不注入 Token
- 测试非白名单路径注入 Token
- 测试 Token 为空时不注入 Authorization 头
- 测试 401 响应触发 Token 刷新流程
- 测试刷新锁机制（并发 401 只触发一次刷新）

**`test/core/storage/secure_storage_test.dart`：**
- 测试保存和读取 Token
- 测试清除 Token
- 测试 hasTokens 方法

**`test/features/auth/repositories/auth_repository_test.dart`：**
- 测试 `login()` 调用正确的 API 路径和请求体
- 测试 `register()` 调用正确的 API 路径和请求体
- 测试 `refreshToken()` 调用正确的 API 路径
- 测试 `logout()` 调用正确的 API 路径
- 测试 `sendVerificationCode()` 调用正确的 API 路径
- 测试 `forgotPasswordReset()` 调用正确的 API 路径
- 测试 DioException 被转换为 ApiResult.error
- 测试成功响应被正确反序列化

**`test/features/auth/models/`：**
- 为 7 个数据模型类编写序列化/反序列化测试

#### 测试验收方法

1. 运行 `flutter test` 所有测试通过
2. 每个测试文件测试覆盖正常路径和边界情况
3. Mockito 模拟 Dio 和 SecureStorage 依赖

---

## 10.2 Provider 层测试

### 10.2.1 TASK-026：编写 Provider 层单元测试

**任务ID：** `TASK-026`
**任务名称：** 编写 Provider 层单元测试
**任务类型：** `test`
**关联UserStory：** `US-005`, `US-007`, `US-009`, `US-010`
**优先级：** `P2`
**当前状态：** `pending`

#### 上下游任务

- **上游任务：** `TASK-011`, `TASK-012`, `TASK-013`
- **下游任务：** 无

#### 上下文读取

- **SDS 第 4.3.1 节：** 第 800-893 行（AuthProvider 状态流转矩阵和方法定义）
- **SDS 第 4.3.2 节：** 第 895-999 行（ForgotPasswordProvider 状态和倒计时逻辑）
- **SDS 第 4.3.3 节：** 第 1001-1026 行（HomeProvider 接口定义）
- **SDS 第 4.4.3 节：** 第 1060-1087 行（Provider 错误处理规范）

#### 详细业务描述

在 `test/` 目录下编写以下单元测试：

**`test/features/auth/providers/auth_provider_test.dart`：**
- 测试 `login()` 调用成功：isLoggedIn=true, currentUser 不为 null, isLoading=false
- 测试 `login()` 调用失败：errorMessage 不为 null, isLoggedIn=false
- 测试 `register()` 调用成功：isLoggedIn=true, Token 被保存
- 测试 `logout()`：Token 被清除, isLoggedIn=false
- 测试 `checkLoginStatus()`：Token 存在返回 true，不存在返回 false
- 测试 loading 状态在请求开始时为 true，请求完成后为 false

**`test/features/auth/providers/forgot_password_provider_test.dart`：**
- 测试 `sendVerificationCode()` 成功后触发倒计时
- 测试倒计时从 60 递减到 0
- 测试倒计时结束后按钮恢复可用
- 测试 `verifyIdentity()` 成功后切换到第二步
- 测试 `resetPassword()` 成功后显示倒计时
- 测试 `dispose()` 释放 Timer

**`test/features/home/providers/home_provider_test.dart`：**
- 测试 `logout()` 调用 AuthRepository.logout()
- 测试退出后清除 Token 的状态
- 测试 `loadUserInfo()` 正确设置 userInfo

#### 测试验收方法

1. 运行 `flutter test` 所有测试通过
2. 使用 Mockito 模拟 AuthRepository 依赖
3. 每个 Provider 的关键状态流转被覆盖测试
4. ForgotPasswordProvider 的倒计时测试使用 FakeAsync 或手动控制时间

---

# 附录

## 任务依赖关系图

```
TASK-001 (子项目创建)
  ├── TASK-002 (pubspec.yaml)
  │   ├── TASK-003 (平台配置)
  │   │   └── TASK-008 (配置类)
  │   │       ├── TASK-006 (ApiClient)
  │   │       │   └── TASK-007 (ApiInterceptor)
  │   │       └── TASK-015 (app.dart)
  │   │           ├── TASK-014 (AppRouter)
  │   │           │   ├── TASK-019 (LoginScreen)
  │   │           │   │   └── TASK-020 (多模式登录)
  │   │           │   ├── TASK-021 (RegisterScreen)
  │   │           │   │   └── TASK-022 (多模式注册)
  │   │           │   ├── TASK-023 (ForgotPasswordScreen)
  │   │           │   └── TASK-024 (HomeScreen)
  │   │           └── TASK-011 (AuthProvider)
  │   │               ├── TASK-019
  │   │               └── TASK-021
  │   ├── TASK-004 (ApiResult)
  │   │   └── TASK-009 (数据模型)
  │   │       └── TASK-010 (AuthRepository)
  │   │           ├── TASK-011
  │   │           ├── TASK-012 (ForgotPasswordProvider)
  │   │           │   └── TASK-023
  │   │           └── TASK-013 (HomeProvider)
  │   │               └── TASK-024
  │   └── TASK-005 (SecureStorage)
  │       ├── TASK-007
  │       └── TASK-011
  ├── TASK-016 (校验工具+常量)
  │   ├── TASK-017 (表单组件)
  │   │   ├── TASK-019
  │   │   ├── TASK-021
  │   │   └── TASK-023
  │   └── TASK-018 (验证码+密码强度)
  │       ├── TASK-019
  │       ├── TASK-022
  │       └── TASK-023
  └── TASK-025 (核心层测试) ── 依赖: TASK-004~TASK-010
  └── TASK-026 (Provider测试) ── 依赖: TASK-011~TASK-013
```
