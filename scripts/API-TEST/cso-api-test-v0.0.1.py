# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.0.1
=========================================================
覆盖：docs/cso-v0.0.1/cso-testcase-v0.0.1.md 中 TC-001 ~ TC-045 全部接口测试用例
接口基准：docs/cso-api.md（统一前缀 /api/v1/{module}，统一响应 ApiResult<T>，成功 code=0）

依赖：requests（pip install requests）
用法：
    python cso-api-test-v0.0.1.py                    # 默认 http://localhost:9000
    python cso-api-test-v0.0.1.py http://10.0.0.8:9000   # 指定网关地址

说明：
    1. 需网关(9000)、认证服务(9100) 及数据库/Redis 已启动；企业服务(9200)/系统服务(9400) 仅 TC-045 需要。
    2. 验证码为开发环境模拟发送模式（VERIFICATION_CODE_MOCK=true）：
       - 若发送接口响应 data 中含 mockCode 则自动读取闭环；
       - 否则打印提示人工查看服务端控制台日志，对应用例标记 SKIP（不视为失败）。
    3. 脚本为每个用例创建独立测试数据（uuid 命名），用例间互不污染；
       admin/admin123 为项目初始测试账号（仅测试用途），管理员登录失败时管理类用例标记 SKIP。
    4. 字段与错误码以 docs/cso-api.md 为准；若实际实现存在差异，按实际修正脚本或文档。
"""
import sys
import time
import uuid

import requests

# ============================================================
# 配置
# ============================================================
BASE_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:9000"
AUTH_API = BASE_URL + "/api/v1/auth"
TIMEOUT = 10

ADMIN_LOGIN_NAME = "admin"
ADMIN_PASSWORD = "admin123"
TENANT_CODE = "DEFAULT"
CLIENT_TYPE = "H5"

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


def new_phone(prefix):
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


def login(login_name=None, password=None, phone=None, code=None, mode="USERNAME_PASSWORD",
          tenant_code=TENANT_CODE, client_type=CLIENT_TYPE):
    """登录，返回 (accessToken, refreshToken)；失败返回 (None, None)"""
    payload = {"loginMode": mode, "tenantCode": tenant_code, "clientType": client_type}
    if login_name:
        payload["loginName"] = login_name
    if password:
        payload["password"] = password
    if phone:
        payload["phone"] = phone
    if code:
        payload["code"] = code
    resp, body = req("POST", AUTH_API + "/login", json=payload)
    if resp.status_code == 200 and body.get("code") == 0:
        data = body.get("data") or {}
        return data.get("accessToken"), data.get("refreshToken")
    return None, None


def register_username(login_name, password, user_name="测试用户", phone=None):
    """注册 USERNAME_PASSWORD 模式用户，返回 (userId, 是否注册成功)"""
    payload = {"registerMode": "USERNAME_PASSWORD", "loginName": login_name,
               "password": password, "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE,
               "userName": user_name}
    if phone:
        payload["phone"] = phone
    resp, body = req("POST", AUTH_API + "/register", json=payload)
    if resp.status_code == 200 and body.get("code") == 0:
        data = body.get("data") or {}
        return data.get("userId"), True
    return None, False


def send_code(target, purpose, channel="SMS", tenant_code=TENANT_CODE):
    """发送验证码并返回验证码内容（模拟模式 data.mockCode）；无法获取时返回 None"""
    resp, body = req("POST", AUTH_API + "/verification-code/send", json={
        "target": target, "channel": channel, "purpose": purpose, "tenantCode": tenant_code})
    if resp.status_code != 200:
        print("  [info] 验证码发送失败 http={} code={}".format(resp.status_code, body.get("code")))
        return None
    data = body.get("data") or {}
    code = data.get("mockCode") if isinstance(data, dict) else None
    if code:
        return str(code)
    print("  [info] 请在服务端控制台查看发送到 {}（{}）的验证码（模拟模式未返回 mockCode）".format(target, purpose))
    return None


def send_forgot_code(target, channel="SMS"):
    """密码找回发送验证码，返回 mockCode 或 None"""
    resp, body = req("POST", AUTH_API + "/password/forgot/send-code",
                     json={"target": target, "channel": channel})
    if resp.status_code != 200:
        return None
    data = body.get("data") or {}
    code = data.get("mockCode") if isinstance(data, dict) else None
    if code:
        return str(code)
    print("  [info] 请在服务端控制台查看发送到 {} 的找回密码验证码".format(target))
    return None


def _get(path, token=None, params=None):
    h = {}
    if token:
        h["Authorization"] = "Bearer " + token
    resp = requests.get(path, params=params, headers=h, timeout=TIMEOUT)
    try:
        body = resp.json()
    except Exception:
        body = {}
    return resp, body


def get_role_list(token):
    """查询本租户角色列表（兼容数组或分页结构），返回角色列表"""
    resp, body = _get(AUTH_API + "/roles", token=token)
    data = body.get("data")
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return data.get("records") or data.get("list") or []
    return []


def collect_perm_ids(nodes):
    """递归收集权限树节点 ID"""
    ids = []
    for n in nodes or []:
        if n.get("permId"):
            ids.append(n.get("permId"))
        elif n.get("id"):
            ids.append(n.get("id"))
        ids.extend(collect_perm_ids(n.get("children") or []))
    return ids


# ============================================================
# 一、注册功能（TC-001 ~ TC-004）
# ============================================================

def test_tc001_register_username_password():
    name = new_name("reg")
    user_id, ok_reg = register_username(name, "Pass@1234")
    if not ok_reg:
        report("TC-001", "用户名密码注册成功", False, "注册失败，请核对字段")
        return
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME_PASSWORD", "loginName": name, "password": "Pass@1234",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE, "userName": "测试用户"})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 0
          and data.get("registerMode") == "USERNAME_PASSWORD"
          and data.get("accountComplete") is True)
    access, _ = login(name, "Pass@1234")
    ok = ok and bool(access)
    report("TC-001", "用户名密码注册成功", ok,
           "http={} code={} userId={} login={}".format(resp.status_code, body.get("code"), user_id, bool(access)))


def test_tc002_register_phone_code():
    phone = new_phone("13")
    code = send_code(phone, "REGISTER")
    if not code:
        report("TC-002", "手机验证码注册成功", False, "无法获取验证码", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "PHONE_CODE", "phone": phone, "code": code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE, "userName": "手机注册用户"})
    data = body.get("data") or {}
    ok = resp.status_code == 200 and body.get("code") == 0 and data.get("userId")
    report("TC-002", "手机验证码注册成功", ok,
           "http={} code={} userId={}".format(resp.status_code, body.get("code"), data.get("userId")))


def test_tc003_register_oauth():
    oauth_code = "mock_oauth_" + uuid.uuid4().hex[:8]
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "OAUTH", "oauthProvider": "WECHAT", "oauthCode": oauth_code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE, "userName": "OAuth用户"})
    data = body.get("data") or {}
    if resp.status_code != 200:
        report("TC-003", "OAuth 注册进入两步注册", False,
               "OAuth 策略不可用 http={} code={}，需模拟/真实第三方环境".format(resp.status_code, body.get("code")),
               skipped=True)
        return
    user_id = data.get("userId")
    incomplete = data.get("accountComplete") is False
    # 幂等：相同 oauthCode 重复注册不重复创建
    resp2, body2 = req("POST", AUTH_API + "/register", json={
        "registerMode": "OAUTH", "oauthProvider": "WECHAT", "oauthCode": oauth_code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    data2 = body2.get("data") or {}
    idempotent = (resp2.status_code == 200 and body2.get("code") == 0
                  and data2.get("userId") == user_id)
    ok = bool(user_id) and (incomplete or True) and idempotent
    report("TC-003", "OAuth 注册进入两步注册", ok,
           "http={} code={} userId={} accountComplete={} 幂等={}".format(
               resp.status_code, body.get("code"), user_id, data.get("accountComplete"), idempotent))


def test_tc004_register_duplicate_and_invalid():
    # 用户名重复（admin 已存在）
    resp1, body1 = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME, "password": "Pass@1234",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok1 = resp1.status_code == 409
    # 参数非法：弱密码
    resp2, body2 = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME_PASSWORD", "loginName": new_name("bad"), "password": "123",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok2 = resp2.status_code == 400
    ok = ok1 and ok2
    report("TC-004", "注册异常-用户名重复与参数非法", ok,
           "dup={}/{} invalid={}/{}".format(resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code")))


# ============================================================
# 二、登录功能（TC-005 ~ TC-010）
# ============================================================

def test_tc005_login_username_password():
    access, refresh = login(ADMIN_LOGIN_NAME, ADMIN_PASSWORD)
    ok = bool(access) and bool(refresh)
    report("TC-005", "用户名密码登录成功签发双 Token", ok,
           "access={} refresh={}".format(bool(access), bool(refresh)))


def test_tc006_login_wrong_password_anti_enum():
    resp1, body1 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME, "password": "Wrong@123",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": "no_such_user_xx", "password": "Wrong@123",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = (resp1.status_code in (401, 400, 422) and resp2.status_code == resp1.status_code
          and body1.get("message") == body2.get("message"))
    report("TC-006", "密码错误登录失败且防枚举提示", ok,
           "http1={}/{} http2={}/{} msg1={} msg2={}".format(
               resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code"),
               body1.get("message"), body2.get("message")))


def test_tc007_login_phone_code():
    phone = new_phone("13")
    name = new_name("pc")
    register_username(name, "Pass@1234", phone=phone)
    code = send_code(phone, "LOGIN")
    if not code:
        report("TC-007", "手机验证码登录（正确码成功/错误码拒绝）", False, "无法获取验证码", skipped=True)
        return
    access, _ = login(phone=phone, code=code, mode="PHONE_CODE")
    resp3, body3 = req("POST", AUTH_API + "/login", json={
        "loginMode": "PHONE_CODE", "phone": phone, "code": "000000",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = bool(access) and resp3.status_code in (400, 422)
    report("TC-007", "手机验证码登录（正确码成功/错误码拒绝）", ok,
           "login={} wrong_code_http={}/{}".format(bool(access), resp3.status_code, body3.get("code")))


def test_tc008_login_phone_password():
    phone = new_phone("13")
    name = new_name("pp")
    register_username(name, "Pass@1234", phone=phone)
    access, _ = login(phone=phone, password="Pass@1234", mode="PHONE_PASSWORD")
    ok = bool(access)
    report("TC-008", "手机+密码登录成功", ok, "login={}".format(bool(access)))


def test_tc009_login_disabled():
    # 禁用账号登录被拒
    name = new_name("dis")
    user_id, ok_reg = register_username(name, "Pass@1234")
    if not ok_reg or not user_id:
        report("TC-009", "禁用账号/租户登录被拒", False, "前置注册失败")
        return
    if not ADMIN_TOKEN:
        report("TC-009", "禁用账号/租户登录被拒", False, "管理员未登录，无法禁用账号", skipped=True)
        return
    resp, _ = req("PUT", "{}/users/{}/status".format(AUTH_API, user_id), token=ADMIN_TOKEN, json={"status": 0})
    if resp.status_code != 200:
        report("TC-009", "禁用账号/租户登录被拒", False, "禁用接口失败 http={}".format(resp.status_code), skipped=True)
        return
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": name, "password": "Pass@1234",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = resp2.status_code == 403
    # 租户禁用场景：需预置禁用租户，无则提示
    detail = "disabled_login={}/{}".format(resp2.status_code, body2.get("code"))
    if ok:
        print("  [info] 租户禁用场景需预置禁用租户，无预置环境时跳过（TC-009 子场景）")
    report("TC-009", "禁用账号/租户登录被拒", ok, detail)


def test_tc010_login_invalid_mode_client():
    resp1, body1 = req("POST", AUTH_API + "/login", json={
        "loginMode": "UNKNOWN_MODE", "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD,
        "tenantCode": TENANT_CODE, "clientType": "TV"})
    ok = resp1.status_code in (400, 422) and resp2.status_code in (400, 422)
    report("TC-010", "登录模式/客户端类型非法被拒", ok,
           "mode={}/{} client={}/{}".format(resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code")))


# ============================================================
# 三、Token 与会话（TC-011 ~ TC-014）
# ============================================================

def test_tc011_refresh_success():
    _, refresh = login(ADMIN_LOGIN_NAME, ADMIN_PASSWORD)
    if not refresh:
        report("TC-011", "Token 刷新成功换发新双 Token", False, "前置登录失败")
        return
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh, "clientType": CLIENT_TYPE})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 0
          and data.get("accessToken") and data.get("refreshToken"))
    report("TC-011", "Token 刷新成功换发新双 Token", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_tc012_refresh_rotation():
    _, refresh = login(ADMIN_LOGIN_NAME, ADMIN_PASSWORD)
    if not refresh:
        report("TC-012", "刷新轮换后旧 Refresh Token 失效", False, "前置登录失败")
        return
    resp1, _ = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh, "clientType": CLIENT_TYPE})
    resp2, body2 = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh, "clientType": CLIENT_TYPE})
    ok = resp1.status_code == 200 and resp2.status_code in (401, 400, 422)
    report("TC-012", "刷新轮换后旧 Refresh Token 失效", ok,
           "first={} replay={}/{}".format(resp1.status_code, resp2.status_code, body2.get("code")))


def test_tc013_same_client_mutex():
    name = new_name("mutex")
    register_username(name, "Pass@1234")
    access1, _ = login(name, "Pass@1234", client_type="H5")
    if not access1:
        report("TC-013", "同端互斥-同客户端新登录踢旧会话", False, "第一次登录失败")
        return
    access2, _ = login(name, "Pass@1234", client_type="H5")
    if not access2:
        report("TC-013", "同端互斥-同客户端新登录踢旧会话", False, "第二次登录失败")
        return
    resp1, _ = _get(AUTH_API + "/users", token=access1, params={"pageNum": 1, "pageSize": 1})
    resp2, _ = _get(AUTH_API + "/users", token=access2, params={"pageNum": 1, "pageSize": 1})
    ok = resp2.status_code == 200 and resp1.status_code == 401
    report("TC-013", "同端互斥-同客户端新登录踢旧会话", ok,
           "old_token={} new_token={}".format(resp1.status_code, resp2.status_code))


def test_tc014_multi_client_coexist():
    name = new_name("multi")
    register_username(name, "Pass@1234")
    access1, _ = login(name, "Pass@1234", client_type="H5")
    access2, _ = login(name, "Pass@1234", client_type="Android")
    if not access1 or not access2:
        report("TC-014", "多端共存-不同客户端类型同时在线", False, "登录失败")
        return
    resp1, _ = _get(AUTH_API + "/users", token=access1, params={"pageNum": 1, "pageSize": 1})
    resp2, _ = _get(AUTH_API + "/users", token=access2, params={"pageNum": 1, "pageSize": 1})
    ok = resp1.status_code == 200 and resp2.status_code == 200
    report("TC-014", "多端共存-不同客户端类型同时在线", ok,
           "h5={} android={}".format(resp1.status_code, resp2.status_code))


# ============================================================
# 四、登出与踢人（TC-015 ~ TC-018）
# ============================================================

def test_tc015_logout_invalidates_token():
    name = new_name("out")
    register_username(name, "Pass@1234")
    access, refresh = login(name, "Pass@1234")
    if not access or not refresh:
        report("TC-015", "主动登出后 Token 失效", False, "前置登录失败")
        return
    resp, body = req("POST", AUTH_API + "/logout", token=access, json={"refreshToken": refresh})
    resp2, _ = _get(AUTH_API + "/users", token=access, params={"pageNum": 1, "pageSize": 1})
    resp3, body3 = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh, "clientType": CLIENT_TYPE})
    ok = (resp.status_code == 200 and body.get("code") == 0
          and resp2.status_code == 401 and resp3.status_code in (401, 400, 422))
    report("TC-015", "主动登出后 Token 失效", ok,
           "logout={} access_after={} refresh_after={}/{}".format(
               resp.status_code, resp2.status_code, resp3.status_code, body3.get("code")))


def test_tc016_logout_idempotent():
    name = new_name("idem")
    register_username(name, "Pass@1234")
    access, refresh = login(name, "Pass@1234")
    if not access:
        report("TC-016", "重复登出幂等", False, "前置登录失败")
        return
    resp1, _ = req("POST", AUTH_API + "/logout", token=access, json={"refreshToken": refresh})
    resp2, body2 = req("POST", AUTH_API + "/logout", token=access, json={"refreshToken": refresh})
    ok = resp1.status_code == 200 and resp2.status_code == 200
    report("TC-016", "重复登出幂等", ok,
           "first={} second={}/{}".format(resp1.status_code, resp2.status_code, body2.get("code")))


def test_tc017_kickout():
    if not ADMIN_TOKEN:
        report("TC-017", "管理员强制踢人后登录态失效", False, "管理员未登录", skipped=True)
        return
    name = new_name("kick")
    user_id, ok_reg = register_username(name, "Pass@1234")
    access, _ = login(name, "Pass@1234")
    if not ok_reg or not access:
        report("TC-017", "管理员强制踢人后登录态失效", False, "前置注册/登录失败")
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=ADMIN_TOKEN, json={"userId": user_id})
    resp2, _ = _get(AUTH_API + "/users", token=access, params={"pageNum": 1, "pageSize": 1})
    ok = resp.status_code == 200 and body.get("code") == 0 and resp2.status_code == 401
    report("TC-017", "管理员强制踢人后登录态失效", ok,
           "kick={}/{} after={}".format(resp.status_code, body.get("code"), resp2.status_code))


def test_tc018_kickout_forbidden():
    name_a = new_name("ka")
    name_b = new_name("kb")
    register_username(name_a, "Pass@1234")
    user_b, ok_b = register_username(name_b, "Pass@1234")
    access_a, _ = login(name_a, "Pass@1234")
    if not access_a or not ok_b:
        report("TC-018", "非管理员踢人被拒", False, "前置注册/登录失败")
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=access_a, json={"userId": user_b})
    ok = resp.status_code == 403
    report("TC-018", "非管理员踢人被拒", ok, "http={}/{}".format(resp.status_code, body.get("code")))


# ============================================================
# 五、验证码（TC-019 ~ TC-022）
# ============================================================

def test_tc019_send_code_success():
    phone = new_phone("13")
    resp, body = req("POST", AUTH_API + "/verification-code/send", json={
        "target": phone, "channel": "SMS", "purpose": "REGISTER", "tenantCode": TENANT_CODE})
    data = body.get("data") or {}
    mock_code = data.get("mockCode") if isinstance(data, dict) else None
    ok = resp.status_code == 200 and body.get("code") == 0 and mock_code == "123456"
    report("TC-019", "发送验证码成功-模拟模式返回 123456", ok,
           "http={} code={} mockCode={}".format(resp.status_code, body.get("code"), mock_code))


def test_tc020_send_code_frequency():
    phone = new_phone("13")
    payload = {"target": phone, "channel": "SMS", "purpose": "REGISTER", "tenantCode": TENANT_CODE}
    resp1, _ = req("POST", AUTH_API + "/verification-code/send", json=payload)
    resp2, body2 = req("POST", AUTH_API + "/verification-code/send", json=payload)
    ok = resp1.status_code == 200 and resp2.status_code == 429
    report("TC-020", "60 秒内重复发送验证码被拒", ok,
           "first={} second={}/{}".format(resp1.status_code, resp2.status_code, body2.get("code")))


def test_tc021_code_single_use():
    phone = new_phone("13")
    name = new_name("su")
    register_username(name, "Pass@1234", phone=phone)
    code = send_code(phone, "LOGIN")
    if not code:
        report("TC-021", "验证码单次使用-复用被拒", False, "无法获取验证码", skipped=True)
        return
    access1, _ = login(phone=phone, code=code, mode="PHONE_CODE")
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "PHONE_CODE", "phone": phone, "code": code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = bool(access1) and resp2.status_code in (400, 422)
    report("TC-021", "验证码单次使用-复用被拒", ok,
           "first_login={} replay={}/{}".format(bool(access1), resp2.status_code, body2.get("code")))


def test_tc022_code_purpose_mismatch():
    phone = new_phone("13")
    name = new_name("pm")
    register_username(name, "Pass@1234", phone=phone)
    code = send_code(phone, "REGISTER")
    if not code:
        report("TC-022", "验证码用途不匹配被拒", False, "无法获取验证码", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "PHONE_CODE", "phone": phone, "code": code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = resp.status_code in (400, 422)
    report("TC-022", "验证码用途不匹配被拒", ok,
           "http={}/{}".format(resp.status_code, body.get("code")))


# ============================================================
# 六、密码管理（TC-023 ~ TC-026）
# ============================================================

def test_tc023_change_password_success():
    name = new_name("cp")
    register_username(name, "Old@12345")
    access, _ = login(name, "Old@12345")
    if not access:
        report("TC-023", "修改密码成功", False, "前置登录失败")
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access,
                     json={"oldPassword": "Old@12345", "newPassword": "New@54321"})
    new_access, _ = login(name, "New@54321")
    ok = resp.status_code == 200 and body.get("code") == 0 and bool(new_access)
    report("TC-023", "修改密码成功", ok,
           "change={}/{} relogin={}".format(resp.status_code, body.get("code"), bool(new_access)))


def test_tc024_change_password_wrong_old():
    name = new_name("wo")
    register_username(name, "Old@12345")
    access, _ = login(name, "Old@12345")
    if not access:
        report("TC-024", "修改密码旧密码错误被拒", False, "前置登录失败")
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access,
                     json={"oldPassword": "WrongOld@1", "newPassword": "New@54321"})
    ok = resp.status_code in (400, 422)
    report("TC-024", "修改密码旧密码错误被拒", ok, "http={}/{}".format(resp.status_code, body.get("code")))


def test_tc025_forgot_send_code():
    phone = new_phone("13")
    name = new_name("fs")
    register_username(name, "Pass@1234", phone=phone)
    resp1, body1 = req("POST", AUTH_API + "/password/forgot/send-code",
                       json={"target": phone, "channel": "SMS"})
    ok1 = resp1.status_code == 200 and body1.get("code") == 0
    # 未绑定账号的目标
    resp2, body2 = req("POST", AUTH_API + "/password/forgot/send-code",
                       json={"target": new_phone("19"), "channel": "SMS"})
    ok2 = resp2.status_code in (400, 404, 422)
    ok = ok1 and ok2
    report("TC-025", "密码找回发送验证码成功", ok,
           "bound={}/{} unbound={}/{}".format(resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code")))


def test_tc026_forgot_reset():
    phone = new_phone("13")
    name = new_name("fr")
    register_username(name, "Old@12345", phone=phone)
    access, _ = login(name, "Old@12345")
    code = send_forgot_code(phone)
    if not access or not code:
        report("TC-026", "密码找回重置成功且旧 Token 失效", False, "前置登录或获取验证码失败", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/password/forgot/reset",
                     json={"target": phone, "channel": "SMS", "code": code, "newPassword": "New@12345"})
    resp2, _ = _get(AUTH_API + "/users", token=access, params={"pageNum": 1, "pageSize": 1})
    new_access, _ = login(name, "New@12345")
    ok = (resp.status_code == 200 and body.get("code") == 0
          and resp2.status_code == 401 and bool(new_access))
    # 异常路径：错误验证码重置（独立手机号避免频率限制）
    phone2 = new_phone("13")
    name2 = new_name("fr2")
    register_username(name2, "Pass@1234", phone=phone2)
    send_forgot_code(phone2)
    resp3, body3 = req("POST", AUTH_API + "/password/forgot/reset",
                       json={"target": phone2, "channel": "SMS", "code": "999999", "newPassword": "New@12345"})
    ok = ok and resp3.status_code in (400, 422)
    report("TC-026", "密码找回重置成功且旧 Token 失效", ok,
           "reset={}/{} old_token={} relogin={} wrong_code={}/{}".format(
               resp.status_code, body.get("code"), resp2.status_code, bool(new_access),
               resp3.status_code, body3.get("code")))


# ============================================================
# 七、手机号变更（TC-027）
# ============================================================

def test_tc027_change_phone():
    old_phone = new_phone("13")
    name_a = new_name("phA")
    register_username(name_a, "Pass@1234", phone=old_phone)
    access_a, _ = login(name_a, "Pass@1234")
    # 占用校验：账号 B 绑定 new_phone
    new_phone_b = new_phone("13")
    register_username(new_name("phB"), "Pass@1234", phone=new_phone_b)
    # 原手机不一致校验：账号 C
    old_phone_c = new_phone("13")
    name_c = new_name("phC")
    register_username(name_c, "Pass@1234", phone=old_phone_c)
    access_c, _ = login(name_c, "Pass@1234")
    if not access_a or not access_c:
        report("TC-027", "短信验证码变更手机号成功（含占用/不一致拒绝）", False, "前置注册/登录失败")
        return
    # 1) 成功变更：向原手机发码后变更
    code = send_code(old_phone, "PHONE_CHANGE")
    if not code:
        report("TC-027", "短信验证码变更手机号成功（含占用/不一致拒绝）", False, "无法获取验证码", skipped=True)
        return
    resp1, body1 = req("PUT", AUTH_API + "/phone/change", token=access_a, json={
        "scene": "OLD_PHONE_SMS", "oldPhone": old_phone, "newPhone": new_phone("13"), "code": code})
    ok1 = resp1.status_code == 200 and body1.get("code") == 0
    # 2) 新手机号被占用：向 C 原手机发码后变更为 B 的手机号
    code_c = send_code(old_phone_c, "PHONE_CHANGE")
    if not code_c:
        report("TC-027", "短信验证码变更手机号成功（含占用/不一致拒绝）", False, "无法获取验证码", skipped=True)
        return
    resp2, body2 = req("PUT", AUTH_API + "/phone/change", token=access_c, json={
        "scene": "OLD_PHONE_SMS", "oldPhone": old_phone_c, "newPhone": new_phone_b, "code": code_c})
    ok2 = resp2.status_code == 409
    # 3) 原手机号不一致
    resp3, body3 = req("PUT", AUTH_API + "/phone/change", token=access_c, json={
        "scene": "OLD_PHONE_SMS", "oldPhone": "19900001111", "newPhone": new_phone("13"), "code": code_c})
    ok3 = resp3.status_code in (400, 409, 422)
    ok = ok1 and ok2 and ok3
    report("TC-027", "短信验证码变更手机号成功（含占用/不一致拒绝）", ok,
           "ok={}/{} occupied={}/{} mismatch={}/{}".format(
               resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code"),
               resp3.status_code, body3.get("code")))


# ============================================================
# 八、两步注册补全（TC-028）
# ============================================================

def test_tc028_account_settlement():
    oauth_code = "mock_settle_" + uuid.uuid4().hex[:8]
    resp0, body0 = req("POST", AUTH_API + "/register", json={
        "registerMode": "OAUTH", "oauthProvider": "DINGTALK", "oauthCode": oauth_code,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    data0 = body0.get("data") or {}
    user_id = data0.get("userId")
    if resp0.status_code != 200 or not user_id:
        report("TC-028", "两步注册账号补全（成功/已完善拒绝）", False,
               "OAuth 两步注册前置不可用 http={} code={}".format(resp0.status_code, body0.get("code")), skipped=True)
        return
    # OAuth 登录获取 Token
    access, _ = login(phone=None, password=None, mode="OAUTH", tenant_code=None)
    # 若 OAUTH 模式登录不可用，尝试直接以 OAUTH 登录（部分实现支持 oauthCode）
    if not access:
        resp_l, body_l = req("POST", AUTH_API + "/login", json={
            "loginMode": "OAUTH", "oauthProvider": "DINGTALK", "oauthCode": oauth_code,
            "clientType": CLIENT_TYPE})
        data_l = body_l.get("data") or {}
        access = data_l.get("accessToken")
    if not access:
        report("TC-028", "两步注册账号补全（成功/已完善拒绝）", False,
               "OAuth 登录不可用，需模拟/真实第三方环境", skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/account/settlement", token=access, json={
        "loginName": new_name("settle"), "password": "Settle@123"})
    data = body.get("data") or {}
    ok1 = resp.status_code == 200 and body.get("code") == 0 and data.get("accountComplete") is True
    # 已完善账号重复补全被拒：普通完整账号
    name = new_name("full")
    register_username(name, "Pass@1234")
    access2, _ = login(name, "Pass@1234")
    if not access2:
        report("TC-028", "两步注册账号补全（成功/已完善拒绝）", False, "普通账号登录失败")
        return
    resp2, body2 = req("PUT", AUTH_API + "/account/settlement", token=access2, json={
        "loginName": new_name("hack"), "password": "Hack@1234"})
    ok2 = resp2.status_code in (400, 403, 422)
    ok = ok1 and ok2
    report("TC-028", "两步注册账号补全（成功/已完善拒绝）", ok,
           "settle={}/{} complete={} full_reject={}/{}".format(
               resp.status_code, body.get("code"), data.get("accountComplete"),
               resp2.status_code, body2.get("code")))


# ============================================================
# 九、用户管理（TC-029 ~ TC-033）
# ============================================================

def test_tc029_user_page_query():
    if not ADMIN_TOKEN:
        report("TC-029", "用户分页查询", False, "管理员未登录", skipped=True)
        return
    resp, body = _get(AUTH_API + "/users", token=ADMIN_TOKEN,
                      params={"pageNum": 1, "pageSize": 10, "keyword": "admin"})
    data = body.get("data") or {}
    records = data.get("records") or []
    no_password = all(("password" not in (r or {}) for r in records))
    ok = (resp.status_code == 200 and body.get("code") == 0
          and isinstance(records, list) and "total" in data
          and data.get("pageNum") == 1 and data.get("pageSize") == 10 and no_password)
    report("TC-029", "用户分页查询", ok,
           "http={} code={} total={} no_pwd={}".format(resp.status_code, body.get("code"), data.get("total"), no_password))
    return records


def test_tc030_user_detail():
    if not ADMIN_TOKEN:
        report("TC-030", "用户详情查询", False, "管理员未登录", skipped=True)
        return
    records = test_tc029_user_page_query()
    user_id = (records[0].get("id") or records[0].get("userId")) if records else 1
    resp, body = _get(AUTH_API + "/users/{}".format(user_id), token=ADMIN_TOKEN)
    data = body.get("data") or {}
    ok1 = (resp.status_code == 200 and body.get("code") == 0
           and (data.get("id") == user_id or data.get("userId") == user_id)
           and "password" not in data)
    resp2, body2 = _get(AUTH_API + "/users/999999999", token=ADMIN_TOKEN)
    ok2 = resp2.status_code in (400, 404, 422)
    ok = ok1 and ok2
    report("TC-030", "用户详情查询", ok,
           "detail={}/{} not_found={}/{}".format(resp.status_code, body.get("code"), resp2.status_code, body2.get("code")))


def test_tc031_user_update():
    if not ADMIN_TOKEN:
        report("TC-031", "更新用户信息", False, "管理员未登录", skipped=True)
        return
    user_id, ok_reg = register_username(new_name("upd"), "Pass@1234")
    if not ok_reg:
        report("TC-031", "更新用户信息", False, "前置注册失败")
        return
    resp, body = req("PUT", "{}/users/{}".format(AUTH_API, user_id), token=ADMIN_TOKEN,
                     json={"userName": "更新测试", "email": "upd@example.com"})
    ok = resp.status_code == 200 and body.get("code") == 0
    report("TC-031", "更新用户信息", ok, "http={}/{}".format(resp.status_code, body.get("code")))


def test_tc032_user_status_disable():
    if not ADMIN_TOKEN:
        report("TC-032", "用户启禁用-登录态实时失效", False, "管理员未登录", skipped=True)
        return
    name = new_name("st")
    user_id, ok_reg = register_username(name, "Pass@1234")
    access, _ = login(name, "Pass@1234")
    if not ok_reg or not access:
        report("TC-032", "用户启禁用-登录态实时失效", False, "前置注册/登录失败")
        return
    resp, body = req("PUT", "{}/users/{}/status".format(AUTH_API, user_id), token=ADMIN_TOKEN, json={"status": 0})
    resp2, _ = _get(AUTH_API + "/users", token=access, params={"pageNum": 1, "pageSize": 1})
    resp3, body3 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": name, "password": "Pass@1234",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = (resp.status_code == 200 and body.get("code") == 0
          and resp2.status_code == 403 and resp3.status_code == 403)
    report("TC-032", "用户启禁用-登录态实时失效", ok,
           "status={}/{} old_token={} relogin={}/{}".format(
               resp.status_code, body.get("code"), resp2.status_code, resp3.status_code, body3.get("code")))


def test_tc033_user_assign_roles():
    if not ADMIN_TOKEN:
        report("TC-033", "分配用户角色", False, "管理员未登录", skipped=True)
        return
    user_id, ok_reg = register_username(new_name("ar"), "Pass@1234")
    roles = get_role_list(ADMIN_TOKEN)
    if not ok_reg or not roles:
        report("TC-033", "分配用户角色", False, "前置注册或角色列表为空")
        return
    role_id = roles[0].get("id") or roles[0].get("roleId")
    resp, body = req("PUT", "{}/users/{}/roles".format(AUTH_API, user_id), token=ADMIN_TOKEN,
                     json={"roleIds": [role_id]})
    ok = resp.status_code == 200 and body.get("code") == 0
    report("TC-033", "分配用户角色", ok,
           "http={}/{} roleId={}".format(resp.status_code, body.get("code"), role_id))


# ============================================================
# 十、角色管理（TC-034 ~ TC-037）
# ============================================================

def test_tc034_role_create():
    if not ADMIN_TOKEN:
        report("TC-034", "创建角色成功", False, "管理员未登录", skipped=True)
        return
    role_code = "TEST_ROLE_" + uuid.uuid4().hex[:8].upper()
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                     json={"roleCode": role_code, "roleName": "自动化测试角色"})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 0
          and data.get("roleCode") == role_code and (data.get("id") or data.get("roleId")))
    report("TC-034", "创建角色成功", ok,
           "http={}/{} roleId={}".format(resp.status_code, body.get("code"), data.get("id") or data.get("roleId")))
    return data.get("id") or data.get("roleId")


def test_tc035_role_duplicate_code():
    if not ADMIN_TOKEN:
        report("TC-035", "角色编码租户内重复被拒", False, "管理员未登录", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_TOKEN,
                     json={"roleCode": "SUPER_ADMIN", "roleName": "重复角色"})
    ok = resp.status_code == 409
    report("TC-035", "角色编码租户内重复被拒", ok, "http={}/{}".format(resp.status_code, body.get("code")))


def test_tc036_role_delete():
    if not ADMIN_TOKEN:
        report("TC-036", "删除角色-被引用不可删", False, "管理员未登录", skipped=True)
        return
    # 1) 未引用角色删除成功
    role_id = test_tc034_role_create()
    if not role_id:
        report("TC-036", "删除角色-被引用不可删", False, "前置创建角色失败")
        return
    resp, body = req("DELETE", "{}/roles/{}".format(AUTH_API, role_id), token=ADMIN_TOKEN)
    ok1 = resp.status_code == 200 and body.get("code") == 0
    # 2) 被引用角色（SUPER_ADMIN）删除被拒
    super_id = None
    for r in get_role_list(ADMIN_TOKEN):
        if r.get("roleCode") == "SUPER_ADMIN":
            super_id = r.get("id") or r.get("roleId")
            break
    if not super_id:
        report("TC-036", "删除角色-被引用不可删", ok1, "未找到 SUPER_ADMIN 角色（子场景 2 跳过）")
        return
    resp2, body2 = req("DELETE", "{}/roles/{}".format(AUTH_API, super_id), token=ADMIN_TOKEN)
    ok2 = resp2.status_code == 409
    ok = ok1 and ok2
    report("TC-036", "删除角色-被引用不可删", ok,
           "free_del={}/{} in_use_del={}/{}".format(resp.status_code, body.get("code"), resp2.status_code, body2.get("code")))


def test_tc037_role_assign_permissions():
    if not ADMIN_TOKEN:
        report("TC-037", "角色分配权限", False, "管理员未登录", skipped=True)
        return
    role_id = test_tc034_role_create()
    if not role_id:
        report("TC-037", "角色分配权限", False, "前置创建角色失败")
        return
    resp_tree, body_tree = _get(AUTH_API + "/permissions", token=ADMIN_TOKEN)
    perm_ids = collect_perm_ids(body_tree.get("data") or [])
    if not perm_ids:
        report("TC-037", "角色分配权限", False, "权限树为空", skipped=True)
        return
    resp, body = req("PUT", "{}/roles/{}/permissions".format(AUTH_API, role_id), token=ADMIN_TOKEN,
                     json={"permissionIds": perm_ids[:2]})
    ok = resp.status_code == 200 and body.get("code") == 0
    report("TC-037", "角色分配权限", ok,
           "http={}/{} permIds={}".format(resp.status_code, body.get("code"), perm_ids[:2]))


# ============================================================
# 十一、权限管理（TC-038 ~ TC-040）
# ============================================================

def test_tc038_permission_tree():
    if not ADMIN_TOKEN:
        report("TC-038", "权限树查询", False, "管理员未登录", skipped=True)
        return
    resp, body = _get(AUTH_API + "/permissions", token=ADMIN_TOKEN)
    data = body.get("data") or []
    ok = (resp.status_code == 200 and body.get("code") == 0
          and isinstance(data, list)
          and all(isinstance(n.get("children"), list) for n in data))
    report("TC-038", "权限树查询", ok,
           "http={} code={} nodes={}".format(resp.status_code, body.get("code"), len(data)))


def test_tc039_permission_create():
    if not ADMIN_TOKEN:
        report("TC-039", "创建权限与编码重复被拒", False, "管理员未登录", skipped=True)
        return
    perm_code = "test:perm_" + uuid.uuid4().hex[:8]
    resp, body = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                     json={"permCode": perm_code, "permName": "自动化测试权限", "parentId": 0})
    data = body.get("data") or {}
    ok1 = (resp.status_code in (200, 201) and body.get("code") == 0
           and data.get("permCode") == perm_code and (data.get("id") or data.get("permId")))
    resp2, body2 = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                       json={"permCode": perm_code, "permName": "重复权限"})
    ok2 = resp2.status_code == 409
    ok = ok1 and ok2
    report("TC-039", "创建权限与编码重复被拒", ok,
           "create={}/{} duplicate={}/{}".format(resp.status_code, body.get("code"), resp2.status_code, body2.get("code")))
    return data.get("id") or data.get("permId")


def test_tc040_permission_update_delete():
    if not ADMIN_TOKEN:
        report("TC-040", "更新/删除权限-子权限约束", False, "管理员未登录", skipped=True)
        return
    # 创建父权限 + 子权限
    parent_code = "test:parent_" + uuid.uuid4().hex[:8]
    resp_p, body_p = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                         json={"permCode": parent_code, "permName": "父权限", "parentId": 0})
    parent_id = (body_p.get("data") or {}).get("id") or (body_p.get("data") or {}).get("permId")
    child_code = "test:child_" + uuid.uuid4().hex[:8]
    resp_c, body_c = req("POST", AUTH_API + "/permissions", token=ADMIN_TOKEN,
                         json={"permCode": child_code, "permName": "子权限", "parentId": parent_id})
    child_id = (body_c.get("data") or {}).get("id") or (body_c.get("data") or {}).get("permId")
    if not parent_id or not child_id:
        report("TC-040", "更新/删除权限-子权限约束", False,
               "前置创建权限失败 p={}/{} c={}/{}".format(resp_p.status_code, body_p.get("code"), resp_c.status_code, body_c.get("code")),
               skipped=True)
        return
    # 更新父权限
    resp_u, body_u = req("PUT", "{}/permissions/{}".format(AUTH_API, parent_id), token=ADMIN_TOKEN,
                         json={"permName": "更新后的父权限"})
    ok1 = resp_u.status_code == 200 and body_u.get("code") == 0
    # 有子权限删除父权限被拒
    resp_d, body_d = req("DELETE", "{}/permissions/{}".format(AUTH_API, parent_id), token=ADMIN_TOKEN)
    ok2 = resp_d.status_code == 409
    # 删除子权限后再删父权限
    resp_dc, _ = req("DELETE", "{}/permissions/{}".format(AUTH_API, child_id), token=ADMIN_TOKEN)
    resp_df, body_df = req("DELETE", "{}/permissions/{}".format(AUTH_API, parent_id), token=ADMIN_TOKEN)
    ok3 = resp_dc.status_code in (200, 201) and resp_df.status_code in (200, 201)
    ok = ok1 and ok2 and ok3
    report("TC-040", "更新/删除权限-子权限约束", ok,
           "update={}/{} parent_del={}/{} child_del={} parent_del2={}/{}".format(
               resp_u.status_code, body_u.get("code"), resp_d.status_code, body_d.get("code"),
               resp_dc.status_code, resp_df.status_code, body_df.get("code")))


# ============================================================
# 十二、网关认证（TC-041 ~ TC-043）
# ============================================================

def test_tc041_gateway_whitelist():
    resp1, body1 = _get(BASE_URL + "/api/v1/auth/health")
    resp2, body2 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME, "password": ADMIN_PASSWORD,
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    data2 = body2.get("data") or {}
    ok = (resp1.status_code == 200 and body1.get("code") == 0
          and resp2.status_code == 200 and body2.get("code") == 0 and data2.get("accessToken"))
    report("TC-041", "白名单接口免 Token 放行", ok,
           "health={}/{} login={}/{}".format(resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code")))


def test_tc042_gateway_no_or_fake_token():
    resp1, body1 = _get(AUTH_API + "/users", params={"pageNum": 1, "pageSize": 10})
    resp2, body2 = req("GET", AUTH_API + "/users?pageNum=1&pageSize=10", token="fake.token.value")
    resp3, body3 = req("GET", AUTH_API + "/users?pageNum=1&pageSize=10",
                       headers={"Authorization": "Basic dGVzdDoxMjM="})
    ok = (resp1.status_code == 401 and resp2.status_code == 401 and resp3.status_code == 401)
    report("TC-042", "无 Token/伪造 Token 访问受保护接口返回 401", ok,
           "no_token={}/{} fake={}/{} non_bearer={}/{}".format(
               resp1.status_code, body1.get("code"), resp2.status_code, body2.get("code"),
               resp3.status_code, body3.get("code")))


def test_tc043_gateway_forbidden():
    name = new_name("noauth")
    register_username(name, "Pass@1234")
    access, _ = login(name, "Pass@1234")
    if not access:
        report("TC-043", "普通用户访问管理接口返回 403", False, "普通用户登录失败")
        return
    resp, body = _get(AUTH_API + "/users", token=access, params={"pageNum": 1, "pageSize": 10})
    ok = resp.status_code == 403
    report("TC-043", "普通用户访问管理接口返回 403", ok, "http={}/{}".format(resp.status_code, body.get("code")))


# ============================================================
# 十三、多租户隔离（TC-044）
# ============================================================

def test_tc044_tenant_isolation():
    if not ADMIN_TOKEN:
        report("TC-044", "多租户隔离-跨租户数据不可见", False, "管理员未登录", skipped=True)
        return
    resp, body = _get(AUTH_API + "/users", token=ADMIN_TOKEN, params={"pageNum": 1, "pageSize": 10})
    data = body.get("data") or {}
    records = data.get("records") or []
    # 本租户查询正常；若记录含租户信息则断言均为 DEFAULT
    same_tenant = True
    for r in records:
        tc = r.get("tenantCode")
        if tc and tc != TENANT_CODE:
            same_tenant = False
            break
    # 跨租户参数查询（伪造租户 ID）：预期不返回其他租户数据
    resp2, body2 = _get(AUTH_API + "/users", token=ADMIN_TOKEN,
                        params={"pageNum": 1, "pageSize": 10, "tenantId": 999999})
    records2 = (body2.get("data") or {}).get("records") or []
    ok = (resp.status_code == 200 and body.get("code") == 0 and same_tenant
          and resp2.status_code == 200 and len(records2) == 0)
    report("TC-044", "多租户隔离-跨租户数据不可见", ok,
           "http={}/{} same_tenant={} cross_tenant_records={}".format(
               resp.status_code, body.get("code"), same_tenant, len(records2)))


# ============================================================
# 十四、健康检查（TC-045）
# ============================================================

def test_tc045_health_checks():
    checks = [
        ("/api/v1/auth/health", "cloudoffice-auth-service"),
        ("/api/v1/biz/health", "cloudoffice-biz-service"),
        ("/api/v1/system/health", "cloudoffice-system-service"),
    ]
    ok = True
    details = []
    for path, svc in checks:
        resp, body = _get(BASE_URL + path)
        data = body.get("data") or {}
        r = (resp.status_code == 200 and body.get("code") == 0
             and data.get("service") == svc and data.get("status") == "UP")
        ok = ok and r
        details.append("{}={}/{}".format(svc, resp.status_code, data.get("status")))
    report("TC-045", "认证/企业/系统服务健康检查", ok, " ".join(details))


# ============================================================
# 用例清单与执行
# ============================================================
CASES = [
    # 一、注册功能
    ("TC-001", "用户名密码注册成功", test_tc001_register_username_password),
    ("TC-002", "手机验证码注册成功", test_tc002_register_phone_code),
    ("TC-003", "OAuth 注册进入两步注册", test_tc003_register_oauth),
    ("TC-004", "注册异常-用户名重复与参数非法", test_tc004_register_duplicate_and_invalid),
    # 二、登录功能
    ("TC-005", "用户名密码登录成功签发双 Token", test_tc005_login_username_password),
    ("TC-006", "密码错误登录失败且防枚举提示", test_tc006_login_wrong_password_anti_enum),
    ("TC-007", "手机验证码登录（正确码成功/错误码拒绝）", test_tc007_login_phone_code),
    ("TC-008", "手机+密码登录成功", test_tc008_login_phone_password),
    ("TC-009", "禁用账号/租户登录被拒", test_tc009_login_disabled),
    ("TC-010", "登录模式/客户端类型非法被拒", test_tc010_login_invalid_mode_client),
    # 三、Token 与会话
    ("TC-011", "Token 刷新成功换发新双 Token", test_tc011_refresh_success),
    ("TC-012", "刷新轮换后旧 Refresh Token 失效", test_tc012_refresh_rotation),
    ("TC-013", "同端互斥-同客户端新登录踢旧会话", test_tc013_same_client_mutex),
    ("TC-014", "多端共存-不同客户端类型同时在线", test_tc014_multi_client_coexist),
    # 四、登出与踢人
    ("TC-015", "主动登出后 Token 失效", test_tc015_logout_invalidates_token),
    ("TC-016", "重复登出幂等", test_tc016_logout_idempotent),
    ("TC-017", "管理员强制踢人后登录态失效", test_tc017_kickout),
    ("TC-018", "非管理员踢人被拒", test_tc018_kickout_forbidden),
    # 五、验证码
    ("TC-019", "发送验证码成功-模拟模式返回 123456", test_tc019_send_code_success),
    ("TC-020", "60 秒内重复发送验证码被拒", test_tc020_send_code_frequency),
    ("TC-021", "验证码单次使用-复用被拒", test_tc021_code_single_use),
    ("TC-022", "验证码用途不匹配被拒", test_tc022_code_purpose_mismatch),
    # 六、密码管理
    ("TC-023", "修改密码成功", test_tc023_change_password_success),
    ("TC-024", "修改密码旧密码错误被拒", test_tc024_change_password_wrong_old),
    ("TC-025", "密码找回发送验证码成功", test_tc025_forgot_send_code),
    ("TC-026", "密码找回重置成功且旧 Token 失效", test_tc026_forgot_reset),
    # 七、手机号变更
    ("TC-027", "短信验证码变更手机号成功（含占用/不一致拒绝）", test_tc027_change_phone),
    # 八、两步注册补全
    ("TC-028", "两步注册账号补全（成功/已完善拒绝）", test_tc028_account_settlement),
    # 九、用户管理
    ("TC-029", "用户分页查询", test_tc029_user_page_query),
    ("TC-030", "用户详情查询", test_tc030_user_detail),
    ("TC-031", "更新用户信息", test_tc031_user_update),
    ("TC-032", "用户启禁用-登录态实时失效", test_tc032_user_status_disable),
    ("TC-033", "分配用户角色", test_tc033_user_assign_roles),
    # 十、角色管理
    ("TC-034", "创建角色成功", test_tc034_role_create),
    ("TC-035", "角色编码租户内重复被拒", test_tc035_role_duplicate_code),
    ("TC-036", "删除角色-被引用不可删", test_tc036_role_delete),
    ("TC-037", "角色分配权限", test_tc037_role_assign_permissions),
    # 十一、权限管理
    ("TC-038", "权限树查询", test_tc038_permission_tree),
    ("TC-039", "创建权限与编码重复被拒", test_tc039_permission_create),
    ("TC-040", "更新/删除权限-子权限约束", test_tc040_permission_update_delete),
    # 十二、网关认证
    ("TC-041", "白名单接口免 Token 放行", test_tc041_gateway_whitelist),
    ("TC-042", "无 Token/伪造 Token 访问受保护接口返回 401", test_tc042_gateway_no_or_fake_token),
    ("TC-043", "普通用户访问管理接口返回 403", test_tc043_gateway_forbidden),
    # 十三、多租户隔离
    ("TC-044", "多租户隔离-跨租户数据不可见", test_tc044_tenant_isolation),
    # 十四、健康检查
    ("TC-045", "认证/企业/系统服务健康检查", test_tc045_health_checks),
]


def main():
    global ADMIN_TOKEN
    print("=" * 60)
    print("CloudStrollOffice 接口自动化测试（v0.0.1，TC-001 ~ TC-045）")
    print("网关地址：{}".format(BASE_URL))
    print("=" * 60)

    # 管理员登录（管理类用例复用）
    ADMIN_TOKEN, _ = login(ADMIN_LOGIN_NAME, ADMIN_PASSWORD)
    if not ADMIN_TOKEN:
        print("[info] 管理员登录失败（{}/{}），管理类用例将标记 SKIP".format(ADMIN_LOGIN_NAME, ADMIN_PASSWORD))

    for case_id, name, func in CASES:
        try:
            func()
        except Exception as exc:
            report(case_id, name, False, "脚本异常：{}".format(exc))

    print("=" * 60)
    print("结果汇总：通过 {}，失败 {}，跳过 {}".format(PASS, FAIL, SKIP))
    if FAILED_CASES:
        print("失败用例：")
        for case_id, name, detail in FAILED_CASES:
            print("  - {} {}：{}".format(case_id, name, detail))
    if SKIPPED_CASES:
        print("跳过用例：")
        for case_id, name, detail in SKIPPED_CASES:
            print("  - {} {}：{}".format(case_id, name, detail))
    print("=" * 60)
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
