# routes/inquiry.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
import base64
import os

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db = client.lecture
collection = db.Inquiry

# ─────────────────────────── 
# Pydantic 모델 - Inquiry
# ─────────────────────────── 
class Inquiry(BaseModel):
    userID: str
    adminID: Optional[str] = None
    qdate: str
    adate: Optional[str] = None
    title: str
    content: str
    answerContent: Optional[str] = None
    state: str

class InquiryUpdate(BaseModel):
    adminID: Optional[str] = None
    adate: Optional[str] = None
    answerContent: Optional[str] = None
    state: Optional[str] = None

# ─────────────────────────── 
# 유틸 함수
# ─────────────────────────── 
def normalize_inquiry(doc: dict) -> dict:
    """_id를 str로 변환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    if 'image' in doc and doc['image']:
        if isinstance(doc['image'], (bytes, bytearray)):
            doc['image'] = base64.b64encode(doc['image']).decode('utf-8')
    return doc

# ─────────────────────────── 
# Inquiry API (기존)
# ─────────────────────────── 

@router.put("/update/{inquiry_id}")
async def update_inquiry(inquiry_id: str, inquiry: InquiryUpdate):
    if not ObjectId.is_valid(inquiry_id):
        raise HTTPException(status_code=400, detail="Invalid ObjectId")

    result = await collection.update_one(
        {"_id": ObjectId(inquiry_id)},
        {"$set": inquiry.dict(exclude_unset=True)}
    )

    # 🔑 수정된 경우 OR 기존 값과 동일한 경우 → 둘 다 성공 처리
    if result.modified_count == 1 or result.matched_count == 1:
        return {"result": "OK"}
    else:
        raise HTTPException(status_code=404, detail="Inquiry not found")

@router.get('/select')
async def select():
    inquirys = await collection.find().to_list(None)
    results = [normalize_inquiry(s) for s in inquirys]
    return {'results': results}

@router.post('/insert')
async def insert(inquiry: Inquiry):
    # userID + title 중복 검사 (같은 사용자가 같은 제목으로 문의하는 것 방지)
    existing = await collection.find_one({
        'userID': inquiry.userID, 
        'title': inquiry.title
    })
    if existing:raise HTTPException(status_code=400, detail='Same inquiry already exists.')
     
    data = inquiry.model_dump()
    await collection.insert_one(data)
    return {'result': 'OK'}

@router.get('/select/user/{userID}')
async def select_user_inquiries(userID: str):
    """특정 사용자의 모든 문의 조회"""
    inquiries = await collection.find({'userID': userID}).to_list(None)
    if not inquiries:
        raise HTTPException(status_code=404, detail='No inquiries found for this user')
    results = [normalize_inquiry(doc) for doc in inquiries]
    return {'results': results}

@router.get('/api/debug/inquiries')
async def debug_inquiries():
    """개발용: 모든 문의 조회"""
    try:
        inquiries = await collection.find().to_list(None)
        results = [normalize_inquiry(doc) for doc in inquiries]
        return {'inquiries': results, 'count': len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))