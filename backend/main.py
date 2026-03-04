from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from pydantic import BaseModel
from sqlalchemy.future import select
from sqlalchemy import and_, or_
import json
import uuid
from datetime import datetime

from websocket_manager import manager
from database import AsyncSessionLocal
from database import engine
from models import Base, Message, Room, User
from auth import hash_password, verify_password, create_access_token
app = FastAPI()

class RegisterRequest(BaseModel):
    name: str
    email: str
    phone: str
    password: str

class LoginRequest(BaseModel):
    email: str | None = None
    phone: str | None = None
    password: str

class RoomCreateRequest(BaseModel):
    name: str
    created_by: str

class MessageCreateRequest(BaseModel):
    sender_id: str
    content: str

class LookupRequest(BaseModel):
    phones: list[str]
    requester_id: str | None = None

class DirectRoomRequest(BaseModel):
    user_id: str
    peer_id: str

def serialize_message(message: Message):
    return {
        "id": str(message.id),
        "room_id": str(message.room_id),
        "sender_id": str(message.sender_id),
        "content": message.content,
        "created_at": message.created_at.isoformat() if message.created_at else None
    }

def serialize_room(room: Room, display_name: str | None = None, peer_id: str | None = None):
    return {
        "id": str(room.id),
        "name": display_name or room.name,
        "created_by": str(room.created_by),
        "created_at": room.created_at.isoformat() if room.created_at else None,
        "is_direct": room.is_direct,
        "peer_id": peer_id
    }

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)



@app.post("/register")
# async def register(name: str, email: str, password: str):
#     async with AsyncSessionLocal() as session:
async def register(body: RegisterRequest):
    async with AsyncSessionLocal() as session:

        # Check username
        result = await session.execute(
            select(User).where(User.name == body.name)
        )
        existing_user = result.scalars().first()

        if existing_user:
            raise HTTPException(status_code=400, detail="Username already exists")

        # Check email
        result = await session.execute(
            select(User).where(User.email == body.email)
        )
        existing_email = result.scalars().first()

        if existing_email:
            raise HTTPException(status_code=400, detail="Email already exists")

        # Check phone
        result = await session.execute(
            select(User).where(User.phone == body.phone)
        )
        existing_phone = result.scalars().first()

        if existing_phone:
            raise HTTPException(status_code=400, detail="Phone already exists")

        new_user = User(
            name=body.name,
            email=body.email,
            phone=body.phone,
            password=hash_password(body.password)
        )

        session.add(new_user)
        await session.commit()

        await session.refresh(new_user)

        return {
            "message": "User created successfully",
            "user": {
                "id": str(new_user.id),
                "name": new_user.name,
                "email": new_user.email,
                "phone": new_user.phone
            }
        }

@app.post("/login")
async def login(body: LoginRequest):
    async with AsyncSessionLocal() as session:

        # Find user by email
        if body.email:
            result = await session.execute(
                select(User).where(User.email == body.email)
            )
        else:
            result = await session.execute(
                select(User).where(User.phone == body.phone)
            )
        user = result.scalars().first()

        if not user:
            raise HTTPException(status_code=400, detail="Invalid email or password")

        # Verify password
        if not verify_password(body.password, user.password):       
            raise HTTPException(status_code=400, detail="Invalid email or password")

        # Create JWT token
        token = create_access_token({"sub": str(user.id)})

        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone
            }
        }

@app.post("/rooms")
async def create_room(body: RoomCreateRequest):
    async with AsyncSessionLocal() as session:
        try:
            creator_id = uuid.UUID(body.created_by)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user id")

        user_result = await session.execute(
            select(User).where(User.id == creator_id)
        )
        user = user_result.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        room_result = await session.execute(
            select(Room).where(Room.name == body.name)
        )
        existing_room = room_result.scalars().first()
        if existing_room:
            raise HTTPException(status_code=400, detail="Room name already exists")

        new_room = Room(
            name=body.name,
            created_by=creator_id,
            is_direct=False
        )
        session.add(new_room)
        await session.commit()
        await session.refresh(new_room)

        return serialize_room(new_room)

@app.get("/rooms")
async def list_rooms():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Room).order_by(Room.created_at.desc()))
        rooms = result.scalars().all()
        return [serialize_room(room) for room in rooms]

@app.post("/users/lookup")
async def lookup_users(body: LookupRequest):
    async with AsyncSessionLocal() as session:
        if not body.phones:
            return []
        result = await session.execute(
            select(User).where(User.phone.in_(body.phones))
        )
        users = result.scalars().all()
        return [
            {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone
            }
            for user in users
            if body.requester_id is None or str(user.id) != body.requester_id
        ]

@app.get("/users")
async def list_users(exclude_id: str | None = None):
    async with AsyncSessionLocal() as session:
        query = select(User)
        if exclude_id:
            try:
                excluded = uuid.UUID(exclude_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid user id")
            query = query.where(User.id != excluded)
        result = await session.execute(query.order_by(User.name.asc()))
        users = result.scalars().all()
        return [
            {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone
            }
            for user in users
        ]

@app.get("/users/{user_id}/rooms")
async def list_user_rooms(user_id: str):
    async with AsyncSessionLocal() as session:
        try:
            user_uuid = uuid.UUID(user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user id")

        result = await session.execute(
            select(Room).where(
                or_(
                    Room.created_by == user_uuid,
                    Room.member_a == user_uuid,
                    Room.member_b == user_uuid
                )
            ).order_by(Room.created_at.desc())
        )
        rooms = result.scalars().all()
        serialized = []
        for room in rooms:
            if room.is_direct:
                peer_id = str(room.member_b if room.member_a == user_uuid else room.member_a)
                peer_result = await session.execute(
                    select(User).where(User.id == uuid.UUID(peer_id))
                )
                peer = peer_result.scalars().first()
                display_name = peer.name if peer else room.name
                serialized.append(serialize_room(room, display_name, peer_id))
            else:
                serialized.append(serialize_room(room))
        return serialized

@app.post("/rooms/direct")
async def create_direct_room(body: DirectRoomRequest):
    async with AsyncSessionLocal() as session:
        try:
            user_id = uuid.UUID(body.user_id)
            peer_id = uuid.UUID(body.peer_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user id")

        user_result = await session.execute(
            select(User).where(User.id == user_id)
        )
        user = user_result.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        peer_result = await session.execute(
            select(User).where(User.id == peer_id)
        )
        peer = peer_result.scalars().first()
        if not peer:
            raise HTTPException(status_code=404, detail="Peer not found")

        result = await session.execute(
            select(Room).where(
                and_(
                    Room.is_direct == True,
                    or_(
                        and_(Room.member_a == user_id, Room.member_b == peer_id),
                        and_(Room.member_a == peer_id, Room.member_b == user_id)
                    )
                )
            )
        )
        existing_room = result.scalars().first()
        if existing_room:
            return serialize_room(existing_room, peer.name, str(peer.id))

        new_room = Room(
            name=f"direct:{min(str(user_id), str(peer_id))}:{max(str(user_id), str(peer_id))}",
            created_by=user_id,
            is_direct=True,
            member_a=user_id,
            member_b=peer_id
        )
        session.add(new_room)
        await session.commit()
        await session.refresh(new_room)
        return serialize_room(new_room, peer.name, str(peer.id))

@app.get("/rooms/{room_id}/messages")
async def list_messages(room_id: str, limit: int = 50, offset: int = 0):
    async with AsyncSessionLocal() as session:
        try:
            room_uuid = uuid.UUID(room_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid room id")

        room_result = await session.execute(
            select(Room).where(Room.id == room_uuid)
        )
        room = room_result.scalars().first()
        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

        result = await session.execute(
            select(Message)
            .where(Message.room_id == room_uuid)
            .order_by(Message.created_at.asc())
            .limit(limit)
            .offset(offset)
        )
        messages = result.scalars().all()
        return [serialize_message(message) for message in messages]

@app.post("/rooms/{room_id}/messages")
async def create_message(room_id: str, body: MessageCreateRequest):
    async with AsyncSessionLocal() as session:
        try:
            room_uuid = uuid.UUID(room_id)
            sender_uuid = uuid.UUID(body.sender_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid id")

        room_result = await session.execute(
            select(Room).where(Room.id == room_uuid)
        )
        room = room_result.scalars().first()
        if not room:
            raise HTTPException(status_code=404, detail="Room not found")

        user_result = await session.execute(
            select(User).where(User.id == sender_uuid)
        )
        user = user_result.scalars().first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        new_message = Message(
            room_id=room_uuid,
            sender_id=sender_uuid,
            content=body.content
        )
        session.add(new_message)
        await session.commit()
        await session.refresh(new_message)

        payload = serialize_message(new_message)
        await manager.broadcast(room_id, json.dumps(payload))
        return payload

@app.websocket("/ws/{room_id}/{user_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str, user_id: str):
    async with AsyncSessionLocal() as session:
        try:
            room_uuid = uuid.UUID(room_id)
            sender_uuid = uuid.UUID(user_id)
        except ValueError:
            await websocket.close(code=1008)
            return

        room_result = await session.execute(
            select(Room).where(Room.id == room_uuid)
        )
        room = room_result.scalars().first()
        if not room:
            await websocket.close(code=1008)
            return

        user_result = await session.execute(
            select(User).where(User.id == sender_uuid)
        )
        user = user_result.scalars().first()
        if not user:
            await websocket.close(code=1008)
            return

        await manager.connect(room_id, websocket)

        try:
            while True:
                data = await websocket.receive_text()

                new_message = Message(
                    room_id=room_uuid,
                    sender_id=sender_uuid,
                    content=data
                )

                session.add(new_message)
                await session.commit()
                await session.refresh(new_message)

                payload = serialize_message(new_message)
                await manager.broadcast(room_id, json.dumps(payload))

        except WebSocketDisconnect:
            manager.disconnect(room_id, websocket)
