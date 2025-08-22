# routes/marker.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
import os

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db = client.lecture
collection_marker = db.Marker

# Pydantic 모델
class Marker(BaseModel):
    name : str
    type : str
    lat : float
    long : float
    address : str
    time : str
    method : str
    price : str
    phone : str

@router.post('/marker/insert')
async def insert_marker(marker: Marker):
    data = marker.model_dump()
    await collection_marker.insert_one(data)
    return {'result': 'OK'}

@router.get("/marker/select")
async def get_markers():
    projection = {"_id": 0}
    markers = await collection_marker.find({}, projection).to_list(None)
    
    # 디버깅: 실제 데이터 구조 확인
    if markers:
        print(f"첫 번째 마커 데이터: {markers[0]}")
    
    # 필드명 수정해서 응답
    for marker in markers:
        # MongoDB에 실제로 어떤 필드가 있는지 확인 필요
        # 만약 lat, long 둘 다 있다면:
        if 'lat' in marker and 'long' in marker:
            # 그대로 유지하고 lng만 추가
            marker['lng'] = marker['long']
        # 만약 long만 있고 실제로는 위도라면:
        elif 'long' in marker:
            marker['lat'] = marker['long']  # 위도
            # 경도는 어디에 저장되어 있나요? 다른 필드명으로?
            # marker['lng'] = marker['longitude'] # 실제 경도 필드명으로 변경
    
    return markers