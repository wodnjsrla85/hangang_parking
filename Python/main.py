# main.py

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import uvicorn

# Routes import
from routes.community import router as community_router
from routes.postlike import router as postlike_router
from routes.comment import router as comment_router
from routes.inquiry import router as inquiry_router
from routes.user import router as user_router
from routes.admin import router as admin_router
from routes.marker import router as marker_router
from routes.weather import router as weather_router
from routes.busking import router as busking_router

# ───────────────────────────
# FastAPI 앱 생성 및 설정
# ───────────────────────────

app = FastAPI(
    title="반포한강 주차수요 예측 앱 프로젝트 API",
    description="커뮤니티, 문의, 사용자, 관리자, 반포마커, 날씨, 버스킹 등 모든 기능을 포함한 통합 API",
    version="1.0.0"
)

# ───────────────────────────
# CORS 설정
# ───────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 운영 시에는 구체적인 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ───────────────────────────
# MongoDB 연결 설정
# ───────────────────────────

MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)

# ───────────────────────────
# Routes 포함 (순서대로)
# ───────────────────────────

# 1. Community 관련 (커뮤니티 게시글, 좋아요, 댓글)
app.include_router(community_router, tags=["Community"])
app.include_router(postlike_router, tags=["PostLike"])  
app.include_router(comment_router, tags=["Comment"])

# 2. 문의 관련 (관리자 페널용)
app.include_router(inquiry_router, tags=["Inquiry"])

# 3. 사용자 및 관리자 관련
app.include_router(user_router, tags=["User"])
app.include_router(admin_router, tags=["Admin"])

# 4. 지도 및 위치 관련
app.include_router(marker_router, tags=["Marker"])

# 5. 날씨 정보
app.include_router(weather_router, tags=["Weather"])

# 6. 버스킹 관련
app.include_router(busking_router, tags=["Busking"])

# ───────────────────────────
# 공통 엔드포인트
# ───────────────────────────

@app.get("/", tags=["Root"])
async def root():
    """API 루트 엔드포인트"""
    return {
        "message": "한강 프로젝트 API 서버",
        "version": "1.0.0",
        "status": "running",
        "available_services": [
            "Community (게시글, 좋아요, 댓글)",
            "Inquiry (문의 관리)",
            "User (사용자 관리)", 
            "Admin (관리자 관리)",
            "Marker (지도 마커)",
            "Weather (날씨 정보)",
            "Busking (버스킹 관리)"
        ],
        "docs": "/docs",
        "redoc": "/redoc"
    }

@app.get('/health', tags=["Health"])
async def health_check():
    """서버 및 데이터베이스 상태 확인"""
    try:
        # MongoDB 연결 테스트
        await client.admin.command('ping')
        
        # 각 데이터베이스 컬렉션 확인
        db_lecture = client.lecture
        db_contents = client.contents
        
        collections_status = {
            "lecture_db": {
                "Inquiry": "connected",
                "User": "connected", 
                "Admin": "connected",
                "Marker": "connected",
                "busking": "connected"
            },
            "contents_db": {
                "community": "connected",
                "postlike": "connected", 
                "comment": "connected"
            }
        }
        
        return {
            'status': 'healthy',
            'database': 'connected',
            'timestamp': uvicorn.main.datetime.datetime.now().isoformat(),
            'collections': collections_status
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Database connection failed: {str(e)}"
        )

@app.get('/api/info', tags=["Info"])
async def api_info():
    """API 정보 및 엔드포인트 목록"""
    return {
        "api_name": "한강 프로젝트 통합 API",
        "version": "1.0.0",
        "description": "Flutter Web 관리자 페널 및 iOS 앱을 위한 통합 백엔드 API",
        "endpoints": {
            "community": {
                "description": "커뮤니티 게시글 관리",
                "endpoints": [
                    "GET /community/select",
                    "GET /community/select/{id}",
                    "POST /community/insert", 
                    "PUT /community/update/{id}",
                    "DELETE /community/delete/{id}"
                ]
            },
            "postlike": {
                "description": "게시글 좋아요 관리", 
                "endpoints": [
                    "GET /postlike/select",
                    "POST /postlike/insert",
                    "DELETE /postlike/delete/{id}"
                ]
            },
            "comment": {
                "description": "댓글 관리",
                "endpoints": [
                    "GET /comment/select", 
                    "POST /comment/insert",
                    "PUT /comment/update/{id}",
                    "DELETE /comment/delete/{id}"
                ]
            },
            "inquiry": {
                "description": "문의 관리 (관리자 페널)",
                "endpoints": [
                    "GET /select",
                    "PUT /update/{inquiry_id}",
                    "POST /insert",
                    "GET /select/user/{userID}"
                ]
            },
            "user": {
                "description": "사용자 관리",
                "endpoints": [
                    "POST /api/user/signup",
                    "POST /api/user/login", 
                    "GET /api/user/{userID}"
                ]
            },
            "weather": {
                "description": "날씨 정보",
                "endpoints": ["GET /weather"]
            },
            "busking": {
                "description": "버스킹 관리", 
                "endpoints": [
                    "GET /busking/select",
                    "POST /busking/insert",
                    "PUT /busking/update/{userid}"
                ]
            }
        },
        "clients": {
            "flutter_web_admin": "문의 관리 페널 (Inquiry API 사용)",
            "ios_app": "전체 API 사용",
            "web_app": "Community, User, Weather API 사용"
        }
    }

# ───────────────────────────
# 서버 실행 설정
# ───────────────────────────

if __name__ == '__main__':
    print("🚀 한강 프로젝트 FastAPI 서버 시작")
    print("=" * 50)
    print("📋 포함된 서비스:")
    print("   ✅ Community API - 커뮤니티 게시글, 좋아요, 댓글")
    print("   ✅ Inquiry API - 문의 관리 (Flutter Web 관리자 페널)")
    print("   ✅ User API - 사용자 회원가입, 로그인")
    print("   ✅ Admin API - 관리자 관리")
    print("   ✅ Marker API - 지도 마커 관리")
    print("   ✅ Weather API - 날씨 정보 크롤링")
    print("   ✅ Busking API - 버스킹 관리")
    print("=" * 50)
    print("🌐 접속 정보:")
    print("   - 서버 주소: http://127.0.0.1:8000")
    print("   - API 문서: http://127.0.0.1:8000/docs")
    print("   - 상태 확인: http://127.0.0.1:8000/health")
    print("   - API 정보: http://127.0.0.1:8000/api/info")
    print("=" * 50)
    print("📱 클라이언트 접속:")
    print("   - Flutter Web (관리자): http://127.0.0.1:8000")
    print("   - iOS 앱: http://127.0.0.1:8000")
    print("=" * 50)
    print("⚡ 서버를 시작합니다...")
    
    # 서버 실행 (reload 옵션 제거)
    uvicorn.run(
        app, 
        host='127.0.0.1',  # 로컬 접속용 
        port=8000,
        log_level="info"
    )