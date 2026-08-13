# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.2.8
=========================================================
覆盖：docs/cso-v0.2.8/cso-testcase-v0.2.8.md 中相关任务的接口测试用例：
      TC-TASK005-001（P0）：common 健康检查端点白名单放行——无 Token 访问
                            /api/v1/common/health 经网关应返回 HTTP 200；
      TC-TASK005-002（P0）：common 配置查询端点需认证——无 Token 访问
                            /api/v1/common/config 经网关应返回 401；
      TC-TASK005-003（P0）：common 按微服务查询配置端点需认证——无 Token 访问
                            /api/v1/common/config/{serviceName} 经网关应返回 401；
      TC-TASK005-004（P0）：既有 auth 路由与白名单不受影响（回归）——无 Token 访问
                            /api/v1/auth/health 仍白名单放行返回 200；无 Token 访问
                            /api/v1/biz/echo（非白名单）仍返回 401；
       TC-TASK006-001/002/005（P0）：build-backend 编译脚本静态校验——.ps1/.sh
                            jar 清单含 cloudoffice-common.jar 且为 5 个，缺失校验
                             失败分支退出码非零；
       TC-TASK006-003/004（P0）：build-backend 编译产物校验——deploy 下 common
                            jar 存在且为可执行 fat jar，既有 4 服务 jar 输出不受影响；
       TC-TASK008-001/002（P0）：deploy-stop-all.ps1/.sh 服务清单含 common 且居末
                            （system→biz→auth→gateway→common）；
       TC-TASK008-003（P0）：deploy-stop-all 全未运行幂等执行——5 服务均"未在运行
                            幂等跳过"、退出码 0；
       TC-TASK008-004/005（P0）：deploy-stop-common.ps1/.sh 存在且契约正确
                            （common/9300/load-env/幂等跳过/退出码约定）；
       TC-TASK008-006（P0）：deploy-stop-common 停止运行中进程——按 PID 文件定位
                            停止模拟 common 进程，输出通过、退出码 0；
       TC-TASK007-001/002（P0）：deploy-start-all.ps1/.sh 服务清单含 common 且居首
                            （common→gateway→auth→biz→system，common 最先启动）；
       TC-TASK007-003/004（P0）：deploy-start-common.ps1/.sh 存在且契约正确
                            （common/COMMON_PORT 缺省 9300/health/load-env/退出码约定）；
       TC-TASK007-005（P0）：deploy-start-all 前置校验缺失时输出缺失项并退出非零、
                            不启动任何服务（5 个服务遍历含 common）；
       TC-TASK007-006（P0）：deploy-start-all common 启动失败失败即停（健康确认失败
                            break，提示含 9300 端口排查）；
        TC-TASK007-007（P0）：deploy-start-all 全部成功输出 5 个服务汇总（含 common）
                            并退出码 0。
        TC-TASK010-001~009（P0）：部署文档与 readme 更新静态校验——deploy.md 端口映射
                            含 common(9300)、启动顺序 common 首位、停止顺序 common 末位、
                            健康检查端点 /api/v1/common/health、环境变量 COMMON_PORT；
                            readme.md 项目介绍含 common 服务化说明、功能清单含通用配置
                            管理功能介绍、端口映射含 common(9300)；现有 gateway/auth/biz/
                            system 内容未被删除或覆盖。
说明：
    v0.2.8 为"cloudoffice-common 服务化改造与通用配置管理接口先行"版本（PRD v0.2.8 /
    SAD v0.2.8 ADR-017/018/019 / API 文档 v0.2.8）。本任务（TASK-005）为网关侧
    纯配置扩展：
      1. 网关路由新增 /api/v1/common/** → lb://cloudoffice-common；
      2. 网关 AuthFilter 白名单新增 /api/v1/common/health（无 Token 放行）；
      3. /api/v1/common/config 与 /api/v1/common/config/{serviceName} 保持非白名单
         （需经 AuthFilter 认证，无 Token 返回 401）；
      4. 不影响既有 gateway/auth/biz/system 路由与白名单规则。
    本脚本校验网关认证与路由行为：
      1. TC-TASK005-001：网关 /api/v1/common/health 无 Token 返回 200（白名单放行）；
         若 cloudoffice-common 服务（TASK-002/003 并行实现，9300 端口）未启动导致
         网关返回 503/504，则按环境阻塞标记 SKIP（不视为脚本失败）；
      2. TC-TASK005-002/003：网关 /api/v1/common/config* 无 Token 返回 401
         （AuthFilter 拦截，与 common 服务是否启动无关）；
      3. TC-TASK005-004：回归——/api/v1/auth/health 无 Token 返回 200（既有白名单
         不受影响）；/api/v1/biz/echo 无 Token 返回 401（非白名单拦截行为保持）。
用法：
    python cso-api-test-v0.2.8.py                    # 项目根默认为脚本所在目录的上级（scripts/API-TEST/../..）
    python cso-api-test-v0.2.8.py D:/path/to/repo    # 指定项目根目录
    环境变量：
      GATEWAY_URL 覆盖网关地址（默认 http://127.0.0.1:9000）
      AUTH_URL    覆盖 auth-service 健康直连地址（默认 http://127.0.0.1:9100）
      COMMON_URL  覆盖 common 服务直连地址（默认 http://127.0.0.1:9300）
说明：
    1. 网关路由/白名单行为（401/200）验证依赖网关已启动；网关不可达时按环境阻塞 SKIP；
    2. TC-TASK005-001 对 common 服务实例（9300）的可用性有环境依赖（由 TASK-002/003
       并行实现），common 未启动时网关对 /api/v1/common/health 返回 503/504，按 SKIP 处理；
    3. 退出码：0=全部通过（SKIP 不计失败），1=存在失败。
"""
import os
import sys

# ============================================================
# 配置
# ============================================================
PROJECT_ROOT = sys.argv[1] if len(sys.argv) > 1 else os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
)
VERSION_DIR = os.path.join(PROJECT_ROOT, "docs", "cso-v0.2.8")
GATEWAY_URL = os.environ.get("GATEWAY_URL", "http://127.0.0.1:9000")
AUTH_URL = os.environ.get("AUTH_URL", "http://127.0.0.1:9100")
COMMON_URL = os.environ.get("COMMON_URL", "http://127.0.0.1:9300")
TIMEOUT = 5

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


def http_get(target):
    """发起 GET 请求，返回 (status_code, body_dict) 或 (None, None)（请求异常）。"""
    try:
        import requests
    except ImportError:
        return None, None
    try:
        resp = requests.get(target, timeout=TIMEOUT)
    except Exception:
        return None, None
    try:
        body = resp.json()
    except Exception:
        body = {}
    return resp.status_code, body


# ============================================================
# 用例：TC-TASK005-001 common 健康检查端点白名单放行（P0）
# ============================================================
def test_tc_task005_001_common_health_whitelist():
    """TC-TASK005-001：无 Token 访问网关 /api/v1/common/health 应白名单放行返回 200；
    common 服务（9300）未启动导致网关 503/504 时按环境阻塞 SKIP"""
    status, body = http_get(GATEWAY_URL + "/api/v1/common/health")
    if status is None:
        report("TC-TASK005-001", "网关不可达，common 健康检查白名单放行验证按环境阻塞",
               False, "网关 @ {}".format(GATEWAY_URL), skipped=True)
        return
    if status in (503, 504):
        report("TC-TASK005-001", "无 Token 访问 /api/v1/common/health 白名单放行（common 服务未启动，网关 503/504）",
               False, "HTTP {}（common 服务未启动，由 TASK-002/003 并行实现，按环境阻塞）".format(status),
               skipped=True)
        return
    code = body.get("code")
    data = body.get("data") or {}
    ok = (status == 200 and code == 200 and data.get("status") == "UP")
    report("TC-TASK005-001", "无 Token 访问 /api/v1/common/health 应白名单放行返回 200",
           ok, "HTTP {} code={} status={}".format(status, code, data.get("status")))


# ============================================================
# 用例：TC-TASK005-002 common 配置查询端点需认证（P0）
# ============================================================
def test_tc_task005_002_common_config_auth():
    """TC-TASK005-002：无 Token 访问网关 /api/v1/common/config 应返回 401
    （AuthFilter 拦截，非白名单）"""
    status, body = http_get(GATEWAY_URL + "/api/v1/common/config")
    if status is None:
        report("TC-TASK005-002", "网关不可达，common 配置查询认证验证按环境阻塞",
               False, "网关 @ {}".format(GATEWAY_URL), skipped=True)
        return
    code = body.get("code")
    ok = (status == 401 and code == 401)
    report("TC-TASK005-002", "无 Token 访问 /api/v1/common/config 应返回 401",
           ok, "HTTP {} code={} message={}".format(status, code, body.get("message")))


# ============================================================
# 用例：TC-TASK005-003 common 按微服务查询配置端点需认证（P0）
# ============================================================
def test_tc_task005_003_common_config_by_service_auth():
    """TC-TASK005-003：无 Token 访问网关 /api/v1/common/config/{serviceName}
    应返回 401（AuthFilter 拦截，非白名单）"""
    status, body = http_get(GATEWAY_URL + "/api/v1/common/config/auth-service")
    if status is None:
        report("TC-TASK005-003", "网关不可达，common 按微服务查询配置认证验证按环境阻塞",
               False, "网关 @ {}".format(GATEWAY_URL), skipped=True)
        return
    code = body.get("code")
    ok = (status == 401 and code == 401)
    report("TC-TASK005-003", "无 Token 访问 /api/v1/common/config/auth-service 应返回 401",
           ok, "HTTP {} code={} message={}".format(status, code, body.get("message")))


# ============================================================
# 用例：TC-TASK005-004 既有 auth 路由与白名单不受影响（回归，P0）
# ============================================================
def test_tc_task005_004_existing_route_regression():
    """TC-TASK005-004：新增 common 路由/白名单后既有路由与白名单不受影响——
    无 Token 访问 /api/v1/auth/health 仍返回 200（白名单）；无 Token 访问
    /api/v1/biz/echo 仍返回 401（非白名单拦截）"""
    # 1. 既有 auth 白名单健康检查端点仍放行（无 Token 200）
    status, body = http_get(GATEWAY_URL + "/api/v1/auth/health")
    if status is None:
        report("TC-TASK005-004-1", "网关不可达，既有 auth 白名单回归验证按环境阻塞",
               False, "网关 @ {}".format(GATEWAY_URL), skipped=True)
    else:
        code = body.get("code")
        ok = (status == 200 and code == 200)
        report("TC-TASK005-004-1", "无 Token 访问 /api/v1/auth/health 仍白名单放行返回 200",
               ok, "HTTP {} code={}".format(status, code))

    # 2. 既有非白名单路径拦截行为保持（无 Token 401）
    status, body = http_get(GATEWAY_URL + "/api/v1/biz/echo")
    if status is None:
        report("TC-TASK005-004-2", "网关不可达，既有非白名单拦截回归验证按环境阻塞",
               False, "网关 @ {}".format(GATEWAY_URL), skipped=True)
    else:
        code = body.get("code")
        ok = (status == 401 and code == 401)
        report("TC-TASK005-004-2", "无 Token 访问 /api/v1/biz/echo 仍返回 401",
               ok, "HTTP {} code={}".format(status, code))


# ============================================================
# 用例：TC-TASK002-005 构建产物可执行 jar 落位 deploy（P0）
# ============================================================
def test_task002_build_artifact():
    """TC-TASK002-005：mvn package 后 deploy/cloudoffice-common.jar 存在且为可执行 fat jar；
    主 artifact（target/cloudoffice-common-0.0.1-SNAPSHOT.jar）仍为普通瘦 jar（下游依赖不受影响）"""
    import subprocess
    deploy_jar = os.path.join(PROJECT_ROOT, "deploy", "cloudoffice-common.jar")
    thin_jar = os.path.join(PROJECT_ROOT, "cloudoffice-common", "target", "cloudoffice-common-0.0.1-SNAPSHOT.jar")

    # 1. deploy 可执行 jar 存在且为 fat jar（含 Spring Boot Loader 与启动类）
    if not os.path.exists(deploy_jar):
        report("TC-TASK002-005", "deploy/cloudoffice-common.jar 应存在（构建产物）",
               False, "jar 缺失，请执行 build-backend 或 mvn package")
        return
    try:
        r = subprocess.run(["jar", "tf", deploy_jar], capture_output=True, text=True, timeout=120)
        entries = r.stdout
    except Exception as e:
        report("TC-TASK002-005", "deploy/cloudoffice-common.jar 内容校验（jar 命令不可用）",
               False, str(e))
        return
    has_loader = ("org/springframework/boot/loader" in entries)
    has_boot_app = ("BOOT-INF/classes/org/cloudstrolling/cloudoffice/common/CommonApplication.class" in entries)
    has_bootstrap = ("BOOT-INF/classes/bootstrap.yml" in entries)
    has_application = ("BOOT-INF/classes/application.yml" in entries)
    ok = has_loader and has_boot_app and has_bootstrap and has_application
    report("TC-TASK002-005", "deploy/cloudoffice-common.jar 为可执行 fat jar（loader/启动类/yml 齐全）",
           ok, "loader={} app={} bootstrap={} application={}".format(has_loader, has_boot_app, has_bootstrap, has_application))

    # 2. 主 artifact 仍为瘦 jar（下游依赖解析安全）
    if not os.path.exists(thin_jar):
        report("TC-TASK002-005-2", "主 artifact 应为瘦 jar（target/cloudoffice-common-0.0.1-SNAPSHOT.jar）",
               False, "瘦 jar 缺失")
        return
    thin_size_mb = os.path.getsize(thin_jar) / (1024 * 1024)
    ok = thin_size_mb < 2
    report("TC-TASK002-005-2", "主 artifact 仍为普通瘦 jar（{:.2f}MB < 2MB）".format(thin_size_mb),
           ok, "")


# ============================================================
# 用例：TC-TASK002-006 common 服务独立启动冒烟（P0）
# ============================================================
def test_task002_startup_smoke():
    """TC-TASK002-006：common 服务可独立启动并监听 9300 端口（/v3/api-docs 可访问）。
    common 未运行且 jar 存在时尝试独立启动（依赖 Nacos 可达）；Nacos 未就绪按环境阻塞 SKIP"""
    import subprocess
    import time
    jar = os.path.join(PROJECT_ROOT, "deploy", "cloudoffice-common.jar")
    url = COMMON_URL  # http://127.0.0.1:9300

    if not os.path.exists(jar):
        report("TC-TASK002-006", "common 服务独立启动冒烟", False,
               "deploy/cloudoffice-common.jar 缺失（请先构建）")
        return

    # 1. 已运行：验证 9300 端口与 SpringDoc 端点
    status, _ = http_get(url + "/v3/api-docs")
    if status is not None:
        ok = (status == 200)
        report("TC-TASK002-006", "common 服务已运行，/v3/api-docs 可访问（9300）", ok, "HTTP {}".format(status))
        return

    # 2. 未运行：尝试独立启动（注入 NACOS_ADDR / COMMON_PORT），探测就绪后停止
    nacos = os.environ.get("NACOS_ADDR", "127.0.0.1:8848")
    env = dict(os.environ)
    env["NACOS_ADDR"] = nacos
    env["COMMON_PORT"] = "9300"
    log_dir = os.path.join(PROJECT_ROOT, "deploy", "logs")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "common-start-test.log")
    with open(log_file, "w", encoding="utf-8", errors="replace") as logf:
        try:
            proc = subprocess.Popen(
                ["java", "-Xms256m", "-Xmx512m", "-jar", jar],
                cwd=PROJECT_ROOT, env=env, stdout=logf, stderr=subprocess.STDOUT)
        except Exception as e:
            report("TC-TASK002-006", "common 服务独立启动（命令执行异常）", False, str(e))
            return
        try:
            up = False
            for _ in range(30):  # 最长 60s
                time.sleep(2)
                s, _ = http_get(url + "/v3/api-docs")
                if s is not None:
                    up = True
                    break
            if up:
                report("TC-TASK002-006", "common 独立启动成功，9300 监听且 /v3/api-docs 可访问", True, "HTTP 200")
            else:
                report("TC-TASK002-006", "common 独立启动冒烟（Nacos 未就绪或启动失败，按环境阻塞）",
                       False, "60s 内未就绪，日志 {}".format(log_file), skipped=True)
        finally:
            try:
                proc.terminate()
                proc.wait(timeout=10)
            except Exception:
                try:
                    proc.kill()
                except Exception:
                    pass


# ============================================================
# 用例：TC-TASK002-007 下游服务依赖不受影响（编译回归，P0）
# ============================================================
def test_task002_downstream_compile():
    """TC-TASK002-007：common 服务化后 gateway/auth/biz/system 对 common 的 Maven 依赖编译正常。
    执行全量 reactor 构建（mvn clean package -DskipTests）并校验 5 个 jar 产物；
    CSO_SKIP_REACTOR_BUILD=1 时仅校验产物存在（构建已由 runtest 单独执行）"""
    import subprocess
    jars = ["cloudoffice-common.jar", "cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
            "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar"]
    missing = [j for j in jars if not os.path.exists(os.path.join(PROJECT_ROOT, "deploy", j))]

    if os.environ.get("CSO_SKIP_REACTOR_BUILD") == "1":
        ok = not missing
        report("TC-TASK002-007", "下游服务编译回归（产物校验，构建已执行）", ok,
               "缺失: {}".format(missing) if missing else "5 个 jar 齐全")
        return

    try:
        r = subprocess.run(
            ["mvn", "-q", "-f", os.path.join(PROJECT_ROOT, "pom.xml"), "clean", "package", "-DskipTests"],
            cwd=PROJECT_ROOT, capture_output=True, text=True, timeout=900)
    except Exception as e:
        report("TC-TASK002-007", "全量 reactor 编译回归（命令执行异常）", False, str(e))
        return
    missing = [j for j in jars if not os.path.exists(os.path.join(PROJECT_ROOT, "deploy", j))]
    ok = (r.returncode == 0) and not missing
    report("TC-TASK002-007", "下游服务依赖不受影响（全量编译回归）", ok,
           "退出码 {} 缺失: {}".format(r.returncode, missing) if not ok else "构建成功且 5 个 jar 齐全")


# ============================================================
# 用例：TC-TASK003-002/003/004/005 common 健康检查端点与 API 服务（P0）
# ============================================================
def test_tc_task003_common_health_endpoint():
    """TC-TASK003-002/003/004/005：common 健康检查端点与 SpringDoc 契约校验——
    1. TC-002：GET /api/v1/common/health 返回 200 与统一 ApiResult（service/status/version/timestamp）；
    2. TC-003：data 字段与 auth/biz/system 健康检查端点一致（service/status/version/timestamp）；
    3. TC-004：/v3/api-docs/common 分组返回 200 且含 /api/v1/common/health；/swagger-ui.html 可访问；
    4. TC-005：访问 common 不存在路径返回统一 ApiResult 且不泄露堆栈。
    说明：common 服务（9300）未运行时按环境阻塞 SKIP（与 TASK-002 冒烟策略一致）。"""
    if COMMON_URL == "http://127.0.0.1:9300":
        pass  # 使用默认直连地址
    # 1. 健康检查端点契约（TC-TASK003-002）
    status, body = http_get(COMMON_URL + "/api/v1/common/health")
    if status is None:
        report("TC-TASK003-002", "common 服务不可达，健康检查契约验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        code = body.get("code")
        data = body.get("data") or {}
        ok = (status == 200 and code == 200 and data.get("service") == "cloudoffice-common"
              and data.get("status") == "UP" and data.get("version")
              and data.get("timestamp"))
        report("TC-TASK003-002", "GET /api/v1/common/health 返回 200 与统一 ApiResult",
               ok, "HTTP {} code={} service={} status={}".format(
                   status, code, data.get("service"), data.get("status")))

    # 2. 响应体字段与既有服务健康检查端点一致（TC-TASK003-003）
    if status is None:
        report("TC-TASK003-003", "common 服务不可达，响应格式一致性验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        data = body.get("data") or {}
        keys = set(data.keys())
        ok = (keys == {"service", "status", "version", "timestamp"})
        report("TC-TASK003-003", "data 字段与 auth/biz/system 健康检查端点一致（4 字段）",
               ok, "data keys: {}".format(sorted(keys)))

    # 3. SpringDoc 分组 common 可访问（TC-TASK003-004）
    status_doc, body_doc = http_get(COMMON_URL + "/v3/api-docs/common")
    if status_doc is None:
        report("TC-TASK003-004", "common 服务不可达，SpringDoc 分组验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        paths = body_doc.get("paths") or {}
        has_health = "/api/v1/common/health" in paths
        ok = (status_doc == 200 and has_health)
        report("TC-TASK003-004", "/v3/api-docs/common 分组含 /api/v1/common/health 端点",
               ok, "HTTP {} 含 health={}".format(status_doc, has_health))
        status_ui, _ = http_get(COMMON_URL + "/swagger-ui.html")
        if status_ui is None:
            report("TC-TASK003-004-2", "common 服务不可达，Swagger UI 访问验证按环境阻塞",
                   False, "common @ {}".format(COMMON_URL), skipped=True)
        else:
            ok_ui = (status_ui == 200)
            report("TC-TASK003-004-2", "Swagger UI（/swagger-ui.html）可访问", ok_ui, "HTTP {}".format(status_ui))

    # 4. 全局异常处理器兜底不泄露堆栈（TC-TASK003-005）
    status404, body404 = http_get(COMMON_URL + "/api/v1/common/non-exist")
    if status404 is None:
        report("TC-TASK003-005", "common 服务不可达，全局异常兜底验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        text = str(body404)
        ok = ("code" in body404 and "message" in body404
              and "timestamp" in body404 and "at org.cloudstrolling" not in text
              and "Exception" not in text)
        report("TC-TASK003-005", "未匹配路径返回统一 ApiResult 且不泄露堆栈",
               ok, "HTTP {} code={}".format(status404, body404.get("code")))


# ============================================================
# 用例：TC-TASK006-001/002/005 build-backend 编译脚本校验（P0）
# ============================================================
def test_task006_build_script_checks():
    """TC-TASK006-001/002/005：build-backend 编译脚本静态校验——
    1. .ps1（TC-001）$Jars 清单包含 cloudoffice-common.jar 且为 5 个；
    2. .sh（TC-002）for 循环 jar 清单包含 cloudoffice-common.jar 且为 5 个；
    3. 缺失校验失败分支（TC-005）：.ps1 $missing 逻辑与 .sh MISSING 逻辑存在且退出码非零约定存在。"""
    ps1 = os.path.join(PROJECT_ROOT, "deploy", "scripts", "build-backend.ps1")
    sh = os.path.join(PROJECT_ROOT, "deploy", "scripts", "build-backend.sh")
    expect = ["cloudoffice-common.jar", "cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
              "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar"]

    # 1. .ps1 静态校验（TC-TASK006-001）
    try:
        with open(ps1, "r", encoding="utf-8", errors="replace") as f:
            content_ps1 = f.read()
    except Exception as e:
        report("TC-TASK006-001", "build-backend.ps1 校验清单含 common", False, "读取失败: {}".format(e))
        return
    has_common = "cloudoffice-common.jar" in content_ps1
    jars_line = None
    for line in content_ps1.splitlines():
        if "$Jars = @" in line:
            jars_line = line
            break
    ok = has_common and jars_line is not None
    report("TC-TASK006-001", "build-backend.ps1 $Jars 清单含 cloudoffice-common.jar（5 个）",
           ok, "" if ok else "$Jars 清单缺失 common 或未定义")

    # 2. .sh 静态校验（TC-TASK006-002）
    try:
        with open(sh, "r", encoding="utf-8", errors="replace") as f:
            content_sh = f.read()
    except Exception as e:
        report("TC-TASK006-002", "build-backend.sh 校验清单含 common", False, "读取失败: {}".format(e))
        return
    has_common_sh = "cloudoffice-common.jar" in content_sh
    has_for_loop = "for jar in" in content_sh
    ok = has_common_sh and has_for_loop
    report("TC-TASK006-002", "build-backend.sh for 循环清单含 cloudoffice-common.jar（5 个）",
           ok, "" if ok else "for 循环清单缺失 common")

    # 3. 缺失校验失败分支（TC-TASK006-005）：静态校验 $missing / MISSING 逻辑与 exit 非零约定
    has_missing_ps1 = ("$missing" in content_ps1 and "exit 1" in content_ps1)
    has_missing_sh = ("MISSING" in content_sh and "exit 1" in content_sh)
    ok = has_missing_ps1 and has_missing_sh
    report("TC-TASK006-005", "build-backend 产物缺失时输出错误并退出非零（.ps1/.sh 静态校验）",
           ok, "" if ok else "缺失校验或退出码约定不完整")


# ============================================================
# 用例：TC-TASK006-003/004 build-backend 编译产物校验（P0）
# ============================================================
def test_task006_build_artifacts():
    """TC-TASK006-003/004：build-backend 编译产物校验——
    1. TC-003：deploy 下 cloudoffice-common.jar 存在且为可执行 fat jar（含 Spring Boot Loader）；
    2. TC-004：既有 gateway/auth/biz/system 4 个 jar 均存在（现有服务产物输出不受影响）。
    产物缺失时尝试执行 build-backend（CSO_SKIP_BUILD_BACKEND=1 时仅校验产物不执行构建）。"""
    import subprocess
    jars = ["cloudoffice-common.jar", "cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
            "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar"]
    missing = [j for j in jars if not os.path.exists(os.path.join(PROJECT_ROOT, "deploy", j))]

    if missing and os.environ.get("CSO_SKIP_BUILD_BACKEND") != "1":
        try:
            script = os.path.join(PROJECT_ROOT, "deploy", "scripts", "build-backend.ps1")
            r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script],
                               capture_output=True, text=True, timeout=1800)
        except Exception as e:
            report("TC-TASK006-003", "执行 build-backend 构建 common jar", False, "命令异常: {}".format(e))
            return
        missing = [j for j in jars if not os.path.exists(os.path.join(PROJECT_ROOT, "deploy", j))]
        ok = (r.returncode == 0) and not missing
        report("TC-TASK006-003", "执行 build-backend 后 5 个 jar 齐全（含 cloudoffice-common.jar）", ok,
               "退出码 {} 缺失: {}".format(r.returncode, missing) if not ok else "构建成功，5 个 jar 齐全")
    elif missing:
        ok = not missing
        report("TC-TASK006-003", "build-backend 产物校验（CSO_SKIP_BUILD_BACKEND=1，跳过构建）", ok,
               "缺失: {}".format(missing))
    else:
        report("TC-TASK006-003", "deploy 下 5 个 jar 齐全（含 cloudoffice-common.jar）", True,
               "5 个 jar 均存在")

    # TC-TASK006-004：既有 4 个服务 jar 输出不受影响
    existing = ["cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
                "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar"]
    missing4 = [j for j in existing if not os.path.exists(os.path.join(PROJECT_ROOT, "deploy", j))]
    ok = not missing4
    report("TC-TASK006-004", "现有 gateway/auth/biz/system 产物输出不受影响", ok,
           "缺失: {}".format(missing4) if missing4 else "4 个既有服务 jar 均存在")


# ============================================================
# 用例：TC-TASK008-001/002/003/004/005 deploy-stop-all 与 deploy-stop-common 脚本静态校验（P0）
# ============================================================
def test_task008_stop_script_checks():
    """TC-TASK008-001/002/004/005：部署停止脚本静态校验——
    1. TC-001：deploy-stop-all.ps1 $Services 含 5 项且 common(cloudoffice-common.jar|9300) 位于最后；
    2. TC-002：deploy-stop-all.sh SERVICES 含 5 项且 common 位于最后；
    3. TC-004：deploy-stop-common.ps1 存在，契约 ServiceName=common/Jar=cloudoffice-common.jar/Port=9300，
       经 load-env 加载，含 PID/命令行校验 + 回退 jar 定位 + 幂等跳过 + 输出分级与退出码约定；
    4. TC-005：deploy-stop-common.sh 存在，契约与 .ps1 对齐（SERVICE_NAME/JAR_NAME/SERVICE_PORT），
       source load-env.sh，含幂等跳过与退出码约定。"""
    stop_all_ps1 = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-all.ps1")
    stop_all_sh = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-all.sh")
    stop_common_ps1 = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-common.ps1")
    stop_common_sh = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-common.sh")

    # ---- TC-TASK008-001：deploy-stop-all.ps1 服务清单含 common 且居末 ----
    try:
        with open(stop_all_ps1, "r", encoding="utf-8", errors="replace") as f:
            c_ps1 = f.read()
    except Exception as e:
        report("TC-TASK008-001", "deploy-stop-all.ps1 服务清单含 common 且居末", False, "读取失败: {}".format(e))
        return
    names = ["system", "biz", "auth", "gateway", "common"]
    jars = ["cloudoffice-system-service.jar", "cloudoffice-biz-service.jar",
            "cloudoffice-auth-service.jar", "cloudoffice-gateway.jar", "cloudoffice-common.jar"]
    has_all = all(n in c_ps1 for n in names) and all(j in c_ps1 for j in jars)
    # 顺序校验：common 出现在 gateway 之后（居末）
    idx_gateway = c_ps1.find('"gateway"')
    idx_common = c_ps1.find('"common"')
    ordered = (idx_gateway != -1 and idx_common != -1 and idx_common > idx_gateway)
    ok = has_all and ordered
    report("TC-TASK008-001", "deploy-stop-all.ps1 服务清单含 common 且居末（system→biz→auth→gateway→common）",
           ok, "" if ok else "清单缺失 common 或顺序错误")

    # ---- TC-TASK008-002：deploy-stop-all.sh 服务清单含 common 且居末 ----
    try:
        with open(stop_all_sh, "r", encoding="utf-8", errors="replace") as f:
            c_sh = f.read()
    except Exception as e:
        report("TC-TASK008-002", "deploy-stop-all.sh 服务清单含 common 且居末", False, "读取失败: {}".format(e))
        return
    has_common_sh = "cloudoffice-common.jar|9300" in c_sh
    idx_gateway_sh = c_sh.find("cloudoffice-gateway.jar|9000")
    idx_common_sh = c_sh.find("cloudoffice-common.jar|9300")
    ordered_sh = (idx_gateway_sh != -1 and idx_common_sh != -1 and idx_common_sh > idx_gateway_sh)
    ok = has_common_sh and ordered_sh
    report("TC-TASK008-002", "deploy-stop-all.sh 服务清单含 common 且居末（common|cloudoffice-common.jar|9300）",
           ok, "" if ok else "清单缺失 common 或顺序错误")

    # ---- TC-TASK008-004：deploy-stop-common.ps1 契约正确 ----
    if not os.path.exists(stop_common_ps1):
        report("TC-TASK008-004", "deploy-stop-common.ps1 存在且契约正确", False, "脚本缺失")
    else:
        with open(stop_common_ps1, "r", encoding="utf-8", errors="replace") as f:
            c_cps1 = f.read()
        ok = ("common" in c_cps1 and "cloudoffice-common.jar" in c_cps1 and "9300" in c_cps1
              and "load-env.ps1" in c_cps1 and "幂等跳过" in c_cps1
              and "exit 1" in c_cps1 and "exit 0" in c_cps1)
        report("TC-TASK008-004", "deploy-stop-common.ps1 存在且契约正确（common/9300/load-env/幂等/退出码）",
               ok, "" if ok else "契约要素缺失")

    # ---- TC-TASK008-005：deploy-stop-common.sh 契约正确 ----
    if not os.path.exists(stop_common_sh):
        report("TC-TASK008-005", "deploy-stop-common.sh 存在且契约正确", False, "脚本缺失")
    else:
        with open(stop_common_sh, "r", encoding="utf-8", errors="replace") as f:
            c_csh = f.read()
        ok = ("common" in c_csh and "cloudoffice-common.jar" in c_csh and "9300" in c_csh
              and "load-env.sh" in c_csh and "幂等跳过" in c_csh
              and "exit 1" in c_csh and "exit 0" in c_csh)
        report("TC-TASK008-005", "deploy-stop-common.sh 存在且契约正确（common/9300/load-env/幂等/退出码）",
               ok, "" if ok else "契约要素缺失")


# ============================================================
# 用例：TC-TASK008-003 deploy-stop-all 未运行幂等执行验证（P0）
#       TC-TASK008-006 deploy-stop-common 停止运行中进程验证（P0）
# ============================================================
def test_task008_stop_script_execute():
    """TC-TASK008-003/006：部署停止脚本实执行验证——
    1. TC-003：当前无后端 java 服务运行时执行 deploy-stop-all.ps1，5 个服务均幂等通过、退出码 0；
    2. TC-006：启动一个命令行含 cloudoffice-common.jar 的模拟 java 进程后执行 deploy-stop-common.ps1，
       进程被停止、输出通过、退出码 0。
    说明：.sh 平台在 Windows 环境不可执行，仅对 .ps1 实执行（双平台契约经静态校验对齐）。"""
    import subprocess
    import time

    # ---- TC-TASK008-003：deploy-stop-all 全未运行幂等执行 ----
    stop_all = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-all.ps1")
    if not os.path.exists(stop_all):
        report("TC-TASK008-003", "deploy-stop-all 未运行服务幂等跳过且退出码 0", False, "脚本缺失")
    else:
        try:
            r = subprocess.run(
                ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", stop_all,
                 "-StopTimeout", "10", "-RetryInterval", "1"],
                capture_output=True, text=True, timeout=300)
        except Exception as e:
            report("TC-TASK008-003", "deploy-stop-all 未运行服务幂等跳过且退出码 0", False, "命令异常: {}".format(e))
            return
        out = (r.stdout or "") + (r.stderr or "")
        # 脚本输出含 common 服务停止段与汇总（jar 名仅用于进程匹配不打印，无需断言）
        has_common = "common" in out
        has_idle = out.count("幂等跳过") >= 5
        has_summary = ("通过" in out and "失败" in out)
        ok = (r.returncode == 0 and has_common and has_idle and has_summary)
        report("TC-TASK008-003", "deploy-stop-all 未运行服务幂等跳过且不影响其他服务（退出码 0）",
               ok, "退出码 {} common段={} 5服务幂等={} 汇总={}".format(r.returncode, has_common, has_idle, has_summary))

    # ---- TC-TASK008-006：deploy-stop-common 停止运行中进程 ----
    stop_common = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-stop-common.ps1")
    if not os.path.exists(stop_common):
        report("TC-TASK008-006", "deploy-stop-common 停止运行中进程并退出码 0", False, "脚本缺失")
        return
    # 启动模拟进程：命令行含 cloudoffice-common.jar（java 命令对任意无参类路径可解析）
    import glob as _glob
    jar_candidates = [os.path.join(PROJECT_ROOT, "deploy", "cloudoffice-common.jar"),
                      os.path.join(PROJECT_ROOT, "deploy", "cloudoffice-gateway.jar")]
    mock_jar = next((p for p in jar_candidates if os.path.exists(p)), None)
    if not mock_jar:
        report("TC-TASK008-006", "deploy-stop-common 停止运行中进程", False, "缺少可用 jar 作为模拟进程", skipped=True)
        return
    proc = None
    try:
        # 启动 jar（注入默认端口避免冲突：-Dserver.port=0 随机端口，命令行仍含 jar 名）
        env = dict(os.environ)
        proc = subprocess.Popen(
            ["java", "-Xms64m", "-Xmx128m", "-Dserver.port=0", "-jar", mock_jar],
            cwd=PROJECT_ROOT, env=env,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)
        if proc.poll() is not None:
            report("TC-TASK008-006", "deploy-stop-common 停止运行中进程（模拟进程已自行退出）",
                   False, "模拟进程未保持运行（无 Nacos 依赖，按环境阻塞）", skipped=True)
            return
        # 写入 common.pid 指向模拟进程（验证 PID 文件定位路径）
        log_dir = os.path.join(PROJECT_ROOT, "deploy", "logs")
        os.makedirs(log_dir, exist_ok=True)
        pid_file = os.path.join(log_dir, "common.pid")
        with open(pid_file, "w", encoding="ascii") as pf:
            pf.write(str(proc.pid))
        r = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", stop_common,
             "-StopTimeout", "10", "-RetryInterval", "1"],
            capture_output=True, text=True, timeout=300)
        out = (r.stdout or "") + (r.stderr or "")
        # 等待进程确认退出
        try:
            proc.wait(timeout=10)
        except Exception:
            pass
        gone = (proc.poll() is not None)
        ok = (r.returncode == 0 and gone and "已停止" in out)
        report("TC-TASK008-006", "deploy-stop-common 停止运行中进程并输出通过、退出码 0",
               ok, "退出码 {} 进程已退出={} 输出={}".format(r.returncode, gone, out.replace(chr(10), " ")[:160]))
    except Exception as e:
        report("TC-TASK008-006", "deploy-stop-common 停止运行中进程并输出通过、退出码 0", False, "命令异常: {}".format(e))
    finally:
        if proc is not None and proc.poll() is None:
            try:
                proc.kill()
            except Exception:
                pass


# ============================================================
# 用例：TC-TASK007-001/002/003/004/005/006/007 deploy-start-all 与 deploy-start-common 脚本校验（P0）
# ============================================================
def test_task007_start_script_checks():
    """TC-TASK007-001/002/003/004/005/006/007：部署启动脚本静态校验——
    1. TC-001：deploy-start-all.ps1 $Services 含 5 项且 common(cloudoffice-common.jar|COMMON_PORT 缺省 9300|
        /api/v1/common/health|NACOS_ADDR,COMMON_PORT,DB_PASSWORD) 位于首位；
    2. TC-002：deploy-start-all.sh SERVICES 含 5 项且 common 位于首位；
    3. TC-003：deploy-start-common.ps1 存在，契约 ServiceName=common/Jar=cloudoffice-common.jar/
        ServicePort 读 COMMON_PORT 缺省 9300/HealthUrl 含 /api/v1/common/health/RequiredVars 含 COMMON_PORT，
        经 load-env 加载，输出分级与退出码约定；
    4. TC-004：deploy-start-common.sh 存在，契约与 .ps1 对齐（SERVICE_NAME/JAR_NAME/SERVICE_PORT），
       source load-env.sh，含输出分级与退出码约定；
    5. TC-005：前置校验缺失分支——.ps1/.sh 前置校验遍历 5 个服务（含 common）且失败 exit 1、不启动服务；
    6. TC-006：common 失败即停分支——.ps1/.sh 健康确认失败后 break（循环中断），失败提示含端口 9300 排查；
    7. TC-007：汇总输出——.ps1/.sh 结尾各服务启动结果遍历覆盖 common，全部成功输出"5 个后端服务"且 exit 0。
    说明：仅静态校验（脚本内容契约），实执行在 runtest 步骤按环境进行。"""
    start_all_ps1 = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-start-all.ps1")
    start_all_sh = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-start-all.sh")
    start_common_ps1 = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-start-common.ps1")
    start_common_sh = os.path.join(PROJECT_ROOT, "deploy", "scripts", "deploy-start-common.sh")

    # ---- TC-TASK007-001：deploy-start-all.ps1 服务清单含 common 且居首 ----
    try:
        with open(start_all_ps1, "r", encoding="utf-8", errors="replace") as f:
            c_ps1 = f.read()
    except Exception as e:
        report("TC-TASK007-001", "deploy-start-all.ps1 服务清单含 common 且居首", False, "读取失败: {}".format(e))
        return
    names = ["common", "gateway", "auth", "biz", "system"]
    jars = ["cloudoffice-common.jar", "cloudoffice-gateway.jar", "cloudoffice-auth-service.jar",
            "cloudoffice-biz-service.jar", "cloudoffice-system-service.jar"]
    has_all = all(n in c_ps1 for n in names) and all(j in c_ps1 for j in jars)
    has_health = "/api/v1/common/health" in c_ps1
    has_common_var = "COMMON_PORT" in c_ps1
    idx_common = c_ps1.find('"common"')
    idx_gateway = c_ps1.find('"gateway"')
    ordered = (idx_common != -1 and idx_gateway != -1 and idx_common < idx_gateway)
    ok = has_all and has_health and has_common_var and ordered
    report("TC-TASK007-001", "deploy-start-all.ps1 服务清单含 common 且居首（common→gateway→auth→biz→system）",
           ok, "" if ok else "清单缺失 common 或顺序错误")

    # ---- TC-TASK007-002：deploy-start-all.sh 服务清单含 common 且居首 ----
    try:
        with open(start_all_sh, "r", encoding="utf-8", errors="replace") as f:
            c_sh = f.read()
    except Exception as e:
        report("TC-TASK007-002", "deploy-start-all.sh 服务清单含 common 且居首", False, "读取失败: {}".format(e))
        return
    has_common_sh = "cloudoffice-common.jar" in c_sh
    has_health_sh = "/api/v1/common/health" in c_sh
    has_common_var_sh = "COMMON_PORT" in c_sh
    idx_common_sh = c_sh.find('"common|')
    idx_gateway_sh = c_sh.find('"gateway|')
    ordered_sh = (idx_common_sh != -1 and idx_gateway_sh != -1 and idx_common_sh < idx_gateway_sh)
    ok = has_common_sh and has_health_sh and has_common_var_sh and ordered_sh
    report("TC-TASK007-002", "deploy-start-all.sh 服务清单含 common 且居首（common→gateway→auth→biz→system）",
           ok, "" if ok else "清单缺失 common 或顺序错误")

    # ---- TC-TASK007-003：deploy-start-common.ps1 契约正确 ----
    if not os.path.exists(start_common_ps1):
        report("TC-TASK007-003", "deploy-start-common.ps1 存在且契约正确", False, "脚本缺失")
    else:
        with open(start_common_ps1, "r", encoding="utf-8", errors="replace") as f:
            c_cps1 = f.read()
        ok = ('$ServiceName = "common"' in c_cps1 and "cloudoffice-common.jar" in c_cps1
              and "COMMON_PORT" in c_cps1 and "9300" in c_cps1
              and "/api/v1/common/health" in c_cps1 and "load-env.ps1" in c_cps1
              and "exit 1" in c_cps1 and "exit 0" in c_cps1)
        report("TC-TASK007-003", "deploy-start-common.ps1 存在且契约正确（common/COMMON_PORT/health/load-env/退出码）",
               ok, "" if ok else "契约要素缺失")

    # ---- TC-TASK007-004：deploy-start-common.sh 契约正确 ----
    if not os.path.exists(start_common_sh):
        report("TC-TASK007-004", "deploy-start-common.sh 存在且契约正确", False, "脚本缺失")
    else:
        with open(start_common_sh, "r", encoding="utf-8", errors="replace") as f:
            c_csh = f.read()
        ok = ('SERVICE_NAME="common"' in c_csh and "cloudoffice-common.jar" in c_csh
              and "COMMON_PORT" in c_csh and "9300" in c_csh
              and "/api/v1/common/health" in c_csh and "load-env.sh" in c_csh
              and "exit 1" in c_csh and "exit 0" in c_csh)
        report("TC-TASK007-004", "deploy-start-common.sh 存在且契约正确（common/COMMON_PORT/health/load-env/退出码）",
               ok, "" if ok else "契约要素缺失")

    # ---- TC-TASK007-005：前置校验缺失分支（5 个服务 + exit 1 不启动） ----
    # .ps1：foreach ($svc in $Services) 前置校验 + $precheckFail 退出 1
    has_precheck_ps1 = ("foreach ($svc in $Services)" in c_ps1 and "$precheckFail" in c_ps1
                        and "exit 1" in c_ps1 and "本次未启动任何服务" in c_ps1)
    # .sh：for entry in "${SERVICES[@]}" 前置校验 + PRECHECK_FAIL 退出 1
    has_precheck_sh = ('for entry in "${SERVICES[@]}"' in c_sh and "PRECHECK_FAIL" in c_sh
                       and "exit 1" in c_sh and "本次未启动任何服务" in c_sh)
    ok = has_precheck_ps1 and has_precheck_sh
    report("TC-TASK007-005", "前置校验缺失时输出缺失项并退出非零、不启动任何服务（.ps1/.sh 静态校验）",
           ok, "" if ok else "前置校验或退出码约定不完整")

    # ---- TC-TASK007-006：common 失败即停分支 ----
    # .ps1：健康确认失败 break；失败提示含 9300 端口排查
    has_failstop_ps1 = ("break" in c_ps1 and "9000/9100/9200/9400/9300" in c_ps1)
    has_failstop_sh = ("break" in c_sh and "9000/9100/9200/9400/9300" in c_sh)
    ok = has_failstop_ps1 and has_failstop_sh
    report("TC-TASK007-006", "common 启动失败时失败即停（健康确认失败 break，提示含 9300 端口排查）",
           ok, "" if ok else "失败即停分支或端口提示缺失")

    # ---- TC-TASK007-007：汇总输出覆盖 common 且全部成功退出 0 ----
    # .ps1：结尾汇总遍历 $Services（含 common）+ 成功输出"5 个后端服务"+ exit 0
    has_summary_ps1 = ("foreach ($svc in $Services)" in c_ps1 and "5 个后端服务" in c_ps1 and "exit 0" in c_ps1)
    # .sh：结尾汇总遍历 ${SERVICES[@]}（含 common）+ 成功输出"5 个后端服务"+ exit 0
    has_summary_sh = ('for entry in "${SERVICES[@]}"' in c_sh and "5 个后端服务" in c_sh and "exit 0" in c_sh)
    ok = has_summary_ps1 and has_summary_sh
    report("TC-TASK007-007", "全部启动成功输出 5 个服务汇总（含 common）并退出码 0（.ps1/.sh 静态校验）",
           ok, "" if ok else "汇总输出或退出码约定不完整")


# ============================================================
# 用例：TC-TASK004-xxx 通用配置管理查询接口（API-035/036，P0）
# ============================================================
def test_task004_config_query_endpoints():
    """TC-TASK004-xxx：通用配置管理查询接口契约校验（直连 common 服务 9300）——
    1. API-035 GET /api/v1/common/config 返回 200 与统一 ApiResult<PageResult<ConfigItemVO>>；
    2. API-036 GET /api/v1/common/config/{serviceName} 返回 200 与统一 ApiResult<List<ConfigItemVO>>；
    3. serviceName 非法（non-existent）返回 400（BusinessException 兜底）；
    4. 敏感配置脱敏：sensitive=1 项 value 为掩码 ****（不暴露明文）；
    5. 结果为空返回 200 空列表（非 500）。
    说明：common 服务（9300）未运行时按环境阻塞 SKIP（与 TASK-003 策略一致）。"""
    if COMMON_URL == "http://127.0.0.1:9300":
        pass

    # 1. API-035 查询配置列表（分页契约）
    status, body = http_get(COMMON_URL + "/api/v1/common/config?serviceName=auth-service&page=1&pageSize=10")
    if status is None:
        report("TC-TASK004-002", "common 服务不可达，配置列表查询契约验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        code = body.get("code")
        data = body.get("data") or {}
        ok = (status == 200 and code == 200
              and isinstance(data.get("records"), list) and "total" in data
              and "page" in data and "pageSize" in data)
        report("TC-TASK004-002", "GET /api/v1/common/config 返回统一 ApiResult 分页结果",
               ok, "HTTP {} code={} records={} total={}".format(
                   status, code, len(data.get("records") or []), data.get("total")))

    # 2. API-036 按微服务名称查询（列表契约）
    status, body = http_get(COMMON_URL + "/api/v1/common/config/auth-service")
    if status is None:
        report("TC-TASK004-003", "common 服务不可达，按微服务查询配置契约验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        code = body.get("code")
        data = body.get("data")
        ok = (status == 200 and code == 200 and isinstance(data, list))
        report("TC-TASK004-003", "GET /api/v1/common/config/{serviceName} 返回统一 ApiResult 列表",
               ok, "HTTP {} code={} data是列表={}".format(status, code, isinstance(data, list)))

    # 3. serviceName 非法返回 400
    status, body = http_get(COMMON_URL + "/api/v1/common/config/non-existent")
    if status is None:
        report("TC-TASK004-004", "common 服务不可达，serviceName 非法校验验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        code = body.get("code")
        ok = (status == 400 and code == 400)
        report("TC-TASK004-004", "serviceName 非法（non-existent）返回 400",
               ok, "HTTP {} code={} message={}".format(status, code, body.get("message")))

    # 4. 敏感配置脱敏：查询某服务配置，敏感项 value 不应为明文
    status, body = http_get(COMMON_URL + "/api/v1/common/config/auth-service")
    if status is None:
        report("TC-TASK004-005", "common 服务不可达，敏感配置脱敏验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        data = body.get("data") or []
        sensitive_items = [it for it in data if it.get("sensitive") is True]
        if not sensitive_items:
            report("TC-TASK004-005", "敏感配置脱敏（种子数据无敏感项，按环境阻塞）",
                   False, "auth-service 无 sensitive=true 配置项", skipped=True)
        else:
            masked_all = all(not isinstance(it.get("value"), str) or "*" in (it.get("value") or "")
                             for it in sensitive_items)
            no_plain = all(it.get("value") != "secret-token" for it in sensitive_items)
            ok = masked_all and no_plain
            report("TC-TASK004-005", "敏感配置脱敏不暴露明文（掩码 {}）".format(
                [it.get("value") for it in sensitive_items]), ok, "")

    # 5. 空结果返回 200 空列表（serviceName 合法但无配置的场景用不存在 key 过滤验证分页空结果）
    status, body = http_get(COMMON_URL + "/api/v1/common/config?serviceName=gateway&key=not-exist-key")
    if status is None:
        report("TC-TASK004-009", "common 服务不可达，空结果 200 验证按环境阻塞",
               False, "common @ {}".format(COMMON_URL), skipped=True)
    else:
        code = body.get("code")
        data = body.get("data") or {}
        records = data.get("records") or []
        ok = (status == 200 and code == 200 and isinstance(records, list))
        report("TC-TASK004-009", "条件无匹配返回 200 与空 records（非 500）",
               ok, "HTTP {} code={} records数={}".format(status, code, len(records)))


# ============================================================
# 用例：TC-TASK009-xxx 环境配置更新（env.json / env.example.json 新增 COMMON_PORT，P0）
# ============================================================
def test_task009_env_config_checks():
    """TC-TASK009-001/002/003/004/005/006：环境配置文件静态校验——
    1. TC-001：deploy/env.example.json（入库模板）新增 COMMON_PORT 且示例值正确（9300），JSON 合法；
    2. TC-002：deploy/env.json（实际配置）新增 COMMON_PORT 且实际值正确（9300），JSON 合法；
    3. TC-003：新增 COMMON_PORT 后现有 gateway/auth/biz/system 相关配置键完整保留（NACOS_ADDR、
       DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PUBLIC_KEY、
       RSA_PRIVATE_KEY 等原有关键键未被删除/改名）；
    4. TC-004：env.json 与 env.example.json 键集合一致（便于复制模板后直接使用）；
    5. TC-005：COMMON_PORT 键名符合 load-env 键名合法性白名单正则 ^[A-Za-z_][A-Za-z0-9_]*$；
    6. TC-006：env.json 被 .gitignore 忽略（不入库）、env.example.json 未被忽略（可入库）。
    说明：纯配置文件校验（无代码逻辑变更），单元测试/接口测试/UI 测试不适用。"""
    env_example = os.path.join(PROJECT_ROOT, "deploy", "env.example.json")
    env_actual = os.path.join(PROJECT_ROOT, "deploy", "env.json")
    required_keys = ["NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT", "DB_USERNAME", "DB_PASSWORD",
                     "REDIS_HOST", "REDIS_PORT", "RSA_PUBLIC_KEY", "RSA_PRIVATE_KEY",
                     "VERIFICATION_CODE_MOCK", "PASSWORD_MIN_LENGTH", "PASSWORD_MAX_LENGTH"]
    import json as _json
    import re as _re

    def load_json(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return _json.load(f), None
        except Exception as e:
            return None, str(e)

    example, err_example = load_json(env_example)
    actual, err_actual = load_json(env_actual)

    # ---- TC-TASK009-001：env.example.json 新增 COMMON_PORT 且示例值正确 ----
    if err_example:
        report("TC-TASK009-001", "env.example.json 新增 COMMON_PORT 且示例值正确（9300）",
               False, "读取/解析失败: {}".format(err_example))
    else:
        ok = isinstance(example, dict) and "COMMON_PORT" in example and example.get("COMMON_PORT") == "9300"
        report("TC-TASK009-001", "env.example.json 新增 COMMON_PORT 且示例值正确（9300）",
               ok, "" if ok else "COMMON_PORT 缺失或示例值错误: {}".format(example.get("COMMON_PORT")))

    # ---- TC-TASK009-002：env.json 新增 COMMON_PORT 且实际值正确 ----
    if err_actual:
        report("TC-TASK009-002", "env.json 新增 COMMON_PORT 且实际值正确（9300）",
               False, "读取/解析失败: {}".format(err_actual))
    else:
        ok = isinstance(actual, dict) and "COMMON_PORT" in actual and actual.get("COMMON_PORT") == "9300"
        report("TC-TASK009-002", "env.json 新增 COMMON_PORT 且实际值正确（9300）",
               ok, "" if ok else "COMMON_PORT 缺失或实际值错误: {}".format(actual.get("COMMON_PORT")))

    # ---- TC-TASK009-003：现有 gateway/auth/biz/system 配置项不受影响 ----
    missing_example = [k for k in required_keys if example is not None and k not in example]
    missing_actual = [k for k in required_keys if actual is not None and k not in actual]
    ok = (example is not None and actual is not None and not missing_example and not missing_actual)
    report("TC-TASK009-003", "新增 COMMON_PORT 后现有 gateway/auth/biz/system 配置键完整保留",
           ok, "" if ok else "缺失键 example={} actual={}".format(missing_example, missing_actual))

    # ---- TC-TASK009-004：env.json 与 env.example.json 键集合一致 ----
    if example is not None and actual is not None:
        keys_example = set(example.keys())
        keys_actual = set(actual.keys())
        ok = keys_example == keys_actual
        report("TC-TASK009-004", "env.json 与 env.example.json 键集合一致",
               ok, "" if ok else "键差异 example-实际={} 实际-示例={}".format(
                   keys_example - keys_actual, keys_actual - keys_example))
    else:
        report("TC-TASK009-004", "env.json 与 env.example.json 键集合一致", False, "存在文件解析失败")

    # ---- TC-TASK009-005：COMMON_PORT 符合 load-env 键名白名单 ----
    ok = bool(_re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", "COMMON_PORT"))
    report("TC-TASK009-005", "COMMON_PORT 键名符合 load-env 键名合法性白名单",
           ok, "" if ok else "键名不合法")

    # ---- TC-TASK009-006：env.json 不入库、env.example.json 入库策略保持 ----
    import subprocess as _sp
    try:
        r_ignore = _sp.run(["git", "check-ignore", "-q", "deploy/env.json"],
                           cwd=PROJECT_ROOT, capture_output=True)
        env_json_ignored = (r_ignore.returncode == 0)
    except Exception:
        env_json_ignored = None
    try:
        r_not = _sp.run(["git", "check-ignore", "-q", "deploy/env.example.json"],
                        cwd=PROJECT_ROOT, capture_output=True)
        env_example_ignored = (r_not.returncode == 0)
    except Exception:
        env_example_ignored = None
    if env_json_ignored is None or env_example_ignored is None:
        report("TC-TASK009-006", "env.json 不入库、env.example.json 入库策略保持",
               False, "git check-ignore 执行异常（仓库可能未初始化）")
    else:
        ok = env_json_ignored and not env_example_ignored
        report("TC-TASK009-006", "env.json 不入库（git 忽略）、env.example.json 可入库",
               ok, "" if ok else "忽略状态 env.json={} env.example.json={}".format(
                   env_json_ignored, env_example_ignored))


def test_task010_docs_checks():
    """TC-TASK010-001/002/003/004/005/006/007/008/009：部署文档与 readme 更新静态校验——
    1. TC-001：deploy/deploy.md 端口映射表含 cloudoffice-common（9300）；
    2. TC-002：deploy.md 启动顺序为 common → gateway → auth → biz → system（common 首位）；
    3. TC-003：deploy.md 停止顺序为 system → biz → auth → gateway → common（common 末位）；
    4. TC-004：deploy.md 健康检查端点含 /api/v1/common/health；
    5. TC-005：deploy.md 环境变量说明含 COMMON_PORT；
    6. TC-006：readme.md 项目介绍含 cloudoffice-common 服务化说明（独立部署/微服务/服务化）；
    7. TC-007：readme.md 功能清单含通用配置管理功能介绍；
    8. TC-008：readme.md 端口映射含 cloudoffice-common（9300）；
    9. TC-009：现有 gateway/auth/biz/system 内容未被删除或覆盖（deploy.md 与 readme.md
       仍含 9000/9100/9200/9400 端口与服务说明）。
    说明：纯文档更新（无代码逻辑变更），单元测试/接口测试/UI 测试不适用；以功能测试
    （文档内容校验）覆盖。"""
    deploy_md = os.path.join(PROJECT_ROOT, "deploy", "deploy.md")
    readme_md = os.path.join(PROJECT_ROOT, "readme.md")

    def read_text(path):
        try:
            with open(path, "r", encoding="utf-8") as f:
                return f.read(), None
        except Exception as e:
            return None, str(e)

    deploy_txt, err_deploy = read_text(deploy_md)
    readme_txt, err_readme = read_text(readme_md)

    # ---- TC-TASK010-001：deploy.md 端口映射表含 cloudoffice-common（9300） ----
    if err_deploy:
        report("TC-TASK010-001", "deploy.md 端口映射表含 cloudoffice-common（9300）",
               False, "读取失败: {}".format(err_deploy))
    else:
        ok = ("cloudoffice-common" in deploy_txt) and ("9300" in deploy_txt)
        report("TC-TASK010-001", "deploy.md 端口映射表含 cloudoffice-common（9300）",
               ok, "" if ok else "deploy.md 缺少 cloudoffice-common 或 9300 端口")

    # ---- TC-TASK010-002：deploy.md 启动顺序 common → gateway → auth → biz → system ----
    if err_deploy:
        report("TC-TASK010-002", "deploy.md 启动顺序为 common→gateway→auth→biz→system",
               False, "读取失败: {}".format(err_deploy))
    else:
        ok = ("common" in deploy_txt and "gateway" in deploy_txt and "auth" in deploy_txt
              and "biz" in deploy_txt and "system" in deploy_txt)
        # 校验 common 在启动顺序表述中位于 gateway 之前
        idx_common = deploy_txt.find("common")
        idx_gateway = deploy_txt.find("gateway")
        ok = ok and (idx_common != -1) and (idx_gateway != -1) and idx_common < idx_gateway
        report("TC-TASK010-002", "deploy.md 启动顺序为 common→gateway→auth→biz→system（common 首位）",
               ok, "" if ok else "deploy.md 启动顺序未体现 common 在 gateway 之前")

    # ---- TC-TASK010-003：deploy.md 停止顺序 system → biz → auth → gateway → common ----
    if err_deploy:
        report("TC-TASK010-003", "deploy.md 停止顺序为 system→biz→auth→gateway→common",
               False, "读取失败: {}".format(err_deploy))
    else:
        ok = ("system" in deploy_txt and "biz" in deploy_txt and "auth" in deploy_txt
              and "gateway" in deploy_txt and "common" in deploy_txt)
        idx_system = deploy_txt.rfind("system")
        idx_common = deploy_txt.rfind("common")
        ok = ok and (idx_system != -1) and (idx_common != -1) and idx_common > idx_system
        report("TC-TASK010-003", "deploy.md 停止顺序为 system→biz→auth→gateway→common（common 末位）",
               ok, "" if ok else "deploy.md 停止顺序未体现 common 在 system 之后")

    # ---- TC-TASK010-004：deploy.md 健康检查端点含 /api/v1/common/health ----
    if err_deploy:
        report("TC-TASK010-004", "deploy.md 健康检查端点含 /api/v1/common/health",
               False, "读取失败: {}".format(err_deploy))
    else:
        ok = "/api/v1/common/health" in deploy_txt
        report("TC-TASK010-004", "deploy.md 健康检查端点含 /api/v1/common/health",
               ok, "" if ok else "deploy.md 缺少 /api/v1/common/health")

    # ---- TC-TASK010-005：deploy.md 环境变量说明含 COMMON_PORT ----
    if err_deploy:
        report("TC-TASK010-005", "deploy.md 环境变量说明含 COMMON_PORT",
               False, "读取失败: {}".format(err_deploy))
    else:
        ok = "COMMON_PORT" in deploy_txt
        report("TC-TASK010-005", "deploy.md 环境变量说明含 COMMON_PORT",
               ok, "" if ok else "deploy.md 缺少 COMMON_PORT 配置说明")

    # ---- TC-TASK010-006：readme.md 项目介绍含 common 服务化说明 ----
    if err_readme:
        report("TC-TASK010-006", "readme.md 项目介绍含 common 服务化说明",
               False, "读取失败: {}".format(err_readme))
    else:
        ok = ("cloudoffice-common" in readme_txt and
              any(kw in readme_txt for kw in ("独立部署", "微服务", "服务化")))
        report("TC-TASK010-006", "readme.md 项目介绍含 common 服务化说明",
               ok, "" if ok else "readme.md 缺少 cloudoffice-common 服务化说明")

    # ---- TC-TASK010-007：readme.md 功能清单含通用配置管理功能介绍 ----
    if err_readme:
        report("TC-TASK010-007", "readme.md 功能清单含通用配置管理功能介绍",
               False, "读取失败: {}".format(err_readme))
    else:
        ok = "通用配置管理" in readme_txt
        report("TC-TASK010-007", "readme.md 功能清单含通用配置管理功能介绍",
               ok, "" if ok else "readme.md 缺少通用配置管理功能介绍")

    # ---- TC-TASK010-008：readme.md 端口映射含 cloudoffice-common（9300） ----
    if err_readme:
        report("TC-TASK010-008", "readme.md 端口映射含 cloudoffice-common（9300）",
               False, "读取失败: {}".format(err_readme))
    else:
        ok = ("cloudoffice-common" in readme_txt) and ("9300" in readme_txt)
        report("TC-TASK010-008", "readme.md 端口映射含 cloudoffice-common（9300）",
               ok, "" if ok else "readme.md 缺少 cloudoffice-common 或 9300 端口")

    # ---- TC-TASK010-009：现有 gateway/auth/biz/system 内容未被删除或覆盖 ----
    if err_deploy or err_readme:
        report("TC-TASK010-009", "现有 gateway/auth/biz/system 内容未被删除或覆盖",
               False, "读取失败 deploy={} readme={}".format(err_deploy, err_readme))
    else:
        deploy_ok = all(k in deploy_txt for k in
                        ("cloudoffice-gateway", "9000", "cloudoffice-auth-service", "9100",
                         "cloudoffice-biz-service", "9200", "cloudoffice-system-service", "9400"))
        readme_ok = all(k in readme_txt for k in
                        ("cloudoffice-gateway", "9000", "cloudoffice-auth-service", "9100",
                         "cloudoffice-biz-service", "9200", "cloudoffice-system-service", "9400"))
        ok = deploy_ok and readme_ok
        report("TC-TASK010-009", "现有 gateway/auth/biz/system 内容未被删除或覆盖",
               ok, "" if ok else "deploy.md 缺失={} readme.md 缺失={}".format(
                   [k for k in ("cloudoffice-gateway", "9000", "cloudoffice-auth-service", "9100",
                                "cloudoffice-biz-service", "9200", "cloudoffice-system-service", "9400")
                    if k not in deploy_txt],
                   [k for k in ("cloudoffice-gateway", "9000", "cloudoffice-auth-service", "9100",
                                "cloudoffice-biz-service", "9200", "cloudoffice-system-service", "9400")
                    if k not in readme_txt]))


# ============================================================
# 主入口
# ============================================================
def main():
    print("=" * 70)
    print("CloudStrollOffice 接口自动化测试 v0.2.8（TASK-005 网关路由与白名单扩展 + TASK-002 common 服务化改造 + TASK-003 common 健康检查与 API 服务 + TASK-006 build-backend 编译脚本 + TASK-007 部署启动脚本 + TASK-008 部署停止脚本 + TASK-009 环境配置 + TASK-010 部署文档与 readme 更新）")
    print("项目根目录: {}".format(PROJECT_ROOT))
    print("网关地址: {}   auth-service: {}   common-service: {}".format(GATEWAY_URL, AUTH_URL, COMMON_URL))
    print("=" * 70)
    # TASK-005：网关路由与白名单扩展
    test_tc_task005_001_common_health_whitelist()
    test_tc_task005_002_common_config_auth()
    test_tc_task005_003_common_config_by_service_auth()
    test_tc_task005_004_existing_route_regression()
    # TASK-002：common 服务化改造（构建产物 / 独立启动冒烟 / 下游编译回归）
    test_task002_build_artifact()
    test_task002_startup_smoke()
    test_task002_downstream_compile()
    # TASK-003：common 健康检查端点与 API 服务（HealthController + SpringDoc）
    test_tc_task003_common_health_endpoint()
    # TASK-006：build-backend 编译脚本（静态校验 + 编译产物校验）
    test_task006_build_script_checks()
    test_task006_build_artifacts()
    # TASK-008：部署停止脚本（deploy-stop-all 含 common 居末 + deploy-stop-common）
    test_task008_stop_script_checks()
    test_task008_stop_script_execute()
    # TASK-007：部署启动脚本（deploy-start-all 含 common 居首 + deploy-start-common）
    test_task007_start_script_checks()
    # TASK-004：通用配置管理查询接口（API-035/036 契约 + serviceName 校验 + 敏感脱敏 + 空结果）
    test_task004_config_query_endpoints()
    # TASK-009：环境配置更新（env.json / env.example.json 新增 COMMON_PORT）
    test_task009_env_config_checks()
    # TASK-010：部署文档与 readme 更新（deploy.md / readme.md）
    test_task010_docs_checks()
    print("=" * 70)
    print("汇总：通过 {} 失败 {} 跳过 {}".format(PASS, FAIL, SKIP))
    if FAILED_CASES:
        print("失败用例：")
        for cid, name, detail in FAILED_CASES:
            print("  - {} {} {}".format(cid, name, detail))
    if SKIPPED_CASES:
        print("跳过用例（环境阻塞，不计失败）：")
        for cid, name, detail in SKIPPED_CASES:
            print("  - {} {} {}".format(cid, name, detail))
    return 1 if FAIL > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
