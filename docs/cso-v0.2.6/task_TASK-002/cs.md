# 代码查询结果（cs.md · TASK-002 统一 RSA 密钥格式契约为 DER 编码单行 Base64）

**任务编号**：TASK-002
**版本号**：v0.2.6
**查询人**：CS（本地代码查询）
**查询日期**：2026-08-09
**查询目标**：定位 deploy/scripts/deploy-rsa-keygen.ps1 现有实现、deploy/env.json 现有 RSA 密钥值格式、gateway/auth 的 RsaKeyConfig 解码契约代码、deploy 目录结构，为"脚本侧修复（方案 A）"提供代码依据。

---

## 1. 问题根因文件（本次任务允许修改，共 2 个）

### 1.1 deploy/scripts/deploy-rsa-keygen.ps1（Windows 密钥生成脚本，88 行）【核心缺陷文件】

**文件路径**：`deploy/scripts/deploy-rsa-keygen.ps1`

**关键代码结构**：

| 行号 | 代码/逻辑 | 说明 |
| --- | --- | --- |
| 13-15 | `param([string]$OutputDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "keys"))` | 输出目录参数，默认 `deploy/keys` |
| 22-25 | 定义输出文件：`private_key.pem`、`public_key.pem`、`private_key_base64.txt`、`public_key_base64.txt` | 输出资产 |
| 33-42 | 检查 OpenSSL 可用性 | 依赖 OpenSSL |
| 46 | `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out "$privateKeyFile"` | 生成 **PEM 格式** PKCS#8 私钥 |
| 52 | `openssl pkey -in "$privateKeyFile" -pubout -outform PEM -out "$publicKeyFile"` | 提取 **PEM 格式** X.509 公钥 |
| **58-59** | `$privateKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $privateKeyFile)))`<br>`$publicKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $publicKeyFile)))` | **缺陷点**：对**整个 PEM 文件内容**（含 `-----BEGIN/END-----` 标记与 `\r\n` 换行）整体做 Base64，产物为"PEM 整体 Base64"，与 Java 端严格解码契约不匹配 |
| 61-62 | 将 Base64 写入 `*_base64.txt` 文件 | 输出产物 |
| 80-88 | 打印 env.json / .env 配置提示（输出当前 PEM 整体 Base64 值） | 需同步改为 DER 单行 Base64 契约说明 |

**修复要点（方案 A）**：第 1/2 步生成 PEM 后，应使用 `openssl pkey -outform DER` 与 `openssl pkey -pubout -outform DER` 输出 **DER 二进制**，再对 DER 字节做 `[Convert]::ToBase64String(...)` 得到**单行 DER Base64**（或对 PEM 剥头尾去换行后拼接再 Base64，但 DER 方式更标准、无歧义）。

### 1.2 deploy/env.json（环境变量注入载体，27 行）【需更新密钥值】

**文件路径**：`deploy/env.json`

**现状（缺陷值）**：
- 第 17 行 `"RSA_PRIVATE_KEY"`：值为 **PEM 整体 Base64**。解码后为 `-----BEGIN PRIVATE KEY-----\r\n...` 多行 PEM 文本（值为 `LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t...` 开头，即 "-----BEGIN PRIVATE KEY-----" 的 Base64）。
- 第 18 行 `"RSA_PUBLIC_KEY"`：值为 **PEM 整体 Base64**。解码后为 `-----BEGIN PUBLIC KEY-----\r\n...` 多行 PEM 文本（值为 `LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0...` 开头，即 "-----BEGIN PUBLIC KEY-----" 的 Base64）。

**修复要求**：将两个值更新为 **DER 编码单行 Base64**（公钥 = X.509 SubjectPublicKeyInfo 的 DER 单行 Base64；私钥 = PKCS#8 PrivateKeyInfo 的 DER 单行 Base64），与脚本新输出严格一致；其余键值（NACOS/DB/REDIS/验证码/时区等 25 项）保持不变。

> 红线：cs.md 不记录任何真实密钥值（敏感信息红线），以上仅记录格式特征，不写入实际密钥内容。

---

## 2. Java 端解码契约代码（本次任务禁止修改，契约依据）

### 2.1 网关 RsaKeyConfig（公钥验签侧）

**文件路径**：`cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/RsaKeyConfig.java`（171 行）

**关键逻辑**：

| 行号 | 代码 | 契约含义 |
| --- | --- | --- |
| 47 | `@Value("${auth.rsa.public-key:}")` | 从配置/环境变量 `RSA_PUBLIC_KEY` 注入公钥 |
| 113 | `byte[] keyBytes = Base64.getDecoder().decode(keyContent.trim());` | **严格解码器** `Base64.getDecoder()`（非 MIME），多行/含头尾的 PEM 整体 Base64 会解码出 PEM 文本字节 → 后续解析失败 |
| 114-116 | `X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);` → `KeyFactory.getInstance("RSA").generatePublic(keySpec)` | 期望字节为 **X.509 SubjectPublicKeyInfo DER 编码** |
| 126-132 | 解码/生成失败 → `throw new IllegalArgumentException("RSA 公钥加载失败...")` | 启动失败即"RSA 公钥解析失败"（Unable to decode key / extra data at the end） |
| 154-170 | `readPemFile(filePath)` 仅作为 `publicKeyPath` 兜底（剥头尾去换行） | Base64 注入路径不走此逻辑 |

### 2.2 认证服务 RsaKeyConfig（私钥签名 + 公钥验签侧）

**文件路径**：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/RsaKeyConfig.java`（171 行）

**关键逻辑**：

| 行号 | 代码 | 契约含义 |
| --- | --- | --- |
| 36-37 | `@Value("${jwt.rsa.private-key:}")` / `@Value("${jwt.rsa.public-key:}")` | 从环境变量 `RSA_PRIVATE_KEY` / `RSA_PUBLIC_KEY` 注入 |
| 76-77 | `Base64.getDecoder().decode(privateKeyBase64.trim())` / `...decode(publicKeyBase64.trim())` | 同样**严格解码器** |
| 82-84 | `PKCS8EncodedKeySpec` → `generatePrivate` | 私钥期望字节为 **PKCS#8 PrivateKeyInfo DER 编码** |
| 88-89 | `X509EncodedKeySpec` → `generatePublic` | 公钥期望字节为 **X.509 SubjectPublicKeyInfo DER 编码** |
| 120-138 | `validateKeyPair()`：SHA256withRSA 签名 + 公钥验签 | 公钥/私钥必须成对，否则启动失败（key pair mismatch） |
| 104-112 | 失败 → `throw new IllegalStateException(...)` | 服务启动终止 |

**契约结论**：Java 端期望 env.json 注入值 = `Base64(公钥.getEncoded())`（X.509 DER 单行）与 `Base64(私钥.getEncoded())`（PKCS8 DER 单行），本次任务只改脚本侧，运行时代码零改动。

### 2.3 配置映射（注入链路，保持不变）

- `cloudoffice-gateway/src/main/resources/application.yml` 第 46-49 行：
  ```yaml
  auth:
    rsa:
      public-key: ${RSA_PUBLIC_KEY:}
      public-key-path: ${RSA_PUBLIC_KEY_PATH:}
  ```
- `cloudoffice-auth-service/src/main/resources/application.yml` 第 58-60 行：
  ```yaml
  jwt:
    rsa:
      private-key: ${RSA_PRIVATE_KEY:}
      public-key: ${RSA_PUBLIC_KEY:}
  ```
- `deploy/scripts/load-env.ps1`（35 行）：读取 `deploy/env.json`，将每个键 `Set-Item -Path "env:$($_.Name)"` 注入当前会话环境变量 —— env.json 值即最终环境变量值。
- `deploy/scripts/deploy-start-gateway.ps1` 第 24-26 行：启动前校验 `RSA_PUBLIC_KEY` 非空，否则报错提示运行 `deploy-rsa-keygen.ps1`。
- `deploy/scripts/deploy-start-auth.ps1` 第 19 行：要求 `RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY` 均非空。
- `scripts/docker/docker-compose.yml` 第 71 行（gateway）、99-100 行（auth）：`RSA_PUBLIC_KEY=${RSA_PUBLIC_KEY}` / `RSA_PRIVATE_KEY=${RSA_PRIVATE_KEY}` Docker 注入。

---

## 3. 回归报告依据（docs/cso-v0.2.5/regression-api-test.md）

**文件路径**：`docs/cso-v0.2.5/regression-api-test.md`（71 行，用户输入指定文档）

| 行号 | 内容 |
| --- | --- |
| 42-44 | **根因**：deploy/env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 **PEM 文件整体 Base64（多行，含 BEGIN/END 标记与 \r\n）**（deploy-rsa-keygen.ps1 生成格式）；Java 端 RsaKeyConfig（gateway/auth）使用严格 `Base64.getDecoder()` + `X509EncodedKeySpec`（期望 **DER 编码的 Base64，单行**），网关启动即报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）` |
| 51 | 整改建议：deploy-rsa-keygen.ps1 输出 DER 单行 Base64（或 Java 端改用 MIME 解码器并剥除 PEM 头尾），保证 env.json 密钥与代码契约一致 |
| 57、63 | 该问题属 v0.0.1 基线遗留审核项 T-02，v0.2.6 修复；修复后需重新构建启动服务，补跑 cso-api-test-v0.0.1.py 完成 TC-001~045 动态闭环 |

---

## 4. 测试参考（验证契约的正确格式样本）

### 4.1 TestRsaKeyProvider.java（gateway 测试工具类）

**文件路径**：`cloudoffice-gateway/src/test/java/org/cloudstrolling/cloudoffice/gateway/TestRsaKeyProvider.java`（69 行）

- 第 60-61 行：`String base64Key = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());`
- `PublicKey.getEncoded()` 返回 **X.509 SubjectPublicKeyInfo DER 字节**，经标准 Base64 编码即为**单行 DER Base64** —— 这正是本次修复后脚本应输出的格式（与 Java 侧 `getEncoded()` 产物等价）。

### 4.2 RsaKeyConfigTest.java（gateway 单元测试）

**文件路径**：`cloudoffice-gateway/src/test/java/org/cloudstrolling/cloudoffice/gateway/config/RsaKeyConfigTest.java`（158 行）

- 第 46 行：`testPublicKeyBase64 = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());` — 同样为 DER 单行 Base64。
- 测试断言：有效公钥可加载（getPublicKey() 返回有效 RSA PublicKey）；无效 Base64 / 非 RSA 内容抛 IllegalArgumentException。

---

## 5. deploy 目录结构与相关资产（范围盘点）

```
deploy/
├── env.json                        # 环境变量注入载体（RSA 密钥值需更新，本任务范围）
├── env.example.json                # 模板（第 17-18 行 RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 为 <占位符>，无需修改）
├── deploy.md                       # 部署文档（第 92、154 行描述 RSA 密钥 Base64 填写说明，范围外，供参考）
├── build.md                        # 编译方案文档
├── cloudoffice-{gateway,auth,biz,system}-service.jar   # 构建产物（target 输出，不入库）
├── cloudoffice-flutter-app/        # 客户端构建产物
└── scripts/
    ├── deploy-rsa-keygen.ps1       # RSA 密钥生成（Windows）【本任务修改】
    ├── deploy-rsa-keygen.sh        # RSA 密钥生成（Linux，92 行，同样存在 PEM 整体 Base64 缺陷：base64 -w0 对整个 PEM 文件编码；任务边界未含，供下游参考）
    ├── load-env.ps1 / load-env.sh  # env.json → 环境变量加载
    ├── deploy-start-{gateway,auth,biz,system}.ps1/.sh   # 服务启动脚本（校验 RSA 变量非空）
    ├── deploy-env.ps1 / deploy-env-template.ps1/.sh     # 环境模板（引用 keygen 脚本输出）
    ├── deploy-check-env.ps1/.sh    # 环境检查
    ├── deploy-db-init.ps1/.sh      # 数据库初始化
    └── build-{backend,client}.ps1/.sh  # 构建脚本
```

---

## 6. 修复实现要点汇总（供编码环节直接使用）

### 6.1 deploy-rsa-keygen.ps1 修改方向（方案 A）
1. 保留 RSA 2048 生成（`openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048`）。
2. **私钥 DER**：`openssl pkey -in "$privateKeyFile" -outform DER -out "$privateKeyDerFile"`（PKCS#8 PrivateKeyInfo DER）。
3. **公钥 DER**：`openssl pkey -in "$privateKeyFile" -pubout -outform DER -out "$publicKeyDerFile"`（X.509 SubjectPublicKeyInfo DER）。
4. **单行 Base64**：`[Convert]::ToBase64String([IO.File]::ReadAllBytes($derFile))`（默认无换行，即单行）。
5. 输出提示中明确契约：无 `-----BEGIN/END-----` 头尾、无换行、单行 DER Base64。
6. 建议保留 `*.pem` 文件（运维审计用），`*_base64.txt` 改为写入 DER 单行 Base64。

### 6.2 deploy/env.json 更新
- `RSA_PUBLIC_KEY` ← 新生成的公钥 DER 单行 Base64（与脚本输出严格一致）。
- `RSA_PRIVATE_KEY` ← 新生成的私钥 DER 单行 Base64（与脚本输出严格一致）。
- 覆盖旧 PEM 整体 Base64 值；其余 25 项键值不变。

### 6.3 契约校验（测试方法，对应 testMethod）
1. env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 不含 `-----BEGIN` / `-----END` 子串；
2. 值不含 `\r`/`\n` 换行符（单行）；
3. 值可被 `Base64.getDecoder()` 严格解码（无 extra data / 无非法字符）；
4. 解码字节可经 `X509EncodedKeySpec`（公钥）/ `PKCS8EncodedKeySpec`（私钥）成功构造 RSA Key（可与 Java 侧 getEncoded() 产物对比验证）；
5. 网关 + auth 启动无 RSA 解析异常，RS256 签名验签链路正常（由 TASK-003 启动验证承接）。

### 6.4 注意事项（敏感信息红线）
- 私钥不得写入日志、不得进入代码仓库（deploy/env.json 的 RSA 密钥值需确认 .gitignore 是否覆盖，或随 env.json 策略处理）；
- cs.md / context.md 不记录任何真实密钥值。

---

## 7. 可复用代码/工具清单

| 复用点 | 位置 | 说明 |
| --- | --- | --- |
| 严格 Base64 解码契约 | gateway/auth `RsaKeyConfig`（`Base64.getDecoder()` + X509/PKCS8EncodedKeySpec） | 脚本输出必须对齐该契约（只读，不改） |
| 正确 DER 单行 Base64 样本 | `TestRsaKeyProvider.java` 第 60-61 行、`RsaKeyConfigTest.java` 第 46 行 | `Base64.getEncoder().encodeToString(key.getEncoded())` 即目标格式 |
| 环境变量注入链路 | `deploy/scripts/load-env.ps1`（env.json → env:） | env.json 值直接成为进程环境变量，修改 env.json 即完成注入 |
| OpenSSL DER 输出能力 | 系统 OpenSSL（脚本已依赖） | `openssl pkey -outform DER` / `-pubout -outform DER` 获取 DER 二进制 |
| 部署文档格式说明 | `deploy/deploy.md` 第 92、154 行 | 若文档提及"Base64 内容"，编码后可同步补充 DER 单行契约说明（范围外，视任务边界） |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
