# routes/busking.py

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
collection_busking = db.busking

# Pydantic 모델
class busking(BaseModel):
    userid : str
    name : str
    date : str
    category : str
    content : str
    bandName : str
    state : int
    # image: Optional[str] = None  # base64 문자열

class buskingUpdate(BaseModel):
    userid : Optional[str] = None
    name : Optional[str] = None
    date : Optional[str] = None
    category : Optional[str] = None
    content : Optional[str] = None
    bandName : Optional[str] = None
    state : Optional[int] = None

# 유틸: Mongo 문서 포맷 보정
def normalize_busking(doc: dict) -> dict:
    if not doc:
        return doc
    doc["_id"] = str(doc.get("_id"))  # ✅ ObjectId -> str
    return doc

def to_object_id(id_str: str) -> ObjectId:
    try:
        return ObjectId(id_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid id format")



@router.get('/busking/select')
async def select():
    busking = await collection_busking.find().to_list(None)
    results = [normalize_busking(s) for s in busking]
    return {'results': results}

@router.post('/busking/insert')
async def insert(busking: busking):
    # userid 중복 검사
    # existing = await collection_busking.find_one({'userid': busking.userid})
    # if existing:
    #     raise HTTPException(status_code=400, detail='busking is existed.')

    data = busking.dict()
    # image(base64) → bytes
    if data.get('image'):
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    await collection_busking.insert_one(data)
    return {'result': 'OK'}

@router.put("/busking/update/{id}")
async def update(id: str, payload: buskingUpdate):
    data = payload.dict(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail="No Field For Update")

    oid = to_object_id(id)  # ✅ 문자열 → ObjectId
    result = await collection_busking.update_one({"_id": oid}, {"$set": data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="busking Not Found")
    return {"result": "OK"}

@router.delete("/busking/delete/{id}")
async def delete(id: str):
    oid = to_object_id(id)  # ✅ 문자열 → ObjectId
    result = await collection_busking.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="busking Not Found")
    return {"result": "OK"}