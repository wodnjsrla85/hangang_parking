# routes/user.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import os

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db = client.lecture
collection_user = db.User

# Pydantic 모델
class User(BaseModel):
    id: str
    pw: str
    phone: str
    date: str

class UserCreate(BaseModel):
    id: str
    pw: str
    phone: Optional[str] = None

class UserLogin(BaseModel):
    id: str
    pw: str

def normalize_user(doc: dict) -> dict:
    """User 문서 정규화"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

@router.get('/api/admin/dashboard')
async def get_dashboard():
    """관리자 대시보드: 유저 & 문의 통계"""
    try:
        # 총 유저 수
        total_users = await collection_user.count_documents({})

        # 오늘 가입자 수 (date: "YYYY-MM-DD" 문자열로 저장됨)
        today_str = datetime.utcnow().strftime('%Y-%m-%d')
        new_today = await collection_user.count_documents({'date': today_str})

        # 오늘 문의 수
        inquiries_today = 0
        collections = await db.list_collection_names()
        if "Inquiry" in collections:
            inquiries_today = await db.Inquiry.count_documents({'qdate': today_str})

        return {
            "result": "OK",
            "total_users": total_users,
            "new_today": new_today,
            "inquiries_today": inquiries_today
        }

    except Exception as e:
        print(f"❌ 관리자 대시보드 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"대시보드 조회 실패: {str(e)}")


@router.post('/user/insert')
async def insert_user(user: User):
    # code 중복 검사
    existing = await collection_user.find_one({'id': user.id})
    if existing:
        raise HTTPException(status_code=400, detail='user is existed.')

    data = user.model_dump()
    await collection_user.insert_one(data)
    return {'result': 'OK'}

@router.post('/api/user/signup')
async def signup(user: UserCreate):
    """회원가입 API"""
    try:
        # 중복 아이디 확인
        existing_user = await collection_user.find_one({'id': user.id})
        if existing_user:
            raise HTTPException(status_code=400, detail='이미 존재하는 아이디입니다')
        
        # 유효성 검사
        if len(user.id) < 3:
            raise HTTPException(status_code=400, detail='아이디는 3자 이상이어야 합니다')
        
        if len(user.pw) < 4:
            raise HTTPException(status_code=400, detail='비밀번호는 4자 이상이어야 합니다')
        
        # 사용자 데이터 준비 (기존 DB 구조에 맞춤)
        user_data = {
            'id': user.id,
            'pw': user.pw,  # 실제 운영에서는 해시화 권장
            'phone': user.phone or "",
            'date': datetime.utcnow().strftime('%Y-%m-%d')
        }
        
        # MongoDB에 저장
        result = await collection_user.insert_one(user_data)
        
        print(f"✅ 회원가입 성공: {user.id}")
        
        return {
            'result': 'OK',
            'message': '회원가입이 완료되었습니다',
            'userID': user.id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 회원가입 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"회원가입 실패: {str(e)}")

@router.post('/api/user/login')
async def login(user_login: UserLogin):
    """로그인 API"""
    try:
        # 사용자 조회
        user = await collection_user.find_one({'id': user_login.id})
        if not user:
            raise HTTPException(status_code=401, detail='아이디 또는 비밀번호가 올바르지 않습니다')
        
        # 비밀번호 확인
        if user['pw'] != user_login.pw:
            raise HTTPException(status_code=401, detail='아이디 또는 비밀번호가 올바르지 않습니다')
        
        print(f"✅ 로그인 성공: {user['id']}")
        
        return {
            'result': 'OK',
            'message': '로그인 성공',
            'user': {
                'id': user['id'],
                'phone': user.get('phone', ''),
                'date': user.get('date', '')
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 로그인 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"로그인 실패: {str(e)}")

@router.get('/api/user/{userID}')
async def get_user(userID: str):
    """사용자 정보 조회 API"""
    try:
        user = await collection_user.find_one({'id': userID})
        if not user:
            raise HTTPException(status_code=404, detail='사용자를 찾을 수 없습니다')
        
        return {
            'result': 'OK',
            'user': {
                'id': user['id'],
                'phone': user.get('phone', ''),
                'date': user.get('date', '')
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 사용자 조회 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"사용자 조회 실패: {str(e)}")

@router.get('/api/debug/users')
async def debug_users():
    """개발용: 모든 사용자 조회"""
    try:
        users = await collection_user.find().to_list(None)
        results = []
        for user in users:
            results.append({
                'id': user.get('id'),
                'phone': user.get('phone', ''),
                'date': user.get('date', ''),
                '_id': str(user.get('_id'))
            })
        return {'users': results, 'count': len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))