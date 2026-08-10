# 网络查询报告（#TASK-007 对齐 deploy-rsa-keygen.ps1 / .sh RSA 密钥输出契约）

## 0. 任务概述

- **任务**：以 deploy-rsa-keygen.ps1（v0.2.6，已对齐 ADR-015）为基准，重构 deploy-rsa-keygen.sh，使双平台输出契约一致——均输出 **DER 编码单行 Base64**（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，无 PEM 头尾、无换行），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约一致（ADR-015，v0.2.6 确立）；提供契约自校验（F-011 / US-004）。
- **查询对象**：OpenSSL（genpkey / pkcs8 / pkey / enc 命令）、Java 标准库（Base64 / X509EncodedKeySpec / PKCS8EncodedKeySpec，JDK 21）、base64 命令行工具（GNU coreutils / BSD macOS）、PKCS#8 与 X.509 标准（RFC 5208 / RFC 5280）。
- **查询方式**：官方文档（docs.openssl.org 3.0 man pages、docs.oracle.com Java SE 21 API、GNU coreutils manual、RFC Editor）+ 本机实测验证（Git for Windows OpenSSL 3.5.5 + JDK 21.0.9 端到端验证）+ GitHub 真实工程样例。
- **边界**：.gitignore 治理（F-012）属下游 TASK-010，本任务不涉及；Java 端代码不得修改（ADR-015 明示 Java 端零改动）。

## 1. 官方文档查询结果

### 1.1 OpenSSL genpkey（生成 RSA 私钥，官方文档 openssl-genpkey，OpenSSL 3.0+）
- 命令：`openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 [-outform PEM] -out <file>`；
- `-pkeyopt rsa_keygen_bits:numbits`：RSA 密钥位数，**未指定时默认 2048**；
- `-pkeyopt rsa_keygen_pubexp:value`：公钥指数，默认 65537（0x10001）；
- `-outform DER|PEM`：输出格式，默认 PEM；
- 官方示例：`openssl genpkey -algorithm RSA -out key.pem`（默认参数生成 RSA 密钥）。
- **结论**：.ps1 现有 `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem` 与官方用法完全一致，可直接沿用。

### 1.2 OpenSSL pkcs8（PKCS#8 私钥转换，官方文档 openssl-pkcs8，OpenSSL 3.0+）
- 命令：`openssl pkcs8 -topk8 -nocrypt -in <pem> -outform DER -out <der>`；
- `-topk8`：读取任意格式私钥并**输出 PKCS#8 格式**（不加则要求输入已是 PKCS#8）；
- `-nocrypt`：输出**未加密的 PrivateKeyInfo**（UnencryptedPrivateKeyInfo，即 Java PKCS8EncodedKeySpec 所需）；
- `-outform DER|PEM`：默认 PEM，DER 输出无加密（PKCS#8 加密信息在 ASN.1 层，传统格式在 PEM 层）；
- 官方示例（与 .ps1 完全同构）：`openssl pkcs8 -in key.pem -topk8 -nocrypt -out enckey.pem`；
- **重要提示**（文档 NOTES）：`-nocrypt` 输出未加密 PrivateKeyInfo，文档明示"某些软件（如部分 Java 代码签名软件）使用未加密私钥"——与 Java `PKCS8EncodedKeySpec` 契约吻合。
- **结论**：`.ps1 的 `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER -out private_key.der` 为官方标准用法，.sh 必须逐字对齐。

### 1.3 OpenSSL pkey（公私钥处理，官方文档 openssl-pkey，OpenSSL 3.0+）
- 公钥导出：`openssl pkey -in <pem> -pubout -outform DER -out <der>`（`-pubout` 仅输出公钥部分；`-outform DER` 输出 DER）；
- 私钥转换：`openssl pkey -in key.pem -outform DER -out key.der`（官方示例"To convert a private key from PEM to DER format"）；
- **关键差异**（-traditional 选项文档原文）：“Normally a private key is written using standard format: this is **PKCS#8 form** ... If the **-traditional** option is specified then the older **'traditional' format** is used instead.”——文档层面 `pkey` 默认输出应为 PKCS#8，但**实测（见 §3）OpenSSL 3.5.5 `pkey -outform DER` 输出 PKCS#1**（即传统格式），印证 .ps1 第 62-64 行注释中"Git for Windows OpenSSL 3.x 的 pkey -outform DER 默认输出传统 PKCS#1，与 PKCS8EncodedKeySpec 不兼容（报 algid parse error, not a sequence）"的工程经验；
- **结论**：私钥 DER **必须**经 `pkcs8 -topk8 -nocrypt -outform DER` 生成，不能用 `pkey -outform DER` 直出；公钥 DER 用 `pkey -pubout -outform DER` 正确（X.509 SubjectPublicKeyInfo）。

### 1.4 OpenSSL enc base64（单行 Base64 编码，官方文档 openssl-enc，OpenSSL 3.0+）
- 命令：`openssl base64 -A -in <der>`（等价 `openssl enc -base64 -A`）；
- `-a`/`-base64`：base64 处理数据；**不带 -A 时编码每 64 字符插入换行**；
- `-A`：**编码输出不含任何换行符**（文档原文："base64 encoding produces output without any newline character"）；解码时不要求换行；
- **BUGS 提示**：`-A` 用于大文件时存在问题（"when used with large files doesn't work properly"）——DER 私钥仅约 1.2KB，不受影响；
- **结论**：macOS/BSD 兼容分支 `openssl base64 -A` 官方语义正确（单行、无换行），可作为 `base64 -w0` 的替代分支。

### 1.5 Java Base64（官方文档 Java SE 21 & JDK 21，java.util.Base64）
- `Base64.getDecoder()`：返回 **Basic 类型**解码器，**编码器不添加任何换行符（line feed）**，**解码器拒绝字母表之外的任何字符**（文档原文："The decoder rejects data that contains characters outside the base64 alphabet"）——即**严格 Base64**；
- `getMimeDecoder()`（宽松，忽略非字母表字符与换行）与 `getDecoder()`（严格）语义不同，本项目使用 `getDecoder()`（auth/gateway RsaKeyConfig 静态核对一致）；
- **结论**：脚本契约自校验的"严格解码"必须等价于"拒绝换行 + 拒绝非法字符 + 拒绝非法长度"，与 Java Basic 解码器一致（实测见 §3.5）。

### 1.6 Java X509EncodedKeySpec / PKCS8EncodedKeySpec（官方文档 Java SE 21 & JDK 21）
- `X509EncodedKeySpec`：表示 **SubjectPublicKeyInfo** 的 ASN.1 编码（文档原文给出结构：`SEQUENCE { algorithm AlgorithmIdentifier, subjectPublicKey BIT STRING }`）；`getFormat()` 返回 `"X.509"`；
- `PKCS8EncodedKeySpec`：表示 **PrivateKeyInfo** 的 ASN.1 编码（文档原文给出结构：`SEQUENCE { version Version, privateKeyAlgorithm PrivateKeyAlgorithmIdentifier, privateKey PrivateKey, attributes [0] IMPLICIT Attributes OPTIONAL }`）；`getFormat()` 返回 `"PKCS#8"`；
- 两构造器均不校验内容（仅封装字节数组），**实际解析发生在 KeyFactory.generatePrivate/generatePublic**：若私钥为 PKCS#1（传统格式），`generatePrivate(new PKCS8EncodedKeySpec(...))` 抛 `InvalidKeySpecException`（`algid parse error, not a sequence`——与 .ps1 注释描述一致）；
- **结论**：脚本产物必须是 X.509（公钥）/ PKCS#8（私钥）DER 结构，否则 Java 端解析失败。

### 1.7 base64 命令行（GNU coreutils 9.11 官方手册 + FreeBSD/macOS man page）
- **GNU base64**（Linux、Git for Windows）：`-w cols`（`--wrap=cols`）编码时按 cols 字符换行，**默认 76 字符换行，`-w 0` 完全禁用换行**；`-d` 解码，解码时**换行总是被接受**（"newlines are always accepted"），`-i` 忽略其他非法字节；
  - ⚠️ 注意：GNU `base64 -d` 解码**默认接受换行**（与 Java `getDecoder()` 严格语义不同），因此契约自校验必须**单独校验"无换行"**（grep 检查），不能只依赖 `base64 -d` 成败；
- **BSD/macOS base64**（FreeBSD man page，macOS 同源）：`base64 [-d] [-w column] [file]`；编码器**默认不产生框架行（framing lines）**；`-w` 为兼容 GNU 而接受，但 `-w 0` 行为在不同版本未保证（部分版本仅 `-w` 有语义）——因此 **macOS 分支应使用 `openssl base64 -A`**（§1.4）而非依赖 `base64 -w0`；
- **结论**：.sh 单行 Base64 实现 = `base64 -w0 <der>`（GNU/Linux/Git Bash）+ `openssl base64 -A <der>`（macOS/BSD 兼容分支），与 cs.md §8 建议一致。

### 1.8 RFC 5208（PKCS#8 v1.2，RFC Editor 官方文本）
- `PrivateKeyInfo ::= SEQUENCE { version Version, privateKeyAlgorithm AlgorithmIdentifier, privateKey PrivateKey, attributes [0] IMPLICIT Attributes OPTIONAL }`；`Version ::= INTEGER`（本版本为 0）；`PrivateKeyAlgorithmIdentifier ::= AlgorithmIdentifier`；`PrivateKey ::= OCTET STRING`；
- 对 RSA：`privateKeyAlgorithm` 为 rsaEncryption（OID 1.2.840.113549.1.1.1）+ NULL 参数；`privateKey` 内嵌 PKCS#1 `RSAPrivateKey` 的 BER 编码；
- **结论**：本任务私钥 DER 结构标准依据（asn1parse 实测见 §3.4）。

### 1.9 X.509 SubjectPublicKeyInfo（RFC 5280 §4.1 / Java 文档 §1.6）
- `SubjectPublicKeyInfo ::= SEQUENCE { algorithm AlgorithmIdentifier, subjectPublicKey BIT STRING }`；对 RSA 2048：`SEQUENCE(30 82 01 22) + algId SEQUENCE(30 0D) + rsaEncryption OID(06 09 ...) + NULL(05 00) + BIT STRING(03 ...)`。

## 2. DER 结构偏移校验依据（契约自校验核心，已实测确认）

### 2.1 私钥（PKCS#8 PrivateKeyInfo，RSA 2048 实测 1218 字节）
```
偏移  字节           含义
0     30              SEQUENCE 标签
1     82              长格式长度
2-3   02 5C           长度 1218
4     02              version INTEGER 标签（PKCS#1 此处同样是 02，无法区分）
5-6   01 00           version = 0
7     30              AlgorithmIdentifier SEQUENCE 标签 ← 区分点
                       （PKCS#1 偏移 7 是 modulus INTEGER 0x02）
8     0D              algId 长度 13
9     06 09 2A 86 48 86 F7 0D 01 01 01   rsaEncryption OID
20    05 00           NULL 参数
22    04 82 04 4B     OCTET STRING（内嵌 PKCS#1 RSAPrivateKey，实测以 30 82 04 A4 开头）
```
- **自校验判定**：`len ≥ 16 && bytes[0]=0x30 && bytes[7]=0x30`（与 .ps1 第 102-106 行一致）；
- 本机实测：**pkcs8 链路** [0]=0x30、[4]=0x02、[7]=0x30 ✅；**pkey 直出链路** [0]=0x30、[4]=0x02、[7]=0x02 ❌（PKCS#1）——两个链路仅 [7] 不同，自校验可精确拦截。

### 2.2 公钥（X.509 SubjectPublicKeyInfo，RSA 2048 实测 294 字节）
```
偏移  字节           含义
0     30              SEQUENCE 标签
1     82              长格式长度
2-3   01 22           长度 294
4     30              AlgorithmIdentifier SEQUENCE 标签
5     0D              algId 长度 13
6     06 09 2A 86 48 86 F7 0D 01 01 01   rsaEncryption OID
16    05 00           NULL 参数
19    03              BIT STRING 标签 ← 结构固定点（对 rsaEncryption 恒定）
20    82 01 0F 00     BIT STRING 长度 + 未用位 0
24    30              RSAPublicKey SEQUENCE（内嵌 PKCS#1 RSAPublicKey）
```
- **自校验判定**：`len ≥ 24 && bytes[0]=0x30 && bytes[4]=0x30 && bytes[19]=0x03`（与 .ps1 第 107-111 行一致）；
- 说明：偏移 19 的 BIT STRING 位置依赖算法标识符固定为 rsaEncryption + NULL（本任务固定 RSA 2048，成立；实测 [19]=0x03 ✅）。

## 3. 本机实测验证（win32，Git for Windows OpenSSL 3.5.5 + JDK 21.0.9，端到端）

> 实测目录：`C:\Users\jenemy\AppData\Local\Temp\opencode\rsa-test`（临时目录，非项目内）。当前项目环境为 Windows，.sh 的 Linux 行为以官方文档 + 样例为据。

### 3.1 环境
- OpenSSL：`C:\Program Files\Git\usr\bin\openssl.exe`，版本 **OpenSSL 3.5.5**（Git for Windows 自带，未加入 PATH）；
- Java：`C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\`，**OpenJDK 21.0.9 LTS**；
- base64：Git for Windows GNU coreutils base64。

### 3.2 命令链路实测（与 .ps1 完全一致）
| 命令 | 结果 |
| --- | --- |
| `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem` | ✅ 生成 PEM 私钥 |
| `openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem` | ✅ 生成 PEM 公钥 |
| `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER -out private_key.der` | ✅ **PKCS#8**：len=1218，[0]=0x30，[4]=0x02，[7]=0x30 |
| `openssl pkey -in private_key.pem -pubout -outform DER -out public_key.der` | ✅ **X.509**：len=294，[0]=0x30，[4]=0x30，[19]=0x03 |
| `openssl pkey -in private_key.pem -outform DER`（对照实验） | ❌ **PKCS#1**：len=1192，[0]=0x30，[4]=0x02，[7]=0x02 —— **实证 .ps1 注释：pkey -outform DER 直出传统 PKCS#1** |

### 3.3 单行 Base64 实测（三者一致）
| 方式 | 输出长度 | 含换行 | 含 PEM 标记 |
| --- | --- | --- | --- |
| GNU `base64 -w0 private_key.der` | 1624 | 否 | 否 |
| `openssl base64 -A -in private_key.der` | 1624 | 否 | 否 |
| PowerShell `[Convert]::ToBase64String(...)` | 1624（与 GNU 逐字符一致） | 否 | 否 |
| 旧 .sh 错误做法 `base64 -w0 private_key.pem` | 2272 | 否 | **含 BEGIN 标记**（2272 字符远大于 DER 单行的 1624） |

### 3.4 asn1parse 结构核验（私钥 DER）
```
0:d=0  hl=4 l=1214 cons: SEQUENCE
4:d=1  hl=2 l=   1 prim: INTEGER           :00        ← version=0
7:d=1  hl=2 l=  13 cons: SEQUENCE                     ← AlgorithmIdentifier
9:d=2  hl=2 l=   9 prim: OBJECT            :rsaEncryption
20:d=2 hl=2 l=   0 prim: NULL
22:d=1 hl=4 l=1192 prim: OCTET STRING      [HEX DUMP]:308204A4...（内嵌 PKCS#1 RSAPrivateKey）
```
与 RFC 5208 PrivateKeyInfo 结构完全一致。

### 3.5 Java 端到端解码验证（契约一致性最强实证）
用 OpenSSL 生成产物经单行 Base64 后，由 Java 21 程序验证：
- `Base64.getDecoder().decode()` 严格解码：✅ 私钥 1218B / 公钥 294B；
- `new PKCS8EncodedKeySpec(priBytes)` → `KeyFactory.generatePrivate`：✅ **RSA/PKCS#8 解析成功**；
- `new X509EncodedKeySpec(pubBytes)` → `KeyFactory.generatePublic`：✅ **RSA/X.509 解析成功**；
- `SHA256withRSA` 私钥签名 + 公钥验签：✅ **true（公私钥成对）**；
- 严格解码语义：对含 `\r\n` 的 Base64 输入，`Base64.getDecoder().decode()` 抛 `IllegalArgumentException` ✅（实证 Basic 解码器拒绝换行，与 .NET `[Convert]::FromBase64String` 实测行为一致）。

## 4. 版本兼容性核对

| 组件 | 本项目版本 | 资料版本 | 兼容性结论 |
| --- | --- | --- | --- |
| OpenSSL（Windows 运行时） | 3.5.5（Git for Windows 实测） | 官方文档 3.0+ | ✅ 命令语法与 3.0 文档一致；`pkcs8 -topk8 -nocrypt -outform DER`、`pkey -pubout -outform DER`、`genpkey` 均可用；实测确认 `pkey -outform DER` 私钥直出 PKCS#1 的兼容性陷阱 |
| OpenSSL（Linux 部署目标） | 未锁定具体版本（系统自带，通常 ≥1.1.1） | 3.0 文档 | ✅ 上述命令自 1.1.1 起均为标准用法（`-iter` 选项 1.1.0 加入、`-engine` 3.0 弃用均不影响本任务命令）；建议脚本运行前 `openssl version` 预检（.ps1 已有，.sh 对齐） |
| Java | JDK 21.0.9 LTS | Java SE 21 API 文档 | ✅ `Base64`/`X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 自 JDK 1.8 起行为稳定，JDK 21 文档与本项目代码（RsaKeyConfig）契约一致 |
| GNU base64 | Git for Windows 自带（coreutils） | GNU coreutils 9.11 手册 | ✅ `-w0` 禁用换行；注意解码默认接受换行，自校验需单独查换行 |
| BSD/macOS base64 | 部署目标含 macOS 场景 | FreeBSD man page（macOS 同源） | ✅ `-w0` 行为不保证，用 `openssl base64 -A` 分支替代（官方语义：无换行输出） |
| PowerShell/.NET | Windows PowerShell 5.1+ | .NET Framework | ✅ `[Convert]::ToBase64String` 单行、`FromBase64String` 严格拒绝换行（实测） |

## 5. 编码实现要点（供编码阶段直接采用，与 cs.md §8 一致）

1. **生成链路**（.sh 对齐 .ps1）：
   - `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem`
   - `openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem`
   - `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER -out private_key.der`（**必须显式 PKCS#8**，注释保留"pkey -outform DER 直出 PKCS#1"实测依据）
   - `openssl pkey -in private_key.pem -pubout -outform DER -out public_key.der`
2. **单行 Base64**：`base64 -w0 <der>`（GNU）；macOS 分支 `openssl base64 -A -in <der>`；输出到 `*_base64.txt` 时不追加换行（建议写后自校验无 `\r`/`\n`）。
3. **契约自校验**（四道，与 .ps1 同标准）：
   - ① 无 PEM：`grep -Eq -- '-----BEGIN|-----END'` 命中即失败；
   - ② 无换行：`grep -q $'\r'` / `grep -q $'\n'` 命中即失败（或 `[[ $b64 != *$'\n'* ]]`）；
   - ③ 严格 Base64：正则预检 `^[A-Za-z0-9+/]+={0,2}$`（且长度 % 4 == 0）+ `base64 -d` 成功（⚠️ GNU `base64 -d` 默认接受换行，不能单独作为无换行证明——与 Java `getDecoder()` 严格语义对齐需①②③组合）；
   - ④ DER 结构偏移：`od -An -t u1` 取字节（或 `xxd -p`）：私钥 `len≥16 && [0]=0x30 && [7]=0x30`；公钥 `len≥24 && [0]=0x30 && [4]=0x30 && [19]=0x03`。
4. **输出脱敏**：完整私钥绝不打印（NFR-004），仅打印前 24 字符前缀 + 指向 `*_base64.txt`；修复旧 .sh 第 87-91 行 `cat` 完整私钥的问题。
5. **产物清单**（与 .ps1 一致，共 6 个文件）：`private_key.pem` / `public_key.pem`（审计）、`private_key.der` / `public_key.der`（DER）、`private_key_base64.txt` / `public_key_base64.txt`（单行 Base64）。
6. **版本号**：.sh 升级至 v0.2.7（解决 P7-13 版本号陈旧）；文件头补 SPDX-License-Identifier（Apache-2.0）与版权声明（US-004 验收）。
7. **预检**：`openssl version` 失败提示安装并退出非零（对齐 .ps1 第 41-50 行）。

## 6. 真实工程样例参考（GitHub 实测检索）

| 项目 | 用法 | 参考价值 |
| --- | --- | --- |
| briansmith/ring `bench/data/rsa-generate.sh` | `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:65537 \| openssl pkcs8 -topk8 -nocrypt -outform der > rsa-2048-65537.p8`；`openssl pkey -pubout -inform der -outform der` | 与 .ps1/.sh 目标链路完全同构（genpkey → pkcs8 DER），权威加密库工程实践 |
| ostreedev/ostree `tests/libtest.sh` | `openssl genpkey ... \| openssl pkey -pubout -outform DER \| base64 -w 0` | `pkey -pubout -outform DER` 接 `base64 -w 0` 单行输出的实际组合 |
| aws/s2n-quic `certs/generate_certs.sh` | `openssl pkcs8 -topk8 -nocrypt -outform DER -in key.pem -out key.der` | PEM → PKCS#8 DER 转换的官方云厂商工程用法 |
| Mon-ius/Docker-Warp-Socks `dev/click.sh` | `echo "$KEY" \| openssl pkey -outform DER \| ... \| base64` | 私钥 DER 输出 + base64 组合的 shell 流水线 |

## 7. 资料清单与来源

| 序号 | 资料 | 来源 | 获取日期 |
| --- | --- | --- | --- |
| 1 | openssl-genpkey 3.0 man page | https://docs.openssl.org/3.0/man1/openssl-genpkey/ | 2026-08-10 |
| 2 | openssl-pkcs8 3.0 man page | https://docs.openssl.org/3.0/man1/openssl-pkcs8/ | 2026-08-10 |
| 3 | openssl-pkey 3.0 man page | https://docs.openssl.org/3.0/man1/openssl-pkey/ | 2026-08-10 |
| 4 | openssl-enc 3.0 man page（-a/-A base64） | https://docs.openssl.org/3.0/man1/openssl-enc/ | 2026-08-10 |
| 5 | Java SE 21 Base64 | https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Base64.html | 2026-08-10 |
| 6 | Java SE 21 X509EncodedKeySpec | https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/X509EncodedKeySpec.html | 2026-08-10 |
| 7 | Java SE 21 PKCS8EncodedKeySpec | https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/security/spec/PKCS8EncodedKeySpec.html | 2026-08-10 |
| 8 | GNU coreutils 9.11 base64 manual（-w 0） | https://www.gnu.org/software/coreutils/manual/html_node/base64-invocation.html | 2026-08-10 |
| 9 | FreeBSD base64(1)（macOS 同源） | https://man.freebsd.org/cgi/man.cgi?query=base64&sektion=1 | 2026-08-10 |
| 10 | RFC 5208 PKCS#8 v1.2（PrivateKeyInfo ASN.1） | https://www.rfc-editor.org/rfc/rfc5208.txt | 2026-08-10 |
| 11 | RFC 5280 X.509（SubjectPublicKeyInfo，知识引用） | RFC Editor（引用，未单独抓取） | 2026-08-10 |
| 12 | 本机端到端实测（OpenSSL 3.5.5 + JDK 21.0.9） | 临时目录 C:\Users\jenemy\AppData\Local\Temp\opencode\rsa-test（已清理或保留，不在项目内） | 2026-08-10 |
| 13 | GitHub 样例（ring / ostree / s2n-quic / Docker-Warp-Socks） | GitHub 代码检索 | 2026-08-10 |

## 8. 结论摘要

1. **契约链路已全部实证**：OpenSSL 3.5.5（Git for Windows）生成链路输出与 .ps1 一致（私钥 PKCS#8 [0]=0x30/[7]=0x30，公钥 X.509 [0]=0x30/[4]=0x30/[19]=0x03）；三种 Base64 方式（GNU `-w0` / `openssl base64 -A` / PowerShell Convert）输出逐字符一致且单行无换行。
2. **Java 解码契约已端到端验证**：JDK 21 的 `Base64.getDecoder()` 严格解码 + `PKCS8EncodedKeySpec`/`X509EncodedKeySpec` 解析成功 + 签名验签配对成功 + 含换行输入被拒绝。
3. **PKCS#1 陷阱已实证**：`openssl pkey -outform DER` 直出私钥为 PKCS#1（[7]=0x02），必须显式 `pkcs8 -topk8 -nocrypt -outform DER`——.sh 重构不得省略此步。
4. **旧 .sh 错误已实证**：`base64 -w0 private_key.pem` 输出 2272 字符（含 BEGIN 标记），与 DER 单行 1624 字符不符，注入 env.json 必致 Java 解码失败（P3 问题确认）。
5. **版本兼容性**：全部命令与 OpenSSL 1.1.1+/3.x、JDK 8+（项目 21）、GNU coreutils、BSD base64 兼容；macOS 分支用 `openssl base64 -A` 规避 `-w0` 差异。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
