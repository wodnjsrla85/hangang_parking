# routes/postlike.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone
from bson import ObjectId
import os
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db1 = client.contents
postlike_collection = db1.postlike

# Pydantic Models
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

# 📌 전체 좋아요 조회
@router.get('/postlike/select')
async def select_postlikes():
    try:
        docs = await postlike_collection.find().to_list(None)
        
        for doc in docs:
            # ObjectId를 문자열로 변환
            doc['id'] = str(doc['_id'])          
            doc['postId'] = str(doc['postId'])   
            doc['userId'] = str(doc['userId'])   
            doc.pop('_id', None)                 
            
        logger.info(f"조회된 좋아요 개수: {len(docs)}")
        return {'results': docs}
    except Exception as e:
        logger.error(f"좋아요 목록 조회 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 목록 조회 중 오류 발생")

# 📌 특정 좋아요 조회
@router.get('/postlike/select/{id}')
async def select_postlike_one(id: str):
    try:
        if not ObjectId.is_valid(id):
            raise HTTPException(status_code=400, detail="잘못된 ID 형식")
            
        doc = await postlike_collection.find_one({'_id': ObjectId(id)})
        if not doc:
            raise HTTPException(status_code=404, detail='좋아요를 찾을 수 없습니다')
        
        doc['id'] = str(doc['_id'])          
        doc['postId'] = str(doc['postId'])   
        doc['userId'] = str(doc['userId'])   
        doc.pop('_id', None)                 
        
        return {'result': doc}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"좋아요 상세 조회 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 조회 중 오류 발생")

# 📌 좋아요 등록 (개선: 중복 방지)
@router.post('/postlike/insert')
async def insert_postlike(item: PostLike):
    try:
        # 🔍 중복 좋아요 확인
        existing = await postlike_collection.find_one({
            'postId': item.postId,
            'userId': item.userId
        })
        
        if existing:
            logger.warning(f"중복 좋아요 시도: postId={item.postId}, userId={item.userId}")
            raise HTTPException(
                status_code=409, 
                detail="이미 좋아요를 누른 게시글입니다"
            )
        
        # 새 좋아요 등록
        new_object_id = ObjectId()
        data = item.model_dump()
        data['createdAt'] = datetime.now(timezone.utc).isoformat()
        data['_id'] = new_object_id
        data.pop('id', None)

        await postlike_collection.insert_one(data)
        logger.info(f"좋아요 등록 성공: postId={item.postId}, userId={item.userId}")
        return {'result': 'OK', 'message': '좋아요가 등록되었습니다'}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"좋아요 등록 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 등록 중 오류 발생")

# 📌 좋아요 수정
@router.put('/postlike/update/{id}')
async def update_postlike(id: str, patch: PostLikeUpdate):
    try:
        if not ObjectId.is_valid(id):
            raise HTTPException(status_code=400, detail="잘못된 ID 형식")
            
        data = patch.model_dump(exclude_unset=True)
        if not data:
            raise HTTPException(status_code=400, detail='수정할 데이터가 없습니다')
        
        data.pop('id', None)
        data['updatedAt'] = datetime.now(timezone.utc).isoformat()
        
        res = await postlike_collection.update_one(
            {'_id': ObjectId(id)}, 
            {'$set': data}
        )
        
        if res.matched_count == 0:
            raise HTTPException(status_code=404, detail='좋아요를 찾을 수 없습니다')
            
        logger.info(f"좋아요 수정 성공: id={id}")
        return {'result': 'OK', 'message': '좋아요가 수정되었습니다'}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"좋아요 수정 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 수정 중 오류 발생")

# 📌 좋아요 삭제 (ID 기준)
@router.delete('/postlike/delete/{id}')
async def delete_postlike(id: str):
    try:
        if not ObjectId.is_valid(id):
            raise HTTPException(status_code=400, detail="잘못된 ID 형식")
            
        res = await postlike_collection.delete_one({'_id': ObjectId(id)})
        
        if res.deleted_count == 0:
            raise HTTPException(status_code=404, detail='좋아요를 찾을 수 없습니다')
            
        logger.info(f"좋아요 삭제 성공: id={id}")
        return {'result': 'OK', 'message': '좋아요가 삭제되었습니다'}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"좋아요 삭제 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 삭제 중 오류 발생")

# 📌 좋아요 취소 (postId + userId 기준) - 개선: 더 나은 응답
@router.post('/postlike/delete')
async def delete_postlike_by_user(data: PostLikeDelete):
    try:
        # 🔍 삭제 대상 확인
        existing = await postlike_collection.find_one({
            'postId': data.postId,
            'userId': data.userId
        })
        
        if not existing:
            logger.warning(f"존재하지 않는 좋아요 삭제 시도: postId={data.postId}, userId={data.userId}")
            # ✅ 404 대신 204 반환 (이미 좋아요가 없는 상태이므로 성공으로 처리)
            return {'result': 'OK', 'message': '좋아요가 이미 취소된 상태입니다'}
        
        # 좋아요 삭제
        res = await postlike_collection.delete_one({
            'postId': data.postId,
            'userId': data.userId
        })
        
        if res.deleted_count > 0:
            logger.info(f"좋아요 취소 성공: postId={data.postId}, userId={data.userId}")
            return {'result': 'OK', 'message': '좋아요가 취소되었습니다'}
        else:
            # 이론적으로는 발생하지 않아야 함
            raise HTTPException(status_code=500, detail="좋아요 취소 처리 중 오류 발생")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"좋아요 취소 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 취소 중 오류 발생")

# 📌 특정 게시글의 좋아요 개수 조회 (추가 유틸리티)
@router.get('/postlike/count/{post_id}')
async def get_like_count(post_id: str):
    try:
        count = await postlike_collection.count_documents({'postId': post_id})
        return {'postId': post_id, 'likeCount': count}
    except Exception as e:
        logger.error(f"좋아요 개수 조회 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 개수 조회 중 오류 발생")

# 📌 사용자가 특정 게시글에 좋아요를 눌렀는지 확인 (추가 유틸리티)
@router.get('/postlike/check/{post_id}/{user_id}')
async def check_user_like(post_id: str, user_id: str):
    try:
        like = await postlike_collection.find_one({
            'postId': post_id,
            'userId': user_id
        })
        return {
            'postId': post_id,
            'userId': user_id,
            'isLiked': like is not None
        }
    except Exception as e:
        logger.error(f"좋아요 상태 확인 실패: {e}")
        raise HTTPException(status_code=500, detail="좋아요 상태 확인 중 오류 발생")
