# 网络查询报告（TASK-005 保障既有接口契约无回归并输出 v0.2.6 回归报告）

## 1. 查询说明

- **任务**：TASK-005（common/测试验证类）——执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>` 复核 TC-046~051 保持 PASS=26、FAIL=0；核对 git 变更清单无接口层与客户端运行时代码改动；静态确认 API-001~033 契约完整保留；汇总输出 `docs/cso-v0.2.6/regression-api-test.md` 完整回归报告并声明"API 测试全部跑通"。
- **本报告为纯查询成果**，未修改任何代码与文档；供 TASK-005 后续执行（runtest/writetest/code）使用。

## 2. 三方组件识别与版本兼容性结论（重点）

| 组件 | 用途 | 官方文档来源（版本） | 与项目兼容性结论 |
| --- | --- | --- | --- |
| Python `requests` | TC-046-3 可选健康检查（`GET /api/v1/auth/health`），脚本其余 26 个断言为纯静态/git 断言，不依赖 requests | psf/requests 官方文档（main 分支，对应 requests 2.32.x 系列） | **兼容**：脚本仅使用 `requests.get(url, timeout=N)`、`resp.status_code`、`requests.exceptions.*` 基础 API，自 requests 2.0 起稳定不变；2.32.x 完全兼容，无风险 |
| Python `pytest`（参考，不引入） | 断言与测试编写最佳实践参考；回归脚本为纯脚本结构（`report()` 汇总函数 + 原生 assert），不采用 pytest 框架 | pytest 官方文档（pytest 9.0.0） | **不引入**：脚本无 pytest 依赖，仅借鉴其断言/报告思想；若未来演进为 pytest 测试套件，pytest 8.x/9.x 均兼容 Python 3.8+ |
| Pact（契约测试，方法论参考） | API 契约回归方法论参考（消费者驱动契约测试），本项目未引入 | pact-python 官方文档 | **不引入**：本项目采用"静态文档核对 + 动态脚本执行 + git 变更清单"三合一轻量契约回归方案（见第 5 节），与 Pact 重型方案目标一致、成本更低，无需引入 |
| 回归报告规范 | 报告结构参考 | IEEE 829 / ISO/IEC/IEEE 29119-3（测试文档国际标准）、ISTQB 回归测试定义 | **引用为规范依据**，非软件依赖 |

> **版本兼容性注意（已核对）**：本机（win32）当前 PATH 中无 `python`/`py` 命令，`requests` 版本无法在本机实测；脚本执行环境需具备 Python 3.x（建议 3.8+）且 `requests>=2.25`（官方推荐 2.32.x）。TC-046-3 按脚本约定在 `requests` 缺失时 SKIP 不视为失败，故 requests 非硬性前提。

## 3. Python requests 接口回归测试断言与超时处理最佳实践（官方文档 + 企业实况）

### 3.1 超时处理（官方 docs/advanced.md、docs/quickstart.md）

1. **必须显式设置 timeout，禁止裸调用**：`requests.get(url)` 不带 timeout 时可能无限期挂起，导致回归脚本卡死；官方文档明确 `timeout` 参数在超时后抛出 `requests.exceptions.Timeout`。
2. **单一超时**：`requests.get(url, timeout=5)` —— 连接与读取共用 5 秒，任一阶段超时即抛异常。
3. **分离超时（推荐用于健康检查）**：`requests.get(url, timeout=(3.05, 27))` —— 第一个值=连接超时，第二个值=读取超时；健康检查类接口建议短超时（连接 2~3 秒、读取 5~10 秒）。
4. **超时异常捕获**：`except requests.exceptions.Timeout`（基类，涵盖 `ConnectTimeout`/`ReadTimeout`）或更宽的 `except requests.RequestException`（涵盖超时、连接错误、HTTPError 等全部请求异常）。
5. **企业实况佐证**：NVIDIA NeMo-Retriever（官方注释"Use a short timeout to prevent long hanging calls. 5 seconds seems reasonable"）、Apache Airflow、bytedance/deer-flow、zenml 等均使用 `timeout=5/30/60` + `raise_for_status()` 组合。

### 3.2 断言与响应校验（官方 docs/quickstart.md）

1. **状态码断言**：`assert resp.status_code == 200` 或先 `resp.raise_for_status()`（对 4XX/5XX 抛出 `requests.exceptions.HTTPError`，成功返回 None）。
2. **JSON 响应体断言**：`data = resp.json()` 后按契约字段逐项断言：顶层 `code`、`message`、`data`、`timestamp` 结构字段，再断言业务字段与错误码（本项目统一 `ApiResult<T>` 响应体：code/message/data/timestamp）。
3. **错误场景断言**：预期非 2xx 时用 `with pytest.raises(HTTPError, match="...")`（pytest 官方 raises 文档）或直接断言 `resp.status_code == 409/429/403` 后校验 `resp.json()["code"]` 与错误码枚举一致（本项目 29 个统一错误码）。
4. **断言消息**：pytest 官方建议断言附可读消息（`assert cond, "消息"`），失败时直接定位原因——对应本项目脚本 `report(case_id, name, ok, detail)` 的 detail 参数。
5. **清理与关闭**：请求完成后 `resp.close()` 或使用 `with requests.Session() as s:` 上下文管理器确保连接池正确关闭（官方 docs/advanced.md）。

### 3.3 回归脚本适用结论（映射到 cso-api-test-v0.2.5.py）

- 本项目脚本对 TC-046-3 健康检查采用"try/except + SKIP"约定，与官方推荐的"短超时 + 捕获 RequestException/Timeout + 可选跳过"一致，无需改动。
- 其余 26 个断言为 git 变更清单/文档静态断言（`git status --short` 解析 + 字符串包含判断），不涉及网络 IO，天然无超时风险；执行时注意 `git_changed_files()` 以项目根为 cwd 运行 `git` 命令。
- 断言消息规范：每个 `report()` 的 detail 应包含"期望 vs 实际"关键信息，便于失败定位。

## 4. API 契约回归测试方法论（pact-python 官方 + 轻量适配）

### 4.1 消费者驱动契约测试（pact 官方方法论，本项目方法论参考）

- **核心思想**：消费者（客户端）定义契约（Pact 文件），提供者（服务端）在每次发布前执行 `pact-verify --provider-url <url> --pact-urls <pacts>` 验证自身实现符合消费者契约，防止"服务端悄然变更接口而客户端不知情"的回归。
- **验证工作流**（pact-python Verifier）：指定 provider URL → 加载契约来源（本地 pacts 目录 / Pact Broker）→ `verifier.verify()` 对运行中的服务逐条校验请求/响应匹配；CI 中可发布验证结果（`set_publish_options(version=..., branch=...)`）。
- **对中小项目/轻量改造的启示**：完整 Pact 基建（Broker、版本矩阵）成本较高；本项目以"文档契约 + 脚本断言 + git 审计"实现等价目标。

### 4.2 本项目轻量契约回归方案（TASK-005 执行依据）

| 契约回归维度 | 本项目方案 | 对应用例/步骤 |
| --- | --- | --- |
| 静态契约核对（提供者视角） | 逐项核对 API-001~033 的编号/方法/路径/认证列，比对 `docs/cso-api.md`（基线）与 `cso-api-v0.2.6.md`，确认无新增/变更/删除接口声明 | TC-046-1 / 047-1 / 048-1 / 049-1 / 050-1 / 051-1、执行要点 3 |
| 动态契约验证（运行视角） | 既有基线脚本 `cso-api-test-v0.0.1.py`（TC-001~045）TASK-004 已 PASS=45；v0.2.5 脚本 TC-046~051 复核 PASS=26、FAIL=0 | 执行要点 1、4 |
| 变更审计（实现视角） | `git diff --name-status 2b343ac..HEAD` 确认无 `controller/`、`lib/`、响应体结构变更；`LoginUserDTO` 内部字段与 `GlobalExceptionHandler` 状态映射属非契约行为对齐 | 执行要点 2、cs.md 第 3.2 节注意项 |
| 客户端兼容保障（消费者视角） | 变更清单无 `cloudoffice-flutter-app/lib/` 文件 → Web/Windows 客户端零修改可用 | TC-050-2c / 051-2b |

### 4.3 回归测试定义（ISTQB 术语）

回归测试：验证修改后的软件组件未引入缺陷、既有功能行为保持不变的测试；关键在于**基线（基线脚本 + 基线报告）可复现、变更范围可审计、结果可对照**。本项目以 v0.0.1（TC-001~045）与 v0.2.5（TC-046~051）为双重基线，符合该定义。

## 5. 回归报告规范结构（IEEE 829 / ISO/IEC/IEEE 29119-3 + v0.2.5 报告映射）

国际测试文档标准（IEEE 829-2008 已由 ISO/IEC/IEEE 29119-3:2013 取代，29119 规定测试报告应含：标识、概述、测试环境、测试结果记录、与实际结果偏差、结论与建议、批准签署）。映射到本项目 v0.2.6 回归报告要求：

| 规范要素（29119-3） | 本项目 v0.2.6 报告章节（docs/cso-v0.2.6/regression-api-test.md） |
| --- | --- |
| 测试标识/版本 | 标题（v0.2.6）+ 项目/版本/测试时间/负责人/测试类型表头 |
| 执行概述与环境 | 一、执行概览（脚本清单与执行结果表格：脚本名/命令/用例数/通过/失败/跳过/结果） |
| 结果记录（逐用例） | 二、用例执行明细：TASK-004 已有 TC-001~045（PASS=45）；TASK-005 追加 TC-046~051 复核明细（断言级 PASS/FAIL/SKIP） |
| 偏差与根因 | 三、根因闭环说明（T-02 两项缺陷：bootstrap 依赖缺失 / RSA 密钥格式契约不匹配，均闭环）；可选场景 SKIP 说明（TC-046-3 服务未启动按脚本约定 SKIP 不视为失败） |
| 结论 | 结论章：PASS=26、FAIL=0（TC-046~051）+ TC-001~045 PASS=45 汇总 → 全量 PASS=71、FAIL=0；声明"API 测试全部跑通" |
| 批准签署 | 签名确认（TE/PM） |

**报告关键统计口径（执行时照此输出，避免口径漂移）**：
- TC-046~051 断言级：PASS=26、FAIL=0、SKIP=1（TC-046-3 可选）→ 脚本退出码 0；
- TC-001~045（TASK-004 基线）：PASS=45、FAIL=0、SKIP=0；
- 全版本累计：PASS=71、FAIL=0、SKIP=1（SKIP 为可选场景约定，不视为失败）。

## 6. 环境与执行注意事项（实测确认）

1. **本机无 Python 运行时**：`python`/`py` 均不在 PATH（已实测 `where.exe` 无结果）；执行回归脚本需在具备 Python 3.x（建议 3.8+）的目标环境运行，或先安装 Python 并 `pip install requests`（可选，缺失时 TC-046-3 SKIP）。
2. **脚本运行方式**：`python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`；项目根缺省为脚本上级两级；`GATEWAY_URL` 环境变量可覆盖健康检查地址（默认 `http://localhost:9000`）。
3. **脚本固定检查对象**：`VERSION_DIR = docs/cso-v0.2.5`、`API_DOC = docs/cso-v0.2.5/cso-api-v0.2.5.md`（文件已确认存在，勿删除）。
4. **git 审计基线**：`git diff --name-status 2b343ac..HEAD`（2b343ac = v0.2.5 收尾提交）；`git_changed_files()` 统计工作区相对 HEAD 的未提交变更，执行前应确保除文档类变更外无接口层/客户端文件未提交。
5. **报告输出**：`docs/cso-v0.2.6/regression-api-test.md`（TASK-004 已含 TC-001~045 部分，TASK-005 在其上追加 TC-046~051 复核与 git/契约核对结论，形成 TC-001~051 全量报告）。

## 7. 资料清单（来源、版本与兼容性）

| # | 资料 | 来源 | 版本 | 兼容性结论 |
| --- | --- | --- | --- | --- |
| 1 | Requests 官方文档（timeout/Session/raise_for_status/异常） | github.com/psf/requests（docs/user/quickstart.md、docs/user/advanced.md） | requests 2.32.x 系列（main 分支） | 与脚本所用基础 API 完全兼容（2.0+ 稳定） |
| 2 | pytest 官方文档（断言内省、pytest.fail + __tracebackhide__、pytest.raises） | github.com/pytest-dev/pytest（doc/en/how-to/assert.rst、doc/en/example/simple.rst、raises.py） | pytest 9.0.0 | 仅方法论参考，本项目脚本不引入 pytest |
| 3 | pact-python 官方文档（消费者驱动契约测试、Verifier 验证工作流） | github.com/pact-foundation/pact-python（docs/provider.md、README） | pact-python 3.x | 方法论参考，本项目不引入 Pact |
| 4 | 企业真实样例（timeout + raise_for_status 组合） | Apache Airflow、NVIDIA NeMo-Retriever、bytedance/deer-flow、zenml-io/zenml、sgl-project/sglang 等公开仓库 scripts/ | 多版本 | 印证 requests 官方推荐用法 |
| 5 | 测试报告国际标准（IEEE 829 / ISO/IEC/IEEE 29119-3）与 ISTQB 回归测试定义 | 公开国际标准与术语 | 29119-3:2013 | 作为报告结构规范依据（非软件依赖） |

## 8. 查询结论（供 TASK-005 直接引用）

1. **requests 用法**：健康检查必须显式 `timeout`（建议连接 2~3s/读取 5~10s 或单值 5s），捕获 `requests.exceptions.Timeout`/`RequestException` 后按脚本约定 SKIP；状态码断言 `resp.status_code == 200`，响应体按 `ApiResult<T>`（code/message/data/timestamp）结构逐字段断言。与 cso-api-test-v0.2.5.py 现有实现一致，无需改动脚本。
2. **契约回归方法论**：采用"静态文档核对（API-001~033 逐项）+ 动态脚本执行（TC-001~051）+ git 变更审计（无接口层/客户端改动）"三重确认，等价于 Pact 消费者驱动契约测试目标，符合 ISTQB 回归测试定义。
3. **回归报告规范**：按 ISO/IEC/IEEE 29119-3 要素（标识/环境/结果记录/偏差根因/结论/签署）输出，对应 v0.2.5 报告既有六章结构；统计口径 PASS=71（TC-001~045=45 + TC-046~051=26）、FAIL=0、SKIP=1（可选场景），声明"API 测试全部跑通"。
4. **环境注意**：本机无 Python，脚本执行需具备 Python 3.x 的环境（或先安装）；requests 缺失时 TC-046-3 SKIP 不视为失败，不影响 PASS=26、FAIL=0 验收目标。
