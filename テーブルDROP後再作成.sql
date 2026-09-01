-- 거시지표 데이블 주말 삭제

DELETE FROM macro_data 
WHERE DAYOFWEEK(날짜) IN (1, 7); 


-- 거시지표 변동률 계산

UPDATE macro_data m
JOIN (
    SELECT
        날짜,

        ROUND(
            (환율 - LAG(환율) OVER (ORDER BY 날짜))
            / LAG(환율) OVER (ORDER BY 날짜) * 100, 2
        ) AS 환율변동률,

        ROUND(
            (금리 - LAG(금리) OVER (ORDER BY 날짜))
            / NULLIF(LAG(금리) OVER (ORDER BY 날짜), 0) * 100, 2
        ) AS 금리변동률,

        ROUND(
            (유가 - LAG(유가) OVER (ORDER BY 날짜))
            / LAG(유가) OVER (ORDER BY 날짜) * 100, 2
        ) AS 유가변동률,

        ROUND(
            (물가 - LAG(물가) OVER (ORDER BY 날짜))
            / LAG(물가) OVER (ORDER BY 날짜) * 100, 2
        ) AS 물가변동률

    FROM macro_data
) calc
    ON m.날짜 = calc.날짜

SET
    m.환율_변동률 = calc.환율변동률,
    m.금리_변동률 = calc.금리변동률,
    m.유가_변동률 = calc.유가변동률,
    m.물가_변동률 = calc.물가변동률;
    
    
   --  oil_event 테이블 드랍

DROP TABLE IF EXISTS oil_event;

CREATE TABLE oil_event (
    충격일자 DATE NOT NULL,
    충격일변동률 DECIMAL(15,2) NOT NULL,
    시점구분 VARCHAR(10) NOT NULL,
    실제날짜 DATE NOT NULL,
    PRIMARY KEY (충격일자, 시점구분)
);


-- oil_event 테이블 재생성

INSERT INTO oil_event
    (충격일자, 충격일변동률, 시점구분, 실제날짜)


WITH 거래일 AS (
    SELECT DISTINCT 날짜
    FROM stock_price
),


거래일순서 AS (
    SELECT
        날짜,
        ROW_NUMBER() OVER (ORDER BY 날짜) AS 거래일번호
    FROM 거래일
),


유가충격 AS (
    SELECT
        m.날짜 AS 충격일자,
        m.유가_변동률 AS 충격일변동률,
        t.거래일번호
    FROM macro_data m
    JOIN 거래일순서 t
        ON m.날짜 = t.날짜
    WHERE ABS(m.유가_변동률) >= 10
),


시점 AS (
    SELECT -3 AS n
    UNION ALL SELECT -2
    UNION ALL SELECT -1
    UNION ALL SELECT 0
    UNION ALL SELECT 1
    UNION ALL SELECT 2
    UNION ALL SELECT 3
)


SELECT
    e.충격일자,
    e.충격일변동률,
    CONCAT(s.n, '일') AS 시점구분,
    t.날짜 AS 실제날짜


FROM 유가충격 e


CROSS JOIN 시점 s


JOIN 거래일순서 t
    ON t.거래일번호 = e.거래일번호 + s.n


ORDER BY
    e.충격일자,
    s.n;

-- fx_event 테이블 드랍

DROP TABLE IF EXISTS fx_event;


CREATE TABLE fx_event (
    충격일자 DATE NOT NULL,
    충격일변동률 DECIMAL(15,2) NOT NULL,
    시점구분 VARCHAR(10) NOT NULL,
    실제날짜 DATE NOT NULL,
    PRIMARY KEY (충격일자, 시점구분)
);


-- fx_event 테이블 재생성

INSERT INTO fx_event
    (충격일자, 충격일변동률, 시점구분, 실제날짜)


WITH 거래일 AS (
    SELECT DISTINCT 날짜
    FROM stock_price
),


거래일순서 AS (
    SELECT
        날짜,
        ROW_NUMBER() OVER (ORDER BY 날짜) AS 거래일번호
    FROM 거래일
),


환율충격 AS (
    SELECT
        m.날짜 AS 충격일자,
        m.환율_변동률 AS 충격일변동률,
        t.거래일번호
    FROM macro_data m
    JOIN 거래일순서 t
        ON m.날짜 = t.날짜
    WHERE ABS(m.환율_변동률) >= 1.5
),


시점 AS (
    SELECT -3 AS n
    UNION ALL SELECT -2
    UNION ALL SELECT -1
    UNION ALL SELECT 0
    UNION ALL SELECT 1
    UNION ALL SELECT 2
    UNION ALL SELECT 3
)


SELECT
    e.충격일자,
    e.충격일변동률,
    CONCAT(s.n, '일') AS 시점구분,
    t.날짜 AS 실제날짜


FROM 환율충격 e


CROSS JOIN 시점 s


JOIN 거래일순서 t
    ON t.거래일번호 = e.거래일번호 + s.n


ORDER BY
    e.충격일자,
    s.n;
    
    
    
