# routes/admin.py

from fastapi import APIRouter, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
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
    date : str

@router.post('/admin/insert')
async def insert_admin(admin: Admin):
    # code 중복 검사
    existing = await collection_admin.find_one({'id': admin.id})
    if existing:
        raise HTTPException(status_code=400, detail='admin is existed.')

    data = admin.model_dump()
    await collection_admin.insert_one(data)
    return {'result': 'OK'}