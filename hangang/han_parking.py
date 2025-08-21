from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
from datetime import datetime, timezone
import base64
import os


# ───────────────────────────
# FastAPI & Mongo 연결
# ───────────────────────────
app = FastAPI()


MONGO_URI = "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/"
client = AsyncIOMotorClient(MONGO_URI)
db = client.contents                  # DB 이름: contents
community_collection = db.community  # 게시글
postlike_collection = db.postlike     # 좋아요
comment_collection = db.comment       # 댓글


# ───────────────────────────
# Pydantic 모델 (기존 그대로)
# ───────────────────────────
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


#  추가: PostLike 삭제용 모델
class PostLikeDelete(BaseModel):
    postId: str
    userId: str


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


# ───────────────────────────
# Community API
# ───────────────────────────
@app.get('/')
async def root():
    return {'message': 'Community API Server is running'}


@app.get('/select')
async def select():
    docs = await community_collection.find({'deleted': False}).to_list(None)   
    
    for doc in docs:
        
        doc['id'] = str(doc['_id'])        # _id → id로 변환
        doc['userId'] = str(doc['userId']) # userId도 문자열로 변환
        doc.pop('_id', None)               # 원본 _id 제거
        
    return {'results': docs}


@app.get('/select/{id}')
async def select_one(id: str):
    doc = await community_collection.find_one({'_id': ObjectId(id), 'deleted': False}) 
    if not doc:
        raise HTTPException(404, 'Content Not Found')
    
    
    doc['id'] = str(doc['_id'])        # _id → id로 변환
    doc['userId'] = str(doc['userId']) # userId도 문자열로 변환
    doc.pop('_id', None)               # 원본 _id 제거
    
    return {'result': doc}


@app.post('/insert')
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


@app.put('/update/{id}')
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


@app.delete('/delete/{id}')
async def delete(id: str):
    """논리 삭제: deleted 플래그만 변경"""                
    now = datetime.now(timezone.utc).isoformat()         
    res = await community_collection.update_one(         
        {'_id': ObjectId(id), 'deleted': False},         
        {'$set': {'deleted': True, 'deletedAt': now}})   
    if res.matched_count == 0:                           
        raise HTTPException(404, 'Content Not Found')    
    return {'result': 'OK'}


# ───────────────────────────
# PostLike API
# ───────────────────────────
@app.get('/postlike/select')
async def select_postlikes():
    docs = await postlike_collection.find().to_list(None)
    
    for doc in docs:
        # ✅ ObjectId를 문자열로 변환
        doc['id'] = str(doc['_id'])          # _id → id로 변환
        doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
        doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
        doc.pop('_id', None)                 # 원본 _id 제거
        
    return {'results': docs}


@app.get('/postlike/select/{id}')
async def select_postlike_one(id: str):
    doc = await postlike_collection.find_one({'_id': ObjectId(id)})
    if not doc:
        raise HTTPException(404, 'PostLike Not Found')
    
    
    doc['id'] = str(doc['_id'])          # _id → id로 변환
    doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
    doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
    doc.pop('_id', None)                 # 원본 _id 제거
    
    return {'result': doc}


@app.post('/postlike/insert')
async def insert_postlike(item: PostLike):
    new_object_id = ObjectId()
    data = item.model_dump()


    data['createdAt'] = datetime.now(timezone.utc).isoformat()
    data['_id'] = new_object_id
    data.pop('id', None)


    await postlike_collection.insert_one(data)
    return {'result': 'OK'}


@app.put('/postlike/update/{id}')
async def update_postlike(id: str, patch: PostLikeUpdate):
    data = patch.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(400, 'No Field For Update')
    
    data.pop('id', None)
    
    res = await postlike_collection.update_one({'_id': ObjectId(id)}, {'$set': data})
    if res.matched_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}


@app.delete('/postlike/delete/{id}')
async def delete_postlike(id: str):
    res = await postlike_collection.delete_one({'_id': ObjectId(id)})
    if res.deleted_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}


# 추가: Swift 호환용 삭제 API
@app.post('/postlike/delete')
async def delete_postlike_by_user(data: PostLikeDelete):
    res = await postlike_collection.delete_one({
        'postId': data.postId,
        'userId': data.userId
    })
    if res.deleted_count == 0:
        raise HTTPException(404, 'PostLike Not Found')
    return {'result': 'OK'}


# ───────────────────────────
# Comment API
# ───────────────────────────
@app.get('/comment/select')
async def select_comments():
    docs = await comment_collection.find({'deleted': False}).to_list(None)      
    
    for doc in docs:
        #  ObjectId를 문자열로 변환 (댓글은 postId, userId 둘 다 있음)
        doc['id'] = str(doc['_id'])          # _id → id로 변환
        doc['postId'] = str(doc['postId'])   # postId도 문자열로 변환
        doc['userId'] = str(doc['userId'])   # userId도 문자열로 변환
        doc.pop('_id', None)                 # 원본 _id 제거
        
    return {'results': docs}


@app.get('/comment/select/{id}')
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


@app.post('/comment/insert')
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


@app.put('/comment/update/{id}')
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


@app.delete('/comment/delete/{id}')
async def delete_comment(id: str):
    now = datetime.now(timezone.utc).isoformat()                              
    res = await comment_collection.update_one(                                
        {'_id': ObjectId(id), 'deleted': False},                              
        {'$set': {'deleted': True, 'deletedAt': now}})                        
    if res.matched_count == 0:
        raise HTTPException(404, 'Comment Not Found')
    return {'result': 'OK'}


# ───────────────────────────
# 실행
# ───────────────────────────
if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='127.0.0.1', port=8000)
