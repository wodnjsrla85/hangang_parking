from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import Optional
import base64
import os

# ───────────────────────────
# FastAPI & Mongo 연결
# ───────────────────────────
app = FastAPI()

# Atlas 사용 시 .env 또는 환경변수로 관리 권장
# 예) MONGODB_URI="mongodb+srv://<user>:<pass>@cluster.xxx.mongodb.net/?retryWrites=true&w=majority"
MONGO_URI = os.getenv("MONGODB_URI", "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/")
client = AsyncIOMotorClient(MONGO_URI)

# DB/Collection 이름은 기존 코드와 맞춤
db = client.lecture
collection = db.student

# ───────────────────────────
# Pydantic 모델
# ───────────────────────────
class Student(BaseModel):
    code: str
    name: str
    dept: str
    phone: str
    # image: Optional[str] = None  # base64 문자열

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

# ───────────────────────────
# API
# ───────────────────────────

@app.get('/select')
async def select():
    students = await collection.find().to_list(None)
    results = [normalize_student(s) for s in students]
    return {'results': results}

@app.get('/select/{code}')
async def select_one(code: str):
    student = await collection.find_one({'code': code})
    if not student:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': normalize_student(student)}

@app.post('/insert')
async def insert(student: Student):
    # code 중복 검사
    existing = await collection.find_one({'code': student.code})
    if existing:
        raise HTTPException(status_code=400, detail='Student is existed.')

    data = student.model_dump()
    # image(base64) → bytes
    if data.get('image'):
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    await collection.insert_one(data)
    return {'result': 'OK'}

@app.put('/update/{code}')
async def update(code: str, student: StudentUpdate):
    # 부분 업데이트 (image 제외)
    data = student.model_dump(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')

    result = await collection.update_one({'code': code}, {'$set': data})
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

    result = await collection.update_one({'code': code}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': 'OK'}

@app.delete('/delete/{code}')
async def delete(code: str):
    result = await collection.delete_one({'code': code})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='Student Not Found')
    return {'result': 'OK'}

# ───────────────────────────
# 실행
# ───────────────────────────
if __name__ == '__main__':
    import uvicorn
    # iOS 시뮬레이터에서 호출하려면 host=127.0.0.1 또는 0.0.0.0(포트포워딩/외부접속)
    uvicorn.run(app, host='127.0.0.1', port=8000)

# Swift

# struct Student: Codable {
#     var code: String
#     var name: String
#     var dept: String
#     var phone: String
#     var image: String?   // 서버에서는 base64 문자열
# }

# class APIConfig {
#     static let shared = APIConfig()   // 싱글턴
#     let baseURL = URL(string: "http://127.0.0.1:8000")! 
#     // ⚠️ iOS 실기기에서는 localhost 불가 → PC IP 주소로 변경 필요
# }

# struct Student: Codable {
#     var code: String
#     var name: String
#     var dept: String
#     var phone: String
#     var image: String?
# }

# 전체 조회 (GET /select)
# func fetchStudents() async throws -> [Student] {
#     let url = APIConfig.shared.baseURL.appendingPathComponent("select")
#     let (data, response) = try await URLSession.shared.data(from: url)
    
#     guard (response as? HTTPURLResponse)?.statusCode == 200 else {
#         throw URLError(.badServerResponse)
#     }
    
#     struct Response: Codable { let results: [Student] }
#     let decoded = try JSONDecoder().decode(Response.self, from: data)
#     return decoded.results
# }

# 추가 (POST /insert)
# func insertStudent(student: Student) async throws {
#     let url = APIConfig.shared.baseURL.appendingPathComponent("insert")
#     var req = URLRequest(url: url)
#     req.httpMethod = "POST"
#     req.addValue("application/json", forHTTPHeaderField: "Content-Type")
#     req.httpBody = try JSONEncoder().encode(student)

#     let (_, response) = try await URLSession.shared.data(for: req)
#     guard (response as? HTTPURLResponse)?.statusCode == 200 else {
#         throw URLError(.badServerResponse)
#     }
# }

# 수정 (PUT /update/{code})
# func updateStudent(code: String, newName: String) async throws {
#     let url = APIConfig.shared.baseURL.appendingPathComponent("update/\(code)")
#     var req = URLRequest(url: url)
#     req.httpMethod = "PUT"
#     req.addValue("application/json", forHTTPHeaderField: "Content-Type")
#     let body = ["name": newName]
#     req.httpBody = try JSONEncoder().encode(body)

#     let (_, response) = try await URLSession.shared.data(for: req)
#     guard (response as? HTTPURLResponse)?.statusCode == 200 else {
#         throw URLError(.badServerResponse)
#     }
# }

# 삭제 (DELETE /delete/{code})
# func deleteStudent(code: String) async throws {
#     let url = APIConfig.shared.baseURL.appendingPathComponent("delete/\(code)")
#     var req = URLRequest(url: url)
#     req.httpMethod = "DELETE"
    
#     let (_, response) = try await URLSession.shared.data(for: req)
#     guard (response as? HTTPURLResponse)?.statusCode == 200 else {
#         throw URLError(.badServerResponse)
#     }
# }

# SwiftUI에서 사용 예
# @MainActor
# class StudentViewModel: ObservableObject {
#     @Published var students: [Student] = []
    
#     func load() async {
#         do {
#             students = try await fetchStudents()
#         } catch {
#             print("Fetch error:", error)
#         }
#     }
    
#     func addSample() async {
#         let s = Student(code: "202501", name: "홍길동", dept: "컴공", phone: "010-1234-5678", image: nil)
#         do {
#             try await insertStudent(student: s)
#             await load()
#         } catch {
#             print("Insert error:", error)
#         }
#     }
# }