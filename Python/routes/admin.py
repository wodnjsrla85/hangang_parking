# routes/admin.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from datetime import datetime
import os

# Router 생성
router = APIRouter()

# MongoDB 연결
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)
db = client.lecture
collection_admin = db.Admin

# Pydantic 모델
class Admin(BaseModel):
    id: str
    pw: str
    date: str

class AdminSignup(BaseModel):
    id: str
    pw: str

class AdminLogin(BaseModel):
    id: str
    pw: str

@router.post('/admin/insert')
async def insert_admin(admin: Admin):
    # code 중복 검사
    existing = await collection_admin.find_one({'id': admin.id})
    if existing:
        raise HTTPException(status_code=400, detail='admin is existed.')

    data = admin.model_dump()
    await collection_admin.insert_one(data)
    return {'result': 'OK'}

@router.post('/api/admin/signup')
async def admin_signup(admin: AdminSignup):
    """관리자 회원가입 API"""
    try:
        # 중복 아이디 확인
        existing_admin = await collection_admin.find_one({'id': admin.id})
        if existing_admin:
            raise HTTPException(status_code=400, detail='이미 존재하는 관리자 아이디입니다')
        
        # 유효성 검사
        if len(admin.id) < 3:
            raise HTTPException(status_code=400, detail='아이디는 3자 이상이어야 합니다')
        
        if len(admin.pw) < 4:
            raise HTTPException(status_code=400, detail='비밀번호는 4자 이상이어야 합니다')
        
        # 관리자 데이터 준비
        admin_data = {
            'id': admin.id,
            'pw': admin.pw,
            'date': datetime.utcnow().strftime('%Y-%m-%d')
        }
        
        # MongoDB에 저장
        result = await collection_admin.insert_one(admin_data)
        
        print(f"✅ 관리자 회원가입 성공: {admin.id}")
        
        return {
            'result': 'OK',
            'message': '관리자 회원가입이 완료되었습니다',
            'adminID': admin.id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 관리자 회원가입 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"관리자 회원가입 실패: {str(e)}")

@router.post('/api/admin/login')
async def admin_login(admin_login: AdminLogin):
    """관리자 로그인 API"""
    try:
        # 관리자 조회
        admin = await collection_admin.find_one({'id': admin_login.id})
        if not admin:
            raise HTTPException(status_code=401, detail='아이디 또는 비밀번호가 올바르지 않습니다')
        
        # 비밀번호 확인
        if admin['pw'] != admin_login.pw:
            raise HTTPException(status_code=401, detail='아이디 또는 비밀번호가 올바르지 않습니다')
        
        print(f"✅ 관리자 로그인 성공: {admin['id']}")
        
        return {
            'result': 'OK',
            'message': '관리자 로그인 성공',
            'admin': {
                'id': admin['id'],
                'date': admin.get('date', '')
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 관리자 로그인 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"관리자 로그인 실패: {str(e)}")

@router.post('/api/admin/logout')
async def admin_logout():
    """관리자 로그아웃 API"""
    try:
        print(f"✅ 관리자 로그아웃")
        
        return {
            'result': 'OK',
            'message': '로그아웃되었습니다'
        }
        
    except Exception as e:
        print(f"❌ 관리자 로그아웃 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"로그아웃 실패: {str(e)}")

@router.get('/api/admin/{adminID}')
async def get_admin(adminID: str):
    """관리자 정보 조회 API"""
    try:
        admin = await collection_admin.find_one({'id': adminID})
        if not admin:
            raise HTTPException(status_code=404, detail='관리자를 찾을 수 없습니다')
        
        return {
            'result': 'OK',
            'admin': {
                'id': admin['id'],
                'date': admin.get('date', '')
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ 관리자 조회 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"관리자 조회 실패: {str(e)}")

@router.get('/api/debug/admins')
async def debug_admins():
    """개발용: 모든 관리자 조회"""
    try:
        admins = await collection_admin.find().to_list(None)
        results = []
        for admin in admins:
            results.append({
                'id': admin.get('id'),
                'date': admin.get('date', ''),
                '_id': str(admin.get('_id'))
            })
        return {'admins': results, 'count': len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))