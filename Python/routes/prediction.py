from fastapi import APIRouter
from pydantic import BaseModel
import pandas as pd
import joblib
import requests
from datetime import datetime
import os

# OpenWeatherMap API 설정
OPENWEATHER_API_KEY = os.getenv("OPENWEATHER_API_KEY", "your_api_key_here")
HANGANG_LAT = 37.5097778  # 한강공원 위도
HANGANG_LON = 126.9952838  # 한강공원 경도  


router = APIRouter()

# =============================
# 1. 모델 로드
# =============================

# 버스 모델 (4개)
bus_model_weekday_승차 = joblib.load("model/평일_승차.h5")
bus_model_weekday_하차 = joblib.load("model/평일_하차.h5")
bus_model_holiday_승차 = joblib.load("model/공휴일_승차.h5")
bus_model_holiday_하차 = joblib.load("model/공휴일_하차.h5")

# 주차 모델 (8개) - 일별 예측
parking_model_weekday_승차_반포1 = joblib.load("model/평일_승차_주차예측_반포1주차장.h5")
parking_model_weekday_승차_반포23 = joblib.load("model/평일_승차_주차예측_반포23주차장.h5")
parking_model_weekday_하차_반포1 = joblib.load("model/평일_하차_주차예측_반포1주차장.h5")
parking_model_weekday_하차_반포23 = joblib.load("model/평일_하차_주차예측_반포23주차장.h5")

parking_model_holiday_승차_반포1 = joblib.load("model/공휴일_승차_주차예측_반포1주차장.h5")
parking_model_holiday_승차_반포23 = joblib.load("model/공휴일_승차_주차예측_반포23주차장.h5")
parking_model_holiday_하차_반포1 = joblib.load("model/공휴일_하차_주차예측_반포1주차장.h5")
parking_model_holiday_하차_반포23 = joblib.load("model/공휴일_하차_주차예측_반포23주차장.h5")

# 버스 일별 모델 (2개) - 추가된 일별 예측 모델
bus_daily_model_승차 = joblib.load("model/일별_승차_xgb_model.pkl")  # 버스 일별 총 승차량 예측
bus_daily_model_하차 = joblib.load("model/일별_하차_xgb_model.pkl")  # 버스 일별 총 하차량 예측

# =============================
# 2. 시간별 가중치 정의
# =============================

# 승차 공휴일 가중치
hourly_weights_승차_공휴일 = {
    0: 1.795671834625323, 1: 0.0, 2: 0.0, 3: 0.0, 4: 8.199074074074074,
    5: 3.6701388888888893, 6: 1.9587107487922706, 7: 1.4412378821774794,
    8: 1.4127693158888237, 9: 1.4960442346358946, 10: 1.5163764510779436,
    11: 1.5757936507936507, 12: 1.4375998402555912, 13: 1.4020855240098142,
    14: 1.4788533074559276, 15: 1.5756257631257629, 16: 1.5748387896825395,
    17: 1.5065545574448365, 18: 1.5585963653754185, 19: 1.6643439176108414,
    20: 1.5403966462650047, 21: 1.4147029138142884, 22: 1.488115126806041,
    23: 1.4908538161329508
}

# 승차 평일 가중치
hourly_weights_승차_평일 = {
    0: 1.8786531568789635, 1: 0.0, 2: 0.0, 3: 0.0, 4: 12.059027777777777,
    5: 4.060007122507123, 6: 2.0426701991008347, 7: 1.4765856319152253,
    8: 1.4400840776830424, 9: 1.53198895279832, 10: 1.570161996497373,
    11: 1.6458635265700483, 12: 1.4867839090143218, 13: 1.5017325216325905,
    14: 1.5373156721536352, 15: 1.6306901868728712, 16: 1.642077352021401,
    17: 1.5839186064289263, 18: 1.6322083461027685, 19: 1.7294861930948657,
    20: 1.588083224652399, 21: 1.4597005350063001, 22: 1.5429869417701276,
    23: 1.5516855281207134
}

# 하차 공휴일 가중치
hourly_weights_하차_공휴일 = {
    0: 3.0969230769230767, 1: 0.0, 2: 0.0, 3: 0.0, 4: 4.264615384615385,
    5: 2.4476113360323883, 6: 2.353984753984754, 7: 2.6799863852961194,
    8: 2.813302486986698, 9: 2.6765082108902334, 10: 2.7735614515805658,
    11: 2.305742145178765, 12: 2.4494314381270903, 13: 2.319946018893387,
    14: 2.3122384182421705, 15: 2.40734709828698, 16: 2.266508875739645,
    17: 2.251492681668709, 18: 2.0877485692113686, 19: 2.1174382178907063,
    20: 2.1488190682556882, 21: 2.168269230769231, 22: 2.183333333333333,
    23: 2.394838056680162
}

# 하차 평일 가중치
hourly_weights_하차_평일 = {
    0: 3.386574074074074, 1: 0.0, 2: 0.0, 3: 0.0, 4: 2.591011743450768,
    5: 1.7585034013605443, 6: 1.7312727686703095, 7: 1.559689771547248,
    8: 1.6361679454390452, 9: 1.6050052273915316, 10: 1.683780864197531,
    11: 1.723682015348682, 12: 1.9613647967324015, 13: 1.973625557206538,
    14: 1.9544506258692629, 15: 1.9496730752576428, 16: 1.9224113296352325,
    17: 1.8452571542925755, 18: 1.7532700421940928, 19: 1.6390388429352294,
    20: 1.7964687660633607, 21: 1.6971334904765774, 22: 1.7198325874357698,
    23: 1.760127314814815
}

# =============================
# 3. 입력 스키마 정의
# =============================
class PredictionRequest(BaseModel):
    date: str
    hour: int
    holiday: int      # 0=평일, 1=공휴일
    discomfort: float # 불쾌지수
    peak: int         # 피크타임 여부 (0,1)
    month: int
    weekday: int      # 0=월 ~ 6=일
    mode: str         # "승차" or "하차"

# =============================
# 4. 일별 총 승하차 수 계산 함수
# =============================
def calculate_daily_total(req: PredictionRequest, mode: str):
    """버스 일별 예측 모델로 총 승하차 수 계산"""
    
    # 구분 원핫 인코딩 (평일/공휴일에 따라)
    if req.holiday == 0:  # 평일
        구분_공휴일 = 0
        구분_평일 = 1
    else:  # 공휴일/주말
        구분_공휴일 = 1
        구분_평일 = 0
    
    # 버스 일별 예측을 위한 features
    daily_features = pd.DataFrame([{
        "일별_불쾌지수평균": req.discomfort,
        "월_num": req.month,
        "요일_num": req.weekday,
        "구분_공휴일": 구분_공휴일,
        "구분_평일": 구분_평일
    }])
    
    # 버스 일별 총 승하차량 예측
    if mode == "승차":
        daily_total = bus_daily_model_승차.predict(daily_features)[0]
    else:
        daily_total = bus_daily_model_하차.predict(daily_features)[0]
    
    return max(0, daily_total)  # 음수 방지

# =============================
# 5. 시간별 가중치 가져오기 함수
# =============================
def get_hourly_weight(holiday: int, mode: str, hour: int) -> float:
    """시간별 가중치 반환"""
    if holiday == 0 and mode == "승차":
        return hourly_weights_승차_평일.get(hour, 1.0)
    elif holiday == 0 and mode == "하차":
        return hourly_weights_하차_평일.get(hour, 1.0)
    elif holiday == 1 and mode == "승차":
        return hourly_weights_승차_공휴일.get(hour, 1.0)
    else:  # 공휴일 + 하차
        return hourly_weights_하차_공휴일.get(hour, 1.0)

# =============================
# 6. API 엔드포인트
# =============================
@router.post("/")
def predict(req: PredictionRequest):
    # -------------------------
    # (1) 버스 예측 입력 생성
    # -------------------------
    bus_features = pd.DataFrame([{
        "불쾌지수": req.discomfort,
        "피크타임": req.peak,
        "월_num": req.month,
        "요일_num": req.weekday
    }])

    # -------------------------
    # (2) 버스 시간대별 예측 (기본값)
    # -------------------------
    if req.holiday == 0 and req.mode == "승차":
        hourly_bus_pred_base = bus_model_weekday_승차.predict(bus_features)[0]
    elif req.holiday == 0 and req.mode == "하차":
        hourly_bus_pred_base = bus_model_weekday_하차.predict(bus_features)[0]
    elif req.holiday == 1 and req.mode == "승차":
        hourly_bus_pred_base = bus_model_holiday_승차.predict(bus_features)[0]
    else:  # 공휴일 + 하차
        hourly_bus_pred_base = bus_model_holiday_하차.predict(bus_features)[0]
    
    # -------------------------
    # (3) 시간별 가중치 적용
    # -------------------------
    hourly_weight = get_hourly_weight(req.holiday, req.mode, req.hour)
    hourly_bus_pred = hourly_bus_pred_base * hourly_weight
    
    # -------------------------
    # (4) 버스 일별 총합 (가중치 계산용)
    # -------------------------
    daily_bus_total = calculate_daily_total(req, req.mode)
    
    # 가중치 계산 (음수/0 방지)
    if daily_bus_total > 0 and hourly_bus_pred > 0:
        time_weight = hourly_bus_pred / daily_bus_total
    else:
        time_weight = 1/24  # 기본 가중치 (1/24시간)

    # -------------------------
    # (5) 주차장 일별 예측
    # -------------------------
    if req.holiday == 0 and req.mode == "승차":
        daily_parking1 = parking_model_weekday_승차_반포1.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]
        daily_parking23 = parking_model_weekday_승차_반포23.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]

    elif req.holiday == 0 and req.mode == "하차":
        daily_parking1 = parking_model_weekday_하차_반포1.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]
        daily_parking23 = parking_model_weekday_하차_반포23.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]

    elif req.holiday == 1 and req.mode == "승차":
        daily_parking1 = parking_model_holiday_승차_반포1.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]
        daily_parking23 = parking_model_holiday_승차_반포23.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]

    else:  # 공휴일 + 하차
        daily_parking1 = parking_model_holiday_하차_반포1.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]
        daily_parking23 = parking_model_holiday_하차_반포23.predict(
            pd.DataFrame([{
                "총합": hourly_bus_pred,              
                "일평균_불쾌지수": req.discomfort,  
                "요일_num": req.weekday,           
                "월": req.month,
            }])
        )[0]

    # -------------------------
    # (6) 시간대별 주차장 예측값 계산
    # -------------------------
    hourly_parking1 = daily_parking1 * time_weight
    hourly_parking23 = daily_parking23 * time_weight

    # -------------------------
    # (7) 응답 반환
    # -------------------------
    return {
        "hourly_bus_prediction_base": float(hourly_bus_pred_base),  # 가중치 적용 전
        "hourly_weight": float(hourly_weight),  # 적용된 가중치
        "hourly_bus_prediction": float(hourly_bus_pred),  # 가중치 적용 후
        "daily_bus_total": float(daily_bus_total),
        "time_weight": float(time_weight),
        "daily_parking_panpo1": float(daily_parking1),
        "daily_parking_panpo23": float(daily_parking23),
        "hourly_parking_panpo1": float(max(0, hourly_parking1)),  # 음수 방지
        "hourly_parking_panpo23": float(max(0, hourly_parking23)),  # 음수 방지
        "hour": req.hour
    }