# 网络资料查询结果（ws.md · TASK-002 统一 RSA 密钥格式契约为 DER 编码单行 Base64）

**任务编号**：TASK-002
**版本号**：v0.2.6
**查询人**：WS（网络查询）
**查询日期**：2026-08-09
**查询目标**：为修改 `deploy/scripts/deploy-rsa-keygen.ps1`（方案 A：脚本侧输出 DER 编码单行 Base64）提供权威依据：OpenSSL 在 Windows PowerShell 下生成 RSA 密钥对并输出 DER 格式的官方命令、PKCS#8 私钥 / X.509 公钥 DER 编码规范、PowerShell 调用 openssl 与 Base64 单行编码的可靠写法、Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约的官方文档。

---

## 1. 任务所需三方组件识别

| 组件 | 用途 | 版本 | 兼容性结论 |
| --- | --- | --- | --- |
| OpenSSL CLI（openssl.exe） | 生成 RSA 2048 密钥对，输出 DER 格式（私钥 PKCS#8 / 公钥 X.509） | 脚本依赖，未固定；1.1.x / 3.x 均支持 `-outform DER`（3.0+ 推荐 genpkey） | **兼容**：`openssl genpkey -outform DER`、`openssl pkey -outform DER / -pubout -outform DER` 为长期稳定功能，官方文档示例与 OpenSSL 官方测试（15-test_pkey.t）均在使用 |
| Java JDK 密钥规范类（java.security.spec） | 契约权威依据：`X509EncodedKeySpec`（公钥）/ `PKCS8EncodedKeySpec`（私钥）+ `KeyFactory` | 项目 Java 21 | **完全兼容**：查询文档为 Java SE 21 & JDK 21 官方 API 文档，与项目版本一致 |
| .NET `Convert.ToBase64String` / `System.IO.File.ReadAllBytes` | PowerShell 中做单行 Base64 编码 | .NET Framework（PowerShell 5.1 内置） | **完全兼容**：`ToBase64String(byte[])` 自 .NET 1.1 起存在，默认输出**无换行**的单行 Base64，Windows PowerShell 5.1 原生可用 |

---

## 2. OpenSSL 官方文档要点（openssl.org，docs.openssl.org）

### 2.1 openssl-pkey（私钥/公钥处理，PEM ↔ DER 转换核心命令）

官方文档：<https://docs.openssl.org/master/man1/openssl-pkey/>

关键选项（原文摘录）：
- `-outform DER|PEM`：密钥输出格式，**默认 PEM**；指定 `DER` 输出二进制 DER 编码。
- `-inform DER|PEM|P12`：输入格式（从 DER 输入时需指定 `-inform DER`）。
- `-pubout`：仅输出公钥部分（默认输出私钥+公钥）。与 `-outform DER` 组合即得到 **X.509 SubjectPublicKeyInfo 的 DER 二进制**。
- `-traditional`：默认私钥输出为标准格式即 **PKCS#8**（`PrivateKeyInfo`）；`-traditional` 才使用旧式传统格式。OpenSSL CHANGES.md 明确记录：`openssl-pkey(1)` 在 `-outform DER` 输出私钥时**默认产生 PKCS#8 格式**（3.5→3.6 变更说明中确认，实际行为长期如此）。

官方示例（原文摘录）：
- 私钥 PEM → DER 转换：`openssl pkey -in key.pem -outform DER -out keyout.der`
- 输出公钥部分：`openssl pkey -in key.pem -pubout -out pubkey.pem`

OpenSSL 官方测试（test/recipes/15-test_pkey.t，源码库）验证了公钥 DER 输出：
```
openssl pkey -in <key> -pubout -outform DER -out pub_unc.der
```
即 `-pubout -outform DER` 输出 **SubjectPublicKeyInfo DER 二进制**（官方测试以 P-256 为例，RSA 同理，输出结构同为 SubjectPublicKeyInfo，见 i2d_PUBKEY：编码结构为 "SubjectPublicKeyInfo"）。

### 2.2 openssl-genpkey（RSA 密钥对生成命令，脚本现用命令）

官方文档：<https://docs.openssl.org/master/man1/openssl-genpkey/>

关键选项（原文摘录）：
- `-outform DER|PEM`：输出格式，**默认 PEM**；指定 `DER` 直接生成 DER 二进制私钥。
- `-outpubkey filename`：**同时输出公钥到指定文件**（不指定则不输出公钥）。
- `-algorithm RSA` + `-pkeyopt rsa_keygen_bits:2048`：生成 2048 位 RSA 密钥（默认位数即 2048、公钥指数默认 65537）。
- 官方注释：推荐使用 genpkey 而非算法特定命令（genrsa 等）。

官方示例（原文摘录）：`openssl genpkey -algorithm RSA -out key.pem`（默认参数生成 RSA 私钥）。

### 2.3 结论：DER 输出两条可行路径（供脚本选择）

| 路径 | 命令 | 产物 |
| --- | --- | --- |
| A. 直接生成 DER（推荐，最少转换步骤） | `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform DER -out priv.der`<br>`openssl pkey -in priv.der -inform DER -pubout -outform DER -out pub.der` | priv.der = PKCS#8 PrivateKeyInfo DER；pub.der = X.509 SubjectPublicKeyInfo DER |
| B. 保留 PEM 审计副本，再转 DER（兼容现有脚本结构） | `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out priv.pem`（现状第 46 行）<br>`openssl pkey -in priv.pem -outform DER -out priv.der`（新增）<br>`openssl pkey -in priv.pem -pubout -outform DER -out pub.der`（替换现状第 52 行） | 同左，且保留 `*.pem` 供运维审计（cs.md 6.1 建议） |

**重要**：无论哪条路径，DER 二进制**绝不包含** `-----BEGIN/END-----` 头尾标记，也不含任何换行符——这正是 Java 严格解码器需要的字节。

---

## 3. Java 端解码契约权威依据（Oracle 官方 API 文档，Java SE 21）

### 3.1 X509EncodedKeySpec（公钥契约，对应网关/auth 公钥解码）

官方文档：<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/X509EncodedKeySpec.html>

原文摘录：
- "This class represents the ASN.1 encoding of a public key, encoded according to the ASN.1 type `SubjectPublicKeyInfo`."（代表按 X.509 标准 ASN.1 类型 `SubjectPublicKeyInfo` 编码的公钥）
- `SubjectPublicKeyInfo ::= SEQUENCE { algorithm AlgorithmIdentifier, subjectPublicKey BIT STRING }`
- `getFormat()` 返回字符串 `"X.509"`。
- 结论：`Base64.getDecoder().decode(值)` 后的字节必须是 **SubjectPublicKeyInfo DER 结构**，即 OpenSSL `-pubout -outform DER` 的产物；也是 Java `PublicKey.getEncoded()`（项目 TestRsaKeyProvider 第 60-61 行所用）的产物，两者等价。

### 3.2 PKCS8EncodedKeySpec（私钥契约，对应 auth 私钥解码）

官方文档：<https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/PKCS8EncodedKeySpec.html>

原文摘录：
- "This class represents the ASN.1 encoding of a private key, encoded according to the ASN.1 type `PrivateKeyInfo`."（代表按 PKCS#8 标准 ASN.1 类型 `PrivateKeyInfo` 编码的私钥）
- `PrivateKeyInfo ::= SEQUENCE { version Version, privateKeyAlgorithm PrivateKeyAlgorithmIdentifier, privateKey PrivateKey, attributes [0] IMPLICIT Attributes OPTIONAL }`
- `getFormat()` 返回字符串 `"PKCS#8"`。
- 结论：`Base64.getDecoder().decode(值)` 后的字节必须是 **PKCS#8 PrivateKeyInfo DER 结构**，即 OpenSSL `pkey -outform DER`（默认 PKCS#8）的产物；也是 Java `PrivateKey.getEncoded()` 的产物，两者等价。

### 3.3 Java 端组合解码模式（与项目 RsaKeyConfig 逐字一致的真实案例）

GitHub 多个知名项目使用与 RsaKeyConfig 完全相同的模式（`Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` + `KeyFactory` RSA）：

- **apache/solr**（Apache-2.0）`CryptoKeys.deserializeX509PublicKey`：`KeyFactory.getInstance("RSA")` + `new X509EncodedKeySpec(Base64.getDecoder().decode(pubKey))` + `generatePublic`。
- **binarywang/WxJava**（Apache-2.0）`PemUtils.java`：先 `.replace("-----BEGIN PUBLIC KEY-----", "").replace("-----END PUBLIC KEY-----", "").replaceAll("\\s+", "")` 再 `new X509EncodedKeySpec(Base64.getDecoder().decode(publicKey))` —— 反例佐证：**严格解码器不接受含 PEM 头尾与空白的字符串，必须先行剥除**，若输入为 DER 单行 Base64 则无需任何预处理。
- **cryptomator/android**（GPL-3.0）、**1Panel-dev/CordysCRM**：`new X509EncodedKeySpec(Base64.getDecoder().decode(KEY))` 直接解码单行 Base64 即成功。

> 佐证结论：项目 gateway/auth `RsaKeyConfig` 的 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 契约 = 主流标准做法；脚本只需输出与 Java `getEncoded()` 等价的 **DER 单行 Base64** 即可零改动对齐。

---

## 4. PowerShell 调用 openssl 与 Base64 单行编码的可靠写法

### 4.1 PowerShell 调用 openssl（官方/社区权威写法）

- 用**调用运算符 `&`** 调用（路径含空格时必要）：`& openssl genpkey ...`；PowerShell 中也可直接写 `openssl ...`（PATH 中存在时）。
- **必须检查退出码**：openssl 失败时用 `$LASTEXITCODE -ne 0` 判断并报错退出（GitHub 真实案例 PerryTS/perry scripts/smoke_updater.ps1 采用此模式）：

```powershell
& openssl genpkey -algorithm ED25519 -outform DER -out $PrivDer 2>$null
if ($LASTEXITCODE -ne 0) { Write-Error 'openssl genpkey failed'; exit 1 }
& openssl pkey -in $PrivDer -inform DER -pubout -outform DER -out $PubDer 2>$null
if ($LASTEXITCODE -ne 0) { Write-Error 'openssl pkey failed'; exit 1 }
$PubBytes = [System.IO.File]::ReadAllBytes($PubDer)
$PubKeyB64 = [Convert]::ToBase64String($PubBytes)
```

- 注意：该案例为 ED25519（32 字节公钥截取），本项目为 RSA 2048，**不需要截取字节**，直接对 DER 文件全部字节 Base64 即可。

### 4.2 Base64 单行编码：`[Convert]::ToBase64String(byte[])`（Microsoft Learn 官方文档）

官方文档：<https://learn.microsoft.com/en-us/dotnet/api/system.convert.tobase64string>

原文要点：
- `Convert.ToBase64String(byte[] inArray)`：将字节数组转换为 Base64 字符串。
- **单参数重载默认不插入换行**；仅当显式传 `Base64FormattingOptions.InsertLineBreaks` 时才每 76 个字符插入 CRLF（`options` 参数为 `None` 时不插入换行）。
- 结论：`[Convert]::ToBase64String([IO.File]::ReadAllBytes($derFile))` 输出**无换行的单行 Base64**，与契约要求完全吻合；切勿使用 `InsertLineBreaks` 重载。

### 4.3 Windows PowerShell 5.1 下的注意事项

- PowerShell 5.1（Windows 内置）基于 .NET Framework 4.x，`[Convert]::ToBase64String`、`[System.IO.File]::ReadAllBytes`、`[Convert]::FromBase64String` 均原生可用，无需安装任何模块。
- 读文件用 `[IO.File]::ReadAllBytes((Resolve-Path $file))`（现有脚本第 58-59 行的写法，`Resolve-Path` 返回 PathInfo 可隐式转字符串）可靠；也可 `Get-Content -Raw -Encoding Byte`（仅 PS 5.1 兼容写法，不推荐混用）。
- 脚本内写 `*_base64.txt` 时用 `[IO.File]::WriteAllText($file, $b64, [Text.Encoding]::ASCII)` 或 `Set-Content -NoNewline`，避免追加换行破坏单行契约。
- PowerShell 变量名/参数不要与 openssl 关键字冲突；`-out`、`-outform` 等直接透传给 openssl 即可（现有脚本已如此工作）。

---

## 5. 版本兼容性核对结论

| 项目 | 使用版本 | 资料版本 | 兼容性 | 说明 |
| --- | --- | --- | --- | --- |
| Java JDK | Java 21（Spring Boot 3.2.5） | Java SE 21 & JDK 21 官方 API 文档 | ✅ 完全兼容 | X509EncodedKeySpec/PKCS8EncodedKeySpec 自 JDK 1.2 起存在（Since: 1.2），行为跨版本稳定 |
| OpenSSL | 未固定（脚本依赖系统安装） | docs.openssl.org master（对应 3.x） | ✅ 兼容 | `genpkey/pkey -outform DER` 在 OpenSSL 1.1.x 与 3.x 均支持；CHANGES.md 确认 DER 私钥默认 PKCS#8。若生产环境为 3.x，推荐直接 `genpkey -outform DER` 生成 |
| PowerShell | Windows PowerShell 5.1 | Microsoft Learn（.NET Framework 4.8 视图） | ✅ 完全兼容 | `ToBase64String(byte[])` 自 .NET 1.1 起可用；PowerShell 5.1 无需额外安装 |

---

## 6. 编码实现建议（供 code 环节直接使用）

### 6.1 deploy-rsa-keygen.ps1 修改方案（方案 A，基于路径 B 保留 PEM 审计副本）

```powershell
# 1. 生成 PEM 私钥（保留现状第 46 行，供运维审计）
& openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out "$privateKeyFile"
if ($LASTEXITCODE -ne 0) { Write-Error 'openssl genpkey 失败'; exit 1 }

# 2. 私钥转 DER（PKCS#8 PrivateKeyInfo）——新增
& openssl pkey -in "$privateKeyFile" -outform DER -out "$privateKeyDerFile"
if ($LASTEXITCODE -ne 0) { Write-Error 'openssl pkey 私钥转 DER 失败'; exit 1 }

# 3. 公钥转 DER（X.509 SubjectPublicKeyInfo）——替换现状第 52 行
& openssl pkey -in "$privateKeyFile" -pubout -outform DER -out "$publicKeyDerFile"
if ($LASTEXITCODE -ne 0) { Write-Error 'openssl pkey 公钥转 DER 失败'; exit 1 }

# 4. DER 二进制 → 单行 Base64（替换现状第 58-59 行对 PEM 整体 Base64 的缺陷写法）
$privateKeyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $privateKeyDerFile)))
$publicKeyBase64  = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $publicKeyDerFile)))
```

### 6.2 契约自校验（脚本内可加，对应 testMethod）

```powershell
# 校验：不含 PEM 头尾、不含换行、可被严格 Base64 解码（.NET FromBase64String 与 Java Base64.getDecoder 同为严格解码）
if ($privateKeyBase64 -match '-----BEGIN' -or $privateKeyBase64 -match '\r|\n') { Write-Error '私钥格式不符合 DER 单行 Base64 契约'; exit 1 }
try { [void][Convert]::FromBase64String($privateKeyBase64) } catch { Write-Error '私钥 Base64 严格解码失败'; exit 1 }
# 公钥同理
```

### 6.3 deploy/env.json 更新要点

- `RSA_PUBLIC_KEY` ← 脚本输出的公钥 DER 单行 Base64（`LS0t...` PEM 前缀 Base64 必须消失，值应为 `MIIBIjANBgkqhkiG9w0BAQEF...` 风格开头）。
- `RSA_PRIVATE_KEY` ← 脚本输出的私钥 DER 单行 Base64（应为 `MIIEvQIBADANBgkqhkiG9w0BAQEFA...` 风格开头，即 PKCS#8 魔数 `3082` 的 Base64）。
- 其余 25 项键值不动；两值必须与脚本新输出严格一致（成对生成）。
- 校验方式（与 TASK-002 testMethod 一致）：值不含 `-----BEGIN`/`-----END` 子串、不含 `\r`/`\n`、可被严格 Base64 解码、解码字节可经 X509/PKCS8EncodedKeySpec 构造密钥。

### 6.4 判别特征（快速自查）

| 特征 | 正确（DER 单行 Base64） | 错误（PEM 整体 Base64，现状缺陷） |
| --- | --- | --- |
| 值前缀解码后 | 二进制 DER 结构（公钥 0x30 0x82... / 私钥 0x30 0x82...） | `-----BEGIN PUBLIC KEY-----` 等 PEM 文本 |
| 原始 Base64 值开头 | 公钥 `MIIBIjAN...` / 私钥 `MIIEvQIBAD...` | `LS0tLS1CRUdJTiBQVUJMSUMgS0VZ...`（即 "-----BEGIN" 的 Base64） |
| 是否含换行 | 否（单行） | 是（PEM 每 64 字符换行） |
| Java `Base64.getDecoder()` 严格解码 | ✅ 成功 | ❌ 解码出 PEM 文本字节，KeySpec 解析报错（extra data at the end / Unable to decode key） |

---

## 7. 注意事项与红线（敏感信息）

1. **私钥不得入库、不得写入日志**：deploy/env.json 为部署资产（SAD 1.2 部署资产约束），密钥值随 env.json 策略处理（确认 .gitignore 覆盖或部署时生成注入）；脚本输出提示仅打印格式契约说明，**不打印完整密钥值**（若打印请脱敏/截断）。
2. 本任务只允许修改 `deploy/scripts/deploy-rsa-keygen.ps1` 与 `deploy/env.json`；Java 端 RsaKeyConfig、配置映射（application.yml）、load-env.ps1、docker-compose.yml 均不动（cs.md 2.x 依据）。
3. `deploy/scripts/deploy-rsa-keygen.sh`（Linux 版）存在同类缺陷（`base64 -w0` 对整个 PEM 编码），但不在本任务边界内，供下游参考。
4. ws.md 不记录任何真实密钥值（敏感信息红线）。

---

## 8. 参考资料清单

| 资料 | 来源 | 权威性 |
| --- | --- | --- |
| openssl-pkey 命令文档（-outform DER / -pubout / PKCS#8） | <https://docs.openssl.org/master/man1/openssl-pkey/> | 官方 |
| openssl-genpkey 命令文档（-outform DER / -algorithm RSA / rsa_keygen_bits） | <https://docs.openssl.org/master/man1/openssl-genpkey/> | 官方 |
| OpenSSL CHANGES.md（pkey DER 输出默认 PKCS#8 确认） | <https://github.com/openssl/openssl/blob/master/CHANGES.md> | 官方 |
| OpenSSL 官方测试 15-test_pkey.t（-pubout -outform DER 输出 SubjectPublicKeyInfo） | <https://github.com/openssl/openssl/blob/master/test/recipes/15-test_pkey.t> | 官方 |
| X509EncodedKeySpec（Java SE 21 官方 API） | <https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/X509EncodedKeySpec.html> | 官方 |
| PKCS8EncodedKeySpec（Java SE 21 官方 API） | <https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/PKCS8EncodedKeySpec.html> | 官方 |
| Convert.ToBase64String（Microsoft Learn） | <https://learn.microsoft.com/en-us/dotnet/api/system.convert.tobase64string> | 官方 |
| PowerShell + openssl DER + ToBase64String 实战样例 | <https://github.com/PerryTS/perry/blob/main/scripts/smoke_updater.ps1> | 社区（MIT，生产仓库） |
| Java 端同款解码模式真实案例 | apache/solr CryptoKeys、binarywang/WxJava PemUtils、cryptomator/android、1Panel-dev/CordysCRM | 社区（Apache-2.0 等） |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
