# 任务上下文（TASK-005 保障既有接口契约无回归并输出 v0.2.6 回归报告）

## 1. 任务信息

- **任务编号**：TASK-005
- **任务名称**：保障既有接口契约无回归并输出 v0.2.6 回归报告（cso-api-test-v0.2.5.py，TC-046~051）
- **任务类型**：common（测试验证类）
- **用户故事**：US-004（保障既有接口契约无回归，关联 PRD 功能 F-005）
- **优先级**：P1
- **状态**：未完成
- **上游依赖**：TASK-003（服务启动与健康检查验证通过）
- **下游依赖**：无

### 任务描述
在 TASK-003 服务启动验证通过后：执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`，复核 TC-046~051 保持通过（PASS=26、FAIL=0，TC-046-3 健康检查为可选场景，服务未启动时按脚本约定 SKIP 不视为失败）；核对 git 变更清单确认本版本无接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码改动，静态确认 API-001~API-033 契约完整保留、无新增/变更/删除接口（API v0.2.6 文档声明）；将 TC-046~051 复核结果与 TASK-004 的 TC-001~045 结果汇总，输出 docs/cso-v0.2.6/regression-api-test.md 完整回归报告（脚本清单、执行明细、统计、T-02 两项缺陷闭环说明、签名确认），API 测试全部跑通。

### 测试方法
接口测试：执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>` 复核 TC-046~051；git 变更清单核对（无接口层/客户端运行时代码改动）。

### 验收标准
1. cso-api-test-v0.2.5.py 执行通过，TC-046~051 保持 PASS=26、FAIL=0；
2. git 变更清单无 Controller/DTO/响应体与客户端 lib/ 运行时代码改动；
3. 静态确认 API-001~API-033 契约完整保留、无新增/变更/删除接口；
4. docs/cso-v0.2.6/regression-api-test.md 完整输出，记录 TC-001~051 全部动态执行结果与 T-02 缺陷闭环说明，API 测试全部跑通。

## 2. 用户需求（PRD US-004 / F-005）

### 故事描述
作为（企业用户/最终用户），我想要（v0.2.6 修复不改变任何对外接口契约与客户端行为），以便（Web/Windows 客户端无需任何修改即可继续正常使用登录认证与业务功能）。

### 前置条件
- v0.2.6 修复范围已完成并提交，git 变更清单可审计。

### 验收标准
- [ ] Given v0.2.6 修复完成，When 检查 git 变更清单，Then 无接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码改动
- [ ] Given 既有接口契约（API-001~API-033）保持完整，When 执行 `python cso-api-test-v0.2.5.py <项目根>`，Then TC-046~051 保持 PASS=26、FAIL=0
- [ ] Given 本版本发布前，When 核对 API 文档与接口实现，Then 无新增/变更/删除接口，契约静态与动态双重确认无回归

### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 修复过程中意外改动接口层文件 | 回退改动，重新构建验证，回归报告中说明 |
| 既有脚本断言因环境（服务未启动）失败 | TC-046-3 健康检查为可选场景，按脚本约定 SKIP 不视为失败 |
| 客户端运行时代码被误改 | 回退，客户端构建产物与运行时代码保持原状 |

### 功能范围（F-005）
- 修复范围严格限定在依赖配置、密钥格式契约与服务启动链路，不触碰接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码；
- 执行 `python cso-api-test-v0.2.5.py <项目根>`，TC-046~051 保持 PASS=26、FAIL=0（TC-046-3 健康检查为可选场景）；
- 若修复过程涉及接口层文件变更，须在回归报告中说明并经 PM 确认。

## 3. 项目信息摘要

- **项目中文名称**：云漫智企；**英文名称**：CloudStrollOffice；**缩写**：cso
- **技术栈**：Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1（Maven 多模块：common/gateway/auth-service/biz-service/system-service）；Flutter 客户端（cloudoffice-flutter-app，Web + Windows）
- **基础设施**：MariaDB 10.6（认证库 9 表）、Redis 7.2（会话/黑名单/缓存）、Nacos 2.3（注册/配置中心）
- **服务端口**：gateway 9000、auth-service 9100、biz-service 9200、system-service 9400
- **关键约定**：接口统一 ApiResult 响应体 + 29 个统一错误码；API 路径规范 `/api/v1/{module}/{resource}`；网关 AuthFilter 9 步认证；JWT RS256 双 Token；接口契约 API-001~API-033（API 设计文档）
- **接口层位置**：各服务 `controller/`（如 AuthController/UserController/RoleController/PermissionController/HealthController）、`dto/`（请求/响应 DTO）、common 模块 `model/ApiResult.java`/`model/PageResult.java` 等响应体；客户端运行时代码位于 `cloudoffice-flutter-app/lib/`
- **测试资产**：`scripts/API-TEST/cso-api-test-v0.0.1.py`（TC-001~045）、`scripts/API-TEST/cso-api-test-v0.2.5.py`（TC-046~051）
- **版本报告**：v0.2.5 回归报告 `docs/cso-v0.2.5/regression-api-test.md`（本版本需求来源：4 个服务无法启动，T-02 两项缺陷：bootstrap 依赖缺失、RSA 密钥格式契约不匹配）

## 4. 系统架构相关

### 接口契约无回归约束（SAD 设计约束）
- 模块间依赖单向（下游依赖 common），服务间禁止循环依赖；所有服务注册到 Nacos，网关统一路由 `/api/v1/{module}/**`；
- 接口统一 ApiResult 响应结构，错误码统一 29 个，全局异常处理不泄露堆栈信息；
- 本版本修复范围为依赖配置/密钥契约/启动链路，不得改变既有接口契约（API-001~API-033）。

### v0.2.6 修复项（T-02 缺陷闭环，供回归报告说明）
1. **bootstrap 依赖缺失**（ADR-014）：四个服务模块引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，消除 `No spring.config.import property has been defined`；
2. **RSA 密钥格式契约不匹配**（ADR-015）：deploy-rsa-keygen.ps1 输出/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64，与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约一致，消除 `RSA 公钥解析失败`。

### 相关文件
- 回归脚本：`scripts/API-TEST/cso-api-test-v0.2.5.py`（TC-046~051）
- 基线脚本：`scripts/API-TEST/cso-api-test-v0.0.1.py`（TC-001~045，TASK-004 已执行）
- 输出报告：`docs/cso-v0.2.6/regression-api-test.md`
- 参考报告：`docs/cso-v0.2.5/regression-api-test.md`
- API 契约：`docs/cso-api.md` / `docs/cso-v0.2.6/cso-api-v0.2.6.md`（API-001~API-033）

## 5. 执行要点（TL 提示）

1. 执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`，记录 TC-046~051 执行明细与 PASS/FAIL/SKIP 统计（目标 PASS=26、FAIL=0；TC-046-3 健康检查可选场景按脚本约定 SKIP 不视为失败）；
2. 核对 git 变更清单：确认无接口层（Controller/DTO/响应体）与客户端 `lib/` 运行时代码改动；若有改动须回退并说明；
3. 静态核对 API-001~API-033 契约完整保留、无新增/变更/删除接口（以 API v0.2.6 文档声明为准）；
4. 汇总 TASK-004（TC-001~045，PASS=45、FAIL=0）与 TC-046~051 结果，输出 `docs/cso-v0.2.6/regression-api-test.md`：脚本清单、执行明细、统计（PASS/FAIL/SKIP）、T-02 两项缺陷闭环说明、签名确认；
5. 回归报告须声明"API 测试全部跑通"。
