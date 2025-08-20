from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import base64
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

# ───────────────────────────
# ─────────────────────────── 
# FastAPI & Mongo 연결
# ───────────────────────────
# ─────────────────────────── 
app = FastAPI()

# CORS 설정 추가 (Flutter, iOS 등에서 접근 가능)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 운영 시에는 구체적인 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Atlas 사용 시 .env 또는 환경변수로 관리 권장
# 예) MONGODB_URI="mongodb+srv://<user>:<pass>@cluster.xxx.mongodb.net/?retryWrites=true&w=majority"
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)

# DB/Collection 이름은 기존 코드와 맞춤
db = client.lecture
collection_student = db.student
collection_user = db.User
collection_admin = db.Admin
collection_marker = db.Marker

# ───────────────────────────
# Pydantic 모델
# ───────────────────────────
class Student(BaseModel):
    code: str
    name: str
    dept: str
    phone: str
    # image: Optional[str] = None  # base64 문자열

class User(BaseModel):
    id: str
    pw: str
    phone: str
    date: str

class Admin(BaseModel):
    id: str
    pw: str
    date : str

class Marker(BaseModel):
    name : str
    type : str
    lat : float
    long : float
    address : str
    time : str
    method : str
    price : str
    phone : str

class StudentUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    dept: Optional[str] = None
    phone: Optional[str] = None

class StudentUpdateAll(StudentUpdate):
    image: Optional[str] = None  # base64 문자열

# ───────────────────────────
collection = db.Inquiry
user_collection = db.User  # User 컬렉션 추가

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
# Pydantic 모델 - User (기존 MongoDB 구조에 맞춤)
# ─────────────────────────── 
class User(BaseModel):
    id: str        # 기존 DB의 id 필드
    pw: str        # 기존 DB의 pw 필드  
    phone: Optional[str] = None
    date: Optional[str] = None

class UserCreate(BaseModel):
    id: str
    pw: str
    phone: Optional[str] = None

class UserLogin(BaseModel):
    id: str
    pw: str

# ─────────────────────────── 
# 유틸: Mongo 문서 포맷 보정
# ───────────────────────────
def normalize_student(doc: dict) -> dict:
    """_id를 str로, image(bytes)를 base64로 바꿔서 반환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    if 'image' in doc and doc['image']:
        if isinstance(doc['image'], (bytes, bytearray)):
            doc['image'] = base64.b64encode(doc['image']).decode('utf-8')
    return doc

def normalize_marker(doc: dict) -> dict:
    """_id를 str로, image(bytes)를 base64로 바꿔서 반환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

# ───────────────────────────
# Student API
# ───────────────────────────
# ─────────────────────────── 
def normalize_inquiry(doc: dict) -> dict:
    """_id를 str로 변환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

def normalize_user(doc: dict) -> dict:
    """User 문서 정규화"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

# ─────────────────────────── 
# Inquiry API (기존)
# ─────────────────────────── 

@app.get('/select')
async def select():
    students = await collection_student.find().to_list(None)
    results = [normalize_student(s) for s in students]
    inquirys = await collection.find().to_list(None)
    results = [normalize_inquiry(s) for s in inquirys]
    return {'results': results}

@app.get('/select/{code}')
async def select_one(code: str):
    student = await collection_student.find_one({'code': code})
    if not student:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': normalize_student(student)}
@app.get('/select/{userID}')
async def select_one(userID: str):
    inquiry = await collection.find_one({'userID': userID})
    if not inquiry:
        raise HTTPException(status_code=404, detail='Inquiry Not Found')
    return {'result': normalize_inquiry(inquiry)}

@app.post('/insert')
async def insert(student: Student):
    # code 중복 검사
    existing = await collection_student.find_one({'code': student.code})
async def insert(inquiry: Inquiry):
    # userID + title 중복 검사 (같은 사용자가 같은 제목으로 문의하는 것 방지)
    existing = await collection.find_one({
        'userID': inquiry.userID, 
        'title': inquiry.title
    })
    if existing:
        raise HTTPException(status_code=400, detail='Student is existed.')

    data = student.model_dump()
    # image(base64) → bytes
    if data.get('image'):
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    await collection_student.insert_one(data)
        raise HTTPException(status_code=400, detail='Same inquiry already exists.')
     
    data = inquiry.model_dump()
    await collection.insert_one(data)
    return {'result': 'OK'}

@app.put('/update/{code}')
async def update(code: str, student: StudentUpdate):
    # 부분 업데이트 (image 제외)
    data = student.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')

    result = await collection_student.update_one({'code': code}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': 'OK'}

@app.put('/updateAll/{code}')
async def update_all(code: str, student: StudentUpdateAll):
    # 전체 필드 업데이트 (image 포함)
    data = student.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')

    if 'image' in data and data['image']:
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    result = await collection_student.update_one({'code': code}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': 'OK'}

@app.delete('/delete/{code}')
async def delete(code: str):
    result = await collection_student.delete_one({'code': code})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='Student Not Found')
@app.put('/update/{userID}')
async def update(userID: str, inquiry: InquiryUpdate):
    # 부분 업데이트 (관리자 답변 등)
    data = inquiry.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')
     
    result = await collection.update_one({'userID': userID}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='Inquiry Not Found')
    return {'result': 'OK'}

# ───────────────────────────
# User/Admin/Marker API
# ───────────────────────────

@app.post('/user/insert')
async def insert_user(user: User):
    # code 중복 검사
    existing = await collection_user.find_one({'id': user.id})
    if existing:
        raise HTTPException(status_code=400, detail='user is existed.')

    data = user.model_dump()
    await collection_user.insert_one(data)
    return {'result': 'OK'}

@app.post('/admin/insert')
async def insert_admin(admin: Admin):
    # code 중복 검사
    existing = await collection_admin.find_one({'id': admin.id})
    if existing:
        raise HTTPException(status_code=400, detail='admin is existed.')

    data = admin.model_dump()
    await collection_admin.insert_one(data)
    return {'result': 'OK'}

@app.post('/marker/insert')
async def insert_marker(marker: Marker):
    data = marker.model_dump()
    await collection_marker.insert_one(data)
    return {'result': 'OK'}

@app.get("/marker/select")
async def get_markers():
    projection = {"_id": 0}
    markers = await collection_marker.find({}, projection).to_list(None)
    
    # 디버깅: 실제 데이터 구조 확인
    if markers:
        print(f"첫 번째 마커 데이터: {markers[0]}")
    
    # 필드명 수정해서 응답
    for marker in markers:
        # MongoDB에 실제로 어떤 필드가 있는지 확인 필요
        # 만약 lat, long 둘 다 있다면:
        if 'lat' in marker and 'long' in marker:
            # 그대로 유지하고 lng만 추가
            marker['lng'] = marker['long']
        # 만약 long만 있고 실제로는 위도라면:
        elif 'long' in marker:
            marker['lat'] = marker['long']  # 위도
            # 경도는 어디에 저장되어 있나요? 다른 필드명으로?
            # marker['lng'] = marker['longitude'] # 실제 경도 필드명으로 변경
    
    return markers

# ───────────────────────────
# Weather API (새로 추가)
# ───────────────────────────

@app.get("/weather")
async def get_weather():
    """
    다음 날씨 사이트에서 날씨 정보를 크롤링하여 반환합니다.
    """
    try:
        chrome_options = webdriver.ChromeOptions()
        chrome_options.add_argument("--headless")  # 창 안 띄우기
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        
        driver = webdriver.Chrome(
            service=Service(ChromeDriverManager().install()),
            options=chrome_options
        )
        
        driver.get("https://weather.daum.net/?location-regionId=AI10000901&weather-cp=kweather")
        time.sleep(2)  # 페이지 로딩 대기
        
        weathers = []
        
        try:
            xpath = '//*[@id="fc7ac7d4-ea2b-4850-bfd1-4f1ba87a03af"]/div/div/div[2]/div'
            elem = driver.find_element(By.XPATH, xpath)
            text = elem.text.strip()
            weathers.append({"title": text})
        except Exception as e:
            # XPath가 변경되었을 경우를 대비한 대안
            try:
                # 클래스나 다른 selector로 시도
                elem = driver.find_element(By.CSS_SELECTOR, "[data-testid='weather-summary']")
                text = elem.text.strip()
                weathers.append({"title": text})
            except:
                weathers.append({"title": "날씨 정보를 가져올 수 없습니다."})
                print(f"Weather scraping error: {e}")
        
        driver.quit()
        return {"results": weathers}
        
    except Exception as e:
        print(f"Weather API error: {e}")
        raise HTTPException(status_code=500, detail=f"날씨 정보를 가져오는데 실패했습니다: {str(e)}")

# ───────────────────────────
# ─────────────────────────── 
# User API (새로 추가)
# ─────────────────────────── 

@app.post('/api/user/signup')
async def signup(user: UserCreate):
    """회원가입 API"""
    try:
        # 중복 아이디 확인
        existing_user = await user_collection.find_one({'id': user.id})
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
        result = await user_collection.insert_one(user_data)
        
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

@app.post('/api/user/login')
async def login(user_login: UserLogin):
    """로그인 API"""
    try:
        # 사용자 조회
        user = await user_collection.find_one({'id': user_login.id})
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
    
@app.get('/select/user/{userID}')
async def select_user_inquiries(userID: str):
    """특정 사용자의 모든 문의 조회"""
    inquiries = await collection.find({'userID': userID}).to_list(None)
    if not inquiries:
        raise HTTPException(status_code=404, detail='No inquiries found for this user')
    results = [normalize_inquiry(doc) for doc in inquiries]
    return {'results': results}


@app.get('/api/user/{userID}')
async def get_user(userID: str):
    """사용자 정보 조회 API"""
    try:
        user = await user_collection.find_one({'id': userID})
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

# ─────────────────────────── 
# 헬스체크 및 CORS 설정
# ─────────────────────────── 

@app.get('/health')
async def health_check():
    """서버 상태 확인"""
    try:
        # MongoDB 연결 테스트
        await client.admin.command('ping')
        return {
            'status': 'healthy', 
            'database': 'connected',
            'collections': ['Inquiry', 'User']
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {str(e)}")

# CORS 설정 (iOS 앱 연동용)
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 특정 도메인만 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────── 
# 개발용 엔드포인트
# ─────────────────────────── 

@app.get('/api/debug/users')
async def debug_users():
    """개발용: 모든 사용자 조회"""
    try:
        users = await user_collection.find().to_list(None)
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

@app.get('/api/debug/inquiries')
async def debug_inquiries():
    """개발용: 모든 문의 조회"""
    try:
        inquiries = await collection.find().to_list(None)
        results = [normalize_inquiry(doc) for doc in inquiries]
        return {'inquiries': results, 'count': len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ─────────────────────────── 
# 실행
# ───────────────────────────
# ─────────────────────────── 
if __name__ == '__main__':
    import uvicorn
    print("🚀 FastAPI 서버 시작")
    print("📋 사용 가능한 엔드포인트:")
    print("   - Inquiry API: /select, /insert, /update")
    print("   - User API: /api/user/signup, /api/user/login")
    print("   - Debug: /api/debug/users, /api/debug/inquiries")
    print("   - Health: /health")
    
    # iOS 시뮬레이터에서 호출하려면 host=127.0.0.1 또는 0.0.0.0(포트포워딩/외부접속)
    uvicorn.run(app, host='127.0.0.1', port=8000)

# Swift에서 날씨 API 호출 예제
# func fetchWeather() async throws -> [WeatherInfo] {
#     let url = APIConfig.shared.baseURL.appendingPathComponent("weather")
#     let (data, response) = try await URLSession.shared.data(from: url)
#     
#     guard (response as? HTTPURLResponse)?.statusCode == 200 else {
#         throw URLError(.badServerResponse)
#     }
#     
#     struct WeatherResponse: Codable { 
#         let results: [WeatherInfo] 
#     }
#     struct WeatherInfo: Codable { 
#         let title: String 
#     }
#     
#     let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
#     return decoded.results
# }    uvicorn.run(app, host='127.0.0.1', port=8000)