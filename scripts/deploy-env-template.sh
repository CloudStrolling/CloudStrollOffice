#!/bin/bash
# ============================================================
# 云漫智企 (CloudStrollOffice) 环境变量模板
# 版本: v0.1.7
# 说明: 在使用此脚本前，将所有 <PLACEHOLDER> 替换为实际值
# 用法:
#   1. cp scripts/deploy-env-template.sh scripts/deploy-env-local.sh
#   2. 编辑 scripts/deploy-env-local.sh，替换所有 <PLACEHOLDER>
#   3. source scripts/deploy-env-local.sh
#   4. 然后运行 java -jar 或 deploy-start-*.sh 脚本
# ============================================================

# ============================================================
# 第一组：必填敏感变量（请务必替换 <PLACEHOLDER>）
# ============================================================

# 数据库密码（MariaDB root 或业务用户密码）
export DB_PASSWORD='<DB_PASSWORD>'

# RSA 私钥（Base64 编码，用于 JWT RS256 签名）
# 生成方式: ./scripts/deploy-rsa-keygen.sh
# 命令输出结果中的 export RSA_PRIVATE_KEY="..." 值
export RSA_PRIVATE_KEY='<RSA_PRIVATE_KEY>'

# RSA 公钥（Base64 编码，用于 JWT RS256 验签）
# 生成方式: ./scripts/deploy-rsa-keygen.sh
# 命令输出结果中的 export RSA_PUBLIC_KEY="..." 值
export RSA_PUBLIC_KEY='<RSA_PUBLIC_KEY>'

# Redis 密码（若无密码则为空）
export REDIS_PASSWORD='<REDIS_PASSWORD>'

# ============================================================
# 第二组：必填连接变量（请根据实际中间件地址修改）
# ============================================================

# Nacos 服务注册与配置中心地址
export NACOS_ADDR='<NACOS_HOST>:8848'

# 数据库主机地址
export DB_HOST='<DB_HOST>'

# 数据库端口
export DB_PORT='3306'

# 数据库用户名
export DB_USERNAME='<DB_USERNAME>'

# biz-service 和 system-service 使用的数据库用户名
export DB_USER='<DB_USERNAME>'

# Redis 主机地址
export REDIS_HOST='<REDIS_HOST>'

# Redis 端口
export REDIS_PORT='6379'

# ============================================================
# 第三组：可选业务变量（通常使用默认值即可）
# ============================================================

# ---------- 验证码配置 ----------
# 模拟模式: true=控制台打印验证码（开发用）, false=真实发送
export VERIFICATION_CODE_MOCK='true'
# 验证码过期时间（秒），默认 5 分钟
export VERIFICATION_CODE_EXPIRE_SECONDS='300'
# 验证码发送间隔（秒），默认 60 秒
export VERIFICATION_CODE_SEND_INTERVAL='60'
# 验证码长度（数字位数），默认 6 位
export VERIFICATION_CODE_LENGTH='6'

# ---------- 密码策略配置 ----------
# 密码最小长度
export PASSWORD_MIN_LENGTH='8'
# 密码最大长度
export PASSWORD_MAX_LENGTH='64'

echo "环境变量已加载（请确认所有 <PLACEHOLDER> 已被替换）"
echo "  NACOS_ADDR:       $NACOS_ADDR"
echo "  DB_HOST:          $DB_HOST"
echo "  DB_PORT:          $DB_PORT"
echo "  DB_USERNAME:      $DB_USERNAME"
echo "  REDIS_HOST:       $REDIS_HOST"
echo "  REDIS_PORT:       $REDIS_PORT"
echo "  RSA 密钥已配置:   $(if [ -n \"$RSA_PRIVATE_KEY\" ]; then echo '是'; else echo '否'; fi)"
echo "  DB 密码已配置:    $(if [ -n \"$DB_PASSWORD\" ]; then echo '是'; else echo '否'; fi)"
