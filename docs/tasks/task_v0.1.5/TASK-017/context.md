# TASK-017 上下文

## 任务信息
- **任务编号：** TASK-017
- **版本号：** v0.1.5
- **任务名称：** 认证服务 RSA 密钥配置类（RsaKeyConfig）
- **模块：** cloudoffice-auth-service
- **包：** `org.cloudstrolling.cloudoffice.auth.config`
- **优先级：** P0
- **关联UserStory：** US-019
- **上游依赖：** TASK-010 ✅

## 关联 UserStory（US-019: RS256 非对称密钥管理）

### 验收标准
- **AC1：** 认证服务配置文件包含 `jwt.rsa.private-key`（Base64 编码私钥）和 `jwt.rsa.public-key`（Base64 编码公钥）配置项
- **AC3：** 密钥格式无效或缺失时服务启动时抛出异常并拒绝启动
- **AC4：** 密钥加载成功后使用 RSA 私钥（RS256 算法）签名
- **AC5：** 密钥加载成功后使用 RSA 公钥（RS256 算法）验签
- **AC6：** 支持三种加载方式（优先级从高到低）：环境变量 → 配置文件 Base64 → PEM 文件路径

### 边界情况与错误处理
- 私钥或公钥配置为空：启动失败，抛出 `IllegalArgumentException`，日志打印错误信息
- Base64 解码失败：启动失败，日志打印解码异常
- 密钥位数不足 2048 位：启动失败，提示密钥强度不足
- PEM 文件不存在：启动失败，提示文件路径无效

## SDS 相关设计

### 5.2 认证机制 - 密钥加载优先级
环境变量 → 配置文件 Base64 → PEM 文件路径

### 认证服务组件清单
- `RsaKeyConfig`：RSA 密钥对加载与校验（含私钥+公钥）

### 密钥配置项
| 配置项 | 说明 | 注入方式 |
|--------|------|---------|
| `jwt.rsa.private-key` | RSA 私钥（Base64）| 环境变量（首选）/配置文件 |
| `jwt.rsa.public-key` | RSA 公钥（Base64）| 环境变量（首选）/配置文件 |

## architecture.md ADR-011
RS256 非对称加密选型决策，认证服务使用私钥签发 Token，网关和业务服务使用公钥验签

## project.md 编码规范
- 构造器注入替代 `@Autowired` 字段注入（注意：RsaKeyConfig 使用 @Value + @PostConstruct 模式，参考 JwtUtils）
- `@Slf4j` 注解记录日志
- 配置类使用 `@Configuration` 注解
- 测试遵循 Given-When-Then 模式

## 现有代码参考

### application.yml 现有配置
```yaml
jwt:
  rsa:
    private-key: ${RSA_PRIVATE_KEY:}
    public-key: ${RSA_PUBLIC_KEY:}
```

### JwtUtils 现有的 @Value + @PostConstruct 模式
```java
@Component
public class JwtUtils {
    @Value("${jwt.secret}") String secret;
    @Value("${jwt.expiration:86400000}") long expiration;
    @Value("${jwt.algorithm:HS256}") String algorithm;
    
    private SecretKey secretKey;
    
    @PostConstruct
    public void init() {
        if (secret == null || secret.length() < 32) {
            throw new IllegalArgumentException("...");
        }
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}
```

## 核心要求
1. 使用 `@Configuration` + `@Slf4j` 注解
2. `@Value("${jwt.rsa.private-key:}")` 注入私钥 Base64
3. `@Value("${jwt.rsa.public-key:}")` 注入公钥 Base64
4. `@PostConstruct init()` 方法中：
   - 加载私钥：`PKCS8EncodedKeySpec` + `KeyFactory.getInstance("RSA")`
   - 加载公钥：`X509EncodedKeySpec` + `KeyFactory.getInstance("RSA")`
   - 校验密钥对是否匹配（签名+验签）
   - 密钥为空抛出 `IllegalStateException`
   - 密钥位数不足 2048 位打印 WARN
5. `getPrivateKey()` / `getPublicKey()` 方法
