/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 登录日志审计服务实现类。
 *
 * <p>使用 {@link LoginLogMapper} 实现登录日志的写入和更新操作。
 * 所有数据库操作均使用 try-catch 包裹，异常时仅记录错误日志，不影响主流程。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
public class LoginLogServiceImpl implements LoginLogService {

    private final LoginLogMapper loginLogMapper;

    /**
     * 构造器注入 LoginLogMapper。
     *
     * @param loginLogMapper 登录日志 Mapper
     */
    public LoginLogServiceImpl(LoginLogMapper loginLogMapper) {
        this.loginLogMapper = loginLogMapper;
    }

    @Override
    public void recordLoginSuccess(Long tenantId, Long userId, String loginName,
                                   String loginIp, String clientType, String deviceInfo) {
        try {
            LoginLogEntity logEntity = new LoginLogEntity();
            logEntity.setTenantId(tenantId);
            logEntity.setUserId(userId);
            logEntity.setLoginName(loginName);
            logEntity.setLoginIp(loginIp);
            logEntity.setClientType(clientType);
            logEntity.setDeviceInfo(deviceInfo);
            logEntity.setLoginTime(LocalDateTime.now());
            logEntity.setLoginResult(0); // 0-成功
            loginLogMapper.insert(logEntity);
            log.info("Login success log recorded | userId={} | tenantId={} | clientType={} | ip={}",
                    userId, tenantId, clientType, loginIp);
        } catch (Exception e) {
            log.error("Failed to record login success log | userId={} | tenantId={}",
                    userId, tenantId, e);
        }
    }

    @Override
    public void recordLoginFailure(String loginName, String loginIp,
                                   String clientType, String failReason) {
        try {
            LoginLogEntity logEntity = new LoginLogEntity();
            logEntity.setLoginName(loginName);
            logEntity.setLoginIp(loginIp);
            logEntity.setClientType(clientType);
            logEntity.setFailReason(failReason);
            logEntity.setLoginTime(LocalDateTime.now());
            logEntity.setLoginResult(1); // 1-失败
            loginLogMapper.insert(logEntity);
            log.info("Login failure log recorded | loginName={} | clientType={} | reason={}",
                    loginName, clientType, failReason);
        } catch (Exception e) {
            log.error("Failed to record login failure log | loginName={}", loginName, e);
        }
    }

    @Override
    public void updateLogoutTime(Long userId, String clientType) {
        try {
            // 查找该用户和客户端类型的最新登录日志（logoutTime 为 null）
            LambdaQueryWrapper<LoginLogEntity> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(LoginLogEntity::getUserId, userId)
                    .eq(LoginLogEntity::getClientType, clientType)
                    .isNull(LoginLogEntity::getLogoutTime)
                    .orderByDesc(LoginLogEntity::getLoginTime)
                    .last("LIMIT 1");

            LoginLogEntity logEntity = loginLogMapper.selectOne(wrapper);
            if (logEntity != null) {
                logEntity.setLogoutTime(LocalDateTime.now());
                loginLogMapper.updateById(logEntity);
                log.info("Logout time updated | userId={} | clientType={}", userId, clientType);
            } else {
                log.warn("No active login log found for logout update | userId={} | clientType={}",
                        userId, clientType);
            }
        } catch (Exception e) {
            // 日志写入失败不影响主流程
            log.error("Failed to update logout time | userId={} | clientType={}",
                    userId, clientType, e);
        }
    }
}
