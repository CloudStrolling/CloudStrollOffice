package org.cloudstrolling.cloudoffice.auth.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 令牌工具类
 *
 * @author CloudStroll Office
 */
@Slf4j
@Component
public class JwtUtils {

    /** JWT 签名密钥字符串（配置项：jwt.secret） */
    private final String secret;
    /** JWT 令牌过期时间，单位毫秒（配置项：jwt.expiration，默认 86400000 = 24 小时） */
    private final long expiration;
    /** JWT 签名算法（配置项：jwt.algorithm，默认 HS256），当前版本暂未使用 */
    @SuppressWarnings("unused")
    private final String algorithm;
    /** HMAC 签名密钥对象，由 {@link #secret} 初始化生成 */
    private SecretKey secretKey;

    /**
     * 构造器注入 JWT 配置属性
     *
     * @param secret     JWT 签名密钥
     * @param expiration 过期时间（毫秒，默认 86400000 = 24小时）
     * @param algorithm  签名算法（默认 HS256）
     */
    public JwtUtils(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration:86400000}") long expiration,
            @Value("${jwt.algorithm:HS256}") String algorithm) {
        this.secret = secret;
        this.expiration = expiration;
        this.algorithm = algorithm;
    }

    /**
     * 初始化校验：secret 不能为空且长度至少为 32 字符
     */
    @PostConstruct
    public void init() {
        if (secret == null || secret.length() < 32) {
            log.error("JWT secret is null or less than 32 characters, service startup rejected");
            throw new IllegalArgumentException(
                    "JWT secret must be at least 32 characters long, current length: "
                            + (secret == null ? 0 : secret.length()));
        }
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        log.info("JwtUtils initialized successfully with algorithm: {}", algorithm);
    }

    /**
     * 生成 JWT 令牌
     *
     * @param userId   用户ID
     * @param userName 用户名
     * @return 紧凑格式 JWT 字符串
     */
    public String generateToken(String userId, String userName) {
        Date now = new Date();
        Date expirationDate = new Date(now.getTime() + expiration);

        String token = Jwts.builder()
                .subject(userId)
                .claim("userName", userName)
                .issuedAt(now)
                .expiration(expirationDate)
                .signWith(secretKey)
                .compact();

        log.debug("Generated JWT token for userId: {}, expires at: {}", userId, expirationDate);
        return token;
    }

    /**
     * 解析 JWT 令牌
     *
     * @param token JWT 令牌字符串
     * @return Claims 载荷
     */
    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * 验证 JWT 令牌是否有效
     *
     * @param token JWT 令牌字符串
     * @return true 有效，false 无效
     */
    public boolean validateToken(String token) {
        try {
            parseToken(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.warn("JWT令牌已过期: {}", e.getMessage());
        } catch (SignatureException e) {
            log.warn("JWT签名验证失败: {}", e.getMessage());
        } catch (MalformedJwtException e) {
            log.warn("JWT格式异常: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            log.warn("JWT参数非法: {}", e.getMessage());
        }
        return false;
    }

    /**
     * 从 JWT 令牌中获取用户ID
     *
     * @param token JWT 令牌字符串
     * @return 用户ID（subject）
     */
    public String getUserIdFromToken(String token) {
        return parseToken(token).getSubject();
    }

    /**
     * 从 JWT 令牌中获取用户名
     *
     * @param token JWT 令牌字符串
     * @return 用户名
     */
    public String getUserNameFromToken(String token) {
        return parseToken(token).get("userName", String.class);
    }
}
