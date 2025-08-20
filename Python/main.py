from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
import base64
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import time

# ───────────────────────────
# FastAPI & Mongo 연결
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

@app.get('/select')
async def select():
    students = await collection_student.find().to_list(None)
    results = [normalize_student(s) for s in students]
    return {'results': results}

@app.get('/select/{code}')
async def select_one(code: str):
    student = await collection_student.find_one({'code': code})
    if not student:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': normalize_student(student)}

@app.post('/insert')
async def insert(student: Student):
    # code 중복 검사
    existing = await collection_student.find_one({'code': student.code})
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
# 실행
# ───────────────────────────
if __name__ == '__main__':
    import uvicorn
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
# }