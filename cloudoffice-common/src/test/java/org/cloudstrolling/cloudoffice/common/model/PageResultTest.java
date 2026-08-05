/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * PageResult 分页结果测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("PageResult 分页结果测试")
class PageResultTest {

    @Test
    @DisplayName("empty() 应返回 total=0, page=1, pageSize=10, records 为空列表")
    void empty_shouldReturnDefaultEmptyPage() {
        PageResult<String> result = PageResult.empty();

        assertEquals(0L, result.getTotal());
        assertEquals(1, result.getPage());
        assertEquals(10, result.getPageSize());
        assertNotNull(result.getRecords());
        assertTrue(result.getRecords().isEmpty());
    }

    @Test
    @DisplayName("of(records, total, page, pageSize) 应正确设置各字段")
    void of_shouldReturnPopulatedPageResult() {
        List<String> records = Arrays.asList("a", "b", "c");
        Long total = 100L;
        Integer page = 2;
        Integer pageSize = 20;

        PageResult<String> result = PageResult.of(records, total, page, pageSize);

        assertSame(records, result.getRecords());
        assertEquals(total, result.getTotal());
        assertEquals(page, result.getPage());
        assertEquals(pageSize, result.getPageSize());
    }
}
