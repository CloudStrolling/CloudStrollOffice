# 任务上下文（TASK-007 对齐 deploy-rsa-keygen.ps1 / .sh RSA 密钥输出契约）

## 0. 用户输入原文与任务定义

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成，测试，调试过程中的临时文件和中间文件在.gitignore中排除。

### 任务定义
对齐 deploy-rsa-keygen.ps1 / .sh RSA 密钥输出契约：检查并重构 deploy-rsa-keygen.ps1 与 deploy-rsa-keygen.sh，使双平台输出契约一致——均输出 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，无 PEM 头尾、无换行），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约一致（ADR-015，v0.2.6 确立契约）；修复 .sh 当前输出 PEM 文件整体 Base64 的问题为与 .ps1 一致的 DER 单行 Base64；提供契约自校验（输出不含 BEGIN/END 标记、不含换行、可被严格 Base64 解码、公钥私钥成对）（F-011，US-004，上游 TASK-001）。

### TASK-001 issue-list 关键结论（P3 主问题 + P7 附加发现，重构直接依据）
- **P3 RSA 密钥输出契约不一致**（对应 F-011 / ADR-015 / US-004）：
  - 问题定位：`deploy-rsa-keygen.sh`（v0.1.7，92 行）第 48-54 行（`base64 -w0 "$PRIVATE_KEY_FILE"` / `openssl base64 -A` 直接编码 **PEM 文件整体**）、第 66-69 行（仅长度统计）、第 72-77 行（仅 openssl 文本验证，无 DER 结构校验）、第 87-91 行（直接 `cat` **完整私钥打印到日志**）。
  - 问题表现：.sh 对 PEM 文件（含 `-----BEGIN/END-----` 头尾）整体 Base64 编码，**非 DER 编码单行 Base64**；未生成 `.der` 文件；无契约自校验；**输出不脱敏**（完整私钥入日志，违反 NFR-004 敏感信息红线）；版本号陈旧（v0.1.7，未随 .ps1 升级）。
  - 影响：.sh 生成的 Base64 注入 env.json 后，Java 端 `Base64.getDecoder()` + `PKCS8EncodedKeySpec` / `X509EncodedKeySpec` 解码失败（网关报 RSA 公钥解析失败）；私钥明文打印构成敏感信息泄露风险。
  - 建议处置：.sh 按 .ps1 对齐：`openssl genpkey` → `openssl pkcs8 -topk8 -nocrypt -outform DER`（私钥 PKCS#8）+ `openssl pkey -pubout -outform DER`（公钥 X.509）→ 单行 Base64（`base64 -w0` 作用于 **.der 文件**）；补充契约自校验（无 PEM/无换行/严格解码/DER 结构偏移：私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`）；输出脱敏（仅前 24 字符）；版本号升级；不得破坏 ADR-015。
- **P7-13 双平台版本号陈旧**：.sh 脚本版本号多为 v0.1.7，.ps1 已为 v0.2.6（rsa-keygen.ps1），重构时统一版本号标注。
- **.gitignore 治理属 F-012 / TASK-010**，本任务（TASK-007）**不涉及**。

---

## 1. 任务信息

```json
{
  "id": "TASK-007",
  "title": "对齐 deploy-rsa-keygen.ps1 / .sh RSA 密钥输出契约",
  "description": "检查并重构 deploy-rsa-keygen.ps1 与 deploy-rsa-keygen.sh，使双平台输出契约一致：均输出 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，无 PEM 头尾、无换行），与 Java 端 Base64.getDecoder() + X509EncodedKeySpec/PKCS8EncodedKeySpec 解码契约一致（ADR-015，v0.2.6 确立契约）；修复 .sh 当前输出 PEM 文件整体 Base64 的问题为与 .ps1 一致的 DER 单行 Base64；提供契约自校验（输出不含 BEGIN/END 标记、不含换行、可被严格 Base64 解码、公钥私钥成对）（F-011）。",
  "taskType": "common",
  "userStoryId": "US-004",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001"],
  "downstreamTaskIds": ["TASK-008", "TASK-010"],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "双平台运行密钥生成，契约自校验（无 PEM 头尾、无换行、可严格 Base64 解码、公钥私钥配对）；与 Java 端解码契约静态核对",
  "acceptanceCriteria": "deploy-rsa-keygen.ps1/.sh 输出契约一致（DER 单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行）；与 Java 端解码契约一致（ADR-015 不破坏）；通过契约自校验"
}
```

## 2. 用户需求

### US-004：双平台脚本契约一致与输出规范
#### 故事描述
作为（运维/部署工程师），我想要（.ps1 与 .sh 双版本脚本行为一致、输出统一分级、密钥契约一致、无弃用脚本残留），以便（Windows 与 Linux 部署行为可预期、结果可核对、仓库整洁可审计）。
#### 前置条件
- 已完成 `deploy/scripts` 全量脚本重构（对应 F-001~F-011）。
#### 验收标准
- [ ] Given 重构完成，When 检查 `deploy-rsa-keygen.sh` 与 `.ps1` 输出，Then 两者输出契约一致（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行），与 Java 端解码契约一致
- [ ] Given 重构完成，When 检查 `deploy/scripts` 目录，Then 无弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1 已移除或明确弃用），无硬编码默认地址
- [ ] Given 双版本脚本存在，When 分别在 Windows PowerShell 与 Linux Bash 校验语法与执行契约自校验，Then 均通过且输出分级（通过/警告/失败）与退出码约定一致
- [ ] Given 脚本文件更新完成，When 检查文件头，Then 保留 SPDX-License-Identifier（Apache-2.0）与版权声明
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| .sh 与 .ps1 输出格式不一致 | 以 v0.2.6 确立的 DER 单行 Base64 契约为准对齐（ADR-015） |
| 移除弃用脚本后其他脚本引用 | 检查引用关系并同步更新，避免加载路径失效 |
| 退出码约定不统一 | 统一为：全部通过 0 / 失败非零（脚本约定） |
| 密码/密钥出现在日志 | 校验脚本输出不含 DB_PASSWORD、RSA_PRIVATE_KEY 明文 |
#### 关联功能编号
F-010、F-011

## 3. 项目信息

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**数据库**：MariaDB 10.6（认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）；Redis 7.2.x（会话/黑名单/状态缓存）
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件。后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），配套 Flutter 客户端（Web + Windows）。已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册等。基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

### 与本任务相关的项目规范（project.md 摘要）
- 部署资产：最终构建产物统一输出到根目录 `deploy`；`env.json`/`env.example.json` 与 `deploy/scripts` 下全部 .sh/.ps1 集中存放；构建中间产物禁止进入 deploy。
- 文件头保留 SPDX-License-Identifier 与版权声明；注释使用简体中文。
- 禁止提交密钥、密码等敏感信息（RSA 密钥对、数据库密码等通过 env.json 注入，密钥文件放 keys/ 并加入 .gitignore）；不提交日志与临时文件。

## 4. 系统架构相关

### RSA 密钥格式契约（ADR-015，v0.2.6 确立，本任务核心依据）
- 统一 RSA 密钥格式为 **DER 编码单行 Base64**：公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，**无 PEM 头尾、无换行**。
- 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/ `PKCS8EncodedKeySpec`（私钥）解码契约严格一致。
- 禁止将多行 PEM 整体 Base64（含 BEGIN/END 标记与 \r\n）直接注入 env.json。
- 决策理由：原 env.json 注入 PEM 整体 Base64 与 Java 严格解码契约不匹配，网关启动报 `RSA 公钥解析失败`（v0.0.1 基线遗留缺陷 T-02，v0.2.6 修复）；统一脚本输出契约可消除配置歧义，Java 端无需兼容代码、运行时代码零改动。

### Java 端解码契约（实际代码，静态核对基准）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/RsaKeyConfig.java`（私钥 + 公钥双加载）：
  - 第 76-77 行：`Base64.getDecoder().decode(privateKeyBase64.trim())` / `decode(publicKeyBase64.trim())` —— **严格 Base64 解码**（非 MIME，遇换行/非法字符抛 IllegalArgumentException）；
  - 第 82 行：`new PKCS8EncodedKeySpec(privateKeyBytes)` 加载私钥（**必须 PKCS#8 PrivateKeyInfo**）；
  - 第 88 行：`new X509EncodedKeySpec(publicKeyBytes)` 加载公钥（**必须 X.509 SubjectPublicKeyInfo**）；
  - 第 93-98 行：密钥强度不低于 2048 位（否则 WARN）；
  - 第 100-101 行：私钥签名 + 公钥验签校验密钥对匹配（**公钥私钥必须成对**）。
- `cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/RsaKeyConfig.java`：
  - 第 113-114 行：`Base64.getDecoder().decode(keyContent.trim())` + `new X509EncodedKeySpec(keyBytes)` 加载公钥（网关验签）；PEM 文件路径加载分支（readPemFile）仅提取 Base64 主体，非本任务契约主路径。

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- **RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏**（ADR-016：.sh 与 .ps1 密钥输出契约对齐）。

### 部署脚本体系重构决策（ADR-016，v0.2.7）
- 以 `deploy/env.json` 为唯一配置源（load-env 统一加载）；能力划分为四类：可用性检查、基础设施一键启动、后端按序一键启动、单服务启动。
- .ps1 与 .sh 双平台行为对齐；输出分级与退出码约定统一；删除弃用脚本残留（deploy-env 等）；`.sh` 与 `.ps1` 密钥输出契约对齐（不破坏 ADR-015）。

### 当前脚本现状对比（重构基线，已实际读取核对）
**deploy-rsa-keygen.ps1（v0.2.6，131 行，已对齐 ADR-015，为 .sh 的对齐基准）**：
- 输出文件：`private_key.pem`/`public_key.pem`（审计用 PEM）、`private_key.der`/`public_key.der`（DER 二进制）、`private_key_base64.txt`/`public_key_base64.txt`（单行 Base64，env.json 注入值来源）；
- 生成链路：`openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM` → `openssl pkcs8 -topk8 -nocrypt -in private_key.pem -outform DER`（**显式 PKCS#8**，注释说明 Git for Windows OpenSSL 3.x 的 `pkey -outform DER` 默认输出传统 PKCS#1，与 PKCS8EncodedKeySpec 不兼容）→ `openssl pkey -pubout -outform DER`（公钥 X.509）→ `[Convert]::ToBase64String()` 单行 Base64（WriteAllText 不追加换行）；
- 契约自校验（第 86-113 行）：无 `-----BEGIN/END-----` 标记 → 无 `[\r\n]` 换行 → `[Convert]::FromBase64String` 严格解码 → DER 结构偏移校验（私钥 `[0]=0x30 && [7]=0x30` 且长度 ≥16；公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03` 且长度 ≥24）；
- 输出脱敏（第 127-128 行）：仅打印前 24 字符前缀，完整值指向 *_base64.txt。

**deploy-rsa-keygen.sh（v0.1.7，92 行，存在 P3 问题，需重构）**：
- 第 48-54 行：`base64 -w0 "$PRIVATE_KEY_FILE"` / `openssl base64 -A` 直接编码 **PEM 文件整体**（含 BEGIN/END 头尾）→ 输出契约错误；
- 无 .der 文件生成、无契约自校验（第 66-69 行仅长度统计、第 72-77 行仅 openssl 文本验证）；
- 第 87-91 行：`cat` 完整私钥打印到日志（**不脱敏**，违反敏感信息红线）；
- 版本号 v0.1.7 陈旧（P7-13）。

## 5. 本任务执行要点（TL 提示）
1. 本任务为**双平台契约对齐**：以 deploy-rsa-keygen.ps1（v0.2.6，已对齐 ADR-015）为基准，重构 deploy-rsa-keygen.sh，使 .sh 输出与 .ps1 完全一致（DER 单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行）；**不得修改 Java 端代码**（ADR-015 明示 Java 端零改动）。
2. .sh 重构要点（按 issue-list P3 建议处置）：`openssl genpkey` → `openssl pkcs8 -topk8 -nocrypt -outform DER`（私钥 PKCS#8）+ `openssl pkey -pubout -outform DER`（公钥 X.509）→ 单行 Base64（`base64 -w0` 作用于 .der 文件；macOS 兼容 `openssl base64 -A` 分支保留）；补充契约自校验（无 PEM/无换行/严格 Base64 解码/DER 结构偏移校验，与 .ps1 同标准：私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`）；输出脱敏（仅前 24 字符）；版本号升级；文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明、简体中文注释。
3. 契约自校验须覆盖任务验收：**无 BEGIN/END 标记、无换行、可被严格 Base64 解码（与 Java Base64.getDecoder() 等价）、公钥私钥成对**（.ps1 已有成对性隐含保证——公私钥均派生自同一私钥文件；.sh 对齐时保持同样链路即可，可参考 auth RsaKeyConfig validateKeyPair 的配对语义）。
4. 测试方式：双平台运行密钥生成脚本，产物通过契约自校验；与 Java 端解码契约（auth/gateway RsaKeyConfig）静态核对。
5. .gitignore 治理（F-012）不在本任务范围（下游 TASK-010）；弃用脚本清理不在本任务范围（下游 TASK-008 等）。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
