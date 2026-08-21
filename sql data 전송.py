import csv
import pymysql

# -----------------------------
# 1. MySQL 연결 설정
# -----------------------------
conn = pymysql.connect(
    host="localhost",
    user="root",
    password="class1234",  # 본인 MySQL 비밀번호
    charset="utf8mb4",
)
cursor = conn.cursor()

# 데이터베이스 생성 및 선택
cursor.execute("CREATE DATABASE IF NOT EXISTS project_stock;")
cursor.execute("USE project_stock;")

# -----------------------------
# 2. 테이블 생성 (DDL)
# -----------------------------
# 주가 테이블 4개
cursor.execute("DROP TABLE IF EXISTS raw_stock_hynix;")
cursor.execute("""
CREATE TABLE raw_stock_hynix (
    trade_date DATE PRIMARY KEY,
    close_price DECIMAL(12, 2),
    open_price DECIMAL(12, 2),
    high_price DECIMAL(12, 2),
    low_price DECIMAL(12, 2),
    volume BIGINT
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_stock_shinhan;")
cursor.execute("""
CREATE TABLE raw_stock_shinhan (
    trade_date DATE PRIMARY KEY,
    close_price DECIMAL(12, 2),
    open_price DECIMAL(12, 2),
    high_price DECIMAL(12, 2),
    low_price DECIMAL(12, 2),
    volume BIGINT
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_stock_koreanair;")
cursor.execute("""
CREATE TABLE raw_stock_koreanair (
    trade_date DATE PRIMARY KEY,
    close_price DECIMAL(12, 2),
    open_price DECIMAL(12, 2),
    high_price DECIMAL(12, 2),
    low_price DECIMAL(12, 2),
    volume BIGINT
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_stock_hanair;")
cursor.execute("""
CREATE TABLE raw_stock_hanair (
    trade_date DATE PRIMARY KEY,
    close_price DECIMAL(12, 2),
    open_price DECIMAL(12, 2),
    high_price DECIMAL(12, 2),
    low_price DECIMAL(12, 2),
    volume BIGINT
);
""")

# 거시 4대 지표 테이블 4개
cursor.execute("DROP TABLE IF EXISTS raw_macro_rate;")
cursor.execute("""
CREATE TABLE raw_macro_rate (
    trade_date DATE PRIMARY KEY,
    base_rate DECIMAL(6, 2)
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_macro_fx;")
cursor.execute("""
CREATE TABLE raw_macro_fx (
    trade_date DATE PRIMARY KEY,
    usd_krw DECIMAL(10, 2)
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_macro_cpi;")
cursor.execute("""
CREATE TABLE raw_macro_cpi (
    trade_date DATE PRIMARY KEY,
    cpi DECIMAL(8, 2)
);
""")

cursor.execute("DROP TABLE IF EXISTS raw_macro_oil;")
cursor.execute("""
CREATE TABLE raw_macro_oil (
    trade_date DATE PRIMARY KEY,
    wti DECIMAL(8, 2),
    brent DECIMAL(8, 2),
    dubai DECIMAL(8, 2)
);
""")

# -----------------------------
# 3. 주가 파일 읽어서 INSERT
# -----------------------------

# (1) SK하이닉스
with open("sk_hynix_all.csv", "r", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    header = next(reader)  # 헤더 한 줄 건너뛰기
    for row in reader:
        if row:
            sql = "INSERT INTO raw_stock_hynix VALUES (%s, %s, %s, %s, %s, %s)"
            cursor.execute(
                sql,
                (
                    row[0],
                    float(row[1].replace(",", "")),
                    float(row[2].replace(",", "")),
                    float(row[3].replace(",", "")),
                    float(row[4].replace(",", "")),
                    int(row[5].replace(",", "")),
                ),
            )

# (2) 신한지주 (신한 파일은 cp949 인코딩)
with open("SHINHAN_all.csv", "r", encoding="cp949") as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        if row:
            sql = "INSERT INTO raw_stock_shinhan VALUES (%s, %s, %s, %s, %s, %s)"
            cursor.execute(
                sql,
                (
                    row[0],
                    float(row[1].replace(",", "")),
                    float(row[2].replace(",", "")),
                    float(row[3].replace(",", "")),
                    float(row[4].replace(",", "")),
                    int(row[5].replace(",", "")),
                ),
            )

# (3) 대한항공
with open("DAEHAN_AIR_all.csv", "r", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        if row:
            sql = "INSERT INTO raw_stock_koreanair VALUES (%s, %s, %s, %s, %s, %s)"
            cursor.execute(
                sql,
                (
                    row[0],
                    float(row[1].replace(",", "")),
                    float(row[2].replace(",", "")),
                    float(row[3].replace(",", "")),
                    float(row[4].replace(",", "")),
                    int(row[5].replace(",", "")),
                ),
            )

# (4) 한화에어로스페이스
with open("HAN_AIR_all.csv", "r", encoding="utf-8-sig") as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        if row:
            sql = "INSERT INTO raw_stock_hanair VALUES (%s, %s, %s, %s, %s, %s)"
            cursor.execute(
                sql,
                (
                    row[0],
                    float(row[1].replace(",", "")),
                    float(row[2].replace(",", "")),
                    float(row[3].replace(",", "")),
                    float(row[4].replace(",", "")),
                    int(row[5].replace(",", "")),
                ),
            )

# -----------------------------
# 4. 거시 4대 지표 파일 읽어서 INSERT (공백 분리)
# -----------------------------

# (1) 기준금리
with open("base_rate_cleaned.csv", "r", encoding="utf-8-sig") as f:
    lines = f.readlines()
    for line in lines[1:]:  # 헤더 제외
        row = line.split()  # 띄어쓰기 기준으로 자르기
        if row:
            sql = "INSERT INTO raw_macro_rate VALUES (%s, %s)"
            cursor.execute(sql, (row[0], float(row[1])))

# (2) 원/달러 환율
with open("usd_krw_cleaned.csv", "r", encoding="utf-8-sig") as f:
    lines = f.readlines()
    for line in lines[1:]:
        row = line.split()
        if row:
            sql = "INSERT INTO raw_macro_fx VALUES (%s, %s)"
            cursor.execute(sql, (row[0], float(row[1])))

# (3) 소비자물가지수 (CPI)
with open("cpi_daily_filled.csv", "r", encoding="utf-8-sig") as f:
    lines = f.readlines()
    for line in lines[1:]:
        row = line.split()
        if row:
            sql = "INSERT INTO raw_macro_cpi VALUES (%s, %s)"
            cursor.execute(sql, (row[0], float(row[1])))

# (4) 국제유가 3종
with open("oil_prices_cleaned.csv", "r", encoding="utf-8-sig") as f:
    lines = f.readlines()
    for line in lines[1:]:
        row = line.split()
        if row:
            sql = "INSERT INTO raw_macro_oil VALUES (%s, %s, %s, %s)"
            cursor.execute(
                sql,
                (row[0], float(row[1]), float(row[2]), float(row[3])),
            )

# -----------------------------
# 5. 커밋 및 접속 종료
# -----------------------------
conn.commit()
cursor.close()
conn.close()

print("8개 주가 및 거시지표 테이블 데이터 입력 완료")
