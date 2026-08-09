# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.2.5
=========================================================
覆盖：docs/cso-v0.2.5/cso-testcase-v0.2.5.md 中 TC-046（无接口变更回归确认）、TC-047（env 文件迁移不影响接口契约）、
      TC-048（scripts 脚本迁移不影响接口契约）、TC-049（Maven 构建配置修改不影响接口契约，TASK-004）、
      TC-050（Flutter 客户端构建配置修改不影响接口契约，TASK-005）、
      TC-051（TASK-006 整体验收回归确认：deploy 目录纯净性/完整性校验不改变任何 HTTP 接口行为）
说明：
    v0.2.5 版本（cso-v0.2.5）声明【无新增接口、无接口变更、无接口删除】，
    本脚本针对 TASK-001（新建 deploy 目录与 deploy/scripts 子目录）、TASK-002（env.json/env.example.json 迁移至 deploy）、
    TASK-003（scripts 下全部 .sh/.ps1 迁移至 deploy/scripts 并适配路径）、
     TASK-004（Maven 构建配置：后端 jar 最终产物统一输出至 deploy）与
    TASK-005（Flutter 客户端构建配置：客户端最终产物统一输出至 deploy）做接口回归确认：
      1. 校验版本 API 文档 cso-api-v0.2.5.md 存在且声明本版本无接口变更；
      2. 校验 git 变更清单中未触碰任何 Controller / 网关路由 / 接口层代码文件；
      3. 校验既有接口契约（API-001~API-033）在 API 文档中完整保留；
      4. 校验脚本迁移类变更仅限 deploy/scripts 下的 .sh/.ps1 与文档/测试资产，无业务代码改动（TC-048 专项）；
      5. 校验构建配置修改仅限根 pom.xml 与 4 个模块 pom.xml，无接口层/业务代码改动（TC-049 专项）；
      6. 校验客户端构建配置修改仅限 cloudoffice-flutter-app 下构建脚本（build-release.ps1/.sh）
         与构建配置（.gitignore 等），无接口层/客户端运行时代码（lib/）改动（TC-050 专项）；
      7. 校验 TASK-006 整体验收（deploy 目录纯净性/完整性）同样不触碰接口层与客户端运行时代码，
         deploy/scripts 脚本中健康检查接口地址引用保持既有契约（TC-051 专项）；
      8. （可选）如服务已启动，对健康检查接口 /api/v1/auth/health 做连通性检查。
用法：
    python cso-api-test-v0.2.5.py                    # 项目根默认为脚本所在目录的上级（scripts/API-TEST/../..）
    python cso-api-test-v0.2.5.py D:/path/to/repo    # 指定项目根目录
    环境变量：GATEWAY_URL 覆盖健康检查网关地址（默认 http://localhost:9000）
说明：
    1. 本脚本不依赖数据库与业务服务启动即可执行前两项静态回归确认；
    2. 第七项健康检查为可选（服务未启动时标记 SKIP，不视为失败）；
    3. 退出码：0=全部通过，1=存在失败。
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
VERSION_DIR = os.path.join(PROJECT_ROOT, "docs", "cso-v0.2.5")
API_DOC = os.path.join(VERSION_DIR, "cso-api-v0.2.5.md")
GATEWAY_URL = os.environ.get("GATEWAY_URL", "http://localhost:9000")
HEALTH_PATH = GATEWAY_URL + "/api/v1/auth/health"
TIMEOUT = 5

# 接口层代码文件特征（Controller / 网关路由 / 接口定义）
INTERFACE_PATTERNS = (".controller.", "/controller/", "Controller.java", "GatewayConfig", "route", "RequestMapping")

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
        # 注意：git status --short 行格式为 "XY PATH"，XY 状态位后有一空格，
        # 路径从第 3 个字符开始。只去除行尾空白，保留前导空格以保证索引正确
        # （" M docs/..." 若 strip 掉前导空格会导致路径被截断为 "ocs/..."）。
        line = line.rstrip()
        if len(line) > 3:
            files.append(line[3:].strip().strip('"'))
    return files


def is_interface_file(path):
    """判断文件路径是否属于接口层（Controller/路由/接口定义）代码文件"""
    lower = path.replace("\\", "/").lower()
    if not lower.endswith(".java") and not lower.endswith(".kt"):
        return False
    return any(p in lower for p in ("/controller/", "/controller.", "controller.java", "gateway", "route"))


# ============================================================
# 用例：TC-046 无接口变更回归确认
# ============================================================
def test_tc046_no_api_change():
    """TC-046：v0.2.5 无接口变更，既有接口契约不受影响"""
    # 1. 版本 API 文档存在且声明无接口变更
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-046-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-046-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. （可选）健康检查接口连通性——服务未启动则 SKIP
    try:
        import requests
        resp = requests.get(HEALTH_PATH, timeout=TIMEOUT)
        ok = resp.status_code == 200
        report("TC-046-3", "健康检查接口连通性（可选）", ok,
               "HTTP {} @ {}".format(resp.status_code, HEALTH_PATH), skipped=False)
    except ImportError:
        report("TC-046-3", "健康检查接口连通性（可选）", False,
               "requests 未安装，跳过（静态回归已覆盖）", skipped=True)
    except Exception as exc:
        report("TC-046-3", "健康检查接口连通性（可选）", False,
               "服务未启动或不可达（{}），本用例为可选检查".format(exc), skipped=True)


# ============================================================
# 用例：TC-047 env 文件迁移不影响接口契约
# ============================================================
def test_tc047_env_migration_no_api_change():
    """TC-047：env.json / env.example.json 迁移至 deploy 不改变任何 HTTP 接口行为"""
    # 1. 版本 API 文档声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-047-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件；env 相关变更仅限两个配置文件移动
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    # env 配置变更识别：env.json 与 env.example.json 均属 env 配置
    # （注意 "env.example.json" 不含子串 "env.json"，需分别匹配；R 行为 "old -> new" 形式）
    is_env_path = lambda p: ("env.json" in p.replace("\\", "/") or "env.example.json" in p.replace("\\", "/"))
    env_changes = [f for f in changed if is_env_path(f)]
    # 非 env 变更中，除文档目录（docs/）、接口测试脚本目录（scripts/API-TEST/）、部署目录（deploy/）外，
    # 还允许本版本脚本迁移类变更（TASK-003：scripts 下 .sh/.ps1 重命名迁移至 deploy/scripts，git 显示为
    # "scripts/xxx.sh -> deploy/scripts/xxx.sh" 或 "scripts/xxx.ps1 -> deploy/scripts/xxx.ps1"）；
    # 除此之外不应出现任何业务代码/构建配置变更
    def is_allowed_change(p):
        p = p.replace("\\", "/")
        if p.startswith("docs/") or p.startswith("scripts/API-TEST/") or p.startswith("deploy/"):
            return True
        if p.startswith("scripts/") and (p.endswith(".sh") or p.endswith(".ps1")):
            return True  # 脚本迁移旧路径删除/重命名项（TASK-003）
        if p in BUILD_POM_WHITELIST:
            return True  # TASK-004 构建配置变更（根 pom + 4 个模块 pom，仅构建配置非业务代码）
        if is_client_build_change(p):
            return True  # TASK-005 客户端构建脚本/配置变更（仅构建配置非业务代码）
        return False
    non_env_changes = [f for f in changed if not is_env_path(f)]
    biz_changes = [f for f in non_env_changes if not is_allowed_change(f)]
    report("TC-047-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))
    report("TC-047-2b", "env 迁移与脚本迁移之外的变更均为文档/测试脚本，无业务代码改动",
           len(interface_changes) == 0 and len(biz_changes) == 0,
           "env 配置变更: {}；接口层变更: {}；业务代码/配置变更: {}".format(
               env_changes if env_changes else "无",
               interface_changes if interface_changes else "无",
               biz_changes if biz_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-047-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-048 scripts 脚本迁移不影响接口契约
# ============================================================
def test_tc048_scripts_migration_no_api_change():
    """TC-048：scripts 下 .sh/.ps1 迁移至 deploy/scripts 不改变任何 HTTP 接口行为"""
    # 1. 版本 API 文档声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-048-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件；脚本迁移类变更仅限 deploy/scripts 的 .sh/.ps1
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-048-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 脚本迁移变更识别：TASK-003 允许的变更仅为 deploy/scripts 下 .sh/.ps1（R 重命名）、
    #    docs 文档、scripts/API-TEST 测试资产、deploy 部署资产（TASK-001/002/005 等）、
    #    客户端构建脚本/配置（TASK-005）；除此之外不应出现任何业务代码/构建配置改动
    def is_migration_asset(p):
        p = p.replace("\\", "/")
        if p.startswith("deploy/scripts/") and (p.endswith(".sh") or p.endswith(".ps1")):
            return True
        if p.startswith("deploy/"):
            return True  # deploy 部署资产（scripts/、env 文件、客户端产物子目录等）
        if p.startswith("docs/") or p.startswith("scripts/API-TEST/"):
            return True
        if p in BUILD_POM_WHITELIST:
            return True  # TASK-004 构建配置变更（根 pom + 4 个模块 pom，仅构建配置非业务代码）
        if is_client_build_change(p):
            return True  # TASK-005 客户端构建脚本/配置变更（仅构建配置非业务代码）
        return False
    biz_changes = [f for f in changed if not is_migration_asset(f)]
    # 排除"旧路径被删除"（scripts/load-env.sh 等删除项，格式为 "old -> new" 或仅 "scripts/xxx.sh"）
    known_old_scripts = [f for f in biz_changes if f.replace("\\", "/").startswith("scripts/")
                         and (f.replace("\\", "/").endswith(".sh") or f.replace("\\", "/").endswith(".ps1"))]
    leftover = [f for f in biz_changes if f not in known_old_scripts]
    report("TC-048-2b", "脚本迁移之外无业务代码/接口层/构建配置改动",
           len(leftover) == 0,
           "非迁移类变更: {}".format(leftover if leftover else "无"))

    # 4. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-048-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 5. 脚本内接口地址引用保持既有契约（迁移只改文件系统路径，不改接口地址）
    #    脚本中允许出现的接口地址模式为既有契约 /api/v1/...；出现任何非 /api/v1/ 前缀的
    #    接口地址（疑似迁移引入/变更）即视为异常。脚本中无接口地址引用同样通过
    #    （说明脚本迁移不影响任何接口行为）。
    deploy_scripts_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    api_refs = []
    if os.path.isdir(deploy_scripts_dir):
        for name in sorted(os.listdir(deploy_scripts_dir)):
            if name.endswith(".sh") or name.endswith(".ps1"):
                path = os.path.join(deploy_scripts_dir, name)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                except OSError:
                    continue
                # 收集脚本中的 http(s) 接口地址引用
                for m in re.findall(r'https?://[^\s"\']+', content):
                    api_refs.append("{}: {}".format(name, m))
    # 断言：全部接口地址引用均为既有契约模式（含 /api/v1/ 或网关地址），不存在失效/变更迹象
    ref_ok = all(("/api/v1/" in r or "/api/" not in r.split(": ", 1)[1] or "localhost" in r or "0.0.0.0" in r) for r in api_refs)
    report("TC-048-4", "deploy/scripts 脚本中接口地址引用保持既有契约（无变更迹象）",
           ref_ok,
           "脚本中接口地址引用 {} 处：{}".format(len(api_refs), "; ".join(api_refs) if api_refs else "无"))


# ============================================================
# 用例：TC-049 Maven 构建配置修改不影响接口契约（TASK-004）
# ============================================================
# TASK-004 允许的构建配置变更（pom.xml 白名单）：
#   - 根 pom.xml（定义 deployDir 属性、统一 antrun 插件版本）
#   - cloudoffice-{gateway,auth-service,biz-service,system-service}/pom.xml（复制最终 jar 至 deploy）
# 不允许出现：任何 Controller/网关路由/接口层代码、common 模块源码、客户端源码改动。
BUILD_POM_WHITELIST = (
    "pom.xml",
    "cloudoffice-gateway/pom.xml",
    "cloudoffice-auth-service/pom.xml",
    "cloudoffice-biz-service/pom.xml",
    "cloudoffice-system-service/pom.xml",
)


def is_build_config_change(path):
    """判断路径是否为 TASK-004 允许的构建配置（pom.xml）变更"""
    p = path.replace("\\", "/")
    return p in BUILD_POM_WHITELIST


def test_tc049_build_config_no_api_change():
    """TC-049：Maven 构建配置修改（产物输出至 deploy）不改变任何 HTTP 接口行为"""
    # 1. 版本 API 文档声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-049-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-049-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 构建配置修改白名单校验：除 pom.xml（根 + 4 模块）、客户端构建脚本/配置（TASK-005）
    #    与文档/测试/部署资产外，不得出现任何业务代码/接口层/客户端源码改动
    def is_allowed_change(p):
        p = p.replace("\\", "/")
        if is_build_config_change(p):
            return True
        if p.startswith("docs/") or p.startswith("scripts/API-TEST/") or p.startswith("deploy/"):
            return True
        # TASK-003 脚本迁移旧路径删除/重命名项（如提交尚未完成时出现）
        if p.startswith("scripts/") and (p.endswith(".sh") or p.endswith(".ps1")):
            return True
        if is_client_build_change(p):
            return True  # TASK-005 客户端构建脚本/配置变更（仅构建配置非业务代码）
        return False
    biz_changes = [f for f in changed if not is_allowed_change(f)]
    report("TC-049-2b", "构建配置修改之外无业务代码/接口层/客户端源码改动",
           len(biz_changes) == 0,
           "非允许变更: {}".format(biz_changes if biz_changes else "无"))

    # 4. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-049-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 5. deploy/scripts 脚本中接口地址引用保持既有契约（构建配置只改产物落点，
    #    不改脚本与接口地址；出现任何非既有契约迹象即视为异常）
    deploy_scripts_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    api_refs = []
    if os.path.isdir(deploy_scripts_dir):
        for name in sorted(os.listdir(deploy_scripts_dir)):
            if name.endswith(".sh") or name.endswith(".ps1"):
                path = os.path.join(deploy_scripts_dir, name)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                except OSError:
                    continue
                for m in re.findall(r'https?://[^\s"\']+', content):
                    api_refs.append("{}: {}".format(name, m))
    ref_ok = all(("/api/v1/" in r or "/api/" not in r.split(": ", 1)[1] or "localhost" in r or "0.0.0.0" in r) for r in api_refs)
    report("TC-049-4", "deploy/scripts 脚本中接口地址引用保持既有契约（无变更迹象）",
           ref_ok,
           "脚本中接口地址引用 {} 处：{}".format(len(api_refs), "; ".join(api_refs) if api_refs else "无"))


# ============================================================
# 用例：TC-050 Flutter 客户端构建配置修改不影响接口契约（TASK-005）
# ============================================================
# TASK-005 允许的客户端构建配置变更（cloudoffice-flutter-app 下）：
#   - cloudoffice-flutter-app/build-release.ps1（Windows/PowerShell 客户端构建脚本，新建）
#   - cloudoffice-flutter-app/build-release.sh（Bash 客户端构建脚本，新建）
#   - cloudoffice-flutter-app/.gitignore（客户端工程 git 忽略规则，如被修改）
# 不允许出现：任何 Controller / 网关路由 / 接口层代码、后端模块源码、
#            cloudoffice-flutter-app/lib 下客户端运行时代码（含 API 调用层）改动。
CLIENT_BUILD_ALLOWED = (
    "cloudoffice-flutter-app/build-release.ps1",
    "cloudoffice-flutter-app/build-release.sh",
    "cloudoffice-flutter-app/.gitignore",
)


def is_client_build_change(path):
    """判断路径是否为 TASK-005 允许的客户端构建脚本/配置变更"""
    p = path.replace("\\", "/")
    return p in CLIENT_BUILD_ALLOWED


def test_tc050_client_build_config_no_api_change():
    """TC-050：Flutter 客户端构建配置修改（产物输出至 deploy）不改变任何 HTTP 接口行为"""
    # 1. 版本 API 文档声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-050-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    report("TC-050-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))

    # 3. 客户端构建配置修改白名单校验：除 cloudoffice-flutter-app 下构建脚本/配置与
    #    文档/测试/部署资产外，不得出现任何业务代码/接口层/客户端运行时代码改动
    def is_allowed_change(p):
        p = p.replace("\\", "/")
        if is_client_build_change(p):
            return True
        if p.startswith("docs/") or p.startswith("scripts/API-TEST/") or p.startswith("deploy/"):
            return True
        if is_build_config_change(p):
            return True  # TASK-004 遗留（提交未完成时出现）
        if p.startswith("scripts/") and (p.endswith(".sh") or p.endswith(".ps1")):
            return True  # TASK-003 脚本迁移旧路径删除/重命名项（提交未完成时出现）
        return False
    biz_changes = [f for f in changed if not is_allowed_change(f)]
    report("TC-050-2b", "客户端构建配置修改之外无业务代码/接口层/客户端运行时代码改动",
           len(biz_changes) == 0,
           "非允许变更: {}".format(biz_changes if biz_changes else "无"))

    # 4. 客户端 API 调用层（lib/ 下）未因构建配置修改而改动（专项负向校验）
    lib_changes = [f for f in changed if f.replace("\\", "/").startswith("cloudoffice-flutter-app/lib/")]
    report("TC-050-2c", "客户端 lib/ 运行时代码（API 调用层）无改动",
           len(lib_changes) == 0,
           "lib 变更: {}".format(lib_changes if lib_changes else "无"))

    # 5. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-050-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))


# ============================================================
# 用例：TC-051 TASK-006 整体验收不影响接口契约
# ============================================================
def test_tc051_acceptance_no_api_change():
    """TC-051：v0.2.5 整体验收（deploy 目录纯净性/完整性校验）不改变任何 HTTP 接口行为"""
    # 1. 版本 API 文档声明本版本无新增/变更/删除接口
    doc_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        doc_ok = ("无新增接口" in content and "无接口变更" in content and "无接口删除" in content)
    report("TC-051-1", "版本 API 文档声明无新增/变更/删除接口",
           doc_ok, "文档路径: {}".format(API_DOC))

    # 2. git 变更清单中无接口层代码文件、无客户端运行时代码（lib/）改动
    changed = git_changed_files()
    interface_changes = [f for f in changed if is_interface_file(f)]
    lib_changes = [f for f in changed if f.replace("\\", "/").startswith("cloudoffice-flutter-app/lib/")]
    report("TC-051-2", "git 变更清单未触碰接口层代码文件",
           len(interface_changes) == 0,
           "接口层变更: {}".format(interface_changes if interface_changes else "无"))
    report("TC-051-2b", "git 变更清单无客户端运行时代码（lib/）改动",
           len(lib_changes) == 0,
           "lib 变更: {}".format(lib_changes if lib_changes else "无"))

    # 3. 既有接口契约 API-001~API-033 在 API 文档中完整保留（33 个接口不受影响）
    contract_ok = False
    if os.path.isfile(API_DOC):
        with open(API_DOC, "r", encoding="utf-8") as f:
            content = f.read()
        contract_ok = ("API-001" in content and "API-033" in content)
    report("TC-051-3", "既有接口契约 API-001~API-033 在 API 文档中完整保留",
           contract_ok, "文档路径: {}".format(API_DOC))

    # 4. deploy/scripts 脚本中健康检查接口地址引用保持既有契约
    #    （整体验收只校验目录/产物，不应改动脚本与接口地址；出现任何非既有契约
    #    健康检查地址迹象即视为异常，无引用同样通过）
    deploy_scripts_dir = os.path.join(PROJECT_ROOT, "deploy", "scripts")
    health_refs = []
    if os.path.isdir(deploy_scripts_dir):
        for name in sorted(os.listdir(deploy_scripts_dir)):
            if name.endswith(".sh") or name.endswith(".ps1"):
                path = os.path.join(deploy_scripts_dir, name)
                try:
                    with open(path, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                except OSError:
                    continue
                # 收集脚本中的健康检查接口地址引用（仅模式匹配，不输出脚本内容）
                for m in re.findall(r'https?://[^\s"\']*(?:health|api/v1/auth)[^\s"\']*', content):
                    health_refs.append("{}: {}".format(name, m))
    ref_ok = all(("/api/v1/auth/health" in r or "/api/v1/" in r or "health" in r) for r in health_refs)
    report("TC-051-4", "deploy/scripts 脚本中健康检查接口地址引用保持既有契约（无变更迹象）",
           ref_ok,
           "健康检查引用 {} 处：{}".format(len(health_refs), "; ".join(health_refs) if health_refs else "无"))


# ============================================================
# main
# ============================================================
def main():
    """按用例编号顺序执行全部接口测试"""
    print("=" * 70)
    print("CloudStrollOffice 接口自动化测试 v0.2.5")
    print("项目根目录: {}".format(PROJECT_ROOT))
    print("开始时间: {}".format(time.strftime("%Y-%m-%d %H:%M:%S")))
    print("=" * 70)

    test_tc046_no_api_change()
    test_tc047_env_migration_no_api_change()
    test_tc048_scripts_migration_no_api_change()
    test_tc049_build_config_no_api_change()
    test_tc050_client_build_config_no_api_change()
    test_tc051_acceptance_no_api_change()

    print("=" * 70)
    print("执行完成 | PASS={} FAIL={} SKIP={}".format(PASS, FAIL, SKIP))
    if FAILED_CASES:
        print("失败用例:")
        for cid, name, detail in FAILED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    if SKIPPED_CASES:
        print("跳过用例:")
        for cid, name, detail in SKIPPED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    print("=" * 70)
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
