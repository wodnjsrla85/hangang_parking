# routes/community.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from bson import ObjectId
import os

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db1 = client.contents
community_collection = db1.community

# Pydantic Model
class Content(BaseModel):
    id: str
    userId: str                      
    content: str
    createdAt: str
    updatedAt: str
    deleted: bool                    
    deletedAt: Optional[str] = None  

class ContentUpdate(BaseModel):
    id: Optional[str] = None
    userId: Optional[str] = None     
    content: Optional[str] = None
    createdAt: Optional[str] = None
    updatedAt: Optional[str] = None
    deleted: Optional[bool] = None   
    deletedAt: Optional[str] = None  

@router.get('/community/select')
async def select():
    docs = await community_collection.find({'deleted': False}).to_list(None)   
    
    for doc in docs:
        doc['id'] = str(doc['_id'])        # _id → id로 변환
        doc['userId'] = str(doc['userId']) # userId도 문자열로 변환
        doc.pop('_id', None)               # 원본 _id 제거
        
    return {'results': docs}

@router.get('/community/select/{id}') 
async def select_one(id: str):
    doc = await community_collection.find_one({'_id': ObjectId(id), 'deleted': False}) 
    if not doc:
        raise HTTPException(404, 'Content Not Found')
    
    doc['id'] = str(doc['_id'])        # _id → id로 변환
    doc['userId'] = str(doc['userId']) # userId도 문자열로 변환
    doc.pop('_id', None)               # 원본 _id 제거
    
    return {'result': doc}

@router.post('/community/insert')
async def insert(item: Content):
    new_object_id = ObjectId()
    data = item.model_dump()

    now = datetime.now(timezone.utc).isoformat()
    data.update({
        'createdAt': now,
        'updatedAt': now,
        'deleted': False,            
        'deletedAt': None            
    })
    data['_id'] = new_object_id
    data.pop('id', None)

    await community_collection.insert_one(data)
    return {'result': 'OK'}

@router.put('/community/update/{id}')
async def update(id: str, patch: ContentUpdate):
    data = patch.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(400, 'No Field For Update')

    data['updatedAt'] = datetime.now(timezone.utc).isoformat()
    data.pop('id', None)

    res = await community_collection.update_one({'_id': ObjectId(id)}, {'$set': data})
    if res.matched_count == 0:
        raise HTTPException(404, 'Content Not Found')
    return {'result': 'OK'}

@router.delete('/community/delete/{id}')
async def delete(id: str):
    """논리 삭제: deleted 플래그만 변경"""                
    now = datetime.now(timezone.utc).isoformat()         
    res = await community_collection.update_one(         
        {'_id': ObjectId(id), 'deleted': False},         
        {'$set': {'deleted': True, 'deletedAt': now}})   
    if res.matched_count == 0:                           
        raise HTTPException(404, 'Content Not Found')    
    return {'result': 'OK'}