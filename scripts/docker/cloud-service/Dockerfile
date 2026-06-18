# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>

# ==================== 构建阶段 ====================
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /build

# 复制父 POM 和所有模块 POM 以缓存依赖
COPY pom.xml ./
COPY cloudoffice-common/pom.xml cloudoffice-common/
COPY cloudoffice-cloud-service/pom.xml cloudoffice-cloud-service/

# 下载依赖（利用 Docker 缓存层）
RUN mvn dependency:go-offline -pl cloudoffice-cloud-service -am -q

# 复制公共模块源码
COPY cloudoffice-common/src cloudoffice-common/src
# 复制云盘服务模块源码
COPY cloudoffice-cloud-service/src cloudoffice-cloud-service/src

# 构建 JAR 包
RUN mvn clean package -DskipTests -pl cloudoffice-cloud-service -am -q

# ==================== 运行阶段 ====================
FROM eclipse-temurin:21-jre-alpine

# 元数据标签
LABEL org.opencontainers.image.authors="CloudStrolling <jenemy8023@163.com>"
LABEL org.opencontainers.image.version="0.0.1-SNAPSHOT"
LABEL org.opencontainers.image.title="CloudStroll Office - Cloud Service"
LABEL org.opencontainers.image.description="云盘服务：文件存储、文档管理"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# 创建非 root 用户
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# 从构建阶段复制编译后的 JAR
COPY --from=builder /build/cloudoffice-cloud-service/target/cloudoffice-cloud-service-0.0.1-SNAPSHOT.jar app.jar

# 使用非 root 用户运行
USER appuser

# 暴露端口
EXPOSE 9300

# 启动入口
ENTRYPOINT ["java", "-jar", "app.jar"]
