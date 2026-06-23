版本号 v0.1.5 本次开发内容为登录，认证与权限管理。
1.采用标准的用户，权限和角色的控制方式。平台为SASS平台，支持多租户，因此用户端要考虑增加租户id。
2.访问的拦截和验证在网关做。认证和权限在认证服务中实现：cloudoffice-auth-service
3.登录认证需要支持Windows端+Ubuntu端+H5端+Android端+IOS端+小程序端的多端混合登录。
4.同类型前端互斥登录，不同类型前端可以共存。登录session可以以前端类型区分。一个userid可以对应多个登录session。
5.登录态的处理采用jwt+redis登录态+redis黑名单的组合
6.支持主动登出、强制踢人、账号封禁实时生效。
7.Token续签采用双 Token 机制：Access Token + Refresh Token。Access Token有效期2小时，Refresh Token有效期7天。
8.JWT 密钥管理：使用非对称加密（RS256）
9.登录日志审计：记录每次登录的 IP、设备、时间，异常登录触发风控。