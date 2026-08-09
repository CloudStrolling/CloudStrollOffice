# 网络资料查询结果（#TASK-004 修改 Maven 构建配置：后端 jar 最终产物统一输出至 deploy）

## 1. 任务需求摘要
修改根 `pom.xml` 与 gateway、auth-service、biz-service、system-service 四个可执行模块 `pom.xml`，在 package 阶段将各模块最终可执行 jar 复制/输出至根目录 `deploy`（deployDir 以根目录相对方式定位）；产物命名保持模块可辨识（如 `cloudoffice-gateway.jar`、`cloudoffice-auth-service.jar` 等），避免同名覆盖，重复构建 overwrite 覆盖旧版本；仅复制最终 jar 文件，禁止整目录递归复制 target（编译类、测试产物等中间产物不得进入 deploy）；common 模块为库依赖不参与输出。对应 PRD F-002、F-004，验收标准 AC-2 / AC-4。

## 2. 三方组件识别结论（本任务需要使用的组件）
| 组件 | 用途 | 选型结论 |
| --- | --- | --- |
| maven-antrun-plugin 3.2.0 | 在 package 阶段执行 Ant `<copy>` 任务，将最终 jar 复制到 deploy（SAD 技术栈已指定方案） | **主方案（推荐）** |
| maven-resources-plugin 3.5.0 | copy-resources goal 实现同样复制能力 | 备选方案（若不便用 antrun） |
| Maven 内置属性 `maven.multiModuleProjectDirectory` | 以根目录相对方式定位 deployDir，避免各模块 `../deploy` 相对路径歧义 | 随主方案使用（见 5.1 风险提示） |
| spring-boot-maven-plugin（项目已有） | 打可执行 fat jar（repackage），antrun 复制的必须是 repackage 后的 jar | 无需改动，注意插件顺序 |

## 3. 官方文档与使用方法

### 3.1 maven-antrun-plugin 3.2.0（Apache 官方，2025-10-17 发布，当前最新版）
官方地址：https://maven.apache.org/plugins/maven-antrun-plugin/
- 唯一 goal：`antrun:run`（参数 `<target>` 内可放置 build.xml 中 `<target>...</target>` 之间的任意 Ant 任务）。
- **⚠ 重大版本差异（3.0.0 破坏性变更）**：`<tasks>` 参数已在 3.0.0 被**完全移除**，必须改用 `<target>`；继续使用 `<tasks>` 会直接导致构建失败（插件文档明确：3.0.0 中该参数仅用于"破坏构建"）。网上大量 2.x 老教程使用 `<tasks>`，**不得照搬**。
- 标准配置模板（官方 usage 页）：
```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-antrun-plugin</artifactId>
  <version>3.2.0</version>
  <executions>
    <execution>
      <id>copy-to-deploy</id>
      <phase>package</phase>
      <goals><goal>run</goal></goals>
      <configuration>
        <target>
          <copy file="${project.build.directory}/${project.build.finalName}.jar"
                tofile="${deployDir}/cloudoffice-gateway.jar"
                overwrite="true"/>
        </target>
      </configuration>
    </execution>
  </executions>
</plugin>
```
- 可用参数要点：`skip`（默认 false，可 `-Dmaven.antrun.skip` 跳过）、`failOnError`（默认 true，Ant 任务失败即构建失败）、`exportAntProperties`（默认 false）。
- 与 Maven 属性互通：`<target>` 中可直接使用 `${project.build.directory}`、`${project.build.finalName}`、`${project.version}` 等全部 Maven 属性（官方 usage 页确认）。

### 3.2 Ant `<copy>` 任务（Apache Ant 官方）
官方地址：https://ant.apache.org/manual/Tasks/copy.html
- 单文件复制用 `file` + `tofile`（源、目标均为具体文件）或 `file` + `todir`（复制到目录，保留文件名）。
- **`overwrite` 属性默认 false**：目标文件存在且比源新时跳过；目标较旧时仍会覆盖。每次 `mvn clean package` 重新生成的 jar 时间戳必然新于旧产物，默认行为基本可覆盖；但为满足"重复构建 overwrite 覆盖旧版本"的确定性要求，**建议显式设置 `overwrite="true"`**。
- 只复制单个文件（`file` 属性）不会带入任何目录结构与中间产物，天然满足 AC-4；禁止使用 `<fileset dir="${project.build.directory}">` 整目录复制 target（会混入 classes、test-classes、*.original、maven-status 等中间产物，违反 AC-4）。
- 扩展说明：`failonerror` 默认 true（源文件缺失时构建失败，符合预期）；`flatten`、`includeEmptyDirs` 等参数本任务用不到。
- 官方还提示：Unix 下复制不保留文件权限（jar 交付无影响）。

### 3.3 maven-resources-plugin 3.5.0（备选方案，2026-03-02 发布）
官方地址：https://maven.apache.org/plugins/maven-resources-plugin/
- 备选实现（绑定 package 阶段 + `copy-resources` goal）：
```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-resources-plugin</artifactId>
  <version>3.5.0</version>
  <executions>
    <execution>
      <id>copy-to-deploy</id>
      <phase>package</phase>
      <goals><goal>copy-resources</goal></goals>
      <configuration>
        <outputDirectory>${deployDir}</outputDirectory>
        <resources>
          <resource>
            <directory>${project.build.directory}</directory>
            <includes><include>${project.build.finalName}.jar</include></includes>
          </resource>
        </resources>
      </configuration>
    </execution>
  </executions>
</plugin>
```
- 说明：`<includes>` 精确限定单个 jar 文件名，同样只复制最终产物、不复制目录；copy-resources 每次执行直接覆盖目标同名文件（满足 overwrite 需求）。

### 3.4 Maven 根目录定位属性（多模块）
- `maven.multiModuleProjectDirectory`：Maven 3.3.1+ 内置属性，**业界标准做法**，keycloak、apache/camel、spring-boot 官方 buildSrc 等大型项目均用它引用多模块根目录。
- 取值机制（权威来源：Maven 3.9.x `mvn.cmd`/`mvn` 启动脚本源码）：Maven 启动时向上遍历目录查找 `.mvn` 目录，找到则根目录 = `.mvn` 所在目录；**找不到则退化为"启动 mvn 的工作目录"**，并通过 `-Dmaven.multiModuleProjectDirectory=%MAVEN_PROJECTBASEDIR%` 传入 JVM。
- 备选属性：`${session.executionRootDirectory}`（执行 mvn 时的工作目录，与上述退化行为一致）；`directory-maven-plugin` 的 `highest-basedir` goal（在 initialize 阶段显式计算根目录并赋给自定义属性，最健壮但引入额外插件）。

### 3.5 插件执行顺序（重要）
- spring-boot-maven-plugin 的 `repackage` 与 maven-antrun-plugin 的 `run` 都绑定在 **package 阶段**；同一阶段多个插件按 **POM 中 `<plugins>` 声明顺序** 执行。
- **antrun 必须声明在 spring-boot-maven-plugin 之后**，否则复制的是未 repackage 的普通 jar（缺少 BOOT-INF/ 可执行结构，无法 `java -jar` 启动）。四个模块现 POM 中 `<plugins>` 已有 spring-boot-maven-plugin，antrun 追加在其后即可。

## 4. 版本兼容性核对（本地环境实测）
| 项目 | 版本 | 兼容性结论 |
| --- | --- | --- |
| 本地 Maven（mvn -v 实测） | 3.9.16 | ✅ 支持 `maven.multiModuleProjectDirectory`（Maven 3.3.1+）与 antrun 3.2.0（要求 Java 8+） |
| 本地 JDK（mvn -v 实测） | Eclipse Adoptium 21.0.9 | ✅ 满足 antrun 3.2.0 / resources 3.5.0 运行要求 |
| Spring Boot | 3.2.5（spring-boot-starter-parent） | ✅ spring-boot-maven-plugin 与 antrun 插件无版本冲突 |
| maven-antrun-plugin | 3.2.0（最新，2025-10-17） | ✅ 建议显式声明版本；注意必须用 `<target>` 而非 `<tasks>` |
| maven-resources-plugin | 3.5.0（最新，2026-03-02） | ✅ 备选方案版本 |
| 项目根目录 `.mvn` 目录 | **不存在（已实测）** | ⚠ `maven.multiModuleProjectDirectory` 将退化为 mvn 启动目录，见 5.1 |

真实项目佐证：UniversalMediaServer（GPL-2.0）同时使用 antrun 3.2.0 + resources-plugin 3.5.0 组合；eugenp/tutorials 使用 antrun 3.0.0；apache/incubator-seata、netty 等大量项目在 pom.xml 中绑定 antrun `run` goal 于 package 阶段执行构建任务。

## 5. 编码建议（供编码阶段直接采用）
### 5.1 deployDir 定位
- 采用 `${maven.multiModuleProjectDirectory}/deploy`（cs.md 提示方案 + 业界标准做法）。
- **风险提示（必须知悉）**：项目根目录无 `.mvn` 目录，该属性实际取值为"启动 mvn 时的工作目录"；项目构建约定为在根目录执行 `mvn clean package`（构建命令统一），此时属性值 = 项目根目录，结果正确。若有人从子模块目录或 IDE 单独构建某模块，该属性可能指向错误目录。可选加固（非必须）：在根目录创建空 `.mvn` 目录（Maven 4 也推荐此做法，保证从任意位置构建都能定位根）；或改用 directory-maven-plugin 显式计算。
- Dockerfile 多阶段构建（scripts/docker/*/Dockerfile）在容器内 `mvn clean package` 时会在容器内 `/deploy` 产生复制动作（容器内 WORKDIR=/build，无实际影响），属无害冗余，不需规避。

### 5.2 配置落点（与 cs.md 结论一致）
| 文件 | 动作 |
| --- | --- |
| 根 `pom.xml` | `<properties>` 增加 `<deployDir>${maven.multiModuleProjectDirectory}/deploy</deployDir>`（便于复用/覆盖）；可在 `<build><pluginManagement>` 统一管理 antrun 版本（可选） |
| 四个可执行模块 pom | 在 `<build><plugins>` 中 spring-boot-maven-plugin **之后**追加 antrun 3.2.0 配置（见 3.1 模板），`tofile` 目标文件名按命名契约：gateway→`cloudoffice-gateway.jar`、auth/biz/system→`cloudoffice-{m}-service.jar` |
| cloudoffice-common/pom.xml | **不修改**（无 spring-boot-maven-plugin，禁止配置复制插件） |

### 5.3 关键注意点（防坑清单）
1. antrun 3.x 用 `<target>`，禁用 `<tasks>`（3.0.0 起会直接构建失败）。
2. 复制用 `file`+`tofile` 单文件，禁止 `<fileset>` 递归复制 target（AC-4）。
3. 显式 `overwrite="true"`（满足"重复构建覆盖旧版本"确定性要求）。
4. antrun 声明顺序必须在 spring-boot-maven-plugin 之后（保证复制 repackage 后的可执行 jar）。
5. 产物命名严格遵循 `deploy/scripts/deploy-start-*.sh` 引用的契约（UT-077-3 断言）。
6. `.gitignore` 已忽略 `*.jar`，deploy 下 jar 不入库属预期行为。

## 6. 参考资料清单
| 资料 | 地址 |
| --- | --- |
| Maven AntRun Plugin 官方文档（3.2.0） | https://maven.apache.org/plugins/maven-antrun-plugin/ |
| antrun:run 参数说明（3.2.0） | https://maven.apache.org/plugins/maven-antrun-plugin/run-mojo.html |
| antrun 官方用法页（含配置模板） | https://maven.apache.org/plugins/maven-antrun-plugin/usage.html |
| Apache Ant Copy Task 官方文档 | https://ant.apache.org/manual/Tasks/copy.html |
| Maven Resources Plugin 官方文档（3.5.0） | https://maven.apache.org/plugins/maven-resources-plugin/ |
| Maven 多模块官方指南 | https://maven.apache.org/guides/mini/guide-multiple-modules.html |
| maven.multiModuleProjectDirectory 说明（Stack Overflow） | https://stackoverflow.com/questions/3084629/ |
| Maven 3.9.x mvn.cmd 源码（属性注入机制） | https://github.com/apache/maven/blob/master/apache-maven/src/assembly/maven/bin/mvn.cmd |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
