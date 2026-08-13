package org.cloudstrolling.cloudoffice.common.service;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.cache.ConfigCacheManager;
import org.cloudstrolling.cloudoffice.common.config.ConfigProperties;
import org.cloudstrolling.cloudoffice.common.entity.ConfigEntity;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.mapper.ConfigMapper;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 通用配置管理服务（ConfigService）。
 *
 * <p>封装通用配置查询的核心编排逻辑：</p>
 * <ul>
 *   <li>API-035 {@code GET /api/v1/common/config}：按 serviceName/group/key 过滤 + 分页查询，
 *       serviceName 非空时缓存优先（命中 ≤ 50ms）→ 未命中回源并回填；serviceName 为空时
 *       跨服务列表直连数据库（不缓存）；</li>
 *   <li>API-036 {@code GET /api/v1/common/config/{serviceName}}：按微服务名称查询（不分页），
 *       缓存优先（Redis，命中 ≤ 50ms）→ 未命中回源数据库 t_common_config 并回填缓存
 *       （TTL 300s，可由 common 配置 cache-ttl-seconds 覆盖）；</li>
 *   <li>查询仅返回启用项（status=0），逻辑删除由 {@code @TableLogic} 自动过滤；</li>
 *   <li>敏感配置脱敏：sensitive=1 的配置项 value 替换为掩码（默认 ****，
 *       可由 common 配置 sensitive-mask 覆盖），不暴露明文。</li>
 * </ul>
 *
 * <p>serviceName 合法取值：gateway/auth-service/biz-service/system-service/common，
 * 非法返回 400。本版本仅实现查询，写入接口（增删改）预留扩展点。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Service
public class ConfigService {

    /** serviceName 合法取值 */
    private static final Set<String> VALID_SERVICE_NAMES =
            Set.of("gateway", "auth-service", "biz-service", "system-service", "common");

    /** 默认每页大小 */
    private static final int DEFAULT_PAGE_SIZE = 10;

    /** 最大每页大小 */
    private static final int MAX_PAGE_SIZE = 100;

    private final ConfigMapper configMapper;
    private final ConfigCacheManager configCacheManager;
    private final ConfigProperties configProperties;

    /**
     * 构造器注入依赖。
     *
     * @param configMapper       配置 Mapper（数据访问）
     * @param configCacheManager 配置缓存管理器（Redis 本地缓存）
     * @param configProperties   通用配置管理属性（缓存 TTL、脱敏掩码）
     */
    public ConfigService(ConfigMapper configMapper,
                         ConfigCacheManager configCacheManager,
                         ConfigProperties configProperties) {
        this.configMapper = configMapper;
        this.configCacheManager = configCacheManager;
        this.configProperties = configProperties;
    }

    /**
     * API-035：按 serviceName/group/key 过滤查询配置项，支持分页。
     *
     * @param serviceName 微服务名称（可选，合法取值 gateway/auth-service/biz-service/system-service/common）
     * @param group       配置分组（可选）
     * @param key         配置键（可选，精确匹配）
     * @param page        页码（从 1 开始）
     * @param pageSize    每页条数
     * @return 统一分页结果（配置项视图对象）
     */
    public PageResult<ConfigItemVO> queryConfigList(String serviceName, String group, String key,
                                                    Integer page, Integer pageSize) {
        if (StrUtil.isNotBlank(serviceName)) {
            validateServiceName(serviceName);
        }
        long currentPage = (page == null || page < 1) ? 1 : page;
        long size = (pageSize == null || pageSize < 1) ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);

        // 查询目标配置列表（仅返回启用项 status=0；逻辑删除已由 @TableLogic 自动过滤）：
        // 1. serviceName 非空：缓存优先（与 API-036 同粒度，缓存该服务完整已脱敏列表），
        //    命中后在内存按 group/key 过滤 + 分页；未命中回源数据库并回填缓存（TTL 300s）。
        // 2. serviceName 为空：跨服务列表查询，属低频管理操作，不缓存（直连数据库），
        //    避免全量缓存带来的失效一致性成本（固定键缓存全量列表收益低且维护复杂）。
        List<ConfigItemVO> all;
        if (StrUtil.isNotBlank(serviceName)) {
            all = loadConfigsByService(serviceName);
        } else {
            all = queryEnabledConfigs();
        }

        // 内存过滤（group/key 精确匹配，空条件不过滤）
        List<ConfigItemVO> filtered = all.stream()
                .filter(vo -> StrUtil.isBlank(group) || group.equals(vo.getGroup()))
                .filter(vo -> StrUtil.isBlank(key) || key.equals(vo.getKey()))
                .collect(Collectors.toList());

        // 内存分页（配置数据量可控，全量列表规模小）
        long total = filtered.size();
        int fromIndex = (int) Math.min((currentPage - 1) * size, total);
        int toIndex = (int) Math.min(fromIndex + size, total);
        List<ConfigItemVO> records = filtered.subList(fromIndex, toIndex);
        return PageResult.of(records, total, (int) currentPage, (int) size);
    }

    /**
     * API-036：按微服务名称查询该服务的全部配置项（不分页）。
     *
     * <p>缓存优先：命中 Redis 本地缓存（≤ 50ms）直接返回；
     * 未命中回源数据库 t_common_config 查询并回填缓存（TTL 300s）。</p>
     *
     * @param serviceName 微服务名称（合法取值 gateway/auth-service/biz-service/system-service/common）
     * @return 配置项视图对象列表（敏感配置已脱敏）
     */
    public List<ConfigItemVO> queryConfigsByService(String serviceName) {
        validateServiceName(serviceName);
        return loadConfigsByService(serviceName);
    }

    /**
     * 缓存优先加载指定微服务的全部启用配置项（已脱敏）。
     *
     * <p>命中 Redis 本地缓存（≤ 50ms）直接返回；未命中回源数据库
     * t_common_config（仅 serviceName + status=0 条件）查询并回填缓存（TTL 300s）。</p>
     *
     * @param serviceName 微服务名称（已通过合法性校验）
     * @return 配置项视图对象列表（敏感配置已脱敏）
     */
    private List<ConfigItemVO> loadConfigsByService(String serviceName) {
        List<ConfigItemVO> cached = configCacheManager.getCachedConfigs(serviceName);
        if (cached != null) {
            return cached;
        }

        LambdaQueryWrapper<ConfigEntity> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ConfigEntity::getServiceName, serviceName)
                .eq(ConfigEntity::getStatus, 0)
                .orderByAsc(ConfigEntity::getId);
        List<ConfigItemVO> result = configMapper.selectList(wrapper).stream()
                .map(this::toConfigItemVO)
                .collect(Collectors.toList());

        configCacheManager.cacheConfigs(serviceName, result);
        return result;
    }

    /**
     * 直连数据库查询全部启用配置项（跨服务列表查询用，不缓存）。
     *
     * <p>仅按 status=0（启用）过滤，逻辑删除由 {@code @TableLogic} 自动过滤。</p>
     *
     * @return 全部启用配置项视图对象列表（敏感配置已脱敏）
     */
    private List<ConfigItemVO> queryEnabledConfigs() {
        LambdaQueryWrapper<ConfigEntity> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(ConfigEntity::getStatus, 0).orderByAsc(ConfigEntity::getId);
        return configMapper.selectList(wrapper).stream()
                .map(this::toConfigItemVO)
                .collect(Collectors.toList());
    }

    /**
     * 校验微服务名称是否合法。
     *
     * @param serviceName 微服务名称
     * @throws BusinessException 服务名称为空或不在合法取值范围内（400）
     */
    private void validateServiceName(String serviceName) {
        if (StrUtil.isBlank(serviceName) || !VALID_SERVICE_NAMES.contains(serviceName)) {
            log.warn("serviceName 取值非法 | serviceName={}", serviceName);
            throw new BusinessException(400, "serviceName 取值非法，仅支持 gateway/auth-service/biz-service/system-service/common");
        }
    }

    /**
     * 将配置实体转换为视图对象，敏感配置脱敏。
     *
     * @param entity 配置实体
     * @return 配置项视图对象
     */
    private ConfigItemVO toConfigItemVO(ConfigEntity entity) {
        boolean isSensitive = entity.getSensitive() != null && entity.getSensitive() == 1;
        ConfigItemVO vo = new ConfigItemVO();
        vo.setId(entity.getId());
        vo.setServiceName(entity.getServiceName());
        vo.setGroup(entity.getConfigGroup());
        vo.setKey(entity.getConfigKey());
        vo.setValue(isSensitive ? configProperties.getSensitiveMask() : entity.getConfigValue());
        vo.setDataType(entity.getDataType());
        vo.setDescription(entity.getDescription());
        vo.setSensitive(isSensitive);
        vo.setStatus(entity.getStatus());
        vo.setCreateTime(entity.getCreateTime());
        vo.setUpdateTime(entity.getUpdateTime());
        return vo;
    }
}
