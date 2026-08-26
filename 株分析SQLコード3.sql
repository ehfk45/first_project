WITH daily_macro AS (
    SELECT 
        o.trade_date,
        o.dubai AS oil_price,
        f.usd_krw AS fx_price,
        r.base_rate AS rate_price,
        -- 유가 전일 대비 변동률 (%)
        ROUND((o.dubai - LAG(o.dubai, 1) OVER (ORDER BY o.trade_date)) 
              / LAG(o.dubai, 1) OVER (ORDER BY o.trade_date) * 100, 2) AS oil_chg_pct,
        -- 환율 전일 대비 변동률 (%)
        ROUND((f.usd_krw - LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct,
        -- 금리 전일 대비 변동폭 (pt)
        ROUND(r.base_rate - LAG(r.base_rate, 1) OVER (ORDER BY r.trade_date), 2) AS rate_chg_pt
    FROM project_stock.raw_macro_oil o
    LEFT JOIN project_stock.raw_macro_fx f ON o.trade_date = f.trade_date
    LEFT JOIN project_stock.raw_macro_rate r ON o.trade_date = r.trade_date
),
macro_with_lead_lag AS (
    SELECT 
        trade_date,
        oil_price,
        oil_chg_pct,
        fx_chg_pct,
        rate_chg_pt,
        
        -- [유가] D-3 ~ D+3
        LAG(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_minus_3_pct,
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_minus_2_pct,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_minus_1_pct,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_plus_1_pct,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_plus_2_pct,
        LEAD(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_plus_3_pct,
        
        -- [환율] D-3 ~ D+3
        LAG(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_minus_3_pct,
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_minus_2_pct,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_minus_1_pct,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_plus_1_pct,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_plus_2_pct,
        LEAD(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_plus_3_pct,

        -- [금리 변동폭 pt] D-3 ~ D+3
        LAG(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_minus_3_pt,
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_minus_2_pt,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_minus_1_pt,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_plus_1_pt,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_plus_2_pt,
        LEAD(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_plus_3_pt
    FROM daily_macro
)
SELECT 
    trade_date AS `이벤트_일자`,
    oil_price AS `두바이유_가격`,
    
    -- [유가 흐름 (%)]
    oil_d_minus_3_pct AS `유가_D-3_변동률`,
    oil_d_minus_2_pct AS `유가_D-2_변동률`,
    oil_d_minus_1_pct AS `유가_D-1_변동률`,
    oil_chg_pct AS `유가_D0_변동률`,
    oil_d_plus_1_pct AS `유가_D+1_변동률`,
    oil_d_plus_2_pct AS `유가_D+2_변동률`,
    oil_d_plus_3_pct AS `유가_D+3_변동률`,
    
    -- [환율 흐름 (%)]
    fx_d_minus_3_pct AS `환율_D-3_변동률`,
    fx_d_minus_2_pct AS `환율_D-2_변동률`,
    fx_d_minus_1_pct AS `환율_D-1_변동률`,
    fx_chg_pct AS `환율_D0_변동률`,
    fx_d_plus_1_pct AS `환율_D+1_변동률`,
    fx_d_plus_2_pct AS `환율_D+2_변동률`,
    fx_d_plus_3_pct AS `환율_D+3_변동률`,

    -- [금리 흐름 (pt)]
    rate_d_minus_3_pt AS `금리_D-3_변동폭`,
    rate_d_minus_2_pt AS `금리_D-2_변동폭`,
    rate_d_minus_1_pt AS `금리_D-1_변동폭`,
    rate_chg_pt AS `금리_D0_변동폭`,
    rate_d_plus_1_pt AS `금리_D+1_변동폭`,
    rate_d_plus_2_pt AS `금리_D+2_변동폭`,
    rate_d_plus_3_pt AS `금리_D+3_변동폭`
FROM macro_with_lead_lag
WHERE ABS(oil_chg_pct) >= 10.0 -- 유가 일간 변동폭 절대값 10% 이상
ORDER BY ABS(oil_chg_pct) DESC;



WITH daily_macro AS (
    SELECT 
        o.trade_date,
        o.dubai AS oil_price,
        f.usd_krw AS fx_price,
        r.base_rate AS rate_price,
        ROUND((o.dubai - LAG(o.dubai, 1) OVER (ORDER BY o.trade_date)) / LAG(o.dubai, 1) OVER (ORDER BY o.trade_date) * 100, 2) AS oil_chg_pct,
        ROUND((f.usd_krw - LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date)) / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct,
        ROUND(r.base_rate - LAG(r.base_rate, 1) OVER (ORDER BY r.trade_date), 2) AS rate_chg_pt
    FROM project_stock.raw_macro_oil o
    LEFT JOIN project_stock.raw_macro_fx f ON o.trade_date = f.trade_date
    LEFT JOIN project_stock.raw_macro_rate r ON o.trade_date = r.trade_date
),
macro_lead_lag AS (
    SELECT 
        trade_date,
        oil_price,
        oil_chg_pct,
        
        -- 유가 D-3 ~ D+3
        LAG(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_m3,
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_m2,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_m1,
        oil_chg_pct AS oil_d0,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_p1,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_p2,
        LEAD(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_p3,
        
        -- 환율 D-3 ~ D+3
        LAG(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_m3,
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_m2,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_m1,
        fx_chg_pct AS fx_d0,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_p1,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_p2,
        LEAD(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_p3,

        -- 금리 D-3 ~ D+3
        LAG(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_m3,
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_m2,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_m1,
        rate_chg_pt AS rate_d0,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_p1,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_p2,
        LEAD(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_p3
    FROM daily_macro
),
filtered_events AS (
    SELECT *
    FROM macro_lead_lag
    WHERE ABS(oil_chg_pct) >= 10.0
    ORDER BY ABS(oil_chg_pct) DESC
    LIMIT 10 -- 상위 10개 이벤트 일자 대상
),
unpivoted AS (
    -- [유가 변동률 (%)]
    SELECT '유가' AS `지표구분`, 'D-3' AS `시차`, trade_date, oil_m3 AS val, 1 AS order_no FROM filtered_events
    UNION ALL SELECT '유가', 'D-2', trade_date, oil_m2, 2 FROM filtered_events
    UNION ALL SELECT '유가', 'D-1', trade_date, oil_m1, 3 FROM filtered_events
    UNION ALL SELECT '유가', 'D0 (이벤트일)', trade_date, oil_d0, 4 FROM filtered_events
    UNION ALL SELECT '유가', 'D+1', trade_date, oil_p1, 5 FROM filtered_events
    UNION ALL SELECT '유가', 'D+2', trade_date, oil_p2, 6 FROM filtered_events
    UNION ALL SELECT '유가', 'D+3', trade_date, oil_p3, 7 FROM filtered_events
    
    -- [환율 변동률 (%)]
    UNION ALL SELECT '환율', 'D-3', trade_date, fx_m3, 8 FROM filtered_events
    UNION ALL SELECT '환율', 'D-2', trade_date, fx_m2, 9 FROM filtered_events
    UNION ALL SELECT '환율', 'D-1', trade_date, fx_m1, 10 FROM filtered_events
    UNION ALL SELECT '환율', 'D0 (이벤트일)', trade_date, fx_d0, 11 FROM filtered_events
    UNION ALL SELECT '환율', 'D+1', trade_date, fx_p1, 12 FROM filtered_events
    UNION ALL SELECT '환율', 'D+2', trade_date, fx_p2, 13 FROM filtered_events
    UNION ALL SELECT '환율', 'D+3', trade_date, fx_p3, 14 FROM filtered_events

    -- [금리 변동폭 (pt)]
    UNION ALL SELECT '금리', 'D-3', trade_date, rate_m3, 15 FROM filtered_events
    UNION ALL SELECT '금리', 'D-2', trade_date, rate_m2, 16 FROM filtered_events
    UNION ALL SELECT '금리', 'D-1', trade_date, rate_m1, 17 FROM filtered_events
    UNION ALL SELECT '금리', 'D0 (이벤트일)', trade_date, rate_d0, 18 FROM filtered_events
    UNION ALL SELECT '금리', 'D+1', trade_date, rate_p1, 19 FROM filtered_events
    UNION ALL SELECT '금리', 'D+2', trade_date, rate_p2, 20 FROM filtered_events
    UNION ALL SELECT '금리', 'D+3', trade_date, rate_p3, 21 FROM filtered_events
)
SELECT 
    `지표구분`,
    `시차`,
    -- 이벤트 날짜별 동적 집계 (필요에 따라 실제 추출된 날짜로 바인딩)
    MAX(CASE WHEN trade_date = '2026-03-24' THEN val END) AS `2026-03-24`,
    MAX(CASE WHEN trade_date = '2026-06-23' THEN val END) AS `2026-06-23`,
    MAX(CASE WHEN trade_date = '2026-04-08' THEN val END) AS `2026-04-08`,
    MAX(CASE WHEN trade_date = '2021-11-26' THEN val END) AS `2021-11-26`,
    MAX(CASE WHEN trade_date = '2026-05-26' THEN val END) AS `2026-05-26`,
    MAX(CASE WHEN trade_date = '2026-04-02' THEN val END) AS `2026-04-02`,
    MAX(CASE WHEN trade_date = '2026-03-18' THEN val END) AS `2026-03-18`,
    MAX(CASE WHEN trade_date = '2026-03-06' THEN val END) AS `2026-03-06`,
    MAX(CASE WHEN trade_date = '2022-11-23' THEN val END) AS `2022-11-23`,
    MAX(CASE WHEN trade_date = '2026-03-05' THEN val END) AS `2026-03-05`
FROM unpivoted
GROUP BY `지표구분`, `시차`, order_no
ORDER BY order_no;



WITH daily_macro AS (
    SELECT 
        o.trade_date,
        o.dubai AS oil_price,
        f.usd_krw AS fx_price,
        r.base_rate AS rate_price,
        ROUND((o.dubai - LAG(o.dubai, 1) OVER (ORDER BY o.trade_date)) / LAG(o.dubai, 1) OVER (ORDER BY o.trade_date) * 100, 2) AS oil_chg_pct,
        ROUND((f.usd_krw - LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date)) / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct,
        ROUND(r.base_rate - LAG(r.base_rate, 1) OVER (ORDER BY r.trade_date), 2) AS rate_chg_pt
    FROM project_stock.raw_macro_oil o
    LEFT JOIN project_stock.raw_macro_fx f ON o.trade_date = f.trade_date
    LEFT JOIN project_stock.raw_macro_rate r ON o.trade_date = r.trade_date
),
macro_lead_lag AS (
    SELECT 
        trade_date,
        oil_price,
        oil_chg_pct,
        
        -- 유가 D-3 ~ D+3
        LAG(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_m3,
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_m2,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_m1,
        oil_chg_pct AS oil_d0,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_p1,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_p2,
        LEAD(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_p3,
        
        -- 환율 D-3 ~ D+3
        LAG(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_m3,
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_m2,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_m1,
        fx_chg_pct AS fx_d0,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_p1,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_p2,
        LEAD(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_p3,

        -- 금리 D-3 ~ D+3
        LAG(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_m3,
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_m2,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_m1,
        rate_chg_pt AS rate_d0,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_p1,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_p2,
        LEAD(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_p3
    FROM daily_macro
),
filtered_events AS (
    SELECT *
    FROM macro_lead_lag
    WHERE ABS(oil_chg_pct) >= 10.0
    ORDER BY ABS(oil_chg_pct) DESC
    LIMIT 10 -- 상위 10개 이벤트 일자 대상
),
unpivoted AS (
    -- [유가 변동률 (%)]
    SELECT '유가' AS `지표구분`, 'D-3' AS `시차`, trade_date, oil_m3 AS val, 1 AS order_no FROM filtered_events
    UNION ALL SELECT '유가', 'D-2', trade_date, oil_m2, 2 FROM filtered_events
    UNION ALL SELECT '유가', 'D-1', trade_date, oil_m1, 3 FROM filtered_events
    UNION ALL SELECT '유가', 'D0 (이벤트일)', trade_date, oil_d0, 4 FROM filtered_events
    UNION ALL SELECT '유가', 'D+1', trade_date, oil_p1, 5 FROM filtered_events
    UNION ALL SELECT '유가', 'D+2', trade_date, oil_p2, 6 FROM filtered_events
    UNION ALL SELECT '유가', 'D+3', trade_date, oil_p3, 7 FROM filtered_events
    
    -- [환율 변동률 (%)]
    UNION ALL SELECT '환율', 'D-3', trade_date, fx_m3, 8 FROM filtered_events
    UNION ALL SELECT '환율', 'D-2', trade_date, fx_m2, 9 FROM filtered_events
    UNION ALL SELECT '환율', 'D-1', trade_date, fx_m1, 10 FROM filtered_events
    UNION ALL SELECT '환율', 'D0 (이벤트일)', trade_date, fx_d0, 11 FROM filtered_events
    UNION ALL SELECT '환율', 'D+1', trade_date, fx_p1, 12 FROM filtered_events
    UNION ALL SELECT '환율', 'D+2', trade_date, fx_p2, 13 FROM filtered_events
    UNION ALL SELECT '환율', 'D+3', trade_date, fx_p3, 14 FROM filtered_events

    -- [금리 변동폭 (pt)]
    UNION ALL SELECT '금리', 'D-3', trade_date, rate_m3, 15 FROM filtered_events
    UNION ALL SELECT '금리', 'D-2', trade_date, rate_m2, 16 FROM filtered_events
    UNION ALL SELECT '금리', 'D-1', trade_date, rate_m1, 17 FROM filtered_events
    UNION ALL SELECT '금리', 'D0 (이벤트일)', trade_date, rate_d0, 18 FROM filtered_events
    UNION ALL SELECT '금리', 'D+1', trade_date, rate_p1, 19 FROM filtered_events
    UNION ALL SELECT '금리', 'D+2', trade_date, rate_p2, 20 FROM filtered_events
    UNION ALL SELECT '금리', 'D+3', trade_date, rate_p3, 21 FROM filtered_events
)
SELECT 
    `지표구분`,
    `시차`,
    -- 이벤트 날짜별 동적 집계 (필요에 따라 실제 추출된 날짜로 바인딩)
    MAX(CASE WHEN trade_date = '2026-03-24' THEN val END) AS `2026-03-24`,
    MAX(CASE WHEN trade_date = '2026-06-23' THEN val END) AS `2026-06-23`,
    MAX(CASE WHEN trade_date = '2026-04-08' THEN val END) AS `2026-04-08`,
    MAX(CASE WHEN trade_date = '2021-11-26' THEN val END) AS `2021-11-26`,
    MAX(CASE WHEN trade_date = '2026-05-26' THEN val END) AS `2026-05-26`,
    MAX(CASE WHEN trade_date = '2026-04-02' THEN val END) AS `2026-04-02`,
    MAX(CASE WHEN trade_date = '2026-03-18' THEN val END) AS `2026-03-18`,
    MAX(CASE WHEN trade_date = '2026-03-06' THEN val END) AS `2026-03-06`,
    MAX(CASE WHEN trade_date = '2022-11-23' THEN val END) AS `2022-11-23`,
    MAX(CASE WHEN trade_date = '2026-03-05' THEN val END) AS `2026-03-05`
FROM unpivoted
GROUP BY `지표구분`, `시차`, order_no
ORDER BY order_no;


WITH daily_macro AS (
    SELECT 
        f.trade_date,
        f.usd_krw AS fx_price,
        o.dubai AS oil_price,
        r.base_rate AS rate_price,
        -- 환율 전일 대비 변동률 (%)
        ROUND((f.usd_krw - LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct,
        -- 유가 전일 대비 변동률 (%)
        ROUND((o.dubai - LAG(o.dubai, 1) OVER (ORDER BY o.trade_date)) 
              / LAG(o.dubai, 1) OVER (ORDER BY o.trade_date) * 100, 2) AS oil_chg_pct,
        -- 금리 전일 대비 변동폭 (pt)
        ROUND(r.base_rate - LAG(r.base_rate, 1) OVER (ORDER BY r.trade_date), 2) AS rate_chg_pt
    FROM project_stock.raw_macro_fx f
    LEFT JOIN project_stock.raw_macro_oil o ON f.trade_date = o.trade_date
    LEFT JOIN project_stock.raw_macro_rate r ON f.trade_date = r.trade_date
),
macro_with_lead_lag AS (
    SELECT 
        trade_date,
        fx_price,
        oil_price,
        rate_price,
        fx_chg_pct,
        oil_chg_pct,
        rate_chg_pt,
        
        -- [환율] D-3 ~ D+3
        LAG(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_minus_3_pct,
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_minus_2_pct,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_minus_1_pct,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_plus_1_pct,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_plus_2_pct,
        LEAD(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_plus_3_pct,
        
        -- [유가] D-3 ~ D+3
        LAG(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_minus_3_pct,
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_minus_2_pct,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_minus_1_pct,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_plus_1_pct,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_plus_2_pct,
        LEAD(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_plus_3_pct,

        -- [금리 변동폭 pt] D-3 ~ D+3
        LAG(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_minus_3_pt,
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_minus_2_pt,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_minus_1_pt,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_plus_1_pt,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_plus_2_pt,
        LEAD(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_plus_3_pt
    FROM daily_macro
)
SELECT 
    trade_date AS `이벤트_일자`,
    fx_price AS `원달러_환율`,
    
    -- [환율 흐름 (%)]
    fx_d_minus_3_pct AS `환율_D-3_변동률`,
    fx_d_minus_2_pct AS `환율_D-2_변동률`,
    fx_d_minus_1_pct AS `환율_D-1_변동률`,
    fx_chg_pct AS `환율_D0_변동률`,
    fx_d_plus_1_pct AS `환율_D+1_변동률`,
    fx_d_plus_2_pct AS `환율_D+2_변동률`,
    fx_d_plus_3_pct AS `환율_D+3_변동률`,
    
    -- [유가 흐름 (%)]
    oil_d_minus_3_pct AS `유가_D-3_변동률`,
    oil_d_minus_2_pct AS `유가_D-2_변동률`,
    oil_d_minus_1_pct AS `유가_D-1_변동률`,
    oil_chg_pct AS `유가_D0_변동률`,
    oil_d_plus_1_pct AS `유가_D+1_변동률`,
    oil_d_plus_2_pct AS `유가_D+2_변동률`,
    oil_d_plus_3_pct AS `유가_D+3_변동률`,

    -- [금리 흐름 (pt)]
    rate_d_minus_3_pt AS `금리_D-3_변동폭`,
    rate_d_minus_2_pt AS `금리_D-2_변동폭`,
    rate_d_minus_1_pt AS `금리_D-1_변동폭`,
    rate_chg_pt AS `금리_D0_변동폭`,
    rate_d_plus_1_pt AS `금리_D+1_변동폭`,
    rate_d_plus_2_pt AS `금리_D+2_변동폭`,
    rate_d_plus_3_pt AS `금리_D+3_변동폭`
FROM macro_with_lead_lag
WHERE ABS(fx_chg_pct) >= 1.5 -- LIMIT 구문을 제거하여 1.5% 이상 변동된 모든 날짜 추출
ORDER BY ABS(fx_chg_pct) DESC;



WITH daily_macro AS (
    SELECT 
        f.trade_date,
        f.usd_krw AS fx_price,
        o.dubai AS oil_price,
        r.base_rate AS rate_price,
        
        -- [기존 매크로 지표 변동률]
        ROUND((f.usd_krw - LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct,
        ROUND((o.dubai - LAG(o.dubai, 1) OVER (ORDER BY o.trade_date)) 
              / LAG(o.dubai, 1) OVER (ORDER BY o.trade_date) * 100, 2) AS oil_chg_pct,
        ROUND(r.base_rate - LAG(r.base_rate, 1) OVER (ORDER BY r.trade_date), 2) AS rate_chg_pt,

        -- [4개 종목 종가 기준 등락률 (%)]
        ROUND((s1.close_price - LAG(s1.close_price, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(s1.close_price, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS hanair_chg_pct,
        ROUND((s2.close_price - LAG(s2.close_price, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(s2.close_price, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS hynix_chg_pct,
        ROUND((s3.close_price - LAG(s3.close_price, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(s3.close_price, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS koreanair_chg_pct,
        ROUND((s4.close_price - LAG(s4.close_price, 1) OVER (ORDER BY f.trade_date)) 
              / LAG(s4.close_price, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS shinhan_chg_pct

    FROM project_stock.raw_macro_fx f
    LEFT JOIN project_stock.raw_macro_oil o ON f.trade_date = o.trade_date
    LEFT JOIN project_stock.raw_macro_rate r ON f.trade_date = r.trade_date
    LEFT JOIN project_stock.raw_stock_hanair s1 ON f.trade_date = s1.trade_date
    LEFT JOIN project_stock.raw_stock_hynix s2 ON f.trade_date = s2.trade_date
    LEFT JOIN project_stock.raw_stock_koreanair s3 ON f.trade_date = s3.trade_date
    LEFT JOIN project_stock.raw_stock_shinhan s4 ON f.trade_date = s4.trade_date
),
macro_with_lead_lag AS (
    SELECT 
        trade_date, fx_price,
        fx_chg_pct,
        
        -- [환율]
        LAG(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_m3,
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_m2,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_m1,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_p1,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_p2,
        LEAD(fx_chg_pct, 3) OVER (ORDER BY trade_date) AS fx_d_p3,
        
        -- [유가]
        LAG(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_m3,
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_m2,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_m1,
        oil_chg_pct AS oil_d0,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_p1,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_p2,
        LEAD(oil_chg_pct, 3) OVER (ORDER BY trade_date) AS oil_d_p3,

        -- [금리 pt]
        LAG(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_m3,
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_m2,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_m1,
        rate_chg_pt AS rate_d0,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_p1,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_p2,
        LEAD(rate_chg_pt, 3) OVER (ORDER BY trade_date) AS rate_d_p3,

        -- [하나투어]
        LAG(hanair_chg_pct, 3) OVER (ORDER BY trade_date) AS hanair_d_m3,
        LAG(hanair_chg_pct, 2) OVER (ORDER BY trade_date) AS hanair_d_m2,
        LAG(hanair_chg_pct, 1) OVER (ORDER BY trade_date) AS hanair_d_m1,
        hanair_chg_pct AS hanair_d0,
        LEAD(hanair_chg_pct, 1) OVER (ORDER BY trade_date) AS hanair_d_p1,
        LEAD(hanair_chg_pct, 2) OVER (ORDER BY trade_date) AS hanair_d_p2,
        LEAD(hanair_chg_pct, 3) OVER (ORDER BY trade_date) AS hanair_d_p3,

        -- [SK하이닉스]
        LAG(hynix_chg_pct, 3) OVER (ORDER BY trade_date) AS hynix_d_m3,
        LAG(hynix_chg_pct, 2) OVER (ORDER BY trade_date) AS hynix_d_m2,
        LAG(hynix_chg_pct, 1) OVER (ORDER BY trade_date) AS hynix_d_m1,
        hynix_chg_pct AS hynix_d0,
        LEAD(hynix_chg_pct, 1) OVER (ORDER BY trade_date) AS hynix_d_p1,
        LEAD(hynix_chg_pct, 2) OVER (ORDER BY trade_date) AS hynix_d_p2,
        LEAD(hynix_chg_pct, 3) OVER (ORDER BY trade_date) AS hynix_d_p3,

        -- [대한항공]
        LAG(koreanair_chg_pct, 3) OVER (ORDER BY trade_date) AS koreanair_d_m3,
        LAG(koreanair_chg_pct, 2) OVER (ORDER BY trade_date) AS koreanair_d_m2,
        LAG(koreanair_chg_pct, 1) OVER (ORDER BY trade_date) AS koreanair_d_m1,
        koreanair_chg_pct AS koreanair_d0,
        LEAD(koreanair_chg_pct, 1) OVER (ORDER BY trade_date) AS koreanair_d_p1,
        LEAD(koreanair_chg_pct, 2) OVER (ORDER BY trade_date) AS koreanair_d_p2,
        LEAD(koreanair_chg_pct, 3) OVER (ORDER BY trade_date) AS koreanair_d_p3,

        -- [신한지주]
        LAG(shinhan_chg_pct, 3) OVER (ORDER BY trade_date) AS shinhan_d_m3,
        LAG(shinhan_chg_pct, 2) OVER (ORDER BY trade_date) AS shinhan_d_m2,
        LAG(shinhan_chg_pct, 1) OVER (ORDER BY trade_date) AS shinhan_d_m1,
        shinhan_chg_pct AS shinhan_d0,
        LEAD(shinhan_chg_pct, 1) OVER (ORDER BY trade_date) AS shinhan_d_p1,
        LEAD(shinhan_chg_pct, 2) OVER (ORDER BY trade_date) AS shinhan_d_p2,
        LEAD(shinhan_chg_pct, 3) OVER (ORDER BY trade_date) AS shinhan_d_p3

    FROM daily_macro
),
unpivoted_events AS (
    -- 1. 환율 (%)
    SELECT trade_date AS `이벤트_일자`, fx_price AS `원달러_환율`, ABS(fx_chg_pct) AS `환율_변동절대값`, 1 AS sort_order, '환율 (%)' AS `지표_종목_구분`, 
           fx_d_m3 AS `D-3`, fx_d_m2 AS `D-2`, fx_d_m1 AS `D-1`, fx_chg_pct AS `D0`, fx_d_p1 AS `D+1`, fx_d_p2 AS `D+2`, fx_d_p3 AS `D+3`
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 2. 유가 (%)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 2, '유가 (%)', oil_d_m3, oil_d_m2, oil_d_m1, oil_d0, oil_d_p1, oil_d_p2, oil_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 3. 금리 (pt)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 3, '금리 (pt)', rate_d_m3, rate_d_m2, rate_d_m1, rate_d0, rate_d_p1, rate_d_p2, rate_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 4. 하나투어 (%)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 4, '하나투어 (%)', hanair_d_m3, hanair_d_m2, hanair_d_m1, hanair_d0, hanair_d_p1, hanair_d_p2, hanair_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 5. SK하이닉스 (%)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 5, 'SK하이닉스 (%)', hynix_d_m3, hynix_d_m2, hynix_d_m1, hynix_d0, hynix_d_p1, hynix_d_p2, hynix_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 6. 대한항공 (%)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 6, '대한항공 (%)', koreanair_d_m3, koreanair_d_m2, koreanair_d_m1, koreanair_d0, koreanair_d_p1, koreanair_d_p2, koreanair_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5

    UNION ALL
    -- 7. 신한지주 (%)
    SELECT trade_date, fx_price, ABS(fx_chg_pct), 7, '신한지주 (%)', shinhan_d_m3, shinhan_d_m2, shinhan_d_m1, shinhan_d0, shinhan_d_p1, shinhan_d_p2, shinhan_d_p3
    FROM macro_with_lead_lag WHERE ABS(fx_chg_pct) >= 1.5
)
SELECT 
    `이벤트_일자`,
    `원달러_환율`,
    `지표_종목_구분`,
    `D-3`, `D-2`, `D-1`, `D0`, `D+1`, `D+2`, `D+3`
FROM unpivoted_events
ORDER BY `환율_변동절대값` DESC, `이벤트_일자` DESC, sort_order ASC;