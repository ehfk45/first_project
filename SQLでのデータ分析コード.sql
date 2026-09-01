-- 집계함수
-- oil_stock_analysis 뷰 생성
    CREATE VIEW oil_stock_analysis AS
SELECT
    o.충격일자,
    o.충격일변동률 AS 유가충격변동률,
    o.시점구분,
    o.실제날짜,
    s.회사명,
    s.종가,
    s.변동률 AS 주가변동률
FROM oil_event o
JOIN stock_price s
    ON o.실제날짜 = s.날짜;


-- fx_stock_analysis 뷰 생성

CREATE VIEW fx_stock_analysis AS
SELECT
    f.충격일자,
    f.충격일변동률 AS 환율충격변동률,
    f.시점구분,
    f.실제날짜,
    s.회사명,
    s.종가,
    s.변동률 AS 주가변동률
FROM fx_event f
JOIN stock_price s
    ON f.실제날짜 = s.날짜;
    
    
--  회사별·시점별 평균 주가변동률
-- 유가

    SELECT
    회사명,
    시점구분,
    ROUND(AVG(주가변동률), 2) AS 평균주가변동률
FROM oil_stock_analysis
GROUP BY
    회사명,
    시점구분
ORDER BY
    회사명,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);


-- 환율
    SELECT
    회사명,
    시점구분,
    ROUND(AVG(주가변동률), 2) AS 평균주가변동률
FROM fx_stock_analysis
GROUP BY
    회사명,
    시점구분
ORDER BY
    회사명,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);

-- 평균 절대변동률
-- 유가

    SELECT
    회사명,
    시점구분,
    ROUND(AVG(ABS(주가변동률)), 2) AS 평균절대변동률
FROM oil_stock_analysis
GROUP BY
    회사명,
    시점구분
ORDER BY
    회사명,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);


-- 유가충격변동률 >= 10 → 유가 급등
-- 유가충격변동률 <= -10 → 유가 급락

-- 회사별·시점별 평균 주가변동률을 비교

    SELECT
    회사명,


    CASE
        WHEN 유가충격변동률 >= 10 THEN '유가 급등'
        WHEN 유가충격변동률 <= -10 THEN '유가 급락'
    END AS 충격구분,


    시점구분,


    ROUND(AVG(주가변동률), 2) AS 평균주가변동률


FROM oil_stock_analysis


GROUP BY
    회사명,
    충격구분,
    시점구분


ORDER BY
    회사명,
    충격구분,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);


-- 시점 구분 0일 일때
-- 회사별 급등,급락일 때 평균 주가 변동률, 평균 절대 변동률




    SELECT
    회사명,


    CASE
        WHEN 유가충격변동률 >= 10 THEN '유가 급등'
        WHEN 유가충격변동률 <= -10 THEN '유가 급락'
    END AS 충격구분,


    ROUND(AVG(주가변동률), 2) AS 평균주가변동률,
    ROUND(AVG(ABS(주가변동률)), 2) AS 평균절대변동률,
    COUNT(*) AS 이벤트수


FROM oil_stock_analysis


WHERE 시점구분 = '0일'


GROUP BY
    회사명,
    충격구분


ORDER BY 회사명, 충격구분;


-- 충격 후 누적 주가변동률 분석

WITH daily AS (
    SELECT
        충격일자,
        회사명,
        CASE
            WHEN 유가충격변동률 >= 10 THEN '유가 급등'
            WHEN 유가충격변동률 <= -10 THEN '유가 급락'
        END AS 충격구분,
        CAST(REPLACE(시점구분, '일', '') AS SIGNED) AS 시점,
        주가변동률
    FROM oil_stock_analysis
    WHERE CAST(REPLACE(시점구분, '일', '') AS SIGNED) BETWEEN 0 AND 3
),


cum AS (
    SELECT
        충격일자,
        회사명,
        충격구분,
        시점,
        주가변동률,


        (
            EXP(
                SUM(
                    LN(1 + 주가변동률 / 100)
                ) OVER (
                    PARTITION BY 충격일자, 회사명
                    ORDER BY 시점
                )
            ) - 1
        ) * 100 AS 누적수익률


    FROM daily
)


SELECT
    회사명,
    충격구분,
    시점,
    ROUND(AVG(누적수익률), 2) AS 평균누적수익률
FROM cum
GROUP BY
    회사명,
    충격구분,
    시점
ORDER BY
    회사명,
    충격구분,
    시점;


-- 평균 주가변동률 → 평균 절대변동률 → 급등/급락 분리 → ±3일 반응 → 충격 이후 누적수익률

-- 1. 회사별·시점별 평균 주가변동률

-- 먼저 환율 충격 전후 -3일 ~ +3일 동안 회사별 평균 주가변동률을 확인해.

SELECT
    회사명,
    시점구분,
    ROUND(AVG(주가변동률), 2) AS 평균주가변동률
FROM fx_stock_analysis
GROUP BY
    회사명,
    시점구분
ORDER BY
    회사명,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);
    
    
-- 2. 평균 절대변동률 확인

-- 상승/하락 방향을 무시하고 주가가 얼마나 크게 움직였는지 확인해.

SELECT
    회사명,
    시점구분,
    ROUND(AVG(주가변동률), 2) AS 평균주가변동률,
    ROUND(AVG(ABS(주가변동률)), 2) AS 평균절대변동률,
    ROUND(MAX(주가변동률), 2) AS 최대상승률,
    ROUND(MIN(주가변동률), 2) AS 최대하락률
FROM fx_stock_analysis
GROUP BY
    회사명,
    시점구분
ORDER BY
    회사명,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);


-- 3. 환율 급등 / 급락 분리

SELECT
    회사명,


    CASE
        WHEN 환율충격변동률 >= 1.5 THEN '환율 급등'
        WHEN 환율충격변동률 <= -1.5 THEN '환율 급락'
    END AS 충격구분,


    시점구분,


    ROUND(AVG(주가변동률), 2) AS 평균주가변동률


FROM fx_stock_analysis


GROUP BY
    회사명,
    충격구분,
    시점구분


ORDER BY
    회사명,
    충격구분,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);
    
    
-- 4. 충격 당일 0일만 따로 비교

-- 충격 당일만 뽑아서 4개 회사를 비교

SELECT
    회사명,


    CASE
        WHEN 환율충격변동률 >= 1.5 THEN '환율 급등'
        WHEN 환율충격변동률 <= -1.5 THEN '환율 급락'
    END AS 충격구분,


    ROUND(AVG(주가변동률), 2) AS 평균주가변동률,
    ROUND(AVG(ABS(주가변동률)), 2) AS 평균절대변동률,
    COUNT(*) AS 이벤트수


FROM fx_stock_analysis


WHERE 시점구분 = '0일'


GROUP BY
    회사명,
    충격구분


ORDER BY
    회사명,
    충격구분;


-- 5. 환율 급등/급락별 ±3일 흐름

-- 4번 분석과 동일한 단계

SELECT
    회사명,


    CASE
        WHEN 환율충격변동률 >= 1.5 THEN '환율 급등'
        WHEN 환율충격변동률 <= -1.5 THEN '환율 급락'
    END AS 충격구분,


    시점구분,


    ROUND(AVG(주가변동률), 2) AS 평균주가변동률,


    ROUND(AVG(ABS(주가변동률)), 2) AS 평균절대변동률,


    COUNT(*) AS 데이터수


FROM fx_stock_analysis


GROUP BY
    회사명,
    충격구분,
    시점구분


ORDER BY
    회사명,
    충격구분,
    CAST(REPLACE(시점구분, '일', '') AS SIGNED);
    
    
-- 6. 환율 충격 이후 누적수익률

-- 0일 → +3일 누적수익률 계산

WITH daily AS (
    SELECT
        충격일자,
        회사명,


        CASE
            WHEN 환율충격변동률 >= 1.5 THEN '환율 급등'
            WHEN 환율충격변동률 <= -1.5 THEN '환율 급락'
        END AS 충격구분,


        CAST(REPLACE(시점구분, '일', '') AS SIGNED) AS 시점,
        주가변동률


    FROM fx_stock_analysis


    WHERE CAST(REPLACE(시점구분, '일    ', '') AS SIGNED)
          BETWEEN 0 AND 3
),


cum AS (
    SELECT
        충격일자,
        회사명,
        충격구분,
        시점,
        주가변동률,


        (
            EXP(
                SUM(
                    LN(1 + 주가변동률 / 100)
                ) OVER (
                    PARTITION BY 충격일자, 회사명
                    ORDER BY 시점
                )
            ) - 1
        ) * 100 AS 누적수익률


    FROM daily
)


SELECT
    회사명,
    충격구분,
    시점,
    ROUND(AVG(누적수익률), 2) AS 평균누적수익률


FROM cum


GROUP BY
    회사명,
    충격구분,
    시점;


-- 유가 충격 vs 환율 충격 중 어떤 쪽에서 각 회사의 주가 반응이 더 컸는지 비교


-- 충격 당일 0일의 평균 절대변동률 “얼마나 크게 움직였는가”를 비교


WITH oil AS (
    SELECT
        회사명,
        ROUND(AVG(ABS(주가변동률)), 2) AS 유가_평균절대변동률
    FROM oil_stock_analysis
    WHERE 시점구분 = '0일'
    GROUP BY 회사명
),


fx AS (
    SELECT
        회사명,
        ROUND(AVG(ABS(주가변동률)), 2) AS 환율_평균절대변동률
    FROM fx_stock_analysis
    WHERE 시점구분 = '0일'
    GROUP BY 회사명
)


SELECT
    o.회사명,
    o.유가_평균절대변동률,
    f.환율_평균절대변동률,


    ROUND(
        o.유가_평균절대변동률 - f.환율_평균절대변동률,
        2
    ) AS 차이,


    CASE
        WHEN o.유가_평균절대변동률 > f.환율_평균절대변동률
            THEN '유가 충격에 더 민감'
        WHEN o.유가_평균절대변동률 < f.환율_평균절대변동률
            THEN '환율 충격에 더 민감'
        ELSE '비슷함'
    END AS 민감도구분


FROM oil o
JOIN fx f
    ON o.회사명 = f.회사명


ORDER BY o.회사명;



-- 충격 이후 +3일까지의 누적수익률 크기도 비교


-- 유가와 환율 각각 0일~3일 누적수익률을 계산한 다음, 회사별 평균을 비교.


WITH oil_daily AS (
    SELECT
        충격일자,
        회사명,
        CAST(REPLACE(시점구분, '일', '') AS SIGNED) AS 시점,
        주가변동률
    FROM oil_stock_analysis
    WHERE CAST(REPLACE(시점구분, '일', '') AS SIGNED)
          BETWEEN 0 AND 3
),


oil_cum AS (
    SELECT
        충격일자,
        회사명,
        시점,


        (
            EXP(
                SUM(
                    LN(1 + 주가변동률 / 100)
                ) OVER (
                    PARTITION BY 충격일자, 회사명
                    ORDER BY 시점
                )
            ) - 1
        ) * 100 AS 누적수익률


    FROM oil_daily
),


oil_result AS (
    SELECT
        회사명,
        ROUND(AVG(ABS(누적수익률)), 2) AS 유가_평균누적변동폭
    FROM oil_cum
    WHERE 시점 = 3
    GROUP BY 회사명
),


fx_daily AS (
    SELECT
        충격일자,
        회사명,
        CAST(REPLACE(시점구분, '일', '') AS SIGNED) AS 시점,
        주가변동률
    FROM fx_stock_analysis
    WHERE CAST(REPLACE(시점구분, '일', '') AS SIGNED)
          BETWEEN 0 AND 3
),


fx_cum AS (
    SELECT
        충격일자,
        회사명,
        시점,


        (
            EXP(
                SUM(
                    LN(1 + 주가변동률 / 100)
                ) OVER (
                    PARTITION BY 충격일자, 회사명
                    ORDER BY 시점
                )
            ) - 1
        ) * 100 AS 누적수익률


    FROM fx_daily
),


fx_result AS (
    SELECT
        회사명,
        ROUND(AVG(ABS(누적수익률)), 2) AS 환율_평균누적변동폭
    FROM fx_cum
    WHERE 시점 = 3
    GROUP BY 회사명
)


SELECT
    o.회사명,
    o.유가_평균누적변동폭,
    f.환율_평균누적변동폭,


    ROUND(
        o.유가_평균누적변동폭 - f.환율_평균누적변동폭,
        2
    ) AS 차이,


    CASE
        WHEN o.유가_평균누적변동폭 > f.환율_평균누적변동폭
            THEN '유가 충격 영향이 더 큼'
        WHEN o.유가_평균누적변동폭 < f.환율_평균누적변동폭
            THEN '환율 충격 영향이 더 큼'
        ELSE '비슷함'
    END AS 비교결과


FROM oil_result o
JOIN fx_result f
    ON o.회사명 = f.회사명


ORDER BY o.회사명;
