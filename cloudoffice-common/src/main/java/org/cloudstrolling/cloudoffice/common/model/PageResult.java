/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

import java.util.ArrayList;
import java.util.List;
import lombok.Data;

/**
 * 分页结果。
 * <p>
 * 统一的分页返回结构，包含数据列表、总记录数、当前页码和每页大小。
 * </p>
 *
 * @param <T> 列表数据类型
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class PageResult<T> {

    /** 数据列表 */
    private List<T> records = new ArrayList<>();

    /** 总记录数 */
    private Long total;

    /** 当前页码 */
    private Integer page;

    /** 每页大小 */
    private Integer pageSize;

    /**
     * 空分页结果。
     *
     * @param <T> 数据类型
     * @return 空分页
     */
    public static <T> PageResult<T> empty() {
        PageResult<T> result = new PageResult<>();
        result.setTotal(0L);
        result.setPage(1);
        result.setPageSize(10);
        return result;
    }

    /**
     * 创建分页结果。
     *
     * @param records  数据列表
     * @param total    总记录数
     * @param page     当前页码
     * @param pageSize 每页大小
     * @param <T>      数据类型
     * @return 分页结果
     */
    public static <T> PageResult<T> of(List<T> records, Long total, Integer page, Integer pageSize) {
        PageResult<T> result = new PageResult<>();
        result.setRecords(records);
        result.setTotal(total);
        result.setPage(page);
        result.setPageSize(pageSize);
        return result;
    }
}
