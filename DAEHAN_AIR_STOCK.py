import csv

# 합칠 CSV 파일 3개
files = [
    "DAEHAN_AIR_2123.csv",
    "DAEHAN_AIR_2325.csv",
    "DAEHAN_AIR_2526.csv"
]

# 3개 파일의 데이터를 저장할 리스트
DAEHAN_AIR_list = []

# 삭제할 컬럼
remove_columns = [
    "대비",
    "등락률",
    "거래대금",
    "시가총액",
    "상장주식수"
]

# 1. CSV 파일 3개 읽어서 하나의 리스트에 합치기
for file in files:

    with open(file, "r", encoding="cp949") as f:

        reader = csv.DictReader(f)

        reader.fieldnames[0] = "날짜"

        for row in reader:
             # 필요 없는 컬럼 삭제
            for column in remove_columns:
                row.pop(column, None)

            # 필요한 데이터만 리스트에 추가
            DAEHAN_AIR_list.append(row)


# 2. 합친 데이터를 새로운 CSV 파일로 저장
with open(
    "DAEHAN_AIR_all.csv",
    "w",
    newline="",
    encoding="utf-8-sig"
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=DAEHAN_AIR_list[0].keys()
    )

    # 컬럼명 작성
    writer.writeheader()

    # 전체 데이터 작성
    writer.writerows(DAEHAN_AIR_list)


print("파일 합치기 완료!")
print("총 데이터 개수:", len(DAEHAN_AIR_list))