# 代码查询报告（#TASK-007 对齐 deploy-rsa-keygen.ps1 / .sh RSA 密钥输出契约）

## 1. 任务信息与查询范围

- **任务**：检查并重构 `deploy/scripts/deploy-rsa-keygen.ps1` 与 `deploy-rsa-keygen.sh`，使双平台输出契约一致——均输出 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，无 PEM 头尾、无换行），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约一致（ADR-015）；提供契约自校验（F-011 / US-004 / 上游 TASK-001）。
- **查询对象**：
  1. `deploy-rsa-keygen.ps1`（v0.2.6，对齐基准）与 `deploy-rsa-keygen.sh`（v0.1.7，待重构）完整源码；
  2. Java 端密钥解码代码：`cloudoffice-auth-service` / `cloudoffice-gateway` 的 `RsaKeyConfig.java`；
  3. `docs/sad.md` 中 ADR-015 / ADR-016 原文；
  4. 可复用模块：`load-env.ps1` / `load-env.sh`（TASK-002 产物）、上游 TASK-001 issue-list（P3 / P7-13）。
- **查询结论**：.ps1（v0.2.6）已完全对齐 ADR-015，是 .sh 重构的唯一对齐基准；.sh（v0.1.7）存在 P3 契约错误（PEM 文件整体 Base64）+ 无契约自校验 + 私钥明文打印（不脱敏）+ 版本号陈旧，需按 .ps1 全量对齐重构。

## 2. 对齐基准：deploy-rsa-keygen.ps1（v0.2.6，131 行，已读全部源码）

**路径**：`deploy/scripts/deploy-rsa-keygen.ps1`

### 2.1 输出文件清单（重构 .sh 时必须一致）
| 文件 | 用途 |
| --- | --- |
| `private_key.pem` / `public_key.pem` | 仅运维审计用 PEM，不做注入 Base64（第 24-26 行注释明示） |
| `private_key.der` / `public_key.der` | DER 二进制文件（Java 端 X509EncodedKeySpec / PKCS8EncodedKeySpec 契约的字节来源） |
| `private_key_base64.txt` / `public_key_base64.txt` | 单行 Base64（env.json 注入值来源，WriteAllText 不追加换行） |

### 2.2 生成链路（第 52-80 行，.sh 须逐条对齐）
1. `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out private_key.pem`（第 54 行，PEM 私钥审计副本）；
2. `openssl pkey -in private_key.pem -pubout -outform PEM -out public_key.pem`（第 60 行，PEM 公钥审计副本）；
3. **私钥 DER**：`openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER -out private_key.der`（第 65 行）——**必须显式 PKCS#8**：第 62-64 行注释说明 Git for Windows OpenSSL 3.x 的 `pkey -outform DER` 默认输出传统 PKCS#1，与 PKCS8EncodedKeySpec 不兼容（报 `algid parse error, not a sequence`）；
4. **公钥 DER**：`openssl pkey -in private_key.pem -pubout -outform DER -out public_key.der`（第 67 行，X.509 SubjectPublicKeyInfo）；
5. 单行 Base64：`[Convert]::ToBase64String([IO.File]::ReadAllBytes(<der>))`（第 75-76 行，单参数重载默认无换行）→ `[System.IO.File]::WriteAllText(<路径>\*_base64.txt, $b64)`（第 79-80 行，不追加换行）。

### 2.3 契约自校验（第 85-116 行，四道校验，.sh 须同标准移植）
1. **无 PEM 头尾**：`-match '-----BEGIN|-----END'` → 失败（第 87-92 行）；
2. **无换行**：`-match '[\r\n]'` → 失败（第 93-95 行）；
3. **严格 Base64 解码**：`[Convert]::FromBase64String()` 抛异常即失败（第 96-101 行，注释明确"与 Java Base64.getDecoder() 等价校验"）；
4. **DER 结构偏移校验**（第 102-113 行，注释含结构说明）：
   - 私钥（PKCS#8 PrivateKeyInfo）：`长度 ≥ 16 && [0]=0x30 && [7]=0x30`（偏移 7 处为 AlgorithmIdentifier SEQUENCE 0x30，而非 PKCS#1 的 modulus INTEGER 0x02）；
   - 公钥（X.509 SubjectPublicKeyInfo）：`长度 ≥ 24 && [0]=0x30 && [4]=0x30 && [19]=0x03`（结构固定：SEQUENCE(30 82) + algId SEQUENCE(30 0D) + OID(06 09 rsaEncryption) + NULL(05 00) + BIT STRING(03)）。

### 2.4 输出脱敏（第 124-131 行）
- 完整私钥值**绝不打印**（第 124 行注释：敏感信息红线，私钥不得写入日志）；
- 仅打印前 24 字符前缀：`$privateKeyBase64.Substring(0, [Math]::Min(24, $privateKeyBase64.Length)) + "..."`（第 127-128 行），完整值指向 *_base64.txt 文件。

### 2.5 其他要点
- OpenSSL 可用性预检（第 41-50 行）：`openssl version` 失败 → 提示安装并 `exit 1`；
- 目录创建（第 20-22 行）：`New-Item -ItemType Directory -Force`；
- 每步 `$LASTEXITCODE -ne 0` 即失败退出（第 55/61/66/68 行）；
- 文件头：`.SYNOPSIS` 注释块含契约说明（第 1-13 行），**无 SPDX 头**（重构 .sh 时可同步补，但以任务验收为准）。

## 3. 待重构：deploy-rsa-keygen.sh（v0.1.7，92 行，已读全部源码，P3 问题定位）

**路径**：`deploy/scripts/deploy-rsa-keygen.sh`

### 3.1 问题明细（对照 .ps1 逐行定位）
| 问题 | 位置 | 现状 | 影响 |
| --- | --- | --- | --- |
| P3-1 输出契约错误 | 第 48-54 行 | `base64 -w0 "$PRIVATE_KEY_FILE"` / `openssl base64 -A` **直接编码 PEM 文件整体**（含 `-----BEGIN/END-----` 头尾与换行） | 注入 env.json 后 Java `Base64.getDecoder()` + PKCS8/X509EncodedKeySpec 解码失败（网关报 RSA 公钥解析失败），违反 ADR-015 |
| P3-2 无 .der 文件生成 | 全程 | 只生成 .pem 与 _base64.txt，无 .der 中间产物 | 与 .ps1 产物清单不一致 |
| P3-3 无契约自校验 | 第 63-77 行 | 仅 `wc -c` 长度统计（66-69）+ `openssl pkey -noout -text` 文本验证（72-73，不校验 DER 结构）+ 模数对比 grep（76-77，无实际输出使用） | 无法在脚本内拦截契约错误输出 |
| P3-4 私钥明文打印 | 第 87-91 行 | `cat $PRIVATE_KEY_B64_FILE` **完整私钥打印到日志**（env.json 配置 + .env 配置两处） | 违反 NFR-004 敏感信息红线（私钥不得写入日志） |
| P3-5 版本号陈旧 | 第 4 行 | `# 版本: v0.1.7` | 与 .ps1 v0.2.6 不一致（P7-13），重构时统一 |
| 附加 | 第 1-8 行 | 无 SPDX-License-Identifier 版权头 | 项目规范要求文件头保留（US-004 验收） |

### 3.2 可保留部分（重构基础）
- `set -euo pipefail`（第 10 行）；
- 目录计算：`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` / `PROJECT_DIR="$(dirname "$SCRIPT_DIR")"` / `OUTPUT_DIR="${1:-$PROJECT_DIR/keys}"` + `mkdir -p`（第 12-15 行）；
- 文件路径变量命名（第 17-20 行）；
- 步骤标题输出风格 `[1/4]`（第 29/37/45/64 行）。

## 4. Java 端解码契约（静态核对基准，已读全部源码，**不得修改**）

### 4.1 cloudoffice-auth-service/config/RsaKeyConfig.java（171 行）
**路径**：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/RsaKeyConfig.java`
- 第 76-77 行：`byte[] privateKeyBytes = Base64.getDecoder().decode(privateKeyBase64.trim())` / `decode(publicKeyBase64.trim())` —— **严格 Base64 解码**（非 MIME，遇换行/非法字符抛 IllegalArgumentException）；
- 第 82 行：`new PKCS8EncodedKeySpec(privateKeyBytes)` 加载私钥（**必须 PKCS#8 PrivateKeyInfo，PKCS#1 会抛 algid parse error**）；
- 第 88 行：`new X509EncodedKeySpec(publicKeyBytes)` 加载公钥（**必须 X.509 SubjectPublicKeyInfo**）；
- 第 93-98 行：密钥强度不低于 2048 位（不足 WARN，不阻断）；
- 第 100-101 / 120-138 行：`validateKeyPair()` 私钥签名 + 公钥验签校验**密钥对匹配**（配对语义参考）；
- 配置键：`jwt.rsa.private-key` / `jwt.rsa.public-key`（第 36/41 行）。

### 4.2 cloudoffice-gateway/config/RsaKeyConfig.java（171 行）
**路径**：`cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/RsaKeyConfig.java`
- 第 113-114 行：`byte[] keyBytes = Base64.getDecoder().decode(keyContent.trim())` + `new X509EncodedKeySpec(keyBytes)` —— 网关验签公钥，**同样严格解码 + X.509 契约**；
- 第 154-170 行：`readPemFile()` PEM 文件路径加载分支（自动剥离 `-----` 头尾与空行、拼接 Base64 主体）——**仅备用路径**，非本任务主契约路径；
- 配置键：`auth.rsa.public-key` / `auth.rsa.public-key-path`（第 47/57 行）。

### 4.3 契约对照结论
脚本输出的单行 Base64 必须满足：严格 Base64 可解码（无换行、无非法字符）→ 解码后为 DER 二进制 → 私钥 `PKCS8EncodedKeySpec` 可解析（PKCS#8，偏移 [0]=0x30、[7]=0x30）→ 公钥 `X509EncodedKeySpec` 可解析（X.509，偏移 [0]=0x30、[4]=0x30、[19]=0x03）。.ps1 的四道自校验与 Java 端契约一一对应，.sh 移植同一套校验即可静态满足。

## 5. ADR-015 / ADR-016 原文（docs/sad.md，已读核对）

### 5.1 ADR-015（sad.md 第 305 行，2026-08-09）
> 统一 RSA 密钥格式为 DER 编码单行 Base64：deploy-rsa-keygen.ps1 输出/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码逻辑严格一致；禁止多行 PEM 整体 Base64 直接注入。决策理由：原 env.json 注入 PEM 整体 Base64（多行、含 BEGIN/END）与 Java 严格解码契约不匹配，网关启动报 `RSA 公钥解析失败`（v0.0.1 基线遗留缺陷 T-02，v0.2.6 修复）；统一脚本输出契约可消除配置歧义，**Java 端无需兼容代码、运行时代码零改动**。

### 5.2 ADR-016（sad.md 第 306 行，2026-08-10，本任务所属版本）
> v0.2.7 系统性重构 `deploy/scripts` 全部脚本：以 `deploy/env.json` 为唯一配置源（`load-env.ps1`/`.sh` 统一加载，脚本不硬编码地址与凭据）；能力划分为可用性检查（deploy-check-env）、基础设施一键启动（deploy-start-services）、后端服务按序一键启动（deploy-start-all）与单服务启动（deploy-start-{svc}）四类；.ps1 与 .sh 双平台行为对齐，输出分级（通过/警告/失败）与退出码约定（失败非零）统一；删除弃用脚本残留（deploy-env 等），**`.sh` 与 `.ps1` 密钥输出契约对齐（不破坏 ADR-015）**；同时治理 `.gitignore` 排除生成/测试/调试临时与中间文件。

## 6. 上游问题清单依据（TASK-001 产物）

**路径**：`docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md`
- **P3 RSA 密钥输出契约不一致**（第 50-57 行）：问题定位与建议处置与本报告 §3 完全一致——建议处置原文："`.sh` 按 `.ps1` 对齐：`openssl genpkey` → `openssl pkcs8 -topk8 -nocrypt -outform DER`（私钥 PKCS#8）+ `openssl pkey -pubout -outform DER`（公钥 X.509）→ 单行 Base64（`base64 -w0` 作用于 **.der 文件**）；补充契约自校验（无 PEM/无换行/严格解码/DER 结构偏移：私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`）；输出脱敏（仅前 24 字符）；版本号升级；不得破坏 ADR-015"。
- **P7-13 双平台版本号陈旧**：.sh 脚本版本号多为 v0.1.7，.ps1 已为 v0.2.6，重构时统一版本号标注。

## 7. 可复用模块与参考

### 7.1 load-env 统一配置加载模块（TASK-002 产物，v0.2.7 已就绪）
**路径**：`deploy/scripts/load-env.ps1`（75 行）/ `load-env.sh`（84 行）
- 调用方式：.ps1 为 dot-source（`. "$PSScriptRoot\load-env.ps1"`）；.sh 为 source 型（`source "$SCRIPT_DIR/load-env.sh"`，失败 `return 1`，**调用方必须 `|| exit $?`**）；
- env.json 缺失 → 提示复制 env.example.json 并退出非零；JSON 解析失败 → 非零退出；8 项关键配置缺失（NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT）→ 逐项列键名、不打印值，非零退出；
- 安全约定：敏感值仅注入会话环境变量，任何输出不打印明文（与 rsa-keygen 脱敏要求同源）。
- **本任务（TASK-007）密钥生成脚本是否需要经 load-env 加载 env.json 由编码实现确定**——注意 ADR-015 契约核心是"脚本输出 DER 单行 Base64"，密钥生成脚本可保持独立参数化（-OutputDir），避免加载 env.json 循环依赖（密钥生成是 env.json 的前置步骤，env.json 中的 RSA 值正是本脚本产物）。

### 7.2 输出分级与退出码约定（F-011 / ADR-016 通用规范）
- 输出分级：通过（绿）/ 警告（黄）/ 失败（红），汇总计数；退出码：全部通过 0，失败非零（1）；
- 参考实现：`deploy-start-all.ps1` 的 `Write-Result`（45-52 行）与 `deploy-start-all.sh` 的 `print_result`（48-55 行）——rsa-keygen 脚本如补充分级输出可复用同款风格（.sh 颜色码 GREEN/YELLOW/RED/NC 定义于第 44-45 行）；
- 文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明（load-env.ps1 第 1 行 / load-env.sh 第 2 行为规范样例），简体中文注释。

### 7.3 敏感信息脱敏红线（NFR-004 / project.md 编码规范）
- 禁止输出 DB_PASSWORD、RSA_PRIVATE_KEY 等明文；RSA 私钥仅打印前 24 字符前缀（对齐 .ps1 第 127-128 行做法）。

## 8. 重构要点汇总（编码依据，按 .ps1 全量对齐）

1. **生成链路**（对齐 .ps1 §2.2）：`openssl genpkey`（RSA 2048 PEM）→ `openssl pkey -pubout -outform PEM`（公钥 PEM 审计）→ `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER -out private_key.der`（**显式 PKCS#8**，注释保留 Git for Windows OpenSSL 3.x 兼容性说明）→ `openssl pkey -in private_key.pem -pubout -outform DER -out public_key.der`（公钥 X.509）；
2. **单行 Base64**：`base64 -w0 <private_key.der>` / `base64 -w0 <public_key.der>`（**作用于 .der 文件而非 .pem**）；macOS 无 `-w0` 时保留 `openssl base64 -A` 分支（作用于 .der 文件）；`printf '%s' "$b64" > *_base64.txt` 或 `base64 -w0 ... > file`（单行无换行，注意 base64 输出末尾无换行才满足契约——建议写后校验无 `\r`/`\n`）；
3. **契约自校验**（对齐 .ps1 §2.3，四道全做）：①无 `-----BEGIN|-----END`；②无 `[\r\n]`（用 `grep -q $'\r'`/`$'\n'` 或参数扩展校验）；③严格 Base64 解码等价校验（`base64 -d -w0 2>/dev/null` 失败即退出，或 `grep -Eq '^[A-Za-z0-9+/]+=*$'` 预检 + 解码成功）；④DER 结构偏移（`od`/`xxd`/`dd`+`od` 取字节：私钥 `len ≥ 16 && [0]=0x30 && [7]=0x30`；公钥 `len ≥ 24 && [0]=0x30 && [4]=0x30 && [19]=0x03`）；
4. **输出脱敏**：完整私钥/公钥值不打印，仅打印前 24 字符前缀 + 指向 *_base64.txt（对齐 .ps1 §2.4）；
5. **产物清单**：.pem（审计）+ .der + *_base64.txt 共 6 个文件，与 .ps1 一致；
6. **版本号**：升级至 v0.2.7（与 .ps1 对齐，解决 P7-13）；
7. **文件头**：保留 SPDX-License-Identifier（Apache-2.0）与版权声明、简体中文注释（US-004 验收）；
8. **不得修改 Java 端代码**（ADR-015 明示 Java 端零改动）；.gitignore 治理（F-012）属下游 TASK-010，本任务不涉及。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
