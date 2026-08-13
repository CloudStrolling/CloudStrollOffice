# 代码查询结果（#TASK-009 环境配置更新（env.json / env.example.json 新增 COMMON_PORT））

## 1. 现有配置现状

### 1.1 deploy/env.example.json（入库模板，v0.2.7 现状）
- 现有键：NACOS_ADDR、NACOS_HOME、DB_SERVICE_NAME、DB_PROCESS_NAME、REDIS_SERVICE_NAME、REDIS_PROCESS_NAME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、DB_USER、REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY、VERIFICATION_CODE_MOCK、VERIFICATION_CODE_EXPIRE_SECONDS、VERIFICATION_CODE_SEND_INTERVAL、VERIFICATION_CODE_LENGTH、PASSWORD_MIN_LENGTH、PASSWORD_MAX_LENGTH、WEB_SERVER_PORT、MARIADB_ROOT_PASSWORD、TZ。
- 无 COMMON_PORT 等 common 服务端口相关项。

### 1.2 deploy/env.json（实际配置，不入库）
- 结构与 env.example.json 一致，键值含实际密码/RSA 密钥（敏感，不入库）。

### 1.3 cloudoffice-common/src/main/resources/application.yml
- `server.port: ${COMMON_PORT:9300}` —— **已预留 COMMON_PORT 环境变量读取**（TASK-007 服务化时已配置），默认值 9300。本任务需在 env.json/env.example.json 中补充 COMMON_PORT 键，使部署脚本加载后可显式注入端口。

## 2. 现有服务端口配置对照
| 服务 | application.yml 端口 | env.json 端口键 |
| --- | --- | --- |
| cloudoffice-common | ${COMMON_PORT:9300} | **缺失（本次新增）** |
| cloudoffice-gateway | 9000（硬编码） | 无 |
| cloudoffice-auth-service | 9100（硬编码） | 无 |
| cloudoffice-biz-service | 9200（硬编码） | 无 |
| cloudoffice-system-service | 9400（硬编码） | 无 |

## 3. load-env 键名校验机制
- deploy/scripts/load-env.ps1 / load-env.sh：键名合法性白名单校验，仅允许 `[A-Za-z_][A-Za-z0-9_]*`。
- `COMMON_PORT` 符合该正则，无需修改 load-env 脚本。
- 关键配置校验（REQUIRED_KEYS 下限 8 项：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT），COMMON_PORT 非必需键，无需加入 REQUIRED_KEYS。

## 4. 复用要点
- env.example.json 的键按字母序/分组风格组织，新增 COMMON_PORT 应保持格式一致（示例值 "9300"）。
- env.json 保持实际值（"9300"），两文件结构一致。
- 保持策略：env.json 不入库（.gitignore 排除）、env.example.json 入库。

## 5. 结论
仅需在 deploy/env.example.json 与 deploy/env.json 中各新增 `"COMMON_PORT": "9300"`（env.example.json 加注释说明），无需改其他脚本/代码。
