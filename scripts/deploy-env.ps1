<#
.SYNOPSIS
  云漫智企 (CloudStrollOffice) 环境变量模板 (Windows PowerShell)
.DESCRIPTION
  在使用此脚本前，将所有 <PLACEHOLDER> 替换为实际值。
  在 PowerShell 中执行此脚本以注入环境变量到当前会话。
.USAGE
  # 步骤1: 复制模板
  Copy-Item scripts/deploy-env-template.ps1 scripts/deploy-env-local.ps1

  # 步骤2: 编辑 scripts/deploy-env-local.ps1，替换所有 <PLACEHOLDER>

  # 步骤3: 执行注入环境变量
  .\scripts\deploy-env-local.ps1

  # 步骤4: 启动服务
  java -jar cloudoffice-gateway/target/cloudoffice-gateway-0.0.1-SNAPSHOT.jar
#>

# ============================================================
# 第一组：必填敏感变量（请务必替换 <PLACEHOLDER>）
# ============================================================

# 数据库密码（MariaDB root 或业务用户密码）
$env:DB_PASSWORD = 'Jenemy19521005'

# RSA 私钥（Base64 编码，用于 JWT RS256 签名）
# 生成方式: .\scripts\deploy-rsa-keygen.ps1
$env:RSA_PRIVATE_KEY = LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tDQpNSUlFdlFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLY3dnZ1NqQWdFQUFvSUJBUUMxRUtTajMyWlFXL1hMDQpoUmFCNGlKTVBneVM4dUNYRDZSNWFraGcwMll5YlBzOHAwVDhOdzlFRHEvTC9DWGhPTHNhcUdVRzg4aGlMaktTDQpyWGdLZW1Fa1VsN29RQkFRRGlYS25ISGVrYXYxUzV3SW5DSjBVSUFyWWJTYURJK0xxYXlUWUFHYVVVSzJac3pwDQp1ZWNtempjSlc2LzJ6VHh5LzB6MW4yTEpXRGMraDJCTUVsVkMvMW8wOUtaVVc3Z2pOQXNyVzNMZkZlSzFvNzRHDQpMVXpFQzZ1Y3BaamtDQ0gvKy9mcmYrTU5nNjNLSjRmRVBNMmRFb3EwVU81OTBsSFFPRGxJWTM1YVNGbkpjejBkDQpQS29lZk1wWDJlZlI4S0NMeTBYK1AydVNsQUNrbDhrTEo3RlpZT2NFK2huVXJETStWM0lxNW5nTityd21YMGRqDQpXUFlKUmlETEFnTUJBQUVDZ2dFQUJNVDVKMm0vMDd0TUZXektwM0lmZHJMNTRFYm5FK2RIUmE2TjhuRnl5OXdEDQpXaXpqVTRsMVNrRXZqWUxybHZxMHArNzBPNHJObkU2Y3dtdTZ1M0lVUksyOWpHanB2bnNqWWlwd3pXeldJRy9YDQpiVzVUSXo3QkpBRHY4SGdhc2JtNHdzcmtkaEhhaEhueTVxRGw2UlBzbGtraVRqcStYNEVaS2dYdkZlb0xSRlhoDQovUzY3UDJrK2RNUXUxWWF6WGw4dldEc3c4b1FsTDVSWDBsT0l2VnI5Y3ltQ2dpL0RXbXBqK0VwOVVjV3k2V2syDQpuYXdXWVUyVTR3ODM0UzZWdDJMZXBZSE5vV0puc3VaZFRoL3B1WGNjb0dNVElNaVRoc1BPMWx3ZzB5UmppUkphDQpCalJhZXlCTjhtOHhMRU04Y0ZPT3FHY3p4NlNBa2hzSEZBNWh0eURORVFLQmdRRDlVcVBzTnNtRE1CRjRqSGJwDQpKTU9TK3RtNlVpTjR2WWNKWlhDQWpEMEMvc0t5dHpuYktzQjJRbEs0c2V2NzlaZVAwR1JzY2VOeFo0b1BlU2g0DQpGYkZ0ODRhUjBINkw5NkZwYjBWRVMxQTZrU2hjclFHa3hQK2w0QUhza1Nwek8wUXBRbGJWTHFkSzRnRFVBZXJ4DQpEamhQb1RNTTRxc1FNMmU2elI0YWROaG9iUUtCZ1FDMitvTEQ4Um8xWm8xZFpGVWE1ZUNmRDN1NmZOQ2FBdTEwDQpYK2RCd3pobDNMWXZxTlI3Wk1BQU04djlDRTVXRnNCSkVDcnFCL3l5VCtNRmo0NlJkUDRob01TaitOMitLRyszDQpycWNYT3Znd1pTa3BxQjFHQlZ3ZlNJZ2c5WFhMWXdZWkhybHhMUjQrb0FLU0lIM0N5ZnQzak5NSTl3WkUzL24vDQpTK08zeWM1YkZ3S0JnRUZiNmhsUEJXMElvT2xXYkhPNDNaRDFrZW1GdWNzME16d1VaUk4xbTJSRGNONkZjYkwvDQpjOHJQVCtLQlhWNlR2ZmdJRDNEL2JXeGNCMzM0aDUxOEUxeElBY2RyWU1zaUtBNDQvRWtqbVY2VEJ6UHFHMHQwDQozSFRpdC94ZWMvSnBMeXZxQnRkWUF5Zko2ZWJKVytHNEJvVmRGUHZWRzhmQlM1a2h4UXVVYkNWOUFvR0FkNGlODQpkbTJDSHBLQkZScWZValFNR2p6bUtqeXhsWHNHSG5rc1BOVEllaHJHVmJvb0hQZ0RTZDZNaXg4cTlhaGxNeFhCDQp3eU0ybkZIOXo3c3BlckovOWYzdGwrVFREdytoYzlBL3piZ3pQSUpKY3JJbGRZRzQzYUxuY3dpSFREZkRXeE9zDQpOMWd2SXVBcTdjVVdBdk1xT0w0aGV3RE04cCtTMUltQ0dLVllEajhDZ1lFQWp0OERERTI0ZDZ4czQ5MkhvdlFyDQoyOUMvak9JOFhpekdQSkZXWlIreTFta2lSbTdEY1RwK1hHMjB5Q25qdWhJdVA1ME9TWHNqUVBmWDFWaFM0QnJXDQpLVXgwM3k3ZlZFbjdEemtoZTJwRm5JN1I3ZzhQV0doaDlJRW0rM1VmbVIvUW84NlJiZlZkcjhXM050WHdEQzBNDQo1bGpkRmwxWGgrb1V2cWNaQ1QwYW5iOD0NCi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0NCg==

# RSA 公钥（Base64 编码，用于 JWT RS256 验签）
$env:RSA_PUBLIC_KEY = LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0NCk1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBdFJDa285OW1VRnYxeTRVV2dlSWkNClRENE1rdkxnbHcra2VXcElZTk5tTW16N1BLZEUvRGNQUkE2dnkvd2w0VGk3R3FobEJ2UElZaTR5a3ExNENucGgNCkpGSmU2RUFRRUE0bHlweHgzcEdyOVV1Y0NKd2lkRkNBSzJHMG1neVBpNm1zazJBQm1sRkN0bWJNNmJubkpzNDMNCkNWdXY5czA4Y3Y5TTlaOWl5VmczUG9kZ1RCSlZRdjlhTlBTbVZGdTRJelFMSzF0eTN4WGl0YU8rQmkxTXhBdXINCm5LV1k1QWdoLy92MzYzL2pEWU90eWllSHhEek5uUktLdEZEdWZkSlIwRGc1U0dOK1draFp5WE05SFR5cUhueksNClY5bm4wZkNnaTh0Ri9qOXJrcFFBcEpmSkN5ZXhXV0RuQlBvWjFLd3pQbGR5S3VaNERmcThKbDlIWTFqMkNVWWcNCnl3SURBUUFCDQotLS0tLUVORCBQVUJMSUMgS0VZLS0tLS0NCg==

# Redis 密码（若无密码则为空）
$env:REDIS_PASSWORD = ''

# ============================================================
# 第二组：必填连接变量（请根据实际中间件地址修改）
# ============================================================

# Nacos 服务注册与配置中心地址
$env:NACOS_ADDR = '<NACOS_HOST>:8848'

# 数据库主机地址
$env:DB_HOST = '<DB_HOST>'

# 数据库端口
$env:DB_PORT = '3306'

# 数据库用户名
$env:DB_USERNAME = '<DB_USERNAME>'

# biz-service 和 system-service 使用的数据库用户名
$env:DB_USER = '<DB_USERNAME>'

# Redis 主机地址
$env:REDIS_HOST = '<REDIS_HOST>'

# Redis 端口
$env:REDIS_PORT = '6379'

# ============================================================
# 第三组：可选业务变量（通常使用默认值即可）
# ============================================================

# ---------- 验证码配置 ----------
$env:VERIFICATION_CODE_MOCK = 'true'
$env:VERIFICATION_CODE_EXPIRE_SECONDS = '300'
$env:VERIFICATION_CODE_SEND_INTERVAL = '60'
$env:VERIFICATION_CODE_LENGTH = '6'

# ---------- 密码策略配置 ----------
$env:PASSWORD_MIN_LENGTH = '8'
$env:PASSWORD_MAX_LENGTH = '64'

Write-Host "环境变量已加载（请确认所有 <PLACEHOLDER> 已被替换）"
Write-Host "  NACOS_ADDR:       $env:NACOS_ADDR"
Write-Host "  DB_HOST:          $env:DB_HOST"
Write-Host "  DB_PORT:          $env:DB_PORT"
Write-Host "  DB_USERNAME:      $env:DB_USERNAME"
Write-Host "  REDIS_HOST:       $env:REDIS_HOST"
Write-Host "  REDIS_PORT:       $env:REDIS_PORT"
Write-Host "  RSA 密钥已配置:   $(if ($env:RSA_PRIVATE_KEY) { '是' } else { '否' })"
Write-Host "  DB 密码已配置:    $(if ($env:DB_PASSWORD) { '是' } else { '否' })"
