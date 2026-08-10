# 回归测试报告（接口测试）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7（部署脚本体系重构与仓库清洁度治理）
**测试日期**：2026-08-10
**测试负责人**：TE
**测试类型**：版本回归测试 - 接口测试（scripts/API-TEST/cso-api-test-v0.2.7.py）

---

## 一、测试环境

| 项目 | 值 |
| --- | --- |
| 操作系统 | Windows 10 Pro 19044.0 |
| Python | 3.13.11（C:\Users\jenemy\miniconda3\python.exe，requests 2.32.5） |
| 被测服务 | gateway 9000 / auth 9100 / biz 9200 / system 9400 / Nacos 8848（全部端口在监听，服务已启动） |
| 执行命令 | `python scripts/API-TEST/cso-api-test-v0.2.7.py D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice` |
| 测试时间 | 2026-08-10 22:30:57 起 |
| 项目根目录 | D:\jenemy\develop\OpenCodeProjects\CloudStrollOffice |

## 二、统计结果

| 指标 | 值 |
| --- | --- |
| 断言总数 | 65 |
| PASS | **63** |
| FAIL | **2** |
| SKIP | 0 |
| 通过率（不含 SKIP） | **63 / 65 = 96.92%** |
| 退出码 | 1（存在 FAIL 用例） |

## 三、用例执行明细

| 用例 | 名称摘要 | 结果 |
| --- | --- | --- |
| TC-077-1~3（TASK-001） | 版本 API 文档无接口变更声明 / git 变更清单未触碰接口层 / API-001~033 契约完整保留 | PASS |
| TC-078-1~2（TASK-001） | 直连与经网关 auth 健康检查（HTTP 200、code=200、status=UP） | PASS |
| TC-079-1~2（TASK-001） | 健康检查响应体 ApiResult 结构契约（API-012：code/message/data/timestamp + service/status/version/timestamp） | PASS |
| TC-080-1~3（TASK-002） | 同 TC-077 无接口变更三重确认 | PASS |
| TC-081-1~2（TASK-002） | 直连与经网关 auth 健康检查 | PASS |
| TC-082-1~3（TASK-003） | 同 TC-077 无接口变更三重确认 | PASS |
| TC-083-1~2（TASK-003） | 直连与经网关 auth 健康检查 | PASS |
| TC-084-1~3（TASK-004） | 同 TC-077 无接口变更三重确认 | PASS |
| TC-085-1~2（TASK-004） | 直连与经网关 auth 健康检查 | PASS |
| TC-086-1~4（TASK-005） | 无接口变更三重确认 + deploy-start-all 双平台脚本仅 GET 探测既有健康端点 | PASS |
| TC-087-1~4（TASK-005） | gateway 9000 根路径探活 + auth/biz/system 直连健康检查 | PASS |
| TC-088-1~3（TASK-006） | 无接口变更三重确认 + 4 个单服务脚本健康 URL 与 API 文档一致 | PASS |
| TC-089-1~4（TASK-006） | gateway 根路径探活 + 三服务直连健康检查 | PASS |
| TC-090-1~4（TASK-007） | 无接口变更三重确认 + 变更范围仅限脚本层（ADR-015 Java 零改动） | PASS |
| TC-091-1~4（TASK-007） | RSA 密钥注入契约：env.example.json 注入键 / Java 配置键对应 / DER 单行 Base64 输出契约与 Java 解码契约静态对应 / ADR-015 契约文档保留 | PASS |
| TC-092-1~4（TASK-008） | 无接口变更三重确认 + 变更范围仅限脚本清理与文档同步（deploy-env* 删除在变更清单/删除记录） | PASS |
| TC-093-1~4（TASK-008） | gateway 根路径探活 + 三服务直连健康检查 | PASS |
| TC-094-1~3（TASK-009） | 无接口变更三重确认 | PASS |
| **TC-094-4（TASK-009）** | **变更范围仅限 .gitignore 治理与任务文档/测试产物** | **FAIL**（越界变更：docs/cso-testcase.md，见第四节） |
| TC-095-1~2（TASK-009） | auth 直连健康检查 + gateway 根路径探活 | PASS |
| TC-096-1~3（TASK-010） | 无接口变更三重确认 | PASS |
| **TC-096-4（TASK-010）** | **变更范围仅限脚本验证/验证报告/测试脚本/版本文档** | **FAIL**（越界变更：docs/cso-testcase.md，见第四节） |
| TC-097-1~2（TASK-010） | auth 直连健康检查 + gateway 根路径探活 | PASS |

## 四、失败用例归因分析

| 失败用例 | 现象 | 归因 |
| --- | --- | --- |
| TC-094-4 | git 变更清单越界变更检出 `docs/cso-testcase.md` | **回归执行自干扰**：该文件修改为本次回归测试步骤1「将 v0.2.7 测试用例合并到主测试用例」的产物（impm-regression-test 步骤1 合并 docs/cso-testcase.md），测试脚本编写时（TASK-009 编码阶段）主测试用例尚未合并，白名单未包含该路径。该变更属于测试/文档类产物，与接口层代码无关，非本版本接口回归缺陷 |
| TC-096-4 | 同上（git 变更清单越界变更检出 `docs/cso-testcase.md`） | 同上：TASK-010 变更范围白名单同样未包含回归阶段合并主测试用例产生的 docs/cso-testcase.md 修改，属测试执行顺序自干扰 |

**佐证**：`git status` 确认工作区仅 `docs/cso-testcase.md`（本次合并产物）与 `docs/cso-v0.2.7/version_progress.md`（进度记录）两处文档变更，无任何 Controller/DTO/响应体/网关路由等接口层文件变更；全部接口契约断言（TC-077-3/080-3/082-3/084-3/086-3/088-3/090-3/092-3/094-3/096-3：API-001~033 完整保留）与全部健康探活断言（auth 9100、gateway 9000、biz 9200、system 9400）均为 PASS。

## 五、回归结论

1. v0.2.7 接口自动化测试共 65 项断言：63 PASS、2 FAIL、0 SKIP，通过率 96.92%。
2. 2 个 FAIL 均为回归测试自身步骤（主测试用例合并）产生的文档变更被「git 变更范围白名单」断言捕获，属**测试执行自干扰误报**，非接口回归缺陷。
3. 核心接口契约（API-001~API-033 完整保留、无新增/变更/删除接口、git 变更清单无接口层文件触碰）与运行态健康检查（四服务 + Nacos 全部可达、ApiResult 结构契约一致）全部通过，v0.2.7 版本（部署脚本重构 + .gitignore 治理）对既有接口零影响。
4. **接口测试回归判定：通过**（失败为自干扰误报，非版本缺陷）。
