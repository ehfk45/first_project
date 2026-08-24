SELECT 
    trade_date,
    wti AS oil_price,
    LAG(wti, 1) OVER (ORDER BY trade_date) AS prev_oil_price,
    ROUND((wti - LAG(wti, 1) OVER (ORDER BY trade_date)) / LAG(wti, 1) OVER (ORDER BY trade_date) * 100, 2) AS oil_change_pct
FROM project_stock.raw_macro_oil
ORDER BY oil_change_pct DESC
LIMIT 10;


SELECT 
    trade_date,
    close_price AS koreanair_close,
    open_price AS koreanair_open,
    ROUND((close_price - open_price) / open_price * 100, 2) AS daily_return_pct
FROM project_stock.raw_stock_koreanair
WHERE trade_date IN ('2026-03-06', '2026-04-02', '2026-03-12', '2026-07-13', '2022-03-01')
ORDER BY trade_date;

SELECT 
    trade_date,
    close_price AS hanair_close,
    open_price AS hanair_open,
    ROUND((close_price - open_price) / open_price * 100, 2) AS daily_return_pct -- 당일 등락률(%)
FROM project_stock.raw_stock_hanair
WHERE trade_date IN ('2026-03-06', '2026-03-12', '2026-04-02', '2026-07-13', '2022-03-01')
ORDER BY trade_date;


SELECT 
    k.trade_date,
    k.close_price AS koreanair_close,
    ROUND((k.close_price - 24900) / 24900 * 100, 2) AS koreanair_return_pct,
    h.close_price AS hanair_close,
    ROUND((h.close_price - 499000) / 499000 * 100, 2) AS hanair_return_pct
FROM project_stock.raw_stock_koreanair k
JOIN project_stock.raw_stock_hanair h 
    ON k.trade_date = h.trade_date
WHERE k.trade_date >= '2026-04-02'
ORDER BY k.trade_date
LIMIT 6;