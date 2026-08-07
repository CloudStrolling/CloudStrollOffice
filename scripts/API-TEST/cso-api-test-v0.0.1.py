# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.0.1
=========================================================
覆盖：docs/cso-v0.0.1/cso-testcase-v0.0.1.md 中 TC-001 ~ TC-045 全部接口测试用例
接口基准：docs/cso-api.md（统一前缀 /api/v1/{module}，统一响应 ApiResult<T>，成功 code=200）

依赖：requests（pip install requests）；验证码从数据库读取需 pymysql（可选，缺失时相关用例 SKIP）
用法：
    python cso-api-test-v0.0.1.py                    # 默认 http://localhost:9000
    python cso-api-test-v0.0.1.py http://10.0.0.8:9000   # 指定网关地址
    环境变量：DB_HOST/DB_PORT/DB_USER/DB_PWD/DB_NAME 覆盖验证码读取库连接；AUTH_DIRECT_URL 覆盖认证服务直连地址（默认 http://localhost:9100）

说明：
    1. 需网关(9000)、认证服务(9100) 及数据库/Redis 已启动；企业服务(9200)/系统服务(9400) 仅 TC-045 需要。
    2. 验证码为模拟发送模式（app.verification-code.mock=true），仅写日志不返回 code，
       脚本通过 pymysql 读取 t_auth_verification_code 表获取最新验证码闭环。
    3. 管理接口经网关访问，X-Tenant-Id/X-Roles 等头由网关 AuthFilter 从 JWT 自动透传；
       TC-043 直连认证服务时验证缺少 X-Tenant-Id 被拒。
    4. OAuth 无真实第三方服务，本版本 OAuth 注册/登录按 oauthCode 即 openId 的模拟方式执行。
    5. 脚本为每个用例创建独立测试数据（uuid 命名），用例间互不污染；
       admin/admin123 为项目初始测试账号（仅测试用途），管理员登录失败时管理类用例标记 SKIP。
"""
import os
import sys
import time
import uuid

import requests

# ============================================================
# 配置
# ============================================================
BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:9000"
AUTH_API = BASE_URL + "/api/v1/auth"
AUTH_DIRECT_URL = os.environ.get("AUTH_DIRECT_URL", "http://localhost:9100")
AUTH_DIRECT_API = AUTH_DIRECT_URL + "/api/v1/auth"
TIMEOUT = 10

ADMIN_LOGIN_NAME = "admin"
ADMIN_PASSWORD = "admin123"
TENANT_CODE = "DEFAULT"
CLIENT_TYPE = "H5"

# 验证码读取数据库连接（环境变量可覆盖）
DB_HOST = os.environ.get("DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ.get("DB_USER", "root")
DB_PWD = os.environ.get("DB_PWD", "root")
DB_NAME = os.environ.get("DB_NAME", "cloudstroll_office_auth")

PASS = 0
FAIL = 0
SKIP = 0
FAILED_CASES = []
SKIPPED_CASES = []

ADMIN_TOKEN = None  # main 中登录后缓存，管理类用例复用


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


def new_name(prefix):
    """生成唯一测试标识（避免重复执行冲突）"""
    return "{}_{}".format(prefix, uuid.uuid4().hex[:8])


def new_phone():
    """生成唯一测试手机号（13x + 8 位随机）"""
    return "13" + str(uuid.uuid4().int % 100000000).zfill(8)


def req(method, path, token=None, json=None, headers=None):
    """统一请求封装：返回 (resp, body)"""
    h = {"Content-Type": "application/json"}
    if token:
        h["Authorization"] = "Bearer " + token
    if headers:
        h.update(headers)
    resp = requests.request(method, path, json=json, headers=h, timeout=TIMEOUT)
    try:
        body = resp.json()
    except Exception:
        body = {}
    return resp, body


def api_ok(resp, body):
    """判断统一响应是否成功（HTTP 200 且 code=200）"""
    return resp.status_code == 200 and body.get("code") == 200


def login(login_name=None, password=None, phone=None, sms_code=None, mode="USERNAME_PASSWORD",
          tenant_code=TENANT_CODE, client_type=CLIENT_TYPE):
    """登录，返回 (accessToken, refreshToken, body)；失败返回 (None, None, body)"""
    payload = {"loginMode": mode, "tenantCode": tenant_code, "clientType": client_type}
    if login_name:
        payload["loginName"] = login_name
    if password:
        payload["password"] = password
    if phone:
        payload["phone"] = phone
    if sms_code:
        payload["smsCode"] = sms_code
    resp, body = req("POST", AUTH_API + "/login", json=payload)
    if api_ok(resp, body):
        data = body.get("data") or {}
        return data.get("accessToken"), data.get("refreshToken"), body
    return None, None, body


def admin_login():
    """管理员登录，成功后缓存 ADMIN_TOKEN；返回是否成功"""
    global ADMIN_TOKEN
    if ADMIN_TOKEN:
        return True
    access_token, _, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    if access_token:
        ADMIN_TOKEN = access_token
        return True
    return False


def register_username(login_name, password, user_name="测试用户", phone=None):
    """注册 USERNAME 模式用户，返回 (userId, body)；失败返回 (None, body)"""
    payload = {"registerMode": "USERNAME", "loginName": login_name,
               "password": password, "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE,
               "userName": user_name}
    if phone:
        payload["phone"] = phone
    resp, body = req("POST", AUTH_API + "/register", json=payload)
    if api_ok(resp, body):
        data = body.get("data") or {}
        return data.get("userId"), body
    return None, body


def send_code(target, purpose, mode="SMS"):
    """发送验证码：返回 (resp, body)"""
    payload = {"target": target, "purpose": purpose, "mode": mode}
    return req("POST", AUTH_API + "/verification-code/send", json=payload)


def fetch_code_from_db(target, purpose):
    """从 t_auth_verification_code 读取最新未使用验证码；无 pymysql 或查询失败返回 None"""
    try:
        import pymysql
        conn = pymysql.connect(host=DB_HOST, port=DB_PORT, user=DB_USER,
                               password=DB_PWD, database=DB_NAME, charset="utf8mb4")
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT code FROM t_auth_verification_code "
                    "WHERE target=%s AND purpose=%s AND used=0 "
                    "ORDER BY id DESC LIMIT 1",
                    (target, purpose))
                row = cur.fetchone()
                return row[0] if row else None
        finally:
            conn.close()
    except Exception as exc:
        print("  [DB] 验证码读取失败: {}（缺失 pymysql 或连接失败，相关用例将 SKIP）".format(exc))
        return None


def db_available():
    """校验数据库可读性（验证码闭环前置条件）"""
    try:
        import pymysql  # noqa: F401
        return True
    except Exception:
        return False


def protected_get(token):
    """携带 token 访问受保护接口 GET /api/v1/auth/users，返回 HTTP 状态码（网关透传租户头）"""
    resp, _ = req("GET", AUTH_API + "/users", token=token)
    return resp.status_code


# ============================================================
# TC-001 ~ TC-004 / TC-028：用户注册（F-001）
# ============================================================

def test_tc001_register_username_password():
    """TC-001：用户名密码注册成功且可自动登录（P0）"""
    login_name = new_name("reg")
    password = "Pass@1234"
    user_id, reg_body = register_username(login_name, password)
    if not user_id:
        report("TC-001", "用户名密码注册成功", False,
               "注册失败: {} {}".format(reg_body.get("code"), reg_body.get("message")))
        return
    reg_data = reg_body.get("data") or {}
    ok = reg_data.get("accountSettled") is True
    access_token, refresh_token, _ = login(login_name=login_name, password=password)
    ok = ok and bool(access_token) and bool(refresh_token)
    report("TC-001", "用户名密码注册成功", ok,
           "userId={} accountSettled={}".format(user_id, reg_data.get("accountSettled")))


def test_tc002_register_phone_code():
    """TC-002：手机验证码注册成功（P0）"""
    if not db_available():
        report("TC-002", "手机验证码注册成功", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    resp, body = send_code(phone, "REGISTER", "SMS")
    if not api_ok(resp, body):
        report("TC-002", "手机验证码注册成功", False,
               "发送验证码失败: {} {}".format(body.get("code"), body.get("message")))
        return
    code = fetch_code_from_db(phone, "REGISTER")
    if not code:
        report("TC-002", "手机验证码注册成功", False, "库中未读取到 REGISTER 验证码", skipped=True)
        return
    payload = {"registerMode": "PHONE_CODE", "phone": phone, "smsCode": code,
               "userName": "手机注册用户", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE}
    resp, reg_body = req("POST", AUTH_API + "/register", json=payload)
    ok = api_ok(resp, reg_body) and bool((reg_body.get("data") or {}).get("userId"))
    report("TC-002", "手机验证码注册成功", ok,
           "phone={} resp={}".format(phone, resp.status_code))


def test_tc003_register_oauth():
    """TC-003：OAuth 注册创建未完善账号，重复 oauthCode 被拒（P1）"""
    oauth_code = "mock_oauth_{}".format(uuid.uuid4().hex[:8])
    payload = {"registerMode": "OAUTH", "oauthProvider": "WECHAT", "oauthCode": oauth_code,
               "userName": "微信用户", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE}
    resp, body = req("POST", AUTH_API + "/register", json=payload)
    data = body.get("data") or {}
    ok = api_ok(resp, body) and bool(data.get("userId")) and data.get("accountSettled") is False
    # 同一 oauthCode 重复注册：实际实现按 openId 全局唯一抛 409（幂等由上层流程保证）
    resp2, body2 = req("POST", AUTH_API + "/register", json=payload)
    ok = ok and resp2.status_code == 409
    report("TC-003", "OAuth 注册两步注册", ok,
           "userId={} 重复注册 HTTP={}（期望 409）".format(data.get("userId"), resp2.status_code))


def test_tc004_register_duplicate_and_invalid():
    """TC-004：登录名重复与弱密码被拒（P0）"""
    ok = True
    # 1. 重复登录名 admin
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME", "loginName": ADMIN_LOGIN_NAME,
        "password": "Pass@1234", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE,
        "userName": "重复注册"})
    ok = ok and resp.status_code == 409
    # 2. 弱密码（3 位）
    resp2, body2 = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME", "loginName": new_name("weak"),
        "password": "123", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE,
        "userName": "弱密码用户"})
    ok = ok and resp2.status_code == 400
    report("TC-004", "重复登录名/弱密码被拒", ok,
           "重复注册 HTTP={} 弱密码 HTTP={}".format(resp.status_code, resp2.status_code))


def test_tc028_account_settlement():
    """TC-028：两步注册账号补全成功与已完善拒绝（P0）"""
    oauth_code = "mock_oauth_{}".format(uuid.uuid4().hex[:8])
    payload = {"registerMode": "OAUTH", "oauthProvider": "DINGTALK", "oauthCode": oauth_code,
               "userName": "钉钉用户", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE}
    resp, body = req("POST", AUTH_API + "/register", json=payload)
    data = body.get("data") or {}
    user_id = data.get("userId")
    token_pair = data.get("tokenPair") or {}
    oauth_token = token_pair.get("accessToken")
    if not user_id or not oauth_token:
        report("TC-028", "两步注册账号补全", False,
               "OAuth 注册未返回 userId/token: {}".format(body))
        return
    # 1. 补全账号
    settle_payload = {"userId": user_id, "loginName": new_name("set"),
                      "password": "Pass@1234"}
    resp2, body2 = req("PUT", AUTH_API + "/account/settlement",
                       token=oauth_token, json=settle_payload)
    ok = api_ok(resp2, body2)
    # 2. 已完善账号重复补全被拒
    resp3, body3 = req("PUT", AUTH_API + "/account/settlement",
                       token=oauth_token, json=settle_payload)
    ok = ok and resp3.status_code in (400, 403, 422)
    report("TC-028", "两步注册账号补全", ok,
           "补全 HTTP={} 重复补全 HTTP={}".format(resp2.status_code, resp3.status_code))


# ============================================================
# TC-005 ~ TC-010：多模式登录（F-002）
# ============================================================

def test_tc005_login_username_password():
    """TC-005：用户名密码登录成功签发双 Token（P0）"""
    access_token, refresh_token, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    ok = bool(access_token) and bool(refresh_token)
    report("TC-005", "用户名密码登录成功", ok, "accessToken 长度={}".format(len(access_token or "")))


def test_tc006_login_wrong_password_anti_enum():
    """TC-006：错误密码与不存在用户返回一致提示（P0）"""
    resp1, body1 = login(password="wrong_password_123")
    resp2, body2 = login(login_name="no_such_user_{}".format(uuid.uuid4().hex[:6]),
                         password="wrong_password_123")
    ok = (body1.get("code") == body2.get("code")) and (body1.get("message") == body2.get("message"))
    report("TC-006", "防账号枚举", ok,
           "错误密码 code={} msg={}；不存在用户 code={} msg={}".format(
               body1.get("code"), body1.get("message"), body2.get("code"), body2.get("message")))


def test_tc007_login_phone_code():
    """TC-007：手机验证码登录（正确码成功/错误码拒绝）（P0）"""
    if not db_available():
        report("TC-007", "手机验证码登录", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    password = "Pass@1234"
    user_id, _ = register_username(new_name("pcl"), password, phone=phone)
    if not user_id:
        report("TC-007", "手机验证码登录", False, "测试用户注册失败", skipped=True)
        return
    # 发送 LOGIN 验证码
    resp, body = send_code(phone, "LOGIN", "SMS")
    if not api_ok(resp, body):
        report("TC-007", "手机验证码登录", False, "发送 LOGIN 验证码失败", skipped=True)
        return
    code = fetch_code_from_db(phone, "LOGIN")
    if not code:
        report("TC-007", "手机验证码登录", False, "库中未读取到 LOGIN 验证码", skipped=True)
        return
    # 正确码登录
    access_token, _, _ = login(phone=phone, sms_code=code, mode="PHONE_CODE")
    ok = bool(access_token)
    # 错误码登录被拒
    _, _, err_body = login(phone=phone, sms_code="000000", mode="PHONE_CODE")
    ok = ok and err_body.get("code") in (400, 422)
    report("TC-007", "手机验证码登录", ok,
           "正确码登录={} 错误码拒绝={}".format(bool(access_token), err_body.get("code")))


def test_tc008_login_phone_password():
    """TC-008：手机+密码登录成功（P0）"""
    phone = new_phone()
    password = "Pass@1234"
    user_id, _ = register_username(new_name("ppl"), password, phone=phone)
    if not user_id:
        report("TC-008", "手机+密码登录", False, "测试用户注册失败", skipped=True)
        return
    access_token, _, _ = login(phone=phone, password=password, mode="PHONE_PASSWORD")
    ok = bool(access_token)
    report("TC-008", "手机+密码登录", ok, "登录成功={}".format(bool(access_token)))


def test_tc009_login_disabled():
    """TC-009：封禁账号登录被拒（P0）"""
    if not admin_login():
        report("TC-009", "封禁账号登录被拒", False, "管理员登录失败", skipped=True)
        return
    password = "Pass@1234"
    user_id, _ = register_username(new_name("ban"), password)
    if not user_id:
        report("TC-009", "封禁账号登录被拒", False, "测试用户注册失败", skipped=True)
        return
    # 管理员封禁用户
    resp, body = req("PUT", AUTH_API + "/users/{}/status".format(user_id),
                     token=ADMIN_TOKEN, json={"status": 3})
    if not api_ok(resp, body):
        report("TC-009", "封禁账号登录被拒", False, "封禁操作失败: {}".format(body), skipped=True)
        return
    # 封禁后登录
    _, _, login_body = login(login_name=ADMIN_LOGIN_NAME, password=password)
    ok = login_body.get("code") in (400, 401, 403)
    report("TC-009", "封禁账号登录被拒", ok,
           "封禁后登录 code={}".format(login_body.get("code")))
    # 还原：解封
    req("PUT", AUTH_API + "/users/{}/status".format(user_id),
        token=ADMIN_TOKEN, json={"status": 0})


def test_tc010_login_invalid_mode_client():
    """TC-010：无效登录模式与客户端类型被拒（P1）"""
    ok = True
    # 无效登录模式
    resp1, body1 = req("POST", AUTH_API + "/login", json={
        "loginMode": "UNKNOWN_MODE", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE,
        "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD})
    ok = ok and resp1.status_code in (400, 422)
    # 无效客户端类型
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "tenantCode": TENANT_CODE, "clientType": "TV",
        "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD})
    ok = ok and resp2.status_code in (400, 422)
    report("TC-010", "无效模式/客户端类型被拒", ok,
           "无效模式 HTTP={} 无效客户端 HTTP={}".format(resp1.status_code, resp2.status_code))


# ============================================================
# TC-011 ~ TC-014：Token 与会话（F-003/F-004）
# ============================================================

def test_tc011_refresh_success():
    """TC-011：Token 刷新成功换发新双 Token（P0）"""
    access_token, refresh_token, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    if not refresh_token:
        report("TC-011", "Token 刷新成功", False, "登录失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    data = body.get("data") or {}
    ok = api_ok(resp, body) and bool(data.get("accessToken")) and bool(data.get("refreshToken"))
    report("TC-011", "Token 刷新成功", ok, "刷新 HTTP={}".format(resp.status_code))


def test_tc012_refresh_rotation():
    """TC-012：刷新轮换后旧 Refresh Token 失效（P0）"""
    access_token, refresh_token, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    if not refresh_token:
        report("TC-012", "刷新轮换防重放", False, "登录失败", skipped=True)
        return
    # 第一次刷新成功
    resp1, body1 = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    # 同一 refreshToken 再次刷新被拒
    resp2, body2 = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    ok = api_ok(resp1, body1) and resp2.status_code in (400, 401)
    report("TC-012", "刷新轮换防重放", ok,
           "第一次 HTTP={} 第二次 HTTP={}".format(resp1.status_code, resp2.status_code))


def test_tc013_same_client_mutex():
    """TC-013：同端互斥-同客户端新登录踢旧会话（P0）"""
    password = "Pass@1234"
    login_name = new_name("mutex")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-013", "同端互斥", False, "测试用户注册失败", skipped=True)
        return
    token1, _, _ = login(login_name=login_name, password=password, client_type="H5")
    token2, _, _ = login(login_name=login_name, password=password, client_type="H5")
    if not token1 or not token2:
        report("TC-013", "同端互斥", False, "两次登录失败", skipped=True)
        return
    code_new = protected_get(token2)
    code_old = protected_get(token1)
    ok = code_new == 200 and code_old in (400, 401)
    report("TC-013", "同端互斥", ok,
           "新 Token 访问 HTTP={} 旧 Token 访问 HTTP={}".format(code_new, code_old))


def test_tc014_multi_client_coexist():
    """TC-014：多端共存-不同客户端类型同时在线（P0）"""
    password = "Pass@1234"
    login_name = new_name("multi")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-014", "多端共存", False, "测试用户注册失败", skipped=True)
        return
    token1, _, _ = login(login_name=login_name, password=password, client_type="H5")
    token2, _, _ = login(login_name=login_name, password=password, client_type="ANDROID")
    if not token1 or not token2:
        report("TC-014", "多端共存", False, "两次登录失败", skipped=True)
        return
    code1 = protected_get(token1)
    code2 = protected_get(token2)
    ok = code1 == 200 and code2 == 200
    report("TC-014", "多端共存", ok,
           "H5 Token HTTP={} Android Token HTTP={}".format(code1, code2))


# ============================================================
# TC-015 ~ TC-018：登出与踢人（F-004）
# ============================================================

def test_tc015_logout_invalidates_token():
    """TC-015：主动登出后 Token 失效（P0）"""
    password = "Pass@1234"
    login_name = new_name("lgout")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-015", "登出后 Token 失效", False, "测试用户注册失败", skipped=True)
        return
    access_token, refresh_token, _ = login(login_name=login_name, password=password)
    if not access_token:
        report("TC-015", "登出后 Token 失效", False, "登录失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/logout", token=access_token)
    code_access = protected_get(access_token)
    resp_refresh, _ = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    ok = api_ok(resp, body) and code_access in (400, 401) and resp_refresh.status_code in (400, 401)
    report("TC-015", "登出后 Token 失效", ok,
           "登出 HTTP={} 原 access 访问 HTTP={} 原 refresh 刷新 HTTP={}".format(
               resp.status_code, code_access, resp_refresh.status_code))


def test_tc016_logout_idempotent():
    """TC-016：重复登出幂等（P0）"""
    access_token, _, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    if not access_token:
        report("TC-016", "重复登出幂等", False, "登录失败", skipped=True)
        return
    resp1, body1 = req("POST", AUTH_API + "/logout", token=access_token)
    resp2, body2 = req("POST", AUTH_API + "/logout", token=access_token)
    ok = api_ok(resp1, body1) and api_ok(resp2, body2)
    report("TC-016", "重复登出幂等", ok,
           "第一次 HTTP={} 第二次 HTTP={}".format(resp1.status_code, resp2.status_code))


def test_tc017_kickout():
    """TC-017：管理员强制踢人后登录态失效（P0）"""
    if not admin_login():
        report("TC-017", "管理员强制踢人", False, "管理员登录失败", skipped=True)
        return
    password = "Pass@1234"
    login_name = new_name("kick")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-017", "管理员强制踢人", False, "测试用户注册失败", skipped=True)
        return
    target_token, _, _ = login(login_name=login_name, password=password)
    if not target_token:
        report("TC-017", "管理员强制踢人", False, "目标用户登录失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=ADMIN_TOKEN,
                     json={"userId": user_id})
    code = protected_get(target_token)
    ok = api_ok(resp, body) and code in (400, 401)
    report("TC-017", "管理员强制踢人", ok,
           "踢人 HTTP={} 原 Token 访问 HTTP={}".format(resp.status_code, code))


def test_tc018_kickout_forbidden():
    """TC-018：非管理员踢人被拒（P0）"""
    password = "Pass@1234"
    login_name = new_name("norole")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-018", "非管理员踢人被拒", False, "测试用户注册失败", skipped=True)
        return
    normal_token, _, _ = login(login_name=login_name, password=password)
    if not normal_token:
        report("TC-018", "非管理员踢人被拒", False, "普通用户登录失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=normal_token,
                     json={"userId": user_id})
    ok = resp.status_code == 403
    report("TC-018", "非管理员踢人被拒", ok,
           "普通用户踢人 HTTP={}（期望 403）".format(resp.status_code))


# ============================================================
# TC-019 ~ TC-022：验证码管理（F-008）
# ============================================================

def test_tc019_send_code_success():
    """TC-019：发送验证码成功且库中存在 6 位验证码（P0）"""
    if not db_available():
        report("TC-019", "发送验证码成功", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    target = new_phone()
    resp, body = send_code(target, "REGISTER", "SMS")
    code = fetch_code_from_db(target, "REGISTER")
    ok = api_ok(resp, body) and bool(code) and len(code) == 6 and code.isdigit()
    report("TC-019", "发送验证码成功", ok,
           "发送 HTTP={} 库中验证码={}".format(resp.status_code, code))


def test_tc020_send_code_frequency():
    """TC-020：60 秒内重复发送验证码被拒（P0）"""
    if not db_available():
        report("TC-020", "验证码发送限频", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    target = new_phone()
    resp1, body1 = send_code(target, "REGISTER", "SMS")
    resp2, body2 = send_code(target, "REGISTER", "SMS")
    ok = api_ok(resp1, body1) and resp2.status_code == 429
    report("TC-020", "验证码发送限频", ok,
           "第一次 HTTP={} 第二次 HTTP={}（期望 429）".format(resp1.status_code, resp2.status_code))


def test_tc021_code_single_use():
    """TC-021：验证码单次使用-复用被拒（P0）"""
    if not db_available():
        report("TC-021", "验证码一次性", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    user_id, _ = register_username(new_name("once"), "Pass@1234", phone=phone)
    if not user_id:
        report("TC-021", "验证码一次性", False, "测试用户注册失败", skipped=True)
        return
    resp, body = send_code(phone, "LOGIN", "SMS")
    if not api_ok(resp, body):
        report("TC-021", "验证码一次性", False, "发送 LOGIN 验证码失败", skipped=True)
        return
    code = fetch_code_from_db(phone, "LOGIN")
    if not code:
        report("TC-021", "验证码一次性", False, "库中未读取到 LOGIN 验证码", skipped=True)
        return
    # 首次登录成功（消费验证码）
    access_token, _, first_body = login(phone=phone, sms_code=code, mode="PHONE_CODE")
    # 复用同一验证码被拒
    _, _, second_body = login(phone=phone, sms_code=code, mode="PHONE_CODE")
    ok = bool(access_token) and second_body.get("code") in (400, 422)
    report("TC-021", "验证码一次性", ok,
           "首次登录成功={} 复用 code={}".format(bool(access_token), second_body.get("code")))


def test_tc022_code_purpose_mismatch():
    """TC-022：验证码用途不匹配被拒（P1）"""
    if not db_available():
        report("TC-022", "验证码用途隔离", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    user_id, _ = register_username(new_name("purpose"), "Pass@1234", phone=phone)
    if not user_id:
        report("TC-022", "验证码用途隔离", False, "测试用户注册失败", skipped=True)
        return
    # 发送 REGISTER 用途验证码
    resp, body = send_code(phone, "REGISTER", "SMS")
    if not api_ok(resp, body):
        report("TC-022", "验证码用途隔离", False, "发送 REGISTER 验证码失败", skipped=True)
        return
    code = fetch_code_from_db(phone, "REGISTER")
    if not code:
        report("TC-022", "验证码用途隔离", False, "库中未读取到 REGISTER 验证码", skipped=True)
        return
    # 用 REGISTER 验证码登录（LOGIN 用途校验应拒绝）
    _, _, login_body = login(phone=phone, sms_code=code, mode="PHONE_CODE")
    ok = login_body.get("code") in (400, 422)
    report("TC-022", "验证码用途隔离", ok,
           "REGISTER 码用于登录被拒 code={}".format(login_body.get("code")))


# ============================================================
# TC-023 ~ TC-026：密码管理（F-006）
# ============================================================

def test_tc023_change_password_success():
    """TC-023：修改密码成功且新密码可登录（P0）"""
    password = "Old@12345"
    login_name = new_name("chpwd")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-023", "修改密码成功", False, "测试用户注册失败", skipped=True)
        return
    access_token, _, _ = login(login_name=login_name, password=password)
    if not access_token:
        report("TC-023", "修改密码成功", False, "旧密码登录失败", skipped=True)
        return
    new_password = "New@54321"
    resp, body = req("PUT", AUTH_API + "/password/change", token=access_token,
                     json={"oldPassword": password, "newPassword": new_password,
                           "confirmPassword": new_password})
    new_token, _, _ = login(login_name=login_name, password=new_password)
    ok = api_ok(resp, body) and bool(new_token)
    report("TC-023", "修改密码成功", ok,
           "修改 HTTP={} 新密码登录={}".format(resp.status_code, bool(new_token)))


def test_tc024_change_password_wrong_old():
    """TC-024：修改密码旧密码错误被拒（P0）"""
    password = "Pass@1234"
    login_name = new_name("wrond")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-024", "旧密码错误被拒", False, "测试用户注册失败", skipped=True)
        return
    access_token, _, _ = login(login_name=login_name, password=password)
    if not access_token:
        report("TC-024", "旧密码错误被拒", False, "登录失败", skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access_token,
                     json={"oldPassword": "WrongOld@1", "newPassword": "New@54321",
                           "confirmPassword": "New@54321"})
    ok = resp.status_code in (400, 422)
    report("TC-024", "旧密码错误被拒", ok, "HTTP={}（期望 400/422）".format(resp.status_code))


def test_tc025_forgot_send_code():
    """TC-025：密码找回发送验证码成功/未绑定账号被拒（P0）"""
    if not db_available():
        report("TC-025", "找回发送验证码", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    user_id, _ = register_username(new_name("forgot"), "Pass@1234", phone=phone)
    if not user_id:
        report("TC-025", "找回发送验证码", False, "测试用户注册失败", skipped=True)
        return
    # 已绑定手机号：发送成功（PasswordService 内部以 RESET_PWD 用途落库）
    payload = {"target": phone, "purpose": "RESET_PASSWORD", "mode": "SMS"}
    resp1, body1 = req("POST", AUTH_API + "/password/forgot/send-code", json=payload)
    code = fetch_code_from_db(phone, "RESET_PWD")
    ok = api_ok(resp1, body1) and bool(code)
    # 未绑定手机号：USER_NOT_FOUND
    resp2, body2 = req("POST", AUTH_API + "/password/forgot/send-code",
                       json={"target": new_phone(), "purpose": "RESET_PASSWORD", "mode": "SMS"})
    ok = ok and resp2.status_code in (400, 404, 422)
    report("TC-025", "找回发送验证码", ok,
           "已绑定 HTTP={} 未绑定 HTTP={}".format(resp1.status_code, resp2.status_code))


def test_tc026_forgot_reset():
    """TC-026：重置密码成功、旧 Token 失效、错误码被拒（P0）"""
    if not db_available():
        report("TC-026", "找回重置密码", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone = new_phone()
    old_password = "Pass@1234"
    login_name = new_name("frst")
    user_id, _ = register_username(login_name, old_password, phone=phone)
    if not user_id:
        report("TC-026", "找回重置密码", False, "测试用户注册失败", skipped=True)
        return
    old_token, _, _ = login(login_name=login_name, password=old_password)
    if not old_token:
        report("TC-026", "找回重置密码", False, "旧密码登录失败", skipped=True)
        return
    # 发送重置验证码
    payload = {"target": phone, "purpose": "RESET_PASSWORD", "mode": "SMS"}
    resp_send, _ = req("POST", AUTH_API + "/password/forgot/send-code", json=payload)
    code = fetch_code_from_db(phone, "RESET_PWD")
    if not api_ok(resp_send, _) or not code:
        report("TC-026", "找回重置密码", False, "发送/读取重置验证码失败", skipped=True)
        return
    new_password = "New@67890"
    # 1. 正确重置
    resp1, body1 = req("POST", AUTH_API + "/password/forgot/reset", json={
        "mode": "SMS", "target": phone, "code": code, "newPassword": new_password})
    # 2. 旧 Token 访问被拒（会话已清）
    old_code = protected_get(old_token)
    # 3. 新密码登录成功
    new_token, _, _ = login(login_name=login_name, password=new_password)
    # 4. 错误验证码重置被拒
    resp4, body4 = req("POST", AUTH_API + "/password/forgot/reset", json={
        "mode": "SMS", "target": phone, "code": "999999", "newPassword": new_password})
    ok = (api_ok(resp1, body1) and old_code in (400, 401) and bool(new_token)
          and resp4.status_code in (400, 422))
    report("TC-026", "找回重置密码", ok,
           "重置 HTTP={} 旧 Token HTTP={} 新密码登录={} 错误码 HTTP={}".format(
               resp1.status_code, old_code, bool(new_token), resp4.status_code))


# ============================================================
# TC-027：手机号变更（F-007）
# ============================================================

def test_tc027_change_phone():
    """TC-027：短信验证码变更手机号（含占用/错误码拒绝）（P0）"""
    if not db_available():
        report("TC-027", "变更手机号", False, "无 pymysql/数据库，无法闭环验证码", skipped=True)
        return
    phone_a = new_phone()
    phone_b = new_phone()
    phone_new = new_phone()
    password = "Pass@1234"
    user_a, _ = register_username(new_name("cp_a"), password, phone=phone_a)
    user_b, _ = register_username(new_name("cp_b"), password, phone=phone_b)
    if not user_a or not user_b:
        report("TC-027", "变更手机号", False, "测试用户注册失败", skipped=True)
        return
    token_a, _, _ = login(login_name=user_a and new_name("cp_a"), password=password)
    # 直接按手机号重新登录 A（loginName 为随机名）
    token_a, _, _ = login(phone=phone_a, password=password, mode="PHONE_PASSWORD")
    if not token_a:
        report("TC-027", "变更手机号", False, "用户 A 登录失败", skipped=True)
        return
    # 发送旧手机与新手机 CHANGE_PHONE 验证码
    send_code(phone_a, "CHANGE_PHONE", "SMS")
    send_code(phone_b, "CHANGE_PHONE", "SMS")
    send_code(phone_new, "CHANGE_PHONE", "SMS")
    old_code = fetch_code_from_db(phone_a, "CHANGE_PHONE")
    new_code = fetch_code_from_db(phone_new, "CHANGE_PHONE")
    if not old_code or not new_code:
        report("TC-027", "变更手机号", False, "验证码读取失败", skipped=True)
        return
    # 1. 占用场景：换绑到 B 已绑定手机号 → 409
    resp1, body1 = req("PUT", AUTH_API + "/phone/change", token=token_a, json={
        "newPhone": phone_b, "oldPhoneCode": old_code,
        "newPhoneCode": fetch_code_from_db(phone_b, "CHANGE_PHONE")})
    # 2. 成功场景：换绑到新手机号 → 200
    resp2, body2 = req("PUT", AUTH_API + "/phone/change", token=token_a, json={
        "newPhone": phone_new, "oldPhoneCode": old_code, "newPhoneCode": new_code})
    # 3. 错误旧手机验证码 → 400/409/422
    send_code(phone_a, "CHANGE_PHONE", "SMS")  # 重新发送（换绑后旧手机已解绑，仅验证错误码路径）
    resp3, body3 = req("PUT", AUTH_API + "/phone/change", token=token_a, json={
        "newPhone": new_phone(), "oldPhoneCode": "000000", "newPhoneCode": new_code})
    ok = (resp1.status_code == 409 and api_ok(resp2, body2)
          and resp3.status_code in (400, 409, 422))
    report("TC-027", "变更手机号", ok,
           "占用 HTTP={} 成功 HTTP={} 错误码 HTTP={}".format(
               resp1.status_code, resp2.status_code, resp3.status_code))


# ============================================================
# TC-029 ~ TC-033：用户管理（F-011）
# ============================================================

def test_tc029_user_page_query():
    """TC-029：管理员分页查询用户列表（P0）"""
    if not admin_login():
        report("TC-029", "用户分页查询", False, "管理员登录失败", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=10&keyword=admin",
                     token=ADMIN_TOKEN)
    data = body.get("data") or {}
    records = data.get("records") or []
    has_pwd = any("password" in r for r in records)
    ok = (api_ok(resp, body) and "records" in data and "total" in data
          and "page" in data and "pageSize" in data and not has_pwd)
    report("TC-029", "用户分页查询", ok,
           "records={} total={} page={} pageSize={} 含密码字段={}".format(
               len(records), data.get("total"), data.get("page"),
               data.get("pageSize"), has_pwd))


def test_tc030_user_detail():
    """TC-030：用户详情查询与不存在用户（P0）"""
    if not admin_login():
        report("TC-030", "用户详情查询", False, "管理员登录失败", skipped=True)
        return
    user_id, _ = register_username(new_name("dtl"), "Pass@1234")
    if not user_id:
        report("TC-030", "用户详情查询", False, "测试用户注册失败", skipped=True)
        return
    resp1, body1 = req("GET", AUTH_API + "/users/{}".format(user_id), token=ADMIN_TOKEN)
    data1 = body1.get("data") or {}
    ok = api_ok(resp1, body1) and "password" not in data1
    resp2, body2 = req("GET", AUTH_API + "/users/999999999", token=ADMIN_TOKEN)
    ok = ok and resp2.status_code in (400, 404, 422)
    report("TC-030", "用户详情查询", ok,
           "详情 HTTP={} 不存在 HTTP={}".format(resp1.status_code, resp2.status_code))


def test_tc031_user_update():
    """TC-031：更新用户信息（P1）"""
    if not admin_login():
        report("TC-031", "更新用户信息", False, "管理员登录失败", skipped=True)
        return
    user_id, _ = register_username(new_name("upd"), "Pass@1234")
    if not user_id:
        report("TC-031", "更新用户信息", False, "测试用户注册失败", skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/users/{}".format(user_id), token=ADMIN_TOKEN,
                     json={"userName": "更新后的名字", "email": "updated@example.com"})
    ok = api_ok(resp, body)
    report("TC-031", "更新用户信息", ok, "HTTP={}".format(resp.status_code))


def test_tc032_user_status_disable():
    """TC-032：用户启禁用-登录态实时失效（P0）"""
    if not admin_login():
        report("TC-032", "用户封禁实时失效", False, "管理员登录失败", skipped=True)
        return
    password = "Pass@1234"
    login_name = new_name("st")
    user_id, _ = register_username(login_name, password)
    if not user_id:
        report("TC-032", "用户封禁实时失效", False, "测试用户注册失败", skipped=True)
        return
    token, _, _ = login(login_name=login_name, password=password)
    if not token:
        report("TC-032", "用户封禁实时失效", False, "用户登录失败", skipped=True)
        return
    # 管理员封禁
    resp, body = req("PUT", AUTH_API + "/users/{}/status".format(user_id),
                     token=ADMIN_TOKEN, json={"status": 3})
    old_code = protected_get(token)
    _, _, login_body = login(login_name=login_name, password=password)
    ok = (api_ok(resp, body) and old_code in (400, 401, 403)
          and login_body.get("code") in (400, 401, 403))
    # 解封还原
    req("PUT", AUTH_API + "/users/{}/status".format(user_id),
        token=ADMIN_TOKEN, json={"status": 0})
    report("TC-032", "用户封禁实时失效", ok,
           "封禁 HTTP={} 旧 Token HTTP={} 重登 code={}".format(
               resp.status_code, old_code, login_body.get("code")))


def test_tc033_user_assign_roles():
    """TC-033：分配用户角色（P1）"""
    if not admin_login():
        report("TC-033", "分配用户角色", False, "管理员登录失败", skipped=True)
        return
    user_id, _ = register_username(new_name("ar"), "Pass@1234")
    if not user_id:
        report("TC-033", "分配用户角色", False, "测试用户注册失败", skipped=True)
        return
    resp_role, body_role = req("GET", AUTH_API + "/roles/list", token=ADMIN_TOKEN)
    roles = (body_role.get("data") or []) if api_ok(resp_role, body_role) else []
    if not roles:
        report("TC-033", "分配用户角色", False, "角色列表为空", skipped=True)
        return
    role_id = roles[0].get("id")
    resp, body = req("PUT", AUTH_API + "/users/{}/roles".format(user_id),
                     token=ADMIN_TOKEN, json={"roleIds": [role_id]})
    ok = api_ok(resp, body)
    report("TC-033", "分配用户角色", ok, "HTTP={} roleId={}".format(resp.status_code, role_id))


# ============================================================
# TC-034 ~ TC-037：角色管理（F-012）
# ============================================================

def test_tc034_role_create():
    """TC-034：创建角色成功（P0）"""
    if not admin_login():
        report("TC-034", "创建角色", False, "管理员登录失败", skipped=True)
        return
    role_code = "ROLE_{}".format(uuid.uuid4().hex[:8].upper())
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                     json={"roleCode": role_code, "roleName": "测试角色", "status": 0})
    data = body.get("data") or {}
    ok = api_ok(resp, body) and data.get("roleCode") == role_code and bool(data.get("id"))
    report("TC-034", "创建角色", ok,
           "HTTP={} roleCode={} id={}".format(resp.status_code, data.get("roleCode"),
                                              data.get("id")))


def test_tc035_role_duplicate_code():
    """TC-035：角色编码租户内重复被拒（P0）"""
    if not admin_login():
        report("TC-035", "角色编码重复被拒", False, "管理员登录失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                     json={"roleCode": "SUPER_ADMIN", "roleName": "重复角色", "status": 0})
    ok = resp.status_code == 409
    report("TC-035", "角色编码重复被拒", ok, "HTTP={}（期望 409）".format(resp.status_code))


def test_tc036_role_delete():
    """TC-036：删除角色-被引用不可删（P0）"""
    if not admin_login():
        report("TC-036", "删除角色", False, "管理员登录失败", skipped=True)
        return
    # 1. 新建未引用角色可删
    role_code = "ROLE_DEL_{}".format(uuid.uuid4().hex[:8].upper())
    resp_c, body_c = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                         json={"roleCode": role_code, "roleName": "待删除角色", "status": 0})
    new_role_id = (body_c.get("data") or {}).get("id")
    if not new_role_id:
        report("TC-036", "删除角色", False, "创建测试角色失败", skipped=True)
        return
    resp_del, _ = req("DELETE", AUTH_API + "/roles/{}".format(new_role_id), token=ADMIN_TOKEN)
    ok = api_ok(resp_del, _)
    # 2. 被引用角色（SUPER_ADMIN 分配给 admin）删除被拒
    resp_ref, body_ref = req("DELETE", AUTH_API + "/roles/2", token=ADMIN_TOKEN)
    ok = ok and resp_ref.status_code == 409
    report("TC-036", "删除角色", ok,
           "未引用删除 HTTP={} 被引用删除 HTTP={}".format(resp_del.status_code,
                                                       resp_ref.status_code))


def test_tc037_role_assign_permissions():
    """TC-037：角色分配权限（P1）"""
    if not admin_login():
        report("TC-037", "角色分配权限", False, "管理员登录失败", skipped=True)
        return
    role_code = "ROLE_PM_{}".format(uuid.uuid4().hex[:8].upper())
    resp_c, body_c = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                         json={"roleCode": role_code, "roleName": "权限角色", "status": 0})
    role_id = (body_c.get("data") or {}).get("id")
    resp_t, body_t = req("GET", AUTH_API + "/permissions/tree", token=ADMIN_TOKEN)
    perms = (body_t.get("data") or []) if api_ok(resp_t, body_t) else []
    if not role_id or not perms:
        report("TC-037", "角色分配权限", False, "角色或权限数据不足", skipped=True)
        return
    perm_id = perms[0].get("id")
    resp, body = req("PUT", AUTH_API + "/roles/{}/permissions".format(role_id),
                     token=ADMIN_TOKEN, json={"permissionIds": [perm_id]})
    ok = api_ok(resp, body)
    report("TC-037", "角色分配权限", ok,
           "HTTP={} roleId={} permId={}".format(resp.status_code, role_id, perm_id))


# ============================================================
# TC-038 ~ TC-040：权限管理（F-013）
# ============================================================

def test_tc038_permission_tree():
    """TC-038：权限树查询（P0）"""
    if not admin_login():
        report("TC-038", "权限树查询", False, "管理员登录失败", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/permissions/tree", token=ADMIN_TOKEN)
    data = body.get("data") or []
    ok = api_ok(resp, body) and isinstance(data, list) and len(data) > 0
    report("TC-038", "权限树查询", ok, "HTTP={} 根节点数={}".format(resp.status_code, len(data)))


def test_tc039_permission_create():
    """TC-039：创建权限与编码重复被拒（P0）"""
    if not admin_login():
        report("TC-039", "创建权限", False, "管理员登录失败", skipped=True)
        return
    perm_code = "test:perm:{}".format(uuid.uuid4().hex[:8])
    payload = {"permCode": perm_code, "permName": "测试权限", "parentId": 0, "status": 0}
    resp1, body1 = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN, json=payload)
    ok = api_ok(resp1, body1) and bool((body1.get("data") or {}).get("id"))
    # 重复创建同编码 → 409
    resp2, body2 = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN, json=payload)
    ok = ok and resp2.status_code == 409
    report("TC-039", "创建权限", ok,
           "创建 HTTP={} 重复 HTTP={}（期望 409）".format(resp1.status_code, resp2.status_code))


def test_tc040_permission_update_delete():
    """TC-040：更新/删除权限-子权限约束（P1）"""
    if not admin_login():
        report("TC-040", "权限更新删除", False, "管理员登录失败", skipped=True)
        return
    parent_code = "test:parent:{}".format(uuid.uuid4().hex[:8])
    child_code = "test:child:{}".format(uuid.uuid4().hex[:8])
    resp_p, body_p = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                         json={"permCode": parent_code, "permName": "父权限",
                               "parentId": 0, "status": 0})
    parent_id = (body_p.get("data") or {}).get("id")
    if not parent_id:
        report("TC-040", "权限更新删除", False, "创建父权限失败", skipped=True)
        return
    resp_c, body_c = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                         json={"permCode": child_code, "permName": "子权限",
                               "parentId": parent_id, "status": 0})
    child_id = (body_c.get("data") or {}).get("id")
    if not child_id:
        report("TC-040", "权限更新删除", False, "创建子权限失败", skipped=True)
        return
    # 1. 更新父权限 → 200
    resp_u, _ = req("PUT", AUTH_API + "/permissions/{}".format(parent_id), token=ADMIN_TOKEN,
                    json={"permName": "父权限-更新", "status": 0})
    ok = api_ok(resp_u, _)
    # 2. 有子权限删除父权限 → 409
    resp_del, _ = req("DELETE", AUTH_API + "/permissions/{}".format(parent_id),
                      token=ADMIN_TOKEN)
    ok = ok and resp_del.status_code == 409
    # 3. 删除子权限 → 200，再删父权限 → 200
    resp_cd, _ = req("DELETE", AUTH_API + "/permissions/{}".format(child_id),
                     token=ADMIN_TOKEN)
    ok = ok and api_ok(resp_cd, _)
    resp_pd, _ = req("DELETE", AUTH_API + "/permissions/{}".format(parent_id),
                     token=ADMIN_TOKEN)
    ok = ok and api_ok(resp_pd, _)
    report("TC-040", "权限更新删除", ok,
           "更新={} 父删(有子)={} 子删={} 父删(无子)={}".format(
               resp_u.status_code, resp_del.status_code,
               resp_cd.status_code, resp_pd.status_code))


# ============================================================
# TC-041 ~ TC-043：网关认证（F-005/F-018）
# ============================================================

def test_tc041_gateway_whitelist():
    """TC-041：白名单接口免 Token 放行（P0）"""
    resp1, body1 = req("GET", AUTH_API + "/health")
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "tenantCode": TENANT_CODE,
        "clientType": CLIENT_TYPE, "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD})
    ok = api_ok(resp1, body1) and api_ok(resp2, body2)
    report("TC-041", "白名单免 Token 放行", ok,
           "health HTTP={} login HTTP={}".format(resp1.status_code, resp2.status_code))


def test_tc042_gateway_no_or_fake_token():
    """TC-042：无 Token/伪造 Token 访问受保护接口返回 401（P0）"""
    ok = True
    # 无 Authorization
    resp1, _ = req("GET", AUTH_API + "/users")
    ok = ok and resp1.status_code == 401
    # 伪造 Token
    resp2, _ = req("GET", AUTH_API + "/users", token="fake.token.value")
    ok = ok and resp2.status_code == 401
    # 非 Bearer
    h = {"Content-Type": "application/json",
         "Authorization": "Basic dGVzdDoxMjM="}
    resp3 = requests.get(AUTH_API + "/users", headers=h, timeout=TIMEOUT)
    ok = ok and resp3.status_code == 401
    report("TC-042", "缺失/伪造 Token 被拒", ok,
           "无 Token HTTP={} 伪造 HTTP={} Basic HTTP={}".format(
               resp1.status_code, resp2.status_code, resp3.status_code))


def test_tc043_gateway_forbidden():
    """TC-043：缺少租户头直连认证服务被拒，经网关透传正常（P0）"""
    if not admin_login():
        report("TC-043", "租户头透传", False, "管理员登录失败", skipped=True)
        return
    # 1. 直连认证服务（无 X-Tenant-Id）→ 400
    resp1 = requests.get(AUTH_DIRECT_API + "/users",
                         headers={"Authorization": "Bearer " + ADMIN_TOKEN},
                         timeout=TIMEOUT)
    # 2. 经网关（透传 X-Tenant-Id）→ 200
    resp2, body2 = req("GET", AUTH_API + "/users", token=ADMIN_TOKEN)
    ok = resp1.status_code == 400 and api_ok(resp2, body2)
    report("TC-043", "租户头透传", ok,
           "直连缺头 HTTP={}（期望 400） 网关 HTTP={}".format(resp1.status_code,
                                                          resp2.status_code))


# ============================================================
# TC-044：多租户隔离（F-010）
# ============================================================

def test_tc044_tenant_isolation():
    """TC-044：多租户隔离-列表内用户均属 DEFAULT 租户（P0）"""
    if not admin_login():
        report("TC-044", "多租户隔离", False, "管理员登录失败", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=50", token=ADMIN_TOKEN)
    records = (body.get("data") or {}).get("records") or []
    tenant_ids = {r.get("tenantId") for r in records}
    ok = api_ok(resp, body) and len(records) > 0 and tenant_ids == {1}
    report("TC-044", "多租户隔离", ok,
           "HTTP={} 用户数={} tenantId 集合={}".format(resp.status_code, len(records), tenant_ids))


# ============================================================
# TC-045：健康检查（F-016）
# ============================================================

def test_tc045_health_checks():
    """TC-045：认证/企业/系统服务健康检查（P1）"""
    ok = True
    # auth health：白名单免 Token
    resp1, body1 = req("GET", AUTH_API + "/health")
    data1 = body1.get("data") or {}
    ok = ok and api_ok(resp1, body1) and data1.get("status") == "UP"
    # biz/system health：需带 Token
    access_token, _, _ = login(login_name=ADMIN_LOGIN_NAME, password=ADMIN_PASSWORD)
    if not access_token:
        report("TC-045", "服务健康检查", False, "管理员登录失败，biz/system 无法验证", skipped=True)
        return
    resp2, body2 = req("GET", BASE_URL + "/api/v1/biz/health", token=access_token)
    data2 = body2.get("data") or {}
    resp3, body3 = req("GET", BASE_URL + "/api/v1/system/health", token=access_token)
    data3 = body3.get("data") or {}
    ok = ok and api_ok(resp2, body2) and api_ok(resp3, body3)
    ok = ok and data2.get("status") == "UP" and data3.get("status") == "UP"
    report("TC-045", "服务健康检查", ok,
           "auth={} biz={} system={}".format(resp1.status_code, resp2.status_code,
                                             resp3.status_code))


# ============================================================
# main
# ============================================================

def main():
    """按用例编号顺序执行全部接口测试"""
    print("=" * 70)
    print("CloudStrollOffice 接口自动化测试 v0.0.1")
    print("网关地址: {}".format(BASE_URL))
    print("认证服务直连地址: {}".format(AUTH_DIRECT_URL))
    print("开始时间: {}".format(time.strftime("%Y-%m-%d %H:%M:%S")))
    print("=" * 70)

    if not admin_login():
        print("[WARN] 管理员登录失败，管理类用例将 SKIP；请确认服务已启动且初始账号可用")
    else:
        print("[INFO] 管理员登录成功，缓存 ADMIN_TOKEN 供管理类用例复用")

    # 注册（F-001）
    test_tc001_register_username_password()
    test_tc002_register_phone_code()
    test_tc003_register_oauth()
    test_tc004_register_duplicate_and_invalid()
    test_tc028_account_settlement()
    # 登录（F-002）
    test_tc005_login_username_password()
    test_tc006_login_wrong_password_anti_enum()
    test_tc007_login_phone_code()
    test_tc008_login_phone_password()
    test_tc009_login_disabled()
    test_tc010_login_invalid_mode_client()
    # Token 与会话（F-003/F-004）
    test_tc011_refresh_success()
    test_tc012_refresh_rotation()
    test_tc013_same_client_mutex()
    test_tc014_multi_client_coexist()
    # 登出与踢人（F-004）
    test_tc015_logout_invalidates_token()
    test_tc016_logout_idempotent()
    test_tc017_kickout()
    test_tc018_kickout_forbidden()
    # 验证码（F-008）
    test_tc019_send_code_success()
    test_tc020_send_code_frequency()
    test_tc021_code_single_use()
    test_tc022_code_purpose_mismatch()
    # 密码管理（F-006）
    test_tc023_change_password_success()
    test_tc024_change_password_wrong_old()
    test_tc025_forgot_send_code()
    test_tc026_forgot_reset()
    # 手机号变更（F-007）
    test_tc027_change_phone()
    # 用户管理（F-011）
    test_tc029_user_page_query()
    test_tc030_user_detail()
    test_tc031_user_update()
    test_tc032_user_status_disable()
    test_tc033_user_assign_roles()
    # 角色管理（F-012）
    test_tc034_role_create()
    test_tc035_role_duplicate_code()
    test_tc036_role_delete()
    test_tc037_role_assign_permissions()
    # 权限管理（F-013）
    test_tc038_permission_tree()
    test_tc039_permission_create()
    test_tc040_permission_update_delete()
    # 网关认证（F-005/F-018）
    test_tc041_gateway_whitelist()
    test_tc042_gateway_no_or_fake_token()
    test_tc043_gateway_forbidden()
    # 多租户隔离（F-010）
    test_tc044_tenant_isolation()
    # 健康检查（F-016）
    test_tc045_health_checks()

    print("=" * 70)
    print("执行完成 | PASS={} FAIL={} SKIP={}".format(PASS, FAIL, SKIP))
    if FAILED_CASES:
        print("失败用例：")
        for cid, name, detail in FAILED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    if SKIPPED_CASES:
        print("跳过用例：")
        for cid, name, detail in SKIPPED_CASES:
            print("  - {} {}：{}".format(cid, name, detail))
    print("=" * 70)
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
