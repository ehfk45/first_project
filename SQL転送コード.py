import csv
import pymysql


# -----------------------------------
# 1. MySQL 연결
# -----------------------------------

conn = pymysql.connect(
    host="localhost",
    user="root",
    password="class1234",   # 본인 비밀번호
    charset="utf8mb4"
)

cursor = conn.cursor()


# -----------------------------------
# 2. 데이터베이스 생성 및 선택
# -----------------------------------

cursor.execute(
    "CREATE DATABASE IF NOT EXISTS project_stock;"
)

cursor.execute(
    "USE project_stock;"
)


# -----------------------------------
# 3. 기존 테이블 삭제
# -----------------------------------

cursor.execute(
    "DROP TABLE IF EXISTS stock_price;"
)


# -----------------------------------
# 4. stock_price 테이블 생성
# -----------------------------------

sql = """
CREATE TABLE stock_price (
    trade_date DATE NOT NULL,
    company VARCHAR(30) NOT NULL,
    close_price DECIMAL(15,2),
    open_price DECIMAL(15,2),
    high_price DECIMAL(15,2),
    low_price DECIMAL(15,2),

    PRIMARY KEY (trade_date, company)
);
"""

cursor.execute(sql)


# -----------------------------------
# 5. CSV 파일 읽기
# -----------------------------------

with open(
    "stock_price.csv",
    "r",
    encoding="utf-8-sig"
) as f:

    reader = csv.DictReader(f)


    # -----------------------------------
    # 6. INSERT SQL
    # -----------------------------------

    insert_sql = """
    INSERT INTO stock_price (
        trade_date,
        company,
        close_price,
        open_price,
        high_price,
        low_price
    )
    VALUES (%s, %s, %s, %s, %s, %s);
    """


    # -----------------------------------
    # 7. CSV 데이터 INSERT
    # -----------------------------------

    count = 0

    for row in reader:

        cursor.execute(
            insert_sql,
            (
                row["날짜"],
                row["회사명"],
                row["종가"],
                row["시가"],
                row["고가"],
                row["저가"]
            )
        )

        count += 1


# -----------------------------------
# 8. 저장
# -----------------------------------

conn.commit()


print("stock_price 테이블 생성 완료")
print("데이터 INSERT 완료")
print("저장된 데이터 개수 :", count)


# -----------------------------------
# 9. 연결 종료
# -----------------------------------

cursor.close()
conn.close()
