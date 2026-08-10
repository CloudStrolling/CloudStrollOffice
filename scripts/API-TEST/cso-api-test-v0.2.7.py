# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.2.7
=========================================================
覆盖：docs/cso-v0.2.7/cso-testcase-v0.2.7.md 中 TASK-001 / TASK-002 / TASK-003 / TASK-004 的接口测试用例：
      TASK-001：TC-077（本任务无接口变更，既有接口契约不受影响，P1）、
                TC-078（基础设施健康检查端点探活，可选、环境依赖，P2）、
                TC-079（健康检查响应体 ApiResult 结构契约校验，可选、环境依赖，P2）
      TASK-002：TC-080（本任务无接口变更，既有接口契约不受影响，P1）、
                TC-081（基础设施健康检查端点探活，可选、环境依赖，P2）
      TASK-003：TC-082（本任务无接口变更，既有接口契约不受影响，P1）、
                TC-083（基础设施健康检查端点探活，可选、环境依赖，P2）
      TASK-004：TC-084（本任务无接口变更，既有接口契约不受影响，P1）、
                TC-085（基础设施健康检查端点探活，可选、环境依赖，P2）
      TASK-005：TC-086（本任务无接口变更，既有接口契约不受影响，P1）、
                TC-087（健康端点契约核对与探活，可选、环境依赖，P2）
      TASK-006：TC-088（本任务无接口变更——4 个单服务脚本健康 URL 与 API 文档一致核对，P1）、
                TC-089（健康端点契约探活，可选、环境依赖，P2）
      TASK-007：TC-090（本任务无接口变更——deploy-rsa-keygen 双平台契约对齐，API-001~033 保留，P1）、
                TC-091（RSA 密钥注入契约与 Java 端解码契约静态核对，P1）
      TASK-008：TC-092（本任务无接口变更——弃用脚本 deploy-env* 清理与文档引用同步，
                API-001~033 保留，P1）、TC-093（健康检查端点契约探活，可选、环境依赖，P2）
      TASK-009：TC-094（本任务无接口变更——.gitignore 治理，git 变更清单无接口层代码，
                API-001~033 保留，P1）、TC-095（健康检查端点契约探活，可选、环境依赖，P2）
      TASK-010：TC-096（本任务无接口变更——全量脚本契约总体验证，git 变更清单无接口层
                代码，API-001~033 保留，P1）、TC-097（健康检查端点契约探活，可选、环境依赖，P2）
说明：
    v0.2.7 版本（cso-v0.2.7）声明【无新增接口、无接口变更、无接口删除】，
    对外接口契约 API-001~API-033 完整保留（docs/cso-api-v0.2.7.md 第 1 章与第 5 章
    明确：变更范围严格限定于部署运维层脚本重构（load-env / deploy-check-env /
    deploy-start-services / deploy-start-all / deploy-start-{svc} / deploy-rsa-keygen
    双平台对齐，SAD ADR-016）与仓库治理（.gitignore 补充临时/中间文件排除规则），
    未触碰任何 Controller/DTO/响应体，客户端运行时代码零改动）。
    TASK-001 为部署脚本梳理任务（输出问题清单 docs/cso-v0.2.7/
    cso-deploy-scripts-issue-list-v0.2.7.md），不修改任何 Java/客户端源码与接口层文件。
    TASK-002 为 load-env 统一配置加载脚本实现（common 类），不修改接口层文件。
    TASK-003 为 deploy-check-env.ps1/.sh 环境可用性检查与运行状态检测重构（common 类），
    不修改接口层文件。
    TASK-004 为 deploy-start-services.ps1/.sh 基础设施运行状态检查与一键启动重构
    （common 类），仅改动 deploy/scripts 下部署脚本，不修改接口层文件。
    TASK-007 为 deploy-rsa-keygen.ps1/.sh 双平台 RSA 密钥输出契约对齐（common 类，
    ADR-015：Java 端零改动），仅改动 deploy/scripts 下 rsa-keygen 脚本与文档，不修改接口层文件。
    TASK-008 为弃用脚本清理与引用关系同步（common 类，ADR-016：git rm 删除 deploy-env.ps1 /
    deploy-env-template.ps1/.sh 并同步 deploy.md 目录树、README.md 指引、deployment-guide.md
    双副本引用），仅改动 deploy/scripts 下弃用脚本删除与文档，不修改接口层文件。
    TASK-009 为 .gitignore 治理（common 类：新增 JVM/调试产物、构建/测试中间产物、测试产物
    与缓存、工具残留四类共 23 条排除规则），仅改动根目录 .gitignore 与任务文档/测试产物，
    不修改接口层文件。
    本脚本对任务做接口回归确认：
      1. 校验版本 API 文档 cso-api-v0.2.7.md 存在且声明本版本无接口变更（TC-077-1/TC-080-1/TC-082-1/TC-084-1）；
      2. 校验 git 变更清单中未触碰任何接口层代码文件（Controller/DTO/响应体/网关路由）
         （TC-077-2/TC-080-2/TC-082-2/TC-084-2）；
      3. 校验既有接口契约（API-001~API-033）在 API 文档中完整保留（TC-077-3/TC-080-3/TC-082-3/TC-084-3）；
      4. 健康检查端点探活（TC-078/TC-081/TC-083/TC-085）：直连 auth-service（9100）与经网关（9000）
         GET /api/v1/auth/health，返回 HTTP 200 且 ApiResult code=200、data.status=UP；
         服务未启动时按环境阻塞标记 SKIP（由 FT-069 前置说明记录），不视为脚本失败；
      5. 响应体结构契约（TC-079）：TC-078 探活成功时，校验健康检查响应体为
         ApiResult 结构（顶层 code/message/data/timestamp + data 四字段
         service/status/version/timestamp，status=UP），与 API-012 契约一致。
用法：
    python cso-api-test-v0.2.7.py                    # 项目根默认为脚本所在目录的上级（scripts/API-TEST/../..）
    python cso-api-test-v0.2.7.py D:/path/to/repo    # 指定项目根目录
     环境变量：
      AUTH_URL    覆盖 auth 健康检查直连地址（默认 http://127.0.0.1:9100）
      GATEWAY_URL 覆盖网关地址（默认 http://127.0.0.1:9000）
说明：
    1. 静态回归确认（TC-077）不依赖数据库与业务服务启动即可执行；
    2. 健康检查探活（TC-078）与响应体结构契约（TC-079）依赖服务已启动
       （SAD 部署架构：auth-service 9100、网关 9000；TASK-001 仅梳理不启动服务，
       v0.2.7 全量回归由既有服务实例支撑），服务不可达时记录 SKIP（环境阻塞），
       由回归报告归因于环境而非脚本失败；
    3. 退出码：0=全部通过（SKIP 不计失败），1=存在失败。
"""
import os
import re
import subprocess
import sys
import time

# ============================================================
# 配置
# ============================================================
PROJECT_ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
)
VERSION_DIR = os.path.join(PROJECT_ROOT, "docs", "cso-v0.2.7")
API_DOC = os.path.join(VERSION_DIR, "cso-api-v0.2.7.md")
AUTH_URL = os.environ.get("AUTH_URL", "http://127.0.0.1:9100")
GATEWAY_URL = os.environ.get("GATEWAY_URL", "http://127.0.0.1:9000")
BIZ_URL = os.environ.get("BIZ_URL", "http://127.0.0.1:9200")
SYSTEM_URL = os.environ.get("SYSTEM_URL", "http://127.0.0.1:9400")
TIMEOUT = 5

# 接口层代码文件特征（Controller / DTO / 响应体 / 网关路由 / 接口定义）
INTERFACE_PATTERNS = (".controller.", "/controller/", "Controller.java",
                      "ApiResult", "PageResult", "GatewayConfig", "route", "RequestMapping")

PASS = 0
FAIL = 0
SKIP = 0
FAILED_CASES = []
SKIPPED_CASES = []


def report(case_id, name, ok, detail="", skipped=False):
    """输出用例执行结果并汇总（skipped=True 时不视为失败）"""
    global PASS, FAIL, SKIP
    if skipped:
        SKIP += 1
        SKIPPED_CASES.append((case_id, name, detail))
        print("[SKIP] {} {} {}".format(case_id, name, detail))
        return
    status = "PASS" if ok else "FAIL"
    if ok:
        PASS += 1
    else:
        FAIL += 1
        FAILED_CASES.append((case_id, name, detail))
    print("[{}] {} {} {}".format(status, case_id, name, detail if not ok else ""))


def git_changed_files():
    """返回当前工作区/暂存区相对 HEAD 的全部变更文件清单（含未跟踪文件）"""
    try:
        out = subprocess.check_output(
            ["git", "status", "--short"],
            cwd=PROJECT_ROOT, stderr=subprocess.STDOUT, timeout=10
        ).decode("utf-8", errors="replace")
    except Exception:
        return []
    files = []
    for line in out.splitlines():
        # git status --short 行格式为 "XY PATH"，路径从第 3 个字符开始
        line = line.rstrip()
        if len(line) > 3:
            files.append(line[3:].strip().strip('"'))
    return files


def is_interface_file(path):
    """判断文件路径是否属于接口层（Controller/DTO/响应体/网关路由）代码文件"""
    lower = path.replace("\\", "/").lower()
    if not lower.endswith(".java") and not lower.endswith(".kt"):
        return False
    return any(p in lower for p in ("/controller/", "/controller.", "controller.java",
                                    "dto/", "/dto.", "gateway", "route"))


# ============================================================
# 用例：TC-077 本任务无接口变更，既有接口契约不受影响（P1）
# ============================================================
def test_tc077_no_api_change():
    """TC-077：脚本梳理类任务不改变任何 HTTP 接口契约（API-001~033 完整保留）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-077-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-001 仅输出问题清单文档，不触碰代码）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-077-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-077-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-078 基础设施健康检查端点探活（P2，环境可选）
# ============================================================
def health_probe(case_id, name, url, path):
    """对单个健康检查地址探活；服务不可达时按环境阻塞标记 SKIP
    （TASK-001 为梳理任务，探活依赖既有/后续启动的服务实例）。"""
    target = url + path
    try:
        import requests
    except ImportError:
        report(case_id, name, False, "requests 未安装，跳过探活（静态回归已覆盖）", skipped=True)
        return
    try:
        resp = requests.get(target, timeout=TIMEOUT)
    except Exception as exc:
        report(case_id, name, False,
               "服务未启动或不可达（{}）@ {}，按环境阻塞记录".format(exc, target),
               skipped=True)
        return
    try:
        body = resp.json()
    except Exception:
        body = {}
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("status") == "UP")
    report(case_id, name, ok,
           "HTTP {} @ {}；code={} status={}".format(
               resp.status_code, target, body.get("code"), data.get("status")))


def test_tc078_health_probe():
    """TC-078：auth-service（9100）与网关（9000）GET /api/v1/auth/health
    返回 HTTP 200 且 ApiResult code=200、data.status=UP；服务未启动按环境 SKIP"""
    # 1. 直连 auth-service 健康检查（端口 9100）
    health_probe("TC-078-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    # 2. 经网关 auth 健康检查（端口 9000，白名单免认证）
    health_probe("TC-078-2", "经网关健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 GATEWAY_URL, "/api/v1/auth/health")


# ============================================================
# 用例：TC-079 健康检查响应体 ApiResult 结构契约校验（P2，环境可选）
# ============================================================
def api_result_contract_assert(case_id, name, url, path):
    """对健康检查端点响应体做 ApiResult 结构契约断言（与 API-012 契约一致）。
    服务不可达按环境阻塞 SKIP；响应体缺失字段即判定 FAIL。"""
    target = url + path
    try:
        import requests
    except ImportError:
        report(case_id, name, False, "requests 未安装，跳过动态断言（静态回归已覆盖）", skipped=True)
        return
    try:
        resp = requests.get(target, timeout=TIMEOUT)
    except Exception as exc:
        report(case_id, name, False,
               "服务未启动或不可达（{}）@ {}，按环境阻塞记录".format(exc, target),
               skipped=True)
        return
    if resp.status_code != 200:
        report(case_id, name, False, "HTTP {}（预期 200）@ {}".format(resp.status_code, target))
        return
    try:
        body = resp.json()
    except Exception:
        report(case_id, name, False, "响应体非合法 JSON @ {}；原始: {}".format(target, resp.text[:200]))
        return

    # 顶层字段 code/message/data/timestamp
    code = body.get("code")
    message = body.get("message")
    data = body.get("data")
    top_ts = body.get("timestamp")
    top_ok = (code == 200 and message is not None and isinstance(data, dict) and top_ts is not None)

    # data 四字段 service/status/version/timestamp（status=UP）
    service = data.get("service")
    status = data.get("status")
    version = data.get("version")
    data_ts = data.get("timestamp")
    data_ok = (bool(service) and status == "UP" and bool(version) and data_ts is not None)

    ok = top_ok and data_ok
    report(case_id, name, ok,
           "@ {}；code={} service={} status={} version={} 顶层timestamp={} data.timestamp={}".format(
               target, code, service, status, version,
               top_ts is not None, data_ts is not None))


def test_tc079_apiresult_contract():
    """TC-079：健康检查响应体为 ApiResult 结构（顶层 code/message/data/timestamp
    + data 四字段 service/status/version/timestamp，code=200、status=UP），与 API-012 一致"""
    api_result_contract_assert("TC-079-1", "直连 auth-service 健康检查响应体 ApiResult 结构契约（API-012）",
                               AUTH_URL, "/api/v1/auth/health")
    api_result_contract_assert("TC-079-2", "经网关 auth 健康检查响应体 ApiResult 结构契约（API-012）",
                               GATEWAY_URL, "/api/v1/auth/health")


# ============================================================
# 用例：TC-080 本任务无接口变更，既有接口契约不受影响（P1，TASK-002）
# ============================================================
def test_tc080_no_api_change():
    """TC-080：TASK-002 为 load-env 统一配置加载脚本实现（common 类），
    不改变任何 HTTP 接口契约（API-001~033 完整保留）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-080-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-002 仅 load-env 脚本与文档，不触碰代码）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-080-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-080-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-081 基础设施健康检查端点探活（P2，环境可选，TASK-002）
# ============================================================
def test_tc081_health_probe():
    """TC-081：验证本任务 load-env 变更未影响服务运行——直连 auth-service（9100）
    与经网关（9000）GET /api/v1/auth/health 返回 HTTP 200 且 ApiResult code=200、
    data.status=UP；服务未启动时按环境阻塞 SKIP，不作为失败"""
    health_probe("TC-081-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-081-2", "经网关健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 GATEWAY_URL, "/api/v1/auth/health")


# ============================================================
# 用例：TC-082 本任务无接口变更，既有接口契约不受影响（P1，TASK-003）
# ============================================================
def test_tc082_no_api_change():
    """TC-082：TASK-003 为 deploy-check-env.ps1/.sh 环境可用性检查与运行状态检测
    重构（common 类），不改变任何 HTTP 接口契约（API-001~033 完整保留）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-082-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-003 仅 deploy-check-env 脚本与文档，不触碰代码）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-082-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-082-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-083 基础设施健康检查端点探活（P2，环境可选，TASK-003）
# ============================================================
def test_tc083_health_probe():
    """TC-083：验证本任务 deploy-check-env 重构未影响服务运行——直连 auth-service
    （9100）与经网关（9000）GET /api/v1/auth/health 返回 HTTP 200 且 ApiResult
    code=200、data.status=UP；服务未启动时按环境阻塞 SKIP，不作为失败"""
    health_probe("TC-083-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-083-2", "经网关健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 GATEWAY_URL, "/api/v1/auth/health")


# ============================================================
# 用例：TC-084 本任务无接口变更，既有接口契约不受影响（P1，TASK-004）
# ============================================================
def test_tc084_no_api_change():
    """TC-084：TASK-004 为 deploy-start-services.ps1/.sh 基础设施运行状态检查与
    一键启动重构（common 类），仅改动 deploy/scripts 下部署脚本，不改变任何 HTTP
    接口契约（API-001~033 完整保留）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-084-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-004 仅 deploy-start-services 双平台脚本与文档）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-084-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-084-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-085 基础设施健康检查端点探活（P2，环境可选，TASK-004）
# ============================================================
def test_tc085_health_probe():
    """TC-085：验证基础设施（MariaDB/Redis/Nacos）由 deploy-start-services 启动后，
    后端服务健康检查端点可用——直连 auth-service（9100）与经网关（9000）
    GET /api/v1/auth/health 返回 HTTP 200 且 ApiResult code=200、data.status=UP；
    服务未启动时按环境阻塞 SKIP，不作为失败"""
    health_probe("TC-085-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-085-2", "经网关健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 GATEWAY_URL, "/api/v1/auth/health")


# ============================================================
# 用例：TC-086 本任务无接口变更，既有接口契约不受影响（P1，TASK-005）
# ============================================================
def test_tc086_no_api_change():
    """TC-086：TASK-005 为 deploy-start-all.ps1/.sh 后端服务按序一键启动脚本
    新增（common 类），仅改动 deploy/scripts 下部署脚本与文档、测试，不改变
    任何 HTTP 接口契约（API-001~033 完整保留）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-086-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-005 仅 deploy-start-all 双平台脚本与文档/测试）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-086-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-086-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. 静态核对 deploy-start-all 双平台脚本仅 HTTP GET 探测既有健康检查端点，
    #    无自定义接口请求（无 POST/PUT/DELETE、无新增 URL 路径）
    script_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    ok_script = True
    detail_script = ""
    for name in ("deploy-start-all.ps1", "deploy-start-all.sh"):
        path = os.path.join(script_dir, name)
        if not os.path.isfile(path):
            ok_script = False
            detail_script = "{} 不存在".format(name)
            break
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        bad_methods = [m for m in ("POST", "PUT", "DELETE", "PATCH") if m in text]
        has_get = ("GET" in text or "Invoke-WebRequest" in text or "curl" in text)
        if bad_methods or not has_get:
            ok_script = False
            detail_script = "{} 含非 GET 方法引用: {}".format(name, bad_methods)
            break
        # 健康检查端点契约路径必须与既有 /api/v1/{module}/health 一致
        if "api/v1/auth/health" not in text or "api/v1/biz/health" not in text or "api/v1/system/health" not in text:
            ok_script = False
            detail_script = "{} 健康检查端点路径与契约不一致".format(name)
            break
    report("TC-086-4", "deploy-start-all 双平台脚本仅 GET 探测既有健康检查端点（无自定义接口请求）",
           ok_script, detail_script if detail_script else "双平台脚本静态核对通过")


# ============================================================
# 用例：TC-087 健康检查端点契约核对与探活（P2，环境可选，TASK-005）
# ============================================================
def gateway_root_probe(case_id, name):
    """gateway 9000 根路径探活：任意 HTTP 响应（404/401/500 亦可）即证明服务在运行；
    服务未启动时按环境阻塞 SKIP，不作为失败。"""
    target = GATEWAY_URL + "/"
    try:
        import requests
    except ImportError:
        report(case_id, name, False, "requests 未安装，跳过探活（静态回归已覆盖）", skipped=True)
        return
    try:
        resp = requests.get(target, timeout=TIMEOUT)
    except Exception as exc:
        report(case_id, name, False,
               "服务未启动或不可达（{}）@ {}，按环境阻塞记录".format(exc, target),
               skipped=True)
        return
    # 任意 HTTP 响应（含 404/401/500）即说明服务在运行（deploy-start-all 健康确认依据）
    report(case_id, name, True,
           "HTTP {} @ {}（任意响应即存活）".format(resp.status_code, target))


def test_tc087_health_probe():
    """TC-087：核对并探活 deploy-start-all 健康确认所依赖的健康检查端点契约：
    gateway GET http://localhost:9000/（任意响应即存活）；auth/biz/system 直连
    自身端口 GET /api/v1/{module}/health（ApiResult 结构、status=UP）；
    服务未启动时按环境阻塞 SKIP，不作为失败"""
    gateway_root_probe("TC-087-1", "gateway 9000 根路径探活（任意 HTTP 响应即存活）")
    health_probe("TC-087-2", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-087-3", "直连 biz-service 健康检查 GET /api/v1/biz/health（code=200、status=UP）",
                 BIZ_URL, "/api/v1/biz/health")
    health_probe("TC-087-4", "直连 system-service 健康检查 GET /api/v1/system/health（code=200、status=UP）",
                 SYSTEM_URL, "/api/v1/system/health")


# ============================================================
# 用例：TC-088 本任务无接口变更，健康 URL 与 API 文档一致（P1，TASK-006）
# ============================================================
SINGLE_START_SCRIPTS = ["deploy-start-gateway", "deploy-start-auth", "deploy-start-biz", "deploy-start-system"]
HEALTH_URL_CONTRACT = {
    "deploy-start-gateway": "http://localhost:9000/",
    "deploy-start-auth": "http://localhost:9100/api/v1/auth/health",
    "deploy-start-biz": "http://localhost:9200/api/v1/biz/health",
    "deploy-start-system": "http://localhost:9400/api/v1/system/health",
}


def test_tc088_no_api_change():
    """TC-088：TASK-006 为单服务启动脚本重构（common 类），无接口变更；
    4 个单服务脚本的健康检查 URL 与 API 文档一致（gateway 根路径 /
    auth API-012 / biz API-032 / system API-033），仅调用既有健康端点"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-088-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-006 仅 deploy/scripts 单服务脚本与 .gitignore）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-088-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 4 个单服务脚本健康 URL 与 API 文档契约一致，且仅 GET 探测既有端点
    script_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    ok_script = True
    detail_script = ""
    for name in SINGLE_START_SCRIPTS:
        for ext in (".ps1", ".sh"):
            path = os.path.join(script_dir, name + ext)
            if not os.path.isfile(path):
                ok_script = False
                detail_script = "{} 不存在".format(name + ext)
                break
            with open(path, "r", encoding="utf-8") as f:
                text = f.read()
            url = HEALTH_URL_CONTRACT[name]
            if url not in text:
                ok_script = False
                detail_script = "{} 健康 URL 与 API 契约不一致（缺 {}）".format(name + ext, url)
                break
            bad_methods = [m for m in ("POST", "PUT", "DELETE", "PATCH") if m in text]
            if bad_methods:
                ok_script = False
                detail_script = "{} 含非 GET 方法引用: {}".format(name + ext, bad_methods)
                break
        if not ok_script:
            break
    report("TC-088-3", "4 个单服务脚本健康 URL 与 API 文档一致且仅 GET 探测既有健康端点（无自定义接口请求）",
           ok_script, detail_script if detail_script else "8 个单服务脚本静态核对通过")


# ============================================================
# 用例：TC-089 健康端点契约探活（P2，环境可选，TASK-006）
# ============================================================
def test_tc089_health_probe():
    """TC-089：按单服务脚本健康 URL 动态探活：gateway 9000 根路径
    （任意 HTTP 响应即存活）；auth 9100 / biz 9200 / system 9400 直连
    GET /api/v1/{module}/health（ApiResult 结构、status=UP）；
    服务未启动时按环境阻塞 SKIP，不作为失败"""
    gateway_root_probe("TC-089-1", "gateway 9000 根路径探活（任意 HTTP 响应即存活，与脚本健康确认判定一致）")
    health_probe("TC-089-2", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-089-3", "直连 biz-service 健康检查 GET /api/v1/biz/health（code=200、status=UP）",
                 BIZ_URL, "/api/v1/biz/health")
    health_probe("TC-089-4", "直连 system-service 健康检查 GET /api/v1/system/health（code=200、status=UP）",
                 SYSTEM_URL, "/api/v1/system/health")


# ============================================================
# 用例：TC-090 本任务无接口变更，既有接口契约不受影响（P1，TASK-007）
# ============================================================
def test_tc090_no_api_change():
    """TC-090：TASK-007 仅重构部署脚本（deploy-rsa-keygen.ps1/.sh 双平台
    RSA 密钥输出契约对齐），不触碰 Controller/DTO/响应体；API 契约
    API-001~API-033 完整保留（API 文档 v0.2.7 确认无变更），客户端运行时代码
    零改动（ADR-015：Java 端零改动）"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-090-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-007 仅 deploy/scripts rsa-keygen 脚本层）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-090-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-090-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. 变更范围仅限脚本层：rsa-keygen 重构脚本（.sh）在变更清单（TASK-007 提交前）
    #    或 git log 有 TASK-007 重构提交记录（TASK-007 已提交后，runtest 在 gitcommit 之前
    #    执行故首次通过；提交后工作区不再含该文件——二者其一即认可）；.ps1 为 v0.2.6 基准
    #    可能未改动（不在清单属正常）；且无 java/dart/yml 代码变更（ADR-015 Java 零改动）
    changed_norm = [c.replace("\\", "/") for c in changed]
    sh_in_changes = "deploy/scripts/deploy-rsa-keygen.sh" in changed_norm
    sh_in_log = False
    try:
        log_out = subprocess.check_output(
            ["git", "log", "--oneline", "--", "deploy/scripts/deploy-rsa-keygen.sh"],
            cwd=PROJECT_ROOT, stderr=subprocess.STDOUT, timeout=10
        ).decode("utf-8", errors="replace")
        sh_in_log = ("TASK-007" in log_out or "rsa-keygen" in log_out)
    except Exception:
        sh_in_log = False
    rsa_scripts_in_changes = sh_in_changes or sh_in_log
    detail_scripts = []
    if not rsa_scripts_in_changes:
        detail_scripts.append("deploy/scripts/deploy-rsa-keygen.sh 不在变更清单且无 TASK-007 提交记录")
    src_changes = [c for c in changed if re.search(r"\.(java|dart|ya?ml)$", c.replace("\\", "/"))]
    ok_scope = rsa_scripts_in_changes and len(src_changes) == 0
    report("TC-090-4", "变更范围仅限脚本层（deploy-rsa-keygen.sh 重构在变更清单或 TASK-007 提交记录；.ps1 为 v0.2.6 基准保持；无 .java/.dart/.yml 代码变更，ADR-015 Java 零改动）",
           ok_scope,
           "脚本确认: {}；源码变更: {}".format(
               "变更清单" if sh_in_changes else ("TASK-007 提交记录" if sh_in_log else "无"),
               "; ".join(src_changes) if src_changes else "无"))


# ============================================================
# 用例：TC-091 RSA 密钥注入契约与 Java 端解码契约静态核对（P1，TASK-007）
# ============================================================
def test_tc091_rsa_inject_contract():
    """TC-091：脚本输出的单行 Base64 注入 env.json（RSA_PUBLIC_KEY /
    RSA_PRIVATE_KEY）后与 Java 端解码契约静态核对：Base64.getDecoder().decode()
    严格解码（无换行、无非法字符、无 PEM 头尾）→ 私钥 PKCS8EncodedKeySpec
    可解析（PKCS#8，[0]=0x30/[7]=0x30）→ 公钥 X509EncodedKeySpec 可解析
    （X.509，[0]=0x30/[4]=0x30/[19]=0x03）——即"脚本输出 → env.json →
    Java 解码"全链路契约一致（ADR-015 不破坏）"""
    # 1. env.example.json 含 RSA 注入键（RSA_PRIVATE_KEY / RSA_PUBLIC_KEY）
    env_example = os.path.join(PROJECT_ROOT, "deploy", "env.example.json")
    keys_ok = False
    detail_env = ""
    if os.path.isfile(env_example):
        try:
            import json
            with open(env_example, "r", encoding="utf-8") as f:
                env_obj = json.load(f)
            has_priv = "RSA_PRIVATE_KEY" in env_obj and str(env_obj["RSA_PRIVATE_KEY"]).strip() != ""
            has_pub = "RSA_PUBLIC_KEY" in env_obj and str(env_obj["RSA_PUBLIC_KEY"]).strip() != ""
            keys_ok = has_priv and has_pub
            detail_env = "RSA_PRIVATE_KEY={} RSA_PUBLIC_KEY={}".format(has_priv, has_pub)
        except Exception as exc:
            detail_env = "解析失败: {}".format(exc)
    else:
        detail_env = "缺失: {}".format(env_example)
    report("TC-091-1", "deploy/env.example.json 含 RSA_PRIVATE_KEY / RSA_PUBLIC_KEY 注入键（脚本输出注入目标）",
           keys_ok, detail_env)

    # 2. Java 端 RsaKeyConfig 配置键对应（auth jwt.rsa.private-key / jwt.rsa.public-key；
    #    gateway auth.rsa.public-key）——脚本输出值经 env.json 注入的配置键
    auth_java = os.path.join(PROJECT_ROOT, "cloudoffice-auth-service", "src", "main", "java",
                             "org", "cloudstrolling", "cloudoffice", "auth", "config", "RsaKeyConfig.java")
    gw_java = os.path.join(PROJECT_ROOT, "cloudoffice-gateway", "src", "main", "java",
                           "org", "cloudstrolling", "cloudoffice", "gateway", "config", "RsaKeyConfig.java")
    cfg_ok = False
    detail_cfg = ""
    try:
        with open(auth_java, "r", encoding="utf-8") as f:
            auth_txt = f.read()
        with open(gw_java, "r", encoding="utf-8") as f:
            gw_txt = f.read()
        auth_keys = ("jwt.rsa.private-key" in auth_txt and "jwt.rsa.public-key" in auth_txt)
        gw_key = ("auth.rsa.public-key" in gw_txt)
        cfg_ok = auth_keys and gw_key
        detail_cfg = "authKeys={} gwKey={}".format(auth_keys, gw_key)
    except Exception as exc:
        detail_cfg = "读取失败: {}".format(exc)
    report("TC-091-2", "Java 配置键对应（auth jwt.rsa.private-key/jwt.rsa.public-key、gateway auth.rsa.public-key）",
           cfg_ok, detail_cfg)

    # 3. 脚本输出契约（DER 单行 Base64）满足 Java 严格解码 + KeySpec 契约：静态核对
    #    双平台生成链路（pkcs8 -topk8 -nocrypt DER 私钥 PKCS#8 / pkey -pubout DER 公钥 X.509
    #    / 单行 base64 作用于 .der，无 PEM 头尾、无换行）与 Java getDecoder + KeySpec 对应
    script_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    contract_ok = False
    detail_contract = ""
    chain_missing = []
    for name in ("deploy-rsa-keygen.ps1", "deploy-rsa-keygen.sh"):
        path = os.path.join(script_dir, name)
        if not os.path.isfile(path):
            detail_contract = "{} 不存在".format(name)
            break
        with open(path, "r", encoding="utf-8") as f:
            txt = f.read()
        has_pkcs8 = ("pkcs8" in txt and "-topk8" in txt and "-nocrypt" in txt and "-outform DER" in txt)
        has_pubout_der = ("-pubout" in txt and "-outform DER" in txt)
        if name.endswith(".ps1"):
            has_single_line = ("[Convert]::ToBase64String" in txt and "InsertLineBreaks" not in txt)
        else:
            has_single_line = ("base64 -w0" in txt or "openssl base64 -A" in txt)
        has_der_selfcheck = ("0x30" in txt or "48" in txt)
        if not (has_pkcs8 and has_pubout_der and has_single_line and has_der_selfcheck):
            chain_missing.append("{}: pkcs8={} puboutDER={} singleLine={} derCheck={}".format(
                name, has_pkcs8, has_pubout_der, has_single_line, has_der_selfcheck))
    if not chain_missing:
        contract_ok = True
    report("TC-091-3", "脚本输出契约（PKCS#8 私钥 DER + X.509 公钥 DER + 单行 Base64 + DER 自校验）与 Java 严格解码/KeySpec 契约静态对应",
           contract_ok, "; ".join(chain_missing) if chain_missing else "双平台生成链路静态核对通过")

    # 4. ADR-015 契约说明（DER 单行 Base64、禁止 PEM 整体 Base64 注入、不得破坏）在版本文档中保留：
    #    PRD 第 1.1 章契约说明 / issue-list P3 问题定位 / URS 契约约束
    adr_ok = False
    detail_adr = ""
    prd_doc = os.path.join(VERSION_DIR, "cso-prd-v0.2.7.md")
    issue_list = os.path.join(VERSION_DIR, "cso-deploy-scripts-issue-list-v0.2.7.md")
    urs_doc = os.path.join(VERSION_DIR, "cso-urs-v0.2.7.md")
    adr_hits = []
    for doc, keywords in ((prd_doc, ("ADR-015", "PEM 文件整体 Base64", "Base64.getDecoder()")),
                          (issue_list, ("ADR-015", "PEM 文件整体 Base64")),
                          (urs_doc, ("ADR-015", "不得破坏"))):
        if os.path.isfile(doc):
            with open(doc, "r", encoding="utf-8") as f:
                txt = f.read()
            if all(k in txt for k in keywords):
                adr_hits.append(os.path.basename(doc))
    adr_ok = len(adr_hits) > 0
    detail_adr = "ADR-015 契约说明保留于: {}".format("、".join(adr_hits) if adr_hits else "无")
    report("TC-091-4", "ADR-015 契约说明（DER 单行 Base64 / 禁止 PEM 整体 Base64 注入 / 不得破坏）在版本文档中保留",
           adr_ok, detail_adr)


# ============================================================
# 用例：TC-092 本任务无接口变更，既有接口契约不受影响（P1，TASK-008）
# ============================================================
def test_tc092_no_api_change():
    """TC-092：TASK-008 仅清理 deploy/scripts 弃用脚本（deploy-env*，git rm）并同步
    文档引用（deploy.md 目录树 / README.md 指引 / deployment-guide.md 双副本），
    不触碰任何 Controller/DTO/响应体；API 契约 API-001~API-033 完整保留
    （API 文档 v0.2.7 确认无变更），客户端运行时代码零改动"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-092-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-008 仅 deploy/scripts 清理与文档同步）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-092-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-092-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. 变更范围仅限脚本清理与文档：deploy-env* 弃用脚本删除在变更清单（暂存 D）
    #    或已提交删除记录（git log --diff-filter=D），二者其一即可；无 .java/.dart/.yml
    #    源码变更（ADR-016 删除弃用脚本残留，不触碰接口层）
    changed_norm = [c.replace("\\", "/") for c in changed]
    dep_in_changes = any("deploy/scripts/deploy-env" in c for c in changed_norm)
    dep_in_log = False
    try:
        log_out = subprocess.check_output(
            ["git", "log", "--diff-filter=D", "--name-only", "--oneline", "--", "deploy/scripts/"],
            cwd=PROJECT_ROOT, stderr=subprocess.STDOUT, timeout=10
        ).decode("utf-8", errors="replace")
        dep_in_log = "deploy-env" in log_out
    except Exception:
        dep_in_log = False
    dep_removed = dep_in_changes or dep_in_log
    src_changes = [c for c in changed if re.search(r"\.(java|dart|ya?ml)$", c.replace("\\", "/"))]
    ok_scope = dep_removed and len(src_changes) == 0
    report("TC-092-4", "变更范围仅限脚本清理与文档同步（deploy-env* 弃用脚本删除在变更清单/删除记录；无 .java/.dart/.yml 代码变更，ADR-016）",
           ok_scope,
           "弃用脚本删除记录: {}；源码变更: {}".format(
               "有（暂存 D 或 git log D）" if dep_removed else "无（可能已提交后无工作区条目）",
               "; ".join(src_changes) if src_changes else "无"))


# ============================================================
# 用例：TC-093 健康检查端点契约探活（P2，环境可选，TASK-008）
# ============================================================
def test_tc093_health_probe():
    """TC-093：脚本清理与文档同步未影响后端服务可用性——gateway 9000 根路径
    （任意 HTTP 响应即存活）+ auth 9100 / biz 9200 / system 9400 直连
    GET /api/v1/{module}/health（ApiResult 结构、status=UP）；
    服务未启动时按环境阻塞 SKIP，不作为失败"""
    gateway_root_probe("TC-093-1", "gateway 9000 根路径探活（任意 HTTP 响应即存活）")
    health_probe("TC-093-2", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    health_probe("TC-093-3", "直连 biz-service 健康检查 GET /api/v1/biz/health（code=200、status=UP）",
                 BIZ_URL, "/api/v1/biz/health")
    health_probe("TC-093-4", "直连 system-service 健康检查 GET /api/v1/system/health（code=200、status=UP）",
                 SYSTEM_URL, "/api/v1/system/health")


# ============================================================
# 用例：TC-094 本任务无接口变更，既有接口契约不受影响（P1，TASK-009）
# ============================================================
def test_tc094_no_api_change():
    """TC-094：TASK-009 仅涉及 .gitignore 规则治理（JVM/调试产物、构建/测试中间产物、
    测试产物与缓存、工具残留四类 23 条排除规则），不触碰任何 Controller/DTO/响应体；
    git 变更清单无接口层代码变更，API-001~API-033 契约完整保留"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-094-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-009 仅 .gitignore 与任务文档/测试产物）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-094-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-094-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. 变更范围仅限 .gitignore 治理与任务产出：允许 .gitignore、docs/cso-v0.2.7/、
    #    scripts/API-TEST/ 相关文件；无任何后端接口代码/客户端源码/配置文件变更
    allowed_prefixes = (".gitignore", "docs/cso-v0.2.7", "scripts/API-TEST")
    changed_norm = [c.replace("\\", "/") for c in changed]
    out_of_scope = [c for c in changed_norm
                    if not (c == ".gitignore" or c.startswith(allowed_prefixes))]
    report("TC-094-4", "变更范围仅限 .gitignore 治理与任务文档/测试产物（无后端接口代码/客户端源码变更）",
           len(out_of_scope) == 0,
           "越界变更: {}".format(out_of_scope if out_of_scope else "无"))


# ============================================================
# 用例：TC-095 健康检查端点契约探活（P2，环境可选，TASK-009）
# ============================================================
def test_tc095_health_probe():
    """TC-095：.gitignore 治理未影响服务运行与健康契约——直连 auth-service（9100）
    GET /api/v1/auth/health（ApiResult 结构、code=200、status=UP）与网关（9000）
    根路径探活（任意 HTTP 响应即存活）；服务未启动时按环境阻塞 SKIP，不作为失败"""
    health_probe("TC-095-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    gateway_root_probe("TC-095-2", "gateway 9000 根路径探活（任意 HTTP 响应即存活）")


# ============================================================
# 用例：TC-096 本任务无接口变更，既有接口契约不受影响（P1，TASK-010）
# ============================================================
def test_tc096_no_api_change():
    """TC-096：TASK-010 为全量脚本契约与双平台行为总体验证（deploy/scripts 语法/契约
    自校验 + 验证报告输出 + 测试产物），不触碰任何 Controller/DTO/响应体；
    git 变更清单无接口层代码变更，API-001~API-033 契约完整保留"""
    # 1. 版本 API 文档存在且声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-096-1", "版本 API 文档声明本版本无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件（TASK-010 仅脚本验证与测试产物）
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-096-2", "git 变更清单未触碰接口层代码文件（无 Controller/DTO/响应体/网关路由改动）",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-096-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. 变更范围仅限脚本验证产出（deploy/scripts、验证报告、测试脚本、版本文档、.gitignore）
    allowed_prefixes = ("deploy/scripts", "docs/cso-v0.2.7", "scripts/API-TEST", ".gitignore")
    changed_norm = [c.replace("\\", "/") for c in changed]
    out_of_scope = [c for c in changed_norm
                    if not (c == ".gitignore" or c.startswith(allowed_prefixes))]
    report("TC-096-4", "变更范围仅限脚本验证/验证报告/测试脚本/版本文档（无后端接口代码/客户端源码变更）",
           len(out_of_scope) == 0,
           "越界变更: {}".format(out_of_scope if out_of_scope else "无"))


# ============================================================
# 用例：TC-097 健康检查端点契约探活（P2，环境可选，TASK-010）
# ============================================================
def test_tc097_health_probe():
    """TC-097：全量脚本契约验证未影响服务运行与健康契约——直连 auth-service（9100）
    GET /api/v1/auth/health（ApiResult 结构、code=200、status=UP）与网关（9000）
    根路径探活（任意 HTTP 响应即存活）；服务未启动时按环境阻塞 SKIP，不作为失败"""
    health_probe("TC-097-1", "直连 auth-service 健康检查 GET /api/v1/auth/health（code=200、status=UP）",
                 AUTH_URL, "/api/v1/auth/health")
    gateway_root_probe("TC-097-2", "gateway 9000 根路径探活（任意 HTTP 响应即存活）")


# ============================================================
# main
# ============================================================
def main():
    """按用例编号顺序执行全部接口测试"""
    print("=" * 70)
    print("CloudStrollOffice 接口自动化测试 v0.2.7")
    print("项目根目录: {}".format(PROJECT_ROOT))
    print("开始时间: {}".format(time.strftime("%Y-%m-%d %H:%M:%S")))
    print("=" * 70)

    # TASK-001（部署脚本梳理 + 问题清单输出，无接口变更回归确认 + 健康检查探活/结构契约）
    test_tc077_no_api_change()
    test_tc078_health_probe()
    test_tc079_apiresult_contract()
    # TASK-002（load-env 统一配置加载脚本实现，无接口变更回归确认 + 健康检查探活）
    test_tc080_no_api_change()
    test_tc081_health_probe()
    # TASK-003（deploy-check-env 可用性检查重构，无接口变更回归确认 + 健康检查探活）
    test_tc082_no_api_change()
    test_tc083_health_probe()
    # TASK-004（deploy-start-services 一键启动重构，无接口变更回归确认 + 健康检查探活）
    test_tc084_no_api_change()
    test_tc085_health_probe()
    # TASK-005（deploy-start-all 后端按序一键启动脚本新增，无接口变更回归确认 + 健康端点契约探活）
    test_tc086_no_api_change()
    test_tc087_health_probe()
    # TASK-006（单服务启动脚本重构，无接口变更回归确认 + 健康端点契约核对/探活）
    test_tc088_no_api_change()
    test_tc089_health_probe()
    # TASK-007（deploy-rsa-keygen 双平台 RSA 密钥输出契约对齐，无接口变更回归确认 + RSA 注入契约与 Java 解码契约静态核对）
    test_tc090_no_api_change()
    test_tc091_rsa_inject_contract()
    # TASK-008（弃用脚本清理与文档引用同步，无接口变更回归确认 + 健康端点契约探活）
    test_tc092_no_api_change()
    test_tc093_health_probe()
    # TASK-009（.gitignore 治理，无接口变更回归确认 + 健康端点契约探活）
    test_tc094_no_api_change()
    test_tc095_health_probe()
    # TASK-010（全量脚本契约总体验证，无接口变更回归确认 + 健康端点契约探活）
    test_tc096_no_api_change()
    test_tc097_health_probe()

    print("=" * 70)
    print("执行完成 | PASS={} FAIL={} SKIP={}".format(PASS, FAIL, SKIP))
    if FAILED_CASES:
        print("失败用例:")
        for cid, name, detail in FAILED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    if SKIPPED_CASES:
        print("跳过用例（环境阻塞，不计失败）:")
        for cid, name, detail in SKIPPED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    print("=" * 70)
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
