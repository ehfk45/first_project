import pandas as pd

# 1. 이전 거시지표 파일 불러오기
df = pd.read_csv('macro_data_merged_10yr_dubai.csv')

# 2. 요청하신 컬럼명으로 변경
column_mapping = {
    '날짜': '날짜(year-month-date)',
    '원/미국달러': '환율(￦)',
    '기준금리': '금리(%)',
    'dubai': '유가($)',
    '총지수': '물가(￦)'
}

df_renamed = df.rename(columns=column_mapping)

# 3. 최종 파일 저장
df_renamed.to_csv('macro_data_final.csv', index=False, encoding='utf-8-sig')
print("컬럼명 변경 완료 및 저장 성공!")