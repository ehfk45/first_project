import csv
from datetime import datetime


# -----------------------------------
# 1. CSV 파일 읽기 함수
# -----------------------------------

def read_csv_file(file_name):

    encodings = [
        "utf-8-sig",
        "utf-8",
        "cp949",
        "euc-kr"
    ]

    for encoding in encodings:

        try:
            with open(file_name, "r", encoding=encoding) as f:

                reader = csv.DictReader(f)

                # 실제로 파일 전체를 읽어봐야
                # 인코딩 오류 여부를 정확히 알 수 있음
                rows = list(reader)

                print(
                    file_name,
                    "→",
                    encoding,
                    "읽기 성공"
                )

                return rows

        except UnicodeDecodeError:
            continue


    print(file_name, "→ 읽기 실패")

    return []


# -----------------------------------
# 2. 회사별 파일 목록
# -----------------------------------

company_files = {

    "대한항공": [
        "DAEHAN_AIR_16_17.csv",
        "DAEHAN_AIR_17_19.csv",
        "DAEHAN_AIR_19_21.csv",
        "DAEHAN_AIR_all.csv"
    ],

    "신한지주": [
        "SHINHAN_16_17.csv",
        "SHINHAN_17_19.csv",
        "SHINHAN_19_21.csv",
        "SHINHAN_all.csv"
    ],

    "하이닉스": [
        "sk_hynix_16_17.csv",
        "sk_hynix_17_19.csv",
        "sk_hynix_19_21.csv",
        "sk_hynix_all.csv"
    ],

    "한화에어로": [
        "HAN_AIR_16_17.csv",
        "HAN_AIR_17_19.csv",
        "HAN_AIR_19_21.csv",
        "HAN_AIR_all.csv"
    ]
}


# -----------------------------------
# 3. 전체 회사 데이터를 저장할 리스트
# -----------------------------------

stock_list = []


# -----------------------------------
# 4. 회사별 파일 읽기
# -----------------------------------

for company, files in company_files.items():

    company_data = []

    print()
    print("========================")
    print(company)
    print("========================")


    for file_name in files:

        # 인코딩 자동 확인 후 파일 읽기
        rows = read_csv_file(file_name)


        # -----------------------------------
        # 5. 각 행 데이터 전처리
        # -----------------------------------

        for row in rows:

            # -------------------------------
            # 날짜 컬럼 확인
            # -------------------------------

            # 새로 받은 파일은 "일자"
            if "일자" in row:
                date = row["일자"]

            # 기존 all 파일은 "날짜"
            elif "날짜" in row:
                date = row["날짜"]

            else:
                print(file_name, "→ 날짜 컬럼 없음")
                continue


            # -------------------------------
            # 날짜 형식 통일
            # -------------------------------

            # 2016/07/01 → 2016-07-01
            date = date.replace("/", "-")


            # -------------------------------
            # 필요한 컬럼만 가져오기
            # -------------------------------

            new_row = {
                "날짜": date,
                "회사명": company,
                "종가": row["종가"],
                "시가": row["시가"],
                "고가": row["고가"],
                "저가": row["저가"]
            }


            company_data.append(new_row)


    # -----------------------------------
    # 6. 회사별 중복 날짜 제거
    # -----------------------------------

    date_dict = {}


    for row in company_data:

        date = row["날짜"]


        # 같은 날짜가 아직 없을 경우만 저장
        if date not in date_dict:

            date_dict[date] = row


    # 딕셔너리 → 리스트
    company_data = list(date_dict.values())


    # -----------------------------------
    # 7. 날짜 오름차순 정렬
    # -----------------------------------

    company_data.sort(
        key=lambda x: datetime.strptime(
            x["날짜"],
            "%Y-%m-%d"
        )
    )


    # -----------------------------------
    # 8. 회사별 결과 확인
    # -----------------------------------

    print()
    print("회사명 :", company)
    print("데이터 개수 :", len(company_data))


    if len(company_data) > 0:

        print(
            "시작 날짜 :",
            company_data[0]["날짜"]
        )

        print(
            "마지막 날짜 :",
            company_data[-1]["날짜"]
        )


    print()


    # -----------------------------------
    # 9. 전체 데이터에 추가
    # -----------------------------------

    stock_list.extend(company_data)


# -----------------------------------
# 10. 전체 데이터 날짜 오름차순 정렬
# -----------------------------------

stock_list.sort(
    key=lambda x: (
        datetime.strptime(
            x["날짜"],
            "%Y-%m-%d"
        ),
        x["회사명"]
    )
)


# -----------------------------------
# 11. 최종 컬럼 순서
# -----------------------------------

columns = [
    "날짜",
    "회사명",
    "종가",
    "시가",
    "고가",
    "저가"
]


# -----------------------------------
# 12. CSV 파일 저장
# -----------------------------------

with open(
    "stock_price.csv",
    "w",
    newline="",
    encoding="utf-8-sig"
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=columns
    )


    # 컬럼명 작성
    writer.writeheader()


    # 데이터 작성
    writer.writerows(stock_list)


# -----------------------------------
# 13. 최종 결과 확인
# -----------------------------------

print()
print("========================")
print("최종 결과")
print("========================")

print(
    "전체 데이터 개수 :",
    len(stock_list)
)

print(
    "stock_price.csv 저장 완료"
)