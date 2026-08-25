SELECT 
    trade_date,
    wti AS oil_price,
    LAG(dubai, 1) OVER (ORDER BY trade_date) AS prev_oil_price,
    ROUND((dubai - LAG(dubai, 1) OVER (ORDER BY trade_date)) / LAG(dubai, 1) OVER (ORDER BY trade_date) * 100, 2) AS oil_change_pct
FROM project_stock.raw_macro_oil
ORDER BY oil_change_pct DESC
LIMIT 100;


WITH weekly_oil AS (
    SELECT 
        YEARWEEK(trade_date, 1) AS yr_wk, -- 주차 구분 (월요일 시작 기준)
        MIN(trade_date) AS week_start_date,
        MAX(trade_date) AS week_end_date,
        -- 주간 마지막 날의 두바이유 종가
        SUBSTRING_INDEX(GROUP_CONCAT(dubai ORDER BY trade_date DESC), ',', 1) AS end_dubai
    FROM project_stock.raw_macro_oil
    GROUP BY YEARWEEK(trade_date, 1)
),
weekly_oil_change AS (
    SELECT 
        yr_wk,
        week_start_date,
        week_end_date,
        CAST(end_dubai AS DECIMAL(10,2)) AS dubai_price,
        LAG(CAST(end_dubai AS DECIMAL(10,2)), 1) OVER (ORDER BY yr_wk) AS prev_dubai_price,
        ROUND((CAST(end_dubai AS DECIMAL(10,2)) - LAG(CAST(end_dubai AS DECIMAL(10,2)), 1) OVER (ORDER BY yr_wk)) 
              / LAG(CAST(end_dubai AS DECIMAL(10,2)), 1) OVER (ORDER BY yr_wk) * 100, 2) AS weekly_change_pct
    FROM weekly_oil
)
SELECT * 
FROM weekly_oil_change
ORDER BY weekly_change_pct DESC
LIMIT 100; -- 두바이유 주간 상승률 상위 10개 주차



WITH weekly_oil AS (
    SELECT 
        YEARWEEK(trade_date, 1) AS yr_wk,
        MIN(trade_date) AS week_start,
        MAX(trade_date) AS week_end,
        SUBSTRING_INDEX(GROUP_CONCAT(dubai ORDER BY trade_date DESC), ',', 1) AS end_dubai
    FROM project_stock.raw_macro_oil
    GROUP BY YEARWEEK(trade_date, 1)
),
weekly_oil_chg AS (
    SELECT 
        yr_wk,
        week_start,
        week_end,
        ROUND((CAST(end_dubai AS DECIMAL(10,2)) - LAG(CAST(end_dubai AS DECIMAL(10,2)), 1) OVER (ORDER BY yr_wk)) 
              / LAG(CAST(end_dubai AS DECIMAL(10,2)), 1) OVER (ORDER BY yr_wk) * 100, 2) AS dubai_weekly_chg
    FROM weekly_oil
),
weekly_fx AS (
    SELECT 
        YEARWEEK(trade_date, 1) AS yr_wk,
        SUBSTRING_INDEX(GROUP_CONCAT(usd_krw ORDER BY trade_date ASC), ',', 1) AS fx_open,
        SUBSTRING_INDEX(GROUP_CONCAT(usd_krw ORDER BY trade_date DESC), ',', 1) AS fx_close
    FROM project_stock.raw_macro_fx
    GROUP BY YEARWEEK(trade_date, 1)
),
weekly_rate AS (
    SELECT 
        YEARWEEK(trade_date, 1) AS yr_wk,
        SUBSTRING_INDEX(GROUP_CONCAT(base_rate ORDER BY trade_date ASC), ',', 1) AS rate_open,
        SUBSTRING_INDEX(GROUP_CONCAT(base_rate ORDER BY trade_date DESC), ',', 1) AS rate_close
    FROM project_stock.raw_macro_rate
    GROUP BY YEARWEEK(trade_date, 1)
)
SELECT 
    o.yr_wk,
    o.week_start,
    o.week_end,
    o.dubai_weekly_chg AS oil_chg_pct,             -- 두바이유 실제 변동률(%)
    ABS(o.dubai_weekly_chg) AS oil_chg_abs_pct,     -- 두바이유 변동률 절대값(%)
    -- 환율 변동률(%)
    ROUND((f.fx_close - f.fx_open) / f.fx_open * 100, 2) AS fx_chg_pct,
    -- 금리 변동폭(pt)
    ROUND(r.rate_close - r.rate_open, 2) AS rate_chg_pt
FROM weekly_oil_chg o
LEFT JOIN weekly_fx f ON o.yr_wk = f.yr_wk
LEFT JOIN weekly_rate r ON o.yr_wk = r.yr_wk
WHERE ABS(o.dubai_weekly_chg) >= 10.0 -- 절대값 10% 이상 조건
ORDER BY oil_chg_abs_pct DESC;


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
        -- 전일(D-1) 지표 변동률
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_prev_chg_pct,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_prev_chg_pct,
        -- 익일(D+1) 지표 변동률
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_next_chg_pct,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_next_chg_pct
    FROM daily_macro
)
SELECT 
    trade_date AS event_date,                       -- 이벤트 당일(D0)
    oil_price,                                      -- 당일 두바이 유가
    
    -- [유가 추이] 전일(D-1) -> 당일(D0) -> 익일(D+1)
    oil_prev_chg_pct AS oil_d_minus_1_pct,
    oil_chg_pct AS oil_d0_pct,
    oil_next_chg_pct AS oil_d_plus_1_pct,
    
    -- [환율 추이] 전일(D-1) -> 당일(D0) -> 익일(D+1)
    fx_prev_chg_pct AS fx_d_minus_1_pct,
    fx_chg_pct AS fx_d0_pct,
    fx_next_chg_pct AS fx_d_plus_1_pct
FROM macro_with_lead_lag
WHERE ABS(oil_chg_pct) >= 10.0                      -- 유가 변동폭 절대값 10% 이상 기준
ORDER BY ABS(oil_chg_pct) DESC;


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
              / LAG(f.usd_krw, 1) OVER (ORDER BY f.trade_date) * 100, 2) AS fx_chg_pct
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
        
        -- [유가] 전전일(D-2), 전일(D-1), 익일(D+1), 명일(D+2)
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_minus_2_pct,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_minus_1_pct,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_plus_1_pct,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_plus_2_pct,
        
        -- [환율] 전전일(D-2), 전일(D-1), 익일(D+1), 명일(D+2)
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_minus_2_pct,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_minus_1_pct,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_plus_1_pct,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_plus_2_pct
    FROM daily_macro
)
SELECT 
    trade_date AS `이벤트_일자`,
    oil_price AS `두바이유_가격`,
    
    -- [유가 흐름]
    oil_d_minus_2_pct AS `유가_D_minus_2_변동률`,
    oil_d_minus_1_pct AS `유가_D_minus_1_변동률`,
    oil_chg_pct AS `유가_D0_변동률`,
    oil_d_plus_1_pct AS `유가_D_plus_1_변동률`,
    oil_d_plus_2_pct AS `유가_D_plus_2_변동률`,
    
    -- [환율 흐름]
    fx_d_minus_2_pct AS `환율_D_minus_2_변동률`,
    fx_d_minus_1_pct AS `환율_D_minus_1_변동률`,
    fx_chg_pct AS `환율_D0_변동률`,
    fx_d_plus_1_pct AS `환율_D_plus_1_변동률`,
    fx_d_plus_2_pct AS `환율_D_plus_2_변동률`
FROM macro_with_lead_lag
WHERE ABS(oil_chg_pct) >= 10.0 -- 유가 일간 변동폭 절대값 10% 이상
ORDER BY ABS(oil_chg_pct) DESC;


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
        
        -- [환율] D-2, D-1, D+1, D+2
        LAG(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_minus_2_pct,
        LAG(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_minus_1_pct,
        LEAD(fx_chg_pct, 1) OVER (ORDER BY trade_date) AS fx_d_plus_1_pct,
        LEAD(fx_chg_pct, 2) OVER (ORDER BY trade_date) AS fx_d_plus_2_pct,
        
        -- [유가] D-2, D-1, D+1, D+2
        LAG(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_minus_2_pct,
        LAG(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_minus_1_pct,
        LEAD(oil_chg_pct, 1) OVER (ORDER BY trade_date) AS oil_d_plus_1_pct,
        LEAD(oil_chg_pct, 2) OVER (ORDER BY trade_date) AS oil_d_plus_2_pct,

        -- [금리 변동폭 pt] D-2, D-1, D+1, D+2
        LAG(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_minus_2_pt,
        LAG(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_minus_1_pt,
        LEAD(rate_chg_pt, 1) OVER (ORDER BY trade_date) AS rate_d_plus_1_pt,
        LEAD(rate_chg_pt, 2) OVER (ORDER BY trade_date) AS rate_d_plus_2_pt
    FROM daily_macro
)
SELECT 
    trade_date AS `이벤트_일자`,
    fx_price AS `원달러_환율`,
    
    -- [환율 흐름]
    fx_d_minus_2_pct AS `환율_D-2_변동률`,
    fx_d_minus_1_pct AS `환율_D-1_변동률`,
    fx_chg_pct AS `환율_D0_변동률`,
    fx_d_plus_1_pct AS `환율_D+1_변동률`,
    fx_d_plus_2_pct AS `환율_D+2_변동률`,
    
    -- [유가 흐름]
    oil_d_minus_2_pct AS `유가_D-2_변동률`,
    oil_d_minus_1_pct AS `유가_D-1_변동률`,
    oil_chg_pct AS `유가_D0_변동률`,
    oil_d_plus_1_pct AS `유가_D+1_변동률`,
    oil_d_plus_2_pct AS `유가_D+2_변동률`,

    -- [금리 흐름 (pt)]
    rate_d_minus_2_pt AS `금리_D-2_변동폭`,
    rate_d_minus_1_pt AS `금리_D-1_변동폭`,
    rate_chg_pt AS `금리_D0_변동폭`,
    rate_d_plus_1_pt AS `금리_D+1_변동폭`,
    rate_d_plus_2_pt AS `금리_D+2_변동폭`
FROM macro_with_lead_lag
WHERE ABS(fx_chg_pct) >= 1.5 -- 환율 일간 변동폭 절대값 1.5% 이상
ORDER BY ABS(fx_chg_pct) DESC;