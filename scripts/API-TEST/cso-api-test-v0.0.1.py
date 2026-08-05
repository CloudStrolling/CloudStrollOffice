# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）接口自动化测试脚本 v0.0.1
=========================================================
覆盖：docs/cso-v0.0.1/cso-testcase-v0.0.1.md 中 TC-API-001 ~ TC-API-057 全部接口测试用例
接口基准：docs/cso-api.md（统一前缀 /api/v1/{module}，统一响应 ApiResult<T>，成功 code=200）

依赖：requests（pip install requests）
用法：
    python cso-api-test-v0.0.1.py                    # 默认 http://localhost:9000
    python cso-api-test-v0.0.1.py http://10.0.0.8:9000   # 指定网关地址

说明：
    1. 需网关(9000)、认证服务(9100) 及数据库/Redis 已启动；企业服务(9200)/系统服务(9400) 仅健康检查用例需要。
    2. 验证码为开发环境模拟发送模式（VERIFICATION_CODE_MOCK=true）：
       - 若发送接口响应 data 中含验证码则自动读取闭环；
       - 否则打印提示人工查看服务端控制台日志，对应用例标记 SKIP（不视为失败）。
    3. 脚本为每个用例创建独立测试数据（uuid 命名），用例间互不污染；
       admin/admin123 为项目初始测试账号（首次登录后应修改），仅作测试用途。
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
TENANT_CODE = "default"
TENANT_ID = 1
CLIENT_TYPE = "WINDOWS"

PASS = 0
FAIL = 0
SKIP = 0
FAILED_CASES = []
SKIPPED_CASES = []


def report(case_id, name, ok, detail="", skipped=False):
    """输出用例执行结果并汇总（skipped=True 时不计入通过/失败）"""
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


def send_code(target, purpose, mode):
    """
    发送验证码并尝试获取验证码内容。
    模拟模式下若响应 data 含 code 则返回；否则返回 None（提示人工查看服务端控制台）。
    """
    resp, body = req("POST", AUTH_API + "/verification-code/send",
                     json={"target": target, "purpose": purpose, "mode": mode})
    data = body.get("data") or {}
    code = data.get("code") if isinstance(data, dict) else None
    if code:
        return str(code)
    print("  [info] 请在服务端控制台查看发送到 {}（{}）的验证码".format(target, purpose))
    return None


def login_user(login_name, password, client_type=CLIENT_TYPE):
    """登录并返回 (accessToken, refreshToken)；失败返回 (None, None)"""
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": login_name, "password": password,
        "tenantCode": TENANT_CODE, "clientType": client_type})
    if resp.status_code == 200 and body.get("code") == 200:
        data = body.get("data") or {}
        return data.get("accessToken"), data.get("refreshToken")
    return None, None


def register_user(login_name, password, phone=None, user_name=None):
    """注册 USERNAME 模式用户，返回 (userId, accessToken, refreshToken)"""
    payload = {"registerMode": "USERNAME", "loginName": login_name,
               "password": password, "tenantCode": TENANT_CODE}
    if user_name:
        payload["userName"] = user_name
    if phone:
        payload["phone"] = phone
    resp, body = req("POST", AUTH_API + "/register", json=payload)
    if resp.status_code == 200 and body.get("code") == 200:
        data = body.get("data") or {}
        tp = data.get("tokenPair") or {}
        return data.get("userId"), tp.get("accessToken"), tp.get("refreshToken")
    return None, None, None


# ============================================================
# 管理员登录（供后续 RBAC 用例复用；在 main 中先执行并缓存）
# ============================================================
ADMIN_ACCESS_TOKEN = None
ADMIN_REFRESH_TOKEN = None


# ============================================================
# 一、认证管理接口（API-001 ~ API-011）
# ============================================================

def test_login_success():  # TC-API-001
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME,
        "password": ADMIN_PASSWORD, "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("accessToken") and data.get("refreshToken")
          and data.get("tokenType") == "Bearer"
          and data.get("accessTokenExpireIn") == 7200
          and data.get("refreshTokenExpireIn") == 604800)
    report("TC-API-001", "用户名密码登录成功", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))
    return data.get("accessToken"), data.get("refreshToken")


def test_login_wrong_password():  # TC-API-002
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME,
        "password": "wrongpass", "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = resp.status_code == 401 and body.get("code") == "AUTH-0010"
    report("TC-API-002", "登录密码错误返回 AUTH-0010", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_login_invalid_client_type():  # TC-API-003
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": ADMIN_LOGIN_NAME,
        "password": ADMIN_PASSWORD, "tenantCode": TENANT_CODE, "clientType": "TV"})
    ok = resp.status_code == 400 and str(body.get("code")) in ("AUTH-0012", 400)
    report("TC-API-003", "登录客户端类型非法返回 AUTH-0012/400", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_login_invalid_mode():  # TC-API-004
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "UNKNOWN_MODE", "loginName": ADMIN_LOGIN_NAME,
        "password": ADMIN_PASSWORD, "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = resp.status_code == 400 and str(body.get("code")) in ("AUTH-0033", 400)
    report("TC-API-004", "登录模式非法返回 AUTH-0033/400", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_login_banned_account():  # TC-API-005
    # 先注册一个账号，用管理员封禁（status=3），再尝试登录
    name = new_name("banned")
    user_id, _, _ = register_user(name, "Ban@12345")
    if not user_id:
        report("TC-API-005", "封禁账号登录返回 AUTH-0008", False, "前置注册失败")
        return
    resp, _ = req("PUT", "{}/users/{}/status".format(AUTH_API, user_id),
                  token=ADMIN_ACCESS_TOKEN, json={"status": 3, "lockReason": "测试封禁"})
    if resp.status_code != 200:
        report("TC-API-005", "封禁账号登录返回 AUTH-0008", False, "封禁接口失败 http={}".format(resp.status_code))
        return
    resp, body = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": name, "password": "Ban@12345",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = resp.status_code == 403 and str(body.get("code")) == "AUTH-0008"
    report("TC-API-005", "封禁账号登录返回 AUTH-0008", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_register_success():  # TC-API-006
    name = new_name("user")
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME", "loginName": name, "password": "Pass@1234",
        "userName": "测试用户", "tenantCode": TENANT_CODE})
    data = body.get("data") or {}
    tp = data.get("tokenPair") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("loginName") == name
          and data.get("accountSettled") is True
          and tp.get("accessToken") and tp.get("refreshToken"))
    report("TC-API-006", "USERNAME 模式注册成功", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_register_duplicate_login_name():  # TC-API-007
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME", "loginName": ADMIN_LOGIN_NAME,
        "password": "Pass@1234", "tenantCode": TENANT_CODE})
    ok = resp.status_code == 409
    report("TC-API-007", "注册登录名重复返回 409", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_register_invalid_params():  # TC-API-008
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "USERNAME", "loginName": "ab",
        "password": "123", "tenantCode": TENANT_CODE})
    ok = resp.status_code == 400
    report("TC-API-008", "注册参数非法返回 400", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_refresh_success():  # TC-API-009
    _, _, refresh_token = register_user(new_name("rf"), "Pass@1234")
    if not refresh_token:
        report("TC-API-009", "Refresh Token 换发新双 Token", False, "前置注册失败")
        return
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("accessToken") and data.get("refreshToken"))
    report("TC-API-009", "Refresh Token 换发新双 Token", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))
    return data.get("refreshToken")  # 供重放用例使用


def test_refresh_invalid_token():  # TC-API-010
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": "invalid.token.value"})
    ok = resp.status_code == 401 and str(body.get("code")) == "AUTH-0005"
    report("TC-API-010", "无效 Refresh Token 返回 AUTH-0005", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_refresh_replay_rejected():  # TC-API-011
    _, _, refresh_token = register_user(new_name("rp"), "Pass@1234")
    if not refresh_token:
        report("TC-API-011", "旧 Refresh Token 重放返回 AUTH-0003", False, "前置注册失败")
        return
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    if resp.status_code != 200 or body.get("code") != 200:
        report("TC-API-011", "旧 Refresh Token 重放返回 AUTH-0003", False, "首次刷新失败 http={}".format(resp.status_code))
        return
    resp, body = req("POST", AUTH_API + "/refresh", json={"refreshToken": refresh_token})
    ok = resp.status_code == 401 and str(body.get("code")) == "AUTH-0003"
    report("TC-API-011", "旧 Refresh Token 重放返回 AUTH-0003", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_logout_success_and_idempotent():  # TC-API-012
    _, access_token, _ = register_user(new_name("out"), "Pass@1234")
    if not access_token:
        report("TC-API-012", "登出成功且重复登出幂等", False, "前置注册失败")
        return
    resp, body = req("POST", AUTH_API + "/logout", token=access_token)
    ok = resp.status_code == 200 and body.get("code") == 200 and body.get("message") == "登出成功"
    resp2, body2 = req("POST", AUTH_API + "/logout", token=access_token)
    ok = ok and resp2.status_code == 200 and body2.get("code") == 200
    report("TC-API-012", "登出成功且重复登出幂等", ok,
           "http1={} code1={} http2={} code2={}".format(resp.status_code, body.get("code"), resp2.status_code, body2.get("code")))


def test_logout_token_invalidated():  # TC-API-013
    _, access_token, _ = register_user(new_name("inv"), "Pass@1234")
    if not access_token:
        report("TC-API-013", "登出后原 Token 访问返回 401", False, "前置注册失败")
        return
    req("POST", AUTH_API + "/logout", token=access_token)
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=10", token=access_token,
                     headers={"X-Tenant-Id": str(TENANT_ID)})
    ok = resp.status_code == 401
    report("TC-API-013", "登出后原 Token 访问返回 401", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_kickout_success():  # TC-API-014
    user_id, access_token, _ = register_user(new_name("kick"), "Pass@1234")
    if not user_id or not access_token or not ADMIN_ACCESS_TOKEN:
        report("TC-API-014", "管理员强制指定用户下线", False, "前置注册/登录失败")
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=ADMIN_ACCESS_TOKEN,
                     json={"userId": user_id, "clientType": CLIENT_TYPE})
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, _ = req("GET", AUTH_API + "/users?page=1&pageSize=10", token=access_token,
                   headers={"X-Tenant-Id": str(TENANT_ID)})
    ok = ok and resp2.status_code == 401
    report("TC-API-014", "管理员强制指定用户下线", ok,
           "kick_http={} after_http={}".format(resp.status_code, resp2.status_code))


def test_kickout_forbidden():  # TC-API-015
    user_id, access_token, _ = register_user(new_name("nf"), "Pass@1234")
    target_id, _, _ = register_user(new_name("nf2"), "Pass@1234")
    if not user_id or not access_token or not target_id:
        report("TC-API-015", "非管理员踢人返回 AUTH-0016", False, "前置注册失败")
        return
    resp, body = req("POST", AUTH_API + "/kickout", token=access_token,
                     json={"userId": target_id, "clientType": CLIENT_TYPE})
    ok = resp.status_code == 403 and str(body.get("code")) == "AUTH-0016"
    report("TC-API-015", "非管理员踢人返回 AUTH-0016", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_change_password_success():  # TC-API-016
    name = new_name("cp")
    _, access_token, _ = register_user(name, "Old@12345")
    if not access_token:
        report("TC-API-016", "修改密码成功并清除登录态", False, "前置注册失败")
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access_token, json={
        "oldPassword": "Old@12345", "newPassword": "New@54321", "confirmPassword": "New@54321"})
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, _ = req("GET", AUTH_API + "/users?page=1&pageSize=10", token=access_token,
                   headers={"X-Tenant-Id": str(TENANT_ID)})
    ok = ok and resp2.status_code == 401  # 改密后旧登录态清除
    new_token, _ = login_user(name, "New@54321")
    ok = ok and bool(new_token)  # 新密码可登录
    report("TC-API-016", "修改密码成功并清除登录态", ok,
           "change_http={} old_token_http={} relogin={}".format(resp.status_code, resp2.status_code, bool(new_token)))


def test_change_password_wrong_old():  # TC-API-017
    _, access_token, _ = register_user(new_name("wo"), "Old@12345")
    if not access_token:
        report("TC-API-017", "改密原密码错误返回 AUTH-0022", False, "前置注册失败")
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access_token, json={
        "oldPassword": "WrongOld123", "newPassword": "New@54321", "confirmPassword": "New@54321"})
    ok = resp.status_code == 400 and str(body.get("code")) == "AUTH-0022"
    report("TC-API-017", "改密原密码错误返回 AUTH-0022", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_change_password_confirm_mismatch():  # TC-API-018
    _, access_token, _ = register_user(new_name("cm"), "Old@12345")
    if not access_token:
        report("TC-API-018", "改密确认密码不一致返回 400", False, "前置注册失败")
        return
    resp, body = req("PUT", AUTH_API + "/password/change", token=access_token, json={
        "oldPassword": "Old@12345", "newPassword": "New@54321", "confirmPassword": "Diff@99999"})
    ok = resp.status_code == 400
    report("TC-API-018", "改密确认密码不一致返回 400", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_forgot_send_code_success():  # TC-API-019
    phone = "138" + str(uuid.uuid4().int % 100000000).zfill(8)
    register_user(new_name("f1"), "Pass@1234", phone=phone)
    resp, body = req("POST", AUTH_API + "/password/forgot/send-code",
                     json={"target": phone, "purpose": "RESET_PASSWORD", "mode": "SMS"})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-019", "密码找回发送重置验证码", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_forgot_send_code_user_not_found():  # TC-API-020
    resp, body = req("POST", AUTH_API + "/password/forgot/send-code",
                     json={"target": "199" + str(uuid.uuid4().int % 100000000).zfill(8),
                           "purpose": "RESET_PASSWORD", "mode": "SMS"})
    ok = resp.status_code == 404 and str(body.get("code")) == "AUTH-0018"
    report("TC-API-020", "找回验证码目标用户不存在返回 AUTH-0018", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_forgot_reset_success():  # TC-API-021
    phone = "137" + str(uuid.uuid4().int % 100000000).zfill(8)
    name = new_name("fr")
    register_user(name, "Old@12345", phone=phone)
    code = send_code(phone, "RESET_PASSWORD", "SMS")
    if not code:
        report("TC-API-021", "验证码重置密码成功", False, "无法获取验证码（模拟模式请人工确认）", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/password/forgot/reset",
                     json={"mode": "SMS", "target": phone, "code": code, "newPassword": "New@12345"})
    ok = resp.status_code == 200 and body.get("code") == 200
    new_token, _ = login_user(name, "New@12345")
    ok = ok and bool(new_token)
    report("TC-API-021", "验证码重置密码成功", ok,
           "reset_http={} code={} relogin={}".format(resp.status_code, body.get("code"), bool(new_token)))


def test_forgot_reset_wrong_code():  # TC-API-022
    phone = "136" + str(uuid.uuid4().int % 100000000).zfill(8)
    register_user(new_name("fw"), "Pass@1234", phone=phone)
    send_code(phone, "RESET_PASSWORD", "SMS")
    resp, body = req("POST", AUTH_API + "/password/forgot/reset",
                     json={"mode": "SMS", "target": phone, "code": "999999", "newPassword": "New@12345"})
    ok = resp.status_code == 400 and str(body.get("code")) in ("AUTH-0011", "AUTH-0023")
    report("TC-API-022", "重置密码验证码错误返回 AUTH-0011", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_change_phone_success():  # TC-API-023
    old_phone = "135" + str(uuid.uuid4().int % 100000000).zfill(8)
    new_phone = "139" + str(uuid.uuid4().int % 100000000).zfill(8)
    _, access_token, _ = register_user(new_name("ph"), "Pass@1234", phone=old_phone)
    if not access_token:
        report("TC-API-023", "短信验证码变更手机号成功", False, "前置注册失败")
        return
    old_code = send_code(old_phone, "CHANGE_PHONE", "SMS")
    new_code = send_code(new_phone, "CHANGE_PHONE", "SMS")
    if not old_code or not new_code:
        report("TC-API-023", "短信验证码变更手机号成功", False,
               "无法获取验证码（模拟模式请人工确认）", skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/phone/change", token=access_token, json={
        "newPhone": new_phone, "oldPhoneCode": old_code, "newPhoneCode": new_code})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-023", "短信验证码变更手机号成功", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_change_phone_already_bound():  # TC-API-024
    phone_owner = "134" + str(uuid.uuid4().int % 100000000).zfill(8)
    _, access_token, _ = register_user(new_name("pb1"), "Pass@1234", phone=phone_owner)
    new_phone = "133" + str(uuid.uuid4().int % 100000000).zfill(8)
    _, access_token2, _ = register_user(new_name("pb2"), "Pass@1234", phone=new_phone)
    if not access_token or not access_token2:
        report("TC-API-024", "新手机号已被其他账号绑定返回 AUTH-0028", False, "前置注册失败")
        return
    code = send_code(new_phone, "CHANGE_PHONE", "SMS")
    if not code:
        report("TC-API-024", "新手机号已被其他账号绑定返回 AUTH-0028", False,
               "无法获取验证码（模拟模式请人工确认）", skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/phone/change", token=access_token, json={
        "newPhone": new_phone, "oldPhoneCode": code, "newPhoneCode": code})
    ok = resp.status_code == 409 and str(body.get("code")) == "AUTH-0028"
    report("TC-API-024", "新手机号已被其他账号绑定返回 AUTH-0028", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_account_settlement_success():  # TC-API-025
    # 两步注册：OAuth 模式注册后账号未完善（accountSettled=false）
    name = new_name("settle")
    resp, body = req("POST", AUTH_API + "/register", json={
        "registerMode": "OAUTH", "oauthProvider": "wechat", "oauthCode": "mock_oauth_code",
        "userName": "两步注册用户", "tenantCode": TENANT_CODE})
    data = body.get("data") or {}
    user_id = data.get("userId")
    tp = data.get("tokenPair") or {}
    access_token = tp.get("accessToken")
    if not user_id or not access_token:
        report("TC-API-025", "两步注册账号补全成功", False,
               "OAuth 两步注册前置不可用（http={} code={}），本用例需人工/模拟环境执行".format(resp.status_code, body.get("code")),
               skipped=True)
        return
    resp, body = req("PUT", AUTH_API + "/account/settlement", token=access_token, json={
        "userId": user_id, "loginName": name, "password": "Settle@123", "phone": None})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-025", "两步注册账号补全成功", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_account_settlement_already_settled():  # TC-API-026
    _, access_token, _ = register_user(new_name("as"), "Pass@1234")
    if not access_token:
        report("TC-API-026", "已完善账号重复补全返回 AUTH-0031", False, "前置注册失败")
        return
    resp, body = req("PUT", AUTH_API + "/account/settlement", token=access_token, json={
        "userId": 1, "loginName": "hacker", "password": "Hack@1234"})
    ok = resp.status_code == 403 and str(body.get("code")) == "AUTH-0031"
    report("TC-API-026", "已完善账号重复补全返回 AUTH-0031", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_send_verification_code_success():  # TC-API-027
    phone = "132" + str(uuid.uuid4().int % 100000000).zfill(8)
    resp, body = req("POST", AUTH_API + "/verification-code/send",
                     json={"target": phone, "purpose": "REGISTER", "mode": "SMS"})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-027", "注册用途发送短信验证码", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_send_verification_code_too_frequent():  # TC-API-028
    phone = "131" + str(uuid.uuid4().int % 100000000).zfill(8)
    payload = {"target": phone, "purpose": "REGISTER", "mode": "SMS"}
    resp1, _ = req("POST", AUTH_API + "/verification-code/send", json=payload)
    resp2, body2 = req("POST", AUTH_API + "/verification-code/send", json=payload)
    ok = (resp1.status_code == 200
          and resp2.status_code == 429 and str(body2.get("code")) == "AUTH-0025")
    report("TC-API-028", "60 秒内重复发送验证码返回 AUTH-0025", ok,
           "first={} second={} code={}".format(resp1.status_code, resp2.status_code, body2.get("code")))


# ============================================================
# 二、RBAC 管理接口（API-012 ~ API-030）
# ============================================================

def test_user_page_query():  # TC-API-029
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-029", "管理员分页查询用户列表", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=10&keyword=admin",
                     token=ADMIN_ACCESS_TOKEN, headers={"X-Tenant-Id": str(TENANT_ID)})
    data = body.get("data") or {}
    records = data.get("records") or []
    no_password = all(("password" not in (r or {}) for r in records))
    ok = (resp.status_code == 200 and body.get("code") == 200
          and "records" in data and "total" in data
          and data.get("page") == 1 and data.get("pageSize") == 10 and no_password)
    report("TC-API-029", "管理员分页查询用户列表", ok,
           "http={} code={} total={}".format(resp.status_code, body.get("code"), data.get("total")))
    return records


def test_user_detail():  # TC-API-030
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-030", "获取用户详情", False, "管理员未登录", skipped=True)
        return
    records = test_user_page_query()
    user_id = (records[0].get("id") if records else None) or 1
    resp, body = req("GET", "{}/users/{}".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN)
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("id") == user_id and "password" not in data)
    report("TC-API-030", "获取用户详情", ok,
           "http={} code={} userId={}".format(resp.status_code, body.get("code"), user_id))


def test_user_detail_not_found():  # TC-API-031
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-031", "查询不存在用户返回 AUTH-0018", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/users/999999999", token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 404 and str(body.get("code")) == "AUTH-0018"
    report("TC-API-031", "查询不存在用户返回 AUTH-0018", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_user_update():  # TC-API-032
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-032", "更新用户姓名/邮箱", False, "管理员未登录", skipped=True)
        return
    user_id, _, _ = register_user(new_name("upd"), "Pass@1234")
    if not user_id:
        report("TC-API-032", "更新用户姓名/邮箱", False, "前置注册失败")
        return
    resp, body = req("PUT", "{}/users/{}".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN,
                     json={"userName": "更新测试", "email": "upd@example.com"})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("userName") == "更新测试" and data.get("email") == "upd@example.com")
    report("TC-API-032", "更新用户姓名/邮箱", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_user_delete():  # TC-API-033
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-033", "逻辑删除用户后查询不可见", False, "管理员未登录", skipped=True)
        return
    user_id, _, _ = register_user(new_name("del"), "Pass@1234")
    if not user_id:
        report("TC-API-033", "逻辑删除用户后查询不可见", False, "前置注册失败")
        return
    resp, body = req("DELETE", "{}/users/{}".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, body2 = req("GET", "{}/users/{}".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN)
    ok = ok and resp2.status_code == 404
    report("TC-API-033", "逻辑删除用户后查询不可见", ok,
           "del_http={} detail_http={}".format(resp.status_code, resp2.status_code))


def test_user_assign_roles():  # TC-API-034
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-034", "全量分配用户角色", False, "管理员未登录", skipped=True)
        return
    user_id, _, _ = register_user(new_name("role"), "Pass@1234")
    resp, body = req("GET", AUTH_API + "/roles/list?tenantId={}".format(TENANT_ID), token=ADMIN_ACCESS_TOKEN)
    roles = body.get("data") or []
    role_id = roles[0].get("id") if roles else None
    if not user_id or not role_id:
        report("TC-API-034", "全量分配用户角色", False, "前置注册/角色查询失败")
        return
    resp, body = req("PUT", "{}/users/{}/roles".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN,
                     json={"roleIds": [role_id]})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-034", "全量分配用户角色", ok,
           "http={} code={} roleId={}".format(resp.status_code, body.get("code"), role_id))


def test_user_status_ban():  # TC-API-035
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-035", "封禁用户后登录态实时失效", False, "管理员未登录", skipped=True)
        return
    name = new_name("ban")
    user_id, access_token, _ = register_user(name, "Pass@1234")
    if not user_id or not access_token:
        report("TC-API-035", "封禁用户后登录态实时失效", False, "前置注册失败")
        return
    resp, body = req("PUT", "{}/users/{}/status".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN,
                     json={"status": 3, "lockReason": "违规操作，封禁处理"})
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, _ = req("GET", AUTH_API + "/users?page=1&pageSize=10", token=access_token,
                   headers={"X-Tenant-Id": str(TENANT_ID)})
    ok = ok and resp2.status_code == 403  # 旧会话被网关账号状态拦截
    resp3, body3 = req("POST", AUTH_API + "/login", json={
        "loginMode": "USERNAME_PASSWORD", "loginName": name, "password": "Pass@1234",
        "tenantCode": TENANT_CODE, "clientType": CLIENT_TYPE})
    ok = ok and resp3.status_code == 403 and str(body3.get("code")) == "AUTH-0008"
    report("TC-API-035", "封禁用户后登录态实时失效", ok,
           "status_http={} old_token_http={} relogin={}/{}".format(resp.status_code, resp2.status_code, resp3.status_code, body3.get("code")))


def test_user_status_invalid():  # TC-API-036
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-036", "状态值超出 0-3 范围返回 400", False, "管理员未登录", skipped=True)
        return
    user_id, _, _ = register_user(new_name("st"), "Pass@1234")
    if not user_id:
        report("TC-API-036", "状态值超出 0-3 范围返回 400", False, "前置注册失败")
        return
    resp, body = req("PUT", "{}/users/{}/status".format(AUTH_API, user_id), token=ADMIN_ACCESS_TOKEN,
                     json={"status": 9})
    ok = resp.status_code == 400
    report("TC-API-036", "状态值超出 0-3 范围返回 400", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_role_page_query():  # TC-API-037
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-037", "按租户分页查询角色列表", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/roles?page=1&pageSize=10&tenantId={}".format(TENANT_ID),
                     token=ADMIN_ACCESS_TOKEN)
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and "records" in data and "total" in data)
    report("TC-API-037", "按租户分页查询角色列表", ok,
           "http={} code={} total={}".format(resp.status_code, body.get("code"), data.get("total")))


def test_role_list():  # TC-API-038
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-038", "不分页查询租户全部角色", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/roles/list?tenantId={}".format(TENANT_ID), token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 200 and body.get("code") == 200 and isinstance(body.get("data"), list)
    report("TC-API-038", "不分页查询租户全部角色", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def _find_role_id():
    resp, body = req("GET", AUTH_API + "/roles/list?tenantId={}".format(TENANT_ID), token=ADMIN_ACCESS_TOKEN)
    roles = body.get("data") or []
    return roles[0].get("id") if roles else None


def test_role_detail():  # TC-API-039
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-039", "查询角色详情", False, "管理员未登录", skipped=True)
        return
    role_id = _find_role_id()
    if not role_id:
        report("TC-API-039", "查询角色详情", False, "角色列表为空")
        return
    resp, body = req("GET", "{}/roles/{}".format(AUTH_API, role_id), token=ADMIN_ACCESS_TOKEN)
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("id") == role_id and data.get("roleCode"))
    report("TC-API-039", "查询角色详情", ok,
           "http={} code={} roleCode={}".format(resp.status_code, body.get("code"), data.get("roleCode")))


def test_role_create():  # TC-API-040
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-040", "创建角色成功", False, "管理员未登录", skipped=True)
        return
    role_code = "TEST_ROLE_" + uuid.uuid4().hex[:8].upper()
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_ACCESS_TOKEN, json={
        "tenantId": TENANT_ID, "roleCode": role_code, "roleName": "自动化测试角色", "status": 1})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("roleCode") == role_code and data.get("id"))
    report("TC-API-040", "创建角色成功", ok,
           "http={} code={} roleId={}".format(resp.status_code, body.get("code"), data.get("id")))
    return data.get("id")


def test_role_create_duplicate_code():  # TC-API-041
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-041", "租户内角色编码重复返回 409", False, "管理员未登录", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/roles", token=ADMIN_ACCESS_TOKEN, json={
        "tenantId": TENANT_ID, "roleCode": "SUPER_ADMIN", "roleName": "重复角色"})
    ok = resp.status_code == 409
    report("TC-API-041", "租户内角色编码重复返回 409", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_role_update():  # TC-API-042
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-042", "更新角色信息", False, "管理员未登录", skipped=True)
        return
    role_id = test_role_create()
    if not role_id:
        report("TC-API-042", "更新角色信息", False, "前置创建角色失败")
        return
    resp, body = req("PUT", "{}/roles/{}".format(AUTH_API, role_id), token=ADMIN_ACCESS_TOKEN,
                     json={"roleName": "更新后的测试角色"})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("roleName") == "更新后的测试角色")
    report("TC-API-042", "更新角色信息", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_role_delete():  # TC-API-043
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-043", "逻辑删除未分配角色", False, "管理员未登录", skipped=True)
        return
    role_id = test_role_create()
    if not role_id:
        report("TC-API-043", "逻辑删除未分配角色", False, "前置创建角色失败")
        return
    resp, body = req("DELETE", "{}/roles/{}".format(AUTH_API, role_id), token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, _ = req("GET", "{}/roles/{}".format(AUTH_API, role_id), token=ADMIN_ACCESS_TOKEN)
    ok = ok and resp2.status_code == 404
    report("TC-API-043", "逻辑删除未分配角色", ok,
           "del_http={} detail_http={}".format(resp.status_code, resp2.status_code))


def test_role_delete_in_use():  # TC-API-044
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-044", "删除已被分配角色返回 409", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/roles/list?tenantId={}".format(TENANT_ID), token=ADMIN_ACCESS_TOKEN)
    roles = body.get("data") or []
    in_use_id = None
    for r in roles:
        if r.get("roleCode") == "SUPER_ADMIN":
            in_use_id = r.get("id")
            break
    if not in_use_id:
        report("TC-API-044", "删除已被分配角色返回 409", False, "未找到已分配角色（如 SUPER_ADMIN）", skipped=True)
        return
    resp, body = req("DELETE", "{}/roles/{}".format(AUTH_API, in_use_id), token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 409
    report("TC-API-044", "删除已被分配角色返回 409", ok,
           "http={} code={} msg={}".format(resp.status_code, body.get("code"), body.get("message")))


def test_role_assign_permissions():  # TC-API-045
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-045", "全量分配角色权限", False, "管理员未登录", skipped=True)
        return
    role_id = test_role_create()
    if not role_id:
        report("TC-API-045", "全量分配角色权限", False, "前置创建角色失败")
        return
    resp, body = req("GET", AUTH_API + "/permissions/list", token=ADMIN_ACCESS_TOKEN)
    perms = body.get("data") or []
    perm_ids = [p.get("id") for p in perms[:2] if p.get("id")]
    if not perm_ids:
        report("TC-API-045", "全量分配角色权限", False, "权限列表为空", skipped=True)
        return
    resp, body = req("PUT", "{}/roles/{}/permissions".format(AUTH_API, role_id), token=ADMIN_ACCESS_TOKEN,
                     json={"permissionIds": perm_ids})
    ok = resp.status_code == 200 and body.get("code") == 200
    report("TC-API-045", "全量分配角色权限", ok,
           "http={} code={} permIds={}".format(resp.status_code, body.get("code"), perm_ids))


def test_permission_tree():  # TC-API-046
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-046", "获取树形权限列表", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/permissions/tree", token=ADMIN_ACCESS_TOKEN)
    data = body.get("data") or []
    ok = (resp.status_code == 200 and body.get("code") == 200
          and isinstance(data, list)
          and all(isinstance(n.get("children"), list) for n in data))
    report("TC-API-046", "获取树形权限列表", ok,
           "http={} code={} nodes={}".format(resp.status_code, body.get("code"), len(data)))


def test_permission_list():  # TC-API-047
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-047", "获取平铺权限列表", False, "管理员未登录", skipped=True)
        return
    resp, body = req("GET", AUTH_API + "/permissions/list", token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 200 and body.get("code") == 200 and isinstance(body.get("data"), list)
    report("TC-API-047", "获取平铺权限列表", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def _find_perm_id():
    resp, body = req("GET", AUTH_API + "/permissions/list", token=ADMIN_ACCESS_TOKEN)
    perms = body.get("data") or []
    return perms[0].get("id") if perms else None


def test_permission_detail():  # TC-API-048
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-048", "查询权限详情", False, "管理员未登录", skipped=True)
        return
    perm_id = _find_perm_id()
    if not perm_id:
        report("TC-API-048", "查询权限详情", False, "权限列表为空", skipped=True)
        return
    resp, body = req("GET", "{}/permissions/{}".format(AUTH_API, perm_id), token=ADMIN_ACCESS_TOKEN)
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("id") == perm_id and data.get("permCode"))
    report("TC-API-048", "查询权限详情", ok,
           "http={} code={} permCode={}".format(resp.status_code, body.get("code"), data.get("permCode")))


def test_permission_create():  # TC-API-049
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-049", "创建权限成功（HTTP 201）", False, "管理员未登录", skipped=True)
        return
    perm_code = "test:perm_" + uuid.uuid4().hex[:8]
    resp, body = req("POST", AUTH_API + "/permissions", token=ADMIN_ACCESS_TOKEN, json={
        "permCode": perm_code, "permName": "自动化测试权限", "parentId": 0, "type": 2, "sort": 1})
    data = body.get("data") or {}
    ok = (resp.status_code == 201 and body.get("code") == 200
          and data.get("permCode") == perm_code and data.get("id"))
    report("TC-API-049", "创建权限成功（HTTP 201）", ok,
           "http={} code={} permId={}".format(resp.status_code, body.get("code"), data.get("id")))
    return data.get("id")


def test_permission_create_duplicate_code():  # TC-API-050
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-050", "权限编码全局重复返回 409", False, "管理员未登录", skipped=True)
        return
    resp, body = req("POST", AUTH_API + "/permissions", token=ADMIN_ACCESS_TOKEN, json={
        "permCode": "user:list", "permName": "重复权限"})
    ok = resp.status_code == 409
    report("TC-API-050", "权限编码全局重复返回 409", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_permission_update():  # TC-API-051
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-051", "更新权限信息", False, "管理员未登录", skipped=True)
        return
    perm_id = test_permission_create()
    if not perm_id:
        report("TC-API-051", "更新权限信息", False, "前置创建权限失败")
        return
    resp, body = req("PUT", "{}/permissions/{}".format(AUTH_API, perm_id), token=ADMIN_ACCESS_TOKEN,
                     json={"permName": "更新后的测试权限", "sort": 4})
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("permName") == "更新后的测试权限" and data.get("sort") == 4)
    report("TC-API-051", "更新权限信息", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_permission_delete():  # TC-API-052
    if not ADMIN_ACCESS_TOKEN:
        report("TC-API-052", "逻辑删除未关联权限", False, "管理员未登录", skipped=True)
        return
    # 1) 删除未关联权限成功
    perm_id = test_permission_create()
    if not perm_id:
        report("TC-API-052", "逻辑删除未关联权限", False, "前置创建权限失败")
        return
    resp, body = req("DELETE", "{}/permissions/{}".format(AUTH_API, perm_id), token=ADMIN_ACCESS_TOKEN)
    ok = resp.status_code == 200 and body.get("code") == 200
    resp2, _ = req("GET", "{}/permissions/{}".format(AUTH_API, perm_id), token=ADMIN_ACCESS_TOKEN)
    ok = ok and resp2.status_code == 404
    report("TC-API-052", "逻辑删除未关联权限", ok,
           "del_http={} detail_http={}".format(resp.status_code, resp2.status_code))


# ============================================================
# 三、健康检查与通用鉴权（API-031 ~ API-033、401/403）
# ============================================================

def test_health_auth():  # TC-API-053
    resp, body = req("GET", BASE_URL + "/api/v1/auth/health")
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("service") == "cloudoffice-auth-service"
          and data.get("status") == "UP" and data.get("version") and data.get("timestamp"))
    report("TC-API-053", "认证服务健康检查", ok,
           "http={} code={} service={} status={}".format(resp.status_code, body.get("code"), data.get("service"), data.get("status")))


def test_health_biz():  # TC-API-054
    resp, body = req("GET", BASE_URL + "/api/v1/biz/health")
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("service") == "cloudoffice-biz-service" and data.get("status") == "UP")
    report("TC-API-054", "企业服务健康检查", ok,
           "http={} code={} service={}".format(resp.status_code, body.get("code"), data.get("service")))


def test_health_system():  # TC-API-055
    resp, body = req("GET", BASE_URL + "/api/v1/system/health")
    data = body.get("data") or {}
    ok = (resp.status_code == 200 and body.get("code") == 200
          and data.get("service") == "cloudoffice-system-service" and data.get("status") == "UP")
    report("TC-API-055", "系统服务健康检查", ok,
           "http={} code={} service={}".format(resp.status_code, body.get("code"), data.get("service")))


def test_unauthorized_access():  # TC-API-056
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=10")
    ok = resp.status_code == 401
    report("TC-API-056", "无 Token 访问受保护接口返回 401", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


def test_admin_api_forbidden():  # TC-API-057
    _, access_token, _ = register_user(new_name("u1"), "Pass@1234")
    if not access_token:
        report("TC-API-057", "普通用户访问管理接口返回 AUTH-0016", False, "前置注册失败")
        return
    resp, body = req("GET", AUTH_API + "/users?page=1&pageSize=10", token=access_token,
                     headers={"X-Tenant-Id": str(TENANT_ID)})
    ok = resp.status_code == 403 and str(body.get("code")) == "AUTH-0016"
    report("TC-API-057", "普通用户访问管理接口返回 AUTH-0016", ok,
           "http={} code={}".format(resp.status_code, body.get("code")))


# ============================================================
# 用例清单与执行
# ============================================================
CASES = [
    # 一、认证管理接口（API-001 ~ API-011）
    ("TC-API-001", "用户名密码登录成功", test_login_success),
    ("TC-API-002", "登录密码错误返回 AUTH-0010", test_login_wrong_password),
    ("TC-API-003", "登录客户端类型非法返回 AUTH-0012/400", test_login_invalid_client_type),
    ("TC-API-004", "登录模式非法返回 AUTH-0033/400", test_login_invalid_mode),
    ("TC-API-005", "封禁账号登录返回 AUTH-0008", test_login_banned_account),
    ("TC-API-006", "USERNAME 模式注册成功", test_register_success),
    ("TC-API-007", "注册登录名重复返回 409", test_register_duplicate_login_name),
    ("TC-API-008", "注册参数非法返回 400", test_register_invalid_params),
    ("TC-API-009", "Refresh Token 换发新双 Token", test_refresh_success),
    ("TC-API-010", "无效 Refresh Token 返回 AUTH-0005", test_refresh_invalid_token),
    ("TC-API-011", "旧 Refresh Token 重放返回 AUTH-0003", test_refresh_replay_rejected),
    ("TC-API-012", "登出成功且重复登出幂等", test_logout_success_and_idempotent),
    ("TC-API-013", "登出后原 Token 访问返回 401", test_logout_token_invalidated),
    ("TC-API-014", "管理员强制指定用户下线", test_kickout_success),
    ("TC-API-015", "非管理员踢人返回 AUTH-0016", test_kickout_forbidden),
    ("TC-API-016", "修改密码成功并清除登录态", test_change_password_success),
    ("TC-API-017", "改密原密码错误返回 AUTH-0022", test_change_password_wrong_old),
    ("TC-API-018", "改密确认密码不一致返回 400", test_change_password_confirm_mismatch),
    ("TC-API-019", "密码找回发送重置验证码", test_forgot_send_code_success),
    ("TC-API-020", "找回验证码目标用户不存在返回 AUTH-0018", test_forgot_send_code_user_not_found),
    ("TC-API-021", "验证码重置密码成功", test_forgot_reset_success),
    ("TC-API-022", "重置密码验证码错误返回 AUTH-0011", test_forgot_reset_wrong_code),
    ("TC-API-023", "短信验证码变更手机号成功", test_change_phone_success),
    ("TC-API-024", "新手机号已被其他账号绑定返回 AUTH-0028", test_change_phone_already_bound),
    ("TC-API-025", "两步注册账号补全成功", test_account_settlement_success),
    ("TC-API-026", "已完善账号重复补全返回 AUTH-0031", test_account_settlement_already_settled),
    ("TC-API-027", "注册用途发送短信验证码", test_send_verification_code_success),
    ("TC-API-028", "60 秒内重复发送验证码返回 AUTH-0025", test_send_verification_code_too_frequent),
    # 二、RBAC 管理接口（API-012 ~ API-030）
    ("TC-API-029", "管理员分页查询用户列表", test_user_page_query),
    ("TC-API-030", "获取用户详情", test_user_detail),
    ("TC-API-031", "查询不存在用户返回 AUTH-0018", test_user_detail_not_found),
    ("TC-API-032", "更新用户姓名/邮箱", test_user_update),
    ("TC-API-033", "逻辑删除用户后查询不可见", test_user_delete),
    ("TC-API-034", "全量分配用户角色", test_user_assign_roles),
    ("TC-API-035", "封禁用户后登录态实时失效", test_user_status_ban),
    ("TC-API-036", "状态值超出 0-3 范围返回 400", test_user_status_invalid),
    ("TC-API-037", "按租户分页查询角色列表", test_role_page_query),
    ("TC-API-038", "不分页查询租户全部角色", test_role_list),
    ("TC-API-039", "查询角色详情", test_role_detail),
    ("TC-API-040", "创建角色成功", test_role_create),
    ("TC-API-041", "租户内角色编码重复返回 409", test_role_create_duplicate_code),
    ("TC-API-042", "更新角色信息", test_role_update),
    ("TC-API-043", "逻辑删除未分配角色", test_role_delete),
    ("TC-API-044", "删除已被分配角色返回 409", test_role_delete_in_use),
    ("TC-API-045", "全量分配角色权限", test_role_assign_permissions),
    ("TC-API-046", "获取树形权限列表", test_permission_tree),
    ("TC-API-047", "获取平铺权限列表", test_permission_list),
    ("TC-API-048", "查询权限详情", test_permission_detail),
    ("TC-API-049", "创建权限成功（HTTP 201）", test_permission_create),
    ("TC-API-050", "权限编码全局重复返回 409", test_permission_create_duplicate_code),
    ("TC-API-051", "更新权限信息", test_permission_update),
    ("TC-API-052", "逻辑删除未关联权限", test_permission_delete),
    # 三、健康检查与通用鉴权
    ("TC-API-053", "认证服务健康检查", test_health_auth),
    ("TC-API-054", "企业服务健康检查", test_health_biz),
    ("TC-API-055", "系统服务健康检查", test_health_system),
    ("TC-API-056", "无 Token 访问受保护接口返回 401", test_unauthorized_access),
    ("TC-API-057", "普通用户访问管理接口返回 AUTH-0016", test_admin_api_forbidden),
]


def main():
    global ADMIN_ACCESS_TOKEN, ADMIN_REFRESH_TOKEN
    print("=" * 78)
    print("CloudStrollOffice 接口自动化测试 v0.0.1")
    print("网关地址: {}".format(BASE_URL))
    print("覆盖用例: TC-API-001 ~ TC-API-057（docs/cso-testcase.md 接口测试）")
    print("=" * 78)

    # 预登录管理员（供 RBAC 用例使用）
    ADMIN_ACCESS_TOKEN, ADMIN_REFRESH_TOKEN = login_user(ADMIN_LOGIN_NAME, ADMIN_PASSWORD)
    if ADMIN_ACCESS_TOKEN:
        print("[info] 管理员预登录成功（{}）".format(ADMIN_LOGIN_NAME))
    else:
        print("[info] 管理员预登录失败，RBAC 相关用例将标记 SKIP")

    for case_id, name, fn in CASES:
        try:
            fn()
        except Exception as exc:  # noqa: BLE001 用例级容错，避免单用例异常中断整体执行
            report(case_id, name, False, "异常: {}".format(exc))

    print("=" * 78)
    print("执行汇总：")
    print("  通过: {PASS}  失败: {FAIL}  跳过: {SKIP}  合计: {TOTAL}".format(
        PASS=PASS, FAIL=FAIL, SKIP=SKIP, TOTAL=PASS + FAIL + SKIP))
    if FAILED_CASES:
        print("失败用例：")
        for cid, nm, dt in FAILED_CASES:
            print("  - {} {} {}".format(cid, nm, dt))
    if SKIPPED_CASES:
        print("跳过用例：")
        for cid, nm, dt in SKIPPED_CASES:
            print("  - {} {} {}".format(cid, nm, dt))
    print("=" * 78)
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
