# routes/postlike.py

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
postlike_collection = db1.postlike

# Pydantic Model
class PostLike(BaseModel):
    id: str
    postId: str
    userId: str                     
    createdAt: str
    updatedAt: Optional[str] = None

class PostLikeUpdate(BaseModel):
    id: Optional[str] = None
    postId: Optional[str] = None
    userId: Optional[str] = None
    createdAt: Optional[str] = None

class PostLikeDelete(BaseModel):
    postId: str
    userId: str

@router.get('/postlike/select')
async def select_postlikes():
    docs = await postlike_collection.find().to_list(None)
    
    for doc in docs:
        # ✅ ObjectId를 문자열로 변환
        doc['id'] = str(doc['_id'])          # _id → id로 변환
        doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
        doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
        doc.pop('_id', None)                 # 원본 _id 제거
        
    return {'results': docs}

@router.get('/postlike/select/{id}')
async def select_postlike_one(id: str):
    doc = await postlike_collection.find_one({'_id': ObjectId(id)})
    if not doc:
        raise HTTPException(404, 'PostLike Not Found')
    
    doc['id'] = str(doc['_id'])          # _id → id로 변환
    doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
    doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
    doc.pop('_id', None)                 # 원본 _id 제거
    
    return {'result': doc}

@router.post('/postlike/insert')
async def insert_postlike(item: PostLike):
    new_object_id = ObjectId()
    data = item.model_dump()

    data['createdAt'] = datetime.now(timezone.utc).isoformat()
    data['_id'] = new_object_id
    data.pop('id', None)

    await postlike_collection.insert_one(data)
    return {'result': 'OK'}

@router.put('/postlike/update/{id}')
async def update_postlike(id: str, patch: PostLikeUpdate):
    data = patch.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(400, 'No Field For Update')
    
    data.pop('id', None)
    
    res = await postlike_collection.update_one({'_id': ObjectId(id)}, {'$set': data})
    if res.matched_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}

@router.delete('/postlike/delete/{id}')
async def delete_postlike(id: str):
    res = await postlike_collection.delete_one({'_id': ObjectId(id)})
    if res.deleted_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}

@router.post('/postlike/delete')
async def delete_postlike_by_user(data: PostLikeDelete):
    res = await postlike_collection.delete_one({
        'postId': data.postId,
        'userId': data.userId
    })
    if res.deleted_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}