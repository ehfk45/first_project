import csv
import pymysql

# -----------------------------
# 1. MySQL 연결
# -----------------------------
conn = pymysql.connect(
    host="localhost",
    user="root",
    password="class1234",
    database="project_stock",
    charset="utf8mb4"
)

cursor = conn.cursor()


# -----------------------------
# 2. 테이블 생성
# -----------------------------
cursor.execute("""
CREATE TABLE IF NOT EXISTS macro_data (
    날짜 DATE PRIMARY KEY,
    환율 DECIMAL(10,2),
    금리 DECIMAL(5,2),
    유가 DECIMAL(10,2),
    물가 DECIMAL(10,3)
);
""")


# -----------------------------
# 3. CSV 파일 읽어서 SQL에 저장
# -----------------------------
with open("거시지표 10년치 데이터.csv", "r", encoding="utf-8-sig") as f:

    reader = csv.DictReader(f)

    for row in reader:

        sql = """
        INSERT INTO macro_data (날짜, 환율, 금리, 유가, 물가)
        VALUES (%s, %s, %s, %s, %s)
        """

        cursor.execute(sql, (
            row["날짜(year-month-date)"],
            row["환율(￦)"],
            row["금리(%)"],
            row["유가($)"],
            row["물가(￦)"]
        ))


# -----------------------------
# 4. 저장 및 종료
# -----------------------------
conn.commit()

cursor.close()
conn.close()

print("거시지표 데이터 저장 완료!")