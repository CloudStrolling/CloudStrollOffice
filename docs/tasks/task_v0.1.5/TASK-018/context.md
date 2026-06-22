# 任务上下文

## 任务信息

| 项目 | 内容 |
|------|------|
| **任务编号** | TASK-018 |
| **任务名称** | JwtUtils 重构（支持 RS256 双 Token） |
| **模块** | cloudoffice-auth-service |
| **优先级** | P0 |
| **当前状态** | context_finish |

## 关联需求

### UserStory: US-020 JwtUtils 重构

**验收标准：**
- AC1：generateAccessToken(LoginUserDTO) 生成 RS256 签名的 Access Token，包含 sub(用户ID)、tenantId、clientType、tokenType="access"、roles、permissions、iat、exp（当前时间+2h）
- AC2：generateRefreshToken(LoginUserDTO) 生成 RS256 签名的 Refresh Token，包含 sub(用户ID)、tenantId、clientType、tokenType="refresh"、iat、exp（当前时间+7d）、tokenVersion
- AC3：parseAccessToken(token) 校验 RS256 签名并检查 tokenType="access"，返回 Claims
- AC4：parseRefreshToken(token) 校验 RS256 签名并检查 tokenType="refresh"，返回 Claims
- AC5：Access Token 使用 parseRefreshToken 解析时抛异常
- AC7：getTokenSignature(token) 返回 Token 的签名指纹（用于黑名单 Key）
- AC8：使用 @Component 注解并通过构造器注入

**边界情况：**
- Token 签名验证失败 → SignatureException
- Token 已过期 → ExpiredJwtException
- Token 格式错误 → MalformedJwtException
- Access Token 用于 Refresh 接口 → tokenType 不匹配异常

## 依赖分析

### 上游依赖（已就绪）
- **TASK-003** ✅（TokenPairDTO / LoginUserDTO）
- **TASK-017** ✅（RsaKeyConfig — 提供 getPrivateKey() / getPublicKey()）

### 下游依赖
- TASK-022（登录认证使用 JwtUtils 签发 Token）
- TASK-023（Token 刷新使用 JwtUtils 解析和签发 Token）

## 现有代码分析

### JwtUtils.java（待重构）
- 位于：`cloudoffice-auth-service/src/main/java/.../auth/util/JwtUtils.java`
- 当前使用 HS256 算法，`@Component` + `@Value` 字段注入
- 方法：generateToken / parseToken / validateToken / getUserIdFromToken / getUserNameFromToken
- 需要重构为 RS256 + 双 Token，使用构造器注入 RsaKeyConfig

### RsaKeyConfig.java（已就绪）
- 位于：`cloudoffice-auth-service/src/main/java/.../auth/config/RsaKeyConfig.java`
- 提供 getPrivateKey() 和 getPublicKey() 方法
- 在 @PostConstruct init() 中完成密钥加载
- 可用测试密钥对（见 test application.yml）

### LoginUserDTO.java（已就绪）
- 位于：`cloudoffice-common/src/main/java/.../common/dto/LoginUserDTO.java`
- 字段：userId(Long)、tenantId(Long)、userName(String)、clientType(String)、roles(List<String>)、permissions(List<String>)
- 使用 @Builder / @Data / @NoArgsConstructor / @AllArgsConstructor

### Test 配置（已就绪）
- test application.yml 包含测试用 RSA 公私钥（Base64 编码）
- test bootstrap.yml 已禁用 Nacos

## 技术方案要点

1. **签名算法**：RS256（SHA256withRSA），使用 RsaKeyConfig 提供的 PrivateKey 签名、PublicKey 验签
2. **双 Token**：
   - Access Token：2h 有效期，含完整用户信息
   - Refresh Token：7d 有效期，含 tokenVersion（雪花算法生成）
3. **tokenType 校验**：parseAccessToken 校验 tokenType="access"，parseRefreshToken 校验 tokenType="refresh"
4. **签名指纹**：getTokenSignature 使用 SHA-256 对整个 token 字符串取摘要，Hex 编码
5. **构造器注入**：JwtUtils(RsaKeyConfig rsaKeyConfig, @Value accessTokenExpiration, @Value refreshTokenExpiration)
6. **tokenVersion 生成**：使用 Hutool Snowflake（cn.hutool.core.lang.Snowflake）

## 测试要求

- 签发 Access Token → parseAccessToken 解析成功
- 签发 Refresh Token → parseRefreshToken 解析成功
- Access Token 过期 → 抛出 ExpiredJwtException
- 校验 tokenType=access（Access Token 可解析、Refresh Token 抛异常）
- 校验 tokenType=refresh（Refresh Token 可解析、Access Token 抛异常）
- 签名指纹提取正确（相同 Token → 相同指纹）
- 签名错误 → 抛异常
