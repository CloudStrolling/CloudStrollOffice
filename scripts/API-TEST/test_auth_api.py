# -*- coding: utf-8 -*-
"""
CloudStrollOffice（云漫智企）认证接口自动化测试脚本
版本：v0.0.1（初始化阶段）
说明：覆盖 docs/cso-v0.0.1/cso-testcase-v0.0.1.md 中 TC-001 ~ TC-020 接口测试用例
依赖：requests（pip install requests）
用法：
    python test_auth_api.py                  # 默认 http://localhost:9000
    python test_auth_api.py http://10.0.0.8:9000   # 指定网关地址
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

PASS = 0
FAIL = 0
FAILED_CASES = []


def report(case_id, name, ok, detail=""):
    """输出用例执行结果并汇总"""
    global PASS, FAIL
    status = "PASS" if ok else "FAIL"
    if ok:
        PASS += 1
    else:
        FAIL += 1
        FAILED_CASES.append((case_id, name, detail))
    print("[{}] {} {} {}".format(status, case_id, name, detail if not ok else ""))


def new_test_name(prefix):
    """生成唯一测试用户名（避免重复执行冲突）"""
    return "{}_{}".format(prefix, uuid.uuid4().hex[:8])


def get_verification_code(target):
    """
    发送验证码并返回验证码内容。
    开发环境为模拟发送（控制台打印），脚本通过验证码接口的响应或约定规则获取。
    若接口返回 data.code 则直接使用；否则提示人工从控制台获取（脚本跳过断言）。
    """
    resp = requests.post(AUTH_API + "/verification-code/send", json={
        "target": target, "purpose": "REGISTER", "sendMode": "SMS"
    }, timeout=10)
    data = resp.json().get("data") or {}
    code = data.get("code")
    if code:
        return str(code)
    print("  [info] 请在服务端控制台查看发送到 {} 的验证码（模拟发送）".format(target))
    return None


# ============================================================
# TC-001 用户名密码登录成功
# ============================================================
def test_login_success():
    name = new_test_name("login_ok")
    # 先注册一个测试用户
    pwd = "Test@1234"
    requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": pwd,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    resp = requests.post(AUTH_API + "/login", json={
        "loginType": "USERNAME_PASSWORD", "loginName": name, "password": pwd,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0 and body.get("data", {}).get("accessToken")
    report("TC-001", "用户名密码登录成功", ok, "resp={}".format(body.get("message")))
    return body.get("data", {}).get("accessToken"), body.get("data", {}).get("refreshToken")


# ============================================================
# TC-002 用户名密码登录失败（密码错误）
# ============================================================
def test_login_wrong_password():
    resp = requests.post(AUTH_API + "/login", json={
        "loginType": "USERNAME_PASSWORD", "loginName": "admin", "password": "wrongpass_xx",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") != 0
    # 安全要求：错误信息不得透露具体原因（不包含"用户名不存在"等字样）
    msg = body.get("message", "")
    safe = ("密码" not in msg and "不存在" not in msg) or "用户名或密码错误" in msg
    report("TC-002", "用户名密码登录失败（密码错误）", ok and safe, "code={}, msg={}".format(body.get("code"), msg))


# ============================================================
# TC-003 手机验证码登录成功
# ============================================================
def test_login_phone_code():
    name = new_test_name("phone_ok")
    phone = "139" + str(int(time.time()))[-8:]
    pwd = "Test@1234"
    requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": pwd, "phone": phone,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    code = get_verification_code(phone)
    if not code:
        report("TC-003", "手机验证码登录成功", False, "无法自动获取验证码，请人工验证")
        return
    resp = requests.post(AUTH_API + "/login", json={
        "loginType": "PHONE_CODE", "phone": phone, "code": code,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0 and body.get("data", {}).get("accessToken")
    report("TC-003", "手机验证码登录成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-004 验证码错误登录失败
# ============================================================
def test_login_wrong_code():
    resp = requests.post(AUTH_API + "/login", json={
        "loginType": "PHONE_CODE", "phone": "13900001111", "code": "000000",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") != 0
    report("TC-004", "验证码错误登录失败", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-005 Token 刷新成功
# ============================================================
def test_refresh_token():
    _, refresh = test_login_success()
    if not refresh:
        return
    resp = requests.post(AUTH_API + "/refresh", json={"refreshToken": refresh}, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0 and body.get("data", {}).get("accessToken")
    report("TC-005", "Token 刷新成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-006 登出成功
# ============================================================
def test_logout():
    token, _ = test_login_success()
    if not token:
        return
    resp = requests.post(AUTH_API + "/logout", headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-006", "登出成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-007 用户名密码注册成功
# ============================================================
def test_register_success():
    name = new_test_name("reg_ok")
    resp = requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": "Test@1234",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-007", "用户名密码注册成功", ok, "resp={}".format(body.get("message")))
    return name


# ============================================================
# TC-008 重复用户名注册失败
# ============================================================
def test_register_duplicate_name():
    name = test_register_success()
    resp = requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": "Test@1234",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") != 0
    report("TC-008", "重复用户名注册失败", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-009 发送验证码成功
# ============================================================
def test_send_verification_code():
    resp = requests.post(AUTH_API + "/verification-code/send", json={
        "target": "13800002222", "purpose": "REGISTER", "sendMode": "SMS"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-009", "发送验证码成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-010 验证码发送频率限制
# ============================================================
def test_send_code_rate_limit():
    target = "138" + str(int(time.time()))[-8:]
    first = requests.post(AUTH_API + "/verification-code/send", json={
        "target": target, "purpose": "REGISTER", "sendMode": "SMS"
    }, timeout=10)
    second = requests.post(AUTH_API + "/verification-code/send", json={
        "target": target, "purpose": "REGISTER", "sendMode": "SMS"
    }, timeout=10)
    ok = first.json().get("code") == 0 and second.json().get("code") != 0
    report("TC-010", "验证码发送频率限制", ok,
           "first={}, second={}".format(first.json().get("code"), second.json().get("code")))


# ============================================================
# TC-011 修改密码成功
# ============================================================
def test_change_password():
    name = new_test_name("pwd_ok")
    old_pwd = "Test@1234"
    requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": old_pwd,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    login = requests.post(AUTH_API + "/login", json={
        "loginType": "USERNAME_PASSWORD", "loginName": name, "password": old_pwd,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    token = login.json().get("data", {}).get("accessToken")
    if not token:
        report("TC-011", "修改密码成功", False, "登录失败")
        return
    resp = requests.put(AUTH_API + "/password/change", json={
        "oldPassword": old_pwd, "newPassword": "NewPass@123"
    }, headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-011", "修改密码成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-012 找回密码重置成功
# ============================================================
def test_forgot_password_reset():
    name = new_test_name("forgot_ok")
    pwd = "Test@1234"
    phone = "137" + str(int(time.time()))[-8:]
    requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": pwd, "phone": phone,
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    # 发送找回密码验证码
    resp = requests.post(AUTH_API + "/password/forgot/send-code", json={
        "phone": phone, "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    if resp.json().get("code") != 0:
        report("TC-012", "找回密码重置成功", False, "发送验证码失败")
        return
    code = (resp.json().get("data") or {}).get("code")
    if not code:
        print("  [info] 请在服务端控制台查看发送到 {} 的找回密码验证码（模拟发送）".format(phone))
        report("TC-012", "找回密码重置成功", False, "无法自动获取验证码，请人工验证")
        return
    resp = requests.post(AUTH_API + "/password/forgot/reset", json={
        "phone": phone, "code": code, "newPassword": "Reset@123",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-012", "找回密码重置成功", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-013 用户分页查询（管理员）
# ============================================================
def admin_token():
    """获取管理员 Token（默认 admin/admin123，失败返回 None）"""
    resp = requests.post(AUTH_API + "/login", json={
        "loginType": "USERNAME_PASSWORD", "loginName": "admin", "password": "admin123",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    return resp.json().get("data", {}).get("accessToken")


def test_user_list():
    token = admin_token()
    if not token:
        report("TC-013", "用户分页查询", False, "管理员登录失败")
        return
    resp = requests.get(AUTH_API + "/users", params={"pageNum": 1, "pageSize": 10},
                        headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    data = body.get("data") or {}
    ok = body.get("code") == 0 and "records" in data and "total" in data
    report("TC-013", "用户分页查询", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-014 无权限访问被拒绝
# ============================================================
def test_permission_denied():
    name = new_test_name("noperm")
    requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": "Test@1234",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    login = requests.post(AUTH_API + "/login", json={
        "loginType": "USERNAME_PASSWORD", "loginName": name, "password": "Test@1234",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    token = login.json().get("data", {}).get("accessToken")
    if not token:
        report("TC-014", "无权限访问被拒绝", False, "普通用户登录失败")
        return
    resp = requests.get(AUTH_API + "/users", params={"pageNum": 1, "pageSize": 10},
                        headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    ok = body.get("code") != 0
    report("TC-014", "无权限访问被拒绝", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-015 变更用户状态
# ============================================================
def test_user_status():
    token = admin_token()
    name = new_test_name("status_ok")
    reg = requests.post(AUTH_API + "/register", json={
        "registerType": "USERNAME", "loginName": name, "password": "Test@1234",
        "clientType": "H5", "tenantCode": "default"
    }, timeout=10)
    user_id = (reg.json().get("data") or {}).get("userId")
    if not token or not user_id:
        report("TC-015", "变更用户状态", False, "管理员登录或注册失败")
        return
    resp = requests.put(AUTH_API + "/users/{}/status".format(user_id), json={"status": 2},
                        headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-015", "变更用户状态", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-016 角色列表查询
# ============================================================
def test_role_list():
    token = admin_token()
    if not token:
        report("TC-016", "角色列表查询", False, "管理员登录失败")
        return
    resp = requests.get(AUTH_API + "/roles/list", headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    roles = body.get("data") or []
    ok = body.get("code") == 0 and any(r.get("roleCode") == "SUPER_ADMIN" for r in roles)
    report("TC-016", "角色列表查询", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-017 权限树查询
# ============================================================
def test_permission_tree():
    token = admin_token()
    if not token:
        report("TC-017", "权限树查询", False, "管理员登录失败")
        return
    resp = requests.get(AUTH_API + "/permissions/tree", headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    tree = body.get("data") or []
    ok = body.get("code") == 0 and len(tree) > 0
    report("TC-017", "权限树查询", ok, "code={}".format(body.get("code")))


# ============================================================
# TC-018 角色授权
# ============================================================
def test_role_assign_permissions():
    token = admin_token()
    if not token:
        report("TC-018", "角色授权", False, "管理员登录失败")
        return
    # 创建临时角色
    resp = requests.post(AUTH_API + "/roles", json={
        "roleName": "临时测试角色", "roleCode": "TMP_" + uuid.uuid4().hex[:6], "description": "自动化测试临时角色"
    }, headers={"Authorization": "Bearer " + token}, timeout=10)
    role_id = (resp.json().get("data") or {}).get("id")
    if not role_id:
        report("TC-018", "角色授权", False, "创建角色失败")
        return
    resp = requests.put(AUTH_API + "/roles/{}/permissions".format(role_id), json={"permissionIds": [1]},
                        headers={"Authorization": "Bearer " + token}, timeout=10)
    body = resp.json()
    ok = body.get("code") == 0
    report("TC-018", "角色授权", ok, "resp={}".format(body.get("message")))


# ============================================================
# TC-019 认证服务健康检查
# ============================================================
def test_health():
    resp = requests.get(AUTH_API + "/health", timeout=10)
    ok = resp.status_code == 200
    report("TC-019", "认证服务健康检查", ok, "http={}".format(resp.status_code))


# ============================================================
# TC-020 网关路由连通性
# ============================================================
def test_gateway_route():
    resp = requests.get(BASE_URL + "/api/v1/auth/health", timeout=10)
    ok = resp.status_code == 200
    report("TC-020", "网关路由连通性", ok, "http={}".format(resp.status_code))


# ============================================================
# 主入口
# ============================================================
def main():
    print("=" * 60)
    print("CloudStrollOffice 认证接口自动化测试（v0.0.1）")
    print("网关地址：{}".format(BASE_URL))
    print("=" * 60)

    # 认证接口
    test_login_success()           # TC-001
    test_login_wrong_password()    # TC-002
    test_login_phone_code()        # TC-003
    test_login_wrong_code()        # TC-004
    test_refresh_token()           # TC-005
    test_logout()                  # TC-006
    test_register_success()        # TC-007
    test_register_duplicate_name() # TC-008
    test_send_verification_code()  # TC-009
    test_send_code_rate_limit()    # TC-010
    test_change_password()         # TC-011
    test_forgot_password_reset()   # TC-012

    # 管理接口
    test_user_list()               # TC-013
    test_permission_denied()       # TC-014
    test_user_status()             # TC-015
    test_role_list()               # TC-016
    test_permission_tree()         # TC-017
    test_role_assign_permissions() # TC-018

    # 网关健康
    test_health()                  # TC-019
    test_gateway_route()           # TC-020

    print("=" * 60)
    print("结果汇总：通过 {}，失败 {}".format(PASS, FAIL))
    if FAILED_CASES:
        print("失败用例：")
        for case_id, name, detail in FAILED_CASES:
            print("  - {} {}：{}".format(case_id, name, detail))
    print("=" * 60)
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
