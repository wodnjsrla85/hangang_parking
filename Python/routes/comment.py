# routes/comment.py

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
comment_collection = db1.comment

# Pydantic Model
class Comment(BaseModel):
    id: str
    postId: str
    userId: str                      
    content: str
    createdAt: str
    updatedAt: str
    deleted: bool                    
    deletedAt: Optional[str] = None  

class CommentUpdate(BaseModel):
    id: Optional[str] = None
    postId: Optional[str] = None
    userId: Optional[str] = None     
    content: Optional[str] = None
    createdAt: Optional[str] = None
    updatedAt: Optional[str] = None
    deleted: Optional[bool] = None   
    deletedAt: Optional[str] = None  

@router.get('/comment/select')
async def select_comments():
    docs = await comment_collection.find({'deleted': False}).to_list(None)      
    
    for doc in docs:
        #  ObjectId를 문자열로 변환 (댓글은 postId, userId 둘 다 있음)
        doc['id'] = str(doc['_id'])          # _id → id로 변환
        doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
        doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
        doc.pop('_id', None)                 # 원본 _id 제거
        
    return {'results': docs}

@router.get('/comment/select/{id}')
async def select_comment_one(id: str):
    doc = await comment_collection.find_one({'_id': ObjectId(id)})
    if not doc:
        raise HTTPException(404, 'Comment Not Found')
    
    #  ObjectId를 문자열로 변환
    doc['id'] = str(doc['_id'])          # _id → id로 변환
    doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
    doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
    doc.pop('_id', None)                 # 원본 _id 제거
    
    return {'result': doc}

@router.post('/comment/insert')
async def insert_comment(item: Comment):
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

    await comment_collection.insert_one(data)
    return {'result': 'OK'}

@router.put('/comment/update/{id}')
async def update_comment(id: str, patch: CommentUpdate):
    data = patch.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(400, 'No Field For Update')
    data['updatedAt'] = datetime.now(timezone.utc).isoformat()
    data.pop('id', None)

    res = await comment_collection.update_one({'_id': ObjectId(id)}, {'$set': data})
    if res.matched_count == 0:
        raise HTTPException(404, 'Comment Not Found')
    return {'result': 'OK'}

@router.delete('/comment/delete/{id}')
async def delete_comment(id: str):
    now = datetime.now(timezone.utc).isoformat()                              
    res = await comment_collection.update_one(                                
        {'_id': ObjectId(id), 'deleted': False},                              
        {'$set': {'deleted': True, 'deletedAt': now}})                        
    if res.matched_count == 0:
        raise HTTPException(404, 'Comment Not Found')
    return {'result': 'OK'}