# routes/busking.py

from fastapi import APIRouter, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import base64
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db = client.lecture
collection_busking = db.busking

# Pydantic 모델
class busking(BaseModel):
    userid : str
    name : str
    date : datetime
    category : str
    content : str
    bandName : str
    state : int
    # image: Optional[str] = None  # base64 문자열

class buskingUpdate(BaseModel):
    userid : Optional[str] = None
    name : Optional[str] = None
    date : Optional[datetime] = None
    category : Optional[str] = None
    content : Optional[str] = None
    bandName : Optional[str] = None
    state : Optional[int] = None

# class buskingUpdateAll(buskingUpdate):
#     image: Optional[str] = None  # base64 문자열

# ───────────────────────────
# 유틸: Mongo 문서 포맷 보정
# ───────────────────────────
def normalize_busking(doc: dict) -> dict:
    """userid를 str로, image(bytes)를 base64로 바꿔서 반환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

# ───────────────────────────
# API
# ───────────────────────────

@router.get('/busking/select')
async def select():
    cursor = collection_busking.find().sort("date", 1)
    busking = await cursor.to_list(None)
    results = [normalize_busking(s) for s in busking]
    return {"results": results}

@router.post('/busking/insert')
async def insert(busking: busking):
    data = busking.dict()
    # image(base64) → bytes
    if data.get('image'):
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    await collection_busking.insert_one(data)
    return {'result': 'OK'}

@router.put('/busking/update/{userid}')
async def update(userid: str, busking: buskingUpdate):
    # 부분 업데이트 (image 제외)
    data = busking.dict(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')

    result = await collection_busking.update_one({'userid': userid}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='busking Not Found')
    return {'result': 'OK'}

@router.delete('/busking/delete/{busking_id}')
async def delete(busking_id: str):
    result = await collection_busking.delete_one({'userid': busking_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='busking Not Found')
    return {'result': 'OK'}
