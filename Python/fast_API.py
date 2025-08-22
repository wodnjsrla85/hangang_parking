
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
MONGO_URI = "mongodb+srv://rlaxoals990504:team2public@team2.jozn4ix.mongodb.net/"
client = AsyncIOMotorClient(MONGO_URI)

# DB/Collection 이름은 기존 코드와 맞춤
db = client.lecture
collection = db.busking

# ───────────────────────────
# Pydantic 모델
# ───────────────────────────
class busking(BaseModel):
    userid : str
    name : str
    date : str
    category : str
    content : str
    bandName : str
    state : int
    # image: Optional[str] = None  # base64 문자열

class buskingUpdate(BaseModel):
    userid : Optional[str] = None
    name : Optional[str] = None
    date : Optional[str] = None
    category : Optional[str] = None
    content : Optional[str] = None
    bandName : Optional[str] = None
    state : Optional[int] = None

# class buskingUpdateAll(buskingUpdate):
#     image: Optional[str] = None  # base64 문자열

# ───────────────────────────
# 유틸: Mongo 문서 포맷 보정
# ───────────────────────────
def normalize_busking(doc: dict) -> dict:
    """userid를 str로, image(bytes)를 base64로 바꿔서 반환"""
    if not doc:
        return doc
    doc['_id'] = str(doc.get('_id'))
    return doc

# ───────────────────────────
# API
# ───────────────────────────

@app.get('/select')
async def select():
    busking = await collection.find().to_list(None)
    results = [normalize_busking(s) for s in busking]
    return {'results': results}

# @app.get('/select/{userid}')
# async def select_one(userid: str):
#     busking = await collection.find_one({'userid': userid})
#     if not busking:
#         raise HTTPException(status_code=404, detail='busking Not Found')
#     return {'result': normalize_busking(busking)}

@app.post('/insert')
async def insert(busking: busking):
    # userid 중복 검사
    existing = await collection.find_one({'userid': busking.userid})
    if existing:
        raise HTTPException(status_code=400, detail='busking is existed.')

    data = busking.dict()
    # image(base64) → bytes
    if data.get('image'):
        try:
            data['image'] = base64.b64decode(data['image'])
        except Exception:
            raise HTTPException(status_code=400, detail='Invalid Base64 image')

    await collection.insert_one(data)
    return {'result': 'OK'}

@app.put('/update/{userid}')
async def update(userid: str, busking: buskingUpdate):
    # 부분 업데이트 (image 제외)
    data = busking.dict(exclude_unset=True)
    if not data:
        raise HTTPException(status_code=400, detail='No Field For Update')

    result = await collection.update_one({'userid': userid}, {'$set': data})
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='busking Not Found')
    return {'result': 'OK'}

# @app.put('/updateAll/{userid}')
# async def update_all(userid: str, busking: buskingUpdate):
#     # 전체 필드 업데이트 (image 포함)
#     data = busking.dict(exclude_unset=True)
#     if not data:
#         raise HTTPException(status_code=400, detail='No Field For Update')

#     if 'image' in data and data['image']:
#         try:
#             data['image'] = base64.b64decode(data['image'])
#         except Exception:
#             raise HTTPException(status_code=400, detail='Invalid Base64 image')

#     result = await collection.update_one({'userid': userid}, {'$set': data})
#     if result.matched_count == 0:
#         raise HTTPException(status_code=404, detail='busking Not Found')
#     return {'result': 'OK'}

@app.delete('/delete/{userid}')
async def delete(userid: str):
    result = await collection.delete_one({'userid': userid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='busking Not Found')
    return {'result': 'OK'}

# ───────────────────────────
# 실행
# ───────────────────────────
if __name__ == '__main__':
    import uvicorn
    # iOS 시뮬레이터에서 호출하려면 ho
    uvicorn.run(app, host='127.0.0.1', port=8000)
