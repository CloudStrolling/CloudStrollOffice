# 任务清单：删除 cloud-service 微服务模块

**项目名称：** CloudStrollOffice（云漫智企）
**版本：** v0.1.0
**文档版本：** v0.1.0
**日期：** 2026-06-19
**任务类型：** 模块删除
**前置条件：** 以下文档已更新完毕：
- `docs/project.md` ✅
- `docs/architecture.md` ✅
- `docs/sds/CloudStrollOffice-sds-v0.1.0.md` ✅

---

## 任务总览

| 任务编号 | 任务名称 | 类型 | 优先级 | 依赖关系 |
|---------|---------|------|--------|---------|
| TASK-001 | 删除 cloud-service 源码目录及关联文件 | 通用 | P0 | 无 |
| TASK-002 | 更新父 POM 移除 cloud-service 模块 | 后端 | P0 | TASK-001 |
| TASK-003 | 更新 Docker Compose 移除 cloud-service | 通用 | P0 | TASK-001 |
| TASK-004 | 更新部署文档 | 通用 | P1 | 无 |
| TASK-005 | 更新数据库设计文档 | 通用 | P1 | 无 |
| TASK-006 | 编译验证 | 后端 | P0 | TASK-001, TASK-002 |

---

## 任务详情

### TASK-001: 删除 cloud-service 源码目录及关联文件

**类型：** 通用
**优先级：** P0
**对应 PRD UserStory：** 不适用（架构调整）
**预估工时：** 0.5 小时

**操作步骤：**

1. **删除源码目录**
   - 删除 `cloudoffice-cloud-service/` 整个目录及其所有子文件和子目录
   - 需删除的文件清单（含 target 编译产物）：
     - `cloudoffice-cloud-service/pom.xml`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/CloudApplication.java`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/controller/HealthController.java`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/controller/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/config/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/service/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/service/impl/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/mapper/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/entity/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/dto/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/vo/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/enums/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/exception/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/filter/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/interceptor/.gitkeep`
     - `cloudoffice-cloud-service/src/main/java/org/cloudstrolling/cloudoffice/cloud/util/.gitkeep`
     - `cloudoffice-cloud-service/src/main/resources/bootstrap.yml`
     - `cloudoffice-cloud-service/src/main/resources/application.yml`
     - `cloudoffice-cloud-service/src/test/resources/bootstrap.yml`
     - `cloudoffice-cloud-service/src/test/java/org/cloudstrolling/cloudoffice/cloud/CloudApplicationTest.java`
     - `cloudoffice-cloud-service/src/test/java/org/cloudstrolling/cloudoffice/cloud/controller/HealthControllerTest.java`
     - `cloudoffice-cloud-service/target/`（整个编译产物目录）

2. **删除 Dockerfile**
   - 删除 `scripts/docker/cloud-service/Dockerfile`

3. **从数据库初始化脚本中移除云数据库**
   - 编辑 `scripts/sql/init.sql`，删除以下行：
     ```sql
     DROP DATABASE IF EXISTS `cloudstroll_office_cloud`;
     CREATE DATABASE IF NOT EXISTS `cloudstroll_office_cloud`
       DEFAULT CHARACTER SET utf8mb4
       DEFAULT COLLATE utf8mb4_general_ci;
     ```

**验收标准：**
- [ ] `cloudoffice-cloud-service/` 目录已完全删除（含 target 编译产物）
- [ ] `scripts/docker/cloud-service/Dockerfile` 已删除
- [ ] `scripts/sql/init.sql` 中不再包含 `cloudstroll_office_cloud` 数据库创建语句
- [ ] 通过 `git status` 确认无残留的 cloud-service 文件

---

### TASK-002: 更新父 POM 移除 cloud-service 模块

**类型：** 后端
**优先级：** P0
**对应 PRD UserStory：** 不适用（架构调整）
**预估工时：** 0.5 小时
**依赖：** TASK-001

**操作步骤：**

1. 编辑项目根目录 `pom.xml`
2. 在 `<modules>` 部分移除以下行：
   ```xml
   <module>cloudoffice-cloud-service</module>
   ```
3. 确保模块声明顺序为：
   ```xml
   <modules>
       <module>cloudoffice-common</module>
       <module>cloudoffice-gateway</module>
       <module>cloudoffice-auth-service</module>
       <module>cloudoffice-biz-service</module>
       <module>cloudoffice-system-service</module>
   </modules>
   ```

**验收标准：**
- [ ] `pom.xml` 的 `<modules>` 中不再包含 `cloudoffice-cloud-service`
- [ ] `<modules>` 声明共计 5 个子模块（common、gateway、auth-service、biz-service、system-service）
- [ ] 声明注释从 `<!-- ======================== 子模块声明 ======================== -->` 开始

---

### TASK-003: 更新 Docker Compose 移除 cloud-service

**类型：** 通用
**优先级：** P0
**对应 PRD UserStory：** 不适用（架构调整）
**预估工时：** 0.5 小时
**依赖：** TASK-001

**操作步骤：**

1. 编辑 `scripts/docker/docker-compose.yml`
2. 删除 cloud-service 整个服务定义块（从第 117 行的 `# 云服务` 注释开始到第 138 行的 `restart: unless-stopped` 结束），需删除的内容：

```yaml
  # 云服务
  cloud-service:
    build:
      context: ../../
      dockerfile: scripts/docker/cloud-service/Dockerfile
    image: cloud-stroll-cloud-service:latest
    container_name: cloud-stroll-cloud-service
    ports:
      - "9300:9300"
    depends_on:
      - nacos
      - mariadb
    environment:
      - NACOS_ADDR=${NACOS_ADDR:-nacos:8848}
      - DB_HOST=${DB_HOST:-mariadb}
      - DB_PORT=${DB_PORT:-3306}
      - DB_USER=${DB_USER:-root}
      - DB_PASSWORD=${DB_PASSWORD:-root123}
      - JWT_SECRET=${JWT_SECRET}
    networks:
      - cloud-stroll-network
    restart: unless-stopped
```

3. 确保删除后 `system-service` 服务直接跟在 `biz-service` 后面

**验收标准：**
- [ ] `scripts/docker/docker-compose.yml` 中不再包含 `cloud-service` 服务定义
- [ ] 删除后文件 YAML 格式正确（可通过 `docker compose config` 验证）
- [ ] 其余服务的缩进和结构未受影响

---

### TASK-004: 更新部署文档

**类型：** 通用
**优先级：** P1
**对应 PRD UserStory：** 不适用（架构调整）
**预估工时：** 1 小时

**操作步骤：**

编辑 `docs/deployment-guide.md`，进行以下修改：

1. **服务端口映射表（第 7 章）**
   - 删除第 439 行：`| cloud-stroll-cloud-service | 云服务 | 9300 | 9300 | HTTP |`
   - 更新第 54 行端口范围：`9100-9400` → `9100-9200, 9400`（非连续端口用逗号分隔）

2. **编译产物列表（第 4.3 节）**
   - 删除第 243 行 cloud-service JAR 包路径：`| cloud-service | \`cloudoffice-cloud-service/target/cloudoffice-cloud-service-0.0.1-SNAPSHOT.jar\` |`

3. **健康检查命令（第 8.1 节）**
   - 删除第 454 行网关健康检查 curl：`curl -s http://localhost:9000/api/v1/cloud/health   | jq .`
   - 删除第 460 行直接健康检查 curl：`curl -s http://localhost:9300/api/v1/cloud/health   | jq .`

4. **验证部署清单（第 8.2 节）**
   - 更新第 486 行："4 个业务数据库" → "3 个业务数据库"
   - 更新第 489 行："5 个已注册服务" → "4 个已注册服务"

5. **手动部署脚本（第 6.1 节）**
   - 删除第 405-408 行 cloud-service 的 `java -jar` 启动命令

6. **Maven 插件启动命令（第 6.2 节）**
   - 删除第 423 行：`mvn spring-boot:run -pl cloudoffice-cloud-service`

7. **Docker 镜像大小表（第 5.6 节）**
   - 删除第 377 行 cloud-service 行

8. **Docker 架构图（第 5.1 节）**
   - 更新第 273 行：从 `gateway(9000) auth-service(9100) biz-service(9200)` 移除 `cloud-service(9300)`
   - 更新第 329 行容器启动顺序：移除 `cloud-service`

9. **数据库初始化命令（第 2.2 节）**
   - 删除第 141 行预期输出中的 `# cloudstroll_office_cloud`
   - 更新第 140 行注释："4 个业务数据库" → "3 个业务数据库"

10. **环境变量清单（第 3.2 节）**
    - 更新第 173-176 行：`DB_HOST/DB_PORT/DB_USER/DB_PASSWORD` 的"适用服务"列从 `biz/cloud/system 服务` → `biz/system 服务`
    - 删除第 187 行 cloud-service 配置文件路径

11. **配置文件路径表（第 3.3 节）**
    - 删除第 187 行 cloud-service 行

12. **备份脚本（第 9.3 节）**
    - 更新第 539-540 行备份命令：移除 `cloudstroll_office_cloud`

**验收标准：**
- [ ] 部署文档中不再包含任何 cloud-service / cloud 服务 / 端口 9300 相关内容
- [ ] 服务端口映射表、编译产物列表、健康检查命令、手动部署脚本均已完成更新
- [ ] 所有数字（数据库数量、服务数量等）已正确调整

---

### TASK-005: 更新数据库设计文档

**类型：** 通用
**优先级：** P1
**对应 PRD UserStory：** 不适用（架构调整）
**预估工时：** 1 小时

**操作步骤：**

编辑 `docs/dbd.md`，进行以下修改：

1. **删除整个第 3.3 节（云服务数据库）**
   - 从 `## 3.3 云服务数据库 —— \`cloudstroll_office_cloud\``（第 216 行）到第 249 行（预留表结束）全部删除
   - 原 3.4 节（系统服务数据库）的编号改为 `## 3.3`

2. **更新数据库对象汇总表（第 2.3 节）**
   - 删除第 58 行云服务数据库行
   - 模块数量更新（4 个 → 3 个）

3. **删除云资源类型枚举值（第 4.8 节）**
   - 删除第 384-391 行（`## 4.8 云资源类型（t_cloud_resource.resource_type）` 整个表格）
   - 后续枚举值章节序号前移（4.9 → 4.8, 4.10 → 4.9, 4.11 → 4.10）

4. **删除云资源状态枚举值（原第 4.9 节）**
   - 删除第 393-399 行（`## 4.9 云资源状态（t_cloud_resource.status）` 整个表格）
   - 后续枚举值章节序号前移

5. **删除云服务应用账号（第 5.2 节）**
   - 删除第 433 行：`| 云服务 | cloudstroll_office_cloud | cloud_app | 仅授予 cloud 库权限 |`

6. **更新 t_sys_oper_log 表注释**
   - 更新第 297 行：`module` 字段的注释 `操作模块（auth/biz/cloud/system）` → `操作模块（auth/biz/system）`

7. **调整数据库总数**
   - 所有提及"4 个数据库"的地方改为"3 个数据库"

**验收标准：**
- [ ] 第 3.3 节（云服务数据库）已完全删除，后续章节编号正确前移
- [ ] 数据库对象汇总表不再包含 `cloudstroll_office_cloud`
- [ ] 云资源类型枚举值表已删除
- [ ] 云资源状态枚举值表已删除
- [ ] 云服务应用账号（cloud_app）已从权限表中删除
- [ ] `t_sys_oper_log.module` 注释已更新

---

### TASK-006: 编译验证

**类型：** 后端
**优先级：** P0
**预估工时：** 0.5 小时
**依赖：** TASK-001, TASK-002

**操作步骤：**

1. 确保已执行 TASK-001 和 TASK-002（已删除源码并更新 POM）

2. 在项目根目录执行以下 Maven 编译命令，验证剩余 5 个模块编译通过：

```bash
mvn clean compile -pl cloudoffice-common,cloudoffice-gateway,cloudoffice-auth-service,cloudoffice-biz-service,cloudoffice-system-service -am
```

3. 确认编译日志输出为 `BUILD SUCCESS`

4. 在 `target/` 目录检查编译后的 class 文件是否存在异常

**验收标准：**
- [ ] `mvn clean compile -pl cloudoffice-common,cloudoffice-gateway,cloudoffice-auth-service,cloudoffice-biz-service,cloudoffice-system-service -am` 输出 `BUILD SUCCESS`
- [ ] 无编译错误或依赖缺失
- [ ] 编译日志中无 cloud-service 相关警告或错误

---

## 执行顺序

```
TASK-001 (删除源码)
    │
    ├──→ TASK-002 (更新 POM)
    │       │
    │       └──→ TASK-006 (编译验证)
    │
    └──→ TASK-003 (更新 Docker Compose)

TASK-004 (更新部署文档) ─── 可与 TASK-001/002/003 并行
TASK-005 (更新 DBD 文档) ─── 可与 TASK-001/002/003 并行
```

---

## 变更记录

| 日期 | 版本 | 变更说明 |
|------|------|----------|
| 2026-06-19 | v0.1.0 | 首次创建 - 删除 cloud-service 微服务模块任务清单 |
